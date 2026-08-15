import assert from "node:assert/strict";
import test from "node:test";

import {
  CONTEXT_PRESSURE_ABORT_MARKER,
  consumeContextPressureAbort,
  recordContextPressureAbort,
  sha256Canonical,
} from "../../template/.omp/contracts/context-continuity-core.mjs";
import { MANAGED_COMPACTION_PROFILE } from "../../template/.omp/contracts/context-continuity-schema.mjs";
import {
  EPOCH_STATES,
  SESSION_MODES,
  createContextContinuityAdapter,
} from "../../template/.omp/extensions/context-continuity.js";

function kernel({ revision = 1, sessionId = "omp:main" } = {}) {
  const value = {
    schema_version: 1,
    record_type: "context_continuity_kernel",
    task: {
      task_id: "T000001", workflow_class: "standard", objective: "Continue the exact task.",
      authority: ["user-approved-topic-07"], execution_mode: "mutating",
      write_scope: [{ kind: "subtree", path: "src" }],
      acceptance_criteria: [{ id: "AC-001", text: "The task stays authoritative.", mandatory: true }],
      obligations: ["Run deterministic verification."],
      locked_decisions: [{ decision_id: "D-001", statement: "Use managed continuity.", authority_ref: "user" }],
    },
    lifecycle: {
      status: "active", owner_session_ref: sessionId, owner_runtime: "omp", revision,
      revision_id: `R${String(revision).padStart(6, "0")}`, revision_sha256: "a".repeat(64), lease_generation: 1,
    },
    checkpoint: {
      checkpoint_id: null, checkpoint_sha256: null, work_unit_id: null, next_action: null,
      blockers: [], open_risks: [],
    },
    candidate: { candidate_id: null, candidate_hash: null, candidate_sha256: null },
    evidence_bindings: [], degraded_fields: [],
  };
  value.kernel_sha256 = sha256Canonical(value);
  return value;
}

function selectedInit(agent = "worker", task = "canonical-topic06-packet") {
  return {
    type: "session_init", id: "entry-init", systemPrompt: "Bounded contract.", task,
    tools: ["read", "yield"], agent,
  };
}

function epochEntry(currentKernel, status = "awaiting_injection", overrides = {}) {
  return {
    type: "custom", id: `entry-epoch-${status}`, customType: "topic07:epoch-state",
    data: {
      schema_version: 1,
      epoch_id: "E-00000000-0000-4000-8000-000000000007",
      task_id: currentKernel.task.task_id,
      task_revision_sha256: currentKernel.lifecycle.revision_sha256,
      kernel_sha256: currentKernel.kernel_sha256,
      branch_sha256: "b".repeat(64),
      recovery_artifact_id: "artifact-topic07-000001",
      recovery_artifact_sha256: "c".repeat(64),
      status,
      ...overrides,
    },
  };
}

function createHarness({
  currentKernel = kernel(),
  branch = [{ id: "entry-001", type: "message" }],
  usage = { tokens: 1_000, contextWindow: 32_768 },
} = {}) {
  const handlers = new Map();
  const entries = [];
  const notifications = [];
  const transitions = [];
  const settings = new Map(Object.entries(MANAGED_COMPACTION_PROFILE));
  const runtime = { branch: structuredClone(branch), usage, aborts: 0, shutdowns: 0, generation: 0 };
  const api = {
    pi: { settings: { get: (key) => settings.get(key), override: (key, value) => settings.set(key, value) } },
    on(name, handler) {
      const list = handlers.get(name) ?? [];
      list.push(handler);
      handlers.set(name, list);
    },
    registerCommand() {},
    appendEntry(customType, data) { entries.push({ customType, data: structuredClone(data) }); },
  };
  const ctx = {
    cwd: "D:\\fixture",
    sessionManager: {
      getSessionId: () => currentKernel.lifecycle.owner_session_ref,
      getSessionFile: () => "D:\\fixture\\session.jsonl",
      getBranch: () => runtime.branch,
    },
    ui: { notify: (message, type) => notifications.push({ message, type }) },
    abort: () => { runtime.aborts += 1; },
    shutdown: () => { runtime.shutdowns += 1; },
    getContextUsage: () => runtime.usage,
  };
  const factory = createContextContinuityAdapter({
    invokeState: async () => ({ code: "AT-OK", data: structuredClone(currentKernel), ok: true, operation: "project-continuity" }),
    onStateChange: (value) => transitions.push(structuredClone(value)),
    setProcessExitCode: () => {},
  });
  async function emit(name, event = { type: name }) {
    const results = [];
    for (const handler of handlers.get(name) ?? []) results.push(await handler(event, ctx));
    return results;
  }
  return {
    api, ctx, handlers, entries, notifications, transitions, runtime, factory, emit,
    async start({ arm = true } = {}) {
      await factory(api);
      await emit("session_start");
      if (arm) await emit("before_provider_request", { type: "before_provider_request", payload: {} });
    },
  };
}

