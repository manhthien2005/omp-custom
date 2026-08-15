#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$installer = Join-Path $repositoryRoot 'scripts\install-template.ps1'
$uninstaller = Join-Path $repositoryRoot 'scripts\uninstall-template.ps1'
$boundaryLibrary = Join-Path $repositoryRoot 'scripts\lib\topic06-agent-boundary.ps1'
$templateRoot = Join-Path $repositoryRoot 'template'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-topic08-installer-'
$tempRoots = [Collections.Generic.List[string]]::new()
$script:Assertions = 0

. $boundaryLibrary

function Assert-Topic08Installer {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function New-Topic08InstallerRoot {
    $path = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $path -Force)
    [void]$tempRoots.Add([IO.Path]::GetFullPath($path))
    return $path
}

function Get-Topic08Fingerprint {
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

function Invoke-Topic08Installer {
    param(
        [Parameter(Mandatory)][string]$ProjectDir,
        [Parameter(Mandatory)][string[]]$Components,
        [switch]$Force
    )
    $arguments = @(
        '-NoProfile', '-File', $installer, '-Target', 'project', '-ProjectDir', $ProjectDir,
        '-Components', ($Components -join ','), '-DryRun:$false'
    )
    if ($Force) { $arguments += '-Force' }
    $output = @(& pwsh @arguments 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output -join [Environment]::NewLine }
}

function Invoke-Topic08Uninstaller {
    param(
        [Parameter(Mandatory)][string]$ProjectDir,
        [Parameter(Mandatory)][string]$BackupDir
    )
    $output = @(& pwsh -NoProfile -File $uninstaller -Target project -ProjectDir $ProjectDir `
        -BackupDir $BackupDir '-DryRun:$false' 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output -join [Environment]::NewLine }
}

try {
    $manifestPath = Join-Path $templateRoot '.omp\contracts\component-manifest.json'
    $manifest = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8 | ConvertFrom-Json
    $owned = @($manifest.files | Where-Object { [bool]$_.owned })
    $dependencies = @($manifest.dependencies | ForEach-Object { [string]$_.component } | Sort-Object)
    Assert-Topic08Installer (
        [string]$manifest.component_version -ceq '2.1.0' -and
        @($manifest.files).Count -eq 20 -and $owned.Count -eq 13 -and
        ($dependencies -join '|') -ceq 'agents|config|skills|state'
    ) 'Topic 08 component ownership or dependency identity is not exact.'

    $copiedTemplate = New-Topic08InstallerRoot
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'template\.omp') -Destination $copiedTemplate -Recurse
    $copiedManifest = Join-Path $copiedTemplate '.omp\contracts\component-manifest.json'
    $missingSkill = Join-Path $copiedTemplate '.omp\skills\evidence-before-completion\SKILL.md'
    Remove-Item -LiteralPath $missingSkill -Force
    $missingRefused = $false
    try {
        [void](Read-Topic06BoundaryManifest -LiteralPath $copiedManifest -TemplateRoot $copiedTemplate)
    } catch {
        $missingRefused = $true
    }
    Assert-Topic08Installer $missingRefused 'Boundary preflight accepted a missing selected skill.'

    $claudeTemplate = New-Topic08InstallerRoot
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'template\.omp') -Destination $claudeTemplate -Recurse
    $claudeBehaviorPath = Join-Path $claudeTemplate '.omp\contracts\behavior-manifest.json'
    $claudeBehavior = Get-Content -Raw -LiteralPath $claudeBehaviorPath -Encoding UTF8 | ConvertFrom-Json
    $claudeBehavior.adapters.claude.installable = $true
    [IO.File]::WriteAllText(
        $claudeBehaviorPath,
        (($claudeBehavior | ConvertTo-Json -Depth 100) + "`n"),
        [Text.UTF8Encoding]::new($false)
    )
    $claudeTarget = New-Topic08InstallerRoot
    $beforeClaude = Get-Topic08Fingerprint -LiteralPath $claudeTarget
    $claudeRefused = $false
    try {
        [void](Read-Topic06BoundaryManifest `
            -LiteralPath (Join-Path $claudeTemplate '.omp\contracts\component-manifest.json') `
            -TemplateRoot $claudeTemplate)
    } catch {
        $claudeRefused = $true
    }
    Assert-Topic08Installer (
        $claudeRefused -and (Get-Topic08Fingerprint -LiteralPath $claudeTarget) -ceq $beforeClaude
    ) 'Boundary preflight accepted an installable Claude adapter or changed the target.'

    $project = New-Topic08InstallerRoot
    $install = Invoke-Topic08Installer -ProjectDir $project `
        -Components @('agents', 'skills', 'state', 'config', 'agent-boundary')
    Assert-Topic08Installer ($install.ExitCode -eq 0) "Topic 08 installation failed: $($install.Output)"
    $targetOmp = Join-Path $project '.omp'
    foreach ($relative in @(
        'contracts\behavior-core-schema.mjs',
        'contracts\behavior-core.mjs',
        'contracts\behavior-manifest.json'
    )) {
        $targetPath = Join-Path $targetOmp $relative
        $sourcePath = Join-Path $templateRoot ('.omp\' + $relative)
        Assert-Topic08Installer (
            (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash -ceq
                (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
        ) "Installed behavior contract hash differs: $relative"
    }

    $driftPath = Join-Path $targetOmp 'contracts\behavior-core.mjs'
    Add-Content -LiteralPath $driftPath -Value 'drift'
    $update = Invoke-Topic08Installer -ProjectDir $project `
        -Components @('agents', 'skills', 'state', 'config', 'agent-boundary') -Force
    Assert-Topic08Installer ($update.ExitCode -eq 0) "Topic 08 update failed: $($update.Output)"
    Assert-Topic08Installer (
        (Get-FileHash -LiteralPath $driftPath -Algorithm SHA256).Hash -ceq
            (Get-FileHash -LiteralPath (Join-Path $templateRoot '.omp\contracts\behavior-core.mjs') -Algorithm SHA256).Hash
    ) 'Topic 08 update did not restore exact owned behavior bytes.'

    $seeded = New-Topic08InstallerRoot
    $seed = Invoke-Topic08Installer -ProjectDir $seeded -Components @('agents', 'skills', 'state', 'config')
    Assert-Topic08Installer ($seed.ExitCode -eq 0) "Could not seed Topic 08 dependencies: $($seed.Output)"
    $authority = Join-Path $seeded '.agent-tasks'
    [void](New-Item -ItemType Directory -Path $authority -Force)
    [IO.File]::WriteAllText((Join-Path $authority 'keep.json'), '{"keep":true}', [Text.UTF8Encoding]::new($false))
    $dependencyHashes = @{}
    foreach ($relative in @(
        'agents\cheap-scout.md', 'agents\worker.md', 'agents\reviewer.md',
        'skills\task-triage\SKILL.md', 'skills\systematic-debugging\SKILL.md',
        'skills\evidence-before-completion\SKILL.md'
    )) {
        $dependencyHashes[$relative] = (Get-FileHash -LiteralPath (Join-Path $seeded ".omp\$relative") -Algorithm SHA256).Hash
    }
    $boundary = Invoke-Topic08Installer -ProjectDir $seeded -Components @('agent-boundary')
    Assert-Topic08Installer ($boundary.ExitCode -eq 0) "Boundary-only install failed: $($boundary.Output)"
    $record = Get-Content -Raw -LiteralPath (Join-Path $seeded '.omp\contracts\install-record.json') | ConvertFrom-Json
    $rollback = Invoke-Topic08Uninstaller -ProjectDir $seeded -BackupDir ([string]$record.backup_dir)
    Assert-Topic08Installer ($rollback.ExitCode -eq 0) "Boundary-only rollback failed: $($rollback.Output)"
    foreach ($relative in $dependencyHashes.Keys) {
        Assert-Topic08Installer (
            (Get-FileHash -LiteralPath (Join-Path $seeded ".omp\$relative") -Algorithm SHA256).Hash -ceq
                $dependencyHashes[$relative]
        ) "Boundary rollback changed dependency bytes: $relative"
    }
    Assert-Topic08Installer (
        -not (Test-Path -LiteralPath (Join-Path $seeded '.omp\contracts\behavior-core.mjs')) -and
        (Get-Content -Raw -LiteralPath (Join-Path $authority 'keep.json')) -ceq '{"keep":true}'
    ) 'Boundary rollback retained owned behavior bytes or changed agent-tasks authority.'

    Write-Host "PASS: Topic 08 installer ($script:Assertions assertions)." -ForegroundColor Green
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
            throw "Refusing unsafe Topic 08 test cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
}
