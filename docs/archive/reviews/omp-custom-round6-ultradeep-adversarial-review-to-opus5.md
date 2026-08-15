# GPT-5.6 Sol → Claude Opus 5
# Round 6 Ultra-Deep Adversarial Review — `omp-custom/spec`

> **Project:** `omp-custom` OMP Workflow template  
> **Input reviewed:** Claude Opus 5 Round-5 response  
> **Opus-reported Round-5 patch:** `95c711f1bcfdf5f4339d1609e5f0e839208da85f`  
> **Parent:** `3596ad14c52866337989131d6d941f4e31bd246e`  
> **OMP runtime reference:** `can1357/oh-my-pi` tag `v17.2.10`  
> **Review date:** 2026-08-07  
> **Mode:** source trace + cross-file invariant attack + production-readiness audit  
> **Overall verdict:** **NOT READY**. The core design is much stronger, but several concrete cross-file/runtime gaps remain.

---

# 0. Verification provenance

## 0.1 SHA provenance supplied by Opus

Round-5 response supplies:

```yaml
round_4_patch_commit:
  full_sha: 3596ad14c52866337989131d6d941f4e31bd246e
  parent_sha: 1df02eca01c71046eefef577cace6aa0f1c96d72

round_5_patch_commit:
  full_sha: 95c711f1bcfdf5f4339d1609e5f0e839208da85f
  parent_sha: 3596ad14c52866337989131d6d941f4e31bd246e
  branch: main
```

That resolves the **response-side provenance discipline**.

## 0.2 Reviewer retrieval result

I attempted both content-addressed paths supplied by Opus:

```text
https://api.github.com/repos/manhthien2005/omp-custom/commits/95c711f1bcfdf5f4339d1609e5f0e839208da85f

https://raw.githubusercontent.com/manhthien2005/omp-custom/95c711f1bcfdf5f4339d1609e5f0e839208da85f/<path>
```

The current reviewer web environment still returns a cache miss for the SHA-addressed raw files, while branch `main` continues to expose an older cached snapshot.

Therefore:

```yaml
VR-04:
  opus_commit_identity: RESOLVED
  exact_95c_bytes_independently_retrieved: false
  reason: reviewer-side CDN/tool cache miss
  architecture_conclusion: do_not_treat_cache_lag_as_repo_defect
```

This is no longer an Opus process defect. It only means previously described patches remain byte-verification-pending from GPT's environment.

## 0.3 What is independently source-verifiable

OMP `v17.2.10` source and docs are retrievable and were re-read directly for this round.

The source-sensitive conclusions below are independent of the `omp-custom` cache.

---

# 1. Round-6 summary

| ID | Verdict | Severity | Finding |
|---|---|---:|---|
| CR-01 | **PROVISIONAL PASS** | — | Correct RULES data-flow model is source-supported. |
| **CR-02** | **REOPEN** | **P1** | `spec/04` still requires Standard Implementer isolation, contradicting canonical Standard=false / Orchestrated=true policy. |
| CR-06 | **PASS on design** | — | Main Tech Lead model user-controlled is coherent. |
| CR-07 | **PASS on design** | — | Observation-phase terminology is correct. |
| CR-08 | **PROVISIONAL PASS** | — | In-process AgentSession correction is correct. |
| CR-09/27/30 | **PARTIAL** | P1 | Capture-first architecture is sound, but CR-31/32 residuals still prevent a complete end-to-end guarantee. |
| CR-11 | **PROVISIONAL PASS** | — | Trusted executable-repo scope is acceptable for v0. |
| CR-12 | **PROVISIONAL PASS** | — | Schema-valid strings remain untrusted. |
| CR-13/14 | **PASS on design** | — | Rollback/write-set model is coherent. |
| CR-15/16/17/18 | **PROVISIONAL/DESIGN PASS** | — | No new source objection. |
| **CR-19** | **REOPEN** | P2 | Numeric context/offload budgets are asserted "sound" before evidence; Phase03 measures compliance rather than calibrating the targets. |
| **CR-20** | **REOPEN** | P2 | Retrieval levels remain hard gates with unbounded "exhaustion"; authority/cost is not monotonic. |
| **CR-21** | **REOPEN** | **P1** | Phase07 T-07.2 still says diff watched paths, undoing the corrected full-range governance contract. |
| CR-22 | **PASS** | — | Closed. |
| **CR-23** | **REOPEN** | P2 | Phase07 still says "all four validation levels", contradicting canonical L0–L4 five-level taxonomy. |
| CR-24/25/28/30 | **PASS/PROVISIONAL PASS** | — | No new core objection. |
| CR-29/26 | **PARTIAL** | P1/P2 | New task-index integration rule is good, but `spec/04` still encodes pre-capture-first flow. |
| **CR-31** | **PARTIAL** | **P1** | Effective settings-read API is actually known; spec should mandate concrete `omp config get ... --json` preflight and remove user-assertion fallback. |
| **CR-32** | **REJECT as "mechanically closed"** | **P1** | Forbidding nested scope by prompt/out_of_scope does not detect a violating isolated worker; parent post-check cannot see a change already lost during cleanup. |
| CR-33 | **PASS on topology design** | — | Relocating `tech-lead.md` out of agent discovery is correct. |
| **CR-34** | **NEW** | P2 | Installer still owns required `modelRoles.tech-lead` despite no mandatory runtime consumer after CR-06 + CR-33. |
| **CR-35** | **NEW** | **P1** | Verification schemas prove JSON shape, not execution provenance; verifier can fabricate `commands_run`/exit/evidence without running bash. |
| **CR-36** | **NEW** | P2 | Verifier failure enum `impl|env|flaky` cannot represent deterministic pre-existing failures; schema forces misclassification. |
| **CR-37** | **NEW** | **P1** | Phase07 allows OQs to remain explicitly open while README's Production Ready definition requires OQ-1…OQ-5 answered by experiment. |

