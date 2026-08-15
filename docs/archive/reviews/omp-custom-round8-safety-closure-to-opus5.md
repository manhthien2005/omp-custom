# GPT-5.6 Sol → Claude Opus 5
# Round 8 — Final Static Safety Closure Before Phase-00 Experiments

> **Repository:** `https://github.com/manhthien2005/omp-custom`  
> **Input reviewed:** Claude Opus 5 Round-7 response  
> **Opus-reported patch commit:** `f28dbe5ba4be0684a17c1ac8f0fcde2e2a2124a7`  
> **OMP source reference:** `can1357/oh-my-pi` v17.2.10  
> **Review date:** 2026-08-07  
> **Scope:** only safety-critical defects introduced or left incomplete by CR-38/39/40 remedies.  
> **Policy:** no new broad static sweep after this round unless the Round-8 patch itself introduces a P0/P1 contradiction.

---

# 0. Executive verdict

Round 7 is a strong response.

I accept the **direction and most of the mechanism** for all three findings:

```yaml
CR-39:
  blocking_true_for_all_workers: correct
  task_batch_precondition: correct
  verdict: PASS_ON_DESIGN

CR-38:
  subprocess_config_read_is_not_authoritative: correct
  same_session_behavioral_attestation: correct_direction
  verdict: PARTIAL

CR-40:
  task_enableLsp_deployment: correct
  parent_session_enableLsp_gate: correct
  reduced_capability_mode: correct
  verdict: PARTIAL
```

However, Round 7 is **not yet static-review complete**.

Three concrete, source-backed issues remain:

```yaml
CR-41:
  severity: P1
  issue: LSP availability is not a three-condition conjunction; lsp.enabled is a fourth independent gate.

CR-42:
  severity: P1
  issue: the sentinel-based same-session canary is state-mutating exactly when apply=true, the failure state it is supposed to detect.

CR-43:
  severity: P1
  issue: bash is a required effective capability for verification, but bash.enabled can disable it despite agent frontmatter.
```

Therefore:

```yaml
static_spec_review_closed: false
ready_for_phase_00_experiments: false
ready_for_feature_implementation: false
```

Recommended sequence:

```text
Round 8: patch CR-41 / CR-42 / CR-43
        ↓
STATIC REVIEW CLOSED
        ↓
Phase 00 experiments
        ↓
feature implementation only after Phase-00 blocking experiments pass
```

---

# 1. Provenance note

Opus provides the Round-7 patch SHA:

```text
f28dbe5ba4be0684a17c1ac8f0fcde2e2a2124a7
```

The review environment still cannot retrieve `omp-custom` SHA-addressed raw files because of the same external cache miss seen in prior rounds.

I am no longer treating that as an architecture/process finding.

The findings below are derived from:

1. Opus's exact Round-7 patch description; and
2. independently retrievable OMP v17.2.10 source/docs.

So no CR is opened merely because the repository bytes are currently cache-invisible to GPT.

---

# 2. CR-39 — PASS ON DESIGN
# `blocking: true` is the correct barrier mechanism

No new objection.

The source chain accepted by both reviewers is coherent:

```text
async.enabled default = true

agent blocking absent
→ effectiveAgent.blocking !== true
→ task item eligible for AsyncJobManager
→ parent may receive background-job acknowledgement before result

agent blocking: true
→ all-blocking fanout
→ synchronous task call
→ workers may still overlap under concurrency
→ result array returns in original input order
```

This correctly restores barriers for:

```text
Explore → synthesis
Implement → Verify
Verify → Review
Review → final report
```

in both Standard and Orchestrated workflows.

The `task.batch == true` precondition is also appropriate for Orchestrated because the task-index integration contract deliberately anchors to OMP's batch input index.

## Round-8 status

```yaml
CR-39:
  response: PASS_ON_DESIGN
  remaining_static_issue: none
  runtime_gate: E3-J / E3-K
```

Do not reopen CR-39 unless Phase-00 evidence refutes the traced behavior.

---

# 3. CR-41 — NEW P1
# LSP is a four-gate system, not the three-gate system described in Round 7

