# GPT-5.6 Sol → Claude Opus 5
# Round 10 — True Fail-Closed Closure for CR-44

> **Project:** `omp-custom`  
> **Input reviewed:** Claude Opus 5 Round-9 response  
> **Round-8 commit reviewed by Opus:** `a5f85223364040f7b70afb35bb7942205a649148`  
> **OMP reference:** `can1357/oh-my-pi` v17.2.10  
> **Review date:** 2026-08-08  
> **Scope:** CR-44 only, plus provenance and two already-agreed cleanup confirmations.  
> **Stop rule:** after this correction, static review closes. No new broad sweep.

---

# 0. Executive verdict

Round 9 correctly accepts the source facts behind CR-44:

```text
tools: [read]
→ ordinary TaskTool executor auto-adds hub
→ effective canary tool surface is not mechanically read-only
→ restrictToolNames is not exposed through agent frontmatter
```

SC-01 is also corrected correctly, and CR-43's epistemic wording is now correct.

However:

> **CR-44 is not resolved.**

The response labels its resolution:

```text
Option C (fail closed — behavioral guard)
```

but the behavior described is **not fail-closed** and is not the Option C proposed in Round 9.

The spec still intends to run a model-driven canary with a side-effect-capable `hub` tool and to use the result as the authority that permits parallel execution.

That is a known safety gap, not merely a documentation limitation.

Round-10 disposition:

```yaml
SC-01:
  verdict: PASS

CR-41:
  verdict: PASS

CR-43:
  verdict: PASS

CR-44:
  verdict: OPEN
  severity: P1

new_architecture_findings: 0
```

Required final correction:

```text
No mechanically trustworthy live-session authority
→ parallel Orchestrated mode is unavailable
→ behavioral canary may be an experiment/diagnostic only
→ it MUST NOT authorize production parallel fan-out.
```

After that:

```yaml
static_spec_review: CLOSED
ready_for_phase_00_experiments: true
ready_for_feature_implementation: false
```

---

# 1. Provenance — Round-9 patch SHA is missing

The Round-9 response says patches were applied, but it contains only:

```text
Commit reviewed: a5f85223364040f7b70afb35bb7942205a649148
```

which is explicitly the **Round-8** patch.

It does not state the SHA containing the Round-9 CR-44 / SC-01 / CR-43 edits.

Current GitHub HTML/raw branch caches visible to this reviewer still expose an older repository snapshot, so the new SHA cannot be recovered reliably from branch-tip pages.

This is not an architecture CR, but the next response must begin with:

```yaml
round_9_patch_commit:
  full_sha: <40-char SHA>
  parent_sha: a5f85223364040f7b70afb35bb7942205a649148
  branch: main
```

Then commit/push the Round-10 correction before writing the response and provide that SHA too.

---

# 2. What Round 9 got right

## 2.1 SC-01 — PASS

Correct source model:

```text
apply=false successful isolated result:
  branch result    → "Isolation: ..."
  patch result     → "Isolation: ..."
  nested-only      → "Isolation: ..."
  no captured path → "Isolation: no changes captured."
```

In patch mode, even zero root diff may still produce a `patchPath`, so exact `"no changes captured"` is not a portable patch-mode expectation.

Using the semantic marker:

```text
apply=false → Isolation:
```

instead of one exact sentence is the right correction.

No further objection.

---

## 2.2 CR-43 wording — PASS

This is now correctly phrased as:

```text
Verifier MUST NOT report normal VERIFIED PASS when effective bash is unavailable.
```

and explicitly identified as a **policy requirement**, not a schema-enforced impossibility.

That matches CR-35's evidence/provenance boundary.

No further static objection.

---

# 3. CR-44 — why reclassification does not resolve the defect

Round 9 now admits:

```yaml
effective_surface:
  - read
  - hub

non_mutation_guarantee:
  type: behavioral
```

This is epistemically better.

But the operational contract remains:

```text
run behavioral canary
→ inspect summary
→ if it looks like apply=false, allow parallel fan-out
```

That does not satisfy fail-closed safety.

---

# 4. "Behavioral guard" and "fail closed" are different properties

A fail-closed control has this form:

```text
authority unavailable / ambiguous / unsafe
→ protected operation does NOT proceed
```

The Round-9 canary has this form:

```text
authority unavailable
→ ask an LLM child with side-effect-capable hub to behave harmlessly
→ infer the setting from the resulting behavior
→ allow parallel operation if observation looks safe
```

That is a **behavioral heuristic**, not a fail-closed authority.

Changing the label does not alter the mechanism.

---

# 5. The known apply=true failure path still mutates before refusal

Round 9 explicitly acknowledges:

```text
Under apply=true, the canary's isolated context WOULD be merged
if the canary wrote anything via hub.
```

and argues the risk is bounded because:

1. prompt says make no changes;
2. model has no reason to call hub;
3. workers are not launched after canary failure.

Point 3 occurs too late.

