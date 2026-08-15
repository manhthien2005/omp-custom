# Phase 00 E3-L Live-Session Reader Implementation Plan

> **Historical-plan correction:** P00-CX-028 supersedes this plan's terminal adjudication
> assumptions. Joint Attempt 5 is `INVALID_RUN / E3IL_NESTED_PROVIDER_RECOVERY`, current
> E3-L authority is `READY`, and the authoritative correction plan is
> `2026-08-09-phase-00-e3il-terminal-precedence-correction-plan.md`. Historical execution
> steps below are preserved for auditability.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement and fail-closed-verify the scoped `pi.pi.settings` live reader for the
OMP-owned default main-CLI root-session class on pinned OMP 17.2.10, then adjudicate L1-L3
from one atomic joint E3-I/E3-L runtime transaction without enabling parallel execution.

**Architecture:** One cwd-gated project custom-tool factory exposes a fixed read-only E3-L
reader in both parent sessions and the existing fixed non-persistent E3-I override only in
Session A. A shared transport layer validates raw event pairing, exact augmented protocols,
provider/retry provenance, canary surfaces, and mutation boundaries. E3-I and E3-L then run
separate semantic oracles directly over the same raw events; neither reads or trusts the
other experiment's conclusion. Static source identity is captured from the clean pinned
upstream clone before any provider checkpoint. A joint runner groups Session A and Session B
under one attempt number, preserves every raw file additively, and materializes deterministic
JSON projections only from a complete selection-eligible transaction.

**Tech Stack:** PowerShell 5.1-compatible scripts, Pester 4 assertions, TypeScript project
custom tools loaded by OMP, OMP 17.2.10, JSON/JSONL/YAML evidence, SHA-256 ledgers, read-only
Git/source inspection, and the pinned `can1357/oh-my-pi` source clone.

## Global Constraints

- Execute inline in the current user-authorized dirty `main` workspace at repository HEAD
  `62fecf277dc9d5e47d06319387eac747462214c1`. In this task, use
  `superpowers:executing-plans`; do not dispatch subagents unless the user later explicitly
  requests them.
- Do not create a branch or worktree. Do not stage, commit, push, pull, reset, checkout, or
  create a pull request in the official workspace. Replace commit checkpoints with focused
  tests, exact hashes, and English changelog checkpoints.
- Preserve every pre-existing user/Codex change. Use `apply_patch` for authored repository
  mutations. Mechanically generated raw captures and deterministic evidence projections may
  be written only by the reviewed runners.
- Normative runtime identity is OMP `17.2.10`, executable SHA-256
  `1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6`, source commit
  `3a8591a8af5b6d200088d12ca75a5517cb064fa8`. Installed `17.2.12` is compatibility-only and
  must not widen the pin or move source anchors.
- Read source only from `_research/upstreams/oh-my-pi` after verifying its HEAD equals the
  pinned commit, its worktree is clean, and its origin is
  `https://github.com/can1357/oh-my-pi.git`.
- The supported E3-L v0 host is only the OMP-owned default main-CLI root-session construction
  class, exercised through print mode. Exclude ACP-created sessions, arbitrary SDK hosts,
  injected `settings`, `settingsManager`, or `deps.settings`, cloned settings instances,
  RPC, and RPC-UI. Never generalize PASS to all OMP hosts or sessions.
- The approved reader call is fixed to
  `pi.pi.settings.get("task.isolation.apply")`. It accepts no path/value argument and offers
  no mutation or subprocess surface. The runtime mutation is fixed to
  `pi.pi.settings.override("task.isolation.apply", true)` in Session A; never call
  `Settings.set()`, `/settings`, flush, save, or a persistence path.
- Keep `parallel_mode: DISABLED`, E3-M `DEFERRED_PARALLEL_DISABLED`, Phase 00 in progress,
  and E3-I characterization-only for every E3-L outcome. E3-L observation is not an atomic
  dispatch guard.
- Provider-backed execution is a separate authorization checkpoint. Tasks 1-8 are static and
  must make zero provider calls. Stop after Task 8 and request explicit authorization before
  Task 9.
- Never print, copy, hash, or serialize a credential value. Provider credentials may only be
  consumed from the already configured process environment after Task 9 is authorized.
- For runtime work, relocate `PI_CODING_AGENT_DIR` and `USERPROFILE`; use only verified
  OS-temporary fixture/session/runtime roots; snapshot the live OMP home and disposable Git
  fixture; validate exact deletion targets before cleanup; never alter the live installed
  OMP binary.
- Execute Session A then Session B sequentially. Never batch, parallelize, auto-retry,
  overwrite, delete, or combine attempts. Attempts 1-3 remain `INVALID_RUN`; Attempt 4 remains
  `BLOCKED_ENVIRONMENT / P00-RUNTIME-PROVIDER-OVERLOAD`.
- Run focused and complete suites in both PowerShell 7 and Windows PowerShell 5.1. A
  shell-specific evidence meaning is a defect.
- Opus peer review remains pending quota. Codex PASS is provisional and cannot jointly close
  E3-L.

**Approved design:**
`docs/superpowers/specs/2026-08-09-phase-00-e3l-live-session-reader-design.md`

---

## File Responsibility Map

