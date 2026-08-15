# Topic 06 Agent Boundary Contracts Implementation Plan

> **Execution selection:** Implement this plan inline and sequentially in the current workspace.
> Do not spawn a subagent: the contract core, Topic 04 state projection, OMP wrapper, installer,
> and evidence manifest form one stateful dependency chain. Do not stage, commit, push, create a
> branch, or open a PR; the user selected local working-tree storage.

**Goal:** Make every template-managed OMP agent dispatch cross one closed, canonical, fail-closed
boundary: project a Topic 04 work unit, compose the minimum role packet, delegate through the
native OMP `task` implementation, validate the settled native result, and record only a
provisional work-unit outcome. If that managed boundary is unavailable, the Tech Lead works
inline and creates no packet.

**Architecture:** A dependency-free JavaScript core owns canonical schemas, normalization,
composition, semantic-result validation, and receipt reconciliation. Topic 04 adds one read-only
work-unit projection and an atomic handoff projection. A trusted OMP extension re-registers the
built-in name `task`, delegates to the captured native implementation with `ctx.invokeTool`, and
uses Topic 04 for projection/outcome CAS. An atomic installer deploys a managed launcher, exact
extension allowlist, and final `task.softRequestBudget: 200` overlay. OMP, not the wrapper, keeps
model execution, cancellation, routing, batching, and isolation mechanics.

**Tech stack:** dependency-free ESM on Node 24; OMP extension API and TypeBox shim; PowerShell
7.4+ Topic 04 state core; JSON/YAML configuration; Node `node:test`; standalone PowerShell test
runners; token-free OMP RPC/config probes; Git read-only plumbing for evidence and checkpoints.

**Approved design:**
`docs/superpowers/specs/2026-08-13-topic-06-agent-boundary-contracts-design.md`

## Global constraints

- Preserve every pre-existing dirty-worktree change. Never reset, revert, clean, or overwrite an
  unrelated path.
- Topic 04 remains the only durable lifecycle authority. A packet, model result, receipt, or
  provisional work-unit outcome cannot accept a task or candidate.
- The model-facing caller may supply only `task_id`, `work_unit_id`, `agent`, `role`, `effort`, and
  `isolated` in the approved combinations. It may not supply prompt text, model IDs, schemas,
  hashes, filesystem roots, candidate identity, or arbitrary context.
- Cheap Scout is exact Flash `xhigh` with Pro `xhigh` as its only availability fallback. Worker is
  exact `high` by default or `xhigh` when the Tech Lead selects it. Reviewer is always exact
  `xhigh`. Compare returned `modelRole` and `resolvedModel`; do not trust fallback flags alone.
- The wrapper must not modify OmniRoute or infer its upstream. The receipt field is
  `not_observed` unless an independently validated runtime surface later supplies that fact.
- Agent-authored output contains semantic facts only. Runtime IDs, worktree roots, hashes, model
  identity, effort, request count, and isolation metadata are attached outside that output.
- Managed v1 rejects async agents and delegated spawn authority. The selected three agents must
  remain `blocking: true` with empty `spawns`.
- Mutating Worker dispatch is refused in plan mode before native `task` runs. Scout and Reviewer
  remain read-only and may run only when their selected capabilities survive plan-mode stripping.
- Compose and validate every batch item before the one native batch call. Batch items must share
  one `task_id`, use distinct `work_unit_id` values, and bind to the same initial revision/hash/
  lease generation. A failed sibling fails the barrier; already-recorded provisional sibling
  outcomes are not rolled back.
- The final managed overlay contains exactly `task.softRequestBudget: 200`. Any settled result
  with `requests >= 300` is `forced_partial` and cannot be accepted as complete.
- Do not add `task.batch`, `async.enabled`, model credentials, provider catalogs, or OmniRoute
  settings to the managed overlay.
- Direct bare `omp` is unmanaged. It remains usable, but its results cannot claim a Topic 06
  boundary receipt.
- Keep the four existing `template/.omp/schemas/*.yml` bytes unchanged because Phase 00 pins them
  as historical evidence. Retire the installer `schemas` component and remove all active claims
  that those files are runtime contracts.
- All Topic 06 tests and evidence capture are model-free. No provider request, DeepSeek request,
  Codex request, or model subprocess is authorized by this plan.
- Carry `OPEN-T06-RUNTIME-01` as nonblocking: a universal hook for unrelated OMP Vibe/eval/
  internal-agent paths is useful upstream work, but it does not block the managed task/handoff
  boundary implemented here.

---

### Task 1: Build the portable closed-schema and canonicalization core

**Files:**

- Create: `template/.omp/contracts/agent-boundary-schema.mjs`
- Create: `template/.omp/contracts/agent-boundary-core.mjs`
- Create: `template/.omp/contracts/agent-boundary-cli.mjs`
- Create: `scripts/tests/topic06-contract-core.Tests.mjs`

**Public interfaces:**

```js
canonicalJson(value) -> string
sha256Canonical(value) -> lowercase 64-hex string
parseJsonNoDuplicateKeys(text) -> JSON-compatible value
validateManagedRequest(value) -> { ok, value } | { ok: false, reason_code, message }
validateProjection(value) -> same result envelope
composeAgentPacket({ request, projection }) -> {
  ok: true, packet, canonical, packet_sha256, utf8_bytes
} | safe failure
composeHandoffPacket({ handoff_projection }) -> {
  ok: true, packet, canonical, packet_sha256, utf8_bytes
} | safe failure
validateSemanticResult({ role, value }) -> validation envelope
normalizeBoundaryReceipt(input) -> receipt envelope
deriveActiveMode(entries) -> { ok: true, mode } | safe failure
```

