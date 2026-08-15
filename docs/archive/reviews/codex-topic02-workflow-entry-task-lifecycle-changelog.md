# Codex — Topic 02 Workflow Entry and Task Lifecycle Change Ledger

> **Project:** `omp-template`
>
> **Scope:** Topic 02 architecture/specification and phase-plan projection
>
> **Authority:** explicit user approvals on 2026-08-12
>
> **Repository baseline:** `main` at
> `62fecf277dc9d5e47d06319387eac747462214c1`
>
> **Pinned OMP source:** clean
> `3a8591a8af5b6d200088d12ca75a5517cb064fa8` (17.2.10)
>
> **Runtime implemented:** no — Phase 02 migration is deferred

## 1. User-approved decision

- A plain natural-language request is the normal entry. No prefix is required.
- `/quick` is the user's explicit light-task choice. The Tech Lead validates it and may
  escalate when unsuitable.
- Standard and Orchestrated are selected by the main-session Tech Lead. Their slash forms
  remain compatibility/advanced hints; the same words without `/` are natural-language hints.
- Workflow changes are internal reclassification, not model-authored slash-command restarts.
- Reclassification preserves valid discovery and workspace changes; it does not automatically
  reset, discard, or revert them.
- Standard is one integrated implementation lane.
- Orchestrated requires at least two independently verifiable work units, explicit unit
  contracts, one task-level integration contract, and cross-boundary verification.
  Parallelism, multiple agents, and multiple writers are optional.
- A phase is a program of tasks. A task starts when its objective, scope/authority, mandatory
  criteria, and verification obligations are accepted as one contract.
- A candidate is a frozen implementation snapshot. Any acceptance-bearing mutation invalidates
  evidence for that snapshot and requires C2 or later.
- A session serves one task and one non-competing candidate lineage. Compaction preserves
  identity; handoff creates a reconciled successor; material contract change opens a linked
  task/session.
- Task terminals are accepted, cancelled, and terminally blocked. Partial, recoverable blocked,
  waiting-for-user, and rework states are nonterminal.
- `accepted_with_waiver` remains a non-promoting evaluation classification. A waiver of a
  mandatory criterion changes the contract and cannot relabel the old candidate.
- Cheap Scout is optional, configurable, read-only, and fail-soft. Its failure falls back to
  the retrieval path the Tech Lead needs without lifecycle side effects.

Canonical authority is `spec/04-workflow-sizing.md`; KD-026 records the decision.

## 2. Scope correction discovered during implementation

The first execution draft scheduled immediate edits to installable `AGENTS.md`, commands,
`tech-lead.md`, task triage, and product documentation. This was incorrect for two independent
reasons:

1. the session attachment authorizes this architecture topic to patch specs/phases after
   approval, while runtime work belongs to a later implementation phase; and
2. five intended runtime targets are hash-bound destinations of the immutable Phase 00 T-00.3
   evidence snapshot. Direct mutation made the historical validator fail even though the new
   semantics were internally coherent.

All attempted Topic 02 runtime edits were withdrawn. The five hash-bound targets and
`task-triage` were reconstructed from the recorded Phase 00 patch chain/HEAD and verified
byte-for-byte. No Phase 00 evidence or validator was refreshed, weakened, or edited.

Phase 02 now owns the runtime migration and must create a new current-product evidence identity
that explicitly supersedes the Phase 00 product snapshot without rewriting that history.

## 3. Old semantics → approved semantics

| Concern | Superseded active semantics | Approved architecture |
|---|---|---|
| Entry | User selects one of three sizes | Plain request is normal; user explicitly selects only Quick |
| Missing slash | Ambiguous/error-prone | Natural-language hint; no resend required |
| Standard/Orchestrated authority | User command decides | Tech Lead validates task structure and decides |
| Workflow transition | Restart another slash command | Internal reclassification |
| Escalation | Discard/restart partial work; no reduction | Preserve valid evidence/work; preflight reduction allowed |
| Standard | Fixed sequential worker chain | One integrated lane; specialists optional |
| Orchestrated | Size/risk/agent-count/parallel-work proxy | Independently verifiable units + integration contract + cross-boundary checks |
| Task | Loose unit mixed with session/result | One accepted contract and one accounting cycle |
| Candidate | Any work state/result | Frozen acceptance-bearing snapshot; evidence invalid after mutation |
| Session | Conversation or phase proxy | One task and one non-competing candidate lineage |
| Compaction | Could act as continuation/state | Same session identity; context operation only |
| Handoff | Summary/state interchangeably | Reconciled successor session; handoff text is context, not authority |
| Outcomes | Partial/blocked/decision-needed treated as terminal | Three task terminals; progress states are nonterminal |
| Waiver | Could resemble accepted terminal | Evaluation-only, excluded; mandatory-criterion waiver changes contract |
| Cheap Scout | Could invite routing/token analysis | Simple optional read-only fail-soft retrieval |

