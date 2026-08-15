#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ROUND0912_SCRATCH_PACKAGE_PROOF
# Expected adapter states: IMPLEMENTED_NOT_PROMOTED and DESIGNED_NOT_VERIFIED, with exact
# installable booleans. Rollback is exercised through uninstall-template.ps1 and must report:
# Operational agent-tasks state retained.

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$installer = Join-Path $repositoryRoot 'scripts\install-template.ps1'
$uninstaller = Join-Path $repositoryRoot 'scripts\uninstall-template.ps1'
$discoveryProbe = Join-Path $repositoryRoot 'scripts\tests\fixtures\topic06-omp-agent-discovery-probe.mjs'
$templateRoot = Join-Path $repositoryRoot 'template'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-round0912-install-'
$tempRoots = [Collections.Generic.List[string]]::new()
$script:Assertions = 0

function Assert-Round0912Installer {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function New-Round0912ScratchProject {
    $path = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $path -Force)
    $resolved = [IO.Path]::GetFullPath($path)
    [void]$tempRoots.Add($resolved)

    $gitOutput = @(& git -C $resolved init --quiet 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not initialize the disposable Git project: $($gitOutput -join [Environment]::NewLine)"
    }
    return $resolved
}

function Set-Round0912UserState {
    param([Parameter(Mandatory)][string]$ProjectDir)

    $ompRoot = Join-Path $ProjectDir '.omp'
    $sessions = Join-Path $ompRoot 'sessions'
    $agentTasks = Join-Path $ProjectDir '.agent-tasks'
    [void](New-Item -ItemType Directory -Path $sessions -Force)
    [void](New-Item -ItemType Directory -Path $agentTasks -Force)
    [IO.File]::WriteAllText(
        (Join-Path $ompRoot 'models.yml'),
        "providers: {}`n",
        [Text.UTF8Encoding]::new($false)
    )
    [IO.File]::WriteAllText(
        (Join-Path $sessions 'keep.json'),
        '{"session":"retained"}',
        [Text.UTF8Encoding]::new($false)
    )
    [IO.File]::WriteAllText(
        (Join-Path $agentTasks 'keep.json'),
        '{"task":"retained"}',
        [Text.UTF8Encoding]::new($false)
    )
}

