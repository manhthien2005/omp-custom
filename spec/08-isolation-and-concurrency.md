# 08 — Isolation and Concurrency

> OPUS PROPOSED SPEC v1 | All claims verified against OMP source in `_research/upstreams/oh-my-pi`.

---

## A. Verified OMP Isolation Facts

| Fact | Evidence | Consequence for this template |
|---|---|---|
| `task.isolation.mode` default is `"none"` | `config/settings-schema.ts:4463` | The frozen baseline sets `auto`, so isolation is available — but only because the baseline overrides the default. A project that installs our template without the baseline gets **no isolation**. |
| The `isolated` parameter only exists on the `task` schema when isolation is enabled | `task/index.ts:570` — `isolationEnabled = !planMode && settings.get("task.isolation.mode") !== "none"` | If a user sets `mode: none`, `isolated: true` in a task call is **not a validation error** — the field is silently absent from the schema (arktype `"+": "delete"` strips unknown keys). The Implementer then writes directly to the working tree with no warning. |
| Isolation **requires a git repository** | `task/isolation-runner.ts` — `prepareIsolationContext` calls `getRepoRoot(cwd)`, documented to throw when cwd is not inside a git repo | Isolated implementation **fails outright** in a non-git directory. This is a hard precondition, not a degradation. |
| Plan mode disables isolation | `task/index.ts:570` — `!planMode &&` | Under plan mode the `isolated` field disappears from the schema. Do not rely on isolation while planning. |
| `task.isolation.apply` default `true` | `config/settings-schema.ts:4499` | Successful isolated changes are auto-applied back to the parent checkout. Isolation is **not** a sandbox for review — it is a staging mechanism that merges on success. |
| `task.isolation.merge` default `patch` | `config/settings-schema.ts:4512` | Merge is "combine diffs and git apply". Conflicting sibling edits fail at apply time, not at write time. |
| `auto` picks a backend, it does not decide *whether* to isolate | `config/settings-schema.ts:4469` — "auto lets the native PAL pick the best available backend" | **This corrects a common misreading.** `auto` is a backend selector (CoW → overlayfs/ProjFS → worktree/rcopy), not a heuristic that decides which agents get isolated. Isolation is requested **per task call** via `isolated: true`. |

### The `auto` misreading, stated plainly

An earlier hypothesis held that `mode: auto` might "decide not to isolate a read-only agent" or "fail to isolate an implementer that doesn't write in a detectable pattern." That is **not** how it works. `auto` never inspects agent behavior. It answers only: *given that this call asked for isolation, which filesystem mechanism should provide it?*

The practical consequence is the inverse of the original concern: isolation is not automatic for writers. **An Implementer spawned without `isolated: true` writes directly to the shared working tree**, regardless of `mode: auto`. Correctness depends on the caller passing the flag, not on the backend.

---

## B. Isolation Decision Matrix

Isolation is decided per task call by the orchestrator, using one question: **does this agent write to disk, and could a sibling be writing concurrently?**

| Agent | Writes implementation artifacts? | `isolated` | Rationale |
|---|---|---|---|
| `explorer` | No | `false` | Read-only. Isolation would cost a worktree materialization and buy nothing. |
| `verifier` | No (but has `bash`; MUST NOT write implementation artifacts) | `false` | Must observe the **real merged tree** — the state that will actually ship. Isolating the Verifier would verify a copy nobody deploys. The correct reason NOT to isolate is observability, not the absence of write capability: a `bash`-capable Verifier can produce side-effects. Pre/post `git status` checks catch unexpected mutations. |
| `reviewer` | No (but has `bash`; MUST NOT write implementation artifacts) | `false` | Same observability reason as Verifier: reviews the real diff, not a copy. Any unexpected write is a contract violation caught by `git status` diff. |
| `implementer` (single, Standard) | Yes | `false` | Sole writer, nothing to conflict with. Direct writes keep the diff immediately visible to Verifier and to the user. |
| `implementer` (parallel, Orchestrated) | Yes | **`true`** | Concurrent writers **must** be isolated or they corrupt each other's edits. |

### The single-writer exception, and why it is deliberate

In Standard workflow the lone Implementer runs **without** isolation. This is a considered tradeoff, not an oversight:

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
| `task.batch` | true | Enables the batched `tasks: [...]` form with a shared `context` string. **Orchestrated precondition — see §C-1.4.** |
| `async.enabled` | **true (OMP default)** | Background task execution. **Every stage barrier in this template depends on defeating this per-agent — see §C-1.** |

---

