# Codex → Opus 5 — Topic 01 Optimization Metrics Change Ledger

> **Project:** `omp-template`
>
> **Scope:** Topic 01 — optimization objective and metrics
>
> **Authority:** explicit user decisions on 2026-08-12
>
> **Requested review:** read-only, adversarial, evidence-backed
>
> **Repository baseline:** branch `main`, HEAD
> `62fecf277dc9d5e47d06319387eac747462214c1`
>
> **OMP source authority:** clean pinned source at
> `3a8591a8af5b6d200088d12ca75a5517cb064fa8` (17.2.10)

## 1. Decision under review

The user approved this priority order:

1. clear mandatory deterministic quality gates;
2. maximize validated accepted-outcome rate;
3. minimize `core_workflow_tokens / validated_accepted_outcomes`;
4. use latency only as a final tie-breaker.

The approved contract also fixes:

- five conditions for a validated accepted outcome;
- `accepted_with_waiver` as a separate non-validated state;
- a full task-cycle accounting boundary that retains failures and rework;
- three unweighted ledgers: `core_workflow_tokens` (optimization),
  `cheap_scout_tokens` (telemetry), and `raw_total_tokens` (observation);
- no model-price weights, premium-token equivalents, Scout quota, or latency composite;
- Tech Lead discretion to use a configurable read-only Cheap Scout, with fail-soft fallback
  and critical-evidence recheck;
- a frozen last-promoted-template baseline for candidates and a pinned plain-OMP baseline for
  release/major-architecture checkpoints;
- hard gates followed by either an efficiency-win or quality-win promotion path;
- at least three paired runs per arm as pilot-only evidence, with adaptive final evidence at
  95% confidence;
- five-percentage-point quality non-inferiority uncertainty, at least 10% core-token
  improvement for an efficiency win, and at most 10% core-token regression for a quality win.

The approved design record is
`docs/superpowers/specs/2026-08-12-topic-01-optimization-metrics-design.md`.

## 2. Old semantics → new semantics

| Concern | Old active semantics | New active semantics |
|---|---|---|
| Objective | `total_tokens / accepted_outcomes`, constrained mainly by false-completion rate | Lexicographic quality gates → validated acceptance rate → core-token efficiency → latency tie-breaker |
| Accepted outcome | Outcome that passed verification/review; some projections implied user acceptance | Five evidence conditions plus Tech Lead terminal acceptance; waiver and honest non-accepted states excluded |
| Accounting boundary | “All agents and retries,” with no task-cycle boundary | Accepted task contract through final/terminal state, including failed candidates, retrieval, retries, rework, handoff, compaction, and fallbacks |
| Model economics | Undecided raw-vs-weighted total | No weights; expensive core ledger optimized, Cheap Scout recorded as telemetry, raw total observational |
| Cheap Scout | Unspecified in Topic 01 | Optional configured cheap retrieval role; read-only; no Scout token gate; fail-soft to the Lead's needed path |
| Latency | Recorded but objective status unclear | Telemetry only; reliability failure for timeout/deadlock; final tie-breaker unless user declares a deadline |
| Baseline | Plain OMP only | Stable promoted template for candidates plus pinned plain OMP for release/value checks |
| A/B pilot | Three runs/arm could satisfy generic variance reporting | Three paired runs/arm may reject obvious regressions but cannot promote |
| Promotion | “Quality neutral-or-better at equal-or-lower tokens” | Hard gates plus `PROMOTE_EFFICIENCY` or `PROMOTE_QUALITY`; otherwise reject/defer |
| Telemetry source | KD-012 treated per-spawn `SingleResult` as the complete accounting surface | Main/Tech Lead assistant-message usage plus unique per-spawn usage, reconciled without double counting |

## 3. Source-backed telemetry correction

Topic 01 exposed two source-level limitations in the previous metric prose:

