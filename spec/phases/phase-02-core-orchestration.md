# Phase 02 — Core Orchestration

<!-- topic08-projection:behavior-core -->
## Topic 08 behavior consumer

Managed dispatch reconciles the manifest-selected project skills and exact role autoload before
native spawn. Worker alone autoloads completion evidence. The main session explicitly uses
`agent_tasks` for lifecycle operations; diagnostic reads need no task, while edit/write/bash need
one valid binding. The current three-skill roster can expand only through the manifest contract.

<!-- topic06-projection:phase-02 -->
## Topic 06 dispatch consumer

Create one Topic 04 work unit before every managed spawn and call the same-name trusted `task`
boundary through `.omp/bin/omp-managed.ps1`. Single and batch items carry complete independent
work-unit identities. Managed v1 is blocking and non-nested; a receipt records a provisional
outcome only. If the boundary is unavailable, the Tech Lead works inline without fabricating an
agent packet, independent review, or receipt.

## Topic 04 consumer projection

Topic 04 consumes task, candidate, and work-unit authority. Phase 02 must create accepted task
contracts before mutation, record bounded work-unit outcomes as provisional, reserve the
authoritative worktree/scope, and let only the integrated candidate reach acceptance. It consumes
the shared manual core without adding a DAG edge or mandatory spawn.

> **Active remap:** implement the approved Topic 02 entry/lifecycle contract with the KD-027
> Topic 03 topology and the later Topic 08 deeper triage adapter. The pre-Topic-02 plan is
> retained below as a non-executable research appendix.

**Depends on**: phase-01
**Blocks**: phase-03, phase-04

---

## Active Topic 02 Runtime Migration

### Objective

Migrate runtime prompts from the Phase 00 snapshot to the Topic 02 contract without rewriting
historical evidence. Implement no-prefix entry, explicit Quick, and Tech-Lead selection of
Standard or Orchestrated. Standard is one integrated implementation lane. Orchestrated
requires independently verifiable work units and an integration contract plus
cross-boundary verification.

### Authority and dependency boundary

- `spec/04-workflow-sizing.md` and KD-026 own entry and lifecycle semantics.
- KD-027 selects exactly `cheap-scout`, `worker`, and `reviewer` as spawnable agents. The
  main-session Tech Lead stays inline by default; stage names never force a spawn.
- Topic 04 owns durable task/candidate/session state. Phase 02 projects the conceptual
  contract into behavior but does not invent a second state store.
- Topic 08 owns the detailed triage procedure and runtime-specific adapters.
- `spec/08-isolation-and-concurrency.md` applies only if Topic 03 selects a parallel-writer
  path. Sequential execution is a valid Orchestrated implementation.

### Migration tasks

#### T-02.N1 — Establish a new current-product evidence boundary

Preserve historical Phase 00 evidence; create new current-product validation evidence.
Do not refresh the hashes in `docs/evidence/phase-00/T-00.3/conclusion.yml`, weaken its
validator, or rewrite its consumer markers to make a later product state look historical.
Record the Phase 00 prompt snapshot as the migration source and create a new evidence identity
for the post-Topic-02 runtime projection.

The current-product manifest records the selected three-agent set, hashes each installed runtime
artifact, binds the immutable Phase 00 T-00.3 conclusion by path and digest, and marks its roster
as `superseded_for_current_runtime_only`. It records DeepSeek smoke as `PASS`, `FAIL`, or
`ENVIRONMENT_BLOCKED` without altering historical evidence.

#### T-02.N2 — Project the entry contract

- Plain natural-language requests enter the main-session Tech Lead normally.
- `/quick` is an explicit user choice with a short suitability preflight.
- `/standard` and `/orchestrated` are compatibility/advanced hints.
- The same words without `/` are natural-language hints, not command errors.
- Workflow reclassification is an internal transition; it never asks the model to invoke
  another slash command.

#### T-02.N3 — Project task, candidate, and session boundaries

