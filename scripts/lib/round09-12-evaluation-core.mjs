import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const PROMOTION_VERDICTS = Object.freeze([
  "PROMOTE_EFFICIENCY",
  "PROMOTE_QUALITY",
  "REJECT",
  "DEFER_INCONCLUSIVE",
]);

export const ENVIRONMENT_STATUSES = Object.freeze(["PASS", "ENVIRONMENT_BLOCKED", "NOT_RUN"]);

const SHA256 = /^(?!0{64}$)[a-f0-9]{64}$/u;
const SEMVER = /^(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)$/u;
const SAFE_ID = /^[A-Z][A-Z0-9-]{1,63}$/u;
const FORBIDDEN_KEYS = new Set([
  "transcript",
  "reasoning",
  "chain_of_thought",
  "credential",
  "credentials",
  "api_key",
  "token",
  "secret",
  "env_contents",
  "terminal_history",
]);
const SECRET_PATTERNS = [
  /sk-[A-Za-z0-9_-]{8,}/u,
  /AKIA[0-9A-Z]{16}/u,
  /-----BEGIN [A-Z ]*PRIVATE KEY-----/u,
  /(?:api[_-]?key|password|secret|token|credential)\s*[:=]\s*\S+/iu,
];
const MAX_DEPTH = 16;
const MAX_ARRAY_ITEMS = 512;
const MAX_STRING_BYTES = 16_384;
const MAX_RECORD_BYTES = 512 * 1024;

const TASK_KEYS = [
  "schema_version",
  "record_type",
  "task_cycle_id",
  "task_contract_hash",
  "candidate_id",
  "candidate_snapshot_hash",
  "lifecycle_terminal_outcome",
  "nonterminal_observation",
  "objective_status",
  "mandatory_ac_results",
  "required_gates",
  "blocking_issues",
  "review_evidence",
  "operations",
  "tech_lead_acceptance",
  "author_claimed_success",
  "oracle_passed",
  "failure_class",
  "usage",
];

function canonicalize(value) {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.keys(value)
        .sort((left, right) => left.localeCompare(right, "en"))
        .map((key) => [key, canonicalize(value[key])]),
    );
  }
  return value;
}

function canonicalJson(value) {
  return JSON.stringify(canonicalize(value));
}

function sha256(value) {
  return createHash("sha256").update(value, "utf8").digest("hex");
}

function safeError(code, jsonPath, message) {
  return { code, path: jsonPath, message };
}

function invalid(errors) {
  return { ok: false, value: null, errors };
}

