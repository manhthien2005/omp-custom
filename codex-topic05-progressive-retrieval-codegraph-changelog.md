# Topic 05 — Progressive Retrieval, CodeGraph, and Cheap Scout

## Outcome

Topic 05 is implemented locally and remains unstaged. CodeGraph is an explicit optional component,
not a default. The official pinned Windows x64 binary passed a disposable no-model smoke, and the
deterministic four-arm campaign produced 54 validated records across nine fixture classes. Because
provider/model usage was not authorized or measured, the campaign conclusion is `inconclusive`,
native retrieval remains the default, and no route is promoted.

## Changed paths by subsystem

- Component/runtime: `template/.omp/codegraph/CODEGRAPH-LICENSE.txt`,
  `template/.omp/codegraph/COMPONENT.md`, `template/.omp/codegraph/upstream-lock.json`,
  `template/.omp/codegraph/component-manifest.json`, `template/.omp/codegraph/safe-init.mjs`,
  `template/.omp/codegraph/codegraph-process.ps1`, and
  `template/.omp/tools/codegraph-retrieve.js`.
- Agent/routing surfaces: `template/.omp/config.yml`, `template/.omp/agents/cheap-scout.md`, and
  `template/.omp/agents/reviewer.md`.
- Provision/install/cleanup: `scripts/lib/topic05-codegraph.ps1`,
  `scripts/provision-codegraph.ps1`, `scripts/cleanup-codegraph.ps1`,
  `scripts/install-template.ps1`, and `scripts/uninstall-template.ps1`.
- Benchmark/validation: `scripts/lib/topic05-benchmark.ps1`,
  `scripts/run-topic05-retrieval-benchmark.ps1`,
  `scripts/lib/topic05-progressive-retrieval.ps1`,
  `scripts/validate-topic05-progressive-retrieval.ps1`, `scripts/validate-template.ps1`, and
  `scripts/lib/phase00-evidence.ps1`.
- Deterministic tests/fixtures: `scripts/tests/topic05-provisioning.Tests.ps1`,
  `scripts/tests/topic05-adapter.Tests.ps1`, `scripts/tests/topic05-tool.Tests.mjs`,
  `scripts/tests/topic05-installer.Tests.ps1`, `scripts/tests/topic05-routing.Tests.ps1`,
  `scripts/tests/topic05-benchmark.Tests.ps1`,
  `scripts/tests/topic05-progressive-retrieval.Tests.ps1`,
  `scripts/tests/fixtures/topic05/fake-codegraph.mjs`, `evals/retrieval/topic05/README.md`, and
  `evals/retrieval/topic05/fixtures.json`.
- Canonical authority: `spec/key/04-decision-log.md`, `spec/key/01-dna.md`,
  `spec/key/03-token-quality-model.md`, `spec/03-agent-topology.md`,
  `spec/05-context-and-token-model.md`, `spec/07-retrieval-and-code-understanding.md`,
  `spec/12-installation-and-rollback.md`, `spec/13-validation-and-evaluation.md`,
  `spec/14-upgradeability-and-governance.md`, `spec/15-security-and-failure-recovery.md`,
  `spec/README.md`, `spec/phases/phase-03-context-efficiency.md`,
  `spec/phases/phase-05-installation-hardening.md`, and `spec/phases/phase-06-evaluation.md`.
- Registries/operator docs: `registry/upstreams.yml`, `registry/adoption-ledger.yml`,
  `registry/rejected-mechanisms.yml`, `README.md`, `docs/retrieval.md`,
  `docs/architecture.md`, `docs/installation.md`, `docs/customization.md`,
  `docs/token-strategy.md`, `docs/security.md`, `docs/rollback.md`, `docs/workflow-v0.md`, and
  `docs/policies/context-budget.md`.
- Design/evidence/handoff: the Topic 05 design and implementation plan under
  `docs/superpowers/`, `docs/evidence/current-product/topic-05/deterministic.json`,
  `docs/evidence/current-product/topic-05/model-campaign.json`,
  `docs/evidence/current-product/topic-05/manifest.json`, `CHANGELOG.md`, and this file.

## Operator commands

Dry-run is the default. Substitute only an exact artifact/path you have inspected.

