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
2. Replace whole-file copy with a **merge** that writes only the keys the template owns
   (see §C for the target-aware ownership set), preserving every other key and the
   file's comments.

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
5. **Backup** — timestamped copy of files in the installer write-set only (not entire destination). **CR-14**: Backup scope limited to template-owned files to avoid preserving unrelated state or bloating backup size.
6. **Apply** — copy files; merge `config.yml`; never touch protected paths.
7. **Manifest** — write the JSON record described in D-6.
8. **Post-validate** — confirm OMP discovers the installed components (§13 L1 Discovery).

Protected paths, never written: `models.yml`, `config.yml` (merge only), `agent.db*`,
`sessions/`, `auth.json`, any `.env`.

---

## C. `config.yml` Merge Rule

**CR-31 — Ownership is now two-class and target-aware.** An earlier draft said "the template
owns exactly one key: `modelRoles`." That was correct before capture-first isolation became a
correctness precondition. It is now insufficient: `08-isolation-and-concurrency.md §E-9`
establishes that `task.isolation.apply: false` must be *effective at runtime* or the parallel
Orchestrated path is unsafe, and OMP's default is `true`.

### C-1. Ownership classes

```yaml
owned_model_roles:              # both targets
  modelRoles.tech-lead
  modelRoles.explorer
  modelRoles.implementer
  modelRoles.verifier
  modelRoles.reviewer

owned_required_settings:        # PROJECT target only — see C-2
  task.isolation.apply: false   # correctness precondition for parallel capture-first
  task.isolation.mode: auto     # backend selector; must not be "none"

user_preserved:
  everything_else               # never read, never written, never reordered
```

`task.isolation.merge` is **not** owned. The integration procedure in
`08-isolation-and-concurrency.md §E-10` handles both `patch` and `branch`; T-00.E3-C records
the observed behavior of whichever value is effective.

### C-2. Target-aware policy for `owned_required_settings`

| Target | Destination | Policy |
|---|---|---|
| **project** | `<repo>/.omp/config.yml` | Installer writes `owned_required_settings`. Blast radius is the one repository that opted in by installing the template. |
| **user** | `~/.omp/agent/config.yml` | Installer **MUST NOT** write `task.isolation.*` unless `-EnableCaptureFirstIsolation` is passed explicitly. Without the flag: skip these keys, print a notice naming the runtime preflight requirement, and continue. With the flag: write them and print a warning that **every isolated task in every repository** on the machine becomes capture-only. |

Rationale for the asymmetry: a project-scoped setting affects only the project that installed
the template. A user-global setting silently changes unrelated OMP work across all
repositories — a blast radius the template has no mandate to take.

### C-3. Merge semantics (all owned keys)

- Destination file absent → write the template file verbatim (owned keys only, per target).
- Destination present, owned key absent → insert it; preserve everything else.
- Destination present, owned key already set to the **required** value → no-op.
- Destination present, owned key set to a **conflicting** value → **CONFLICT: report, do not
  overwrite.** For `modelRoles.*` the user's choice is simply preserved. For
  `task.isolation.apply: true` the installer MUST print:

  ```
  CONFIG CONFLICT: task.isolation.apply is set to true at <path>.
  The Orchestrated workflow requires false for safe parallel capture-first integration.
  Parallel isolated Implementers will not launch until this is resolved
  (/orchestrated preflight will refuse and fall back to sequential).
  Resolve manually, or re-run with -Force-CaptureFirstIsolation to overwrite.
  ```

  Never silently overwrite a value the user explicitly set.
- Always preserve unrelated keys and, where practical, comments.

A destructive whole-file replacement of `config.yml` is prohibited in every mode.

### C-4. Installation does not replace the runtime preflight

Config precedence in OMP v17.2.10 is
`defaults < user/global < project < CLI overlay < runtime overrides`. A CLI overlay or runtime
override can re-enable `apply` after a correct install. Therefore `/orchestrated` MUST read the
**effective** value before every parallel fan-out (`08-isolation-and-concurrency.md §E-9`).
Installation reduces the probability of misconfiguration; it never proves the runtime state.

---

## D. Rollback Contract

```
uninstall-template.ps1
  -BackupDir <path>     (mandatory — printed by install)
  -Manifest  <path>     (optional — enables targeted revert)
  -Target / -ProjectDir (must match the original install)
  -DryRun               (default: TRUE)
```

**CR-13 — Rollback per-operation semantics:**

Two modes:

- **Backup restore** (available today): restore files from the backup. Simple and reliable for OVERWRITE operations (exact bit-for-bit restoration). **Limitation**: cannot detect conflicts when the user modified a file post-install — applying backup wholesale may clobber legitimate user edits.
- **Manifest revert** (to add): operation-aware rollback using per-operation records in the manifest.
  - **OVERWRITE**: restore original content from backup, but **verify SHA-256 first**. If current file ≠ installed SHA, report CONFLICT (user modified post-install) and skip restoration. No "force" mode is provided — the user must manually resolve OVERWRITE conflicts.
  - **MERGE** (config.yml): key-level rollback using the installer delta recorded in the manifest (see manifest schema below). For each installer-owned inserted key: if current value == installed value → remove key; if key no longer exists → no-op; else → CONFLICT on that key (preserve user value, report). For installer-modified keys: if current value == installed value → restore previous value; if current value == previous value → already restored, no-op; else → CONFLICT on that key.
  - **CREATE**: delete only if current SHA matches installed SHA; otherwise report MODIFIED and skip.

**Manifest delta requirement (CR-13):** The manifest MUST record, per MERGE operation:

```json
{
  "operation": "MERGE",
  "path": "config.yml",
  "installer_delta": {
    "inserted": {
      "modelRoles.explorer": "omniroute/codex/...",
      "modelRoles.implementer": "omniroute/codex/...",
      "task.isolation.apply": false,
      "task.isolation.mode": "auto"
    },
    "modified": {
      "task.isolation.apply": {
        "before": true,
        "installed": false
      }
    }
  }
}
```

A file-level hash alone is insufficient to reconstruct installer key ownership for MERGE rollback.

**CR-31 — isolation keys are tracked identically to `modelRoles`.** `task.isolation.apply` and `task.isolation.mode` are installer-owned in the project target (§C), so they appear in `installer_delta` and follow the same per-key rollback algorithm: on uninstall, remove/restore the key only if its current value still equals the installed value; otherwise report a per-key CONFLICT and preserve the user's value. Because `task.isolation.apply` has a meaningful OMP default (`true`), the `modified` record MUST capture `before` even when the key was absent — record `before: null` for "key was absent, OMP default applied" so rollback removes the key rather than writing `true` explicitly.

In the user/global target these keys are **not** installer-owned unless `-EnableCaptureFirstIsolation` was passed; when it was, the manifest MUST record that flag so uninstall knows the global key is in scope for reversal.

Rollback must be dry-run by default, never delete a file absent from the manifest, and never silently clobber user modifications.

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
