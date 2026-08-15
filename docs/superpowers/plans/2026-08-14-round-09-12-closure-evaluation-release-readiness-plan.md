# Round 09–12 Closure, Evaluation, and Release Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. The user has already selected inline execution; do not dispatch subagents.

**Goal:** Close Topics 09–10 as executable contracts, replace the metadata-only benchmark with a safe deterministic evaluation/promotion core, and derive a truthful Topic 12 release-readiness result without provider spend or live installation.

**Architecture:** Topic 04 remains the durable task/candidate/evidence authority and Topic 06 remains the managed dispatch/receipt boundary. New repository-only evaluation tooling consumes closed records, exercises quality/security adversarial cases, and emits one bounded Round 09–12 evidence bundle. Topic 12 consumes that evidence to remap active phases and report `IMPLEMENTED_NOT_PROMOTED` unless separately authorized final campaign evidence exists.

**Tech Stack:** Node.js 24 ESM + built-in `node:test`, PowerShell 7.4+, JSON, Git scratch repositories, installed OMP 17.2.12 for model-free discovery/package canaries.

**Spec:** `docs/superpowers/specs/2026-08-14-round-09-12-closure-evaluation-release-readiness-design.md`

## Global Constraints

- Work only in `D:\Dev\Projects\omp-template`; preserve the existing dirty worktree.
- Do not create/switch a branch or worktree; do not stage, commit, push, create a PR, or mutate remotes.
- Do not install into a live project or user OMP directory; installer tests use verified disposable temp roots only.
- Do not call a provider/model during this implementation. Campaign support is tested with a fake local runtime only.
- Do not download/downgrade OMP, configure credentials, or mutate accounts.
- Do not spawn subagents. A benefit-gated decision would require a new explicit user authorization.
- Preserve immutable/historical evidence. Refresh only `docs/evidence/current-product/**` artifacts whose live-byte contract requires it.
- Keep Topic 04 as the sole durable lifecycle authority; never write directly into `.agent-tasks` from evaluation code.
- Keep Topic 06 receipts provisional; evaluation cannot turn a child receipt into parent acceptance.
- Retain selected roles exactly `cheap-scout`, `worker`, `reviewer`; add no permanent Verifier.
- Reviewer stays exact `xhigh`; `critical` and `important` block, `minor` supports `APPROVED_WITH_NOTES`.
- Provider campaign status is `PASS | ENVIRONMENT_BLOCKED | NOT_RUN`; promotion verdict is exactly `PROMOTE_EFFICIENCY | PROMOTE_QUALITY | REJECT | DEFER_INCONCLUSIVE`.
- Default runner mode is deterministic and model-free. Campaign mode requires `-AllowProviderCalls`, a positive evidence budget, a runtime path, and a frozen manifest.
- `evals/results/` is local/ignored and may contain no raw transcript, reasoning, credential, `.env`, or secret-shaped payload.
- Existing OMP status remains `IMPLEMENTED_NOT_PROMOTED`; Claude remains `DESIGNED_NOT_VERIFIED` and non-installable unless real evidence changes that status.
- Replace every commit step normally required by the planning skill with a local checkpoint: run tests, inspect `git diff`, and confirm `git diff --cached --name-only` is empty.

---

## File Structure and Interfaces

### New files

| Path | Responsibility |
|---|---|
| `scripts/lib/round09-12-evaluation-core.mjs` | Closed JSON validation, accepted-outcome classification, token accounting, hard gates, promotion verdict, deterministic CLI |
| `scripts/run-round09-12-evaluation.ps1` | Safe runner; deterministic default and explicitly authorized campaign process boundary |
| `scripts/lib/round09-12-release-readiness.ps1` | Focused repository/evidence validator and governed-file inventory |
| `scripts/validate-round09-12-release-readiness.ps1` | Human/JSON focused-validator entry point |
| `scripts/capture-round09-12-evidence.ps1` | Transactional model-free evidence capture |
| `scripts/tests/round09-12-evaluation-core.Tests.mjs` | Core schema/classification/accounting/promotion tests |
| `scripts/tests/round09-12-review-security.Tests.mjs` | Quality, security, secret, retry, stale-evidence adversarial tests |
| `scripts/tests/round09-12-installer.Tests.ps1` | Disposable install/discovery/uninstall/rollback proof |
| `scripts/tests/round09-12-validator-mutations.Tests.ps1` | One mutation for every focused-validator category |
| `scripts/tests/fixtures/round09-12-fake-omp.mjs` | Zero-provider campaign seam with invocation counter and deterministic JSON output |
| `evals/round09-12/manifest.json` | Closed fixture version, baseline kinds, case index, and campaign policy |
| `evals/round09-12/cases/quality-security.json` | Topic 09/10 deterministic cases |
| `evals/round09-12/cases/promotion.json` | Topic 11 hard-gate/pilot/final verdict cases |
| `evals/round09-12/cases/package.json` | Topic 12 scratch-package expectations |
| `docs/evidence/current-product/round-09-12/{quality,security,evaluation,release-readiness,manifest}.json` | Generated bounded current-product evidence |
| `codex-round09-12-closure-evaluation-release-readiness-changelog.md` | One round decision/change/evidence/limitation record |

### Modified files

