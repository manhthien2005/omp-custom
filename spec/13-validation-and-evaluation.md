# 13 — Validation and Evaluation

<!-- round09-12-projection:evaluation -->
## Round 09–12 executable evaluation boundary (KD-032)

The default evaluator is deterministic and starts zero provider/model processes. It validates the
closed fixture manifest, task-cycle records, false-completion and security cases, unique token
accounting, hard gates, and the exact four promotion verdicts. Synthetic/adversarial records prove
the machinery only; they cannot promote a product candidate.

Campaign mode is a separate process boundary. It requires an explicit provider-call switch, a
positive evidence budget, an exact runtime path, and the frozen fixture manifest before any
process starts. Unavailable provider/quota/network/runtime input is recorded as
`ENVIRONMENT_BLOCKED` with `DEFER_INCONCLUSIVE`; no result is fabricated and no fallback lowers a
hard gate. A missing authorization or budget is `NOT_RUN`.

Three independent paired runs per arm remain a pilot minimum only. Pilot evidence may reject an
obvious hard-gate regression but cannot promote. Final promotion still requires the frozen,
sequentially valid procedure in §C-4/§C-5, measured/coherent ledgers and baselines, declared looks,
complete alpha allocation, and joint false-promotion probability `<= 0.05`. The only promotion
verdicts are `PROMOTE_EFFICIENCY`, `PROMOTE_QUALITY`, `REJECT`, and `DEFER_INCONCLUSIVE`; environment
status remains the separate `PASS | ENVIRONMENT_BLOCKED | NOT_RUN` field.

<!-- topic08-projection:behavior-core -->
## Topic 08 deterministic behavior slice

L0 calls the JavaScript behavior core, then checks exact roster/autoload, token budgets,
provenance, trigger pairs, lifecycle allowlist, mutation/observation boundaries, adapter fences,
component hashes, installer ownership, active documentation, and pinned OMP source ranges. The
mutation suite changes one load-bearing fact at a time and requires its named failure. L1 uses
OMP discovery to reconcile exact project skill paths/hashes and role autoload before dispatch.
Model-assisted trigger and pressure scoring remain unpromoted until Topic 11.

<!-- topic05-projection:validation -->
## Topic 05 four-arm evidence gate (KD-029)

Compare Lead/native (A), Lead/CodeGraph (B), Scout/native then Lead (C), and Scout/CodeGraph then
Lead (D) on identical source snapshots. B/D run cold then warm on the same prepared target; A/C
must not see the adapter, managed component, index, CodeGraph instructions, or `CODEGRAPH_*`
environment. Correctness, citation, identity, fallback, candidate/source, and contamination gates
precede efficiency. Provider usage is never estimated. A model pilot requires explicit spend
permission and exact confirmation; unavailable DeepSeek routes are `ENVIRONMENT_BLOCKED`, not
provider substitution. Results may recommend a source-fit task class, never a universal default
or invented percentage threshold.

## Topic 04 validation ladder (KD-028)

L0 validates state files, nonempty schemas, manifest hashes, protocol text, and PowerShell parsing.
L1 validates root selection, `pwsh` floor, installed component discovery, and the honest manual
adapter gate. L2 executes deterministic lifecycle/CAS/candidate/evidence/handoff/retention fixtures.
L3 exercises cross-session/worktree behavior; L4 binds fresh test/verification/review evidence to
the exact frozen candidate. Static checks never claim the automatic adapter is installed.

## Topic 07 continuity validation slice (KD-031)

L0 validates the closed continuity schema/profile, component hashes, command and authority
projections. L1 proves extension discovery, exact settings reassertion, persisted session/artifact
APIs, and source attachments at pinned OMP
`3a8591a8af5b6d200088d12ca75a5517cb064fa8`. L2 covers state CAS, kernel canonicalization,
artifact-first single-flight compaction, epoch settlement, one-shot injection, pressure abort,
bounded-child failure, install, and rollback without a provider. L4 uses a local in-process
provider sentinel: at pressure the counter remains zero; below pressure it becomes exactly one.
Promotion requires that stop-before-provider canary on both OMP 17.2.10 and 17.2.12. Missing local
17.2.10 is `OPEN-T07-RUNTIME-02` and leaves status `IMPLEMENTED_NOT_PROMOTED`; it does not trigger a
download, downgrade, provider call, or Opus requirement.

