# Topic 06 — Agent Boundary Contracts Design

**Status:** approved by the user on 2026-08-13

**Decision:** portable deterministic contract core plus a trusted same-name OMP `task` wrapper

**Storage policy:** local working-tree documentation; no commit, push, branch, or PR is authorized

## 1. Purpose

Topic 06 defines the information that may cross a template-managed agent or session boundary and
the deterministic mechanism that validates that boundary. It closes the gap between Topic 04's
durable task authority, Topic 03's selected actors/model routes, Topic 05's retrieval overlay, and
the runtime `task` tool that actually launches an OMP worker.

The design optimizes for accepted-outcome quality and false-completion resistance. It does not
spawn an agent merely to create a packet, create a packet for the main-session Tech Lead working
inline, or introduce another lifecycle authority beside Topic 04.

## 2. Approved Decisions

```yaml
topic: 06-task-packet-and-result-contracts
decision: trusted_task_wrapper_with_portable_contract_core
status: approved
rationale:
  - task state remains durable authority while packets and receipts are bounded projections
  - the same-name wrapper can validate both sides of native OMP task execution
  - Claude and OMP adapters can share one deterministic contract core
  - OMP isolation, batching, routing, cancellation, and task lifecycle remain native
benefits:
  - invalid boundaries fail before model dispatch
  - plausible but invalid worker output cannot become a successful receipt
  - reviewer input is not primed by the writer's self-assessment
  - packet/result content is closed, compact, and secret-scanned
tradeoffs:
  - managed dispatch must use the supported trusted launcher/profile
  - managed v1 rejects asynchronous and nested agent dispatch
  - universal control of every unrelated OMP internal agent facility would require an upstream hook
failure_modes:
  - missing contract core or state authority refuses dispatch
  - invalid packet refuses dispatch
  - invalid/partial/fallback-incompatible result returns a failed receipt
  - outcome recording CAS failure leaves the result unaccepted and requires reconciliation
fallback:
  - the Tech Lead works inline when a managed subagent boundary is unavailable
  - no packet is created for that inline path
affected_topics:
  - Topic 03 model and effort reconciliation
  - Topic 04 work-unit projection and handoff
  - Topic 05 retrieval result overlay
  - Topic 08 runtime adapter and hook ownership
  - Topic 09 review and verification evidence
  - Topic 10 security and recovery
  - Topic 11 evaluation
  - Topic 12 installation and rollback
open_runtime_note:
  - OPEN-T06-RUNTIME-01
```

## 3. Authority and Terminology

The four relevant objects are deliberately different:

| Object | Authority | Lifetime | Purpose |
|---|---|---|---|
| Task state | Topic 04 durable core | task lifecycle | accepted objective, ACs, ownership, candidate, evidence, CAS |
| Work-unit contract | Topic 04 immutable record | task lifecycle | one bounded unit that may be delegated |
| Agent packet | Topic 06 projection | one dispatch | minimum role-specific context sent to an agent |
| Boundary receipt | Topic 06 normalized observation | one dispatch/result | states what runtime/result checks actually passed |
| Handoff packet | Topic 04 transfer projection using Topic 06 envelope rules | one session transfer | transfers ownership to a named successor |

No packet or receipt can accept the parent task. A work-unit outcome remains provisional. Only the
Topic 04 lifecycle can freeze and accept a candidate.

## 4. Scope

### In scope

- canonical JSON transport for agent dispatch and session handoff;
- base envelopes and Scout, Worker, General Reviewer, Specialist-profile, and Handoff overlays;
- deterministic composition, closed validation, canonical serialization, size bounds, and secret
  screening;
- a read-only Topic 04 projection for one immutable work unit;
- a same-name OMP `task` wrapper that delegates to the native built-in;
- post-result reconciliation against native OMP result details;
- provisional work-unit outcome recording;
- batch, plan-mode, cancellation, partial-result, model/effort, and fallback behavior;
- local installation/activation evidence needed to prove the selected attachment point; and
- portable interfaces usable later by a Claude adapter.

### Out of scope

- changing Topic 03's model/provider choices;
- wrapping or changing OmniRoute;
- creating a second task-state reducer;
- creating a custom compaction engine;
- accepting a task or candidate from an agent result;
- forwarding transcripts, hidden reasoning, raw terminal history, or repository dumps;
- supporting managed asynchronous or nested agent execution in v1; and
- claiming a tamper-proof sandbox against a local operator who intentionally bypasses the managed
  launcher.