| Path | Action | Single responsibility |
| --- | --- | --- |
| `spec/08-isolation-and-concurrency.md` | Modify | Correct `Settings.set()` persistence/precedence and name the scoped approved proxy reader |
| `spec/13-validation-and-evaluation.md` | Modify | Lock the L4 E3-L runtime control to the approved host-scoped proxy plus non-persistent override |
| `spec/phases/phase-00-foundation.md` | Modify | Replace the retired unresolved reader and impossible case 3 with the approved L1-L3 contract |
| `spec/phases/phase-02-core-orchestration.md` | Modify | Record the reader's bounded diagnostic scope while retaining E3-M as the only parallel gate |
| `docs/superpowers/specs/2026-08-09-phase-00-e3l-live-session-reader-design.md` | Modify after static/runtime checkpoints | Record implementation status and exact evidence without rewriting the approved design |
| `scripts/lib/phase00-e3il-transport.ps1` | Create | Shared raw-event transport, sequence, provenance, canary, and selection-eligibility checks |
| `scripts/lib/phase00-e3l-evidence.ps1` | Create | Independent E3-L source, reader, L1-L3, transaction, projection, and durable-artifact oracle |
| `scripts/lib/phase00-e3i-evidence.ps1` | Modify | Consume the augmented sequence structurally while preserving E3-I-only semantic decisions |
| `scripts/run-phase00-e3i.ps1` | Modify | Capture one augmented parent session and record joint-protocol-safe raw metadata |
| `scripts/run-phase00-e3l-joint.ps1` | Create | Group Session A/B under one attempt, enforce continuation rules, and write joint adjudication |
| `scripts/tests/phase00-e3l.Tests.ps1` | Create | E3-L source, reader, matrix, negative-control, joint-runner, and durable-evidence tests |
| `scripts/tests/phase00-e3i.Tests.ps1` | Modify | Lock the augmented E3-I protocol without making E3-I depend on E3-L semantics |
| `scripts/tests/phase00-e3a-e3h.Tests.ps1` | Modify | Permit E3-L's valid terminal states while dependencies and parallel state remain exact |
| `scripts/lib/phase00-evidence.ps1` | Modify | Add E3-L manifest/artifact fail-closed validation entry point |
| `scripts/validate-template.ps1` | Modify | Invoke E3-L durable validation through the existing single repository validator |
| `docs/evidence/phase-00/E3-I/fixture/.omp/tools/phase00-e3i-runtime-override.ts` | Modify | Return the fixed reader in both parent sessions and the fixed override only in Session A |
| `docs/evidence/phase-00/E3-I/fixture/prompts/session-a.md` | Modify | Exact reader/diagnostic/canary/override/reader/diagnostic/canary protocol |
| `docs/evidence/phase-00/E3-I/fixture/prompts/session-b.md` | Modify | Exact reader/diagnostic/canary CLI-overlay protocol with no override |
| `docs/evidence/phase-00/E3-L/source-identity.json` | Create statically | Seven-link pinned-source proof, host scope, exclusions, file hashes, and reader identity |
| `docs/evidence/phase-00/E3-L/raw/joint-attempt-*.json` | Create only in Task 9 | Additive joint attempt envelope and independent oracle statuses |
| `docs/evidence/phase-00/E3-L/selected-transaction.json` | Create only for complete selected attempt | Deterministic raw-input projection and L1-L3 observations |
| `docs/evidence/phase-00/E3-L/L1.json` | Create only after runtime adjudication | Project-false case linked to the selected projection |
| `docs/evidence/phase-00/E3-L/L2.json` | Create only after runtime adjudication | CLI-overlay case linked to the selected projection |
| `docs/evidence/phase-00/E3-L/L3.json` | Create only after runtime adjudication | Runtime-override case linked to the selected projection |
| `docs/evidence/phase-00/E3-L/conclusion.json` | Create only after runtime adjudication | Scoped terminal E3-L outcome, hashes, non-claims, and peer-review status |
| `docs/evidence/phase-00/E3-I/I1.yml` through `I4.yml` and `conclusion.yml` | Modify/create only from the same selected runtime transaction | Independent E3-I outcome; never consumed by E3-L |
| `docs/evidence/phase-00/manifest.yml` | Modify only after terminal runtime adjudication | Exact E3-I/E3-L terminal artifacts; E3-M and parallel state unchanged |
| `codex-phase00-execution-changelog-for-opus5.md` | Append | Exact English mutations, evidence, hashes, debugging, gates, and Opus challenge ledger |

## Interfaces and Locked Schemas

The shared transport layer exports:

| Function | Required parameters and types |
| --- | --- |
| `Get-Phase00E3ILToolEventPairs` | `[object[]] Events` |
| `Get-Phase00E3ILResultText` | `[object] ToolResult` |
| `Get-Phase00E3ILPropertyNames` | `[object] Object` |
| `Get-Phase00E3ILSummaryBranch` | `[string] Text` |
| `ConvertFrom-Phase00E3ILChildDiagnostic` | `[object] ToolResult` |
| `Get-Phase00E3ILTaskSample` | `[object] Pair`, `[string] ExpectedId` |
| `Get-Phase00E3ILCanarySession` | `[object[]] Events`, `[string] ExpectedId` |
| `Test-Phase00E3ILSessionTransport` | `[ValidateSet('A','B')] Session`, `[object[]] ParentEvents`, `[IDictionary] CanaryEvents`, `[bool] TimedOut` |
| `Test-Phase00E3ILSelectionEnvelope` | `[object] SessionTransport`, `[object] Boundary`, `[bool] LiveHomeMutationAttributable`, `[string] CleanupError` |

`Test-Phase00E3ILSelectionEnvelope` returns only `ELIGIBLE`, `INVALID_RUN`, or
`BLOCKED_ENVIRONMENT`; it never decides E3-I or E3-L semantic PASS/FAIL. Its exact future
parent sequences are:

```text
Session A: phase00_e3l_read_apply,bash,task,task,task,phase00_e3i_override_apply_true,phase00_e3l_read_apply,bash,task,task,task
Session B: phase00_e3l_read_apply,bash,task,task,task
```

The E3-L layer exports:

| Function | Required parameters and types |
| --- | --- |
| `Get-Phase00E3LSourceIdentity` | `[string] OmpSourceRoot` |
| `ConvertFrom-Phase00E3LReaderResult` | `[object] ToolResult` |
| `ConvertFrom-Phase00E3LOverrideResult` | `[object] ToolResult` |
| `Test-Phase00E3LSessionAOracle` | `[object] SessionTransport` |
| `Test-Phase00E3LSessionBOracle` | `[object] SessionTransport` |
| `Test-Phase00E3LTransaction` | `[object] SourceIdentity`, `[object] SessionA`, `[object] SessionB` |
| `New-Phase00E3LTransactionProjection` | `[object] Transaction`, `[object[]] RawInputs` |
| `Test-Phase00E3LDurableContract` | `[string] RepositoryRoot` |

The fixed reader returns exactly one text item and an identical `details` object with these
five properties and no others:

```json
{
  "probe": "phase00-e3l-live-reader-v1",
  "setting": "task.isolation.apply",
  "operation": "pi.pi.settings.get",
  "value": false,
  "scope": "parent-only"
}
```

`value` is a JSON boolean. The only legal alternate instance changes it to `true`. The exact
case oracle is:

| Case | Session/indexes | Reader | Child diagnostic | Three task branches |
| --- | --- | ---: | ---: | --- |
| L1 | A: reader 0, bash 1, tasks 2-4 | `false` | `false` | `APPLY_FALSE_CAPTURE_ONLY` |
| L2 | B: reader 0, bash 1, tasks 2-4 | `true` | `false` | `APPLY_TRUE_NO_DIFF` |
| L3 | A: override 5, reader 6, bash 7, tasks 8-10 | `true` | `false` | `APPLY_TRUE_NO_DIFF` |

---

### Task 1: Correct the normative E3-L contract and establish the RED harness

**Files:**

- Create: `scripts/tests/phase00-e3l.Tests.ps1`
- Modify: `spec/08-isolation-and-concurrency.md:428,570-609`
- Modify: `spec/13-validation-and-evaluation.md:156`
- Modify: `spec/phases/phase-00-foundation.md:530-621`
- Modify: `spec/phases/phase-02-core-orchestration.md:147,300`

**Interfaces:**

- Consumes: the approved design's host boundary, seven-link chain, and corrected case matrix.
- Produces: normative strings that every later artifact and test must match.

- [ ] **Step 1: Record the exact pre-edit authority state**

Run:

```powershell
Get-FileHash -Algorithm SHA256 `
  spec/08-isolation-and-concurrency.md, `
  spec/13-validation-and-evaluation.md, `
  spec/phases/phase-00-foundation.md, `
  spec/phases/phase-02-core-orchestration.md, `
  docs/evidence/phase-00/manifest.yml
git branch --show-current
git rev-parse HEAD
@(git diff --cached --name-only).Count
```

Expected: branch `main`, HEAD `62fecf277dc9d5e47d06319387eac747462214c1`, staged
count `0`. Record hashes for P00-CX-027; do not interpret the dirty worktree as disposable.

- [ ] **Step 2: Write the first failing E3-L contract tests**

Create `scripts/tests/phase00-e3l.Tests.ps1` with `#Requires -Version 5.1`, resolve the
repository root, conditionally dot-source `phase00-e3il-transport.ps1` and
`phase00-e3l-evidence.ps1`, and add one `Describe 'E3-L normative contract'` block that
asserts all of the following literal facts:

```text
pi.pi.settings.get("task.isolation.apply")
Settings.override("task.isolation.apply", true)
OMP-owned default main-CLI root-session
parallel_mode: DISABLED
```

It must also assert that the E3-L sections do not contain:

```text
change via /settings mid-session (Settings.set())
E3-L remains unresolved until an alternative public surface is designed and reviewed
source-verified for every supported host
```

- [ ] **Step 3: Run focused RED in PowerShell 7**

```powershell
Invoke-Pester scripts/tests/phase00-e3l.Tests.ps1 -PassThru
```

Expected: failure because the helper files are absent and the old normative E3-L text still
contains the impossible `/settings`/`Settings.set()` case.

- [ ] **Step 4: Apply the normative correction**

Make these precise changes:

1. In `spec/08`, replace the claim that `Settings.set()` writes the highest-precedence
   in-memory layer and never touches a file. State that `set()` updates the global layer and
   queues persistence, project `false` wins over global `true`, and `override()` is the
   non-persistent highest-precedence runtime layer.
2. In `spec/08` E3-L, select `pi.pi.settings` only for the OMP-owned default main-CLI
   root-session class; insert the seven positive source links and the ACP/SDK/injection/RPC
   exclusions; retain CR-45 and E3-M authority unchanged.
3. In Phase 00 E3-L, replace “unresolved replacement reader” with the same scoped reader,
   replace case 3 with the fixed `Settings.override()` transition, and replace universal
   host wording with the exact bounded host claim.
4. In specs 13 and phase 02, name the scoped proxy as diagnostic observation only and keep
   E3-M/equivalent as the guarded-dispatch gate.

- [ ] **Step 5: Run the normative tests again**

Expected: normative assertions pass; helper-availability assertions remain RED for Task 2.

- [ ] **Step 6: Reviewer gate**

Re-read all four changed normative sections. Reject any wording that says E3-L enables
parallel, that `Settings.set()` is non-persistent, or that the proxy is universal.

---

### Task 2: Build the shared raw-transport and selection envelope

**Files:**

- Create: `scripts/lib/phase00-e3il-transport.ps1`
- Modify: `scripts/tests/phase00-e3l.Tests.ps1`
- Modify: `scripts/lib/phase00-e3i-evidence.ps1`
- Modify: `scripts/tests/phase00-e3i.Tests.ps1`

