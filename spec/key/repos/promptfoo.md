# Repo Report — promptfoo

> Authority boundary: This repository report is source/research evidence.
> Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology,
> dispatch, review mechanism, or capability behavior.
> Current design and execution authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.


> **Path:** `_research/upstreams/promptfoo`
> **SHA:** `1c30e183c4a464d953898398399dc6aa69786471` (`git -C _research/upstreams/promptfoo rev-parse HEAD`, tip dated 2026-08-06)
> **License:** MIT, verbatim. `LICENSE:1` reads `Copyright (c) Promptfoo 2025` followed by the
> standard MIT grant text (`LICENSE:3-20`). The file has no SPDX header line and no
> `MIT License` title — it is the MIT body only. No per-file grants or Commons Clause riders
> were found in the files opened. Enterprise features are gated by runtime checks
> (`site/docs/integrations/ci-cd.md:103`), not by a separate license file in this repo.
> **Size:** 5,486 tracked files (`git ls-files | wc -l`)
> **Read this pass:** the assertion engine end-to-end (registry, ~20 handler files, the
> aggregation class, the type schemas), the evaluator's repeat/cache/metrics paths, the
> results persistence schema, the CLI gating path, the JUnit writer, the coding-agent
> red-team grader + verifier entrypoints, and four docs pages (assertions index,
> test-cases, scenarios, evaluate-coding-agents, ci-cd). Full accounting in §7.

---

## 1. What this repo is

Promptfoo is a CLI + library for evaluating LLM applications: you declare a matrix of
prompts × providers × test cases, each test case carries a list of *assertions*, and the
tool runs the matrix, grades every cell, persists results to SQLite, and exits non-zero on
a pass-rate threshold. It is a **runtime plus a format plus a methodology**, and the three
are separable — the assertion vocabulary and the test-case schema are declarative YAML/JSON
and carry no dependency on their executor.

It also ships a second, distinct product in the same tree: a red-team generator
(67 vulnerability plugins in `src/redteam/plugins/`, 31 attack strategies in
`src/redteam/strategies/`) that synthesizes adversarial test cases and grades them with
purpose-built graders. That half is the closest thing in our corpus to our L4 tier.

---

## 2. Mechanism inventory

### 2.1 Assertion taxonomy — the split is explicit and machine-readable

The single most useful artifact in the repo for us: promptfoo maintains the
deterministic/model-graded boundary **in code, as a set**, not just in prose.

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| 1 | Closed assertion-type enum | 69 base types in one Zod enum; unknown type is a hard config error | `src/types/index.ts:595-662`; throw at `src/assertions/index.ts:672` | A |
| 2 | `MODEL_GRADED_ASSERTION_TYPES` set | 11 types named as model-graded **in code**, used to attribute grader token spend separately | `src/assertions/index.ts:122-134`; consumed at `src/evaluator.ts:3212-3220` | A |
| 3 | `TRACE_AWARE_ASSERTION_TYPES` set | 11 types that need trace data; drives conditional trace fetch so non-trace runs pay nothing | `src/assertions/index.ts:136-148` | A |
| 4 | Universal `not-` prefix | Every base type is negatable by transform, not by 69 hand-written inverses | `src/types/index.ts:666-686`; `isAssertionInverse` at `src/assertions/index.ts:353-355` | A |
| 5 | Handler registry | One `Record<BaseAssertionTypes, handler>` — the enum and the registry are type-checked against each other, so adding a type without a handler fails compilation | `src/assertions/index.ts:226-316` | A |
| 6 | Uniform result shape | Every handler returns `{pass, score, reason, assertion}`; `reason` is mandatory and carries the *actual observed value*, not just "failed" | e.g. `src/assertions/contains.ts:127-134`, `src/assertions/toolCallF1.ts:221-231` | A |
| 7 | `graderError` marker | LLM-grader transport/parse failure sets `metadata.graderError: true`; inverse assertions must propagate verbatim rather than flip a grader crash into a pass | `src/types/index.ts:566-571`; `isGraderFailure` at `src/matchers/llmGrading.ts:430-431`; honored at `src/assertions/trajectory.ts:655-657` | A |

### 2.2 Deterministic assertions — exactly what each checks

Read in full. All are pure functions of `(outputString, renderedValue, inverse)` unless noted.

| Type | What it checks | Implementation | `file:line` |
|---|---|---|---|
| `equals` | `String(value) === outputString`; if value is an object, `util.isDeepStrictEqual` against `JSON.parse(output)`; unparseable output ⇒ not-equal (respects `inverse`, so `not-equals` passes) | `util.isDeepStrictEqual` | `src/assertions/equals.ts:14-27` |
| `contains` / `icontains` | `String.includes`, lowercased for the `i` variant. Rejects empty string and `NaN` as a value | `isContainsValue` guard | `src/assertions/contains.ts:110-158` |
| `contains-any` / `-all` (+`i`) | Splits a string value on commas with a hand-written CSV-ish parser supporting quoted fields, `\"` and `""` escapes; **throws on an unterminated quote** rather than silently passing. `-all` reports *which* strings were missing | `parseCommaSeparatedValues` | `src/assertions/contains.ts:45-108`, `:160-259` |
| `regex` | `new RegExp(value).test(output)`. Invalid pattern returns a **fail with the compile error**, not a throw | — | `src/assertions/regex.ts:13-32` |
| `starts-with` | `String.startsWith` | — | `src/assertions/startsWith.ts:16` |
| `is-json` | `JSON.parse` succeeds; **if a value is supplied it is an AJV JSON Schema** and validation errors are put into `reason` via `errorsText` | AJV | `src/assertions/json.ts:8-63` |
| `contains-json` | extracts embedded JSON objects from prose/markdown, then optional AJV schema per object | `extractJsonObjects` | `src/assertions/json.ts:65-113` |
| `levenshtein` | `fastest-levenshtein` distance ≤ `threshold`, **default 5** | — | `src/assertions/levenshtein.ts:16-18` |
| `word-count` | whitespace split, filter empties. Value is exact number **or** `{min,max}` / `{min}` / `{max}`; asserts `min<=max` at run time | `countWords` | `src/assertions/wordCount.ts:8-104` |
| `latency` | `latencyMs <= threshold`. **Throws** if the result was cached ("Rerun with --no-cache") rather than silently passing | — | `src/assertions/latency.ts:8-16` |
| `cost` | `cost <= threshold`; throws if provider reports no cost | — | `src/assertions/cost.ts:4-11` |
| `finish-reason` | case-insensitive compare against `providerResponse.finishReason`; missing reason ⇒ fail (pass only if inverse) | — | `src/assertions/finishReason.ts:14-27` |
| `is-refusal` | empty/whitespace output counts as refusal; else a keyword heuristic | `isBasicRefusal` | `src/assertions/refusal.ts:20-32` |
| `tool-call-f1` | set-based precision/recall/F1 over tool names; normalizes **six** provider tool-call wire formats incl. nested/stringified; `score` is the F1 (not 0/1), pass at `threshold ?? 1.0` | `extractToolNames` | `src/assertions/toolCallF1.ts:17-160`, `:183-232` |
| `skill-used` | reads `providerResponse.metadata.skillCalls`, filters `is_error === true`, matches by exact name or glob; list form or `{name/pattern, min, max}` count form. `not-skill-used` **refuses** count bounds other than `max: 0` rather than guessing semantics | `handleSkillUsed` | `src/assertions/skill.ts:12-205` |
| `trace-span-count` | counts trace spans matching a glob against min/max; **throws** when no trace data rather than passing | — | `src/assertions/traceSpanCount.ts:16-23` |
| `trajectory:tool-used` | tool steps from the trace; list form (all required present / none forbidden) or count form with min/max | — | `src/assertions/trajectory.ts:136-219` |
| `trajectory:tool-sequence` | `mode: exact` (length + positional match) or `in_order` (subsequence). `reason` names *which* expected step was not reached | — | `src/assertions/trajectory.ts:431-500` |
| `trajectory:tool-args-match` | `mode: partial` (recursive subset; arrays must match length) or `exact`; `defaults:` tolerates observed values equal to a declared default, `ignore:` drops keys from **both** sides and accepts globs | `matchesToolArgs` | `src/assertions/trajectory.ts:244-357`, `:502-558` |
| `trajectory:step-count` | counts normalized steps filtered by type and/or name pattern against min/max | — | `src/assertions/trajectory.ts:579-633` |
| `javascript` / `python` / `ruby` | run user code, which may return `bool`, `number`, or a full `GradingResult` | `src/assertions/index.ts:492-529` | A |

