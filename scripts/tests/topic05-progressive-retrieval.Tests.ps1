#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\topic05-progressive-retrieval.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    Write-Host 'FAIL [T05-TEST-HELPER] focused Topic 05 validator helper is missing' -ForegroundColor Red
    exit 1
}
. $helperPath

$script:Assertions = 0
$script:FixtureRoots = New-Object 'System.Collections.Generic.List[string]'

function Assert-Topic05Progressive {
    param([bool]$Condition, [string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function New-Topic05ProgressiveFixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('omp-topic05-contract-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $root)
    [void]$script:FixtureRoots.Add([IO.Path]::GetFullPath($root))
    foreach ($relative in Get-Topic05ProgressiveGovernedFiles) {
        $source = Join-Path $repositoryRoot ($relative -replace '/', '\')
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Governed source is missing: $relative" }
        $destination = Join-Path $root ($relative -replace '/', '\')
        [void](New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force)
        Copy-Item -LiteralPath $source -Destination $destination
    }
    return $root
}

function Update-Topic05ProgressiveFixture {
    param([string]$Root, [string]$RelativePath, [scriptblock]$Mutation)
    $path = Join-Path $Root ($RelativePath -replace '/', '\')
    $before = Get-Content -Raw -LiteralPath $path -Encoding UTF8
    $after = & $Mutation $before
    if ($after -ceq $before) { throw "Mutation did not change $RelativePath" }
    Set-Content -LiteralPath $path -Value $after -Encoding UTF8 -NoNewline
}

function Assert-Topic05ProgressiveMutationCaught {
    param([string]$Name, [string]$ExpectedCode, [string]$RelativePath, [scriptblock]$Mutation)
    $root = New-Topic05ProgressiveFixture
    Update-Topic05ProgressiveFixture -Root $root -RelativePath $RelativePath -Mutation $Mutation
    $failCodes = @(Test-Topic05ProgressiveRetrievalContract -RepositoryRoot $root |
        Where-Object Status -eq FAIL | ForEach-Object Code)
    Assert-Topic05Progressive ($failCodes -contains $ExpectedCode) `
        "[$Name] expected $ExpectedCode, got: $($failCodes -join ', ')"
}

try {
    $live = @(Test-Topic05ProgressiveRetrievalContract -RepositoryRoot $repositoryRoot)
    $liveFailures = @($live | Where-Object Status -eq FAIL)
    Assert-Topic05Progressive ($liveFailures.Count -eq 0) `
        "Live contract failures: $(($liveFailures | ForEach-Object Code) -join ', ')"
    $liveCodes = @($live | ForEach-Object Code)
    foreach ($evidenceCode in @(
        'T05-EVIDENCE-DISPOSITION', 'T05-EVIDENCE-MANIFEST', 'T05-EVIDENCE-HASHES'
    )) {
        Assert-Topic05Progressive ($liveCodes -ccontains $evidenceCode) `
            "Live contract did not enforce $evidenceCode."
    }
    Assert-Topic05Progressive (@(Get-Topic05ProgressiveGovernedFiles | Where-Object {
        $_ -like 'docs/evidence/phase-00/*' -or $_ -like 'docs/research/*'
    }).Count -eq 0) 'Historical Phase 00 evidence and fenced research must stay outside the Topic 05 rewrite set.'

    Assert-Topic05ProgressiveMutationCaught 'default-on' 'T05-DEFAULT-OFF' 'scripts/install-template.ps1' {
        param($t) $t.Replace('"agents-md", "rules-md", "config"', '"agents-md", "rules-md", "config", "codegraph"')
    }
    Assert-Topic05ProgressiveMutationCaught 'pin-identity' 'T05-UPSTREAM-PIN' 'template/.omp/codegraph/upstream-lock.json' {
        param($t) $t.Replace('"version": "1.5.0"', '"version": "latest"')
    }
    Assert-Topic05ProgressiveMutationCaught 'artifact-digest' 'T05-ARTIFACT-DIGESTS' 'template/.omp/codegraph/upstream-lock.json' {
        param($t) $t.Replace('cf5ee435a6e44d097b2f98f2b7b8b9422bb1094844404efed82519c5da1af2cf', ('0' * 64))
    }
    Assert-Topic05ProgressiveMutationCaught 'mcp-hooks-update' 'T05-NO-CONTRADICTIONS' 'docs/retrieval.md' {
        param($t) $t + "`nConfigure CodeGraph as an MCP server with hooks and auto-update.`n"
    }
    Assert-Topic05ProgressiveMutationCaught 'model-input-authority' 'T05-NO-CONTRADICTIONS' 'docs/retrieval.md' {
        param($t) $t + "`nLet the model choose the CodeGraph executable, working directory, or environment.`n"
    }
    Assert-Topic05ProgressiveMutationCaught 'shared-index' 'T05-NO-CONTRADICTIONS' 'docs/retrieval.md' {
        param($t) $t + "`nUse one shared or symlinked .codegraph index across worktrees.`n"
    }
    Assert-Topic05ProgressiveMutationCaught 'candidate-lazy-init' 'T05-NO-CONTRADICTIONS' 'docs/retrieval.md' {
        param($t) $t + "`nInitialize CodeGraph lazily after the candidate is frozen.`n"
    }
    Assert-Topic05ProgressiveMutationCaught 'topic04-postcheck' 'T05-STATE-BINDING' 'template/.omp/codegraph/codegraph-process.ps1' {
        param($t) $t.Replace("Throw-Topic05CodeGraphReason -Reason 'source_changed'", "Throw-Topic05CodeGraphReason -Reason 'query_failed'")
    }
    Assert-Topic05ProgressiveMutationCaught 'graph-truth' 'T05-NO-CONTRADICTIONS' 'docs/retrieval.md' {
        param($t) $t + "`nGraph evidence is authoritative truth.`n"
    }
    Assert-Topic05ProgressiveMutationCaught 'absence-proof' 'T05-NO-CONTRADICTIONS' 'docs/retrieval.md' {
        param($t) $t + "`nGraph evidence alone proves absence.`n"
    }
    Assert-Topic05ProgressiveMutationCaught 'opaque-retry' 'T05-NO-CONTRADICTIONS' 'docs/retrieval.md' {
        param($t) $t + "`nRetry CodeGraph opaquely until it works.`n"
    }
    Assert-Topic05ProgressiveMutationCaught 'scout-authority' 'T05-NO-CONTRADICTIONS' 'spec/03-agent-topology.md' {
        param($t) $t + "`nCheap Scout may execute changes, review candidates, and issue acceptance verdicts.`n"
    }
    Assert-Topic05ProgressiveMutationCaught 'reviewer-inheritance' 'T05-NO-CONTRADICTIONS' 'spec/03-agent-topology.md' {
        param($t) $t + "`nReviewer accepts inherited Scout evidence without rereading current source.`n"
    }
    Assert-Topic05ProgressiveMutationCaught 'native-contamination' 'T05-NATIVE-CONTAMINATION' 'evals/retrieval/topic05/fixtures.json' {
        param($t) $t.Replace('"separate_capability_targets": true', '"separate_capability_targets": false')
    }
    Assert-Topic05ProgressiveMutationCaught 'spend-confirmation' 'T05-SPEND-TELEMETRY' 'scripts/lib/topic05-benchmark.ps1' {
        param($t) $t.Replace('RUN_TOPIC05_MODEL_PILOT', 'RUN_MODEL_NOW')
    }
    Assert-Topic05ProgressiveMutationCaught 'deepseek-block' 'T05-DEEPSEEK-DISPOSITION' 'scripts/lib/topic05-benchmark.ps1' {
        param($t) $t.Replace('ENVIRONMENT_BLOCKED', 'COMPLETED_WITH_SUBSTITUTE')
    }
    Assert-Topic05ProgressiveMutationCaught 'universal-promotion' 'T05-NO-CONTRADICTIONS' 'docs/retrieval.md' {
        param($t) $t + "`nCodeGraph is a universal default.`n"
    }
    Assert-Topic05ProgressiveMutationCaught 'missing-active-projection' 'T05-ACTIVE-PROJECTIONS' 'spec/07-retrieval-and-code-understanding.md' {
        param($t) $t.Replace('<!-- topic05-projection:retrieval -->', '<!-- removed-topic05-projection -->')
    }
    Assert-Topic05ProgressiveMutationCaught 'registry-reciprocity' 'T05-REGISTRY-DISPOSITIONS' 'registry/upstreams.yml' {
        param($t) $t.Replace('reject-019', 'reject-missing')
    }
    Assert-Topic05ProgressiveMutationCaught 'evidence-promotion' 'T05-EVIDENCE-DISPOSITION' `
        'docs/evidence/current-product/topic-05/deterministic.json' {
        param($t) $t.Replace('"promotion": false', '"promotion": true')
    }
    Assert-Topic05ProgressiveMutationCaught 'evidence-model-claim' 'T05-EVIDENCE-DISPOSITION' `
        'docs/evidence/current-product/topic-05/model-campaign.json' {
        param($t) $t.Replace('"status": "NOT_RUN"', '"status": "PASS"')
    }
    Assert-Topic05ProgressiveMutationCaught 'evidence-byte-drift' 'T05-EVIDENCE-HASHES' `
        'docs/retrieval.md' {
        param($t) $t + "`nEvidence manifest drift fixture.`n"
    }
    Assert-Topic05ProgressiveMutationCaught 'evidence-manifest-open' 'T05-EVIDENCE-MANIFEST' `
        'docs/evidence/current-product/topic-05/manifest.json' {
        param($t) $t.TrimEnd().TrimEnd('}') + ',"unexpected":true}'
    }

    Write-Host ("PASS Topic 05 progressive-retrieval contract ({0} assertions)" -f $script:Assertions) -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("FAIL [T05-TEST] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    foreach ($path in @($script:FixtureRoots)) {
        $resolved = [IO.Path]::GetFullPath($path).TrimEnd('\', '/')
        $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
        if ([IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/') -cne $temp -or
            -not [IO.Path]::GetFileName($resolved).StartsWith('omp-topic05-contract-', [StringComparison]::Ordinal)) {
            throw "Refusing unsafe Topic 05 fixture cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
}
