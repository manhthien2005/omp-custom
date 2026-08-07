# Rollback Guide

## When to roll back

- The installed template causes unexpected OMP behavior
- An agent definition conflicts with an existing project agent
- Token budget is exceeded and performance degraded
- A skill triggers incorrectly and affects unrelated tasks

## Rollback procedure

### Step 1 — Find your backup

The installer creates a timestamped backup before every install:

```powershell
# List backups for user-level install
Get-ChildItem "$env:USERPROFILE\.omp" -Filter "agent.backup-*" | Sort-Object Name

# List backups for project-level install
Get-ChildItem "C:\path\to\project\.omp" -Filter ".backup-*" | Sort-Object Name
```

### Step 2 — Preview the rollback (dry-run)

```powershell
.\scripts\uninstall-template.ps1 `
    -BackupDir "$env:USERPROFILE\.omp\agent.backup-20260807-120000" `
    -Target user
```

Review the output. When ready:

### Step 3 — Apply the rollback

```powershell
.\scripts\uninstall-template.ps1 `
    -BackupDir "$env:USERPROFILE\.omp\agent.backup-20260807-120000" `
    -Target user `
    -DryRun:$false
```

The script:
1. Creates a pre-rollback snapshot of the current state
2. Removes the current `.omp/agent/` directory
3. Restores the backup

### Step 4 — Verify

```powershell
omp --version
# Confirm OMP starts normally
```

## Partial rollback (selective removal)

If only specific components need to be removed:

```powershell
# Remove installed agents
Remove-Item ".omp\agents\tech-lead.md" -Force
Remove-Item ".omp\agents\explorer.md" -Force
# etc.

# Re-run validation
.\scripts\validate-template.ps1
```

## Safety guarantees

- `models.yml` and credential files are never touched by the installer or uninstaller
- The backup includes all files present before install, including non-template files
- The pre-rollback snapshot preserves the post-install state so rollback itself can be undone

## If the backup is lost

If the backup directory was deleted:

1. Remove the template files manually (compare against `template/.omp/` to identify which files were installed)
2. OMP's default behavior is restored once template files are removed
3. No live OMP agent database files are modified by the template
