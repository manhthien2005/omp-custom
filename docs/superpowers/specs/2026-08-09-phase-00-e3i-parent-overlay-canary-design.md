# Phase 00 E3-I Parent-Overlay Canary Evidence Design

> **P00-CX-028 correction notice (2026-08-09):** The terminal outcome statements retained
> below are historical. They are superseded by
> `2026-08-09-phase-00-e3il-terminal-precedence-correction-design.md`: Attempts 4 and 5 are
> `INVALID_RUN`, not `BLOCKED_ENVIRONMENT`, and current E3-I authority is `READY` with no
> selected attempt. No provider retry or parallel execution is authorized.

**Status:** `READY` after P00-CX-028 additive correction; Attempts 1-5 are preserved as
`INVALID_RUN`; no selected attempt, no Session B, no I1-I4 materialization, and no parallel
authority
**Scope:** Phase 00 experiment E3-I only
**Normative authority:** `spec/phases/phase-00-foundation.md:379-443`
**Parent design:** `docs/superpowers/specs/2026-08-08-phase-00-execution-evidence-design.md`
**Repository HEAD:** `62fecf277dc9d5e47d06319387eac747462214c1`
**Pinned OMP:** `17.2.10` at `3a8591a8af5b6d200088d12ca75a5517cb064fa8`
**Manifest state at design time:** `E3-I: READY`; `parallel_mode: DISABLED`
**Peer-review state:** Codex design judgment only; Opus review remains pending quota

**Runtime adjudication update:** Attempt 3 proved that the corrected child profile boundary,
`[read, yield, hub]` surface, exact terminal-yield protocol, parent sequence, runtime override,
branch discrimination, and mutation boundaries can all hold in one attempt. It remains
non-selectable because `e3i-project-2` recovered from `server_is_overloaded` through an
internal auto-retry. E3-I requires one clean retry-free sample; no observation from Attempt 3
may be combined with another attempt, and Session B remains ineligible.

**Terminal runtime update:** After renewed user authorization and a fresh two-shell/model
gateway gate, Attempt 4 again produced the exact parent sequence, corrected child surfaces,
terminal yields, branch split, runtime override, cost rows, and six clean mutation boundaries.
After the ninth tool call, the parent terminated on `server_is_overloaded` without a recovered
completion. Provider-failure precedence makes the terminal E3-I outcome
`BLOCKED_ENVIRONMENT / P00-RUNTIME-PROVIDER-OVERLOAD`. The otherwise conforming partial
observations are non-selectable and cannot be combined across attempts. The retained terminal
artifacts are `raw/session-a.attempt-004.adjudication.json` and `conclusion.yml`; I1-I4 do not
exist because Session B was never eligible.

**Joint Attempt 5 update:** The separately authorized E3-I/E3-L joint attempt launched one
Session A under the same pinned 17.2.10 identity. Replaying the E3-I classifier over 735 parent
events and six canary histories independently returned
`BLOCKED_ENVIRONMENT / P00-RUNTIME-PROVIDER-OVERLOAD`. Canary `e3i-runtime-3` contains one
recovered nested auto-retry; that fact is retained, but the parent terminal capacity failure
has precedence and still prevents selection and Session B. E3-I did not consume an E3-L
conclusion. The current terminal artifacts are
`raw/session-a.attempt-005.adjudication.json` and `conclusion.yml`; Attempt 4 remains immutable
history and I1-I4 remain absent.

## 1. Decision

Execute E3-I as a two-parent-session, three-runtime-state characterization experiment.
The experiment will deliberately make a subprocess configuration read disagree with the
live parent session twice: once through a synchronous in-memory runtime override and once
through a parent launch-time CLI overlay. A cooperative, read-only canary will then expose
which `task.isolation.apply` branch the parent dispatch actually used through the task
summary returned to the parent.

The selected shape is:

1. **Parent session A:** project `apply:false`, three control canaries, one custom-tool
   runtime override to `true`, then three post-override canaries.
2. **Parent session B:** the same project `apply:false`, but launch the parent with a CLI
   overlay of `apply:true`, then run three canaries.

