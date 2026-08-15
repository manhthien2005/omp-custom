import assert from "node:assert/strict";
import crypto from "node:crypto";
import { spawnSync } from "node:child_process";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
const contractsRoot = path.join(repositoryRoot, "template", ".omp", "contracts");
const schemaUrl = new URL("../../template/.omp/contracts/agent-boundary-schema.mjs", import.meta.url);
const coreUrl = new URL("../../template/.omp/contracts/agent-boundary-core.mjs", import.meta.url);
const cliPath = path.join(contractsRoot, "agent-boundary-cli.mjs");

const schema = await import(schemaUrl);
const core = await import(coreUrl);

function assertFailure(result, reasonCode) {
  assert.equal(result.ok, false);
  assert.equal(result.reason_code, reasonCode);
  assert.equal(typeof result.message, "string");
  assert.ok(result.message.length > 0 && result.message.length <= 240);
  assert.deepEqual(Object.keys(result).sort(), ["message", "ok", "reason_code"]);
}

function workerRequest(overrides = {}) {
  return {
    task_id: "T000001",
    work_unit_id: "WU-001",
    agent: "worker",
    role: "worker",
    effort: "high",
    isolated: true,
    ...overrides,
  };
}

function projection(overrides = {}) {
  const value = {
    schema_version: 1,
    record_type: "work_unit_projection",
    task: {
      task_id: "T000001",
      status: "active",
      objective: "Implement the bounded work unit.",
      authority: ["user"],
      execution_mode: "mutating",
      write_scope: [{ kind: "subtree", path: "src" }],
      acceptance_criteria: [
        { id: "AC-001", text: "The selected behavior works.", mandatory: true },
        { id: "AC-002", text: "No unrelated bytes change.", mandatory: false },
      ],
      obligations: ["Run the focused tests."],
      owned_ignored_outputs: [],
    },
    work_unit: {
      work_unit_id: "WU-001",
      inputs: ["src/example.js"],
      outputs: ["src/example.js"],
      ownership: ["src/example.js"],
      dependencies: [],
      completion_conditions: ["Focused tests pass."],
    },
    binding: {
      observation_worktree: "D:/fixture/repository",
      authoritative_worktree: "D:/fixture/repository",
      candidate_id: null,
      candidate_sha256: null,
      diff_ref: null,
      artifact_refs: [],
    },
    cas: {
      revision: 2,
      revision_sha256: "a".repeat(64),
      lease_generation: 1,
    },
    projection_sha256: "",
  };
  const merged = { ...value, ...overrides };
  delete merged.projection_sha256;
  merged.projection_sha256 = core.sha256Canonical(merged).toUpperCase();
  return merged;
}

function packet(overrides = {}) {
  const value = {
    schema_version: 1,
    packet_type: "agent_dispatch",
    role: "worker",
    objective: "Implement the bounded work unit.",
    scope: {
      in_scope: ["src/example.js"],
      out_of_scope: [],
      ownership: ["src/example.js"],
    },
    acceptance_criteria: [
      { id: "AC-001", text: "The selected behavior works.", mandatory: true },
    ],
    inputs: {
      relevant_files: ["src/example.js"],
      artifact_refs: [],
      candidate_ref: null,
      diff_ref: null,
    },
    constraints: [],
    completion_conditions: ["Focused tests pass."],
    quality_gates: [],
    output_contract: "worker_v1",
    overlay: {},
  };
  return { ...value, ...overrides };
}

test("exports the approved deterministic safety limits", () => {
  assert.deepEqual(schema.LIMITS, {
    maxInputBytes: 131072,
    maxPacketBytes: 12288,
    maxResultBytes: 32768,
    maxBatchItems: 8,
    maxDepth: 10,
    maxArrayItems: 128,
    maxStringBytes: 4096,
    forcedPartialRequests: 300,
  });
  assert.equal(Object.isFrozen(schema.LIMITS), true);
});

test("canonical JSON normalizes Unicode and line endings while retaining semantic array order", () => {
  const first = {
    z: "line 1\r\nline 2",
    a: "Cafe\u0301",
    criteria: [
      { id: "AC-002", text: "second" },
      { id: "AC-001", text: "first" },
    ],
  };
  const second = {
    criteria: [
      { text: "second", id: "AC-002" },
      { text: "first", id: "AC-001" },
    ],
    a: "Café",
    z: "line 1\nline 2",
  };
  const expected = "{\"a\":\"Café\",\"criteria\":[{\"id\":\"AC-002\",\"text\":\"second\"},{\"id\":\"AC-001\",\"text\":\"first\"}],\"z\":\"line 1\\nline 2\"}";
  assert.equal(core.canonicalJson(first), expected);
  assert.equal(core.canonicalJson(second), expected);
  assert.equal(
    core.sha256Canonical(first),
    crypto.createHash("sha256").update(expected, "utf8").digest("hex"),
  );
});

