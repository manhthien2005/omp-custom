param(
    [ValidateSet('Deterministic', 'Campaign')]
    [string]$Mode = 'Deterministic',

    [string]$OutputDirectory,
    [string]$OmpPath,
    [switch]$AllowProviderCalls,
    [ValidateRange(0, 1000000)]
    [int]$EvidenceBudget = 0,
    [string]$FixtureManifest,
    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$defaultResultsRoot = [IO.Path]::GetFullPath((Join-Path $repositoryRoot 'evals\results'))
$systemTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$userProfileRoot = [IO.Path]::GetFullPath([Environment]::GetFolderPath('UserProfile'))

function Test-Round0912PathWithin {
    param(
        [Parameter(Mandatory)][string]$Candidate,
        [Parameter(Mandatory)][string]$Parent
    )
    $candidateFull = [IO.Path]::GetFullPath($Candidate).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $parentFull = [IO.Path]::GetFullPath($Parent).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    return $candidateFull.Equals($parentFull, [StringComparison]::OrdinalIgnoreCase) -or
        $candidateFull.StartsWith("$parentFull$([IO.Path]::DirectorySeparatorChar)", [StringComparison]::OrdinalIgnoreCase)
}

function Get-Round0912Sha256Text {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
}

function Write-Round0912Record {
    param(
        [Parameter(Mandatory)][Collections.IDictionary]$Record,
        [Parameter(Mandatory)][string]$Path
    )
    if (Test-Path -LiteralPath $Path) {
        throw "Refusing to overwrite immutable evaluation result: $Path"
    }
    $json = $Record | ConvertTo-Json -Depth 32
    [IO.File]::WriteAllText($Path, "$json`n", [Text.UTF8Encoding]::new($false))
}

function New-Round0912BoundaryRecord {
    param(
        [Parameter(Mandatory)][ValidateSet('NOT_RUN', 'ENVIRONMENT_BLOCKED')][string]$EnvironmentStatus,
        [Parameter(Mandatory)][string]$Reason,
        [Parameter(Mandatory)][string]$ManifestSha256
    )
    return [ordered]@{
        schema_version = 1
        record_type = 'round0912_evaluation_run'
        mode = 'campaign'
        status = $EnvironmentStatus
        environment_status = $EnvironmentStatus
        reasons = @($Reason)
        fixture_manifest_sha256 = $ManifestSha256
        provider_calls = 0
        model_processes_started = 0
        runtime_processes_started = 0
        promotion = [ordered]@{
            verdict = 'DEFER_INCONCLUSIVE'
            reasons = @($(if ($EnvironmentStatus -eq 'ENVIRONMENT_BLOCKED') { 'environment_blocked' } else { 'campaign_not_run' }))
            eligible = $false
        }
    }
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = $defaultResultsRoot
}
$resolvedOutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$outputDriveRoot = [IO.Path]::GetPathRoot($resolvedOutputDirectory)
if ($resolvedOutputDirectory.Equals($repositoryRoot, [StringComparison]::OrdinalIgnoreCase) -or
    $resolvedOutputDirectory.Equals($outputDriveRoot, [StringComparison]::OrdinalIgnoreCase) -or
    $resolvedOutputDirectory.Equals($userProfileRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing unsafe evaluation output directory: $resolvedOutputDirectory"
}
$outputIsLocalResults = Test-Round0912PathWithin -Candidate $resolvedOutputDirectory -Parent $defaultResultsRoot
$outputIsTemporary = (Test-Round0912PathWithin -Candidate $resolvedOutputDirectory -Parent $systemTempRoot) -and
    -not $resolvedOutputDirectory.Equals($systemTempRoot.TrimEnd([IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)
if (-not $outputIsLocalResults -and -not $outputIsTemporary) {
    throw 'Evaluation output must stay under evals/results or a caller-supplied system temp directory.'
}
[IO.Directory]::CreateDirectory($resolvedOutputDirectory) | Out-Null
$resultPath = Join-Path $resolvedOutputDirectory 'round09-12-evaluation.json'

if ([string]::IsNullOrWhiteSpace($FixtureManifest)) {
    $FixtureManifest = Join-Path $repositoryRoot 'evals\round09-12\manifest.json'
}
$resolvedFixtureManifest = [IO.Path]::GetFullPath($FixtureManifest)
if (-not (Test-Path -LiteralPath $resolvedFixtureManifest -PathType Leaf)) {
    throw "Fixture manifest is unavailable: $resolvedFixtureManifest"
}
$manifestSha256 = (Get-FileHash -LiteralPath $resolvedFixtureManifest -Algorithm SHA256).Hash.ToLowerInvariant()

if ($Mode -eq 'Deterministic') {
    $corePath = Join-Path $PSScriptRoot 'lib\round09-12-evaluation-core.mjs'
    $node = Get-Command node -CommandType Application -ErrorAction Stop
    $nodeOutput = & $node.Source $corePath --fixture-manifest $resolvedFixtureManifest --output $resultPath 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Deterministic evaluation failed with exit code $LASTEXITCODE."
    }
    Write-Host 'Round 09-12 deterministic evaluation PASS (provider_calls=0, model_processes_started=0).'
    exit 0
}

if (-not $AllowProviderCalls) {
    Write-Round0912Record -Record (New-Round0912BoundaryRecord -EnvironmentStatus NOT_RUN -Reason 'provider_calls_not_authorized' -ManifestSha256 $manifestSha256) -Path $resultPath
    Write-Host 'Campaign NOT_RUN: provider calls were not explicitly authorized.'
    exit 3
}
if ($EvidenceBudget -lt 1) {
    Write-Round0912Record -Record (New-Round0912BoundaryRecord -EnvironmentStatus NOT_RUN -Reason 'evidence_budget_missing' -ManifestSha256 $manifestSha256) -Path $resultPath
    Write-Host 'Campaign NOT_RUN: a positive evidence budget is required.'
    exit 3
}
if ([string]::IsNullOrWhiteSpace($OmpPath)) {
    $OmpPath = ''
}
$resolvedOmpPath = if ($OmpPath) { [IO.Path]::GetFullPath($OmpPath) } else { '' }
if (-not $resolvedOmpPath -or -not (Test-Path -LiteralPath $resolvedOmpPath -PathType Leaf)) {
    Write-Round0912Record -Record (New-Round0912BoundaryRecord -EnvironmentStatus ENVIRONMENT_BLOCKED -Reason 'runtime_unavailable' -ManifestSha256 $manifestSha256) -Path $resultPath
    Write-Host 'Campaign ENVIRONMENT_BLOCKED: runtime unavailable.'
    exit 0
}

$scratchRoot = $null
try {
    $scratchRoot = [IO.Path]::GetFullPath((Join-Path $systemTempRoot ("omp-round0912-campaign-$([guid]::NewGuid().ToString('N'))")))
    if (-not (Test-Round0912PathWithin -Candidate $scratchRoot -Parent $systemTempRoot) -or
        -not ([IO.Path]::GetFileName($scratchRoot)).StartsWith('omp-round0912-campaign-', [StringComparison]::Ordinal)) {
        throw 'Refusing unsafe campaign scratch path.'
    }
    [IO.Directory]::CreateDirectory($scratchRoot) | Out-Null
    $gitOutput = & git -C $scratchRoot init --quiet 2>&1
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $scratchRoot '.git') -PathType Container)) {
        throw 'Unable to materialize the scratch Git repository.'
    }

    $prompt = "ROUND0912_CAMPAIGN fixture_manifest_sha256=$manifestSha256 evidence_budget=$EvidenceBudget"
    $isFakeRuntime = [IO.Path]::GetFileName($resolvedOmpPath) -ceq 'round09-12-fake-omp.mjs'
    $processInfo = [Diagnostics.ProcessStartInfo]::new()
    $processInfo.UseShellExecute = $false
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.CreateNoWindow = $true
    $processInfo.WorkingDirectory = $scratchRoot
    if ([IO.Path]::GetExtension($resolvedOmpPath) -ceq '.mjs') {
        $node = Get-Command node -CommandType Application -ErrorAction Stop
        $processInfo.FileName = $node.Source
        [void]$processInfo.ArgumentList.Add($resolvedOmpPath)
        [void]$processInfo.ArgumentList.Add($prompt)
    } else {
        $processInfo.FileName = $resolvedOmpPath
        [void]$processInfo.ArgumentList.Add('-p')
        [void]$processInfo.ArgumentList.Add($prompt)
    }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $processInfo
    if (-not $process.Start()) { throw 'Campaign runtime process failed to start.' }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $completed = $process.WaitForExit($TimeoutSeconds * 1000)
    if (-not $completed) {
        try { $process.Kill($true) } catch { }
        $process.WaitForExit()
        $timeoutRecord = [ordered]@{
            schema_version = 1
            record_type = 'round0912_evaluation_run'
            mode = 'campaign'
            status = 'FAIL'
            environment_status = 'PASS'
            reasons = @('runtime_timeout')
            fixture_manifest_sha256 = $manifestSha256
            provider_calls = 'not_measured'
            model_processes_started = $(if ($isFakeRuntime) { 0 } else { 1 })
            runtime_processes_started = 1
            promotion = [ordered]@{ verdict = 'REJECT'; reasons = @('reliability_failure'); eligible = $false }
        }
        Write-Round0912Record -Record $timeoutRecord -Path $resultPath
        exit 4
    }
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    if ($process.ExitCode -ne 0) {
        $failureRecord = [ordered]@{
            schema_version = 1
            record_type = 'round0912_evaluation_run'
            mode = 'campaign'
            status = 'FAIL'
            environment_status = 'PASS'
            reasons = @('runtime_failed')
            fixture_manifest_sha256 = $manifestSha256
            runtime_stdout_sha256 = Get-Round0912Sha256Text -Text $stdout
            runtime_stderr_sha256 = Get-Round0912Sha256Text -Text $stderr
            provider_calls = 'not_measured'
            model_processes_started = $(if ($isFakeRuntime) { 0 } else { 1 })
            runtime_processes_started = 1
            promotion = [ordered]@{ verdict = 'REJECT'; reasons = @('runtime_failure'); eligible = $false }
        }
        Write-Round0912Record -Record $failureRecord -Path $resultPath
        exit 4
    }
    if ([Text.Encoding]::UTF8.GetByteCount($stdout) -gt 65536) {
        throw 'Campaign runtime output exceeded the bounded result size.'
    }

    $runtimeRecord = $null
    try { $runtimeRecord = $stdout | ConvertFrom-Json -AsHashtable -ErrorAction Stop } catch { }
    if ($isFakeRuntime) {
        if (-not $runtimeRecord -or $runtimeRecord.record_type -cne 'round0912_fake_runtime_result' -or
            $runtimeRecord.status -cne 'PASS' -or $runtimeRecord.cwd_is_git -ne $true -or
            $runtimeRecord.provider_calls -ne 0 -or $runtimeRecord.model_processes_started -ne 0) {
            throw 'Fake campaign runtime returned an invalid bounded record.'
        }
    }
    $campaignRecord = [ordered]@{
        schema_version = 1
        record_type = 'round0912_evaluation_run'
        mode = 'campaign'
        status = $(if ($isFakeRuntime) { 'PASS' } else { 'CAPTURED_NOT_EVALUATED' })
        environment_status = 'PASS'
        reasons = @($(if ($isFakeRuntime) { 'synthetic_runtime_only' } else { 'campaign_result_requires_task_cycle_reconciliation' }))
        fixture_manifest_sha256 = $manifestSha256
        runtime_stdout_sha256 = Get-Round0912Sha256Text -Text $stdout
        runtime_stderr_sha256 = Get-Round0912Sha256Text -Text $stderr
        fake_runtime = $isFakeRuntime
        provider_calls = $(if ($isFakeRuntime) { 0 } elseif ($runtimeRecord -and $runtimeRecord.provider_calls -is [int]) { $runtimeRecord.provider_calls } else { 'not_measured' })
        model_processes_started = $(if ($isFakeRuntime) { 0 } else { 1 })
        runtime_processes_started = 1
        promotion = [ordered]@{
            verdict = 'DEFER_INCONCLUSIVE'
            reasons = @($(if ($isFakeRuntime) { 'synthetic_runtime_cannot_promote' } else { 'task_cycle_evidence_incomplete' }))
            eligible = $false
        }
    }
    Write-Round0912Record -Record $campaignRecord -Path $resultPath
    Write-Host "Round 09-12 campaign boundary completed: $($campaignRecord.status)."
    exit 0
} finally {
    if ($scratchRoot -and (Test-Path -LiteralPath $scratchRoot -PathType Container)) {
        $safeScratch = (Test-Round0912PathWithin -Candidate $scratchRoot -Parent $systemTempRoot) -and
            ([IO.Path]::GetFileName($scratchRoot)).StartsWith('omp-round0912-campaign-', [StringComparison]::Ordinal)
        if (-not $safeScratch) { throw 'Refusing unsafe campaign scratch cleanup.' }
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force
    }
}
