# Durable Task State Protocol

This directory contains the deterministic, local `agent-tasks` core. Claude and Codex use the
same request/result envelope and the same authority root; neither runtime may maintain a second
lifecycle reducer.

## Locate and invoke the core

Prefer the project component at `<project>/.omp/state`. If it is absent, use the installed user
component at `~/.omp/agent/state`. The core requires `pwsh 7.4` or newer.

Write one JSON request envelope to a temporary file and invoke:

```powershell
pwsh -NoProfile -File .omp/state/agent-tasks.ps1 -RequestPath request.json
```

Use `-RequestPath -` to read the envelope from stdin. A request contains `schema_version`,
`operation`, `working_directory`, opaque `session_ref`, `runtime`, and structured `request`.
The command writes exactly one machine-readable result envelope to stdout. Consult
`schemas/agent-tasks-v1.schema.json` for field definitions; do not reproduce the schema in an
adapter or prompt.

Exit codes are stable:

| Exit | Meaning |
|---:|---|
| 0 | Operation succeeded |
| 2 | Request/schema error |
| 3 | Authority, state, CAS, or policy refusal |
| 4 | Corrupt/unavailable local authority or capability |
| 5 | Sanitized unexpected internal failure |

## Lifecycle calls

All calls use the envelope above. These examples show only the operation and request payload;
the schema file remains authoritative.

| Boundary | Operation | Request payload sketch |
|---|---|---|
| Inspect | `status` | `{}` |
| Initialize | `init-project` | `{"display_name":"Project"}` |
| Accept task contract | `create-task` | objective, authority, mandatory ACs, obligations, mode, scope, workflow class, locked decisions |
| Set continuity contract | `set-continuity-contract` | task ID, workflow class, complete locked decisions, authority/reason, current CAS |
| Durable boundary | `checkpoint` | task ID, kind, next action, blockers/risks, current CAS |
| Project selected work | `project-work-unit` | exact task ID and listed immutable work-unit ID |
| Project continuity | `project-continuity` | `{}`; task identity is derived from the exact envelope session/runtime |
| Freeze exact bytes | `freeze` | task ID, acceptance inputs, dispositions, current CAS |
| Rehash candidate | `check` | task ID and candidate ID |
| Promote safe output | `promote-artifact` | task ID, scratch source, media type, candidate/handoff ID |
| Record proof | `record-evidence` | closed evidence type, exact bindings, observation, current CAS |
| Start transfer | `begin-handoff` | named successor, next action, blockers/risks, current CAS |
| Accept transfer | `accept-handoff` | handoff/predecessor identity and current CAS |
| Crash recovery | `takeover` | named successor, explicit user authorization, reconciliation, CAS |
| Finish | `close` | exact terminal status, candidate when accepted, reason otherwise, CAS |

`status`, `project-work-unit`, and `project-continuity` are read-only. `project-work-unit` returns a closed,
hash-stable `work_unit_projection` containing only the selected task/work-unit contract,
reconciled worktree/candidate/diff/artifact bindings, and current CAS. It refuses inactive,
unowned, corrupt, stale, unlisted, or incorrectly bound authority instead of reconstructing
private state in an adapter.

`project-continuity` accepts an empty request only. It derives exactly one active task owned by
the envelope's exact `session_ref` and `runtime`; zero or multiple matches fail closed. The result
is a closed, hash-stable `context_continuity_kernel` capped at 16 KiB. It includes the task
contract, workflow/locked decisions, lease/revision identity, validated checkpoint, selected
candidate, and evidence IDs plus record hashes only. It never returns authority paths, raw
evidence observations, messages, transcripts, terminal output, prompts, or hidden reasoning.
Referenced missing, corrupt, stale, or drifted records always refuse. Explicit null/empty
secondary state is valid; only Quick may name the exact permitted fields missing from a classified
legacy record, while Standard and Orchestrated refuse every degradation.

Every new task revision records exactly one `workflow_class` (`quick`, `standard`, or
`orchestrated`) and a bounded, canonical `locked_decisions` array. Only
`set-continuity-contract` may initialize or replace those fields. It requires the exact owner
session/runtime and current revision/hash/lease CAS, refuses no-op changes, and binds an immutable
`supporting/CCnnnnnn.json` authority record to the new revision. Legacy v1 task revisions without
both fields remain readable and projectable, but every mutation is refused with
`AT-CONTINUITY-CLASSIFICATION-REQUIRED` until that explicit operation classifies the task. The
reducer never infers a workflow class from prompt text, model choice, command name, or agent count.

`begin-handoff` returns `handoff_projection` in the same task lock that creates the durable
handoff and transferring revision. Callers must use that projection; they must not reconstruct a
handoff packet from authority JSON or perform an unlocked follow-up read.

Run `cleanup` without a mode (or with `dry-run`) before `apply`. Archive is recoverable through
`restore`. Permanent `purge` requires confirmation exactly equal to the task ID. Lock recovery,
takeover, purge, and migration are explicit operations; elapsed time and model prose never grant
authority.

## Safety boundary

Never edit authority JSON directly. Never copy authority records, raw transcripts, credentials,
or hidden reasoning into a prompt. Pass compact IDs and validated projections only. Runtime
artifacts remain transient until the core promotes sanitized, acceptance-relevant bytes.

If the core or authority root is unavailable, mutation fails closed. Read-only diagnosis may
continue and must report that durable authority was unavailable. A manual core adapter is the
selected integration in Topic 04; automatic lifecycle hooks remain uninstalled until the Topic 08
installed-runtime probe validates their attachment points.
