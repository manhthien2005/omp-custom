# Change Narrative and Traceability

## How to use this map

This is a routing index, not a substitute for the exact snapshot. For each topic, begin with the
decision/design, follow the named executable path, inspect adversarial tests and current evidence,
then reconcile active spec/phase projections. `01-CANDIDATE-SNAPSHOT.jsonl` remains the exhaustive
path inventory.

## Foundation and topics

| Scope | Intended outcome | Primary authority | Design and plan | Executable/load-bearing surfaces | Tests, evidence, and status record | Central audit question |
|---|---|---|---|---|---|---|
| Phase 00 | Prove native OMP discovery, schemas, model roles, settings, task/isolation, extension and compaction facts before product projection | `spec/phases/phase-00-foundation.md`, `spec/key/00-method.md`, pinned OMP source | `docs/superpowers/specs/2026-08-08-*` through `2026-08-10-*`; matching plans | `scripts/lib/phase00-*`, `scripts/run-phase00-*` | `scripts/tests/phase00-*`, `docs/evidence/phase-00/manifest.yml` | Are immutable observations intact, correctly scoped, and not promoted into policy beyond what they prove? |
| Topic 01 | Quality-first accepted-outcome economics with sequentially valid promotion evidence; Cheap Scout/raw totals remain telemetry | KD-024, KD-025; `spec/key/03-token-quality-model.md`; `spec/13-validation-and-evaluation.md` | `2026-08-12-topic-01-optimization-metrics-{design,plan}.md` | Evaluation/promotion logic consumed by Round 09–12 | `codex-topic01-closure-status.md`, Topic 01 review/correction ledgers, Round 09–12 fixtures | Do calculations, stopping rules, exclusions, and verdicts resist bias and avoid turning missing data into promotion? |
| Topic 02 | Prefix-free entry, Tech-Lead sizing, contract-first lifecycle, internal reclassification, no fixed worker chain | KD-026; `spec/04-workflow-sizing.md`; relevant `spec/02`, `05`, `08`, `10` | `2026-08-12-topic-02-workflow-entry-task-lifecycle-{design,plan}.md` | `scripts/lib/topic02-workflow-lifecycle.ps1`; Quick/Standard/Orchestrated commands; task-triage and Tech Lead docs | `scripts/tests/topic02-workflow-lifecycle.Tests.ps1`; `scripts/validate-topic02-workflow-lifecycle.ps1`; Topic 02 changelog | Can plain requests and reclassification reach the correct contract without losing authority/evidence or forcing an obsolete topology? |
| Topic 03 | Benefit-gated three-agent manifest and explicit Cheap Scout/Worker/Reviewer routing | KD-027; `spec/03-agent-topology.md`; `spec/09-model-routing.md` | `2026-08-12-topic-03-agent-topology-model-routing-{design,plan}.md` | `template/.omp/config.yml`; `agents/{cheap-scout,worker,reviewer}.md`; commands; installer/uninstaller; `scripts/lib/topic03-topology-routing.ps1` | `scripts/tests/topic03-*`; `scripts/validate-topic03-topology-routing.ps1`; `docs/evidence/current-product/topic-03/manifest.yml`; Topic 03 changelog | Are role selection, exact model/effort identity, fallback, provider authority, and optional Opus semantics enforced rather than documented only? |
| Topic 04 | Durable local task/candidate/evidence/handoff authority shared across linked worktrees without entering Git | KD-028; `spec/04`, `06`, `08`, `10`, `15`; `docs/task-state.md` | `2026-08-13-topic-04-durable-task-state-candidate-handoff-offload-{design,plan}.md` | `scripts/lib/topic04-*`; `template/.omp/state/`; state installer integration | `scripts/tests/topic04-*`; `scripts/validate-topic04-durable-state.ps1`; `docs/evidence/current-product/topic-04/`; Topic 04 changelog | Can stale, competing, drifting, cross-worktree, or child-produced state ever gain acceptance authority or cause destructive cleanup? |
| Topic 05 | Progressive bounded retrieval; native default; optional pinned CodeGraph; read-only fail-soft Cheap Scout | KD-029; `spec/07-retrieval-and-code-understanding.md`; `spec/05`, `12`, `14`, `15` | `2026-08-13-topic-05-progressive-retrieval-codegraph-cheap-scout-{design,plan}.md` | `template/.omp/codegraph/`; `tools/codegraph-retrieve.js`; provisioning/cleanup/benchmark/retrieval scripts | `scripts/tests/topic05-*`; `scripts/validate-topic05-progressive-retrieval.ps1`; `docs/evidence/current-product/topic-05/`; Topic 05 changelog | Does every selected retrieval guarantee have real prerequisites/outcomes, bounded fallback, worktree safety, and no implicit network/provider/policy authority? |
| Topic 06 | Managed validation/receipt boundary over native OMP `task`, without becoming a second orchestrator | KD-030; `spec/06`, `08`, `10`, `15`; `docs/agent-boundaries.md` | `2026-08-13-topic-06-agent-boundary-contracts-{design,plan}.md` | `template/.omp/extensions/`; `template/.omp/contracts/`; `scripts/lib/topic06-agent-boundary.ps1` | `scripts/tests/topic06-*`; `scripts/validate-topic06-agent-boundary.ps1`; `docs/evidence/current-product/topic-06/`; Topic 06 changelog | Can malformed, partial, wrong-model, wrong-candidate, replayed, untrusted, or capability-stripped results cross the managed boundary as accepted work? |
| Topic 07 | Safe context-full compaction and continuity with explicit kernel, abort-before-provider pressure guard, and no summary-as-authority | KD-031; `spec/05`, `08`, `10`, `15`; `docs/context-continuity.md` | `2026-08-13-topic-07-context-compaction-continuity-design.md`; `2026-08-13-topic-07-safe-context-compaction-continuity-plan.md` | Topic 07 extension/state adapters; `scripts/lib/topic07-context-continuity.ps1` | `scripts/tests/topic07-*`; `scripts/validate-topic07-context-continuity.ps1`; `docs/evidence/current-product/topic-07/`; Topic 07 changelog | Can pressure, stale kernel, worktree drift, child state, or failed compaction continue into provider use or acceptance? |
| Topic 08 | Portable behavior core with one selected manifest, executable OMP adapter, non-installable Claude mapping, and retained local authority | Active behavior/adapter projections in `spec/12`, `14`, `16`; selected behavior manifest | `2026-08-14-topic-08-portable-behavior-core-runtime-adapters-{design,plan}.md` | `template/.omp/contracts/behavior-manifest.json`; behavior gates; agent-tasks tool; installer/uninstaller | `scripts/tests/topic08-*`; `scripts/validate-topic08-behavior-core.ps1`; `docs/evidence/current-product/topic-08/`; Topic 08 changelog | Is behavior injected exactly once, are adapters capability-only, and can an unverified adapter or external tool acquire workflow/policy/state authority? |
| Topic 09 | Close verification/review/quality gaps without permanent Verifier or duplicate lifecycle authority | KD-032; `spec/10`; Phase 04 | Round 09–12 design and plan | `scripts/lib/round09-12-evaluation-core.mjs`; quality/security fixtures | Round review/security tests; `quality.json`; `R0912-Q-*`; Round changelog | Are review selection, severity, freshness, independence, candidate binding, and re-review triggers executable and resistant to false completion? |
| Topic 10 | Close security, authority, destructive-action, retry, recovery, secret, and trust boundaries | KD-032; `spec/15`; Phase 05 | Round 09–12 design and plan | Evaluation core, installer/uninstaller/cleanup paths, security fixtures | Round review/security and installer tests; `security.json`; `R0912-S-*`; Round changelog | Can any untrusted input, secret-shaped output, retry, recovery, path escape, or destructive default bypass explicit authority and bounded evidence? |
| Topic 11 | Deterministic evaluation by default; provider campaign separately authorized; four closed promotion verdicts | KD-032; `spec/13`; Phase 06 | Round 09–12 design and plan | `round09-12-evaluation-core.mjs`; `run-round09-12-evaluation.ps1`; `benchmark.ps1`; promotion fixtures | Evaluation core tests; `evaluation.json`; `R0912-E-*`; Round changelog | Can incomplete, synthetic, pilot, unavailable, biased, or budget-exhausted evidence ever promote or start a provider process implicitly? |
| Topic 12 | Derive truthful package/phase/readiness status last; scratch proof is not live promotion | KD-032; `spec/12`, `14`, `16`; Phases 05–07 | Round 09–12 design and plan | Release-readiness validator/capture; package fixtures; installer scratch path | Installer/mutation tests; `release-readiness.json`; `R0912-R-*`; Round changelog | Are package ownership, repair/uninstall/rollback, evidence hashing, phase remap, adapter status, and non-promotion claims truthful and safe? |

