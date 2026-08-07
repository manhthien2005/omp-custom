# omp-custom

> Production-ready workflow template for [OMP (Oh My Pi)](https://github.com/oh-my-pi/oh-my-pi) — adds multi-agent coordination, structured quality gates, and evidence-backed code review to any OMP project.

---

## What it does

When you install this template into a project, OMP gains:

| What | How many | Purpose |
|---|---|---|
| **Agents** | 5 | Specialized roles: coordinator, investigator, implementer, verifier, reviewer |
| **Commands** | 3 | `/quick` (5 steps), `/standard` (8 steps), `/orchestrated` (full delegation) |
| **Skills** | 3 | Task triage, systematic debugging, completion evidence |
| **Schemas** | 4 | Typed structured outputs for every agent |
| **Policies** | 5 | Token budgets, model routing, quality gates, escalation rules |

All of it runs natively inside OMP — no extra runtime, no extra dependencies.

---

## How to install

```powershell
# Preview what will be copied (safe, no changes)
.\scripts\install-template.ps1 -DryRun

# Install for real (backs up your existing .omp/ first)
.\scripts\install-template.ps1 -TargetDir "D:\Your\Project"
```

To undo:

```powershell
.\scripts\uninstall-template.ps1 -TargetDir "D:\Your\Project"
```

---

## How to validate

```powershell
.\scripts\validate-template.ps1 -Verbose
# Expected: 63 passed · 0 warnings · 0 failures
```

---

## Project layout

```
template/.omp/        ← the installable OMP config (copy this into your project)
  agents/             ← 5 agent definitions
  commands/           ← 3 slash commands
  skills/             ← 3 skill definitions
  schemas/            ← 4 YAML schemas
  policies/           ← 5 policy files
  AGENTS.md           ← shared context + coding constitution
  RULES.md            ← 8 sticky invariants (always loaded)
  config.yml          ← model role mappings

scripts/              ← install · validate · benchmark · rollback
docs/                 ← architecture, installation guide, design report
registry/             ← upstream provenance, license classification, adoption ledger
evals/                ← evaluation fixtures for regression testing
```

---

## Choosing a command

| Scenario | Command |
|---|---|
| Quick fix, clear requirement | `/quick` |
| Normal feature or bug | `/standard` |
| Complex, multi-file, needs full review | `/orchestrated` |

Not sure? Run `/quick task-triage` first — the triage skill picks the right command for you.

---

## Design principles

- **OMP-native** — no second runtime layered on top
- **OmniRoute-only** — single model gateway, model roles decoupled from agent definitions
- **Token-aware** — every file has a measured budget; shake compaction configured
- **12-Factor Agents** — agents own their prompts, context, and control flow
- **Evidence before completion** — no task is done until output is verified against the original goal

---

## Provenance

Every adopted mechanism is recorded in [`registry/adoption-ledger.yml`](registry/adoption-ledger.yml) with source repo, license, and rationale. 17 mechanisms were rejected with documented reasons in [`registry/rejected-mechanisms.yml`](registry/rejected-mechanisms.yml).

See [`docs/report-design.md`](docs/report-design.md) for the full design report.