**Interfaces:**

- Produces the shared transport functions listed above.
- Preserves every public `phase00-e3i-evidence.ps1` function currently used by its tests.
- Does not parse E3-L reader values or decide either experiment's semantic verdict.

- [ ] **Step 1: Add RED transport tests**

Add synthetic parent events for the exact Session A and B sequences. Assert:

- starts and ends pair once by `toolCallId`, in start order;
- duplicate, missing, reversed, renamed, errored, extra, and reordered calls are invalid;
- every reader and override invocation has exactly `{}` arguments;
- diagnostics retain the exact command and integer timeout `60`;
- every task remains a single-item isolated canary with the exact ID order;
- each canary has exact `[read,yield,hub]`, one conforming terminal `yield`, no other calls,
  no recovered provider error, and positive cost data;
- terminal provider capacity/auth failures map to `BLOCKED_ENVIRONMENT`;
- timeouts, recovered provider retries, incomplete Session B, and provenance defects map to
  `INVALID_RUN`;
- cleanup uncertainty, live-home activity, and boundary mutation make the transaction
  selection-ineligible without inventing E3-L semantics.

Run the E3-L and E3-I suites. Expected: RED because the shared functions and augmented
indexes do not exist.

- [ ] **Step 2: Implement the shared helper**

Move only transport-neutral mechanics into `phase00-e3il-transport.ps1`. Return ordered
objects with:

```text
Status: ELIGIBLE | INVALID_RUN | BLOCKED_ENVIRONMENT
Reasons: unique ordered reason codes
Session: A | B
Pairs: exact paired parent tools
Diagnostics: parsed child diagnostics
TaskSamples: parsed task rows and summary branches
CanarySessions: parsed child provenance
```

Use `E3IL_*` reason codes. `E3IL_PARENT_PROVIDER_*` and `E3IL_CANARY_PROVIDER_*` are
environment-blocking only when the existing terminal failure helper classifies them as
external. Use `E3IL_NESTED_PROVIDER_RECOVERY`, `E3IL_TIMEOUT`,
`E3IL_PARENT_SEQUENCE_MISMATCH`, `E3IL_EVENT_PAIRING_INVALID`,
`E3IL_CANARY_PROVENANCE_MISSING`, and `E3IL_BOUNDARY_INELIGIBLE` for invalid selection.

- [ ] **Step 3: Preserve E3-I compatibility while adopting the augmented indexes**

Keep existing E3-I function names as wrappers or semantic consumers. Change only the
future protocol indexes:

```text
Session A diagnostics: 1 and 7
Session A control tasks: 2,3,4
Session A override: 5
Session A runtime tasks: 8,9,10
Session B diagnostic: 1
Session B tasks: 2,3,4
```

E3-I may require reader calls to be present, paired, parameterless, and non-error. It must
not assert the reader's `value`, `probe`, or relation to task behavior; those are E3-L-only
semantics. Preserve the historical Attempt 1-4 adjudication files and tests without
reclassifying old raw transcripts under the augmented protocol.

- [ ] **Step 4: Run GREEN in both shells**

Run E3-L then E3-I under PowerShell 7 and Windows PowerShell 5.1. Expected: zero failures;
old Attempt 1-4 durable classifications remain byte-for-byte unchanged.

- [ ] **Step 5: Reviewer gate**

Confirm the shared layer has no `PASS`/`FAIL` branch for L1-L3 or I1-I4. It may decide only
whether raw evidence is selection-eligible.

---

### Task 3: Add the fixed reader and augment both disposable parent protocols

**Files:**

- Modify: `docs/evidence/phase-00/E3-I/fixture/.omp/tools/phase00-e3i-runtime-override.ts`
- Modify: `docs/evidence/phase-00/E3-I/fixture/prompts/session-a.md`
- Modify: `docs/evidence/phase-00/E3-I/fixture/prompts/session-b.md`
- Modify: `scripts/run-phase00-e3i.ps1`
- Modify: `scripts/tests/phase00-e3i.Tests.ps1`
- Modify: `scripts/tests/phase00-e3l.Tests.ps1`

**Interfaces:**

- Produces tool `phase00_e3l_read_apply` in both parent sessions.
- Produces tool `phase00_e3i_override_apply_true` only in Session A.
- Uses environment keys `OMP_PHASE00_E3IL_PARENT_CWD` and
  `OMP_PHASE00_E3IL_ENABLE_OVERRIDE` with exact values `1` or `0`.

- [ ] **Step 1: Write fixture RED tests**

Assert that a parent cwd with enable flag `1` receives exactly the reader and override, the
same parent cwd with flag `0` receives only the reader, and a different child cwd receives
`[]` in both cases. Assert the reader has empty parameters, `loadMode: "essential"`, no
mutation symbol in its execute body, and the locked five-field result. Assert Session B's
prompt forbids the override but requires the reader.

- [ ] **Step 2: Implement the factory**

Retain the existing path normalizer. Fail closed with `[]` unless the normalized factory cwd
equals `OMP_PHASE00_E3IL_PARENT_CWD`. Construct the reader first. Its execute function must
recheck the parent cwd, call `pi.pi.settings.get("task.isolation.apply")` exactly once, require
a boolean result, and return identical text/details. Throw
`P00_E3L_PARENT_SCOPE_MISMATCH` on scope drift and `P00_E3L_READER_NON_BOOLEAN` on a non-boolean
value. Add the existing override only when the enable flag is exactly `1`; any other value
omits it.

- [ ] **Step 3: Replace both prompts with the exact locked protocols**

Session A call order:

