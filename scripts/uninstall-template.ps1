# Uninstall Template — restore OMP directory from backup
# Run from project root: .\scripts\uninstall-template.ps1 -BackupDir <path>

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupDir,     # Path to backup directory created by install-template.ps1

    [Parameter(Mandatory=$false)]
    [string]$Target = "project",

    [Parameter(Mandatory=$false)]
    [string]$ProjectDir = $PWD,

    [switch]$DryRun = $true
)

$ErrorActionPreference = "Stop"

if ($Target -eq "user") {
    $dest_omp = Join-Path $env:USERPROFILE ".omp\agent"
} else {
    $dest_omp = Join-Path $ProjectDir ".omp"
}
$dest_omp = [IO.Path]::GetFullPath($dest_omp).TrimEnd('\', '/')
$backupFull = [IO.Path]::GetFullPath($BackupDir).TrimEnd('\', '/')

function Get-CodeGraphRetainedPaths {
    param(
        [Parameter(Mandatory)][string]$TargetOmp,
        [Parameter(Mandatory)][string]$ExpectedBackup,
        [Parameter(Mandatory)][string]$InstallTarget,
        [Parameter(Mandatory)][string]$InstallProjectDir
    )

    try {
        $recordPath = Join-Path $TargetOmp 'codegraph\install-record.json'
        if (-not (Test-Path -LiteralPath $recordPath -PathType Leaf)) {
            throw 'install record is missing'
        }
        $record = Get-Content -Raw -LiteralPath $recordPath -Encoding UTF8 | ConvertFrom-Json
        $expectedFields = @(
            'schema_version', 'record_type', 'component', 'installed_at_utc', 'target_omp',
            'backup_dir', 'component_manifest_sha256', 'upstream_lock_sha256', 'runtime_sha256',
            'bundle_root', 'receipt_path', 'installed_paths', 'known_index_paths',
            'retained_cache_policy'
        ) | Sort-Object
        $actualFields = @($record.PSObject.Properties.Name | Sort-Object)
        if (($actualFields -join '|') -cne ($expectedFields -join '|')) {
            throw 'install record fields are not closed'
        }
        if ([int]$record.schema_version -ne 1 -or
            [string]$record.record_type -cne 'codegraph_install_record' -or
            [string]$record.component -cne 'codegraph' -or
            [string]$record.retained_cache_policy -cne 'retain_and_report') {
            throw 'install record identity is unsupported'
        }
        foreach ($name in @('component_manifest_sha256', 'upstream_lock_sha256', 'runtime_sha256')) {
            if ([string]$record.$name -cnotmatch '^[0-9a-f]{64}$') {
                throw "install record $name is invalid"
            }
        }
        $comparison = if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
                [Runtime.InteropServices.OSPlatform]::Windows
            )) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
        $recordTarget = [IO.Path]::GetFullPath([string]$record.target_omp).TrimEnd('\', '/')
        $recordBackup = [IO.Path]::GetFullPath([string]$record.backup_dir).TrimEnd('\', '/')
        if (-not $recordTarget.Equals($TargetOmp, $comparison) -or
            -not $recordBackup.Equals($ExpectedBackup, $comparison)) {
            throw 'install record target or backup does not match this rollback'
        }

        [string[]]$expectedInstalled = @(
            '.omp/codegraph/CODEGRAPH-LICENSE.txt',
            '.omp/codegraph/COMPONENT.md',
            '.omp/codegraph/codegraph-process.ps1',
            '.omp/codegraph/component-manifest.json',
            '.omp/codegraph/install-record.json',
            '.omp/codegraph/runtime.json',
            '.omp/codegraph/safe-init.mjs',
            '.omp/codegraph/upstream-lock.json',
            '.omp/tools/codegraph-retrieve.js'
        )
        [Array]::Sort($expectedInstalled, [StringComparer]::Ordinal)
        [string[]]$installed = @($record.installed_paths)
        if (($installed -join '|') -cne ($expectedInstalled -join '|')) {
            throw 'install record installed path set is not exact and sorted'
        }

        [string[]]$knownIndexes = @($record.known_index_paths)
        if ($InstallTarget -ceq 'project') {
            $expectedIndex = [IO.Path]::GetFullPath((Join-Path $InstallProjectDir '.codegraph')).TrimEnd('\', '/')
            if ($knownIndexes.Count -ne 1 -or
                -not ([IO.Path]::GetFullPath($knownIndexes[0]).TrimEnd('\', '/')).Equals(
                    $expectedIndex,
                    $comparison
                )) {
                throw 'install record project index path is not exact'
            }
            $knownIndexes = @($expectedIndex)
        } elseif ($knownIndexes.Count -ne 0) {
            throw 'install record user install cannot name project indexes'
        }

        $bundleRoot = [IO.Path]::GetFullPath([string]$record.bundle_root).TrimEnd('\', '/')
        $receiptPath = [IO.Path]::GetFullPath([string]$record.receipt_path)
        $managedRoot = [IO.Path]::GetFullPath((Join-Path $env:USERPROFILE '.omp\cache\codegraph')).TrimEnd('\', '/')
        if (-not $bundleRoot.StartsWith($managedRoot + [IO.Path]::DirectorySeparatorChar, $comparison) -or
            -not $receiptPath.Equals((Join-Path $bundleRoot 'receipt.json'), $comparison) -or
            -not (Test-Path -LiteralPath $bundleRoot -PathType Container) -or
            -not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) {
            throw 'install record retained bundle paths are invalid'
        }

        $runtimePath = Join-Path $TargetOmp 'codegraph\runtime.json'
        $manifestPath = Join-Path $TargetOmp 'codegraph\component-manifest.json'
        $lockPath = Join-Path $TargetOmp 'codegraph\upstream-lock.json'
        foreach ($path in @($runtimePath, $manifestPath, $lockPath)) {
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'installed CodeGraph record is incomplete' }
        }
        if ((Get-FileHash -LiteralPath $runtimePath -Algorithm SHA256).Hash.ToLowerInvariant() -cne
                [string]$record.runtime_sha256 -or
            (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne
                [string]$record.component_manifest_sha256 -or
            (Get-FileHash -LiteralPath $lockPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne
                [string]$record.upstream_lock_sha256) {
            throw 'installed CodeGraph record hash mismatch'
        }
        $runtime = Get-Content -Raw -LiteralPath $runtimePath -Encoding UTF8 | ConvertFrom-Json
        $runtimeFields = @(
            'schema_version', 'record_type', 'component', 'component_version', 'created_at_utc',
            'target_omp', 'component_manifest_sha256', 'upstream_lock_sha256', 'receipt_sha256',
            'upstream', 'version', 'tag', 'commit', 'platform', 'artifact_sha256', 'paths'
        ) | Sort-Object
        if ((@($runtime.PSObject.Properties.Name | Sort-Object) -join '|') -cne
            ($runtimeFields -join '|')) { throw 'runtime record fields are not closed' }
        $runtimePathFields = @(
            'bundle_root', 'receipt', 'launcher', 'node', 'library_entry', 'cli_entry',
            'safe_init', 'process_wrapper', 'pwsh'
        ) | Sort-Object
        if ((@($runtime.paths.PSObject.Properties.Name | Sort-Object) -join '|') -cne
            ($runtimePathFields -join '|')) { throw 'runtime path fields are not closed' }
        if ([string]$runtime.record_type -cne 'codegraph_target_runtime' -or
            -not ([IO.Path]::GetFullPath([string]$runtime.target_omp).TrimEnd('\', '/')).Equals(
                $TargetOmp,
                $comparison
            ) -or
            -not ([IO.Path]::GetFullPath([string]$runtime.paths.bundle_root).TrimEnd('\', '/')).Equals(
                $bundleRoot,
                $comparison
            ) -or
            -not ([IO.Path]::GetFullPath([string]$runtime.paths.receipt)).Equals($receiptPath, $comparison) -or
            [string]$runtime.component_manifest_sha256 -cne [string]$record.component_manifest_sha256 -or
            [string]$runtime.upstream_lock_sha256 -cne [string]$record.upstream_lock_sha256 -or
            (Get-FileHash -LiteralPath $receiptPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne
                [string]$runtime.receipt_sha256) {
            throw 'runtime and install records do not reconcile'
        }
        return [pscustomobject]@{
            Valid = $true
            BundleRoot = $bundleRoot
            IndexPaths = $knownIndexes
        }
    } catch {
        return [pscustomobject]@{
            Valid = $false
            Reason = $_.Exception.Message
            BundleRoot = $null
            IndexPaths = @()
        }
    }
}

function Get-AgentBoundaryRollbackStatus {
    param(
        [Parameter(Mandatory)][string]$TargetOmp,
        [Parameter(Mandatory)][string]$ExpectedBackup
    )
    $recordPath = Join-Path $TargetOmp 'contracts\install-record.json'
    $runtimePath = Join-Path $TargetOmp 'contracts\runtime.json'
    $wrapperPath = Join-Path $TargetOmp 'extensions\agent-task-boundary.js'
    $launcherPath = Join-Path $TargetOmp 'bin\omp-managed.ps1'
    $present = @(@($recordPath, $runtimePath, $wrapperPath, $launcherPath) | Where-Object {
        Test-Path -LiteralPath $_ -PathType Leaf
    }).Count -gt 0
    if (-not $present) { return [pscustomobject]@{ Present = $false; Valid = $true; Reason = $null } }

    try {
        if (-not (Test-Path -LiteralPath $recordPath -PathType Leaf)) { throw 'install record is missing' }
        $record = Get-Content -Raw -LiteralPath $recordPath -Encoding UTF8 | ConvertFrom-Json
        $expectedFields = @(
            'schema_version', 'record_type', 'component', 'component_version', 'installed_at_utc',
            'target_omp', 'backup_dir', 'component_manifest_sha256', 'runtime_sha256',
            'installed_paths', 'installed_hashes', 'generated_paths', 'operational_state_policy'
        ) | Sort-Object
        if ((@($record.PSObject.Properties.Name | Sort-Object) -join '|') -cne ($expectedFields -join '|') -or
            [int]$record.schema_version -ne 2 -or
            [string]$record.record_type -cne 'agent_boundary_install_record' -or
            [string]$record.component -cne 'agent-boundary' -or
            [string]$record.component_version -cne '2.1.0' -or
            [string]$record.operational_state_policy -cne 'retain_outside_target_omp') {
            throw 'install record identity is invalid'
        }
        foreach ($name in @('component_manifest_sha256', 'runtime_sha256')) {
            if ([string]$record.$name -cnotmatch '^[0-9a-f]{64}$') { throw "install record $name is invalid" }
        }
        $comparison = if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
                [Runtime.InteropServices.OSPlatform]::Windows
            )) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
        if (-not ([IO.Path]::GetFullPath([string]$record.target_omp).TrimEnd('\', '/')).Equals(
                $TargetOmp, $comparison
            ) -or -not ([IO.Path]::GetFullPath([string]$record.backup_dir).TrimEnd('\', '/')).Equals(
                $ExpectedBackup, $comparison
            )) {
            throw 'install record target or backup does not match this rollback'
        }

        [string[]]$expectedPaths = @(
            '.omp/bin/omp-managed.ps1',
            '.omp/contracts/agent-boundary-cli.mjs',
            '.omp/contracts/agent-boundary-core.mjs',
            '.omp/contracts/agent-boundary-schema.mjs',
            '.omp/contracts/behavior-core-schema.mjs',
            '.omp/contracts/behavior-core.mjs',
            '.omp/contracts/behavior-manifest.json',
            '.omp/contracts/component-manifest.json',
            '.omp/contracts/context-continuity-core.mjs',
            '.omp/contracts/context-continuity-schema.mjs',
            '.omp/contracts/install-record.json',
            '.omp/contracts/managed-runtime.yml',
            '.omp/contracts/managed-state-client.mjs',
            '.omp/contracts/runtime.json',
            '.omp/extensions/agent-task-boundary.js',
            '.omp/extensions/context-continuity.js'
        )
        [string[]]$installedPaths = @($record.installed_paths | ForEach-Object { [string]$_ })
        if (($installedPaths -join '|') -cne ($expectedPaths -join '|')) {
            throw 'install record path set is not exact and sorted'
        }
        if ((@($record.generated_paths) -join '|') -cne
            '.omp/contracts/runtime.json|.omp/contracts/install-record.json') {
            throw 'install record generated path set is invalid'
        }

        $hashRows = @($record.installed_hashes)
        if ($hashRows.Count -ne 15) { throw 'install record hash set is incomplete' }
        $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($row in $hashRows) {
            if ((@($row.PSObject.Properties.Name | Sort-Object) -join '|') -cne 'path|sha256' -or
                [string]$row.sha256 -cnotmatch '^[0-9a-f]{64}$' -or
                -not $seen.Add([string]$row.path) -or [string]$row.path -cnotin $expectedPaths -or
                [string]$row.path -ceq '.omp/contracts/install-record.json') {
                throw 'install record contains an invalid hash row'
            }
            $relative = ([string]$row.path).Substring('.omp/'.Length).Replace('/', '\')
            $installed = [IO.Path]::GetFullPath((Join-Path $TargetOmp $relative))
            if (-not $installed.StartsWith($TargetOmp + [IO.Path]::DirectorySeparatorChar, $comparison) -or
                -not (Test-Path -LiteralPath $installed -PathType Leaf) -or
                (Get-FileHash -LiteralPath $installed -Algorithm SHA256).Hash.ToLowerInvariant() -cne
                    [string]$row.sha256) {
                throw "installed boundary file hash mismatch: $($row.path)"
            }
        }
        if ((Get-FileHash -LiteralPath $runtimePath -Algorithm SHA256).Hash.ToLowerInvariant() -cne
                [string]$record.runtime_sha256 -or
            (Get-FileHash -LiteralPath (Join-Path $TargetOmp 'contracts\component-manifest.json') `
                -Algorithm SHA256).Hash.ToLowerInvariant() -cne [string]$record.component_manifest_sha256) {
            throw 'runtime or manifest hash does not match the install record'
        }
        return [pscustomobject]@{ Present = $true; Valid = $true; Reason = $null }
    } catch {
        return [pscustomobject]@{ Present = $true; Valid = $false; Reason = $_.Exception.Message }
    }
}

$codeGraphRetention = Get-CodeGraphRetainedPaths -TargetOmp $dest_omp -ExpectedBackup $backupFull `
    -InstallTarget $Target -InstallProjectDir $ProjectDir
$agentBoundaryRollback = Get-AgentBoundaryRollbackStatus -TargetOmp $dest_omp -ExpectedBackup $backupFull
if ($agentBoundaryRollback.Present -and -not $agentBoundaryRollback.Valid) {
    Write-Host "ERROR: Agent-boundary rollback refused: $($agentBoundaryRollback.Reason)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "OMP Workflow Template — Rollback" -ForegroundColor Cyan
Write-Host "Backup source: $BackupDir"
Write-Host "Restore target: $dest_omp"
Write-Host "Mode: $(if ($DryRun) { 'DRY-RUN' } else { 'APPLY' })" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Red" })
Write-Host "Operational agent-tasks state: RETAINED (outside installed .omp files)" -ForegroundColor Cyan
if ($agentBoundaryRollback.Present) {
    Write-Host "Agent-boundary install record: VALID; exact managed paths will be restored from backup" -ForegroundColor Cyan
}
if ($codeGraphRetention.Valid) {
    Write-Host "CodeGraph bundle retained: $($codeGraphRetention.BundleRoot)" -ForegroundColor Cyan
    foreach ($indexPath in @($codeGraphRetention.IndexPaths)) {
        Write-Host "CodeGraph index retained: $indexPath" -ForegroundColor Cyan
    }
} else {
    Write-Host "CodeGraph cache paths unknown; no cache searched or deleted. Use scripts/cleanup-codegraph.ps1 for explicit cleanup." -ForegroundColor Yellow
}
Write-Host ""

if (-not (Test-Path $BackupDir)) {
    Write-Host "ERROR: Backup directory not found: $BackupDir" -ForegroundColor Red
    exit 1
}

$backup_files = @(Get-ChildItem $BackupDir -Recurse -File)
Write-Host "Files to restore: $($backup_files.Count)"

if ($DryRun) {
    $backup_files | ForEach-Object {
        $rel = $_.FullName.Substring($BackupDir.Length).TrimStart("\")
        Write-Host "  RESTORE $rel" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "DRY-RUN complete. No changes made." -ForegroundColor Yellow
    Write-Host "To apply: .\scripts\uninstall-template.ps1 -BackupDir `"$BackupDir`" -DryRun:`$false"
    exit 0
}

# Restore: remove current .omp dir, replace with backup
$pre_rollback = $null
if (Test-Path $dest_omp) {
    $pre_rollback = "$dest_omp.pre-rollback-$(Get-Date -Format 'yyyyMMdd-HHmmssfff')"
    Write-Host "Creating pre-rollback snapshot: $pre_rollback" -ForegroundColor Cyan
    Copy-Item $dest_omp $pre_rollback -Recurse
}

Remove-Item $dest_omp -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item $BackupDir $dest_omp -Recurse

# Preserve user-owned model, credential, database, and session bytes from immediately before rollback.
if ($pre_rollback) {
    $protected = @(
        'models.yml', 'agent.db', 'agent.db-shm', 'agent.db-wal', 'sessions',
        'credentials.json', 'credentials.yml', 'auth.json'
    )
    foreach ($relative in $protected) {
        $snapshotPath = Join-Path $pre_rollback $relative
        $restorePath = Join-Path $dest_omp $relative
        if (Test-Path -LiteralPath $restorePath) {
            Remove-Item -LiteralPath $restorePath -Recurse -Force
        }
        if (Test-Path -LiteralPath $snapshotPath) {
            $parent = Split-Path $restorePath -Parent
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }
            Copy-Item -LiteralPath $snapshotPath -Destination $restorePath -Recurse
        }
    }
}

Write-Host "Rollback complete. $dest_omp restored from $BackupDir" -ForegroundColor Green
Write-Host "Operational agent-tasks state retained." -ForegroundColor Green
if ($codeGraphRetention.Valid) {
    Write-Host "CodeGraph bundle retained: $($codeGraphRetention.BundleRoot)" -ForegroundColor Green
    foreach ($indexPath in @($codeGraphRetention.IndexPaths)) {
        Write-Host "CodeGraph index retained: $indexPath" -ForegroundColor Green
    }
} else {
    Write-Host "CodeGraph cache paths unknown; no cache searched or deleted. Use scripts/cleanup-codegraph.ps1 for explicit cleanup." -ForegroundColor Yellow
}
