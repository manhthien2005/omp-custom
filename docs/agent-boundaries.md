# Managed Agent Boundaries

The template has one supported managed-agent entry point:

```powershell
pwsh -NoProfile -File .omp/bin/omp-managed.ps1
```

It starts OMP in the caller's project, loads the trusted Topic 06 wrapper followed by the final
Topic 07 continuity adapter, and applies the closed managed overlay last. The wrapper validates the
boundary, delegates execution to OMP's native `task` tool, validates the settled result, and
records a provisional Topic 04 work-unit outcome. The continuity adapter disables automatic
semantic paths and exposes armed argument-free `/safe-compact`. Neither is a second orchestrator.

Operational task state is local only. Git projects store it under the repository's Git common
directory at `agent-tasks`; non-Git projects use `.agent-tasks` in the project. It is not committed,
staged, or used as Git history.

## 1. Create the task and work unit

After the user accepts the task contract and before mutation, use the installed Topic 04 core:

```powershell
pwsh -NoProfile -File .omp/state/agent-tasks.ps1 -RequestPath request.json
```

Create the task with `create-task`, then create each dispatchable unit with `create-work-unit`.
The request envelope and compare-and-swap fields are defined by
`.omp/state/schemas/agent-tasks-v1.schema.json`; do not reproduce or relax that schema in a prompt.
`create-task` includes exact `workflow_class` and complete initial `locked_decisions`; legacy
active tasks use `set-continuity-contract` with current CAS before managed continuity.
Each unit names its inputs, outputs, ownership, dependencies, and observable completion conditions.

The wrapper obtains the authoritative projection itself with `project-work-unit`. Do not paste raw
authority JSON, state paths, credentials, conversation history, or hidden reasoning into the task.

## 2. Start the managed session

Run the launcher from the project you want OMP to operate on:

```powershell
pwsh -NoProfile -File .omp/bin/omp-managed.ps1
```

The launcher refuses altered manifests/files, unsupported OMP versions, incompatible selected
agents/config, caller-supplied extension controls, or a missing Topic 04 component. Direct `omp`
still works, but it is outside this managed evidence boundary.

## 3. Dispatch shapes

A managed single call contains only routing identity; the wrapper composes the full packet from
Topic 04 authority:

```json
{
  "task_id": "T000001",
  "work_unit_id": "WU-IMPLEMENT",
  "agent": "worker",
  "role": "worker",
  "effort": "high",
  "isolated": false
}
```

A managed batch contains complete, unique work-unit identities from one task. One invalid item
prevents native fan-out:

```json
{
  "tasks": [
    {
      "task_id": "T000001",
      "work_unit_id": "WU-A",
      "agent": "worker",
      "role": "worker",
      "effort": "high",
      "isolated": true
    },
    {
      "task_id": "T000001",
      "work_unit_id": "WU-B",
      "agent": "worker",
      "role": "worker",
      "effort": "xhigh",
      "isolated": true
    }
  ]
}
```

Native OMP owns concurrency and artifact production. Topic 04 owns worktree/scope authority,
integration order, candidate identity, and final acceptance.

## 4. Role and effort selection

| Role | Selection | Exact route | Authority |
|---|---|---|---|
| Cheap Scout | Only when bounded read-only retrieval helps | DeepSeek Flash `xhigh`; Pro `xhigh` availability fallback | Evidence hints only |
| Worker | Only when delegation has a concrete benefit | `high` normally; Tech Lead selects `xhigh` for hard work | One provisional work unit |
| Reviewer | Only when the accepted risk/quality gate requires review | `xhigh` | Findings/decision only |

The Tech Lead decides whether work is hard enough for Worker `xhigh`. Reviewer effort is fixed.
The wrapper checks the returned model role, resolved model, fallback flag, and effective effort;
silent substitution fails the managed result.

If Flash is unavailable, the receipt must disclose the exact Pro fallback. If both Scout routes
are unavailable, the Tech Lead retrieves inline. No unapproved model becomes a Scout fallback.

## 5. Reviewer independence

Reviewer input is:

```text
ARTIFACT + CONTRACT + independently obtainable evidence
```

It explicitly excludes:

```text
Worker CLAIM + Worker narrative + hidden reasoning + proposed verdict
```

Opus may be preferred when available, but is not required. A same-model review uses a separate
session and is disclosed. If managed review is unavailable, inline Tech Lead review is allowed,
but it is not called independent and receives no fabricated Reviewer receipt.

## 6. Receipt and outcome meaning

`agent_boundary_receipt` reports whether the selected packet, runtime identity, structured output,
candidate binding, and outcome recording passed. A completed receipt is still provisional. It
cannot freeze a candidate, integrate artifacts, satisfy omitted acceptance criteria, or accept the
parent task. Those transitions remain Topic 04 + Tech Lead responsibilities.

Malformed or overridden structured output, identity mismatch, stale candidate, a forced partial,
or a failed outcome compare-and-swap produces a failed receipt. Raw model prose is never promoted
as a substitute.

## 7. Execution-mode rules

- **Plan mode:** read-only planning contracts may run; mutation or fresh-command completion is
  refused because plan-mode child tools cannot fulfill it.
- **Batch:** supported for bounded independent work units from one task; every item is validated
  before one native call and settled independently afterwards.
- **Async:** rejected in managed v1. Selected agents are blocking so stage barriers receive a
  settled result.
- **Nested agents:** rejected in managed v1. The Tech Lead repartitions nested work into top-level
  work units.
- **Isolation:** validated and delegated to native OMP. Topic 06 does not create worktrees, merge
  artifacts, or infer write ownership.
- **Request budget:** Topic 06 sets `task.softRequestBudget: 200`; the runtime's forced partial at
  300 requests is nonterminal.
- **Continuity:** Topic 07 sets the exact disabled automatic-compaction profile. At pressure the
  main session runs `/safe-compact` once or hands off explicitly; a bounded child fails/partial
  without automatic retry. See `docs/context-continuity.md`.

## 8. When managed dispatch is unavailable

The normal fallback is simple: the Tech Lead works inline or selects a genuinely different
contract and validates it before use. Inline fallback creates no self-packet, self-review,
simulated subagent, or `agent_boundary_receipt`. If independent review is mandatory and no valid
review path exists, that gate remains unmet rather than being renamed complete.

## 9. Managed versus unmanaged OMP output

Only calls made through the installed launcher and same-name wrapper can produce a valid Topic 06
receipt. Bare OMP, Vibe, `eval`, and unrelated OMP internal agents remain useful native facilities,
but their output is unmanaged context and cannot become acceptance evidence merely because it
exists.

`OPEN-T06-RUNTIME-01` records a possible future upstream universal interception seam. It is not a requirement
for this local single-operator boundary and does not require Opus or another provider
to unblock Topic 06.