This yields nine sequential canary samples across three states while consuming only two
provider-backed parent sessions. It preserves the required within-session transition for
the hardest variant and keeps the CLI-overlay observation independent.

Two alternatives were rejected:

1. Three independent parent sessions would make state separation simple, but would add
   provider cost and setup variance without improving the decisive within-session proof.
2. An SDK or direct in-process harness would provide precise control, but would bypass the
   model-facing parent task call and returned-summary path E3-I is required to characterize.

No E3-I outcome authorizes parallel dispatch. E3-I remains behavioral evidence only.
E3-L owns live mechanical observation; E3-M remains the only guarded-dispatch gate.

## 2. Required Normative Correction

The current E3-I text at `spec/phases/phase-00-foundation.md:424-427` says that changing
the setting through `/settings` calls `Settings.set()` into in-memory `#overrides` without
file changes. That statement is contradicted by the pinned implementation:

- `config/settings.ts:498-505`: `Settings.set()` updates the global settings object,
  marks settings modified, rebuilds the effective settings, and queues persistence on the
  normal writable path.
- `config/settings.ts:518-526`: `Settings.override()` updates `#overrides`, rebuilds the
  effective settings, and does not queue persistence.
- `config/settings.ts:2143-2147`: the effective merge order places runtime overrides after
  global, project, and CLI-config-overlay layers.
- `modes/components/settings-selector.ts:1272-1282` and its sibling update paths call
  `settings.set`, so `/settings` is not the runtime-only override primitive described by
  the current contract.

The initial implementation selected the nominal context surface below because the pinned
type and custom-tool documentation advertised it:

```ts
ctx.settings.override("task.isolation.apply", true)
```

Attempt 1 proved that selection was not executable. `custom-tools/types.ts:85-105` declares
`settings?: Settings`, but project custom tools are converted through
`sdk.ts:885-894,938-955`; `createCustomToolContext()` omits `settings`. The tool therefore
failed with `P00_E3I_SETTINGS_UNAVAILABLE`. This is a pinned runtime type/bridge mismatch,
not an observed settings contradiction.

For the exact default main-CLI print host used by E3-I, the corrected primitive is:

```ts
pi.pi.settings.override("task.isolation.apply", true)
```

`custom-tools/loader.ts:132-154` injects the package namespace as `pi`; `index.ts:17`
exports the `settings` proxy; `Settings.init()` binds that proxy
(`config/settings.ts:404-416,2371-2389`); and `main.ts:1282-1283,1545` passes the same
initialized instance into the session. The tool reads immediately before and after, calls
no `Settings.set`, flush, or save method, and remains parent-cwd gated. Runtime divergence
must still prove that this host-scoped proxy mutation affected the parent dispatch. No
source chain alone earns PASS.

This correction is source reconciliation for E3-I, not a general endorsement of the
global proxy. It says nothing about ACP cloned settings or injected SDK settings, does not
replace E3-L, and does not satisfy E3-M's separate atomic-timing requirement.

## 3. Source Facts and Epistemic Boundary

The design relies on the following pinned-source facts:

- `task/structured-subagent.ts:315-317` reads
  `request.session.settings.get("task.isolation.apply")` for the live dispatch policy.
- `task/structured-subagent.ts:385` leaves an ordinary task unrestricted; the experiment
  must therefore impose and observe its own behavioral safety contract.
- `task/executor.ts:2675-2692` auto-adds `hub` to a read-capable ordinary agent;
  `executor.ts:3019-3024` also creates every TaskTool child with `requireYieldTool:true`;
  and `tools/index.ts:641-643` plus `sdk.ts:2964-2977` force-include `yield`. A canary
  declared with `[read]` therefore has controlled effective surface `[read, yield, hub]`.
- `task/structured-subagent.ts:597-632` selects the applied-change summary when apply is
  true and the capture-only `Isolation:` summaries when apply is false.
- `task/isolation-runner.ts:281-385` produces the no-change applied branch, including the
  exact summary `No changes to apply.` when the cooperative canary creates no diff.
- `docs/custom-tools.md:43-60` defines project custom-tool discovery under `.omp/tools`.
- `extensibility/custom-tools/types.ts:85-105` nominally declares optional
  `CustomToolContext.settings`, but `sdk.ts:885-894,938-955` omits it from the context
  actually passed to a project custom tool. Attempt 1 corroborates the executable bridge.
