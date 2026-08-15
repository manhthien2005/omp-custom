# Codex → Opus 5 — Compact Review Packet for Topic 01

> **Project:** `omp-template`
>
> **Scope:** optimization objective, outcome semantics, accounting, baselines, and promotion
>
> **Activity:** adversarial review only; do not mutate files
>
> **Full ledger:** `codex-topic01-optimization-metrics-changelog-for-opus5.md`
>
> **Full-ledger SHA-256:**
> `11491FC80CBB287462369E42CFB2A680DDAF0C2A12140E00B24FF1C6D0E4DA0C`

## 1. Requested verdict

Return exactly one:

```text
ACCEPT_TOPIC_01
REOPEN_TOPIC_01
INSUFFICIENT_EVIDENCE
```

Acceptance means the user-approved Topic 01 contract is projected consistently, the four OMP
source claims below are correct at the pinned commit, phase responsibilities do not drift, and
no Critical or Important defect remains. It does not mean the Phase 06 harness exists, any
candidate was promoted, Phase 00 is closed, or the product is production ready.

## 2. Mandatory read order

1. Verify the full-ledger hash above.
2. Read `docs/superpowers/specs/2026-08-12-topic-01-optimization-metrics-design.md`.
3. Read `spec/key/04-decision-log.md` KD-012 and KD-024.
4. Read `spec/key/03-token-quality-model.md §A`.
5. Read `spec/13-validation-and-evaluation.md §C-F`.
6. Read Phase 03 T-03.7/T-03.8, Phase 06 T-06.5…T-06.8, and Phase 07 PR-7.
7. Use the full ledger for hashes, projections, validation results, and non-claims.
8. Inspect other files only to falsify a claim or trace a contradiction.

Stop with `INSUFFICIENT_EVIDENCE` if the ledger hash or a load-bearing file hash does not match.

## 3. User-approved contract

```yaml
priority:
  - mandatory_quality_gates
  - validated_accepted_outcome_rate
  - core_workflow_tokens_per_validated_accepted_outcome
  - latency_final_tiebreaker

accepted_outcome_requires:
  - objective_complete
  - every_mandatory_criterion_PASS
  - required_verification_and_review_clear
  - no_blocking_authority_or_scope_issue
  - tech_lead_acceptance

nonvalidated_states:
  - accepted_with_waiver
  - partial
  - blocked
  - cancelled
  - needs_user_decision

ledgers:
  core_workflow_tokens: optimization
  cheap_scout_tokens: telemetry_only
  raw_total_tokens: observational
  model_weights: none

baselines:
  candidates: stable_product_baseline
  releases_and_major_architecture: pinned_plain_omp_runtime_baseline

pilot:
  minimum_paired_runs_per_arm: 3
  may_promote: false

promotion:
  hard_gates_first: true
  valid_paths: [PROMOTE_EFFICIENCY, PROMOTE_QUALITY]
  confidence: 95_percent
  quality_noninferiority_uncertainty: 5_percentage_points
  efficiency_minimum_core_token_improvement: 10_percent
  quality_win_maximum_core_token_regression: 10_percent
  inconclusive: reject_or_defer

cheap_scout:
  decision_owner: tech_lead
  model: configurable_cheap_role
  permissions: read_only_retrieval
  token_gate: none
  failure: fail_soft_to_needed_lead_retrieval
  critical_evidence: rechecked_by_tech_lead
```

## 4. Source facts to falsify

Pinned source: `_research/upstreams/oh-my-pi` at
`3a8591a8af5b6d200088d12ca75a5517cb064fa8`.

1. `task/types.ts:471-510` exposes per-spawn identity, role, usage, duration, and token fields.
2. `task/executor.ts:759-782` intends input + output + cacheWrite for `tokens`, but its
   breakdown-missing fallback uses provider `totalTokens` and may include cacheRead.
3. `session/session-stats.ts:52-110` aggregates main assistant-message usage and task-tool child
   usage, so blindly adding session totals to child results double counts.
4. `modes/print-mode.ts:47-83,191-194` emits authoritative message/agent events in JSON mode,
   preserving the usage-bearing messages needed to derive main-session usage.

The spec's consequence is fail-closed: derive the promotion ledger from explicit usage
breakdowns, main messages, unique child IDs, and role attribution. If a required breakdown or
attribution is missing, use `not_measured`; never estimate or promote.

## 5. Load-bearing frozen hashes

