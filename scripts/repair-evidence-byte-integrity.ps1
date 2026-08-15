#Requires -Version 7.4
[CmdletBinding()]
param(
    [string]$RepositoryRoot = '.',
    [string]$SnapshotPath = 'docs/audit/claude-preflight-2026-08-14/02-POST-CLEANUP-CANDIDATE-SNAPSHOT.jsonl',
    [ValidateSet('WorkingTree', 'Index', 'Head')][string]$Source = 'WorkingTree',
    [switch]$Apply,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:StrictUtf8 = [Text.UTF8Encoding]::new($false, $true)
$script:LimitationHashes = [ordered]@{
    'docs/archive/reviews/opus5-response-to-gpt56-counter-review.md' =
        '5c1f4ed33f3b9e57001a54a81dfc55f835e11521d19ce8bde145056ed1477c2b'
    'docs/evidence/phase-00/E3-J/raw/J1-attempt-002.run.json' =
        'b08da68322a73112e1495aa1bd888dadde7c1dde608add5c3632401c07e532b5'
    'docs/evidence/phase-00/E3-J/raw/J1-attempt-003.run.json' =
        'e348796c0d7323a920fde8ac90de5daae2e8fa898978a233fa09a0ff89cc7b59'
    'docs/evidence/phase-00/E3-J/raw/J1.run.json' =
        '27afe78ce8d9daec2f0a0cd058829428156a50a2d0e090ed81581bd8bbdfe76a'
    'spec/phases/phase-00-foundation.md' =
        'fd01490b089317f6253e4426a431af3d9275cffafd0ce56a200c4a02d2758b9b'
}

function Get-ByteIntegritySha256([byte[]]$Bytes) {
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()
}

function Resolve-ByteIntegrityChildPath([string]$Root, [string]$RelativePath) {
    $resolvedRoot = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).Path.TrimEnd('\', '/')
    if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
        throw "Repository root is not a directory: $Root"
    }
    if ([String]::IsNullOrWhiteSpace($RelativePath) -or [IO.Path]::IsPathRooted($RelativePath)) {
        throw "Snapshot path must be a non-rooted child path: $RelativePath"
    }
    $segments = $RelativePath -split '[\\/]'
    if ($segments -contains '..') {
        throw "Snapshot path must not contain '..' segments: $RelativePath"
    }
    $candidate = [IO.Path]::GetFullPath((Join-Path $resolvedRoot $RelativePath))
    $rootPrefix = $resolvedRoot + [IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Snapshot path escapes repository root: $RelativePath"
    }
    return $candidate
}

function Get-GitObjectBytes([string]$Root, [string]$ObjectExpression) {
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.UseShellExecute = $false
    [void]$startInfo.ArgumentList.Add('-C')
    [void]$startInfo.ArgumentList.Add($Root)
    [void]$startInfo.ArgumentList.Add('show')
    [void]$startInfo.ArgumentList.Add($ObjectExpression)
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw "Unable to start git for $ObjectExpression" }
    $bytes = [IO.MemoryStream]::new()
    try {
        $process.StandardOutput.BaseStream.CopyTo($bytes)
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            throw "git show failed for ${ObjectExpression}: $stderr"
        }
        return $bytes.ToArray()
    }
    finally {
        $bytes.Dispose()
        $process.Dispose()
    }
}

function Get-ByteIntegritySourceBytes(
    [string]$Root, [string]$RelativePath, [string]$Source
) {
    switch ($Source) {
        'WorkingTree' {
            $path = Resolve-ByteIntegrityChildPath -Root $Root -RelativePath $RelativePath
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
            return [IO.File]::ReadAllBytes($path)
        }
        'Index' { return Get-GitObjectBytes -Root $Root -ObjectExpression ":$RelativePath" }
        'Head' { return Get-GitObjectBytes -Root $Root -ObjectExpression "HEAD:$RelativePath" }
        default { throw "Unsupported source: $Source" }
    }
}

function Get-ByteIntegrityCandidates([byte[]]$CurrentBytes) {
    $text = $script:StrictUtf8.GetString($CurrentBytes)
    $lf = $text.Replace("`r`n", "`n")
    $allCrlfText = $lf.Replace("`n", "`r`n")
    $finalLfText = if ($lf.EndsWith("`n", [StringComparison]::Ordinal)) {
        $lf.Substring(0, $lf.Length - 1).Replace("`n", "`r`n") + "`n"
    } else {
        $allCrlfText
    }
    $allCrlfBytes = $script:StrictUtf8.GetBytes($allCrlfText)
    $finalLfBytes = $script:StrictUtf8.GetBytes($finalLfText)
    $unique = [ordered]@{}
    foreach ($bytes in @($allCrlfBytes, $finalLfBytes)) {
        $hash = Get-ByteIntegritySha256 -Bytes $bytes
        if (-not $unique.Contains($hash)) { $unique[$hash] = $bytes }
    }
    return @($unique.GetEnumerator() | ForEach-Object {
        [pscustomobject]@{ Sha256 = $_.Key; Bytes = $_.Value }
    })
}

