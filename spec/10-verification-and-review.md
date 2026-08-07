# 10 — Verification and Review

> OPUS PROPOSED SPEC v1 | All claims verified against OMP source in `_research/upstreams/oh-my-pi`.

---

## A. Why Verification Is a Separate Agent

The Implementer runs verification as part of its loop (`inspect → edit → verify → compact`). A separate Verifier appears redundant — and would be, if the only goal were running commands.

The actual goal is defeating a specific failure mode: **an agent that has just written code is the worst judge of whether that code works.** It knows what it intended, so it reads output charitably. It ran the test that it designed to pass. It reports "tests pass" having run one file.

The Verifier's value is not that it runs commands. It is that it runs them **without having written the code**, and therefore has no intention to protect.

This is the same reason `09-model-routing.md` recommends a different model family for the Reviewer than the Implementer once differentiation is possible: same-author review inherits same-author blind spots.

---

## B. The Verifier Contract

The existing `verifier.md` is well-constructed. Its core rule is the load-bearing part:

> Run every verification command fresh in this session. Read the full output. Count failures.

Three properties make this correct:

1. **Fresh** — a result from a prior turn or a prior agent is not evidence in this turn. Stale passes are the most common false-completion vector.
2. **Full output** — reading the summary line and skipping the body hides skipped tests, warnings, and partial failures.
3. **Count** — "tests pass" is a claim; "12 passed, 0 failed, exit 0" is evidence.

### Failure classification is the highest-value requirement

The schema requires each failure be classified `impl | env | flaky`. This distinction determines the next action and nothing else in the system captures it:

| Classification | Meaning | Correct next action |
|---|---|---|
| `impl` | The code is wrong. | Return to Implementer with the failure evidence. |
| `env` | Missing dependency, wrong config, absent tool. | Fix the environment. **Not** an implementation failure. Do not send the Implementer chasing a phantom bug. |
| `flaky` | Non-deterministic. | Re-run to confirm; if it reproduces intermittently, report as a known risk rather than a blocker. |

Conflating `env` with `impl` is the expensive error: it sends an Implementer to "fix" working code, which usually means it changes something until the symptom moves.

### Coverage gaps must be reported, not hidden

The schema's `coverage_gaps` field handles the case where an acceptance criterion has **no command that tests it**. This is the honest answer to a criterion like "the UI renders correctly" when no UI test exists.

The rule that `coverage_gaps` does not automatically cause `FAIL` is correct — an uncovered criterion is not a failed criterion. But it MUST be surfaced, because an uncovered criterion is also not a *passed* criterion, and `decision: PASS` with silent gaps is false completion wearing a schema.

This is what `decision: PARTIAL` exists for.

### One correction to the existing schema

`verification-result.schema.yml` states:

> `decision: PASS requires all acceptance_criteria_results to be PASS`

`acceptance_criteria_results` permits `SKIP` as a per-criterion result. A `SKIP` is not a `PASS`. The rule as written is ambiguous about whether `PASS + one SKIP` is legal.

It must not be. Tighten to:

> `decision: PASS` requires every criterion to be `PASS`. Any `SKIP` forces `PARTIAL` at best, and the reason MUST appear in `coverage_gaps`.

---

## C. The Reviewer Contract

The existing `reviewer.md` is the strongest file in the template. Two of its mechanisms are worth calling out as load-bearing.

### False-positive control is mandatory and structural

The `false_positive_checks` field is required, and each entry must name a concern and state why it was cleared. This inverts the usual review dynamic: instead of rewarding volume of findings, it requires the reviewer to show its work on findings it *rejected*.

This matters because a reviewer optimizing for apparent thoroughness produces noise, and noise trains the reader to skim. The four required checks before reporting anything:

- Is the concern already handled elsewhere in the codebase?
- Did the task packet explicitly exclude it from scope?
- Is it actually present in the current code, or theoretical?
- Was the lint/type output already failing before this change?

