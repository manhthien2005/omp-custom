#Requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet('A','B')][string]$Session = 'A',
    [string]$Model = 'omniroute/codex/gpt-5.6-sol-high',
    [ValidateRange(1,999)][int]$Attempt = 1,
    [string]$OmpExecutable,
    [switch]$AllowOverwrite
)

Set-StrictMode -Version 2.0

$script:Phase00E3IRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:Phase00E3IFixtureSource = Join-Path $script:Phase00E3IRoot `
    'docs\evidence\phase-00\E3-I\fixture'
. (Join-Path $PSScriptRoot 'lib\phase00-runtime-evidence.ps1')
. (Join-Path $PSScriptRoot 'lib\phase00-config-evidence.ps1')
. (Join-Path $PSScriptRoot 'lib\phase00-e3i-evidence.ps1')

function Get-Phase00E3IParentArguments {
    param(
        [Parameter(Mandatory)][ValidateSet('A','B')][string]$Session,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$SessionDirectory,
        [Parameter(Mandatory)][string]$OverlayPath,
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$Prompt
    )

    $arguments = @(
        '-p','--mode','json','--cwd',$FixtureRoot,
        '--session-dir',$SessionDirectory,'--model',$Model,
        '--tools','task,bash','--approval-mode','yolo','--max-time','12m',
        '--no-extensions','--no-skills','--no-rules','--no-lsp','--no-title'
    )
    if ($Session -eq 'B') {
        $insert = [Array]::IndexOf($arguments, '--model')
        $arguments = @(
            $arguments[0..($insert - 1)] + @('--config',$OverlayPath) +
            $arguments[$insert..($arguments.Count - 1)]
        )
    }
    @($arguments + $Prompt)
}

function Get-Phase00E3IProcessEnvironment {
    param(
        [Parameter(Mandatory)][ValidateSet('A','B')][string]$Session,
        [Parameter(Mandatory)]$Fixture,
        $PinnedRuntime
    )

    $environment = @{
        PI_CODING_AGENT_DIR = [string]$Fixture.AgentDirectory
        USERPROFILE = [string]$Fixture.UserProfileDirectory
        OMP_PHASE00_E3IL_PARENT_CWD = [string]$Fixture.ProjectRoot
        OMP_PHASE00_E3IL_ENABLE_OVERRIDE = if ($Session -eq 'A') { '1' } else { '0' }
    }
    if ($null -ne $PinnedRuntime) {
        $existingPath = [Environment]::GetEnvironmentVariable('PATH', 'Process')
        $environment.PATH = [string]$PinnedRuntime.Directory +
            [IO.Path]::PathSeparator + $existingPath
    }
    $environment
}

function Assert-Phase00E3IDisposableRoot {
    param([Parameter(Mandatory)][string]$Path)

    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')
    $resolved = [IO.Path]::GetFullPath($Path).TrimEnd('\','/')
    if ($resolved -eq $tempRoot) {
        throw "Refusing the system temporary directory itself: $resolved"
    }
    $tempPrefix = $tempRoot + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Disposable root is outside the system temporary directory: $resolved"
    }
    $filesystemRoot = [IO.Path]::GetPathRoot($resolved).TrimEnd('\','/')
    if ($resolved -eq $filesystemRoot) {
        throw "Refusing a filesystem root as disposable path: $resolved"
    }
    $resolved
}

function Remove-Phase00E3IDisposableDirectory {
    param([Parameter(Mandatory)][string]$Path)

    $verified = Assert-Phase00E3IDisposableRoot -Path $Path
    for ($cleanupAttempt = 1; $cleanupAttempt -le 10; $cleanupAttempt++) {
        if (-not (Test-Path -LiteralPath $verified)) { break }
        try {
            Remove-Item -LiteralPath $verified -Recurse -Force -ErrorAction Stop
        } catch {
            if ($cleanupAttempt -eq 10) { throw }
            Start-Sleep -Milliseconds (100 * $cleanupAttempt)
        }
    }
    if (Test-Path -LiteralPath $verified) {
        throw "Disposable directory still exists after cleanup: $verified"
    }
}

function Write-Phase00E3IUtf8NoBom {
    param(
        [Parameter(Mandatory)][string]$Path,
        [AllowEmptyString()][Parameter(Mandatory)][string]$Text
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Initialize-Phase00E3IFixture {
    param([Parameter(Mandatory)][string]$Root)

    $verifiedRoot = Assert-Phase00E3IDisposableRoot -Path $Root
    if (Test-Path -LiteralPath $verifiedRoot) {
        $existing = @(Get-ChildItem -LiteralPath $verifiedRoot -Force -ErrorAction Stop)
        if ($existing.Count -gt 0) {
            throw "Disposable root is not empty: $verifiedRoot"
        }
    }
    $agentDirectory = Join-Path $verifiedRoot 'agent'
    $projectRoot = Join-Path $verifiedRoot 'project'
    $sessionDirectory = Join-Path $verifiedRoot 'sessions'
    $userProfileDirectory = Join-Path $verifiedRoot 'user-profile'
    foreach ($directory in @(
        $verifiedRoot,$agentDirectory,$projectRoot,$sessionDirectory,$userProfileDirectory
    )) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $script:Phase00E3IFixtureSource -PathType Container)) {
        throw "E3-I fixture source is missing: $script:Phase00E3IFixtureSource"
    }
    Get-ChildItem -LiteralPath $script:Phase00E3IFixtureSource -Force |
        Copy-Item -Destination $projectRoot -Recurse -Force

    $modelCatalogPath = Join-Path $script:Phase00E3IRoot `
        'docs\evidence\phase-00\environment\runtime-models.yml'
    if (-not (Test-Path -LiteralPath $modelCatalogPath -PathType Leaf)) {
        throw "Runtime model catalog is missing: $modelCatalogPath"
    }
    Copy-Item -LiteralPath $modelCatalogPath `
        -Destination (Join-Path $agentDirectory 'models.yml') -Force

    $commands = @(
        @('init','--quiet'),
        @('config','user.name','Phase 00 E3-I Probe'),
        @('config','user.email','phase00-e3i.invalid@example.invalid'),
        @('config','core.autocrlf','false'),
        @('add','--all'),
        @(
            '-c','commit.gpgSign=false','-c','core.hooksPath=NUL','commit','--quiet',
            '-m','phase00 E3-I disposable fixture baseline'
        )
    )
    foreach ($gitArguments in $commands) {
        $output = @(& git -C $projectRoot @gitArguments 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "Disposable Git initialization failed: $($output -join ' ')"
        }
    }
    $status = @(& git -C $projectRoot status --porcelain=v1 --untracked-files=all 2>&1)
    if ($LASTEXITCODE -ne 0 -or $status.Count -ne 0) {
        throw "Disposable Git fixture is not clean: $($status -join ' ')"
    }
    $baselineHead = (& git -C $projectRoot rev-parse HEAD 2>&1).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($baselineHead)) {
        throw 'Disposable Git fixture lacks a baseline HEAD.'
    }

    $agentFull = [IO.Path]::GetFullPath($agentDirectory)
    $projectFull = [IO.Path]::GetFullPath($projectRoot)
    [pscustomobject][ordered]@{
        Root = [IO.Path]::GetFullPath($verifiedRoot)
        AgentDirectory = $agentFull
        ProjectRoot = $projectFull
        SessionDirectory = [IO.Path]::GetFullPath($sessionDirectory)
        UserProfileDirectory = [IO.Path]::GetFullPath($userProfileDirectory)
        OverlayPath = [IO.Path]::GetFullPath((Join-Path $projectRoot 'overlay.yml'))
        BaselineHead = $baselineHead
        Environment = @{
            PI_CODING_AGENT_DIR = $agentFull
            USERPROFILE = [IO.Path]::GetFullPath($userProfileDirectory)
            OMP_PHASE00_E3IL_PARENT_CWD = $projectFull
            OMP_PHASE00_E3IL_ENABLE_OVERRIDE = '1'
        }
    }
}

function Get-Phase00E3ISha256Text {
    param([AllowEmptyString()][Parameter(Mandatory)][string]$Text)

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $digest = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))
    } finally {
        $sha.Dispose()
    }
    ([BitConverter]::ToString($digest)).Replace('-','').ToUpperInvariant()
}

function Get-Phase00E3IRepositorySnapshot {
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $root = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\','/')
    $rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
    $gitPrefix = (Join-Path $root '.git').TrimEnd('\','/') +
        [IO.Path]::DirectorySeparatorChar
    $rows = @(Get-ChildItem -LiteralPath $root -Force -File -Recurse | Where-Object {
        -not $_.FullName.StartsWith($gitPrefix, [StringComparison]::OrdinalIgnoreCase)
    } | ForEach-Object {
        [pscustomobject][ordered]@{
            Path = $_.FullName.Substring($rootPrefix.Length).Replace('\','/')
            Sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
    } | Sort-Object Path)
    $canonical = @($rows | ForEach-Object { "$($_.Path)`t$($_.Sha256)`n" }) -join ''

    $head = (& git -C $root rev-parse HEAD 2>&1).Trim()
    if ($LASTEXITCODE -ne 0) { throw "Cannot read disposable HEAD: $head" }
    $status = @(& git -C $root status --porcelain=v1 --untracked-files=all 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Cannot read disposable status: $($status -join ' ')" }

    $fixturePaths = [ordered]@{
        ProjectConfig = '.omp\config.yml'
        Overlay = 'overlay.yml'
        Agent = '.omp\agents\phase00-e3i-canary.md'
        OverrideTool = '.omp\tools\phase00-e3i-runtime-override.ts'
        SessionA = 'prompts\session-a.md'
        SessionB = 'prompts\session-b.md'
    }
    $fixtureHashes = [ordered]@{}
    foreach ($key in $fixturePaths.Keys) {
        $path = Join-Path $root $fixturePaths[$key]
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Fixture file is missing from disposable project: $($fixturePaths[$key])"
        }
        $fixtureHashes[$key] = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
    }

    [pscustomobject][ordered]@{
        ContentSha256 = Get-Phase00E3ISha256Text -Text $canonical
        FileCount = $rows.Count
        Files = @($rows)
        Head = $head
        Status = @($status)
        FixtureHashes = $fixtureHashes
    }
}

function Compare-Phase00E3IRepositorySnapshot {
    param(
        [Parameter(Mandatory)]$Before,
        [Parameter(Mandatory)]$After,
        [Parameter(Mandatory)][bool]$LiveHomeUnchanged,
        [Parameter(Mandatory)][bool]$CleanupSucceeded
    )

    $fixtureKeys = @(
        'ProjectConfig','Overlay','Agent','OverrideTool','SessionA','SessionB'
    )
    $fixtureUnchanged = $true
    foreach ($key in $fixtureKeys) {
        if ([string](Get-Phase00PropertyValue $Before.FixtureHashes $key) -ne
            [string](Get-Phase00PropertyValue $After.FixtureHashes $key)) {
            $fixtureUnchanged = $false
        }
    }
    [pscustomobject][ordered]@{
        ParentContentUnchanged = [string]$Before.ContentSha256 -eq [string]$After.ContentSha256
        ParentHeadUnchanged = [string]$Before.Head -eq [string]$After.Head
        ParentStatusUnchanged = (@($Before.Status) -join "`n") -eq
            (@($After.Status) -join "`n")
        FixtureHashesUnchanged = $fixtureUnchanged
        LiveHomeUnchanged = $LiveHomeUnchanged
        CleanupSucceeded = $CleanupSucceeded
    }
}