Prompts must distinguish clarification, accepted task contract, active work, frozen candidate,
verification, rework, and terminal outcome. The accepted contract locks objective,
scope/authority, mandatory criteria, and required verification and review obligations.
Acceptance evidence binds to one frozen snapshot; mutation requires C2 or later. One session
serves one task and one non-competing candidate lineage. Compaction preserves identity;
handoff opens a reconciled successor.

#### T-02.N4 — Implement topology-neutral Standard

Implement one integrated lane under Tech Lead ownership. Default to inline/no spawn. Optional
Cheap Scout retrieval and Worker implementation require a stated benefit; verification remains a
Tech Lead task-contract obligation; General Reviewer dispatch follows the KD-027 risk gate rather
than a fixed Explorer-to-Implementer-to-Verifier chain.

#### T-02.N5 — Implement structurally Orchestrated work

Require at least two work-unit contracts with inputs, outputs, ownership, dependencies, and
completion conditions; one task-level integration contract; and cross-boundary verification.
Only the fully integrated frozen task candidate may be accepted. Parallelism and multiple
writers remain optional.

#### T-02.N6 — Preserve work during reclassification and failure

Keep valid discovery and workspace changes. Do not reset, discard, revert, or restart a slash
command merely because classification changes. Cheap Scout remains optional/read-only and
fails softly to the retrieval path the Tech Lead needs.

Cheap Scout routes Flash `xhigh` (provider `max`) → Pro `xhigh` (provider `max`) only for
availability/runtime failure → Tech Lead retrieval. Worker defaults to `high` and uses per-spawn
`effort: hi` only for Tech-Lead-selected difficult work. Reviewer is fixed at `xhigh`; unavailable
Opus uses the approved review fallback ladder and is not itself a blocker.

#### T-02.N7 — Validate the runtime projection

Add deterministic and behavioral checks for every Topic 02 scenario in
`spec/04-workflow-sizing.md`: no-prefix entry, missing slash, explicit Quick, compatibility
hints, internal escalation, candidate invalidation, rework, compaction, handoff, resume/fork,
Orchestrated integration, and Scout fallback. Validate both supported runtime adapters and
record any capability-specific limitation.

### Active deliverables

- runtime-specific entry adapters aligned with one behavioral core;
- topology-neutral Standard and structural Orchestrated contracts;
- exactly three discoverable runtime agents: Cheap Scout, Worker, and Reviewer;
- benefit-gated spawn, dynamic Worker effort, fixed Reviewer `xhigh`, and Scout-only fallback;
- candidate-bound verification behavior;
- non-destructive reclassification and fail-soft Scout fallback;
- new post-Topic-02 evidence and an explicit supersession link from the Phase 00 snapshot.

### Active exit criteria

- [ ] Plain requests and missing-slash hints do not produce command errors.
- [ ] Quick is user-selected; Standard versus Orchestrated is Tech-Lead-selected.
- [ ] Orchestrated passes the work-unit/integration structural test; agent count and
      parallelism do not select it.
- [ ] Reclassification preserves valid work and never reinvokes a slash command.
- [ ] Candidate mutation invalidates prior acceptance-bearing evidence.
- [ ] Compaction and handoff preserve the approved lifecycle identities.
- [ ] Topology-specific and parallel-writer paths run only when their later contracts select
      and authorize them.
- [ ] Runtime discovery is exactly `cheap-scout`, `worker`, `reviewer`; `tech-lead`, `explorer`,
      `implementer`, and `verifier` are absent from agent discovery.
- [ ] Current-product evidence binds the immutable Phase 00 source and records the supersession
      disposition plus actual DeepSeek environment state.
- [ ] Historical Phase 00 evidence remains byte-stable and the new product state has separate,
      reproducible evidence.

---

## Appendix A — Superseded Pre-Topic-02 Plan (Reference Only)

<!-- topic08-supersession:fixed-role-autoload -->

The remainder of this file preserves useful source notes and the earlier fixed-worker
implementation candidate. It is not execution authority. Topic 03 may adopt, revise, or reject
individual mechanisms; none may override the active remap above.

