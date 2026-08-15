import crypto from "node:crypto";
import {
  canonicalJson,
  sha256Canonical,
} from "./agent-boundary-core.mjs";
import {
  CONTINUITY_ACTIVE_STATUSES,
  CONTINUITY_DEGRADED_FIELDS,
  CONTINUITY_LIMITS,
  CONTINUITY_OBSERVATION_ENUMS,
  CONTINUITY_PATTERNS,
  CONTINUITY_REASON_CODES,
  CONTINUITY_WORKFLOW_CLASSES,
} from "./context-continuity-schema.mjs";

export { canonicalJson, sha256Canonical } from "./agent-boundary-core.mjs";

export const CONTEXT_PRESSURE_ABORT_MARKER = "T07_CONTEXT_PRESSURE_ABORT";
const PRESSURE_ABORT_REGISTRY_KEY = Symbol.for("omp-template.topic07.context-pressure.v1");
const PRESSURE_ABORT_TTL_MS = 5 * 60 * 1_000;
const PRESSURE_ABORT_MAX_RECORDS = 128;

function pressureAbortRegistry() {
  const current = globalThis[PRESSURE_ABORT_REGISTRY_KEY];
  if (current instanceof Map) return current;
  const created = new Map();
  Object.defineProperty(globalThis, PRESSURE_ABORT_REGISTRY_KEY, {
    value: created,
    configurable: false,
    enumerable: false,
    writable: false,
  });
  return created;
}

function pressureAbortKey({ agent, task }) {
  if (!["cheap-scout", "worker", "reviewer"].includes(agent) || typeof task !== "string" ||
      task.length === 0 || Buffer.byteLength(task, "utf8") > 131_072) return null;
  return `${agent}:${crypto.createHash("sha256").update(task, "utf8").digest("hex")}`;
}

export function recordContextPressureAbort({ agent, task, nowMs = Date.now() } = {}) {
  const key = pressureAbortKey({ agent, task });
  if (key === null || !Number.isSafeInteger(nowMs) || nowMs < 0) return false;
  const registry = pressureAbortRegistry();
  for (const [candidate, record] of registry) if (record.expiresAtMs <= nowMs) registry.delete(candidate);
  while (registry.size >= PRESSURE_ABORT_MAX_RECORDS) registry.delete(registry.keys().next().value);
  registry.set(key, { marker: CONTEXT_PRESSURE_ABORT_MARKER, expiresAtMs: nowMs + PRESSURE_ABORT_TTL_MS });
  return true;
}

export function consumeContextPressureAbort({ agent, task, nowMs = Date.now() } = {}) {
  const key = pressureAbortKey({ agent, task });
  if (key === null || !Number.isSafeInteger(nowMs) || nowMs < 0) return null;
  const registry = pressureAbortRegistry();
  const record = registry.get(key);
  registry.delete(key);
  return record?.marker === CONTEXT_PRESSURE_ABORT_MARKER && record.expiresAtMs > nowMs
    ? CONTEXT_PRESSURE_ABORT_MARKER
    : null;
}

const FORBIDDEN_PROPERTY_NAMES = new Set([
  "transcript",
  "conversation",
  "conversationhistory",
  "history",
  "messages",
  "toolhistory",
  "toolcall",
  "toolcalls",
  "toolresult",
  "toolresults",
  "terminalhistory",
  "terminaloutput",
  "reasoning",
  "thought",
  "thoughts",
  "chainofthought",
  "credential",
  "credentials",
  "authorization",
  "authorizationheader",
  "cookie",
  "cookies",
  "apikey",
  "accesstoken",
  "refreshtoken",
  "privatekey",
  "secret",
  "secrets",
  "privatepath",
  "sessionpath",
  "statepath",
  "rawnonce",
  "nonce",
  "prompt",
  "providerpayload",
]);

