# 08 — Isolation and Concurrency

## Authoritative reservation (KD-028)

One task has one authority/integration writer. Every concurrent mutating task requires a
distinct authoritative worktree plus a non-overlapping scope reservation; ambiguous overlap needs explicit
recorded user authority. Worker worktrees are subordinate/provisional. The integration owner
serially applies and verifies selected outputs, freezes one candidate, and retains acceptance
authority. The state core never creates, deletes, merges, or prunes Git worktrees.

> Verified OMP isolation/concurrency facts plus the guarded parallel-writer candidate.
>
> **Topic 02 boundary:** Parallel execution and parallel writers are optional. Sequential
> execution remains Orchestrated when independently verifiable work units, an integration
> contract, and cross-boundary verification exist. Parallel-writer preconditions apply only
> when that path is selected by the KD-027 topology and Phase 02 runtime migration;
> they do not define workflow classification.
>
> The source-backed failure analysis below remains authoritative for any selected parallel
> writer path. KD-027 defaults to Tech Lead inline writing or one sequential Worker. Parallel
> Workers require disjoint scopes, proven isolation/capture, and sequential integration;
> otherwise the disclosed fallback is one sequential writer. Cheap Scout never writes.

---

## A. Verified OMP Isolation Facts

| Fact | Evidence | Consequence for this template |
|---|---|---|
| `task.isolation.mode` default is `"none"` | `config/settings-schema.ts:4463` | The frozen baseline sets `auto`, so isolation is available — but only because the baseline overrides the default. A project that installs our template without the baseline gets **no isolation**. |
| The `isolated` parameter only exists on the `task` schema when isolation is enabled | `task/index.ts:570` — `isolationEnabled = !planMode && settings.get("task.isolation.mode") !== "none"` | If a user sets `mode: none`, `isolated: true` in a task call is **not a validation error** — the field is silently absent from the schema (arktype `"+": "delete"` strips unknown keys). The Implementer then writes directly to the working tree with no warning. |
| Isolation **requires a git repository** | `task/isolation-runner.ts` — `prepareIsolationContext` calls `getRepoRoot(cwd)`, documented to throw when cwd is not inside a git repo | Isolated implementation **fails outright** in a non-git directory. This is a hard precondition, not a degradation. |
| Plan mode rewrites every spawned agent to a read-only tool set and disables isolation | `task/structured-subagent.ts:159,190-198`; `task/index.ts:568-576` | `write`/`edit`/`bash`, child spawning, prewalk, and isolation controls disappear. A selected mutation or fresh-command contract cannot run honestly in this mode. |
| `task.isolation.apply` default `true` | `config/settings-schema.ts:4499` | Successful isolated changes are auto-applied back to the parent checkout. Isolation is **not** a sandbox for review — it is a staging mechanism that merges on success. |
| `task.isolation.merge` default `patch` | `config/settings-schema.ts:4512` | Merge is "combine diffs and git apply". Conflicting sibling edits fail at apply time, not at write time. |
| `auto` picks a backend, it does not decide *whether* to isolate | `config/settings-schema.ts:4469` — "auto lets the native PAL pick the best available backend" | **This corrects a common misreading.** `auto` is a backend selector (CoW → overlayfs/ProjFS → worktree/rcopy), not a heuristic that decides which agents get isolated. Isolation is requested **per task call** via `isolated: true`. |

### The `auto` misreading, stated plainly

An earlier hypothesis held that `mode: auto` might "decide not to isolate a read-only agent" or "fail to isolate an implementer that doesn't write in a detectable pattern." That is **not** how it works. `auto` never inspects agent behavior. It answers only: *given that this call asked for isolation, which filesystem mechanism should provide it?*

The practical consequence is the inverse of the original concern: isolation is not automatic for writers. **An Implementer spawned without `isolated: true` writes directly to the shared working tree**, regardless of `mode: auto`. Correctness depends on the caller passing the flag, not on the backend.

### Plan-mode contract boundary

Plan mode selects a distinct planning-only contract; selected mutation and fresh-command
contracts stop before dispatch or acceptance. The runtime can otherwise execute a transformed,
read-only worker and still receive a plausible structured yield. `assertPlanControlsAllowed`
rejects explicit isolation controls, but it does not reject a sequential writer or command
executor whose tools were stripped (`task/structured-subagent.ts:201-213`). A transition from a
planning-only result to implementation therefore requires an explicit non-plan contract,
reconciliation against the same task/candidate lineage, and fresh validation before dispatch.

---

## B. Conditional Parallel-Writer Isolation Matrix

When Topic 03 selects a dispatched writer path, isolation is decided per task call using one
question: **does this agent write to disk, and could a sibling be writing concurrently?**
The table preserves the pre-Topic-03 role mapping as a candidate, not a requirement to spawn
those roles.

| Agent | Writes implementation artifacts? | `isolated` | Rationale |
|---|---|---|---|
| `explorer` | No | `false` | Read-only. Isolation would cost a worktree materialization and buy nothing. |
| `verifier` | No (but has `bash`; MUST NOT write implementation artifacts) | `false` | Must observe the **real merged tree** — the state that will actually ship. Isolating the Verifier would verify a copy nobody deploys. The correct reason NOT to isolate is observability, not the absence of write capability: a `bash`-capable Verifier can produce side-effects. Pre/post `git status` checks catch unexpected mutations. |
| `reviewer` | No (but has `bash`; MUST NOT write implementation artifacts) | `false` | Same observability reason as Verifier: reviews the real diff, not a copy. Any unexpected write is a contract violation caught by `git status` diff. |
| `implementer` (single, Standard) | Yes | `false` | Sole writer, nothing to conflict with. Direct writes keep the diff immediately visible to Verifier and to the user. |
| `implementer` (parallel, Orchestrated) | Yes | **`true`** | Concurrent writers **must** be isolated or they corrupt each other's edits. |

### The single-writer exception, and why it is deliberate

Under the prior single-writer candidate, Standard's sole dispatched Implementer runs
**without** isolation. This is a conditional tradeoff, not a requirement for Standard to
dispatch an Implementer:

- **For:** the change lands where the Verifier and the user can see it directly; no patch-apply step can fail; works in non-git directories.
- **Against:** a failed implementation leaves partial edits in the working tree.

The mitigation is that the user's own VCS is the undo mechanism — the template must never claim isolation is a substitute for version control. `RULES.md` already forbids committing without explicit instruction, so a partial edit remains inspectable and revertible by the user.

