# Phase 03 — Context Efficiency

> OPUS PROPOSED SPEC v1 | Reduce tokens per accepted outcome without losing correctness.

**Depends on**: phase-02
**Blocks**: phase-06

---

## Objective

Make the context budget real: enforce compaction settings, keep task packets and
results small, use progressive retrieval, and offload large artifacts to the
filesystem.

---

## Rationale

Optimizing before phase-02 would be measuring a broken system. Now that workflows
run, token cost per accepted outcome becomes a meaningful metric — and the goal is
explicitly *per accepted outcome*, not raw token count. A cheaper run that produces
an unusable result costs more, not less.

---

## Tasks

### T-03.1 — Enforce the compaction baseline

Document and require the compaction settings the context-budget policy assumes:
`compaction.strategy: shake`, `supersedeReads: true`, `dropUseless: true`,
`keepRecentTokens: 20000`. These are OMP settings (`config/settings-schema.ts`), so
they belong in config, not in prose.

**Acceptance**: settings documented with real key names; L0 (Static) validation checks
they are present.

### T-03.2 — Enforce task-packet discipline

Packets must carry objective, scope, acceptance criteria, verification commands, and
Explorer-provided `file:line` references — and must **not** carry parent transcript,
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
broad web. Each level must be tried before escalating.

**Acceptance**: Explorer and Implementer prompts state the order; the Explorer
prefers symbol lookup over full reads.

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

Record tokens per accepted outcome for each workflow size, before and after the
above. Without a before, none of this is demonstrable.

**Acceptance**: recorded measurements for both states on the same fixtures.

### T-03.8 — Calibrate the budgets, do not merely audit compliance with them

**CR-19 — the numeric targets in `05-context-and-token-model.md §C` and the offload
thresholds in T-03.5 are v0 engineering hypotheses, not measured optima.** They were chosen
from role complexity, and no source fact can establish that `AGENTS.md 600–1,200` or
`exploration offload >2,000` minimizes tokens per accepted outcome for this workflow and
model family.

The failure mode this task exists to prevent is circular validation:

```
choose target 600  →  constrain output to <600  →  observe output fits 600
                   →  conclude the target is correct        # proves nothing
```

That measures *compliance*, and compliance with an arbitrary number is not evidence the
number is good. T-03.2/T-03.3/T-03.6 legitimately check compliance; this task checks the
targets themselves.

Record, per workflow run, not just totals:

```yaml
per_run:
  - total_tokens
  - accepted_outcome            # the §A metric's denominator: did the user accept it
  - retries                     # schema retries, verifier FAIL→reimplement cycles
  - packet_tokens
  - worker_result_tokens
  - verifier_evidence_tokens
  - offloaded_bytes
  - quality_failure_reason       # incl. truncation- or offload-induced loss

analyze:
  - distributions (p50 / p90 / p95), never a single sample
  - accepted runs vs rejected runs, compared separately
  - whether crossing a threshold actually predicts worse quality or higher total cost
```

The decisive question is the third: if runs that exceed a target show no worse acceptance
rate and no higher total cost, the target is too tight and is costing tokens (compression
work, offload round-trips) for no benefit. If runs that respect it still fail on truncated
context, it is too loose. Either finding adjusts the number.

**Threshold-crossing must be observed, not prevented.** T-03.5's offload thresholds are
enforced in the *implementation*; this task requires that at least some fixtures run with
the threshold relaxed, or the distribution has no data above the line and the comparison is
impossible.

**Acceptance**: recorded distributions (not single samples) for every field above;
acceptance rate and total cost compared across threshold-crossing and threshold-respecting
runs; each `§05 §C` target and each T-03.5 offload threshold is either confirmed by that
evidence or revised, with the revision recorded. No target is described as validated on the
basis of compliance alone.

---

## Deliverables

- Documented compaction settings with real key names
- Packet and result discipline enforced at every dispatch site
- Progressive retrieval in worker prompts
- Offload thresholds implemented
- Right-sized `AGENTS.md` / `RULES.md`
- Before/after measurements
- Budget calibration record: distributions per field, and each `§05 §C` target
  confirmed-by-evidence or revised (CR-19)

---

## Verification

1. Run the same fixtures pre- and post-change; compare tokens per accepted outcome.
2. Confirm no accepted-outcome regression (efficiency must not cost correctness).
3. Inspect a real task packet: no transcript, no full-file dump.
4. Inspect a real Verifier result: key lines, not whole logs.
5. **CR-19 — confirm the calibration record contains threshold-crossing runs.** A record
   in which every run respects every target cannot calibrate anything; it only proves the
   enforcement works. At least some fixtures MUST have run with a relaxed threshold so the
   distribution has data on both sides of the line.
6. **CR-19 — confirm no target is reported as validated on compliance alone.** For each
   `§05 §C` target, the record states either the evidence that confirmed it (acceptance
   rate and total cost across both sides of the threshold) or the revision made.

---

## Exit Criteria

- [ ] Compaction settings documented and checked
- [ ] Packets carry no transcript
- [ ] Results carry evidence, not narrative
- [ ] Progressive retrieval stated in prompts
- [ ] Offload implemented
- [ ] `AGENTS.md` / `RULES.md` within budget
- [ ] Tokens per accepted outcome measured before and after, with no correctness regression
- [ ] **Budget calibration record produced (CR-19)**: p50/p90/p95 per instrumented field,
      acceptance and retry rate per run, and threshold-crossing runs present
- [ ] **Every `§05 §C` numeric target either confirmed by that evidence or revised** — no
      target promoted from "provisional default" to "validated" on compliance alone

---

## Risks

| Risk | Mitigation |
|---|---|
| Over-compaction hides evidence the Verifier needs | Verifier reads fresh; it does not depend on compacted history |
| Offload adds file I/O and indirection | Only above thresholds where inlining is worse |
| Token reduction reduces result quality | Metric is per *accepted* outcome; rejected work counts as cost |
| Summarization drops a load-bearing detail | Keep summarization on by default; disable only with a written reason |
