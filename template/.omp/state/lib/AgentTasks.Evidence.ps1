#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command Test-AgentTasksCandidateCurrentUnlocked -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'AgentTasks.Candidate.ps1')
}

$script:EvidenceTypes = @{
    test = @{
        CandidateBound = $true
        Producers = @('tech_lead', 'deterministic_runner')
        RequiresInputHashes = $true
    }
    verification = @{
        CandidateBound = $true
        Producers = @('tech_lead', 'deterministic_runner')
        RequiresInputHashes = $true
    }
    review = @{
        CandidateBound = $true
        Producers = @('independent_reviewer')
        RequiresInputHashes = $false
    }
    user_authority = @{
        CandidateBound = $false
        Producers = @('user')
        RequiresInputHashes = $false
    }
    provider_environment = @{
        CandidateBound = $false
        Producers = @('deterministic_probe', 'tech_lead')
        RequiresInputHashes = $false
    }
    external_fact = @{
        CandidateBound = $false
        Producers = @('retrieval_source', 'tech_lead')
        RequiresInputHashes = $false
    }
}

function Test-AgentTasksSensitiveValue {
    param([AllowNull()][object]$Value, [int]$Depth = 0)
    if ($Depth -gt 32) { return $true }
    if ($null -eq $Value) { return $false }
    if ($Value -is [Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            if ([string]$key -match '(?i)(password|passwd|api[_-]?key|access[_-]?token|refresh[_-]?token|secret|credential|private[_-]?key|env_contents)') { return $true }
            if (Test-AgentTasksSensitiveValue -Value $Value[$key] -Depth ($Depth + 1)) { return $true }
        }
        return $false
    }
    if ($Value -is [Collections.IEnumerable] -and $Value -isnot [string]) {
        foreach ($item in $Value) {
            if (Test-AgentTasksSensitiveValue -Value $item -Depth ($Depth + 1)) { return $true }
        }
        return $false
    }
    if ($Value -is [string]) {
        return $Value -match '(?i)(sk-[A-Za-z0-9_-]{8,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(?:api[_-]?key|password|secret|token|credential)\s*[:=]\s*\S+)'
    }
    return $false
}

function Get-AgentTasksCandidateRecord {
    param([Parameter(Mandatory)][object]$Authority, [Parameter(Mandatory)][string]$CandidateId)
    $path = Join-Path $Authority.Root (Join-Path 'candidates' ($CandidateId + '.json'))
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Throw-AgentTasksError -Code 'AT-CANDIDATE-NOT-FOUND' -ExitCode 3 -SafeMessage 'The evidence candidate does not exist.'
    }
    $candidate = Read-AgentTasksJsonFile -LiteralPath $path
    if ([string]$candidate.record_hash -cne (Get-AgentTasksSha256 -Value $candidate)) {
        Throw-AgentTasksError -Code 'AT-CANDIDATE-CORRUPT' -ExitCode 4 -SafeMessage 'The evidence candidate record is corrupt.'
    }
    return $candidate
}

function Get-AgentTasksCandidateInputBindings {
    param([Parameter(Mandatory)][object]$Candidate)
    return @($Candidate.acceptance_inputs | ForEach-Object {
        [ordered]@{ path = [string]$_.path; sha256 = [string]$_.sha256 }
    } | Sort-Object -Property @{ Expression = { [string]$_['path'] } })
}

function Test-AgentTasksInputBindingsEqual {
    param([Parameter(Mandatory)][object[]]$Actual, [Parameter(Mandatory)][object[]]$Expected)
    $normalize = {
        param($items)
        @($items | ForEach-Object {
            if ($_ -isnot [Collections.IDictionary] -or -not $_.Contains('path') -or -not $_.Contains('sha256')) { return '__INVALID__' }
            [ordered]@{ path = [string]$_['path']; sha256 = [string]$_['sha256'] }
        } | Sort-Object -Property @{ Expression = { if ($_ -is [string]) { $_ } else { [string]$_['path'] } } })
    }
    $left = & $normalize $Actual
    $right = & $normalize $Expected
    return (ConvertTo-AgentTasksCanonicalJson -Value $left) -ceq (ConvertTo-AgentTasksCanonicalJson -Value $right)
}

