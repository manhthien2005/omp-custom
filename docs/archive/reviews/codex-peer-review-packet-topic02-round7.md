# Codex peer-review packet — Topic 02 closure — Round 7

```yaml
topic: 02-workflow-entry-task-lifecycle
review_round: 7
round1_verdict: REOPEN_TOPIC_02
round2_verdict: REOPEN_TOPIC_02
round3_verdict: REOPEN_TOPIC_02
round4_verdict: REOPEN_TOPIC_02
round5_verdict: REOPEN_TOPIC_02
round6_verdict: REOPEN_TOPIC_02
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

This packet identifies the frozen Round-7 snapshot. The reviewer is read-only: do not edit,
format, stage, commit, reset, clean, move, or delete anything. Independently reproduce hashes,
source claims, validators, Git facts, history fences, Phase-00 supersession behavior, and
contract semantics.

Read the Round-6 correction ledger immediately after this packet:

`codex-topic02-round6-correction-ledger.md`

Expected SHA-256:

`3C58DB8D712ACD3A608BEF96DC7AF22EEE8C625EB678B615355E424DCEDA4BAB`

The immediately preceding review chain is immutable:

| Artifact | SHA-256 |
|---|---|
| `codex-peer-review-packet-topic02-round6.md` | `05C8FE205D8714FE421EDB98DC1FFFFB306317E9D529E02BC4FF1F138DA21291` |
| `codex-peer-review-prompt-topic02-round6.md` | `86138C60EADA88DEC773CDEB4E8E019E2D4EBDF5369A19BF486BECFD83FD1FA4` |
| `codex-peer-review-response-topic02-round6.md` | `4052DD966D5A3FC57B1833ABA3C4FFC3C36D5D121E354508B7A20667ED4252C9` |
| `codex-topic02-round5-correction-ledger.md` | `9693849ECF51FD300904438D90824690A0B5E18C0EF9D5251A5011F92964A1FD` |

Round 6 transitively pins Rounds 1–5. Reproduce the earlier chain from its packet rather than
assuming those historical dispositions. The Round-6 response itself records two Important
findings. The correction ledger additionally discloses the later semantic-equivalent breadth
clusters; none is considered closed until this review independently falsifies it.

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
    command execution, blocking, structured schemas, skills, aliases, exact model/effort,
    retrieval tools, nested delegation, and owned settings activate only for selected contracts
    that consume them. Every required selected path remains fail-closed.
11. Cheap Scout is optional, configurable, read-only, and fail-soft. Failure falls back to the
    retrieval path the Tech Lead needs without lifecycle effects, token gating, or token-weight
    analysis.
12. Topic 04 owns durable lifecycle state, Topic 08 deeper triage, and Phase 06 the future
    evaluation harness. Phase 02 owns runtime projection with a new current-product evidence
    identity. Historical Phase-00 evidence is not rewritten.

## 3. Findings and correction clusters that must be independently closed

### R1-F1 — Contract-gate lock

Verification/review obligations must remain locked before task start and covered by the
material-contract-change rule in the design, canonical spec, KD-026, DNA, active Phase 02, and
focused guard.

### R1-F2 — DNA topology/review authority

DNA must keep main-session ownership as the invariant, assign final topology to Topic 03, fence
the former L2 roster as non-authoritative, and keep later active genes responsibility-based.
Independent evidence must not imply a permanent named Verifier; review remains
contract/risk-gated.

### R1-F3 through R6-F1 — Selected LSP path

Independently test all of the following:

1. The four independent registration conditions are selected allowlist, `task.enableLsp`, parent
   session enabled and not plan mode, and `lsp.enabled`.
2. Passing all four only registers the tool. Selected symbol-aware work additionally requires an
   applicable/configured language server and `details.success: true` for every required call.
3. No matching/configured server and any `details.success: false` result stop the same selected
   contract before acceptance. A later schema-valid yield does not cure failed capability
   evidence.
4. `grep` may satisfy an explicitly different non-LSP contract only after selection,
   reconciliation, and validation. Disclosure alone is not semantic equivalence.
5. A topology that does not select LSP remains valid and is not forced to enable it.

### R6-F2 — Context7 and web availability

An unavailable level 4 uses the named/disclosed `context7_unavailable` reason and proceeds to the
next fitting accessible source. An unavailable level 5 uses `web_unavailable`; a freshness
contract remains unresolved without authoritative evidence. No silent loopback or exhaustion
gate may reappear.

### Round-6 semantic-equivalent clusters

Do not trust the ledger. Source-audit these paths independently:

- **Selected manifest:** no active fixed roster, five-file requirement, schema-per-worker,
  all-skills count, permanent review agent, or mandatory dispatch/parallel/isolation assumption.
- **Structured output:** malformed selected schemas fail full lint or yield
  `structuredOutput.status: unavailable`; acceptance requires `valid` and rejects invalid,
  unavailable, and overridden results.
- **Alias/model identity:** E2 hard failures are authoritative. Effective retry settings,
  `task.agentModelOverrides`, credential fallback, returned `modelRole`/`resolvedModel`, and
  `resolvedModelIsFallback` must be reconciled without assuming the flag detects every misroute.
- **Effort:** selected per-spawn effort requires `task.enableEffort`; exact effort also requires a
  sufficient `task.maxEffort` and matching returned effort suffix.
- **Forced partial:** a `task.softRequestBudget` force-stop cannot be accepted as completion.
- **Plan mode:** its read-only tool rewrite cannot satisfy selected mutation/fresh-command work;
  it requires a distinct planning-only contract or explicit transition and revalidation.
- **Retrieval tools:** selected `glob`, `grep`, `ast_grep`, and `web_search` require their
  effective setting gates. In particular, `astGrep.enabled` defaults false.
- **Recursion:** selected nested delegation must fit remaining `task.maxRecursionDepth`; a child
  stripped of `task` cannot plausibly satisfy the delegation contract.
- **Authority fences:** research/final/dossier/registry text must not restore current fallback,
  topology, or capability authority merely by retaining old ADOPT/final wording.
- **Phase-00 supersession:** the immutable T-00.3 conclusion retains its original model-routing
  destination hash. Only the exact declared current supersession path may differ; missing
  declaration or forged historical hash must fail.

Also search semantic equivalents outside the focused guard and compare behavior against batch,
isolation, bash, schemas, skills, aliases, settings, barriers, model routing, effort, partial
results, plan-mode transforms, retrieval tools, recursion, and LSP call outcomes. Mechanisms may
have different valid fallback shapes, but no required selected contract may false-accept.

## 4. Mandatory read order and history fences

1. This packet.
2. `codex-topic02-round6-correction-ledger.md`.
3. `codex-peer-review-response-topic02-round6.md`.
4. Round-6 packet, then Round-5 through Round-1 correction ledgers and substantive responses.
5. The design, KD-026/KD-002/KD-004/KD-006/KD-010/KD-011/KD-012/KD-017, canonical
   `spec/04`, DNA, and `spec/03`.
6. Every remaining file in the Round-7 load-bearing table.
7. The Topic-02 helper, mutation self-test, and wrapper; then the Phase-00 helper and T-00.3
   mutation suite.
8. Pinned OMP source anchors, historical pins, Git identity/staging, and Phase DAG.

`spec/03-agent-topology.md` sections B–I remain pre-Topic-03 hypotheses beneath an explicit
non-authority fence. In Phase 02, content below
`## Appendix A — Superseded Pre-Topic-02 Plan (Reference Only)` is history. Phase 00 remains
historical evidence. Research/final/dossier documents are non-authoritative only where their own
text says so; do not infer a fence. `docs/policies/model-routing.md` is a current reference with an
explicit Topic-02 supersession declaration, while the T-00.3 conclusion remains historical.

