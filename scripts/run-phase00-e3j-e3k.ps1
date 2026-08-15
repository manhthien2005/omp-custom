#Requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet('J1','J2','J3','K1')][string]$CaseId = 'J1',
    [string]$Model = 'omniroute/codex/gpt-5.6-sol-high',
    [ValidateRange(1,999)][int]$Attempt = 1,
    [switch]$AllowOverwrite
)

Set-StrictMode -Version 2.0

$script:Phase00RunnerRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:Phase00RuntimeHelper = Join-Path $PSScriptRoot 'lib\phase00-runtime-evidence.ps1'

if (Test-Path -LiteralPath $script:Phase00RuntimeHelper -PathType Leaf) {
    . $script:Phase00RuntimeHelper
}

function Get-Phase00OmpArguments {
    param(
        [Parameter(Mandatory)][ValidateSet('J1','J2','J3','K1')][string]$CaseId,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$SessionDir,
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$Prompt
    )

    return @(
        '-p',
        '--mode', 'json',
        '--cwd', $FixtureRoot,
        '--session-dir', $SessionDir,
        '--config', (Join-Path $FixtureRoot 'config.yml'),
        '--model', $Model,
        '--tools', 'task,bash',
        '--approval-mode', 'yolo',
        '--max-time', '8m',
        '--no-extensions',
        '--no-skills',
        '--no-rules',
        '--no-lsp',
        '--no-title',
        $Prompt
    )
}

function Get-Phase00OmpEnvironment {
    param([Parameter(Mandatory)][string]$AgentDirectory)

    return @{ PI_CODING_AGENT_DIR = $AgentDirectory }
}

function Get-Phase00DirectoryMetadataSnapshot {
    param([Parameter(Mandatory)][string]$Path)

    $fullRoot = [System.IO.Path]::GetFullPath($Path).TrimEnd('\','/')
    $entries = @()
    if (Test-Path -LiteralPath $fullRoot -PathType Container) {
        $rootPrefix = $fullRoot + [System.IO.Path]::DirectorySeparatorChar
        $entries = @(Get-ChildItem -LiteralPath $fullRoot -Force -File -Recurse | ForEach-Object {
            [pscustomobject][ordered]@{
                Path = $_.FullName.Substring($rootPrefix.Length).Replace('\','/')
                Length = [long]$_.Length
                LastWriteUtcTicks = [long]$_.LastWriteTimeUtc.Ticks
            }
        } | Sort-Object Path)
    }
    $canonical = @($entries | ForEach-Object { '{0}|{1}|{2}' -f $_.Path,$_.Length,$_.LastWriteUtcTicks }) -join "`n"
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $digest = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($canonical))
    } finally {
        $sha.Dispose()
    }
    return [pscustomobject][ordered]@{
        FileCount = $entries.Count
        Sha256 = ([System.BitConverter]::ToString($digest)).Replace('-','').ToLowerInvariant()
        Entries = $entries
    }
}

function Compare-Phase00DirectoryMetadataSnapshot {
    param(
        [Parameter(Mandatory)]$Before,
        [Parameter(Mandatory)]$After
    )

    $beforeByPath = @{}
    $afterByPath = @{}
    foreach ($entry in @($Before.Entries)) { $beforeByPath[[string]$entry.Path] = $entry }
    foreach ($entry in @($After.Entries)) { $afterByPath[[string]$entry.Path] = $entry }
    $changed = @($beforeByPath.Keys + $afterByPath.Keys | Sort-Object -Unique | Where-Object {
        $path = [string]$_
        if (-not $beforeByPath.ContainsKey($path) -or -not $afterByPath.ContainsKey($path)) { return $true }
        $left = $beforeByPath[$path]
        $right = $afterByPath[$path]
        return [long]$left.Length -ne [long]$right.Length -or
            [long]$left.LastWriteUtcTicks -ne [long]$right.LastWriteUtcTicks
    })
    return [pscustomobject][ordered]@{
        BeforeFileCount = [int]$Before.FileCount
        AfterFileCount = [int]$After.FileCount
        BeforeSha256 = [string]$Before.Sha256
        AfterSha256 = [string]$After.Sha256
        ChangedCount = $changed.Count
        ChangedPaths = $changed
        BoundaryResult = if ($changed.Count -eq 0) { 'PASS_LIVE_HOME_READ_ONLY' } else { 'FAILED_LIVE_HOME_READ_ONLY' }
    }
}

