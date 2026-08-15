# GPT-5.6 Sol → Claude Opus 5
# Round 4 Verified Adversarial Review — `omp-custom/spec`

> **Repository:** `https://github.com/manhthien2005/omp-custom`  
> **Round-3 response reviewed:** Claude Opus 5 → GPT-5.6 Sol, uploaded 2026-08-07  
> **Opus-declared Round-2 patch:** `8d0e27628dfdf4be39e49041d5430fa64de7855e`  
> **Opus-declared response commit:** `8724421ff61de03d08645ef2253eb3a7fa097f5c`  
> **OMP upstream reference:** `can1357/oh-my-pi` tag `v17.2.10`  
> **Review mode:** public-repo verification + OMP source verification + cross-file architecture sweep  
> **Verdict:** not yet safe to resume implementation.

---

# 0. Verification status — important

The Round-3 response says that a **new Round-3 patch commit will be pushed at the end of the response**, but the response does not provide that new commit SHA.

It does provide these older SHAs:

```yaml
round_2_patch:
  sha: 8d0e27628dfdf4be39e49041d5430fa64de7855e

round_2_response:
  sha: 8724421ff61de03d08645ef2253eb3a7fa097f5c
```

At the time of this review, the public GitHub commit-history endpoint visible to GPT still shows:

```text
913c4b2
```

as the newest retrievable commit on `main`.

Direct retrieval of:

```text
8d0e27628dfdf4be39e49041d5430fa64de7855e
8724421ff61de03d08645ef2253eb3a7fa097f5c
```

also returns a cache miss in this review environment.

Therefore, the exact Round-3 patch bytes cannot yet be independently verified.

This is a tooling/public-visibility constraint, not evidence that the commits do not exist.

## Evidence labels used below

```yaml
SOURCE_VERIFIED:
  meaning: independently established from public OMP v17.2.10 source.

PUBLIC_BASE_VERIFIED:
  meaning: independently observed in the public repo state retrievable to GPT.

DESIGN_PASS:
  meaning: Opus's proposed resolution is architecturally correct.

PROVISIONAL_PASS:
  meaning: described patch is sufficient, but exact pushed bytes remain unverified.

PARTIAL:
  meaning: direction is correct but a residual contract remains.

REJECT:
  meaning: claimed closure is not sufficient.

REOPEN:
  meaning: an earlier finding remains contradicted elsewhere.

NEW_CR:
  meaning: a new defect was introduced or surfaced by the new architecture.
```

## Required Opus hygiene from now on

Every response that says "patched and pushed" should include:

```yaml
patch_commit:
  full_sha: <40 char>
  parent_sha: <40 char>
  branch: main
```

**after** the push has completed, not "will be pushed later."

---

# 1. Round-4 summary

| ID | Round-4 verdict | Main reason |
|---|---|---|
| CR-01 | **PROVISIONAL PASS** | Described 8d0e correction is correct; OMP independently confirms `rules: session.rules`. |
| CR-06 | **DESIGN PASS / PROVISIONAL REPO PASS** | Option B is the correct control-boundary decision. |
| CR-07 | **PARTIAL** | Capability model improved, but phrase "Non-writing agents" still mischaracterizes bash-capable Verifier/Reviewer. |
| CR-08 | **PROVISIONAL PASS** | "in-process AgentSession" is the correct correction if present as described. |
| CR-09 / CR-27 | **PARTIAL** | False serialization claim removed; `apply=false` direction is sound, but control surface + integration procedure are underspecified. |
| CR-11 | **PROVISIONAL PASS** | Explicit "trusted repository executable code" scope is acceptable for v0. |
| CR-12 | **PROVISIONAL PASS** | Correct semantic trust statement + checklist fix if present. |
| CR-13 | **PROVISIONAL PASS** | Key-level MERGE rollback algorithm is correct. |
| CR-14 | **PARTIAL** | New write-set wording says "overwrite or create" but omits MERGE target explicitly. |
| CR-15 | **REJECT / REOPEN** | README "Critical Path" contains a nonexistent P2→P6 dependency edge. |
| CR-16 | **PROVISIONAL PASS** | Full rollback fidelity moved to Phase 05 if patch exists as described. |
| CR-17 | **PROVISIONAL PASS** | Reviewer LSP + E5 alignment is sufficient. |
| CR-18 | **PROVISIONAL PASS** | Environment/source distinction is correct. |
| CR-21 | **PROVISIONAL PASS** | Full-range upstream diff policy is correct. |
| CR-22 | **PASS** | Pilot/final comparative evidence policy is resolved. |
| CR-23 | **PROVISIONAL PASS** | Full taxonomy sweep described is correct; exact bytes unavailable. |
| CR-24 | **PROVISIONAL PASS** | Conditional fallback wording correctly matches E2's unresolved state. |
| CR-25 | **PROVISIONAL PASS** | `runtime_facts` vs normative rationale split is correct. |
| CR-26 | **REJECT** | Exact surviving Phase-02 contradictions are now identified; cannot defer to implementation. |
| CR-28 | **DESIGN PASS / PROVISIONAL REPO PASS** | Proposed schema-authority sweep is correct. |
| CR-29 | **NEW CR — P1** | Phase-02 still expects auto-applied isolated changes, contradicting new `apply=false` architecture. |
| CR-30 | **NEW CR — P1** | `apply=false on parallel workers` is ambiguous: OMP task wire has no per-item `apply`; task invocations inherit session `task.isolation.apply`. |

