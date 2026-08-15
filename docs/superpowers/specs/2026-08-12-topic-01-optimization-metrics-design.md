# Topic 01 Optimization Metrics Design

> **Status:** User-approved and projected into the canonical specs; adversarial audit pending.
>
> **Scope:** Objective, outcome semantics, token accounting, latency, baselines, and
> promotion policy. This is a design record, not a runtime artifact. The projection keeps
> decision authority in `spec/key/03-token-quality-model.md` and the executable evaluation
> contract in `spec/13-validation-and-evaluation.md`.

## Goal

Make quality the first constraint and minimize expensive workflow tokens per validated
accepted outcome. Cheap Scout remains a simple, optional retrieval helper rather than a
separate optimization problem.

## Decision

The project uses a lexicographic objective:

1. Clear every mandatory quality gate.
2. Maximize the validated accepted-outcome rate.
3. Minimize core workflow tokens per validated accepted outcome.
4. Use latency only as a final tie-breaker when quality and core-token efficiency are
   equivalent.

No weighted quality score, model-price multiplier, premium-token equivalent, or composite
latency score may override this order.

## Validated Accepted Outcome

A task is a validated accepted outcome only when all of the following hold:

- the task objective is complete;
- every mandatory acceptance criterion has authoritative PASS evidence, with no SKIP or
  coverage gap;
- required verification and review gates are clear;
- no blocking finding, unresolved authority conflict, or unresolved scope issue remains;
- the Tech Lead records final acceptance.

`partial`, `blocked`, `cancelled`, and `needs_user_decision` are honest terminal states but
are not accepted outcomes. `accepted_with_waiver` is a separate user-authorized state and is
excluded from the validated benchmark denominator.

## Task-Cycle Accounting

The accounting boundary begins when the task contract is accepted and ends at final
acceptance or a terminal non-accepted state. The same cycle includes initial and repeated
retrieval, rejected candidates, schema/provider/workflow retries, verification and review
rework, attributable compaction or handoff, and fallback work after Scout failure. A new task
contract starts a new cycle.

Every failed or rejected cycle remains in the aggregate numerator. Failed work is not erased
or charged only to a later retry.

Three unweighted ledgers are reported:

- `core_workflow_tokens`: Tech Lead and non-Scout worker/reviewer activity; this is the
  optimization ledger.
- `cheap_scout_tokens`: read-only Cheap Scout activity; telemetry only and never a routing or
  promotion gate.
- `raw_total_tokens`: the sum of both ledgers using the runtime/provider token fields that were
  actually observed. Missing token classes are disclosed and never estimated silently.

The aggregate optimization metric is:

```text
sum(core_workflow_tokens across every attempted task cycle)
----------------------------------------------------------------
count(validated accepted outcomes)
```

Zero validated accepted outcomes means infinite cost.

## Cheap Scout Boundary

The Tech Lead decides whether a Cheap Scout is useful. The Scout is a configurable cheap
model role such as DeepSeek, Gemini, or another suitable provider model; workflows do not
hardcode a model ID. It performs read-only retrieval and returns compact evidence. If it is
unavailable, fails, or returns unusable evidence, the workflow fails softly to the retrieval
path the Tech Lead needs. The Tech Lead rechecks critical evidence. Scout token volume is
telemetry, not a quota to optimize.

## Latency

Wall time, provider waits, and timeouts are recorded for diagnosis. Latency is not an
optimization objective. A timeout, deadlock, or unbounded wait is a reliability failure. An
explicit user deadline becomes a task constraint. Otherwise latency is considered only after
quality and core-token efficiency are equivalent.

## Dual Baselines

Two frozen baselines have distinct jobs:

- The last accepted template is the candidate baseline for every mechanism or optimization.
- Pinned plain OMP without the template is the runtime baseline for releases and major
  architecture checkpoints.

Both arms use identical fixtures, runtime version, provider/model policy, retry and timeout
policy, cache policy, and tool environment. Baseline identity records the OMP binary SHA,
template artifact SHA where applicable, fixture version, and provider configuration. The
stable-template baseline advances only after promotion, and every advance records what it
supersedes. Baselines never move silently.

## Promotion Gate

Every candidate must first pass these hard gates. Here, "required fixtures" means the
deterministic operational and adversarial gate suite; stochastic behavioral repetitions are
summarized separately as the accepted-outcome rate:

- all deterministic required gate fixtures pass;
- acceptance-criteria coverage is complete;
- no new false completion occurs;
- no blocking or critical correctness/security regression occurs;
- the observed validated accepted-outcome rate does not decrease.

A candidate may then promote through exactly one of two paths:

### Efficiency win

- The candidate's accepted-outcome rate is statistically non-inferior to the stable baseline.
- The observed accepted-outcome rate is not lower than baseline.
- The one-sided 95% confidence bound permits at most five percentage points of uncertainty on
  quality non-inferiority.
- Core workflow tokens per validated accepted outcome improve by at least 10%, and the paired
  95% interval supports an improvement rather than noise.

### Quality win

- The accepted-outcome rate is credibly better at 95% confidence.
- Core workflow tokens per validated accepted outcome regress by no more than 10%, including
  the paired 95% uncertainty bound.

At least three independent paired runs per arm are required for a pilot. Pilot evidence can
reject an obvious regression but cannot promote a candidate. Final runs continue under a
predeclared sequentially valid adaptive procedure until a promotion condition, rejection
condition, or declared evidence budget is reached. The procedure must use an anytime-valid
paired confidence sequence or a finite look schedule with explicit alpha spending (or an
equivalent joint construction) so the probability of any false promotion remains at most 5%
across all interim looks, both promotion paths, and every promotion-bearing bound. Ordinary
per-look 95% paired/bootstrap intervals may be reported descriptively but cannot trigger an
adaptive promotion. Pilot observations are excluded from final promotion inference unless the
sequential procedure was frozen before the first pilot look and treats them as its first look.
An inconclusive candidate is deferred or rejected, never promoted automatically.

Higher-risk evaluations may predeclare stricter thresholds. Thresholds cannot be loosened
after final sampling begins. A user waiver is recorded as `accepted_with_waiver`; it is not a
validated promotion.

## Evaluation Flow

```text
accepted task contract
  -> isolated task cycle
  -> outcome and three token ledgers recorded
  -> deterministic acceptance and quality gates
  -> paired comparison against frozen stable template
  -> efficiency-win or quality-win test
  -> promotion, rejection, or defer
  -> release checkpoint also compared with pinned plain OMP
```

Model-graded maintainability, plan coherence, review usefulness, and requirement alignment
remain advisory. They may explain a result but cannot override deterministic gates.

## Failure Handling

- Provider, schema, workflow, Scout, verification, and review retries remain charged to the
  originating task cycle.
- Crashes and timeouts are recorded as non-accepted outcomes and classified by cause.
- Missing metrics are reported as `not_measured`; they are not imputed.
- A zero-denominator aggregate is reported as infinite or undefined-for-promotion, never zero.
- A baseline identity mismatch invalidates the comparison.
- A post-hoc threshold change invalidates the final promotion claim.

## Impact Boundary

The approved design changes the metric authority, evaluation contract, Phase 03
instrumentation, Phase 06 benchmark and promotion work, Phase 07 production gate, and concise
human documentation. It does not implement the benchmark harness, change runtime/template
behavior, change the phase DAG, alter Phase 00 authority state, or modify historical evidence,
review packets, the DNA worktree, upstream source, registry, or license records.