## C-1. Execution Mode: Stage Barriers Are Not Free (CR-39)

**This is the correctness gap that every workflow sequence in this spec silently assumed away.** `04-workflow-sizing.md` writes Standard and Orchestrated as ordered stages — explore *then* plan, implement *then* integrate, verify *then* review, review *then* report. Those arrows are barriers: each stage consumes the previous stage's completed result. OMP does not provide them by default.

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

Every barrier fails in the same way — the parent proceeds on an empty result set:

| Intended barrier | Actual default behavior |
|---|---|
| parallel Implementers complete → serial integration | `task` returns `results: []`; integration begins with **nothing to integrate** |
| Verifier completes → Reviewer dispatched | Reviewer runs against an unverified tree |
| Reviewer completes → final report | Report is produced before any review exists |
| Explorers complete → architecture synthesis | Synthesis runs on absent evidence |

Worse, it interacts with two decisions already made:

- **Task-index integration order (§E-10) becomes unimplementable.** That rule anchors on `parallel.ts`'s input-order guarantee, which applies to the **synchronous** fan-out. Background jobs settle independently and deliver on completion, so consuming async results as they arrive is *completion order* — exactly what §E-10 forbids. Implementing index order over async delivery would require an explicit job-collection barrier plus an index map, a protocol this spec does not define and does not need.
- **The capture-first canary (§E-9) cannot work.** A canary that returns before the worker has written anything proves nothing.

### C-1.3 Resolution: `blocking: true` on every worker agent

```yaml
worker_agents:                    # all four
  blocking: true                  # frontmatter; parsed by discovery/helpers.ts:299
rationale: stage barriers are a correctness property of this workflow
async_enabled: NOT MODIFIED       # user's global preference, left alone
```

**Do not disable `async.enabled`.** It is a useful OMP capability and a user-global setting; suppressing it to fix a template-local barrier requirement would be the same category error as writing `task.isolation.apply` globally (§E-9). Per-agent `blocking: true` makes this template's orchestration deterministic **regardless** of the user's async preference — the strictly narrower fix.

**`blocking: true` does not serialize the batch.** This is the point most likely to be misread, so it is stated normatively: when every item in a batch is blocking, `asyncItems` is empty and `task/index.ts:722` takes the **synchronous fan-out** path, which runs the batch under the concurrency semaphore (`#getSpawnSemaphore()`, cap `task.maxConcurrency`) via `mapWithConcurrencyLimit`. Workers still run **concurrently**; the parent waits for the complete set; results arrive in **input order** (`task/parallel.ts:14`). That is precisely the contract §E-10 requires:

```
batch of blocking Implementers
  → concurrent execution      (semaphore-bounded, cap 4)
  → parent waits for all      (barrier)
  → merged result in task-index order  (§E-10 anchor holds)
```

### C-1.4 `task.batch` is an Orchestrated precondition, not an assumption

`task.batch` defaults to `true`, but a user can disable it — and when disabled the model-facing schema reverts to the **flat single-spawn** form (`docs/tools/task.md`: *"Disable to restore the flat single-spawn schema"*). The Orchestrated contract depends on a `tasks[]` array and its stable indices, so "default true" is not sufficient grounds to assume it.

```
preflight: effective task.batch == true
  → false: parallel Orchestrated path UNAVAILABLE
           route to sequential non-isolated implementation, disclose the setting
```

Defining a multi-flat-call aggregation protocol with its own synthetic indices is the alternative and is **rejected for v0**: it reimplements batching in prose, and the stable key would no longer be OMP's own input index, which is the only thing making §E-10 source-anchored.

This check joins the other two in the Orchestrated preflight. Ordering matters — cheapest and most decisive first:

```
1. nested-repo scan          (§D-1.2)  → any hit disables parallel
2. task.batch == true        (§C-1.4)  → false disables parallel
3. isolation settings        (§E-9)    → diagnostics + canary
4. fan out
```

### Recursion depth governs the topology

Depth 2 is what makes the flat topology in `03-agent-topology.md` mandatory rather than merely preferable:

```
depth 0  main session (= Tech Lead)
depth 1  explorer / implementer / verifier / reviewer     ← all workers live here
depth 2  reserved headroom
```

Had we spawned `tech-lead` as an agent, workers would sit at depth 2 and consume the entire budget, leaving a worker unable to delegate even once. The flat topology keeps a full level in reserve.

### Parallelism rule

Parallelize only genuinely independent work. Two Explorers scoped to *different* modules is legitimate parallelism. Two Explorers asked the same question is duplicated cost with no added information — the anti-pattern the DNA explicitly forbids.

