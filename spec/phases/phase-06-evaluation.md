# Phase 06 — Evaluation

<!-- round09-12-projection:evaluation -->
## Round 09–12 executable evaluation supersession

The metadata-only benchmark is superseded by the closed deterministic core and the explicit
campaign process boundary. Deterministic fixtures validate machinery with zero provider/model
processes and cannot promote. Campaigns require separate authority and frozen inputs; unavailable
environments yield `ENVIRONMENT_BLOCKED` plus `DEFER_INCONCLUSIVE`. Pilot evidence cannot promote;
the existing §13 C-4/C-5 sequential final protocol remains the only promotion path.

<!-- topic08-projection:behavior-core -->
## Topic 08 deterministic evaluation consumer

Run the four Node suites, installer/rollback and one-defect mutation suites, generated-lock check,
focused validator, pinned OMP source attachments, and one final full validator. Record OMP as
`IMPLEMENTED_NOT_PROMOTED`, keep Claude `DESIGNED_NOT_VERIFIED`, retain Topic 07's independent
runtime blocker, and leave model-assisted trigger/pressure promotion to Topic 11.

<!-- topic06-projection:phase-06 -->
## Topic 06 deterministic evaluation consumer

Run the model-free core, role, projection, receipt, wrapper, installer, managed-runtime, batch,
and adversarial suites. Prove native same-name delegation, exact route/effort reconciliation,
forced-partial refusal, plan/async/nested behavior, Reviewer claim exclusion, Topic 04 CAS, and
managed/unmanaged separation. Record `provider_calls: 0` and nonblocking
`OPEN-T06-RUNTIME-01`; do not infer universal OMP interception.

<!-- topic07-projection:phase-06 -->
## Topic 07 deterministic evaluation consumer

Run continuity state/schema/core/adapter/transaction/pressure/installer/rollback suites, verify all
pinned OMP source-range attachments, and use the local in-process provider sentinel to prove zero
provider entry at pressure and exactly one entry below threshold. Verify one fresh kernel on the
next normal prompt, no automatic continuation/retry/handoff, and bounded-child failed/partial
settlement. Execute the canary on both supported runtimes when locally available; a missing
17.2.10 executable remains `OPEN-T07-RUNTIME-02` and status `IMPLEMENTED_NOT_PROMOTED` without
network acquisition or an Opus gate.

<!-- topic05-projection:phase-06 -->
## Topic 05 evaluation consumer

Run the deterministic A/B/C/D matrix with identical snapshots, uncontaminated native targets, and
separate cold/warm graph records. A live pilot is optional and requires explicit spend authority;
missing DeepSeek/provider telemetry is recorded, not inferred. Exit permits only a task-class
recommendation after hard gates and never changes CodeGraph into a universal default.

## Topic 04 consumer projection

Topic 04 consumes deterministic and behavioral lifecycle fixtures. Phase 06 runs schema/root/CAS,
candidate/evidence drift, handoff/takeover, lock, archive/purge, migration, installer, and
cross-session/worktree checks; acceptance evidence binds the exact candidate and inputs.

> OPUS PROPOSED SPEC v1 | Replace the benchmark placeholder with real measurement.
>
> **Topic 02 supersession boundary:** L0–L4 consume the Topic 03-selected topology manifest.
> Worker names/count, structured-result producers, skills, batching, isolation, LSP, bash, and
> blocking requirements activate only when the selected runtime contract consumes them. The
> three approved workflow entry adapters remain the Topic 02 command surface.
>
> **KD-027 projection:** the selected three-agent manifest is exactly `cheap-scout`, `worker`,
> and `reviewer`; the main-session Tech Lead is not discoverable as an agent.

**Depends on**: phase-03, phase-04, phase-05 (all three converge here — see `README.md §6`)
**Blocks**: phase-07

---

## Objective

Build the L0–L4 validation stack (per the canonical taxonomy in `spec/13-validation-and-evaluation.md §B`) and a benchmark harness that executes real OMP sessions, so quality claims rest on measurement rather than on file-existence counts.

---

