# Phase 05 — Installation Hardening

<!-- round09-12-projection:security -->
## Round 09–12 security/package supersession

KD-032 adds deterministic secret, authority, retry, partial-output, and trust-boundary cases, then
uses only a disposable Git project for package proof. That proof exercises current transactional
install/repair/uninstall/rollback behavior; it does not authorize a live install, provider call,
credential change, runtime download, or Git publication. Historical tasks below remain the
implementation provenance and may not weaken the scratch-only boundary.

<!-- topic06-projection:phase-05 -->
## Topic 06 installation consumer

Install `agent-boundary` transactionally after agents, config, and Topic 04 state. Validate the
component manifest, exact source/installed hashes, PowerShell 7.4+, supported OMP version, wrapper
load order, and the closed overlay before success. Rollback removes/restores only attributable
boundary bytes and retains operational `agent-tasks` authority.

<!-- topic07-projection:phase-05 -->
## Topic 07 installation consumer

Install continuity schema/core/state client/extension as manifest-bound `agent-boundary` v2 bytes,
load the continuity extension last, and validate supported OMP 17.2.10/17.2.12 plus the exact
disabled profile. Rollback restores attributable installed bytes while preserving Topic 04
`agent-tasks`, OMP sessions, and recovery artifacts. Installation makes no provider call and must
not download or downgrade a missing runtime. Until both runtime canaries pass, report
`IMPLEMENTED_NOT_PROMOTED` with `OPEN-T07-RUNTIME-02` rather than promoting the default.

<!-- topic05-projection:phase-05 -->
## Topic 05 installation consumer

Ship `codegraph` as an explicit state-dependent component with offline-artifact and separately
authorized pinned-download paths. Exit only when default/dry-run is inert, every activation
boundary restores exact prior bytes on failure, the tool activates last, uninstall reports exact
retained bundle/index paths, and cleanup is confined to an explicit dry-run/apply target.

## Topic 04 consumer projection

Topic 04 consumes state-core installation and rollback retention. Phase 05 installs the default
`state` component only after `pwsh` 7.4+ and manifest validation, backs up/restores `.omp/state`,
preserves protected files, and never touches operational `agent-tasks` authority.

> OPUS PROPOSED SPEC v1 | Make install and rollback safe, complete, and reversible.
>
> **Topic 02 supersession boundary:** installed workers, model aliases, and optional capability
> settings derive from the Topic 03-selected topology manifest. Former four-role keys are
> migration examples, not the owned set.

**Depends on**: phase-01
**Blocks**: phase-06

---

## KD-027 installation projection

The installer-owned agent manifest is exactly `cheap-scout.md`, `worker.md`, and `reviewer.md`.
After a successful target backup, installation explicitly retires only the stale discovered
definitions `explorer.md`, `implementer.md`, `tech-lead.md`, and `verifier.md`. Dry-run reports
those retirements without mutation. Rollback restores the backed-up state; broad wildcard deletion
is forbidden.

The owned model-role keys are `cheap-scout`, `worker`, and `reviewer`. Project config owns
`task.enableEffort: true`, `task.maxEffort: xhigh`, `retry.modelFallback: true`,
`retry.usageAwareFallback: false`, the single Cheap Scout Pro fallback, and explicit empty
default/Worker/Reviewer chains. User/global installation does not widen these settings without an
explicit opt-in. `models.yml`, credentials, databases, and sessions remain protected.

---

## Objective

Deliver an installer that plans accurately, never destroys user data, records what it
did, and can be reverted exactly — plus a rollback path that restores rather than
approximates.

---

## Rationale

Phase-01 stopped the bleeding (component map, config protection, `$Force`). This phase
makes installation trustworthy as a system: manifest-based rollback instead of
backup-directory guessing, real config merging instead of side-by-side files, and
verification that the install actually works rather than that files were copied.

---

## Tasks

### T-05.1 — Emit an install manifest

Record, per install: timestamp, template version, OMP verified commit, target,
resolved destination, components, and every file written with its hash — plus the
backup path.

Rollback currently depends on the user remembering a backup path printed to a
terminal that may be long gone. A manifest makes reversal deterministic.

**Acceptance**: `.omp/.omp-template-manifest.json` written on every real install and
lists every file with a hash.

### T-05.2 — Implement manifest-based rollback