function Assert-AgentTasksEvidenceTriggers {
    param(
        [Parameter(Mandatory)][string]$EvidenceType,
        [Parameter(Mandatory)][object[]]$Triggers
    )
    foreach ($trigger in $Triggers) {
        if ($trigger -isnot [Collections.IDictionary] -or -not $trigger.Contains('kind')) {
            Throw-AgentTasksError -Code 'AT-EVIDENCE-TRIGGER' -ExitCode 2 -SafeMessage 'Each evidence validity trigger must be a named object.'
        }
        if ([string]$trigger.kind -match '(?i)^ttl(?:_|$)|time_to_live') {
            Throw-AgentTasksError -Code 'AT-EVIDENCE-TTL' -ExitCode 2 -SafeMessage 'A global evidence TTL is not supported.'
        }
    }
    if ($EvidenceType -ceq 'external_fact') {
        $fresh = @($Triggers | Where-Object { [string]$_.kind -in @('expires_at', 'fresh_at_acceptance') }).Count -gt 0
        if (-not $fresh) {
            Throw-AgentTasksError -Code 'AT-EVIDENCE-FRESHNESS' -ExitCode 3 -SafeMessage 'External facts require expiry or a fresh-at-acceptance rule.'
        }
    }
}

function Assert-AgentTasksEvidenceEnvironment {
    param([Parameter(Mandatory)][Collections.IDictionary]$Request)
    if (-not $Request.Contains('environment_fingerprint') -or $Request.environment_fingerprint -isnot [Collections.IDictionary]) {
        Throw-AgentTasksError -Code 'AT-EVIDENCE-ENVIRONMENT' -ExitCode 2 -SafeMessage 'Provider/environment evidence requires a structured fingerprint.'
    }
    $allowedFingerprint = [Collections.Generic.HashSet[string]]::new(
        [string[]]@('runtime', 'version', 'platform', 'provider', 'model', 'status'),
        [StringComparer]::Ordinal
    )
    foreach ($key in $Request.environment_fingerprint.Keys) {
        if (-not $allowedFingerprint.Contains([string]$key)) {
            Throw-AgentTasksError -Code 'AT-EVIDENCE-ENVIRONMENT' -ExitCode 2 -SafeMessage 'Provider/environment fingerprint contains a nonallowlisted field.'
        }
    }
    if ($Request.observation -isnot [Collections.IDictionary]) {
        Throw-AgentTasksError -Code 'AT-EVIDENCE-ENVIRONMENT' -ExitCode 2 -SafeMessage 'Provider/environment observation must be structured.'
    }
    $allowedObservation = [Collections.Generic.HashSet[string]]::new(
        [string[]]@('status', 'available', 'reason_code', 'observed_version', 'capabilities'),
        [StringComparer]::Ordinal
    )
    foreach ($key in $Request.observation.Keys) {
        if (-not $allowedObservation.Contains([string]$key)) {
            Throw-AgentTasksError -Code 'AT-EVIDENCE-ENVIRONMENT' -ExitCode 2 -SafeMessage 'Provider/environment observation contains a nonallowlisted field.'
        }
    }
}

