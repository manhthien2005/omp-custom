import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
const templateRoot = path.join(repositoryRoot, "template");
const discoveryProbe = path.join(repositoryRoot, "scripts", "tests", "fixtures", "topic06-omp-agent-discovery-probe.mjs");
const schemaUrl = new URL("../../template/.omp/contracts/agent-boundary-schema.mjs", import.meta.url);
const coreUrl = new URL("../../template/.omp/contracts/agent-boundary-core.mjs", import.meta.url);
const schema = await import(schemaUrl);
const core = await import(coreUrl);

function assertFailure(result, reasonCode) {
  assert.equal(result.ok, false);
  assert.equal(result.reason_code, reasonCode);
  assert.deepEqual(Object.keys(result).sort(), ["message", "ok", "reason_code"]);
}

function withProjectionHash(value) {
  const projection = structuredClone(value);
  delete projection.projection_sha256;
  projection.projection_sha256 = core.sha256Canonical(projection).toUpperCase();
  return projection;
}

function projectionFor(role, overrides = {}) {
  const reviewer = role === "reviewer";
  const scout = role === "cheap_scout";
  const value = {
    schema_version: 1,
    record_type: "work_unit_projection",
    task: {
      task_id: "T000001",
      status: reviewer ? "candidate_frozen" : "active",
      objective: scout ? "Find the producer and consumers of the routing decision." :
        reviewer ? "Review the frozen routing candidate." : "Implement the bounded routing change.",
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
      completion_conditions: reviewer ?
        ["Check fallback authorization and exact model identity."] :
        scout ? ["Return current-source citations for every claim."] : ["Run verify-router."],
    },
    binding: {
      observation_worktree: "D:/fixture/repository",
      authoritative_worktree: scout ? null : "D:/fixture/repository",
      candidate_id: reviewer ? "C1" : null,
      candidate_sha256: reviewer ? "A".repeat(64) : null,
      diff_ref: reviewer ? "B".repeat(64) : null,
      artifact_refs: reviewer ? ["src/router.mjs"] : [],
    },
    cas: {
      revision: 4,
      revision_sha256: "C".repeat(64),
      lease_generation: 1,
    },
  };
  const merged = {
    ...value,
    ...overrides,
    task: { ...value.task, ...(overrides.task ?? {}) },
    work_unit: { ...value.work_unit, ...(overrides.work_unit ?? {}) },
    binding: { ...value.binding, ...(overrides.binding ?? {}) },
    cas: { ...value.cas, ...(overrides.cas ?? {}) },
  };
  return withProjectionHash(merged);
}

function managedRequest(role, overrides = {}) {
  const base = role === "cheap_scout" ? {
    task_id: "T000001",
    work_unit_id: "WU-SCOUT-001",
    agent: "cheap-scout",
    role,
  } : role === "reviewer" ? {
    task_id: "T000001",
    work_unit_id: "WU-REVIEW-001",
    agent: "reviewer",
    role,
  } : {
    task_id: "T000001",
    work_unit_id: "WU-WORKER-001",
    agent: "worker",
    role,
    effort: "high",
    isolated: true,
  };
  return { ...base, ...overrides };
}

function validScoutResult() {
  return {
    status: "completed",
    summary: "The route is selected in the policy module and consumed by the wrapper.",
    capability: "native",
    source_fitness_reason: "Direct source reads are sufficient for this bounded producer-consumer trace.",
    fallback_path: [],
    claims: [{
      claim: "The policy module selects the route before wrapper dispatch.",
      sources: [{ path: "src/router.mjs", line_start: 10, line_end: 18 }],
    }],
    gaps: [],
    searches_performed: [{ method: "grep", query: "selectRoute", outcome: "Found one producer and two consumers." }],
    recommended_next_action: "Inspect the two consumers before changing the producer.",
  };
}

function validWorkerResult() {
  return {
    status: "completed",
    summary: "Implemented the bounded route selection change and ran the focused check.",
    artifact_refs: ["src/router.mjs"],
    verification_observations: [{ command_id: "verify-router", status: "passed", observation: "Focused check passed." }],
    covered_ac_ids: ["AC-002", "AC-001"],
    blockers: [],
    remaining_risks: [],
  };
}

