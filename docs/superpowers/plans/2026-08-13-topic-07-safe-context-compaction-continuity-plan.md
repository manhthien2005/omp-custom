# Topic 07 Safe Context Compaction and Continuity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one fail-closed `/safe-compact` path to the managed OMP runtime while keeping every
automatic semantic-compaction path disabled and preserving task identity, authority, acceptance
criteria, locked decisions, current work, and recovery bindings across the native compaction.

**Architecture:** Topic 04 remains the durable reducer and gains an explicit continuity contract
plus an exact-current-session kernel projection. A dependency-light JavaScript core validates and
hashes that projection. A separate final trusted OMP extension owns the command, authorization
nonce, recovery artifact, native lifecycle hooks, pressure guard, and one-time post-compaction
kernel injection. Topic 07 upgrades the existing managed `agent-boundary` install component to a
closed v2 runtime contract; it does not merge continuity behavior into the Topic 06 `task` wrapper.

**Tech Stack:** dependency-free ESM on Node 24; OMP 17.2.10/17.2.12 extension APIs; PowerShell
7.4+ Topic 04 reducer; JSON/YAML manifests and settings; Node `node:test`; standalone PowerShell
test runners; local model-free OMP/RPC canaries; Git read-only checks only.

**Spec:**
`docs/superpowers/specs/2026-08-13-topic-07-context-compaction-continuity-design.md`

## Global Constraints

- Preserve all pre-existing dirty-worktree changes. Never reset, revert, clean, or overwrite an
  unrelated path.
- Work remains local. Do not create or switch a branch/worktree, stage, commit, push, or open a
  pull request. Every task ends with a read-only local checkpoint instead of a commit.
- Execute inline and sequentially by default. Do not spawn a subagent unless the user later selects
  subagent-driven execution and the individual task is genuinely independent.
- Do not make a provider/model call and do not launch an OMP task agent during deterministic
  verification. Local fake-provider listeners may prove that a forbidden request was never sent.
- Treat `_research/upstreams/oh-my-pi` as immutable runtime authority. Source-attachment tests may
  read it and hash it but may not edit it or install dependencies into it.
- Topic 04 remains sole durable task/candidate/evidence/handoff authority. A compaction summary,
  recovery artifact, epoch entry, metric, or injected kernel never accepts work or mutates task
  semantics.
- Topic 06 remains the sole managed task-dispatch wrapper. Topic 07 may share the bounded state-CLI
  transport and must classify pressure aborts, but it must not absorb packet/result composition.
- Automatic context promotion, semantic compaction, idle/mid-turn compaction, auto-continuation,
  remote compaction, shake, snapcompact, and automatic handoff remain disabled or unselected.
- `/safe-compact` calls native `ctx.compact({ mode: "soft" })` exactly once. Topic 07 adds no model
  retry outside OMP's bounded candidate handling inside that one native transaction.
- The Topic 07 extension is the final trusted extension and sole managed owner of
  `session.compacting`. An unprovable load order is a startup refusal.
- A missing/changed runtime seam, swallowed-handler ambiguity, or failed provider-abort canary is a
  promotion blocker, not permission to weaken the contract. Record it as `OPEN-T07-RUNTIME-*`, keep
  automatic compaction off, leave the adapter unpromoted, and continue only with work that remains
  valid independently. Opus is optional, never mandatory, for resolving such a blocker.
- All saved session artifacts and metrics stay under OMP's local persisted-session storage. No
  transcript, recovery artifact, or metric is written into Git by the runtime.

---

## File and Ownership Map

### New implementation files

- `template/.omp/contracts/managed-state-client.mjs` — shared bounded Topic 04 CLI transport used
  by the Topic 06 wrapper and Topic 07 adapter.
- `template/.omp/contracts/context-continuity-schema.mjs` — closed limits, enums, profile, reason
  codes, and allowed record shapes.
- `template/.omp/contracts/context-continuity-core.mjs` — canonical kernel validation, hashing,
  pressure calculation, recovery/preserve-data binding, and safe observation envelopes.
- `template/.omp/extensions/context-continuity.js` — final OMP command/lifecycle adapter.
- `scripts/lib/topic07-context-continuity.ps1` — focused validator/source-attachment helpers.
- `scripts/validate-topic07-context-continuity.ps1` — focused validator entry point.
- `scripts/capture-topic07-evidence.ps1` — deterministic local evidence capture.
- `docs/context-continuity.md` — operator guide.
- `codex-topic07-context-compaction-continuity-changelog.md` — local implementation/verification
  record.
- `docs/evidence/current-product/topic-07/deterministic.json` and `manifest.json` — generated
  model-free evidence.

### New focused tests and fixtures

- `scripts/tests/topic07-managed-state-client.Tests.mjs`
- `scripts/tests/topic07-continuity-core.Tests.mjs`
- `scripts/tests/topic07-state-contract.Tests.ps1`
- `scripts/tests/topic07-state-projection.Tests.ps1`
- `scripts/tests/topic07-omp-adapter.Tests.mjs`
- `scripts/tests/topic07-safe-compact.Tests.mjs`
- `scripts/tests/topic07-pressure-guard.Tests.mjs`
- `scripts/tests/topic07-managed-runtime.Tests.ps1`
- `scripts/tests/topic07-pressure-canary.Tests.ps1`
- `scripts/tests/topic07-validator-mutations.Tests.ps1`
- `scripts/tests/fixtures/topic07-omp-runtime-probe.mjs`
- `scripts/tests/fixtures/topic07-provider-sentinel.mjs`

### Existing implementation surfaces to modify

- Topic 04: `template/.omp/state/agent-tasks.ps1`,
  `template/.omp/state/lib/AgentTasks.Common.ps1`,
  `template/.omp/state/lib/AgentTasks.Lifecycle.ps1`,
  `template/.omp/state/lib/AgentTasks.Projection.ps1`,
  `template/.omp/state/lib/AgentTasks.Store.ps1`,
  `template/.omp/state/schemas/agent-tasks-v1.schema.json`,
  `template/.omp/state/PROTOCOL.md`, and `template/.omp/state/manifest.json`.
- Topic 06/runtime: `template/.omp/extensions/agent-task-boundary.js`,
  `template/.omp/contracts/managed-runtime.yml`,
  `template/.omp/contracts/component-manifest.json`, and
  `template/.omp/bin/omp-managed.ps1`.
- Installation: `scripts/install-template.ps1`, `scripts/uninstall-template.ps1`,
  `scripts/validate-template.ps1`, `scripts/lib/topic06-agent-boundary.ps1`, and affected Topic 04/
  Topic 06 installer/runtime tests.
- Authority/docs: only the load-bearing files named in Task 9.

### Read-only source attachments

