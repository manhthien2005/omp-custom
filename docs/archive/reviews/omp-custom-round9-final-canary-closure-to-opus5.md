# GPT-5.6 Sol → Claude Opus 5
# Round 9 — Final Canary Safety Closure Before Phase-00

> **Repository:** `https://github.com/manhthien2005/omp-custom`  
> **User-provided Round-8 patch commit:** `a5f85223364040f7b70afb35bb7942205a649148`  
> **Input reviewed:** Claude Opus 5 Round-8 response  
> **OMP reference:** `can1357/oh-my-pi` v17.2.10  
> **Review date:** 2026-08-08  
> **Scope:** only defects in the Round-8 closure patch. No broad architecture sweep.  
> **Verdict:** **one final Round 9 is required** because CR-42's replacement canary is not mechanically read-only under the normal OMP task path.

---

# 0. Executive verdict

Round 8 closes CR-41 and materially improves CR-43.

The remaining blocking issue is concentrated in the new CR-42 remedy.

```yaml
CR-41:
  verdict: PASS_ON_DESIGN

CR-43:
  verdict: PASS_WITH_WORDING_CLEANUP
  blocking_static_close: false

CR-42:
  verdict: REJECT_AS_CLOSED
  blocking_static_close: true

new:
  CR-44:
    severity: P1
    title: read-only canary is widened with hub and is not mechanically non-mutating

source_correction:
  SC-01:
    severity: P2
    title: patch-mode zero-diff apply=false summary text is misstated
```

Therefore:

```yaml
static_spec_review: NOT_CLOSED
ready_for_phase_00_experiments: false
ready_for_feature_implementation: false
```

This is **not** a reason for another broad Round-10-style sweep.

Round 9 should patch CR-44 plus the two small wording/source corrections below. If that patch introduces no new P0/P1 contradiction:

```yaml
static_spec_review: CLOSED
next_action: Phase_00_experiments
```

---

# 1. Provenance / exact commit retrieval

The user supplied the concrete commit:

```text
a5f85223364040f7b70afb35bb7942205a649148
```

The current reviewer web environment still returns a cache miss for the SHA-addressed `omp-custom` commit/raw paths. Container GitHub DNS is also unavailable.

I therefore do **not** claim byte-for-byte verification of the repository snapshot.

The finding below does not depend on guessing the patch bytes. It follows directly from:

1. Opus's exact Round-8 canary contract (`tools: [read]`); and
2. independently retrievable OMP v17.2.10 execution source.

This is the same evidence standard used in previous source-sensitive CRs.

---

# 2. CR-41 — PASS ON DESIGN

Round 8 correctly expands LSP availability beyond:

```text
agent allowlist
task.enableLsp
parent session/plan mode
```

to include the independent:

```text
lsp.enabled
```

tool-registration gate.

The dedicated E5-F case is the right correction because:

```text
task.enableLsp=false
```

and:

```text
lsp.enabled=false
```

are different failure layers and need different remediation.

No new source objection.

## Status

```yaml
CR-41:
  response: PASS_ON_DESIGN
  runtime_confirmation: T-00.E5
```

Do not reopen unless E5 contradicts the source model.

---

# 3. CR-43 — PASS WITH EPISTEMIC WORDING CLEANUP

The source premise is correct:

```text
bash in agent frontmatter
!=
effective bash availability
```

because `bash.enabled` independently gates the built-in tool.

The policy:

```text
bash unavailable
→ no normal VERIFIED PASS
→ REFUSE or explicit UNVERIFIED
```

is the correct v0 behavior.

The only cleanup is epistemic.

Round 8's closure table says:

```text
bash_disabled_cannot_report_normal_verified_PASS: true
```

while the same response acknowledges:

```text
whether preflight can read the effective Verifier tool set before dispatch
still needs Phase-00 verification
```

and CR-35 already established that schema output alone cannot mechanically attest tool execution.

Until a runtime capability preflight/provenance mechanism is measured, use:

```text
MUST NOT report normal VERIFIED PASS
```

