# Phase 04 — Quality System

<!-- round09-12-projection:quality -->
## Round 09–12 quality supersession

KD-032 closes Topic 09 as a delta over Topic 04 candidate/evidence authority and Topic 06
provisional receipts. The active Reviewer severity is `critical | important | minor`; critical and
important block, minor alone may produce notes. Candidate mutation always requires fresh bound
evidence. There is no permanent Verifier, universal review dispatch, or mandatory Opus gate.
Historical tasks below remain rationale and test inventory where compatible with this rule.

<!-- topic06-projection:phase-04 -->
## Topic 06 quality consumer

Treat `agent_boundary_receipt` as a checked observation, never acceptance. Reviewer receives
ARTIFACT + CONTRACT and independently obtainable evidence, not Worker CLAIM; Reviewer is fixed
`xhigh`, while Opus remains preferred rather than required. Tech Lead fresh verification,
integration, and parent acceptance remain outside the wrapper.

> OPUS PROPOSED SPEC v1 | Make verification and review produce trustworthy evidence.
>
> **Topic 02 supersession boundary:** Topic 03 owns the selected verification mechanism and
> review shape. Phase 04 strengthens whatever responsibilities it selects; it does not require
> permanent Verifier/Reviewer agents or a worker dispatch.
>
> **KD-027 target:** Tech Lead owns fresh verification; one General Reviewer is risk-gated and
> fixed at `xhigh`. Cheap Scout cannot verify or review. Review concern profiles are task-packet
> data, and unavailable Opus follows the approved fallback ladder rather than blocking by name.

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

### T-04.1 — Enforce contract-gated verification independence

When the accepted task contract requires independent verification, the selected verification
mechanism must obtain fresh evidence from a non-author and must never infer a pass from the
candidate author's report. If Topic 03 selects a command-executing worker, that role runs every
required command fresh and reads the actual output.

A separate AgentSession is one permitted mechanism (CR-08), not a permanent topology rule.
Other permitted mechanisms include a main-session Tech Lead check or another independently
justified non-author path. A selected spawned path combines `autoloadSkills:
evidence-before-completion` with a `verification-result` schema requiring `commands_run`, exit
codes, and per-criterion evidence.

**CR-35 — what the schema proves, and what it does not.** An earlier revision of this
task claimed the schema's "required fields cannot be satisfied without real command
output." That claim is false and is withdrawn. `buildOutputValidator()`
(`tools/output-schema-validator.ts`) compiles the declared schema and runs
`validateJsonSchemaValue()` against the yielded object. It is generic JSON Schema
validation: it knows about types, `required`, closure, and per-section labels. It has no
access to the child's tool-call events and no concept of `commands_run` provenance. A
selected verification producer that runs zero `bash` calls and yields a syntactically perfect object with
invented commands, exit codes, and evidence strings **passes validation**.

The honest contract, stated in three separable layers:

```yaml
schema_layer:
  proves: the evidence claim is structurally complete and internally consistent
  does_not_prove: the commands were executed
independence_layer:
  proves: the selected independent judge did not author the candidate
  does_not_prove: its evidence strings came from real tool events
provenance_layer:
  v0_status: behavioral — the prompt requires fresh execution; not runtime-attested
  audit_path: when a worker is selected, its transcript is addressable at `history://<worker-id>` and
              renders one line per tool call with arguments
              (`session/session-history-format.ts` — `toolCallLine()`), so a
              claimed-vs-executed comparison is mechanically possible from the parent
  gate: T-04.8 (below) must confirm the transcript carries enough tool-call detail
        before any spec text claims fabrication is detectable