- `_research/upstreams/oh-my-pi/packages/agent/src/compaction/compaction.ts`
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/config/settings-schema.ts`
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/session/compact-modes.ts`
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/session/session-maintenance.ts`
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/session/session-manager.ts`
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/session/agent-session.ts`
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/extensibility/shared-events.ts`
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/extensibility/extensions/types.ts`
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/extensibility/extensions/runner.ts`
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/task/executor.ts`

---

### Task 1: Extract one bounded managed-state client without changing Topic 06 behavior

**Files:**

- Create: `template/.omp/contracts/managed-state-client.mjs`
- Modify: `template/.omp/extensions/agent-task-boundary.js`
- Create: `scripts/tests/topic07-managed-state-client.Tests.mjs`
- Modify: `scripts/tests/topic06-omp-wrapper.Tests.mjs`

**Public interface:**

```js
export function getManagedSessionRef(ctx) -> non-empty string | safe throw
export function parseManagedStateEnvelope(text) -> closed state envelope | safe throw
export async function invokeManagedState({
  pwshPath,
  stateCliPath,
  operation,
  request,
  ctx,
  signal,
  timeoutMs = 30_000,
  outputLimitBytes = 131_072,
}) -> parsed Topic 04 envelope
```

- [ ] **Step 1: Write the failing transport tests**

Cover exact `ctx.sessionManager.getSessionId()` propagation; absolute working directory; runtime
fixed to `omp`; canonical single-document request; a unique temp directory; stdout/stderr byte
caps; timeout; abort; nonzero exit; malformed/duplicate/extra output lines; closed success/failure
envelopes; safe diagnostics that contain neither raw state nor request contents; and verified temp
cleanup constrained to the created temp root.

- [ ] **Step 2: Run RED**

```powershell
node --test scripts/tests/topic07-managed-state-client.Tests.mjs
```

Expected: nonzero because `managed-state-client.mjs` does not yet exist. A skipped test is not RED.

- [ ] **Step 3: Implement the shared client and refactor Topic 06 to use it**

Move only the bounded process/envelope/session-reference transport from
`agent-task-boundary.js`. Keep Topic 06 runtime validation, request composition, native delegation,
and receipt reconciliation in the Topic 06 wrapper. The shared client must import canonical JSON
and duplicate-safe parsing from `agent-boundary-core.mjs`; it must not introduce a second parser or
state authority.

- [ ] **Step 4: Prove behavior-preserving GREEN**

```powershell
node --test scripts/tests/topic07-managed-state-client.Tests.mjs scripts/tests/topic06-omp-wrapper.Tests.mjs
pwsh -NoProfile -File scripts/tests/topic06-agent-boundary.Tests.ps1
git diff --check -- template/.omp/contracts/managed-state-client.mjs template/.omp/extensions/agent-task-boundary.js scripts/tests/topic07-managed-state-client.Tests.mjs scripts/tests/topic06-omp-wrapper.Tests.mjs
git status --short -- template/.omp/contracts/managed-state-client.mjs template/.omp/extensions/agent-task-boundary.js scripts/tests/topic07-managed-state-client.Tests.mjs scripts/tests/topic06-omp-wrapper.Tests.mjs
```

Expected: all tests pass; Topic 06 receipts are byte-for-byte stable for existing fixtures; only the
four intended paths appear. Do not stage or commit them.

---

### Task 2: Build the portable continuity schema and core

**Files:**

- Create: `template/.omp/contracts/context-continuity-schema.mjs`
- Create: `template/.omp/contracts/context-continuity-core.mjs`
- Create: `scripts/tests/topic07-continuity-core.Tests.mjs`

**Frozen limits:**

```js
export const CONTINUITY_LIMITS = Object.freeze({
  maxKernelBytes: 16_384,
  maxRecoveryArtifactBytes: 262_144,
  maxMetricBytes: 4_096,
  maxDepth: 12,
  maxArrayItems: 128,
  maxStringBytes: 4_096,
  maxLockedDecisions: 64,
  maxBranchEntries: 4_096,
  maxDegradedFields: 8,
  nonceTtlMs: 120_000,
});
```

**Public interface:**

```js
export { canonicalJson, sha256Canonical } from "./agent-boundary-core.mjs";
export function validateContinuityKernel(value) -> validation envelope
export function validateContinuityProjection(value) -> validation envelope
export function buildContinuityKernel(projection) -> { ok, kernel, canonical, sha256, utf8_bytes }
export function resolvePressureBoundary({ tokens, contextWindow, reserveTokens }) -> {
  reserveTokens, thresholdTokens, atOrAbove
}
export function buildRecoveryArtifact(input) -> closed canonical artifact
export function buildPreserveData(input) -> closed `omp_template.topic07` payload
export function validatePreserveData(input, expected) -> validation envelope
export function buildKernelMessage(kernel) -> hidden custom-message value
export function buildObservation(input) -> bounded transcript-free metric
```

- [ ] **Step 1: Write failing closed-schema and canonicalization tests**

Cover the exact kernel shape from the approved spec; unknown properties at every level; duplicate
decision/evidence IDs; malformed SHA-256; invalid workflow class; critical-field absence; explicit
null versus unavailable secondary fields; Quick named degradation; Standard/Orchestrated refusal;
NFC/LF normalization; stable ordinal key ordering; hash exclusion of only `kernel_sha256`; nested
depth/item/string/byte limits; transcript/tool-history/reasoning/credential/private-path property
names; credential signatures; and exact 16 KiB rejection without truncation.

The locked-decision item is exactly:

```js
{
  decision_id: string,      // `D-` plus 1..64 uppercase alphanumeric/period/underscore/hyphen
  statement: string,        // non-empty, at most 2048 UTF-8 bytes
  authority_ref: string,    // non-empty, at most 512 UTF-8 bytes
}
```

Normalize `locked_decisions` by ordinal `decision_id` and reject duplicates. Preserve semantic
order for acceptance criteria, obligations, blockers, risks, and authority. Sort only fields whose
contract is explicitly set-like: write scope, evidence bindings, and degraded field names.

- [ ] **Step 2: Freeze and test the exact pressure formula**

Implement the pinned OMP formula, including its small-window default-reserve recovery:

```js
const proportional = Math.max(1, Math.floor(contextWindow * 0.15));
const initial = Math.max(Math.floor(contextWindow * 0.15), reserveTokens ?? 16_384);
const defaultImpossible = reserveTokens === undefined && initial >= contextWindow - proportional;
const resolved = defaultImpossible || initial >= contextWindow ? proportional : initial;
const threshold = Math.max(1, Math.min(contextWindow - 1, contextWindow - resolved));
```

Test tiny, 8K, 16K, 32K, 128K, 200K, and 1M windows; unset versus explicit 16384 reserve; invalid
negative/non-integer usage; exact threshold equality; and one-token-below behavior.

- [ ] **Step 3: Run RED**

```powershell
node --test scripts/tests/topic07-continuity-core.Tests.mjs
```

Expected: nonzero because the continuity modules do not exist.

- [ ] **Step 4: Implement the core and safe envelopes**

Reuse the Topic 06 canonical JSON and SHA-256 implementation by import/re-export. Keep OMP, the
filesystem, clocks, randomness, and process execution outside this core. Require callers to supply
time/nonce hashes/branch identities. Return bounded reason codes; never include raw input, kernel,
path, nonce, stack, or provider payload in a failure message.

- [ ] **Step 5: Run GREEN and a no-Git checkpoint**

```powershell
node --test scripts/tests/topic07-continuity-core.Tests.mjs scripts/tests/topic06-contract-core.Tests.mjs
git diff --check -- template/.omp/contracts/context-continuity-schema.mjs template/.omp/contracts/context-continuity-core.mjs scripts/tests/topic07-continuity-core.Tests.mjs
git status --short -- template/.omp/contracts/context-continuity-schema.mjs template/.omp/contracts/context-continuity-core.mjs scripts/tests/topic07-continuity-core.Tests.mjs
```

Expected: GREEN, canonical/hash regressions remain GREEN, and only the three intended new paths are
reported. Do not stage or commit.

---

### Task 3: Add explicit workflow/decision continuity authority to Topic 04

**Files:**

- Modify: `template/.omp/state/lib/AgentTasks.Common.ps1`
- Modify: `template/.omp/state/lib/AgentTasks.Lifecycle.ps1`
- Modify: `template/.omp/state/lib/AgentTasks.Store.ps1`
- Modify: `template/.omp/state/agent-tasks.ps1`
- Modify: `template/.omp/state/schemas/agent-tasks-v1.schema.json`
- Modify: `template/.omp/state/PROTOCOL.md`
- Modify: `template/.omp/state/manifest.json`
- Create: `scripts/tests/topic07-state-contract.Tests.ps1`
- Modify: focused Topic 04/06 test fixture builders that call `create-task`

**New request contract:**

```json
{
  "schema_version": 1,
  "operation": "set-continuity-contract",
  "working_directory": "absolute project path",
  "session_ref": "exact OMP session ID",
  "runtime": "omp",
  "request": {
    "task_id": "T000001",
    "workflow_class": "standard",
    "locked_decisions": [],
    "authority_ref": "user:2026-08-13",
    "reason": "Initialize the approved continuity contract.",
    "expected_revision": 1,
    "expected_revision_sha256": "64 lowercase hex",
    "expected_lease_generation": 1
  }
}
```

New `create-task` requests require `workflow_class` and `locked_decisions`. Existing revision files
without those properties remain valid/readable legacy v1 records.

- [ ] **Step 1: Write failing state-contract tests**

Cover new-task required fields; exact workflow enum; decision item shape/bounds/unique IDs/order;
unknown properties; legacy status/read-only projection; explicit legacy initialization; normal
reclassification; replacement of locked decisions; owner/runtime/CAS/lease enforcement; non-empty
authority/reason; stale CAS; no-op update refusal; and no state revision on any rejection.

- [ ] **Step 2: Run RED**

```powershell
pwsh -NoProfile -File scripts/tests/topic07-state-contract.Tests.ps1
```

Expected: nonzero because the operation and fields are absent.

- [ ] **Step 3: Implement the reducer rules**

Add `workflow_class` and canonical `locked_decisions` to R000001 for every new task. Add
`set-continuity-contract` as the only operation allowed to initialize or replace them. Publish a
closed supporting record `supporting/CC000001.json` (incremented per change) containing the task
ID, prior/new workflow class, prior/new decision-array hashes, authority reference, reason,
timestamp, and `record_hash`; append its ID to `supporting_refs` in the same locked CAS revision.

Update `Write-AgentTasksRevision` so an old revision may be read but may not publish any new
revision until `set-continuity-contract` initializes both fields. Give only that operation a narrow
`-AllowLegacyContinuityInitialization` path. Use safe code
`AT-CONTINUITY-CLASSIFICATION-REQUIRED` for blocked legacy mutations.

- [ ] **Step 4: Update schema/protocol and all existing fixture constructors**

Keep the schema bundle at version 1 because stored legacy records remain readable; represent
legacy/current task revisions as an explicit `oneOf`, not optional-by-accident properties. Add the
closed supporting record and request/result definitions. Update reusable fixture creators to pass
`workflow_class = standard` and `locked_decisions = @()` unless a test intentionally constructs a
legacy record.

- [ ] **Step 5: Regenerate the state manifest hashes**

Recompute SHA-256 for every state component file after all Task 3 changes and replace only the
matching rows in `template/.omp/state/manifest.json`. Then prove the manifest covers the exact
state source tree.

- [ ] **Step 6: Run state GREEN and a no-Git checkpoint**

```powershell
pwsh -NoProfile -File scripts/tests/topic07-state-contract.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-foundation.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-lifecycle.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-candidate.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-evidence.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-transfer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-retention.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-e2e.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic06-state-projection.Tests.ps1
git diff --check -- template/.omp/state scripts/tests/topic04-state-foundation.Tests.ps1 scripts/tests/topic04-state-lifecycle.Tests.ps1 scripts/tests/topic04-state-candidate.Tests.ps1 scripts/tests/topic04-state-evidence.Tests.ps1 scripts/tests/topic04-state-transfer.Tests.ps1 scripts/tests/topic04-state-retention.Tests.ps1 scripts/tests/topic04-state-e2e.Tests.ps1 scripts/tests/topic06-state-projection.Tests.ps1 scripts/tests/topic07-state-contract.Tests.ps1
git status --short -- template/.omp/state scripts/tests
```

Expected: all state suites pass, legacy cases remain readable, every new revision is continuity-
initialized, manifest hashes reconcile, and no file is staged or committed.

---

---

### Task 4: Add the exact-current-session continuity projection

**Files:**

- Modify: `template/.omp/state/lib/AgentTasks.Projection.ps1`
- Modify: `template/.omp/state/lib/AgentTasks.Common.ps1`
- Modify: `template/.omp/state/agent-tasks.ps1`
- Modify: `template/.omp/state/schemas/agent-tasks-v1.schema.json`
- Modify: `template/.omp/state/PROTOCOL.md`
- Modify: `template/.omp/state/manifest.json`
- Create: `scripts/tests/topic07-state-projection.Tests.ps1`

**Read-only operation:**

```json
{
  "schema_version": 1,
  "operation": "project-continuity",
  "working_directory": "absolute project path",
  "session_ref": "exact OMP session ID",
  "runtime": "omp",
  "request": {}
}
```

The caller cannot provide `task_id`, workflow class, revision, checkpoint, candidate, or evidence
selection. The reducer derives them from exactly one active task whose current revision matches the
envelope's `session_ref` and `runtime`.

- [ ] **Step 1: Write failing exact-session and privacy tests**

Cover zero, one, and multiple owned active tasks; another session's task; wrong runtime; terminal,
transferring, reconcile-required, and trashed tasks; unclassified legacy tasks; stale lease;
corrupt revision/checkpoint/candidate/evidence hashes; candidate drift; stable repeated output; and
the absence of caller-selectable task identity.

Assert that output contains no authority-root path, state/session file path, transcript, message,
tool call/result, terminal output, prompt, hidden reasoning, credentials, raw evidence observation,
candidate source blob, or unrelated task.

- [ ] **Step 2: Define the exact kernel projection**

Implement one entry point:

```powershell
Get-AgentTasksContinuityProjection `
    -Context $context `
    -SessionRef $sessionRef `
    -Runtime $runtime
```