> OPUS PROPOSED SPEC v1 | Source-verified against `scripts/validate-template.ps1` and `scripts/benchmark.ps1`.
>
> **Topic 02 supersession boundary:** validation derives the project-worker set, structured
> result producers, skills, model aliases, and conditional execution capabilities from the
> Topic 03-selected runtime manifest. Former role names below are frozen-baseline defect or
> experiment labels, not roster authority. The three approved slash-command entry adapters
> remain the Topic 02 command surface.

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
- **CR-39 — `blocking: true` on every selected stage-barrier worker.** The Topic 03-selected
  topology manifest declares the worker set and which results are required before the parent
  may proceed. Every corresponding worker file MUST declare exact boolean `true`; `blocking`
  has no parser default (`discovery/helpers.ts:299`) and `async.enabled` defaults to `true`, so a
  missing key silently bypasses the declared barrier (§08 §C-1). A selected non-barrier helper
  is not forced blocking merely because it is a worker.
- **CR-40 — LSP allowlist ↔ setting coherence.** If any agent lists `lsp` in `tools:`, the
  template's project `config.yml` MUST set `task.enableLsp: true` (default is `false`). An
  allowlist that grants a tool the settings layer withholds is the round-1 defect inverted, and
  it is statically detectable.
- **CR-41 — `lsp.enabled` gate.** LSP is a four-condition conjunction; `lsp.enabled` (default
  `true`) is a separate settings key from `task.enableLsp`. An L0 check that covers CR-40 does
  not cover CR-41, because `lsp.enabled=false` with `task.enableLsp=true` satisfies the CR-40
  allowlist↔setting check while leaving LSP unavailable. Statically flag the contradiction when
  the template config sets `task.enableLsp: true` but also sets `lsp.enabled: false`.
- **KD-004 — selected schema lint.** L0 fully lints every selected structured-result schema
  before dispatch: parse/compile it, reject `$ref` or unrepresentable constructs, and verify that
  every required field is taught by the selected producer contract. Mere presence of an
  `output:` boundary is not a pass. A malformed schema that would make the runtime report
  `structuredOutput.status: unavailable` is a static failure.

### L1 — Discovery (new, highest value per effort)

Install into a scratch directory, then confirm **OMP itself** sees every component.
This is the layer that would have caught D-1 on day one.

Assertions:
- All three slash commands are discovered and invocable.
- The discovered project-worker set exactly matches the **Topic 03-selected topology manifest**:
  exactly `cheap-scout`, `worker`, and `reviewer`; every selected worker parses and appears with
  no `logger.warn` drop, and no unselected project worker appears accidentally.
- **CR-33 — `tech-lead` does NOT appear in the discovered agent list.** The Tech Lead is the main session (DR-1); the role-reference document lives at `docs/roles/tech-lead.md`, outside every agent discovery root. A discovered `tech-lead` agent is a **FAIL**, not a warning: `loadAgentsFromDir()` parses every `.md` under `.omp/agents/` as an active `AgentDefinition`, so its presence creates a second, spawnable Tech Lead path that contradicts the selected topology.
- The skill set declared by the selected runtime manifest is discovered; no fixed skill name
  or count is inferred from the former baseline.
- **CR-39 — `blocking === true` survives discovery for every selected stage-barrier worker.**
  L0 checks bytes; L1 checks the parsed `AgentDefinition`, because `task/index.ts:707` requires
  exact `=== true`. Non-barrier helpers remain governed by their Topic 03 contract.
- **CR-39 — effective `task.batch == true` when the conditional parallel path uses batch
  dispatch.** If Topic 03 does not select that path, L1 does not require batching. If it does,
  `false` must disable the path before dispatch rather than fail mid-run (§08 §C-1.4).
- **CR-40/CR-41 — effective LSP conjunction when selected.** If a selected worker lists `lsp`,
  confirm `task.enableLsp == true` and `lsp.enabled == true` after precedence. If no selected
  worker needs LSP, these settings are not topology requirements. A selected LSP-consuming path
  fails closed when its effective conjunction is unmet. A different contract that does not
  consume LSP must be explicitly selected, reconciled, and validated before continuation.
- **LSP server/outcome gate.** L1 rejects selected LSP acceptance when no applicable language
  server exists or any required LSP call returns details.success false. The four registration
  gates are necessary but do not cover `lsp/index.ts:2145-2160`, where no matching/configured
  server is returned as ordinary tool content. A representative probe covers selected file
  types, and acceptance checks each required call's `details.success` field.