test("below threshold is allowed while equal and above synchronously abort every normal boundary", async () => {
  const cases = [
    { contextWindow: 32_768, threshold: 16_384 },
    { contextWindow: 128_000, threshold: 108_800 },
    { contextWindow: 8_192, threshold: 6_964 },
  ];
  for (const item of cases) {
    for (const [offset, aborted] of [[-1, false], [0, true], [1, true]]) {
      const harness = createHarness();
      await harness.start();
      harness.runtime.usage = { tokens: item.threshold + offset, contextWindow: item.contextWindow };
      const before = harness.runtime.aborts;
      await harness.emit("before_agent_start");
      assert.equal(harness.runtime.aborts > before, aborted, `${item.contextWindow}/${offset}`);
    }
  }
});

test("unavailable usage fails closed only at the final provider boundary after arming", async () => {
  const harness = createHarness();
  await harness.start();
  harness.runtime.usage = undefined;
  const before = harness.runtime.aborts;
  await harness.emit("before_agent_start");
  await harness.emit("turn_end");
  assert.equal(harness.runtime.aborts, before);
  await harness.emit("before_provider_request", { type: "before_provider_request", payload: {} });
  assert.equal(harness.runtime.aborts, before + 1);
});

test("one awaiting epoch injects one fresh hidden kernel for one request generation then is consumed", async () => {
  const current = kernel();
  const harness = createHarness({ branch: [
    { id: "entry-001", type: "message" },
    { id: "entry-compaction", type: "compaction" },
    epochEntry(current),
  ] });
  await harness.start({ arm: false });
  assert.equal(harness.transitions.at(-1).epoch_state, EPOCH_STATES.AWAITING_INJECTION);
  await harness.emit("before_agent_start");
  const base = [{ role: "user", content: "continue" }];
  const first = (await harness.emit("context", { type: "context", messages: structuredClone(base) })).at(-1);
  const repeated = (await harness.emit("context", { type: "context", messages: structuredClone(base) })).at(-1);
  for (const value of [first, repeated]) {
    assert.equal(value.messages.length, 2);
    assert.equal(value.messages.filter((message) => message.customType === "topic07-continuity-kernel").length, 1);
    assert.match(value.messages.at(-1).content, /^<context_continuity_kernel>\n/u);
  }
  assert.equal(harness.transitions.at(-1).epoch_state, EPOCH_STATES.INJECTED);
  await harness.emit("before_provider_request", { type: "before_provider_request", payload: {} });
  assert.equal(harness.transitions.at(-1).epoch_state, EPOCH_STATES.CONSUMED);
  assert.equal(harness.entries.filter((entry) => entry.customType === "topic07:epoch-state" && entry.data.status === "consumed").length, 1);
  const later = (await harness.emit("context", { type: "context", messages: structuredClone(base) })).at(-1);
  assert.equal(later, undefined);
});

test("pressure-aborted generation leaves injection pending for the next below-threshold request", async () => {
  const current = kernel();
  const harness = createHarness({ branch: [{ id: "entry-001", type: "message" }, epochEntry(current)] });
  await harness.start({ arm: false });
  harness.runtime.usage = { tokens: 16_384, contextWindow: 32_768 };
  await harness.emit("before_agent_start");
  const blocked = (await harness.emit("context", { type: "context", messages: [] })).at(-1);
  assert.equal(blocked, undefined);
  assert.equal(harness.transitions.at(-1).epoch_state, EPOCH_STATES.AWAITING_INJECTION);
  harness.runtime.usage = { tokens: 1_000, contextWindow: 32_768 };
  await harness.emit("before_agent_start");
  const retried = (await harness.emit("context", { type: "context", messages: [] })).at(-1);
  assert.equal(retried.messages.length, 1);
});

