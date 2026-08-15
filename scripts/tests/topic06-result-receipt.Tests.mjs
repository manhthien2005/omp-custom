import assert from "node:assert/strict";
import test from "node:test";

const core = await import(new URL("../../template/.omp/contracts/agent-boundary-core.mjs", import.meta.url));

function withProjectionHash(value) {
  const projection = structuredClone(value);
  delete projection.projection_sha256;
  projection.projection_sha256 = core.sha256Canonical(projection).toUpperCase();
  return projection;
}

function projectionFor(role, overrides = {}) {
  const reviewer = role === "reviewer";
  const scout = role === "cheap_scout";
  const base = {
    schema_version: 1,
    record_type: "work_unit_projection",
    task: {
      task_id: "T000001",
      status: reviewer ? "candidate_frozen" : "active",
      objective: scout ? "Find the routing producer and consumers." : reviewer ?
        "Review the frozen routing candidate." : "Implement the bounded routing change.",
      authority: ["user-approved-topic-06"],
      execution_mode: scout ? "read_only" : "mutating",
      write_scope: scout ? [] : [{ kind: "subtree", path: "src" }],
      acceptance_criteria: [
        { id: "AC-002", text: "The selected behavior is deterministic.", mandatory: true },
        { id: "AC-001", text: "Unrelated bytes remain unchanged.", mandatory: true },
      ],
      obligations: ["Preserve unrelated user changes."],
      owned_ignored_outputs: [],
    },
    work_unit: {
      work_unit_id: scout ? "WU-SCOUT-001" : reviewer ? "WU-REVIEW-001" : "WU-WORKER-001",
      inputs: ["src/router.mjs"],
      outputs: scout ? [] : ["src/router.mjs"],
      ownership: role === "worker" ? ["src/router.mjs"] : [],
      dependencies: [],
      completion_conditions: reviewer ? ["Check exact route identity."] : scout ?
        ["Return current-source citations."] : ["Run verify-router."],
    },
    binding: {
      observation_worktree: "D:/fixture/repository",
      authoritative_worktree: scout ? null : "D:/fixture/repository",
      candidate_id: reviewer ? "C1" : null,
      candidate_sha256: reviewer ? "A".repeat(64) : null,
      diff_ref: reviewer ? "B".repeat(64) : null,
      artifact_refs: reviewer ? ["src/router.mjs"] : [],
    },
    cas: { revision: 4, revision_sha256: "C".repeat(64), lease_generation: 1 },
  };
  return withProjectionHash({
    ...base,
    ...overrides,
    task: { ...base.task, ...(overrides.task ?? {}) },
    work_unit: { ...base.work_unit, ...(overrides.work_unit ?? {}) },
    binding: { ...base.binding, ...(overrides.binding ?? {}) },
    cas: { ...base.cas, ...(overrides.cas ?? {}) },
  });
}

function requestFor(role, overrides = {}) {
  const request = role === "cheap_scout" ? {
    task_id: "T000001", work_unit_id: "WU-SCOUT-001", agent: "cheap-scout", role,
  } : role === "reviewer" ? {
    task_id: "T000001", work_unit_id: "WU-REVIEW-001", agent: "reviewer", role,
  } : {
    task_id: "T000001", work_unit_id: "WU-WORKER-001", agent: "worker", role,
    effort: "high", isolated: true,
  };
  return { ...request, ...overrides };
}

function scoutSemantic(status = "completed") {
  return {
    status,
    summary: `Scout returned a ${status} bounded retrieval result.`,
    capability: "native",
    source_fitness_reason: "Current source is sufficient.",
    fallback_path: [],
    claims: status === "completed" ? [{
      claim: "The policy module selects the route.",
      sources: [{ path: "src/router.mjs", line_start: 10, line_end: 18 }],
    }] : [],
    gaps: status === "partial" ? ["One consumer remains unresolved."] : [],
    searches_performed: [{ method: "grep", query: "selectRoute", outcome: "Found the producer." }],
    recommended_next_action: "Inspect the selected consumer.",
  };
}

function workerSemantic(status = "completed", artifactRefs = ["src/router.mjs"]) {
  return {
    status,
    summary: `Worker returned a ${status} bounded implementation result.`,
    artifact_refs: artifactRefs,
    verification_observations: status === "completed" ?
      [{ command_id: "verify-router", status: "passed", observation: "Focused check passed." }] :
      [{ command_id: "verify-router", status: "not_run", observation: "Verification did not complete." }],
    covered_ac_ids: status === "completed" ? ["AC-002", "AC-001"] : [],
    blockers: status === "blocked" ? ["A required dependency is unavailable."] : [],
    remaining_risks: status === "partial" ? ["The remaining branch is unverified."] : [],
  };
}