`uninstall-template.ps1` should: locate the manifest, then for each recorded file apply operation-aware rollback per CR-13:
- **OVERWRITE** operations: remove only if hash still matches; report CONFLICT and preserve when user-modified
- **MERGE** operations (config.yml): key-level revert using installer delta from manifest; preserve user additions; report conflicts on diverged keys
- **CREATE** operations: delete only if hash still matches
- Restore from backup when appropriate (for OVERWRITE files that match installed hash)

**Acceptance**: uninstall removes template files that haven't been modified, preserves user-modified ones, performs key-level MERGE rollback for config.yml, and reports all conflicts. Round-trip returns the directory to its pre-install state when no user modifications occurred.

### T-05.3 — Implement real config merging

Phase-01 avoids overwrite by writing `config.yml.new` — safe but incomplete. Merge the
installer-owned keys into an existing config, preserving all other keys and comments;
report conflicts rather than resolving silently.

**CR-31 — two ownership classes, target-aware.** Per `12-installation-and-rollback.md §C`,
the merge now covers two classes, not just `modelRoles`:

- `owned_model_roles` — owned model-role keys are derived from the Topic 03-selected topology
  manifest: `cheap-scout`, `worker`, and `reviewer`. Both targets. Conflict → preserve the
  user's value, report.
  **`modelRoles.tech-lead` is NOT owned (CR-34)** — it has no mandatory runtime consumer
  after CR-06 (user-controlled main session) and CR-33 (no `tech-lead` agent file), so the
  installer never writes, conflicts on, tracks, or rolls it back.
