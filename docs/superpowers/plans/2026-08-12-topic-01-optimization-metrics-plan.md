# Topic 01 Optimization Metrics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Project the approved quality-first optimization contract into the canonical specs,
phase plans, concise documentation, changelog, and an adversarial Opus review packet.

**Architecture:** `spec/key/03-token-quality-model.md` owns the decision semantics and
`spec/13-validation-and-evaluation.md` owns the executable measurement and promotion contract.
All other files are projections that reference those authorities instead of inventing local
variants. This topic changes planning/documentation only; the Phase 06 harness remains future
implementation work.

**Tech Stack:** Markdown specifications, YAML contract examples, PowerShell validation,
Git read-only inspection.

## Global Constraints

- Current-session user decisions outrank prior topology and unnumbered metric prose.
- Quality gates precede accepted-outcome rate, which precedes core-token efficiency; latency is
  only a final tie-breaker.
- `cheap_scout_tokens` are telemetry only and never a weighted or gating input.
- Preserve all pre-existing dirty workspace changes; patch only named sections.
- Do not modify `template/`, runtime scripts, fixtures, Phase 00 evidence, historical packets,
  the DNA worktree, `_research/upstreams`, registry, or license files.
- Do not change the phase DAG or Phase 00 authority state.
- Do not stage, commit, branch, push, or create a pull request.
- Main Agent is the only writer for this scope; execute inline with
  `superpowers:executing-plans`.

---

### Task 1: Establish the metric decision authority

**Files:**
- Modify: `spec/key/03-token-quality-model.md:1-45`
- Modify: `spec/key/04-decision-log.md:830-end`

**Interfaces:**
- Consumes: the approved design record at
  `docs/superpowers/specs/2026-08-12-topic-01-optimization-metrics-design.md`.
- Produces: the terms `validated accepted outcome`, `core_workflow_tokens`,
  `cheap_scout_tokens`, `raw_total_tokens`, dual baselines, and the two-path promotion rule.

- [x] **Step 1: Capture the pre-edit semantic baseline**

Run:

```powershell
rg -n "total_tokens / accepted_outcomes|primary metric|false-completion|baseline|promotion" `
  spec/key/03-token-quality-model.md spec/key/04-decision-log.md
```

Expected: the old two-term formula exists and no Topic 01 decision entry exists.

- [x] **Step 2: Replace the old objective with the approved lexicographic contract**

Write Section A so it defines, in order: hard quality gates, validated accepted-outcome rate,
core workflow tokens per validated accepted outcome, and latency tie-breaking. Include the full
task-cycle boundary, three token ledgers, zero-denominator behavior, dual-baseline roles, and
promotion thresholds. Keep the existing token-lifetime analysis in Sections B-H unchanged.

- [x] **Step 3: Append an immutable decision-log entry**

Add `KD-024` with `Decision`, `Grounds`, `Because`, `Rejected`, `Reverse if`, and `Touches`.
Record that it supersedes the unnumbered `total_tokens / accepted_outcomes` and
equal-or-lower-token semantics; do not rewrite any earlier KD entry.

- [x] **Step 4: Verify authority terminology**

Run:

```powershell
rg -n "core_workflow_tokens|cheap_scout_tokens|raw_total_tokens|accepted_with_waiver|KD-024" `
  spec/key/03-token-quality-model.md spec/key/04-decision-log.md
```

Expected: every approved term appears in the authority layer and `KD-024` appears exactly once.

---

### Task 2: Make the evaluation spec executable and unambiguous

**Files:**
- Modify: `spec/13-validation-and-evaluation.md:165-268`

**Interfaces:**
- Consumes: Task 1 terminology and thresholds.
- Produces: the canonical accepted-outcome state machine, task-cycle record fields, baseline
  identities, paired A/B protocol, and promotion verdicts consumed by Phase 06 and PR-7.

- [x] **Step 1: Record the stale-contract failure before editing**

Run:

```powershell
rg -n "input/output/cached tokens|Primary metric|No template vs Workflow|Stable disagreement" `
  spec/13-validation-and-evaluation.md
```

Expected: the file lacks separate core/Scout/raw ledgers, lacks accepted terminal-state
semantics, and has no promotion gate.

- [x] **Step 2: Add the accepted-outcome and accounting contract**

Define the five required acceptance conditions, non-accepted terminal states,
`accepted_with_waiver`, the full task-cycle boundary, failed-cycle accounting, the three token
ledgers, zero-denominator behavior, and latency telemetry/reliability semantics.

- [x] **Step 3: Replace the single baseline with the dual-baseline protocol**

Define `stable_product_baseline` for every candidate comparison and
`pinned_plain_omp_runtime_baseline` for release/major-architecture checkpoints. Require frozen
OMP/template/fixture/provider/tool identities and recorded supersession on baseline advance.

- [x] **Step 4: Replace the unresolved statistical note with the approved promotion gate**

Keep fresh independent paired runs and counterbalanced order. Define pilot-only `>=3` runs per
arm, adaptive final sampling at 95% confidence, five-percentage-point non-inferiority
uncertainty, 10% efficiency improvement, 10% maximum quality-win core-token regression,
stricter predeclared risk overrides, and defer/reject for inconclusive evidence.

- [x] **Step 5: Extend acceptance criteria**

Add criteria that require automatic accepted-outcome classification, complete failed-cycle
accounting, all three ledgers, frozen dual-baseline identities, and a promotion verdict that a
pilot alone cannot produce.

- [x] **Step 6: Verify the canonical contract**

Run:

```powershell
rg -n "validated_accepted_outcome|core_workflow_tokens|stable_product_baseline|95%|promotion" `
  spec/13-validation-and-evaluation.md
```

Expected: all concepts are present in one operational section with no unresolved disagreement.

---

### Task 3: Synchronize decision-layer and human-facing projections

**Files:**
- Modify: `spec/key/01-dna.md:570-613,667-684`
- Modify: `spec/key/05-coverage-audit.md:147-151`
- Modify: `spec/key/06-investment-thesis.md:41-50,187-194`
- Modify: `spec/key/README.md:70-90`
- Modify: `spec/05-context-and-token-model.md:7-24`
- Modify: `spec/07-retrieval-and-code-understanding.md:179-182`
- Modify: `spec/README.md:120-133,425-448`
- Modify: `docs/token-strategy.md:1-15`

**Interfaces:**
- Consumes: Task 1 authority and Task 2 executable contract.
- Produces: concise references that preserve the same priority order and avoid duplicate local
  promotion formulas.

- [x] **Step 1: Replace ambiguous raw-token wording**

Where these files currently say only “tokens per accepted outcome,” qualify the primary
optimization ledger as core workflow tokens and state that failed cycles remain charged.

- [x] **Step 2: Correct the quality hierarchy**

Make validated accepted-outcome rate the primary quality measure, false completion a hard
safety gate, and model-graded metrics advisory. Do not retain prose that calls false completion
the sole headline quality metric.

- [x] **Step 3: Project the dual baseline without duplicating thresholds**

Update the investment thesis to require both the stable-product baseline and pinned plain-OMP
release baseline. Point exact promotion mechanics to `spec/13 §C`.

- [x] **Step 4: Correct PR-7**

Replace “quality neutral-or-better at equal-or-lower tokens” with clearance of the canonical
two-path promotion gate against the stable baseline plus an acceptable pinned plain-OMP release
comparison. State that `accepted_with_waiver` cannot satisfy PR-7.

- [x] **Step 5: Scan the projections for local semantic drift**

Run:

```powershell
rg -n -i "total_tokens / accepted_outcomes|quality neutral-or-better at equal-or-lower|headline quality metric" `
  spec/key/01-dna.md spec/key/06-investment-thesis.md spec/key/README.md `
  spec/05-context-and-token-model.md spec/README.md docs/token-strategy.md
```

Expected: no stale formula or superseded PR-7 wording remains.