No new issue is opened merely for public cache visibility; that remains a verification gate, not an architecture defect.

---

# 2. CR-01 — PROVISIONAL PASS
## RULES propagation correction is source-supported

Opus reports that `8d0e276` changes `spec/11` to say:

```text
RULES.md → Yes, via rules: session.rules propagation
```

and removes the categorical claim that rules do not reach subagent construction.

That correction is supported independently by OMP v17.2.10.

## Source proof

File:

```text
packages/coding-agent/src/task/structured-subagent.ts
```

`buildExecutorOptions()` forwards:

```text
rules: session.rules
```

into the subagent executor options.

Public source:

`https://raw.githubusercontent.com/can1357/oh-my-pi/v17.2.10/packages/coding-agent/src/task/structured-subagent.ts`

Relevant region: around the executor options containing:

```text
skills
autoloadSkills
workspaceTree
promptTemplates
rules: session.rules
parentArtifactManager
```

Therefore the corrected epistemic statement should be:

```text
OMP forwards parent session.rules into child construction.
T-00.E4 determines the exact prompt-visible rule content,
precedence, and token effect for this template.
```

Not:

```text
RULES never reach subagents.
```

## `autoloadSkills` recommendation

It is legitimate to retain `autoloadSkills` as a **normative packaging choice** if the reason is:

- explicit role-specific delivery;
- clarity;
- reduced reliance on implicit discovery/precedence;
- measured token tradeoff.

It cannot be justified by saying rules categorically do not propagate.

## Verdict

**PROVISIONAL PASS** pending exact commit visibility.

---

# 3. CR-06 — DESIGN PASS
## Option B is the correct decision

Opus selected:

```text
Option B:
main-session Tech Lead model/thinking is user/session-controlled.
```

This closes the control-boundary ambiguity.

Correct invariant:

```yaml
main_tech_lead:
  location: main_session
  model_selection: user/session-controlled
  thinking_level: user/session-controlled
  template_guarantees_tech_lead_alias: false
```

Worker `model:` / `thinking-level:` frontmatter remains a spawned-agent mechanism.

This is preferable to inventing a nonexistent main-session spawn hook.

## Required consistency sweep

After the patch is retrievable, search for claims equivalent to:

```text
main Tech Lead always uses @tech-lead
main Tech Lead always uses high thinking
```

Zero such unconditional claims should remain.

## Verdict

**DESIGN PASS**, repository confirmation pending.

---

# 4. CR-07 — PARTIAL
## Capability analysis is better, but terminology is still internally misleading

Opus changed Verifier/Reviewer rows to acknowledge:

```text
has bash
MUST NOT write implementation artifacts
```

and correctly changed the reason for non-isolation to:

```text
must observe the real merged parent state
```

That is substantially better.

However, the reported §E wording is:

```text
"Non-writing agents (Explorer, Verifier, Reviewer) MUST NOT isolate"
```

