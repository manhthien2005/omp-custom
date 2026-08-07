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
