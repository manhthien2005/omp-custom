# Codex Peer Review — Topic 01 — Attempt 02

```yaml
reviewer: codex-cli
requested_model: gpt-5.6-sol
reasoning_effort: xhigh
thread_id: 019ff48a-d7f6-7d72-920a-b3dcf1a56dbd
prompt_sha256: 98BD78D3BC5508AA03B3927784403EA7AC5D23FDE544DD3CA41D0297A822133C
sandbox: workspace-write-with-explicit-read-only-prompt
session: ephemeral
input_tokens: 5466371
cached_input_tokens: 5251840
output_tokens: 22075
verdict: INSUFFICIENT_EVIDENCE
substantive_disposition: REOPEN_TOPIC_01_IF_HASHES_VERIFIED
```

The controlling process verified before and after this review that all frozen Topic 01 hashes
were unchanged. The Codex CLI policy rejected the reviewer's hashing commands before execution,
so the top-level `INSUFFICIENT_EVIDENCE` is retained as issued. The substantive Important
finding is independently adjudicated in a separate correction record.

---

## 1. Verdict

INSUFFICIENT_EVIDENCE

No executable produced a conflicting hash, and Attempt 01's unsupported `AA517C...DFA0` value
is not credible evidence against the controller-observed `D1A99C...C5AE2`. However, this
attempt could not independently verify any required SHA-256 because the sandbox rejected every
hashing command before execution. The completed substantive audit also found an Important
adaptive-stopping defect that would require `REOPEN_TOPIC_01` if the frozen hashes are
subsequently verified.

## 2. Hash and source audit

| Check | Expected | Observed | Result |
|---|---|---|---|
| Primary review prompt | `6B7FAEE9BE002E2022426D4B1ACD7A0B86A00A68B59ABABFFA795C7A8A7CF118` | No executable hash; command rejected before execution | INSUFFICIENT |
| Review packet | `3EB732F06859F854A85E9E2FF52742B53FA6E19F0AC0494754B8C1CCB0101F9A` | No executable hash; command rejected before execution | INSUFFICIENT |
| Full ledger | `11491FC80CBB287462369E42CFB2A680DDAF0C2A12140E00B24FF1C6D0E4DA0C` | No executable hash; command rejected before execution | INSUFFICIENT |
| Topic 01 design | `D4505E510A66D5746A88AAE53BDDDF017DC7B0D0FCECAA811656D939B684FCF3` | No executable hash; command rejected before execution | INSUFFICIENT |
| Token-quality model | `F83A471CD01377BBE24F98679359B8D86354AEDE87941130D8167D2E1E186D27` | No executable hash; command rejected before execution | INSUFFICIENT |
| Decision log | `D1A99C8C0094837A8FBBBAD773EC6CFAAB168D4306C1B9D5CED4F9CBD72C5AE2` | Controller reported expected value; independent command rejected before execution | INSUFFICIENT |
| Validation/evaluation | `F92E031ED121297BC34A4365659C37A3F644E713342470540DC6A799A7347DEA` | No executable hash; command rejected before execution | INSUFFICIENT |
| Phase 03 | `F8FD4988D9C13B690BEF38BE12E856D7AB2F485D3597153FF828338628D2BBB4` | No executable hash; command rejected before execution | INSUFFICIENT |
| Phase 06 | `3682FF448A23F81EF951229FA4AE1075BD7AF451AD89EC3221FC66F431F46E28` | No executable hash; command rejected before execution | INSUFFICIENT |
| Phase 07 | `D43A3858D638639EE2B332AF60BA4B0FCA70B4834AD411271ACD050AF8591E8C` | No executable hash; command rejected before execution | INSUFFICIENT |
| Changelog | `718932BCEADB64E8F8ACD0264317CDDEA61D46F2F099ADC35D1319A572CE169D` | No executable hash; command rejected before execution | INSUFFICIENT |
| Spawn telemetry claim | Per-spawn identity, role, usage, duration, token fields | Clean pinned source `3a8591a8...`; fields present at `task/types.ts:471-510` | PASS |
| Token-fallback claim | Breakdown basis; fallback may contain cache-read | `getUsageTokens()` computes input + output + cache-write, then falls back to `totalTokens`, documented as including cache-read at `task/executor.ts:759-782` | PASS |
| Session aggregation claim | Main assistant and task-child usage both aggregated | Both branches are added at `session/session-stats.ts:67-91` | PASS |
| JSON event claim | Usage-bearing authoritative messages preserved | `message_end`/`agent_end` retain messages at `modes/print-mode.ts:47-83`; all events emit in JSON mode at `:191-194` | PASS |

## 3. Findings

### IMPORTANT — Adaptive stopping does not preserve the promised 95% confidence