function Assert-AgentTasksEvidenceRequest {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$OwnerSessionRef
    )
    $type = [string]$Request.evidence_type
    if (-not $script:EvidenceTypes.ContainsKey($type)) {
        Throw-AgentTasksError -Code 'AT-EVIDENCE-TYPE' -ExitCode 2 -SafeMessage 'The evidence type is not part of the closed registry.'
    }
    $definition = $script:EvidenceTypes[$type]
    $producer = if ($Request.Contains('producer')) { [string]$Request.producer } else { '' }
    if ($producer -notin @($definition.Producers)) {
        Throw-AgentTasksError -Code 'AT-EVIDENCE-PRODUCER' -ExitCode 3 -SafeMessage 'The evidence producer is not authorized for this evidence type.'
    }
    $knownAcIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($criterion in @($Authority.Contract.acceptance_criteria)) { [void]$knownAcIds.Add([string]$criterion.id) }
    foreach ($covered in @($Request.covered_ac_ids)) {
        if (-not $knownAcIds.Contains([string]$covered)) {
            Throw-AgentTasksError -Code 'AT-EVIDENCE-AC' -ExitCode 3 -SafeMessage 'Evidence names an unknown acceptance criterion.'
        }
    }
    Assert-AgentTasksEvidenceTriggers -EvidenceType $type -Triggers @($Request.validity_triggers)
    if ($type -ceq 'provider_environment') { Assert-AgentTasksEvidenceEnvironment -Request $Request }
    if ($type -ceq 'external_fact') {
        if (-not $Request.Contains('source_identity') -or $Request.source_identity -isnot [Collections.IDictionary]) {
            Throw-AgentTasksError -Code 'AT-EVIDENCE-SOURCE' -ExitCode 2 -SafeMessage 'External facts require structured source identity.'
        }
    }
    if ($type -ceq 'user_authority') {
        if (-not $Request.Contains('authority_scope') -or -not $Request.Contains('contract_hash')) {
            Throw-AgentTasksError -Code 'AT-EVIDENCE-AUTHORITY' -ExitCode 2 -SafeMessage 'User authority evidence must bind scope and contract hash.'
        }
        if ([string]$Request.contract_hash -cne (Get-AgentTasksSha256 -Value $Authority.Contract)) {
            Throw-AgentTasksError -Code 'AT-EVIDENCE-AUTHORITY' -ExitCode 3 -SafeMessage 'User authority evidence names a different task contract.'
        }
    }
    if ($definition.CandidateBound) {
        if (-not $Request.Contains('candidate_id') -or [string]::IsNullOrWhiteSpace([string]$Request.candidate_id)) {
            Throw-AgentTasksError -Code 'AT-EVIDENCE-BINDING' -ExitCode 2 -SafeMessage 'This evidence type requires a candidate binding.'
        }
        $candidate = Get-AgentTasksCandidateRecord -Authority $Authority -CandidateId ([string]$Request.candidate_id)
        if ($Authority.Revision.Contains('selected_candidate_id') -and [string]$Authority.Revision.selected_candidate_id -and
            [string]$Authority.Revision.selected_candidate_id -cne [string]$Request.candidate_id) {
            Throw-AgentTasksError -Code 'AT-EVIDENCE-BINDING' -ExitCode 3 -SafeMessage 'Evidence must bind the selected candidate.'
        }
        if ($definition.RequiresInputHashes) {
            if (-not $Request.Contains('acceptance_input_hashes') -or
                -not (Test-AgentTasksInputBindingsEqual -Actual @($Request.acceptance_input_hashes) -Expected @(Get-AgentTasksCandidateInputBindings -Candidate $candidate))) {
                Throw-AgentTasksError -Code 'AT-EVIDENCE-BINDING' -ExitCode 3 -SafeMessage 'Evidence must bind every exact candidate acceptance input.'
            }
        }
        if ($type -ceq 'review') {
            if (-not $Request.Contains('producer_session_ref') -or [string]::IsNullOrWhiteSpace([string]$Request.producer_session_ref) -or
                [string]$Request.producer_session_ref -ceq $OwnerSessionRef) {
                Throw-AgentTasksError -Code 'AT-EVIDENCE-INDEPENDENCE' -ExitCode 3 -SafeMessage 'Review evidence requires an independent producer session.'
            }
        }
    }
    if ($type -ceq 'verification' -and $Request.Contains('input_evidence_ids')) {
        foreach ($evidenceId in @($Request.input_evidence_ids)) {
            $path = Join-Path $Authority.Root (Join-Path 'evidence' ([string]$evidenceId + '.json'))
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                Throw-AgentTasksError -Code 'AT-EVIDENCE-INPUT' -ExitCode 3 -SafeMessage 'Verification names missing input evidence.'
            }
        }
    }
    if ($Request.Contains('artifact_hash')) {
        [void](Get-AgentTasksArtifactMetadata -Authority $Authority -ArtifactHash ([string]$Request.artifact_hash) -VerifyBytes)
    }
    if (Test-AgentTasksSensitiveValue -Value $Request.observation) {
        Throw-AgentTasksError -Code 'AT-EVIDENCE-SECRET' -ExitCode 2 -SafeMessage 'Evidence contains secret-shaped material.'
    }
}

