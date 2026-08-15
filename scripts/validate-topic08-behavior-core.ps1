#Requires -Version 7.4
[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [switch]$Json,
    [switch]$SkipRuntime,
    [switch]$SkipDocumentation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }

$helperPath = Join-Path $PSScriptRoot 'lib\topic08-behavior-core.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    if ($Json) {
        [pscustomobject]@{
            schema_version = 1
            record_type = 'topic08_validation_result'
            pass = 0
            warn = 0
            fail = 1
            results = @([pscustomobject]@{
                Status = 'FAIL'; Code = 'T08-VALIDATOR-HELPER'; Message = 'Focused helper is missing.'
            })
        } | ConvertTo-Json -Depth 8
    } else {
        Write-Host 'FAIL [T08-VALIDATOR-HELPER] focused Topic 08 validator helper is missing' -ForegroundColor Red
    }
    exit 1
}
. $helperPath

$skipEvidence = $env:OMP_TOPIC08_CAPTURE -ceq '1'
$results = @(Test-Topic08BehaviorCore -RepositoryRoot $RepositoryRoot -SkipEvidence:$skipEvidence `
    -SkipRuntime:$SkipRuntime -SkipDocumentation:$SkipDocumentation)
$passCount = @($results | Where-Object Status -eq PASS).Count
$warnCount = @($results | Where-Object Status -eq WARN).Count
$failCount = @($results | Where-Object Status -eq FAIL).Count

if ($Json) {
    [pscustomobject]@{
        schema_version = 1
        record_type = 'topic08_validation_result'
        pass = $passCount
        warn = $warnCount
        fail = $failCount
        results = $results
    } | ConvertTo-Json -Depth 8
} else {
    foreach ($result in $results) {
        $color = switch ($result.Status) { 'PASS' { 'Green' } 'WARN' { 'Yellow' } default { 'Red' } }
        Write-Host "$($result.Status) [$($result.Code)] $($result.Message)" -ForegroundColor $color
    }
    Write-Host "Topic 08 focused validation: $passCount PASS, $warnCount WARN, $failCount FAIL"
}
if ($failCount -gt 0) { exit 1 }
exit 0
