<div align="center">

<h1>⚡ omp-custom</h1>

**Production-ready workflow template for [OMP (Oh My Pi)](https://github.com/can1357/oh-my-pi)**

<sub><i>Three-agent topology with benefit-gated retrieval, bounded implementation, and risk-gated review —<br/>
runs natively inside OMP, with no second orchestration runtime.</i></sub>

<br/>

<p>
<img src="https://img.shields.io/badge/status-IMPLEMENTED__NOT__PROMOTED-F59E0B?style=for-the-badge&labelColor=1F2328" alt="Status" />
<img src="https://img.shields.io/badge/OMP-17.2.12-6E56CF?style=for-the-badge&labelColor=1F2328" alt="OMP version" />
<img src="https://img.shields.io/badge/PowerShell-7.4%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white&labelColor=1F2328" alt="PowerShell 7.4+" />
<img src="https://img.shields.io/badge/gateway-OmniRoute_only-06B6D4?style=for-the-badge&labelColor=1F2328" alt="OmniRoute only" />
<img src="https://img.shields.io/badge/provider_calls-0-2EA043?style=for-the-badge&labelColor=1F2328" alt="Zero provider calls" />
</p>

<b>3</b> agents &nbsp;·&nbsp; <b>3</b> commands &nbsp;·&nbsp; <b>3</b> skills &nbsp;·&nbsp; <b>1</b> state core &nbsp;·&nbsp; <b>1</b> managed boundary &nbsp;·&nbsp; <b>1</b> managed continuity

</div>

---

## 📑 Table of Contents

| | | |
|---|---|---|
| [📊 Status](#-status) | [💾 Durable Task State](#-durable-task-state) | [📚 Documentation](#-documentation) |
| [🧩 What It Ships](#-what-it-ships) | [🧭 Commands](#-commands) | [🧾 Provenance](#-provenance) |
| [🚀 Quick Start](#-quick-start) | [🎯 Design Principles](#-design-principles) | [🚧 Limitations](#-limitations) |
| [🧱 Architecture](#-architecture) | [🌳 Project Structure](#-project-structure) | |

---

## 📊 Status

<!-- round09-12-projection:release-readiness -->

| | Component | Status |
|---|---|---|
| 🟢 | **OMP adapter** | `IMPLEMENTED_NOT_PROMOTED` — installable, scratch-proven (30 assertions) |
| 🟡 | **Claude adapter** | `DESIGNED_NOT_VERIFIED` — non-installable, mapping reviewed only |
| ⚪ | **Model-assisted campaign** | `NOT_RUN` — the deterministic evaluator starts zero provider/model processes |
| 🔵 | **Promotion verdict** | `DEFER_INCONCLUSIVE` — requires separately authorized evidence |

> **Scope.** Topics 09 and 10 are closed as executable quality/security delta contracts. Topic 12 has
> proved the package only in disposable Git projects — it has **not** installed into a live project or
> user OMP directory.

---

## 🧩 What It Ships

Installing this template into a project gives OMP:

| | Component | Count | Purpose |
|---|---|:---:|---|
| 🤖 | **Agents** | 3 | `cheap-scout` (read-only retrieval) · `worker` (bounded implementation) · `reviewer` (risk-gated review) |
| ⌨️ | **Commands** | 3 | `/quick` · `/standard` · `/orchestrated` — adapters without a fixed agent chain |
| 🧠 | **Skills** | 3 | Task triage · systematic debugging · completion evidence |
| 💾 | **State core** | 1 | Local task/candidate/evidence authority shared by Claude and Codex/OMP |
| 🛡️ | **Managed boundary** | 1 | Validates Topic 04 packets/results around native OMP `task` |
| 🧵 | **Managed continuity** | 1 | Explicit `/safe-compact` with local recovery and a Topic 04-derived kernel |

### 🔍 Retrieval

<!-- topic05-doc:readme -->
Progressive retrieval uses native source tools by default. An optional, default-off CodeGraph
component can help with source-fit relationship questions while Cheap Scout stays read-only and the
Tech Lead/Reviewer retain decision authority. → [Retrieval guide](docs/retrieval.md)

### 🧭 Routing behaviour

Plain requests enter the main-session Tech Lead, and inline/no-spawn work is the default. The Tech
Lead uses Cheap Scout only when bounded retrieval helps, Worker only when delegation creates a clear
benefit, and Reviewer when the risk gate selects independent review. Worker effort is `high` for
normal work and Tech-Lead-selected `xhigh` for hard work; Reviewer stays `xhigh`.

Cheap Scout is read-only and fail-soft: DeepSeek Flash at maximum reasoning is primary, DeepSeek Pro
at maximum reasoning is its only model fallback, then the Tech Lead performs the needed retrieval.
Opus is preferred for review when available, never required. A same-model review runs in a separate
session and is disclosed. Parallel writers require safe isolation and disjoint ownership; otherwise
execution degrades to one sequential writer.

### 🧬 Behavior core

<!-- topic08-projection:behavior-core -->
The portable behavior core installs a manifest-governed selected roster: three skills, Worker-only
completion-evidence autoload, explicit main-session `agent_tasks`, and a fail-closed mutation gate.
→ [Behavior guide](docs/behavior-core.md)

---

## 🚀 Quick Start

**1️⃣ Preview the installation** — safe, changes nothing:

```powershell
.\scripts\install-template.ps1 -Target project -ProjectDir "D:\Your\Project"
```

**2️⃣ Install for real:**

```powershell
.\scripts\install-template.ps1 -Target project -ProjectDir "D:\Your\Project" -DryRun:$false
```

**3️⃣ Validate:**

```powershell
.\scripts\validate-template.ps1 -Verbose
# Expected: zero failures. The advisory RULES.md lower-budget warning may remain.
```

**↩️ Uninstall:**

```powershell
.\scripts\uninstall-template.ps1 -ProjectDir "D:\Your\Project" -BackupDir "<printed-backup-path>" -DryRun:$false
```

> 🔑 DeepSeek routing needs external, user-owned entries in `~/.omp/agent/models.yml` plus valid
> OmniRoute provider credentials. Gateway IDs are `ds/...`; OMP selectors are `omniroute/ds/...`.
> **No credential belongs in this repository.**

---

## 🧱 Architecture

Policy-derived contracts are delivered directly through commands, agents, `AGENTS.md`, and the
advisory validator. Human references live under `docs/policies/`; they are not installed and OMP
never loads them.

**🛡️ Managed boundary.** Topic 06 managed agent calls start through `.omp/bin/omp-managed.ps1`. Bare
OMP remains usable, but its Vibe/`eval`/internal-agent output is unmanaged and cannot claim a managed
receipt. If the boundary is unavailable, the Tech Lead works inline without fabricating a packet or a
review. → [Managed Agent Boundaries](docs/agent-boundaries.md)

**🧵 Managed continuity.** The same launcher disables automatic semantic compaction and exposes only
argument-free `/safe-compact`, and only after the current persisted OMP session owns exactly one
armed task. It saves and verifies local recovery bytes, runs one native soft context-full
transaction, then waits for the next normal prompt and injects one authoritative-state-derived
kernel. There is no hidden continuation and no retry. At pressure, provider dispatch stops: use
`/safe-compact` once, or make an explicit Topic 04 handoff. Built-in `/compact`, direct `/shake`,
snapcompact, remote compaction, and bare OMP are all outside this guarantee.
→ [Context Continuity](docs/context-continuity.md)

> ✅ All of it runs natively inside OMP — no second orchestration runtime.

---

## 💾 Durable Task State

The installed `.omp/state` component is executable support code; operational state stays local and
outside Git.

| | Environment | Authority location |
|---|---|---|
| 🌿 | Git projects | `<absolute-git-common-dir>/agent-tasks` (plural) — linked worktrees see one repository authority |
| 📁 | Non-Git projects | `<project-root>/.agent-tasks` |

Each mutating task has one authority writer and one authoritative worktree. Separate mutating tasks
use separate worktrees and scope reservations; Worker output stays provisional until the Tech Lead
integrates it and freezes a candidate. A candidate manifest identifies exact scoped bytes — it is
**not a source backup**. Verification and review evidence is accepted only for the exact candidate
and acceptance inputs it names.

Claude and Codex/OMP can call the same deterministic PowerShell core explicitly. Automatic lifecycle
hooks are deliberately not claimed here; their installed-runtime probe belongs to Topic 08. Installer
rollback and normal cleanup preserve operational state.
→ [Task State](docs/task-state.md) for commands, recovery, archive, restore, and purge.

> ⚠️ **Intentional limits.** State is same-machine and is lost if repository metadata is deleted.
> Direct external edits are detected at lifecycle boundaries rather than intercepted. Complete
> semantic acceptance inputs remain the Tech Lead's responsibility. Leases give consistency, not
> protection from another local process that already holds filesystem permission.

---

## 🧭 Commands

| | Scenario | Entry |
|---|---|---|
| 💬 | Normal request; let the Tech Lead classify it | *plain natural language* |
| ⚡ | Explicit narrow/light path | `/quick` |
| 🔗 | Compatibility hint for one integrated lane | `/standard` |
| 🏗️ | Structural hint for multiple work units plus integration | `/orchestrated` |

> Workflow class alone never forces a spawn or a review. The Tech Lead validates the requested shape
> against the actual work and risk.

---

## 🎯 Design Principles

- 🧩 **OMP-native** — no second runtime layered on top
- 🛣️ **OmniRoute-only** — a single model gateway, with model roles decoupled from agent definitions
- 🪙 **Token-aware** — bounded packets plus explicit, authority-preserving `/safe-compact`
- 📐 **12-Factor Agents** — agents own their prompts, context, and control flow
- ✅ **Evidence before completion** — nothing is done until output is verified against the original goal

---

## 🌳 Project Structure

```
omp-custom/
├── template/.omp/          ← the installable OMP config (copy this into your project)
│   ├── agents/             ← 3 selected agent definitions
│   ├── commands/           ← 3 slash commands
│   ├── skills/             ← 3 skill definitions
│   ├── schemas/            ← YAML schemas
│   ├── state/              ← deterministic state core, schemas, protocol, source manifest
│   ├── contracts/          ← managed agent + continuity schemas, core, runtime record
│   ├── extensions/         ← trusted task wrapper and final continuity adapter
│   ├── bin/                ← managed OMP launcher
│   ├── AGENTS.md           ← shared context + coding constitution
│   ├── RULES.md            ← sticky invariants (always loaded)
│   └── config.yml          ← model role mappings
├── scripts/                ← install · validate · benchmark · rollback
├── docs/                   ← architecture, guides, design report, policy references
├── registry/               ← upstream provenance, license classification, adoption ledger
├── evals/                  ← evaluation fixtures for regression testing
└── spec/                   ← specification and key decisions
```

---

## 📚 Documentation

| | Document | Description |
|---|---|---|
| 🧱 | [`docs/architecture.md`](docs/architecture.md) | System architecture and execution flow |
| 📦 | [`docs/installation.md`](docs/installation.md) | Installation guide and prerequisites |
| 🧬 | [`docs/behavior-core.md`](docs/behavior-core.md) | Selected skills, injection, and the mutation gate |
| 🛡️ | [`docs/agent-boundaries.md`](docs/agent-boundaries.md) | Managed agent call contract and safety |
| 🧵 | [`docs/context-continuity.md`](docs/context-continuity.md) | `/safe-compact`, recovery, and pressure handling |
| 💾 | [`docs/task-state.md`](docs/task-state.md) | Durable state commands, recovery, archive |
| 🔍 | [`docs/retrieval.md`](docs/retrieval.md) | Progressive retrieval and optional CodeGraph |
| 🔐 | [`docs/security.md`](docs/security.md) | Threat model and security boundaries |
| ↩️ | [`docs/rollback.md`](docs/rollback.md) | Uninstall, rollback, and state retention |
| 🎨 | [`docs/customization.md`](docs/customization.md) | Adapting the template to your project |
| 📄 | [`docs/final-report.md`](docs/final-report.md) | Full design and implementation report |

---

## 🧾 Provenance

Every adopted mechanism is recorded in
[`registry/adoption-ledger.yml`](registry/adoption-ledger.yml) with its source repo, license, and
rationale. **17** mechanisms were rejected, each with a documented reason, in
[`registry/rejected-mechanisms.yml`](registry/rejected-mechanisms.yml).

See [`docs/report-design.md`](docs/report-design.md) for the full design report.

---

## 🚧 Limitations

> This template has been validated **deterministically, with zero provider or model calls**. Live
> installation, model-assisted promotion campaigns, and Claude runtime verification have not been
> performed.

| | Area | State |
|---|---|---|
| 🧪 | **OMP 17.2.10** | runtime arm is not locally available; static pinned source/evidence remains |
| 🔑 | **DeepSeek provider smoke** | environment-blocked by missing credentials; the fallback contract remains valid |
| 📉 | **CodeGraph model/provider campaign** | inconclusive / not authorized; native retrieval stays the default |
| 🏗️ | **Live project install** | not performed; the scratch proof is bounded characterization only |
| 📁 | **Operational task state** | local, outside Git — an expected owner choice, not portability-tested |

<div align="center">

<br/>

**Built for [OMP (Oh My Pi)](https://github.com/can1357/oh-my-pi)** · [Architecture](docs/architecture.md) · [Installation](docs/installation.md) · [Security](docs/security.md)

</div>
