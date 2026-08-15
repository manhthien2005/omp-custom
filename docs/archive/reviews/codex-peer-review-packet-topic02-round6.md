# Codex peer-review packet — Topic 02 closure — Round 6

```yaml
topic: 02-workflow-entry-task-lifecycle
review_round: 6
round1_verdict: REOPEN_TOPIC_02
round2_verdict: REOPEN_TOPIC_02
round3_verdict: REOPEN_TOPIC_02
round4_verdict: REOPEN_TOPIC_02
round5_verdict: REOPEN_TOPIC_02
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

The user approved the Topic-02 design and explicitly authorized Codex as temporary independent
reviewer because Claude/Opus has no usable account or quota. Acceptance still requires no
Critical or Important scoped defect.

This packet identifies the frozen Round-6 snapshot. The reviewer is read-only: do not edit,
format, stage, commit, reset, clean, move, or delete anything. Independently reproduce hashes,
source claims, validators, Git facts, history fences, and contract semantics.

Read the Round-5 correction ledger immediately after this packet:

`codex-topic02-round5-correction-ledger.md`

Expected SHA-256:

`9693849ECF51FD300904438D90824690A0B5E18C0EF9D5251A5011F92964A1FD`

Earlier evidence is immutable:

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
| `codex-topic02-round2-correction-ledger.md` | `1A053EEDB6987AC6E61898DB63E63E8998A39E28B7EB4CCC28C50EB43FB3D348` |
| `codex-peer-review-packet-topic02-round3.md` | `2D809ED7ED1776CB3E5A7FCEE7C6D28D33D72942E628DD770CC670995DAE6295` |
| `codex-peer-review-prompt-topic02-round3.md` | `B0A538E2ECFC4213E8FDE79FACD169047273A6C6E8428074FEF6598369B671C5` |
| `codex-peer-review-response-topic02-round3.md` | `EAA5737DD5663A6B354BA13E821D0A7BEB8F308DE6D0A07DC809D22E25536D58` |
| `codex-topic02-round3-correction-ledger.md` | `F0C61C044EB62C3151B2DD097E80E418FF4B5A77DF14798E10DB5E390169B305` |
| `codex-peer-review-packet-topic02-round4.md` | `0EC39794C5E11C4B790DD937C59B02FB35AA11240DCBFB8C52995A9F79BAA63E` |
| `codex-peer-review-prompt-topic02-round4.md` | `111D33A676615F24181131F085D7BEFF8C22F3DF9613144376E4EA261A4BD8FB` |
| `codex-peer-review-response-topic02-round4.md` | `7015D11AF9A8CA3880468D9EADFAE28C1BC1A8AEAEF792EF1AD77557465D2FE7` |
| `codex-topic02-round4-correction-ledger.md` | `0EFC0F62F60373E34A1699FF243B62BA83DD917ADA1E0E4C7263F0E548C0A40F` |
| `codex-peer-review-packet-topic02-round5.md` | `CE94F2F14B6C6C4E64DD71F11A56C709E01FC431445EF975D096BF618B270B5B` |
| `codex-peer-review-prompt-topic02-round5.md` | `E78C65E3751D53ACF7D335C3C2EF0AA69B0D7B7F976B2CED2C7D2EE87AFC4FE3` |
| `codex-peer-review-response-topic02-round5.md` | `EB7DAAAF7C59A96625F380CF043AF0D05A926636DD6433F183649A4A00DD7CDF` |

Rounds 1–4 repeatedly found incomplete projection of task-contract and topology-neutral
authority. Round 5 found that the selected LSP-consuming contract still ran with weaker
semantics instead of failing closed, plus two Minor drifts. Treat every disposition as open
until independently falsified against this exact snapshot.

## 2. Approved Topic-02 contract

1. Plain natural-language requests are normal entry; no workflow prefix is required.
2. The user explicitly selects Quick with `/quick`. The main-session Tech Lead validates Quick
   and selects Standard or Orchestrated. Slash Standard/Orchestrated forms remain compatibility
   hints; the same words without `/` are natural-language hints.
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
   non-promoting evaluation classification; waiving a mandatory criterion changes the contract.
8. Standard is one integrated lane. Orchestrated requires at least two independently verifiable
   work units, explicit unit contracts, a task-level integration contract, and cross-boundary
   verification. Size, risk, file count, and agent count do not select it.
9. Worker dispatch, fixed roles, multiple agents, parallel writers, parallel execution, and a
   separate reviewer are not required by Orchestrated classification. Topic 03 owns final
   topology. Review is contract/risk-gated.
10. Validation consumes the Topic-03-selected topology/runtime manifest. Batch, isolation, LSP,
    command execution, blocking, schemas, skills, aliases, and owned settings activate only for
    selected contracts that consume them. Required selected-path checks remain fail-closed.
11. Cheap Scout is optional, configurable, read-only, and fail-soft. Failure falls back to the
    retrieval path the Tech Lead needs without lifecycle effects, token gating, or token-weight
    analysis.
12. Topic 04 owns durable lifecycle state, Topic 08 deeper triage, and Phase 06 the future
    evaluation harness. Phase 02 owns runtime projection with a new current-product evidence
    identity. Historical Phase-00 evidence is not rewritten.

## 3. Findings that must be independently closed

### R1-F1 — Contract-gate lock

Verification/review obligations must remain locked before task start and covered by the
material-contract-change rule in the design, canonical spec, KD-026, DNA, active Phase 02, and
focused guard.

### R1-F2 — DNA topology/review authority

DNA must keep main-session ownership as the invariant, assign final topology to Topic 03, fence
the former L2 roster as non-authoritative, and keep every later active gene responsibility-based.
It must express independent evidence without a permanent named Verifier and keep review
contract/risk-gated.

### R1-F3 / R2-F1 / R3-F1 / R4-F1 / R5-F1 — Complete selected-path projection

Independently falsify the Round-5 correction rather than trusting its ledger:

1. A selected LSP-consuming path whose allowlist, `task.enableLsp`, parent-session LSP, or
   `lsp.enabled` gate is unmet must stop before dispatch or acceptance.
2. Disclosure cannot make `grep` an acceptable continuation of the same symbol-aware contract.
3. A user's explicit setting remains preserved; continuation requires remediation or explicit
   Tech-Lead selection of a different non-LSP contract, manifest/task-contract reconciliation,
   and validation. A material locked-criterion or verification/review change still opens a
   linked task/session.
4. A topology whose selected contract does not consume LSP remains valid and is not forced to
   install or enable LSP.
5. Search DNA, target architecture, decision authority, specs 07/10/12/13, every active phase,
   install docs, acceptance/contract summaries, and semantic equivalents beyond the focused
   guard. Compare LSP behavior against bash, schemas, skills, aliases, batch, and isolation
   without incorrectly requiring identical mechanisms.
6. Confirm the helper's whitespace normalization catches wrapped required and forbidden
   semantics without masking a real contradiction, and that every new mutation fixture fails
   for the intended reason when reintroduced.

### R5-F2 — Bounded retrieval escalation

Phase 03 must project spec 07's default-priority, bounded-escalation rule. Named permitted skips
are valid when disclosed; every retrieval level is not an exhaustion gate.

### R5-F3 — Offload safety follows isolation/retention

`.task/` offload must be allowed only when the worker is non-isolated and the workspace survives
the Tech-Lead lifecycle. It must not be restricted by the Standard workflow name because
sequential non-isolated Orchestrated execution is valid. Isolated workers require a durable
parent artifact domain.

Also re-audit the Round-4 surfaces: DNA L3–L7, KD-002/KD-004/KD-017, specs 06/11/13,
Phase 01, and Phase 06 must remain selected-manifest-driven rather than restoring fixed roster,
schema, skill-count, isolation, or review authority.

## 4. Mandatory read order and history fences

1. This packet.
2. `codex-topic02-round5-correction-ledger.md`.
3. `codex-peer-review-response-topic02-round5.md`.
4. Round-4 through Round-1 correction ledgers and substantive responses.
5. The design, KD-026/KD-002/KD-004/KD-006/KD-017, canonical `spec/04`, DNA, and `spec/03`.
6. Every remaining file in the Round-6 load-bearing table.
7. The focused helper, mutation self-test, and wrapper.
8. Pinned OMP source anchors, historical pins, Git identity/staging, and Phase DAG.

`spec/03-agent-topology.md` sections B–I remain pre-Topic-03 hypotheses beneath an explicit
non-authority fence. In Phase 02, content below
`## Appendix A — Superseded Pre-Topic-02 Plan (Reference Only)` remains explicit history.
Phase 00 remains historical evidence. Verify all fences before excluding their retained
baseline statements. Other research/dossier documents are evidence, not decision authority,
only where their own headers say so; do not infer a history fence that is absent.

