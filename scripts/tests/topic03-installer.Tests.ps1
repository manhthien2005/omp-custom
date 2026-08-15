$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$installerPath = Join-Path $repositoryRoot 'scripts\install-template.ps1'
$uninstallerPath = Join-Path $repositoryRoot 'scripts\uninstall-template.ps1'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-topic03-installer-'
$tempRoots = [Collections.Generic.List[string]]::new()
$script:passed = 0
$script:failed = 0

function New-Topic03InstallerRoot {
    $path = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $path -Force)
    [void]$tempRoots.Add([IO.Path]::GetFullPath($path))
    return $path
}

function Remove-Topic03InstallerRoots {
    foreach ($path in $tempRoots) {
        $resolved = [IO.Path]::GetFullPath($path).TrimEnd('\', '/')
        $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
        $leaf = [IO.Path]::GetFileName($resolved)
        if ($parent -cne $tempBase -or -not $leaf.StartsWith($tempPrefix, [StringComparison]::Ordinal)) {
            throw "Refusing unsafe test cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) {
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }
}

function Invoke-Topic03Installer {
    param(
        [Parameter(Mandatory)][ValidateSet('project', 'user')][string]$Target,
        [string]$ProjectDir,
        [string[]]$Components,
        [switch]$Apply,
        [switch]$EnablePerSpawnEffort
    )

    $arguments = @('-NoProfile', '-File', $installerPath, '-Target', $Target)
    if ($Target -ceq 'project') {
        $arguments += @('-ProjectDir', $ProjectDir)
    }
    if ($null -ne $Components -and $Components.Count -gt 0) {
        $arguments += '-Components'
        $arguments += $Components
    }
    if ($Apply) {
        $arguments += '-DryRun:$false'
    }
    if ($EnablePerSpawnEffort) {
        $arguments += '-EnablePerSpawnEffort'
    }

    $output = @(& pwsh @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = ($output -join [Environment]::NewLine)
    }
}

function Invoke-Topic03Rollback {
    param(
        [Parameter(Mandatory)][string]$ProjectDir,
        [Parameter(Mandatory)][string]$BackupDir
    )

    $output = @(& pwsh -NoProfile -File $uninstallerPath -Target project -ProjectDir $ProjectDir `
        -BackupDir $BackupDir '-DryRun:$false' 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join [Environment]::NewLine)
    }
}

function Get-Topic03TreeFingerprint {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return '<absent>' }

    $root = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    $rows = foreach ($item in Get-ChildItem -LiteralPath $root -Force -Recurse | Sort-Object FullName) {
        $relative = $item.FullName.Substring($root.Length).TrimStart('\', '/')
        if ($item.PSIsContainer) {
            "D|$relative"
        } else {
            "F|$relative|$((Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash)"
        }
    }
    return $rows -join "`n"
}

function Assert-Topic03 {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Topic03FileSet {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][string[]]$Expected
    )
    $actual = @(
        Get-ChildItem -LiteralPath $Directory -File |
            ForEach-Object Name |
            Sort-Object
    )
    $want = @($Expected | Sort-Object)
    Assert-Topic03 (($actual -join '|') -ceq ($want -join '|')) `
        "Unexpected file set in ${Directory}: $($actual -join ', ')"
}

function Invoke-Topic03Test {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][scriptblock]$Body)
    try {
        & $Body
        $script:passed++
        Write-Host "PASS $Name" -ForegroundColor Green
    } catch {
        $script:failed++
        Write-Host "FAIL $Name :: $($_.Exception.Message)" -ForegroundColor Red
    }
}

try {
    Invoke-Topic03Test 'dry-run leaves the target byte-for-byte unchanged' {
        $root = New-Topic03InstallerRoot
        $agents = Join-Path $root '.omp\agents'
        [void](New-Item -ItemType Directory -Path $agents -Force)
        Set-Content -LiteralPath (Join-Path $agents 'explorer.md') -Value 'legacy explorer'
        $before = Get-Topic03TreeFingerprint $root

        $result = Invoke-Topic03Installer -Target project -ProjectDir $root
        Assert-Topic03 ($result.ExitCode -eq 0) "dry-run exited $($result.ExitCode): $($result.Output)"
        Assert-Topic03 ((Get-Topic03TreeFingerprint $root) -ceq $before) 'dry-run changed the target tree'
        Assert-Topic03 (@(Get-ChildItem -LiteralPath $root -Directory -Filter '.omp.backup-*').Count -eq 0) `
            'dry-run created a backup'
    }

    Invoke-Topic03Test 'workflows installs the commands component' {
        $root = New-Topic03InstallerRoot
        $result = Invoke-Topic03Installer -Target project -ProjectDir $root -Components @('workflows') -Apply
        Assert-Topic03 ($result.ExitCode -eq 0) "workflow install exited $($result.ExitCode): $($result.Output)"
        Assert-Topic03FileSet -Directory (Join-Path $root '.omp\commands') `
            -Expected @('orchestrated.md', 'quick.md', 'standard.md')
        Assert-Topic03 (-not (Test-Path -LiteralPath (Join-Path $root '.omp\workflows'))) `
            'installer created a stale workflows directory'
    }

    Invoke-Topic03Test 'apply installs the selected agents and retires only the closed stale set' {
        $root = New-Topic03InstallerRoot
        $agents = Join-Path $root '.omp\agents'
        [void](New-Item -ItemType Directory -Path $agents -Force)
        foreach ($name in @('tech-lead.md', 'explorer.md', 'implementer.md', 'verifier.md')) {
            Set-Content -LiteralPath (Join-Path $agents $name) -Value "legacy $name"
        }
        Set-Content -LiteralPath (Join-Path $agents 'custom-agent.md') -Value 'keep me'

        $result = Invoke-Topic03Installer -Target project -ProjectDir $root -Components @('agents') -Apply
        Assert-Topic03 ($result.ExitCode -eq 0) "agent install exited $($result.ExitCode): $($result.Output)"
        Assert-Topic03FileSet -Directory $agents `
            -Expected @('cheap-scout.md', 'custom-agent.md', 'reviewer.md', 'worker.md')

        $backup = @(Get-ChildItem -LiteralPath $root -Directory -Filter '.omp.backup-*')
        Assert-Topic03 ($backup.Count -eq 1) "expected one backup, found $($backup.Count)"
        Assert-Topic03FileSet -Directory (Join-Path $backup[0].FullName 'agents') `
            -Expected @('custom-agent.md', 'explorer.md', 'implementer.md', 'tech-lead.md', 'verifier.md')
    }

    Invoke-Topic03Test 'protected model database credential and session files survive apply' {
        $root = New-Topic03InstallerRoot
        $dest = Join-Path $root '.omp'
        $sessions = Join-Path $dest 'sessions'
        [void](New-Item -ItemType Directory -Path $sessions -Force)
        $protectedFiles = [ordered]@{
            'models.yml' = 'models-secret'
            'agent.db' = 'database-secret'
            'agent.db-shm' = 'database-shm-secret'
            'agent.db-wal' = 'database-wal-secret'
            'credentials.json' = 'credential-secret'
            'sessions\active.json' = 'session-secret'
        }
        foreach ($entry in $protectedFiles.GetEnumerator()) {
            $path = Join-Path $dest $entry.Key
            $parent = Split-Path $path -Parent
            if (-not (Test-Path -LiteralPath $parent)) {
                [void](New-Item -ItemType Directory -Path $parent -Force)
            }
            Set-Content -LiteralPath $path -Value $entry.Value -NoNewline
        }

        $result = Invoke-Topic03Installer -Target project -ProjectDir $root -Apply
        Assert-Topic03 ($result.ExitCode -eq 0) "full install exited $($result.ExitCode): $($result.Output)"
        foreach ($entry in $protectedFiles.GetEnumerator()) {
            $actual = Get-Content -Raw -LiteralPath (Join-Path $dest $entry.Key)
            Assert-Topic03 ($actual -ceq $entry.Value) "protected file changed: $($entry.Key)"
        }
    }

    Invoke-Topic03Test 'project config exposes only the selected role and effort contract' {
        $root = New-Topic03InstallerRoot
        $result = Invoke-Topic03Installer -Target project -ProjectDir $root -Components @('config') -Apply
        Assert-Topic03 ($result.ExitCode -eq 0) "config install exited $($result.ExitCode): $($result.Output)"
        $config = Get-Content -Raw -LiteralPath (Join-Path $root '.omp\config.yml')
        foreach ($literal in @(
            'cheap-scout: omniroute/ds/deepseek-v4-flash:xhigh',
            'worker: omniroute/codex/gpt-5.6-sol:high',
            'reviewer: omniroute/codex/gpt-5.6-sol:xhigh',
            'modelFallback: true',
            'usageAwareFallback: false',
            'omniroute/ds/deepseek-v4-pro:xhigh',
            'enableEffort: true',
            'maxEffort: xhigh'
        )) {
            Assert-Topic03 ($config.IndexOf($literal, [StringComparison]::Ordinal) -ge 0) `
                "installed config lacks: $literal"
        }
        foreach ($retired in @('tech-lead:', 'explorer:', 'implementer:', 'verifier:')) {
            Assert-Topic03 ($config.IndexOf($retired, [StringComparison]::OrdinalIgnoreCase) -lt 0) `
                "installed config retains retired role: $retired"
        }
    }

    Invoke-Topic03Test 'rollback restores the pre-install agent set' {
        $root = New-Topic03InstallerRoot
        $agents = Join-Path $root '.omp\agents'
        [void](New-Item -ItemType Directory -Path $agents -Force)
        foreach ($name in @('tech-lead.md', 'explorer.md', 'implementer.md', 'verifier.md', 'custom-agent.md')) {
            Set-Content -LiteralPath (Join-Path $agents $name) -Value "before $name"
        }

        $install = Invoke-Topic03Installer -Target project -ProjectDir $root -Components @('agents') -Apply
        Assert-Topic03 ($install.ExitCode -eq 0) "agent install exited $($install.ExitCode): $($install.Output)"
        $backup = @(Get-ChildItem -LiteralPath $root -Directory -Filter '.omp.backup-*')
        Assert-Topic03 ($backup.Count -eq 1) "expected one backup, found $($backup.Count)"

        $rollback = Invoke-Topic03Rollback -ProjectDir $root -BackupDir $backup[0].FullName
        Assert-Topic03 ($rollback.ExitCode -eq 0) "rollback exited $($rollback.ExitCode): $($rollback.Output)"
        Assert-Topic03FileSet -Directory $agents `
            -Expected @('custom-agent.md', 'explorer.md', 'implementer.md', 'tech-lead.md', 'verifier.md')
    }

    Invoke-Topic03Test 'user config omits per-spawn effort unless explicitly enabled' {
        $userRoot = New-Topic03InstallerRoot
        $previousUserProfile = $env:USERPROFILE
        try {
            $env:USERPROFILE = $userRoot
            $result = Invoke-Topic03Installer -Target user -Components @('config') -Apply
            Assert-Topic03 ($result.ExitCode -eq 0) "user config install exited $($result.ExitCode): $($result.Output)"
            $config = Get-Content -Raw -LiteralPath (Join-Path $userRoot '.omp\agent\config.yml')
            Assert-Topic03 ($config.IndexOf('enableEffort: true', [StringComparison]::Ordinal) -lt 0) `
                'user config enabled task.enableEffort without opt-in'
            Assert-Topic03 ($config.IndexOf('maxEffort: xhigh', [StringComparison]::Ordinal) -lt 0) `
                'user config enabled task.maxEffort without opt-in'
        } finally {
            $env:USERPROFILE = $previousUserProfile
        }
    }

    Invoke-Topic03Test 'user config accepts explicit per-spawn effort opt-in' {
        $userRoot = New-Topic03InstallerRoot
        $previousUserProfile = $env:USERPROFILE
        try {
            $env:USERPROFILE = $userRoot
            $result = Invoke-Topic03Installer -Target user -Components @('config') -Apply -EnablePerSpawnEffort
            Assert-Topic03 ($result.ExitCode -eq 0) "user opt-in install exited $($result.ExitCode): $($result.Output)"
            $config = Get-Content -Raw -LiteralPath (Join-Path $userRoot '.omp\agent\config.yml')
            Assert-Topic03 ($config.IndexOf('enableEffort: true', [StringComparison]::Ordinal) -ge 0) `
                'user config did not enable task.enableEffort after opt-in'
            Assert-Topic03 ($config.IndexOf('maxEffort: xhigh', [StringComparison]::Ordinal) -ge 0) `
                'user config did not enable task.maxEffort after opt-in'
        } finally {
            $env:USERPROFILE = $previousUserProfile
        }
    }
} finally {
    Remove-Topic03InstallerRoots
}

Write-Host "Topic 03 installer tests: $($script:passed) PASS, $($script:failed) FAIL"
if ($script:failed -gt 0) { exit 1 }
exit 0
