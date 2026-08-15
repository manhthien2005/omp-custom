#Requires -Version 7.4
[CmdletBinding(DefaultParameterSetName = 'Verify')]
param(
    [Parameter()][string]$RepositoryRoot = '.',
    [Parameter(Mandatory, ParameterSetName = 'Capture')][switch]$Capture,
    [Parameter(ParameterSetName = 'Capture')][string]$OutputPath = (Join-Path $PSScriptRoot '01-CANDIDATE-SNAPSHOT.jsonl'),
    [Parameter(Mandatory, ParameterSetName = 'Verify')][switch]$Verify,
    [Parameter(ParameterSetName = 'Verify')][string]$InputPath = (Join-Path $PSScriptRoot '01-CANDIDATE-SNAPSHOT.jsonl')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$packetRelativePrefix = 'docs/audit/claude-preflight-2026-08-14/'
$utf8NoBom = [Text.UTF8Encoding]::new($false)

function ConvertTo-LowerHex {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    return [Convert]::ToHexString($Bytes).ToLowerInvariant()
}

function Get-BytesSha256 {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    return ConvertTo-LowerHex -Bytes ([Security.Cryptography.SHA256]::HashData($Bytes))
}

function Get-FileSha256 {
    param([Parameter(Mandatory)][string]$LiteralPath)
    $stream = [IO.File]::OpenRead($LiteralPath)
    try {
        return ConvertTo-LowerHex -Bytes ([Security.Cryptography.SHA256]::HashData($stream))
    }
    finally {
        $stream.Dispose()
    }
}

function Invoke-GitLines {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string[]]$Arguments
    )
    $output = @(& git -c core.quotepath=false -C $Root @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return @($output | ForEach-Object { [string]$_ })
}

function Get-GitBlobSha256 {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Revision,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    [void]$startInfo.ArgumentList.Add('-C')
    [void]$startInfo.ArgumentList.Add($Root)
    [void]$startInfo.ArgumentList.Add('show')
    [void]$startInfo.ArgumentList.Add("$Revision`:$RelativePath")

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    [void]$process.Start()
    $memory = [IO.MemoryStream]::new()
    try {
        $process.StandardOutput.BaseStream.CopyTo($memory)
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            throw "Cannot read baseline blob '$RelativePath': $stderr"
        }
        return Get-BytesSha256 -Bytes $memory.ToArray()
    }
    finally {
        $memory.Dispose()
        $process.Dispose()
    }
}