## Rationale

`validate-template.ps1` reports 63/63 PASS while eight P0 defects are present — it
checks that files exist and are the right length, which is orthogonal to whether the
system works. `benchmark.ps1` executes nothing; it lists fixtures and asks the user to
hand-write result files. Both need replacing before any quality claim is defensible.

---

## Tasks

**CR-23 — Canonical level taxonomy:** All level references in this file follow the L0–L4 taxonomy defined in `spec/13-validation-and-evaluation.md §B`. Prior drafts of this file used "Level 1–4" for what the canonical taxonomy calls L0–L3; those references are corrected below.

### T-06.0 — Add the Topic 02 lifecycle scenario matrix

At L2/L3, evaluate plain entry, explicit Quick, compatibility hints, and internal
reclassification. Include missing-slash input and prove it does not become a command error.

Evaluate candidate mutation invalidation, handoff reconciliation, and Orchestrated integration.
Cover same-task C1→C2 rework, a material contract change opening a linked task, stale resume
refusal, compaction identity preservation, work-unit completion that cannot accept the parent,
and acceptance that binds only to the integrated candidate.

Cheap Scout retryable availability/runtime failure follows Flash `xhigh` → Pro `xhigh` → Tech
Lead retrieval without lifecycle side effects, workflow reclassification, or lowered quality
gates. Weak evidence is rework/Tech Lead adjudication, not an opaque provider fallback.

Validator contract: Cheap Scout retryable availability/runtime failure follows Flash xhigh to
Pro xhigh to Tech Lead retrieval without lifecycle side effects.

**Acceptance**: every scenario has a deterministic oracle where possible and a bounded
behavioral oracle otherwise; failures are recorded as failed cycles rather than hidden retries.

### T-06.1 — Keep L0 (static) validation, honestly scoped

Retain file-existence, token-budget, and YAML checks — they catch real regressions —
but rename the output so passing no longer implies working. Add the checks that would
have caught phase-01's defects: no `policy:` references, no tool named outside its own
allowlist, no bundled-name collision, every selected `autoloadSkills` name resolvable, and
every selected structured-result producer carrying the output contract Topic 03 requires.
Topic 06 must not hard-code the pre-Topic-03 roster hypothesis.

**CR-39/CR-40/CR-41 — three static checks catching defaults or contradictions that work against the template:**

- **`blocking: true` on each selected worker whose result is a required stage barrier.** Missing ⇒ that worker becomes a background job
  (`async.enabled` defaults `true`; `blocking` has no parser default), and every stage barrier in
  `04-workflow-sizing.md` breaks with a clean-looking early return rather than an error. Exactly
  the silent-structural defect L0 is for.
- **LSP allowlist ↔ setting coherence.** If any agent lists `lsp`, the template's project
  `config.yml` must set `task.enableLsp: true` — its default is `false`, so otherwise the
  allowlist grants what the settings layer withholds.
- **Independent `lsp.enabled` gate.** If project config sets `task.enableLsp: true` while
  setting `lsp.enabled: false`, L0 rejects the static contradiction. Runtime/parent overlays
  remain an L1 effective-settings concern.

L0 implements CR-41 separately and rejects task.enableLsp true with lsp.enabled false. L1 still
checks the complete effective four-gate conjunction after precedence.

**CR-28 correction:** L0 must NOT require "every dispatch carries inline `outputSchema`" —
that inverts DR-2. The correct L0 check is: every selected spawned worker whose contract
requires a structured result has a canonical `output:` frontmatter block (the primary worker
enforcement path per DR-2 and `spec/06`). A selected non-worker producer is checked at its
equivalent enforced boundary. Caller inline `outputSchema` is an override, not the default —
its presence is not globally required and its absence is not inherently a defect.

**KD-004 — compile, do not merely find.** L0 fully lints every selected structured-result
schema before dispatch. It rejects malformed/unrepresentable schemas, `$ref`, and required
fields not taught by the selected producer contract. A fixture injects a malformed schema that
would otherwise return `structuredOutput.status: unavailable`. Acceptance requires
structuredOutput.status valid; unavailable, invalid, and overridden results are unvalidated.

