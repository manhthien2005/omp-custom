# Phase 00 E3-I/E3-L Terminal Precedence Correction Plan

> **Execution rule:** Implement inline in the user-authorized dirty `main` workspace. Do not
> dispatch subagents, create a branch/worktree, stage, commit, push, pull, reset, checkout, or
> open a pull request. Use tests, hashes, immutable sidecars, and the English continuation
> changelog as checkpoints.

**Goal:** Remove the false parent-terminal provider classification from Attempts 4 and 5,
preserve recovered-retry facts at their correct scopes, and restore honest E3-I/E3-L `READY`
authority without making a provider call.

**Approved design:**
`docs/superpowers/specs/2026-08-09-phase-00-e3il-terminal-precedence-correction-design.md`

**Peer basis:** Codex reopen
`codex-response-to-opus5-p00-cx-028-reopen.md`; Opus acceptance and additional helper finding
`opus5-response-to-codex-p00-cx-028-round2.md`.

## Global constraints

- Preserve raw evidence bytes and every existing adjudication sidecar.
- Preserve frozen review artifacts at their recorded SHA-256 values.
- No provider call, Attempt 6, Session B replay, E3-M execution, or parallel-mode change.
- Do not import the independent spec/key numeric audit worktree.
- Apply authored mutations with `apply_patch`.
- Use PowerShell 5.1-compatible syntax and Pester 4 assertions.
- Treat the result as provisional pending later equal Opus review.

## Task 1: Lock pre-state and add RED terminal-precedence tests

**Files:**

- Modify: `scripts/tests/phase00-e3i.Tests.ps1`
- Modify: `scripts/tests/phase00-e3l.Tests.ps1`

- [x] Record HEAD, branch, staged count, focused file hashes, raw hashes, conclusion hashes,
  and frozen artifact hashes.
- [x] Add synthetic tests proving a recovered error followed by terminal stop is not terminal.
- [x] Add fallback tests proving the last assistant `message_end` wins even without
  `agent_end`.
- [x] Preserve tests proving a genuinely final error or aborted outcome remains terminal.
- [x] Replay real Attempt 4 and Attempt 5 parent JSONL and require `Found == false`.
- [x] Run focused tests and record the expected RED failures before production edits.

## Task 2: Lock recovered-retry semantics with RED tests

**Files:**

- Modify: `scripts/tests/phase00-e3i.Tests.ps1`
- Modify: `scripts/tests/phase00-e3l.Tests.ps1`

- [x] Require nested helpers to return only error messages with explicit
  `retryRecovery.status == recovered`.
- [x] Require returned recovery kind/status/attempt metadata.
- [x] Prove a bare assistant error is not reported as recovered.
- [x] Prove parent recovery projection accepts `auto_retry_start` followed by terminal stop,
  including a stream without `auto_retry_end`.
- [x] Prove parent recovery projection rejects a retry start followed only by terminal error.
- [x] Run focused tests and record RED.

## Task 3: Implement the minimal classifier and retry projection

**Files:**

- Modify: `scripts/lib/phase00-runtime-evidence.ps1`
- Modify: `scripts/lib/phase00-e3i-evidence.ps1`
- Modify: `scripts/lib/phase00-e3il-transport.ps1`
- Modify: `scripts/run-phase00-e3l-joint.ps1`

- [x] Select the last authoritative assistant outcome before filtering its stop reason.
- [x] Gate both nested recovered-failure helpers on exact recovered metadata.
- [x] Add one shared parent recovered-retry fact helper with fail-closed ordering.
- [x] Extend the joint session record to inspect parent events in addition to canary events.
- [x] Run focused tests until GREEN; do not refactor unrelated code.

## Task 4: Replay immutable Attempts 4 and 5

**Files:**

- Modify: `scripts/tests/phase00-e3i.Tests.ps1`
- Modify: `scripts/tests/phase00-e3l.Tests.ps1`

