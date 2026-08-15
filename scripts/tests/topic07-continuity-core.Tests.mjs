import assert from "node:assert/strict";
import test from "node:test";

import * as boundary from "../../template/.omp/contracts/agent-boundary-core.mjs";
import {
  buildContinuityKernel,
  buildKernelMessage,
  buildObservation,
  buildPreserveData,
  buildRecoveryArtifact,
  resolvePressureBoundary,
  validateContinuityKernel,
  validateContinuityProjection,
  validatePreserveData,
} from "../../template/.omp/contracts/context-continuity-core.mjs";
import { CONTINUITY_LIMITS } from "../../template/.omp/contracts/context-continuity-schema.mjs";

const HASH_A = "a".repeat(64);
const HASH_B = "b".repeat(64);
const HASH_C = "c".repeat(64);
const HASH_D = "d".repeat(64);
const HASH_E = "e".repeat(64);

function rehash(value) {
  const copy = structuredClone(value);
  delete copy.kernel_sha256;
  value.kernel_sha256 = boundary.sha256Canonical(copy);
  return value;
}

function kernel(overrides = {}) {
  const value = {
    schema_version: 1,
    record_type: "context_continuity_kernel",
    task: {
      task_id: "T000001",
      workflow_class: "standard",
      objective: "Implement the approved safe compaction boundary.",
      authority: ["user:topic07", "spec:topic07"],
      execution_mode: "mutating",
      write_scope: [
        { kind: "exact", path: "README.md" },
        { kind: "subtree", path: "src" },
      ],
      acceptance_criteria: [
        { id: "AC-001", text: "Automatic semantic compaction stays disabled.", mandatory: true },
        { id: "AC-002", text: "The kernel remains bounded.", mandatory: false },
      ],
      obligations: ["verification", "rollback"],
      locked_decisions: [
        { decision_id: "D-001", statement: "Use native soft compaction once.", authority_ref: "user:2026-08-13" },
        { decision_id: "D-002", statement: "Do not auto-continue.", authority_ref: "spec:topic07" },
      ],
    },
    lifecycle: {
      status: "active",
      owner_session_ref: "session-exact-01",
      owner_runtime: "omp",
      revision: 4,
      revision_id: "R000004",
      revision_sha256: HASH_A,
      lease_generation: 1,
    },
    checkpoint: {
      checkpoint_id: "CP000001",
      checkpoint_sha256: HASH_B,
      work_unit_id: "WU-CONTINUITY-01",
      next_action: "Run the focused continuity checks.",
      blockers: ["Runtime promotion remains separate."],
      open_risks: ["A provider can still produce an imperfect summary."],
    },
    candidate: {
      candidate_id: "C000001",
      candidate_hash: HASH_C,
      candidate_sha256: HASH_C,
    },
    evidence_bindings: [
      { evidence_id: "E000001", record_sha256: HASH_D },
      { evidence_id: "E000002", record_sha256: HASH_E },
    ],
    degraded_fields: [],
    kernel_sha256: HASH_A,
  };
  for (const [name, replacement] of Object.entries(overrides)) value[name] = replacement;
  return rehash(value);
}

function nullSecondary(workflowClass = "standard", degradedFields = []) {
  const value = kernel();
  value.task.workflow_class = workflowClass;
  value.checkpoint = {
    checkpoint_id: null,
    checkpoint_sha256: null,
    work_unit_id: null,
    next_action: null,
    blockers: [],
    open_risks: [],
  };
  value.candidate = { candidate_id: null, candidate_hash: null, candidate_sha256: null };
  value.evidence_bindings = [];
  value.degraded_fields = degradedFields;
  return rehash(value);
}

test("continuity limits are the exact approved bounded values", () => {
  assert.deepEqual(CONTINUITY_LIMITS, {
    maxKernelBytes: 16_384,
    maxRecoveryArtifactBytes: 262_144,
    maxMetricBytes: 4_096,
    maxDepth: 12,
    maxArrayItems: 128,
    maxStringBytes: 4_096,
    maxLockedDecisions: 64,
    maxBranchEntries: 4_096,
    maxDegradedFields: 8,
    nonceTtlMs: 120_000,
  });
});

