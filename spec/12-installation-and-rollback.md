# 12 — Installation and Rollback

<!-- round09-12-projection:release -->
## Round 09–12 scratch proof and release boundary (KD-032)

Repository implementation proves install, discovery, repair/update, uninstall, rollback, and
user-state retention only inside a verified disposable Git project under the system temp root.
The proof may invoke the already installed supported OMP executable for model-free discovery, but
it never installs into the user's live project or user OMP directory and never copies evaluation
tooling or `evals/` into installed `.omp`.

Scratch proof is necessary package evidence, not live-install authority and not promotion evidence.
A future live install, credential change, runtime download/downgrade, provider campaign, Git stage,
commit, push, or release action requires separate explicit authority. Current truthful adapter
status remains OMP `IMPLEMENTED_NOT_PROMOTED / installable true` and Claude
`DESIGNED_NOT_VERIFIED / installable false`.

<!-- topic08-projection:behavior-core -->
## Topic 08 behavior component boundary

The manifest-coupled `agent-boundary` component owns the behavior schema, core, manifest, OMP
extension, and managed launcher, while depending on exact selected agent, skill, state, and config
bytes. Install/update checks generated locks before staging. Rollback restores attributable
component bytes and retains operational `agent-tasks`/`.agent-tasks` state. Claude is not an
installable target.

<!-- topic05-projection:installation -->
## Topic 05 optional component contract (KD-029)

`codegraph` is absent from installer defaults and requires the `state` component. Selection is
explicit; acquisition is either a caller-supplied pinned offline artifact or a separately enabled
pinned download, never both. Installation validates the component manifest, upstream lock,
artifact, receipt, platform, and runtime record before target mutation and activates the tool last.
Rollback restores exact template-owned bytes but retains the known managed bundle and per-worktree
indexes; cleanup is a separate exact-path dry-run/apply action. Generated runtime/install records,
the binary, and indexes are target state—not checked-in validation prerequisites.

## State component boundary (KD-028)

`state` is a default installer component mapped to `template/.omp/state`. Selection requires
`pwsh` 7.4+ and an exact source-manifest hash check before copy; the installer remains Windows
PowerShell 5.1 parseable. Backup/reinstall/rollback affect installed `.omp/state` executable bytes
but preserve protected model/credential/session files and never read, write, migrate, or delete
operational `agent-tasks`/`.agent-tasks` authority.

> OPUS PROPOSED SPEC v1 | Source-verified against `scripts/install-template.ps1`.
>
> **Topic 02 supersession boundary:** installer ownership is derived from the Topic
> 03-selected topology manifest. Former role keys remain baseline examples, not a fixed roster.
> Optional capability settings are owned only when the selected runtime path consumes them.
>
> **KD-027 selected set:** install exactly `cheap-scout.md`, `worker.md`, and `reviewer.md`.
> After the destination backup succeeds, retire only stale `explorer.md`, `implementer.md`,
> `tech-lead.md`, and `verifier.md`; dry-run reports but never performs retirement.

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
OMP defaults — including `approvalMode` dropping from `yolo` and the historical user-owned
`compaction.strategy: shake` value being lost. This paragraph records the pre-Topic-07 defect; it
does not select current managed continuity, which reasserts `strategy: off` through KD-031.

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
establishes that `task.isolation.apply: false` must be *effective at runtime* or a selected
conditional parallel-writer path is unsafe, and OMP's default is `true`.

### C-1. Ownership classes

```yaml
owned_model_roles:              # both targets; derived, not a static list
  source: Topic 03-selected topology manifest
  include: every custom modelRoles.<alias> referenced by a selected spawned worker

optional_model_roles:           # CR-34 — convenience alias, NOT installer-owned
  modelRoles.tech-lead:
    installer_owned: false
    required_for_workflow: false

owned_required_settings:        # PROJECT target only — see C-2
  when_conditional_parallel_writer_path_selected:
    task.isolation.apply: false # correctness precondition for parallel capture-first
    task.isolation.mode: auto   # backend selector; must not be "none"
  when_selected_roles_consume_lsp:
    task.enableLsp: true        # CR-40/CR-41; four-condition capability — see §07 §A-1
  when_selected_dispatch_uses_effort:
    task.enableEffort: true     # KD-010; otherwise effort is stripped from the task schema
    task.maxEffort: selected_required_ceiling
  when_selected_topology_uses_nested_delegation:
    task.maxRecursionDepth: selected_required_depth
  when_selected_contract_consumes_retrieval_tools:
    glob.enabled: true          # only if glob is selected
    grep.enabled: true          # only if grep is selected
    astGrep.enabled: true       # only if ast_grep is selected; default false
    web_search.enabled: true    # only if web_search is selected
  when_selected_model_identity_is_acceptance_bearing:
    retry.modelFallback: false
    retry.usageAwareFallback: false

opt_in_only_settings:           # CR-40 — user/global target requires an explicit flag
  task.enableLsp:
    flag: -EnableSubagentLsp
    blast_radius: LSP servers spawn for unrelated subagents in every repository
  task.enableEffort:
    flag: -EnablePerSpawnEffort
    blast_radius: exposes the effort field to unrelated subagent dispatches
  retry.modelFallback_and_retry.usageAwareFallback:
    flag: -EnforceSelectedModelIdentity
    blast_radius: disables fallback recovery for unrelated sessions

user_preserved:
  everything_else               # never read, never written, never reordered
```