- `extensibility/custom-tools/loader.ts:132-154`, `index.ts:17`,
  `config/settings.ts:404-416,2371-2389`, and `main.ts:1282-1283,1545` establish the
  corrected global-proxy chain only for the default main-CLI host used here.
- `task/structured-subagent.ts:439-440` forwards the parent's preloaded custom-tool paths
  into ordinary subagents, and `sdk.ts:1980-1990` reloads those factories for the child
  session. `sdk.ts:3025-3036` then force-includes registered custom tools regardless of a
  normal tool-name filter. An ungated essential override tool would therefore contaminate
  the canary surface it is intended to measure.
- `task/executor.ts:2910-2916` creates an isolated subagent session with the worktree as
  its effective cwd, which gives the fixture a source-backed parent/child scope boundary.

These facts establish what the experiment is expected to observe, but they do not
substitute for runtime evidence. Conversely, runtime summary text demonstrates only the
behavioral branch reached by these samples. It does not prove an atomic gate, make the
canary a sandbox, or prove that an unobserved hub call is impossible.

The following statements must remain distinct in every artifact:

| Claim | Authority |
| --- | --- |
| The declared canary surface is `[read]` | Fixture fact |
| The controlled effective canary surface is `[read, yield, hub]` | Pinned-source fact plus isolated runtime corroboration |
| Whether the canary made exactly one terminal `yield` and no forbidden call | Runtime transcript |
| Which apply branch produced the returned summary | Runtime behavior plus source mapping |
| Whether the default main-CLI parent setting changed | Host-scoped proxy before/after plus changed dispatch behavior |
| Whether the child `omp config get` observed the parent overlay/override | Subprocess observation |
| Whether parallel work is safe | Not decided by E3-I |

## 4. Architecture

The slice has six isolated units:

1. **Disposable fixture** contains project configuration, a cooperative canary agent, the
   runtime-override custom tool, prompts, and the CLI overlay file. It contains no secret
   and no machine-specific absolute path.
2. **Parent-session prompts** constrain the model to one exact sequence of tool calls.
   A deviation is invalid evidence; it is never silently normalized into a PASS.
3. **Runner** relocates OMP's agent directory and the process-local user-profile discovery
   root, materializes a fresh disposable repository, launches the two parent sessions
   sequentially against pinned OMP behavior, and captures raw JSONL/stdout/stderr/run
   metadata.
4. **Evidence helper** pairs tool calls with results, identifies parent versus canary
   events, classifies summary branches, validates exact sequencing, and checks cost and
   mutation evidence.
5. **Snapshot guard** records parent content, Git state, fixture settings, and live-home
   metadata before and after each selected attempt.
6. **Case adjudicators** produce I1 through I4 and a conclusion without granting authority
   beyond E3-I.

Existing Phase 00 sanitization and strict JSONL behavior should be reused through the
shared evidence libraries where their contracts match. E3-I owns its orchestration,
sequence validator, summary classifier, and snapshot decisions. The closed E3-A/E3-H
runner will not be refactored merely to share process-launch code; unnecessary edits to a
closed slice would enlarge the review surface.

## 5. Disposable Fixture Contract

The fixture will define:

```yaml
project:
  task:
    isolation:
      mode: rcopy
      apply: false

cli_overlay:
  task:
    isolation:
      apply: true
```

The canary agent contract is:

```yaml
blocking: true
declared_tools: [read]
prompt_contract:
  - make no changes
  - call exactly one terminal yield with the fixed acknowledgement object
  - call no other tool, including read, hub, or MCP tools
```

The `[read]` declaration is deliberate. It keeps direct write/edit/bash/lsp tools out of
the declared surface while preserving the source-proven executor widening to
`[read, yield, hub]`. `yield` is mandatory TaskTool completion transport, not an optional
capability: the canary must call it exactly once with
`{"type":"result","result":{"data":{"acknowledgement":"PHASE00_E3I_CANARY_OK"}}}`.
The prompt is a behavioral guard only. The design does not label it an OS sandbox or a
mechanical non-mutation boundary.