**Acceptance**: L0 detects all eight P0 defects when reintroduced. Report wording
states it verifies structure, not behavior.

### T-06.2 — Add L1 (OMP discovery) validation

Assert OMP actually discovers what was selected and installed: project workers from the
topology manifest, the approved workflow entry adapters, the skill set declared by the
selected runtime manifest, and every referenced config role. This is the layer that catches
"installed but invisible."

**CR-33 — derive the selected worker set from Topic 03; `tech-lead` remains ABSENT.** L1 loads
the Topic 03-selected topology manifest, requires every selected project worker to be discovered,
and rejects any unselected project worker. The Tech Lead is the main session (DR-1); its role
contract lives outside every discovery root. A discovered `tech-lead` agent is a **FAIL** because
every `.md` under an agents directory becomes a spawnable `AgentDefinition`.

**CR-31 — L1 asserts effective isolation settings only for the conditional parallel path.** If
Topic 03 selects isolated parallel writers, a discovered-but-misconfigured install must fail:
`task.isolation.mode != "none"` and, in the project target,
`task.isolation.apply == false`. Sequential Orchestrated execution does not require isolation.

**CR-34 — resolvable model roles follow actual consumers, not a fixed count.** L1 resolves every
model-role alias referenced by the selected workers or command adapters. `modelRoles.tech-lead`
is not installer-owned and its absence is not a failure unless Topic 03/Phase 02 creates an
explicit runtime consumer without changing main-session Tech Lead ownership.

E2 fixes alias-resolution behavior: missing aliases and an unavailable selected target hard-fail;
project settings win. KD-027 separately selects one explicit runtime retry chain for Cheap Scout.
L1 requires effective `task.enableEffort: true` and `task.maxEffort: xhigh`; normal Worker
resolves at `high`, hard Worker at `xhigh`, and Reviewer at exact `xhigh`.

L1 requires effective task.enableEffort true and task.maxEffort xhigh for selected exact effort
paths. Missing aliases and an unavailable selected target hard-fail; KD-027 separately validates
the explicit Scout runtime retry chain.

L1 requires effective `retry.modelFallback: true`, `retry.usageAwareFallback: false`, a Scout
chain containing only Pro `xhigh`, and empty default/Worker/Reviewer chains. It resolves both
DeepSeek catalog entries and checks their reasoning metadata. Provider smoke must prove thinking
and a real tool call before recording PASS; missing DeepSeek credential is
`ENVIRONMENT_BLOCKED` and routes Scout work back to the Tech Lead.

Validator contract: L1 requires retry.modelFallback true, retry.usageAwareFallback false, a Scout
chain containing only Pro xhigh, and empty default/Worker/Reviewer chains. L1 reconciles
task.agentModelOverrides and rejects a Worker/Reviewer returned modelRole or resolvedModel
mismatch, including unflagged credential fallback.

L1 reconciles task.agentModelOverrides and rejects a returned modelRole or resolvedModel mismatch
for Worker and Reviewer,
including unflagged credential fallback. The expected identity is derived from the selected
manifest plus reconciled effective settings before dispatch; an unselected override or
parent-model credential substitution cannot satisfy the selected contract.

**CR-39/CR-40/CR-41/CR-43 — L1 also asserts the execution-mode and capability settings**, because all are
defaults that work *against* this template and all fail silently:

- `effectiveAgent.blocking === true` for each selected worker whose result is a required stage
  barrier. Check the parsed value; non-barrier helpers are not forced blocking by membership.
- effective `task.batch == true` only when the selected topology uses batch dispatch; otherwise
  batching is not a workflow requirement.
- the effective LSP conjunction only when a selected worker declares `lsp`; the selected
  LSP-consuming path fails closed when the conjunction is unmet. A replacement contract that
  does not consume LSP must be explicit, reconciled, and revalidated before dispatch.
- L1 probes applicable language-server routing for selected file types and rejects every required
  LSP call whose `details.success` is false; four-gate registration alone is not acceptance.