```text
read, diagnostic, e3i-project-1, e3i-project-2, e3i-project-3,
override, read, diagnostic, e3i-runtime-1, e3i-runtime-2, e3i-runtime-3,
final E3I_SESSION_A_DONE
```

Session B call order:

```text
read, diagnostic, e3i-cli-1, e3i-cli-2, e3i-cli-3,
final E3I_SESSION_B_DONE
```

Every read and override call uses `{}`. Preserve the exact bash and task argument objects.

- [ ] **Step 4: Update the session runner without launching OMP**

Set `OMP_PHASE00_E3IL_PARENT_CWD` to the disposable project for both sessions. Set the
enable flag to `1` for A and `0` for B. Record only redacted values in schema-version-2 future
run records. Preserve schema-version-1 raw attempts. Do not invoke
`Invoke-Phase00E3IEvidenceSession` during this task.

- [ ] **Step 5: Run loader, environment, prompt, and protocol tests in both shells**

Use the preserved backup executable only for local loader/version tests; do not pass a model
prompt. Expected: both suites green, no raw attempt file created, live OMP home unchanged.

- [ ] **Step 6: Reviewer gate**

Search the reader execute path for `.set(`, `.override(`, `flush`, `save`, `bash`, `spawn`,
`write`, and user-supplied parameters. The reader must contain none. The separate override
must retain its existing exact non-persistent attestation.

---

### Task 4: Implement and capture the pinned seven-link source identity

**Files:**

- Create: `scripts/lib/phase00-e3l-evidence.ps1`
- Modify: `scripts/tests/phase00-e3l.Tests.ps1`
- Create: `docs/evidence/phase-00/E3-L/source-identity.json`

**Interfaces:**

- Consumes the clean nested clone `_research/upstreams/oh-my-pi`.
- Produces `Get-Phase00E3LSourceIdentity` and one deterministic source artifact.

- [ ] **Step 1: Write source-audit RED tests**

Build OS-temporary synthetic source trees and assert rejection of: wrong Git commit, dirty
tree, wrong remote, missing export, `Settings.init()` not assigning/returning the global,
main CLI using injected settings, session options not receiving the instance, SDK replacing
an explicit instance, dispatch reading a different key, proxy not binding to the global,
missing ACP/clone/injection exclusions, and source paths escaping the audited root.

- [ ] **Step 2: Implement exact source checks**

Verify Git HEAD, clean status, and official origin first. Then verify all seven positive
links and four exclusion groups from the design by exact source path, expected line range,
and syntax pattern. Record actual line numbers and SHA-256 for each complete source file.
Return `FAIL` on a complete source contradiction and `INVALID_RUN` on inaccessible/ambiguous
source. The supported-host declaration must be exactly:

```text
OMP-owned default main-CLI root-session construction class
```

- [ ] **Step 3: Generate the source artifact mechanically**

Run a reviewed writer function over:

```powershell
$sourceRoot = (Resolve-Path '_research/upstreams/oh-my-pi').Path
$identity = Get-Phase00E3LSourceIdentity -OmpSourceRoot $sourceRoot
if ($identity.Status -ne 'PASS') { throw "E3-L source identity failed: $($identity.Status)" }
```

Write UTF-8 without BOM to `docs/evidence/phase-00/E3-L/source-identity.json`. The JSON must
contain schema version, experiment, status, runtime version, pinned commit, supported host,
reader operation, seven positive links, exclusions, full-file hashes, and explicit
non-claims. Sanitize absolute paths to repository-relative paths before writing.

- [ ] **Step 4: Re-read and re-audit the created artifact**

Parse JSON, re-hash every cited source file, and confirm exactly seven positive links. Assert
ACP, cloneForCwd, SDK injection, dependency injection, RPC, and RPC-UI are excluded. Assert
no real absolute path or credential material exists.

- [ ] **Step 5: Reviewer gate**

Reject the artifact if it says `all sessions`, `all OMP hosts`, `universal`, or treats
runtime observation as a substitute for any source link.

---

### Task 5: Implement the independent E3-L reader and L1-L3 oracle

**Files:**

- Modify: `scripts/lib/phase00-e3l-evidence.ps1`
- Modify: `scripts/tests/phase00-e3l.Tests.ps1`

**Interfaces:**

- Consumes only source identity, shared selection envelope, and raw-derived session objects.
- Produces the E3-L functions in the interface block and no E3-I conclusion dependency.

- [ ] **Step 1: Add exact reader parser RED tests**

Test one false and one true five-field result. Reject missing/extra properties, string
booleans, wrong probe/key/operation/scope, multiple/no text items, text/details divergence,
errored tool completion, non-empty invocation arguments, and arbitrary setting names.

- [ ] **Step 2: Implement `ConvertFrom-Phase00E3LReaderResult`**

Sort property names and require exactly `operation,probe,scope,setting,value`. Parse the
single text item as JSON, require the same exact shape and value equality with `details`, and
return `PASS` with the boolean value. Structural ambiguity is `INVALID_RUN /
E3L_READER_EVIDENCE_INVALID`; an attributable complete wrong probe/value/shape is `FAIL /
E3L_READER_CONTRADICTION`.

- [ ] **Step 3: Add Session A/B and transaction RED tests**

Use synthetic raw parent and canary events, not an E3-I conclusion. Verify the exact L1-L3
matrix and these negative controls:

```text
wrong reader value
reader agrees with child but disagrees with task branch
reader agrees with branch but child is true
one wrong task summary among three
wrong override attestation or persistence flag
cross-attempt A/B records
wrong OMP version/hash
wrong or unsupported host
partial Session B
provider terminal failure
recovered provider retry
canary surface contamination
repository/live-home/fixture/cleanup boundary breach
source identity failure
```

