import assert from "node:assert/strict";
import test from "node:test";

import {
  EPOCH_STATES,
  SESSION_MODES,
  createContextContinuityAdapter,
} from "../../template/.omp/extensions/context-continuity.js";
import {
  MANAGED_COMPACTION_PROFILE,
} from "../../template/.omp/contracts/context-continuity-schema.mjs";
import {
  sha256Canonical,
  validateContinuityKernel,
} from "../../template/.omp/contracts/context-continuity-core.mjs";

const EXPECTED_HOOKS = Object.freeze([
  "before_agent_start",
  "before_provider_request",
  "context",
  "input",
  "session.compacting",
  "session_before_compact",
  "session_compact",
  "session_start",
  "session_switch",
  "turn_end",
]);

function makeKernel({ sessionId = "omp:main", taskId = "T000001", revision = 1 } = {}) {
  const value = {
    schema_version: 1,
    record_type: "context_continuity_kernel",
    task: {
      task_id: taskId,
      workflow_class: "standard",
      objective: "Preserve exact managed continuity.",
      authority: ["user-approved-topic-07"],
      execution_mode: "mutating",
      write_scope: [{ kind: "subtree", path: "src" }],
      acceptance_criteria: [{ id: "AC-001", text: "Continuity remains exact.", mandatory: true }],
      obligations: ["Run deterministic verification."],
      locked_decisions: [{
        decision_id: "D-001",
        statement: "Use explicit safe compaction only.",
        authority_ref: "user:2026-08-13",
      }],
    },
    lifecycle: {
      status: "active",
      owner_session_ref: sessionId,
      owner_runtime: "omp",
      revision,
      revision_id: `R${String(revision).padStart(6, "0")}`,
      revision_sha256: "a".repeat(64),
      lease_generation: 1,
    },
    checkpoint: {
      checkpoint_id: null,
      checkpoint_sha256: null,
      work_unit_id: null,
      next_action: null,
      blockers: [],
      open_risks: [],
    },
    candidate: { candidate_id: null, candidate_hash: null, candidate_sha256: null },
    evidence_bindings: [],
    degraded_fields: [],
  };
  value.kernel_sha256 = sha256Canonical(value);
  assert.equal(validateContinuityKernel(value).ok, true);
  return value;
}

function selectedSessionInit(agent = "worker", overrides = {}) {
  return {
    type: "session_init",
    id: "entry-init",
    parentId: null,
    timestamp: "2026-08-14T00:00:00.000Z",
    systemPrompt: "Bounded selected-agent system contract.",
    task: "Execute WU-CURRENT only.",
    tools: ["read", "yield"],
    agent,
    modelRole: `@${agent}`,
    resolvedModel: "omniroute/example/model",
    ...overrides,
  };
}

