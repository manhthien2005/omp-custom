import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";

import { canonicalJson, parseJsonNoDuplicateKeys } from "./agent-boundary-core.mjs";

const DEFAULT_TIMEOUT_MS = 30_000;
const DEFAULT_OUTPUT_LIMIT_BYTES = 128 * 1024;
const TEMP_PREFIX = "omp-managed-state-";

function safeError(reason = "state_unavailable") {
  return new Error(reason === "cancelled" ? "cancelled" : "state_unavailable");
}

function isPlainObject(value) {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function exactKeys(value, allowed) {
  return isPlainObject(value) &&
    Object.keys(value).every((key) => allowed.includes(key)) &&
    allowed.every((key) => Object.hasOwn(value, key));
}

function comparablePath(value) {
  const resolved = path.resolve(value).replace(/[\\/]+$/u, "");
  return process.platform === "win32" ? resolved.toLowerCase() : resolved;
}

function removeOwnedTempDirectory(tempDirectory) {
  if (typeof tempDirectory !== "string" || tempDirectory.length === 0) return;
  const resolved = path.resolve(tempDirectory);
  const expectedParent = path.resolve(os.tmpdir());
  if (comparablePath(path.dirname(resolved)) !== comparablePath(expectedParent) ||
      !path.basename(resolved).startsWith(TEMP_PREFIX)) {
    return;
  }
  fs.rmSync(resolved, { recursive: true, force: true });
}

export function getManagedSessionRef(ctx) {
  try {
    const sessionRef = ctx?.sessionManager?.getSessionId?.();
    if (typeof sessionRef !== "string" || sessionRef.trim().length === 0) throw safeError();
    return sessionRef;
  } catch {
    throw safeError();
  }
}

export function parseManagedStateEnvelope(text) {
  try {
    if (typeof text !== "string" || Buffer.byteLength(text, "utf8") > DEFAULT_OUTPUT_LIMIT_BYTES) {
      throw safeError();
    }
    const lines = text.split(/\r?\n/u);
    if (lines.at(-1) === "") lines.pop();
    if (lines.length !== 1 || lines[0].length === 0) throw safeError();
    const envelope = parseJsonNoDuplicateKeys(lines[0]);
    if (!exactKeys(envelope, ["code", "data", "ok", "operation"]) ||
        typeof envelope.code !== "string" || envelope.code.length === 0 ||
        !isPlainObject(envelope.data) || typeof envelope.ok !== "boolean" ||
        typeof envelope.operation !== "string" || envelope.operation.length === 0) {
      throw safeError();
    }
    return envelope;
  } catch {
    throw safeError();
  }
}

function runBoundedProcess(command, args, { cwd, signal, timeoutMs, outputLimitBytes }) {
  return new Promise((resolve, reject) => {
    let settled = false;
    let stdout = "";
    let stderr = "";
    let stdoutBytes = 0;
    let stderrBytes = 0;
    let timer;
    let child;
    let stoppingReason;

    const finish = (callback, value) => {
      if (settled) return;
      settled = true;
      if (timer !== undefined) clearTimeout(timer);
      signal?.removeEventListener?.("abort", abort);
      callback(value);
    };
    const stop = (reason) => {
      if (settled || stoppingReason !== undefined) return;
      stoppingReason = reason;
      try {
        child?.kill();
      } catch {
        finish(reject, safeError(reason));
      }
    };
    const abort = () => stop("cancelled");
    const append = (kind, chunk) => {
      if (settled || stoppingReason !== undefined) return;
      const bytes = Buffer.byteLength(chunk, "utf8");
      if (kind === "stdout") {
        stdoutBytes += bytes;
        if (stdoutBytes > outputLimitBytes) return stop("state_unavailable");
        stdout += chunk;
      } else {
        stderrBytes += bytes;
        if (stderrBytes > outputLimitBytes) return stop("state_unavailable");
        stderr += chunk;
      }
      return undefined;
    };

    try {
      child = spawn(command, args, {
        cwd,
        windowsHide: true,
        shell: false,
        stdio: ["ignore", "pipe", "pipe"],
      });
      timer = setTimeout(() => stop("state_unavailable"), timeoutMs);
      child.stdout.setEncoding("utf8");
      child.stderr.setEncoding("utf8");
      child.stdout.on("data", (chunk) => append("stdout", chunk));
      child.stderr.on("data", (chunk) => append("stderr", chunk));
      child.once("error", () => finish(reject, safeError(stoppingReason)));
      child.once("close", (code, closeSignal) => {
        if (stoppingReason !== undefined) {
          finish(reject, safeError(stoppingReason));
          return;
        }
        finish(resolve, { code, signal: closeSignal, stdout, stderr });
      });
      if (signal?.aborted) abort();
      else signal?.addEventListener?.("abort", abort, { once: true });
    } catch {
      finish(reject, safeError());
    }
  });
}

export async function invokeManagedState({
  pwshPath,
  stateCliPath,
  operation,
  request,
  ctx,
  signal,
  timeoutMs = DEFAULT_TIMEOUT_MS,
  outputLimitBytes = DEFAULT_OUTPUT_LIMIT_BYTES,
  acceptNonzeroFailureEnvelope = false,
}) {
  let tempDirectory;
  try {
    if (typeof pwshPath !== "string" || !path.isAbsolute(pwshPath) ||
        typeof stateCliPath !== "string" || !path.isAbsolute(stateCliPath) ||
        typeof operation !== "string" || operation.trim().length === 0 ||
        !Number.isSafeInteger(timeoutMs) || timeoutMs <= 0 ||
        !Number.isSafeInteger(outputLimitBytes) || outputLimitBytes <= 0 ||
        typeof acceptNonzeroFailureEnvelope !== "boolean" ||
        typeof ctx?.cwd !== "string" || !path.isAbsolute(ctx.cwd)) {
      throw safeError();
    }

    const envelope = {
      schema_version: 1,
      operation,
      working_directory: ctx.cwd,
      session_ref: getManagedSessionRef(ctx),
      runtime: "omp",
      request,
    };
    const document = canonicalJson(envelope);
    tempDirectory = fs.mkdtempSync(path.join(os.tmpdir(), TEMP_PREFIX));
    const requestPath = path.join(tempDirectory, "request.json");
    fs.writeFileSync(requestPath, document, { encoding: "utf8", flag: "wx" });

    const result = await runBoundedProcess(pwshPath, [
      "-NoProfile",
      "-NonInteractive",
      "-File", stateCliPath,
      "-RequestPath", requestPath,
    ], {
      cwd: envelope.working_directory,
      signal,
      timeoutMs,
      outputLimitBytes,
    });
    if (result.signal !== null && result.signal !== undefined) throw safeError();
    const parsed = parseManagedStateEnvelope(result.stdout);
    if (parsed.operation !== operation) throw safeError();
    if (result.code !== 0 && (!acceptNonzeroFailureEnvelope || parsed.ok !== false)) throw safeError();
    return parsed;
  } catch (error) {
    if (error?.message === "cancelled") throw safeError("cancelled");
    throw safeError();
  } finally {
    removeOwnedTempDirectory(tempDirectory);
  }
}
