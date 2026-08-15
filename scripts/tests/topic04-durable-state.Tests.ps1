#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\topic04-durable-state.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    Write-Host 'FAIL [T04-TEST-HELPER] focused Topic 04 validator helper is missing' -ForegroundColor Red
    exit 1
}
. $helperPath

$script:Assertions = 0
$script:FixtureRoots = New-Object 'System.Collections.Generic.List[string]'

function Assert-Topic04Contract {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Get-Topic04LoadBearingFiles {
    return @(
        'docs/superpowers/specs/2026-08-13-topic-04-durable-task-state-candidate-handoff-offload-design.md',
        'spec/key/04-decision-log.md', 'spec/key/01-dna.md', 'spec/key/03-token-quality-model.md',
        'spec/01-target-architecture.md', 'spec/02-runtime-semantics.md', 'spec/04-workflow-sizing.md',
        'spec/05-context-and-token-model.md', 'spec/08-isolation-and-concurrency.md',
        'spec/10-verification-and-review.md', 'spec/12-installation-and-rollback.md',
        'spec/13-validation-and-evaluation.md', 'spec/14-upgradeability-and-governance.md',
        'spec/15-security-and-failure-recovery.md', 'spec/16-migration-plan.md', 'spec/README.md',
        'spec/phases/phase-02-core-orchestration.md', 'spec/phases/phase-03-context-efficiency.md',
        'spec/phases/phase-05-installation-hardening.md', 'spec/phases/phase-06-evaluation.md',
        'spec/phases/phase-07-stabilization.md', 'scripts/install-template.ps1',
        'template/.omp/state/manifest.json', 'template/.omp/state/PROTOCOL.md',
        'template/.omp/state/schemas/agent-tasks-v1.schema.json',
        'template/.omp/state/lib/AgentTasks.Retention.ps1',
        'docs/evidence/current-product/topic-04/adapter-gate.json',
        'README.md', 'docs/architecture.md', 'docs/workflow-v0.md', 'docs/security.md', 'docs/task-state.md'
    )
}

function New-Topic04ContractFixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('omp-topic04-contract-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $root)
    [void]$script:FixtureRoots.Add([IO.Path]::GetFullPath($root))
    foreach ($relative in Get-Topic04LoadBearingFiles) {
        $source = Join-Path $repositoryRoot $relative
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Load-bearing source is missing: $relative" }
        $destination = Join-Path $root $relative
        $parent = Split-Path -Parent $destination
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) { [void](New-Item -ItemType Directory -Path $parent -Force) }
        Copy-Item -LiteralPath $source -Destination $destination
    }
    return $root
}

function Update-Topic04FixtureText {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][scriptblock]$Mutation
    )
    $path = Join-Path $Root $RelativePath
    $before = Get-Content -Raw -LiteralPath $path -Encoding UTF8
    $after = & $Mutation $before
    if ($after -ceq $before) { throw "Mutation did not change $RelativePath" }
    Set-Content -LiteralPath $path -Value $after -Encoding UTF8 -NoNewline
}

function Assert-Topic04MutationCaught {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$ExpectedCode,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][scriptblock]$Mutation
    )
    $root = New-Topic04ContractFixture
    Update-Topic04FixtureText -Root $root -RelativePath $RelativePath -Mutation $Mutation
    $results = @(Test-Topic04DurableStateContract -RepositoryRoot $root)
    $failCodes = @($results | Where-Object Status -eq 'FAIL' | ForEach-Object Code)
    Assert-Topic04Contract ($failCodes -contains $ExpectedCode) "[$Name] expected $ExpectedCode, got: $($failCodes -join ', ')"
}

