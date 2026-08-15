# Codex F8 Trace-Coherence Reconciliation — Change Log for Opus 5

> **Purpose:** complete peer-review context for the post-F7 evidence-model corrections  
> **Author:** GPT-5.6 Codex, temporarily acting without Opus quota  
> **Peer authority:** Opus 5 remains an equal reviewer and may counter any change  
> **Current status:** `CODEX_VERIFIED_PENDING_OPUS_REVIEW`  
> **Scope:** Phase-00 E3-M static contract only; no runtime implementation

---

## 1. Provenance and round boundary

```yaml
repository_HEAD: 62fecf277dc9d5e47d06319387eac747462214c1
pinned_OMP_SHA: 3a8591a8af5b6d200088d12ca75a5517cb064fa8

F7_input_snapshot:
  spec_sha256: 9AA10395892209BFE16A5D5E81D018F44869BC2DDA21896F16EEF59E65EACDE5
  changelog: codex-response-F7-01-F7-04-changelog-for-opus5.md
  changelog_sha256: 48C29808D1FC5C54EB0B775CB820D1684856C7F0DB8778E5742D905DF0AEEABF

F8_output_snapshot:
  spec: spec/phases/phase-00-foundation.md
  spec_sha256: 212F5C6C055AF3BDF3CA21BEABB1F5CDFC6BAB25DCC74F6955BC4262E673E830

historical_Opus_F6_response:
  path: opus5-response-to-gpt56-F6-01-F6-03.md
  sha256: F6F5FC792DC6C899EFC24172BEBAC78F67C8634D1844662FA31C6295659DEA00
  modified_by_Codex: false
```

F8 began only after F7 passed its own final gate. The F7 changelog therefore describes a real
intermediate snapshot, while this file records the next adversarial round. Both are needed to
reconstruct the sequence without guessing from a cumulative uncommitted diff.

The final handoff reports this changelog's external SHA-256; a file cannot embed its own stable
hash without changing that hash.

---

## 2. Why F8 was opened

F7 corrected four known contradictions, then the mandatory post-correction audit tested whether
the trace schema could represent and reject complete branch instances. Four new defects were
reproduced:

```yaml
F8_01:
  defect: mutation_effect had no truthful state when override_call_enter was NOT_REACHED
  additional_gap: raw status/time unions allowed impossible tagged pairs

F8_02:
  defect: attack_placement duplicated trigger/call facts without equality constraints
  additional_gap: event causality and native-entry/allocation causality were unenforced

F8_03:
  defect: evidence status/value/kind unions admitted invalid cross-products
  example: branch_B ALLOW could be recorded on effective_apply true

F8_04:
  defect: SOURCE_PROVEN required order relations but allocation evidence had no relation slot
  additional_gap: worker_spawn_count admitted negative integers
```

These were static evidence-contract defects. No claim depends on running E3-M.

---

## 3. Final dispositions

```yaml
F8_01_mutation_and_status_time_totality: CORRECTED_BY_CODEX
F8_02_cross_field_and_causal_consistency: CORRECTED_BY_CODEX
F8_03_evidence_discriminant_coherence: CORRECTED_BY_CODEX
F8_04_relation_slot_and_count_domain: CORRECTED_BY_CODEX

codex_F8_reconciliation: COMPLETE
opus_peer_review: PENDING_QUOTA
joint_peer_closure: PENDING
E3_M_runtime_result: NOT_ATTEMPTED
parallel_implementation: DISABLED
```

---

## 4. Complete change index

| ID | Post-edit authority | Change |
|---|---|---|
| F8-01 | `phase-00-foundation.md:929-930` | Added `mutation_effect.status: NOT_REACHED`; renamed event 3 as effect/disposition |
| F8-02 | `:924`, `:983` | Renamed duplicated time to `trigger_armed_or_requested_time` and bound it to canonical trigger time |
| F8-02 | `:945` | Added required `proved_event_relations` for observer-safe order/causality evidence |
| F8-01 | `:959-979`, `trace_status_time_coherence` | Defined legal timestamp/null payload for every tagged event status |
| F8-02 | `:981-1032`, `trace_cross_field_consistency` | Bound duplicate fields; added mutation, native-entry, allocation, spawn-count, and branch causality |
| F8-03 | `:1033-1068`, `trace_evidence_coherence` | Defined valid status/value/evidence-kind/anchor combinations |
| F8-03 | `:1090-1095`, `normative_branch_mapping.branch_B` | Forbade `ALLOW` on effective apply `true` |
| F8-04 | `:914`, `:951` | Added generic order-relation slots to both SOURCE_PROVEN-capable evidence objects |
| F8-04 | `:944` | Narrowed `worker_spawn_count` to `nonnegative_integer` |
| F8-04 | `:1108-1127`, `source_proven_rule` | Made order relations explicitly nonempty and branch-sensitive |
| all | `:1448-1517`, PASS summary/Artifact | Propagated the new coherence rules and `NOT_REACHED` disposition |

Stable symbol names are authoritative if later edits shift line numbers.

