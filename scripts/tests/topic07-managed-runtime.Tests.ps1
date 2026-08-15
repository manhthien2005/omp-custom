#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$installer = Join-Path $repositoryRoot 'scripts\install-template.ps1'
$uninstaller = Join-Path $repositoryRoot 'scripts\uninstall-template.ps1'
$probe = Join-Path $repositoryRoot 'scripts\tests\fixtures\topic07-omp-runtime-probe.mjs'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-topic07-runtime-'
$roots = [Collections.Generic.List[string]]::new()
$script:Assertions = 0

function Assert-Topic07Runtime {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function New-Topic07RuntimeRoot {
    $path = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $path -Force)
    [void]$roots.Add([IO.Path]::GetFullPath($path))
    return $path
}

function Invoke-Topic07Install {
    param([Parameter(Mandatory)][string]$Project, [string]$OmpPath)
    $arguments = @(
        '-NoProfile', '-File', $installer, '-Target', 'project', '-ProjectDir', $Project,
        '-Components', 'agents,workflows,skills,state,agents-md,rules-md,config,agent-boundary',
        '-DryRun:$false'
    )
    if ($OmpPath) { $arguments += @('-OmpPath', $OmpPath) }
    $output = @(& pwsh @arguments 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output -join [Environment]::NewLine }
}

