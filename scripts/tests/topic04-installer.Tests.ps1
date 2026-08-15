#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$installerPath = Join-Path $repositoryRoot 'scripts\install-template.ps1'
$uninstallerPath = Join-Path $repositoryRoot 'scripts\uninstall-template.ps1'
$templateState = Join-Path $repositoryRoot 'template\.omp\state'
$protocolPath = Join-Path $templateState 'PROTOCOL.md'
$manifestPath = Join-Path $templateState 'manifest.json'
$adapterGatePath = Join-Path $repositoryRoot 'docs\evidence\current-product\topic-04\adapter-gate.json'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-topic04-installer-'
$tempRoots = [Collections.Generic.List[string]]::new()
$script:Assertions = 0

$installerSource = [IO.File]::ReadAllText($installerPath)
if (
    $installerSource -notmatch '(?ms)\[string\[\]\]\$Components\s*=\s*@\([^\)]*"state"' -or
    $installerSource -notmatch '(?m)^\s*"state"\s*=\s*"state"\s*$'
) {
    Write-Host 'FAIL [AT-TEST-INSTALLER-STATE-COMPONENT-MISSING] Installer does not expose the default state component.' -ForegroundColor Red
    exit 1
}

function Assert-Topic04Installer {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function New-Topic04InstallerRoot {
    $path = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $path)
    [void]$tempRoots.Add([IO.Path]::GetFullPath($path))
    return $path
}

