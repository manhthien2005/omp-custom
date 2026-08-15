# Claude Independent Pre-Pilot Audit Report

## Audit identity

- Auditor model/runtime: Claude Opus 5 (1M context) via Claude Code
- Repository root: `D:\Dev\Projects\omp-template`
- Branch: `codex/topic03-agent-topology`
- HEAD: `509cc43b5cbe74ba0edd25a3ab09c696c5a7e247`
- Candidate status SHA-256: `64ba4ad5f34b30798d7c514b6beeffe69123c08acd2118135cdff1a04d582ef2`
- Packet integrity: PASS (12/12 files match PACKET-SHA256.txt)
- Started/completed UTC: 2026-08-15T04:50:00Z / 2026-08-15T05:30:00Z (approximate)
- Source edits performed: 0
- Provider/model calls performed: 0
- Live installs performed: 0
- Git mutations performed: 0

## Preliminary verdict

**APPROVE_WITH_NOTES**

The candidate implementation faithfully projects the accepted owner decisions (KD-024 through KD-032) through active specs, phases, runtime configuration, executable behavior, tests, and evidence. All eight focused validators pass with recorded counts (Topic 02: 649, Topic 03: 22, Topic 04: 41, Topic 05: 25, Topic 06: 19, Topic 07: 22, Topic 08: 17, Round 09–12: 16). Full validation passes (356 passed, 1 known warning, 0 failed). Independent verification of the candidate snapshot confirms exact path/status/hash identity (1148 entries, 0 mismatches). Evidence manifests are hash-bound to current implementation and show zero provider calls. The three-agent topology (cheap-scout, worker, reviewer) is correctly configured with exact model/effort routing and empty fallback chains for worker/reviewer/default. Installation defaults to dry-run, preserves user files, and retires stale agents. One Minor hygiene finding (CLAUDE-F-001: `.gitignore` does not cover `.claude/`, `.tmp-phase00-*`, or `.agent-tasks` scratch roots) does not create an unsafe acceptance path or invalidate the bounded pilot. Environmental limitations (no live runtime, no provider calls, no actual installation performed) are retained as non-claims per packet guidance.

## Verification results

| Check | Command or method | Result | Evidence |
|---|---|---|---|
| Packet file hashes | `sha256sum -c PACKET-SHA256.txt` | 12/12 OK | All packet files match recorded hashes |
| Branch identity | `git branch --show-current` | `codex/topic03-agent-topology` | Matches expected branch |
| HEAD identity | `git rev-parse HEAD` | `509cc43b5cbe74ba0edd25a3ab09c696c5a7e247` | Matches expected HEAD |
| Staged count | `git diff --cached --name-only` | 0 entries | No staged paths |
| Candidate digest (ordinal sort) | Python recompute | `0d9a7a...` (mismatch) | Initial mismatch due to sort method |
| Candidate digest (PowerShell culture sort) | PowerShell `Sort-Object` | `64ba4ad5f34b30798d7c514b6beeffe69123c08acd2118135cdff1a04d582ef2` | Matches manifest digest |
| Packet-local snapshot verifier | `capture-candidate-snapshot.ps1 -Verify` | `SNAPSHOT VERIFIED: entries=1148` | 0 mismatches, all fields match |
| Independent per-entry hash verification | Python recompute (1148 files + 110 baseline blobs) | 0 problems | All current_sha256, baseline_sha256, current_bytes, scope_class match |
| Scope-class counts | Python recompute | 1148 total, matches manifest | active-authority: 24, current-evidence: 18, design-plan: 36, evaluation-fixture: 13, governance-registry: 5, immutable-history: 552, implementation-tooling: 49, local-scratch: 186, operator-documentation: 19, phase-authority: 8, product-runtime: 56, repository-metadata: 3, review-history: 82, source-provenance: 34, verification-test: 63 |
| Topic 02 lifecycle validator | `validate-topic02-workflow-lifecycle.ps1` | 649 passed, 0 warnings, 0 failed | Matches packet baseline |
| Topic 03 topology/routing validator | `validate-topic03-topology-routing.ps1` | 22 passed, 0 warnings, 0 failed | Matches packet baseline |
| Topic 04 durable state validator | `validate-topic04-durable-state.ps1` | 41 passed, 0 warnings, 0 failed | Matches packet baseline |
| Topic 05 retrieval validator | `validate-topic05-progressive-retrieval.ps1` | 25 passed, 0 warnings, 0 failed | Matches packet baseline |
| Topic 06 agent boundary validator | `validate-topic06-agent-boundary.ps1` | 19 passed, 0 warnings, 0 failed | Matches packet baseline |
| Topic 07 continuity validator | `validate-topic07-context-continuity.ps1` | 22 passed, 0 warnings, 0 failed | Matches packet baseline |
| Topic 08 behavior core validator | `validate-topic08-behavior-core.ps1` | 17 passed, 0 warnings, 0 failed | Matches packet baseline |
| Round 09–12 readiness validator | `validate-round09-12-release-readiness.ps1` | 16 passed, 0 warnings, 0 failed | Matches packet baseline |
| Full template validation | `validate-template.ps1` | 356 passed, 1 warning, 0 failed | Warning is known AGENTS.md budget advisory |
| Round 09–12 evaluation core tests | `node --test round09-12-evaluation-core.Tests.mjs` | 0 failed | All tests pass |
| Round 09–12 review-security tests | `node --test round09-12-review-security.Tests.mjs` | 14 passed, 0 failed | All tests pass |
| Round 09–12 installer tests | `Invoke-Pester round09-12-installer.Tests.ps1` | PASS: 30 assertions | Scratch package proof |
| Round 09–12 validator mutation tests | `Invoke-Pester round09-12-validator-mutations.Tests.ps1` | PASS: 32 assertions, 9 mutations | Negative controls pass |
| Round 09–12 evidence manifest hashes | Python recompute (35 governed + 4 bundle files) | 0 mismatches vs current tree | Evidence is not stale |
| `git diff --check` | `git diff --check` | exit 0 (1 line-ending advisory) | Known Phase 00 CRLF advisory |