Return the exact `context_continuity_kernel` shape in the approved spec. Bind fields as follows:

- task contract supplies objective, authority, mode, scope, ACs, and obligations;
- current task revision supplies workflow class, locked decisions, owner, status, revision ID,
  lease generation, and revision SHA-256;
- the referenced latest checkpoint supplies checkpoint ID/hash, work unit, next action, blockers,
  and risks;
- selected candidate binding supplies candidate ID, selected candidate hash, and validated candidate
  record hash; both hashes must agree when present;
- current revision evidence IDs supply sorted `{ evidence_id, record_sha256 }` bindings only; and
- `kernel_sha256` hashes canonical JSON with only that property omitted.

An explicit authoritative absence is represented by null/empty fields and is not degradation. The
only v1 degradations are these exact names when a classified legacy revision lacks the corresponding
secondary pointer entirely:

```text
checkpoint, work_unit_id, next_action, blockers, open_risks, candidate, evidence_bindings
```

A referenced-but-missing, corrupt, stale, or ambiguous record refuses every workflow; it is never a
Quick degradation.

- [ ] **Step 3: Run RED, then implement the read-only route**

```powershell
pwsh -NoProfile -File scripts/tests/topic07-state-projection.Tests.ps1
```

Add `project-continuity` beside `status` and `project-work-unit` in the read-only root guard. Do not
take a mutation lock or publish a revision. Use existing Topic 04 readers/hash helpers and candidate
reconciliation; do not add a second filesystem parser.

