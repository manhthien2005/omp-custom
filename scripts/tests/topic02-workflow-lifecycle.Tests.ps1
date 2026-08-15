#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\topic02-workflow-lifecycle.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    Write-Host 'FAIL [T02-TEST-HELPER] focused Topic 02 validator helper is missing' -ForegroundColor Red
    exit 1
}
. $helperPath

$script:assertions = 0

function Assert-NoTopic02Failures {
    param([Parameter(Mandatory)][object[]]$Results, [Parameter(Mandatory)][string]$Scenario)
    $script:assertions++
    $failures = @($Results | Where-Object Status -eq 'FAIL')
    if ($failures.Count -gt 0) {
        throw "[$Scenario] expected zero failures, got: $($failures.Code -join ', ')"
    }
}

function Assert-Topic02FailureCode {
    param([Parameter(Mandatory)][object[]]$Results, [Parameter(Mandatory)][string]$Code, [Parameter(Mandatory)][string]$Scenario)
    $script:assertions++
    $matching = @($Results | Where-Object Code -eq $Code)
    if ($matching.Count -ne 1 -or $matching[0].Status -ne 'FAIL') {
        throw "[$Scenario] expected exactly one FAIL '$Code'"
    }
}

function Set-Topic02FixtureFile {
    param([Parameter(Mandatory)][string]$FixtureRoot, [Parameter(Mandatory)][string]$RelativePath, [Parameter(Mandatory)][AllowEmptyString()][string]$Content)
    $path = Join-Path $FixtureRoot $RelativePath
    $parent = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    Set-Content -LiteralPath $path -Value $Content -Encoding UTF8
}