## 4. Authority and phase impact

| Layer | File(s) | Result |
|---|---|---|
| Approved design | `docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md` | Decision and scope record |
| Canonical authority | `spec/04-workflow-sizing.md` | Entry, classification, lifecycle, reclassification, fallback |
| Decision log | `spec/key/04-decision-log.md` | KD-026 |
| Architecture reconciliation | `spec/key/01-dna.md`, `spec/key/03-token-quality-model.md`, `spec/01-target-architecture.md`, `spec/03-agent-topology.md`, `spec/05-context-and-token-model.md`, `spec/08-isolation-and-concurrency.md`, `spec/10-verification-and-review.md`, `spec/13-validation-and-evaluation.md`, `spec/README.md` | Removed active contradictions and fenced Topic 03/04/08 ownership |
| Phase 02 | `spec/phases/phase-02-core-orchestration.md` | New runtime migration, evidence supersession, entry/lifecycle exit gates |
| Phase 03 | `spec/phases/phase-03-context-efficiency.md` | Compaction/handoff identity and Topic 04 boundary |
| Phase 06 | `spec/phases/phase-06-evaluation.md` | Topic 02 scenario matrix and corrected terminal vocabulary |
| Validation | `scripts/lib/topic02-workflow-lifecycle.ps1`, `scripts/tests/topic02-workflow-lifecycle.Tests.ps1`, `scripts/validate-topic02-workflow-lifecycle.ps1` | Focused spec/phase contract with mutation controls |
| Product changelog | `CHANGELOG.md` | Concise non-runtime Topic 02 entry |

The Phase dependency DAG, registry, installer, license/provenance, benchmark harness, upstream
source, DNA worktree, and Phase 00 evidence are unchanged by Topic 02.

## 5. File ledger

“Before” is the exact state captured immediately before Topic 02 edits, not necessarily HEAD,
because Topic 01 and Phase 00 changes were already present in the dirty workspace. SHA-256:

| File | Before | Current |
|---|---|---|
| `spec/01-target-architecture.md` | `39FE36472B35458CF5B3AA1B502DD44ADF349AAA2C350570508F6C6B320EB9F6` | `E022AC1C7BDA7DC27FFEBA41ECFB807B716925C7033B9CBA60B59916D884859A` |
| `spec/03-agent-topology.md` | `0453B00C84F84C130B4CDFBA71803FEF547A77808360774C55B4B7FDD83A5892` | `F2AF9FE39C7C942F03CBA5D158F45A60ACE65888707A8171CE17C2CB07389266` |
| `spec/04-workflow-sizing.md` | `8E9329E1A953028A8ACFFBFF8E2D6FC97F42CF5C6B595BD57A97A9E1FB78593F` | `3B5EE8686C5B6FF96E0D573D2C357F7F1922B70D40CE4CBE61C01AABEAF47481` |
| `spec/05-context-and-token-model.md` | `D487EB1267749DF3E54BD6A18CCFC87F864569A76780810D2C4E334486755478` | `76DDFBE46AE412CB298E296702C90C109E4B032A43AC3AA409AE592CC163FFB8` |
| `spec/08-isolation-and-concurrency.md` | `08EACD97A86B91B3DA1D2D77B7630EC61979370FCF53DCB9B3493F58168DD978` | `B1B38CFE6EDE9218D595A40B6C45EC92172DB189F83D29791F2858A584E5EF19` |
| `spec/10-verification-and-review.md` | `1FF5728D017A106FA420DAF030AF8CA8A774F948524E079E3D3A9321C39C0477` | `331C7F17E57D634FCF77CFB3B789D7FA71CA6DF6FC596CFDD08AA41EB032818C` |
| `spec/13-validation-and-evaluation.md` | `78F1157C614CC27CCC2CF7053FADD8DC6CB142D0DEC56AA57BFD89A2B347D062` | `E51C32802664040F84144A5A95887E22468234BEDFD16F0A27A4D8F08DF38F57` |
| `spec/README.md` | `5E003BC77BC178A78FA9FB4C106443AD2014EE66D7E50059DA1B46E85F357663` | `98D08A9E0484C99204708E0B39B354AA6975D0853A9A45DDB83491CC5C1CC2A1` |
| `spec/key/01-dna.md` | `C41E82F8CEB5B6A7643C4702F227FE289A51CBBC98824259CF6F3F0F412B1AA1` | `745DFEFBFDDDB638F503CA108DA80A3CFDF27F92620213FD315D0F152D19D73E` |
| `spec/key/03-token-quality-model.md` | `DF235DA4712B8B2144F87A1CD8BC004EEC4648629D39E15BFC3EFDDFBC7830EF` | `3015BE8C1B5D540274547508C5CF2110445071267D4F21D643159962F6079989` |
| `spec/key/04-decision-log.md` | `7F01A324E1FC35D811815DF40665E39B37A9C8F1F81CF3468274731E17447D8E` | `4F4C6A103BB2815C5CA2335A460C42754946BF2623869E9B09A7C83B284AE29D` |
| `spec/phases/phase-02-core-orchestration.md` | `770C7ADCE306B8C205695974686151DBA3172FC0AA3ED66251233FD2F6DFF39F` | `CA0E002E66D33B9F7F3AAE681D272D8C053BC6AAEA3282DE336D58E6FE670E05` |
| `spec/phases/phase-03-context-efficiency.md` | `F8FD4988D9C13B690BEF38BE12E856D7AB2F485D3597153FF828338628D2BBB4` | `D31591F84DBD6484F0736983541A336D8ED6BB1EC5B141C9164CE679B0366095` |
| `spec/phases/phase-06-evaluation.md` | `1301FB89CDF6225C6A644021093728DE2E0B37C782AB47B373E10290FCD8E153` | `D276240CE344816B4243EF5C186CE67A641D83D6E5F2E87B14EFF30DC29CFEAA` |
| `docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md` | absent | `DADD361135629B210AFF0F581E3B27FDFD2AB869D04E18476B59691106CF0AFE` |
| `docs/superpowers/plans/2026-08-12-topic-02-workflow-entry-task-lifecycle-plan.md` | absent | `9A9D8C4AEEC6236B1516E61F03AD0EE244F3EE2BCC8FD0A3A85FC272618400E0` |
| `scripts/lib/topic02-workflow-lifecycle.ps1` | absent | `C44300F726522874B2EFE88AD2E266470C75F063B6740192C5ACA989A8882DB9` |
| `scripts/tests/topic02-workflow-lifecycle.Tests.ps1` | absent | `743B699780B45BB835011D0D14B9C6605B59E3BAAA665962880D8A6317448AC7` |
| `scripts/validate-topic02-workflow-lifecycle.ps1` | absent | `EC4F5BC38194C3DB4E486D77BDEBC1AAA73E335A49746CCDC44B31AA447582A4` |
| `CHANGELOG.md` | `C920B7E0B05B8EAD334AAE23AD64C623390A7E3831F94B3B1FE7226C26338B7C` | `C83FF7B6886E682B23B23ACC1A5F37D57DF07F77A90E26401AB55C6A110350C0` |

The plan is a mutable execution tracker. Its hash above is the pre-audit checkpoint, not a
semantic authority pin.

## 6. Preserved runtime/evidence pins

| Runtime target | SHA-256 after withdrawal | Phase 00 expected |
|---|---|---|
| `template/.omp/AGENTS.md` | `3F194D81208872B6CDE4A51265156D06A8016810CAA9D24BF37B545E60848BBC` | match |
| `template/.omp/agents/tech-lead.md` | `47B3060A725F9C41EA832E2CE8E7CBAEFCAFACB4137A9B4153C2819732016AD2` | match |
| `template/.omp/commands/quick.md` | `F4E9081846368DA140923C8D51C7BAB079DA4B75577019A412735DBAC4A21731` | match |
| `template/.omp/commands/standard.md` | `F849485369F0E8EE6D7D816752D7CAD263DA5381EF8216C319B19091FCBB626B` | match |
| `template/.omp/commands/orchestrated.md` | `D88179FA0C27B9EEDF9EE59B5CD6A59B75FC426BCDAD18061209942C36012D12` | match |

`template/.omp/skills/task-triage/SKILL.md` also matches its pre-Topic-02 HEAD bytes
`D398AFAE80D199F6951C988A4D13C90FD4EFDE4E2B1290CF8A9AB642977430BC`.
`scripts/validate-template.ps1` remains
`D78594BA7DD28C843BDCCEC6F532FBBB491C9E380FD91B686B2AA70850D61701`.

## 7. Validation evidence

### Validator self-test

```powershell
pwsh -NoProfile -File scripts/tests/topic02-workflow-lifecycle.Tests.ps1
```

Result: exit `0`; `PASS Topic 02 validator self-test (8 assertions)`.
Controls include missing files, stale user-sizing prose, stale classification-mandatory review,
missing Phase 00 history boundary, and wrapped-line semantics.

### Focused Topic 02 contract

```powershell
pwsh -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
```

Result: exit `0`; `60 passed, 0 warnings, 0 failed`.