test("the exact closed kernel validates as both projection and kernel", () => {
  const value = kernel();
  assert.deepEqual(validateContinuityProjection(value), { ok: true, value });
  assert.deepEqual(validateContinuityKernel(value), { ok: true, value });
});

test("unknown properties at every kernel level fail closed", () => {
  const mutations = [
    (value) => { value.extra = true; },
    (value) => { value.task.extra = true; },
    (value) => { value.lifecycle.extra = true; },
    (value) => { value.checkpoint.extra = true; },
    (value) => { value.candidate.extra = true; },
    (value) => { value.task.write_scope[0].extra = true; },
    (value) => { value.task.acceptance_criteria[0].extra = true; },
    (value) => { value.task.locked_decisions[0].extra = true; },
    (value) => { value.evidence_bindings[0].extra = true; },
  ];
  for (const mutate of mutations) {
    const value = kernel();
    mutate(value);
    rehash(value);
    assert.equal(validateContinuityKernel(value).ok, false);
  }
});

test("duplicate decision, acceptance, write-scope, evidence, and degradation identities are rejected", () => {
  const values = [];
  let value = kernel();
  value.task.locked_decisions[1].decision_id = "D-001";
  values.push(rehash(value));
  value = kernel();
  value.task.acceptance_criteria[1].id = "AC-001";
  values.push(rehash(value));
  value = kernel();
  value.task.write_scope.push(structuredClone(value.task.write_scope[0]));
  values.push(rehash(value));
  value = kernel();
  value.evidence_bindings[1].evidence_id = "E000001";
  values.push(rehash(value));
  value = nullSecondary("quick", ["candidate", "candidate"]);
  values.push(value);
  for (const candidate of values) assert.equal(validateContinuityKernel(candidate).ok, false);
});

test("malformed or inconsistent hashes and candidate/checkpoint pairs are rejected", () => {
  const mutations = [
    (value) => { value.lifecycle.revision_sha256 = "A".repeat(64); },
    (value) => { value.checkpoint.checkpoint_sha256 = "not-a-hash"; },
    (value) => { value.checkpoint.checkpoint_id = null; },
    (value) => { value.candidate.candidate_sha256 = HASH_D; },
    (value) => { value.candidate.candidate_id = null; },
    (value) => { value.evidence_bindings[0].record_sha256 = "f".repeat(63); },
  ];
  for (const mutate of mutations) {
    const value = kernel();
    mutate(value);
    rehash(value);
    assert.equal(validateContinuityKernel(value).ok, false);
  }
});

test("missing critical fields and invalid workflow classes fail every workflow", () => {
  const values = [];
  for (const workflowClass of ["quick", "standard", "orchestrated"]) {
    const value = kernel();
    value.task.workflow_class = workflowClass;
    delete value.task.objective;
    values.push(rehash(value));
  }
  const invalid = kernel();
  invalid.task.workflow_class = "automatic";
  values.push(rehash(invalid));
  for (const value of values) assert.equal(validateContinuityKernel(value).ok, false);
});

test("explicit secondary absence is valid but named degradation is Quick-only and exact", () => {
  assert.equal(validateContinuityKernel(nullSecondary("standard")).ok, true);
  assert.equal(validateContinuityKernel(nullSecondary("orchestrated")).ok, true);
  const fields = [
    "blockers", "candidate", "checkpoint", "evidence_bindings", "next_action", "open_risks", "work_unit_id",
  ];
  assert.equal(validateContinuityKernel(nullSecondary("quick", fields)).ok, true);
  assert.equal(validateContinuityKernel(nullSecondary("standard", ["candidate"])).ok, false);
  assert.equal(validateContinuityKernel(nullSecondary("orchestrated", ["checkpoint"])).ok, false);
  assert.equal(validateContinuityKernel(nullSecondary("quick", ["unknown_field"])).ok, false);
  const mismatch = kernel();
  mismatch.task.workflow_class = "quick";
  mismatch.degraded_fields = ["candidate"];
  rehash(mismatch);
  assert.equal(validateContinuityKernel(mismatch).ok, false);
});

