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
- **CR-39 — `blocking: true` on every worker agent.** All four worker files MUST declare it.
  `blocking` has no parser default (`discovery/helpers.ts:299`) and `async.enabled` defaults to
  `true`, so a missing key silently converts that worker into a background job and breaks every
  stage barrier the workflows are written around (§08 §C-1). Absent or non-`true` is a **FAIL** —
  this is the exact class of defect static validation exists to catch, because the runtime
  symptom is a clean-looking early return rather than an error.
- **CR-40 — LSP allowlist ↔ setting coherence.** If any agent lists `lsp` in `tools:`, the
  template's project `config.yml` MUST set `task.enableLsp: true` (default is `false`). An
  allowlist that grants a tool the settings layer withholds is the round-1 defect inverted, and
  it is statically detectable.
- **CR-41 — `lsp.enabled` gate.** LSP is a four-condition conjunction; `lsp.enabled` (default
  `true`) is a separate settings key from `task.enableLsp`. An L0 check that covers CR-40 does
  not cover CR-41, because `lsp.enabled=false` with `task.enableLsp=true` satisfies the CR-40
  allowlist↔setting check while leaving LSP unavailable. Statically flag the contradiction when
  the template config sets `task.enableLsp: true` but also sets `lsp.enabled: false`.

### L1 — Discovery (new, highest value per effort)

Install into a scratch directory, then confirm **OMP itself** sees every component.
This is the layer that would have caught D-1 on day one.

Assertions:
- All three slash commands are discovered and invocable.
- **All four worker agents** (`explorer`, `implementer`, `verifier`, `diff-reviewer`) parse and appear in the agent list — no `logger.warn` drops.
- **CR-33 — `tech-lead` does NOT appear in the discovered agent list.** The Tech Lead is the main session (DR-1); the role-reference document lives at `docs/roles/tech-lead.md`, outside every agent discovery root. A discovered `tech-lead` agent is a **FAIL**, not a warning: `loadAgentsFromDir()` parses every `.md` under `.omp/agents/` as an active `AgentDefinition`, so its presence creates a second, spawnable Tech Lead path that contradicts the selected topology.
- All three skills are discovered.
- **CR-39 — `blocking === true` survives discovery for all four workers.** L0 checks the file
  bytes; L1 checks the parsed `AgentDefinition`, because `parseBoolean` is what the runtime
  actually consults (`task/index.ts:707` tests `effectiveAgent.blocking === true` — only exact
  `true` blocks, so a truthy-but-not-`true` value would pass a naive text check and fail at
  runtime).
- **CR-39 — effective `task.batch == true`.** The Orchestrated path depends on the `tasks[]`
  wire shape and its stable indices; `false` reverts to the flat single-spawn form and must
  disable the parallel path rather than fail mid-run (§08 §C-1.4).
- **CR-40 — effective `task.enableLsp == true`** in the project target. This is the settings
  half of the LSP conjunction; the allowlist half is L0 and the parent-session half is only
  observable at runtime (T-00.E5 E5-C).
- **CR-41 — effective `lsp.enabled == true`** alongside `task.enableLsp`. Both settings must be
  true for the child tool list to contain `lsp`. Check the effective merged value — a project
  config that sets `task.enableLsp: true` while a higher layer sets `lsp.enabled: false` will
  pass the CR-40 check but still produce no LSP tool. (T-00.E5 E5-F is the runtime fixture.)
- **CR-43 — effective Verifier `bash` tool presence.** The Verifier's allowlist entry is
  necessary but not sufficient: `bash.enabled` (default `true`) gates registration independently.
  L1 MUST confirm the effective Verifier tool set includes `bash`. A Verifier missing effective
  `bash` is a configuration failure — do not dispatch it and report a schema-valid `PASS`.
  (§10 §B-2, CR-43 L4 fixture below.)