```powershell
# Offline explicit install preview, then apply
pwsh -NoProfile -File scripts/install-template.ps1 -Target project -ProjectDir <project> `
  -Components state,codegraph -CodeGraphArtifactPath <pinned-artifact>
pwsh -NoProfile -File scripts/install-template.ps1 -Target project -ProjectDir <project> `
  -Components state,codegraph -CodeGraphArtifactPath <pinned-artifact> -DryRun:$false

# Explicit pinned network path instead of an offline artifact
pwsh -NoProfile -File scripts/install-template.ps1 -Target project -ProjectDir <project> `
  -Components state,codegraph -AllowCodeGraphDownload -DryRun:$false

# Restore template-owned files; verified bundle/index data is retained and reported
pwsh -NoProfile -File scripts/uninstall-template.ps1 -Target project -ProjectDir <project> `
  -BackupDir <exact-backup> -DryRun:$false

# Preview/apply exact index cleanup; Confirmation is the canonical worktree root
pwsh -NoProfile -File scripts/cleanup-codegraph.ps1 -Kind index `
  -LiteralPath <worktree>/.codegraph -Confirmation <canonical-worktree-root>
pwsh -NoProfile -File scripts/cleanup-codegraph.ps1 -Kind index `
  -LiteralPath <worktree>/.codegraph -Confirmation <canonical-worktree-root> -Apply

# Preview/apply exact bundle cleanup; use v1.5.0:<platform>:<artifact-sha256>
pwsh -NoProfile -File scripts/cleanup-codegraph.ps1 -Kind bundle `
  -LiteralPath <managed-bundle> -Confirmation <exact-bundle-confirmation>
pwsh -NoProfile -File scripts/cleanup-codegraph.ps1 -Kind bundle `
  -LiteralPath <managed-bundle> -Confirmation <exact-bundle-confirmation> -Apply
```

## Retained data and rollback boundary

- The verified binary bundle remains in the user's managed local CodeGraph cache until explicit
  exact-path cleanup.
- Each worktree owns its physical `.codegraph/` index. Uninstall retains and reports known indexes.
- Cleanup moves only the validated exact bundle/index to recoverable sibling trash; it never scans
  broadly or deletes a Git worktree.
- Operational `agent-tasks` state remains outside installed `.omp` files and is retained.

## Evidence and observed corrections

- Official binary: CodeGraph `v1.5.0`, commit
  `ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6`, Windows x64 artifact SHA-256
  `d6798622b4f44ee6757c94335f437ee27a9ff7d3537b554cb6a2b3baf11bc4a1`.
- Real smoke covered lazy main/linked indexes, wrong-worktree refusal, native absence
  corroboration, source-change invalidation, frozen-candidate refusal, token-free tool discovery,
  rollback, and retained-cache reporting.
- Live smoke corrected four concrete issues: leaked network-copy output, named `CodeGraph` export
  resolution, the actual `codegraph.db` marker, and strict-mode single-file rollback.
- Deterministic campaign: 54 records, nine paired groups, zero exclusions, hard gates PASS,
  efficiency/token use not measured, recommendation `inconclusive`.
- Model campaign: `NOT_RUN` because explicit model spend was not authorized. DeepSeek was not
  probed merely to manufacture a disposition.

## Verification recorded before the final regression gate

- Topic 05 focused validator: 25 PASS, 0 WARN, 0 FAIL.
- Progressive retrieval mutation suite: 28 assertions PASS.
- Benchmark suite: 386 assertions PASS.
- Installer suite after the strict-mode fix: 78 assertions PASS.
- Real-binary smoke and deterministic campaign: PASS without model/provider calls.

## Final regression gate

- Topic 05: provisioning 21 cases PASS; adapter 15 cases PASS; Node tool 10 PASS; installer 78
  assertions PASS; routing 110 assertions PASS; benchmark 386 assertions PASS; progressive
  retrieval 28 assertions PASS; focused validator 25 PASS / 0 WARN / 0 FAIL.
- Topic 02: mutation/self-test 134 assertions PASS; focused validator 604 PASS / 0 WARN / 0 FAIL.
- Topic 03: DeepSeek 12 assertions PASS; topology 20 assertions PASS; installer 8 cases PASS;
  focused validator 22 PASS / 0 WARN / 0 FAIL.
