# Phase 03 — Context Efficiency

<!-- topic06-projection:phase-03 -->
## Topic 06 context consumer

Compose a role-minimal packet from the Topic 04 projection; never include the parent transcript,
hidden reasoning, raw logs, credentials, or unrelated authority. Reviewer input excludes Worker
CLAIM. Topic 06 contributes `task.softRequestBudget: 200`; the resulting 300-request forced
partial is nonterminal rather than a cheap-looking completion. Topic 07 separately owns the exact
continuity profile below.

<!-- topic07-projection:phase-03 -->
## Topic 07 continuity consumer

Replace the historical automatic-`shake` assumption with KD-031's exact disabled managed profile.
Only argument-free `/safe-compact` after Topic 04 task arming may run one native soft context-full
transaction. Persist and verify local recovery bytes before the call, inject one canonical kernel
on the next normal prompt, and schedule no continuation or retry. Pressure stops provider dispatch;
bounded children fail, while the main session uses `/safe-compact` or explicit Topic 04 handoff.

<!-- topic05-projection:phase-03 -->
## Topic 05 retrieval consumer

Implement source-fit progressive retrieval and the compact evidence overlay. Exit only when native
fallback is explicit, graph output remains a hypothesis, absence requires native corroboration,
actor/capability selection is independent, and no raw graph-plus-summary duplication crosses a
session boundary. CodeGraph remains optional/default-off.

## Topic 04 consumer projection

Topic 04 consumes checkpoints, handoff, and offload boundaries. Phase 03 writes compact mandatory
checkpoints before compaction/switch/stop, treats raw `.task/` and runtime artifacts as transient,
and promotes only bounded sanitized evidence. It never creates a second lifecycle compactor.

> OPUS PROPOSED SPEC v1 | Reduce core workflow tokens per validated accepted outcome after quality gates.
>
> **Topic 02 supersession boundary:** context controls attach to responsibilities selected by
> Topic 03. Former Explorer/Implementer/Verifier names are baseline examples, not required
> workers.
>
> **KD-027 target:** Cheap Scout handles bounded retrieval with cheap-token telemetry; Worker and
> Reviewer consume core-token budgets only after benefit/risk gates. Do not suppress useful Scout
> retrieval merely to optimize raw token totals.

**Depends on**: phase-02
**Blocks**: phase-06

---

## Objective

Make the context budget real: enforce continuity settings, keep task packets and
results small, use progressive retrieval, and offload large artifacts to the
filesystem.

---

## Rationale

Optimizing before phase-02 would be measuring a broken system. Now that workflows run, the
meaningful target is core workflow tokens per validated accepted outcome across the whole task
cycle. Quality gates and accepted-outcome rate come first; Cheap Scout and raw totals remain
unweighted telemetry. A cheaper run that produces an unusable result costs more, not less.

---

## Tasks

### T-03.0 — Preserve lifecycle identity across context operations

Safe compaction preserves session identity, the open task, candidate lineage, workflow,
ownership, and acceptance state. It is a context operation, not a task-state transition, and
its summary, recovery artifact, and continuity kernel cannot become lifecycle authority.

Handoff creates a reconciled successor session for the same task and candidate lineage. The
successor must compare the handoff with the accepted contract and actual workspace before
mutation; the predecessor loses active ownership after acceptance of the handoff.

Durable lifecycle state remains owned by Topic 04. Phase 03 may consume its future projection
but must not create a competing state store.

**Acceptance**: safe-compaction and handoff tests preserve/reconcile the Topic 02 identities,
inject exactly one fresh kernel on the next normal prompt, and reject a stale resume before
provider dispatch or mutation.

### T-03.1 — Enforce explicit managed continuity

Document and require automatic/context-promotion disabled, `compaction.strategy: off`, thresholds
`-1`, idle/mid-turn/auto-continue/remote paths disabled, `keepRecentTokens: 20000`, and
`supersedeReads`/`dropUseless` true. `/safe-compact` alone authorizes one native
`ctx.compact({ mode: "soft" })` call after exact task arming. Built-in `/compact`, direct `shake`,
`snapcompact`, automatic handoff, and remote compaction are unsupported managed fallbacks.

