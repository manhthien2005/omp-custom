# Managed Context Continuity

Topic 07 keeps a long managed OMP task continuous without letting a generated summary replace the
task's real authority. Automatic semantic compaction is off. The protected path is one explicit,
argument-free command:

```text
/safe-compact
```

Use it only from `.omp/bin/omp-managed.ps1`. Bare `omp` remains usable, but it does not provide the
guarantee described here.

## When the command is available

`/safe-compact` works only when all of these are true:

- the trusted managed component and exact continuity settings are active;
- the main OMP session is persisted to a real session file;
- the session is idle, with no queued/running async delivery or pending user message;
- exactly one active Topic 04 task is owned by this exact OMP session;
- that task has an exact `workflow_class` and complete `locked_decisions`;
- the task projection, revision, lease, branch, and session bytes still agree; and
- no earlier safe-compaction epoch is pending, summarizing, invalid, or awaiting injection.

The first task is created after its contract is accepted. Its `create-task` request must carry
`workflow_class: quick`, `standard`, or `orchestrated` plus the complete initial
`locked_decisions` array. Empty is valid when nothing was locked. A legacy active task must first
use `set-continuity-contract` with non-empty authority/reason and the exact current
revision/hash/lease compare-and-swap.

The command accepts no focus text. A phrase such as `/safe-compact focus on X` is rejected because
caller prose could omit or rewrite a locked fact. The focus is always the canonical Topic 04
continuity kernel.

## What happens during one safe compaction

1. The adapter rechecks the managed settings and exact current-session task ownership.
2. It reads the persisted session branch and builds a closed, hash-stable Topic 04 kernel.
3. It writes a local recovery artifact containing the bound branch and kernel, reads it back, and
   verifies its location, bytes, and hash before any compaction starts.
4. It opens a short-lived single-use authorization and calls native
   `ctx.compact({ mode: "soft" })` exactly once. That one transaction uses local context-full
   summarization; remote compaction stays disabled.
5. OMP settles the native compaction entry with bound preserve data. The authorization is consumed.
6. Control returns to the user. No prompt is sent and no continuation, retry, or handoff is
   scheduled.
7. The next normal prompt receives one fresh canonical kernel. Immediately before provider entry,
   the adapter rechecks authority and records that the kernel was consumed. It is not injected
   again.

The native context-full summarizer uses OMP's configured model/provider. Topic 07 adds no model
fallback or retry around it.

## What is saved locally

Before compaction, the recovery artifact binds:

- the exact persisted session and branch entries;
- task ID, current revision hash, and lease generation;
- workflow class and locked decisions;
- objective, authority, execution mode, write scope, and mandatory acceptance criteria;
- validated checkpoint, current work unit/next action/blockers/risks when applicable;
- selected candidate identity and evidence record IDs/hashes; and
- the continuity-kernel and recovery-artifact hashes.

It does not contain authority paths, raw evidence observations, conversation transcripts, prompts,
terminal history, hidden reasoning, environment dumps, or credentials. The raw authorization
nonce exists only in memory and is cleared before summarization.

Operational authority remains in the local Topic 04 `agent-tasks` root. The recovery artifact,
native summary, preserve data, epoch record, and injected kernel are context only. None can accept,
reclassify, transfer, or close a task.

## Workflow completeness

Quick, Standard, and Orchestrated always require task identity, workflow class, objective,
mandatory criteria, authority, execution mode, write scope, obligations, revision/lease identity,
and every locked decision.

Quick may continue when authoritative state explicitly reports that one or more secondary fields
are absent and names those exact fields in `degraded_fields`: checkpoint, work-unit ID, next action,
blockers, open risks, candidate, or evidence bindings. The adapter never invents a replacement.
Standard and Orchestrated permit no such degradation; an applicable missing secondary field
refuses compaction.

## Context pressure