function Remove-Topic04InstallerRoots {
    foreach ($path in @($tempRoots)) {
        $resolved = [IO.Path]::GetFullPath($path).TrimEnd('\', '/')
        $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
        $leaf = [IO.Path]::GetFileName($resolved)
        if ($parent -cne $tempBase -or -not $leaf.StartsWith($tempPrefix, [StringComparison]::Ordinal)) {
            throw "Refusing unsafe Topic 04 installer cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
    $tempRoots.Clear()
}

function Get-Topic04InstallerFingerprint {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return '<absent>' }
    $root = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    return @(
        Get-ChildItem -LiteralPath $root -Force -Recurse | Sort-Object FullName | ForEach-Object {
            $relative = [IO.Path]::GetRelativePath($root, $_.FullName).Replace('\', '/')
            if ($_.PSIsContainer) { "D|$relative" } else { "F|$relative|$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)" }
        }
    ) -join "`n"
}

function Invoke-Topic04Installer {
    param(
        [Parameter(Mandatory)][string]$ProjectDir,
        [AllowNull()][string[]]$Components = $null,
        [switch]$Apply,
        [AllowNull()][string]$PwshPath = $null
    )
    $arguments = @('-NoProfile', '-File', $installerPath, '-Target', 'project', '-ProjectDir', $ProjectDir)
    if ($null -ne $Components) { $arguments += '-Components'; $arguments += $Components }
    if ($Apply) { $arguments += '-DryRun:$false' }
    if ($PwshPath) { $arguments += @('-PwshPath', $PwshPath) }
    $output = @(& pwsh @arguments 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join [Environment]::NewLine) }
}

function Invoke-Topic04Rollback {
    param(
        [Parameter(Mandatory)][string]$ProjectDir,
        [Parameter(Mandatory)][string]$BackupDir
    )
    $output = @(& pwsh -NoProfile -File $uninstallerPath -Target project -ProjectDir $ProjectDir `
        -BackupDir $BackupDir '-DryRun:$false' 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join [Environment]::NewLine) }
}

try {
    Assert-Topic04Installer (Test-Path -LiteralPath $protocolPath -PathType Leaf) 'State component must include PROTOCOL.md.'
    Assert-Topic04Installer (Test-Path -LiteralPath $manifestPath -PathType Leaf) 'State component must include its source manifest.'

    $dryRoot = New-Topic04InstallerRoot
    [void](New-Item -ItemType Directory -Path (Join-Path $dryRoot '.omp') -Force)
    [IO.File]::WriteAllText((Join-Path $dryRoot '.omp\sentinel.txt'), 'unchanged', [Text.UTF8Encoding]::new($false))
    $dryBefore = Get-Topic04InstallerFingerprint -Path $dryRoot
    $dryRun = Invoke-Topic04Installer -ProjectDir $dryRoot
    Assert-Topic04Installer ($dryRun.ExitCode -eq 0 -and $dryRun.Output -match '(?i)state') "Default dry-run must list the state component: $($dryRun.Output)"
    Assert-Topic04Installer ((Get-Topic04InstallerFingerprint -Path $dryRoot) -ceq $dryBefore) 'Default dry-run must change no target bytes.'
    Assert-Topic04Installer (@(Get-ChildItem -LiteralPath $dryRoot -Directory -Filter '.omp.backup-*').Count -eq 0) 'Dry-run must not create a backup.'

    $missingRoot = New-Topic04InstallerRoot
    $missingPwsh = Join-Path $missingRoot 'missing-pwsh.exe'
    $missingBefore = Get-Topic04InstallerFingerprint -Path $missingRoot
    $missingResult = Invoke-Topic04Installer -ProjectDir $missingRoot -Components @('state') -Apply -PwshPath $missingPwsh
    Assert-Topic04Installer ($missingResult.ExitCode -ne 0 -and $missingResult.Output -match '(?i)pwsh.*7\.4|7\.4.*pwsh') 'Missing pwsh must fail clearly before copy.'
    Assert-Topic04Installer ((Get-Topic04InstallerFingerprint -Path $missingRoot) -ceq $missingBefore) 'Missing pwsh failure must change no target bytes.'

    $oldRoot = New-Topic04InstallerRoot
    $oldPwsh = Join-Path $oldRoot 'pwsh-7.3.cmd'
    [IO.File]::WriteAllText($oldPwsh, "@echo off`r`necho 7.3.9`r`n", [Text.ASCIIEncoding]::new())
    $oldBefore = Get-Topic04InstallerFingerprint -Path $oldRoot
    $oldResult = Invoke-Topic04Installer -ProjectDir $oldRoot -Components @('state') -Apply -PwshPath $oldPwsh
    Assert-Topic04Installer ($oldResult.ExitCode -ne 0 -and $oldResult.Output -match '7\.4') 'pwsh older than 7.4 must fail clearly.'
    Assert-Topic04Installer ((Get-Topic04InstallerFingerprint -Path $oldRoot) -ceq $oldBefore) 'Old pwsh failure must change no target bytes.'

    $stateOnlyRoot = New-Topic04InstallerRoot
    $stateOnly = Invoke-Topic04Installer -ProjectDir $stateOnlyRoot -Components @('state') -Apply
    Assert-Topic04Installer ($stateOnly.ExitCode -eq 0) "State-only install failed: $($stateOnly.Output)"
    Assert-Topic04Installer (
        (Get-Topic04InstallerFingerprint -Path (Join-Path $stateOnlyRoot '.omp\state')) -ceq
        (Get-Topic04InstallerFingerprint -Path $templateState)
    ) 'State-only apply must reproduce the exact template state tree.'
    Assert-Topic04Installer (@(Get-ChildItem -LiteralPath (Join-Path $stateOnlyRoot '.omp') -Force).Count -eq 1) 'State-only install must not add a hook, skill, agent, or command.'

    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json -Depth 64
    Assert-Topic04Installer ([long]$manifest.schema_version -eq 1 -and [string]$manifest.minimum_pwsh_version -ceq '7.4.0') 'State manifest must pin schema and minimum pwsh versions.'
    foreach ($entry in @($manifest.files)) {
        $sourceFile = Join-Path $templateState ([string]$entry.path -replace '/', [IO.Path]::DirectorySeparatorChar)
        Assert-Topic04Installer (
            (Test-Path -LiteralPath $sourceFile -PathType Leaf) -and
            (Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash -ceq [string]$entry.sha256
        ) "State manifest hash mismatch for $($entry.path)."
    }

    $protectedRoot = New-Topic04InstallerRoot
    $gitOutput = @(& git -C $protectedRoot init --quiet 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Git init failed: $($gitOutput -join ' ')" }
    $operationalRoot = Join-Path $protectedRoot '.git\agent-tasks'
    $legacyOperationalRoot = Join-Path $protectedRoot '.agent-tasks'
    [void](New-Item -ItemType Directory -Path $operationalRoot -Force)
    [void](New-Item -ItemType Directory -Path $legacyOperationalRoot -Force)
    [IO.File]::WriteAllText((Join-Path $operationalRoot 'sentinel.bin'), 'git-common-authority', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $legacyOperationalRoot 'sentinel.bin'), 'legacy-authority', [Text.UTF8Encoding]::new($false))
    $dest = Join-Path $protectedRoot '.omp'
    [void](New-Item -ItemType Directory -Path (Join-Path $dest 'state') -Force)
    [void](New-Item -ItemType Directory -Path (Join-Path $dest 'sessions') -Force)
    [IO.File]::WriteAllText((Join-Path $dest 'state\legacy.txt'), 'pre-install-state', [Text.UTF8Encoding]::new($false))
    $protectedValues = [ordered]@{
        'models.yml' = 'model-catalog'; 'credentials.json' = 'credential'; 'sessions\active.json' = 'session'
    }
    foreach ($item in $protectedValues.GetEnumerator()) {
        $path = Join-Path $dest $item.Key
        [IO.File]::WriteAllText($path, $item.Value, [Text.UTF8Encoding]::new($false))
    }
    $operationalBefore = Get-Topic04InstallerFingerprint -Path $operationalRoot
    $legacyBefore = Get-Topic04InstallerFingerprint -Path $legacyOperationalRoot
    $install = Invoke-Topic04Installer -ProjectDir $protectedRoot -Components @('state') -Apply
    Assert-Topic04Installer ($install.ExitCode -eq 0) "Protected-root state install failed: $($install.Output)"
    $backup = @(Get-ChildItem -LiteralPath $protectedRoot -Directory -Filter '.omp.backup-*')
    Assert-Topic04Installer ($backup.Count -eq 1) "State install must create one .omp backup; found $($backup.Count)."
    foreach ($item in $protectedValues.GetEnumerator()) {
        Assert-Topic04Installer ([IO.File]::ReadAllText((Join-Path $dest $item.Key)) -ceq $item.Value) "Installer changed protected file $($item.Key)."
    }
    Assert-Topic04Installer ((Get-Topic04InstallerFingerprint -Path $operationalRoot) -ceq $operationalBefore) 'Installer must not read/write/delete Git-common operational authority.'
    Assert-Topic04Installer ((Get-Topic04InstallerFingerprint -Path $legacyOperationalRoot) -ceq $legacyBefore) 'Installer must not read/write/delete legacy operational authority.'

    [IO.File]::WriteAllText((Join-Path $dest 'state\PROTOCOL.md'), 'locally stale executable', [Text.UTF8Encoding]::new($false))
    $reinstall = Invoke-Topic04Installer -ProjectDir $protectedRoot -Components @('state') -Apply
    Assert-Topic04Installer ($reinstall.ExitCode -eq 0) "State reinstall failed: $($reinstall.Output)"
    Assert-Topic04Installer ([IO.File]::ReadAllText((Join-Path $dest 'state\PROTOCOL.md')) -ceq [IO.File]::ReadAllText($protocolPath)) 'Reinstall must update executable state files.'
    Assert-Topic04Installer ((Get-Topic04InstallerFingerprint -Path $operationalRoot) -ceq $operationalBefore) 'Reinstall must preserve operational authority.'

    $rollback = Invoke-Topic04Rollback -ProjectDir $protectedRoot -BackupDir $backup[0].FullName
    Assert-Topic04Installer ($rollback.ExitCode -eq 0 -and $rollback.Output -match '(?i)operational(?: agent-tasks)? state.*retained') "Rollback must explicitly retain operational state: $($rollback.Output)"
    Assert-Topic04Installer (Test-Path -LiteralPath (Join-Path $dest 'state\legacy.txt') -PathType Leaf) 'Rollback must restore prior .omp/state bytes.'
    Assert-Topic04Installer ((Get-Topic04InstallerFingerprint -Path $operationalRoot) -ceq $operationalBefore) 'Rollback must preserve Git-common operational authority.'
    Assert-Topic04Installer ((Get-Topic04InstallerFingerprint -Path $legacyOperationalRoot) -ceq $legacyBefore) 'Rollback must preserve legacy operational authority.'

    $protocol = [IO.File]::ReadAllText($protocolPath)
    foreach ($literal in @('pwsh 7.4', 'state/agent-tasks.ps1', 'request', 'result', 'exit', 'dry-run', 'never edit', 'read-only diagnosis', 'Claude', 'Codex')) {
        Assert-Topic04Installer ($protocol.IndexOf($literal, [StringComparison]::OrdinalIgnoreCase) -ge 0) "PROTOCOL.md lacks required contract text: $literal"
    }
    foreach ($relative in @('template/.omp/AGENTS.md', 'template/.omp/commands/quick.md', 'template/.omp/commands/standard.md', 'template/.omp/commands/orchestrated.md')) {
        $text = [IO.File]::ReadAllText((Join-Path $repositoryRoot $relative))
        Assert-Topic04Installer ($text.IndexOf('state/PROTOCOL.md', [StringComparison]::OrdinalIgnoreCase) -ge 0) "$relative must point to the shared state protocol."
        Assert-Topic04Installer ($text.IndexOf('before mutation', [StringComparison]::OrdinalIgnoreCase) -ge 0) "$relative must create authority before mutation."
        Assert-Topic04Installer ($text.IndexOf('read-only diagnosis', [StringComparison]::OrdinalIgnoreCase) -ge 0) "$relative must preserve read-only diagnosis when core is unavailable."
        Assert-Topic04Installer ($text -notmatch '(?i)expected_revision_sha256|record_type|schema_version') "$relative must not duplicate the state schema."
    }
    $quick = [IO.File]::ReadAllText((Join-Path $repositoryRoot 'template/.omp/commands/quick.md'))
    Assert-Topic04Installer ($quick -match '(?i)minimal task authority' -and $quick -notmatch '(?i)exempt') 'Quick must use the same minimal task authority rather than an exemption.'

    $gate = Get-Content -Raw -LiteralPath $adapterGatePath | ConvertFrom-Json -Depth 32
    Assert-Topic04Installer (
        [string]$gate.manual_core_adapter -ceq 'SELECTED' -and
        [string]$gate.automatic_lifecycle_adapter -ceq 'NOT_INSTALLED' -and
        [string]$gate.reason_code -ceq 'TOPIC08_INSTALLED_RUNTIME_PROBE_REQUIRED' -and
        [string]$gate.pinned_source_commit -ceq '3a8591a8af5b6d200088d12ca75a5517cb064fa8'
    ) 'Adapter gate must keep automatic lifecycle integration deferred to Topic 08.'

    foreach ($doc in @('docs/task-state.md', 'docs/installation.md', 'docs/rollback.md')) {
        $text = [IO.File]::ReadAllText((Join-Path $repositoryRoot $doc))
        Assert-Topic04Installer ($text.IndexOf('agent-tasks', [StringComparison]::OrdinalIgnoreCase) -ge 0) "$doc must document operational state boundaries."
    }

    $parseOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -Command (
        "`$errors=`$null; [void][Management.Automation.Language.Parser]::ParseFile('{0}',[ref]`$null,[ref]`$errors); if(`$errors.Count){{`$errors; exit 1}}" -f $installerPath.Replace("'", "''")
    ) 2>&1)
    Assert-Topic04Installer ($LASTEXITCODE -eq 0) "Installer must remain Windows PowerShell 5.1 parseable: $($parseOutput -join ' ')"

    Write-Host ("PASS Topic 04 installer and adapter ({0} assertions)" -f $script:Assertions) -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("FAIL [AT-TEST-INSTALLER] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    Remove-Topic04InstallerRoots
}
