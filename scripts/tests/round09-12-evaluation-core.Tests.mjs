import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import {
  PROMOTION_VERDICTS,
  aggregateTaskCycles,
  classifyValidatedOutcome,
  evaluatePromotion,
  runDeterministicCli,
  validateFixtureManifest,
  validateTaskCycleRecord,
} from "../lib/round09-12-evaluation-core.mjs";

const HASH_A = "a".repeat(64);
const HASH_B = "b".repeat(64);
const HASH_C = "c".repeat(64);
const HASH_D = "d".repeat(64);
const corePath = fileURLToPath(new URL("../lib/round09-12-evaluation-core.mjs", import.meta.url));

function acceptedCycle(overrides = {}) {
  const cycle = {
    schema_version: 1,
    record_type: "round0912_task_cycle",
    task_cycle_id: "TC-000001",
    task_contract_hash: HASH_A,
    candidate_id: "C000001",
    candidate_snapshot_hash: HASH_B,
    lifecycle_terminal_outcome: "accepted",
    nonterminal_observation: null,
    objective_status: "complete",
    mandatory_ac_results: [
      { id: "AC-001", status: "PASS", evidence_ids: ["E000001"] },
    ],
    required_gates: { verification: "PASS", review: "PASS" },
    blocking_issues: [],
    review_evidence: {
      required: true,
      decision: "APPROVED",
      candidate_id: "C000001",
      candidate_snapshot_hash: HASH_B,
      reviewer_role: "reviewer",
      independent: true,
      fresh_result: true,
      findings: [],
    },
    operations: {
      retries: [],
      destructive_action: { requested: false, authorized: false },
    },
    tech_lead_acceptance: "accepted",
    author_claimed_success: true,
    oracle_passed: true,
    failure_class: "none",
    usage: {
      main: { input: 100, output: 20, cache_write: 5, cache_read: 10 },
      children: [
        { id: "A-1", role: "worker", input: 50, output: 10, cache_write: 2, cache_read: 5 },
        { id: "A-2", role: "cheap-scout", input: 30, output: 5, cache_write: 1, cache_read: 3 },
      ],
    },
  };
  return Object.assign(cycle, structuredClone(overrides));
}

function manifest(overrides = {}) {
  return {
    schema_version: 1,
    record_type: "round0912_fixture_manifest",
    fixture_version: "1.0.0",
    baseline_kinds: ["stable_product_baseline", "pinned_plain_omp_runtime_baseline"],
    campaign_policy: {
      default_mode: "deterministic",
      provider_calls_require_explicit_authority: true,
      pilot_min_pairs_per_arm: 3,
      pilot_can_promote: false,
      max_joint_false_promotion_probability: 0.05,
    },
    case_files: ["cases/quality-security.json"],
    ...structuredClone(overrides),
  };
}

function promotionInput(overrides = {}) {
  const value = {
    campaign: {
      environment_status: "PASS",
      phase: "final",
      evidence_budget_exhausted: false,
      frozen_threshold_hash: HASH_A,
      observed_threshold_hash: HASH_A,
      frozen_plan_hash: HASH_B,
      observed_plan_hash: HASH_B,
      look_declared: true,
      inference_method: "anytime_valid",
      alpha_allocation_complete: true,
      joint_false_promotion_probability: 0.05,
      pilot_included_in_frozen_plan: false,
    },
    hard_gates: {
      operational_fixtures_pass: true,
      acceptance_criteria_coverage_complete: true,
      new_false_completions: 0,
      blocking_regressions: 0,
      acceptance_rate_not_lower: true,
      ledgers_coherent: true,
      baseline_identities_coherent: true,
    },
    summary: {
      observed_acceptance_rate_delta: 0.02,
      acceptance_rate_lower_bound: -0.03,
      token_improvement_fraction: 0.12,
      token_improvement_lower_bound: 0.01,
      token_ratio_upper_bound: 0.88,
    },
    sequential_evidence: {
      measured: true,
      promotion_bounds_valid: true,
    },
  };
  for (const [key, replacement] of Object.entries(overrides)) {
    value[key] = { ...value[key], ...structuredClone(replacement) };
  }
  return value;
}

test("the fixture manifest is closed and accepts only the approved campaign policy", () => {
  assert.equal(validateFixtureManifest(manifest()).ok, true);
  assert.equal(validateFixtureManifest(manifest({ unexpected: true })).errors[0].code, "R0912-SCHEMA-CLOSED");
  assert.equal(validateFixtureManifest(manifest({ case_files: ["../private.json"] })).ok, false);
  const unsafe = manifest();
  unsafe.campaign_policy.pilot_can_promote = true;
  assert.equal(validateFixtureManifest(unsafe).ok, false);
});

test("one closed accepted task cycle validates and classifies as accepted", () => {
  const result = validateTaskCycleRecord(acceptedCycle());
  assert.equal(result.ok, true);
  assert.deepEqual(classifyValidatedOutcome(result.value), {
    validated_accepted_outcome: true,
    false_completion: false,
    reasons: [],
  });
});