function reviewerSemantic(decision = "APPROVED") {
  if (decision === "CHANGES_REQUESTED") {
    return {
      decision,
      summary: "The review completed and found one blocking issue.",
      findings: [{
        severity: "important",
        title: "Fallback route bypass",
        location: "src/router.mjs:10",
        trigger: "The primary route is unavailable.",
        impact: "An unauthorized model can settle.",
        violated_contract: "Only the selected route may settle.",
        evidence: "The fallback branch skips exact identity comparison.",
      }],
      cleared_concerns: [],
      recommended_action: "REWORK_BLOCKING",
    };
  }
  return {
    decision,
    summary: "The frozen candidate preserves the selected route boundary.",
    findings: [],
    cleared_concerns: [{ concern: "Unauthorized fallback", evidence: "The exact route is compared at src/router.mjs:10." }],
    recommended_action: "ACCEPT",
  };
}

function expectedRoute(role, request, fallback = false) {
  if (role === "cheap_scout") return {
    modelRole: "cheap-scout",
    resolvedModel: fallback ? "omniroute/ds/deepseek-v4-pro:xhigh" : "omniroute/ds/deepseek-v4-flash:xhigh",
    resolvedModelIsFallback: fallback,
  };
  const effort = role === "reviewer" ? "xhigh" : request.effort;
  return {
    modelRole: role,
    resolvedModel: `omniroute/codex/gpt-5.6-sol:${effort}`,
    resolvedModelIsFallback: false,
  };
}

function receiptCase(role, options = {}) {
  const request = requestFor(role, options.request);
  const projectionBefore = projectionFor(role, options.projectionBefore);
  const projectionAfter = options.projectionAfter ?? structuredClone(projectionBefore);
  const composed = core.composeAgentPacket({ request, projection: projectionBefore });
  assert.equal(composed.ok, true);
  const semantic = options.semantic ?? (role === "cheap_scout" ? scoutSemantic() :
    role === "worker" ? workerSemantic() : reviewerSemantic());
  const route = expectedRoute(role, request, options.fallback === true);
  const result = {
    index: options.index ?? 0,
    id: "Agent-1",
    agent: request.agent,
    agentSource: "project",
    task: composed.canonical,
    exitCode: 0,
    output: "TOP_SECRET_NATIVE_PROSE_MUST_NOT_LEAK",
    stderr: "",
    truncated: false,
    structuredOutput: { source: "agent", mode: "permissive", status: "valid", data: semantic },
    durationMs: 10,
    tokens: 100,
    requests: 2,
    ...route,
    ...(options.result ?? {}),
  };
  const nativeDetails = options.nativeDetails ?? {
    projectAgentsDir: "D:/fixture/repository/.omp/agent-tasks",
    results: [result],
    totalDurationMs: 10,
  };
  return {
    input: {
      request,
      projection_before: projectionBefore,
      projection_after: projectionAfter,
      index: options.expectedIndex ?? 0,
      expected_count: options.expectedCount ?? 1,
      native_details: nativeDetails,
    },
    request,
    projectionBefore,
    result,
  };
}

function assertFailedReceipt(result, reasonCode) {
  assert.equal(result.ok, false);
  assert.equal(result.reason_code, reasonCode);
  assert.deepEqual(Object.keys(result).sort(), ["message", "ok", "reason_code", "receipt"]);
  assert.deepEqual(Object.keys(result.receipt).sort(), [
    "outcome", "reason_code", "record_type", "role", "runtime", "schema_version", "semantic_result", "status",
  ]);
  assert.equal(result.receipt.status, "failed");
  assert.equal(result.receipt.reason_code, reasonCode);
  assert.equal(result.receipt.outcome.recorded, false);
  assert.equal(result.receipt.outcome.status, "failed");
  assert.deepEqual(result.receipt.outcome.artifact_refs, []);
  assert.equal(result.receipt.runtime.forced_partial, reasonCode === "forced_partial");
  assert.doesNotMatch(JSON.stringify(result), /TOP_SECRET_NATIVE_PROSE|provider diagnostic|native stderr/u);
}

