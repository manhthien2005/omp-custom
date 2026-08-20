#Requires -Version 7.4
[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
$evidenceDir = Join-Path $RepositoryRoot 'docs\evidence\current-product\topic-07'
[void](New-Item -ItemType Directory -Path $evidenceDir -Force)
$deterministicPath = Join-Path $evidenceDir 'deterministic.json'
$manifestPath = Join-Path $evidenceDir 'manifest.json'

function Get-Topic07CaptureSha256Text {
    param([AllowEmptyString()][string]$Text)
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData(
        [Text.Encoding]::UTF8.GetBytes($Text)
    )).ToLowerInvariant()
}

function Get-Topic07CaptureFileSha256 {
    param([Parameter(Mandatory)][string]$LiteralPath)
    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Write-Topic07CaptureJson {
    param([Parameter(Mandatory)][string]$LiteralPath, [Parameter(Mandatory)][object]$Value)
    $json = ($Value | ConvertTo-Json -Depth 64) + "`n"
    [IO.File]::WriteAllText($LiteralPath, $json, [Text.UTF8Encoding]::new($false))
}

function Invoke-Topic07CaptureProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [hashtable]$Environment = @{}
    )
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $FilePath
    $psi.WorkingDirectory = $RepositoryRoot
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    foreach ($argument in $Arguments) { [void]$psi.ArgumentList.Add($argument) }
    foreach ($entry in $Environment.GetEnumerator()) { $psi.Environment[$entry.Key] = [string]$entry.Value }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $psi
    if (-not $process.Start()) { throw "Could not start evidence command: $FilePath" }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        StdoutSha256 = Get-Topic07CaptureSha256Text $stdout
        StderrSha256 = Get-Topic07CaptureSha256Text $stderr
    }
}

function New-Topic07CaptureCase {
    param([Parameter(Mandatory)][object]$Run, [Parameter(Mandatory)][string]$Scope)
    return [ordered]@{
        status = if ([int]$Run.ExitCode -eq 0) { 'PASS' } else { 'FAIL' }
        exit_code = [int]$Run.ExitCode
        scope = $Scope
        stdout_sha256 = [string]$Run.StdoutSha256
        stderr_sha256 = [string]$Run.StderrSha256
        provider_calls = 0
        model_processes_started = 0
    }
}