| Path | Responsibility in this round |
|---|---|
| `.gitignore` | Ignore `evals/results/` |
| `scripts/benchmark.ps1` | Compatibility forwarder to the real runner |
| `scripts/validate-template.ps1` | Section 12 Round 09–12 integration |
| `spec/key/04-decision-log.md` | `KD-032` umbrella authority |
| `spec/10-verification-and-review.md` | Single severity vocabulary and fresh delta-review rules |
| `spec/15-security-and-failure-recovery.md` | Executable matrix and local-result privacy boundary |
| `spec/13-validation-and-evaluation.md` | Deterministic/campaign split and truthful blocked status |
| `spec/12-installation-and-rollback.md` | Scratch proof and separate live-install authority |
| `spec/16-migration-plan.md` | Topic 12 supersession/remap |
| `spec/phases/phase-04-quality-system.md` | Topic 09 current consumer |
| `spec/phases/phase-05-installation-hardening.md` | Topic 10/12 package consumer |
| `spec/phases/phase-06-evaluation.md` | Topic 11 current executable consumer |
| `spec/phases/phase-07-stabilization.md` | Release-readiness/limitations consumer |
| `README.md`, `docs/architecture.md`, `docs/security.md`, `docs/installation.md`, `docs/rollback.md`, `docs/final-report.md`, `docs/workflow-v0.md` | Operator-facing round projection |
| `docs/evidence/current-product/topic-03/manifest.yml` | Refresh exact `scripts/validate-template.ps1` hash |
| `docs/evidence/current-product/topic-05/manifest.json` | Refresh exact `scripts/validate-template.ps1` hash |

### Core JavaScript API

```js
export const PROMOTION_VERDICTS = Object.freeze([
  "PROMOTE_EFFICIENCY",
  "PROMOTE_QUALITY",
  "REJECT",
  "DEFER_INCONCLUSIVE",
]);

export function validateFixtureManifest(input) {
  // -> { ok: boolean, value: object|null, errors: [{ code, path, message }] }
}

export function validateTaskCycleRecord(input) {
  // -> same result envelope; normalized value has closed keys and canonical ordering
}

export function classifyValidatedOutcome(record) {
  // -> { validated_accepted_outcome, false_completion, reasons: string[] }
}

export function aggregateTaskCycles(records) {
  // -> { attempted_cycles, validated_accepted, accepted_rate,
  //      core_workflow_tokens_per_accepted, ledgers, not_measured_reasons }
}

export function evaluatePromotion({ campaign, hard_gates, summary, sequential_evidence }) {
  // -> { verdict, reasons, eligible }
}

export async function runDeterministicCli(argv) {
  // Reads a fixture manifest/case files and writes one canonical evaluation result.
}
```

### PowerShell validator API

```powershell
function Get-Round0912GovernedFiles { [string[]] }

function Test-Round0912ReleaseReadiness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [switch]$SkipEvidence,
        [switch]$SkipRuntime,
        [switch]$SkipDocumentation
    )
    # -> objects: @{ Status = PASS|WARN|FAIL; Code = R0912-*; Message = string }
}
```

---

### Task 1: Build the closed evaluation and promotion core

**Files:**
- Create: `scripts/lib/round09-12-evaluation-core.mjs`
- Create: `scripts/tests/round09-12-evaluation-core.Tests.mjs`

**Interfaces:**
- Consumes: canonical JSON-compatible objects only; no filesystem access except through `runDeterministicCli`.
- Produces: the six JavaScript exports defined in the File Structure section.
- Later tasks rely on error codes `R0912-SCHEMA-*`, canonical result records, and the exact four promotion verdicts.

- [x] **Step 1: Write RED tests for closed fixture and task-cycle records**

Create tests that construct one exact passing cycle and mutate one property per case:

```js
const acceptedCycle = {
  schema_version: 1,
  record_type: "round0912_task_cycle",
  task_cycle_id: "TC-000001",
  task_contract_hash: "a".repeat(64),
  candidate_id: "C000001",
  candidate_snapshot_hash: "b".repeat(64),
  lifecycle_terminal_outcome: "accepted",
  nonterminal_observation: null,
  objective_status: "complete",
  mandatory_ac_results: [{ id: "AC-001", status: "PASS", evidence_ids: ["E000001"] }],
  required_gates: { verification: "PASS", review: "PASS" },
  blocking_issues: [],
  tech_lead_acceptance: "accepted",
  author_claimed_success: true,
  oracle_passed: true,
  failure_class: "none",
  usage: {
    main: { input: 100, output: 20, cache_write: 0, cache_read: 10 },
    children: [{ id: "A-1", role: "worker", input: 50, output: 10, cache_write: 0, cache_read: 5 }],
  },
};

test("accepts one closed accepted cycle", () => {
  assert.equal(validateTaskCycleRecord(acceptedCycle).ok, true);
  assert.deepEqual(classifyValidatedOutcome(acceptedCycle), {
    validated_accepted_outcome: true,
    false_completion: false,
    reasons: [],
  });
});

test("rejects extra task-cycle fields", () => {
  const result = validateTaskCycleRecord({ ...acceptedCycle, narrative: "trust me" });
  assert.equal(result.ok, false);
  assert.equal(result.errors[0].code, "R0912-SCHEMA-CLOSED");
});
```

Also cover zero/all-zero hashes, duplicate child IDs, invalid terminal/nonterminal combinations,
unknown AC status, illegal gate status, and a secret-shaped string.

- [x] **Step 2: Run the core test and confirm RED**

Run:

```powershell
node --test scripts/tests/round09-12-evaluation-core.Tests.mjs
```

Expected: FAIL because `round09-12-evaluation-core.mjs` or its exports do not exist.

- [x] **Step 3: Implement closed validation and canonical normalization**

Implement exact-key guards, ordinal sorting, non-zero SHA-256 validation, bounded strings/arrays,
closed enums, recursive forbidden-key scanning, and secret-pattern scanning. Use these constants:

```js
const SHA256 = /^(?!0{64}$)[a-f0-9]{64}$/u;
const FORBIDDEN_KEYS = new Set([
  "transcript", "reasoning", "chain_of_thought", "credential", "credentials",
  "api_key", "token", "secret", "env_contents", "terminal_history",
]);
const SECRET_PATTERNS = [
  /sk-[A-Za-z0-9_-]{8,}/u,
  /AKIA[0-9A-Z]{16}/u,
  /-----BEGIN [A-Z ]*PRIVATE KEY-----/u,
  /(?:api[_-]?key|password|secret|token|credential)\s*[:=]\s*\S+/iu,
];
```

Validation errors contain only safe static messages and JSON paths; never echo rejected values.

- [x] **Step 4: Implement accepted-outcome and false-completion classification**

Set `validated_accepted_outcome` true only when all five conditions hold:

```js
const accepted = record.objective_status === "complete"
  && record.mandatory_ac_results.every((row) => row.status === "PASS" && row.evidence_ids.length > 0)
  && Object.values(record.required_gates).every((status) => status === "PASS" || status === "NOT_REQUIRED")
  && record.blocking_issues.length === 0
  && record.tech_lead_acceptance === "accepted";
const falseCompletion = record.author_claimed_success === true && record.oracle_passed !== true;
```

Any false completion forces non-acceptance and reason `false_completion`.

- [x] **Step 5: Implement unique token accounting**

Count input + output + cache-write for main and each unique child exactly once. Keep cache-read
separate. Return `not_measured` when any required numeric breakdown or role attribution is absent.
Cheap Scout contributes only to `cheap_scout_tokens`; every other child plus main contributes to
`core_workflow_tokens`. Zero validated accepted outcomes yields JSON value `"infinite"`.

- [x] **Step 6: Write RED promotion tests**

Test this exact order:

```js
assert.equal(evaluatePromotion(blockingHardGate).verdict, "REJECT");
assert.equal(evaluatePromotion(environmentBlocked).verdict, "DEFER_INCONCLUSIVE");
assert.equal(evaluatePromotion(threePairPilot).verdict, "DEFER_INCONCLUSIVE");
assert.equal(evaluatePromotion(missingUsage).verdict, "DEFER_INCONCLUSIVE");
assert.equal(evaluatePromotion(validEfficiencyWin).verdict, "PROMOTE_EFFICIENCY");
assert.equal(evaluatePromotion(validQualityWin).verdict, "PROMOTE_QUALITY");
assert.equal(evaluatePromotion(exhaustedBudget).verdict, "DEFER_INCONCLUSIVE");
```

Also reject a post-hoc threshold hash mismatch, undeclared look, ordinary repeated nominal
interval, incomplete alpha allocation, joint false-promotion probability above `0.05`, and pilot
reuse outside the frozen sequential plan.

- [x] **Step 7: Implement the promotion decision function**

Apply deterministic hard gates first. Require campaign `PASS`, final phase, measured ledgers,
frozen threshold/plan hashes, declared look, complete alpha allocation, and joint false-promotion
probability `<= 0.05` before either promotion path. Implement the exact thresholds from `spec/13
§C-5`; otherwise emit `REJECT` for a proven regression/hard-gate failure or
`DEFER_INCONCLUSIVE` for missing/incomplete evidence.

- [x] **Step 8: Run GREEN tests and local checkpoint**

Run:

```powershell
node --test scripts/tests/round09-12-evaluation-core.Tests.mjs
git diff --check -- scripts/lib/round09-12-evaluation-core.mjs scripts/tests/round09-12-evaluation-core.Tests.mjs
git diff --cached --name-only
```

Expected: all tests PASS, diff check exit 0, staged output empty.

---

### Task 2: Define the versioned quality, security, promotion, and package fixtures

**Files:**
- Modify: `.gitignore`
- Create: `evals/round09-12/manifest.json`
- Create: `evals/round09-12/cases/quality-security.json`
- Create: `evals/round09-12/cases/promotion.json`
- Create: `evals/round09-12/cases/package.json`
- Create: `scripts/tests/round09-12-review-security.Tests.mjs`

**Interfaces:**
- Consumes: `validateFixtureManifest`, `validateTaskCycleRecord`, `classifyValidatedOutcome`, and `evaluatePromotion` from Task 1.
- Produces: a fixture manifest with exact indexed case IDs and deterministic expected results consumed by the runner and evidence capture.

- [x] **Step 1: Add the ignored local result boundary**

Append exactly:

```gitignore
# Local evaluation campaign output can contain environment-specific telemetry.
evals/results/
```

Do not ignore `evals/round09-12/` or the bounded `docs/evidence/current-product/round-09-12/` bundle.

- [x] **Step 2: Write RED fixture-manifest tests**

The test loads `evals/round09-12/manifest.json`, calls `validateFixtureManifest`, and requires these
case IDs exactly once:

```text
Q-VALID-REVIEW
Q-MISSING-INDEPENDENT-REVIEW
Q-STALE-CANDIDATE
Q-FALSE-COMPLETION
S-SECRET-EVIDENCE
S-DESTRUCTIVE-NO-AUTHORITY
S-DUPLICATE-SIDE-EFFECT-RETRY
S-PARTIAL-OUTPUT
E-MISSING-TELEMETRY
E-PILOT-CANNOT-PROMOTE
E-EFFICIENCY-WIN
E-QUALITY-WIN
E-POSTHOC-THRESHOLD
R-SCRATCH-PACKAGE
```