The CLI reads one UTF-8 JSON document from stdin, writes exactly one canonical JSON line to
stdout, writes diagnostics only to stderr, and exits `0` for a valid operation, `2` for input/
schema rejection, or `5` for a sanitized internal failure. Its closed operations are `compose`,
`compose-handoff`, `lint-packet`, `lint-handoff`, `validate-semantic`, and
`normalize-receipt`.

Use these initial deterministic limits in `agent-boundary-schema.mjs`:

```js
export const LIMITS = Object.freeze({
  maxInputBytes: 131072,
  maxPacketBytes: 12288,
  maxResultBytes: 32768,
  maxBatchItems: 8,
  maxDepth: 10,
  maxArrayItems: 128,
  maxStringBytes: 4096,
  forcedPartialRequests: 300,
});
```

- [ ] **Step 1: Write the failing canonical-core tests**

Cover valid single/batch managed requests; rejection of mixed single+batch shapes; unknown keys at
every level; duplicate JSON keys; invalid UTF-16 surrogate input; NUL; NFC and LF normalization;
stable object-key order; semantically ordered AC/completion arrays; sorted set-like path arrays;
duplicate AC IDs and paths; depth/item/string/byte limits; forbidden property names; private-key,
Bearer/JWT/GitHub/AWS credential signatures; absolute authority/state/session paths in
model-facing path fields; and safe closed error envelopes.

Assert the exact managed item union:

```js
{
  task_id: /^T[0-9]{6}$/,
  work_unit_id: /^WU-[A-Z0-9][A-Z0-9._-]{0,79}$/,
  agent: "cheap-scout" | "worker" | "reviewer",
  role: "cheap_scout" | "worker" | "reviewer",
  effort?: "high" | "xhigh",
  isolated?: boolean
}
```

Require exact pairs (`cheap-scout`/`cheap_scout`, `worker`/`worker`, `reviewer`/`reviewer`), forbid
caller effort for Scout/Reviewer, and forbid `isolated` except on Worker.

- [ ] **Step 2: Run the focused test and observe RED**

```powershell
node --test scripts/tests/topic06-contract-core.Tests.mjs
```

Expected: nonzero because the three contract modules do not exist. A skipped test is not RED.

- [ ] **Step 3: Implement schema constants, duplicate-safe parsing, and canonical JSON**

Keep the modules dependency-free. Normalize all strings to NFC and LF, reject unpaired
surrogates/NUL, sort object keys ordinally, retain semantic array order, and sort/deduplicate only
fields declared as sets. Hash the UTF-8 canonical bytes. Never use locale-sensitive comparison.

Recursively reject normalized property names for transcript, conversation, tool history,
reasoning/thought/chain-of-thought, credential/authorization/cookie/API key/token/private key/
secret, stdout/stderr/provider payload, and state/session path. Scan string values for the exact
credential signatures tested in Step 1; do not reject ordinary prose merely because it contains
the English word “token.”

- [ ] **Step 4: Implement the closed CLI transport**

The CLI must call the exported pure functions rather than copy validation logic. Add tests proving
one input produces one output line, duplicate keys are refused before `JSON.parse`, oversized
stdin is refused, raw input/stack/stderr is absent from stdout, and an unknown operation exits 2.

- [ ] **Step 5: Run GREEN and a no-Git checkpoint**

```powershell
node --test scripts/tests/topic06-contract-core.Tests.mjs
git diff --check -- template/.omp/contracts scripts/tests/topic06-contract-core.Tests.mjs
git status --short -- template/.omp/contracts scripts/tests/topic06-contract-core.Tests.mjs
```

Expected: all tests pass, no whitespace errors, and only the four intended new paths appear.

---

### Task 2: Add the Topic 04 work-unit and atomic handoff projections

**Files:**

- Create: `template/.omp/state/lib/AgentTasks.Projection.ps1`
- Modify: `template/.omp/state/lib/AgentTasks.Common.ps1`
- Modify: `template/.omp/state/lib/AgentTasks.Transfer.ps1`
- Modify: `template/.omp/state/agent-tasks.ps1`
- Modify: `template/.omp/state/schemas/agent-tasks-v1.schema.json`
- Modify: `template/.omp/state/PROTOCOL.md`
- Modify: `template/.omp/state/manifest.json`
- Create: `scripts/tests/topic06-state-projection.Tests.ps1`

**State interface:**

`project-work-unit` is read-only and accepts exactly:

```json
{"task_id":"T000001","work_unit_id":"WU-001"}
```

Its `data` is a closed `work_unit_projection` with these top-level fields:

```text
schema_version, record_type, task, work_unit, binding, cas, projection_sha256
```

`task` contains `task_id`, `status`, `objective`, `authority`, `execution_mode`, `write_scope`,
`acceptance_criteria`, `obligations`, and `owned_ignored_outputs`. `work_unit` contains its six
immutable contract fields. `binding` contains reconciled observation/authoritative worktree,
candidate/diff/artifact references, without exposing authority-record paths. `cas` contains
revision, revision SHA-256, and lease generation. `projection_sha256` hashes the canonical object
with that property omitted.

- [ ] **Step 1: Write failing projection and privacy tests**

Use Topic 04 disposable fixtures. Prove that only an active owned task and an existing listed work
unit project; the projected contract matches immutable records; current candidate/worktree/CAS
bindings reconcile; hashes are stable across repeated reads; linked-worktree observation is
handled according to Topic 04 ownership; and corrupt/missing/stale/unowned records fail with safe
`AT-*` errors.