For parallel Implementers, independence means **disjoint file sets**. Because `merge: patch` resolves conflicts at `git apply` time, two isolated Implementers editing the same file produce a late, confusing failure. The orchestrator must partition by file ownership before fanning out, and state that partition in each task packet's `scope` / `out_of_scope`.

---

## D. Failure Modes

| Failure | Trigger | Detection | Handling |
|---|---|---|---|
| Isolation unavailable — not a git repo | `prepareIsolationContext` throws | Task-tool failure surfaced to caller | Orchestrator MUST fall back to sequential, non-isolated implementation and **say so in the final report**. Never silently proceed as if isolation held. |
| Isolation silently absent — `mode: none` | User config overrides baseline | **Not detectable from the task call** — the field is stripped, not rejected | Validation must assert `task.isolation.mode != none` in effective config (see `13-validation-and-evaluation.md`). This is the highest-value runtime check in the suite. |
| Patch apply conflict | Two isolated Implementers touched the same file | `git apply` failure at merge | **CR-09 — Batch merge is explicit partial-integration, not atomic:** Prior successful merges remain applied. The orchestrator does NOT rollback successful merges when a later merge conflicts. After merge A succeeds and merge B conflicts, the parent state is B+A, not original base B. Recovery: (1) re-partition work excluding the conflicting file, (2) retry B's scope sequentially on the new base, or (3) report conflict and surface to user. The user's own VCS owns the undo mechanism if full rollback is required. |
| Partial edits from a failed non-isolated Implementer | Implementer fails mid-loop in Standard | Verifier reports FAIL; working tree dirty | Report the partial state explicitly with the file list. Do not attempt automated cleanup — the user's VCS owns undo. |
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

**The instruction is not a constraint.** The Implementer carries `edit`, `write`, and
`bash` inside its workspace. OMP v17.2.10 has **no per-task path write allowlist**: the
task item wire schema is `{name?, agent?, task, effort?, outputSchema?, schemaMode?, isolated?}`
(`task/types.ts`, `docs/tools/task.md`) and carries no path scope. The only built-in
write boundary is agent-level and all-or-nothing — `isReadOnlyAgent()` in
`task/read-only-policy.ts` checks whether the agent's declared `tools:` are a subset of
`READ_ONLY_TOOL_NAMES`; an Implementer fails that test by definition. So `out_of_scope`
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
3. Parallel writers MUST set `isolated: true`. **Observation-phase agents** (Explorer, Verifier, Reviewer) MUST NOT isolate — they must observe the real merged parent state. The exclusion is based on **assigned responsibility**, not mechanical capability: Verifier and Reviewer carry `bash` and can produce filesystem side effects; they are not isolated because they must inspect the real integrated state, not a copy. Any unexpected mutation is a contract violation, caught by pre/post `git status` checks.
4. Isolation requires git. Absent git, fall back to sequential and disclose it.
5. `apply: true` means isolation stages-then-merges; it is not a review sandbox.
6. Effective-config validation MUST assert `task.isolation.mode != none`, because the silent-absence failure has no runtime signal.
6b. **CR-38 — a subprocess settings read is a diagnostic, not attestation.** `omp config get` cannot see the parent's `--config` overlay or in-session runtime overrides, both of which outrank project config and both of which govern the actual dispatch (`task/structured-subagent.ts:315-317` reads `request.session.settings`). The authority is the same-session capture canary (§E-9.2); the command pair supplies the actionable diagnosis. Neither alone is sufficient.
6c. **CR-39 — every worker agent MUST declare `blocking: true`.** `async.enabled` defaults to `true` (`settings-schema.ts:4223`) and `blocking` has no default (`discovery/helpers.ts:299`), so an undeclared worker becomes a background job and its `task` call returns before the work completes — breaking every stage barrier in `04-workflow-sizing.md` and making the §E-10 task-index order unimplementable. `blocking: true` does **not** serialize a batch: all-blocking takes the synchronous fan-out path, which keeps concurrency (semaphore, cap 4) and input ordering. Do not modify `async.enabled` (§C-1).
6d. **CR-39 — `task.batch == true` is an Orchestrated precondition**, checked in preflight rather than assumed from its default; `false` reverts the wire to the flat single-spawn form and disables the parallel path (§C-1.4).
7. **CR-09/CR-27/CR-30 — Parallel integration is NOT internally serialized by OMP; `apply=false` is a session/settings control, not a per-task-item field.** `runStructuredSubagent()` calls `mergeIsolatedChanges()` directly from each spawn (verified: `task/structured-subagent.ts`, `task/isolation-runner.ts` in OMP v17.2.10). There is no orchestrator-level merge mutex in that path. Git lock contention can cause one apply to fail, but that is lock *contention*, not safe serialization.

   **Control surface (CR-30 — OMP v17.2.10):** The model-facing task item schema exposes `{name?, agent?, task, effort?, outputSchema?, schemaMode?, isolated?}`. There is **no per-item `apply` field**. Effective apply policy resolves as:
   ```
   applyChanges = request.isolation?.apply
     ?? (invocationKind === "task"
         ? session.settings.get("task.isolation.apply")
         : true)
   ```
   Therefore `apply=false` must be set at the **session/project settings level** (`task.isolation.apply: false`), not inside individual task item dispatches. **Do NOT put `apply: false` inside task item bodies** — that field is not part of the documented model-facing task wire in v17.2.10.

   **Recommended architecture:** Configure `task.isolation.apply: false` at project/session settings. Under this template's isolation matrix (only parallel Implementers use `isolated: true`), that setting is coherent — it exclusively affects isolated spawns. Parallel Implementers then return retained patch/branch artifacts without auto-applying to the parent. The Tech Lead collects all artifacts and integrates them one at a time in a deterministic serial coordinator step. T-00.E3 must verify the exact settings path and capture-only behavior before parallel implementation is attempted.

   If `apply=false` cannot be confirmed via T-00.E3, fall back to sequential (non-parallel) implementation and document the degradation. **Do not claim OMP serializes integration internally** without a source-verified lock primitive.