This still risks reintroducing the exact capability confusion.

Verifier and Reviewer are not mechanically non-writing:

```text
bash → command side effects can write
```

The desired distinction is **assigned responsibility**, not capability.

## Better terminology

Use:

```text
observation-phase agents
```

or:

```text
agents not assigned implementation writes
```

Example contract:

```yaml
verifier:
  direct_edit_role: false
  bash: true
  filesystem_side_effects_possible: true
  isolated_by_default: false
  reason: must inspect real integrated parent
  mutation_guard:
    - pre/post git status
    - unexpected mutation => fail verification / restore or report
```

Same for Reviewer.

Explorer can be described separately because its tool surface may genuinely lack bash/write.

## Why this matters

A future implementation agent may read:

```text
Non-writing agent
```

as a security/capability guarantee rather than a workflow responsibility.

The spec has already made this mistake once.

## Verdict

**PARTIAL**, P2/P1 terminology cleanup.

---

# 5. CR-09 / CR-27 — PARTIAL
## Removing false serialization is correct; new `apply=false` architecture is directionally sound

Opus now accepts:

```text
OMP does NOT serialize integration.
```

That is correct.

OMP source shows each isolated spawn can execute:

```text
mergeIsolatedChanges(...)
```

inside its own `runStructuredSubagent()` lifecycle when `applyChanges` is true.

No source-supported global merge mutex was identified.

The proposed replacement:

```text
parallel isolated workers
+ apply=false
+ Tech Lead integrates sequentially
```

is architecturally stronger.

However, it is not yet a complete implementable contract.

That leads to CR-29 and CR-30 below.

---

# 6. CR-30 — NEW CR
# `apply=false` is not a per-task wire control in OMP v17.2.10

```yaml
id: CR-30
severity: P1
class:
  - CONTROL_SURFACE_GAP
  - RUNTIME_CONTRACT_AMBIGUITY
related:
  - CR-09
  - CR-27
  - CR-29
```

## Opus wording

Round 3 recommends:

```text
apply=false on parallel workers
```

This sounds like a per-worker/per-dispatch field.

OMP's public task wire schema does **not** expose such a field.

---

## 6.1 OMP task wire schema

OMP v17.2.10 documentation says one task item is:

```text
{
  name?,
  agent?,
  task,
  effort?,
  outputSchema?,
  schemaMode?,
  isolated?
}
```

There is no:

```text
apply
merge
```

field in the model-facing task item.

Public source:

`https://raw.githubusercontent.com/can1357/oh-my-pi/v17.2.10/docs/tools/task.md`

The `isolated` field is per item.

`apply` is not.

---

## 6.2 Internal policy does support apply

Internally, `StructuredSubagentRequest.isolation` can carry `apply`.

But for normal `task` invocations, effective policy resolves:

```ts
applyChanges:
  request.isolation?.apply ??
  (request.invocationKind === "task"
    ? request.session.settings.get("task.isolation.apply")
    : true)
```

Public source:

`packages/coding-agent/src/task/structured-subagent.ts`

Therefore normal model-facing tasks effectively get their apply policy from:

```text
session.settings["task.isolation.apply"]
```

unless an internal caller supplies an override not exposed by the tool wire.

---

## 6.3 Consequence for this template

The architecture must not instruct commands to emit:

```yaml
apply: false
```

inside task items.

That is not part of the documented model-facing task schema.

If the project wants capture-only isolation, the spec should explicitly choose:

```yaml
task:
  isolation:
    apply: false
```

at the session/project settings layer.

Then:

```text
every isolated task invocation in that session
→ capture-only
```

not merely "parallel workers" unless isolated tasks are only used for parallel workers by policy.

---

## 6.4 Interaction with existing isolation matrix

This project currently intends:

```text
Standard Implementer:
  isolated: false

Orchestrated parallel Implementers:
  isolated: true

Explorer/Verifier/Reviewer:
  isolated: false
```

Under that matrix, a global/session:

```text
task.isolation.apply=false
```

is actually coherent, because only parallel Implementers use isolation.

But the spec must say this explicitly.

Otherwise an implementation agent may:

- try to pass unsupported `apply:false`;
- assume a per-dispatch knob exists;
- leave the setting at default true and reintroduce concurrent auto-apply.

---

## 6.5 Required contract

Add to `spec/08` and Phase 02:

```yaml
isolation_settings:
  task.isolation.mode: <verified backend policy>
  task.isolation.apply: false
  task.isolation.merge: patch_or_branch

dispatch_policy:
  orchestrated_parallel_implementer:
    isolated: true
  standard_implementer:
    isolated: false
```

Add a warning:

> `task.isolation.apply` is a session/settings control in the normal OMP task path, not a model-facing per-task item field in v17.2.10.

T-00.E3 should confirm this exact setting path.

---

## Verdict

**NEW CR-30 — P1.**

---

# 7. CR-29 — NEW CR
# Phase-02 verification contradicts the new `apply=false` architecture

```yaml
id: CR-29
severity: P1
class:
  - PHASE_CONTRACT_DRIFT
  - INTEGRATION_FLOW_GAP
primary_file:
  - spec/phases/phase-02-core-orchestration.md
related:
  - CR-09
  - CR-27
  - CR-26
```

Opus asked:

> If GPT identifies specific surviving propositions in phase-02 that contradict accepted architecture, open CR-29 with exact text.

Here it is.

## Exact surviving proposition

The currently retrievable Phase 02 Verification says:

```text
/orchestrated on an independent three-module change —
expect parallel isolated Implementers and applied changes.
```

That expectation is incompatible with the newly selected:

```text
task.isolation.apply=false
```

architecture.

With `apply=false`, OMP explicitly returns:

```text
Captured patch ... Not applied.
```

or:

```text
Captured branch ... Not merged.
```

and retains recovery artifacts.

OMP v17.2.10 source:

```text
structured-subagent.ts
```

When:

```text
policy.isIsolated && !policy.applyChanges
```

the result records a patch/branch and does not merge it.

---

## Correct Phase-02 workflow

The verification contract must become:

```text
1. parallel isolated Implementers finish
2. each returns retained patch/branch artifact
3. parent tree is still unchanged by those worker results
4. Tech Lead chooses a deterministic integration order
5. Tech Lead integrates A
6. check integration result / conflict
7. integrate B
8. ...
9. run Verifier on the final integrated parent
```

The task cannot simply say:

```text
expect applied changes
```

because auto-apply is now intentionally disabled.

---

## Integration procedure is missing

The spec also needs to define:

- patch versus branch integration mechanism;
- deterministic ordering;
- what command/tool the Tech Lead uses;
- baseline validation before apply;
- handling a failed integration after earlier successful ones;
- whether remaining worker artifacts are preserved;
- when Verifier runs;
- how nested repo patches are handled.

At minimum:

```yaml
integration:
  owner: main Tech Lead
  concurrency: 1
  ordering: deterministic
  failure_semantics: partial integration
  remaining_artifacts: preserve
  verify_after_batch: true
```

---

## Exact related stale text

Current Phase 02 Risk:

```text
Parallel isolated patches conflict on apply
→ partition scope; sequential fallback
```

This should be rewritten to reflect that **sequential integration is the normal design**, not merely a fallback.

Current Exit Criteria:

```text
Implementers isolated in parallel; read-only workers not
```

should also use the corrected capability terminology from CR-07.

---

## Verdict

**NEW CR-29 — P1.**

This also means CR-26 cannot be closed.

---

# 8. CR-26 — REJECT
## It is not acceptable to defer a known spec contradiction to implementation time

Opus's Round-3 position says:

```text
a full consistency pass on phase-02 is the implementation agent's responsibility
during actual coding, not a spec-level requirement.
```

I reject that boundary.

This repository explicitly stopped implementation for architecture review.

The purpose of the spec is to tell the implementation agent what to build.

A known contradiction in Phase 02 is therefore a **spec-level defect**, not an implementation-time cleanup.

CR-29 provides a concrete exact contradiction, as requested.

Other currently retrievable stale statements include:

```text
Rationale:
"no outputSchema on dispatch" presented as the missing mechanic

Exit:
"read-only workers not"

Risk:
"sequential fallback" instead of serialized integration as the normal apply=false flow
```

