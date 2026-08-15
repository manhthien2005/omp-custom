# Round 09–12 — Closure, Evaluation, and Release Readiness Design

Status: proposed written design for user review  
Date: 2026-08-14  
Repository: `omp-template`  
Execution policy: local workspace only; no stage, commit, push, PR, live install, or implicit
provider spend

## 1. Approved umbrella decision

```yaml
round: 09-12-closure-evaluation-release-readiness
decision: combine Topics 09, 10, 11, and 12 into one continuous round
status: umbrella_approved_written_design_pending_review
execution_shape:
  - close Topic 09 and Topic 10 contract gaps first
  - build and exercise Topic 11 evaluation next
  - derive Topic 12 phase, package, and promotion status last
subagents: benefit-gated; none by default
provider_calls: explicit opt-in only
opus: optional review path, never a completion prerequisite
git_mutation: prohibited unless separately authorized
live_install: prohibited unless separately authorized
```

The four topics share one discovery pass, impact map, implementation plan, changelog, focused
validator, evidence bundle, and final repository validation. They remain separate logical gates
inside the round because evaluation consumes the quality/security contracts and release status
consumes evaluation evidence.

## 2. Current baseline

The accepted baseline through Topic 08 is:

- the current repository validator reports 340 PASS, one advisory token-budget warning, and zero
  failures;
- Topic 04 already owns candidate-bound verification/review evidence, invalidation, acceptance,
  and recovery state;
- Topic 06 already validates frozen-candidate Reviewer packets, exact model/effort identity,
  structured results, forced-partial refusal, plan-mode refusal, and provisional receipts;
- Topic 07 already implements explicit local continuity recovery and remains
  `IMPLEMENTED_NOT_PROMOTED` while the OMP 17.2.10 canary is unavailable;
- Topic 08 already supplies the portable behavior manifest, selected skill roster, lifecycle
  adapter, mutation gates, and an OMP adapter marked `IMPLEMENTED_NOT_PROMOTED`;
- Claude remains `DESIGNED_NOT_VERIFIED` and non-installable;
- `spec/10-verification-and-review.md` and `spec/15-security-and-failure-recovery.md` are broad
  current contracts, but Topics 09 and 10 have no dedicated current-product closure bundle;
- `scripts/benchmark.ps1` is metadata-only and does not execute or classify a task cycle;
- no Topic 09–12 design, plan, decision, or current-product evidence bundle exists yet.

This round preserves the verified baseline. It does not reopen Topics 03–08 unless a focused
fixture demonstrates a real incompatibility.

## 3. Goals and non-goals

### Goals

1. Close Topic 09 without adding a permanent Verifier or duplicating Topic 04 authority.
2. Close Topic 10 with an executable failure/security matrix and safe evaluation storage.
3. Replace the metadata-only benchmark with a deterministic evaluation core and an explicitly
   opt-in runtime campaign adapter.
4. Compute accepted-outcome, false-completion, token-ledger, and promotion decisions from closed
   records rather than prose.
5. Remap active phases by supersession, validate scratch installation/rollback, and emit a
   truthful release status.
6. Keep unavailable provider/runtime branches visible without blocking model-free implementation.

### Non-goals

- no live project or user-scope OMP installation;
- no automatic provider/model call;
- no fabricated model-assisted score when DeepSeek, Claude, or another provider is unavailable;
- no Claude runtime adapter implementation or promotion;
- no OMP download, downgrade, credential setup, or account mutation;
- no new agent role, fixed reviewer roster, universal review dispatch, or mandatory Opus gate;
- no production promotion from synthetic records, deterministic unit fixtures, or a three-pair
  pilot;
- no rewrite of historical phase/evidence artifacts.

## 4. Round architecture

```text
Topic 09/10 closed contracts
        |
        v
deterministic gate + task-cycle record validator
        |
        v
optional explicit runtime campaign adapter
        |
        v
promotion classifier
        |
        v
Topic 12 phase/package/readiness projection
```

The round adds repository evaluation tooling, not a second lifecycle authority. Topic 04 remains
the only durable task/candidate/evidence authority. Topic 06 receipts remain provisional. The
round reads exported, bounded records and never writes directly into `.agent-tasks`.

### 4.1 Topic 09 — verification, review, and quality-gate closure

Topic 09 is a delta closure over existing behavior:

- the candidate author performs fresh self-verification;
- the main-session Tech Lead owns the final quality decision;
- no permanent Verifier exists;
- a selected General Reviewer remains independent, non-writing, exact `xhigh`, and mandatory only
  for the approved high-risk concern set;
- unavailable preferred review models use the already approved disclosed fallback ladder;
- missing required independent review remains an unmet gate, not a self-review success;
- review consumes `ARTIFACT + CONTRACT`, never the Writer's claim;
- Critical/Important findings block acceptance; Minor findings are recorded and adjudicated by
  the Tech Lead against the accepted contract;
- a changed candidate, diff, acceptance input, required tool capability, or evidence-bound file
  invalidates the affected proof;
- after rework, a fresh Reviewer may use delta-scoped reading only when the exact base/new
  candidates and unaffected concern bindings are available; the new candidate still requires a
  fresh review result and never reuses the prior approval;
- the full selected concern profile runs again when a finding touches a shared invariant, the
  concern profile changes, or unaffected bindings cannot be proven;
- an unvalidated or schema-unavailable result cannot clear a quality gate.

One current contradiction is closed explicitly: `spec/10` still describes
`BLOCKING | NON_BLOCKING | OBSERVATION`, while the selected Reviewer schema and prompt use
`critical | important | minor`. The runtime vocabulary is retained. `critical` and `important`
are blocking; `minor` supports `APPROVED_WITH_NOTES`; evidence-free observations are omitted from
the structured finding set. Active specs and phase criteria are remapped to that single vocabulary.

Implementation first tests the existing Topic 04/06 mechanisms. Runtime bytes change only when a
fixture exposes a concrete missing enforcement point. The normal expected output is stronger
validation and evidence, not a replacement review engine.

### 4.2 Topic 10 — security, authority, and recovery closure

The round turns the existing threat prose into a closed executable matrix covering:

- user authority and destructive-operation refusal;
- credential, secret-shaped content, raw environment, transcript, and reasoning exclusion;
- tool, hook, extension, MCP, external-provider, and remote-code trust boundaries;
- quota, provider, network, timeout, partial-output, context-pressure, retry, and cancellation
  outcomes;
- bounded retry with a stable operation identity and no duplicate side effect;
- transactional scratch installation and rollback;
- explicit separation of implementation failure, environment failure, flaky behavior, and
  pre-existing failure;
- fail-closed acceptance for missing authority, evidence, selected capability, or security gate;
- fail-soft optimization only where a separate fallback contract was already selected.

`evals/results/` is added to `.gitignore`. Evaluation persistence rejects or redacts secret-shaped
material and stores no raw transcript, chain of thought, credential, `.env` content, or private
provider payload.

### 4.3 Topic 11 — evaluation core and campaign boundary

The metadata-only benchmark is replaced by three bounded layers.

#### Layer A — closed deterministic core

The core validates:

- fixture identity and immutable baseline identity;
- task-cycle terminal state and candidate binding;
- the five required conditions for `validated_accepted_outcome`;
- mandatory AC coverage and required verification/review gates;
- false completion from the external deterministic oracle;
- failure classification;
- unique main/child usage attribution without double counting;
- `core_workflow_tokens`, `cheap_scout_tokens`, `raw_total_tokens`, and cache-read telemetry;
- missing/unattributable telemetry as `not_measured`;
- deterministic hard gates and the closed promotion decision set.

The promotion verdict set remains:

```text
PROMOTE_EFFICIENCY
PROMOTE_QUALITY
REJECT
DEFER_INCONCLUSIVE
```

Environment state is separate: `PASS | ENVIRONMENT_BLOCKED | NOT_RUN`. An unavailable campaign
therefore emits `DEFER_INCONCLUSIVE` with reason `environment_blocked`; it never invents a fifth
promotion verdict or reports a passing comparison.

#### Layer B — adversarial and synthetic tests

Synthetic records exercise the classifier but cannot support promotion. Required cases include:

- false completion;
- missing AC coverage;
- missing required independent review;
- stale candidate evidence;
- malformed/schema-unavailable result;
- forced partial result;
- plan-mode read-only substitution for a write/fresh-command contract;
- missing selected tool/capability;
- secret-shaped evidence;
- retry that would duplicate a side effect;
- missing token attribution;
- pilot attempting to promote;
- ordinary repeated 95% intervals or post-hoc thresholds attempting to promote.