test("valid primary/fallback Scout, high/xhigh Worker, and Reviewer identities produce closed receipts", () => {
  const cases = [
    receiptCase("cheap_scout"),
    receiptCase("cheap_scout", { fallback: true }),
    receiptCase("worker"),
    receiptCase("worker", { request: { effort: "xhigh" } }),
    receiptCase("reviewer"),
  ];
  for (const fixture of cases) {
    const normalized = core.normalizeBoundaryReceipt(fixture.input);
    assert.equal(normalized.ok, true);
    assert.deepEqual(Object.keys(normalized).sort(), ["ok", "receipt"]);
    assert.deepEqual(Object.keys(normalized.receipt).sort(), [
      "outcome", "reason_code", "record_type", "role", "runtime", "schema_version", "semantic_result", "status",
    ]);
    assert.equal(normalized.receipt.schema_version, 1);
    assert.equal(normalized.receipt.record_type, "agent_boundary_receipt");
    assert.equal(normalized.receipt.reason_code, "ok");
    assert.equal(normalized.receipt.runtime.structured_output, "valid");
    assert.equal(normalized.receipt.runtime.aborted, false);
    assert.equal(normalized.receipt.runtime.forced_partial, false);
    assert.equal(normalized.receipt.runtime.omniroute_upstream, "not_observed");
    assert.equal(normalized.receipt.outcome.recorded, false);
    assert.doesNotMatch(JSON.stringify(normalized), /TOP_SECRET_NATIVE_PROSE|projectAgentsDir|task_id|projection_sha256/iu);
  }
  assert.equal(core.normalizeBoundaryReceipt(cases[0].input).receipt.runtime.fallback_used, false);
  assert.equal(core.normalizeBoundaryReceipt(cases[1].input).receipt.runtime.fallback_used, true);
  assert.equal(core.normalizeBoundaryReceipt(cases[2].input).receipt.runtime.effort, "high");
  assert.equal(core.normalizeBoundaryReceipt(cases[3].input).receipt.runtime.effort, "xhigh");
  assert.equal(core.normalizeBoundaryReceipt(cases[4].input).receipt.runtime.effort, "xhigh");
});

test("valid semantic partial, blocked, failed, and blocking-review results remain provisional", () => {
  for (const status of ["partial", "blocked", "failed"]) {
    const scout = core.normalizeBoundaryReceipt(receiptCase("cheap_scout", { semantic: scoutSemantic(status) }).input);
    assert.equal(scout.ok, true);
    assert.equal(scout.receipt.status, status);
    assert.equal(core.toProvisionalOutcome(scout.receipt).status, status);

    const worker = core.normalizeBoundaryReceipt(receiptCase("worker", { semantic: workerSemantic(status, []) }).input);
    assert.equal(worker.ok, true);
    assert.equal(worker.receipt.status, status);
    assert.equal(core.toProvisionalOutcome(worker.receipt).status, status);
  }
  const review = core.normalizeBoundaryReceipt(receiptCase("reviewer", {
    semantic: reviewerSemantic("CHANGES_REQUESTED"),
  }).input);
  assert.equal(review.ok, true);
  assert.equal(review.receipt.status, "completed");
  assert.equal(core.toProvisionalOutcome(review.receipt).status, "completed");
});

test("missing, asynchronous, duplicate, or mismatched native settlement fails closed", () => {
  const base = receiptCase("worker");
  const duplicate = structuredClone(base.input.native_details);
  duplicate.results = [structuredClone(base.result), { ...structuredClone(base.result), id: "Agent-2" }];
  const cases = [
    [null, "result_unsettled", {}],
    [{ ...structuredClone(base.input.native_details), async: { state: "completed", jobId: "J1", type: "task" } }, "unsupported_async", {}],
    [{ ...structuredClone(base.input.native_details), results: [] }, "result_unsettled", {}],
    [duplicate, "result_unsettled", { expected_count: 2 }],
    [{ ...structuredClone(base.input.native_details), results: [{ ...structuredClone(base.result), index: 1 }] }, "result_unsettled", {}],
    [{ ...structuredClone(base.input.native_details), results: [{ ...structuredClone(base.result), agent: "reviewer" }] }, "result_unsettled", {}],
    [{ ...structuredClone(base.input.native_details), results: [{ ...structuredClone(base.result), task: "different" }] }, "result_unsettled", {}],
  ];
  for (const [nativeDetails, reason, inputOverrides] of cases) {
    assertFailedReceipt(core.normalizeBoundaryReceipt({
      ...structuredClone(base.input), ...inputOverrides, native_details: nativeDetails,
    }), reason);
  }
});

