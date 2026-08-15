# Topic 02 Workflow Entry and Task Lifecycle Design

> **Status:** User-approved. Canonical specification and phase-plan projection complete;
> installable runtime projection is deliberately deferred to Phase 02 after Topic 03/04/08
> dependencies are decided.
>
> **Scope:** Workflow entry, workflow classification, and the lifecycle boundaries among
> phases, tasks, candidates, sessions, work units, compaction, and handoff. This document is
> a design record, not runtime state or implementation authority.

## Goal

Give users one simple default entry path while giving the main-session Tech Lead enough
authority to select and change the workflow safely. Define lifecycle boundaries precisely
enough that later topology, persistence, accounting, and evaluation work can rely on the
same meanings.

The design must:

- let a user choose Quick without requiring them to distinguish Standard from Orchestrated;
- make a request without any workflow prefix a valid normal entry;
- let the Tech Lead reclassify work without pretending to invoke another slash command;
- preserve valid discovery and workspace changes during escalation;
- distinguish Orchestrated by its integration structure, not by task size or agent count;
- prevent task, candidate, session, compaction, and handoff from being used interchangeably;
- remain topology-neutral until Topic 03 and persistence-neutral until Topic 04.

## Non-goals

Topic 02 does not:

- implement a durable task-state store or identifier schema;
- mandate a particular agent graph, model, or number of workers;
- make parallel writers the default;
- implement the benchmark or token-accounting machinery;
- redesign the full `task-triage` skill;
- change OMP's native slash-command, session, fork, compaction, or handoff mechanics.

Topic 03 owns detailed agent topology. Topic 04 owns durable lifecycle state and recovery.
Topic 08 owns the deeper task-triage behavior. Topic 02 may make only the minimal changes on
those surfaces needed to remove contradictions with this contract.

## Authority and Projection

`spec/04-workflow-sizing.md` is the canonical project authority for workflow entry,
classification, and task/candidate/session lifecycle semantics. Other surfaces project that
contract and must not introduce independent rules:

- Phase 02 will migrate `template/.omp/AGENTS.md`, the three command adapters, Tech Lead role
  material, and task triage from their hash-locked Phase 00 snapshot;
- human-facing product documentation is updated with that runtime migration, not ahead of it;
- phase specifications track later implementation without redefining the lifecycle;
- `task-triage` may mirror the canonical classification terms but is not their authority.

OMP conversation history, session storage, generated handoff text, and compaction summaries
are context carriers. None is authoritative task state by itself.

## Core Vocabulary

### Phase

A phase is a larger program of related work composed of multiple tasks. A phase is not a
session and does not become accepted through a single task's acceptance.

### Task contract and task

A task contract is one objective, its scope and authority boundary, its mandatory acceptance
criteria, and its required verification and review obligations. Clarification before this
contract is accepted is not a task cycle.

A task begins when its contract is accepted. Retries, rework, rejected candidates, and
internal Orchestrated work units remain within the same task while they pursue that contract.
A material change to the objective, mandatory criteria, required verification or review
obligations, authority, or scope after contract lock opens a new linked task rather than
silently expanding the existing task.

### Candidate

A candidate is a coherent implementation snapshot frozen for verification against one task
contract. Work in progress is not a new candidate merely because files changed.

Candidates form an ordered sequence within a task: C1, C2, and so on. After a candidate is
frozen, any change to code, configuration, specifications, or other acceptance-bearing
content invalidates evidence for that snapshot. The changed result must be frozen as the
next candidate before verification can establish acceptance.

### Session

A session serves one task and one active candidate lineage. Bounded rework and the sequential
transition from C1 to C2 may remain in the same session, but the session must not mix tasks or
competing candidate alternatives.

### Work unit

A work unit is a bounded portion of an Orchestrated task with explicit inputs, outputs,
ownership, dependencies, and completion conditions. It is not an independent task unless it
receives a separate accepted task contract. Work-unit completion cannot accept the parent
task.

## Workflow Entry Contract

### Normal entry without a prefix

A plain natural-language request is the normal default entry. The main-session Tech Lead
clarifies the contract as needed and chooses Standard or Orchestrated. The user is never
required to decide between those two workflows.

If there is not yet enough evidence to distinguish Standard from Orchestrated, the Tech Lead
uses bounded Standard-style clarification or discovery. It switches to Orchestrated only when
the task is shown to require multiple independently verifiable work units and explicit
integration.

### Quick entry

`/quick` is the user's explicit choice for work they judge to be light and bounded. The Tech
Lead performs a short preflight before mutation and escalates when the actual scope, risk, or
structure is unsuitable for Quick.

### Compatibility entries and natural-language hints

`/standard` and `/orchestrated` remain available for compatibility and advanced use. They are
routing hints, not authority that bypasses Tech Lead validation. Before mutation, the Tech
Lead confirms or reclassifies the workflow from the task's actual structure.

