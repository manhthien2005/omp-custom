# Codex peer-review packet — Topic 02 closure — Round 3

```yaml
topic: 02-workflow-entry-task-lifecycle
review_round: 3
round1_verdict: REOPEN_TOPIC_02
round2_verdict: REOPEN_TOPIC_02
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

## 1. Authority, frozen scope, and evidence chain

The user approved the Topic-02 design and explicitly authorized Codex as the temporary
independent reviewer because Claude/Opus has no usable account or quota. Acceptance still
requires no Critical or Important scoped defect.

This packet identifies the frozen Round-3 review snapshot. The reviewer is read-only: do not
edit, stage, commit, reset, clean, move, or delete anything. Do not accept a correction merely
because its ledger claims success; independently reproduce hashes, source claims, validators,
Git facts, and the semantics of the complete contract.

Read the Round-2 correction ledger immediately after this packet:

`codex-topic02-round2-correction-ledger.md`

Expected SHA-256:

`1A053EEDB6987AC6E61898DB63E63E8998A39E28B7EB4CCC28C50EB43FB3D348`

Earlier review evidence is immutable:

| Artifact | SHA-256 |
|---|---|
| `codex-peer-review-packet-topic02-round1.md` | `B26118D339C644B75035CA0EFA8B1C443AE0CE7086B31877AEFD0A912EF7D20E` |
| `codex-peer-review-prompt-topic02-round1.md` | `470B915043336395E61C633DCA1FDB1837EA2ED9964ABAF6767CAD1B85122CE6` |
| `codex-peer-review-response-topic02-round1.md` | `4821FC972FD2828BFDDC3C4167BF2A3AB39C7BB99ABA09B32FA5E12C3B9D06B9` |
| `codex-peer-review-response-topic02-round1-attempt-01-blocked-input.json` | `01FB30C8687C268F9634D1E891C690604B0895F3D53CA78A86168DEE1B64EC7C` |
| `codex-topic02-round1-correction-ledger.md` | `BE9CE1AAA904D2D03E06973364FA7294690DEA5B59B63FAD026F59F8E7B4FAC9` |
| `codex-peer-review-packet-topic02-round2.md` | `7823E99DB0E917C267FF8BD0C87F53B463056A50A842BB1434E69A56D732008A` |
| `codex-peer-review-prompt-topic02-round2.md` | `7BA1D68228F1D0E9A148A6F24FFDCF75BFB4F6A91B6FCCC4A5154C0E62282FE1` |
| `codex-peer-review-response-topic02-round2.md` | `A3719F5823E933FA4BDEC0E7BA9D3E686C279A57E5091BF36D421E2F6CE8AB32` |

Round 1 found three Important defects. Round 2 independently closed all three, then found one
new Important defect: active non-DNA documents still projected a permanent named Verifier,
fixed roster, or topology-owned capability as current authority. Round 3 must close all four
findings and search for semantic equivalents outside the phrases covered by the validator.

## 2. Approved Topic-02 contract

1. Plain natural-language requests are normal entry; no workflow prefix is required.
2. The user explicitly selects Quick with `/quick`. The main-session Tech Lead validates
   Quick and selects Standard or Orchestrated. Slash Standard/Orchestrated forms remain
   compatibility hints; the same words without `/` are natural-language hints.
3. Reclassification is internal, preserves valid discovery and workspace changes, and neither
   reinvokes slash commands nor silently enlarges scope or authority.
4. A task begins only when objective, scope/authority, mandatory acceptance criteria, and
   required verification/review obligations are locked in one accepted contract. A material
   change to any locked element opens a linked task/session.
5. A candidate is a frozen snapshot. Acceptance-bearing mutation invalidates its evidence and
   requires C2 or later. Work-unit evidence cannot accept the integrated parent task.
6. A session serves one task and one non-competing candidate lineage. Compaction preserves
   identity; handoff creates a reconciled successor; fork is deliberate; resume reconciles the
   contract, candidate, and workspace.
7. Task terminals are accepted, cancelled, and terminally blocked. Partial, recoverable
   blocked, waiting-for-user, and rework are nonterminal. `accepted_with_waiver` remains a
   non-promoting evaluation classification; waiving a mandatory criterion changes the
   contract.
8. Standard is one integrated lane. Orchestrated requires at least two independently
   verifiable work units, explicit unit contracts, a task-level integration contract, and
   cross-boundary verification. Size, risk, file count, and agent count do not select it.
9. Worker dispatch, fixed roles, multiple agents, parallel writers, parallel execution, and a
   separate reviewer are not required by Orchestrated classification. Topic 03 owns the final
   topology. Review is contract/risk-gated.
10. Validation consumes the Topic-03-selected topology manifest: selected workers, referenced
    model roles, required stage barriers, and capabilities derive from it. Batch, isolation,
    LSP, command execution, blocking, schemas, skills, aliases, and owned-setting checks
    activate only for selected contracts that consume them. The main-session Tech Lead must
    not accidentally become a second discovered project worker.
11. Cheap Scout remains optional, configurable, read-only, and fail-soft. Its failure falls
    back to the retrieval path the Tech Lead needs without lifecycle effects, token gating, or
    token-weight analysis.
12. Topic 04 owns durable lifecycle state, Topic 08 deeper triage, and Phase 06 the future
    evaluation harness. Phase 02 owns runtime projection with a new current-product evidence
    identity. Historical Phase-00 evidence is not rewritten.

## 3. Findings that must be independently closed

### R1-F1 — Contract-gate lock

Required verification/review obligations must be locked before task start in the design,
canonical `spec/04`, KD-026, DNA projection, active Phase-02 migration, material-change rule,
and focused guard. Attempt to change a mandatory gate while claiming the same task contract.

### R1-F2 — DNA topology/review authority

DNA must keep main-session ownership as the invariant, assign final topology to Topic 03, fence
the former roster as non-authoritative history, express independent evidence without a
permanent named Verifier, and avoid unconditional Orchestrated review.

### R1-F3 — Topology-neutral validation

`spec/13` and Phase 06 must derive workers, roles, barriers, and capabilities from the
Topic-03-selected manifest. Sequential Orchestrated execution, merged or renamed roles, and
topologies without LSP or parallel isolation must not fail merely for differing from the old
roster. Gates required by a selected path must still fail closed.

### R2-F1 — Active-authority projection

Every active architecture, context, output, retrieval, isolation, routing, verification,
skills, installation, evaluation, security, migration, README, token model, and phase
projection must obey the same topology boundary. Search beyond exact validator phrases for:

- a required role named Verifier, Implementer, Explorer, or Reviewer;
- an exact worker count or permanent roster;
- unconditional separate-agent or separate-session verification;
- unconditional parallel batch, writer isolation, stage barrier, command, LSP, schema, skill,
  alias, or owned-setting requirements;
- language that turns pre-Topic-03 tables into current execution or validation authority.

Required independent evidence, fail-closed selected-path checks, and reviewer independence must
not be weakened while removing fixed implementation mechanics.

## 4. Mandatory read order and history fences

1. This packet.
2. `codex-topic02-round2-correction-ledger.md`.
3. `codex-peer-review-response-topic02-round2.md`.
4. `codex-topic02-round1-correction-ledger.md` and
   `codex-peer-review-response-topic02-round1.md`.
5. The design, KD-026, canonical `spec/04`, DNA, and `spec/03`.
6. Every remaining file in the Round-3 load-bearing table.
7. The focused validator helper, mutation self-test, and wrapper.
8. Pinned OMP source anchors, historical pins, repository identity, staging, and Phase DAG.

`spec/03-agent-topology.md` deliberately retains former roster material beneath a top-level
fence declaring sections B–I pre-Topic-03 hypotheses and not execution authority until Topic 03
adjudicates them. Verify that this fence is sufficient; do not assume it is.

In `spec/phases/phase-02-core-orchestration.md`, content below
`## Appendix A — Superseded Pre-Topic-02 Plan (Reference Only)` is explicit history, not active
Phase-02 authority. Phase 00 is historical evidence. Verify both boundaries before excluding
their retained baseline statements from active-authority findings.