## 5. Frozen Round-7 load-bearing SHA-256 table

| File | Expected SHA-256 |
|---|---|
| `codex-topic02-round6-correction-ledger.md` | `3C58DB8D712ACD3A608BEF96DC7AF22EEE8C625EB678B615355E424DCEDA4BAB` |
| `codex-peer-review-packet-topic02-round6.md` | `05C8FE205D8714FE421EDB98DC1FFFFB306317E9D529E02BC4FF1F138DA21291` |
| `codex-peer-review-prompt-topic02-round6.md` | `86138C60EADA88DEC773CDEB4E8E019E2D4EBDF5369A19BF486BECFD83FD1FA4` |
| `codex-peer-review-response-topic02-round6.md` | `4052DD966D5A3FC57B1833ABA3C4FFC3C36D5D121E354508B7A20667ED4252C9` |
| `docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md` | `1A9F0DD9449B18FF56F870EA0F0B57739E2F7D494429269C6BAAFF1F22A9204A` |
| `spec/01-target-architecture.md` | `C4B18601B774CF107C3FFF5911A90B24E0C6F73F21858A82F9B4D0E06B6CF490` |
| `spec/02-runtime-semantics.md` | `A9E8CA2535341B5B62AC888890D7CC11590B4AFBE279B6C4F58D658BF8D6B168` |
| `spec/03-agent-topology.md` | `F2AF9FE39C7C942F03CBA5D158F45A60ACE65888707A8171CE17C2CB07389266` |
| `spec/04-workflow-sizing.md` | `DBD99DCD3871142B8C22EE6EEBF51AC833097CB8841C8E9E65DA6F8A5FF273CF` |
| `spec/05-context-and-token-model.md` | `755C148BD99854BF89F6C25B8044DE2E00F57C4496F517A6081C2A02929E8F3C` |
| `spec/06-structured-output.md` | `4929147AD7A282FCCD2A548E1D35F234E78F25795AE8AE25AE3FEA7BE2CFCE39` |
| `spec/07-retrieval-and-code-understanding.md` | `8B056577F445BDA410EC6AEF8F5340E82BB804ED39F127C8AC2EAC14A029BCE3` |
| `spec/08-isolation-and-concurrency.md` | `5B5FFDDBEA310A3C61CF4DAE6B0027E5243E5A05155944E87AF22373948786C4` |
| `spec/09-model-routing.md` | `50B5C7EA917B99C134C08E3B3C172741642652C3A5FBBC1970864B09B6C0EC1D` |
| `spec/10-verification-and-review.md` | `7EAD3E10B52222FCE0E94F57BB89DED4692CE3F3FEA0AC6C63B4288810B92167` |
| `spec/11-skills-rules-and-quality-gates.md` | `380BEC7B7D60CF3268C753B07F3FCFB35EA78564577D4058357C56C2F0F5D9CB` |
| `spec/12-installation-and-rollback.md` | `7C0645D4BC87A578F4E090DD72B64B7BA73F947AB12E14D0C7E53133B29A13DF` |
| `spec/13-validation-and-evaluation.md` | `F2CCF96A11FE4F20CAA40F05B061D4892057895F9533A61DBEE5D8EA448E8404` |
| `spec/14-upgradeability-and-governance.md` | `61FECDF3BC151CD42DC9BA2F20B614063155DA96359ABBD37C482A8817E1C410` |
| `spec/15-security-and-failure-recovery.md` | `0577E40062DF1B9D632A8254B0C8C1239219C202F791AF751CC1108A27C0792A` |
| `spec/16-migration-plan.md` | `C02CD27D1C294744CAB8C2DFEB638F1A91AF723416E5BDB72BAF9A34F2FD027D` |
| `spec/README.md` | `CE066FD639AB5EB69325465200586FE15E1330082E295CAD59C1FB7B5162F1C1` |
| `spec/key/01-dna.md` | `6260DF35AC7EB87EE05A5FCAF0233ABF5A3A037A1A93199EDDC9AE27D26FF28D` |
| `spec/key/02-repo-synthesis.md` | `F7C4E1112F33C9C4A95218A57CB6AC489628857C159FA3BC8BF7FC085FB82675` |
| `spec/key/03-token-quality-model.md` | `482BC92D8CD96C77C0C264E78E5BF99C952E121C2C76A8E68F8C4A8F4B54F431` |
| `spec/key/04-decision-log.md` | `C2BB5616EA1134984EB7966443B183023D0F6C14430E621DEAECDFFF3B0503B6` |
| `spec/key/05-coverage-audit.md` | `289321D6B440E9E3C1FC552929D3882A7E53CF4F54EC47CB6688A50F2CD4E01C` |
| `spec/key/06-investment-thesis.md` | `9750EA7E974FD07784F59341CE1BA42D2A52DE0174B136FCB4CD7B3A374C6610` |
| `spec/key/dossiers/oh-my-pi.md` | `773081ECD8628AF4438FBCDFF75BB584C13BD303FF4DBDD635B7F5838946199B` |
| `spec/key/dossiers/retrieval-cluster.md` | `E23D9A68E75C09888792E3A5491065A43035F0F6AC4143B554BF57E08D1F56C1` |
| `spec/key/repos/context7.md` | `616FC0DBD83E4BD8AF52B500AD4B15EE4D049D3A8E8E96CC88FBAC787B0A410A` |
| `spec/key/repos/serena.md` | `833038B816E9986D0725D54631BA7DF067C75A39C02839F86741596E34A8E385` |
| `spec/phases/phase-01-runtime-correctness.md` | `228CE3BB548A6B2FC506F53F2320DF473F4533DE861B9C3CDDE940B85743707E` |
| `spec/phases/phase-02-core-orchestration.md` | `BF78F2580E965CD7331550D120A5F94F3FED16394174D768910A403A1FA8B758` |
| `spec/phases/phase-03-context-efficiency.md` | `C56FB899B646470AD44D96526B5E60B596272F815415CCC6193A0D75F5C0FCAA` |
| `spec/phases/phase-04-quality-system.md` | `A290EBC6816EF4902D4EC3CE1B06F7EA4972686BAA0D693C0AD648D15951BA6E` |
| `spec/phases/phase-05-installation-hardening.md` | `B3B0BAC403355B2BBC29C81EA46D64DADC36AB9ED621732D12BC1C170D94E850` |
| `spec/phases/phase-06-evaluation.md` | `D53558E2046CC9EB0A279C2363119D5587C548B3833191EE14F0EEBAFF5F24DA` |
| `docs/policies/model-routing.md` | `9D81CD2D22EEDAD57B9DBF236B1E224DD2A977EDB6CE39967687C891973BED50` |
| `docs/research/authority-map.md` | `FC64F9DFBB14A7389C615C29A7AE0680FB2A39B60539C7A21F9D7AAC411B5D51` |
| `docs/research/mechanism-matrix.md` | `4BF0FF36E7445AEC18012FDECFBD5E18035F9F67FABE9F47F6E40410111066E8` |
| `docs/research/final-adoption-plan.md` | `A393426C8AD2C98A47E6DA14DCDF3ED870FA1E5BD255353795444DB2C160D3C9` |
| `docs/final-report.md` | `F60C769D383BC6B602A80326C482BC256A35D5DC9124FF396CB209544018FAA8` |
| `registry/rejected-mechanisms.yml` | `506FBDF0C3C7354E5FC625E78609C50BDFBA9FB314BF3B65BB41542490DBD6CC` |
| `registry/upstreams.yml` | `A73881C80622BB457ACF0643FB1A4029EE8790A44E11605844234037D2456C8D` |
| `docs/evidence/phase-00/E2/conclusion.yml` | `570CC4D763012B2E74CF6647BB9652053242A9CED8677E4A469DDF3445729644` |
| `docs/evidence/phase-00/manifest.yml` | `A3B6004CF0B2ED3E216AC31EF86A927656D46901FCA96DF115283956FED61A1A` |
| `docs/evidence/phase-00/T-00.3/conclusion.yml` | `B0792E6109C9FB767F4B821EF6F56B2BE655B52C9C244865033C2F25E842834F` |
| `scripts/lib/topic02-workflow-lifecycle.ps1` | `3814C35D07800FC86A60D0C92A5CA22541F7C62572971D3318923B1B94DB51E9` |
| `scripts/tests/topic02-workflow-lifecycle.Tests.ps1` | `23DAC47D70727A3A1EFE398D57D91F332AB39DAF1F070953742A473D0A379538` |
| `scripts/validate-topic02-workflow-lifecycle.ps1` | `EC4F5BC38194C3DB4E486D77BDEBC1AAA73E335A49746CCDC44B31AA447582A4` |
| `scripts/lib/phase00-evidence.ps1` | `EF6DB7A01FE044A5C3BCAEF84951250B4ECD4F3DAF642B8C67F584ABF1BF1CCD` |
| `scripts/tests/phase00-t003.Tests.ps1` | `A67B70390BD979EBBA69035F22BDFEAF9B519CC29AEC630233A36223DB85BB45` |
| `CHANGELOG.md` | `C83FF7B6886E682B23B23ACC1A5F37D57DF07F77A90E26401AB55C6A110350C0` |
| `codex-topic02-workflow-entry-task-lifecycle-changelog.md` | `B966276CE8C92CC78108921119415163B35D9CAE7EDBAA52C1C7B34FCD18C97B` |