### Historical objective

Get `/quick`, `/standard`, and `/orchestrated` executing correctly with real agent
dispatch, real structured results, explicit isolation, and guaranteed discipline
injection.

---

### Historical rationale

Phase-01 removed the defects; this phase supplies what was missing. The commands currently describe a workflow in prose without the mechanics that make it happen: no `output:` frontmatter schemas on worker agents, no `isolated: true` on parallel Implementers, no `autoloadSkills`, no non-git-repo fallback, and no defined sequential integration procedure for captured parallel-worker artifacts. Prose alone does not orchestrate.

---

### Historical tasks

### T-02.1 — Wire autoloadSkills for guaranteed discipline

**CR-01/CR-26 correction:** Whether `alwaysApply` rules propagate to subagents depends on the T-00.E4 experiment result from phase-00:
- *Outcome A (rules ARE prompt-visible in child)*: `autoloadSkills` is still the preferred delivery mechanism for policy packaging, token-budget control, and explicit per-agent precedence — but NOT because parent rules categorically cannot reach child sessions.
- *Outcomes B/C (rules do NOT propagate or are not prompt-visible)*: `autoloadSkills` remains the required delivery mechanism for enforcing discipline invariants in workers.

In either case, `autoloadSkills` injects a skill body via `sendCustomMessage` (`task/executor.ts`) and is the recommended delivery path. The key change from prior drafts: **do not state this is the "only deterministic mechanism"** — that claim was upstream of T-00.E4 evidence and may be false.

Assign:
- `implementer`: `evidence-before-completion, systematic-debugging`
- `verifier`: `evidence-before-completion`
- `diff-reviewer`: `evidence-before-completion`
- `explorer`: none (read-only; nothing to falsely complete)

**Acceptance**: three agents carry `autoloadSkills`; every name resolves to an
existing skill directory. Dangling names fail validation (they are filtered silently
at runtime — `resolveAutoloadSkills` drops unresolved entries).

### T-02.1b — Make stage barriers real: `blocking: true` on every worker (CR-39)

Every workflow in `04-workflow-sizing.md` is written as ordered stages, and each stage
consumes the previous stage's completed result. **OMP does not provide that ordering by
default.** `async.enabled` defaults to `true` (`config/settings-schema.ts:4223-4225`),
`blocking` is parsed with no default (`discovery/helpers.ts:299`), and every non-blocking item
is routed to the `AsyncJobManager` (`task/index.ts:715`) — so the `task` call returns before
the worker finishes, with `results: []` for a fully-background batch.

Without this fix the failures are silent and systematic, not cosmetic:

| Stage arrow | Default behavior without `blocking` |
|---|---|
| parallel Implementers → serial integration | integration starts with nothing to integrate |
| Verifier → Reviewer | review runs against an unverified tree |
| Reviewer → final report | report written before any findings exist |
| Explorers → architecture synthesis | synthesis runs on absent evidence |

Fix — add to all four worker agent files:

```yaml
blocking: true
```

**Do not set `async.enabled: false`.** It is a user-global execution preference; suppressing
it to satisfy a template-local barrier requirement is the same category error as writing
`task.isolation.apply` globally. Per-agent frontmatter makes this template deterministic
regardless of the user's async setting — the strictly narrower fix.

**`blocking: true` does not serialize the batch.** When every item is blocking, `asyncItems` is
empty and `task/index.ts:722` takes the synchronous fan-out path: concurrent execution under
the `task.maxConcurrency` semaphore, results returned in **input order**
(`task/parallel.ts:14`). That input-order guarantee is the anchor T-02.3b's task-index
integration depends on — so this task is a **precondition** for T-02.3b, not an alternative to
it. Consuming async deliveries as they arrive would be completion order, which T-02.3b forbids.