function Get-AgentTasksArtifactMetadata {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$ArtifactHash,
        [switch]$VerifyBytes
    )
    if ($ArtifactHash -notmatch '^[A-F0-9]{64}$') {
        Throw-AgentTasksError -Code 'AT-ARTIFACT-HASH' -ExitCode 3 -SafeMessage 'The artifact hash is invalid.'
    }
    $metadataPath = Join-Path $Authority.Root (Join-Path 'artifacts' ($ArtifactHash + '.json'))
    if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
        Throw-AgentTasksError -Code 'AT-ARTIFACT-MISSING' -ExitCode 3 -SafeMessage 'Artifact metadata does not exist.'
    }
    $metadata = Read-AgentTasksJsonFile -LiteralPath $metadataPath
    if ([string]$metadata.record_hash -cne (Get-AgentTasksSha256 -Value $metadata)) {
        Throw-AgentTasksError -Code 'AT-ARTIFACT-INVALID' -ExitCode 4 -SafeMessage 'Artifact metadata is corrupt.'
    }
    $contentPath = Join-Path $Authority.Root (Join-Path 'artifacts' ([string]$metadata.file_name))
    if ($VerifyBytes) {
        if (-not (Test-Path -LiteralPath $contentPath -PathType Leaf) -or (Get-AgentTasksSha256 -LiteralPath $contentPath) -cne $ArtifactHash) {
            Throw-AgentTasksError -Code 'AT-ARTIFACT-INVALID' -ExitCode 3 -SafeMessage 'Artifact bytes are absent or no longer match their content address.'
        }
    }
    return [pscustomobject]@{ Metadata = $metadata; ContentPath = $contentPath; MetadataPath = $metadataPath }
}

function Add-AgentTasksEvidence {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )
    $taskId = [string]$Request.task_id
    return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain task -Id $taskId -Action {
        $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $taskId
        Assert-AgentTasksTaskCas -Authority $authority -Request $Request -SessionRef $SessionRef
        Assert-AgentTasksEvidenceRequest -Authority $authority -Request $Request -OwnerSessionRef $SessionRef
        $existing = @(Get-ChildItem -LiteralPath (Join-Path $authority.Root 'evidence') -File -Filter 'E*.json')
        $evidenceId = 'E{0:D6}' -f ($existing.Count + 1)
        $record = [ordered]@{
            schema_version = 1; record_type = 'evidence'; evidence_id = $evidenceId
            evidence_type = [string]$Request.evidence_type
            producer = [string]$Request.producer
            producer_session_ref = $(if ($Request.Contains('producer_session_ref')) { [string]$Request.producer_session_ref } else { $null })
            task_id = $taskId
            candidate_id = $(if ($Request.Contains('candidate_id')) { [string]$Request.candidate_id } else { $null })
            candidate_hash = $(if ($Request.Contains('candidate_id')) { [string](Get-AgentTasksCandidateRecord -Authority $authority -CandidateId ([string]$Request.candidate_id)).record_hash } else { $null })
            task_contract_hash = Get-AgentTasksSha256 -Value $authority.Contract
            covered_ac_ids = @($Request.covered_ac_ids | Sort-Object -Unique)
            observation = $Request.observation
            validity_triggers = @($Request.validity_triggers)
            acceptance_input_hashes = $(if ($Request.Contains('acceptance_input_hashes')) { @($Request.acceptance_input_hashes) } else { @() })
            input_evidence_ids = $(if ($Request.Contains('input_evidence_ids')) { @($Request.input_evidence_ids) } else { @() })
            artifact_hash = $(if ($Request.Contains('artifact_hash')) { [string]$Request.artifact_hash } else { $null })
            authority_scope = $(if ($Request.Contains('authority_scope')) { $Request.authority_scope } else { $null })
            environment_fingerprint = $(if ($Request.Contains('environment_fingerprint')) { $Request.environment_fingerprint } else { $null })
            source_identity = $(if ($Request.Contains('source_identity')) { $Request.source_identity } else { $null })
            created_at = Get-AgentTasksUtcTimestamp
        }
        $publishedEvidence = Publish-AgentTasksRecord -LiteralPath (Join-Path $authority.Root (Join-Path 'evidence' ($evidenceId + '.json'))) -Value $record
        $revision = Publish-AgentTasksTaskRevisionUnlocked -Authority $authority -Mutator {
            param($next)
            $prior = if ($next.Contains('evidence_ids')) { @($next.evidence_ids) } else { @() }
            $next.evidence_ids = @(@($prior) + @($evidenceId) | Sort-Object -Unique)
            $next.supporting_refs = @(@($next.supporting_refs) + @($evidenceId) | Sort-Object -Unique)
        }
        return [ordered]@{
            task_id = $taskId; evidence_id = $evidenceId
            evidence_hash = [string]$publishedEvidence.Record.record_hash
            evidence_type = [string]$Request.evidence_type
            covered_ac_ids = @($record.covered_ac_ids)
            revision = [long]$revision.Record.revision
            revision_sha256 = [string]$revision.Sha256
        }
    }
}