function validReviewerResult() {
  return {
    decision: "APPROVED",
    summary: "The frozen candidate preserves the selected fallback boundary.",
    findings: [],
    cleared_concerns: [{ concern: "Unauthorized fallback", evidence: "The exact branch is guarded in src/router.mjs:10." }],
    recommended_action: "ACCEPT",
  };
}

function handoffProjection(overrides = {}) {
  const value = {
    schema_version: 1,
    record_type: "handoff_projection",
    task_contract: {
      task_id: "T000001",
      objective: "Transfer the frozen routing candidate.",
      authority: ["user-approved-topic-06"],
      acceptance_criteria: [{ id: "AC-001", text: "The transfer is exact.", mandatory: true }],
      obligations: ["Revalidate before mutation."],
      execution_mode: "mutating",
      write_scope: [{ kind: "subtree", path: "src" }],
      owned_ignored_outputs: [],
      task_contract_sha256: "D".repeat(64),
    },
    candidate: {
      candidate_id: "C1",
      candidate_sha256: "A".repeat(64),
      diff_ref: "B".repeat(64),
      artifact_refs: ["src/router.mjs"],
      evidence_bindings: [{ evidence_id: "E000001", record_hash: "E".repeat(64) }],
      workspace_snapshot_sha256: "F".repeat(64),
    },
    lifecycle: {
      status: "transferring",
      prior_status: "candidate_frozen",
      next_action: "Reload authority and revalidate.",
      blockers: [],
      open_risks: ["Workspace may drift before acceptance."],
    },
    successor: { session_ref: "codex:successor", runtime: "codex" },
    transfer: {
      task_id: "T000001",
      handoff_id: "H000001",
      handoff_sha256: "1".repeat(64),
      predecessor_revision: 5,
      predecessor_revision_sha256: "2".repeat(64),
      revision: 6,
      revision_sha256: "3".repeat(64),
      lease_generation: 1,
    },
  };
  return withProjectionHash({ ...value, ...overrides });
}

test("Worker composition preserves Topic 04 AC identity/order and emits deterministic canonical bytes", () => {
  const projection = projectionFor("worker");
  const request = managedRequest("worker");
  const first = core.composeAgentPacket({ request, projection });
  const second = core.composeAgentPacket({ projection: structuredClone(projection), request: structuredClone(request) });
  assert.equal(first.ok, true);
  assert.equal(second.ok, true);
  assert.deepEqual(first.packet.acceptance_criteria.map((criterion) => criterion.id), ["AC-002", "AC-001"]);
  assert.equal(new Set(first.packet.acceptance_criteria.map((criterion) => criterion.id)).size, 2);
  assert.deepEqual(first.packet.scope.ownership, ["src/router.mjs"]);
  assert.deepEqual(first, second);
  assert.equal(first.canonical, core.canonicalJson(first.packet));
  assert.equal(first.packet_sha256, core.sha256Canonical(first.packet));
  assert.equal(first.utf8_bytes, Buffer.byteLength(first.canonical, "utf8"));
});

test("Cheap Scout is read-only and receives only its closed retrieval overlay", () => {
  const result = core.composeAgentPacket({
    request: managedRequest("cheap_scout"),
    projection: projectionFor("cheap_scout"),
  });
  assert.equal(result.ok, true);
  assert.equal(result.packet.role, "cheap_scout");
  assert.equal(result.packet.output_contract, "cheap_scout_v1");
  assert.deepEqual(result.packet.scope.ownership, []);
  assert.deepEqual(Object.keys(result.packet.overlay).sort(), [
    "allowed_capabilities",
    "evidence_requirements",
    "question",
    "retrieval_contract",
    "source_fitness_guidance",
    "stop_condition",
  ]);
  assert.doesNotMatch(JSON.stringify(result.packet.overlay), /review|accept|mutat|model|effort/iu);

  const mutatingParent = core.composeAgentPacket({
    request: managedRequest("cheap_scout"),
    projection: projectionFor("cheap_scout", { task: { execution_mode: "mutating" } }),
  });
  assert.equal(mutatingParent.ok, true, "a read-only Scout work unit may support a mutating parent task");
  assertFailure(core.composeAgentPacket({
    request: managedRequest("cheap_scout"),
    projection: projectionFor("cheap_scout", { work_unit: { ownership: ["src/router.mjs"] } }),
  }), "work_unit_incompatible");
});

