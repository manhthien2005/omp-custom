#Requires -Version 7.4
[CmdletBinding()]
param(
    [ValidateSet('plan', 'deterministic', 'model-pilot')]
    [string]$Mode = 'plan',
    [ValidateRange(1, 100)][int]$Pairs = 3,
    [ValidateRange(1, 2147483647)][int]$Seed = 20260813,
    [string]$OutputDirectory,
    [switch]$AllowModelSpend,
    [string]$Confirmation,
    [string]$LeadModel,
    [string]$CodeGraphArtifactPath,
    [switch]$AllowCodeGraphDownload
)

$ErrorActionPreference = 'Stop'
if ($CodeGraphArtifactPath -and $AllowCodeGraphDownload) {
    throw 'CodeGraph artifact path and download permission are mutually exclusive.'
}
if ($Mode -cne 'model-pilot' -and
    ($AllowModelSpend -or $Confirmation -or $CodeGraphArtifactPath -or $AllowCodeGraphDownload)) {
    throw 'Model-spend and CodeGraph acquisition controls are valid only with -Mode model-pilot.'
}
$root = Split-Path $PSScriptRoot -Parent
$libraryPath = Join-Path $PSScriptRoot 'lib\topic05-benchmark.ps1'
$fixturePath = Join-Path $root 'evals\retrieval\topic05\fixtures.json'
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $root 'evals\retrieval\topic05\runs'
}
. $libraryPath

$registry = Read-Topic05BenchmarkFixtures -LiteralPath $fixturePath
$plan = New-Topic05BenchmarkPlan -Registry $registry -Pairs $Pairs -Seed $Seed `
    -OutputDirectory $OutputDirectory

if ($Mode -ceq 'plan') {
    Write-Host "Topic 05 benchmark plan (no repositories, credentials, or model processes)"
    Write-Host "Campaign: $($plan.campaign_id)"
    Write-Host "Seed: $Seed; pairs: $Pairs; executions: $($plan.execution_count)"
    Write-Host 'Required Lead identity: provider/model:effort (model-pilot only)'
    Write-Host 'Cheap Scout identity: omniroute/ds/deepseek-v4-flash:xhigh -> omniroute/ds/deepseek-v4-pro:xhigh only'
    foreach ($execution in @($plan.executions)) {
        Write-Host ('{0:D4} pair={1} fixture={2} arm={3} cache={4} output={5}' -f
            $execution.order, $execution.pair, $execution.fixture_id, $execution.arm,
            $execution.cache_condition, $execution.output_path)
    }
    exit 0
}

if ($Mode -ceq 'deterministic') {
    $records = @(Invoke-Topic05DeterministicBenchmark -Registry $registry -Plan $plan)
    $report = Get-Topic05BenchmarkComparisonReport -Records $records
    Write-Host "Topic 05 deterministic benchmark: $($records.Count) immutable records"
    Write-Host "Output: $(Join-Path $plan.output_directory $plan.campaign_id)"
    Write-Host "Recommendation: $($report.recommendation) (deterministic PASS is not model-campaign PASS)"
    exit 0
}

[void](Assert-Topic05BenchmarkModelPilotGate -AllowModelSpend:$AllowModelSpend `
    -Confirmation $Confirmation -LeadModel $LeadModel)
$records = @(Invoke-Topic05ModelPilotBenchmark -Registry $registry -Plan $plan `
    -LeadModel $LeadModel -AllowModelSpend:$AllowModelSpend -Confirmation $Confirmation `
    -CodeGraphArtifactPath $CodeGraphArtifactPath `
    -AllowCodeGraphDownload:$AllowCodeGraphDownload)
$report = Get-Topic05BenchmarkComparisonReport -Records $records
Write-Host "Topic 05 model pilot: $($records.Count) immutable records"
Write-Host "Output: $(Join-Path $plan.output_directory $plan.campaign_id)"
Write-Host "Recommendation: $($report.recommendation)"
