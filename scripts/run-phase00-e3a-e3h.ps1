#Requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet('A1','A2','A3','A4','H2','H3','H5')][string]$CaseId = 'A1',
    [string]$Model = 'omniroute/codex/gpt-5.6-sol-high',
    [ValidateRange(1,999)][int]$Attempt = 1,
    [string]$OmpExecutable,
    [switch]$AllowOverwrite
)

Set-StrictMode -Version 2.0

$script:Phase00ConfigRunnerRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:Phase00ConfigRuntimeSha256 = `
    '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
$script:Phase00ConfigHelperPath = Join-Path $PSScriptRoot 'lib\phase00-config-evidence.ps1'
$script:Phase00RuntimeHelperPath = Join-Path $PSScriptRoot 'lib\phase00-runtime-evidence.ps1'

if (Test-Path -LiteralPath $script:Phase00RuntimeHelperPath -PathType Leaf) {
    . $script:Phase00RuntimeHelperPath
}
if (Test-Path -LiteralPath $script:Phase00ConfigHelperPath -PathType Leaf) {
    . $script:Phase00ConfigHelperPath
}

function Get-Phase00ConfigCaseDefinition {
    param([Parameter(Mandatory)][ValidateSet('A1','A2','A3','A4','H2','H3','H5')][string]$CaseId)

    switch ($CaseId) {
        'A1' { return [pscustomobject]@{ Experiment = 'E3-A'; Provider = $false; Context = 'ProjectRoot'; Prompt = $null } }
        'A2' { return [pscustomobject]@{ Experiment = 'E3-A'; Provider = $false; Context = 'DirectRead'; Prompt = $null } }
        'A3' { return [pscustomobject]@{ Experiment = 'E3-A'; Provider = $false; Context = 'NestedCwd'; Prompt = $null } }
        'A4' { return [pscustomobject]@{ Experiment = 'E3-A'; Provider = $true; Context = 'ProjectRoot'; Prompt = 'A4-apply-non-authority.md' } }
        'H2' { return [pscustomobject]@{ Experiment = 'E3-H'; Provider = $false; Context = 'NoProject'; Prompt = $null } }
        'H3' { return [pscustomobject]@{ Experiment = 'E3-H'; Provider = $false; Context = 'CliOverlay'; Prompt = $null } }
        'H5' { return [pscustomobject]@{ Experiment = 'E3-H'; Provider = $true; Context = 'ToolUnavailable'; Prompt = 'H5-config-command-unavailable.md' } }
    }
}

function Get-Phase00InstalledOmpPath {
    $command = Get-Command 'omp.exe' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        $command = Get-Command 'omp' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if ($null -eq $command -or -not (Test-Path -LiteralPath $command.Source -PathType Leaf)) {
        throw 'Installed OMP executable was not found.'
    }
    return [System.IO.Path]::GetFullPath($command.Source)
}

function Get-Phase00ConfigOmpVersion {
    param([Parameter(Mandatory)][string]$OmpExecutable)

    $process = [System.Diagnostics.Process]::new()
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = [System.IO.Path]::GetFullPath($OmpExecutable)
    $startInfo.WorkingDirectory = $script:Phase00ConfigRunnerRoot
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    if ($null -ne $startInfo.PSObject.Properties['ArgumentList']) {
        [void]$startInfo.ArgumentList.Add('--version')
    } else {
        $startInfo.Arguments = '--version'
    }
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) { throw 'OMP version probe did not start.' }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(30000)) {
            try { $process.Kill() } catch {}
            throw 'OMP version probe timed out.'
        }
        $process.WaitForExit()
        $stdout = $stdoutTask.GetAwaiter().GetResult().Trim()
        $stderr = $stderrTask.GetAwaiter().GetResult().Trim()
        if ($process.ExitCode -ne 0) {
            throw "OMP version probe failed: $stderr"
        }
        $stdout
    } finally {
        $process.Dispose()
    }
}

function Resolve-Phase00ConfigOmpRuntime {
    param([string]$OmpExecutable)

    $selection = if ([string]::IsNullOrWhiteSpace($OmpExecutable)) {
        'INSTALLED_COMMAND'
    } else {
        'EXPLICIT_SOURCE'
    }
    $path = if ($selection -eq 'EXPLICIT_SOURCE') {
        [System.IO.Path]::GetFullPath($OmpExecutable)
    } else {
        Get-Phase00InstalledOmpPath
    }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Selected OMP executable was not found: $path"
    }
    $sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
    if ($sha256 -cne $script:Phase00ConfigRuntimeSha256) {
        throw "Selected OMP executable SHA-256 is not the pinned 17.2.10 runtime: $sha256"
    }
    $version = Get-Phase00ConfigOmpVersion -OmpExecutable $path
    if ($version -cne 'omp/17.2.10') {
        throw "Selected OMP executable is not the required 17.2.10: $version"
    }
    [pscustomobject][ordered]@{
        Path = $path
        Selection = $selection
        Version = $version
        Sha256 = $sha256
    }
}

function Get-Phase00ConfigProcessEnvironment {
    param([Parameter(Mandatory)][string]$AgentDirectory)

    return @{ PI_CODING_AGENT_DIR = [System.IO.Path]::GetFullPath($AgentDirectory) }
}

function Get-Phase00ConfigCommandArguments {
    param(
        [Parameter(Mandatory)][string]$Key,
        [string]$OverlayPath,
        [ValidateSet('None','Before','After')][string]$OverlayPosition = 'None'
    )

    if ($OverlayPosition -ne 'None' -and [string]::IsNullOrWhiteSpace($OverlayPath)) {
        throw 'OverlayPath is required for an overlay argument placement.'
    }
    switch ($OverlayPosition) {
        'Before' { return @('--config',$OverlayPath,'config','get',$Key,'--json') }
        'After' { return @('config','get',$Key,'--json','--config',$OverlayPath) }
        default { return @('config','get',$Key,'--json') }
    }
}

function Get-Phase00ParentArguments {
    param(
        [Parameter(Mandatory)][ValidateSet('A4','H5')][string]$CaseId,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$SessionDirectory,
        [Parameter(Mandatory)][string]$ConfigPath,
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$Prompt
    )

    $tools = if ($CaseId -eq 'A4') { 'task,bash,eval' } else { 'bash' }
    return @(
        '-p',
        '--mode', 'json',
        '--cwd', $FixtureRoot,
        '--session-dir', $SessionDirectory,
        '--config', $ConfigPath,
        '--model', $Model,
        '--tools', $tools,
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

function Get-Phase00PathWithoutOmp {
    param(
        [AllowEmptyString()][Parameter(Mandatory)][string]$PathValue,
        [Parameter(Mandatory)][string]$OmpDirectory
    )

    $target = [System.IO.Path]::GetFullPath($OmpDirectory).TrimEnd('\','/')
    $kept = @($PathValue -split [regex]::Escape([string][System.IO.Path]::PathSeparator) | Where-Object {
        if ([string]::IsNullOrWhiteSpace($_)) { return $false }
        $candidate = [System.IO.Path]::GetFullPath($_).TrimEnd('\','/')
        -not $candidate.Equals($target, [System.StringComparison]::OrdinalIgnoreCase)
    })
    return ($kept -join [System.IO.Path]::PathSeparator)
}

function Assert-Phase00ConfigDisposableRoot {
    param([Parameter(Mandatory)][string]$Path)

    $resolved = [System.IO.Path]::GetFullPath($Path).TrimEnd('\','/')
    $temp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\','/')
    $prefix = $temp + [System.IO.Path]::DirectorySeparatorChar
    if (-not ($resolved + [System.IO.Path]::DirectorySeparatorChar).StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Disposable root is outside the OS temporary directory: $resolved"
    }
    if ([System.IO.Path]::GetPathRoot($resolved) -eq $resolved) {
        throw "Refusing a filesystem root as disposable path: $resolved"
    }
    return $resolved
}

function Initialize-Phase00ConfigFixture {
    param(
        [Parameter(Mandatory)][string]$DisposableRoot,
        [Parameter(Mandatory)][ValidateSet('A1','A2','A3','A4','H2','H3','H5')][string]$CaseId
    )

    $root = Assert-Phase00ConfigDisposableRoot $DisposableRoot
    $fixtureSource = Join-Path $script:Phase00ConfigRunnerRoot 'docs\evidence\phase-00\E3-A\fixture'
    $agentDirectory = Join-Path $root 'agent'
    $projectRoot = Join-Path $root 'project'
    $projectConfigDirectory = Join-Path $projectRoot '.omp'
    $nestedCwd = Join-Path $projectRoot 'packages\foo'
    $sessionDirectory = Join-Path $root 'sessions'
    $overlayPath = Join-Path $projectRoot 'overlay.yml'

    foreach ($directory in @($agentDirectory,$projectRoot,$nestedCwd,$sessionDirectory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    Copy-Item -LiteralPath (Join-Path $fixtureSource 'global-config.yml') -Destination (Join-Path $agentDirectory 'config.yml')
    Copy-Item -LiteralPath (Join-Path $fixtureSource 'overlay-config.yml') -Destination $overlayPath

    if ($CaseId -ne 'H2') {
        New-Item -ItemType Directory -Path $projectConfigDirectory -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $fixtureSource 'project-config.yml') -Destination (Join-Path $projectConfigDirectory 'config.yml')
    }

    $fixtureHead = $null
    if ($CaseId -in @('A4','H5')) {
        $modelCatalogPath = Join-Path $script:Phase00ConfigRunnerRoot 'docs\evidence\phase-00\environment\runtime-models.yml'
        Copy-Item -LiteralPath $modelCatalogPath -Destination (Join-Path $agentDirectory 'models.yml')
    }
    if ($CaseId -eq 'A4') {
        $agentTarget = Join-Path $projectConfigDirectory 'agents'
        New-Item -ItemType Directory -Path $agentTarget -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $fixtureSource '.omp\agents\phase00-apply-probe.md') -Destination $agentTarget
        $null = & git -C $projectRoot init -q
        if ($LASTEXITCODE -ne 0) { throw 'Disposable A4 Git initialization failed.' }
        $null = & git -C $projectRoot config user.email 'phase00-evidence@example.invalid'
        $null = & git -C $projectRoot config user.name 'Phase 00 Evidence'
        $null = & git -C $projectRoot add --all
        $commitOutput = @(& git -C $projectRoot commit -q -m 'phase00 A4 fixture' 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Disposable A4 baseline commit failed: $($commitOutput -join ' ')" }
        $fixtureHead = (& git -C $projectRoot rev-parse HEAD).Trim()
    }

    return [pscustomobject][ordered]@{
        DisposableRoot = $root
        AgentDirectory = $agentDirectory
        ProjectRoot = $projectRoot
        NestedCwd = $nestedCwd
        SessionDirectory = $sessionDirectory
        OverlayPath = $overlayPath
        FixtureHead = $fixtureHead
    }
}

function Invoke-Phase00CapturedProcess {
    param(
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][hashtable]$Environment,
        [Parameter(Mandatory)][string]$StderrPath,
        [ValidateRange(1,3600)][int]$TimeoutSeconds = 600
    )

    $process = [System.Diagnostics.Process]::new()
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = [System.IO.Path]::GetFullPath($Executable)
    $startInfo.WorkingDirectory = [System.IO.Path]::GetFullPath($WorkingDirectory)
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($key in $Environment.Keys) {
        $startInfo.EnvironmentVariables[[string]$key] = [string]$Environment[$key]
    }

    $argumentListProperty = $startInfo.PSObject.Properties['ArgumentList']
    if ($null -ne $argumentListProperty) {
        foreach ($argument in $Arguments) { [void]$startInfo.ArgumentList.Add([string]$argument) }
    } else {
        $quotedArguments = foreach ($argumentValue in $Arguments) {
            $argument = [string]$argumentValue
            if ($argument.Length -gt 0 -and $argument -notmatch '[\s"]') {
                $argument
                continue
            }
            $builder = [System.Text.StringBuilder]::new()
            [void]$builder.Append('"')
            $backslashes = 0
            foreach ($character in $argument.ToCharArray()) {
                if ($character -eq '\') {
                    $backslashes += 1
                    continue
                }
                if ($character -eq '"') {
                    [void]$builder.Append(('\' * (($backslashes * 2) + 1)))
                    [void]$builder.Append('"')
                    $backslashes = 0
                    continue
                }
                if ($backslashes -gt 0) { [void]$builder.Append(('\' * $backslashes)) }
                [void]$builder.Append($character)
                $backslashes = 0
            }
            if ($backslashes -gt 0) { [void]$builder.Append(('\' * ($backslashes * 2))) }
            [void]$builder.Append('"')
            $builder.ToString()
        }
        $startInfo.Arguments = $quotedArguments -join ' '
    }

    $process.StartInfo = $startInfo
    $started = [DateTimeOffset]::Now
    try {
        if (-not $process.Start()) { throw 'Child process did not start.' }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            try { $process.Kill() } catch {}
            throw "Child process timed out after $TimeoutSeconds seconds."
        }
        $process.WaitForExit()
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        $completed = [DateTimeOffset]::Now
        $stderrParent = Split-Path -Parent $StderrPath
        if (-not (Test-Path -LiteralPath $stderrParent -PathType Container)) {
            New-Item -ItemType Directory -Path $stderrParent -Force | Out-Null
        }
        [System.IO.File]::WriteAllText($StderrPath, $stderr, [System.Text.UTF8Encoding]::new($false))
        return [pscustomobject][ordered]@{
            ExitCode = [int]$process.ExitCode
            StartedAt = $started
            CompletedAt = $completed
            Stdout = [string]$stdout
            Stderr = [string]$stderr
        }
    } finally {
        $process.Dispose()
    }
}

function Get-Phase00ConfigDirectoryMetadataSnapshot {
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

function Compare-Phase00ConfigDirectoryMetadataSnapshot {
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

function Remove-Phase00ConfigDisposableDirectory {
    param([Parameter(Mandatory)][string]$Path)

    $verified = Assert-Phase00ConfigDisposableRoot $Path
    for ($cleanupAttempt = 1; $cleanupAttempt -le 10; $cleanupAttempt++) {
        if (-not (Test-Path -LiteralPath $verified)) { return }
        try {
            Remove-Item -LiteralPath $verified -Recurse -Force -ErrorAction Stop
            return
        } catch {
            if ($cleanupAttempt -eq 10) { throw }
            Start-Sleep -Milliseconds (100 * $cleanupAttempt)
        }
    }
}

function Write-Phase00ConfigUtf8NoBom {
    param(
        [Parameter(Mandatory)][string]$Path,
        [AllowEmptyString()][Parameter(Mandatory)][string]$Text
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Get-Phase00DirectCaseAnalysis {
    param(
        [Parameter(Mandatory)][ValidateSet('A1','A2','A3','H2','H3')][string]$CaseId,
        [Parameter(Mandatory)][object[]]$Operations
    )

    $byName = @{}
    foreach ($operation in $Operations) { $byName[[string]$operation.Name] = $operation.Classification }
    switch ($CaseId) {
        'A1' {
            return Test-Phase00A1Evidence -ModeResult $byName.root_mode -ApplyResult $byName.root_apply
        }
        'A2' {
            return Test-Phase00A2Evidence -UnknownResult $byName.unknown_key
        }
        'A3' {
            return Test-Phase00A3Evidence -RootModeResult $byName.root_mode -RootApplyResult $byName.root_apply `
                -NestedModeResult $byName.nested_mode -NestedApplyResult $byName.nested_apply
        }
        'H2' {
            return Test-Phase00H2Evidence -ModeResult $byName.no_project_mode -ApplyResult $byName.no_project_apply
        }
        'H3' {
            return Test-Phase00H3Evidence -BeforeResult $byName.overlay_before -AfterResult $byName.overlay_after
        }
    }
}

