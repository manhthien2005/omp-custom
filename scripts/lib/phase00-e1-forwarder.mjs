import { createHash } from "node:crypto";
import { closeSync, openSync, readFileSync, writeSync } from "node:fs";
import { createServer } from "node:http";
import { request as httpRequest } from "node:http";
import { request as httpsRequest } from "node:https";
import { pathToFileURL } from "node:url";

const LOOPBACK_HOST = "127.0.0.1";
const LOOPBACK_LISTEN = "127.0.0.1:0";
const MAX_REQUEST_BYTES = 32 * 1024 * 1024;
const HOP_BY_HOP_HEADERS = new Set([
  "connection",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "proxy-connection",
  "te",
  "trailer",
  "trailers",
  "transfer-encoding",
  "upgrade",
]);

export function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.keys(value)
        .sort()
        .map((key) => [key, stable(value[key])]),
    );
  }
  return value;
}

export function sha256(value) {
  return createHash("sha256")
    .update(JSON.stringify(stable(value)), "utf8")
    .digest("hex")
    .toUpperCase();
}

export function findYieldDataSchema(parameters) {
  const candidates = [];
  const addCandidate = (value) => {
    if (value && typeof value === "object" && !Array.isArray(value)) {
      candidates.push(value);
    }
  };
  const visitResultSchema = (value) => {
    if (!value || typeof value !== "object" || Array.isArray(value)) return;
    addCandidate(value?.properties?.data);
    for (const keyword of ["anyOf", "oneOf", "allOf"]) {
      const branches = value[keyword];
      if (!Array.isArray(branches)) continue;
      for (const branch of branches) visitResultSchema(branch);
    }
  };

  addCandidate(parameters?.properties?.data);
  visitResultSchema(parameters?.properties?.result);
  return candidates.length === 1 ? candidates[0] : null;
}

export function projectYieldTool(body, piNoStrictEffective) {
  const tools = Array.isArray(body?.tools) ? body.tools : [];
  const tool = tools.find(
    (candidate) => candidate?.name === "yield" || candidate?.function?.name === "yield",
  );
  const strictPresent = Boolean(tool && Object.prototype.hasOwnProperty.call(tool, "strict"));
  const parameters = tool?.parameters ?? tool?.function?.parameters ?? null;
  const data = findYieldDataSchema(parameters);
  return {
    gateway: "omniroute",
    api: "openai-responses",
    yield_tool_present: Boolean(tool),
    yield_strict_field_present: strictPresent,
    yield_strict: strictPresent ? tool.strict : null,
    yield_parameters_sha256: parameters === null ? null : sha256(parameters),
    allowed_data_properties: Object.keys(data?.properties ?? {}).sort(),
    required_data_properties: Array.isArray(data?.required) ? [...data.required].sort() : [],
    data_additional_properties: data?.additionalProperties ?? null,
    pi_no_strict_effective: piNoStrictEffective,
  };
}

export function createProjectionRecord(body, piNoStrictEffective, metadata = {}) {
  return {
    record_type: "phase00_e1_request_projection",
    request_index: metadata.requestIndex ?? 1,
    request_path: metadata.requestPath ?? "/v1/responses",
    forwarded: metadata.forwarded ?? false,
    gateway_http_status: metadata.gatewayHttpStatus ?? null,
    ...projectYieldTool(body, piNoStrictEffective),
  };
}

function parseBoolean(text, optionName) {
  if (text === "true") return true;
  if (text === "false") return false;
  throw new Error(`${optionName} must be exactly true or false.`);
}

function parseCliArguments(argv) {
  const options = new Map();
  for (let index = 0; index < argv.length; index += 2) {
    const name = argv[index];
    const value = argv[index + 1];
    if (!name?.startsWith("--") || value === undefined || value.startsWith("--")) {
      throw new Error(`Invalid or incomplete argument near ${name ?? "<end>"}.`);
    }
    if (options.has(name)) throw new Error(`Duplicate argument: ${name}.`);
    options.set(name, value);
  }
  const allowed = new Set([
    "--project-only",
    "--listen",
    "--target",
    "--output",
    "--pi-no-strict",
  ]);
  for (const name of options.keys()) {
    if (!allowed.has(name)) throw new Error(`Unknown argument: ${name}.`);
  }
  for (const name of ["--output", "--pi-no-strict"]) {
    if (!options.has(name)) throw new Error(`Missing required argument: ${name}.`);
  }
  const projectOnly = options.has("--project-only");
  const live = options.has("--listen") || options.has("--target");
  if (projectOnly === live) {
    throw new Error("Select exactly one mode: --project-only or --listen with --target.");
  }
  const common = {
    outputPath: options.get("--output"),
    piNoStrictEffective: parseBoolean(options.get("--pi-no-strict"), "--pi-no-strict"),
  };
  if (projectOnly) {
    return { mode: "project-only", requestPath: options.get("--project-only"), ...common };
  }
  if (!options.has("--listen") || !options.has("--target")) {
    throw new Error("Live mode requires both --listen and --target.");
  }
  if (options.get("--listen") !== LOOPBACK_LISTEN) {
    throw new Error(`--listen must be exactly ${LOOPBACK_LISTEN}.`);
  }
  const target = new URL(options.get("--target"));
  if (
    !["http:", "https:"].includes(target.protocol) ||
    target.hostname !== LOOPBACK_HOST ||
    !target.port ||
    target.username ||
    target.password ||
    target.pathname !== "/" ||
    target.search ||
    target.hash
  ) {
    throw new Error("--target must be an HTTP(S) 127.0.0.1 origin with an explicit port.");
  }
  return { mode: "live", listen: options.get("--listen"), target, ...common };
}

