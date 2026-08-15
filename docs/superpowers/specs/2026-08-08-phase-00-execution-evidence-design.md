# Phase 00 Execution and Evidence Design

**Status:** Approved in conversation on 2026-08-08
**Scope:** Phase 00 foundation execution only
**Normative authority:** `spec/phases/phase-00-foundation.md`
**Base repository HEAD:** `62fecf277dc9d5e47d06319387eac747462214c1`

## 1. Purpose

Phase 00 establishes a falsifiable foundation before any workflow behavior is
implemented. It freezes the OMP source authority, removes installed-surface files
that have no runtime consumer, corrects the human record, and records reproducible
runtime experiments for every downstream assumption.

Phase 00 may change documentation, registries, validation, result-contract
placement, and the installed file layout. It must not introduce or enable new
workflow behavior. Phase 01 and later behavior remain out of scope.

## 2. Design Principles

1. **Evidence precedes claims.** A runtime-dependent conclusion is not closed by
   source inference when the phase spec requires an experiment.
2. **Artifacts are durable and reviewable.** Evidence needed to close a phase gate
   lives in the repository, not only in a terminal transcript or chat.
3. **Raw observation is separate from interpretation.** Sanitized command output,
   environment metadata, and the conclusion are recorded as distinct fields.
4. **The phase DAG controls execution.** Schema re-homing that depends on OQ-A does
   not run before T-00.E1 resolves the accepted `output:` form.
5. **No hidden product setup.** Experiment-only configuration is isolated from the
   distributable template and restored or discarded after each case.
6. **Every Codex mutation is reconstructable.** The Opus changelog identifies the
   reason, exact files, relevant anchors, verification, and before/after hashes.

## 3. Repository Layout

```text
docs/evidence/phase-00/
├── manifest.yml
├── environment/
│   └── baseline.yml
├── E1/
│   ├── case-<case-id>.yml
│   └── raw/<sanitized-artifact>
├── E2/
├── E3-A/ ... E3-M/
├── E4/
└── E5/

codex-phase00-execution-changelog-for-opus5.md
```

`manifest.yml` is the compact index Opus reads first. It records each required
task or experiment, its dependencies, state, decision, and artifact links. The
per-case records hold the reproducible evidence. The root changelog records Codex
authorship and mutations; it does not duplicate raw logs.

E3-M remains `DEFERRED_PARALLEL_DISABLED` unless parallel v0 is explicitly
attempted. Deferral is a governed result, not a missing artifact.

## 4. Artifact Contract

Every experiment case record contains these fields:

```yaml
schema_version: 1
phase: "00"
experiment: E3-J
case: J1
status: PASS | FAIL | BLOCKED_ENVIRONMENT | INVALID_RUN

provenance:
  repository_head: <40-character SHA>
  repository_status_before: <artifact-relative path>
  repository_status_after: <artifact-relative path>
  omp_version: <observed version>
  omp_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  platform: <OS and architecture>
  shell: <shell and version>
  provider_gateway: <name and sanitized version/endpoint identity>

setup:
  working_directory: <absolute or repository-relative path>
  fixture: <artifact-relative path>
  effective_settings: <sanitized mapping>

execution:
  command: <exact command with secrets removed>
  exit_code: <integer or null when no process started>
  started_at: <ISO-8601 timestamp>
  completed_at: <ISO-8601 timestamp>
  raw_artifacts: [<artifact-relative path>]

observation:
  facts: [<directly observed fact>]
  source_anchors: [<pinned-SHA file and line or symbol>]
  limitations: [<observation boundary>]

interpretation:
  decision: <contract conclusion>
  spec_effect: RETAIN | CHANGE | NONE
  affected_requirements: [<stable requirement ID>]
```

Case-specific schemas in the normative phase spec extend this common envelope.
A case is `INVALID_RUN` when provenance, required fields, sanitization, or the
case-specific observation contract is incomplete. Invalid runs have no PASS power.

## 5. Manifest State Model

Allowed states are:

- `NOT_STARTED`
- `READY`
- `RUNNING`
- `PASS`
- `FAIL`
- `BLOCKED_ENVIRONMENT`
- `DEFERRED_PARALLEL_DISABLED`

A task becomes `READY` only when every dependency in the manifest is `PASS` or an
explicit phase-spec rule admits a deferral. `BLOCKED_ENVIRONMENT` records the exact
missing capability and the non-destructive checks that established the block. It
does not convert an unrun experiment into a conclusion.

