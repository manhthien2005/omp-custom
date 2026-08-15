# Phase 00 E3-I/E3-L Terminal Precedence Correction Design

**Status:** Approved correction scope; implementation pending  
**Scope:** P00-CX-028 only: terminal-outcome precedence, recovered-retry facts, and additive re-adjudication of Attempts 4 and 5  
**Repository HEAD:** `62fecf277dc9d5e47d06319387eac747462214c1` on user-authorized dirty `main`  
**Peer basis:** Codex reopen `EF369545394E1591D81B489FB7D19345CBAA85748BD0FC79A072CC5DBA578358`; Opus round-2 acceptance `127C289BC9C4B0069C966DD75AA8466861A160E9BFDCE46B9E2B9607D3F833BF`  
**Runtime authority:** pinned OMP `17.2.10`; no provider call or new attempt is authorized  
**Parallel authority:** `DISABLED`; E3-M remains `DEFERRED_PARALLEL_DISABLED`  
**Review state:** implementation may proceed under user authorization, but the resulting correction remains provisional until later equal Opus review

## 1. Decision

Correct the shared terminal classifier so that it determines the final authoritative
assistant outcome before asking whether that outcome is an error. An earlier assistant error
that is followed by a successful retry and a later terminal `stop` outcome is superseded and
must not be classified as terminal.

Correct both E3-I and E3-I/E3-L recovered-failure helpers so their names match their behavior:
they report only assistant error messages carrying explicit
`retryRecovery.status == "recovered"`. Separately, project parent-level recovered retry facts
from parent events when an `auto_retry_start` is followed by a later authoritative non-error
assistant outcome. Parent recovery is an evidence fact; it does not override transport
sequence or nested-canary invalidity.

Replay the immutable raw evidence locally after those corrections:

- Attempt 4 becomes `INVALID_RUN / E3I_PARENT_SEQUENCE_MISMATCH` and
  `INVALID_RUN / E3IL_PARENT_SEQUENCE_MISMATCH` because its nine tool pairs omit both
  `phase00_e3l_read_apply` calls required by the joint protocol.
- Attempt 5 becomes `INVALID_RUN / E3I_NESTED_PROVIDER_RECOVERY` and
  `INVALID_RUN / E3IL_NESTED_PROVIDER_RECOVERY` because canary `e3i-runtime-3` contains an
  explicitly recovered provider error.
- Session B remains unlaunched for both attempts. Attempt 5's corrected joint skip reason is
  `A_INVALID_RUN`.
- No attempt is selected, no I1-I4 or L1-L3 artifact is materialized, and partial observations
  remain non-authoritative.
- E3-I and E3-L return from the false `BLOCKED_ENVIRONMENT` authority state to `READY`, with
  no terminal manifest artifacts. This means a valid experiment is still required; it is not
  a PASS, FAIL, provider retry authorization, or parallel authorization.

## 2. Decisive Raw Facts

### Attempt 4 parent

`session-a-attempt-004.stdout.jsonl` contains an assistant overload error at line 592,
`auto_retry_start` at line 594, successful terminal text `E3I_SESSION_A_DONE` at line 610,
and terminal `agent_end` with `stopReason: stop` at line 612. The process exit code is `0`.
The terminal stop supersedes the earlier error. The captured tool order is:

```text
bash,task,task,task,phase00_e3i_override_apply_true,bash,task,task,task
```

It is not the augmented E3-I/E3-L Session A protocol.

### Attempt 5 parent and nested canary

`session-a-attempt-005.stdout.jsonl` contains an assistant overload error at line 715,
`auto_retry_start` at line 717, successful terminal text `E3I_SESSION_A_DONE` at line 733,
and terminal `agent_end` with `stopReason: stop` at line 735. The process exit code is `0`.
The parent therefore recovered rather than terminated on overload.

`session-a-attempt-005.canary.e3i-runtime-3.jsonl` line 7 contains an assistant error with
`retryRecovery.kind: auto-retry`, `retryRecovery.status: recovered`, and attempt `1`; line 8
contains the successful terminal yield. This explicit nested recovery makes the otherwise
complete attempt non-selectable.

