# 10 — Verification and Review

## Candidate-bound proof (KD-028)

Verification and review consume an immutable candidate manifest and exact acceptance-input hashes.
Evidence types have closed producer/binding/validity rules; review uses an independent session when
required. Any workspace or acceptance-input mutation invalidates acceptance-bearing proof:
old candidate evidence cannot be accepted after mutation, and a new C2 candidate needs new applicable
evidence. The core derives candidate entries and scope dispositions from Git/workspace facts; the
model never supplies the final owned-output list.

> OPUS PROPOSED SPEC v1 | All claims verified against OMP source in `_research/upstreams/oh-my-pi`.
>
> **Topic 02 supersession boundary:** Topic 03 owns the verification mechanism, worker graph,
> specialist names, and review shape. A named Verifier is not mandatory. References to the
> existing `verifier.md`, `reviewer.md`, and former Implementer role are pre-Topic-03 adapters
> or examples; they do not require those agents to be spawned.
>
> **KD-027 selection:** the permanent Verifier is removed. Fresh verification is owned by the
> Tech Lead and follows the accepted task contract. One General Reviewer runs at exact `xhigh`
> and is mandatory for security, authentication, durable data, database migration, concurrency,
> public API, and destructive change concerns. Opus is preferred when suitable, never an
> implicit gate; an approved different-family/strong-model/same-model-separate-session fallback
> remains valid with disclosure.

---

## A. Why Required Independent Verification Needs a Non-Author

A candidate author runs verification as part of its loop (`inspect → edit → verify → compact`).
A separate session is one possible independence mechanism, but Topic 02 does not make it a
permanent agent or require it for every task.

The actual goal is defeating a specific failure mode: **an agent that has just written code is the worst judge of whether that code works.** It knows what it intended, so it reads output charitably. It ran the test that it designed to pass. It reports "tests pass" having run one file.

When the accepted contract requires independent verification, its value is that a **non-author**
judges fresh evidence without having written the candidate and therefore has no intention to
protect. KD-027 makes the main-session Tech Lead the verification owner; when the locked contract
requires non-author independence, the Tech Lead selects a separate fresh context or another
independently justified mechanism without restoring a permanent Verifier slot.

The same principle can justify a different model family for a selected independent review path
once differentiation is possible: same-author review inherits same-author blind spots. Model
or role separation is a mechanism choice, not the workflow definition.

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

So a selected command-executing verification role that runs **zero** commands and emits a syntactically perfect
`{commands_run: [{command: "npm test", exit_code: 0, evidence: "12 passed"}], decision: "PASS"}`
passes validation. The schema constrains *shape*, and shape is not provenance.

**What the architecture does guarantee.** Three real properties, none of which is attestation:

| Mechanism | Real guarantee | Not a guarantee of |
|---|---|---|
| Non-author verification context selected by Topic 03 | The verifying context did not author the candidate and has no author intent to protect | that any command in the result was executed |
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
is a genuine cross-check surface: the Tech Lead can read a selected verification role's transcript and compare
claimed `commands_run` against `bash` calls actually present.

It is **not** promoted to a contract in v0 because the check has not been demonstrated in the
target environment: whether the rendered form preserves enough of each `bash` invocation to match
a claimed command string, and what the transcript costs in tokens for a realistic verification run,
are both unmeasured. T-04.8 (`phases/phase-04-quality-system.md`) is the experiment; until it
reports, transcript audit is an available high-risk escalation, not a guarantee the spec leans on.

**Where the boundary must be visible.** This limitation is documented in the selected verification contract
(below), in `phases/phase-04-quality-system.md` T-04.1/T-04.8, as an L4 adversarial fixture in
`13-validation-and-evaluation.md`, and in the known-limitations list produced by
`phases/phase-07-stabilization.md` T-07.7 — so a user reads it before relying on absent behavior.

---

## B. Contract for a Selected Independent Verification Path

The existing `verifier.md` is a well-constructed pre-Topic-03 adapter. Its core rule is the
load-bearing part whenever Topic 03 selects a command-executing verification role:

> Run every verification command fresh in this session. Read the full output. Count failures.

Three properties make this correct:

1. **Fresh** — a result from a prior turn or a prior agent is not evidence in this turn. Stale passes are the most common false-completion vector.
2. **Full output** — reading the summary line and skipping the body hides skipped tests, warnings, and partial failures.
3. **Count** — "tests pass" is a claim; "12 passed, 0 failed, exit 0" is evidence.

### Failure classification is the highest-value requirement

The schema requires each failure be classified `impl | env | flaky | preexisting`. This distinction determines the next action and nothing else in the system captures it:

| Classification | Meaning | Correct next action |
|---|---|---|
| `impl` | The code is wrong. | Return to the candidate's remediation owner with the failure evidence. |
| `env` | Missing dependency, wrong config, absent tool. | Fix the environment. **Not** an implementation failure. Do not send the candidate author chasing a phantom bug. |
| `flaky` | Non-deterministic. | Re-run to confirm; if it reproduces intermittently, report as a known risk rather than a blocker. |
| `preexisting` | Deterministic, and **failed on the baseline before this change** (CR-36). | Do **not** route to the remediation owner. Record baseline evidence, exclude from this change's attribution, surface as a project risk / coverage blocker. |

Conflating `env` with `impl` is the expensive error: it sends a remediation owner to "fix" working code, which usually means it changes something until the symptom moves.

#### Why `preexisting` is a required fourth category, not a variant of the other three (CR-36)

A three-way `impl | env | flaky` taxonomy is not exhaustive over real verification runs. The
missing case is concrete and common: the baseline already has a deterministic failing test in a
subsystem the diff does not touch, and it still fails identically afterwards. That failure is
not `impl` (the current change did not cause it), not `env` (the toolchain is fine and
reproducible), and not `flaky` (it is perfectly deterministic).

Forcing it into `impl` — the only remaining label with a "return to remediation" action — produces
exactly the expensive error the taxonomy exists to prevent, and worse than the `env`/`impl`
confusion: a remediation owner is dispatched to modify code the packet declared out of scope, on
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
  routing: never to the candidate author or remediation owner as a bug to fix
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

### Historical schema correction (non-authority)

The retired `verification-result.schema.yml` stated:

> `decision: PASS requires all acceptance_criteria_results to be PASS`

`acceptance_criteria_results` permits `SKIP` as a per-criterion result. A `SKIP` is not a `PASS`. The rule as written is ambiguous about whether `PASS + one SKIP` is legal.

It must not be. Tighten to:

> `decision: PASS` requires every criterion to be `PASS`. Any `SKIP` forces `PARTIAL` at best, and the reason MUST appear in `coverage_gaps`.

### B-2. Effective Tool Availability is a Precondition for a Command-Executing Verification Path (CR-43)

A selected command-executing verification role's core contract — run every command fresh, read
full output, count failures — depends on the `bash` tool being **effectively available**, not
merely listed in a spawned agent's `tools:` allowlist.

OMP's built-in tool registration (`tools/index.ts:594`) gates `bash` independently:

```ts
if (name === "bash") return session.settings.get("bash.enabled");
```

`bash.enabled` defaults to `true` (`config/settings-schema.ts`), but a user who intentionally
disabled shell execution sets it `false`. When that happens, a spawned verification role's
allowlist entry is irrelevant — the tool is withheld regardless.

**This is the same selected-path fail-closed principle as LSP.** Without effective `bash`, the
selected role cannot execute a single command. It cannot run tests, builds, lint, or typecheck.
The entire fresh-execution contract collapses. A selected role without bash can still yield a
schema-valid `PASS` — CR-35 already established that `buildOutputValidator()` has no tool-event
correlation — which would be undetected false completion from the workflow's most trusted gate.

**A selected command-executing verification role MUST NOT yield `decision: PASS` when effective
bash is unavailable.** This is a
policy requirement, not a mechanical impossibility: the schema gate cannot enforce it (CR-35).
Until a runtime preflight/provenance mechanism exists that makes this mechanically impossible,
the requirement is normative: submit REFUSE or UNVERIFIED, never a normal VERIFIED PASS.

