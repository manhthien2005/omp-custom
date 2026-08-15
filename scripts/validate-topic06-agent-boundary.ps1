#Requires -Version 7.4
[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }

$helperPath = Join-Path $PSScriptRoot 'lib\topic06-agent-boundary.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    Write-Host 'FAIL [T06-VALIDATOR-HELPER] focused Topic 06 validator helper is missing' -ForegroundColor Red
    exit 1
}
. $helperPath

$results = @(Test-Topic06AgentBoundaryContract -RepositoryRoot $RepositoryRoot)
foreach ($result in $results) {
    $color = switch ($result.Status) { 'PASS' { 'Green' } 'WARN' { 'Yellow' } default { 'Red' } }
    Write-Host "$($result.Status) [$($result.Code)] $($result.Message)" -ForegroundColor $color
}
$passCount = @($results | Where-Object Status -eq PASS).Count
$warnCount = @($results | Where-Object Status -eq WARN).Count
$failCount = @($results | Where-Object Status -eq FAIL).Count
Write-Host "Topic 06 focused validation: $passCount PASS, $warnCount WARN, $failCount FAIL"
if ($failCount -gt 0) { exit 1 }
exit 0