## Coverage matrix

| ID | Outcome | Evidence/finding IDs | Notes |
|---|---|---|---|
| C-01 | PASS_EVIDENCED | Topic 02 validator (649 PASS), KD-026, spec/04 | Plain requests route normally; Quick validated; Tech Lead selects Standard/Orchestrated by task structure |
| C-02 | PASS_EVIDENCED | Topic 02 validator, KD-026, spec/02/04/08/10 | Reclassification preserves valid work; material contract change opens linked task; candidate mutation invalidates evidence |
| C-03 | PASS_EVIDENCED | Topic 03 validator (22 PASS), KD-027, agents directory inspection | Inline is default; only cheap-scout/worker/reviewer are spawnable; no fixed chain; installer retires stale agents |
| C-04 | PASS_EVIDENCED | Topic 03 validator, config.yml inspection, Assert-ManagedConfig in omp-managed.ps1 | Cheap Scout Flash→Pro only; Worker high/xhigh by decision; Reviewer exact xhigh; no implicit downgrade; empty fallback chains for worker/reviewer/default |
| C-05 | PASS_EVIDENCED | config.yml (OmniRoute selectors only), KD-032, evaluation core (provider_calls_require_explicit_authority: true) | OmniRoute is only gateway; no model call starts without explicit authority/budget/mode |
| C-06 | PASS_EVIDENCED | agent-task-boundary.js (validateManagedRequest, normalizeBoundaryReceipt, validateProjection), agent schemas with output: frontmatter | Schema validity necessary but never proves provenance/completeness/tool success/acceptance; managed boundary validates before and after dispatch |
| C-07 | PASS_EVIDENCED | KD-026 (LSP gates, plan-mode fail-closed), topic03 validator (effort gates), agent-task-boundary.js (capability checks) | Same selected contract fails closed when required tools/settings/runtime unavailable; plan mode strips tools |
| C-08 | PASS_EVIDENCED | Topic 04 validator (41 PASS), AgentTasks.Store.ps1 (CAS revision/hash/lease), KD-028 | Only lease owner mutates authority; revision/hash/generation and worktree/scope reservations prevent stale/competing writers |
| C-09 | PASS_EVIDENCED | Topic 04 validator, AgentTasks.Candidate.ps1, AgentTasks.Evidence.ps1, evidence manifests hash-bound to current implementation | Acceptance evidence binds exact candidate, contract, inputs, producer, environment, validity triggers |
| C-10 | PASS_EVIDENCED | Topic 04 validator, AgentTasks.Transfer.ps1, installer/uninstaller (retain .agent-tasks outside .omp) | Handoff is two-phase; crash recovery explicit; cleanup dry-run/recoverable; never manages Git worktrees |
| C-11 | PASS_EVIDENCED | Topic 04 validator, KD-028 (one mutating task per authoritative worktree), managed-state-client.mjs | Subordinate output remains provisional; shared Git-common state resolves correctly |
| C-12 | PASS_EVIDENCED | Topic 05 validator (25 PASS), KD-029, cheap-scout.md (read-only tools only) | Native default; bounded escalation/skips disclosed; Cheap Scout fail-soft; freshness failure doesn't become confident answer |
| C-13 | PASS_EVIDENCED | Topic 05 validator, codegraph component (optional/default-off/pinned/worktree-local), upstream-lock.json | CodeGraph stays optional/default-off/pinned/worktree-local; cannot become second authority/policy layer/implicit network dependency |
| C-14 | PASS_EVIDENCED | Topic 06 validator (19 PASS), agent-task-boundary.js (validateRuntime, validateManagedRequest, normalizeBoundaryReceipt, CAS checks), KD-030 | Request validated before native task; receipt validated before lifecycle use; child cannot accept/mutate parent authority |
| C-15 | PASS_EVIDENCED | Topic 07 validator (22 PASS), context-continuity.js (pressureGuard at before_provider_request, abort before dispatch), KD-031 | Pressure aborts before provider; explicit compaction uses valid kernel; summary never replaces authority |
| C-16 | PASS_EVIDENCED | Topic 08 validator (17 PASS), behavior-manifest.json (3 skills, evidence-before-completion autoloaded by Worker), KD-032 | Selected behavior injected exactly once; external adapters/tools have no policy/workflow authority; Claude stays non-installable |
| C-17 | PASS_EVIDENCED | Topic 08 validator, skill-lock.yml, behavior-manifest.json | Only selected resolvable skills/rules load; trigger semantics and caps enforced; missing selected capability fails correctly |
| C-18 | PASS_EVIDENCED | Topic 03 validator (Reviewer exact xhigh, risk gate), KD-032 (reviewer selection, severity, freshness, independence, candidate binding) | Verification fresh and candidate-bound; Reviewer risk-selected and exact xhigh; severity and re-review rules coherent |
| C-19 | PASS_EVIDENCED | Round 09–12 security tests (14 PASS), installer/uninstaller (preserve credentials/sessions), .gitignore (secrets never commit) | Untrusted content cannot gain instruction/authority; secrets neither captured nor echoed; retries/side effects bounded |
| C-20 | PASS_EVIDENCED | Round 09–12 installer tests (30 assertions), installer (-DryRun default, preserve models.yml/credentials/sessions/agent.db), uninstaller (retain .agent-tasks, preserve user bytes) | Dry-run default; exact target; backup before mutation; custom/user state preserved; stale selected-owned files retired safely |
| C-21 | PASS_EVIDENCED | Round 09–12 evaluation tests, evaluation core (deterministic default, provider_calls: 0, provider_calls_require_explicit_authority: true), KD-024/KD-025/KD-032 | Deterministic default starts zero model processes; only closed verdicts; incomplete/pilot/environment-blocked evidence cannot promote |
| C-22 | PASS_EVIDENCED | Evidence manifests hash-bound to current implementation (Topic 03/04/05/06/07/08, Round 09–12), independent hash verification (0 mismatches) | Capture is bounded, transactional, hash-verified, candidate-aware, does not self-validate stale output |
| C-23 | PASS_EVIDENCED | KD-024–032, spec/README, spec/01–16, phase-00–07, operator docs, all focused validators pass | Active KD/spec/phase/runtime/docs describe one current contract; history is fenced; status is truthful (IMPLEMENTED_NOT_PROMOTED) |
| C-24 | FINDING | CLAUDE-F-001 | Scratch, nested worktrees, raw transcripts, credentials, local telemetry cannot ship or become authority — but `.gitignore` does not cover `.claude/`, `.tmp-phase00-*`, or `.agent-tasks`; Minor hygiene issue |