Assert that the serialized projection contains none of: authority/state file paths, revision
history, checkpoints, raw evidence bodies, transcript/session history, credentials, unrelated
tasks, or raw provider/tool output.

- [ ] **Step 2: Run RED**

```powershell
pwsh -NoProfile -File scripts/tests/topic06-state-projection.Tests.ps1
```

Expected: nonzero with `project-work-unit` missing.

- [ ] **Step 3: Implement the read-only projection operation**

Add `project-work-unit` to `Get-AgentTasksRequestShape`, load
`AgentTasks.Projection.ps1` from the CLI, route it before mutation operations, and add it beside
`status` to the read-only root guard. The projection module must call existing Topic 04 readers and
canonical/hash helpers; it must never parse private state JSON through a second adapter path.

Use one function boundary:

```powershell
Get-AgentTasksWorkUnitProjection -Context $context -TaskId $taskId -WorkUnitId $workUnitId
```

- [ ] **Step 4: Make `begin-handoff` return its safe projection atomically**

Add failing cases first, then make `Start-AgentTasksHandoff` construct
`handoff_projection` from the exact accepted contract, candidate/evidence/workspace bindings, and
new revision produced inside the existing task lock/transaction. Do not perform a second unlocked
read after publishing the handoff. Tests must prove a concurrent/stale CAS cannot produce a
projection for a handoff that was not created.

- [ ] **Step 5: Update the protocol/schema and regenerate state-manifest hashes**

The JSON Schema must admit the new request/result shapes while remaining closed. `PROTOCOL.md`
must classify `project-work-unit` as read-only and explain that handoff projection is returned by
`begin-handoff`, not reconstructed by callers. Add the new module and every changed state file to
the exact manifest with fresh uppercase SHA-256 values.

- [ ] **Step 6: Run Topic 04 and Topic 06 state GREEN**

```powershell
pwsh -NoProfile -File scripts/tests/topic06-state-projection.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-foundation.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-lifecycle.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-transfer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-e2e.Tests.ps1
pwsh -NoProfile -File scripts/validate-topic04-durable-state.ps1
git diff --check -- template/.omp/state scripts/tests/topic06-state-projection.Tests.ps1
```

Expected: all pass; the state manifest covers the exact state tree; no provider is invoked.

---

### Task 3: Compose the role packets and migrate semantic output contracts

**Files:**

- Modify: `template/.omp/contracts/agent-boundary-schema.mjs`
- Modify: `template/.omp/contracts/agent-boundary-core.mjs`
- Modify: `template/.omp/agents/cheap-scout.md`
- Modify: `template/.omp/agents/worker.md`
- Modify: `template/.omp/agents/reviewer.md`
- Create: `scripts/tests/topic06-agent-contracts.Tests.mjs`

**Canonical packet:** Use the exact base fields approved in the design:
`schema_version`, `packet_type`, `role`, `objective`, `scope`, `acceptance_criteria`, `inputs`,
`constraints`, `completion_conditions`, `quality_gates`, `output_contract`, and `overlay`.
Technical task/work-unit IDs and hashes remain in wrapper metadata and are not copied into the
model-facing object.

**Semantic outputs:**

- Cheap Scout: `status`, `summary`, `capability`, `source_fitness_reason`, `fallback_path`,
  `claims`, `gaps`, `searches_performed`, `recommended_next_action`.
- Worker: `status`, `summary`, `artifact_refs`, `verification_observations`, `covered_ac_ids`,
  `blockers`, `remaining_risks`.
- Reviewer: `decision`, `summary`, `findings`, `cleared_concerns`, `recommended_action`.

Every object and nested object is closed; every string/list has an explicit bound. Reviewer
findings contain exact `severity`, `title`, `location`, `trigger`, `impact`,
`violated_contract`, and `evidence` fields. They do not contain Worker confidence, narrative
claim, or recommended verdict.

Use these exact nested contracts:

- Scout `claims` has at most 32 `{ claim, sources }` rows; each claim is at most 600 characters
  and each of at most 8 sources is `{ path, line_start, line_end }` with a project-relative path
  and positive inclusive line range. `gaps` has at most 16 strings of 400 characters.
  `searches_performed` has at most 32 `{ method, query, outcome }` rows where method is one of
  `read|grep|glob|web_search|codegraph`. `fallback_path` has at most 8 strings.
- Worker `artifact_refs` has at most 64 project-relative paths; `verification_observations` has at
  most 32 `{ command_id, status, observation }` rows with status
  `passed|failed|not_run`; `covered_ac_ids` has at most 64 unique `AC-*` values; `blockers` and
  `remaining_risks` each have at most 16 bounded strings.
- Reviewer `findings` has at most 32 rows with severity `critical|important|minor` and the seven
  required fields named above; `cleared_concerns` has at most 32 `{ concern, evidence }` rows.
  Decision is `APPROVED|APPROVED_WITH_NOTES|CHANGES_REQUESTED`; recommended action is
  `ACCEPT|REWORK_BLOCKING|ACCEPT_WITH_FOLLOWUP`. Any critical/important finding requires
  `CHANGES_REQUESTED` plus `REWORK_BLOCKING`.
- `summary` is required and at most 1,200 characters in every role. Every other free-text leaf is
  at most 1,024 characters unless the tighter bound above applies. The output contract names are
  exact `cheap_scout_v1`, `worker_v1`, and `reviewer_v1`.

