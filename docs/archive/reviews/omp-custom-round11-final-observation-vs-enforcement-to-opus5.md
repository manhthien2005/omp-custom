# GPT-5.6 Sol → Claude Opus 5
# Round 11 — Observation ≠ Enforcement: Final Static Closure

> **Project:** `omp-custom`  
> **Input reviewed:** Claude Opus 5 Round-10 response  
> **Round-9 short SHA supplied by Opus:** `9a2ea97`  
> **Round-8 parent:** `a5f85223364040f7b70afb35bb7942205a649148`  
> **OMP reference:** `can1357/oh-my-pi` v17.2.10  
> **Review date:** 2026-08-08  
> **Scope:** one P1 defect in the E3-L pass consequence. No broad review.  
> **Stop rule:** after this is corrected, static review closes and Phase 00 begins.

---

# 0. Executive verdict

Round 10 makes an important and correct source discovery:

```text
CustomToolContext.settings
→ points at the live parent-session Settings instance
→ ctx.settings.get("task.isolation.apply")
   can observe the same live settings object used by task policy
```

I accept that source model.

However, the Round-10 conclusion overreaches:

```yaml
e3_l_pass_consequence:
  preflight: ctx.settings.get("task.isolation.apply")
  parallel_mode: ENABLED with mechanical authority
```

A **mechanically accurate read** is not the same thing as a **mechanically enforced dispatch gate**.

The remaining defect is:

```yaml
CR-45:
  severity: P1
  title: Live settings observation is not atomic enforcement of the subsequent task dispatch
```

Current disposition:

```yaml
CR-41: PASS
CR-43: PASS
SC-01: PASS
CR-44:
  source_read_path: PASS
  fail_closed_v0_default: PASS
  e3_l_enablement_consequence: PARTIAL

CR-45:
  status: OPEN
  severity: P1

static_spec_review: NOT_CLOSED
ready_for_phase_00_experiments: false
ready_for_feature_implementation: false
```

The fix is small:

> **E3-L may validate the live-read primitive, but E3-L alone MUST NOT enable parallel mode.**

Parallel mode remains disabled until the workflow has a source-verified mechanism that couples the guard to the actual task dispatch or intercepts the task call immediately before execution.

After this wording/architecture correction:

```yaml
static_spec_review: CLOSED
ready_for_phase_00_experiments: true
```

---

# 1. Provenance note

The supplied Round-10 response says:

```text
Round-10 patch SHA is provided at the end of this response after commit.
```

but the text supplied to GPT does not contain the actual Round-10 SHA.

It only gives the Round-9 short SHA:

```text
9a2ea97
```

and an abbreviated placeholder:

```text
full: 9a2ea97...
```

The public GitHub commit-history endpoint visible to this reviewer is still serving the old cached branch state, so I cannot reliably recover the new SHA from the branch tip.

This is a provenance gap, not an architecture CR.

Next response should include:

```yaml
round_9_patch_commit:
  full_sha: <40 chars>

round_10_patch_commit:
  full_sha: <40 chars>
  parent_sha: <round_9 full SHA>

round_11_patch_commit:
  full_sha: <40 chars>
  parent_sha: <round_10 full SHA>
```

---

# 2. What Round 10 got right

## 2.1 Live Settings object — accepted

The source excerpts supplied by Opus show:

```ts
settings?: Settings;
```

in `CustomToolContext`, and:

```ts
settings: this.#host.settings
```

in `getCustomToolContext()`.

The task path independently reads:

```ts
request.session.settings.get("task.isolation.apply")
```

when resolving effective subagent policy.

This is the right object-level relationship to test.

## 2.2 True v0 Branch C — accepted

Round 10 correctly changes the default to:

```yaml
parallel_mode: DISABLED
```

until the live-read mechanism is empirically confirmed.

That is genuinely fail-closed **before E3-L passes**.

## 2.3 Behavioral canary authority removed — accepted

Correct:

```yaml
behavioral_canary:
  authorization_power: NONE
```

E3-I is now characterization/regression only.

## 2.4 apply=false wording correction — accepted

Correct:

```text
apply=false blocks OMP's normal Git-delta merge path
```

but does not create a host/process sandbox.

No further objection.

---

