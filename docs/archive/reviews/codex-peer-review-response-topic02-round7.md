REOPEN_TOPIC_02

# Independent Codex review — Topic 02 — Round 7

No Critical and no Minor finding was identified. Four Important findings remain.

## Findings

### R7-F1 — Important — Unfenced research and registry files restore fixed topology and permanent-review authority

`docs/research/conflict-matrix.md:4-6` presents itself as recording current resolutions, then:

- `docs/research/conflict-matrix.md:22` says five custom agents are discovered and dispatched.
- `docs/research/conflict-matrix.md:64-66` makes a dedicated Reviewer agent the primary
  Orchestrated review mechanism.
- `docs/research/conflict-matrix.md:188-199` reiterates a Tech Lead agent, Reviewer-only
  Orchestrated flow, and fixed role routing.
- `registry/adoption-ledger.yml:1-17` records five fixed custom agents as the adopted mechanism.
- `registry/adoption-ledger.yml:70-80` assigns evidence-before-completion to a Verifier agent.
- `registry/adoption-ledger.yml:149-167` hardwires gates into Standard/Orchestrated and retains a
  reviewer-to-diff-reviewer migration.

Neither file establishes its own history-only or non-authoritative fence. Their reviewed hashes
were:

```text
docs/research/conflict-matrix.md = 8E069AD00DCE16A8E5B072077E27F94FCB875EA0A19939CE57BAE8B872D27E13
registry/adoption-ledger.yml     = F793AE77146E8E07A4DE52DCC88759C3E8CF33F81C3C5DA538D20CE2721343E9
```

That conflicts with `spec/key/01-dna.md:145-152,180-187`,
`spec/04-workflow-sizing.md:142-170`, and `spec/13-validation-and-evaluation.md:5-9`, which make
the roster Topic-03-selected, dispatch optional, review contract/risk-gated, and sequential
Orchestrated execution valid. Under the Round-7 rule that research/registry text is
non-authoritative only where its own text supplies the fence, this reopens the selected-manifest
and authority-fence cluster.

### R7-F2 — Important — Target architecture still permits unflagged selected-model misrouting

`spec/01-target-architecture.md:166-172` projects model acceptance through alias hard failures,
project precedence, and rejection of `resolvedModelIsFallback == true`. It never requires
reconciliation of `task.agentModelOverrides` or comparison of returned `modelRole` and
`resolvedModel` against the selected identity.

Pinned source shows why the fallback flag alone is insufficient:

- `task/structured-subagent.ts:281-294`: `task.agentModelOverrides` takes precedence.
- `config/model-resolver.ts:1399-1421` and `task/executor.ts:2840-2867`: credential failure may
  fall back to the parent model.
- `task/executor.ts:1707-1715`: `resolvedModelIsFallback` is set for retry fallback, not that
  credential-fallback branch.

The complete contract exists in `spec/09-model-routing.md:151-160,201-205`,
`spec/13-validation-and-evaluation.md:124-128`, and
`spec/phases/phase-06-evaluation.md:115-120`, but its omission from an active load-bearing
architecture summary leaves an implementation following that summary able to false-accept an
override or credential fallback.

### R7-F3 — Important — The declared settings freeze makes prerequisite phases impossible

`spec/README.md:261-269` forbids “Any settings change to the frozen baseline before phase-06
provides evidence.” However:

- Phase 01 must deploy conditional `task.enableLsp` at
  `spec/phases/phase-01-runtime-correctness.md:70-90`.
- Phase 03 requires compaction settings in configuration at
  `spec/phases/phase-03-context-efficiency.md:49-57`.
- Phase 05 must merge selected aliases and capability settings at
  `spec/phases/phase-05-installation-hardening.md:55-126`.

The canonical DAG at `spec/README.md:185-212` places Phase 03 and Phase 05 before, and feeding,
Phase 06. Taken literally, the prohibition prevents Phase 06’s prerequisites from being
implemented until after Phase 06 supplies the evidence, creating a circular phase gate and
disabling selected runtime paths.

### R7-F4 — Important — Active authority incorrectly equates static validation with runtime discovery

`spec/01-target-architecture.md:190-199` requires static validation passing to imply runtime
discovery succeeded. `spec/key/01-dna.md:734-737` repeats that assertion.

The canonical validation contract says the opposite:

- `spec/13-validation-and-evaluation.md:41-43`: L0 Static uses filesystem/text checks and requires
  no OMP.
- `spec/13-validation-and-evaluation.md:80-83`: OMP discovery is a separate L1 tier.
- `spec/04-workflow-sizing.md:362-363`: passing static checks does not prove runtime lifecycle
  enforcement.
- `spec/phases/phase-06-evaluation.md:50-54`: static output must be renamed so passing no longer
  implies the workflow works.

This is a direct false-evidence contradiction in active authority, not merely an aspirational
implementation detail.

## Reproducibility evidence

