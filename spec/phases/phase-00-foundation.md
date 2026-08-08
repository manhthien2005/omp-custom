# Phase 00 — Foundation

> OPUS PROPOSED SPEC v1 | Establish ground truth before changing anything.

**Depends on**: nothing
**Blocks**: phase-01

---

## Objective

Freeze the facts. Record the exact OMP commit the template's runtime claims were
verified against, correct every documentation claim that contradicts verified
behavior, and **remove `policies/` and `schemas/` from `.omp/`**, re-homing their
content to the tier that actually consumes it (KD-001).

No behavior changes in this phase — nothing in `policies/` or `schemas/` was ever
read at runtime, so removing them cannot change behavior. That is the point. This is
the phase that makes later phases falsifiable.

---

## Rationale

Every downstream fix depends on knowing which OMP behaviors are real. The current
repository states things that are not true (schemas enforced, policies loaded,
validation implies correctness). Fixing code before fixing the record means later
work builds on the same false premises.

---

## Tasks

### T-00.1 — Pin the OMP commit

Record in `registry/upstreams.yml` for `oh-my-pi`: `pinned_commit`, `clone_date`,
`tier: runtime-authority`, and the full `watched_paths` list from §14-C.

**Acceptance**: `upstreams.yml` contains a resolvable SHA and ≥13 watched paths, each
mapping to a claim in `02-runtime-semantics.md`.

### T-00.2 — Record the verified-claims ledger

Create the compatibility record from §14-H: `omp_verified_version`,
`omp_verified_commit`, `verified_claims`.

**Acceptance**: every claim in `02-runtime-semantics.md` §A appears with its source
file path.

### T-00.3 — Move policies out of `.omp/`

> **KD-001 correction (2026-08-08).** This task previously read *"add a
> `documentation` header to each `template/.omp/policies/*.yml`"* — the option KD-001
> explicitly **rejects**: *"Placement inside `.omp/` is itself a claim about runtime
> meaning. A header is read by maintainers; the directory path is read by everyone who
> greps the tree."* `spec/README.md:169` already records `REMOVED: .omp/policies/`. The
> header approach also contradicted this phase's own Objective if left in place. The task
> is restated to match the decision.

Delete `template/.omp/policies/` from the installed surface. Re-home its 5 files
(363 lines) by content type:

| File | Destination | Form |
|---|---|---|
| `quality-gates.yml` | inlined matrix in `standard.md` / `orchestrated.md`, reference copy in `docs/policies/` | prose in the consuming command |
| `context-budget.yml` | `docs/` + validator thresholds | reference + enforced numbers |
| `model-routing.yml` | inlined into the dispatching command prose | prose |
| `workflow-sizing.yml` | inlined into the dispatching command prose | prose |
| `escalation.yml` | agent "Must not" sections (per `03-token-quality-model.md`) | per-spawn prose |

Every re-homed file keeps a provenance line naming the YAML it came from, so
`registry/` entries stay traceable.

**Acceptance**: `template/.omp/policies/` does not exist. No agent prompt or command
references `policy:` or a `policies/` path. Each of the 5 contents is locatable at its
named destination. `registry/` `local_components` updated (see T-00.6).

### T-00.4 — Move schemas out of `.omp/`

Same correction as T-00.3, same grounds. Delete `template/.omp/schemas/` (4 files,
218 lines).

Re-home: each result shape becomes the `output:` frontmatter of the agent that produces
it (KD-002), with the YAML retained under `docs/` as the human-authoritative source that
the inline blocks are generated from.

| File | Becomes `output:` on |
|---|---|
| `agent-result.schema.yml` | `implementer.md` |
| `verification-result.schema.yml` | `verifier.md` |
| `review-result.schema.yml` | `diff-reviewer.md` |
| `task-packet.schema.yml` | not an output — it is the dispatch *input*; re-home to `docs/` only |

**CR-28 correction (retained):** the canonical enforcement path is
`agent output: frontmatter → YieldTool validator`. Caller task `outputSchema` is an
explicit per-call **override**, not the default path. No document may state the inverse.

**OQ-A dependency:** which schema dialect `output:` accepts (JTD, JSON Schema, or both)
is unresolved. Write the `output:` blocks only after OQ-A is settled; until then the
YAML under `docs/` is the source of record and the frontmatter is a stub.

**Acceptance**: `template/.omp/schemas/` does not exist. Three worker agents carry
`output:` frontmatter (or a recorded OQ-A block). No file claims caller `outputSchema`
is the primary enforcement path.

### T-00.5 — Correct the documentation claims

Fix, in `docs/**`, `README.md`, and `docs/final-report.md`:

- any statement that schemas or policies are enforced at runtime
- any statement that `validate-template.ps1` passing means the workflow works
- the installer invocation examples that use non-existent parameters (`-TargetDir`)
- the claim that `benchmark.ps1` benchmarks anything

**Acceptance**: no doc statement contradicts `02-runtime-semantics.md`. Installer
examples match the script's real parameters.

### T-00.6 — Fix the agent-result conditional requirement (F-30)

> **Runs after T-00.4.** The defect below was recorded against
> `template/.omp/schemas/agent-result.schema.yml`, which T-00.4 deletes. The *defect*
> is semantic and survives the move; only its address changes. Fixing the YAML in
> place before T-00.4 would waste the work.

The result contract lists `verification_results` as optional while a field rule requires
it for `status: completed`. Make the conditional requirement explicit in **both**
re-homed locations:

| Target | Form |
|---|---|
| `template/.omp/agents/implementer.md` `output:` frontmatter | the enforced shape (KD-002) — **gated on OQ-A**, same as T-00.4 |
| `docs/schemas/agent-result.md` | the human-authoritative source the frontmatter is generated from |

Note this interacts with **SD-2**: `status: completed` with an absent `patchPath` /
`branchName` or an empty diff is not a completion. F-30 is the *schema* half of that
rule; SD-2 is the *acceptance-check* half. Neither alone is sufficient — a schema proves
shape, never provenance (KD-019).

**Acceptance**: the conditional requirement is unambiguous in `docs/`, and either
expressed in `implementer.md`'s `output:` block or recorded as blocked on OQ-A with the
`docs/` copy as the source of record (F-30).

### T-00.7 — Record the resolved decisions

Record DR-1 … DR-7 (§README-10) with their evidence-based resolutions, so later
phases do not relitigate them. Each DR must explicitly separate **runtime_facts**
(source/test-backed — eligible for "verified from source" label) from **design_objectives**
and **normative decisions** (not source-provable; require explicit rationale instead).
See CR-25.

**Acceptance**: each decision has a resolution; runtime facts carry source citations;
normative decisions carry explicit rationale; no source citation used to justify a
purely normative choice.

---

## Experiment Tasks (Phase-Gate Required) — CR-05

These experiments resolve open questions that later phases depend on. **Phase 00
cannot close and dependent phases cannot begin until each experiment has a recorded
artifact.** Record: exact OMP SHA, OS/runtime, provider/gateway version, raw
(sanitized) output, interpretation, and which decision is changed or retained.

**CR-05 resolution:** every experiment below carries an explicit `**Blocks**:` line
naming the downstream tasks and spec sections it gates. Phase-00 does not merely
*list* the open questions — it gates dependent implementation on their recorded
answers. No dependent task may begin against an unresolved experiment.

**Enforcement level (precise).** This gate is **normative, not mechanically validated**.
It is a written contract consumed by humans and coding agents: nothing under `scripts/`
parses experiment status, checks artifact presence, or fails a build when a blocked task
is attempted, and there is no CI workflow in this repository. A reader who chooses to
ignore the gate is not stopped by tooling. Stating this plainly is required by the same
discipline the spec applies elsewhere — documentation requirement ≠ runtime enforcement,
preflight instruction ≠ protected-operation boundary. Optional future hardening: a
machine-readable experiment-status file plus a validator that rejects missing or invalid
required artifacts.

### T-00.E1 — Schema precedence and provider enforcement

Verify `resolveSchema` precedence and provider strict-mode behavior at the pinned SHA.

Test cases:
1. agent `output:` only (no caller `outputSchema`)
2. caller `outputSchema` only (no agent `output:`)
3. both present with intentionally different sentinel schemas — confirm caller wins
4. session-level `outputSchema` only — confirm session is used when neither caller nor agent is set
5. `schemaMode: strict` — confirm provider enforces rather than permissively accepts

**Artifact**: structured-output experiment transcript with binary result per case.

**Blocks**: phase-01 T-01.7 implementation; DR-2 runtime_facts section.

### T-00.E2 — Model-role merge order

Verify how missing/unknown model roles resolve in the OMP main session and for workers. This is the **canonical fallback test matrix** — `spec/09-model-routing.md §F` references these cases.

Test cases:
1. known built-in role with config present — record selected model
2. known custom role with config present — record selected model. **Use a required worker
   role (`@implementer`), not `@tech-lead` (CR-34):** `tech-lead` is an optional alias with
   no mandatory runtime consumer, so testing the required path with it would prove role
   resolution for a role the template does not own. Test `@tech-lead` separately, if at all,
   as the optional-alias case.
3. referenced custom role absent from config — record selected model or error
4. arbitrary `@unknown` pattern (not a built-in, not in config) — record parser/resolver terminal behavior (error vs silent fallback)
5. role resolves to unavailable provider/model — record error or fallback (distinguishes alias-resolution success from downstream provider failure)
6. **user-level** role vs **project-level** role with same name — assert which wins (project beats user?) by defining the role differently at each level
7. role name collision with OMP built-in (e.g., `default`) — custom role wins or OMP built-in wins?
8. main-session model selection path (coordinator) vs worker agent model selection — verify they use the same resolver or document the difference