- effective `bash` for any selected verification role whose contract requires fresh command
  execution; do not require a role named `verifier` merely to satisfy the check.
- L1 checks effective glob.enabled, grep.enabled, astGrep.enabled, and web_search.enabled for
  selected consumers and fails closed when unmet. `astGrep.enabled` defaults false, so the
  manifest/setting contradiction is an explicit L0/L1 case.
- L1 checks task.maxEffort and the returned resolvedModel effort suffix for selected exact effort.
- L1 rejects selected nested delegation when task.maxRecursionDepth would strip the task tool.
- Plan mode requires a distinct planning-only contract and rejects selected mutation or
  fresh-command paths before dispatch or acceptance. The read-only plan-mode worker transform
  cannot supply completion evidence for a write or command-execution contract.

**Acceptance**: L1 confirms the exact Topic 03-selected worker set (with no discovered
`tech-lead`), all three approved workflow entry adapters, the skill set declared by the selected runtime manifest,
every actually referenced model role, and every
stage-barrier/capability/config conjunction declared by that topology. Batch, isolation, LSP,
and writer-concurrency assertions activate only for the selected path that consumes them.

The model/effort matrix additionally proves Cheap Scout Flash/Pro at OMP `xhigh` → provider
`max`, Worker `high` and hard-task `xhigh`, Reviewer fixed `xhigh`, Worker/Reviewer exact returned
identity, and the disclosed same-model separate-session review fallback when a cross-family model
is unavailable.

### T-06.3 — Add L2 (contract) + L3 (behavioral) workflow fixtures

Execute each workflow against fixtures with known-correct outcomes: a one-line fix for
`/quick`, a two-file change for `/standard`, an independent three-module change for
`/orchestrated`, plus an ambiguous task that must trigger triage rather than a guess,
and a failing-verification task that must not report completion.

**Acceptance**: each fixture asserts a specific observable outcome, including the two
negative cases.

### T-06.4 — Add L4 (adversarial) fixtures

Test the failure modes the design claims to prevent: a candidate author that claims success
falsely (the selected non-author verification mechanism must contradict it when independence
is contract-required), an environment failure (must classify as `env`), a non-git-repo
isolated dispatch on a selected isolation path (must hit the fallback, not throw), a
malformed or schema-violating result (must fail lint or surface a non-valid status), and conflicting parallel
patches when parallel writers are selected (must be detected). Also falsify an unmet selected
LSP conjunction: the path must stop before dispatch or acceptance, and no `grep` substitution
may satisfy the same contract. L4 forces a softRequestBudget partial yield and proves it cannot
satisfy completion. It also dispatches a selected mutation/fresh-command producer from plan mode
and proves its plausible read-only yield is rejected until a distinct planning-only contract or
an explicit reconciled transition out of plan mode is selected.

L4 covers registered LSP with no applicable language server and rejects every required LSP
result whose details.success is false. The fixture passes all four registration gates, targets a
file with no matching/configured server, and proves that a later plausible structured yield
cannot mask the failed semantic capability.

For an external freshness fixture, web_unavailable is disclosed and a freshness contract cannot
pass without authoritative evidence. Disable `web_search.enabled`, keep the worker otherwise
capable of returning prose, and require the result to remain unresolved/nonterminal.

**Acceptance**: every listed adversarial case produces its specified deterministic detection.

### T-06.5 — Rewrite the benchmark harness

Replace metadata recording with real execution. Materialize a fresh scratch repo, run OMP,
execute the external deterministic oracle, and emit one immutable task-cycle record for every
success, failure, crash, and timeout. Capture the task contract/hash, objective and criterion
evidence, required verification/review state, Tech Lead acceptance, terminal state, failure
class, agents, tool calls, retries, rework, handoff/compaction, and latency.

Reconcile main-session message usage with unique per-spawn `SingleResult` usage and role
metadata. Compute `core_workflow_tokens`, `cheap_scout_tokens`, and `raw_total_tokens` on the
same input+output+cache-write basis; report cache-read separately and prohibit double counting.
If the main-session or role attribution is unavailable, record `not_measured` and make the run
ineligible for promotion (`spec/13 §C-2`).