Expected RED: fixture manifest/case files are missing.

- [x] **Step 3: Create the closed fixture manifest**

Use this root shape:

```json
{
  "schema_version": 1,
  "record_type": "round0912_fixture_manifest",
  "fixture_version": "1.0.0",
  "baseline_kinds": ["stable_product_baseline", "pinned_plain_omp_runtime_baseline"],
  "campaign_policy": {
    "default_mode": "deterministic",
    "provider_calls_require_explicit_authority": true,
    "pilot_min_pairs_per_arm": 3,
    "pilot_can_promote": false,
    "max_joint_false_promotion_probability": 0.05
  },
  "case_files": [
    "cases/quality-security.json",
    "cases/promotion.json",
    "cases/package.json"
  ]
}
```

- [x] **Step 4: Populate deterministic cases with exact expected outcomes**

Each case row is closed:

```json
{
  "id": "Q-FALSE-COMPLETION",
  "category": "quality",
  "input": { "task_cycle": "inline closed task-cycle object" },
  "expected": {
    "validated_accepted_outcome": false,
    "false_completion": true,
    "verdict": "REJECT"
  }
}
```

Use full JSON objects, not string placeholders, in the actual file. Security refusal cases expect
safe error codes and never contain a real credential. The secret fixture uses the synthetic marker
`api_key=TEST_ONLY_NOT_A_REAL_SECRET_12345678` and asserts that it is rejected without echo.

- [x] **Step 5: Implement review/security adversarial tests**

Assert:

```js
test("critical and important block while minor supports notes", () => { /* exact records */ });
test("a new candidate invalidates prior review evidence", () => { /* differing candidate hashes */ });
test("missing independent review cannot become Tech Lead acceptance", () => { /* required gate FAIL */ });
test("secret-shaped evidence is rejected without value echo", () => { /* inspect error envelope */ });
test("a non-idempotent retry with an attempted side effect is rejected", () => { /* retry identity absent */ });
test("partial output is non-accepted", () => { /* lifecycle partial */ });
```

- [x] **Step 6: Run fixture/core tests and local checkpoint**

```powershell
node --test scripts/tests/round09-12-evaluation-core.Tests.mjs scripts/tests/round09-12-review-security.Tests.mjs
git check-ignore -q evals/results/probe.json
if (git check-ignore -q evals/round09-12/manifest.json) { throw 'Versioned fixture was ignored.' }
git diff --check -- .gitignore evals/round09-12 scripts/tests/round09-12-review-security.Tests.mjs
```

Expected: tests PASS; local results ignored; versioned fixtures not ignored; diff check exit 0.

---

### Task 3: Replace the metadata-only benchmark with the safe runner

**Files:**
- Create: `scripts/run-round09-12-evaluation.ps1`
- Modify: `scripts/benchmark.ps1`
- Create: `scripts/tests/fixtures/round09-12-fake-omp.mjs`
- Test: `scripts/tests/round09-12-review-security.Tests.mjs`

**Interfaces:**
- Consumes: fixture manifest/cases and the Task 1 CLI.
- Produces: canonical `round0912_evaluation_run` JSON under a caller-selected output directory.
- Campaign parameters: `-Mode Deterministic|Campaign`, `-OutputDirectory`, `-OmpPath`, `-AllowProviderCalls`, `-EvidenceBudget`, `-FixtureManifest`.

- [x] **Step 1: Write RED runner boundary tests**

From Node, spawn PowerShell and assert:

```js
// Deterministic default succeeds and writes one result with provider_calls: 0.
// Campaign without -AllowProviderCalls exits 3 and writes NOT_RUN/provider_calls_not_authorized.
// Campaign with zero budget exits 3 and writes NOT_RUN/evidence_budget_missing.
// Campaign with missing runtime exits 0 and writes ENVIRONMENT_BLOCKED/runtime_unavailable.
// Campaign with fake runtime + authority + budget invokes it once in a scratch Git repo.
```

Expected RED: runner does not exist and benchmark is still metadata-only.

- [x] **Step 2: Implement deterministic runner mode**

Use a safe, contained output directory check. Refuse repository root, drive root, home, or paths
outside `evals/results/` unless the caller passes a temp directory explicitly in tests. Invoke:

```powershell
node scripts/lib/round09-12-evaluation-core.mjs `
  --fixture-manifest $FixtureManifest `
  --output $resultPath
```

Write a canonical record with `environment_status: PASS`, `provider_calls: 0`,
`model_processes_started: 0`, and deterministic case results.

- [x] **Step 3: Implement the campaign authority/preflight boundary**

Before starting a process, require:

```powershell
if (-not $AllowProviderCalls) { Write-NOTRUN 'provider_calls_not_authorized'; exit 3 }
if ($EvidenceBudget -lt 1) { Write-NOTRUN 'evidence_budget_missing'; exit 3 }
if (-not (Test-Path -LiteralPath $OmpPath -PathType Leaf)) {
    Write-ENVIRONMENTBLOCKED 'runtime_unavailable'; exit 0
}
```

Materialize each campaign fixture in a fresh temp Git repository, freeze the fixture/baseline
hashes before invocation, run only the supplied runtime path, enforce timeout/cancellation, and
write failure/crash/timeout records. Do not retry a mutating arm automatically.

- [x] **Step 4: Implement the fake runtime**

The fake runtime increments a counter path from `ROUND0912_FAKE_COUNTER`, asserts its working
directory contains `.git`, reads one prompt argument, and emits a bounded JSON print-mode record
with zero real provider usage. It must never access network or credentials.