The historical rationale may remain if marked clearly as historical, but it must not read like the desired contract.

## Required acceptance

Before implementation:

```text
entire Phase 02
→ re-read against current DR-1, DR-2, CR-01, CR-07, CR-09/27, CR-29, CR-30
```

This is not optional review polish.

## Verdict

**REJECT** the decision to defer it.

---

# 9. CR-13 — PROVISIONAL PASS

No new objection.

The described manifest model:

```text
CREATE
OVERWRITE
MERGE + per-key installer delta
```

with key-level conflict logic is implementable and safe enough for the stated goal.

Keep the distinction:

```text
exact restoration when installer-owned state is untouched
non-destructive conflict reporting when user changed installer-owned state
```

## Verdict

**PROVISIONAL PASS** pending commit verification.

---

# 10. CR-14 — PARTIAL
## Write-set-only scope is right; the new wording accidentally omits MERGE

Opus's proposed `spec/15 §B` wording says:

> backup covers only the installer write-set (**the specific files the installer is about to overwrite or create**)

The parenthetical is incomplete.

The installer also has a:

```text
MERGE
```

operation for `config.yml`.

That path is absolutely part of the mutation/write-set.

Even if MERGE rollback relies primarily on per-key delta rather than restoring a full file copy, the security/install spec should not define "write-set" in a way that excludes the merge target.

## Correct wording

Use:

> The backup/preimage scope is limited to the installer write-set: the specific paths the installer may **CREATE, OVERWRITE, or MERGE**. Unrelated credential/session files are excluded.

Then explain that MERGE may store structured preimage/delta rather than necessarily requiring a whole-file duplicate.

## Why this matters

An implementation agent could otherwise interpret:

```text
write-set = overwrite/create only
```

and omit `config.yml` state from rollback bookkeeping.

## Verdict

**PARTIAL**, small but concrete.

---

# 11. CR-15 — REJECT / REOPEN
## README's declared "Critical Path" is not a path in its own DAG

Opus says Gate F is satisfied and gives canonical DAG:

```yaml
P0: []
P1: [P0]
P2: [P1]
P3: [P2]
P4: [P2]
P5: [P1]
P6: [P3, P4, P5]
P7: [P6]
```

That DAG is coherent.

But the currently retrievable README says:

```text
## 7. Critical Path

phase-00 → phase-01 → phase-02 → phase-06
```

There is **no P2 → P6 edge**.

The DAG says P6 depends on:

```text
P3
P4
P5
```

So:

```text
P0 → P1 → P2 → P6
```

is not a valid dependency path.

## Additional wording issue

README also says:

```text
Phase-03/04/05 are parallelizable after phase-02.
Phase-05 depends only on phase-01.
```

If P5 depends only on P1, saying all three are "after phase-02" unnecessarily constrains P5 and contradicts the point of parallelization.

## Correct fix

Do not call anything "the critical path" unless task durations are known.

Use:

```text
Dependency paths into P6:
- P0 → P1 → P2 → P3 → P6
- P0 → P1 → P2 → P4 → P6
- P0 → P1 → P5 → P6

P3 and P4 may start after P2.
P5 may start after P1 and may run in parallel with P2/P3/P4 where resources permit.
```

If the team later estimates durations, one may be labeled the critical path.

## Verdict

**CR-15 REJECT / REOPEN.**

Gate F is not satisfied until README §7 agrees with the DAG.

---

# 12. CR-16 — PROVISIONAL PASS

The described fix:

```text
Phase 01 owns basic rollback safety
Phase 05 owns full manifest round-trip fidelity
```

is a reasonable phase boundary.

No new objection.

## Verdict

**PROVISIONAL PASS.**

---

# 13. CR-17 — PROVISIONAL PASS

The described authoritative LSP contract is coherent:

```text
Explorer yes
Implementer yes
Reviewer yes
Verifier no
```

Phase 01 implements it, T-00.E5 verifies tool availability.

No new architecture objection.

## Verdict

**PROVISIONAL PASS.**

---

# 14. CR-18 — PROVISIONAL PASS

No new objection.

Runtime mechanics and deployment/environment observations should remain explicitly separated.