function createHarness({
  branch = [],
  sessionId = "omp:main",
  sessionFile = "C:\\sessions\\main.jsonl",
  initialSettings = MANAGED_COMPACTION_PROFILE,
  projectionResponses = [],
  includeSettings = true,
  stickyOverrideFailure = null,
} = {}) {
  const handlers = new Map();
  const commands = new Map();
  const values = new Map(Object.entries(initialSettings));
  const settingsCalls = [];
  const notifications = [];
  const transitions = [];
  const providerStateCalls = [];
  const exitCodes = [];
  const runtime = {
    branch,
    sessionId,
    sessionFile,
    aborts: 0,
    shutdowns: 0,
    compactCalls: [],
  };
  const settings = includeSettings ? {
    get(path) {
      settingsCalls.push({ method: "get", path });
      return values.get(path);
    },
    override(path, value) {
      settingsCalls.push({ method: "override", path, value });
      if (path !== stickyOverrideFailure) values.set(path, value);
    },
  } : {};
  const api = {
    pi: { settings },
    on(name, handler) {
      const valuesForName = handlers.get(name) ?? [];
      valuesForName.push(handler);
      handlers.set(name, valuesForName);
    },
    registerCommand(name, options) {
      if (commands.has(name)) throw new Error("duplicate command");
      commands.set(name, options);
    },
  };
  const ctx = {
    cwd: "C:\\project",
    sessionManager: {
      getBranch: () => runtime.branch,
      getSessionId: () => runtime.sessionId,
      getSessionFile: () => runtime.sessionFile,
    },
    ui: { notify: (message, type) => notifications.push({ message, type }) },
    abort: () => { runtime.aborts += 1; },
    shutdown: () => { runtime.shutdowns += 1; },
    isIdle: () => true,
    hasPendingMessages: () => false,
    getAsyncJobSnapshot: () => ({ running: [], queued: [], delivering: [] }),
    getContextUsage: () => ({ tokens: 1_000, contextWindow: 32_768 }),
    compact: async (options) => { runtime.compactCalls.push(options); },
  };
  const invokeState = async ({ operation, request, ctx: stateContext }) => {
    providerStateCalls.push({ operation, request, sessionId: stateContext.sessionManager.getSessionId() });
    if (projectionResponses.length === 0) throw new Error("state_unavailable");
    const response = projectionResponses.shift();
    if (response instanceof Error) throw response;
    return structuredClone(response);
  };
  const factory = createContextContinuityAdapter({
    invokeState,
    onStateChange: (snapshot) => transitions.push(structuredClone(snapshot)),
    setProcessExitCode: (code) => exitCodes.push(code),
  });
  return {
    api,
    ctx,
    handlers,
    commands,
    values,
    settingsCalls,
    notifications,
    transitions,
    providerStateCalls,
    projectionResponses,
    exitCodes,
    runtime,
    factory,
    async emit(name, event = { type: name }) {
      const results = [];
      for (const handler of handlers.get(name) ?? []) results.push(await handler(event, ctx));
      return results;
    },
  };
}

function successEnvelope(kernel) {
  return { code: "AT-OK", data: kernel, ok: true, operation: "project-continuity" };
}

function failureEnvelope(code) {
  return { code, data: { message: "bounded" }, ok: false, operation: "project-continuity" };
}

test("registers exactly the v1 command and bootstrap hooks", async () => {
  const harness = createHarness();
  await harness.factory(harness.api);
  assert.deepEqual([...harness.handlers.keys()].sort(), [...EXPECTED_HOOKS]);
  assert.deepEqual([...harness.commands.keys()], ["safe-compact"]);
  assert.equal(typeof harness.commands.get("safe-compact").handler, "function");
  assert.equal(SESSION_MODES.BOOTSTRAP_UNARMED, "bootstrap_unarmed");
  assert.equal(SESSION_MODES.ARMED_MAIN, "armed_main");
  assert.equal(SESSION_MODES.BOUNDED_SUBAGENT, "bounded_subagent");
  assert.equal(EPOCH_STATES.NONE, "none");
});

test("reasserts the exact non-persistent managed profile without touching reserveTokens", async () => {
  const drifted = { ...MANAGED_COMPACTION_PROFILE };
  drifted["compaction.enabled"] = true;
  drifted["compaction.strategy"] = "context-full";
  const harness = createHarness({ initialSettings: drifted });
  await harness.factory(harness.api);
  await harness.emit("session_start");
  assert.deepEqual(Object.fromEntries(harness.values), MANAGED_COMPACTION_PROFILE);
  assert.deepEqual(
    harness.settingsCalls.filter((call) => call.method === "override").map((call) => call.path).sort(),
    ["compaction.enabled", "compaction.strategy"],
  );
  assert.equal(harness.settingsCalls.some((call) => call.path === "compaction.reserveTokens"), false);
  assert.equal(harness.settingsCalls.some((call) => call.method === "set"), false);
  assert.equal(harness.transitions.at(-1).mode, SESSION_MODES.BOOTSTRAP_UNARMED);
  assert.deepEqual(harness.transitions.at(-1).settings_drift_paths.sort(), ["compaction.enabled", "compaction.strategy"]);
});