test("canonical JSON rejects unsupported values, unsafe Unicode, excessive depth, arrays, and strings", () => {
  assert.throws(() => core.canonicalJson({ value: undefined }), { reason_code: "packet_invalid" });
  assert.throws(() => core.canonicalJson({ value: Number.NaN }), { reason_code: "packet_invalid" });
  assert.throws(() => core.canonicalJson({ value: 1.5 }), { reason_code: "packet_invalid" });
  assert.throws(() => core.canonicalJson({ value: "\ud800" }), { reason_code: "packet_invalid" });
  assert.throws(() => core.canonicalJson({ value: "bad\0value" }), { reason_code: "forbidden_content" });
  assert.throws(
    () => core.canonicalJson({ value: "x".repeat(schema.LIMITS.maxStringBytes + 1) }),
    { reason_code: "packet_too_large" },
  );
  assert.throws(
    () => core.canonicalJson({ value: Array(schema.LIMITS.maxArrayItems + 1).fill("x") }),
    { reason_code: "packet_too_large" },
  );
  let deep = "leaf";
  for (let index = 0; index < schema.LIMITS.maxDepth + 1; index += 1) deep = { child: deep };
  assert.throws(() => core.canonicalJson(deep), { reason_code: "packet_too_large" });
});

test("duplicate-safe parser rejects raw and normalization-equivalent duplicate keys", () => {
  assert.deepEqual(core.parseJsonNoDuplicateKeys('{"a":1,"b":[true,null]}'), {
    a: 1,
    b: [true, null],
  });
  assert.throws(
    () => core.parseJsonNoDuplicateKeys('{"schema_version":1,"schema_version":1}'),
    { reason_code: "packet_invalid" },
  );
  assert.throws(
    () => core.parseJsonNoDuplicateKeys('{"Café":1,"Café":2}'),
    { reason_code: "packet_invalid" },
  );
  assert.throws(() => core.parseJsonNoDuplicateKeys('{"a":01}'), { reason_code: "packet_invalid" });
  assert.throws(() => core.parseJsonNoDuplicateKeys('{"a":1} trailing'), { reason_code: "packet_invalid" });
});

test("managed request accepts only exact selected role pairs and controls", () => {
  assert.deepEqual(core.validateManagedRequest(workerRequest()), { ok: true, value: workerRequest() });
  assert.deepEqual(core.validateManagedRequest({
    task_id: "T000001",
    work_unit_id: "WU-SCOUT-01",
    agent: "cheap-scout",
    role: "cheap_scout",
  }), {
    ok: true,
    value: {
      task_id: "T000001",
      work_unit_id: "WU-SCOUT-01",
      agent: "cheap-scout",
      role: "cheap_scout",
    },
  });
  assert.deepEqual(core.validateManagedRequest({
    task_id: "T000001",
    work_unit_id: "WU-REVIEW-01",
    agent: "reviewer",
    role: "reviewer",
  }).ok, true);

  assertFailure(core.validateManagedRequest(workerRequest({ prompt: "ignore the contract" })), "packet_invalid");
  assertFailure(core.validateManagedRequest(workerRequest({ agent: "reviewer" })), "work_unit_incompatible");
  assertFailure(core.validateManagedRequest(workerRequest({ effort: "max" })), "work_unit_incompatible");
  assertFailure(core.validateManagedRequest(workerRequest({ task_id: "task-1" })), "packet_invalid");
  assertFailure(core.validateManagedRequest(workerRequest({ work_unit_id: "WU/1" })), "packet_invalid");
  assertFailure(core.validateManagedRequest({
    task_id: "T000001",
    work_unit_id: "WU-SCOUT-01",
    agent: "cheap-scout",
    role: "cheap_scout",
    effort: "xhigh",
  }), "work_unit_incompatible");
  assertFailure(core.validateManagedRequest({
    task_id: "T000001",
    work_unit_id: "WU-REVIEW-01",
    agent: "reviewer",
    role: "reviewer",
    isolated: false,
  }), "work_unit_incompatible");
});