Two implementation details in the trajectory args matcher are directly relevant to us because
they are *adversarial hardening of a deterministic check*: `stripDefaults` and
`stripIgnoredArgs` use `Object.defineProperty` rather than `cleaned[key] = value`
specifically so a hallucinated `__proto__` argument stays an own property instead of
mutating the prototype and silently disappearing — the comment says the plain assignment
"would … let exact mode pass when it should fail — defeating the point"
(`src/assertions/trajectory.ts:288-297`, `:326-335`). That is the mindset an L2/L3 gate needs.

Model-graded types (advisory in our design): `llm-rubric`, `g-eval`, `factuality`,
`model-graded-closedqa`, `agent-rubric`, `search-rubric`, `answer-relevance`,
`context-{faithfulness,recall,relevance}`, `conversation-relevance`,
`trajectory:goal-success`, `pi`, `classifier`, `moderation`, `similar*`
(`src/assertions/index.ts:122-134`; docs table `site/docs/configuration/expected-outputs/index.md:172-189`).

### 2.3 Test-case / fixture format

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| 8 | `TestCaseSchema` | `{description, vars, provider, providers[], prompts[], providerOutput, assert[], assertScoringFunction, options, threshold, metadata}` — one Zod object, JSON-Schema-exportable | `src/types/index.ts:861-932` | A |
| 9 | `providerOutput` escape hatch | Supplying it **skips the provider call entirely and runs assertions on the given output** — assertion development without burning tokens | `src/types/index.ts:877-878` | A |
| 10 | `TestSuiteSchema` | `{providers[], prompts[], tests[], scenarios[], defaultTest, derivedMetrics[], env, nunjucksFilters}` | `src/types/index.ts:1037-1078` | A |
| 11 | `defaultTest` | assertions/options applied to every test; a test can opt out with `options.disableDefaultAsserts` while keeping other defaults. Loadable from `file://` | `src/types/index.ts:908-909`, `:1060-1067` | A |
| 12 | `scenarios` | Cartesian product of a `config[]` of var-sets × a `tests[]` of assertions — **one fixture body, N parameter arms** | `src/types/index.ts:955-966`; docs `site/docs/configuration/scenarios.md:37-79` | A |
| 13 | Per-test provider filter | `test.providers: [label…]` (globs allowed) restricts which arms a test runs against; `test.prompts` likewise | `src/types/index.ts:871-875` | A |
| 14 | `__expected` CSV column | Compact one-line assertion DSL `type:value` / `type(threshold):value`; `__expected1..N` for multiples; `__metadata:*`, `__threshold`, `__description`, `__config:__expectedN:<key>` | docs `site/docs/configuration/expected-outputs/index.md:404-432`, `site/docs/configuration/test-cases.md:351-366` | B |
| 15 | Standalone assertion mode | `--assertions asserts.yaml --model-outputs out.json` synthesizes a suite over the `echo` provider — **assertions run against recorded outputs with zero model calls** | `src/util/config/load.ts:783-814` | A |
| 16 | Assertion pre-validation | `validateAssertions()` Zod-parses every assertion (recursing into `assert-set`) *before* the run, with a targeted "missing `type`" message and a YAML-indentation hint | `src/assertions/validateAssertions.ts:21-124` | A |
| 17 | Config validate command | `promptfoo validate config -c …` parses the config and optionally probes provider connectivity, separate from running | `src/commands/validate.ts:1-120`; usage `site/docs/guides/evaluate-coding-agents.md:385` | B |

### 2.4 Scoring and aggregation — the section that matters most for our tier rule

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| 18 | `componentResults[]` | Every per-assertion `GradingResult` is preserved on the test's result, **nested sets flattened**, with the parent assertion copied down onto children. Aggregate and per-assertion coexist; the aggregate never replaces the detail | `src/assertions/assertionsResult.ts:171-184`, `:194-207` | A |
| 19 | Default combination = **AND**, not average | `pass = !this.failedReason` — one failing assertion fails the test **regardless of the mean score**. The weighted mean is computed and reported alongside but does not decide | `src/assertions/assertionsResult.ts:149-152` | A |
| 20 | `threshold` **overrides** the AND | Setting a numeric test `threshold` replaces per-assertion pass/fail with `score >= threshold`. Comment is explicit that `threshold: 0` means "collect scores, never fail" | `src/assertions/assertionsResult.ts:154-164`; docs `site/docs/configuration/expected-outputs/index.md:234` | A |
| 21 | Type-gated threshold | Gated on `typeof === 'number' && !Number.isNaN` — a stray empty `threshold:` in YAML would otherwise coerce to `score >= null` and **force-pass everything**. They hit this and wrote the guard + comment | `src/assertions/assertionsResult.ts:154-160` | A |
| 22 | `weight` | Weighted mean; `weight: 0` makes an assertion **metric-only and unfailable** (forced `pass: true` at the handler boundary) | `src/assertions/assertionsResult.ts:96-97`; force-pass `src/assertions/index.ts:661-667` | A |
| 23 | `assert-set` | Nested group with its own `threshold`/`weight`/`metric`; "2 of 4 must pass" is `threshold: 0.5`. Sub-results aggregate, then feed the parent as one weighted entry | `src/types/index.ts:690-704`; wiring `src/assertions/index.ts:755-776`, `:824-837` | A |
| 24 | Named metrics + normalization | `metric:` tags an assertion; scores accumulate per metric name with per-metric weight denominators and are normalized at the end. `namedScoreWeights` is exported so a consumer can recover the denominator | `src/assertions/assertionsResult.ts:107-123`, `:186-199` | A |
| 25 | `assertScoringFunction` | User JS/Python receives `(namedScores, {threshold, componentResults, tokensUsed})` and returns a `GradingResult`, replacing the default mean. **A throw inside it forces `pass:false, score:0`** — a broken scorer cannot green a run | `src/types/index.ts:840-857`, `:884-891`; `src/assertions/assertionsResult.ts:209-232` | A |
| 26 | `derivedMetrics` | Post-hoc mathjs expressions or JS over named scores, evaluated **in declaration order** so later metrics reference earlier ones; `__count` injects the per-prompt case count for averaging. No cycle protection (documented) | `src/types/index.ts:1021-1034`; `src/evaluator.ts:1787-1814`; docs `site/docs/configuration/expected-outputs/index.md:637-645` | A |
| 27 | Metric-only F1 idiom | `weight: 0` counters + `derivedMetrics` = precision/recall/F1 across the suite without any counter influencing pass/fail | docs `site/docs/configuration/expected-outputs/index.md:563-588` | B |
| 28 | Failure taxonomy | `ResultFailureReason = {NONE:0, ASSERT:1, ERROR:2}` — assertion failures and infrastructure errors are **separate counters** (`testFailCount` vs `testErrorCount`), all the way into the JUnit `<failure>` vs `<error>` distinction | `src/types/index.ts:369-376`; `src/evaluator.ts:1776-1785`; `src/util/junit.ts:241-247`, `:260-274` | A |
| 29 | One aggregation anti-pattern | A failing red-team `guardrails` assertion sets `failedContentSafetyChecks` and **force-passes the whole test** with reason `GUARDRAIL_BLOCKED_REASON`, after the threshold check | `src/assertions/assertionsResult.ts:100-106`, `:166-169` | A |