function Get-Topic07CaptureGitOutput {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $output = @(& git @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    return [pscustomobject]@{
        ExitCode = $exitCode
        Text = (($output | ForEach-Object { [string]$_ }) -join "`n")
    }
}

try {
    # Create both evidence paths first so the dirty-path identity is stable during capture.
    if (-not (Test-Path -LiteralPath $deterministicPath -PathType Leaf)) {
        [IO.File]::WriteAllText($deterministicPath, "{}`n", [Text.UTF8Encoding]::new($false))
    }
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        [IO.File]::WriteAllText($manifestPath, "{}`n", [Text.UTF8Encoding]::new($false))
    }

    $helperPath = Join-Path $RepositoryRoot 'scripts\lib\topic07-context-continuity.ps1'
    . $helperPath
    $pwsh = [Environment]::ProcessPath
    $nodeCommand = Get-Command node -ErrorAction Stop
    $node = if ($nodeCommand.Source) { $nodeCommand.Source } else { $nodeCommand.Path }
    $cases = [ordered]@{}

    $run = Invoke-Topic07CaptureProcess $node @(
        '--test',
        'scripts/tests/topic07-managed-state-client.Tests.mjs',
        'scripts/tests/topic07-continuity-core.Tests.mjs',
        'scripts/tests/topic07-omp-adapter.Tests.mjs',
        'scripts/tests/topic07-safe-compact.Tests.mjs',
        'scripts/tests/topic07-pressure-guard.Tests.mjs'
    )
    $cases.portable_core_and_adapter = New-Topic07CaptureCase $run `
        'Model-free closed-schema, continuity-core, adapter, transaction, and pressure checks.'

    foreach ($entry in ([ordered]@{
        durable_state_contract = 'scripts/tests/topic07-state-contract.Tests.ps1'
        durable_state_projection = 'scripts/tests/topic07-state-projection.Tests.ps1'
        managed_runtime_profile = 'scripts/tests/topic07-managed-runtime.Tests.ps1'
        local_pressure_canary = 'scripts/tests/topic07-pressure-canary.Tests.ps1'
        validator_mutations = 'scripts/tests/topic07-validator-mutations.Tests.ps1'
    }).GetEnumerator()) {
        $run = Invoke-Topic07CaptureProcess $pwsh @('-NoProfile', '-File', $entry.Value)
        $cases[$entry.Key] = New-Topic07CaptureCase $run "Model-free $($entry.Key.Replace('_', ' '))."
    }

    $focused = @(Test-Topic07ContextContinuityContract -RepositoryRoot $RepositoryRoot -SkipEvidence)
    $focusedFailures = @($focused | Where-Object Status -eq FAIL)
    $focusedText = ($focused | ForEach-Object { "$($_.Status)|$($_.Code)|$($_.Message)" }) -join "`n"
    $focusedRun = [pscustomobject]@{
        ExitCode = if ($focusedFailures.Count -eq 0) { 0 } else { 1 }
        StdoutSha256 = Get-Topic07CaptureSha256Text $focusedText
        StderrSha256 = Get-Topic07CaptureSha256Text ''
    }
    $cases.focused_contract_bootstrap = New-Topic07CaptureCase $focusedRun `
        "Focused Topic 07 validation with only its not-yet-final evidence pair skipped ($($focused.Count) records)."

    $run = Invoke-Topic07CaptureProcess $pwsh @('-NoProfile', '-File', 'scripts/validate-template.ps1') `
        @{ OMP_TOPIC07_CAPTURE = '1' }
    $cases.full_validator_bootstrap = New-Topic07CaptureCase $run `
        'Full repository validator with only the Topic 07 evidence self-check skipped during capture.'

    $source = Test-Topic07SourceAttachments -RepositoryRoot $RepositoryRoot
    $matrix = Resolve-Topic07RuntimeMatrix -RepositoryRoot $RepositoryRoot
    $allPass = @($cases.Values | Where-Object status -ne PASS).Count -eq 0 -and $source.Status -ceq 'PASS'

    $repoHead = (Get-Topic07CaptureGitOutput @('-C', $RepositoryRoot, 'rev-parse', 'HEAD')).Text.Trim()
    $porcelain = (Get-Topic07CaptureGitOutput @(
        '-C', $RepositoryRoot, 'status', '--porcelain=v1', '--untracked-files=all'
    )).Text
    $porcelainLines = @($porcelain -split "`n" | Where-Object { $_ } | Sort-Object)
    $porcelainCanonical = if ($porcelainLines.Count -eq 0) { '' } else { ($porcelainLines -join "`n") + "`n" }
    $pinnedRoot = Join-Path $RepositoryRoot '_research\upstreams\oh-my-pi'
    $pinnedStatus = Get-Topic07CaptureGitOutput @('-C', $pinnedRoot, 'status', '--porcelain', '--untracked-files=no')
    $pinnedClean = $source.Status -ceq 'PASS' -and $pinnedStatus.ExitCode -eq 0 -and
        [string]::IsNullOrWhiteSpace($pinnedStatus.Text)

    $ompVersionOutput = @(& omp --version 2>&1)
    $ompVersionExit = $LASTEXITCODE
    $ompVersion = (($ompVersionOutput | ForEach-Object { [string]$_ }) -join "`n").Trim()
    if ($ompVersionExit -ne 0) { $ompVersion = 'unavailable' }
    $gitVersion = ((& git --version 2>&1) | ForEach-Object { [string]$_ }) -join ' '
    $nodeVersion = ((& $node --version 2>&1) | ForEach-Object { [string]$_ }) -join ' '

    $evidence = [ordered]@{
        schema_version = 1
        record_type = 'topic07_context_continuity_evidence'
        status = 'IMPLEMENTED_NOT_PROMOTED'
        captured_at_utc = [DateTime]::UtcNow.ToString('o')
        provider_calls = 0
        model_processes_started = 0
        source_attachment_count = @($source.Attachments).Count
        repository = [ordered]@{
            head = $repoHead
            working_tree_clean = ($porcelainLines.Count -eq 0)
            dirty_paths_sha256 = Get-Topic07CaptureSha256Text $porcelainCanonical
            dirty_paths_algorithm = 'sha256(sorted_git_porcelain_v1_lines_utf8_lf)'
        }
        environment = [ordered]@{
            os = [Runtime.InteropServices.RuntimeInformation]::OSDescription
            architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
            pwsh_version = $PSVersionTable.PSVersion.ToString()
            node_version = $nodeVersion
            git_version = $gitVersion
            installed_omp_version = $ompVersion
        }
        pinned_omp = [ordered]@{
            commit = $script:Topic07PinnedOmpSha
            clean = $pinnedClean
            source_status = [string]$source.Status
        }
        runtime_matrix = [ordered]@{
            status = [string]$matrix.Status
            code = [string]$matrix.Code
            rows = @($matrix.Rows | ForEach-Object {
                [ordered]@{ version = [string]$_.Version; available = [bool]$_.Available; source = [string]$_.Source }
            })
        }
        cases = $cases
        limitations = [ordered]@{
            # A passing two-runtime canary satisfies the canary prerequisite; promotion itself is a
            # separate owner decision, so record which of the two the environment has reached rather
            # than claiming the stronger one.
            promotion = if ($matrix.Code -ceq 'T07-RUNTIME-MATRIX-READY') {
                'RUNTIME_CANARIES_PASS_PENDING_OWNER_PROMOTION'
            } else {
                'BLOCKED_UNTIL_BOTH_SUPPORTED_RUNTIME_CANARIES_PASS'
            }
            open_blocker = [string]$matrix.Code
            provider_smoke = 'NOT_RUN_MODEL_FREE_CAMPAIGN'
            operational_state = 'LOCAL_OUTSIDE_GIT'
        }
    }
    Write-Topic07CaptureJson $deterministicPath $evidence

    $manifestFiles = @(Get-Topic07ContextContinuityGovernedFiles | Where-Object {
        $_ -cne 'docs/evidence/current-product/topic-07/manifest.json' -and
        $_ -cne 'codex-topic07-context-compaction-continuity-changelog.md'
    } | Sort-Object -Unique)
    $fileRows = foreach ($relative in $manifestFiles) {
        $path = Join-Path $RepositoryRoot ($relative -replace '/', '\')
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Evidence manifest input is missing: $relative" }
        $role = if ($relative -like 'scripts/tests/*') { 'test_or_fixture' }
            elseif ($relative -like 'template/*' -or $relative -like 'scripts/*') { 'implementation' }
            elseif ($relative -like 'docs/evidence/*') { 'evidence' }
            else { 'authority_or_guide' }
        [ordered]@{ path = $relative; role = $role; sha256 = Get-Topic07CaptureFileSha256 $path }
    }
    $manifest = [ordered]@{
        schema_version = 1
        record_type = 'topic07_current_product_manifest'
        generated_at_utc = [DateTime]::UtcNow.ToString('o')
        repository = [ordered]@{
            head = $repoHead
            working_tree_clean = ($porcelainLines.Count -eq 0)
            dirty_paths_sha256 = Get-Topic07CaptureSha256Text $porcelainCanonical
            dirty_paths_algorithm = 'sha256(sorted_git_porcelain_v1_lines_utf8_lf)'
        }
        pinned_omp = [ordered]@{ commit = $script:Topic07PinnedOmpSha; clean = $pinnedClean }
        files = @($fileRows)
        commands = @($cases.GetEnumerator() | ForEach-Object {
            [ordered]@{ id = $_.Key; exit_code = [int]$_.Value.exit_code; status = [string]$_.Value.status }
        })
    }
    Write-Topic07CaptureJson $manifestPath $manifest

    $final = @(Test-Topic07ContextContinuityContract -RepositoryRoot $RepositoryRoot)
    $finalFailures = @($final | Where-Object Status -eq FAIL)
    $deterministicHash = Get-Topic07CaptureFileSha256 $deterministicPath
    $manifestHash = Get-Topic07CaptureFileSha256 $manifestPath
    Write-Host "Topic 07 evidence: $($evidence.status); $($fileRows.Count) hashed files; $($cases.Count) command groups"
    Write-Host "deterministic.json SHA256: $deterministicHash"
    Write-Host "manifest.json SHA256: $manifestHash"
    if (-not $allPass -or $finalFailures.Count -gt 0) {
        if ($finalFailures.Count -gt 0) {
            Write-Host "Final contract failures: $(($finalFailures | ForEach-Object Code) -join ', ')"
        }
        exit 1
    }
    exit 0
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