Also make `task.batch` an explicit Orchestrated precondition rather than an assumption. It
defaults to `true`, but a user can disable it, and doing so reverts the wire to the flat
single-spawn shape with no `tasks[]` array and therefore no stable index.

```
preflight: effective task.batch == true  → else parallel path unavailable, disclose, go sequential
```

**Acceptance**: all four worker agent files carry `blocking: true`; L0 asserts it statically
and L1 asserts it survives discovery; `/orchestrated` checks `task.batch` before fan-out and
has a disclosed fallback; `async.enabled` is **not** modified by the template or the installer.
T-00.E3-J proves the barrier and the ordering together.

### T-02.2 — Make isolation explicit for write-capable workers

`task.isolation.mode` defaults to `none`, and the `isolated` parameter only exists in
the task schema when isolation is enabled (`task/index.ts`). Relying on `auto` is
not a correctness strategy.

Fix:
- document `task.isolation.mode: auto` as a prerequisite for parallel implementation
- pass `isolated: true` explicitly on every Implementer dispatch in `orchestrated.md`
- never isolate Explorer, Verifier, or Reviewer (they observe the real merged/written state; Verifier and Reviewer have `bash` for running commands and reading output, but MUST NOT write implementation artifacts — isolation would cause them to verify/review a copy, not the real tree that will ship)

**CR-30 — Session settings (not per-task-item):** capture-only isolation requires setting `task.isolation.apply: false` at the project/session settings level — it is **not** a per-task-item dispatch field in OMP v17.2.10. T-00.E3 must verify this settings path before parallel implementation is attempted. Under this template's matrix (only parallel Implementers use `isolated: true`), the setting exclusively affects parallel worker spawns.

**CR-31 — Runtime preflight is mandatory, and deployment is target-aware.** OMP's default is `task.isolation.apply: true`, so the capture-first architecture is only correct if the setting is *actually effective at runtime*. Installing it is not sufficient — a higher-precedence overlay can re-enable apply. `/orchestrated` MUST, before any parallel fan-out:

```
assert effective task.isolation.mode  != "none"
assert effective task.isolation.apply == false
```

On failure: **do not launch parallel isolated Implementers.** Fall back to sequential non-isolated implementation, or refuse and name the setting the user must opt into. Disclose the degradation in the final report. Deployment target policy (project config owns the key; user/global requires explicit opt-in flag) is specified in `08-isolation-and-concurrency.md §E-9` and `12-installation-and-rollback.md §C`.

**CR-38 — the settings read is a diagnostic; the same-session canary is the authority.** `omp config get` runs in a **separate process** and re-resolves settings from files. What actually governs dispatch is the parent session's in-memory `Settings`: `applyChanges: request.isolation?.apply ?? (invocationKind === "task" ? request.session.settings.get("task.isolation.apply") : true)` (`task/structured-subagent.ts:315-317`). Two layers are invisible to a subprocess and both outrank project config:

- `--config <file>` CLI overlay — *"for that one process. Never persisted."* (`docs/settings.md:21`)
- in-session runtime override — `Settings.override()` writes the in-memory `#overrides` layer (`config/settings.ts:518-526`), touching no file

So a parent launched with `--config` setting `apply: true` over a project config of `false` yields a subprocess read of `false` (preflight PASS) and an actual `applyChanges == true` — restoring the CR-27 concurrent-auto-apply hazard through the check meant to prevent it.