The project custom-tool module will be discovered from `.omp/tools`, but its factory must
return no tools unless `pi.cwd` equals the normalized disposable parent root supplied in
the non-secret `OMP_PHASE00_E3I_PARENT_CWD` process variable. Isolated canaries use their
worktree as `pi.cwd`, so their factory invocation must return `[]`. Only the parent factory
invocation returns the narrowly-scoped essential tool. The tool's `execute` path repeats
the same cwd equality check and fails closed if the boundary changed between factory load
and invocation.

This parent-scope gate is required, not optional. Merely declaring the custom tool
`loadMode: essential` would make it available to the canaries because custom-tool paths
are forwarded and registered tools are force-included. Merely making it discoverable
would hide its top-level presentation without proving absence from the child's enabled
registry. The runner also sets process-local `USERPROFILE` to a disposable empty directory
so external user MCP discovery cannot contaminate the controlled surface. The child
`session_init.tools` record must therefore equal `[read, yield, hub]` and must not contain
the override tool name or any ambient MCP/custom tool.

The returned parent tool exposes one narrowly-scoped operation. Its successful result
must attest:

```yaml
setting: task.isolation.apply
before: false
operation: pi.pi.settings.override
requested: true
after: true
called_set: false
called_flush_or_save: false
```

The exported proxy is the reviewed host-scoped primitive, not a silent fallback. If it is
uninitialized or cannot perform the exact operation, the tool must error and the attempt is
`INVALID_RUN`; the runner may not reinterpret that as a semantic settings contradiction.
The tool must not expose a general setting name or arbitrary value input. That restriction
keeps the fixture from becoming an unrelated mutation mechanism.

The fixture's project config and custom-tool source are hashed before and after the
runtime override. Equality is mandatory evidence that the in-memory operation did not
persist into the disposable configuration.

## 6. Exact Parent-Session Protocol

### 6.1 Session A — project control followed by runtime override

Launch the parent from the disposable repository with project `apply:false` and no CLI
overlay. The parent model must perform exactly this ordered sequence:

```text
parent bash diagnostic
task canary A1
task canary A2
task canary A3
runtime-override custom tool
parent bash diagnostic
task canary A4
task canary A5
task canary A6
```

Both parent bash diagnostics run a child `omp config get task.isolation.apply --json`
from the disposable project root. Both child processes are expected to report project
value `false`. The second child must remain false even though the custom tool has attested
that the live parent changed from false to true.

All six task calls are individual, blocking, sequential calls to the same canary agent.
Batching, concurrent calls, retries, omitted calls, or extra calls invalidate the attempt.

### 6.2 Session B — CLI-overlay divergence

Launch a fresh parent from a fresh copy of the same project with a CLI configuration
overlay setting `apply:true`. The parent model must perform exactly:

```text
parent bash diagnostic
task canary B1
task canary B2
task canary B3
```

The child diagnostic is expected to report project value `false`, because a new child OMP
process does not inherit the parent's launch-only overlay. The three parent task calls are
expected to behave as `apply:true` because dispatch reads the live parent session.

Session B must not load or invoke the runtime-override tool. This prevents the CLI result
from being conflated with a second mutation mechanism.

## 7. Case Contracts and Oracles

### I1 — Project configuration control

I1 consumes Session A's first three task results. PASS requires:

1. The first child diagnostic strictly parses to `task.isolation.apply=false`.
2. Exactly three control task calls and exactly three paired task results exist.
3. Every normalized task result begins with `Isolation:`.
4. Every control canary makes exactly one conforming terminal `yield` and no other call.
5. The three calls complete without retry, timeout, or parent/nested-session recovery.

The repeated samples characterize stability; they do not create statistical proof.

### I2 — In-session runtime-override divergence

I2 consumes the custom-tool result, Session A's second child diagnostic, and the final
three task results. PASS requires:

1. The custom tool attests `false -> true` through exactly
   `pi.pi.settings.override("task.isolation.apply", true)` in the default main-CLI host.
2. No `Settings.set`, flush, or save path is called.
3. The disposable project config and custom-tool source hashes are unchanged.
4. The post-override child diagnostic strictly parses to `false`.
5. Exactly three post-override task results equal the normalized no-change branch
   `No changes to apply.`.
