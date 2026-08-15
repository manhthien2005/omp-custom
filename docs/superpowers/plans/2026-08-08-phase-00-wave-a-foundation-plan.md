# Phase 00 Wave A Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the durable Phase 00 provenance, status manifest, OMP compatibility ledger, and static validation foundation without changing template workflow behavior or the live OMP installation.

**Architecture:** Wave A adds a repository-owned evidence index and a dedicated compatibility record, then extends the existing PowerShell validator through a focused helper library. The manifest uses a constrained YAML shape that the helper validates without adding a package manager, runtime service, or general-purpose YAML engine. Runtime experiments and installed-surface migration remain later waves.

**Tech Stack:** PowerShell 5.1-compatible scripts, Pester 3.4-compatible tests, YAML/Markdown data artifacts, Git and OMP read-only provenance commands.

## Global Constraints

- Normative authority: `spec/phases/phase-00-foundation.md`.
- Approved design: `docs/superpowers/specs/2026-08-08-phase-00-execution-evidence-design.md`.
- Base HEAD: `62fecf277dc9d5e47d06319387eac747462214c1` on `main`.
- Pinned OMP SHA: `3a8591a8af5b6d200088d12ca75a5517cb064fa8`.
- Verified runtime: `omp/17.2.10`.
- Phase 00 introduces no workflow behavior and does not enable parallel mode.
- Do not write under `C:/Users/MrThien/.omp/agent` or change frozen global settings.
- Preserve the tracked F7/F8 spec diff and all pre-existing untracked review packets.
- Do not stage, commit, push, branch, or rewrite history without explicit user direction.
- Record every mutation in `codex-phase00-execution-changelog-for-opus5.md` with hashes.
- Wave A cannot mark any runtime experiment `PASS` because it runs no runtime experiment.

---

## File Map

**Create:**

- `docs/evidence/phase-00/manifest.yml` — Phase 00 state/dependency index.
- `docs/evidence/phase-00/environment/baseline.yml` — sanitized baseline provenance.
- `docs/evidence/phase-00/environment/repository-status-before.txt` — initial Git status.
- `registry/omp-compatibility.yml` — version and claim-to-source ledger.
- `scripts/lib/phase00-evidence.ps1` — focused contract parser/validator.
- `scripts/tests/phase00-wave-a.Tests.ps1` — Pester controls.

**Modify:**

- `registry/upstreams.yml` — correct OMP pin metadata and watched paths.
- `scripts/validate-template.ps1` — require and validate Wave A records.
- `codex-phase00-execution-changelog-for-opus5.md` — append evidence for every change.
- This plan — check off only evidence-backed completed steps.

**Untouched in Wave A:** `template/.omp/policies/**`, `template/.omp/schemas/**`,
`template/.omp/agents/**`, `template/.omp/commands/**`, and the live OMP home.

---

### Task 1: Write Wave A Contract Tests First

**Files:**
- Create: `scripts/tests/phase00-wave-a.Tests.ps1`
- Read: `scripts/validate-template.ps1`
- Read: `spec/phases/phase-00-foundation.md`

**Interfaces:**
- Consumes: repository paths and future helper functions.
- Produces: acceptance tests for manifest, registry, and compatibility contracts.

- [x] **Step 1: Capture pre-change hashes and status**

```powershell
git status --short
git rev-parse HEAD
Get-FileHash -Algorithm SHA256 registry/upstreams.yml, scripts/validate-template.ps1, spec/phases/phase-00-foundation.md
```

Expected: HEAD matches the global constraint; no Wave A production artifact exists.

- [x] **Step 2: Create exact Pester invariants**

The test file defines:

```powershell
$expectedIds = @(
    'T-00.1','T-00.2','T-00.3','T-00.4','T-00.5','T-00.6','T-00.7',
    'E1','E2','E3-A','E3-B','E3-C','E3-D','E3-E','E3-F','E3-G','E3-H',
    'E3-I','E3-J','E3-K','E3-L','E3-M','E4','E5-A','E5-B','E5-C','E5-D','E5-E','E5-F'
)
$allowedStates = @(
    'NOT_STARTED','READY','RUNNING','PASS','FAIL',
    'BLOCKED_ENVIRONMENT','DEFERRED_PARALLEL_DISABLED'
)
```

Required tests cover: exact/unique IDs; allowed states; known non-self dependencies;
dependency completion before READY/RUNNING/PASS; E3-M-only deferral; E3-M retaining
`parallel_mode: DISABLED`; existing in-repository artifact links for PASS; exact OMP
pin; thirteen watched paths; `DISC-001` through `DISC-015`; and watched-path claim coverage.