- **CR-43 — effective command-execution capability when selected.** Any selected verification
  role whose contract requires fresh command execution must retain effective `bash`; a topology
  without such a role is not forced to invent one.
- **Selected retrieval-tool gates.** L1 checks effective glob.enabled, grep.enabled,
  astGrep.enabled, and web_search.enabled only for selected consumers. If a required tool is
  filtered out, the selected path stops before dispatch/acceptance or changes to a separately
  reconciled and validated contract.
- Every custom model-role alias actually referenced by the selected workers or commands resolves
  (§09). E2 requires missing/unknown aliases and an unavailable selected target to remain hard
  failures, and project values win. KD-027 separately validates the explicit Scout runtime retry
  chain: Flash `xhigh` primary, Pro `xhigh` only, then Tech Lead retrieval.
- **KD-010 — effective effort gate.** If any selected dispatch uses per-spawn `effort`, require
  effective `task.enableEffort == true`; otherwise the selected path stops before dispatch.
  L1 checks task.maxEffort against selected exact effort and verifies the returned resolvedModel
  effort suffix. This ceiling check is acceptance-bearing only when the selected manifest
  requires an exact effort rather than a best-effort hint.
- **KD-012/KD-027 — effective routing and selected-model identity.** Effective
  `retry.modelFallback` is true solely for the named Cheap Scout chain,
  `retry.usageAwareFallback` is false, and default/Worker/Reviewer chains are empty. L1 reconciles
  `task.agentModelOverrides`; Worker/Reviewer acceptance compares returned modelRole and
  resolvedModel with the expected identity. The exact comparison remains mandatory because
  credential fallback to the parent model is not marked by the fallback flag. Cheap Scout records
  the actual Flash/Pro path but owns no candidate acceptance.

Validator contract: Effective retry.modelFallback is true solely for the named Cheap Scout chain;
retry.usageAwareFallback is false; default/Worker/Reviewer chains are empty. L1 reconciles
task.agentModelOverrides; Worker/Reviewer acceptance compares returned modelRole and resolvedModel
with the expected identity.
- `.omp/AGENTS.md` and `.omp/RULES.md` load, with RULES.md forced `alwaysApply` (§11).
- **CR-31 — effective isolation settings for the conditional parallel path.** If Topic 03
  selects isolated parallel writers, read the effective post-precedence values and require
  `task.isolation.mode != "none"`; for a project target also require
  `task.isolation.apply == false`. If that path is not selected, these values do not define
  Orchestrated and are not global acceptance requirements. The runtime preflight remains
  mandatory whenever the path is attempted (§08 §E-9).
- **Selected nested-delegation depth.** Selected nested delegation must have remaining
  task.maxRecursionDepth; stripped task capability cannot satisfy acceptance. L1 validates the
  deepest selected edge against the effective setting before dispatch.

A component that OMP cannot see is broken regardless of how well-formed its file is. A component OMP *can* see but the architecture does not want is equally broken.

The selected effort fixtures require Cheap Scout `xhigh` mapped to DeepSeek `max`, Worker default
`high`, hard-task Worker `xhigh`, and Reviewer fixed `xhigh`. The review fixture requires General
Reviewer for security, authentication, durable data, database migration, concurrency, public API,
and destructive change concerns; unavailable Opus exercises the approved cross-family/strong-model/
same-model-separate-session fallback ladder rather than blocking universally.

### L2 — Contract (new)

Exercise the structured-output path (§06) without judging code quality:
- A `task` call with an inline `outputSchema` returns a schema-valid object.
- A deliberately malformed yield is rejected, and the retry ladder engages (§06 §D).
- A deliberately malformed selected schema fails L0 before dispatch; if injected below L0, its
  `structuredOutput.status: unavailable` result cannot satisfy acceptance.
- A selected completion-result contract claiming `status: completed` with missing required
  verification evidence is rejected by its schema, not merely discouraged by prose.

Acceptance requires structuredOutput.status valid. `unavailable`, `invalid`, and
`schemaOverridden` results are unvalidated even if their prose and fields look complete.

### L3 — Behavioral (new, the real measure)

Run the ten fixture tasks from the plan end-to-end and measure outcomes. This is the only
level that can answer "is the workflow better than no workflow".

### L4 — Adversarial (new)

