<div align="center">

# omp-custom

**Production-ready workflow template for [OMP (Oh My Pi)](https://github.com/oh-my-pi/oh-my-pi)**

Three-agent topology with benefit-gated retrieval, implementation, and review — runs natively inside OMP with no second orchestration runtime.

</div>

---

## Table of Contents

- [Status](#status)
- [What It Does](#what-it-does)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Durable Task State](#durable-task-state)
- [Commands](#commands)
- [Design Principles](#design-principles)
- [Project Structure](#project-structure)
- [Documentation](#documentation)
- [Provenance](#provenance)
- [Limitations](#limitations)

---

## Status

<!-- round09-12-projection:release-readiness -->

| Component | Status |
|---|---|
| OMP adapter | `IMPLEMENTED_NOT_PROMOTED` — installable, scratch-proven (30 assertions) |
| Claude adapter | `DESIGNED_NOT_VERIFIED` — non-installable, mapping reviewed only |
| Model-assisted campaign | `NOT_RUN` — deterministic evaluator starts zero provider/model processes |
| Promotion verdict | `DEFER_INCONCLUSIVE` — requires separately authorized evidence |

Topics 09 and 10 are closed as executable quality/security delta contracts. Topic 12 has proved the package only in disposable Git projects. It has not installed into a live project or user OMP directory.

---

## What It Does

When you install this template into a project, OMP gains:

| What | Count | Purpose |
|---|---|---|
| **Agents** | 3 | `cheap-scout` (read-only retrieval), `worker` (bounded implementation), `reviewer` (risk-gated review) |
| **Commands** | 3 | `/quick`, `/standard`, `/orchestrated` adapters without a fixed agent chain |
| **Skills** | 3 | Task triage, systematic debugging, completion evidence |
| **State core** | 1 | Local task/candidate/evidence authority shared by Claude and Codex/OMP |
| **Managed boundary** | 1 | Validates Topic 04 packets/results around native OMP `task` |
| **Managed continuity** | 1 | Explicit `/safe-compact` with local recovery and Topic 04-derived kernel |

<!-- topic05-doc:readme -->
Progressive retrieval uses native source tools by default. An optional, default-off CodeGraph component can help with source-fit relationship questions while Cheap Scout remains read-only and the Tech Lead/Reviewer retain decision authority. See [the retrieval guide](docs/retrieval.md).

Plain requests enter the main-session Tech Lead. Inline/no-spawn work is the default. The Tech Lead uses Cheap Scout only when bounded retrieval helps, Worker only when delegation creates a clear benefit, and Reviewer when the risk gate selects independent review. Worker effort is `high` for normal work and Tech-Lead-selected `xhigh` for hard work; Reviewer stays `xhigh`.

Cheap Scout is read-only and fail-soft: DeepSeek Flash at maximum reasoning is primary, DeepSeek Pro at maximum reasoning is its only model fallback, then the Tech Lead performs the needed retrieval. Opus is preferred for review when available, never required. A same-model review runs in a separate session and is disclosed. Parallel writers require safe isolation and disjoint ownership; otherwise execution degrades to one sequential writer.

<!-- topic08-projection:behavior-core -->
The portable behavior core installs a manifest-governed selected roster: three skills, Worker-only completion-evidence autoload, explicit main-session `agent_tasks`, and a fail-closed mutation gate. See [the behavior guide](docs/behavior-core.md).

---

## Quick Start

### Preview installation (safe, no changes)

```powershell
.\scripts\install-template.ps1 -Target project -ProjectDir "D:\Your\Project"
```

### Install for real

```powershell
.\scripts\install-template.ps1 -Target project -ProjectDir "D:\Your\Project" -DryRun:$false
```

### Uninstall

```powershell
.\scripts\uninstall-template.ps1 -ProjectDir "D:\Your\Project" -BackupDir "<printed-backup-path>" -DryRun:$false
```

### Validate

```powershell
.\scripts\validate-template.ps1 -Verbose
# Expected: zero failures; the advisory RULES.md lower-budget warning may remain.
```

---

## Architecture

Policy-derived contracts are delivered directly through commands, agents, `AGENTS.md`, and the advisory validator. Human references live under `docs/policies/`; they are not installed or loaded by OMP.

Topic 06 managed agent calls start through `.omp/bin/omp-managed.ps1`. Bare OMP remains usable but its Vibe/`eval`/internal-agent output is unmanaged and cannot claim a managed receipt. If the boundary is unavailable, the Tech Lead works inline without fabricating a packet or review. See [Managed Agent Boundaries](docs/agent-boundaries.md).

The same managed launcher disables automatic semantic compaction and exposes only argument-free `/safe-compact` after the current persisted OMP session owns exactly one armed task. It saves and verifies local recovery bytes, runs one native soft context-full transaction, then waits for the next normal prompt and injects one authoritative-state-derived kernel. There is no hidden continuation or retry. At pressure, provider dispatch stops; use `/safe-compact` once or make an explicit Topic 04 handoff. Built-in `/compact`, direct `/shake`, snapcompact, remote compaction, and bare OMP are outside this guarantee. See [Context Continuity](docs/context-continuity.md).

All of it runs natively inside OMP — no second orchestration runtime.

---

## Durable Task State

The installed `.omp/state` component is executable support code; operational state stays local and outside Git. Git projects use `<absolute-git-common-dir>/agent-tasks` (plural), so linked worktrees see one repository authority. Non-Git projects use `<project-root>/.agent-tasks`.

Each mutating task has one authority writer and one authoritative worktree. Separate mutating tasks use separate worktrees and scope reservations; Worker output remains provisional until the Tech Lead integrates it and freezes a candidate. A candidate manifest identifies exact scoped bytes—it is not a source backup. Verification and review evidence is accepted only for the exact candidate and acceptance inputs it names.

Claude and Codex/OMP can call the same deterministic PowerShell core explicitly. Automatic lifecycle hooks are deliberately not claimed here; their installed-runtime probe belongs to Topic 08. Installer rollback and normal cleanup preserve operational state. See [`docs/task-state.md`](docs/task-state.md) for commands, recovery, archive, restore, and purge.

Current limits are intentional: state is same-machine and is lost if repository metadata is deleted; direct external edits are detected at lifecycle boundaries rather than intercepted; complete semantic acceptance inputs remain the Tech Lead's responsibility; and leases provide consistency, not protection from another local process that already has filesystem permission.

---

## Commands

| Scenario | Entry |
|---|---|
| Normal request; let the Tech Lead classify it | Plain natural language |
| Explicit narrow/light path | `/quick` |
| Compatibility hint for one integrated lane | `/standard` |
| Structural hint for multiple work units plus integration | `/orchestrated` |

Workflow class alone does not force a spawn or review. The Tech Lead validates the requested shape against the work and risk.

---

## Design Principles

- **OMP-native** — no second runtime layered on top
- **OmniRoute-only** — single model gateway, model roles decoupled from agent definitions
- **Token-aware** — bounded packets plus explicit, authority-preserving `/safe-compact`
- **12-Factor Agents** — agents own their prompts, context, and control flow
- **Evidence before completion** — no task is done until output is verified against the original goal

DeepSeek routing requires external user-owned entries in `~/.omp/agent/models.yml` and valid provider credentials in OmniRoute. Gateway IDs are `ds/...`; OMP selectors are `omniroute/ds/...`. No credential belongs in this repository.

---

## Project Structure

```
template/.omp/        ← the installable OMP config (copy this into your project)
  agents/             ← 3 selected agent definitions
  commands/           ← 3 slash commands
  skills/             ← 3 skill definitions
  schemas/            ← YAML schemas
  AGENTS.md           ← shared context + coding constitution
  RULES.md            ← sticky invariants (always loaded)
  config.yml          ← model role mappings
  state/              ← deterministic state core, schemas, protocol, source manifest
  contracts/          ← managed agent and continuity schemas/core/runtime record
  extensions/         ← trusted task wrapper and final continuity adapter
  bin/                ← managed OMP launcher
scripts/              ← install · validate · benchmark · rollback
docs/                 ← architecture, guides, design report, policy references
registry/             ← upstream provenance, license classification, adoption ledger
evals/                ← evaluation fixtures for regression testing
spec/                 ← specification and key decisions
```

---

## Documentation

| Document | Description |
|---|---|
| [Architecture](docs/architecture.md) | System architecture and execution flow |
| [Installation](docs/installation.md) | Installation guide and prerequisites |
| [Behavior Core](docs/behavior-core.md) | Selected skills, injection, and mutation gate |
| [Agent Boundaries](docs/agent-boundaries.md) | Managed agent call contract and safety |
| [Context Continuity](docs/context-continuity.md) | `/safe-compact`, recovery, and pressure handling |
| [Task State](docs/task-state.md) | Durable state commands, recovery, archive |
| [Retrieval](docs/retrieval.md) | Progressive retrieval and optional CodeGraph |
| [Security](docs/security.md) | Threat model and security boundaries |
| [Rollback](docs/rollback.md) | Uninstall, rollback, and state retention |
| [Customization](docs/customization.md) | Adapting the template to your project |
| [Final Report](docs/final-report.md) | Full design and implementation report |

---

## Provenance

Every adopted mechanism is recorded in [`registry/adoption-ledger.yml`](registry/adoption-ledger.yml) with source repo, license, and rationale. 17 mechanisms were rejected with documented reasons in [`registry/rejected-mechanisms.yml`](registry/rejected-mechanisms.yml).

See [`docs/report-design.md`](docs/report-design.md) for the full design report.

---

## Limitations

> This template has been validated deterministically with zero provider or model calls. Live installation, model-assisted promotion campaigns, and Claude runtime verification have not been performed.

- **OMP 17.2.10** runtime arm is not locally available; static pinned source/evidence remains
- **DeepSeek provider smoke** is environment-blocked by missing credentials; fallback contract remains valid
- **CodeGraph model/provider campaign** is inconclusive/not authorized; native retrieval remains default
- **Live project install** has not been performed; scratch proof is bounded characterization only
- **Operational task state** is local outside Git; expected owner choice, not portability-tested