test("buildContinuityKernel normalizes NFC/LF and only the declared set-like fields", () => {
  const input = kernel();
  input.task.objective = "Cafe\u0301\r\ncontinuity";
  input.task.write_scope.reverse();
  input.task.locked_decisions.reverse();
  input.evidence_bindings.reverse();
  input.task.authority = ["z-authority", "a-authority"];
  input.task.acceptance_criteria.reverse();
  input.task.obligations = ["z-obligation", "a-obligation"];
  input.checkpoint.blockers = ["z-blocker", "a-blocker"];
  input.checkpoint.open_risks = ["z-risk", "a-risk"];

  const expected = structuredClone(input);
  expected.task.objective = "Café\ncontinuity";
  expected.task.write_scope = [
    { kind: "exact", path: "README.md" },
    { kind: "subtree", path: "src" },
  ];
  expected.task.locked_decisions.sort((left, right) => left.decision_id.localeCompare(right.decision_id));
  expected.evidence_bindings.sort((left, right) => left.evidence_id.localeCompare(right.evidence_id));
  rehash(expected);
  input.kernel_sha256 = expected.kernel_sha256;

  const result = buildContinuityKernel(input);
  assert.equal(result.ok, true);
  assert.deepEqual(result.kernel, expected);
  assert.equal(result.canonical, boundary.canonicalJson(expected));
  assert.equal(result.sha256, expected.kernel_sha256);
  assert.equal(result.utf8_bytes, Buffer.byteLength(result.canonical, "utf8"));
  assert.deepEqual(result.kernel.task.authority, ["z-authority", "a-authority"]);
  assert.deepEqual(result.kernel.task.acceptance_criteria.map((item) => item.id), ["AC-002", "AC-001"]);
  assert.deepEqual(result.kernel.task.obligations, ["z-obligation", "a-obligation"]);
  assert.deepEqual(result.kernel.checkpoint.blockers, ["z-blocker", "a-blocker"]);
  assert.deepEqual(result.kernel.checkpoint.open_risks, ["z-risk", "a-risk"]);
});

test("kernel_sha256 excludes only itself and detects every other mutation", () => {
  const value = kernel();
  const originalHash = value.kernel_sha256;
  value.kernel_sha256 = HASH_E;
  assert.equal(validateContinuityKernel(value).ok, false);
  value.kernel_sha256 = originalHash;
  value.task.objective = "Changed purpose";
  assert.equal(validateContinuityKernel(value).ok, false);
});

test("depth, item, string, locked-decision, and 16 KiB limits reject without truncation", () => {
  const tooManyItems = kernel();
  tooManyItems.task.authority = Array.from({ length: 129 }, (_, index) => `authority-${index}`);
  const tooLong = kernel();
  tooLong.task.objective = "x".repeat(4_097);
  const tooManyDecisions = kernel();
  tooManyDecisions.task.locked_decisions = Array.from({ length: 65 }, (_, index) => ({
    decision_id: `D-${String(index).padStart(3, "0")}`,
    statement: "bounded",
    authority_ref: "user:test",
  }));
  rehash(tooManyDecisions);
  const tooDeep = kernel();
  let cursor = tooDeep;
  for (let index = 0; index < 14; index += 1) {
    cursor.extra = {};
    cursor = cursor.extra;
  }
  const tooManyBytes = kernel();
  tooManyBytes.task.acceptance_criteria = Array.from({ length: 20 }, (_, index) => ({
    id: `AC-X${String(index).padStart(3, "0")}`,
    text: "x".repeat(1_000),
    mandatory: true,
  }));
  rehash(tooManyBytes);
  assert.ok(Buffer.byteLength(boundary.canonicalJson(tooManyBytes), "utf8") > CONTINUITY_LIMITS.maxKernelBytes);

  for (const value of [tooManyItems, tooLong, tooManyDecisions, tooDeep, tooManyBytes]) {
    const result = buildContinuityKernel(value);
    assert.equal(result.ok, false);
    assert.equal(JSON.stringify(result).includes("xxxx"), false);
  }
  assert.equal(tooManyBytes.task.acceptance_criteria[0].text.length, 1_000);
});

