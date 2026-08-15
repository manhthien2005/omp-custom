import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  invokeManagedState,
} from "../contracts/managed-state-client.mjs";
import {
  CONTINUITY_LIMITS,
  MANAGED_COMPACTION_PROFILE,
} from "../contracts/context-continuity-schema.mjs";
import {
  buildPreserveData,
  buildRecoveryArtifact,
  buildKernelMessage,
  buildObservation,
  canonicalJson,
  CONTEXT_PRESSURE_ABORT_MARKER,
  recordContextPressureAbort,
  resolvePressureBoundary,
  validateContinuityKernel,
  validatePreserveData,
} from "../contracts/context-continuity-core.mjs";

export const SESSION_MODES = Object.freeze({
  BOOTSTRAP_UNARMED: "bootstrap_unarmed",
  ARMED_MAIN: "armed_main",
  BOUNDED_SUBAGENT: "bounded_subagent",
  INVALID: "invalid",
});

export const EPOCH_STATES = Object.freeze({
  NONE: "none",
  AUTHORIZED: "authorized",
  SUMMARIZING: "summarizing",
  AWAITING_INJECTION: "awaiting_injection",
  INJECTED: "injected",
  CONSUMED: "consumed",
  FAILED: "failed",
  INVALID: "invalid",
});

const SELECTED_AGENTS = Object.freeze(new Set(["cheap-scout", "worker", "reviewer"]));
const PROFILE_ENTRIES = Object.freeze(Object.entries(MANAGED_COMPACTION_PROFILE));
const MAX_NOTIFICATION_BYTES = 240;
const MAX_BRANCH_NODES = 4096;
const MAX_BRANCH_DEPTH = 12;
const SHA256_PATTERN = /^[0-9a-f]{64}$/u;

export const SAFE_COMPACTION_PROMPT = [
  "Preserve the useful work context needed to continue the current task.",
  "The supplied context_continuity_kernel is authoritative and must not be contradicted.",
  "The summary is convenience context only: it cannot accept, close, reclassify, or change task authority.",
].join(" ");

