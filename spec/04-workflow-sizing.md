# 04 — Workflow Entry and Task Lifecycle

## Durable boundary for every workflow (KD-028)

After objective, authority, mandatory acceptance criteria, and verification/review obligations are
accepted, Quick, Standard, and Orchestrated create task state before mutation. Quick uses the same
minimal authority and may finish in one session. Standard adds checkpoints as needed. Orchestrated
records bounded work-unit contracts/outcomes, but subordinate results remain provisional and only
the integrated frozen task candidate can close the parent. Session switches use checked handoff,
not conversation prose.

> USER-APPROVED SPEC v2 | Canonical authority for workflow entry, classification, and the
> conceptual phase/task/candidate/session lifecycle. Detailed agent topology belongs to
> Topic 03; durable state belongs to Topic 04.

---

## A. Authority, Scope, and Runtime Grounding

This file owns five decisions:

1. how a request enters the workflow;
2. who selects Quick, Standard, or Orchestrated;
3. what distinguishes those workflows;
4. when task, candidate, and session boundaries change; and
5. how reclassification, compaction, handoff, fork, and resume affect those boundaries.

Commands, agents, skills, phase plans, and human documentation project this contract. They do
not create local variants. Agent count, model routing, and writer ownership are Topic 03
decisions. Durable IDs, storage, ownership leases, recovery, and state reconciliation are
Topic 04 decisions. Detailed task-triage interaction is Topic 08 work.

The entry contract follows pinned OMP behavior:

- `expandSlashCommand()` returns unchanged text unless it begins with `/`
  (`packages/coding-agent/src/extensibility/slash-commands.ts:110-129`);
- `AgentSession.prompt()` enters extension/custom/file-command handling only for `/`-prefixed
  text (`session/agent-session.ts:4942-4966`);
- therefore a main model cannot perform a runtime workflow transition merely by emitting
  prose such as “restart as `/standard`”; and
- `/handoff` uses a model-generated document, creates a new child session, and injects the
  document as a custom message (`session/session-handoff.ts:97-103,217-275`). The generated
  document carries context; it is not structurally validated task state.

OMP conversation history, session persistence, compaction summaries, and handoff text are
context carriers. None is project lifecycle authority by itself.

---

## B. Vocabulary

### B-1. Phase

A phase is a large program composed of multiple tasks. A phase is not a session and does not
become complete merely because one task is accepted.

### B-2. Task contract and task

A task contract contains one objective, its scope and authority boundary, its mandatory
acceptance criteria, and its required verification and review obligations. Clarification before
that contract is accepted is outside the task cycle.

**A task begins when its contract is accepted.** Retry, retrieval, rework, rejected candidate
snapshots, verification, review, compaction, handoff, and fallback stay within that task while
they pursue the same contract.

A material change to objective, mandatory criteria, required verification or review
obligations, authority, or scope after contract lock opens a new linked task. A clarification
that merely resolves the accepted contract does not.

### B-3. Candidate

A candidate is a coherent implementation snapshot frozen for verification against one task
contract. Work in progress is not a candidate merely because files have changed.

Candidates form a sequence within a task: C1, C2, and so on. Once C1 is frozen, any
**acceptance-bearing mutation invalidates** its verification and review evidence. The changed
state must be frozen as C2 before it can be accepted. Evidence never transfers silently from
one snapshot to another.

A deliberately competing implementation alternative has its own candidate lineage and must
not share an active session with another alternative.

### B-4. Session

A session serves **one task and one active candidate lineage**. Bounded rework from C1 to C2
may remain in that session, provided there is no competing alternative and stale evidence is
discarded from acceptance consideration.

### B-5. Work unit

A work unit is a bounded part of an Orchestrated task. It has explicit inputs, outputs,
ownership, dependencies, and completion conditions. It is not an independent task unless it
receives its own accepted task contract. Completing a work unit cannot accept its parent task.

---

## C. Workflow Entry

### C-1. Plain request

