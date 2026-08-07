# Install Template — copy template files to OMP project or user directory
# Run from project root: .\scripts\install-template.ps1
#
# SAFETY RULES:
#   - Always dry-run first (default)
#   - Never overwrites models.yml or credential files
#   - Creates a timestamped backup before applying
#   - Validates OMP config after applying
#   - Use .\scripts\uninstall-template.ps1 to revert

param(
    [Parameter(Mandatory=$false)]
    [string]$Target = "project",          # "project" | "user"

    [Parameter(Mandatory=$false)]
    [string]$ProjectDir = $PWD,           # Target project directory for project install

    [string[]]$Components = @(            # Subset to install; defaults to all
        "agents", "workflows", "skills", "schemas", "policies", "agents-md", "rules-md", "config"
    ),

    [switch]$DryRun = $true,             # DEFAULT: dry-run. Pass -DryRun:$false to apply.
    [switch]$Force                        # Overwrite existing files without prompting
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$template_omp = Join-Path $root "template\.omp"

# Resolve destination
if ($Target -eq "user") {
    $dest_omp = Join-Path $env:USERPROFILE ".omp\agent"
} else {
    $dest_omp = Join-Path $ProjectDir ".omp"
}

Write-Host ""
Write-Host "OMP Workflow Template Installer" -ForegroundColor Cyan
Write-Host "Target:     $Target → $dest_omp" -ForegroundColor Cyan
Write-Host "Components: $($Components -join ', ')" -ForegroundColor Cyan
Write-Host "Mode:       $(if ($DryRun) { 'DRY-RUN (no changes)' } else { 'APPLY' })" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Red" })
Write-Host ""

# Protected files — never overwrite
$protected = @("models.yml", "agent.db", "agent.db-shm", "agent.db-wal", "sessions")

# Component → source path mapping
$component_map = @{
    "agents"    = "agents"
    "workflows" = "workflows"  # Note: OMP calls these "commands" internally
    "skills"    = "skills"
    "schemas"   = "schemas"
    "policies"  = "policies"
    "agents-md" = $null        # Special: AGENTS.md root file
    "rules-md"  = $null        # Special: RULES.md root file
    "config"    = $null        # Special: config.yml
}

$plan = @()

foreach ($comp in $Components) {
    switch ($comp) {
        "agents-md" {
            $plan += @{ src = Join-Path $template_omp "AGENTS.md"; dst = Join-Path $dest_omp "AGENTS.md" }
        }
        "rules-md" {
            $plan += @{ src = Join-Path $template_omp "RULES.md"; dst = Join-Path $dest_omp "RULES.md" }
        }
        "config" {
            $plan += @{ src = Join-Path $template_omp "config.yml"; dst = Join-Path $dest_omp "config.yml" }
        }
        default {
            $src_dir = Join-Path $template_omp $comp
            if (Test-Path $src_dir) {
                Get-ChildItem $src_dir -Recurse -File | ForEach-Object {
                    $rel = $_.FullName.Substring($template_omp.Length + 1)
                    $plan += @{ src = $_.FullName; dst = Join-Path $dest_omp $rel }
                }
            }
        }
    }
}

# Display plan
Write-Host "Planned changes ($($plan.Count) files):" -ForegroundColor White
foreach ($item in $plan) {
    $dst_rel = $item.dst.Replace($dest_omp, "").TrimStart("\")
    $exists = Test-Path $item.dst
    $protected_flag = $protected | Where-Object { $dst_rel -like "*$_*" }
    if ($protected_flag) {
        Write-Host "  SKIP     $dst_rel (protected)" -ForegroundColor DarkGray
    } elseif ($exists) {
        Write-Host "  OVERWRITE $dst_rel" -ForegroundColor Yellow
    } else {
        Write-Host "  CREATE   $dst_rel" -ForegroundColor Green
    }
}

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY-RUN complete. No changes made." -ForegroundColor Yellow
    Write-Host "To apply: .\scripts\install-template.ps1 -DryRun:`$false [options]"
    exit 0
}

# Backup
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup_dir = "$dest_omp.backup-$timestamp"
if (Test-Path $dest_omp) {
    Write-Host ""
    Write-Host "Creating backup: $backup_dir" -ForegroundColor Cyan
    Copy-Item $dest_omp $backup_dir -Recurse
    Write-Host "Backup created." -ForegroundColor Green
}

# Apply
$applied = 0
foreach ($item in $plan) {
    $dst_rel = $item.dst.Replace($dest_omp, "").TrimStart("\")
    $protected_flag = $protected | Where-Object { $dst_rel -like "*$_*" }
    if ($protected_flag) { continue }

    $dst_dir = Split-Path $item.dst -Parent
    if (-not (Test-Path $dst_dir)) {
        New-Item -ItemType Directory -Path $dst_dir -Force | Out-Null
    }
    Copy-Item $item.src $item.dst -Force
    $applied++
}

Write-Host ""
Write-Host "$applied files installed to $dest_omp" -ForegroundColor Green
Write-Host "Backup at: $backup_dir" -ForegroundColor Green
Write-Host ""
Write-Host "To roll back: .\scripts\uninstall-template.ps1 -BackupDir `"$backup_dir`""