Execute byte-level hashing. `INSUFFICIENT_EVIDENCE` is valid only after an actual mismatch,
missing artifact/source, inaccessible required source, or internal evidence contradiction.

## 6. Mandatory reproducibility checks

| Check | Expected result |
|---|---|
| Focused Topic-02 mutation self-test | `PASS Topic 02 validator self-test (107 assertions)` |
| Focused Topic-02 validator | `449 passed, 0 warnings, 0 failed` |
| All Phase-00 Pester suites | `329 passed, 0 failed` |
| T-00.3 focused suite | `28 passed, 0 failed` |
| Full repository validator | `102 passed, 1 warnings, 0 failed`; only pre-existing RULES budget warning |
| `git diff --check` | Exit `0`; only pre-existing Phase-00 CRLF advisory |
| Repository identity | `main`, HEAD `62fecf277dc9d5e47d06319387eac747462214c1`, zero staged paths |
| Phase DAG | nine expected reciprocal edges, zero reciprocal failures |

Re-run all checks. The dirty worktree is user-owned and grows when frozen review artifacts are
added; report its observed count but do not treat a changing untracked-artifact count as staged
mutation. Compare every load-bearing hash instead. Literal validator success alone is not
sufficient.

## 7. Historical Phase-00 runtime pins

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

