# Opus 5 Review — P00-CX-028

## 1. Verdict

`REOPEN_P00_CX_028`

Every hash in the packet matches disk, the immutable raw joint was not rewritten, the sidecar
hash-link chain is sound, and no artifact claims semantic PASS. But the premise the entire
terminal materialization rests on is contradicted by the raw parent stream: Attempt 5 Session A
did **not** end on a terminal provider failure. Its last `server_is_overloaded` error
(`stdout.jsonl:715`) is followed by `auto_retry_start` (`:717`) and a fully successful
continuation ending `stopReason: stop` with the required sentinel `E3I_SESSION_A_DONE`
(`:733`), a terminal `agent_end` whose message is `stop` (`:735`), `exit_code: 0`, and all
six canaries emitting `PHASE00_E3I_CANARY_OK`. `provider_terminal: true`,
`failure_scope: parent-terminal`, `skip_reason: A_BLOCKED_ENVIRONMENT`, and the
`E3-L: READY → BLOCKED_ENVIRONMENT` transition are therefore unsupported by the evidence they
cite. The correction round fixed the nested retry fact while leaving a larger retry fact — the
parent's own recovered retries — unreported.

## 2. Hash and artifact-chain audit

| Check | Expected | Observed | Result |
| --- | --- | --- | --- |
| Review packet | `ACFF1179…AC8CF4` | identical | MATCH |
| Full ledger | `47607590…98F63A` | identical | MATCH |
| Review prompt | `49DB7B55…828C8B` | identical | MATCH |
| 6 Section-4 load-bearing artifacts | per packet | all identical | 6/6 MATCH |
| 9 Attempt 5 Session A raw files | per packet | all identical | 9/9 MATCH |
| `sidecar.correction_of.sha256` → raw joint | `BDC3A720…B51948C` | recomputed equal | LINK OK |
| `conclusion.joint_adjudication.sha256` → sidecar | `C1D2307F…7BF0B5D` | recomputed equal | LINK OK |
| `correction_reason` exact | `E3IL_RETRY_FACT_UNDER_REPORTED` | identical | MATCH |
| `sessions.a.recovered_provider_retry` raw → sidecar | `false` → `true` | `false` → `true` | AS CLAIMED |
| `retry_evidence` event `f04e9843` in raw canary | present, recovered | `canary.e3i-runtime-3.jsonl:7` + superseding child `:8` | CORROBORATED |
| Selected I1-I4 / L1-L3 artifacts | 0 | 0 | MATCH |
| `parent_stderr` | empty-string digest | 0 bytes | MATCH |

No hash defect exists. The reopening is a semantic-fidelity defect, not an integrity defect.

## 3. Findings

### CRITICAL — Attempt 5 Session A was not parent-terminal; it completed successfully

- **Claim rejected:** "Session A parent events contain terminal OmniRoute `server_is_overloaded`
  evidence" / `provider_terminal: true` / `failure_scope: parent-terminal` / "Parent-terminal
  provider overload stopped continuation, so Session B was not invoked."
- **Evidence:**
  - `docs/evidence/phase-00/E3-I/raw/session-a-attempt-005.stdout.jsonl:715` — last
    `message_end`, `stopReason: error`, `server_is_overloaded`, **no** `retryRecovery` key
  - same file `:717` — `auto_retry_start` immediately follows that error
  - same file `:718-732` — `agent_start`, `turn_start`, 12 `message_update` events
  - same file `:733` — `message_end`, `stopReason: stop`, text `E3I_SESSION_A_DONE`
  - same file `:735` — `agent_end`, `isTerminal: true`, `messages[0].stopReason: stop`
  - `session-a-attempt-005.run.json` — `exit_code: 0`, `timed_out: false`
  - all 6 `session-a-attempt-005.canary.*.jsonl` — each contains `PHASE00_E3I_CANARY_OK`
  - 27 `toolCall` blocks cover all 8 prompt steps of
    `E3-I/fixture/prompts/session-a.md`, through `e3i-runtime-3`
  - **Root cause:** `scripts/lib/phase00-runtime-evidence.ps1:156-183`. Branch 1 correctly
    inspects the `agent_end`(`isTerminal`) messages and finds no `error`/`aborted` — the
    terminal message is `stop`. Execution then falls through to the unconditional fallback at
    `:177-183`, which takes `$messageEnds[-1]` — line 715 — with no check that the error was
    superseded by a successful retry. `phase00-e3il-transport.ps1:396-402` then maps
    `overload` → `P00-RUNTIME-PROVIDER-OVERLOAD` as an environment block, and
    `run-phase00-e3l-joint.ps1:194` derives `provider_terminal` from that selection status
    rather than from any independent terminality observation.