Test the failure modes the design claims to prevent. These cases must be fully deterministic
(no model-grading): a candidate author that reports false success, an environment failure, a
non-git-repo isolation dispatch when that optional path is selected, a schema-violating result,
and conflicting parallel patches when parallel writers are selected. The selected non-author
verification mechanism must detect or contradict false success when the accepted contract
requires independence. Each case must produce a specified detection response. L4 also covers
A/B comparison runs where a single variable is isolated and results are compared statistically
(see §C).

Add two false-completion cases from the runtime boundary. L4 forces a softRequestBudget partial
yield and proves that it cannot satisfy completion. It also runs a selected mutation/fresh-command
worker while the parent is in plan mode: plan mode cannot satisfy a selected mutation or
fresh-command contract, and L4 proves that a plausible read-only yield is rejected. Continuation
requires a distinct planning-only contract or an explicit transition out of plan mode followed by
contract reconciliation and fresh validation.

For external freshness, web_unavailable leaves a freshness contract unresolved and unable to
satisfy acceptance without authoritative evidence. L4 disables `web_search.enabled` beneath a
selected freshness consumer and proves a plausible memory-based answer is rejected.

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
| **Selected verification producer fabricates evidence** (CR-35) | Drive the selected command-executing verification role, if any, to make **zero** `bash` calls and yield a schema-valid `PASS` with invented `commands_run`, `exit_code: 0`, and per-criterion `evidence` strings | The yield **succeeds** — `buildOutputValidator()` does pure JSON Schema validation with no tool-event correlation (`tools/output-schema-validator.ts`). This is the **expected** outcome and must be recorded as such. The fixture's assertion is on the *spec*, not the runtime: `spec/10 §B-1` and phase-04 T-04.1 MUST describe verification as shape-enforced and behaviorally-required, never as provenance-attested. **A spec claiming schema fields "cannot be satisfied without real command output" while this fixture passes is a FAIL.** |
| **Transcript audit detects the fabrication** (CR-35, T-04.8) | Same selected-worker fixture; Tech Lead then reads `history://<worker-id>` | The transcript renders one line per tool call with name and arguments (`session/session-history-format.ts`), so a selected worker with zero `bash` calls is distinguishable from one that ran the claimed commands. Records whether the audit is deterministic enough to gate on. Gates any future stronger claim. |
| **Deterministic pre-existing failure** (CR-36) | Baseline contains a deterministic failing test in a subsystem the diff does not touch; implemented change is clean; the selected verification path runs the full suite | Classification is `preexisting` with baseline evidence, and the remediation owner is **not** dispatched. **Classifying as `impl` is a FAIL** — it sends an author to modify out-of-scope code, the exact expensive error the taxonomy exists to prevent (§10 §B). |

**CR-38/CR-39/CR-40/CR-41/CR-42/CR-43 — required additional L4 cases.** All are silent-failure classes at the
OMP task boundary, which is what L4 exists for:

| Case | Setup | Required detection response |
|---|---|---|
| **Parent overlay defeats the settings read** (CR-38/CR-42/CR-44) | Project config `apply: false`; launch the OMP-owned default main-CLI root-session construction class with `--config` setting `apply: true`; run the Phase-00 characterization scope | Subprocess `omp config get` reports `false` (a false pass on its own). E3-L must establish the scoped `pi.pi.settings.get("task.isolation.apply")` reader; the earlier project custom-tool `ctx.settings` claim is invalid on pinned v17.2.10 because `sdk.ts:885-894,938-955` omits settings from that bridge. The reader claim excludes ACP, injected SDK/settings-manager/dependency hosts, clones, RPC, and RPC-UI. **Until E3-L and E3-M pass, parallel mode is DISABLED** — behavioral canary (E3-I) is characterization/diagnostic only and does NOT authorize parallel. **Fanning out on behavioral-canary PASS alone is a FAIL. A canary that directly mutates the parent is also a FAIL.** Repeat the reader test with project config, CLI overlay, and a non-persistent `Settings.override("task.isolation.apply", true)` runtime change. |
| **Selected stage-barrier worker without `blocking`** (CR-39) | Remove `blocking: true` from one selected worker whose result gates integration/review/report; run with `async.enabled: true` (the default) | The barrier failure must be **detected, not absorbed**: L0/L1 fail the run before dispatch. If the run proceeds, the consumer receives no result and MUST refuse rather than report clean completion. **A successful-looking report with no required evidence is the worst outcome in the suite** — false completion produced by the orchestrator itself. |
| **`task.batch` disabled on selected parallel path** (CR-39) | Set `task.batch: false`; select the conditional parallel-batch path | Preflight detects the flat wire shape and routes to sequential execution with disclosure while retaining structural Orchestrated classification — **not** a mid-run schema error after composing a `tasks[]` call. |
| **LSP granted but gated off at task.enableLsp** (CR-40) | A selected LSP-consuming role lists `lsp`; `task.enableLsp` remains at its `false` default | L0 fails on allowlist↔setting incoherence for that selected role, and runtime preflight refuses that path before dispatch. The failure names `task.enableLsp=false`. Continuing the same contract with `grep`, disclosed or not, is a **FAIL** (§07 §A-1). A topology with no LSP consumer does not run this fixture. |
| **LSP granted but gated off at lsp.enabled** (CR-41) | `task.enableLsp: true`, a selected consumer lists `lsp`, but `lsp.enabled: false` in session settings | CR-40 check passes, but CR-41/runtime preflight fails and the selected path is not dispatched or accepted. The failure names `lsp.enabled=false`, not `task.enableLsp` or allowlist. A generic "LSP unavailable" response or continuation under the same contract is a **FAIL** (T-00.E5 E5-F). |
| **LSP registered but no applicable server** | All four registration gates pass; select symbol-aware work for a file with no matching/configured language server | The required call returns `details.success: false` (`lsp/index.ts:2145-2160`) and L4 rejects the selected LSP result. Continuing the same contract with `grep` or accepting a later schema-valid yield is a **FAIL**; only remediation or an explicit reconciled/revalidated non-LSP contract may continue. |
| **Selected verification command capability disabled** (CR-43) | Set `bash.enabled: false`; select a verification role whose contract requires fresh command execution | The selected role MUST NOT be dispatched and yield `decision: PASS` with fabricated command evidence. Required outcome: preflight refuses that verified path OR explicitly marks the result `UNVERIFIED` with `bash_unavailable` stated as cause. A schema-valid `PASS` with zero effective `bash` calls is a **FAIL** (§10 §B-2). A topology with no command-executing verification role is not forced to invent one. |

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
3. Capture main-session message usage, unique per-spawn `SingleResult` usage and role metadata,
   tool calls, agents spawned, retries, handoffs, compactions, and wall time. Aggregated `task`
   usage MUST NOT be added again after its individual child results have been counted.
4. Run the fixture's own deterministic acceptance check — its test command or oracle.
5. Record one immutable YAML task-cycle result per run, including failures, crashes, timeouts,
   and unavailable metrics.
6. Support paired A/B runs on the same fixture with exactly one differing variable.
7. Freeze and record the baseline and environment identities before either arm runs.

### C-1. Validated accepted-outcome contract

`accepted_outcome` is not a worker self-report and is not shorthand for “the user tolerated
the result.” The harness sets `validated_accepted_outcome: true` only when all five conditions
are present in the terminal record:

1. `objective_status: complete`;
2. every mandatory acceptance-criterion ID has authoritative `PASS` evidence, with no `SKIP`
   or coverage gap;
3. every verification and review gate required by the task contract is clear;
4. `blocking_issues` is empty, including unresolved authority and scope issues;
5. `tech_lead_acceptance: accepted` is recorded after the evidence above.

Lifecycle outcomes and evaluation classifications are separate:

```yaml
lifecycle_terminal_outcome:
  one_of:
    - accepted
    - cancelled
    - terminally_blocked
nonterminal_observation:
  one_of:
    - partial
    - blocked
    - waiting_for_user
    - rework
    - null
evaluation_classification:
  one_of:
    - validated_accepted
    - accepted_with_waiver
    - non_accepted
```

Only `validated_accepted` contributes to the benchmark denominator.
`accepted_with_waiver` remains excluded from the validated denominator, is recorded with its
rationale, and cannot satisfy a promotion gate. A waiver of a mandatory criterion changes the
contract; it cannot relabel the old candidate as accepted.

Acceptance evidence binds to an immutable candidate snapshot identified in the run record.
Any acceptance-bearing mutation after freeze invalidates that evidence and requires a new
candidate before another acceptance decision.

### C-2. Full task-cycle accounting and metrics

