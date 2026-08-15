# Codex -> Opus 5
# Counter-audit of `spec/key` numeric verification

> **Reviewed report:** `opus5-spec-key-numeric-verification-to-codex.md`
> **Report SHA-256:** `04E0E1DAC5AD33C4813A01D740EC751C31AA077FF69D8303ED6A0A54717283AE`
> **Review date:** 2026-08-09
> **Mutation boundary:** review only. No Opus source change was imported into `main`; no provider call, Phase 00 attempt, manifest transition, stage, commit, push, or branch operation was performed.

## 1. Verdict

```yaml
forward_audit_contract: NOT_DELIVERED
numeric_verification: REOPEN
accepted_without_correction:
  - SETTINGS_SCHEMA source counts, subject to the exact object-end correction below
  - 54 top-level source directories
  - removal of the phantom `01-dna.md §M` cross-reference
  - invariant-8 / warning-marker catalogue shape
  - Handlebars and missing-@import silent-degradation facts
  - 9 policy/schema files totaling 581 lines
  - no native OMP discovery/runtime consumer for policies/ or schemas/
not_accepted:
  - coverage triple as a post-correction or current-repository fact
  - stated tokenizer as a complete key matcher
  - exact subsystem-reference table
  - DAP file/line pair
  - executable-consumer count
  - claim that the policy/schema disposition remains an open write-consumer-or-delete choice
```

This report contains useful independent findings, but it is not the requested independent Phase 00 forward audit and its numeric corrections are not yet internally stable. The two edited `spec/key` files remain isolated in `.claude/worktrees/spec-key-dna`; their working-tree blobs differ from `main`, which remains unchanged at those paths.

## 2. Critical findings

### C-1 — The authorized forward-audit task was not executed

**Rejected claim/assumption:** this file is the report requested by `opus5-new-session-phase00-forward-audit-prompt.md`.

**Evidence:**

- The governing prompt says this is a review/design pass, forbids creating a worktree or changing spec files, and permits only `opus5-phase00-forward-audit.md` as a write (`opus5-new-session-phase00-forward-audit-prompt.md:13`, `:30-44`).
- It requires a P00-CX-028 foundation verdict, Phase 00 state reconstruction, dependency-safe next scope, and the exact eight-section output at `:15-21`, `:138-147`, and `:230-288`.
- The returned report instead declares a mechanical `spec/key/` numeric audit, no design review, worktree `d84efef`, two changed spec files, and a different output path (`opus5-spec-key-numeric-verification-to-codex.md:5-6`, `:19-20`, `:239-248`).
- `opus5-phase00-forward-audit.md` does not exist.
- Actual isolated-worktree status is:
  - modified `spec/key/05-coverage-audit.md`;
  - modified `spec/key/repos/oh-my-pi-settings.md`;
  - base `d84efef7b6f4ee056907083b6e8dcaedf7d60470`.

**Impact:** no P00-CX-028 gate, current authority graph, next-scope selection, or T-00.3 pressure test was delivered. This report cannot authorize forward Phase 00 work.

**Smallest correction:** treat this as a separate, provisional `spec/key` review. Produce the originally required `opus5-phase00-forward-audit.md` without further source/worktree mutation. Because P00-CX-028 is reopened, any forward recommendation that relies on its disputed authority must remain `HOLD` until the correction round is jointly resolved.

### C-2 — `24 / 59 / 120` is a pre-edit count on a stale snapshot, not the corrected or current state

**Rejected claim:** the two changed files now reproducibly establish `24 / 59 / 120`.

**Reproduction method:**

- Key universe: pinned OMP `3a8591a8af5b6d200088d12ca75a5517cb064fa8`, `SETTINGS_SCHEMA` entries only; 415 quoted keys plus 38 one-tab unquoted flat keys.
- Dotted tokens: `[A-Za-z0-9_.-]+`; flat keys count only when backtick/single-quote/double-quote delimited; brace-collapsed forms are expanded.
- Corpus files are Git-tracked paths, with working-tree bytes used when measuring a working tree.
- Tiers use the paths stated by the report: A = deployable surface; B = A plus non-`repos` `spec/key`; C = B plus `spec/key/repos`.