6. Every post-override canary makes exactly one conforming terminal `yield` and no other
   call.

The decisive finding is the simultaneous divergence: child process `false`, live parent
behavior `true`.

### I3 — Parent CLI-overlay divergence

I3 consumes Session B. PASS requires:

1. The child diagnostic strictly parses to project value `false`.
2. Exactly three task calls and paired results exist.
3. Every normalized task result equals `No changes to apply.`.
4. No runtime-override tool call exists in Session B.
5. Every canary makes exactly one conforming terminal `yield` and no other call.

Again, the decisive finding is child process `false` versus live parent behavior `true`.

### I4 — Safety, reliability, and cost characterization

I4 evaluates all nine canary samples and both selected parent attempts. PASS requires:

1. Nine of nine canaries complete in the prescribed order.
2. Every canary has a recorded wall duration and token count from the observed result.
3. The six expected apply-true/apply-false summary classifications are stable within each
   three-sample state.
4. Every canary transcript contains exactly one conforming terminal `yield`, with zero
   `read`, `hub`, MCP, or other forbidden calls.
5. Every canary `session_init.tools` record equals `[read, yield, hub]`; the parent-only
   override tool and ambient MCP/custom tools are absent from every child registry.
6. The disposable parent repository content snapshot, excluding `.git`, is unchanged.
7. Parent Git HEAD and porcelain status are unchanged.
8. The disposable agent/project configuration hashes are unchanged by the runtime
   override.
9. Live OMP-home metadata is unchanged.
10. Cleanup removes only verified disposable roots and leaves no selected temp root behind.

I4 must report the source-proven controlled effective surface `[read, yield, hub]`
separately from the runtime observation of one exact terminal `yield` and zero forbidden
calls. The latter is a finite behavioral sample, not proof that hub cannot be exercised.

## 8. Summary Classifier

The classifier operates only on the paired task-tool result, never on assistant prose.
After normalizing transport wrappers and line endings:

```yaml
starts_with_Isolation_colon:
  observed_branch: apply_false_capture_only
equals_No_changes_to_apply_period:
  observed_branch: apply_true_no_diff
anything_else:
  observed_branch: contradiction
```

The classifier must not accept semantic paraphrases such as "nothing changed". An
unexpected branch, an error result, a missing result, or an ambiguous nested payload is a
complete-run contradiction or invalid evidence according to the classification rules
below. It cannot be repaired by the parent model's explanation.

## 9. Raw Capture, Pairing, and Provenance

Each attempt retains sanitized raw stdout JSONL, stderr, exit/timing metadata, executable
identity, working directory token, launch arguments with secrets omitted, fixture hashes,
parent-repository snapshots, live-home metadata snapshots, and selected/non-selected
status.

The JSONL analyzer must:

1. Strictly parse every non-empty object.
2. Pair each parent tool call with exactly one result by the observed call identifier.
3. Distinguish parent calls from nested canary events using the actual event ancestry and
   call identity, not textual inference.
4. Enforce the exact sequence for Session A and Session B.
5. Reject retries, duplicate results, unpaired results, extra calls, missing calls, and
   out-of-order calls.
6. Extract summaries only from paired `task` results.
7. Require exactly one conforming terminal `yield`; count any other nested canary call,
   especially `hub`, as a safety contradiction.
8. Record duration and token fields for all nine canaries without inventing a value if the
   provider omits it.

An attempt with malformed or incomplete provenance is not eligible for PASS even when its
visible summaries appear correct.

## 10. Outcome Classification and Error Handling

The selected attempt receives exactly one top-level classification:

| Classification | Meaning |
| --- | --- |
| `PASS` | I1-I4 all satisfy every required oracle |
| `FAIL` | A complete, attributable run contradicts a semantic or safety requirement |
| `INVALID_RUN` | The run cannot support adjudication because execution or evidence shape deviated |
| `BLOCKED_ENVIRONMENT` | The required provider run could not complete for an attributable external environment reason |

`BLOCKED_ENVIRONMENT` is limited to evidence such as authentication failure, exhausted
quota, provider overload, or requested-model unavailability. It is not a generic bucket
for model noncompliance or a failed assertion.