function valid(value) {
  return { ok: true, value, errors: [] };
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function addClosedErrors(value, allowed, required, jsonPath, errors) {
  if (!isPlainObject(value)) {
    errors.push(safeError("R0912-SCHEMA-TYPE", jsonPath, "Expected a JSON object."));
    return false;
  }
  const allowedSet = new Set(allowed);
  for (const key of Object.keys(value)) {
    if (!allowedSet.has(key)) {
      errors.push(safeError("R0912-SCHEMA-CLOSED", `${jsonPath}.${key}`, "Unknown field."));
    }
  }
  for (const key of required) {
    if (!Object.hasOwn(value, key)) {
      errors.push(safeError("R0912-SCHEMA-REQUIRED", `${jsonPath}.${key}`, "Required field is missing."));
    }
  }
  return true;
}

function scanForbidden(value, jsonPath, errors, depth = 0) {
  if (depth > MAX_DEPTH) {
    errors.push(safeError("R0912-SCHEMA-BOUNDS", jsonPath, "Maximum nesting depth exceeded."));
    return;
  }
  if (typeof value === "string") {
    if (Buffer.byteLength(value, "utf8") > MAX_STRING_BYTES) {
      errors.push(safeError("R0912-SCHEMA-BOUNDS", jsonPath, "String exceeds the bounded size."));
      return;
    }
    if (SECRET_PATTERNS.some((pattern) => pattern.test(value))) {
      errors.push(safeError("R0912-SCHEMA-SECRET", jsonPath, "Secret-shaped content is forbidden."));
    }
    return;
  }
  if (Array.isArray(value)) {
    if (value.length > MAX_ARRAY_ITEMS) {
      errors.push(safeError("R0912-SCHEMA-BOUNDS", jsonPath, "Array exceeds the bounded item count."));
      return;
    }
    value.forEach((item, index) => scanForbidden(item, `${jsonPath}[${index}]`, errors, depth + 1));
    return;
  }
  if (isPlainObject(value)) {
    for (const [key, child] of Object.entries(value)) {
      if (FORBIDDEN_KEYS.has(key.toLowerCase())) {
        errors.push(safeError("R0912-SCHEMA-FORBIDDEN", `${jsonPath}.${key}`, "Forbidden evidence field."));
      }
      scanForbidden(child, `${jsonPath}.${key}`, errors, depth + 1);
    }
  }
}

function preflight(value) {
  const errors = [];
  if (!isPlainObject(value)) {
    return [safeError("R0912-SCHEMA-TYPE", "$", "Expected a JSON object.")];
  }
  let bytes;
  try {
    bytes = Buffer.byteLength(JSON.stringify(value), "utf8");
  } catch {
    return [safeError("R0912-SCHEMA-TYPE", "$", "Value must be JSON-compatible.")];
  }
  if (bytes > MAX_RECORD_BYTES) {
    errors.push(safeError("R0912-SCHEMA-BOUNDS", "$", "Record exceeds the bounded size."));
    return errors;
  }
  scanForbidden(value, "$", errors);
  return errors;
}

function isEnum(value, allowed) {
  return typeof value === "string" && allowed.includes(value);
}

function isNonNegativeInteger(value) {
  return Number.isSafeInteger(value) && value >= 0;
}

function isBoundedString(value, pattern = null) {
  return typeof value === "string"
    && value.length > 0
    && Buffer.byteLength(value, "utf8") <= MAX_STRING_BYTES
    && (pattern === null || pattern.test(value));
}

function pushInvalid(errors, condition, code, jsonPath, message) {
  if (!condition) errors.push(safeError(code, jsonPath, message));
}

function validateUsageRow(row, jsonPath, errors, includeIdentity) {
  const keys = includeIdentity
    ? ["id", "role", "input", "output", "cache_write", "cache_read"]
    : ["input", "output", "cache_write", "cache_read"];
  if (!addClosedErrors(row, keys, keys, jsonPath, errors)) return;
  if (includeIdentity) {
    pushInvalid(errors, isBoundedString(row.id, /^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/u), "R0912-SCHEMA-ID", `${jsonPath}.id`, "Invalid usage identity.");
    pushInvalid(errors, isEnum(row.role, ["cheap-scout", "worker", "reviewer"]), "R0912-SCHEMA-ENUM", `${jsonPath}.role`, "Invalid usage role.");
  }
  for (const key of ["input", "output", "cache_write", "cache_read"]) {
    pushInvalid(errors, isNonNegativeInteger(row[key]), "R0912-SCHEMA-NUMBER", `${jsonPath}.${key}`, "Usage must be a non-negative integer.");
  }
}

export function validateFixtureManifest(input) {
  const errors = preflight(input);
  if (!isPlainObject(input)) return invalid(errors);
  const keys = ["schema_version", "record_type", "fixture_version", "baseline_kinds", "campaign_policy", "case_files"];
  addClosedErrors(input, keys, keys, "$", errors);
  pushInvalid(errors, input.schema_version === 1, "R0912-SCHEMA-VERSION", "$.schema_version", "Unsupported schema version.");
  pushInvalid(errors, input.record_type === "round0912_fixture_manifest", "R0912-SCHEMA-TYPE", "$.record_type", "Unexpected record type.");
  pushInvalid(errors, typeof input.fixture_version === "string" && SEMVER.test(input.fixture_version), "R0912-SCHEMA-VERSION", "$.fixture_version", "Invalid fixture version.");

  const expectedBaselines = ["pinned_plain_omp_runtime_baseline", "stable_product_baseline"];
  const baselines = Array.isArray(input.baseline_kinds) ? [...input.baseline_kinds].sort() : [];
  pushInvalid(errors, JSON.stringify(baselines) === JSON.stringify(expectedBaselines), "R0912-SCHEMA-BASELINE", "$.baseline_kinds", "Both frozen baseline kinds are required exactly once.");

  const policyKeys = [
    "default_mode",
    "provider_calls_require_explicit_authority",
    "pilot_min_pairs_per_arm",
    "pilot_can_promote",
    "max_joint_false_promotion_probability",
  ];
  if (addClosedErrors(input.campaign_policy, policyKeys, policyKeys, "$.campaign_policy", errors)) {
    const policy = input.campaign_policy;
    pushInvalid(errors, policy.default_mode === "deterministic", "R0912-SCHEMA-POLICY", "$.campaign_policy.default_mode", "Default mode must remain deterministic.");
    pushInvalid(errors, policy.provider_calls_require_explicit_authority === true, "R0912-SCHEMA-POLICY", "$.campaign_policy.provider_calls_require_explicit_authority", "Provider calls require explicit authority.");
    pushInvalid(errors, policy.pilot_min_pairs_per_arm === 3, "R0912-SCHEMA-POLICY", "$.campaign_policy.pilot_min_pairs_per_arm", "Pilot minimum must remain three pairs per arm.");
    pushInvalid(errors, policy.pilot_can_promote === false, "R0912-SCHEMA-POLICY", "$.campaign_policy.pilot_can_promote", "Pilot evidence cannot promote.");
    pushInvalid(errors, policy.max_joint_false_promotion_probability === 0.05, "R0912-SCHEMA-POLICY", "$.campaign_policy.max_joint_false_promotion_probability", "Joint false-promotion probability must remain 0.05.");
  }

  if (!Array.isArray(input.case_files) || input.case_files.length === 0) {
    errors.push(safeError("R0912-SCHEMA-CASES", "$.case_files", "At least one case file is required."));
  } else {
    const seen = new Set();
    input.case_files.forEach((entry, index) => {
      const safe = typeof entry === "string"
        && entry.length > 0
        && entry.endsWith(".json")
        && !path.isAbsolute(entry)
        && !entry.split(/[\\/]/u).includes("..")
        && !entry.includes(":");
      pushInvalid(errors, safe, "R0912-SCHEMA-PATH", `$.case_files[${index}]`, "Case path must be a safe relative JSON path.");
      if (seen.has(entry)) errors.push(safeError("R0912-SCHEMA-DUPLICATE", `$.case_files[${index}]`, "Duplicate case path."));
      seen.add(entry);
    });
  }
  if (errors.length > 0) return invalid(errors);
  const value = structuredClone(input);
  value.baseline_kinds.sort((left, right) => left.localeCompare(right, "en"));
  return valid(canonicalize(value));
}

export function validateTaskCycleRecord(input) {
  const errors = preflight(input);
  if (!isPlainObject(input)) return invalid(errors);
  addClosedErrors(input, TASK_KEYS, TASK_KEYS, "$", errors);
  pushInvalid(errors, input.schema_version === 1, "R0912-SCHEMA-VERSION", "$.schema_version", "Unsupported schema version.");
  pushInvalid(errors, input.record_type === "round0912_task_cycle", "R0912-SCHEMA-TYPE", "$.record_type", "Unexpected record type.");
  pushInvalid(errors, typeof input.task_cycle_id === "string" && /^TC-[0-9]{6}$/u.test(input.task_cycle_id), "R0912-SCHEMA-ID", "$.task_cycle_id", "Invalid task-cycle identity.");
  pushInvalid(errors, typeof input.candidate_id === "string" && /^C[0-9]{6}$/u.test(input.candidate_id), "R0912-SCHEMA-ID", "$.candidate_id", "Invalid candidate identity.");
  pushInvalid(errors, typeof input.task_contract_hash === "string" && SHA256.test(input.task_contract_hash), "R0912-SCHEMA-HASH", "$.task_contract_hash", "Invalid task-contract hash.");
  pushInvalid(errors, typeof input.candidate_snapshot_hash === "string" && SHA256.test(input.candidate_snapshot_hash), "R0912-SCHEMA-HASH", "$.candidate_snapshot_hash", "Invalid candidate hash.");

  pushInvalid(errors, input.lifecycle_terminal_outcome === null || isEnum(input.lifecycle_terminal_outcome, ["accepted", "cancelled", "terminally_blocked"]), "R0912-SCHEMA-ENUM", "$.lifecycle_terminal_outcome", "Invalid terminal lifecycle outcome.");
  pushInvalid(errors, input.nonterminal_observation === null || isEnum(input.nonterminal_observation, ["partial", "blocked", "waiting_for_user", "rework"]), "R0912-SCHEMA-ENUM", "$.nonterminal_observation", "Invalid nonterminal observation.");
  const lifecycleExclusive = (input.lifecycle_terminal_outcome === null) !== (input.nonterminal_observation === null);
  pushInvalid(errors, lifecycleExclusive, "R0912-SCHEMA-LIFECYCLE", "$", "Exactly one terminal or nonterminal lifecycle state is required.");
  pushInvalid(errors, isEnum(input.objective_status, ["complete", "incomplete"]), "R0912-SCHEMA-ENUM", "$.objective_status", "Invalid objective status.");

  if (!Array.isArray(input.mandatory_ac_results) || input.mandatory_ac_results.length === 0) {
    errors.push(safeError("R0912-SCHEMA-AC", "$.mandatory_ac_results", "At least one mandatory criterion result is required."));
  } else {
    const seen = new Set();
    input.mandatory_ac_results.forEach((row, index) => {
      const rowPath = `$.mandatory_ac_results[${index}]`;
      if (!addClosedErrors(row, ["id", "status", "evidence_ids"], ["id", "status", "evidence_ids"], rowPath, errors)) return;
      pushInvalid(errors, typeof row.id === "string" && /^AC-[0-9]{3}$/u.test(row.id), "R0912-SCHEMA-ID", `${rowPath}.id`, "Invalid acceptance-criterion identity.");
      pushInvalid(errors, isEnum(row.status, ["PASS", "FAIL", "SKIP"]), "R0912-SCHEMA-ENUM", `${rowPath}.status`, "Invalid acceptance-criterion status.");
      if (!Array.isArray(row.evidence_ids)) {
        errors.push(safeError("R0912-SCHEMA-TYPE", `${rowPath}.evidence_ids`, "Evidence identities must be an array."));
      } else {
        const evidence = new Set();
        row.evidence_ids.forEach((id, evidenceIndex) => {
          pushInvalid(errors, typeof id === "string" && /^E[0-9]{6}$/u.test(id), "R0912-SCHEMA-ID", `${rowPath}.evidence_ids[${evidenceIndex}]`, "Invalid evidence identity.");
          if (evidence.has(id)) errors.push(safeError("R0912-SCHEMA-DUPLICATE", `${rowPath}.evidence_ids[${evidenceIndex}]`, "Duplicate evidence identity."));
          evidence.add(id);
        });
      }
      if (seen.has(row.id)) errors.push(safeError("R0912-SCHEMA-DUPLICATE", `${rowPath}.id`, "Duplicate acceptance-criterion identity."));
      seen.add(row.id);
    });
  }

  if (addClosedErrors(input.required_gates, ["verification", "review"], ["verification", "review"], "$.required_gates", errors)) {
    for (const gate of ["verification", "review"]) {
      pushInvalid(errors, isEnum(input.required_gates[gate], ["PASS", "FAIL", "NOT_REQUIRED"]), "R0912-SCHEMA-ENUM", `$.required_gates.${gate}`, "Invalid gate status.");
    }
  }

  if (!Array.isArray(input.blocking_issues)) {
    errors.push(safeError("R0912-SCHEMA-TYPE", "$.blocking_issues", "Blocking issues must be an array."));
  } else {
    const seen = new Set();
    input.blocking_issues.forEach((row, index) => {
      const rowPath = `$.blocking_issues[${index}]`;
      if (!addClosedErrors(row, ["code", "severity"], ["code", "severity"], rowPath, errors)) return;
      pushInvalid(errors, isBoundedString(row.code, SAFE_ID), "R0912-SCHEMA-ID", `${rowPath}.code`, "Invalid blocking issue code.");
      pushInvalid(errors, isEnum(row.severity, ["critical", "important"]), "R0912-SCHEMA-ENUM", `${rowPath}.severity`, "Only blocking severities belong in blocking_issues.");
      if (seen.has(row.code)) errors.push(safeError("R0912-SCHEMA-DUPLICATE", `${rowPath}.code`, "Duplicate blocking issue."));
      seen.add(row.code);
    });
  }

  const reviewKeys = ["required", "decision", "candidate_id", "candidate_snapshot_hash", "reviewer_role", "independent", "fresh_result", "findings"];
  if (addClosedErrors(input.review_evidence, reviewKeys, reviewKeys, "$.review_evidence", errors)) {
    const review = input.review_evidence;
    pushInvalid(errors, typeof review.required === "boolean", "R0912-SCHEMA-TYPE", "$.review_evidence.required", "Review requirement must be boolean.");
    pushInvalid(errors, isEnum(review.decision, ["APPROVED", "APPROVED_WITH_NOTES", "REWORK", "NOT_REQUIRED"]), "R0912-SCHEMA-ENUM", "$.review_evidence.decision", "Invalid review decision.");
    pushInvalid(errors, typeof review.candidate_id === "string" && /^C[0-9]{6}$/u.test(review.candidate_id), "R0912-SCHEMA-ID", "$.review_evidence.candidate_id", "Invalid reviewed candidate identity.");
    pushInvalid(errors, typeof review.candidate_snapshot_hash === "string" && SHA256.test(review.candidate_snapshot_hash), "R0912-SCHEMA-HASH", "$.review_evidence.candidate_snapshot_hash", "Invalid reviewed candidate hash.");
    pushInvalid(errors, review.reviewer_role === "reviewer", "R0912-SCHEMA-ENUM", "$.review_evidence.reviewer_role", "Selected review evidence must use the reviewer role.");
    pushInvalid(errors, typeof review.independent === "boolean", "R0912-SCHEMA-TYPE", "$.review_evidence.independent", "Review independence must be boolean.");
    pushInvalid(errors, typeof review.fresh_result === "boolean", "R0912-SCHEMA-TYPE", "$.review_evidence.fresh_result", "Review freshness must be boolean.");
    if (!Array.isArray(review.findings)) {
      errors.push(safeError("R0912-SCHEMA-TYPE", "$.review_evidence.findings", "Review findings must be an array."));
    } else {
      const seen = new Set();
      review.findings.forEach((row, index) => {
        const rowPath = `$.review_evidence.findings[${index}]`;
        if (!addClosedErrors(row, ["code", "severity"], ["code", "severity"], rowPath, errors)) return;
        pushInvalid(errors, isBoundedString(row.code, SAFE_ID), "R0912-SCHEMA-ID", `${rowPath}.code`, "Invalid review finding code.");
        pushInvalid(errors, isEnum(row.severity, ["critical", "important", "minor"]), "R0912-SCHEMA-ENUM", `${rowPath}.severity`, "Invalid review severity.");
        if (seen.has(row.code)) errors.push(safeError("R0912-SCHEMA-DUPLICATE", `${rowPath}.code`, "Duplicate review finding."));
        seen.add(row.code);
      });
    }
  }

  if (addClosedErrors(input.operations, ["retries", "destructive_action"], ["retries", "destructive_action"], "$.operations", errors)) {
    if (!Array.isArray(input.operations.retries)) {
      errors.push(safeError("R0912-SCHEMA-TYPE", "$.operations.retries", "Retries must be an array."));
    } else {
      const seen = new Set();
      input.operations.retries.forEach((row, index) => {
        const rowPath = `$.operations.retries[${index}]`;
        const keys = ["operation_id", "side_effect_attempted", "idempotency_key", "reconciliation_status"];
        if (!addClosedErrors(row, keys, keys, rowPath, errors)) return;
        pushInvalid(errors, isBoundedString(row.operation_id, SAFE_ID), "R0912-SCHEMA-ID", `${rowPath}.operation_id`, "Invalid operation identity.");
        pushInvalid(errors, typeof row.side_effect_attempted === "boolean", "R0912-SCHEMA-TYPE", `${rowPath}.side_effect_attempted`, "Side-effect flag must be boolean.");
        pushInvalid(errors, row.idempotency_key === null || isBoundedString(row.idempotency_key, /^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/u), "R0912-SCHEMA-ID", `${rowPath}.idempotency_key`, "Invalid idempotency identity.");
        pushInvalid(errors, isEnum(row.reconciliation_status, ["not_required", "confirmed", "missing"]), "R0912-SCHEMA-ENUM", `${rowPath}.reconciliation_status`, "Invalid reconciliation status.");
        if (seen.has(row.operation_id)) errors.push(safeError("R0912-SCHEMA-DUPLICATE", `${rowPath}.operation_id`, "Duplicate retry operation."));
        seen.add(row.operation_id);
      });
    }
    if (addClosedErrors(input.operations.destructive_action, ["requested", "authorized"], ["requested", "authorized"], "$.operations.destructive_action", errors)) {
      pushInvalid(errors, typeof input.operations.destructive_action.requested === "boolean", "R0912-SCHEMA-TYPE", "$.operations.destructive_action.requested", "Destructive request flag must be boolean.");
      pushInvalid(errors, typeof input.operations.destructive_action.authorized === "boolean", "R0912-SCHEMA-TYPE", "$.operations.destructive_action.authorized", "Destructive authority flag must be boolean.");
    }
  }

  pushInvalid(errors, isEnum(input.tech_lead_acceptance, ["accepted", "not_accepted", "pending"]), "R0912-SCHEMA-ENUM", "$.tech_lead_acceptance", "Invalid Tech Lead acceptance state.");
  pushInvalid(errors, typeof input.author_claimed_success === "boolean", "R0912-SCHEMA-TYPE", "$.author_claimed_success", "Author success claim must be boolean.");
  pushInvalid(errors, input.oracle_passed === null || typeof input.oracle_passed === "boolean", "R0912-SCHEMA-TYPE", "$.oracle_passed", "Oracle status must be boolean or null.");
  pushInvalid(errors, isEnum(input.failure_class, ["none", "quality", "provider", "environment", "timeout", "contract", "cancelled", "security"]), "R0912-SCHEMA-ENUM", "$.failure_class", "Invalid failure class.");

  if (addClosedErrors(input.usage, ["main", "children"], ["main", "children"], "$.usage", errors)) {
    validateUsageRow(input.usage.main, "$.usage.main", errors, false);
    if (!Array.isArray(input.usage.children)) {
      errors.push(safeError("R0912-SCHEMA-TYPE", "$.usage.children", "Child usage must be an array."));
    } else {
      const seen = new Set();
      input.usage.children.forEach((row, index) => {
        validateUsageRow(row, `$.usage.children[${index}]`, errors, true);
        if (isPlainObject(row) && seen.has(row.id)) errors.push(safeError("R0912-SCHEMA-DUPLICATE", `$.usage.children[${index}].id`, "Duplicate child usage identity."));
        if (isPlainObject(row)) seen.add(row.id);
      });
    }
  }

  if (errors.length > 0) return invalid(errors);
  const value = structuredClone(input);
  value.mandatory_ac_results.sort((left, right) => left.id.localeCompare(right.id, "en"));
  for (const row of value.mandatory_ac_results) row.evidence_ids.sort((left, right) => left.localeCompare(right, "en"));
  value.blocking_issues.sort((left, right) => left.code.localeCompare(right.code, "en"));
  value.review_evidence.findings.sort((left, right) => left.code.localeCompare(right.code, "en"));
  value.operations.retries.sort((left, right) => left.operation_id.localeCompare(right.operation_id, "en"));
  value.usage.children.sort((left, right) => left.id.localeCompare(right.id, "en"));
  return valid(canonicalize(value));
}

export function classifyValidatedOutcome(record) {
  const validation = validateTaskCycleRecord(record);
  if (!validation.ok) {
    return { validated_accepted_outcome: false, false_completion: false, reasons: ["invalid_task_cycle"] };
  }
  const value = validation.value;
  const reasons = [];
  const falseCompletion = value.author_claimed_success === true && value.oracle_passed !== true;
  if (falseCompletion) reasons.push("false_completion");
  if (value.lifecycle_terminal_outcome !== "accepted") reasons.push("task_cycle_not_accepted");
  if (value.objective_status !== "complete") reasons.push("objective_incomplete");
  if (!value.mandatory_ac_results.every((row) => row.status === "PASS" && row.evidence_ids.length > 0)) reasons.push("mandatory_acceptance_gap");
  if (!Object.values(value.required_gates).every((status) => status === "PASS" || status === "NOT_REQUIRED")) reasons.push("required_gate_not_clear");
  if (value.blocking_issues.length > 0) reasons.push("blocking_issues_present");
  if (value.tech_lead_acceptance !== "accepted") reasons.push("tech_lead_not_accepted");

  if (value.review_evidence.required) {
    if (value.review_evidence.candidate_id !== value.candidate_id
      || value.review_evidence.candidate_snapshot_hash !== value.candidate_snapshot_hash
      || value.review_evidence.fresh_result !== true) {
      reasons.push("stale_review_evidence");
    }
    if (value.review_evidence.independent !== true) reasons.push("review_not_independent");
    if (!["APPROVED", "APPROVED_WITH_NOTES"].includes(value.review_evidence.decision)) reasons.push("review_not_approved");
  }
  if (value.review_evidence.findings.some((finding) => finding.severity === "critical" || finding.severity === "important")
      && !reasons.includes("blocking_issues_present")) {
    reasons.push("blocking_review_finding");
  }
  if (value.operations.destructive_action.requested && !value.operations.destructive_action.authorized) {
    reasons.push("destructive_action_not_authorized");
  }
  if (value.operations.retries.some((retry) => retry.side_effect_attempted
      && (retry.idempotency_key === null || retry.reconciliation_status !== "confirmed"))) {
    reasons.push("unsafe_side_effect_retry");
  }
  return {
    validated_accepted_outcome: reasons.length === 0,
    false_completion: falseCompletion,
    reasons,
  };
}

function tokenTotal(row) {
  return row.input + row.output + row.cache_write;
}

export function aggregateTaskCycles(records) {
  if (!Array.isArray(records)) throw Object.assign(new TypeError("Task cycles must be an array."), { code: "R0912-SCHEMA-TYPE" });
  let validatedAccepted = 0;
  let core = 0;
  let cheapScout = 0;
  let cacheRead = 0;
  let measured = true;
  const notMeasuredReasons = new Set();
  for (const record of records) {
    const validation = validateTaskCycleRecord(record);
    if (!validation.ok) {
      measured = false;
      notMeasuredReasons.add("invalid_task_cycle");
      continue;
    }
    const value = validation.value;
    if (classifyValidatedOutcome(value).validated_accepted_outcome) validatedAccepted += 1;
    core += tokenTotal(value.usage.main);
    cacheRead += value.usage.main.cache_read;
    for (const child of value.usage.children) {
      if (child.role === "cheap-scout") cheapScout += tokenTotal(child);
      else core += tokenTotal(child);
      cacheRead += child.cache_read;
    }
  }
  const attempted = records.length;
  const acceptedRate = attempted === 0 ? 0 : validatedAccepted / attempted;
  let perAccepted;
  if (!measured) perAccepted = "not_measured";
  else if (validatedAccepted === 0) perAccepted = "infinite";
  else perAccepted = core / validatedAccepted;
  return {
    attempted_cycles: attempted,
    validated_accepted: validatedAccepted,
    accepted_rate: acceptedRate,
    core_workflow_tokens: measured ? core : "not_measured",
    cheap_scout_tokens: measured ? cheapScout : "not_measured",
    raw_total_tokens: measured ? core + cheapScout : "not_measured",
    cache_read_tokens: measured ? cacheRead : "not_measured",
    core_workflow_tokens_per_accepted: perAccepted,
    not_measured_reasons: [...notMeasuredReasons].sort((left, right) => left.localeCompare(right, "en")),
  };
}

function promotionResult(verdict, reasons) {
  return { verdict, reasons, eligible: verdict === "PROMOTE_EFFICIENCY" || verdict === "PROMOTE_QUALITY" };
}

export function evaluatePromotion({ campaign, hard_gates: hardGates, summary, sequential_evidence: sequentialEvidence } = {}) {
  if (!isPlainObject(campaign) || !isPlainObject(hardGates) || !isPlainObject(summary) || !isPlainObject(sequentialEvidence)) {
    return promotionResult("REJECT", ["promotion_input_invalid"]);
  }
  const hardGateFailure = hardGates.operational_fixtures_pass !== true
    || hardGates.acceptance_criteria_coverage_complete !== true
    || hardGates.new_false_completions !== 0
    || hardGates.blocking_regressions !== 0
    || hardGates.acceptance_rate_not_lower !== true
    || hardGates.ledgers_coherent !== true
    || hardGates.baseline_identities_coherent !== true;
  if (hardGateFailure) return promotionResult("REJECT", ["hard_gate_failed"]);
  if (!ENVIRONMENT_STATUSES.includes(campaign.environment_status)) return promotionResult("REJECT", ["environment_status_invalid"]);
  if (campaign.environment_status !== "PASS") return promotionResult("DEFER_INCONCLUSIVE", ["environment_blocked"]);
  if (!SHA256.test(campaign.frozen_threshold_hash ?? "")
      || !SHA256.test(campaign.observed_threshold_hash ?? "")
      || campaign.frozen_threshold_hash !== campaign.observed_threshold_hash) {
    return promotionResult("REJECT", ["threshold_identity_mismatch"]);
  }
  if (!SHA256.test(campaign.frozen_plan_hash ?? "")
      || !SHA256.test(campaign.observed_plan_hash ?? "")
      || campaign.frozen_plan_hash !== campaign.observed_plan_hash) {
    return promotionResult("REJECT", ["sequential_plan_identity_mismatch"]);
  }
  if (campaign.look_declared !== true) return promotionResult("REJECT", ["undeclared_look"]);
  if (!["anytime_valid", "finite_alpha_spending", "equivalent_joint_sequential"].includes(campaign.inference_method)) {
    return promotionResult("REJECT", ["invalid_sequential_method"]);
  }
  if (campaign.alpha_allocation_complete !== true) return promotionResult("REJECT", ["alpha_allocation_incomplete"]);
  if (typeof campaign.joint_false_promotion_probability !== "number"
      || campaign.joint_false_promotion_probability < 0
      || campaign.joint_false_promotion_probability > 0.05) {
    return promotionResult("REJECT", ["joint_false_promotion_control_invalid"]);
  }
  if (campaign.phase === "pilot") return promotionResult("DEFER_INCONCLUSIVE", ["pilot_cannot_promote"]);
  if (campaign.phase !== "final") return promotionResult("REJECT", ["campaign_phase_invalid"]);
  if (campaign.evidence_budget_exhausted === true) return promotionResult("DEFER_INCONCLUSIVE", ["evidence_budget_exhausted"]);
  if (sequentialEvidence.measured !== true) return promotionResult("DEFER_INCONCLUSIVE", ["required_ledger_not_measured"]);
  if (sequentialEvidence.promotion_bounds_valid !== true) return promotionResult("DEFER_INCONCLUSIVE", ["promotion_bounds_incomplete"]);

  const efficiency = summary.observed_acceptance_rate_delta >= 0
    && summary.acceptance_rate_lower_bound >= -0.05
    && summary.token_improvement_fraction >= 0.10
    && summary.token_improvement_lower_bound > 0;
  if (efficiency) return promotionResult("PROMOTE_EFFICIENCY", ["efficiency_path_clear"]);
  const quality = summary.acceptance_rate_lower_bound > 0 && summary.token_ratio_upper_bound <= 1.10;
  if (quality) return promotionResult("PROMOTE_QUALITY", ["quality_path_clear"]);
  return promotionResult("REJECT", ["promotion_threshold_not_met"]);
}

function parseCliArguments(argv) {
  const parsed = {};
  for (let index = 0; index < argv.length; index += 1) {
    const key = argv[index];
    if (!["--fixture-manifest", "--output"].includes(key) || index + 1 >= argv.length) {
      throw Object.assign(new Error("Invalid deterministic CLI arguments."), { code: "R0912-CLI-ARGS" });
    }
    if (Object.hasOwn(parsed, key)) throw Object.assign(new Error("Duplicate deterministic CLI argument."), { code: "R0912-CLI-ARGS" });
    parsed[key] = argv[index + 1];
    index += 1;
  }
  if (!parsed["--fixture-manifest"] || !parsed["--output"]) {
    throw Object.assign(new Error("Fixture manifest and output are required."), { code: "R0912-CLI-ARGS" });
  }
  return { manifestPath: path.resolve(parsed["--fixture-manifest"]), outputPath: path.resolve(parsed["--output"]) };
}

function matchesExpected(actual, expected) {
  if (Array.isArray(expected)) {
    return Array.isArray(actual)
      && actual.length === expected.length
      && expected.every((item, index) => matchesExpected(actual[index], item));
  }
  if (isPlainObject(expected)) {
    return isPlainObject(actual)
      && Object.entries(expected).every(([key, value]) => Object.hasOwn(actual, key) && matchesExpected(actual[key], value));
  }
  return Object.is(actual, expected);
}

function validateCaseFile(value) {
  const errors = preflight(value);
  if (!isPlainObject(value)) return invalid(errors);
  addClosedErrors(value, ["schema_version", "record_type", "category", "cases"], ["schema_version", "record_type", "category", "cases"], "$", errors);
  pushInvalid(errors, value.schema_version === 1, "R0912-SCHEMA-VERSION", "$.schema_version", "Unsupported case schema version.");
  pushInvalid(errors, value.record_type === "round0912_fixture_cases", "R0912-SCHEMA-TYPE", "$.record_type", "Unexpected case record type.");
  pushInvalid(errors, isEnum(value.category, ["quality", "security", "promotion", "package"]), "R0912-SCHEMA-ENUM", "$.category", "Invalid case category.");
  if (!Array.isArray(value.cases)) errors.push(safeError("R0912-SCHEMA-TYPE", "$.cases", "Cases must be an array."));
  if (errors.length > 0) return invalid(errors);
  return valid(value);
}

function evaluateCase(row) {
  if (!isPlainObject(row) || !isBoundedString(row.id, SAFE_ID) || !isPlainObject(row.input) || !isPlainObject(row.expected)) {
    return { id: typeof row?.id === "string" ? row.id : "INVALID-CASE", status: "FAIL" };
  }
  let actual;
  if (row.kind === "task_cycle") {
    actual = classifyValidatedOutcome(row.input.task_cycle);
  } else if (row.kind === "promotion") {
    actual = evaluatePromotion(row.input.promotion);
  } else if (row.kind === "secret_probe") {
    const segments = Array.isArray(row.input.segments) ? row.input.segments : [];
    const rejectedValue = segments.every((segment) => typeof segment === "string") ? segments.join("") : "";
    const probe = validateTaskCycleRecord({
      schema_version: 1,
      record_type: "round0912_task_cycle",
      candidate_id: rejectedValue,
    });
    const secretError = probe.errors.find((error) => error.code === "R0912-SCHEMA-SECRET");
    actual = {
      code: secretError?.code ?? "R0912-SCHEMA-SECRET-NOT-DETECTED",
      echoes_value: rejectedValue.length > 0 && JSON.stringify(probe).includes(rejectedValue),
    };
  } else if (row.kind === "package_expectation") {
    actual = { deferred_to_package_proof: true };
  } else {
    return { id: row.id, status: "FAIL" };
  }
  return { id: row.id, status: matchesExpected(actual, row.expected) ? "PASS" : "FAIL" };
}

export async function runDeterministicCli(argv) {
  const { manifestPath, outputPath } = parseCliArguments(argv);
  const manifestText = await readFile(manifestPath, "utf8");
  const manifestInput = JSON.parse(manifestText);
  const manifestResult = validateFixtureManifest(manifestInput);
  if (!manifestResult.ok) throw Object.assign(new Error("Fixture manifest validation failed."), { code: manifestResult.errors[0].code });
  const manifestDirectory = path.dirname(manifestPath);
  const cases = [];
  const ids = new Set();
  for (const relativePath of manifestResult.value.case_files) {
    const casePath = path.resolve(manifestDirectory, relativePath);
    if (!casePath.startsWith(`${manifestDirectory}${path.sep}`)) throw Object.assign(new Error("Case path escaped manifest root."), { code: "R0912-SCHEMA-PATH" });
    const parsed = JSON.parse(await readFile(casePath, "utf8"));
    const caseResult = validateCaseFile(parsed);
    if (!caseResult.ok) throw Object.assign(new Error("Fixture case validation failed."), { code: caseResult.errors[0].code });
    for (const row of caseResult.value.cases) {
      if (ids.has(row.id)) throw Object.assign(new Error("Duplicate fixture case identity."), { code: "R0912-SCHEMA-DUPLICATE" });
      ids.add(row.id);
      cases.push(evaluateCase(row));
    }
  }
  cases.sort((left, right) => left.id.localeCompare(right.id, "en"));
  const result = canonicalize({
    schema_version: 1,
    record_type: "round0912_evaluation_run",
    fixture_version: manifestResult.value.fixture_version,
    fixture_manifest_sha256: sha256(canonicalJson(manifestResult.value)),
    mode: "deterministic",
    status: cases.every((row) => row.status === "PASS") ? "PASS" : "FAIL",
    environment_status: "PASS",
    provider_calls: 0,
    model_processes_started: 0,
    cases,
    promotion: promotionResult("DEFER_INCONCLUSIVE", ["deterministic_evidence_cannot_promote"]),
  });
  await mkdir(path.dirname(outputPath), { recursive: true });
  await writeFile(outputPath, `${JSON.stringify(result, null, 2)}\n`, { encoding: "utf8", flag: "wx" });
  return result;
}

const invokedPath = process.argv[1] ? path.resolve(process.argv[1]) : null;
const importedFromEval = process.execArgv.some((argument) =>
  argument === "-e" || argument === "--eval" || argument.startsWith("--eval="));
if (!importedFromEval && invokedPath === fileURLToPath(import.meta.url)) {
  runDeterministicCli(process.argv.slice(2))
    .then((result) => {
      process.stdout.write(`${JSON.stringify({ ok: true, status: result.status })}\n`);
    })
    .catch((error) => {
      process.stdout.write(`${JSON.stringify({ ok: false, code: error?.code ?? "R0912-CLI-FAILED" })}\n`);
      process.exitCode = 2;
    });
}