- [ ] **Step 4: Enforce workflow completeness and the 16 KiB boundary**

Critical-field loss refuses Quick, Standard, and Orchestrated. Quick admits only the exact named
legacy secondary degradations above. Standard/Orchestrated refuse any non-empty
`degraded_fields`. Measure UTF-8 canonical bytes after the hash field is inserted; refuse at 16385
bytes and never truncate.

- [ ] **Step 5: Cross-check PowerShell output with the JavaScript core**

For every valid fixture, pipe the returned `data` object to a small Node child that imports
`context-continuity-core.mjs`. Assert the core accepts it and recomputes the identical canonical
hash and byte count. Mutate every critical group and every secondary group independently and prove
the expected workflow result.

- [ ] **Step 6: Refresh the state manifest and run GREEN**

```powershell
pwsh -NoProfile -File scripts/tests/topic07-state-projection.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic07-state-contract.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic06-state-projection.Tests.ps1
node --test scripts/tests/topic07-continuity-core.Tests.mjs
git diff --check -- template/.omp/state scripts/tests/topic07-state-projection.Tests.ps1
git status --short -- template/.omp/state scripts/tests/topic07-state-projection.Tests.ps1
```

Expected: GREEN, exact state-manifest hashes, read-only byte stability, and no Git write.

---

### Task 5: Build the adapter bootstrap, session classification, and settings guard

**Files:**

- Create: `template/.omp/extensions/context-continuity.js`
- Create: `scripts/tests/topic07-omp-adapter.Tests.mjs`

**Testable adapter surface:**

```js
export const SESSION_MODES = Object.freeze({
  BOOTSTRAP_UNARMED: "bootstrap_unarmed",
  ARMED_MAIN: "armed_main",
  BOUNDED_SUBAGENT: "bounded_subagent",
  INVALID: "invalid",
});

export const EPOCH_STATES = Object.freeze({
  NONE: "none",
  AUTHORIZED: "authorized",
  SUMMARIZING: "summarizing",
  AWAITING_INJECTION: "awaiting_injection",
  INJECTED: "injected",
  CONSUMED: "consumed",
  FAILED: "failed",
  INVALID: "invalid",
});

export function createContextContinuityAdapter(dependencies = {}) -> OMP extension factory
export default createContextContinuityAdapter()
```

- [ ] **Step 1: Write the failing fake-runtime tests**

Build a minimal fake Extension API/context/session manager/settings surface. Test exact command and
hook registration; lazy main-session bootstrap; valid selected-agent `session_init` detection;
malformed/ambiguous session-init refusal; main-session arming only after exactly one owned task is
visible; zero/multiple task behavior before and after arming; session switch reset/reconstruction;
and safe bounded notifications.

- [ ] **Step 2: Freeze the managed disabled profile**

The adapter and tests use this exact map from `context-continuity-schema.mjs`:

```js
export const MANAGED_COMPACTION_PROFILE = Object.freeze({
  "contextPromotion.enabled": false,
  "compaction.enabled": false,
  "compaction.strategy": "off",
  "compaction.midTurnEnabled": false,
  "compaction.thresholdPercent": -1,
  "compaction.thresholdTokens": -1,
  "compaction.keepRecentTokens": 20_000,
  "compaction.autoContinue": false,
  "compaction.idleEnabled": false,
  "compaction.remoteEnabled": false,
  "compaction.remoteStreamingV2Enabled": false,
  "compaction.supersedeReads": true,
  "compaction.dropUseless": true,
});
```

`compaction.reserveTokens` must be unconfigured by the managed overlay and must never be overridden
by the adapter.

- [ ] **Step 3: Run RED, then implement bootstrap and classification**

```powershell
node --test scripts/tests/topic07-omp-adapter.Tests.mjs
```

At `session_start` and `session_switch`, inspect the current branch. A valid `session_init` for
`cheap-scout`, `worker`, or `reviewer` selects `bounded_subagent`; a main persisted session without
one selects `bootstrap_unarmed`. Before the first normal provider request, invoke Topic 04
`project-continuity`: one valid owned task arms the main session, no task leaves bootstrap unarmed,
and malformed/multiple ownership selects invalid and aborts.

- [ ] **Step 4: Implement non-persistent settings reassertion**

Use only `api.pi.settings.get(path)` and `api.pi.settings.override(path, value)`. Never call
`settings.set`, because that persists global configuration. At `session_start`,
`before_agent_start`, `turn_end`, and `before_provider_request`:

1. read every frozen path;
2. record only path names whose effective value drifted;
3. apply runtime overrides for the exact frozen values;
4. read them back; and
5. abort/shutdown if any value remains wrong.

If `get` or `override` is unavailable, register a startup shutdown guard, set a nonzero process exit
code, and allow no provider request. Do not rely on a thrown handler error because OMP contains
handler exceptions.

- [ ] **Step 5: Add unsupported-input guards**

The `input` hook consumes ordinary interactive `/shake` input and reports it unsupported. The
compaction hook work arrives in Task 6. Branch inspection marks the session invalid if it sees a
native shake placeholder beginning `[shaken ~`; this detects unsupported direct routes after the
fact and blocks further provider work without claiming rollback.

- [ ] **Step 6: Run adapter GREEN and a no-Git checkpoint**

```powershell
node --test scripts/tests/topic07-omp-adapter.Tests.mjs scripts/tests/topic07-managed-state-client.Tests.mjs
git diff --check -- template/.omp/extensions/context-continuity.js scripts/tests/topic07-omp-adapter.Tests.mjs
git status --short -- template/.omp/extensions/context-continuity.js scripts/tests/topic07-omp-adapter.Tests.mjs
```

Expected: every fake-runtime path is deterministic, settings changes are runtime-only, and no
provider/model call or Git write occurs.

---

### Task 6: Implement the single-flight `/safe-compact` transaction

**Files:**

- Modify: `template/.omp/extensions/context-continuity.js`
- Modify: `template/.omp/contracts/context-continuity-core.mjs`
- Create: `scripts/tests/topic07-safe-compact.Tests.mjs`

**Persisted namespace:**

```js
{
  "omp_template.topic07": {
    schema_version: 1,
    epoch_id: "E-...",
    nonce_sha256: "64 lowercase hex",
    task_id: "T000001",
    task_revision_sha256: "64 lowercase hex",
    kernel_sha256: "64 lowercase hex",
    branch_sha256: "64 lowercase hex",
    recovery_artifact_id: "OMP artifact ID"
  }
}
```

The raw nonce exists only in adapter memory. It never appears in preserveData, session custom
entries, metrics, logs, notifications, or the recovery artifact.

- [ ] **Step 1: Write the failing command/preflight matrix**

Cover non-empty arguments; bootstrap/unarmed/subagent/invalid mode; in-memory session; missing
artifact directory; busy session; pending messages; running async jobs; queued/delivering async
results; concurrent compaction; an existing nonterminal epoch; zero/multiple owned tasks; settings
drift that cannot be reasserted; invalid kernel; oversize kernel; and every artifact save/path/read/
hash failure. Assert `ctx.compact` call count remains zero for every refusal.

- [ ] **Step 2: Implement canonical recovery-artifact creation**

The artifact is exactly one closed `context_continuity_recovery` record containing epoch ID;
creation/expiry timestamps; session ID; normalized-session-file SHA-256; leaf entry ID; ordered
branch entry IDs and their aggregate hash; task ID/revision ID/revision SHA/lease; the full canonical
kernel; and `artifact_sha256` computed with only itself omitted.

