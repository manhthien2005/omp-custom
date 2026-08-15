#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$validatorPath = Join-Path $repositoryRoot 'scripts\validate-round09-12-release-readiness.ps1'
$helperPath = Join-Path $repositoryRoot 'scripts\lib\round09-12-release-readiness.ps1'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-round0912-mutation-'
$tempRoots = [Collections.Generic.List[string]]::new()
$script:Assertions = 0

. $helperPath

function Assert-Round0912Validator {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function ConvertTo-Round0912MutationJson {
    param([Parameter(Mandatory)][object]$Value)
    return (($Value | ConvertTo-Json -Depth 64) -replace "`r`n", "`n") + "`n"
}

function Write-Round0912MutationJson {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][object]$Value
    )
    $parent = Split-Path $LiteralPath -Parent
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    [IO.File]::WriteAllText(
        $LiteralPath,
        (ConvertTo-Round0912MutationJson -Value $Value),
        [Text.UTF8Encoding]::new($false)
    )
}

function New-Round0912MutationRoot {
    $fixtureRoot = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $fixtureRoot)
    $fixtureRoot = [IO.Path]::GetFullPath($fixtureRoot)
    [void]$tempRoots.Add($fixtureRoot)

    $required = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($relative in @(Get-Round0912GovernedFiles)) {
        if (-not ([string]$relative).StartsWith('docs/evidence/current-product/round-09-12/', [StringComparison]::Ordinal)) {
            [void]$required.Add([string]$relative)
        }
    }
    [void]$required.Add('template/.omp/agents/reviewer.md')
    [void]$required.Add('scripts/lib/topic04-durable-state.ps1')

    foreach ($relative in @($required | Sort-Object)) {
        $source = Join-Path $repositoryRoot ($relative -replace '/', '\')
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "Mutation fixture source is missing: $relative"
        }
        $destination = Join-Path $fixtureRoot ($relative -replace '/', '\')
        $parent = Split-Path $destination -Parent
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            [void](New-Item -ItemType Directory -Path $parent -Force)
        }
        Copy-Item -LiteralPath $source -Destination $destination
    }
    return $fixtureRoot
}

function Invoke-Round0912MutationValidator {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [switch]$IncludeEvidence
    )

    $previousCapture = $env:OMP_ROUND0912_CAPTURE
    try {
        $env:OMP_ROUND0912_CAPTURE = ''
        $arguments = @(
            '-NoLogo', '-NoProfile', '-File', $validatorPath,
            '-RepositoryRoot', $FixtureRoot, '-Json', '-SkipRuntime', '-SkipDocumentation'
        )
        if (-not $IncludeEvidence) { $arguments += '-SkipEvidence' }
        $output = @(& pwsh @arguments 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        if ($null -eq $previousCapture) {
            Remove-Item Env:OMP_ROUND0912_CAPTURE -ErrorAction SilentlyContinue
        } else {
            $env:OMP_ROUND0912_CAPTURE = $previousCapture
        }
    }
    $jsonText = $output -join "`n"
    try { $result = $jsonText | ConvertFrom-Json -AsHashtable -ErrorAction Stop }
    catch { throw "Focused validator returned non-JSON output for mutation fixture: $jsonText" }
    return [pscustomobject]@{ ExitCode = [int]$exitCode; Result = $result }
}

function Set-Round0912TextMutation {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Old,
        [Parameter(Mandatory)][string]$New
    )

    $path = Join-Path $FixtureRoot ($RelativePath -replace '/', '\')
    $beforeHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    $text = Get-Content -Raw -LiteralPath $path -Encoding UTF8
    if (-not $text.Contains($Old, [StringComparison]::Ordinal)) {
        throw "Mutation anchor is unavailable: $RelativePath"
    }
    $mutated = $text.Replace($Old, $New, [StringComparison]::Ordinal)
    [IO.File]::WriteAllText($path, $mutated, [Text.UTF8Encoding]::new($false))
    $afterHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    Assert-Round0912Validator ($beforeHash -cne $afterHash) "Mutation did not change bytes: $RelativePath"
}

function Assert-Round0912MutationCaught {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$ExpectedCode,
        [switch]$IncludeEvidence
    )

    $validation = Invoke-Round0912MutationValidator -FixtureRoot $FixtureRoot -IncludeEvidence:$IncludeEvidence
    $rows = @($validation.Result.results | Where-Object { [string]$_.Code -ceq $ExpectedCode })
    Assert-Round0912Validator ($validation.ExitCode -ne 0) "Mutation unexpectedly passed: $ExpectedCode"
    Assert-Round0912Validator (
        $rows.Count -eq 1 -and [string]$rows[0].Status -ceq 'FAIL'
    ) "Mutation was not caught by $ExpectedCode."
}