```

So "no false completion" is defended by independence plus structural discipline, not by
execution attestation. Where the spec states the guarantee — `10-verification-and-review.md §A`,
`README §14` — it MUST use that wording.

Unavailable, invalid, and overridden structured results are unvalidated and cannot satisfy
acceptance. This is separate from provenance: a `valid` result can still contain fabricated
claims, while a non-valid result does not even establish the declared shape.

**Acceptance**: when the selected path emits `verification-result`, it requires `commands_run`
with exit codes and per-criterion evidence; the selected contract forbids inference; `PASS` is
invalid when any criterion lacks evidence; **no spec text claims the schema proves execution**.

### T-04.2 — Enforce failure classification

Every failure classifies as `impl`, `env`, `flaky`, or `preexisting`. Each leads to a
different action: fix the code, fix the environment, re-run and investigate
nondeterminism, or attribute the failure away from the current diff. Without
classification, an environment failure gets "fixed" by changing correct code.

**CR-36 — `preexisting` is required, not optional.** The three-value enum could not
represent the most common deterministic case in a real repository: a test that was
already failing on the base commit, in a subsystem the diff does not touch, failing
identically after the change. It is not `impl` (the current code did not cause it), not
`env` (the toolchain is fine), and not `flaky` (it is perfectly deterministic). Forced
into `impl` — the only remaining option that does not lie about determinism — the
prescribed remediation sends the candidate's remediation owner to modify out-of-scope code until the
symptom moves. That is precisely the expensive misattribution the taxonomy exists to
prevent, manufactured by the taxonomy itself.

```yaml
preexisting:
  meaning: the failure reproduces on the base commit, independent of this change
  evidence_required: base-commit run showing the identical failure
  attribution: NOT the current diff
  next_action: surface as project risk / coverage blocker; do NOT dispatch a remediation owner
  decision_effect: does not force FAIL for this change; MUST appear in the result
```

The `evidence_required` line is what keeps `preexisting` from becoming a universal
excuse: claiming it obliges the selected verification path to show the base-commit failure, which is a
command with output like any other criterion.

**Acceptance**: classification is required for each failure; the prompt defines all four
categories and their distinct consequences; `preexisting` requires base-commit evidence
and does not route to a remediation owner.

### T-04.3 — Make review diff-first

The selected independent review path reads the diff first and expands only into files the diff touches or
directly implicates. Unbounded "diff context" becomes a full-repository read.

**Acceptance**: the prompt states diff-first with bounded expansion, and names the
expansion trigger (a symbol the diff changes, used elsewhere).

### T-04.4 — Make false-positive control checkable

The selected review path must, before reporting a finding, confirm: it is present in the current
code (not theoretical), not already handled elsewhere, not excluded by the packet's
scope, and not pre-existing lint output.

**Acceptance**: `false_positive_checks` is a required field; each entry names the
concern and why it was cleared. Findings without evidence are invalid.

### T-04.5 — Wire risk-based quality gates

Gates activate by risk level per the quality-gates policy (LOW: none; MEDIUM:
security; HIGH/CRITICAL: broader). Enabling every gate for every task wastes tokens and
trains the reader to ignore output; enabling none defeats the purpose.

Because there is no policy loader, the matrix is delivered to the selected gate-applier and
the packet's `quality_gates` field. No selected independent review means no reviewer prompt to
populate; the main-session Tech Lead still owns gate selection.

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

### T-04.8 — Measure what the child transcript can prove (CR-35 experiment)

T-04.1 downgrades the provenance claim because schema validation cannot attest execution.
This task establishes what the **available** provenance mechanism can actually support, so
the high-risk audit path in T-04.1 rests on measurement rather than on the same optimism
the schema claim rested on.

Source facts to start from (OMP v17.2.10):

- Each subagent's transcript is persisted as `<artifactsDir>/<id>.jsonl`
  (`task/executor.ts` — `subtaskSessionFile`), and `history://<id>` renders it
  (`internal-urls/history-protocol.ts`), falling back to an on-disk scan for
  unregistered agents.
- `formatSessionHistoryMarkdown()` renders each `toolCall` block with its **name and
  arguments**, collapsing the matching `toolResult` into the same line
  (`session/session-history-format.ts` — `toolCallLine`).

So tool *names* and *arguments* are recoverable. What must be measured, not assumed:

| # | Question | Why it matters |
|---|---|---|
| 1 | Is the full `bash` command text recoverable from the rendered transcript, or is it truncated? | A truncated command cannot be matched against a `commands_run` entry. |
| 2 | Is command **output**/exit code recoverable, or only the invocation? | Determines whether a claimed `exit_code` is checkable or only the fact of invocation is. |
| 3 | What does the transcript cost to read at realistic verification length? | An audit that costs more than re-running the command should re-run the command instead. |
| 4 | Is `history://<id>` reachable for an isolated, torn-down worker? | Isolated agents are not revivable; the disk-scan fallback must be confirmed for them. |
| 5 | Can a deterministic matcher fire without false positives on legitimate results? | A noisy check is one the Tech Lead learns to skip. |