test("forbidden history, reasoning, credential, and private-path content is rejected safely", () => {
  const propertyNames = ["transcript", "tool_history", "reasoning", "credential", "private_path"];
  for (const propertyName of propertyNames) {
    const value = kernel();
    value.task[propertyName] = "do-not-leak-contents";
    rehash(value);
    const result = validateContinuityKernel(value);
    assert.equal(result.ok, false);
    assert.equal(JSON.stringify(result).includes("do-not-leak-contents"), false);
  }
  for (const signature of [
    "Bearer abcdefghijklmnopqrstuvwxyz",
    "ghp_abcdefghijklmnopqrstuvwxyz123456",
    "AKIAABCDEFGHIJKLMNOP",
    "-----BEGIN PRIVATE KEY-----",
  ]) {
    const value = kernel();
    value.task.objective = signature;
    rehash(value);
    assert.equal(validateContinuityKernel(value).reason_code, "continuity_forbidden");
  }
});

test("pressure boundary mirrors the frozen OMP reserve formula", () => {
  const cases = [
    { contextWindow: 2, reserveTokens: 1, thresholdTokens: 1 },
    { contextWindow: 8_192, reserveTokens: 1_228, thresholdTokens: 6_964 },
    { contextWindow: 16_384, reserveTokens: 2_457, thresholdTokens: 13_927 },
    { contextWindow: 32_768, reserveTokens: 16_384, thresholdTokens: 16_384 },
    { contextWindow: 131_072, reserveTokens: 19_660, thresholdTokens: 111_412 },
    { contextWindow: 200_000, reserveTokens: 30_000, thresholdTokens: 170_000 },
    { contextWindow: 1_000_000, reserveTokens: 150_000, thresholdTokens: 850_000 },
  ];
  for (const item of cases) {
    assert.deepEqual(resolvePressureBoundary({ tokens: item.thresholdTokens, contextWindow: item.contextWindow }), {
      reserveTokens: item.reserveTokens,
      thresholdTokens: item.thresholdTokens,
      atOrAbove: true,
    });
    assert.equal(resolvePressureBoundary({
      tokens: item.thresholdTokens - 1,
      contextWindow: item.contextWindow,
    }).atOrAbove, false);
  }
  assert.deepEqual(resolvePressureBoundary({ tokens: 16_384, contextWindow: 32_768, reserveTokens: 16_384 }), {
    reserveTokens: 16_384,
    thresholdTokens: 16_384,
    atOrAbove: true,
  });
});

test("pressure boundary rejects negative, fractional, or impossible counters", () => {
  for (const input of [
    { tokens: -1, contextWindow: 32_768 },
    { tokens: 1.5, contextWindow: 32_768 },
    { tokens: 0, contextWindow: 1 },
    { tokens: 0, contextWindow: 32_768.5 },
    { tokens: 0, contextWindow: 32_768, reserveTokens: -1 },
    { tokens: 0, contextWindow: 32_768, reserveTokens: 1.5 },
  ]) assert.throws(() => resolvePressureBoundary(input), (error) => error?.reason_code === "pressure_invalid");
});

