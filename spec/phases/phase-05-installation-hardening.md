# Phase 05 — Installation Hardening

> OPUS PROPOSED SPEC v1 | Make install and rollback safe, complete, and reversible.

**Depends on**: phase-01
**Blocks**: phase-06

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

Phase-01 avoids overwrite by writing `config.yml.new` — safe but incomplete. Merge
`modelRoles` keys into an existing config, preserving all other keys and comments;
report conflicts rather than resolving silently.

**Acceptance**: merging into an existing config adds the five role keys, preserves
every existing key, and reports conflicts.

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

### T-05.7 — Document prerequisites at the install boundary

`task.enableLsp: true`, `task.isolation.mode: auto`, concurrency, compaction settings,
and the OmniRoute endpoint are prerequisites for the template to behave as specified.
A user who installs without them gets degraded behavior with no signal.

**Acceptance**: prerequisites appear in installation docs and are checked by Level 1
validation.

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
| Users skip prerequisites | Level 1 validation reports missing settings |