| File | SHA-256 |
|---|---|
| `docs/superpowers/specs/2026-08-12-topic-01-optimization-metrics-design.md` | `D4505E510A66D5746A88AAE53BDDDF017DC7B0D0FCECAA811656D939B684FCF3` |
| `spec/key/03-token-quality-model.md` | `F83A471CD01377BBE24F98679359B8D86354AEDE87941130D8167D2E1E186D27` |
| `spec/key/04-decision-log.md` | `D1A99C8C0094837A8FBBBAD773EC6CFAAB168D4306C1B9D5CED4F9CBD72C5AE2` |
| `spec/13-validation-and-evaluation.md` | `F92E031ED121297BC34A4365659C37A3F644E713342470540DC6A799A7347DEA` |
| `spec/phases/phase-03-context-efficiency.md` | `F8FD4988D9C13B690BEF38BE12E856D7AB2F485D3597153FF828338628D2BBB4` |
| `spec/phases/phase-06-evaluation.md` | `3682FF448A23F81EF951229FA4AE1075BD7AF451AD89EC3221FC66F431F46E28` |
| `spec/phases/phase-07-stabilization.md` | `D43A3858D638639EE2B332AF60BA4B0FCA70B4834AD411271ACD050AF8591E8C` |
| `CHANGELOG.md` | `718932BCEADB64E8F8ACD0264317CDDEA61D46F2F099ADC35D1319A572CE169D` |

The full ledger contains every projection hash and its captured pre-Topic-01 value.

## 6. Mandatory adversarial questions

Answer each `ACCEPT`, `REJECT`, or `INSUFFICIENT`, with exact repository evidence:

1. Does the accepted-outcome classifier prevent worker self-report, skipped criteria, waiver,
   partial completion, or unresolved blockers from entering the validated denominator?
2. Does the task-cycle boundary charge failures, rejected candidates, retrieval, retries,
   rework, handoff/compaction, and Scout fallback exactly once?
3. Can the proposed main-message + unique-child reconciliation be implemented from pinned OMP
   telemetry without double counting nested/retried task usage?
4. Is fail-closed `not_measured` handling sufficient for the `SingleResult.tokens` fallback
   caveat, and does any active text still trust that fallback for promotion?
5. Is Cheap Scout still the user's simple policy — Tech Lead discretion, cheap configurable
   role, no token gate, fail-soft fallback — rather than a hidden weighting/quota mechanism?
6. Do the two baselines answer distinct questions without making plain OMP satisfy impossible
   template-internal discovery/contract mechanisms?
7. Are the efficiency and quality paths mathematically coherent with the shared hard gate that
   observed accepted-outcome rate cannot decrease?
8. Can a three-run pilot, a post-hoc threshold change, missing telemetry, or an inconclusive
   interval accidentally produce a promotion verdict anywhere?
9. Does PR-7 consistently require candidate/stable promotion plus a release/plain-OMP value
   comparison, while excluding `accepted_with_waiver`?
10. Did Topic 01 change only specifications/plans/docs, leaving runtime, DAG, Phase 00,
    template, registry/license, worktree, and historical evidence semantics untouched?

## 7. Finding standard

Classify every observation as one of:

```text
contract-misread
actionable
trade-off
noise
```

Every `actionable` or `trade-off` finding must include:

```yaml
severity: CRITICAL | IMPORTANT | MINOR
claim_rejected: exact claim
evidence:
  path: repository-relative path
  lines_or_symbol: tight location
observed: what the evidence proves
expected: contract that should hold
impact: why acceptance changes or why the issue is bounded
minimal_correction: exact smallest correction
```

Do not reopen for wording preference, desire for runtime implementation in Topic 01, or a wish
to replace the user-approved defaults with different defaults. Do reopen for a mathematical
contradiction, infeasible telemetry requirement, source misread, denominator leak, double
count, phase/gate drift, or silent weakening of quality/fallback semantics.

## 8. Validation already performed

- Required-term scan: PASS.
- Superseded-active-semantics scan: PASS.
- Markdown fence balance across all Topic 01 targets: PASS.
- `git diff --check`: exit 0; only an unrelated pre-existing Phase 00 CRLF notice.
- `scripts/validate-template.ps1`: exit 0, `102 passed, 1 warnings, 0 failed`; the warning is
  the pre-existing advisory lower-bound warning for `RULES.md`.

These checks support structural consistency only. Independently inspect the contract and
source; do not accept because validation passed.