- `owned_required_settings` — settings consumed by a selected runtime path, **project target
  only**: capture-first isolation keys for a selected conditional parallel-writer path;
  `task.enableLsp: true` for selected LSP consumers; `task.enableEffort: true` and
  `task.maxEffort: xhigh` for the selected effort paths; and the closed KD-027 retry policy
  (`retry.modelFallback: true`, `retry.usageAwareFallback: false`, one Scout-only fallback,
  empty default/Worker/Reviewer chains). For the user/global target these keys are
  skipped unless the corresponding explicit opt-in flag is passed, because their blast radius
  includes unrelated repositories.

  Selected effort consumers own task.enableEffort true and a sufficient xhigh ceiling as
  conditional prerequisites. Worker/Reviewer exact identity is protected by their empty chains
  plus returned-identity comparison, while Cheap Scout owns the explicit availability chain. The
  post-install preflight also reconciles
  `task.agentModelOverrides`; an unselected effective override disables the selected path.

  Validator contract: Selected effort consumers own task.enableEffort true and task.maxEffort
  xhigh as conditional prerequisites. KD-027 owns retry.modelFallback true,
  retry.usageAwareFallback false, one Cheap-Scout-only Pro chain, and empty
  default/Worker/Reviewer chains.

  Selected retrieval consumers own matching grep, glob, ast_grep, and web_search project
  settings. Selected exact effort owns a sufficient task.maxEffort ceiling; selected nested
  delegation validates task.maxRecursionDepth before dispatch. User-scope writes require explicit
  opt-in and disclose global blast radius; preserved conflicts disable only the affected selected
  path until remediation or a reconciled/revalidated replacement contract.

  **`task.enableLsp` conflicts preserve the user value and disable that selected path.** An
  existing `false` is a deliberate user cost decision (the setting's own description is *"Off
  by default to keep subagents cheap"*). Report the conflict and preserve the user's value; the
  selected LSP-consuming path remains disabled while any required condition is unavailable.
  Continue only after remediation or after the Tech Lead selects a different contract that does
  not consume LSP, reconciles the manifest/task contract, and revalidates the replacement path.
  Installation acceptance probes applicable language-server routing for selected file types and
  treats details.success false as failure. Passing all four registration gates does not prove the
  selected file has a configured working server (`lsp/index.ts:2145-2160`).

  **`async.enabled` and `task.batch` are NOT owned (CR-39).** Stage barriers come from
  per-agent `blocking: true` frontmatter, not from suppressing a user-global execution mode;
  `task.batch` is verified only as a conditional parallel-batch path precondition with a
  documented sequential fallback. The installer must not write either key.

  **`lsp.enabled` and `bash.enabled` are NOT owned by the installer (CR-41/CR-43).** Both
  default to `true` and govern whether built-in tools are registered at all. A user who sets
  either to `false` has made a deliberate capability decision — disabling shell execution
  (`bash.enabled`) or the LSP tool (`lsp.enabled`) globally. The installer MUST NOT silently
  override these. Instead, the post-install preflight (T-05.4 / L1) detects the contradiction
  and reports it: `bash.enabled=false` is reported as a verification capability gap (§10 §B-2);
  `lsp.enabled=false` with `task.enableLsp=true` disables the selected LSP path and names that
  specific cause (§07 §A-1, CR-41 fourth gate).

  Returned `modelRole` and `resolvedModel` are compared to the reconciled expected identity at
  acceptance. This catches the credential fallback to the parent model that is not represented by
  `resolvedModelIsFallback`; a true fallback flag is independently rejected.

The manifest `installer_delta` must record `before: null` for a key that was absent, so
rollback removes it rather than writing OMP's default back explicitly (§D).

**Acceptance**: merging into an existing project config adds exactly the selected aliases and optional settings consumed by the manifest,
using the conditional ownership rules above. It
writes **no** `modelRoles.tech-lead`, `async.enabled`, or `task.batch` key; writes no
unselected LSP or isolation setting; preserves every existing key; and reports conflicts per
key. A user-target merge without the matching opt-in writes none of the conditional capability
keys and prints the relevant notice. Round-trip rollback removes exactly the keys the installer
inserted.

### T-05.4 — Verify install completeness

After applying, assert every planned non-protected file exists at its destination and
that each requested component contributed ≥1 file. The original silent failure was
exactly this class of bug.

**Acceptance**: install fails loudly on any missing expected file.

### T-05.5 — Guard the user-scope install

`-Target user` writes to the live `~/.omp/agent/`. Require explicit confirmation
(matching RULES.md invariant 5), and never touch `models.yml`, `agent.db*`, or
`sessions/`.

**Acceptance**: user-scope install without confirmation refuses; protected paths are
never planned.

### T-05.6 — Make dry-run byte-accurate

The dry-run plan must equal what apply does — same files, same skip decisions, same
protection outcomes. A dry-run that diverges from apply is worse than none.

**Acceptance**: dry-run output and apply output list identical file sets on the same
inputs.

### T-05.7 — Document selected-path requirements at the install boundary

Capability and settings prerequisites are conditional on the selected runtime path. Installation
docs derive them from the Topic 03 manifest: LSP settings only for selected LSP consumers,
isolation and concurrency only for a selected parallel-writer path, and provider endpoints only
for referenced model aliases. Topic 07 continuity is an exact managed component/profile rather
than topology selection: automatic semantic paths stay off and `/safe-compact` requires its
trusted extension, Topic 04 state, persisted sessions, local artifacts, and a supported OMP
runtime. A user whose selected path lacks a required capability receives an
explicit fail-closed notice plus the remediation or validated replacement-contract choices.

**Acceptance**: installation docs list the requirements for each selected path, and L0/L1
validation checks only the capabilities and settings consumed by that manifest.

---

## Deliverables

- Manifest emission
- Manifest-based uninstall
- `modelRoles` merge with conflict reporting
- Post-apply completeness assertion
- User-scope confirmation gate
- Byte-accurate dry-run
- Documented and checked prerequisites

---

## Verification

```powershell
# Round-trip into a scratch project
$t = "$env:TEMP\omp-install-test"
.\scripts\install-template.ps1 -Target project -ProjectDir $t -DryRun
.\scripts\install-template.ps1 -Target project -ProjectDir $t -DryRun:$false
# expect manifest present, all components non-empty
.\scripts\uninstall-template.ps1 -ProjectDir $t -DryRun:$false
# expect original state restored
```

Also: install over an existing `config.yml` (expect merge + preserved keys); modify an
installed file then uninstall (expect it preserved and reported); compare dry-run and
apply file lists.

---

## Exit Criteria

- [ ] Manifest written with hashes
- [ ] Uninstall is manifest-driven and preserves user edits
- [ ] `modelRoles` merge preserves existing config
- [ ] Post-apply completeness enforced
- [ ] User-scope requires confirmation; protected paths untouched
- [ ] Dry-run matches apply exactly
- [ ] Prerequisites documented and checked
- [ ] Round-trip restores original state

---

## Risks

| Risk | Mitigation |
|---|---|
| YAML merge loses comments | Targeted key insertion, not parse-and-reserialize; report conflicts |
| Manifest drifts from disk | Hash check at uninstall; mismatch means preserve, not delete |
| Confirmation prompt breaks automation | Explicit non-interactive flag, documented as deliberate |
| Users skip prerequisites | L0 (Static) validation reports missing settings |