rather than:

```text
cannot report PASS
```

unless there is an actual mechanical rejection path.

This is a P2 wording/epistemic correction, not a reason by itself to continue static architecture review.

## Status

```yaml
CR-43:
  design: PASS
  wording_cleanup: required
  blocking_static_close: false
```

---

# 4. SC-01 — P2 source correction
# Patch-mode zero-change `apply=false` does not use the summary text Round 8 claims

Round 8 states:

```text
apply=false + no changes
→ "Isolation: no changes captured."
```

That is not true for OMP patch mode.

## Source trace

`isolation-runner.ts` patch mode always calls:

```ts
writeIsolationPatch(...)
```

on a successful isolated run.

`writeIsolationPatch()` always creates:

```text
<artifactsDir>/<agentId>.patch
```

and returns `patchPath`, even when the root patch is an empty string.

Then `structured-subagent.ts` applies this branch order:

```ts
if (result.branchName) ...
else if (result.patchPath)
    "Isolation: changes captured at <path> (apply=false). Not applied."
else if (nestedPatches.length > 0) ...
else
    "Isolation: no changes captured."
```

Therefore in successful **patch mode**, zero-diff `apply=false` still has `result.patchPath` and the model-facing text is:

```text
Isolation: changes captured at <path> (apply=false). Not applied.
```

not:

```text
Isolation: no changes captured.
```

## Important nuance

This does **not** destroy the proposed prefix discriminator.

The source still supports:

```text
successful apply=false isolated path
→ mergeSummary begins with / contains "Isolation:"

successful apply=true zero-change path
→ "No changes to apply."
```

So:

```text
prefix/category discrimination
```

can remain a Phase-00 characterization hypothesis.

The spec should not hard-code the wrong exact patch-mode string.

## Required correction

E3-I should assert semantic class:

```yaml
apply_false:
  expected_summary_class: isolation_capture
  expected_marker: "Isolation:"

apply_true_zero_change:
  expected_summary_class: apply_path
  expected_marker_absent: "Isolation:"
```

and record exact text separately.

## Status

```yaml
SC-01:
  severity: P2
  blocking_static_close: false
```

---

# 5. CR-44 — NEW P1
# `tools: [read]` is NOT the child's actual tool surface

```yaml
id: CR-44
severity: P1
class:
  - CANARY_CAPABILITY_WIDENING
  - FALSE_NON_MUTATION_GUARANTEE
  - TASK_EXECUTOR_CONTRACT_GAP
related:
  - CR-38
  - CR-42
```

This is the load-bearing Round-9 finding.

Round 8's CR-42 remedy says:

```yaml
isolation_canary:
  tools:
    - read
  blocking: true
```

and concludes:

```text
mechanically impossible to write
parent file side effects: zero
parent HEAD side effects: zero
```

That conclusion is false under the ordinary OMP task/subagent execution path.

---

# 6. OMP automatically adds `hub` to ordinary explicit agent tool lists

OMP v17.2.10 `task/executor.ts`:

```ts
let toolNames: string[] | undefined;

if (agent.tools && agent.tools.length > 0) {
    toolNames = agent.tools;
    ...
}

// Ordinary agents retain the host's always-on collaboration capability.
if (
    toolNames
    && !options.restrictToolNames
    && !toolNames.includes("hub")
) {
    toolNames = [...toolNames, "hub"];
}
```

Therefore:

```yaml
frontmatter:
  tools:
    - read
```

normally becomes:

```yaml
effective_host_tools:
  - read
  - hub
```

before child-session creation.

This is not hypothetical or an optional discovery path.

It is explicit executor behavior.

---

# 7. Normal TaskTool does not give this canary a per-spawn `restrictToolNames=true`

`structured-subagent.ts` resolves:

```ts
const restrictToolNames =
    policy.planMode
    || session.restrictToolNames === true;
```

and forwards that to the executor.

For an ordinary Orchestrated workflow:

```text
planMode = false
parent session restrictToolNames = normally false
```

so:

```text
restrictToolNames = false
```

and `hub` is auto-added.

The model-facing task item does not expose a per-item:

```text
restrictToolNames
```

field that the spec can put on only the canary dispatch.

Thus declaring:

```yaml
tools: [read]
```

does not create the restricted child session Round 8 assumes.

---

# 8. `hub` is not a harmless read-only primitive

OMP's own `read-only-policy.ts` includes:

```text
hub
```

inside `READ_ONLY_TOOL_NAMES`.

That classifier is based on declared tool approval categories.

It is **not** sufficient to prove filesystem immutability.

OMP's Hub documentation exposes process operations including:

```text
start
stop
restart
send-to-process
```

and states those process operations are `exec`.

`hub op:start` can launch an application with:

```text
cwd = session directory
```

by default.

OMP settings define:

```yaml
launch.enabled:
  default: true
```

so normal sessions allow this process surface unless the user disabled it.

A process launched in the isolated session directory can write files.

Therefore the actual canary can be:

```text
read
hub
```

and `hub` can indirectly produce filesystem changes.

If effective:

```text
task.isolation.apply == true
```

those changes can then enter the normal merge/apply path.

This directly breaks the Round-8 assertion:

```text
read-only tool surface → mechanically impossible to write
```

---

# 9. The OMP "read-only agent" classifier does not rescue CR-42

OMP's read-only policy contains:

```ts
READ_ONLY_TOOL_NAMES = {
  read,
  grep,
  glob,
  ...,
  hub,
  ...
}
```

and says an agent is read-only when its **declared** tools are all in that set.

This produces an important distinction:

```text
OMP read-only policy classification
!=
proof that no side-effect-capable path exists
```

`hub` demonstrates the mismatch.

Do not use:

```text
isReadOnlyAgent(canary) == true
```

as evidence that the canary cannot mutate its isolated worktree.

---

# 10. Consequence for CR-42

The Round-8 non-mutating canary has two separate properties:

## A. Behavioral intent

```text
canary prompt asks for no edits
```

Likely fine.

## B. Mechanical guarantee

```text
canary has no capability that can mutate state
```

False.

Round 8 explicitly claims B.

That makes CR-42 still open.

---

# 11. Correct resolution options

There is no need to discard same-session attestation as a concept.

But the production gate needs a real mechanism.

## Option A — preferred if runtime/helper enhancement is acceptable

Provide a genuinely restricted canary invocation where:

```text
restrictToolNames=true
```

and the effective tool set is exactly the intended safe set plus required hidden completion machinery.

Important:

```text
normal TaskTool wire does not expose this per-spawn today
```

so this requires an OMP/runtime/template helper path, not merely frontmatter.

Before adopting, source-verify the exact invocation path.

## Option B — direct same-session settings introspection

Use an in-process extension/custom capability that reads the **actual parent session's** effective:

```text
task.isolation.apply
```

instead of inferring it with a child.

This would be cleaner than any behavioral canary if OMP exposes the required session/settings handle to the chosen extension/tool API.

Do not write this into the spec as fact until that API path is source-verified.

The current generic ExtensionContext documentation does not itself establish a `session.settings.get(...)` surface.

## Option C — fail closed until one of A/B exists

If the template cannot mechanically read the parent setting or launch a truly restricted canary:

```text
parallel capture-first mode remains unavailable by default
```

and Phase-00 E3-I becomes a characterization experiment for a future implementation mechanism.

This is conservative but honest.

---

# 12. What NOT to do

## Do not only set `launch.enabled=false`

That removes Hub process start, but:

- it changes an unrelated user capability setting;
- Hub remains auto-added;
- Hub still has coordination/message side effects;
- it is another settings blast-radius dependency;
- it still does not make `tools:[read]` mean what the spec says.

It may reduce risk but does not repair the contract.

## Do not rely on the canary model "not using hub"

That turns the mechanical safety guarantee into behavioral compliance.

The entire point of the CR-42 rewrite was to avoid that class of guarantee.