function Invoke-Topic07Launcher {
    param(
        [Parameter(Mandatory)][string]$Launcher,
        [Parameter(Mandatory)][string[]]$Arguments,
        [string]$WorkingDirectory = ''
    )
    $pushed = $false
    try {
        if ($WorkingDirectory) {
            Push-Location -LiteralPath $WorkingDirectory
            $pushed = $true
        }
        $output = @(& pwsh -NoProfile -File $Launcher @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        if ($pushed) { Pop-Location }
    }
    return [pscustomobject]@{ ExitCode = $exitCode; Output = $output -join [Environment]::NewLine; Lines = $output }
}

function Get-Topic07FileBytes {
    param([Parameter(Mandatory)][string]$LiteralPath)
    return [IO.File]::ReadAllBytes([IO.Path]::GetFullPath($LiteralPath))
}

try {
    $templateRoot = Join-Path $repositoryRoot 'template'
    $manifestPath = Join-Path $templateRoot '.omp\contracts\component-manifest.json'
    $overlayPath = Join-Path $templateRoot '.omp\contracts\managed-runtime.yml'
    $manifest = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8 | ConvertFrom-Json
    $expectedOwned = @(
        '.omp/bin/omp-managed.ps1',
        '.omp/contracts/agent-boundary-cli.mjs',
        '.omp/contracts/agent-boundary-core.mjs',
        '.omp/contracts/agent-boundary-schema.mjs',
        '.omp/contracts/behavior-core-schema.mjs',
        '.omp/contracts/behavior-core.mjs',
        '.omp/contracts/behavior-manifest.json',
        '.omp/contracts/context-continuity-core.mjs',
        '.omp/contracts/context-continuity-schema.mjs',
        '.omp/contracts/managed-runtime.yml',
        '.omp/contracts/managed-state-client.mjs',
        '.omp/extensions/agent-task-boundary.js',
        '.omp/extensions/context-continuity.js'
    ) | Sort-Object
    $actualOwned = @($manifest.files | Where-Object { [bool]$_.owned } | ForEach-Object { [string]$_.path } | Sort-Object)
    Assert-Topic07Runtime (
        [int]$manifest.schema_version -eq 2 -and
        [string]$manifest.record_type -ceq 'agent_boundary_component_manifest' -and
        [string]$manifest.component -ceq 'agent-boundary' -and
        [string]$manifest.component_version -ceq '2.1.0'
    ) 'The shared component identity is not the exact v2 contract.'
    Assert-Topic07Runtime (
        @($manifest.files).Count -eq 20 -and $actualOwned.Count -eq 13 -and
        (($actualOwned -join "`n") -ceq ($expectedOwned -join "`n"))
    ) 'The v2 component does not own the exact ten managed files.'
    Assert-Topic07Runtime (
        (@($manifest.supported_omp_versions) -join ',') -ceq '17.2.10,17.2.12' -and
        (@($manifest.generated_target_files) -join ',') -ceq '.omp/contracts/runtime.json,.omp/contracts/install-record.json'
    ) 'Supported OMP versions or generated record paths drifted.'
    $dependencyNames = @($manifest.dependencies | ForEach-Object { [string]$_.component })
    Assert-Topic07Runtime (($dependencyNames -join ',') -ceq 'agents,skills,state,config') `
        'The v2 component dependency set drifted.'
    Assert-Topic07Runtime (
        -not (@($manifest.files.path) -match '(?i)(?:^|/)(?:agent-tasks|sessions|artifacts|credentials)(?:/|$)')
    ) 'The component claims ownership over operational or private runtime data.'
    Assert-Topic07Runtime (
        [string]$manifest.continuity_policy.command -ceq 'safe-compact' -and
        [bool]$manifest.continuity_policy.automatic_semantic_compaction -eq $false -and
        [bool]$manifest.continuity_policy.context_promotion -eq $false -and
        [int]$manifest.continuity_policy.keep_recent_tokens -eq 20000 -and
        [int]$manifest.continuity_policy.nonce_ttl_ms -eq 120000 -and
        [int]$manifest.continuity_policy.max_kernel_bytes -eq 16384 -and
        [int]$manifest.continuity_policy.max_recovery_artifact_bytes -eq 262144 -and
        [int]$manifest.continuity_policy.pressure_default_reserve_tokens -eq 16384
    ) 'The closed continuity policy drifted.'
    foreach ($row in $manifest.files) {
        $source = Join-Path $templateRoot ([string]$row.path).Replace('/', [IO.Path]::DirectorySeparatorChar)
        Assert-Topic07Runtime (
            (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant() -ceq [string]$row.sha256
        ) "Manifest hash drifted for $($row.path)."
    }
    $exactOverlay = "task:`n  softRequestBudget: 200`ncontextPromotion:`n  enabled: false`ncompaction:`n  enabled: false`n  strategy: off`n  midTurnEnabled: false`n  thresholdPercent: -1`n  thresholdTokens: -1`n  keepRecentTokens: 20000`n  autoContinue: false`n  idleEnabled: false`n  remoteEnabled: false`n  remoteStreamingV2Enabled: false`n  supersedeReads: true`n  dropUseless: true`n"
    Assert-Topic07Runtime ((Get-Content -Raw -LiteralPath $overlayPath -Encoding UTF8) -ceq $exactOverlay) `
        'The combined managed overlay is not byte exact.'

    $fakeRoot = New-Topic07RuntimeRoot
    $fakeOmp = Join-Path $fakeRoot 'fake-omp.cmd'
    $capture = Join-Path $fakeRoot 'args.txt'
    [IO.File]::WriteAllText($fakeOmp, @'
@echo off
if "%~1"=="--version" (
  echo omp/17.2.12
  exit /b 0
)
> "%TOPIC07_OMP_CAPTURE%" echo %*
exit /b 0
'@, [Text.ASCIIEncoding]::new())
    $fakeProject = Join-Path $fakeRoot 'project'
    [void](New-Item -ItemType Directory -Path $fakeProject)
    $fakeInstall = Invoke-Topic07Install -Project $fakeProject -OmpPath $fakeOmp
    Assert-Topic07Runtime ($fakeInstall.ExitCode -eq 0) "Fake OMP installation failed: $($fakeInstall.Output)"
    $reinstall = Invoke-Topic07Install -Project $fakeProject -OmpPath $fakeOmp
    Assert-Topic07Runtime ($reinstall.ExitCode -eq 0) "Idempotent reinstall failed: $($reinstall.Output)"
    $fakeTarget = Join-Path $fakeProject '.omp'
    $fakeLauncher = Join-Path $fakeTarget 'bin\omp-managed.ps1'
    $runtimePath = Join-Path $fakeTarget 'contracts\runtime.json'
    $runtime = Get-Content -Raw -LiteralPath $runtimePath -Encoding UTF8 | ConvertFrom-Json
    Assert-Topic07Runtime (
        [int]$runtime.schema_version -eq 2 -and [string]$runtime.component_version -ceq '2.1.0' -and
        [bool]$runtime.capabilities.continuity -eq $true -and
        [string]$runtime.paths.state_client -ceq [IO.Path]::GetFullPath((Join-Path $fakeTarget 'contracts\managed-state-client.mjs')) -and
        [string]$runtime.paths.continuity_schema -ceq [IO.Path]::GetFullPath((Join-Path $fakeTarget 'contracts\context-continuity-schema.mjs')) -and
        [string]$runtime.paths.continuity_core -ceq [IO.Path]::GetFullPath((Join-Path $fakeTarget 'contracts\context-continuity-core.mjs')) -and
        [string]$runtime.paths.continuity_adapter -ceq [IO.Path]::GetFullPath((Join-Path $fakeTarget 'extensions\context-continuity.js')) -and
        [string]$runtime.policy.continuity_policy_sha256 -cmatch '^[0-9a-f]{64}$'
    ) 'The generated v2 runtime is not closed over the Topic 07 paths and policy.'

    $env:TOPIC07_OMP_CAPTURE = $capture
    try {
        $accepted = Invoke-Topic07Launcher -Launcher $fakeLauncher `
            -Arguments @('--config', 'caller.yml', '--mode', 'rpc', '--', '--no-session')
        Assert-Topic07Runtime ($accepted.ExitCode -eq 0 -and (Test-Path -LiteralPath $capture)) `
            'Literal prompt text after -- was not accepted.'
        $captured = Get-Content -Raw -LiteralPath $capture
        $callerIndex = $captured.IndexOf('--config caller.yml', [StringComparison]::Ordinal)
        $wrapperIndex = $captured.IndexOf("--trusted-extension $($runtime.paths.wrapper)", [StringComparison]::Ordinal)
        $continuityIndex = $captured.IndexOf("--trusted-extension $($runtime.paths.continuity_adapter)", [StringComparison]::Ordinal)
        $overlayIndex = $captured.LastIndexOf("--config $($runtime.paths.overlay)", [StringComparison]::Ordinal)
        $separatorIndex = $captured.LastIndexOf('-- --no-session', [StringComparison]::Ordinal)
        Assert-Topic07Runtime (
            $callerIndex -ge 0 -and $wrapperIndex -gt $callerIndex -and
            $continuityIndex -gt $wrapperIndex -and $overlayIndex -gt $continuityIndex -and
            $separatorIndex -gt $overlayIndex -and
            ([regex]::Matches($captured, '(?<!\S)--trusted-extension(?!\S)')).Count -eq 2
        ) 'Managed launcher argument order or extension multiplicity drifted.'

        Remove-Item -LiteralPath $capture -Force
        $promptAccepted = Invoke-Topic07Launcher -Launcher $fakeLauncher `
            -Arguments @('--', 'please discuss --no-session')
        Assert-Topic07Runtime ($promptAccepted.ExitCode -eq 0 -and (Test-Path -LiteralPath $capture)) `
            'A prompt containing --no-session after the separator was rejected.'

        foreach ($blockedArguments in @(@('--no-session'), @('--no-session=true'), @('--extension=shadow.js'))) {
            Remove-Item -LiteralPath $capture -Force -ErrorAction SilentlyContinue
            $blocked = Invoke-Topic07Launcher -Launcher $fakeLauncher -Arguments $blockedArguments
            Assert-Topic07Runtime ($blocked.ExitCode -ne 0 -and -not (Test-Path -LiteralPath $capture)) `
                "Launcher invoked OMP for a forbidden option: $($blockedArguments -join ' ')"
        }

        $tamperTargets = [ordered]@{
            manifest = Join-Path $fakeTarget 'contracts\component-manifest.json'
            boundary_core = Join-Path $fakeTarget 'contracts\agent-boundary-core.mjs'
            continuity_core = Join-Path $fakeTarget 'contracts\context-continuity-core.mjs'
            continuity_adapter = Join-Path $fakeTarget 'extensions\context-continuity.js'
            overlay = Join-Path $fakeTarget 'contracts\managed-runtime.yml'
            launcher = $fakeLauncher
            runtime = $runtimePath
            state = Join-Path $fakeTarget 'state\manifest.json'
            agent = Join-Path $fakeTarget 'agents\cheap-scout.md'
        }
        foreach ($entry in $tamperTargets.GetEnumerator()) {
            $original = Get-Topic07FileBytes -LiteralPath ([string]$entry.Value)
            try {
                [IO.File]::AppendAllText([string]$entry.Value, "`n# topic07 drift`n", [Text.UTF8Encoding]::new($false))
                Remove-Item -LiteralPath $capture -Force -ErrorAction SilentlyContinue
                $tampered = Invoke-Topic07Launcher -Launcher $fakeLauncher -Arguments @('--version')
                Assert-Topic07Runtime ($tampered.ExitCode -ne 0 -and -not (Test-Path -LiteralPath $capture)) `
                    "Launcher started OMP after $($entry.Key) drift."
            } finally {
                [IO.File]::WriteAllBytes([string]$entry.Value, $original)
            }
        }
    } finally {
        Remove-Item Env:TOPIC07_OMP_CAPTURE -ErrorAction SilentlyContinue
    }

    $actualProject = New-Topic07RuntimeRoot
    $actualInstall = Invoke-Topic07Install -Project $actualProject
    Assert-Topic07Runtime ($actualInstall.ExitCode -eq 0) "Actual OMP installation failed: $($actualInstall.Output)"
    $actualRuntime = Get-Content -Raw -LiteralPath (Join-Path $actualProject '.omp\contracts\runtime.json') -Encoding UTF8 | ConvertFrom-Json
    $sessionDir = Join-Path $actualProject 'sessions'
    [void](New-Item -ItemType Directory -Path $sessionDir -Force)
    $actualArguments = @(
        '--mode', 'rpc', '--no-skills', '--no-rules', '--session-dir', $sessionDir,
        '--trusted-extension', $probe,
        '--trusted-extension', ([string]$actualRuntime.paths.wrapper),
        '--trusted-extension', ([string]$actualRuntime.paths.continuity_adapter),
        '--config', ([string]$actualRuntime.paths.overlay)
    )
    Push-Location -LiteralPath $actualProject
    try {
        $actualOutput = @(& ([string]$actualRuntime.paths.omp) @actualArguments 2>&1)
        $actualExitCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    Assert-Topic07Runtime ($actualExitCode -eq 0) `
        "The model-free installed runtime probe failed: $($actualOutput -join [Environment]::NewLine)"
    $probeLine = @($actualOutput | ForEach-Object { [string]$_ } | Where-Object {
        $_.StartsWith('TOPIC07_RUNTIME_PROBE=', [StringComparison]::Ordinal)
    })
    Assert-Topic07Runtime ($probeLine.Count -eq 1) `
        "The runtime probe did not emit exactly one closed observation: $($actualOutput -join [Environment]::NewLine)"
    $observation = $probeLine[0].Substring('TOPIC07_RUNTIME_PROBE='.Length) | ConvertFrom-Json
    Assert-Topic07Runtime (
        [bool]$observation.ok -and [int]$observation.task_tool_count -eq 1 -and
        [int]$observation.safe_compact_command_count -eq 1 -and
        [bool]$observation.settings_get_available -and [bool]$observation.settings_override_available -and
        [bool]$observation.perturbation_applied -and [bool]$observation.topic07_last_managed_handler_observed -and
        [bool]$observation.exact_profile_after_handlers
    ) 'The installed runtime did not expose the exact wrapper, command, settings, and final handler behavior.'
    Assert-Topic07Runtime (
        [string]$observation.session_file -and
        (Test-Path -LiteralPath $sessionDir -PathType Container) -and
        [string]$observation.artifacts_dir -and (Test-Path -LiteralPath ([string]$observation.artifacts_dir) -PathType Container) -and
        [string]$observation.artifact_marker_path -and (Test-Path -LiteralPath ([string]$observation.artifact_marker_path) -PathType Leaf) -and
        [IO.Path]::GetFullPath([string]$observation.session_file).StartsWith([IO.Path]::GetFullPath($sessionDir), [StringComparison]::OrdinalIgnoreCase) -and
        [IO.Path]::GetFullPath([string]$observation.artifacts_dir).StartsWith([IO.Path]::GetFullPath($sessionDir), [StringComparison]::OrdinalIgnoreCase) -and
        [IO.Path]::GetFullPath([string]$observation.artifact_marker_path).StartsWith([IO.Path]::GetFullPath([string]$observation.artifacts_dir), [StringComparison]::OrdinalIgnoreCase)
    ) "The model-free runtime did not persist its session and artifact directories under --session-dir: $($observation | ConvertTo-Json -Compress)"

    $rollbackProject = New-Topic07RuntimeRoot
    $priorOmp = Join-Path $rollbackProject '.omp'
    [void](New-Item -ItemType Directory -Path (Join-Path $priorOmp 'contracts') -Force)
    [void](New-Item -ItemType Directory -Path (Join-Path $priorOmp 'extensions') -Force)
    [void](New-Item -ItemType Directory -Path (Join-Path $priorOmp 'sessions\artifacts') -Force)
    [void](New-Item -ItemType Directory -Path (Join-Path $rollbackProject '.agent-tasks') -Force)
    [IO.File]::WriteAllText((Join-Path $priorOmp 'contracts\agent-boundary-core.mjs'), 'prior-v1-core', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $priorOmp 'extensions\agent-task-boundary.js'), 'prior-v1-wrapper', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $priorOmp 'sessions\session.jsonl'), '{"prior":true}', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $priorOmp 'sessions\artifacts\recovery.json'), '{"keep":true}', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $priorOmp 'credentials.json'), 'private-bytes', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $rollbackProject '.agent-tasks\task.json'), '{"task":true}', [Text.UTF8Encoding]::new($false))
    $rollbackInstall = Invoke-Topic07Install -Project $rollbackProject -OmpPath $fakeOmp
    Assert-Topic07Runtime ($rollbackInstall.ExitCode -eq 0) "Rollback fixture installation failed: $($rollbackInstall.Output)"
    $installRecord = Get-Content -Raw -LiteralPath (Join-Path $priorOmp 'contracts\install-record.json') -Encoding UTF8 | ConvertFrom-Json
    $uninstallOutput = @(& pwsh -NoProfile -File $uninstaller -Target project -ProjectDir $rollbackProject `
        -BackupDir ([string]$installRecord.backup_dir) '-DryRun:$false' 2>&1)
    Assert-Topic07Runtime ($LASTEXITCODE -eq 0) "Rollback failed: $($uninstallOutput -join [Environment]::NewLine)"
    Assert-Topic07Runtime ((Get-Content -Raw -LiteralPath (Join-Path $priorOmp 'contracts\agent-boundary-core.mjs')) -ceq 'prior-v1-core') `
        'Rollback did not restore the prior component bytes.'
    Assert-Topic07Runtime (
        (Get-Content -Raw -LiteralPath (Join-Path $priorOmp 'sessions\session.jsonl')) -ceq '{"prior":true}' -and
        (Get-Content -Raw -LiteralPath (Join-Path $priorOmp 'sessions\artifacts\recovery.json')) -ceq '{"keep":true}' -and
        (Get-Content -Raw -LiteralPath (Join-Path $priorOmp 'credentials.json')) -ceq 'private-bytes' -and
        (Get-Content -Raw -LiteralPath (Join-Path $rollbackProject '.agent-tasks\task.json')) -ceq '{"task":true}'
    ) 'Rollback changed session, recovery, credential, or operational task data.'
    Assert-Topic07Runtime (-not (Test-Path -LiteralPath (Join-Path $priorOmp 'contracts\runtime.json'))) `
        'Rollback retained a generated runtime that was absent before installation.'

    Write-Host "PASS: Topic 07 managed runtime ($script:Assertions assertions)." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Remove-Item Env:TOPIC07_OMP_CAPTURE -ErrorAction SilentlyContinue
    foreach ($root in $roots) {
        $resolved = [IO.Path]::GetFullPath($root).TrimEnd('\', '/')
        $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
        $leaf = [IO.Path]::GetFileName($resolved)
        if ($parent -cne $tempBase -or -not $leaf.StartsWith($tempPrefix, [StringComparison]::Ordinal)) {
            throw "Refusing unsafe Topic 07 runtime cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) {
            for ($attempt = 1; $attempt -le 20; $attempt++) {
                try {
                    Remove-Item -LiteralPath $resolved -Recurse -Force
                    break
                } catch {
                    if ($attempt -eq 20) { throw }
                    Start-Sleep -Milliseconds 100
                }
            }
        }
    }
}