1. `AgentSession.getSessionStats()` aggregates both main assistant messages and `task` tool
   result usage (`packages/coding-agent/src/session/session-stats.ts:52-110`). Adding that total
   to individual child results would double count. JSON print mode emits authoritative
   `message_end` and `agent_end` messages with usage
   (`packages/coding-agent/src/modes/print-mode.ts:47-83,191-194`), so Phase 06 can derive main
   usage separately and reconcile unique children.
2. `SingleResult.tokens` is documented as input + output + cacheWrite excluding cacheRead
   (`packages/coding-agent/src/task/types.ts:471-510`), but `getUsageTokens()` falls back to a
   provider's `totalTokens` when the breakdown is missing and explicitly notes that the
   fallback may include cacheRead (`packages/coding-agent/src/task/executor.ts:759-782`). The
   promotion contract therefore requires the explicit `usage` breakdown; fallback-only runs
   are `not_measured` and cannot promote.

KD-012 is marked superseded only in aggregation scope. Its runtime-telemetry authority and
prohibition on transcript-length/`chars / 4` estimation remain active. KD-024 records the new
user-approved decision.

## 4. Authority and projection map

| Layer | File | Topic 01 responsibility |
|---|---|---|
| Design record | `docs/superpowers/specs/2026-08-12-topic-01-optimization-metrics-design.md` | User-approved contract and scope boundary |
| Decision authority | `spec/key/03-token-quality-model.md` | Objective, outcome, ledgers, Scout, latency, baselines, promotion |
| Immutable decision log | `spec/key/04-decision-log.md` | KD-024; partial supersession annotation on KD-012 |
| Executable evaluation authority | `spec/13-validation-and-evaluation.md` | Task-cycle schema, telemetry rules, A/B, thresholds, verdicts, AC-11…AC-16 |
| Decision projections | `spec/key/01-dna.md`, `spec/key/05-coverage-audit.md`, `spec/key/06-investment-thesis.md`, `spec/key/README.md` | Consistent terminology and experiment references |
| Main spec projections | `spec/05-context-and-token-model.md`, `spec/07-retrieval-and-code-understanding.md`, `spec/README.md` | Concise metric/retrieval/PR-7 semantics |
| Human documentation | `docs/token-strategy.md` | Concise public explanation without duplicating thresholds |
| Phase plan | `spec/phases/phase-03-context-efficiency.md` | Calibration only; cannot promote |
| Phase plan | `spec/phases/phase-06-evaluation.md` | Future harness, dual baselines, accounting, and promotion implementation |
| Phase plan | `spec/phases/phase-07-stabilization.md` | References canonical PR-7 instead of paraphrasing it |
| Process | `docs/superpowers/plans/2026-08-12-topic-01-optimization-metrics-plan.md` | Main-Agent inline implementation and verification plan |
| Product changelog | `CHANGELOG.md` | Short non-runtime Topic 01 delta |

The Phase DAG remains Phase 03/04/05 → Phase 06 → Phase 07. Phase 00 authority and parallel
mode are unchanged.

## 5. Frozen file ledger

“Before” is the exact file state immediately before Topic 01 patching, not necessarily HEAD;
this matters because `spec/13`, `docs/token-strategy.md`, and `CHANGELOG.md` already contained
user changes. `spec/07` and `spec/key/05` were clean, so their before value is the exact HEAD
blob. Hashes are SHA-256.