The last one is the most frequently violated in practice: reporting pre-existing lint noise as a finding of the current change.

### Diff-first, with bounded expansion

The instruction to "read the actual changed files and their diff context" is right in intent but loose in wording — "diff context" can be read as license to load whole files.

Tighten it to a specific sequence:

1. Read the diff. This is the change.
2. Expand only to answer a **specific question the diff raised** — a caller's expectations, a type's contract, an invariant's other enforcement site.
3. Never read a file "for context" without a question it answers.

OMP's `read` tool takes line ranges, and `lsp` (when enabled) answers "who calls this" without loading callers. Step 2 should almost always be a range read or a symbol query, not a whole file.

### Severity must map to action

The three-level scheme is correct and should not grow:

| Severity | Gate | Meaning |
|---|---|---|
| `BLOCKING` | Blocks acceptance | Correctness bug, security vulnerability, spec mismatch, unintended breaking change. |
| `NON_BLOCKING` | Follow-up | Real but deferrable — minor maintainability, missing edge-case test. |
| `OBSERVATION` | None | Informational. |

The rule that `decision: APPROVED` requires `blocking_findings` to be empty, and `CHANGES_REQUESTED` requires at least one, makes the decision a **function of the findings** rather than an independent judgment. That prevents the two most common review pathologies: approving while listing blockers, and requesting changes without naming one.

---

## D. When the Reviewer Runs

Review is risk-based, not universal. Running a reviewer on every one-line fix burns tokens to produce "looks fine."

| Workflow | Reviewer | Condition |
|---|---|---|
| Quick | No | Scope is a narrow, low-risk change with clear acceptance criteria. |
| Standard | Conditional | Enable for: public API surface change, security-touching code, new interface, or a diff large enough that the Implementer's own scope discipline is in question. Skip for internal changes passing all criteria at LOW risk. |
| Orchestrated | Yes | Cross-module or architecture-affecting work always gets independent review. |

The Standard-tier condition is where judgment lives. The signal to watch is not diff size alone but **whether the change creates a contract someone else depends on** — that is what review catches and tests do not.

---

## E. The Ordering Constraint

Verification precedes review, and the ordering is not arbitrary:

```
implement → verify → [review] → report
```

Reviewing code that does not pass its own tests wastes the reviewer on defects the test suite already found. Verification is cheap and deterministic; review is expensive and judgment-based. Run the cheap deterministic filter first.

Corollary: if verification returns `FAIL`, **do not dispatch the Reviewer**. Return to the Implementer with the failure evidence. The template's command files should make this branch explicit rather than implying a linear pipeline.

---

## F. Evidence Discipline Applies to the Orchestrator Too

The Tech Lead must not accept `status: completed` without `verification_results` populated — this is enforced by the `agent-result` schema rule (see `06-structured-output.md`, which also flags that the field must be **required** when status is `completed`, not merely listed as optional).

Beyond the schema, one behavioral rule: **the orchestrator does not re-derive verification from a worker's prose.** If a worker says "all tests pass" but `verification_results` is empty, that is a contract violation, not a summary to be trusted. Re-dispatch or run verification directly.

---

## G. Contract Summary

1. The Verifier's value is independence from authorship, not command execution.
2. Failure classification (`impl | env | flaky`) is mandatory — it determines the next action.
3. `coverage_gaps` MUST be reported; `PASS` requires every criterion `PASS`, and any `SKIP` caps the result at `PARTIAL`.
4. Reviewer false-positive checks are structural and required, including the pre-existing-lint check.
5. Review is diff-first with question-driven expansion — never whole-file reads for "context."
6. Review decision is a function of findings: `APPROVED` ⇒ no blockers; `CHANGES_REQUESTED` ⇒ at least one.
7. Reviewer runs risk-based: never in Quick, conditionally in Standard, always in Orchestrated.
8. Verification precedes review; a `FAIL` short-circuits back to the Implementer and skips review entirely.
