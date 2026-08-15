# Local Durable Task State

OMP workflow lifecycle authority is local and intentionally untracked by Git. In a Git project it
lives at `<git-common-dir>/agent-tasks`, shared by linked worktrees. Before Git initialization it
lives at `<project>/.agent-tasks`; after Git is initialized that legacy root becomes read-only until
the explicit migration command moves it to the Git common directory.

The installed executable component is `<project>/.omp/state` (or user fallback
`~/.omp/agent/state`). It contains code, the protocol, and schemas—not operational records.
Installing, reinstalling, backing up, or rolling back `.omp/state` never removes or rewrites an
`agent-tasks` authority root.

After the user accepts the objective, authority, mandatory acceptance criteria, and required
verification/review, create the task through `state/agent-tasks.ps1` before mutation. Quick,
Standard, and Orchestrated all use this same core. See
[`template/.omp/state/PROTOCOL.md`](../template/.omp/state/PROTOCOL.md) for the black-box protocol.

Candidate and evidence records bind exact bytes. Normal handoff is two-phase; crash takeover and
stale-lock recovery require explicit user authorization. Cleanup defaults to dry-run, archive is
recoverable from trash, and permanent purge requires the exact task ID.

Operational state is local to this machine. Deleting repository metadata can delete the Git-local
authority, so use cleanup/backup policy deliberately. Never commit the authority root or paste its
raw records into a prompt.

## Managed agent projection

Topic 06 never reads private authority files directly. Its trusted wrapper asks this core for one
closed `project-work-unit` projection, validates it before and after native OMP dispatch, and
records only a provisional `record-work-unit-outcome` through compare-and-swap. The receipt cannot
freeze, integrate, or accept the parent task.

Use `.omp/bin/omp-managed.ps1` for managed agent calls. If the boundary is unavailable, inline Tech
Lead work continues against the same Topic 04 authority without a self-packet or fabricated
receipt. See [`agent-boundaries.md`](agent-boundaries.md).

## Continuity projection

Every new `create-task` request includes exact `workflow_class` (`quick`, `standard`, or
`orchestrated`) and the complete initial `locked_decisions` array. Empty is valid when no decision
was locked. A legacy active task missing either field remains readable but cannot mutate or use
managed continuity until `set-continuity-contract` initializes both with non-empty authority and
reason plus exact current revision/hash/lease compare-and-swap.

`project-continuity` is read-only and derives exactly one active task from the current persisted
OMP session identity. Its closed 16 KiB kernel carries task contract, workflow/decisions,
revision/lease, validated checkpoint, selected candidate, and evidence IDs/hashes—never authority
paths, raw observations, transcripts, prompts, terminal output, or hidden reasoning. `/safe-compact`
uses this projection but cannot change it. If continuity is unavailable or pressure remains after
one attempt, record a checkpoint and use Topic 04 `begin-handoff`/`accept-handoff`; do not infer a
successor from summary text.