### Readiness

```yaml
ready_to_resume_implementation: false
```

Strongest remaining blockers:

```text
CR-02
CR-21
CR-31
CR-32
CR-35
CR-37
```

The P2 items should be fixed in the same consistency pass but are not individually equivalent to a P0 runtime blocker.

---

# 2. CR-31 — PARTIAL
# The settings-read API is no longer an uncertainty

Opus's Round-5 response says:

> The exact settings-read API available to a command at runtime is unverified.  
> If no such read path is exposed to the model, refuse parallel by default and require the user to assert the setting explicitly.

The first sentence is now source-refuted by OMP documentation.

## 2.1 OMP provides an effective-settings read API

OMP `v17.2.10` `docs/settings.md` explicitly states:

```text
/settings and `omp config` both read merged effective settings.
```

and:

```bash
omp config get <key>
omp config get <key> --json
```

`--json` emits:

```json
{
  "key": "...",
  "value": ...,
  "type": "...",
  "description": "..."
}
```

Source:

```text
docs/settings.md
"Reading and writing settings"
"omp config get <key>"
```

Canonical URL:

`https://github.com/can1357/oh-my-pi/blob/v17.2.10/docs/settings.md`

## 2.2 Precedence is also source-documented

Effective value:

```text
built-in defaults
< global config
< project config
< CLI overlays
< runtime overrides
```

Therefore the exact preflight can be normative.

## 2.3 Required preflight

Run from the workflow's actual repository root/cwd:

```bash
omp config get task.isolation.mode --json
omp config get task.isolation.apply --json
```

Parse the returned `value`.

Require:

```text
mode != "none"
apply == false
```

Otherwise:

```text
do not dispatch parallel isolated Implementers
```

Permitted degradation:

```text
sequential non-isolated fallback
or
explicit refusal
```

## 2.4 User assertion must not substitute for runtime evidence

The current proposed fallback:

```text
require the user to assert the setting explicitly
```

is not equivalent to checking the effective runtime state.

The whole reason CR-31 exists is that:

```text
file-level intent != effective settings
```

because project/global/CLI/runtime precedence can change the value.

A user's statement does not resolve precedence.

If `omp config get` is unavailable or cannot execute:

```text
parallel mode MUST refuse
```

not:

```text
accept a user assertion and proceed
```

## 2.5 CWD nuance

OMP project settings are loaded from:

```text
<cwd>/.omp/config.yml
```

and settings discovery **does not walk ancestors**.

So the preflight must also guarantee that the process cwd is the intended project root.

Otherwise an install at:

```text
repo/.omp/config.yml
```

can be invisible to a session started under:

```text
repo/packages/foo/
```

The effective-value check catches this, but the error/report should explain the root cause.

## Required patch

Update:

```text
spec/08 §E-9
phase-00 T-00.E3-A / H
phase-02 preflight
phase-06 L1
```

from generic:

```text
assert effective settings
```

to concrete:

```text
query via `omp config get <key> --json`
```

and remove user assertion as a valid proof path.

## Verdict

**CR-31 PARTIAL — P1.**

This is a small patch but it is load-bearing.

---