function Read-ByteIntegritySnapshot([string]$SnapshotLiteralPath) {
    if (-not (Test-Path -LiteralPath $SnapshotLiteralPath -PathType Leaf)) {
        throw "Snapshot does not exist: $SnapshotLiteralPath"
    }
    $entries = [Collections.Generic.List[object]]::new()
    $lineNumber = 0
    foreach ($line in [IO.File]::ReadLines($SnapshotLiteralPath, [Text.Encoding]::UTF8)) {
        $lineNumber++
        if ([String]::IsNullOrWhiteSpace($line)) { continue }
        try { $record = $line | ConvertFrom-Json -ErrorAction Stop }
        catch { throw "Invalid JSONL at line ${lineNumber}: $($_.Exception.Message)" }
        if ($record.record_type -eq 'candidate_snapshot_entry') { [void]$entries.Add($record) }
    }
    return @($entries)
}

function New-EvidenceByteIntegrityPlan(
    [string]$RepositoryRoot, [string]$SnapshotPath, [string]$Source
) {
    $resolvedRoot = (Resolve-Path -LiteralPath $RepositoryRoot -ErrorAction Stop).Path.TrimEnd('\', '/')
    if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) { throw "Repository root is not a directory: $RepositoryRoot" }
    $snapshotInput = if ([IO.Path]::IsPathRooted($SnapshotPath)) { $SnapshotPath } else { Join-Path $resolvedRoot $SnapshotPath }
    $resolvedSnapshot = (Resolve-Path -LiteralPath $snapshotInput -ErrorAction Stop).Path
    $counts = [pscustomobject]@{ Exact = 0; Recoverable = 0; Unrecoverable = 0; Missing = 0; Invalid = 0; Ambiguous = 0; Written = 0 }
    $entries = [Collections.Generic.List[object]]::new()
    $errors = [Collections.Generic.List[object]]::new()

    foreach ($snapshotEntry in (Read-ByteIntegritySnapshot -SnapshotLiteralPath $resolvedSnapshot)) {
        $relativePath = [string]$snapshotEntry.path
        $expectedSha256 = [string]$snapshotEntry.current_sha256
        $entry = [ordered]@{ Path = $relativePath; ExpectedSha256 = $expectedSha256; Classification = $null; ActualSha256 = $null; FullPath = $null; OriginalBytes = $null; CandidateBytes = $null; Message = $null }
        try {
            $fullPath = Resolve-ByteIntegrityChildPath -Root $resolvedRoot -RelativePath $relativePath
            $entry.FullPath = $fullPath
            $currentBytes = Get-ByteIntegritySourceBytes -Root $resolvedRoot -RelativePath $relativePath -Source $Source
            if ($null -eq $currentBytes) {
                $entry.Classification = 'missing'; $entry.Message = 'Source file is missing.'; $counts.Missing++
            }
            else {
                $currentSha256 = Get-ByteIntegritySha256 -Bytes $currentBytes
                $entry.ActualSha256 = $currentSha256
                if ($currentSha256 -eq $expectedSha256) {
                    $entry.Classification = 'exact'; $counts.Exact++
                }
                elseif ($script:LimitationHashes.Contains($relativePath) -and $script:LimitationHashes[$relativePath] -eq $currentSha256) {
                    $entry.Classification = 'unrecoverable'; $entry.Message = 'Closed limitation: accepted Git-LF hash has no authorized reconstruction.'; $counts.Unrecoverable++
                }
                else {
                    $matches = @(Get-ByteIntegrityCandidates -CurrentBytes $currentBytes | Where-Object Sha256 -eq $expectedSha256)
                    if ($matches.Count -eq 1) {
                        $entry.Classification = 'recoverable'; $entry.OriginalBytes = $currentBytes; $entry.CandidateBytes = $matches[0].Bytes; $counts.Recoverable++
                    }
                    elseif ($matches.Count -gt 1) {
                        $entry.Classification = 'ambiguous'; $entry.Message = 'More than one distinct reconstruction matched the snapshot hash.'; $counts.Ambiguous++
                    }
                    else {
                        $entry.Classification = 'invalid'; $entry.Message = 'Raw bytes and both authorized reconstructions do not match the snapshot hash.'; $counts.Invalid++
                    }
                }
            }
        }
        catch {
            $entry.Classification = 'invalid'; $entry.Message = $_.Exception.Message; $counts.Invalid++
        }
        $entryObject = [pscustomobject]$entry
        [void]$entries.Add($entryObject)
        if ($entryObject.Classification -notin @('exact', 'recoverable')) {
            [void]$errors.Add([pscustomobject]@{ Path = $relativePath; Classification = $entryObject.Classification; Message = $entryObject.Message })
        }
    }

    $status = if ($counts.Missing -gt 0 -or $counts.Invalid -gt 0 -or $counts.Ambiguous -gt 0) { 'FAIL' }
    elseif ($counts.Recoverable -gt 0) { 'REPAIR_REQUIRED' }
    else { 'PASS' }
    return [pscustomobject]@{
        SchemaVersion = 1
        RecordType = 'evidence_byte_integrity_plan'
        Status = $status
        RepositoryRoot = $resolvedRoot
        SnapshotPath = $resolvedSnapshot
        Source = $Source
        Counts = $counts
        Entries = @($entries)
        Errors = @($errors)
    }
}