**Acceptance**: L0 validates the exact profile and command contract; deterministic fixtures prove
artifact-first single-flight settlement, one-shot injection, no hidden continuation/retry, Quick
degradation bounds, and child pressure failure. Runtime canaries prove stop-before-provider on both
supported versions before promotion.

### T-03.2 — Enforce task-packet discipline

Packets must carry objective, scope, acceptance criteria, verification commands, and
evidence references from selected retrieval roles — and must **not** carry parent transcript,
raw terminal history, or full-file dumps.

**Acceptance**: dispatch templates in commands contain no transcript-forwarding
pattern; the prohibition is stated at each dispatch site.

### T-03.3 — Enforce result compaction

Worker results return evidence, not narrative: exact commands, exit codes, key output
lines. `verification_results` quotes lines, not whole logs.

**Acceptance**: schemas and prompts both state the constraint; sample results from
phase-02 runs fit the §05 targets.

### T-03.4 — Implement progressive retrieval

Order: local code and types → local docs → official versioned docs → Context7 →
broad web. This is a default priority with bounded escalation, not an exhaustion gate. A named
permitted skip from `spec/07 §B-1` is valid when disclosed; an undisclosed skip violates the
retrieval contract.

**Acceptance**: every selected retrieval role and remediation role states the applicable
order and named permitted skip rules; a selected symbol-aware retrieval contract prefers
symbol lookup over full reads. A topology with no spawned retrieval role preserves the order
in the main-session procedure.

### T-03.5 — Implement filesystem offload

Exploration output over ~2,000 tokens, review findings over ~1,000, and verification
output over ~500 go to files; results carry the path plus key lines.

**Acceptance**: offload thresholds and paths are stated; results reference paths
rather than inlining bulk.

### T-03.6 — Right-size the persistent context

`AGENTS.md` (persistent) and `RULES.md` (sticky, re-attached near every turn) are the
only always-loaded template files. `RULES.md` is the expensive one per §05.

**Acceptance**: both within §05 targets; `RULES.md` contains only invariants that
change behavior mid-turn.

### T-03.7 — Measure before and after

Freeze the pre-change template identity and record, for each workflow size, the validated
accepted-outcome rate and core workflow tokens per validated accepted outcome before and after
the changes above. Retain failed cycles in the numerator and report Cheap Scout, raw total,
cache-read, latency, retry, and rework telemetry separately.

**Acceptance**: recorded measurements for both states on the same fixtures and accounting
basis, with no double counting. These are calibration results only; Phase 03 cannot emit a
promotion verdict before Phase 06 implements `spec/13 §C`.

### T-03.8 — Calibrate the budgets, do not merely audit compliance with them

**CR-19 — the numeric targets in `05-context-and-token-model.md §C` and the offload
thresholds in T-03.5 are v0 engineering hypotheses, not measured optima.** They were chosen
from role complexity, and no source fact can establish that `AGENTS.md 600–1,200` or
`exploration offload >2,000` minimizes core workflow tokens per validated accepted outcome for
this workflow and model family.

The failure mode this task exists to prevent is circular validation:

```
choose target 600  →  constrain output to <600  →  observe output fits 600
                   →  conclude the target is correct        # proves nothing
```

That measures *compliance*, and compliance with an arbitrary number is not evidence the
number is good. T-03.2/T-03.3/T-03.6 legitimately check compliance; this task checks the
targets themselves.

Record, per task cycle, not just totals:

```yaml
per_task_cycle:
  - task_cycle_id
  - terminal_state
  - validated_accepted_outcome
  - acceptance_criteria_coverage
  - false_completion
  - failure_class
  - core_workflow_tokens
  - cheap_scout_tokens
  - raw_total_tokens
  - cache_read_tokens
  - retries
  - rework_loops
  - wall_time_ms
  - packet_tokens
  - worker_result_tokens
  - verifier_evidence_tokens
  - offloaded_bytes
  - failure_detail               # incl. truncation- or offload-induced loss

analyze:
  - distributions (p50 / p90 / p95), never a single sample
  - validated vs non-accepted cycles, compared separately
  - whether crossing a threshold predicts worse quality or higher core cost per outcome
  - Cheap Scout, raw total, cache-read, and latency telemetry without weighting
```