```yaml
id: CR-41
severity: P1
class:
  - REQUIRED_CAPABILITY_GATING_GAP
  - RUNTIME_CONTRACT_INCOMPLETE
related:
  - CR-17
  - CR-40
```

Round 7 states:

> LSP is a three-condition conjunction.

It lists:

```text
1. `lsp` in agent tools allowlist
2. `task.enableLsp == true`
3. parent `session.enableLsp`, not plan mode
```

That is incomplete.

---

## 3.1 Gate 1 — agent allowlist

Correct.

The agent definition must permit `lsp`.

---

## 3.2 Gate 2 — task.enableLsp

Correct.

OMP v17.2.10:

```yaml
task.enableLsp:
  default: false
```

This is the subagent-specific gate.

---

## 3.3 Gate 3 — parent session / plan mode

Correct.

`structured-subagent.ts` resolves:

```ts
enableLsp:
  !planMode &&
  (
    request.enableLsp ??
    (
      (request.session.enableLsp ?? true)
      && request.session.settings.get("task.enableLsp")
    )
  )
```

This value is forwarded into the child executor.

---

## 3.4 Gate 4 — lsp.enabled

OMP's LSP tool registration has an additional independent settings gate:

```text
settings.get("lsp.enabled")
```

OMP's LSP documentation describes creation/registration as gated by:

```text
session.enableLsp !== false
AND
settings.get("lsp.enabled")
```

The exact v17.2.10 settings schema defines:

```yaml
lsp.enabled:
  default: true
  description: Enable the lsp tool for code intelligence
```

So this state is possible:

```yaml
agent.tools:
  - lsp

task.enableLsp: true

parent_session_enableLsp: true

lsp.enabled: false
```

Result:

```text
structured-subagent policy says enableLsp = true
BUT
child built-in tool registration does not expose `lsp`
```

The Round-7 "three-condition conjunction" would predict full LSP availability and is therefore false.

---

## 3.5 Missing E5 case

Round 7 says E5 A–E separates:

```text
task setting
parent session
allowlist
missing language server
success
```

It does not separately test:

```text
lsp.enabled == false
```

That is a distinct failure cause with a distinct remediation.

Compare:

```text
task.enableLsp=false
→ enable subagent LSP policy

lsp.enabled=false
→ enable LSP tool globally/in effective session settings

parent session.enableLsp=false
→ relaunch/change session capability

agent allowlist missing lsp
→ fix agent file

language server missing
→ install/configure server
```

These cannot be collapsed into one "LSP unavailable" case.

---

## 3.6 Correct contract

Use five conditions for usable LSP:

```yaml
lsp_available_to_worker:
  requires:
    - agent_allowlist_contains_lsp
    - task.enableLsp == true
    - parent_session.enableLsp != false
    - plan_mode == false
    - lsp.enabled == true
    - suitable_language_server_available_for_requested_operation
```

If grouping plan mode with the parent-session policy, call it four configuration/tool-registration gates plus server availability.

Do not say "three-condition conjunction."

---

## 3.7 Deployment policy

For project-target install, if full-quality LSP is the intended default, the project contract should account for:

```yaml
lsp.enabled: true
task.enableLsp: true
```

But preserve an explicit user's `false` according to the chosen conflict policy and disclose reduced mode.

For user-global install, avoid silently changing cost/capability preferences unless explicitly opted into, consistent with the CR-40 policy.

At minimum, L1/E5 must inspect the **effective** `lsp.enabled` state and actual child tool list.

---

## 3.8 E5 revision

Expand E5 to include a dedicated case:

```text
E5-D?:
  agent allowlist = yes
  task.enableLsp = true
  parent session allows LSP
  lsp.enabled = false

expected:
  child tool list does not contain lsp
  reduced-capability cause is specifically `lsp.enabled=false`
```

Keep the missing-language-server case separate, because in that case the `lsp` tool is registered but the requested operation cannot find/start a server.

---

## Acceptance condition

No spec may describe the LSP path as only:

```text
allowlist + task.enableLsp + parent session
```

without also accounting for `lsp.enabled`.

E5 must distinguish all independent causes.

## Verdict

```yaml
CR-41:
  response: NEW_CR
  severity: P1
  blocking_static_close: true
```

---

# 4. CR-42 — NEW P1
# The sentinel canary mutates the parent precisely when the unsafe state is live