**Canonical handoff packet:** `composeHandoffPacket` produces a separate closed object with
`schema_version`, `packet_type: "session_handoff"`, `task_contract`, `candidate`, `lifecycle`,
`successor`, and `transfer`. `task_contract` contains only the accepted task contract;
`candidate` contains frozen candidate/diff/artifact/evidence bindings; `lifecycle` contains current
status, next action, blockers, and open risks; `successor` contains the named successor/session
runtime; and `transfer` contains the handoff/predecessor CAS identity needed by
`accept-handoff`. It contains no transcript, terminal history, checkpoints, raw evidence body,
hidden reasoning, provider output, credential, or authority-state path.

- [ ] **Step 1: Write failing role composition and semantic-schema tests**

Create representative projection fixtures for Scout, mutating Worker, general Reviewer, and a
Reviewer specialist concern profile. Prove that:

1. all Topic 04 `AC-*` IDs and order survive;
2. no second AC namespace is generated;
3. Scout cannot receive mutation/review authority;
4. Worker ownership is an exact subset of task write scope;
5. Reviewer requires a frozen candidate plus actual diff/artifact references;
6. Reviewer input excludes every Worker result/self-assessment field;
7. specialist review changes only the closed concern profile, not the agent roster;
8. output schemas reject unknown fields, runtime metadata, hashes, absolute roots, and
   status-incompatible values; and
9. handoff composition accepts only the atomic Topic 04 projection, preserves its frozen
   contract/candidate/evidence/CAS identity, and rejects transcript/history/raw evidence fields;
   and
10. dispatch and handoff composition are byte/hash deterministic.

- [ ] **Step 2: Run RED, then implement composition and semantic validation**

```powershell
node --test scripts/tests/topic06-agent-contracts.Tests.mjs
```

Implement `composeAgentPacket` and `composeHandoffPacket` as pure projection transforms. Role
policies are frozen data in `agent-boundary-schema.mjs`; prompts never choose models or
capabilities. Reject incompatible work units or handoff projections rather than silently deleting
fields.

- [ ] **Step 3: Replace agent frontmatter outputs with the semantic-only shapes**

Retain Topic 03 routing/frontmatter: Scout and Reviewer `xhigh`, Worker `high`, all three
`blocking: true`, and all three empty `spawns`. Remove Scout `binding`, worktree/candidate hashes,
CodeGraph runtime paths/version, and every other runtime-owned echo. Add missing top-level
`type: object`, `additionalProperties: false`, `required`, nested bounds, and discriminated status
rules to Worker and Reviewer.

Update prompt prose so agents consume the canonical packet, return only their semantic result,
and never claim parent-task acceptance. Do not add a permanent Explorer, Verifier, specialist, or
fixed roster member.

- [ ] **Step 4: Prove frontmatter/core parity through OMP discovery**

The test must load the three files through the pinned OMP agent parser (or the installed OMP
token-free discovery surface), compare discovered output schemas with the canonical role schema
fingerprints, and verify malformed output is rejected both by OMP schema validation and Topic 06
semantic validation. Do not write a second YAML parser.

- [ ] **Step 5: Run GREEN and focused regressions**

```powershell
node --test scripts/tests/topic06-contract-core.Tests.mjs scripts/tests/topic06-agent-contracts.Tests.mjs
pwsh -NoProfile -File scripts/tests/topic03-topology-routing.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic05-routing.Tests.ps1
node --test scripts/tests/topic05-tool.Tests.mjs
git diff --check -- template/.omp/agents template/.omp/contracts scripts/tests/topic06-agent-contracts.Tests.mjs
```

Expected: all pass; no model/provider call; historical `.omp/schemas/*.yml` hashes are unchanged.

---

### Task 4: Reconcile native OMP results into closed receipts

**Files:**

- Modify: `template/.omp/contracts/agent-boundary-schema.mjs`
- Modify: `template/.omp/contracts/agent-boundary-core.mjs`
- Create: `scripts/tests/topic06-result-receipt.Tests.mjs`

**Native contract:** Accept only a synchronous `TaskToolDetails` object with no `async` member and
exactly one `SingleResult` per dispatched item. Match by stable `index`, exact `agent`, and exact
canonical `task` string. Each result must have exit code 0, no `error`, `retryFailure`, `aborted`,
or truncation, `requests < 300`, and `structuredOutput` with `source: "agent"`,
`status: "valid"`, and a role-valid `data` object.

**Identity policy:**

```text
cheap_scout primary  modelRole=cheap-scout, resolvedModel=omniroute/ds/deepseek-v4-flash:xhigh,
                     resolvedModelIsFallback=false
cheap_scout fallback modelRole=cheap-scout, resolvedModel=omniroute/ds/deepseek-v4-pro:xhigh,
                     resolvedModelIsFallback=true
worker high          modelRole=worker, resolvedModel=omniroute/codex/gpt-5.6-sol:high,
                     resolvedModelIsFallback=false
worker xhigh         modelRole=worker, resolvedModel=omniroute/codex/gpt-5.6-sol:xhigh,
                     resolvedModelIsFallback=false
reviewer             modelRole=reviewer, resolvedModel=omniroute/codex/gpt-5.6-sol:xhigh,
                     resolvedModelIsFallback=false
```

- [ ] **Step 1: Write the failing result matrix**

Include valid primary/fallback Scout, valid high/xhigh Worker, valid Reviewer, valid semantic
partial/blocked/failed statuses, and every fail-closed class: missing details/result, duplicate or
wrong index, task/agent mismatch, nonzero exit, error/stderr-only failure, abort/cancel, retry
failure, truncation, output schema caller override, schema unavailable/invalid, malformed data,
requests 299/300, model-role mismatch, credential fallback to parent with a false fallback flag,
agent-model override, effort cap, unauthorized Scout fallback, any Worker/Reviewer fallback,
missing/stale candidate/diff/artifact, and changed projection binding.