function Get-Phase00E3IDirectoryMetadataSnapshot {
    param([Parameter(Mandatory)][string]$Path)

    $fullRoot = [IO.Path]::GetFullPath($Path).TrimEnd('\','/')
    $entries = @()
    if (Test-Path -LiteralPath $fullRoot -PathType Container) {
        $rootPrefix = $fullRoot + [IO.Path]::DirectorySeparatorChar
        $entries = @(Get-ChildItem -LiteralPath $fullRoot -Force -File -Recurse |
            ForEach-Object {
                [pscustomobject][ordered]@{
                    Path = $_.FullName.Substring($rootPrefix.Length).Replace('\','/')
                    Length = [long]$_.Length
                    LastWriteUtcTicks = [long]$_.LastWriteTimeUtc.Ticks
                    Sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
                }
            } | Sort-Object Path)
    }
    $canonical = @($entries | ForEach-Object {
        '{0}|{1}|{2}|{3}' -f $_.Path,$_.Length,$_.LastWriteUtcTicks,$_.Sha256
    }) -join "`n"
    [pscustomobject][ordered]@{
        FileCount = $entries.Count
        Sha256 = Get-Phase00E3ISha256Text -Text $canonical
        Entries = @($entries)
    }
}

function Compare-Phase00E3IDirectoryMetadataSnapshot {
    param(
        [Parameter(Mandatory)]$Before,
        [Parameter(Mandatory)]$After
    )

    $beforeByPath = @{}
    $afterByPath = @{}
    foreach ($entry in @($Before.Entries)) { $beforeByPath[[string]$entry.Path] = $entry }
    foreach ($entry in @($After.Entries)) { $afterByPath[[string]$entry.Path] = $entry }
    $changed = @($beforeByPath.Keys + $afterByPath.Keys | Sort-Object -Unique |
        Where-Object {
            $relativePath = [string]$_
            if (-not $beforeByPath.ContainsKey($relativePath) -or
                -not $afterByPath.ContainsKey($relativePath)) {
                return $true
            }
            $left = $beforeByPath[$relativePath]
            $right = $afterByPath[$relativePath]
            [long]$left.Length -ne [long]$right.Length -or
                [long]$left.LastWriteUtcTicks -ne [long]$right.LastWriteUtcTicks -or
                [string]$left.Sha256 -ne [string]$right.Sha256
        })
    [pscustomobject][ordered]@{
        BeforeFileCount = [int]$Before.FileCount
        AfterFileCount = [int]$After.FileCount
        BeforeSha256 = [string]$Before.Sha256
        AfterSha256 = [string]$After.Sha256
        ChangedPaths = @($changed)
        ChangedCount = $changed.Count
        BoundaryResult = if ($changed.Count -eq 0) { 'PASS' } else { 'FAIL' }
    }
}

function ConvertTo-Phase00E3IWindowsArgument {
    param([AllowEmptyString()][Parameter(Mandatory)][string]$Argument)

    if ($Argument.Length -gt 0 -and $Argument -notmatch '[\s"]') { return $Argument }
    $builder = [Text.StringBuilder]::new()
    [void]$builder.Append('"')
    $backslashes = 0
    foreach ($character in $Argument.ToCharArray()) {
        if ($character -eq '\') {
            $backslashes++
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

function Stop-Phase00E3IProcessTree {
    param([Parameter(Mandatory)][Diagnostics.Process]$Process)

    if ($Process.HasExited) { return }
    $killTree = $Process.GetType().GetMethod('Kill', [type[]]@([bool]))
    if ($null -ne $killTree) {
        [void]$killTree.Invoke($Process, @($true))
        return
    }
    $taskkill = Get-Command taskkill.exe -ErrorAction SilentlyContinue
    if ($null -ne $taskkill) {
        $taskkillProcess = Start-Process -FilePath $taskkill.Source `
            -ArgumentList @('/PID',[string]$Process.Id,'/T','/F') -Wait -PassThru `
            -WindowStyle Hidden
        if ($taskkillProcess.ExitCode -eq 0) { return }
    }
    $Process.Kill()
}

function Invoke-Phase00E3ICapturedProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Environment,
        [ValidateRange(1,3600)][int]$TimeoutSeconds = 720
    )

    $process = [Diagnostics.Process]::new()
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = [IO.Path]::GetFullPath($FilePath)
    $startInfo.WorkingDirectory = [IO.Path]::GetFullPath($WorkingDirectory)
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($key in $Environment.Keys) {
        $startInfo.EnvironmentVariables[[string]$key] = [string]$Environment[$key]
    }

    if ($null -ne $startInfo.PSObject.Properties['ArgumentList']) {
        foreach ($argument in $Arguments) {
            [void]$startInfo.ArgumentList.Add([string]$argument)
        }
    } else {
        $startInfo.Arguments = @($Arguments | ForEach-Object {
            ConvertTo-Phase00E3IWindowsArgument -Argument ([string]$_)
        }) -join ' '
    }

    $process.StartInfo = $startInfo
    $started = [DateTimeOffset]::Now
    $timedOut = $false
    try {
        if (-not $process.Start()) { throw 'Child process did not start.' }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $timedOut = $true
            Stop-Phase00E3IProcessTree -Process $process
            [void]$process.WaitForExit(10000)
        }
        if (-not $process.HasExited) {
            throw 'Timed-out child process did not terminate.'
        }
        $process.WaitForExit()
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        $completed = [DateTimeOffset]::Now
        [pscustomobject][ordered]@{
            ExitCode = [int]$process.ExitCode
            Stdout = [string]$stdout
            Stderr = [string]$stderr
            StartedAt = $started
            CompletedAt = $completed
            TimedOut = $timedOut
        }
    } finally {
        $process.Dispose()
    }
}

function Initialize-Phase00E3IPinnedRuntime {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$SourceExecutable
    )

    $verifiedRoot = Assert-Phase00E3IDisposableRoot -Path $Root
    $resolvedSource = [IO.Path]::GetFullPath($SourceExecutable)
    if (-not (Test-Path -LiteralPath $resolvedSource -PathType Leaf)) {
        throw "Pinned OMP source executable does not exist: $resolvedSource"
    }

    $runtimeDirectory = Join-Path $verifiedRoot 'runtime'
    if (Test-Path -LiteralPath $runtimeDirectory) {
        $existing = @(Get-ChildItem -LiteralPath $runtimeDirectory -Force)
        if ($existing.Count -gt 0) {
            throw "Disposable runtime directory is not empty: $runtimeDirectory"
        }
    } else {
        New-Item -ItemType Directory -Path $runtimeDirectory -Force | Out-Null
    }
    $copiedExecutable = Join-Path $runtimeDirectory 'omp.exe'
    Copy-Item -LiteralPath $resolvedSource -Destination $copiedExecutable -Force

    $sourceHash = (Get-FileHash -LiteralPath $resolvedSource -Algorithm SHA256).Hash
    $copiedHash = (Get-FileHash -LiteralPath $copiedExecutable -Algorithm SHA256).Hash
    if ($sourceHash -ne $copiedHash) {
        throw 'Pinned OMP runtime copy hash mismatch.'
    }
    $probe = Invoke-Phase00E3ICapturedProcess -FilePath $copiedExecutable `
        -Arguments @('--version') -WorkingDirectory $verifiedRoot `
        -Environment @{} -TimeoutSeconds 30
    $version = $probe.Stdout.Trim()
    if ($probe.TimedOut -or $probe.ExitCode -ne 0 -or $version -ne 'omp/17.2.10') {
        throw "Selected OMP runtime is not the required 17.2.10: $version"
    }

    [pscustomobject][ordered]@{
        Directory = $runtimeDirectory
        Executable = $copiedExecutable
        Version = $version
        SourceSha256 = $sourceHash
        CopiedSha256 = $copiedHash
    }
}

function Resolve-Phase00E3IRunAnalysis {
    param(
        [Parameter(Mandatory)]$SessionAnalysis,
        [Parameter(Mandatory)]$Boundary,
        [Parameter(Mandatory)][bool]$LiveHomeMutationAttributable,
        [string]$CleanupError
    )

    if (-not $Boundary.CleanupSucceeded) {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_CLEANUP_UNCERTAIN') @{
            Error = $CleanupError
            Upstream = $SessionAnalysis
        }
    }
    if (-not $Boundary.ParentContentUnchanged -or
        -not $Boundary.ParentHeadUnchanged -or -not $Boundary.ParentStatusUnchanged) {
        return New-Phase00E3IAnalysis FAIL @('E3I_PARENT_MUTATION') @{
            Upstream = $SessionAnalysis
        }
    }
    if (-not $Boundary.FixtureHashesUnchanged) {
        return New-Phase00E3IAnalysis FAIL @('E3I_OVERRIDE_PERSISTED') @{
            Upstream = $SessionAnalysis
        }
    }
    if (-not $Boundary.LiveHomeUnchanged -and $LiveHomeMutationAttributable) {
        return New-Phase00E3IAnalysis FAIL @('E3I_LIVE_HOME_MUTATION') @{
            Upstream = $SessionAnalysis
        }
    }
    if ($SessionAnalysis.Status -in @('FAIL','BLOCKED_ENVIRONMENT')) {
        return $SessionAnalysis
    }
    if (-not $Boundary.LiveHomeUnchanged) {
        $reasons = if ($SessionAnalysis.Status -eq 'INVALID_RUN') {
            @($SessionAnalysis.Reasons) + @('E3I_LIVE_HOME_CONCURRENT_ACTIVITY')
        } else {
            @('E3I_LIVE_HOME_CONCURRENT_ACTIVITY')
        }
        return New-Phase00E3IAnalysis INVALID_RUN @($reasons | Select-Object -Unique) @{
            Upstream = $SessionAnalysis
        }
    }
    $SessionAnalysis
}

