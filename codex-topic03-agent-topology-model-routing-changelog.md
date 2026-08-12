# Topic 03 — Agent Topology and Model/Provider Routing Changelog

## Status

`IN_PROGRESS` — authority/spec projection complete; runtime, installer, human documentation, and
final behavioral validation remain.

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
- Mutation suite: 18 assertions PASS (one complete fixture plus 17 isolated mutations).
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
- Topic 02 focused validator: 603 PASS / 0 WARN / 0 FAIL.
- Topic 03 canonical spec checks: PASS; runtime/config/install/evidence checks remain red by
  design until the next checkpoints.
- `git diff --check` for spec/projection surfaces: exit 0.

## Pre-existing dirty-worktree boundary

The repository already contained extensive Topic 01/02/Phase 00 changes before Topic 03. Existing
dirty files are preserved and are not staged or claimed as Topic 03-only commits. New Topic 03
files are committed path-by-path; integration of overlapping existing files requires a later
explicit path review.