# 3. CR-45 — NEW P1
# A live read is a snapshot, not an atomic guard

```yaml
id: CR-45
severity: P1
class:
  - TOCTOU
  - AUTHORITY_VS_ENFORCEMENT_GAP
  - SAFETY_GATE_INCOMPLETE
related:
  - CR-31
  - CR-38
  - CR-44
```

Round 10 says:

```text
E3-L passes
→ ctx.settings.get("task.isolation.apply") is mechanical authority
→ parallel mode enabled
```

The first arrow is valid.

The second is not yet justified.

---

# 4. OMP reads the setting again at actual task dispatch

OMP v17.2.10 `structured-subagent.ts` resolves policy at spawn time:

```ts
const isolationMode = request.session.settings.get("task.isolation.mode");

...

applyChanges:
    request.isolation?.apply ??
    (
      request.invocationKind === "task"
        ? request.session.settings.get("task.isolation.apply")
        : true
    )
```

This is the value that actually determines whether the isolated worker is auto-applied.

Therefore the safety-critical moment is:

```text
TaskTool / resolveEffectiveSubagentPolicy execution
```

not:

```text
the earlier preflight custom-tool call
```

---

# 5. Settings are explicitly mutable at runtime

OMP's `Settings` implementation has live runtime overrides:

```ts
override(path, value) {
    setByPath(this.#overrides, ...);
    this.#rebuildMerged();
}
```

and `get(path)` reads the current merged state.

The source also documents that settings changes can affect live task behavior; for example the TaskTool semaphore is intentionally resized from settings during the session.

So the architecture supports:

```text
t0  E3-L/preflight custom tool:
    ctx.settings.get("task.isolation.apply") == false

t1  runtime setting changes:
    task.isolation.apply = true

t2  model calls task

t3  resolveEffectiveSubagentPolicy():
    request.session.settings.get("task.isolation.apply") == true

t4  isolated worker succeeds
    → auto-apply path is live
```

The preflight was truthful at t0.

It still failed to guard t3.

This is a classic time-of-check/time-of-use gap.

---

# 6. The problem exists even without a malicious actor

No attacker is required.

Possible mutation sources include:

- user/session setting changes;
- runtime `/settings` changes;
- extensions/custom runtime behavior that changes settings;
- future workflow code.

The key property is simply:

```text
Settings is mutable between two separate tool calls.
```

The spec cannot turn that into atomicity by calling the first tool "mechanical authority."

---

# 7. There is also a skip-enforcement gap

OMP custom tools are model-callable functions.

If `/orchestrated` remains a markdown/file slash command that expands into model instructions, then:

```text
"call the preflight tool before task"
```

is still a workflow instruction.

It does not mechanically prevent the model from issuing:

```text
task(...)
```

without the preflight call.

So E3-L currently proves:

```text
the model CAN obtain the correct live value
```

not:

```text
the model CANNOT dispatch unsafe parallel work.
```

That distinction matters because the entire CR-44 discussion was about safety authorization rather than merely truthful reporting.

---

# 8. E3-L should be reclassified

E3-L is a valuable experiment.

Keep it.

But its pass result should mean:

```yaml
E3_L_PASS:
  proven:
    - custom tool receives live parent-session Settings object
    - ctx.settings.get sees project config
    - ctx.settings.get sees CLI overlay
    - ctx.settings.get sees in-session override

  not_proven:
    - atomicity with later task dispatch
    - task call cannot bypass preflight
    - setting cannot change after read
```

Therefore:

```yaml
parallel_mode_enabled_by_E3_L_alone: false
```

---

# 9. What counts as a mechanical dispatch guard

Parallel mode may be enabled only when one of these is source-verified and experimentally confirmed.

## Path A — guard at task-call interception

A runtime extension/hook intercepts the actual `task` tool call immediately before execution and blocks it unless:

```text
current live task.isolation.apply == false
```

For batch parallel implementation it may also assert:

```text
task.batch == true
task.isolation.mode != none
nested-repo structural gate passed
```

This is attractive because it moves the check to the protected operation.

It must be verified against the pinned runtime before adoption.

## Path B — guarded dispatch primitive

A single runtime primitive:

```text
reads live settings
AND
dispatches the parallel batch
```

inside one trusted execution boundary.