test("native failure, cancellation, retry failure, and truncation never become successful receipts", () => {
  const mutations = [
    [{ exitCode: 1, error: "provider diagnostic" }, "native_task_failed"],
    [{ stderr: "native stderr" }, "native_task_failed"],
    [{ aborted: true, abortReason: "cancelled" }, "cancelled"],
    [{ retryFailure: { attempt: 3, errorMessage: "provider diagnostic" } }, "native_task_failed"],
    [{ truncated: true }, "result_unsettled"],
  ];
  for (const [mutation, reason] of mutations) {
    assertFailedReceipt(core.normalizeBoundaryReceipt(receiptCase("worker", { result: mutation }).input), reason);
  }
});

test("the exact Topic 07 pressure marker plus native abort becomes a non-completed context-pressure receipt", () => {
  const pressure = core.normalizeBoundaryReceipt(receiptCase("worker", {
    result: {
      topic07AbortMarker: "T07_CONTEXT_PRESSURE_ABORT",
      aborted: true,
      abortReason: "signal",
    },
  }).input);
  assertFailedReceipt(pressure, "context_pressure");
  assert.equal(pressure.receipt.runtime.aborted, true);
  assert.equal(core.toProvisionalOutcome(pressure.receipt), null);

  assertFailedReceipt(core.normalizeBoundaryReceipt(receiptCase("worker", {
    result: { topic07AbortMarker: "T07_CONTEXT_PRESSURE_ABORT" },
  }).input), "result_unsettled");
  assertFailedReceipt(core.normalizeBoundaryReceipt(receiptCase("worker", {
    result: { topic07AbortMarker: "T07_CONTEXT_PRESSURE_ABORT_TAMPERED", aborted: true },
  }).input), "cancelled");
});

test("structured output source/status/data and the forced-partial request threshold are fail closed", () => {
  const malformed = workerSemantic();
  malformed.extra = true;
  const mutations = [
    [{ structuredOutput: undefined }, "structured_output_invalid"],
    [{ structuredOutput: { source: "caller", mode: "strict", status: "valid", data: workerSemantic() } }, "structured_output_invalid"],
    [{ structuredOutput: { source: "agent", mode: "permissive", status: "unavailable", data: workerSemantic() } }, "structured_output_invalid"],
    [{ structuredOutput: { source: "agent", mode: "permissive", status: "invalid", data: workerSemantic() } }, "structured_output_invalid"],
    [{ structuredOutput: { source: "agent", mode: "permissive", status: "valid", data: malformed } }, "structured_output_invalid"],
    [{ requests: 300 }, "forced_partial"],
  ];
  for (const [mutation, reason] of mutations) {
    assertFailedReceipt(core.normalizeBoundaryReceipt(receiptCase("worker", { result: mutation }).input), reason);
  }
  const below = core.normalizeBoundaryReceipt(receiptCase("worker", { result: { requests: 299 } }).input);
  assert.equal(below.ok, true);
});

test("model role, exact model, effort, and availability fallback policy are enforced independently", () => {
  const cases = [
    [receiptCase("worker", { result: { modelRole: "reviewer" } }).input, "model_identity_mismatch"],
    [receiptCase("worker", { result: { resolvedModel: "omniroute/codex/gpt-5.6-terra:high", resolvedModelIsFallback: false } }).input, "model_identity_mismatch"],
    [receiptCase("worker", { request: { effort: "xhigh" }, result: { resolvedModel: "omniroute/codex/gpt-5.6-sol:high" } }).input, "effort_mismatch"],
    [receiptCase("worker", { result: { resolvedModelIsFallback: true } }).input, "fallback_not_allowed"],
    [receiptCase("reviewer", { result: { resolvedModelIsFallback: true } }).input, "fallback_not_allowed"],
    [receiptCase("cheap_scout", { result: { resolvedModel: "omniroute/ds/deepseek-v4-pro:xhigh", resolvedModelIsFallback: false } }).input, "fallback_not_allowed"],
    [receiptCase("cheap_scout", { fallback: true, result: { resolvedModel: "omniroute/ds/deepseek-v4-flash:xhigh" } }).input, "fallback_not_allowed"],
    [receiptCase("cheap_scout", { result: { resolvedModel: "omniroute/codex/gpt-5.6-sol:xhigh", resolvedModelIsFallback: false } }).input, "model_identity_mismatch"],
  ];
  for (const [input, reason] of cases) assertFailedReceipt(core.normalizeBoundaryReceipt(input), reason);
});