function Get-Phase00CaseDefinition {
    param([Parameter(Mandatory)][ValidateSet('J1','J2','J3','K1')][string]$CaseId)

    switch ($CaseId) {
        'J1' { return [pscustomobject]@{ Experiment = 'E3-J'; Prompt = 'J1-blocking-batch.md' } }
        'J2' { return [pscustomobject]@{ Experiment = 'E3-J'; Prompt = 'J2-missing-blocking-control.md' } }
        'J3' { return [pscustomobject]@{ Experiment = 'E3-J'; Prompt = 'J3-stage-barriers.md' } }
        'K1' { return [pscustomobject]@{ Experiment = 'E3-K'; Prompt = 'K1-flat-wire-fallback.md' } }
    }
}

function Assert-Phase00DisposableRoot {
    param([Parameter(Mandatory)][string]$Path)

    $temp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\','/') + [System.IO.Path]::DirectorySeparatorChar
    $resolved = [System.IO.Path]::GetFullPath($Path).TrimEnd('\','/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($temp, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Disposable root is outside the system temporary directory: $resolved"
    }
    if ([System.IO.Path]::GetPathRoot($resolved) -eq $resolved) {
        throw "Refusing a filesystem root as disposable path: $resolved"
    }
    return $resolved.TrimEnd('\','/')
}

function Remove-Phase00DisposableDirectory {
    param([Parameter(Mandatory)][string]$Path)

    $verified = Assert-Phase00DisposableRoot $Path
    for ($attempt = 1; $attempt -le 10; $attempt++) {
        if (-not (Test-Path -LiteralPath $verified)) { return }
        try {
            Remove-Item -LiteralPath $verified -Recurse -Force -ErrorAction Stop
            return
        } catch {
            if ($attempt -eq 10) { throw }
            Start-Sleep -Milliseconds (100 * $attempt)
        }
    }
}

function Initialize-Phase00DisposableRepository {
    param([Parameter(Mandatory)][string]$FixtureRoot)

    $commands = @(
        @('init','--quiet'),
        @('config','user.name','Phase 00 Runtime Probe'),
        @('config','user.email','phase00-probe.invalid@example.invalid'),
        @('config','core.autocrlf','false'),
        @('add','--all'),
        @('-c','commit.gpgSign=false','-c','core.hooksPath=NUL','commit','--quiet','-m','phase00 disposable fixture baseline')
    )
    foreach ($arguments in $commands) {
        $output = & git -C $FixtureRoot @arguments 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Disposable Git initialization failed: $($output -join ' ')"
        }
    }
    $status = @(& git -C $FixtureRoot status --porcelain 2>&1)
    if ($LASTEXITCODE -ne 0 -or $status.Count -ne 0) {
        throw "Disposable Git fixture is not clean: $($status -join ' ')"
    }
    return (& git -C $FixtureRoot rev-parse HEAD).Trim()
}

function Invoke-Phase00OmpProcess {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][hashtable]$Environment,
        [Parameter(Mandatory)][string]$StderrPath
    )

    $started = [DateTimeOffset]::Now
    $previous = @{}
    try {
        foreach ($key in $Environment.Keys) {
            $previous[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
            [Environment]::SetEnvironmentVariable($key, [string]$Environment[$key], 'Process')
        }
        $stdout = @(& omp @Arguments 2> $StderrPath)
        $exitCode = $LASTEXITCODE
    } finally {
        foreach ($key in $Environment.Keys) {
            [Environment]::SetEnvironmentVariable($key, $previous[$key], 'Process')
        }
    }
    $completed = [DateTimeOffset]::Now
    $stderr = if (Test-Path -LiteralPath $StderrPath -PathType Leaf) {
        Get-Content -Raw -LiteralPath $StderrPath -Encoding UTF8
    } else { '' }
    return [pscustomobject][ordered]@{
        ExitCode = $exitCode
        StartedAt = $started
        CompletedAt = $completed
        Stdout = ($stdout -join "`n")
        Stderr = $stderr
    }
}

