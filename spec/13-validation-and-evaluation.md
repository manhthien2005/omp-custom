# 13 — Validation and Evaluation

> OPUS PROPOSED SPEC v1 | Source-verified against `scripts/validate-template.ps1` and `scripts/benchmark.ps1`.

---

## A. Why the Current 63/63 PASS Is Misleading

`validate-template.ps1` runs four sections:

1. Required files exist (32 paths)
2. Token budgets via `chars / 4` approximation
3. Constitutional phrases not duplicated into agent files
4. YAML files are non-empty (`.Trim().Length -gt 10`)

Every check is a **filesystem or string property**. Not one check exercises OMP. The
consequence is direct and demonstrable: the suite reports 63/63 PASS on a template whose
installer copies **zero slash commands** (§12 D-1), whose agents reference an
unresolvable `policy:workflow-sizing` (§02), and whose `read-summarize: false` on the
Explorer contradicts its own retrieval instructions (§07).

Worse, Section 1 lists `template\.omp\commands\quick.md` and friends — so validation
confirms the files exist in the *template*, while the installer never copies them. The
suite validates the source tree and says nothing about the installed result.

A green suite here means "the files are present and roughly the right size". It does not
mean the workflow runs.

---

## B. Validation Taxonomy (L0–L4)

**CR-23 — Canonical Validation Taxonomy (L0–L4):** The authoritative level names are defined here and must be used consistently across all spec files and phase plans. This taxonomy defines **five levels** (L0 through L4).

### L0 — Static (exists today, keep and extend)

Filesystem and text properties. Fast, no OMP required, runs in CI.

Keep: required files, token budgets, YAML non-emptiness.

Add:
- **Frontmatter parse check** — every `agents/*.md` has `---` fences and parses as YAML
  with `name` and `description` present. `parseAgentFields` returns `null` without both,
  and the agent is dropped with only a `logger.warn` (§02 §D). Silent-drop is exactly the
  failure mode static validation should catch.
- **Tool-allowlist coherence** — no agent instruction references a tool absent from its
  `tools:` list. This catches the Explorer LSP contradiction (F-11) mechanically.
- **Dangling reference check** — no `policy:<name>` or `schema:<name>` string appears in
  any prompt file, since neither resolves (§02 §C).
- **Token budget by tokenizer** — replace `chars / 4` with a real BPE count. OMP embeds
  o200k/cl100k counting; `chars / 4` misestimates markdown tables and code fences badly.
- **Secret scan** — no API keys, tokens, or credentials in any template file.

### L1 — Discovery (new, highest value per effort)

Install into a scratch directory, then confirm **OMP itself** sees every component.
This is the layer that would have caught D-1 on day one.

Assertions:
- All three slash commands are discovered and invocable.
- All five agents parse and appear in the agent list — no `logger.warn` drops.
- All three skills are discovered.
- Custom model roles resolve (§09) — `@explorer` maps to a real model, not silently to `default`.
- `.omp/AGENTS.md` and `.omp/RULES.md` load, with RULES.md forced `alwaysApply` (§11).

A component that OMP cannot see is broken regardless of how well-formed its file is.

### L2 — Contract (new)

Exercise the structured-output path (§06) without judging code quality:
- A `task` call with an inline `outputSchema` returns a schema-valid object.
- A deliberately malformed yield is rejected, and the retry ladder engages (§06 §D).
- An `agent-result` claiming `status: completed` with empty `verification_results` is
  rejected by the schema, not merely discouraged by prose.

### L3 — Behavioral (new, the real measure)

Run the ten fixture tasks from the plan end-to-end and measure outcomes. This is the only
level that can answer "is the workflow better than no workflow".

### L4 — Adversarial (new)

Test the failure modes the design claims to prevent. These cases must be fully deterministic (no model-grading): an Implementer that reports false success, an environment failure, a non-git-repo isolation dispatch, a schema-violating result, and conflicting parallel patches. Each case must produce a specified detection response. L4 also covers A/B comparison runs where a single variable is isolated and results are compared statistically (see §C).

---

## C. Benchmark: Current State and Required Redesign

`benchmark.ps1` today enumerates `evals/**/*.yml`, prints the intended record format, and
tells the user to create result files by hand. Its own output says actual execution "must
be done manually per fixture". It measures nothing.

Only three fixtures exist (`eval-001-tiny-bug`, `eval-002-root-cause-bug`,
`eval-007-ambiguous`) against the plan's ten task types.

**Required redesign** — the harness must:

1. Materialize each fixture into a scratch git repo (isolation requires git, §08).
2. Invoke OMP non-interactively (`omp -p`) with the fixture prompt and chosen workflow.
3. Capture the transcript, token counts, tool calls, and agents spawned.
4. Run the fixture's own deterministic acceptance check — its test command.
5. Record one YAML result per run, including failures.
6. Support A/B: same fixture, differing single variable.