- Classification: actionable
- Claim rejected: A predeclared adaptive stopping rule combined with 95% paired/bootstrap
  intervals is sufficient to maintain a 95% promotion decision.
- Evidence: `spec/13-validation-and-evaluation.md:326-337`,
  `spec/13-validation-and-evaluation.md:350-367`,
  `spec/phases/phase-06-evaluation.md:180-196`
- Observed: The procedure repeatedly evaluates nominal 95% bounds and stops when a promotion
  condition, rejection condition, or budget is reached. It freezes the stopping rule but
  requires no confidence sequence, alpha-spending rule, multiplicity-adjusted look schedule,
  or equivalent sequentially valid construction. Predeclaring the rule prevents post-hoc
  selection but does not make ordinary repeated 95% intervals retain 95% coverage.
- Expected: The overall promotion decision must retain the approved 95% confidence under the
  actual adaptive stopping process.
- Impact: Repeated looks can produce a chance promotion boundary crossing that would not occur
  under a fixed-sample 95% analysis. This can change promotion classification and silently
  weaken the approved confidence gate.
- Minimal correction: In `spec/13 §C-4/C-5` and T-06.8, require a predeclared sequentially valid
  procedure—such as an anytime-valid confidence sequence or explicit alpha-spending/look
  schedule—for every promotion-bearing bound, with a fixture proving overall error control
  under repeated looks.

## 4. Mandatory-question answers

| # | Decision | Decisive evidence |
|---|---|---|
| 1 | ACCEPT | Five conjunctive conditions and exclusive terminal vocabulary at `spec/13-validation-and-evaluation.md:187-215`; Phase 06 implements rather than trusts worker self-report at `phase-06-evaluation.md:157-178`. |
| 2 | ACCEPT | Full boundary and retained failed cycles at `spec/key/03-token-quality-model.md:44-72`; same categories and no-double-count rule at `spec/13-validation-and-evaluation.md:217-280`. |
| 3 | ACCEPT | Main assistant and task usage are separable at `session/session-stats.ts:67-91`; child usage counts assistant messages only at `task/executor.ts:1598-1623`; nested results remain recursively available through `TaskToolDetails` and `extractedToolData` at `task/types.ts:509-547`. Unresolvable attribution fails closed. |
| 4 | ACCEPT | Fallback caveat is explicit at `task/executor.ts:759-782`; promotion requires `SingleResult.usage` and converts missing breakdowns to `not_measured` at `spec/13-validation-and-evaluation.md:251-268`. |
| 5 | ACCEPT | Tech Lead discretion, configurable role, read-only retrieval, fail-soft fallback, recheck, and no token gate appear at `spec/key/03-token-quality-model.md:74-81`. |
| 6 | ACCEPT | Candidate/stable and release/plain-OMP purposes are separated at `spec/13-validation-and-evaluation.md:293-316`; plain OMP uses the external oracle rather than impossible template mechanisms. |
| 7 | ACCEPT | Shared observed-rate hard gate and the two coherent paths are specified at `spec/13-validation-and-evaluation.md:339-368`. |
| 8 | REJECT | Pilot, missing telemetry, post-hoc mutation, and inconclusive exhaustion fail closed, but adaptive repeated looks lack sequential 95% error control at `spec/13-validation-and-evaluation.md:326-367`. |
| 9 | ACCEPT | PR-7 requires candidate/stable plus release/plain-OMP and excludes pilot/waiver at `spec/README.md:433-448`; Phase 07 references the canonical gate at `phase-07-stabilization.md:124-130`. |
| 10 | ACCEPT | Topic boundary expressly excludes runtime, template, DAG, Phase 00, historical evidence, registry, and licenses at `2026-08-12-topic-01-optimization-metrics-design.md:169-175`; `git diff --check` remained read-only and exited 0. |

## 5. Contract and non-claim check

- validated denominator: PASS — all five conditions required; waiver, skipped coverage,
  partial, blocked, cancelled, and decision-needed states excluded
- task-cycle accounting: PASS — failures, rejected work, retrieval, retries, rework,
  handoff/compaction, Scout fallback, and terminal cycles remain charged
- Scout treatment: PASS — optional configurable read-only helper, no token quota or weighting,
  fail-soft fallback
- dual baselines: PASS — candidate/stable and release/plain-OMP comparisons remain distinct
- pilot/final promotion: REJECT — nominal intervals are not required to remain valid under
  adaptive stopping
- PR-7: PASS — canonical dual-baseline gate; pilot and `accepted_with_waiver` excluded
- runtime implemented by Topic 01: NO
- candidate promoted by Topic 01: NO
- Phase 00 / DAG changed by Topic 01: NO

## 6. Next action

Rerun this exact audit in a sandbox where `Get-FileHash` is actually permitted to execute and
record every frozen SHA-256 value.