Attempts 1-3 have no assistant error `message_end` events and are unaffected by this
correction.

## 3. Terminal-Outcome Precedence Contract

`Get-Phase00TerminalModelFailure` applies this order:

1. If any terminal `agent_end` exists, select the last assistant message in the last terminal
   `agent_end` without pre-filtering by stop reason.
2. Otherwise, select the last assistant `message_end` without pre-filtering by stop reason.
3. Only after selecting that final authoritative message, report a failure when its
   `stopReason` is `error` or `aborted`.
4. Classify provider/environment codes from that final failure only.

The fallback exists for incomplete transports that lack terminal `agent_end`; it must obey
the same supersession rule. Exit code `0` corroborates the raw event order but is not part of
the classifier contract.

## 4. Recovered-Retry Contracts

### Nested event streams

`Get-Phase00E3IRecoveredProviderFailures` and
`Get-Phase00E3ILRecoveredProviderFailures` accept only assistant error messages whose
`retryRecovery.status` is exactly `recovered`. Their returned projection includes provider,
model, error text, recovery kind, recovery status, and recovery attempt. A bare assistant
error is not a recovered-retry fact.

### Parent event streams

The joint evidence projection records parent recovery when both conditions hold:

1. at least one parent `auto_retry_start` exists; and
2. that retry start has a later completed assistant `message_end` or terminal-agent outcome
   whose stop reason is non-error (`stop` or `toolUse`).

This deliberately does not require `auto_retry_end`, because Attempt 4 lacks that event while
its later terminal stop proves supersession. Recovery is projected per retry start, so a
later independent terminal failure does not erase a recovery that already reached a completed
non-error assistant outcome. An `auto_retry_start` followed only by errors is not recovered.

## 5. Additive Evidence Correction

Raw JSONL, run metadata, stderr, canary files, the original joint envelope, and all existing
adjudication sidecars remain byte-immutable. Add a second correction layer:

- `E3-I/raw/session-a.attempt-004.adjudication-002.json`
- `E3-I/raw/session-a.attempt-005.adjudication-002.json`
- `E3-L/raw/joint-attempt-005.adjudication-002.json`

Each new sidecar must hash-link its immediate predecessor, retain hashes of every raw input
it relies on, state the original and corrected classifications, record parent/nested retry
facts independently, and explicitly deny selection, Session B launch, automatic new
invocation, and parallel authority.

The mutable authority summaries (`E3-I/conclusion.yml`, `E3-L/conclusion.json`, and the Phase
00 manifest) are then replaced with the corrected `READY` state. The continuation changelog
records their before/after hashes so the change remains auditable even though those summaries
are not append-only raw evidence.

## 6. Failure and Non-Claim Rules

- An authoritative terminal error still maps to the existing environment or invalid-run
  taxonomy; the correction does not weaken real terminal failure handling.
- A recovered nested provider error invalidates the attempt even when its final canary
  outcome succeeds.
- Parent recovery is recorded in the joint projection even when another rule, such as exact
  sequence or nested recovery, is the load-bearing invalidity.
- `READY` means no valid selected transaction currently exists. It does not erase historical
  attempts or authorize an additional attempt.
- No provider call, Attempt 6, Session B replay, E3-M execution, spec/key audit import, or
  parallel-mode change belongs to this correction.

## 7. Verification Gates

The correction is acceptable only when:

1. focused RED tests fail for the old classifier and over-broad recovery helpers;
2. minimal implementation changes make those tests GREEN;
3. real raw Attempt 4 and 5 replay to the exact invalid-run reasons above;
4. the three second-order sidecars hash-link correctly and all cited raw hashes recompute;
5. conclusions and manifest expose `READY` with no terminal artifacts;
6. E3-M and `parallel_mode: DISABLED` are unchanged;
7. focused, full Phase 00, and repository validation pass in PowerShell 7 and Windows
   PowerShell 5.1; and
8. an English continuation changelog lists every edited file, before/after hash, exact
   semantic change, test command/result, non-claim, and frozen-file integrity check.
