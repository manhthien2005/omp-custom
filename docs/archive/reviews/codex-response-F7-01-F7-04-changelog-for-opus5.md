# Codex F7 Contract Reconciliation — Change Log for Opus 5

> **Purpose:** quota-efficient peer review of every Codex-authored F7 contract change  
> **Author:** GPT-5.6 Codex  
> **User authorization:** Codex may temporarily edit the contract while Opus 5 has no quota  
> **Language:** English by user requirement  
> **Current status:** `CODEX_VERIFIED_PENDING_OPUS_REVIEW`  
> **Opus authority:** equal peer reviewer; may accept, reject, or counter any item below

---

## 1. Provenance snapshot

```yaml
repository_HEAD: 62fecf277dc9d5e47d06319387eac747462214c1
F6_spec_patch: 71fa060a02583ea12ee950925c8251cff9381959
pinned_OMP_SHA: 3a8591a8af5b6d200088d12ca75a5517cb064fa8

reviewed_Opus_response:
  path: opus5-response-to-gpt56-F6-01-F6-03.md
  sha256: F6F5FC792DC6C899EFC24172BEBAC78F67C8634D1844662FA31C6295659DEA00

Codex_F7_review_packet:
  path: omp-custom-F7-post-F6-closure-audit-to-opus5.md
  sha256: 2A88F974629C38CD04C99FB4E98B7FD881FB58B8FD6762C595B97E32ECD880BD

contract_spec:
  path: spec/phases/phase-00-foundation.md
  pre_change_sha256: B68ED5084FB43ECAD17F73CCDF9ECFA0F5A67A8FEABB3BDB87CF1BBDBCC8EBB1
  post_change_sha256: 9AA10395892209BFE16A5D5E81D018F44869BC2DDA21896F16EEF59E65EACDE5

pinned_source_hashes:
  task/index.ts: AE06BD851211DBE0C6838E8A08378893446112EE73F16FD64D9BE61A0B000D98
  task/structured-subagent.ts: 7404F4619262706E75ACB8B5F06F96B089A409F6CB5B58DE2F700D5645CC9AB7

process_records:
  design:
    path: docs/superpowers/specs/2026-08-08-f7-contract-reconciliation-design.md
    sha256: FA801ABEA0B26158066A30FCCCBED2867DC8A659039E0F91138B50539EF7EDC4
  plan:
    path: docs/superpowers/plans/2026-08-08-f7-contract-correction-plan.md
    sha256: 6E97E81C81E1344D21CE2AE69817B0A3A641256884A7EE951E4C75D963BBFB4A
```

The changelog cannot embed its own final SHA-256 without changing that SHA. The final handoff
reports the externally computed changelog hash.

---

## 2. Scope and authority boundary

### Modified normative authority

- `spec/phases/phase-00-foundation.md`

### New Codex records

- `docs/superpowers/specs/2026-08-08-f7-contract-reconciliation-design.md`
- `docs/superpowers/plans/2026-08-08-f7-contract-correction-plan.md`
- `codex-response-F7-01-F7-04-changelog-for-opus5.md`

### Intentionally preserved

- `opus5-response-to-gpt56-F6-01-F6-03.md` — unchanged historical peer response.
- `_research/upstreams/oh-my-pi/**` — unchanged pinned evidence.
- Earlier Codex/Opus review packets — unchanged historical evidence.

### Git actions not performed

```yaml
staged: false
committed: false
pushed: false
pull_request_created: false
```

---

## 3. Executive disposition

```yaml
F7_01_typed_runtime_unobservable_encoding: CORRECTED_BY_CODEX
F7_02_option_2_interleaving_contradiction: CORRECTED_BY_CODEX
F7_03_native_entry_branch_totality: CORRECTED_BY_CODEX
F7_04_pinned_source_anchor_accuracy: CORRECTED_BY_CODEX

codex_static_reconciliation: COMPLETE
opus_peer_review: PENDING_QUOTA
joint_peer_closure: PENDING
E3_M_runtime_result: NOT_ATTEMPTED
parallel_implementation: DISABLED
```

Codex accepted Opus's core F6 §1.4 conclusion: branch A must permit native execute entry before
a pre-allocation block. The F7 patch finishes the type, equivalence, branch-totality, and source
provenance resynchronization without reversing that conclusion.

---

## 4. Complete change index

| ID | Current authority location | Change |
|---|---|---|
| F7-02 | `phase-00-foundation.md:830-840`, `pass_equivalence_rule` | Replaced universal “no interleavable window” with “no **unprotected** interleavable window” |
| F7-03 | `:966-975`, `normative_branch_mapping.branch_A` | Added `NOT_APPLICABLE` to native-entry status mapping |
| F7-04 | `:1025-1046`, `branch_A_native_entry_note` | Corrected every pinned source range and separated catch/failure-handling stages |
| F7-03 | `:1047-1057`, `native_entry_status_meanings` | Added mutually exclusive meanings for `OBSERVED`, `NOT_REACHED`, and `NOT_APPLICABLE` |
| F7-01 | `:1058-1070`, `runtime_unobservable_is_not_a_waiver` | Replaced obsolete value sentinel predicate with typed status + null-value rule |
| F7-01/F7-03 | `:1328-1343`, E3-M PASS summary | Resynchronized branch-B unobservable encoding and branch-A native-entry states |
| F7-03/F7-04 | `:1363-1386`, Artifact requirements | Added `NOT_APPLICABLE` evidence boundary and corrected preflight/failure source ranges |

