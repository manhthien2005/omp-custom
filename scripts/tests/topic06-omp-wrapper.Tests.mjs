import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const core = await import(new URL("../../template/.omp/contracts/agent-boundary-core.mjs", import.meta.url));
const schema = await import(new URL("../../template/.omp/contracts/agent-boundary-schema.mjs", import.meta.url));
const wrapperUrl = new URL("../../template/.omp/extensions/agent-task-boundary.js", import.meta.url);

function withHash(value) {
  const projection = structuredClone(value);
  delete projection.projection_sha256;
  projection.projection_sha256 = core.sha256Canonical(projection).toUpperCase();
  return projection;
}

function projectionFor(workUnitId, options = {}) {
  const role = options.role ?? "worker";
  const worker = role === "worker";
  const reviewer = role === "reviewer";
  const output = `src/${workUnitId.toLowerCase()}.mjs`;
  return withHash({
    schema_version: 1,
    record_type: "work_unit_projection",
    task: {
      task_id: "T000001",
      status: reviewer ? "candidate_frozen" : "active",
      objective: "Implement and review the bounded routing change.",
      authority: ["user-approved-topic-06"],
      execution_mode: "mutating",
      write_scope: [{ kind: "subtree", path: "src" }],
      acceptance_criteria: [{ id: "AC-001", text: "The selected behavior is deterministic.", mandatory: true }],
      obligations: ["Preserve unrelated user changes."],
      owned_ignored_outputs: [],
    },
    work_unit: {
      work_unit_id: workUnitId,
      inputs: ["src/router.mjs"],
      outputs: worker ? [output] : [],
      ownership: worker ? [output] : [],
      dependencies: [],
      completion_conditions: [worker ? "Run verify-router." : reviewer ? "Review fallback identity." : "Return cited evidence."],
    },
    binding: {
      observation_worktree: "D:/fixture/repository",
      authoritative_worktree: "D:/fixture/repository",
      candidate_id: reviewer ? "C1" : null,
      candidate_sha256: reviewer ? "A".repeat(64) : null,
      diff_ref: reviewer ? "B".repeat(64) : null,
      artifact_refs: reviewer ? ["src/router.mjs"] : [],
    },
    cas: { revision: 4, revision_sha256: "C".repeat(64), lease_generation: 1 },
  });
}

function requestFor(workUnitId, options = {}) {
  const role = options.role ?? "worker";
  if (role === "cheap_scout") return {
    task_id: "T000001", work_unit_id: workUnitId, agent: "cheap-scout", role,
  };
  if (role === "reviewer") return {
    task_id: "T000001", work_unit_id: workUnitId, agent: "reviewer", role,
  };
  return {
    task_id: "T000001", work_unit_id: workUnitId, agent: "worker", role,
    effort: options.effort ?? "high", isolated: options.isolated ?? false,
  };
}

function semanticFor(agent, workUnitId) {
  if (agent === "cheap-scout") return {
    status: "completed",
    summary: "The selected producer and consumer were located.",
    capability: "native",
    source_fitness_reason: "Current source is sufficient.",
    fallback_path: [],
    claims: [{ claim: "The route is selected before dispatch.", sources: [{ path: "src/router.mjs", line_start: 1, line_end: 5 }] }],
    gaps: [],
    searches_performed: [{ method: "grep", query: "route", outcome: "Found the route." }],
    recommended_next_action: "Inspect the consumer.",
  };
  if (agent === "reviewer") return {
    decision: "APPROVED",
    summary: "The frozen candidate preserves exact route identity.",
    findings: [],
    cleared_concerns: [{ concern: "Fallback identity", evidence: "The exact route is checked at src/router.mjs:1." }],
    recommended_action: "ACCEPT",
  };
  const artifact = `src/${workUnitId.toLowerCase()}.mjs`;
  return {
    status: "completed",
    summary: "The bounded implementation and focused verification completed.",
    artifact_refs: [artifact],
    verification_observations: [{ command_id: "verify-router", status: "passed", observation: "Focused check passed." }],
    covered_ac_ids: ["AC-001"],
    blockers: [],
    remaining_risks: [],
  };
}

