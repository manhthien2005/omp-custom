#Requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateRange(1,999)][int]$Attempt = 1,
    [string]$Model = 'omniroute/oc/mimo-v2.5-free',
    [string]$OmpExecutable,
    [switch]$AllowOverwrite
)

Set-StrictMode -Version 2.0

$script:Phase00E5CliAttempt = $Attempt
$script:Phase00E5CliModel = $Model
$script:Phase00E5CliOmpExecutable = $OmpExecutable
$script:Phase00E5CliAllowOverwrite = $AllowOverwrite

$script:Phase00E5Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:Phase00E5FixtureRoot = Join-Path $script:Phase00E5Root `
    'docs\evidence\phase-00\E5\fixture\project'
. (Join-Path $PSScriptRoot 'run-phase00-e3i.ps1')
. (Join-Path $PSScriptRoot 'lib\phase00-e5-evidence.ps1')

function Get-Phase00E5Matrix {
    @(
        [pscustomobject][ordered]@{ CaseId='E5-A'; Role='allowlisted'; Agent='e5-allowlisted'; Stem='e5-a'; TaskEnableLsp=$false; ParentEnableLsp=$true; LspEnabled=$true; ConfigureServer=$false; ExpectCall=$false; File='probe.ts' },
        [pscustomobject][ordered]@{ CaseId='E5-B'; Role='explorer'; Agent='e5-explorer'; Stem='e5-b-explorer'; TaskEnableLsp=$true; ParentEnableLsp=$true; LspEnabled=$true; ConfigureServer=$true; ExpectCall=$true; File='probe.ts' },
        [pscustomobject][ordered]@{ CaseId='E5-B'; Role='implementer'; Agent='e5-implementer'; Stem='e5-b-implementer'; TaskEnableLsp=$true; ParentEnableLsp=$true; LspEnabled=$true; ConfigureServer=$true; ExpectCall=$true; File='probe.ts' },
        [pscustomobject][ordered]@{ CaseId='E5-B'; Role='reviewer'; Agent='e5-reviewer'; Stem='e5-b-reviewer'; TaskEnableLsp=$true; ParentEnableLsp=$true; LspEnabled=$true; ConfigureServer=$true; ExpectCall=$true; File='probe.ts' },
        [pscustomobject][ordered]@{ CaseId='E5-B'; Role='verifier'; Agent='e5-verifier'; Stem='e5-b-verifier'; TaskEnableLsp=$true; ParentEnableLsp=$true; LspEnabled=$true; ConfigureServer=$true; ExpectCall=$false; File='probe.ts' },
        [pscustomobject][ordered]@{ CaseId='E5-C'; Role='allowlisted'; Agent='e5-allowlisted'; Stem='e5-c'; TaskEnableLsp=$true; ParentEnableLsp=$false; LspEnabled=$true; ConfigureServer=$false; ExpectCall=$false; File='probe.ts' },
        [pscustomobject][ordered]@{ CaseId='E5-D'; Role='no-lsp'; Agent='e5-no-lsp'; Stem='e5-d'; TaskEnableLsp=$true; ParentEnableLsp=$true; LspEnabled=$true; ConfigureServer=$false; ExpectCall=$false; File='probe.ts' },
        [pscustomobject][ordered]@{ CaseId='E5-E'; Role='allowlisted'; Agent='e5-allowlisted'; Stem='e5-e'; TaskEnableLsp=$true; ParentEnableLsp=$true; LspEnabled=$true; ConfigureServer=$false; ExpectCall=$true; File='probe.e5none' },
        [pscustomobject][ordered]@{ CaseId='E5-F'; Role='allowlisted'; Agent='e5-allowlisted'; Stem='e5-f'; TaskEnableLsp=$true; ParentEnableLsp=$true; LspEnabled=$false; ConfigureServer=$false; ExpectCall=$false; File='probe.ts' }
    )
}

function Get-Phase00E5RepositorySnapshot {
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
    if ($LASTEXITCODE -ne 0) { throw "Cannot read E5 fixture HEAD: $head" }
    $status = @(& git -C $root status --porcelain=v1 --untracked-files=all 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Cannot read E5 fixture status: $($status -join ' ')" }
    [pscustomobject][ordered]@{
        Head = $head
        Status = @($status)
        ContentSha256 = Get-Phase00E3ISha256Text $canonical
        FileCount = $rows.Count
    }
}

function Get-Phase00E5ConfigText {
    param([Parameter(Mandatory)][object]$Spec)

    $taskValue = ([string]$Spec.TaskEnableLsp).ToLowerInvariant()
    $lspValue = ([string]$Spec.LspEnabled).ToLowerInvariant()
    @"
plan:
  defaultOnStartup: false
async:
  enabled: false
task:
  batch: false
  enableEffort: false
  enableLsp: $taskValue
  maxConcurrency: 1
  maxRecursionDepth: 2
  maxRuntimeMs: 180000
  isolation:
    mode: none
    apply: false
lsp:
  enabled: $lspValue
  shared: false
  lazy: true
"@
}

function Initialize-Phase00E5Fixture {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][object]$Spec,
        [Parameter(Mandatory)][string]$NodeExecutable
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
    Get-ChildItem -LiteralPath $script:Phase00E5FixtureRoot -Force |
        Copy-Item -Destination (Join-Path $verified 'project') -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $script:Phase00E5Root `
        'docs\evidence\phase-00\environment\runtime-models.yml') `
        -Destination (Join-Path $verified 'agent\models.yml') -Force

    $project = Join-Path $verified 'project'
    Write-Phase00E3IUtf8NoBom (Join-Path $project '.omp\config.yml') `
        (Get-Phase00E5ConfigText $Spec)
    if ($Spec.ConfigureServer) {
        $serverConfig = [ordered]@{
            servers = [ordered]@{
                'phase00-fake' = [ordered]@{
                    command = [IO.Path]::GetFullPath($NodeExecutable)
                    args = @([IO.Path]::GetFullPath((Join-Path $project `
                        'fake-lsp-server.cjs')))
                    fileTypes = @('.ts')
                    languageId = 'typescript'
                    rootMarkers = @('.git')
                }
            }
        }
        Write-Phase00E3IUtf8NoBom (Join-Path $project 'lsp.json') `
            (($serverConfig | ConvertTo-Json -Depth 12) + "`n")
    }

    foreach ($arguments in @(
        @('init','--quiet'),
        @('config','user.name','Phase 00 E5 Probe'),
        @('config','user.email','phase00-e5.invalid@example.invalid'),
        @('config','core.autocrlf','false'),
        @('add','--all'),
        @('-c','commit.gpgSign=false','-c','core.hooksPath=NUL','commit','--quiet',
            '-m','phase00 E5 disposable baseline')
    )) {
        $output = @(& git -C $project @arguments 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "E5 fixture Git initialization failed: $($output -join ' ')"
        }
    }
    [pscustomobject][ordered]@{
        Root = [IO.Path]::GetFullPath($verified)
        ProjectRoot = [IO.Path]::GetFullPath($project)
        AgentDirectory = [IO.Path]::GetFullPath((Join-Path $verified 'agent'))
        SessionDirectory = [IO.Path]::GetFullPath((Join-Path $verified 'sessions'))
        UserProfileDirectory = [IO.Path]::GetFullPath((Join-Path $verified 'user-profile'))
    }
}

function Get-Phase00E5ParentPrompt {
    param([Parameter(Mandatory)][object]$Spec)

    $expectation = Get-Phase00E5Expectation $Spec.CaseId $Spec.Role
    $childTask = if ($Spec.ExpectCall) {
        "The lsp tool must be present. Call lsp exactly once with action=references, file=$($Spec.File), line=1, symbol=alpha, timeout=20. Observe the exact tool result. Then terminal-yield result.data.completion exactly $($expectation.Marker)."
    } else {
        "The lsp tool must be absent in this fixture. Do not invent or attempt an unavailable lsp call. Terminal-yield result.data.completion exactly $($expectation.Marker)."
    }
    $taskObject = [ordered]@{
        name = $Spec.Stem
        agent = $Spec.Agent
        task = $childTask
        isolated = $false
    }
    $json = $taskObject | ConvertTo-Json -Compress
    "Call the task tool exactly once with this object:`n$json`n`nAfter the blocking task returns, output exactly $($Spec.Stem.ToUpperInvariant().Replace('-','_'))_PARENT_DONE and stop."
}

function Invoke-Phase00E5Case {
    param(
        [Parameter(Mandatory)][object]$Spec,
        [Parameter(Mandatory)][ValidateRange(1,999)][int]$Attempt,
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$OmpExecutable,
        [Parameter(Mandatory)][string]$NodeExecutable,
        [switch]$AllowOverwrite
    )

    $rawRoot = Join-Path $script:Phase00E5Root 'docs\evidence\phase-00\E5\raw'
    [IO.Directory]::CreateDirectory($rawRoot) | Out-Null
    $attemptStem = "$($Spec.Stem)-attempt-{0:D3}" -f $Attempt
    $paths = [ordered]@{
        ParentStdout = Join-Path $rawRoot "$attemptStem.parent.stdout.jsonl"
        ParentStderr = Join-Path $rawRoot "$attemptStem.parent.stderr.txt"
        Child = Join-Path $rawRoot "$attemptStem.child.jsonl"
        Projection = Join-Path $rawRoot "$attemptStem.projection.json"
        Run = Join-Path $rawRoot "$attemptStem.run.json"
    }
    if (-not $AllowOverwrite) {
        $collisions = @($paths.Values | Where-Object { Test-Path -LiteralPath $_ })
        if ($collisions.Count -gt 0) {
            throw "E5 evidence already exists for $attemptStem; use a new attempt."
        }
    }

    $disposable = Assert-Phase00E3IDisposableRoot (Join-Path `
        ([IO.Path]::GetTempPath()) `
        ("omp-phase00-$($Spec.Stem)-{0}" -f [guid]::NewGuid().ToString('N')))
    $liveHome = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.omp\agent'
    $liveBefore = Get-Phase00E3IDirectoryMetadataSnapshot $liveHome
    $fixture = $null
    $runtime = $null
    $before = $null
    $after = $null
    $process = $null
    $analysis = New-Phase00E5Result INVALID_RUN @('E5_NOT_INVOKED')
    $cleanupSucceeded = $false
    $cleanupError = $null
    $startedAt = [DateTimeOffset]::Now
    try {
        $fixture = Initialize-Phase00E5Fixture $disposable $Spec $NodeExecutable
        $runtime = Initialize-Phase00E3IPinnedRuntime -Root $disposable `
            -SourceExecutable $OmpExecutable
        $before = Get-Phase00E5RepositorySnapshot $fixture.ProjectRoot
        $arguments = @(
            '-p','--mode','json','--cwd',$fixture.ProjectRoot,
            '--session-dir',$fixture.SessionDirectory,
            '--model',$Model,'--tools','task','--approval-mode','yolo',
            '--max-time','8m','--no-extensions','--no-title'
        )
        if (-not $Spec.ParentEnableLsp) { $arguments += '--no-lsp' }
        $arguments += Get-Phase00E5ParentPrompt $Spec
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
            $script:Phase00E5Root $disposable
        $safeParent = ConvertTo-Phase00E3ICanaryProjection $safeParent
        Write-Phase00E3IUtf8NoBom $paths.ParentStdout $safeParent
        Write-Phase00E3IUtf8NoBom $paths.ParentStderr `
            (Protect-Phase00EvidenceText $process.Stderr `
                $script:Phase00E5Root $disposable)

        $childMatches = @(Get-ChildItem -LiteralPath $fixture.SessionDirectory -Force `
            -File -Recurse -Filter "$($Spec.Stem).jsonl" -ErrorAction SilentlyContinue)
        if ($childMatches.Count -ne 1) {
            $analysis = New-Phase00E5Result INVALID_RUN `
                @('E5_CHILD_PROVENANCE_MISSING') @{
                    ChildTranscriptCount = $childMatches.Count
                }
        } else {
            $childRaw = [IO.File]::ReadAllText($childMatches[0].FullName)
            $childEvents = @($childRaw -split "`r?`n" | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            } | ForEach-Object { $_ | ConvertFrom-Json -ErrorAction Stop })
            $analysis = Test-Phase00E5Case -CaseId $Spec.CaseId `
                -Role $Spec.Role -Events $childEvents
            $safeChild = Protect-Phase00EvidenceText $childRaw `
                $script:Phase00E5Root $disposable
            $safeChild = ConvertTo-Phase00E3ICanaryProjection $safeChild
            Write-Phase00E3IUtf8NoBom $paths.Child $safeChild
            $projection = [ordered]@{
                schema_version = 1
                experiment = $Spec.CaseId
                role = $Spec.Role
                attempt = $Attempt
                status = $analysis.Status
                reasons = @($analysis.Reasons)
                tools = @(Get-Phase00PropertyValue $analysis 'Tools')
                lsp_present = Get-Phase00PropertyValue $analysis 'LspPresent'
                lsp_call_count = Get-Phase00PropertyValue $analysis 'LspCallCount'
                lsp_result_count = Get-Phase00PropertyValue $analysis 'LspResultCount'
                lsp_result_success = Get-Phase00PropertyValue $analysis 'LspResultSuccess'
                lsp_result_text = Get-Phase00PropertyValue $analysis 'LspResultText'
                lsp_server_name = Get-Phase00PropertyValue $analysis 'LspServerName'
                yield_call_count = Get-Phase00PropertyValue $analysis 'YieldCallCount'
                marker = Get-Phase00PropertyValue $analysis 'Marker'
                marker_count = Get-Phase00PropertyValue $analysis 'MarkerCount'
                cause = Get-Phase00PropertyValue $analysis 'Cause'
                remediation = Get-Phase00PropertyValue $analysis 'Remediation'
                first_turn_prompt_tokens = Get-Phase00PropertyValue `
                    $analysis 'FirstTurnPromptTokens'
                final_total_tokens = Get-Phase00PropertyValue `
                    $analysis 'FinalTotalTokens'
                fixture = [ordered]@{
                    task_enable_lsp = $Spec.TaskEnableLsp
                    parent_session_lsp = $Spec.ParentEnableLsp
                    lsp_enabled = $Spec.LspEnabled
                    agent_allowlist_includes_lsp = $Spec.Agent -ne 'e5-no-lsp' -and `
                        $Spec.Agent -ne 'e5-verifier'
                    language_server_configured = $Spec.ConfigureServer
                }
                child_transcript = [ordered]@{
                    path = "docs/evidence/phase-00/E5/raw/$attemptStem.child.jsonl"
                    sha256 = (Get-FileHash -Algorithm SHA256 $paths.Child).Hash
                }
            }
            Write-Phase00E3IUtf8NoBom $paths.Projection `
                (($projection | ConvertTo-Json -Depth 20) + "`n")
        }
        $after = Get-Phase00E5RepositorySnapshot $fixture.ProjectRoot
    } catch {
        $analysis = New-Phase00E5Result INVALID_RUN @('E5_HARNESS_FAILURE') @{
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
        experiment = $Spec.CaseId
        role = $Spec.Role
        attempt = $Attempt
        selected = $eligible
        status = if ($eligible) { 'PASS' } else { $analysis.Status }
        model = $Model
        runtime = [ordered]@{
            version = 'omp/17.2.10'
            sha256 = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
            source_commit = '3a8591a8af5b6d200088d12ca75a5517cb064fa8'
        }
        node = [ordered]@{
            version = (& $NodeExecutable --version 2>&1 | Select-Object -First 1)
            sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $NodeExecutable).Hash
            used_as_language_server = [bool]$Spec.ConfigureServer
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
    Write-Phase00E3IUtf8NoBom $paths.Run (($run | ConvertTo-Json -Depth 24) + "`n")
    [pscustomobject][ordered]@{
        CaseId = $Spec.CaseId
        Role = $Spec.Role
        Status = $run.status
        Selected = $eligible
        RunPath = $paths.Run
        ProjectionPath = $paths.Projection
    }
}

function Invoke-Phase00E5Experiment {
    param(
        [Parameter(Mandatory)][ValidateRange(1,999)][int]$Attempt,
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$OmpExecutable,
        [switch]$AllowOverwrite
    )

    $nodeCommand = Get-Command node.exe -ErrorAction Stop
    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($spec in @(Get-Phase00E5Matrix)) {
        $result = Invoke-Phase00E5Case -Spec $spec -Attempt $Attempt `
            -Model $Model -OmpExecutable $OmpExecutable `
            -NodeExecutable $nodeCommand.Source -AllowOverwrite:$AllowOverwrite
        [void]$results.Add($result)
    }
    @($results)
}

if ($MyInvocation.InvocationName -ne '.') {
    if ([string]::IsNullOrWhiteSpace($script:Phase00E5CliOmpExecutable)) {
        throw 'Direct E5 execution requires -OmpExecutable.'
    }
    Invoke-Phase00E5Experiment $script:Phase00E5CliAttempt `
        $script:Phase00E5CliModel $script:Phase00E5CliOmpExecutable `
        -AllowOverwrite:$script:Phase00E5CliAllowOverwrite |
        Format-Table CaseId,Role,Status,Selected -AutoSize
}