Invalid controls use one resolved directory beneath `[System.IO.Path]::GetTempPath()`.
Cleanup first proves the exact fixture path begins with the resolved OS temp root.

- [x] **Step 3: Run tests and verify RED**

```powershell
Invoke-Pester -Script scripts/tests/phase00-wave-a.Tests.ps1 -PassThru
```

Expected: non-zero tests and FAIL because the helper and durable artifacts do not exist.
Record exact total/passed/failed counts; a zero-test run is invalid.

- [x] **Step 4: Record the RED checkpoint**

Append the command and counts to the Opus changelog, explicitly stating that no runtime
experiment ran.

---

### Task 2: Create Baseline Provenance and the Manifest

**Files:**
- Create: `docs/evidence/phase-00/environment/repository-status-before.txt`
- Create: `docs/evidence/phase-00/environment/baseline.yml`
- Create: `docs/evidence/phase-00/manifest.yml`
- Modify: `codex-phase00-execution-changelog-for-opus5.md`

**Interfaces:**
- Consumes: Task 1 pre-change commands and normative dependencies.
- Produces: stable IDs and provenance for all later waves.

- [x] **Step 1: Persist sanitized initial Git status**

Write exact `git status --short` output to the status artifact. Store names/statuses only,
never file contents.

- [x] **Step 2: Create the baseline record from fresh observations**

Acquire dynamic values first:

```powershell
$observedCapturedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
$observedArchitecture = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString()
$observedPowerShell = $PSVersionTable.PSVersion.ToString()
```

Use `apply_patch` and insert those three literal outputs into this contract:

```yaml
schema_version: 1
phase: "00"
captured_at: literal value of observedCapturedAt
repository:
  root: D:/Dev/Projects/omp-template
  branch: main
  head: 62fecf277dc9d5e47d06319387eac747462214c1
  status_artifact: docs/evidence/phase-00/environment/repository-status-before.txt
platform:
  os: Microsoft Windows 10.0.26100
  architecture: literal value of observedArchitecture
  powershell: literal value of observedPowerShell
omp:
  executable: C:/Users/MrThien/AppData/Local/omp/omp.exe
  version: 17.2.10
  pinned_source_clone: _research/upstreams/oh-my-pi
  pinned_source_head: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
protected_live_home:
  path: C:/Users/MrThien/.omp/agent
  write_authorized: false
  content_captured: false
runtime_experiments_executed: []
```

- [x] **Step 3: Create every manifest row using one grammar**

```yaml
  - id: E3-L
    kind: experiment
    state: NOT_STARTED
    depends_on: [E3-A, E3-H]
    artifacts: []
    decision: null
```

Root keys are `schema_version`, `phase`, `normative_spec`, `parallel_mode`, and
`entries`; `parallel_mode` is `DISABLED`.

Use this dependency map:

```text
T-00.1 []
T-00.2 [T-00.1]
T-00.3 []
T-00.4 [E1]
T-00.5 [T-00.3, T-00.4]
T-00.6 [T-00.4]
T-00.7 [E1, E2, E3-A, E3-B, E3-C, E3-D, E3-E, E3-F, E3-G, E3-H, E3-I, E3-J, E3-K, E3-L, E4, E5-A, E5-B, E5-C, E5-D, E5-E, E5-F]
E1 []
E2 []
E3-A []
E3-B [E3-A, E3-H]
E3-C [E3-A, E3-H]
E3-D [E3-B]
E3-E [E3-D, E3-J]
E3-F [E3-E]
E3-G []
E3-H []
E3-I [E3-A, E3-H]
E3-J []
E3-K [E3-J]
E3-L [E3-A, E3-H]
E3-M [E3-L]
E4 []
E5-A []
E5-B []
E5-C []
E5-D []
E5-E []
E5-F []
```

No-dependency rows start `READY`, dependent rows start `NOT_STARTED`, and E3-M starts
`DEFERRED_PARALLEL_DISABLED` with decision `parallel_mode: DISABLED; experiment not attempted`.

- [x] **Step 4: Run provisional self-consistency checks**

Assert 29 unique IDs, allowed spelling, disabled parallel mode, and E3-M deferral.

- [x] **Step 5: Hash and log all three artifacts**

Do not mark any experiment PASS.

---

### Task 3: Normalize the OMP Pin and Compatibility Ledger

