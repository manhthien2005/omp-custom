#Requires -Version 5.1

Set-StrictMode -Version Latest

function New-Topic05ProgressiveResult {
    param(
        [ValidateSet('PASS', 'FAIL', 'WARN')][string]$Status,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Message
    )

    [pscustomobject]@{ Status = $Status; Code = $Code; Message = $Message }
}

function New-Topic05ProgressiveBooleanResult {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$PassMessage,
        [Parameter(Mandatory)][string]$FailMessage
    )

    if ($Condition) {
        return New-Topic05ProgressiveResult -Status PASS -Code $Code -Message $PassMessage
    }
    return New-Topic05ProgressiveResult -Status FAIL -Code $Code -Message $FailMessage
}

function Get-Topic05ProgressiveContent {
    param([string]$RepositoryRoot, [string]$RelativePath)
    $path = Join-Path $RepositoryRoot ($RelativePath -replace '/', '\')
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return '' }
    return Get-Content -Raw -LiteralPath $path -Encoding UTF8
}

function Get-Topic05ProgressiveJson {
    param([string]$RepositoryRoot, [string]$RelativePath)
    $text = Get-Topic05ProgressiveContent $RepositoryRoot $RelativePath
    if (-not $text) { return $null }
    try { return $text | ConvertFrom-Json } catch { return $null }
}

function Test-Topic05ProgressiveExactFields {
    param([AllowNull()][object]$Value, [Parameter(Mandatory)][string[]]$Names)
    if ($null -eq $Value) { return $false }
    $actual = @($Value.PSObject.Properties.Name | Sort-Object)
    $expected = @($Names | Sort-Object)
    return ($actual -join '|') -ceq ($expected -join '|')
}

function Get-Topic05ProgressiveSha256 {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) { return $null }
    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-Topic05ProgressiveContainsAll {
    param([AllowEmptyString()][string]$Content, [string[]]$Needles)
    foreach ($needle in $Needles) {
        if ($Content.IndexOf($needle, [StringComparison]::OrdinalIgnoreCase) -lt 0) { return $false }
    }
    return $true
}

function Get-Topic05ProgressiveGovernedFiles {
    return @(
        'spec/key/04-decision-log.md', 'spec/key/01-dna.md',
        'spec/key/03-token-quality-model.md', 'spec/03-agent-topology.md',
        'spec/05-context-and-token-model.md', 'spec/07-retrieval-and-code-understanding.md',
        'spec/12-installation-and-rollback.md', 'spec/13-validation-and-evaluation.md',
        'spec/14-upgradeability-and-governance.md', 'spec/15-security-and-failure-recovery.md',
        'spec/README.md', 'spec/phases/phase-03-context-efficiency.md',
        'spec/phases/phase-05-installation-hardening.md', 'spec/phases/phase-06-evaluation.md',
        'registry/upstreams.yml', 'registry/adoption-ledger.yml',
        'registry/rejected-mechanisms.yml', 'README.md', 'docs/retrieval.md',
        'docs/architecture.md', 'docs/installation.md', 'docs/customization.md',
        'docs/token-strategy.md', 'docs/security.md', 'docs/rollback.md',
        'docs/workflow-v0.md', 'docs/policies/context-budget.md',
        'scripts/install-template.ps1', 'scripts/lib/topic05-codegraph.ps1',
        'scripts/lib/topic05-benchmark.ps1', 'scripts/run-topic05-retrieval-benchmark.ps1',
        'scripts/uninstall-template.ps1', 'scripts/provision-codegraph.ps1',
        'scripts/cleanup-codegraph.ps1', 'scripts/lib/phase00-evidence.ps1',
        'scripts/lib/topic05-progressive-retrieval.ps1',
        'scripts/validate-topic05-progressive-retrieval.ps1', 'scripts/validate-template.ps1',
        'scripts/tests/topic05-provisioning.Tests.ps1',
        'scripts/tests/topic05-adapter.Tests.ps1', 'scripts/tests/topic05-tool.Tests.mjs',
        'scripts/tests/topic05-installer.Tests.ps1', 'scripts/tests/topic05-routing.Tests.ps1',
        'scripts/tests/topic05-benchmark.Tests.ps1',
        'scripts/tests/topic05-progressive-retrieval.Tests.ps1',
        'scripts/tests/fixtures/topic05/fake-codegraph.mjs',
        'template/.omp/codegraph/upstream-lock.json',
        'template/.omp/codegraph/component-manifest.json',
        'template/.omp/codegraph/CODEGRAPH-LICENSE.txt',
        'template/.omp/codegraph/COMPONENT.md',
        'template/.omp/codegraph/codegraph-process.ps1',
        'template/.omp/codegraph/safe-init.mjs',
        'template/.omp/tools/codegraph-retrieve.js',
        'template/.omp/config.yml', 'template/.omp/agents/cheap-scout.md',
        'template/.omp/agents/reviewer.md',
        'evals/retrieval/topic05/fixtures.json', 'evals/retrieval/topic05/README.md',
        'docs/superpowers/specs/2026-08-13-topic-05-progressive-retrieval-codegraph-cheap-scout-design.md',
        'docs/superpowers/plans/2026-08-13-topic-05-progressive-retrieval-codegraph-cheap-scout-plan.md',
        'docs/evidence/current-product/topic-05/deterministic.json',
        'docs/evidence/current-product/topic-05/model-campaign.json',
        'docs/evidence/current-product/topic-05/manifest.json'
    )
}