If a project prefers strict staging for all writes, this is a **one-line policy change** (`isolated: true` in the Standard command's Implementer call), documented in customization. It is a preference, not a correctness fix.

---

## C. Concurrency Limits

| Setting | Baseline value | Meaning |
|---|---|---|
| `task.maxConcurrency` | 4 | Max simultaneous subagents. |
| `task.maxRecursionDepth` | 2 | Max nesting. Main session → worker = depth 1. A worker spawning its own worker = depth 2. |
| `task.batch` | true | Enables the batched `tasks: [...]` form with a shared `context` string. **Precondition only for a selected conditional parallel-batch path — see §C-1.4.** |
| `async.enabled` | **true (OMP default)** | Background task execution. **Every selected worker whose result gates a later stage must defeat this per-agent — see §C-1.** |

---

## C-1. Execution Mode: Stage Barriers Are Not Free (CR-39)

**This is the correctness gap for any selected multi-stage dispatch sequence.** Every arrow
whose next stage consumes a worker result is a barrier. OMP does not provide those barriers
by default, so a future Topic 03 topology must either satisfy this contract or stay inline.

### C-1.1 Verified source behavior

```ts
// task/index.ts:707-715
const itemBlocking = policies.map(policy => policy.effectiveAgent.blocking === true);
const asyncEnabled = this.session.settings.get("async.enabled");
const manager = asyncEnabled ? this.session.asyncJobManager : undefined;
const asyncItems = manager ? spawnItems.filter((_, index) => !itemBlocking[index]) : [];
```

| Fact | Source |
|---|---|
| `async.enabled` defaults to **`true`** | `config/settings-schema.ts:4223-4225` |
| `blocking` is parsed from agent frontmatter, with **no default** | `discovery/helpers.ts:299` — `parseBoolean(frontmatter.blocking)`; absent ⇒ `undefined` |
| Only exact `=== true` is treated as blocking | `task/index.ts:707`, `task/index.ts:165` |
| Non-blocking items become `AsyncJobManager` background jobs | `task/index.ts:715`, and the async branch at `:795+` |
| A background call returns **before** the work finishes | `docs/tools/task.md` — *"Spawned agent `<id>` (job `<jobId>`). The result will be delivered when it yields."*; batch form returns `results: []` |

So a worker agent that does not declare `blocking: true` becomes a background job whose result arrives **later**, as an async injection into the parent conversation. The `task` call itself returns immediately.

### C-1.2 What that does to this template

Every barrier fails in the same way — the parent proceeds on an empty result set. The role
labels below illustrate the non-authoritative pre-Topic-03 candidate; the failure applies to
whatever selected topology supplies the corresponding stage:

| Intended barrier | Actual default behavior |
|---|---|
| selected parallel writers complete → serial integration | `task` returns `results: []`; integration begins with **nothing to integrate** |
| selected verification stage completes → selected review stage | Review runs against an unverified tree |
| selected review stage completes → final report | Report is produced before any review exists |
| selected discovery stages complete → architecture synthesis | Synthesis runs on absent evidence |

Worse, it interacts with two decisions already made:

- **Task-index integration order (§E-10) becomes unimplementable.** That rule anchors on `parallel.ts`'s input-order guarantee, which applies to the **synchronous** fan-out. Background jobs settle independently and deliver on completion, so consuming async results as they arrive is *completion order* — exactly what §E-10 forbids. Implementing index order over async delivery would require an explicit job-collection barrier plus an index map, a protocol this spec does not define and does not need.
- **The capture-first canary (§E-9) cannot work.** A canary that returns before the worker has written anything proves nothing.

### C-1.3 Resolution: `blocking: true` on every selected stage-barrier worker

```yaml
selected_stage_barrier_workers:
  blocking: true                  # frontmatter; parsed by discovery/helpers.ts:299
rationale: stage barriers are a correctness property of this workflow
async_enabled: NOT MODIFIED       # user's global preference, left alone
```

**Do not disable `async.enabled`.** It is a useful OMP capability and a user-global setting; suppressing it to fix a template-local barrier requirement would be the same category error as writing `task.isolation.apply` globally (§E-9). Per-agent `blocking: true` makes this template's orchestration deterministic **regardless** of the user's async preference — the strictly narrower fix.

**`blocking: true` does not serialize a selected batch.** This is the point most likely to be misread, so it is stated normatively: when every item in a selected batch is blocking, `asyncItems` is empty and `task/index.ts:722` takes the **synchronous fan-out** path, which runs the batch under the concurrency semaphore (`#getSpawnSemaphore()`, cap `task.maxConcurrency`) via `mapWithConcurrencyLimit`. Workers still run **concurrently**; the parent waits for the complete set; results arrive in **input order** (`task/parallel.ts:14`). That is precisely the contract §E-10 requires for that optional path:

```
batch of selected blocking writers
  → concurrent execution      (semaphore-bounded, cap 4)
  → parent waits for all      (barrier)
  → merged result in task-index order  (§E-10 anchor holds)
```

### C-1.4 `task.batch` is a conditional parallel-batch path precondition, not an Orchestrated precondition

`task.batch` defaults to `true`, but a user can disable it — and when disabled the model-facing schema reverts to the **flat single-spawn** form (`docs/tools/task.md`: *"Disable to restore the flat single-spawn schema"*). Only the selected parallel-batch implementation path depends on a `tasks[]` array and its stable indices; Orchestrated classification does not. Therefore "default true" is not sufficient grounds to assume batching when that optional path is selected.

```
preflight: effective task.batch == true
  → false: conditional parallel-batch path UNAVAILABLE
           route to a sequential implementation, disclose the setting,
           and retain Orchestrated classification when its structural contract still holds
```

Defining a multi-flat-call aggregation protocol with its own synthetic indices is the alternative and is **rejected for the v0 parallel-batch path**: it reimplements batching in prose, and the stable key would no longer be OMP's own input index, which is the only thing making §E-10 source-anchored. This rejection does not disable sequential Orchestrated execution.

This check joins the other two in the conditional parallel-path preflight. Ordering matters — cheapest and most decisive first:

```
1. nested-repo scan          (§D-1.2)  → any hit disables parallel
2. task.batch == true        (§C-1.4)  → false disables parallel
3. isolation settings        (§E-9)    → diagnostics + canary
4. fan out
```

### Recursion depth constrains any selected topology

Depth 2 limits any topology Topic 03 selects; it does not choose a fixed roster or make a flat
graph part of Orchestrated classification. The diagram below preserves the former candidate as
a capacity example only:

```
depth 0  main session (= Tech Lead)
depth 1  former explorer / implementer / verifier / reviewer candidate
depth 2  reserved headroom
```

Under that former candidate, spawning `tech-lead` as an agent would put workers at depth 2 and
consume the entire budget, leaving a worker unable to delegate even once. A flat graph preserves
headroom. KD-027 selects a flat optional-worker graph; any later nested delegation remains a
separately selected contract and must satisfy the same runtime limit.

Selected nested delegation requires remaining task.maxRecursionDepth; a result from a worker whose
task tool was stripped cannot satisfy that contract. At `childDepth >= task.maxRecursionDepth`,
OMP removes `task` from the effective tool list (`task/executor.ts:2655-2687`) rather than failing
an otherwise sequential child. Preflight therefore computes the deepest selected edge before
dispatch. If insufficient, select/reconcile/revalidate a shallower topology or stop; never accept
a plausible yield from a worker that could not perform its selected delegation responsibility.

### Parallelism rule

Parallelize only genuinely independent work. Two Explorers scoped to *different* modules is legitimate parallelism. Two Explorers asked the same question is duplicated cost with no added information — the anti-pattern the DNA explicitly forbids.

For selected parallel writers, independence means **disjoint file sets**. Because `merge:
patch` resolves conflicts at `git apply` time, two isolated writers editing the same file
produce a late, confusing failure. The orchestrator must partition by file ownership before
fanning out, and state that partition in each task packet's `scope` / `out_of_scope`.

---

## D. Failure Modes

| Failure | Trigger | Detection | Handling |
|---|---|---|---|
| Isolation unavailable — not a git repo | `prepareIsolationContext` throws | Task-tool failure surfaced to caller | Orchestrator MUST fall back to sequential, non-isolated implementation and **say so in the final report**. Never silently proceed as if isolation held. |
| Isolation silently absent — `mode: none` | User config overrides baseline | **Not detectable from the task call** — the field is stripped, not rejected | Validation must assert `task.isolation.mode != none` in effective config (see `13-validation-and-evaluation.md`). This is the highest-value runtime check in the suite. |
| Patch apply conflict | Two isolated writers touched the same file | `git apply` failure at merge | **CR-09 — Batch merge is explicit partial-integration, not atomic:** Prior successful merges remain applied. The orchestrator does NOT rollback successful merges when a later merge conflicts. After merge A succeeds and merge B conflicts, the parent state is B+A, not original base B. Recovery: (1) re-partition work excluding the conflicting file, (2) retry B's scope sequentially on the new base, or (3) report conflict and surface to user. The user's own VCS owns the undo mechanism if full rollback is required. |
| Partial edits from a failed non-isolated writer | A selected writer fails mid-loop | Required verification reports FAIL; working tree dirty | Report the partial state explicitly with the file list. Do not attempt automated cleanup — the user's VCS owns undo. |
| Recursion exhaustion | A worker tries to spawn at depth 2+ | Task tool refuses | Workers other than the orchestrator carry an empty `spawns:`, so this should be unreachable. If it occurs, it indicates a topology regression. |
| **Nested-repo change lost under `apply=false`** | Isolated worker edits a file inside a nested git repo / submodule | **Not detectable — before or after the fact.** The result never reports it and the parent tree looks identical to correct behavior (§D-1, §D-1.1) | **Presence of ANY nested git repo or submodule disables parallel isolated implementation for the repository (CR-32, Option A1).** Orchestrator preflight enumerates before fan-out; a non-empty result routes the whole run to sequential non-isolated implementation. Scope exclusion and post-hoc `git status` are explicitly NOT accepted as enforcement. |

---

### D-1. CR-32 — Nested-repo patches are NOT durable on the successful `apply=false` path

**This is a source-verified gap in OMP v17.2.10, not a template defect.** It constrains what the capture-first architecture can safely cover.

**Verified control flow** (`task/structured-subagent.ts`, `task/isolation-runner.ts`, OMP v17.2.10):

1. `captureDeltaPatch()` produces `{ rootPatch, nestedPatches }`.
2. `writeIsolationPatch()` writes **only** `rootPatch` to a durable artifact file (`<artifactsDir>/<agentId>.patch`). It returns `nestedPatches` as **in-memory `SingleResult` data** — no file is written for them.
3. `persistNestedPatches()` — the only function that materializes nested patches to disk — is called **exclusively** from `isolationRecoveryHint()`.
4. `isolationRecoveryHint()` is reached only via `buildStructuredSubagentRecoveryHint()`, whose call sites (`eval/agent-bridge.ts`) all fire on **failure/abort/apply-failed** paths:
   - `result.exitCode !== 0 || result.error || result.aborted`
   - `policy.isIsolated && changesApplied === false`
   - structured output + `mergeSummary` contains `<system-notification>`
5. On the **successful** `policy.isIsolated && !policy.applyChanges` branch, only a `mergeSummary` string is produced. **`persistNestedPatches()` is never called.**
6. `runIsolatedSubprocess()` tears the isolation handle down in `finally` — the nested working state is gone after the task.
7. `rememberAgentArtifacts()` records `{ outputPath, patchPath, branchName }` in AgentRegistry history — **`nestedPatches` is not recorded.**

**Consequence, stated precisely:** on a *successful* capture-only spawn, nested-repo changes exist only as in-memory result metadata that the model-facing task path never converts to an addressable file. The worktree is then destroyed.

**Worse than a missing artifact — the summary is silent.** The `apply=false` summary branches are `if/else if`:

```
if      (result.branchName)          → "captured on branch ... Not merged."
else if (result.patchPath)           → "captured at <path> ... Not applied."
else if (nestedPatches.length > 0)   → "captured for N nested repositories ... Not applied."
else                                 → "no changes captured."
```

Whenever the root also changed, `result.patchPath` is set, so the **second** branch wins and the nested-repo count is **never mentioned**. A Tech Lead integrating `<agentId>.patch` gets a silently incomplete integration and no signal that anything is missing.

#### D-1.1 Why scope-exclusion is NOT sufficient enforcement (CR-32 round 6)

A previous revision of this section enforced the exclusion by **telling the worker not to
do it** — scope partitioning plus `out_of_scope` in the task packet — and detected
violations by checking nested-repo `git status` after integration. Both halves are
inadequate, and the second is worthless:

**The instruction is not a constraint.** A selected writer may carry `edit`, `write`, and
`bash` inside its workspace. OMP v17.2.10 has **no per-task path write allowlist**: the
task item wire schema is `{name?, agent?, task, effort?, outputSchema?, schemaMode?, isolated?}`
(`task/types.ts`, `docs/tools/task.md`) and carries no path scope. The only built-in
write boundary is agent-level and all-or-nothing — `isReadOnlyAgent()` in
`task/read-only-policy.ts` checks whether the agent's declared `tools:` are a subset of
`READ_ONLY_TOOL_NAMES`; a selected writer with mutation tools fails that test by definition.
So `out_of_scope`
is a behavioral instruction to the same model whose misbehavior it is meant to prevent.

**The post-integration detector has zero discriminating power.** Trace a violating worker:

| Stage | Root repo | Nested repo |
|---|---|---|
| Worker edits | `src/a.ts` changed | `vendor/lib/b.ts` changed |
| OMP captures | durable `<agentId>.patch` | in-memory `nestedPatches` only |
| `apply=false` summary | "captured at `<path>`" | **not mentioned** (`else if` — §D-1) |
| Worktree teardown | — | change destroyed |
| Parent after worker | unchanged | unchanged |
| Parent after integration | changed | **unchanged** |

The final row is *identical* whether the worker correctly left the nested repo alone or
touched it and lost the change. `git submodule status` after integration therefore cannot
distinguish compliance from silent loss. It is not a weak detector; it is not a detector.

An in-worker guard (compare nested repos against spawn baseline before `yield`) is useful
defense-in-depth but is also self-reported by the same model, so it cannot carry a
"nested changes cannot silently disappear" claim either.

#### D-1.2 Resolution adopted — Option A1: nested repos disable parallel isolation

The guarantee must come from **never entering the dangerous runtime path**, not from
worker compliance. That is mechanically enforceable at template level because it is a
decision the orchestrator makes *before* fan-out, using its own tool calls:

```yaml
parallel_isolated_implementer:
  precondition: nested_repo_count == 0
  on_violation:
    parallel_isolated_implementation: DISABLED        # for the whole repository
    route_to: sequential non-isolated implementation  # Standard-style, single writer
    disclose: name the nested repo paths and the reason
  rationale: >
    On the successful apply=false path OMP v17.2.10 neither persists nested patches
    nor reports their existence, and the worktree is torn down. A lost nested change
    is undetectable from the parent afterwards, so the only safe v0 policy is to keep
    the repository off that path entirely.
  enforcement_class: mechanical (orchestrator preflight, pre-dispatch)
  NOT_enforcement:
    - task packet out_of_scope        # instruction, not constraint
    - post-integration git status     # cannot distinguish compliance from loss
```

This is deliberately coarser than the previous rule. The previous rule tried to keep
parallelism available in repositories that merely *contain* a nested repo by fencing the
scope; that trade is unavailable because the failure it guards against is silent. A
repository with any nested repo gets the sequential path — slower, and correct.

**Scope of the check.** The preflight MUST be a **superset** of what OMP's own capture
walks, so the two cannot disagree. OMP enumerates non-submodule nested repos with
`discoverNestedRepos()` (`task/worktree.ts`): it walks from the repo root, skips
`node_modules` and `.git`, treats any directory containing a `.git` entry as a nested
repo, and does not recurse past one once found; tracked submodules are enumerated
separately. The preflight therefore covers both classes:

```bash
# 1. tracked submodules (recursive)
git submodule status --recursive

# 2. non-submodule nested repos, mirroring discoverNestedRepos() semantics:
#    skip node_modules, do not descend past a nested repo
find . -mindepth 2 -name .git -not -path './.git/*' -not -path './node_modules/*' -prune
```

A non-empty result from either command disables parallel isolated implementation.

**Option A2 — path-level write boundary — is technically reachable but NOT adopted for v0.**
GPT's round-6 review concluded that "current OMP task tool does not provide that
path-level write sandbox in the reviewed primitives." That is correct about the *task
tool* and incomplete about *OMP*. Two source facts combine into a real mechanical boundary:

1. `ExtensionToolWrapper` emits a `tool_call` event **before** execution and aborts the
   call when any handler returns `{ block: true }`; a handler that throws also blocks
   (fail-closed) — `extensibility/extensions/wrapper.ts:200-232`, `docs/hooks.md`.
2. Isolated spawns **re-discover** extensions inside the worktree:
   `runIsolatedSubprocess()` passes `preloadedExtensionPaths: undefined`
   (`task/isolation-runner.ts:168`), which routes to full session discovery in `sdk.ts`
   with `cwd` = the isolation dir. Discovery is suppressed only when `restrictToolNames`
   is set (`task/executor.ts:3029`), which for this template's non-plan-mode Orchestrated
   dispatch it is not.

So a `tool_call` hook could deny `write`/`edit`/`bash` targeting nested paths, in-worker,
before the write lands. It is **not adopted for v0** for three reasons: it introduces a
new installed component class (hooks) that the template does not otherwise ship; the
worktree-relative discovery path and the `bash`-argument coverage are unverified in the
target environment; and `docs/hooks.md` states the default runtime now routes `--hook`
through the extension runner, so the exact authoring surface needs confirmation before
the template can depend on it. Recorded as the **lift path**, gated on T-00.E3-G.

**Option B (OMP runtime fix)** — persist every `nestedPatches` entry on the successful
`apply=false` path and surface the artifact paths in the task result — remains the clean
resolution and is out of template scope. T-00.E3-G records observed behavior per OMP
version; if a future version materializes nested artifacts, or Option A2 is verified,
this exclusion can be narrowed from "repository-wide disable" back to "scope exclusion
with a real boundary."

---

## E. Contract Summary

1. Isolation is requested **per task call**, never inferred from `mode`.
2. `mode: auto` selects a *backend*; it never decides *whether* to isolate.
3. Parallel writers MUST set `isolated: true`. **Selected observation roles** MUST NOT isolate when their contract is to judge the real integrated candidate. The former Explorer/Verifier/Reviewer mapping is a non-authoritative Topic 03 candidate, not a fixed roster. The exclusion is based on **assigned responsibility**, not mechanical capability: an observation role may carry `bash` and produce filesystem side effects; it remains non-isolated only because it must inspect the real integrated state, not a copy. Any unexpected mutation is a contract violation, caught by pre/post `git status` checks.
4. Isolation requires git. Absent git, fall back to sequential and disclose it.
5. `apply: true` means isolation stages-then-merges; it is not a review sandbox.
6. Effective-config validation MUST assert `task.isolation.mode != none`, because the silent-absence failure has no runtime signal.
6b. **CR-38 — a subprocess settings read is a diagnostic, not attestation.** `omp config get` cannot see the parent's `--config` overlay or in-session runtime overrides, both of which outrank project config and both of which govern the actual dispatch (`task/structured-subagent.ts:315-317` reads `request.session.settings`). The authority is the same-session capture canary (§E-9.2); the command pair supplies the actionable diagnosis. Neither alone is sufficient.
6c. **CR-39 — every selected stage-barrier worker MUST declare `blocking: true`.** `async.enabled` defaults to `true` (`settings-schema.ts:4223`) and `blocking` has no default (`discovery/helpers.ts:299`), so an undeclared selected worker becomes a background job and its `task` call returns before the work completes — breaking the stage barrier it supplies and making §E-10 task-index order unimplementable on a selected batch path. `blocking: true` does **not** serialize a batch: all-blocking takes the synchronous fan-out path, which keeps concurrency (semaphore, cap 4) and input ordering. Do not modify `async.enabled` (§C-1).
6d. **CR-39 — `task.batch == true` is a conditional parallel-batch path precondition**, checked in that path's preflight rather than assumed from its default; `false` reverts the wire to the flat single-spawn form and disables only the parallel-batch path (§C-1.4), not Orchestrated classification.
7. **CR-09/CR-27/CR-30 — Parallel integration is NOT internally serialized by OMP; `apply=false` is a session/settings control, not a per-task-item field.** `runStructuredSubagent()` calls `mergeIsolatedChanges()` directly from each spawn (verified: `task/structured-subagent.ts`, `task/isolation-runner.ts` in OMP v17.2.10). There is no orchestrator-level merge mutex in that path. Git lock contention can cause one apply to fail, but that is lock *contention*, not safe serialization.

   **Control surface (CR-30 — OMP v17.2.10):** The model-facing task item schema exposes `{name?, agent?, task, effort?, outputSchema?, schemaMode?, isolated?}`. There is **no per-item `apply` field**. Effective apply policy resolves as:
   ```
   applyChanges = request.isolation?.apply
     ?? (invocationKind === "task"
         ? session.settings.get("task.isolation.apply")
         : true)
   ```
   Therefore `apply=false` must be set at the **session/project settings level** (`task.isolation.apply: false`), not inside individual task item dispatches. **Do NOT put `apply: false` inside task item bodies** — that field is not part of the documented model-facing task wire in v17.2.10.

   **Recommended architecture:** Configure `task.isolation.apply: false` at project/session
   settings only when Topic 03 selects the conditional parallel-writer path. Under the
   responsibility-based matrix, only concurrently writing selected tasks use `isolated: true`,
   so the setting exclusively affects those spawns. Selected parallel writers then return
   retained patch/branch artifacts without auto-applying to the parent. The Tech Lead collects
   all artifacts and integrates them one at a time in a deterministic serial coordinator step.
   T-00.E3 must verify the exact settings path and capture-only behavior before parallel
   implementation is attempted.

   If `apply=false` cannot be confirmed via T-00.E3, fall back to sequential (non-parallel) implementation and document the degradation. **Do not claim OMP serializes integration internally** without a source-verified lock primitive.

8. **Isolation settings contract (CR-30):** These settings are project/session level, not per-task-item fields:

   ```yaml
   task:
     isolation:
       apply: false   # capture-only; Tech Lead integrates artifacts serially
       merge: patch   # or branch — T-00.E2 confirms behavior
       mode: auto     # backend selector (CoW/overlayfs/ProjFS/worktree); confirmed by T-00.E3
   ```

   Per-task dispatch: selected parallel writers set `isolated: true`; other selected tasks
   omit it unless their own contract requires isolation.

9. **CR-31 — `apply: false` is a correctness precondition, not a tuning knob; deployment is target-aware.** OMP's default is `task.isolation.apply: true` (`config/settings-schema.ts:4499`). Absence of an explicit setting therefore means every successful isolated worker auto-applies to the parent — exactly the concurrent-integration hazard CR-09/CR-27 removed. The template MUST NOT depend on a setting it does not deploy or verify.

   **Config precedence (OMP v17.2.10):** `defaults < user/global config < project config < CLI overlay < runtime overrides`. Project-local `.omp/config.yml` can therefore establish capture-only behavior without touching global state.

   **Deployment policy by install target:**

   | Target | Destination | Policy |
   |---|---|---|
   | **Project** (`-Target project`) | `<repo>/.omp/config.yml` | Template **owns** `task.isolation.apply: false` and `task.isolation.mode: auto`. Blast radius is one repository — the repository that opted in by installing the template. |
   | **User/global** (`-Target user`) | `~/.omp/agent/config.yml` | Template **MUST NOT** silently write `task.isolation.apply`. Doing so changes behavior for **every isolated task in every repository** on the machine — a change far outside this workflow's scope. Requires an explicit opt-in flag (`-EnableCaptureFirstIsolation`) with a printed warning naming the global blast radius. |

   **Runtime preflight is mandatory regardless of install target.** Installation alone is insufficient: a higher-precedence overlay (CLI, runtime override) can re-enable apply after install. Before any parallel isolated fan-out, `/orchestrated` MUST read the **effective** settings and assert:

   ```
   effective task.isolation.mode  != "none"
   effective task.isolation.apply == false
   ```

   **CR-38 — `omp config get` is a DIAGNOSTIC, not attestation of the running session.** Read §E-9.1 below before treating the command pair as proof. The authoritative check is the same-session canary (§E-9.2). The command pair remains required — it is what produces an actionable *diagnosis* — but it cannot close the gate alone.

   **The read mechanism is concrete and source-verified (CR-31 round 6).** An earlier revision of this section left the settings-read API as an open uncertainty and permitted a user assertion as a fallback proof. Both are now closed. OMP exposes the effective (fully merged) value on the command line:

   ```bash
   omp config get task.isolation.mode  --json
   omp config get task.isolation.apply --json
   ```

   Verified against OMP v17.2.10 `docs/settings.md`:
   - `omp config get <key>` — *"Print the **effective** value of one key. Unknown keys exit non-zero. `--json` emits `{ key, value, type, description }`."* (§"Subcommands")
   - *"Both read merged effective settings."* (§"Reading and writing settings") — `/settings` and `omp config` share the resolution path.
   - Precedence resolved by that read: `built-in defaults < global config < project config < CLI overlays < runtime overrides`.

   The selected-writer contract parses `value` from the JSON and asserts
   `mode != "none"` and `apply == false`. Non-zero exit, unparseable output, or `omp` not
   being on `PATH` is a **preflight failure**, not a pass.

   **A user assertion is NOT a valid proof path.** The reason CR-31 exists is that *file-level intent ≠ effective value* — project config can be overridden by a CLI overlay or runtime override that no file inspection reveals. A user statement about what they configured cannot resolve precedence, so it cannot substitute for the read. If the effective value cannot be obtained, the parallel path is unavailable.

   **CWD is part of the precondition.** OMP loads project settings from `<cwd>/.omp/config.yml` and **does not walk ancestor directories** (`docs/settings.md` §Troubleshooting: *"Settings discovery only checks the current working directory's `.omp/`, not ancestor directories"*). A template installed at `repo/.omp/config.yml` is therefore invisible to a session launched from `repo/packages/foo/`. Consequences:
   - The preflight MUST run with the process cwd at the intended project root — the same directory the install targeted.
   - The effective-value check already catches the mismatch (the key reads as its default `true`), but the **failure report MUST name this root cause explicitly** rather than reporting a generic "apply is true", because the corrective action is different: relaunch from the project root, not edit the config.

   **On preflight failure — do not launch selected parallel isolated writers.** Two permitted
   responses, both of which MUST be disclosed in the final report:
   - fall back to sequential non-isolated implementation (one selected writer, direct writes), or
   - refuse the parallel path and tell the user the exact setting to opt into.

   Silently proceeding with `apply=true` is prohibited: it produces concurrent auto-apply with no serialization guarantee.

   **Rollback consequence:** `task.isolation.apply` and `task.isolation.mode` become installer-owned MERGE keys in the project target. `spec/12 §C` and the manifest `installer_delta` schema must track them alongside `modelRoles` — see `spec/12 §C`.

   T-00.E3 (cases E3-A and E3-H) proves the settings path, the precedence behavior, and the preflight read.

   ### E-9.1 CR-38 — Why a subprocess read is not attestation

   The round-6 preflight has a cross-process gap. What governs the actual dispatch is the **already-running parent session's in-memory `Settings` object**:

   ```ts
   // task/structured-subagent.ts:315-317
   applyChanges:
     request.isolation?.apply ??
     (request.invocationKind === "task"
       ? request.session.settings.get("task.isolation.apply")
       : true),
   // and :314 — mergeMode, :320 — enableLsp: all request.session.settings
   ```

   `omp config get` is a **different process**. It re-resolves settings from scratch, and two layers of the precedence chain are not reconstructible from outside:

   | Divergence source | Why the subprocess misses it | Source |
   |---|---|---|
   | `--config <file>` CLI overlay | *"Loaded after global and project settings, **for that one process**. Never persisted."* A plain `omp config get` has no way to know the parent was launched with it. | `docs/settings.md:21` |
   | In-session runtime override | `Settings.set()` updates the global layer and queues persistence; a project `false` then merges later and still wins. `Settings.override()` writes the non-persistent highest-precedence `#overrides` layer and rebuilds synchronously. | `config/settings.ts:498-526,2143-2147` |

   `PI_CONFIG_FILES` overlays *are* environment-inherited and so would be seen by a child process — but that only narrows the gap, it does not close it. Explicit `--config` and in-session overrides remain invisible.

   **The concrete false pass:**

   ```yaml
   project_config:  task.isolation.apply: false        # <repo>/.omp/config.yml
   parent_launched: omp --config /tmp/override.yml     # where apply: true
   parent_session:  session.settings.get(...) == true  # what dispatch actually reads
   subprocess_read: omp config get ... --json → false  # what the preflight sees
   preflight:       PASS                               # WRONG
   actual:          applyChanges == true → parallel workers auto-apply
   ```

   That is the CR-27 hazard — concurrent unserialized auto-apply — restored through the very check meant to prevent it. Accepting a subprocess read as proof would be a narrower version of the round-5 error: substituting an inspectable artifact for the effective runtime value.

   **Wording is normative.** `omp config get` MUST be described as a *diagnostic precheck*, never as attestation of current session state. It is retained because it is the only thing that can produce an actionable diagnosis — it distinguishes "the project file is wrong", "you launched from the wrong cwd" (§E-9, cwd scoping), and "the persistent layers are fine, so the divergence is an overlay or an in-session override."

   ### E-9.2 CR-38 — The same-session canary is the authority

   Verify capture-first behavior through **the same parent session, the same `task` tool, the same `session.settings`, the same isolation code path** — rather than trying to reconstruct the session's config externally. This is a behavioral test, and behavior is what the gate actually cares about.

   **CR-42 — the canary MUST NOT be able to mutate the parent.** The Round-7 sentinel design
   had the canary create a file and then check whether the file was absent from the parent tree.
   That detection logic is correct in principle, but it is wrong in safety direction: it discovers
   `apply=true` *by letting the apply happen*. When `apply=true`, `runStructuredSubagent()` calls
   `mergeIsolatedChanges({ repoRoot: isolationContext.repoRoot })` unconditionally on a successful
   exit (`task/structured-subagent.ts:600-605`), using the parent's repo root. So the sentinel
   file written by the canary lands in the parent before the preflight can read it. The failure
   detection IS the parent mutation — that is the wrong polarity for a safety gate.

   The fix is to remove direct write capability from the canary. The discrimination relies on
   the merge summary text, which is textually distinct on the two paths (source-verified,
   `structured-subagent.ts:625-632`):

   ```text
   apply=false → merge-summary begins "Isolation: ..."   (semantic class — three variants exist:
                   branch mode:   "Isolation: changes captured on branch `<name>` (apply=false). Not merged."
                   patch mode:    "Isolation: changes captured at `<path>` (apply=false). Not applied."
                   no-artifact:   "Isolation: no changes captured."  ← only if !patchPath && !branchName && !nestedPatches
                 In patch mode a zero-diff isolated run still has result.patchPath set (writeIsolationPatch
                 always creates the file), so the "no changes captured" fallback is NOT the canonical zero-diff text.)
   apply=true, no changes → "No changes to apply."
   ```

   ```yaml
   canary:
     when: after the §D-1.2 nested-repo scan and §C-1.4 batch check pass
     agent:
       name: isolation-canary       # support agent — NOT a workflow worker role (see note below)
       tools: [read]                # declared surface; minimum effective surface includes [read, yield, hub] — see CR-44 note below
       blocking: true               # required: synchronous from coordinator's perspective (§C-1.3)
       isolated: true
     prompt: "Report the current working directory through exactly one terminal yield. Make no changes and call no other tool."
     assert_all:
       - task completed (exit 0)
       - parent git status unchanged  — same HEAD, same working tree as before canary
       - merge-summary begins with "Isolation:"  (apply=false semantic class discriminator)
     on_apply_true_detected:
       - merge-summary does NOT begin with "Isolation:" — indicates apply=true path
       - preflight FAILED — effective apply is true regardless of any persistent config
       - do NOT launch parallel workers
       - report: "Isolation preflight failed: effective apply=true detected.
                  Run `omp config get task.isolation.apply --json` to diagnose.
                  Falling back to sequential non-isolated implementation."
     on_dispatch_error:
       - parallel mode unavailable (covers non-git, backend failure, mode: none)
     cost: one minimal spawn per Orchestrated run
   ```

   **Why the assertions are discriminating** — the two paths produce different, model-visible
   summaries:

   | Effective setting | Parent tree | `<merge-summary>` text |
   |---|---|---|
   | `apply == false` (required) | **unchanged** | begins with `"Isolation: ..."` (semantic class) |
   | `apply == true` (hazard) | unchanged — behavioral guard (see CR-44 note) | `"No changes to apply."` |

   The summary is rendered into the model-facing task result (`prompts/tools/task-summary.md` —
   `<merge-summary>`), not buried in `details`.

   **CR-44 — yield and hub are auto-added to the effective tool surface.**
   `executor.ts:2689-2692` adds
   `hub` to the tool list whenever `!options.restrictToolNames && !toolNames.includes("hub")`.
   For ordinary TaskTool invocations, `structured-subagent.ts:385` resolves
   `restrictToolNames = policy.planMode || session.restrictToolNames === true`, which is `false`
   in a normal Orchestrated workflow. TaskTool also creates every child with
   `requireYieldTool:true` (`executor.ts:3019-3024`), and `tools/index.ts:641-643` plus
   `sdk.ts:2964-2977` force-include the terminal `yield` tool. Therefore `tools: [read]` in
   the canary frontmatter produces a **minimum effective surface containing
   `[read, yield, hub]`**, not `[read]` alone. Unrestricted registered custom/MCP tools may
   widen it further (`sdk.ts:3025-3036`). Phase-00 E3-I must relocate user-profile discovery
   and require the controlled exact `[read, yield, hub]` surface; a production host cannot
   assume that exactness without equivalent discovery isolation.

   OMP documents that `hub` exposes process operations (`start`, `stop`, `restart`) that can
   write files when `launch.enabled=true` (the default). A truly restricted canary — hub absent
   from the effective surface — requires `restrictToolNames=true` at the executor level
   (`ExecutorOptions.restrictToolNames`), which is not accessible via agent frontmatter in the
   current template wire.

   **Consequence: the behavioral canary is a diagnostic/characterization tool, NOT a
   production gate.** A fail-closed control has the form: "authority unavailable or unsafe →
   protected operation does NOT proceed." The behavioral canary has the form: "run an LLM
   child with mandatory yield, hub, and possibly ambient registered tools in its effective
   surface → infer the setting from the result → allow parallel if it looks safe." That is a
   behavioral heuristic, not fail-closed authority.

   **Under `apply=false`, OMP's normal git delta merge is structurally prevented** — no
   `mergeIsolatedChanges` call is made, so the isolated worktree's git-tracked changes cannot
   propagate to the parent via OMP's merge path. **This does NOT sandbox process-level
   side-effects:** a hub-spawned process executing from the isolated context is not restricted
   to OMP's git-tracked paths. Do not claim "the canary cannot affect parent/host state
   regardless of what it does" — that stronger statement requires a real OS-level sandbox.

   **Under `apply=true` detection (the hazard path):** the canary's isolated context IS merged
   before the preflight result can block anything. Hub-spawned content could land in the parent.
   This is precisely why a behavioral heuristic is not safe authority for a gate whose job is
   to prevent the CR-27 concurrent-auto-apply hazard.

   **CR-44 fail-closed contract.** Until a mechanical live-session authority passes Phase-00
   E3-L (see below), parallel capture-first mode is **DISABLED by default**:

   ```yaml
   parallel_orchestrated:
     mechanical_authority_available: false  # until E3-L passes
     parallel_mode: DISABLED
     behavioral_canary:
       authorization_power: NONE
       purpose:
         - characterization (Phase-00 E3-I)
         - diagnostics
         - future-mechanism experiment
     fallback:
       - sequential non-isolated implementation
       - explicit refusal with disclosure
   ```

   The behavioral canary MAY run as part of Phase-00 E3-I or diagnostics, but its PASS MUST
   NOT authorize the production parallel fan-out.

   **E3-L — live-read authority requirement (CR-44 Branch A).** The approved v0 reader is
   `pi.pi.settings.get("task.isolation.apply")` through the public exported settings proxy,
   restricted to the **OMP-owned default main-CLI root-session construction class** on
   pinned v17.2.10. Print mode exercises that construction deterministically; interactive
   text and print presentations receive the same root settings object before their
   presentation-specific loop.

   The same-instance proof is a seven-link conjunction: `index.ts:17` exports `Settings` and
   `settings`; `settings.ts:404-416` assigns and returns the same `globalInstance`;
   `main.ts:1282-1283` initializes the default CLI instance; `main.ts:1533-1545` passes it as
   `sessionOptions.settings`; `sdk.ts:1271-1274` consumes the supplied instance;
   `structured-subagent.ts:315-317` reads the session instance for actual apply behavior; and
   `settings.ts:2371-2388` binds proxy methods to `globalInstance`.

   This is intentionally not universal. ACP `session/new` supplies a `cloneForCwd()` instance
   (`main.ts:397-424`, `settings.ts:603-620`); SDK callers may inject `settings` or
   `settingsManager`; `runRootCommand` may receive injected `deps.settings`; and RPC/RPC-UI
   lifecycles are outside the v0 experiment. Each excluded host requires its own identity
   chain and runtime evidence before support can expand.

   The nominal project custom-tool `ctx.settings` path remains retired: its public type
   advertises the member (`custom-tools/types.ts:85-105`), while the actual project-tool
   bridge omits it (`sdk.ts:885-894,938-955`). The connected-MCP context at
   `session-tools.ts:1295-1314` is a different in-process adapter and does not transmit a live
   JavaScript Settings object to the external MCP server.

   Phase-00 E3-L confirms the proxy in one attempt-atomic joint E3-I/E3-L transaction:

   ```yaml
   L1:
     parent: project apply=false
     reader: false
     child_diagnostic: false
     task_branch: APPLY_FALSE_CAPTURE_ONLY
   L2:
     parent: project apply=false plus CLI overlay apply=true
     reader: true
     child_diagnostic: false
     task_branch: APPLY_TRUE_NO_DIFF
   L3:
     parent: project apply=false plus Settings.override("task.isolation.apply", true)
     reader: true
     child_diagnostic: false
     task_branch: APPLY_TRUE_NO_DIFF
   ```

   L3 MUST use `Settings.override()`. `Settings.set()` updates the global layer and queues
   persistence (`settings.ts:498-505`), and project settings merge after global settings so
   project `false` still wins (`settings.ts:2143-2147`). `Settings.override()` writes the
   non-persistent highest-precedence layer and rebuilds synchronously
   (`settings.ts:518-526`). The fixed reader itself has no mutation, subprocess, arbitrary
   key, or persistence surface.

   E3-I and E3-L independently adjudicate the same selected raw transaction; neither reads
   the other's conclusion. L2 and L3 must show the reader disagreeing with the subprocess
   diagnostic and agreeing with native task behavior. Source proof and runtime observation
   are both mandatory.

   **CR-45 — live read ≠ atomic dispatch guard (TOCTOU).** `Settings` is live-mutable:
   `settings.ts:518-525` shows `override(path, value)` calls `#rebuildMerged()` synchronously
   at any time. Between the preflight live read (t0) and the actual `task` dispatch (t3),
   `Settings` can be mutated by user `/settings` changes, runtime extensions, or future workflow
   code. At t3, `structured-subagent.ts:315-317` reads the live setting again independently.
   A truthful read at t0 does NOT prevent an unsafe value at t3.

   Additionally, `/orchestrated` as a slash command expands to model instructions:
   "call preflight before task" is a workflow instruction, not a mechanical constraint — the
   model can issue `task(...)` without the preflight call.

   **E3-L PASS consequence (CR-45 corrected):**

   ```yaml
   e3_l_pass_consequence:
     live_read_primitive_verified: true   # scoped proxy sees all L1-L3 states
     supported_host: OMP-owned default main-CLI root-session construction class
     behavioral_canary: demoted to diagnostic/regression test
     parallel_mode: DISABLED              # TOCTOU gap — observation ≠ atomic enforcement
     parallel_mode_requires: guarded_dispatch (E3-M or equivalent)
   ```

   **Parallel mode enablement requires an atomic guarded dispatch mechanism** (E3-M — see
   phase-00), NOT merely E3-L. Two **known** candidate classes at the pinned SHA:
   - **Path A**: interceptor at the actual native task dispatch boundary that reads the
     **same live parent `Settings` instance** and blocks before any worker spawn
   - **Path B**: single primitive that reads settings AND dispatches the batch atomically

   Plus an open **equivalence class**: any other source-verified mechanism with equivalent
   atomic / fail-closed semantics is PASS-eligible on its properties, without needing a new
   identifier or being reducible to A or B (`phase-00` → `pass_equivalence_rule`). A/B is
   what has been *found*, not an exhaustive account of what can exist.

   **PASS requires two independent conjunctions, not one.** Settings-instance identity and
   boundary timing are separate and separately unresolved:
   - *identity* — the guard must read the same live parent `Settings` the dispatch reads
   - *timing* — the guard read must occur at the native spawn boundary, with no
     interleavable mutation window before worker allocation (or an invariant spanning it)

   Until one mechanism is source-verified on **both** conjunctions AND Phase-00 confirms it
   against the gating cases (`phases/phase-00-foundation.md` — M1, M2, M2b, M4, with M2
   attacking the guard-read→spawn interval), parallel mode stays DISABLED.

   **The ordinary `tool_call` hook is pre-scheduling, not the spawn boundary.** Verified at
   `3a8591a`: for a loop-dispatched call the event is emitted at arg-prep time — documented
   "before concurrency scheduling, `tool_execution_start`, and the wrapper's approval gate"
   (`session/agent-session.ts:3179-3187`) — and the dispatch is marked so the wrapper does
   **not** re-emit at execute time (`extensions/wrapper.ts:183` consumes the marker;
   `:205` emits only when the loop did not). Blocking ability is therefore weaker than
   atomic coupling: between such a guard's read and worker spawn lie message completion,
   scheduling, an approval gate that may await UI, `TaskTool.execute`'s `await Promise.all`
   over per-item preflight (`task/index.ts:664-689`), and `await discoverAgents(...)`
   (`task/structured-subagent.ts:245-255`) — only after which the native policy reads
   `task.isolation.apply` (`:315-317`). `Settings.override()` can run in that interval.
   A re-registered `task` tool that reads settings and then calls `ctx.invokeTool` inherits
   the same gap. Binding the safe value into the call would close it, but no public argument
   carries it: `task/types.ts` exposes only `isolated?: boolean` and `task/index.ts:643`/`:1418`
   populate `isolation: { requested: params.isolated }` only, leaving `apply` undefined so the
   settings read always wins.

   **The "path C" label is withdrawn.** An earlier revision of this section listed "Path C:
   setting locked/forced for the duration of the guarded dispatch" as a third pass-eligible
   option, while `phases/phase-00-foundation.md` used the same label for a *behavioral
   disclosure* that is explicitly non-PASS. One label cannot mean both a candidate mechanical
   guard and a non-guard. The label is therefore retired — but note precisely what that does
   and does not assert:

   1. **No built-in public lock primitive was FOUND at the pinned SHA.** `Settings.override()`
      (`config/settings.ts:518-528`) applies the override and calls `#rebuildMerged()`
      unconditionally — no lock, freeze, or read-only check on the mutation path. The
      `readOnly` option sets `#persist` (`settings.ts:384`), which gates only *file writes*
      (`settings.ts:1958`, `:1980`, `:2070`), never in-memory mutation.
      `built_in_public_lock_primitive_found: false`.
   2. **That is NOT a claim of universal unimplementability.** An earlier revision said a
      locked/forced setting "cannot be implemented against the pinned runtime" and that any
      future lock is "path A or path B by definition". Both were stronger than the evidence:
      inspecting `Settings.override()` cannot exclude every extension composition, host
      wrapper, patched runtime, or equivalent invariant. A lock or invariant held from safety
      observation through spawn is conceptually equivalent fail-closed enforcement without
      being identical to a boundary interceptor (A) or a single read-and-dispatch primitive
      (B). Such a mechanism is **admissible** under the equivalence class above, judged on
      its properties. Retiring the label removes a naming collision; it does not close the
      mechanism space.

   Behavioral disclosure ("assume no Settings mutation during execution") is retained
   **only** on the explicit non-PASS list in `phases/phase-00-foundation.md`.

   **Post-dispatch detection is not an option.** A worker-side settings fingerprint checked
   as the worker's first action is `defense_in_depth` only: the isolated worker has already
   been spawned, and the check is a model-directed action the worker can skip. Documenting
   the residual window does not convert it into a pre-spawn guard. It can never pass E3-M.

   **Source-authority gap (verified at v17.2.10 `3a8591a`).** The blocking capability and
   the live-settings capability sit on *different* public contexts. **Three** of four
   candidate surfaces are closed: `ExtensionContext`
   (`extensibility/extensions/types.ts:415-483`, no `settings` field);
   `ReadonlySessionManager` (`session/session-manager.ts:327-350`, a 21-member `Pick` with
   no settings accessor); and a re-registered built-in via `invokeTool`
   (`types.ts:479-482`, but `ToolDefinition.execute` at `types.ts:576-582` also receives
   `ExtensionContext`). `CustomToolContext` nominally declares `settings?: Settings`
   (`extensibility/custom-tools/types.ts:98-99`), but the project-tool bridge omits it
   (`sdk.ts:885-894,938-955`); even a future corrected context would have no task-dispatch
   member, so a custom tool would not itself be the dispatch boundary.

   **The fourth surface is UNRESOLVED, not closed.** The package publicly exports the global
   `settings` Proxy (`index.ts:17`; `config/settings.ts:2371`). An earlier revision of this
   section recorded it as closed on the strength of `cloneForCwd` (`settings.ts:603-620`) —
   that was an overreach. `cloneForCwd` proves the proxy is **not universally** the dispatch
   instance; it does not disprove identity on the default main-CLI path, where
   `Settings.init()` assigns and returns the same object (`settings.ts:404-416`), `main.ts`
   binds it via `sessionOptions.settings = settingsInstance` (`main.ts:1282-1283`, `:1545`),
   and dispatch reads `request.session.settings.get(...)`
   (`task/structured-subagent.ts:314-317`). Identity is therefore **host-scoped**: plausible
   on default main CLI, definitely different under ACP (`main.ts:399` clones) or injected
   SDK settings (`sdk.ts:1271-1272`) or injected `deps.settings` (`main.ts:1282`).

   Consequence: path-A feasibility is **UNRESOLVED and must be settled empirically**, not by
   inference in either direction. E3-M remains **NOT_ATTEMPTED** and parallel mode stays
   **DISABLED** — the fail-closed posture is unchanged, but the reason is "untested and
   host-scoped candidate", not "no candidate exists". Full determination requirements in
   `phases/phase-00-foundation.md` E3-M `global_proxy_candidate.required_determination`.

   **Agent taxonomy note.** `isolation-canary` is an **internal preflight support agent**, not a
   selected workflow worker. The Topic 03 manifest defines the worker set and count. When
   validation compares discovered project workers with that manifest, support agents are excluded from the selected worker-set comparison;
   no fixed role name or count is inferred.

   **The canary depends on CR-39.** It must be synchronous from the coordinator's perspective.
   `blocking: true` on the canary is required (§C-1.3). CR-38 and CR-39 remain a single fix.

   **What the canary does not prove.** It attests `apply` and that isolation engaged, at canary
   time, for a single spawn. It is a behavioral guard (not a mechanical sandbox). It does not
   prove the setting cannot change mid-run, and it is not a substitute for the nested-repo gate
   (§D-1.2) — a nested repo is undetectable by *any* behavioral probe, which is exactly why
   that gate is structural. The canary's PASS does NOT authorize parallel fan-out in v0 (see
   fail-closed contract above).

   Full preflight sequence (v0 — parallel disabled; E3-L must prove the scoped proxy read;
   E3-M gates enable):

   ```
   1. nested-repo scan             (§D-1.2)   structural   → any hit disables parallel
   2. effective task.batch         (§C-1.4)   diagnostic   → false disables parallel
   3. omp config get × 2           (§E-9)     diagnostic   → produces the actionable message
   4. parallel mode:               DISABLED until E3-M (guarded dispatch) passes
       └─ fallback: sequential non-isolated + disclosure
   5. [experiment] E3-L            scoped proxy read → live_read_primitive_verified
   6. [diagnostic] behavioral canary (§E-9.2) → characterization only, does NOT gate
   ```

   Steps 3, 5, 6 are retained as diagnostics and experiments. None gates the production
   parallel decision in v0. Step 4 is the fail-closed v0 state.

