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

---

## Deliverables

- Documented compaction settings with real key names
- Packet and result discipline enforced at every dispatch site
- Progressive retrieval in worker prompts
- Offload thresholds implemented
- Right-sized `AGENTS.md` / `RULES.md`
- Before/after measurements

---

## Verification

1. Run the same fixtures pre- and post-change; compare tokens per accepted outcome.
2. Confirm no accepted-outcome regression (efficiency must not cost correctness).
3. Inspect a real task packet: no transcript, no full-file dump.
4. Inspect a real Verifier result: key lines, not whole logs.

---

## Exit Criteria

- [ ] Compaction settings documented and checked
- [ ] Packets carry no transcript
- [ ] Results carry evidence, not narrative
- [ ] Progressive retrieval stated in prompts
- [ ] Offload implemented
- [ ] `AGENTS.md` / `RULES.md` within budget
- [ ] Tokens per accepted outcome measured before and after, with no correctness regression

---

## Risks

| Risk | Mitigation |
|---|---|
| Over-compaction hides evidence the Verifier needs | Verifier reads fresh; it does not depend on compacted history |
| Offload adds file I/O and indirection | Only above thresholds where inlining is worse |
| Token reduction reduces result quality | Metric is per *accepted* outcome; rejected work counts as cost |
| Summarization drops a load-bearing detail | Keep summarization on by default; disable only with a written reason |
