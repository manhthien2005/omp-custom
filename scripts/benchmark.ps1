# Benchmark Script
# Run evaluation tasks and record metrics.
# Usage: .\scripts\benchmark.ps1 [-Task all|<id>] [-Workflow quick|standard|orchestrated|compare]

param(
    [string]$Task = "all",
    [string]$Workflow = "compare",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$evals_dir = Join-Path $root "evals"
$results_dir = Join-Path $root "evals\results"

if (-not (Test-Path $results_dir)) {
    New-Item -ItemType Directory -Path $results_dir -Force | Out-Null
}

Write-Host ""
Write-Host "OMP Workflow Template — Benchmark Runner" -ForegroundColor Cyan
Write-Host "Note: This script records task fixture metadata." -ForegroundColor Yellow
Write-Host "Actual OMP session execution must be done manually per fixture." -ForegroundColor Yellow
Write-Host ""

# List available fixtures
$fixtures = Get-ChildItem $evals_dir -Filter "*.yml" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.DirectoryName -notlike "*results*" }

if ($fixtures.Count -eq 0) {
    Write-Host "No evaluation fixtures found in $evals_dir" -ForegroundColor Yellow
    Write-Host "Add fixture files (*.yml) to evals/triage/, evals/implementation/, etc."
    exit 0
}

Write-Host "Available fixtures:" -ForegroundColor White
foreach ($f in $fixtures) {
    $rel = $f.FullName.Substring($evals_dir.Length).TrimStart("\")
    Write-Host "  $rel"
}

Write-Host ""
Write-Host "Benchmark record format:" -ForegroundColor White
Write-Host "  Each fixture records: task_id, workflow_used, agents_spawned, tool_calls,"
Write-Host "  input_tokens, output_tokens, accepted_outcome, test_pass_rate, retries"
Write-Host ""
Write-Host "To record a benchmark result, create:"
Write-Host "  evals\results\<task-id>-<workflow>-<timestamp>.yml"
Write-Host ""
Write-Host "Compare workflows: evals\results\compare-*.yml (side-by-side records)"

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY-RUN: no benchmark sessions started." -ForegroundColor Yellow
}
