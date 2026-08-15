# Compatibility entry point for the governed Round 09-12 evaluator.

param(
    [string]$Task = 'all',
    [string]$Workflow = 'compare',
    [switch]$DryRun,
    [ValidateSet('Deterministic', 'Campaign')]
    [string]$Mode = 'Deterministic',
    [string]$OutputDirectory,
    [string]$OmpPath,
    [switch]$AllowProviderCalls,
    [ValidateRange(0, 1000000)]
    [int]$EvidenceBudget = 0,
    [string]$FixtureManifest,
    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'run-round09-12-evaluation.ps1'
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Round 09-12 evaluator is unavailable: $runner"
}

Write-Host 'DEPRECATED: scripts/benchmark.ps1 now forwards to the governed Round 09-12 evaluator.' -ForegroundColor Yellow
Write-Host 'Hand-authored result files cannot support promotion.' -ForegroundColor Yellow
if ($Task -cne 'all' -or $Workflow -cne 'compare') {
    Write-Host "Legacy selectors Task=$Task and Workflow=$Workflow are retained for compatibility but do not alter the closed fixture manifest." -ForegroundColor Yellow
}

$selectedMode = if ($DryRun) { 'Deterministic' } else { $Mode }
$arguments = @(
    '-Mode', $selectedMode,
    '-EvidenceBudget', [string]$EvidenceBudget,
    '-TimeoutSeconds', [string]$TimeoutSeconds
)
if (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) { $arguments += @('-OutputDirectory', $OutputDirectory) }
if (-not [string]::IsNullOrWhiteSpace($OmpPath)) { $arguments += @('-OmpPath', $OmpPath) }
if (-not [string]::IsNullOrWhiteSpace($FixtureManifest)) { $arguments += @('-FixtureManifest', $FixtureManifest) }
if ($AllowProviderCalls) { $arguments += '-AllowProviderCalls' }

& pwsh -NoLogo -NoProfile -File $runner @arguments
exit $LASTEXITCODE
