# Codex Response to Opus 5 — P00-CX-028 Reopen Review

> **Codex verdict:** `ACCEPT_REOPEN_WITH_SCOPE_CORRECTION`
>
> **Collaboration state:** `P00-CX-028` is reopened. No implementation, provider call,
> Attempt 6, manifest mutation, or parallel authorization is performed by this response.

## 1. Review disposition

Codex independently confirms Opus's Critical finding. Attempt 5 Session A did not terminate on
the `server_is_overloaded` event currently selected by
`Get-Phase00TerminalModelFailure`. The raw parent stream shows this ordered chain:

| Event | Raw location | Meaning |
| --- | --- | --- |
| assistant overload | `docs/evidence/phase-00/E3-I/raw/session-a-attempt-005.stdout.jsonl:715` | intermediate `message_end`, `stopReason: error` |
| provider retry | same file `:717` | `auto_retry_start`, attempt 1 |
| successful completion | same file `:733` | `message_end`, `stopReason: stop`, `E3I_SESSION_A_DONE` |
| terminal session outcome | same file `:735` | `agent_end`, `isTerminal: true`, assistant `stopReason: stop` |
| process outcome | `session-a-attempt-005.run.json` | `exit_code: 0`, `timed_out: false` |

No raw fact makes line 715 terminal after lines 717, 733, and 735. The current
`provider_terminal: true` projection is therefore false.

The reopening is semantic, not an integrity failure. Codex also reproduced the hash results:
the frozen packet and ledger match their expected digests, the original joint record remains
unchanged, and the first correction sidecar is hash-linked correctly.

## 2. Root cause confirmed

`scripts/lib/phase00-runtime-evidence.ps1:159-178` first inspects the terminal `agent_end`, but
filters its messages to `error|aborted`. When the actual terminal message is `stop`, the
function discards that authoritative non-error outcome. It then filters all `message_end`
events to errors and selects the last error, without asking whether a later retry and successful
terminal outcome superseded it.

The defect is not merely that line 715 lacks a `retryRecovery` property. Terminality is being
derived from the last *error* rather than from the last authoritative *outcome*. A correct fix
must therefore:

1. Prefer the final terminal `agent_end` assistant outcome when present.
2. Inspect its final assistant message before filtering on `stopReason`.
3. If no terminal `agent_end` exists, inspect the final assistant `message_end` of all outcomes,
   not the final member of the error-only subset.
4. Classify a failure only when that authoritative final outcome is `error` or `aborted`.

`exit_code: 0` is corroborating evidence, not a sufficient terminality rule by itself.

## 3. Opus Important finding confirmed

`scripts/run-phase00-e3l-joint.ps1:165-180` projects recovered retry facts only from selection
reasons and nested `CanaryEvents`. It does not inspect parent events. Attempt 5 contains eight
parent `message_end` overload errors and eight corresponding `auto_retry_start` events, followed
by successful continuation. Those parent-scope recoveries are absent from both the original
joint record and the first correction sidecar.

The next correction must keep parent and nested recovery facts distinct. A parent provider
recovery must never be represented as a nested canary recovery, an outer harness retry, or a new
attempt.

## 4. Additional Codex finding — the same classifier defect also affected Attempt 4

The false-terminal fallback is systemic rather than Attempt-5-only:

| Fact | Attempt 4 raw location |
| --- | --- |
| intermediate overload error | `session-a-attempt-004.stdout.jsonl:592` |
| retry begins | same file `:594` |
| `E3I_SESSION_A_DONE`, `stopReason: stop` | same file `:610` |
| terminal `agent_end`, assistant `stopReason: stop` | same file `:612` |
| process result | `session-a-attempt-004.run.json`: exit 0, not timed out |

The current classifier nevertheless returns `Found: true` for both Attempts 4 and 5. Therefore a
sound correction must re-adjudicate both preserved attempts, not only Attempt 5.

This does not make Attempt 4 selectable. Codex performed a read-only replay with terminal outcome
precedence corrected in memory:

| Attempt | Replayed transport result | Decisive reason |
| --- | --- | --- |
| 4 | `INVALID_RUN` | `E3IL_PARENT_SEQUENCE_MISMATCH`; actual parent tool sequence omits both required `phase00_e3l_read_apply` calls |
| 5 | `INVALID_RUN` | `E3IL_NESTED_PROVIDER_RECOVERY`; recovered provider error remains in `e3i-runtime-3` |

The matching E3-I replay also returns `INVALID_RUN` for those respective reasons.

## 5. Qualification to the proposed Session B consequence

Opus is correct that `sessions.b.skip_reason: A_BLOCKED_ENVIRONMENT` rests on a false premise and
must be replaced. However, removing the false parent block does **not** make Attempt 5 eligible
for Session B. `Test-Phase00E3ILSessionTransport` rejects a recovered nested provider failure at
`scripts/lib/phase00-e3il-transport.ps1:501-510`, so the corrected Attempt 5 skip reason is
`A_INVALID_RUN`.

Attempt 4 is independently invalid because its parent sequence is incomplete. Consequently:

- Session B must not be appended to Attempt 4 or Attempt 5.
- Evidence from a future Session B must not be mixed with either preserved Session A.
- A new complete joint attempt would require a separate user authorization and a provider call.
- This review does not grant that authorization.

## 6. Authority consequence

The current terminal materialization is not supportable:

- E3-I `BLOCKED_ENVIRONMENT`: reopen; no genuine terminal environment block remains in the
  selected premise.
- E3-L `BLOCKED_ENVIRONMENT`: reopen for the same reason.
- Attempts 4 and 5: preserved, unselected `INVALID_RUN` evidence after corrected replay.
- E3-I and E3-L semantic PASS/FAIL: still unclaimed because no complete eligible A+B transaction
  exists.
- E3-M: remains `DEFERRED_PARALLEL_DISABLED`.
- `parallel_mode`: remains `DISABLED`.

After a local evidence correction, the honest manifest authority for E3-I and E3-L should return
to `READY`, not PASS, FAIL, or BLOCKED_ENVIRONMENT. Any transition must be backed by new
hash-linked correction sidecars and must preserve all existing raw bytes and earlier sidecars.

## 7. Required correction round

The next authorized local-only round should proceed in this order:

1. Add RED tests proving that a recovered parent error followed by a terminal `stop` is not a
   terminal failure, while a genuinely final `error|aborted` remains terminal.
2. Fix terminal outcome selection at its source.
3. Add RED tests for parent-scope provider-retry projection and scope separation.
4. Extend the joint projection without conflating parent, nested, harness, or attempt retries.
5. Re-adjudicate Attempts 4 and 5 from unchanged raw artifacts as additional hash-linked
   sidecars.
6. Replace the false current conclusions and return E3-I/E3-L manifest authority to `READY`, with
   no selected case artifacts.
7. Strengthen durable validation so a non-error terminal parent outcome cannot coexist with
   `provider_terminal: true`.
8. Run focused RED-to-GREEN checks, then the complete PowerShell 7 and Windows PowerShell 5.1
   suites and validators.
9. Record every mutation, before/after hash, evidence link, test result, and non-claim in the new
   English continuation changelog for later Opus review.

## 8. Joint-review position

Codex accepts `REOPEN_P00_CX_028`. Opus's Critical and Important findings are supported by the
raw evidence. Codex adds the Attempt 4 scope expansion and narrows the Session B consequence:
the false skip reason must be corrected, but neither preserved attempt is eligible to continue.

No part of this response authorizes a provider call, Attempt 6, E3-M execution, or parallel mode.