try {
    $results = @(Test-Topic04DurableStateContract -RepositoryRoot $repositoryRoot)
    $failures = @($results | Where-Object Status -eq 'FAIL')
    $failureCodes = @($failures | ForEach-Object Code)
    Assert-Topic04Contract ($failures.Count -eq 0) "Repository contract failures: $($failureCodes -join ', ')"
    $requirements = @($results | Where-Object Code -like 'T04-REQ-*')
    Assert-Topic04Contract ($requirements.Count -eq 25 -and @($requirements | Where-Object Status -ne 'PASS').Count -eq 0) 'All 25 approved design requirements must have explicit passing guards.'

    Assert-Topic04MutationCaught -Name 'git-common-root' -ExpectedCode 'T04-ROOT-GIT-COMMON' `
        -RelativePath 'spec/key/04-decision-log.md' -Mutation { param($text) $text.Replace('<absolute-git-common-dir>/agent-tasks', '<worktree>/.task') }
    Assert-Topic04MutationCaught -Name 'plural-namespace' -ExpectedCode 'T04-ROOT-NAMESPACE' `
        -RelativePath 'spec/key/04-decision-log.md' -Mutation { param($text) $text.Replace('git_root: <absolute-git-common-dir>/agent-tasks', 'git_root: <absolute-git-common-dir>/agent-task') }
    Assert-Topic04MutationCaught -Name 'transcript-authority' -ExpectedCode 'T04-STATE-AUTHORITY' `
        -RelativePath 'spec/key/01-dna.md' -Mutation { param($text) $text + "`nTranscript becomes the lifecycle source of truth.`n" }
    Assert-Topic04MutationCaught -Name 'mutable-revision' -ExpectedCode 'T04-REVISION-IMMUTABLE' `
        -RelativePath 'spec/02-runtime-semantics.md' -Mutation { param($text) $text + "`nUse current.json with last-write-wins state updates.`n" }
    Assert-Topic04MutationCaught -Name 'automatic-takeover' -ExpectedCode 'T04-WRITER-LEASE' `
        -RelativePath 'spec/02-runtime-semantics.md' -Mutation { param($text) $text.Replace('There is no heartbeat TTL', 'A heartbeat timeout triggers automatic takeover') }
    Assert-Topic04MutationCaught -Name 'shared-writer-worktree' -ExpectedCode 'T04-WORKTREE-RESERVATION' `
        -RelativePath 'spec/08-isolation-and-concurrency.md' -Mutation { param($text) $text.Replace('distinct authoritative worktree', 'shared authoritative worktree') }
    Assert-Topic04MutationCaught -Name 'model-owned-output-list' -ExpectedCode 'T04-CANDIDATE-SCOPE' `
        -RelativePath 'spec/10-verification-and-review.md' -Mutation { param($text) $text + "`nThe model supplies the final owned-output list.`n" }
    Assert-Topic04MutationCaught -Name 'old-evidence-after-mutation' -ExpectedCode 'T04-CANDIDATE-EVIDENCE' `
        -RelativePath 'spec/10-verification-and-review.md' -Mutation { param($text) $text.Replace('old candidate evidence cannot be accepted after mutation', 'old candidate evidence may be accepted after mutation') }
    Assert-Topic04MutationCaught -Name 'global-evidence-ttl' -ExpectedCode 'T04-EVIDENCE-TTL' `
        -RelativePath 'spec/key/03-token-quality-model.md' -Mutation { param($text) $text + "`nUse a global evidence TTL for every proof.`n" }
    Assert-Topic04MutationCaught -Name 'prose-transfer' -ExpectedCode 'T04-HANDOFF-TRANSFER' `
        -RelativePath 'spec/02-runtime-semantics.md' -Mutation { param($text) $text + "`nHandoff prose alone transfers ownership.`n" }
    Assert-Topic04MutationCaught -Name 'artifact-authority' -ExpectedCode 'T04-OFFLOAD-AUTHORITY' `
        -RelativePath 'spec/05-context-and-token-model.md' -Mutation { param($text) $text + "`nartifact:// and .task become lifecycle authority.`n" }
    Assert-Topic04MutationCaught -Name 'schema-secret-boundary' -ExpectedCode 'T04-SECRET-BOUNDARY' `
        -RelativePath 'template/.omp/state/schemas/agent-tasks-v1.schema.json' -Mutation { param($text) $text.Replace('            "transcript",' + "`n", '') }
    Assert-Topic04MutationCaught -Name 'automatic-destructive-cleanup' -ExpectedCode 'T04-CLEANUP-SAFETY' `
        -RelativePath 'spec/15-security-and-failure-recovery.md' -Mutation { param($text) $text + "`nCleanup automatically purges and runs git worktree remove.`n" }
    Assert-Topic04MutationCaught -Name 'unprobed-hook' -ExpectedCode 'T04-ADAPTER-GATE' `
        -RelativePath 'docs/evidence/current-product/topic-04/adapter-gate.json' -Mutation { param($text) $text.Replace('"automatic_lifecycle_adapter": "NOT_INSTALLED"', '"automatic_lifecycle_adapter": "INSTALLED"') }
    Assert-Topic04MutationCaught -Name 'installer-omits-state' -ExpectedCode 'T04-INSTALL-COMPONENT' `
        -RelativePath 'scripts/install-template.ps1' -Mutation { param($text) $text.Replace('    "state"     = "state"' + "`n", '') }
    Assert-Topic04MutationCaught -Name 'phase-consumer-missing' -ExpectedCode 'T04-PHASE-OWNERSHIP' `
        -RelativePath 'spec/phases/phase-03-context-efficiency.md' -Mutation { param($text) $text.Replace('Topic 04 consumes checkpoints, handoff, and offload boundaries.', '') }

    Write-Host ("PASS Topic 04 durable-state contract ({0} assertions)" -f $script:Assertions) -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("FAIL [T04-TEST] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    foreach ($path in @($script:FixtureRoots)) {
        $resolved = [IO.Path]::GetFullPath($path).TrimEnd('\', '/')
        $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
        if ([IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/') -cne $temp -or -not [IO.Path]::GetFileName($resolved).StartsWith('omp-topic04-contract-', [StringComparison]::Ordinal)) {
            throw "Refusing unsafe Topic 04 contract cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
}
