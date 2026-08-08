# Phase 00 — Foundation

> OPUS PROPOSED SPEC v1 | Establish ground truth before changing anything.

**Depends on**: nothing
**Blocks**: phase-01

---

## Objective

Freeze the facts. Record the exact OMP commit the template's runtime claims were
verified against, correct every documentation claim that contradicts verified
behavior, and reclassify `policies/` and `schemas/` as documentation.

No behavior changes in this phase. This is the phase that makes later phases
falsifiable.

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

### T-00.3 — Reclassify policies as documentation

Add a header to each `template/.omp/policies/*.yml`:

> This file is **documentation**. OMP has no policy loader and no `policy://`
> scheme. Its content is authoritative for humans and is inlined into command and
> agent prose at authoring time. Nothing reads this file at runtime.

**Acceptance**: all five policy files carry the header. No file claims runtime effect.

### T-00.4 — Reclassify schemas as documentation

Add an equivalent header to each `template/.omp/schemas/*.yml`, stating that:
- runtime enforcement happens through the worker agent's **`output:` frontmatter** (the canonical schema source per DR-2);
- caller task `outputSchema` is an explicit per-call override, not the default path;
- these YAML files are the human-authoritative source that generates the inline `output:` blocks; nothing reads them at runtime.

**CR-28 correction:** the header must NOT say "enforcement happens through `outputSchema` inlined in the task call" — that inverts DR-2. The canonical enforcement path is `agent output: frontmatter → YieldTool validator`. Caller `outputSchema` is the override/escape-hatch.

**Acceptance**: all four schema files carry the corrected header. No schema file claims caller `outputSchema` is the primary enforcement path.

### T-00.5 — Correct the documentation claims

Fix, in `docs/**`, `README.md`, and `docs/final-report.md`:

- any statement that schemas or policies are enforced at runtime
- any statement that `validate-template.ps1` passing means the workflow works
- the installer invocation examples that use non-existent parameters (`-TargetDir`)
- the claim that `benchmark.ps1` benchmarks anything

**Acceptance**: no doc statement contradicts `02-runtime-semantics.md`. Installer
examples match the script's real parameters.

### T-00.6 — Fix the agent-result schema contradiction

`agent-result.schema.yml` lists `verification_results` as optional while a field rule
requires it for `status: completed`. Make the conditional requirement explicit.

**Acceptance**: the schema states the conditional requirement unambiguously (F-30).

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

## Experiment Tasks (Phase-Gate Required)

These experiments resolve open questions that later phases depend on. **Phase 00
cannot close and dependent phases cannot begin until each experiment has a recorded
artifact.** Record: exact OMP SHA, OS/runtime, provider/gateway version, raw
(sanitized) output, interpretation, and which decision is changed or retained.

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

**CR-42 canary contract.** The canary is a read-only agent (tools: `[read]`). It creates NO
files. The discrimination is via merge summary text:

```text
apply=false → merge-summary begins "Isolation: ..."   (§E-9.2 apply=false path)
apply=true  → merge-summary is "No changes to apply." (§E-9.2 apply=true, no-change path)
```

Assert that after the canary runs: `parent HEAD == before`, `parent git status == before`,
`no files created or modified in parent`. On the apply=true path the canary must still produce
zero parent mutations. If the canary creates any file in the parent even on the failure path,
that is a CR-42 violation and §08 §E-9.2 must be revised before phase-02.

Run the same shape a second time with an **in-session** override instead of a CLI overlay
(change the setting via `/settings` mid-session, then dispatch). `Settings.set()` writes the
in-memory `#overrides` layer (`config/settings.ts:524`), so no file changes at all — this is
the harder variant and the one no external read can ever catch.

Also record the canary's own cost and reliability: wall time, tokens, and whether the
summary-discrimination assertion is stable across repeated runs (a flaky gate is worse than
none).

**Records**: whether `omp config get` can be trusted as a gate (expected: no, diagnostic only),
whether the read-only canary reliably discriminates apply=false vs apply=true, and whether it
leaves zero parent mutations in both cases. If the canary proves unreliable, the parallel path
needs a different authority and §08 §E-9.2 must be revised before phase-02.

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

**E3-A, E3-G, E3-H, E3-I, and E3-J are BLOCKING for phase-02 parallel implementation.** E3-J
additionally blocks *every* workflow size, not just Orchestrated — Standard's stage arrows
depend on the same barrier.

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
- Nine reclassification headers (5 policies + 4 schemas)
- Corrected docs
- Fixed `agent-result.schema.yml`
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
- [ ] Policies and schemas labeled documentation-only
- [ ] No documentation claim contradicts verified runtime behavior
- [ ] `agent-result` conditional requirement explicit
- [ ] DR-1 … DR-7 resolved and recorded with runtime_facts separated from normative decisions
- [ ] **T-00.E1 artifact present** (schema precedence + provider enforcement)
- [ ] **T-00.E2 artifact present** (model-role merge order)
- [ ] **T-00.E3 artifacts present for ALL cases E3-A … E3-K** (isolation backend, capture-first settings control, root patch durability, branch mode, parallel capture, task-index integration order, conflict stop-preserve-report, nested-repo artifact durability, config precedence + preflight, **parent-overlay attestation gap with non-mutating canary (E3-I/CR-42)**, **async barrier + ordering with its no-`blocking` control (E3-J)**, **`task.batch: false` fallback (E3-K)**). **E3-A, E3-G, E3-H, E3-I and E3-J are BLOCKING for phase-02 parallel implementation**; E3-J additionally blocks Standard, whose stage arrows depend on the same barrier.
- [ ] **T-00.E4 artifact present** (rule sentinel propagation)
- [ ] **T-00.E5 artifacts present for cases E5-A … E5-F** (LSP capability as a four-condition conjunction — `task.enableLsp` default-false, parent-session gate, agent allowlist, `lsp.enabled` gate (CR-41), language-server availability), each recording the tool-list contents and verbatim error so the five distinct remediations are distinguishable (CR-40/CR-41)

---

## Risks

| Risk | Mitigation |
|---|---|
| Correcting docs makes the project look less complete | Accuracy is the point; completeness claims that are false are worse than gaps |
| Pinned commit becomes stale immediately | Expected; §14-D defines the controlled update process |
| Reclassification reads as "these files are useless" | Header states they are human-authoritative, just not runtime-loaded |