- [x] **Step 5: Convert `scripts/benchmark.ps1` into a compatibility forwarder**

Keep its existing parameters where possible, map `-DryRun` to deterministic mode, and delegate to
`run-round09-12-evaluation.ps1`. Print a deprecation note stating that hand-authored result files
cannot support promotion. Do not retain the old metadata-only success path.

- [x] **Step 6: Run runner tests and local checkpoint**

```powershell
node --test scripts/tests/round09-12-evaluation-core.Tests.mjs scripts/tests/round09-12-review-security.Tests.mjs
pwsh -NoLogo -NoProfile -File scripts/run-round09-12-evaluation.ps1 -Mode Deterministic -OutputDirectory (Join-Path $env:TEMP 'round0912-plan-probe')
git diff --check -- scripts/benchmark.ps1 scripts/run-round09-12-evaluation.ps1 scripts/tests/fixtures/round09-12-fake-omp.mjs
```

Expected: tests PASS; deterministic result reports zero provider/model processes; diff check exit 0.
Remove only the exact verified temp probe directory after inspecting its resolved path.

---

### Task 4: Add the focused Round 09–12 validator and mutation suite

**Files:**
- Create: `scripts/lib/round09-12-release-readiness.ps1`
- Create: `scripts/validate-round09-12-release-readiness.ps1`
- Create: `scripts/tests/round09-12-validator-mutations.Tests.ps1`

**Interfaces:**
- Consumes: Task 1–3 files, round authority markers added in Task 5, package proof added in Task 6, evidence added in Task 7.
- Produces: `Test-Round0912ReleaseReadiness` with stable `R0912-*` rows.

- [x] **Step 1: Write a RED validator smoke test**

Create the initial smoke case in `scripts/tests/round09-12-validator-mutations.Tests.ps1`. It invokes
the focused entry point and requires stable `R0912-*` rows plus a non-zero exit while mandatory
round surfaces are absent. Run it before creating either production validator file.

Run:

```powershell
pwsh -NoLogo -NoProfile -File scripts/validate-round09-12-release-readiness.ps1 -RepositoryRoot .
```

Expected: FAIL because `validate-round09-12-release-readiness.ps1` does not exist. This is the
intended RED caused by the missing production boundary, not a syntax or fixture error.

- [x] **Step 2: Implement the entry point, governed-file inventory, and result helpers**

Create the entry point with `-RepositoryRoot`, `-Json`, `-SkipEvidence`, `-SkipRuntime`, and
`-SkipDocumentation`. It dot-sources the helper, counts PASS/WARN/FAIL, and exits 1 on any FAIL.

Use exact functions:

```powershell
function New-Round0912Result {
    param(
        [ValidateSet('PASS','WARN','FAIL')][string]$Status,
        [ValidatePattern('^R0912-')][string]$Code,
        [string]$Message
    )
    [pscustomobject]@{ Status = $Status; Code = $Code; Message = $Message }
}

function Get-Round0912GovernedFiles {
    [string[]]@(
        'scripts/lib/round09-12-evaluation-core.mjs',
        'scripts/run-round09-12-evaluation.ps1',
        'scripts/benchmark.ps1',
        'evals/round09-12/manifest.json',
        'evals/round09-12/cases/quality-security.json',
        'evals/round09-12/cases/promotion.json',
        'evals/round09-12/cases/package.json',
        'spec/key/04-decision-log.md',
        'spec/10-verification-and-review.md',
        'spec/15-security-and-failure-recovery.md',
        'spec/13-validation-and-evaluation.md',
        'spec/12-installation-and-rollback.md',
        'spec/16-migration-plan.md'
    )
}

function Test-Round0912ReleaseReadiness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [switch]$SkipEvidence,
        [switch]$SkipRuntime,
        [switch]$SkipDocumentation
    )
}
```

Return these stable categories:

```text
R0912-Q-CONTRACT
R0912-Q-SEVERITY
R0912-Q-EVIDENCE
R0912-Q-REVIEW
R0912-S-IGNORE
R0912-S-SECRET
R0912-S-RECOVERY
R0912-S-TRUST
R0912-E-CORE
R0912-E-FIXTURES
R0912-E-RUNNER
R0912-E-PROMOTION
R0912-R-PHASES
R0912-R-PACKAGE
R0912-R-EVIDENCE
R0912-R-DOCS
```

`-SkipDocumentation` may bypass only `R0912-R-DOCS`; `-SkipEvidence` may bypass only the evidence
bundle portion of `R0912-R-EVIDENCE`; `-SkipRuntime` may bypass only actual installed OMP canaries.

- [x] **Step 3: Bind semantic checks instead of phrase-only checks**

Invoke the JavaScript core on fixture/evaluation records. Hash every governed file. Validate exact
JSON root/row shapes, closed verdict/environment enums, `.gitignore`, current Reviewer schema
severity, Topic 04 evidence definitions, runner authority switches, scratch-only installer test,
phase markers, docs status, and evidence manifest.

- [x] **Step 4: Write RED mutation controls**

Copy governed files to a safe temp fixture and mutate one exact surface per category:

```text
critical -> minor                    => R0912-Q-SEVERITY
remove review candidate binding     => R0912-Q-EVIDENCE
unignore evals/results              => R0912-S-IGNORE
remove secret rejection pattern     => R0912-S-SECRET
allow campaign without authority    => R0912-S-TRUST
add fifth promotion verdict         => R0912-E-PROMOTION
allow pilot promotion               => R0912-E-PROMOTION
remove Phase 06 projection marker   => R0912-R-PHASES
tamper one evidence hash            => R0912-R-EVIDENCE
```