- [ ] **Step 2: Run RED, then implement receipt normalization**

```powershell
node --test scripts/tests/topic06-result-receipt.Tests.mjs
```

Build one receipt per item with exact top-level fields from the design. `forced_partial` is true
only in a failed receipt. `omniroute_upstream` is always `not_observed` in v1. A completed receipt
does not include raw stdout/stderr, provider errors, schema dumps, session paths, task IDs, hashes,
or native output prose.

- [ ] **Step 3: Define provisional outcome mapping**

Export `toProvisionalOutcome(receipt)`:

- Scout/Worker semantic `completed|partial|blocked|failed` maps to the same Topic 04 status;
- a structurally valid Reviewer decision maps to work-unit `completed` regardless of APPROVED vs
  CHANGES_REQUESTED, because the review work finished but did not accept the parent task;
- `artifact_refs` come only from validated Worker semantics;
- `observed_summary` is the bounded semantic summary plus decision/status, never native prose;
- an invalid receipt returns no outcome request.

- [ ] **Step 4: Run GREEN**

```powershell
node --test scripts/tests/topic06-contract-core.Tests.mjs scripts/tests/topic06-agent-contracts.Tests.mjs scripts/tests/topic06-result-receipt.Tests.mjs
git diff --check -- template/.omp/contracts scripts/tests/topic06-result-receipt.Tests.mjs
```

---

### Task 5: Implement the trusted same-name OMP `task` wrapper

**Files:**

- Create: `template/.omp/extensions/agent-task-boundary.js`
- Create: `scripts/tests/topic06-omp-wrapper.Tests.mjs`

**Exported test seams:**

```js
loadManagedRuntime(moduleUrl)
deriveActiveMode(entries)
buildNativeTaskParams(composedItems)
parseStateEnvelope(stdout)
createManagedTaskTool(pi, runtime, agentCatalog, dependencies?)
```

The default extension factory validates its installed runtime and then calls
`pi.registerTool(createManagedTaskTool(...))`. The tool definition is exact name `task`, essential,
strict, approval `exec`, and uses a TypeBox union of the closed single/batch managed schemas. Its
execute signature is `(toolCallId, params, signal, onUpdate, ctx)`.

During extension startup, call the OMP-exported `pi.pi.discoverAgents(pi.cwd)` once and build a
closed catalog for exactly `cheap-scout`, `worker`, and `reviewer`. Reconcile each parsed
`AgentDefinition` against installed policy: project source, exact model role, exact thinking level,
`blocking === true`, empty spawn policy, permitted tools, and canonical output-schema fingerprint.
Missing/duplicate/mismatched selected agents abort extension startup; do not parse frontmatter in
the wrapper or rely only on installer-time file bytes.

- [ ] **Step 1: Write failing wrapper tests with a fake native tool**

Inject a fake `ctx.invokeTool` and fake Topic 04 process adapter. Prove invalid input, projection
failure, role mismatch, plan-mode mutation, async/nested agent policy, isolation mismatch, and one
invalid batch item invoke native zero times. Prove a valid single calls native exactly once and a
valid batch calls native exactly once after all items pass.

For native parameters, translate managed Worker `xhigh` to OMP `effort: "hi"`; omit native effort
for Worker `high`; never send caller `outputSchema`, `schemaMode`, model IDs, or arbitrary context.
Use this fixed canonical batch context:

```json
{"packet_type":"agent_dispatch_batch_context","schema_version":1,"statement":"Each task field is one complete independent canonical Topic 06 packet."}
```

Every native batch item has a deterministic unique `name`, exact selected `agent`, canonical JSON
in `task`, and only the reconciled `isolated`/`effort` controls.

- [ ] **Step 2: Implement safe Topic 04 invocation**

Use `fs.mkdtempSync(path.join(os.tmpdir(), "agent-tasks-topic06-"))`, write one closed request file,
invoke the installed absolute `pwsh` with an argument array:

```text
-NoProfile -NonInteractive -File <absolute agent-tasks.ps1> -RequestPath <request.json>
```

Bound execution to 30 seconds and stdout/stderr to 128 KiB, pass the outer AbortSignal, accept
exactly one JSON line, and remove only the exact generated temporary directory in `finally`.
Never interpolate a shell command or copy stderr into a tool result.

- [ ] **Step 3: Implement plan/batch/native/result/outcome flow**

Derive mode from the last `mode_change` on `ctx.sessionManager.getBranch()`. Missing history means
`none`; malformed/unsupported history blocks Worker. Worker requires a mutating task and nonempty
owned scope, so it is always refused in plan mode. Scout/Reviewer require read-only role policy.

After native settlement, call `project-work-unit` again for every item before accepting any result.
Compare immutable work-unit bytes, task contract, worktree, candidate/diff/artifact bindings, lease,
and the original revision/hash. Any external change is `candidate_drift` or `outcome_record_failed`
and no outcome recording starts. Validate native `outputPath`/`patchPath`/branch metadata as bounded
paths under the native `projectAgentsDir`; validate Worker semantic artifact refs as unique
project-relative paths allowed by the work-unit outputs/ownership. Missing, outside-root, stale, or
unexpected isolation artifacts are `artifact_stale`.