function Assert-AgentTasksArtifactSource {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$SourcePath
    )
    $worktree = [string]$Authority.Revision.authoritative_worktree
    $allowedRoot = [IO.Path]::GetFullPath((Join-Path $worktree (Join-Path '.task' ([string]$Authority.Contract.task_id)))).TrimEnd('\', '/')
    $source = if ([IO.Path]::IsPathFullyQualified($SourcePath)) {
        [IO.Path]::GetFullPath($SourcePath)
    } else {
        [IO.Path]::GetFullPath((Join-Path $worktree $SourcePath))
    }
    if (-not (Test-AgentTasksPathInside -Root $allowedRoot -Candidate $source) -or -not (Test-Path -LiteralPath $source -PathType Leaf)) {
        Throw-AgentTasksError -Code 'AT-ARTIFACT-SOURCE' -ExitCode 3 -SafeMessage 'Artifact source is outside the registered task scratch root.'
    }
    $cursor = $source
    while ($cursor -and (Test-AgentTasksPathInside -Root $allowedRoot -Candidate $cursor)) {
        $item = Get-Item -LiteralPath $cursor -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            Throw-AgentTasksError -Code 'AT-ARTIFACT-REPARSE' -ExitCode 3 -SafeMessage 'Artifact source traverses a reparse point.'
        }
        if ($cursor -ceq $allowedRoot) { break }
        $cursor = Split-Path -Parent $cursor
    }
    if ([IO.Path]::GetFileName($source) -match '(?i)^\.env(?:\.|$)') {
        Throw-AgentTasksError -Code 'AT-ARTIFACT-SECRET' -ExitCode 2 -SafeMessage 'Raw environment files cannot be promoted.'
    }
    return $source
}