function fakeTypebox() {
  const Type = {
    String: (options = {}) => ({ type: "string", ...options }),
    Boolean: () => ({ type: "boolean" }),
    Literal: (value) => ({ const: value }),
    Optional: (value) => ({ ...value, optional: true }),
    Object: (properties, options = {}) => ({ type: "object", properties, ...options }),
    Array: (items, options = {}) => ({ type: "array", items, ...options }),
    Union: (anyOf) => ({ anyOf }),
  };
  return { Type };
}

function discovery(overrides = {}) {
  const definitions = {
    "cheap-scout": {
      name: "cheap-scout", source: "project", model: ["@cheap-scout"], thinkingLevel: "xhigh",
      blocking: true, spawns: [], tools: ["read", "grep", "glob", "web_search", "yield"], output: schema.SEMANTIC_OUTPUT_SCHEMAS.cheap_scout,
    },
    worker: {
      name: "worker", source: "project", model: ["@worker"], thinkingLevel: "high",
      blocking: true, spawns: [], tools: ["read", "grep", "glob", "edit", "write", "bash", "yield"], output: schema.SEMANTIC_OUTPUT_SCHEMAS.worker,
    },
    reviewer: {
      name: "reviewer", source: "project", model: ["@reviewer"], thinkingLevel: "xhigh",
      blocking: true, spawns: [], tools: ["read", "grep", "glob", "bash", "yield"], output: schema.SEMANTIC_OUTPUT_SCHEMAS.reviewer,
    },
  };
  for (const [name, patch] of Object.entries(overrides)) definitions[name] = { ...definitions[name], ...patch };
  return { projectAgentsDir: "D:/fixture/repository/.omp/agents", agents: Object.values(definitions) };
}

function runtime(overrides = {}) {
  return {
    schema_version: 2,
    record_type: "agent_boundary_runtime",
    target_omp: "D:/fixture/repository/.omp",
    paths: {
      pwsh: "C:/Program Files/PowerShell/7/pwsh.exe",
      state_cli: "D:/fixture/repository/.omp/state/agent-tasks.ps1",
    },
    capabilities: { batch: true, isolation: true, effort: true, max_effort: "xhigh", continuity: true },
    ...overrides,
  };
}

function nativeDetails(params, mutateResult) {
  const items = Array.isArray(params.tasks) ? params.tasks : [params];
  const projectAgentsDir = "D:/fixture/repository/.omp/agent-tasks";
  const results = items.map((item, index) => {
    const workUnitId = item.name.slice(item.name.indexOf("-") + 1);
    const agent = item.agent;
    const route = agent === "cheap-scout" ? {
      modelRole: "cheap-scout", resolvedModel: "omniroute/ds/deepseek-v4-flash:xhigh", resolvedModelIsFallback: false,
    } : agent === "reviewer" ? {
      modelRole: "reviewer", resolvedModel: "omniroute/codex/gpt-5.6-sol:xhigh", resolvedModelIsFallback: false,
    } : {
      modelRole: "worker", resolvedModel: `omniroute/codex/gpt-5.6-sol:${item.effort === "hi" ? "xhigh" : "high"}`,
      resolvedModelIsFallback: false,
    };
    const result = {
      index,
      id: `Agent-${index + 1}`,
      agent,
      agentSource: "project",
      task: item.task,
      exitCode: 0,
      output: "NATIVE_OUTPUT_MUST_NOT_LEAK",
      stderr: "",
      truncated: false,
      structuredOutput: { source: "agent", mode: "permissive", status: "valid", data: semanticFor(agent, workUnitId) },
      durationMs: 10,
      tokens: 100,
      requests: 2,
      outputPath: `${projectAgentsDir}/Agent-${index + 1}.md`,
      ...(item.isolated ? { patchPath: `${projectAgentsDir}/Agent-${index + 1}.patch` } : {}),
      ...route,
    };
    return mutateResult ? mutateResult(result, index, item) : result;
  });
  return { projectAgentsDir, results, totalDurationMs: 10 };
}

