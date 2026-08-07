# Installation Guide

## Prerequisites

- OMP 17.2.10 or later (`omp --version`)
- OmniRoute running at `http://127.0.0.1:20128`
- Git and PowerShell 5.1+
- Windows (scripts use PowerShell; adapt for other platforms as needed)

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
# Install only agents and skills (not policies or schemas)
.\scripts\install-template.ps1 -Target project `
    -ProjectDir "C:\path\to\project" `
    -Components agents, skills `
    -DryRun:$false
```

Available components: `agents`, `workflows`, `skills`, `schemas`, `policies`, `agents-md`, `rules-md`, `config`

## User-level install

Install to `~/.omp/agent/` (applies to all projects):

```powershell
.\scripts\install-template.ps1 -Target user -DryRun:$false
```

⚠️ User-level install affects ALL your OMP sessions. Review carefully.

## After installing

1. Edit `template/.omp/AGENTS.md` — fill in the **Project** section with your project's build commands, architecture notes, and conventions.
2. Edit `template/.omp/config.yml` — update `modelRoles` if you want different models for different agents.
3. Run `.\scripts\validate-template.ps1` to confirm the installation is clean.

## Customization

See `docs/customization.md` for project-level customization.

## Rollback

```powershell
.\scripts\uninstall-template.ps1 -BackupDir "C:\Users\..\.omp\agent.backup-20260807-120000" -DryRun:$false
```

The backup directory path is printed by `install-template.ps1` after a successful install.