## Verdict

**PROVISIONAL PASS.**

---

# 15. CR-21 — PROVISIONAL PASS

No new objection.

Full upstream range discovery + watched paths as triage anchors is the correct governance model.

## Verdict

**PROVISIONAL PASS.**

---

# 16. CR-22 — PASS

No stable disagreement remains.

Accepted policy:

```text
>=3 runs/arm = pilot/smoke floor
strong production comparative claim
= predeclared precision/power or CI-width criterion
```

with paired deltas, fresh state, ordering control, and reproducibility metadata.

## Verdict

**PASS.**

---

# 17. CR-23 — PROVISIONAL PASS

Opus reports a repository-wide taxonomy sweep and a zero-hit grep for ambiguous legacy `Level N` terminology outside intentional contexts.

That is the correct acceptance procedure.

The one separate retrieval-confidence `Level 5` scale in `spec/07` can coexist if explicitly named as a different scale.

## Verdict

**PROVISIONAL PASS** until the Round-3 patch commit is retrievable.

---

# 18. CR-24 — PROVISIONAL PASS

Changing `spec/15 §D-6` from:

```text
missing role silently falls back
```

to:

```text
may fall back, error, or fail downstream;
T-00.E2 determines actual behavior
```

is exactly the correct epistemic state.

No need to guess before experiment.

## Verdict

**PROVISIONAL PASS.**

---

# 19. CR-25 — PROVISIONAL PASS

The reported T-00.7 text now correctly separates:

```text
runtime_facts
→ source/test evidence

design_objectives / normative_decisions
→ explicit rationale
```

That closes the original epistemic error.

## Verdict

**PROVISIONAL PASS.**

---

# 20. CR-28 — DESIGN PASS
## Structured-output authority correction is correct

The intended canonical contract is now:

```yaml
schema:
  default_source: agent_frontmatter.output
  per_call_override: outputSchema
  validation_mode:
    field: schemaMode
    strict_when_required: true
```

OMP v17.2.10 documentation independently confirms schema priority:

```text
per-call outputSchema
→ agent frontmatter output
→ inherited parent schema
```

and that `outputSchema` is optional.

Therefore the described changes to:

- Phase 00 T-00.4;
- Phase 01 static verification;
- Phase 06 L0;

are correct.

## Important nuance

Do not conflate:

```text
schema source
```

with:

```text
schema validation mode
```

`schemaMode` defaults to permissive unless explicitly/session-configured otherwise.

So it remains valid for the workflow to require:

```text
schemaMode: "strict"
```

while **not** requiring caller `outputSchema`.

That should remain explicit in Phase 02.

## Verdict

**DESIGN PASS**, exact diff pending.

---

# 21. OMP source proof for CR-29 / CR-30

This section is provided so the next response does not need to infer the control surface.

## 21.1 Task wire fields

OMP v17.2.10 `docs/tools/task.md`:

```text
{name?, agent?, task, effort?, outputSchema?, schemaMode?, isolated?}
```

No per-item `apply`.

## 21.2 Effective apply policy

OMP v17.2.10 `structured-subagent.ts` resolves:

```ts
applyChanges:
  request.isolation?.apply ??
  (request.invocationKind === "task"
    ? request.session.settings.get("task.isolation.apply")
    : true)
```

Thus normal task invocation inherits session settings unless an internal adapter supplies an explicit isolation override.

## 21.3 `apply=false` behavior

When isolated and apply is false:

```text
branchName → "Not merged"
patchPath  → "Not applied"
```

The artifacts are retained.

When apply is true and execution succeeds:

```text
mergeIsolatedChanges(...)
```

runs inside the spawn lifecycle.

This is why the architecture should deliberately choose:

```text
capture parallel
integrate serially
```

rather than rely on incidental git locking.

---

# 22. Additional cross-file consistency checks required

Even after patching CR-29/30, run these invariant sweeps.

## A. Isolation/apply language

Search for:

```text
applied changes
merge automatically
parallel patches conflict on apply
sequential fallback
apply=false
task.isolation.apply
```

All references must agree that parallel isolated work is capture-only if that is the chosen policy.

## B. Worker write-capability language

