# Quick Workflow

Quick is the user's explicit narrow-task choice. The main-session Tech Lead validates suitability
before mutation; an unsuitable hint changes internal classification without reinvoking another
slash command or discarding valid work.

## Contract

- one tightly bounded objective and write scope;
- low risk, known target, no unresolved cross-boundary behavior;
- one to three mandatory acceptance criteria;
- named fresh verification;
- review obligations locked before mutation.

After the contract is accepted, create the same minimal task authority through
`state/agent-tasks.ps1` as described by `state/PROTOCOL.md` before mutation. At lifecycle
boundaries call that same core; never edit authority JSON directly. If the core or authority root
is unavailable, mutating work fails closed, while read-only diagnosis may continue with the
limitation disclosed. The `create-task` request must include exact `workflow_class: quick` and the
complete initial `locked_decisions` array accepted for this task; an empty array is valid, but the
runtime never invents decisions. For a legacy active task missing these fields, call
`set-continuity-contract` with `workflow_class: quick`, complete `locked_decisions`, non-empty
authority/reason, and exact current revision/hash/lease compare-and-swap. Quick may still finish in
one session.

## Flow

1. Accept the task contract and freeze the scope.
2. Inspect the directly relevant files and confirm the root cause/change target.
3. Implement inline as the Tech Lead. Default to no subagent spawn.
4. Run fresh verification and bind it to the frozen candidate.
5. Apply the review risk gate and report evidence/unresolved items.

Cheap Scout is optional only when one bounded read-only retrieval question has a concrete benefit
over inline search. It remains advisory and cannot verify, review, write, integrate, or issue a
verdict. Quick does not spawn Worker merely to mirror a workflow stage.

Retrieval routing has the same truth authority in every workflow; only workflow depth differs.
The Tech Lead independently selects one of four arms: Lead/native, Lead/CodeGraph, Scout/native
then Lead, or Scout/CodeGraph then Lead. CodeGraph is optional/default-off and source-fitness
selected. An absent/unhealthy graph takes a named native fallback; Scout unavailability is
`ENVIRONMENT_BLOCKED`, after which the Tech Lead continues the required retrieval.

Review is mandatory for security, authentication, durable data, database migration, concurrency,
public API, and destructive change concerns; those concerns normally prove Quick unsuitable. Other
review follows the accepted contract and actual risk. Reviewer always runs at exact `xhigh`.

## Lifecycle boundary

If inspection changes the objective, authority boundary, mandatory criteria, or locked
verification/review obligations, open a linked task. If only workflow classification changes,
preserve valid discovery/work and continue under the reconciled internal state. Any
acceptance-bearing mutation invalidates earlier evidence and creates the next candidate.

## Context continuity

Only after exactly one active task is owned by this persisted OMP session and the managed gate is
armed may the user or Tech Lead run argument-free `/safe-compact`. It saves and verifies local
recovery bytes, runs one native soft transaction, and leaves the next normal prompt to receive one
fresh kernel without hidden continuation or retry. Quick may disclose only the exact permitted
missing secondary fields—never objective, authority, mandatory criteria, revision/lease identity,
or locked decisions. If `/safe-compact` is unavailable/refused or one attempt leaves pressure
unresolved, checkpoint and use explicit Topic 04 `begin-handoff`/`accept-handoff` recovery. Do not
use built-in `/compact`, `/shake`, snapcompact, automatic retry, or automatic handoff.

## Completion

Do not report completion unless every mandatory criterion has fresh evidence for the current
candidate. A partial, blocked, failed, invalid structured result, or missing capability remains
nonterminal and is disclosed.