**Acceptance**: the harness runs a fixture end to end and emits a populated record
with no manual authoring; a failed cycle remains in the aggregate numerator.

### T-06.6 — Establish the frozen dual baselines

Create two independently identified baselines:

- `stable_product_baseline`: the last promoted template for every candidate decision;
- `pinned_plain_omp_runtime_baseline`: plain pinned OMP for release and major architecture
  checkpoints.

Record OMP/template hashes, fixture version, provider/model-role map, reasoning, timeout/retry,
cache, and tool environment. A stable baseline advances only after promotion and records the
identity it supersedes.

**CR-22 correction — Formal A/B protocol:** The earlier back-to-back/same-session wording is
withdrawn because it permits conversation, cache, provider-warmth, and filesystem confounds.
Each arm runs from fresh independent state, with ordering randomized or counterbalanced and
exactly one variable changed. Three paired runs per arm are pilot-only; final evidence uses the
predeclared sequentially valid adaptive protocol in `spec/13 §C-4/C-5`. It controls the
probability of any false promotion at `<= 0.05` across interim looks, both win paths, and all
promotion-bearing bounds; repeated nominal 95% intervals are descriptive only.

**Acceptance**: both baseline identities are frozen and recorded; paired results use identical
baseline-compatible task objectives and oracles. Template-specific discovery/contract gates
apply to the template, not as impossible mechanism requirements on plain OMP.

### T-06.7 — Implement accepted-outcome and metric semantics

Implement the five-condition `validated_accepted_outcome` classifier in `spec/13 §C-1`.
`accepted_with_waiver` and every non-accepted cycle are excluded from its denominator. The
lifecycle terminals are accepted, cancelled, and terminally blocked; partial, recoverable
blocked, waiting-for-user, and rework observations remain inside an open cycle. Quality gates
run first, validated accepted-outcome rate is the primary quality measure, and false completion
is a hard safety gate.

Then compute:

```text
sum(core_workflow_tokens across all attempted cycles, including failures)
--------------------------------------------------------------------------
count(validated accepted outcomes)
```

Zero accepted outcomes means infinite cost. Cheap Scout and raw total tokens are unweighted
telemetry. Wall time is telemetry and a final tie-breaker only; timeout/deadlock is a
reliability failure.

**Acceptance**: the harness derives terminal state and all three ledgers automatically,
retains failed cycles, refuses a promotion calculation when required telemetry is missing, and
reports the metric per arm.

### T-06.8 — Implement the promotion gate

Implement `spec/13 §C-5` in this order: deterministic hard gates, then exactly one of
`PROMOTE_EFFICIENCY` or `PROMOTE_QUALITY`. The efficiency path requires no observed acceptance
loss, a sequentially valid lower promotion bound of at least `-0.05`, at least 10% observed
core-token improvement, and a sequentially valid paired bound excluding no improvement. The
quality path requires a strictly positive sequentially valid lower acceptance bound and a
sequentially valid paired upper core-token bound no greater than `1.10x` baseline.

Pilot evidence can reject but cannot promote and is not reused in final inference unless the
sequential procedure was frozen before the pilot and includes it as the first look. Final
sampling uses an anytime-valid confidence sequence, an explicit alpha-spending/look schedule,
or an equivalent joint construction that keeps false-promotion probability at `<= 0.05`
across all looks, both paths, and every promotion-bearing bound. It stops only on a valid
predeclared promotion condition, rejection/futility condition, or evidence budget.
Inconclusive results defer or reject. Risk overrides may be stricter only and must be frozen
before final sampling; `accepted_with_waiver` never becomes a validated promotion.

**Acceptance**: deterministic fixtures cover every hard-gate failure, both valid win paths,
pilot-only rejection, missing telemetry, post-hoc threshold mutation, nominal per-look
interval rejection, undeclared looks, missing/exhausted alpha allocation, invalid pilot reuse,
and inconclusive-budget exhaustion. Calibration simulation may supplement but cannot replace
deterministic verification of the sequential gate and error-allocation math.

