import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test, { after } from "node:test";

import {
  EPOCH_STATES,
  SAFE_COMPACTION_PROMPT,
  SESSION_MODES,
  createContextContinuityAdapter,
} from "../../template/.omp/extensions/context-continuity.js";
import { MANAGED_COMPACTION_PROFILE } from "../../template/.omp/contracts/context-continuity-schema.mjs";
import {
  canonicalJson,
  sha256Canonical,
  validateContinuityKernel,
  validatePreserveData,
} from "../../template/.omp/contracts/context-continuity-core.mjs";

const roots = [];
after(() => {
  for (const root of roots) fs.rmSync(root, { recursive: true, force: true });
});

function makeKernel({ sessionId = "omp:main", taskId = "T000001", revision = 1, lease = 1 } = {}) {
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
      lease_generation: lease,
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

function successEnvelope(kernel) {
  return { code: "AT-OK", data: kernel, ok: true, operation: "project-continuity" };
}

function failureEnvelope(code) {
  return { code, data: {}, ok: false, operation: "project-continuity" };
}

function selectedSessionInit(agent = "worker") {
  return {
    type: "session_init",
    id: "entry-init",
    parentId: null,
    timestamp: "2026-08-14T00:00:00.000Z",
    systemPrompt: "Bounded selected-agent system contract.",
    task: "Execute WU-CURRENT only.",
    tools: ["read", "yield"],
    agent,
  };
}

function preparation(branch) {
  return {
    firstKeptEntryId: branch.at(-1).id,
    messagesToSummarize: [{ role: "user", content: "bounded" }],
    turnPrefixMessages: [],
    recentMessages: [{ role: "assistant", content: "kept" }],
    isSplitTurn: false,
    tokensBefore: 24_000,
    fileOps: { read: [], modified: [] },
    settings: {
      strategy: "context-full",
      remoteEnabled: false,
      keepRecentTokens: 20_000,
    },
  };
}

function createHarness({
  branch = [{ id: "entry-001", type: "message" }, { id: "entry-002", type: "message" }],
  sessionId = "omp:main",
  persisted = true,
  artifactDirectory = true,
  idle = true,
  pendingMessages = false,
  asyncJobs = { running: [], queued: [], delivering: [] },
  projectionResponses,
  projectionFactory,
  artifactFault = null,
  nativeDriver,
  stickyOverrideFailure = null,
  nowMs = Date.parse("2026-08-14T00:00:00.000Z"),
} = {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "topic07-safe-compact-"));
  roots.push(root);
  const sessionFile = path.join(root, "session.jsonl");
  const artifactsDir = path.join(root, "artifacts");
  if (persisted) fs.writeFileSync(sessionFile, "{}\n", "utf8");
  if (artifactDirectory) fs.mkdirSync(artifactsDir, { recursive: true });

  const handlers = new Map();
  const commands = new Map();
  const entries = [];
  const notifications = [];
  const transitions = [];
  const stateCalls = [];
  const settingsValues = new Map(Object.entries(MANAGED_COMPACTION_PROFILE));
  const clock = { nowMs };
  const queue = projectionResponses ? [...projectionResponses] : null;
  const currentKernel = makeKernel({ sessionId });
  const runtime = {
    branch: structuredClone(branch),
    sessionId,
    sessionFile: persisted ? sessionFile : undefined,
    artifactsDir: artifactDirectory ? artifactsDir : null,
    idle,
    pendingMessages,
    asyncJobs: structuredClone(asyncJobs),
    compacts: [],
    aborts: 0,
    shutdowns: 0,
    savedBytes: null,
    artifactPath: null,
    usage: { tokens: 1_000, contextWindow: 32_768 },
  };

  async function emit(name, event, ctx) {
    const results = [];
    for (const handler of handlers.get(name) ?? []) results.push(await handler(event ?? { type: name }, ctx));
    return results;
  }

  const api = {
    pi: {
      settings: {
        get(settingPath) { return settingsValues.get(settingPath); },
        override(settingPath, value) {
          if (settingPath !== stickyOverrideFailure) settingsValues.set(settingPath, value);
        },
      },
    },
    on(name, handler) {
      const list = handlers.get(name) ?? [];
      list.push(handler);
      handlers.set(name, list);
    },
    registerCommand(name, options) { commands.set(name, options); },
    appendEntry(customType, data) { entries.push({ customType, data: structuredClone(data) }); },
  };

  const ctx = {
    cwd: root,
    sessionManager: {
      getBranch: () => runtime.branch,
      getSessionId: () => runtime.sessionId,
      getSessionFile: () => runtime.sessionFile,
      getArtifactsDir: () => runtime.artifactsDir,
      async saveArtifact(content, toolType) {
        if (artifactFault === "save_throw") throw new Error("private save failure");
        if (artifactFault === "empty_id") return "";
        const artifactId = "artifact-topic07-000001";
        const destination = artifactFault === "outside_path"
          ? path.join(root, "outside.json")
          : path.join(artifactsDir, `${artifactId}.json`);
        runtime.savedBytes = content;
        runtime.artifactPath = destination;
        fs.mkdirSync(path.dirname(destination), { recursive: true });
        fs.writeFileSync(destination, artifactFault === "read_mismatch" ? `${content}tampered` : content, "utf8");
        return artifactId;
      },
      async getArtifactPath() {
        if (artifactFault === "path_throw") throw new Error("private path failure");
        if (artifactFault === "missing_path") return path.join(artifactsDir, "missing.json");
        return runtime.artifactPath;
      },
    },
    ui: { notify: (message, type) => notifications.push({ message, type }) },
    abort: () => { runtime.aborts += 1; },
    shutdown: () => { runtime.shutdowns += 1; },
    isIdle: () => runtime.idle,
    hasPendingMessages: () => runtime.pendingMessages,
    getAsyncJobSnapshot: () => runtime.asyncJobs,
    getContextUsage: () => runtime.usage,
    async compact(options) {
      runtime.compacts.push(options);
      const drive = nativeDriver ?? (async () => {
        const beforeResults = await emit("session_before_compact", {
          type: "session_before_compact",
          preparation: preparation(runtime.branch),
          branchEntries: structuredClone(runtime.branch),
          signal: new AbortController().signal,
        }, ctx);
        const before = beforeResults.at(-1);
        if (before?.cancel) {
          const error = new Error("native compact cancelled");
          options.onError?.(error);
          throw error;
        }
        const compactingResults = await emit("session.compacting", {
          type: "session.compacting",
          sessionId: runtime.sessionId,
          messages: [{ role: "user", content: "bounded" }],
        }, ctx);
        const compacting = compactingResults.at(-1);
        const result = {
          summary: "bounded summary",
          firstKeptEntryId: runtime.branch.at(-1).id,
          tokensBefore: 24_000,
          preserveData: compacting?.preserveData,
        };
        await emit("session_compact", {
          type: "session_compact",
          compactionEntry: { id: "entry-compaction", type: "compaction", ...result },
          fromExtension: false,
        }, ctx);
        options.onComplete?.(result);
      });
      return drive({ api, ctx, emit, options, runtime, clock });
    },
  };

  const invokeState = async ({ operation, request, ctx: stateContext }) => {
    stateCalls.push({ operation, request, sessionId: stateContext.sessionManager.getSessionId() });
    if (projectionFactory) return structuredClone(await projectionFactory(stateCalls.length));
    if (queue) {
      if (queue.length === 0) throw new Error("state queue exhausted");
      return structuredClone(queue.shift());
    }
    return successEnvelope(currentKernel);
  };
  const factory = createContextContinuityAdapter({
    invokeState,
    onStateChange: (value) => transitions.push(structuredClone(value)),
    setProcessExitCode: () => {},
    now: () => clock.nowMs,
    randomBytes: () => Buffer.alloc(32, 7),
    randomUUID: () => "00000000-0000-4000-8000-000000000007",
  });

  return {
    api, ctx, handlers, commands, entries, notifications, transitions, stateCalls, settingsValues,
    runtime, clock, factory,
    emit: (name, event) => emit(name, event, ctx),
    async start({ arm = true } = {}) {
      await factory(api);
      await emit("session_start", { type: "session_start" }, ctx);
      if (arm) await emit("before_provider_request", { type: "before_provider_request", payload: {} }, ctx);
    },
    runCommand(args = "") { return commands.get("safe-compact").handler(args, ctx); },
  };
}