function readRequestObject(requestPath) {
  const parsed = JSON.parse(readFileSync(requestPath, "utf8"));
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("Projection request must be one JSON object.");
  }
  return parsed;
}

function createExclusiveNdjsonWriter(outputPath) {
  const descriptor = openSync(outputPath, "wx", 0o600);
  let closed = false;
  return {
    write(record) {
      if (closed) throw new Error("Evidence writer is already closed.");
      writeSync(descriptor, `${JSON.stringify(record)}\n`, undefined, "utf8");
    },
    close() {
      if (closed) return;
      closed = true;
      closeSync(descriptor);
    },
  };
}

export function runProjectOnly({ requestPath, outputPath, piNoStrictEffective }) {
  const body = readRequestObject(requestPath);
  const record = createProjectionRecord(body, piNoStrictEffective);
  const writer = createExclusiveNdjsonWriter(outputPath);
  try {
    writer.write(record);
  } finally {
    writer.close();
  }
  return record;
}

function connectionHeaderTokens(headers) {
  const value = headers.connection;
  const text = Array.isArray(value) ? value.join(",") : (value ?? "");
  return text
    .split(",")
    .map((token) => token.trim().toLowerCase())
    .filter(Boolean);
}

export function stripHopByHopHeaders(headers, { stripEntityLength = false } = {}) {
  const blocked = new Set([...HOP_BY_HOP_HEADERS, ...connectionHeaderTokens(headers)]);
  blocked.add("host");
  if (stripEntityLength) blocked.add("content-length");
  const result = {};
  for (const [name, value] of Object.entries(headers)) {
    if (value === undefined || blocked.has(name.toLowerCase())) continue;
    result[name] = value;
  }
  return result;
}

function sendLocalError(response, statusCode, message) {
  const body = Buffer.from(message, "utf8");
  response.writeHead(statusCode, {
    "content-type": "text/plain; charset=utf-8",
    "content-length": String(body.length),
    connection: "close",
  });
  response.end(body);
}

function readRequestBody(request) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    request.on("data", (chunk) => {
      size += chunk.length;
      if (size > MAX_REQUEST_BYTES) {
        reject(new Error("Request body exceeds the bounded in-memory limit."));
        request.destroy();
        return;
      }
      chunks.push(chunk);
    });
    request.on("end", () => resolve(Buffer.concat(chunks)));
    request.on("error", reject);
  });
}

function registerRelay(activeRelays, upstream, outgoing) {
  const relay = {
    upstream,
    upstreamResponse: null,
    outgoing,
    finished: false,
    finish() {
      if (relay.finished) return;
      relay.finished = true;
      activeRelays.delete(relay);
    },
    dispose({ destroyDownstream = false } = {}) {
      if (relay.finished) return;
      if (relay.upstreamResponse && !relay.upstreamResponse.destroyed) {
        relay.upstreamResponse.destroy();
      }
      if (!relay.upstream.destroyed) relay.upstream.destroy();
      if (destroyDownstream && !relay.outgoing.destroyed) relay.outgoing.destroy();
      relay.finish();
    },
  };
  activeRelays.add(relay);
  return relay;
}