function New-Round0912MutationEvidence {
    param([Parameter(Mandatory)][string]$FixtureRoot)

    $generatedAt = '2026-08-14T00:00:00.0000000Z'
    $emptyHash = [Convert]::ToHexString(
        [Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(''))
    ).ToLowerInvariant()
    $receipt = [ordered]@{
        name = 'mutation-baseline'
        command = 'model-free mutation baseline'
        exit_code = 0
        status = 'PASS'
        stdout_sha256 = $emptyHash
        stderr_sha256 = $emptyHash
    }
    $quality = [ordered]@{
        schema_version = 1
        record_type = 'round0912_quality_evidence'
        generated_at_utc = $generatedAt
        status = 'PASS'
        provider_calls = 0
        model_processes_started = 0
        scope = 'deterministic_current_product'
        case_ids = @('Q-VALID-REVIEW', 'Q-MISSING-INDEPENDENT-REVIEW', 'Q-STALE-CANDIDATE', 'Q-FALSE-COMPLETION')
        commands = @($receipt)
    }
    $security = [ordered]@{
        schema_version = 1
        record_type = 'round0912_security_evidence'
        generated_at_utc = $generatedAt
        status = 'PASS'
        provider_calls = 0
        model_processes_started = 0
        scope = 'deterministic_current_product'
        case_ids = @('S-SECRET-EVIDENCE', 'S-DESTRUCTIVE-NO-AUTHORITY', 'S-DUPLICATE-SIDE-EFFECT-RETRY', 'S-PARTIAL-OUTPUT')
        commands = @($receipt)
    }
    $evaluation = [ordered]@{
        schema_version = 1
        record_type = 'round0912_evaluation_evidence'
        generated_at_utc = $generatedAt
        status = 'PASS'
        provider_calls = 0
        model_processes_started = 0
        deterministic = [ordered]@{
            status = 'PASS'
            environment_status = 'PASS'
            cases_passed = 14
            verdicts = @('PROMOTE_EFFICIENCY', 'PROMOTE_QUALITY', 'REJECT', 'DEFER_INCONCLUSIVE')
        }
        campaign = [ordered]@{
            environment_status = 'NOT_RUN'
            promotion_verdict = 'DEFER_INCONCLUSIVE'
            reasons = @('model_assisted_campaign_not_authorized')
        }
        commands = @($receipt)
    }
    $release = [ordered]@{
        schema_version = 1
        record_type = 'round0912_release_readiness'
        generated_at_utc = $generatedAt
        status = 'IMPLEMENTED_NOT_PROMOTED'
        provider_calls = 0
        model_processes_started = 0
        live_install_performed = $false
        scratch_package = [ordered]@{
            status = 'PASS'
            omp_version = '17.2.12'
            assertions = 30
            live_target_modified = $false
        }
        adapters = [ordered]@{
            omp = [ordered]@{ status = 'IMPLEMENTED_NOT_PROMOTED'; installable = $true }
            claude = [ordered]@{ status = 'DESIGNED_NOT_VERIFIED'; installable = $false }
        }
        campaign = [ordered]@{ environment_status = 'NOT_RUN'; promotion_verdict = 'DEFER_INCONCLUSIVE' }
        limitations = @(
            'OMP_17_2_10_NOT_AVAILABLE',
            'CLAUDE_RUNTIME_NOT_VERIFIED',
            'MODEL_ASSISTED_ARMS_NOT_RUN',
            'SCRATCH_PROOF_NOT_LIVE_INSTALL'
        )
        commands = @($receipt)
    }

    $evidenceRoot = Join-Path $FixtureRoot 'docs\evidence\current-product\round-09-12'
    $records = [ordered]@{
        'quality.json' = $quality
        'security.json' = $security
        'evaluation.json' = $evaluation
        'release-readiness.json' = $release
    }
    $types = [ordered]@{
        'quality.json' = 'round0912_quality_evidence'
        'security.json' = 'round0912_security_evidence'
        'evaluation.json' = 'round0912_evaluation_evidence'
        'release-readiness.json' = 'round0912_release_readiness'
    }
    foreach ($entry in $records.GetEnumerator()) {
        Write-Round0912MutationJson -LiteralPath (Join-Path $evidenceRoot ([string]$entry.Key)) -Value $entry.Value
    }

    $fileRows = @($records.Keys | ForEach-Object {
        $name = [string]$_
        [ordered]@{
            path = $name
            sha256 = (Get-FileHash -LiteralPath (Join-Path $evidenceRoot $name) -Algorithm SHA256).Hash.ToLowerInvariant()
            record_type = [string]$types[$name]
        }
    })
    $governedRows = @(
        Get-Round0912GovernedFiles | Where-Object {
            -not ([string]$_).StartsWith('docs/evidence/current-product/round-09-12/', [StringComparison]::Ordinal)
        } | Sort-Object | ForEach-Object {
            $relative = [string]$_
            $path = Join-Path $FixtureRoot ($relative -replace '/', '\')
            [ordered]@{
                path = $relative
                sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
            }
        }
    )
    $manifest = [ordered]@{
        schema_version = 1
        record_type = 'round0912_current_product_manifest'
        generated_at_utc = $generatedAt
        status = 'PASS'
        provider_calls = 0
        model_processes_started = 0
        files = $fileRows
        governed_files = $governedRows
    }
    Write-Round0912MutationJson -LiteralPath (Join-Path $evidenceRoot 'manifest.json') -Value $manifest
}

function Remove-Round0912MutationRoot {
    param([Parameter(Mandatory)][string]$LiteralPath)

    $resolved = [IO.Path]::GetFullPath($LiteralPath).TrimEnd('\', '/')
    $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
    $leaf = [IO.Path]::GetFileName($resolved)
    if ($parent -cne $tempBase -or -not $leaf.StartsWith($tempPrefix, [StringComparison]::Ordinal)) {
        throw "Refusing unsafe mutation cleanup target: $resolved"
    }
    for ($attempt = 1; $attempt -le 10; $attempt++) {
        try {
            if ([IO.Directory]::Exists($resolved)) { [IO.Directory]::Delete($resolved, $true) }
        } catch {
            if ($attempt -eq 10) { throw }
        }
        if (-not [IO.Directory]::Exists($resolved)) { return }
        Start-Sleep -Milliseconds 100
    }
    throw "Mutation fixture still exists after bounded cleanup: $resolved"
}

try {
    Assert-Round0912Validator (Test-Path -LiteralPath $validatorPath -PathType Leaf) `
        'Focused Round 09-12 validator entry point is missing.'

    $baselineRoot = New-Round0912MutationRoot
    $baseline = Invoke-Round0912MutationValidator -FixtureRoot $baselineRoot
    $expectedCodes = @(
        'R0912-Q-CONTRACT', 'R0912-Q-SEVERITY', 'R0912-Q-EVIDENCE', 'R0912-Q-REVIEW',
        'R0912-S-IGNORE', 'R0912-S-SECRET', 'R0912-S-RECOVERY', 'R0912-S-TRUST',
        'R0912-E-CORE', 'R0912-E-FIXTURES', 'R0912-E-RUNNER', 'R0912-E-PROMOTION',
        'R0912-R-PHASES', 'R0912-R-PACKAGE', 'R0912-R-EVIDENCE', 'R0912-R-DOCS'
    )
    $actualCodes = @($baseline.Result.results | ForEach-Object { [string]$_.Code })
    Assert-Round0912Validator ($baseline.ExitCode -eq 0 -and [int]$baseline.Result.fail -eq 0) `
        'Unmutated pre-evidence fixture must pass before mutation controls run.'
    Assert-Round0912Validator (
        (($actualCodes | Sort-Object) -join '|') -ceq (($expectedCodes | Sort-Object) -join '|')
    ) "Focused validator codes drifted: $($actualCodes -join ', ')"
    Assert-Round0912Validator (@($actualCodes | Sort-Object -Unique).Count -eq $expectedCodes.Count) `
        'Focused validator emitted duplicate result codes.'

    $severityRoot = New-Round0912MutationRoot
    Set-Round0912TextMutation -FixtureRoot $severityRoot -RelativePath 'template/.omp/agents/reviewer.md' `
        -Old 'enum: [critical, important, minor]' -New 'enum: [minor]'
    Assert-Round0912MutationCaught -FixtureRoot $severityRoot -ExpectedCode 'R0912-Q-SEVERITY'

    $bindingRoot = New-Round0912MutationRoot
    Set-Round0912TextMutation -FixtureRoot $bindingRoot -RelativePath 'spec/10-verification-and-review.md' `
        -Old 'Every candidate mutation invalidates prior acceptance-bearing proof' `
        -New 'Candidate mutation may retain prior acceptance-bearing proof'
    Assert-Round0912MutationCaught -FixtureRoot $bindingRoot -ExpectedCode 'R0912-Q-EVIDENCE'

    $ignoreRoot = New-Round0912MutationRoot
    Set-Round0912TextMutation -FixtureRoot $ignoreRoot -RelativePath '.gitignore' `
        -Old 'evals/results/' -New 'evals/local-results/'
    Assert-Round0912MutationCaught -FixtureRoot $ignoreRoot -ExpectedCode 'R0912-S-IGNORE'

    $secretRoot = New-Round0912MutationRoot
    Set-Round0912TextMutation -FixtureRoot $secretRoot -RelativePath 'scripts/lib/round09-12-evaluation-core.mjs' `
        -Old '  /(?:api[_-]?key|password|secret|token|credential)\s*[:=]\s*\S+/iu,' `
        -New '  /ROUND0912_PATTERN_DISABLED/u,'
    Assert-Round0912MutationCaught -FixtureRoot $secretRoot -ExpectedCode 'R0912-S-SECRET'

    $trustRoot = New-Round0912MutationRoot
    Set-Round0912TextMutation -FixtureRoot $trustRoot -RelativePath 'scripts/run-round09-12-evaluation.ps1' `
        -Old 'if (-not $AllowProviderCalls) {' -New 'if ($false) {'
    Assert-Round0912MutationCaught -FixtureRoot $trustRoot -ExpectedCode 'R0912-S-TRUST'

    $verdictRoot = New-Round0912MutationRoot
    Set-Round0912TextMutation -FixtureRoot $verdictRoot -RelativePath 'scripts/lib/round09-12-evaluation-core.mjs' `
        -Old "  `"DEFER_INCONCLUSIVE`",`n]);" `
        -New "  `"DEFER_INCONCLUSIVE`",`n  `"PROMOTE_UNSAFE`",`n]);"
    Assert-Round0912MutationCaught -FixtureRoot $verdictRoot -ExpectedCode 'R0912-E-PROMOTION'

    $pilotRoot = New-Round0912MutationRoot
    Set-Round0912TextMutation -FixtureRoot $pilotRoot -RelativePath 'scripts/lib/round09-12-evaluation-core.mjs' `
        -Old '  if (campaign.phase === "pilot") return promotionResult("DEFER_INCONCLUSIVE", ["pilot_cannot_promote"]);' `
        -New '  if (campaign.phase === "pilot") return promotionResult("PROMOTE_EFFICIENCY", ["pilot_promoted"]);'
    Assert-Round0912MutationCaught -FixtureRoot $pilotRoot -ExpectedCode 'R0912-E-PROMOTION'

    $phaseRoot = New-Round0912MutationRoot
    Set-Round0912TextMutation -FixtureRoot $phaseRoot -RelativePath 'spec/phases/phase-06-evaluation.md' `
        -Old '<!-- round09-12-projection:evaluation -->' -New '<!-- round09-12-projection:removed -->'
    Assert-Round0912MutationCaught -FixtureRoot $phaseRoot -ExpectedCode 'R0912-R-PHASES'

    $evidenceRoot = New-Round0912MutationRoot
    New-Round0912MutationEvidence -FixtureRoot $evidenceRoot
    $evidenceBaseline = Invoke-Round0912MutationValidator -FixtureRoot $evidenceRoot -IncludeEvidence
    $evidenceBaselineFailures = @($evidenceBaseline.Result.results | Where-Object Status -ceq 'FAIL' |
        ForEach-Object { "$($_.Code): $($_.Message)" }) -join '; '
    Assert-Round0912Validator ($evidenceBaseline.ExitCode -eq 0 -and [int]$evidenceBaseline.Result.fail -eq 0) `
        "Closed mutation evidence baseline must pass before hash tampering: $evidenceBaselineFailures"
    $qualityPath = Join-Path $evidenceRoot 'docs\evidence\current-product\round-09-12\quality.json'
    $beforeEvidenceHash = (Get-FileHash -LiteralPath $qualityPath -Algorithm SHA256).Hash
    [IO.File]::AppendAllText($qualityPath, " `n", [Text.UTF8Encoding]::new($false))
    $afterEvidenceHash = (Get-FileHash -LiteralPath $qualityPath -Algorithm SHA256).Hash
    Assert-Round0912Validator ($beforeEvidenceHash -cne $afterEvidenceHash) 'Evidence hash mutation did not change bytes.'
    Assert-Round0912MutationCaught -FixtureRoot $evidenceRoot -ExpectedCode 'R0912-R-EVIDENCE' -IncludeEvidence

    Write-Host "PASS: Round 09-12 validator mutations ($script:Assertions assertions, 9 mutations)." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    foreach ($root in $tempRoots) { Remove-Round0912MutationRoot -LiteralPath $root }
}