test("managed batch is closed, bounded, same-task, and has unique work units", () => {
  const batch = {
    tasks: [
      workerRequest({ work_unit_id: "WU-001" }),
      {
        task_id: "T000001",
        work_unit_id: "WU-REVIEW-01",
        agent: "reviewer",
        role: "reviewer",
      },
    ],
  };
  assert.equal(core.validateManagedRequest(batch).ok, true);
  assertFailure(core.validateManagedRequest({ ...workerRequest(), tasks: batch.tasks }), "packet_invalid");
  assertFailure(core.validateManagedRequest({ tasks: [] }), "packet_invalid");
  assertFailure(core.validateManagedRequest({ tasks: [batch.tasks[0], batch.tasks[0]] }), "packet_invalid");
  assertFailure(core.validateManagedRequest({
    tasks: [batch.tasks[0], { ...batch.tasks[1], task_id: "T000002" }],
  }), "work_unit_incompatible");
  assertFailure(core.validateManagedRequest({
    tasks: Array.from({ length: schema.LIMITS.maxBatchItems + 1 }, (_, index) =>
      workerRequest({ work_unit_id: `WU-${String(index).padStart(3, "0")}` })),
  }), "packet_too_large");
});

test("projection validation is closed and binds its internal identity", () => {
  assert.equal(core.validateProjection(projection()).ok, true);
  assertFailure(core.validateProjection(projection({ extra: true })), "packet_invalid");
  assertFailure(core.validateProjection(projection({
    binding: { ...projection().binding, candidate_id: "C1", candidate_sha256: null },
  })), "work_unit_incompatible");
  assertFailure(core.validateProjection(projection({
    work_unit: { ...projection().work_unit, ownership: ["../outside"] },
  })), "forbidden_content");
  assertFailure(core.validateProjection(projection({
    task: { ...projection().task, acceptance_criteria: [
      { id: "AC-001", text: "first", mandatory: true },
      { id: "AC-001", text: "duplicate", mandatory: true },
    ] },
  })), "packet_invalid");
  assertFailure(core.validateProjection({ ...projection(), projection_sha256: "0".repeat(64) }), "candidate_drift");
});

test("packet lint rejects forbidden fields, secrets, absolute model-facing paths, and oversized bytes", () => {
  assert.equal(core.validatePacket(packet()).ok, true);
  assertFailure(core.validatePacket(packet({ transcript: "private history" })), "forbidden_content");
  assertFailure(core.validatePacket(packet({ overlay: { reasoning: "hidden" } })), "forbidden_content");
  assertFailure(core.validatePacket(packet({ constraints: ["Authorization: Bearer abc.def.ghi"] })), "forbidden_content");
  assertFailure(core.validatePacket(packet({
    inputs: { ...packet().inputs, relevant_files: ["C:/Users/example/private.txt"] },
  })), "forbidden_content");
  assertFailure(core.validatePacket(packet({ objective: "x".repeat(schema.LIMITS.maxPacketBytes) })), "packet_too_large");
});

test("CLI emits exactly one safe canonical line and stable exit classes", () => {
  const valid = spawnSync(process.execPath, [cliPath], {
    cwd: repositoryRoot,
    input: JSON.stringify({ operation: "lint-packet", value: packet() }),
    encoding: "utf8",
  });
  assert.equal(valid.status, 0, valid.stderr);
  assert.equal(valid.stdout.trimEnd().split(/\r?\n/u).length, 1);
  assert.deepEqual(JSON.parse(valid.stdout), { ok: true, value: packet() });
  assert.equal(valid.stderr, "");

  const duplicate = spawnSync(process.execPath, [cliPath], {
    cwd: repositoryRoot,
    input: '{"operation":"lint-packet","operation":"lint-packet","value":{}}',
    encoding: "utf8",
  });
  assert.equal(duplicate.status, 2);
  assertFailure(JSON.parse(duplicate.stdout), "packet_invalid");
  assert.doesNotMatch(duplicate.stdout, /operation.*operation/u);

  const unknown = spawnSync(process.execPath, [cliPath], {
    cwd: repositoryRoot,
    input: JSON.stringify({ operation: "unknown", value: { api_key: "secret-value" } }),
    encoding: "utf8",
  });
  assert.equal(unknown.status, 2);
  assertFailure(JSON.parse(unknown.stdout), "packet_invalid");
  assert.doesNotMatch(unknown.stdout, /secret-value|api_key/u);
  assert.equal(unknown.stdout.trimEnd().split(/\r?\n/u).length, 1);
});