The words `quick`, `standard`, or `orchestrated` supplied without `/` are natural-language
hints rather than runtime commands. The Tech Lead interprets them in context. A missing slash
is not an error and does not require the user to resend the request.

When a hint conflicts with the task, the Tech Lead selects the safer suitable workflow and
briefly reports the reclassification. Workflow commands and hints never authorize a material
change to the task contract.

## Workflow Definitions

### Quick

Quick is for a small, clear, bounded task selected explicitly by the user. It has reduced
ceremony, not reduced correctness. The same contract, candidate-evidence binding, and
acceptance rules still apply.

### Standard

Standard is one integrated implementation lane controlled by the Tech Lead. The Tech Lead may
use read-only Scouts, reviewers, verifiers, or other specialists when useful. Their presence
does not change the workflow classification and no fixed Explorer-to-Implementer-to-Verifier
topology is part of this lifecycle contract.

### Orchestrated

Orchestrated applies only when all of the following are true:

- the task contains at least two independently bounded and verifiable work units;
- each work unit can state its inputs, outputs, ownership, dependencies, and completion
  conditions;
- the outputs share a task-level integration contract; and
- acceptance requires integration or cross-boundary verification beyond checking each unit
  separately.

The Tech Lead integrates work-unit outputs into one task-level candidate. Only that integrated
candidate can be accepted.

Orchestrated does not inherently require multiple agents, multiple writers, parallel
execution, or one session per work unit. Those are execution optimizations used only when
ownership, dependencies, and write sets support them. Sequential work can still be
Orchestrated, while several parallel read-only Scouts can still support a Standard task.

File count, duration, complexity labels, and risk level affect planning and verification
depth but do not independently select Orchestrated. Without genuine independently verifiable
work units and an integration boundary, the Tech Lead uses Standard.

## Cheap Scout

Cheap Scout is an optional, configurable, read-only retrieval role. The Tech Lead uses it when
useful and may select DeepSeek, Gemini, or another suitable inexpensive model. Cheap Scout
does not own workflow classification, task state, or acceptance.

If Cheap Scout is unavailable, fails, or returns unusable evidence, the workflow fails softly
to the retrieval path the Tech Lead needs. This fallback does not change the task, candidate,
session, or workflow by itself.

## Lifecycle States

The conceptual lifecycle is:

```text
Clarifying
  -> Active
  -> Candidate frozen
  -> Verifying
  -> Accepted
```

`Clarifying` precedes the task cycle. The cycle begins only when the contract is accepted and
the task becomes `Active`.

Verification failure returns the task to `Active/Rework`. Any acceptance-bearing change then
invalidates the frozen snapshot's evidence, and the next verification attempt targets a newly
frozen candidate.

A task has exactly one of these terminal outcomes:

- `Accepted`: the current frozen candidate satisfies the accepted contract with required
  evidence;
- `Cancelled`: authorized work stops without an accepted candidate;
- `Terminally blocked`: work cannot proceed within the current authority or available
  conditions and is honestly closed as non-accepted.

A clarification or user response remains in the current task when it only resolves the
existing contract. A new objective or mandatory criterion after a terminal outcome is a new
linked task.

If later evidence proves that an accepted candidate violated its original contract, history
is not rewritten. The prior acceptance is marked invalid, and a linked remediation task is
opened. This preserves the original evidence trail and avoids treating post-acceptance work
as hidden rework inside a closed task.

## Workflow Reclassification and Escalation

Workflow changes are internal classification transitions. The Tech Lead does not instruct
the model to "restart as" another slash command.

Before mutation, reclassification keeps valid clarification and discovery evidence. During
preflight, the Tech Lead may also reduce an overestimated workflow when evidence shows a
simpler structure.

After workspace mutation begins, escalation does not delete, discard, reset, or automatically
revert existing work. The Tech Lead records the current boundary and continues under the
suitable workflow. Reclassification alone creates neither a new task nor a new candidate.
Candidate creation still follows the freeze rule.

The Tech Lead may perform an in-contract escalation without asking permission and reports the
reason briefly. If the proposed change materially alters objective, mandatory criteria,
required verification or review obligations, authority, or scope, the Tech Lead stops at the
old boundary and obtains the user decision needed for a new task contract.

## Session Operations

### Continue within a session

The same session may continue while it serves the same open task and the same non-competing
candidate lineage. Bounded rework from C1 to C2 is allowed, with prior evidence invalidated as
specified above.

### New

A new task or materially changed contract requires a new session. The old task may be linked
for provenance, but its session must not absorb the new objective.

### Compaction

Compaction rescues context for one long work unit within the current session. It changes
neither session identity nor task, candidate, workflow, ownership, or acceptance state. A
compaction summary cannot become lifecycle authority.

### Handoff

Handoff creates a successor session that continues the same task and candidate lineage. Once
the handoff is accepted, the predecessor session no longer has active ownership. Its history
remains available.

Generated handoff text is a context aid, not authoritative state. The successor must reconcile
the handoff with the accepted task contract and the actual workspace before mutation.

### Fork

