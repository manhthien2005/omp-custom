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

Write-Host ""
Write-Host "OMP Workflow Template — Rollback" -ForegroundColor Cyan
Write-Host "Backup source: $BackupDir"
Write-Host "Restore target: $dest_omp"
Write-Host "Mode: $(if ($DryRun) { 'DRY-RUN' } else { 'APPLY' })" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Red" })
Write-Host ""

if (-not (Test-Path $BackupDir)) {
    Write-Host "ERROR: Backup directory not found: $BackupDir" -ForegroundColor Red
    exit 1
}

$backup_files = Get-ChildItem $BackupDir -Recurse -File
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
if (Test-Path $dest_omp) {
    $pre_rollback = "$dest_omp.pre-rollback-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "Creating pre-rollback snapshot: $pre_rollback" -ForegroundColor Cyan
    Copy-Item $dest_omp $pre_rollback -Recurse
}

Remove-Item $dest_omp -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item $BackupDir $dest_omp -Recurse

Write-Host "Rollback complete. $dest_omp restored from $BackupDir" -ForegroundColor Green
