#Requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateRange(1,999)][int]$Attempt = 1,
    [string]$Model = 'omniroute/oc/mimo-v2.5-free',
    [string]$OmpExecutable,
    [switch]$AllowOverwrite
)

Set-StrictMode -Version 2.0

$script:Phase00E4CliAttempt = $Attempt
$script:Phase00E4CliModel = $Model
$script:Phase00E4CliOmpExecutable = $OmpExecutable
$script:Phase00E4CliAllowOverwrite = $AllowOverwrite

$script:Phase00E4Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:Phase00E4FixtureRoot = Join-Path $script:Phase00E4Root `
    'docs\evidence\phase-00\E4\fixture'
. (Join-Path $PSScriptRoot 'run-phase00-e3i.ps1')
. (Join-Path $PSScriptRoot 'lib\phase00-e4-evidence.ps1')

function Get-Phase00E4RepositorySnapshot {
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $root = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\','/')
    $prefix = $root + [IO.Path]::DirectorySeparatorChar
    $git = (Join-Path $root '.git').TrimEnd('\','/') +
        [IO.Path]::DirectorySeparatorChar
    $rows = @(Get-ChildItem -LiteralPath $root -Force -File -Recurse |
        Where-Object {
            -not $_.FullName.StartsWith($git, [StringComparison]::OrdinalIgnoreCase)
        } | ForEach-Object {
            [pscustomobject][ordered]@{
                Path = $_.FullName.Substring($prefix.Length).Replace('\','/')
                Sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
            }
        } | Sort-Object Path)
    $canonical = @($rows | ForEach-Object {
        "$($_.Path)`t$($_.Sha256)`n"
    }) -join ''
    $head = (& git -C $root rev-parse HEAD 2>&1).Trim()
    if ($LASTEXITCODE -ne 0) { throw "Cannot read E4 fixture HEAD: $head" }
    $status = @(& git -C $root status --porcelain=v1 --untracked-files=all 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Cannot read E4 fixture status: $($status -join ' ')" }
    [pscustomobject][ordered]@{
        Head = $head
        Status = @($status)
        ContentSha256 = Get-Phase00E3ISha256Text $canonical
        FileCount = $rows.Count
    }
}

function Initialize-Phase00E4Fixture {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][ValidateSet('RULE','AUTOLOAD')][string]$Arm
    )

    $verified = Assert-Phase00E3IDisposableRoot $Root
    foreach ($directory in @(
        $verified,
        (Join-Path $verified 'agent'),
        (Join-Path $verified 'project'),
        (Join-Path $verified 'sessions'),
        (Join-Path $verified 'user-profile')
    )) {
        [IO.Directory]::CreateDirectory($directory) | Out-Null
    }
    $source = Join-Path $script:Phase00E4FixtureRoot $Arm.ToLowerInvariant()
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        throw "E4 fixture arm is missing: $source"
    }
    Get-ChildItem -LiteralPath $source -Force |
        Copy-Item -Destination (Join-Path $verified 'project') -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $script:Phase00E4Root `
        'docs\evidence\phase-00\environment\runtime-models.yml') `
        -Destination (Join-Path $verified 'agent\models.yml') -Force

    $project = Join-Path $verified 'project'
    foreach ($arguments in @(
        @('init','--quiet'),
        @('config','user.name','Phase 00 E4 Probe'),
        @('config','user.email','phase00-e4.invalid@example.invalid'),
        @('config','core.autocrlf','false'),
        @('add','--all'),
        @('-c','commit.gpgSign=false','-c','core.hooksPath=NUL','commit','--quiet',
            '-m','phase00 E4 disposable baseline')
    )) {
        $output = @(& git -C $project @arguments 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "E4 fixture Git initialization failed: $($output -join ' ')"
        }
    }
    [pscustomobject][ordered]@{
        Root = [IO.Path]::GetFullPath($verified)
        ProjectRoot = [IO.Path]::GetFullPath($project)
        AgentDirectory = [IO.Path]::GetFullPath((Join-Path $verified 'agent'))
        SessionDirectory = [IO.Path]::GetFullPath((Join-Path $verified 'sessions'))
        UserProfileDirectory = [IO.Path]::GetFullPath((Join-Path $verified 'user-profile'))
        PromptPath = [IO.Path]::GetFullPath((Join-Path $project 'prompt.md'))
    }
}

function Invoke-Phase00E4Arm {
    param(
        [Parameter(Mandatory)][ValidateSet('RULE','AUTOLOAD')][string]$Arm,
        [Parameter(Mandatory)][ValidateRange(1,999)][int]$Attempt,
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$OmpExecutable,
        [switch]$AllowOverwrite
    )

    $rawRoot = Join-Path $script:Phase00E4Root 'docs\evidence\phase-00\E4\raw'
    [IO.Directory]::CreateDirectory($rawRoot) | Out-Null
    $lower = $Arm.ToLowerInvariant()
    $stem = "$lower-attempt-{0:D3}" -f $Attempt
    $paths = [ordered]@{
        ParentStdout = Join-Path $rawRoot "$stem.parent.stdout.jsonl"
        ParentStderr = Join-Path $rawRoot "$stem.parent.stderr.txt"
        Child = Join-Path $rawRoot "$stem.child.jsonl"
        Projection = Join-Path $rawRoot "$stem.projection.json"
        Run = Join-Path $rawRoot "$stem.run.json"
    }
    if (-not $AllowOverwrite) {
        $collisions = @($paths.Values | Where-Object { Test-Path -LiteralPath $_ })
        if ($collisions.Count -gt 0) {
            throw "E4 evidence already exists for $stem; use a new attempt."
        }
    }

    $disposable = Assert-Phase00E3IDisposableRoot (Join-Path `
        ([IO.Path]::GetTempPath()) `
        ("omp-phase00-e4-$lower-{0}" -f [guid]::NewGuid().ToString('N')))
    $liveHome = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.omp\agent'
    $liveBefore = Get-Phase00E3IDirectoryMetadataSnapshot $liveHome
    $fixture = $null
    $runtime = $null
    $before = $null
    $after = $null
    $process = $null
    $analysis = New-Phase00E4Result INVALID_RUN @('E4_NOT_INVOKED')
    $projection = $null
    $cleanupSucceeded = $false
    $cleanupError = $null
    $startedAt = [DateTimeOffset]::Now
    try {
        $fixture = Initialize-Phase00E4Fixture $disposable $Arm
        $runtime = Initialize-Phase00E3IPinnedRuntime -Root $disposable `
            -SourceExecutable $OmpExecutable
        $before = Get-Phase00E4RepositorySnapshot $fixture.ProjectRoot
        $prompt = [IO.File]::ReadAllText($fixture.PromptPath)
        $arguments = @(
            '-p','--mode','json','--cwd',$fixture.ProjectRoot,
            '--session-dir',$fixture.SessionDirectory,
            '--model',$Model,'--tools','task','--approval-mode','yolo',
            '--max-time','8m','--no-extensions','--no-lsp','--no-title',$prompt
        )
        $environment = @{
            PI_CODING_AGENT_DIR = $fixture.AgentDirectory
            USERPROFILE = $fixture.UserProfileDirectory
            PATH = $runtime.Directory + [IO.Path]::PathSeparator +
                [Environment]::GetEnvironmentVariable('PATH','Process')
        }
        $process = Invoke-Phase00E3ICapturedProcess -FilePath $runtime.Executable `
            -Arguments $arguments -WorkingDirectory $fixture.ProjectRoot `
            -Environment $environment -TimeoutSeconds 540

        $safeParent = Protect-Phase00EvidenceText $process.Stdout `
            $script:Phase00E4Root $disposable
        $safeParent = ConvertTo-Phase00E3ICanaryProjection $safeParent
        Write-Phase00E3IUtf8NoBom $paths.ParentStdout $safeParent
        Write-Phase00E3IUtf8NoBom $paths.ParentStderr `
            (Protect-Phase00EvidenceText $process.Stderr $script:Phase00E4Root $disposable)

        $childId = "e4-$lower"
        $childMatches = @(Get-ChildItem -LiteralPath $fixture.SessionDirectory -Force `
            -File -Recurse -Filter "$childId.jsonl" -ErrorAction SilentlyContinue)
        if ($childMatches.Count -ne 1) {
            $analysis = New-Phase00E4Result INVALID_RUN `
                @('E4_CHILD_PROVENANCE_MISSING') @{
                    ChildTranscriptCount = $childMatches.Count
                }
        } else {
            $childRaw = [IO.File]::ReadAllText($childMatches[0].FullName)
            $childEvents = @($childRaw -split "`r?`n" | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            } | ForEach-Object { $_ | ConvertFrom-Json -ErrorAction Stop })
            $analysis = Test-Phase00E4Arm -Arm $Arm -Events $childEvents
            $initializer = @($childEvents | Where-Object type -eq 'session_init')[0]
            $systemPrompt = [string]$initializer.systemPrompt
            $safeChild = Protect-Phase00EvidenceText $childRaw `
                $script:Phase00E4Root $disposable
            $safeChild = ConvertTo-Phase00E3ICanaryProjection $safeChild
            Write-Phase00E3IUtf8NoBom $paths.Child $safeChild
            $projection = [ordered]@{
                schema_version = 1
                experiment = 'E4'
                arm = $Arm
                attempt = $Attempt
                status = $analysis.Status
                reasons = @($analysis.Reasons)
                propagation_class = Get-Phase00PropertyValue $analysis 'PropagationClass'
                system_prompt_sha256 = Get-Phase00E3ISha256Text $systemPrompt
                system_prompt_sentinel_count = Get-Phase00PropertyValue $analysis 'SystemPromptSentinelCount'
                system_prompt_marker_count = Get-Phase00PropertyValue $analysis 'SystemPromptMarkerCount'
                autoload_message_count = Get-Phase00PropertyValue $analysis 'AutoloadMessageCount'
                behavior_phrase_count = Get-Phase00PropertyValue $analysis 'BehaviorPhraseCount'
                tools = @(Get-Phase00PropertyValue $analysis 'Tools')
                yield_call_count = Get-Phase00PropertyValue $analysis 'YieldCallCount'
                read_call_count = Get-Phase00PropertyValue $analysis 'ReadCallCount'
                forbidden_tool_call_count = Get-Phase00PropertyValue $analysis 'ForbiddenToolCallCount'
                input_tokens = Get-Phase00PropertyValue $analysis 'InputTokens'
                total_tokens = Get-Phase00PropertyValue $analysis 'TotalTokens'
                sentinel_excerpt = if ($Arm -eq 'RULE') {
                    $script:Phase00E4Sentinel
                } else { $null }
                child_transcript = [ordered]@{
                    path = "docs/evidence/phase-00/E4/raw/$stem.child.jsonl"
                    sha256 = (Get-FileHash -Algorithm SHA256 $paths.Child).Hash
                }
            }
            Write-Phase00E3IUtf8NoBom $paths.Projection `
                (($projection | ConvertTo-Json -Depth 12) + "`n")
        }
        $after = Get-Phase00E4RepositorySnapshot $fixture.ProjectRoot
    } catch {
        $analysis = New-Phase00E4Result INVALID_RUN @('E4_HARNESS_FAILURE') @{
            Error = $_.Exception.Message
        }
    } finally {
        $liveAfter = Get-Phase00E3IDirectoryMetadataSnapshot $liveHome
        if (Test-Path -LiteralPath $disposable) {
            try {
                Remove-Phase00E3IDisposableDirectory $disposable
                $cleanupSucceeded = -not (Test-Path -LiteralPath $disposable)
            } catch {
                $cleanupError = $_.Exception.Message
            }
        } else { $cleanupSucceeded = $true }
    }
    $completedAt = [DateTimeOffset]::Now
    $liveComparison = Compare-Phase00E3IDirectoryMetadataSnapshot $liveBefore $liveAfter
    $repoUnchanged = $null -ne $before -and $null -ne $after -and
        $before.Head -ceq $after.Head -and
        ($before.Status -join "`n") -ceq ($after.Status -join "`n") -and
        $before.ContentSha256 -ceq $after.ContentSha256
    $eligible = $null -ne $process -and $process.ExitCode -eq 0 -and
        -not $process.TimedOut -and $analysis.Status -eq 'PASS' -and
        $repoUnchanged -and $liveComparison.ChangedCount -eq 0 -and $cleanupSucceeded
    $run = [ordered]@{
        schema_version = 1
        experiment = 'E4'
        arm = $Arm
        attempt = $Attempt
        selected = $eligible
        status = if ($eligible) { 'PASS' } else { $analysis.Status }
        model = $Model
        runtime = [ordered]@{
            version = 'omp/17.2.10'
            sha256 = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
        }
        started_at = $startedAt.ToString('o')
        completed_at = $completedAt.ToString('o')
        duration_ms = [long]($completedAt - $startedAt).TotalMilliseconds
        exit_code = if ($null -eq $process) { $null } else { $process.ExitCode }
        timed_out = if ($null -eq $process) { $false } else { $process.TimedOut }
        analysis = $analysis
        repository_unchanged = $repoUnchanged
        live_home_changed_count = $liveComparison.ChangedCount
        cleanup_succeeded = $cleanupSucceeded
        cleanup_error = $cleanupError
        artifacts = [ordered]@{
            parent_stdout = if (Test-Path $paths.ParentStdout) {
                (Get-FileHash $paths.ParentStdout -Algorithm SHA256).Hash
            } else { $null }
            parent_stderr = if (Test-Path $paths.ParentStderr) {
                (Get-FileHash $paths.ParentStderr -Algorithm SHA256).Hash
            } else { $null }
            child = if (Test-Path $paths.Child) {
                (Get-FileHash $paths.Child -Algorithm SHA256).Hash
            } else { $null }
            projection = if (Test-Path $paths.Projection) {
                (Get-FileHash $paths.Projection -Algorithm SHA256).Hash
            } else { $null }
        }
    }
    Write-Phase00E3IUtf8NoBom $paths.Run (($run | ConvertTo-Json -Depth 20) + "`n")
    [pscustomobject][ordered]@{
        Status = $run.status
        Selected = $eligible
        Arm = $Arm
        Attempt = $Attempt
        RunPath = $paths.Run
        ProjectionPath = $paths.Projection
    }
}

