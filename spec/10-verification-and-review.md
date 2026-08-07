# 10 — Verification and Review

> OPUS PROPOSED SPEC v1 | All claims verified against OMP source in `_research/upstreams/oh-my-pi`.

---

## A. Why Verification Is a Separate Agent

The Implementer runs verification as part of its loop (`inspect → edit → verify → compact`). A separate Verifier appears redundant — and would be, if the only goal were running commands.

The actual goal is defeating a specific failure mode: **an agent that has just written code is the worst judge of whether that code works.** It knows what it intended, so it reads output charitably. It ran the test that it designed to pass. It reports "tests pass" having run one file.

The Verifier's value is not that it runs commands. It is that it runs them **without having written the code**, and therefore has no intention to protect.

This is the same reason `09-model-routing.md` recommends a different model family for the Reviewer than the Implementer once differentiation is possible: same-author review inherits same-author blind spots.

---

## A-1. What the Verification Schema Proves — and What It Does Not (CR-35)

The template's headline claim is "no false completion." That claim must be stated at exactly the
strength the runtime supports, because overstating it is itself a false-completion vector: a
reader who believes evidence is machine-attested will stop checking it.

**The false claim, now withdrawn.** Earlier revisions of this spec and `phases/phase-04-quality-system.md`
said the `verification-result` schema has "required fields that cannot be satisfied without real
command output." That is not true, and the source is unambiguous. OMP's output-schema path is
generic JSON Schema validation over the yielded value:

- `buildOutputValidator(schema)` compiles the declared schema and returns
  `validate(value) → JsonSchemaValidationResult` (`tools/output-schema-validator.ts`).
- `YieldTool` runs that validator against the yielded `data` and retries on mismatch
  (`tools/yield.ts`, `MAX_SCHEMA_RETRIES = 3`).
- The validator's inputs are the schema and the value. It has no access to the session's tool-call
  history, no notion of `commands_run`, and no correlation between a claimed `exit_code` and any
  `bash` invocation.

So a Verifier that runs **zero** commands and emits a syntactically perfect
`{commands_run: [{command: "npm test", exit_code: 0, evidence: "12 passed"}], decision: "PASS"}`
passes validation. The schema constrains *shape*, and shape is not provenance.

**What the architecture does guarantee.** Three real properties, none of which is attestation:

| Mechanism | Real guarantee | Not a guarantee of |
|---|---|---|
| Separate child session per Verifier | The verifying context did not author the implementation — no shared transcript, no intention to protect | that any command in the result was executed |
| Required `commands_run` / per-criterion evidence | Every criterion must be *addressed*; omissions become visible; retries fire on malformed output | that the cited output came from a process |
| `evidence-before-completion` autoloaded skill + prompt | Behavioral instruction to run fresh and quote real bytes | mechanical enforcement of it |

**Honest v0 formulation**, which replaces the withdrawn claim everywhere it appeared:

```text
False-completion resistance in v0 is behavioral and independence-based, not tool-event attested.
The schema enforces that an evidence claim is present, complete, and internally consistent.
It does not prove the claimed commands ran.
```

**The available provenance mechanism, and why it is not yet load-bearing.** OMP retains a
per-subagent JSONL transcript and exposes it as `history://<agent-id>`; the renderer emits one line
per tool call including tool name and arguments, pairing each call with its result
(`session/session-history-format.ts`, `internal-urls/history-protocol.ts`). Transcripts survive the
agent leaving the registry — resolution falls back to scanning artifact dirs for `<id>.jsonl`. That
is a genuine cross-check surface: the Tech Lead can read the Verifier's transcript and compare
claimed `commands_run` against `bash` calls actually present.

It is **not** promoted to a contract in v0 because the check has not been demonstrated in the
target environment: whether the rendered form preserves enough of each `bash` invocation to match
a claimed command string, and what the transcript costs in tokens for a realistic verification run,
are both unmeasured. T-04.8 (`phases/phase-04-quality-system.md`) is the experiment; until it
reports, transcript audit is an available high-risk escalation, not a guarantee the spec leans on.

**Where the boundary must be visible.** This limitation is documented in the Verifier contract
(below), in `phases/phase-04-quality-system.md` T-04.1/T-04.8, as an L4 adversarial fixture in
`13-validation-and-evaluation.md`, and in the known-limitations list produced by
`phases/phase-07-stabilization.md` T-07.7 — so a user reads it before relying on absent behavior.

---

## B. The Verifier Contract

