import crypto from "node:crypto";
import {
  ACCEPTANCE_ID_PATTERN,
  LIMITS,
  MANAGED_ROLES,
  OUTPUT_CONTRACTS,
  REASON_CODES,
  ROLE_POLICIES,
  RUNTIME_IDENTITIES,
  SEMANTIC_OUTPUT_SCHEMAS,
  SHA256_PATTERN,
  TASK_ID_PATTERN,
  WORK_UNIT_ID_PATTERN,
} from "./agent-boundary-schema.mjs";

const FORBIDDEN_PROPERTY_NAMES = new Set([
  "transcript",
  "conversation",
  "conversationhistory",
  "history",
  "toolhistory",
  "terminalhistory",
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
  "token",
  "privatekey",
  "secret",
  "secrets",
  "stdout",
  "stderr",
  "providerpayload",
  "statepath",
  "sessionpath",
]);

const SECRET_PATTERNS = Object.freeze([
  /(?:authorization\s*:\s*)?bearer\s+[A-Za-z0-9._~+/=-]{8,}/iu,
  /\beyJ[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{6,}\b/u,
  /\bgh[pousr]_[A-Za-z0-9]{20,}\b/u,
  /\bAKIA[0-9A-Z]{16}\b/u,
  /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/u,
]);

export class BoundaryError extends Error {
  constructor(reasonCode, message) {
    super(message);
    this.name = "BoundaryError";
    this.reason_code = REASON_CODES.has(reasonCode) ? reasonCode : "internal_error";
  }
}

function boundaryError(reasonCode, message) {
  return new BoundaryError(reasonCode, message);
}

function failure(reasonCode, message) {
  return {
    ok: false,
    reason_code: REASON_CODES.has(reasonCode) ? reasonCode : "internal_error",
    message: String(message).slice(0, 240) || "The managed boundary rejected the value.",
  };
}

function success(value) {
  return { ok: true, value };
}

function isPlainObject(value) {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function normalizeString(value) {
  if (typeof value !== "string") throw boundaryError("packet_invalid", "A string field has an invalid type.");
  for (let index = 0; index < value.length; index += 1) {
    const code = value.charCodeAt(index);
    if (code >= 0xd800 && code <= 0xdbff) {
      const next = value.charCodeAt(index + 1);
      if (!Number.isInteger(next) || next < 0xdc00 || next > 0xdfff) {
        throw boundaryError("packet_invalid", "A string contains invalid Unicode.");
      }
      index += 1;
    } else if (code >= 0xdc00 && code <= 0xdfff) {
      throw boundaryError("packet_invalid", "A string contains invalid Unicode.");
    }
  }
  if (value.includes("\0")) throw boundaryError("forbidden_content", "A string contains a forbidden control value.");
  const normalized = value.replace(/\r\n?/gu, "\n").normalize("NFC");
  if (Buffer.byteLength(normalized, "utf8") > LIMITS.maxStringBytes) {
    throw boundaryError("packet_too_large", "A string exceeds the managed boundary limit.");
  }
  return normalized;
}

function normalizePropertyName(value) {
  return normalizeString(value);
}

function propertyVocabulary(value) {
  return value.normalize("NFKC").toLowerCase().replace(/[^a-z0-9]/gu, "");
}

function assertSafePropertyName(value) {
  if (FORBIDDEN_PROPERTY_NAMES.has(propertyVocabulary(value))) {
    throw boundaryError("forbidden_content", "The value contains a forbidden property.");
  }
}

function assertSafeStringValue(value) {
  for (const pattern of SECRET_PATTERNS) {
    if (pattern.test(value)) throw boundaryError("forbidden_content", "The value contains secret-like content.");
  }
}

function normalizeNode(value, depth = 0, options = {}) {
  if (depth > LIMITS.maxDepth) {
    throw boundaryError("packet_too_large", "The value exceeds the managed nesting limit.");
  }
  if (value === null || typeof value === "boolean") return value;
  if (typeof value === "string") {
    const normalized = normalizeString(value);
    if (options.scanValues) assertSafeStringValue(normalized);
    return normalized;
  }
  if (typeof value === "number") {
    if (!Number.isSafeInteger(value)) throw boundaryError("packet_invalid", "Only safe integer numbers are supported.");
    return value;
  }
  if (Array.isArray(value)) {
    if (value.length > LIMITS.maxArrayItems) {
      throw boundaryError("packet_too_large", "An array exceeds the managed boundary limit.");
    }
    return value.map((item) => normalizeNode(item, depth + 1, options));
  }
  if (!isPlainObject(value)) throw boundaryError("packet_invalid", "The value is not JSON-compatible.");
  const output = {};
  const seen = new Set();
  for (const rawKey of Object.keys(value)) {
    const key = normalizePropertyName(rawKey);
    if (seen.has(key)) throw boundaryError("packet_invalid", "An object contains duplicate normalized properties.");
    seen.add(key);
    if (options.scanPropertyNames) assertSafePropertyName(key);
    output[key] = normalizeNode(value[rawKey], depth + 1, options);
  }
  return output;
}

function encodeCanonical(value) {
  if (value === null) return "null";
  if (typeof value === "boolean") return value ? "true" : "false";
  if (typeof value === "number") return String(value);
  if (typeof value === "string") return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(encodeCanonical).join(",")}]`;
  const keys = Object.keys(value).sort((left, right) => (left < right ? -1 : left > right ? 1 : 0));
  return `{${keys.map((key) => `${JSON.stringify(key)}:${encodeCanonical(value[key])}`).join(",")}}`;
}

export function canonicalJson(value) {
  return encodeCanonical(normalizeNode(value));
}

export function sha256Canonical(value) {
  return crypto.createHash("sha256").update(canonicalJson(value), "utf8").digest("hex");
}

class ClosedJsonParser {
  constructor(text) {
    if (typeof text !== "string") throw boundaryError("packet_invalid", "JSON input must be text.");
    if (Buffer.byteLength(text, "utf8") > LIMITS.maxInputBytes) {
      throw boundaryError("packet_too_large", "JSON input exceeds the managed boundary limit.");
    }
    this.text = text;
    this.index = 0;
  }

  parse() {
    this.skipWhitespace();
    const value = this.parseValue(0);
    this.skipWhitespace();
    if (this.index !== this.text.length) throw boundaryError("packet_invalid", "JSON input has trailing content.");
    return value;
  }

  skipWhitespace() {
    while (this.index < this.text.length && /[\u0009\u000a\u000d\u0020]/u.test(this.text[this.index])) {
      this.index += 1;
    }
  }

  parseValue(depth) {
    if (depth > LIMITS.maxDepth) throw boundaryError("packet_too_large", "JSON input exceeds the nesting limit.");
    this.skipWhitespace();
    const current = this.text[this.index];
    if (current === "{") return this.parseObject(depth);
    if (current === "[") return this.parseArray(depth);
    if (current === '"') return this.parseString();
    if (current === "t" && this.text.slice(this.index, this.index + 4) === "true") {
      this.index += 4;
      return true;
    }
    if (current === "f" && this.text.slice(this.index, this.index + 5) === "false") {
      this.index += 5;
      return false;
    }
    if (current === "n" && this.text.slice(this.index, this.index + 4) === "null") {
      this.index += 4;
      return null;
    }
    return this.parseNumber();
  }

  parseObject(depth) {
    this.index += 1;
    this.skipWhitespace();
    const output = {};
    const seen = new Set();
    if (this.text[this.index] === "}") {
      this.index += 1;
      return output;
    }
    while (this.index < this.text.length) {
      if (this.text[this.index] !== '"') throw boundaryError("packet_invalid", "An object key is invalid.");
      const key = this.parseString();
      if (seen.has(key)) throw boundaryError("packet_invalid", "JSON input contains a duplicate property.");
      seen.add(key);
      this.skipWhitespace();
      if (this.text[this.index] !== ":") throw boundaryError("packet_invalid", "An object separator is invalid.");
      this.index += 1;
      output[key] = this.parseValue(depth + 1);
      this.skipWhitespace();
      if (this.text[this.index] === "}") {
        this.index += 1;
        return output;
      }
      if (this.text[this.index] !== ",") throw boundaryError("packet_invalid", "An object terminator is invalid.");
      this.index += 1;
      this.skipWhitespace();
    }
    throw boundaryError("packet_invalid", "JSON input contains an unterminated object.");
  }

  parseArray(depth) {
    this.index += 1;
    this.skipWhitespace();
    const output = [];
    if (this.text[this.index] === "]") {
      this.index += 1;
      return output;
    }
    while (this.index < this.text.length) {
      if (output.length >= LIMITS.maxArrayItems) {
        throw boundaryError("packet_too_large", "JSON input contains an oversized array.");
      }
      output.push(this.parseValue(depth + 1));
      this.skipWhitespace();
      if (this.text[this.index] === "]") {
        this.index += 1;
        return output;
      }
      if (this.text[this.index] !== ",") throw boundaryError("packet_invalid", "An array terminator is invalid.");
      this.index += 1;
      this.skipWhitespace();
    }
    throw boundaryError("packet_invalid", "JSON input contains an unterminated array.");
  }

  parseString() {
    const start = this.index;
    this.index += 1;
    let escaped = false;
    while (this.index < this.text.length) {
      const character = this.text[this.index];
      if (!escaped && character === '"') {
        this.index += 1;
        let decoded;
        try {
          decoded = JSON.parse(this.text.slice(start, this.index));
        } catch {
          throw boundaryError("packet_invalid", "JSON input contains an invalid string.");
        }
        return normalizeString(decoded);
      }
      if (!escaped && character.charCodeAt(0) < 0x20) {
        throw boundaryError("packet_invalid", "JSON input contains an invalid control character.");
      }
      if (!escaped && character === "\\") escaped = true;
      else escaped = false;
      this.index += 1;
    }
    throw boundaryError("packet_invalid", "JSON input contains an unterminated string.");
  }

  parseNumber() {
    const remainder = this.text.slice(this.index);
    const match = remainder.match(/^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/u);
    if (!match) throw boundaryError("packet_invalid", "JSON input contains an invalid value.");
    this.index += match[0].length;
    const number = Number(match[0]);
    if (!Number.isSafeInteger(number)) throw boundaryError("packet_invalid", "Only safe integer numbers are supported.");
    return number;
  }
}

export function parseJsonNoDuplicateKeys(text) {
  return new ClosedJsonParser(text).parse();
}

function exactKeys(value, allowed, required = allowed) {
  if (!isPlainObject(value)) return false;
  const actual = Object.keys(value);
  return actual.every((key) => allowed.includes(key)) && required.every((key) => Object.hasOwn(value, key));
}

function normalizedSafeValue(value, options = {}) {
  return normalizeNode(value, 0, {
    scanPropertyNames: options.scanPropertyNames === true,
    scanValues: options.scanValues === true,
  });
}

function isRelativePath(value) {
  if (typeof value !== "string" || !value || value.includes("\\")) return false;
  if (/^(?:[A-Za-z]:|\/|~\/|\\\\)/u.test(value)) return false;
  const parts = value.split("/");
  return parts.every((part) => part && part !== "." && part !== "..");
}

function isAbsolutePath(value) {
  return typeof value === "string" && /^(?:[A-Za-z]:[\\/]|\/|\\\\)/u.test(value);
}

function validateManagedItem(input) {
  const allowed = ["task_id", "work_unit_id", "agent", "role", "effort", "isolated"];
  const required = ["task_id", "work_unit_id", "agent", "role"];
  if (!exactKeys(input, allowed, required)) return failure("packet_invalid", "A managed task item has an invalid shape.");
  let value;
  try {
    value = normalizedSafeValue(input);
  } catch (error) {
    return error instanceof BoundaryError ? failure(error.reason_code, error.message) : failure("internal_error", "Managed request validation failed.");
  }
  if (!TASK_ID_PATTERN.test(value.task_id) || !WORK_UNIT_ID_PATTERN.test(value.work_unit_id)) {
    return failure("packet_invalid", "A managed task identity is invalid.");
  }
  const policy = MANAGED_ROLES[value.agent];
  if (!policy || value.role !== policy.role) {
    return failure("work_unit_incompatible", "The selected agent and role do not match.");
  }
  if (value.agent === "worker") {
    if (Object.hasOwn(value, "effort") && !policy.effort.includes(value.effort)) {
      return failure("work_unit_incompatible", "The selected Worker effort is unsupported.");
    }
    if (Object.hasOwn(value, "isolated") && typeof value.isolated !== "boolean") {
      return failure("work_unit_incompatible", "The selected isolation value is invalid.");
    }
  } else if (Object.hasOwn(value, "effort") || Object.hasOwn(value, "isolated")) {
    return failure("work_unit_incompatible", "The selected role does not accept caller runtime controls.");
  }
  return success(value);
}

export function validateManagedRequest(input) {
  if (!isPlainObject(input)) return failure("packet_invalid", "The managed request must be an object.");
  if (Object.hasOwn(input, "tasks")) {
    if (!exactKeys(input, ["tasks"]) || !Array.isArray(input.tasks) || input.tasks.length === 0) {
      return failure("packet_invalid", "A managed batch has an invalid shape.");
    }
    if (input.tasks.length > LIMITS.maxBatchItems) {
      return failure("packet_too_large", "A managed batch exceeds the item limit.");
    }
    const items = [];
    for (const item of input.tasks) {
      const result = validateManagedItem(item);
      if (!result.ok) return result;
      items.push(result.value);
    }
    const taskIds = new Set(items.map((item) => item.task_id));
    if (taskIds.size !== 1) return failure("work_unit_incompatible", "Managed batch items must share one task.");
    const workUnits = new Set(items.map((item) => item.work_unit_id));
    if (workUnits.size !== items.length) return failure("packet_invalid", "Managed batch work units must be unique.");
    return success({ tasks: items });
  }
  return validateManagedItem(input);
}

function validateStringArray(value, { allowEmpty = true, paths = false, unique = false, maxItems = LIMITS.maxArrayItems, maxLength = 1024 } = {}) {
  if (!Array.isArray(value) || (!allowEmpty && value.length === 0) || value.length > maxItems) return false;
  const seen = new Set();
  for (const item of value) {
    if (typeof item !== "string" || !item || item.length > maxLength) return false;
    if (paths && !isRelativePath(item)) return false;
    if (unique && seen.has(item)) return false;
    seen.add(item);
  }
  return true;
}

function validateAcceptanceCriteria(value) {
  if (!Array.isArray(value) || value.length > 64) return false;
  const seen = new Set();
  for (const criterion of value) {
    if (!exactKeys(criterion, ["id", "text", "mandatory"]) ||
        typeof criterion.id !== "string" || !ACCEPTANCE_ID_PATTERN.test(criterion.id) ||
        typeof criterion.text !== "string" || !criterion.text || criterion.text.length > 1024 || typeof criterion.mandatory !== "boolean" ||
        seen.has(criterion.id)) return false;
    seen.add(criterion.id);
  }
  return true;
}

function validateWriteScope(value) {
  if (!Array.isArray(value) || value.length > 64) return false;
  for (const row of value) {
    if (!isPlainObject(row) || typeof row.kind !== "string") return false;
    if (row.kind === "exact" || row.kind === "subtree") {
      if (!exactKeys(row, ["kind", "path"]) || !isRelativePath(row.path)) return false;
    } else if (row.kind === "glob") {
      if (!exactKeys(row, ["kind", "pattern"]) || typeof row.pattern !== "string" || !row.pattern ||
          isAbsolutePath(row.pattern) || row.pattern.split(/[\\/]/u).includes("..")) return false;
    } else return false;
  }
  return true;
}

export function validateProjection(input) {
  try {
    const value = normalizedSafeValue(input, { scanPropertyNames: true, scanValues: true });
    if (!exactKeys(value, ["schema_version", "record_type", "task", "work_unit", "binding", "cas", "projection_sha256"]) ||
        value.schema_version !== 1 || value.record_type !== "work_unit_projection") {
      return failure("packet_invalid", "The work-unit projection has an invalid shape.");
    }
    if (!exactKeys(value.task, [
      "task_id", "status", "objective", "authority", "execution_mode", "write_scope",
      "acceptance_criteria", "obligations", "owned_ignored_outputs",
    ]) || !TASK_ID_PATTERN.test(value.task.task_id) || typeof value.task.status !== "string" ||
        typeof value.task.objective !== "string" || !value.task.objective ||
        !validateStringArray(value.task.authority, { allowEmpty: false }) ||
        !["mutating", "read_only"].includes(value.task.execution_mode) ||
        !validateWriteScope(value.task.write_scope) || !validateAcceptanceCriteria(value.task.acceptance_criteria) ||
        !validateStringArray(value.task.obligations) ||
        !validateStringArray(value.task.owned_ignored_outputs, { paths: true, unique: true })) {
      return failure("packet_invalid", "The projected task contract is invalid.");
    }
    if (!exactKeys(value.work_unit, [
      "work_unit_id", "inputs", "outputs", "ownership", "dependencies", "completion_conditions",
    ]) || !WORK_UNIT_ID_PATTERN.test(value.work_unit.work_unit_id) ||
        !validateStringArray(value.work_unit.inputs) || !validateStringArray(value.work_unit.outputs) ||
        !validateStringArray(value.work_unit.ownership, { paths: true, unique: true }) ||
        !validateStringArray(value.work_unit.dependencies, { unique: true }) ||
        !validateStringArray(value.work_unit.completion_conditions)) {
      const pathFailure = Array.isArray(value.work_unit?.ownership) && value.work_unit.ownership.some((item) =>
        typeof item === "string" && !isRelativePath(item));
      return failure(pathFailure ? "forbidden_content" : "packet_invalid", "The projected work-unit contract is invalid.");
    }
    if (!exactKeys(value.binding, [
      "observation_worktree", "authoritative_worktree", "candidate_id", "candidate_sha256", "diff_ref", "artifact_refs",
    ]) || typeof value.binding.observation_worktree !== "string" || !isAbsolutePath(value.binding.observation_worktree) ||
        !(value.binding.authoritative_worktree === null || (typeof value.binding.authoritative_worktree === "string" && isAbsolutePath(value.binding.authoritative_worktree))) ||
        !(value.binding.candidate_id === null || (typeof value.binding.candidate_id === "string" && value.binding.candidate_id)) ||
        !(value.binding.candidate_sha256 === null || (typeof value.binding.candidate_sha256 === "string" && SHA256_PATTERN.test(value.binding.candidate_sha256))) ||
        !(value.binding.diff_ref === null || (typeof value.binding.diff_ref === "string" && SHA256_PATTERN.test(value.binding.diff_ref))) ||
        !validateStringArray(value.binding.artifact_refs, { paths: true, unique: true, maxItems: 64 })) {
      return failure("packet_invalid", "The projected runtime binding is invalid.");
    }
    if ((value.binding.candidate_id === null) !== (value.binding.candidate_sha256 === null)) {
      return failure("work_unit_incompatible", "The projected candidate identity is incomplete.");
    }
    if (!exactKeys(value.cas, ["revision", "revision_sha256", "lease_generation"]) ||
        !Number.isSafeInteger(value.cas.revision) || value.cas.revision < 1 ||
        typeof value.cas.revision_sha256 !== "string" || !SHA256_PATTERN.test(value.cas.revision_sha256) ||
        !Number.isSafeInteger(value.cas.lease_generation) || value.cas.lease_generation < 0 ||
        typeof value.projection_sha256 !== "string" || !SHA256_PATTERN.test(value.projection_sha256)) {
      return failure("packet_invalid", "The projected CAS binding is invalid.");
    }
    const projectionWithoutHash = { ...value };
    delete projectionWithoutHash.projection_sha256;
    if (sha256Canonical(projectionWithoutHash).toLowerCase() !== value.projection_sha256.toLowerCase()) {
      return failure("candidate_drift", "The work-unit projection hash is stale.");
    }
    return success(value);
  } catch (error) {
    return error instanceof BoundaryError ? failure(error.reason_code, error.message) : failure("internal_error", "Projection validation failed.");
  }
}

function validatePathArray(value) {
  return validateStringArray(value, { paths: true, unique: true });
}

export function validatePacket(input) {
  try {
    const value = normalizedSafeValue(input, { scanPropertyNames: true, scanValues: true });
    if (!exactKeys(value, [
      "schema_version", "packet_type", "role", "objective", "scope", "acceptance_criteria", "inputs",
      "constraints", "completion_conditions", "quality_gates", "output_contract", "overlay",
    ]) || value.schema_version !== 1 || value.packet_type !== "agent_dispatch" ||
        !Object.hasOwn(OUTPUT_CONTRACTS, value.role) || typeof value.objective !== "string" || !value.objective ||
        value.output_contract !== OUTPUT_CONTRACTS[value.role]) {
      return failure("packet_invalid", "The agent packet has an invalid base shape.");
    }
    if (!exactKeys(value.scope, ["in_scope", "out_of_scope", "ownership"]) ||
        !validatePathArray(value.scope.in_scope) || !validatePathArray(value.scope.out_of_scope) ||
        !validatePathArray(value.scope.ownership) || !validateAcceptanceCriteria(value.acceptance_criteria) ||
        !exactKeys(value.inputs, ["relevant_files", "artifact_refs", "candidate_ref", "diff_ref"]) ||
        !validatePathArray(value.inputs.relevant_files) || !validateStringArray(value.inputs.artifact_refs, { paths: true, unique: true, maxItems: 64 }) ||
        !(value.inputs.candidate_ref === null || typeof value.inputs.candidate_ref === "string") ||
        !(value.inputs.diff_ref === null || typeof value.inputs.diff_ref === "string") ||
        !validateStringArray(value.constraints) || !validateStringArray(value.completion_conditions) ||
        !validateStringArray(value.quality_gates) || !isPlainObject(value.overlay)) {
      const allPaths = [
        ...(Array.isArray(value.scope?.in_scope) ? value.scope.in_scope : []),
        ...(Array.isArray(value.scope?.out_of_scope) ? value.scope.out_of_scope : []),
        ...(Array.isArray(value.scope?.ownership) ? value.scope.ownership : []),
        ...(Array.isArray(value.inputs?.relevant_files) ? value.inputs.relevant_files : []),
      ];
      const unsafePath = allPaths.some((item) => typeof item === "string" && !isRelativePath(item));
      return failure(unsafePath ? "forbidden_content" : "packet_invalid", "The agent packet contains invalid fields.");
    }
    const canonical = canonicalJson(value);
    if (Buffer.byteLength(canonical, "utf8") > LIMITS.maxPacketBytes) {
      return failure("packet_too_large", "The agent packet exceeds the byte limit.");
    }
    return success(value);
  } catch (error) {
    return error instanceof BoundaryError ? failure(error.reason_code, error.message) : failure("internal_error", "Packet validation failed.");
  }
}

function uniqueInOrder(values) {
  const seen = new Set();
  const output = [];
  for (const value of values) {
    if (!seen.has(value)) {
      seen.add(value);
      output.push(value);
    }
  }
  return output;
}

function globPatternToRegExp(pattern) {
  let expression = "^";
  for (let index = 0; index < pattern.length; index += 1) {
    const character = pattern[index];
    if (character === "*") {
      if (pattern[index + 1] === "*") {
        expression += ".*";
        index += 1;
      } else expression += "[^/]*";
    } else if (character === "?") expression += "[^/]";
    else expression += character.replace(/[\\^$.*+?()[\]{}|]/gu, "\\$&");
  }
  return new RegExp(`${expression}$`, "u");
}

function pathInsideScope(candidate, scope) {
  if (!isRelativePath(candidate)) return false;
  return scope.some((row) => {
    if (row.kind === "exact") return candidate === row.path;
    if (row.kind === "subtree") return candidate === row.path || candidate.startsWith(`${row.path}/`);
    if (row.kind === "glob") return globPatternToRegExp(row.pattern).test(candidate);
    return false;
  });
}

function pathInsideOwnership(candidate, ownership) {
  return ownership.some((owned) => candidate === owned || candidate.startsWith(`${owned}/`));
}

function agentPacketResult(packet) {
  const lint = validatePacket(packet);
  if (!lint.ok) return lint;
  const canonical = canonicalJson(lint.value);
  return {
    ok: true,
    packet: lint.value,
    canonical,
    packet_sha256: sha256Canonical(lint.value),
    utf8_bytes: Buffer.byteLength(canonical, "utf8"),
  };
}

function composeRoleOverlay(role, request, projection, inScope) {
  if (role === "cheap_scout") {
    return {
      question: projection.task.objective,
      source_fitness_guidance: ROLE_POLICIES.cheap_scout.overlay.source_fitness_guidance,
      allowed_capabilities: [...ROLE_POLICIES.cheap_scout.overlay.allowed_capabilities],
      evidence_requirements: [...ROLE_POLICIES.cheap_scout.overlay.evidence_requirements],
      retrieval_contract: { ...ROLE_POLICIES.cheap_scout.overlay.retrieval_contract },
      stop_condition: ROLE_POLICIES.cheap_scout.overlay.stop_condition,
    };
  }
  if (role === "worker") {
    return {
      ownership: [...projection.work_unit.ownership],
      permitted_outputs: [...projection.work_unit.outputs],
      verification_commands: [...projection.work_unit.completion_conditions],
      mutation_intent: "mutating",
      isolation_intent: request.isolated === true ? "isolated" : "retained_worktree",
    };
  }
  return {
    concern_profile: {
      concerns: [...projection.work_unit.completion_conditions],
      evidence_obligations: [...projection.task.obligations],
      scope: [...inScope],
      severity_boundary: ROLE_POLICIES.reviewer.severity_boundary,
      stop_condition: ROLE_POLICIES.reviewer.stop_condition,
    },
    verification_commands: [],
    exclusions: [
      "prior_agent_narrative",
      "prior_agent_status",
      "prior_agent_verdict",
      "prior_agent_quality_rating",
    ],
    prior_accepted_dispositions: [],
  };
}

export function composeAgentPacket(input) {
  try {
    const normalized = normalizedSafeValue(input, { scanPropertyNames: true, scanValues: true });
    if (!exactKeys(normalized, ["request", "projection"])) {
      return failure("packet_invalid", "Agent packet composition has an invalid input shape.");
    }
    const requestResult = validateManagedRequest(normalized.request);
    if (!requestResult.ok) return requestResult;
    if (Object.hasOwn(requestResult.value, "tasks")) {
      return failure("packet_invalid", "Compose one agent packet at a time.");
    }
    const projectionResult = validateProjection(normalized.projection);
    if (!projectionResult.ok) return projectionResult;
    const request = requestResult.value;
    const projection = projectionResult.value;
    if (request.task_id !== projection.task.task_id || request.work_unit_id !== projection.work_unit.work_unit_id) {
      return failure("candidate_drift", "Managed request and projected authority identities differ.");
    }
    const role = request.role;
    if (!Object.hasOwn(ROLE_POLICIES, role)) {
      return failure("work_unit_incompatible", "The selected role has no packet policy.");
    }
    const relevantFiles = [...projection.work_unit.inputs];
    const outputs = [...projection.work_unit.outputs];
    const ownership = [...projection.work_unit.ownership];
    if (![...relevantFiles, ...outputs, ...ownership].every(isRelativePath)) {
      return failure("work_unit_incompatible", "The work unit contains a non-project-relative path.");
    }

    if (role === "cheap_scout") {
      if (ownership.length > 0 || outputs.length > 0 || projection.binding.candidate_id !== null) {
        return failure("work_unit_incompatible", "Cheap Scout requires a read-only retrieval work unit.");
      }
    } else if (role === "worker") {
      if (projection.task.execution_mode !== "mutating" || ownership.length === 0 ||
          !["active", "partial", "rework"].includes(projection.task.status) ||
          !ownership.every((item) => pathInsideScope(item, projection.task.write_scope)) ||
          !outputs.every((item) => pathInsideOwnership(item, ownership))) {
        return failure("work_unit_incompatible", "Worker ownership or output exceeds the accepted task scope.");
      }
    } else if (role === "reviewer") {
      if (ownership.length > 0 || !["candidate_frozen", "verifying", "reviewing"].includes(projection.task.status) ||
          projection.binding.candidate_id === null || projection.binding.candidate_sha256 === null ||
          projection.binding.diff_ref === null || projection.binding.artifact_refs.length === 0) {
        return failure("work_unit_incompatible", "Reviewer requires a frozen candidate with diff and artifact bindings.");
      }
    }

    const inScope = uniqueInOrder([...relevantFiles, ...outputs, ...ownership]);
    const packet = {
      schema_version: 1,
      packet_type: "agent_dispatch",
      role,
      objective: projection.task.objective,
      scope: {
        in_scope: inScope,
        out_of_scope: [],
        ownership: role === "worker" ? ownership : [],
      },
      acceptance_criteria: projection.task.acceptance_criteria.map((criterion) => ({ ...criterion })),
      inputs: {
        relevant_files: relevantFiles,
        artifact_refs: [...projection.binding.artifact_refs],
        candidate_ref: role === "reviewer" ? "selected_frozen_candidate" : null,
        diff_ref: role === "reviewer" ? "selected_candidate_diff" : null,
      },
      constraints: [...ROLE_POLICIES[role].constraints, ...projection.task.obligations],
      completion_conditions: [...projection.work_unit.completion_conditions],
      quality_gates: [...ROLE_POLICIES[role].quality_gates],
      output_contract: OUTPUT_CONTRACTS[role],
      overlay: composeRoleOverlay(role, request, projection, inScope),
    };
    return agentPacketResult(packet);
  } catch (error) {
    return error instanceof BoundaryError ? failure(error.reason_code, error.message) : failure("internal_error", "Agent packet composition failed.");
  }
}

function validateEvidenceBindings(value) {
  if (!Array.isArray(value) || value.length > 64) return false;
  const seen = new Set();
  for (const binding of value) {
    if (!exactKeys(binding, ["evidence_id", "record_hash"]) ||
        typeof binding.evidence_id !== "string" || !/^E[0-9]{6}$/u.test(binding.evidence_id) ||
        typeof binding.record_hash !== "string" || !SHA256_PATTERN.test(binding.record_hash) ||
        seen.has(binding.evidence_id)) return false;
    seen.add(binding.evidence_id);
  }
  return true;
}

function validateHandoffParts(value, projectionShape) {
  const expectedTop = projectionShape ? [
    "schema_version", "record_type", "task_contract", "candidate", "lifecycle", "successor", "transfer", "projection_sha256",
  ] : ["schema_version", "packet_type", "task_contract", "candidate", "lifecycle", "successor", "transfer"];
  if (!exactKeys(value, expectedTop) || value.schema_version !== 1 ||
      (projectionShape ? value.record_type !== "handoff_projection" : value.packet_type !== "session_handoff")) return false;
  if (!exactKeys(value.task_contract, [
    "task_id", "objective", "authority", "acceptance_criteria", "obligations", "execution_mode", "write_scope",
    "owned_ignored_outputs", "task_contract_sha256",
  ]) || !TASK_ID_PATTERN.test(value.task_contract.task_id) ||
      typeof value.task_contract.objective !== "string" || !value.task_contract.objective ||
      !validateStringArray(value.task_contract.authority, { allowEmpty: false }) ||
      !validateAcceptanceCriteria(value.task_contract.acceptance_criteria) ||
      !validateStringArray(value.task_contract.obligations) ||
      !["mutating", "read_only"].includes(value.task_contract.execution_mode) ||
      !validateWriteScope(value.task_contract.write_scope) ||
      !validateStringArray(value.task_contract.owned_ignored_outputs, { paths: true, unique: true }) ||
      !SHA256_PATTERN.test(value.task_contract.task_contract_sha256)) return false;
  if (!exactKeys(value.candidate, [
    "candidate_id", "candidate_sha256", "diff_ref", "artifact_refs", "evidence_bindings", "workspace_snapshot_sha256",
  ]) || !(value.candidate.candidate_id === null || (typeof value.candidate.candidate_id === "string" && /^C[0-9]+$/u.test(value.candidate.candidate_id))) ||
      !(value.candidate.candidate_sha256 === null || (typeof value.candidate.candidate_sha256 === "string" && SHA256_PATTERN.test(value.candidate.candidate_sha256))) ||
      !(value.candidate.diff_ref === null || (typeof value.candidate.diff_ref === "string" && SHA256_PATTERN.test(value.candidate.diff_ref))) ||
      !validateStringArray(value.candidate.artifact_refs, { paths: true, unique: true, maxItems: 64 }) ||
      !validateEvidenceBindings(value.candidate.evidence_bindings) ||
      typeof value.candidate.workspace_snapshot_sha256 !== "string" || !SHA256_PATTERN.test(value.candidate.workspace_snapshot_sha256) ||
      ((value.candidate.candidate_id === null) !== (value.candidate.candidate_sha256 === null)) ||
      ((value.candidate.candidate_id === null) !== (value.candidate.diff_ref === null))) return false;
  if (!exactKeys(value.lifecycle, ["status", "prior_status", "next_action", "blockers", "open_risks"]) ||
      value.lifecycle.status !== "transferring" || typeof value.lifecycle.prior_status !== "string" || !value.lifecycle.prior_status ||
      typeof value.lifecycle.next_action !== "string" || !value.lifecycle.next_action || value.lifecycle.next_action.length > 1024 ||
      !validateStringArray(value.lifecycle.blockers, { maxItems: 16 }) ||
      !validateStringArray(value.lifecycle.open_risks, { maxItems: 16 })) return false;
  if (!exactKeys(value.successor, ["session_ref", "runtime"]) ||
      typeof value.successor.session_ref !== "string" || !value.successor.session_ref || value.successor.session_ref.length > 1024 ||
      typeof value.successor.runtime !== "string" || !value.successor.runtime || value.successor.runtime.length > 1024) return false;
  if (!exactKeys(value.transfer, [
    "task_id", "handoff_id", "handoff_sha256", "predecessor_revision", "predecessor_revision_sha256",
    "revision", "revision_sha256", "lease_generation",
  ]) || value.transfer.task_id !== value.task_contract.task_id || !/^H[0-9]{6}$/u.test(value.transfer.handoff_id) ||
      !SHA256_PATTERN.test(value.transfer.handoff_sha256) || !Number.isSafeInteger(value.transfer.predecessor_revision) || value.transfer.predecessor_revision < 1 ||
      !SHA256_PATTERN.test(value.transfer.predecessor_revision_sha256) || !Number.isSafeInteger(value.transfer.revision) ||
      value.transfer.revision <= value.transfer.predecessor_revision || !SHA256_PATTERN.test(value.transfer.revision_sha256) ||
      !Number.isSafeInteger(value.transfer.lease_generation) || value.transfer.lease_generation < 1) return false;
  return true;
}

export function composeHandoffPacket(input) {
  try {
    const normalized = normalizedSafeValue(input, { scanPropertyNames: true, scanValues: true });
    if (!exactKeys(normalized, ["handoff_projection"])) {
      return failure("packet_invalid", "Handoff composition has an invalid input shape.");
    }
    const projection = normalized.handoff_projection;
    if (!validateHandoffParts(projection, true)) {
      return failure("packet_invalid", "The atomic handoff projection is invalid.");
    }
    const withoutHash = { ...projection };
    delete withoutHash.projection_sha256;
    if (sha256Canonical(withoutHash).toLowerCase() !== projection.projection_sha256.toLowerCase()) {
      return failure("candidate_drift", "The atomic handoff projection hash is stale.");
    }
    const packet = {
      schema_version: 1,
      packet_type: "session_handoff",
      task_contract: projection.task_contract,
      candidate: projection.candidate,
      lifecycle: projection.lifecycle,
      successor: projection.successor,
      transfer: projection.transfer,
    };
    const validation = validateHandoffPacket(packet);
    if (!validation.ok) return validation;
    const canonical = canonicalJson(validation.value);
    if (Buffer.byteLength(canonical, "utf8") > LIMITS.maxPacketBytes) {
      return failure("packet_too_large", "The handoff packet exceeds the byte limit.");
    }
    return {
      ok: true,
      packet: validation.value,
      canonical,
      packet_sha256: sha256Canonical(validation.value),
      utf8_bytes: Buffer.byteLength(canonical, "utf8"),
    };
  } catch (error) {
    return error instanceof BoundaryError ? failure(error.reason_code, error.message) : failure("internal_error", "Handoff composition failed.");
  }
}

export function validateHandoffPacket(input) {
  try {
    const value = normalizedSafeValue(input, { scanPropertyNames: true, scanValues: true });
    if (!validateHandoffParts(value, false)) return failure("packet_invalid", "The handoff packet is invalid.");
    return success(value);
  } catch (error) {
    return error instanceof BoundaryError ? failure(error.reason_code, error.message) : failure("internal_error", "Handoff validation failed.");
  }
}

const SEMANTIC_RUNTIME_KEYS = new Set([
  "task_id", "work_unit_id", "candidate_id", "candidate_hash", "candidate_sha256", "contract_hash",
  "packet_hash", "packet_sha256", "worktree_root", "observation_worktree", "authoritative_worktree",
  "model", "model_role", "resolved_model", "effort", "isolation", "binding", "codegraph_version", "index_path",
]);

function assertNoSemanticRuntimeLeak(value) {
  if (Array.isArray(value)) {
    for (const item of value) assertNoSemanticRuntimeLeak(item);
    return;
  }
  if (isPlainObject(value)) {
    for (const [key, child] of Object.entries(value)) {
      if (SEMANTIC_RUNTIME_KEYS.has(key)) {
        throw boundaryError("structured_output_invalid", "Semantic output contains runtime-owned metadata.");
      }
      assertNoSemanticRuntimeLeak(child);
    }
    return;
  }
  if (typeof value === "string") {
    if (/(?:^|\s)(?:[A-Za-z]:[\\/]|\\\\[^\\\s]+[\\]|\/(?:Users|home|tmp|var|etc)\/)/u.test(value) ||
        /\b[0-9A-Fa-f]{64}\b/u.test(value)) {
      throw boundaryError("forbidden_content", "Semantic output contains an absolute path or runtime hash.");
    }
  }
}

function validText(value, maxLength) {
  return typeof value === "string" && value.length > 0 && value.length <= maxLength;
}

function validateScoutSemantic(value) {
  if (!exactKeys(value, SEMANTIC_OUTPUT_SCHEMAS.cheap_scout.required) ||
      !["completed", "partial", "blocked", "failed"].includes(value.status) || !validText(value.summary, 1200) ||
      !["native", "codegraph", "mixed"].includes(value.capability) || !validText(value.source_fitness_reason, 1024) ||
      !validateStringArray(value.fallback_path, { maxItems: 8 }) || !Array.isArray(value.claims) || value.claims.length > 32 ||
      !validateStringArray(value.gaps, { maxItems: 16, maxLength: 400 }) || !Array.isArray(value.searches_performed) ||
      value.searches_performed.length > 32 || !validText(value.recommended_next_action, 1024)) return false;
  for (const row of value.claims) {
    if (!exactKeys(row, ["claim", "sources"]) || !validText(row.claim, 600) || !Array.isArray(row.sources) ||
        row.sources.length < 1 || row.sources.length > 8) return false;
    for (const source of row.sources) {
      if (!exactKeys(source, ["path", "line_start", "line_end"]) || !isRelativePath(source.path) ||
          !Number.isSafeInteger(source.line_start) || source.line_start < 1 ||
          !Number.isSafeInteger(source.line_end) || source.line_end < source.line_start) return false;
    }
  }
  for (const row of value.searches_performed) {
    if (!exactKeys(row, ["method", "query", "outcome"]) ||
        !["read", "grep", "glob", "web_search", "codegraph"].includes(row.method) ||
        !validText(row.query, 1024) || !validText(row.outcome, 1024)) return false;
  }
  return value.status !== "completed" || value.claims.length > 0;
}

function validateWorkerSemantic(value) {
  if (!exactKeys(value, SEMANTIC_OUTPUT_SCHEMAS.worker.required) ||
      !["completed", "partial", "blocked", "failed"].includes(value.status) || !validText(value.summary, 1200) ||
      !validateStringArray(value.artifact_refs, { paths: true, unique: true, maxItems: 64 }) ||
      !Array.isArray(value.verification_observations) || value.verification_observations.length > 32 ||
      !validateStringArray(value.covered_ac_ids, { unique: true, maxItems: 64 }) ||
      value.covered_ac_ids.some((id) => !ACCEPTANCE_ID_PATTERN.test(id)) ||
      !validateStringArray(value.blockers, { maxItems: 16 }) ||
      !validateStringArray(value.remaining_risks, { maxItems: 16 })) return false;
  for (const row of value.verification_observations) {
    if (!exactKeys(row, ["command_id", "status", "observation"]) || !validText(row.command_id, 1024) ||
        !["passed", "failed", "not_run"].includes(row.status) || !validText(row.observation, 1024)) return false;
  }
  if (value.status === "completed" && (value.blockers.length > 0 || value.verification_observations.length === 0 ||
      value.verification_observations.some((row) => row.status !== "passed"))) return false;
  if (value.status === "blocked" && value.blockers.length === 0) return false;
  return true;
}

function validReviewerLocation(value) {
  if (!validText(value, 1024)) return false;
  const match = value.match(/^(.+):([1-9][0-9]*)(?:-([1-9][0-9]*))?$/u);
  if (!match || !isRelativePath(match[1])) return false;
  return match[3] === undefined || Number(match[3]) >= Number(match[2]);
}

function validateReviewerSemantic(value) {
  if (!exactKeys(value, SEMANTIC_OUTPUT_SCHEMAS.reviewer.required) ||
      !["APPROVED", "APPROVED_WITH_NOTES", "CHANGES_REQUESTED"].includes(value.decision) ||
      !validText(value.summary, 1200) || !Array.isArray(value.findings) || value.findings.length > 32 ||
      !Array.isArray(value.cleared_concerns) || value.cleared_concerns.length > 32 ||
      !["ACCEPT", "REWORK_BLOCKING", "ACCEPT_WITH_FOLLOWUP"].includes(value.recommended_action)) return false;
  for (const finding of value.findings) {
    if (!exactKeys(finding, ["severity", "title", "location", "trigger", "impact", "violated_contract", "evidence"]) ||
        !["critical", "important", "minor"].includes(finding.severity) || !validText(finding.title, 1024) ||
        !validReviewerLocation(finding.location) || !validText(finding.trigger, 1024) || !validText(finding.impact, 1024) ||
        !validText(finding.violated_contract, 1024) || !validText(finding.evidence, 1024)) return false;
  }
  for (const row of value.cleared_concerns) {
    if (!exactKeys(row, ["concern", "evidence"]) || !validText(row.concern, 1024) || !validText(row.evidence, 1024)) return false;
  }
  const blocking = value.findings.some((finding) => ["critical", "important"].includes(finding.severity));
  if (blocking) return value.decision === "CHANGES_REQUESTED" && value.recommended_action === "REWORK_BLOCKING";
  if (value.decision === "CHANGES_REQUESTED") return false;
  if (value.decision === "APPROVED") {
    return value.findings.length === 0 && value.cleared_concerns.length > 0 && value.recommended_action === "ACCEPT";
  }
  return value.findings.every((finding) => finding.severity === "minor") && value.cleared_concerns.length > 0 &&
    value.recommended_action === "ACCEPT_WITH_FOLLOWUP";
}

export function validateSemanticResult(input) {
  try {
    const normalized = normalizedSafeValue(input, { scanPropertyNames: true, scanValues: true });
    if (!exactKeys(normalized, ["role", "value"]) || !Object.hasOwn(SEMANTIC_OUTPUT_SCHEMAS, normalized.role)) {
      return failure("structured_output_invalid", "Semantic result validation has an invalid input shape.");
    }
    assertNoSemanticRuntimeLeak(normalized.value);
    const valid = normalized.role === "cheap_scout" ? validateScoutSemantic(normalized.value) :
      normalized.role === "worker" ? validateWorkerSemantic(normalized.value) : validateReviewerSemantic(normalized.value);
    if (!valid) return failure("structured_output_invalid", "The role semantic result violates its closed contract.");
    const canonical = canonicalJson(normalized.value);
    if (Buffer.byteLength(canonical, "utf8") > LIMITS.maxResultBytes) {
      return failure("structured_output_invalid", "The role semantic result exceeds the byte limit.");
    }
    return success(normalized.value);
  } catch (error) {
    return error instanceof BoundaryError ? failure(error.reason_code, error.message) : failure("internal_error", "Semantic result validation failed.");
  }
}

function receiptRuntimeFailure(reasonCode) {
  return {
    structured_output: "not_validated",
    model_role: "not_observed",
    resolved_model: "not_observed",
    fallback_used: false,
    effort: "not_observed",
    aborted: reasonCode === "cancelled" || reasonCode === "context_pressure",
    forced_partial: reasonCode === "forced_partial",
    omniroute_upstream: "not_observed",
  };
}

function failedReceipt(role, reasonCode, message) {
  const receipt = {
    schema_version: 1,
    record_type: "agent_boundary_receipt",
    status: "failed",
    reason_code: REASON_CODES.has(reasonCode) ? reasonCode : "internal_error",
    role,
    semantic_result: null,
    runtime: receiptRuntimeFailure(reasonCode),
    outcome: { recorded: false, status: "failed", artifact_refs: [] },
  };
  return {
    ok: false,
    reason_code: receipt.reason_code,
    message: String(message).slice(0, 240) || "The native result was rejected.",
    receipt,
  };
}

function sameCanonical(left, right) {
  return canonicalJson(left) === canonicalJson(right);
}

function resultFailure(role, reasonCode, message) {
  return failedReceipt(role, reasonCode, message);
}

function safeFallbackFlag(value) {
  if (value === undefined || value === false) return { ok: true, value: false };
  if (value === true) return { ok: true, value: true };
  return { ok: false, value: false };
}

function validateObservedIdentity(role, request, result) {
  const identity = RUNTIME_IDENTITIES[role];
  if (result.modelRole !== identity.model_role) {
    return failure("model_identity_mismatch", "The native result reported an unexpected model role.");
  }
  const fallback = safeFallbackFlag(result.resolvedModelIsFallback);
  if (!fallback.ok || typeof result.resolvedModel !== "string") {
    return failure("model_identity_mismatch", "The native result did not report a usable model identity.");
  }

  const expectedEffort = role === "worker" ? request.effort : identity.effort;
  const primary = `${identity.primary_model}:${expectedEffort}`;
  if (role === "cheap_scout") {
    const approvedFallback = `${identity.fallback_model}:${expectedEffort}`;
    if (fallback.value) {
      if (result.resolvedModel !== approvedFallback) {
        return failure("fallback_not_allowed", "The Scout result did not use the exact approved fallback route.");
      }
      return success({ model_role: identity.model_role, resolved_model: approvedFallback, fallback_used: true, effort: expectedEffort });
    }
    if (result.resolvedModel.startsWith(`${identity.fallback_model}:`)) {
      return failure("fallback_not_allowed", "The Scout fallback route was not reported as fallback use.");
    }
    if (result.resolvedModel === primary) {
      return success({ model_role: identity.model_role, resolved_model: primary, fallback_used: false, effort: expectedEffort });
    }
    if (result.resolvedModel.startsWith(`${identity.primary_model}:`)) {
      return failure("effort_mismatch", "The Scout result reported an unexpected effective effort.");
    }
    return failure("model_identity_mismatch", "The Scout result reported an unexpected model identity.");
  }

  if (fallback.value) {
    return failure("fallback_not_allowed", "Fallback is not authorized for the selected role.");
  }
  if (result.resolvedModel === primary) {
    return success({ model_role: identity.model_role, resolved_model: primary, fallback_used: false, effort: expectedEffort });
  }
  if (result.resolvedModel.startsWith(`${identity.primary_model}:`)) {
    return failure("effort_mismatch", "The native result reported an unexpected effective effort.");
  }
  return failure("model_identity_mismatch", "The native result reported an unexpected model identity.");
}

function artifactBindingChanged(before, after) {
  return before.binding.candidate_id !== after.binding.candidate_id ||
    before.binding.candidate_sha256?.toLowerCase() !== after.binding.candidate_sha256?.toLowerCase() ||
    before.binding.diff_ref?.toLowerCase() !== after.binding.diff_ref?.toLowerCase() ||
    !sameCanonical(before.binding.artifact_refs, after.binding.artifact_refs);
}

function normalizedProjectionForComparison(projection) {
  const value = structuredClone(projection);
  value.projection_sha256 = value.projection_sha256.toLowerCase();
  value.cas.revision_sha256 = value.cas.revision_sha256.toLowerCase();
  if (value.binding.candidate_sha256 !== null) value.binding.candidate_sha256 = value.binding.candidate_sha256.toLowerCase();
  if (value.binding.diff_ref !== null) value.binding.diff_ref = value.binding.diff_ref.toLowerCase();
  return value;
}

function workerArtifactsValid(semantic, projection) {
  const allowed = [...projection.work_unit.outputs, ...projection.work_unit.ownership];
  if (!semantic.artifact_refs.every((artifact) => pathInsideOwnership(artifact, allowed))) return false;
  if (semantic.status !== "completed") return true;
  return projection.work_unit.outputs.every((output) =>
    semantic.artifact_refs.some((artifact) => pathInsideOwnership(artifact, [output])));
}

function semanticReceiptStatus(role, semantic) {
  return role === "reviewer" ? "completed" : semantic.status;
}

function completedReceipt(role, semantic, identity) {
  const status = semanticReceiptStatus(role, semantic);
  const artifactRefs = role === "worker" ? [...semantic.artifact_refs] : [];
  return {
    schema_version: 1,
    record_type: "agent_boundary_receipt",
    status,
    reason_code: "ok",
    role,
    semantic_result: semantic,
    runtime: {
      structured_output: "valid",
      model_role: identity.model_role,
      resolved_model: identity.resolved_model,
      fallback_used: identity.fallback_used,
      effort: identity.effort,
      aborted: false,
      forced_partial: false,
      omniroute_upstream: "not_observed",
    },
    outcome: { recorded: false, status, artifact_refs: artifactRefs },
  };
}

export function normalizeBoundaryReceipt(input) {
  let role = "unknown";
  try {
    if (!isPlainObject(input) || !exactKeys(input, [
      "request", "projection_before", "projection_after", "index", "expected_count", "native_details",
    ])) {
      return failure("result_unsettled", "Boundary receipt normalization has an invalid input shape.");
    }
    const requestResult = validateManagedRequest(input.request);
    if (!requestResult.ok || Object.hasOwn(requestResult.value ?? {}, "tasks")) {
      return failure("result_unsettled", "Boundary receipt normalization requires one valid managed item.");
    }
    const request = requestResult.value;
    role = request.role;
    if (!Number.isSafeInteger(input.index) || input.index < 0 ||
        !Number.isSafeInteger(input.expected_count) || input.expected_count < 1 ||
        input.expected_count > LIMITS.maxBatchItems || input.index >= input.expected_count) {
      return resultFailure(role, "result_unsettled", "The expected native result index/count is invalid.");
    }

    const beforeResult = validateProjection(input.projection_before);
    if (!beforeResult.ok) return resultFailure(role, "candidate_drift", "The pre-dispatch work-unit projection is invalid.");
    const afterResult = validateProjection(input.projection_after);
    if (!afterResult.ok) return resultFailure(role, "candidate_drift", "The post-dispatch work-unit projection is invalid.");
    const before = beforeResult.value;
    const after = afterResult.value;
    if (request.task_id !== before.task.task_id || request.work_unit_id !== before.work_unit.work_unit_id) {
      return resultFailure(role, "candidate_drift", "The managed request no longer matches its projected authority.");
    }
    if (artifactBindingChanged(before, after)) {
      return resultFailure(role, "artifact_stale", "Candidate, diff, or artifact bindings changed during dispatch.");
    }
    if (!sameCanonical(normalizedProjectionForComparison(before), normalizedProjectionForComparison(after))) {
      return resultFailure(role, "candidate_drift", "The projected task/work-unit authority changed during dispatch.");
    }

    const composed = composeAgentPacket({ request, projection: before });
    if (!composed.ok) return resultFailure(role, composed.reason_code, "The selected agent packet no longer composes.");

    const details = input.native_details;
    if (!isPlainObject(details)) {
      return resultFailure(role, "result_unsettled", "Native task details are missing.");
    }
    if (Object.hasOwn(details, "async")) {
      return resultFailure(role, "unsupported_async", "Managed dispatch requires synchronous native task settlement.");
    }
    if (!Array.isArray(details.results) || details.results.length !== input.expected_count) {
      return resultFailure(role, "result_unsettled", "Native task details do not contain exactly one result per item.");
    }
    const indexes = details.results.map((result) => isPlainObject(result) ? result.index : null);
    if (indexes.some((index) => !Number.isSafeInteger(index) || index < 0 || index >= input.expected_count) ||
        new Set(indexes).size !== input.expected_count ||
        !Array.from({ length: input.expected_count }, (_, index) => index).every((index) => indexes.includes(index))) {
      return resultFailure(role, "result_unsettled", "Native result indexes are missing, duplicated, or out of range.");
    }
    const result = details.results.find((candidate) => candidate.index === input.index);
    if (!isPlainObject(result) || result.agent !== request.agent || result.agentSource !== "project" || result.task !== composed.canonical) {
      return resultFailure(role, "result_unsettled", "The settled native result does not match the dispatched agent/task identity.");
    }
    if (result.topic07AbortMarker === "T07_CONTEXT_PRESSURE_ABORT") {
      if (result.aborted === true || result.truncated === true || result.exitCode !== 0 ||
          result.structuredOutput?.data?.status === "partial") {
        return resultFailure(role, "context_pressure", "The bounded child stopped at the managed context-pressure boundary.");
      }
      return resultFailure(role, "result_unsettled", "A context-pressure marker lacked matching native abort or partial settlement.");
    }
    if (result.aborted === true) {
      return resultFailure(role, "cancelled", "The native task was cancelled or aborted.");
    }
    if (!Number.isSafeInteger(result.exitCode) || result.exitCode !== 0 ||
        (result.error !== undefined && result.error !== null && result.error !== "") ||
        (result.retryFailure !== undefined && result.retryFailure !== null) ||
        typeof result.stderr !== "string" || result.stderr.length !== 0) {
      return resultFailure(role, "native_task_failed", "The native task reported a terminal failure.");
    }
    if (result.truncated !== false || typeof result.output !== "string") {
      return resultFailure(role, "result_unsettled", "The native task output was truncated or incomplete.");
    }
    if (!Number.isSafeInteger(result.requests) || result.requests < 0) {
      return resultFailure(role, "result_unsettled", "The native task request count is invalid.");
    }
    if (result.requests >= LIMITS.forcedPartialRequests) {
      return resultFailure(role, "forced_partial", "The native task reached the managed forced-partial threshold.");
    }

    const structured = result.structuredOutput;
    if (!isPlainObject(structured) || !exactKeys(structured, ["source", "mode", "status", "data"]) ||
        structured.source !== "agent" || !["permissive", "strict"].includes(structured.mode) || structured.status !== "valid") {
      return resultFailure(role, "structured_output_invalid", "The native structured output was missing, overridden, or unvalidated.");
    }
    const semanticResult = validateSemanticResult({ role, value: structured.data });
    if (!semanticResult.ok) {
      return resultFailure(role, "structured_output_invalid", "The native semantic result violates the selected role contract.");
    }

    const identityResult = validateObservedIdentity(role, request, result);
    if (!identityResult.ok) return resultFailure(role, identityResult.reason_code, identityResult.message);
    if (role === "worker" && !workerArtifactsValid(semanticResult.value, before)) {
      return resultFailure(role, "artifact_stale", "Worker artifact references do not match the projected outputs/ownership.");
    }

    return { ok: true, receipt: completedReceipt(role, semanticResult.value, identityResult.value) };
  } catch (error) {
    const reasonCode = error instanceof BoundaryError ? error.reason_code : "internal_error";
    if (role !== "unknown") return resultFailure(role, reasonCode, "Boundary receipt normalization failed safely.");
    return failure(reasonCode, "Boundary receipt normalization failed safely.");
  }
}

function validReceiptRuntime(role, runtime) {
  if (!isPlainObject(runtime) || !exactKeys(runtime, [
    "structured_output", "model_role", "resolved_model", "fallback_used", "effort", "aborted",
    "forced_partial", "omniroute_upstream",
  ]) || runtime.structured_output !== "valid" || runtime.aborted !== false ||
      runtime.forced_partial !== false || runtime.omniroute_upstream !== "not_observed") return false;
  const identity = RUNTIME_IDENTITIES[role];
  if (!identity || runtime.model_role !== identity.model_role || typeof runtime.resolved_model !== "string") return false;
  if (role === "cheap_scout") {
    if (runtime.effort !== identity.effort) return false;
    const expected = runtime.fallback_used ? identity.fallback_model : identity.primary_model;
    return runtime.resolved_model === `${expected}:${identity.effort}`;
  }
  if (runtime.fallback_used !== false) return false;
  const effort = role === "reviewer" ? identity.effort : runtime.effort;
  if (role === "worker" && !identity.efforts.includes(effort)) return false;
  return runtime.effort === effort && runtime.resolved_model === `${identity.primary_model}:${effort}`;
}

export function toProvisionalOutcome(receipt) {
  try {
    if (!isPlainObject(receipt) || !exactKeys(receipt, [
      "schema_version", "record_type", "status", "reason_code", "role", "semantic_result", "runtime", "outcome",
    ]) || receipt.schema_version !== 1 || receipt.record_type !== "agent_boundary_receipt" ||
        receipt.reason_code !== "ok" || !Object.hasOwn(SEMANTIC_OUTPUT_SCHEMAS, receipt.role) ||
        !["completed", "partial", "blocked", "failed"].includes(receipt.status) ||
        !validReceiptRuntime(receipt.role, receipt.runtime) ||
        !isPlainObject(receipt.outcome) || !exactKeys(receipt.outcome, ["recorded", "status", "artifact_refs"]) ||
        typeof receipt.outcome.recorded !== "boolean") return null;
    const semantic = validateSemanticResult({ role: receipt.role, value: receipt.semantic_result });
    if (!semantic.ok) return null;
    const status = semanticReceiptStatus(receipt.role, semantic.value);
    const artifactRefs = receipt.role === "worker" ? [...semantic.value.artifact_refs] : [];
    if (receipt.status !== status || receipt.outcome.status !== status ||
        !sameCanonical(receipt.outcome.artifact_refs, artifactRefs)) return null;
    const observedSummary = receipt.role === "reviewer" ? {
      role: receipt.role,
      decision: semantic.value.decision,
      summary: semantic.value.summary,
    } : {
      role: receipt.role,
      status: semantic.value.status,
      summary: semantic.value.summary,
    };
    return { status, artifact_refs: artifactRefs, observed_summary: observedSummary };
  } catch {
    return null;
  }
}

export function deriveActiveMode(entries) {
  if (!Array.isArray(entries)) return failure("plan_mode_incompatible", "Session mode history is unavailable.");
  let mode = "none";
  for (const entry of entries) {
    if (isPlainObject(entry) && entry.type === "mode_change") {
      if (typeof entry.mode !== "string" || !["none", "plan", "goal"].includes(entry.mode)) {
        return failure("plan_mode_incompatible", "Session mode history is invalid.");
      }
      mode = entry.mode;
    }
  }
  return { ok: true, mode };
}