test("safe compact refuses every ineligible mode or busy/pending runtime before native compact", async () => {
  const cases = [
    ["arguments", {}, "focus"],
    ["bootstrap", { projectionResponses: [failureEnvelope("AT-CONTINUITY-TASK-NOT-FOUND")] }, ""],
    ["subagent", { branch: [selectedSessionInit()] }, ""],
    ["invalid", { branch: [{ type: "session_init", id: "bad" }] }, ""],
    ["memory", { persisted: false }, ""],
    ["artifact directory", { artifactDirectory: false }, ""],
    ["busy", { idle: false }, ""],
    ["pending messages", { pendingMessages: true }, ""],
    ["running jobs", { asyncJobs: { running: [{}], queued: [], delivering: [] } }, ""],
    ["queued jobs", { asyncJobs: { running: [], queued: [{}], delivering: [] } }, ""],
    ["delivering jobs", { asyncJobs: { running: [], queued: [], delivering: [{}] } }, ""],
  ];
  for (const [label, options, args] of cases) {
    const harness = createHarness(options);
    await harness.start();
    await harness.runCommand(args);
    assert.equal(harness.runtime.compacts.length, 0, label);
  }
});

test("safe compact rejects zero, ambiguous, malformed, changed, and oversize task authority", async () => {
  const invalid = makeKernel();
  invalid.extra = true;
  const oversize = makeKernel();
  oversize.task.objective = "x".repeat(4_000);
  oversize.task.authority = Array.from({ length: 60 }, (_, index) => `${String(index).padStart(2, "0")}-${"a".repeat(300)}`);
  delete oversize.kernel_sha256;
  oversize.kernel_sha256 = sha256Canonical(oversize);
  assert.equal(validateContinuityKernel(oversize).ok, false);
  const changed = makeKernel({ taskId: "T000002" });
  for (const [label, response] of [
    ["zero", failureEnvelope("AT-CONTINUITY-TASK-NOT-FOUND")],
    ["ambiguous", failureEnvelope("AT-CONTINUITY-TASK-AMBIGUOUS")],
    ["malformed", { ok: true }],
    ["invalid kernel", successEnvelope(invalid)],
    ["oversize kernel", successEnvelope(oversize)],
    ["changed task", successEnvelope(changed)],
  ]) {
    const harness = createHarness({ projectionResponses: [successEnvelope(makeKernel()), response] });
    await harness.start();
    await harness.runCommand();
    assert.equal(harness.runtime.compacts.length, 0, label);
  }
});