The stale reduced-capability wording retained in historical Phase 00 and Phase-02 Appendix A
must not be treated as active authority, but the reviewer must first verify that those exact
fences cover it. A similar phrase in any unfenced active document remains actionable.

## 5. Frozen Round-6 load-bearing SHA-256 table

| File | Expected SHA-256 |
|---|---|
| `codex-topic02-round5-correction-ledger.md` | `9693849ECF51FD300904438D90824690A0B5E18C0EF9D5251A5011F92964A1FD` |
| `docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md` | `1A9F0DD9449B18FF56F870EA0F0B57739E2F7D494429269C6BAAFF1F22A9204A` |
| `spec/01-target-architecture.md` | `71E48A4320F21A784E87F82EBC56727C6976C14085C5A1DE14C787E8A5BD5A92` |
| `spec/03-agent-topology.md` | `F2AF9FE39C7C942F03CBA5D158F45A60ACE65888707A8171CE17C2CB07389266` |
| `spec/04-workflow-sizing.md` | `DBD99DCD3871142B8C22EE6EEBF51AC833097CB8841C8E9E65DA6F8A5FF273CF` |
| `spec/05-context-and-token-model.md` | `9AC69603D50BF2966906BEDCB22BAAEDFBBDEB15FD3B3ACEA5EB50CFDB02544E` |
| `spec/06-structured-output.md` | `F1EB8F518EC52FCB1D07B811874912AC8311B330CDE4F77AA2BA3BF2D00F6087` |
| `spec/07-retrieval-and-code-understanding.md` | `79EB094B303B89E245C12739387A8C3EFD99CC12C052F3AC7B71300F9054F9DB` |
| `spec/08-isolation-and-concurrency.md` | `D6FFC77B35A8CF7846376AA263BC0DDAEE1560E3562567D4E1E0A2AFBB3F2A2C` |
| `spec/09-model-routing.md` | `BA9E643BB2A10682B11EE4BF4C6868A5C4F05FD6126CC48BDDF2313EBEFFAA71` |
| `spec/10-verification-and-review.md` | `7EAD3E10B52222FCE0E94F57BB89DED4692CE3F3FEA0AC6C63B4288810B92167` |
| `spec/11-skills-rules-and-quality-gates.md` | `380BEC7B7D60CF3268C753B07F3FCFB35EA78564577D4058357C56C2F0F5D9CB` |
| `spec/12-installation-and-rollback.md` | `9F284EC8A652801DD10AFD8D4163E49D5BFAE7AE477AC6F242AF0D4D2B3CB19F` |
| `spec/13-validation-and-evaluation.md` | `28500C45BCAE811FE066A6935E4E029FEE43B4896F9FF00B6CEA19B8B167AD37` |
| `spec/15-security-and-failure-recovery.md` | `BAE8C825C1BB6D87717F6B2D0B9D7EBAF97DE2C04BDD08768E5DE248062EE250` |
| `spec/16-migration-plan.md` | `C02CD27D1C294744CAB8C2DFEB638F1A91AF723416E5BDB72BAF9A34F2FD027D` |
| `spec/README.md` | `7203A7D3CC9D961A337A1FACB739B7D0520083736D39B07BEF5C80E1E74CD2C6` |
| `spec/key/01-dna.md` | `8376DD5D4CCF05A00F5A2E928ADB4B6BFE5BAB25C8F53A12152CD25957D23C7B` |
| `spec/key/03-token-quality-model.md` | `3DCA01D082EB7D2FC5AAE70DE4178E8B820BB966B880F7A33E01B667DCD4D711` |
| `spec/key/04-decision-log.md` | `D7EF3026944F2380F8AFED74BCC0884688A8533DCE3F4A25B1B972F25F844C81` |
| `spec/phases/phase-01-runtime-correctness.md` | `58FF2161263E02BB4408485A4828C824D908EEDA98B232687F7B33385AF8080A` |
| `spec/phases/phase-02-core-orchestration.md` | `0F98830CF5E3E47892FD9B00B1309F31CF321FD7E8C550DB86AF0E863AD3F0BC` |
| `spec/phases/phase-03-context-efficiency.md` | `C56FB899B646470AD44D96526B5E60B596272F815415CCC6193A0D75F5C0FCAA` |
| `spec/phases/phase-04-quality-system.md` | `932F648757B2B2860EBB3CECC92C53BA789570F8ACBB1535CB2B6CA6B21F75A5` |
| `spec/phases/phase-05-installation-hardening.md` | `C095FF47ECC1DDCDB7FC360473221047F67FCAC4127B8585D31E9C39C21B0F9D` |
| `spec/phases/phase-06-evaluation.md` | `6619C8518DA37A3A623AC9F057482D221BECF488D6FDA8B470B12645F6EC7C57` |
| `scripts/lib/topic02-workflow-lifecycle.ps1` | `98EA82C492039EA77078771819A75C3D9CB55281BDAD42A9FDEC9CE924B3CD37` |
| `scripts/tests/topic02-workflow-lifecycle.Tests.ps1` | `A3CF83F625E642CBD9124F1F2096556929FE5C0050CFD7271DC3DFAA6B44981A` |
| `scripts/validate-topic02-workflow-lifecycle.ps1` | `EC4F5BC38194C3DB4E486D77BDEBC1AAA73E335A49746CCDC44B31AA447582A4` |
| `CHANGELOG.md` | `C83FF7B6886E682B23B23ACC1A5F37D57DF07F77A90E26401AB55C6A110350C0` |
| `codex-topic02-workflow-entry-task-lifecycle-changelog.md` | `B966276CE8C92CC78108921119415163B35D9CAE7EDBAA52C1C7B34FCD18C97B` |