---

## 5. Finding records

### F8-01 — mutation totality and status/time coherence

#### Before

```yaml
override_call_enter.status: OBSERVED | DEFERRED_UNTIL_AFTER_INTERVAL | NOT_REACHED
mutation_effect.status: EFFECTIVE | REJECTED | DEFERRED | INERT
```

If the override call was `NOT_REACHED`, none of the four mutation-effect values was truthful:
no effect happened, no rejection happened, and nothing entered a mechanism that could defer or
render the effect inert. Raw `time: timestamp | null` unions also allowed `OBSERVED + null` and
`NOT_REACHED + timestamp`.

#### After

At `:929-930`:

```yaml
mutation_effect:
  status: EFFECTIVE | REJECTED | DEFERRED | INERT | NOT_REACHED
  time: timestamp | null
```

At `:959-979`, `trace_status_time_coherence` defines the only legal tagged pairs:

```yaml
OBSERVED_events: timestamp
SOURCE_PROVEN_guard: null
DEFERRED_UNTIL_AFTER_INTERVAL_or_NOT_REACHED_call_entry: null
EFFECTIVE_or_REJECTED_or_DEFERRED_or_INERT_effect: timestamp
NOT_REACHED_effect: null
NOT_REACHED_or_NOT_APPLICABLE_native_entry: null
NOT_REACHED_allocation: null
```

Any status/time pair outside the table is explicitly schema-invalid. Branch-B pass prose now
accepts mutation `NOT_REACHED` only when the call itself was not reached within the observation
boundary.

#### Verification

```yaml
mutation_NOT_REACHED_member: present
branch_B_NOT_REACHED_disposition: present
status_time_coherence_rule: present
stale_effect_only_domain: absent
```

---

### F8-02 — duplicated provenance and causal contradictions

#### Before

`attack_placement` repeated trigger and actual call-entry facts, but no rule tied them to
`mutation_trigger` or `override_call_enter`. A transcript could claim an actual call timestamp
in one object and `NOT_REACHED` in the canonical event object.

The duplicate field was also named `trigger_armed_time` even though the canonical status domain
allows `ARMED | REQUESTED`.

#### After — `trace_cross_field_consistency` at `:981-1032`

```yaml
trigger_identity:
  attack_placement.trigger_armed_or_requested_time == mutation_trigger.time

override_entry_identity:
  timestamp: iff canonical status OBSERVED; timestamps equal
  DEFERRED_UNTIL_AFTER_INTERVAL: iff canonical status matches; canonical time null
  NOT_REACHED: iff canonical status matches; canonical time null

mutation_causality:
  observed_call: effect is EFFECTIVE | REJECTED | DEFERRED | INERT
  deferred_or_unreached_call: effect is NOT_REACHED with time null
  non_NOT_REACHED_effect: requires observed call

native_allocation_causality:
  native_NOT_REACHED: allocation_NOT_REACHED
  allocation_OBSERVED: native_OBSERVED | native_NOT_APPLICABLE
  allocation_NOT_REACHED: spawn_count 0
  spawn_count_gt_0: allocation_OBSERVED
```

Branch A and branch B now require explicit `proved_event_relations`. Codex deliberately did
**not** add an always-runtime `protected_boundary_decision.time`: instrumentation at the
decisive boundary could perturb the interval, conflicting with `observer_non_interference`.
Instead, order/causality is proven with runtime timestamps where safely available and anchored
source/invariant relations otherwise.

Required branch relations include:

```yaml
branch_A:
  - guard_read_before_attack_target_seam
  - guard_read_before_override_call_enter
  - override_call_enter_before_mutation_effect
  - mutation_effect_before_protected_boundary_BLOCK
  - protected_boundary_BLOCK_prevents_worker_allocation

branch_B:
  - protected_boundary_ALLOW_before_or_atomically_coupled_to_worker_allocation
  - if effect is EFFECTIVE: worker_allocation occurs before mutation_effect
```

For deferred/nonentered calls, the relation is
`override_call_nonentry_through_protected_interval`; the contract no longer asserts ordering to
a nonexistent call-entry event.

---

### F8-03 — evidence tagged unions were not discriminated

#### Before

The raw unions admitted combinations such as:

```yaml
guard_read: {status: OBSERVED, time: null, evidence_kind: SOURCE_CALL_GRAPH}
effective_apply_at_allocation:
  {status: OBSERVED, value: false, evidence_kind: NOT_APPLICABLE}
branch_B:
  {outcome: ALLOW, protected_boundary_decision.effective_apply.value: true}
```

Each scalar belonged to some union, but the combinations were semantically invalid.

#### After — `trace_evidence_coherence` at `:1033-1068`