function createHarness(wrapper, options = {}) {
  const projections = new Map();
  for (const item of options.items ?? [requestFor("WU-1")]) {
    projections.set(item.work_unit_id, projectionFor(item.work_unit_id, { role: item.role }));
  }
  const stateCalls = [];
  const nativeCalls = [];
  let revision = 4;
  let revisionSha = "C".repeat(64);
  const invokeState = async (operation, request) => {
    stateCalls.push({ operation, request: structuredClone(request) });
    if (options.stateFailure === operation) return { ok: false, code: "AT-TEST", data: { message: "state failed" } };
    if (operation === "project-work-unit") return { ok: true, code: "AT-OK", data: structuredClone(projections.get(request.work_unit_id)) };
    assert.equal(operation, "record-work-unit-outcome");
    assert.equal(request.expected_revision, revision);
    assert.equal(request.expected_revision_sha256, revisionSha);
    revision += 1;
    revisionSha = String(revision).padStart(64, "D");
    return { ok: true, code: "AT-OK", data: { task_id: request.task_id, work_unit_id: request.work_unit_id, revision, revision_sha256: revisionSha } };
  };
  const pi = { typebox: fakeTypebox(), cwd: "D:/fixture/repository" };
  const tool = wrapper.createManagedTaskTool(pi, runtime(options.runtime), discovery(options.agentOverrides), {
    invokeState,
    artifactExists: options.artifactExists ?? (() => true),
    consumeContextPressureAbort: options.consumeContextPressureAbort,
  });
  const context = {
    cwd: "D:/fixture/repository",
    sessionManager: {
      getBranch: () => options.modeEntries ?? [],
      getSessionId: () => "session-1",
    },
    invokeTool: async (params) => {
      nativeCalls.push(structuredClone(params));
      if (options.nativeFailure) return { content: [{ type: "text", text: "provider diagnostic" }], isError: true };
      return {
        content: [{ type: "text", text: "native prose" }],
        details: nativeDetails(params, options.mutateResult),
        isError: false,
      };
    },
  };
  return { tool, context, stateCalls, nativeCalls };
}

test("wrapper module exports the trusted same-name task adapter seams", async () => {
  const wrapper = await import(wrapperUrl);
  assert.equal(typeof wrapper.loadManagedRuntime, "function");
  assert.equal(typeof wrapper.deriveActiveMode, "function");
  assert.equal(typeof wrapper.buildNativeTaskParams, "function");
  assert.equal(typeof wrapper.parseStateEnvelope, "function");
  assert.equal(typeof wrapper.createManagedTaskTool, "function");
});

test("mode derivation uses the last valid mode change and rejects malformed mode entries", async () => {
  const wrapper = await import(wrapperUrl);
  assert.deepEqual(wrapper.deriveActiveMode([]), { ok: true, mode: "none" });
  assert.deepEqual(wrapper.deriveActiveMode([
    { type: "mode_change", mode: "plan" }, { type: "message", text: "ignored" }, { type: "mode_change", mode: "goal" },
  ]), { ok: true, mode: "goal" });
  assert.equal(wrapper.deriveActiveMode([{ type: "mode_change", mode: "unsafe" }]).reason_code, "plan_mode_incompatible");
});

test("native parameter translation is canonical and never forwards schema/model/context controls", async () => {
  const wrapper = await import(wrapperUrl);
  const high = requestFor("WU-1", { isolated: true });
  const xhigh = requestFor("WU-2", { effort: "xhigh" });
  const highPacket = core.composeAgentPacket({ request: high, projection: projectionFor("WU-1") });
  const xhighPacket = core.composeAgentPacket({ request: xhigh, projection: projectionFor("WU-2") });
  const single = wrapper.buildNativeTaskParams([{ request: high, composed: highPacket }]);
  assert.deepEqual(single, { name: "worker-WU-1", agent: "worker", task: highPacket.canonical, isolated: true });
  const batch = wrapper.buildNativeTaskParams([
    { request: high, composed: highPacket }, { request: xhigh, composed: xhighPacket },
  ]);
  assert.equal(batch.context, wrapper.MANAGED_BATCH_CONTEXT);
  assert.deepEqual(batch.tasks, [
    { name: "worker-WU-1", agent: "worker", task: highPacket.canonical, isolated: true },
    { name: "worker-WU-2", agent: "worker", task: xhighPacket.canonical, effort: "hi" },
  ]);
  assert.doesNotMatch(JSON.stringify(batch), /outputSchema|schemaMode|resolvedModel|modelRole/iu);
});