### Entry and session identity

1. `packages/coding-agent/src/extensibility/slash-commands.ts:110-129` leaves non-slash text
   unchanged.
2. `packages/coding-agent/src/session/agent-session.ts:4942-4966` gates command handling on
   slash-prefixed input.
3. `packages/coding-agent/src/session/session-handoff.ts:97-103,217-275` creates a new session,
   resets session-scoped state, and injects generated handoff text; the text is context, not
   durable lifecycle authority.

### Selected capability and result identity

4. `task/structured-subagent.ts:318-320`, `tools/index.ts:593`, and
   `task/executor.ts:2675-2678` establish the four LSP registration gates.
5. `lsp/index.ts:2145-2160,2423-2428` returns ordinary failure content with
   `details.success: false` when no applicable/configured language server exists.
6. `task/executor.ts:623-669` permits a malformed schema to surface
   `structuredOutput.status: unavailable`; runtime exit alone is not acceptance.
7. `config/settings-schema.ts:4582-4592,4706-4718` and `task/executor.ts:2886-2908`
   establish `task.enableEffort`, the `task.maxEffort` ceiling, and returned effective effort.
8. `config/settings-schema.ts:4676-4692` and `task/executor.ts:87-123,1568-1596,1821-1826`
   establish the soft-request force-stop and partial yield.