Add a **same-session capture canary** after the nested-repo and `task.batch` checks pass:
dispatch one minimal isolated **blocking** read-only agent (tools: `[read]`) that makes NO
changes to its worktree and yields immediately. Assert the task completed, and that the
result merge-summary begins with `"Isolation: ..."` (the apply=false discriminator). If the
summary does NOT begin with "Isolation:" (indicating apply=true path), fail the preflight and
do not fan out — and verify the parent tree is unchanged. If the isolated dispatch itself
errors, parallel mode is unavailable. This exercises the same session, the same `task` tool,
the same `session.settings`, and the same isolation path — so it attests behavior instead of
reconstructing config. **CR-44/CR-45 fail-closed:** the behavioral canary does NOT authorize parallel fan-out — it
is a diagnostic/characterization tool only. E3-L must source-verify and test an approved
replacement live-session reader. The earlier project custom-tool `ctx.settings` claim is
invalid on pinned v17.2.10 because `sdk.ts:885-894,938-955` omits settings from that bridge;
the `session-tools.ts:1295-1314` settings-bearing context belongs to MCP refresh. E3-L PASS
confirms observation capability
only — it is NOT the parallel authority gate. CR-45 TOCTOU: the read at t0 is a snapshot;
`Settings.override()` (`settings.ts:518-525`) can mutate the value before dispatch at t3.
**E3-M (guarded dispatch) is the gate**: until E3-M passes, parallel mode is DISABLED.
Until E3-M (guarded dispatch) passes, parallel mode is **DISABLED**; sequential non-isolated is the fallback. E3-L confirms live-read capability (prerequisite for E3-M) but does NOT itself enable parallel — CR-45 TOCTOU: `Settings.override()` (`settings.ts:518-525`) can mutate the value between the preflight read (t0) and actual dispatch (t3).
Full contract and CR-44/CR-45/E3-L/E3-M analysis in `08-isolation-and-concurrency.md §E-9.2`.

The canary requires T-02.1b: it must be synchronous from the coordinator's perspective.
`blocking: true` on the canary agent is required (§C-1.3).

**CR-32 — Any nested git repo or submodule disables parallel isolated implementation for the whole repository.** On the successful `apply=false` path, OMP v17.2.10 never materializes nested-repo patches to disk (`persistNestedPatches()` is reachable only from the failure/recovery path), and the `apply=false` summary reports only the root patch when the root also changed — so a nested-repo change is silently lost with no signal. Post-integration `git status` on the nested repo **cannot distinguish compliance from silent loss** (the parent tree looks identical in both cases), so scope-exclusion instructions and post-hoc detection are not accepted as enforcement (§08 §D-1.1). The safe v0 policy is **Option A1**: the orchestrator enumerates nested repos before fan-out (`git submodule status --recursive`, `find . -mindepth 2 -name .git -not -path './node_modules/*'`), and **any non-empty result disables parallel isolated implementation for that run**, routing to sequential non-isolated implementation instead. Full source trace and enforcement analysis in `08-isolation-and-concurrency.md §D-1`.

**Acceptance**: every parallel Implementer dispatch carries `isolated: true`; observation-phase agents (Explorer, Verifier, Reviewer) carry no isolation; `/orchestrated` runs the settings diagnostics and, only after E3-L passes, may use the scoped `pi.pi.settings.get("task.isolation.apply")` observation for the OMP-owned default main-CLI root-session construction class as a diagnostic input (behavioral canary is diagnostic-only per CR-44; excluded ACP/SDK/injected/cloned/RPC hosts receive no reader claim); the nested-repo preflight runs **before** fan-out and a non-empty result **disables parallel isolated implementation for the whole run**, routing to sequential non-isolated implementation with the nested paths disclosed (T-00.E3-G, CR-32 Option A1). Scope exclusion is explicitly NOT an accepted outcome here — an acceptance criterion reading "excluded from parallel scope" would restate the rule §08 §D-1.1 withdrew. **Until E3-M (guarded dispatch) passes, parallel mode is DISABLED; sequential non-isolated is the fallback. E3-L is a prerequisite for E3-M but does not itself enable parallel (CR-45 TOCTOU).**

### T-02.3 — Add the non-git-repo fallback

`prepareIsolationContext` **throws** when cwd is not inside a git repository, failing
the task.

Fix: the Tech Lead checks `git rev-parse --show-toplevel` before dispatching
isolated work. On failure: sequential, non-isolated implementation, and say so in
the report.

**Acceptance**: `orchestrated.md` contains the preflight check and the documented
fallback.

### T-02.3b — Specify the serial integration procedure (CR-29/CR-26)