Call `sessionManager.saveArtifact(canonical + "\n", "context-continuity-recovery")`, require a
non-empty artifact ID, resolve it with `getArtifactPath`, require the resolved file to be inside
`getArtifactsDir`, read it back, and revalidate exact bytes/hash before opening an epoch.

- [ ] **Step 3: Open one bounded authorization epoch**

Use `crypto.randomBytes(32)` for the nonce and `crypto.randomUUID()` for the epoch ID. Bind the
in-memory epoch to nonce, expiry, session ID/file hash, leaf/branch hash, task ID/revision/lease,
kernel hash, artifact ID/hash, and current command invocation. Reject a second command while any
epoch is authorized, summarizing, awaiting injection, injected, failed, or invalid.

- [ ] **Step 4: Implement fail-closed `session_before_compact`**

Return `{ cancel: true }` unless one unexpired authorized nonce exists and all bindings still match
fresh branch and Topic 04 reads. Require a real context-full preparation: non-empty
`messagesToSummarize`, non-empty `firstKeptEntryId` present in the branch, positive `tokensBefore`,
`preparation.settings.strategy === "context-full"`, remote disabled, and keep-recent 20000.

On the one authorized path, consume the nonce, move the epoch to `summarizing`, and return `{}`.
That explicit empty result, from the final handler, replaces an earlier non-cancelling custom
compaction result while leaving native context-full behavior intact.

- [ ] **Step 5: Supply the final summarizer context and preserveData**

During `session.compacting`, return exactly:

```js
{
  prompt: SAFE_COMPACTION_PROMPT,
  context: ["<context_continuity_kernel>\n" + canonicalKernel + "\n</context_continuity_kernel>"],
  preserveData: { "omp_template.topic07": boundIdentity }
}
```

The prompt says the summary is convenience context, must preserve useful work, must not contradict
the authoritative kernel, and cannot accept/close/reclassify work. The full kernel appears once in
`context`, not again in `preserveData`.

- [ ] **Step 6: Invoke native compaction exactly once and settle the epoch**

The command calls:

```js
await ctx.compact({
  mode: "soft",
  onComplete,
  onError,
});
```

`session_compact` requires exact preserveData and re-reads Topic 04. Unchanged task/revision/lease
becomes `awaiting_injection`; a change becomes `invalid`. Append a hidden non-model custom entry
`topic07:epoch-state` with hashes/status only so resume can reconstruct the pending epoch.
`onError` or an exception clears the raw nonce, records one bounded failure, and never retries.
The command sends no user message that triggers a turn and schedules no continuation.

- [ ] **Step 7: Test unauthorized and race paths**

Prove built-in `/compact`, another extension's programmatic compact, expired/replayed nonce,
changed leaf/branch, changed task revision/lease/kernel, malformed native preparation, earlier
custom compaction, mismatched preserveData, swallowed handler exception, and terminal native
failure all cancel/fail without a Topic 07 retry. Verify the original branch remains authoritative
when native preparation or compaction fails.

- [ ] **Step 8: Run transaction GREEN**

```powershell
node --test scripts/tests/topic07-safe-compact.Tests.mjs scripts/tests/topic07-omp-adapter.Tests.mjs scripts/tests/topic07-continuity-core.Tests.mjs
git diff --check -- template/.omp/extensions/context-continuity.js template/.omp/contracts/context-continuity-core.mjs scripts/tests/topic07-safe-compact.Tests.mjs
git status --short -- template/.omp/extensions/context-continuity.js template/.omp/contracts/context-continuity-core.mjs scripts/tests/topic07-safe-compact.Tests.mjs
```

Expected: all command/lifecycle races are GREEN, `ctx.compact` is called once only in the valid
case, and no Git write occurs.

---

### Task 7: Add one-time kernel injection, pressure aborts, metrics, and subagent settlement

**Files:**

- Modify: `template/.omp/extensions/context-continuity.js`
- Modify: `template/.omp/contracts/context-continuity-core.mjs`
- Modify: `template/.omp/extensions/agent-task-boundary.js`
- Create: `scripts/tests/topic07-pressure-guard.Tests.mjs`
- Modify: `scripts/tests/topic06-result-receipt.Tests.mjs`
- Modify: `scripts/tests/topic06-omp-wrapper.Tests.mjs`

- [ ] **Step 1: Write failing post-compaction injection tests**

Cover fresh task re-read; unchanged versus changed revision; one hidden custom message; exact kernel
delimiters; request-generation sentinel; multiple `context` emissions; aborted request before final
dispatch; first successful provider boundary; later tool-loop/provider calls; resume after process
restart using `topic07:epoch-state`; already-consumed epoch; malformed persisted epoch; and zero
automatic continuations.

- [ ] **Step 2: Implement request-generation binding**

Increment a local generation counter at each normal `before_agent_start`. When an epoch awaits
injection, the next `context` event reprojects Topic 04, validates the epoch, and appends exactly one
hidden `role: "custom"`, `customType: "topic07-continuity-kernel"`, `display: false` message to that
request's copied message array. Bind its kernel hash to the current generation.

At `before_provider_request`, require this binding whenever an epoch awaits injection. If an abort
already occurred, leave the epoch pending. Otherwise append a hash-only `consumed` epoch entry and
clear the in-memory pending state immediately before the provider boundary. Never parse the native
summary to decide whether injection is needed.

- [ ] **Step 3: Write failing pressure-boundary tests**

For every window case from Task 2, test below/equal/above threshold; unavailable usage; summarizing
exception; ordinary main request; bootstrap; invalid ownership; bounded Scout/Worker/Reviewer;
repeated hooks; and a second request after one compaction remains too large. Assert `ctx.abort()` is
called synchronously and no replacement payload is treated as cancellation.

- [ ] **Step 4: Implement the stop-before-dispatch guard**

At `before_agent_start`, `turn_end`, and `before_provider_request`, read
`ctx.getContextUsage()`, calculate the frozen boundary, and:

- allow below threshold;
- allow only the active native summarization provider call while state is `summarizing`;
- synchronously call `ctx.abort()` at/above threshold for every normal request;
- tell an interactive main user to run `/safe-compact` or make an explicit Topic 04 handoff;
- mark bounded-subagent pressure with `T07_CONTEXT_PRESSURE_ABORT`; and
- after one successful compaction still leaves pressure at/above threshold, require handoff/user
  action rather than opening a second epoch automatically.

If usage/window is unavailable once the gate is armed, fail closed at the final provider boundary;
do not guess from transcript length.

- [ ] **Step 5: Make Topic 06 reject pressure-aborted child results**

Extend receipt normalization only enough to recognize the exact Topic 07 abort marker plus native
aborted/partial details. Map it to an unsuccessful `context_pressure` reason and prohibit a
`complete` provisional outcome. Cheap Scout returns to its existing Lead fallback; Worker/Reviewer
require an explicit Tech Lead narrow/re-dispatch or inline decision. Do not auto-retry and do not
change model routing.

- [ ] **Step 6: Emit bounded local observations**

Append non-model `topic07:observation` entries whose serialized form is at most 4096 bytes. Include
component/runtime version; hashed session/task/epoch identity; workflow class; context/window/
threshold; kernel bytes/hash; artifact status; native preparation/settlement; degraded field names;
settings-drift path names; injection status; and provider allowed/aborted. Exclude prompts,
summaries, transcript/tool bodies, paths, raw nonce, credentials, and raw provider payloads.