test("Worker ownership and outputs must remain inside the accepted task scope", () => {
  const request = managedRequest("worker");
  assertFailure(core.composeAgentPacket({
    request,
    projection: projectionFor("worker", { work_unit: { ownership: ["docs/outside.md"] } }),
  }), "work_unit_incompatible");
  assertFailure(core.composeAgentPacket({
    request,
    projection: projectionFor("worker", { work_unit: { outputs: ["docs/outside.md"] } }),
  }), "work_unit_incompatible");
});

test("Reviewer requires frozen candidate/diff/artifacts and never receives Worker self-assessment", () => {
  const request = managedRequest("reviewer");
  const result = core.composeAgentPacket({ request, projection: projectionFor("reviewer") });
  assert.equal(result.ok, true);
  assert.equal(result.packet.role, "reviewer");
  assert.equal(result.packet.inputs.candidate_ref, "selected_frozen_candidate");
  assert.equal(result.packet.inputs.diff_ref, "selected_candidate_diff");
  assert.deepEqual(result.packet.inputs.artifact_refs, ["src/router.mjs"]);
  assert.doesNotMatch(
    JSON.stringify(result.packet),
    /worker_result|self_assessment|confidence|completion_claim|recommended_verdict/iu,
  );

  for (const binding of [
    { candidate_id: null, candidate_sha256: null },
    { diff_ref: null },
    { artifact_refs: [] },
  ]) {
    assertFailure(core.composeAgentPacket({
      request,
      projection: projectionFor("reviewer", { binding }),
    }), "work_unit_incompatible");
  }
});

test("A specialist concern changes only the closed Reviewer profile, never the roster", () => {
  const request = managedRequest("reviewer");
  const general = core.composeAgentPacket({ request, projection: projectionFor("reviewer") });
  const specialist = core.composeAgentPacket({
    request,
    projection: projectionFor("reviewer", {
      work_unit: { completion_conditions: ["Trace transaction rollback after a concurrent write."] },
    }),
  });
  assert.equal(general.ok, true);
  assert.equal(specialist.ok, true);
  assert.equal(general.packet.role, "reviewer");
  assert.equal(specialist.packet.role, "reviewer");
  assert.equal(schema.MANAGED_ROLES.reviewer.role, "reviewer");
  const generalWithoutProfile = structuredClone(general.packet);
  const specialistWithoutProfile = structuredClone(specialist.packet);
  delete generalWithoutProfile.overlay.concern_profile;
  delete specialistWithoutProfile.overlay.concern_profile;
  generalWithoutProfile.completion_conditions = [];
  specialistWithoutProfile.completion_conditions = [];
  assert.deepEqual(generalWithoutProfile, specialistWithoutProfile);
  assert.notDeepEqual(general.packet.overlay.concern_profile, specialist.packet.overlay.concern_profile);
});

test("semantic schemas accept valid role output and reject unknown/runtime/status-incompatible fields", () => {
  assert.equal(core.validateSemanticResult({ role: "cheap_scout", value: validScoutResult() }).ok, true);
  assert.equal(core.validateSemanticResult({ role: "worker", value: validWorkerResult() }).ok, true);
  assert.equal(core.validateSemanticResult({ role: "reviewer", value: validReviewerResult() }).ok, true);

  assertFailure(core.validateSemanticResult({
    role: "cheap_scout",
    value: { ...validScoutResult(), candidate_hash: "A".repeat(64) },
  }), "structured_output_invalid");
  assertFailure(core.validateSemanticResult({
    role: "worker",
    value: { ...validWorkerResult(), worktree_root: "D:/fixture/repository" },
  }), "structured_output_invalid");
  assertFailure(core.validateSemanticResult({
    role: "worker",
    value: { ...validWorkerResult(), blockers: ["Verification is unavailable."] },
  }), "structured_output_invalid");
  assertFailure(core.validateSemanticResult({
    role: "reviewer",
    value: {
      ...validReviewerResult(),
      decision: "APPROVED",
      findings: [{
        severity: "important",
        title: "Fallback bypass",
        location: "src/router.mjs:10",
        trigger: "The primary model is unavailable.",
        impact: "An unauthorized route can settle.",
        violated_contract: "Only the selected fallback is allowed.",
        evidence: "The branch skips the selected-route comparison.",
      }],
    },
  }), "structured_output_invalid");
  assertFailure(core.validateSemanticResult({
    role: "reviewer",
    value: { ...validReviewerResult(), cleared_concerns: [{ concern: "path", evidence: "C:/private/root" }] },
  }), "forbidden_content");
});