Execute byte-level hashing. `INSUFFICIENT_EVIDENCE` is valid only after an actual mismatch,
missing artifact/source, inaccessible required source, or internal evidence contradiction.

## 6. Mandatory reproducibility checks

| Check | Expected result |
|---|---|
| Focused mutation self-test | `PASS Topic 02 validator self-test (78 assertions)` |
| Focused Topic-02 validator | `262 passed, 0 warnings, 0 failed` |
| Full repository validator | `102 passed, 1 warnings, 0 failed`; only pre-existing RULES budget warning |
| `git diff --check` | Exit `0`; only pre-existing Phase-00 CRLF advisory |
| Repository identity | `main`, HEAD `62fecf277dc9d5e47d06319387eac747462214c1`, zero staged paths |
| Phase DAG | nine expected reciprocal edges, zero reciprocal failures |

Re-run all checks. Perform independent active-authority searches and inspect context around every
hit. Literal validator success alone is not sufficient.

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

These are historical evidence only. Topic 02 has not migrated runtime files.

## 8. Pinned OMP source claims

Pinned checkout: `_research/upstreams/oh-my-pi`, expected clean commit
`3a8591a8af5b6d200088d12ca75a5517cb064fa8` (coding-agent 17.2.10).

1. `packages/coding-agent/src/extensibility/slash-commands.ts:110-129` leaves non-slash text
   unchanged.