- [ ] **Step 7: Run pressure/injection and Topic 06 GREEN**

```powershell
node --test scripts/tests/topic07-pressure-guard.Tests.mjs scripts/tests/topic07-safe-compact.Tests.mjs scripts/tests/topic06-result-receipt.Tests.mjs scripts/tests/topic06-omp-wrapper.Tests.mjs
pwsh -NoProfile -File scripts/tests/topic06-agent-boundary.Tests.ps1
git diff --check -- template/.omp/extensions/context-continuity.js template/.omp/contracts/context-continuity-core.mjs template/.omp/extensions/agent-task-boundary.js scripts/tests/topic07-pressure-guard.Tests.mjs scripts/tests/topic06-result-receipt.Tests.mjs scripts/tests/topic06-omp-wrapper.Tests.mjs
git status --short -- template/.omp/extensions scripts/tests
```

Expected: one-time injection, synchronous pressure aborts, unsuccessful child receipts, no
automatic retry/continuation, and no Git write.

---

### Task 8: Upgrade the managed launcher, overlay, manifest, installer, and rollback

**Files:**

- Modify: `template/.omp/contracts/managed-runtime.yml`
- Modify: `template/.omp/contracts/component-manifest.json`
- Modify: `template/.omp/bin/omp-managed.ps1`
- Modify: `template/.omp/extensions/agent-task-boundary.js`
- Modify: `scripts/lib/topic06-agent-boundary.ps1`
- Modify: `scripts/install-template.ps1`
- Modify: `scripts/uninstall-template.ps1`
- Modify: `scripts/tests/topic06-installer.Tests.ps1`
- Modify: `scripts/tests/topic06-managed-runtime.Tests.ps1`
- Create: `scripts/tests/topic07-managed-runtime.Tests.ps1`
- Create: `scripts/tests/fixtures/topic07-omp-runtime-probe.mjs`

**Component decision:** Upgrade the existing public `agent-boundary` component rather than expose a
second partially overlapping installer component. The manifest, generated runtime, and install
record become closed schema version 2 with component version `2.0.0`. Topic 06 and Topic 07 remain
separate extensions inside that atomic component.

- [ ] **Step 1: Write failing v2 manifest/runtime tests**

Require exact owned files for the shared state client, continuity schema/core/adapter, Topic 06
core/wrapper, overlay, and launcher; exact dependencies on agents/state/config; supported OMP
versions `17.2.10` and `17.2.12`; exact hashes; no unsafe/duplicate path; generated runtime/install
record paths; and no ownership claim over operational `agent-tasks` or session data.

The v2 runtime adds exact path keys `state_client`, `continuity_schema`, `continuity_core`, and
`continuity_adapter`; capability `continuity`; and a `continuity_policy_sha256` binding. Update the
Topic 06 wrapper to validate the v2 runtime but keep using only its own paths/policy.

- [ ] **Step 2: Replace the overlay with the exact combined profile**

The UTF-8/LF bytes are exactly:

```yaml
task:
  softRequestBudget: 200
contextPromotion:
  enabled: false
compaction:
  enabled: false
  strategy: off
  midTurnEnabled: false
  thresholdPercent: -1
  thresholdTokens: -1
  keepRecentTokens: 20000
  autoContinue: false
  idleEnabled: false
  remoteEnabled: false
  remoteStreamingV2Enabled: false
  supersedeReads: true
  dropUseless: true
```

Do not add `reserveTokens`, provider credentials, retry settings, model catalogs, OmniRoute
settings, async settings, or task batch/isolation settings.

- [ ] **Step 3: Make launcher option parsing literal and fail closed**

Split caller arguments at the first literal `--` before scanning controls. In the OMP option region
only:

- reject `--no-session` and `--no-session=*`;
- reject caller trusted-extension/extension/hook controls already forbidden by Topic 06; and
- retain caller config flags but append the managed overlay after them.

Text at and after literal `--` is prompt text. Therefore `-- --no-session` and
`-- "please discuss --no-session"` are accepted as text.

Build launch order exactly:

```text
caller OMP options
--trusted-extension <agent-task-boundary.js>
--trusted-extension <context-continuity.js>
--config <managed-runtime.yml>
-- and caller prompt text, when present
```

Validate manifest/runtime/hash/version/settings identities before invoking OMP. The continuity
adapter must be the final trusted extension and the managed overlay the final config overlay.

- [ ] **Step 4: Implement transactional installation and exact rollback**

Keep the public component name `agent-boundary`. The installer stages all v2 owned/generated files,
validates hashes/dependencies/OMP version, and atomically activates them with its existing backup
transaction. A failure restores the complete previous v1 component. Reinstall is idempotent.

Uninstall uses only the v2 install record, restores attributable prior bytes, removes only generated
v2 runtime/install records when owned, and retains Topic 04 operational state, OMP sessions,
recovery artifacts, metrics, user config, credentials, and unrelated extensions.

- [ ] **Step 5: Test fake-OMP argument order and tamper refusal**

Extend the fake launcher capture to assert exact option/prompt partitioning, two trusted extensions
in order, final overlay, no-session refusal before `--`, no-session acceptance after `--`, and no
OMP process start after any manifest/core/adapter/overlay/launcher/state/agent hash drift.

- [ ] **Step 6: Test actual installed runtime without `--no-session`**

Use a disposable project plus a disposable `--session-dir`. Start OMP RPC with the installed
17.2.12 binary and the model-free runtime probe. Assert one managed `task` wrapper, one
`safe-compact` command, Topic 07 last-handler observation, settings `get/override` availability,
persisted session/artifact directories, and clean shutdown. Do not send an agent prompt or model
request in this installation test.

- [ ] **Step 7: Run installer/runtime GREEN**

```powershell
pwsh -NoProfile -File scripts/tests/topic06-installer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic06-managed-runtime.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic07-managed-runtime.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-installer.Tests.ps1
git diff --check -- template/.omp/contracts template/.omp/extensions template/.omp/bin scripts/install-template.ps1 scripts/uninstall-template.ps1 scripts/lib/topic06-agent-boundary.ps1 scripts/tests/topic06-installer.Tests.ps1 scripts/tests/topic06-managed-runtime.Tests.ps1 scripts/tests/topic07-managed-runtime.Tests.ps1 scripts/tests/fixtures/topic07-omp-runtime-probe.mjs
git status --short -- template/.omp scripts/install-template.ps1 scripts/uninstall-template.ps1 scripts/lib scripts/tests
```

Expected: transactional install/reinstall/rollback GREEN, exact order/profile proven, no runtime
state lost, no provider call, and no Git write.

---

### Task 9: Prove the source seams and stop-before-provider behavior

**Files:**

- Create: `scripts/tests/fixtures/topic07-provider-sentinel.mjs`
- Create: `scripts/tests/topic07-pressure-canary.Tests.ps1`
- Create: `scripts/lib/topic07-context-continuity.ps1`

- [ ] **Step 1: Add exact source-attachment assertions**

Pin repository SHA `3a8591a8af5b6d200088d12ca75a5517cb064fa8` and assert the checkout is clean. Use structural
source needles plus bounded surrounding hashes for:

- `mode: "soft"` overriding to context-full and remote false;
- manual preparation occurring before `session_before_compact`;
- cancellable `session_before_compact`;
- last-result behavior for `session.compacting`;
- `session_compact` carrying the saved entry;
- `context`, `before_agent_start`, `turn_end`, and `before_provider_request` ordering;
- synchronous `ctx.abort()` generation invalidation before its first await;
- per-turn superseded-read/useless-result pruning occurring before the automatic-compaction gate;
- auto context-full rescue shake preceding the cancellable hook when preparation is absent;
- shake artifact failure still permitting placeholder rewrite;
- read-only session artifact/branch APIs; and
- `createSubagentSettings` copying effective parent settings plus `session_init` before the child
  prompt.