`INVALID_RUN` includes wrong tool order, missing or extra parent calls, any recovered
provider error inside a nested canary, a missing/malformed terminal yield, malformed JSONL,
unpaired events, missing provenance, timeout without a complete semantic result, or cleanup
failure that prevents trustworthy boundary comparison.

`FAIL` includes wrong summary branch in a complete run, absent parent/child divergence,
setter persistence, use of `Settings.set` or a flush path, any canary call other than the
one exact terminal `yield`, parent content/Git mutation, or live-home mutation attributable
to the selected experiment.

All attempts are retained and hash-ledgered. A rerun may be selected only after the prior
attempt is classified and preserved. No failed or invalid history may be overwritten, and
no post-hoc extraction may silently combine observations from different attempts.

## 11. Safety Boundary

The experiment uses only a disposable repository, relocated disposable OMP agent
directory, and an empty process-local user-profile discovery root. Before each session,
the runner records:

- a content hash over the disposable parent excluding `.git`;
- Git HEAD and porcelain status;
- individual hashes for project config, overlay, agent, custom tool, and prompts;
- live OMP-home file metadata using the established Phase 00 boundary checker.

After the session it records and compares the same surfaces before cleanup. Cleanup must
resolve and verify each target as a descendant of its designated OS-temp root before
removing it. The runner never deletes a repository root, live home, unresolved variable,
or glob-expanded path.

The experiment cannot promise that an unrestricted model process is an OS sandbox or that
no transient side effect existed and disappeared between snapshots. The defensible claim
is narrower: pinned source proves the declared/controlled effective surface, selected
transcripts show one exact terminal `yield` and zero forbidden calls per canary, and
before/after snapshots show no persistent mutation on the measured boundaries. Any
broader claim is prohibited.

Provider credentials may be consumed from the already configured process environment,
but their values must never be printed, placed in launch metadata, copied to fixtures, or
persisted in raw or interpreted artifacts.

`OMP_PHASE00_E3I_PARENT_CWD` is non-secret fixture state. Raw launch metadata records only
the variable name and `<DISPOSABLE_PROJECT>` token, never the actual temporary path. The
runner removes the variable with the disposable process; it does not mutate the caller's
process environment.

## 12. Planned Artifact Layout

Implementation will produce the following review surface:

```text
docs/evidence/phase-00/E3-I/
  fixture/
    .omp/config.yml
    .omp/agents/phase00-e3i-canary.md
    .omp/tools/phase00-e3i-runtime-override.ts
    overlay.yml
    prompts/session-a.md
    prompts/session-b.md
  raw/
    ... preserved selected and non-selected attempt records ...
  I1.yml
  I2.yml
  I3.yml
  I4.yml
  conclusion.yml
scripts/lib/phase00-e3i-evidence.ps1
scripts/run-phase00-e3i.ps1
scripts/tests/phase00-e3i.Tests.ps1
```

The interpreted YAML documents will contain expected/observed values, raw artifact
references and SHA-256 hashes, source-versus-runtime authority labels, outcome reason
codes, and non-authority disclosures. `conclusion.yml` will aggregate the cases without
copying evidence that cannot be traced to a raw record.

## 13. Test-First Strategy

Implementation must begin with failing tests for the evidence decisions before fixture or
runner behavior is added. Required test groups are:

1. Strict child config JSON parsing, including unknown keys, wrong types, extra shapes,
   non-zero exits, and malformed content.
2. Exact Session A and Session B sequence acceptance.
3. Call/result pairing and rejection of missing, duplicate, extra, retried, or out-of-order
   events.
4. Summary classification for `Isolation:`, `No changes to apply.`, and contradictory
   shapes.
5. Host-scoped proxy attestation of `false -> true`, override-only use, no
   set/flush/save, and no persisted fixture change.
6. Separation of parent tool calls from nested canary calls, requiring one exact terminal
   `yield` and rejecting every other canary call.
7. Parent-scope factory gating: parent cwd returns exactly one essential override tool;
   isolated child cwd returns `[]`; every child `session_init.tools` equals
   `[read, yield, hub]` after user-profile discovery isolation.