test("unknown fields, zero hashes, and duplicate child identities fail closed", () => {
  assert.equal(
    validateTaskCycleRecord({ ...acceptedCycle(), narrative: "trust me" }).errors[0].code,
    "R0912-SCHEMA-CLOSED",
  );
  assert.equal(validateTaskCycleRecord(acceptedCycle({ task_contract_hash: "0".repeat(64) })).ok, false);
  const duplicate = acceptedCycle();
  duplicate.usage.children.push(structuredClone(duplicate.usage.children[0]));
  assert.equal(validateTaskCycleRecord(duplicate).ok, false);
});

test("terminal and nonterminal lifecycle states cannot be combined", () => {
  assert.equal(validateTaskCycleRecord(acceptedCycle({ nonterminal_observation: "partial" })).ok, false);
  const partial = acceptedCycle({
    lifecycle_terminal_outcome: null,
    nonterminal_observation: "partial",
    objective_status: "incomplete",
    tech_lead_acceptance: "pending",
    author_claimed_success: false,
    oracle_passed: null,
    failure_class: "contract",
  });
  partial.required_gates.review = "FAIL";
  partial.review_evidence.decision = "REWORK";
  assert.equal(validateTaskCycleRecord(partial).ok, true);
  assert.equal(classifyValidatedOutcome(partial).validated_accepted_outcome, false);
});

test("secret-shaped values are rejected without echoing the rejected value", () => {
  const marker = "api_key=TEST_ONLY_NOT_A_REAL_SECRET_12345678";
  const cycle = acceptedCycle({ candidate_id: marker });
  const result = validateTaskCycleRecord(cycle);
  assert.equal(result.ok, false);
  assert.doesNotMatch(JSON.stringify(result), /TEST_ONLY_NOT_A_REAL_SECRET/u);
});

test("false completion, stale review evidence, and non-independent review prevent acceptance", () => {
  const falseCompletion = acceptedCycle({ oracle_passed: false });
  assert.deepEqual(classifyValidatedOutcome(falseCompletion), {
    validated_accepted_outcome: false,
    false_completion: true,
    reasons: ["false_completion"],
  });

  const stale = acceptedCycle();
  stale.review_evidence.candidate_snapshot_hash = HASH_C;
  assert.deepEqual(classifyValidatedOutcome(stale).reasons, ["stale_review_evidence"]);

  const dependent = acceptedCycle();
  dependent.review_evidence.independent = false;
  assert.deepEqual(classifyValidatedOutcome(dependent).reasons, ["review_not_independent"]);
});

test("critical and important findings block while minor findings support approval with notes", () => {
  for (const severity of ["critical", "important"]) {
    const cycle = acceptedCycle();
    cycle.review_evidence.findings = [{ code: "REV-001", severity }];
    cycle.blocking_issues = [{ code: "REV-001", severity }];
    cycle.review_evidence.decision = "REWORK";
    assert.equal(classifyValidatedOutcome(cycle).validated_accepted_outcome, false);
  }
  const noted = acceptedCycle();
  noted.review_evidence.findings = [{ code: "REV-002", severity: "minor" }];
  noted.review_evidence.decision = "APPROVED_WITH_NOTES";
  assert.equal(classifyValidatedOutcome(noted).validated_accepted_outcome, true);
});

test("unauthorized destructive work and unreconciled side-effect retries are rejected", () => {
  const destructive = acceptedCycle();
  destructive.operations.destructive_action = { requested: true, authorized: false };
  assert.deepEqual(classifyValidatedOutcome(destructive).reasons, ["destructive_action_not_authorized"]);

  const retry = acceptedCycle();
  retry.operations.retries = [{
    operation_id: "OP-001",
    side_effect_attempted: true,
    idempotency_key: null,
    reconciliation_status: "missing",
  }];
  assert.deepEqual(classifyValidatedOutcome(retry).reasons, ["unsafe_side_effect_retry"]);
});

test("token accounting counts main and each unique child once and separates Cheap Scout", () => {
  const second = acceptedCycle({ task_cycle_id: "TC-000002", candidate_id: "C000002" });
  second.review_evidence.candidate_id = "C000002";
  const summary = aggregateTaskCycles([acceptedCycle(), second]);
  assert.deepEqual(summary, {
    attempted_cycles: 2,
    validated_accepted: 2,
    accepted_rate: 1,
    core_workflow_tokens: 374,
    cheap_scout_tokens: 72,
    raw_total_tokens: 446,
    cache_read_tokens: 36,
    core_workflow_tokens_per_accepted: 187,
    not_measured_reasons: [],
  });
});