8. **Isolation settings contract (CR-30):** These settings are project/session level, not per-task-item fields:

   ```yaml
   task:
     isolation:
       apply: false   # capture-only; Tech Lead integrates artifacts serially
       merge: patch   # or branch — T-00.E2 confirms behavior
       mode: auto     # backend selector (CoW/overlayfs/ProjFS/worktree); confirmed by T-00.E3
   ```

   Per-task dispatch: parallel Implementers set `isolated: true`; all other agents omit `isolated` (defaults to non-isolated).

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

   The Implementer-facing contract: parse `value` from the JSON, assert `mode != "none"` and `apply == false`. Non-zero exit, unparseable output, or `omp` not being on `PATH` is a **preflight failure**, not a pass.

   **A user assertion is NOT a valid proof path.** The reason CR-31 exists is that *file-level intent ≠ effective value* — project config can be overridden by a CLI overlay or runtime override that no file inspection reveals. A user statement about what they configured cannot resolve precedence, so it cannot substitute for the read. If the effective value cannot be obtained, the parallel path is unavailable.

   **CWD is part of the precondition.** OMP loads project settings from `<cwd>/.omp/config.yml` and **does not walk ancestor directories** (`docs/settings.md` §Troubleshooting: *"Settings discovery only checks the current working directory's `.omp/`, not ancestor directories"*). A template installed at `repo/.omp/config.yml` is therefore invisible to a session launched from `repo/packages/foo/`. Consequences:
   - The preflight MUST run with the process cwd at the intended project root — the same directory the install targeted.
   - The effective-value check already catches the mismatch (the key reads as its default `true`), but the **failure report MUST name this root cause explicitly** rather than reporting a generic "apply is true", because the corrective action is different: relaunch from the project root, not edit the config.

   **On preflight failure — do not launch parallel isolated Implementers.** Two permitted responses, both of which MUST be disclosed in the final report:
   - fall back to sequential non-isolated implementation (single Implementer, direct writes), or
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
   | In-session runtime override | `Settings.set()` writes to the in-memory `#overrides` layer (`config/settings.ts:524`), the **highest** precedence tier. A `/settings` change during the session never touches any file. | `config/settings.ts:343,524` |

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
       tools: [read]                # declared surface; effective surface is [read, hub] — see CR-44 note below
       blocking: true               # required: synchronous from coordinator's perspective (§C-1.3)
       isolated: true
     prompt: "Report the current working directory. Make no changes. Yield immediately."
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

   **CR-44 — hub is auto-added to the effective tool surface.** `executor.ts:2689-2692` adds
   `hub` to the tool list whenever `!options.restrictToolNames && !toolNames.includes("hub")`.
   For ordinary TaskTool invocations, `structured-subagent.ts:385` resolves
   `restrictToolNames = policy.planMode || session.restrictToolNames === true`, which is `false`
   in a normal Orchestrated workflow. Therefore `tools: [read]` in the canary frontmatter
   produces an **effective surface of `[read, hub]`**, not `[read]` alone.

   OMP documents that `hub` exposes process operations (`start`, `stop`, `restart`) that can
   write files when `launch.enabled=true` (the default). A truly restricted canary — hub absent
   from the effective surface — requires `restrictToolNames=true` at the executor level
   (`ExecutorOptions.restrictToolNames`), which is not accessible via agent frontmatter in the
   current template wire.

   **Consequence: the behavioral canary is a diagnostic/characterization tool, NOT a
   production gate.** A fail-closed control has the form: "authority unavailable or unsafe →
   protected operation does NOT proceed." The behavioral canary has the form: "run an LLM
   child with hub in its effective surface → infer the setting from the result → allow parallel
   if it looks safe." That is a behavioral heuristic, not fail-closed authority.

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

   **E3-L — source-verified mechanical authority path (CR-44 Branch A).** A project custom
   preflight tool can read the live parent-session `task.isolation.apply` directly:

   ```text
   session-tools.ts:1295-1307 — getCustomToolContext() sets:
       settings: this.#host.settings   // live parent-session Settings instance
   custom-tools/types.ts:99:
       settings?: Settings   // "Prefer over the global singleton"
   ```

   `this.#host.settings` is the same `Settings` instance that `structured-subagent.ts:315-317`
   reads when determining `applyChanges`. CLI `--config` overlays and in-session
   `Settings.set()` overrides are ALL visible — this is not a subprocess snapshot. A custom
   tool calling `ctx.settings.get("task.isolation.apply")` reads the true effective value.

   Phase-00 E3-L must confirm empirically that the end-to-end path works as expected (value
   correct under project config, `--config` overlay, and in-session override). After E3-L
   PASS, the preflight replaces the behavioral canary with a custom-tool settings read:

   ```yaml
   e3_l_pass_consequence:
     preflight_mechanism: ctx.settings.get("task.isolation.apply")  # mechanical
     behavioral_canary: demoted to diagnostic/regression test
     parallel_mode: ENABLED with mechanical authority
   ```

   **Agent taxonomy note.** `isolation-canary` is an **internal preflight support agent**, not a
   workflow worker role. The four-worker constraint (CR-33: explorer, implementer, verifier,
   reviewer) counts *workflow reasoning roles*, not support/preflight agents. Validation MUST NOT
   collapse "number of discovered agent files" into "number of workflow worker roles" — the
   canary agent file, if present, must be excluded from that count.

   **The canary depends on CR-39.** It must be synchronous from the coordinator's perspective.
   `blocking: true` on the canary is required (§C-1.3). CR-38 and CR-39 remain a single fix.

   **What the canary does not prove.** It attests `apply` and that isolation engaged, at canary
   time, for a single spawn. It is a behavioral guard (not a mechanical sandbox). It does not
   prove the setting cannot change mid-run, and it is not a substitute for the nested-repo gate
   (§D-1.2) — a nested repo is undetectable by *any* behavioral probe, which is exactly why
   that gate is structural. The canary's PASS does NOT authorize parallel fan-out in v0 (see
   fail-closed contract above).

   Full preflight sequence (v0 — before E3-L mechanical authority):

   ```
   1. nested-repo scan             (§D-1.2)   structural   → any hit disables parallel
   2. effective task.batch         (§C-1.4)   diagnostic   → false disables parallel
   3. omp config get × 2           (§E-9)     diagnostic   → produces the actionable message
   4. mechanical live-session      (E3-L)     AUTHORITY    → gates parallel fan-out
      authority available?
       └─ NO  → parallel DISABLED → sequential non-isolated + disclosure
       └─ YES → verify apply=false via ctx.settings
                → fan out
   5. [diagnostic] behavioral canary (§E-9.2) → characterization only, does NOT gate
   ```

   Steps 3 and 5 are retained as diagnostics: step 3 explains *why* to the user when the
   setting is wrong; step 5 (E3-I) characterizes the canary mechanism for future use. Neither
   gates the production decision in v0.

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
      - Verifier does NOT run on a partially integrated tree
    ```

    Recovery is the user's or Tech Lead's explicit next decision (re-partition, retry the conflicting scope on the new base, or escalate) — never an automatic rollback of already-integrated artifacts, because OMP provides no atomic batch-merge primitive (see §D partial-integration row).

    T-00.E3 cases E3-E and E3-F prove ordering independence from completion order and the stop-preserve-report conflict path.
