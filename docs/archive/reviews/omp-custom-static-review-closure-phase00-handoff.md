# GPT-5.6 Sol — Static Review Closure & Phase-00 Handoff

> **Project:** `omp-custom`  
> **Review lineage:** adversarial rounds 1–11  
> **OMP reference:** `can1357/oh-my-pi` v17.2.10  
> **Date:** 2026-08-08  
> **Final static-review verdict:** **CLOSED**  
> **Feature implementation:** **NOT YET AUTHORIZED**  
> **Next authority:** **Phase-00 empirical experiments**

---

# 1. Final decision

```yaml
static_spec_review: CLOSED

ready_for_phase_00_experiments: true

ready_for_feature_implementation: false

parallel_orchestrated_implementation:
  default: DISABLED
  reason: guarded dispatch has not yet been empirically proven

sequential_fallback:
  status: AVAILABLE_BY_SPEC

reopen_static_architecture_only_if:
  - Phase-00 produces concrete P0/P1 contradictory evidence
  - implementation of a guarded-dispatch mechanism introduces a new P0/P1 contract conflict
```

No Round 12 broad static review is recommended.

---

# 2. Why CR-45 is now sufficiently resolved

OMP's actual task policy is resolved at dispatch time from the live session:

```ts
applyChanges:
  request.isolation?.apply ??
  (request.invocationKind === "task"
    ? request.session.settings.get("task.isolation.apply")
    : true)
```

Therefore an earlier `ctx.settings.get(...)` is an observation, not an atomic authorization boundary.

Round 11 now states exactly that:

```yaml
E3_L_pass:
  live_read_primitive_verified: true
  parallel_mode: DISABLED
  parallel_mode_requires: guarded_dispatch
```

This is fail-closed.

The unsafe optimization remains unavailable unless a later mechanism proves enforcement at the operation boundary.

---

# 3. Stable static conclusions

The following architecture decisions are sufficiently closed for Phase 00:

```yaml
tech_lead:
  runtime_role: main_session
  discovered_agent: false

workers:
  explorer:
    blocking: true
  implementer:
    blocking: true
  verifier:
    blocking: true
  reviewer:
    blocking: true

standard_workflow:
  implementer_isolated: false

orchestrated_parallel_candidate:
  implementer_isolated: true
  capture_first: true
  auto_apply_required: false
  current_v0_status: disabled_until_guarded_dispatch_verified

structured_output:
  default_schema: agent_output_frontmatter
  caller_outputSchema: explicit_override
  schemaMode: independent_validation_mode

nested_repositories:
  parallel_isolated_implementation: disabled_if_present

integration:
  owner: main_session_tech_lead
  concurrency: 1
  order: original_task_list_index
  completion_order: ignored
  conflict: stop_and_preserve_remaining_artifacts

verification:
  schema_proves_shape_not_execution_provenance: true
  verifier_requires_effective_bash_for_normal_verified_pass: true
  bash_missing: REFUSE_or_UNVERIFIED

lsp:
  full_quality_requires:
    - agent_allowlist
    - task.enableLsp
    - parent_session_enableLsp
    - not_plan_mode
    - lsp.enabled
    - suitable_server
  missing_lsp: disclosed_reduced_capability

governance:
  upstream_update_discovery: full_commit_range
  watched_paths: triage_only

production_readiness:
  required_OQs: must_be_resolved_by_recorded_experiment
  validation:
    operational: L0-L3
    comparative: L4_threshold
```

---

# 4. Phase-00 experiment priorities

The first implementation work should be experiments, not feature construction.

## Highest priority

### E3-J — blocking semantics

Prove:

```text
blocking:true workers
→ synchronous task barrier
→ workers still overlap in parallel batch
→ results returned in original input order
```

Include a no-blocking control.

### E3-A / E3-H — settings/runtime diagnostic behavior

Verify current target environment and configuration precedence.

### E3-G — nested repo behavior

Characterize the OMP nested-patch defect and retain v0 exclusion regardless of sampled success unless the runtime mechanism materially changes.

### E3-I — isolation behavioral characterization

Diagnostic only.

It MUST NOT authorize parallel execution.

### E3-L — live settings read

Prove:

```text
CustomToolContext.settings
```

reflects:

1. project config;
2. CLI overlay;
3. in-session runtime override.

PASS means only:

```text
live observation primitive verified
```

not:

```text
parallel enabled
```

---

# 5. E3-M — guarded-dispatch acceptance rule