**Plain natural-language requests are the normal default entry.** No workflow prefix is
required. The main-session Tech Lead clarifies the contract as needed and selects Standard or
Orchestrated. The user is not required to understand or choose between those workflows.

When evidence is insufficient to distinguish them, the Tech Lead performs bounded
Standard-style clarification or discovery. It selects Orchestrated only after the structural
test in §D-3 is satisfied.

### C-2. Quick request

The user invokes `/quick` when they judge a task to be light and bounded. This is the user's
explicit Quick choice, but not an instruction to bypass correctness. The Tech Lead performs a
short preflight and may reclassify the workflow when the observed boundary is unsuitable.

### C-3. Compatibility commands and missing-slash hints

`/standard` and `/orchestrated` remain available for compatibility and advanced use. The
command files are **compatibility hints**, not final authority. The Tech Lead validates the
classification before mutating the workspace and may choose a different suitable workflow.

The words `quick`, `standard`, or `orchestrated` without `/` are natural-language routing hints,
not runtime commands. A missing slash is not an error and never requires the user to resend the
request.

| User input | Runtime interpretation | Decision owner |
|---|---|---|
| Plain natural-language request | Normal entry; no command expansion required | Tech Lead chooses Standard or Orchestrated |
| `/quick ...` | Explicit Quick request; preflight may reclassify | User initiates; Tech Lead validates |
| `/standard ...` or `/orchestrated ...` | Compatibility or advanced routing hint | Tech Lead validates before mutation |
| `quick`, `standard`, or `orchestrated` without `/` | Natural-language hint, not a slash command | Tech Lead interprets it in context |

When a hint conflicts with the task's actual boundary, the Tech Lead selects the safe suitable
workflow and reports the reason briefly. No entry form authorizes a material contract change.

---

## D. Workflow Classification

### D-1. Quick

Quick is a reduced-ceremony path for a small, clear, bounded task explicitly selected by the
user. It retains the same task contract, candidate-evidence binding, verification, and honest
terminal-state rules as every other workflow.

Quick implementation is inline by default. Optional read-only Cheap Scout retrieval does not
change the workflow classification by itself.

### D-2. Standard

Standard is **one integrated implementation lane** controlled by the Tech Lead. Discovery,
implementation, verification, and review may occur inline or use specialists under the active
Topic 03 topology. A stage name never forces a spawn.

Standard may be large, cross-module, slow, or high-risk. Those properties increase planning
and verification depth; they do not select Orchestrated by themselves.

### D-3. Orchestrated

Orchestrated applies only when all four conditions hold:

1. the task has **at least two independently verifiable work units**;
2. every work unit states its inputs, outputs, ownership, dependencies, and completion
   conditions;
3. all work-unit outputs share one task-level integration contract; and
4. acceptance requires integration or cross-boundary verification beyond checking each work
   unit separately.

The Tech Lead integrates work-unit outputs into one task-level candidate. Only the integrated
candidate can be accepted.

**Parallel writers are optional.** Orchestrated does not inherently require multiple agents,
multiple writers, parallel execution, or a separate session for every work unit. Sequential
execution remains Orchestrated when the integration graph exists. Conversely, several parallel
read-only Scouts do not turn a Standard task into Orchestrated.

If Topic 03 later selects parallel writers for particular work units, every applicable
isolation, capture, guarded-dispatch, deterministic-integration, and conflict-stop rule in
`08-isolation-and-concurrency.md` remains mandatory. Those safety mechanics constrain an
optional execution path; they do not define the workflow.

### D-4. Non-decisive signals

These signals affect risk handling but cannot select Orchestrated alone:

- number of files or modules;
- estimated duration;
- architecture, API, security, or migration risk;
- number of available agents;
- possible wall-time savings; or
- desire for a more elaborate review.

Without independently verifiable work units and a real integration boundary, use Standard.

---

## E. Lifecycle States and Candidate Evidence

The conceptual lifecycle is:

```text
Clarifying (outside the task cycle)
  -> Active
  -> Candidate frozen
  -> Verifying
  -> Accepted

Verification failure
  -> Active/Rework
  -> next frozen candidate

Other task terminals
  -> Cancelled | Terminally blocked
```

`Clarifying` ends when the task contract is accepted. At that point the task cycle becomes
`Active` and Topic 01 accounting begins.

`Candidate frozen` is an evidence boundary, not necessarily a commit. Topic 04 owns the final
durable identifier and snapshot representation. Until that mechanism exists, conversational
claims such as “this is still C1” cannot substitute for reconciling the actual workspace.

A verification failure returns the task to `Active/Rework`. Any acceptance-bearing mutation
then invalidates the frozen snapshot's evidence, and the next verification attempt targets a
newly frozen candidate.

Task lifecycle has three terminal outcomes:

- `Accepted`: the current frozen candidate satisfies the accepted contract with required
  evidence;
- `Cancelled`: authorized work ends without an accepted candidate; or
- `Terminally blocked`: the task cannot proceed within its accepted authority or available
  conditions and closes honestly as non-accepted.

`waiting_for_user`, a recoverable `blocked` condition, `partial`, and rework are not task
terminals. Topic 01's `accepted_with_waiver` remains an evaluation classification excluded
from validated acceptance and promotion. Waiving a mandatory criterion changes the contract;
it cannot relabel the old candidate as a validated accepted outcome.

If later evidence proves an accepted candidate violated its original contract, history is not
rewritten. Mark the acceptance invalid and open a linked remediation task.

---

## F. Reclassification and Escalation

Workflow changes are internal classification transitions. They do not require the user to run
another command, and the model does not claim to invoke a slash command from prose.

Before mutation, reclassification retains valid clarification and discovery evidence. During
preflight, the Tech Lead may also reduce an overestimated workflow when evidence proves the
simpler boundary.

After mutation, escalation does not delete, reset, revert, or abandon existing work. The Tech
Lead records the current boundary and continues under the suitable workflow. Reclassification
alone creates neither a new task nor a new candidate; candidate creation remains governed by
the freeze rule.

The Tech Lead may reclassify within the accepted contract without asking permission and reports
the reason briefly. If the proposed change materially alters objective, mandatory criteria,
required verification or review obligations, authority, or scope, stop at the old boundary and
obtain the user decision needed for a new linked task contract.

---

## G. Session Operations

### G-1. Continue

Continue in the current session only while it serves the same open task and the same
non-competing candidate lineage. Bounded C1-to-C2 rework is allowed after invalidating C1's
evidence.

### G-2. New

A new task or materially changed contract requires a new session. Link the old task for
provenance; do not absorb the new objective into the old conversation.

### G-3. Safe compaction

**Safe compaction does not change** session, task, candidate lineage, workflow, work-unit
ownership, or acceptance state. KD-031 permits only armed argument-free `/safe-compact` for one
native soft transaction in the managed path. Its summary, recovery artifact, and injected kernel
are not lifecycle authority; pressure recovery is one attempt or explicit Topic 04 handoff.

### G-4. Handoff

**Handoff creates a successor session** for the same task and candidate lineage. After a
successful handoff, the predecessor session no longer has active ownership, though its history
remains available.

The successor reconciles generated handoff text with the accepted task contract and actual
workspace before mutation. Handoff prose cannot alter the contract or validate a candidate.

### G-5. Fork

Fork is deliberate: use it for a competing candidate alternative or a work unit with explicit
ownership. It is not the normal continuation mechanism. A forked session cannot accept the
parent task; its output returns through Tech Lead integration and the task-level freeze boundary.

### G-6. Resume or continue a persisted session

Resume only when the task remains open and the candidate lineage still matches the contract and
workspace. On drift, stop and reconcile before mutation. Do not continue silently from stale
conversation context.

---

## H. Topology-neutral Execution and Cheap Scout

Topic 02 specifies outcomes and boundaries, not a fixed worker graph:

- the main session owns Tech Lead classification and final task acceptance;
- optional specialists are used only when they provide a clear quality benefit;
- work-unit concurrency is an execution optimization, not classification authority;
- no stage name mandates an Explorer, Implementer, Verifier, or Reviewer spawn; and
- no subagent or work unit may claim parent-task acceptance.

Cheap Scout is an optional, configurable, read-only retrieval role. The Tech Lead may use
DeepSeek, Gemini, or another suitable inexpensive model. Cheap Scout owns neither workflow
classification nor lifecycle state. If it is unavailable, fails, or returns unusable evidence,
fall back to the retrieval path the Tech Lead needs. The fallback does not change task,
candidate, session, or workflow by itself.

---

## I. Failure and Recovery Rules

| Situation | Required response |
|---|---|
| Ambiguous objective, scope, authority, mandatory criteria, or required verification/review obligations | Remain in clarification; inspect available evidence, then ask one decision question if still necessary |
| No workflow prefix | Treat as normal entry; Tech Lead selects Standard or Orchestrated |
| Missing slash on a workflow word | Treat as a natural-language hint; do not reject or ask for resubmission |
| Unsuitable explicit command or hint | Reclassify safely and report why |
| Cheap Scout unavailable or unusable | Fall back without lifecycle side effects |
| Escalation after workspace mutation | Preserve work; never perform an automatic destructive reset |
| Material contract change | Close the old boundary honestly and open a linked task/session |
| Mutation after candidate freeze | Invalidate prior acceptance-bearing evidence and freeze the next candidate |
| Incomplete or misleading handoff | Reconcile against contract and workspace |
| Resume-time workspace drift | Stop mutation until reconciliation |
| Orchestrated work unit completes | Keep parent task open until integrated candidate verification passes |
| Accepted candidate later proves invalid | Mark acceptance invalid and open linked remediation |

---

## J. Verification Matrix

Static and later behavioral evaluation must cover at least:

1. plain request without a prefix;
2. `quick`, `standard`, and `orchestrated` without `/`;
3. explicit `/quick`, `/standard`, and `/orchestrated`;
4. Quick reclassification before and after mutation;
5. preflight reduction of an overestimated hint;
6. material contract change versus in-contract clarification;
7. C1 freeze, failed verification, mutation, and C2 evidence isolation;
8. bounded rework in the same task/session;
9. compaction with unchanged lifecycle identity;
10. handoff to a reconciled successor session;
11. forked competing candidate isolation;
12. resume with matching state and resume with drift;
13. sequential Orchestrated execution;
14. optional parallel retrieval without Orchestrated classification;
15. integrated-candidate cross-boundary verification; and
16. Cheap Scout failure with retrieval fallback.

Static checks must reject active prose that requires users to select all three workflows,
claims a model can re-enter a slash command, discards work during escalation, uses modified-
candidate evidence, treats compaction/handoff text as task authority, or defines Orchestrated
by size, risk, agent count, or mandatory parallel writers.

Passing static checks does not prove runtime lifecycle enforcement. Behavioral enforcement and
durable reconciliation depend on the Topic 03 and Topic 04 mechanisms selected later.

---

## K. Deferred Ownership and Migration

| Concern | Owner | Topic 02 position |
|---|---|---|
| Detailed agent/model topology and sticky model behavior | Topic 03 | Deferred; workflow prompts remain topology-neutral |
| Durable task/candidate/session IDs and state | Topic 04 | Deferred; conceptual boundaries defined here |
| Deep task-triage interaction and heuristics | Topic 08 | Deferred; remove contradictions only |
| Parallel-writer isolation and integration safety | `spec/08` plus Topic 03 choice | Mandatory only if that optional path is selected |
| Candidate evaluation and token accounting | Topic 01 / `spec/13` | Consume these task and candidate boundaries |

The retired `workflow-sizing.yml` does not return as runtime authority. It remains only as
hash-recorded migration history. This file and the command adapters are the active sizing and
lifecycle contract.
