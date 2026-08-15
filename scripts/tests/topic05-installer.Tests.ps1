#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$installerPath = Join-Path $repositoryRoot 'scripts\install-template.ps1'
$uninstallerPath = Join-Path $repositoryRoot 'scripts\uninstall-template.ps1'
$libraryPath = Join-Path $repositoryRoot 'scripts\lib\topic05-codegraph.ps1'
$componentManifestPath = Join-Path $repositoryRoot 'template\.omp\codegraph\component-manifest.json'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-topic05-installer-'
$script:Roots = [Collections.Generic.List[string]]::new()
$script:Assertions = 0
. $libraryPath

function Assert-Topic05Installer {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function New-Topic05InstallerRoot {
    $root = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $root)
    [void]$script:Roots.Add([IO.Path]::GetFullPath($root))
    return $root
}

function Get-Topic05InstallerFingerprint {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return '<absent>' }
    $root = [IO.Path]::GetFullPath($LiteralPath).TrimEnd('\', '/')
    return @(
        Get-ChildItem -LiteralPath $root -Force -Recurse | Sort-Object FullName | ForEach-Object {
            $relative = [IO.Path]::GetRelativePath($root, $_.FullName).Replace('\', '/')
            if ($_.PSIsContainer) { "D|$relative" }
            else { "F|$relative|$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)" }
        }
    ) -join "`n"
}

function Invoke-Topic05InstallerChild {
    param(
        [Parameter(Mandatory)][string]$ProjectDir,
        [Parameter(Mandatory)][string]$UserProfile,
        [AllowNull()][string[]]$Components = $null,
        [switch]$Apply,
        [string]$ArtifactPath,
        [switch]$AllowDownload,
        [string]$ScriptPath = $installerPath
    )

    $arguments = @('-NoProfile', '-File', $ScriptPath, '-Target', 'project', '-ProjectDir', $ProjectDir)
    if ($null -ne $Components) { $arguments += @('-Components', ($Components -join ',')) }
    if ($Apply) { $arguments += '-DryRun:$false' }
    if ($ArtifactPath) { $arguments += @('-CodeGraphArtifactPath', $ArtifactPath) }
    if ($AllowDownload) { $arguments += '-AllowCodeGraphDownload' }
    $oldProfile = $env:USERPROFILE
    try {
        $env:USERPROFILE = $UserProfile
        $output = @(& pwsh @arguments 2>&1)
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join [Environment]::NewLine) }
    } finally {
        $env:USERPROFILE = $oldProfile
    }
}

function Invoke-Topic05UninstallerChild {
    param(
        [Parameter(Mandatory)][string]$ProjectDir,
        [Parameter(Mandatory)][string]$UserProfile,
        [Parameter(Mandatory)][string]$BackupDir,
        [switch]$Apply,
        [switch]$StrictCaller,
        [string]$ScriptPath = $uninstallerPath
    )

    $arguments = @(
        '-NoProfile', '-File', $ScriptPath, '-Target', 'project', '-ProjectDir', $ProjectDir,
        '-BackupDir', $BackupDir
    )
    if ($Apply) { $arguments += '-DryRun:$false' }
    $oldProfile = $env:USERPROFILE
    try {
        $env:USERPROFILE = $UserProfile
        if ($StrictCaller) {
            try {
                if ($Apply) {
                    $output = @(& $ScriptPath -Target project -ProjectDir $ProjectDir `
                        -BackupDir $BackupDir -DryRun:$false 2>&1)
                } else {
                    $output = @(& $ScriptPath -Target project -ProjectDir $ProjectDir `
                        -BackupDir $BackupDir 2>&1)
                }
                $exitCode = 0
            } catch {
                $output = @($_)
                $exitCode = 1
            }
        } else {
            $output = @(& pwsh @arguments 2>&1)
            $exitCode = $LASTEXITCODE
        }
        return [pscustomobject]@{ ExitCode = $exitCode; Output = ($output -join [Environment]::NewLine) }
    } finally {
        $env:USERPROFILE = $oldProfile
    }
}

