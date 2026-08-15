import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const TOOL_NAME = "codegraph_retrieve";
const OUTER_TIMEOUT_MS = 600_000;
const STDOUT_LIMIT_BYTES = 131_072;
const REASON_CODES = new Set([
  "ok",
  "component_uninstalled",
  "runtime_manifest_invalid",
  "unsupported_platform",
  "artifact_identity_mismatch",
  "executable_missing",
  "version_mismatch",
  "state_component_missing",
  "state_binding_ambiguous",
  "state_cache_not_owned",
  "candidate_index_missing",
  "candidate_drift",
  "worktree_mismatch",
  "index_busy",
  "index_missing",
  "index_init_failed",
  "index_sync_failed",
  "index_unhealthy",
  "index_partial",
  "index_pending_refs",
  "query_failed",
  "graph_gap",
  "output_truncated",
  "timeout",
  "cancelled",
  "source_changed",
  "internal_error",
]);

function fallbackEnvelope(reason) {
  const partial = new Set(["index_partial", "index_pending_refs", "graph_gap"]);
  const blocked = new Set([
    "component_uninstalled",
    "unsupported_platform",
    "state_component_missing",
    "state_binding_ambiguous",
    "state_cache_not_owned",
    "candidate_index_missing",
    "index_busy",
    "index_missing",
    "cancelled",
  ]);
  return {
    schema_version: 1,
    ok: false,
    status: partial.has(reason) ? "partial" : blocked.has(reason) ? "blocked" : "failed",
    reason_code: reason,
    fallback: "native",
    data: null,
  };
}

function toolResult(envelope) {
  if (envelope.ok) {
    return {
      content: [{ type: "text", text: envelope.data.text }],
      details: envelope,
      isError: false,
    };
  }
  return {
    content: [{
      type: "text",
      text: `CodeGraph retrieval unavailable (${envelope.reason_code}); continue with native read/grep/glob retrieval.`,
    }],
    details: envelope,
    isError: true,
  };
}

function safeFallback(reason = "internal_error") {
  return toolResult(fallbackEnvelope(REASON_CODES.has(reason) && reason !== "ok" ? reason : "internal_error"));
}

function exactProperties(value, names) {
  return value !== null && typeof value === "object" && !Array.isArray(value) &&
    Object.keys(value).sort().join("|") === [...names].sort().join("|");
}