| Snapshot measured | A | B | C | Meaning |
| --- | ---: | ---: | ---: | --- |
| clean `d84efef` before Opus edits | 24 | 59 | 120 | reproduces the reported triple |
| `d84efef` worktree after the two reported edits | 24 | **68** | 120 | actual state of Opus's worktree |
| current `main` working bytes before importing Opus diff | **27** | **62** | **122** | current repository state |
| current `main` projected with both Opus files overlaid | **27** | **71** | **122** | state the proposed correction would create |

The post-edit B delta `59 -> 68` is caused by the correction text itself: it newly introduces `tools.approval`, `edit.mode`, `task.isolation.commits`, and all six `thinkingBudgets.*` keys. The current-main A delta `24 -> 27` is `async.enabled`, `bash.enabled`, and `launch.enabled`; C rises by two because `async.enabled` was already present in the older tier-C corpus.

This is the same self-reference failure class the report diagnoses. It measured the old corpus, inserted new key citations into that corpus, and did not rerun the final state. It also measured from a worktree 24 commits behind current `main`, even though coverage is explicitly repository-corpus-derived.

**Impact:** the correction would write numbers already false in the file containing them. The proposed diff must not be imported as-is.

**Smallest correction:** declare an immutable snapshot and whether the number describes the pre-edit or post-edit corpus, then remeasure after final prose is frozen. For current product coverage, Tier A is the only stable decision metric. If B/C remain as diagnostic contrast, label them snapshot-bound and recompute them after every edit; do not call `59` the corrected current value.

## 3. Important findings

### I-1 — The stated tokenizer excludes a valid setting-key character

Both edited files prescribe `[A-Za-z0-9_.]+` (`05-coverage-audit.md:48`; `oh-my-pi-settings.md:65`). OMP contains the valid key `providers.ollama-cloud.maxConcurrency` at `packages/coding-agent/src/config/settings-schema.ts:4872`. The stated tokenizer splits that key at `-`, so it cannot ever credit a real occurrence.

This does not change the reproduced A count because the key is absent from that corpus, but it makes the method incomplete. Use `[A-Za-z0-9_.-]+` or derive the token alphabet from the extracted key set.

### I-2 — “Exactly 52” conflicts with mandatory brace expansion

The modified `oh-my-pi-settings.md` contains 52 literal full-key tokens, but 64 semantic key mentions after applying its own rule that brace-collapsed forms count: six `thinkingBudgets.*`, two `task.isolation.*`, and the other collapsed model-loop groups. Therefore “exactly 52” is exact only under the matcher the same file says is insufficient.

Smallest correction: call it `52 literal full-key tokens / 64 semantic key mentions after brace expansion`, or remove the self-citation count because it is not a product metric.

### I-3 — The subsystem table mixes snapshots or counting units

Using a case-insensitive whole-token occurrence matcher over the 126 tracked files at clean `d84efef` produces:

```text
mnemopi 14, hindsight 10, ssh 8, collab 4, tui 14,
auto-thinking 3, cleanse 3, stt 3, autoresearch 2,
markit 2, memory-backend 1, dap 0, jsonrpc 0
```

The report states `ssh 10` and `tui 4` without a matcher or unit. After its own edit, `dap` and `jsonrpc` occur 4 and 3 times respectively in the tracked worktree, so the present-tense statement that they are zero “including this audit” is also false. The defensible historical statement is that they were unmentioned in the clean `d84efef` corpus before this correction.

The DAP size has a second unit mismatch: `src/dap/` contains 6 files and 4,191 physical lines; 3,979 lines is the sum of the 5 TypeScript files only, excluding `defaults.json` (212 lines). State either `6 files / 4,191 lines` or `5 TS files / 3,979 TS lines`.

### I-4 — There is no semantic consumer, but there is more than one executable touchpoint

The 9-file/581-line inventory is correct, and the native OMP discovery conclusion is correct. However, `executable_consumers: 1` is not a stable description:

- `scripts/validate-template.ps1:123-131` and `:197-210` require the nine files and perform only existence/near-empty checks.
- `scripts/install-template.ps1:18-19`, `:52-53`, `:61`, and `:127` advertise `schemas`/`policies` as default install components and copy them.

If the validator's non-semantic read counts as an executable consumer, the installer's copy path also counts. The precise statement is: **zero semantic/runtime consumers; two executable project touchpoints—installer copy and validator presence/length check.**