The task cycle starts when the task contract is accepted and ends only at `accepted`,
`cancelled`, or `terminally_blocked`. It includes initial and repeated retrieval, rejected
candidates, schema/provider/workflow retries, verification and review rework, attributable
handoff or compaction, and fallback after Scout failure. A new task contract creates a new
cycle. Failed and rejected cycles remain in the aggregate numerator.

Every run records at least:

```yaml
task_cycle:
  task_cycle_id: string
  task_contract_hash: sha256
  candidate_id: string
  candidate_snapshot_hash: sha256
  lifecycle_terminal_outcome: accepted | cancelled | terminally_blocked | null
  nonterminal_observation: partial | blocked | waiting_for_user | rework | null
  evaluation_classification: validated_accepted | accepted_with_waiver | non_accepted
  validated_accepted_outcome: boolean
  acceptance_criteria_coverage: complete | gap
  false_completion: boolean
  failure_class: none | quality | provider | environment | timeout | contract | cancelled

tokens:
  core_workflow_tokens: integer | not_measured
  cheap_scout_tokens: integer | not_measured
  raw_total_tokens: integer | not_measured
  cache_read_tokens: integer | not_measured
  missing_token_classes: []

operations:
  retries: integer
  rework_loops: integer
  tool_calls: integer
  wall_time_ms: integer
```

All three primary ledgers use the same observed accounting basis: input + output + cache-write
tokens, excluding cache-read because cumulative cache reads repeatedly charge the same cached
context. Cache-read remains separate telemetry. Main-session usage is taken from authoritative
assistant-message usage; each child is counted once from its `SingleResult.usage` breakdown and
attributed by role. The display-oriented `SingleResult.tokens` field is not sufficient for
promotion: when a provider omits the breakdown, OMP falls back to `totalTokens`, which may
include cacheRead (`packages/coding-agent/src/task/executor.ts:759-782`). Such a run is
`not_measured`, not estimated. `cheap_scout_tokens` contains only configured read-only Cheap
Scout runs.
`core_workflow_tokens` contains the Tech Lead and every non-Scout worker/reviewer activity.
`raw_total_tokens = core_workflow_tokens + cheap_scout_tokens`.

`AgentSession.getSessionStats()` and JSON print-mode messages expose the runtime usage fields
(`packages/coding-agent/src/session/session-stats.ts:52-110`,
`packages/coding-agent/src/modes/print-mode.ts:58-83,191-194`); the harness must reconcile
them without double counting. If the main-session portion, a child role, or the token basis
cannot be established, the affected ledger is `not_measured` and the run cannot support
promotion. No transcript-length or `chars / 4` estimate is allowed.

The primary efficiency metric is computed across whole task cycles:

```text
sum(core_workflow_tokens for every attempted cycle, including failures)
-----------------------------------------------------------------------
count(validated accepted outcomes)
```

Zero validated accepted outcomes means infinite cost. `cheap_scout_tokens` are telemetry only;
they do not gate routing or promotion. `raw_total_tokens`, provider cost, quota usage, cache
reads, and model identity are observational diagnostics. No model weighting is applied.

The primary quality measure is validated accepted-outcome rate. False completion is a hard
safety gate. Deterministic diagnostics include test pass rate, acceptance-criteria coverage,
correct-file localization, unnecessary diff size, retry/rework counts, and failure class.
Model-graded plan coherence, maintainability, review usefulness, and requirement alignment are
advisory only.

Wall time, provider waits, and timeouts are telemetry, not optimization terms. A timeout,
deadlock, or unbounded wait is a reliability failure. An explicit user deadline becomes a task
constraint; otherwise latency is used only as the final tie-breaker after equivalent quality
and core-token efficiency.

### C-3. Frozen dual baselines

The two baselines are not interchangeable:

| Baseline | Use | Advancement |
|---|---|---|
| `stable_product_baseline` | Every candidate mechanism or optimization | Advances only after a validated promotion and records the superseded identity |
| `pinned_plain_omp_runtime_baseline` | Release and major architecture checkpoints | Changes only through an explicit runtime-pin decision |

Every baseline identity records `baseline_id`, `omp_binary_sha`, `template_artifact_sha` (or
`absent` for plain OMP), `fixture_version`, `provider`, `gateway_version`, `model_role_map`,
`reasoning_level`, `timeout_policy`, `retry_policy`, `cache_policy`, and `tool_environment`.
The two arms must match on every controlled field. A mismatch invalidates the comparison.
Baselines never move silently.

