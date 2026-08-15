# Prompt for Claude Opus — Adversarial Audit of Topic 01

You are Claude Opus acting as Codex's equal technical peer on `omp-template`. Neither model has
authority by reputation. Review only from the user-approved contract, repository files, and
pinned OMP source evidence.

## Scope and mutation boundary

Audit Topic 01: optimization objective, validated accepted outcomes, task-cycle accounting,
Cheap Scout treatment, latency, dual baselines, and promotion gates. This is a read-only pass.
Do not edit/create/delete files, run a provider-backed benchmark, change Git state, implement
the Phase 06 harness, or broaden into Topics 2-12.

## Mandatory read order

1. Read `opus5-review-packet-codex-topic01-optimization-metrics.md` first.
2. Verify its SHA-256 is
   `3EB732F06859F854A85E9E2FF52742B53FA6E19F0AC0494754B8C1CCB0101F9A`.
3. Verify the packet's full-ledger hash and load-bearing hashes.
4. Follow the packet's mandatory read order and source anchors.
5. Read `codex-topic01-optimization-metrics-changelog-for-opus5.md` only for the mutation
   ledger, validation details, projections, limitations, or a claim requiring drill-down. Its
   SHA-256 is `11491FC80CBB287462369E42CFB2A680DDAF0C2A12140E00B24FF1C6D0E4DA0C`.

If either top-level hash differs, return `INSUFFICIENT_EVIDENCE` with the observed hash. Do not
repair anything.

## Review method

Independently attempt to falsify all ten mandatory questions in the packet. In particular:

- test every route by which a waived, partial, skipped, blocked, or self-reported result might
  enter the validated denominator;
- trace failure/retry/rework/Scout/handoff accounting for omission and double counting;
- verify pinned OMP source claims, especially session totals containing task usage and the
  `SingleResult.tokens` fallback potentially containing cacheRead;
- check whether the explicit-usage-breakdown fail-closed rule is implementable;
- test the mathematics and interaction of hard gates, the five-point non-inferiority
  uncertainty, the 10% efficiency threshold, and the 10% quality-win token ceiling;
- test pilot/final/adaptive-stopping and post-hoc-threshold failure modes;
- distinguish candidate/stable and release/plain-OMP comparisons, including the external
  oracle versus template-internal gate boundary;
- verify Cheap Scout stays a simple optional read-only helper with no token quota/weighting;
- scan active authority/projection/phase files for stale single-baseline, weighted-token,
  latency-objective, user-acceptance, or pilot-promotion semantics;
- verify Topic 01 makes no runtime or production-readiness claim.

Tests and hashes are supporting evidence, not proof by themselves. Separate source fact,
inference, approved design judgment, and recommendation. Do not replace the user's chosen
defaults merely because you prefer another threshold. A threshold becomes a finding only if
the written rules are contradictory, unimplementable, unsafe, or silently weaker than the
approved contract.

## Required verdict

Return exactly one top-level verdict:

```text
ACCEPT_TOPIC_01
REOPEN_TOPIC_01
INSUFFICIENT_EVIDENCE
```

Use `ACCEPT_TOPIC_01` only when no Critical or Important scoped defect remains. Minor findings
may coexist with acceptance only when they cannot change outcome classification, accounting,
promotion, source meaning, phase authority, or reproducibility.

Use `REOPEN_TOPIC_01` for at least one evidence-backed defect that can change those semantics.
Use `INSUFFICIENT_EVIDENCE` when a required artifact/source/hash is missing or contradictory.

## Required response format

```markdown
# Opus Review — Topic 01

## 1. Verdict
<ACCEPT_TOPIC_01 | REOPEN_TOPIC_01 | INSUFFICIENT_EVIDENCE>
<two to five decisive sentences>

## 2. Hash and source audit
| Check | Expected | Observed | Result |
|---|---|---|---|
<load-bearing hashes and four pinned-source claims only>

## 3. Findings
<None, or findings ordered Critical → Important → Minor>

For every finding:
### <severity> — <short title>
- Classification: contract-misread | actionable | trade-off | noise
- Claim rejected: <exact claim>
- Evidence: `<path:line-or-symbol>`
- Observed: <what evidence proves>
- Expected: <contract>
- Impact: <why verdict changes or why bounded>
- Minimal correction: <exact smallest correction>

## 4. Mandatory-question answers
| # | Decision | Decisive evidence |
|---|---|---|
| 1-10 | ACCEPT / REJECT / INSUFFICIENT | exact path and location |

## 5. Contract and non-claim check
- validated denominator: <state>
- task-cycle accounting: <state>
- Scout treatment: <state>
- dual baselines: <state>
- pilot/final promotion: <state>
- PR-7: <state>
- runtime implemented by Topic 01: NO
- candidate promoted by Topic 01: NO
- Phase 00 / DAG changed by Topic 01: NO

## 6. Next action
<one concrete action only>
```

Keep the review compact. Do not restate the packet or praise either author. Cite tight
repository-relative paths and source lines. Target 1,000-1,800 words; exceed only for an
evidence-backed reopening finding.

