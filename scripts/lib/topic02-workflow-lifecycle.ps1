#Requires -Version 5.1

Set-StrictMode -Version Latest

function New-Topic02ValidationResult {
    param(
        [ValidateSet('PASS','FAIL','WARN')][string]$Status,
        [string]$Code,
        [string]$Message
    )

    [pscustomobject]@{
        Status = $Status
        Code = $Code
        Message = $Message
    }
}

function Test-Topic02FileContract {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$CodePrefix,
        [string[]]$Required = @(),
        [string[]]$Forbidden = @()
    )

    $path = Join-Path $RepositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return (New-Topic02ValidationResult -Status 'FAIL' -Code "$CodePrefix-MISSING" -Message "missing: $RelativePath")
    }

    $content = Get-Content -Raw -LiteralPath $path -Encoding UTF8
    $semanticContent = [regex]::Replace($content, '(?m)^\s*>\s?', '')
    $normalizedContent = [regex]::Replace($semanticContent, '\s+', ' ')
    $results = @()
    for ($index = 0; $index -lt $Required.Count; $index++) {
        $needle = $Required[$index]
        $normalizedNeedle = [regex]::Replace($needle, '\s+', ' ')
        if ($normalizedContent.IndexOf($normalizedNeedle, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $results += New-Topic02ValidationResult -Status 'PASS' -Code "$CodePrefix-REQ-$($index + 1)" -Message "required semantic present in $RelativePath"
        } else {
            $results += New-Topic02ValidationResult -Status 'FAIL' -Code "$CodePrefix-REQ-$($index + 1)" -Message ("missing required semantic in " + $RelativePath + ": " + $needle)
        }
    }

    for ($index = 0; $index -lt $Forbidden.Count; $index++) {
        $needle = $Forbidden[$index]
        $normalizedNeedle = [regex]::Replace($needle, '\s+', ' ')
        if ($normalizedContent.IndexOf($normalizedNeedle, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $results += New-Topic02ValidationResult -Status 'FAIL' -Code "$CodePrefix-BAN-$($index + 1)" -Message ("superseded semantic remains in " + $RelativePath + ": " + $needle)
        } else {
            $results += New-Topic02ValidationResult -Status 'PASS' -Code "$CodePrefix-BAN-$($index + 1)" -Message "superseded semantic absent from $RelativePath"
        }
    }
    return $results
}

function Test-Topic02EvidenceAuthorityDirectory {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativeDirectory,
        [Parameter(Mandatory)][string]$CodePrefix,
        [Parameter(Mandatory)][string]$EvidenceKind,
        [string[]]$ExcludeNames = @()
    )

    $directory = Join-Path $RepositoryRoot $RelativeDirectory
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        return (New-Topic02ValidationResult -Status 'FAIL' -Code "$CodePrefix-DIRECTORY-MISSING" -Message "missing: $RelativeDirectory")
    }

    $results = @()
    $files = @(Get-ChildItem -LiteralPath $directory -File -Filter '*.md' |
        Where-Object { $ExcludeNames -notcontains $_.Name } |
        Sort-Object Name)
    foreach ($file in $files) {
        $slug = (([IO.Path]::GetFileNameWithoutExtension($file.Name) -replace '[^A-Za-z0-9]+', '-').Trim('-')).ToUpperInvariant()
        $relativePath = Join-Path $RelativeDirectory $file.Name
        $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath $relativePath -CodePrefix "$CodePrefix-$slug" -Required @(
            "Authority boundary: This $EvidenceKind is source/research evidence",
            'Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology, dispatch, review mechanism, or capability behavior',
            'Current design and execution authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest'
        )
    }
    return $results
}

function Test-Topic02CanonicalContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/04-workflow-sizing.md' -CodePrefix 'T02-CANONICAL' -Required @(
        'Plain natural-language requests are the normal default entry.',
        'explicit Quick choice',
        'compatibility hints',
        'A task begins when its contract is accepted.',
        'one task and one active candidate lineage',
        'acceptance-bearing mutation invalidates',
        'at least two independently verifiable work units',
        'Parallel writers are optional',
        'Compaction does not change',
        'Handoff creates a successor session',
        'required verification and review obligations'
    ) -Forbidden @(
        'The user picks the size',
        'restart as Standard',
        'restart as Orchestrated',
        'discards its partial work',
        'De-escalation is not permitted'
    )
}

