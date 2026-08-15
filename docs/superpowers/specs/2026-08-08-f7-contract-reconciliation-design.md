# F7 Contract Reconciliation Design

> **Author:** GPT-5.6 Codex  
> **User approval:** 2026-08-08  
> **Status:** Approved design; implementation not started  
> **Peer-review status:** Opus 5 review deferred until quota is available

## 1. Objective

Reconcile F7-01 through F7-04 in the current Phase-00 E3-M static contract without widening
the implementation scope, editing Opus-authored historical responses, or claiming joint peer
closure before Opus can review the Codex-authored patch.

The implementation must leave an English, evidence-complete changelog that lets Opus recover
the full decision context and review every Codex change without rereading the entire prior
conversation.

## 2. Authority and edit boundary

### Files Codex may modify

- `spec/phases/phase-00-foundation.md` — current normative authority for the F7 corrections.

### Files Codex will create

- `codex-response-F7-01-F7-04-changelog-for-opus5.md` — peer-facing change and evidence record.

### Files Codex will not modify

- `opus5-response-to-gpt56-F6-01-F6-03.md` — preserved as the immutable historical peer
  response that motivated the F7 audit.
- Earlier Codex/Opus review packets — preserved as historical evidence.
- OMP upstream source under `_research/upstreams/oh-my-pi` — read-only evidence at pinned SHA
  `3a8591a8af5b6d200088d12ca75a5517cb064fa8`.

### Git boundary

Codex will not create a commit, stage files, push, or open a pull request in this round. The
user approved an inspectable working-tree patch plus changelog. Commit creation remains a
separate user decision.

## 3. Normative changes

### F7-01 — typed `RUNTIME_UNOBSERVABLE` encoding

Retarget `runtime_unobservable_is_not_a_waiver` from the obsolete selector
`effective_apply_at_allocation.value: RUNTIME_UNOBSERVABLE` to the F6 representation:

```yaml
effective_apply_at_allocation:
  status: RUNTIME_UNOBSERVABLE
  value: null
```

The rule will continue to require a complete option-1 or option-2 proof, a source-call-graph or
spanning-invariant evidence kind, and a concrete evidence anchor. Summary prose will name
`RUNTIME_UNOBSERVABLE` as a status rather than an allocation value.

### F7-02 — shared safety property for both atomicity options

Replace the unqualified `no interleavable window` parenthetical in `pass_equivalence_rule`
with a shared requirement: no **unprotected** interleavable window may allow unsafe state to
become visible to allocation or spawn.

This preserves:

- option 1: a seam-free/non-interleavable source path;
- option 2: protected interleavings, including awaits, under a spanning invariant.

No-await will remain an option-1 requirement only.

### F7-03 — total native-entry mapping

Add `NOT_APPLICABLE` to the branch-A normative domain for
`native_task_execute_enter.status`. Define it narrowly: it is legal only when the chosen
source-verified mechanism's allocation path does not use native `TaskTool.execute`.

Keep the other meanings distinct:

- `OBSERVED`: native execute was entered before the block;
- `NOT_REACHED`: native execute belongs to the path but the guard blocked before entry;
- `NOT_APPLICABLE`: native execute is not part of the chosen mechanism's path.

This keeps the trace schema total without forcing every pass-equivalent mechanism into path A
or path B.

### F7-04 — exact pinned-source anchors

Correct the current authority's source ranges to the pinned source:

```yaml
execute_declaration: task/index.ts:659-664
repairTaskParams: task/index.ts:665
batch_and_validation: task/index.ts:670-674
per_item_preflight_Promise_all: task/index.ts:681-689
preflight_failure_early_return: task/index.ts:690-705
post_preflight_execution_mode_decisions: task/index.ts:713-719
apply_setting_read: structured-subagent.ts:315-317
```

The conclusion remains unchanged: a correct guard may block after entering native execute but
before any worker allocation or spawn.

The Opus-authored F6 response will not be rewritten. Its inaccurate range will be quoted in the
new changelog and marked as superseded by the corrected normative anchor.

## 4. Changelog contract

`codex-response-F7-01-F7-04-changelog-for-opus5.md` will be written in English and optimized
for a quota-constrained peer review. It will contain:

1. reviewed repository HEAD, F6 patch commit, pinned OMP SHA, and relevant file hashes;
2. final disposition for every F7 finding;
3. exact pre-change and post-change text or compact semantic diff;
4. post-edit file locations and stable section/symbol anchors;
5. source evidence and reasoning for each correction;
6. verification commands, exit codes, and material output;
7. unchanged decisions and explicit non-goals;
8. unresolved uncertainties and questions for Opus;
9. a compact review checklist that Opus can accept, reject, or counter item by item;
10. status wording that distinguishes Codex reconciliation from joint peer closure.

## 5. Status semantics

After successful Codex verification, the changelog may state:

```yaml
codex_static_reconciliation: COMPLETE
opus_peer_review: PENDING_QUOTA
joint_peer_closure: PENDING
E3_M_runtime_result: NOT_ATTEMPTED
parallel_implementation: DISABLED
```

It must not state `CR45_E3M_reconciled: true` as a joint Codex–Opus determination while Opus
has not reviewed the Codex-authored diff.

## 6. Verification design

Verification will include all of the following:

1. Targeted assertions proving the obsolete allocation-value selector is absent and the new
   status-plus-null predicate is present.
2. Targeted assertions proving the equivalence rule no longer forbids protected option-2
   interleavings and still keeps option 1 seam-free.
3. Targeted assertions proving all three native-entry states have normative meanings and
   branch-A coverage.
4. Direct pinned-source checks for every F7-04 line range.
5. A stale-authority scan across the whole Phase-00 spec for the superseded formulations.
6. Markdown fence and placeholder checks for the spec and changelog.
7. `git diff --check` plus a scoped diff review proving no Opus-authored response or upstream
   source was modified.
8. The repository's relevant validation command, `scripts/validate-template.ps1 -Verbose`,
   with the actual result recorded rather than inferred.

## 7. Failure handling

- If a targeted assertion fails, Codex will not mark that finding reconciled.
- If repository validation exposes an unrelated pre-existing failure, the changelog will
  separate it from the F7 patch and preserve the exact output.
- If a new normative contradiction appears during the post-patch sweep, Codex will open a new
  finding instead of hiding it inside the F7 completion claim.
- If exact line numbers shift during editing, the final changelog will use the verified
  post-edit lines and stable headings/symbol names.

## 8. Acceptance criteria

The Codex-authored reconciliation is complete only when:

- all four F7 findings have an implemented disposition supported by the final diff;
- the stale selector and unqualified interleaving prohibition no longer exist in current
  authority;
- native-entry statuses are total and semantically distinct;
- source anchors match the pinned source exactly;
- the English changelog contains every material edit and verification result;
- no historical Opus response or pinned upstream source was modified;
- runtime E3-M remains `NOT_ATTEMPTED` and parallel implementation remains `DISABLED`;
- joint peer closure remains pending Opus review.
