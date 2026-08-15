#Requires -Version 7.4
[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [switch]$Json,
    [switch]$SkipEvidence,
    [switch]$SkipRuntime,
    [switch]$SkipDocumentation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }

$helperPath = Join-Path $PSScriptRoot 'lib\round09-12-release-readiness.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    $missing = [pscustomobject]@{
        Status = 'FAIL'
        Code = 'R0912-VALIDATOR-HELPER'
        Message = 'Focused Round 09-12 helper is missing.'
    }
    if ($Json) {
        [pscustomobject]@{
            schema_version = 1
            record_type = 'round0912_validation_result'
            pass = 0
            warn = 0
            fail = 1
            results = @($missing)
        } | ConvertTo-Json -Depth 8
    } else {
        Write-Host "FAIL [$($missing.Code)] $($missing.Message)" -ForegroundColor Red
    }
    exit 1
}
. $helperPath

$effectiveSkipEvidence = $SkipEvidence -or ($env:OMP_ROUND0912_CAPTURE -ceq '1')
$results = @(Test-Round0912ReleaseReadiness -RepositoryRoot $RepositoryRoot `
    -SkipEvidence:$effectiveSkipEvidence -SkipRuntime:$SkipRuntime -SkipDocumentation:$SkipDocumentation)
$passCount = @($results | Where-Object Status -eq PASS).Count
$warnCount = @($results | Where-Object Status -eq WARN).Count
$failCount = @($results | Where-Object Status -eq FAIL).Count

if ($Json) {
    [pscustomobject]@{
        schema_version = 1
        record_type = 'round0912_validation_result'
        pass = $passCount
        warn = $warnCount
        fail = $failCount
        results = $results
    } | ConvertTo-Json -Depth 12
} else {
    foreach ($result in $results) {
        $color = switch ($result.Status) { 'PASS' { 'Green' } 'WARN' { 'Yellow' } default { 'Red' } }
        Write-Host "$($result.Status) [$($result.Code)] $($result.Message)" -ForegroundColor $color
    }
    Write-Host "Round 09-12 focused validation: $passCount PASS, $warnCount WARN, $failCount FAIL"
}
if ($failCount -gt 0) { exit 1 }
exit 0