## 5. Frozen Round-3 load-bearing SHA-256 table

| File | Expected SHA-256 |
|---|---|
| `codex-topic02-round2-correction-ledger.md` | `1A053EEDB6987AC6E61898DB63E63E8998A39E28B7EB4CCC28C50EB43FB3D348` |
| `docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md` | `1A9F0DD9449B18FF56F870EA0F0B57739E2F7D494429269C6BAAFF1F22A9204A` |
| `spec/01-target-architecture.md` | `71E48A4320F21A784E87F82EBC56727C6976C14085C5A1DE14C787E8A5BD5A92` |
| `spec/03-agent-topology.md` | `F2AF9FE39C7C942F03CBA5D158F45A60ACE65888707A8171CE17C2CB07389266` |
| `spec/04-workflow-sizing.md` | `DBD99DCD3871142B8C22EE6EEBF51AC833097CB8841C8E9E65DA6F8A5FF273CF` |
| `spec/05-context-and-token-model.md` | `A341A741908892572DF815EF5150D4DCFD539B27C4A9B9959C51B7B7DBCA1FE1` |
| `spec/06-structured-output.md` | `7259C01CF0BA908017F7B7B3560116B903FFE91B715F1C47C0D981B42A806D8C` |
| `spec/07-retrieval-and-code-understanding.md` | `5E2D09DFDF2B5DC388D02B975FC588704BCCD1641D457607599EA55AEA14E0AD` |
| `spec/08-isolation-and-concurrency.md` | `3F085C04D261B68F3CD5E064CC78282CC3F16C7F3717F959A10B6CD09424C50C` |
| `spec/09-model-routing.md` | `BA9E643BB2A10682B11EE4BF4C6868A5C4F05FD6126CC48BDDF2313EBEFFAA71` |
| `spec/10-verification-and-review.md` | `C47CA16A22907EA2C953E4E63C5405D5B6EF925A6E0207544FB6760E0814B9FB` |
| `spec/11-skills-rules-and-quality-gates.md` | `8651DADDC8AD852B7C8BC141DF0BD8897CC498EE5AE9448A167C757964826A89` |
| `spec/12-installation-and-rollback.md` | `0C98FC3A49DF2E2FC5801706C1646C44B8B91E23DDB59B2B9BAD172E0D60DD1E` |
| `spec/13-validation-and-evaluation.md` | `0888C0E5A50C3E3928B50EE5E1FF830CA48B890CFDBA838AE13CA1BB4CFA0C14` |
| `spec/15-security-and-failure-recovery.md` | `BAE8C825C1BB6D87717F6B2D0B9D7EBAF97DE2C04BDD08768E5DE248062EE250` |
| `spec/16-migration-plan.md` | `C02CD27D1C294744CAB8C2DFEB638F1A91AF723416E5BDB72BAF9A34F2FD027D` |
| `spec/README.md` | `B0F4759562580700DBD82D01CFA1DB21D19CC9B3C82808C157DC6A1353CB5283` |
| `spec/key/01-dna.md` | `81FDC69E8A1563EC17C9215537AA92F61AC91BFC8FCBE17FA96F1F61C319E544` |
| `spec/key/03-token-quality-model.md` | `339D6B99C0E252E2328F9B7F7A7D38DA9E58FDDB76C7AF3B1B76E79EE6CA1E2F` |
| `spec/key/04-decision-log.md` | `64FD57060E38249A241D657C3E6520023B876985E7D858106BD801687FBE9760` |
| `spec/phases/phase-01-runtime-correctness.md` | `39E57565B5315530CDB74120E182BBCF24EC32DEA9C705B831DD15971CBE73F5` |
| `spec/phases/phase-02-core-orchestration.md` | `0F98830CF5E3E47892FD9B00B1309F31CF321FD7E8C550DB86AF0E863AD3F0BC` |
| `spec/phases/phase-03-context-efficiency.md` | `20C763027F3A53F2F3F5CD2A5CEDC00FB5F90C68DB2D8B89D6B3D35FF78F85CA` |
| `spec/phases/phase-04-quality-system.md` | `932F648757B2B2860EBB3CECC92C53BA789570F8ACBB1535CB2B6CA6B21F75A5` |
| `spec/phases/phase-05-installation-hardening.md` | `E586E22B800DE1A75D7397B0ACB9EBEF16CD220E8E05A623F74E1FDD123A525F` |
| `spec/phases/phase-06-evaluation.md` | `973FB9A69C411A9DB1E750FEB592F2C5F9B81F84282FB6FF44153EF17B815B27` |
| `scripts/lib/topic02-workflow-lifecycle.ps1` | `D75F94A7CBBF58613891C714289666A7585B890FCDFE3CBCB0C05CAD52B99CAC` |
| `scripts/tests/topic02-workflow-lifecycle.Tests.ps1` | `31B1AE751FE7EEE1C38281AA612B56FE086C1403AD18DA2B8143F165660EDC03` |
| `scripts/validate-topic02-workflow-lifecycle.ps1` | `EC4F5BC38194C3DB4E486D77BDEBC1AAA73E335A49746CCDC44B31AA447582A4` |
| `CHANGELOG.md` | `C83FF7B6886E682B23B23ACC1A5F37D57DF07F77A90E26401AB55C6A110350C0` |
| `codex-topic02-workflow-entry-task-lifecycle-changelog.md` | `B966276CE8C92CC78108921119415163B35D9CAE7EDBAA52C1C7B34FCD18C97B` |