The added review-projection guard first reproduced one stale checklist statement in
`spec/10-verification-and-review.md` (`always in Orchestrated`) while its authoritative table
already used the approved contract/risk gate. The focused validator failed `1` check; the
checklist was reconciled to the same gate, and the self-test plus focused validator then passed
with the totals above.

### Full repository validator

```powershell
pwsh -NoProfile -File scripts/validate-template.ps1
```

Result: exit `0`; `102 passed, 1 warning, 0 failed`. The sole warning is the pre-existing
approximate `RULES.md` budget (`226 < 300`).

### Contradiction scan

Active specs were scanned for user-picks-all sizing, restart/discard escalation,
de-escalation prohibition, size/risk/fixed-count Orchestrated selection, fixed
Explorer→Implementer→Verifier topology, stale terminal vocabulary, and mandatory review by
classification. Remaining hits are explicit supersession/history, conditional parallel-path
safety, or per-repository research evidence; active authority contains no conflicting rule.

### Workspace/source integrity

- branch `main`; HEAD `62fecf277dc9d5e47d06319387eac747462214c1`;
- staged paths: `0`;
- DNA worktree still has its pre-existing corrections and was not written;
- pinned OMP source remains clean at
  `3a8591a8af5b6d200088d12ca75a5517cb064fa8`;
- no commit, branch, push, PR, provider benchmark, registry change, or Phase 00 evidence
  mutation occurred.

## 8. Known limitations and deferred work

- Current installable prompts still express the Phase 00 workflow snapshot. This is intentional
  and visible; Phase 02 must migrate them after Topic 03/04/08 decisions.
- Topic 03 may adopt, revise, or reject the prior four-worker topology; Topic 02 does not decide
  model/provider mapping or mandatory specialist dispatch.
- Topic 04 must design durable identity/storage, ownership, recovery, and handoff state.
- Topic 08 must design runtime-specific triage adapters.
- Phase 06 must implement behavioral evaluation; Topic 02 only specifies its matrix.
- Cheap Scout provider/model configuration remains future Topic 03/05 work; only its simple
  optional/read-only/fail-soft boundary is fixed here.

## 9. Audit focus

The read-only Codex reviewer must try to falsify:

1. whether no-prefix and missing-slash entry are coherent with pinned slash expansion;
2. whether Quick authority and Tech Lead Standard/Orchestrated authority drift anywhere;
3. whether Orchestrated is truly topology/parallelism-neutral while retaining an integration
   distinction from Standard;
4. whether task/candidate/session/compaction/handoff/fork/resume boundaries are mutually
   coherent;
5. whether the new terminal vocabulary contradicts Topic 01 accounting;
6. whether `accepted_with_waiver` can accidentally validate an old candidate;
7. whether Phase 02/03/06 contain executable migration/eval gates without preempting later
   topics;
8. whether preserving Phase 00 runtime hashes while deferring migration is honest and
   reproducible;
9. whether the focused validator can be gamed or misses an active contradictory authority;
10. whether any runtime implementation, topology choice, durable state, benchmark result, or
    Opus verdict is overclaimed.

## 10. Handoff status after Codex review rounds

Status on 2026-08-12: **IMPLEMENTED_REVIEW_DEFERRED_NON_BLOCKING**.

- User decision: approved and locked.
- Architecture/specification/phase-plan projection: implemented.
- Focused Topic 02 validator and mutation coverage: implemented.
- Latest lean verification after the Round 7 corrections:
  - Phase 00 T-00.3: `30 passed, 0 failed`;
  - focused Topic 02 contract: `600 passed, 0 warnings, 0 failed`;
  - full repository validator: `102 passed, 1 known RULES.md budget warning, 0 failed`.
- Round 7 correction set: applied. It reconciles residual fixed-topology authority, exact
  selected-model identity checks, settings-phase ownership, and the L0-static/L1-runtime
  discovery boundary.
- Runtime projection: intentionally deferred to Phase 02, after Topic 03 selects the agent and
  model/provider topology. Existing runtime diffs are not claimed as Topic 02 implementation.
- Independent review: deferred and non-blocking. Opus is preferred when available, but it is
  not a mandatory gate. Codex or another suitable strong model is a valid fallback; same-model
  review uses a separate session and discloses that limitation. No additional review loop is
  required before moving on.
- Closure label: `IMPLEMENTED_REVIEW_DEFERRED_NON_BLOCKING`. Record an optional future Opus
  review only for unresolved difficult findings or when the task contract explicitly requires
  Opus; do not stop the topic sequence merely because Opus is unavailable.
- Next active topic: **Topic 03 — Agent topology and model/provider routing**, beginning at
  `DISCOVER`.