$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$fixtureRoot = Join-Path $tempBase ("omp-topic02-validator-{0}" -f [guid]::NewGuid().ToString('N'))
$goodFixture = [ordered]@{
    'spec/04-workflow-sizing.md' = @'
Plain natural-language requests are the normal default entry.
This is the user's explicit Quick choice.
The other entry adapters are compatibility hints.
A task begins when its contract is accepted.
A session serves one task and one active candidate lineage.
Any acceptance-bearing mutation invalidates prior evidence.
Orchestrated needs at least two independently verifiable work units.
Parallel writers are optional.
Compaction does not change task or session identity.
Handoff creates a successor session.
The contract locks its required verification and review obligations.
'@
    'spec/key/01-dna.md' = @'
A plain request enters the main-session Tech Lead.
The user makes an explicit Quick choice.
Standard and Orchestrated are selected from task structure.
Orchestrated requires an integration contract.
A candidate snapshot binds acceptance evidence.
Handoff opens a successor session.
Topic 03 owns the final worker graph.
Orchestrated classification alone does not force review.
The task contract locks required verification and review obligations.
Each selected spawned worker with a structured result contract declares its schema.
Discipline attaches to selected completion-claiming responsibilities.
Isolation applies to selected parallel writers.
The selected verification mechanism short-circuits failures to the selected remediation owner.
A selected LSP-consuming path fails closed when its capability conjunction is unmet.
Effective LSP requires all four independent gates: allowlist, task.enableLsp, parent session not disabled and not plan mode, and lsp.enabled.
The four registration gates do not prove that an applicable language server exists or that an LSP call succeeded.
When Context7 is unavailable, record context7_unavailable and disclose the skipped level and reason.
Acceptance requires structuredOutput.status valid; unavailable, invalid, and overridden results are unvalidated.
Returned modelRole and resolvedModel identity comparison catches credential fallback that resolvedModelIsFallback does not mark.
Static validation proves only L0 filesystem and text properties; runtime discovery requires a separate L1 OMP discovery check.
'@
    'docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md' = @'
The accepted task contract includes required verification and review obligations.
'@
    'spec/key/04-decision-log.md' = @'
KD-026 locks required verification and review obligations into the accepted task contract.
KD-006 is superseded as a global rule.
Dispatch syntax follows the effective task-tool schema selected by Topic 03.
Each selected spawned worker whose contract requires a structured result declares it in frontmatter.
L0 validation parses every selected agent `output:` block.
Malformed selected schemas yield structuredOutput.status unavailable and fail acceptance.
Selected per-spawn effort requires task.enableEffort true.
A forced softRequestBudget stop returns a partial yield that cannot satisfy completion.
The coordinator rejects any result with resolvedModelIsFallback true.
resolvedModelIsFallback marks retry fallback only; credential fallback and task.agentModelOverrides require exact returned identity comparison.
Plan mode is a distinct planning-only contract and cannot satisfy selected mutation or fresh-command work.
The four LSP registration gates do not authorize acceptance when no applicable language server exists or a required LSP call returns details.success false.
'@
    'spec/key/03-token-quality-model.md' = @'
The task cycle starts when the task contract is accepted.
Evidence binds to one candidate snapshot and is invalid after mutation.
Accepted, cancelled, and terminally_blocked are terminal task outcomes.
accepted_with_waiver remains outside the validated denominator.
Never remove required independent verification because the candidate author reported success.
All role names below are frozen-baseline examples, not topology authority.
A selected exact-output verification responsibility may justify unsummarized reads.
A selected LSP-consuming responsibility receives LSP only when its contract consumes it.
Effective LSP requires all four independent gates: allowlist, task.enableLsp, parent session not disabled and not plan mode, and lsp.enabled.
An LSP tool result with details.success false is a failed capability result, not symbol-aware evidence.
Treat a partial yield as a partial result rather than a completion.
Model identity is observable only by comparing returned modelRole and resolvedModel; resolvedModelIsFallback covers retry fallback but not credential fallback.
'@
    'spec/03-agent-topology.md' = @'
Topic 02 owns workflow classification.
Topology does not redefine workflow classification.
Topic 03 owns the worker graph and dispatch choices.
'@
    'spec/05-context-and-token-model.md' = @'
Compaction preserves the current task, candidate lineage, and session identity.
Handoff creates a successor session.
The successor must reconcile the contract and workspace before mutation.
Never skip required independent verification because the candidate author reported success.
All role names below are frozen-baseline examples, not topology authority.
A selected exact-output verification responsibility may justify unsummarized reads.
Offload safety follows effective isolation and artifact-retention responsibility, independent of workflow name.
context7_unavailable is the disclosed named skip when level 4 is unavailable.
A forced softRequestBudget partial yield is nonterminal and requires recovery or redispatch.
web_unavailable is disclosed when level 5 is unavailable; a freshness contract remains unresolved and cannot be accepted without authoritative evidence.
'@
    'spec/08-isolation-and-concurrency.md' = @'
Parallel execution and parallel writers are optional.
Sequential execution remains Orchestrated when the work-unit integration structure exists.
Parallel-writer preconditions apply only when that path is selected.
Every selected stage-barrier worker preserves its barrier.
Batching gates only the conditional parallel-batch path.
Recursion depth constrains any selected topology.
Isolation rules refer to selected observation roles.
Optional support agents are excluded from the selected worker-set comparison.
Plan mode selects a distinct planning-only contract; selected mutation and fresh-command contracts stop before dispatch or acceptance.
Selected nested delegation requires remaining task.maxRecursionDepth; a result from a worker whose task tool was stripped cannot satisfy that contract.
'@
    'spec/10-verification-and-review.md' = @'
Review remains contract and risk gated.
Orchestrated classification alone does not force a reviewer.
Topic 03 owns the verification mechanism.
A named Verifier is not mandatory.
Any selected command-executing verification role requires its effective command tool.
Every selected stage-barrier worker must block until its evidence exists.
This is the same selected-path fail-closed principle as LSP.
'@
    'spec/13-validation-and-evaluation.md' = @'
Acceptance evidence binds to an immutable candidate snapshot.
Accepted, cancelled, and terminally_blocked are terminal task outcomes.
partial, blocked, waiting_for_user, and rework are nonterminal observations.
accepted_with_waiver remains excluded from the validated denominator.
Discovery consumes the Topic 03-selected topology manifest.
Every selected stage-barrier worker preserves its required blocking contract.
Isolation checks apply only to the conditional parallel path.
Discovery validates the skill set declared by the selected runtime manifest.
Adversarial false-success fixtures exercise the selected non-author verification mechanism.
A selected LSP-consuming path fails closed when its effective conjunction is unmet.
A different contract that does not consume LSP must be selected and validated before continuation.
L1 rejects selected LSP acceptance when no applicable language server exists or any required LSP call returns details.success false.
L0 fully lints every selected structured-result schema before dispatch.
Acceptance requires structuredOutput.status valid; unavailable, invalid, and overridden results are unvalidated.
L4 forces a softRequestBudget partial yield and proves that it cannot satisfy completion.
Effective retry.modelFallback is true solely for the named Cheap Scout chain, retry.usageAwareFallback is false, and default/Worker/Reviewer chains are empty.
L1 reconciles task.agentModelOverrides; Worker/Reviewer acceptance compares returned modelRole and resolvedModel with the expected identity.
Plan mode cannot satisfy a selected mutation or fresh-command contract; L4 proves that a plausible read-only yield is rejected.
L1 checks effective glob.enabled, grep.enabled, astGrep.enabled, and web_search.enabled only for selected consumers.
web_unavailable leaves a freshness contract unresolved and unable to satisfy acceptance without authoritative evidence.
L1 checks task.maxEffort against selected exact effort and verifies the returned resolvedModel effort suffix.
Selected nested delegation must have remaining task.maxRecursionDepth; stripped task capability cannot satisfy acceptance.
'@
    'spec/14-upgradeability-and-governance.md' = @'
Governance consumes the Topic 03-selected topology manifest.
Former worker names and counts are non-authoritative baseline examples.
All selected worker definitions depend on accepted frontmatter keys.
Selected skill-autoload consumers depend on autoloadSkills injection.
Selected isolation paths depend on the isolation backend contract.
The LSP four-gate conjunction is a watched governance claim backed by tools/index.ts.
Applicable-language-server routing and LSP details.success are watched governance claims backed by lsp/index.ts.
The grep, glob, ast_grep, and web_search setting gates are watched governance claims backed by tools/index.ts.
'@
    'spec/README.md' = @'
A plain request is the normal workflow entry.
Slash forms for Standard and Orchestrated are compatibility hints.
Topic 03 owns topology, Topic 04 owns durable lifecycle state, and Topic 08 owns deeper triage.
Runtime projection is scheduled in Phase 02.
All role-specific choices below are non-authoritative migration history.
DR-8 is Reopened by KD-026 and Topic 03.
Selected concurrent writers are isolated only when selected by the manifest.
Source facts enumerate all four independent LSP gates: allowlist, task.enableLsp, parent session not disabled and not plan mode, and lsp.enabled.
E2 closed the model-role question: unresolved aliases and unavailable models hard-fail without fallback, and project values win.
Phase 01, Phase 03, and Phase 05 may implement settings they explicitly own as selected-contract prerequisites.
Those settings remain provisional candidates until Phase 06 evaluates them; unowned or speculative settings changes remain frozen.
'@
    'spec/01-target-architecture.md' = @'
The Topic 03-selected topology manifest is the only authority for worker names and count.
Selected completion-claiming roles receive the evidence discipline they consume.
Each selected spawned worker carries its own enforceable result contract.
Effective subagent LSP uses a four-condition conjunction: allowlist, task.enableLsp, parent session not disabled and not plan mode, and lsp.enabled.
The four registration gates establish LSP tool presence only; selected symbol-aware work also requires an applicable working language server and successful required LSP calls.
Selected model-role aliases fail closed with no fallback, and project configuration wins precedence.
Selected-model preflight reconciles task.agentModelOverrides before dispatch.
Acceptance compares returned modelRole and resolvedModel with the reconciled expected identity; any mismatch fails even when resolvedModelIsFallback is false.
Every selected structured-result schema is fully linted; acceptance requires structuredOutput.status valid.
Static validation proves only L0 filesystem and text properties; runtime discovery requires a separate L1 OMP discovery check.
'@
    'spec/02-runtime-semantics.md' = @'
Source-verified LSP availability is a four-condition conjunction: allowlist, task.enableLsp, parent session not disabled and not plan mode, and lsp.enabled.
All four effective gates are source-verified independently.
A registered LSP tool may still return details.success false when no language server applies; that result cannot satisfy a selected symbol-aware contract.
OQ-3 is closed by pinned source: child depth 1 retains task, while child depth 2 reaches the default maxRecursionDepth and loses task.
E2 proves missing or unknown aliases and unavailable models fail with no fallback; project configuration wins.
Former worker names and counts below describe the frozen Phase 00 baseline only; they are runtime observations, not topology authority.
The Topic 03-selected manifest owns current worker names and count; Phase 02 owns runtime projection.
'@
    'spec/06-structured-output.md' = @'
Topic 03-selected worker contracts determine which schemas and producers exist.
The former four-role mapping is non-authoritative migration input.
Each selected spawned worker with a structured result contract declares output frontmatter.
Selected responsibility contracts may diverge when their result shapes differ.
Every selected structured-result schema is fully linted before dispatch.
Acceptance requires structuredOutput.status valid; unavailable, invalid, and overridden results are unvalidated.
'@
    'spec/07-retrieval-and-code-understanding.md' = @'
Capabilities are assigned only to selected LSP-consuming roles.
The former role table is non-authoritative migration input.
When no selected contract consumes LSP, installation does not require it.
For each selected contract that consumes symbol-aware retrieval, its selected consumer receives LSP.
A selected LSP-consuming path must stop before dispatch or acceptance when its capability conjunction is unmet.
Continuation requires an explicit different contract that does not consume LSP, followed by reconciliation and validation.
The four-gate conjunction is allowlist membership, task.enableLsp == true, parent session LSP enabled and not plan mode, and lsp.enabled == true.
The four gates establish tool registration only; selected symbol-aware retrieval additionally requires an applicable working language server and successful required calls.
No language server found for this file and any details.success false result fail the selected LSP contract.
context7_unavailable is a permitted skip reason and must be disclosed with the skipped level.
Every selected grep, glob, ast_grep, or web_search consumer requires its matching effective setting true.
An unmet selected retrieval capability stops before dispatch or acceptance unless a different contract is reconciled and revalidated.
web_unavailable is the named disclosed reason for an unavailable level 5; a freshness-specific contract remains unresolved without authoritative evidence.
'@
    'spec/09-model-routing.md' = @'
Only model-role aliases referenced by the Topic 03-selected topology manifest are required.
The former four-role routing table is non-authoritative migration input.
E2 proves missing or unknown aliases and unavailable models hard-fail with no fallback, while project values win precedence.
Any selected per-spawn effort path requires effective task.enableEffort true and fails before dispatch otherwise.
Selected model identity requires effective retry.modelFallback false and retry.usageAwareFallback false; resolvedModelIsFallback true fails acceptance.
Effective selected-model preflight reconciles task.agentModelOverrides before dispatch.
Acceptance compares returned modelRole and resolvedModel with the reconciled expected identity; any mismatch fails even when resolvedModelIsFallback is false.
Selected exact effort requires task.maxEffort at least the requested level, and acceptance confirms the resolvedModel effort suffix matches the expected effective effort.
'@
    'spec/11-skills-rules-and-quality-gates.md' = @'
Selected completion-claiming roles autoload the evidence discipline.
The former role table is non-authoritative migration input.
Each selected gate-applier receives only the gate contract it consumes.
Validation covers the skill set selected by the runtime manifest.
Every selected spawned role whose contract consumes an autoloaded discipline declares it.
'@
    'spec/12-installation-and-rollback.md' = @'
Owned model-role keys are derived from the Topic 03-selected topology manifest.
Settings are installed only for selected LSP-consuming roles.
Isolation settings are owned only for a selected conditional parallel-writer path.
The selected LSP-consuming path remains disabled while any required gate is unmet.
Continuation requires an explicit different contract that does not consume LSP and revalidation.
Selected LSP installation acceptance probes applicable language-server routing and treats details.success false as a failed capability result.
Selected per-spawn effort makes task.enableEffort true and task.maxEffort xhigh owned prerequisites and fails preflight when either is not effective.
KD-027 selected routing owns retry.modelFallback true, retry.usageAwareFallback false, one Cheap-Scout-only Pro chain, and empty default/Worker/Reviewer chains.
Selected-model preflight reconciles task.agentModelOverrides and rejects an unselected effective override.
Selected grep, glob, ast_grep, and web_search consumers own matching project settings and fail preflight when ineffective.
Selected exact-effort consumers own a sufficient task.maxEffort ceiling, and selected nested delegation preflights task.maxRecursionDepth.
'@
    'spec/15-security-and-failure-recovery.md' = @'
Security policy applies to all selected bash-capable roles.
A selected discovery role returns evidence as untrusted data.
Failure loops return to the selected remediation owner.
False completion is checked by the selected non-author verification mechanism.
Missing or unknown aliases and unavailable models fail with no fallback.
A forced softRequestBudget partial yield remains nonterminal and cannot satisfy acceptance.
Any result with resolvedModelIsFallback true is rejected.
Returned modelRole and resolvedModel must match the reconciled expected identity because credential fallback is not marked by resolvedModelIsFallback.
'@
    'spec/16-migration-plan.md' = @'
Runtime migration consumes the Topic 03-selected topology manifest.
The former agent-file rows are non-authoritative baseline inventory.
The runtime agent file set is derived from the selected manifest.
'@
    'spec/phases/phase-01-runtime-correctness.md' = @'
Runtime migration consumes the Topic 03-selected topology manifest.
Every selected LSP-consuming worker receives the capability it consumes.
Every selected stage-barrier worker declares blocking behavior.
The installed project-worker set exactly matches the Topic 03-selected topology manifest.
Each selected spawned worker whose contract requires structured output declares its schema.
Deliverables update selected worker adapters and selected command contracts.
The selected LSP-consuming path must fail closed when any required condition is unavailable.
Continuation requires a different contract that does not consume LSP and explicit revalidation.
Runtime validation rejects the selected LSP path when no applicable language server exists or a required call reports details.success false.
Every selected structured-result schema is fully linted before dispatch, and acceptance requires structuredOutput.status valid.
'@
    'spec/phases/phase-02-core-orchestration.md' = @'
Migrate runtime prompts from the Phase 00 snapshot to the Topic 02 contract.
Implement no-prefix entry, explicit Quick, and Tech-Lead selection of Standard or Orchestrated.
Orchestrated requires independently verifiable work units and an integration contract.
Preserve historical Phase 00 evidence; create new current-product validation evidence.
When a selected dispatch uses effort, task.enableEffort must be effective or that path stops before dispatch.
Malformed schemas and any structuredOutput status other than valid cannot satisfy acceptance.
'@
    'spec/phases/phase-03-context-efficiency.md' = @'
Compaction preserves session identity and cannot become lifecycle authority.
Handoff creates a reconciled successor session for the same task and candidate lineage.
Durable lifecycle state remains owned by Topic 04.
Packets use file references from selected retrieval roles.
Inspect a selected verification result for compact evidence.
Retrieval uses bounded escalation; a named permitted skip is valid and disclosed.
'@
    'spec/phases/phase-04-quality-system.md' = @'
The selected verification mechanism obtains fresh evidence from a non-author.
A separate AgentSession is one permitted mechanism, not a permanent role requirement.
Unavailable, invalid, and overridden structured results are unvalidated and cannot satisfy acceptance.
'@
    'spec/phases/phase-05-installation-hardening.md' = @'
Owned model-role keys are derived from the Topic 03-selected topology manifest.
Acceptance covers selected aliases and optional settings consumed by the manifest.
Install prerequisites are conditional on the selected runtime path.
The selected LSP-consuming path remains disabled while any required condition is unavailable.
Continuation requires a different contract that does not consume LSP and explicit revalidation.
Installation acceptance probes applicable language-server routing for selected file types and treats details.success false as failure.
Selected effort consumers own task.enableEffort true and task.maxEffort xhigh as conditional prerequisites.
KD-027 owns retry.modelFallback true, retry.usageAwareFallback false, one Cheap-Scout-only Pro chain, and empty default/Worker/Reviewer chains.
Selected retrieval consumers own matching grep, glob, ast_grep, and web_search project settings.
Selected exact effort owns a sufficient task.maxEffort ceiling; selected nested delegation validates task.maxRecursionDepth before dispatch.
'@
    'spec/phases/phase-06-evaluation.md' = @'
Evaluate plain entry, explicit Quick, compatibility hints, and internal reclassification.
Evaluate candidate mutation invalidation, handoff reconciliation, and Orchestrated integration.
Cheap Scout retryable availability/runtime failure follows Flash xhigh to Pro xhigh to Tech Lead retrieval without lifecycle side effects.
L0 and L1 consume the Topic 03-selected topology manifest and its selected worker set.
Isolation and batching checks apply only to the conditional parallel path.
For false success, the selected non-author verification mechanism must contradict the author.
Every selected structured-result producer carries the contract required by the manifest.
Discovery validates the skill set declared by the selected runtime manifest.
Evaluation proves the selected LSP-consuming path fails closed when its conjunction is unmet.
A replacement contract that does not consume LSP must be explicit and revalidated.
L4 covers registered LSP with no applicable language server and rejects every required LSP result whose details.success is false.
L0 implements CR-41 separately and rejects task.enableLsp true with lsp.enabled false.
L0 fully lints every selected structured-result schema before dispatch.
Acceptance requires structuredOutput.status valid.
L1 requires effective task.enableEffort true and task.maxEffort xhigh for selected exact effort paths.
Missing aliases and an unavailable selected target hard-fail; KD-027 separately validates the explicit Scout runtime retry chain.
L4 forces a softRequestBudget partial yield and proves it cannot satisfy completion.
L1 requires retry.modelFallback true, retry.usageAwareFallback false, a Scout chain containing only Pro xhigh, and empty default/Worker/Reviewer chains.
L1 reconciles task.agentModelOverrides and rejects a Worker/Reviewer returned modelRole or resolvedModel mismatch, including unflagged credential fallback.
Plan mode requires a distinct planning-only contract and rejects selected mutation or fresh-command paths before dispatch or acceptance.
L1 checks effective glob.enabled, grep.enabled, astGrep.enabled, and web_search.enabled for selected consumers and fails closed when unmet.
web_unavailable is disclosed and a freshness contract cannot pass without authoritative evidence.
L1 checks task.maxEffort and the returned resolvedModel effort suffix for selected exact effort.
L1 rejects selected nested delegation when task.maxRecursionDepth would strip the task tool.
'@
    'docs/policies/model-routing.md' = @'
Topic 03-selected aliases are the only required routing set.
E2 is closed: missing or unknown aliases and unavailable models hard-fail with no fallback.
Project configuration values win over global values.
Selected model identity rejects resolvedModelIsFallback true.
'@
    'docs/research/authority-map.md' = @'
Authority boundary: This research file is source/research evidence.
Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology, dispatch, review mechanism, or capability behavior.
Current design and execution authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest.
Historical research input only; no current design, execution, routing, fallback, topology, or capability authority.
Current authority lives in the accepted design, key decisions, active specs, and Topic 03-selected manifest.
'@
    'docs/research/mechanism-matrix.md' = @'
Authority boundary: This research file is source/research evidence.
Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology, dispatch, review mechanism, or capability behavior.
Current design and execution authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest.
Historical research input only; no current design, execution, routing, fallback, topology, or capability authority.
ADOPT and ADAPT labels below record an earlier research pass and do not select current runtime behavior.
'@
    'docs/research/conflict-matrix.md' = @'
Authority boundary: This research file is source/research evidence.
Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology, dispatch, review mechanism, or capability behavior.
Current design and execution authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest.
Historical Phase 2 conflict-resolution snapshot only; no current design, execution, topology, review, routing, or capability authority.
Current authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest.
'@
    'registry/adoption-ledger.yml' = @'
# Historical adoption-provenance ledger only; adopted_to paths, role names, and rationales do not select current topology, dispatch, review, or capability behavior.
# Current authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest.
'@
    'spec/key/02-repo-synthesis.md' = @'
Former fixed worker names and counts are historical research examples; Topic 03-selected responsibilities are the only current topology input.
Each selected responsibility names the distinct context it isolates; no worker count is selected here.
'@
    'spec/key/repos/_CONTRACT.md' = @'
Every repository report repeats its own authority boundary; a folder-level notice is insufficient.
'@
    'spec/key/repos/sample.md' = @'
Authority boundary: This repository report is source/research evidence.
Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology, dispatch, review mechanism, or capability behavior.
Current design and execution authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest.
'@
    'spec/key/dossiers/sample.md' = @'
Authority boundary: This dossier is source/research evidence.
Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology, dispatch, review mechanism, or capability behavior.
Current design and execution authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest.
'@
    'spec/key/repos/serena.md' = @'
Authority boundary: This repository report is source/research evidence.
Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology, dispatch, review mechanism, or capability behavior.
Current design and execution authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest.
If LSP is unavailable, continuation requires an explicit different contract that does not consume LSP, followed by reconciliation and validation.
'@
    'spec/key/dossiers/retrieval-cluster.md' = @'
Authority boundary: This dossier is source/research evidence.
Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology, dispatch, review mechanism, or capability behavior.
Current design and execution authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest.
Context7 unavailability uses the named reason context7_unavailable and discloses the skipped level.
Current retrieval authority is spec/07 section B-1: bounded escalation with named permitted skips.
'@
    'spec/key/06-investment-thesis.md' = @'
Former fixed-role routing examples are historical hypotheses; selected model responsibilities come only from the Topic 03 manifest.
E2 supersedes the earlier fall-through hypothesis: missing and unknown aliases hard-fail before session creation, and unavailable models surface an error with no fallback.
Project role values override global values.
resolvedModelIsFallback does not mark credential fallback; acceptance compares returned modelRole and resolvedModel with the expected identity.
Read resolvedModelIsFallback and compare exact returned identity in the acceptance check.
Differentiate two selected responsibility classes and measure.
'@
    'spec/key/05-coverage-audit.md' = @'
Former fixed-role topology statements below are historical audit observations, not current topology authority.
Current topology and review behavior derive from the accepted design, active specs, phase plans, and Topic 03-selected manifest.
resolvedModelIsFallback detects retry fallback only; credential fallback requires returned modelRole and resolvedModel identity comparison.
Malformed schemas and non-valid structured outputs fail acceptance.
A selected subagent verification mechanism is incompatible with the injected prohibition on subagent verification.
L1 compares the Topic 03-selected worker set and reports foreign discovered agents separately.
'@
    'docs/research/final-adoption-plan.md' = @'
Authority boundary: This research file is source/research evidence.
Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology, dispatch, review mechanism, or capability behavior.
Current design and execution authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest.
Historical Phase 2 snapshot only; no current design or implementation authority.
Current behavior derives from the accepted design, key decisions, active specs, and Topic 03-selected manifest.
'@
    'docs/final-report.md' = @'
Historical Phase 8 snapshot only; no current architecture, completion, topology, or capability authority.
Current status derives from active specs, phase plans, evidence, and the Topic 03-selected manifest.
'@
    'registry/rejected-mechanisms.yml' = @'
Serena remains excluded as a second runtime. A selected OMP LSP or native-search contract runs only when its effective tool and settings conjunction passes; otherwise it fails closed or selects and revalidates a different contract.
Independent review is selected by the accepted task contract and risk; Orchestrated classification alone does not mandate a Reviewer or worker dispatch.
'@
    'registry/upstreams.yml' = @'
Serena default integration is excluded as a second runtime; selected OMP retrieval capabilities remain conditional on their effective tool and settings conjunction.
Source-provenance registry only; derived_into paths and former role names do not select current topology, dispatch, review, routing, or capability behavior.
'@
    'docs/workflow-v0.md' = @'
Historical Workflow v0 snapshot only; no current topology, dispatch, review, routing, or lifecycle authority.
Current authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest.
'@
    'docs/report-design.md' = @'
Historical Workflow v0 snapshot only; no current topology, dispatch, review, routing, or lifecycle authority.
Current authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest.
'@
    'docs/architecture.md' = @'
Architecture — Current Topic 03 Runtime
Plain requests enter the main-session Tech Lead; the default is inline work with no spawn.
OMP discovers exactly three custom agents.
'@
    'docs/customization.md' = @'
Current Topic 03 guide.
The selected custom-agent manifest is `cheap-scout`, `worker`, and `reviewer`; the Tech Lead remains the main session.
Cheap Scout owns only read-only retrieval.
'@
    'docs/rollback.md' = @'
Frozen Phase 00 runtime guide; role and file examples describe the installed baseline only and do not select the Topic 03 topology or authorize runtime migration.
Phase 02 performs runtime migration only after Topic 03 selects the manifest.
'@
    'docs/token-strategy.md' = @'
Selected independent verification mechanism | Independent verification prevents false-completion acceptance
Independent review on every Quick task is unnecessary token cost unless the accepted task contract and risk require it.
'@
    'docs/policies/quality-gates.md' = @'
The main session selects gates; the task packet carries names; the selected gate-applier applies only those names.
The selected gate-applier may report a missing gate as a scoped finding but does not expand its own review contract.
This matrix does not decide whether independent review is selected. Review remains task-contract and risk-gated; Orchestrated classification alone does not mandate a Reviewer or worker dispatch.
'@
}

