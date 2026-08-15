# Rollback Guide

<!-- round09-12-projection:release-readiness -->
## Round 09–12 rollback evidence

The release-readiness proof installed only into disposable Git projects. Using the exact backup
recorded by `contracts/install-record.json`, `scripts/uninstall-template.ps1` restored the original
`.omp` bytes and retained protected models, sessions, and operational `.agent-tasks` state. Repair
mode separately restored a deliberately drifted template-owned byte to its manifest hash.

No live OMP target was changed, so this round requires no live rollback. Evaluation fixtures and
bounded evidence are repository files; local campaign output is ignored under `evals/results/`
and is never installed. OMP remains `IMPLEMENTED_NOT_PROMOTED`; Claude remains non-installable
`DESIGNED_NOT_VERIFIED`.

<!-- topic08-projection:behavior-core -->
Topic 08 behavior schema, core, manifest, and OMP hook are part of the same manifest-coupled
`agent-boundary` component. Rollback restores their attributable bytes from the local snapshot;
it does not delete or rewrite operational `agent-tasks`/`.agent-tasks` authority.

<!-- topic05-doc:rollback -->
Uninstall restores template-owned CodeGraph files but intentionally retains the exact known managed
bundle and each worktree's `.codegraph` index. Use `scripts/cleanup-codegraph.ps1` as a dry run,
inspect the resolved exact bundle/index target, then apply explicitly. Cleanup never searches
unknown caches or creates/deletes/prunes Git worktrees.

> Frozen Phase 00 runtime guide; role and file examples describe the installed baseline only
> and do not select the Topic 03 topology or authorize runtime migration. Phase 02 performs
> runtime migration only after Topic 03 selects the manifest.
>
> **Current Topic 06 rule:** the uninstaller validates the boundary install record and restores
> the backup transactionally. It retains Topic 04 operational `agent-tasks` state. Historical
> manual agent-removal examples below are not a supported partial boundary rollback.
>
> **Current Topic 07 rule:** continuity files are part of the same manifest-coupled
> `agent-boundary` component. Rollback restores/removes only attributable installed bytes and does
> not delete Topic 04 authority, OMP session files, or already written recovery artifacts.

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
3. Restores the backup and then restores protected model, credential, database, and session files
   from the pre-rollback snapshot
4. Retains operational `<git-common-dir>/agent-tasks` or `<project>/.agent-tasks` authority

### Step 4 — Verify

```powershell
omp --version
# Confirm OMP starts normally
```

## Partial rollback

Do not manually remove one selected agent, wrapper, contract file, or overlay from an installed
managed boundary. Those bytes are one manifest-coupled component. Use the dry-run uninstaller and
the exact backup it names; then apply the full restore. User-modified boundary files are reported
as conflicts and preserved rather than silently deleted.

## Safety guarantees

- `models.yml` and credential files are never touched by the installer or uninstaller
- The backup includes all files present before install, including non-template files
- The pre-rollback snapshot preserves the post-install state so rollback itself can be undone
- `.omp/state` is executable template content; operational `agent-tasks` state is outside `.omp`
  and is retained by install, reinstall, and rollback
- Topic 06 component hashes and install-record identity are checked before boundary removal;
  `.omp/bin/omp-managed.ps1` is removed/restored only as part of that attributable transaction
- Topic 07 continuity schema/core/client/extension are restored with that same transaction;
  rollback disables the managed guarantee but never rewrites task authority or session history

After rollback, start through the restored managed launcher and re-run the Topic 07 validator if
continuity remains installed. Bare OMP or a partial/manual removal cannot claim `/safe-compact`
protection. Retained recovery artifacts are local context only and may be cleaned later through the
normal OMP/session retention policy; they must not be treated as Topic 04 authority.

## If the backup is lost

If the backup directory was deleted:

1. Remove the template files manually (compare against `template/.omp/` to identify which files were installed)
2. OMP's default behavior is restored once template files are removed
3. No live OMP agent database files are modified by the template