Candidate promotion is decided against `stable_product_baseline`. At release and major
architecture checkpoints, the promoted template must additionally clear the same hard gates
and one of the two evidence paths below against `pinned_plain_omp_runtime_baseline`; otherwise
PR-7 remains not ready.

The plain-OMP arm is evaluated by the same external task objective and deterministic outcome
oracle, not by template-internal mechanism requirements it cannot possess. Template-specific
L0-L2 discovery/contract fixtures remain hard gates on the template candidate; the paired
plain-OMP value comparison uses baseline-compatible behavioral/adversarial tasks.

### C-4. CR-22 — Formal paired A/B protocol

Every comparison MUST:

1. isolate exactly one variable;
2. run both arms on identical fixture tasks with fresh, independent state per run, unless the
   tested variable explicitly concerns within-session behavior;
3. randomize or counterbalance arm ordering;
4. freeze the task contract, baselines, thresholds, sequential inference method, stopping
   rule, familywise error allocation, look schedule (when finite), and evidence budget before
   final sampling;
5. record both arms before interpreting either;
6. report per-fixture paired deltas plus the aggregate, failure rate, and the promotion-bearing
   sequential bounds; nominal 95% paired/bootstrap intervals may be supplemental only;
7. capture the reproducibility metadata in §C-3 for every run.

At least three independent paired runs per arm are required for a pilot. Pilot evidence may
reject an obvious regression but MUST NOT produce a promotion verdict. Pilot observations are
excluded from final promotion inference unless the sequential procedure was frozen before the
first pilot look and includes them as that procedure's first look.

Adaptive final sampling MUST use either an anytime-valid paired confidence sequence, a finite
look schedule with explicit alpha spending/multiplicity adjustment, or an equivalent joint
sequential construction. Across all interim looks, both promotion paths, and every
promotion-bearing bound, the procedure MUST control the probability of any false promotion at
`<= 0.05` (at least 95% simultaneous confidence). Merely predeclaring repeated nominal 95%
paired/bootstrap intervals does not satisfy this rule. Continue until a sequentially valid
promotion condition, the predeclared rejection/futility condition, or the evidence budget is
reached. Budget exhaustion without decisive valid bounds yields `DEFER_INCONCLUSIVE` or
`REJECT`, never promotion.

### C-5. Promotion gate

Hard gates run first:

- all deterministic required operational and adversarial gate fixtures pass;
- acceptance-criteria coverage is complete;
- new false completions equal zero;
- blocking or critical correctness/security regressions equal zero;
- the observed validated accepted-outcome rate is not below baseline;
- all required ledgers and baseline identities are measured and coherent.

After the hard gates, exactly two promotion paths are valid:

Every confidence bound below is a promotion-bearing bound from the joint sequential procedure
in §C-4. “95%” refers to its at-least-95% overall false-promotion control, not to an ordinary
95% interval recomputed independently at each look.

**Efficiency win (`PROMOTE_EFFICIENCY`)**

- observed accepted-outcome-rate delta is `>= 0`;
- the sequentially valid one-sided lower promotion bound on that delta is `>= -0.05`;
- observed core workflow tokens per validated accepted outcome improve by at least 10%;
- the sequentially valid paired promotion bound excludes no token improvement.

**Quality win (`PROMOTE_QUALITY`)**

- the sequentially valid one-sided lower promotion bound on accepted-outcome-rate delta is
  `> 0`;
- the sequentially valid paired upper promotion bound keeps core workflow tokens per validated
  accepted outcome at no more than `1.10x` baseline.

Higher-risk campaigns may predeclare stricter thresholds. Thresholds cannot be loosened after
final sampling begins. Results that clear neither path are `REJECT` or
`DEFER_INCONCLUSIVE`. `accepted_with_waiver` is reported separately and never converted into a
validated promotion.

### C-6. Required comparison matrix

| Comparison | Question it answers | Baseline type |
|---|---|---|
| Plain pinned OMP vs promoted template | Does the product add validated value? | Runtime/release |
| Last promoted template vs candidate | Does this candidate deserve promotion? | Stable product |
| Quick vs Standard on the same task | Is the heavier workflow worth it? | Mechanism A/B |
| One worker vs several | Does fan-out pay for its overhead? | Mechanism A/B |
| Reviewer on vs off | Does review catch real defects? | Mechanism A/B |
| Compact vs bloated task packet | Does packet discipline matter? | Mechanism A/B |
| `autoloadSkills` on vs off | Does forced skill injection change outcomes? | Mechanism A/B |
| High effort everywhere vs only where needed | Is selective effort as good and cheaper? | Mechanism A/B |