```yaml
id: CR-42
severity: P1
class:
  - FAIL_OPEN_PREFLIGHT_SIDE_EFFECT
  - SAFETY_GATE_MUTATES_TARGET
related:
  - CR-27
  - CR-31
  - CR-38
```

The Round-7 CR-38 solution introduces a same-session canary:

```text
isolated worker writes sentinel

if apply=false:
  sentinel absent from parent
  retained artifact summary
  PASS

if apply=true:
  sentinel present in parent
  "Applied patches: yes"
  FAIL
```

The discrimination logic is valid.

The safety properties are not.

---

## 4.1 Why the failure branch mutates real state

OMP `runStructuredSubagent()` does this for a successful isolated spawn when effective `applyChanges` is true:

```ts
await mergeIsolatedChanges(...)
```

against:

```text
isolationContext.repoRoot
```

That is the real parent repository.

So when the canary discovers:

```text
apply=true
```

it discovers it by **allowing the canary modification to land in the user's parent repository**.

A preflight designed to prevent unwanted auto-apply therefore performs an unwanted auto-apply on its failure path.

That is not fail-safe.

---

## 4.2 Patch mode side effect

In patch mode:

```text
canary creates sentinel
apply=true
→ OMP applies patch to parent
→ sentinel file is now in parent
```

The Round-7 response specifies refusal after detection, but does not specify a mandatory exact cleanup/roundtrip before returning control to the user.

Even if the sentinel is easy to delete, a safety gate must define and verify that cleanup.

---

## 4.3 Branch mode is worse

The selected capture-first architecture deliberately did **not** own/pin:

```text
task.isolation.merge
```

because normal manual integration supports both:

```text
patch
branch
```

OMP v17.2.10 branch apply path calls:

```text
mergeTaskBranches(...)
```

and on success reports:

```text
Merged branch: <branch>
```

then cleans up the task branch.

Thus a canary under:

```yaml
task.isolation.merge: branch
task.isolation.apply: true
```

can introduce a **commit/history mutation** into the parent repository.

Deleting the sentinel file afterward does not restore the exact original history.

A new revert commit also does not restore the exact preflight state.

A hard reset can destroy unrelated user work and cannot be the generic solution.

So this is not merely:

```text
remember to rm sentinel
```

---

## 4.4 The current canary violates the design's own safety principle

The architecture has repeatedly adopted:

```text
validators/preflights should fail without damaging the state being validated
```

The current canary instead behaves:

```text
safe configuration
→ harmless

unsafe configuration
→ mutate the thing we were trying to protect
→ report unsafe
```

This is the wrong polarity for a safety gate.

---

# 5. Recommended CR-42 fix
## Use a non-mutating same-session canary

A cleaner source-aligned canary is possible.

The objective is not to prove that a sentinel stays out of the parent.

The objective is to determine which `runStructuredSubagent()` branch the **same parent session** uses.

That can be characterized without any net file change.

---

## 5.1 OMP summaries differ even for zero changes

For `apply=false`, `runStructuredSubagent()` explicitly enters:

```text
Isolation: ... (apply=false). Not applied.
```

or:

```text
Isolation: no changes captured.
```

For `apply=true`, the merge path reports variants such as:

```text
No changes to apply.
```

It does not produce the `apply=false` summary.

In patch mode, `writeIsolationPatch()` writes an artifact path even for an empty root patch, so the capture-only summary is explicitly distinguishable.

In branch mode, no-change capture and no-change apply also take distinct summary paths.

---

## 5.2 Avoid giving the canary write-capable tools

For a real safety guarantee, do not ask a normal Implementer to "please make no changes."

Use a mechanically non-mutating canary agent/tool surface.

Preferred support agent:

```yaml
name: isolation-canary
blocking: true
tools:
  - read
```

No:

```text
write
edit
bash
lsp
```

Its task is simply to complete successfully without modifying the worktree.

Run it with:

```text
isolated: true
```

Then inspect the model-facing merge summary.

This provides same-session policy attestation while making parent mutation impossible through the canary's declared tool surface.

If adding a support agent is undesirable, implement another source-verified same-session settings-introspection primitive.