## 5. Architecture

```text
Topic 04 task authority
  -> immutable work-unit projection
  -> Topic 06 portable composer/linter
  -> canonical role packet
  -> trusted OMP task wrapper
  -> native OMP task tool
  -> native TaskToolDetails / SingleResult
  -> Topic 06 result validator
  -> provisional Topic 04 work-unit outcome
  -> compact boundary receipt
```

The implementation has four layers:

1. **Portable contract core** — dependency-free JavaScript containing the closed schemas,
   canonicalization, composition, semantic validation, size accounting, and safe error envelopes.
2. **Topic 04 projection adapter** — a read-only operation that returns exactly the immutable task
   and work-unit fields required by the composer. It never returns raw authority records.
3. **OMP adapter** — a trusted extension that re-registers `task`, composes/validates the packet,
   delegates to the unwrapped native `task` via `ctx.invokeTool`, validates native result details,
   and records a provisional outcome.
4. **Runtime launch/installation adapter** — an exact trusted-extension allowlist. The packet
   wrapper is last among any explicitly trusted extensions, and a final managed settings overlay
   pins the runtime values whose effects are otherwise not observable in settled task details.
   Missing/invalid trusted modules or managed overlays abort startup.

Claude later invokes the same portable contract core and Topic 04 projection operation through a
Claude-specific hook/adapter. It does not copy the schemas or lifecycle rules.

## 6. Managed Dispatch Input

The wrapper replaces native free-form `task` input with a narrow managed request. It accepts either
one item or a batch, never both.

```json
{
  "task_id": "T000001",
  "work_unit_id": "WU-001",
  "agent": "worker",
  "role": "worker",
  "effort": "high",
  "isolated": true
}
```

```json
{
  "tasks": [
    {
      "task_id": "T000001",
      "work_unit_id": "WU-RETRIEVAL-001",
      "agent": "cheap-scout",
      "role": "cheap_scout"
    },
    {
      "task_id": "T000001",
      "work_unit_id": "WU-REVIEW-001",
      "agent": "reviewer",
      "role": "reviewer"
    }
  ]
}
```

The caller does not supply objective text, AC text, arbitrary prompt additions, model IDs, output
schema, worktree paths, candidate hashes, allowed subagents, or raw state. The wrapper resolves
those from installed role policy plus Topic 04 authority. This prevents the model-facing caller
from overriding load-bearing contract fields.

`effort` is permitted only where Topic 03 gives the Tech Lead a per-spawn choice. Reviewer effort
is resolved from its fixed role policy; Cheap Scout's primary/fallback effort is resolved from its
route policy. `isolated` is accepted only for a write-capable work unit and must reconcile with
Topic 04 ownership and OMP capability.

## 7. Canonical Agent Packet

The model-facing packet is canonical JSON with this closed base shape:

```json
{
  "schema_version": 1,
  "packet_type": "agent_dispatch",
  "role": "worker",
  "objective": "Implement the bounded work unit.",
  "scope": {
    "in_scope": ["src/example.ts"],
    "out_of_scope": ["unrelated modules"],
    "ownership": ["src/example.ts"]
  },
  "acceptance_criteria": [
    { "id": "AC-001", "text": "The selected behavior is implemented.", "mandatory": true }
  ],
  "inputs": {
    "relevant_files": ["src/example.ts"],
    "artifact_refs": [],
    "candidate_ref": null,
    "diff_ref": null
  },
  "constraints": [],
  "completion_conditions": [],
  "quality_gates": [],
  "output_contract": "worker_v1",
  "overlay": {}
}
```

Rules:

- Topic 04 assigns and owns all `AC-*` IDs. Topic 06 creates no second AC namespace.
- Project-relative bounded paths are preferred in model text. Absolute authority roots, session
  files, state paths, credentials, hashes, and technical runtime IDs stay in wrapper metadata.
- The agent is not required to echo task ID, work-unit ID, candidate hash, contract hash, model
  identity, effort, isolation, or packet hash. The tool binds those facts to the result.
- Dispatch metadata already enforced by OMP/config is not repeated in the prompt.
- Unknown properties are rejected at every object level.
- Arrays are sorted only when order is semantically irrelevant. Acceptance criteria and
  completion conditions retain authority order.