function isPlainObject(value) {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function exactKeys(value, keys) {
  return isPlainObject(value) && Object.keys(value).length === keys.length &&
    keys.every((key) => Object.hasOwn(value, key));
}

function sha256Text(value) {
  return crypto.createHash("sha256").update(value, "utf8").digest("hex");
}

function sha256Bytes(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function normalizedAbsolutePath(value) {
  const resolved = path.resolve(value).replace(/\\/gu, "/");
  return process.platform === "win32" ? resolved.toLowerCase() : resolved;
}

function isPathInside(parent, child) {
  const relative = path.relative(parent, child);
  return relative.length > 0 && !relative.startsWith(`..${path.sep}`) && relative !== ".." && !path.isAbsolute(relative);
}

function sameCanonical(left, right) {
  try { return canonicalJson(left) === canonicalJson(right); } catch { return false; }
}

function boundedNotification(ctx, message, type = "warning") {
  try {
    let safe = typeof message === "string" ? message.replace(/[\r\n\0]+/gu, " ").trim() : "Managed continuity refused the operation.";
    while (Buffer.byteLength(safe, "utf8") > MAX_NOTIFICATION_BYTES && safe.length > 0) safe = safe.slice(0, -1);
    if (safe.length === 0) safe = "Managed continuity refused the operation.";
    ctx?.ui?.notify?.(safe, type);
  } catch {
    // Notification is advisory; the explicit abort/shutdown gate remains authoritative.
  }
}

function defaultSetProcessExitCode(code) {
  if (process.exitCode === undefined || process.exitCode === 0) process.exitCode = code;
}

function readDefaultRuntime(moduleUrl = import.meta.url) {
  try {
    const modulePath = fileURLToPath(moduleUrl);
    const targetOmp = path.resolve(path.dirname(modulePath), "..");
    const runtimePath = path.join(targetOmp, "contracts", "runtime.json");
    const runtime = JSON.parse(fs.readFileSync(runtimePath, "utf8"));
    if (!isPlainObject(runtime) || runtime.schema_version !== 2 || runtime.component !== "agent-boundary" ||
        runtime.component_version !== "2.1.0" || path.resolve(runtime.target_omp) !== targetOmp ||
        runtime.capabilities?.continuity !== true || !isPlainObject(runtime.paths) ||
        typeof runtime.paths.pwsh !== "string" || !path.isAbsolute(runtime.paths.pwsh) ||
        typeof runtime.paths.state_cli !== "string" || !path.isAbsolute(runtime.paths.state_cli) ||
        typeof runtime.paths.continuity_adapter !== "string" ||
        path.resolve(runtime.paths.continuity_adapter) !== path.resolve(modulePath)) {
      throw new Error("runtime_unavailable");
    }
    return runtime;
  } catch {
    throw new Error("runtime_unavailable");
  }
}

function validSessionInit(entry) {
  if (!isPlainObject(entry) || entry.type !== "session_init" || !SELECTED_AGENTS.has(entry.agent) ||
      typeof entry.systemPrompt !== "string" || entry.systemPrompt.trim().length === 0 ||
      typeof entry.task !== "string" || entry.task.trim().length === 0 ||
      !Array.isArray(entry.tools) || entry.tools.length === 0 || entry.tools.length > 128) return false;
  const seen = new Set();
  return entry.tools.every((tool) => typeof tool === "string" && tool.length > 0 && !seen.has(tool) && seen.add(tool));
}

function branchContainsShakePlaceholder(branch) {
  const seen = new WeakSet();
  let nodes = 0;
  function visit(value, depth) {
    nodes += 1;
    if (nodes > MAX_BRANCH_NODES || depth > MAX_BRANCH_DEPTH) throw new Error("branch_invalid");
    if (typeof value === "string") return value.startsWith("[shaken ~");
    if (value === null || typeof value !== "object") return false;
    if (seen.has(value)) throw new Error("branch_invalid");
    seen.add(value);
    if (Array.isArray(value)) return value.some((item) => visit(item, depth + 1));
    return Object.values(value).some((item) => visit(item, depth + 1));
  }
  return visit(branch, 0);
}

function inspectSession(ctx) {
  try {
    const sessionId = ctx?.sessionManager?.getSessionId?.();
    const branch = ctx?.sessionManager?.getBranch?.();
    if (typeof sessionId !== "string" || sessionId.trim().length === 0 || !Array.isArray(branch)) {
      return { ok: false, reason_code: "session_identity_invalid" };
    }
    if (branchContainsShakePlaceholder(branch)) return { ok: false, reason_code: "native_shake_detected", sessionId };
    const sessionInitEntries = branch.filter((entry) => isPlainObject(entry) && entry.type === "session_init");
    if (sessionInitEntries.length === 0) {
      return { ok: true, mode: SESSION_MODES.BOOTSTRAP_UNARMED, sessionId };
    }
    if (sessionInitEntries.length !== 1 || !validSessionInit(sessionInitEntries[0])) {
      return { ok: false, reason_code: "session_identity_invalid", sessionId };
    }
    return {
      ok: true,
      mode: SESSION_MODES.BOUNDED_SUBAGENT,
      sessionId,
      agent: sessionInitEntries[0].agent,
      task: sessionInitEntries[0].task,
    };
  } catch {
    return { ok: false, reason_code: "session_identity_invalid" };
  }
}

function captureBranchIdentity(branch) {
  if (!Array.isArray(branch) || branch.length === 0 || branch.length > CONTINUITY_LIMITS.maxBranchEntries) {
    throw new Error("branch_invalid");
  }
  const seen = new Set();
  const branchEntryIds = branch.map((entry) => {
    if (!isPlainObject(entry) || typeof entry.id !== "string" || entry.id.length === 0 ||
        Buffer.byteLength(entry.id, "utf8") > 256 || seen.has(entry.id)) throw new Error("branch_invalid");
    seen.add(entry.id);
    return entry.id;
  });
  return {
    branchEntryIds,
    leafEntryId: branchEntryIds.at(-1),
    branchSha256: sha256Text(canonicalJson(branchEntryIds)),
  };
}

function capturePersistedSession(ctx) {
  const sessionId = ctx?.sessionManager?.getSessionId?.();
  const sessionFile = ctx?.sessionManager?.getSessionFile?.();
  const artifactsDir = ctx?.sessionManager?.getArtifactsDir?.();
  if (typeof sessionId !== "string" || sessionId.trim().length === 0 ||
      typeof sessionFile !== "string" || !path.isAbsolute(sessionFile) ||
      typeof artifactsDir !== "string" || !path.isAbsolute(artifactsDir)) {
    throw new Error("persistence_unavailable");
  }
  const sessionStat = fs.statSync(sessionFile);
  const artifactStat = fs.statSync(artifactsDir);
  if (!sessionStat.isFile() || !artifactStat.isDirectory()) throw new Error("persistence_unavailable");
  const branch = ctx?.sessionManager?.getBranch?.();
  const branchIdentity = captureBranchIdentity(branch);
  return {
    sessionId,
    sessionIdSha256: sha256Text(sessionId),
    sessionFile,
    sessionFileSha256: sha256Text(normalizedAbsolutePath(sessionFile)),
    artifactsDir,
    ...branchIdentity,
  };
}

function validAsyncSnapshot(value) {
  return isPlainObject(value) && ["running", "queued", "delivering"].every((key) => Array.isArray(value[key]));
}

function sameKernelBinding(epoch, kernel) {
  return kernel.task.task_id === epoch.taskId &&
    kernel.lifecycle.owner_session_ref === epoch.sessionId &&
    kernel.lifecycle.owner_runtime === "omp" &&
    kernel.lifecycle.revision_id === epoch.revisionId &&
    kernel.lifecycle.revision_sha256 === epoch.taskRevisionSha256 &&
    kernel.lifecycle.lease_generation === epoch.leaseGeneration &&
    kernel.kernel_sha256 === epoch.kernelSha256;
}

function validNativePreparation(event, epoch) {
  const value = event?.preparation;
  if (!isPlainObject(value) || !Array.isArray(value.messagesToSummarize) || value.messagesToSummarize.length === 0 ||
      typeof value.firstKeptEntryId !== "string" || !epoch.branchEntryIds.includes(value.firstKeptEntryId) ||
      !Number.isSafeInteger(value.tokensBefore) || value.tokensBefore <= 0 || !isPlainObject(value.settings) ||
      value.settings.strategy !== "context-full" || value.settings.remoteEnabled !== false ||
      value.settings.keepRecentTokens !== 20_000 || event.customInstructions !== undefined) return false;
  try {
    const eventBranch = captureBranchIdentity(event.branchEntries);
    return eventBranch.branchSha256 === epoch.branchSha256 && eventBranch.leafEntryId === epoch.leafEntryId;
  } catch {
    return false;
  }
}

function readPersistedEpoch(branch, sessionId) {
  if (!Array.isArray(branch)) return { kind: "invalid" };
  const records = branch.filter((entry) => isPlainObject(entry) && entry.type === "custom" &&
    entry.customType === "topic07:epoch-state");
  if (records.length === 0) return { kind: "none" };
  const data = records.at(-1).data;
  const keys = [
    "schema_version", "epoch_id", "task_id", "task_revision_sha256", "kernel_sha256",
    "branch_sha256", "recovery_artifact_id", "recovery_artifact_sha256", "status",
  ];
  if (!exactKeys(data, keys) || data.schema_version !== 1 ||
      typeof data.epoch_id !== "string" || !/^E-[A-Z0-9][A-Z0-9._-]{0,79}$/u.test(data.epoch_id) ||
      typeof data.task_id !== "string" || !/^T[0-9]{6}$/u.test(data.task_id) ||
      !SHA256_PATTERN.test(data.task_revision_sha256) || !SHA256_PATTERN.test(data.kernel_sha256) ||
      !SHA256_PATTERN.test(data.branch_sha256) || !SHA256_PATTERN.test(data.recovery_artifact_sha256) ||
      typeof data.recovery_artifact_id !== "string" || data.recovery_artifact_id.length === 0 ||
      Buffer.byteLength(data.recovery_artifact_id, "utf8") > 512 ||
      ![EPOCH_STATES.AWAITING_INJECTION, EPOCH_STATES.CONSUMED].includes(data.status)) {
    return { kind: "invalid" };
  }
  if (data.status === EPOCH_STATES.CONSUMED) return { kind: "consumed" };
  return {
    kind: "awaiting",
    epoch: {
      epochId: data.epoch_id,
      rawNonce: null,
      nonceSha256: null,
      sessionId,
      taskId: data.task_id,
      taskRevisionSha256: data.task_revision_sha256,
      kernelSha256: data.kernel_sha256,
      branchSha256: data.branch_sha256,
      recoveryArtifactId: data.recovery_artifact_id,
      recoveryArtifactSha256: data.recovery_artifact_sha256,
      kernel: null,
      kernelCanonical: null,
      status: EPOCH_STATES.AWAITING_INJECTION,
      reasonCode: null,
    },
  };
}

function epochStateEntry(epoch, status) {
  return {
    schema_version: 1,
    epoch_id: epoch.epochId,
    task_id: epoch.taskId,
    task_revision_sha256: epoch.taskRevisionSha256,
    kernel_sha256: epoch.kernelSha256,
    branch_sha256: epoch.branchSha256,
    recovery_artifact_id: epoch.recoveryArtifactId,
    recovery_artifact_sha256: epoch.recoveryArtifactSha256,
    status,
  };
}

function initialState() {
  return {
    mode: SESSION_MODES.INVALID,
    epochState: EPOCH_STATES.NONE,
    sessionId: null,
    boundedAgent: null,
    armedTaskId: null,
    armedKernelHash: null,
    invalidReason: "not_initialized",
    settingsDriftPaths: [],
    settingsFatal: false,
    exitCodeSet: false,
    notifiedReasons: new Set(),
    epoch: null,
    nativeInvocationActive: false,
    boundedTask: null,
    requestGeneration: 0,
    requestAborted: false,
    injectionGeneration: null,
    injectionKernelHash: null,
  };
}

function snapshotState(state) {
  return {
    mode: state.mode,
    epoch_state: state.epochState,
    armed_task_id: state.armedTaskId,
    armed_kernel_sha256: state.armedKernelHash,
    bounded_agent: state.boundedAgent,
    invalid_reason: state.invalidReason,
    settings_drift_paths: [...state.settingsDriftPaths],
    epoch_id: state.epoch?.epochId ?? null,
  };
}

export function createContextContinuityAdapter(dependencies = {}) {
  const setProcessExitCode = dependencies.setProcessExitCode ?? defaultSetProcessExitCode;
  const onStateChange = typeof dependencies.onStateChange === "function" ? dependencies.onStateChange : () => {};
  const now = typeof dependencies.now === "function" ? dependencies.now : () => Date.now();
  const randomBytes = typeof dependencies.randomBytes === "function" ? dependencies.randomBytes : crypto.randomBytes;
  const randomUUID = typeof dependencies.randomUUID === "function" ? dependencies.randomUUID : crypto.randomUUID;
  let runtimePromise;
  const resolveRuntime = async () => {
    if (dependencies.runtime) return dependencies.runtime;
    if (!runtimePromise) runtimePromise = Promise.resolve().then(() => readDefaultRuntime());
    return runtimePromise;
  };
  const invokeState = dependencies.invokeState ?? (async ({ operation, request, ctx, signal }) => {
    const runtime = await resolveRuntime();
    return invokeManagedState({
      pwshPath: runtime.paths.pwsh,
      stateCliPath: runtime.paths.state_cli,
      operation,
      request,
      ctx,
      signal,
      acceptNonzeroFailureEnvelope: true,
    });
  });

  return async function contextContinuityFactory(api) {
    if (!api || typeof api.on !== "function" || typeof api.registerCommand !== "function") {
      throw new Error("continuity_api_unavailable");
    }
    const settings = api?.pi?.settings;
    const settingsSurfaceAvailable = typeof settings?.get === "function" && typeof settings?.override === "function";
    const state = initialState();

    const publishState = () => {
      try { onStateChange(snapshotState(state)); } catch { /* Test/observation callback cannot weaken gates. */ }
    };
    const notifyOnce = (ctx, reason, message, type = "warning") => {
      if (state.notifiedReasons.has(reason)) return;
      state.notifiedReasons.add(reason);
      boundedNotification(ctx, message, type);
    };
    const setExitFailure = () => {
      if (state.exitCodeSet) return;
      state.exitCodeSet = true;
      try { setProcessExitCode(1); } catch { /* Shutdown remains authoritative. */ }
    };
    const abortSafely = (ctx) => {
      try { ctx?.abort?.(); } catch { /* Handler exceptions are contained by OMP. */ }
    };
    const shutdownSafely = (ctx) => {
      try { ctx?.shutdown?.(); } catch { /* Exit code is the second startup guard. */ }
    };
    const invalidate = (ctx, reasonCode, { abort = true, shutdown = false, message } = {}) => {
      state.mode = SESSION_MODES.INVALID;
      state.armedTaskId = null;
      state.armedKernelHash = null;
      state.invalidReason = reasonCode;
      if (state.epoch) {
        state.epoch.rawNonce = null;
        state.epochState = EPOCH_STATES.INVALID;
      }
      state.nativeInvocationActive = false;
      setExitFailure();
      if (abort) abortSafely(ctx);
      if (shutdown) shutdownSafely(ctx);
      notifyOnce(ctx, reasonCode, message ?? "Managed continuity is unavailable; provider work was stopped.", "error");
      publishState();
    };

    const reassertSettings = (ctx, boundary) => {
      if (state.settingsFatal) {
        if (boundary !== "session_start" && boundary !== "session_switch") abortSafely(ctx);
        return false;
      }
      if (!settingsSurfaceAvailable) {
        state.settingsFatal = true;
        state.settingsDriftPaths = [];
        invalidate(ctx, "settings_surface_unavailable", {
          abort: boundary !== "session_start" && boundary !== "session_switch",
          shutdown: true,
          message: "Managed continuity settings are unavailable; startup was stopped.",
        });
        return false;
      }
      const drift = [];
      try {
        for (const [settingPath, expected] of PROFILE_ENTRIES) {
          if (!Object.is(settings.get(settingPath), expected)) {
            drift.push(settingPath);
            settings.override(settingPath, expected);
          }
        }
        for (const [settingPath, expected] of PROFILE_ENTRIES) {
          if (!Object.is(settings.get(settingPath), expected)) throw new Error("settings_reassertion_failed");
        }
      } catch {
        state.settingsFatal = true;
        state.settingsDriftPaths = [...drift].sort();
        invalidate(ctx, "settings_reassertion_failed", {
          abort: boundary !== "session_start" && boundary !== "session_switch",
          shutdown: true,
          message: "Managed continuity settings could not be enforced; startup was stopped.",
        });
        return false;
      }
      state.settingsDriftPaths = [...drift].sort();
      if (drift.length > 0) {
        boundedNotification(ctx, `Managed continuity restored ${drift.length} runtime-only setting${drift.length === 1 ? "" : "s"}.`, "warning");
      }
      return true;
    };

    const initializeSession = (ctx, boundary) => {
      state.epochState = EPOCH_STATES.NONE;
      if (state.epoch) state.epoch.rawNonce = null;
      state.epoch = null;
      state.nativeInvocationActive = false;
      state.boundedTask = null;
      state.requestGeneration = 0;
      state.requestAborted = false;
      state.injectionGeneration = null;
      state.injectionKernelHash = null;
      state.armedTaskId = null;
      state.armedKernelHash = null;
      state.boundedAgent = null;
      state.invalidReason = null;
      state.notifiedReasons = new Set();
      if (!reassertSettings(ctx, boundary)) return false;
      const inspection = inspectSession(ctx);
      if (!inspection.ok) {
        invalidate(ctx, inspection.reason_code, {
          abort: false,
          shutdown: inspection.reason_code === "session_identity_invalid",
          message: inspection.reason_code === "native_shake_detected"
            ? "An unsupported native shake was detected; managed provider work is blocked."
            : "The managed session identity is invalid; startup was stopped.",
        });
        return false;
      }
      state.mode = inspection.mode;
      state.sessionId = inspection.sessionId;
      state.boundedAgent = inspection.agent ?? null;
      state.boundedTask = inspection.task ?? null;
      state.invalidReason = null;
      if (inspection.mode !== SESSION_MODES.BOUNDED_SUBAGENT) {
        const persisted = readPersistedEpoch(ctx?.sessionManager?.getBranch?.(), inspection.sessionId);
        if (persisted.kind === "invalid") {
          invalidate(ctx, "persisted_epoch_invalid", {
            abort: false,
            shutdown: true,
            message: "Persisted managed continuity state is invalid; startup was stopped.",
          });
          return false;
        }
        if (persisted.kind === "awaiting") {
          state.epoch = persisted.epoch;
          state.epochState = EPOCH_STATES.AWAITING_INJECTION;
        } else if (persisted.kind === "consumed") {
          state.epochState = EPOCH_STATES.CONSUMED;
        }
      }
      publishState();
      return true;
    };

    const guardSessionAndSettings = (ctx, boundary) => {
      if (!reassertSettings(ctx, boundary)) return false;
      const inspection = inspectSession(ctx);
      if (!inspection.ok) {
        invalidate(ctx, inspection.reason_code, {
          abort: true,
          shutdown: false,
          message: inspection.reason_code === "native_shake_detected"
            ? "An unsupported native shake was detected; managed provider work is blocked."
            : "The managed session identity changed unexpectedly; provider work was stopped.",
        });
        return false;
      }
      if (state.sessionId !== inspection.sessionId) return initializeSession(ctx, boundary);
      if (state.mode === SESSION_MODES.BOUNDED_SUBAGENT && inspection.mode !== SESSION_MODES.BOUNDED_SUBAGENT ||
          state.mode !== SESSION_MODES.BOUNDED_SUBAGENT && inspection.mode === SESSION_MODES.BOUNDED_SUBAGENT) {
        invalidate(ctx, "session_identity_changed", {
          abort: true,
          message: "The managed session role changed unexpectedly; provider work was stopped.",
        });
        return false;
      }
      return state.mode !== SESSION_MODES.INVALID;
    };

    const readProjection = async (ctx) => {
      let envelope;
      try {
        envelope = await invokeState({ operation: "project-continuity", request: {}, ctx });
      } catch {
        return { kind: "invalid", reason_code: "state_unavailable" };
      }
      if (!exactKeys(envelope, ["code", "data", "ok", "operation"]) || envelope.operation !== "project-continuity" ||
          typeof envelope.code !== "string" || typeof envelope.ok !== "boolean" || !isPlainObject(envelope.data)) {
        return { kind: "invalid", reason_code: "state_unavailable" };
      }
      if (envelope.ok === false) {
        if (envelope.code === "AT-CONTINUITY-TASK-NOT-FOUND") return { kind: "none" };
        if (envelope.code === "AT-CONTINUITY-TASK-AMBIGUOUS") return { kind: "ambiguous" };
        return { kind: "invalid", reason_code: "state_invalid" };
      }
      if (envelope.code !== "AT-OK") return { kind: "invalid", reason_code: "state_invalid" };
      const validated = validateContinuityKernel(envelope.data);
      if (!validated.ok || validated.value.lifecycle.owner_session_ref !== state.sessionId ||
          validated.value.lifecycle.owner_runtime !== "omp") {
        return { kind: "invalid", reason_code: "projection_invalid" };
      }
      return { kind: "one", kernel: validated.value };
    };

    const refuseCommand = (ctx, reasonCode = "safe_compact_refused") => {
      notifyOnce(ctx, reasonCode, "Managed safe compaction was refused because its preflight was not satisfied.", "warning");
    };

    const setEpochState = (epochState, reasonCode = null) => {
      state.epochState = epochState;
      if (state.epoch) {
        state.epoch.status = epochState;
        state.epoch.reasonCode = reasonCode;
        if ([EPOCH_STATES.FAILED, EPOCH_STATES.INVALID, EPOCH_STATES.CONSUMED].includes(epochState)) {
          state.epoch.rawNonce = null;
        }
      }
      publishState();
    };

    const failEpoch = (ctx, reasonCode, epochState = EPOCH_STATES.FAILED) => {
      if (!state.epoch || [EPOCH_STATES.FAILED, EPOCH_STATES.INVALID].includes(state.epochState)) return;
      state.nativeInvocationActive = false;
      setEpochState(epochState, reasonCode);
      notifyOnce(ctx, `epoch:${reasonCode}`, "Managed safe compaction failed without retry; the prior branch remains authoritative.", "error");
    };

    const appendObservation = (ctx, {
      usage,
      boundary,
      reasonCode,
      providerAction,
    }) => {
      if (typeof api.appendEntry !== "function" || !usage) return;
      try {
        const pressure = resolvePressureBoundary(usage);
        const epoch = state.epoch;
        const kernelCanonical = epoch?.kernelCanonical;
        const compactionStatus = state.epochState === EPOCH_STATES.SUMMARIZING ? "summarizing" :
          [EPOCH_STATES.AWAITING_INJECTION, EPOCH_STATES.INJECTED, EPOCH_STATES.CONSUMED].includes(state.epochState)
            ? "completed" : [EPOCH_STATES.FAILED, EPOCH_STATES.INVALID].includes(state.epochState) ? "failed" : "not_started";
        const injectionStatus = state.epochState === EPOCH_STATES.AWAITING_INJECTION ? "awaiting" :
          state.epochState === EPOCH_STATES.INJECTED ? "injected" : state.epochState === EPOCH_STATES.CONSUMED ? "consumed" :
            [EPOCH_STATES.FAILED, EPOCH_STATES.INVALID].includes(state.epochState) ? "failed" : "not_pending";
        const observation = buildObservation({
          component_version: "2.1.0",
          runtime_version: String(api?.pi?.VERSION ?? "unverified-runtime"),
          session_sha256: sha256Text(state.sessionId ?? "unavailable"),
          task_sha256: sha256Text(epoch?.taskId ?? state.armedTaskId ?? state.boundedTask ?? "unavailable"),
          epoch_sha256: sha256Text(epoch?.epochId ?? "none"),
          workflow_class: epoch?.kernel?.task?.workflow_class ?? "standard",
          context_tokens: usage.tokens,
          context_window: usage.contextWindow,
          threshold_tokens: pressure.thresholdTokens,
          kernel_bytes: typeof kernelCanonical === "string" ? Buffer.byteLength(kernelCanonical, "utf8") : 0,
          kernel_sha256: epoch?.kernelSha256 ?? sha256Text("none"),
          artifact_status: epoch?.recoveryArtifactId ? "saved" : "not_attempted",
          preparation_status: state.epochState === EPOCH_STATES.SUMMARIZING ? "ready" : "not_attempted",
          compaction_status: compactionStatus,
          validation_status: epoch?.kernelSha256 ? "passed" : "not_run",
          reason_code: `${boundary}:${reasonCode}`,
          degraded_fields: epoch?.kernel?.degraded_fields ?? [],
          settings_drift: state.settingsDriftPaths,
          injection_status: injectionStatus,
          provider_action: providerAction,
        });
        api.appendEntry("topic07:observation", observation);
      } catch {
        // Observation failure never authorizes provider work or weakens a stop decision.
      }
    };

    const pressureGuard = (ctx, boundary) => {
      if (state.epochState === EPOCH_STATES.SUMMARIZING && state.nativeInvocationActive) return true;
      let usage;
      try { usage = ctx?.getContextUsage?.(); } catch { usage = undefined; }
      const validUsage = isPlainObject(usage) && Number.isSafeInteger(usage.tokens) && usage.tokens >= 0 &&
        Number.isSafeInteger(usage.contextWindow) && usage.contextWindow >= 2;
      if (!validUsage) {
        if (boundary !== "before_provider_request" ||
            ![SESSION_MODES.ARMED_MAIN, SESSION_MODES.BOUNDED_SUBAGENT].includes(state.mode) &&
            ![EPOCH_STATES.AWAITING_INJECTION, EPOCH_STATES.INJECTED].includes(state.epochState)) return true;
      } else {
        let pressure;
        try { pressure = resolvePressureBoundary(usage); } catch { pressure = null; }
        if (pressure && !pressure.atOrAbove) return true;
      }

      if (!state.requestAborted) {
        state.requestAborted = true;
        abortSafely(ctx);
        if (state.mode === SESSION_MODES.BOUNDED_SUBAGENT && state.boundedAgent && state.boundedTask) {
          recordContextPressureAbort({ agent: state.boundedAgent, task: state.boundedTask, nowMs: now() });
          try {
            api.appendEntry?.("topic07:context-pressure-abort", {
              schema_version: 1,
              marker: CONTEXT_PRESSURE_ABORT_MARKER,
              session_sha256: sha256Text(state.sessionId),
              task_sha256: sha256Text(state.boundedTask),
              generation: state.requestGeneration,
            });
          } catch { /* The in-process marker still prevents a plausible successful receipt. */ }
        }
      }
      notifyOnce(ctx, `pressure:${state.requestGeneration}`, state.mode === SESSION_MODES.BOUNDED_SUBAGENT
        ? "The bounded child stopped at the managed context-pressure boundary."
        : "Context is at the managed limit; run /safe-compact or make an explicit handoff before continuing.", "warning");
      if (validUsage) appendObservation(ctx, {
        usage,
        boundary,
        reasonCode: "context_pressure",
        providerAction: "aborted",
      });
      publishState();
      return false;
    };

    const currentProjectionMatchesEpoch = async (ctx, epoch) => {
      const projection = await readProjection(ctx);
      return projection.kind === "one" && sameKernelBinding(epoch, projection.kernel)
        ? projection.kernel
        : null;
    };

    const refreshPendingEpoch = async (ctx, epoch) => {
      const projection = await readProjection(ctx);
      if (projection.kind !== "one" || projection.kernel.task.task_id !== epoch.taskId ||
          projection.kernel.lifecycle.revision_sha256 !== epoch.taskRevisionSha256 ||
          projection.kernel.kernel_sha256 !== epoch.kernelSha256) return null;
      epoch.kernel = projection.kernel;
      epoch.kernelCanonical = canonicalJson(projection.kernel);
      epoch.revisionId = projection.kernel.lifecycle.revision_id;
      epoch.leaseGeneration = projection.kernel.lifecycle.lease_generation;
      if (state.mode === SESSION_MODES.BOOTSTRAP_UNARMED) {
        state.mode = SESSION_MODES.ARMED_MAIN;
        state.armedTaskId = projection.kernel.task.task_id;
        state.armedKernelHash = projection.kernel.kernel_sha256;
      }
      return projection.kernel;
    };

    const verifyAndSaveRecoveryArtifact = async (ctx, session, kernel, epochId, createdAtMs, expiresAtMs) => {
      const recovery = buildRecoveryArtifact({
        epoch_id: epochId,
        created_at_utc: new Date(createdAtMs).toISOString(),
        expires_at_utc: new Date(expiresAtMs).toISOString(),
        session_id_sha256: session.sessionIdSha256,
        session_file_sha256: session.sessionFileSha256,
        task_id: kernel.task.task_id,
        task_revision_sha256: kernel.lifecycle.revision_sha256,
        lease_generation: kernel.lifecycle.lease_generation,
        branch_sha256: session.branchSha256,
        leaf_entry_id: session.leafEntryId,
        branch_entry_ids: session.branchEntryIds,
        kernel,
      });
      const bytes = `${recovery.canonical}\n`;
      const artifactId = await ctx.sessionManager.saveArtifact(bytes, "context-continuity-recovery");
      if (typeof artifactId !== "string" || artifactId.trim().length === 0 || Buffer.byteLength(artifactId, "utf8") > 512) {
        throw new Error("artifact_invalid");
      }
      const artifactPath = await ctx.sessionManager.getArtifactPath(artifactId);
      if (typeof artifactPath !== "string" || !path.isAbsolute(artifactPath)) throw new Error("artifact_invalid");
      const realArtifactDirectory = fs.realpathSync(session.artifactsDir);
      const realArtifactPath = fs.realpathSync(artifactPath);
      if (!isPathInside(realArtifactDirectory, realArtifactPath) || !fs.statSync(realArtifactPath).isFile()) {
        throw new Error("artifact_invalid");
      }
      const savedBytes = fs.readFileSync(realArtifactPath, "utf8");
      if (savedBytes !== bytes || sha256Text(savedBytes.slice(0, -1)) !== sha256Text(recovery.canonical)) {
        throw new Error("artifact_invalid");
      }
      return { artifactId, artifactSha256: recovery.sha256, recovery };
    };

    api.registerCommand("safe-compact", {
      description: "Run one explicit managed continuity compaction.",
      handler: async (args, ctx) => {
        if (typeof args !== "string" || args.trim().length > 0) {
          boundedNotification(ctx, "/safe-compact does not accept arguments in managed v1.", "warning");
          return;
        }
        if (!guardSessionAndSettings(ctx, "safe_compact") || state.mode !== SESSION_MODES.ARMED_MAIN ||
            ![EPOCH_STATES.NONE, EPOCH_STATES.CONSUMED].includes(state.epochState)) {
          refuseCommand(ctx, "safe_compact_mode_refused");
          return;
        }
        let session;
        try {
          if (ctx?.isIdle?.() !== true || ctx?.hasPendingMessages?.() !== false) throw new Error("runtime_busy");
          const jobs = ctx?.getAsyncJobSnapshot?.();
          if (!validAsyncSnapshot(jobs) || jobs.running.length > 0 || jobs.queued.length > 0 || jobs.delivering.length > 0) {
            throw new Error("runtime_busy");
          }
          session = capturePersistedSession(ctx);
        } catch {
          refuseCommand(ctx, "safe_compact_persistence_or_idle_refused");
          return;
        }
        const projection = await readProjection(ctx);
        if (projection.kind !== "one" || projection.kernel.task.task_id !== state.armedTaskId) {
          refuseCommand(ctx, "safe_compact_task_refused");
          return;
        }
        const createdAtMs = now();
        if (!Number.isSafeInteger(createdAtMs) || createdAtMs < 0) {
          refuseCommand(ctx, "safe_compact_clock_refused");
          return;
        }
        const expiresAtMs = createdAtMs + CONTINUITY_LIMITS.nonceTtlMs;
        let rawNonce;
        let epochId;
        let recovery;
        try {
          rawNonce = randomBytes(32);
          if (!Buffer.isBuffer(rawNonce) || rawNonce.length !== 32) throw new Error("nonce_invalid");
          const uuid = randomUUID();
          if (typeof uuid !== "string" || uuid.length === 0) throw new Error("epoch_invalid");
          epochId = `E-${uuid.toUpperCase()}`;
          recovery = await verifyAndSaveRecoveryArtifact(
            ctx, session, projection.kernel, epochId, createdAtMs, expiresAtMs,
          );
        } catch {
          if (Buffer.isBuffer(rawNonce)) rawNonce.fill(0);
          refuseCommand(ctx, "safe_compact_artifact_refused");
          return;
        }
        const nonceSha256 = sha256Bytes(rawNonce);
        const preserveData = buildPreserveData({
          epoch_id: epochId,
          nonce_sha256: nonceSha256,
          task_id: projection.kernel.task.task_id,
          task_revision_sha256: projection.kernel.lifecycle.revision_sha256,
          kernel_sha256: projection.kernel.kernel_sha256,
          branch_sha256: session.branchSha256,
          recovery_artifact_id: recovery.artifactId,
        });
        state.epoch = {
          epochId,
          rawNonce,
          nonceSha256,
          createdAtMs,
          expiresAtMs,
          sessionId: session.sessionId,
          sessionFileSha256: session.sessionFileSha256,
          branchEntryIds: session.branchEntryIds,
          leafEntryId: session.leafEntryId,
          branchSha256: session.branchSha256,
          taskId: projection.kernel.task.task_id,
          revisionId: projection.kernel.lifecycle.revision_id,
          taskRevisionSha256: projection.kernel.lifecycle.revision_sha256,
          leaseGeneration: projection.kernel.lifecycle.lease_generation,
          kernel: projection.kernel,
          kernelCanonical: canonicalJson(projection.kernel),
          kernelSha256: projection.kernel.kernel_sha256,
          recoveryArtifactId: recovery.artifactId,
          recoveryArtifactSha256: recovery.artifactSha256,
          preserveData,
          status: EPOCH_STATES.AUTHORIZED,
          reasonCode: null,
        };
        state.nativeInvocationActive = true;
        setEpochState(EPOCH_STATES.AUTHORIZED);
        const onError = () => failEpoch(ctx, "native_compaction_failed", EPOCH_STATES.FAILED);
        const onComplete = () => {
          if (state.epochState === EPOCH_STATES.SUMMARIZING || state.epochState === EPOCH_STATES.AUTHORIZED) {
            failEpoch(ctx, "native_settlement_missing", EPOCH_STATES.INVALID);
          }
        };
        try {
          await ctx.compact({ mode: "soft", onComplete, onError });
          onComplete();
        } catch {
          failEpoch(ctx, "native_compaction_failed", EPOCH_STATES.FAILED);
        } finally {
          state.nativeInvocationActive = false;
        }
      },
    });

    api.on("session_before_compact", async (event, ctx) => {
      const epoch = state.epoch;
      if (!epoch || state.epochState !== EPOCH_STATES.AUTHORIZED || !state.nativeInvocationActive ||
          !Buffer.isBuffer(epoch.rawNonce)) return { cancel: true };
      if (now() >= epoch.expiresAtMs || !reassertSettings(ctx, "session_before_compact") ||
          !validNativePreparation(event, epoch)) {
        failEpoch(ctx, "native_preparation_invalid", EPOCH_STATES.INVALID);
        return { cancel: true };
      }
      let session;
      try {
        session = capturePersistedSession(ctx);
      } catch {
        failEpoch(ctx, "session_binding_changed", EPOCH_STATES.INVALID);
        return { cancel: true };
      }
      if (session.sessionId !== epoch.sessionId || session.sessionFileSha256 !== epoch.sessionFileSha256 ||
          session.branchSha256 !== epoch.branchSha256 || session.leafEntryId !== epoch.leafEntryId ||
          !sameCanonical(session.branchEntryIds, epoch.branchEntryIds) ||
          !await currentProjectionMatchesEpoch(ctx, epoch)) {
        failEpoch(ctx, "authority_binding_changed", EPOCH_STATES.INVALID);
        return { cancel: true };
      }
      epoch.rawNonce.fill(0);
      epoch.rawNonce = null;
      setEpochState(EPOCH_STATES.SUMMARIZING);
      try {
        const usage = ctx?.getContextUsage?.();
        if (isPlainObject(usage)) appendObservation(ctx, {
          usage,
          boundary: "session_before_compact",
          reasonCode: "authorized",
          providerAction: "allowed",
        });
      } catch { /* Observation is best-effort and cannot change authorization. */ }
      return {};
    });

    api.on("session.compacting", (event, ctx) => {
      const epoch = state.epoch;
      if (!epoch || state.epochState !== EPOCH_STATES.SUMMARIZING || event?.sessionId !== epoch.sessionId) {
        if (epoch && state.epochState === EPOCH_STATES.SUMMARIZING) {
          failEpoch(ctx, "summarizer_binding_changed", EPOCH_STATES.INVALID);
        }
        return undefined;
      }
      return {
        prompt: SAFE_COMPACTION_PROMPT,
        context: [`<context_continuity_kernel>\n${epoch.kernelCanonical}\n</context_continuity_kernel>`],
        preserveData: structuredClone(epoch.preserveData),
      };
    });

    api.on("session_compact", async (event, ctx) => {
      const epoch = state.epoch;
      if (!epoch || state.epochState !== EPOCH_STATES.SUMMARIZING) return;
      const persisted = event?.compactionEntry?.preserveData;
      const preserveValidation = validatePreserveData(persisted, epoch.preserveData);
      const kernel = preserveValidation.ok ? await currentProjectionMatchesEpoch(ctx, epoch) : null;
      if (!preserveValidation.ok || !kernel) {
        failEpoch(ctx, "native_settlement_invalid", EPOCH_STATES.INVALID);
        return;
      }
      try {
        if (typeof api.appendEntry !== "function") throw new Error("append_unavailable");
        api.appendEntry("topic07:epoch-state", epochStateEntry(epoch, EPOCH_STATES.AWAITING_INJECTION));
      } catch {
        failEpoch(ctx, "epoch_persistence_failed", EPOCH_STATES.INVALID);
        return;
      }
      setEpochState(EPOCH_STATES.AWAITING_INJECTION);
      try {
        const usage = ctx?.getContextUsage?.();
        if (isPlainObject(usage)) appendObservation(ctx, {
          usage,
          boundary: "session_compact",
          reasonCode: "settled",
          providerAction: "not_applicable",
        });
      } catch { /* Observation is best-effort and cannot change settlement. */ }
    });

    api.on("session_start", (_event, ctx) => { initializeSession(ctx, "session_start"); });
    api.on("session_switch", (_event, ctx) => { initializeSession(ctx, "session_switch"); });
    api.on("before_agent_start", (_event, ctx) => {
      if (!guardSessionAndSettings(ctx, "before_agent_start")) return;
      if (state.epochState === EPOCH_STATES.SUMMARIZING && state.nativeInvocationActive) return;
      if (state.epochState === EPOCH_STATES.INJECTED) {
        state.epochState = EPOCH_STATES.AWAITING_INJECTION;
        if (state.epoch) state.epoch.status = EPOCH_STATES.AWAITING_INJECTION;
      }
      state.requestGeneration += 1;
      state.requestAborted = false;
      state.injectionGeneration = null;
      state.injectionKernelHash = null;
      pressureGuard(ctx, "before_agent_start");
    });
    api.on("turn_end", (_event, ctx) => {
      if (!guardSessionAndSettings(ctx, "turn_end")) return;
      pressureGuard(ctx, "turn_end");
    });
    api.on("context", async (event, ctx) => {
      if (state.mode === SESSION_MODES.BOUNDED_SUBAGENT || state.requestAborted ||
          ![EPOCH_STATES.AWAITING_INJECTION, EPOCH_STATES.INJECTED].includes(state.epochState)) return undefined;
      const epoch = state.epoch;
      if (!epoch || state.requestGeneration < 1 || !Array.isArray(event?.messages)) {
        if (epoch) failEpoch(ctx, "kernel_injection_invalid", EPOCH_STATES.INVALID);
        abortSafely(ctx);
        return undefined;
      }
      if (state.epochState === EPOCH_STATES.AWAITING_INJECTION) {
        if (!await refreshPendingEpoch(ctx, epoch)) {
          failEpoch(ctx, "kernel_authority_changed", EPOCH_STATES.INVALID);
          abortSafely(ctx);
          return undefined;
        }
        state.injectionGeneration = state.requestGeneration;
        state.injectionKernelHash = epoch.kernelSha256;
        setEpochState(EPOCH_STATES.INJECTED);
      }
      if (state.injectionGeneration !== state.requestGeneration ||
          state.injectionKernelHash !== epoch.kernelSha256 || !epoch.kernel) {
        failEpoch(ctx, "kernel_injection_binding_changed", EPOCH_STATES.INVALID);
        abortSafely(ctx);
        return undefined;
      }
      const messages = event.messages.filter((message) =>
        !(isPlainObject(message) && message.role === "custom" && message.customType === "topic07-continuity-kernel"));
      messages.push(buildKernelMessage(epoch.kernel));
      return { messages };
    });
    api.on("before_provider_request", async (_event, ctx) => {
      if (!guardSessionAndSettings(ctx, "before_provider_request")) return;
      if (state.epochState === EPOCH_STATES.SUMMARIZING && state.nativeInvocationActive) return;
      if (state.mode === SESSION_MODES.BOUNDED_SUBAGENT) {
        pressureGuard(ctx, "before_provider_request");
        return;
      }
      const projection = await readProjection(ctx);
      if (projection.kind === "none" && state.mode === SESSION_MODES.BOOTSTRAP_UNARMED) {
        pressureGuard(ctx, "before_provider_request");
        publishState();
        return;
      }
      if (projection.kind !== "one") {
        invalidate(ctx, projection.kind === "ambiguous" ? "task_ownership_ambiguous" : "task_authority_unavailable", {
          abort: true,
          message: "Managed task authority is not uniquely available; provider work was stopped.",
        });
        return;
      }
      if (state.mode === SESSION_MODES.ARMED_MAIN && state.armedTaskId !== projection.kernel.task.task_id) {
        invalidate(ctx, "task_identity_changed", {
          abort: true,
          message: "Managed task identity changed unexpectedly; provider work was stopped.",
        });
        return;
      }
      state.mode = SESSION_MODES.ARMED_MAIN;
      state.armedTaskId = projection.kernel.task.task_id;
      state.armedKernelHash = projection.kernel.kernel_sha256;
      state.invalidReason = null;
      if (!pressureGuard(ctx, "before_provider_request")) {
        if (state.epochState === EPOCH_STATES.INJECTED && state.epoch) {
          state.epochState = EPOCH_STATES.AWAITING_INJECTION;
          state.epoch.status = EPOCH_STATES.AWAITING_INJECTION;
          state.injectionGeneration = null;
          state.injectionKernelHash = null;
          publishState();
        }
        return;
      }
      if (state.epochState === EPOCH_STATES.INVALID) {
        abortSafely(ctx);
        notifyOnce(ctx, "invalid_epoch_provider_block", "Managed continuity requires reconciliation before provider work can continue.", "error");
        publishState();
        return;
      }
      if (state.epochState === EPOCH_STATES.AWAITING_INJECTION) {
        abortSafely(ctx);
        notifyOnce(ctx, `injection_pending:${state.requestGeneration}`, "The required continuity kernel was not injected; provider work was stopped.", "error");
        publishState();
        return;
      }
      if (state.epochState === EPOCH_STATES.INJECTED) {
        if (!state.epoch || state.requestAborted || state.injectionGeneration !== state.requestGeneration ||
            state.injectionKernelHash !== state.epoch.kernelSha256) {
          abortSafely(ctx);
          if (state.epoch) {
            state.epochState = EPOCH_STATES.AWAITING_INJECTION;
            state.epoch.status = EPOCH_STATES.AWAITING_INJECTION;
          }
          publishState();
          return;
        }
        try {
          if (typeof api.appendEntry !== "function") throw new Error("append_unavailable");
          api.appendEntry("topic07:epoch-state", epochStateEntry(state.epoch, EPOCH_STATES.CONSUMED));
        } catch {
          failEpoch(ctx, "epoch_consumption_persistence_failed", EPOCH_STATES.INVALID);
          abortSafely(ctx);
          return;
        }
        setEpochState(EPOCH_STATES.CONSUMED);
        state.injectionGeneration = null;
        state.injectionKernelHash = null;
        try {
          const usage = ctx?.getContextUsage?.();
          if (isPlainObject(usage)) appendObservation(ctx, {
            usage,
            boundary: "before_provider_request",
            reasonCode: "kernel_consumed",
            providerAction: "allowed",
          });
        } catch { /* Observation is best-effort and cannot change consumption. */ }
      }
      publishState();
    });
    api.on("input", (event, ctx) => {
      if (event?.source === "interactive" && typeof event.text === "string" && /^\s*\/shake(?:\s|$)/u.test(event.text)) {
        boundedNotification(ctx, "Native /shake is unsupported in managed continuity; use /safe-compact after task arming.", "warning");
        return { handled: true };
      }
      return undefined;
    });
  };
}

export default createContextContinuityAdapter();
