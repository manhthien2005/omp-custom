#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\topic06-agent-boundary.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) { throw 'Topic 06 validator helper is missing.' }
. $helperPath

$script:Assertions = 0
$script:FixtureRoots = [Collections.Generic.List[string]]::new()

function Assert-Topic06ValidatorMutation {
    param([bool]$Condition, [string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function New-Topic06ValidatorFixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('omp-topic06-validator-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $root)
    [void]$script:FixtureRoots.Add([IO.Path]::GetFullPath($root))
    foreach ($relative in Get-Topic06AgentBoundaryGovernedFiles) {
        $source = Join-Path $repositoryRoot ($relative -replace '/', '\')
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Governed source is missing: $relative" }
        $destination = Join-Path $root ($relative -replace '/', '\')
        [void](New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force)
        Copy-Item -LiteralPath $source -Destination $destination
    }
    return $root
}

function Update-Topic06ValidatorFixture {
    param([string]$Root, [string]$RelativePath, [scriptblock]$Mutation)
    $path = Join-Path $Root ($RelativePath -replace '/', '\')
    $before = Get-Content -Raw -LiteralPath $path -Encoding UTF8
    $after = & $Mutation $before
    if ($after -ceq $before) { throw "Mutation did not change $RelativePath" }
    Set-Content -LiteralPath $path -Value $after -Encoding UTF8 -NoNewline
}

function Assert-Topic06MutationCaught {
    param([string]$Name, [string]$ExpectedCode, [string]$RelativePath, [scriptblock]$Mutation)
    $root = New-Topic06ValidatorFixture
    Update-Topic06ValidatorFixture -Root $root -RelativePath $RelativePath -Mutation $Mutation
    $failCodes = @(Test-Topic06AgentBoundaryContract -RepositoryRoot $root |
        Where-Object Status -eq FAIL | ForEach-Object Code)
    Assert-Topic06ValidatorMutation ($failCodes -ccontains $ExpectedCode) `
        "[$Name] expected $ExpectedCode, got: $($failCodes -join ', ')"
}

try {
    $live = @(Test-Topic06AgentBoundaryContract -RepositoryRoot $repositoryRoot)
    $liveFailures = @($live | Where-Object Status -eq FAIL)
    Assert-Topic06ValidatorMutation ($liveFailures.Count -eq 0) `
        "Live contract failures: $(($liveFailures | ForEach-Object Code) -join ', ')"

    $missingRoot = New-Topic06ValidatorFixture
    Remove-Item -LiteralPath (Join-Path $missingRoot 'docs\agent-boundaries.md') -Force
    $missingCodes = @(Test-Topic06AgentBoundaryContract -RepositoryRoot $missingRoot |
        Where-Object Status -eq FAIL | ForEach-Object Code)
    Assert-Topic06ValidatorMutation ($missingCodes -ccontains 'T06-REQUIRED-FILES') `
        'A missing required authority surface was not rejected.'

    Assert-Topic06MutationCaught 'decision' 'T06-DECISION-KD030' 'spec/key/04-decision-log.md' {
        param($t) $t.Replace('<!-- topic06-authority:kd-030 -->', '<!-- topic06-authority:missing -->')
    }
    Assert-Topic06MutationCaught 'manifest' 'T06-COMPONENT-MANIFEST' 'template/.omp/contracts/component-manifest.json' {
        param($t) [regex]::Replace($t, '"component_version": "\d+\.\d+\.\d+"', '"component_version": "0.0.0"')
    }
    Assert-Topic06MutationCaught 'portable-core' 'T06-BOUNDARY-CORE' 'template/.omp/contracts/agent-boundary-core.mjs' {
        param($t) $t.Replace('record_type: "agent_boundary_receipt"', 'record_type: "raw_agent_result"')
    }
    Assert-Topic06MutationCaught 'state-projection' 'T06-STATE-PROJECTION' 'template/.omp/state/agent-tasks.ps1' {
        param($t) $t.Replace("'project-work-unit'", "'project-work-unit-disabled'")
    }
    Assert-Topic06MutationCaught 'agent-contract' 'T06-AGENT-CONTRACTS' 'template/.omp/agents/worker.md' {
        param($t) $t.Replace('blocking: true', 'blocking: false')
    }
    Assert-Topic06MutationCaught 'native-delegation' 'T06-WRAPPER' 'template/.omp/extensions/agent-task-boundary.js' {
        param($t) $t.Replace('ctx.invokeTool(buildNativeTaskParams(prepared), { signal, onUpdate })', 'Promise.resolve({ content: [] })')
    }
    Assert-Topic06MutationCaught 'trusted-launcher' 'T06-LAUNCHER' 'template/.omp/bin/omp-managed.ps1' {
        param($t) $t.Replace("'--trusted-extension'", "'--extension'")
    }
    Assert-Topic06MutationCaught 'route-identity' 'T06-ROUTING' 'template/.omp/config.yml' {
        param($t) $t.Replace('omniroute/ds/deepseek-v4-pro:xhigh', 'omniroute/ds/deepseek-v4-pro:high')
    }
    Assert-Topic06MutationCaught 'forced-partial' 'T06-SOFT-BUDGET' 'template/.omp/contracts/managed-runtime.yml' {
        param($t) $t.Replace('softRequestBudget: 200', 'softRequestBudget: 201')
    }
    Assert-Topic06MutationCaught 'managed-modes' 'T06-EXECUTION-MODES' 'docs/agent-boundaries.md' {
        param($t) $t.Replace('**Async:** rejected in managed v1.', '**Async:** accepted in managed v1.')
    }
    Assert-Topic06MutationCaught 'reviewer-claim' 'T06-REVIEWER-INDEPENDENCE' 'docs/agent-boundaries.md' {
        param($t) $t.Replace('Worker CLAIM + Worker narrative', 'Worker narrative')
    }
    Assert-Topic06MutationCaught 'schema-retirement' 'T06-SCHEMA-RETIREMENT' 'scripts/install-template.ps1' {
        param($t) $t.Replace("`$_ -ieq 'schemas'", "`$_ -ieq 'schemas-disabled'")
    }
    Assert-Topic06MutationCaught 'rollback' 'T06-INSTALL-ROLLBACK' 'scripts/uninstall-template.ps1' {
        param($t) $t.Replace("'agent_boundary_install_record'", "'agent_boundary_install_record_disabled'")
    }
    Assert-Topic06MutationCaught 'phase-projection' 'T06-AUTHORITY-PROJECTIONS' 'spec/phases/phase-06-evaluation.md' {
        param($t) $t.Replace('<!-- topic06-projection:phase-06 -->', '<!-- topic06-projection:missing -->')
    }
    Assert-Topic06MutationCaught 'open-scope' 'T06-OPEN-SCOPE' 'docs/agent-boundaries.md' {
        param($t) $t.Replace('It is not a requirement', 'It is a mandatory requirement')
    }
    Assert-Topic06MutationCaught 'semantic-fail-open' 'T06-NO-FAIL-OPEN' 'docs/agent-boundaries.md' {
        param($t) $t + "`nBare OMP output may be accepted as a managed receipt when the wrapper is unavailable.`n"
    }
    Assert-Topic06MutationCaught 'evidence-status' 'T06-EVIDENCE' 'docs/evidence/current-product/topic-06/deterministic.json' {
        param($t) $t.Replace('"status": "PASS"', '"status": "FAIL"')
    }
    Assert-Topic06MutationCaught 'evidence-hash' 'T06-EVIDENCE-HASHES' 'docs/evidence/current-product/topic-06/deterministic.json' {
        param($t) $t.Replace('"provider_calls": 0', '"provider_calls": 1')
    }

    Write-Host "PASS: Topic 06 validator mutations ($script:Assertions assertions)." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    foreach ($root in $script:FixtureRoots) {
        $resolved = [IO.Path]::GetFullPath($root)
        $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
        if (-not $resolved.StartsWith($temp + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
            [IO.Path]::GetFileName($resolved) -notlike 'omp-topic06-validator-*') {
            throw "Refusing unsafe Topic 06 validator cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
}