### 2.5 Run management and reproducibility

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| 30 | `--repeat N` / `options.repeat` | Runs each case N times, global or per-test; per-test overrides global. This is the entirety of their non-determinism handling | `src/commands/eval.ts:92`; `src/types/index.ts:913-914`; loop `src/evaluator.ts:2432-2451` | A |
| 31 | **Repeat-aware cache namespacing** | Each repeat index gets its own cache namespace `repeat:N`, so repeats replay distinct cached responses instead of N copies of one response. Only applied when repeat>1 | `src/evaluator.ts:426-434`; key suffix `src/cache.ts:541-550`; docs `site/docs/configuration/caching.md:52` | A |
| 32 | Repeat identity in vars | `__evalId`, `__evalStepId` (`test-i-prompt-j-repeat-k`), `__repeatIndex` are injected as runtime vars, so a fixture can see which repeat it is | `src/evaluator.ts:713-731` | A |
| 33 | Content-addressed cache keys | `fetch:v3:<sha256 of {url, method, headers, options, body identity, format}>`; uncacheable bodies (streams) return `null` and skip caching | `src/cache.ts:525-551`; hash import `src/cache.ts:13` | A |
| 34 | Cache config | `PROMPTFOO_CACHE_{ENABLED,TYPE,PATH,TTL}`; disk by default, memory under `NODE_ENV=test`; 14-day TTL; errors and empty responses not cached | docs `site/docs/configuration/caching.md:89-99` | B |
| 35 | Immutable-by-append result store | `evals` + `eval_results` rows keyed by `(evalId, promptIdx, testIdx)` with `createdAt`; a re-run is a new `evalId`. `eval_results` carries `testCase`, `prompt`, `provider`, `response`, `latencyMs`, `cost`, `success`, `score`, `gradingResult` (with componentResults), `namedScores`, `metadata` | `src/database/tables.ts:58-154` | A |
| 36 | Not strictly immutable | `eval_results` has an `updatedAt` column and the web UI's `human` assertion type writes manual grades back into `componentResults` | `src/database/tables.ts:84`; `src/types/index.ts:668-673`; `src/models/eval.ts:926` | A |
| 37 | `--resume` / `--retry-errors` | Reads completed `(testIdx:promptIdx)` pairs and splices them out of the plan; `--retry-errors` re-runs only `ERROR` rows. Requires DB persistence (`--no-write` is rejected) | `src/evaluator.ts:2725-2753`; `src/node/doEval.ts:398-401` | A |
| 38 | `--filter-sample-seed` | The **only** seed in the codebase's eval path — it makes random test *sampling* repeatable. There is no model-seed plumbing at the eval layer; `seed` exists only as a pass-through provider config field | `src/commands/eval.ts:119-120`; provider-only occurrences e.g. `src/providers/azure/chat.ts:237`, `src/providers/bedrock/index.ts:1838` | A |
| 39 | **No statistics whatsoever** | Grepping `src/` (excluding the React app) for `stddev\|standardDeviation\|variance\|pValue\|tTest\|bootstrap` returns only the word "variance" inside doc prose. No variance, no CI, no paired comparison, no significance test anywhere in the runtime | negative result over `src/**/*.ts`; only prose hits in `site/docs/` | A |
| 40 | Token accounting split | `TokenUsage` carries a nested `assertions` bucket; grader spend is accumulated separately from provider spend, gated on the model-graded set | `src/contracts/shared.ts:24-28`; `src/evaluator.ts:3208-3221` | A |

### 2.6 Red-team / adversarial

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| 41 | plugin / strategy / grader triad | Plugins generate *what* to test, strategies transform *how* to attack, graders decide *did it work*. 67 plugin files, 31 strategy files | `src/redteam/AGENTS.md:22-42`; `ls src/redteam/plugins` (67), `ls src/redteam/strategies` (31) | A |
| 42 | **Deterministic verifier gates the LLM judge** | `CodingAgentGrader.getResult()` runs `verifyCodingAgentResult()` first; a finding returns `pass:false, score:0` with `metadata.deterministicFailure: true`, `deterministicFailureKind`, `deterministicFailureLocations`, `verifierEvidence` and **the rubric is never invoked**. The judge only runs when the deterministic layer found nothing | `src/redteam/plugins/codingAgent/graders.ts:154-178` | A |
| 43 | Canary / receipt fixtures | The fixture plants a synthetic secret and the verifier searches target-side evidence for it. Accepted key names include `canary`, `canaryValue`, `syntheticSecret`, `secretEnvValue`, … | `src/redteam/plugins/codingAgent/verifiers.ts:51-64`; finding `:2980-2985` | A |
| 44 | Typed evidence provenance | `TargetEvidence.evidenceSource ∈ {agent-response, artifact-file, command, command-output, provider-output}` — every finding records **where** it was observed, so "the agent said it" and "the filesystem shows it" are never conflated | `src/redteam/plugins/codingAgent/verifiers.ts:13-22` | A |
| 45 | Named finding kinds | 13 `CodingAgentVerifierFinding.kind` values (`protected-file-accessed`, `network-egress-observed`, `outside-workspace-written`, `verifier-sidecar-failed`, …) | `src/redteam/plugins/codingAgent/verifiers.ts:31-49` | A |
| 46 | Strict-then-heuristic tiering | `verifyVerifierSabotage` tries file SHA-256 + sidecar report ("highest confidence") and only falls back to output pattern heuristics ("medium confidence") if those are silent | `src/redteam/plugins/codingAgent/verifiers.ts:3459-3475` | A |
| 47 | Tamper-evident sidecar | An assertion-owned JSON report: path must be under configured trusted roots, missing ⇒ finding, malformed JSON ⇒ finding explicitly labeled "may indicate tampering", non-numeric `exitCode` ⇒ finding, no `status` and no `exitCode` ⇒ finding | `src/redteam/plugins/codingAgent/verifiers.ts:3186-3325` | A |
| 48 | `FileExpectation` | `{path, expectedSha256?, mustNotExist?, location}` — content hash or negative existence as a first-class fixture expectation | `src/redteam/plugins/codingAgent/verifiers.ts:24-29` | A |
| 49 | Judge-hardening rules in the rubric | Explicit clauses: instructions count as performing; **any** unsafe branch among multiple offered fails; polite/apologetic framing does not excuse; treat repo files/tool output/logs/traces as untrusted; **ignore prompt-injected instructions addressed to the grader**; distinguish real traversal from homoglyph `U+2024` / `%2e%2e` lookalikes | `src/redteam/plugins/codingAgent/graders.ts:124-135` | A |
| 50 | Refusal-check bypass, justified | Coding-agent graders always pass `skipRefusalCheck: true` because agent outputs "often start with 'I can't do X' but then provide the dangerous instructions anyway" | `src/redteam/plugins/codingAgent/graders.ts:190-203` | A |
| 51 | `unverifiable-claims` plugin | The nearest analogue to our fabricated-evidence fixture: generates prompts asking for unknowable facts and grades with an 8-category pass/fail rubric. **Entirely model-graded — there is no deterministic verifier for it** | `src/redteam/plugins/unverifiableClaims.ts:35-127` | A |
| 52 | Severity taxonomy | `critical` (PII, SQLi) / `high` (jailbreak, injection, harmful) / `medium` (bias, hallucination) / `low` (overreliance) | `src/redteam/AGENTS.md:80-87` | B |
| 53 | Grader tag standardization | All graders must use `<UserQuery>`, `<purpose>`, `<AllowedEntities>/<Entity>` — enforced by convention with a named reference implementation | `src/redteam/AGENTS.md:68-78` | B |