Each comparison isolates one variable; anything else confounds the result.

---

## D. False-Completion Detection

The template's central claim is "no false completion". It must be measured, not asserted.

A run is a **false completion** when the agent reports success and the fixture's own
acceptance check fails. This is fully deterministic and needs no grader.

False completion is a hard safety gate. A workflow that lowers token cost while introducing
one is rejected before efficiency is considered. Validated accepted-outcome rate remains the
primary quality measure because it also counts honest failures and incomplete work that do not
pretend to be complete.

---

## E. Honest Reporting

The plan requires that failed evaluations not be hidden. Therefore:

- Every run is recorded, including crashes and timeouts.
- Result files are immutable; a re-run creates a new record.
- Aggregates state the run count and variance, never a single cherry-picked run.
- Failed and rejected task cycles remain in the core-token numerator.
- `accepted_with_waiver` is reported separately from validated acceptance and promotion.
- Baseline identities and any supersession are reported explicitly.
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
| AC-8 | Benchmark token counts come from runtime/provider usage telemetry, not transcript length or `chars / 4`; static prompt budgets continue to use a real tokenizer |
| AC-9 | At least one A/B comparison is executed and reported with variance |
| AC-10 | Failed and crashed runs appear in the report |
| AC-11 | The harness computes `validated_accepted_outcome` from all five contract conditions and excludes `accepted_with_waiver` from its denominator |
| AC-12 | Full task-cycle accounting retains failed/rejected cycles and reports coherent `core_workflow_tokens`, `cheap_scout_tokens`, and `raw_total_tokens` without double counting |
| AC-13 | Candidate and release comparisons carry frozen `stable_product_baseline` and `pinned_plain_omp_runtime_baseline` identities with recorded supersession |
| AC-14 | Three runs per arm can produce only pilot rejection/smoke evidence, never a promotion verdict |
| AC-15 | Final evaluation emits `PROMOTE_EFFICIENCY`, `PROMOTE_QUALITY`, `REJECT`, or `DEFER_INCONCLUSIVE` from a predeclared sequential procedure with at least 95% joint false-promotion control |
| AC-16 | Latency is reported as telemetry; timeout/deadlock is a reliability failure and cannot be averaged into a quality/token composite |
| AC-17 | Adaptive-look fixtures reject nominal per-look intervals, undeclared looks, missing/exhausted alpha allocation, and pilot reuse outside the frozen sequential procedure |

---

## G. Topic 06 validation slice

Topic 06 adds a model-free deterministic gate before provider evaluation. It validates contract
schema/core/CLI behavior, Topic 04 projection and compare-and-swap, all three role outputs, native
same-name delegation, exact model/effort identity, the 200/300 soft-budget boundary, plan-mode and
async/nested refusal, Reviewer claim exclusion, batch independence, transactional install/
rollback, managed/unmanaged output separation, and evidence-manifest hashes.

Installed OMP probes must show the wrapper loaded last and delegated to the native `task`; they do
not call a provider. An `agent_boundary_receipt` remains provisional and cannot satisfy the five
parent acceptance conditions by itself. Missing universal coverage for unrelated Vibe/`eval`/
internal-agent facilities is recorded as nonblocking `OPEN-T06-RUNTIME-01`, not hidden as success.

---

## H. Topic 07 validation slice

Topic 07's deterministic gate separately rejects command arguments, unarmed/in-memory/busy or
ambiguous sessions, stale revision/branch/lease bindings, artifact write/read/hash failure,
unauthorized native compact calls, malformed preserve data, repeated kernel injection, settings
drift that cannot be reasserted, provider dispatch at pressure, plausible child success after a
pressure abort, and any hidden continuation/retry. Quick degradation is accepted only for an
explicitly absent named secondary field; Standard and Orchestrated accept none.

The final evidence must record the exact source-range hashes, test commands and assertion counts,
provider counter, supported runtime matrix, local/no-Git execution, and promotion status. A pass
on one runtime proves that runtime only; it cannot close the two-version promotion gate.