test("state output parser accepts one closed line and rejects duplicate/extra/multiple records", async () => {
  const wrapper = await import(wrapperUrl);
  const good = '{"code":"AT-OK","data":{"value":1},"ok":true,"operation":"project-work-unit"}\n';
  assert.deepEqual(wrapper.parseStateEnvelope(good), { code: "AT-OK", data: { value: 1 }, ok: true, operation: "project-work-unit" });
  for (const text of [
    `${good}${good}`,
    '{"code":"AT-OK","code":"AT-OTHER","data":{},"ok":true,"operation":"x"}',
    '{"code":"AT-OK","data":{},"ok":true,"operation":"x","extra":true}',
  ]) assert.throws(() => wrapper.parseStateEnvelope(text), /state_unavailable/);
});

test("agent discovery reconciliation rejects async, nested, wrong-route, tool, and schema drift", async () => {
  const wrapper = await import(wrapperUrl);
  for (const overrides of [
    { worker: { blocking: false } },
    { worker: { spawns: ["cheap-scout"] } },
    { worker: { model: ["@reviewer"] } },
    { worker: { tools: ["read"] } },
    { worker: { tools: ["read", "grep", "glob", "edit", "write", "bash"] } },
    { worker: { output: schema.SEMANTIC_OUTPUT_SCHEMAS.reviewer } },
  ]) {
    assert.throws(() => wrapper.createManagedTaskTool(
      { typebox: fakeTypebox(), cwd: "D:/fixture/repository" }, runtime(), discovery(overrides), { invokeState: async () => ({ ok: false }) },
    ), /managed_component_unavailable/);
  }
});

test("invalid input, projection failure, role mismatch, plan mutation, and isolation mismatch make zero native calls", async () => {
  const wrapper = await import(wrapperUrl);
  const invalid = createHarness(wrapper);
  let result = await invalid.tool.execute("call", { task_id: "bad" }, undefined, undefined, invalid.context);
  assert.equal(result.isError, true);
  assert.equal(invalid.nativeCalls.length, 0);

  const stateFailure = createHarness(wrapper, { stateFailure: "project-work-unit" });
  result = await stateFailure.tool.execute("call", requestFor("WU-1"), undefined, undefined, stateFailure.context);
  assert.equal(result.details.reason_code, "state_unavailable");
  assert.equal(stateFailure.nativeCalls.length, 0);

  const roleMismatch = createHarness(wrapper);
  result = await roleMismatch.tool.execute("call", { ...requestFor("WU-1"), agent: "reviewer" }, undefined, undefined, roleMismatch.context);
  assert.equal(result.details.reason_code, "work_unit_incompatible");
  assert.equal(roleMismatch.nativeCalls.length, 0);

  const plan = createHarness(wrapper, { modeEntries: [{ type: "mode_change", mode: "plan" }] });
  result = await plan.tool.execute("call", requestFor("WU-1"), undefined, undefined, plan.context);
  assert.equal(result.details.reason_code, "plan_mode_incompatible");
  assert.equal(plan.nativeCalls.length, 0);

  const isolation = createHarness(wrapper, { runtime: { capabilities: { batch: true, isolation: false, effort: true, max_effort: "xhigh", continuity: true } } });
  result = await isolation.tool.execute("call", requestFor("WU-1", { isolated: true }), undefined, undefined, isolation.context);
  assert.equal(result.details.reason_code, "isolation_unavailable");
  assert.equal(isolation.nativeCalls.length, 0);
});

test("one invalid batch item prevents the entire native batch from starting", async () => {
  const wrapper = await import(wrapperUrl);
  const items = [requestFor("WU-1"), requestFor("WU-2")];
  const harness = createHarness(wrapper, { items });
  const result = await harness.tool.execute("call", {
    tasks: [items[0], { ...items[1], work_unit_id: "WU-1" }],
  }, undefined, undefined, harness.context);
  assert.equal(result.isError, true);
  assert.equal(harness.nativeCalls.length, 0);
  assert.equal(harness.stateCalls.length, 0);
});

