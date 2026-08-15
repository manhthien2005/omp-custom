#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$installer = Join-Path $repositoryRoot 'scripts\install-template.ps1'
$uninstaller = Join-Path $repositoryRoot 'scripts\uninstall-template.ps1'
$boundaryLibrary = Join-Path $repositoryRoot 'scripts\lib\topic06-agent-boundary.ps1'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-topic06-installer-'
$tempRoots = [Collections.Generic.List[string]]::new()
$script:Assertions = 0

. $boundaryLibrary

function Assert-Topic06Installer {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function New-Topic06InstallerRoot {
    $path = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $path -Force)
    [void]$tempRoots.Add([IO.Path]::GetFullPath($path))
    return $path
}

function Get-Topic06InstallerFingerprint {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return '<absent>' }
    $root = [IO.Path]::GetFullPath($LiteralPath).TrimEnd('\', '/')
    return @(
        Get-ChildItem -LiteralPath $root -Force -Recurse | Sort-Object FullName | ForEach-Object {
            $relative = $_.FullName.Substring($root.Length).TrimStart('\', '/')
            if ($_.PSIsContainer) { "D|$relative" }
            else { "F|$relative|$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)" }
        }
    ) -join "`n"
}

function Invoke-Topic06Installer {
    param(
        [Parameter(Mandatory)][string]$ProjectDir,
        [AllowNull()][string[]]$Components = $null,
        [switch]$Apply,
        [string]$ScriptPath = $installer,
        [string]$OmpPath
    )
    $arguments = @('-NoProfile', '-File', $ScriptPath, '-Target', 'project', '-ProjectDir', $ProjectDir)
    if ($null -ne $Components) { $arguments += @('-Components', ($Components -join ',')) }
    if ($Apply) { $arguments += '-DryRun:$false' }
    if ($OmpPath) { $arguments += @('-OmpPath', $OmpPath) }
    $output = @(& pwsh @arguments 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output -join [Environment]::NewLine }
}

function Invoke-Topic06Uninstaller {
    param([Parameter(Mandatory)][string]$ProjectDir, [Parameter(Mandatory)][string]$BackupDir)
    $output = @(& pwsh -NoProfile -File $uninstaller -Target project -ProjectDir $ProjectDir `
        -BackupDir $BackupDir '-DryRun:$false' 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output -join [Environment]::NewLine }
}

try {
    $manifestPath = Join-Path $repositoryRoot 'template\.omp\contracts\component-manifest.json'
    $overlayPath = Join-Path $repositoryRoot 'template\.omp\contracts\managed-runtime.yml'
    $launcherPath = Join-Path $repositoryRoot 'template\.omp\bin\omp-managed.ps1'
    Assert-Topic06Installer (Test-Path -LiteralPath $manifestPath -PathType Leaf) 'Boundary component manifest is missing.'
    Assert-Topic06Installer (Test-Path -LiteralPath $overlayPath -PathType Leaf) 'Managed overlay is missing.'
    Assert-Topic06Installer (Test-Path -LiteralPath $launcherPath -PathType Leaf) 'Managed launcher is missing.'

    $manifest = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8 | ConvertFrom-Json
    Assert-Topic06Installer (
        $manifest.record_type -ceq 'agent_boundary_component_manifest' -and
        $manifest.component -ceq 'agent-boundary' -and
        @($manifest.supported_omp_versions).Count -eq 2 -and
        @($manifest.supported_omp_versions) -ccontains '17.2.10' -and
        @($manifest.supported_omp_versions) -ccontains '17.2.12' -and
        [int]$manifest.role_policy.soft_request_budget -eq 200 -and
        [int]$manifest.role_policy.forced_partial_requests -eq 300
    ) 'Boundary manifest policy identity is invalid.'
    Assert-Topic06Installer (
        (Get-Content -Raw -LiteralPath $overlayPath -Encoding UTF8) -ceq "task:`n  softRequestBudget: 200`ncontextPromotion:`n  enabled: false`ncompaction:`n  enabled: false`n  strategy: off`n  midTurnEnabled: false`n  thresholdPercent: -1`n  thresholdTokens: -1`n  keepRecentTokens: 20000`n  autoContinue: false`n  idleEnabled: false`n  remoteEnabled: false`n  remoteStreamingV2Enabled: false`n  supersedeReads: true`n  dropUseless: true`n"
    ) 'Managed overlay bytes are not exact.'

    $manifestFixture = New-Topic06InstallerRoot
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'template\.omp') -Destination $manifestFixture -Recurse
    $fixtureManifestPath = Join-Path $manifestFixture '.omp\contracts\component-manifest.json'
    $manifestText = Get-Content -Raw -LiteralPath $fixtureManifestPath -Encoding UTF8
    $manifestMutations = @(
        [ordered]@{ Name = 'unknown top-level field'; Apply = {
            param($value) $value | Add-Member -NotePropertyName unexpected -NotePropertyValue $true
        } },
        [ordered]@{ Name = 'unsupported schema version'; Apply = {
            param($value) $value.schema_version = 3
        } },
        [ordered]@{ Name = 'unsupported PowerShell contract'; Apply = {
            param($value) $value.minimum_pwsh_version = '7.3.0'
        } },
        [ordered]@{ Name = 'duplicate path'; Apply = {
            param($value) $value.files[1].path = [string]$value.files[0].path
        } },
        [ordered]@{ Name = 'unsafe path'; Apply = {
            param($value) $value.files[0].path = '.omp/../escape'
        } },
        [ordered]@{ Name = 'source hash drift'; Apply = {
            param($value) $value.files[0].sha256 = '0' * 64
        } }
    )
    foreach ($case in $manifestMutations) {
        $mutated = $manifestText | ConvertFrom-Json
        & $case.Apply $mutated
        [IO.File]::WriteAllText(
            $fixtureManifestPath,
            (($mutated | ConvertTo-Json -Depth 64 -Compress) + "`n"),
            [Text.UTF8Encoding]::new($false)
        )
        $refused = $false
        try {
            [void](Read-Topic06BoundaryManifest -LiteralPath $fixtureManifestPath -TemplateRoot $manifestFixture)
        } catch {
            $refused = $true
        }
        Assert-Topic06Installer $refused "Boundary manifest accepted $($case.Name)."
    }
    [IO.File]::WriteAllText($fixtureManifestPath, $manifestText, [Text.UTF8Encoding]::new($false))
    $missingSource = Join-Path $manifestFixture '.omp\contracts\agent-boundary-core.mjs'
    $missingBytes = [IO.File]::ReadAllBytes($missingSource)
    Remove-Item -LiteralPath $missingSource -Force
    $missingRefused = $false
    try {
        [void](Read-Topic06BoundaryManifest -LiteralPath $fixtureManifestPath -TemplateRoot $manifestFixture)
    } catch {
        $missingRefused = $true
    } finally {
        [IO.File]::WriteAllBytes($missingSource, $missingBytes)
    }
    Assert-Topic06Installer $missingRefused 'Boundary manifest accepted a missing managed source file.'

    $dryRoot = New-Topic06InstallerRoot
    $before = Get-Topic06InstallerFingerprint -LiteralPath $dryRoot
    $dry = Invoke-Topic06Installer -ProjectDir $dryRoot
    Assert-Topic06Installer ($dry.ExitCode -eq 0) "Default dry-run failed: $($dry.Output)"
    Assert-Topic06Installer ((Get-Topic06InstallerFingerprint -LiteralPath $dryRoot) -ceq $before) 'Dry-run changed the target.'
    Assert-Topic06Installer ($dry.Output.Contains('agent-boundary', [StringComparison]::Ordinal)) 'Default component set omits agent-boundary.'
    $componentsLine = @($dry.Output -split '\r?\n' | Where-Object { $_ -match '^Components:' })[0]
    Assert-Topic06Installer ($componentsLine -notmatch '(?:^|,\s*)schemas(?:,|$)') 'Default component set still installs schemas.'

    $retiredRoot = New-Topic06InstallerRoot
    $retired = Invoke-Topic06Installer -ProjectDir $retiredRoot -Components @('schemas')
    Assert-Topic06Installer ($retired.ExitCode -ne 0 -and $retired.Output.Contains('retired', [StringComparison]::OrdinalIgnoreCase)) `
        'Explicit schemas selection was not refused as retired.'

    $partialRoot = New-Topic06InstallerRoot
    $partialBefore = Get-Topic06InstallerFingerprint -LiteralPath $partialRoot
    $partial = Invoke-Topic06Installer -ProjectDir $partialRoot -Components @('agent-boundary')
    Assert-Topic06Installer ($partial.ExitCode -ne 0) 'Boundary installed without agents/skills/state/config dependencies.'
    Assert-Topic06Installer ((Get-Topic06InstallerFingerprint -LiteralPath $partialRoot) -ceq $partialBefore) `
        'Failed dependency preflight changed the target.'

    foreach ($components in @(
        @('skills', 'state', 'config', 'agent-boundary'),
        @('agents', 'state', 'config', 'agent-boundary'),
        @('agents', 'skills', 'config', 'agent-boundary'),
        @('agents', 'skills', 'state', 'agent-boundary')
    )) {
        $dependencyRoot = New-Topic06InstallerRoot
        $dependencyBefore = Get-Topic06InstallerFingerprint -LiteralPath $dependencyRoot
        $dependency = Invoke-Topic06Installer -ProjectDir $dependencyRoot -Components $components
        Assert-Topic06Installer (
            $dependency.ExitCode -ne 0 -and
            (Get-Topic06InstallerFingerprint -LiteralPath $dependencyRoot) -ceq $dependencyBefore
        ) "Boundary dependency preflight accepted an incomplete selection: $($components -join ',')."
    }

    $badConfigRoot = New-Topic06InstallerRoot
    $baseDependencies = Invoke-Topic06Installer -ProjectDir $badConfigRoot `
        -Components @('agents', 'skills', 'state', 'config') -Apply
    Assert-Topic06Installer ($baseDependencies.ExitCode -eq 0) 'Could not seed installed dependency fixture.'
    $badConfigPath = Join-Path $badConfigRoot '.omp\config.yml'
    $badConfigText = Get-Content -Raw -LiteralPath $badConfigPath
    [IO.File]::WriteAllText(
        $badConfigPath,
        $badConfigText.Replace('omniroute/codex/gpt-5.6-sol:high', 'omniroute/codex/gpt-5.6-terra:high'),
        [Text.UTF8Encoding]::new($false)
    )
    $badConfigBefore = Get-Topic06InstallerFingerprint -LiteralPath $badConfigRoot
    $badConfig = Invoke-Topic06Installer -ProjectDir $badConfigRoot -Components @('agent-boundary')
    Assert-Topic06Installer (
        $badConfig.ExitCode -ne 0 -and
        (Get-Topic06InstallerFingerprint -LiteralPath $badConfigRoot) -ceq $badConfigBefore
    ) 'Boundary accepted an incompatible installed role route or changed the target on refusal.'

    $staleStateRoot = New-Topic06InstallerRoot
    $staleDependencies = Invoke-Topic06Installer -ProjectDir $staleStateRoot `
        -Components @('agents', 'skills', 'state', 'config') -Apply
    Assert-Topic06Installer ($staleDependencies.ExitCode -eq 0) 'Could not seed stale dependency fixture.'
    Add-Content -LiteralPath (Join-Path $staleStateRoot '.omp\state\manifest.json') -Value ' '
    $staleBefore = Get-Topic06InstallerFingerprint -LiteralPath $staleStateRoot
    $stale = Invoke-Topic06Installer -ProjectDir $staleStateRoot -Components @('agent-boundary')
    Assert-Topic06Installer (
        $stale.ExitCode -ne 0 -and
        (Get-Topic06InstallerFingerprint -LiteralPath $staleStateRoot) -ceq $staleBefore
    ) 'Boundary accepted a stale installed state dependency or changed the target on refusal.'

    $unsupportedRoot = New-Topic06InstallerRoot
    $unsupportedOmp = Join-Path $unsupportedRoot 'unsupported-omp.cmd'
    [IO.File]::WriteAllText($unsupportedOmp, "@echo off`r`necho omp/17.2.11`r`n", [Text.ASCIIEncoding]::new())
    $unsupportedBefore = Get-Topic06InstallerFingerprint -LiteralPath $unsupportedRoot
    $unsupported = Invoke-Topic06Installer -ProjectDir $unsupportedRoot `
        -Components @('agents', 'skills', 'state', 'config', 'agent-boundary') -OmpPath $unsupportedOmp
    Assert-Topic06Installer (
        $unsupported.ExitCode -ne 0 -and
        (Get-Topic06InstallerFingerprint -LiteralPath $unsupportedRoot) -ceq $unsupportedBefore
    ) 'Boundary accepted an unsupported OMP version or changed the target on refusal.'

    $project = New-Topic06InstallerRoot
    $dest = Join-Path $project '.omp'
    [void](New-Item -ItemType Directory -Path $dest -Force)
    Set-Content -LiteralPath (Join-Path $dest 'keep.txt') -Value 'pre-install-byte' -NoNewline
    $stateOutside = Join-Path $project '.agent-tasks'
    [void](New-Item -ItemType Directory -Path $stateOutside -Force)
    Set-Content -LiteralPath (Join-Path $stateOutside 'keep.json') -Value '{"keep":true}' -NoNewline
    $install = Invoke-Topic06Installer -ProjectDir $project `
        -Components @('agents', 'skills', 'state', 'config', 'agent-boundary') -Apply
    Assert-Topic06Installer ($install.ExitCode -eq 0) "Boundary installation failed: $($install.Output)"
    foreach ($relative in @(
        'contracts\component-manifest.json', 'contracts\managed-runtime.yml',
        'contracts\managed-state-client.mjs',
        'contracts\context-continuity-schema.mjs', 'contracts\context-continuity-core.mjs',
        'contracts\runtime.json', 'contracts\install-record.json',
        'extensions\agent-task-boundary.js', 'extensions\context-continuity.js', 'bin\omp-managed.ps1'
    )) {
        Assert-Topic06Installer (Test-Path -LiteralPath (Join-Path $dest $relative) -PathType Leaf) `
            "Installed boundary file is missing: $relative"
    }
    $runtime = Get-Content -Raw -LiteralPath (Join-Path $dest 'contracts\runtime.json') -Encoding UTF8 | ConvertFrom-Json
    $record = Get-Content -Raw -LiteralPath (Join-Path $dest 'contracts\install-record.json') -Encoding UTF8 | ConvertFrom-Json
    Assert-Topic06Installer (
        $runtime.record_type -ceq 'agent_boundary_runtime' -and
        [int]$runtime.schema_version -eq 2 -and [string]$runtime.component_version -ceq '2.1.0' -and
        [bool]$runtime.capabilities.continuity -eq $true -and
        [IO.Path]::GetFullPath([string]$runtime.target_omp).TrimEnd('\', '/') -ceq
            [IO.Path]::GetFullPath($dest).TrimEnd('\', '/') -and
        [string]$runtime.paths.wrapper -ceq [IO.Path]::GetFullPath((Join-Path $dest 'extensions\agent-task-boundary.js')) -and
        [string]$runtime.paths.continuity_adapter -ceq [IO.Path]::GetFullPath((Join-Path $dest 'extensions\context-continuity.js'))
    ) 'Installed runtime record is not bound to the exact target.'
    Assert-Topic06Installer (Test-Path -LiteralPath ([string]$record.backup_dir) -PathType Container) `
        'Boundary install record does not bind an existing backup.'

    $rollback = Invoke-Topic06Uninstaller -ProjectDir $project -BackupDir ([string]$record.backup_dir)
    Assert-Topic06Installer ($rollback.ExitCode -eq 0) "Boundary rollback failed: $($rollback.Output)"
    Assert-Topic06Installer ((Get-Content -Raw -LiteralPath (Join-Path $dest 'keep.txt')) -ceq 'pre-install-byte') `
        'Rollback did not restore the prior target bytes.'
    Assert-Topic06Installer (-not (Test-Path -LiteralPath (Join-Path $dest 'contracts\runtime.json'))) `
        'Rollback retained a generated boundary runtime.'
    Assert-Topic06Installer ((Get-Content -Raw -LiteralPath (Join-Path $stateOutside 'keep.json')) -ceq '{"keep":true}') `
        'Rollback changed operational agent-tasks state outside .omp.'

    Write-Host "PASS: Topic 06 installer ($script:Assertions assertions)." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    foreach ($root in $tempRoots) {
        $resolved = [IO.Path]::GetFullPath($root).TrimEnd('\', '/')
        $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
        $leaf = [IO.Path]::GetFileName($resolved)
        if ($parent -cne $tempBase -or -not $leaf.StartsWith($tempPrefix, [StringComparison]::Ordinal)) {
            throw "Refusing unsafe Topic 06 test cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
}