Validate all results and post-run projections before recording any outcome. For a valid batch,
record provisional outcomes in input order, chaining the revision/hash returned by each successful
`record-work-unit-outcome` call. A CAS failure stops further recording, marks the batch error, and
does not roll back earlier provisional sibling outcomes. If native batching is disabled and OMP
returns its pre-provider shape refusal, return `native_task_failed`; the Tech Lead reissues managed
single calls sequentially rather than bypassing the wrapper.

- [ ] **Step 4: Return a bounded managed tool result**

`details` is a closed `agent_boundary_tool_details` object containing `managed: true`, batch
status, and receipts. User-facing `content` contains only a short status/reason/next-action line.
Set `isError: true` whenever any item is invalid or not `completed`. A valid `partial`, `blocked`,
or `failed` semantic result may be recorded provisionally but cannot satisfy a stage barrier.

- [ ] **Step 5: Run wrapper GREEN and pinned-source sentinels**

```powershell
node --test scripts/tests/topic06-omp-wrapper.Tests.mjs
git -C _research/upstreams/oh-my-pi rev-parse HEAD
git -C _research/upstreams/oh-my-pi status --short
git diff --check -- template/.omp/extensions scripts/tests/topic06-omp-wrapper.Tests.mjs
```

The test must assert the clean pinned commit
`3a8591a8af5b6d200088d12ca75a5517cb064fa8` and source sentinels for same-name delegation,
ignored generic result-handler errors, `SingleResult` fields, plan-mode tool stripping, trusted
extension loading, config overlay order, and the 1.5x forced-yield threshold.

---

### Task 6: Install and launch the boundary as one atomic managed component

**Files:**

- Create: `template/.omp/contracts/managed-runtime.yml`
- Create: `template/.omp/contracts/component-manifest.json`
- Create: `template/.omp/bin/omp-managed.ps1`
- Modify: `scripts/install-template.ps1`
- Modify: `scripts/uninstall-template.ps1`
- Create: `scripts/tests/topic06-installer.Tests.ps1`
- Create: `scripts/tests/topic06-managed-runtime.Tests.ps1`

**Component:** Name it `agent-boundary`. Add it to the default component list. It depends on
compatible `agents`, `state`, and `config` selected in the same operation or already installed.
Its source manifest lists exact SHA-256 values for the core/schema/CLI/overlay/wrapper/launcher,
the three selected agent files, and the Topic 04 state manifest. Generated target files are
`.omp/contracts/runtime.json` and `.omp/contracts/install-record.json`.

- [ ] **Step 1: Write failing closed-manifest and dependency tests**

Reject unknown/duplicate/unsafe manifest paths, missing/hash-drifted files, unsupported manifest
version, PowerShell below 7.4, missing state/agents/config, incompatible role routes, partial
component selection, and a stale installed dependency. Prove dry-run writes nothing.

The role-policy manifest contains the exact identities from Task 4, `soft_request_budget: 200`,
`forced_partial_requests: 300`, selected agent `blocking/spawns` expectations, and supported OMP
versions `17.2.10` and `17.2.12`. A different version refuses managed startup until compatibility
evidence updates the manifest; bare OMP remains available.

- [ ] **Step 2: Run installer RED, then implement transactional installation**

```powershell
pwsh -NoProfile -File scripts/tests/topic06-installer.Tests.ps1
```

Extend the existing backup/staging transaction; do not create a second installer. Validate every
source/dependency before the first target write, copy to staging, create the closed runtime/install
records, validate staging hashes, then publish. Any failure restores the pre-operation `.omp`
bytes. Never overwrite credentials/models files.

- [ ] **Step 3: Add the final immutable overlay**

`template/.omp/contracts/managed-runtime.yml` contains exactly:

```yaml
task:
  softRequestBudget: 200
```

The launcher allows caller `--config` overlays but appends this absolute overlay last. It rejects
caller `--trusted-extension`, `--extension`, `-e`, and `--hook` forms, including `--flag=value`, so
the wrapper is the sole trusted extension and cannot be shadowed. It uses an argument array, keeps
the caller working directory, forwards exit code/signals, and never uses `Invoke-Expression`.

- [ ] **Step 4: Implement dual runtime validation**

The launcher validates `runtime.json`, manifest/file hashes, installed OMP version, exact absolute
wrapper/overlay paths, and Topic 04/agent dependencies before starting OMP. The extension repeats
the load-bearing hash/runtime checks when loaded; a missing or invalid trusted module throws during
startup. This duplication is deliberate: launcher validation gives a useful local message, while
extension validation prevents direct trusted-extension use with a forged/stale launcher state.

- [ ] **Step 5: Retire the inert installer `schemas` component without changing evidence bytes**

Remove `schemas` from defaults and component mapping. Explicit `-Components schemas` returns the
same retired-component class used for `policies`. Keep the four YAML files byte-identical for the
Phase 00 protected-surface tests; installation/status/docs must label them historical and
non-authoritative.

- [ ] **Step 6: Test rollback and exact cleanup**

Uninstall restores the timestamped backup, removes generated boundary files only when their
install-record paths/hashes match, and retains operational `agent-tasks` state outside `.omp`.
Missing/corrupt records cause a safe refusal, not wildcard deletion. Add apply/failure/rollback
fixtures for project and user targets.

- [ ] **Step 7: Run installer/runtime GREEN**

```powershell
pwsh -NoProfile -File scripts/tests/topic06-installer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic06-managed-runtime.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic03-installer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-installer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic05-installer.Tests.ps1
git diff --check -- template/.omp/contracts template/.omp/bin scripts/install-template.ps1 scripts/uninstall-template.ps1 scripts/tests/topic06-installer.Tests.ps1 scripts/tests/topic06-managed-runtime.Tests.ps1
```

