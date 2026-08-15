#Requires -Version 7.4
[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) { $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$evidenceDirectory = [IO.Path]::GetFullPath((Join-Path $root 'docs\evidence\current-product\round-09-12'))
if (-not $evidenceDirectory.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -or
    -not $evidenceDirectory.EndsWith('docs\evidence\current-product\round-09-12', [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing unsafe Round 09-12 evidence target: $evidenceDirectory"
}

$helperPath = Join-Path $root 'scripts\lib\round09-12-release-readiness.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    throw 'Round 09-12 evidence capture requires the focused validator helper.'
}
. $helperPath

function ConvertTo-Round0912EvidenceJson {
    param([Parameter(Mandatory)][object]$Value)
    return (($Value | ConvertTo-Json -Depth 64) -replace "`r`n", "`n") + "`n"
}

function Get-Round0912EvidenceSha256Bytes {
    param([Parameter(Mandatory)][AllowEmptyCollection()][byte[]]$Bytes)
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()
}

function Get-Round0912EvidenceSha256Text {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    return Get-Round0912EvidenceSha256Bytes -Bytes ([Text.Encoding]::UTF8.GetBytes($Text))
}

function Get-Round0912EvidenceCommandLine {
    param(
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)][string[]]$Arguments
    )
    $rendered = @($Arguments | ForEach-Object {
        if ($_ -match '[\s"]') { '"' + ([string]$_).Replace('"', '\"') + '"' } else { [string]$_ }
    })
    return $Executable + $(if ($rendered.Count -gt 0) { ' ' + ($rendered -join ' ') } else { '' })
}

function Invoke-Round0912EvidenceCommand {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)][string[]]$Arguments,
        [ValidateRange(1, 900)][int]$TimeoutSeconds = 300,
        [Collections.IDictionary]$Environment,
        [string]$RecordedCommand
    )

    $commands = @(Get-Command $Executable -CommandType Application -ErrorAction Stop)
    if ($commands.Count -lt 1) { throw "Evidence executable is unavailable: $Executable" }
    $command = $commands[0]
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = [string]$command.Source
    $startInfo.WorkingDirectory = $root
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    foreach ($argument in $Arguments) { [void]$startInfo.ArgumentList.Add($argument) }
    if ($null -ne $Environment) {
        foreach ($entry in $Environment.GetEnumerator()) {
            $startInfo.Environment[[string]$entry.Key] = [string]$entry.Value
        }
    }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) { throw "Could not start evidence command: $Name" }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            try { $process.Kill($true) } catch { }
            $process.WaitForExit()
            throw "Evidence command timed out without settlement: $Name"
        }
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        return [pscustomobject]@{
            Name = $Name
            Command = $(if ($RecordedCommand) {
                $RecordedCommand
            } else {
                Get-Round0912EvidenceCommandLine -Executable $Executable -Arguments $Arguments
            })
            ExitCode = [int]$process.ExitCode
            Status = $(if ($process.ExitCode -eq 0) { 'PASS' } else { 'FAIL' })
            StdoutSha256 = Get-Round0912EvidenceSha256Text -Text $stdout
            StderrSha256 = Get-Round0912EvidenceSha256Text -Text $stderr
            Stdout = $stdout
            Stderr = $stderr
        }
    } finally {
        $process.Dispose()
    }
}

function ConvertTo-Round0912CommandReceipt {
    param([Parameter(Mandatory)][object]$Check)
    return [ordered]@{
        name = [string]$Check.Name
        command = [string]$Check.Command
        exit_code = [int]$Check.ExitCode
        status = [string]$Check.Status
        stdout_sha256 = [string]$Check.StdoutSha256
        stderr_sha256 = [string]$Check.StderrSha256
    }
}

function Select-Round0912CommandReceipts {
    param(
        [Parameter(Mandatory)][object[]]$Checks,
        [Parameter(Mandatory)][string[]]$Names
    )
    return @($Checks | Where-Object { [string]$_.Name -cin $Names } |
        ForEach-Object { ConvertTo-Round0912CommandReceipt -Check $_ })
}

