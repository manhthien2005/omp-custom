import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

import { canonicalJson } from "../../template/.omp/contracts/agent-boundary-core.mjs";
import { reconcileBehaviorCatalog } from "../../template/.omp/contracts/behavior-core.mjs";
import {
  createBehaviorToolCallHandler,
  reconcileEffectiveBehavior,
} from "../../template/.omp/extensions/agent-task-boundary.js";
import { sha256Canonical } from "../../template/.omp/contracts/context-continuity-core.mjs";

const repositoryRoot = path.resolve(import.meta.dirname, "../..");
const ompRoot = path.join(repositoryRoot, "template/.omp");
const manifest = JSON.parse(fs.readFileSync(path.join(ompRoot, "contracts/behavior-manifest.json"), "utf8"));

function sha256File(file) {
  return crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

function validCatalog() {
  return {
    manifest: structuredClone(manifest),
    ompRoot,
    agents: Object.fromEntries(Object.entries(manifest.roles).map(([name, row]) => [name, {
      autoloadSkills: [...row.required_autoload],
    }])),
    skills: manifest.skills.filter((row) => row.status === "active").map((row) => ({
      name: row.name,
      filePath: path.join(repositoryRoot, "template", row.path),
      hide: row.visibility !== "visible",
    })),
    fileHashes: Object.fromEntries(manifest.skills.filter((row) => row.status === "active")
      .map((row) => [row.path, sha256File(path.join(repositoryRoot, "template", row.path))])),
  };
}

function withMissingEvidenceSkill() {
  const value = validCatalog();
  value.skills = value.skills.filter((row) => row.name !== "evidence-before-completion");
  return value;
}

function withUserShadow() {
  const value = validCatalog();
  value.skills.find((row) => row.name === "evidence-before-completion").filePath =
    path.resolve("user/.omp/skills/evidence-before-completion/SKILL.md");
  return value;
}

function withChangedEvidenceBytes() {
  const value = validCatalog();
  value.fileHashes[".omp/skills/evidence-before-completion/SKILL.md"] = "f".repeat(64);
  return value;
}

function withWorkerAutoload(autoloadSkills) {
  const value = validCatalog();
  value.agents.worker.autoloadSkills = autoloadSkills;
  return value;
}

function runtime() {
  return {
    schema_version: 2,
    record_type: "agent_boundary_runtime",
    target_omp: ompRoot,
    paths: {
      pwsh: path.resolve("fake/pwsh.exe"),
      state_cli: path.join(ompRoot, "state/agent-tasks.ps1"),
    },
    capabilities: {
      batch: true,
      isolation: true,
      effort: true,
      max_effort: "xhigh",
      continuity: true,
    },
  };
}

function makeKernel(sessionId = "codex:topic08-main") {
  const value = {
    schema_version: 1,
    record_type: "context_continuity_kernel",
    task: {
      task_id: "T000001",
      workflow_class: "standard",
      objective: "Exercise deterministic Topic 08 behavior gates.",
      authority: ["user"],
      execution_mode: "mutating",
      write_scope: [{ kind: "subtree", path: "template/.omp" }],
      acceptance_criteria: [{ id: "AC-001", text: "The gate is deterministic.", mandatory: true }],
      obligations: ["verification"],
      locked_decisions: [],
    },
    lifecycle: {
      status: "active",
      owner_session_ref: sessionId,
      owner_runtime: "omp",
      revision: 1,
      revision_id: "R000001",
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
  return value;
}

function packet(role) {
  const output = {
    cheap_scout: "cheap_scout_v1",
    worker: "worker_v1",
    reviewer: "reviewer_v1",
  }[role];
  return {
    schema_version: 1,
    packet_type: "agent_dispatch",
    role,
    objective: "Execute only the bounded work unit.",
    scope: { in_scope: ["template/.omp"], out_of_scope: [], ownership: ["template/.omp"] },
    acceptance_criteria: [{ id: "AC-001", text: "The bounded result is valid.", mandatory: true }],
    inputs: { relevant_files: [], artifact_refs: [], candidate_ref: null, diff_ref: null },
    constraints: [],
    completion_conditions: [],
    quality_gates: [],
    output_contract: output,
    overlay: {},
  };
}

function sessionInit(agent, role) {
  return {
    type: "session_init",
    agent,
    systemPrompt: "Bounded selected-agent contract.",
    task: canonicalJson(packet(role)),
    tools: ["read", "yield"],
  };
}

function context({ branch = [], sessionId = "codex:topic08-main" } = {}) {
  return {
    cwd: repositoryRoot,
    sessionManager: {
      getSessionId: () => sessionId,
      getBranch: () => branch,
    },
  };
}

function successState(sessionId = "codex:topic08-main") {
  return { ok: true, code: "AT-OK", operation: "project-continuity", data: makeKernel(sessionId) };
}

async function gate({
  toolName,
  branch = [],
  sessionId = "codex:topic08-main",
  state = successState(sessionId),
  observe,
}) {
  const handler = createBehaviorToolCallHandler({
    pi: { logger: { warn() {} } },
    runtime: runtime(),
    manifest,
    dependencies: {
      invokeState: async () => {
        if (state instanceof Error) throw state;
        return state;
      },
      observe,
    },
  });
  return handler({ type: "tool_call", toolName, input: {} }, context({ branch, sessionId }));
}

test("reconciles selected skills, hashes, paths, and exact autoload bindings", () => {
  assert.equal(reconcileBehaviorCatalog(validCatalog()).ok, true);
  assert.equal(reconcileBehaviorCatalog(withMissingEvidenceSkill()).reason_code, "BHV-SKILL-MISSING");
  assert.equal(reconcileBehaviorCatalog(withUserShadow()).reason_code, "BHV-SKILL-SHADOWED");
  assert.equal(reconcileBehaviorCatalog(withChangedEvidenceBytes()).reason_code, "BHV-SKILL-HASH-MISMATCH");
  assert.equal(reconcileBehaviorCatalog(withWorkerAutoload([])).reason_code, "BHV-AUTOLOAD-MISMATCH");
});

test("uses fresh OMP discovery output for effective behavior reconciliation", async () => {
  const snapshot = validCatalog();
  const result = await reconcileEffectiveBehavior({
    pi: {
      cwd: repositoryRoot,
      pi: {
        discoverAgents: async () => ({
          agents: Object.entries(snapshot.agents).map(([name, row]) => ({ name, ...row })),
        }),
        discoverSkills: async () => ({ skills: snapshot.skills, warnings: [] }),
      },
    },
    runtime: runtime(),
    manifest,
  });
  assert.equal(result.behavior.ok, true);
  assert.equal(result.skillCatalog.skills.length, 3);
});

test("allows diagnosis, blocks unbound mutation, and permits one valid main binding", async () => {
  assert.equal(await gate({ toolName: "read", state: new Error("state_unavailable") }), undefined);
  const missing = await gate({
    toolName: "bash",
    state: { ok: false, code: "AT-CONTINUITY-NOT-FOUND", operation: "project-continuity", data: {} },
  });
  assert.equal(missing.block, true);
  assert.match(missing.reason, /^BHV-STATE-MISSING:/u);
  assert.equal(await gate({ toolName: "bash" }), undefined);
});

test("distinguishes ambiguous authority from a state-client failure", async () => {
  const ambiguous = await gate({
    toolName: "write",
    state: { ok: false, code: "AT-CONTINUITY-TASK-AMBIGUOUS", operation: "project-continuity", data: {} },
  });
  assert.match(ambiguous.reason, /^BHV-STATE-AMBIGUOUS:/u);
  const unavailable = await gate({ toolName: "edit", state: new Error("state_unavailable") });
  assert.match(unavailable.reason, /^BHV-HOOK-UNAVAILABLE:/u);
});

test("accepts only one canonical role-matched child packet for mutation", async () => {
  const worker = sessionInit("worker", "worker");
  assert.equal(await gate({ toolName: "write", branch: [worker], sessionId: "codex:worker" }), undefined);
  const reviewer = sessionInit("reviewer", "reviewer");
  assert.equal(await gate({ toolName: "bash", branch: [reviewer], sessionId: "codex:reviewer" }), undefined);

  const scout = await gate({
    toolName: "bash",
    branch: [sessionInit("cheap-scout", "cheap_scout")],
    sessionId: "codex:scout",
  });
  assert.match(scout.reason, /^BHV-LIFECYCLE-FORBIDDEN:/u);

  const malformed = structuredClone(worker);
  malformed.task = `${malformed.task} `;
  assert.match((await gate({ toolName: "edit", branch: [malformed], sessionId: "codex:worker" })).reason,
    /^BHV-STATE-MISSING:/u);
  assert.match((await gate({ toolName: "edit", branch: [worker, worker], sessionId: "codex:worker" })).reason,
    /^BHV-STATE-AMBIGUOUS:/u);
});

test("agent_tasks owns its strict child refusal and observation failures preserve the decision", async () => {
  assert.equal(await gate({
    toolName: "agent_tasks",
    branch: [sessionInit("worker", "worker")],
    sessionId: "codex:worker",
  }), undefined);
  assert.equal(await gate({
    toolName: "bash",
    observe: () => { throw new Error("logger unavailable"); },
  }), undefined);
});

test("pressure fixture retains the complete approved deterministic scenario roster", () => {
  const fixture = JSON.parse(fs.readFileSync(
    path.join(repositoryRoot, "evals/pressure/topic08/behavior-gates.json"),
    "utf8",
  ));
  assert.equal(fixture.record_type, "topic08_behavior_pressure_suite");
  assert.deepEqual(fixture.cases.map((row) => row.id), [
    "explicit-bootstrap-success",
    "inferred-bootstrap-refusal",
    "authority-sensitive-operation-refusal",
    "child-lifecycle-refusal",
    "missing-state-mutation",
    "ambiguous-state-mutation",
    "read-only-diagnosis",
    "valid-main-mutation",
    "valid-managed-child-binding",
    "missing-skill",
    "shadowed-skill",
    "skill-hash-drift",
    "logging-failure",
  ]);
  assert.equal(new Set(fixture.cases.map((row) => row.id)).size, fixture.cases.length);
});