**Acceptance**: a recorded measurement per question. If (1) and (2) hold, T-04.1's
high-risk audit is a real cross-check and the wording may be strengthened to name it as
such. If they do not, the honest fallback is stated: **re-run the criterion command in the
main session for high-risk work** and treat the selected worker's evidence as a claim to
corroborate, not a proof. Either way the outcome is recorded — no provenance strength is
asserted that this task did not measure.

---

## Deliverables

- Selected verification contract and, when spawned, schema enforcing fresh evidence
- Failure classification with distinct consequences, including `preexisting`
- Diff-first selected review path with bounded expansion
- Required, checkable false-positive control
- Inlined risk-based gate matrix
- Blocking-decision consistency rules
- Override handling
- Stated provenance boundary (structural validity vs execution attestation) plus the
  fabricated-evidence fixture and the T-04.8 measurement backing it

---

## Verification

1. Introduce a real bug; confirm the selected verification mechanism reports `FAIL` with the actual output.
2. Have the candidate author claim success falsely; confirm the selected non-author mechanism contradicts it.
3. Break the environment (remove a dependency); confirm classification is `env`, not `impl`.
4. Submit a clean diff; confirm `APPROVED` with populated `false_positive_checks`.
5. Submit a security-touching diff at MEDIUM risk; confirm the security gate activates.
6. Confirm a blocking finding cannot coexist with `APPROVED`.
7. **Fabricated-evidence fixture (CR-35).** Run the selected command-executing verification worker, if any, with **zero** `bash`
   calls and yields a schema-valid `PASS` with invented `commands_run`, exit codes, and
   per-criterion evidence. Confirm the documented outcome: the yield is **accepted** by
   schema validation. This is a characterization test of the provenance boundary, not a
   defect to be fixed at schema level — it must keep passing (i.e. keep being accepted)
   for as long as T-04.1's stated boundary is the honest one. If a future OMP version or
   template mechanism rejects it, T-04.1's wording is upgraded and this fixture inverts.
8. **Pre-existing failure fixture (CR-36).** Baseline contains a deterministic failing
   test unrelated to the diff; the implemented change is clean and does not touch that
   subsystem. Confirm classification is `preexisting` with baseline evidence — **not**
   `impl` — and that a remediation owner is not dispatched to "fix" it.
9. Confirm a `preexisting` classification does not by itself force `FAIL`, and that it
   appears in the report as a project risk with its baseline evidence.

---

## Exit Criteria

- [ ] Selected command-executing verification path runs fresh and cites real output
- [ ] `PASS` **structurally** impossible without per-criterion evidence fields — and the
      provenance boundary (fields are a claim, not an attestation) is stated in both
      `10-verification-and-review.md` and the selected verification contract (CR-35)
- [ ] Failures classified `impl` / `env` / `flaky` / `preexisting` (CR-36)
- [ ] Review is diff-first with bounded expansion
- [ ] `false_positive_checks` required and substantive
- [ ] Gates activate by risk level
- [ ] Blocking/decision consistency enforced
- [ ] `structuredOutput.status` is `valid`; unavailable/invalid/overridden results are unvalidated
- [ ] Fabricated-evidence fixture recorded with its documented (accepted) outcome
- [ ] Pre-existing-failure fixture classifies `preexisting`, not `impl`
- [ ] T-04.8 transcript-provenance measurement recorded, and T-04.1's high-risk audit
      wording matches what it measured

---

## Risks

| Risk | Mitigation |
|---|---|
| Verification doubles execution cost | It is the feature; a false pass costs more |
| Selected review path produces noise that trains users to ignore it | Required false-positive control and severity tiers |
| Gates fire on irrelevant tasks | Risk-based matrix, LOW gets none |
| Strict schemas cause retry loops | `yield` bounds retries at 3, then surfaces the override |
| **CR-35 — the spec overclaims what schemas prove, so a fabricated `PASS` reads as verified** | T-04.1 states the boundary explicitly; the fabricated-evidence fixture keeps it visible; high-risk work corroborates via transcript audit or main-session re-run (T-04.8) |
| **CR-36 — `preexisting` is misclassified as `impl`, sending a remediation owner to change out-of-scope working code** | Fourth category with baseline-evidence requirement; fixture asserts the classification; `preexisting` never routes to remediation |
| Baseline capture for `preexisting` is itself expensive on large suites | Baseline is captured once per workflow before implementation, reused across verification rounds; scope to the criterion commands, not the whole suite |
