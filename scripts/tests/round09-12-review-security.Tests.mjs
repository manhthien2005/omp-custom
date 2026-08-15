import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import {
  classifyValidatedOutcome,
  runDeterministicCli,
  validateFixtureManifest,
  validateTaskCycleRecord,
} from "../lib/round09-12-evaluation-core.mjs";

const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const fixtureRoot = path.join(repositoryRoot, "evals", "round09-12");
const manifestPath = path.join(fixtureRoot, "manifest.json");
const runnerPath = path.join(repositoryRoot, "scripts", "run-round09-12-evaluation.ps1");
const benchmarkPath = path.join(repositoryRoot, "scripts", "benchmark.ps1");
const fakeRuntimePath = path.join(repositoryRoot, "scripts", "tests", "fixtures", "round09-12-fake-omp.mjs");
const EXPECTED_CASE_IDS = [
  "E-EFFICIENCY-WIN",
  "E-MISSING-TELEMETRY",
  "E-PILOT-CANNOT-PROMOTE",
  "E-POSTHOC-THRESHOLD",
  "E-QUALITY-WIN",
  "Q-FALSE-COMPLETION",
  "Q-MISSING-INDEPENDENT-REVIEW",
  "Q-STALE-CANDIDATE",
  "Q-VALID-REVIEW",
  "R-SCRATCH-PACKAGE",
  "S-DESTRUCTIVE-NO-AUTHORITY",
  "S-DUPLICATE-SIDE-EFFECT-RETRY",
  "S-PARTIAL-OUTPUT",
  "S-SECRET-EVIDENCE",
];

async function loadFixtureSet() {
  const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
  const cases = [];
  for (const relativePath of manifest.case_files) {
    const file = JSON.parse(await readFile(path.join(fixtureRoot, relativePath), "utf8"));
    cases.push(...file.cases);
  }
  return { manifest, cases };
}

async function taskCycle(caseId) {
  const { cases } = await loadFixtureSet();
  const row = cases.find((candidate) => candidate.id === caseId);
  assert.ok(row, `Missing case ${caseId}`);
  return structuredClone(row.input.task_cycle);
}

function runPowerShell(scriptPath, args, environment = {}) {
  return spawnSync("pwsh", ["-NoLogo", "-NoProfile", "-File", scriptPath, ...args], {
    cwd: repositoryRoot,
    encoding: "utf8",
    env: { ...process.env, ...environment },
    timeout: 30_000,
  });
}

test("the versioned fixture manifest indexes every approved case exactly once", async () => {
  const { manifest, cases } = await loadFixtureSet();
  assert.equal(validateFixtureManifest(manifest).ok, true);
  assert.deepEqual(
    cases.map((row) => row.id).sort((left, right) => left.localeCompare(right, "en")),
    EXPECTED_CASE_IDS,
  );
  assert.equal(new Set(cases.map((row) => row.id)).size, cases.length);
  for (const row of cases) {
    assert.equal(typeof row.input, "object");
    assert.equal(typeof row.expected, "object");
    assert.notEqual(typeof row.input.task_cycle, "string");
  }
});

test("critical and important block while minor supports approval with notes", async () => {
  for (const severity of ["critical", "important"]) {
    const cycle = await taskCycle("Q-VALID-REVIEW");
    cycle.review_evidence.findings = [{ code: "REV-900", severity }];
    cycle.blocking_issues = [{ code: "REV-900", severity }];
    cycle.review_evidence.decision = "REWORK";
    assert.equal(classifyValidatedOutcome(cycle).validated_accepted_outcome, false);
  }
  const minor = await taskCycle("Q-VALID-REVIEW");
  minor.review_evidence.findings = [{ code: "REV-901", severity: "minor" }];
  minor.review_evidence.decision = "APPROVED_WITH_NOTES";
  assert.equal(classifyValidatedOutcome(minor).validated_accepted_outcome, true);
});

test("a changed candidate invalidates prior review evidence", async () => {
  const cycle = await taskCycle("Q-STALE-CANDIDATE");
  assert.deepEqual(classifyValidatedOutcome(cycle), {
    validated_accepted_outcome: false,
    false_completion: false,
    reasons: ["stale_review_evidence"],
  });
});