| File | Before | Frozen after |
|---|---|---|
| `spec/key/03-token-quality-model.md` | `7545155E05313B6BF275A3B5CFAD3C1B0288C965F0D3EF3DEECD7BB256ACEEDB` | `F83A471CD01377BBE24F98679359B8D86354AEDE87941130D8167D2E1E186D27` |
| `spec/key/04-decision-log.md` | `CDF3A957F2B2217873F83F5923F4A95733355EEEF8C985BE0E09FABFB5063275` | `D1A99C8C0094837A8FBBBAD773EC6CFAAB168D4306C1B9D5CED4F9CBD72C5AE2` |
| `spec/13-validation-and-evaluation.md` | `43A66F3BB9826B7AD62ACA820BF45761825B4D10840A9FFED72C4851B4F81864` | `F92E031ED121297BC34A4365659C37A3F644E713342470540DC6A799A7347DEA` |
| `spec/key/01-dna.md` | `AB19A186397358C0643EA5D6D318D77053DBF8C66415233F674B64E47C878C36` | `C41E82F8CEB5B6A7643C4702F227FE289A51CBBC98824259CF6F3F0F412B1AA1` |
| `spec/key/05-coverage-audit.md` | `B3A8A2C054B09D36454F9D4809D32D78AD1B0E61F5B865FB0C0F7F6167B7E63C` | `99A181C9E984B06F5AD0DD85FA90AF752B340BD2CB7D12725EAEA2C5F10F15AA` |
| `spec/key/06-investment-thesis.md` | `826A62896254159B337CC4A0B09C25D7F6D340984C46E17B2F7CCE590EDCD770` | `54226AC403141CA98B553BA59C722E5E1560A5E825913474759FF4CF6D5C761C` |
| `spec/key/README.md` | `0A2F0660D9F41D4DE2F59C17B3F9FAD3FA4D561579EE9FA652B4FCB2829362C4` | `1E6CF1D9B76BA5A498ECEC8587ED6DF73F765CA066D239A849FD1B56640247D7` |
| `spec/05-context-and-token-model.md` | `832E1F46BF7C474A541D01F0E09C3AE3006F52D4D2A0BE0E7275AEC32F9FD74D` | `D487EB1267749DF3E54BD6A18CCFC87F864569A76780810D2C4E334486755478` |
| `spec/07-retrieval-and-code-understanding.md` | `BD52C5C65FE3557BF242704B9B682439C9AF9F542D0964923D52A8796EF0D016` | `BF716322713AB83103F477DA97360FF0F14667F83B94A3B3664F70D23F6F9017` |
| `spec/README.md` | `8AC3CE0A575E36A9E6C9EDD79F128F3885B9B71147917D6F5CBEEB644C379106` | `5E003BC77BC178A78FA9FB4C106443AD2014EE66D7E50059DA1B46E85F357663` |
| `docs/token-strategy.md` | `F02F2C9F69AF5DD5C63F5C267B372AAC9408E096E0E81F18A0E88670F88B9747` | `68D2CE31E7C2F57CD2A7FDEC76A4994369CC4D6359A6F442FB7B77616D49EEEB` |
| `spec/phases/phase-03-context-efficiency.md` | `BB5D135B747CB4FAB465063AB479C9B4423BE53E45DD5E50B556EDB7AE2555C5` | `F8FD4988D9C13B690BEF38BE12E856D7AB2F485D3597153FF828338628D2BBB4` |
| `spec/phases/phase-06-evaluation.md` | `E0805435AB6383736295332BEF9786C9F46F8F9C717F5459F47CCD440632BAD3` | `3682FF448A23F81EF951229FA4AE1075BD7AF451AD89EC3221FC66F431F46E28` |
| `spec/phases/phase-07-stabilization.md` | `C1F79551B348FD5480465DBE36A2FE8B28217795D7A7684AC5B48FB0634F41A4` | `D43A3858D638639EE2B332AF60BA4B0FCA70B4834AD411271ACD050AF8591E8C` |
| `docs/superpowers/specs/2026-08-12-topic-01-optimization-metrics-design.md` | absent | `D4505E510A66D5746A88AAE53BDDDF017DC7B0D0FCECAA811656D939B684FCF3` |
| `CHANGELOG.md` | `09D79C80ABF3AD8798830F90AF9E214A9FE3A199732613B98DE24A5AD46F29B0` | `718932BCEADB64E8F8ACD0264317CDDEA61D46F2F099ADC35D1319A572CE169D` |

The implementation plan is a mutable execution tracker and is intentionally excluded from the
frozen semantic ledger. No historical audit packet was edited.

## 6. Validation evidence

### Required-semantics scan