9. `task/structured-subagent.ts:281-294` gives `task.agentModelOverrides` precedence over agent
   frontmatter. `config/model-resolver.ts:1399-1421` and `task/executor.ts:2840-2867` permit
   credential fallback to the parent model; `resolvedModelIsFallback` is set for retry fallback,
   not that credential branch (`task/executor.ts:1707-1715`).
10. `task/structured-subagent.ts:159,190-198` rewrites plan-mode tools; `task/index.ts:568-576`
    removes isolation controls from the plan-mode wire.
11. `tools/index.ts:599-605` filters `glob`, `grep`, `ast_grep`, and `web_search` by effective
    settings; `astGrep.enabled` defaults false in `settings-schema.ts:3828-3836`.
12. `task/executor.ts:2655-2687` strips `task` at `childDepth >= maxRecursionDepth`; default 2
    means the main child at depth 1 retains `task`, while its child at depth 2 loses it.

## 9. Twelve mandatory questions

1. Are verification/review obligations locked before task start and covered by material change?
2. Is DNA genuinely topology-neutral across active genes and review contract/risk-gated?
3. Do spec 13 and Phase 06 consume the selected manifest without count/name/schema/skill
   assumptions while keeping every selected capability path fail-closed?
4. Are all prior selected-path findings closed, including the four LSP registration gates,
   applicable-server routing, and required-call `details.success`?
5. Are no-prefix, `/quick`, compatibility, missing-slash, and internal reclassification semantics
   coherent with pinned OMP handling?
6. Are task, work-unit, candidate, and session boundaries plus evidence invalidation implementable?
7. Do compaction, handoff, fork, and resume preserve their intended ownership distinctions?
8. Are task terminals, forced partial yields, and Topic-01 evaluation categories separated
   without a false-completion path?
9. Is Orchestrated structural and sequentially implementable without mandatory dispatch,
   agents, batch, parallelism, isolation, or review?
10. Are schemas, skills, aliases, model/effort identity, retrieval settings, recursion, plan mode,
    barriers, LSP, bash, batch, and isolation conditional yet fail-closed when selected?
11. Is Cheap Scout simple, optional, configurable, read-only, fail-soft, and free of token or
    lifecycle gating?
12. Are phase ownership, history/supersession, runtime non-claims, hashes, source evidence, Git
    identity, and dependencies honest and reproducible?

## 10. Verdict policy

Return exactly one:

```text
ACCEPT_TOPIC_02
REOPEN_TOPIC_02
INSUFFICIENT_EVIDENCE
```

`ACCEPT_TOPIC_02` requires every prior Important finding and every disclosed semantic-equivalent
cluster closed, with no other Critical or Important scoped defect. Minor findings may coexist
only when they cannot change entry authority, lifecycle identity, evidence validity, topology
ownership, selected-path safety, fallback behavior, phase ownership, historical evidence,
runtime feasibility, or reproducibility.

Preferences for fixed roles, universal review, mandatory parallelism, or elaborate Cheap Scout
optimization are not defects unless the approved contract becomes contradictory, unsafe,
unimplementable, weakened, or irreproducible.