- [ ] **Step 4: Implement separate Session A and Session B oracles**

Session A produces L1 and L3 only. Session B produces L2 only. The override attestation is
independently parsed by E3-L and must remain false-to-true, operation
`pi.pi.settings.override`, `calledSet:false`, `calledFlushOrSave:false`, parent-only. Do not
call an E3-I semantic function.

- [ ] **Step 5: Implement transaction conjunction and outcome precedence**

Apply this exact order:

1. inaccessible/ambiguous source identity or raw structural defect → `INVALID_RUN`;
2. shared terminal external failure → `BLOCKED_ENVIRONMENT`;
3. wrong runtime identity or selection/atomicity/boundary defect → `INVALID_RUN`;
4. complete attributable pinned-source, reader, or case contradiction → `FAIL`;
5. all seven source links plus L1-L3 exact → `PASS`.

The PASS claim string must be exactly:

```text
The approved proxy observes live effective task.isolation.apply for the OMP-owned default main-CLI root-session class on pinned 17.2.10.
```

- [ ] **Step 6: Prove verdict independence**

Add tests where the same raw transaction yields E3-L PASS/E3-I FAIL and E3-L FAIL/E3-I PASS.
Assert no E3-L function opens `E3-I/conclusion.yml` and no E3-I function opens an E3-L
conclusion.

- [ ] **Step 7: Run both focused suites in both shells**

Expected: zero failures and identical reason/status semantics.

- [ ] **Step 8: Reviewer gate**

Trace L1, L2, and L3 from raw synthetic events through the shared eligibility envelope and
the E3-L oracle. Confirm no verdict, observation, or hash is imported from E3-I interpreted
evidence.

---

### Task 6: Build the additive joint attempt runner without making a provider call

**Files:**

- Create: `scripts/run-phase00-e3l-joint.ps1`
- Modify: `scripts/run-phase00-e3i.ps1`
- Modify: `scripts/tests/phase00-e3l.Tests.ps1`

**Interfaces:**

- CLI parameters: `Attempt` range 5-999, `Model`, `OmpExecutable`.
- Function test seam: `Invoke-Phase00E3ILJointAttempt` also accepts a mandatory internal
  `SessionInvoker` scriptblock when dot-sourced; the direct script entry point supplies the
  real E3-I session invoker.
- Produces `docs/evidence/phase-00/E3-L/raw/joint-attempt-{NNN}.json` only during authorized
  runtime execution.

- [ ] **Step 1: Add mocked-runner RED tests**

With an injected scriptblock, assert A runs before B, both receive the same attempt/model and
exact runtime path, B is skipped after A `INVALID_RUN` or `BLOCKED_ENVIRONMENT`, B continues
after an attributable experiment-specific semantic `FAIL`, no existing file is overwritten,
attempts below 5 are rejected, and a second invocation never becomes an implicit retry.

- [ ] **Step 2: Implement the joint orchestration**

Before A, verify the selected executable reports `omp/17.2.10` and matches the normative
SHA-256. Check collisions for every A/B E3-I raw destination and E3-L joint destination.
Invoke A once. Run shared selection eligibility. Invoke B once only if A is selection-eligible
or contains a complete experiment-semantic contradiction that does not breach shared
atomicity. Never retry inside the function.

- [ ] **Step 3: Write the joint record deterministically**

The record includes schema version, attempt, selected false until adjudication, exact runtime
identity, source-identity path/hash, A/B run paths and hashes, every parent/canary raw path and
hash, transport eligibility, E3-I status, E3-L status, provider/retry facts, boundary facts,
and `e3_i_conclusion_consumed:false` / `e3_l_conclusion_consumed:false`. Sanitize absolute
paths and write UTF-8 without BOM.

- [ ] **Step 4: Run only mocked tests**

Do not invoke the script entry point. Expected: all runner tests green, zero new E3-I/E3-L
raw files, zero provider call, no temporary root left.

- [ ] **Step 5: Reviewer gate**

Inspect every call site and prove there is no automatic retry loop, no overwrite switch, no
cross-attempt lookup, and no path from one experiment's conclusion into the other's oracle.

---

### Task 7: Add deterministic projection and fail-closed repository validator wiring

**Files:**

- Modify: `scripts/lib/phase00-e3l-evidence.ps1`
- Modify: `scripts/tests/phase00-e3l.Tests.ps1`
- Modify: `scripts/lib/phase00-evidence.ps1`
- Modify: `scripts/validate-template.ps1`
- Modify: `scripts/tests/phase00-e3a-e3h.Tests.ps1`
- Modify: `docs/superpowers/specs/2026-08-09-phase-00-e3l-live-session-reader-design.md`

**Interfaces:**

- Produces deterministic selected transaction and case/conclusion validation.
- Leaves manifest E3-L `READY` with `artifacts: []` during static implementation.

- [ ] **Step 1: Add RED durable-contract tests**

Assert the validator accepts E3-L `READY` with a valid unlisted source identity and no runtime
artifacts. For terminal E3-L states, assert rejection of missing conclusion, missing L1-L3 on
PASS/FAIL, selected false, bad raw hash, mismatched attempt, wrong host, wrong runtime, absent
source identity, non-disabled parallel mode, E3-M state drift, circular conclusion reference,
and unresolved incomplete-work markers.

- [ ] **Step 2: Implement deterministic projection**

`New-Phase00E3LTransactionProjection` must sort raw inputs by repository-relative path,
re-hash each file, copy only parsed observations, and include L1-L3 rows, source identity hash,
runtime identity, host scope, transport facts, boundaries, and independent oracle statuses.
It must never copy a transcript wholesale or accept a caller-supplied observation value.