test("every recovery artifact save, path, containment, read, or hash failure stops before compact", async () => {
  for (const fault of ["save_throw", "empty_id", "path_throw", "missing_path", "outside_path", "read_mismatch"]) {
    const harness = createHarness({ artifactFault: fault });
    await harness.start();
    await harness.runCommand();
    assert.equal(harness.runtime.compacts.length, 0, fault);
  }
});

test("one valid command writes and verifies one closed recovery artifact then invokes native soft compact once", async () => {
  const harness = createHarness();
  await harness.start();
  await harness.runCommand();
  assert.equal(harness.runtime.compacts.length, 1);
  assert.deepEqual(Object.keys(harness.runtime.compacts[0]).sort(), ["mode", "onComplete", "onError"]);
  assert.equal(harness.runtime.compacts[0].mode, "soft");
  assert.match(harness.runtime.savedBytes, /\n$/u);
  const artifact = JSON.parse(harness.runtime.savedBytes);
  assert.deepEqual(Object.keys(artifact).sort(), [
    "artifact_sha256", "branch_entry_ids", "branch_sha256", "created_at_utc", "epoch_id",
    "expires_at_utc", "kernel", "kernel_sha256", "leaf_entry_id", "lease_generation",
    "record_type", "schema_version", "session_file_sha256", "session_id_sha256", "task_id",
    "task_revision_sha256",
  ]);
  const withoutHash = structuredClone(artifact);
  delete withoutHash.artifact_sha256;
  assert.equal(artifact.artifact_sha256, sha256Canonical(withoutHash));
  assert.doesNotMatch(harness.runtime.savedBytes, /raw_nonce|transcript|conversation|reasoning/iu);
  assert.equal(harness.transitions.at(-1).epoch_state, EPOCH_STATES.AWAITING_INJECTION);
  const epochEntries = harness.entries.filter((entry) => entry.customType === "topic07:epoch-state");
  assert.equal(epochEntries.length, 1);
  assert.doesNotMatch(JSON.stringify(epochEntries[0]), /nonce(?!_sha256)|session\.jsonl/iu);
  assert.ok(harness.entries.some((entry) => entry.customType === "topic07:observation"));
});

