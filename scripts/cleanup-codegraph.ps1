#Requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('bundle', 'index')]
    [string]$Kind,

    [Parameter(Mandatory)]
    [string]$LiteralPath,

    [Parameter(Mandatory)]
    [string]$Confirmation,

    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$libraryPath = Join-Path $PSScriptRoot 'lib\topic05-codegraph.ps1'
. $libraryPath

function Stop-Topic05Cleanup {
    param([Parameter(Mandatory)][string]$Reason)
    [Console]::Error.WriteLine("topic05_codegraph_cleanup:$Reason")
    exit 2
}

try {
    $result = Invoke-Topic05CodeGraphCleanup -Kind $Kind -LiteralPath $LiteralPath `
        -Confirmation $Confirmation -Apply:$Apply
    $result | ConvertTo-Json -Depth 5 -Compress
    exit 0
} catch {
    Stop-Topic05Cleanup -Reason 'validation_failed'
}
