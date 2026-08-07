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
| `task.batch` | true | Enables the batched `tasks: [...]` form with a shared `context` string. |

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
| **Nested-repo change lost under `apply=false`** | Isolated worker edits a file inside a nested git repo / submodule | **Not detectable from the task result** — see §D-1 below | **Parallel isolated Implementers MUST NOT modify nested git repositories (CR-32, Option A).** Scope partitioning excludes nested repo paths; such scope routes to sequential non-isolated implementation. |

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

**Resolution adopted: Option A — exclude nested-repo mutation from parallel capture-first (v0).**

```yaml
parallel_isolated_implementer:
  nested_repo_mutation: FORBIDDEN
  rationale: no durable artifact on the successful apply=false path (OMP v17.2.10)
  enforcement:
    - orchestrator preflight: enumerate nested repos before fan-out
    - scope partitioning MUST exclude nested repo paths from parallel worker scope
    - task packet out_of_scope names each nested repo path explicitly
  detection:
    - post-integration: `git submodule status` / nested-repo `git status` unchanged
    - any nested-repo diff after integration = contract violation, report to user
  fallback:
    - nested-repo scope routes to sequential non-isolated implementation
```

Option B (prove/materialize nested artifacts) is **not available at template level** — it requires an OMP runtime change to call `persistNestedPatches()` on the successful capture path and surface the paths in the task result. T-00.E3-G records the observed behavior; if a future OMP version materializes them, this exclusion can be lifted.

**Preflight enumeration:**

```bash
# nested repos / submodules under the orchestration root
git submodule status --recursive
find . -mindepth 2 -name .git -not -path './.git/*'
```

---

## E. Contract Summary

1. Isolation is requested **per task call**, never inferred from `mode`.
2. `mode: auto` selects a *backend*; it never decides *whether* to isolate.
3. Parallel writers MUST set `isolated: true`. **Observation-phase agents** (Explorer, Verifier, Reviewer) MUST NOT isolate — they must observe the real merged parent state. The exclusion is based on **assigned responsibility**, not mechanical capability: Verifier and Reviewer carry `bash` and can produce filesystem side effects; they are not isolated because they must inspect the real integrated state, not a copy. Any unexpected mutation is a contract violation, caught by pre/post `git status` checks.
4. Isolation requires git. Absent git, fall back to sequential and disclose it.
5. `apply: true` means isolation stages-then-merges; it is not a review sandbox.
6. Effective-config validation MUST assert `task.isolation.mode != none`, because the silent-absence failure has no runtime signal.
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

   **On preflight failure — do not launch parallel isolated Implementers.** Two permitted responses, both of which MUST be disclosed in the final report:
   - fall back to sequential non-isolated implementation (single Implementer, direct writes), or
   - refuse the parallel path and tell the user the exact setting to opt into.

   Silently proceeding with `apply=true` is prohibited: it produces concurrent auto-apply with no serialization guarantee.

   **Rollback consequence:** `task.isolation.apply` and `task.isolation.mode` become installer-owned MERGE keys in the project target. `spec/12 §C` and the manifest `installer_delta` schema must track them alongside `modelRoles` — see `spec/12 §C`.

   T-00.E3 (cases E3-A and E3-H) proves the settings path, the precedence behavior, and the preflight read.

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