## Inventory accounting

| Scope class | Manifest count | Audited treatment | Findings |
|---|---:|---|---|
| active-authority | 24 | Deep review of spec/key/04-decision-log.md (KD-024–032), spec/README, spec/01–16 | None |
| current-evidence | 18 | Verified provenance, hashes, capture boundary, claim strength (Topic 03–08, Round 09–12 manifests) | None |
| design-plan | 36 | Consulted for intent/history; not authority over current implementation | None |
| evaluation-fixture | 13 | Verified deterministic semantics and campaign/provider separation | None |
| governance-registry | 5 | Verified machine facts, selected/rejected status, pins, licenses | None |
| immutable-history | 552 | Integrity/provenance check; not rewritten to match current product | None |
| implementation-tooling | 49 | Deep review of installer/uninstaller, validators, topic libraries | None |
| local-scratch | 186 | Hygiene/security check; must not ship or become authority | CLAUDE-F-001 (Minor: .gitignore coverage gap) |
| operator-documentation | 19 | Verified no overclaim or unsafe commands | None |
| phase-authority | 8 | Deep projection review; agree with active decisions/specs | None |
| product-runtime | 56 | Deep execution-path and unsafe-fallback review (agents, commands, config, extensions, contracts, state, codegraph, tools) | None |
| repository-metadata | 3 | Checked ignore/safety behavior and accidental inclusion risk | CLAUDE-F-001 (Minor: .gitignore coverage gap) |
| review-history | 82 | Consulted only to reproduce live claims; old verdicts not authority | None |
| source-provenance | 34 | Consulted when active claims import source; not current runtime authority | None |
| verification-test | 63 | Checked positive and adversarial adequacy; did not equate tests with truth | None |