- Topic 04: candidate 35 assertions PASS; transfer 44 assertions PASS; installer/adapter 70
  assertions PASS; end-to-end 18 assertions PASS; focused validator 41 PASS / 0 WARN / 0 FAIL.
- Full template validator: 239 PASS / 2 WARN / 0 FAIL. The two non-failing advisories are the
  pre-existing `RULES.md` approximate budget below 300 and `cheap-scout.md` above 1200.
- JavaScript syntax checks and `git diff --check` passed. Git emitted only the existing Phase 00
  CRLF advisory. The staged path count remained zero.
- Aggregate Phase 00 Pester (the repository has Pester 3.4, so the equivalent `-Script ...
  -EnableExit` entry point was used): 330 PASS / 8 FAIL. The failures are outside Topic 05 and all
  come from the historical E1 product snapshot still expecting nine protected pins and the retired
  `template/.omp/agents/explorer.md`. This is recorded as a predecessor reconciliation follow-up,
  not hidden or reclassified as Topic 05 PASS.

## Acceptance criterion to evidence audit

| Criterion | Owning implementation | Deterministic test | Current evidence field | Canonical authority |
|---|---|---|---|---|
| AC-1 | `scripts/install-template.ps1` + `upstream-lock.json` | `topic05-provisioning.Tests.ps1` | `real_binary_smoke.artifact` | KD-029 + `spec/12-installation-and-rollback.md` |
| AC-2 | `codegraph-process.ps1` + bounded installer | adapter/provisioning suites | `real_binary_smoke.accepted_adapter_runs_disable_telemetry_and_updates` | KD-029 + `spec/15-security-and-failure-recovery.md` |
| AC-3 | `codegraph-retrieve.js` | `topic05-tool.Tests.mjs` | `real_binary_smoke.cases.tool_discovery` | KD-029 + `spec/03-agent-topology.md` |
| AC-4 | `safe-init.mjs` + `codegraph-process.ps1` | adapter worktree/index cases | `main_lazy_index`, `linked_worktree_index`, `shared_index_refusal` | KD-029 + `spec/07-retrieval-and-code-understanding.md` |
| AC-5 | Topic 04 binding in `codegraph-process.ps1` | candidate/source drift cases | `source_mutation_invalidation` + `frozen_candidate_without_index` | KD-029 + `spec/12-installation-and-rollback.md` |
| AC-6 | `cheap-scout.md` closed output overlay | `topic05-routing.Tests.ps1` | manifest-bound routing/test hashes + overall deterministic PASS | KD-029 + `spec/05-context-and-token-model.md` |
| AC-7 | graph-gap/native fallback in wrapper and prompts | absence/fallback cases | `real_binary_smoke.cases.absence_corroboration` | KD-029 + `spec/07-retrieval-and-code-understanding.md` |
| AC-8 | closed adapter reason map + native fallback | adapter and tool failure matrices | mismatch, mutation, and candidate reason-code evidence | KD-029 + `spec/15-security-and-failure-recovery.md` |
| AC-9 | `reviewer.md` independent retrieval contract | routing/progressive suites | manifest-bound Reviewer hash + focused PASS | KD-029 + `spec/03-agent-topology.md` |
| AC-10 | `topic05-benchmark.ps1` + fixture registry | benchmark suite | `deterministic_campaign` counts and comparison | KD-029 + `spec/13-validation-and-evaluation.md` |
| AC-11 | comparison hard gates before efficiency | benchmark mutation suite | `hard_gates_pass=true`, `efficiency_measured=false`, threshold `null` | KD-029 + `spec/key/03-token-quality-model.md` |
| AC-12 | non-promoting comparison report | benchmark/progressive suites | `recommendation=inconclusive`, `promotion=false`, native default | KD-029 + `spec/14-upgradeability-and-governance.md` |

All Topic 05 completion claims are supported by implementation, deterministic tests, current
evidence, and active authority. No files are staged or committed by this handoff.

## Explicit non-goals

- No CodeGraph default enablement or universal promotion.
- No upstream interactive installer, MCP server, hooks, daemon, or auto-update.
- No graph-only truth or graph-only proof of absence.
- No mandatory Cheap Scout spawn and no Reviewer/Verifier authority for Cheap Scout.
- No paid model campaign, provider substitution, Opus requirement, commit, push, or PR.