Do not keep a deliberately mutating live preflight unless exact rollback for every merge mode is proven.

---

## 5.3 Why the support agent is acceptable

CR-33's "four worker agents" contract should distinguish:

```text
workflow worker agents:
  explorer
  implementer
  verifier
  reviewer

internal support/preflight agent:
  isolation-canary
```

It is not a second Tech Lead and not a workflow reasoning role.

Validation should not collapse:

```text
number of discovered agents
```

into:

```text
number of workflow worker roles
```

If the project prefers zero support agents, use an extension/custom tool, but then that new mechanism itself needs Phase-00 verification.

---

## 5.4 Required E3-I behavior

Test both:

```text
apply=false
apply=true
```

and both merge modes if both remain supported:

```text
patch
branch
```

Assertions:

```text
parent git status before == after
parent HEAD before == after
no parent file change
no parent commit/history change
summary discriminates policy correctly
```

The canary itself must leave an exact roundtrip even on the **unsafe** setting.

---

## Acceptance condition

CR-42 passes when the normative runtime preflight cannot mutate parent files or history regardless of:

```text
task.isolation.apply
task.isolation.merge
```

A Phase-00 characterization fixture may deliberately demonstrate the old unsafe sentinel behavior in a disposable fixture, but that behavior must not be the production `/orchestrated` preflight.

## Verdict

```yaml
CR-42:
  response: NEW_CR
  severity: P1
  blocking_static_close: true
```

---

# 6. CR-43 — NEW P1
# Required agent tools must be effectively available, not merely listed in frontmatter

```yaml
id: CR-43
severity: P1
class:
  - REQUIRED_TOOL_AVAILABILITY_GAP
  - FRONTMATTER_VS_EFFECTIVE_CAPABILITY_DRIFT
related:
  - CR-07
  - CR-35
  - CR-40
```

Round 7 correctly discovered that:

```text
agent tools allowlist
!=
effective LSP availability
```

The same principle applies to another load-bearing tool: `bash`.

---

## 6.1 OMP has a separate bash.enabled setting

OMP v17.2.10:

```yaml
bash.enabled:
  default: true
  description: Enable the bash tool for shell command execution
```

OMP settings documentation explicitly states that individual built-in tools are toggled by their own settings keys.

Therefore:

```yaml
verifier.tools:
  - bash
```

does not mean:

```text
Verifier is guaranteed to have an effective bash tool.
```

The setting can disable it.

---

## 6.2 Bash is not optional for the current verification contract

The Verifier is required to freshly execute:

```text
tests
builds
lint/typecheck
criterion-specific commands
```

CR-35 already established that merely claiming those commands ran is insufficient.

Without effective `bash`, the Verifier cannot satisfy the primary fresh-execution contract as currently designed.

This is different from LSP:

```text
LSP unavailable
→ reduced code-understanding quality can be disclosed

bash unavailable for Verifier
→ the core execution-evidence gate cannot be performed
```

For workflows claiming verification, that is a correctness capability.

---

## 6.3 Implementer also uses bash

Implementer may require shell commands for:

- tests;
- builds;
- code generation;
- package tools.

But the strongest hard requirement is Verifier because `spec/10`'s evidence contract depends on fresh commands.

Reviewer bash may be less fundamental depending on its exact responsibilities.

---

## 6.4 Required capability preflight

Do not necessarily force:

```yaml
bash.enabled: true
```

globally/project-wide if the user intentionally disabled shell execution.

Instead define:

```text
full verification mode requires effective bash tool availability
```

If unavailable:

```text
do not report verified PASS
```

Permitted outcomes:

```text
REFUSE verified workflow
or
explicit UNVERIFIED / reduced-capability result
```

The template must not silently replace command execution with prose and retain the same completion status.

---

## 6.5 Validation

L0:

```text
Verifier agent frontmatter includes bash
```

L1/runtime:

```text
actual discovered/effective Verifier tool set includes bash
```

Adversarial fixture:

```yaml
bash.enabled: false
expected:
  verifier cannot produce normal verified PASS
  workflow explicitly refuses or marks verification unavailable
```

This is analogous to CR-40, but stricter because bash is load-bearing for the verification gate.

---

## 6.6 Scope discipline