Execute byte-level hashing. `INSUFFICIENT_EVIDENCE` is valid only after a command actually
produces a mismatch, a required file or source is absent, or the supplied evidence contradicts
itself. Include the exact command and output.

## 6. Mandatory reproducibility checks

Expected current results:

| Check | Expected result |
|---|---|
| Focused mutation self-test | `PASS Topic 02 validator self-test (34 assertions)` |
| Focused Topic-02 validator | `177 passed, 0 warnings, 0 failed` |
| Full repository validator | `102 passed, 1 warnings, 0 failed`; only the pre-existing `template/.omp/RULES.md` budget warning |
| `git diff --check` | Exit `0`; only the pre-existing Phase-00 CRLF advisory |
| Repository identity | branch `main`, HEAD `62fecf277dc9d5e47d06319387eac747462214c1`, zero staged paths |
| Phase DAG | nine expected reciprocal edges, zero reciprocal failures |

Re-run all checks. Also perform independent active-authority searches and inspect context around
every hit; a passing literal validator is not sufficient evidence for R2-F1.

## 7. Historical Phase-00 pins

| File | Expected SHA-256 |
|---|---|
| `template/.omp/AGENTS.md` | `3F194D81208872B6CDE4A51265156D06A8016810CAA9D24BF37B545E60848BBC` |
| `template/.omp/agents/tech-lead.md` | `47B3060A725F9C41EA832E2CE8E7CBAEFCAFACB4137A9B4153C2819732016AD2` |
| `template/.omp/commands/quick.md` | `F4E9081846368DA140923C8D51C7BAB079DA4B75577019A412735DBAC4A21731` |
| `template/.omp/commands/standard.md` | `F849485369F0E8EE6D7D816752D7CAD263DA5381EF8216C319B19091FCBB626B` |
| `template/.omp/commands/orchestrated.md` | `D88179FA0C27B9EEDF9EE59B5CD6A59B75FC426BCDAD18061209942C36012D12` |
| `template/.omp/skills/task-triage/SKILL.md` | `D398AFAE80D199F6951C988A4D13C90FD4EFDE4E2B1290CF8A9AB642977430BC` |
| `scripts/validate-template.ps1` | `D78594BA7DD28C843BDCCEC6F532FBBB491C9E380FD91B686B2AA70850D61701` |

