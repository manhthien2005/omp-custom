# Phase 04 — Quality System

> OPUS PROPOSED SPEC v1 | Make verification and review produce trustworthy evidence.

**Depends on**: phase-02
**Blocks**: phase-06

---

## Objective

Turn the verification and review layer from prose intent into an evidence discipline:
independent verification, diff-first review, risk-based quality gates, and false-positive
control that is actually checkable.

---

## Rationale

The template's core value proposition is "no false completion." That claim currently
rests on prompt wording alone. Phase-02 made the workers run; this phase makes their
output trustworthy — because an orchestration system that confidently reports success
it did not verify is worse than no orchestration at all.

---

## Tasks

### T-04.1 — Enforce Verifier independence

The Verifier must run every verification command fresh in its own session and read
the actual output. It must never infer a pass from the Implementer's report.

Mechanically supported by: separate in-process AgentSession (no shared transcript — CR-08: OMP subagents run on the main thread, not in an OS subprocess),
`autoloadSkills: evidence-before-completion`, and a `verification-result` schema whose
required fields cannot be satisfied without real command output.

**Acceptance**: `verification-result` requires `commands_run` with exit codes and
per-criterion evidence; the Verifier prompt forbids inference; `PASS` is invalid when
any criterion lacks evidence.

### T-04.2 — Enforce failure classification

Every failure classifies as `impl`, `env`, or `flaky`. The three lead to different
actions: fix the code, fix the environment, re-run and investigate nondeterminism.
Without classification, an environment failure gets "fixed" by changing correct code.

**Acceptance**: classification is required for each failure; the prompt defines the
three categories and their distinct consequences.

### T-04.3 — Make review diff-first

The Reviewer reads the diff first and expands only into files the diff touches or
directly implicates. Unbounded "diff context" becomes a full-repository read.

**Acceptance**: the prompt states diff-first with bounded expansion, and names the
expansion trigger (a symbol the diff changes, used elsewhere).

### T-04.4 — Make false-positive control checkable

The Reviewer must, before reporting a finding, confirm: it is present in the current
code (not theoretical), not already handled elsewhere, not excluded by the packet's
scope, and not pre-existing lint output.

**Acceptance**: `false_positive_checks` is a required field; each entry names the
concern and why it was cleared. Findings without evidence are invalid.

### T-04.5 — Wire risk-based quality gates

Gates activate by risk level per the quality-gates policy (LOW: none; MEDIUM:
security; HIGH/CRITICAL: broader). Enabling every gate for every task wastes tokens and
trains the reader to ignore output; enabling none defeats the purpose.

Because there is no policy loader, the matrix is inlined into the Reviewer prompt and
the packet's `quality_gates` field.

**Acceptance**: the default matrix is inlined; disabling a default gate for HIGH or
CRITICAL requires a stated reason.

### T-04.6 — Define blocking semantics

`CHANGES_REQUESTED` requires ≥1 blocking finding; `APPROVED` requires zero. A blocking
finding cannot be waived without addressing it or an explicit, recorded user decision.

**Acceptance**: the decision/finding consistency rule is enforced in the schema and
stated in the prompt.

### T-04.7 — Handle the unvalidated-result case

When `yield` sets `schemaOverridden`, the result bypassed schema validation. The Tech
Lead must treat those fields as unverified and re-check independently.

**Acceptance**: the handling rule appears in the commands and in `10-verification-and-review.md`.

---

## Deliverables

- Verifier prompt and schema enforcing fresh, evidence-backed verification
- Failure classification with distinct consequences
- Diff-first Reviewer with bounded expansion
- Required, checkable false-positive control
- Inlined risk-based gate matrix
- Blocking-decision consistency rules
- Override handling

---

## Verification

1. Introduce a real bug; confirm the Verifier reports `FAIL` with the actual output.
2. Have the Implementer claim success falsely; confirm the Verifier contradicts it.
3. Break the environment (remove a dependency); confirm classification is `env`, not `impl`.
4. Submit a clean diff; confirm `APPROVED` with populated `false_positive_checks`.
5. Submit a security-touching diff at MEDIUM risk; confirm the security gate activates.
6. Confirm a blocking finding cannot coexist with `APPROVED`.

---

## Exit Criteria

- [ ] Verifier runs fresh and cites real output
- [ ] `PASS` impossible without per-criterion evidence
- [ ] Failures classified impl/env/flaky
- [ ] Review is diff-first with bounded expansion
- [ ] `false_positive_checks` required and substantive
- [ ] Gates activate by risk level
- [ ] Blocking/decision consistency enforced
- [ ] `schemaOverridden` treated as unvalidated

---

## Risks

| Risk | Mitigation |
|---|---|
| Verification doubles execution cost | It is the feature; a false pass costs more |
| Reviewer produces noise that trains users to ignore it | Required false-positive control and severity tiers |
| Gates fire on irrelevant tasks | Risk-based matrix, LOW gets none |
| Strict schemas cause retry loops | `yield` bounds retries at 3, then surfaces the override |