**Files:**
- Modify: `registry/upstreams.yml`
- Create: `registry/omp-compatibility.yml`
- Modify: `docs/evidence/phase-00/manifest.yml`
- Modify: `codex-phase00-execution-changelog-for-opus5.md`

**Interfaces:**
- Consumes: pinned source clone and `spec/02-runtime-semantics.md`.
- Produces: T-00.1/T-00.2 artifacts and source mappings.

- [x] **Step 1: Verify pinned clone**

```powershell
git -C _research/upstreams/oh-my-pi rev-parse HEAD
git -C _research/upstreams/oh-my-pi status --short
```

Expected: exact pinned SHA and clean status.

- [x] **Step 2: Update only the OMP registry entry**

Set `clone_date: "2026-08-07"`, `tier: runtime-authority`,
`update_policy: manual-review-only`, `last_reviewed: "2026-08-08"`, and
`evaluation_suite: evals/`. Replace its six documentation watched paths with:

```text
packages/coding-agent/src/discovery/helpers.ts
packages/coding-agent/src/discovery/builtin.ts
packages/coding-agent/src/task/discovery.ts
packages/coding-agent/src/task/agents.ts
packages/coding-agent/src/task/index.ts
packages/coding-agent/src/task/executor.ts
packages/coding-agent/src/task/structured-subagent.ts
packages/coding-agent/src/task/isolation-runner.ts
packages/coding-agent/src/tools/yield.ts
packages/coding-agent/src/config/model-resolver.ts
packages/coding-agent/src/config/model-roles.ts
packages/coding-agent/src/config/settings-schema.ts
packages/utils/src/frontmatter.ts
```

- [x] **Step 3: Prove all thirteen paths resolve at the pinned clone**

Join each path to `_research/upstreams/oh-my-pi` and require a leaf file.

- [x] **Step 4: Create `registry/omp-compatibility.yml`**

Root contract:

```yaml
schema_version: 1
omp_verified_version: "17.2.10"
omp_verified_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
omp_minimum_version: "17.2.0"
verification_date: "2026-08-08"
normative_source: spec/02-runtime-semantics.md
verified_claims: []
```

Create `DISC-001` through `DISC-013` for commands, rules, prompts, extensions,
settings.json, instructions, hooks, tools, config.yml, skills, AGENTS.md, RULES.md,
and agents discovery. `DISC-014` proves policies have no consumer; `DISC-015` proves
schemas have no consumer. Every claim contains `statement`, `source_path`,
`source_anchor`, `spec_anchor`, and `evidence_type: SOURCE_VERIFIED`.

Add focused claims for frontmatter parsing, key normalization, yield injection, model
roles, output enforcement, isolation, settings defaults, and LSP so each watched path
backs at least one claim.

- [x] **Step 5: Advance only T-00.1 and T-00.2 legally**

After checks pass: `T-00.1 READY -> PASS`, then
`T-00.2 NOT_STARTED -> READY -> PASS`. Link the registry and compatibility artifacts.

- [x] **Step 6: Record before/after hashes and exact claim anchors**

No other manifest row becomes PASS.

---

### Task 4: Implement the Focused Validator Helper

**Files:**
- Create: `scripts/lib/phase00-evidence.ps1`
- Test: `scripts/tests/phase00-wave-a.Tests.ps1`

**Interfaces:**
- Consumes: manifest, registry block, compatibility ledger, repository root.
- Produces: result objects with `Status`, `Code`, and `Message`.

- [x] **Step 1: Implement exact function signatures**

```powershell
function New-Phase00ValidationResult {
    param(
        [ValidateSet('PASS','FAIL','WARN')][string]$Status,
        [string]$Code,
        [string]$Message
    )
    [pscustomobject]@{ Status = $Status; Code = $Code; Message = $Message }
}
function Read-Phase00Manifest { param([Parameter(Mandatory)][string]$Path) }
function Test-Phase00ManifestContract { param([Parameter(Mandatory)][string]$RepositoryRoot) }
function Test-OmpRegistryContract { param([Parameter(Mandatory)][string]$RepositoryRoot) }
function Test-OmpCompatibilityContract { param([Parameter(Mandatory)][string]$RepositoryRoot) }
```

- [x] **Step 2: Parse only the constrained manifest grammar**

Recognize root scalars and entry blocks beginning with exactly two spaces plus `- id:`.
Entry keys use four spaces. Split inline arrays on commas after brackets are removed.
Reject tabs, duplicate/missing/unrecognized keys. Do not claim general YAML conformance.

- [x] **Step 3: Implement manifest semantic checks**