```powershell
rg -n "core_workflow_tokens|cheap_scout_tokens|raw_total_tokens|accepted_with_waiver|stable_product_baseline|pinned_plain_omp_runtime_baseline|PROMOTE_EFFICIENCY|PROMOTE_QUALITY" `
  spec/key/03-token-quality-model.md spec/13-validation-and-evaluation.md `
  spec/phases/phase-06-evaluation.md
```

Result: exit 0; every required term appears in decision authority, executable evaluation
authority, and the Phase 06 implementation projection.

### Superseded-semantics scan

```powershell
rg -n -i "quality neutral-or-better at equal-or-lower|back-to-back or in the same session|did the user accept it|headline quality metric" `
  spec docs/token-strategy.md `
  --glob '!spec/key/repos/**' --glob '!spec/key/dossiers/**' `
  --glob '!docs/research/**' --glob '!docs/evidence/**' --glob '!docs/superpowers/**'
```

Result: no matches. Historical KD prose retains the old phrase only beside an explicit KD-024
supersession annotation.

### Markdown structure

All 16 Topic 01 Markdown targets were scanned for triple-backtick fences. Every target has an
even fence count; no unclosed fenced block was found.

### Diff hygiene

```powershell
git diff --check
```

Result: exit 0, no whitespace error. Git emitted one line-ending notice for pre-existing
`spec/phases/phase-00-foundation.md`; Topic 01 did not edit that file.

### Existing repository validator

```powershell
pwsh -NoProfile -File scripts/validate-template.ps1
```

Result: exit 0 — `102 passed, 1 warnings, 0 failed`. The warning is the existing advisory
`template/.omp/RULES.md` approximate budget below target (`226 < 300`). This is static
structural evidence only; it does not prove the future Phase 06 harness or promotion gate runs.

## 7. Explicit non-claims and exclusions

- No benchmark harness, statistical routine, schema, fixture, template prompt, runtime file,
  installer, hook, MCP integration, or model route was implemented in Topic 01.
- No candidate was benchmarked or promoted.
- Cheap Scout was not deployed and no provider/model ID was hardcoded.
- No claim is made that OMP 17.2.12 source matches the pinned 17.2.10 source. Source mechanisms
  in this ledger are scoped to pinned commit `3a8591a`.
- No Phase 00 state, phase dependency edge, parallel-mode authority, registry/license record,
  DNA worktree file, `_research/upstreams` file, or historical audit packet changed.
- No branch, stage, commit, push, or pull request was created.
- The main worktree had extensive pre-existing dirty state. Topic 01 hashes use the captured
  session-before bytes so pre-existing edits are not overwritten or falsely attributed.
- Topic 01 is not closed merely because static validation passes; Opus review and finding
  adjudication remain required.

## 8. Known limitations and review focus

1. The numeric thresholds are explicit user-approved defaults but are not empirically
   calibrated yet. Phase 06 may predeclare stricter replacements; it cannot loosen them after
   observing final samples.
2. Binary accepted-outcome intervals and paired token intervals need an implementation choice
   in Phase 06. This topic fixes the semantic bounds, not a statistics library.
3. Plain OMP cannot satisfy template-internal L0-L2 mechanisms. The spec therefore applies the
   external objective/oracle to plain OMP while retaining template-specific operational gates
   on the template candidate. Audit whether this separation is precise enough for PR-7.
4. `AgentSession.getSessionStats()` includes task-tool child usage. Audit whether the stated
   main-message + unique-child reconciliation is sufficient to prevent double counting across
   retries, handoffs, and nested task calls.
5. Audit whether `accepted_with_waiver` is consistently excluded from both candidate promotion
   and release readiness.
6. Audit whether any active spec outside the frozen file map still implies weighted tokens,
   Scout quotas, latency optimization, a single baseline, or pilot promotion.

## 9. Requested Opus verdict

Return exactly one top-level verdict:

```text
ACCEPT_TOPIC_01
REOPEN_TOPIC_01
INSUFFICIENT_EVIDENCE
```

Acceptance means the approved decisions are faithfully projected, source claims are scoped and
correct, phases remain coherent, and no Critical or Important contradiction remains. It does
not mean the benchmark is implemented or the product is production ready.