function Test-Topic05ProgressiveRetrievalContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $results = @()
    $governed = @(Get-Topic05ProgressiveGovernedFiles)
    $missing = @($governed | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $RepositoryRoot ($_ -replace '/', '\')) -PathType Leaf)
    })
    $requiredResult = New-Topic05ProgressiveBooleanResult -Condition ($missing.Count -eq 0) `
        -Code 'T05-REQUIRED-FILES' -PassMessage 'All Topic 05 governed files exist' `
        -FailMessage ("Missing Topic 05 governed files: {0}" -f ($missing -join ', '))
    $results += $requiredResult

    $decision = Get-Topic05ProgressiveContent $RepositoryRoot 'spec/key/04-decision-log.md'
    $decisionValid = Test-Topic05ProgressiveContainsAll $decision @(
        '<!-- topic05-authority:kd-029 -->', '## KD-029', 'optional and default-off',
        'actor and retrieval capability are selected independently', 'graph output is a hypothesis',
        'native retrieval', 'four-arm'
    )
    $results += New-Topic05ProgressiveBooleanResult $decisionValid 'T05-DECISION-KD029' `
        'KD-029 owns the progressive-retrieval decision' 'KD-029 is missing or incomplete'

    $installer = Get-Topic05ProgressiveContent $RepositoryRoot 'scripts/install-template.ps1'
    $defaultMatch = [regex]::Match($installer, '(?s)\[string\[\]\]\$Components\s*=\s*@\((?<body>.*?)\),')
    $defaultOff = $defaultMatch.Success -and $defaultMatch.Groups['body'].Value -notmatch '(?i)["'']codegraph["'']' -and
        $installer.Contains("`$codeGraphSelected = `$Components -ccontains 'codegraph'") -and
        $installer.Contains('CodeGraph acquisition inputs require the explicit codegraph component.')
    $results += New-Topic05ProgressiveBooleanResult $defaultOff 'T05-DEFAULT-OFF' `
        'CodeGraph is absent from defaults and requires explicit selection' 'CodeGraph became implicit or default-on'

    $lock = Get-Topic05ProgressiveJson $RepositoryRoot 'template/.omp/codegraph/upstream-lock.json'
    $expectedDigests = @(
        'cf5ee435a6e44d097b2f98f2b7b8b9422bb1094844404efed82519c5da1af2cf',
        '0a0ccc29bf7da9d10be1458d89d7e15c55927ae24cd95e9fa3de4bdfea059dde',
        '9f17750aedf45d51f68caae39ed21d6e2a7290b2326e5c53f95a165918ebd1d8',
        '2ba65e87a1210b706bb1e67d5e48b5fc4a1935e43dbb3fb5f31c5597840d2e58',
        'de125e792b5eed7dee8def2ab9bd7e762f372012f75f595e59d3b0c8714b0d55',
        'd6798622b4f44ee6757c94335f437ee27a9ff7d3537b554cb6a2b3baf11bc4a1'
    )
    $pinValid = $null -ne $lock -and [string]$lock.upstream -ceq 'colbymchenry/codegraph' -and
        [string]$lock.version -ceq '1.5.0' -and [string]$lock.tag -ceq 'v1.5.0' -and
        [string]$lock.commit -ceq 'ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6' -and
        [string]$lock.license -ceq 'MIT' -and @($lock.artifacts).Count -eq 6
    $results += New-Topic05ProgressiveBooleanResult $pinValid 'T05-UPSTREAM-PIN' `
        'CodeGraph v1.5.0 identity is pinned exactly' 'CodeGraph version, tag, commit, license, or artifact set drifted'
    $actualDigests = if ($null -ne $lock) { @($lock.artifacts | ForEach-Object { [string]$_.sha256 }) } else { @() }
    $digestValid = $actualDigests.Count -eq 6 -and @($expectedDigests | Where-Object { $actualDigests -cnotcontains $_ }).Count -eq 0
    $results += New-Topic05ProgressiveBooleanResult $digestValid 'T05-ARTIFACT-DIGESTS' `
        'All six release artifact digests are pinned' 'A CodeGraph release artifact digest is missing or changed'

    $manifest = Get-Topic05ProgressiveJson $RepositoryRoot 'template/.omp/codegraph/component-manifest.json'
    $componentValid = $null -ne $manifest -and [string]$manifest.component -ceq 'codegraph' -and
        @($manifest.requires | Where-Object { [string]$_.component -ceq 'state' }).Count -eq 1 -and
        @($manifest.generated_target_files) -ccontains '.omp/codegraph/runtime.json' -and
        @($manifest.generated_target_files) -ccontains '.omp/codegraph/install-record.json'
    $results += New-Topic05ProgressiveBooleanResult $componentValid 'T05-COMPONENT-CONTRACT' `
        'The optional component has a closed state dependency and generated-file boundary' 'CodeGraph component dependency or generated-file boundary drifted'

    $guide = Get-Topic05ProgressiveContent $RepositoryRoot 'docs/retrieval.md'
    $guideCollapsed = [regex]::Replace($guide, '\s+', ' ')
    $adapterValid = Test-Topic05ProgressiveContainsAll $guideCollapsed @(
        '<!-- topic05-operator-guide -->', 'capability adapter', 'No MCP server',
        'no interactive upstream installer', 'no hooks, daemon, or auto-update'
    )
    $results += New-Topic05ProgressiveBooleanResult $adapterValid 'T05-ADAPTER-BOUNDARY' `
        'CodeGraph stays behind the bounded capability adapter' 'MCP, interactive initialization, hooks, daemon, or auto-update entered the selected path'

    $tool = Get-Topic05ProgressiveContent $RepositoryRoot 'template/.omp/tools/codegraph-retrieve.js'
    $inputValid = (Test-Topic05ProgressiveContainsAll $tool @(
        '["question", "max_files"]', '{ additionalProperties: false }',
        'resolveInstalledRuntime(import.meta.url)', 'fallback: "native"'
    )) -and (Test-Topic05ProgressiveContainsAll $guideCollapsed @(
        'Models may provide only the bounded question and max_files',
        'cannot choose an executable, command, working directory, environment, or index path'
    ))
    $results += New-Topic05ProgressiveBooleanResult $inputValid 'T05-INPUT-AUTHORITY' `
        'Model input cannot choose process, path, or environment authority' 'Model-selected process, path, or environment input became possible'

    $process = Get-Topic05ProgressiveContent $RepositoryRoot 'template/.omp/codegraph/codegraph-process.ps1'
    $indexValid = (Test-Topic05ProgressiveContainsAll $process @(
        "Join-Path `$worktreeRoot '.codegraph'", 'Test-Topic05CodeGraphReparsePoint $indexPath',
        "Throw-Topic05CodeGraphReason -Reason 'worktree_mismatch'"
    )) -and (Test-Topic05ProgressiveContainsAll $guideCollapsed @(
        'one physical', 'index per Git worktree', 'shared and symlinked indexes are refused',
        'frozen candidate never triggers lazy initialization'
    ))
    $results += New-Topic05ProgressiveBooleanResult $indexValid 'T05-WORKTREE-INDEX' `
        'Indexes are physical, per-worktree, and initialized before a frozen candidate' 'Shared, linked, or lazy candidate index semantics appeared'

    $stateValid = Test-Topic05ProgressiveContainsAll $process @(
        'Get-AgentTasksActiveTaskAuthorities', 'Get-AgentTasksWorkspaceSnapshot',
        'Test-AgentTasksCandidateCurrentUnlocked',
        "Throw-Topic05CodeGraphReason -Reason 'candidate_drift'",
        "Throw-Topic05CodeGraphReason -Reason 'source_changed'",
        "Throw-Topic05CodeGraphReason -Reason 'state_cache_not_owned'"
    )
    $results += New-Topic05ProgressiveBooleanResult $stateValid 'T05-STATE-BINDING' `
        'Topic 04 owns cache binding and candidate/source post-checks' 'Topic 04 ownership or post-query candidate/source validation is missing'

    $graphValid = Test-Topic05ProgressiveContainsAll $guideCollapsed @(
        'Graph output is a bounded hypothesis, never source truth',
        'An absence claim requires current native-source corroboration'
    )
    $results += New-Topic05ProgressiveBooleanResult $graphValid 'T05-GRAPH-HYPOTHESIS' `
        'Graph results are hypotheses and cannot prove absence alone' 'Graph evidence was promoted to truth or sole absence proof'

    $fallbackGuideValid = Test-Topic05ProgressiveContainsAll $guideCollapsed @(
            'Every unavailable, partial, failed, timed-out, or unhealthy CodeGraph outcome names native retrieval',
            'never an opaque model retry loop'
        )
    $fallbackValid = $tool.Contains('continue with native read/grep/glob retrieval') -and
        $tool.Contains('fallback: "native"') -and $fallbackGuideValid
    $results += New-Topic05ProgressiveBooleanResult $fallbackValid 'T05-NATIVE-FALLBACK' `
        'Every CodeGraph failure names the native fallback' 'Native fallback disappeared or became an opaque retry'

    $scout = [regex]::Replace((Get-Topic05ProgressiveContent $RepositoryRoot 'template/.omp/agents/cheap-scout.md'), '\s+', ' ')
    $config = Get-Topic05ProgressiveContent $RepositoryRoot 'template/.omp/config.yml'
    $scoutValid = (Test-Topic05ProgressiveContainsAll $scout @(
        'Never edit, verify acceptance, review a candidate, integrate, or issue a verdict.',
        'fallback_path'
    )) -and (Test-Topic05ProgressiveContainsAll $config @(
        'cheap-scout: omniroute/ds/deepseek-v4-flash:xhigh',
        'omniroute/ds/deepseek-v4-pro:xhigh'
    ))
    $results += New-Topic05ProgressiveBooleanResult $scoutValid 'T05-SCOUT-AUTHORITY' `
        'Cheap Scout remains read-only advisory retrieval' 'Cheap Scout gained execution, review, or acceptance authority'

    $reviewer = [regex]::Replace((Get-Topic05ProgressiveContent $RepositoryRoot 'template/.omp/agents/reviewer.md'), '\s+', ' ')
    $reviewerValid = Test-Topic05ProgressiveContainsAll $reviewer @(
        'Choose native, CodeGraph, or mixed retrieval independently from any Scout choice.',
        'Every critical graph-supported claim must be corroborated against current source',
        'an absence claim cannot pass without native corroboration'
    )
    $results += New-Topic05ProgressiveBooleanResult $reviewerValid 'T05-REVIEWER-INDEPENDENCE' `
        'Reviewer retrieval and corroboration remain independent' 'Reviewer inherited Scout evidence or lost independent current-source retrieval'

    $benchmark = Get-Topic05ProgressiveContent $RepositoryRoot 'scripts/lib/topic05-benchmark.ps1'
    $fixtures = Get-Topic05ProgressiveJson $RepositoryRoot 'evals/retrieval/topic05/fixtures.json'
    $armsValid = Test-Topic05ProgressiveContainsAll $benchmark @(
        'A_lead_native', 'B_lead_codegraph', 'C_scout_native_lead', 'D_scout_codegraph_lead',
        "'cold'", "'warm'"
    )
    $results += New-Topic05ProgressiveBooleanResult $armsValid 'T05-BENCHMARK-ARMS' `
        'Benchmark keeps all four arms and cold/warm separation' 'The four-arm benchmark comparison drifted'
    $contaminationValid = $null -ne $fixtures -and
        (@($fixtures.contamination_controls.native_forbidden_paths) -join '|') -ceq '.omp/codegraph|.omp/tools/codegraph-retrieve.js|.codegraph' -and
        (@($fixtures.contamination_controls.native_forbidden_environment_prefixes) -join '|') -ceq 'CODEGRAPH_' -and
        $fixtures.contamination_controls.separate_capability_targets -eq $true -and
        $fixtures.contamination_controls.identical_snapshot_required -eq $true
    $results += New-Topic05ProgressiveBooleanResult $contaminationValid 'T05-NATIVE-CONTAMINATION' `
        'Native benchmark arms exclude CodeGraph paths, instructions, and environment' 'Native benchmark arms can see CodeGraph state or differ from graph snapshots'

    $spendValid = Test-Topic05ProgressiveContainsAll $benchmark @(
        'model-pilot requires -AllowModelSpend', 'RUN_TOPIC05_MODEL_PILOT',
        'provider_reported', 'not_measured', 'resolved_model'
    )
    $results += New-Topic05ProgressiveBooleanResult $spendValid 'T05-SPEND-TELEMETRY' `
        'Model spend is explicit and telemetry never estimates missing usage' 'Spend confirmation or truthful provider telemetry handling is missing'

    $deepSeekValid = $benchmark.Contains('omniroute/ds/deepseek-v4-flash:xhigh') -and
        $benchmark.Contains('omniroute/ds/deepseek-v4-pro:xhigh') -and
        $benchmark.Contains('ENVIRONMENT_BLOCKED')
    $results += New-Topic05ProgressiveBooleanResult $deepSeekValid 'T05-DEEPSEEK-DISPOSITION' `
        'DeepSeek Flash/Pro routing blocks truthfully without provider substitution' 'DeepSeek route identity or environment-blocked disposition drifted'

    $promotionValid = (Test-Topic05ProgressiveContainsAll $benchmark @(
        'universal_default = $false', 'codegraph_percentage_threshold = $null', 'promotion = $false'
    )) -and (Test-Topic05ProgressiveContainsAll $guideCollapsed @(
        'No run makes CodeGraph a universal default', 'recommendation is task-class-specific'
    ))
    $results += New-Topic05ProgressiveBooleanResult $promotionValid 'T05-PROMOTION-BOUNDARY' `
        'Evidence can recommend a task-class route but cannot promote a universal default' 'Universal/default promotion or a made-up CodeGraph threshold appeared'

    $deterministic = Get-Topic05ProgressiveJson $RepositoryRoot `
        'docs/evidence/current-product/topic-05/deterministic.json'
    $modelCampaign = Get-Topic05ProgressiveJson $RepositoryRoot `
        'docs/evidence/current-product/topic-05/model-campaign.json'
    $deterministicFields = @(
        'schema_version', 'record_type', 'status', 'captured_at_utc', 'scope',
        'provider_calls', 'model_processes_started', 'environment', 'real_binary_smoke',
        'deterministic_campaign', 'disposition'
    )
    $modelFields = @(
        'schema_version', 'record_type', 'status', 'reason', 'captured_at_utc',
        'provider_calls', 'model_processes_started', 'lead_identity', 'cheap_scout_routes',
        'planned_arms', 'planned_cache_conditions', 'harness', 'environment_probe', 'usage',
        'recommendation', 'promotion', 'universal_default'
    )
    $evidenceDispositionValid = (Test-Topic05ProgressiveExactFields $deterministic $deterministicFields) -and
        (Test-Topic05ProgressiveExactFields $modelCampaign $modelFields)
    if ($evidenceDispositionValid) {
        $smokeCases = @($deterministic.real_binary_smoke.cases.PSObject.Properties.Value)
        $evidenceDispositionValid = [int]$deterministic.schema_version -eq 1 -and
            [string]$deterministic.record_type -ceq 'topic05_deterministic_evidence' -and
            [string]$deterministic.status -ceq 'PASS' -and
            [int]$deterministic.provider_calls -eq 0 -and
            [int]$deterministic.model_processes_started -eq 0 -and
            [string]$deterministic.real_binary_smoke.status -ceq 'PASS' -and
            $smokeCases.Count -eq 8 -and
            @($smokeCases | Where-Object { [string]$_.status -cne 'PASS' }).Count -eq 0 -and
            [string]$deterministic.real_binary_smoke.cases.frozen_candidate_without_index.reason_code -ceq
                'candidate_index_missing' -and
            $deterministic.real_binary_smoke.cases.absence_corroboration.graph_only_acceptance -eq $false -and
            [int]$deterministic.deterministic_campaign.record_count -eq 54 -and
            [int]$deterministic.deterministic_campaign.fixture_count -eq 9 -and
            $deterministic.deterministic_campaign.all_records_model_free -eq $true -and
            $deterministic.deterministic_campaign.comparison.hard_gates_pass -eq $true -and
            $deterministic.deterministic_campaign.comparison.efficiency_measured -eq $false -and
            [string]$deterministic.deterministic_campaign.comparison.recommendation -ceq 'inconclusive' -and
            $deterministic.deterministic_campaign.comparison.promotion -eq $false -and
            [string]$deterministic.disposition.codegraph_component -ceq 'experimental_default_off' -and
            $deterministic.disposition.native_retrieval_default -eq $true -and
            $deterministic.disposition.promotion -eq $false -and
            [string]$modelCampaign.record_type -ceq 'topic05_model_campaign_disposition' -and
            [string]$modelCampaign.status -ceq 'NOT_RUN' -and
            [string]$modelCampaign.reason -ceq 'explicit_model_spend_not_authorized_for_this_campaign' -and
            [int]$modelCampaign.provider_calls -eq 0 -and [int]$modelCampaign.model_processes_started -eq 0 -and
            [string]$modelCampaign.cheap_scout_routes.primary -ceq
                'omniroute/ds/deepseek-v4-flash:xhigh' -and
            [string]$modelCampaign.cheap_scout_routes.fallback -ceq
                'omniroute/ds/deepseek-v4-pro:xhigh' -and
            @($modelCampaign.cheap_scout_routes.additional_fallbacks).Count -eq 0 -and
            (@($modelCampaign.planned_arms) -join '|') -ceq
                'A_lead_native|B_lead_codegraph|C_scout_native_lead|D_scout_codegraph_lead' -and
            $null -eq $modelCampaign.recommendation -and $modelCampaign.promotion -eq $false -and
            $modelCampaign.universal_default -eq $false
    }
    $results += New-Topic05ProgressiveBooleanResult $evidenceDispositionValid `
        'T05-EVIDENCE-DISPOSITION' 'Current evidence is truthful, model-free, default-off, and non-promoting' `
        'Current evidence overclaims a model campaign, promotion, or deterministic outcome'

    $evidenceManifest = Get-Topic05ProgressiveJson $RepositoryRoot `
        'docs/evidence/current-product/topic-05/manifest.json'
    $manifestFields = @(
        'schema_version', 'record_type', 'generated_at_utc', 'repository', 'pinned_omp',
        'environment', 'files', 'commands'
    )
    $manifestValid = Test-Topic05ProgressiveExactFields $evidenceManifest $manifestFields
    $hashesValid = $manifestValid
    if ($manifestValid) {
        $manifestValid = [int]$evidenceManifest.schema_version -eq 1 -and
            [string]$evidenceManifest.record_type -ceq 'topic05_current_product_manifest' -and
            (Test-Topic05ProgressiveExactFields $evidenceManifest.repository @(
                'head', 'dirty_paths_sha256', 'dirty_paths_algorithm'
            )) -and
            [string]$evidenceManifest.repository.head -cmatch '^[0-9a-f]{40}$' -and
            [string]$evidenceManifest.repository.dirty_paths_sha256 -cmatch '^[0-9a-f]{64}$' -and
            [string]$evidenceManifest.repository.dirty_paths_algorithm -ceq
                'sha256(sorted_git_porcelain_v1_lines_utf8_lf)' -and
            (Test-Topic05ProgressiveExactFields $evidenceManifest.pinned_omp @('commit', 'version', 'clean')) -and
            [string]$evidenceManifest.pinned_omp.commit -ceq
                '3a8591a8af5b6d200088d12ca75a5517cb064fa8' -and
            [string]$evidenceManifest.pinned_omp.version -ceq '17.2.10' -and
            $evidenceManifest.pinned_omp.clean -eq $true -and
            (Test-Topic05ProgressiveExactFields $evidenceManifest.environment @(
                'pwsh_version', 'node_version', 'git_version', 'installed_omp_version'
            ))
        $declaredPaths = [Collections.Generic.List[string]]::new()
        foreach ($file in @($evidenceManifest.files)) {
            if (-not (Test-Topic05ProgressiveExactFields $file @('path', 'role', 'sha256'))) {
                $manifestValid = $false; $hashesValid = $false; continue
            }
            $relative = [string]$file.path
            if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative.Contains('\') -or
                $relative -match '(^|/)\.\.(/|$)' -or
                $relative -ceq 'docs/evidence/current-product/topic-05/manifest.json' -or
                [string]$file.sha256 -cnotmatch '^[0-9a-f]{64}$') {
                $manifestValid = $false; $hashesValid = $false; continue
            }
            [void]$declaredPaths.Add($relative)
            $actualHash = Get-Topic05ProgressiveSha256 `
                (Join-Path $RepositoryRoot ($relative -replace '/', '\'))
            if ($null -eq $actualHash -or $actualHash -cne [string]$file.sha256) { $hashesValid = $false }
        }
        [string[]]$sortedPaths = @($declaredPaths)
        [Array]::Sort($sortedPaths, [StringComparer]::Ordinal)
        $uniquePathCount = @($declaredPaths | Sort-Object -Unique).Count
        if ($uniquePathCount -ne $declaredPaths.Count -or
            ($sortedPaths -join '|') -cne (@($declaredPaths) -join '|')) {
            $manifestValid = $false
        }
        $requiredEvidencePaths = @(
            'docs/evidence/current-product/topic-05/deterministic.json',
            'docs/evidence/current-product/topic-05/model-campaign.json',
            'docs/superpowers/specs/2026-08-13-topic-05-progressive-retrieval-codegraph-cheap-scout-design.md',
            'spec/key/04-decision-log.md', 'template/.omp/codegraph/upstream-lock.json',
            'template/.omp/codegraph/component-manifest.json',
            'scripts/lib/topic05-benchmark.ps1', 'scripts/run-topic05-retrieval-benchmark.ps1',
            'evals/retrieval/topic05/fixtures.json', 'scripts/tests/topic05-benchmark.Tests.ps1',
            'scripts/tests/topic05-progressive-retrieval.Tests.ps1'
        )
        if (@($requiredEvidencePaths | Where-Object { $declaredPaths -cnotcontains $_ }).Count -gt 0) {
            $manifestValid = $false
        }
        $commandIds = [Collections.Generic.List[string]]::new()
        foreach ($command in @($evidenceManifest.commands)) {
            if (-not (Test-Topic05ProgressiveExactFields $command @('id', 'exit_code', 'status')) -or
                [string]$command.status -cnotin @(
                    'PASS', 'EXPECTED_FAIL', 'EXPECTED_NO_MATCH', 'PREDECESSOR_FAIL'
                )) {
                $manifestValid = $false; continue
            }
            [void]$commandIds.Add([string]$command.id)
        }
        foreach ($requiredCommand in @(
            'official_artifact_provision', 'real_main_retrieval', 'real_linked_retrieval',
            'candidate_index_missing', 'rpc_tool_discovery', 'strict_uninstall_pre_fix',
            'strict_uninstall_post_fix', 'deterministic_campaign'
        )) {
            if ($commandIds -cnotcontains $requiredCommand) { $manifestValid = $false }
        }
    }
    $results += New-Topic05ProgressiveBooleanResult $manifestValid 'T05-EVIDENCE-MANIFEST' `
        'The current-product manifest is closed, relative, unique, and complete' `
        'The current-product manifest is open, unsafe, duplicated, or incomplete'
    $results += New-Topic05ProgressiveBooleanResult $hashesValid 'T05-EVIDENCE-HASHES' `
        'Every declared current-product evidence byte matches its manifest digest' `
        'A declared current-product evidence file is missing or hash-drifted'

    $upstreams = Get-Topic05ProgressiveContent $RepositoryRoot 'registry/upstreams.yml'
    $adoption = Get-Topic05ProgressiveContent $RepositoryRoot 'registry/adoption-ledger.yml'
    $rejected = Get-Topic05ProgressiveContent $RepositoryRoot 'registry/rejected-mechanisms.yml'
    $registryValid = (Test-Topic05ProgressiveContainsAll $upstreams @(
        'id: codegraph', 'pinned_commit: ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6',
        'adopt-017', 'reject-018', 'reject-019'
    )) -and $adoption.Contains('id: adopt-017') -and $adoption.Contains('source: colbymchenry/codegraph') -and
        $rejected.Contains('id: reject-018') -and $rejected.Contains('id: reject-019')
    $results += New-Topic05ProgressiveBooleanResult $registryValid 'T05-REGISTRY-DISPOSITIONS' `
        'Registry references are reciprocal and close adopted/rejected subsets' 'Topic 05 registry IDs or reciprocal references are missing'

    $projectionMarkers = [ordered]@{
        'spec/key/01-dna.md' = '<!-- topic05-projection:dna -->'
        'spec/key/03-token-quality-model.md' = '<!-- topic05-projection:token -->'
        'spec/03-agent-topology.md' = '<!-- topic05-projection:topology -->'
        'spec/05-context-and-token-model.md' = '<!-- topic05-projection:context -->'
        'spec/07-retrieval-and-code-understanding.md' = '<!-- topic05-projection:retrieval -->'
        'spec/12-installation-and-rollback.md' = '<!-- topic05-projection:installation -->'
        'spec/13-validation-and-evaluation.md' = '<!-- topic05-projection:validation -->'
        'spec/14-upgradeability-and-governance.md' = '<!-- topic05-projection:governance -->'
        'spec/15-security-and-failure-recovery.md' = '<!-- topic05-projection:security -->'
        'spec/README.md' = '<!-- topic05-projection:spec-index -->'
        'spec/phases/phase-03-context-efficiency.md' = '<!-- topic05-projection:phase-03 -->'
        'spec/phases/phase-05-installation-hardening.md' = '<!-- topic05-projection:phase-05 -->'
        'spec/phases/phase-06-evaluation.md' = '<!-- topic05-projection:phase-06 -->'
        'README.md' = '<!-- topic05-doc:readme -->'
        'docs/architecture.md' = '<!-- topic05-doc:architecture -->'
        'docs/installation.md' = '<!-- topic05-doc:installation -->'
        'docs/customization.md' = '<!-- topic05-doc:customization -->'
        'docs/token-strategy.md' = '<!-- topic05-doc:token -->'
        'docs/security.md' = '<!-- topic05-doc:security -->'
        'docs/rollback.md' = '<!-- topic05-doc:rollback -->'
        'docs/workflow-v0.md' = '<!-- topic05-doc:workflow -->'
        'docs/policies/context-budget.md' = '<!-- topic05-doc:context-budget -->'
    }
    $missingMarkers = @()
    foreach ($entry in $projectionMarkers.GetEnumerator()) {
        if (-not (Get-Topic05ProgressiveContent $RepositoryRoot $entry.Key).Contains($entry.Value)) {
            $missingMarkers += $entry.Key
        }
    }
    $results += New-Topic05ProgressiveBooleanResult ($missingMarkers.Count -eq 0) 'T05-ACTIVE-PROJECTIONS' `
        'Every active authority and operator surface links to KD-029 ownership' ("Missing Topic 05 projection: {0}" -f ($missingMarkers -join ', '))

    $allActive = ($governed | Where-Object { $_ -match '^(spec|docs|README|registry)' } | ForEach-Object {
        Get-Topic05ProgressiveContent $RepositoryRoot $_
    }) -join "`n"
    $forbidden = @(
        'CodeGraph is enabled by default.',
        'CodeGraph is a universal default.',
        'Graph evidence is authoritative truth.',
        'Graph evidence alone proves absence.',
        'Retry CodeGraph opaquely until it works.',
        'Cheap Scout may execute changes, review candidates, and issue acceptance verdicts.',
        'Reviewer accepts inherited Scout evidence without rereading current source.',
        'Use one shared or symlinked .codegraph index across worktrees.',
        'Initialize CodeGraph lazily after the candidate is frozen.',
        'Let the model choose the CodeGraph executable, working directory, or environment.',
        'Configure CodeGraph as an MCP server with hooks and auto-update.'
    )
    $unsafe = @($forbidden | Where-Object { $allActive.IndexOf($_, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
    $results += New-Topic05ProgressiveBooleanResult ($unsafe.Count -eq 0) 'T05-NO-CONTRADICTIONS' `
        'No registered active contradiction to KD-029 is present' ("Active Topic 05 contradiction: {0}" -f ($unsafe -join ' | '))

    return $results
}