function Get-ScopeClassification {
    param([Parameter(Mandatory)][string]$Path)

    if ($Path.StartsWith('.tmp-phase00-', [StringComparison]::Ordinal) -or
        $Path.StartsWith('.claude/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'local-scratch'; audit_depth = 'hygiene-only'; risk = 'hygiene' }
    }
    if ($Path.StartsWith('docs/evidence/phase-00/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'immutable-history'; audit_depth = 'integrity-and-provenance'; risk = 'medium' }
    }
    if ($Path.StartsWith('docs/evidence/current-product/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'current-evidence'; audit_depth = 'deep-claim-boundary'; risk = 'high' }
    }
    if ($Path.StartsWith('spec/phases/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'phase-authority'; audit_depth = 'deep-projection'; risk = 'high' }
    }
    if ($Path.StartsWith('spec/key/dossiers/', [StringComparison]::Ordinal) -or
        $Path.StartsWith('spec/key/repos/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'source-provenance'; audit_depth = 'targeted-if-imported'; risk = 'medium' }
    }
    if ($Path.StartsWith('spec/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'active-authority'; audit_depth = 'deep-contract'; risk = 'high' }
    }
    if ($Path.StartsWith('template/.omp/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'product-runtime'; audit_depth = 'deep-execution'; risk = 'high' }
    }
    if ($Path.StartsWith('scripts/tests/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'verification-test'; audit_depth = 'negative-control-review'; risk = 'medium' }
    }
    if ($Path.StartsWith('scripts/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'implementation-tooling'; audit_depth = 'deep-when-load-bearing'; risk = 'high' }
    }
    if ($Path.StartsWith('evals/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'evaluation-fixture'; audit_depth = 'semantic-and-boundary'; risk = 'medium' }
    }
    if ($Path.StartsWith('registry/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'governance-registry'; audit_depth = 'fact-and-pin-review'; risk = 'high' }
    }
    if ($Path.StartsWith('docs/superpowers/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'design-plan'; audit_depth = 'targeted-intent'; risk = 'medium' }
    }
    if ($Path.StartsWith('docs/research/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'source-provenance'; audit_depth = 'targeted-if-imported'; risk = 'medium' }
    }
    if ($Path.StartsWith('docs/', [StringComparison]::Ordinal)) {
        return [ordered]@{ scope_class = 'operator-documentation'; audit_depth = 'safety-and-overclaim'; risk = 'medium' }
    }
    if ($Path -match '^(codex-|opus5-|omp-custom-|fable5-)' -or $Path -match 'peer-review') {
        return [ordered]@{ scope_class = 'review-history'; audit_depth = 'targeted-if-reproduced'; risk = 'low' }
    }
    return [ordered]@{ scope_class = 'repository-metadata'; audit_depth = 'packaging-and-safety'; risk = 'medium' }
}

function Get-TopicLabel {
    param([Parameter(Mandatory)][string]$Path)
    $lower = $Path.ToLowerInvariant()
    if ($lower -match 'round09-12|round-09-12|round0912') { return 'round09-12' }
    foreach ($number in 2..8) {
        $two = $number.ToString('00')
        if ($lower -match "topic[-_]?0?$number(?![0-9])" -or $lower -match "topic-$two") {
            return "topic$two"
        }
    }
    if ($lower -match 'topic[-_]?0?1(?![0-9])|optimization-metrics') { return 'topic01' }
    if ($lower -match 'phase-00|phase00|\.tmp-phase00') { return 'phase00' }
    return 'shared'
}

function Get-CandidateState {
    param([Parameter(Mandatory)][string]$Root)

    $resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
    $branch = (Invoke-GitLines -Root $resolvedRoot -Arguments @('branch', '--show-current') | Select-Object -First 1)
    $head = (Invoke-GitLines -Root $resolvedRoot -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1)
    $staged = @(Invoke-GitLines -Root $resolvedRoot -Arguments @('diff', '--cached', '--name-only'))
    $statusLines = @(Invoke-GitLines -Root $resolvedRoot -Arguments @(
        'status', '--porcelain=v1', '--untracked-files=all', '--no-renames'
    ))

    $entries = [Collections.Generic.List[object]]::new()
    foreach ($line in $statusLines) {
        if ([string]::IsNullOrEmpty($line) -or $line.Length -lt 4) { continue }
        $status = $line.Substring(0, 2)
        $path = $line.Substring(3).Replace('\', '/')
        if ($path.StartsWith($packetRelativePrefix, [StringComparison]::Ordinal)) { continue }

        $classification = Get-ScopeClassification -Path $path
        $absolutePath = Join-Path $resolvedRoot ($path.Replace('/', [IO.Path]::DirectorySeparatorChar))
        $currentExists = Test-Path -LiteralPath $absolutePath -PathType Leaf
        $currentSha = $null
        $currentBytes = $null
        if ($currentExists) {
            $currentSha = Get-FileSha256 -LiteralPath $absolutePath
            $currentBytes = (Get-Item -LiteralPath $absolutePath).Length
        }

        $baselineSha = $null
        if ($status -cne '??' -and $status -cne 'A ' -and $status -cne 'D ') {
            $baselineSha = Get-GitBlobSha256 -Root $resolvedRoot -Revision $head -RelativePath $path
        }

        [void]$entries.Add([ordered]@{
            record_type = 'candidate_snapshot_entry'
            status = $status
            path = $path
            topic = Get-TopicLabel -Path $path
            scope_class = $classification.scope_class
            audit_depth = $classification.audit_depth
            risk = $classification.risk
            current_exists = [bool]$currentExists
            current_bytes = $currentBytes
            current_sha256 = $currentSha
            baseline_sha256 = $baselineSha
        })
    }

    $sortedEntries = @($entries | Sort-Object { $_.path })
    $normalizedStatus = (($sortedEntries | ForEach-Object { "$($_.status)`t$($_.path)" }) -join "`n")
    if ($sortedEntries.Count -gt 0) { $normalizedStatus += "`n" }
    $statusDigest = Get-BytesSha256 -Bytes $utf8NoBom.GetBytes($normalizedStatus)

    $classCounts = [ordered]@{}
    foreach ($group in @($sortedEntries | Group-Object -Property { $_.scope_class } | Sort-Object Name)) {
        $classCounts[$group.Name] = $group.Count
    }

    return [ordered]@{
        metadata = [ordered]@{
            record_type = 'candidate_snapshot_metadata'
            schema_version = 1
            repository_root = $resolvedRoot
            branch = [string]$branch
            head = [string]$head
            staged_count = $staged.Count
            packet_prefix_excluded = $packetRelativePrefix
            entry_count = $sortedEntries.Count
            candidate_status_sha256 = $statusDigest
            scope_class_counts = $classCounts
        }
        entries = $sortedEntries
    }
}

function ConvertTo-JsonLine {
    param([Parameter(Mandatory)][object]$Value)
    return ($Value | ConvertTo-Json -Depth 16 -Compress)
}

function Write-CandidateSnapshot {
    param(
        [Parameter(Mandatory)][object]$State,
        [Parameter(Mandatory)][string]$LiteralPath
    )
    $resolvedRoot = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
    $resolvedOutput = [IO.Path]::GetFullPath($LiteralPath)
    $requiredParent = [IO.Path]::GetFullPath((Join-Path $resolvedRoot $packetRelativePrefix.Replace('/', [IO.Path]::DirectorySeparatorChar))).TrimEnd('\', '/')
    $actualParent = [IO.Path]::GetDirectoryName($resolvedOutput).TrimEnd('\', '/')
    if ($actualParent -cne $requiredParent) {
        throw "Capture output must stay inside the excluded audit packet directory: $requiredParent"
    }

    $metadata = [ordered]@{}
    foreach ($key in $State.metadata.Keys) { $metadata[$key] = $State.metadata[$key] }
    $metadata.captured_at_utc = [DateTimeOffset]::UtcNow.ToString('o')
    $lines = [Collections.Generic.List[string]]::new()
    [void]$lines.Add((ConvertTo-JsonLine -Value $metadata))
    foreach ($entry in $State.entries) {
        [void]$lines.Add((ConvertTo-JsonLine -Value $entry))
    }
    [IO.File]::WriteAllText($resolvedOutput, (($lines -join "`n") + "`n"), $utf8NoBom)
}

function Compare-CandidateSnapshot {
    param(
        [Parameter(Mandatory)][object]$State,
        [Parameter(Mandatory)][string]$LiteralPath
    )
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        return @("manifest_missing:$LiteralPath")
    }
    $records = @(Get-Content -LiteralPath $LiteralPath | ForEach-Object { $_ | ConvertFrom-Json })
    if ($records.Count -lt 1 -or $records[0].record_type -cne 'candidate_snapshot_metadata') {
        return @('manifest_metadata_missing_or_invalid')
    }

    $expectedMeta = $records[0]
    $actualMeta = $State.metadata
    $mismatches = [Collections.Generic.List[string]]::new()
    foreach ($field in @('branch', 'head', 'staged_count', 'entry_count', 'candidate_status_sha256', 'packet_prefix_excluded')) {
        if ([string]$expectedMeta.$field -cne [string]$actualMeta[$field]) {
            [void]$mismatches.Add("metadata.$field expected='$($expectedMeta.$field)' actual='$($actualMeta[$field])'")
        }
    }

    $expectedEntries = @($records | Select-Object -Skip 1)
    $actualByPath = @{}
    foreach ($entry in $State.entries) { $actualByPath[[string]$entry.path] = $entry }
    foreach ($expected in $expectedEntries) {
        $path = [string]$expected.path
        if (-not $actualByPath.ContainsKey($path)) {
            [void]$mismatches.Add("missing_current_path:$path")
            continue
        }
        $actual = $actualByPath[$path]
        foreach ($field in @('status', 'topic', 'scope_class', 'audit_depth', 'risk', 'current_exists', 'current_bytes', 'current_sha256', 'baseline_sha256')) {
            if ([string]$expected.$field -cne [string]$actual[$field]) {
                [void]$mismatches.Add("entry:$path field:$field expected='$($expected.$field)' actual='$($actual[$field])'")
            }
        }
        [void]$actualByPath.Remove($path)
    }
    foreach ($extra in @($actualByPath.Keys | Sort-Object)) {
        [void]$mismatches.Add("unexpected_current_path:$extra")
    }
    return @($mismatches)
}

try {
    $RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
    $state = Get-CandidateState -Root $RepositoryRoot
    if ($Capture) {
        Write-CandidateSnapshot -State $state -LiteralPath $OutputPath
        "SNAPSHOT CAPTURED: entries=$($state.metadata.entry_count) digest=$($state.metadata.candidate_status_sha256)"
        exit 0
    }

    $mismatches = @(Compare-CandidateSnapshot -State $state -LiteralPath $InputPath)
    if ($mismatches.Count -gt 0) {
        "SNAPSHOT_MISMATCH: count=$($mismatches.Count)"
        $mismatches | Select-Object -First 20
        exit 2
    }
    "SNAPSHOT VERIFIED: entries=$($state.metadata.entry_count) digest=$($state.metadata.candidate_status_sha256)"
    exit 0
}
catch {
    Write-Error $_
    exit 1
}