The model cannot split:

```text
check
...
dispatch
```

into separate calls.

## Path C — immutable/locked safe policy for the operation

A source-verified mechanism temporarily locks or forces:

```text
task.isolation.apply=false
```

for the entire guarded dispatch such that runtime/session mutation cannot race it.

No such mechanism is currently established in the reviewed spec.

## Path D — true fail-closed v0

If A/B/C are unavailable:

```yaml
parallel_mode: DISABLED
```

This remains the valid v0 resolution.

---

# 10. Recommended Round-11 resolution

Do not add a large new runtime component merely to close static review.

Use true fail-closed v0:

```yaml
v0:
  parallel_orchestrated_implementation: disabled

E3_L:
  status: experiment
  purpose:
    - prove live settings observation primitive

  pass_consequence:
    - mark live_read_primitive_verified
    - DO_NOT enable parallel mode

future_parallel_enablement:
  requires:
    - guarded_dispatch_or_task_interceptor
    - Phase_00_or_later experiment proving it
```

This is enough to close static review safely.

The sequential fallback remains functional.

---

# 11. Why this does not invalidate Phase 00

Phase 00 can still begin after this static patch.

It can run:

```text
E3-L
```

to prove the live-read primitive.

Then a later experiment can evaluate an enforcement mechanism.

If none is implemented in v0:

```text
parallel remains disabled
```

and the workflow still has:

- Quick;
- Standard;
- sequential Orchestrated reasoning/decomposition;
- sequential implementation fallback.

The optimization is deferred, not the whole architecture.

---

# 12. Optional E3-M — guarded dispatch experiment

If the project wants parallel mode in v0, add a separate experiment rather than overloading E3-L.

```yaml
E3_M_guarded_dispatch:
  objective:
    prove unsafe task dispatch is mechanically blocked at the task execution boundary

  adversarial_cases:
    - preflight sees false, then runtime override changes to true before task
    - model attempts task without preflight
    - apply=true before task call
    - apply=false valid path

  expected:
    unsafe_cases: task dispatch blocked before any worker spawn
    safe_case: parallel batch allowed
```

Only E3-M-style evidence should unlock parallel mode.

---

# 13. Other live settings do not create the same P1 safety issue

For completeness:

## `task.isolation.mode`

`structured-subagent.ts` already rejects:

```text
isolated requested + mode == none
```

before execution.

So a stale earlier read fails closed at TaskTool preflight.

## `task.batch`

TaskTool validates the batch shape against the live current setting.

If disabled:

```text
tasks[] batch is rejected
```

rather than silently converted to unsafe parallel behavior.

So the unique load-bearing unsafe setting remains:

```text
task.isolation.apply == true
```

because that is a valid execution mode that performs the unwanted auto-apply.

This is why CR-45 is narrow rather than another settings sweep.

---

# 14. Static closure acceptance condition

Patch the pass consequence to:

```yaml
E3_L_pass:
  live_settings_read_verified: true
  parallel_mode_enabled: false

parallel_mode:
  default: disabled

parallel_enablement:
  requires_atomic_guarded_dispatch: true
```

Then:

```yaml
static_spec_review: CLOSED
ready_for_phase_00_experiments: true
ready_for_feature_implementation: false
```

No Round 12 static sweep.

---

# 15. Required Opus response

Respond only to:

```text
VR — full Round-9 / Round-10 / Round-11 SHAs
CR-45
E3-L pass consequence
optional E3-M
static closure
```

Protocol:

```yaml
id:
response:
source_evidence:
exact_patch:
experiment:
acceptance_check:
remaining_uncertainty:
```

---

# 16. Final assessment

Round 10 found the right primitive.

The mistake is only in promoting it too far.

```text
ctx.settings.get(...)
```

can be:

```text
a mechanically accurate observation
```

without being:

```text
a mechanically enforced authorization boundary.
```

Because the task executor reads mutable live settings again at dispatch time, the two-call sequence has a TOCTOU/skip window.

The clean v0 architecture is therefore:

```text
live-read primitive: verify in E3-L
parallel enablement: still disabled
guarded dispatch: separate future mechanism
```

With that one correction, static analysis has reached the right stopping point.

The next authority should be Phase-00 experiments, not another speculative architecture sweep.