- Custom model roles resolve (§09) — `@explorer` maps to a real model, not silently to `default`.
- `.omp/AGENTS.md` and `.omp/RULES.md` load, with RULES.md forced `alwaysApply` (§11).
- **CR-31 — effective isolation settings.** Read the *effective* (post-precedence) values and assert `task.isolation.mode != "none"`. For a project-target install, also assert `task.isolation.apply == false`. For a user-target install without `-EnableCaptureFirstIsolation`, assert the key was **not** written globally and that the preflight notice was emitted. This is the static counterpart to the mandatory `/orchestrated` runtime preflight (§08 §E-9) — it catches a bad install, but does not replace the runtime read, because a CLI overlay can still override it.

A component that OMP cannot see is broken regardless of how well-formed its file is. A component OMP *can* see but the architecture does not want is equally broken.

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

**CR-31/CR-32/CR-33 — required additional L4 cases.** Each of the three Round-5 findings describes a *silent* failure, which is precisely the class L4 exists to catch:

| Case | Setup | Required detection response |
|---|---|---|
| **Effective `apply=true` despite install** | Install correctly, then override `task.isolation.apply: true` via a higher-precedence layer (CLI overlay / runtime override), then run `/orchestrated` on independent parallel scope | `/orchestrated` preflight refuses the parallel path; falls back to sequential non-isolated or refuses with the setting named; degradation disclosed in the final report. **Silently fanning out with `apply=true` is a FAIL.** |
| **`mode: none` with parallel dispatch** | Set `task.isolation.mode: none`, run `/orchestrated` | Preflight refuses. The `isolated` field is *stripped* not rejected (§08 §A), so absent the preflight this silently degrades to concurrent unisolated writers — the worst case in the suite. |
| **Nested repo present at all** | Fixture repo containing a nested git repo or submodule; request ordinary independent parallel work touching **only root paths** | Preflight detects `nested_repo_count > 0` and **disables parallel isolated implementation for the whole repository**, routing to sequential non-isolated (§08 §D-1.2). The check fires on *presence*, not on requested scope. **Fanning out in parallel because "the scope avoids the nested repo" is a FAIL** — that was the withdrawn Round-5 rule (CR-32 round 6). |
| **`tech-lead` discoverable as an agent** | Place any `tech-lead.md` under an agents discovery root | L1 reports FAIL (§B L1). Verifies the CR-33 relocation cannot silently regress. |

The first three share a signature worth stating plainly: the runtime returns success, the report reads clean, and work is missing or unsafely serialized. None of them is detectable from the task result alone — each needs an explicit assertion.

**Why the nested-repo case tests the preflight and not a post-hoc detector.** An earlier
revision of this table asserted that post-integration nested-repo `git status` would flag a
violating worker. It cannot: on the successful `apply=false` path the nested change is never
persisted and the worktree is torn down, so the parent's nested repo is unchanged whether the
worker complied or silently lost work (§08 §D-1.1). A fixture asserting on that detector would
pass while the defect it targets goes undetected — the exact "validator that cannot fail on a
real defect" this spec's principle 9 prohibits. The assertion is therefore on the **preflight
decision**, which is observable: did the orchestrator refuse to fan out?

**CR-35/CR-36 — evidence-provenance and failure-taxonomy fixtures.** Both target the
project's central "no false completion" claim:

| Case | Setup | Required detection response |
|---|---|---|
| **Verifier fabricates evidence** (CR-35) | Drive a Verifier that makes **zero** `bash` calls and yields a schema-valid `PASS` with invented `commands_run`, `exit_code: 0`, and per-criterion `evidence` strings | The yield **succeeds** — `buildOutputValidator()` does pure JSON Schema validation with no tool-event correlation (`tools/output-schema-validator.ts`). This is the **expected** outcome and must be recorded as such. The fixture's assertion is on the *spec*, not the runtime: `spec/10 §B-1` and phase-04 T-04.1 MUST describe verification as shape-enforced and behaviorally-required, never as provenance-attested. **A spec claiming schema fields "cannot be satisfied without real command output" while this fixture passes is a FAIL.** |
| **Transcript audit detects the fabrication** (CR-35, T-04.8) | Same fixture; Tech Lead then reads `history://<verifier-id>` | The transcript renders one line per tool call with name and arguments (`session/session-history-format.ts`), so a Verifier with zero `bash` calls is distinguishable from one that ran the claimed commands. Records whether the audit is deterministic enough to gate on. Gates any future stronger claim. |
| **Deterministic pre-existing failure** (CR-36) | Baseline contains a deterministic failing test in a subsystem the diff does not touch; implemented change is clean; Verifier runs the full suite | Classification is `preexisting` with baseline evidence, and the Implementer is **not** dispatched. **Classifying as `impl` is a FAIL** — it sends the Implementer to modify out-of-scope code, the exact expensive error the taxonomy exists to prevent (§10 §B). |

**CR-38/CR-39/CR-40/CR-41/CR-42/CR-43 — required additional L4 cases.** All are silent-failure classes at the
OMP task boundary, which is what L4 exists for:

| Case | Setup | Required detection response |
|---|---|---|
| **Parent overlay defeats the settings read** (CR-38/CR-42) | Project config `apply: false`; launch the parent with `--config` setting `apply: true`; run `/orchestrated` on independent parallel scope | Subprocess `omp config get` reports `false` (a false pass on its own). The **same-session read-only canary** detects the merge-summary does NOT begin with "Isolation:", fails the preflight, and blocks fan-out — **without modifying any parent file** (CR-42). **Fanning out because the diagnostic passed is a FAIL. A canary that mutates the parent on its failure path is also a FAIL.** Repeat with an in-session `/settings` override, where no file changes at all. |
| **Worker without `blocking`** (CR-39) | Remove `blocking: true` from the Implementer; run `/orchestrated` with `async.enabled: true` (the default) | The barrier failure must be **detected, not absorbed**: L0/L1 fail the run before dispatch. If the run proceeds, integration receives `results: []` and MUST refuse rather than report a clean completion over zero integrated artifacts. **A successful-looking report with no work integrated is the worst outcome in the suite** — it is false completion produced by the orchestrator itself. |
| **`task.batch` disabled** (CR-39) | Set `task.batch: false`; run `/orchestrated` | Preflight detects the flat wire shape and routes to sequential non-isolated with disclosure — **not** a mid-run schema error after the model has already composed a `tasks[]` call. |
| **LSP granted but gated off at task.enableLsp** (CR-40) | Agents list `lsp`; `task.enableLsp` left at its `false` default | L0 fails on allowlist↔setting incoherence. At runtime, the workflow discloses reduced-capability mode **naming which condition failed**. **Silently substituting `grep` and reporting normal-quality retrieval is a FAIL** (§07 §A-1). |
| **LSP granted but gated off at lsp.enabled** (CR-41) | `task.enableLsp: true`, agents list `lsp`, but `lsp.enabled: false` in session settings | CR-40 check passes (task.enableLsp is true). The child tool list does NOT contain `lsp`. Workflow must disclose reduced-capability mode naming `lsp.enabled=false` as the specific cause — not `task.enableLsp` or allowlist. A disclosure reading "LSP unavailable" without naming `lsp.enabled` is a **FAIL** (T-00.E5 E5-F). |
| **Verifier bash disabled** (CR-43) | Set `bash.enabled: false`; run any workflow with a Verifier | The Verifier MUST NOT be dispatched and yield `decision: PASS` with fabricated command evidence. Required outcome: preflight refuses the verified workflow OR workflow explicitly marks result as `UNVERIFIED` with `bash_unavailable` stated as cause. A schema-valid `PASS` from a Verifier with zero effective `bash` calls is a **FAIL** (§10 §B-2). |

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