**Required behavior when bash is unavailable:**

```yaml
bash_unavailable_policy:
  detection: preflight checks the effective tool set for the selected verification role
  permitted_outcomes:
    - REFUSE the verified path — do not dispatch the selected role; report bash unavailable
    - UNVERIFIED result — mark result explicitly as unverified due to bash unavailability
  prohibited_outcome:
    - yield decision: PASS with prose substituting for command output
    - silently downgrade to read-only "verification" without disclosing the incapacity
  scope: selected command-executing verification role when fresh execution is hard_required
```

**L1/runtime check**: the preflight that reads effective isolation settings (§08 §E-9) MUST also
read the effective tool set for the selected command-executing verification role and assert
`bash` is present. A selected role missing effective `bash` is reported as a configuration
failure, not dispatched. See `13-validation-and-evaluation.md §B` L1 and the CR-43 L4 fixture.

---

## C. Contract for a Selected Independent Review Path

The existing `reviewer.md` is a strong pre-Topic-03 adapter. When an accepted contract or risk
gate selects independent review, two of its mechanisms are load-bearing regardless of which
role or session performs that responsibility.

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

<!-- round09-12-projection:quality -->
The selected `reviewer_v1` vocabulary is the single active three-level scheme and must not grow:

| Severity | Gate | Meaning |
|---|---|---|
| `critical` | blocks; | Correctness, security, authority, data-loss, or destructive-action failure. |
| `important` | blocks; | Actionable accepted-contract failure that must be corrected before acceptance. |
| `minor` | non-blocking note; | Real follow-up that may support `APPROVED_WITH_NOTES`; it never masks a blocking issue. |

`APPROVED` requires no findings, `APPROVED_WITH_NOTES` permits minor findings only, and any
`critical` or `important` finding requires `CHANGES_REQUESTED`. This makes the decision a
function of the findings rather than an independent assertion.

Every candidate mutation invalidates prior acceptance-bearing proof. A later review is a fresh
result bound to the new candidate. Delta-scoped reading is allowed only when the packet binds the
exact base and new candidate plus every unchanged concern input; it never reuses approval.

There is no permanent Verifier and no universal Reviewer dispatch. The candidate author performs
fresh self-verification, the Tech Lead owns the accepted verification contract, and independent
review runs only when the accepted contract or risk profile selects it. Opus is optional: if it is
unavailable, the approved different-family, strong-model, or same-model separate-session fallback
remains valid with disclosure.

---

## D. When Independent Review Runs

Review is risk-based, not universal. Running an independent review path on every one-line fix
burns tokens to produce "looks fine."

| Workflow | Independent review | Condition |
|---|---|---|
| Quick | No | Scope is a narrow, low-risk change with clear acceptance criteria. |
| Standard | Conditional | Enable for: public API surface change, security-touching code, new interface, or a diff large enough that the candidate author's own scope discipline is in question. Skip for internal changes passing all criteria at LOW risk. |
| Orchestrated | Contract/risk-gated | Require independent review when the accepted task contract, selected quality gates, integration risk, or cross-boundary evidence demands it. Orchestrated classification alone does not force a reviewer; when review is required, it still does not force a named role or worker dispatch. |

The Standard-tier condition is where judgment lives. The signal to watch is not diff size alone but **whether the change creates a contract someone else depends on** — that is what review catches and tests do not.

---

## E. The Ordering Constraint

Verification precedes review, and the ordering is not arbitrary:

```
implement → verify → [review] → report
```

Reviewing code that does not pass its own tests wastes the reviewer on defects the test suite already found. Verification is cheap and deterministic; review is expensive and judgment-based. Run the cheap deterministic filter first.

Corollary: if verification returns `FAIL`, **do not start the selected review stage**. Return to
the candidate's remediation owner with the failure evidence. The selected runtime path must make
this branch explicit rather than implying a linear pipeline.