test("valid single delegates once, reprojects, records one provisional outcome, and returns no native prose", async () => {
  const wrapper = await import(wrapperUrl);
  const item = requestFor("WU-1", { isolated: true });
  const harness = createHarness(wrapper, { items: [item] });
  const result = await harness.tool.execute("call", item, undefined, undefined, harness.context);
  assert.equal(harness.nativeCalls.length, 1);
  assert.deepEqual(Object.keys(harness.nativeCalls[0]).sort(), ["agent", "isolated", "name", "task"]);
  assert.deepEqual(harness.stateCalls.map((call) => call.operation), [
    "project-work-unit", "project-work-unit", "record-work-unit-outcome",
  ]);
  assert.equal(result.isError, false);
  assert.equal(result.details.managed, true);
  assert.equal(result.details.batch, false);
  assert.equal(result.details.status, "completed");
  assert.equal(result.details.receipts[0].outcome.recorded, true);
  assert.doesNotMatch(JSON.stringify(result), /NATIVE_OUTPUT|native prose|session-1|task_id|projection_sha256/iu);
});

test("a child context-pressure marker converts an aborted native result into an unsuccessful receipt without recording outcome", async () => {
  const harness = createHarness(await import(wrapperUrl), {
    mutateResult: (result) => ({ ...result, aborted: true, abortReason: "signal" }),
    consumeContextPressureAbort: () => "T07_CONTEXT_PRESSURE_ABORT",
  });
  const result = await harness.tool.execute("call", requestFor("WU-1"), undefined, undefined, harness.context);
  assert.equal(result.isError, true);
  assert.equal(result.details.reason_code, "context_pressure");
  assert.equal(result.details.receipts[0].status, "failed");
  assert.equal(result.details.receipts[0].outcome.recorded, false);
  assert.equal(harness.stateCalls.filter((call) => call.operation === "record-work-unit-outcome").length, 0);
});

test("valid batch delegates once and records outcomes in input order with chained CAS", async () => {
  const wrapper = await import(wrapperUrl);
  const items = [requestFor("WU-1"), requestFor("WU-2", { effort: "xhigh" })];
  const harness = createHarness(wrapper, { items });
  const result = await harness.tool.execute("call", { tasks: items }, undefined, undefined, harness.context);
  assert.equal(harness.nativeCalls.length, 1);
  assert.equal(Array.isArray(harness.nativeCalls[0].tasks), true);
  const records = harness.stateCalls.filter((call) => call.operation === "record-work-unit-outcome");
  assert.deepEqual(records.map((call) => call.request.work_unit_id), ["WU-1", "WU-2"]);
  assert.deepEqual(records.map((call) => call.request.expected_revision), [4, 5]);
  assert.equal(result.isError, false);
  assert.equal(result.details.batch, true);
  assert.equal(result.details.receipts.every((receipt) => receipt.outcome.recorded), true);
});

test("one invalid native result fails the batch barrier before any outcome record", async () => {
  const wrapper = await import(wrapperUrl);
  const items = [requestFor("WU-1"), requestFor("WU-2")];
  const harness = createHarness(wrapper, {
    items,
    mutateResult: (result, index) => index === 1 ? { ...result, resolvedModel: "omniroute/codex/gpt-5.6-terra:high" } : result,
  });
  const result = await harness.tool.execute("call", { tasks: items }, undefined, undefined, harness.context);
  assert.equal(harness.nativeCalls.length, 1);
  assert.equal(harness.stateCalls.filter((call) => call.operation === "record-work-unit-outcome").length, 0);
  assert.equal(result.isError, true);
  assert.equal(result.details.reason_code, "model_identity_mismatch");
});

test("an outcome CAS refusal stays provisional after the one native call", async () => {
  const wrapper = await import(wrapperUrl);
  const harness = createHarness(wrapper, { stateFailure: "record-work-unit-outcome" });
  const result = await harness.tool.execute(
    "call",
    requestFor("WU-1"),
    undefined,
    undefined,
    harness.context,
  );
  assert.equal(harness.nativeCalls.length, 1);
  assert.equal(result.isError, true);
  assert.equal(result.details.reason_code, "outcome_record_failed");
  assert.equal(result.details.receipts[0].status, "failed");
  assert.equal(result.details.receipts[0].outcome.recorded, false);
});

