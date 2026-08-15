#Requires -Version 7.4
[CmdletBinding()]
param(
    [string]$LockPath,
    [string]$CacheRoot,
    [string]$ArtifactPath,
    [switch]$AllowNetwork,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$libraryPath = Join-Path $PSScriptRoot 'lib\topic05-codegraph.ps1'
. $libraryPath

function Write-Topic05ProvisionFailure {
    param([Parameter(Mandatory)][string]$Reason, [Parameter(Mandatory)][int]$ExitCode)
    [Console]::Error.WriteLine("topic05_codegraph_provision:$Reason")
    exit $ExitCode
}

try {
    if ([string]::IsNullOrWhiteSpace($LockPath)) {
        $LockPath = Join-Path $repositoryRoot 'template\.omp\codegraph\upstream-lock.json'
    }
    if ([string]::IsNullOrWhiteSpace($CacheRoot)) {
        $CacheRoot = Get-Topic05CodeGraphManagedCacheRoot
    }
    if ($ArtifactPath -and $AllowNetwork) {
        Write-Topic05ProvisionFailure -Reason 'invalid_input' -ExitCode 2
    }

    $lock = Read-Topic05CodeGraphLock -LiteralPath $LockPath
    $platform = Get-Topic05CodeGraphPlatform
    $artifact = @($lock.artifacts | Where-Object platform -CEQ $platform)
    if ($artifact.Count -ne 1) {
        Write-Topic05ProvisionFailure -Reason 'unsupported_platform' -ExitCode 4
    }

    if (-not $Apply) {
        $plan = [ordered]@{
            schema_version = 1
            status = 'planned'
            apply = $false
            platform = $platform
            artifact_name = [string]$artifact[0].name
            cache_root = [IO.Path]::GetFullPath($CacheRoot)
            source = if ($ArtifactPath) { 'offline_artifact' } elseif ($AllowNetwork) { 'network' } else { 'none' }
        }
        $plan | ConvertTo-Json -Depth 5 -Compress
        exit 0
    }

    $receipt = Install-Topic05CodeGraphBundle -LockPath $LockPath -CacheRoot $CacheRoot `
        -ArtifactPath $ArtifactPath -AllowNetwork:$AllowNetwork
    $receipt | ConvertTo-Json -Depth 12 -Compress
    exit 0
} catch {
    $message = $_.Exception.Message
    if ($message -match 'unsupported_platform|network') {
        Write-Topic05ProvisionFailure -Reason 'environment_unavailable' -ExitCode 4
    }
    if ($message -match 'digest|size|conflict|archive|required|version') {
        Write-Topic05ProvisionFailure -Reason 'integrity_refusal' -ExitCode 3
    }
    Write-Topic05ProvisionFailure -Reason 'invalid_input' -ExitCode 2
}