The existing Topic 05 retrieval, Topic 07 continuity, and Topic 08 trigger/pressure fixtures are
referenced through exact results; their runtime logic is not copied into a new harness.

#### Layer C — explicit runtime campaign adapter

Runtime/model execution requires all of:

1. an explicit provider-call switch;
2. a frozen fixture and baseline manifest;
3. a stated evidence budget and stopping rule;
4. available runtime/model aliases and credentials;
5. scratch Git repositories and external deterministic oracles;
6. zero live-install mutation.

Without those inputs, the adapter writes a bounded `ENVIRONMENT_BLOCKED` campaign record and does
not launch a model. Cheap Scout/provider fallback follows Topic 03, but a fallback never changes
the frozen comparison variable silently. Claude unavailability remains a disclosed missing arm.

Pilot evidence may reject an unsafe/regressive candidate but cannot promote. Final promotion
continues to require the predeclared sequentially valid procedure in `spec/13`; this round tests
that gate with deterministic records but does not manufacture final sampling.

### 4.4 Topic 12 — phase remapping, package validation, and readiness

Topic 12 consumes the preceding records and produces four outputs:

1. **Phase supersession map** — update active Phase 04–07 tasks, dependencies, and exit criteria;
   preserve historical text behind explicit supersession notes.
2. **Scratch package proof** — dry-run, install, discovery, update/repair, uninstall, and rollback
   against a disposable project only.
3. **Adapter matrix** — OMP is evaluated at each locally available supported version; Claude stays
   non-installable until a compatible runtime and quota are available.
4. **Release-readiness record** — list deterministic gates, campaign status, promotion verdict,
   open blockers, known limitations, and the exact next action.

The current expected truthful release result is `IMPLEMENTED_NOT_PROMOTED` unless real final
promotion evidence becomes available. That is a successful round outcome, not a hidden test
failure. `PRODUCTION_READY` requires all selected runtime canaries, final promotion evidence, and
separate user authorization for the live-install verification step.

## 5. Artifacts and ownership

The implementation uses these exact primary surfaces:

| Surface | Ownership |
|---|---|
| `spec/key/04-decision-log.md` | one new umbrella decision, expected `KD-032` |
| `spec/10`, `spec/15` | Topic 09/10 closed contracts and gap dispositions |
| `spec/13` | evaluation/promotion authority |
| `spec/12`, `spec/16` | package, rollback, phase/remapping projection |
| Phase 04–07 plans | supersession projections, not rewritten history |
| `scripts/lib/round09-12-evaluation-core.mjs` | pure closed-record validation, accounting, and promotion logic |
| `scripts/run-round09-12-evaluation.ps1` | model-free default runner and explicit provider campaign boundary |
| `scripts/benchmark.ps1` | compatibility entry point delegating to the round runner |
| `scripts/lib/round09-12-release-readiness.ps1` | focused repository/evidence validator helper |
| `scripts/validate-round09-12-release-readiness.ps1` | focused validator entry point |
| `scripts/capture-round09-12-evidence.ps1` | transactional bounded evidence capture |
| `scripts/tests/round09-12-evaluation-core.Tests.mjs` | accepted-outcome, ledger, and promotion tests |
| `scripts/tests/round09-12-review-security.Tests.mjs` | quality/security adversarial records |
| `scripts/tests/round09-12-installer.Tests.ps1` | scratch package and rollback tests |
| `scripts/tests/round09-12-validator-mutations.Tests.ps1` | focused validator mutation coverage |
| `scripts/validate-template.ps1` | one integrated round section; Topic 03–08 checks retained |
| `evals/round09-12/manifest.json` and `evals/round09-12/cases/*.json` | versioned fixture/baseline definitions only |
| `evals/results/` | ignored local raw campaign results |
| `docs/evidence/current-product/round-09-12/` | bounded generated closure/readiness evidence |
| README plus architecture/security/installation/rollback/final-report docs | current status and operator projection |
| `codex-round09-12-closure-evaluation-release-readiness-changelog.md` | decisions, changes, validation, blockers, and optional review notes |

No new installed runtime component is created for repository-only evaluation tooling. The
`agent-boundary` component version changes only if an actual installed byte must change to close a
demonstrated Topic 09/10 defect.

## 6. Evidence bundle

The consolidated current-product bundle contains:

```text
docs/evidence/current-product/round-09-12/
  quality.json
  security.json
  evaluation.json
  release-readiness.json
  manifest.json
```