- [x] Load raw parent and canary JSONL directly; do not invoke OMP or a provider.
- [x] Require Attempt 4 E3-I and E3-I/E3-L transport results to be
  `INVALID_RUN / *_PARENT_SEQUENCE_MISMATCH`.
- [x] Require Attempt 5 results to be
  `INVALID_RUN / *_NESTED_PROVIDER_RECOVERY`.
- [x] Require parent recovered-retry facts for Attempts 4 and 5.
- [x] Require Attempt 5 nested recovery to point to `e3i-runtime-3`.
- [x] Require Session B to remain unlaunched and the corrected joint skip reason to be
  `A_INVALID_RUN`.

## Task 5: Add the second hash-linked correction sidecars

**Files:**

- Create: `docs/evidence/phase-00/E3-I/raw/session-a.attempt-004.adjudication-002.json`
- Create: `docs/evidence/phase-00/E3-I/raw/session-a.attempt-005.adjudication-002.json`
- Create: `docs/evidence/phase-00/E3-L/raw/joint-attempt-005.adjudication-002.json`
- Modify: `scripts/tests/phase00-e3i.Tests.ps1`
- Modify: `scripts/tests/phase00-e3l.Tests.ps1`

- [x] Compute every predecessor and raw-input hash from disk.
- [x] Write additive sidecars with exact original/corrected status, retry scope, selection,
  launch, authority, and non-claim fields.
- [x] Add tests that recompute all hash references and reject missing/forged predecessors.
- [x] Confirm every pre-existing raw/adjudication file hash remains unchanged.

## Task 6: Restore honest durable authority

**Files:**

- Modify: `docs/evidence/phase-00/E3-I/conclusion.yml`
- Modify: `docs/evidence/phase-00/E3-L/conclusion.json`
- Modify: `docs/evidence/phase-00/manifest.yml`
- Modify: `scripts/lib/phase00-evidence.ps1`
- Modify: `scripts/validate-template.ps1`
- Modify: `scripts/tests/phase00-e3i.Tests.ps1`
- Modify: `scripts/tests/phase00-e3l.Tests.ps1`

- [x] Set E3-I and E3-L authority to `READY` with no manifest terminal artifacts.
- [x] Record Attempts 4 and 5 as `INVALID_RUN`, their exact reasons, and their second-order
  sidecars in the historical conclusions.
- [x] State that no selected transaction, I1-I4, or L1-L3 authority exists.
- [x] Keep E3-M and root parallel mode byte-semantically unchanged.
- [x] Update durable tests to accept repository `READY` while preserving generic PASS, FAIL,
  and BLOCKED fixture validation.
- [x] Add the P00-CX-028 correction-chain validator to the repository validation entry point;
  require it to reject forged E3-I predecessor hashes and corrected E3-L skip reasons.

## Task 7: Cross-shell verification

- [x] Run the focused E3-I and E3-L suites in PowerShell 7.
- [x] Run the focused E3-I and E3-L suites in Windows PowerShell 5.1.
- [x] Run the complete Phase 00 suite in both shells.
- [x] Run `scripts/validate-template.ps1` in both shells.
- [x] Recompute frozen artifact hashes, all raw evidence hashes, and every new correction
  chain link.
- [x] Confirm zero staged files and no provider-backed attempt was launched by this round;
  local pinned-runtime verification processes are permitted.

## Task 8: Write the Opus continuation changelog

**File:**

- Create: `codex-phase00-p00-cx-028-correction-changelog-for-opus5.md`

- [x] Write in English and optimize for independent Opus verification.
- [x] Include scope, peer basis, pre-state, file-by-file changes, exact line anchors,
  before/after hashes, raw-event evidence, RED/GREEN chronology, all command results,
  correction-chain hashes, manifest diff, unchanged/frozen hashes, non-claims, residual risks,
  and explicit questions for Opus.
- [x] Self-review the changelog against the actual filesystem and remove no material fact.