---

## Deliverables

- L0 (Static) with defect-catching static checks, honestly labeled
- L1 (Discovery) validation
- L2 (Contract) + L3 (Behavioral) workflow fixtures including negative cases
- L4 (Adversarial/Comparative) fixtures
- Executing benchmark harness
- Frozen stable-product and pinned plain-OMP baselines
- Validated accepted-outcome classifier and three-ledger task-cycle accounting
- Primary quality and efficiency metrics implemented
- Two-path promotion verdict with pilot/final separation

---

## Verification

1. Reintroduce each P0 defect; confirm L0 or L1 catches it.
2. Run all L3 (Behavioral) fixtures; confirm expected outcomes including the two negatives.
3. Run all L4 (Adversarial) fixtures; confirm each failure mode is detected.
4. Run candidate/stable and release/plain-OMP pairs from fresh independent state; confirm
   identities and records populate automatically with counterbalanced ordering.
5. Confirm main-session and unique child usage reconcile without double counting; inject a
   missing role/usage field and confirm promotion fails closed as `not_measured`.
6. Confirm a three-run pilot cannot emit either promotion verdict.
7. Exercise the efficiency-win, quality-win, hard-gate rejection, and inconclusive paths.
8. Attempt promotion with an ordinary 95% interval after repeated looks, an undeclared look,
   exhausted alpha allocation, and pilot data outside the frozen procedure; confirm each fails
   closed.
9. Confirm latency cannot compensate for a quality or core-token regression.

---

## Exit Criteria

- [ ] L0 catches all eight P0 defects
- [ ] L0/L1 validate the topology selected by Topic 03, including every required stage barrier
      and capability/config conjunction, without assuming a fixed worker count
- [ ] L0 fully lints selected schemas; result acceptance requires `structuredOutput.status == valid`
- [ ] L1 validates effort and selected-model identity across fallback settings, agent overrides,
      returned role/model identity, and unflagged credential fallback
- [ ] L2 (contract) proves schema rejection and retry actually occur
- [ ] L2/L3 Topic 02 lifecycle fixtures pass, including no-prefix entry, internal
      reclassification, candidate invalidation, handoff reconciliation, Orchestrated
      integration, and fail-soft Scout fallback
- [ ] L4 adversarial cases detected, including forced partial yield and plan-mode read-only substitution
- [ ] Benchmark executes real sessions
- [ ] `stable_product_baseline` and `pinned_plain_omp_runtime_baseline` identities frozen and
      measured on fresh paired runs with counterbalanced ordering
- [ ] `validated_accepted_outcome` computed from all five conditions; waiver and non-accepted
      terminal states excluded
- [ ] `core_workflow_tokens`, `cheap_scout_tokens`, and `raw_total_tokens` computed without
      double counting; failed cycles remain charged
- [ ] Pilot (`>=3` paired runs/arm) cannot promote; final adaptive evidence is sequentially
      valid with `<=0.05` joint false-promotion probability and emits only
      `PROMOTE_EFFICIENCY`, `PROMOTE_QUALITY`, `REJECT`, or `DEFER_INCONCLUSIVE`
- [ ] Release comparison against pinned plain OMP clears PR-7 on baseline-compatible fixtures

---

## Risks

| Risk | Mitigation |
|---|---|
| Fixtures are nondeterministic (LLM variance) | Multiple runs under a frozen sequentially valid procedure; report distribution, not a single number |
| Benchmark costs expensive core tokens | Pilot first; continue adaptively only for viable candidates; never promote from the pilot |
| Baseline arm is unflattering | That is the finding; report it honestly |
| Session and child telemetry double-count the same spawn | Reconcile unique child IDs against task-tool aggregates; missing attribution is `not_measured` and fails promotion closed |
| Cheap Scout volume dominates raw totals | Keep it visible as telemetry but exclude it from the unweighted core optimization ledger |
| L3/L4 fixtures rot as workflows change | Fixtures assert outcomes, not internal steps |