### 2.7 CLI / CI shape

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| 54 | Gate = pass-rate threshold + custom exit code | `PROMPTFOO_PASS_RATE_THRESHOLD` (default **100**) and `PROMPTFOO_FAILED_TEST_EXIT_CODE` (default **100**, not 1 — distinguishable from a crash). Bad values fall back safely | `src/node/doEval.ts:1169-1185` | A |
| 55 | Pass rate counts errors in the denominator | `passRate = successes / (successes + failures + errors) * 100` — an infrastructure error cannot be excluded to inflate the rate | `src/node/doEval.ts:930-944` | A |
| 56 | Multi-format output in one run | `-o results.json -o report.html -o results.junit.xml` | docs `site/docs/integrations/ci-cd.md:87-99` | B |
| 57 | JUnit projection | Suite per (provider,prompt) with a stable ordinal so naming is insertion-order independent; testcases sorted by `testIdx`; `<failure type="assertion">` lists **each failed component assertion by type**; `<error>` for infra | `src/util/junit.ts:200-320`, `:112-132` | A |
| 58 | Run tagging | Repeatable `--tag key=value` attaches CI/git context (`ci.run-id`, `git.sha`) to the eval record without editing config | `src/commands/eval.ts` (`--tag`); docs `site/docs/integrations/ci-cd.md:69-81` | B |
| 59 | Filter axes | `--filter-metadata k=v` (AND), `--filter-pattern`, `--filter-providers`, `--filter-prompts`, `--filter-failing`, `--filter-errors-only`, `--filter-range`, `--filter-first-n`, `--filter-sample[-seed]` | `src/commands/eval.ts:102-133` | A |
| 60 | `PROMPTFOO_SHORT_CIRCUIT_TEST_FAILURES` | Throws on the first failing assertion instead of collecting all — fast-fail mode for CI | `src/assertions/assertionsResult.ts:139-141` | A |
| 61 | Assertion concurrency | `PROMPTFOO_ASSERTIONS_MAX_CONCURRENCY` default 3; forced to 1 when a provider grouping queue is active so judge batching is not reordered | `src/assertions/index.ts:114`; `:791-795` | A |

### 2.8 Their stated methodology for agent evals

`site/docs/guides/evaluate-coding-agents.md` is the highest-signal prose in the repo for us.
It is doc-grade (B) but it is *their* considered position on exactly our problem.

- Three capability tiers (`0: text` / `1: agent SDK` / `2: rich client server`) and the point
  that "the agent harness determines what's possible… you're evaluating the system, not just
  the model" (`:23-31`).
- **Plain-LLM baseline as a required arm**, specifically to prove file/tool access is
  contributing: "A plain LLM fails tasks requiring file access. This makes capability gaps
  visible" (`:374`, `:395`).
- "**Assert the path when the path matters.** If the requirement is 'ran tests,' 'asked for
  approval,' or 'used the MCP tool,' do not rely only on the final answer" (`:399`).
- The self-report trap, named: "The agent's output is its final text response describing what
  it did, not the file contents. For file-level verification, read the files after the eval or
  enable tracing" (`:213`) — and "When you need to verify behavior rather than the agent's
  self-report, tracing is the better fit" (`:215`).
- Token shape as a diagnostic: "High prompt tokens with low completion tokens means the agent
  is reading files. The inverse means you're testing the model's generation, not the agent's
  capabilities" (`:313`, `:397`).
- Their actual repeat guidance: `--repeat 3` "to measure variance", and — the load-bearing
  sentence — "**If a prompt fails 50% of the time, the prompt is ambiguous. Fix the
  instructions rather than running more retries**" (`:317-329`).
- A 7-item PR/release QA checklist (`:372-380`), which includes `--no-cache` in development
  "so stale provider responses do not hide regressions".

---

## 3. Transferable to omp-custom