**CR-39 — this ordering requires `blocking: true`, or the branch is unreachable.** The corollary
above is a decision made *on the selected verification role's result*, which means the orchestrator must actually
hold that result before choosing. It does not by default: `async.enabled` defaults to `true` and
`blocking` has no parser default, so a selected worker without `blocking: true` returns a "spawned
background agent" acknowledgement and the orchestrator proceeds — starting review
against an unverified tree, and later receiving the `FAIL` as an async injection after the
review it was supposed to prevent.

The same applies to a selected review worker: `decision: APPROVED` gating the final report is a
barrier, so a non-blocking worker allows a report to be written before any findings exist. Every
selected stage-barrier worker therefore carries `blocking: true`
(`03-agent-topology.md`, `08-isolation-and-concurrency.md §C-1`). Inline mechanisms do not need
agent frontmatter but must still complete before the dependent gate proceeds.
An evidence discipline whose gates can be bypassed by a default execution mode is not a
discipline — this is the same class of error as CR-35, where a stated guarantee outran its
mechanism.

---

## F. Evidence Discipline Applies to the Orchestrator Too

The Tech Lead must not accept a completed Worker outcome without the verification facts required
by the selected Worker `output:` contract and the Topic 06 result validator. Historical
`agent-result.schema.yml` is not runtime authority; see `06-structured-output.md`.

Beyond the schema, one behavioral rule: **the orchestrator does not re-derive verification from a worker's prose.** If a worker says "all tests pass" but `verification_results` is empty, that is a contract violation, not a summary to be trusted. Re-dispatch or run verification directly.

---

## G. Contract Summary

1. When the accepted contract requires independent verification, its value is independence from authorship, not a permanent agent name. Topic 03 owns the verification mechanism.
2. Failure classification (`impl | env | flaky | preexisting`) is mandatory — it determines the next action. `preexisting` exists because a deterministic baseline failure is none of the other three, and mislabeling it `impl` sends a remediation owner to change out-of-scope code (CR-36).
2b. **The schema proves shape, not provenance (CR-35).** Required evidence fields guarantee a claim is present and complete; they do not prove the claimed commands ran. v0 false-completion resistance is behavioral and independence-based. Do not describe it as attested — see §A-1.
3. `coverage_gaps` MUST be reported; `PASS` requires every criterion `PASS`, and any `SKIP` caps the result at `PARTIAL`.
4. A selected independent review path includes structural false-positive checks, including the pre-existing-lint check.
5. Review is diff-first with question-driven expansion — never whole-file reads for "context."
6. Review decision is a function of findings: `APPROVED` ⇒ no blockers; `CHANGES_REQUESTED` ⇒ at least one.
7. Independent review runs risk-based: never in Quick, conditionally in Standard, and in Orchestrated
   only when the accepted contract, selected quality gates, integration risk, or cross-boundary
   evidence requires independent review.
8. Verification precedes review; a `FAIL` short-circuits back to the remediation owner and skips review entirely.
9. **CR-39 — every selected stage-barrier worker MUST declare `blocking: true`.** Both the verify→review gate and the review→report gate are decisions made on a selected worker's completed result. Without `blocking: true` the `task` call returns before the result exists (`async.enabled` defaults `true`; `blocking` has no default), so the gate is skipped and the result arrives afterwards as an async injection. A named Verifier is not mandatory; this rule applies only when Topic 03 selects a dispatched worker for such a barrier. See §E.

---

## H. Topic 06 reviewer boundary

Reviewer independence is defined by inputs and ownership, not by a required provider name.
Reviewer receives the accepted CONTRACT, the current ARTIFACT/diff, and independently obtainable
evidence. The Worker's CLAIM, narrative, hidden reasoning, and proposed verdict are excluded from
the review packet. Reviewer is always `xhigh`; Opus may be preferred but is never required. A
same-model review uses a separate session and discloses that limitation.

The wrapper validates the Reviewer output and records a provisional receipt. It does not turn
`APPROVED` into parent acceptance. The Tech Lead still performs fresh verification, reconciles
findings, integrates the candidate, and owns the final decision. If managed review is unavailable,
the Tech Lead may review inline but cannot label that self-review independent or fabricate a
Reviewer receipt.