function New-Phase00E3ICaptureFailureAnalysis {
    param(
        [Parameter(Mandatory)][string]$ErrorMessage,
        [Parameter(Mandatory)][bool]$TimedOut
    )

    $reason = if ($TimedOut) { 'E3I_TIMEOUT' } else {
        'E3I_CANARY_PROVENANCE_MISSING'
    }
    New-Phase00E3IAnalysis INVALID_RUN @($reason) @{
        Error = $ErrorMessage
    }
}

function Copy-Phase00E3ICanaryArtifacts {
    param(
        [Parameter(Mandatory)][string]$SessionDirectory,
        [Parameter(Mandatory)][string]$DestinationDirectory,
        [Parameter(Mandatory)][string]$Stem,
        [Parameter(Mandatory)][string[]]$ExpectedIds,
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$DisposableRoot
    )

    $artifacts = @()
    foreach ($id in $ExpectedIds) {
        $matches = @(Get-ChildItem -LiteralPath $SessionDirectory -Force -File -Recurse `
            -Filter "$id.jsonl" -ErrorAction SilentlyContinue)
        if ($matches.Count -ne 1) {
            throw "E3I_CANARY_PROVENANCE_MISSING: '$id' has $($matches.Count) JSONL files."
        }
        $raw = [IO.File]::ReadAllText($matches[0].FullName)
        $safe = Protect-Phase00EvidenceText -Text $raw -RepositoryRoot $RepositoryRoot `
            -DisposableRoot $DisposableRoot
        $safe = ConvertTo-Phase00E3ICanaryProjection -Text $safe
        $destination = Join-Path $DestinationDirectory "$Stem.canary.$id.jsonl"
        Write-Phase00E3IUtf8NoBom -Path $destination -Text $safe
        $events = @(Read-Phase00JsonLines -Path $destination)
        $artifacts += [pscustomobject][ordered]@{
            Id = $id
            Path = $destination
            Sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash
            Events = @($events)
        }
    }
    @($artifacts)
}

function ConvertTo-Phase00E3ICanaryProjection {
    param([AllowEmptyString()][Parameter(Mandatory)][string]$Text)

    $lines = @($Text -split "`r?`n" | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    })
    $projected = @($lines | ForEach-Object {
        $event = $_ | ConvertFrom-Json -ErrorAction Stop
        if (@($event.PSObject.Properties.Name) -contains 'systemPrompt') {
            $event.systemPrompt = '<SYSTEM_PROMPT_OMITTED>'
        }
        if (@($event.PSObject.Properties.Name) -contains 'message' -and
            $null -ne $event.message) {
            $message = $event.message
            foreach ($property in @('providerPayload','contextSnapshot')) {
                if (@($message.PSObject.Properties.Name) -contains $property) {
                    $replacement = if ($property -eq 'providerPayload') {
                        '<PROVIDER_PAYLOAD_OMITTED>'
                    } else { '<CONTEXT_SNAPSHOT_OMITTED>' }
                    $message.$property = $replacement
                }
            }
            foreach ($block in @($message.content)) {
                if ($null -eq $block) { continue }
                $blockType = [string]$block.type
                if ($blockType -in @('thinking','reasoning','redacted_thinking') -and
                    @($block.PSObject.Properties.Name) -contains 'text') {
                    $block.text = '<PRIVATE_REASONING_OMITTED>'
                }
                foreach ($property in @(
                    'thinkingSignature','encrypted_content','encryptedContent','signature'
                )) {
                    if (@($block.PSObject.Properties.Name) -contains $property) {
                        $block.$property = '<PRIVATE_PROVIDER_STATE_OMITTED>'
                    }
                }
            }
        }
        $json = $event | ConvertTo-Json -Compress -Depth 100
        foreach ($placeholder in @(
            '<SYSTEM_PROMPT_OMITTED>',
            '<PROVIDER_PAYLOAD_OMITTED>',
            '<CONTEXT_SNAPSHOT_OMITTED>',
            '<PRIVATE_REASONING_OMITTED>',
            '<PRIVATE_PROVIDER_STATE_OMITTED>'
        )) {
            $escaped = '"' + $placeholder.Replace('<','\u003c').Replace('>','\u003e') + '"'
            $json = $json.Replace($escaped,('"' + $placeholder + '"'))
        }
        $json
    })
    if ($projected.Count -eq 0) { return '' }
    ($projected -join "`n") + "`n"
}