function Invoke-Phase00ConfigEvidenceCase {
    param(
        [Parameter(Mandatory)][ValidateSet('A1','A2','A3','A4','H2','H3','H5')][string]$CaseId,
        [Parameter(Mandatory)][string]$Model,
        [ValidateRange(1,999)][int]$Attempt = 1,
        [string]$EvidenceRoot = (Join-Path $script:Phase00ConfigRunnerRoot 'docs\evidence\phase-00'),
        [string]$OmpExecutable,
        [switch]$AllowOverwrite
    )

    foreach ($requiredFunction in @(
        'Get-Phase00ConfigCommandClassification','Test-Phase00A1Evidence',
        'Test-Phase00A2Evidence','Test-Phase00A3Evidence','Test-Phase00A4Evidence',
        'Test-Phase00H2Evidence','Test-Phase00H3Evidence','Test-Phase00H5Evidence',
        'Protect-Phase00EvidenceText','Read-Phase00JsonLines','Get-Phase00TerminalModelFailure'
    )) {
        if ($null -eq (Get-Command $requiredFunction -ErrorAction SilentlyContinue)) {
            throw "Required evidence function is unavailable: $requiredFunction"
        }
    }

    $definition = Get-Phase00ConfigCaseDefinition -CaseId $CaseId
    $runtime = Resolve-Phase00ConfigOmpRuntime -OmpExecutable $OmpExecutable
    $ompPath = $runtime.Path
    $versionOutput = @($runtime.Version)

    $resolvedEvidenceRoot = [System.IO.Path]::GetFullPath($EvidenceRoot)
    $rawRoot = Join-Path $resolvedEvidenceRoot "$($definition.Experiment)\raw"
    $stem = if ($Attempt -eq 1) { $CaseId } else { "$CaseId-attempt-{0:D3}" -f $Attempt }
    $stdoutExtension = if ($definition.Provider) { 'stdout.jsonl' } else { 'stdout.json' }
    $stdoutPath = Join-Path $rawRoot "$stem.$stdoutExtension"
    $stderrPath = Join-Path $rawRoot "$stem.stderr.txt"
    $runPath = Join-Path $rawRoot "$stem.run.json"
    $existing = @($stdoutPath,$stderrPath,$runPath | Where-Object { Test-Path -LiteralPath $_ })
    if (-not $AllowOverwrite -and $existing.Count -gt 0) {
        throw "Evidence already exists for $CaseId attempt $Attempt."
    }

    $disposable = Assert-Phase00ConfigDisposableRoot (Join-Path ([System.IO.Path]::GetTempPath()) ("omp-phase00-$($CaseId.ToLowerInvariant())-{0}" -f [guid]::NewGuid().ToString('N')))
    $liveAgentDirectory = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.omp\agent'
    $liveBefore = Get-Phase00ConfigDirectoryMetadataSnapshot -Path $liveAgentDirectory
    $liveAfter = $null
    $liveComparison = $null
    $fixture = $null
    $operations = [System.Collections.Generic.List[object]]::new()
    $providerResult = $null
    $analysis = $null
    $safeProviderStdout = ''
    $safeProviderStderr = ''
    $sentinelObserved = $false
    $cleanupSucceeded = $false
    $cleanupError = $null
    try {
        $fixture = Initialize-Phase00ConfigFixture -DisposableRoot $disposable -CaseId $CaseId
        $processEnvironment = Get-Phase00ConfigProcessEnvironment -AgentDirectory $fixture.AgentDirectory

        if (-not $definition.Provider) {
            $operationDefinitions = switch ($CaseId) {
                'A1' {
                    @(
                        [pscustomobject]@{ Name = 'root_mode'; Key = 'task.isolation.mode'; Cwd = $fixture.ProjectRoot; Context = 'ProjectRoot'; Position = 'None' },
                        [pscustomobject]@{ Name = 'root_apply'; Key = 'task.isolation.apply'; Cwd = $fixture.ProjectRoot; Context = 'ProjectRoot'; Position = 'None' }
                    )
                }
                'A2' {
                    @([pscustomobject]@{ Name = 'unknown_key'; Key = 'task.isolation.__phase00_unknown'; Cwd = $fixture.ProjectRoot; Context = 'DirectRead'; Position = 'None' })
                }
                'A3' {
                    @(
                        [pscustomobject]@{ Name = 'root_mode'; Key = 'task.isolation.mode'; Cwd = $fixture.ProjectRoot; Context = 'ProjectRoot'; Position = 'None' },
                        [pscustomobject]@{ Name = 'root_apply'; Key = 'task.isolation.apply'; Cwd = $fixture.ProjectRoot; Context = 'ProjectRoot'; Position = 'None' },
                        [pscustomobject]@{ Name = 'nested_mode'; Key = 'task.isolation.mode'; Cwd = $fixture.NestedCwd; Context = 'NestedCwd'; Position = 'None' },
                        [pscustomobject]@{ Name = 'nested_apply'; Key = 'task.isolation.apply'; Cwd = $fixture.NestedCwd; Context = 'NestedCwd'; Position = 'None' }
                    )
                }
                'H2' {
                    @(
                        [pscustomobject]@{ Name = 'no_project_mode'; Key = 'task.isolation.mode'; Cwd = $fixture.ProjectRoot; Context = 'NoProject'; Position = 'None' },
                        [pscustomobject]@{ Name = 'no_project_apply'; Key = 'task.isolation.apply'; Cwd = $fixture.ProjectRoot; Context = 'NoProject'; Position = 'None' }
                    )
                }
                'H3' {
                    @(
                        [pscustomobject]@{ Name = 'overlay_before'; Key = 'task.isolation.apply'; Cwd = $fixture.ProjectRoot; Context = 'CliOverlay'; Position = 'Before' },
                        [pscustomobject]@{ Name = 'overlay_after'; Key = 'task.isolation.apply'; Cwd = $fixture.ProjectRoot; Context = 'CliOverlay'; Position = 'After' }
                    )
                }
            }
            $operationIndex = 0
            foreach ($operationDefinition in @($operationDefinitions)) {
                $operationIndex += 1
                $operationStderr = Join-Path $disposable ("operation-{0:D2}.stderr.txt" -f $operationIndex)
                $arguments = @(Get-Phase00ConfigCommandArguments -Key $operationDefinition.Key `
                    -OverlayPath $fixture.OverlayPath -OverlayPosition $operationDefinition.Position)
                $captured = Invoke-Phase00CapturedProcess -Executable $ompPath -Arguments $arguments `
                    -WorkingDirectory $operationDefinition.Cwd -Environment $processEnvironment `
                    -StderrPath $operationStderr -TimeoutSeconds 60
                $classification = Get-Phase00ConfigCommandClassification -ExpectedKey $operationDefinition.Key `
                    -ExitCode $captured.ExitCode -Stdout $captured.Stdout -Stderr $captured.Stderr `
                    -Context $operationDefinition.Context
                [void]$operations.Add([pscustomobject][ordered]@{
                    Name = $operationDefinition.Name
                    Key = $operationDefinition.Key
                    Context = $operationDefinition.Context
                    OverlayPosition = $operationDefinition.Position
                    ExitCode = $captured.ExitCode
                    StartedAt = $captured.StartedAt
                    CompletedAt = $captured.CompletedAt
                    Stdout = $captured.Stdout
                    Stderr = $captured.Stderr
                    Classification = $classification
                })
            }
            $analysis = Get-Phase00DirectCaseAnalysis -CaseId $CaseId -Operations @($operations)
        } else {
            $promptRoot = if ($CaseId -eq 'A4') {
                Join-Path $script:Phase00ConfigRunnerRoot 'docs\evidence\phase-00\E3-A\fixture\prompts'
            } else {
                Join-Path $script:Phase00ConfigRunnerRoot 'docs\evidence\phase-00\E3-H\fixture\prompts'
            }
            $prompt = Get-Content -Raw -LiteralPath (Join-Path $promptRoot $definition.Prompt) -Encoding UTF8
            $arguments = @(Get-Phase00ParentArguments -CaseId $CaseId -FixtureRoot $fixture.ProjectRoot `
                -SessionDirectory $fixture.SessionDirectory -ConfigPath $fixture.OverlayPath `
                -Model $Model -Prompt $prompt)
            if ($CaseId -eq 'H5') {
                $processEnvironment.PATH = Get-Phase00PathWithoutOmp -PathValue ([Environment]::GetEnvironmentVariable('PATH','Process')) `
                    -OmpDirectory (Split-Path -Parent $ompPath)
            }
            $providerStderr = Join-Path $disposable 'provider.stderr.txt'
            $providerResult = Invoke-Phase00CapturedProcess -Executable $ompPath -Arguments $arguments `
                -WorkingDirectory $fixture.ProjectRoot -Environment $processEnvironment `
                -StderrPath $providerStderr -TimeoutSeconds 600
            if ($CaseId -eq 'A4') {
                $sentinelPath = Join-Path $fixture.ProjectRoot 'phase00-a4-sentinel.txt'
                $sentinelObserved = (Test-Path -LiteralPath $sentinelPath -PathType Leaf) -and
                    (Get-Content -Raw -LiteralPath $sentinelPath -Encoding UTF8) -eq 'PHASE00_A4_APPLY_TRUE_SENTINEL'
            }
            $safeProviderStdout = Protect-Phase00EvidenceText -Text $providerResult.Stdout `
                -RepositoryRoot $script:Phase00ConfigRunnerRoot -DisposableRoot $disposable
            $safeProviderStderr = Protect-Phase00EvidenceText -Text $providerResult.Stderr `
                -RepositoryRoot $script:Phase00ConfigRunnerRoot -DisposableRoot $disposable
            if ($providerResult.ExitCode -eq 0) {
                $eventPath = Join-Path $disposable 'events.sanitized.jsonl'
                Write-Phase00ConfigUtf8NoBom -Path $eventPath -Text $safeProviderStdout
                $events = @(Read-Phase00JsonLines -Path $eventPath)
                $terminalFailure = Get-Phase00TerminalModelFailure -Events $events
                if ($terminalFailure.Found) {
                    $terminalStatus = if ($terminalFailure.IsEnvironmentBlock) { 'BLOCKED_ENVIRONMENT' } else { 'INVALID_RUN' }
                    $analysis = New-Phase00RuntimeAnalysis $terminalStatus @($terminalFailure.Code) @{
                        Provider = $terminalFailure.Provider
                        Model = $terminalFailure.Model
                        ErrorMessage = $terminalFailure.ErrorMessage
                    }
                } elseif ($CaseId -eq 'A4') {
                    $analysis = Test-Phase00A4Evidence -Events $events -SentinelObserved $sentinelObserved
                } else {
                    $analysis = Test-Phase00H5Evidence -Events $events
                }
            } else {
                $environmentPattern = '(?i)(quota|rate.?limit|authentication|unauthorized|forbidden|provider|model.+not.+found|credential)'
                $status = if (("$safeProviderStdout`n$safeProviderStderr") -match $environmentPattern) { 'BLOCKED_ENVIRONMENT' } else { 'INVALID_RUN' }
                $analysis = New-Phase00RuntimeAnalysis $status @("OMP_EXIT_$($providerResult.ExitCode)")
            }
        }
    } finally {
        $liveAfter = Get-Phase00ConfigDirectoryMetadataSnapshot -Path $liveAgentDirectory
        try {
            Remove-Phase00ConfigDisposableDirectory -Path $disposable
        } catch {
            $cleanupError = $_.Exception.Message
        }
        $cleanupSucceeded = $null -eq $cleanupError -and -not (Test-Path -LiteralPath $disposable)
    }

    $liveComparison = Compare-Phase00ConfigDirectoryMetadataSnapshot -Before $liveBefore -After $liveAfter
    if (-not $cleanupSucceeded) {
        $analysis = New-Phase00RuntimeAnalysis INVALID_RUN @('P00-CONFIG-DISPOSABLE-CLEANUP_FAILED')
    }
    if ($liveComparison.ChangedCount -ne 0) {
        $analysis = New-Phase00RuntimeAnalysis INVALID_RUN @('P00-CONFIG-LIVE-HOME-WRITE')
    }

    if ($definition.Provider) {
        Write-Phase00ConfigUtf8NoBom -Path $stdoutPath -Text $safeProviderStdout
        Write-Phase00ConfigUtf8NoBom -Path $stderrPath -Text $safeProviderStderr
    } else {
        $safeOperations = @($operations | ForEach-Object {
            [ordered]@{
                name = $_.Name
                key = $_.Key
                context = $_.Context
                overlay_position = $_.OverlayPosition
                exit_code = $_.ExitCode
                started_at = $_.StartedAt.ToString('o')
                completed_at = $_.CompletedAt.ToString('o')
                stdout = Protect-Phase00EvidenceText -Text ([string]$_.Stdout) `
                    -RepositoryRoot $script:Phase00ConfigRunnerRoot -DisposableRoot $disposable
                classification = $_.Classification
            }
        })
        $stdoutRecord = [ordered]@{
            schema_version = 1
            case = $CaseId
            attempt = $Attempt
            operations = $safeOperations
        } | ConvertTo-Json -Depth 12
        $safeStderrParts = @($operations | ForEach-Object {
            $safeText = Protect-Phase00EvidenceText -Text ([string]$_.Stderr) `
                -RepositoryRoot $script:Phase00ConfigRunnerRoot -DisposableRoot $disposable
            "[$($_.Name)]`n$safeText"
        })
        Write-Phase00ConfigUtf8NoBom -Path $stdoutPath -Text $stdoutRecord
        Write-Phase00ConfigUtf8NoBom -Path $stderrPath -Text ($safeStderrParts -join "`n")
    }

    $commandRecord = if ($definition.Provider) {
        @('omp','-p','--mode','json','--cwd','<DISPOSABLE_PROJECT>','--session-dir','<DISPOSABLE_SESSIONS>',
            '--config','<DISPOSABLE_PROJECT>/overlay.yml','--model',$Model,'--tools',$(if ($CaseId -eq 'A4') { 'task,bash,eval' } else { 'bash' }),
            '--approval-mode','yolo','--max-time','8m','<REVIEWED_PROMPT>')
    } else {
        @('absolute omp 17.2.10 config-get operations; see stdout operation records')
    }
    $runRecord = [ordered]@{
        schema_version = 1
        case = $CaseId
        attempt = $Attempt
        experiment = $definition.Experiment
        omp_version = ($versionOutput -join ' ').Trim()
        omp_runtime = [ordered]@{
            selection = $runtime.Selection
            sha256 = $runtime.Sha256
        }
        model = if ($definition.Provider) { $Model } else { $null }
        provider_call = [bool]$definition.Provider
        process_environment = [ordered]@{
            PI_CODING_AGENT_DIR = '<DISPOSABLE_AGENT_DIR>'
            PATH = if ($CaseId -eq 'H5') { 'FILTERED_OMP_DIRECTORY' } else { 'INHERITED' }
        }
        fixture_commit = if ($null -ne $fixture) { $fixture.FixtureHead } else { $null }
        command = $commandRecord
        process_exit_code = if ($definition.Provider -and $null -ne $providerResult) { $providerResult.ExitCode } else { $null }
        started_at = if ($definition.Provider -and $null -ne $providerResult) { $providerResult.StartedAt.ToString('o') } else { $null }
        completed_at = if ($definition.Provider -and $null -ne $providerResult) { $providerResult.CompletedAt.ToString('o') } else { $null }
        duration_ms = if ($definition.Provider -and $null -ne $providerResult) { [long]($providerResult.CompletedAt - $providerResult.StartedAt).TotalMilliseconds } else { $null }
        cleanup_succeeded = $cleanupSucceeded
        cleanup_error = $cleanupError
        live_home_metadata = [ordered]@{
            before_file_count = $liveComparison.BeforeFileCount
            after_file_count = $liveComparison.AfterFileCount
            before_sha256 = $liveComparison.BeforeSha256
            after_sha256 = $liveComparison.AfterSha256
            changed_count = $liveComparison.ChangedCount
            changed_paths = @($liveComparison.ChangedPaths)
            boundary_result = $liveComparison.BoundaryResult
        }
        sentinel_observed = if ($CaseId -eq 'A4') { $sentinelObserved } else { $null }
        analysis = $analysis
    } | ConvertTo-Json -Depth 15
    Write-Phase00ConfigUtf8NoBom -Path $runPath -Text $runRecord

    return [pscustomobject][ordered]@{
        CaseId = $CaseId
        Attempt = $Attempt
        Experiment = $definition.Experiment
        Analysis = $analysis
        StdoutPath = $stdoutPath
        StderrPath = $stderrPath
        RunPath = $runPath
        CleanupSucceeded = $cleanupSucceeded
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase00ConfigEvidenceCase -CaseId $CaseId -Model $Model `
        -Attempt $Attempt -OmpExecutable $OmpExecutable `
        -AllowOverwrite:$AllowOverwrite
}