function Invoke-Phase00E4Experiment {
    param(
        [Parameter(Mandatory)][ValidateRange(1,999)][int]$Attempt,
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$OmpExecutable,
        [switch]$AllowOverwrite
    )

    $rule = Invoke-Phase00E4Arm RULE $Attempt $Model $OmpExecutable `
        -AllowOverwrite:$AllowOverwrite
    if (-not $rule.Selected) {
        return [pscustomobject][ordered]@{
            Status = $rule.Status; Rule = $rule; Autoload = $null
        }
    }
    $autoload = Invoke-Phase00E4Arm AUTOLOAD $Attempt $Model $OmpExecutable `
        -AllowOverwrite:$AllowOverwrite
    [pscustomobject][ordered]@{
        Status = if ($rule.Selected -and $autoload.Selected) { 'PASS' } else {
            $autoload.Status
        }
        Rule = $rule
        Autoload = $autoload
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if ([string]::IsNullOrWhiteSpace($script:Phase00E4CliOmpExecutable)) {
        throw 'Direct E4 execution requires -OmpExecutable.'
    }
    Invoke-Phase00E4Experiment $script:Phase00E4CliAttempt `
        $script:Phase00E4CliModel $script:Phase00E4CliOmpExecutable `
        -AllowOverwrite:$script:Phase00E4CliAllowOverwrite
}
