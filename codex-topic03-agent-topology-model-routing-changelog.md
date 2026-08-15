# Topic 03 — Agent Topology and Model/Provider Routing Changelog

## Status

`IMPLEMENTED_WITH_ENVIRONMENT_BLOCK` — the repository migration and behavioral matrix are
complete. DeepSeek provider execution remains blocked only by the named external credential
prerequisite; the approved Tech Lead retrieval fallback was observed.

## Approved selection

- Main-session Tech Lead is the default writer, verification owner, integrator, and final owner.
- Default is inline/no spawn; every spawn requires a concrete benefit and bounded contract.
- Selected spawnable manifest: `cheap-scout`, `worker`, `reviewer`.
- Cheap Scout: read-only advisory retrieval; Flash `xhigh`/provider `max` → Pro
  `xhigh`/provider `max` availability fallback → Tech Lead retrieval.
- Worker: `high` for moderate work; Tech-Lead-selected `xhigh` for difficult work.
- Reviewer: General Reviewer, dynamic concern profiles, exact `xhigh`, risk-gated.
- Opus is preferred when suitable, never implicitly mandatory.

## Checkpoint 1 — DeepSeek environment and probe

- OmniRoute advertises `ds/deepseek-v4-flash` and `ds/deepseek-v4-pro`.
- User OMP catalog resolves both selectors with reasoning and `high..xhigh` thinking metadata.
- Timestamped OMP catalog and OmniRoute database backups were created before the scoped catalog
  edit; no credential or secret is recorded here.
- Flash and Pro provider smoke: `ENVIRONMENT_BLOCKED / DEEPSEEK_CREDENTIAL_MISSING`.
- Tech Lead retrieval fallback remains valid; this environment condition does not block the
  repository migration.
- `scripts/tests/topic03-deepseek-routing.Tests.ps1`: 12 assertions PASS.

## Checkpoint 2 — Focused contract validator

- Added pure focused helper, mutation suite, and runner.
- Mutation suite: 20 assertions PASS.
- Pre-migration repository state: 3 PASS / 14 FAIL, correctly exposing the five-agent runtime.
- Post-spec projection: 5 PASS / 12 FAIL; all remaining failures are runtime/config/install/
  evidence migration items.

## Checkpoint 3 — Canonical authority and phase projection

Authority/projection paths updated in place without staging their pre-existing Topic 01/02 work:

- `spec/03-agent-topology.md`, `spec/09-model-routing.md`, `spec/key/04-decision-log.md` (KD-027)
- `spec/key/01-dna.md`, active specs 01/02/05/06/08/10/12–16, `spec/README.md`
- phases 01–07, with Phase 02 runtime ownership, Phase 05 retirement/settings ownership, and
  Phase 06 exact topology/routing/effort fixtures

Regression evidence:

- Topic 02 mutation self-test: 134 assertions PASS.
- Topic 02 focused validator: 604 PASS / 0 WARN / 0 FAIL.
- Topic 03 canonical spec checks: PASS; runtime/config/install/evidence checks remain red by
  design until the next checkpoints.
- `git diff --check` for spec/projection surfaces: exit 0.

## Checkpoint 4 — Three-agent runtime migration

- Added `template/.omp/agents/cheap-scout.md` and `worker.md`; rewrote `reviewer.md`.
- Rehomed main-session Tech Lead guidance to `docs/roles/tech-lead.md`.
- Retired exactly `tech-lead.md`, `explorer.md`, `implementer.md`, and `verifier.md` from OMP
  agent discovery.
- Rewrote Quick, Standard, and Orchestrated as benefit/risk-gated adapters without a fixed chain
  or concrete model ID.
- Added a closed current-product manifest that binds the immutable Phase 00 conclusion and every
  selected runtime/config/installer/validator file by SHA-256.
- Phase 00 T-00.3 tests: 37 PASS / 0 FAIL.

## Checkpoint 5 — Routing and installation enforcement

- Project routing selects Flash `xhigh` for Cheap Scout, Pro `xhigh` as its only fallback, empty
  default/Worker/Reviewer fallback chains, and per-spawn effort capped at `xhigh`.
- Installer maps the product `workflows` component to OMP `commands`, backs up before mutation,
  retires only the closed stale-agent set, preserves custom/protected files, and omits global
  user-level effort settings without explicit `-EnablePerSpawnEffort`.
- Installer behavior tests: 8 PASS / 0 FAIL.
- Topic 03 mutation tests: 20 assertions PASS.
- Topic 03 focused validation: 22 PASS / 0 WARN / 0 FAIL.
- Topic 02 lifecycle regression: 604 PASS / 0 WARN / 0 FAIL.
- Full template validation: 119 PASS / 1 known advisory warning / 0 FAIL.

## Checkpoint 6 — Product documentation and authority reconciliation

- Current product docs now describe main-session Tech Lead entry, inline/no-spawn default,
  read-only fail-soft Cheap Scout, benefit-gated Worker, risk-gated `xhigh` Reviewer, optional
  Opus, disclosed same-model review, and conditional parallel writers.
- Installation/routing docs distinguish gateway IDs (`ds/...`) from OMP selectors
  (`omniroute/ds/...`) and keep the model catalog and credentials external.
- Workflow v0 reports and research matrices retain their old role names only behind explicit
  historical/non-authority fences.
- Command and main-session prompts contain zero concrete DeepSeek or Codex model identifiers.

## Checkpoint 7 — Disposable behavioral verification and handoff

