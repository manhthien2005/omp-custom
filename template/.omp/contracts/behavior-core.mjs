import path from "node:path";

import { canonicalJson } from "./agent-boundary-core.mjs";
import {
  BEHAVIOR_LIMITS,
  DIAGNOSTIC_TOOLS,
  LIFECYCLE_OPERATIONS,
  MUTATION_CAPABLE_TOOLS,
} from "./behavior-core-schema.mjs";

const SHA256_PATTERN = /^[a-f0-9]{64}$/u;
const ZERO_SHA256_PATTERN = /^0{64}$/u;
const NAME_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/u;
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/u;
const VERSION_PATTERN = /^\d+\.\d+\.\d+$/u;

const TOP_LEVEL_KEYS = Object.freeze([
  "schema_version",
  "record_type",
  "component",
  "component_version",
  "reviewed_on",
  "constitution",
  "budgets",
  "skills",
  "roles",
  "commands",
  "hooks",
  "tools",
  "adapters",
  "provenance",
]);

const BUDGET_KEYS = Object.freeze([
  "rules_target_max_tokens",
  "rules_hard_warning_tokens",
  "skill_description_max_tokens",
  "visible_catalog_max_tokens",
  "visible_skill_soft_cap",
  "visible_skill_hard_cap",
  "worker_autoload_body_max_tokens",
  "lazy_skill_body_max_tokens",
]);

const EXPECTED_BUDGETS = Object.freeze({
  rules_target_max_tokens: BEHAVIOR_LIMITS.rulesTargetMaxTokens,
  rules_hard_warning_tokens: BEHAVIOR_LIMITS.rulesHardWarningTokens,
  skill_description_max_tokens: BEHAVIOR_LIMITS.skillDescriptionMaxTokens,
  visible_catalog_max_tokens: BEHAVIOR_LIMITS.visibleCatalogMaxTokens,
  visible_skill_soft_cap: BEHAVIOR_LIMITS.visibleSkillSoftCap,
  visible_skill_hard_cap: BEHAVIOR_LIMITS.visibleSkillHardCap,
  worker_autoload_body_max_tokens: BEHAVIOR_LIMITS.workerAutoloadBodyMaxTokens,
  lazy_skill_body_max_tokens: BEHAVIOR_LIMITS.lazySkillBodyMaxTokens,
});

const SKILL_KEYS = Object.freeze([
  "name",
  "path",
  "sha256",
  "visibility",
  "loading",
  "intended_consumers",
  "autoload_roles",
  "positive_trigger_fixture",
  "negative_trigger_fixture",
  "description_max_tokens",
  "body_max_tokens",
  "provenance_id",
  "license_id",
  "status",
  "replacement",
  "behavior_ids",
]);

const ROLE_KEYS = Object.freeze([
  "agent_path",
  "required_autoload",
  "forbidden_responsibilities",
  "behavior_ids",
]);

const COMMAND_KEYS = Object.freeze(["path", "behavior_ids"]);
const HOOK_KEYS = Object.freeze([
  "name",
  "extension",
  "boundary",
  "predicate",
  "failure_policy",
  "error_prefix",
  "observation_policy",
  "behavior_ids",
]);
const PROVENANCE_KEYS = Object.freeze(["id", "license_id", "kind", "source", "commit"]);
const MAPPING_KEYS = Object.freeze(["constitution", "agents", "commands", "skills", "hooks"]);

const success = (value) => ({ ok: true, value });
const failure = (reason_code, message) => ({
  ok: false,
  reason_code,
  message: String(message).slice(0, 240),
});