function Copy-AgentTasksPromotedArtifact {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )
    $taskId = [string]$Request.task_id
    return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain task -Id $taskId -Action {
        $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $taskId
        Assert-AgentTasksTaskCas -Authority $authority -Request $Request -SessionRef $SessionRef
        if ($Request.Contains('candidate_id')) { [void](Get-AgentTasksCandidateRecord -Authority $authority -CandidateId ([string]$Request.candidate_id)) }
        $source = Assert-AgentTasksArtifactSource -Authority $authority -SourcePath ([string]$Request.source_path)
        $info = Get-Item -LiteralPath $source -Force
        if ($info.Length -gt 2MB) {
            Throw-AgentTasksError -Code 'AT-ARTIFACT-LIMIT' -ExitCode 3 -SafeMessage 'Artifact exceeds the default promoted-artifact byte limit.'
        }
        $bytes = [IO.File]::ReadAllBytes($source)
        $text = $null
        try { $text = [Text.UTF8Encoding]::new($false, $true).GetString($bytes) } catch { $text = $null }
        if ($null -ne $text -and (Test-AgentTasksSensitiveValue -Value $text)) {
            Throw-AgentTasksError -Code 'AT-ARTIFACT-SECRET' -ExitCode 2 -SafeMessage 'Artifact contains secret-shaped material.'
        }
        $hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
        $extension = [IO.Path]::GetExtension($source).TrimStart('.').ToLowerInvariant()
        if ($extension -notmatch '^[a-z0-9]{1,10}$') { $extension = 'bin' }
        $fileName = $hash + '.' + $extension
        $destination = Join-Path $authority.Root (Join-Path 'artifacts' $fileName)
        if (Test-Path -LiteralPath $destination -PathType Leaf) {
            if ((Get-AgentTasksSha256 -LiteralPath $destination) -cne $hash) {
                Throw-AgentTasksError -Code 'AT-ARTIFACT-INVALID' -ExitCode 4 -SafeMessage 'An existing content-addressed artifact has different bytes.'
            }
        } else {
            $stream = [IO.FileStream]::new($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        }
        $metadataPath = Join-Path $authority.Root (Join-Path 'artifacts' ($hash + '.json'))
        if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
            [void](Publish-AgentTasksRecord -LiteralPath $metadataPath -Value ([ordered]@{
                schema_version = 1; record_type = 'artifact_metadata'; artifact_id = 'A-' + $hash.Substring(0, 16)
                sha256 = $hash; file_name = $fileName; media_type = [string]$Request.media_type
                byte_length = [long]$bytes.Length; candidate_id = $(if ($Request.Contains('candidate_id')) { [string]$Request.candidate_id } else { $null })
                handoff_id = $(if ($Request.Contains('handoff_id')) { [string]$Request.handoff_id } else { $null })
                created_at = Get-AgentTasksUtcTimestamp
            }))
        } else {
            [void](Get-AgentTasksArtifactMetadata -Authority $authority -ArtifactHash $hash -VerifyBytes)
        }
        $revision = Publish-AgentTasksTaskRevisionUnlocked -Authority $authority -Mutator {
            param($next)
            $prior = if ($next.Contains('artifact_hashes')) { @($next.artifact_hashes) } else { @() }
            $next.artifact_hashes = @(@($prior) + @($hash) | Sort-Object -Unique)
        }
        return [ordered]@{
            task_id = $taskId; artifact_id = 'A-' + $hash.Substring(0, 16)
            artifact_hash = $hash; artifact_path = $destination
            revision = [long]$revision.Record.revision; revision_sha256 = [string]$revision.Sha256
        }
    }
}

function Test-AgentTasksEvidencePasses {
    param([Parameter(Mandatory)][object]$Evidence)
    if ($Evidence.observation -is [Collections.IDictionary]) {
        if ($Evidence.observation.Contains('status') -and [string]$Evidence.observation.status -notin @('PASS', 'pass', 'passed', 'available')) { return $false }
        if ($Evidence.observation.Contains('verdict') -and [string]$Evidence.observation.verdict -notin @('PASS', 'pass', 'APPROVED', 'approved')) { return $false }
        if ($Evidence.observation.Contains('blocking_findings') -and @($Evidence.observation.blocking_findings).Count -gt 0) { return $false }
        if ($Evidence.observation.Contains('conflicts') -and @($Evidence.observation.conflicts).Count -gt 0) { return $false }
    }
    return $true
}