---

### Task 4: Remap Phase 03, Phase 06, and Phase 07 acceptance work

**Files:**
- Modify: `spec/phases/phase-03-context-efficiency.md:80-139,156-184`
- Modify: `spec/phases/phase-06-evaluation.md:118-192`
- Modify: `spec/phases/phase-07-stabilization.md:116-130`

**Interfaces:**
- Consumes: the canonical evaluation contract in Task 2.
- Produces: future implementation tasks and exit criteria that cannot pass with pilot-only,
single-baseline, or raw-total-token evidence.

- [x] **Step 1: Update Phase 03 instrumentation**

Replace `total_tokens` and user-acceptance shorthand with the three ledgers,
`validated_accepted_outcome`, terminal state, acceptance-criteria coverage, failure class,
retries, and latency telemetry. State that Phase 03 measurements are calibration evidence and
cannot themselves promote a candidate before Phase 06 implements the final gate.

- [x] **Step 2: Repair Phase 06 CR-22**

Delete the stale back-to-back/same-session rule. Require fresh independent state,
counterbalanced ordering, frozen identities, pilot-only minimums, and adaptive final evidence.

- [x] **Step 3: Split Phase 06 baseline, metric, and promotion responsibilities**

Make T-06.6 implement both baselines, T-06.7 implement task-cycle accounting and the primary
metric, and add T-06.8 for the hard gates and two valid promotion paths. Update deliverables,
verification, exit criteria, and risks accordingly.

- [x] **Step 4: Make Phase 07 reference PR-7 instead of restating it**

Keep the stable gate ID and canonical source, removing the obsolete equal-or-lower-token
paraphrase.

- [x] **Step 5: Verify phase dependency and criterion consistency**

Run:

```powershell
rg -n "Depends on|Blocks|core_workflow_tokens|pilot|stable_product_baseline|PR-7" `
  spec/phases/phase-03-context-efficiency.md `
  spec/phases/phase-06-evaluation.md `
  spec/phases/phase-07-stabilization.md
```

Expected: the DAG remains Phase 03 -> Phase 06 -> Phase 07 and each projection references the
same metric and gate.

---

### Task 5: Run repository and contradiction validation

**Files:**
- Test: every file modified by Tasks 1-4
- Test: `scripts/validate-template.ps1`

**Interfaces:**
- Consumes: the complete Topic 01 patch.
- Produces: exact command, exit code, and key-output evidence for the changelog and audit packet.

- [x] **Step 1: Scan for superseded semantics**

Run:

```powershell
rg -n -i "total_tokens / accepted_outcomes|quality neutral-or-better at equal-or-lower|back-to-back or in the same session|did the user accept it" `
  spec docs/token-strategy.md
```

Expected: no active top-level spec or concise doc retains the superseded wording. Historical
research and review artifacts are excluded from this scan and remain immutable.

- [x] **Step 2: Scan for required semantics**

Run:

```powershell
rg -n "core_workflow_tokens|cheap_scout_tokens|raw_total_tokens|accepted_with_waiver|stable_product_baseline|pinned_plain_omp" `
  spec/key/03-token-quality-model.md spec/13-validation-and-evaluation.md `
  spec/phases/phase-06-evaluation.md
```

Expected: authority and implementation plan agree on every named field.

- [x] **Step 3: Run the existing template validator**

Run:

```powershell
pwsh -NoProfile -File scripts/validate-template.ps1
```

Expected: exit 0. Record the exact pass/warning/failure summary without treating static success
as runtime evidence.

- [x] **Step 4: Parse and inspect the final diff**

Run:

```powershell
git diff --check
git diff --stat
git diff -- spec/key/03-token-quality-model.md spec/key/04-decision-log.md `
  spec/13-validation-and-evaluation.md spec/phases/phase-03-context-efficiency.md `
  spec/phases/phase-06-evaluation.md spec/phases/phase-07-stabilization.md
```

Expected: no whitespace error, no accidental rewrite, and no unrelated target-file change.