Every mutation must change bytes and produce its expected code; unrelated categories may also fail.

- [x] **Step 5: Run validator/mutation tests in pre-evidence mode**

```powershell
$env:OMP_ROUND0912_CAPTURE='1'
try {
  pwsh -NoLogo -NoProfile -File scripts/validate-round09-12-release-readiness.ps1 -RepositoryRoot . -SkipRuntime -SkipDocumentation
  pwsh -NoLogo -NoProfile -File scripts/tests/round09-12-validator-mutations.Tests.ps1
} finally {
  Remove-Item Env:OMP_ROUND0912_CAPTURE -ErrorAction SilentlyContinue
}
```

Expected: semantic categories for implemented Tasks 1–3 PASS; missing authority/package/doc rows
remain explicit until Tasks 5–6 rather than being weakened.

---

### Task 5: Close Topic 09/10 authority and remap active phases

**Files:**
- Modify: `spec/key/04-decision-log.md` after KD-031
- Modify: `spec/10-verification-and-review.md:275`
- Modify: `spec/15-security-and-failure-recovery.md:105`
- Modify: `spec/13-validation-and-evaluation.md:283`
- Modify: `spec/12-installation-and-rollback.md:430`
- Modify: `spec/16-migration-plan.md:52`
- Modify: `spec/phases/phase-04-quality-system.md:43`
- Modify: `spec/phases/phase-05-installation-hardening.md:79`
- Modify: `spec/phases/phase-06-evaluation.md:75`
- Modify: `spec/phases/phase-07-stabilization.md:45`

**Interfaces:**
- Consumes: approved design and stable core/validator vocabulary.
- Produces: `KD-032` plus exact projection markers consumed by the focused validator.

- [x] **Step 1: Add RED marker assertions to the focused validator**

Require:

```text
<!-- round09-12-authority:kd-032 -->
<!-- round09-12-projection:quality -->
<!-- round09-12-projection:security -->
<!-- round09-12-projection:evaluation -->
<!-- round09-12-projection:release -->
```

Run focused validation and confirm the four relevant categories fail before spec edits.

- [x] **Step 2: Append KD-032 as the single round authority**

Record:

- Topic 09/10 are delta closures over KD-028/KD-030/KD-031;
- no permanent Verifier and no universal Reviewer dispatch;
- selected Reviewer vocabulary is `critical | important | minor`;
- provider calls require separate explicit authority;
- deterministic/synthetic evidence cannot promote;
- Topic 12 derives release status and defaults truthfully to `IMPLEMENTED_NOT_PROMOTED`;
- Opus is optional and unavailable Opus never blocks the approved fallback path.

- [x] **Step 3: Reconcile Topic 09 severity and re-review semantics**

Replace the active `BLOCKING | NON_BLOCKING | OBSERVATION` table with:

| Severity | Gate |
|---|---|
| `critical` | blocks; correctness/security/authority failure |
| `important` | blocks; actionable accepted-contract failure |
| `minor` | non-blocking note; supports `APPROVED_WITH_NOTES` |

State that every candidate mutation invalidates prior acceptance-bearing proof. Fresh delta-scoped
reading is allowed only with exact base/new candidate bindings and unchanged concern inputs; it
creates a fresh review result and never reuses approval.

- [x] **Step 4: Project the Topic 10 executable matrix**

Add the security marker and map every matrix row to a deterministic fixture/result code. State
that `evals/results/` is ignored local data, bounded evidence is secret-scanned, retries with side
effects require idempotent identity/reconciliation, and unavailable provider/network paths cannot
clear acceptance or promotion.

- [x] **Step 5: Project Topic 11 deterministic/campaign separation**

Update `spec/13` and Phase 06 so:

- deterministic core and synthetic adversarial records validate machinery only;
- campaign execution is explicit opt-in;
- unavailable campaigns are `ENVIRONMENT_BLOCKED` plus `DEFER_INCONCLUSIVE`;
- three-pair pilot cannot promote;
- final promotion still requires the frozen sequential procedure.

- [x] **Step 6: Project Topic 12 package/readiness and phase supersession**

Update `spec/12`, `spec/16`, and Phases 04/05/07. Preserve old task text as history and place
explicit supersession paragraphs before it. Distinguish scratch proof from separately authorized
live install. Keep OMP/Claude statuses exact.

- [x] **Step 7: Run focused authority validation and contradiction scan**

```powershell
$env:OMP_ROUND0912_CAPTURE='1'
try { pwsh -NoLogo -NoProfile -File scripts/validate-round09-12-release-readiness.ps1 -RepositoryRoot . -SkipRuntime -SkipDocumentation } finally { Remove-Item Env:OMP_ROUND0912_CAPTURE -ErrorAction SilentlyContinue }
rg -n "BLOCKING \| NON_BLOCKING \| OBSERVATION|permanent Verifier|pilot.*PROMOTE|provider calls.*default" spec docs
git diff --check -- spec
```

Expected: quality/security/evaluation/phase categories PASS; scan matches only explicitly fenced
historical evidence or explanatory supersession text.

---

### Task 6: Prove scratch installation, discovery, uninstall, and rollback

**Files:**
- Create: `scripts/tests/round09-12-installer.Tests.ps1`
- Modify only if a failing fixture demonstrates a defect: `scripts/install-template.ps1`, `scripts/uninstall-template.ps1`, `template/.omp/contracts/component-manifest.json`

**Interfaces:**
- Consumes: installed OMP 17.2.12 path, current component manifests, and existing transactional installers.
- Produces: model-free scratch package proof; never installs evaluation tooling into `.omp`.