- Unicode is NFC-normalized, line endings are normalized, and duplicate paths/AC IDs are rejected.

## 8. Role Overlays

### 8.1 Cheap Scout

The Scout overlay contains one bounded retrieval question, source-fitness guidance, allowed
capability, evidence requirements, and the Topic 05 retrieval contract. It cannot contain review,
acceptance, mutation, or model-selection authority.

Its semantic result contains status, cited claims, gaps, searches performed, fallback path, and a
recommended next action. Runtime binding/model metadata is attached by the wrapper rather than
echoed by the Scout.

The approved Flash -> Pro availability fallback remains Topic 03 policy. A Pro result is valid only
when native result metadata proves it is the configured Scout fallback; the receipt discloses it.
Quality weakness returns `partial`; it does not trigger an opaque model retry.

### 8.2 Worker

The Worker overlay contains exact ownership, permitted outputs, required verification commands,
and mutation/isolation intent. The Worker returns semantic status, changed artifact references,
verification observations, covered AC IDs, blockers, and remaining risks.

The wrapper validates artifacts against the retained worktree/candidate and records only a
provisional work-unit outcome. Worker prose cannot claim parent-task acceptance.

### 8.3 General Reviewer

The Reviewer overlay contains:

- frozen candidate and actual diff/artifact references;
- the accepted task contract and selected AC IDs;
- dynamic concern profile and severity policy;
- exact verification/reproduction commands when applicable; and
- explicit exclusions and prior accepted dispositions only when they are current authority.

It never contains the Worker's self-assessment, completion claim, narrative result, confidence, or
recommended verdict. Reviewer output contains findings and a review decision only.

### 8.4 Specialist profile

Specialist review is an additional closed concern profile on the same Reviewer contract, not a new
permanent discovered agent or fixed roster member. It names the concern, evidence obligations,
scope, severity boundary, and stop condition. The Reviewer remains exact `xhigh` under Topic 03.

### 8.5 Session handoff

Handoff is not a `task` dispatch. `begin-handoff` creates the durable transfer record and returns a
safe canonical projection in the same task lock/transaction. The handoff packet contains the task
contract identity, frozen candidate/evidence bindings, current lifecycle status, next action,
blockers, open risks, and the named successor/runtime.

It contains no transcript, hidden reasoning, terminal history, raw state record, or predecessor
self-evaluation. `accept-handoff` validates the existing Topic 04 CAS, candidate, workspace, and
evidence bindings before ownership changes.

## 9. Result and Receipt Contract

The model produces only its role-specific semantic output. The wrapper combines that output with
native OMP observations to produce this closed receipt:

```json
{
  "schema_version": 1,
  "record_type": "agent_boundary_receipt",
  "status": "completed",
  "reason_code": "ok",
  "role": "worker",
  "semantic_result": {},
  "runtime": {
    "structured_output": "valid",
    "model_role": "worker",
    "resolved_model": "omniroute/codex/gpt-5.6-sol:high",
    "fallback_used": false,
    "effort": "high",
    "aborted": false,
    "forced_partial": false,
    "omniroute_upstream": "not_observed"
  },
  "outcome": {
    "recorded": true,
    "status": "completed",
    "artifact_refs": []
  }
}
```

Technical request bindings and hashes may exist in tool `details` or local state mutation input;
they are omitted from model-authored fields and from ordinary user-facing prose.

The wrapper rejects completion when any required observation is absent or incompatible:

- nonzero exit, error, abort, cancellation, or incomplete settlement;
- `structuredOutput.status` other than `valid`;
- schema override or unavailable validation;
- forced soft-budget partial output represented as completion;
- unexpected role/model/effort identity;
- Worker or Reviewer fallback not selected by Topic 03;
- Scout fallback outside the exact approved chain;
- missing/stale artifact, candidate, diff, worktree, or AC binding;
- invalid role semantic status or unknown properties; or
- inability to record the provisional outcome under current CAS.

The pinned OMP result has no dedicated `budgetStopRequested`/forced-yield discriminator. Managed
sessions therefore load a final immutable overlay with `task.softRequestBudget: 200`; the wrapper
uses the same policy value and rejects any settled result with `requests >= 300` (the runtime's
1.5x force-stop threshold). This is intentionally conservative: even a voluntary completion at
that boundary is not accepted. The launcher appends this overlay after every other config source,
and installed-runtime evidence proves the effective threshold. An unmanaged session cannot claim
this guarantee.