test("post-run projection, candidate, diff, and Worker artifact bindings must remain exact", () => {
  const workerBase = receiptCase("worker");
  const casChanged = withProjectionHash({
    ...structuredClone(workerBase.projectionBefore),
    cas: { ...workerBase.projectionBefore.cas, revision: 5 },
  });
  assertFailedReceipt(core.normalizeBoundaryReceipt({
    ...structuredClone(workerBase.input), projection_after: casChanged,
  }), "candidate_drift");

  const reviewerBase = receiptCase("reviewer");
  for (const binding of [
    { candidate_id: "C2", candidate_sha256: "D".repeat(64) },
    { diff_ref: "E".repeat(64) },
    { artifact_refs: ["src/other.mjs"] },
  ]) {
    const changed = withProjectionHash({
      ...structuredClone(reviewerBase.projectionBefore),
      binding: { ...reviewerBase.projectionBefore.binding, ...binding },
    });
    assertFailedReceipt(core.normalizeBoundaryReceipt({
      ...structuredClone(reviewerBase.input), projection_after: changed,
    }), "artifact_stale");
  }

  assertFailedReceipt(core.normalizeBoundaryReceipt(receiptCase("worker", {
    semantic: workerSemantic("completed", []),
  }).input), "artifact_stale");
  assertFailedReceipt(core.normalizeBoundaryReceipt(receiptCase("worker", {
    semantic: workerSemantic("completed", ["docs/outside.md"]),
  }).input), "artifact_stale");
});

test("every load-bearing projection mutation returns its named non-completed receipt", () => {
  const base = receiptCase("worker");
  const mutations = [
    ["work-unit ownership", (value) => { value.work_unit.ownership = ["src"]; }],
    ["work-unit outputs", (value) => { value.work_unit.outputs = ["src/other.mjs"]; }],
    ["acceptance list", (value) => { value.task.acceptance_criteria[0].text = "Changed after dispatch."; }],
    ["task status", (value) => { value.task.status = "partial"; }],
    ["revision", (value) => { value.cas.revision += 1; }],
    ["revision hash", (value) => { value.cas.revision_sha256 = "D".repeat(64); }],
    ["lease generation", (value) => { value.cas.lease_generation += 1; }],
    ["observation worktree", (value) => { value.binding.observation_worktree = "D:/fixture/other"; }],
    ["authoritative worktree", (value) => { value.binding.authoritative_worktree = "D:/fixture/other"; }],
  ];
  for (const [name, mutate] of mutations) {
    const changed = structuredClone(base.projectionBefore);
    mutate(changed);
    const result = core.normalizeBoundaryReceipt({
      ...structuredClone(base.input),
      projection_after: withProjectionHash(changed),
    });
    assertFailedReceipt(result, "candidate_drift");
    assert.notEqual(result.receipt.status, "completed", name);
  }

  assertFailedReceipt(core.normalizeBoundaryReceipt(receiptCase("worker", {
    result: { requests: -1 },
  }).input), "result_unsettled");
});

test("provisional outcome mapping uses only validated semantic content and never accepts a failed receipt", () => {
  const worker = core.normalizeBoundaryReceipt(receiptCase("worker").input);
  assert.equal(worker.ok, true);
  assert.deepEqual(core.toProvisionalOutcome(worker.receipt), {
    status: "completed",
    artifact_refs: ["src/router.mjs"],
    observed_summary: {
      role: "worker",
      status: "completed",
      summary: "Worker returned a completed bounded implementation result.",
    },
  });

  const reviewer = core.normalizeBoundaryReceipt(receiptCase("reviewer", {
    semantic: reviewerSemantic("CHANGES_REQUESTED"),
  }).input);
  assert.deepEqual(core.toProvisionalOutcome(reviewer.receipt), {
    status: "completed",
    artifact_refs: [],
    observed_summary: {
      role: "reviewer",
      decision: "CHANGES_REQUESTED",
      summary: "The review completed and found one blocking issue.",
    },
  });

  const failed = core.normalizeBoundaryReceipt(receiptCase("worker", { result: { requests: 300 } }).input);
  assert.equal(core.toProvisionalOutcome(failed.receipt), null);
  assert.equal(core.toProvisionalOutcome({ ...worker.receipt, unexpected: true }), null);
});

test("Vibe, eval, and internal-agent artifacts cannot masquerade as managed acceptance evidence", () => {
  const unmanaged = [
    { schema_version: 1, record_type: "vibe_result", status: "completed", output: "looks plausible" },
    { schema_version: 1, record_type: "eval_result", score: 1, accepted: true },
    { schema_version: 1, record_type: "internal_agent_result", status: "completed", findings: [] },
    { projectAgentsDir: "D:/fixture/repository/.omp/agent-tasks", results: [] },
  ];
  for (const artifact of unmanaged) assert.equal(core.toProvisionalOutcome(artifact), null);
});