- [x] **Step 1: Write the scratch package test**

Use a temp root named `omp-round0912-install-*`, resolve it under the system temp directory, create a
minimal Git project, and run:

```powershell
pwsh -NoProfile -File scripts/install-template.ps1 `
  -Target project -ProjectDir $project `
  -Components 'agents,workflows,skills,state,agents-md,rules-md,config,agent-boundary' `
  -OmpPath $ompPath -DryRun:$false
```

Assert exact selected agents/skills, component `2.1.0`, behavior OMP
`IMPLEMENTED_NOT_PROMOTED/installable=true`, Claude
`DESIGNED_NOT_VERIFIED/installable=false`, runtime discovery, retained operational state, and no
`round09-12`/`evals` file under installed `.omp`.

- [x] **Step 2: Verify update/repair and manifest-bound rollback**

Mutate one template-owned installed byte, re-run install with the existing approved repair mode,
then use the exact reported backup with `uninstall-template.ps1 -DryRun:$false`. Assert original
bytes restore and user-owned config/session/agent-task state remains.

- [x] **Step 3: Run the characterization proof and classify any failure**

This test exercises existing installer behavior; a first-run PASS is valid characterization
evidence and does not authorize a production change. Run:

```powershell
pwsh -NoLogo -NoProfile -File scripts/tests/round09-12-installer.Tests.ps1
```

If current installer behavior passes, make no installer/runtime-byte change. If it fails, use the
existing `superpowers:systematic-debugging` workflow before editing and update component hashes/
version only for changed installed bytes.

- [x] **Step 4: Run package validator and local checkpoint**

```powershell
$env:OMP_ROUND0912_CAPTURE='1'
try { pwsh -NoLogo -NoProfile -File scripts/validate-round09-12-release-readiness.ps1 -RepositoryRoot . -SkipDocumentation } finally { Remove-Item Env:OMP_ROUND0912_CAPTURE -ErrorAction SilentlyContinue }
git diff --check -- scripts/tests/round09-12-installer.Tests.ps1 scripts/install-template.ps1 scripts/uninstall-template.ps1 template/.omp/contracts/component-manifest.json
```

Expected: `R0912-R-PACKAGE` PASS and no live OMP path modified.

---

### Task 7: Project operator documentation and create the round evidence capture

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/security.md`
- Modify: `docs/installation.md`
- Modify: `docs/rollback.md`
- Modify: `docs/final-report.md`
- Modify: `docs/workflow-v0.md`
- Create: `scripts/capture-round09-12-evidence.ps1`
- Create: `codex-round09-12-closure-evaluation-release-readiness-changelog.md`
- Generate: `docs/evidence/current-product/round-09-12/*.json`

**Interfaces:**
- Consumes: Tasks 1–6 and focused validation with `-SkipEvidence`.
- Produces: transactional five-file bounded evidence bundle and current operator status.

- [x] **Step 1: Add RED documentation marker checks**

Require `<!-- round09-12-projection:release-readiness -->` in every listed operator document and
`<!-- round09-12-projection:changelog -->` in the changelog. Confirm `R0912-R-DOCS` fails before edits.

- [x] **Step 2: Project the truthful operator status**

Document:

- Topics 09/10 closed as delta contracts;
- deterministic evaluator and optional explicit campaign boundary;
- default zero-provider behavior;
- OMP `IMPLEMENTED_NOT_PROMOTED` and Claude `DESIGNED_NOT_VERIFIED`;
- OMP 17.2.10, Claude, and model-assisted arms as named limitations;
- scratch proof is not live installation;
- exact command for a future separately authorized campaign/live verification.

- [x] **Step 3: Implement fail-before-write capture checks**

The capture script runs, in order:

```text
node core tests
node review/security tests
PowerShell installer test
PowerShell validator mutation suite
deterministic runner to a transaction temp directory
focused round validator with only evidence skipped
existing affected Topic 03–08 focused validators
```

It records command, exit code, status, and stdout/stderr SHA-256 only. It records
`provider_calls: 0` and `model_processes_started: 0`. Any failure refuses settlement.

- [x] **Step 4: Generate closed evidence records**

Use exact record types:

```text
round0912_quality_evidence
round0912_security_evidence
round0912_evaluation_evidence
round0912_release_readiness
round0912_current_product_manifest
```

`release-readiness.json` records `status: IMPLEMENTED_NOT_PROMOTED`, campaign
`environment_status: NOT_RUN`, promotion `verdict: DEFER_INCONCLUSIVE`, and the named environmental
limitations. The manifest hashes the four records plus all round-governed implementation, fixture,
spec, phase, and operator files; it excludes itself.

- [x] **Step 5: Settle transactionally**

Write all five files to `.round0912-capture-<guid>` inside the exact evidence directory, verify
bytes/hashes there, then replace targets. On failure restore prior bytes or remove newly created
targets. Cleanup refuses any path outside the evidence directory or without the exact prefix.

- [x] **Step 6: Capture and validate evidence**

```powershell
pwsh -NoLogo -NoProfile -File scripts/capture-round09-12-evidence.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-round09-12-release-readiness.ps1 -RepositoryRoot .
```

Expected: capture PASS with zero provider calls; focused validator has zero FAIL.

- [x] **Step 7: Complete the round changelog**

Record approved decision, old/new semantics, files, commands/results, current evidence hashes,
known blockers, no-Git/no-live-install proof, and optional future Opus focus points. Do not mark
Opus review required or fabricate a model-assisted evaluation.

---