test("keeps zero-task bootstrap unarmed, arms on one exact projection, then blocks authority loss", async () => {
  const kernel = makeKernel();
  const harness = createHarness({ projectionResponses: [
    failureEnvelope("AT-CONTINUITY-TASK-NOT-FOUND"),
    successEnvelope(kernel),
    failureEnvelope("AT-CONTINUITY-TASK-NOT-FOUND"),
  ] });
  await harness.factory(harness.api);
  await harness.emit("session_start");
  await harness.emit("before_provider_request", { type: "before_provider_request", payload: { messages: [] } });
  assert.equal(harness.runtime.aborts, 0);
  assert.equal(harness.transitions.at(-1).mode, SESSION_MODES.BOOTSTRAP_UNARMED);
  await harness.emit("before_provider_request", { type: "before_provider_request", payload: { messages: [] } });
  assert.equal(harness.runtime.aborts, 0);
  assert.equal(harness.transitions.at(-1).mode, SESSION_MODES.ARMED_MAIN);
  assert.equal(harness.transitions.at(-1).armed_task_id, "T000001");
  await harness.emit("before_provider_request", { type: "before_provider_request", payload: { messages: [] } });
  assert.equal(harness.runtime.aborts, 1);
  assert.equal(harness.transitions.at(-1).mode, SESSION_MODES.INVALID);
  assert.equal(harness.providerStateCalls.every((call) => call.operation === "project-continuity" && Object.keys(call.request).length === 0), true);
});

test("multiple ownership and malformed projections fail before provider dispatch", async () => {
  for (const response of [
    failureEnvelope("AT-CONTINUITY-TASK-AMBIGUOUS"),
    successEnvelope({ ...makeKernel(), extra: true }),
    new Error("state_unavailable"),
  ]) {
    const harness = createHarness({ projectionResponses: [response] });
    await harness.factory(harness.api);
    await harness.emit("session_start");
    await harness.emit("before_provider_request", { type: "before_provider_request", payload: {} });
    assert.equal(harness.runtime.aborts, 1);
    assert.equal(harness.transitions.at(-1).mode, SESSION_MODES.INVALID);
  }
});

test("recognizes exactly one selected-agent session_init as a bounded subagent", async () => {
  for (const agent of ["cheap-scout", "worker", "reviewer"]) {
    const harness = createHarness({ branch: [selectedSessionInit(agent)] });
    await harness.factory(harness.api);
    await harness.emit("session_start");
    assert.equal(harness.transitions.at(-1).mode, SESSION_MODES.BOUNDED_SUBAGENT);
    await harness.emit("before_provider_request", { type: "before_provider_request", payload: {} });
    assert.equal(harness.runtime.aborts, 0);
    assert.equal(harness.providerStateCalls.length, 0);
  }
});

test("malformed, unknown, or ambiguous session_init fails closed", async () => {
  for (const branch of [
    [selectedSessionInit("worker", { task: "" })],
    [selectedSessionInit("unknown")],
    [selectedSessionInit("worker"), selectedSessionInit("reviewer", { id: "entry-init-2" })],
    null,
  ]) {
    const harness = createHarness({ branch });
    await harness.factory(harness.api);
    await harness.emit("session_start");
    assert.equal(harness.transitions.at(-1).mode, SESSION_MODES.INVALID);
    assert.equal(harness.runtime.shutdowns, 1);
    assert.equal(harness.exitCodes.at(-1), 1);
  }
});

test("session switch discards prior arming and reconstructs from the new branch", async () => {
  const harness = createHarness({ projectionResponses: [successEnvelope(makeKernel())] });
  await harness.factory(harness.api);
  await harness.emit("session_start");
  await harness.emit("before_provider_request", { type: "before_provider_request", payload: {} });
  assert.equal(harness.transitions.at(-1).mode, SESSION_MODES.ARMED_MAIN);
  harness.runtime.sessionId = "omp:child";
  harness.runtime.sessionFile = "C:\\sessions\\child.jsonl";
  harness.runtime.branch = [selectedSessionInit("worker")];
  await harness.emit("session_switch", { type: "session_switch", reason: "resume", previousSessionFile: "C:\\sessions\\main.jsonl" });
  assert.equal(harness.transitions.at(-1).mode, SESSION_MODES.BOUNDED_SUBAGENT);
  assert.equal(harness.transitions.at(-1).armed_task_id, null);
});