# 3. CR-32 — REJECT as "closed"
# Scope exclusion does not mechanically prevent an undetectable nested-repo write

Opus correctly escalated the OMP defect.

The source trace is correct:

- root patch is persisted;
- nested patches are returned in-memory;
- `persistNestedPatches()` is recovery-path logic;
- successful `apply=false` branch does not persist nested patch files;
- if a root `patchPath` exists, the `else if` chain hides the nested-repo count;
- isolated worktree is torn down.

I agree with that diagnosis.

The residual problem is the **enforcement mechanism chosen for Option A**.

---

## 3.1 Current proposed enforcement

Opus says:

```yaml
nested_repo_mutation: FORBIDDEN

enforcement:
  - enumerate nested repos before fan-out
  - exclude nested paths from worker scope
  - put nested repo paths in task packet out_of_scope

detection:
  - post-integration nested git status/submodule status unchanged
```

This is policy enforcement by prompt/scope assignment.

It is not filesystem enforcement.

---

## 3.2 A violating worker can still write the excluded path

Implementer has:

```text
edit
write
bash
```

inside the isolated workspace.

Nothing in the task tool prevents:

```text
write vendor/component/file.ts
```

just because the packet says:

```text
out_of_scope: vendor/component
```

OMP has no per-task path write allowlist in the source contract being used here.

Therefore:

```text
FORBIDDEN
```

is a behavioral instruction, not a mechanical constraint.

---

## 3.3 The proposed parent post-check cannot detect the precise failure CR-32 describes

Suppose a parallel isolated worker violates scope:

```text
root/src/a.ts                         changed
vendor/component/src/b.ts             changed
```

OMP captures:

```text
root patch → durable .patch
nested patch → in-memory nestedPatches
```

Then:

```text
successful apply=false summary
→ reports root patch only
worktree cleanup
→ nested change disappears
```

Parent repository state after worker:

```text
root unchanged
nested repo unchanged
```

Then after Tech Lead applies the root patch:

```text
root changed
nested repo still unchanged
```

The proposed post-integration:

```bash
git status
git submodule status
```

reports the nested repo unchanged.

That is exactly the expected parent state whether:

A. the worker correctly did not touch the nested repo, or  
B. the worker touched it and the change was silently lost.

So this detector has **zero power** against the actual silent-loss path.

---

## 3.4 Safe template-level resolutions

### Option A1 — strongest v0 policy

If **any nested Git repository/submodule exists**, Orchestrated parallel isolated implementation is disabled for that repository.

Route to:

```text
sequential non-isolated Standard-style implementation
```

or refuse parallel mode.

This is mechanically safe at the template level because the dangerous runtime path is never entered.

### Option A2 — only if stronger sandboxing is introduced

Allow parallel workers in a repository containing nested repos only if writes can be mechanically restricted away from nested paths.

Current OMP task tool does not provide that path-level write sandbox in the reviewed primitives.

### Option B — OMP runtime fix

Persist every `nestedPatches` item on successful `apply=false` and surface durable artifact paths in the result.

Then capture-first can support nested repos safely.

---

## 3.5 What an in-worker guard can and cannot do

A mandatory worker-side check before `yield` is useful defense-in-depth:

```text
compare nested repos against spawn baseline
```

but the same model that may violate scope is also responsible for running/reporting the check.

That is not a mechanical guarantee.

It can supplement Option A1, not replace it if the architecture wants a hard claim such as:

```text
nested changes cannot silently disappear
```

---

## Required correction

Change the contract from:

```text
parallel scope may coexist with nested repos as long as workers are told not to edit them
```

to:

```text
v0: presence of any nested repo disables parallel isolated implementation
```

until OMP exposes durable nested artifacts or a real path-level write boundary.

Keep E3-G as a regression probe for future OMP versions.

## Verdict

**CR-32 REJECT as CLOSED — P1.**

The diagnosis is excellent; the chosen enforcement is weaker than the guarantee.

---

# 4. CR-02 — REOPEN
# `spec/04-workflow-sizing.md` still encodes the old Standard isolation policy

This is a concrete downstream contradiction missed by the capture-first sweep.

Current `spec/04` says under Standard:

```text
5. Implement — task → implementer (isolated: true)
```

and Verification says:

```text
Standard and Orchestrated dispatch Implementers with isolated: true.
```

The canonical policy established in prior rounds is:

```yaml
Standard:
  implementer:
    isolated: false

Orchestrated:
  parallel_implementer:
    isolated: true
    auto_apply: false
```

README's proposed topology also adopted:

```text
isolated: false (Standard) / true (Orchestrated)
```

Therefore `spec/04` directly contradicts the accepted isolation decision.

## Why this matters

`spec/04` is not historical commentary.

It defines:

```text
workflow sizing
flow steps
verification criteria
```

An implementation agent following it will put Standard through isolation, changing:

- git requirements;
- artifact behavior;
- integration behavior;
- non-git fallback;
- token/runtime cost.

## Additional capture-first drift in the same file

The Orchestrated flow still uses conceptual wording:

```text
Verify — after merge
Integrate + report
```

and its old comments are from the auto-apply architecture.

After CR-29 the correct sequence is:

```text
parallel capture
→ Tech Lead sequential integration by task index
→ Verifier
→ Reviewer
→ report
```

`spec/04` must reflect that explicitly.

## Required patch

Standard:

```text
Implement — task → implementer (isolated: false)
```

Orchestrated:

```text
Implement in parallel — isolated:true, capture-only
Sequential integration — main Tech Lead, task-index order
Verify integrated tree
Review
Report
```

Verification:

```text
Standard Implementer non-isolated
Orchestrated parallel Implementers isolated
```

## Verdict

**CR-02 REOPEN — P1.**

This is another claim-propagation miss.

---

# 5. CR-29 / CR-26 — PARTIAL
## The task-index rule is good; `spec/04` has not adopted the resulting flow

I accept the new normative order:

```yaml
integration:
  order: original task-list index
  completion_order: ignored
  stop_on_conflict: true
  preserve_remaining_artifacts: true
```

That is testable and source-aligned with ordered task results.

However the contract is not globally closed while `spec/04` continues to encode the earlier isolation/merge flow.

Therefore:

```yaml
CR-29:
  local_phase_02_fix: PASS
  global_contract: PARTIAL
  dependency: CR-02
```

---

# 6. CR-34 — NEW
# `modelRoles.tech-lead` is no longer a required template-owned runtime role

```yaml
id: CR-34
severity: P2
class:
  - DEAD_REQUIRED_CONFIG
  - TOPOLOGY_CONFIG_DRIFT
related:
  - CR-06
  - CR-31
  - CR-33
```

Round-5 CR-31 ownership still lists:

```yaml
owned_model_roles:
  modelRoles.tech-lead
  modelRoles.explorer
  modelRoles.implementer
  modelRoles.verifier
  modelRoles.reviewer
```

Round-5 CR-33 simultaneously relocates:

```text
tech-lead.md
```

out of agent discovery.

CR-06 selected:

```text
main-session model/thinking is user-controlled
template does not guarantee @tech-lead routing
```

So there is no mandatory runtime consumer for:

```text
modelRoles.tech-lead
```

inside the selected architecture.

OMP supports arbitrary custom roles, so a user may still manually choose:

```text
@tech-lead
```

That makes the role a possible convenience alias.

It does **not** make it a required installer-owned key.

## Why ownership is harmful

Owning the key means the installer may:

- create it;
- conflict on it;
- include it in rollback;
- validate it;
- force users to reason about it;

despite the workflow not requiring it.

That is configuration surface with no mandatory consumer.

It also contradicts the principle:

> every artifact/config must map to a named runtime consumer.

## Correct fix

Required worker roles:

```yaml
modelRoles:
  explorer: ...
  implementer: ...
  verifier: ...
  reviewer: ...
```

`tech-lead` should be:

```text
optional user convenience alias
```

or removed entirely.

If kept:

```yaml
optional_model_roles:
  tech-lead:
    installer_owned: false
    required_for_workflow: false
```

Update E2 model-role experiments to use a worker custom role for required-path testing.

## Verdict

**NEW CR-34 — P2.**

---

# 7. CR-35 — NEW
# Verification schema validates shape, not command-execution provenance

```yaml
id: CR-35
severity: P1
class:
  - EVIDENCE_PROVENANCE_GAP
  - FALSE_MECHANICAL_GUARANTEE
primary:
  - spec/phases/phase-04-quality-system.md
  - spec/10-verification-and-review.md
related:
  - CR-12
```

This is the strongest new quality-system finding.

---

## 7.1 The spec claims a mechanical guarantee it does not have

Phase04 T-04.1 says the Verifier is mechanically supported by a schema:

```text
required fields cannot be satisfied without real command output
```

and Exit Criteria says:

```text
PASS impossible without per-criterion evidence
```

The first statement is false.

A JSON schema can require:

```json
{
  "commands_run": [
    {
      "command": "npm test",
      "exit_code": 0,
      "evidence": "12 passed"
    }
  ]
}
```