2. `packages/coding-agent/src/session/agent-session.ts:4942-4966` gates command handling on
   slash-prefixed input.
3. `packages/coding-agent/src/session/session-handoff.ts:97-103,217-275` creates a new session,
   resets session-scoped state, and injects generated handoff text; the text is context, not
   durable lifecycle authority.

## 9. Twelve mandatory questions

1. Are verification/review obligations locked before task start and covered by material change?
2. Is DNA genuinely topology-neutral across L2–L7 and review contract/risk-gated?
3. Do `spec/13` and Phase 06 consume the selected manifest without count/name/schema/skill
   assumptions while keeping every selected capability path fail-closed?
4. Is R2-F1/R3-F1/R4-F1/R5-F1 now closed across all active Decision, Contract Summary,
   Acceptance, final-architecture, DNA, install, and phase surfaces?
5. Are no-prefix, `/quick`, compatibility, missing-slash, and reclassification semantics
   coherent with pinned OMP handling?
6. Are task, work-unit, candidate, and session boundaries plus evidence invalidation implementable?
7. Do compaction, handoff, fork, and resume preserve their intended ownership distinctions?
8. Are task terminals and Topic-01 evaluation categories separated without loopholes?
9. Is Orchestrated structural and sequentially implementable without mandatory dispatch,
   agents, batch, parallelism, isolation, or review?
10. Are schemas, skills, aliases, barriers, LSP, bash, batch, and isolation conditional yet
    fail-closed when their selected contract consumes them?
11. Is Cheap Scout simple, optional, configurable, read-only, fail-soft, and free of token or
    lifecycle gating?
12. Are phase ownership, history, runtime non-claims, hashes, source evidence, Git identity, and
    dependencies honest and reproducible?

## 10. Verdict policy

Return exactly one:

```text
ACCEPT_TOPIC_02
REOPEN_TOPIC_02
INSUFFICIENT_EVIDENCE
```

`ACCEPT_TOPIC_02` requires all prior Important findings closed and no other Critical or
Important scoped defect. Minor findings may coexist only when they cannot change entry
authority, lifecycle identity, evidence validity, topology ownership, selected-path safety,
fallback behavior, phase ownership, historical evidence, runtime feasibility, or
reproducibility.

Preferences for fixed roles, universal review, mandatory parallelism, or elaborate Cheap Scout
optimization are not defects unless the approved contract becomes contradictory, unsafe,
unimplementable, weakened, or irreproducible.