**CR-34 — `modelRoles.tech-lead` is no longer installer-owned.** Two earlier decisions
jointly removed its mandatory runtime consumer:

- **CR-06/DR-1** — the main session is the Tech Lead, and its model is *user-controlled*.
  The template explicitly does **not** guarantee `@tech-lead` routing for the main session
  (`phases/phase-01-runtime-correctness.md` T-01.7): agent frontmatter is applied only at
  spawn time, and the main session is never spawned.
- **CR-33** — `agents/tech-lead.md` is removed from agent discovery entirely, so no
  `model: "@tech-lead"` frontmatter is ever parsed by `loadAgentsFromDir()`.

A model role only has an effect when something resolves it — either spawn-time agent
frontmatter, or a user explicitly selecting the alias. After CR-06 and CR-33, neither is
required by any workflow path, so `@tech-lead` has **zero mandatory runtime consumers**.
Owned model-role keys are derived from the Topic 03-selected topology manifest: only aliases
actually referenced by selected spawned workers are required.

Keeping it installer-owned would violate architecture principle 3 ("every artifact maps to
a verified OMP primitive, or is explicitly labelled documentation / build input / dead"):
the installer would create the key, conflict on it, track it in the manifest, include it in
rollback, and require the user to reason about it — all for a value nothing reads.

It is retained as an **optional convenience alias** because OMP does support arbitrary
custom roles (`config/model-resolver.ts:925`), so a user who wants `@tech-lead` available
for manual model selection in their main session can add it. The template documents it in
`docs/roles/tech-lead.md`; the installer neither writes nor validates it. Consequences:

- **Not written** on either target, with or without conflict.
- **Not in `installer_delta`**, therefore not in rollback.
- **Not validated** — role-reference validation (`spec/09 §B`) checks only roles actually
  referenced by a discovered `agents/*.md` file. Since no agent file references
  `@tech-lead` after CR-33, a missing `modelRoles.tech-lead` is **not** a validation
  failure. An agent file that *does* reference it would be a CR-33 regression, caught by
  the L1 check that `tech-lead` must not appear in the discovered agent list.

**CR-40 — `task.enableLsp` is owned for the same reason `task.isolation.apply` is.** Its
default is `false` (`config/settings-schema.ts:4615-4617`), and subagent LSP requires it to be
`true` at the settings layer — there is no per-call override on the model-facing task wire.
When selected LSP-consuming roles depend on `lsp`, a template that adds it to their allowlists
without deploying the setting ships a capability that is granted and then withheld. If no
selected contract consumes LSP, the installer does not own this key. That was the round-1
defect inverted: the allowlist fixed, the gate still shut.

Conflict handling differs from the isolation keys in one respect worth stating: an existing
`task.enableLsp: false` is a **deliberate user cost decision** (the setting's own description
is *"Off by default to keep subagents cheap"*). Report the conflict and do not overwrite. That
preserves the user's configuration choice, but it does not make the selected contract runnable:
the selected LSP-consuming path remains disabled while any required gate is unmet. Continue
only after remediation or after the Tech Lead selects a different contract that does not consume
LSP, reconciles the manifest and accepted task contract, and validates the replacement path.
If locked criteria or verification/review obligations change, the material-change rule applies.

Selected LSP installation acceptance probes applicable language-server routing and treats
details.success false as a failed capability result. Four effective registration gates are not
enough: representative selected file types must route to an applicable server, and every
acceptance-bearing LSP call must report `details.success: true` (`lsp/index.ts:2145-2160`). The
installer reports missing server provisioning/configuration without replacing the selected
semantic contract with text retrieval.

**KD-010/KD-012/KD-027 — effort and model identity are selected-path settings, not assumed
baselines.** Selected per-spawn effort makes `task.enableEffort: true` and
`task.maxEffort: xhigh` owned project prerequisites and fails preflight when either is not
effective. KD-027 owns `retry.modelFallback: true`, `retry.usageAwareFallback: false`, one
Cheap-Scout-only Pro chain, and explicit empty default/Worker/Reviewer chains. The installer
validates that closed shape rather than globally forcing fallback off.

Validator contract: Selected per-spawn effort makes task.enableEffort true and task.maxEffort
xhigh owned prerequisites and fails preflight when either is not effective. KD-027 selected
routing owns retry.modelFallback true, retry.usageAwareFallback false, one Cheap-Scout-only Pro
chain, and empty default/Worker/Reviewer chains.

Selected-model preflight reconciles task.agentModelOverrides and rejects an unselected effective
override. Because missing model credentials can silently choose the parent model
without setting `resolvedModelIsFallback`, Worker/Reviewer result acceptance also compares
returned `modelRole` and `resolvedModel` with the reconciled expected identity. The explicit
fallback flag remains diagnostic evidence; only the selected Scout availability path may consume
the named Pro fallback.

Selected grep, glob, ast_grep, and web_search consumers own matching project settings and fail
preflight when ineffective. At user scope these remain opt-in and conflict-preserving; a conflict
disables only the selected consumer path and requires an explicit different contract plus
reconciliation/revalidation.

Selected exact-effort consumers own a sufficient task.maxEffort ceiling, and selected nested
delegation preflights task.maxRecursionDepth. A lower effort ceiling or exhausted recursion depth
does not silently downgrade the selected contract. The installer records the manifest-derived
minimum/ceiling, while L1 verifies the effective value after precedence.

`task.isolation.merge` is **not** owned. The integration procedure in
`08-isolation-and-concurrency.md §E-10` handles both `patch` and `branch`; T-00.E3-C records
the observed behavior of whichever value is effective.

`task.batch` and `async.enabled` are **not** owned either, for opposite reasons.
`task.batch: true` is a conditional parallel-batch path precondition checked at runtime with a
documented sequential fallback (§08 §C-1.4); it does not define Orchestrated classification.
Owning it would write a key whose default is already correct and whose override the user may
want for other work. `async.enabled` is deliberately left alone: selected stage barriers use
per-agent `blocking: true` frontmatter (§08 §C-1.3), which is strictly narrower than suppressing
a user-global execution mode.

### C-2. Target-aware policy for `owned_required_settings`

| Target | Destination | Policy |
|---|---|---|
| **project** | `<repo>/.omp/config.yml` | Installer writes `owned_required_settings`. Blast radius is the one repository that opted in by installing the template. |
| **user** | `~/.omp/agent/config.yml` | Installer **MUST NOT** write conditional settings without their explicit opt-in: `-EnableCaptureFirstIsolation`, `-EnableSubagentLsp`, `-EnablePerSpawnEffort`, or `-EnforceSelectedModelIdentity`. Without the relevant flag, skip that key set and state that its selected path remains disabled. With it, write the values and disclose their global blast radius. The LSP path may continue only under an explicitly selected and validated non-LSP replacement contract; other selected paths follow the same fail-closed/reconciliation rule. |

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
  The selected parallel capture-first path requires false for safe integration.
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

---

## G. Topic 06 component transaction

`agent-boundary` is a manifest-verified installed component containing the portable core/schema/
CLI, trusted extension, managed overlay, and launcher. Its dependencies are the selected agents,
compatible config, and Topic 04 state component. Installation validates all source hashes,
supported OMP version, PowerShell 7.4+, dependency manifests, target config, and wrapper load
before reporting success. Apply is backup-first and rollback restores exact prior bytes.

Topic 06 owns `task.softRequestBudget: 200`; Topic 07 adds the exact disabled automatic-compaction
profile, continuity schema/core/client, and final trusted adapter. The launcher is
`.omp/bin/omp-managed.ps1` and preserves the caller's project working directory while placing the
managed overlay last. Uninstall removes only manifest-owned/generated boundary files whose bytes
are still attributable, preserves user modifications as conflicts, and never touches operational
`agent-tasks` authority. Historical `.omp/schemas` files are not installed requirements.

The combined component supports OMP 17.2.10 and 17.2.12. Installation does not promote Topic 07
until the stop-before-provider canary passes on both versions; a missing local runtime is reported
as `OPEN-T07-RUNTIME-02` / `IMPLEMENTED_NOT_PROMOTED` without download or downgrade.