The manifest hashes every record and every round-governed implementation/fixture file. Capture is
transactional and refuses to settle a PASS bundle if a prerequisite check fails. Raw provider
output stays under ignored local results and is not copied into the bounded evidence bundle.

## 7. Failure and recovery behavior

| Failure | Required result |
|---|---|
| Required review unavailable | gate unmet; disclose fallback attempts; no acceptance |
| Provider/quota unavailable | campaign `ENVIRONMENT_BLOCKED`; no retry storm; no promotion |
| Runtime version unavailable | retain exact version blocker; validate available versions only |
| Missing usage attribution | affected ledger `not_measured`; promotion fails closed |
| Secret-shaped result | refuse persistence; bounded error without echoing the value |
| Crash/timeout | immutable failed cycle; included in numerator and reliability report |
| Partial output | non-accepted cycle; never completion evidence |
| Candidate mutation | invalidate bound verification/review evidence |
| Scratch install failure | transactional rollback; preserve diagnostic hashes |
| Rollback failure | stop, retain pre-rollback snapshot, report manual recovery path |
| Opus unavailable | continue approved fallback review or retain optional audit note |

Retries are bounded and classified. A retry that could duplicate a mutation requires an idempotent
operation identity or explicit reconciliation; otherwise it is refused.

## 8. Verification strategy

The round uses one focused validator with stable result codes grouped under four logical gates:

- `R0912-Q-*` — Topic 09 quality/review;
- `R0912-S-*` — Topic 10 security/recovery;
- `R0912-E-*` — Topic 11 evaluation/promotion;
- `R0912-R-*` — Topic 12 package/readiness.

Verification order:

1. focused unit/contract tests for each changed core;
2. mutation tests proving every result category can fail;
3. scratch installer/rollback tests;
4. model-free evaluation capture;
5. optional provider campaign only with separate explicit authorization;
6. focused round validator with evidence;
7. existing Topic 03–08 focused regressions affected by changed bytes;
8. one final full repository validator;
9. `git diff --check`, staged-path check, and no-live-install proof.

The known AGENTS token advisory may remain a warning. Any new failure blocks round closure.

## 9. Exit criteria

- [ ] Topic 09 gap scan is closed without a permanent Verifier or duplicated lifecycle authority.
- [ ] Required review, evidence invalidation, severity, re-review, and unvalidated-result behavior
      are executable and mutation-tested.
- [ ] Topic 10 matrix covers authority, secrets, destructive actions, trust, bounded retry,
      partial output, context pressure, provider failure, and transactional recovery.
- [ ] `evals/results/` is ignored and evidence persistence rejects secret-shaped content.
- [ ] The benchmark executes the deterministic core and can drive an explicitly authorized
      runtime campaign; metadata-only behavior is removed.
- [ ] Accepted-outcome, false-completion, token-ledger, pilot, and promotion logic are tested.
- [ ] Unavailable provider/runtime arms are recorded truthfully and cannot promote.
- [ ] Phase 04–07 plans are remapped through explicit supersession.
- [ ] Scratch install/update/uninstall/rollback and discovery validation pass.
- [ ] The consolidated evidence bundle settles transactionally.
- [ ] Existing Topic 03–08 focused checks remain green.
- [ ] Full repository validation has zero failures.
- [ ] No live OMP path, Git index, commit, remote, credential, or account is mutated.

## 10. Known limitations after a successful round

The round may complete while the product remains `IMPLEMENTED_NOT_PROMOTED`. The following are
environment/promotion limitations, not implementation claims:

- OMP 17.2.10 is not locally available for the Topic 07 second-runtime canary;
- Claude has no compatible verified runtime/quota and remains non-installable;
- DeepSeek/model-assisted arms may remain `ENVIRONMENT_BLOCKED`;
- deterministic and synthetic records prove the promotion machinery, not model quality;
- a live install still requires a separate explicit user decision.

These limitations are retained in the release-readiness record and never converted into PASS.

## 11. Internal execution checkpoints

The implementation proceeds continuously with only three internal checkpoints:

1. **Contract checkpoint:** Topic 09/10 focused tests green.
2. **Evaluation checkpoint:** deterministic core, adversarial fixtures, and evidence capture green.
3. **Release checkpoint:** phase/package projection and final full validation green.

Work pauses for the user only if a new architectural decision, external authority, provider spend,
live install, destructive action, or genuine environment blocker changes the approved scope.