**Artifact**: model-selection transcript per case; final statement for §09/§14/§15 normalization.

**Blocks**: DR-1 and DR for model routing (§09); §14/§15 consistency.

### T-00.E3 — Isolation backend, capture-first control surface, and artifact lifecycle

**CR-31/CR-32 escalation:** this is no longer a backend smoke test. The capture-first architecture in `08-isolation-and-concurrency.md §E-7/§E-9/§E-10` depends on settings that OMP defaults *against* (`task.isolation.apply` default `true`), and on artifact durability that OMP does not guarantee for nested repositories. T-00.E3 is the experiment that either proves the architecture or forces the documented degradation. It blocks all parallel implementation.

Baseline cases (original scope):
1. standard workflow (single Implementer, `isolated: false`) — confirm parent worktree unchanged after success
2. orchestrated workflow (parallel Implementers, `isolated: true`) — confirm isolation backend engages
3. isolation backend unavailable — record fallback behavior
4. non-git repository — record fallback behavior

#### E3-A — Settings control surface (CR-30) + concrete read mechanism (CR-31)

Assert the effective values are readable at runtime and that no per-item `apply` exists.
The read mechanism is **no longer open** — `docs/settings.md` documents that
`omp config get` reports the merged effective value, and `--json` gives a parseable shape.
Run from the intended project root:

```bash
omp config get task.isolation.mode  --json    # expect value != "none"
omp config get task.isolation.apply --json    # expect value == false
```

Record for each: exit code, the raw JSON, and the parsed `value`. Unknown keys exit
non-zero (`docs/settings.md`), so a non-zero exit is itself a signal the preflight must
treat as "cannot prove" → refuse parallel.

Also confirm that passing `apply: false` inside a task **item** is silently stripped (arktype `"+": "delete"`), not honored — i.e. that the settings layer is the only control point.