Under `task.isolation.apply: false`, parallel Implementers return artifacts and the Tech Lead owns integration. "Deterministic order" is not a specification — it must name the key.

**Normative integration contract:**

```yaml
integration:
  owner: main Tech Lead
  concurrency: 1
  order:
    source: original orchestrator task-list
    stable_key: task_index          # tasks[0], tasks[1], tasks[2], ...
    worker_completion_order: IGNORED
  per_artifact:
    - validate baseline applies cleanly (git apply --check)
    - apply artifact
    - record applied / conflicted
  failure_semantics: partial integration — stop at first conflict
  remaining_artifacts: preserved, paths reported to user
  verify_after: full batch only (never per-artifact)
```

**Why task-index order, not completion order:** OMP's fan-out returns results in original input order (`task/parallel.ts` — "Results are returned in the same order as input items"; `results[index]` assignment preserves the input index). Task-index order is therefore source-anchored, repeatable across runs, and independent of scheduling jitter. Completion order is nondeterministic and would make conflict behavior irreproducible between identical runs.

**No topological ordering is needed.** If two work units have a real dependency, they were not independent and MUST NOT have been parallelized in the first place (see `08-isolation-and-concurrency.md §C`). Dependency-ordered integration would paper over a partitioning error.

**Conflict handling:**

```
apply tasks[0] → OK
apply tasks[1] → CONFLICT
                 → stop; do NOT attempt tasks[2..n]
                 → parent retains tasks[0] only
                 → report: applied=[0], conflicted=[1], unapplied=[2..n]
                 → all unapplied artifact paths reported to the user
                 → Verifier does NOT run on a partially integrated tree
```

**Acceptance**: `orchestrated.md` names task-index order explicitly; conflict path stops integration, preserves and reports remaining artifact paths, and does not run the Verifier on a partial tree. T-00.E3-E and E3-F prove ordering and conflict behavior.

### T-02.4 — Complete the dispatch contracts in commands

**CR-03/CR-26 correction:** Per DR-2 and phase-01 T-01.7, each worker agent carries its canonical schema in `output:` frontmatter — this is the primary enforcement path. Task dispatch commands use inline `outputSchema` **only** as an explicit caller override (e.g., a one-off call needing a narrower schema).

Each dispatch must specify: agent, task packet content, `isolated` (write-capable only), and
`effort` only when the selected manifest consumes that lever. When a selected dispatch uses
effort, task.enableEffort must be effective or the path stops before dispatch; do not silently
drop the escalation. `schemaMode: "strict"` should be passed when strict enforcement is required.
Inline `outputSchema` is used only when overriding the agent's `output:` frontmatter.

**Acceptance**: every dispatch specifies agent, task packet, isolation intent (when
write-capable), and effort only when selected and proven effective. Inline `outputSchema` appears
only for explicit overrides, not as a universal requirement.

### T-02.5 — Implement Quick as genuinely inline

`quick.md` says the Tech Lead "handles this workflow inline" — correct, and it should
spawn nothing. Make that explicit: zero subagents, main session does inspect →
implement → verify, and the escalation trigger to `/standard` is stated.

**Acceptance**: `/quick` spawns no subagent; escalation criteria are explicit.

### T-02.6 — Define the Verifier rework loop

`verification-result.decision: FAIL` must have a defined next step: return to
Implementer with the failure evidence, bounded to two attempts, then escalate to
re-scoping.

**Acceptance**: `standard.md` and `orchestrated.md` define the loop and its bound.

### T-02.7 — Handle the schema-override signal

The coordinator must distinguish the full runtime status surface. A malformed schema can return
`structuredOutput.status: unavailable`; a schema violation can be `invalid`; retry exhaustion may
set `schemaOverridden`. Malformed schemas and any structuredOutput status other than valid cannot
satisfy acceptance, and an override remains unvalidated even if its payload looks complete.

**Acceptance**: commands require `structuredOutput.status == "valid"`, reject every override,
and repair or explicitly replace/reconcile/revalidate the selected contract before redispatch.