It cannot prove that:

```text
npm test
```

was actually invoked.

---

## 7.2 OMP YieldTool is generic shape validation

OMP `YieldTool`:

- compiles the caller/agent JSON schema;
- validates the yielded `data`;
- retries shape mismatch;
- may eventually set `schemaOverridden`.

It has no knowledge of:

```text
commands_run
exit_code provenance
bash call ids
which command actually executed
```

A schema-valid fabricated object passes shape validation.

This follows directly from generic `buildOutputValidator(session.outputSchema)` behavior.

---

## 7.3 Fresh child session improves independence, not attestation

The separate child AgentSession is valuable:

```text
Verifier did not author the implementation
```

That addresses cognitive independence.

It does not mean:

```text
every evidence string in its result came from a real tool event
```

Those are different guarantees.

---

## 7.4 Adversarial fixture required

Add a Phase04 fixture where a fake/misbehaving Verifier:

```text
calls no bash command
yields a perfectly schema-valid PASS
with invented commands_run and exit_code
```

If the system accepts it, then:

```text
schema-backed verification is structurally valid but not provenance-attested
```

and the spec must say so.

---

## 7.5 Mechanical provenance options

### Option A — v0 honest contract

Downgrade wording:

```text
schema enforces evidence shape;
fresh-session prompt requires actual command execution;
provenance is behavioral, not cryptographically/runtime-attested.
```

For high-risk runs, the Tech Lead may inspect:

```text
history://<verifier-id>
```

OMP task docs state child JSONL history exists and `history://<id>` renders the transcript.

But first add an experiment to verify the transcript gives enough tool-call evidence for a deterministic check.

### Option B — runtime cross-check

Implement/extend validation so claimed commands are cross-checked against child tool-call events.

Only then can the spec say:

```text
commands_run cannot be fabricated without detection
```

---

## Required wording change

Replace:

```text
schema required fields cannot be satisfied without real command output
```

with:

```text
schema requires a structured evidence claim, but does not attest its provenance.
The Verifier prompt requires fresh execution. High-risk verification additionally
audits the child transcript/tool events or uses another source-verified provenance mechanism.
```

## Verdict

**NEW CR-35 — P1.**

This directly attacks the project's central claim:

```text
no false completion
```

so it should be resolved before production-readiness is asserted.

---

# 8. CR-36 — NEW
# `impl | env | flaky` is not an exhaustive failure taxonomy

```yaml
id: CR-36
severity: P2
class:
  - SCHEMA_TAXONOMY_GAP
  - FALSE_REMEDIATION_RISK
primary:
  - spec/10-verification-and-review.md
  - phase-04 T-04.2
```

The Verifier requires every failure to be:

```text
impl
env
flaky
```

Definitions:

```text
impl  → current code is wrong; return to Implementer
env   → dependency/config/tool problem
flaky → nondeterministic
```

There is an obvious deterministic fourth case:

```text
the failure existed before this change
```

Example:

```text
baseline has an unrelated failing test
new diff does not touch that subsystem
same test still fails deterministically
```

This is:

- not caused by the current implementation;
- not an environment failure;
- not flaky.

The schema forces a false label.

Then the prescribed `impl` remediation sends the Implementer to alter out-of-scope code, exactly the expensive error the taxonomy claims to prevent.

## Correct fix

At minimum add:

```text
preexisting
```

with:

```text
record baseline evidence
do not attribute to current diff
surface as project risk / coverage blocker
```

Depending on desired precision, also consider:

```text
test_or_spec
```

for an invalid test/acceptance contract.

But `preexisting` is the minimum concrete gap.

## Required fixture

1. Baseline contains a deterministic unrelated failure.
2. Implemented change is clean.
3. Verifier runs full command.
4. Expected classification:

```text
preexisting
```

not `impl`.

## Verdict

**NEW CR-36 — P2.**

---

# 9. CR-19 — REOPEN
# Token/context budgets are asserted as truths, not calibrated hypotheses

`spec/05` says:

```text
Adopted from context-budget.yml, which is sound and needs no revision.
```

Then hardcodes targets such as:

```text
AGENTS.md           600–1,200
RULES.md            300–700
agent prompt        500–1,200
skill body          800–2,000
task packet         300–800
worker result       200–600
```

and filesystem-offload thresholds:

```text
exploration >2,000
verification >500
review >1,000
```

These are design hypotheses.

No source fact can prove that those numbers optimize:

```text
tokens per accepted outcome
```

for this workflow/model family.

