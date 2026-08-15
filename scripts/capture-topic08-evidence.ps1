#Requires -Version 7.4
[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
$evidenceDirectory = [IO.Path]::GetFullPath((Join-Path $root 'docs\evidence\current-product\topic-08'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $evidenceDirectory.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -or
    -not $evidenceDirectory.EndsWith('docs\evidence\current-product\topic-08',
        [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing unsafe Topic 08 evidence target: $evidenceDirectory"
}

function ConvertTo-Topic08EvidenceJson {
    param([Parameter(Mandatory)][object]$Value)
    return (($Value | ConvertTo-Json -Depth 64) -replace "`r`n", "`n") + "`n"
}

function Get-Topic08EvidenceSha256Bytes {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()
}

function Invoke-Topic08EvidenceCommand {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$CaptureMode
    )
    $previousCapture = $env:OMP_TOPIC08_CAPTURE
    $pushed = $false
    try {
        Push-Location -LiteralPath $root
        $pushed = $true
        if ($CaptureMode) { $env:OMP_TOPIC08_CAPTURE = '1' }
        $output = @(& $Executable @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        if ($pushed) { Pop-Location }
        if ($null -eq $previousCapture) {
            Remove-Item Env:OMP_TOPIC08_CAPTURE -ErrorAction SilentlyContinue
        } else {
            $env:OMP_TOPIC08_CAPTURE = $previousCapture
        }
    }
    $summary = @($output | ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ }) | Select-Object -Last 1
    return [pscustomobject]@{
        Name = $Name
        Command = ($Executable + ' ' + (($Arguments | ForEach-Object {
            if ($_ -match '\s') { '"' + $_.Replace('"', '\"') + '"' } else { $_ }
        }) -join ' '))
        ExitCode = [int]$exitCode
        Status = if ($exitCode -eq 0) { 'PASS' } else { 'FAIL' }
        Summary = if ($summary) { ([string]$summary).Substring(0, [Math]::Min(300, ([string]$summary).Length)) } else { '' }
        RawOutput = @($output | ForEach-Object { [string]$_ })
    }
}

function Get-Topic08InstalledOmp {
    $command = Get-Command omp.exe -ErrorAction SilentlyContinue
    if ($null -eq $command) { $command = Get-Command omp -ErrorAction SilentlyContinue }
    if ($null -eq $command) { return $null }
    $path = if ($command.Source) { [string]$command.Source } else { [string]$command.Path }
    try {
        $output = @(& $path --version 2>&1)
        if ($LASTEXITCODE -ne 0) { return $null }
        $match = [regex]::Match(($output -join "`n"), '(?m)^omp/([^\s]+)\s*$')
        if (-not $match.Success) { return $null }
        return [pscustomobject]@{ Path = [IO.Path]::GetFullPath($path); Version = $match.Groups[1].Value }
    } catch { return $null }
}

$checks = [Collections.Generic.List[object]]::new()
[void]$checks.Add((Invoke-Topic08EvidenceCommand -Name 'topic08-node' -Executable 'node' -Arguments @(
    '--test',
    'scripts/tests/topic08-behavior-core.Tests.mjs',
    'scripts/tests/topic08-skill-contracts.Tests.mjs',
    'scripts/tests/topic08-agent-tasks-tool.Tests.mjs',
    'scripts/tests/topic08-behavior-gates.Tests.mjs'
)))
[void]$checks.Add((Invoke-Topic08EvidenceCommand -Name 'topic08-installer' -Executable 'pwsh' -Arguments @(
    '-NoProfile', '-File', 'scripts/tests/topic08-installer.Tests.ps1'
)))
[void]$checks.Add((Invoke-Topic08EvidenceCommand -Name 'topic08-validator-mutations' -Executable 'pwsh' -Arguments @(
    '-NoProfile', '-File', 'scripts/tests/topic08-validator-mutations.Tests.ps1'
)))
[void]$checks.Add((Invoke-Topic08EvidenceCommand -Name 'topic08-focused-no-evidence' -Executable 'pwsh' -CaptureMode `
    -Arguments @('-NoProfile', '-File', 'scripts/validate-topic08-behavior-core.ps1', '-RepositoryRoot', '.')))
[void]$checks.Add((Invoke-Topic08EvidenceCommand -Name 'topic08-lock-check' -Executable 'pwsh' -Arguments @(
    '-NoProfile', '-File', 'scripts/update-skill-lock.ps1', '-RepositoryRoot', '.', '-Check'
)))

$installedOmp = Get-Topic08InstalledOmp
$runtimeRows = [Collections.Generic.List[object]]::new()
$installedCanary = $null
if ($null -ne $installedOmp -and [string]$installedOmp.Version -ceq '17.2.12') {
    $installedCanary = Invoke-Topic08EvidenceCommand -Name 'omp-17.2.12-discovery-canary' -Executable 'node' `
        -Arguments @('--test', 'scripts/tests/topic06-agent-contracts.Tests.mjs')
    [void]$checks.Add($installedCanary)
    [void]$runtimeRows.Add([pscustomobject]@{
        version = '17.2.12'
        available = $true
        path = [string]$installedOmp.Path
        canary = [string]$installedCanary.Status
    })
} else {
    [void]$runtimeRows.Add([pscustomobject]@{
        version = '17.2.12'
        available = $false
        path = $null
        canary = 'UNAVAILABLE_NO_DOWNLOAD'
    })
}
$legacyPath = Join-Path $root 'tools\runtime-cache\omp\17.2.10\omp.exe'
$legacyAvailable = Test-Path -LiteralPath $legacyPath -PathType Leaf
[void]$runtimeRows.Add([pscustomobject]@{
    version = '17.2.10'
    available = $legacyAvailable
    path = if ($legacyAvailable) { [IO.Path]::GetFullPath($legacyPath) } else { $null }
    canary = if ($legacyAvailable) { 'NOT_RUN_TOPIC07_OWNER' } else { 'UNAVAILABLE_NO_DOWNLOAD' }
})

$failed = @($checks | Where-Object ExitCode -ne 0)
if ($failed.Count -gt 0) {
    foreach ($failure in $failed) {
        [Console]::Error.WriteLine("FAIL [$($failure.Name)] $($failure.Summary)")
    }
    throw 'Topic 08 evidence capture refused to write because a prerequisite check failed.'
}

$behaviorManifestPath = Join-Path $root 'template\.omp\contracts\behavior-manifest.json'
if (-not (Test-Path -LiteralPath $behaviorManifestPath -PathType Leaf)) {
    throw 'Topic 08 evidence capture refused to write because the behavior manifest is missing.'
}
$behaviorManifestBytes = [IO.File]::ReadAllBytes($behaviorManifestPath)
$behaviorManifest = [Text.Encoding]::UTF8.GetString($behaviorManifestBytes) | ConvertFrom-Json -AsHashtable
if ([string]$behaviorManifest.component -cne 'behavior-core' -or
    [string]$behaviorManifest.component_version -cne '1.0.0' -or
    [string]$behaviorManifest.adapters.omp.status -cne 'IMPLEMENTED_NOT_PROMOTED' -or
    $behaviorManifest.adapters.omp.installable -ne $true -or
    [string]$behaviorManifest.adapters.claude.status -cne 'DESIGNED_NOT_VERIFIED' -or
    $behaviorManifest.adapters.claude.installable -ne $false) {
    throw 'Topic 08 evidence capture refused to write an unsupported adapter claim.'
}

$deterministic = [ordered]@{
    schema_version = 1
    record_type = 'topic08_deterministic_evidence'
    generated_at_utc = [DateTime]::UtcNow.ToString('o')
    status = 'IMPLEMENTED_NOT_PROMOTED'
    component = 'behavior-core'
    component_version = [string]$behaviorManifest.component_version
    omp_source_sha = '3a8591a8af5b6d200088d12ca75a5517cb064fa8'
    source_attachment_count = 11
    provider_calls = 0
    adapters = [ordered]@{
        omp = [ordered]@{ status = 'IMPLEMENTED_NOT_PROMOTED'; installable = $true }
        claude = [ordered]@{ status = 'DESIGNED_NOT_VERIFIED'; installable = $false }
    }
    runtime_matrix = @($runtimeRows)
    checks = @($checks | ForEach-Object {
        [ordered]@{
            name = [string]$_.Name
            command = [string]$_.Command
            exit_code = [int]$_.ExitCode
            status = [string]$_.Status
            summary = [string]$_.Summary
        }
    })
    open_items = @(
        [ordered]@{ code = 'OPEN-T07-RUNTIME-02'; owner = 'Topic 07'; disposition = 'retained' },
        [ordered]@{ code = 'TOPIC11-SEMANTIC-PROMOTION'; owner = 'Topic 11'; disposition = 'not_promoted' }
    )
}
$deterministicBytes = [Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Topic08EvidenceJson $deterministic))
$snapshotHash = Get-Topic08EvidenceSha256Bytes -Bytes $behaviorManifestBytes
$deterministicHash = Get-Topic08EvidenceSha256Bytes -Bytes $deterministicBytes
$evidenceManifest = [ordered]@{
    schema_version = 1
    record_type = 'topic08_evidence_manifest'
    component = 'behavior-core'
    component_version = [string]$behaviorManifest.component_version
    generated_at_utc = [string]$deterministic.generated_at_utc
    files = @(
        [ordered]@{ path = 'behavior-manifest.json'; sha256 = $snapshotHash },
        [ordered]@{ path = 'deterministic.json'; sha256 = $deterministicHash }
    )
}
$evidenceManifestBytes = [Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Topic08EvidenceJson $evidenceManifest))

[void](New-Item -ItemType Directory -Path $evidenceDirectory -Force)
$transaction = Join-Path $evidenceDirectory ('.topic08-capture-' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $transaction)
$names = @('behavior-manifest.json', 'deterministic.json', 'manifest.json')
$bytesByName = [ordered]@{
    'behavior-manifest.json' = $behaviorManifestBytes
    'deterministic.json' = $deterministicBytes
    'manifest.json' = $evidenceManifestBytes
}
$previous = @{}
try {
    foreach ($name in $names) {
        $target = Join-Path $evidenceDirectory $name
        if (Test-Path -LiteralPath $target -PathType Leaf) { $previous[$name] = [IO.File]::ReadAllBytes($target) }
        [IO.File]::WriteAllBytes((Join-Path $transaction $name), [byte[]]$bytesByName[$name])
    }
    foreach ($name in $names) {
        [IO.File]::Move((Join-Path $transaction $name), (Join-Path $evidenceDirectory $name), $true)
    }
} catch {
    foreach ($name in $names) {
        $target = Join-Path $evidenceDirectory $name
        if ($previous.ContainsKey($name)) {
            [IO.File]::WriteAllBytes($target, [byte[]]$previous[$name])
        } elseif (Test-Path -LiteralPath $target -PathType Leaf) {
            Remove-Item -LiteralPath $target -Force
        }
    }
    throw
} finally {
    $resolvedTransaction = [IO.Path]::GetFullPath($transaction)
    if ($resolvedTransaction.StartsWith($evidenceDirectory + [IO.Path]::DirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase) -and
        [IO.Path]::GetFileName($resolvedTransaction) -like '.topic08-capture-*' -and
        (Test-Path -LiteralPath $resolvedTransaction -PathType Container)) {
        Remove-Item -LiteralPath $resolvedTransaction -Recurse -Force
    }
}

Write-Host "PASS: Topic 08 evidence captured ($($checks.Count) checks, 0 provider calls)." -ForegroundColor Green