function Get-Round0912Fingerprint {
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

function Invoke-Round0912Installer {
    param(
        [Parameter(Mandatory)][string]$ProjectDir,
        [Parameter(Mandatory)][string]$OmpPath,
        [switch]$Force
    )

    $arguments = @(
        '-NoLogo', '-NoProfile', '-File', $installer,
        '-Target', 'project',
        '-ProjectDir', $ProjectDir,
        '-Components', 'agents,workflows,skills,state,agents-md,rules-md,config,agent-boundary',
        '-OmpPath', $OmpPath,
        '-DryRun:$false'
    )
    if ($Force) { $arguments += '-Force' }
    $output = @(& pwsh @arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = $output -join [Environment]::NewLine
    }
}

function Invoke-Round0912Uninstaller {
    param(
        [Parameter(Mandatory)][string]$ProjectDir,
        [Parameter(Mandatory)][string]$BackupDir
    )

    $output = @(& pwsh -NoLogo -NoProfile -File $uninstaller `
        -Target project -ProjectDir $ProjectDir -BackupDir $BackupDir '-DryRun:$false' 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = $output -join [Environment]::NewLine
    }
}

function Invoke-Round0912Discovery {
    param(
        [Parameter(Mandatory)][string]$ProjectDir,
        [Parameter(Mandatory)][string]$OmpPath
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $OmpPath
    $startInfo.WorkingDirectory = $repositoryRoot
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    foreach ($argument in @(
        '--cwd', $ProjectDir,
        '--mode', 'rpc',
        '--no-session',
        '--no-tools',
        '--no-skills',
        '--no-rules',
        '--no-extensions',
        '--extension', $discoveryProbe
    )) {
        [void]$startInfo.ArgumentList.Add($argument)
    }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        [void]$process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(30000)) {
            try { $process.Kill($true) } catch { }
            throw 'Installed OMP discovery exceeded the 30-second model-free boundary.'
        }
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Stdout = $stdout
            Stderr = $stderr
        }
    } finally {
        $process.Dispose()
    }
}

function Assert-Round0912UserState {
    param([Parameter(Mandatory)][string]$ProjectDir)

    Assert-Round0912Installer (
        (Get-Content -Raw -LiteralPath (Join-Path $ProjectDir '.omp\models.yml') -Encoding UTF8) -ceq "providers: {}`n"
    ) 'Installer or rollback changed the protected model catalog.'
    Assert-Round0912Installer (
        (Get-Content -Raw -LiteralPath (Join-Path $ProjectDir '.omp\sessions\keep.json') -Encoding UTF8) -ceq '{"session":"retained"}'
    ) 'Installer or rollback changed protected session state.'
    Assert-Round0912Installer (
        (Get-Content -Raw -LiteralPath (Join-Path $ProjectDir '.agent-tasks\keep.json') -Encoding UTF8) -ceq '{"task":"retained"}'
    ) 'Installer or rollback changed operational agent-tasks state.'
}

function Remove-Round0912ScratchRoot {
    param([Parameter(Mandatory)][string]$LiteralPath)

    $resolved = [IO.Path]::GetFullPath($LiteralPath).TrimEnd('\', '/')
    $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
    $leaf = [IO.Path]::GetFileName($resolved)
    if ($parent -cne $tempBase -or -not $leaf.StartsWith($tempPrefix, [StringComparison]::Ordinal)) {
        throw "Refusing unsafe Round 09-12 test cleanup target: $resolved"
    }
    $lastCleanupError = $null
    for ($attempt = 1; $attempt -le 20; $attempt++) {
        try {
            if (Test-Path -LiteralPath $resolved) {
                Remove-Item -LiteralPath $resolved -Recurse -Force
            }
        } catch {
            $lastCleanupError = $_
        }
        Start-Sleep -Milliseconds 100
        if (-not (Test-Path -LiteralPath $resolved)) {
            Start-Sleep -Milliseconds 100
            if (-not (Test-Path -LiteralPath $resolved)) { return }
        }
    }
    if ($null -ne $lastCleanupError) { throw $lastCleanupError }
    throw "Round 09-12 scratch root still exists after bounded cleanup: $resolved"
}

try {
    $ompCommand = Get-Command omp.exe -ErrorAction SilentlyContinue
    if ($null -eq $ompCommand) { $ompCommand = Get-Command omp -ErrorAction SilentlyContinue }
    Assert-Round0912Installer ($null -ne $ompCommand) 'Pinned local OMP is unavailable; no live install was attempted.'
    $ompPath = [IO.Path]::GetFullPath([string]$ompCommand.Source)
    Assert-Round0912Installer (
        (Test-Path -LiteralPath $ompPath -PathType Leaf)
    ) "Resolved OMP path is not a file: $ompPath"

    $packageProject = New-Round0912ScratchProject
    Set-Round0912UserState -ProjectDir $packageProject
    $originalOmp = Get-Round0912Fingerprint -LiteralPath (Join-Path $packageProject '.omp')
    $originalAgentTasks = Get-Round0912Fingerprint -LiteralPath (Join-Path $packageProject '.agent-tasks')

    $install = Invoke-Round0912Installer -ProjectDir $packageProject -OmpPath $ompPath
    Assert-Round0912Installer ($install.ExitCode -eq 0) "Scratch package installation failed: $($install.Output)"
    Assert-Round0912UserState -ProjectDir $packageProject

    $installedOmp = Join-Path $packageProject '.omp'
    $agents = @(Get-ChildItem -LiteralPath (Join-Path $installedOmp 'agents') -File -Filter '*.md' |
        ForEach-Object { $_.BaseName } | Sort-Object)
    $skills = @(Get-ChildItem -LiteralPath (Join-Path $installedOmp 'skills') -Directory |
        ForEach-Object { $_.Name } | Sort-Object)
    Assert-Round0912Installer (
        ($agents -join '|') -ceq 'cheap-scout|reviewer|worker'
    ) "Installed agent set is not exact: $($agents -join ', ')"
    Assert-Round0912Installer (
        ($skills -join '|') -ceq 'evidence-before-completion|systematic-debugging|task-triage'
    ) "Installed skill set is not exact: $($skills -join ', ')"

    $component = Get-Content -Raw -LiteralPath (Join-Path $installedOmp 'contracts\component-manifest.json') `
        -Encoding UTF8 | ConvertFrom-Json
    $behavior = Get-Content -Raw -LiteralPath (Join-Path $installedOmp 'contracts\behavior-manifest.json') `
        -Encoding UTF8 | ConvertFrom-Json
    $runtime = Get-Content -Raw -LiteralPath (Join-Path $installedOmp 'contracts\runtime.json') `
        -Encoding UTF8 | ConvertFrom-Json
    Assert-Round0912Installer (
        [string]$component.component_version -ceq '2.1.0' -and
        [string]$runtime.installed_omp_version -ceq '17.2.12'
    ) 'Installed agent-boundary component or pinned OMP 17.2.12 identity is not exact.'
    Assert-Round0912Installer (
        [string]$behavior.adapters.omp.status -ceq 'IMPLEMENTED_NOT_PROMOTED' -and
        [bool]$behavior.adapters.omp.installable
    ) 'OMP adapter lifecycle or installable state is not truthful.'
    Assert-Round0912Installer (
        [string]$behavior.adapters.claude.status -ceq 'DESIGNED_NOT_VERIFIED' -and
        -not [bool]$behavior.adapters.claude.installable
    ) 'Claude adapter lifecycle or installable state is not truthful.'

    $unexpectedPackageFiles = @(
        Get-ChildItem -LiteralPath $installedOmp -File -Recurse -Force | Where-Object {
            $relative = $_.FullName.Substring($installedOmp.Length).TrimStart('\', '/')
            $relative -match '(?i)(?:^|[\\/])evals(?:[\\/]|$)|round09-12'
        }
    )
    $unexpectedPackageNames = @($unexpectedPackageFiles | ForEach-Object { $_.FullName }) -join ', '
    Assert-Round0912Installer (
        $unexpectedPackageFiles.Count -eq 0
    ) "Evaluation tooling leaked into installed .omp: $unexpectedPackageNames"

    $discovery = Invoke-Round0912Discovery -ProjectDir $packageProject -OmpPath $ompPath
    Assert-Round0912Installer (
        $discovery.ExitCode -eq 0
    ) "Installed OMP discovery failed: $($discovery.Stderr)$($discovery.Stdout)"
    $discoveryMarker = [regex]::Match($discovery.Stdout, '(?m)^TOPIC06_AGENT_DISCOVERY=(.*)$')
    Assert-Round0912Installer ($discoveryMarker.Success) 'Installed OMP did not emit the bounded discovery receipt.'
    $discoveredAgents = @($discoveryMarker.Groups[1].Value | ConvertFrom-Json)
    Assert-Round0912Installer (
        (@($discoveredAgents | ForEach-Object { [string]$_.name }) -join '|') -ceq 'cheap-scout|reviewer|worker'
    ) 'Installed OMP runtime discovery did not return the exact selected roles.'

    $record = Get-Content -Raw -LiteralPath (Join-Path $installedOmp 'contracts\install-record.json') `
        -Encoding UTF8 | ConvertFrom-Json
    $backupDir = [IO.Path]::GetFullPath([string]$record.backup_dir)
    Assert-Round0912Installer (
        (Test-Path -LiteralPath $backupDir -PathType Container)
    ) 'Manifest-bound package backup is unavailable.'
    $rollback = Invoke-Round0912Uninstaller -ProjectDir $packageProject -BackupDir $backupDir
    Assert-Round0912Installer ($rollback.ExitCode -eq 0) "Scratch package rollback failed: $($rollback.Output)"
    Assert-Round0912Installer (
        $rollback.Output.Contains('Operational agent-tasks state retained.', [StringComparison]::Ordinal)
    ) 'Rollback did not report retained operational agent-tasks state.'
    Assert-Round0912Installer (
        (Get-Round0912Fingerprint -LiteralPath (Join-Path $packageProject '.omp')) -ceq $originalOmp
    ) 'Manifest-bound rollback did not restore the original .omp bytes.'
    Assert-Round0912Installer (
        (Get-Round0912Fingerprint -LiteralPath (Join-Path $packageProject '.agent-tasks')) -ceq $originalAgentTasks
    ) 'Manifest-bound rollback changed operational agent-tasks state.'
    Assert-Round0912UserState -ProjectDir $packageProject

    $repairProject = New-Round0912ScratchProject
    Set-Round0912UserState -ProjectDir $repairProject
    $repairInstall = Invoke-Round0912Installer -ProjectDir $repairProject -OmpPath $ompPath
    Assert-Round0912Installer ($repairInstall.ExitCode -eq 0) "Repair fixture installation failed: $($repairInstall.Output)"
    $driftPath = Join-Path $repairProject '.omp\contracts\behavior-core.mjs'
    $templatePath = Join-Path $templateRoot '.omp\contracts\behavior-core.mjs'
    Add-Content -LiteralPath $driftPath -Value '// round09-12 deliberate drift'
    Assert-Round0912Installer (
        (Get-FileHash -LiteralPath $driftPath -Algorithm SHA256).Hash -cne
            (Get-FileHash -LiteralPath $templatePath -Algorithm SHA256).Hash
    ) 'Repair fixture did not create an owned-byte drift.'
    $repair = Invoke-Round0912Installer -ProjectDir $repairProject -OmpPath $ompPath -Force
    Assert-Round0912Installer ($repair.ExitCode -eq 0) "Approved repair mode failed: $($repair.Output)"
    Assert-Round0912Installer (
        (Get-FileHash -LiteralPath $driftPath -Algorithm SHA256).Hash -ceq
            (Get-FileHash -LiteralPath $templatePath -Algorithm SHA256).Hash
    ) 'Approved repair mode did not restore exact template-owned bytes.'
    Assert-Round0912UserState -ProjectDir $repairProject

    Write-Host "PASS: Round 09-12 scratch package proof ($script:Assertions assertions)." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    foreach ($root in $tempRoots) {
        Remove-Round0912ScratchRoot -LiteralPath $root
    }
}
