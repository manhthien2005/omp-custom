# Codex peer-review packet — Topic 02 closure — Round 2

```yaml
topic: 02-workflow-entry-task-lifecycle
review_round: 2
round1_verdict: REOPEN_TOPIC_02
reviewer: fresh-codex-peer
reviewer_substitution: explicitly-authorized-by-user
review_mode: read-only
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
repository_branch: main
runtime_implemented: false
phase02_runtime_migration_pending: true
historical_phase00_evidence_preserved: true
original_opus_status: unavailable-no-account-or-quota
```

## 1. Authority and evidence chain

The user approved the Topic 02 design and explicitly authorized Codex as temporary reviewer
because Claude Opus has no usable account/quota. Acceptance still requires no Critical or
Important scoped defect.

Read the correction ledger first after this packet:

`codex-topic02-round1-correction-ledger.md`

Expected SHA-256:

`BE9CE1AAA904D2D03E06973364FA7294690DEA5B59B63FAD026F59F8E7B4FAC9`

Round-1 evidence is immutable:

| Artifact | SHA-256 |
|---|---|
| `codex-peer-review-packet-topic02-round1.md` | `B26118D339C644B75035CA0EFA8B1C443AE0CE7086B31877AEFD0A912EF7D20E` |
| `codex-peer-review-prompt-topic02-round1.md` | `470B915043336395E61C633DCA1FDB1837EA2ED9964ABAF6767CAD1B85122CE6` |
| `codex-peer-review-response-topic02-round1.md` | `4821FC972FD2828BFDDC3C4167BF2A3AB39C7BB99ABA09B32FA5E12C3B9D06B9` |
| `codex-peer-review-response-topic02-round1-attempt-01-blocked-input.json` | `01FB30C8687C268F9634D1E891C690604B0895F3D53CA78A86168DEE1B64EC7C` |

The substantive Round-1 verdict was `REOPEN_TOPIC_02` with three Important findings. Do not
accept because the correction ledger claims they are fixed; independently falsify each
correction and recheck the complete contract.

## 2. Approved contract

1. Plain natural-language requests are normal entry; no workflow prefix is required.
2. The user explicitly selects Quick with `/quick`. The main-session Tech Lead validates Quick
   and selects Standard or Orchestrated. Slash Standard/Orchestrated forms remain compatibility
   hints; the same words without `/` are natural-language hints.
3. Reclassification is internal, preserves valid discovery/workspace changes, and neither
   reinvokes slash commands nor silently enlarges scope/authority.
4. A task begins only when objective, scope/authority, mandatory acceptance criteria, and
   required verification and review obligations are locked in one accepted contract. A
   material change to any locked element opens a linked task/session.
5. A candidate is a frozen snapshot. Acceptance-bearing mutation invalidates its evidence and
   requires C2 or later. Work-unit evidence cannot accept the integrated parent task.
6. A session serves one task and one non-competing candidate lineage. Compaction preserves
   identity; handoff creates a reconciled successor; fork is deliberate; resume reconciles the
   contract, candidate, and workspace.
7. Task terminals are accepted, cancelled, and terminally blocked. Partial, recoverable
   blocked, waiting-for-user, and rework are nonterminal. `accepted_with_waiver` remains a
   non-promoting evaluation classification; waiving a mandatory criterion changes the contract.
8. Standard is one integrated lane. Orchestrated requires at least two independently
   verifiable work units, explicit unit contracts, a task-level integration contract, and
   cross-boundary verification. Size/risk/file count/agent count do not select it.
9. Worker dispatch, fixed roles, multiple agents, parallel writers, parallel execution, and a
   separate reviewer are not required by Orchestrated classification. Topic 03 owns the final
   topology. Review is contract/risk-gated.
10. L0/L1 validation consumes the Topic 03-selected topology manifest: selected workers,
    actually referenced model roles, required stage barriers, and capabilities are derived from
    it. Batch/isolation/LSP/bash checks activate only for a selected path that consumes them.
    The main-session Tech Lead must not accidentally become a second discovered project worker.
11. Cheap Scout remains optional, configurable, read-only, and fail-soft. Its failure falls
    back to the retrieval path the Tech Lead needs without lifecycle effects or token gating.
12. Topic 04 owns durable lifecycle state, Topic 08 deeper triage, and Phase 06 the future
    evaluation harness. Phase 02 owns runtime projection with a new current-product evidence
    identity. Historical Phase 00 evidence is not rewritten.

## 3. Round-1 findings that must be closed

### R1-F1 — Contract-gate lock

Required verification/review obligations must appear in the design, canonical `spec/04`,
KD-026, DNA projection, active Phase 02 migration, material-change rule, and focused guard. Try
to start or continue a task while changing gates inside one contract.

### R1-F2 — DNA topology/review authority