test("native shape refusal and unsafe artifact evidence return bounded failures", async () => {
  const wrapper = await import(wrapperUrl);
  const nativeFailure = createHarness(wrapper, { nativeFailure: true });
  let result = await nativeFailure.tool.execute("call", requestFor("WU-1"), undefined, undefined, nativeFailure.context);
  assert.equal(result.details.reason_code, "native_task_failed");
  assert.doesNotMatch(JSON.stringify(result), /provider diagnostic/iu);

  const artifact = createHarness(wrapper, {
    mutateResult: (native) => ({ ...native, outputPath: "D:/outside/Agent-1.md" }),
  });
  result = await artifact.tool.execute("call", requestFor("WU-1"), undefined, undefined, artifact.context);
  assert.equal(result.details.reason_code, "artifact_stale");
  assert.equal(artifact.stateCalls.filter((call) => call.operation === "record-work-unit-outcome").length, 0);
});

test("loadManagedRuntime refuses a missing generated runtime record", async () => {
  const wrapper = await import(wrapperUrl);
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "topic06-wrapper-load-"));
  try {
    const modulePath = path.join(root, ".omp", "extensions", "agent-task-boundary.js");
    fs.mkdirSync(path.dirname(modulePath), { recursive: true });
    fs.writeFileSync(modulePath, "fixture", "utf8");
    await assert.rejects(() => wrapper.loadManagedRuntime(new URL(`file:///${modulePath.replaceAll("\\", "/")}`)), /managed_component_unavailable/);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test("pinned OMP source retains every trusted wrapper seam", () => {
  const upstream = fileURLToPath(new URL("../../_research/upstreams/oh-my-pi/", import.meta.url));
  const head = spawnSync("git", ["-C", upstream, "rev-parse", "HEAD"], { encoding: "utf8" });
  const status = spawnSync("git", ["-C", upstream, "status", "--short"], { encoding: "utf8" });
  assert.equal(head.status, 0);
  assert.equal(head.stdout.trim(), "3a8591a8af5b6d200088d12ca75a5517cb064fa8");
  assert.equal(status.status, 0);
  assert.equal(status.stdout, "");

  const read = (relative) => fs.readFileSync(path.join(upstream, relative), "utf8");
  const runner = read("packages/coding-agent/src/extensibility/extensions/runner.ts");
  assert.match(runner, /same-tool `ctx\.invokeTool`/u);
  assert.match(runner, /Calls the unwrapped native `execute` directly/u);
  assert.match(runner, /catch \(err\)[\s\S]{0,500}return undefined;/u);

  const types = read("packages/coding-agent/src/task/types.ts");
  for (const field of [
    "agentSource", "structuredOutput", "requests", "modelRole", "resolvedModel",
    "resolvedModelIsFallback", "outputPath", "patchPath", "branchName", "branchBaseSha", "nestedPatches",
  ]) assert.match(types, new RegExp(`\\b${field}\\??:`, "u"));

  const structured = read("packages/coding-agent/src/task/structured-subagent.ts");
  assert.match(structured, /function createPlanModeAgent[\s\S]{0,500}tools,[\s\S]{0,250}spawns: undefined,[\s\S]{0,100}prewalk: undefined/u);

  const main = read("packages/coding-agent/src/main.ts");
  assert.match(main, /Trusted extension paths are an exact allowlist/u);
  assert.match(main, /options\.disableExtensionDiscovery = true/u);
  assert.match(main, /Trusted extension failed to load/u);

  const settings = read("packages/coding-agent/src/config/settings.ts");
  assert.match(settings, /for \(const filePath of this\.#configFiles\)[\s\S]{0,250}this\.#deepMerge\(merged, overlay\)/u);

  const executor = read("packages/coding-agent/src/task/executor.ts");
  assert.match(executor, /At 1\.5x the budget the free-running turn is stopped/u);
  assert.match(executor, /Math\.ceil\(budget \* 1\.5\)/u);
});