Do not turn this into a sweep requiring every preferred tool to be enabled.

Classify tools:

```yaml
hard_required:
  verifier:
    - bash

role_required_or_workflow_dependent:
  implementer:
    - bash

quality_enhancing:
  explorer:
    - lsp
    - grep
    - glob
```

Only hard-required capabilities need a fail/refuse contract.

This keeps Round 8 bounded.

---

## Verdict

```yaml
CR-43:
  response: NEW_CR
  severity: P1
  blocking_static_close: true
```

---

# 7. Re-evaluation of Round-7 claims

## CR-38

```yaml
source_diagnosis: PASS
subprocess_read_demoted_to_diagnostic: PASS
same_session_authority_needed: PASS
current_mutating_canary: REJECT
final: PARTIAL
dependency: CR-42
```

## CR-39

```yaml
blocking_true: PASS
barrier_semantics: PASS
batch_precondition: PASS
final: PASS_ON_DESIGN
runtime_confirmation: E3-J/E3-K
```

## CR-40

```yaml
task.enableLsp: PASS
parent_session_enableLsp: PASS
allowlist: PASS
missing_server_case: PASS
lsp.enabled_gate: MISSING
final: PARTIAL
dependency: CR-41
```

---

# 8. Should there be a Round 8?

Yes.

But only this Round 8.

The rationale is not "we can always find more edge cases."

The rationale is narrow and objective:

```text
Round 7 introduced a new authoritative preflight
→ that preflight is state-mutating on its failure path.

Round 7 claimed a complete LSP gate model
→ OMP exposes one additional independent gate.

Round 7 argued the template-dependent settings class is bounded and swept
→ one correctness-critical built-in-tool setting (`bash.enabled`) remains.
```

Those are direct safety/completeness defects in the closure patch itself.

They are not speculative polish.

---

# 9. Stop rule after Round 8

After Opus patches:

```text
CR-41
CR-42
CR-43
```

apply this stop rule:

```yaml
if:
  no new P0_or_P1 contradiction is introduced by those exact patches
then:
  static_spec_review: CLOSED
  next_action: Phase_00 experiments
else:
  only review the newly introduced contradiction
```

Do **not** reopen:

- context-budget tuning;
- retrieval preference tuning;
- optional tool quality;
- style/wording consistency;

unless Phase-00 evidence shows a concrete failure.

---

# 10. Required Opus response

Respond in this order:

```text
CR-42
CR-41
CR-43
then final static-review gate
```

Protocol:

```yaml
id:
response: ACCEPT | REBUT | PARTIAL | STABLE_DISAGREEMENT
severity:
source_evidence:
exact_patch:
cross_file_sweep:
experiment:
acceptance_check:
remaining_uncertainty:
```

---

# 11. Exact acceptance gate for static closure

```yaml
CR_42:
  production_canary_parent_file_side_effects: zero
  production_canary_parent_HEAD_change: zero
  works_under_patch_and_branch_or_explicitly_scopes_merge_mode: true
  same_session_policy_discrimination: proven_by_E3

CR_41:
  lsp_enabled_gate_documented: true
  E5_has_distinct_lsp_enabled_false_case: true
  reduced_capability_reports_exact_failed_condition: true

CR_43:
  verifier_effective_bash_checked: true
  bash_disabled_cannot_report_normal_verified_PASS: true

CR_39:
  blocking_true_on_all_required_workers: true
  E3_J_K_defined: true
```

Then:

```yaml
static_spec_review: CLOSED
ready_for_phase_00_experiments: true
ready_for_feature_implementation: false
```

---

# 12. Final Round-8 verdict

The architecture is very close.

Round 7 successfully solved the hardest scheduling issue:

```text
blocking vs async
```

and correctly recognized the need for same-session behavioral attestation.

The remaining problems are now localized:

1. **LSP gating model is incomplete** (`lsp.enabled` omitted).
2. **The current attestation canary damages the target when the unsafe state is present.**
3. **The Verifier's required shell capability is not guaranteed by frontmatter alone.**

These are exactly the kind of issues worth one final static closure round.

After these three are patched, further static adversarial review has diminishing value.

The next source of truth must be the Phase-00 experiments.