Require the exact 29 IDs, unique allowed states, valid non-self dependencies, completed
dependencies before READY/RUNNING/PASS, existing in-repository artifacts for PASS,
E3-M-only deferral, and disabled parallel mode for E3-M deferral. Resolve paths with
`[System.IO.Path]::GetFullPath()` and prevent repository-root escape.

- [x] **Step 4: Implement registry checks**

Validate exact SHA, runtime-authority tier, manual policy, clone date, evaluation suite,
thirteen unique watched paths, and leaf-file existence under the pinned clone.

- [x] **Step 5: Implement compatibility checks**

Validate versions, commit, verification date, unique required claim IDs/fields, all
`DISC-001` through `DISC-015`, and watched-path source coverage.

- [x] **Step 6: Run Pester and verify GREEN**

```powershell
Invoke-Pester -Script scripts/tests/phase00-wave-a.Tests.ps1 -PassThru
```

Expected: non-zero tests, zero failures, every negative control passing.

- [x] **Step 7: Hash and log helper/test files**

Record test counts and the constrained-parser limitation.

---

### Task 5: Integrate Checks into the Existing Validator

**Files:**
- Modify: `scripts/validate-template.ps1`
- Test: `scripts/tests/phase00-wave-a.Tests.ps1`
- Modify: `codex-phase00-execution-changelog-for-opus5.md`

**Interfaces:**
- Consumes: Task 4 result objects.
- Produces: one repository validation entrypoint with Wave A failures in existing counters.

- [x] **Step 1: Add Wave A durable records to required files**

Require the manifest, baseline, status artifact, compatibility ledger, and helper.
Keep policies/schemas required until Wave C.

- [x] **Step 2: Load helper fail-closed**

Resolve it relative to `$PSScriptRoot`; call `Write-Fail` if absent or unloadable.

- [x] **Step 3: Add a dedicated Phase 00 section**

Call all three contract functions and map PASS/FAIL/WARN to existing counters, retaining
stable result codes in messages.

- [x] **Step 4: Run full validation**

```powershell
& ./scripts/validate-template.ps1 -Verbose
```

Expected: exit 0 and no Wave A failure; record existing warnings exactly.

- [x] **Step 5: Run fail-closed integration control**

Use a temporary copied manifest with one invalid state. Expected: stable manifest-state
FAIL. Never mutate the canonical manifest for a negative control.

- [x] **Step 6: Record validator hashes and results**

Append exact counts and exit code to the changelog.

---

### Task 6: Wave A Closure Audit

**Files:**
- Modify: this plan and the Opus changelog.
- Read: all Wave A files and the normative spec.

**Interfaces:**
- Consumes: all Wave A artifacts and fresh verification.
- Produces: Wave A status without Phase 00 or joint peer closure claims.

- [x] **Step 1: Run final verification fresh**

```powershell
Invoke-Pester -Script scripts/tests/phase00-wave-a.Tests.ps1 -PassThru
& ./scripts/validate-template.ps1 -Verbose
git diff --check
git status --short
git diff -- registry/upstreams.yml scripts/validate-template.ps1
```

- [x] **Step 2: Re-verify safety boundaries**

Confirm no live-home path occurs in the mutation ledger, no experiment row is PASS,
and `parallel_mode` remains DISABLED.

- [x] **Step 3: Complete the Wave A changelog entry**

Record file/section anchors, before/after SHA-256, commands and exact counts, negative
controls, manifest transitions, limitations, and Opus review questions. Report the
changelog's final hash outside the file to avoid self-reference.

- [x] **Step 4: Mark only evidence-backed plan checkboxes**

Each checked item must map to a fresh command result or durable hash.

- [x] **Step 5: State exact status**

Only T-00.1 and T-00.2 may close in Wave A. Runtime experiments remain unexecuted,
E3-M remains deferred, and Phase 00 plus joint peer closure stay open.

---

## Plan Self-Review Checklist

- [x] Every Wave A file has one responsibility.
- [x] Tests precede production artifacts and validator logic.
- [x] All 29 IDs and states are exact and consistent.
- [x] OQ-A-dependent schema migration is outside Wave A.
- [x] No task enables parallel behavior or modifies live OMP.
- [x] The existing validator remains the only repository entrypoint.
- [x] No incomplete marker or unspecified error-handling step remains.
- [x] No Git commit step remains under the user's no-stage/no-commit direction.

## Execution Mode

The user directed inline execution in this session. Use `superpowers:executing-plans`,
do not dispatch subagents, and checkpoint after RED, T-00.1/T-00.2, and final GREEN.