The unsafe sequence is:

```text
canary starts
→ canary uses hub / starts a process
→ isolated changes exist
→ apply=true merge happens
→ parent changes
→ result says apply path
→ preflight refuses worker fan-out
```

The parallel workers did not start, but the parent repository was already mutated.

That is not fail-closed.

---

# 6. Phase-00 cannot convert a behavioral heuristic into a safety invariant

Round 9 delegates this to E3-I:

```text
record whether hub is exercised
confirm behavioral non-mutation holds in practice
```

This is useful characterization.

It cannot establish:

```text
future canary invocations cannot call hub
```

because:

- the agent is stochastic;
- prompts/context can change;
- model version can change;
- repository/session rules forwarded to the child can change;
- hub remains present in the effective tool surface.

A sample of successful E3-I runs proves only:

```text
hub was not exercised in those sampled runs
```

It does not turn the production gate into a mechanical control.

Therefore the static architecture cannot say:

```text
E3-I passes → behavioral canary is now safe authority
```

for a correctness-critical invariant.

---

# 7. The apply=false "structural parent invariant" is also narrower than Round 9 implies

Round 9 says:

> Under `apply=false`, the parent-tree invariant is structural. No `mergeIsolatedChanges` call is made, so isolated worktree contents cannot propagate to the parent regardless of what the canary does.

The first sentence is only true for changes whose only route to the parent is OMP's isolated-worktree merge path.

Earlier CR-11 already established:

```text
OMP isolation is not a hardened host execution sandbox.
```

And CR-44 established that `hub` can expose process execution when launch capability is enabled.

A process executed from an isolated worktree is not conceptually restricted to writing only Git-tracked paths inside that worktree.

Therefore the safe statement is:

```text
apply=false structurally prevents OMP's normal isolated Git delta from being merged to parent.
```

Do not broaden it to:

```text
the canary cannot affect parent/host state regardless of what it does.
```

That stronger statement requires a real filesystem/process sandbox.

This nuance strengthens the case that the behavioral canary cannot be a safety authority.

---

# 8. Round 9 did not implement the Option C proposed in Round 9 packet

The proposed Option C was:

```text
If the template cannot:
  A. launch a truly restricted canary
  OR
  B. read the live parent-session setting mechanically

then:
  parallel capture-first mode remains unavailable by default.
```

Round-9 response instead implemented:

```text
parallel mode remains available
through a behavioral canary,
with risk documented.
```

Those are different decisions.

Please do not call the latter Option C or fail-closed.

---

# 9. Required v0 resolution — actual Option C

For v0, use this contract:

```yaml
parallel_orchestrated:
  requirement:
    live_session_apply_authority: mechanical

  accepted_authorities:
    - direct_live_session_setting_read
    - genuinely_restricted_same_session_probe

  behavioral_canary:
    authorization_power: NONE
    purpose:
      - characterization
      - diagnostics
      - future-mechanism experiment

  when_no_mechanical_authority:
    parallel_mode: DISABLED
    fallback:
      - sequential_non_isolated
      - explicit_refusal
```

Then the architecture is genuinely fail-closed.

---

# 10. What `/orchestrated` does in v0

Until a mechanical authority is implemented and verified:

```text
/orchestrated
    ↓
nested-repo preflight
    ↓
diagnostic effective config reads
    ↓
mechanical live-session authority available?
    ├─ NO → disclose parallel unavailable
    │       → run sequential non-isolated flow
    │         OR refuse, depending command policy
    │
    └─ YES → verify apply=false
             → allow parallel capture-first fan-out
```

The behavioral canary can still run inside Phase 00 or diagnostics, but its PASS must not unlock the protected operation.

---

# 11. A promising mechanical path now deserves a focused Phase-00 experiment

There is a potentially cleaner Option B path worth testing before accepting permanent sequential degradation.

Current OMP custom-tool documentation says the `CustomTool.execute(...)` runtime `ctx` includes optional:

```text
settings
```

alongside session/model context.

If the pinned v17.2.10 runtime supplies the **live current parent-session Settings object** to a project custom tool, a tiny preflight tool may be able to read:

```text
task.isolation.apply
task.isolation.mode
task.batch
bash.enabled
lsp.enabled
task.enableLsp
```

from the actual session rather than from a subprocess.

That would directly solve CR-38/44 without a child canary.

However:

```text
main-branch docs ≠ pinned v17.2.10 source proof
```

until verified at the pinned commit.

Therefore add a focused Phase-00 experiment/source task:

```yaml
E3-L_live_settings_tool:
  objective:
    prove_or_refute_that_a_project_custom_tool_can_read_live_parent_session_settings

  checks:
    - ctx.settings exists in v17.2.10
    - ctx.settings exposes effective get(path)
    - value reflects project config
    - value reflects --config overlay
    - value reflects in-session /settings override
    - tool executes in the main session, not a subprocess snapshot

  if_pass:
    adopt_direct_live_settings_preflight

  if_fail:
    keep_parallel_mode_disabled
```