- **Observed:** the parent recovered from every provider error and finished its prescribed
  procedure. 8 `message_end` errors (`:26,236,246,489,499,509,610,715`) against 8
  `auto_retry_start` (`:28,238,248,491,501,511,612,717`); 4 `auto_retry_end` all
  `success: true` carrying 7 `recoveredErrors`; the 8th retry produced the successful
  terminal turn.
- **Expected:** a run whose terminal `agent_end` message is `stop`, whose exit code is 0, and
  whose every prescribed step completed is not `BLOCKED_ENVIRONMENT` on a
  parent-terminal-failure ground. Codex's own precedence principle — a recovered failure is a
  fact but not a terminal outcome — applies to the parent exactly as it applies to
  `e3i-runtime-3`.
- **Impact:** invalidates `sessions.a.provider_terminal` in both the immutable raw joint and
  the sidecar, `adjudication.precedence` in
  `E3-L/raw/joint-attempt-005.adjudication.json`, `terminal_parent_failure.terminal: true`
  in `E3-I/raw/session-a.attempt-005.adjudication.json` (which simultaneously records
  `runtime_record.parent_exit_code: 0`), `E3-L/conclusion.json:state`, the
  `E3-L: READY → BLOCKED_ENVIRONMENT` manifest transition (`manifest.yml:128`), and
  `sessions.b.skip_reason: A_BLOCKED_ENVIRONMENT` — Session B was withheld on a false
  premise. P00-CX-028 cannot be a faithful terminal representation of a run that did not
  terminate in failure.
- **Minimal correction:** gate the `:177-183` fallback so an error is terminal only when it is
  not superseded — i.e. treat the run as parent-terminal only if the final
  `agent_end`(`isTerminal`) assistant message has `stopReason` in `error`/`aborted`, or the
  error carries `retryRecovery.status != 'recovered'` and no successful continuation follows.
  Then re-derive Attempt 5 adjudication from the unchanged raw set as a **second** hash-linked
  sidecar (no provider call, no Attempt 6, raw bytes still immutable), and re-evaluate whether
  Session A is semantically adjudicable and whether Session B must now be launched under a
  separately authorized round.

### IMPORTANT — the corrected retry projection still under-reports, in the same class it fixes

- **Claim rejected:** "future joint writes inspect `Invocation.CanaryEvents` using the existing
  recovered-provider helper" resolves `E3IL_RETRY_FACT_UNDER_REPORTED`.
- **Evidence:** `scripts/run-phase00-e3l-joint.ps1:165-180` consults only
  `Selection.Reasons` then `Invocation.CanaryEvents`; no parent-event branch exists.
  `E3-L/raw/joint-attempt-005.adjudication.json` records `automatic_retry: false` and a
  single `retry_evidence` object scoped to `canary_id: e3i-runtime-3`.
- **Observed:** the parent stream itself contains 8 `auto_retry_start` events and 4
  `auto_retry_end` events with `success: true` and 7 aggregate `recoveredErrors`
  (`stdout.jsonl:57,326,589,690`). None is represented anywhere in the corrected sidecar.