$runnerOutputRoot = Join-Path ([IO.Path]::GetTempPath()) ('omp-round0912-evidence-run-' + [guid]::NewGuid().ToString('N'))
$runnerOutputRoot = [IO.Path]::GetFullPath($runnerOutputRoot)
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
if (-not $runnerOutputRoot.StartsWith($tempRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
    -not ([IO.Path]::GetFileName($runnerOutputRoot)).StartsWith('omp-round0912-evidence-run-', [StringComparison]::Ordinal)) {
    throw "Refusing unsafe deterministic evidence output: $runnerOutputRoot"
}
[void](New-Item -ItemType Directory -Path $runnerOutputRoot)

$checks = [Collections.Generic.List[object]]::new()
try {
    [void]$checks.Add((Invoke-Round0912EvidenceCommand -Name 'round0912-core-tests' -Executable 'node' -Arguments @(
        '--test', '--test-reporter=dot', 'scripts/tests/round09-12-evaluation-core.Tests.mjs'
    )))
    [void]$checks.Add((Invoke-Round0912EvidenceCommand -Name 'round0912-review-security-tests' -Executable 'node' -Arguments @(
        '--test', '--test-reporter=dot', 'scripts/tests/round09-12-review-security.Tests.mjs'
    )))
    [void]$checks.Add((Invoke-Round0912EvidenceCommand -Name 'round0912-installer-proof' -Executable 'pwsh' -Arguments @(
        '-NoLogo', '-NoProfile', '-File', 'scripts/tests/round09-12-installer.Tests.ps1'
    )))
    [void]$checks.Add((Invoke-Round0912EvidenceCommand -Name 'round0912-validator-mutations' -Executable 'pwsh' -Arguments @(
        '-NoLogo', '-NoProfile', '-File', 'scripts/tests/round09-12-validator-mutations.Tests.ps1'
    ) -TimeoutSeconds 600))
    [void]$checks.Add((Invoke-Round0912EvidenceCommand -Name 'round0912-deterministic-runner' -Executable 'pwsh' -Arguments @(
        '-NoLogo', '-NoProfile', '-File', 'scripts/run-round09-12-evaluation.ps1',
        '-Mode', 'Deterministic', '-OutputDirectory', $runnerOutputRoot
    ) -RecordedCommand 'pwsh -NoLogo -NoProfile -File scripts/run-round09-12-evaluation.ps1 -Mode Deterministic -OutputDirectory <system-temp>/omp-round0912-evidence-run-*'))
    [void]$checks.Add((Invoke-Round0912EvidenceCommand -Name 'round0912-focused-no-evidence' -Executable 'pwsh' -Arguments @(
        '-NoLogo', '-NoProfile', '-File', 'scripts/validate-round09-12-release-readiness.ps1',
        '-RepositoryRoot', '.', '-SkipEvidence'
    )))

    $topicValidators = [ordered]@{
        'topic03-focused' = 'scripts/validate-topic03-topology-routing.ps1'
        'topic04-focused' = 'scripts/validate-topic04-durable-state.ps1'
        'topic05-focused' = 'scripts/validate-topic05-progressive-retrieval.ps1'
        'topic06-focused' = 'scripts/validate-topic06-agent-boundary.ps1'
        'topic07-focused' = 'scripts/validate-topic07-context-continuity.ps1'
        'topic08-focused' = 'scripts/validate-topic08-behavior-core.ps1'
    }
    foreach ($entry in $topicValidators.GetEnumerator()) {
        [void]$checks.Add((Invoke-Round0912EvidenceCommand -Name ([string]$entry.Key) -Executable 'pwsh' -Arguments @(
            '-NoLogo', '-NoProfile', '-File', [string]$entry.Value, '-RepositoryRoot', '.'
        )))
    }

    $failed = @($checks | Where-Object ExitCode -ne 0)
    if ($failed.Count -gt 0) {
        foreach ($failure in $failed) {
            [Console]::Error.WriteLine(
                "FAIL [$($failure.Name)] exit=$($failure.ExitCode) stdout_sha256=$($failure.StdoutSha256) stderr_sha256=$($failure.StderrSha256)"
            )
        }
        throw 'Round 09-12 evidence capture refused to write because a prerequisite check failed.'
    }

    $installerCheck = @($checks | Where-Object Name -ceq 'round0912-installer-proof')[0]
    if ($installerCheck.Stdout -notmatch 'PASS: Round 09-12 scratch package proof \(30 assertions\)\.') {
        throw 'Scratch installer proof did not report the exact 30-assertion contract.'
    }

    $deterministicPath = Join-Path $runnerOutputRoot 'round09-12-evaluation.json'
    if (-not (Test-Path -LiteralPath $deterministicPath -PathType Leaf)) {
        throw 'Deterministic evaluation record is missing.'
    }
    $deterministic = Get-Content -Raw -LiteralPath $deterministicPath -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    if ([string]$deterministic.record_type -cne 'round0912_evaluation_run' -or
        [string]$deterministic.mode -cne 'deterministic' -or [string]$deterministic.status -cne 'PASS' -or
        [string]$deterministic.environment_status -cne 'PASS' -or
        [int]$deterministic.provider_calls -ne 0 -or [int]$deterministic.model_processes_started -ne 0 -or
        @($deterministic.cases).Count -ne 14 -or @($deterministic.cases | Where-Object status -cne 'PASS').Count -ne 0) {
        throw 'Deterministic evaluation record cannot support current-product evidence.'
    }

    $generatedAt = [DateTime]::UtcNow.ToString('o')
    $priorManifestPath = Join-Path $evidenceDirectory 'manifest.json'
    if (Test-Path -LiteralPath $priorManifestPath -PathType Leaf) {
        try {
            $priorRaw = Get-Content -Raw -LiteralPath $priorManifestPath -Encoding UTF8
            $typeMatch = [regex]::Match($priorRaw, '"record_type"\s*:\s*"round0912_current_product_manifest"')
            $timeMatch = [regex]::Match($priorRaw, '"generated_at_utc"\s*:\s*"([^"]+)"')
            if ($typeMatch.Success -and $timeMatch.Success) {
                $priorGeneratedAt = $timeMatch.Groups[1].Value
                if ($priorGeneratedAt -cmatch '^\d{4}-\d{2}-\d{2}T.*Z$') {
                    $generatedAt = $priorGeneratedAt
                } else {
                    $legacyTime = [DateTime]::ParseExact(
                        $priorGeneratedAt,
                        'MM/dd/yyyy HH:mm:ss',
                        [Globalization.CultureInfo]::InvariantCulture,
                        [Globalization.DateTimeStyles]::None
                    )
                    $generatedAt = [DateTime]::SpecifyKind($legacyTime, [DateTimeKind]::Utc).ToString('o')
                }
            }
        } catch { }
    }
    $allChecks = @($checks)
    $quality = [ordered]@{
        schema_version = 1
        record_type = 'round0912_quality_evidence'
        generated_at_utc = $generatedAt
        status = 'PASS'
        provider_calls = 0
        model_processes_started = 0
        scope = 'deterministic_current_product'
        case_ids = @('Q-VALID-REVIEW', 'Q-MISSING-INDEPENDENT-REVIEW', 'Q-STALE-CANDIDATE', 'Q-FALSE-COMPLETION')
        commands = Select-Round0912CommandReceipts -Checks $allChecks -Names @(
            'round0912-core-tests', 'round0912-review-security-tests', 'topic04-focused'
        )
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
        commands = Select-Round0912CommandReceipts -Checks $allChecks -Names @(
            'round0912-review-security-tests', 'round0912-validator-mutations', 'topic05-focused'
        )
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
        commands = Select-Round0912CommandReceipts -Checks $allChecks -Names @(
            'round0912-core-tests', 'round0912-review-security-tests',
            'round0912-deterministic-runner', 'round0912-focused-no-evidence'
        )
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
        campaign = [ordered]@{
            environment_status = 'NOT_RUN'
            promotion_verdict = 'DEFER_INCONCLUSIVE'
        }
        limitations = @(
            'OMP_17_2_10_NOT_AVAILABLE',
            'CLAUDE_RUNTIME_NOT_VERIFIED',
            'MODEL_ASSISTED_ARMS_NOT_RUN',
            'SCRATCH_PROOF_NOT_LIVE_INSTALL'
        )
        commands = Select-Round0912CommandReceipts -Checks $allChecks -Names @(
            'round0912-installer-proof', 'round0912-validator-mutations',
            'round0912-focused-no-evidence', 'topic03-focused', 'topic04-focused',
            'topic05-focused', 'topic06-focused', 'topic07-focused', 'topic08-focused'
        )
    }

    $recordValues = [ordered]@{
        'quality.json' = $quality
        'security.json' = $security
        'evaluation.json' = $evaluation
        'release-readiness.json' = $release
    }
    $recordTypes = [ordered]@{
        'quality.json' = 'round0912_quality_evidence'
        'security.json' = 'round0912_security_evidence'
        'evaluation.json' = 'round0912_evaluation_evidence'
        'release-readiness.json' = 'round0912_release_readiness'
    }
    $bytesByName = [ordered]@{}
    foreach ($entry in $recordValues.GetEnumerator()) {
        $bytesByName[[string]$entry.Key] = [Text.UTF8Encoding]::new($false).GetBytes(
            (ConvertTo-Round0912EvidenceJson -Value $entry.Value)
        )
    }

    $governedRows = [Collections.Generic.List[object]]::new()
    $governedPaths = @(Get-Round0912GovernedFiles | Where-Object {
        -not ([string]$_).StartsWith('docs/evidence/current-product/round-09-12/', [StringComparison]::Ordinal)
    } | Sort-Object)
    foreach ($relative in $governedPaths) {
        $path = Join-Path $root (([string]$relative) -replace '/', '\')
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Governed Round 09-12 file is unavailable: $relative"
        }
        [void]$governedRows.Add([ordered]@{
            path = [string]$relative
            sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
        })
    }

    $fileRows = [Collections.Generic.List[object]]::new()
    foreach ($name in $recordValues.Keys) {
        [void]$fileRows.Add([ordered]@{
            path = [string]$name
            sha256 = Get-Round0912EvidenceSha256Bytes -Bytes ([byte[]]$bytesByName[[string]$name])
            record_type = [string]$recordTypes[[string]$name]
        })
    }
    $manifest = [ordered]@{
        schema_version = 1
        record_type = 'round0912_current_product_manifest'
        generated_at_utc = $generatedAt
        status = 'PASS'
        provider_calls = 0
        model_processes_started = 0
        files = @($fileRows)
        governed_files = @($governedRows)
    }
    $bytesByName['manifest.json'] = [Text.UTF8Encoding]::new($false).GetBytes(
        (ConvertTo-Round0912EvidenceJson -Value $manifest)
    )

    [void](New-Item -ItemType Directory -Path $evidenceDirectory -Force)
    $transaction = Join-Path $evidenceDirectory ('.round0912-capture-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $transaction)
    $names = @('quality.json', 'security.json', 'evaluation.json', 'release-readiness.json', 'manifest.json')
    $previous = @{}
    try {
        foreach ($name in $names) {
            $target = Join-Path $evidenceDirectory $name
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                $previous[$name] = [IO.File]::ReadAllBytes($target)
            }
            $stagedPath = Join-Path $transaction $name
            [IO.File]::WriteAllBytes($stagedPath, [byte[]]$bytesByName[$name])
            $stagedHash = (Get-FileHash -LiteralPath $stagedPath -Algorithm SHA256).Hash.ToLowerInvariant()
            $expectedHash = Get-Round0912EvidenceSha256Bytes -Bytes ([byte[]]$bytesByName[$name])
            if ($stagedHash -cne $expectedHash) { throw "Staged evidence hash mismatch: $name" }
            [void](Get-Content -Raw -LiteralPath $stagedPath -Encoding UTF8 | ConvertFrom-Json -AsHashtable)
        }
        foreach ($name in $names) {
            [IO.File]::Move((Join-Path $transaction $name), (Join-Path $evidenceDirectory $name), $true)
        }
        if (-not (Test-Round0912EvidenceBundle -Root $root)) {
            throw 'Settled Round 09-12 evidence failed its closed manifest contract.'
        }
    } catch {
        foreach ($name in $names) {
            $target = Join-Path $evidenceDirectory $name
            if ($previous.ContainsKey($name)) {
                [IO.File]::WriteAllBytes($target, [byte[]]$previous[$name])
            } elseif (Test-Path -LiteralPath $target -PathType Leaf) {
                Remove-Item -LiteralPath $target -Force
            }
        }
        throw
    } finally {
        $resolvedTransaction = [IO.Path]::GetFullPath($transaction)
        $safeTransaction = $resolvedTransaction.StartsWith(
            $evidenceDirectory + [IO.Path]::DirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase
        ) -and ([IO.Path]::GetFileName($resolvedTransaction)).StartsWith(
            '.round0912-capture-', [StringComparison]::Ordinal
        )
        if (-not $safeTransaction) { throw "Refusing unsafe evidence transaction cleanup: $resolvedTransaction" }
        if (Test-Path -LiteralPath $resolvedTransaction -PathType Container) {
            Remove-Item -LiteralPath $resolvedTransaction -Recurse -Force
        }
    }

    Write-Host "PASS: Round 09-12 evidence captured ($($checks.Count) checks, 0 provider calls, 0 model processes)." -ForegroundColor Green
} finally {
    if (Test-Path -LiteralPath $runnerOutputRoot -PathType Container) {
        $safeRunner = $runnerOutputRoot.StartsWith(
            $tempRoot + [IO.Path]::DirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase
        ) -and ([IO.Path]::GetFileName($runnerOutputRoot)).StartsWith(
            'omp-round0912-evidence-run-', [StringComparison]::Ordinal
        )
        if (-not $safeRunner) { throw "Refusing unsafe runner-output cleanup: $runnerOutputRoot" }
        Remove-Item -LiteralPath $runnerOutputRoot -Recurse -Force
    }
}