**Additionally record the cwd sensitivity (CR-31 §2.5).** OMP settings discovery checks
only `<cwd>/.omp/`, never ancestors (`docs/settings.md`, "A project setting is not taking
effect"). Run the same two commands from a subdirectory (e.g. `packages/foo/`) of a repo
whose `.omp/config.yml` sets `apply: false`, and record whether the effective value
changes. If it does, the preflight MUST also verify the session cwd is the intended
project root, and the refusal message MUST name cwd as the likely cause.

**Records**: the exact command, exit code, and JSON shape `/orchestrated` will parse; the
observed cwd sensitivity. This case is BLOCKING — every downstream preflight claim depends
on it.

#### E3-B — Capture-only root patch durability

```
isolated: true, apply=false
worker edits root repo, exits 0
→ parent working tree unchanged
→ root patch path present in result summary
→ patch file still readable AFTER worktree teardown
```

#### E3-C — Branch mode (if `merge: branch` is selected)

```
branch retained, not merged
Tech Lead can integrate it later by name
```

#### E3-D — Parallel capture

Two near-simultaneous isolated workers:

```
parent unchanged until the Tech Lead begins integration
neither worker's changes visible in parent before integration
```

#### E3-E — Sequential integration ordering (CR-29)

Integrate by **original task-list index**, not completion order:

```
task[0] artifact → task[1] → task[2]
```

Arrange for `task[2]` to finish first; assert integration still runs 0 → 1 → 2.

#### E3-F — Conflict semantics

```
apply task[0] → succeeds
apply task[1] → conflicts
→ integration STOPS (task[2] not attempted)
→ parent retains task[0] only
→ task[1] and task[2] artifacts remain readable on disk
```

#### E3-G — Nested repository (CR-32 — decisive)

```
worker edits root repo AND a nested git repo / submodule
apply=false, exit 0
```

Record exactly:
- does the result summary mention the nested repo at all when the root also changed?
- is any nested patch file materialized under the artifacts dir?
- after teardown, can the parent locate and `git apply` the nested change?

**Expected per source reading (OMP v17.2.10):** no — `persistNestedPatches()` is reachable only from `isolationRecoveryHint()` (failure path), and the `apply=false` summary's `else if` chain reports only `patchPath` when the root also changed. If the experiment confirms this, the CR-32 **Option A1** policy (any nested repo present ⇒ parallel isolated implementation DISABLED for that repository) stands as normative — see `08-isolation-and-concurrency.md §D-1.2`.

**Also record the preflight-vs-runtime agreement.** The orchestrator's nested-repo
enumeration MUST be a superset of what OMP's own capture walks. Run the §D-1.2 preflight
commands and compare against what `captureDeltaPatch()` actually produced `nestedPatches`
entries for. Any repo OMP captured that the preflight missed is a preflight defect — record
it, because the A1 gate is only as good as its enumeration. Cases to include: a tracked
submodule, a plain nested repo, a nested repo under `node_modules` (OMP skips it), and a
nested repo two levels deep.

**Lift path (Option A2, NOT adopted for v0).** Also record, as future-facing evidence only:
whether a `tool_call` extension hook discovered *inside* the isolation worktree can block a
`write`/`edit`/`bash` call targeting a nested path. Source indicates it should be possible —
`runIsolatedSubprocess()` passes `preloadedExtensionPaths: undefined`
(`task/isolation-runner.ts:168`), which triggers full discovery with `cwd` = the isolation
dir, and `ExtensionToolWrapper` blocks on `{ block: true }` and fails closed on a throw
(`extensibility/extensions/wrapper.ts:200-232`). Confirming this would allow narrowing A1
from a repository-wide disable back to a mechanically-enforced scope exclusion. **A negative
or ambiguous result changes nothing** — A1 remains the v0 policy either way.

#### E3-H — Config precedence and preflight refusal (CR-31 — decisive)

Run every case through the concrete preflight command, not by reading files:

```bash
omp config get task.isolation.mode  --json
omp config get task.isolation.apply --json
```

```
global apply=true + project apply=false  → effective false   (project wins)
project config absent, global/default true → effective true
  → /orchestrated preflight MUST refuse the parallel path
  → falls back to sequential non-isolated, and discloses it
CLI overlay (--config) apply=true over project apply=false → effective true
  → preflight MUST refuse (this is why file inspection is insufficient)
```

**Also record the cwd-scoping case (CR-31 §2.5).** `docs/settings.md` states settings
discovery checks only the current working directory's `.omp/`, **not ancestor directories**.
So a correct install at `<repo>/.omp/config.yml` is invisible to a session launched from
`<repo>/packages/foo/`. Launch from a subdirectory and assert:

```
cwd = <repo>/packages/foo
→ omp config get task.isolation.apply --json  reports the DEFAULT (true), not the project value
→ preflight refuses
→ the refusal message names cwd scoping as the likely cause, not just the setting
```

**Also record the tool-availability case.** If `omp config get` cannot be executed at all
from the workflow's bash tool (not on PATH, non-zero exit, unparseable output), the preflight
has no evidence and MUST refuse the parallel path. Record the exact observed failure shape so
the command can distinguish "read succeeded, value is wrong" from "read failed" — they get
the same refusal but different user-facing messages.

#### E3-I — Parent-overlay attestation gap (CR-38/CR-42 — decisive)

The case that proves why a subprocess read is not attestation, AND that the canary must be
non-mutating. Construct the divergence deliberately:

```yaml
project_config:            task.isolation.apply: false     # <repo>/.omp/config.yml
parent_launch:            omp --config /tmp/override.yml   # containing apply: true
child_config_get_expect:  {"value": false}                 # subprocess sees files only
parent_actual_expect:     applyChanges == true             # session.settings governs
canary_expect:            detects apply=true → refuses parallel
canary_parent_tree:       unchanged before and after canary (CR-42 — no mutations)
```

Assert all five rows. The third and fourth **must disagree** — that disagreement is the
finding. If they agree, record it: either the overlay did not take effect as documented, or a
subprocess inherits more context than `docs/settings.md:21` implies, and CR-38's premise needs
revision.

**CR-42/CR-44 canary contract.** The canary is an agent with declared tools `[read]`. Its
**effective tool surface is `[read, hub]`** — `executor.ts:2689-2692` adds `hub` when
`!restrictToolNames`, and ordinary TaskTool paths have `restrictToolNames=false`
(`structured-subagent.ts:385`). The canary is therefore a **behavioral guard, not a mechanical
sandbox**: it MUST NOT directly write files (no write/edit/bash/lsp in declared surface), and
its prompt instructs "make no changes". Under `apply=false`, any files written into the isolated
worktree are never applied to the parent — the parent-tree invariant holds by isolation design.
Under `apply=true` detection, the canary's isolated context is merged; a cooperative canary
model will not use hub. E3-I must record the effective canary tool surface to confirm hub is
present and whether it is exercised.

The discrimination is via merge summary text (SC-01: three apply=false variants all start
"Isolation:"; the "no changes captured" fallback is only reached if `!patchPath && !branchName
&& !nestedPatches`; in patch mode even a zero-diff run sets patchPath):

```text
apply=false → merge-summary begins "Isolation: ..."   (§E-9.2 — semantic class discriminator)
apply=true  → merge-summary is "No changes to apply." (§E-9.2 apply=true, no-change path)
```

Assert that after the canary runs: `parent HEAD == before`, `parent git status == before`,
`no files directly created or modified in parent by the canary itself`. On the apply=true path
the canary must still produce zero direct parent mutations. **Also assert: the effective canary
tool surface contains `hub`** (confirming CR-44 executor auto-widening). If the canary directly
modifies any parent file, that is a violation of §08 §E-9.2's behavioral-guard contract.

Run the same shape a second time with an **in-session** override instead of a CLI overlay
(change the setting via `/settings` mid-session, then dispatch). `Settings.set()` writes the
in-memory `#overrides` layer (`config/settings.ts:524`), so no file changes at all — this is
the harder variant and the one no external read can ever catch.

Also record the canary's own cost and reliability: wall time, tokens, and whether the
summary-discrimination assertion is stable across repeated runs (a flaky gate is worse than
none).

**Records**: whether `omp config get` can be trusted as a gate (expected: no, diagnostic only),
whether the canary reliably discriminates apply=false vs apply=true, whether hub appears in the
effective tool surface (expected: yes), whether hub is exercised by the model (expected: no),
and whether the behavioral non-mutation contract holds in both cases. If hub is exercised,
§08 §E-9.2 must be updated before phase-02.

**E3-I authority: characterization/diagnostic only.** E3-I PASS does NOT authorize parallel
fan-out. The behavioral canary has hub in its effective surface and is a heuristic, not a
mechanical control. The production gate for parallel mode is E3-L (live custom-tool settings
read). E3-I results feed into E3-L context and serve as a regression test after E3-L adopts
the mechanical path.

#### E3-J — Async barrier and ordering (CR-39 — decisive)

Proves the two properties the whole Orchestrated sequence rests on, together:

```yaml
setup:
  async_enabled: true                    # OMP default — do NOT disable
  worker_frontmatter: blocking: true     # all four workers
  batch: three isolated Implementers
  completion_order: [2, 0, 1]            # make tasks[2] finish first
assert:
  task_call_returns_after_all: true      # barrier holds despite async.enabled
  result_order: [0, 1, 2]                # input order, not completion order
  concurrency_preserved: true            # workers overlapped; not serialized
```

The `concurrency_preserved` assertion is the one most worth capturing evidence for, because the
objection to `blocking: true` would be "it serializes the batch." Record start/end timestamps
per worker and show overlap.

**Control case — omit `blocking`:** rerun with the frontmatter key removed from one worker and
record what the parent receives. Expected: a "Spawned … background agent" response and
`results` missing that item, i.e. the barrier failure the fix prevents. This is what makes the
fix falsifiable rather than assumed.

Then the two stage-specific barriers:

```
Verifier sleeps briefly  → parent cannot dispatch Reviewer until the verification result returns
Reviewer sleeps briefly  → final report cannot be produced from workflow state until findings return
```

#### E3-K — `task.batch` disabled (CR-39)

```yaml
task_batch: false
expected:
  model_facing_wire: flat single-spawn form (no tasks[] array)
  orchestrated_parallel_path: refuses or falls back to sequential
```

Record the actual wire shape the model sees, to confirm the fallback trigger is detectable
before dispatch rather than discovered by a schema error mid-run.

**Artifact**: isolation behavior transcript per scenario, including the E3-G nested-repo
determination, the E3-H precedence table, the E3-I attestation disagreement, and the E3-J
timing/ordering record.

**Blocks**: phase-02 T-02.1b (barrier + batch precondition), T-02.2 (isolation preflight, including the CR-32 nested-repo disable and the CR-38 canary), T-02.3b (serial integration order); §08 §C-1/§E-7/§E-9/§E-9.2/§E-10; §12 §C config-ownership policy.

**E3-A, E3-G, E3-H, E3-I, E3-J, and E3-L are BLOCKING for phase-02 parallel implementation.**
E3-J additionally blocks *every* workflow size, not just Orchestrated — Standard's stage arrows
depend on the same barrier. E3-L confirms live-settings read capability (prerequisite for E3-M)
but does NOT itself enable parallel — CR-45 TOCTOU: the preflight read at t0 is a snapshot;
`Settings.override()` (`settings.ts:518-525`) can mutate the value before dispatch.
**E3-M (guarded dispatch) is the gate that enables parallel mode**: without a passing E3-M,
the canary (E3-I) is characterization-only and parallel fan-out remains disabled.

#### E3-L — Live-session settings authority via custom-tool ctx (CR-44 — Branch A gate)

Source-verify and empirically confirm that a project custom tool can read the live parent
session's `task.isolation.apply` — the same value that governs actual `applyChanges`.

**Source pre-verification (v17.2.10 — already confirmed):**

```text
custom-tools/types.ts:99:
    settings?: Settings
    // "Settings instance for the current session. Prefer over the global singleton."

session-tools.ts:1295-1307  getCustomToolContext():
    settings: this.#host.settings    // live parent-session Settings instance

structured-subagent.ts:315-317:
    applyChanges: request.isolation?.apply
        ?? request.session.settings.get("task.isolation.apply")
```

`this.#host.settings` is the **same** `Settings` instance that `structured-subagent.ts`
reads for `applyChanges`. CLI `--config` overlays, in-session `Settings.set()` overrides, and
all config layers are visible.

**Procedure — three cases required:**

```yaml
case_1_project_config:
  setup: task.isolation.apply: false in .omp/config.yml
  preflight_tool: ctx.settings.get("task.isolation.apply")
  expected: false

case_2_cli_overlay:
  setup: project config apply:false; launch with --config /tmp/overlay.yml apply:true
  preflight_tool: ctx.settings.get("task.isolation.apply")
  expected: true   # same overlay that defeats omp-config-get (CR-38)
  compare: omp config get reports false (subprocess miss)

case_3_in_session_override:
  setup: project config apply:false; change via /settings mid-session (Settings.set())
  preflight_tool: ctx.settings.get("task.isolation.apply")
  expected: true   # in-memory override, no file change
  compare: omp config get reports false (subprocess miss)
```

Case 2 and Case 3 are the decisive tests: they are the exact scenarios where `omp config get`
gives a false PASS (CR-38). If `ctx.settings.get(...)` returns the correct value in both cases,
the mechanical authority path is confirmed.

**E3-L PASS consequence:**

```yaml
preflight_mechanism:
  type: custom-tool live-settings read
  call: ctx.settings.get("task.isolation.apply")
  authority: observation (not atomic dispatch guard)
  note: >
    CR-45 TOCTOU: ctx.settings.get() at t0 (preflight) is a snapshot.
    Settings.override() (settings.ts:518-525) mutates the in-memory value
    synchronously — between the preflight read (t0) and actual task dispatch (t3),
    a Settings.set() or external override can change the effective value.
    Observation ≠ atomic enforcement.
behavioral_canary_E3_I:
  role: regression / characterization test only
live_settings_read_verified: true   # ctx.settings.get sees live value including overlays
parallel_mode: DISABLED             # CR-45 TOCTOU: read at t0 ≠ atomic guard at t3
parallel_mode_requires: guarded_dispatch (E3-M or equivalent)
```

**E3-L FAIL consequence:**

```yaml
parallel_mode: DISABLED until alternative mechanical authority found
behavioral_canary: diagnostic/experiment only — never authorizes parallel
required_action: identify alternative (Option A restrictToolNames path or other)
```

**Artifact:** Three-case transcript with `ctx.settings` read values vs `omp config get` values
vs actual `applyChanges` observed; confirmation that the custom tool executes in parent-session
context (not subagent context).

#### E3-M — Guarded dispatch (optional — CR-45 resolution gate)

Design and empirically test an atomic check-and-dispatch mechanism that closes the CR-45 TOCTOU
gap. E3-L proves the live-read capability; E3-M turns it into an enforceable gate.

**Problem:** `ctx.settings.get("task.isolation.apply")` at preflight time (t0) is a snapshot.
`Settings.override()` (`settings.ts:518-525`) is synchronously mutable — a value change
between t0 and the actual task dispatch (t3) is undetectable by any preflight read alone.

**Candidate mechanisms (choose one to test):**

```yaml
path_A_true_interceptor:
  approach: >
    An OMP extension hook that intercepts the task call at the actual dispatch boundary —
    executing synchronously as part of the task processing pipeline, not as a prior
    separate custom-tool call. The hook reads ctx.settings.get("task.isolation.apply")
    at the moment of dispatch and blocks the task before any worker is spawned if the
    value is unsafe.
  requirement: >
    The check must be mechanically coupled to the dispatch. Adjacent tool calls within
    a single model turn are NOT atomically coupled: each tool call is a separate async
    operation on the OMP JS runtime, and Settings.override() can execute between any
    two tool calls regardless of whether they are in the "same model turn". An OMP
    extension `tool_call` hook (extensibility/extensions/wrapper.ts:205-232 — blocks on
    { block: true }, fails closed on throw) can BLOCK a task call, but blocking ability
    alone does NOT satisfy path A. Two independent conditions must hold — live parent
    Settings access (see blocking_source_gap) AND a guard read at the native spawn
    boundary (see boundary_timing_gap). Neither is demonstrated. An earlier revision of
    this field implied Settings access was the only missing condition; that was wrong,
    and the ordinary loop `tool_call` event is in fact emitted pre-scheduling rather than
    at the dispatch boundary.
  pass_requires_ALL:   # F3-02 — identity and timing are SEPARATE conjunctions
    - the same live parent Settings instance (identity)
    - the guard read occurs AT the protected native boundary (timing)
    - no await/interleavable mutation window between the safe read and worker spawn,
      OR an equivalent fail-closed invariant spanning that entire interval
    - case M2 (guard_read → spawn race) passes
    - cases M2b and M4 block before spawn, with distinguishable traces
  note_identity_is_not_sufficient: >
    An earlier revision implied path-A feasibility rested entirely on resolving the
    global-proxy identity question. That was incomplete: identity is ONE necessary
    conjunction, atomic timing is another and is independently unresolved. Solving proxy
    identity does not establish that any cited hook runs at the dispatch boundary.

  boundary_timing_gap: >
    Verified against pinned v17.2.10 (3a8591a). The ordinary loop `tool_call` event is a
    PRE-SCHEDULING interception point, not the native spawn boundary. It can block a call,
    but "can block somewhere before execution" is strictly weaker than "check and spawn
    share one indivisible boundary". Source:
      - session/agent-session.ts:3179-3187 — the loop emits `tool_call` for a
        loop-dispatched call at ARG-PREP time, documented as "before concurrency
        scheduling, `tool_execution_start`, and the wrapper's approval gate", and MARKS the
        dispatch so ExtensionToolWrapper does not emit a second event.
      - extensibility/extensions/wrapper.ts:183 — consumeToolCallEmitted(...) consumes that
        marker unconditionally.
      - extensibility/extensions/wrapper.ts:205 — `if (!loopEmittedToolCall && ...)`: the
        wrapper emits `tool_call` ONLY for dispatches the loop never saw. So for an ordinary
        loop-dispatched task call there is NO second event at execute time.
      - extensibility/extensions/wrapper.ts:238+ — the approval gate runs AFTER the event
        and may await UI/events; the wrapped tool.execute runs after that.
    Untested interval that therefore exists between an extension guard read and worker
    spawn: guard reads apply=false → handler returns → assistant message completes →
    concurrency scheduling → approval (may await UI) → native TaskTool.execute begins →
    async agent discovery awaits → native policy reads task.isolation.apply → worker
    allocation/spawn. Settings.override() may run anywhere in that interval.

  composed_candidate_re_registration_plus_proxy: >
    The more plausible current candidate is the COMPOSITION of surface 3 and surface 4: a
    re-registered `task` tool whose execute() reads the global proxy and then calls
    ctx.invokeTool(params). Pinned source shows this is NOT automatically atomic either:
      - extensibility/extensions/wrapper.ts:62-86 — the registered tool's execute delegates
        via ctx.invokeTool bound to the same tool name.
      - extensibility/extensions/runner.ts:445-462 — invokeNativeTool calls the UNWRAPPED
        native execute directly.
      - task/index.ts:664-689 — native TaskTool.execute then does `await Promise.all(...)`
        over per-item preflight resolution before any execution path is chosen.
      - task/structured-subagent.ts:245-255 — resolveEffectiveSubagentPolicy awaits
        discoverAgents(request.session.cwd).
      - task/structured-subagent.ts:315-317 — only AFTER those awaits does the native policy
        read request.session.settings.get("task.isolation.apply").
    So a wrapper-side proxy read is followed by at least two await points before the native
    read. A bare "read false, then ctx.invokeTool" wrapper is NOT an atomic
    check-and-dispatch primitive.
  no_public_bound_value_escape: >
    Binding the safe value into the call instead of re-reading it would close the interval,
    but no public argument carries it. structured-subagent.ts:315-317 gives
    `request.isolation?.apply` PRECEDENCE over the settings read — however task/types.ts
    exposes only `isolated?: boolean` (:128, :147, :212, :244, :304) and no
    `isolation.apply` parameter, and task/index.ts:643 and :1418 populate the request as
    `isolation: { requested: params.isolated }` ONLY. `apply` is therefore always undefined
    on the public task path, so the settings read at dispatch always wins. A future round
    may revisit this if OMP exposes a bound-apply argument.

  blocking_source_gap: >
    Verified against pinned v17.2.10 (3a8591a): the blocking capability and the settings
    capability live on DIFFERENT public contexts, and no public surface joins them.
    Four candidate surfaces were checked; surfaces 1-3 are CLOSED, surface 4 is UNRESOLVED:
      1. ExtensionContext (extensibility/extensions/types.ts:415-483) — the context the
         tool_call interceptor actually receives. Has NO settings field.
      2. ReadonlySessionManager (session/session-manager.ts:327-350) — reachable from
         ExtensionContext.sessionManager, but it is a 21-member Pick with no settings
         accessor (getCwd, getSessionDir, getEntries, putBlob, ...).
      3. ExtensionContext.invokeTool / re-registered built-in (types.ts:479-482, and
         ToolDefinition.execute at types.ts:576-582) — a re-registered tool RECEIVES
         execute() for the call, but that is NOT the same as sitting at the protected
         native boundary: see composed_candidate_re_registration_plus_proxy below, which
         shows a read-then-invokeTool composition still has awaits before the native
         policy read and is therefore not automatically atomic. It also inherits the same
         missing-settings gap, since its execute() receives ctx: ExtensionContext.
         "Can receive execute" must never be abbreviated to "sits at the native boundary".
      4. The global settings Proxy (config/settings.ts:2371) — **UNRESOLVED, NOT closed.
         Host-scoped.** See global_proxy_candidate below; an earlier revision wrongly
         recorded this surface as closed.
    By contrast CustomToolContext (extensibility/custom-tools/types.ts:98-99) DOES expose
    settings?: Settings ("Prefer over the global singleton") — but exposes no task
    dispatch member, so a custom tool cannot be the dispatch boundary.
    Consequence (F4-03 — corrected): surfaces 1-3 are closed FOR LIVE-SETTINGS ACCESS, i.e.
    for the IDENTITY conjunction only. An earlier revision concluded "Path A feasibility
    therefore rests entirely on surface 4" — that is the identity-only inference F3-02
    withdrew, restated. It does not follow. Even if surface 4 proves same-instance identity,
    the TIMING conjunction (boundary_timing_gap) remains independently unresolved, and a
    candidate must satisfy BOTH. E3-M remains NOT_ATTEMPTED and parallel mode stays
    DISABLED — but this is NOT the same as "no candidate exists".
    rule: proxy identity success is NECESSARY for that candidate, never SUFFICIENT for a
    Path-A PASS.

global_proxy_candidate:
  status: UNRESOLVED_AND_HOST_SCOPED   # must be settled empirically, not by inference
  correction: >
    An earlier revision claimed reading the global Proxy "proves nothing" and concluded
    "no known public path-A implementation exists on pinned v17.2.10". That conclusion was
    stronger than the source supports. cloneForCwd proves NON-UNIVERSALITY; it does not
    disprove instance identity on the default main-CLI path, and the package exports the
    proxy publicly (index.ts:17 — `export { Settings, settings }`).
  positive_identity_chain_default_main_CLI:   # verified line-by-line at 3a8591a
    - index.ts:17                     exports both Settings and the `settings` Proxy publicly
    - config/settings.ts:404-416      Settings.init() creates instance, assigns
                                      globalInstance = instance, returns THAT instance
    - main.ts:1282-1283               settingsInstance = deps.settings ?? await Settings.init(...)
    - main.ts:1545                    sessionOptions.settings = settingsInstance
    - sdk.ts:1271-1272                createAgentSession uses options.settings when provided
    - task/structured-subagent.ts:314-317
                                      dispatch reads request.session.settings.get(
                                        "task.isolation.apply")
    - config/settings.ts:2371-2384    exported Proxy delegates property access to globalInstance
    reading: >
      On the default main-CLI path with no injected deps.settings, this chain is consistent
      with the exported Proxy resolving to the SAME instance the dispatch reads. That makes
      the candidate plausible — not proven. It must be demonstrated empirically.
  negative_identity_paths:
    - main.ts:399    ACP session/new does args.settings.cloneForCwd(cwd) → DIFFERENT instance
    - sdk.ts:1271-1272  callers may inject options.settings / options.settingsManager
                        instead of the singleton → identity NOT guaranteed
    - config/settings.ts:603-620  cloneForCwd structuredClones layers into a distinct object
    - main.ts:1282   deps.settings ?? ... — an injected deps.settings also bypasses the global
  required_determination:   # all of it, before any PASS may be recorded
    - define the supported host modes for /orchestrated v0
    - test the imported proxy against the live session value under: project config,
      CLI overlay, in-session override, default main CLI, ACP cloned session (if ACP is
      supported), injected SDK settings (if SDK hosting is supported)
    - prove the read executes INSIDE the actual task interception boundary (not adjacent)
    - prove an unsafe value blocks before any worker spawn (gating cases M2, M2b, M4)
    - fail closed in every host where instance identity cannot be established
  v0_consequence: >
    Feasibility is UNRESOLVED, not refuted. E3-M stays NOT_ATTEMPTED and parallel mode
    stays DISABLED — the fail-closed posture is unchanged. What changed is the accuracy of
    the reason: the candidate is untested and host-scoped, not non-existent. If v0 must
    support ACP or arbitrary SDK hosts, this candidate is insufficient unless the
    implementation detects unsupported hosts and fails closed.
  consolidated_status:   # F4-03 — the single current-authority statement of path-A status
    identity_surface:
      surfaces_1_to_3: closed_for_live_Settings_access
      global_proxy: UNRESOLVED_AND_HOST_SCOPED
    timing_surface:
      ordinary_loop_tool_call: PRE_SCHEDULING_NON_ATOMIC
      read_then_invokeTool: NON_ATOMIC_UNTIL_STRONGER_INVARIANT_PROVEN
      other_public_native_boundary_surface: UNRESOLVED
    overall: UNRESOLVED
    rule: >
      Proxy identity success is NECESSARY for that candidate and never SUFFICIENT for a
      Path-A PASS. No statement of the form "feasibility rests entirely on proxy identity"
      belongs in current authority — identity and timing are independent conjunctions and
      both are unresolved.
  explicit_non_pass: >
    "Same JS event loop" or "same model turn" reasoning alone, without an actual
    interceptor running at the dispatch boundary, does NOT satisfy path A. Tool calls
    are separated by async JS operations regardless of model-turn framing. A separate
    preflight custom-tool call followed by a later TaskTool invocation is not atomic
    and is explicitly on the E3-M non-PASS list.

path_B_atomic_dispatching_primitive:
  approach: >
    A single trusted primitive that reads the live setting AND performs the task
    dispatch as one indivisible operation — no separate model-visible step between
    the read and the spawn. If the read returns an unsafe value the primitive never
    dispatches.
  requirement: >
    Read and dispatch must live inside the same primitive. Any design in which the
    model performs the read and then separately requests the dispatch is path-A
    territory at best and is non-PASS if no interceptor sits at the dispatch boundary.

worker_side_fingerprint:
  status: NOT a path to E3-M PASS
  approach: >
    Capture a settings fingerprint (hash of relevant keys) at preflight; the worker's
    first action reads ctx.settings and verifies the fingerprint; abort if mismatch.
  authority: defense_in_depth_only
  e3_m_pass_power: none
  limitation: >
    Detects the race post-dispatch, not pre-dispatch — the isolated worker has already
    been spawned, and the check is a model-directed action the worker can skip.
    Documenting the residual window does not convert a post-dispatch detector into a
    pre-spawn mechanical guard. May be adopted as an additional layer on top of a
    passing mechanism (path A, path B, or one admitted by pass_equivalence_rule); never as
    the mechanism that passes E3-M.

non_pass_behavioral_disclosure:
  former_label: path_C_behavioral_only   # renamed — "path C" no longer denotes a mechanism
  e3_m_pass_power: none
  approach: >
    Document that /orchestrated assumes no Settings mutations during execution; add a
    precondition note. Not a mechanical guard.
  limitation: >
    Same class as the behavioral canary — insufficient for enabling parallel mode
    mechanically. Acceptable only as disclosure, not as a gate.
  why_renamed: >
    `08-isolation-and-concurrency.md` previously listed "Path C: setting locked/forced for
    the duration of the guarded dispatch" as a third PASS-eligible option while this file
    used the same "path C" label for a non-PASS behavioral note — one identifier with two
    incompatible meanings. The label is withdrawn; the *behavioral* reading survives here as
    a non-PASS disclosure, and any *mechanical* lock/invariant is handled by the
    pass_equivalence_rule below rather than by a "path C" identifier.
  source_finding_precise_scope: >
    What the source supports (verified at 3a8591a): Settings.override()
    (config/settings.ts:518-528) applies overrides unconditionally — no lock, freeze, or
    read-only guard on the mutation path — and the readOnly option only sets #persist
    (settings.ts:384), which gates file writes (:1958, :1980, :2070), not in-memory
    mutation. Therefore: `built_in_public_lock_primitive_found: false`.
    What the source does NOT support (F3-04 — earlier overclaim withdrawn): that "a
    locked/forced setting cannot be implemented against the pinned runtime". Inspecting
    Settings.override() cannot exclude every extension composition, host wrapper, patched
    runtime, or equivalent invariant mechanism. Absence of a public primitive is not
    universal impossibility, and an earlier revision promoted the former into the latter.
```

**PASS-equivalence rule (F3-04 — normative).** The known-candidate list at the pinned SHA is
paths A and B; that is a statement about what has been *found*, not about what can *exist*.
The static-closure contract's equivalence escape hatch is retained explicitly:

```yaml
known_pinned_candidates:
  path_A: unresolved            # identity AND timing both unresolved
  path_B: unresolved
  built_in_lock_or_freeze_primitive: NOT_FOUND   # not "impossible"

pass_equivalence_rule:
  allowed: >
    Another source-verified mechanism with equivalent atomic / fail-closed semantics is
    PASS-eligible. It does not need to be reducible to path A or path B, and it does not
    need a new identifier — it is admitted on its properties, not its label.
  requirements:   # all four
    - unsafe state cannot cross into worker spawn
    - the invariant covers the COMPLETE guard-read → spawn interval (no interleavable window)
    - direct bypass fails closed (case M2b)
    - gating cases M1, M2, M2b, M4 all pass
  note: >
    An earlier revision asserted that any future lock/force implementation is "path A or
    path B by definition". That was stronger than necessary and risked a migration trap: a
    lock or invariant held from safety observation through spawn is conceptually equivalent
    fail-closed enforcement without being identical to a boundary interceptor (A) or a
    single read-and-dispatch primitive (B). Such a mechanism is admissible under this rule.
```

**Test matrix (for the chosen mechanism — path A, path B, or one admitted by
`pass_equivalence_rule`):**

```yaml
case_M1_no_mutation:
  gating:   true
  setup:    project apply:false, no mutation during execution
  expected: dispatch proceeds normally; no false positive

case_M2_guard_read_to_spawn_race:
  gating:   true
  supersedes: case_M2_mutation_between_t0_and_t3   # see M2-control below
  common_setup:   # F5-01 — branch-NEUTRAL: shared state and adversarial intent only
    - the candidate ENFORCEMENT GUARD itself observes effective apply=false
    - the harness ARMS an adversarial mutation trigger targeted at the earliest reachable
      seam after guard_read (arming is always possible; landing an effect is not)
    - record trigger/request, actual override-call entry, effect/disposition, and allocation
  common_setup_note: >
    F5-01: an earlier revision put "inject Settings.override(..., true) AFTER that guard read"
    and "place the injection before native worker allocation/spawn" at CASE level, above
    branch selection. That wording is branch-A-only and made branch B unsatisfiable. At the
    pinned SHA Settings.override() is fully synchronous — it returns void and applies the
    value via setByPath + #rebuildMerged + #fireEffectiveSettingChanged
    (config/settings.ts:518-528), with no deferred result in the built-in method. So for a
    same-stack atomic primitive the override CALL cannot execute inside the interval at all,
    and for a spanning invariant the call may enter but its effect is rejected/deferred —
    meaning "inject true before spawn" was never achieved in either valid branch-B shape.
    Effect-timing requirements therefore belong ONLY inside the branches. The harness can
    always ARM a trigger; whether the call enters and whether its effect lands are exactly
    what the branches distinguish.
  invariant_under_test: unsafe state cannot cross into worker spawn
  # F4-01: the oracle is BRANCH-SENSITIVE. An earlier revision required both
  # "the interval is non-interleavable" AND unconditionally "NO worker is spawned" — those
  # cannot both be normative. If atomicity holds, effective apply stays FALSE through
  # allocation, and spawning is CORRECT (it agrees with M1). Demanding a block there would
  # require a false positive. What matters is `mutation_effect`, not `mutation_attempt`.
  branch_A_effect_lands_before_allocation:
    setup:   # the ONLY branch that may require an effective mutation before allocation
      - the override CALL enters after guard_read
      - mutation_effect makes effective apply=true BEFORE worker allocation
    pass_requires:
      - a boundary recheck or spanning invariant detects the effective unsafe state
      - worker_spawn_count == 0
  branch_B_effect_cannot_land_in_interval:
    setup:
      - the harness trigger is armed / adversarially scheduled (per common_setup)
      - EITHER the actual override call cannot enter until after allocation,
        OR it enters but is rejected / deferred / observationally inert under a
        spanning invariant
    pass_requires:
      - effective apply remains FALSE at allocation
      - safe spawn MAY proceed — this is NOT a false-positive failure
      - the trace proves mutation_effect occurred only AFTER the protected interval,
        or was rejected / deferred / inert
      - the corresponding atomicity_proof option is satisfied (option_1 or option_2)
  trace_schema:   # F5-03/F5-04 — branch-TOTAL and observer-aware; every field has a
                  # legal value for a correct run in EITHER branch. A bare `_time` name is
                  # not enough: it still implies a timestamp for an event that correct
                  # enforcement may prevent.
    guard_read:
      status: OBSERVED | SOURCE_PROVEN
      time: timestamp | null
    mutation_trigger:                 # F5-04 event 1 of 3 — arming/scheduling
      status: ARMED | REQUESTED
      time: timestamp
    override_call_enter:              # F5-04 event 2 of 3 — the call actually begins
      status: OBSERVED | DEFERRED_UNTIL_AFTER_INTERVAL | NOT_REACHED
      time: timestamp | null
    mutation_effect:                  # F5-04 event 3 of 3 — the value actually changes
      status: EFFECTIVE | REJECTED | DEFERRED | INERT
      time: timestamp | null
    native_task_execute_enter:
      status: OBSERVED | NOT_REACHED | NOT_APPLICABLE
      time: timestamp | null
    worker_allocation_attempt:
      status: OBSERVED | NOT_REACHED
      time: timestamp | null
    worker_spawn_count: integer
    effective_apply_at_allocation:
      value: false | true | RUNTIME_UNOBSERVABLE
      evidence_kind: RUNTIME | SOURCE_CALL_GRAPH | SPANNING_INVARIANT
      evidence_anchor: source_or_artifact_reference
    observer_non_interference:
      required: true
      proof: >
        Instrumentation adds no await, synchronous callback, getter/proxy trap, event
        emission, or other seam that changes the candidate's atomicity/re-entrancy
        properties. An observer that creates the interleaving it measures invalidates both
        the measurement and any option_1 proof that depends on the interval being seam-free.
  why_typed_statuses_not_bare_times: >
    F4 replaced four mandatory EVENTS with seven field names, which fixed the
    "required event that must not happen" contradiction but not the underlying grammar: a
    required `native_task_execute_enter_time` still presumes a timestamp for an event that a
    correct Path-A block prevents (guard reads false → effect lands → boundary recheck
    blocks → native execute never entered → allocation never attempted). NOT_REACHED is now
    an explicit legal value. Likewise `effective_apply_at_allocation` presumed a runtime
    observation point that a genuinely atomic mechanism may not expose — and instrumenting
    one there can itself introduce the seam that invalidates the option_1 proof. Hence
    RUNTIME_UNOBSERVABLE with a declared `evidence_kind`.
  runtime_unobservable_is_not_a_waiver: >
    `effective_apply_at_allocation.value: RUNTIME_UNOBSERVABLE` is accepted ONLY when
    accompanied by a COMPLETE atomicity_proof (option_1 or option_2) and an
    `evidence_kind` of SOURCE_CALL_GRAPH or SPANNING_INVARIANT with a concrete
    `evidence_anchor`. It is never a licence to omit evidence, and a source/invariant
    argument must never be recorded as though it were a runtime observation.
  forbidden_as_pass:
    - mutation placed only between the E3-L observational preflight and the guard read
    - the guard seeing `true` because the mutation happened BEFORE the guard ran
    - worker-side detection of the mismatch
    - worker refusal after spawn
    - "parent tree unchanged" as the only evidence
    - an effective apply=true crossing into worker spawn (the invariant itself)
    - recording mutation_attempt WITHOUT recording mutation_effect / rejection / defer state
      — attempt alone cannot distinguish branch A from branch B
    - a finite sample in which the harness simply missed an actually interleavable interval
  rationale: >
    This is the load-bearing case and it must attack the candidate's OWN read, not an
    earlier diagnostic observation. An earlier revision mutated after the observational
    preflight (t0), which a mechanism can pass merely by having a later handler correct a
    stale preflight: t0 preflight reads false → t1 mutate to true → t2 handler reads true
    and blocks. That trace proves a later read can supersede an earlier one; it proves
    nothing about whether the handler's read is coupled to the spawn. The protected event
    is the dispatch/spawn itself, not eventual patch application — "parent tree unchanged"
    is not a substitute for "no worker spawned", since an isolated worker that spawned and
    then declined still consumed the dispatch, and its refusal is a model-directed action
    it can skip.
  if_injection_is_impossible: >
    If the candidate primitive is genuinely atomic, the harness may be UNABLE to make the
    mutation EFFECTIVE between guard_read and worker_allocation (branch B). That inability
    is a valid PASS result, but it must be DEMONSTRATED — never assumed, and never inferred
    from a finite sample in which the race did not happen to occur. See atomicity_proof
    below for what counts.
  atomicity_proof:   # F5-02 — no-await belongs to option_1 ONLY, not to the gate as a whole
    universal_rule: >
      No-await alone is neither a complete proof NOR a universal prerequisite. It is one
      requirement of option_1 only. Option_2 is judged by invariant coverage across ALL
      interleavings, INCLUDING awaits. Satisfy option_1 OR option_2 — they are alternatives,
      and no requirement of one may be imposed on the other.
    why_not_universal: >
      An earlier revision annotated this block and the Artifact rule with '"no await" is
      NECESSARY but NOT SUFFICIENT'. The "not sufficient" half is right (synchronous
      re-entrancy needs no await — see option_1's callback clause). The "necessary" half is
      WRONG for option_2 and silently re-narrowed the equivalence mechanism class that the
      pass_equivalence_rule restores: a lock, freeze, capability, or other spanning
      fail-closed invariant may deliberately remain held ACROSS one or more awaits. The await
      creates an interleaving opportunity; the invariant makes the mutation's effect
      unobservable until after the protected interval. Demanding no-await there would reject
      a mechanism that is safe by construction.
    option_1_non_interleavable_source_path:
      requires:
        - no await or async yield anywhere in the COMPLETE guard-read → allocation interval
        - no attacker-controlled or extension-controlled SYNCHRONOUS callback in the interval
        - no synchronous event emission, getter, proxy trap, hook, or re-entrant call in the
          interval capable of reaching Settings.override or any equivalent mutation path
        - the entire call graph for the interval is ENUMERATED at the pinned SHA (not sampled)
    option_2_spanning_invariant:
      await_allowed: true            # explicitly — awaits do not disqualify this option
      requires:
        - the invariant remains held/effective across EVERY yield and EVERY synchronous
          re-entry within the protected interval
        - the mutation effect is rejected, deferred, or observationally inert until the
          protected interval ends
        - effective unsafe state cannot become visible to worker allocation
        - invariant RELEASE and any deferred-effect ordering are recorded in the trace
        - branch-sensitive M2 evidence records trigger, override-call entry,
          effect/disposition, and spawn state (see trace_schema)

case_M2_control_stale_preflight_corrected:
  gating:   false
  authority: control_only
  e3_m_pass_power: none
  setup:    project apply:false at the observational preflight; override to true after the
            preflight read returns but before the guard runs
  expected: the guard observes the CURRENT value (true) and blocks before any worker spawn
  note: >
    Retained as a useful control — it confirms the guard reads live state rather than a
    cached preflight value. It is NOT the adversarial guard-to-spawn case and carries no
    PASS power: passing it only shows a later read supersedes an earlier one.

case_M2b_no_preflight_direct_bypass:
  gating:   true
  contract: option_A_live_unsafe_state
  setup:
    - NO preflight read occurs at any point — the guard is never invoked cooperatively
    - preflight_invocation_count == 0 (must be recorded and asserted zero)
    - live effective task.isolation.apply = TRUE at the moment of dispatch (unsafe)
    - the protected task is attempted DIRECTLY, bypassing the cooperative path entirely
  expected: the task boundary itself blocks dispatch before any worker spawn
  required_evidence:   # distinguishes M2b from M4 — see trace_distinction below
    - preflight_invocation_count: 0
    - no preflight observation record exists in the transcript
    - the block originates at the boundary, with no prior cooperative refusal
  premise_note: >
    The unsafe state is explicit and is the live value, not the absence of a preflight.
    This matters: under EVERY eligible mechanism (path A reads live at the boundary; path B
    reads live and dispatches atomically; an equivalence-rule mechanism holds a spanning
    fail-closed invariant) a missing observational preflight does NOT by
    itself make a dispatch unsafe — if the live value were apply:false the dispatch would
    be legitimately safe, which is what M1 already covers. Without naming the live value,
    two correct implementations could produce opposite results for this same written case.
    v0 deliberately does NOT adopt the alternative capability/token contract
    (preflight mints an unforgeable authorization; absence of the token is itself unsafe),
    because no such token primitive is specified or source-verified — adopting it would
    add an unverified mechanism to a fail-closed gate. If a future round specifies one,
    it must define capability creation, binding, lifetime, and anti-replay semantics.
  rationale: >
    This is the direct-bypass failure mode and it is distinct from M2. M2 tests whether
    a mutation between t0 and t3 is caught; M2b tests whether the mechanism has any
    authority when no preflight happened. A mechanism that only works when politely
    called first is cooperative, not mechanical — it fails exactly where an
    uncooperative or forgetful caller matters most. M2 cannot substitute for M2b:
    passing M2 only proves the guard works on a path that already invoked it.

case_M3_mutation_reverted:
  gating:   false
  authority: characterization_only
  e3_m_pass_power: none
  setup:    project apply:false; override to true; revert to false before dispatch
  expected: document whether the chosen mechanism catches the revert or misses it;
            a known gap of the mechanism, not a failure if documented
  note: >
    A case whose outcome may be either "caught" or "missed", and whose miss is explicitly
    never a failure, is characterization — it cannot confer or withhold a PASS. It is
    recorded as a required *diagnostic* in the artifact so the mechanism's blind spots are
    on record, but it has no independent PASS power. Do not read a documented miss here as
    evidence for or against E3-M.

case_M4_preexisting_unsafe_after_cooperative_observation:
  gating:   true
  former_id: case_M4_apply_true_before_call
  setup:
    - apply=true in effect BEFORE the preflight runs (no mid-execution mutation needed)
    - the preflight DOES execute and observes true — preflight_invocation_count == 1
    - the cooperative path therefore refuses; the harness then DELIBERATELY attempts the
      protected task anyway, despite that refusal
  expected: the boundary INDEPENDENTLY blocks before any isolated worker spawn — this is
            the baseline case; a mechanism that fails M4 provides no protection at all
  required_evidence:
    - preflight_invocation_count: 1
    - the preflight observation record exists and shows `true`
    - a cooperative refusal was issued AND was deliberately overridden by the harness
    - the boundary block is attributable to the boundary, not to the cooperative refusal
```

**M2b vs M4 — required trace distinction (F3-03).** Distinct labels do not create distinct
evidence. Both cases end in "blocked before spawn", so the artifact MUST prove they
exercised different execution paths rather than recording the same trace under two IDs:

```yaml
trace_distinction:
  M2b:
    preflight_invocation_count: 0        # cooperative path never entered
    cooperative_refusal_present: false
    tests: does the boundary have authority when nothing invoked it?
  M4:
    preflight_invocation_count: 1        # cooperative path entered AND refused
    cooperative_refusal_present: true
    cooperative_refusal_overridden: true
    tests: does the boundary block independently of the cooperative refusal?
  artifact_requirement: >
    Both traces must be recorded with their preflight_invocation_count and refusal state.
    If the two recorded traces are indistinguishable, BOTH cases are unproven — a runner
    that executes M4 with no preflight produces the M2b trace and silently collapses two
    independent failure modes into one. Equivalent separations are acceptable provided the
    artifact demonstrates observably different execution paths.
```

**Canonical acceptance-class mapping (normative — IDs are stable, classes are the contract).**
The four gating classes below are what E3-M actually tests; the `M*` identifiers are retained
only so that references in already-committed documents keep their meaning. Any future
renumbering MUST preserve this class mapping:

```yaml
canonical_acceptance_class_mapping:
  safe_stable_dispatch:                        M1    # gating — must NOT false-positive
  guard_read_to_spawn_race:                    M2    # gating — the load-bearing case (F3-01)
  no_preflight_direct_bypass:                  M2b   # gating — no cooperation; preflight count 0
  preexisting_unsafe_after_cooperative_refusal: M4   # gating — baseline; preflight count 1

diagnostic_only:
  mutation_reverted:                           M3    # characterization; e3_m_pass_power: none
  stale_preflight_corrected:                   M2-control  # control; e3_m_pass_power: none

gating_set:              [M1, M2, M2b, M4]      # all four must PASS for E3-M PASS
required_diagnostic_set: [M3]                   # MUST be recorded; cannot pass or fail the gate
optional_control_set:    [M2-control]           # MAY be recorded; no PASS power
artifact_set:            [M1, M2, M2b, M3, M4]  # exactly what the artifact MUST contain

# F4-05: M2-control is OPTIONAL, in every list, without exception. An earlier revision put
# it in a `diagnostic_set` annotated "must be recorded" while the artifact_set comment and
# the Artifact section both called it optional — two incompatible answers. It is a control
# that confirms the guard reads live state; it is not required evidence for the gate.

class_renames_F3:   # IDs are stable; these classes were sharpened, not renumbered
  M2:  was "unsafe_mutation_before_dispatch" — mutation after the OBSERVATIONAL preflight.
       Now "guard_read_to_spawn_race" — mutation after the CANDIDATE GUARD's own read.
       The old class is retained as the non-gating M2-control.
  M4:  was "preexisting_unsafe_state" — silent on whether a preflight ran.
       Now requires preflight_invocation_count == 1 plus a deliberately overridden
       cooperative refusal, so M4 cannot produce the M2b trace.
```

**E3-M non-PASS mechanisms (explicit — must not be accepted as PASS):**

```text
- a separate preflight custom-tool call followed by a later TaskTool invocation
- empirical evidence that no Settings mutation happened to occur between calls
- "same JS event loop" or "same model turn" reasoning without an actual dispatch interceptor
- a worker's first model-directed action checking a fingerprint (post-dispatch, skippable)
- a worker prompt instructing it to abort before edits (behavioral, not mechanical)
- the behavioral isolation canary
- a finite sample in which hub happened not to execute
- a mechanism that only blocks when a preflight was cooperatively invoked first
  (i.e. fails case M2b — cooperative, not mechanical)
- reading the global `settings` Proxy (config/settings.ts:2371) and *assuming* it is the
  instance dispatch will read — identity is host-scoped and must be demonstrated, not
  assumed: ACP clones (main.ts:399), injected `options.settings`/`settingsManager`
  (sdk.ts:1271-1272) and injected `deps.settings` (main.ts:1282) all yield a different
  instance. NOTE: this entry rejects the *assumption*, not the surface — see
  `global_proxy_candidate` above. A proxy read whose instance identity is empirically
  proven for the declared supported host, which executes at the dispatch boundary, and
  which fails closed on any host where identity cannot be established, is a path-A
  candidate and is NOT excluded by this list
- documenting a residual unsafe window as though disclosure converted a post-dispatch
  detector into a pre-spawn guard
- passing only the M2-control (stale preflight corrected by a later read) and presenting it
  as the guard-read→spawn race — it proves a later read supersedes an earlier one, nothing
  about coupling to spawn (F3-01)
- an ordinary loop `tool_call` handler presented as "the dispatch boundary" — it is emitted
  at arg-prep time, before concurrency scheduling and the approval gate
  (agent-session.ts:3179-3187), and is not re-emitted at execute time for loop-dispatched
  calls (wrapper.ts:183, :205). Blocking ability ≠ atomic coupling (F3-02)
- a wrapper that reads settings and then calls ctx.invokeTool, without a COMPLETE
  atomicity_proof — task/index.ts:664-689 (await Promise.all over per-item preflight) and
  structured-subagent.ts:245-255 (await discoverAgents) both sit in that interval (F3-02).
  F5-02: showing "no await/yield intervenes" is NOT on its own enough to admit this
  composition — that phrasing could be misread as an accept condition. It must satisfy the
  FULL option_1 (no await AND no synchronous re-entrant mutation path AND an enumerated
  pinned-SHA call graph for the interval) OR present a spanning option_2 invariant. Absence
  of await is one requirement of option_1, never a standalone pass
- M2b and M4 recorded with indistinguishable traces — if preflight_invocation_count and
  cooperative-refusal state do not differ between them, BOTH are unproven (F3-03)
```

**E3-M PASS consequence:**

```yaml
parallel_mode: ENABLED
guarded_dispatch: confirmed via ONE of —
                  path A (interceptor at the actual native dispatch boundary, reading the
                    SAME live parent Settings instance, blocking before any worker spawn);
                  path B (atomic read-and-dispatch primitive);
                  or any mechanism admitted by pass_equivalence_rule (equivalent
                    atomic / fail-closed semantics, source-verified).
                  Post-dispatch detection is NOT a PASS mechanism under any of them.
timing_conjunction_satisfied: true   # F3-02 — separate from settings identity
settings_identity_demonstrated: true
e3_l_prerequisite: satisfied
required_gating_cases: [M1, M2, M2b, M4]   # ALL four must pass — M2b is mandatory
required_diagnostic_cases: [M3]            # must be recorded; no PASS power (characterization)
optional_control_cases: [M2-control]       # MAY be recorded; no PASS power (F4-05)
artifact_must_record: [M1, M2, M2b, M3, M4]
m2_oracle: branch-sensitive (F4-01/F5-01) — common_setup is branch-NEUTRAL (arm a trigger;
           do not require an effect). Branch A (effect landed before allocation) requires
           worker_spawn_count == 0. Branch B (effect could not land) permits spawn when
           effective_apply_at_allocation was false, or RUNTIME_UNOBSERVABLE with a declared
           evidence_kind + anchor and a COMPLETE atomicity_proof (F5-03).
m2_trace: per trace_schema — typed statuses, NOT_REACHED legal, observer_non_interference
          proven, and mutation_trigger / override_call_enter / mutation_effect kept
          distinct (F5-04)
```

**E3-M FAIL or not attempted consequence:**

```yaml
parallel_mode: DISABLED
fallback: sequential non-isolated + disclosure
note: >
  E3-L satisfies live_settings_read_verified but does not enable parallel.
  E3-M is optional for v0 — parallel remains disabled if E3-M is deferred.
```

**Artifact:** Mechanism design note + test transcript for the chosen mechanism (path A,
path B, or one admitted by `pass_equivalence_rule`). Must record:

- **The five artifact cases** — gating `[M1, M2, M2b, M4]` (all four must pass; M2b, the
  no-preflight direct bypass, is mandatory and not optional) plus required diagnostic `[M3]`
  (recorded for characterization; no PASS power). `M2-control` is in
  `optional_control_set` — it MAY be recorded and is not part of the five (F4-05).
- **M2's `trace_schema`** (typed statuses, not bare timestamps — F4-01/F5-03/F5-04) — every
  field per `case_M2_guard_read_to_spawn_race.trace_schema`, with its `status`/`value`
  recorded even when the event did not occur. `NOT_REACHED` is a legal, expected value for
  `native_task_execute_enter` and `worker_allocation_attempt` when a correct boundary block
  prevented them. The three mutation events stay **distinct** — `mutation_trigger` (armed),
  `override_call_enter` (call began), `mutation_effect` (value changed / rejected / deferred
  / inert); one timestamp may never stand for more than one of them. Record which branch was
  exercised: **branch A** (effect landed before allocation) requires `worker_spawn_count == 0`;
  **branch B** (the effect could not land) permits spawn provided
  `effective_apply_at_allocation` was false — or `RUNTIME_UNOBSERVABLE` with a declared
  `evidence_kind` and anchor. Recording a trigger or call-entry without the effect
  disposition is non-PASS. `observer_non_interference` must be proven: instrumentation that
  introduces a seam invalidates both the measurement and any option_1 proof.
- **Atomicity proof for branch B** (F4-02/F5-02) — satisfy **either** option, and do not
  impose one option's requirements on the other. `option_1_non_interleavable_source_path`
  requires no await AND no attacker- or extension-controlled synchronous callback, event
  emission, getter, proxy trap, hook, or re-entrant path reaching a mutation path, with the
  interval's call graph **enumerated** at the pinned SHA. `option_2_spanning_invariant`
  **explicitly permits awaits** (`await_allowed: true`): the invariant must hold across every
  yield and synchronous re-entry, the effect must be rejected/deferred/inert until the
  interval ends, and invariant release plus deferred-effect ordering must be recorded.
  No-await is **not** a universal prerequisite — it belongs to option_1 only; treating it as
  universally necessary would re-narrow the `pass_equivalence_rule` mechanism class.
- **M2b vs M4 trace distinction** — `preflight_invocation_count` and cooperative-refusal
  state for each, proving the two cases exercised different execution paths.
- **The settings-identity conjunction** — declared supported host modes plus instance-identity
  evidence for whichever `Settings` object the mechanism reads (see
  `global_proxy_candidate.required_determination`).
- **The boundary-timing conjunction** — evidence that the guard read executes at the native
  spawn boundary, not merely somewhere before execution (see `boundary_timing_gap`). Identity
  and timing are independent; both must be shown.
- **The overall determination** — whether a mechanical, not merely behavioral, guard is
  achievable with current OMP primitives.

**Blocks (if E3-M is attempted):** phase-02 parallel fan-out. Without a passing E3-M, parallel
mode remains DISABLED regardless of E3-L result.

### T-00.E4 — Rule sentinel propagation

Verify whether a RULES.md rule actually appears in a spawned worker's system prompt.

Procedure:
1. Add a unique sentinel rule to `RULES.md`:
   `RULE_SENTINEL_7F3A: before claiming task complete, emit the phrase QUALITY_GATE_SEEN.`
2. Spawn a worker without `autoloadSkills` for a corresponding skill.
3. Capture child system prompt or debug rule buckets (A: prompt-visible; B: stored but not visible; C: not discovered).
4. Observe worker behavior.
5. Compare token cost: forwarded RULES.md vs autoloadSkills.

**Artifact**: child prompt/rule-bucket capture + behavioral observation + token diff.

**Discriminator**:
- A → rules propagate and are prompt-visible; DR-4 updated accordingly
- B → rules propagate but are not prompt-visible; `autoloadSkills` still required
- C → parent did not discover RULES.md; investigate discovery mode

**Blocks**: DR-4 final justification; phase-02 worker initialization.

### T-00.E5 — LSP allowlist validation (CR-17)

Verify that `task.enableLsp = true` baseline setting actually makes the `lsp` tool callable within spawned subagents when `lsp` is present in the agent's `tools:` allowlist.

Procedure:
1. Spawn an agent (e.g., explorer) with `tools: [read, grep, glob, lsp]` and `task.enableLsp = true` baseline.
2. Instruct the agent to call `lsp references` on a known symbol.
3. Capture whether the tool call succeeds or is rejected as unavailable.
4. Compare with control: same agent without `lsp` in allowlist (expect rejection).

**Artifact**: LSP tool availability transcript per case (with-allowlist vs without-allowlist).

**Discriminator**:
- Success with `lsp` in allowlist → phase-01 T-01.3 proceeds safely
- Rejection despite allowlist → investigate `task.enableLsp` propagation or allowlist gating logic

**CR-40/CR-41 — this is a four-condition conjunction, not a single allowlist check.** The
procedure above tests only "allowlist present vs absent" against an assumed `task.enableLsp = true`
baseline. That assumed the spec author's environment: the setting defaults to **`false`**
(`config/settings-schema.ts:4615-4617`), so the interesting failures are ones the original
procedure could not distinguish. Additionally, CR-41 adds a fourth independent gate: `lsp.enabled`
at the built-in tool registration layer (`tools/index.ts:593`). Verified policy:

```ts
// task/structured-subagent.ts:318-320 — child session enableLsp resolution
enableLsp:
  !planMode &&
  (request.enableLsp ??
    ((request.session.enableLsp ?? true) && request.session.settings.get("task.enableLsp"))),

// tools/index.ts:593 — child session built-in tool registration (CR-41)
if (name === "lsp") return enableLsp && session.settings.get("lsp.enabled");
```

There is no per-call override — `request.enableLsp` is not on the model-facing task wire
(`docs/tools/task.md`), so the settings layer is the only control point. Each condition gets its
own case, because each has a different fix:

```yaml
E5-A:
  task_enableLsp: false            # OMP default
  agent_allowlist: includes lsp
  expected: worker lsp UNAVAILABLE
  fix_if_hit: project install must merge task.enableLsp: true (spec/12 §C-1)

E5-B:
  task_enableLsp: true
  parent_session_lsp: enabled
  lsp_enabled: true
  agent_allowlist: includes lsp
  expected:
    explorer:    lsp callable
    implementer: lsp callable
    reviewer:    lsp callable
    verifier:    lsp NOT in allowlist by contract — control case

E5-C:
  task_enableLsp: true
  parent_session_lsp: DISABLED
  expected: worker lsp UNAVAILABLE
  fix_if_hit: user must relaunch with LSP enabled — the template cannot fix this

E5-D:
  task_enableLsp: true
  parent_session_lsp: enabled
  agent_allowlist: lsp ABSENT      # the original control case
  expected: worker lsp UNAVAILABLE
  fix_if_hit: agent file edit (phase-01 T-01.3)

E5-E:
  all_conditions_met: true
  language_server: unavailable / not installed
  expected: distinguish "tool callable but no server" from "tool unavailable"

E5-F:
  task_enableLsp: true             # CR-40 satisfied
  parent_session_lsp: enabled      # condition 3 satisfied
  agent_allowlist: includes lsp    # condition 1 satisfied
  lsp_enabled: false               # CR-41 gate — independent setting, default: true
  expected: worker lsp UNAVAILABLE
  fix_if_hit: enable lsp.enabled in project config or session settings
  note: >
    This case is distinct from E5-A: `task.enableLsp` is true, the L0/CR-40 check passes,
    but `lsp.enabled=false` at tools/index.ts:593 means the child tool list does not contain
    lsp. The disclosure MUST name lsp.enabled as the failed condition, not task.enableLsp.
```

**The discriminator that matters is the error shape.** E5-A, E5-C, E5-D, E5-E, and E5-F all
present to the agent as "LSP did not work", but they require five different remediations (merge
a project setting / relaunch the session / edit an agent file / install a language server /
enable the lsp.enabled setting). Record the exact observed failure — is `lsp` absent from the
tool list, or present and erroring? — because the reduced-capability disclosure required by
`07-retrieval-and-code-understanding.md §A-1` must name the actual cause. A disclosure reading
"LSP unavailable" without the cause sends the user to the wrong fix.

**Artifact (extended)**: LSP capability transcript per case A–E, each recording the tool-list
contents and the verbatim error or success.

**Blocks**: phase-01 T-01.3 (LSP allowlist fix for explorer, implementer, reviewer);
phase-05 T-05.3 (`task.enableLsp` as an owned project setting); the reduced-capability
disclosure contract in §07 §A-1.

---

## Deliverables

- Updated `registry/upstreams.yml` with pin + watched paths (SHA `3a8591a8af5b6d200088d12ca75a5517cb064fa8`)
- Compatibility/verified-claims record
- `template/.omp/policies/` and `template/.omp/schemas/` **removed**; all 9 files (581 lines)
  re-homed per T-00.3 / T-00.4 (KD-001)
- Corrected docs
- `agent-result` conditional requirement (F-30) made explicit at its re-homed address
  (`implementer.md` `output:` pending OQ-A, plus `docs/schemas/agent-result.md`)
- Decision record (runtime_facts separated from normative decisions per CR-25)
- Experiment artifacts: T-00.E1 through T-00.E4 recorded transcripts

---

## Verification

```powershell
# All watched paths exist in the cloned upstream
# (run from repo root; expects _research/upstreams/oh-my-pi present)
.\scripts\validate-template.ps1 -Verbose
```

Manual checks:
1. Every watched path in `upstreams.yml` resolves to a real file in the pinned clone.
2. Grep `docs/` for "enforce", "validated", "benchmark" — each hit is accurate.
3. Grep for `-TargetDir` — zero hits outside a changelog note.

---

## Exit Criteria

- [ ] OMP pinned to exact SHA `3a8591a8af5b6d200088d12ca75a5517cb064fa8` with watched paths recorded
- [ ] All verified claims traceable to a source file
- [ ] `template/.omp/policies/` and `template/.omp/schemas/` do not exist; contents re-homed
      and no prompt references `policy:` / `schema:` (KD-001)
- [ ] No documentation claim contradicts verified runtime behavior
- [ ] `agent-result` conditional requirement explicit
- [ ] DR-1 … DR-7 resolved and recorded with runtime_facts separated from normative decisions
- [ ] **T-00.E1 artifact present** (schema precedence + provider enforcement)
- [ ] **T-00.E2 artifact present** (model-role merge order)
- [ ] **T-00.E3 artifacts present for ALL cases E3-A … E3-L** (isolation backend, capture-first settings control, root patch durability, branch mode, parallel capture, task-index integration order, conflict stop-preserve-report, nested-repo artifact durability, config precedence + preflight, **parent-overlay attestation gap with non-mutating canary (E3-I/CR-42)**, **async barrier + ordering with its no-`blocking` control (E3-J)**, **`task.batch: false` fallback (E3-K)**, **live-session settings read via custom-tool ctx (E3-L)**). **E3-A, E3-G, E3-H, E3-I, E3-J, and E3-L are BLOCKING for phase-02 parallel implementation**; E3-J additionally blocks Standard, whose stage arrows depend on the same barrier. **E3-M (guarded dispatch) gates parallel fan-out** — if attempted, its artifact must be present and record ALL FIVE cases: gating `[M1, M2, M2b, M4]` (all four must PASS — M2b, the no-preflight direct bypass, is mandatory) plus diagnostic `[M3]` (recorded for characterization only, no PASS power). PASS-eligible mechanisms are path A, path B, **or any mechanism admitted by `pass_equivalence_rule`** (source-verified, equivalent atomic / fail-closed semantics — it need not reduce to A or B). The retired `path C` label denotes no mechanism; label retirement does NOT narrow the mechanism space. If not attempted, parallel mode remains DISABLED and sequential non-isolated is the v0 fallback.
- [ ] **T-00.E4 artifact present** (rule sentinel propagation)
- [ ] **T-00.E5 artifacts present for cases E5-A … E5-F** (LSP capability as a four-condition conjunction — `task.enableLsp` default-false, parent-session gate, agent allowlist, `lsp.enabled` gate (CR-41), language-server availability), each recording the tool-list contents and verbatim error so the five distinct remediations are distinguishable (CR-40/CR-41)

---

## Risks

| Risk | Mitigation |
|---|---|
| Correcting docs makes the project look less complete | Accuracy is the point; completeness claims that are false are worse than gaps |
| Pinned commit becomes stale immediately | Expected; §14-D defines the controlled update process |
| Reclassification reads as "these files are useless" | Header states they are human-authoritative, just not runtime-loaded |