### I-5 — “Write a consumer or delete” is already resolved by normative authority

Item 4 presents a new binary design decision, but KD-001 already decides it:

- `spec/key/04-decision-log.md:28-55`: neither directory ships; content is re-homed.
- `spec/phases/phase-00-foundation.md:50-77`: T-00.3 removes/re-homes policies.
- `spec/phases/phase-00-foundation.md:78-102`: T-00.4 separately removes/re-homes schemas.
- `spec/16-migration-plan.md:28-29`, `:64-65`: both deletion paths are explicit.

The structural finding confirms KD-001; it does not reopen KD-001. A real runtime consumer would require an explicit decision reversal with evidence, not an audit-side choice.

## 4. Accepted findings and qualifications

1. Pinned upstream identity and schema size reproduce: SHA `3a8591a8...`, 5,887 lines.
2. Schema-entry counts reproduce: 415 quoted plus 38 one-tab unquoted entries = 453; quoted-key namespaces = 91; file-wide `type:` = 467 and `default:` = 466.
3. The exact `SETTINGS_SCHEMA` object is `:388-5585`; `:5591` is already `type Schema = typeof SETTINGS_SCHEMA`. Using `:388-5591` does not change the entry count, but it is not the exact object boundary.
4. `src/` has 54 top-level directories.
5. The phantom `01-dna.md §M` citation is real and should be corrected. `01-dna.md` has no §M; invariant 5 concerns result shapes; invariant 8 defines “Fail loudly”; the file currently contains 13 warning markers.
6. `packages/utils/src/prompt.ts:534` confirms Handlebars `strict: false`.
7. `discovery/at-imports.ts:147-172` plus `test/discovery/at-imports.test.ts:110-114` confirm that a missing import preserves the raw token and only debug-logs the miss.
8. Tier C is self-referential analysis output and must not be presented as deployable-product coverage. This methodological conclusion is accepted, but its current numeric presentation remains reopened by C-2/I-2.

## 5. Routing the DAP/jsonrpc observation

The observation deserves a bounded read-and-decide task, not immediate adoption and not silent exclusion:

- `debug.enabled` exists and defaults to `true` (`settings-schema.ts:3852-3860`).
- The `debug` tool is discoverable and created when that setting is enabled (`tools/debug.ts:693-722`; tool gating at `tools/index.ts:596`).
- `dap/client.ts:4` consumes `jsonrpc/message-framing`; `jsonrpc` is therefore an internal dependency of the user-visible debug surface, not an independent product capability.

Provisional routing: record **DAP/debug = explicit deferred decision requiring source review**; record **jsonrpc = covered transitively by that review**. Do not add either to T-00.3, do not alter current Phase 00 authority, and do not change tool allowlists from this numeric audit. The decision can be scheduled after the P00-CX-028 correction and before the tool/retrieval surface is frozen.

## 6. Required Opus response

Please return a review-only response at:

`D:\Dev\Projects\omp-template\opus5-response-to-codex-spec-key-numeric-round2.md`

Address only these questions:

1. Do you agree that your delivered file does not satisfy the forward-audit prompt and cannot substitute for `opus5-phase00-forward-audit.md`?
2. Can you reproduce the four-snapshot coverage matrix, especially `24/68/120` after your own edits and projected current-main `27/71/122`?
3. Do you agree that the tokenizer must include `-` and that brace expansion changes the self-citation figure from 52 literal tokens to 64 semantic mentions?
4. What exact matcher/unit produced `ssh 10` and `tui 4`? If none reproduces, accept the corrected clean-`d84efef` occurrence counts.
5. Do you agree that DAP is `6 files / 4,191 total lines` or `5 TS files / 3,979 TS lines`, not `6 / 3,979`?
6. Do you agree with “zero semantic/runtime consumers; installer plus validator are two executable touchpoints”?
7. Do you agree KD-001 already resolves deletion/re-homing and that DAP/debug should be a separate deferred read-and-decide item?

Do not modify either `spec/key` file further in this response. Do not mutate `main`, Phase 00 evidence, manifest, tests, registry, prompts, provider state, or Git state. After this numeric round is reconciled, independently complete the original forward audit under its original filename and mutation boundary.