The manifest records task IDs T-00.1 through T-00.7 and experiment IDs E1, E2,
E3-A through E3-M, E4, and E5-A through E5-F. Aggregate rows never replace the
required per-case artifacts.

## 6. Execution Decomposition

Phase 00 is split into reviewable waves:

### Wave A — Provenance and evidence foundation

- Capture the baseline without modifying live OMP configuration.
- Correct the OMP registry pin metadata and watched paths.
- Create the verified-claims compatibility record.
- Add validation for registry/evidence invariants.
- Create the manifest and common artifact validation contract.

### Wave B — Highest-priority runtime characterization

- Run E3-J and E3-K for blocking and batch semantics.
- Run E3-A and E3-H for settings/config precedence.
- Run E3-L for live parent-session settings observation.
- Run E3-I and E3-G for isolation boundaries.

### Wave C — Contract and installed-surface migration

- Run E1 before selecting the enforced `output:` schema form.
- Run E2 before finalizing model-role recovery behavior.
- Re-home all policy content to its named consumers and reference documents.
- Re-home schema sources to `docs/` and the E1-supported agent frontmatter form.
- Correct F-30 and all contradictory documentation claims.
- Record DR-1 through DR-7 with epistemic separation.

### Wave D — Remaining runtime gates

- Run E4 for RULES propagation and token behavior.
- Run E5-A through E5-F for the LSP four-condition conjunction.
- Run E3-B through E3-F where they were not already exercised by an earlier
  isolation fixture. A shared fixture may reduce setup duplication, but every case
  still receives its own case-specific artifact and verdict.
- Leave E3-M deferred unless parallel v0 is attempted; otherwise execute all
  mandatory E3-M gating cases and its diagnostic case.

### Wave E — Closure audit

- Run the complete validator and targeted negative controls.
- Verify every watched path against the pinned clone.
- Check every Phase 00 exit criterion against an artifact rather than prose.
- Record unresolved environment blocks without weakening downstream gates.
- Produce the compact Opus peer-review index.

## 7. Safety and Isolation

- Files under `C:/Users/MrThien/.omp/agent` are read-only during Phase 00.
- Experiment settings use disposable project fixtures or process-local/session-local
  overrides. They do not overwrite the frozen global baseline.
- Provider credentials, authorization headers, tokens, private prompts, call logs,
  and OmniRoute database content are excluded from artifacts.
- Absolute user paths are retained only when reproduction requires them; otherwise
  repository-relative paths are preferred.
- Every fixture records cleanup status. Cleanup never deletes outside the exact
  disposable fixture root.
- Existing user changes and historical review packets are preserved.

## 8. Validation Strategy

Validation has four layers:

1. **Artifact shape:** required fields, allowed states, stable IDs, and relative links.
2. **Repository consistency:** watched paths resolve, removed runtime-misleading
   directories are absent after migration, and no live prompt retains dangling
   `policy:` or `schema:` references.
3. **Experiment controls:** valid positive cases pass and deliberately incomplete or
   contradictory artifacts fail validation.
4. **Phase closure:** each exit criterion maps to a concrete artifact and fresh
   verification output.

The existing `scripts/validate-template.ps1` remains the single repository validator.
Phase 00 extends it rather than adding a second validation engine.

## 9. Changelog Contract for Opus

Each changelog entry records:

- stable change ID and timestamp;
- task/requirement IDs and rationale;
- files created, modified, moved, or removed;
- exact section or symbol anchors;
- before and after SHA-256 for every existing file changed;
- SHA-256 for every new durable artifact;
- verification commands and summarized results;
- evidence links and unresolved questions;
- whether a spec statement was retained or changed.

The changelog cannot embed its own final hash without becoming self-referential. Its
hash is therefore reported in the completion message and becomes the `previous_log_hash`
of the next appended review packet.

## 10. Non-Goals

- No Phase 01 or Phase 02 workflow implementation.
- No installation into the live OMP home.
- No enabling parallel orchestration.
- No new runtime, orchestration engine, evidence service, or database.
- No Git stage, commit, push, or branch operation without explicit user direction.

## 11. Acceptance Criteria

This design is satisfied when:

1. A single manifest indexes every Phase 00 task and experiment.
2. Every runtime conclusion is backed by a reproducible, sanitized per-case artifact.
3. OQ-A gates schema frontmatter migration.
4. E3-M deferral cannot be mistaken for parallel readiness.
5. The validator rejects malformed evidence and Phase 00 structural regressions.
6. Opus can reconstruct every Codex mutation without reading the full chat history.
7. The live OMP home and frozen global settings remain unchanged.