A source mismatch is `OPEN-T07-RUNTIME-01` and blocks promotion. It is not auto-fixed by changing a
needle to match unknown semantics.

- [ ] **Step 2: Build a zero-model provider sentinel**

The fixture registers one local in-process provider/model with a tiny context window and a
`streamSimple` function that atomically increments a disposable counter before returning a fixed
error. It exposes no network endpoint and no credential. A correct pressure abort leaves the
counter at zero; any invocation is an immediate test failure.

- [ ] **Step 3: Build the persisted-session canary**

For each tested OMP executable, install the v2 component in a disposable project, use a disposable
session directory, create a persisted OMP session, create/classify exactly one Topic 04 task owned
by that session ID, seed sufficient local context to reach the tiny fake model's threshold, and
submit one normal RPC prompt. Assert:

- the Topic 07 final guard calls abort;
- the sentinel provider count remains zero;
- the session remains persisted and resumable;
- `/safe-compact` guidance is surfaced for the main session;
- a bounded-subagent fixture settles as an unsuccessful Topic 06 receipt; and
- no automatic compact, shake, handoff, retry, or continuation entry appears.

Run a below-threshold control case and allow the fake provider counter to become exactly one; this
proves the sentinel could have observed a dispatch.

- [ ] **Step 4: Enforce the two-version promotion matrix**

The script locates 17.2.12 through the installed managed runtime. It locates 17.2.10 only from an
explicit `OMP_TOPIC07_17_2_10_PATH` or the local untracked runtime cache
`tools/runtime-cache/omp/17.2.10/omp.exe`; it never downgrades/replaces the user's installed OMP and
never downloads a binary implicitly.

Both executable canaries must pass to mark Topic 07 promoted. If a verified 17.2.10 executable is
unavailable, return named blocker `OPEN-T07-RUNTIME-02` and status
`IMPLEMENTED_NOT_PROMOTED`; keep automatic compaction disabled and do not claim Topic 07 complete.
The user may later authorize acquisition or assign this narrow gate to Opus/upstream review.

- [ ] **Step 5: Run source and runtime canaries twice**

```powershell
pwsh -NoProfile -File scripts/tests/topic07-pressure-canary.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic07-pressure-canary.Tests.ps1
git diff --check -- scripts/lib/topic07-context-continuity.ps1 scripts/tests/topic07-pressure-canary.Tests.ps1 scripts/tests/fixtures/topic07-provider-sentinel.mjs
git status --short -- scripts/lib/topic07-context-continuity.ps1 scripts/tests/topic07-pressure-canary.Tests.ps1 scripts/tests/fixtures/topic07-provider-sentinel.mjs
```

Expected for promotion: identical PASS classifications for both OMP versions on both runs, zero
sentinel calls in blocked cases, exactly one in controls, no model/network request, and no Git
write. A named runtime blocker is reported once and is not hidden by unit-test GREEN.

---

### Task 10: Project the implemented contract into operator and authority surfaces

**Files:**