An invalid result returns `isError: true`, a safe reason code, and a bounded next action. Raw stderr,
provider diagnostics, schema dumps, and secret-bearing child output never enter model-facing text.

## 10. State Projection

Topic 04 receives a new read-only `project-work-unit` operation with this request:

```json
{
  "task_id": "T000001",
  "work_unit_id": "WU-001"
}
```

It returns only:

- task/work-unit identity for tool metadata;
- objective, authority label, execution mode, write scope, ACs, obligations, and owned ignored
  outputs needed by the packet;
- immutable work-unit inputs, outputs, ownership, dependencies, and completion conditions;
- reconciled observation/authoritative worktree identity;
- current candidate/diff/artifact references needed by the selected overlay;
- current revision, revision hash, and lease generation for later outcome CAS; and
- a projection hash computed by the state core.

It does not return checkpoints, full revision history, raw evidence bodies, session history,
credentials, authority filesystem paths, or unrelated task records. The state schema and protocol
remain authoritative; adapters do not parse private authority files directly.

If projection validation, ownership, candidate reconciliation, or the state core fails, no native
task call occurs. The Tech Lead may continue inline without a packet.

## 11. OMP Attachment Point

The selected OMP adapter re-registers the built-in name `task`. OMP captures the unwrapped native
tool before applying extension overrides and supplies same-name `ctx.invokeTool`, so the wrapper
can delegate without copying OMP's executor.

This is intentionally not implemented as only `tool_call`/`tool_result` listeners. OMP blocks a
pre-call handler failure, but a generic result-handler timeout/error can be logged and ignored.
The same-name wrapper owns its entire execute promise and therefore cannot silently lose the
post-result validation step.

The supported launcher passes the wrapper as an absolute `--trusted-extension` path. Trusted mode
uses an exact allowlist, disables ambient extension discovery, and aborts startup when a trusted
module fails to load. If additional trusted extensions are selected later, they are listed
explicitly and the Topic 06 wrapper remains last. Installed-runtime tests verify that no later
extension shadows `task` and that required skills, commands, rules, and custom tools still load as
intended.

The launcher also appends `--config <absolute-managed-overlay>` as the final config overlay. The
overlay is closed, installation-hashed, and pins `task.softRequestBudget: 200`. Callers cannot add
another config after it through the managed launcher. This gives the wrapper a deterministic
forced-partial threshold without parsing private OMP settings or changing OMP source.

Direct bare `omp` execution is outside the managed-workflow guarantee. It is not treated as a
malicious security boundary for this single-user local template. Documentation and status output
must make the managed entrypoint visible and distinguish managed from unmanaged sessions.

## 12. Plan Mode, Batch, Async, Nested, and Isolation

### Plan mode

OMP records mode changes in the public read-only session history. Before native dispatch the
wrapper derives the active branch's latest `mode_change` entry. A `plan` mode blocks any mutating
Worker contract before dispatch. Read-only Scout/Reviewer packets may proceed only when their
selected capabilities remain valid under the restricted child contract.

Malformed, ambiguous, or unsupported mode history is unsafe for a mutating role and therefore
blocks it. Runtime probes compare this derivation with OMP's actual plan-mode behavior on the
pinned version.

### Batch

The wrapper composes, lints, state-reconciles, and capability-checks every item before invoking the
native batch. One invalid item prevents the entire batch from starting. Native OMP remains
responsible for synchronous fan-out, ordering, concurrency limits, cancellation, and isolation.

After settlement, every result is validated independently. Successful sibling outcomes may be
recorded provisionally, but the batch barrier is failed while any required item is invalid. No
rollback of already-produced isolated artifacts is implied; integration/acceptance remains closed.

### Async

Managed v1 requires selected roles to declare `blocking: true`. A nonblocking agent cannot supply
a final receipt in the same tool result and is rejected before dispatch. The current selected
Cheap Scout, Worker, and Reviewer satisfy the stage-barrier requirement.

### Nested agents

Managed v1 rejects roles with delegated spawn authority. Current selected worker definitions do
not receive a nested `task` capability. A future nested design must prove that the same contract
core and wrapper are present at every child boundary before this restriction can be relaxed.

