#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$helper = Join-Path $PSScriptRoot 'lib\topic02-workflow-lifecycle.ps1'
if (-not (Test-Path -LiteralPath $helper -PathType Leaf)) {
    Write-Host 'FAIL [T02-HELPER-MISSING] focused Topic 02 validator helper is missing' -ForegroundColor Red
    exit 1
}

. $helper

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$results = @(Test-Topic02WorkflowLifecycleContract -RepositoryRoot $repositoryRoot)

foreach ($result in $results) {
    $color = switch ($result.Status) {
        'PASS' { 'Green' }
        'WARN' { 'Yellow' }
        'FAIL' { 'Red' }
        default { 'Red' }
    }
    Write-Host ("{0} [{1}] {2}" -f $result.Status, $result.Code, $result.Message) -ForegroundColor $color
}

$passed = @($results | Where-Object Status -eq 'PASS').Count
$warnings = @($results | Where-Object Status -eq 'WARN').Count
$failed = @($results | Where-Object Status -eq 'FAIL').Count

Write-Host ("Topic 02 lifecycle: {0} passed, {1} warnings, {2} failed" -f $passed, $warnings, $failed)

if ($failed -gt 0) {
    exit 1
}

exit 0