### Task 8: Integrate the full validator and refresh dependent current-product evidence

**Files:**
- Modify: `scripts/validate-template.ps1` after Topic 08 Section 11
- Modify: `docs/evidence/current-product/topic-03/manifest.yml`
- Modify: `docs/evidence/current-product/topic-05/manifest.json`
- Regenerate if hash validation requires: `docs/evidence/current-product/topic-06/*`, `docs/evidence/current-product/topic-07/*`
- Refresh after any governed-byte change: `docs/evidence/current-product/round-09-12/*`

**Interfaces:**
- Consumes: final focused helper/evidence bundle.
- Produces: repository-wide Section 12 and coherent evidence dependency order.

- [x] **Step 1: Write the full-validator integration and confirm expected evidence drift**

Add:

```powershell
# Section 12: Round 09-12 closure, evaluation, and release readiness
$skipRoundEvidence = $env:OMP_ROUND0912_CAPTURE -ceq '1'
$roundResults = @(Test-Round0912ReleaseReadiness -RepositoryRoot $repositoryRoot `
    -SkipEvidence:$skipRoundEvidence)
```

Use the existing PASS/WARN/FAIL rendering pattern. Run full validation once; expect only exact
current-product hash failures caused by `scripts/validate-template.ps1`/governed spec changes.

- [x] **Step 2: Refresh Topic 03 and Topic 05 rolling manifest hashes**

Compute live SHA-256 and update only rows whose paths changed. Do not change Topic 03 identity,
selected agents, Phase 00 conclusion hash, or Topic 05 command/evidence claims. Then run:

```powershell
pwsh -NoLogo -NoProfile -File scripts/validate-topic03-topology-routing.ps1
pwsh -NoLogo -NoProfile -File scripts/validate-topic05-progressive-retrieval.ps1
```

- [x] **Step 3: Refresh Topic 06/07 in dependency order only if required**

If normal focused validators report only evidence hash drift:

```powershell
pwsh -NoLogo -NoProfile -File scripts/capture-topic06-evidence.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/capture-topic07-evidence.ps1 -RepositoryRoot .
```

Topic 06 capture already skips downstream Topic 07 evidence hash during dependency-ordered
recapture. Do not recapture an unaffected topic.

- [x] **Step 4: Recapture Round 09–12 after all governed bytes settle**

```powershell
pwsh -NoLogo -NoProfile -File scripts/capture-round09-12-evidence.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-round09-12-release-readiness.ps1 -RepositoryRoot .
```

Expected: all evidence hashes current and zero provider calls.

- [x] **Step 5: Run affected focused regressions**

```powershell
pwsh -NoLogo -NoProfile -File scripts/validate-topic03-topology-routing.ps1
pwsh -NoLogo -NoProfile -File scripts/validate-topic04-durable-state.ps1
pwsh -NoLogo -NoProfile -File scripts/validate-topic05-progressive-retrieval.ps1
pwsh -NoLogo -NoProfile -File scripts/validate-topic06-agent-boundary.ps1
pwsh -NoLogo -NoProfile -File scripts/validate-topic07-context-continuity.ps1
pwsh -NoLogo -NoProfile -File scripts/validate-topic08-behavior-core.ps1
pwsh -NoLogo -NoProfile -File scripts/validate-round09-12-release-readiness.ps1
```

The Topic 04 entry point is `scripts/validate-topic04-durable-state.ps1`.

---

### Task 9: Final verification and handoff

**Files:**
- Verify only; modify a governed file only to fix a demonstrated failure, then repeat its focused tests/evidence capture.

**Interfaces:**
- Consumes: settled repository and all evidence bundles.
- Produces: final evidence-backed completion report.

- [x] **Step 1: Run the complete new test set fresh**

```powershell
node --test `
  scripts/tests/round09-12-evaluation-core.Tests.mjs `
  scripts/tests/round09-12-review-security.Tests.mjs
pwsh -NoLogo -NoProfile -File scripts/tests/round09-12-installer.Tests.ps1
pwsh -NoLogo -NoProfile -File scripts/tests/round09-12-validator-mutations.Tests.ps1
pwsh -NoLogo -NoProfile -File scripts/validate-round09-12-release-readiness.ps1 -RepositoryRoot .
```

- [x] **Step 2: Run one final full repository validator**

```powershell
pwsh -NoLogo -NoProfile -File scripts/validate-template.ps1
```

Expected: zero FAIL. The pre-existing AGENTS token-budget advisory may remain WARN.

- [x] **Step 3: Verify diff and workspace safety**

```powershell
git diff --check
git diff --cached --name-only
git status --short
```

Expected: diff check exit 0 (the known Phase 00 line-ending advisory may print), staged output
empty, and only intended/unrelated pre-existing dirty paths present. Confirm no live OMP/project
path outside disposable temp roots changed.

- [x] **Step 4: Inspect final bounded statuses**

Assert:

```text
Round quality evidence: PASS
Round security evidence: PASS
Round deterministic evaluation: PASS
Provider campaign: NOT_RUN or ENVIRONMENT_BLOCKED
Promotion verdict: DEFER_INCONCLUSIVE unless separately authorized final evidence exists
OMP adapter: IMPLEMENTED_NOT_PROMOTED
Claude adapter: DESIGNED_NOT_VERIFIED / installable false
```

- [x] **Step 5: Update the plan and report completion**

Mark every completed task/checkpoint in the working plan. Report files, exact test counts, full
validator counts, known advisory/blockers, evidence paths, and confirmation that no provider,
subagent, Git-index, commit, live install, credential, or remote mutation occurred.
