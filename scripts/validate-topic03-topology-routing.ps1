#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$helperPath = Join-Path $PSScriptRoot 'lib\topic03-topology-routing.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    Write-Host 'FAIL [T03-VALIDATOR-HELPER] focused Topic 03 validator helper is missing' -ForegroundColor Red
    exit 1
}
. $helperPath

$results = @(Test-Topic03TopologyRoutingContract -RepositoryRoot $RepositoryRoot)
foreach ($result in $results) {
    $color = switch ($result.Status) {
        'PASS' { 'Green' }
        'WARN' { 'Yellow' }
        default { 'Red' }
    }
    Write-Host "$($result.Status) [$($result.Code)] $($result.Message)" -ForegroundColor $color
}

$passCount = @($results | Where-Object Status -eq 'PASS').Count
$warnCount = @($results | Where-Object Status -eq 'WARN').Count
$failCount = @($results | Where-Object Status -eq 'FAIL').Count
Write-Host "Topic 03 focused validation: $passCount PASS, $warnCount WARN, $failCount FAIL"

if ($failCount -gt 0) {
    exit 1
}
exit 0