function New-Topic05InstallerFixture {
    param([Parameter(Mandatory)][string]$Root)

    $sourceRoot = Join-Path $Root 'source'
    foreach ($directory in @('scripts\lib', 'template\.omp\state', 'template\.omp\codegraph', 'template\.omp\tools')) {
        [void](New-Item -ItemType Directory -Path (Join-Path $sourceRoot $directory) -Force)
    }
    Copy-Item -LiteralPath $installerPath -Destination (Join-Path $sourceRoot 'scripts\install-template.ps1')
    Copy-Item -LiteralPath $uninstallerPath -Destination (Join-Path $sourceRoot 'scripts\uninstall-template.ps1')
    Copy-Item -LiteralPath $libraryPath -Destination (Join-Path $sourceRoot 'scripts\lib\topic05-codegraph.ps1')
    Copy-Item -Path (Join-Path $repositoryRoot 'template\.omp\state\*') `
        -Destination (Join-Path $sourceRoot 'template\.omp\state') -Recurse
    Copy-Item -Path (Join-Path $repositoryRoot 'template\.omp\codegraph\*') `
        -Destination (Join-Path $sourceRoot 'template\.omp\codegraph') -Recurse
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'template\.omp\tools\codegraph-retrieve.js') `
        -Destination (Join-Path $sourceRoot 'template\.omp\tools\codegraph-retrieve.js')

    $platform = Get-Topic05CodeGraphPlatform
    $archiveParent = Join-Path $Root 'archive'
    $bundleTop = Join-Path $archiveParent "codegraph-$platform"
    foreach ($directory in @('bin', 'lib\dist\bin')) {
        [void](New-Item -ItemType Directory -Path (Join-Path $bundleTop $directory) -Force)
    }
    $launcherName = if ($platform.StartsWith('win32-', [StringComparison]::Ordinal)) {
        'codegraph.cmd'
    } else { 'codegraph' }
    $nodeName = if ($platform.StartsWith('win32-', [StringComparison]::Ordinal)) { 'node.exe' } else { 'node' }
    [IO.File]::WriteAllText(
        (Join-Path $bundleTop "bin\$launcherName"),
        'fake launcher',
        [Text.UTF8Encoding]::new($false)
    )
    if (-not $platform.StartsWith('win32-', [StringComparison]::Ordinal)) {
        throw 'Topic 05 installer fixture currently requires Windows.'
    }
    $fakeNodeSource = @"
public static class FakeCodeGraphNode {
    public static int Main(string[] args) {
        System.Console.WriteLine("1.5.0");
        return 0;
    }
}
"@
    $fakeNodeSourcePath = Join-Path $Root 'fake-codegraph-node.cs'
    [IO.File]::WriteAllText($fakeNodeSourcePath, $fakeNodeSource, [Text.UTF8Encoding]::new($false))
    $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    $nodePath = Join-Path $bundleTop $nodeName
    $compilerOutput = @(& $compiler /nologo /target:exe "/out:$nodePath" $fakeNodeSourcePath 2>&1)
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $nodePath -PathType Leaf)) {
        throw "Fake CodeGraph node compilation failed: $($compilerOutput -join ' ')"
    }
    [IO.File]::WriteAllText(
        (Join-Path $bundleTop 'lib\package.json'),
        '{"name":"codegraph","version":"1.5.0"}',
        [Text.UTF8Encoding]::new($false)
    )
    [IO.File]::WriteAllText(
        (Join-Path $bundleTop 'lib\dist\index.js'),
        'export const fake = true;',
        [Text.UTF8Encoding]::new($false)
    )
    [IO.File]::WriteAllText(
        (Join-Path $bundleTop 'lib\dist\bin\codegraph.js'),
        'console.log("1.5.0");',
        [Text.UTF8Encoding]::new($false)
    )
    $artifactPath = Join-Path $Root "codegraph-$platform.zip"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory(
        $archiveParent,
        $artifactPath,
        [IO.Compression.CompressionLevel]::Optimal,
        $false
    )

    $lockPath = Join-Path $sourceRoot 'template\.omp\codegraph\upstream-lock.json'
    $lock = Get-Content -Raw -LiteralPath $lockPath -Encoding UTF8 | ConvertFrom-Json
    $artifact = @($lock.artifacts | Where-Object platform -CEQ $platform)[0]
    $artifact.size = [long](Get-Item -LiteralPath $artifactPath).Length
    $artifact.sha256 = Get-Topic05CodeGraphSha256 -LiteralPath $artifactPath
    Write-Topic05CodeGraphJson -LiteralPath $lockPath -Value $lock

    $manifestPath = Join-Path $sourceRoot 'template\.omp\codegraph\component-manifest.json'
    $manifest = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8 | ConvertFrom-Json
    $lockHash = Get-Topic05CodeGraphSha256 -LiteralPath $lockPath
    $manifest.upstream_lock.sha256 = $lockHash
    @($manifest.files | Where-Object path -CEQ '.omp/codegraph/upstream-lock.json')[0].sha256 = $lockHash
    Write-Topic05CodeGraphJson -LiteralPath $manifestPath -Value $manifest

    return [pscustomobject]@{
        Root = $sourceRoot
        Installer = Join-Path $sourceRoot 'scripts\install-template.ps1'
        Uninstaller = Join-Path $sourceRoot 'scripts\uninstall-template.ps1'
        Artifact = $artifactPath
        Lock = $lockPath
        Manifest = $manifestPath
    }
}

try {
    Assert-Topic05Installer (Test-Path -LiteralPath $componentManifestPath -PathType Leaf) `
        'CodeGraph component manifest is missing.'

    $root = New-Topic05InstallerRoot
    $project = Join-Path $root 'project'
    $profile = Join-Path $root 'profile'
    [void](New-Item -ItemType Directory -Path (Join-Path $project '.omp') -Force)
    [void](New-Item -ItemType Directory -Path $profile -Force)
    [IO.File]::WriteAllText((Join-Path $project '.omp\sentinel.txt'), 'unchanged', [Text.UTF8Encoding]::new($false))
    $before = Get-Topic05InstallerFingerprint $project
    $result = Invoke-Topic05InstallerChild -ProjectDir $project -UserProfile $profile
    Assert-Topic05Installer ($result.ExitCode -eq 0) "Default dry-run failed: $($result.Output)"
    Assert-Topic05Installer ($result.Output -notmatch '(?i)codegraph') 'Default installation must not mention CodeGraph.'
    Assert-Topic05Installer ((Get-Topic05InstallerFingerprint $project) -ceq $before) 'Default dry-run changed target bytes.'
    Assert-Topic05Installer (-not (Test-Path -LiteralPath (Join-Path $profile '.omp\cache\codegraph'))) `
        'Default installation created a CodeGraph cache.'

    $graphDryRoot = New-Topic05InstallerRoot
    $graphProject = Join-Path $graphDryRoot 'project'
    $graphProfile = Join-Path $graphDryRoot 'profile'
    [void](New-Item -ItemType Directory -Path $graphProject -Force)
    [void](New-Item -ItemType Directory -Path $graphProfile -Force)
    $graphBefore = Get-Topic05InstallerFingerprint $graphProject
    $graphDry = Invoke-Topic05InstallerChild -ProjectDir $graphProject -UserProfile $graphProfile `
        -Components @('state', 'codegraph')
    Assert-Topic05Installer ($graphDry.ExitCode -eq 0) "CodeGraph dry-run failed: $($graphDry.Output)"
    foreach ($literal in @('state dependency', 'bundle receipt', '.omp\codegraph',
            '.omp\tools\codegraph-retrieve.js', 'runtime.json', 'install-record.json')) {
        Assert-Topic05Installer ($graphDry.Output.IndexOf($literal, [StringComparison]::OrdinalIgnoreCase) -ge 0) `
            "CodeGraph dry-run did not list $literal."
    }
    Assert-Topic05Installer ((Get-Topic05InstallerFingerprint $graphProject) -ceq $graphBefore) `
        'CodeGraph dry-run changed target bytes.'
    Assert-Topic05Installer (-not (Test-Path -LiteralPath (Join-Path $graphProfile '.omp\cache\codegraph'))) `
        'CodeGraph dry-run created managed cache bytes.'

    $missingStateRoot = New-Topic05InstallerRoot
    $missingStateProject = Join-Path $missingStateRoot 'project'
    $missingStateProfile = Join-Path $missingStateRoot 'profile'
    [void](New-Item -ItemType Directory -Path $missingStateProject -Force)
    [void](New-Item -ItemType Directory -Path $missingStateProfile -Force)
    $missingStateBefore = Get-Topic05InstallerFingerprint $missingStateProject
    $missingState = Invoke-Topic05InstallerChild -ProjectDir $missingStateProject -UserProfile $missingStateProfile `
        -Components @('codegraph') -Apply
    Assert-Topic05Installer ($missingState.ExitCode -ne 0 -and $missingState.Output -match '(?i)state') `
        'CodeGraph without selected or installed compatible state must fail clearly.'
    Assert-Topic05Installer ((Get-Topic05InstallerFingerprint $missingStateProject) -ceq $missingStateBefore) `
        'Missing state dependency mutated the target.'

    $invalidInputRoot = New-Topic05InstallerRoot
    $invalidProject = Join-Path $invalidInputRoot 'project'
    $invalidProfile = Join-Path $invalidInputRoot 'profile'
    [void](New-Item -ItemType Directory -Path $invalidProject -Force)
    [void](New-Item -ItemType Directory -Path $invalidProfile -Force)
    $bogusArtifact = Join-Path $invalidInputRoot 'bogus.zip'
    [IO.File]::WriteAllText($bogusArtifact, 'not an artifact', [Text.UTF8Encoding]::new($false))
    $mutual = Invoke-Topic05InstallerChild -ProjectDir $invalidProject -UserProfile $invalidProfile `
        -Components @('state', 'codegraph') -Apply -ArtifactPath $bogusArtifact -AllowDownload
    Assert-Topic05Installer ($mutual.ExitCode -ne 0 -and $mutual.Output -match '(?i)mutually exclusive|exclusive') `
        'Offline artifact plus download permission must be rejected.'
    Assert-Topic05Installer (-not (Test-Path -LiteralPath (Join-Path $invalidProject '.omp'))) `
        'Mutually exclusive acquisition inputs mutated the target.'

    $missingArtifact = Invoke-Topic05InstallerChild -ProjectDir $invalidProject -UserProfile $invalidProfile `
        -Components @('state', 'codegraph') -Apply
    Assert-Topic05Installer ($missingArtifact.ExitCode -ne 0 -and $missingArtifact.Output -match '(?i)artifact|download') `
        'Apply without artifact or explicit download permission must fail clearly.'
    Assert-Topic05Installer (-not (Test-Path -LiteralPath (Join-Path $invalidProfile '.omp\cache\codegraph'))) `
        'Missing acquisition input touched managed cache.'

    $fixtureRoot = New-Topic05InstallerRoot
    $fixture = New-Topic05InstallerFixture -Root $fixtureRoot

    $freshProject = Join-Path $fixtureRoot 'fresh-project'
    $freshProfile = Join-Path $fixtureRoot 'fresh-profile'
    [void](New-Item -ItemType Directory -Path $freshProject -Force)
    [void](New-Item -ItemType Directory -Path $freshProfile -Force)
    $freshInstall = Invoke-Topic05InstallerChild -ProjectDir $freshProject -UserProfile $freshProfile `
        -Components @('state', 'codegraph') -Apply -ArtifactPath $fixture.Artifact `
        -ScriptPath $fixture.Installer
    Assert-Topic05Installer ($freshInstall.ExitCode -eq 0) `
        "Offline state+CodeGraph installation failed: $($freshInstall.Output)"
    $freshOmp = Join-Path $freshProject '.omp'
    foreach ($relative in @(
            'state\manifest.json', 'codegraph\component-manifest.json', 'codegraph\runtime.json',
            'codegraph\install-record.json', 'tools\codegraph-retrieve.js')) {
        Assert-Topic05Installer (Test-Path -LiteralPath (Join-Path $freshOmp $relative) -PathType Leaf) `
            "Offline installation omitted $relative."
    }
    $freshRuntimePath = Join-Path $freshOmp 'codegraph\runtime.json'
    $freshRecordPath = Join-Path $freshOmp 'codegraph\install-record.json'
    $freshRuntime = Get-Content -Raw -LiteralPath $freshRuntimePath -Encoding UTF8 | ConvertFrom-Json
    $freshRecord = Get-Content -Raw -LiteralPath $freshRecordPath -Encoding UTF8 | ConvertFrom-Json
    Assert-Topic05Installer ($freshRuntime.record_type -ceq 'codegraph_target_runtime' -and
        $freshRuntime.target_omp -ceq [IO.Path]::GetFullPath($freshOmp)) `
        'Installed runtime identity or canonical target is wrong.'
    Assert-Topic05Installer ($freshRecord.record_type -ceq 'codegraph_install_record' -and
        $freshRecord.retained_cache_policy -ceq 'retain_and_report') `
        'Installed record identity or retention policy is wrong.'
    Assert-Topic05Installer ($freshRecord.runtime_sha256 -ceq
        (Get-Topic05CodeGraphSha256 -LiteralPath $freshRuntimePath)) `
        'Install record did not bind the exact runtime bytes.'
    Assert-Topic05Installer (Test-Path -LiteralPath $freshRecord.receipt_path -PathType Leaf) `
        'Offline installation did not publish a verified bundle receipt.'
    [string[]]$recordPaths = @($freshRecord.installed_paths)
    [string[]]$sortedRecordPaths = @($recordPaths)
    [Array]::Sort($sortedRecordPaths, [StringComparer]::Ordinal)
    Assert-Topic05Installer (($recordPaths -join '|') -ceq ($sortedRecordPaths -join '|') -and
        $recordPaths.Count -eq 9) 'Installed path journal is not sorted and exact.'

    $existingProject = Join-Path $fixtureRoot 'existing-project'
    $existingProfile = Join-Path $fixtureRoot 'existing-profile'
    $existingOmp = Join-Path $existingProject '.omp'
    [void](New-Item -ItemType Directory -Path $existingOmp -Force)
    [void](New-Item -ItemType Directory -Path (Join-Path $existingOmp 'state') -Force)
    [void](New-Item -ItemType Directory -Path $existingProfile -Force)
    Copy-Item -Path (Join-Path $fixture.Root 'template\.omp\state\*') `
        -Destination (Join-Path $existingOmp 'state') -Recurse -Force
    [IO.File]::WriteAllText((Join-Path $existingOmp 'sentinel.txt'), 'before', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $existingOmp 'models.yml'), 'protected', [Text.UTF8Encoding]::new($false))
    $existingBefore = Get-Topic05InstallerFingerprint $existingOmp
    $existingInstall = Invoke-Topic05InstallerChild -ProjectDir $existingProject -UserProfile $existingProfile `
        -Components @('codegraph') -Apply -ArtifactPath $fixture.Artifact -ScriptPath $fixture.Installer
    Assert-Topic05Installer ($existingInstall.ExitCode -eq 0) `
        "Installed compatible state did not satisfy CodeGraph: $($existingInstall.Output)"
    Assert-Topic05Installer ((Get-Content -Raw -LiteralPath (Join-Path $existingOmp 'models.yml')) -ceq 'protected') `
        'CodeGraph installation changed a protected pre-existing file.'
    $existingRecord = Get-Content -Raw -LiteralPath (Join-Path $existingOmp 'codegraph\install-record.json') `
        -Encoding UTF8 | ConvertFrom-Json
    Assert-Topic05Installer (Test-Path -LiteralPath $existingRecord.backup_dir -PathType Container) `
        'CodeGraph installation did not create its rollback backup.'
    $indexPath = Join-Path $existingProject '.codegraph'
    [void](New-Item -ItemType Directory -Path $indexPath -Force)
    [IO.File]::WriteAllText((Join-Path $indexPath 'codegraph.db'), 'retained', [Text.UTF8Encoding]::new($false))
    $uninstall = Invoke-Topic05UninstallerChild -ProjectDir $existingProject -UserProfile $existingProfile `
        -BackupDir $existingRecord.backup_dir -Apply -ScriptPath $fixture.Uninstaller
    Assert-Topic05Installer ($uninstall.ExitCode -eq 0) "CodeGraph rollback failed: $($uninstall.Output)"
    Assert-Topic05Installer ((Get-Topic05InstallerFingerprint $existingOmp) -ceq $existingBefore) `
        'Rollback did not restore the exact pre-install target.'
    Assert-Topic05Installer (-not (Test-Path -LiteralPath (Join-Path $existingOmp 'codegraph'))) `
        'Rollback retained installed CodeGraph adapter or records.'
    Assert-Topic05Installer (Test-Path -LiteralPath $existingRecord.bundle_root -PathType Container) `
        'Rollback deleted the verified shared bundle.'
    Assert-Topic05Installer ((Get-Content -Raw -LiteralPath (Join-Path $indexPath 'codegraph.db')) -ceq 'retained') `
        'Rollback deleted the project CodeGraph index.'
    foreach ($retainedPath in @([string]$existingRecord.bundle_root, [string]$indexPath)) {
        Assert-Topic05Installer ($uninstall.Output.IndexOf($retainedPath, [StringComparison]::OrdinalIgnoreCase) -ge 0) `
            "Rollback did not report retained path $retainedPath."
    }

    $singleProject = Join-Path $fixtureRoot 'single-file-rollback-project'
    $singleProfile = Join-Path $fixtureRoot 'single-file-rollback-profile'
    $singleOmp = Join-Path $singleProject '.omp'
    $singleBackup = Join-Path $singleProject '.omp.backup-single'
    [void](New-Item -ItemType Directory -Path $singleOmp -Force)
    [void](New-Item -ItemType Directory -Path $singleBackup -Force)
    [void](New-Item -ItemType Directory -Path $singleProfile -Force)
    [IO.File]::WriteAllText((Join-Path $singleOmp 'installed.txt'), 'installed', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $singleBackup 'sentinel.txt'), 'before', [Text.UTF8Encoding]::new($false))
    $singleRollback = Invoke-Topic05UninstallerChild -ProjectDir $singleProject -UserProfile $singleProfile `
        -BackupDir $singleBackup -Apply -StrictCaller -ScriptPath $fixture.Uninstaller
    Assert-Topic05Installer ($singleRollback.ExitCode -eq 0) `
        "Strict-caller single-file rollback failed: $($singleRollback.Output)"
    Assert-Topic05Installer ((Get-Content -Raw -LiteralPath (Join-Path $singleOmp 'sentinel.txt')) -ceq 'before') `
        'Strict-caller single-file rollback did not restore the only backup file.'

    $rollbackProject = Join-Path $fixtureRoot 'rollback-project'
    $rollbackOmp = Join-Path $rollbackProject '.omp'
    [void](New-Item -ItemType Directory -Path $rollbackOmp -Force)
    [void](New-Item -ItemType Directory -Path (Join-Path $rollbackOmp 'state') -Force)
    Copy-Item -Path (Join-Path $fixture.Root 'template\.omp\state\*') `
        -Destination (Join-Path $rollbackOmp 'state') -Recurse -Force
    [IO.File]::WriteAllText((Join-Path $rollbackOmp 'sentinel.txt'), 'rollback-boundary', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $rollbackOmp 'tools'), 'blocks-final-tool-activation', [Text.UTF8Encoding]::new($false))
    $rollbackBefore = Get-Topic05InstallerFingerprint $rollbackOmp
    $activationFailure = Invoke-Topic05InstallerChild -ProjectDir $rollbackProject -UserProfile $existingProfile `
        -Components @('codegraph') -Apply -ScriptPath $fixture.Installer
    Assert-Topic05Installer ($activationFailure.ExitCode -ne 0 -and
        $activationFailure.Output -match '(?i)restored exactly') `
        'Final activation failure did not report transactional rollback.'
    Assert-Topic05Installer ((Get-Topic05InstallerFingerprint $rollbackOmp) -ceq $rollbackBefore) `
        'Final activation failure did not restore exact target bytes.'
    Assert-Topic05Installer (Test-Path -LiteralPath $existingRecord.bundle_root -PathType Container) `
        'Transactional rollback deleted an already valid shared bundle.'

    $installerSource = [IO.File]::ReadAllText($fixture.Installer, [Text.Encoding]::UTF8)
    $activationNeedle = '        $applied++'
    Assert-Topic05Installer ($installerSource.IndexOf(
            $activationNeedle,
            [StringComparison]::Ordinal
        ) -ge 0) 'Installer activation boundary marker is unavailable for fault injection.'
    foreach ($activationBoundary in 1..9) {
        $faultScript = Join-Path $fixture.Root "scripts\install-template-fail-$activationBoundary.ps1"
        $faultSource = $installerSource.Replace(
            $activationNeedle,
            "$activationNeedle`r`n        if (`$applied -eq $activationBoundary) { throw 'fixture activation interruption $activationBoundary' }"
        )
        [IO.File]::WriteAllText($faultScript, $faultSource, [Text.UTF8Encoding]::new($false))
        $boundaryProject = Join-Path $fixtureRoot "boundary-project-$activationBoundary"
        $boundaryOmp = Join-Path $boundaryProject '.omp'
        [void](New-Item -ItemType Directory -Path (Join-Path $boundaryOmp 'state') -Force)
        Copy-Item -Path (Join-Path $fixture.Root 'template\.omp\state\*') `
            -Destination (Join-Path $boundaryOmp 'state') -Recurse -Force
        [IO.File]::WriteAllText(
            (Join-Path $boundaryOmp 'sentinel.txt'),
            "boundary-$activationBoundary",
            [Text.UTF8Encoding]::new($false)
        )
        $boundaryBefore = Get-Topic05InstallerFingerprint $boundaryOmp
        $boundaryResult = Invoke-Topic05InstallerChild -ProjectDir $boundaryProject `
            -UserProfile $existingProfile -Components @('codegraph') -Apply -ScriptPath $faultScript
        Assert-Topic05Installer ($boundaryResult.ExitCode -ne 0 -and
            $boundaryResult.Output -match '(?i)restored exactly') `
            "Activation boundary $activationBoundary did not trigger transactional rollback."
        Assert-Topic05Installer ((Get-Topic05InstallerFingerprint $boundaryOmp) -ceq $boundaryBefore) `
            "Activation boundary $activationBoundary did not restore exact target bytes."
    }

    $badArtifactRoot = New-Topic05InstallerRoot
    $badArtifactProject = Join-Path $badArtifactRoot 'project'
    $badArtifactProfile = Join-Path $badArtifactRoot 'profile'
    [void](New-Item -ItemType Directory -Path $badArtifactProject -Force)
    [void](New-Item -ItemType Directory -Path $badArtifactProfile -Force)
    $badArtifact = Join-Path $badArtifactRoot 'tampered.zip'
    Copy-Item -LiteralPath $fixture.Artifact -Destination $badArtifact
    [IO.File]::AppendAllText($badArtifact, 'tamper', [Text.UTF8Encoding]::new($false))
    $badArtifactResult = Invoke-Topic05InstallerChild -ProjectDir $badArtifactProject `
        -UserProfile $badArtifactProfile -Components @('state', 'codegraph') -Apply `
        -ArtifactPath $badArtifact -ScriptPath $fixture.Installer
    Assert-Topic05Installer ($badArtifactResult.ExitCode -ne 0 -and
        $badArtifactResult.Output -match '(?i)artifact (size|digest) mismatch') `
        'Tampered offline artifact did not fail closed.'
    Assert-Topic05Installer (-not (Test-Path -LiteralPath (Join-Path $badArtifactProject '.omp')) -and
        -not (Test-Path -LiteralPath (Join-Path $badArtifactProfile '.omp\cache\codegraph'))) `
        'Tampered offline artifact mutated target or managed cache.'

    $badStateRoot = New-Topic05InstallerRoot
    $badStateProject = Join-Path $badStateRoot 'project'
    $badStateProfile = Join-Path $badStateRoot 'profile'
    [void](New-Item -ItemType Directory -Path (Join-Path $badStateProject '.omp\state') -Force)
    [void](New-Item -ItemType Directory -Path $badStateProfile -Force)
    Copy-Item -Path (Join-Path $fixture.Root 'template\.omp\state\*') `
        -Destination (Join-Path $badStateProject '.omp\state') -Recurse -Force
    [IO.File]::AppendAllText(
        (Join-Path $badStateProject '.omp\state\manifest.json'),
        "`n",
        [Text.UTF8Encoding]::new($false)
    )
    $badStateBefore = Get-Topic05InstallerFingerprint (Join-Path $badStateProject '.omp')
    $badStateResult = Invoke-Topic05InstallerChild -ProjectDir $badStateProject -UserProfile $badStateProfile `
        -Components @('codegraph') -Apply -ArtifactPath $fixture.Artifact -ScriptPath $fixture.Installer
    Assert-Topic05Installer ($badStateResult.ExitCode -ne 0 -and $badStateResult.Output -match '(?i)state') `
        'Incompatible installed state manifest did not fail closed.'
    Assert-Topic05Installer ((Get-Topic05InstallerFingerprint (Join-Path $badStateProject '.omp')) -ceq
        $badStateBefore) 'Incompatible installed state mutated the target.'

    $manifestOriginal = [IO.File]::ReadAllText($fixture.Manifest, [Text.Encoding]::UTF8)
    try {
        $tamperedManifest = $manifestOriginal | ConvertFrom-Json
        $tamperedManifest | Add-Member -NotePropertyName unexpected -NotePropertyValue $true
        Write-Topic05CodeGraphJson -LiteralPath $fixture.Manifest -Value $tamperedManifest
        $badManifestRoot = New-Topic05InstallerRoot
        $badManifestProject = Join-Path $badManifestRoot 'project'
        $badManifestProfile = Join-Path $badManifestRoot 'profile'
        [void](New-Item -ItemType Directory -Path $badManifestProject -Force)
        [void](New-Item -ItemType Directory -Path $badManifestProfile -Force)
        $badManifest = Invoke-Topic05InstallerChild -ProjectDir $badManifestProject `
            -UserProfile $badManifestProfile -Components @('state', 'codegraph') -Apply `
            -ArtifactPath $fixture.Artifact -ScriptPath $fixture.Installer
        Assert-Topic05Installer ($badManifest.ExitCode -ne 0 -and
            $badManifest.Output -match '(?i)unknown|properties') `
            'Tampered component manifest did not fail closed.'
        Assert-Topic05Installer (-not (Test-Path -LiteralPath (Join-Path $badManifestProject '.omp')) -and
            -not (Test-Path -LiteralPath (Join-Path $badManifestProfile '.omp\cache\codegraph'))) `
            'Tampered component manifest mutated target or cache.'
    } finally {
        [IO.File]::WriteAllText($fixture.Manifest, $manifestOriginal, [Text.UTF8Encoding]::new($false))
    }

    $lockOriginal = [IO.File]::ReadAllText($fixture.Lock, [Text.Encoding]::UTF8)
    try {
        [IO.File]::AppendAllText($fixture.Lock, "`n", [Text.UTF8Encoding]::new($false))
        $badLockRoot = New-Topic05InstallerRoot
        $badLockProject = Join-Path $badLockRoot 'project'
        $badLockProfile = Join-Path $badLockRoot 'profile'
        [void](New-Item -ItemType Directory -Path $badLockProject -Force)
        [void](New-Item -ItemType Directory -Path $badLockProfile -Force)
        $badLock = Invoke-Topic05InstallerChild -ProjectDir $badLockProject -UserProfile $badLockProfile `
            -Components @('state', 'codegraph') -Apply -ArtifactPath $fixture.Artifact `
            -ScriptPath $fixture.Installer
        Assert-Topic05Installer ($badLock.ExitCode -ne 0 -and $badLock.Output -match '(?i)lock|upstream') `
            'Tampered upstream lock digest did not fail closed.'
        Assert-Topic05Installer (-not (Test-Path -LiteralPath (Join-Path $badLockProject '.omp')) -and
            -not (Test-Path -LiteralPath (Join-Path $badLockProfile '.omp\cache\codegraph'))) `
            'Tampered upstream lock mutated target or cache.'
    } finally {
        [IO.File]::WriteAllText($fixture.Lock, $lockOriginal, [Text.UTF8Encoding]::new($false))
    }

    $receiptOriginal = [IO.File]::ReadAllText([string]$existingRecord.receipt_path, [Text.Encoding]::UTF8)
    try {
        $tamperedReceipt = $receiptOriginal | ConvertFrom-Json
        $tamperedReceipt | Add-Member -NotePropertyName unexpected -NotePropertyValue $true
        Write-Topic05CodeGraphJson -LiteralPath ([string]$existingRecord.receipt_path) -Value $tamperedReceipt
        $badReceiptProject = Join-Path $fixtureRoot 'bad-receipt-project'
        $badReceiptOmp = Join-Path $badReceiptProject '.omp'
        [void](New-Item -ItemType Directory -Path (Join-Path $badReceiptOmp 'state') -Force)
        Copy-Item -Path (Join-Path $fixture.Root 'template\.omp\state\*') `
            -Destination (Join-Path $badReceiptOmp 'state') -Recurse -Force
        $badReceiptBefore = Get-Topic05InstallerFingerprint $badReceiptOmp
        $badReceipt = Invoke-Topic05InstallerChild -ProjectDir $badReceiptProject `
            -UserProfile $existingProfile -Components @('codegraph') -Apply -ScriptPath $fixture.Installer
        Assert-Topic05Installer ($badReceipt.ExitCode -ne 0 -and
            $badReceipt.Output -match '(?i)managed cache conflict') `
            'Tampered bundle receipt did not fail closed.'
        Assert-Topic05Installer ((Get-Topic05InstallerFingerprint $badReceiptOmp) -ceq $badReceiptBefore) `
            'Tampered bundle receipt mutated the target.'
    } finally {
        [IO.File]::WriteAllText(
            [string]$existingRecord.receipt_path,
            $receiptOriginal,
            [Text.UTF8Encoding]::new($false)
        )
    }

    $invalidRuntimeProject = Join-Path $fixtureRoot 'invalid-runtime-project'
    $invalidRuntimeOmp = Join-Path $invalidRuntimeProject '.omp'
    [void](New-Item -ItemType Directory -Path (Join-Path $invalidRuntimeOmp 'state') -Force)
    Copy-Item -Path (Join-Path $fixture.Root 'template\.omp\state\*') `
        -Destination (Join-Path $invalidRuntimeOmp 'state') -Recurse -Force
    [IO.File]::WriteAllText(
        (Join-Path $invalidRuntimeOmp 'sentinel.txt'),
        'invalid-runtime-before',
        [Text.UTF8Encoding]::new($false)
    )
    $invalidRuntimeInstall = Invoke-Topic05InstallerChild -ProjectDir $invalidRuntimeProject `
        -UserProfile $existingProfile -Components @('codegraph') -Apply -ScriptPath $fixture.Installer
    Assert-Topic05Installer ($invalidRuntimeInstall.ExitCode -eq 0) `
        "Runtime mutation fixture install failed: $($invalidRuntimeInstall.Output)"
    $invalidRuntimeRecord = Get-Content -Raw `
        -LiteralPath (Join-Path $invalidRuntimeOmp 'codegraph\install-record.json') -Encoding UTF8 |
        ConvertFrom-Json
    [IO.File]::AppendAllText(
        (Join-Path $invalidRuntimeOmp 'codegraph\runtime.json'),
        "`n",
        [Text.UTF8Encoding]::new($false)
    )
    $invalidRuntimeBefore = Get-Topic05InstallerFingerprint $invalidRuntimeOmp
    $invalidRuntimeDryRun = Invoke-Topic05UninstallerChild -ProjectDir $invalidRuntimeProject `
        -UserProfile $existingProfile -BackupDir $invalidRuntimeRecord.backup_dir `
        -ScriptPath $fixture.Uninstaller
    Assert-Topic05Installer ($invalidRuntimeDryRun.ExitCode -eq 0 -and
        $invalidRuntimeDryRun.Output -match '(?i)cache paths unknown.*no cache searched') `
        'Invalid runtime record did not downgrade to an explicit unknown-cache warning.'
    Assert-Topic05Installer ((Get-Topic05InstallerFingerprint $invalidRuntimeOmp) -ceq $invalidRuntimeBefore -and
        (Test-Path -LiteralPath $existingRecord.bundle_root -PathType Container)) `
        'Invalid-record uninstall dry-run changed target or retained cache bytes.'

    Write-Host "PASS Topic 05 installer tests ($script:Assertions assertions)" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "FAIL [T05-INSTALLER] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    foreach ($root in @($script:Roots)) {
        $resolved = [IO.Path]::GetFullPath($root).TrimEnd('\', '/')
        $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
        $leaf = [IO.Path]::GetFileName($resolved)
        if ($parent -cne $tempBase -or -not $leaf.StartsWith($tempPrefix, [StringComparison]::Ordinal)) {
            throw "Refusing unsafe Topic 05 installer cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
}