test("missing independent review cannot become Tech Lead acceptance", async () => {
  const cycle = await taskCycle("Q-MISSING-INDEPENDENT-REVIEW");
  assert.equal(cycle.tech_lead_acceptance, "accepted");
  assert.deepEqual(classifyValidatedOutcome(cycle).reasons, ["review_not_independent"]);
});

test("secret-shaped evidence is rejected without value echo", () => {
  const marker = ["api_key=", "TEST_ONLY_NOT_A_REAL_SECRET_12345678"].join("");
  const cycle = {
    schema_version: 1,
    record_type: "round0912_task_cycle",
    candidate_id: marker,
  };
  const result = validateTaskCycleRecord(cycle);
  assert.equal(result.ok, false);
  assert.equal(result.errors.some((error) => error.code === "R0912-SCHEMA-SECRET"), true);
  assert.doesNotMatch(JSON.stringify(result), /TEST_ONLY_NOT_A_REAL_SECRET/u);
});

test("a non-idempotent retry with an attempted side effect is rejected", async () => {
  const cycle = await taskCycle("S-DUPLICATE-SIDE-EFFECT-RETRY");
  assert.deepEqual(classifyValidatedOutcome(cycle).reasons, ["unsafe_side_effect_retry"]);
});

test("partial output stays nonterminal and cannot be accepted", async () => {
  const cycle = await taskCycle("S-PARTIAL-OUTPUT");
  const result = classifyValidatedOutcome(cycle);
  assert.equal(result.validated_accepted_outcome, false);
  assert.equal(result.reasons.includes("task_cycle_not_accepted"), true);
  assert.equal(result.reasons.includes("objective_incomplete"), true);
});

test("all deterministic fixtures execute without a provider process", async () => {
  const outputRoot = await mkdtemp(path.join(os.tmpdir(), "round0912-fixture-test-"));
  try {
    const outputPath = path.join(outputRoot, "result.json");
    const result = await runDeterministicCli([
      "--fixture-manifest", manifestPath,
      "--output", outputPath,
    ]);
    assert.equal(result.status, "PASS");
    assert.equal(result.provider_calls, 0);
    assert.equal(result.model_processes_started, 0);
    assert.equal(result.cases.length, EXPECTED_CASE_IDS.length);
    assert.equal(result.cases.every((row) => row.status === "PASS"), true);
  } finally {
    await rm(outputRoot, { recursive: true, force: true });
  }
});

test("the runner defaults to deterministic mode and starts no provider or model process", async () => {
  const outputRoot = await mkdtemp(path.join(os.tmpdir(), "round0912-runner-default-"));
  try {
    const run = runPowerShell(runnerPath, ["-OutputDirectory", outputRoot]);
    assert.equal(run.status, 0, run.stderr || run.stdout);
    const result = JSON.parse(await readFile(path.join(outputRoot, "round09-12-evaluation.json"), "utf8"));
    assert.equal(result.mode, "deterministic");
    assert.equal(result.environment_status, "PASS");
    assert.equal(result.provider_calls, 0);
    assert.equal(result.model_processes_started, 0);
  } finally {
    await rm(outputRoot, { recursive: true, force: true });
  }
});

test("campaign mode refuses before process start without explicit provider authority", async () => {
  const outputRoot = await mkdtemp(path.join(os.tmpdir(), "round0912-runner-noauth-"));
  try {
    const run = runPowerShell(runnerPath, [
      "-Mode", "Campaign",
      "-OutputDirectory", outputRoot,
      "-OmpPath", fakeRuntimePath,
      "-EvidenceBudget", "1",
    ]);
    assert.equal(run.status, 3, run.stderr || run.stdout);
    const result = JSON.parse(await readFile(path.join(outputRoot, "round09-12-evaluation.json"), "utf8"));
    assert.equal(result.environment_status, "NOT_RUN");
    assert.deepEqual(result.reasons, ["provider_calls_not_authorized"]);
    assert.equal(result.runtime_processes_started, 0);
  } finally {
    await rm(outputRoot, { recursive: true, force: true });
  }
});