function Test-AgentTasksAcceptance {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][object]$Candidate
    )
    $evidenceRecords = [Collections.Generic.List[object]]::new()
    foreach ($evidenceId in $(if ($Authority.Revision.Contains('evidence_ids')) { @($Authority.Revision.evidence_ids) } else { @() })) {
        $path = Join-Path $Authority.Root (Join-Path 'evidence' ([string]$evidenceId + '.json'))
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        $record = Read-AgentTasksJsonFile -LiteralPath $path
        if ([string]$record.record_hash -cne (Get-AgentTasksSha256 -Value $record)) { continue }
        if ([string]$record.candidate_id -and [string]$record.candidate_id -cne [string]$Candidate.candidate_id) { continue }
        if ([string]$record.candidate_id -and [string]$record.candidate_hash -cne [string]$Candidate.record_hash) { continue }
        $recordInputBindings = @($record.acceptance_input_hashes | Where-Object { $null -ne $_ })
        if ($recordInputBindings.Count -gt 0) {
            $candidateInputBindings = @(Get-AgentTasksCandidateInputBindings -Candidate $Candidate)
            if (-not (Test-AgentTasksInputBindingsEqual -Actual $recordInputBindings -Expected $candidateInputBindings)) { continue }
        }
        if ($record.artifact_hash) { [void](Get-AgentTasksArtifactMetadata -Authority $Authority -ArtifactHash ([string]$record.artifact_hash) -VerifyBytes) }
        if (Test-AgentTasksEvidencePasses -Evidence $record) { [void]$evidenceRecords.Add($record) }
    }
    $covered = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $types = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($record in $evidenceRecords) {
        [void]$types.Add([string]$record.evidence_type)
        foreach ($acId in @($record.covered_ac_ids)) { [void]$covered.Add([string]$acId) }
    }
    $missingAc = @($Authority.Contract.acceptance_criteria | Where-Object { $_.mandatory -and -not $covered.Contains([string]$_.id) } | ForEach-Object id)
    $missingTypes = @($Authority.Contract.obligations | Where-Object { -not $types.Contains([string]$_) })
    return [pscustomobject]@{
        Valid = $missingAc.Count -eq 0 -and $missingTypes.Count -eq 0
        MissingAcceptanceCriteria = $missingAc
        MissingObligations = $missingTypes
        EvidenceIds = @($evidenceRecords | ForEach-Object evidence_id)
    }
}

function Set-AgentTasksTerminalState {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )
    $taskId = [string]$Request.task_id
    return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain task -Id $taskId -Action {
        $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $taskId
        Assert-AgentTasksTaskCas -Authority $authority -Request $Request -SessionRef $SessionRef
        $target = [string]$Request.terminal_status
        if ($target -notin @('accepted', 'cancelled', 'terminally_blocked')) {
            Throw-AgentTasksError -Code 'AT-TERMINAL-STATUS' -ExitCode 2 -SafeMessage 'The requested terminal status is unsupported.'
        }
        if ($target -notin @($script:TaskTransitions[[string]$authority.Revision.status])) {
            Throw-AgentTasksError -Code 'AT-TASK-TRANSITION' -ExitCode 3 -SafeMessage 'The requested terminal transition is not allowed.'
        }
        $candidate = $null
        $evidenceIds = @()
        if ($target -ceq 'accepted') {
            if (-not $Request.Contains('candidate_id') -or [string]$Request.candidate_id -cne [string]$authority.Revision.selected_candidate_id) {
                Throw-AgentTasksError -Code 'AT-ACCEPTANCE-CANDIDATE' -ExitCode 3 -SafeMessage 'Acceptance must name the selected frozen candidate.'
            }
            $comparison = Test-AgentTasksCandidateCurrentUnlocked -Authority $authority -CandidateId ([string]$Request.candidate_id)
            if (-not $comparison.Valid) {
                Throw-AgentTasksError -Code 'AT-CANDIDATE-DRIFT' -ExitCode 3 -SafeMessage 'Candidate bytes drifted before acceptance.'
            }
            $candidate = $comparison.Candidate
            $acceptance = Test-AgentTasksAcceptance -Authority $authority -Candidate $candidate
            if (-not $acceptance.Valid) {
                Throw-AgentTasksError -Code 'AT-ACCEPTANCE-EVIDENCE' -ExitCode 3 -SafeMessage 'Mandatory acceptance criteria or evidence obligations are not satisfied.'
            }
            $evidenceIds = @($acceptance.EvidenceIds)
        } else {
            if (-not $Request.Contains('reason') -or [string]::IsNullOrWhiteSpace([string]$Request.reason)) {
                Throw-AgentTasksError -Code 'AT-TERMINAL-REASON' -ExitCode 2 -SafeMessage 'Cancelled and terminally blocked tasks require a compact reason.'
            }
        }
        $revision = Publish-AgentTasksTaskRevisionUnlocked -Authority $authority -Mutator {
            param($next)
            $next.status = $target
            $next.terminal_reason = $(if ($target -ceq 'accepted') { $null } else { [string]$Request.reason })
            if ($target -ceq 'accepted') {
                $next.accepted_candidate_id = [string]$candidate.candidate_id
                $next.accepted_candidate_hash = [string]$candidate.record_hash
                $next.acceptance_evidence_ids = @($evidenceIds)
                $next.historical_acceptance_validity = 'valid'
            } else {
                $next.accepted_candidate_id = $null
                $next.accepted_candidate_hash = $null
            }
        }
        return [ordered]@{
            task_id = $taskId; status = $target
            candidate_id = $(if ($target -ceq 'accepted') { [string]$candidate.candidate_id } else { $null })
            candidate_hash = $(if ($target -ceq 'accepted') { [string]$candidate.record_hash } else { $null })
            revision = [long]$revision.Record.revision; revision_sha256 = [string]$revision.Sha256
        }
    }
}