### Isolation

Topic 06 does not implement worktrees or merging. It validates that the requested isolation intent
matches the role, Topic 04 ownership, and effective OMP capability, then delegates to native OMP.
The receipt records the observed artifact/merge outcome needed by later integration.

## 13. Size and Token Discipline

The deterministic hard safety boundary is expressed in UTF-8 bytes, object depth, string length,
array count, and field-specific limits. It does not pretend that OMP's default byte/4 estimator is
an exact tokenizer.

When the accurate native tokenizer is available, telemetry may additionally record measured
tokens and the tokenizer method. Missing token measurement is `not_measured`, not an estimate
presented as fact. Topic 11 owns promotion thresholds and final per-role budgets; Topic 06 begins
with the existing 300–800 target and 1,200 warning/hard-contract evidence as a provisional packet
budget, with role overlays measured separately.

Cheap Scout's inexpensive model quota does not justify bloated packets. It removes pressure to
micro-optimize Scout reasoning tokens, not the quality/security reasons for a bounded boundary.

## 14. Security and Privacy

The contract core recursively rejects forbidden property names and suspicious secret values,
reusing Topic 04's vocabulary rather than creating divergent lists. At minimum it rejects:

- transcript/conversation/history/tool-history/reasoning/thought/chain-of-thought fields;
- credential, authorization header, cookie, API key, token, private key, and secret fields;
- raw stdout/stderr/provider payloads;
- absolute authority/state/session paths in model-facing content; and
- unbounded full-file or repository-dump payloads.

Repository content remains untrusted data, never executable packet instructions. The wrapper uses
argument arrays rather than shell interpolation when invoking the state core. State/core stderr is
diagnostic-only and never copied into the tool result.

## 15. Failure Codes and Fallback

The outer envelope uses a closed reason-code set including:

```text
ok
managed_component_unavailable
state_unavailable
task_not_active
work_unit_missing
work_unit_incompatible
packet_invalid
packet_too_large
forbidden_content
plan_mode_incompatible
unsupported_async
unsupported_nested_spawn
isolation_unavailable
native_task_unavailable
native_task_failed
result_unsettled
structured_output_invalid
forced_partial
model_identity_mismatch
effort_mismatch
fallback_not_allowed
artifact_stale
candidate_drift
outcome_record_failed
cancelled
internal_error
```

Pre-dispatch failures make zero provider calls. Post-dispatch failures never become successful
receipts and never satisfy a stage barrier. Re-running an identical packet after a deterministic
sizing/schema/context failure is forbidden; the Tech Lead must repartition or change the contract.

When the managed boundary itself is unavailable, the normal fallback is for the Tech Lead to work
inline. That path creates no self-packet. A missing Reviewer where review is mandatory does not
fall back to self-review; it remains an unmet gate under Topic 09.

## 16. Alternative OMP Agent Facilities

The selected guarantee covers every **template-managed** agent dispatch and Topic 04 session
handoff. OMP also contains unrelated native facilities such as Vibe, agent-backed eval, and
internal maintenance agents that do not all converge on one public universal spawn hook.

The managed profile does not use those facilities to satisfy a task work unit or acceptance gate.
Any artifact/result produced outside a managed packet lacks a valid receipt and cannot become
acceptance evidence through existence alone.

`OPEN-T06-RUNTIME-01` records the stronger upstream question: add or expose one universal
`before_agent_spawn`/`after_agent_result` seam if the product later requires adversarial enforcement
over every OMP-internal agent path. That stronger claim is not required for the approved local,
single-operator workflow and does not block Topic 06.

## 17. Portability

The portable core:

- uses standard JSON-compatible values and dependency-free JavaScript;
- has no OMP, Claude, OmniRoute, UI, or filesystem-authority semantics;
- exposes pure compose/lint/normalize functions plus a one-request/one-result CLI;
- keeps role policy in explicit data, not runtime-specific prompts; and
- returns safe, closed error envelopes.

The OMP adapter owns `ctx.invokeTool`, native result-detail interpretation, trusted extension load,
plan-mode journal observation, and OMP discovery. A future Claude adapter owns Claude hook/session
semantics and invokes the same core. Neither adapter owns task acceptance.

## 18. Validation Strategy

### L0 — static contract