function Get-Phase00E3IExpectedIds {
    param([Parameter(Mandatory)][ValidateSet('A','B')][string]$Session)

    if ($Session -eq 'A') {
        return @(
            'e3i-project-1','e3i-project-2','e3i-project-3',
            'e3i-runtime-1','e3i-runtime-2','e3i-runtime-3'
        )
    }
    @('e3i-cli-1','e3i-cli-2','e3i-cli-3')
}

function Invoke-Phase00E3IEvidenceSession {
    param(
        [Parameter(Mandatory)][ValidateSet('A','B')][string]$Session,
        [Parameter(Mandatory)][string]$Model,
        [ValidateRange(1,999)][int]$Attempt = 1,
        [string]$OmpExecutable,
        [switch]$AllowOverwrite
    )

    $selectedOmpExecutable = if ([string]::IsNullOrWhiteSpace($OmpExecutable)) {
        (Get-Command omp -ErrorAction Stop).Source
    } else {
        [IO.Path]::GetFullPath($OmpExecutable)
    }
    $versionProbe = Invoke-Phase00E3ICapturedProcess -FilePath $selectedOmpExecutable `
        -Arguments @('--version') -WorkingDirectory $script:Phase00E3IRoot `
        -Environment @{} -TimeoutSeconds 30
    $versionOutput = $versionProbe.Stdout.Trim()
    if ($versionProbe.TimedOut -or $versionProbe.ExitCode -ne 0 -or
        $versionOutput -ne 'omp/17.2.10') {
        throw "Selected OMP runtime is not the required 17.2.10: $versionOutput"
    }

    $rawRoot = Join-Path $script:Phase00E3IRoot 'docs\evidence\phase-00\E3-I\raw'
    $baseStem = "session-$($Session.ToLowerInvariant())"
    $stem = if ($Attempt -eq 1) { $baseStem } else {
        "$baseStem-attempt-{0:D3}" -f $Attempt
    }
    $stdoutPath = Join-Path $rawRoot "$stem.stdout.jsonl"
    $stderrPath = Join-Path $rawRoot "$stem.stderr.txt"
    $runPath = Join-Path $rawRoot "$stem.run.json"
    $existing = @(@($stdoutPath,$stderrPath,$runPath) | Where-Object {
        Test-Path -LiteralPath $_
    })
    if (-not $AllowOverwrite -and $existing.Count -gt 0) {
        throw "Evidence already exists for $stem; preserve it and use a new attempt."
    }

    $disposableRoot = Assert-Phase00E3IDisposableRoot -Path (Join-Path `
        ([IO.Path]::GetTempPath()) `
        ("omp-phase00-e3i-{0}-{1}" -f $Session.ToLowerInvariant(),
            [guid]::NewGuid().ToString('N')))
    $liveHome = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.omp\agent'
    $liveBefore = Get-Phase00E3IDirectoryMetadataSnapshot -Path $liveHome
    $liveAfter = $null
    $fixture = $null
    $pinnedRuntime = $null
    $repositoryBefore = $null
    $repositoryAfter = $null
    $processResult = $null
    $sessionAnalysis = $null
    $parentEvents = @()
    $canaryMap = @{}
    $canaryArtifacts = @()
    $cleanupSucceeded = $false
    $cleanupError = $null
    $safeStdout = ''
    $safeStderr = ''
    try {
        $fixture = Initialize-Phase00E3IFixture -Root $disposableRoot
        $pinnedRuntime = Initialize-Phase00E3IPinnedRuntime -Root $disposableRoot `
            -SourceExecutable $selectedOmpExecutable
        $repositoryBefore = Get-Phase00E3IRepositorySnapshot -ProjectRoot $fixture.ProjectRoot
        $promptName = if ($Session -eq 'A') { 'session-a.md' } else { 'session-b.md' }
        $promptPath = Join-Path $fixture.ProjectRoot "prompts\$promptName"
        $prompt = Get-Content -Raw -LiteralPath $promptPath -Encoding UTF8
        $arguments = @(Get-Phase00E3IParentArguments -Session $Session `
            -FixtureRoot $fixture.ProjectRoot -SessionDirectory $fixture.SessionDirectory `
            -OverlayPath $fixture.OverlayPath -Model $Model -Prompt $prompt)
        $childEnvironment = Get-Phase00E3IProcessEnvironment `
            -Session $Session -Fixture $fixture -PinnedRuntime $pinnedRuntime
        $processResult = Invoke-Phase00E3ICapturedProcess -FilePath $pinnedRuntime.Executable `
            -Arguments $arguments -WorkingDirectory $fixture.ProjectRoot `
            -Environment $childEnvironment -TimeoutSeconds 720

        $safeStdout = Protect-Phase00EvidenceText -Text $processResult.Stdout `
            -RepositoryRoot $script:Phase00E3IRoot -DisposableRoot $disposableRoot
        $safeStderr = Protect-Phase00EvidenceText -Text $processResult.Stderr `
            -RepositoryRoot $script:Phase00E3IRoot -DisposableRoot $disposableRoot
        Write-Phase00E3IUtf8NoBom -Path $stdoutPath -Text $safeStdout
        Write-Phase00E3IUtf8NoBom -Path $stderrPath -Text $safeStderr

        try {
            $parentEvents = @(Read-Phase00JsonLines -Path $stdoutPath)
            $terminal = Get-Phase00TerminalModelFailure -Events $parentEvents
            $expectedIds = @(Get-Phase00E3IExpectedIds -Session $Session)
            $canaryMap = @{}
            if ($terminal.Found) {
                $availableIds = @($expectedIds | Where-Object {
                    @(Get-ChildItem -LiteralPath $fixture.SessionDirectory -Force -File `
                        -Recurse -Filter "$_.jsonl" -ErrorAction SilentlyContinue).Count -eq 1
                })
                if ($availableIds.Count -gt 0) {
                    $canaryArtifacts = @(Copy-Phase00E3ICanaryArtifacts `
                        -SessionDirectory $fixture.SessionDirectory `
                        -DestinationDirectory $rawRoot -Stem $stem `
                        -ExpectedIds $availableIds -RepositoryRoot $script:Phase00E3IRoot `
                        -DisposableRoot $disposableRoot)
                    foreach ($artifact in $canaryArtifacts) {
                        $canaryMap[$artifact.Id] = @($artifact.Events)
                    }
                }
            } else {
                $canaryArtifacts = @(Copy-Phase00E3ICanaryArtifacts `
                    -SessionDirectory $fixture.SessionDirectory `
                    -DestinationDirectory $rawRoot -Stem $stem `
                    -ExpectedIds $expectedIds -RepositoryRoot $script:Phase00E3IRoot `
                    -DisposableRoot $disposableRoot)
                foreach ($artifact in $canaryArtifacts) {
                    $canaryMap[$artifact.Id] = @($artifact.Events)
                }
            }
            $sessionAnalysis = if ($Session -eq 'A') {
                Test-Phase00E3ISessionA -ParentEvents $parentEvents `
                    -CanaryEvents $canaryMap -TimedOut $processResult.TimedOut
            } else {
                Test-Phase00E3ISessionB -ParentEvents $parentEvents `
                    -CanaryEvents $canaryMap -TimedOut $processResult.TimedOut
            }
        } catch {
            $sessionAnalysis = New-Phase00E3ICaptureFailureAnalysis `
                -ErrorMessage $_.Exception.Message -TimedOut $processResult.TimedOut
        }
        $repositoryAfter = Get-Phase00E3IRepositorySnapshot -ProjectRoot $fixture.ProjectRoot
    } finally {
        $liveAfter = Get-Phase00E3IDirectoryMetadataSnapshot -Path $liveHome
        if (Test-Path -LiteralPath $disposableRoot) {
            try {
                Remove-Phase00E3IDisposableDirectory -Path $disposableRoot
                $cleanupSucceeded = -not (Test-Path -LiteralPath $disposableRoot)
            } catch {
                $cleanupError = $_.Exception.Message
                $cleanupSucceeded = $false
            }
        } else {
            $cleanupSucceeded = $true
        }
    }

    if ($null -eq $processResult) {
        throw 'OMP parent process did not produce a captured result.'
    }
    if ($null -eq $repositoryBefore -or $null -eq $repositoryAfter) {
        throw 'Repository boundary snapshots are incomplete.'
    }
    $liveComparison = Compare-Phase00E3IDirectoryMetadataSnapshot `
        -Before $liveBefore -After $liveAfter
    $disposableIdentity = Split-Path -Leaf $disposableRoot
    $liveHomeMutationAttributable = @($liveComparison.ChangedPaths | Where-Object {
        [string]$_ -like "*$disposableIdentity*"
    }).Count -gt 0
    $liveComparison | Add-Member NoteProperty MutationAttributableToExperiment `
        $liveHomeMutationAttributable
    $liveComparison | Add-Member NoteProperty AttributionBasis $(if (
        $liveComparison.ChangedCount -eq 0) {
            'NO_CHANGE'
        } elseif ($liveHomeMutationAttributable) {
            'DISPOSABLE_ROOT_IDENTITY_IN_LIVE_PATH'
        } else {
            'NO_DISPOSABLE_IDENTITY_IN_CHANGED_PATHS'
        })
    $boundary = Compare-Phase00E3IRepositorySnapshot -Before $repositoryBefore `
        -After $repositoryAfter -LiveHomeUnchanged ($liveComparison.ChangedCount -eq 0) `
        -CleanupSucceeded $cleanupSucceeded
    $sessionAnalysis = Resolve-Phase00E3IRunAnalysis -SessionAnalysis $sessionAnalysis `
        -Boundary $boundary -LiveHomeMutationAttributable $liveHomeMutationAttributable `
        -CleanupError $cleanupError

    $environmentRecord = [ordered]@{
        PI_CODING_AGENT_DIR = '<DISPOSABLE_AGENT_DIR>'
        USERPROFILE = '<DISPOSABLE_USER_PROFILE>'
        OMP_PHASE00_E3IL_PARENT_CWD = '<DISPOSABLE_PROJECT>'
        OMP_PHASE00_E3IL_ENABLE_OVERRIDE = if ($Session -eq 'A') { '1' } else { '0' }
    }
    $commandRecord = @(
        '<DISPOSABLE_RUNTIME>/omp.exe','-p','--mode','json','--cwd','<DISPOSABLE_PROJECT>',
        '--session-dir','<DISPOSABLE_SESSION_DIR>'
    )
    if ($Session -eq 'B') { $commandRecord += @('--config','<DISPOSABLE_PROJECT>/overlay.yml') }
    $commandRecord += @(
        '--model',$Model,'--tools','task,bash','--approval-mode','yolo',
        '--max-time','12m','--no-extensions','--no-skills','--no-rules',
        '--no-lsp','--no-title',"<PROMPT:session-$($Session.ToLowerInvariant()).md>"
    )
    $runRecord = [ordered]@{
        schema_version = 2
        experiment = 'E3-I'
        session = $Session
        attempt = $Attempt
        selected = $false
        omp_version = $versionOutput
        omp_runtime = [ordered]@{
            selection = if ([string]::IsNullOrWhiteSpace($OmpExecutable)) {
                'PATH_DEFAULT'
            } else {
                'EXPLICIT_SOURCE'
            }
            launch_path = '<DISPOSABLE_RUNTIME>/omp.exe'
            source_sha256 = $pinnedRuntime.SourceSha256
            copied_sha256 = $pinnedRuntime.CopiedSha256
            nested_path_prepended = $true
        }
        model = $Model
        process_environment = $environmentRecord
        command = $commandRecord
        exit_code = $processResult.ExitCode
        timed_out = $processResult.TimedOut
        started_at = $processResult.StartedAt.ToString('o')
        completed_at = $processResult.CompletedAt.ToString('o')
        duration_ms = [long]($processResult.CompletedAt - $processResult.StartedAt).TotalMilliseconds
        parent_stdout_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $stdoutPath).Hash
        parent_stderr_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $stderrPath).Hash
        canary_artifacts = @($canaryArtifacts | ForEach-Object {
            [ordered]@{ id = $_.Id; sha256 = $_.Sha256; file = Split-Path -Leaf $_.Path }
        })
        boundary = $boundary
        live_home_metadata = $liveComparison
        cleanup_error = $cleanupError
        analysis = $sessionAnalysis
    } | ConvertTo-Json -Depth 16
    $safeRunRecord = Protect-Phase00EvidenceText -Text $runRecord `
        -RepositoryRoot $script:Phase00E3IRoot -DisposableRoot $disposableRoot
    Write-Phase00E3IUtf8NoBom -Path $runPath -Text $safeRunRecord

    [pscustomobject][ordered]@{
        Session = $Session
        Attempt = $Attempt
        Analysis = $sessionAnalysis
        Boundary = $boundary
        StdoutPath = $stdoutPath
        StderrPath = $stderrPath
        RunPath = $runPath
        CanaryArtifacts = @($canaryArtifacts)
        CleanupSucceeded = $cleanupSucceeded
        CleanupError = [string]$cleanupError
        LiveHomeMutationAttributable = $liveHomeMutationAttributable
        ParentEvents = @($parentEvents)
        CanaryEvents = $canaryMap
        TimedOut = [bool]$processResult.TimedOut
        RuntimeVersion = $pinnedRuntime.Version
        RuntimeSha256 = $pinnedRuntime.SourceSha256
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase00E3IEvidenceSession -Session $Session -Model $Model `
        -Attempt $Attempt -OmpExecutable $OmpExecutable -AllowOverwrite:$AllowOverwrite
}