function Invalidate-AgentTasksHistory {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )
    $taskId = [string]$Request.task_id
    return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain task -Id $taskId -Action {
        $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $taskId
        Assert-AgentTasksTaskCas -Authority $authority -Request $Request -SessionRef $SessionRef
        if ([string]$authority.Revision.status -cne 'accepted') {
            Throw-AgentTasksError -Code 'AT-INVALIDATE-STATE' -ExitCode 3 -SafeMessage 'Only an accepted historical decision can be invalidated.'
        }
        if ([string]$Request.target_type -ceq 'candidate') {
            [void](Get-AgentTasksCandidateRecord -Authority $authority -CandidateId ([string]$Request.target_id))
        } elseif ([string]$Request.target_type -ceq 'evidence') {
            if (-not (Test-Path -LiteralPath (Join-Path $authority.Root (Join-Path 'evidence' ([string]$Request.target_id + '.json'))))) {
                Throw-AgentTasksError -Code 'AT-EVIDENCE-NOT-FOUND' -ExitCode 3 -SafeMessage 'The invalidation evidence target does not exist.'
            }
        } else {
            Throw-AgentTasksError -Code 'AT-INVALIDATE-TARGET' -ExitCode 2 -SafeMessage 'The invalidation target type is unsupported.'
        }
        $invalidationsRoot = Join-Path $authority.Root 'invalidations'
        [void](New-Item -ItemType Directory -Path $invalidationsRoot -Force)
        $existing = @(Get-ChildItem -LiteralPath $invalidationsRoot -File -Filter 'I*.json')
        $invalidationId = 'I{0:D6}' -f ($existing.Count + 1)
        [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $invalidationsRoot ($invalidationId + '.json')) -Value ([ordered]@{
            schema_version = 1; record_type = 'invalidation'; invalidation_id = $invalidationId
            task_id = $taskId; target_type = [string]$Request.target_type; target_id = [string]$Request.target_id
            reason = [string]$Request.reason
            remediation_task_id = $(if ($Request.Contains('remediation_task_id')) { [string]$Request.remediation_task_id } else { $null })
            created_at = Get-AgentTasksUtcTimestamp
        }))
        $revision = Publish-AgentTasksTaskRevisionUnlocked -Authority $authority -Mutator {
            param($next)
            $next.historical_acceptance_validity = 'invalidated'
            $prior = if ($next.Contains('invalidation_ids')) { @($next.invalidation_ids) } else { @() }
            $next.invalidation_ids = @(@($prior) + @($invalidationId) | Sort-Object -Unique)
            if ($Request.Contains('remediation_task_id')) { $next.remediation_task_id = [string]$Request.remediation_task_id }
        }
        return [ordered]@{
            task_id = $taskId; invalidation_id = $invalidationId
            historical_acceptance_validity = 'invalidated'
            revision = [long]$revision.Record.revision; revision_sha256 = [string]$revision.Sha256
        }
    }
}