- schema objects are closed and canonical serialization is deterministic;
- every overlay accepts valid minimal input and rejects unknown/missing/duplicate fields;
- agent-authored outputs contain no runtime IDs/hashes/model metadata;
- forbidden names/values, transcript/history, raw diagnostics, absolute state paths, and oversized
  structures are rejected;
- no fixed pre-Topic-03 roster is reintroduced; and
- old inert task/result YAMLs cannot be discovered as active runtime contracts.

### L1 — state projection

- only active owned tasks and existing immutable work units project;
- AC IDs, worktree, candidate, revision, and lease bindings come from authority;
- projection contains no private authority records or unrelated tasks;
- projection is deterministic and hash-stable;
- handoff projection is emitted in the same transaction as `begin-handoff`; and
- unavailable/corrupt/stale authority refuses.

### L2 — wrapper contract

- the registered `task` schema is the narrow managed schema;
- invalid single/batch requests invoke native `task` zero times;
- valid single/batch requests delegate exactly once with canonical packet strings;
- native result details are preserved for validation but raw diagnostics are not exposed;
- every named invalid-result class returns an error receipt; and
- successful results record one provisional outcome under current CAS.

### L3 — installed runtime

- missing/invalid trusted wrapper aborts OMP startup;
- the loaded wrapper shadows native `task` and delegates to the captured native implementation;
- the wrapper remains active across normal and plan-mode transitions;
- mutating Worker is rejected before native dispatch in plan mode;
- read-only role behavior matches the pinned restricted-child semantics;
- required commands, skills, rules, agents, and custom tools remain available under the managed
  launcher; and
- direct unmanaged OMP is clearly reported as outside the managed guarantee.

### L4 — adversarial and lifecycle

- malicious strings cannot add fields, inject commands, escape paths, or leak secrets;
- batch preflight is all-or-none;
- schema override, fallback, auth fallback, effort cap, forced partial, cancellation, output
  truncation, missing artifacts, candidate drift, and CAS conflict all fail closed;
- the managed overlay is last/effective and `requests >= 300` is never accepted as complete;
- Reviewer construction excludes Worker claim even when a prior outcome contains prose;
- successful sibling results cannot make a failed batch barrier pass;
- handoff rejects changed candidate/evidence/workspace bindings; and
- no packet or receipt can accept the parent task.

## 19. Impact Map

### Authority and decision surfaces

- `spec/key/04-decision-log.md` — add the approved Topic 06 decision and supersede the
  documentation-only packet assumption where applicable.
- `spec/key/01-dna.md` and relevant synthesis/coverage surfaces — project the selected boundary
  semantics without restoring a fixed roster.

### Direct specifications

- `spec/03-agent-topology.md`
- `spec/05-context-and-token-model.md`
- `spec/06-structured-output.md`
- `spec/08-isolation-and-concurrency.md`
- `spec/09-model-routing.md`
- `spec/10-verification-and-review.md`
- `spec/12-installation-and-rollback.md`
- `spec/13-validation-and-evaluation.md`
- `spec/15-security-and-failure-recovery.md`
- `spec/README.md`

### Phase projections

- `spec/phases/phase-01-runtime-correctness.md`
- `spec/phases/phase-02-core-orchestration.md`
- `spec/phases/phase-03-context-efficiency.md`
- `spec/phases/phase-04-quality-system.md`
- `spec/phases/phase-05-installation-hardening.md`
- `spec/phases/phase-06-evaluation.md`
- `spec/phases/phase-07-stabilization.md`

No historical Phase 00 evidence is rewritten. New runtime evidence is additive.

### Runtime/template

- portable contract core, CLI, and closed managed runtime overlay under
  `template/.omp/contracts/`;
- trusted same-name wrapper under `template/.omp/extensions/`;
- safe projection support under `template/.omp/state/`;
- selected agent output contracts under `template/.omp/agents/`;
- managed launcher/component mapping and rollback metadata; and
- retirement or explicit historical fencing of stale inert schemas under `template/.omp/schemas/`.

### Tests, validation, and documentation

- deterministic JavaScript contract/wrapper tests;
- PowerShell state projection and installer tests;
- token-free OMP RPC/print-mode attachment probes;
- Topic 06 focused validator and full validator integration;
- architecture, workflow, task-state, security, installation, customization, rollback, and token
  documentation;
- current-product Topic 06 evidence manifest; and
- Topic 06 changelog/audit packet following the established local convention.