The managed-runtime test uses a disposable install and token-free OMP RPC/config calls to prove:
trusted wrapper load, `task` source replacement, core/native delegation seam presence, overlay-last
value 200, plan/normal mode persistence, and continued discovery of required agents, commands,
skills, rules, and the CodeGraph custom tool. Missing/invalid wrapper startup must be nonzero. No
prompt that can invoke a provider is sent.

---

### Task 7: Add adversarial lifecycle and installed-boundary coverage

**Files:**

- Create: `scripts/tests/topic06-agent-boundary.Tests.ps1`
- Modify: `scripts/tests/topic06-omp-wrapper.Tests.mjs`
- Modify: `scripts/tests/topic06-managed-runtime.Tests.ps1`

- [ ] **Step 1: Add an end-to-end disposable Topic 04 fixture**

Create active task/work units for Scout, Worker, Reviewer, and a two-item batch. Invoke the wrapper
with fake native settled results but the real installed contract core and real Topic 04 CLI. Prove
projection -> packet -> result -> provisional outcome round trips without accepting/freezing/
closing the parent task.

- [ ] **Step 2: Add the full fail-closed mutation table**

Mutate one load-bearing field at a time: work-unit ownership, AC list, task revision/hash/lease,
worktree, candidate, diff, artifact reference, packet bytes, semantic output, schema source/status,
model role/resolved model/fallback flag, effort suffix, request count, abort/truncation, agent
blocking/spawns, component/agent/state hash, active plan mode, batch item, and outcome CAS. Each
mutation must have one named expected reason code and must not produce a completed receipt.

- [ ] **Step 3: Prove reviewer independence and inline fallback**

Seed a Worker summary with a distinctive sentinel. Assert the Reviewer packet and canonical bytes
do not contain it, while actual artifact/diff/contract data does. Remove the managed component and
prove the documented next action is “Tech Lead works inline”; no self-packet, self-review, native
task call, or fabricated receipt is produced.

- [ ] **Step 4: Prove unmanaged facilities cannot satisfy managed acceptance**

Construct result artifacts shaped like OMP Vibe/eval/internal-agent output without a Topic 06
receipt. Assert Topic 06/Topic 04 consumers reject them as acceptance evidence. Record
`OPEN-T06-RUNTIME-01` but do not patch or fork OMP.

- [ ] **Step 5: Run the adversarial suite twice**

```powershell
pwsh -NoProfile -File scripts/tests/topic06-agent-boundary.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic06-agent-boundary.Tests.ps1
```

Expected: identical pass counts and deterministic hashes; no residual temp directory, task lock,
worktree, OMP process, or changed ordinary user cache.

---

### Task 8: Project the approved decision into authority, phase, and operator docs

**Files:**

- Modify: `spec/key/04-decision-log.md`
- Modify: `spec/key/01-dna.md`
- Modify: `spec/key/02-repo-synthesis.md`
- Modify: `spec/key/03-token-quality-model.md`
- Modify: `spec/key/05-coverage-audit.md`
- Modify: `spec/03-agent-topology.md`
- Modify: `spec/05-context-and-token-model.md`
- Modify: `spec/06-structured-output.md`
- Modify: `spec/08-isolation-and-concurrency.md`
- Modify: `spec/09-model-routing.md`
- Modify: `spec/10-verification-and-review.md`
- Modify: `spec/12-installation-and-rollback.md`
- Modify: `spec/13-validation-and-evaluation.md`
- Modify: `spec/15-security-and-failure-recovery.md`
- Modify: `spec/README.md`
- Modify: `spec/phases/phase-01-runtime-correctness.md`
- Modify: `spec/phases/phase-02-core-orchestration.md`
- Modify: `spec/phases/phase-03-context-efficiency.md`
- Modify: `spec/phases/phase-04-quality-system.md`
- Modify: `spec/phases/phase-05-installation-hardening.md`
- Modify: `spec/phases/phase-06-evaluation.md`
- Modify: `spec/phases/phase-07-stabilization.md`
- Modify: `registry/omp-compatibility.yml`
- Create: `docs/agent-boundaries.md`
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/workflow-v0.md`
- Modify: `docs/task-state.md`
- Modify: `docs/security.md`
- Modify: `docs/installation.md`
- Modify: `docs/customization.md`
- Modify: `docs/rollback.md`
- Modify: `docs/token-strategy.md`
- Modify: `docs/final-report.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Add one decision-log entry and one authority rule, then project outward**

State the selected mechanism, local/no-Git policy, managed/unmanaged boundary, inline fallback,
Topic 04 authority, exact Topic 03 model/effort reconciliation, Reviewer independence, managed
v1 async/nested refusal, final soft-budget overlay, and nonblocking `OPEN-T06-RUNTIME-01`. Do not
rewrite Phase 00 evidence or present research dossiers as current runtime authority.

- [ ] **Step 2: Reconcile prior contradictions rather than append duplicate prose**

Remove active claims that all agents use free-form prose packets, that static schema presence proves
runtime enforcement, that `.omp/schemas` is installed/runtime authority, or that a fixed
Explorer/Worker/Verifier/Reviewer roster is required. Preserve conditional Cheap Scout and dynamic
specialist profiles. Keep verification/review selection under the accepted task contract.

- [ ] **Step 3: Document the operator workflow**

`docs/agent-boundaries.md` must show:

1. creating the Topic 04 work unit;
2. using `.omp/bin/omp-managed.ps1`;
3. managed single and batch call shapes;
4. how high vs xhigh Worker selection works;
5. Scout Flash -> Pro disclosure;
6. Reviewer ARTIFACT + CONTRACT input and exclusion of Worker CLAIM;
7. receipt/outcome meaning;
8. plan-mode/batch/async/nested behavior;
9. inline fallback when managed dispatch is unavailable; and
10. why bare OMP/Vibe/eval output is unmanaged.

No example may contain a real credential, absolute user home, hidden reasoning, or fabricated
OmniRoute upstream.

- [ ] **Step 4: Run authority drift searches**

```powershell
rg -n "task-packet\.schema|agent-result\.schema|review-result\.schema|verification-result\.schema|all five agents|separate Verifier|dedicated Reviewer" README.md docs spec template scripts
rg -n "OPEN-T06-RUNTIME-01|omp-managed|agent_boundary_receipt|project-work-unit|softRequestBudget" README.md docs spec registry template scripts
git diff --check -- README.md CHANGELOG.md docs spec registry/omp-compatibility.yml
```

Every first-search hit must be explicitly historical/non-authority or corrected. Every new runtime
claim must have implementation/test/source evidence.

---

### Task 9: Add focused validation, deterministic evidence, and final regression

**Files:**

- Create: `scripts/lib/topic06-agent-boundary.ps1`
- Create: `scripts/validate-topic06-agent-boundary.ps1`
- Create: `scripts/capture-topic06-evidence.ps1`
- Modify: `scripts/validate-template.ps1`
- Create: `docs/evidence/current-product/topic-06/deterministic.json`
- Create: `docs/evidence/current-product/topic-06/manifest.json`
- Create: `codex-topic06-agent-boundary-contracts-changelog.md`

- [ ] **Step 1: Write failing validator mutation tests before the validator**

Add deterministic mutations for every acceptance criterion: core/schema/CLI, projection/handoff,
agent outputs, wrapper registration/delegation, launcher/overlay/component manifest, exact route
identity, forced partial threshold, plan mode, async/nested prohibition, Reviewer claim exclusion,
schemas retirement, installer rollback, evidence manifest, and `OPEN-T06-RUNTIME-01` scope. A
missing required surface and a semantic-equivalent fail-open wording must both fail.

- [ ] **Step 2: Implement one reusable focused-validator function**

`Test-Topic06AgentBoundaryContract -RepositoryRoot` returns closed PASS/WARN/FAIL records. The
entry script prints counts and exits nonzero on any FAIL. Integrate it into
`scripts/validate-template.ps1` without copying the assertions. The full validator must list every
new required file and must no longer require the historical schemas as installed components.

- [ ] **Step 3: Capture model-free current-product evidence**

`capture-topic06-evidence.ps1` runs the focused Node/PowerShell suites, token-free installed OMP
RPC/config probes, pinned-source/hash checks, installer dry-run/apply/rollback fixture, and full
validator. It writes canonical JSON with:

```text
schema_version, record_type, status, captured_at_utc, provider_calls=0,
model_processes_started=0, repository, environment, pinned_omp, cases, limitations
```

The manifest hashes the evidence plus implementation/tests/authority docs and records dirty-tree
identity as `sha256(sorted_git_porcelain_v1_lines_utf8_lf)`. It must not claim a clean repository
or Git commit containing Topic 06.

- [ ] **Step 4: Run the complete fresh verification set**

```powershell
node --test scripts/tests/topic06-contract-core.Tests.mjs scripts/tests/topic06-agent-contracts.Tests.mjs scripts/tests/topic06-result-receipt.Tests.mjs scripts/tests/topic06-omp-wrapper.Tests.mjs
pwsh -NoProfile -File scripts/tests/topic06-state-projection.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic06-installer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic06-managed-runtime.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic06-agent-boundary.Tests.ps1
pwsh -NoProfile -File scripts/validate-topic06-agent-boundary.ps1
pwsh -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
pwsh -NoProfile -File scripts/validate-topic04-durable-state.ps1
pwsh -NoProfile -File scripts/validate-topic05-progressive-retrieval.ps1
pwsh -NoProfile -File scripts/validate-template.ps1
git -C _research/upstreams/oh-my-pi status --short
git diff --check
```

Expected: all Topic 06 and prior focused validators pass; the full validator has zero FAIL (only
pre-existing explicitly known warnings may remain); pinned OMP source is clean; no model/provider
call occurs; whitespace check passes.

- [ ] **Step 5: Capture and revalidate evidence**

```powershell
pwsh -NoProfile -File scripts/capture-topic06-evidence.ps1
pwsh -NoProfile -File scripts/validate-topic06-agent-boundary.ps1
Get-FileHash docs/evidence/current-product/topic-06/deterministic.json -Algorithm SHA256
Get-FileHash docs/evidence/current-product/topic-06/manifest.json -Algorithm SHA256
git status --short
```

Update `codex-topic06-agent-boundary-contracts-changelog.md` with exact files, commands, pass/
warning counts, evidence hashes, known limitations, confirmation of zero provider calls, local
no-Git status, and the still-nonblocking `OPEN-T06-RUNTIME-01` note.

## Completion boundary

Topic 06 is complete only when AC-1 through AC-14 in the approved design have direct passing
evidence, all prior focused validators remain green, installation/rollback is transactional, and
the managed launcher produces a verifiable attachment without a model call. A universal hook for
unrelated OMP internal agent facilities is explicitly not required; if later needed, hand
`OPEN-T06-RUNTIME-01` to an upstream-runtime specialist rather than widening this local wrapper.

At completion, leave every change unstaged in the local working tree and report the exact test/
validator/evidence results. Do not create a commit merely because implementation is finished.