test("reasserts at every required boundary and fails closed when settings cannot be proven", async () => {
  const harness = createHarness({ stickyOverrideFailure: "compaction.enabled" });
  await harness.factory(harness.api);
  harness.values.set("compaction.enabled", true);
  await harness.emit("session_start");
  assert.equal(harness.runtime.shutdowns, 1);
  assert.equal(harness.exitCodes.at(-1), 1);
  assert.equal(harness.transitions.at(-1).mode, SESSION_MODES.INVALID);

  const healthy = createHarness();
  await healthy.factory(healthy.api);
  await healthy.emit("session_start");
  for (const hook of ["before_agent_start", "turn_end", "before_provider_request"]) {
    healthy.values.set("compaction.dropUseless", false);
    if (hook === "before_provider_request") healthy.projectionResponses.push(failureEnvelope("AT-CONTINUITY-TASK-NOT-FOUND"));
    await healthy.emit(hook, { type: hook, payload: {} });
    assert.equal(healthy.values.get("compaction.dropUseless"), true);
  }
  assert.equal(
    healthy.settingsCalls.filter((call) => call.method === "override" && call.path === "compaction.dropUseless").length,
    3,
  );
});

test("missing settings get/override registers a startup shutdown guard", async () => {
  const harness = createHarness({ includeSettings: false });
  await harness.factory(harness.api);
  assert.deepEqual([...harness.handlers.keys()].sort(), [...EXPECTED_HOOKS]);
  await harness.emit("session_start");
  assert.equal(harness.runtime.shutdowns, 1);
  assert.equal(harness.exitCodes.at(-1), 1);
  await harness.emit("before_provider_request", { type: "before_provider_request", payload: {} });
  assert.equal(harness.runtime.aborts, 1);
  assert.equal(harness.providerStateCalls.length, 0);
});

test("consumes interactive shake input and detects native shake placeholders", async () => {
  const harness = createHarness();
  await harness.factory(harness.api);
  await harness.emit("session_start");
  const [shake] = await harness.emit("input", { type: "input", text: "/shake aggressive", source: "interactive" });
  const [ordinary] = await harness.emit("input", { type: "input", text: "continue", source: "interactive" });
  assert.deepEqual(shake, { handled: true });
  assert.equal(ordinary, undefined);
  harness.runtime.branch = [{
    type: "message",
    id: "entry-shaken",
    message: { role: "toolResult", content: [{ type: "text", text: "[shaken ~1234 tokens]" }] },
  }];
  await harness.emit("before_agent_start", { type: "before_agent_start", prompt: "continue", systemPrompt: [] });
  assert.equal(harness.runtime.aborts, 1);
  assert.equal(harness.transitions.at(-1).mode, SESSION_MODES.INVALID);
});

test("notifications and state snapshots remain bounded and exclude drift values", async () => {
  const drifted = { ...MANAGED_COMPACTION_PROFILE, "compaction.strategy": "SECRET_PROVIDER_PAYLOAD" };
  const harness = createHarness({ initialSettings: drifted });
  await harness.factory(harness.api);
  await harness.emit("session_start");
  await harness.commands.get("safe-compact").handler("unexpected", harness.ctx);
  assert.equal(harness.notifications.length > 0, true);
  for (const notification of harness.notifications) {
    assert.equal(typeof notification.message, "string");
    assert.equal(Buffer.byteLength(notification.message, "utf8") <= 240, true);
    assert.equal(notification.message.includes("SECRET_PROVIDER_PAYLOAD"), false);
  }
  assert.equal(JSON.stringify(harness.transitions).includes("SECRET_PROVIDER_PAYLOAD"), false);
  assert.equal(harness.runtime.compactCalls.length, 0);
});
