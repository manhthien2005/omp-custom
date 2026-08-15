import fs from "node:fs";
import crypto from "node:crypto";
import path from "node:path";
import { fileURLToPath } from "node:url";

import * as core from "../contracts/agent-boundary-core.mjs";
import {
  invokeManagedState,
  parseManagedStateEnvelope,
} from "../contracts/managed-state-client.mjs";
import {
  LIMITS,
  SEMANTIC_OUTPUT_SCHEMAS,
  SHA256_PATTERN,
} from "../contracts/agent-boundary-schema.mjs";
import {
  CONTEXT_PRESSURE_ABORT_MARKER,
  consumeContextPressureAbort,
  validateContinuityKernel,
} from "../contracts/context-continuity-core.mjs";
import * as behaviorCore from "../contracts/behavior-core.mjs";
import {
  DIAGNOSTIC_TOOLS,
  LIFECYCLE_OPERATIONS,
  MUTATION_CAPABLE_TOOLS,
} from "../contracts/behavior-core-schema.mjs";

export const MANAGED_BATCH_CONTEXT = core.canonicalJson({
  packet_type: "agent_dispatch_batch_context",
  schema_version: 1,
  statement: "Each task field is one complete independent canonical Topic 06 packet.",
});

const AGENT_POLICY = Object.freeze({
  "cheap-scout": Object.freeze({
    role: "cheap_scout",
    model: "@cheap-scout",
    thinkingLevel: "xhigh",
    tools: Object.freeze(["read", "grep", "glob", "web_search"]),
  }),
  worker: Object.freeze({
    role: "worker",
    model: "@worker",
    thinkingLevel: "high",
    tools: Object.freeze(["read", "grep", "glob", "edit", "write", "bash"]),
  }),
  reviewer: Object.freeze({
    role: "reviewer",
    model: "@reviewer",
    thinkingLevel: "xhigh",
    tools: Object.freeze(["read", "grep", "glob", "bash"]),
  }),
});