DNA must make main-session ownership the invariant, assign final topology to Topic 03, fence
the former roster as non-authoritative history, express independent evidence without a
permanent named Verifier, and avoid unconditional Orchestrated review. Check that historical
details cannot be read as active authority.

### R1-F3 — Topology-neutral L0/L1

`spec/13` and Phase 06 must derive workers, roles, barriers, and capabilities from the Topic
03-selected manifest. A sequential Orchestrated topology, a topology with merged/renamed roles,
or a topology without LSP/parallel isolation must not fail merely because it differs from the
old roster. Required gates for a selected path must still fail closed.

## 4. Mandatory read order

1. This packet.
2. `codex-topic02-round1-correction-ledger.md`.
3. `codex-peer-review-response-topic02-round1.md`.
4. `docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md`.
5. KD-026 in `spec/key/04-decision-log.md`.
6. Canonical `spec/04-workflow-sizing.md`.
7. `spec/key/01-dna.md` and `spec/03-agent-topology.md`.
8. `spec/13-validation-and-evaluation.md` and Phase 06.
9. The remaining files in §5, then the focused validator helper/self-test/wrapper.
10. Pinned OMP source anchors in §7 and historical pins in §6.

In active-authority scans, `spec/phases/phase-02-core-orchestration.md` content below
`## Appendix A — Superseded Pre-Topic-02 Plan (Reference Only)` is explicit history, not active
Phase 02 authority. Verify the boundary exists; do not silently treat the appendix as current.

## 5. Corrected load-bearing SHA-256 table

| File | Expected SHA-256 |
|---|---|
| `codex-topic02-round1-correction-ledger.md` | `BE9CE1AAA904D2D03E06973364FA7294690DEA5B59B63FAD026F59F8E7B4FAC9` |
| `docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md` | `1A9F0DD9449B18FF56F870EA0F0B57739E2F7D494429269C6BAAFF1F22A9204A` |
| `spec/01-target-architecture.md` | `E022AC1C7BDA7DC27FFEBA41ECFB807B716925C7033B9CBA60B59916D884859A` |
| `spec/03-agent-topology.md` | `F2AF9FE39C7C942F03CBA5D158F45A60ACE65888707A8171CE17C2CB07389266` |
| `spec/04-workflow-sizing.md` | `DBD99DCD3871142B8C22EE6EEBF51AC833097CB8841C8E9E65DA6F8A5FF273CF` |
| `spec/05-context-and-token-model.md` | `76DDFBE46AE412CB298E296702C90C109E4B032A43AC3AA409AE592CC163FFB8` |
| `spec/08-isolation-and-concurrency.md` | `B1B38CFE6EDE9218D595A40B6C45EC92172DB189F83D29791F2858A584E5EF19` |
| `spec/10-verification-and-review.md` | `331C7F17E57D634FCF77CFB3B789D7FA71CA6DF6FC596CFDD08AA41EB032818C` |
| `spec/13-validation-and-evaluation.md` | `CFE96317B33ACDEAB81D3E853DDDE3B72955EAC91E5849E23112C2F46655A23D` |
| `spec/README.md` | `98D08A9E0484C99204708E0B39B354AA6975D0853A9A45DDB83491CC5C1CC2A1` |
| `spec/key/01-dna.md` | `81FDC69E8A1563EC17C9215537AA92F61AC91BFC8FCBE17FA96F1F61C319E544` |
| `spec/key/03-token-quality-model.md` | `3015BE8C1B5D540274547508C5CF2110445071267D4F21D643159962F6079989` |
| `spec/key/04-decision-log.md` | `64FD57060E38249A241D657C3E6520023B876985E7D858106BD801687FBE9760` |
| `spec/phases/phase-02-core-orchestration.md` | `0F98830CF5E3E47892FD9B00B1309F31CF321FD7E8C550DB86AF0E863AD3F0BC` |
| `spec/phases/phase-03-context-efficiency.md` | `D31591F84DBD6484F0736983541A336D8ED6BB1EC5B141C9164CE679B0366095` |
| `spec/phases/phase-06-evaluation.md` | `0CA71FD4CDA5708B48E13C7EC4BA99202CD2027A722D71E056E0A96375AE4ABD` |
| `scripts/lib/topic02-workflow-lifecycle.ps1` | `FFEFDD3F98002E8F1F23D9955FAE2F67BE79805991F706B69B26D567340940FE` |
| `scripts/tests/topic02-workflow-lifecycle.Tests.ps1` | `38848B5F70CF4860CC5ED3EE567F1CB1803E198A492D4CA3F541485FF0A59814` |
| `scripts/validate-topic02-workflow-lifecycle.ps1` | `EC4F5BC38194C3DB4E486D77BDEBC1AAA73E335A49746CCDC44B31AA447582A4` |
| `CHANGELOG.md` | `C83FF7B6886E682B23B23ACC1A5F37D57DF07F77A90E26401AB55C6A110350C0` |
| `codex-topic02-workflow-entry-task-lifecycle-changelog.md` | `B966276CE8C92CC78108921119415163B35D9CAE7EDBAA52C1C7B34FCD18C97B` |