test("changed authority or malformed persisted epoch blocks injection and provider dispatch", async () => {
  const original = kernel();
  const revised = kernel({ revision: 2 });
  const changed = createHarness({ currentKernel: revised, branch: [{ id: "entry-001", type: "message" }, epochEntry(original)] });
  await changed.start({ arm: false });
  await changed.emit("before_agent_start");
  assert.equal((await changed.emit("context", { type: "context", messages: [] })).at(-1), undefined);
  await changed.emit("before_provider_request", { type: "before_provider_request", payload: {} });
  assert.ok(changed.runtime.aborts >= 1);
  assert.equal(changed.transitions.at(-1).epoch_state, EPOCH_STATES.INVALID);

  const malformed = createHarness({ branch: [{ id: "entry-001", type: "message" }, epochEntry(original, "awaiting_injection", { extra: true })] });
  await malformed.start({ arm: false });
  assert.equal(malformed.transitions.at(-1).mode, SESSION_MODES.INVALID);
  assert.equal(malformed.runtime.shutdowns, 1);
});

test("an already-consumed persisted epoch never reinjects or schedules a continuation", async () => {
  const current = kernel();
  const harness = createHarness({ branch: [{ id: "entry-001", type: "message" }, epochEntry(current, "consumed")] });
  await harness.start({ arm: false });
  await harness.emit("before_agent_start");
  assert.equal((await harness.emit("context", { type: "context", messages: [] })).at(-1), undefined);
  assert.equal(harness.transitions.at(-1).epoch_state, EPOCH_STATES.CONSUMED);
  assert.equal(harness.entries.length, 0);
});

test("bounded Scout, Worker, and Reviewer pressure aborts publish one exact consumable marker", async () => {
  for (const agent of ["cheap-scout", "worker", "reviewer"]) {
    const task = `canonical-${agent}-packet`;
    const current = kernel({ sessionId: `omp:${agent}` });
    const harness = createHarness({
      currentKernel: current,
      branch: [selectedInit(agent, task)],
      usage: { tokens: 16_384, contextWindow: 32_768 },
    });
    await harness.start({ arm: false });
    await harness.emit("before_agent_start");
    assert.equal(harness.runtime.aborts, 1);
    assert.equal(consumeContextPressureAbort({ agent, task }), CONTEXT_PRESSURE_ABORT_MARKER);
    assert.equal(consumeContextPressureAbort({ agent, task }), null, "marker is single-consume");
    const markerEntries = harness.entries.filter((entry) => entry.customType === "topic07:context-pressure-abort");
    assert.equal(markerEntries.length, 1);
    assert.equal(markerEntries[0].data.marker, CONTEXT_PRESSURE_ABORT_MARKER);
    assert.doesNotMatch(JSON.stringify(markerEntries[0]), new RegExp(task, "u"));
  }
});

test("the in-process pressure marker accepts a bounded full-size canonical child packet", () => {
  const task = `packet-${"x".repeat(12_000)}`;
  assert.equal(recordContextPressureAbort({ agent: "worker", task }), true);
  assert.equal(consumeContextPressureAbort({ agent: "worker", task }), CONTEXT_PRESSURE_ABORT_MARKER);
});

test("pressure observations stay bounded and exclude prompts, paths, and provider payloads", async () => {
  const harness = createHarness();
  await harness.start();
  harness.runtime.usage = { tokens: 16_384, contextWindow: 32_768 };
  await harness.emit("before_agent_start");
  const observations = harness.entries.filter((entry) => entry.customType === "topic07:observation");
  assert.ok(observations.length >= 1);
  for (const entry of observations) {
    assert.ok(Buffer.byteLength(JSON.stringify(entry.data), "utf8") <= 4_096);
    assert.doesNotMatch(JSON.stringify(entry), /D:\\fixture|provider payload|<context_continuity_kernel>|Continue the exact task/iu);
  }
});