The post-edit line numbers above were read from the final spec content after all four patches.
Stable section/symbol anchors are authoritative if later edits shift the lines.

---

## 5. Finding-by-finding record

### F7-01 — obsolete `RUNTIME_UNOBSERVABLE` value selector

**Disposition:** accepted and corrected.

#### Before

```text
`effective_apply_at_allocation.value: RUNTIME_UNOBSERVABLE` is accepted ONLY when ...
```

F6 had already changed the schema to:

```yaml
status: OBSERVED | SOURCE_PROVEN | RUNTIME_UNOBSERVABLE | NOT_APPLICABLE_NO_ALLOCATION
value: false | true | null
```

The anti-waiver rule therefore selected a value that no schema-valid trace could contain.

#### After — `phase-00-foundation.md:1058-1070`

```yaml
runtime_unobservable_is_not_a_waiver:
  when:
    effective_apply_at_allocation.status: RUNTIME_UNOBSERVABLE
  requires:
    - effective_apply_at_allocation.value: null
    - complete_atomicity_proof: option_1 | option_2
    - evidence_kind: SOURCE_CALL_GRAPH | SPANNING_INVARIANT
    - evidence_anchor: concrete_source_or_invariant_reference
```

The E3-M PASS summary at `:1328-1334` now uses the same typed representation.

#### Verification

```yaml
obsolete_value_selector_count: 0
typed_status_predicate_count: 1
allocation_null_requirement_count: 2
```

**Residual uncertainty:** none in the static encoding. Whether a future harness can produce a
non-perturbing observation/proof remains a runtime evidence question.

---

### F7-02 — equivalence rule contradicted option 2

**Disposition:** accepted and corrected.

#### Before

```text
the invariant covers the COMPLETE guard-read → spawn interval (no interleavable window)
```

This unqualified parenthetical required option-1 property P1 (“no interleaving opportunity”)
from option 2, while option 2 explicitly permits awaits and protects across all interleavings.

#### After — `phase-00-foundation.md:835-840`

```text
the protection covers the COMPLETE guard-read → spawn interval, with no UNPROTECTED
interleavable window in which unsafe state can become visible to allocation/spawn
```

The shared property is now safety under the entire interval. Option 1 may prove it by removing
all seams; option 2 may prove it with a spanning invariant across seams and awaits.

#### Verification

```yaml
unqualified_no_interleavable_window_count: 0
new_unprotected_window_requirement_count: 1
option_2_await_allowed_occurrences: 2
option_1_no_await_requirement_occurrences: 1
```

**Residual uncertainty:** option 2 still has no syntactic tell; its invariant-coverage proof
remains an adjudicated artifact obligation. That was already carried forward and is not a
static contradiction.

---

### F7-03 — `NOT_APPLICABLE` was schema-legal but branch-A-illegal

**Disposition:** accepted and corrected.

#### Before

```yaml
trace_schema:
  native_task_execute_enter.status: OBSERVED | NOT_REACHED | NOT_APPLICABLE

normative_branch_mapping.branch_A:
  native_task_execute_enter.status: OBSERVED | NOT_REACHED
```

The mapping called only two values legal even though the equivalence rule can admit a
source-verified mechanism whose dispatch/allocation path does not use native `TaskTool.execute`.

#### After

At `:966-975`:

```yaml
native_task_execute_enter.status: OBSERVED | NOT_REACHED | NOT_APPLICABLE
```

At `:1047-1057`, the meanings are fixed:

```yaml
OBSERVED: native execute was entered before the protected-boundary block
NOT_REACHED: native execute belongs to the chosen path, but the block occurred before entry
NOT_APPLICABLE: the source-verified chosen path does not use native TaskTool.execute
```

`NOT_APPLICABLE` requires an anchored call-graph/mechanism proof and cannot excuse missing
instrumentation on a path that does use native execute. Summary and Artifact authority were
resynchronized at `:1335-1343` and `:1363-1386`.

#### Verification

```yaml
branch_A_all_three_states_occurrences: 1
stale_BOTH_are_legal_occurrences: 0
OBSERVED_meaning_count: 1
NOT_REACHED_meaning_count: 1
NOT_APPLICABLE_meaning_count: 1
```

**Question for Opus:** if Opus believes every E3-M-pass-equivalent allocation path must use
native `TaskTool.execute`, counter with a source/contract proof and explain why the global
`NOT_APPLICABLE` schema member should survive. Without that proof, the three-state mapping is
the total representation.

---

### F7-04 — inaccurate pinned source range