- [ ] **Step 3: Add `Test-Phase00E3LArtifactContract` to the Phase 00 validator layer**

When E3-L is `READY`, verify only that no terminal artifact is claimed. When E3-L is
`BLOCKED_ENVIRONMENT`, require a complete joint adjudication and conclusion. When E3-L is
`PASS` or `FAIL`, require source identity, selected transaction, L1-L3, and conclusion; parse
all JSON and re-hash every reference. Always assert E3-M deferred and root parallel disabled.

- [ ] **Step 4: Wire the validator and relax only the stale E3-A/H expectation**

Add `Test-Phase00E3LArtifactContract` to the existing validator array. In the E3-A/H suite,
replace the exact E3-L `READY` assertion with membership in
`READY,PASS,FAIL,BLOCKED_ENVIRONMENT`; retain exact dependency and parallel assertions.

- [ ] **Step 5: Update the E3-L design status**

Record “static implementation complete; runtime adjudication pending explicit
authorization,” list source-identity hash and implemented file paths, and state manifest
remains READY. Do not claim a runtime outcome.

- [ ] **Step 6: Run focused and complete static gates**

Run E3-L, E3-I, E3-A/H, Wave A, E3-J/K, and the repository validator in both shells under a
process-local hash-verified 17.2.10 copy. Expected: zero failures/warnings; no provider call;
manifest E3-L remains READY, E3-I remains its existing blocked state, E3-M remains deferred.

- [ ] **Step 7: Reviewer gate**

Mutate a temporary manifest/artifact fixture through every terminal E3-L state and verify the
single repository validator fails each incomplete or hash-incoherent state. Confirm READY
does not acquire runtime authority merely because source identity exists.

---

### Task 8: Static implementation audit, P00-CX-027, and mandatory provider stop

**Files:**

- Append: `codex-phase00-execution-changelog-for-opus5.md` as P00-CX-027
- Modify only if verification proves an E3-L-owned defect: files in Tasks 1-7

- [ ] **Step 1: Run static integrity scans**

Verify all authored PowerShell parses in both shells; TypeScript fixture loads under pinned
OMP without a model prompt; every JSON parses; every hash matches; no absolute disposable
path, credential value, trailing whitespace, unbalanced Markdown fence, or incomplete-work
marker exists; `git diff --check` succeeds; staged count is zero; source clone is pinned and
clean; no `omp-phase00-e3i-*` or `omp-phase00-e3l-*` temporary root remains.

- [ ] **Step 2: Append exhaustive P00-CX-027 in English**

Record predecessor changelog hash; user-approved design/plan; every file and exact
before/after hash; every RED/GREEN/debugging cycle; source link/file hashes; exact fixed tool
schemas; transport/oracle independence; cross-shell focused/full totals; validator totals;
manifest non-transition; installed 17.2.12 versus normative 17.2.10; zero provider calls; no
Git integration; explicit non-claims; and Opus challenge targets.

- [ ] **Step 3: Re-run complete gates after the changelog append**

Documentation bytes can break scans. Repeat Task 7.6 and Task 8.1. Report the final changelog
hash outside the self-referential entry.

- [ ] **Step 4: Stop and request user authorization**

Do not begin Task 9 merely because Tasks 1-8 are green. Report that static implementation is
ready and ask for one explicit provider-backed Attempt 5 authorization.

- [ ] **Step 5: Reviewer gate**

Compare the P00-CX-027 file ledger against `git status --short` and the responsibility map.
Confirm every changed byte is covered, the final log hash is reported externally, and the
handoff contains no language that authorizes Task 9 implicitly.

---

### Task 9: Execute exactly one joint provider attempt after separate authorization

**Files created mechanically:**

- `docs/evidence/phase-00/E3-I/raw/session-a-attempt-005.*`
- `docs/evidence/phase-00/E3-I/raw/session-b-attempt-005.*` only if continuation is eligible
- `docs/evidence/phase-00/E3-L/raw/joint-attempt-005.json`

- [ ] **Step 1: Re-establish the external-state and static gates**

Confirm gateway/model availability without exposing credentials, verify the preserved binary
at
`C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak` hashes to the normative
value, verify the pinned source clone, run the full two-shell gate, confirm no Attempt 5
destination exists, and snapshot live-home/repository state.

- [ ] **Step 2: Launch one joint attempt**

Run exactly:

```powershell
& scripts/run-phase00-e3l-joint.ps1 `
  -Attempt 5 `
  -Model 'omniroute/codex/gpt-5.6-sol-high' `
  -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