### T-02.8 — Bound concurrency deliberately

Set `task.maxConcurrency` per `08-isolation-and-concurrency.md` and state the
provider rate-limit interaction. Do not exceed the number of genuinely independent
work units.

**Acceptance**: concurrency is a stated number with a rationale, not a default.

---

### Historical deliverables

- Agent files with `autoloadSkills`
- Commands with complete dispatch contracts (schema, isolation, effort)
- Non-git-repo fallback path
- Defined rework loop and override handling
- `/quick` implemented as truly inline
- **Effective-settings preflight** in `orchestrated.md` (`mode != none`, `apply == false`) with disclosed fallback (CR-31)
- **Nested-repo enumeration + exclusion** from parallel worker scope (CR-32)
- **Normative integration-order rule** (original task-list index) with conflict-stop semantics (CR-29)

---

### Historical verification

Execute each workflow against a real task in a scratch repository:

1. `/quick` on a one-line fix — expect zero subagents, verification evidence present.
2. `/standard` on a two-file change — expect Explorer → Implementer → Verifier, each
   returning a schema-valid result.
3. `/orchestrated` on an independent three-module change — expect:
   - the effective-settings preflight runs and passes (`mode != none`, `apply == false`);
   - parallel isolated Implementers complete and return **retained patch/branch artifacts**;
   - parent working tree is **unchanged** after workers finish (no auto-apply — `task.isolation.apply: false`);
   - Tech Lead integrates artifacts in **original task-list index order**, one at a time, regardless of worker completion order;
   - Verifier runs **only after all integration is complete** on the final merged parent;
   - final working tree reflects the fully integrated result of all Implementers' work.
4. `/orchestrated` in a non-git directory — expect the documented fallback, not a throw.
5. Force a verification failure — expect the rework loop, not a false `completed`.
6. **CR-31 — preflight failure**: run `/orchestrated` with effective `task.isolation.apply: true`
   (e.g. a CLI overlay re-enabling it). Expect **no parallel isolated fan-out** — either
   sequential non-isolated fallback or an explicit refusal naming the setting. The degradation
   MUST appear in the final report. A silent parallel run with `apply=true` is a FAIL.
7. **CR-32 — nested-repo exclusion**: create a repo with a nested git repo (`vendor/component/.git`).
   Run `/orchestrated` on a change spanning root + nested paths. Expect the orchestrator to
   enumerate the nested repo, exclude it from every parallel worker's scope, name it in
   `scope`, and route that scope to sequential non-isolated implementation (A1 policy). A parallel
   worker silently editing the nested repo is a FAIL.
8. **CR-29 — integration order determinism**: dispatch three parallel Implementers where
   completion order deliberately differs from task-list order (e.g. task[2] finishes first).
   Expect integration to proceed `task[0] → task[1] → task[2]` regardless. Re-run and expect
   identical integration order.
9. **CR-29 — conflict stop semantics**: force `task[1]`'s artifact to conflict. Expect
   `task[0]` applied, `task[1]` reported as conflicted, `task[2]` **not attempted**, and both
   `task[1]` and `task[2]` artifacts still readable on disk.

---

### Historical exit criteria