const SECRET_PATTERNS = Object.freeze([
  /(?:authorization\s*:\s*)?bearer\s+[A-Za-z0-9._~+/=-]{8,}/iu,
  /\beyJ[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{6,}\b/u,
  /\bgh[pousr]_[A-Za-z0-9]{20,}\b/u,
  /\bAKIA[0-9A-Z]{16}\b/u,
  /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/u,
]);

const FAILURE_MESSAGES = Object.freeze({
  continuity_invalid: "The continuity value does not satisfy the managed contract.",
  continuity_too_large: "The continuity value exceeds a managed bound.",
  continuity_forbidden: "The continuity value contains prohibited content.",
  continuity_degraded: "The continuity degradation is not permitted for this workflow.",
  pressure_invalid: "The context pressure counters are invalid.",
});

class ContinuityError extends Error {
  constructor(reasonCode) {
    const safeCode = CONTINUITY_REASON_CODES.has(reasonCode) ? reasonCode : "continuity_invalid";
    super(FAILURE_MESSAGES[safeCode] ?? FAILURE_MESSAGES.continuity_invalid);
    this.name = "ContinuityError";
    this.reason_code = safeCode;
  }
}

function throwContinuity(reasonCode = "continuity_invalid") {
  throw new ContinuityError(reasonCode);
}

function failure(error) {
  const reasonCode = CONTINUITY_REASON_CODES.has(error?.reason_code)
    ? error.reason_code
    : "continuity_invalid";
  return {
    ok: false,
    reason_code: reasonCode,
    message: FAILURE_MESSAGES[reasonCode] ?? FAILURE_MESSAGES.continuity_invalid,
  };
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

function ordinalCompare(left, right) {
  return left < right ? -1 : left > right ? 1 : 0;
}

function propertyVocabulary(value) {
  return value.normalize("NFKC").toLowerCase().replace(/[^a-z0-9]/gu, "");
}

function normalizeText(value, { maxBytes = CONTINUITY_LIMITS.maxStringBytes, nonEmpty = true } = {}) {
  if (typeof value !== "string") throwContinuity();
  for (let index = 0; index < value.length; index += 1) {
    const code = value.charCodeAt(index);
    if (code >= 0xd800 && code <= 0xdbff) {
      const next = value.charCodeAt(index + 1);
      if (!Number.isInteger(next) || next < 0xdc00 || next > 0xdfff) throwContinuity();
      index += 1;
    } else if (code >= 0xdc00 && code <= 0xdfff) {
      throwContinuity();
    }
  }
  const normalized = value.replace(/\r\n?/gu, "\n").normalize("NFC");
  if (normalized.includes("\0")) throwContinuity("continuity_forbidden");
  if (nonEmpty && normalized.trim().length === 0) throwContinuity();
  if (Buffer.byteLength(normalized, "utf8") > maxBytes) throwContinuity("continuity_too_large");
  for (const pattern of SECRET_PATTERNS) {
    if (pattern.test(normalized)) throwContinuity("continuity_forbidden");
  }
  return normalized;
}

function inspectGraph(value, { maxArrayItems = CONTINUITY_LIMITS.maxArrayItems } = {}) {
  const ancestors = new WeakSet();
  const visit = (node, depth) => {
    if (depth > CONTINUITY_LIMITS.maxDepth) throwContinuity("continuity_too_large");
    if (node === null || typeof node === "boolean") return;
    if (typeof node === "string") {
      normalizeText(node, { nonEmpty: false });
      return;
    }
    if (typeof node === "number") {
      if (!Number.isSafeInteger(node)) throwContinuity();
      return;
    }
    if (Array.isArray(node)) {
      if (node.length > maxArrayItems) throwContinuity("continuity_too_large");
      if (ancestors.has(node)) throwContinuity();
      ancestors.add(node);
      for (const item of node) visit(item, depth + 1);
      ancestors.delete(node);
      return;
    }
    if (!isPlainObject(node)) throwContinuity();
    if (ancestors.has(node)) throwContinuity();
    ancestors.add(node);
    for (const [key, child] of Object.entries(node)) {
      const normalizedKey = normalizeText(key);
      if (FORBIDDEN_PROPERTY_NAMES.has(propertyVocabulary(normalizedKey))) {
        throwContinuity("continuity_forbidden");
      }
      visit(child, depth + 1);
    }
    ancestors.delete(node);
  };
  visit(value, 0);
}

function normalizeIdentifier(value, pattern, maxBytes = 128) {
  const normalized = normalizeText(value, { maxBytes });
  if (!pattern.test(normalized)) throwContinuity();
  return normalized;
}

function normalizeHash(value) {
  return normalizeIdentifier(value, CONTINUITY_PATTERNS.sha256, 64);
}

function normalizeSafeInteger(value, { minimum = 0, maximum = Number.MAX_SAFE_INTEGER } = {}) {
  if (!Number.isSafeInteger(value) || value < minimum || value > maximum) throwContinuity();
  return value;
}

function normalizeStringArray(value, options = {}) {
  const maxItems = options.maxItems ?? CONTINUITY_LIMITS.maxArrayItems;
  if (!Array.isArray(value) || value.length > maxItems) {
    throwContinuity(value?.length > maxItems ? "continuity_too_large" : "continuity_invalid");
  }
  const result = value.map((item) => normalizeText(item, {
    maxBytes: options.maxBytes ?? 1_024,
    nonEmpty: options.nonEmpty ?? true,
  }));
  if (options.unique) {
    const seen = new Set();
    for (const item of result) if (seen.has(item) || !seen.add(item)) throwContinuity();
  }
  if (options.sort) result.sort(ordinalCompare);
  return result;
}

function normalizeRelativePath(value) {
  const normalized = normalizeText(value, { maxBytes: 1_024 });
  if (normalized.includes("\\") || normalized.startsWith("/") || /^[A-Za-z]:/u.test(normalized) ||
      normalized.split("/").some((part) => !part || part === "." || part === "..")) {
    throwContinuity("continuity_forbidden");
  }
  return normalized;
}

function normalizeWriteScope(value) {
  if (!Array.isArray(value) || value.length > CONTINUITY_LIMITS.maxArrayItems) {
    throwContinuity(value?.length > CONTINUITY_LIMITS.maxArrayItems ? "continuity_too_large" : "continuity_invalid");
  }
  const identities = new Set();
  const result = value.map((entry) => {
    if (!isPlainObject(entry) || !["exact", "subtree", "glob"].includes(entry.kind)) throwContinuity();
    const field = entry.kind === "glob" ? "pattern" : "path";
    if (!exactKeys(entry, ["kind", field])) throwContinuity();
    const normalized = { kind: entry.kind, [field]: normalizeRelativePath(entry[field]) };
    const identity = canonicalJson(normalized);
    if (identities.has(identity)) throwContinuity();
    identities.add(identity);
    return normalized;
  });
  result.sort((left, right) => ordinalCompare(canonicalJson(left), canonicalJson(right)));
  return result;
}

function normalizeAcceptanceCriteria(value) {
  if (!Array.isArray(value) || value.length > CONTINUITY_LIMITS.maxArrayItems) {
    throwContinuity(value?.length > CONTINUITY_LIMITS.maxArrayItems ? "continuity_too_large" : "continuity_invalid");
  }
  const seen = new Set();
  return value.map((item) => {
    if (!exactKeys(item, ["id", "text", "mandatory"]) || typeof item.mandatory !== "boolean") throwContinuity();
    const id = normalizeIdentifier(item.id, CONTINUITY_PATTERNS.acceptanceId, 83);
    if (seen.has(id)) throwContinuity();
    seen.add(id);
    return { id, text: normalizeText(item.text, { maxBytes: 2_048 }), mandatory: item.mandatory };
  });
}

function normalizeLockedDecisions(value) {
  if (!Array.isArray(value) || value.length > CONTINUITY_LIMITS.maxLockedDecisions) {
    throwContinuity(value?.length > CONTINUITY_LIMITS.maxLockedDecisions ? "continuity_too_large" : "continuity_invalid");
  }
  const seen = new Set();
  const result = value.map((item) => {
    if (!exactKeys(item, ["decision_id", "statement", "authority_ref"])) throwContinuity();
    const decisionId = normalizeIdentifier(item.decision_id, CONTINUITY_PATTERNS.decisionId, 66);
    if (seen.has(decisionId)) throwContinuity();
    seen.add(decisionId);
    return {
      decision_id: decisionId,
      statement: normalizeText(item.statement, { maxBytes: 2_048 }),
      authority_ref: normalizeText(item.authority_ref, { maxBytes: 512 }),
    };
  });
  result.sort((left, right) => ordinalCompare(left.decision_id, right.decision_id));
  return result;
}

function normalizeTask(value) {
  const keys = [
    "task_id", "workflow_class", "objective", "authority", "execution_mode", "write_scope",
    "acceptance_criteria", "obligations", "locked_decisions",
  ];
  if (!exactKeys(value, keys)) throwContinuity();
  const workflowClass = normalizeText(value.workflow_class, { maxBytes: 32 });
  if (!CONTINUITY_WORKFLOW_CLASSES.includes(workflowClass)) throwContinuity();
  const executionMode = normalizeText(value.execution_mode, { maxBytes: 32 });
  if (!["read_only", "mutating"].includes(executionMode)) throwContinuity();
  return {
    task_id: normalizeIdentifier(value.task_id, CONTINUITY_PATTERNS.taskId, 7),
    workflow_class: workflowClass,
    objective: normalizeText(value.objective),
    authority: normalizeStringArray(value.authority, { maxBytes: 512 }),
    execution_mode: executionMode,
    write_scope: normalizeWriteScope(value.write_scope),
    acceptance_criteria: normalizeAcceptanceCriteria(value.acceptance_criteria),
    obligations: normalizeStringArray(value.obligations, { maxBytes: 512 }),
    locked_decisions: normalizeLockedDecisions(value.locked_decisions),
  };
}

function normalizeLifecycle(value) {
  const keys = [
    "status", "owner_session_ref", "owner_runtime", "revision", "revision_id", "revision_sha256",
    "lease_generation",
  ];
  if (!exactKeys(value, keys)) throwContinuity();
  const status = normalizeText(value.status, { maxBytes: 32 });
  if (!CONTINUITY_ACTIVE_STATUSES.includes(status)) throwContinuity();
  if (value.owner_runtime !== "omp") throwContinuity();
  return {
    status,
    owner_session_ref: normalizeText(value.owner_session_ref, { maxBytes: 512 }),
    owner_runtime: "omp",
    revision: normalizeSafeInteger(value.revision, { minimum: 1 }),
    revision_id: normalizeIdentifier(value.revision_id, CONTINUITY_PATTERNS.revisionId, 7),
    revision_sha256: normalizeHash(value.revision_sha256),
    lease_generation: normalizeSafeInteger(value.lease_generation, { minimum: 1 }),
  };
}

function normalizeNullableIdentifier(value, pattern, maxBytes) {
  return value === null ? null : normalizeIdentifier(value, pattern, maxBytes);
}

function normalizeNullableText(value, maxBytes = 1_024) {
  return value === null ? null : normalizeText(value, { maxBytes });
}

function normalizeCheckpoint(value) {
  const keys = [
    "checkpoint_id", "checkpoint_sha256", "work_unit_id", "next_action", "blockers", "open_risks",
  ];
  if (!exactKeys(value, keys)) throwContinuity();
  const checkpointId = normalizeNullableIdentifier(value.checkpoint_id, CONTINUITY_PATTERNS.checkpointId, 8);
  const checkpointSha = value.checkpoint_sha256 === null ? null : normalizeHash(value.checkpoint_sha256);
  if ((checkpointId === null) !== (checkpointSha === null)) throwContinuity();
  return {
    checkpoint_id: checkpointId,
    checkpoint_sha256: checkpointSha,
    work_unit_id: normalizeNullableIdentifier(value.work_unit_id, CONTINUITY_PATTERNS.workUnitId, 83),
    next_action: normalizeNullableText(value.next_action),
    blockers: normalizeStringArray(value.blockers, { maxBytes: 1_024 }),
    open_risks: normalizeStringArray(value.open_risks, { maxBytes: 1_024 }),
  };
}

function normalizeCandidate(value) {
  if (!exactKeys(value, ["candidate_id", "candidate_hash", "candidate_sha256"])) throwContinuity();
  const candidateId = normalizeNullableIdentifier(value.candidate_id, CONTINUITY_PATTERNS.candidateId, 81);
  const candidateHash = value.candidate_hash === null ? null : normalizeHash(value.candidate_hash);
  const candidateSha = value.candidate_sha256 === null ? null : normalizeHash(value.candidate_sha256);
  const nullCount = [candidateId, candidateHash, candidateSha].filter((item) => item === null).length;
  if (nullCount !== 0 && nullCount !== 3 || candidateHash !== candidateSha) throwContinuity();
  return { candidate_id: candidateId, candidate_hash: candidateHash, candidate_sha256: candidateSha };
}

function normalizeEvidenceBindings(value) {
  if (!Array.isArray(value) || value.length > CONTINUITY_LIMITS.maxArrayItems) {
    throwContinuity(value?.length > CONTINUITY_LIMITS.maxArrayItems ? "continuity_too_large" : "continuity_invalid");
  }
  const seen = new Set();
  const result = value.map((item) => {
    if (!exactKeys(item, ["evidence_id", "record_sha256"])) throwContinuity();
    const evidenceId = normalizeIdentifier(item.evidence_id, CONTINUITY_PATTERNS.evidenceId, 7);
    if (seen.has(evidenceId)) throwContinuity();
    seen.add(evidenceId);
    return { evidence_id: evidenceId, record_sha256: normalizeHash(item.record_sha256) };
  });
  result.sort((left, right) => ordinalCompare(left.evidence_id, right.evidence_id));
  return result;
}

function normalizeDegradedFields(value) {
  const normalized = normalizeStringArray(value, {
    maxItems: CONTINUITY_LIMITS.maxDegradedFields,
    maxBytes: 64,
    unique: true,
    sort: true,
  });
  if (normalized.some((item) => !CONTINUITY_DEGRADED_FIELDS.includes(item))) {
    throwContinuity("continuity_degraded");
  }
  return normalized;
}

function validateDegradation(kernel) {
  const fields = kernel.degraded_fields;
  if (kernel.task.workflow_class !== "quick" && fields.length > 0) {
    throwContinuity("continuity_degraded");
  }
  if (kernel.task.workflow_class !== "quick") return;
  const absent = {
    checkpoint: kernel.checkpoint.checkpoint_id === null && kernel.checkpoint.checkpoint_sha256 === null,
    work_unit_id: kernel.checkpoint.work_unit_id === null,
    next_action: kernel.checkpoint.next_action === null,
    blockers: kernel.checkpoint.blockers.length === 0,
    open_risks: kernel.checkpoint.open_risks.length === 0,
    candidate: kernel.candidate.candidate_id === null && kernel.candidate.candidate_hash === null &&
      kernel.candidate.candidate_sha256 === null,
    evidence_bindings: kernel.evidence_bindings.length === 0,
  };
  if (fields.some((field) => absent[field] !== true)) throwContinuity("continuity_degraded");
}

function normalizeKernel(value) {
  inspectGraph(value);
  const topKeys = [
    "schema_version", "record_type", "task", "lifecycle", "checkpoint", "candidate",
    "evidence_bindings", "degraded_fields", "kernel_sha256",
  ];
  if (!exactKeys(value, topKeys) || value.schema_version !== 1 ||
      value.record_type !== "context_continuity_kernel") throwContinuity();
  const normalized = {
    schema_version: 1,
    record_type: "context_continuity_kernel",
    task: normalizeTask(value.task),
    lifecycle: normalizeLifecycle(value.lifecycle),
    checkpoint: normalizeCheckpoint(value.checkpoint),
    candidate: normalizeCandidate(value.candidate),
    evidence_bindings: normalizeEvidenceBindings(value.evidence_bindings),
    degraded_fields: normalizeDegradedFields(value.degraded_fields),
    kernel_sha256: normalizeHash(value.kernel_sha256),
  };
  validateDegradation(normalized);
  const withoutHash = structuredClone(normalized);
  delete withoutHash.kernel_sha256;
  if (sha256Canonical(withoutHash) !== normalized.kernel_sha256) throwContinuity();
  const canonical = canonicalJson(normalized);
  if (Buffer.byteLength(canonical, "utf8") > CONTINUITY_LIMITS.maxKernelBytes) {
    throwContinuity("continuity_too_large");
  }
  return normalized;
}

export function validateContinuityKernel(value) {
  try {
    return { ok: true, value: normalizeKernel(value) };
  } catch (error) {
    return failure(error);
  }
}

export function validateContinuityProjection(value) {
  return validateContinuityKernel(value);
}

export function buildContinuityKernel(projection) {
  try {
    const kernel = normalizeKernel(projection);
    const canonical = canonicalJson(kernel);
    return {
      ok: true,
      kernel,
      canonical,
      sha256: kernel.kernel_sha256,
      utf8_bytes: Buffer.byteLength(canonical, "utf8"),
    };
  } catch (error) {
    return failure(error);
  }
}

export function resolvePressureBoundary({ tokens, contextWindow, reserveTokens } = {}) {
  if (!Number.isSafeInteger(tokens) || tokens < 0 ||
      !Number.isSafeInteger(contextWindow) || contextWindow < 2 ||
      reserveTokens !== undefined && (!Number.isSafeInteger(reserveTokens) || reserveTokens < 0)) {
    throw new ContinuityError("pressure_invalid");
  }
  const proportional = Math.max(1, Math.floor(contextWindow * 0.15));
  const initial = Math.max(Math.floor(contextWindow * 0.15), reserveTokens ?? 16_384);
  const defaultImpossible = reserveTokens === undefined && initial >= contextWindow - proportional;
  const resolved = defaultImpossible || initial >= contextWindow ? proportional : initial;
  const threshold = Math.max(1, Math.min(contextWindow - 1, contextWindow - resolved));
  return { reserveTokens: resolved, thresholdTokens: threshold, atOrAbove: tokens >= threshold };
}

function normalizeEpochId(value) {
  return normalizeIdentifier(value, CONTINUITY_PATTERNS.epochId, 82);
}

function normalizeUtcTimestamp(value) {
  const normalized = normalizeIdentifier(value, CONTINUITY_PATTERNS.utcTimestamp, 24);
  if (!Number.isFinite(Date.parse(normalized))) throwContinuity();
  return normalized;
}

export function buildRecoveryArtifact(input) {
  try {
    inspectGraph(input, { maxArrayItems: CONTINUITY_LIMITS.maxBranchEntries });
    const keys = [
      "epoch_id", "created_at_utc", "expires_at_utc", "session_id_sha256", "session_file_sha256", "task_id",
      "task_revision_sha256", "lease_generation", "branch_sha256", "leaf_entry_id",
      "branch_entry_ids", "kernel",
    ];
    if (!exactKeys(input, keys)) throwContinuity();
    const kernel = normalizeKernel(input.kernel);
    const taskId = normalizeIdentifier(input.task_id, CONTINUITY_PATTERNS.taskId, 7);
    const taskRevisionSha = normalizeHash(input.task_revision_sha256);
    const leaseGeneration = normalizeSafeInteger(input.lease_generation, { minimum: 1 });
    if (taskId !== kernel.task.task_id || taskRevisionSha !== kernel.lifecycle.revision_sha256 ||
        leaseGeneration !== kernel.lifecycle.lease_generation) throwContinuity();
    const branchEntryIds = normalizeStringArray(input.branch_entry_ids, {
      maxItems: CONTINUITY_LIMITS.maxBranchEntries,
      maxBytes: 256,
      unique: true,
    });
    if (branchEntryIds.length === 0) throwContinuity();
    const leafEntryId = normalizeText(input.leaf_entry_id, { maxBytes: 256 });
    if (branchEntryIds.at(-1) !== leafEntryId) throwContinuity();
    const createdAtUtc = normalizeUtcTimestamp(input.created_at_utc);
    const expiresAtUtc = normalizeUtcTimestamp(input.expires_at_utc);
    const lifetimeMs = Date.parse(expiresAtUtc) - Date.parse(createdAtUtc);
    if (!Number.isSafeInteger(lifetimeMs) || lifetimeMs <= 0 || lifetimeMs > CONTINUITY_LIMITS.nonceTtlMs) {
      throwContinuity();
    }
    const artifactWithoutHash = {
      schema_version: 1,
      record_type: "context_continuity_recovery",
      epoch_id: normalizeEpochId(input.epoch_id),
      created_at_utc: createdAtUtc,
      expires_at_utc: expiresAtUtc,
      session_id_sha256: normalizeHash(input.session_id_sha256),
      session_file_sha256: normalizeHash(input.session_file_sha256),
      task_id: taskId,
      task_revision_sha256: taskRevisionSha,
      lease_generation: leaseGeneration,
      kernel_sha256: kernel.kernel_sha256,
      branch_sha256: normalizeHash(input.branch_sha256),
      leaf_entry_id: leafEntryId,
      branch_entry_ids: branchEntryIds,
      kernel,
    };
    const artifact = { ...artifactWithoutHash, artifact_sha256: sha256Canonical(artifactWithoutHash) };
    const canonical = canonicalJson(artifact);
    const utf8Bytes = Buffer.byteLength(canonical, "utf8");
    if (utf8Bytes > CONTINUITY_LIMITS.maxRecoveryArtifactBytes) throwContinuity("continuity_too_large");
    return { artifact, canonical, sha256: artifact.artifact_sha256, utf8_bytes: utf8Bytes };
  } catch (error) {
    if (error instanceof ContinuityError) throw error;
    throw new ContinuityError("continuity_invalid");
  }
}

function normalizePreserveIdentity(value, { withSchemaVersion = false } = {}) {
  const fields = [
    "epoch_id", "nonce_sha256", "task_id", "task_revision_sha256", "kernel_sha256",
    "branch_sha256", "recovery_artifact_id",
  ];
  const keys = withSchemaVersion ? ["schema_version", ...fields] : fields;
  if (!exactKeys(value, keys) || withSchemaVersion && value.schema_version !== 1) throwContinuity();
  return {
    ...(withSchemaVersion ? { schema_version: 1 } : {}),
    epoch_id: normalizeEpochId(value.epoch_id),
    nonce_sha256: normalizeHash(value.nonce_sha256),
    task_id: normalizeIdentifier(value.task_id, CONTINUITY_PATTERNS.taskId, 7),
    task_revision_sha256: normalizeHash(value.task_revision_sha256),
    kernel_sha256: normalizeHash(value.kernel_sha256),
    branch_sha256: normalizeHash(value.branch_sha256),
    recovery_artifact_id: normalizeText(value.recovery_artifact_id, { maxBytes: 512 }),
  };
}

export function buildPreserveData(input) {
  try {
    inspectGraph(input);
    return { "omp_template.topic07": normalizePreserveIdentity({ schema_version: 1, ...input }, { withSchemaVersion: true }) };
  } catch (error) {
    if (error instanceof ContinuityError) throw error;
    throw new ContinuityError("continuity_invalid");
  }
}

export function validatePreserveData(input, expected) {
  try {
    inspectGraph(input);
    inspectGraph(expected);
    if (!exactKeys(input, ["omp_template.topic07"])) throwContinuity();
    const value = { "omp_template.topic07": normalizePreserveIdentity(input["omp_template.topic07"], { withSchemaVersion: true }) };
    const expectedValue = isPlainObject(expected) && Object.hasOwn(expected, "omp_template.topic07")
      ? { "omp_template.topic07": normalizePreserveIdentity(expected["omp_template.topic07"], { withSchemaVersion: true }) }
      : { "omp_template.topic07": normalizePreserveIdentity({ schema_version: 1, ...expected }, { withSchemaVersion: true }) };
    if (canonicalJson(value) !== canonicalJson(expectedValue)) throwContinuity();
    return { ok: true, value };
  } catch (error) {
    return failure(error);
  }
}

export function buildKernelMessage(value) {
  const result = buildContinuityKernel(value);
  if (!result.ok) throw new ContinuityError(result.reason_code);
  return {
    role: "custom",
    customType: "topic07-continuity-kernel",
    content: `<context_continuity_kernel>\n${result.canonical}\n</context_continuity_kernel>`,
    display: false,
    attribution: "agent",
  };
}

function normalizeEnum(value, allowed) {
  const normalized = normalizeText(value, { maxBytes: 64 });
  if (!allowed.includes(normalized)) throwContinuity();
  return normalized;
}

export function buildObservation(input) {
  try {
    inspectGraph(input);
    const keys = [
      "component_version", "runtime_version", "session_sha256", "task_sha256", "epoch_sha256",
      "workflow_class", "context_tokens", "context_window", "threshold_tokens", "kernel_bytes",
      "kernel_sha256", "artifact_status", "preparation_status", "compaction_status",
      "validation_status", "reason_code", "degraded_fields", "settings_drift", "injection_status",
      "provider_action",
    ];
    if (!exactKeys(input, keys)) throwContinuity();
    const workflowClass = normalizeEnum(input.workflow_class, CONTINUITY_WORKFLOW_CLASSES);
    const contextWindow = normalizeSafeInteger(input.context_window, { minimum: 2 });
    const thresholdTokens = normalizeSafeInteger(input.threshold_tokens, { minimum: 1, maximum: contextWindow - 1 });
    const observation = {
      schema_version: 1,
      record_type: "context_continuity_observation",
      component_version: normalizeText(input.component_version, { maxBytes: 128 }),
      runtime_version: normalizeText(input.runtime_version, { maxBytes: 128 }),
      session_sha256: normalizeHash(input.session_sha256),
      task_sha256: normalizeHash(input.task_sha256),
      epoch_sha256: normalizeHash(input.epoch_sha256),
      workflow_class: workflowClass,
      context_tokens: normalizeSafeInteger(input.context_tokens),
      context_window: contextWindow,
      threshold_tokens: thresholdTokens,
      kernel_bytes: normalizeSafeInteger(input.kernel_bytes, { maximum: CONTINUITY_LIMITS.maxKernelBytes }),
      kernel_sha256: normalizeHash(input.kernel_sha256),
      artifact_status: normalizeEnum(input.artifact_status, CONTINUITY_OBSERVATION_ENUMS.artifactStatus),
      preparation_status: normalizeEnum(input.preparation_status, CONTINUITY_OBSERVATION_ENUMS.preparationStatus),
      compaction_status: normalizeEnum(input.compaction_status, CONTINUITY_OBSERVATION_ENUMS.compactionStatus),
      validation_status: normalizeEnum(input.validation_status, CONTINUITY_OBSERVATION_ENUMS.validationStatus),
      reason_code: normalizeText(input.reason_code, { maxBytes: 128 }),
      degraded_fields: normalizeDegradedFields(input.degraded_fields),
      settings_drift: normalizeStringArray(input.settings_drift, { maxBytes: 128, unique: true, sort: true }),
      injection_status: normalizeEnum(input.injection_status, CONTINUITY_OBSERVATION_ENUMS.injectionStatus),
      provider_action: normalizeEnum(input.provider_action, CONTINUITY_OBSERVATION_ENUMS.providerAction),
    };
    if (workflowClass !== "quick" && observation.degraded_fields.length > 0) {
      throwContinuity("continuity_degraded");
    }
    if (Buffer.byteLength(canonicalJson(observation), "utf8") > CONTINUITY_LIMITS.maxMetricBytes) {
      throwContinuity("continuity_too_large");
    }
    return observation;
  } catch (error) {
    if (error instanceof ContinuityError) throw error;
    throw new ContinuityError("continuity_invalid");
  }
}