10. **CR-29 — Integration order is normative: original orchestrator task-list index.** "Deterministic order" is not a specification — alphabetical name, worker finish order, batch input order, and file-path order all satisfy the English word while producing different conflict and recovery behavior. The rule is fixed:

    ```yaml
    integration_order:
      source: original_orchestrator_task_list
      stable_key: task_index          # position in the tasks[] array as dispatched
      worker_completion_order: ignored
    ```

    **Why task index, source-supported:** OMP's batch fan-out preserves per-item indices and returns results in input order — `task/parallel.ts:14` states *"Results are returned in the same order as input items"*, and both worker loops assign `results[index] = ...` against the original array position. The ordering anchor therefore already exists in the result payload; no additional bookkeeping is required, and the order is independent of worker timing.

    **No topological logic is needed.** If two work units have a real dependency, they were not independent and MUST NOT have been parallelized in the first place (see §C parallelism rule). Dependency ordering is a partitioning decision made *before* fan-out, not an integration-time resolution.

    **Conflict semantics during serial integration:**

    ```
    integrate artifact[0] … artifact[n] in ascending task_index

    on conflict at artifact[i]:
      - STOP: do not attempt artifact[i+1 …]
      - PRESERVE: every unapplied artifact remains on disk and addressable
      - REPORT: parent state = base + artifact[0 … i-1], name the conflicting artifact
                and every unapplied artifact path
      - required verification does NOT run on a partially integrated tree
    ```

    Recovery is the user's or Tech Lead's explicit next decision (re-partition, retry the conflicting scope on the new base, or escalate) — never an automatic rollback of already-integrated artifacts, because OMP provides no atomic batch-merge primitive (see §D partial-integration row).

    T-00.E3 cases E3-E and E3-F prove ordering independence from completion order and the stop-preserve-report conflict path.

---

## G. Topic 06 managed execution modes

The managed wrapper accepts blocking single dispatch and bounded native batch dispatch. Every
batch item is a complete independent Topic 04 work-unit packet; batch order never grants shared
authority. Managed v1 rejects async and nested-agent requests. A nested requirement must be
repartitioned by the Tech Lead into top-level work units.

Plan mode is planning-only. It cannot satisfy a selected mutation or fresh-command contract after
OMP strips write/bash capabilities. Isolation intent is validated against the work unit and
effective runtime, but Topic 06 neither creates worktrees nor merges artifacts. When a selected
mode cannot run safely, the Tech Lead selects a different validated contract or works inline; no
receipt is fabricated.