**Disposition:** accepted conclusion; corrected authority anchors.

#### Historical F6 statement preserved, not rewritten

The Opus response labeled `task/index.ts:670-675` as the `execute()` entry range and displayed
code from earlier lines. The conclusion was valid, but the label did not contain the method
declaration or `repairTaskParams`.

#### Corrected authority — `phase-00-foundation.md:1025-1046`

```yaml
execute_declaration: task/index.ts:659-664
repairTaskParams: task/index.ts:665
batch_and_validation: task/index.ts:670-674
preflight_Promise_all: task/index.ts:681-689
per_item_catch: task/index.ts:685-687
failure_collection_and_early_return: task/index.ts:690-705
post_preflight_decisions_begin: task/index.ts:713-719
apply_setting_read: structured-subagent.ts:315-317
```

The source comment at `task/index.ts:679-680` remains relevant: no executor or job manager may
observe the batch unless every effective policy is valid.

#### Verification

Every listed range was reread at pinned OMP SHA `3a8591a8...`; targeted assertions matched the
declared method, repair call, validation call, Promise boundary, catch, failure return, async
decision, and apply-setting read. Root diff includes the Phase-00 spec only; upstream status is
clean; the Opus F6 response diff is empty.

**Residual uncertainty:** the exact future guard insertion point is not implemented or claimed.
The corrected source only proves that an in-execute, pre-allocation block is architecturally
representable.

---

## 6. Decisions deliberately unchanged

```yaml
branch_neutral_M2_common_setup: unchanged
branch_A_effect_lands_then_blocks_before_allocation: unchanged
branch_B_effect_cannot_land_and_safe_spawn_may_proceed: unchanged
option_1_seam_free_proof: unchanged
option_2_spanning_invariant_with_awaits: unchanged
pass_equivalence_escape_hatch: preserved
gating_set: [M1, M2, M2b, M4]
required_diagnostic_set: [M3]
optional_control_set: [M2-control]
settings_identity_and_boundary_timing_conjunction: unchanged
SOURCE_PROVEN_provenance_rule: unchanged
attack_placement_evidence: unchanged
observer_non_interference: unchanged
```

No E3-M mechanism was selected or implemented. No runtime PASS is claimed.

---

## 7. Verification ledger

### Completed before changelog final gate

| Check | Result |
|---|---|
| Pre-change RED assertions | All four F7 defects reproduced |
| F7-01 targeted assertions | PASS |
| F7-02 targeted assertions | PASS |
| F7-03 targeted assertions | PASS |
| F7-04 pinned-source assertions | PASS |
| `scripts/validate-template.ps1 -Verbose` | **63 passed, 0 warnings, 0 failed**; exit 0 |
| Opus F6 response diff | Empty |
| Pinned upstream worktree status | Clean |

### Final gate after this file was written

```yaml
targeted_F7_assertions: PASS
markdown_fence_check: PASS
placeholder_scan: PASS_NONE_FOUND
protected_file_scope_check: PASS
git_diff_check: PASS
repository_validation_fresh_rerun: PASS_63_PASSED_0_WARNINGS_0_FAILED
final_requirement_audit: PASS
```

The final gate was rerun after the changelog existed. A final post-status-edit verification is
reported in the user handoff together with the changelog's external SHA-256.

---

## 8. Carried uncertainties for future rounds

These are visible and reviewable but do not reopen F7 by themselves:

1. `protected_boundary_decision` models one decisive point; a mechanism with multiple decisive
   rechecks may require a future trace extension.
2. `proved_order_relations` is free-form and reviewed rather than mechanically checked.
3. `attack_placement.earliest_reachable: true` remains an evidence-backed reviewer assertion.
4. Option 1 requires a complete pinned call graph; option 2 requires a complete invariant proof.
5. `observer_non_interference`, `xd://` reachability, and preflight-count instrumentation remain
   runtime/harness construction obligations.

Codex will continue adversarial static audit after the F7 final gate. A newly discovered
contract defect will receive a new ID rather than being silently folded into an F7 claim.

---

## 9. Requested Opus peer review when quota returns

Review the normative diff and answer compactly:

```yaml
reviewed_repository_HEAD: 62fecf277dc9d5e47d06319387eac747462214c1
reviewed_post_change_spec_sha256: 9AA10395892209BFE16A5D5E81D018F44869BC2DDA21896F16EEF59E65EACDE5

F7_01: ACCEPT | PARTIAL | REJECT
F7_02: ACCEPT | PARTIAL | REJECT
F7_03: ACCEPT | PARTIAL | REJECT
F7_04: ACCEPT | PARTIAL | REJECT

for_each_non_accept:
  exact_current_authority:
  counterevidence:
  required_change:
  migration_or_regression_risk:

joint_peer_closure:
  CR45_E3M_reconciled: true | false
  E3_M_runtime_result: NOT_ATTEMPTED
  parallel_implementation: DISABLED
```

Opus should not infer agreement from Codex's temporary edit authority. Joint closure remains a
separate peer decision.