function sha256(file) {
  return crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

function comparable(value) {
  const resolved = path.resolve(value).replace(/[\\/]+$/, "");
  return process.platform === "win32" ? resolved.toLowerCase() : resolved;
}

function pathInside(root, candidate) {
  const relative = path.relative(root, candidate);
  return relative !== "" && relative !== ".." && !relative.startsWith(`..${path.sep}`) &&
    !path.isAbsolute(relative);
}

function expectedPlatform() {
  const osName = { win32: "win32", linux: "linux", darwin: "darwin" }[process.platform];
  const architecture = { x64: "x64", arm64: "arm64" }[process.arch];
  if (!osName || !architecture) throw new Error("unsupported_platform");
  return `${osName}-${architecture}`;
}

export function normalizeQuestion(value) {
  if (typeof value !== "string" || value.includes("\0")) throw new Error("query_failed");
  const trimmed = value.trim().normalize("NFC");
  if (!trimmed || [...trimmed].length > 1024 || !Buffer.from(trimmed, "utf8").toString("utf8").includes(trimmed)) {
    throw new Error("query_failed");
  }
  for (let index = 0; index < trimmed.length; index += 1) {
    const code = trimmed.charCodeAt(index);
    if (code >= 0xd800 && code <= 0xdbff) {
      const next = trimmed.charCodeAt(index + 1);
      if (!(next >= 0xdc00 && next <= 0xdfff)) throw new Error("query_failed");
      index += 1;
    } else if (code >= 0xdc00 && code <= 0xdfff) {
      throw new Error("query_failed");
    }
  }
  return trimmed;
}

export function normalizeInput(params) {
  if (!exactProperties(params, Object.hasOwn(params ?? {}, "max_files")
    ? ["question", "max_files"]
    : ["question"])) throw new Error("query_failed");
  const question = normalizeQuestion(params.question);
  let maxFiles = 6;
  if (Object.hasOwn(params, "max_files")) {
    if (!Number.isInteger(params.max_files)) throw new Error("query_failed");
    maxFiles = Math.min(12, Math.max(1, params.max_files));
  }
  return { question, maxFiles };
}

export function encodeBase64Url(value) {
  return Buffer.from(value, "utf8").toString("base64url");
}

export function resolveInstalledRuntime(moduleUrl = import.meta.url) {
  const toolPath = fileURLToPath(moduleUrl);
  const toolsRoot = path.dirname(toolPath);
  const targetOmp = path.resolve(toolsRoot, "..");
  const componentRoot = path.join(targetOmp, "codegraph");
  const runtimePath = path.join(componentRoot, "runtime.json");
  const wrapperPath = path.join(componentRoot, "codegraph-process.ps1");
  if (!fs.existsSync(runtimePath) || !fs.statSync(runtimePath).isFile()) {
    throw new Error("component_uninstalled");
  }
  let runtime;
  try { runtime = JSON.parse(fs.readFileSync(runtimePath, "utf8")); }
  catch { throw new Error("runtime_manifest_invalid"); }
  if (!exactProperties(runtime, [
    "schema_version", "record_type", "component", "component_version", "created_at_utc",
    "target_omp", "component_manifest_sha256", "upstream_lock_sha256", "receipt_sha256",
    "upstream", "version", "tag", "commit", "platform", "artifact_sha256", "paths",
  ]) || !exactProperties(runtime.paths, [
    "bundle_root", "receipt", "launcher", "node", "library_entry", "cli_entry", "safe_init",
    "process_wrapper", "pwsh",
  ]) || runtime.schema_version !== 1 || runtime.record_type !== "codegraph_target_runtime" ||
      runtime.component !== "codegraph" || runtime.component_version !== "1.0.0" ||
      comparable(runtime.target_omp) !== comparable(targetOmp) || runtime.platform !== expectedPlatform()) {
    throw new Error("runtime_manifest_invalid");
  }
  for (const name of [
    "component_manifest_sha256", "upstream_lock_sha256", "receipt_sha256", "artifact_sha256",
  ]) {
    if (!/^[0-9a-f]{64}$/.test(runtime[name])) throw new Error("runtime_manifest_invalid");
  }
  if (comparable(runtime.paths.process_wrapper) !== comparable(wrapperPath) ||
      !pathInside(targetOmp, runtime.paths.process_wrapper) ||
      !pathInside(targetOmp, runtime.paths.safe_init) ||
      !fs.existsSync(wrapperPath) || !fs.statSync(wrapperPath).isFile()) {
    throw new Error("runtime_manifest_invalid");
  }
  const componentManifestPath = path.join(componentRoot, "component-manifest.json");
  const upstreamLockPath = path.join(componentRoot, "upstream-lock.json");
  for (const [file, expected] of [
    [componentManifestPath, runtime.component_manifest_sha256],
    [upstreamLockPath, runtime.upstream_lock_sha256],
    [runtime.paths.receipt, runtime.receipt_sha256],
  ]) {
    if (!fs.existsSync(file) || !fs.statSync(file).isFile() || sha256(file) !== expected) {
      throw new Error("runtime_manifest_invalid");
    }
  }
  let lock;
  let receipt;
  try {
    lock = JSON.parse(fs.readFileSync(upstreamLockPath, "utf8"));
    receipt = JSON.parse(fs.readFileSync(runtime.paths.receipt, "utf8"));
  } catch { throw new Error("runtime_manifest_invalid"); }
  if (lock.upstream !== runtime.upstream || lock.version !== runtime.version || lock.tag !== runtime.tag ||
      lock.commit !== runtime.commit || receipt.upstream !== runtime.upstream ||
      receipt.version !== runtime.version || receipt.tag !== runtime.tag ||
      receipt.commit !== runtime.commit || receipt.platform !== runtime.platform ||
      receipt.artifact?.sha256 !== runtime.artifact_sha256 ||
      comparable(receipt.bundle_root) !== comparable(runtime.paths.bundle_root) ||
      comparable(receipt.receipt_path) !== comparable(runtime.paths.receipt)) {
    throw new Error("artifact_identity_mismatch");
  }
  return { runtime, runtimePath, wrapperPath };
}

export function parseEnvelope(stdout) {
  if (typeof stdout !== "string" || Buffer.byteLength(stdout, "utf8") > STDOUT_LIMIT_BYTES) {
    throw new Error("internal_error");
  }
  const lines = stdout.split(/\r?\n/);
  if (lines.at(-1) === "") lines.pop();
  if (lines.length !== 1 || !lines[0]) throw new Error("internal_error");
  let envelope;
  try { envelope = JSON.parse(lines[0]); }
  catch { throw new Error("internal_error"); }
  if (!exactProperties(envelope, [
    "schema_version", "ok", "status", "reason_code", "fallback", "data",
  ]) || envelope.schema_version !== 1 || typeof envelope.ok !== "boolean" ||
      !["completed", "partial", "blocked", "failed"].includes(envelope.status) ||
      !REASON_CODES.has(envelope.reason_code)) {
    throw new Error("internal_error");
  }
  if (envelope.ok) {
    if (envelope.status !== "completed" || envelope.reason_code !== "ok" ||
        envelope.fallback !== null || !envelope.data || typeof envelope.data.text !== "string" ||
        !envelope.data.text || Buffer.byteLength(envelope.data.text, "utf8") > 32768) {
      throw new Error("internal_error");
    }
  } else if (envelope.reason_code === "ok" || envelope.fallback !== "native" || envelope.data !== null) {
    throw new Error("internal_error");
  }
  return envelope;
}

export default function codeGraphRetrieveFactory(pi) {
  const { Type } = pi.typebox;
  return {
    name: TOOL_NAME,
    label: "CodeGraph Retrieve",
    description: "Retrieve bounded graph context for the current worktree; use native retrieval on any fallback result.",
    loadMode: "discoverable",
    approval: "exec",
    strict: true,
    parameters: Type.Object({
      question: Type.String({ minLength: 1, maxLength: 1024 }),
      max_files: Type.Optional(Type.Integer()),
    }, { additionalProperties: false }),
    async execute(_toolCallId, params, _onUpdate, _ctx, signal) {
      let input;
      let installed;
      try {
        input = normalizeInput(params);
        installed = resolveInstalledRuntime(import.meta.url);
      } catch (error) {
        return safeFallback(error instanceof Error ? error.message : "internal_error");
      }

      let processResult;
      try {
        processResult = await pi.exec(installed.runtime.paths.pwsh, [
          "-NoProfile",
          "-NonInteractive",
          "-File", installed.wrapperPath,
          "-Operation", "retrieve",
          "-RuntimePath", installed.runtimePath,
          "-WorkingDirectory", pi.cwd,
          "-QuestionBase64", encodeBase64Url(input.question),
          "-MaxFiles", String(input.maxFiles),
        ], { cwd: pi.cwd, signal, timeout: OUTER_TIMEOUT_MS });
      } catch {
        return safeFallback(signal?.aborted ? "cancelled" : "internal_error");
      }
      if (processResult?.killed) return safeFallback("cancelled");
      if (!processResult || processResult.code !== 0) return safeFallback("internal_error");
      try { return toolResult(parseEnvelope(processResult.stdout)); }
      catch { return safeFallback("internal_error"); }
    },
  };
}