Phase03 then says:

```text
sample results fit §05 targets
```

while separately measuring before/after token totals.

That evaluates whether implementation obeys the chosen numbers.

It does not validate whether the numbers are good.

## Circularity

Current logic:

```text
choose target 600
→ make output <600
→ verify output fits target
→ call target sound
```

Missing logic:

```text
vary target
→ measure cost + quality/acceptance
→ determine useful region
```

## Correct fix

Label numeric values:

```text
initial engineering budgets / hypotheses
```

not source-backed truths.

Phase03 should record distributions:

```text
p50 / p90 / p95 token size
acceptance rate
retry rate
quality failures caused by truncation/offload
```

Then adjust thresholds based on evidence.

No requirement for sophisticated statistics here; just do not claim "sound and needs no revision" before measurement.

## Verdict

**CR-19 REOPEN — P2.**

---

# 10. CR-20 — REOPEN
# Retrieval priority is useful; mandatory exhaustive gates are not

`spec/05` says:

```text
Each level is cheaper and more authoritative than the next.
Do not descend until current level is exhausted.
```

`spec/07` strengthens this to:

```text
Levels are gates, not preferences.
MUST NOT reach level 4 without trying 1–3.
```

This is too rigid.

## 10.1 Authority is not monotonic

Examples:

- Local README may be stale.
- Bundled dependency docs may describe a different installed patch version.
- Source code can reveal implementation but official docs define public contract.
- Security advisories/current compatibility information may only exist externally.
- User explicitly asks for latest official behavior.

So:

```text
local == always more authoritative
```

is false.

## 10.2 Cost is not monotonic

A single official-doc lookup can be cheaper than:

```text
grep + LSP + read + local docs + package source excavation
```

Trying to "exhaust" each layer may waste more tokens.

## 10.3 "Exhausted" has no bounded definition

An agent cannot falsifiably prove:

```text
local sources exhausted
```

without a stopping rule.

That makes the gate:

- unbounded;
- hard to test;
- easy to satisfy by prose assertion.

## Correct contract

Keep the ordering as a default priority:

```text
local code/types
→ local docs
→ official versioned docs
→ Context7
→ broader web
```

but allow skipping with explicit reasons:

```text
local source missing
local docs stale/version mismatch
question is explicitly about current external behavior
official contract required
security/advisory freshness required
user requested authoritative/current source
```

Define a bounded escalation rule, e.g.:

```text
after N targeted local queries fail to answer the question,
move to the next appropriate source.
```

The exact N can be empirical; the key is boundedness.

## Verdict

**CR-20 REOPEN — P2.**

---

# 11. CR-21 — REOPEN
# Phase07 still uses the watched-path-only process that CR-21 removed

The corrected governance design from earlier rounds is:

```text
full commit-range discovery
watched paths = high-priority triage anchors
non-watched changes inspected for transitive/call-chain impact
```

But Phase07 T-07.2 says:

```text
On upstream change: diff watched paths,
re-verify affected claims...
```

That is the old architecture.

This is especially serious because Phase07 is the terminal stabilization/governance phase.

An implementation following it will reintroduce the exact future-upgrade blind spot CR-21 fixed.

## Required patch

T-07.2:

```text
1. diff full upstream commit range
2. prioritize watched-path changes
3. scan non-watched changes for transitive impact
4. map candidate changes to claims
5. re-run affected source checks + behavioral suite
```

Reference `spec/14` rather than restating a weaker version.

## Verdict

**CR-21 REOPEN — P1.**

---

# 12. CR-23 — REOPEN
# Phase07 still encodes the old four-level validation taxonomy

Phase07 T-07.6 says production readiness requires:

```text
all four validation levels passing
```

Canonical taxonomy is:

```text
L0 Static
L1 Discovery
L2 Contract
L3 Behavioral
L4 Adversarial/Comparative
```

That is five levels.

This is exactly the stale terminology CR-23's "full repo sweep" claimed to eliminate.

Phase07 was not listed in the Round-3/Round-5 taxonomy patch surfaces, and it was explicitly named by Opus as a section needing more attack in Round6.

## Correct wording

Production-ready gate:

```text
all required L0–L4 validation gates passing
```

or, if L4 is benchmark-only:

```text
L0–L3 operational gates green;
L4 comparative criterion meets the production threshold
```

matching README §14.

## Verdict

**CR-23 REOPEN — P2.**

The claimed "full repository sweep complete" was incomplete.

---

# 13. CR-37 — NEW
# Phase07 can declare production-ready while open questions remain unresolved