## 20. Migration and Rollback

Migration replaces prose-only/free-form selected agent dispatch with the managed schema. Existing
role prompts keep their semantic responsibilities but stop requiring the model to echo runtime
bindings. Old packet/result YAML files are either removed from active template installation or
moved behind an explicit historical/non-authority fence; two active contract systems cannot
coexist.

Installer application remains transactional. Rollback restores the prior `.omp` tree while
retaining Topic 04 operational state. A rollback that removes the trusted wrapper also removes the
managed launcher/profile; it must not leave a launcher that silently starts bare OMP while claiming
managed enforcement.

## 21. Acceptance Criteria

- **AC-1:** A packet exists only for a managed agent dispatch or session handoff; inline Tech Lead
  work creates none.
- **AC-2:** Topic 04 task/work-unit state is the only durable authority; packets and receipts are
  bounded projections and provisional observations.
- **AC-3:** Base and role overlays are closed canonical JSON and reuse Topic 04 `AC-*` IDs.
- **AC-4:** Packets/results exclude transcripts, terminal history, repository dumps, hidden
  reasoning, secrets, raw diagnostics, and redundant runtime-owned dispatch metadata.
- **AC-5:** Reviewer receives the frozen artifact/diff plus accepted contract and concern profile,
  never the Worker's claim.
- **AC-6:** Invalid single/batch packets make zero native task/provider calls.
- **AC-7:** The OMP wrapper delegates to the native built-in and rejects every invalid,
  unsettled, partial, stale, or routing-incompatible result.
- **AC-8:** Cheap Scout permits only the approved availability fallback; Worker and Reviewer obey
  their exact selected identity/effort contracts.
- **AC-9:** Managed v1 rejects asynchronous and nested dispatch; plan-mode mutating Worker is
  rejected before native dispatch.
- **AC-10:** A successful receipt records only a provisional work-unit outcome and cannot accept
  the parent task.
- **AC-11:** Handoff projection and durable handoff creation are atomic with respect to the Topic 04
  task lock and remain subject to CAS/candidate/evidence validation.
- **AC-12:** The same portable contract core can be invoked by OMP and a future Claude adapter
  without duplicating schemas or lifecycle logic.
- **AC-13:** The supported trusted launcher fails startup when the wrapper is missing/invalid and
  clearly distinguishes managed from direct unmanaged OMP.
- **AC-14:** Deterministic, installed-runtime, adversarial, lifecycle, installer, and rollback tests
  pass without calling a model/provider.

## 22. Rejected Alternatives

### Composer/linter without runtime wrapper

Rejected because it cannot guarantee that the composed packet is the value dispatched or inspect
the native result metadata required for acceptance.

### Only `tool_call` and `tool_result` listeners

Rejected because the generic result-listener path is fail-open on handler timeout/error in the
pinned OMP source. A pre-call block does not repair an unvalidated post-result acceptance path.

### Fork or copy OMP's task executor

Rejected because it duplicates routing, isolation, batching, cancellation, async, structured
output, and upgrade behavior. The same-name delegation seam supplies the needed control at much
lower maintenance cost.

### Encode packets in Markdown or free-form prose

Rejected because unknown fields, duplicate semantics, stable canonical hashing, and deterministic
cross-runtime linting become ambiguous.

### Put packet state in Git

Rejected. Operational state and receipts are local. Git remains candidate/source history only when
the user explicitly uses it; Topic 06 does not require commits for continuity.

## 23. Final Approved Summary

- Build one dependency-free portable packet/result contract core.
- Project one immutable Topic 04 work unit; do not parse private state in adapters.
- Re-register OMP `task`, validate before dispatch, delegate to native `task`, and validate after
  settlement.
- Load the wrapper through an exact trusted managed entrypoint; direct bare OMP is unmanaged.
- Use canonical JSON with closed base and role overlays.
- Keep runtime identities/hashes in tool metadata, not model-authored output.
- Keep Reviewer independent from Worker claim.
- Reject managed async/nested dispatch and incompatible plan-mode mutation.
- Record only provisional outcomes; Topic 04 remains the sole acceptance authority.
- Leave OmniRoute untouched and record its actual upstream only when independently observed.
- Carry `OPEN-T06-RUNTIME-01` as a nonblocking upstream enhancement for a universal OMP spawn seam.