---

### Task 6: Record the change and prepare read-only Opus audit

**Files:**
- Modify: `CHANGELOG.md:Unreleased`
- Create: `codex-topic01-optimization-metrics-changelog-for-opus5.md`
- Create: `opus5-review-packet-codex-topic01-optimization-metrics.md`
- Create: `opus5-review-prompt-codex-topic01-optimization-metrics.md`

**Interfaces:**
- Consumes: final file hashes, diff ledger, validation outputs, approved design, and known
  exclusions.
- Produces: a short product-facing entry, detailed immutable handoff ledger, compact review
  packet, and adversarial prompt. These files do not themselves close Topic 01.

- [x] **Step 1: Add the short Unreleased changelog entry**

Record the quality-first objective, validated accepted-outcome contract, unweighted core/Scout
ledgers, dual baselines, and two-path promotion gate. Do not claim the benchmark harness is
implemented.

- [x] **Step 2: Create the detailed Codex-to-Opus ledger**

Include user-approved decisions, old/new semantics, before/after hashes, files changed, exact
validation commands and results, cross-phase effects, exclusions/non-claims, limitations, and
requested review questions.

- [x] **Step 3: Create the compact packet and adversarial prompt**

Require Opus to audit source authority, internal contradictions, phase dependencies, metric
edge cases, threshold semantics, Cheap Scout simplicity/fallback, and spec/runtime non-claims.
Require evidence-backed findings in `contract-misread`, `actionable`, `trade-off`, or `noise`
categories. The prompt is read-only and prohibits mutation.

- [x] **Step 4: Freeze audit hashes and verify references**

Run:

```powershell
Get-FileHash -Algorithm SHA256 `
  codex-topic01-optimization-metrics-changelog-for-opus5.md, `
  opus5-review-packet-codex-topic01-optimization-metrics.md, `
  opus5-review-prompt-codex-topic01-optimization-metrics.md
```

Expected: every hash embedded by the prompt/packet matches the final file bytes. If embedding a
hash changes a file, hash the dependency in one direction only and document the chain.

- [x] **Step 5: Report the audit gate honestly**

If Claude Opus is not callable from the current environment, report
`opus_audit: PENDING_UNAVAILABLE`, provide the prepared prompt, and do not substitute another
model silently. Topic 01 remains open until findings are adjudicated or the user authorizes a
fallback.

---

### Task 7: Run the user-authorized Codex fallback audit and correct sequential validity

**Files:**
- Create: `codex-peer-review-prompt-topic01-optimization-metrics.md`
- Create: `codex-peer-review-response-topic01-attempt-01.md`
- Create: `codex-peer-review-response-topic01-attempt-02.md`
- Modify: Topic 01 design, decision authority, evaluation authority, Phase 06, and changelog
- Create: a correction ledger plus a fresh Codex review packet/prompt

- [x] **Step 1: Preserve the unavailable Opus gate and obtain explicit fallback authority**

Record that Opus had no usable account/quota and that the user authorized Codex temporarily;
do not rewrite the historical Opus packet or claim an Opus verdict.

- [x] **Step 2: Run a fresh adversarial Codex review and adjudicate findings**

Preserve both attempts. Reject Attempt 01's unsupported hash mismatch after byte-level
controller verification. Accept Attempt 02's adaptive-stopping finding only after checking it
against the written 95% contract.

- [x] **Step 3: Correct adaptive inference without changing approved thresholds**

Require a predeclared jointly sequentially valid procedure with false-promotion probability
at most 5% across interim looks, both win paths, and every promotion-bearing bound. Reject
ordinary per-look intervals and invalid pilot reuse.

- [x] **Step 4: Freeze the corrected snapshot, validate, and rerun Codex audit**

Create a new packet and prompt whose hash chain supersedes only the original semantic snapshot,
not its historical record. Run the reviewer in a disposable copy where byte-level hash commands
are permitted, verify the official workspace is unchanged, and adjudicate the final verdict.