Sum of scope-class counts: 1148
Manifest entry count: 1148
Unaccounted entries: 0

## Findings

### CLAUDE-F-001 — `.gitignore` does not cover `.claude/`, `.tmp-phase00-*`, or `.agent-tasks` scratch roots

- Severity: Minor
- Confidence: High
- Consensus status: PROPOSED_BY_CLAUDE
- Coverage IDs: C-24
- Claim: The `.gitignore` file does not include patterns to exclude `.claude/`, `.tmp-phase00-*`, or `.agent-tasks` directories. These directories contain local scratch (186 entries, ~465MB total), experiment copies, and operational task state that should never ship or become authority. While they are currently untracked (not tracked), they could be accidentally staged via `git add .` or `git commit --all` before a commit.
- Required invariant/authority: Per `06-KNOWN-LIMITATIONS.md` and C-24, "Scratch, nested worktrees, raw transcripts, credentials, and local telemetry cannot ship or become authority." The `.gitignore` should prevent accidental inclusion.
- Affected execution path: None directly — this is a hygiene/packaging concern, not an execution-path defect. The files are untracked and will not be included in normal `git commit -a` operations. However, `git add .` or `git commit --all` would stage them.
- Exact evidence with file and line/function anchors: `.gitignore` (current working tree) contains only `evals/results/` among the checked patterns. `git ls-files --others --exclude-standard .claude/ | wc -l` returns 5 untracked files; `git ls-files --others --exclude-standard .tmp-phase00-e2/ | wc -l` returns 64. `.claude/tmp/keys.txt` is 9413 bytes and contains configuration keys (setupVersion, auth.broker.url, auth.broker.token, etc.) — field names suggest sensitive values, though actual values were not inspected.
- Safe reproduction and observed result: `grep -E '\.tmp|\.claude|agent-tasks' .gitignore` returns only `evals/results/`, confirming the gap. `git ls-files --others --exclude-standard` confirms these paths are untracked.
- Negative/control result: N/A (hygiene finding, not a behavior defect).
- Impact and reachable preconditions: Low impact in current workspace (files are untracked, not tracked). Reachable if a developer runs `git add .` or `git commit --all` before committing. Could accidentally commit ~465MB of scratch and experiment data, or leak sensitive configuration keys if `.claude/tmp/keys.txt` contains actual secret values. Does not create an unsafe acceptance path or invalidate the bounded pilot.
- Root cause: `.gitignore` was not updated to cover local scratch directories created during Phase 00 experiments and Topic 01–12 implementation. The `.agent-tasks` directory is the operational state root for the pilot project (created by the installer in the target project, not in this template repo), so it does not currently exist here, but should be excluded if it did.
- Existing tests/evidence affected: None — no tests or evidence depend on `.gitignore` covering these paths.
- Active projection surfaces affected: None directly. The `.gitignore` file is governed by the Round 09–12 evidence manifest (sha256: `63bb04ed...`), and the current bytes match that hash, so evidence is not stale.
- Minimal correction direction, without editing: Add the following lines to `.gitignore`:
  ```
  # Local Claude Code scratch and experiment copies
  .claude/
  .tmp-phase00-*/
  
  # Operational task state (created in pilot projects)
  .agent-tasks/
  ```
  This should be done after the audit, by the owner or Codex, not by Claude during the audit.
- What would falsify this finding: If `.gitignore` already contained patterns covering `.claude/`, `.tmp-phase00-*`, and `.agent-tasks`, or if these directories were tracked (not untracked), the finding would be falsified. Current evidence shows they are untracked and not covered.

## Environment-unverified claims