Execute byte-level hashing. `INSUFFICIENT_EVIDENCE` is valid only after a command actually
produces a mismatch, a required file/source is absent, or the supplied evidence contradicts
itself. Include exact command/output.

## 6. Historical Phase 00 pins

| File | Expected SHA-256 |
|---|---|
| `template/.omp/AGENTS.md` | `3F194D81208872B6CDE4A51265156D06A8016810CAA9D24BF37B545E60848BBC` |
| `template/.omp/agents/tech-lead.md` | `47B3060A725F9C41EA832E2CE8E7CBAEFCAFACB4137A9B4153C2819732016AD2` |
| `template/.omp/commands/quick.md` | `F4E9081846368DA140923C8D51C7BAB079DA4B75577019A412735DBAC4A21731` |
| `template/.omp/commands/standard.md` | `F849485369F0E8EE6D7D816752D7CAD263DA5381EF8216C319B19091FCBB626B` |
| `template/.omp/commands/orchestrated.md` | `D88179FA0C27B9EEDF9EE59B5CD6A59B75FC426BCDAD18061209942C36012D12` |
| `template/.omp/skills/task-triage/SKILL.md` | `D398AFAE80D199F6951C988A4D13C90FD4EFDE4E2B1290CF8A9AB642977430BC` |
| `scripts/validate-template.ps1` | `D78594BA7DD28C843BDCCEC6F532FBBB491C9E380FD91B686B2AA70850D61701` |

Re-run: focused self-test (expected 12 assertions), focused validator (expected `81/0/0`),
full validator (expected `102/1/0`, only pre-existing RULES budget warning), active-authority
contradiction scans, `git diff --check`, repository identity/staging, and Phase DAG checks.

## 7. Pinned OMP source claims

Pinned checkout: `_research/upstreams/oh-my-pi`, expected clean commit
`3a8591a8af5b6d200088d12ca75a5517cb064fa8` (17.2.10).

1. `packages/coding-agent/src/extensibility/slash-commands.ts:110-129` leaves non-slash text
   unchanged.
2. `packages/coding-agent/src/session/agent-session.ts:4942-4966` gates command handling on
   slash-prefixed input.
3. `packages/coding-agent/src/session/session-handoff.ts:97-103,217-275` creates a new session,
   resets session-scoped state, and injects generated handoff text; that text is context, not
   durable lifecycle authority.

## 8. Ten mandatory questions

1. Are required verification/review obligations locked before task start and covered by the
   material-contract-change rule everywhere authoritative?
2. Is DNA now genuinely topology-neutral, with the former roster unmistakably non-authoritative
   and no permanent named Verifier or unconditional Orchestrated reviewer rule?
3. Do `spec/13` and Phase 06 consume a Topic 03-selected manifest without exact count/name
   assumptions while still validating every selected barrier/capability fail-closed?
4. Are no-prefix, `/quick`, compatibility, missing-slash, and internal reclassification semantics
   coherent with pinned OMP slash handling?
5. Are task/work-unit/candidate/session boundaries and evidence invalidation implementable?
6. Do compaction/handoff/fork/resume preserve the intended identity/ownership distinctions?
7. Are lifecycle terminal state and Topic 01 evaluation classification separated without a
   waiver/partial/blocked/waiting denominator loophole?
8. Is Orchestrated structural and sequentially implementable without mandatory agents,
   parallelism, isolation, or review?
9. Is Cheap Scout still simple, optional, read-only, configurable, and fail-soft?
10. Are Topic 03/04/08, Phase 02/03/06, Phase 00 history, dependencies, and all runtime
    non-claims honest and non-contradictory?

## 9. Verdict policy

Return exactly one:

```text
ACCEPT_TOPIC_02
REOPEN_TOPIC_02
INSUFFICIENT_EVIDENCE
```

`ACCEPT_TOPIC_02` requires all three Round-1 Important findings closed and no other Critical or
Important scoped defect. Minor findings may coexist only when they cannot change entry
authority, task/candidate/session identity, evidence validity, lifecycle/evaluation category,
topology ownership, selected-path safety, fallback behavior, phase ownership, historical
evidence, runtime feasibility, or reproducibility. Preferences for a fixed roster, universal
review, mandatory parallelism, or a more elaborate Cheap Scout policy are trade-offs, not
defects, unless the approved contract is contradictory, unsafe, unimplementable, or weakened.