- [ ] All three workflows run end to end without silent failure
- [ ] Every dispatch returns a schema-valid result
- [ ] Implementers isolated in parallel; observation-phase agents (Explorer, Verifier, Reviewer) not isolated
- [ ] `task.isolation.apply: false` confirmed at session/project settings (T-00.E3); parallel Implementers return captured artifacts without auto-apply
- [ ] **CR-31** — `/orchestrated` performs the effective-settings preflight (`mode != none`, `apply == false`) and never fans out in parallel when it fails; the fallback or refusal is disclosed in the report
- [ ] **CR-38/CR-42/CR-44/CR-45** — `omp config get` is used as a diagnostic only; **parallel mode is DISABLED until E3-M (guarded dispatch) passes**. E3-L must prove the scoped `pi.pi.settings.get("task.isolation.apply")` reader for the OMP-owned default main-CLI root-session construction class because the nominal project custom-tool `ctx.settings` bridge is unavailable on pinned v17.2.10. ACP/SDK/injected/cloned/RPC hosts remain excluded. E3-L remains a prerequisite for E3-M, but E3-L PASS alone does NOT enable parallel: CR-45 TOCTOU means the preflight read at t0 is a snapshot; `Settings.override()` (`settings.ts:518-525`) can mutate the value between t0 and actual dispatch. Behavioral canary (§E-9.2) runs as characterization/diagnostic (E3-I) only — its PASS does NOT authorize parallel fan-out. After E3-M PASS: preflight uses the guarded-dispatch mechanism; the scoped reader informs supported-host diagnostics; `omp config get` explains the diagnosis to the user.
- [ ] **CR-39** — all four worker agents carry `blocking: true`; L0 checks the files, L1 checks discovery; `async.enabled` untouched; `task.batch == true` verified in preflight with a disclosed fallback
- [ ] **CR-40/CR-41** — project install owns `task.enableLsp: true`; an existing `false` reports CONFLICT and is not overwritten; a run without LSP discloses reduced-capability mode naming which of the **four conditions** failed (`lsp.enabled` is the fourth, distinct from `task.enableLsp`)
- [ ] **CR-32** — orchestrator performs nested-repo preflight (Option A1); any non-empty nested-repo result disables parallel isolated implementation for that run and routes to sequential non-isolated; withdrawn enforcement: scope exclusion and post-integration `git status`
- [ ] **CR-29** — integration order is original task-list index order, normatively stated in `orchestrated.md` and independent of worker completion order
- [ ] **CR-29** — conflict on artifact *i* stops integration of *i+1…n*; all unapplied artifacts remain readable and are reported by path
- [ ] Tech Lead integrates artifacts sequentially; Verifier runs only after full integration
- [ ] Non-git-repo fallback works
- [ ] Discipline skills injected via `autoloadSkills`
- [ ] Rework loop bounded and defined
- [ ] `schemaOverridden` handled as unvalidated
- [ ] Concurrency set deliberately

---

### Historical risks

| Risk | Mitigation |
|---|---|
| `autoloadSkills` adds fixed cost per subagent | Only for agents that can falsely claim completion |
| Isolation setup latency | Only for parallel writes, where the alternative is corruption |
| Parallel isolated patches conflict during sequential integration | **Serialized integration is the normal design**, not a fallback. Conflict on a given artifact pauses remaining integration; unapplied artifacts are preserved. Recovery: re-partition scope, retry the conflicting artifact on the new base, or escalate to user. |
| **CR-31 — effective `apply` is `true` at runtime despite install** | Higher-precedence overlay (CLI, runtime override) can re-enable apply after install. Mandatory effective-settings preflight before fan-out; on failure, sequential fallback or refusal, always disclosed. Never proceed in parallel with `apply=true`. |
| **CR-31 — user/global install changes unrelated repos** | Template never writes `task.isolation.apply` to `~/.omp/agent/config.yml` without the explicit `-EnableCaptureFirstIsolation` flag and a printed blast-radius warning. Project target is the default and preferred scope. |
| **CR-32 — nested-repo change silently dropped** | OMP v17.2.10 does not materialize nested patches on the successful `apply=false` path, and the summary omits the nested count when the root also changed. Mitigation is exclusion, not detection-after-the-fact: enumerate nested repos pre-fan-out, forbid them in parallel scope, route to sequential. Post-integration nested `git status` check catches violations. |
| **CR-29 — nondeterministic integration order** | Order is normatively the original task-list index, never worker completion order. OMP `mapConcurrent` writes `results[index]`, preserving input order (`task/parallel.ts:14`) — the ordering anchor is source-supported and repeatable. |
| Strict schema mode causes retry loops | Bounded at 3 by `yield`; override surfaces to parent |