The existing `verifier.md` is well-constructed. Its core rule is the load-bearing part:

> Run every verification command fresh in this session. Read the full output. Count failures.

Three properties make this correct:

1. **Fresh** — a result from a prior turn or a prior agent is not evidence in this turn. Stale passes are the most common false-completion vector.
2. **Full output** — reading the summary line and skipping the body hides skipped tests, warnings, and partial failures.
3. **Count** — "tests pass" is a claim; "12 passed, 0 failed, exit 0" is evidence.

### Failure classification is the highest-value requirement

The schema requires each failure be classified `impl | env | flaky | preexisting`. This distinction determines the next action and nothing else in the system captures it:

| Classification | Meaning | Correct next action |
|---|---|---|
| `impl` | The code is wrong. | Return to Implementer with the failure evidence. |
| `env` | Missing dependency, wrong config, absent tool. | Fix the environment. **Not** an implementation failure. Do not send the Implementer chasing a phantom bug. |
| `flaky` | Non-deterministic. | Re-run to confirm; if it reproduces intermittently, report as a known risk rather than a blocker. |
| `preexisting` | Deterministic, and **failed on the baseline before this change** (CR-36). | Do **not** route to the Implementer. Record baseline evidence, exclude from this change's attribution, surface as a project risk / coverage blocker. |

Conflating `env` with `impl` is the expensive error: it sends an Implementer to "fix" working code, which usually means it changes something until the symptom moves.

#### Why `preexisting` is a required fourth category, not a variant of the other three (CR-36)

A three-way `impl | env | flaky` taxonomy is not exhaustive over real verification runs. The
missing case is concrete and common: the baseline already has a deterministic failing test in a
subsystem the diff does not touch, and it still fails identically afterwards. That failure is
not `impl` (the current change did not cause it), not `env` (the toolchain is fine and
reproducible), and not `flaky` (it is perfectly deterministic).

Forcing it into `impl` — the only remaining label with a "return to Implementer" action — produces
exactly the expensive error the taxonomy exists to prevent, and worse than the `env`/`impl`
confusion: the Implementer is dispatched to modify code the packet declared out of scope, on
evidence that the change never touched it. A schema that makes the honest answer unrepresentable
manufactures that dispatch.

`preexisting` carries a distinct evidence obligation:

```yaml
preexisting:
  requires:
    baseline_evidence: >
      the same command, same failure, observed on the pre-change baseline
      (baseline run recorded before implementation, or an explicit re-run at the base commit)
    relation_to_diff: >
      statement that the failing subsystem is not touched by this change,
      or naming the overlap if it is
  effect_on_decision: >
    does not force FAIL for this change; MUST appear in the report and,
    where a criterion depends on it, in coverage_gaps
  routing: never to the Implementer as a bug to fix
```

An unsubstantiated `preexisting` — claimed with no baseline evidence — is the label's own abuse
vector: it converts any real regression into "was already broken." Baseline evidence is therefore
mandatory for this classification specifically, and a `preexisting` claim without it is treated as
unclassified, not as cleared.

A fifth category (`test_or_spec`, for an invalid test or wrong acceptance criterion) is
**deliberately not added in v0.** It is real but rarer, its remediation overlaps `impl` and
"ask the user," and each additional label costs classification accuracy on every run. Revisit
with phase-06 evidence.

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
2. Failure classification (`impl | env | flaky | preexisting`) is mandatory — it determines the next action. `preexisting` exists because a deterministic baseline failure is none of the other three, and mislabeling it `impl` sends the Implementer to change out-of-scope code (CR-36).
2b. **The schema proves shape, not provenance (CR-35).** Required evidence fields guarantee a claim is present and complete; they do not prove the claimed commands ran. v0 false-completion resistance is behavioral and independence-based. Do not describe it as attested — see §A-1.
3. `coverage_gaps` MUST be reported; `PASS` requires every criterion `PASS`, and any `SKIP` caps the result at `PARTIAL`.
4. Reviewer false-positive checks are structural and required, including the pre-existing-lint check.
5. Review is diff-first with question-driven expansion — never whole-file reads for "context."
6. Review decision is a function of findings: `APPROVED` ⇒ no blockers; `CHANGES_REQUESTED` ⇒ at least one.
7. Reviewer runs risk-based: never in Quick, conditionally in Standard, always in Orchestrated.
8. Verification precedes review; a `FAIL` short-circuits back to the Implementer and skips review entirely.