function Test-Topic02ArchitectureContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $results = @()
    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/key/01-dna.md' -CodePrefix 'T02-DNA' -Required @(
        'plain request enters',
        'explicit Quick choice',
        'integration contract',
        'candidate snapshot',
        'successor session',
        'Topic 03 owns the final worker graph',
        'classification alone does not force review',
        'required verification and review obligations',
        'Each selected spawned worker with a structured result contract',
        'selected completion-claiming responsibilities',
        'selected parallel writers',
        'selected verification mechanism',
        'selected LSP-consuming path fails closed',
        'all four independent gates',
        'four registration gates do not prove that an applicable language server exists',
        'context7_unavailable',
        'disclose the skipped level and reason',
        'Acceptance requires structuredOutput.status valid',
        'unavailable, invalid, and overridden results are unvalidated',
        'Returned modelRole and resolvedModel identity comparison catches credential fallback that resolvedModelIsFallback does not mark',
        'Static validation proves only L0 filesystem and text properties; runtime discovery requires a separate L1 OMP discovery check'
    ) -Forbidden @(
        'The user picks the size',
        'Escalation restarts; it does not continue',
        'De-escalation is forbidden',
        'four workers at depth 1',
        'Verifier is separate from Implementer, permanently',
        'Always in Orchestrated',
        'Each worker declares its own result schema',
        'Assigned to `implementer`, `verifier`, `diff-reviewer`',
        '| `implementer` (parallel, Orchestrated) | **`true`**',
        'FAIL short-circuits back to Implementer',
        'selected LSP-consuming path may continue with grep in reduced-capability mode',
        'Both gates apply',
        'fall back to level 3 silently',
        'Static validation passing must imply runtime discovery succeeded'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md' -CodePrefix 'T02-DESIGN' -Required @(
        'required verification and review obligations'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/key/04-decision-log.md' -CodePrefix 'T02-DECISION' -Required @(
        'required verification and review obligations',
        'KD-006 is superseded as a global rule',
        'effective task-tool schema selected by Topic 03',
        'Each selected spawned worker whose contract requires a structured result',
        'L0 validation parses every selected agent `output:` block',
        'Malformed selected schemas yield structuredOutput.status unavailable and fail acceptance',
        'Selected per-spawn effort requires task.enableEffort true',
        'forced softRequestBudget stop returns a partial yield that cannot satisfy completion',
        'coordinator rejects any result with resolvedModelIsFallback true',
        'resolvedModelIsFallback marks retry fallback only; credential fallback and task.agentModelOverrides require exact returned identity comparison',
        'Plan mode is a distinct planning-only contract and cannot satisfy selected mutation or fresh-command work',
        'four LSP registration gates do not authorize acceptance when no applicable language server exists or a required LSP call returns details.success false'
    ) -Forbidden @(
        'Every dispatch in every command file uses the batch wire form',
        'Each worker declares its result schema in its own frontmatter',
        'all four worker agent files',
        'L0 validation parses every agent `output:` block'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/key/03-token-quality-model.md' -CodePrefix 'T02-METRIC' -Required @(
        'task cycle starts when the task contract is accepted',
        'candidate snapshot',
        'terminally_blocked',
        'accepted_with_waiver',
        'required independent verification because the candidate author reported success',
        'role names below are frozen-baseline examples',
        'selected exact-output verification responsibility',
        'selected LSP-consuming responsibility',
        'Effective LSP requires all four independent gates',
        'parent session not disabled and not plan mode',
        'lsp.enabled',
        'LSP tool result with details.success false is a failed capability result',
        'partial yield as a partial result rather than a completion',
        'Model identity is observable only by comparing returned modelRole and resolvedModel',
        'resolvedModelIsFallback covers retry fallback but not credential fallback'
    ) -Forbidden @(
        'are truthful terminal states',
        'Skip the Verifier because the Implementer said it passed',
        'restore it for the Verifier only',
        'Decision: ADOPT for explorer, implementer, reviewer.'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/03-agent-topology.md' -CodePrefix 'T02-TOPOLOGY' -Required @(
        'Topic 02 owns workflow classification',
        'Topology does not',
        'Topic 03 owns'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/05-context-and-token-model.md' -CodePrefix 'T02-CONTEXT' -Required @(
        'Compaction preserves',
        'Handoff creates a successor session',
        'reconcile the contract and workspace',
        'required independent verification because the candidate author reported success',
        'role names below are frozen-baseline examples',
        'selected exact-output verification responsibility',
        'offload safety follows effective isolation and artifact-retention responsibility',
        'context7_unavailable is the disclosed named skip when level 4 is unavailable',
        'forced softRequestBudget partial yield is nonterminal and requires recovery or redispatch',
        'web_unavailable is disclosed when level 5 is unavailable',
        'freshness contract remains unresolved and cannot be accepted without authoritative evidence'
    ) -Forbidden @(
        'Skipping the Verifier because the Implementer reported success',
        'restore it for the Verifier only',
        'Standard workflow only',
        'non-isolated (Standard) workers',
        'When Context7 is unavailable, fall back silently'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/08-isolation-and-concurrency.md' -CodePrefix 'T02-ISOLATION' -Required @(
        'Parallel execution and parallel writers are optional',
        'remains Orchestrated',
        'preconditions apply',
        'selected stage-barrier worker',
        'conditional parallel-batch path',
        'Recursion depth constrains any selected topology',
        'selected observation roles',
        'support agents are excluded from the selected worker-set comparison',
        'Plan mode selects a distinct planning-only contract',
        'selected mutation and fresh-command contracts stop before dispatch or acceptance',
        'Selected nested delegation requires remaining task.maxRecursionDepth',
        'worker whose task tool was stripped cannot satisfy that contract'
    ) -Forbidden @(
        'blocking: true on every worker agent',
        'flat topology in `03-agent-topology.md` mandatory',
        'every worker agent MUST declare `blocking: true`',
        '`task.batch == true` is an Orchestrated precondition',
        'The four-worker constraint (CR-33'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/10-verification-and-review.md' -CodePrefix 'T02-REVIEW' -Required @(
        'Orchestrated classification alone does not force a reviewer',
        'Topic 03 owns the verification mechanism',
        'A named Verifier is not mandatory',
        'selected command-executing verification role',
        'selected stage-barrier worker',
        'same selected-path fail-closed principle as LSP'
    ) -Forbidden @(
        'always in Orchestrated',
        'Why Verification Is a Separate Agent',
        'Separate child session per Verifier',
        'scope: Verifier ONLY as hard_required',
        'the Verifier and Reviewer MUST declare `blocking: true`',
        'not a reduced-capability mode like LSP unavailability'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/13-validation-and-evaluation.md' -CodePrefix 'T02-EVAL' -Required @(
        'immutable candidate snapshot',
        'terminally_blocked',
        'waiting_for_user',
        'remains excluded from the validated denominator',
        'Topic 03-selected topology manifest',
        'selected stage-barrier worker',
        'conditional parallel path',
        'skill set declared by the selected runtime manifest',
        'selected LSP-consuming path fails closed',
        'different contract that does not consume LSP',
        'L1 rejects selected LSP acceptance when no applicable language server exists or any required LSP call returns details.success false',
        'L0 fully lints every selected structured-result schema before dispatch',
        'Acceptance requires structuredOutput.status valid',
        'L4 forces a softRequestBudget partial yield',
        'Effective retry.modelFallback is true solely for the named Cheap Scout chain',
        'retry.usageAwareFallback is false',
        'default/Worker/Reviewer chains are empty',
        'L1 reconciles task.agentModelOverrides',
        'Worker/Reviewer acceptance compares returned modelRole and resolvedModel with the expected identity',
        'Plan mode cannot satisfy a selected mutation or fresh-command contract',
        'L4 proves that a plausible read-only yield is rejected',
        'L1 checks effective glob.enabled, grep.enabled, astGrep.enabled, and web_search.enabled only for selected consumers',
        'web_unavailable leaves a freshness contract unresolved',
        'unable to satisfy acceptance without authoritative evidence',
        'L1 checks task.maxEffort against selected exact effort',
        'verifies the returned resolvedModel effort suffix',
        'Selected nested delegation must have remaining task.maxRecursionDepth',
        'stripped task capability cannot satisfy acceptance'
    ) -Forbidden @(
        'All four worker agents',
        'for all four workers',
        'All three skills are discovered.',
        'workflow discloses reduced-capability mode',
        'Workflow must disclose reduced-capability mode'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/README.md' -CodePrefix 'T02-SPEC-README' -Required @(
        'plain request is the normal workflow entry',
        'compatibility hints',
        'Topic 03 owns topology',
        'Runtime projection is scheduled in Phase 02',
        'role-specific choices below are non-authoritative',
        'Reopened by KD-026 and Topic 03',
        'concurrent writers are isolated only when selected',
        'all four independent LSP gates',
        'parent session not disabled and not plan mode',
        'E2 closed the model-role question',
        'hard-fail without fallback',
        'project values win',
        'Phase 01, Phase 03, and Phase 05 may implement settings they explicitly own as selected-contract prerequisites',
        'Those settings remain provisional candidates until Phase 06 evaluates them; unowned or speculative settings changes remain frozen'
    ) -Forbidden @(
        'The user picks the size',
        'task: explorer → implementer → verifier',
        '**Keep separate.**',
        'Explicit per-task isolation; implementers isolated, readers not',
        'gated on BOTH',
        'lsp/index.ts:1639',
        'Any settings change to the frozen baseline before phase-06 provides evidence'
    )
    return $results
}