try {
    [void](New-Item -ItemType Directory -Path $fixtureRoot)
    foreach ($entry in $goodFixture.GetEnumerator()) {
        Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath $entry.Key -Content $entry.Value
    }

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'template/.omp/commands/quick.md' -Content 'restart as Standard'
    Assert-NoTopic02Failures -Results @(Test-Topic02WorkflowLifecycleContract -RepositoryRoot $fixtureRoot) -Scenario 'compliant-spec-phase-fixture'

    $wrapped = $goodFixture['spec/04-workflow-sizing.md'].Replace("This is the user's explicit Quick choice", "This is the user's" + [Environment]::NewLine + 'explicit Quick choice')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/04-workflow-sizing.md' -Content $wrapped
    Assert-NoTopic02Failures -Results @(Test-Topic02CanonicalContract -RepositoryRoot $fixtureRoot) -Scenario 'wrapped-quick-semantic'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/04-workflow-sizing.md' -Content $goodFixture['spec/04-workflow-sizing.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/03-agent-topology.md' -Content ($goodFixture['spec/03-agent-topology.md'].Replace('does not redefine', 'does not' + [Environment]::NewLine + 'redefine'))
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/08-isolation-and-concurrency.md' -Content ($goodFixture['spec/08-isolation-and-concurrency.md'].Replace('Sequential execution remains', 'Sequential execution' + [Environment]::NewLine + 'remains').Replace('preconditions apply only', 'preconditions apply' + [Environment]::NewLine + 'only'))
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/13-validation-and-evaluation.md' -Content ($goodFixture['spec/13-validation-and-evaluation.md'].Replace('accepted_with_waiver remains', 'accepted_with_waiver' + [Environment]::NewLine + 'remains'))
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content ($goodFixture['spec/phases/phase-06-evaluation.md'].Replace('compatibility hints, and internal reclassification', 'compatibility hints,' + [Environment]::NewLine + 'and internal reclassification'))
    Assert-NoTopic02Failures -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Scenario 'wrapped-architecture-semantics'
    Assert-NoTopic02Failures -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Scenario 'wrapped-phase-semantics'
    foreach ($relative in @('spec/03-agent-topology.md','spec/08-isolation-and-concurrency.md','spec/13-validation-and-evaluation.md','spec/phases/phase-06-evaluation.md')) {
        Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath $relative -Content $goodFixture[$relative]
    }

    $wrappedLspFailure = $goodFixture['spec/key/01-dna.md'].Replace('A selected LSP-consuming path fails closed', 'A selected LSP-consuming' + [Environment]::NewLine + 'path fails closed')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content $wrappedLspFailure
    Assert-NoTopic02Failures -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Scenario 'wrapped-lsp-fail-closed-semantic'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content $goodFixture['spec/key/01-dna.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content ($goodFixture['spec/key/01-dna.md'] + [Environment]::NewLine + 'The user picks the size.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DNA-BAN-1' -Scenario 'stale-user-sizing'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content $goodFixture['spec/key/01-dna.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content ($goodFixture['spec/key/01-dna.md'] + [Environment]::NewLine + 'Each worker declares its own result schema.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DNA-BAN-7' -Scenario 'fixed-dna-schema-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content $goodFixture['spec/key/01-dna.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content ($goodFixture['spec/key/01-dna.md'] + [Environment]::NewLine + 'Assigned to `implementer`, `verifier`, `diff-reviewer`.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DNA-BAN-8' -Scenario 'fixed-dna-skill-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content $goodFixture['spec/key/01-dna.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content ($goodFixture['spec/key/01-dna.md'] + [Environment]::NewLine + '| `implementer` (parallel, Orchestrated) | **`true`** |')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DNA-BAN-9' -Scenario 'fixed-dna-isolation-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content $goodFixture['spec/key/01-dna.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content ($goodFixture['spec/key/01-dna.md'] + [Environment]::NewLine + 'FAIL short-circuits back to Implementer.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DNA-BAN-10' -Scenario 'fixed-dna-remediation-role'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content $goodFixture['spec/key/01-dna.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content ($goodFixture['spec/key/01-dna.md'] + [Environment]::NewLine + 'A selected LSP-consuming path may continue with grep in reduced-capability mode.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DNA-BAN-11' -Scenario 'dna-lsp-fail-open'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content $goodFixture['spec/key/01-dna.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content ($goodFixture['spec/key/01-dna.md'] + [Environment]::NewLine + 'Both gates apply (`lsp/index.ts:1639` + allowlist).')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DNA-BAN-12' -Scenario 'dna-two-gate-lsp-model'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content $goodFixture['spec/key/01-dna.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content ($goodFixture['spec/key/01-dna.md'] + [Environment]::NewLine + 'Agents must fall back to level 3 silently when Context7 is absent.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DNA-BAN-13' -Scenario 'dna-context7-silent-fallback'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content $goodFixture['spec/key/01-dna.md']

    $wrappedRepoAuthority = $goodFixture['spec/key/repos/sample.md'].Replace('Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology, dispatch, review mechanism, or capability behavior.', 'Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology,' + [Environment]::NewLine + '> dispatch, review mechanism, or capability behavior.').Replace('Current design and execution authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest.', 'Current design and execution authority lives in the accepted design, key decisions, active' + [Environment]::NewLine + '> specs, phase plans, and Topic 03-selected manifest.')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/repos/sample.md' -Content $wrappedRepoAuthority
    Assert-NoTopic02Failures -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Scenario 'wrapped-markdown-authority-boundary'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/repos/sample.md' -Content $goodFixture['spec/key/repos/sample.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/04-decision-log.md' -Content ($goodFixture['spec/key/04-decision-log.md'] + [Environment]::NewLine + 'Every dispatch in every command file uses the batch wire form.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DECISION-BAN-1' -Scenario 'global-batch-dispatch-rule'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/04-decision-log.md' -Content $goodFixture['spec/key/04-decision-log.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/04-decision-log.md' -Content ($goodFixture['spec/key/04-decision-log.md'] + [Environment]::NewLine + 'Each worker declares its result schema in its own frontmatter.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DECISION-BAN-2' -Scenario 'fixed-decision-schema-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/04-decision-log.md' -Content $goodFixture['spec/key/04-decision-log.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/04-decision-log.md' -Content ($goodFixture['spec/key/04-decision-log.md'] + [Environment]::NewLine + 'L0 validation parses every agent `output:` block.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DECISION-BAN-4' -Scenario 'fixed-decision-schema-lint-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/04-decision-log.md' -Content $goodFixture['spec/key/04-decision-log.md']

    $missingVerificationLock = $goodFixture['spec/04-workflow-sizing.md'].Replace('The contract locks its required verification and review obligations.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/04-workflow-sizing.md' -Content $missingVerificationLock
    Assert-Topic02FailureCode -Results @(Test-Topic02CanonicalContract -RepositoryRoot $fixtureRoot) -Code 'T02-CANONICAL-REQ-11' -Scenario 'missing-verification-contract-lock'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/04-workflow-sizing.md' -Content $goodFixture['spec/04-workflow-sizing.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content ($goodFixture['spec/key/01-dna.md'] + [Environment]::NewLine + 'The gene is four workers at depth 1.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DNA-BAN-4' -Scenario 'stale-fixed-dna-topology'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content $goodFixture['spec/key/01-dna.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/10-verification-and-review.md' -Content ($goodFixture['spec/10-verification-and-review.md'] + [Environment]::NewLine + 'Reviewer runs always in Orchestrated.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-REVIEW-BAN-1' -Scenario 'stale-orchestrated-review-rule'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/10-verification-and-review.md' -Content $goodFixture['spec/10-verification-and-review.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/10-verification-and-review.md' -Content ($goodFixture['spec/10-verification-and-review.md'] + [Environment]::NewLine + '## Why Verification Is a Separate Agent')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-REVIEW-BAN-2' -Scenario 'permanent-named-verifier'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/10-verification-and-review.md' -Content $goodFixture['spec/10-verification-and-review.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/10-verification-and-review.md' -Content ($goodFixture['spec/10-verification-and-review.md'] + [Environment]::NewLine + 'This is not a reduced-capability mode like LSP unavailability.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-REVIEW-BAN-6' -Scenario 'stale-lsp-reduced-capability-comparison'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/10-verification-and-review.md' -Content $goodFixture['spec/10-verification-and-review.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/05-context-and-token-model.md' -Content ($goodFixture['spec/05-context-and-token-model.md'] + [Environment]::NewLine + 'Skipping the Verifier because the Implementer reported success.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-CONTEXT-BAN-1' -Scenario 'named-verifier-token-rule'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/05-context-and-token-model.md' -Content $goodFixture['spec/05-context-and-token-model.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/03-token-quality-model.md' -Content ($goodFixture['spec/key/03-token-quality-model.md'] + [Environment]::NewLine + 'Skip the Verifier because the Implementer said it passed.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-METRIC-BAN-2' -Scenario 'named-verifier-metric-rule'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/03-token-quality-model.md' -Content $goodFixture['spec/key/03-token-quality-model.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/03-token-quality-model.md' -Content ($goodFixture['spec/key/03-token-quality-model.md'] + [Environment]::NewLine + 'Decision: ADOPT for explorer, implementer, reviewer.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-METRIC-BAN-4' -Scenario 'fixed-lsp-token-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/03-token-quality-model.md' -Content $goodFixture['spec/key/03-token-quality-model.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/03-token-quality-model.md' -Content ($goodFixture['spec/key/03-token-quality-model.md'] + [Environment]::NewLine + 'If detail is lost, restore it for the Verifier only.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-METRIC-BAN-3' -Scenario 'fixed-token-role-tuning'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/03-token-quality-model.md' -Content $goodFixture['spec/key/03-token-quality-model.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/05-context-and-token-model.md' -Content ($goodFixture['spec/05-context-and-token-model.md'] + [Environment]::NewLine + 'If detail is lost, restore it for the Verifier only.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-CONTEXT-BAN-2' -Scenario 'fixed-context-role-tuning'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/05-context-and-token-model.md' -Content $goodFixture['spec/05-context-and-token-model.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/05-context-and-token-model.md' -Content ($goodFixture['spec/05-context-and-token-model.md'] + [Environment]::NewLine + 'Standard workflow only')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-CONTEXT-BAN-3' -Scenario 'workflow-name-offload-gate'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/05-context-and-token-model.md' -Content $goodFixture['spec/05-context-and-token-model.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/05-context-and-token-model.md' -Content ($goodFixture['spec/05-context-and-token-model.md'] + [Environment]::NewLine + 'non-isolated (Standard) workers')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-CONTEXT-BAN-4' -Scenario 'standard-only-task-artifacts'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/05-context-and-token-model.md' -Content $goodFixture['spec/05-context-and-token-model.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/05-context-and-token-model.md' -Content ($goodFixture['spec/05-context-and-token-model.md'] + [Environment]::NewLine + 'When Context7 is unavailable, fall back silently.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-CONTEXT-BAN-5' -Scenario 'context-model-silent-context7-skip'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/05-context-and-token-model.md' -Content $goodFixture['spec/05-context-and-token-model.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/06-structured-output.md' -Content ($goodFixture['spec/06-structured-output.md'] + [Environment]::NewLine + 'Explorer and Implementer share `agent-result`.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-OUTPUT-BAN-3' -Scenario 'fixed-output-role-pair'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/06-structured-output.md' -Content $goodFixture['spec/06-structured-output.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/06-structured-output.md' -Content ($goodFixture['spec/06-structured-output.md'] + [Environment]::NewLine + 'Each worker declares its result contract in its own file.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-OUTPUT-BAN-4' -Scenario 'unconditional-output-contract'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/06-structured-output.md' -Content $goodFixture['spec/06-structured-output.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/08-isolation-and-concurrency.md' -Content ($goodFixture['spec/08-isolation-and-concurrency.md'] + [Environment]::NewLine + 'The flat topology in `03-agent-topology.md` mandatory.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-ISOLATION-BAN-2' -Scenario 'fixed-isolation-topology'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/08-isolation-and-concurrency.md' -Content $goodFixture['spec/08-isolation-and-concurrency.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/08-isolation-and-concurrency.md' -Content ($goodFixture['spec/08-isolation-and-concurrency.md'] + [Environment]::NewLine + 'The four-worker constraint (CR-33: explorer, implementer, verifier, reviewer) is mandatory.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-ISOLATION-BAN-5' -Scenario 'fixed-canary-roster-count'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/08-isolation-and-concurrency.md' -Content $goodFixture['spec/08-isolation-and-concurrency.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/README.md' -Content ($goodFixture['spec/README.md'] + [Environment]::NewLine + '| DR-8 | **Keep separate.** |')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-SPEC-README-BAN-3' -Scenario 'stale-dr8-roster-decision'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/README.md' -Content $goodFixture['spec/README.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/README.md' -Content ($goodFixture['spec/README.md'] + [Environment]::NewLine + 'Explicit per-task isolation; implementers isolated, readers not.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-SPEC-README-BAN-4' -Scenario 'fixed-final-isolation-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/README.md' -Content $goodFixture['spec/README.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/README.md' -Content ($goodFixture['spec/README.md'] + [Environment]::NewLine + '`lsp` tool is gated on BOTH `session.enableLsp` AND per-agent `tools:` allowlist membership.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-SPEC-README-BAN-5' -Scenario 'readme-two-gate-lsp-source-fact'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/README.md' -Content $goodFixture['spec/README.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/README.md' -Content ($goodFixture['spec/README.md'] + [Environment]::NewLine + 'Explorer LSP access is gated at `lsp/index.ts:1639`.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-SPEC-README-BAN-6' -Scenario 'readme-stale-single-gate-lsp-citation'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/README.md' -Content $goodFixture['spec/README.md']

    $readmeWithoutOwnedSettingsPrerequisites = $goodFixture['spec/README.md'].Replace('Phase 01, Phase 03, and Phase 05 may implement settings they explicitly own as selected-contract prerequisites.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/README.md' -Content $readmeWithoutOwnedSettingsPrerequisites
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-SPEC-README-REQ-13' -Scenario 'readme-settings-phase-deadlock'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/README.md' -Content $goodFixture['spec/README.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/README.md' -Content ($goodFixture['spec/README.md'] + [Environment]::NewLine + 'Any settings change to the frozen baseline before phase-06 provides evidence.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-SPEC-README-BAN-7' -Scenario 'readme-restores-settings-phase-deadlock'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/README.md' -Content $goodFixture['spec/README.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/01-target-architecture.md' -Content ($goodFixture['spec/01-target-architecture.md'] + [Environment]::NewLine + 'The implementer, verifier, and reviewer declare `autoloadSkills: evidence-before-completion`.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-TARGET-BAN-1' -Scenario 'fixed-target-role-contract'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/01-target-architecture.md' -Content $goodFixture['spec/01-target-architecture.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/01-target-architecture.md' -Content ($goodFixture['spec/01-target-architecture.md'] + [Environment]::NewLine + 'Any agent needing LSP must list `lsp` explicitly **and** run with `task.enableLsp: true`.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-TARGET-BAN-2' -Scenario 'target-two-gate-lsp-model'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/01-target-architecture.md' -Content $goodFixture['spec/01-target-architecture.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/01-target-architecture.md' -Content ($goodFixture['spec/01-target-architecture.md'] + [Environment]::NewLine + 'The LSP gate is at `lsp/index.ts:1639`.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-TARGET-BAN-3' -Scenario 'target-stale-single-gate-lsp-citation'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/01-target-architecture.md' -Content $goodFixture['spec/01-target-architecture.md']

    $targetWithoutModelOverridePreflight = $goodFixture['spec/01-target-architecture.md'].Replace('Selected-model preflight reconciles task.agentModelOverrides before dispatch.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/01-target-architecture.md' -Content $targetWithoutModelOverridePreflight
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-TARGET-REQ-11' -Scenario 'target-missing-model-override-preflight'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/01-target-architecture.md' -Content $goodFixture['spec/01-target-architecture.md']

    $targetWithoutExactModelIdentity = $goodFixture['spec/01-target-architecture.md'].Replace('Acceptance compares returned modelRole and resolvedModel with the reconciled expected identity; any mismatch fails even when resolvedModelIsFallback is false.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/01-target-architecture.md' -Content $targetWithoutExactModelIdentity
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-TARGET-REQ-12' -Scenario 'target-missing-exact-model-identity'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/01-target-architecture.md' -Content $goodFixture['spec/01-target-architecture.md']

    $targetWithoutStaticDiscoverySeparation = $goodFixture['spec/01-target-architecture.md'].Replace('Static validation proves only L0 filesystem and text properties; runtime discovery requires a separate L1 OMP discovery check.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/01-target-architecture.md' -Content $targetWithoutStaticDiscoverySeparation
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-TARGET-REQ-13' -Scenario 'target-static-discovery-false-evidence'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/01-target-architecture.md' -Content ($goodFixture['spec/01-target-architecture.md'] + [Environment]::NewLine + 'Static validation passing implies runtime discovery succeeded.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-TARGET-BAN-4' -Scenario 'target-restores-static-discovery-equivalence'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/01-target-architecture.md' -Content $goodFixture['spec/01-target-architecture.md']

    $dnaWithoutStaticDiscoverySeparation = $goodFixture['spec/key/01-dna.md'].Replace('Static validation proves only L0 filesystem and text properties; runtime discovery requires a separate L1 OMP discovery check.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content $dnaWithoutStaticDiscoverySeparation
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DNA-REQ-21' -Scenario 'dna-static-discovery-false-evidence'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content ($goodFixture['spec/key/01-dna.md'] + [Environment]::NewLine + 'Static validation passing must imply runtime discovery succeeded.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-DNA-BAN-14' -Scenario 'dna-restores-static-discovery-equivalence'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/01-dna.md' -Content $goodFixture['spec/key/01-dna.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/02-runtime-semantics.md' -Content ($goodFixture['spec/02-runtime-semantics.md'] + [Environment]::NewLine + 'Gate: `lsp/index.ts:1639` — `session.enableLsp === false ? null : new LspTool(session)`.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RUNTIME-BAN-1' -Scenario 'runtime-incomplete-lsp-source-model'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/02-runtime-semantics.md' -Content $goodFixture['spec/02-runtime-semantics.md']

    $activeRuntimeRoster = $goodFixture['spec/02-runtime-semantics.md'].Replace('Former worker names and counts below describe the frozen Phase 00 baseline only; they are runtime observations, not topology authority.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/02-runtime-semantics.md' -Content $activeRuntimeRoster
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RUNTIME-REQ-9' -Scenario 'missing-runtime-baseline-topology-boundary'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/02-runtime-semantics.md' -Content $goodFixture['spec/02-runtime-semantics.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/14-upgradeability-and-governance.md' -Content ($goodFixture['spec/14-upgradeability-and-governance.md'] + [Environment]::NewLine + '| `discovery/helpers.ts` | parser contract | All 5 agent files |')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-GOVERNANCE-BAN-1' -Scenario 'governance-fixed-worker-count'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/14-upgradeability-and-governance.md' -Content $goodFixture['spec/14-upgradeability-and-governance.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/14-upgradeability-and-governance.md' -Content ($goodFixture['spec/14-upgradeability-and-governance.md'] + [Environment]::NewLine + '| `task/isolation-runner.ts` | git requirement | Implementer isolation |')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-GOVERNANCE-BAN-2' -Scenario 'governance-fixed-isolation-role'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/14-upgradeability-and-governance.md' -Content $goodFixture['spec/14-upgradeability-and-governance.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/06-structured-output.md' -Content ($goodFixture['spec/06-structured-output.md'] + [Environment]::NewLine + 'Each of the four worker agents has an output block.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-OUTPUT-BAN-1' -Scenario 'fixed-output-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/06-structured-output.md' -Content $goodFixture['spec/06-structured-output.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content ($goodFixture['spec/07-retrieval-and-code-understanding.md'] + [Environment]::NewLine + 'DR-7 status: **DECIDED** — add `lsp` to explorer, implementer, reviewer.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RETRIEVAL-BAN-1' -Scenario 'fixed-lsp-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content $goodFixture['spec/07-retrieval-and-code-understanding.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content ($goodFixture['spec/07-retrieval-and-code-understanding.md'] + [Environment]::NewLine + '`lsp` MUST be added to `explorer`, `implementer`, and `reviewer` allowlists.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RETRIEVAL-BAN-3' -Scenario 'fixed-lsp-contract-summary'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content $goodFixture['spec/07-retrieval-and-code-understanding.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content ($goodFixture['spec/07-retrieval-and-code-understanding.md'] + [Environment]::NewLine + '**Reduced-capability mode, stated honestly.**')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RETRIEVAL-BAN-6' -Scenario 'selected-lsp-reduced-mode'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content $goodFixture['spec/07-retrieval-and-code-understanding.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content ($goodFixture['spec/07-retrieval-and-code-understanding.md'] + [Environment]::NewLine + 'Selected LSP-consuming roles fall back to `grep` + ranged `read`.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RETRIEVAL-BAN-7' -Scenario 'selected-lsp-grep-substitution'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content $goodFixture['spec/07-retrieval-and-code-understanding.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content ($goodFixture['spec/07-retrieval-and-code-understanding.md'] + [Environment]::NewLine + 'is a stated reduced-capability run when it does')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RETRIEVAL-BAN-8' -Scenario 'selected-lsp-valid-degraded-run'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content $goodFixture['spec/07-retrieval-and-code-understanding.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content ($goodFixture['spec/07-retrieval-and-code-understanding.md'] + [Environment]::NewLine + 'and a parent session that has not disabled LSP. If no selected contract consumes LSP')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RETRIEVAL-BAN-9' -Scenario 'retrieval-three-gate-contract-summary'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content $goodFixture['spec/07-retrieval-and-code-understanding.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content ($goodFixture['spec/07-retrieval-and-code-understanding.md'] + [Environment]::NewLine + 'fall back to level 3 if unavailable')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RETRIEVAL-BAN-10' -Scenario 'retrieval-context7-unnamed-fallback'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content $goodFixture['spec/07-retrieval-and-code-understanding.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/09-model-routing.md' -Content ($goodFixture['spec/09-model-routing.md'] + [Environment]::NewLine + 'The four spawnable worker roles are required.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-ROUTING-BAN-1' -Scenario 'fixed-routing-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/09-model-routing.md' -Content $goodFixture['spec/09-model-routing.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/11-skills-rules-and-quality-gates.md' -Content ($goodFixture['spec/11-skills-rules-and-quality-gates.md'] + [Environment]::NewLine + '`implementer.md` and `verifier.md` carry `autoloadSkills: evidence-before-completion`.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-SKILLS-BAN-1' -Scenario 'fixed-skill-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/11-skills-rules-and-quality-gates.md' -Content $goodFixture['spec/11-skills-rules-and-quality-gates.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/11-skills-rules-and-quality-gates.md' -Content ($goodFixture['spec/11-skills-rules-and-quality-gates.md'] + [Environment]::NewLine + 'Trigger fixtures exist for all three skills.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-SKILLS-BAN-2' -Scenario 'fixed-skill-inventory-count'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/11-skills-rules-and-quality-gates.md' -Content $goodFixture['spec/11-skills-rules-and-quality-gates.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/11-skills-rules-and-quality-gates.md' -Content ($goodFixture['spec/11-skills-rules-and-quality-gates.md'] + [Environment]::NewLine + 'Every selected spawned role whose contract claims completion carries the skill.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-SKILLS-BAN-3' -Scenario 'unconditional-selected-skill-autoload'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/11-skills-rules-and-quality-gates.md' -Content $goodFixture['spec/11-skills-rules-and-quality-gates.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/12-installation-and-rollback.md' -Content ($goodFixture['spec/12-installation-and-rollback.md'] + [Environment]::NewLine + 'Only the four spawnable worker roles remain required.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-INSTALL-BAN-1' -Scenario 'fixed-installer-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/12-installation-and-rollback.md' -Content $goodFixture['spec/12-installation-and-rollback.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/12-installation-and-rollback.md' -Content ($goodFixture['spec/12-installation-and-rollback.md'] + [Environment]::NewLine + 'let the workflow enter the disclosed reduced-capability mode')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-INSTALL-BAN-3' -Scenario 'installer-lsp-reduced-mode'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/12-installation-and-rollback.md' -Content $goodFixture['spec/12-installation-and-rollback.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/12-installation-and-rollback.md' -Content ($goodFixture['spec/12-installation-and-rollback.md'] + [Environment]::NewLine + 'quality reduction, so it degrades rather than refuses')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-INSTALL-BAN-4' -Scenario 'installer-lsp-degrades'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/12-installation-and-rollback.md' -Content $goodFixture['spec/12-installation-and-rollback.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/12-installation-and-rollback.md' -Content ($goodFixture['spec/12-installation-and-rollback.md'] + [Environment]::NewLine + 'workers will run in reduced-capability mode')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-INSTALL-BAN-5' -Scenario 'user-install-lsp-reduced-mode'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/12-installation-and-rollback.md' -Content $goodFixture['spec/12-installation-and-rollback.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/13-validation-and-evaluation.md' -Content ($goodFixture['spec/13-validation-and-evaluation.md'] + [Environment]::NewLine + '| **Verifier fabricates evidence** |')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-EVAL-TOPOLOGY-BAN-1' -Scenario 'fixed-evaluation-verifier'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/13-validation-and-evaluation.md' -Content $goodFixture['spec/13-validation-and-evaluation.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content ($goodFixture['spec/phases/phase-01-runtime-correctness.md'] + [Environment]::NewLine + 'All four worker files carry `blocking: true`.')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE01-BAN-1' -Scenario 'fixed-phase01-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content $goodFixture['spec/phases/phase-01-runtime-correctness.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content ($goodFixture['spec/phases/phase-01-runtime-correctness.md'] + [Environment]::NewLine + 'Corrected agent frontmatter across all five files.')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE01-BAN-5' -Scenario 'fixed-phase01-deliverable-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content $goodFixture['spec/phases/phase-01-runtime-correctness.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content ($goodFixture['spec/phases/phase-01-runtime-correctness.md'] + [Environment]::NewLine + 'Commands with inline `outputSchema` and inline policy prose.')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE01-BAN-6' -Scenario 'default-inline-schema-deliverable'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content $goodFixture['spec/phases/phase-01-runtime-correctness.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content ($goodFixture['spec/phases/phase-01-runtime-correctness.md'] + [Environment]::NewLine + 'Every worker agent (`explorer`, `implementer`, `verifier`, `reviewer`) has a schema.')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE01-BAN-4' -Scenario 'fixed-phase01-schema-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content $goodFixture['spec/phases/phase-01-runtime-correctness.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content ($goodFixture['spec/phases/phase-01-runtime-correctness.md'] + [Environment]::NewLine + 'state the reduced-capability behavior when required LSP is unavailable')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE01-BAN-7' -Scenario 'phase01-lsp-reduced-mode'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content $goodFixture['spec/phases/phase-01-runtime-correctness.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content ($goodFixture['spec/phases/phase-01-runtime-correctness.md'] + [Environment]::NewLine + 'reduced-capability fallback')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE01-BAN-8' -Scenario 'phase01-lsp-fallback'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content $goodFixture['spec/phases/phase-01-runtime-correctness.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content ($goodFixture['spec/phases/phase-01-runtime-correctness.md'] + [Environment]::NewLine + 'degrade to grep/glob')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE01-BAN-9' -Scenario 'phase01-lsp-grep-degrade'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -Content $goodFixture['spec/phases/phase-01-runtime-correctness.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-04-quality-system.md' -Content ($goodFixture['spec/phases/phase-04-quality-system.md'] + [Environment]::NewLine + '### T-04.1 — Enforce Verifier independence')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE04-BAN-1' -Scenario 'fixed-phase04-verifier'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-04-quality-system.md' -Content $goodFixture['spec/phases/phase-04-quality-system.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content ($goodFixture['spec/phases/phase-05-installation-hardening.md'] + [Environment]::NewLine + '`owned_model_roles` — the **four** worker `modelRoles.*` keys')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE05-BAN-1' -Scenario 'fixed-phase05-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content $goodFixture['spec/phases/phase-05-installation-hardening.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content ($goodFixture['spec/phases/phase-05-installation-hardening.md'] + [Environment]::NewLine + 'Acceptance adds the **four** worker role keys and the two isolation keys **and** `task.enableLsp: true`.')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE05-BAN-2' -Scenario 'fixed-phase05-owned-settings'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content $goodFixture['spec/phases/phase-05-installation-hardening.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content ($goodFixture['spec/phases/phase-05-installation-hardening.md'] + [Environment]::NewLine + 'These settings are prerequisites for the template to behave as specified.')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE05-BAN-4' -Scenario 'global-phase05-prerequisites'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content $goodFixture['spec/phases/phase-05-installation-hardening.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content ($goodFixture['spec/phases/phase-05-installation-hardening.md'] + [Environment]::NewLine + 'conflicts degrade rather than refuse')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE05-BAN-5' -Scenario 'phase05-lsp-degrades'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content $goodFixture['spec/phases/phase-05-installation-hardening.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content ($goodFixture['spec/phases/phase-05-installation-hardening.md'] + [Environment]::NewLine + 'let the workflow run')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE05-BAN-6' -Scenario 'phase05-lsp-continues'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content $goodFixture['spec/phases/phase-05-installation-hardening.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content ($goodFixture['spec/phases/phase-05-installation-hardening.md'] + [Environment]::NewLine + 'LSP reduced-capability')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE05-BAN-7' -Scenario 'phase05-lsp-reduced-capability'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content $goodFixture['spec/phases/phase-05-installation-hardening.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content ($goodFixture['spec/phases/phase-05-installation-hardening.md'] + [Environment]::NewLine + 'explicit reduced-capability or fail-closed notice')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE05-BAN-8' -Scenario 'phase05-ambiguous-lsp-policy'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -Content $goodFixture['spec/phases/phase-05-installation-hardening.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content ($goodFixture['spec/phases/phase-06-evaluation.md'] + [Environment]::NewLine + 'Verifier must contradict the Implementer.')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE06-BAN-5' -Scenario 'fixed-phase06-verifier'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content $goodFixture['spec/phases/phase-06-evaluation.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content ($goodFixture['spec/phases/phase-06-evaluation.md'] + [Environment]::NewLine + 'Every worker agent has a canonical `output:` frontmatter block.')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE06-BAN-6' -Scenario 'fixed-phase06-schema-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content $goodFixture['spec/phases/phase-06-evaluation.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content ($goodFixture['spec/phases/phase-06-evaluation.md'] + [Environment]::NewLine + 'L1 confirms three commands, three skills.')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE06-BAN-7' -Scenario 'fixed-phase06-skill-count'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content $goodFixture['spec/phases/phase-06-evaluation.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content ($goodFixture['spec/phases/phase-06-evaluation.md'] + [Environment]::NewLine + 'selected LSP-consuming path may continue in reduced-capability mode')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE06-BAN-8' -Scenario 'phase06-lsp-fail-open'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content $goodFixture['spec/phases/phase-06-evaluation.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content ($goodFixture['spec/phases/phase-06-evaluation.md'] + [Environment]::NewLine + 'CR-39/CR-40 — two more static checks')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE06-BAN-9' -Scenario 'phase06-l0-omits-cr41'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content $goodFixture['spec/phases/phase-06-evaluation.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/13-validation-and-evaluation.md' -Content ($goodFixture['spec/13-validation-and-evaluation.md'] + [Environment]::NewLine + 'workflow discloses reduced-capability mode')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-EVAL-BAN-4' -Scenario 'evaluation-lsp-reduced-mode'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/13-validation-and-evaluation.md' -Content $goodFixture['spec/13-validation-and-evaluation.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/13-validation-and-evaluation.md' -Content ($goodFixture['spec/13-validation-and-evaluation.md'] + [Environment]::NewLine + 'Workflow must disclose reduced-capability mode')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-EVAL-BAN-5' -Scenario 'evaluation-lsp-must-disclose-mode'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/13-validation-and-evaluation.md' -Content $goodFixture['spec/13-validation-and-evaluation.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-03-context-efficiency.md' -Content ($goodFixture['spec/phases/phase-03-context-efficiency.md'] + [Environment]::NewLine + 'Each level must be tried before escalating.')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE03-BAN-4' -Scenario 'phase03-retrieval-exhaustion-gate'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-03-context-efficiency.md' -Content $goodFixture['spec/phases/phase-03-context-efficiency.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/15-security-and-failure-recovery.md' -Content ($goodFixture['spec/15-security-and-failure-recovery.md'] + [Environment]::NewLine + 'Workers with `bash` access (Implementer, Verifier) run commands.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-SECURITY-BAN-1' -Scenario 'fixed-security-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/15-security-and-failure-recovery.md' -Content $goodFixture['spec/15-security-and-failure-recovery.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/16-migration-plan.md' -Content ($goodFixture['spec/16-migration-plan.md'] + [Environment]::NewLine + '`template/.omp/agents/explorer.md`')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-MIGRATION-BAN-1' -Scenario 'fixed-migration-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/16-migration-plan.md' -Content $goodFixture['spec/16-migration-plan.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-03-context-efficiency.md' -Content ($goodFixture['spec/phases/phase-03-context-efficiency.md'] + [Environment]::NewLine + 'Explorer and Implementer prompts state the order.')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE03-BAN-2' -Scenario 'fixed-phase03-roster'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-03-context-efficiency.md' -Content $goodFixture['spec/phases/phase-03-context-efficiency.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/13-validation-and-evaluation.md' -Content ($goodFixture['spec/13-validation-and-evaluation.md'] + [Environment]::NewLine + 'All four worker agents are mandatory.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-EVAL-BAN-1' -Scenario 'stale-fixed-evaluation-topology'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/13-validation-and-evaluation.md' -Content $goodFixture['spec/13-validation-and-evaluation.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/13-validation-and-evaluation.md' -Content ($goodFixture['spec/13-validation-and-evaluation.md'] + [Environment]::NewLine + 'All three skills are discovered.')
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-EVAL-BAN-3' -Scenario 'fixed-evaluation-skill-count'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/13-validation-and-evaluation.md' -Content $goodFixture['spec/13-validation-and-evaluation.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content ($goodFixture['spec/phases/phase-06-evaluation.md'] + [Environment]::NewLine + 'The agent count is four.')
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE06-BAN-1' -Scenario 'stale-fixed-phase06-topology'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content $goodFixture['spec/phases/phase-06-evaluation.md']

    $phase02 = $goodFixture['spec/phases/phase-02-core-orchestration.md'].Replace('Preserve historical Phase 00 evidence; create new current-product validation evidence.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-02-core-orchestration.md' -Content $phase02
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE02-REQ-4' -Scenario 'missing-history-boundary'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-02-core-orchestration.md' -Content $goodFixture['spec/phases/phase-02-core-orchestration.md']

    $missingSchemaLint = $goodFixture['spec/06-structured-output.md'].Replace('Every selected structured-result schema is fully linted before dispatch.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/06-structured-output.md' -Content $missingSchemaLint
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-OUTPUT-REQ-5' -Scenario 'missing-selected-schema-lint'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/06-structured-output.md' -Content $goodFixture['spec/06-structured-output.md']

    $staleAliasBoundary = $goodFixture['spec/09-model-routing.md'].Replace('E2 proves missing or unknown aliases and unavailable models hard-fail with no fallback, while project values win precedence.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/09-model-routing.md' -Content $staleAliasBoundary
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-ROUTING-REQ-3' -Scenario 'missing-e2-routing-conclusion'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/09-model-routing.md' -Content $goodFixture['spec/09-model-routing.md']

    $missingEffortPreflight = $goodFixture['spec/09-model-routing.md'].Replace('Any selected per-spawn effort path requires effective task.enableEffort true and fails before dispatch otherwise.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/09-model-routing.md' -Content $missingEffortPreflight
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-ROUTING-REQ-4' -Scenario 'missing-effort-preflight'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/09-model-routing.md' -Content $goodFixture['spec/09-model-routing.md']

    $missingFallbackResultGate = $goodFixture['spec/09-model-routing.md'].Replace('Selected model identity requires effective retry.modelFallback false and retry.usageAwareFallback false; resolvedModelIsFallback true fails acceptance.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/09-model-routing.md' -Content $missingFallbackResultGate
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-ROUTING-REQ-5' -Scenario 'missing-model-fallback-result-gate'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/09-model-routing.md' -Content $goodFixture['spec/09-model-routing.md']

    $missingEffectiveModelIdentity = $goodFixture['spec/09-model-routing.md'].Replace('Acceptance compares returned modelRole and resolvedModel with the reconciled expected identity; any mismatch fails even when resolvedModelIsFallback is false.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/09-model-routing.md' -Content $missingEffectiveModelIdentity
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-ROUTING-REQ-8' -Scenario 'missing-effective-model-identity-check'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/09-model-routing.md' -Content $goodFixture['spec/09-model-routing.md']

    $missingEffortCeiling = $goodFixture['spec/09-model-routing.md'].Replace('Selected exact effort requires task.maxEffort at least the requested level, and acceptance confirms the resolvedModel effort suffix matches the expected effective effort.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/09-model-routing.md' -Content $missingEffortCeiling
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-ROUTING-REQ-10' -Scenario 'missing-selected-effort-ceiling'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/09-model-routing.md' -Content $goodFixture['spec/09-model-routing.md']

    $activeResearchAuthority = $goodFixture['docs/research/authority-map.md'].Replace('Historical research input only; no current design, execution, routing, fallback, topology, or capability authority.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/research/authority-map.md' -Content $activeResearchAuthority
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RESEARCH-AUTHORITY-REQ-1' -Scenario 'missing-research-authority-fence'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/research/authority-map.md' -Content $goodFixture['docs/research/authority-map.md']

    $activeResearchFile = $goodFixture['docs/research/authority-map.md'].Replace('Authority boundary: This research file is source/research evidence.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/research/authority-map.md' -Content $activeResearchFile
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RESEARCH-FILE-AUTH-AUTHORITY-MAP-REQ-1' -Scenario 'missing-generic-research-file-authority-boundary'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/research/authority-map.md' -Content $goodFixture['docs/research/authority-map.md']

    $activeConflictMatrix = $goodFixture['docs/research/conflict-matrix.md'].Replace('Historical Phase 2 conflict-resolution snapshot only; no current design, execution, topology, review, routing, or capability authority.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/research/conflict-matrix.md' -Content $activeConflictMatrix
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RESEARCH-CONFLICT-REQ-1' -Scenario 'missing-conflict-matrix-authority-fence'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/research/conflict-matrix.md' -Content $goodFixture['docs/research/conflict-matrix.md']

    $activeAdoptionLedger = $goodFixture['registry/adoption-ledger.yml'].Replace('Historical adoption-provenance ledger only; adopted_to paths, role names, and rationales do not select current topology, dispatch, review, or capability behavior.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'registry/adoption-ledger.yml' -Content $activeAdoptionLedger
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-ADOPTION-LEDGER-REQ-1' -Scenario 'missing-adoption-ledger-authority-fence'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'registry/adoption-ledger.yml' -Content $goodFixture['registry/adoption-ledger.yml']

    $activeRepoSynthesis = $goodFixture['spec/key/02-repo-synthesis.md'].Replace('Former fixed worker names and counts are historical research examples; Topic 03-selected responsibilities are the only current topology input.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/02-repo-synthesis.md' -Content $activeRepoSynthesis
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-REPO-SYNTHESIS-REQ-1' -Scenario 'missing-repo-synthesis-topology-boundary'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/02-repo-synthesis.md' -Content ($goodFixture['spec/key/02-repo-synthesis.md'] + [Environment]::NewLine + 'Our topology has four workers.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-REPO-SYNTHESIS-BAN-1' -Scenario 'repo-synthesis-restores-fixed-worker-count'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/02-repo-synthesis.md' -Content $goodFixture['spec/key/02-repo-synthesis.md']

    $missingRepoReportContract = $goodFixture['spec/key/repos/_CONTRACT.md'].Replace('Every repository report repeats its own authority boundary; a folder-level notice is insufficient.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/repos/_CONTRACT.md' -Content $missingRepoReportContract
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-REPO-REPORT-CONTRACT-REQ-1' -Scenario 'missing-per-report-authority-contract'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/repos/_CONTRACT.md' -Content $goodFixture['spec/key/repos/_CONTRACT.md']

    $activeRepoReport = $goodFixture['spec/key/repos/sample.md'].Replace('Authority boundary: This repository report is source/research evidence.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/repos/sample.md' -Content $activeRepoReport
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-REPO-REPORT-AUTH-SAMPLE-REQ-1' -Scenario 'missing-repo-report-authority-fence'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/repos/sample.md' -Content $goodFixture['spec/key/repos/sample.md']

    $activeDossier = $goodFixture['spec/key/dossiers/sample.md'].Replace('Authority boundary: This dossier is source/research evidence.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/dossiers/sample.md' -Content $activeDossier
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-DOSSIER-AUTH-SAMPLE-REQ-1' -Scenario 'missing-dossier-authority-fence'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/dossiers/sample.md' -Content $goodFixture['spec/key/dossiers/sample.md']

    $serenaFailOpen = $goodFixture['spec/key/repos/serena.md'].Replace('If LSP is unavailable, continuation requires an explicit different contract that does not consume LSP, followed by reconciliation and validation.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/repos/serena.md' -Content $serenaFailOpen
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-SERENA-REQ-2' -Scenario 'serena-lsp-fail-open'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/repos/serena.md' -Content $goodFixture['spec/key/repos/serena.md']

    $staleInvestmentAlias = $goodFixture['spec/key/06-investment-thesis.md'].Replace('E2 supersedes the earlier fall-through hypothesis: missing and unknown aliases hard-fail before session creation, and unavailable models surface an error with no fallback.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/06-investment-thesis.md' -Content $staleInvestmentAlias
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-INVESTMENT-REQ-1' -Scenario 'stale-investment-alias-fallthrough'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/06-investment-thesis.md' -Content $goodFixture['spec/key/06-investment-thesis.md']

    $incompleteInvestmentIdentity = $goodFixture['spec/key/06-investment-thesis.md'].Replace('Read resolvedModelIsFallback and compare exact returned identity in the acceptance check.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/06-investment-thesis.md' -Content $incompleteInvestmentIdentity
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-INVESTMENT-REQ-5' -Scenario 'incomplete-investment-model-identity-check'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/06-investment-thesis.md' -Content $goodFixture['spec/key/06-investment-thesis.md']

    $activeInvestmentRoles = $goodFixture['spec/key/06-investment-thesis.md'].Replace('Former fixed-role routing examples are historical hypotheses; selected model responsibilities come only from the Topic 03 manifest.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/06-investment-thesis.md' -Content $activeInvestmentRoles
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-INVESTMENT-REQ-6' -Scenario 'missing-investment-role-boundary'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/06-investment-thesis.md' -Content ($goodFixture['spec/key/06-investment-thesis.md'] + [Environment]::NewLine + 'Make **two roles differ**, and measure.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-INVESTMENT-BAN-2' -Scenario 'investment-restores-fixed-role-experiment'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/06-investment-thesis.md' -Content $goodFixture['spec/key/06-investment-thesis.md']

    $activeCoverageTopology = $goodFixture['spec/key/05-coverage-audit.md'].Replace('Former fixed-role topology statements below are historical audit observations, not current topology authority.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/05-coverage-audit.md' -Content $activeCoverageTopology
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-COVERAGE-REQ-4' -Scenario 'missing-coverage-topology-boundary'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/05-coverage-audit.md' -Content ($goodFixture['spec/key/05-coverage-audit.md'] + [Environment]::NewLine + 'the one agent the whole template exists to justify')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-COVERAGE-BAN-1' -Scenario 'coverage-restores-permanent-verifier-authority'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/key/05-coverage-audit.md' -Content $goodFixture['spec/key/05-coverage-audit.md']

    $missingForcedPartialCase = $goodFixture['spec/13-validation-and-evaluation.md'].Replace('L4 forces a softRequestBudget partial yield and proves that it cannot satisfy completion.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/13-validation-and-evaluation.md' -Content $missingForcedPartialCase
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-EVAL-REQ-14' -Scenario 'missing-forced-partial-adversarial-case'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/13-validation-and-evaluation.md' -Content $goodFixture['spec/13-validation-and-evaluation.md']

    $missingPlanModeGate = $goodFixture['spec/08-isolation-and-concurrency.md'].Replace('Plan mode selects a distinct planning-only contract; selected mutation and fresh-command contracts stop before dispatch or acceptance.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/08-isolation-and-concurrency.md' -Content $missingPlanModeGate
    Assert-Topic02FailureCode -Results @(Test-Topic02ArchitectureContract -RepositoryRoot $fixtureRoot) -Code 'T02-ISOLATION-REQ-9' -Scenario 'missing-plan-mode-contract-gate'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/08-isolation-and-concurrency.md' -Content $goodFixture['spec/08-isolation-and-concurrency.md']

    $missingRetrievalSettingGate = $goodFixture['spec/07-retrieval-and-code-understanding.md'].Replace('Every selected grep, glob, ast_grep, or web_search consumer requires its matching effective setting true.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content $missingRetrievalSettingGate
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RETRIEVAL-REQ-10' -Scenario 'missing-selected-retrieval-setting-gate'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content $goodFixture['spec/07-retrieval-and-code-understanding.md']

    $missingLspServerOutcomeGate = $goodFixture['spec/07-retrieval-and-code-understanding.md'].Replace('No language server found for this file and any details.success false result fail the selected LSP contract.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content $missingLspServerOutcomeGate
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RETRIEVAL-REQ-13' -Scenario 'missing-lsp-server-outcome-gate'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -Content $goodFixture['spec/07-retrieval-and-code-understanding.md']

    $activeFinalAdoptionPlan = $goodFixture['docs/research/final-adoption-plan.md'].Replace('Historical Phase 2 snapshot only; no current design or implementation authority.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/research/final-adoption-plan.md' -Content $activeFinalAdoptionPlan
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-RESEARCH-FINAL-REQ-1' -Scenario 'missing-final-adoption-plan-fence'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/research/final-adoption-plan.md' -Content $goodFixture['docs/research/final-adoption-plan.md']

    $activeArchitectureDoc = $goodFixture['docs/architecture.md'].Replace('Architecture — Current Topic 03 Runtime', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/architecture.md' -Content $activeArchitectureDoc
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-ARCHITECTURE-DOC-REQ-1' -Scenario 'missing-v0-architecture-authority-fence'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/architecture.md' -Content $goodFixture['docs/architecture.md']

    $activeCustomizationGuide = $goodFixture['docs/customization.md'].Replace('Current Topic 03 guide.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/customization.md' -Content $activeCustomizationGuide
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-CUSTOMIZATION-DOC-REQ-1' -Scenario 'missing-customization-runtime-boundary'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/customization.md' -Content $goodFixture['docs/customization.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/token-strategy.md' -Content ($goodFixture['docs/token-strategy.md'] + [Environment]::NewLine + 'Verifier agent')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-TOKEN-REFERENCE-BAN-1' -Scenario 'token-strategy-restores-named-verifier'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/token-strategy.md' -Content $goodFixture['docs/token-strategy.md']

    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/policies/quality-gates.md' -Content ($goodFixture['docs/policies/quality-gates.md'] + [Environment]::NewLine + 'Reviewer scheduling remains risk-based in Standard and mandatory in Orchestrated.')
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-QUALITY-GATE-REFERENCE-BAN-1' -Scenario 'quality-gates-restores-mandatory-orchestrated-reviewer'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'docs/policies/quality-gates.md' -Content $goodFixture['docs/policies/quality-gates.md']

    $activeUpstreamPaths = $goodFixture['registry/upstreams.yml'].Replace('Source-provenance registry only; derived_into paths and former role names do not select current topology, dispatch, review, routing, or capability behavior.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'registry/upstreams.yml' -Content $activeUpstreamPaths
    Assert-Topic02FailureCode -Results @(Test-Topic02TopologyProjectionContract -RepositoryRoot $fixtureRoot) -Code 'T02-UPSTREAM-REGISTRY-REQ-3' -Scenario 'missing-upstream-registry-authority-boundary'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'registry/upstreams.yml' -Content $goodFixture['registry/upstreams.yml']

    $missingAliasHardFailure = $goodFixture['spec/phases/phase-06-evaluation.md'].Replace('Missing aliases and an unavailable selected target hard-fail; KD-027 separately validates the explicit Scout runtime retry chain.', '')
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content $missingAliasHardFailure
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE06-REQ-19' -Scenario 'missing-phase06-alias-hard-failure'
    Set-Topic02FixtureFile -FixtureRoot $fixtureRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -Content $goodFixture['spec/phases/phase-06-evaluation.md']

    Remove-Item -LiteralPath (Join-Path $fixtureRoot 'spec/phases/phase-06-evaluation.md') -Force
    Assert-Topic02FailureCode -Results @(Test-Topic02PhaseContract -RepositoryRoot $fixtureRoot) -Code 'T02-PHASE06-MISSING' -Scenario 'required-phase-file'

    Write-Host ("PASS Topic 02 validator self-test ({0} assertions)" -f $script:assertions) -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("FAIL [T02-TEST] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    if (Test-Path -LiteralPath $fixtureRoot -PathType Container) {
        $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
        $resolvedTemp = [IO.Path]::GetFullPath($tempBase).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
        $leaf = Split-Path -Leaf $resolvedFixture
        $insideTemp = $resolvedFixture.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase)
        if (-not $insideTemp -or $leaf -notlike 'omp-topic02-validator-*') {
            throw "Refusing unsafe fixture cleanup: $resolvedFixture"
        }
        Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
    }
}