test("recovery, preserveData, kernel-message, and observation builders stay closed and transcript-free", () => {
  const currentKernel = kernel();
  const recovery = buildRecoveryArtifact({
    epoch_id: "E-000001",
    created_at_utc: "2026-08-13T12:00:00.000Z",
    expires_at_utc: "2026-08-13T12:02:00.000Z",
    session_id_sha256: HASH_A,
    session_file_sha256: HASH_B,
    task_id: "T000001",
    task_revision_sha256: HASH_A,
    lease_generation: 1,
    branch_sha256: HASH_C,
    leaf_entry_id: "entry-002",
    branch_entry_ids: ["entry-001", "entry-002"],
    kernel: currentKernel,
  });
  assert.equal(recovery.artifact.record_type, "context_continuity_recovery");
  assert.equal(recovery.artifact.kernel.kernel_sha256, currentKernel.kernel_sha256);
  assert.equal(recovery.utf8_bytes <= CONTINUITY_LIMITS.maxRecoveryArtifactBytes, true);
  assert.doesNotMatch(recovery.canonical, /transcript|nonce/iu);

  const identity = {
    epoch_id: "E-000001",
    nonce_sha256: HASH_D,
    task_id: "T000001",
    task_revision_sha256: HASH_A,
    kernel_sha256: currentKernel.kernel_sha256,
    branch_sha256: HASH_C,
    recovery_artifact_id: "artifact-topic07-000001",
  };
  const preserveData = buildPreserveData(identity);
  assert.deepEqual(validatePreserveData(preserveData, identity), { ok: true, value: preserveData });
  const tampered = structuredClone(preserveData);
  tampered["omp_template.topic07"].branch_sha256 = HASH_E;
  assert.equal(validatePreserveData(tampered, identity).ok, false);

  const message = buildKernelMessage(currentKernel);
  assert.deepEqual(Object.keys(message).sort(), ["attribution", "content", "customType", "display", "role"]);
  assert.equal(message.role, "custom");
  assert.equal(message.display, false);
  assert.match(message.content, /^<context_continuity_kernel>\n/u);
  assert.match(message.content, /\n<\/context_continuity_kernel>$/u);

  const observation = buildObservation({
    component_version: "2.1.0",
    runtime_version: "17.2.12",
    session_sha256: HASH_A,
    task_sha256: HASH_B,
    epoch_sha256: HASH_C,
    workflow_class: "standard",
    context_tokens: 10_000,
    context_window: 32_768,
    threshold_tokens: 16_384,
    kernel_bytes: Buffer.byteLength(boundary.canonicalJson(currentKernel), "utf8"),
    kernel_sha256: currentKernel.kernel_sha256,
    artifact_status: "saved",
    preparation_status: "ready",
    compaction_status: "completed",
    validation_status: "passed",
    reason_code: "ok",
    degraded_fields: [],
    settings_drift: [],
    injection_status: "awaiting",
    provider_action: "not_applicable",
  });
  assert.equal(observation.record_type, "context_continuity_observation");
  assert.ok(Buffer.byteLength(boundary.canonicalJson(observation), "utf8") <= CONTINUITY_LIMITS.maxMetricBytes);
  assert.doesNotMatch(JSON.stringify(observation), /prompt|transcript|session-exact-01/iu);
});

test("safe builders reject raw nonce, private paths, and unbounded observation text without echoing them", () => {
  const currentKernel = kernel();
  const marker = "do-not-leak-private-value";
  const attempts = [
    () => buildPreserveData({
      epoch_id: "E-000001",
      nonce: marker,
      nonce_sha256: HASH_D,
      task_id: "T000001",
      task_revision_sha256: HASH_A,
      kernel_sha256: currentKernel.kernel_sha256,
      branch_sha256: HASH_C,
      recovery_artifact_id: "artifact-topic07-000001",
    }),
    () => buildRecoveryArtifact({
      epoch_id: "E-000001",
      created_at_utc: "2026-08-13T12:00:00.000Z",
      expires_at_utc: "2026-08-13T12:02:00.000Z",
      session_id_sha256: HASH_A,
      session_file_sha256: HASH_B,
      session_path: marker,
      task_id: "T000001",
      task_revision_sha256: HASH_A,
      lease_generation: 1,
      branch_sha256: HASH_C,
      leaf_entry_id: "entry-001",
      branch_entry_ids: ["entry-001"],
      kernel: currentKernel,
    }),
  ];
  for (const attempt of attempts) {
    assert.throws(attempt, (error) => !error.message.includes(marker) && error.reason_code === "continuity_forbidden");
  }
});
