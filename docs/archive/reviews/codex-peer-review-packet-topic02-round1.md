# Codex peer-review packet — Topic 02 closure — Round 1

```yaml
topic: 02-workflow-entry-task-lifecycle
review_round: 1
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

## 1. Authority and audit boundary

The user approved the Topic 02 design and explicitly authorized Codex as the temporary audit
reviewer because Claude Opus has no usable account/quota. Reviewer substitution does not
weaken the gate: acceptance requires no Critical or Important scoped defect.

This is an uncommitted, dirty shared workspace containing pre-existing Phase 00, Topic 01, and
other user work. Do not infer Topic 02 scope from the whole Git diff. The SHA-256 table in §5
defines the frozen Topic 02 snapshot; the ledger below records before/current identity and
scope attribution:

`codex-topic02-workflow-entry-task-lifecycle-changelog.md`

Expected SHA-256:

`B966276CE8C92CC78108921119415163B35D9CAE7EDBAA52C1C7B34FCD18C97B`

Topic 02 closes architecture/specification and phase-plan projection only. It does not claim
that the installable template, user-facing runtime documentation, durable lifecycle state,
final agent topology, or evaluation harness already implements the new contract.

## 2. Approved contract that must remain intact

1. A plain natural-language request is the normal entry. No prefix is required.
2. `/quick` is the user's explicit light-path choice. The Tech Lead validates the boundary and
   may internally reclassify it. `/standard` and `/orchestrated` are compatibility/advanced
   hints, not final workflow authority; the same words without `/` are natural-language hints.
3. The main-session Tech Lead selects Standard or Orchestrated. Workflow change is internal
   reclassification, not model-authored slash-command re-entry.
4. Reclassification preserves valid discovery and workspace changes. It does not
   automatically reset, revert, or discard work, and it cannot silently expand the accepted
   contract or authority boundary.
5. A task starts only after objective, scope/authority, mandatory criteria, and verification
   obligations are accepted as one contract. Clarification before that boundary is not a task
   cycle. Retry, retrieval, rework, and rejected candidates remain in the same cycle while the
   contract is unchanged.
6. A candidate is a coherent frozen snapshot. Any acceptance-bearing mutation after freeze
   invalidates evidence for that candidate; C2 or later must be frozen and verified. Only the
   integrated task candidate can be accepted.
7. A session serves one task and one non-competing candidate lineage. Compaction preserves
   identity. Handoff creates a reconciled successor session. A material contract change opens
   a linked task/session. Fork is deliberate for a competing alternative or explicitly owned
   work unit. Resume requires contract/candidate/workspace reconciliation.
8. Task terminals are `accepted`, `cancelled`, and `terminally_blocked`. `partial`, recoverable
   `blocked`, `waiting_for_user`, and rework are nonterminal. Topic 01
   `accepted_with_waiver` is an evaluation classification excluded from validated acceptance;
   waiving a mandatory criterion changes the contract and cannot relabel the old candidate.
9. Standard is one integrated implementation lane. Orchestrated requires at least two
   independently verifiable work units, explicit unit contracts, one task-level integration
   contract, and cross-boundary verification. Multiple agents, parallel writers, and parallel
   execution are optional. Reviewer dispatch remains contract/risk-gated rather than forced
   by Orchestrated classification alone.
10. Cheap Scout is optional, configurable, read-only, and fail-soft. DeepSeek, Gemini, or
    another inexpensive suitable model may be used. Failure falls back to the retrieval path
    the Tech Lead needs without changing task, candidate, session, or workflow state.
11. Topic 03 owns final topology/model routing, Topic 04 durable state/identifiers, Topic 08
    deeper task-triage behavior, and Phase 06 the future evaluation harness. Phase 02 owns the
    installable runtime migration and must create a new current-product evidence identity.
12. Phase 00 T-00.3 evidence remains immutable history. Topic 02 must not refresh or rewrite it
    to make future semantics appear retroactively implemented.

## 3. Scope correction and non-claims

An initial execution draft proposed immediate edits to the installable commands, Tech Lead,
`AGENTS.md`, triage skill, and product documentation. That projection was withdrawn because
the architecture session authorizes specs/phases and those runtime targets are hash-bound by
the Phase 00 historical evidence snapshot. The final design and phase plan explicitly defer
runtime migration to Phase 02.

Therefore:

- expected old runtime semantics in the preserved Phase 00 template are a documented migration
  gap, not evidence that Topic 02 falsely edited runtime;
- the active Topic 02 specification and phase-plan authority must be internally coherent;
- the runtime gap becomes a defect only if a Topic 02 artifact claims it is already enforced,
  omits the Phase 02 migration, weakens the historical boundary, or makes the migration
  unimplementable;
- no runtime lifecycle engine, candidate identity store, evaluation harness, candidate
  promotion, Phase 00 refresh, DAG edit, commit, stage, push, or PR is claimed.

## 4. Mandatory read order

1. This packet.
2. `codex-topic02-workflow-entry-task-lifecycle-changelog.md`.
3. `docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md`.
4. `spec/key/04-decision-log.md` — KD-026.
5. `spec/04-workflow-sizing.md` — canonical authority.
6. `spec/key/01-dna.md`, then `spec/01-target-architecture.md` and
   `spec/03-agent-topology.md`.
7. `spec/05-context-and-token-model.md`, `spec/08-isolation-and-concurrency.md`, and
   `spec/10-verification-and-review.md`.
8. `spec/key/03-token-quality-model.md` and `spec/13-validation-and-evaluation.md`.
9. `spec/README.md` and Phase 02, Phase 03, and Phase 06 plans in §5.
10. The focused validator helper, self-test, and wrapper in §5.
11. The pinned OMP source anchors in §7.
12. The preserved runtime files in §6 only to verify byte identity and the honest deferral
    boundary; do not require the deferred migration in this Topic 02 closure.

The execution plan is a mutable process artifact and is deliberately excluded from the
load-bearing semantic table. It may be consulted only to understand the recorded scope
correction:
`docs/superpowers/plans/2026-08-12-topic-02-workflow-entry-task-lifecycle-plan.md`.

## 5. Frozen load-bearing SHA-256 table

| File | Expected SHA-256 |
|---|---|
| `docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md` | `DADD361135629B210AFF0F581E3B27FDFD2AB869D04E18476B59691106CF0AFE` |
| `spec/01-target-architecture.md` | `E022AC1C7BDA7DC27FFEBA41ECFB807B716925C7033B9CBA60B59916D884859A` |
| `spec/03-agent-topology.md` | `F2AF9FE39C7C942F03CBA5D158F45A60ACE65888707A8171CE17C2CB07389266` |
| `spec/04-workflow-sizing.md` | `3B5EE8686C5B6FF96E0D573D2C357F7F1922B70D40CE4CBE61C01AABEAF47481` |
| `spec/05-context-and-token-model.md` | `76DDFBE46AE412CB298E296702C90C109E4B032A43AC3AA409AE592CC163FFB8` |
| `spec/08-isolation-and-concurrency.md` | `B1B38CFE6EDE9218D595A40B6C45EC92172DB189F83D29791F2858A584E5EF19` |
| `spec/10-verification-and-review.md` | `331C7F17E57D634FCF77CFB3B789D7FA71CA6DF6FC596CFDD08AA41EB032818C` |
| `spec/13-validation-and-evaluation.md` | `E51C32802664040F84144A5A95887E22468234BEDFD16F0A27A4D8F08DF38F57` |
| `spec/README.md` | `98D08A9E0484C99204708E0B39B354AA6975D0853A9A45DDB83491CC5C1CC2A1` |
| `spec/key/01-dna.md` | `745DFEFBFDDDB638F503CA108DA80A3CFDF27F92620213FD315D0F152D19D73E` |
| `spec/key/03-token-quality-model.md` | `3015BE8C1B5D540274547508C5CF2110445071267D4F21D643159962F6079989` |
| `spec/key/04-decision-log.md` | `4F4C6A103BB2815C5CA2335A460C42754946BF2623869E9B09A7C83B284AE29D` |
| `spec/phases/phase-02-core-orchestration.md` | `CA0E002E66D33B9F7F3AAE681D272D8C053BC6AAEA3282DE336D58E6FE670E05` |
| `spec/phases/phase-03-context-efficiency.md` | `D31591F84DBD6484F0736983541A336D8ED6BB1EC5B141C9164CE679B0366095` |
| `spec/phases/phase-06-evaluation.md` | `D276240CE344816B4243EF5C186CE67A641D83D6E5F2E87B14EFF30DC29CFEAA` |
| `scripts/lib/topic02-workflow-lifecycle.ps1` | `C44300F726522874B2EFE88AD2E266470C75F063B6740192C5ACA989A8882DB9` |
| `scripts/tests/topic02-workflow-lifecycle.Tests.ps1` | `743B699780B45BB835011D0D14B9C6605B59E3BAAA665962880D8A6317448AC7` |
| `scripts/validate-topic02-workflow-lifecycle.ps1` | `EC4F5BC38194C3DB4E486D77BDEBC1AAA73E335A49746CCDC44B31AA447582A4` |
| `CHANGELOG.md` | `C83FF7B6886E682B23B23ACC1A5F37D57DF07F77A90E26401AB55C6A110350C0` |
| `codex-topic02-workflow-entry-task-lifecycle-changelog.md` | `B966276CE8C92CC78108921119415163B35D9CAE7EDBAA52C1C7B34FCD18C97B` |

Execute byte-level hashing. Stop with `INSUFFICIENT_EVIDENCE` only if a required command
actually executes and produces a mismatch, a required file/source is absent, or the evidence
is contradictory. Report exact command and output.

## 6. Historical Phase 00 runtime pins

These are preservation checks, not Topic 02 runtime implementation claims.

| File | Expected SHA-256 |
|---|---|
| `template/.omp/AGENTS.md` | `3F194D81208872B6CDE4A51265156D06A8016810CAA9D24BF37B545E60848BBC` |
| `template/.omp/agents/tech-lead.md` | `47B3060A725F9C41EA832E2CE8E7CBAEFCAFACB4137A9B4153C2819732016AD2` |
| `template/.omp/commands/quick.md` | `F4E9081846368DA140923C8D51C7BAB079DA4B75577019A412735DBAC4A21731` |
| `template/.omp/commands/standard.md` | `F849485369F0E8EE6D7D816752D7CAD263DA5381EF8216C319B19091FCBB626B` |
| `template/.omp/commands/orchestrated.md` | `D88179FA0C27B9EEDF9EE59B5CD6A59B75FC426BCDAD18061209942C36012D12` |
| `template/.omp/skills/task-triage/SKILL.md` | `D398AFAE80D199F6951C988A4D13C90FD4EFDE4E2B1290CF8A9AB642977430BC` |
| `scripts/validate-template.ps1` | `D78594BA7DD28C843BDCCEC6F532FBBB491C9E380FD91B686B2AA70850D61701` |

The focused self-test last returned `PASS Topic 02 validator self-test (8 assertions)`; the
focused contract returned `60 passed, 0 warnings, 0 failed`; and the full repository validator
returned `102 passed, 1 warning, 0 failed`. The sole full-validator warning is the pre-existing
approximate `template/.omp/RULES.md` budget (`226 < 300`). Re-run rather than trusting these
statements.

## 7. Pinned OMP source claims

Pinned repository: `_research/upstreams/oh-my-pi`

Expected clean commit: `3a8591a8af5b6d200088d12ca75a5517cb064fa8` (OMP 17.2.10).

Verify independently:

1. `packages/coding-agent/src/extensibility/slash-commands.ts:110-129` returns the original
   text when it does not begin with `/`; file-command expansion applies only to slash input.
2. `packages/coding-agent/src/session/agent-session.ts:4942-4966` gates extension, custom, and
   file-based command handling on `text.startsWith("/")`. A plain `standard ...` or
   `orchestrated ...` string is therefore ordinary model input, not a command invocation.
3. `packages/coding-agent/src/session/session-handoff.ts:97-103,217-275` generates handoff text,
   starts a new child session, resets session-scoped runtime state, and injects the generated
   document into that new transcript. This supports successor-session semantics but does not
   make generated prose authoritative lifecycle state.

Do not infer more than these source anchors prove. Durable reconciliation remains Topic 04
work.

## 8. Ten mandatory questions

1. Is no-prefix entry coherent with actual OMP slash expansion, and are missing-slash words
   handled as natural-language hints without requiring the user to resend?
2. Is authority unambiguous: user explicitly selects Quick; Tech Lead validates Quick and
   selects Standard/Orchestrated; compatibility commands remain hints?
3. Can internal reclassification preserve valid evidence/work without resetting it, while
   still preventing silent contract or authority expansion?
4. Are clarification, accepted task contract, work unit, task cycle, and phase boundaries
   distinct and implementable?
5. Is candidate freeze a real evidence boundary: mutation invalidates old evidence, C2 cannot
   inherit C1 acceptance, and unit completion cannot accept the integrated task?
6. Are continue/new/compaction/handoff/fork/resume semantics mutually coherent and grounded in
   OMP behavior without treating conversation prose or `.task/` scratch as authority?
7. Are lifecycle terminal state and Topic 01 evaluation classification separated without any
   denominator, waiver, partial, blocked, or waiting-state loophole?
8. Is Orchestrated structural rather than a proxy for size/risk/file/agent count, mandatory
   parallelism, fixed topology, or unconditional reviewer dispatch?
9. Is Cheap Scout still the simple optional read-only fail-soft helper the user approved, with
   no token quota/weighting or lifecycle side effect?
10. Are Topic 03/04/08 and Phase 02/03/06 ownership boundaries, historical Phase 00
    preservation, dependencies, and runtime non-claims honest and sufficient for later
    implementation?

## 9. Verdict policy

Return exactly one:

```text
ACCEPT_TOPIC_02
REOPEN_TOPIC_02
INSUFFICIENT_EVIDENCE
```

`ACCEPT_TOPIC_02` requires no Critical or Important scoped defect. Minor findings may coexist
only when they cannot change entry authority, task/candidate/session identity, evidence
validity, terminal classification, Orchestrated structure, fallback behavior, phase ownership,
runtime feasibility, historical evidence, or reproducibility. A preference for different
terminology, mandatory parallelism, universal review, or a more elaborate Cheap Scout policy
is a trade-off, not a defect, unless the approved contract is contradictory, unsafe,
unimplementable, or silently weaker than stated.
