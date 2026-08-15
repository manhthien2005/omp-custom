# F7 Contract Correction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. This plan is assigned to inline Codex execution; do not dispatch subagents.

**Goal:** Correct F7-01 through F7-04 in the Phase-00 E3-M static contract and produce an English, evidence-complete changelog for later Opus 5 peer review.

**Architecture:** Apply four surgical normative edits to the single current-authority file, verifying each correction before moving to the next. Preserve all Opus-authored historical response files, then create one peer-facing changelog that records the exact diff, source evidence, verification output, and pending peer-review state.

**Tech Stack:** Markdown/YAML contract prose, PowerShell assertions, Git read-only diff/status checks, pinned TypeScript source evidence.

## Global Constraints

- Modify only `spec/phases/phase-00-foundation.md` as normative authority.
- Create `codex-response-F7-01-F7-04-changelog-for-opus5.md` as the peer-facing record.
- Do not modify any `opus5-response-*.md`, earlier review packet, or `_research/upstreams/oh-my-pi` file.
- Do not stage, commit, push, or create a pull request.
- Keep `E3_M_runtime_result: NOT_ATTEMPTED` and `parallel_implementation: DISABLED`.
- Use `codex_static_reconciliation: COMPLETE` only after fresh verification.
- Keep `opus_peer_review: PENDING_QUOTA` and `joint_peer_closure: PENDING`.
- Record post-edit line numbers and stable section/symbol anchors in the final changelog.

---

### Task 1: Capture the pre-change failure evidence

**Files:**
- Read: `spec/phases/phase-00-foundation.md`
- Read: `_research/upstreams/oh-my-pi/packages/coding-agent/src/task/index.ts`
- Read: `_research/upstreams/oh-my-pi/packages/coding-agent/src/task/structured-subagent.ts`

**Interfaces:**
- Consumes: F7 findings from `omp-custom-F7-post-F6-closure-audit-to-opus5.md`.
- Produces: reproducible RED evidence for F7-01 through F7-04 and exact pinned-source ranges.

- [ ] **Step 1: Assert the obsolete F7-01 selector exists**

Run:

```powershell
rg -n --fixed-strings -- '`effective_apply_at_allocation.value: RUNTIME_UNOBSERVABLE` is accepted ONLY when' spec/phases/phase-00-foundation.md
```

Expected before correction: one hit in `runtime_unobservable_is_not_a_waiver`.

- [ ] **Step 2: Assert the F7-02 contradiction exists**

Run:

```powershell
rg -n -e 'no interleavable window|INCLUDING awaits|await_allowed: true' spec/phases/phase-00-foundation.md
```

Expected before correction: the unqualified prohibition and the option-2 permissions both
exist in current authority.

- [ ] **Step 3: Assert the F7-03 domain/mapping mismatch exists**

Run:

```powershell
rg -n -e 'status: OBSERVED \| NOT_REACHED \| NOT_APPLICABLE|native_task_execute_enter.status: OBSERVED \| NOT_REACHED' spec/phases/phase-00-foundation.md
```

Expected before correction: the schema includes `NOT_APPLICABLE`; branch A lists only
`OBSERVED | NOT_REACHED`.

- [ ] **Step 4: Capture exact F7-04 source lines**

Run a PowerShell line dump for `task/index.ts:659-719` and
`structured-subagent.ts:315-317`.

Expected source facts:

```yaml
execute_declaration: 659-664
repairTaskParams: 665
validation: 670-674
preflight_Promise_all: 681-689
failure_early_return: 690-705
post_preflight_decisions: 713-719
apply_setting_read: 315-317
```

---

### Task 2: Correct F7-01 typed unobservable evidence

**Files:**
- Modify: `spec/phases/phase-00-foundation.md` under
  `runtime_unobservable_is_not_a_waiver` and the E3-M PASS summary.

**Interfaces:**
- Consumes: `effective_apply_at_allocation.status` and `.value` schema introduced by F6.
- Produces: one consistent unobservable encoding and a reachable anti-waiver predicate.

- [ ] **Step 1: Replace the obsolete selector with a status predicate**

Use this normative shape:

```yaml
when:
  effective_apply_at_allocation.status: RUNTIME_UNOBSERVABLE
requires:
  effective_apply_at_allocation.value: null
  complete_atomicity_proof: option_1 | option_2
  evidence_kind: SOURCE_CALL_GRAPH | SPANNING_INVARIANT
  evidence_anchor: concrete_source_or_invariant_reference
```

- [ ] **Step 2: Resync summary prose**

State that branch B permits allocation when the value is proven/observed false or when its
status is `RUNTIME_UNOBSERVABLE` with `value: null`, required provenance, and a complete
atomicity proof.

- [ ] **Step 3: Verify F7-01 locally**

Run targeted searches proving:

```text
obsolete value selector count == 0
new status predicate count >= 1
RUNTIME_UNOBSERVABLE branch-B mapping uses value null
```

---

### Task 3: Correct F7-02 shared interleaving semantics

**Files:**
- Modify: `spec/phases/phase-00-foundation.md` under `pass_equivalence_rule.requirements`.

**Interfaces:**
- Consumes: option-1 seam-free proof and option-2 spanning-invariant proof.
- Produces: a single shared safety property that admits both proof classes.