## Current focused validators

- `scripts/validate-topic02-workflow-lifecycle.ps1`
- `scripts/validate-topic03-topology-routing.ps1`
- `scripts/validate-topic04-durable-state.ps1`
- `scripts/validate-topic05-progressive-retrieval.ps1`
- `scripts/validate-topic06-agent-boundary.ps1`
- `scripts/validate-topic07-context-continuity.ps1`
- `scripts/validate-topic08-behavior-core.ps1`
- `scripts/validate-round09-12-release-readiness.ps1`
- `scripts/validate-template.ps1`

## Current-product evidence entry points

- `docs/evidence/current-product/topic-03/manifest.yml`
- `docs/evidence/current-product/topic-04/`
- `docs/evidence/current-product/topic-05/manifest.json`
- `docs/evidence/current-product/topic-06/manifest.json`
- `docs/evidence/current-product/topic-07/manifest.json`
- `docs/evidence/current-product/topic-08/manifest.json`
- `docs/evidence/current-product/round-09-12/manifest.json`

Topic 02 is primarily contract/projection validation and inherits the later runtime migration.
Topic 04's directory is governed by its focused state/evidence contracts even though it does not
use the same top-level manifest filename pattern. Missing uniformity is not automatically a defect;
verify whether provenance and current-candidate binding are complete for the claim being made.

## Vertical issue rule

For every candidate finding, cite at least:

1. the owner/KD/spec requirement or a defensible safety invariant;
2. the exact implementation path and behavior;
3. the relevant positive/negative test or the demonstrated coverage gap;
4. evidence impact, including whether existing evidence becomes stale or merely incomplete; and
5. all active projection surfaces that would need reconciliation if the finding is confirmed.

Do not expand a finding by keyword association alone. Add a file only when it shares the same
execution path, authority contract, acceptance consequence, or evidence claim.
