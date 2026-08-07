# Phase 02 — Core Orchestration

> OPUS PROPOSED SPEC v1 | Make the three workflows actually run end to end.

**Depends on**: phase-01
**Blocks**: phase-03, phase-04

---

## Objective

Get `/quick`, `/standard`, and `/orchestrated` executing correctly with real agent
dispatch, real structured results, explicit isolation, and guaranteed discipline
injection.

---

## Rationale

Phase-01 removed the defects; this phase supplies what was missing. The commands currently describe a workflow in prose without the mechanics that make it happen: no `output:` frontmatter schemas on worker agents, no `isolated: true` on parallel Implementers, no `autoloadSkills`, no non-git-repo fallback, and no defined sequential integration procedure for captured parallel-worker artifacts. Prose alone does not orchestrate.

---

## Tasks

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

**CR-32 — Any nested git repo or submodule disables parallel isolated implementation for the whole repository.** On the successful `apply=false` path, OMP v17.2.10 never materializes nested-repo patches to disk (`persistNestedPatches()` is reachable only from the failure/recovery path), and the `apply=false` summary reports only the root patch when the root also changed — so a nested-repo change is silently lost with no signal. Post-integration `git status` on the nested repo **cannot distinguish compliance from silent loss** (the parent tree looks identical in both cases), so scope-exclusion instructions and post-hoc detection are not accepted as enforcement (§08 §D-1.1). The safe v0 policy is **Option A1**: the orchestrator enumerates nested repos before fan-out (`git submodule status --recursive`, `find . -mindepth 2 -name .git -not -path './node_modules/*'`), and **any non-empty result disables parallel isolated implementation for that run**, routing to sequential non-isolated implementation instead. Full source trace and enforcement analysis in `08-isolation-and-concurrency.md §D-1`.

**Acceptance**: every parallel Implementer dispatch carries `isolated: true`; observation-phase agents (Explorer, Verifier, Reviewer) carry no isolation; `/orchestrated` performs the effective-settings preflight and has a disclosed fallback path (T-00.E3-A/E3-H); nested-repo paths are enumerated and excluded from parallel scope (T-00.E3-G).

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

Each dispatch must specify: agent, task packet content, `isolated` (write-capable only), and `effort` when `task.enableEffort` is on. `schemaMode: "strict"` should be passed when strict enforcement is required. Inline `outputSchema` is used only when overriding the agent's `output:` frontmatter.

**Acceptance**: every dispatch specifies agent, task packet, isolation intent (when write-capable), and effort (when enabled). Inline `outputSchema` appears only for explicit overrides, not as a universal requirement.

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

`yield` accepts non-conforming data after three failed retries and sets
`schemaOverridden`. The Tech Lead must treat such a result as **unvalidated** rather
than trusting its fields.

**Acceptance**: commands instruct the Tech Lead to re-verify independently when the
override flag is present.

### T-02.8 — Bound concurrency deliberately

Set `task.maxConcurrency` per `08-isolation-and-concurrency.md` and state the
provider rate-limit interaction. Do not exceed the number of genuinely independent
work units.

**Acceptance**: concurrency is a stated number with a rationale, not a default.

---

## Deliverables

- Agent files with `autoloadSkills`
- Commands with complete dispatch contracts (schema, isolation, effort)
- Non-git-repo fallback path
- Defined rework loop and override handling
- `/quick` implemented as truly inline
- **Effective-settings preflight** in `orchestrated.md` (`mode != none`, `apply == false`) with disclosed fallback (CR-31)
- **Nested-repo enumeration + exclusion** from parallel worker scope (CR-32)
- **Normative integration-order rule** (original task-list index) with conflict-stop semantics (CR-29)

---

## Verification

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

## Exit Criteria

- [ ] All three workflows run end to end without silent failure
- [ ] Every dispatch returns a schema-valid result
- [ ] Implementers isolated in parallel; observation-phase agents (Explorer, Verifier, Reviewer) not isolated
- [ ] `task.isolation.apply: false` confirmed at session/project settings (T-00.E3); parallel Implementers return captured artifacts without auto-apply
- [ ] **CR-31** — `/orchestrated` performs the effective-settings preflight (`mode != none`, `apply == false`) and never fans out in parallel when it fails; the fallback or refusal is disclosed in the report
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

## Risks

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