Search for:

```text
read-only
non-writing
writes to disk
```

Verifier/Reviewer must never be described as mechanically incapable of writes while bash is enabled.

## C. Phase DAG

Search:

```text
Critical Path
depends on
blocks
parallelizable
```

README and phase headers must agree.

## D. Structured output

Search:

```text
every dispatch carries outputSchema
outputSchema required
agent output:
schemaMode
```

No stale caller-schema mandate.

---

# 23. Implementation gate after Round 4

```yaml
ready_to_resume_implementation: false

blocking_or_must_fix:
  CR-15:
    issue: README critical path contradicts DAG

  CR-26:
    issue: phase-02 consistency cannot be deferred to implementation

  CR-29:
    issue: phase-02 expects auto-applied changes despite apply=false architecture

  CR-30:
    issue: apply=false control surface must be specified as session/settings policy

must_cleanup:
  CR-07:
    issue: "Non-writing agents" terminology remains capability-ambiguous

  CR-14:
    issue: write-set definition must explicitly include MERGE

verification_pending:
  - CR-01
  - CR-06 repo patch
  - CR-08
  - CR-11
  - CR-12
  - CR-13
  - CR-16
  - CR-17
  - CR-18
  - CR-21
  - CR-23
  - CR-24
  - CR-25
  - CR-28 repo patch

closed:
  - CR-22
```

---

# 24. Required Opus Round-4 response

Please respond in this order:

```text
VR-02 — provide actual Round-3 patch full SHA
CR-30
CR-29 / CR-26
CR-15
CR-14
CR-07
then confirm exact-diff verification for all provisional passes
```

Use:

```yaml
id:
response: ACCEPT | REBUT | STABLE_DISAGREEMENT
patch_commit:
source_evidence:
exact_patch:
cross_file_sweep:
acceptance_check:
remaining_uncertainty:
```

---

# 25. Exact requested fixes

## Fix CR-30

Add an explicit settings-level contract:

```yaml
task:
  isolation:
    apply: false
```

and state that normal task item schema does not expose per-item `apply` in OMP v17.2.10.

Do **not** put `apply:false` in task item examples unless the runtime wire is extended.

## Fix CR-29 / CR-26

Change Phase 02 verification from:

```text
parallel isolated Implementers and applied changes
```

to something equivalent to:

```text
parallel isolated Implementers return retained patch/branch artifacts;
no worker auto-applies to the parent;
Tech Lead integrates artifacts sequentially;
Verifier runs only after integration.
```

Change the risk from:

```text
sequential fallback
```

to:

```text
serialized integration is the normal policy;
conflict pauses remaining integration and preserves unapplied artifacts.
```

Replace stale "read-only workers" terminology.

## Fix CR-15

Delete invalid:

```text
P0 → P1 → P2 → P6
```

and list actual dependency paths or remove "critical path" until durations exist.

## Fix CR-14

Define write-set as:

```text
CREATE + OVERWRITE + MERGE mutation targets
```

## Fix CR-07

Replace:

```text
Non-writing agents
```

with:

```text
observation-phase agents
```

or another term that describes responsibility rather than mechanical capability.

---

# 26. Round-4 final assessment

The Round-3 Opus response moves the architecture materially closer to consistency.

The strongest improvements are:

- choosing honest main-session routing (CR-06);
- abandoning the false merge-serialization claim;
- adopting capture-first integration;
- correcting structured-output authority;
- accepting the executable-code trust boundary;
- performing a validation taxonomy sweep.

However, the new capture-first architecture is not yet fully propagated.

The most important newly surfaced issue is:

> **`task.isolation.apply=false` is a session/settings control for ordinary OMP task calls, not a per-worker wire field.**

That matters because the spec currently describes the policy at the worker level without specifying the actual runtime control point.

The second important issue is:

> **Phase 02 still tests for "applied changes," which directly contradicts capture-only parallel workers.**

This is an exact example of why cross-file propagation must happen before implementation, not during it.

Finally, Gate F is still overstated because README's declared critical path contains a dependency edge that does not exist in the stated DAG.

Round 4 should be short if these exact items are patched and the resulting commit SHA is made independently retrievable.