function Invoke-EvidenceByteIntegrityRepair(
    [object]$Plan,
    [scriptblock]$WriteBytes = { param($Path, $Bytes) [IO.File]::WriteAllBytes($Path, $Bytes) }
) {
    $Plan.Counts.Written = 0
    $rollback = [Collections.Generic.List[object]]::new()
    $reject = $Plan.Source -ne 'WorkingTree' -or $Plan.Counts.Missing -gt 0 -or $Plan.Counts.Invalid -gt 0 -or $Plan.Counts.Ambiguous -gt 0
    $recoverable = @($Plan.Entries | Where-Object Classification -eq 'recoverable')
    if ($recoverable | Where-Object { $null -eq $_.OriginalBytes -or $null -eq $_.CandidateBytes }) { $reject = $true }
    if ($reject) {
        $Plan.Status = 'FAIL'
        $Plan.Errors = @($Plan.Errors) + [pscustomobject]@{ Path = $null; Classification = 'invalid'; Message = 'Apply requires a valid WorkingTree plan with complete recovery bytes.' }
        $Plan | Add-Member -NotePropertyName Rollback -NotePropertyValue @($rollback) -Force
        return $Plan
    }

    $written = [Collections.Generic.List[object]]::new()
    try {
        foreach ($entry in $recoverable) {
            & $WriteBytes $entry.FullPath $entry.CandidateBytes
            [void]$written.Add($entry)
            $writtenHash = Get-ByteIntegritySha256 -Bytes ([IO.File]::ReadAllBytes($entry.FullPath))
            $candidateHash = Get-ByteIntegritySha256 -Bytes $entry.CandidateBytes
            if ($writtenHash -ne $candidateHash) { throw "Post-write hash verification failed: $($entry.Path)" }
        }
        $post = New-EvidenceByteIntegrityPlan -RepositoryRoot $Plan.RepositoryRoot -SnapshotPath $Plan.SnapshotPath -Source WorkingTree
        if ($post.Counts.Recoverable -ne 0 -or $post.Counts.Missing -ne 0 -or $post.Counts.Invalid -ne 0 -or $post.Counts.Ambiguous -ne 0) {
            throw 'Post-write preflight did not reach an exact, non-failing state.'
        }
        $post.Counts.Written = $written.Count
        $post | Add-Member -NotePropertyName Rollback -NotePropertyValue @($rollback) -Force
        return $post
    }
    catch {
        $failureMessage = $_.Exception.Message
        for ($index = $written.Count - 1; $index -ge 0; $index--) {
            $entry = $written[$index]
            try {
                [IO.File]::WriteAllBytes($entry.FullPath, $entry.OriginalBytes)
                [void]$rollback.Add([pscustomobject]@{ Path = $entry.Path; Restored = $true; Message = $null })
            }
            catch {
                [void]$rollback.Add([pscustomobject]@{ Path = $entry.Path; Restored = $false; Message = $_.Exception.Message })
            }
        }
        $Plan.Status = 'FAIL'
        $Plan.Counts.Written = 0
        $Plan.Errors = @($Plan.Errors) + [pscustomobject]@{ Path = $null; Classification = 'invalid'; Message = $failureMessage }
        $Plan | Add-Member -NotePropertyName Rollback -NotePropertyValue @($rollback) -Force
        return $Plan
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        $plan = New-EvidenceByteIntegrityPlan -RepositoryRoot $RepositoryRoot -SnapshotPath $SnapshotPath -Source $Source
        if ($Apply) { $plan = Invoke-EvidenceByteIntegrityRepair -Plan $plan }
    }
    catch {
        $plan = [pscustomobject]@{
            SchemaVersion = 1; RecordType = 'evidence_byte_integrity_plan'; Status = 'FAIL'; RepositoryRoot = $RepositoryRoot; SnapshotPath = $SnapshotPath; Source = $Source
            Counts = [pscustomobject]@{ Exact = 0; Recoverable = 0; Unrecoverable = 0; Missing = 0; Invalid = 1; Ambiguous = 0; Written = 0 }
            Entries = @(); Errors = @([pscustomobject]@{ Path = $null; Classification = 'invalid'; Message = $_.Exception.Message })
        }
    }
    if ($Json) { $plan | ConvertTo-Json -Depth 8 -Compress }
    else {
        Write-Host ("{0}: Exact={1} Recoverable={2} Unrecoverable={3} Missing={4} Invalid={5} Ambiguous={6} Written={7}" -f $plan.Status, $plan.Counts.Exact, $plan.Counts.Recoverable, $plan.Counts.Unrecoverable, $plan.Counts.Missing, $plan.Counts.Invalid, $plan.Counts.Ambiguous, $plan.Counts.Written)
        foreach ($errorEntry in $plan.Errors) { Write-Host ("{0}: {1}" -f $errorEntry.Path, $errorEntry.Message) }
    }
    switch ($plan.Status) { 'PASS' { exit 0 }; 'REPAIR_REQUIRED' { exit 2 }; default { exit 1 } }
}