function isPlainObject(value) {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function exactKeys(value, keys) {
  if (!isPlainObject(value)) return false;
  const actual = Object.keys(value);
  return actual.length === keys.length && keys.every((key) => Object.hasOwn(value, key));
}

function uniqueStrings(value, { allowEmpty = true } = {}) {
  return Array.isArray(value) && (allowEmpty || value.length > 0) &&
    value.every((item) => typeof item === "string" && item.length > 0) &&
    new Set(value).size === value.length;
}

function safeRelativePath(value) {
  if (typeof value !== "string" || !value || value.includes("\\") || path.isAbsolute(value)) return false;
  const segments = value.split("/");
  return segments.every((segment) => segment && segment !== "." && segment !== "..");
}

function sameStringArray(left, right) {
  return Array.isArray(left) && Array.isArray(right) && left.length === right.length &&
    left.every((item, index) => item === right[index]);
}

function validBehaviorIds(value) {
  return uniqueStrings(value, { allowEmpty: false });
}

function validateAdapterMappings(value) {
  return exactKeys(value, MAPPING_KEYS) && MAPPING_KEYS.every((key) => safeRelativePath(value[key]));
}

function validateProvenance(rows) {
  if (!Array.isArray(rows) || rows.length === 0) return false;
  const ids = new Set();
  for (const row of rows) {
    if (!exactKeys(row, PROVENANCE_KEYS) || !NAME_PATTERN.test(row.id) ||
        typeof row.license_id !== "string" || !row.license_id ||
        !["project-owned", "derived"].includes(row.kind) ||
        typeof row.source !== "string" || !row.source ||
        !(row.commit === null || (typeof row.commit === "string" && /^[a-f0-9]{40,64}$/u.test(row.commit))) ||
        ids.has(row.id)) return false;
    ids.add(row.id);
  }
  return true;
}

function validateSkillRows(manifest) {
  if (!Array.isArray(manifest.skills) || manifest.skills.length === 0 ||
      manifest.skills.length > BEHAVIOR_LIMITS.visibleSkillHardCap) {
    return failure("BHV-BUDGET-EXCEEDED", "The selected skill roster exceeds its hard cap.");
  }
  const names = new Set();
  const paths = new Set();
  const provenance = new Map(manifest.provenance.map((row) => [row.id, row]));
  for (const row of manifest.skills) {
    if (!exactKeys(row, SKILL_KEYS) || !NAME_PATTERN.test(row.name) || names.has(row.name) ||
        !safeRelativePath(row.path) || row.path !== `.omp/skills/${row.name}/SKILL.md` || paths.has(row.path) ||
        !["visible", "hidden"].includes(row.visibility) || !["lazy", "autoload"].includes(row.loading) ||
        !uniqueStrings(row.intended_consumers, { allowEmpty: false }) || !uniqueStrings(row.autoload_roles) ||
        !safeRelativePath(row.positive_trigger_fixture) || !safeRelativePath(row.negative_trigger_fixture) ||
        row.positive_trigger_fixture === row.negative_trigger_fixture ||
        !Number.isSafeInteger(row.description_max_tokens) || row.description_max_tokens < 1 ||
        row.description_max_tokens > BEHAVIOR_LIMITS.skillDescriptionMaxTokens ||
        !Number.isSafeInteger(row.body_max_tokens) || row.body_max_tokens < 1 ||
        !["active", "deprecated", "removed"].includes(row.status) ||
        !(row.replacement === null || NAME_PATTERN.test(row.replacement)) ||
        !validBehaviorIds(row.behavior_ids)) {
      return failure("BHV-MANIFEST-INVALID", "A skill row violates the closed behavior contract.");
    }
    if (row.status === "removed") {
      if (row.sha256 !== null || row.visibility !== "hidden" || row.autoload_roles.length > 0) {
        return failure("BHV-AUTOLOAD-MISMATCH", "A removed skill remains visible, installed, or autoloaded.");
      }
    } else if (!SHA256_PATTERN.test(row.sha256) || ZERO_SHA256_PATTERN.test(row.sha256)) {
      return failure("BHV-MANIFEST-INVALID", "An installed skill has an invalid SHA-256.");
    }
    if (row.status !== "active" && (row.visibility === "visible" || row.autoload_roles.length > 0)) {
      return failure("BHV-AUTOLOAD-MISMATCH", "A deprecated or removed skill remains an active consumer.");
    }
    if (row.loading === "autoload" !== (row.autoload_roles.length > 0)) {
      return failure("BHV-AUTOLOAD-MISMATCH", "A skill loading mode and its autoload roles disagree.");
    }
    const bodyLimit = row.loading === "autoload" ? BEHAVIOR_LIMITS.workerAutoloadBodyMaxTokens :
      BEHAVIOR_LIMITS.lazySkillBodyMaxTokens;
    if (row.body_max_tokens > bodyLimit) {
      return failure("BHV-BUDGET-EXCEEDED", "A selected skill exceeds its body budget.");
    }
    const source = provenance.get(row.provenance_id);
    if (!source || source.license_id !== row.license_id) {
      return failure("BHV-MANIFEST-INVALID", "A selected skill lacks matching provenance and license data.");
    }
    names.add(row.name);
    paths.add(row.path);
  }
  const visibleCount = manifest.skills.filter((row) => row.status === "active" && row.visibility === "visible").length;
  if (visibleCount > BEHAVIOR_LIMITS.visibleSkillHardCap) {
    return failure("BHV-BUDGET-EXCEEDED", "The visible skill roster exceeds its hard cap.");
  }
  return success(new Map(manifest.skills.map((row) => [row.name, row])));
}

function validateRoles(manifest, skills) {
  if (!exactKeys(manifest.roles, ["cheap-scout", "worker", "reviewer"])) {
    return failure("BHV-MANIFEST-INVALID", "The selected role roster is invalid.");
  }
  const expectedAutoload = {
    "cheap-scout": [],
    worker: ["evidence-before-completion"],
    reviewer: [],
  };
  for (const [name, row] of Object.entries(manifest.roles)) {
    if (!exactKeys(row, ROLE_KEYS) || row.agent_path !== `.omp/agents/${name}.md` ||
        !uniqueStrings(row.required_autoload) || !uniqueStrings(row.forbidden_responsibilities) ||
        !validBehaviorIds(row.behavior_ids) || !sameStringArray(row.required_autoload, expectedAutoload[name])) {
      return failure("BHV-AUTOLOAD-MISMATCH", "A role has an invalid required-autoload contract.");
    }
    for (const skillName of row.required_autoload) {
      const skill = skills.get(skillName);
      if (!skill || skill.status !== "active" || !skill.autoload_roles.includes(name)) {
        return failure("BHV-AUTOLOAD-MISMATCH", "A role requires an unavailable autoload skill.");
      }
    }
  }
  for (const row of manifest.skills) {
    const requiredBy = Object.entries(manifest.roles)
      .filter(([, role]) => role.required_autoload.includes(row.name))
      .map(([name]) => name);
    if (!sameStringArray(row.autoload_roles, requiredBy)) {
      return failure("BHV-AUTOLOAD-MISMATCH", "Skill and role autoload declarations disagree.");
    }
  }
  return success(true);
}

function validateCommands(value) {
  if (!exactKeys(value, ["quick", "standard", "orchestrated"])) return false;
  return Object.entries(value).every(([name, row]) => exactKeys(row, COMMAND_KEYS) &&
    row.path === `.omp/commands/${name}.md` && validBehaviorIds(row.behavior_ids));
}

function validateHooks(value) {
  if (!Array.isArray(value) || value.length === 0) return false;
  const names = new Set();
  for (const row of value) {
    if (!exactKeys(row, HOOK_KEYS) || !NAME_PATTERN.test(row.name) || names.has(row.name) ||
        !safeRelativePath(row.extension) || typeof row.boundary !== "string" || !row.boundary ||
        typeof row.predicate !== "string" || !row.predicate ||
        !["fail_closed", "fail_open"].includes(row.failure_policy) ||
        typeof row.error_prefix !== "string" || !row.error_prefix ||
        !["warn_only", "none"].includes(row.observation_policy) || !validBehaviorIds(row.behavior_ids)) return false;
    names.add(row.name);
  }
  return true;
}

function validateInjectionOwnership(manifest) {
  const owners = [];
  owners.push(["constitution", manifest.constitution.behavior_ids]);
  for (const row of manifest.skills) owners.push([`skill:${row.name}`, row.behavior_ids]);
  for (const [name, row] of Object.entries(manifest.roles)) owners.push([`role:${name}`, row.behavior_ids]);
  for (const [name, row] of Object.entries(manifest.commands)) owners.push([`command:${name}`, row.behavior_ids]);
  for (const row of manifest.hooks) owners.push([`hook:${row.name}`, row.behavior_ids]);

  const byBehavior = new Map();
  for (const [owner, behaviorIds] of owners) {
    for (const behaviorId of behaviorIds) {
      if (!byBehavior.has(behaviorId)) byBehavior.set(behaviorId, []);
      byBehavior.get(behaviorId).push(owner);
    }
  }
  const declared = new Set(manifest.constitution.intentional_duplications);
  if (!sameStringArray(manifest.constitution.intentional_duplications, ["evidence-before-completion"])) return false;
  for (const [behaviorId, behaviorOwners] of byBehavior) {
    if (behaviorOwners.length > 1 && !declared.has(behaviorId)) return false;
    if (behaviorOwners.length === 1 && declared.has(behaviorId)) return false;
  }
  return [...declared].every((behaviorId) => byBehavior.get(behaviorId)?.length === 2);
}

export function estimateApproxTokens(text) {
  if (typeof text !== "string") throw new TypeError("text must be a string");
  return Math.ceil(text.length / 4);
}

export function validateBehaviorManifest(value) {
  try {
    if (!exactKeys(value, TOP_LEVEL_KEYS)) {
      return failure("BHV-MANIFEST-INVALID", "The behavior manifest has an invalid top-level shape.");
    }
    if (Buffer.byteLength(canonicalJson(value), "utf8") > BEHAVIOR_LIMITS.maxManifestBytes) {
      return failure("BHV-BUDGET-EXCEEDED", "The behavior manifest exceeds its byte budget.");
    }
    if (value.schema_version !== 1 || value.record_type !== "portable_behavior_manifest" ||
        value.component !== "behavior-core" || !VERSION_PATTERN.test(value.component_version) ||
        !DATE_PATTERN.test(value.reviewed_on)) {
      return failure("BHV-MANIFEST-INVALID", "The behavior manifest identity is invalid.");
    }
    if (!exactKeys(value.constitution, ["path", "behavior_ids", "intentional_duplications"]) ||
        value.constitution.path !== ".omp/RULES.md" || !validBehaviorIds(value.constitution.behavior_ids) ||
        !uniqueStrings(value.constitution.intentional_duplications, { allowEmpty: false })) {
      return failure("BHV-MANIFEST-INVALID", "The portable constitution contract is invalid.");
    }
    if (!exactKeys(value.budgets, BUDGET_KEYS) ||
        BUDGET_KEYS.some((key) => value.budgets[key] !== EXPECTED_BUDGETS[key])) {
      return failure("BHV-BUDGET-EXCEEDED", "The declared behavior budgets differ from the approved limits.");
    }
    if (!validateProvenance(value.provenance)) {
      return failure("BHV-MANIFEST-INVALID", "The provenance registry is invalid.");
    }
    const skillResult = validateSkillRows(value);
    if (!skillResult.ok) return skillResult;
    const roleResult = validateRoles(value, skillResult.value);
    if (!roleResult.ok) return roleResult;
    if (!validateCommands(value.commands) || !validateHooks(value.hooks)) {
      return failure("BHV-MANIFEST-INVALID", "A command or hook row violates the closed behavior contract.");
    }
    if (!exactKeys(value.tools, ["external_capabilities"]) ||
        !exactKeys(value.tools.external_capabilities, ["policy_authority", "workflow_selection"]) ||
        value.tools.external_capabilities.policy_authority !== false ||
        value.tools.external_capabilities.workflow_selection !== false) {
      return failure("BHV-MANIFEST-INVALID", "External capabilities cannot own policy or workflow selection.");
    }
    if (!exactKeys(value.adapters, ["omp", "claude"]) ||
        !exactKeys(value.adapters.omp, ["status", "installable", "mappings"]) ||
        !exactKeys(value.adapters.claude, ["status", "installable", "mappings"]) ||
        !validateAdapterMappings(value.adapters.omp.mappings) ||
        !validateAdapterMappings(value.adapters.claude.mappings)) {
      return failure("BHV-ADAPTER-UNSUPPORTED", "The runtime adapter map is incomplete.");
    }
    const ompPairValid = (value.adapters.omp.status === "SELECTED_FOR_IMPLEMENTATION" &&
      value.adapters.omp.installable === false) ||
      (value.adapters.omp.status === "IMPLEMENTED_NOT_PROMOTED" && value.adapters.omp.installable === true);
    if (!ompPairValid || value.adapters.claude.status !== "DESIGNED_NOT_VERIFIED" ||
        value.adapters.claude.installable !== false) {
      return failure("BHV-ADAPTER-UNSUPPORTED", "A runtime adapter claims an unsupported status.");
    }
    if (!validateInjectionOwnership(value)) {
      return failure("BHV-MANIFEST-INVALID", "Behavior injection authority is duplicated or incomplete.");
    }
    return success(value);
  } catch {
    return failure("BHV-MANIFEST-INVALID", "The behavior manifest is not closed JSON-compatible data.");
  }
}

function normalizedPath(value) {
  const resolved = path.resolve(value);
  return process.platform === "win32" ? resolved.toLowerCase() : resolved;
}

export function reconcileBehaviorCatalog(input) {
  if (!isPlainObject(input)) return failure("BHV-MANIFEST-INVALID", "Catalog reconciliation input is invalid.");
  const manifestResult = validateBehaviorManifest(input.manifest);
  if (!manifestResult.ok) return manifestResult;
  if (typeof input.ompRoot !== "string" || !path.isAbsolute(input.ompRoot) ||
      !Array.isArray(input.skills) || !isPlainObject(input.agents) || !isPlainObject(input.fileHashes)) {
    return failure("BHV-MANIFEST-INVALID", "Catalog reconciliation evidence is incomplete.");
  }

  for (const row of input.manifest.skills.filter((skill) => skill.status === "active")) {
    const matches = input.skills.filter((candidate) => isPlainObject(candidate) && candidate.name === row.name);
    if (matches.length === 0 || matches[0].hide === true) {
      return failure("BHV-SKILL-MISSING", `Required skill ${row.name} is unavailable.`);
    }
    if (matches.length !== 1) {
      return failure("BHV-SKILL-SHADOWED", `Required skill ${row.name} is duplicated.`);
    }
    const expected = path.resolve(input.ompRoot, row.path.slice(".omp/".length));
    if (typeof matches[0].filePath !== "string" || normalizedPath(matches[0].filePath) !== normalizedPath(expected)) {
      return failure("BHV-SKILL-SHADOWED", `Required skill ${row.name} resolved outside the project adapter.`);
    }
    if (typeof input.fileHashes[row.path] !== "string" ||
        input.fileHashes[row.path].toLowerCase() !== row.sha256) {
      return failure("BHV-SKILL-HASH-MISMATCH", `Required skill ${row.name} differs from its reviewed hash.`);
    }
  }

  for (const [name, role] of Object.entries(input.manifest.roles)) {
    const effective = input.agents[name];
    if (!isPlainObject(effective) || !sameStringArray(effective.autoloadSkills ?? [], role.required_autoload)) {
      return failure("BHV-AUTOLOAD-MISMATCH", `Agent ${name} has an unexpected autoload binding.`);
    }
  }
  return success(input);
}

export function decideToolBoundary(input) {
  if (!isPlainObject(input) || typeof input.toolName !== "string") {
    return failure("BHV-HOOK-UNAVAILABLE", "The tool boundary cannot be evaluated.");
  }
  if (DIAGNOSTIC_TOOLS.has(input.toolName)) return { allow: true };
  if (input.toolName === "agent_tasks") {
    return input.sessionKind === "main" ? { allow: true } :
      failure("BHV-LIFECYCLE-FORBIDDEN", "The lifecycle tool is available only in the main session.");
  }
  if (!MUTATION_CAPABLE_TOOLS.has(input.toolName) && input.toolName !== "task") return { allow: true };
  if (input.hookAvailable === false || input.behaviorReady === false) {
    return failure(input.hookAvailable === false ? "BHV-HOOK-UNAVAILABLE" : "BHV-MANIFEST-INVALID",
      "The managed behavior preflight is unavailable.");
  }
  if (input.sessionKind === "child") {
    return input.childPacketValid === true ? { allow: true } :
      failure("BHV-STATE-MISSING", "The bounded child lacks a validated task packet.");
  }
  if (input.stateKind === "one") return { allow: true };
  if (input.stateKind === "ambiguous" || input.stateKind === "many") {
    return failure("BHV-STATE-AMBIGUOUS", "The current session has multiple managed task bindings.");
  }
  return failure("BHV-STATE-MISSING", "The current session lacks one managed task binding.");
}

export { LIFECYCLE_OPERATIONS };