```

The runner copies the binary into its verified temporary root; it never replaces the live
installed executable. Session A runs once. Session B runs once only when the shared
continuation gate permits it.

- [ ] **Step 3: Classify without retry**

- Terminal provider/auth/capacity failure: `BLOCKED_ENVIRONMENT`; preserve partial raw and
  stop.
- Protocol, recovered retry, missing provenance, timeout, cleanup uncertainty, or incomplete
  Session B: `INVALID_RUN`; preserve raw, keep manifest E3-L READY, add regression before any
  separately authorized retry.
- Complete attributable contradiction: selection-eligible semantic `FAIL`; do not retry it
  into PASS.
- Complete exact transaction: selection-eligible for independent E3-I and E3-L adjudication.

- [ ] **Step 4: Verify post-run boundaries before interpretation**

Require unchanged live home, official repository HEAD/status/content snapshot, disposable
fixture hashes except reviewed session output roots, successful exact cleanup, matching raw
hashes, zero credential leakage, and no recovered provider error. A boundary defect has no
PASS power.

- [ ] **Step 5: Report the raw outcome before materializing terminal evidence**

Tell the user whether the joint attempt is blocked, invalid, complete-fail, or complete and
selection-eligible. Do not launch Attempt 6 in the same authorization.

- [ ] **Step 6: Reviewer gate**

Recompute every Attempt 5 hash from disk, compare the live-home/repository before/after
snapshots, and verify Session B shares the same attempt and runtime identity. Do not proceed
to Task 10 if any fact is inferred only from model prose.

---

### Task 10: Materialize independent terminal outcomes and perform provisional closure

**Files:**

- Create/modify the runtime artifacts listed in the responsibility map
- Modify: `docs/evidence/phase-00/manifest.yml`
- Modify: both E3-I and E3-L design status sections
- Append: `codex-phase00-execution-changelog-for-opus5.md` as P00-CX-028

- [ ] **Step 1: Create the selected projection only from a complete transaction**

Run both independent oracles over raw events, then mechanically write
`selected-transaction.json` with `selected:true`. Re-hash all raw inputs after writing. If the
transaction is blocked/invalid, do not create a selected projection.

- [ ] **Step 2: Materialize L1-L3 and conclusion**

Each case JSON must hash-link the selected projection and copy its own exact reader,
diagnostic, three task branches/summaries, session/attempt, and boundary facts. The conclusion
must hash-link source identity, projection, L1-L3, state the bounded PASS claim only on PASS,
name every exclusion/non-claim, set `parallel_authorized:false`,
`parallel_mode_after:"DISABLED"`, `e3_m_replaced:false`, and
`opus_peer_review:"PENDING_QUOTA"`.

- [ ] **Step 3: Adjudicate E3-I independently**

Create/update I1-I4 and E3-I conclusion from the same raw transaction using only the E3-I
oracle. Do not cite E3-L PASS as evidence. E3-I may PASS or FAIL independently and remains
non-authoritative for parallel execution.

- [ ] **Step 4: Make exact manifest transitions**

- E3-L PASS/FAIL: list source identity, selected transaction, L1-L3, and conclusion.
- E3-L BLOCKED_ENVIRONMENT: list only complete joint adjudication and conclusion.
- E3-L INVALID_RUN: retain `READY`, `artifacts: []`, and preserve raw unselected history.
- E3-I complete PASS/FAIL/BLOCKED_ENVIRONMENT: transition independently to that actual
  terminal state/artifacts.
- E3-I INVALID_RUN: preserve its prior Attempt 4 `BLOCKED_ENVIRONMENT` terminal state and
  artifacts, append Attempt 5 only to invalid attempt history, and never invent a manifest
  state for INVALID_RUN.
- E3-M: retain `DEFERRED_PARALLEL_DISABLED` and unchanged decision.
- Root `parallel_mode`: retain `DISABLED`.

- [ ] **Step 5: Run final cross-shell closure verification**

Run every Phase 00 suite including E3-L and the repository validator under pinned 17.2.10 in
PowerShell 7 and Windows PowerShell 5.1. Re-parse JSON/YAML/JSONL, re-hash every cited file,
scan paths/secrets/temp roots, run `git diff --check`, and confirm zero staged files.

- [ ] **Step 6: Append P00-CX-028 and re-run all gates**

Record every provider/raw/artifact observation and hash, independent E3-I/E3-L verdicts,
manifest transitions, safety boundaries, test totals, non-claims, and exact Opus review
questions. Re-run all checks after the entry. Report the final self-referential changelog hash
outside the log.

- [ ] **Step 7: State provisional, not joint, closure**

If E3-L PASS, say Codex provisionally closes only the scoped E3-L experiment; Phase 00 and
parallel enablement remain open behind E3-M and Opus review. If FAIL/BLOCKED/INVALID, state the
exact unresolved condition without softening it.

- [ ] **Step 8: Reviewer gate**

Start from the final manifest and follow every E3-I/E3-L artifact and hash back to raw files.
Confirm the two verdicts are independently reproducible, E3-M and parallel mode are
unchanged, and the changelog gives Opus enough exact locations to challenge every mutation.

---

## Execution Stop Conditions

Stop and report evidence when any of these occurs:

- source HEAD/remote/cleanliness or runtime version/hash differs from the exact pin;
- an official-workspace Git mutation or overlapping user-owned edit cannot be preserved;
- the reader exposes an arbitrary key/value, mutation, subprocess, file write, or persistence
  path;
- either parent-only fixture tool appears in any canary child surface;
- a provider call would occur before separate Task 9 authorization;
- Session B would combine with a different attempt or an ineligible Session A;
- any retry would overwrite or reinterpret Attempts 1-5;
- source or runtime evidence claims ACP, injected SDK, cloned settings, RPC, RPC-UI, or a
  universal host;
- live OMP home, official repository, fixture, or cleanup boundaries are uncertain;
- one experiment's conclusion is used to determine the other's verdict;
- manifest terminal state cannot be supported by complete hash-linked artifacts;
- E3-M or root parallel mode would change.

Provider quota/auth/overload is `BLOCKED_ENVIRONMENT`. Harness/protocol/provenance/retry/
ordering/cleanup defects are `INVALID_RUN`. A complete attributable wrong source link,
reader value, diagnostic relation, or L1-L3 branch is semantic `FAIL` and must not be retried
away.

## Plan Completion Definition

The implementation plan is complete when Tasks 1-8 are statically green and recorded, and—
only after separate authorization—one terminal Task 9/10 outcome is preserved, independently
adjudicated, hash-linked, cross-shell verified, and recorded for Opus. E3-L PASS closes only
the scoped observational experiment. Phase 00 remains in progress, E3-M remains unresolved,
parallel mode remains disabled, and joint Codex/Opus closure remains pending quota.