- Disposable installation dry-run produced zero mutations; apply discovered exactly
  `cheap-scout.md`, `reviewer.md`, and `worker.md`, with no retired agent discoverable.
- A low-risk request stayed in the main session with zero task calls; when DeepSeek was
  unavailable, Tech Lead retrieval fallback completed and was recorded without fabricating a
  Scout PASS.
- Worker resolved at `high` for moderate work and at `xhigh` for the difficult-task override.
- Reviewer resolved at explicit `xhigh`, returned valid structured output, used a separate
  same-model session, and disclosed that limitation.
- The first Reviewer observation exposed an effort-identity visibility gap. Worker and Reviewer
  role selectors were corrected to explicit `:high` and `:xhigh` suffixes, then the Reviewer case
  was rerun successfully.
- With batch dispatch unavailable, three writer calls completed sequentially without a task
  block and disclosed the fallback.
- Redacted evidence is retained in `docs/evidence/current-product/topic-03/e2e.yml`; the validated
  disposable project was removed after the run.
- Final lean verification: DeepSeek routing 12 assertions PASS; topology mutations 20 assertions
  PASS; installer 8 PASS; Phase 00 T-00.3 37 PASS; Topic 02 604 PASS; Topic 03 22 PASS; full
  validator 119 PASS / 1 known RULES advisory / 0 FAIL; unstaged and staged diff checks exit 0.
- Focused self-review found zero secret-shaped values, exactly three installed agents, zero model
  identifiers in commands/main instructions, zero broad-delete patterns, explicit user effort
  opt-in, and present fallback disclosures.

## Repository paths changed by Topic 03

New Topic 03-owned paths:

- `docs/superpowers/specs/2026-08-12-topic-03-agent-topology-model-routing-design.md`
- `docs/superpowers/plans/2026-08-12-topic-03-agent-topology-model-routing-plan.md`
- `scripts/lib/topic03-deepseek-routing.ps1`
- `scripts/tests/topic03-deepseek-routing.Tests.ps1`
- `scripts/run-topic03-deepseek-smoke.ps1`
- `scripts/lib/topic03-topology-routing.ps1`
- `scripts/tests/topic03-topology-routing.Tests.ps1`
- `scripts/tests/topic03-installer.Tests.ps1`
- `scripts/validate-topic03-topology-routing.ps1`
- `docs/evidence/current-product/topic-03/deepseek-smoke.yml`
- `docs/evidence/current-product/topic-03/e2e.yml`
- `docs/evidence/current-product/topic-03/manifest.yml`
- `docs/roles/tech-lead.md`
- `template/.omp/agents/cheap-scout.md`
- `template/.omp/agents/worker.md`
- `codex-topic03-agent-topology-model-routing-changelog.md`

Overlapping repository paths updated for the selected projection:

- `template/.omp/AGENTS.md`, `template/.omp/config.yml`, `template/.omp/agents/reviewer.md`
- `template/.omp/commands/quick.md`, `standard.md`, `orchestrated.md`
- retired `template/.omp/agents/tech-lead.md`, `explorer.md`, `implementer.md`, `verifier.md`
- `scripts/install-template.ps1`, `scripts/validate-template.ps1`
- `scripts/lib/phase00-evidence.ps1`, `scripts/lib/phase00-e1-evidence.ps1`
- `scripts/tests/phase00-t003.Tests.ps1`
- `scripts/lib/topic02-workflow-lifecycle.ps1`, `scripts/tests/topic02-workflow-lifecycle.Tests.ps1`
- `spec/03-agent-topology.md`, `spec/09-model-routing.md`, `spec/key/04-decision-log.md`
- `spec/key/01-dna.md`, specs `01`, `02`, `05`, `06`, `08`, `10`, `12`–`16`, and
  `spec/README.md`
- phase plans `phase-01` through `phase-07`
- `README.md`, `CHANGELOG.md`, `docs/architecture.md`, `docs/customization.md`,
  `docs/installation.md`, `docs/workflow-v0.md`, `docs/policies/model-routing.md`,
  `docs/policies/quality-gates.md`, `docs/security.md`, `docs/token-strategy.md`,
  `docs/report-design.md`, and `docs/final-report.md`

## External configuration and backups

- Updated user catalog: `C:/Users/MrThien/.omp/agent/models.yml` (no credential recorded).
- Catalog backup: `C:/Users/MrThien/.omp/agent/models.yml.topic03-20260812-233919.bak`.
- OmniRoute database backup:
  `/app/data/db_backups/topic03-20260812-233919-before-deepseek.sqlite`.
- OmniRoute advertises `ds/deepseek-v4-flash` and `ds/deepseek-v4-pro`.
- Smoke evidence: `docs/evidence/current-product/topic-03/deepseek-smoke.yml` records
  `ENVIRONMENT_BLOCKED / DEEPSEEK_CREDENTIAL_MISSING` for both provider calls.

## Remaining limitations

- DeepSeek provider execution cannot pass until OmniRoute receives an active DeepSeek credential;
  Tech Lead retrieval fallback is the approved behavior meanwhile.
- Opus is not configured and is not required. Same-model independent-session review remains a
  disclosed fallback; live cross-family review quality is not claimed.

## Pre-existing dirty-worktree boundary

The repository already contained extensive Topic 01/02/Phase 00 changes before Topic 03. Existing
dirty files are preserved and are not staged or claimed as Topic 03-only commits. No final
staging or integration commit was created; integration of overlapping existing files requires an
explicit path review.
