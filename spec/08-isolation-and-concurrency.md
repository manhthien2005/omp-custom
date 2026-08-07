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