The decisive question is the third: if runs that exceed a target show no worse acceptance
rate and no higher core cost per outcome, the target is too tight and is costing tokens
(compression work, offload round-trips) for no benefit. If runs that respect it still fail on
truncated context, it is too loose. Either finding adjusts the number.

**Threshold-crossing must be observed, not prevented.** T-03.5's offload thresholds are
enforced in the *implementation*; this task requires that at least some fixtures run with
the threshold relaxed, or the distribution has no data above the line and the comparison is
impossible.

**Acceptance**: recorded distributions (not single samples) for every field above; validated
acceptance rate and core cost per outcome compared across threshold-crossing and
threshold-respecting runs; each `§05 §C` target and each T-03.5 offload threshold is either
confirmed by that evidence or revised, with the revision recorded. No target is described as
validated on the basis of compliance alone, and no Phase 03 record claims promotion.

---

## Deliverables

- Documented managed continuity settings and `/safe-compact` contract with real key names
- Packet and result discipline enforced at every dispatch site
- Progressive retrieval in worker prompts
- Offload thresholds implemented
- Right-sized `AGENTS.md` / `RULES.md`
- Before/after calibration measurements using the three token ledgers
- Budget calibration record: distributions per field, and each `§05 §C` target
  confirmed-by-evidence or revised (CR-19)

---

## Verification

1. Run the same fixtures pre- and post-change from fresh state; compare validated
   accepted-outcome rate and core workflow tokens per validated accepted outcome.
2. Confirm deterministic quality gates pass and the observed accepted-outcome rate does not
   regress; efficiency cannot pay for correctness.
3. Inspect a real task packet: no transcript, no full-file dump.
4. Inspect a selected verification result, whether inline or worker-produced: key lines, not whole logs.
5. **CR-19 — confirm the calibration record contains threshold-crossing runs.** A record
   in which every run respects every target cannot calibrate anything; it only proves the
   enforcement works. At least some fixtures MUST have run with a relaxed threshold so the
   distribution has data on both sides of the line.
6. **CR-19 — confirm no target is reported as validated on compliance alone.** For each
   `§05 §C` target, the record states either the evidence that confirmed it (validated
   acceptance rate and core cost per outcome across both sides of the threshold) or the
   revision made.
7. Confirm the calibration output cannot emit `PROMOTE_EFFICIENCY` or `PROMOTE_QUALITY`;
   promotion belongs to Phase 06.

---

## Exit Criteria

- [ ] Safe compaction and handoff satisfy T-03.0 without changing lifecycle authority
- [ ] Disabled automatic profile and `/safe-compact` contract documented and checked
- [ ] Packets carry no transcript
- [ ] Results carry evidence, not narrative
- [ ] Progressive retrieval stated in prompts
- [ ] Offload implemented
- [ ] `AGENTS.md` / `RULES.md` within budget
- [ ] Validated accepted-outcome rate and core workflow tokens per validated accepted outcome
      measured before and after; failed cycles remain charged and no correctness regression occurs
- [ ] `cheap_scout_tokens`, `raw_total_tokens`, cache-read, latency, retry, and rework telemetry
      reported separately without weighting
- [ ] **Budget calibration record produced (CR-19)**: p50/p90/p95 per instrumented field,
      acceptance and retry rate per run, and threshold-crossing runs present
- [ ] **Every `§05 §C` numeric target either confirmed by that evidence or revised** — no
      target promoted from "provisional default" to "validated" on compliance alone

---

## Risks

| Risk | Mitigation |
|---|---|
| Safe compaction drops a locked fact | Canonical Topic 04 kernel is validated, hash-bound, and injected once before provider work |
| Offload adds file I/O and indirection | Only above thresholds where inlining is worse |
| Token reduction reduces result quality | Quality gates and observed accepted-outcome rate run before the core-token metric; rejected work remains charged |
| One attempt leaves pressure unresolved | Stop and use explicit Topic 04 handoff or user action; never rescue-shake or auto-retry |