E3-M is the only experiment that may unlock parallel implementation.

The experiment must distinguish **observation** from **enforcement**.

## Required PASS property

A PASS requires a mechanism where the safety check is mechanically coupled to the protected task dispatch.

Acceptable forms include:

```text
A. task-call interceptor/hook that reads the current live setting immediately at the actual
   task boundary and blocks the task before worker spawn;

B. one trusted guarded-dispatch primitive that reads the live setting and dispatches the
   batch inside the same enforcement boundary;

C. another source-verified mechanism with equivalent atomic/fail-closed semantics.
```

## Explicit non-PASS mechanisms

The following MUST NOT by themselves pass E3-M:

```text
- a separate preflight custom-tool call followed by a later task call;
- empirical evidence that no runtime setting happened to change between two calls;
- "same JS event loop" reasoning without an actual dispatch interceptor/atomic primitive;
- a worker's first model-directed action checking a fingerprint;
- a worker prompt instructing it to abort before edits;
- the behavioral isolation canary;
- a finite sample in which hub happened not to execute.
```

A worker-side fingerprint may be defense-in-depth, but it is post-dispatch and behaviorally skippable unless implemented below the model/tool boundary.

## Adversarial E3-M cases

```yaml
M1:
  setup: guard sees apply=false, then live override becomes true before attempted task dispatch
  expected: task blocked before any worker spawn

M2:
  setup: model/workflow attempts parallel task without performing an earlier preflight step
  expected: task blocked by the protected-operation boundary itself

M3:
  setup: apply=false remains true
  expected: guarded parallel batch is allowed

M4:
  setup: apply=true before task call
  expected: task blocked before any isolated worker spawn
```

Only a mechanism passing these classes should flip:

```yaml
parallel_orchestrated_implementation: ENABLED
```

---

# 6. E3-M may legitimately fail

Phase 00 does not need to force parallel mode into v0.

If no suitable guarded-dispatch primitive exists:

```yaml
E3_M: FAIL_OR_DEFER

parallel_orchestrated_implementation: DISABLED

fallback:
  - sequential non-isolated implementation

architecture_status:
  static_spec_review: remains_closed
  limitation: documented
```

This is a valid v0 result.

Do not reopen architecture merely because a performance optimization is unavailable.

---

# 7. Other Phase-00 empirical gates

Continue the already-defined experiments for:

```text
E2     model-role resolution
E3-*   isolation/capture/barrier/config behavior
E4     RULES/subagent propagation and token consequences
E5     LSP conditions/remediation
```

The experiments should produce retained evidence:

```yaml
per_case:
  - exact OMP version/SHA
  - effective settings
  - invocation
  - tool surface
  - transcript
  - parent git status before/after
  - parent HEAD before/after where relevant
  - artifact paths
  - observed result
  - expected result
  - PASS/FAIL
  - architecture consequence
```

---

# 8. Static review reopen policy

Do not return to generalized adversarial prose review.

Reopen only on concrete evidence.

Valid reopen trigger:

```text
Phase-00 case shows source model and observed runtime differ in a way that invalidates a
load-bearing design decision.
```

Examples:

```text
blocking:true does not create the expected barrier
ctx.settings is not the live parent Settings object
nested repo behavior differs materially from traced source
guarded dispatcher can be bypassed
RULES prompt propagation differs from expected runtime prompt
```

Not valid reopen triggers:

```text
a nicer naming convention
another possible optional optimization
different token-budget preference
hypothetical edge case without a reachable mechanism
```

---

# 9. Provenance note

Known full prior commits supplied by Opus:

```yaml
round_9:
  full_sha: 9a2ea9745a53f603f4c070f079066d11dd9997f1

round_10:
  full_sha: 0e7e07cbdb7179a59dbadbbe55be2ab0f2a248a2
```

The Round-11 response supplied to GPT does not include the Round-11 patch SHA.

Before Phase-00 implementation work is merged, record the actual Round-11 full SHA in the review ledger.

This is an audit-hygiene item, not a blocker to the architecture conclusion.

---

# 10. Final gate

```yaml
STATIC_SPEC_REVIEW:
  verdict: CLOSED

ROUND_12_STATIC_SWEEP:
  recommended: false

PHASE_00:
  authorized: true

FEATURE_IMPLEMENTATION:
  authorized: false

PARALLEL_IMPLEMENTATION:
  authorized: false
  unlock_gate: E3-M guarded-dispatch PASS

NEXT_ACTION:
  implement_and_run_phase_00_experiments
```
