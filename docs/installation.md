# Installation Guide

<!-- round09-12-projection:release-readiness -->
## Round 09–12 installation status

The complete selected package has been exercised model-free against local OMP 17.2.12 in
disposable Git projects. The proof covered exact agent/skill discovery, component `2.1.0`, repair
of an owned-byte drift, manifest-bound uninstall, and rollback while retaining user-owned
models/session/`.agent-tasks` state. Evaluation tooling was not copied into installed `.omp`.

This is scratch evidence, not authority for a live installation. OMP remains
`IMPLEMENTED_NOT_PROMOTED`; OMP 17.2.10 is not locally verified, and Claude remains non-installable
`DESIGNED_NOT_VERIFIED`. Continue using the dry-run/apply flow below only after separately choosing
the real target. A future model-assisted evaluation is also separate from installation:

```powershell
# Only after explicit provider and budget approval; output remains local and Git-ignored.
$omp = (Get-Command omp.exe).Source
pwsh -NoLogo -NoProfile -File scripts/run-round09-12-evaluation.ps1 -Mode Campaign `
  -OutputDirectory evals/results/authorized-campaign-001 -OmpPath $omp `
  -AllowProviderCalls -EvidenceBudget <approved-budget>
```

The campaign boundary cannot itself promote a synthetic, pilot-only, or unreconciled result.

<!-- topic08-projection:behavior-core -->
The default `agent-boundary` component now includes the OMP behavior adapter and depends on the
three selected skills. Before staging, installation checks the generated lock and refuses a
missing, shadowed, or hash-drifted skill. No Claude runtime files are installed. Operational
`agent-tasks` state remains outside the installed component.

<!-- topic05-doc:installation -->
CodeGraph is not in the default component list. To enable it, include `state,codegraph` explicitly
and provide either `-CodeGraphArtifactPath <pinned-archive>` or
`-AllowCodeGraphDownload` (never both). Run dry-run first. The installer verifies the pinned
v1.5.0 artifact before target mutation. See [`retrieval.md`](retrieval.md) for retained-data and
cleanup behavior.

## Prerequisites

- OMP 17.2.10 or 17.2.12 for the default managed boundary (`omp --version`)
- OmniRoute running at `http://127.0.0.1:20128`
- Git and Windows PowerShell 5.1+ for the outer installer entry
- `pwsh` 7.4+ for the default `state` and `agent-boundary` components
- Windows (scripts use PowerShell; adapt for other platforms as needed)

For Cheap Scout, OmniRoute must advertise the gateway IDs `ds/deepseek-v4-flash` and
`ds/deepseek-v4-pro`. OMP uses the full selectors `omniroute/ds/deepseek-v4-flash:xhigh` and
`omniroute/ds/deepseek-v4-pro:xhigh`; these are not interchangeable names. Add both models to the
external user-owned `~/.omp/agent/models.yml` catalog and configure DeepSeek credentials in
OmniRoute. Do not store a key in this repository.

If DeepSeek credentials are unavailable, installation and local static validation still work.
Cheap Scout provider calls remain environment-blocked and retrieval falls back to the main-session
Tech Lead.

## Quick install (project-level)

```powershell
# 1. Clone this template repository
git clone https://github.com/your-org/omp-workflow-template.git
cd omp-workflow-template

# 2. Preview what will be installed (dry-run, no changes)
.\scripts\install-template.ps1 -Target project -ProjectDir "C:\path\to\your\project"

# 3. Review the output. When ready:
.\scripts\install-template.ps1 -Target project -ProjectDir "C:\path\to\your\project" -DryRun:$false

# 4. Validate the installed template
.\scripts\validate-template.ps1
```

## Selective install

Install only specific components:

```powershell
# Install only agents and skills (unmanaged; no Topic 06 receipt)
.\scripts\install-template.ps1 -Target project `
    -ProjectDir "C:\path\to\project" `
    -Components agents, skills `
    -DryRun:$false
```

Available components: `agents`, `workflows`, `skills`, `state`, `agents-md`, `rules-md`, `config`,
`agent-boundary`, and optional `codegraph`. `state` and `agent-boundary` are installed by default.
A state-only install copies executable files under
`.omp/state`; it never reads, writes, migrates, or deletes operational `agent-tasks` data.

## User-level install

Install to `~/.omp/agent/` (applies to all projects):

```powershell
.\scripts\install-template.ps1 -Target user -DryRun:$false
```

⚠️ User-level install affects ALL your OMP sessions. Review carefully.

User installation intentionally omits `task.enableEffort` and `task.maxEffort` unless you opt in:

```powershell
.\scripts\install-template.ps1 -Target user -EnablePerSpawnEffort -DryRun:$false
```

## After installing

1. Edit `<project>/.omp/AGENTS.md` — fill in the **Project** section with build commands, architecture notes, and conventions.
2. Review `<project>/.omp/config.yml` and confirm the external model catalog resolves every selected alias.
3. Run `.\scripts\validate-template.ps1` to confirm the installation is clean.
4. Read `<project>/.omp/state/PROTOCOL.md`. Durable operational state is local at
   `<git-common-dir>/agent-tasks` (or pre-Git `<project>/.agent-tasks`) and is not stored inside the
   installed `.omp/state` component.

Plain requests enter the main-session Tech Lead and default to inline/no-spawn work. Cheap Scout
is optional read-only retrieval; Worker is benefit-gated at `high` or Tech-Lead-selected `xhigh`;
Reviewer is risk-gated and always `xhigh`. Opus is preferred for review when available, never a
requirement. If review uses the same model, it runs in a separate session and that limitation is
disclosed. Parallel writers require safe isolation and disjoint ownership; otherwise execution is
sequential.

For managed dispatch, start OMP from the target project with:

```powershell
pwsh -NoProfile -File .omp/bin/omp-managed.ps1
```

The default install includes `agent-boundary` and validates its dependencies, hashes, selected
agents/config, supported OMP version, wrapper load, and `task.softRequestBudget: 200` overlay.
Bare `omp` is intentionally unmanaged. See [`agent-boundaries.md`](agent-boundaries.md).

That component also includes Topic 07 continuity schema/core/client and the final
`context-continuity.js` extension. The managed launcher validates OMP 17.2.10 or 17.2.12, loads the
continuity adapter last, and reasserts the exact disabled automatic-compaction profile at runtime.
After the current persisted OMP session creates/owns one classified Topic 04 task, use
argument-free `/safe-compact`; do not use focus text, built-in `/compact`, or `/shake`.

Validate the local implementation with:

```powershell
pwsh -NoProfile -File scripts/validate-topic07-context-continuity.ps1
```

Promotion requires the local stop-before-provider canary on both supported OMP versions. Missing
17.2.10 is reported as `OPEN-T07-RUNTIME-02` / `IMPLEMENTED_NOT_PROMOTED`; installation must not
download or downgrade it. This gate is unrelated to OmniRoute models and does not require Opus.
See [`context-continuity.md`](context-continuity.md).

## Customization

See `docs/customization.md` for project-level customization.

## Rollback

```powershell
.\scripts\uninstall-template.ps1 -BackupDir "C:\Users\..\.omp\agent.backup-20260807-120000" -DryRun:$false
```

The backup directory path is printed by `install-template.ps1` after a successful install.
Rollback restores installed `.omp/state` executable bytes but retains operational `agent-tasks`
authority. See [`task-state.md`](task-state.md) for lifecycle, migration, and cleanup boundaries.
