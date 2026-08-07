# 12 — Installation and Rollback

> OPUS PROPOSED SPEC v1 | Source-verified against `scripts/install-template.ps1`.

---

## A. Verified Defects in the Current Installer

### D-1 (P0) — `workflows` component alias resolves to nothing

```powershell
$Components = @("agents", "workflows", "skills", ...)   # default
$component_map = @{ "workflows" = "workflows" }         # maps to workflows/
```

`template/.omp/workflows/` **does not exist**; the real folder is `template/.omp/commands/`.
The `default` switch branch does `if (Test-Path $src_dir)` — false — so the branch
silently contributes zero files.

**Consequence**: a default install copies agents, skills, schemas, policies, AGENTS.md,
RULES.md, config.yml — **but not one slash command**. The three workflows that are the
entire point of the template are missing, and the installer reports success.

**Fix**: rename the alias to `commands`, keep `workflows` as a deprecated input alias
that maps to the `commands` folder.

---

### D-2 (P0) — `config.yml` is unprotected and destroys the live global baseline

```powershell
$protected = @("models.yml", "agent.db", "agent.db-shm", "agent.db-wal", "sessions")
```

`config.yml` is absent from this list. With `-Target user`, the destination is
`~/.omp/agent/config.yml` — the user's live global config holding the entire frozen
baseline (`tools.approvalMode`, `retry.*`, `task.*`, `edit.*`, `compaction.*`,
`lsp.*`, `memory.backend`, …).

The template's `config.yml` contains **only** a `modelRoles:` block. `Copy-Item -Force`
replaces the file wholesale, so every baseline setting is erased and silently reverts to
OMP defaults — including `approvalMode` dropping from `yolo` and `compaction.strategy`
losing `shake`.

A timestamped backup is taken first, so this is recoverable, but only if the user
notices. The plan explicitly requires "preserves models.yml and credentials"; the same
protection must extend to `config.yml`.

**Fix**: two changes, both required.
1. Add `config.yml` to `$protected`.
2. Replace whole-file copy with a **merge** that writes only the `modelRoles` keys the
   template owns, preserving every other key and the file's comments.

---

### D-3 (P1) — `$Force` is declared but never used

```powershell
[switch]$Force   # declared
Copy-Item $item.src $item.dst -Force   # unconditional -Force regardless
```

The parameter implies opt-in overwrite protection that does not exist. Every existing
file is overwritten whether or not `-Force` is passed.

**Fix**: without `-Force`, skip files that exist and differ, listing them as conflicts.
With `-Force`, overwrite.

---

### D-4 (P1) — README documents parameters the script does not accept

| README / docs | Script signature |
|---|---|
| `-TargetDir "D:\Your\Project"` | `-ProjectDir` (no `-TargetDir` parameter) |
| `.\scripts\uninstall-template.ps1 -TargetDir ...` | `-BackupDir` is **mandatory** |

`README.md` lines 27–36 and `docs/report-design.md` lines 186–192 use `-TargetDir`,
which does not exist. PowerShell fails on the unknown parameter, so the documented
command cannot run. The documented uninstall omits the mandatory `-BackupDir`, so it
prompts or fails.

`docs/installation.md` uses the correct `-Target project -ProjectDir ...` form, so the
documentation contradicts itself.

**Fix**: make `-TargetDir` a real alias of `-ProjectDir`, and correct README and
`report-design.md` to pass `-BackupDir` for rollback.

---

### D-5 (P2) — Substring protection matching is over-broad

```powershell
$protected | Where-Object { $dst_rel -like "*$_*" }
```

`sessions` matches any path containing that substring — e.g. a legitimate
`skills/manage-sessions/SKILL.md` would be silently skipped as "protected".

**Fix**: match on exact relative path or first path segment, not substring.

---

### D-6 (P2) — No installation manifest

The plan requires "produces an installation manifest". The installer prints a plan and
creates a backup but writes no machine-readable record of what it installed, so
uninstall cannot do a targeted revert — only a wholesale backup restore.

**Fix**: write `.omp/.omp-template-manifest.json` recording template version, install
timestamp, target, components, per-file relative path + SHA-256, and backup path.

---

## B. Required Installer Contract

```
install-template.ps1
  -Target        project | user           (default: project)
  -ProjectDir    <path>                   (alias: -TargetDir)
  -Components    commands,agents,skills,docs,agents-md,rules-md,config
  -DryRun        (default: TRUE)
  -Force         (actually honored)
```

Ordered behavior:

1. **Detect** target `.omp` directory; for `user`, resolve `~/.omp/agent`.
2. **Validate** the template first — refuse to install if `validate-template.ps1` fails.
3. **Plan** — classify every file CREATE / OVERWRITE / MERGE / SKIP(protected) / CONFLICT.
4. **Dry-run by default** — print the plan and exit 0 without touching disk.
5. **Backup** — timestamped copy of the entire destination before any write.
6. **Apply** — copy files; merge `config.yml`; never touch protected paths.
7. **Manifest** — write the JSON record described in D-6.
8. **Post-validate** — confirm OMP discovers the installed components (§13 Level 1).

Protected paths, never written: `models.yml`, `config.yml` (merge only), `agent.db*`,
`sessions/`, `auth.json`, any `.env`.

---

## C. `config.yml` Merge Rule

The template owns exactly one key: `modelRoles`, and within it only the five role names
it defines. Merge semantics:

- Destination file absent → write the template file verbatim.
- Destination present, no `modelRoles` → append the block, preserve everything else.
- Destination present with `modelRoles` → add only missing role keys; **never** modify
  a role the user already set; never touch keys outside `modelRoles`.
- Always preserve unrelated keys and, where practical, comments.

A destructive whole-file replacement of `config.yml` is prohibited in every mode.

---

## D. Rollback Contract

```
uninstall-template.ps1
  -BackupDir <path>     (mandatory — printed by install)
  -Manifest  <path>     (optional — enables targeted revert)
  -Target / -ProjectDir (must match the original install)
  -DryRun               (default: TRUE)
```

Two modes:

- **Backup restore** (available today): restore the whole destination from the backup.
  Simple and reliable, but also reverts unrelated changes made after install.
- **Manifest revert** (to add): delete only files the manifest recorded as CREATE and
  restore only those recorded as OVERWRITE/MERGE, verifying SHA-256 first. Files the
  user modified after install are reported, not clobbered.

Rollback must be dry-run by default and must never delete a file absent from the manifest.

---

## E. Live-OMP Safety Gate

`-Target user` writes into the live OMP home, which the plan places behind explicit
approval. The installer must therefore:

1. Refuse `-Target user` unless `-IAcceptLiveInstall` is also passed.
2. Print the resolved destination and full diff before applying.
3. Confirm the backup succeeded before the first write.
4. Never write `models.yml`, credentials, or session databases.
5. Merge — never replace — `config.yml`.

---

## F. Acceptance Criteria

| # | Criterion |
|---|---|
| AC-1 | Default install copies all three slash commands into `commands/` |
| AC-2 | `config.yml` is merged, never replaced; baseline keys survive a user-target install |
| AC-3 | `-Force` absent + existing differing file → reported CONFLICT, not overwritten |
| AC-4 | Every documented command in README and docs runs without a parameter error |
| AC-5 | Protected-path matching does not skip legitimately named template files |
| AC-6 | A manifest is written and supports targeted revert |
| AC-7 | Dry-run is the default in both install and uninstall, and writes nothing |
| AC-8 | `-Target user` requires an explicit acceptance flag |
| AC-9 | Post-install validation confirms OMP discovery of commands, agents, and skills |