function isPlainObject(value) {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function exactKeys(value, allowed, required = allowed) {
  if (!isPlainObject(value)) return false;
  const actual = Object.keys(value);
  return actual.every((key) => allowed.includes(key)) && required.every((key) => Object.hasOwn(value, key));
}

function fail(reasonCode, message) {
  return {
    ok: false,
    reason_code: reasonCode,
    message: String(message).slice(0, 240) || "The managed boundary refused the operation.",
  };
}

function throwUnavailable() {
  throw new Error("managed_component_unavailable");
}

function comparablePath(value) {
  const resolved = path.resolve(value).replace(/[\\/]+$/u, "");
  return process.platform === "win32" ? resolved.toLowerCase() : resolved;
}

function pathInside(root, candidate) {
  if (typeof root !== "string" || typeof candidate !== "string" ||
      !path.isAbsolute(root) || !path.isAbsolute(candidate)) return false;
  const relative = path.relative(path.resolve(root), path.resolve(candidate));
  return relative !== "" && relative !== ".." && !relative.startsWith(`..${path.sep}`) && !path.isAbsolute(relative);
}

function validateRuntime(runtime, expectedTargetOmp) {
  const minimal = exactKeys(runtime, ["schema_version", "record_type", "target_omp", "paths", "capabilities"]) &&
    exactKeys(runtime?.paths, ["pwsh", "state_cli"]);
  const installed = exactKeys(runtime, [
    "schema_version", "record_type", "component", "component_version", "created_at_utc", "target_omp",
    "component_manifest_sha256", "installed_omp_version", "supported_omp_versions", "paths", "capabilities", "policy",
  ]) && exactKeys(runtime?.paths, [
    "pwsh", "omp", "state_cli", "wrapper", "overlay", "launcher", "manifest", "core", "schema", "cli",
    "config", "state_manifest", "state_client", "continuity_schema", "continuity_core",
    "continuity_adapter", "agents",
  ]);
  if ((!minimal && !installed) ||
      runtime.schema_version !== 2 || runtime.record_type !== "agent_boundary_runtime" ||
      typeof runtime.target_omp !== "string" || !path.isAbsolute(runtime.target_omp) ||
      typeof runtime.paths.pwsh !== "string" || !path.isAbsolute(runtime.paths.pwsh) ||
      typeof runtime.paths.state_cli !== "string" || !path.isAbsolute(runtime.paths.state_cli) ||
      !pathInside(runtime.target_omp, runtime.paths.state_cli) ||
      !exactKeys(runtime.capabilities, ["batch", "isolation", "effort", "max_effort", "continuity"]) ||
      typeof runtime.capabilities.batch !== "boolean" ||
      typeof runtime.capabilities.isolation !== "boolean" ||
      typeof runtime.capabilities.effort !== "boolean" ||
      runtime.capabilities.continuity !== true ||
      !["high", "xhigh"].includes(runtime.capabilities.max_effort)) {
    throwUnavailable();
  }
  if (installed && (runtime.component !== "agent-boundary" || runtime.component_version !== "2.1.0" ||
      typeof runtime.created_at_utc !== "string" ||
      typeof runtime.component_manifest_sha256 !== "string" || !SHA256_PATTERN.test(runtime.component_manifest_sha256) ||
      typeof runtime.installed_omp_version !== "string" ||
      !Array.isArray(runtime.supported_omp_versions) ||
      core.canonicalJson(runtime.supported_omp_versions) !== core.canonicalJson(["17.2.10", "17.2.12"]) ||
      !exactKeys(runtime.paths.agents, ["cheap-scout", "worker", "reviewer"]) ||
      !exactKeys(runtime.policy, [
        "soft_request_budget", "forced_partial_requests", "role_policy_sha256", "continuity_policy_sha256",
      ]) ||
      runtime.policy.soft_request_budget !== 200 || runtime.policy.forced_partial_requests !== 300 ||
      typeof runtime.policy.role_policy_sha256 !== "string" || !SHA256_PATTERN.test(runtime.policy.role_policy_sha256) ||
      typeof runtime.policy.continuity_policy_sha256 !== "string" ||
      !SHA256_PATTERN.test(runtime.policy.continuity_policy_sha256))) {
    throwUnavailable();
  }
  if (expectedTargetOmp !== undefined && comparablePath(runtime.target_omp) !== comparablePath(expectedTargetOmp)) {
    throwUnavailable();
  }
  return runtime;
}

function sha256File(file) {
  if (!fs.existsSync(file) || !fs.statSync(file).isFile()) throwUnavailable();
  return crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

function deepFreeze(value) {
  if (value === null || typeof value !== "object" || Object.isFrozen(value)) return value;
  for (const child of Object.values(value)) deepFreeze(child);
  return Object.freeze(value);
}

export function loadBehaviorManifest(moduleUrl = import.meta.url) {
  try {
    const modulePath = fileURLToPath(moduleUrl);
    const targetOmp = path.resolve(path.dirname(modulePath), "..");
    const manifestPath = path.join(targetOmp, "contracts", "behavior-manifest.json");
    const componentPath = path.join(targetOmp, "contracts", "component-manifest.json");
    const realTarget = fs.realpathSync(targetOmp);
    for (const candidate of [manifestPath, componentPath]) {
      if (!pathInside(realTarget, fs.realpathSync(candidate)) || fs.lstatSync(candidate).isSymbolicLink()) {
        throwUnavailable();
      }
    }
    const manifest = readClosedJsonFile(manifestPath);
    const validation = behaviorCore.validateBehaviorManifest(manifest);
    if (!validation.ok) throwUnavailable();
    const component = readClosedJsonFile(componentPath);
    if (!Array.isArray(component.files)) throwUnavailable();
    for (const relativePath of [
      ".omp/contracts/behavior-core-schema.mjs",
      ".omp/contracts/behavior-core.mjs",
      ".omp/contracts/behavior-manifest.json",
    ]) {
      const rows = component.files.filter((row) => isPlainObject(row) && row.path === relativePath);
      if (rows.length !== 1 || rows[0].owned !== true || rows[0].sha256 !== sha256File(installedPath(targetOmp, relativePath))) {
        throwUnavailable();
      }
    }
    return deepFreeze(validation.value);
  } catch {
    throwUnavailable();
  }
}

function readClosedJsonFile(file) {
  if (!fs.existsSync(file) || !fs.statSync(file).isFile()) throwUnavailable();
  return core.parseJsonNoDuplicateKeys(fs.readFileSync(file, "utf8"));
}

function installedPath(targetOmp, relative) {
  if (typeof relative !== "string" || !relative.startsWith(".omp/") || relative.includes("\\") ||
      relative.split("/").some((part) => !part || part === "." || part === "..")) throwUnavailable();
  const candidate = path.resolve(targetOmp, relative.slice(".omp/".length));
  if (!pathInside(targetOmp, candidate)) throwUnavailable();
  return candidate;
}

function samePath(left, right) {
  return typeof left === "string" && typeof right === "string" && comparablePath(left) === comparablePath(right);
}

function assertInstalledConfig(file) {
  const text = fs.readFileSync(file, "utf8");
  const patterns = [
    /^\s{2}cheap-scout:\s+omniroute\/ds\/deepseek-v4-flash:xhigh\s*$/gmu,
    /^\s{2}worker:\s+omniroute\/codex\/gpt-5\.6-sol:high\s*$/gmu,
    /^\s{2}reviewer:\s+omniroute\/codex\/gpt-5\.6-sol:xhigh\s*$/gmu,
    /^\s{2}modelFallback:\s+true\s*$/gmu,
    /^\s{2}usageAwareFallback:\s+false\s*$/gmu,
    /^\s{6}-\s+omniroute\/ds\/deepseek-v4-pro:xhigh\s*$/gmu,
    /^\s{2}enableEffort:\s+true\s*$/gmu,
    /^\s{2}maxEffort:\s+xhigh\s*$/gmu,
  ];
  if (patterns.some((pattern) => [...text.matchAll(pattern)].length !== 1)) throwUnavailable();
}

function validateInstalledRuntime(runtime, modulePath, runtimePath) {
  const targetOmp = runtime.target_omp;
  const expectedPaths = {
    state_cli: path.join(targetOmp, "state", "agent-tasks.ps1"),
    wrapper: path.join(targetOmp, "extensions", "agent-task-boundary.js"),
    overlay: path.join(targetOmp, "contracts", "managed-runtime.yml"),
    launcher: path.join(targetOmp, "bin", "omp-managed.ps1"),
    manifest: path.join(targetOmp, "contracts", "component-manifest.json"),
    core: path.join(targetOmp, "contracts", "agent-boundary-core.mjs"),
    schema: path.join(targetOmp, "contracts", "agent-boundary-schema.mjs"),
    cli: path.join(targetOmp, "contracts", "agent-boundary-cli.mjs"),
    config: path.join(targetOmp, "config.yml"),
    state_manifest: path.join(targetOmp, "state", "manifest.json"),
    state_client: path.join(targetOmp, "contracts", "managed-state-client.mjs"),
    continuity_schema: path.join(targetOmp, "contracts", "context-continuity-schema.mjs"),
    continuity_core: path.join(targetOmp, "contracts", "context-continuity-core.mjs"),
    continuity_adapter: path.join(targetOmp, "extensions", "context-continuity.js"),
  };
  for (const [name, expected] of Object.entries(expectedPaths)) {
    if (!samePath(runtime.paths[name], expected)) throwUnavailable();
  }
  for (const name of ["cheap-scout", "worker", "reviewer"]) {
    if (!samePath(runtime.paths.agents[name], path.join(targetOmp, "agents", `${name}.md`))) throwUnavailable();
  }
  if (!samePath(runtime.paths.wrapper, modulePath) || !samePath(runtimePath, path.join(targetOmp, "contracts", "runtime.json")) ||
      typeof runtime.paths.omp !== "string" || !path.isAbsolute(runtime.paths.omp) ||
      !fs.existsSync(runtime.paths.omp) || !fs.statSync(runtime.paths.omp).isFile()) throwUnavailable();

  const installRecordPath = path.join(targetOmp, "contracts", "install-record.json");
  const record = readClosedJsonFile(installRecordPath);
  if (!exactKeys(record, [
    "schema_version", "record_type", "component", "component_version", "installed_at_utc", "target_omp", "backup_dir",
    "component_manifest_sha256", "runtime_sha256", "installed_paths", "installed_hashes", "generated_paths",
    "operational_state_policy",
  ]) || record.schema_version !== 2 || record.record_type !== "agent_boundary_install_record" ||
      record.component !== "agent-boundary" || record.component_version !== "2.1.0" ||
      !samePath(record.target_omp, targetOmp) || record.component_manifest_sha256 !== runtime.component_manifest_sha256 ||
      record.runtime_sha256 !== sha256File(runtimePath) || record.operational_state_policy !== "retain_outside_target_omp") {
    throwUnavailable();
  }

  const manifest = readClosedJsonFile(runtime.paths.manifest);
  if (sha256File(runtime.paths.manifest) !== runtime.component_manifest_sha256 ||
      !exactKeys(manifest, [
        "schema_version", "record_type", "component", "component_version", "minimum_pwsh_version",
        "supported_omp_versions", "role_policy", "continuity_policy", "dependencies", "files", "generated_target_files",
      ]) || manifest.schema_version !== 2 || manifest.record_type !== "agent_boundary_component_manifest" ||
      manifest.component !== "agent-boundary" || manifest.component_version !== "2.1.0" ||
      core.canonicalJson(manifest.supported_omp_versions) !== core.canonicalJson(runtime.supported_omp_versions) ||
      crypto.createHash("sha256").update(JSON.stringify(manifest.role_policy), "utf8").digest("hex") !==
        runtime.policy.role_policy_sha256 ||
      crypto.createHash("sha256").update(JSON.stringify(manifest.continuity_policy), "utf8").digest("hex") !==
        runtime.policy.continuity_policy_sha256 || !Array.isArray(manifest.files) || manifest.files.length !== 20) {
    throwUnavailable();
  }
  const seen = new Set();
  let ownedCount = 0;
  for (const row of manifest.files) {
    if (!exactKeys(row, ["path", "sha256", "owned"]) || typeof row.path !== "string" ||
        typeof row.sha256 !== "string" || !SHA256_PATTERN.test(row.sha256) || typeof row.owned !== "boolean" ||
        seen.has(row.path)) throwUnavailable();
    seen.add(row.path);
    if (row.owned) ownedCount += 1;
    if (sha256File(installedPath(targetOmp, row.path)) !== row.sha256) throwUnavailable();
  }
  if (ownedCount !== 13) throwUnavailable();
  if (fs.readFileSync(runtime.paths.overlay, "utf8") !== [
    "task:", "  softRequestBudget: 200", "contextPromotion:", "  enabled: false", "compaction:",
    "  enabled: false", "  strategy: off", "  midTurnEnabled: false", "  thresholdPercent: -1",
    "  thresholdTokens: -1", "  keepRecentTokens: 20000", "  autoContinue: false", "  idleEnabled: false",
    "  remoteEnabled: false", "  remoteStreamingV2Enabled: false", "  supersedeReads: true",
    "  dropUseless: true", "",
  ].join("\n")) throwUnavailable();
  assertInstalledConfig(runtime.paths.config);
  return runtime;
}

export async function loadManagedRuntime(moduleUrl = import.meta.url) {
  try {
    const modulePath = fileURLToPath(moduleUrl);
    const targetOmp = path.resolve(path.dirname(modulePath), "..");
    const runtimePath = path.join(targetOmp, "contracts", "runtime.json");
    if (!fs.existsSync(runtimePath) || !fs.statSync(runtimePath).isFile()) throwUnavailable();
    const raw = fs.readFileSync(runtimePath, "utf8");
    const runtime = core.parseJsonNoDuplicateKeys(raw);
    validateRuntime(runtime, targetOmp);
    return validateInstalledRuntime(runtime, modulePath, runtimePath);
  } catch {
    throwUnavailable();
  }
}

export function deriveActiveMode(entries) {
  return core.deriveActiveMode(entries);
}

function normalizeEffectiveRequest(request) {
  if (request.agent !== "worker") return { ...request };
  return {
    ...request,
    effort: request.effort ?? "high",
    isolated: request.isolated ?? false,
  };
}

function nativeItem({ request, composed }) {
  const item = {
    name: `${request.agent}-${request.work_unit_id}`,
    agent: request.agent,
    task: composed.canonical,
  };
  if (request.agent === "worker" && request.isolated === true) item.isolated = true;
  if (request.agent === "worker" && request.effort === "xhigh") item.effort = "hi";
  return item;
}

export function buildNativeTaskParams(composedItems) {
  if (!Array.isArray(composedItems) || composedItems.length === 0 || composedItems.length > LIMITS.maxBatchItems) {
    throw new Error("packet_invalid");
  }
  const items = composedItems.map(nativeItem);
  return items.length === 1 ? items[0] : { context: MANAGED_BATCH_CONTEXT, tasks: items };
}

export { parseManagedStateEnvelope as parseStateEnvelope };

function reconcileAgentCatalog(catalog) {
  if (!isPlainObject(catalog) || !Array.isArray(catalog.agents)) throwUnavailable();
  const selectedNames = new Set(Object.keys(AGENT_POLICY));
  const selected = catalog.agents.filter((agent) => isPlainObject(agent) && selectedNames.has(agent.name));
  if (selected.length !== selectedNames.size) throwUnavailable();
  const reconciled = {};
  for (const name of selectedNames) {
    const matches = selected.filter((agent) => agent.name === name);
    if (matches.length !== 1) throwUnavailable();
    const agent = matches[0];
    const policy = AGENT_POLICY[name];
    const spawns = agent.spawns ?? [];
    const effectiveTools = [...policy.tools, "yield"];
    if (agent.source !== "project" || !Array.isArray(agent.model) || agent.model.length !== 1 ||
        agent.model[0] !== policy.model || agent.thinkingLevel !== policy.thinkingLevel ||
        agent.blocking !== true || !Array.isArray(spawns) || spawns.length !== 0 ||
        !Array.isArray(agent.tools) || core.canonicalJson(agent.tools) !== core.canonicalJson(effectiveTools) ||
        core.sha256Canonical(agent.output) !== core.sha256Canonical(SEMANTIC_OUTPUT_SCHEMAS[policy.role])) {
      throwUnavailable();
    }
    reconciled[name] = Object.freeze({
      name,
      role: policy.role,
      model: policy.model,
      thinkingLevel: policy.thinkingLevel,
    });
  }
  return Object.freeze(reconciled);
}

function buildParameters(pi) {
  const { Type } = pi.typebox;
  const common = (agent, role) => ({
    task_id: Type.String({ pattern: "^T[0-9]{6}$" }),
    work_unit_id: Type.String({ pattern: "^WU-[A-Z0-9][A-Z0-9._-]{0,79}$" }),
    agent: Type.Literal(agent),
    role: Type.Literal(role),
  });
  const cheapScout = Type.Object(common("cheap-scout", "cheap_scout"), { additionalProperties: false });
  const worker = Type.Object({
    ...common("worker", "worker"),
    effort: Type.Optional(Type.Union([Type.Literal("high"), Type.Literal("xhigh")])),
    isolated: Type.Optional(Type.Boolean()),
  }, { additionalProperties: false });
  const reviewer = Type.Object(common("reviewer", "reviewer"), { additionalProperties: false });
  const item = Type.Union([cheapScout, worker, reviewer]);
  const batch = Type.Object({
    tasks: Type.Array(item, { minItems: 1, maxItems: LIMITS.maxBatchItems }),
  }, { additionalProperties: false });
  return Type.Union([cheapScout, worker, reviewer, batch]);
}

function buildAgentTasksParameters(pi) {
  const { Type } = pi.typebox;
  const operations = [...LIFECYCLE_OPERATIONS].map((operation) => Type.Literal(operation));
  return Type.Object({
    operation: Type.Union(operations),
    request: Type.Record(Type.String(), Type.Unknown()),
  }, { additionalProperties: false });
}

class BehaviorUnavailableError extends Error {
  constructor(reasonCode, message) {
    super(message);
    this.name = "BehaviorUnavailableError";
    this.reason_code = reasonCode;
  }
}

function buildCatalogSnapshot({ runtime, manifest, agentCatalog, skillCatalog }) {
  if (!isPlainObject(agentCatalog) || !Array.isArray(agentCatalog.agents) ||
      !isPlainObject(skillCatalog) || !Array.isArray(skillCatalog.skills)) {
    throw new BehaviorUnavailableError("BHV-HOOK-UNAVAILABLE", "OMP discovery returned an invalid catalog.");
  }
  const agents = {};
  for (const name of Object.keys(manifest.roles)) {
    const matches = agentCatalog.agents.filter((row) => isPlainObject(row) && row.name === name);
    if (matches.length !== 1) {
      throw new BehaviorUnavailableError("BHV-AUTOLOAD-MISMATCH", `Agent ${name} is missing or duplicated.`);
    }
    agents[name] = { autoloadSkills: [...(matches[0].autoloadSkills ?? [])] };
  }
  const fileHashes = {};
  for (const skill of manifest.skills.filter((row) => row.status === "active")) {
    const installed = installedPath(runtime.target_omp, skill.path);
    if (!fs.existsSync(installed) || !fs.statSync(installed).isFile()) {
      throw new BehaviorUnavailableError("BHV-SKILL-MISSING", `Required skill ${skill.name} is missing.`);
    }
    fileHashes[skill.path] = sha256File(installed);
  }
  return {
    manifest,
    ompRoot: runtime.target_omp,
    agents,
    skills: skillCatalog.skills.map((row) => ({
      name: row?.name,
      filePath: row?.filePath,
      hide: row?.hide === true,
    })),
    fileHashes,
  };
}

export async function reconcileEffectiveBehavior({ pi, runtime: runtimeInput, manifest }) {
  const runtime = validateRuntime(runtimeInput);
  const validation = behaviorCore.validateBehaviorManifest(manifest);
  if (!validation.ok) throw new BehaviorUnavailableError(validation.reason_code, validation.message);
  if (!pi?.pi || typeof pi.pi.discoverAgents !== "function" || typeof pi.pi.discoverSkills !== "function") {
    throw new BehaviorUnavailableError("BHV-HOOK-UNAVAILABLE", "OMP behavior discovery is unavailable.");
  }
  let agentCatalog;
  let skillCatalog;
  try {
    [agentCatalog, skillCatalog] = await Promise.all([
      pi.pi.discoverAgents(pi.cwd),
      pi.pi.discoverSkills(pi.cwd),
    ]);
  } catch {
    throw new BehaviorUnavailableError("BHV-HOOK-UNAVAILABLE", "OMP behavior discovery failed.");
  }
  const snapshot = buildCatalogSnapshot({ runtime, manifest: validation.value, agentCatalog, skillCatalog });
  const result = behaviorCore.reconcileBehaviorCatalog(snapshot);
  if (!result.ok) throw new BehaviorUnavailableError(result.reason_code, result.message);
  return { agentCatalog, skillCatalog, behavior: result };
}

function inspectBehaviorSession(ctx) {
  try {
    const sessionId = ctx?.sessionManager?.getSessionId?.();
    const branch = ctx?.sessionManager?.getBranch?.();
    if (typeof sessionId !== "string" || sessionId.trim().length === 0 || !Array.isArray(branch)) {
      return { kind: "invalid", agent: null, packet: null, reason_code: "BHV-STATE-MISSING" };
    }
    const entries = branch.filter((entry) => isPlainObject(entry) && entry.type === "session_init");
    if (entries.length === 0) return { kind: "main", agent: null, packet: null, sessionId };
    if (entries.length !== 1) {
      return { kind: "invalid", agent: null, packet: null, reason_code: "BHV-STATE-AMBIGUOUS", sessionId };
    }
    const entry = entries[0];
    if (!Object.hasOwn(AGENT_POLICY, entry.agent) || typeof entry.systemPrompt !== "string" ||
        !entry.systemPrompt.trim() || typeof entry.task !== "string" || !entry.task.trim() ||
        !Array.isArray(entry.tools) || entry.tools.length === 0 ||
        entry.tools.some((tool) => typeof tool !== "string" || !tool) || new Set(entry.tools).size !== entry.tools.length) {
      return { kind: "invalid", agent: null, packet: null, reason_code: "BHV-STATE-MISSING", sessionId };
    }
    const packet = core.parseJsonNoDuplicateKeys(entry.task);
    const validation = core.validatePacket(packet);
    if (!validation.ok || core.canonicalJson(validation.value) !== entry.task ||
        validation.value.role !== AGENT_POLICY[entry.agent].role) {
      return { kind: "invalid", agent: null, packet: null, reason_code: "BHV-STATE-MISSING", sessionId };
    }
    return { kind: "child", agent: entry.agent, packet: validation.value, sessionId };
  } catch {
    return { kind: "invalid", agent: null, packet: null, reason_code: "BHV-STATE-MISSING" };
  }
}

function behaviorBlock(reasonCode, message) {
  return {
    block: true,
    reason: `${reasonCode}: ${String(message).slice(0, 180)}`,
  };
}

export function createBehaviorToolCallHandler({ pi, runtime: runtimeInput, manifest, dependencies = {} }) {
  const runtime = validateRuntime(runtimeInput);
  const validation = behaviorCore.validateBehaviorManifest(manifest);
  if (!validation.ok) throw new BehaviorUnavailableError(validation.reason_code, validation.message);
  const invokeState = dependencies.invokeState ?? ((operation, request, ctx) => invokeManagedState({
    pwshPath: runtime.paths.pwsh,
    stateCliPath: runtime.paths.state_cli,
    operation,
    request,
    ctx,
    acceptNonzeroFailureEnvelope: true,
  }));
  const observe = dependencies.observe;

  return async function behaviorToolCallHandler(event, ctx) {
    const toolName = event?.toolName;
    let decision;
    if (DIAGNOSTIC_TOOLS.has(toolName) || toolName === "agent_tasks" ||
        (!MUTATION_CAPABLE_TOOLS.has(toolName) && toolName !== "task")) {
      decision = undefined;
    } else if (toolName === "task") {
      decision = undefined;
    } else {
      const session = inspectBehaviorSession(ctx);
      if (session.kind === "invalid") {
        decision = behaviorBlock(session.reason_code, "The managed session identity is missing or ambiguous.");
      } else if (session.kind === "child") {
        decision = AGENT_POLICY[session.agent].tools.includes(toolName) ? undefined :
          behaviorBlock("BHV-LIFECYCLE-FORBIDDEN", `Agent ${session.agent} cannot use ${toolName}.`);
      } else {
        try {
          const state = await invokeState("project-continuity", {}, ctx);
          if (!isPlainObject(state) || state.operation !== "project-continuity" || state.ok !== true) {
            const ambiguous = typeof state?.code === "string" && /AMBIGUOUS/u.test(state.code);
            decision = behaviorBlock(ambiguous ? "BHV-STATE-AMBIGUOUS" : "BHV-STATE-MISSING",
              "The main session lacks one current managed task binding.");
          } else {
            const kernel = validateContinuityKernel(state.data);
            if (!kernel.ok || kernel.value.lifecycle.owner_session_ref !== session.sessionId) {
              decision = behaviorBlock("BHV-STATE-MISSING", "The continuity projection does not bind this session.");
            } else if (kernel.value.task.execution_mode !== "mutating") {
              decision = behaviorBlock("BHV-LIFECYCLE-FORBIDDEN", "The current task is read-only.");
            } else decision = undefined;
          }
        } catch {
          decision = behaviorBlock("BHV-HOOK-UNAVAILABLE", "The managed state predicate could not be evaluated.");
        }
      }
    }
    try {
      observe?.({ toolName, blocked: decision?.block === true, reason: decision?.reason ?? null });
    } catch {
      try { pi?.logger?.warn?.("Topic 08 behavior observation failed."); } catch { /* best effort */ }
    }
    return decision;
  };
}

function isMainSession(ctx) {
  try {
    const sessionId = ctx?.sessionManager?.getSessionId?.();
    const branch = ctx?.sessionManager?.getBranch?.();
    if (typeof sessionId !== "string" || sessionId.trim().length === 0 || !Array.isArray(branch)) return false;
    const sessionInit = branch.filter((entry) => isPlainObject(entry) && entry.type === "session_init");
    return sessionInit.length === 0;
  } catch {
    return false;
  }
}

function lifecycleToolFailure(operation, reasonCode) {
  const safeOperation = typeof operation === "string" && operation.length > 0 ? operation.slice(0, 80) : "unknown";
  const safeReason = typeof reasonCode === "string" && reasonCode.length > 0 ? reasonCode.slice(0, 80) :
    "BHV-HOOK-UNAVAILABLE";
  return {
    content: [{
      type: "text",
      text: `Managed task lifecycle refused ${safeOperation} (${safeReason}). Correct the bounded request or continue with read-only diagnosis.`,
    }],
    details: {
      schema_version: 1,
      record_type: "agent_tasks_tool_details",
      operation: safeOperation,
      ok: false,
      code: safeReason,
      data: { reason_code: safeReason },
    },
    isError: true,
  };
}

function lifecycleToolResult(envelope) {
  if (!exactKeys(envelope, ["ok", "code", "operation", "data"]) ||
      typeof envelope.ok !== "boolean" || typeof envelope.code !== "string" || !envelope.code ||
      typeof envelope.operation !== "string" || !envelope.operation || !isPlainObject(envelope.data)) {
    return lifecycleToolFailure("unknown", "BHV-HOOK-UNAVAILABLE");
  }
  return {
    content: [{
      type: "text",
      text: envelope.ok ? "Managed task lifecycle operation settled." :
        `Managed task lifecycle operation was refused (${envelope.code}).`,
    }],
    details: {
      schema_version: 1,
      record_type: "agent_tasks_tool_details",
      operation: envelope.operation,
      ok: envelope.ok,
      code: envelope.code,
      data: envelope.data,
    },
    isError: envelope.ok !== true,
  };
}

export function createAgentTasksTool(pi, runtimeInput, dependencies = {}) {
  const runtime = validateRuntime(runtimeInput);
  const invokeState = dependencies.invokeState ?? ((operation, request, ctx, signal) =>
    invokeManagedState({
      pwshPath: runtime.paths.pwsh,
      stateCliPath: runtime.paths.state_cli,
      operation,
      request,
      ctx,
      signal,
      acceptNonzeroFailureEnvelope: true,
    }));
  const observe = dependencies.observe;

  return {
    name: "agent_tasks",
    label: "Managed Task Lifecycle",
    description: "Apply one explicit structured Topic 04 lifecycle operation after the task contract is accepted.",
    loadMode: "essential",
    approval: "exec",
    strict: true,
    parameters: buildAgentTasksParameters(pi),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      if (!exactKeys(params, ["operation", "request"]) || !isPlainObject(params.request) ||
          !isMainSession(ctx) || !LIFECYCLE_OPERATIONS.has(params.operation)) {
        return lifecycleToolFailure(params?.operation, "BHV-LIFECYCLE-FORBIDDEN");
      }
      try {
        const envelope = await invokeState(params.operation, params.request, ctx, signal);
        const result = lifecycleToolResult(envelope);
        try {
          observe?.({ operation: params.operation, ok: result.details.ok, code: result.details.code });
        } catch {
          try { pi?.logger?.warn?.("Topic 08 lifecycle observation failed."); } catch { /* best effort */ }
        }
        return result;
      } catch (error) {
        return lifecycleToolFailure(params.operation,
          signal?.aborted || error?.message === "cancelled" ? "cancelled" : "BHV-HOOK-UNAVAILABLE");
      }
    },
  };
}

function stateFailureReason(envelope, operation) {
  if (!isPlainObject(envelope) || envelope.ok !== false || typeof envelope.code !== "string") return "state_unavailable";
  if (/WORK-UNIT-(?:NOT-FOUND|UNLISTED)/u.test(envelope.code)) return "work_unit_missing";
  if (/TASK-(?:NOT-FOUND|STATUS)/u.test(envelope.code)) return "task_not_active";
  if (operation === "record-work-unit-outcome" && /CAS/u.test(envelope.code)) return "outcome_record_failed";
  return "state_unavailable";
}

function runtimeCapabilityFailure(items, runtime, modeResult) {
  const hasWorker = items.some((item) => item.agent === "worker");
  if (!modeResult.ok && hasWorker) return modeResult.reason_code;
  if (hasWorker && modeResult.mode === "plan") return "plan_mode_incompatible";
  if (items.length > 1 && runtime.capabilities.batch !== true) return "native_task_unavailable";
  for (const item of items) {
    if (item.agent !== "worker") continue;
    if (item.isolated === true && runtime.capabilities.isolation !== true) return "isolation_unavailable";
    if (item.effort === "xhigh" &&
        (runtime.capabilities.effort !== true || runtime.capabilities.max_effort !== "xhigh")) return "effort_mismatch";
  }
  return null;
}

function defaultArtifactExists(candidate, root) {
  try {
    if (!fs.statSync(candidate).isFile()) return false;
    const realRoot = fs.realpathSync(root);
    const realCandidate = fs.realpathSync(candidate);
    return pathInside(realRoot, realCandidate);
  } catch {
    return false;
  }
}

function validateNativeArtifacts(details, items, artifactExists) {
  if (!isPlainObject(details) || typeof details.projectAgentsDir !== "string" ||
      !path.isAbsolute(details.projectAgentsDir) || !Array.isArray(details.results) ||
      details.results.length !== items.length) return fail("result_unsettled", "Native artifact details are incomplete.");
  const root = details.projectAgentsDir;
  for (let index = 0; index < items.length; index += 1) {
    const result = details.results.find((candidate) => isPlainObject(candidate) && candidate.index === index);
    if (!result) return fail("result_unsettled", "A native result is missing.");
    if (result.topic07AbortMarker === CONTEXT_PRESSURE_ABORT_MARKER &&
        (result.aborted === true || result.truncated === true || result.exitCode !== 0 ||
         result.structuredOutput?.data?.status === "partial")) continue;
    if (typeof result.outputPath !== "string" || !pathInside(root, result.outputPath) ||
        artifactExists(result.outputPath, root) !== true) {
      return fail("artifact_stale", "A native output artifact is missing or outside its managed root.");
    }
    if (Object.hasOwn(result, "nestedPatches") &&
        (!Array.isArray(result.nestedPatches) || result.nestedPatches.length !== 0)) {
      return fail("artifact_stale", "Nested isolation artifacts are not accepted by this boundary.");
    }
    const isolated = items[index].isolated === true;
    if (Object.hasOwn(result, "patchPath")) {
      if (typeof result.patchPath !== "string" || !pathInside(root, result.patchPath) ||
          artifactExists(result.patchPath, root) !== true) {
        return fail("artifact_stale", "A native isolation artifact is missing or outside its managed root.");
      }
    }
    const hasBranch = typeof result.branchName === "string" && result.branchName.length > 0 &&
      typeof result.branchBaseSha === "string" && SHA256_PATTERN.test(result.branchBaseSha);
    if (isolated) {
      if (!Object.hasOwn(result, "patchPath") && !hasBranch) {
        return fail("artifact_stale", "The selected isolated Worker returned no bounded patch or branch artifact.");
      }
    } else if (Object.hasOwn(result, "patchPath") || Object.hasOwn(result, "branchName") ||
               Object.hasOwn(result, "branchBaseSha") || Object.hasOwn(result, "nestedPatches")) {
      return fail("artifact_stale", "A non-isolated result returned unexpected isolation metadata.");
    }
  }
  return { ok: true };
}

function failedReceipt(role, reasonCode) {
  return {
    schema_version: 1,
    record_type: "agent_boundary_receipt",
    status: "failed",
    reason_code: reasonCode,
    role,
    semantic_result: null,
    runtime: {
      structured_output: "not_validated",
      model_role: "not_observed",
      resolved_model: "not_observed",
      fallback_used: false,
      effort: "not_observed",
      aborted: reasonCode === "cancelled" || reasonCode === "context_pressure",
      forced_partial: reasonCode === "forced_partial",
      omniroute_upstream: "not_observed",
    },
    outcome: { recorded: false, status: "failed", artifact_refs: [] },
  };
}

function aggregateStatus(receipts) {
  const statuses = receipts.map((receipt) => receipt.status);
  if (statuses.includes("failed")) return "failed";
  if (statuses.includes("blocked")) return "blocked";
  if (statuses.includes("partial")) return "partial";
  return "completed";
}

function managedToolResult(batch, reasonCode, receipts = []) {
  const status = reasonCode === "ok" ? aggregateStatus(receipts) : "failed";
  const isError = reasonCode !== "ok" || receipts.some((receipt) => receipt.status !== "completed");
  const text = isError
    ? `Managed agent work did not cross the completion barrier (${reasonCode}). Review the bounded receipt and continue inline or retry after correcting the boundary.`
    : "Managed agent work completed and its provisional outcome was recorded.";
  return {
    content: [{ type: "text", text }],
    details: {
      schema_version: 1,
      record_type: "agent_boundary_tool_details",
      managed: true,
      batch,
      status,
      reason_code: reasonCode,
      receipts,
    },
    isError,
  };
}

function firstReceiptFailure(results) {
  for (const result of results) if (!result.ok) return result.reason_code;
  return null;
}

export function createManagedTaskTool(pi, runtimeInput, agentCatalog, dependencies = {}) {
  const runtime = validateRuntime(runtimeInput);
  reconcileAgentCatalog(agentCatalog);
  const invokeState = dependencies.invokeState ?? ((operation, request, ctx, signal) =>
    invokeManagedState({
      pwshPath: runtime.paths.pwsh,
      stateCliPath: runtime.paths.state_cli,
      operation,
      request,
      ctx,
      signal,
    }));
  const artifactExists = dependencies.artifactExists ?? defaultArtifactExists;
  const consumePressureAbort = dependencies.consumeContextPressureAbort ?? consumeContextPressureAbort;
  const reconcileBehavior = dependencies.reconcileBehavior;

  return {
    name: "task",
    label: "Managed Agent Task",
    description: "Dispatch one closed managed Scout, Worker, or Reviewer work unit through the Topic 06 boundary.",
    loadMode: "essential",
    approval: "exec",
    strict: true,
    parameters: buildParameters(pi),
    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const validated = core.validateManagedRequest(params);
      if (!validated.ok) return managedToolResult(Boolean(params?.tasks), validated.reason_code);
      const batch = Object.hasOwn(validated.value, "tasks");
      const rawItems = batch ? validated.value.tasks : [validated.value];
      const items = rawItems.map(normalizeEffectiveRequest);

      let modeEntries = [];
      try {
        modeEntries = ctx?.sessionManager?.getBranch?.() ?? [];
      } catch {
        modeEntries = null;
      }
      const modeResult = deriveActiveMode(modeEntries);
      const capabilityFailure = runtimeCapabilityFailure(items, runtime, modeResult);
      if (capabilityFailure) return managedToolResult(batch, capabilityFailure);

      const prepared = [];
      for (const request of items) {
        let state;
        try {
          state = await invokeState("project-work-unit", {
            task_id: request.task_id,
            work_unit_id: request.work_unit_id,
          }, ctx, signal);
        } catch (error) {
          return managedToolResult(batch, signal?.aborted || error?.message === "cancelled" ? "cancelled" : "state_unavailable");
        }
        if (!isPlainObject(state) || state.ok !== true || !isPlainObject(state.data)) {
          return managedToolResult(batch, stateFailureReason(state, "project-work-unit"));
        }
        const projection = core.validateProjection(state.data);
        if (!projection.ok) return managedToolResult(batch, projection.reason_code);
        const composed = core.composeAgentPacket({ request, projection: projection.value });
        if (!composed.ok) return managedToolResult(batch, composed.reason_code);
        prepared.push({ request, projection_before: projection.value, composed });
      }

      if (typeof ctx?.invokeTool !== "function") return managedToolResult(batch, "native_task_unavailable");
      if (typeof reconcileBehavior === "function") {
        try {
          await reconcileBehavior();
        } catch (error) {
          return managedToolResult(batch, error?.reason_code ?? "BHV-HOOK-UNAVAILABLE");
        }
      }
      let native;
      try {
        native = await ctx.invokeTool(buildNativeTaskParams(prepared), { signal, onUpdate });
      } catch {
        return managedToolResult(batch, signal?.aborted ? "cancelled" : "native_task_failed");
      }
      if (!isPlainObject(native) || native.isError === true || !isPlainObject(native.details)) {
        return managedToolResult(batch, "native_task_failed");
      }

      const nativeDetails = structuredClone(native.details);
      for (const result of nativeDetails.results ?? []) {
        if (!isPlainObject(result)) continue;
        let marker = null;
        try { marker = consumePressureAbort({ agent: result.agent, task: result.task }); } catch { marker = null; }
        if (marker === CONTEXT_PRESSURE_ABORT_MARKER &&
            (result.aborted === true || result.truncated === true || result.exitCode !== 0 ||
             result.structuredOutput?.data?.status === "partial")) {
          result.topic07AbortMarker = marker;
        }
      }

      const after = [];
      for (const item of prepared) {
        let state;
        try {
          state = await invokeState("project-work-unit", {
            task_id: item.request.task_id,
            work_unit_id: item.request.work_unit_id,
          }, ctx, signal);
        } catch (error) {
          return managedToolResult(batch, signal?.aborted || error?.message === "cancelled" ? "cancelled" : "state_unavailable");
        }
        if (!isPlainObject(state) || state.ok !== true || !isPlainObject(state.data)) {
          return managedToolResult(batch, stateFailureReason(state, "project-work-unit"));
        }
        after.push(state.data);
      }

      const artifactCheck = validateNativeArtifacts(nativeDetails, items, artifactExists);
      if (!artifactCheck.ok) {
        return managedToolResult(batch, artifactCheck.reason_code, items.map((item) => failedReceipt(item.role, artifactCheck.reason_code)));
      }

      const normalized = prepared.map((item, index) => core.normalizeBoundaryReceipt({
        request: item.request,
        projection_before: item.projection_before,
        projection_after: after[index],
        index,
        expected_count: prepared.length,
        native_details: nativeDetails,
      }));
      const normalizationFailure = firstReceiptFailure(normalized);
      if (normalizationFailure) {
        const receipts = normalized.map((result, index) => result.receipt ?? failedReceipt(items[index].role, result.reason_code));
        return managedToolResult(batch, normalizationFailure, receipts);
      }

      const receipts = normalized.map((result) => result.receipt);
      let expectedRevision = after[0].cas.revision;
      let expectedRevisionSha256 = after[0].cas.revision_sha256;
      for (let index = 0; index < receipts.length; index += 1) {
        const provisional = core.toProvisionalOutcome(receipts[index]);
        if (provisional === null) {
          receipts[index] = failedReceipt(items[index].role, "outcome_record_failed");
          return managedToolResult(batch, "outcome_record_failed", receipts);
        }
        let state;
        try {
          state = await invokeState("record-work-unit-outcome", {
            task_id: items[index].task_id,
            work_unit_id: items[index].work_unit_id,
            status: provisional.status,
            artifact_refs: provisional.artifact_refs,
            observed_summary: provisional.observed_summary,
            expected_revision: expectedRevision,
            expected_revision_sha256: expectedRevisionSha256,
            expected_lease_generation: after[index].cas.lease_generation,
          }, ctx, signal);
        } catch {
          receipts[index] = failedReceipt(items[index].role, signal?.aborted ? "cancelled" : "outcome_record_failed");
          return managedToolResult(batch, receipts[index].reason_code, receipts);
        }
        if (!isPlainObject(state) || state.ok !== true || !isPlainObject(state.data) ||
            !Number.isSafeInteger(state.data.revision) || state.data.revision < 1 ||
            typeof state.data.revision_sha256 !== "string" || !SHA256_PATTERN.test(state.data.revision_sha256)) {
          receipts[index] = failedReceipt(items[index].role, stateFailureReason(state, "record-work-unit-outcome"));
          if (receipts[index].reason_code === "state_unavailable") receipts[index].reason_code = "outcome_record_failed";
          return managedToolResult(batch, receipts[index].reason_code, receipts);
        }
        receipts[index].outcome.recorded = true;
        expectedRevision = state.data.revision;
        expectedRevisionSha256 = state.data.revision_sha256;
      }

      return managedToolResult(batch, "ok", receipts);
    },
  };
}

export default async function agentTaskBoundaryFactory(pi) {
  const runtime = await loadManagedRuntime(import.meta.url);
  if (!pi?.pi || typeof pi.pi.discoverAgents !== "function" || typeof pi.registerTool !== "function" ||
      typeof pi.pi.discoverSkills !== "function" || typeof pi.on !== "function" ||
      !runtime.supported_omp_versions.includes(String(pi.pi.VERSION))) {
    throwUnavailable();
  }
  const manifest = loadBehaviorManifest(import.meta.url);
  const discovery = await reconcileEffectiveBehavior({ pi, runtime, manifest });
  pi.registerTool(createAgentTasksTool(pi, runtime));
  pi.registerTool(createManagedTaskTool(pi, runtime, discovery.agentCatalog, {
    reconcileBehavior: () => reconcileEffectiveBehavior({ pi, runtime, manifest }),
  }));
  pi.on("tool_call", createBehaviorToolCallHandler({ pi, runtime, manifest }));
}