Managed sessions reserve the larger of 16,384 tokens or 15% of the context window (with a bounded
fallback for small windows). At or above the resulting threshold, ordinary provider dispatch is
aborted before entry.

- In the main session, wait until idle and run `/safe-compact`, or make an explicit Topic 04
  handoff.
- In a bounded subagent, the child stops. Topic 06 settles it as failed/partial; it cannot return a
  plausible managed success and is not retried automatically.
- If one safe compaction leaves pressure unresolved, stop. Checkpoint and hand off explicitly, or
  request user-directed cleanup/action.

## Failure recovery

| Situation | Required action |
|---|---|
| Command is unavailable or task is not armed | Create/classify the Topic 04 task, or use explicit handoff; do not compact an authority-free bootstrap transcript. |
| Session is in-memory or busy | Persist the session and wait until idle; retry only by explicit user/Tech Lead action. |
| Recovery artifact cannot be written or verified | No native compaction occurs. Keep the original branch and resolve local persistence. |
| Revision, lease, branch, or session changes | Reconcile Topic 04 authority; never continue from the stale summary. |
| Native preparation cannot compact the recent turn | Preserve the original branch and use explicit handoff or user-directed cleanup; never rescue-shake. |
| Native transaction fails or exhausts its internal candidate chain | Topic 07 adds no retry. The original branch remains authoritative. |
| Kernel is missing, duplicated, stale, or cannot be injected | Provider work stops until authority is reconciled. |
| One attempt still leaves pressure | Checkpoint and use Topic 04 `begin-handoff`/`accept-handoff`, or request user action. |
| Bounded child reaches pressure | Treat the outcome as failed/partial; Tech Lead chooses inline recovery, a narrower redispatch, or the approved Scout fallback. |

## Unsupported paths

- Automatic context-full compaction and context promotion are disabled.
- Built-in `/compact` lacks the protected authorization and is cancelled.
- Direct `/shake` is blocked where the managed input hook sees it. A bypass through bare or
  unsupported OMP is outside the guarantee and may be irreversible.
- Snapcompact is evaluation-only and not a managed fallback.
- Automatic handoff is disabled. Handoff is an explicit Topic 04 ownership transition.
- Remote compaction and remote streaming are disabled.
- Subagents cannot invoke `/safe-compact`.

## Install, validate, observe, and roll back

Install the default project components and launch the managed entry point:

```powershell
.\scripts\install-template.ps1 -Target project -ProjectDir "D:\Your\Project" -DryRun:$false
pwsh -NoProfile -File .omp\bin\omp-managed.ps1
```

Run the focused local validator:

```powershell
pwsh -NoProfile -File scripts\validate-topic07-context-continuity.ps1
```

The adapter appends bounded `topic07:observation`, `topic07:epoch-state`, and—only for child
pressure—`topic07:context-pressure-abort` entries to the local OMP session. Inspect them through
OMP's session tools or search the exact known session file; do not edit the session file. An
observation records counts, hashes/statuses, the boundary, settings drift, and provider action—not
the transcript or hidden reasoning.

Rollback with the exact backup printed by the installer. The manifest-coupled continuity files are
restored with `agent-boundary`; Topic 04 `agent-tasks`, OMP sessions, and recovery artifacts are
retained. Rollback removes the managed guarantee but does not rewrite task authority.

## Routing and promotion status

OmniRoute, DeepSeek Scout routing, Worker/Reviewer effort, and Opus preference are separate and
unchanged. Opus is not required for continuity. A missing model/provider may affect the one native
summary call, but it does not authorize another continuity mechanism.

The component declares OMP 17.2.10 and 17.2.12 support. Pinned source seams and the installed
17.2.12 stop-before-provider canary pass locally. A verified local 17.2.10 executable is currently
unavailable, and no download or downgrade was attempted. Therefore Topic 07 is
`IMPLEMENTED_NOT_PROMOTED` with `OPEN-T07-RUNTIME-02` until that second local canary passes.