test("canonical semantic schema exports are closed and use the exact contract names", () => {
  assert.deepEqual(Object.keys(schema.SEMANTIC_OUTPUT_SCHEMAS).sort(), ["cheap_scout", "reviewer", "worker"]);
  assert.equal(schema.OUTPUT_CONTRACTS.cheap_scout, "cheap_scout_v1");
  assert.equal(schema.OUTPUT_CONTRACTS.worker, "worker_v1");
  assert.equal(schema.OUTPUT_CONTRACTS.reviewer, "reviewer_v1");
  for (const role of ["cheap_scout", "worker", "reviewer"]) {
    const outputSchema = schema.SEMANTIC_OUTPUT_SCHEMAS[role];
    assert.equal(outputSchema.type, "object");
    assert.equal(outputSchema.additionalProperties, false);
    assert.ok(Array.isArray(outputSchema.required) && outputSchema.required.length > 0);
  }
});

test("installed OMP discovers exact routing and schema parity without a provider call", () => {
  const discovered = spawnSync("omp", [
    "--cwd", templateRoot,
    "--mode", "rpc",
    "--no-session",
    "--no-tools",
    "--no-skills",
    "--no-rules",
    "--no-extensions",
    "--extension", discoveryProbe,
  ], {
    cwd: repositoryRoot,
    encoding: "utf8",
    timeout: 30000,
    windowsHide: true,
    maxBuffer: 1024 * 1024,
  });
  assert.equal(discovered.status, 0, discovered.stderr || discovered.stdout);
  const marker = discovered.stdout.match(/^TOPIC06_AGENT_DISCOVERY=(.*)$/mu);
  assert.ok(marker, discovered.stdout);
  const agents = JSON.parse(marker[1]);
  assert.deepEqual(agents.map((agent) => agent.name), ["cheap-scout", "reviewer", "worker"]);
  const roleByAgent = { "cheap-scout": "cheap_scout", reviewer: "reviewer", worker: "worker" };
  const expectedThinking = { "cheap-scout": "xhigh", reviewer: "xhigh", worker: "high" };
  for (const agent of agents) {
    const role = roleByAgent[agent.name];
    assert.deepEqual(agent.output, schema.SEMANTIC_OUTPUT_SCHEMAS[role]);
    assert.deepEqual(agent.model, [`@${agent.name}`]);
    assert.equal(agent.thinkingLevel, expectedThinking[agent.name]);
    assert.equal(agent.blocking, true);
    assert.deepEqual(agent.spawns, []);
    assert.equal(agent.schemaError, null);
    assert.equal(agent.rejectsMalformed, true);
  }
});

test("handoff composition accepts only the atomic closed projection and preserves exact identity", () => {
  const projection = handoffProjection();
  const first = core.composeHandoffPacket({ handoff_projection: projection });
  const second = core.composeHandoffPacket({ handoff_projection: structuredClone(projection) });
  assert.equal(first.ok, true);
  assert.deepEqual(first, second);
  assert.equal(first.packet.packet_type, "session_handoff");
  assert.deepEqual(first.packet.task_contract, projection.task_contract);
  assert.deepEqual(first.packet.candidate, projection.candidate);
  assert.deepEqual(first.packet.transfer, projection.transfer);
  assert.equal(first.packet_sha256, core.sha256Canonical(first.packet));
  assert.doesNotMatch(JSON.stringify(first.packet), /transcript|history|checkpoint|reasoning|provider|credential/iu);

  assertFailure(core.composeHandoffPacket({
    handoff_projection: { ...projection, transcript: "private" },
  }), "forbidden_content");
  assertFailure(core.composeHandoffPacket({
    handoff_projection: withProjectionHash({ ...projection, lifecycle: { ...projection.lifecycle, history: [] } }),
  }), "forbidden_content");
  assertFailure(core.composeHandoffPacket({ handoff_projection: { ...projection, projection_sha256: "0".repeat(64) } }), "candidate_drift");
});