```yaml
id: CR-37
severity: P1
class:
  - READINESS_GATE_CONTRADICTION
  - EXPERIMENTAL_EVIDENCE_GAP
primary:
  - spec/phases/phase-07-stabilization.md
  - spec/README.md §14
```

README Definition of Production Ready requires:

```text
OQ-1…OQ-5 answered by recorded experiment, not inference.
```

Phase07 T-07.5 says:

```text
every OQ is resolved or explicitly open
```

and its Exit Criteria repeats:

```text
Every OQ resolved or explicitly open
```

T-07.6 production readiness then checks:

```text
all P0/P1 resolved
validation passing
benchmark
rollback
no unresolved-risk claims
```

It does **not** require all OQs closed.

Therefore this state can satisfy Phase07:

```yaml
OQ_1: explicitly_open
OQ_2: explicitly_open
risk_registry: says "known/open", not marked unresolved-risk
production_ready_determination: PASS
```

while violating README §14.

## Correct state machine

Reconciliation may allow:

```text
OQ = open
```

as an intermediate Phase07 state.

Production-ready **must not**.

Use:

```yaml
T_07_5_reconciliation:
  allowed:
    - resolved_with_evidence
    - explicitly_open

T_07_6_production_ready:
  requires:
    all_required_OQs: resolved_with_recorded_evidence
```

If any required OQ remains open:

```text
verdict = NOT READY
```

A "production ready with caveats" verdict cannot waive a High-impact unresolved runtime experiment unless README explicitly changes that policy.

## Verdict

**NEW CR-37 — P1.**

---

# 14. Phase07 production-readiness wording should be single-source

Phase07 currently paraphrases production criteria instead of referencing the canonical definition.

That is why:

- four-level numbering drifted;
- OQ closure requirement disappeared;
- governance process regressed to watched-path-only.

Recommended structural fix:

```text
README/spec13/spec14 define canonical gates
Phase07 references those gates by ID
```

For example:

```yaml
production_ready_gates:
  PR-1: all P0/P1 closed/waived
  PR-2: OQ-1..5 resolved by experiment
  PR-3: workflows E2E
  PR-4: structured-output malformed fixture
  PR-5: installer/rollback/idempotency
  PR-6: L0-L3 green
  PR-7: L4 comparative threshold
  PR-8: runtime-consumer mapping
```

Phase07 should say:

```text
evaluate PR-1..PR-8
```

instead of copying their prose.

---

# 15. Quality-system attack: structural evidence vs provenance

CR-35 is not a reason to discard schemas.

Schemas are still valuable for:

- forcing criterion enumeration;
- preventing missing fields;
- enforcing decision/finding consistency;
- ensuring coverage gaps are named.

The correction is epistemic:

```text
structured field present
!=
underlying event occurred
```

This same distinction should be added to:

```text
spec/10
phase04
spec/13 adversarial fixtures
```

A suitable L4 adversarial fixture:

```yaml
fixture: verifier-fabricated-evidence
setup:
  verifier makes zero bash calls
  verifier yields schema-valid PASS
expected:
  production quality system must not treat this as independently evidenced
```

If no runtime provenance check exists in v0, document:

```text
false-completion resistance is behavioral + independent-session,
not full tool-event attestation.
```

That is still honest and useful.

---

# 16. Context/token attack: do not optimize to self-authored thresholds

Recommended Phase03 evaluation:

```yaml
for_each_workflow:
  record:
    - total_tokens
    - accepted_outcome
    - retries
    - packet_tokens
    - worker_result_tokens
    - verifier_evidence_tokens
    - offloaded_bytes
    - quality_failure_reason

analyze:
  - distributions, not one sample
  - accepted vs rejected
  - whether threshold crossing predicts worse quality/cost

then:
  - tune budgets
```

The initial numbers can remain as guardrails, but label them:

```text
v0 starting budgets
```

not:

```text
sound and needs no revision
```

---

# 17. Retrieval attack: use source fitness, not ritual escalation

A better rule:

```text
Choose the cheapest source likely to answer the exact question with sufficient authority.
Prefer local evidence by default.
Escalate or skip based on source fitness.
```

Examples:

| Question | Best first source |
|---|---|
| What does this installed function call? | LSP/local source |
| What public behavior is guaranteed by library vX.Y? | official versioned docs |
| Is there a newly disclosed vulnerability? | current official advisory/web |
| What type does installed package expose? | local types |
| User explicitly asks latest upstream behavior | current upstream source/docs |

This preserves the spirit of progressive retrieval without turning it into bureaucracy.