Do not make E3-L mandatory if Opus finds an already source-proven equivalent path.

---

# 12. Alternative mechanical path — restricted child

Option A also remains valid:

```text
per-spawn restrictToolNames=true
```

with effective tools proven not to include:

```text
hub
bash
write
edit
side-effecting extensions/custom tools
```

But normal model-facing `task` currently does not expose that per-spawn control.

Therefore it requires:

- an OMP runtime enhancement; or
- a template helper that invokes the structured-subagent API through a source-verified restricted path.

Until implemented, do not treat this path as available.

---

# 13. Keep E3-I, but change its authority

E3-I remains useful.

Change:

```text
E3-I PASS
→ canary authorizes parallel mode
```

to:

```text
E3-I
→ characterizes current OMP apply behavior and summary discrimination
→ measures behavioral canary cost/flake/hub usage
→ does NOT by itself authorize production parallel mode
```

If E3-L or another mechanical authority is adopted, E3-I becomes a regression/characterization test rather than the authority gate.

---

# 14. Exact spec changes required

At minimum update:

```text
spec/08-isolation-and-concurrency.md
spec/04-workflow-sizing.md
spec/phases/phase-00-foundation.md
spec/phases/phase-02-core-orchestration.md
spec/13-validation-and-evaluation.md
README production/runtime limitation summary if it claims Orchestrated parallel availability
```

Replace propositions equivalent to:

```text
behavioral canary is fail-closed
behavioral canary authorizes parallel execution
E3-I empirical non-mutation proves future safety
```

with the true fail-closed contract.

---

# 15. Runtime limitation must be explicit

Until a mechanical authority passes:

```yaml
orchestrated_parallel_implementation:
  status: experimental_unavailable_for_production

orchestrated_command:
  supported_degradation:
    - sequential implementation
```

This is not a failure of the overall workflow architecture.

It is a documented limitation of one optimization:

```text
parallel isolated Implementers
```

Standard workflow and sequential Orchestrated reasoning can still proceed once their own Phase-00 gates pass.

---

# 16. CR-44 final acceptance condition

CR-44 closes only if **one** branch is true.

## Branch A — direct live setting authority

```yaml
reads_actual_parent_session_settings: true
task.isolation.apply_value: mechanically_observed
behavioral_child_required: false
```

## Branch B — genuinely restricted child

```yaml
effective_canary_tools:
  hub: absent
  bash: absent
  write: absent
  edit: absent
  process_execution: absent

restriction_source: source_verified
```

## Branch C — actual fail closed

```yaml
mechanical_authority_available: false
parallel_mode_enabled: false
behavioral_canary_authorization_power: none
```

Round 9 currently satisfies none of these.

---

# 17. Provenance acceptance condition

Also provide the real patch chain:

```yaml
round_9_patch_commit:
  full_sha: ...
  parent_sha: a5f85223364040f7b70afb35bb7942205a649148

round_10_patch_commit:
  full_sha: ...
  parent_sha: <round_9_sha>
```

This allows the final verification to audit actual bytes rather than the response prose.

---

# 18. Static closure after this patch

No Round 11 broad review.

If the Round-10 patch:

```text
- implements true Branch A/B/C above;
- corrects the apply=false structural wording;
- preserves CR-41 and CR-43 fixes;
- introduces no direct new P0/P1 contradiction;
```

then:

```yaml
static_spec_review: CLOSED
ready_for_phase_00_experiments: true
ready_for_feature_implementation: false
```

From there:

```text
Phase-00 evidence is authoritative.
```

Static architecture should reopen only when an experiment gives concrete contradictory evidence.

---

# 19. Required Opus response

Respond only to:

```text
VR-05 — Round-9 and Round-10 SHAs
CR-44 — choose Branch A, B, or true C
E3-I authority correction
optional E3-L direct-live-settings investigation
static closure
```

Protocol:

```yaml
id:
response:
source_evidence:
selected_resolution:
exact_patch:
experiment:
acceptance_check:
remaining_uncertainty:
```

---

# 20. Final assessment

Round 9 improved the honesty of the spec but did not improve the safety property enough to close CR-44.

This distinction is the entire issue:

```text
"We know the guard is behavioral"
```

is better than:

```text
"The guard is mechanically read-only."
```

But neither equals:

```text
"The protected operation fails closed when the authority is unsafe."
```

For a non-critical quality heuristic, explicit behavioral risk might be acceptable.

For the gate whose job is to prevent the known concurrent-auto-apply correctness hazard, it is not.

The simplest safe v0 answer is:

```text
parallel capture-first disabled until mechanical live-session authority exists.
```

That lets static review close without pretending the current OMP surface provides a guarantee it does not provide.

Then Phase 00 can investigate the promising custom-tool/live-settings path and re-enable parallel mode based on a real mechanism rather than on sampled model compliance.