- [ ] **Step 1: Replace the unqualified prohibition**

Use this requirement:

```text
the protection covers the COMPLETE guard-read → spawn interval, with no UNPROTECTED
interleavable window in which unsafe state can become visible to allocation/spawn
```

- [ ] **Step 2: Preserve option-specific rules**

Do not modify these established decisions:

```yaml
option_1:
  no_await_or_async_yield: required
option_2:
  await_allowed: true
  invariant_covers_every_yield_and_synchronous_reentry: required
```

- [ ] **Step 3: Verify F7-02 locally**

Assert the unqualified `(no interleavable window)` text is absent, the new
`no UNPROTECTED interleavable window` text exists, and option 2 still contains
`await_allowed: true`.

---

### Task 4: Correct F7-03 native-entry branch totality

**Files:**
- Modify: `spec/phases/phase-00-foundation.md` under `normative_branch_mapping`,
  `branch_A_native_entry_note`, E3-M PASS summary, and artifact requirements.

**Interfaces:**
- Consumes: the three-state `native_task_execute_enter.status` schema and
  `pass_equivalence_rule`.
- Produces: three non-overlapping meanings and a truthful branch-A value for every admissible
  chosen-mechanism path.

- [ ] **Step 1: Extend branch-A mapping**

Use:

```yaml
native_task_execute_enter.status: OBSERVED | NOT_REACHED | NOT_APPLICABLE
```

- [ ] **Step 2: Define every status**

Record:

```yaml
OBSERVED: native TaskTool.execute was entered before the block
NOT_REACHED: native TaskTool.execute belongs to the chosen path, but the guard blocked before entry
NOT_APPLICABLE: the chosen source-verified mechanism's allocation path does not use native TaskTool.execute
```

- [ ] **Step 3: Resync summaries and artifacts**

Replace every branch-A “both are legal” statement with a three-state statement and retain the
source-backed explanation for the `OBSERVED` case.

- [ ] **Step 4: Verify F7-03 locally**

Assert branch A lists all three states, each state has a distinct normative meaning, and no
current-authority text still says only “both” are legal.

---

### Task 5: Correct F7-04 pinned-source provenance

**Files:**
- Modify: `spec/phases/phase-00-foundation.md` under `branch_A_native_entry_note`.
- Preserve: `opus5-response-to-gpt56-F6-01-F6-03.md`.

**Interfaces:**
- Consumes: pinned OMP source at `3a8591a8af5b6d200088d12ca75a5517cb064fa8`.
- Produces: exact source ranges supporting the already-accepted native-entry conclusion.

- [ ] **Step 1: Correct declaration, repair, and validation ranges**

State separately:

```text
execute declaration: task/index.ts:659-664
repairTaskParams: task/index.ts:665
batch/validation: task/index.ts:670-674
```

- [ ] **Step 2: Correct downstream ranges**

Use:

```text
preflight Promise.all: task/index.ts:681-689
preflight-failure early return: task/index.ts:690-705
post-preflight execution-mode decisions: task/index.ts:713-719
apply setting read: structured-subagent.ts:315-317
```

- [ ] **Step 3: Verify F7-04 locally**

Read the pinned source line-by-line and assert each contract range contains the code attributed
to it. Confirm `git diff --name-only` does not include the Opus response or upstream source.

---

### Task 6: Produce the Opus-facing changelog and run final verification

**Files:**
- Create: `codex-response-F7-01-F7-04-changelog-for-opus5.md`
- Read: `spec/phases/phase-00-foundation.md`
- Read: `omp-custom-F7-post-F6-closure-audit-to-opus5.md`
- Read: `docs/superpowers/specs/2026-08-08-f7-contract-reconciliation-design.md`

**Interfaces:**
- Consumes: verified final spec diff and source evidence from Tasks 1-5.
- Produces: token-efficient complete peer-review context for Opus 5.

- [ ] **Step 1: Record provenance**

Include repository HEAD, F6 patch SHA, pinned upstream SHA, pre/post spec SHA-256 hashes, review
packet hash, and final changelog hash handling note.

- [ ] **Step 2: Record every material edit**

For F7-01 through F7-04, include disposition, before/after semantics, exact post-edit locations,
evidence, reasoning, verification, and any residual uncertainty.

- [ ] **Step 3: Record status without claiming joint closure**

Use:

```yaml
codex_static_reconciliation: COMPLETE
opus_peer_review: PENDING_QUOTA
joint_peer_closure: PENDING
E3_M_runtime_result: NOT_ATTEMPTED
parallel_implementation: DISABLED
```

- [ ] **Step 4: Run full verification**

Run:

```powershell
./scripts/validate-template.ps1 -Verbose
git diff --check
git diff -- spec/phases/phase-00-foundation.md
git status --short
```

Also run targeted F7 assertions, Markdown fence checks, placeholder scans, and a protected-file
scope assertion.

- [ ] **Step 5: Perform a final requirement audit**

Check every acceptance criterion in
`docs/superpowers/specs/2026-08-08-f7-contract-reconciliation-design.md` against fresh command
output. If any criterion lacks evidence, leave reconciliation incomplete and document the gap.

- [ ] **Step 6: Stop without Git mutation**

Do not stage or commit. Report the working-tree files and wait for the user's next instruction
or future Opus peer review.