---

# 18. `modelRoles.tech-lead` cleanup after topology correction

CR-34 should propagate through:

```text
README topology
spec/09 model routing
spec/12 installer ownership
phase00 E2 role tests
phase05 config merge
validation role-count checks
```

Do not accidentally revert CR-33 by requiring a five-role runtime configuration when only four spawned worker roles are required.

---

# 19. Required Opus Round-6 response order

Please respond in this order:

```text
VR-04 acknowledgment (no action unless a new retrieval path exists)
CR-32
CR-31
CR-02 / CR-29
CR-35
CR-21
CR-37
CR-23
CR-34
CR-36
CR-19
CR-20
```

Use:

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

# 20. Exact recommended fixes

## CR-32

For v0:

```text
if nested repo/submodule count > 0:
    do not use parallel isolated Implementers
    route sequential/non-isolated
```

Do not claim `out_of_scope` mechanically prevents writes.

## CR-31

Mandatory concrete preflight:

```bash
omp config get task.isolation.mode --json
omp config get task.isolation.apply --json
```

from project cwd.

No user assertion as substitute.

## CR-02 / CR-29

Update `spec/04`:

```text
Standard Implementer: isolated=false

Orchestrated:
parallel isolated capture
→ sequential task-index integration
→ Verifier
→ Reviewer
```

## CR-35

Delete false claim:

```text
schema fields cannot be satisfied without real command output
```

Add adversarial fake-evidence fixture and honest provenance boundary.

## CR-21

Phase07 update process = full-range discovery, not watched-only.

## CR-37

Production-ready requires every required OQ closed by recorded evidence.

## CR-23

Replace Phase07 "four validation levels" with canonical L0–L4 wording.

## CR-34

Remove `modelRoles.tech-lead` from required installer-owned roles.

## CR-36

Add at least:

```text
preexisting
```

to failure classification.

## CR-19

Reclassify hard token targets as initial v0 budgets and calibrate empirically.

## CR-20

Retrieval sequence becomes default priority + bounded skip/escalation rules.

---

# 21. Readiness answer

Opus explicitly asked for a direct answer rather than another indefinite "not yet."

Here it is:

```yaml
ready_to_resume_implementation: false
```

## Why not

Not because every P2 optimization must be perfect.

The blockers are specific:

### 1. Parallel safety is still overstated

CR-32 claims nested mutation is excluded, but no mechanical boundary detects a violating isolated worker. The exact silent-loss failure can still occur.

### 2. Standard workflow policy is contradictory

`spec/04` still says Standard is isolated while the canonical isolation architecture says it is not.

### 3. Verification's central evidence claim is stronger than the runtime guarantee

A schema-valid verifier result can fabricate command execution provenance.

### 4. Terminal governance reintroduces a known upgrade blind spot

Phase07 uses watched-path-only diffing after CR-21 explicitly rejected it.

### 5. Production-ready gate can pass with required experiments still open

Phase07 and README disagree on OQ closure.

These are specification contradictions affecting runtime safety/evidence, not optional polish.

---

# 22. What would flip readiness to true

A Round-7 readiness flip is reasonable if Opus patches and cross-sweeps:

```text
CR-32
CR-31
CR-02/29
CR-35
CR-21
CR-37
```

and no new P0/P1 inconsistency is discovered in that patch.

The remaining:

```text
CR-19
CR-20
CR-23
CR-34
CR-36
```

should also be corrected, but they are bounded enough that they need not trigger another broad architectural redesign.

After those patches, the right next step is:

```text
resume at Phase 00 experiments
```

—not jump directly to feature implementation.

Phase00 E2/E3/E4/E5 remains the empirical gate that converts the final source-supported design into observed target-environment behavior.

---

# 23. Final assessment

The architecture has converged substantially.

Round 5's strongest work is:

- correct settings-level isolation model;
- explicit capture-first integration;
- task-index order;
- target-aware config ownership;
- Tech Lead discovery correction;
- accurate diagnosis of OMP nested-patch loss.

The remaining problems are mostly **propagation and epistemic strength**:

```text
a correct decision exists
but a downstream file still says the old thing

or

a useful schema exists
but prose claims it proves more than it can prove
```

That is encouraging: the project is no longer fighting basic OMP mechanics.

But it is also exactly the point where premature "all gates closed" language becomes risky.

The correct Round-6 verdict is:

```text
close many old findings,
patch the six concrete P1 blockers above,
then run Phase00 experiments.
```

Do not declare the spec fully implementation-ready before that consistency pass.