test("campaign mode refuses a missing positive evidence budget before process start", async () => {
  const outputRoot = await mkdtemp(path.join(os.tmpdir(), "round0912-runner-budget-"));
  try {
    const run = runPowerShell(runnerPath, [
      "-Mode", "Campaign",
      "-OutputDirectory", outputRoot,
      "-OmpPath", fakeRuntimePath,
      "-AllowProviderCalls",
      "-EvidenceBudget", "0",
    ]);
    assert.equal(run.status, 3, run.stderr || run.stdout);
    const result = JSON.parse(await readFile(path.join(outputRoot, "round09-12-evaluation.json"), "utf8"));
    assert.equal(result.environment_status, "NOT_RUN");
    assert.deepEqual(result.reasons, ["evidence_budget_missing"]);
    assert.equal(result.runtime_processes_started, 0);
  } finally {
    await rm(outputRoot, { recursive: true, force: true });
  }
});

test("an unavailable campaign runtime is environment-blocked rather than promoted or retried", async () => {
  const outputRoot = await mkdtemp(path.join(os.tmpdir(), "round0912-runner-missing-"));
  try {
    const missingRuntime = path.join(outputRoot, "missing-omp.exe");
    const run = runPowerShell(runnerPath, [
      "-Mode", "Campaign",
      "-OutputDirectory", outputRoot,
      "-OmpPath", missingRuntime,
      "-AllowProviderCalls",
      "-EvidenceBudget", "1",
    ]);
    assert.equal(run.status, 0, run.stderr || run.stdout);
    const result = JSON.parse(await readFile(path.join(outputRoot, "round09-12-evaluation.json"), "utf8"));
    assert.equal(result.environment_status, "ENVIRONMENT_BLOCKED");
    assert.equal(result.promotion.verdict, "DEFER_INCONCLUSIVE");
    assert.deepEqual(result.reasons, ["runtime_unavailable"]);
    assert.equal(result.runtime_processes_started, 0);
  } finally {
    await rm(outputRoot, { recursive: true, force: true });
  }
});

test("the explicitly authorized fake campaign runtime runs once inside a scratch Git repository", async () => {
  const outputRoot = await mkdtemp(path.join(os.tmpdir(), "round0912-runner-fake-"));
  const counterPath = path.join(outputRoot, "fake-counter.txt");
  try {
    const run = runPowerShell(runnerPath, [
      "-Mode", "Campaign",
      "-OutputDirectory", outputRoot,
      "-OmpPath", fakeRuntimePath,
      "-AllowProviderCalls",
      "-EvidenceBudget", "1",
    ], { ROUND0912_FAKE_COUNTER: counterPath });
    assert.equal(run.status, 0, run.stderr || run.stdout);
    assert.equal((await readFile(counterPath, "utf8")).trim(), "1");
    const result = JSON.parse(await readFile(path.join(outputRoot, "round09-12-evaluation.json"), "utf8"));
    assert.equal(result.environment_status, "PASS");
    assert.equal(result.fake_runtime, true);
    assert.equal(result.runtime_processes_started, 1);
    assert.equal(result.provider_calls, 0);
    assert.equal(result.model_processes_started, 0);
  } finally {
    await rm(outputRoot, { recursive: true, force: true });
  }
});

test("the legacy benchmark entry point forwards DryRun to deterministic evaluation", async () => {
  const outputRoot = await mkdtemp(path.join(os.tmpdir(), "round0912-benchmark-forward-"));
  try {
    const run = runPowerShell(benchmarkPath, ["-DryRun", "-OutputDirectory", outputRoot]);
    assert.equal(run.status, 0, run.stderr || run.stdout);
    assert.match(run.stdout, /deprecated/iu);
    const result = JSON.parse(await readFile(path.join(outputRoot, "round09-12-evaluation.json"), "utf8"));
    assert.equal(result.mode, "deterministic");
    assert.equal(result.provider_calls, 0);
  } finally {
    await rm(outputRoot, { recursive: true, force: true });
  }
});