## Do not call the canary mechanically read-only because `isReadOnlyAgent()` says so

Approval taxonomy is not a filesystem-sandbox proof.

---

# 13. Phase-00 E3-I should explicitly test effective canary tools

Whichever mechanism is selected, E3-I must record the child/tool surface.

For a genuinely restricted child, assert:

```text
no hub
no bash
no write
no edit
no launch
no process-start-capable custom/extension tool
```

and separately assert:

```text
parent git status before == after
parent HEAD before == after
```

under both:

```text
apply=false
apply=true
```

If Hub appears in the production canary, the mechanical non-mutation acceptance gate fails.

---

# 14. Support-agent taxonomy note

Round 8 says:

```text
isolation-canary may live in .omp/agents
but is a support/preflight agent, not a workflow worker
```

That classification is fine for topology/counting purposes.

It does **not** create a runtime privilege class.

OMP discovers it as a normal agent definition and runs it through the normal executor unless a different invocation path is explicitly implemented.

The spec must keep these separate:

```text
semantic role classification: support agent
runtime execution class: ordinary TaskTool child unless otherwise implemented
```

CR-44 is about the second line.

---

# 15. Re-evaluation of static closure

## CR-41

```yaml
verdict: PASS_ON_DESIGN
```

## CR-43

```yaml
verdict: PASS_WITH_P2_WORDING_CLEANUP
```

Required wording:

```text
bash unavailable → workflow MUST NOT report normal VERIFIED PASS
```

Do not claim impossibility until the runtime preflight/provenance mechanism makes it impossible.

## CR-42

```yaml
verdict: PARTIAL_REJECT
dependency: CR-44
```

## CR-44

```yaml
verdict: NEW_P1
blocking_static_close: true
```

---

# 16. Exact Round-9 acceptance gate

Static review closes when one of the following is source-backed:

### Path 1 — restricted child

```yaml
canary:
  effective_tool_surface:
    hub: absent
    bash: absent
    write: absent
    edit: absent
    side_effecting_extensions: absent_or_blocked
  restrict_mechanism: source_verified
  same_session_apply_attestation: E3_I
```

### Path 2 — direct parent-session introspection

```yaml
preflight:
  reads_actual_parent_session_settings: true
  setting: task.isolation.apply
  source_path: documented_and_verified
  child_canary_required: false
```

### Path 3 — fail closed

```yaml
parallel_orchestrated:
  enabled_without_safe_authority_mechanism: false
```

Then Phase-00 can evaluate a future mechanism without pretending production parallel mode is already safe.

---

# 17. Stop rule

This is the last static round.

After CR-44 is resolved and SC-01 / CR-43 wording are corrected:

```yaml
static_spec_review: CLOSED
ready_for_phase_00_experiments: true
ready_for_feature_implementation: false
```

Do not perform another broad static search.

Only reopen architecture if:

```text
Phase-00 experiment
or
the CR-44 patch itself
```

produces a concrete new P0/P1 contradiction.

---

# 18. Required Opus response

Respond only to:

```text
CR-44
SC-01
CR-43 wording
static closure
```

Protocol:

```yaml
id:
response: ACCEPT | REBUT | PARTIAL | STABLE_DISAGREEMENT
severity:
source_evidence:
exact_patch:
runtime_mechanism:
experiment:
acceptance_check:
remaining_uncertainty:
```

---

# 19. Final verdict

Round 8 is very close, but the CR-42 closure rests on a false runtime assumption:

```text
agent frontmatter tools:[read]
→ child has only read
```

OMP v17.2.10 explicitly widens that tool list with `hub` for ordinary agents.

Because Hub can start processes when `launch.enabled=true` (the default), the canary is not mechanically non-mutating.

That is a real P1 safety-contract gap in the exact mechanism chosen to close the final P1 safety finding.

Therefore:

```yaml
start_round_9: true
round_9_scope: CR-44 + two small source/wording corrections only

static_review_after_round_9_if_clean: CLOSED
next_action_after_closure: Phase_00 experiments
```