function Get-Phase00RuntimeAnalysis {
    param(
        [Parameter(Mandatory)][ValidateSet('J1','J2','J3','K1')][string]$CaseId,
        [Parameter(Mandatory)][object[]]$Events
    )

    switch ($CaseId) {
        'J1' { return Test-Phase00J1Evidence -Events $Events }
        'J2' { return Test-Phase00J2Evidence -Events $Events }
        'J3' { return Test-Phase00J3Evidence -Events $Events }
        'K1' { return Test-Phase00K1Evidence -Events $Events }
    }
}

function Write-Phase00Utf8NoBom {
    param([Parameter(Mandatory)][string]$Path, [AllowEmptyString()][Parameter(Mandatory)][string]$Text)

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-Phase00RuntimeCase {
    param(
        [Parameter(Mandatory)][ValidateSet('J1','J2','J3','K1')][string]$CaseId,
        [Parameter(Mandatory)][string]$Model,
        [ValidateRange(1,999)][int]$Attempt = 1,
        [switch]$AllowOverwrite
    )

    if (-not (Test-Path -LiteralPath $script:Phase00RuntimeHelper -PathType Leaf)) {
        throw "Runtime evidence helper is missing: $script:Phase00RuntimeHelper"
    }
    $definition = Get-Phase00CaseDefinition -CaseId $CaseId
    $sourceFixture = Join-Path $script:Phase00RunnerRoot "docs\evidence\phase-00\$($definition.Experiment)\fixture"
    $promptPath = Join-Path $sourceFixture "prompts\$($definition.Prompt)"
    $modelCatalogPath = Join-Path $script:Phase00RunnerRoot 'docs\evidence\phase-00\environment\runtime-models.yml'
    if (-not (Test-Path -LiteralPath $promptPath -PathType Leaf)) { throw "Prompt fixture missing: $promptPath" }
    if (-not (Test-Path -LiteralPath $modelCatalogPath -PathType Leaf)) { throw "Runtime model catalog missing: $modelCatalogPath" }
    $modelCatalog = Get-Content -Raw -LiteralPath $modelCatalogPath -Encoding UTF8
    $catalogSafe = $modelCatalog -match '(?m)^\s*baseUrl:\s+http://127\.0\.0\.1:20128/v1\s*$' -and
        $modelCatalog -match '(?m)^\s*apiKey:\s+OMNIROUTE_API_KEY\s*$' -and
        $modelCatalog -match '(?m)^\s*- id:\s+codex/gpt-5\.6-sol-high\s*$' -and
        $modelCatalog -notmatch '(?i)(sk-[A-Za-z0-9]|Bearer\s+[A-Za-z0-9])'
    if (-not $catalogSafe) { throw 'Runtime model catalog failed the non-secret contract.' }

    $fixtureChecks = @(Test-Phase00RuntimeFixtureContract -RepositoryRoot $script:Phase00RunnerRoot)
    $failedFixtureChecks = @($fixtureChecks | Where-Object { -not $_.Passed })
    if ($failedFixtureChecks.Count -gt 0) {
        throw "Runtime fixture contract failed: $($failedFixtureChecks.Code -join ', ')"
    }

    $versionOutput = @(& omp --version 2>&1)
    if ($LASTEXITCODE -ne 0 -or ($versionOutput -join "`n") -notmatch '17\.2\.10') {
        throw "Installed OMP is not the required 17.2.10: $($versionOutput -join ' ')"
    }

    $rawRoot = Join-Path $script:Phase00RunnerRoot "docs\evidence\phase-00\$($definition.Experiment)\raw"
    $evidenceStem = if ($Attempt -eq 1) { $CaseId } else { "$CaseId-attempt-{0:D3}" -f $Attempt }
    $stdoutPath = Join-Path $rawRoot "$evidenceStem.stdout.jsonl"
    $stderrPath = Join-Path $rawRoot "$evidenceStem.stderr.txt"
    $runPath = Join-Path $rawRoot "$evidenceStem.run.json"
    $existingEvidence = @(@($stdoutPath,$stderrPath,$runPath) | Where-Object { Test-Path -LiteralPath $_ })
    if (-not $AllowOverwrite -and $existingEvidence.Count -gt 0) {
        throw "Evidence already exists for $CaseId. Use -AllowOverwrite only after preserving the prior attempt."
    }

    $disposable = Assert-Phase00DisposableRoot (Join-Path ([System.IO.Path]::GetTempPath()) ("omp-phase00-$($CaseId.ToLowerInvariant())-{0}" -f [guid]::NewGuid().ToString('N')))
    $sessionDir = Assert-Phase00DisposableRoot ("$disposable-sessions")
    $agentDirectory = Assert-Phase00DisposableRoot ("$disposable-agent-home")
    $tempStderr = Join-Path ([System.IO.Path]::GetTempPath()) ("omp-phase00-$($CaseId.ToLowerInvariant())-{0}.stderr" -f [guid]::NewGuid().ToString('N'))
    $cleanupSucceeded = $false
    $processResult = $null
    $fixtureHead = $null
    $arguments = $null
    $liveAgentDirectory = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.omp\agent'
    $liveHomeBefore = Get-Phase00DirectoryMetadataSnapshot -Path $liveAgentDirectory
    $liveHomeAfter = $null
    $cleanupFailures = [System.Collections.Generic.List[string]]::new()
    try {
        New-Item -ItemType Directory -Path $disposable -Force | Out-Null
        Get-ChildItem -Force -LiteralPath $sourceFixture | Copy-Item -Destination $disposable -Recurse -Force
        New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
        New-Item -ItemType Directory -Path $agentDirectory -Force | Out-Null
        Copy-Item -LiteralPath $modelCatalogPath -Destination (Join-Path $agentDirectory 'models.yml')
        $fixtureHead = Initialize-Phase00DisposableRepository -FixtureRoot $disposable
        $prompt = Get-Content -Raw -LiteralPath $promptPath -Encoding UTF8
        $arguments = @(Get-Phase00OmpArguments -CaseId $CaseId -FixtureRoot $disposable -SessionDir $sessionDir -Model $Model -Prompt $prompt)
        $ompEnvironment = Get-Phase00OmpEnvironment -AgentDirectory $agentDirectory
        $processResult = Invoke-Phase00OmpProcess -Arguments $arguments -Environment $ompEnvironment -StderrPath $tempStderr
    } finally {
        $liveHomeAfter = Get-Phase00DirectoryMetadataSnapshot -Path $liveAgentDirectory
        if ((Test-Path -LiteralPath $tempStderr -PathType Leaf) -and $null -eq $processResult) {
            Remove-Item -LiteralPath $tempStderr -Force -ErrorAction SilentlyContinue
        }
        foreach ($cleanupPath in @($disposable,$sessionDir,$agentDirectory)) {
            try {
                Remove-Phase00DisposableDirectory -Path $cleanupPath
            } catch {
                [void]$cleanupFailures.Add("$cleanupPath`: $($_.Exception.Message)")
            }
        }
        $cleanupSucceeded = $cleanupFailures.Count -eq 0 -and
            -not (Test-Path -LiteralPath $disposable) -and
            -not (Test-Path -LiteralPath $sessionDir) -and
            -not (Test-Path -LiteralPath $agentDirectory)
    }

    if ($null -eq $processResult) { throw "OMP process did not produce a result for $CaseId." }
    try {
        $safeStdout = Protect-Phase00EvidenceText -Text $processResult.Stdout -RepositoryRoot $script:Phase00RunnerRoot -DisposableRoot $disposable
        $safeStderr = Protect-Phase00EvidenceText -Text $processResult.Stderr -RepositoryRoot $script:Phase00RunnerRoot -DisposableRoot $disposable
    } finally {
        if (Test-Path -LiteralPath $tempStderr -PathType Leaf) {
            Remove-Item -LiteralPath $tempStderr -Force
        }
    }

    Write-Phase00Utf8NoBom -Path $stdoutPath -Text $safeStdout
    Write-Phase00Utf8NoBom -Path $stderrPath -Text $safeStderr

    $analysis = $null
    if ($processResult.ExitCode -eq 0) {
        try {
            $events = @(Read-Phase00JsonLines -Path $stdoutPath)
            $terminalFailure = Get-Phase00TerminalModelFailure -Events $events
            if ($terminalFailure.Found) {
                $terminalStatus = if ($terminalFailure.IsEnvironmentBlock) { 'BLOCKED_ENVIRONMENT' } else { 'INVALID_RUN' }
                $analysis = New-Phase00RuntimeAnalysis $terminalStatus @($terminalFailure.Code) @{
                    Provider = $terminalFailure.Provider
                    Model = $terminalFailure.Model
                    ErrorMessage = $terminalFailure.ErrorMessage
                }
            } else {
                $analysis = Get-Phase00RuntimeAnalysis -CaseId $CaseId -Events $events
            }
        } catch {
            $analysis = New-Phase00RuntimeAnalysis INVALID_RUN @("RUNTIME_PARSE: $($_.Exception.Message)")
        }
    } else {
        $environmentPattern = '(?i)(quota|rate.?limit|authentication|unauthorized|forbidden|provider|model.+not.+found|credential)'
        $status = if ($safeStderr -match $environmentPattern) { 'BLOCKED_ENVIRONMENT' } else { 'INVALID_RUN' }
        $analysis = New-Phase00RuntimeAnalysis $status @("OMP_EXIT_$($processResult.ExitCode)")
    }
    $liveHomeComparison = Compare-Phase00DirectoryMetadataSnapshot -Before $liveHomeBefore -After $liveHomeAfter
    if ($liveHomeComparison.ChangedCount -ne 0) {
        $analysis = New-Phase00RuntimeAnalysis INVALID_RUN @('P00-RUNTIME-LIVE-HOME-WRITE')
    }

    $commandRecord = @(
        'omp', '-p', '--mode', 'json', '--cwd', '<DISPOSABLE_ROOT>', '--session-dir',
        '<DISPOSABLE_SESSION_DIR>', '--config', '<DISPOSABLE_ROOT>/config.yml', '--model',
        $Model, '--tools', 'task,bash', '--approval-mode', 'yolo', '--max-time', '8m',
        '--no-extensions', '--no-skills', '--no-rules', '--no-lsp', '--no-title',
        "<PROMPT:$($definition.Prompt)>"
    )
    $runRecord = [ordered]@{
        schema_version = 1
        case = $CaseId
        attempt = $Attempt
        experiment = $definition.Experiment
        omp_version = ($versionOutput -join ' ').Trim()
        model = $Model
        process_environment = @{ PI_CODING_AGENT_DIR = '<DISPOSABLE_AGENT_DIR>' }
        model_catalog_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $modelCatalogPath).Hash
        fixture_commit = $fixtureHead
        command = $commandRecord
        exit_code = $processResult.ExitCode
        started_at = $processResult.StartedAt.ToString('o')
        completed_at = $processResult.CompletedAt.ToString('o')
        duration_ms = [long]($processResult.CompletedAt - $processResult.StartedAt).TotalMilliseconds
        cleanup_succeeded = $cleanupSucceeded
        cleanup_failure_count = $cleanupFailures.Count
        live_home_metadata = [ordered]@{
            before_file_count = $liveHomeComparison.BeforeFileCount
            after_file_count = $liveHomeComparison.AfterFileCount
            before_sha256 = $liveHomeComparison.BeforeSha256
            after_sha256 = $liveHomeComparison.AfterSha256
            changed_count = $liveHomeComparison.ChangedCount
            changed_paths = @($liveHomeComparison.ChangedPaths)
            boundary_result = $liveHomeComparison.BoundaryResult
        }
        analysis = $analysis
    } | ConvertTo-Json -Depth 12
    Write-Phase00Utf8NoBom -Path $runPath -Text $runRecord

    return [pscustomobject][ordered]@{
        CaseId = $CaseId
        Attempt = $Attempt
        Experiment = $definition.Experiment
        ExitCode = $processResult.ExitCode
        Analysis = $analysis
        StdoutPath = $stdoutPath
        StderrPath = $stderrPath
        RunPath = $runPath
        CleanupSucceeded = $cleanupSucceeded
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase00RuntimeCase -CaseId $CaseId -Model $Model -Attempt $Attempt -AllowOverwrite:$AllowOverwrite
}