- Create: `docs/context-continuity.md`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/architecture.md`
- Modify: `docs/workflow-v0.md`
- Modify: `docs/task-state.md`
- Modify: `docs/token-strategy.md`
- Modify: `docs/security.md`
- Modify: `docs/installation.md`
- Modify: `docs/rollback.md`
- Modify: `docs/final-report.md`
- Modify: `template/.omp/AGENTS.md`
- Modify: `template/.omp/RULES.md`
- Modify: `template/.omp/commands/quick.md`
- Modify: `template/.omp/commands/standard.md`
- Modify: `template/.omp/commands/orchestrated.md`
- Modify: `spec/key/04-decision-log.md`
- Modify: `spec/key/01-dna.md`
- Modify: `spec/key/03-token-quality-model.md`
- Modify: `spec/01-target-architecture.md`
- Modify: `spec/02-runtime-semantics.md`
- Modify: `spec/05-context-and-token-model.md`
- Modify: `spec/13-validation-and-evaluation.md`
- Modify: `spec/15-security-and-failure-recovery.md`
- Modify: `spec/README.md`
- Modify: `spec/phases/phase-01-runtime-correctness.md`
- Modify: `spec/phases/phase-03-context-efficiency.md`
- Modify: `spec/phases/phase-05-installation-hardening.md`
- Modify: `spec/phases/phase-06-evaluation.md`
- Modify: `registry/omp-compatibility.yml`
- Modify: `scripts/lib/topic02-workflow-lifecycle.ps1`
- Create: `codex-topic07-context-compaction-continuity-changelog.md`

- [ ] **Step 1: Add one canonical decision entry**

Add `KD-031 — Explicit safe context-full compaction with authoritative continuity kernel` to the
decision log with one stable `topic07-authority:kd-031` marker. Record automatic semantic
compaction off; `/safe-compact` only; Topic 04 authority; Quick/Standard/Orchestrated completeness;
single native soft transaction; no auto continuation/retry; pressure abort; bounded-subagent
failure; local persistence; unsupported shake/snapcompact/handoff/remote paths; and two-version
promotion gate.

- [ ] **Step 2: Reconcile rather than append contradictory prose**

Search each listed authority file for claims that automatic compaction is enabled, that built-in
`/compact`/shake is a safe fallback, that a summary is authority, that exhaustion is automatic,
that subagents may compact, or that an unavailable Opus/reviewer blocks continuity. Replace the
active clause or fence it explicitly as historical/evaluation-only. Do not add a second competing
rule elsewhere.

- [ ] **Step 3: Update workflow entry and task-state instructions**

Quick/Standard/Orchestrated command docs must pass their exact workflow class and initial locked
decisions to `create-task`; legacy active tasks use `set-continuity-contract` through explicit CAS.
They must instruct `/safe-compact` only after the task is armed and must use explicit Topic 04
handoff when safe compaction is unavailable or one attempt leaves pressure unresolved.

- [ ] **Step 4: Write the operator guide**

`docs/context-continuity.md` must explain, in plain language:

- when `/safe-compact` is available and why it takes no focus text;
- what is saved locally before compaction;
- what survives and what remains authoritative;
- why the next normal prompt gets one fresh kernel and no hidden continuation occurs;
- what Quick degradation means;
- what to do at pressure, artifact failure, revision race, uncompactable recent turn, or child
  pressure abort;
- why bare OMP/direct shake are outside the managed guarantee;
- how to install, validate, inspect local observations, and rollback without deleting state;
- that OmniRoute/model routing is separate and unchanged; and
- promotion/blocker status when one runtime canary is unavailable.

- [ ] **Step 5: Update compatibility and changelog records**

Add source-verified Topic 07 capability rows to `registry/omp-compatibility.yml` with pinned source
anchors, selected status, supported versions, and the explicit runtime-canary gate. The Topic 07
changelog records implemented files, exact verification counts/hashes after Task 11, zero provider
calls, local/no-Git policy, and any `OPEN-T07-RUNTIME-*` item without calling it complete.

- [ ] **Step 6: Run focused drift searches**

```powershell
rg -n "automatic compaction|auto.?compact|/compact|/shake|shake|snapcompact|remote compaction|auto.?continue|summary.*authorit|subagent.*compact|Opus.*required" README.md CHANGELOG.md docs spec registry template/.omp
rg -n "safe-compact|KD-031|topic07-authority:kd-031|workflow_class|locked_decisions|IMPLEMENTED_NOT_PROMOTED" README.md docs spec registry template/.omp codex-topic07-context-compaction-continuity-changelog.md
git diff --check -- README.md CHANGELOG.md docs spec registry template/.omp/AGENTS.md template/.omp/RULES.md template/.omp/commands scripts/lib/topic02-workflow-lifecycle.ps1 codex-topic07-context-compaction-continuity-changelog.md
git status --short -- README.md CHANGELOG.md docs spec registry template/.omp scripts/lib/topic02-workflow-lifecycle.ps1 codex-topic07-context-compaction-continuity-changelog.md
```

Expected: each risky phrase is selected policy, explicit rejection, historical evidence, or
evaluation-only text; no active contradiction and no Git write.

---

### Task 11: Add mutation-resistant validation, capture evidence, and run final regression

**Files:**

- Complete: `scripts/lib/topic07-context-continuity.ps1`
- Create: `scripts/validate-topic07-context-continuity.ps1`
- Create: `scripts/capture-topic07-evidence.ps1`
- Create: `scripts/tests/topic07-validator-mutations.Tests.ps1`
- Modify: `scripts/validate-template.ps1`
- Generate: `docs/evidence/current-product/topic-07/deterministic.json`
- Generate: `docs/evidence/current-product/topic-07/manifest.json`
- Complete: `codex-topic07-context-compaction-continuity-changelog.md`

- [ ] **Step 1: Write failing validator-mutation tests**

Copy only governed files to disposable fixtures and mutate one load-bearing contract at a time:
enable any automatic path; add reserveTokens; change keep-recent; remove final extension order;
allow no-session; accept command arguments; weaken exact-session ownership; remove a critical
field; admit Standard degradation; remove artifact verification; persist raw nonce; allow compact
without nonce; schedule continuation/retry; remove pressure abort; accept child partial; change
supported versions; weaken source pins; omit rollback retention; or claim completion while a
runtime blocker exists. Each mutation must produce one stable `T07-*` failure.

- [ ] **Step 2: Implement one focused validator**

`Test-Topic07ContextContinuityContract` returns structured PASS/WARN/FAIL records and validates:

- required governed files and exact hashes/manifests;
- KD-031 and outward authority projections;
- state fields/operation/projection/privacy/limits;
- portable core/profile/reason codes;
- command/hook/epoch/injection/pressure semantics;
- Topic 06 partial-receipt rejection;
- overlay/launcher/install/uninstall identities and order;
- pinned source SHA/cleanliness/attachment sentinels;
- runtime canary matrix status; and
- evidence/changelog truthfulness.

Do not use broad phrase counting as proof. Phrase sentinels may locate a clause, but each
load-bearing check must also validate its owning structure or executable test result.

- [ ] **Step 3: Integrate the focused validator into the full validator**

Run Topic 07 normally from `scripts/validate-template.ps1`. During evidence bootstrap only,
`OMP_TOPIC07_CAPTURE=1` may skip the not-yet-written Topic 07 evidence self-hash check; every other
Topic 07 check still runs. No other skip environment variable is added.

- [ ] **Step 4: Run the fresh verification set**

```powershell
node --test scripts/tests/topic07-managed-state-client.Tests.mjs scripts/tests/topic07-continuity-core.Tests.mjs scripts/tests/topic07-omp-adapter.Tests.mjs scripts/tests/topic07-safe-compact.Tests.mjs scripts/tests/topic07-pressure-guard.Tests.mjs
pwsh -NoProfile -File scripts/tests/topic07-state-contract.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic07-state-projection.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic07-managed-runtime.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic07-pressure-canary.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic07-validator-mutations.Tests.ps1
pwsh -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
pwsh -NoProfile -File scripts/validate-topic04-durable-state.ps1
pwsh -NoProfile -File scripts/validate-topic06-agent-boundary.ps1
pwsh -NoProfile -File scripts/validate-topic07-context-continuity.ps1
pwsh -NoProfile -File scripts/validate-template.ps1
git diff --check
git diff --cached --name-only
git status --short
```

Expected: all implementation/state/install/mutation/source/runtime tests pass; Topic 02/04/06
regressions pass; full validator has no new warning/failure; `git diff --check` passes apart from
already documented line-ending advisories; cached diff remains unchanged/empty; working tree may
remain dirty but contains no unintended path.

- [ ] **Step 5: Capture deterministic current-product evidence**

```powershell
pwsh -NoProfile -File scripts/capture-topic07-evidence.ps1
pwsh -NoProfile -File scripts/validate-topic07-context-continuity.ps1
pwsh -NoProfile -File scripts/validate-template.ps1
```

The evidence records exact commands, exit codes, stdout/stderr hashes, assertion counts, component
and source hashes, OMP versions, canary provider counters, dirty-path identity, and
`provider_calls: 0`, `model_processes_started: 0`. It stores no transcript, prompt, nonce, absolute
session/state path, credential, or raw tool output. The manifest hashes every governed evidence,
authority, implementation, and plan/spec file.

- [ ] **Step 6: Final truthfulness and no-Git checkpoint**

Re-run the complete verification set after evidence generation. Fill the Topic 07 changelog with
observed counts/hashes only. If both runtime canaries pass, status is `PROMOTED`; if the only open
item is the unavailable/failed 17.2.10 canary, status is `IMPLEMENTED_NOT_PROMOTED` and
`OPEN-T07-RUNTIME-02` remains explicit. Never label the topic complete solely because unit tests
pass.

```powershell
git diff --check
git diff --cached --name-only
git status --short
```

Do not stage or commit after the checkpoint.

---

## Acceptance Coverage

| Approved acceptance criterion | Implemented/proved by |
|---|---|
| 1–2 disabled automatic paths; native per-turn pruning retained | Tasks 5, 8, 9, 11 |
| 3–7 command arguments, persistence, artifact-first, one soft call, nonce-only compact, no-session parsing | Tasks 6, 8, 9 |
| 8–10 exact owned task, workflow/decisions, explicit legacy CAS | Tasks 3–5 |
| 11–13 closed/bounded kernel and workflow completeness | Tasks 2, 4 |
| 14–15 preserveData and branch/task race binding | Task 6 |
| 16 one fresh post-compaction kernel | Task 7 |
| 17 no continuation or Topic 07 retry | Tasks 6–7 |
| 18 provider dispatch blocked at pressure | Tasks 7, 9 |
| 19 inherited child profile and unsuccessful receipt | Tasks 5, 7, 9 |
| 20 unsupported alternatives remain unselected | Tasks 5, 8, 10 |
| 21 final extension and installed component identity | Tasks 8–9 |
| 22 rollback restores prior component set | Task 8 |
| 23 bare OMP/direct shake limitations disclosed | Task 10 |

## Completion Boundary

Topic 07 is `PROMOTED` only when every checkbox is complete, all deterministic verification is
fresh, both supported OMP executable canaries prove stop-before-provider behavior, evidence hashes
reconcile, and no required work remains. No Git commit is part of completion.

If all code/spec/evidence work is done but a supported runtime executable or abort seam cannot be
proven, stop at `IMPLEMENTED_NOT_PROMOTED`, leave automatic compaction disabled, preserve the named
`OPEN-T07-RUNTIME-*` record, and hand that narrow issue to the user for optional Opus/upstream work.
That is a safe partial outcome, not a hidden fallback and not Topic 07 completion.