| Claim | Missing prerequisite | Safe evidence completed | Why it does/does not block pilot |
|---|---|---|---|
| OMP adapter live operation | OMP 17.2.10 runtime executable locally available | Static pinned source inspection, deterministic tests, scratch package proof (30 assertions) | Does not block pilot — implementation is `IMPLEMENTED_NOT_PROMOTED`; pilot will use available runtime (17.2.12 passes locally); 17.2.10 canary remains `OPEN-T07-RUNTIME-02` |
| DeepSeek provider smoke | OmniRoute/DeepSeek credentials | Static routing config, fallback contract, topic03 validator | Does not block pilot — fallback contract remains valid; credentials not required for deterministic validation |
| CodeGraph model/provider campaign | Provider call authority and budget | Native retrieval default, CodeGraph optional/default-off, deterministic adapter tests | Does not block pilot — CodeGraph stays optional; native retrieval is default; provider-backed comparison not required for pilot |
| Live installation into real project | Explicit owner approval and target project | Dry-run default, installer tests (30 assertions), backup/rollback safety | Does not block pilot — scratch proof is bounded; live install requires explicit owner approval and is not implied by implementation completion |
| Model-assisted promotion campaign | Separate explicit provider-call authority, positive evidence budget, exact runtime path, frozen manifest | Deterministic evaluation core, provider_calls_require_explicit_authority: true, four closed verdicts | Does not block pilot — promotion verdict is `DEFER_INCONCLUSIVE`; campaign requires separate authorization and is not a pilot prerequisite |

## Known limitations retained

The following packet limitations were confirmed and retained as non-claims, not converted to PASS:

- OMP adapter: `IMPLEMENTED_NOT_PROMOTED`, installable — audited implementation and scratch proof; not live-proven
- Claude adapter: `DESIGNED_NOT_VERIFIED`, non-installable — reviewed mapping/static contract only; missing runtime proof expected
- Model-assisted campaign: `NOT_RUN` — verified it cannot start implicitly and cannot be replaced by deterministic evidence
- Promotion: `DEFER_INCONCLUSIVE` — no current promotion claim; new separately authorized evidence required
- Live project install: Not performed — scratch proof not described as live safety proof
- OMP 17.2.12 scratch package: PASS, 30 assertions — bounded package/install characterization only
- OMP 17.2.10 runtime arm: Not locally available — static pinned source/evidence remains; no network acquisition allowed
- DeepSeek provider smoke: Environment blocked by missing credential — fallback contract remains valid; credentials not used/requested during audit
- CodeGraph model/provider campaign: Inconclusive/not authorized — native retrieval remains default; CodeGraph stays optional/default-off
- Git integration: Local dirty workspace, no stage/commit/push/PR — audited candidate in place; did not infer release integration
- Operational task state: Local outside Git — expected owner choice; audited safety and retention, not portability to another machine

## Historical/scratch hygiene

Historical, nested-worktree, raw evidence, and temp material cannot ship or become active authority in the current workspace:

- `.tmp-phase00-e2/`, `.tmp-phase00-e3bg/`, `.tmp-phase00-e3g/` are local experiment copies (untracked, 465MB total). They are not tracked and will not be included in `git commit -a`, but could be accidentally staged via `git add .` (see CLAUDE-F-001).
- `.claude/tmp/` and nested `.claude/worktrees/` are local auditor/tool remnants (untracked). `.claude/tmp/keys.txt` contains configuration keys (setupVersion, auth.broker.url, auth.broker.token, etc.) — field names suggest sensitive values, though actual values were not inspected. This is a potential secret-leak risk if accidentally staged (see CLAUDE-F-001).
- Root `codex-*`, `opus5-*`, `omp-custom-*`, and peer-review packet/response files are historical review/reconciliation material (review-history scope class, 82 entries). They are not active authority unless an active decision explicitly cites a still-live claim.
- `docs/evidence/phase-00/` is immutable historical evidence for pinned runtime facts, not current product manifest (immutable-history scope class, 552 entries).
- `evals/results/` is ignored local campaign output and is not promotion evidence (correctly covered by `.gitignore`).
- `.agent-tasks/` does not currently exist in this workspace (it will be created in pilot projects by the installer). It is not covered by `.gitignore` (see CLAUDE-F-001).

## Recommended next action

Owner should add `.claude/`, `.tmp-phase00-*/`, and `.agent-tasks/` patterns to `.gitignore` to prevent accidental staging of scratch, experiment copies, and operational task state. This is a bounded hygiene fix that does not affect the pilot verdict. After applying the fix, re-run `validate-template.ps1` and update the Round 09–12 evidence manifest to reflect the new `.gitignore` hash. No other corrections are required. Codex should independently reproduce CLAUDE-F-001 and confirm or reject it per the two-party reconciliation protocol.