Fork is reserved for a deliberate competing candidate alternative or a work unit with an
explicit ownership boundary. It is not the ordinary continuation mechanism. Forked work does
not acquire authority to accept the parent task; competing results must return through the
Tech Lead's integration and candidate-freeze boundary.

### Resume or continue

Resume/continue is valid only when the task remains open and the session's candidate lineage
matches the authoritative contract and workspace. If the workspace or lifecycle has drifted,
the Tech Lead stops and reconciles it before mutation. It does not silently continue from stale
conversation context.

## Failure and Recovery Rules

- An ambiguous request stays in clarification until the contract can be accepted.
- A missing workflow prefix is normal entry, not a command error.
- An unsuitable command or hint is safely reclassified and reported.
- Failed or unavailable Cheap Scout retrieval falls back without changing lifecycle state.
- A misleading or incomplete handoff is corrected from the contract and workspace.
- Resume-time candidate drift blocks mutation until reconciliation.
- Mutation after candidate freeze invalidates all acceptance-bearing evidence for that
  candidate.
- Partial work survives escalation unless the user separately authorizes a destructive
  operation.
- A material contract change opens a linked task rather than being hidden inside rework.
- Completion of an Orchestrated work unit cannot be mistaken for task acceptance.

## Validation Matrix

Projection of this design must include scenario checks for at least the following cases:

| Scenario | Required result |
| --- | --- |
| Plain request, no prefix | Main-session Tech Lead chooses Standard or Orchestrated; no command error |
| `quick` without slash | Treated as a natural-language hint and validated in context |
| Explicit `/quick` | Quick preflight occurs; escalation remains available |
| Explicit `/standard` or `/orchestrated` | Treated as a compatibility/advanced hint, validated before mutation |
| Uncertain Standard versus Orchestrated | Bounded Standard-style discovery; Orchestrated only after its structural test passes |
| Quick becomes unsuitable before mutation | Internal escalation retains valid discovery |
| Escalation after mutation | Existing work is preserved; no automatic reset or slash-command restart |
| Material contract change | A new linked task and new session are required |
| Candidate changed after freeze | Prior verification evidence is invalid; next snapshot becomes C2 or later |
| Verification rework without contract change | Remains in the same task and may stay in the same session |
| Compaction | Same session, task, candidate lineage, ownership, and state |
| Handoff | Successor session continues the same lineage after reconciliation; predecessor loses active ownership |
| Forked alternative | Competing lineage remains isolated and returns through Tech Lead integration |
| Resume with matching state | Continuation is allowed |
| Resume with workspace drift | Reconciliation is required before mutation |
| Orchestrated unit completes | Parent task remains open until the integrated candidate passes cross-boundary verification |
| Cheap Scout failure | Retrieval fallback occurs without lifecycle or classification side effects |
| Accepted task later shown invalid | Acceptance is marked invalid and a linked remediation task opens |

Static consistency checks must also remove or reject statements that:

- require users to choose among all three workflows;
- treat a model-authored `/standard` or `/orchestrated` string as a runtime transition;
- equate Orchestrated with size, risk, file count, agent count, or parallel writers;
- prescribe the old fixed agent topology as part of Topic 02;
- treat compaction or handoff prose as task-state authority;
- permit evidence from a modified candidate to support acceptance;
- imply escalation discards or automatically reverts workspace changes.

## Acceptance Criteria for Topic 02 Architecture Projection

Topic 02 architecture/specification work is complete only when:

1. The canonical workflow spec contains this entry and lifecycle contract without depending
   on the later persistent state engine.
2. Phase 02 explicitly schedules main-session and command migration for no-prefix entry,
   user-selected Quick, and Tech-Lead-selected Standard versus Orchestrated.
3. Workflow transitions are described as internal classification changes rather than slash
   command reinvocation.
4. Task, candidate, session, work-unit, compaction, handoff, fork, and resume boundaries are
   mutually consistent across all projected surfaces.
5. Orchestrated requires independently verifiable units plus task-level integration and does
   not require default parallel writers.
6. Candidate-bound verification evidence is invalidated after mutation.
7. The specification/phase validation matrix passes and stale contradictory statements are
   absent from active architectural authority.
8. Topic 03, Topic 04, and Topic 08 ownership boundaries remain explicit and unimplemented
   except for minimal contradiction removal.
9. Historical Phase 00 prompt/evidence hashes remain unchanged; Phase 02 requires a separate
   current-product evidence identity rather than rewriting history.

Runtime acceptance remains a Phase 02 exit gate. Topic 02 closure does not claim that the
currently installed prompt snapshot already implements the new design.

## Expected Follow-on Work

After this design is approved and projected:

- Topic 03 can select an agent topology without redefining workflow classification.
- Topic 04 can assign durable IDs, persistence, ownership leases, and recovery transitions to
  these conceptual states.
- Topic 08 can implement deeper triage behavior against the same Standard/Orchestrated test.
- Evaluation work can attach task-cycle accounting and evidence to stable task and candidate
  boundaries.