- **Expected:** if the correction's stated purpose is that recovered provider retries must not
  be silently dropped, parent-scope recoveries are strictly more load-bearing than nested ones
  — they are the events that decide terminality.
- **Impact:** Important rather than Critical only because the Critical finding already forces
  re-derivation; it is the same defect class the round claims to have closed, so closing
  P00-CX-028 would leave the stated invariant unmet.
- **Minimal correction:** extend the projection to parent events and record parent recovered
  retries as a distinct field (e.g. `sessions.a.parent_recovered_provider_retries`), with a
  fail-closed validator invariant that `provider_terminal: true` is inconsistent with
  `parent_exit_code: 0` plus a non-error terminal message.

### MINOR — no defect found in immutability, sidecar constraints, or non-claim boundary

Recorded for completeness: the decision not to rewrite the raw joint is correct and verified;
the four malformed-sidecar negative controls target the right invariants; zero selected
I1-I4/L1-L3 artifacts exist; `parallel_mode: DISABLED` and
`E3-M: DEFERRED_PARALLEL_DISABLED` hold at `manifest.yml:4,134`.

## 4. Mandatory-question answers

| # | Decision | Decisive evidence |
| --- | --- | --- |
| 1 | REJECT | Rule is sound; premise false. `stdout.jsonl:715` error is superseded by `:717` retry → `:733` `stop` → `:735` `agent_end.messages[0].stopReason: stop`; `run.json` `exit_code: 0` |
| 2 | ACCEPT | Raw joint byte-identical to `BDC3A720…`; `correction_of.sha256` recomputes equal; sidecar is additive, not a rewrite |
| 3 | REJECT | Constraints are individually correct but incomplete. Missing invariants: (a) `provider_terminal` consistency with terminal message + `parent_exit_code`; (b) retry projection completeness over parent scope. `scripts/lib/phase00-evidence.ps1:412-487` checks predecessor/hash/reason/`true` only |
| 4 | REJECT | Provider execution, selection eligibility, and retry policy are correctly untouched, but retry-fact preservation is canary-scoped only — `run-phase00-e3l-joint.ps1:165-180` |
| 5 | ACCEPT | Structure is legitimate: `E3-I/raw/session-a.attempt-005.adjudication.json` re-hashes the Session A raw set independently and keeps separate `non_claims`. Both nonetheless inherit the Q1 premise defect |
| 6 | REJECT | Transition is well-formed but unsound: `manifest.yml:128` and `E3-L/conclusion.json:state` assert `BLOCKED_ENVIRONMENT` for a run that completed with `exit_code: 0` and emitted `E3I_SESSION_A_DONE` |
| 7 | ACCEPT | `E3-L/conclusion.json` `non_claims`, `parallel_authorized: false`, `e3_m_replaced: false`, `cases_materialized: []`; `E3-I/conclusion.yml:43-49`; 0 selected artifacts |

## 5. Authority and non-claim check

- E3-I: `BLOCKED_ENVIRONMENT` — **disputed by this review** (Critical finding)
- E3-L: `BLOCKED_ENVIRONMENT` — **disputed by this review** (Critical finding)
- E3-M: `DEFERRED_PARALLEL_DISABLED` — undisputed, unchanged
- parallel_mode: `DISABLED` — undisputed, unchanged; nothing in this review authorizes parallel
- selected I1-I4/L1-L3 artifacts: 0
- Attempt 6/provider call authorized by this review: NO

## 6. Next action

Gate the terminal-failure fallback at `scripts/lib/phase00-runtime-evidence.ps1:177-183` so a
superseded/recovered provider error cannot be classified terminal, then re-derive the Attempt 5
adjudication from the unchanged raw set as an additional hash-linked sidecar — no provider call,
no Attempt 6, no mutation of existing raw bytes — and bring the re-derived state back for joint
review before any manifest transition.