### Metrics

Deterministic (authoritative): accepted outcome, test pass rate, acceptance-criteria
coverage, correct-file localization, unnecessary diff size, false-completion count,
agents spawned, retries, tool calls, wall time, input/output/cached tokens.

Model-graded (advisory only, per the plan): plan coherence, maintainability, review
usefulness, requirement alignment.

**Primary metric: tokens per accepted outcome.** A run that is cheap and wrong scores
worse than a run that is expensive and right. Reporting raw token counts without the
acceptance denominator is the failure mode this metric exists to prevent.

### A/B Comparisons

**CR-22 — Formal A/B Protocol:** Each A/B comparison MUST:
1. isolate exactly one variable — any other difference confounds the result
2. run both arms on identical fixture tasks with **fresh, independent state per run** — same-session or back-to-back runs risk conversation state, cache, warmed provider state, filesystem mutation, or tool output confounds; fresh isolated runs are required unless the variable being tested explicitly concerns within-session behavior
3. **randomize or counterbalance arm ordering** — always running baseline-first creates order effects
4. record results from both arms before interpreting either
5. report **per-fixture paired delta** plus aggregate across ≥3 independent runs per arm — three runs is a **pilot/smoke minimum** suitable for "this doesn't obviously regress"; it is NOT sufficient evidence for a strong "quality neutral-or-better" claim
6. state the null hypothesis and the threshold used to judge the result
7. capture **reproducibility metadata** per run: `omp_sha`, `template_sha`, `provider`, `gateway_version`, `model_id`, `reasoning_level`, `timeout_policy`, `retry_policy`, `cache_policy`, `tool_environment`

**Pilot vs final evidence standard:**
- `≥3 runs/arm` = **pilot/smoke evidence** — sufficient to catch obvious regressions, not sufficient for production-quality comparative claims
- For any final "quality neutral-or-better" claim, N must be determined from a predeclared precision criterion OR runs must continue until the paired-delta confidence interval width meets a predeclared bound (e.g., 95% CI < 10% of the metric's expected range)

**Preferred summary metric** (because fixtures are paired): per-fixture paired delta, aggregate paired delta, confidence interval or bootstrap interval, failure rate, and token delta — rather than only separate arm means and standard deviations.

**Stable disagreement on power analysis requirement:** Opus holds that requiring formal power analysis or CI-width stopping rules for all comparisons is over-engineering for an initial evaluation framework. These techniques are appropriate once the fixture suite is stable and the claim is for production quality gates. GPT's preference for full statistical rigor is noted and the protocol is designed to be extendable to that standard.

| Comparison | Question it answers |
|---|---|
| No template vs Workflow v0 | Does the template help at all? |
| Quick vs Standard on the same task | Is the heavier workflow worth it? |
| One worker vs several | Does parallelism pay for its overhead? |
| Reviewer on vs off | Does review catch real defects? |
| Compact vs bloated task packet | Does packet discipline matter? |
| `autoloadSkills` on vs off | Does forced skill injection change outcomes? |
| High effort everywhere vs only where needed | Is selective effort as good and cheaper? |

Each isolates one variable; anything else confounds the result.

---

## D. False-Completion Detection

The template's central claim is "no false completion". It must be measured, not asserted.

A run is a **false completion** when the agent reports success and the fixture's own
acceptance check fails. This is fully deterministic and needs no grader.

False-completion rate is the headline quality metric. A workflow that lowers token cost
while raising false completions is a regression, and §05's rule that efficiency must
never come from weaker verification depends on this number being tracked.

---

## E. Honest Reporting

The plan requires that failed evaluations not be hidden. Therefore:

- Every run is recorded, including crashes and timeouts.
- Result files are immutable; a re-run creates a new record.
- Aggregates state the run count and variance, never a single cherry-picked run.
- Fixtures with no deterministic acceptance check are labeled as such, and their
  model-graded scores are never presented as evidence of correctness.
- Where a metric was not measured, the report says "not measured" rather than omitting it.

---

## F. Acceptance Criteria

| # | Criterion |
|---|---|
| AC-1 | L0 catches a missing `---` fence, a dangling `policy:` reference, and a tool-allowlist contradiction |
| AC-2 | L1 fails when the installer omits slash commands (regression test for §12 D-1) |
| AC-3 | L1 fails when a custom model role is unresolved |
| AC-4 | L2 proves schema rejection and retry actually occur |
| AC-5 | Benchmark executes real OMP sessions and records results without manual authoring |
| AC-6 | All ten plan fixture types exist with deterministic acceptance checks |
| AC-7 | False-completion rate is computed automatically per run |
| AC-8 | Token counts come from a real tokenizer, not `chars / 4` |
| AC-9 | At least one A/B comparison is executed and reported with variance |
| AC-10 | Failed and crashed runs appear in the report |