test("unauthorized, malformed, expired, and replayed before-compact hooks always cancel", async () => {
  const harness = createHarness({ nativeDriver: async () => {} });
  await harness.start();
  const event = {
    type: "session_before_compact",
    preparation: preparation(harness.runtime.branch),
    branchEntries: structuredClone(harness.runtime.branch),
    signal: new AbortController().signal,
  };
  assert.deepEqual((await harness.emit("session_before_compact", event)).at(-1), { cancel: true });

  let first;
  const authorized = createHarness({
    nativeDriver: async ({ emit, ctx, runtime, clock }) => {
      clock.nowMs += 120_000;
      first = (await emit("session_before_compact", {
        ...event,
        preparation: preparation(runtime.branch),
        branchEntries: structuredClone(runtime.branch),
      }, ctx)).at(-1);
    },
  });
  await authorized.start();
  await authorized.runCommand();
  assert.deepEqual(first, { cancel: true });

  let allowed;
  let replay;
  const consumed = createHarness({
    nativeDriver: async ({ emit, ctx, runtime }) => {
      const current = {
        type: "session_before_compact",
        preparation: preparation(runtime.branch),
        branchEntries: structuredClone(runtime.branch),
        signal: new AbortController().signal,
      };
      allowed = (await emit("session_before_compact", current, ctx)).at(-1);
      replay = (await emit("session_before_compact", current, ctx)).at(-1);
    },
  });
  await consumed.start();
  await consumed.runCommand();
  assert.deepEqual(allowed, {});
  assert.deepEqual(replay, { cancel: true });
});

test("branch, leaf, task revision, lease, kernel, or preparation races cancel without retry", async () => {
  const base = makeKernel();
  const revised = makeKernel({ revision: 2 });
  const leaseChanged = makeKernel({ lease: 2 });
  for (const [label, mutate, response] of [
    ["branch", ({ runtime }) => runtime.branch.push({ id: "entry-race", type: "message" }), successEnvelope(base)],
    ["revision", () => {}, successEnvelope(revised)],
    ["lease", () => {}, successEnvelope(leaseChanged)],
  ]) {
    let before;
    const harness = createHarness({
      projectionResponses: [successEnvelope(base), successEnvelope(base), response],
      nativeDriver: async (surface) => {
        mutate(surface);
        before = (await surface.emit("session_before_compact", {
          type: "session_before_compact",
          preparation: preparation(surface.runtime.branch),
          branchEntries: structuredClone(surface.runtime.branch),
          signal: new AbortController().signal,
        }, surface.ctx)).at(-1);
      },
    });
    await harness.start();
    await harness.runCommand();
    assert.deepEqual(before, { cancel: true }, label);
    assert.equal(harness.runtime.compacts.length, 1, label);
  }

  const malformedPreparations = [
    (value) => { value.messagesToSummarize = []; },
    (value) => { value.firstKeptEntryId = "missing-entry"; },
    (value) => { value.tokensBefore = 0; },
    (value) => { value.settings.strategy = "off"; },
    (value) => { value.settings.remoteEnabled = true; },
    (value) => { value.settings.keepRecentTokens = 1; },
  ];
  for (const mutate of malformedPreparations) {
    let before;
    const harness = createHarness({
      nativeDriver: async ({ emit, ctx, runtime }) => {
        const value = preparation(runtime.branch);
        mutate(value);
        before = (await emit("session_before_compact", {
          type: "session_before_compact", preparation: value,
          branchEntries: structuredClone(runtime.branch), signal: new AbortController().signal,
        }, ctx)).at(-1);
      },
    });
    await harness.start();
    await harness.runCommand();
    assert.deepEqual(before, { cancel: true });
  }
});

test("the summarizer receives one authoritative kernel and exact hashed preserveData, never the raw nonce", async () => {
  let compacting;
  let before;
  const harness = createHarness({
    nativeDriver: async ({ emit, ctx, runtime }) => {
      before = (await emit("session_before_compact", {
        type: "session_before_compact",
        preparation: preparation(runtime.branch),
        branchEntries: structuredClone(runtime.branch),
        signal: new AbortController().signal,
      }, ctx)).at(-1);
      compacting = (await emit("session.compacting", {
        type: "session.compacting", sessionId: runtime.sessionId, messages: [],
      }, ctx)).at(-1);
    },
  });
  await harness.start();
  await harness.runCommand();
  assert.deepEqual(before, {});
  assert.equal(compacting.prompt, SAFE_COMPACTION_PROMPT);
  assert.equal(compacting.context.length, 1);
  assert.equal((compacting.context[0].match(/<context_continuity_kernel>/gu) ?? []).length, 1);
  assert.equal(validatePreserveData(compacting.preserveData, compacting.preserveData).ok, true);
  const serialized = canonicalJson(compacting);
  assert.doesNotMatch(serialized, /0707070707070707/iu);
  assert.equal(Object.hasOwn(compacting.preserveData["omp_template.topic07"], "kernel"), false);
});