test("missing usage attribution is not measured and zero acceptance has infinite cost", () => {
  const missing = acceptedCycle();
  delete missing.usage.children[0].role;
  const unmeasured = aggregateTaskCycles([missing]);
  assert.equal(unmeasured.core_workflow_tokens, "not_measured");
  assert.equal(unmeasured.core_workflow_tokens_per_accepted, "not_measured");
  assert.deepEqual(unmeasured.not_measured_reasons, ["invalid_task_cycle"]);

  const rejected = acceptedCycle({ objective_status: "incomplete", tech_lead_acceptance: "not_accepted" });
  const zeroAccepted = aggregateTaskCycles([rejected]);
  assert.equal(zeroAccepted.validated_accepted, 0);
  assert.equal(zeroAccepted.core_workflow_tokens_per_accepted, "infinite");
});

test("promotion verdicts are closed and hard gates run before evidence paths", () => {
  assert.deepEqual(PROMOTION_VERDICTS, [
    "PROMOTE_EFFICIENCY",
    "PROMOTE_QUALITY",
    "REJECT",
    "DEFER_INCONCLUSIVE",
  ]);
  assert.equal(evaluatePromotion(promotionInput()).verdict, "PROMOTE_EFFICIENCY");

  const quality = promotionInput({
    summary: {
      acceptance_rate_lower_bound: 0.01,
      token_improvement_fraction: 0.02,
      token_improvement_lower_bound: -0.02,
      token_ratio_upper_bound: 1.08,
    },
  });
  assert.equal(evaluatePromotion(quality).verdict, "PROMOTE_QUALITY");

  const blocking = promotionInput({ hard_gates: { new_false_completions: 1 } });
  assert.equal(evaluatePromotion(blocking).verdict, "REJECT");
});

test("blocked, pilot, missing, and exhausted evidence defer without inventing a fifth verdict", () => {
  assert.equal(
    evaluatePromotion(promotionInput({ campaign: { environment_status: "ENVIRONMENT_BLOCKED" } })).verdict,
    "DEFER_INCONCLUSIVE",
  );
  assert.equal(evaluatePromotion(promotionInput({ campaign: { phase: "pilot" } })).verdict, "DEFER_INCONCLUSIVE");
  assert.equal(
    evaluatePromotion(promotionInput({ sequential_evidence: { measured: false } })).verdict,
    "DEFER_INCONCLUSIVE",
  );
  assert.equal(
    evaluatePromotion(promotionInput({ campaign: { evidence_budget_exhausted: true } })).verdict,
    "DEFER_INCONCLUSIVE",
  );
});

test("post-hoc or invalid sequential controls reject promotion", () => {
  const cases = [
    promotionInput({ campaign: { observed_threshold_hash: HASH_C } }),
    promotionInput({ campaign: { look_declared: false } }),
    promotionInput({ campaign: { inference_method: "nominal_repeated" } }),
    promotionInput({ campaign: { alpha_allocation_complete: false } }),
    promotionInput({ campaign: { joint_false_promotion_probability: 0.051 } }),
    promotionInput({ campaign: { phase: "final", pilot_included_in_frozen_plan: true, observed_plan_hash: HASH_D } }),
  ];
  for (const value of cases) assert.equal(evaluatePromotion(value).verdict, "REJECT");
});

test("the deterministic CLI writes one canonical zero-provider result", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "round0912-core-test-"));
  try {
    const casesDirectory = path.join(root, "cases");
    await import("node:fs/promises").then(({ mkdir }) => mkdir(casesDirectory));
    await writeFile(path.join(root, "manifest.json"), `${JSON.stringify(manifest(), null, 2)}\n`, "utf8");
    await writeFile(path.join(casesDirectory, "quality-security.json"), `${JSON.stringify({
      schema_version: 1,
      record_type: "round0912_fixture_cases",
      category: "quality",
      cases: [{
        id: "Q-VALID-REVIEW",
        kind: "task_cycle",
        input: { task_cycle: acceptedCycle() },
        expected: { validated_accepted_outcome: true, false_completion: false, reasons: [] },
      }],
    }, null, 2)}\n`, "utf8");
    const output = path.join(root, "result.json");
    const result = await runDeterministicCli([
      "--fixture-manifest", path.join(root, "manifest.json"),
      "--output", output,
    ]);
    assert.equal(result.environment_status, "PASS");
    assert.equal(result.provider_calls, 0);
    assert.equal(result.model_processes_started, 0);
    assert.deepEqual(result.cases, [{ id: "Q-VALID-REVIEW", status: "PASS" }]);
    assert.equal(result.promotion.verdict, "DEFER_INCONCLUSIVE");
    const written = await readFile(output, "utf8");
    assert.equal(written.endsWith("\n"), true);
    assert.deepEqual(JSON.parse(written), result);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("importing the core from node eval mode never self-invokes its CLI", () => {
  const probe = spawnSync(process.execPath, [
    "--input-type=module",
    "-e",
    'import { pathToFileURL } from "node:url"; await import(pathToFileURL(process.argv[1]).href); process.stdout.write("imported\\n");',
    corePath,
  ], { cwd: path.dirname(corePath), encoding: "utf8" });
  assert.equal(probe.status, 0, probe.stderr || probe.stdout);
  assert.equal(probe.stdout, "imported\n");
  assert.equal(probe.stderr, "");
});