function relayRequest({
  incoming,
  outgoing,
  target,
  writer,
  requestIndex,
  piNoStrictEffective,
  activeRelays,
}) {
  void (async () => {
    let bodyBytes;
    let relay = null;
    try {
      const incomingUrl = new URL(incoming.url ?? "/", `http://${LOOPBACK_HOST}`);
      if (incoming.method !== "POST" || incomingUrl.pathname !== "/v1/responses") {
        sendLocalError(outgoing, 404, "Only POST /v1/responses is accepted.");
        return;
      }
      bodyBytes = await readRequestBody(incoming);
      const body = JSON.parse(bodyBytes.toString("utf8"));
      if (!body || typeof body !== "object" || Array.isArray(body)) {
        throw new Error("Provider request must be one JSON object.");
      }

      const headers = stripHopByHopHeaders(incoming.headers, { stripEntityLength: true });
      headers["content-length"] = String(bodyBytes.length);
      const forwardPath = `${incomingUrl.pathname}${incomingUrl.search}`;
      const requester = target.protocol === "https:" ? httpsRequest : httpRequest;
      let projectionWritten = false;
      const persistProjection = (upstreamResponse) => {
        if (projectionWritten) return;
        projectionWritten = true;
        writer.write(
          createProjectionRecord(body, piNoStrictEffective, {
            requestIndex,
            requestPath: incomingUrl.pathname,
            forwarded: true,
            gatewayHttpStatus: upstreamResponse.statusCode ?? null,
          }),
        );
      };
      const upstream = requester(
        {
          protocol: target.protocol,
          hostname: target.hostname,
          port: target.port,
          method: incoming.method,
          path: forwardPath,
          headers,
        },
        (upstreamResponse) => {
          if (relay.finished) {
            upstreamResponse.destroy();
            return;
          }
          relay.upstreamResponse = upstreamResponse;
          persistProjection(upstreamResponse);
          const responseHeaders = stripHopByHopHeaders(upstreamResponse.headers);
          outgoing.writeHead(upstreamResponse.statusCode ?? 502, responseHeaders);
          upstreamResponse.on("end", () => {
            if (!outgoing.destroyed) outgoing.end();
            relay.finish();
          });
          upstreamResponse.on("error", () => {
            if (!outgoing.destroyed) outgoing.destroy();
            relay.dispose();
          });
          upstreamResponse.on("close", () => {
            if (upstreamResponse.complete) return;
            if (!outgoing.destroyed) outgoing.destroy();
            relay.dispose();
          });
          upstreamResponse.pipe(outgoing, { end: false });
        },
      );
      relay = registerRelay(activeRelays, upstream, outgoing);
      outgoing.on("close", () => {
        if (!relay.finished && (!relay.upstreamResponse || !relay.upstreamResponse.complete)) {
          relay.dispose();
        }
      });
      upstream.on("error", () => {
        if (!outgoing.headersSent && !outgoing.destroyed) {
          sendLocalError(outgoing, 502, "Loopback gateway unavailable.");
        } else if (!outgoing.destroyed) {
          outgoing.destroy();
        }
        relay.dispose();
      });
      upstream.on("close", () => {
        if (!relay.upstreamResponse && !relay.finished) {
          if (!outgoing.headersSent && !outgoing.destroyed) {
            sendLocalError(outgoing, 502, "Loopback gateway unavailable.");
          } else if (!outgoing.destroyed) {
            outgoing.destroy();
          }
          relay.finish();
        }
      });
      upstream.end(bodyBytes);
    } catch (error) {
      if (relay) relay.dispose();
      if (!outgoing.headersSent) {
        const status = error.message.includes("bounded in-memory") ? 413 : 400;
        sendLocalError(outgoing, status, "Invalid provider request.");
      } else {
        outgoing.destroy();
      }
    }
  })();
}

export async function runLive({ target, outputPath, piNoStrictEffective }) {
  const writer = createExclusiveNdjsonWriter(outputPath);
  const server = createServer();
  const activeRelays = new Set();
  let requestIndex = 0;
  let listenPort = null;
  let closing = false;
  let resolveClosed;
  let rejectClosed;
  const closed = new Promise((resolve, reject) => {
    resolveClosed = resolve;
    rejectClosed = reject;
  });

  server.on("request", (incoming, outgoing) => {
    requestIndex += 1;
    relayRequest({
      incoming,
      outgoing,
      target,
      writer,
      requestIndex,
      piNoStrictEffective,
      activeRelays,
    });
  });

  const shutdown = () => {
    if (closing) return;
    closing = true;
    process.stdin.pause();
    server.close((error) => {
      try {
        writer.write({
          record_type: "phase00_e1_forwarder_closed",
          listen_host: LOOPBACK_HOST,
          listen_port: listenPort,
        });
        writer.close();
      } catch (writeError) {
        rejectClosed(writeError);
        return;
      }
      if (error) rejectClosed(error);
      else resolveClosed();
    });
    for (const relay of [...activeRelays]) {
      relay.dispose({ destroyDownstream: true });
    }
  };

  try {
    await new Promise((resolve, reject) => {
      server.once("error", reject);
      server.listen(0, LOOPBACK_HOST, () => {
        server.off("error", reject);
        resolve();
      });
    });
    const address = server.address();
    if (!address || typeof address !== "object") throw new Error("Loopback listener has no address.");
    listenPort = address.port;
    const ready = {
      record_type: "phase00_e1_forwarder_ready",
      listen_host: LOOPBACK_HOST,
      listen_port: listenPort,
    };
    writer.write(ready);
    process.stdout.write(`${JSON.stringify(ready)}\n`);

    let stdinBuffer = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (text) => {
      stdinBuffer += text;
      const lines = stdinBuffer.split(/\r?\n/);
      stdinBuffer = lines.pop() ?? "";
      if (lines.some((line) => line.trim() === "close")) shutdown();
    });
    process.on("SIGINT", shutdown);
    process.on("SIGTERM", shutdown);
    await closed;
  } catch (error) {
    if (!closing && server.listening) server.close();
    writer.close();
    throw error;
  }
}

async function main() {
  const options = parseCliArguments(process.argv.slice(2));
  if (options.mode === "project-only") runProjectOnly(options);
  else await runLive(options);
}

const isMain = process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url;
if (isMain) {
  main().catch((error) => {
    process.stderr.write(`phase00-e1-forwarder: ${error.message}\n`);
    process.exitCode = 1;
  });
}