test("mismatched preserveData or task changes during summarization invalidates the epoch", async () => {
  const original = makeKernel();
  const revised = makeKernel({ revision: 2 });
  for (const [label, tamper, finalResponse] of [
    ["preserve", (value) => { value["omp_template.topic07"].branch_sha256 = "f".repeat(64); }, successEnvelope(original)],
    ["revision", () => {}, successEnvelope(revised)],
  ]) {
    const harness = createHarness({
      projectionResponses: [successEnvelope(original), successEnvelope(original), successEnvelope(original), finalResponse],
      nativeDriver: async ({ emit, ctx, runtime, options }) => {
        await emit("session_before_compact", {
          type: "session_before_compact", preparation: preparation(runtime.branch),
          branchEntries: structuredClone(runtime.branch), signal: new AbortController().signal,
        }, ctx);
        const compacting = (await emit("session.compacting", {
          type: "session.compacting", sessionId: runtime.sessionId, messages: [],
        }, ctx)).at(-1);
        const persisted = structuredClone(compacting.preserveData);
        tamper(persisted);
        await emit("session_compact", {
          type: "session_compact",
          compactionEntry: { id: "entry-compaction", type: "compaction", preserveData: persisted },
          fromExtension: false,
        }, ctx);
        options.onComplete?.({ preserveData: persisted });
      },
    });
    await harness.start();
    await harness.runCommand();
    assert.equal(harness.transitions.at(-1).epoch_state, EPOCH_STATES.INVALID, label);
    assert.equal(harness.runtime.compacts.length, 1, label);
  }
});

test("native failure clears authorization, records one bounded failure, and never retries", async () => {
  const originalBranch = [{ id: "entry-001", type: "message" }, { id: "entry-002", type: "message" }];
  const harness = createHarness({
    branch: originalBranch,
    nativeDriver: async ({ options }) => {
      const error = new Error("provider secret marker must not escape");
      options.onError?.(error);
      throw error;
    },
  });
  await harness.start();
  await harness.runCommand();
  assert.equal(harness.runtime.compacts.length, 1);
  assert.deepEqual(harness.runtime.branch, originalBranch);
  assert.equal(harness.transitions.at(-1).epoch_state, EPOCH_STATES.FAILED);
  assert.doesNotMatch(JSON.stringify(harness.notifications), /provider secret marker/iu);
  await harness.runCommand();
  assert.equal(harness.runtime.compacts.length, 1, "a failed epoch remains single-flight until recovery");
});

test("a concurrent command cannot open a second nonterminal epoch", async () => {
  let release;
  const gate = new Promise((resolve) => { release = resolve; });
  const harness = createHarness({ nativeDriver: async () => gate });
  await harness.start();
  const first = harness.runCommand();
  await new Promise((resolve) => setImmediate(resolve));
  await harness.runCommand();
  assert.equal(harness.runtime.compacts.length, 1);
  release();
  await first;
  assert.notEqual(harness.transitions.at(-1).mode, SESSION_MODES.BOUNDED_SUBAGENT);
});

test("only the active native summarizer bypasses the normal context-pressure abort", async () => {
  let abortsDuringSummary;
  const harness = createHarness({
    nativeDriver: async ({ emit, ctx, runtime }) => {
      const allowed = (await emit("session_before_compact", {
        type: "session_before_compact",
        preparation: preparation(runtime.branch),
        branchEntries: structuredClone(runtime.branch),
        signal: new AbortController().signal,
      }, ctx)).at(-1);
      assert.deepEqual(allowed, {});
      runtime.usage = { tokens: 16_384, contextWindow: 32_768 };
      const before = runtime.aborts;
      await emit("before_provider_request", { type: "before_provider_request", payload: {} }, ctx);
      abortsDuringSummary = runtime.aborts - before;
    },
  });
  await harness.start();
  await harness.runCommand();
  assert.equal(abortsDuringSummary, 0);
});