function Test-Topic02TopologyProjectionContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $results = @()
    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/01-target-architecture.md' -CodePrefix 'T02-TARGET' -Required @(
        'Topic 03-selected topology manifest is the only authority',
        'completion-claiming roles',
        'Each selected spawned worker',
        'four-condition conjunction',
        'parent session not disabled and not plan mode',
        'four registration gates establish LSP tool presence only',
        'Selected model-role aliases fail closed with no fallback',
        'project configuration wins precedence',
        'Every selected structured-result schema is fully linted',
        'acceptance requires structuredOutput.status valid',
        'Selected-model preflight reconciles task.agentModelOverrides before dispatch',
        'Acceptance compares returned modelRole and resolvedModel with the reconciled expected identity; any mismatch fails even when resolvedModelIsFallback is false',
        'Static validation proves only L0 filesystem and text properties; runtime discovery requires a separate L1 OMP discovery check'
    ) -Forbidden @(
        'implementer, verifier, and reviewer declare `autoloadSkills: evidence-before-completion`',
        'Any agent needing LSP must list `lsp` explicitly **and** run with `task.enableLsp: true`',
        'lsp/index.ts:1639',
        'Static validation passing implies runtime discovery succeeded'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/02-runtime-semantics.md' -CodePrefix 'T02-RUNTIME' -Required @(
        'four-condition conjunction',
        'all four effective gates are source-verified independently',
        'parent session not disabled and not plan mode',
        'lsp.enabled',
        'registered LSP tool may still return details.success false when no language server applies',
        'OQ-3 is closed by pinned source: child depth 1 retains task, while child depth 2 reaches the default maxRecursionDepth and loses task',
        'missing or unknown aliases and unavailable models fail with no fallback',
        'project configuration wins',
        'Former worker names and counts below describe the frozen Phase 00 baseline only; they are runtime observations, not topology authority',
        'The Topic 03-selected manifest owns current worker names and count; Phase 02 owns runtime projection'
    ) -Forbidden @(
        'Gate: `lsp/index.ts:1639`'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/14-upgradeability-and-governance.md' -CodePrefix 'T02-GOVERNANCE' -Required @(
        'Topic 03-selected topology manifest',
        'Former worker names and counts are non-authoritative baseline examples',
        'All selected worker definitions',
        'Selected skill-autoload consumers',
        'Selected isolation paths',
        'LSP four-gate conjunction is a watched governance claim',
        'tools/index.ts',
        'Applicable-language-server routing and LSP details.success are watched governance claims backed by lsp/index.ts',
        'grep, glob, ast_grep, and web_search setting gates are watched governance claims'
    ) -Forbidden @(
        'All 5 agent files',
        'Implementer isolation'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/06-structured-output.md' -CodePrefix 'T02-OUTPUT' -Required @(
        'Topic 03-selected worker contracts determine',
        'former four-role mapping is non-authoritative',
        'Each selected spawned worker with a structured result contract',
        'selected responsibility contracts may diverge',
        'Every selected structured-result schema is fully linted before dispatch',
        'Acceptance requires structuredOutput.status valid',
        'unavailable, invalid, and overridden results are unvalidated'
    ) -Forbidden @(
        'Each of the four worker agents',
        '| `verification-result` | `verifier.md` frontmatter `output:` | Sole producer |',
        'Explorer and Implementer share `agent-result`',
        'Each worker declares its result'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/07-retrieval-and-code-understanding.md' -CodePrefix 'T02-RETRIEVAL' -Required @(
        'selected LSP-consuming roles',
        'former role table is non-authoritative',
        'no selected contract consumes LSP',
        'For each selected contract that consumes symbol-aware retrieval',
        'selected LSP-consuming path must stop before dispatch or acceptance',
        'different contract that does not consume LSP',
        'four-gate conjunction',
        'context7_unavailable',
        'must be disclosed with the skipped level',
        'Every selected grep, glob, ast_grep, or web_search consumer requires its matching effective setting true',
        'unmet selected retrieval capability stops before dispatch or acceptance',
        'different contract is reconciled and revalidated',
        'No language server found for this file and any details.success false result fail the selected LSP contract',
        'web_unavailable is the named disclosed reason for an unavailable level 5',
        'freshness-specific contract remains unresolved without authoritative evidence'
    ) -Forbidden @(
        'DR-7 status: **DECIDED** — add `lsp` to explorer, implementer, reviewer',
        'Explorer, Implementer, and Reviewer fall back',
        '`lsp` MUST be added to `explorer`, `implementer`, and `reviewer` allowlists',
        'the Explorer builds the map',
        'The Explorer''s ranked evidence is the map',
        '**Reduced-capability mode, stated honestly.**',
        'Selected LSP-consuming roles fall back to `grep` + ranged `read`',
        'is a stated reduced-capability run when it does',
        'and a parent session that has not disabled LSP. If no selected contract consumes LSP',
        'fall back to level 3 if unavailable'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/09-model-routing.md' -CodePrefix 'T02-ROUTING' -Required @(
        'only model-role aliases referenced by the Topic 03-selected topology manifest are required',
        'former four-role routing table is non-authoritative',
        'E2 proves missing or unknown aliases and unavailable models hard-fail with no fallback',
        'Any selected per-spawn effort path requires effective task.enableEffort true and fails before dispatch otherwise',
        'Selected model identity requires effective retry.modelFallback false and retry.usageAwareFallback false',
        'resolvedModelIsFallback true fails acceptance',
        'Effective selected-model preflight reconciles task.agentModelOverrides before dispatch',
        'Acceptance compares returned modelRole and resolvedModel with the reconciled expected identity',
        'mismatch fails even when resolvedModelIsFallback is false',
        'Selected exact effort requires task.maxEffort at least the requested level',
        'acceptance confirms the resolvedModel effort suffix matches the expected effective effort'
    ) -Forbidden @(
        'The four spawnable worker roles are required',
        '**Four** required worker roles'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/11-skills-rules-and-quality-gates.md' -CodePrefix 'T02-SKILLS' -Required @(
        'selected completion-claiming roles',
        'former role table is non-authoritative',
        'selected gate-applier',
        'skill set selected by the runtime manifest',
        'selected spawned role whose contract consumes'
    ) -Forbidden @(
        '`implementer.md` and `verifier.md` carry `autoloadSkills: evidence-before-completion`',
        'Trigger fixtures exist for all three skills.',
        'Every selected spawned role whose contract claims completion'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/12-installation-and-rollback.md' -CodePrefix 'T02-INSTALL' -Required @(
        'owned model-role keys are derived from the Topic 03-selected topology manifest',
        'selected LSP-consuming roles',
        'conditional parallel-writer path',
        'selected LSP-consuming path remains disabled',
        'different contract that does not consume LSP',
        'Selected LSP installation acceptance probes applicable language-server routing and treats details.success false as a failed capability result',
        'Selected per-spawn effort makes task.enableEffort true and task.maxEffort xhigh owned prerequisites',
        'fails preflight when either is not effective',
        'KD-027 selected routing owns retry.modelFallback true, retry.usageAwareFallback false, one Cheap-Scout-only Pro chain, and empty default/Worker/Reviewer chains',
        'Selected-model preflight reconciles task.agentModelOverrides and rejects an unselected effective override',
        'Selected grep, glob, ast_grep, and web_search consumers own matching project settings',
        'fail preflight when ineffective',
        'Selected exact-effort consumers own a sufficient task.maxEffort ceiling',
        'selected nested delegation preflights task.maxRecursionDepth'
    ) -Forbidden @(
        'Only the four spawnable worker roles remain required',
        'Three worker roles (Explorer, Implementer, Reviewer)',
        'workflow enter the disclosed reduced-capability mode',
        'quality reduction, so it degrades rather than refuses',
        'workers will run in reduced-capability mode'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/13-validation-and-evaluation.md' -CodePrefix 'T02-EVAL-TOPOLOGY' -Required @(
        'selected non-author'
    ) -Forbidden @(
        '**Verifier fabricates evidence**',
        '**Verifier bash disabled**'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/15-security-and-failure-recovery.md' -CodePrefix 'T02-SECURITY' -Required @(
        'selected bash-capable roles',
        'selected discovery role',
        'selected remediation owner',
        'selected non-author verification mechanism',
        'Missing or unknown aliases and unavailable models fail with no fallback',
        'forced softRequestBudget partial yield remains nonterminal and cannot satisfy acceptance',
        'result with resolvedModelIsFallback true is rejected',
        'Returned modelRole and resolvedModel must match the reconciled expected identity',
        'credential fallback is not marked by resolvedModelIsFallback'
    ) -Forbidden @(
        'Workers with `bash` access (Implementer, Verifier)',
        'Verifier catches false completion',
        'Verifier re-runs independently'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'docs/policies/model-routing.md' -CodePrefix 'T02-ROUTING-REFERENCE' -Required @(
        'Topic 03-selected aliases are the only required routing set',
        'E2 is closed: missing or unknown aliases and unavailable models hard-fail with no fallback',
        'Project configuration values win over global values',
        'Selected model identity rejects resolvedModelIsFallback true'
    ) -Forbidden @(
        'Unresolved E2 boundary'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'docs/research/authority-map.md' -CodePrefix 'T02-RESEARCH-AUTHORITY' -Required @(
        'Historical research input only; no current design, execution, routing, fallback, topology, or capability authority',
        'Current authority lives in the accepted design, key decisions, active specs, and Topic 03-selected manifest'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'docs/research/mechanism-matrix.md' -CodePrefix 'T02-RESEARCH-MECHANISM' -Required @(
        'Historical research input only; no current design, execution, routing, fallback, topology, or capability authority',
        'ADOPT and ADAPT labels below record an earlier research pass and do not select current runtime behavior'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'docs/research/conflict-matrix.md' -CodePrefix 'T02-RESEARCH-CONFLICT' -Required @(
        'Historical Phase 2 conflict-resolution snapshot only; no current design, execution, topology, review, routing, or capability authority',
        'Current authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'registry/adoption-ledger.yml' -CodePrefix 'T02-ADOPTION-LEDGER' -Required @(
        'Historical adoption-provenance ledger only; adopted_to paths, role names, and rationales do not select current topology, dispatch, review, or capability behavior',
        'Current authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/key/02-repo-synthesis.md' -CodePrefix 'T02-REPO-SYNTHESIS' -Required @(
        'Former fixed worker names and counts are historical research examples; Topic 03-selected responsibilities are the only current topology input',
        'Each selected responsibility names the distinct context it isolates; no worker count is selected here'
    ) -Forbidden @(
        'our topology has four workers',
        'our four workers are named'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/key/repos/_CONTRACT.md' -CodePrefix 'T02-REPO-REPORT-CONTRACT' -Required @(
        'Every repository report repeats its own authority boundary; a folder-level notice is insufficient'
    )

    $results += Test-Topic02EvidenceAuthorityDirectory -RepositoryRoot $RepositoryRoot -RelativeDirectory 'spec/key/repos' -CodePrefix 'T02-REPO-REPORT-AUTH' -EvidenceKind 'repository report' -ExcludeNames @('_CONTRACT.md', 'README.md')
    $results += Test-Topic02EvidenceAuthorityDirectory -RepositoryRoot $RepositoryRoot -RelativeDirectory 'spec/key/dossiers' -CodePrefix 'T02-DOSSIER-AUTH' -EvidenceKind 'dossier'
    $results += Test-Topic02EvidenceAuthorityDirectory -RepositoryRoot $RepositoryRoot -RelativeDirectory 'docs/research' -CodePrefix 'T02-RESEARCH-FILE-AUTH' -EvidenceKind 'research file'

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/key/repos/serena.md' -CodePrefix 'T02-SERENA' -Required @(
        'Authority boundary: This repository report is source/research evidence',
        'If LSP is unavailable, continuation requires an explicit different contract that does not consume LSP, followed by reconciliation and validation'
    ) -Forbidden @(
        'Wrong for us: our worker agents must finish the task on whatever the repo is, so a degraded path has to exist'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/key/dossiers/retrieval-cluster.md' -CodePrefix 'T02-RETRIEVAL-DOSSIER' -Required @(
        'Context7 unavailability uses the named reason context7_unavailable and discloses the skipped level',
        'Current retrieval authority is spec/07 section B-1: bounded escalation with named permitted skips'
    ) -Forbidden @(
        'Context7 needs a fallback, CR-18',
        'The gate framing (`spec/07:79`)'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/key/06-investment-thesis.md' -CodePrefix 'T02-INVESTMENT' -Required @(
        'E2 supersedes the earlier fall-through hypothesis: missing and unknown aliases hard-fail before session creation, and unavailable models surface an error with no fallback',
        'Project role values override global values',
        'resolvedModelIsFallback does not mark credential fallback',
        'acceptance compares returned modelRole and resolvedModel with the expected identity',
        'Read resolvedModelIsFallback and compare exact returned identity in the acceptance check',
        'Former fixed-role routing examples are historical hypotheses; selected model responsibilities come only from the Topic 03 manifest',
        'Differentiate two selected responsibility classes and measure'
    ) -Forbidden @(
        'Every `@role` in every agent file resolves through a single destination, or falls through',
        'Make **two roles differ**, and measure'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/key/05-coverage-audit.md' -CodePrefix 'T02-COVERAGE' -Required @(
        'resolvedModelIsFallback detects retry fallback only',
        'credential fallback requires returned modelRole and resolvedModel identity comparison',
        'Malformed schemas and non-valid structured outputs fail acceptance',
        'Former fixed-role topology statements below are historical audit observations, not current topology authority',
        'Current topology and review behavior derive from the accepted design, active specs, phase plans, and Topic 03-selected manifest',
        'A selected subagent verification mechanism is incompatible with the injected prohibition on subagent verification',
        'L1 compares the Topic 03-selected worker set and reports foreign discovered agents separately'
    ) -Forbidden @(
        'the one agent the whole template exists to justify',
        '`spec/13` L1 asserts an exact agent roster',
        '/standard` dispatches exactly one Explorer, then one Implementer, then one Verifier'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'docs/research/final-adoption-plan.md' -CodePrefix 'T02-RESEARCH-FINAL' -Required @(
        'Historical Phase 2 snapshot only; no current design or implementation authority',
        'Current behavior derives from the accepted design, key decisions, active specs, and Topic 03-selected manifest'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'docs/final-report.md' -CodePrefix 'T02-FINAL-REPORT' -Required @(
        'Historical Phase 8 snapshot only; no current architecture, completion, topology, or capability authority',
        'Current status derives from active specs, phase plans, evidence, and the Topic 03-selected manifest'
    )

    foreach ($historicalDoc in @(
        @{ Path = 'docs/workflow-v0.md'; Prefix = 'T02-WORKFLOW-V0-DOC' },
        @{ Path = 'docs/report-design.md'; Prefix = 'T02-REPORT-DESIGN-DOC' }
    )) {
        $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath $historicalDoc.Path -CodePrefix $historicalDoc.Prefix -Required @(
            'Historical Workflow v0 snapshot only; no current topology, dispatch, review, routing, or lifecycle authority',
            'Current authority lives in the accepted design, key decisions, active specs, phase plans, and Topic 03-selected manifest'
        ) -Forbidden @(
            'Authoritative architecture document for Workflow v0'
        )
    }

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'docs/architecture.md' -CodePrefix 'T02-ARCHITECTURE-DOC' -Required @(
        'Architecture — Current Topic 03 Runtime',
        'Plain requests enter the main-session Tech Lead; the default is inline work with no spawn',
        'OMP discovers exactly three custom agents'
    )

    foreach ($baselineGuide in @(
        @{ Path = 'docs/rollback.md'; Prefix = 'T02-ROLLBACK-DOC' }
    )) {
        $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath $baselineGuide.Path -CodePrefix $baselineGuide.Prefix -Required @(
            'Frozen Phase 00 runtime guide; role and file examples describe the installed baseline only and do not select the Topic 03 topology or authorize runtime migration',
            'Phase 02 performs runtime migration only after Topic 03 selects the manifest'
        )
    }

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'docs/customization.md' -CodePrefix 'T02-CUSTOMIZATION-DOC' -Required @(
        'Current Topic 03 guide',
        'The selected custom-agent manifest is `cheap-scout`, `worker`, and `reviewer`; the Tech Lead remains the main session',
        'Cheap Scout owns only read-only retrieval'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'docs/token-strategy.md' -CodePrefix 'T02-TOKEN-REFERENCE' -Required @(
        'Selected independent verification mechanism | Independent verification prevents false-completion acceptance',
        'Independent review on every Quick task is unnecessary token cost unless the accepted task contract and risk require it'
    ) -Forbidden @(
        'Verifier agent',
        'Reviewer on every Quick task'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'docs/policies/quality-gates.md' -CodePrefix 'T02-QUALITY-GATE-REFERENCE' -Required @(
        'The main session selects gates; the task packet carries names; the selected gate-applier applies only those names',
        'The selected gate-applier may report a missing gate as a scoped finding but does not expand its own review contract',
        'This matrix does not decide whether independent review is selected',
        'Review remains task-contract and risk-gated; Orchestrated classification alone does not mandate a Reviewer or worker dispatch'
    ) -Forbidden @(
        'Reviewer scheduling remains risk-based in Standard and mandatory in Orchestrated',
        'Reviewer applies only those names'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'registry/rejected-mechanisms.yml' -CodePrefix 'T02-REJECTED-REGISTRY' -Required @(
        'Serena remains excluded as a second runtime',
        'selected OMP LSP or native-search contract runs only when its effective tool and settings conjunction passes',
        'fails closed or selects and revalidates a different contract',
        'Independent review is selected by the accepted task contract and risk; Orchestrated classification alone does not mandate a Reviewer or worker dispatch'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'registry/upstreams.yml' -CodePrefix 'T02-UPSTREAM-REGISTRY' -Required @(
        'Serena default integration is excluded as a second runtime',
        'selected OMP retrieval capabilities remain conditional on their effective tool and settings conjunction',
        'Source-provenance registry only; derived_into paths and former role names do not select current topology, dispatch, review, routing, or capability behavior'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/16-migration-plan.md' -CodePrefix 'T02-MIGRATION' -Required @(
        'Topic 03-selected topology manifest',
        'former agent-file rows are non-authoritative',
        'runtime agent file set is derived'
    ) -Forbidden @(
        '`template/.omp/agents/explorer.md`',
        '`template/.omp/agents/implementer.md`',
        '`template/.omp/agents/verifier.md`',
        '`template/.omp/agents/reviewer.md`'
    )
    return $results
}

function Test-Topic02PhaseContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $results = @()
    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/phases/phase-02-core-orchestration.md' -CodePrefix 'T02-PHASE02' -Required @(
        'Migrate runtime prompts from the Phase 00 snapshot',
        'no-prefix entry, explicit Quick, and Tech-Lead selection',
        'independently verifiable work units and an integration contract',
        'Preserve historical Phase 00 evidence; create new current-product validation evidence',
        'selected dispatch uses effort, task.enableEffort must be effective',
        'Malformed schemas and any structuredOutput status other than valid cannot satisfy acceptance'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/phases/phase-03-context-efficiency.md' -CodePrefix 'T02-PHASE03' -Required @(
        'Compaction preserves session identity',
        'reconciled successor session',
        'Durable lifecycle state remains owned by Topic 04',
        'selected retrieval roles',
        'selected verification result',
        'bounded escalation',
        'named permitted skip'
    ) -Forbidden @(
        'Explorer-provided `file:line` references',
        'Explorer and Implementer prompts state the order',
        'Inspect a real Verifier result',
        'Each level must be tried before escalating.'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/phases/phase-01-runtime-correctness.md' -CodePrefix 'T02-PHASE01' -Required @(
        'Runtime migration consumes',
        'selected LSP-consuming worker',
        'selected stage-barrier worker',
        'installed project-worker set exactly matches',
        'Each selected spawned worker whose contract requires structured output',
        'selected worker adapters and selected command contracts',
        'selected LSP-consuming path must fail closed',
        'different contract that does not consume LSP',
        'Runtime validation rejects the selected LSP path when no applicable language server exists or a required call reports details.success false',
        'Every selected structured-result schema is fully linted before dispatch',
        'acceptance requires structuredOutput.status valid'
    ) -Forbidden @(
        'All four worker files carry `blocking: true`',
        'installed agent set is exactly `{explorer, implementer, verifier',
        'Add `blocking: true` to every worker agent file',
        'every worker agent (`explorer`, `implementer`, `verifier`, `reviewer`)',
        'Corrected agent frontmatter across all five files',
        'Commands with inline `outputSchema` and inline policy prose',
        'state the reduced-capability behavior when required LSP is unavailable',
        'reduced-capability fallback',
        'degrade to grep/glob'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/phases/phase-04-quality-system.md' -CodePrefix 'T02-PHASE04' -Required @(
        'selected verification mechanism',
        'non-author',
        'A separate AgentSession is one permitted mechanism',
        'Unavailable, invalid, and overridden structured results are unvalidated and cannot satisfy acceptance'
    ) -Forbidden @(
        'T-04.1 — Enforce Verifier independence',
        'The Verifier must run every verification command fresh in its own session'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/phases/phase-05-installation-hardening.md' -CodePrefix 'T02-PHASE05' -Required @(
        'owned model-role keys are derived',
        'selected aliases and optional settings consumed by the manifest',
        'prerequisites are conditional on the selected runtime path',
        'selected LSP-consuming path remains disabled',
        'different contract that does not consume LSP',
        'Installation acceptance probes applicable language-server routing for selected file types and treats details.success false as failure',
        'Selected effort consumers own task.enableEffort true and task.maxEffort xhigh as conditional prerequisites',
        'KD-027 owns retry.modelFallback true, retry.usageAwareFallback false, one Cheap-Scout-only Pro chain, and empty default/Worker/Reviewer chains',
        'Selected retrieval consumers own matching grep, glob, ast_grep, and web_search project settings',
        'Selected exact effort owns a sufficient task.maxEffort ceiling',
        'selected nested delegation validates task.maxRecursionDepth before dispatch'
    ) -Forbidden @(
        '`owned_model_roles` — the **four** worker `modelRoles.*` keys',
        'adds the **four** worker role keys',
        'the two isolation keys **and** `task.enableLsp: true`',
        'are prerequisites for the template to behave as specified',
        'conflicts degrade rather than refuse',
        'let the workflow run',
        'LSP reduced-capability',
        'explicit reduced-capability or fail-closed notice'
    )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot -RelativePath 'spec/phases/phase-06-evaluation.md' -CodePrefix 'T02-PHASE06' -Required @(
        'plain entry, explicit Quick',
        'reclassification',
        'candidate mutation invalidation, handoff reconciliation, and Orchestrated integration',
        'Cheap Scout retryable availability/runtime failure follows Flash xhigh to Pro xhigh to Tech Lead retrieval without lifecycle side effects',
        'Topic 03-selected topology manifest',
        'selected worker set',
        'conditional parallel path',
        'selected non-author verification mechanism must contradict',
        'selected structured-result producer',
        'skill set declared by the selected runtime manifest',
        'selected LSP-consuming path fails closed',
        'replacement contract that does not consume LSP',
        'L4 covers registered LSP with no applicable language server and rejects every required LSP result whose details.success is false',
        'L0 implements CR-41 separately',
        'lsp.enabled false',
        'L0 fully lints every selected structured-result schema before dispatch',
        'Acceptance requires structuredOutput.status valid',
        'L1 requires effective task.enableEffort true and task.maxEffort xhigh for selected exact effort paths',
        'Missing aliases and an unavailable selected target hard-fail',
        'KD-027 separately validates the explicit Scout runtime retry chain',
        'L4 forces a softRequestBudget partial yield and proves it cannot satisfy completion',
        'L1 requires retry.modelFallback true, retry.usageAwareFallback false, a Scout chain containing only Pro xhigh, and empty default/Worker/Reviewer chains',
        'L1 reconciles task.agentModelOverrides and rejects a Worker/Reviewer returned modelRole or resolvedModel mismatch',
        'unflagged credential fallback',
        'Plan mode requires a distinct planning-only contract',
        'rejects selected mutation or fresh-command paths before dispatch or acceptance',
        'L1 checks effective glob.enabled, grep.enabled, astGrep.enabled, and web_search.enabled for selected consumers',
        'fails closed when unmet',
        'web_unavailable is disclosed',
        'freshness contract cannot pass without authoritative evidence',
        'L1 checks task.maxEffort and the returned resolvedModel effort suffix for selected exact effort',
        'L1 rejects selected nested delegation when task.maxRecursionDepth would strip the task tool'
    ) -Forbidden @(
        'the agent count is four',
        'required resolvable role count is four',
        'for all four discovered workers',
        'L1 confirms **four** agents',
        'Verifier must contradict',
        'every worker agent has a canonical `output:` frontmatter block',
        'three commands, three skills',
        'selected LSP-consuming path may continue in reduced-capability mode',
        'CR-39/CR-40 — two more static checks'
    )
    return $results
}

function Test-Topic02WorkflowLifecycleContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)
    @(
        Test-Topic02CanonicalContract -RepositoryRoot $RepositoryRoot
        Test-Topic02ArchitectureContract -RepositoryRoot $RepositoryRoot
        Test-Topic02TopologyProjectionContract -RepositoryRoot $RepositoryRoot
        Test-Topic02PhaseContract -RepositoryRoot $RepositoryRoot
        Test-Topic02ContinuityProjectionContract -RepositoryRoot $RepositoryRoot
    )
}

function Test-Topic02ContinuityProjectionContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $results = @()
    $decisionPath = Join-Path $RepositoryRoot 'spec/key/04-decision-log.md'
    if (Test-Path -LiteralPath $decisionPath -PathType Leaf) {
        $decisionText = Get-Content -Raw -LiteralPath $decisionPath -Encoding UTF8
        $markerCount = [regex]::Matches($decisionText, 'topic07-authority:kd-031').Count
        $results += New-Topic02ValidationResult -Status $(if ($markerCount -eq 1) { 'PASS' } else { 'FAIL' }) `
            -Code 'T02-T07-MARKER' -Message "KD-031 authority marker count: $markerCount (expected 1)"
    } else {
        $results += New-Topic02ValidationResult -Status 'FAIL' -Code 'T02-T07-MARKER' `
            -Message 'spec/key/04-decision-log.md is missing.'
    }

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot `
        -RelativePath 'spec/key/04-decision-log.md' -CodePrefix 'T02-T07-DECISION' -Required @(
            'KD-031 — Explicit safe context-full compaction with authoritative continuity kernel',
            'Managed sessions disable automatic semantic compaction and context promotion',
            'complete initial `locked_decisions` in `create-task`',
            'there is no hidden auto-continue',
            'IMPLEMENTED_NOT_PROMOTED',
            'OPEN-T07-RUNTIME-02',
            'Opus is not a continuity dependency'
        )

    $commandContracts = @(
        @{ Path = 'template/.omp/commands/quick.md'; Class = 'quick'; Prefix = 'T02-T07-QUICK' },
        @{ Path = 'template/.omp/commands/standard.md'; Class = 'standard'; Prefix = 'T02-T07-STANDARD' },
        @{ Path = 'template/.omp/commands/orchestrated.md'; Class = 'orchestrated'; Prefix = 'T02-T07-ORCHESTRATED' }
    )
    foreach ($contract in $commandContracts) {
        $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot `
            -RelativePath $contract.Path -CodePrefix $contract.Prefix -Required @(
                "workflow_class: $($contract.Class)",
                'complete initial `locked_decisions`',
                '`set-continuity-contract`',
                'argument-free `/safe-compact`',
                '`begin-handoff`/`accept-handoff`',
                'without hidden continuation'
            )
    }

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot `
        -RelativePath 'docs/context-continuity.md' -CodePrefix 'T02-T07-OPERATOR' -Required @(
            'The command accepts no focus text',
            'Operational authority remains in the local Topic 04 `agent-tasks` root',
            'No prompt is sent and no continuation, retry, or handoff is scheduled',
            'Quick may continue when authoritative state explicitly reports',
            'Bare `omp` remains usable, but it does not provide the guarantee',
            'OmniRoute, DeepSeek Scout routing, Worker/Reviewer effort, and Opus preference are separate and unchanged',
            'IMPLEMENTED_NOT_PROMOTED',
            'OPEN-T07-RUNTIME-02'
        )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot `
        -RelativePath 'spec/05-context-and-token-model.md' -CodePrefix 'T02-T07-CONTEXT' -Required @(
            'compaction.strategy = off',
            '`/safe-compact` accepts no arguments',
            'next normal prompt receives one fresh Topic 04-derived kernel exactly once',
            'bounded subagent aborts as failed/partial'
        ) -Forbidden @(
            'compaction.enabled = true',
            'compaction.strategy = shake'
        )

    $results += Test-Topic02FileContract -RepositoryRoot $RepositoryRoot `
        -RelativePath 'spec/phases/phase-03-context-efficiency.md' -CodePrefix 'T02-T07-PHASE03' -Required @(
            'Topic 07 continuity consumer',
            '`compaction.strategy: off`',
            'no hidden continuation/retry',
            'Runtime canaries prove stop-before-provider on both supported versions before promotion'
        ) -Forbidden @('`compaction.strategy: shake`')

    return $results
}