```text
Round-7 packet: 8A835B7ABE71B6B0B64F307BA1E0771E9EBBBCA9FD095B05348FACA2FC01321F
Round-7 prompt: 26810B9D5A56FC36DDC2CFA095AE4C7FF1402A7ED1A8F8817DF91314BDDA9FFC
Round-7 load-bearing hashes: 55/55 matched
Historical runtime pins: 7/7 matched
Immutable Round-1-through-Round-5 artifacts: 20/20 matched

Repository branch: main
Repository HEAD: 62fecf277dc9d5e47d06319387eac747462214c1
Staged paths: 0

Pinned OMP HEAD: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
Pinned OMP status: clean
Pinned OMP version: 17.2.10

Topic-02 mutation self-test: 107/107 PASS
Focused Topic-02 validator: 449 passed, 0 warnings, 0 failed
All Phase-00 Pester suites: 329 passed, 0 failed
Focused T-00.3 suite: 28 passed, 0 failed
Full repository validator: 102 passed, 1 warning, 0 failed
Sole warning: pre-existing RULES approximate budget, 226 < 300
git diff --check: exit 0; only the disclosed Phase-00 CRLF advisory
Phase DAG: 9 expected edges, 9 reciprocal projections, 0 failures
Pinned OMP source claims: 12/12 reproduced
```

Required test activity was confined to guarded system-temporary/TestDrive fixtures. The reviewer
reported no repository cleanup target was used.

## Prior-finding dispositions

- **R1-F1 — CLOSED.** Verification/review is locked before task start and covered by material
  contract change.
- **R1-F2 — REOPENED at the semantic-equivalent authority level by R7-F1.** DNA itself is
  topology-neutral, but unfenced active projections restore the fixed roster and Reviewer.
- **R1-F3 — CLOSED at its original spec-13/Phase-06 locus.** R7-F1 separately reopens the
  repository-wide selected-manifest cluster.
- **R2-F1 — CLOSED at its corrected loci, but its fixed-topology semantic class is reopened by
  R7-F1.**
- **R3-F1 — CLOSED** at the corrected batch/LSP/isolation/schema/settings loci.
- **R4-F1 — CLOSED** at the corrected DNA/KD/spec/phase loci; R7-F1 is a new unfenced equivalent.
- **R5-F1 — CLOSED.** A selected LSP contract cannot degrade to grep by disclosure alone.
- **R5-F2 — CLOSED.** Context7/web uses named unresolved reasons without an exhaustion gate.
- **R5-F3 — CLOSED.** Offload/isolation/retention is not tied merely to Standard.
- **R6-F1 — CLOSED.** Primary owners contain all four registration gates plus applicable-server
  and required-call outcome gates.
- **R6-F2 — CLOSED.** `context7_unavailable` and `web_unavailable` do not falsely satisfy
  unresolved freshness.

Round-6 clusters: selected manifest and authority fences are open via R7-F1; alias/model identity
is open via R7-F2; settings phase ownership is open via R7-F3; static/runtime evidence separation
is open via R7-F4. Structured output, effort, forced partial, plan mode, retrieval tools,
recursion, Phase-00 supersession, and batch/isolation/bash/barrier/LSP mechanics are closed.

## Twelve mandatory answers

1. **Yes.** Verification/review obligations are locked before task start and material change
   invalidates the lock.
2. **Yes at DNA; no repository-wide.** R7-F1 restores conflicting fixed authority elsewhere.
3. **Yes at spec 13 and Phase 06.** They consume the selected manifest; the broader architecture
   remains incomplete because of R7-F2.
4. **Yes.** The LSP path covers all four registration gates, applicable-server routing, and each
   required call’s `details.success`.
5. **Yes.** Entry and reclassification semantics match pinned OMP behavior.
6. **Yes.** Task/work-unit/candidate/session/evidence boundaries are implementable.
7. **Yes.** Compaction, handoff, fork, and resume preserve the intended distinctions.
8. **Yes.** Forced budget partials remain nonterminal and evaluation categories stay separate.
9. **No repository-wide.** Canonical workflow is structural/sequential, but R7-F1 mandates agents
   and a dedicated Reviewer elsewhere.
10. **No.** Most paths are conditional and fail-closed, but R7-F2 leaves selected-model identity
    incomplete in target architecture.
11. **Yes.** Cheap Scout remains simple, optional, configurable, read-only, and fail-soft without
    token/lifecycle gating.
12. **No overall.** Mechanical evidence is reproducible, but R7-F1, R7-F3, and R7-F4 remain
    contradictory executable projections.

## No-write confirmation

The reviewer made no repository or pinned-OMP writes and did not edit, format, stage, commit,
reset, clean, move, or delete any file. Required fixtures were confined to guarded temporary
locations. The repository retained zero staged paths, frozen load-bearing hashes remained
unchanged, and the pinned OMP checkout remained clean.