These are historical evidence pins only. Topic 02 has not migrated runtime files; Phase 02 must
do that later under a new current-product evidence identity.

## 8. Pinned OMP source claims

Pinned checkout: `_research/upstreams/oh-my-pi`, expected clean commit
`3a8591a8af5b6d200088d12ca75a5517cb064fa8` (coding-agent 17.2.10).

1. `packages/coding-agent/src/extensibility/slash-commands.ts:110-129` leaves non-slash text
   unchanged.
2. `packages/coding-agent/src/session/agent-session.ts:4942-4966` gates command handling on
   slash-prefixed input.
3. `packages/coding-agent/src/session/session-handoff.ts:97-103,217-275` creates a new
   session, resets session-scoped state, and injects generated handoff text; that text is
   context, not durable lifecycle authority.

Verify the pinned checkout is clean at the expected commit, confirm its version, and inspect the
named source ranges directly.

## 9. Twelve mandatory questions

1. Are required verification/review obligations locked before task start and covered by the
   material-contract-change rule everywhere authoritative?
2. Is DNA genuinely topology-neutral, with former roster content unmistakably
   non-authoritative and no permanent named Verifier or unconditional reviewer rule?
3. Do `spec/13` and Phase 06 consume a Topic-03-selected manifest without exact count/name
   assumptions while still validating every selected barrier and capability fail-closed?
4. Did the R2-F1 correction reach every active authority surface without weakening required
   independent evidence or selected-path safety?
5. Are no-prefix, `/quick`, compatibility, missing-slash, and internal reclassification
   semantics coherent with pinned OMP slash handling?
6. Are task, work-unit, candidate, and session boundaries plus candidate evidence invalidation
   implementable without identity ambiguity?
7. Do compaction, handoff, fork, and resume preserve the intended ownership distinctions?
8. Are task terminal states and Topic-01 evaluation classifications separated without a
   waiver, partial, blocked, waiting, or denominator loophole?
9. Is Orchestrated structural and sequentially implementable without mandatory agents,
   parallelism, isolation, or review?
10. Do conditional capabilities remain fail-closed when a selected contract requires them,
    while absent capabilities do not select or invalidate a topology?
11. Is Cheap Scout simple, optional, configurable, read-only, fail-soft, and free of lifecycle
    or token-gating consequences?
12. Are Topic 03/04/08, Phase 02/03/06, Phase-00 history, phase dependencies, runtime
    non-claims, hashes, and reproduced evidence honest and non-contradictory?

## 10. Verdict policy

Return exactly one:

```text
ACCEPT_TOPIC_02
REOPEN_TOPIC_02
INSUFFICIENT_EVIDENCE
```

`ACCEPT_TOPIC_02` requires all three Round-1 Important findings and R2-F1 closed, with no other
Critical or Important scoped defect. Minor findings may coexist only when they cannot change
entry authority, task/candidate/session identity, evidence validity, lifecycle/evaluation
category, topology ownership, selected-path safety, fallback behavior, phase ownership,
historical evidence, runtime feasibility, or reproducibility.

Preferences for a fixed roster, universal review, mandatory parallelism, or an elaborate Cheap
Scout policy are trade-offs rather than defects unless the approved contract is contradictory,
unsafe, unimplementable, or weakened.