8. Duration and token presence for all nine samples.
9. Parent content/Git, fixture, live-home, and cleanup invariants.
10. Outcome separation among `FAIL`, `INVALID_RUN`, and `BLOCKED_ENVIRONMENT`.
11. Negative fixtures for leaked override-tool registration, hub use, parent mutation,
    malformed/missing JSONL, bad ordering, and provider-environment errors.

After focused tests pass, the full existing Phase 00 suites and repository validator must
pass under both PowerShell 7 and Windows PowerShell 5.1. Any shell-specific evidence
meaning is a defect; the runner may not waive one shell.

## 14. Manifest Transition

The only legal E3-I transitions during implementation are:

```text
READY -> RUNNING -> PASS
READY -> RUNNING -> FAIL
READY -> RUNNING -> BLOCKED_ENVIRONMENT
```

The manifest must not retain `RUNNING` after the selected attempt is adjudicated. A PASS
may list only the complete I1-I4/conclusion artifacts. A blocked outcome must preserve the
environment evidence and keep dependencies locked.

No other experiment row is unlocked by E3-I alone. In particular:

- E3-M remains `DEFERRED_PARALLEL_DISABLED` until its own dependencies and evidence exist.
- `parallel_mode` remains `DISABLED` for every E3-I outcome.
- Phase 00 remains `IN_PROGRESS`.
- E3-I does not close E3-B, E3-C, E3-L, or any later phase task.

## 15. Acceptance Criteria

E3-I is eligible for Codex PASS only when all of the following hold:

1. I1, I2, I3, and I4 independently pass.
2. Three of three project-control summaries begin with `Isolation:`.
3. Three of three runtime-override summaries and three of three CLI-overlay summaries
   equal `No changes to apply.` after normalization.
4. Both hazards demonstrate child `false` versus parent behavior `true`.
5. The custom tool proves `pi.pi.settings.override` changed `false -> true` in the selected
   default main-CLI host without set, flush, save, or fixture persistence.
6. Nine of nine canaries complete with exactly one conforming terminal `yield` each and
   zero `read`, `hub`, MCP, or other forbidden calls.
7. Parent-only factory gating is proven by child `session_init.tools` records equal to
   `[read, yield, hub]` with no override, ambient MCP, or other custom tool in any canary
   session.
8. Parent content/Git, fixture hashes, and live-home metadata remain unchanged.
9. The controlled effective `[read, yield, hub]` surface is reported as source-proven and
   runtime-corroborated, never model-attested.
10. Duration and token observations exist for all nine canaries.
11. Raw artifacts, attempt history, selected provenance, interpreted YAML, and hashes are
    complete, sanitized, and internally consistent.
12. Focused and full verification passes in both supported PowerShell versions, and the
    repository validator passes.
13. The English Codex changelog records every normative, evidence, script, test, and
    manifest mutation with exact locations and hashes for later Opus review.

Codex PASS remains provisional peer adjudication. Opus may reopen any case with concrete
counter-evidence; neither agent has unilateral closure authority.

## 16. Non-Goals

This slice does not:

- implement the production isolation preflight;
- implement or prove E3-L's live-settings reader;
- design or implement E3-M's atomic guarded dispatch;
- enable parallel mode or authorize fan-out;
- install or modify live OMP configuration;
- claim OS-level sandboxing or universal canary non-mutation;
- modify product workflow contracts outside the narrow E3-I source correction;
- stage, commit, branch, push, or create a pull request.

## 17. Review Gate

The user approved the design, the parent-cwd factory amendment, implementation, and
continued work after Attempt 1. Attempt 1 exposed two harness defects: the project
custom-tool context bridge omitted `settings`, and the nested PowerShell diagnostic lost
its variables through outer-shell expansion. Both raw failures are preserved. TDD now
requires the host-scoped proxy primitive, a direct `omp config get ... --json` diagnostic,
an explicitly selected/copy-hashed 17.2.10 executable for parent and nested resolution,
and `INVALID_RUN` rather than semantic `FAIL` for harness errors or unattributed concurrent
live-home noise. Any retry remains numbered, non-overwriting, and separately adjudicated.