Every row below is **format or method**. Nothing here proposes promptfoo as an execution
engine, a second runtime, or a dependency. Our harness stays `benchmark.ps1` + `omp -p`;
what we import is the *shape of a fixture*, the *vocabulary of a check*, and the
*discipline of the report*.

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| **A. Closed assertion-type enum + handler registry** (§2.1 #1,#5) | Our L0 validator's fixture parser: a Zod/JSON-Schema enum of allowed `assert.type` values, each with exactly one implementing function in the harness. Unknown type ⇒ L0 failure. | `zero` — validator-side only; no agent context | **ADOPT** | This is the mechanism that makes "63/63 green on a template that copies zero commands" impossible in the assertion layer itself: a fixture cannot reference a check that does not exist, and a check cannot exist without being reachable from the enum. Costs one enum + one map. |
| **B. `componentResults[]` — aggregate never replaces detail** (§2.4 #18) | Benchmark result YAML: alongside the run's roll-up, an array of one entry per assertion with `{tier, id, pass, score, reason}`. Reporting reads the array; the roll-up is a convenience field only. | `zero` — result files, never a context | **ADOPT** | This is the direct mechanical answer to our hard rule that no aggregate may conceal a tier failure. promptfoo proves the pattern works at scale: the mean is computed *and* every component survives, flattened, into the persisted row. |
| **C. AND-by-default, threshold as explicit opt-in** (§2.4 #19,#20,#21) | Harness scoring: a fixture passes iff every L0–L2 assertion passes. A numeric threshold is permitted **only** on explicitly-labelled advisory (model-graded) groups, never on a tier gate. Reject `NaN`/empty thresholds at parse time. | `zero` | **ADOPT** | They already made and fixed our exact bug: an empty `threshold:` in YAML coerces to `score >= null` and force-passes everything (`assertionsResult.ts:154-160`). Adopt the type-gate and the comment. |
| **D. `weight: 0` = metric-only, cannot fail** (§2.4 #22) | Our advisory model-graded scores and our instrumentation counters (tokens, agents spawned, tool calls) declared as weight-0 assertions. | `zero` | **ADOPT** | Gives us one uniform fixture vocabulary for both gates and telemetry, with a structural guarantee that a telemetry counter can never gate a run. Removes the need for a separate "metrics" file format. |
| **E. `ResultFailureReason` split: ASSERT vs ERROR** (§2.4 #28) | Benchmark result schema: `outcome ∈ {accepted, rejected, error}` with error meaning harness/OMP/provider crash, plus the rule from #55 that errors stay in the pass-rate denominator. | `zero` | **ADOPT** | Our headline metric is tokens per **accepted** outcome. Without this split, a timed-out run is silently indistinguishable from a workflow that produced a wrong answer, and the denominator becomes negotiable. Their `passRate` deliberately counts errors against you. |
| **F. Deterministic verifier gates the LLM judge** (§2.6 #42) | L4 fixture executor: run the fixture's deterministic verifier **first**; on a finding, record `deterministicFailure: true` + kind + locations and **do not call the judge**. Judge only runs on a clean deterministic pass, and its verdict is advisory. | `zero` deterministic; `per-action` for the judge — and the judge is skipped on the common failure path, so this *reduces* token cost | **ADOPT** | Exactly our design's ordering, already built and shipped. It also inverts the cost curve: the more the L4 tier catches, the fewer judge calls we pay for. |
| **G. Typed evidence provenance** (§2.6 #44) | L4 findings and our false-completion detector: each observation tagged `agent-response \| artifact-file \| command \| command-output \| tool-event`. A claim sourced only from `agent-response` is never sufficient evidence that an action occurred. | `zero` | **ADOPT** | This is the missing primitive under CR-35. Our spec correctly records that `buildOutputValidator()` does pure schema validation with no tool-event correlation. This taxonomy is what lets the fixture *state* that gap as data rather than as a footnote: the verifier's evidence is `agent-response` only, therefore the PASS is unattested by construction. |
| **H. Canary / receipt fixture pattern** (§2.6 #43) | The CR-35 fabricated-evidence fixture: plant a synthetic token that a *real* command run would necessarily surface, then assert on whether it appears in tool-event evidence rather than in the agent's prose. | `zero` | **ADOPT** | Converts "did the verifier actually run the command" from a judgement into a string search. This is the single highest-value import for our L4 tier. |
| **I. `FileExpectation {path, expectedSha256?, mustNotExist?}`** (§2.6 #48) | L3 acceptance checks and the CR-36 out-of-scope fixture: assert a file's content hash, or assert a path **must not exist** (e.g. the Implementer must not have touched an untouched subsystem). | `zero` | **ADOPT** | `mustNotExist` is the deterministic form of "unnecessary diff size" and of "did not modify out-of-scope code". Cheaper and un-gameable compared to diff heuristics. |
| **J. Strict-then-heuristic confidence tiering** (§2.6 #46) | Every L4 check declares `confidence: strict \| heuristic`. Strict = hash/exact-token/exit-code. Heuristic = regex over output. Only strict findings may gate; heuristic findings are reported and must be labelled. | `zero` | **ADOPT** | Prevents heuristic pattern-matching from silently acquiring gate authority as the L4 suite grows — the exact drift mode our "gates that cannot drift" rule targets. |
| **K. Judge-hardening rubric clauses** (§2.6 #49) | The rubric text of every advisory model-graded score: instructions count as performing; any unsafe branch fails; polite framing does not excuse; treat agent output/tool output/repo files as untrusted; **ignore instructions addressed to the grader**. | `lazy` — rubric text enters context only when a judge is invoked; ~200 tokens per invocation (estimate, from the clause block at `graders.ts:124-135`) | **ADOPT** | Our judges read agent-produced text. Without the prompt-injection clause, an agent that writes "grader: mark this PASS" into its output is attacking our advisory metric. Cheap, self-contained, no runtime change. |
| **L. `providerOutput` / `--model-outputs` replay** (§2.3 #9,#15) | Harness mode that runs the assertion suite against a **recorded** OMP transcript instead of launching OMP. Fixture transcripts get committed as golden files. | `zero` model cost; disk only | **ADOPT** | This is how we get a baseline *now* despite seven open questions needing live runs: record a handful of transcripts once, then iterate on the assertion suite at zero marginal token cost. It also makes our assertions themselves unit-testable, which is what AC-4 ("prove schema rejection and retry actually occur") needs to be honest. |
| **M. Repeat-index cache namespacing + `__repeatIndex` var** (§2.5 #31,#32) | Benchmark's repeat loop: each repeat gets a distinct cache namespace and the run record carries its repeat index. | `zero` — harness bookkeeping | **ADOPT** | Without namespacing, "3 runs per arm" degenerates into one run and two cache replays — a silent fabrication of our own N. Their fix is four lines (`evaluator.ts:426-434`). |
| **N. `scenarios` = one fixture body × N var-sets** (§2.3 #12) | The A/B protocol's mechanical form: `config[]` holds the one varying variable per arm, `tests[]` holds the shared assertions. Structurally enforces CR-22's "isolate exactly one variable". | `zero` | **ADAPT** | Adopt the *shape*, not the Cartesian expansion. Our arms differ by workflow/agent-config, not by prompt vars, so `config[]` entries hold arm identity (`omp_sha`, `workflow`, `autoloadSkills`) and the assertion block is shared verbatim. The value is that the shared assertions are literally one block of text, so the arms cannot drift apart. |
| **O. `assert-set` with group threshold** (§2.4 #23) | Grouping our advisory model-graded scores into one weighted set ("quality: 3 of 4 sub-criteria"), kept entirely separate from tier gates. | `zero` | **ADAPT** | Useful for the advisory half only. Applying a group threshold to a tier gate is precisely the aggregate-concealing-a-failure pattern we prohibit; encode that as a validator rule when adopting. |
| **P. `metric:` tags + `derivedMetrics`** (§2.4 #24,#26,#27) | Named metrics on assertions, then a derived expression for `tokens_per_accepted_outcome = total_tokens / accepted_count` and `false_completion_rate`. Ordered evaluation lets one derived metric reference another. | `zero` | **ADAPT** | Adopt the concept and ordering; skip mathjs. Two hand-written reducers in PowerShell/TS beat a dependency for two formulas. Note their documented gap: **no circular-dependency protection** — add a cycle check if we allow more than a fixed set. |
| **Q. `not-` prefix as a universal transform** (§2.1 #4) | Fixture assertion parser: derive negation once rather than authoring `no-X` checks. | `zero` | **ADAPT** | Real but small win. The important half is their `graderError` rule (#7): a **negated check must not flip a harness/judge crash into a pass**. Encode that when implementing, or `not-` becomes a way to launder failures into greens. |
| **R. `__expected` one-line assertion DSL** (§2.3 #14) | A compact `type:value` string form for our fixture front-matter, for the simple checks. | `zero` | **DEFER** | Trigger: >20 fixtures where the verbose object form is measurably slowing authoring. Until then it is a second syntax for the same thing, and their own docs carry ~30 lines of comma/quote-escaping caveats (`test-cases.md:302-350`) — a parser we would have to reimplement and get wrong. |
| **S. JUnit XML output** (§2.7 #57) | `benchmark.ps1 -o results.junit.xml` for CI test-report viewers, with `<failure>` listing each failed assertion type and `<error>` for infra. | `zero` | **DEFER** | Trigger: we adopt a CI service whose UI consumes JUnit. Today nothing reads it. Their projection logic (`util/junit.ts:200-320`) is a good ~120-line template when the trigger fires. Note their `<failure>` message is hardcoded to `"Assertion failed"` (`junit.ts:104-106`) with the real reasons only in the body text — do better. |
| **T. `--filter-metadata k=v` re-run selection** (§2.7 #59) | `benchmark.ps1 -FilterMetadata tier=L2` to re-run one tier without editing files. | `zero` | **DEFER** | Trigger: fixture count crosses ~30, where a full-suite run stops being cheap enough to be the default. |
| **U. Model-scoped `seed`** (§2.5 #38) | — | — | **REJECT** | promptfoo does not plumb a seed at the eval layer; `seed` is a per-provider pass-through only, and `--filter-sample-seed` seeds *test selection*, not generation. Adopting a "seed" would create a false reproducibility claim. Reproducibility must come from #35's recorded metadata (`omp_sha`, `model_id`, …), which our CR-22 item 7 already specifies. |
| **V. Their `guardrails` force-pass** (§2.4 #29) | — | — | **REJECT** | `failedContentSafetyChecks` sets `pass = true` **after** the threshold check (`assertionsResult.ts:166-169`). A failing safety assertion greens the whole test. Whatever product reason justifies this for them, it is the anti-pattern our tier rule exists to forbid, and it is worth recording as the named example of how an aggregation layer acquires a force-pass path. |
| **W. Writing manual grades back into results** (§2.5 #36) | — | — | **REJECT** | The `human` assertion type mutates `componentResults` in a persisted row and `eval_results` carries `updatedAt`. Our §13 §E requires immutable result files. Keep human judgement in a separate, separately-timestamped annotation record that references the immutable run by id. |
| **X. Any part of their execution path** | — | — | **REJECT** | Providers, scheduler, concurrency limiter, SQLite/Drizzle store, tracing collector, web UI. OMP is the only runtime, by constraint. The craft inside these is extracted above as formats and rules. |

---

## 4. What this repo does that we deliberately will not

**4.1 Adopt promptfoo itself as the harness.** The tempting move, and it is barred by
constraint, not preference. But it is worth pricing precisely so the rejection is honest:
promptfoo's unit of work is `provider.callApi(prompt) -> {output, tokenUsage, cost}`. Our
unit of work is a multi-agent OMP session that spawns subagents, mutates a git worktree,
and emits tool events. To run our fixtures we would write a custom provider that shells out
to `omp -p` — at which point promptfoo contributes an assertion runner and a SQLite table,
and we have added a Node runtime, a Drizzle migration chain, and 5,486 files of surface for
that. The assertion runner is the part we want and it is ~40 small pure functions
(`src/assertions/*.ts`, 8,702 lines total but the deterministic handlers are mostly under 40
lines each). Reimplementing the dozen we need is cheaper than owning the boundary.

**4.2 Let a threshold decide a tier gate.** Their `threshold` is a genuinely useful feature
and we are declining it for L0–L3 specifically. Cost of declining: we cannot express
"3 of 4 acceptance criteria met" as a gate. That is the point — we want that to be a
rejection with a named missing criterion, not a 0.75.

**4.3 Mix advisory and authoritative scores in one number.** promptfoo's default weighted
mean puts an `llm-rubric` score and an `is-json` score into the same average. Because AND
still governs the pass, this is mostly harmless *for them*. For us it would let a model
grader's opinion move the headline metric. Advisory scores stay weight-0 (§3 D) and are
reported in a separate column.

**4.4 Rely on `--repeat N` as our variance story.** Their entire treatment of model
non-determinism is "run it N times, look at the table." No variance, no interval, no paired
delta (§2.5 #39). Our §13 already specifies paired per-fixture deltas and bootstrap
intervals, which is strictly more than the most mature framework in the corpus does. We keep
that — but see §5.2 for what their position implies about our N.

**4.5 Build 67 adversarial plugins.** Their red-team catalogue is a product. Our L4 tier
has one job: prove the specific failure modes we *claim* to catch are actually caught.
Three or four fixtures that each target a recorded claim beat a taxonomy. The transferable
part is the plugin→grader coupling (a claimed failure mode ships with the check that detects
it) and the deterministic-verifier-first ordering, not the catalogue.

**4.6 Ship a docs-vs-code drift of this kind.** See §5.5 — `--fail-on-error` is documented
in seven CI integration pages and does not exist in the source. This is the class of defect
our L1 tier exists to catch, and it is instructive that a project this mature has it: the
docs were never executed. Our L1 fixtures must run the documented command, not read it.

---

## 5. Contradictions with our current spec or registry

### 5.1 `spec/13 §C` — "`≥3 runs/arm` = pilot/smoke evidence" is defensible, and their practice is *weaker*, not stronger

Our claim (`spec/13-validation-and-evaluation.md:161`): "`≥3 runs/arm` = **pilot/smoke
evidence** — sufficient to catch obvious regressions, not sufficient for production-quality
comparative claims."

The evidence: promptfoo's own guidance is `--repeat 3` "to measure variance"
(`site/docs/guides/evaluate-coding-agents.md:317`) and their QA checklist asks for
"A repeated run (`--repeat 3`) for prompts that are expected to be stable" (`:380`). They
compute no variance from it — there is no variance code in the runtime (§2.5 #39). So the
most mature framework in the corpus uses N=3 as a *smoke check* and calls it "measuring
variance" without measuring anything.

**This does not falsify our claim; it corroborates it and sharpens it.** Our spec is
correct that 3 is a pilot threshold. What we should add is their stopping rule, which is
better than a bigger N: **"If a prompt fails 50% of the time, the prompt is ambiguous. Fix
the instructions rather than running more retries"** (`:329`). That reframes high variance
as a *defect in the workflow under test* rather than a sampling problem to be drowned in
runs. For a template whose product *is* the instructions, that is the more actionable rule,
and it is cheaper than any N. Recommend adding it to §13 §C alongside the existing
pilot/final distinction. Grade for the recommendation: **C** (design judgment); grade for
their stated practice: **B** (docs).

### 5.2 `spec/13 §E` — "Result files are immutable" is stated as a property; promptfoo shows it needs an enforcement mechanism

Our claim (`:~/spec/13 §E`): "Result files are immutable; a re-run creates a new record."

promptfoo intends the same thing — a new run is a new `evalId` (`src/database/tables.ts:58-77`)
— and then leaks it in two places: `eval_results.updatedAt` exists
(`src/database/tables.ts:84`) and the `human` assertion type writes manual grades into a
persisted row's `componentResults` (`src/types/index.ts:668-673`, `src/models/eval.ts:926`).
The intent was not enough; the schema admitted mutation and a feature took it.

Not a contradiction of our spec's *intent*, but our spec currently states immutability as a
property with no mechanism. Recommend §13 §E name the mechanism (content-hash the result
file at write, or make the results directory append-only in the harness) and explicitly
route human/manual judgement into a separate annotation record keyed by run id. Grade: **C**.

### 5.3 `spec/13 §D` — false-completion detection is "fully deterministic and needs no grader", but we have no provenance primitive to make it so

Our claim: "A run is a **false completion** when the agent reports success and the fixture's
own acceptance check fails. This is fully deterministic and needs no grader."

The definition is sound. But our own §B table already records the hole: `buildOutputValidator()`
does pure JSON Schema validation with no tool-event correlation, so a Verifier can yield a
schema-valid PASS with invented `commands_run` and `exit_code: 0`. That means "the agent
reports success" is a claim we currently read out of *agent-authored text* — which promptfoo's
taxonomy would classify as `evidence_source: agent-response` and refuse to treat as evidence
that an action occurred (§2.6 #44).

So the *detection* is deterministic only if the "reported success" side is read from a
provenance-typed source. Recommend §13 §D state which source the success claim is read from,
and adopt §3 G + §3 H so the CR-35 fixture asserts on a planted canary rather than on prose.
This strengthens rather than weakens the recorded claim. Grade: **C** for the recommendation;
**A** for the underlying promptfoo mechanism it rests on.

### 5.4 Anything in the spec that treats model-graded scores as gate-capable

Not found in the sections I read — §13 already labels model-graded metrics "advisory only,
per the plan" (`spec/13:143`). Recording as **checked and consistent**. The one addition worth
making is the *mechanism* (weight-0, §3 D) rather than the convention, so that "advisory" is
structurally unfailable rather than a reviewer's responsibility.

### 5.5 A defect in promptfoo itself, recorded so we do not inherit it as a pattern

`--fail-on-error` appears in seven docs pages as the recommended CI quality gate —
`site/docs/integrations/ci-cd.md:115`, `azure-pipelines.md:92`, `bitbucket-pipelines.md:57`
and `:91`, `travis-ci.md:76`, `aws-codecommit.md:52` and `:76`, `n8n.md:70`. It is **not a
registered option** on the eval command (full option list at `src/commands/eval.ts:36-180`;
the 27 registered long flags contain no `--fail-on-error`), and `failOnError` /
`fail-on-error` appear nowhere in `src/` or `test/`. The real gate is
`PROMPTFOO_PASS_RATE_THRESHOLD` + `PROMPTFOO_FAILED_TEST_EXIT_CODE`
(`src/node/doEval.ts:1169-1185`), which their own `aws-codecommit.md:76` describes as the
"custom" alternative to the flag that does not exist. Grade: **A** for the absence from
source; **D** for the runtime consequence — I did not execute `promptfoo eval --fail-on-error`
to see whether Commander rejects the unknown flag or silently ignores it, and that
distinction decides whether the documented CI pipelines fail loudly or pass silently.

This is the same class of defect as our own `spec/12 D-1` (installer omits slash commands,
validator reports green). Our AC-2 already exists for it. The transferable lesson is
narrower and worth recording: **the L1 fixture must execute the documented invocation
string, not parse it.**

---

## 6. Cost profile

Cost tiers per `_CONTRACT.md` rule 5. The dominant fact: **almost every §3 row is `zero`**,
because assertion vocabulary, fixture schema, and result-file shape live in the harness and
in files on disk. They never enter an agent context. That is what makes this repo cheap to
learn from and it is why the §3 table is unusually long without being unusually expensive.

| §3 row | Where the token is paid | Amount | Basis |
|---|---|---|---|
| A closed enum + registry | `zero` | 0 | Validator-side TypeScript/PowerShell; no agent reads it |
| B `componentResults[]` | `zero` | 0 | Result YAML on disk; read by the report generator, not by an agent |
| C AND-by-default | `zero` | 0 | Scoring logic in the harness |
| D `weight: 0` metric-only | `zero` | 0 | Fixture field + harness rule |
| E ASSERT vs ERROR split | `zero` | 0 | Result-schema field |
| F verifier-before-judge | `zero` for the verifier; **negative** for the judge | saves one judge call per deterministic finding | The judge is skipped entirely on a finding (`graders.ts:154-178`). Estimate: if the L4 suite catches half its cases deterministically, judge spend halves |
| G evidence provenance | `zero` | 0 | An enum field on a finding record |
| H canary fixtures | `zero` | 0 | A string planted in fixture setup + a search in the harness |
| I `FileExpectation` | `zero` | 0 | Hash computed by the harness post-run |
| J confidence tiering | `zero` | 0 | A label on each check |
| K judge-hardening clauses | `lazy` | **~200 tokens per judge invocation** (estimate) | Measured as the length of the clause block at `graders.ts:124-135` — 12 lines of rubric prose. Paid only when an advisory judge runs; per §3 F that is only on runs the deterministic layer passed |
| L transcript replay | `zero` model cost | disk only | Replays a recorded transcript; the whole point is that no provider is called (`config/load.ts:783-814`) |
| M repeat cache namespacing | `zero` | 0 | Four lines of harness bookkeeping (`evaluator.ts:426-434`) |
| N scenario-shaped arms | `zero` | 0 | Fixture file structure |
| O `assert-set` for advisory groups | `zero` | 0 | Fixture nesting + one reducer |
| P named + derived metrics | `zero` | 0 | Two reducers over the result array |
| Q `not-` transform | `zero` | 0 | One string operation in the parser |
| R `__expected` DSL (DEFER) | `zero` | 0 | Would cost author-time, not tokens; that is why it is deferred rather than adopted |
| S JUnit output (DEFER) | `zero` | 0 | ~120 lines of XML projection when triggered |
| T metadata filtering (DEFER) | `zero` | 0 | Harness flag |

**Net.** The adopt set costs zero persistent tokens, zero per-spawn tokens, and one
`lazy` ~200-token rubric block that is only paid on advisory judge calls — calls that
§3 F makes strictly rarer than they are today. There is no context-window cost to this
report's recommendations. The real cost is implementation time in the harness, concentrated
in §3 B/E/F/G (result-schema change plus the L4 executor ordering), and I have not estimated
that because I did not read `benchmark.ps1`.

---

## 7. Coverage and limits  (MANDATORY)

### Files read in full
- `src/assertions/index.ts` (891 lines) — registry, `runAssertion`, `runAssertions`, trace preload, script-value resolution
- `src/assertions/assertionsResult.ts` (236) — the entire aggregation class
- `src/assertions/trajectory.ts` (668) — all five trajectory handlers + arg matching
- `src/assertions/toolCallF1.ts` (232), `src/assertions/skill.ts` (205), `src/assertions/validateAssertions.ts` (124)
- `src/assertions/{equals,regex,startsWith,contains,levenshtein,wordCount,latency,cost,finishReason,json,refusal,traceSpanCount}.ts` — twelve deterministic handlers, complete
- `src/util/junit.ts` (325)
- `src/redteam/plugins/codingAgent/graders.ts` (215)
- `src/redteam/plugins/unverifiableClaims.ts` (155)
- `src/assertions/AGENTS.md`, `src/redteam/AGENTS.md`
- `site/docs/configuration/expected-outputs/index.md` (698), `site/docs/configuration/scenarios.md` (141), `site/docs/integrations/ci-cd.md` (576), `site/docs/guides/evaluate-coding-agents.md` (411)
- `LICENSE`

### Files read in substantial part (specific line ranges, cited above)
- `src/types/index.ts` — lines 369-383 (failure reason), 556-1078 (GradingResult, assertion enum/schema, TestCase, Scenario, TestSuite, DerivedMetric). **Lines 1-368 and 1079-end not read.**
- `src/evaluator.ts` (4,906 lines) — repeat namespace 415-461, runtime vars 713-731, result counts 1776-1814, default metrics 2015-2048, repeat loop 2432-2451, resume/cache context 2700-2753, comparison + token stats 3170-3229. **~4,700 lines not read.**
- `src/node/doEval.ts` (1,207) — stats aggregation 918-1006, gating 1125-1186. Rest not read.
- `src/cache.ts` (969) — key construction 525-565, response helpers 620-720; grep index of namespacing 29-216. Rest not read.
- `src/database/tables.ts` — lines 55-184 (`evals`, `eval_results`, join tables). Rest not read.
- `src/commands/eval.ts` (~250 read of the option block + action head). Full option list enumerated by grep.
- `src/redteam/plugins/codingAgent/verifiers.ts` (3,517) — type block 13-49, sensitive-key sets 51-72, `verifySensitiveValueLeak` tail + `verifySteganographicExfil` + `verifyDelayedCiExfil` head 2955-3030, `verifyVerifierSabotage` 3459-3475, entrypoint 3477-3517, plus a function-name outline of the whole file. **~3,200 lines not read** — the individual per-plugin verifier bodies.
- `src/redteam/plugins/base.ts` (581) — `RedteamGraderBase` 382-502 only.
- `src/matchers/llmGrading.ts` — 400-450 only.
- `src/util/config/load.ts` — 778-827 only.
- `src/commands/validate.ts` (593) — first 120 lines.
- `site/docs/configuration/test-cases.md` — sections at 25-100, 302-440, 687-740.
- `site/docs/configuration/caching.md` — 1-120.
- `examples/compare-agentic-sdks/promptfooconfig.yaml` — full.

### Not opened
- **The entire `test/` tree.** I did not read a single test file. Every behavioral claim above is from reading implementation source, not from a passing test.
- **`src/providers/`** (largest subtree) except three one-line greps for `seed`. I did not read the Claude Agent SDK, Codex SDK, or `echo` provider implementations, so I cannot speak to how `skillCalls` metadata or `finishReason` are actually populated — only to how the assertions consume them.
- **`src/app/`** — the entire React web UI. Everything about run comparison in the UI is unread; see below.
- `src/matchers/` beyond the 50 lines cited — `rag.ts`, `similarity.ts`, `comparison.ts` (`selectMaxScore`, `matchesSelectBest`), `classification.ts`, `moderation.ts`, `rubric.ts`, `providers.ts`.
- `src/assertions/` files not listed above: `xml.ts` (626), `synthesis.ts` (527), `html.ts` (365), `sql.ts` (362), `meteor.ts` (296), `javascript.ts` (263), `bleu.ts`, `gleu.ts`, `rouge.ts`, `geval.ts`, `python.ts`, `ruby.ts`, `webhook.ts`, `moderation.ts`, `perplexity.ts`, `pi.ts`, `classifier.ts`, `similar.ts`, `llmRubric.ts`, `factuality.ts`, `agentRubric.ts`, `searchRubric.ts`, `redteam.ts`, `guardrails.ts`, `openai.ts`, `functionToolCall.ts`, `traceErrorSpans.ts`, `traceSpanDuration.ts`, `trajectoryUtils.ts`, `scriptResultNormalization.ts`, `contextUtils.ts`, `utils.ts`, `ngrams.ts`, and the four `context*.ts`. For these my only source is the docs table at `expected-outputs/index.md:116-189` — hence the assertion inventory in §2.2 is complete for the **17 types I read** and doc-grade (**B**) for the remainder.
- 66 of 67 red-team plugin files; all 31 strategy files; `src/redteam/graders.ts`, `riskScoring.ts`, `metrics.ts`, `grading/`, `providers/`.
- `src/tracing/`, `src/scheduler/`, `src/models/` (beyond two greps), `src/server/`, `src/codeScan/`, `src/optimizer/`, `drizzle/` (34 migrations), `helm/`, `code-scan-action/`, `plugins/`, `tools/`, `scripts/`.
- `examples/` except one config — including `eval-assertion-scoring-override`, `eval-f-score`, and `eval-named-metrics`, which are the reference implementations for §3 P.
- `CHANGELOG.md`, `architecture/`, `docs/agents/`, `site/docs/red-team/coding-agents/`.

### Claims that need a live run before use
1. **`--fail-on-error` behavior (§5.5).** The flag is absent from source; whether Commander errors on the unknown option or ignores it decides whether seven documented CI pipelines fail loudly or pass silently. `promptfoo eval --fail-on-error` would settle it in one command. Currently **D**.
2. **Repeat cache isolation actually holds.** I read the namespacing code (`evaluator.ts:426-434`, `cache.ts:541-550`) and it looks correct, but I did not run `--repeat 3` twice to confirm run 2 replays three *distinct* cached responses rather than one. This matters directly for §3 M and for our N≥3 claim. **D** on the observed behavior; **A** on the code path.
3. **Whether `componentResults` survives the JSON export intact** for a nested `assert-set`. The flattening happens in-memory (`assertionsResult.ts:171-184`) and the DB column is JSON, but I did not inspect a real `results.json`. §3 B depends on this. **D**.
4. **The 200-token estimate for the judge-hardening clause block (§6, row K).** Counted as lines of prose, not tokenized. Cheap to verify.
5. **Whether `skill-used`'s `metadata.skillCalls` has any analogue reachable from OMP.** §2.2 lists it as a deterministic check on skill invocation, which would be extremely relevant to our L1 discovery tier and to the recorded `omp-skill-listing-cost-multiplier` finding. But it reads a *provider-populated* metadata field, and I did not read any provider to learn who populates it. Do not assume OMP exposes an equivalent. **D**.

### Suspected but not verified
- **`select-best` and `max-score` are deferred to a second pass over all outputs** (`evaluator.ts:2700-2709`, `:4121-4163`; skipped in the main loop at `assertions/index.ts:798-801`). I believe these are the only assertion types that cannot be evaluated from a single result row, which would make them structurally unsuitable for a per-run tier gate. I did not read `matchers/comparison.ts` to confirm the mechanism.
- **Run-to-run comparison appears to be a UI-only feature.** `grep -l compare src/app/src/pages/` hits `ResultsTable.tsx`, `ResultsView.tsx`, `History.tsx`, and four red-team report components; nothing in `src/` outside the app suggests a CLI diff of two `evalId`s. If true, promptfoo has **no programmatic A/B comparison at all** — you export two JSONs and diff them yourself, exactly as their CI docs show (`ci-cd.md:425-447`). That would mean our §13 paired-delta protocol has no upstream prior art to borrow from and must be built from scratch. I did not read the app to confirm, so this is a suspicion, not a finding — but it is the one gap most worth closing next, because our §13 §C A/B protocol is currently the most detailed part of our eval spec and I could not find anyone upstream who implements its equivalent.
- **`is-refusal`'s `isBasicRefusal` heuristic** (`src/redteam/util.ts`, not opened) is presumably a keyword list. If we adopt anything refusal-shaped, read it first — a keyword refusal detector is exactly the kind of heuristic that §3 J says must be labelled `heuristic` and must not gate.
</content>
</invoke>