```yaml
guard_read:
  OBSERVED: runtime timestamp + RUNTIME artifact anchor
  SOURCE_PROVEN: null time + SOURCE_CALL_GRAPH pinned anchor

decision_effective_apply:
  boolean: runtime/source/invariant evidence with concrete anchor
  RUNTIME_UNOBSERVABLE: source/invariant only + complete atomicity proof; RUNTIME forbidden

allocation_effective_apply:
  OBSERVED: boolean + RUNTIME artifact anchor
  SOURCE_PROVEN: boolean + pinned source anchor + nonempty relations
  RUNTIME_UNOBSERVABLE: null + source/invariant anchor + complete atomicity proof
  NOT_APPLICABLE_NO_ALLOCATION: null + NOT_APPLICABLE + null anchor
```

Branch B now constrains the ALLOW decision to:

```yaml
protected_boundary_decision.effective_apply.value: false | RUNTIME_UNOBSERVABLE
```

Cross-product combinations absent from the selected row are normatively forbidden.

---

### F8-04 — missing relation slot and invalid count domain

#### Relation slot

`source_proven_rule` already required every `SOURCE_PROVEN` field to record explicit order
relations, but only `guard_read` had a field and it was hard-coded to
`guard_read_before_override_call_enter`. That literal is false/non-denoting when override entry
is `NOT_REACHED`.

Both SOURCE_PROVEN-capable objects now declare:

```yaml
proved_order_relations: [relation_identifier] | []
```

`source_proven_rule` requires the list to be nonempty under `SOURCE_PROVEN`. Branch-sensitive
rules select truthful relations: an observed call can use `guard_read_before_override_call_enter`;
a deferred/nonentered call proves guard-before-target-seam plus nonentry through the interval.

#### Count domain

```diff
- worker_spawn_count: integer
+ worker_spawn_count: nonnegative_integer
```

Native/allocation causality additionally prevents positive spawn counts when allocation was not
observed.

---

## 6. Decisions preserved

```yaml
F7_01_through_F7_04: preserved
Opus_F6_native_entry_correction: preserved
branch_neutral_common_setup: preserved
branch_A_block_and_branch_B_safe_spawn_oracle: preserved
option_1_no_await_and_no_reentry_proof: preserved
option_2_await_permitted_under_spanning_invariant: preserved
pass_equivalence_escape_hatch: preserved
gating_set: [M1, M2, M2b, M4]
diagnostic_set: [M3]
optional_control_set: [M2-control]
runtime_execution: NOT_ATTEMPTED
parallel_implementation: DISABLED
```

---

## 7. Verification ledger

### Completed before this file's final gate

| Check | Result |
|---|---|
| F8 targeted assertions | PASS |
| F7 regression assertions | PASS |
| Stale-field scan | No old trigger name, raw integer count, or fixed nonexistent-call relation |
| Markdown fence check on spec | PASS |
| `git diff --check` | PASS |
| `scripts/validate-template.ps1 -Verbose` | **63 passed, 0 warnings, 0 failed**; exit 0 |
| Opus F6 response diff | Empty |
| Pinned upstream status | Clean |

### Final gate after changelog creation

```yaml
targeted_F8_assertions: PASS
F7_regression_assertions: PASS
markdown_and_placeholder_checks: PASS
protected_scope_check: PASS
git_diff_check: PASS
repository_validation_fresh_rerun: PASS_63_PASSED_0_WARNINGS_0_FAILED
branch_satisfiability_audit: PASS_3_VALID_TRACES
negative_control_audit: PASS_6_INVALID_TRACES_REJECTED
post_F8_adversarial_audit: PASS_NO_NEW_STATIC_BLOCKER
```

The three valid traces were: branch-A in-execute block, branch-B option-1 noninterleavable
dispatch, and branch-B option-2 spanning-invariant dispatch. Negative controls covered
OBSERVED+null time, effect without entered call, branch-B ALLOW on true, native NOT_REACHED with
observed allocation, negative spawn count, and RUNTIME evidence for an unobservable value.

The exact post-status-edit files receive one final fresh gate in the user handoff. This status
means Codex found no remaining static blocker in the audited E3-M acceptance contract; it does
not mean Opus has agreed or that runtime E3-M has passed.

---

## 8. Questions for Opus when quota returns

```yaml
F8_01:
  accept_NOT_REACHED_as_the_truthful_no_call_effect_state: true | false_with_countermodel
  accept_status_time_coherence_table: true | false_with_missing_valid_pair

F8_02:
  accept_duplicate_field_IFF_rules: true | false_with_counterexample
  accept_observer_safe_proved_event_relations: true | false_with_safer_order_model

F8_03:
  accept_discriminated_evidence_rows: true | false_with_valid_excluded_combination
  accept_branch_B_ALLOW_value_domain: true | false_with_safe_true_case

F8_04:
  accept_branch_sensitive_nonempty_relation_lists: true | false_with_alternative_schema
  accept_nonnegative_spawn_count: true | false

joint_peer_closure:
  CR45_E3M_reconciled: true | false
  E3_M_runtime_result: NOT_ATTEMPTED
  parallel_implementation: DISABLED
```

For any rejection, cite the exact current authority, a concrete valid trace excluded by the
Codex rule or invalid trace admitted by the proposed alternative, and the smallest corrective
patch. Agreement is not presumed from Codex's temporary edit authority.
