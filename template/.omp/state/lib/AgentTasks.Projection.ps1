#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-AgentTasksProjectionRecordHash {
    param(
        [Parameter(Mandatory)][object]$Record,
        [Parameter(Mandatory)][string]$ExpectedRecordType,
        [Parameter(Mandatory)][string]$ErrorCode,
        [Parameter(Mandatory)][string]$SafeMessage
    )

    if (
        $Record -isnot [Collections.IDictionary] -or
        -not $Record.Contains('record_hash') -or
        [string]$Record.record_type -cne $ExpectedRecordType -or
        [string]$Record.record_hash -cne (Get-AgentTasksSha256 -Value $Record)
    ) {
        Throw-AgentTasksError -Code $ErrorCode -ExitCode 4 -SafeMessage $SafeMessage
    }
}

function Get-AgentTasksProjectionArtifactRefs {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][object]$Candidate
    )

    $knownOutcomes = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($outcomeId in @($Authority.Revision.work_unit_outcome_ids)) {
        [void]$knownOutcomes.Add([string]$outcomeId)
    }

    $artifactRefs = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($outcomeIdValue in @($Candidate.integration_provenance)) {
        $outcomeId = [string]$outcomeIdValue
        Assert-AgentTasksIdentifier -Id $outcomeId -Code 'AT-WORK-UNIT-OUTCOME-ID'
        if (-not $knownOutcomes.Contains($outcomeId)) {
            Throw-AgentTasksError -Code 'AT-PROJECTION-STALE' -ExitCode 3 -SafeMessage 'The candidate references an outcome outside current task authority.'
        }
        $outcomePath = Join-Path $Authority.Root (Join-Path 'work-units' ($outcomeId + '.json'))
        if (-not (Test-Path -LiteralPath $outcomePath -PathType Leaf)) {
            Throw-AgentTasksError -Code 'AT-PROJECTION-STALE' -ExitCode 3 -SafeMessage 'A candidate outcome binding is unavailable.'
        }
        $outcome = Read-AgentTasksJsonFile -LiteralPath $outcomePath
        Assert-AgentTasksProjectionRecordHash -Record $outcome -ExpectedRecordType 'work_unit_outcome' `
            -ErrorCode 'AT-PROJECTION-CORRUPT' -SafeMessage 'A candidate outcome binding is corrupt.'
        if ([string]$outcome.outcome_id -cne $outcomeId) {
            Throw-AgentTasksError -Code 'AT-PROJECTION-CORRUPT' -ExitCode 4 -SafeMessage 'A candidate outcome identity is inconsistent.'
        }
        foreach ($artifactRefValue in @($outcome.artifact_refs)) {
            $artifactRef = [string]$artifactRefValue
            if (-not [string]::IsNullOrWhiteSpace($artifactRef)) {
                [void]$artifactRefs.Add($artifactRef)
            }
        }
    }
    return @($artifactRefs | Sort-Object)
}

function ConvertTo-AgentTasksProjectionCandidateBinding {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [AllowNull()][object]$Candidate
    )

    if ($null -eq $Candidate) {
        return [ordered]@{
            candidate_id = $null
            candidate_sha256 = $null
            diff_ref = $null
            artifact_refs = @()
        }
    }

    return [ordered]@{
        candidate_id = [string]$Candidate.candidate_id
        candidate_sha256 = [string]$Candidate.record_hash
        diff_ref = Get-AgentTasksSha256 -Value @($Candidate.entries)
        artifact_refs = @(Get-AgentTasksProjectionArtifactRefs -Authority $Authority -Candidate $Candidate)
    }
}

function Get-AgentTasksProjectionCandidateBinding {
    param([Parameter(Mandatory)][object]$Authority)

    $candidateId = if ($Authority.Revision.Contains('selected_candidate_id')) {
        [string]$Authority.Revision.selected_candidate_id
    } else {
        ''
    }
    if ([string]::IsNullOrWhiteSpace($candidateId)) {
        return ConvertTo-AgentTasksProjectionCandidateBinding -Authority $Authority -Candidate $null
    }

    $comparison = Test-AgentTasksCandidateCurrentUnlocked -Authority $Authority -CandidateId $candidateId
    if (-not $comparison.Valid) {
        Throw-AgentTasksError -Code 'AT-CANDIDATE-DRIFT' -ExitCode 3 -SafeMessage 'The selected candidate drifted before projection.'
    }
    $candidate = $comparison.Candidate
    if (
        $Authority.Revision.Contains('selected_candidate_hash') -and
        -not [string]::IsNullOrWhiteSpace([string]$Authority.Revision.selected_candidate_hash) -and
        [string]$Authority.Revision.selected_candidate_hash -cne [string]$candidate.record_hash
    ) {
        Throw-AgentTasksError -Code 'AT-CANDIDATE-DRIFT' -ExitCode 3 -SafeMessage 'The selected candidate hash is stale.'
    }
    return ConvertTo-AgentTasksProjectionCandidateBinding -Authority $Authority -Candidate $candidate
}

function Assert-AgentTasksProjectionAuthority {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$TaskId
    )

    $activeTasksRoot = [IO.Path]::GetFullPath((Join-Path $Context.StateRoot 'tasks')).TrimEnd('\', '/')
    $authorityParent = [IO.Path]::GetFullPath((Split-Path -Parent $Authority.Root)).TrimEnd('\', '/')
    if ($authorityParent -cne $activeTasksRoot) {
        Throw-AgentTasksError -Code 'AT-PROJECTION-INACTIVE' -ExitCode 3 -SafeMessage 'Only an active task can be projected.'
    }
    if (
        [string]$Authority.Contract.task_id -cne $TaskId -or
        [string]$Authority.Revision.task_id -cne $TaskId
    ) {
        Throw-AgentTasksError -Code 'AT-PROJECTION-CORRUPT' -ExitCode 4 -SafeMessage 'Task authority identity is inconsistent.'
    }
    Assert-AgentTasksProjectionRecordHash -Record $Authority.Contract -ExpectedRecordType 'task_contract' `
        -ErrorCode 'AT-PROJECTION-CORRUPT' -SafeMessage 'The task contract is corrupt.'
    if (
        [string]$Authority.Revision.status -in @('accepted', 'cancelled', 'terminally_blocked', 'transferring', 'reconcile_required') -or
        [string]$Authority.Revision.lease_status -cne 'active' -or
        [string]::IsNullOrWhiteSpace([string]$Authority.Revision.owner_session_ref)
    ) {
        Throw-AgentTasksError -Code 'AT-PROJECTION-INACTIVE' -ExitCode 3 -SafeMessage 'Only an active task with a current owner can be projected.'
    }

    $currentWorktree = [IO.Path]::GetFullPath($Context.WorktreeRoot).TrimEnd('\', '/')
    $observationWorktree = [IO.Path]::GetFullPath([string]$Authority.Revision.observation_worktree).TrimEnd('\', '/')
    if ($currentWorktree -cne $observationWorktree) {
        Throw-AgentTasksError -Code 'AT-PROJECTION-WORKTREE' -ExitCode 3 -SafeMessage 'The caller is not observing the task-bound worktree.'
    }
    if (
        [string]$Authority.Contract.execution_mode -ceq 'mutating' -and
        [string]::IsNullOrWhiteSpace([string]$Authority.Revision.authoritative_worktree)
    ) {
        Throw-AgentTasksError -Code 'AT-PROJECTION-WORKTREE' -ExitCode 3 -SafeMessage 'The mutating task has no authoritative worktree binding.'
    }
}

function Get-AgentTasksWorkUnitProjection {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$TaskId,
        [Parameter(Mandatory)][string]$WorkUnitId
    )

    Assert-AgentTasksIdentifier -Id $TaskId -Code 'AT-TASK-ID'
    Assert-AgentTasksIdentifier -Id $WorkUnitId -Code 'AT-WORK-UNIT-ID'
    $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $TaskId
    Assert-AgentTasksProjectionAuthority -Context $Context -Authority $authority -TaskId $TaskId

    $workUnitPath = Join-Path $authority.Root (Join-Path 'work-units' ($WorkUnitId + '.json'))
    if (-not (Test-Path -LiteralPath $workUnitPath -PathType Leaf)) {
        Throw-AgentTasksError -Code 'AT-WORK-UNIT-NOT-FOUND' -ExitCode 3 -SafeMessage 'The work-unit contract does not exist.'
    }
    $workUnit = Read-AgentTasksJsonFile -LiteralPath $workUnitPath
    Assert-AgentTasksProjectionRecordHash -Record $workUnit -ExpectedRecordType 'work_unit_contract' `
        -ErrorCode 'AT-WORK-UNIT-CORRUPT' -SafeMessage 'The work-unit contract is corrupt.'
    if ([string]$workUnit.work_unit_id -cne $WorkUnitId) {
        Throw-AgentTasksError -Code 'AT-WORK-UNIT-CORRUPT' -ExitCode 4 -SafeMessage 'The work-unit identity is inconsistent.'
    }
    if (@($authority.Revision.work_unit_ids | Where-Object { [string]$_ -ceq $WorkUnitId }).Count -ne 1) {
        Throw-AgentTasksError -Code 'AT-WORK-UNIT-UNLISTED' -ExitCode 3 -SafeMessage 'The work-unit contract is outside current task authority.'
    }
    foreach ($dependencyValue in @($workUnit.dependencies)) {
        $dependency = [string]$dependencyValue
        if (@($authority.Revision.work_unit_ids | Where-Object { [string]$_ -ceq $dependency }).Count -ne 1) {
            Throw-AgentTasksError -Code 'AT-WORK-UNIT-INCOMPATIBLE' -ExitCode 3 -SafeMessage 'A work-unit dependency is outside current task authority.'
        }
    }
    if ([string]$authority.Contract.execution_mode -ceq 'mutating') {
        foreach ($ownedPathValue in @($workUnit.ownership)) {
            $ownedPath = [string]$ownedPathValue
            if (-not (Test-AgentTasksPathInScope -Path $ownedPath -Scope @($authority.Contract.write_scope))) {
                Throw-AgentTasksError -Code 'AT-WORK-UNIT-INCOMPATIBLE' -ExitCode 3 -SafeMessage 'Work-unit ownership exceeds the task write scope.'
            }
        }
    }

    $candidateBinding = Get-AgentTasksProjectionCandidateBinding -Authority $authority
    $projection = [ordered]@{
        schema_version = 1
        record_type = 'work_unit_projection'
        task = [ordered]@{
            task_id = $TaskId
            status = [string]$authority.Revision.status
            objective = [string]$authority.Contract.objective
            authority = @($authority.Contract.authority)
            execution_mode = [string]$authority.Contract.execution_mode
            write_scope = @($authority.Contract.write_scope)
            acceptance_criteria = @($authority.Contract.acceptance_criteria)
            obligations = @($authority.Contract.obligations)
            owned_ignored_outputs = @($authority.Contract.owned_ignored_outputs)
        }
        work_unit = [ordered]@{
            work_unit_id = $WorkUnitId
            inputs = @($workUnit.inputs)
            outputs = @($workUnit.outputs)
            ownership = @($workUnit.ownership)
            dependencies = @($workUnit.dependencies)
            completion_conditions = @($workUnit.completion_conditions)
        }
        binding = [ordered]@{
            observation_worktree = [string]$authority.Revision.observation_worktree
            authoritative_worktree = $(if ([string]::IsNullOrWhiteSpace([string]$authority.Revision.authoritative_worktree)) { $null } else { [string]$authority.Revision.authoritative_worktree })
            candidate_id = $candidateBinding.candidate_id
            candidate_sha256 = $candidateBinding.candidate_sha256
            diff_ref = $candidateBinding.diff_ref
            artifact_refs = @($candidateBinding.artifact_refs)
        }
        cas = [ordered]@{
            revision = [long]$authority.Revision.revision
            revision_sha256 = [string]$authority.RevisionSha256
            lease_generation = [long]$authority.Revision.lease_generation
        }
    }
    $projection.projection_sha256 = Get-AgentTasksSha256 -Value $projection
    return $projection
}

function ConvertTo-AgentTasksContinuityHash {
    param([AllowNull()][object]$Value)
    if ($Value -isnot [string] -or [string]$Value -cnotmatch '^[A-Fa-f0-9]{64}$') {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'A continuity authority hash is invalid.'
    }
    return ([string]$Value).ToLowerInvariant()
}

function ConvertTo-AgentTasksProjectionText {
    param(
        [AllowNull()][object]$Value,
        [Parameter(Mandatory)][int]$MaximumUtf8Bytes
    )
    if ($Value -isnot [string]) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'A continuity text field is invalid.'
    }
    try {
        $normalized = ([string]$Value).Replace("`r`n", "`n").Replace("`r", "`n").Normalize([Text.NormalizationForm]::FormC)
        $byteCount = [Text.UTF8Encoding]::new($false, $true).GetByteCount($normalized)
    } catch {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'A continuity text field is invalid.'
    }
    if ([string]::IsNullOrWhiteSpace($normalized) -or $normalized.Contains([char]0)) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'A continuity text field is invalid.'
    }
    if ($byteCount -gt $MaximumUtf8Bytes) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-TOO-LARGE' -ExitCode 4 -SafeMessage 'A continuity text field exceeds a managed bound.'
    }
    foreach ($pattern in @(
        '(?i)(?:authorization\s*:\s*)?bearer\s+[A-Za-z0-9._~+/=-]{8,}',
        '\beyJ[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{6,}\b',
        '\bgh[pousr]_[A-Za-z0-9]{20,}\b',
        '\bAKIA[0-9A-Z]{16}\b',
        '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'
    )) {
        if ($normalized -match $pattern) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'A continuity text field contains prohibited content.'
        }
    }
    return $normalized
}

function ConvertTo-AgentTasksContinuityStringArray {
    param(
        [AllowNull()][object]$Value,
        [int]$MaximumItems = 128,
        [int]$MaximumUtf8Bytes = 1024
    )
    if ($null -eq $Value -or $Value -is [string] -or $Value -is [Collections.IDictionary] -or $Value -isnot [Collections.IEnumerable]) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'A continuity string collection is invalid.'
    }
    $items = @($Value)
    if ($items.Count -gt $MaximumItems) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-TOO-LARGE' -ExitCode 4 -SafeMessage 'The continuity projection exceeds a managed bound.'
    }
    return @($items | ForEach-Object {
        try {
            ConvertTo-AgentTasksProjectionText -Value $_ -MaximumUtf8Bytes $MaximumUtf8Bytes
        } catch {
            if ([string]$_.Exception.Data['AgentTasksCode'] -in @('AT-CONTINUITY-CORRUPT', 'AT-CONTINUITY-TOO-LARGE')) { throw }
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'A continuity string collection is invalid.'
        }
    })
}

function ConvertTo-AgentTasksContinuityWriteScope {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value -or $Value -is [string] -or $Value -is [Collections.IDictionary] -or $Value -isnot [Collections.IEnumerable]) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity write scope is invalid.'
    }
    $items = @($Value)
    if ($items.Count -gt 128) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-TOO-LARGE' -ExitCode 4 -SafeMessage 'The continuity projection exceeds a managed bound.'
    }
    $identities = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $byIdentity = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    foreach ($entry in $items) {
        if ($entry -isnot [Collections.IDictionary] -or $entry.kind -isnot [string] -or [string]$entry.kind -cnotin @('exact', 'subtree', 'glob')) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity write scope is invalid.'
        }
        $kind = [string]$entry.kind
        $field = if ($kind -ceq 'glob') { 'pattern' } else { 'path' }
        try { Assert-AgentTasksClosedObject -Value $entry -Allowed @('kind', $field) -Required @('kind', $field) } catch {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity write scope is invalid.'
        }
        $relative = ConvertTo-AgentTasksProjectionText -Value $entry[$field] -MaximumUtf8Bytes 1024
        if (
            $relative.Contains('\') -or $relative.StartsWith('/', [StringComparison]::Ordinal) -or
            $relative -match '^[A-Za-z]:' -or @($relative -split '/') -contains '' -or
            @($relative -split '/') -contains '.' -or @($relative -split '/') -contains '..'
        ) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity write scope is invalid.'
        }
        $copy = [ordered]@{ kind = $kind }; $copy[$field] = $relative
        $identity = ConvertTo-AgentTasksCanonicalJson -Value $copy
        if (-not $identities.Add($identity)) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity write scope is invalid.'
        }
        $byIdentity[$identity] = $copy
    }
    [string[]]$keys = @($byIdentity.Keys)
    [Array]::Sort($keys, [StringComparer]::Ordinal)
    return @($keys | ForEach-Object { $byIdentity[$_] })
}

function ConvertTo-AgentTasksContinuityAcceptanceCriteria {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value -or $Value -is [string] -or $Value -is [Collections.IDictionary] -or $Value -isnot [Collections.IEnumerable]) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity acceptance criteria are invalid.'
    }
    $items = @($Value)
    if ($items.Count -gt 128) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-TOO-LARGE' -ExitCode 4 -SafeMessage 'The continuity projection exceeds a managed bound.'
    }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $mandatoryCount = 0
    $result = [Collections.Generic.List[object]]::new()
    foreach ($item in $items) {
        if ($item -isnot [Collections.IDictionary]) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity acceptance criteria are invalid.'
        }
        try { Assert-AgentTasksClosedObject -Value $item -Allowed @('id', 'text', 'mandatory') -Required @('id', 'text', 'mandatory') } catch {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity acceptance criteria are invalid.'
        }
        if ($item.id -isnot [string] -or [string]$item.id -cnotmatch '^AC-[A-Z0-9][A-Z0-9._-]{0,79}$' -or $item.mandatory -isnot [bool]) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity acceptance criteria are invalid.'
        }
        $id = [string]$item.id
        if (-not $seen.Add($id)) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity acceptance criteria are invalid.'
        }
        if ([bool]$item.mandatory) { $mandatoryCount++ }
        [void]$result.Add([ordered]@{
            id = $id
            text = ConvertTo-AgentTasksProjectionText -Value $item.text -MaximumUtf8Bytes 2048
            mandatory = [bool]$item.mandatory
        })
    }
    if ($mandatoryCount -eq 0) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The task has no mandatory continuity acceptance criterion.'
    }
    return $result.ToArray()
}

function Test-AgentTasksContinuitySessionIdentity {
    param(
        [Parameter(Mandatory)][string]$TaskRoot,
        [Parameter(Mandatory)][string]$SessionRef,
        [Parameter(Mandatory)][string]$Runtime
    )
    $identityName = (Get-AgentTasksSha256 -Value $SessionRef).Substring(0, 16) + '.json'
    $path = Join-Path $TaskRoot (Join-Path 'sessions' $identityName)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
    try {
        $record = Read-AgentTasksJsonFile -LiteralPath $path
        if (
            $record -isnot [Collections.IDictionary] -or [string]$record.record_type -cne 'session_identity' -or
            -not $record.Contains('record_hash') -or [string]$record.record_hash -cne (Get-AgentTasksSha256 -Value $record)
        ) { return $false }
        return [string]$record.session_ref -ceq $SessionRef -and [string]$record.runtime -ceq $Runtime
    } catch { return $false }
}

function Get-AgentTasksContinuityOwnedAuthority {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$SessionRef,
        [Parameter(Mandatory)][string]$Runtime
    )
    $tasksRoot = Join-Path $Context.StateRoot 'tasks'
    $matches = [Collections.Generic.List[object]]::new()
    $inactiveMatches = 0
    if (Test-Path -LiteralPath $tasksRoot -PathType Container) {
        foreach ($directory in Get-ChildItem -LiteralPath $tasksRoot -Directory | Sort-Object Name) {
            $hasMatchingIdentity = Test-AgentTasksContinuitySessionIdentity -TaskRoot $directory.FullName -SessionRef $SessionRef -Runtime $Runtime
            try {
                $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $directory.Name
            } catch {
                if ($hasMatchingIdentity) {
                    Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'Owned task authority requires reconciliation.'
                }
                continue
            }
            if ([string]$authority.Revision.owner_session_ref -cne $SessionRef -or [string]$authority.Revision.owner_runtime -cne $Runtime) { continue }
            if (
                [string]$authority.Revision.status -cnotin @('active', 'candidate_frozen', 'rework') -or
                [string]$authority.Revision.lease_status -cne 'active' -or [long]$authority.Revision.lease_generation -lt 1
            ) {
                $inactiveMatches++
                continue
            }
            [void]$matches.Add($authority)
        }
    }
    if ($matches.Count -eq 0) {
        if ($inactiveMatches -gt 0) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-INACTIVE' -ExitCode 3 -SafeMessage 'The current session task is not active for continuity projection.'
        }
        Throw-AgentTasksError -Code 'AT-CONTINUITY-TASK-NOT-FOUND' -ExitCode 3 -SafeMessage 'No active task is owned by the current session and runtime.'
    }
    if ($matches.Count -ne 1) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-TASK-AMBIGUOUS' -ExitCode 3 -SafeMessage 'More than one active task is owned by the current session and runtime.'
    }
    return $matches[0]
}

function Get-AgentTasksContinuityCheckpoint {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][AllowEmptyCollection()][Collections.Generic.List[string]]$DegradedFields
    )
    if (-not $Authority.Revision.Contains('latest_checkpoint_id')) {
        foreach ($field in @('checkpoint', 'work_unit_id', 'next_action', 'blockers', 'open_risks')) { [void]$DegradedFields.Add($field) }
        return [ordered]@{ checkpoint_id = $null; checkpoint_sha256 = $null; work_unit_id = $null; next_action = $null; blockers = @(); open_risks = @() }
    }
    $checkpointId = [string]$Authority.Revision.latest_checkpoint_id
    if ([string]::IsNullOrWhiteSpace($checkpointId)) {
        return [ordered]@{ checkpoint_id = $null; checkpoint_sha256 = $null; work_unit_id = $null; next_action = $null; blockers = @(); open_risks = @() }
    }
    if ($checkpointId -cnotmatch '^CP[0-9]{6}$') {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity checkpoint identity is invalid.'
    }
    $path = Join-Path $Authority.Root (Join-Path 'checkpoints' ($checkpointId + '.json'))
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The referenced continuity checkpoint is unavailable.'
    }
    $record = Read-AgentTasksJsonFile -LiteralPath $path
    if (
        $record -isnot [Collections.IDictionary] -or [string]$record.record_type -cne 'checkpoint' -or
        [string]$record.checkpoint_id -cne $checkpointId -or -not $record.Contains('record_hash') -or
        [string]$record.record_hash -cne (Get-AgentTasksSha256 -Value $record) -or
        [long]$record.lineage_revision -lt 1 -or [long]$record.lineage_revision -ge [long]$Authority.Revision.revision -or
        [string]$record.worktree_binding -cne [string]$Authority.Revision.observation_worktree
    ) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The referenced continuity checkpoint is invalid or stale.'
    }
    $workUnitId = if ($null -eq $record.work_unit_id -or [string]::IsNullOrWhiteSpace([string]$record.work_unit_id)) { $null } else { [string]$record.work_unit_id }
    if ($null -ne $workUnitId) {
        if ($workUnitId -cnotmatch '^WU-[A-Z0-9][A-Z0-9._-]{0,79}$' -or @($Authority.Revision.work_unit_ids | Where-Object { [string]$_ -ceq $workUnitId }).Count -ne 1) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity checkpoint work-unit binding is stale.'
        }
        $workUnitPath = Join-Path $Authority.Root (Join-Path 'work-units' ($workUnitId + '.json'))
        if (-not (Test-Path -LiteralPath $workUnitPath -PathType Leaf)) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity checkpoint work unit is unavailable.'
        }
        $workUnit = Read-AgentTasksJsonFile -LiteralPath $workUnitPath
        if (
            [string]$workUnit.record_type -cne 'work_unit_contract' -or [string]$workUnit.work_unit_id -cne $workUnitId -or
            -not $workUnit.Contains('record_hash') -or [string]$workUnit.record_hash -cne (Get-AgentTasksSha256 -Value $workUnit)
        ) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity checkpoint work unit is corrupt.'
        }
    }
    return [ordered]@{
        checkpoint_id = $checkpointId
        checkpoint_sha256 = ConvertTo-AgentTasksContinuityHash -Value $record.record_hash
        work_unit_id = $workUnitId
        next_action = ConvertTo-AgentTasksProjectionText -Value $record.next_action -MaximumUtf8Bytes 1024
        blockers = @(ConvertTo-AgentTasksContinuityStringArray -Value $record.blockers -MaximumUtf8Bytes 1024)
        open_risks = @(ConvertTo-AgentTasksContinuityStringArray -Value $record.open_risks -MaximumUtf8Bytes 1024)
    }
}

function Get-AgentTasksContinuityCandidate {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][AllowEmptyCollection()][Collections.Generic.List[string]]$DegradedFields
    )
    $hasId = $Authority.Revision.Contains('selected_candidate_id')
    $hasHash = $Authority.Revision.Contains('selected_candidate_hash')
    if (-not $hasId -and -not $hasHash) {
        [void]$DegradedFields.Add('candidate')
        return [ordered]@{ candidate_id = $null; candidate_hash = $null; candidate_sha256 = $null }
    }
    if ($hasId -ne $hasHash) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The selected candidate binding is incomplete.'
    }
    $candidateId = [string]$Authority.Revision.selected_candidate_id
    $selectedHash = [string]$Authority.Revision.selected_candidate_hash
    if ([string]::IsNullOrWhiteSpace($candidateId) -and [string]::IsNullOrWhiteSpace($selectedHash)) {
        return [ordered]@{ candidate_id = $null; candidate_hash = $null; candidate_sha256 = $null }
    }
    if ([string]::IsNullOrWhiteSpace($candidateId) -or [string]::IsNullOrWhiteSpace($selectedHash)) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The selected candidate binding is incomplete.'
    }
    $comparison = Test-AgentTasksCandidateCurrentUnlocked -Authority $Authority -CandidateId $candidateId
    if (-not $comparison.Valid) {
        Throw-AgentTasksError -Code 'AT-CANDIDATE-DRIFT' -ExitCode 3 -SafeMessage 'The selected candidate drifted before continuity projection.'
    }
    $candidate = $comparison.Candidate
    if ([string]$selectedHash -cne [string]$candidate.record_hash) {
        Throw-AgentTasksError -Code 'AT-CANDIDATE-DRIFT' -ExitCode 3 -SafeMessage 'The selected candidate hash is stale.'
    }
    return [ordered]@{
        candidate_id = [string]$candidate.candidate_id
        candidate_hash = ConvertTo-AgentTasksContinuityHash -Value $selectedHash
        candidate_sha256 = ConvertTo-AgentTasksContinuityHash -Value $candidate.record_hash
    }
}

function Get-AgentTasksContinuityEvidenceBindings {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][Collections.IDictionary]$Candidate,
        [Parameter(Mandatory)][AllowEmptyCollection()][Collections.Generic.List[string]]$DegradedFields
    )
    if (-not $Authority.Revision.Contains('evidence_ids')) {
        [void]$DegradedFields.Add('evidence_bindings')
        return @()
    }
    $ids = @($Authority.Revision.evidence_ids)
    if ($ids.Count -gt 128) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-TOO-LARGE' -ExitCode 4 -SafeMessage 'The continuity projection exceeds a managed bound.'
    }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $bindings = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    foreach ($idValue in $ids) {
        $id = [string]$idValue
        if ($idValue -isnot [string] -or $id -cnotmatch '^E[0-9]{6}$' -or -not $seen.Add($id)) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The continuity evidence identity set is invalid.'
        }
        $path = Join-Path $Authority.Root (Join-Path 'evidence' ($id + '.json'))
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'A referenced continuity evidence record is unavailable.'
        }
        $record = Read-AgentTasksJsonFile -LiteralPath $path
        if (
            $record -isnot [Collections.IDictionary] -or [string]$record.record_type -cne 'evidence' -or
            [string]$record.evidence_id -cne $id -or -not $record.Contains('record_hash') -or
            [string]$record.record_hash -cne (Get-AgentTasksSha256 -Value $record)
        ) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'A referenced continuity evidence record is corrupt.'
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$record.candidate_id)) {
            if (
                $null -eq $Candidate.candidate_id -or [string]$record.candidate_id -cne [string]$Candidate.candidate_id -or
                [string]$record.candidate_hash -cne ([string]$Candidate.candidate_hash).ToUpperInvariant()
            ) {
                Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'A continuity evidence candidate binding is stale.'
            }
        }
        $bindings[$id] = [ordered]@{ evidence_id = $id; record_sha256 = ConvertTo-AgentTasksContinuityHash -Value $record.record_hash }
    }
    [string[]]$sortedIds = @($bindings.Keys)
    [Array]::Sort($sortedIds, [StringComparer]::Ordinal)
    return @($sortedIds | ForEach-Object { $bindings[$_] })
}

function Get-AgentTasksContinuityProjection {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$SessionRef,
        [Parameter(Mandatory)][string]$Runtime
    )
    $authority = Get-AgentTasksContinuityOwnedAuthority -Context $Context -SessionRef $SessionRef -Runtime $Runtime
    if (-not $authority.Revision.Contains('workflow_class') -and -not $authority.Revision.Contains('locked_decisions')) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-UNCLASSIFIED' -ExitCode 3 -SafeMessage 'The owned legacy task requires explicit continuity classification.'
    }
    if (-not $authority.Revision.Contains('workflow_class') -or -not $authority.Revision.Contains('locked_decisions')) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The task continuity classification is incomplete.'
    }
    Assert-AgentTasksProjectionRecordHash -Record $authority.Contract -ExpectedRecordType 'task_contract' `
        -ErrorCode 'AT-CONTINUITY-CORRUPT' -SafeMessage 'The task contract is corrupt.'
    if ([string]$authority.Contract.task_id -cne [string]$authority.Revision.task_id) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The task continuity identity is inconsistent.'
    }
    $currentWorktree = [IO.Path]::GetFullPath($Context.WorktreeRoot).TrimEnd('\', '/')
    $observationWorktree = [IO.Path]::GetFullPath([string]$authority.Revision.observation_worktree).TrimEnd('\', '/')
    if ($currentWorktree -cne $observationWorktree) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-WORKTREE' -ExitCode 3 -SafeMessage 'The current session is not observing the task-bound worktree.'
    }
    if ($Runtime -cne 'omp') {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-TASK-NOT-FOUND' -ExitCode 3 -SafeMessage 'No active OMP task is owned by the current session.'
    }
    try {
        $workflowClass = Assert-AgentTasksWorkflowClass -Value $authority.Revision.workflow_class
        $lockedDecisions = @(ConvertTo-AgentTasksLockedDecisions -Value $authority.Revision.locked_decisions)
    } catch {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The task continuity classification is invalid.'
    }
    $degradedFields = [Collections.Generic.List[string]]::new()
    $checkpoint = Get-AgentTasksContinuityCheckpoint -Authority $authority -DegradedFields $degradedFields
    $candidate = Get-AgentTasksContinuityCandidate -Authority $authority -DegradedFields $degradedFields
    $evidenceBindings = @(Get-AgentTasksContinuityEvidenceBindings -Authority $authority -Candidate $candidate -DegradedFields $degradedFields)
    if ($workflowClass -cne 'quick' -and $degradedFields.Count -gt 0) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-DEGRADED' -ExitCode 3 -SafeMessage 'This workflow requires complete secondary continuity authority.'
    }
    [string[]]$degraded = @($degradedFields)
    [Array]::Sort($degraded, [StringComparer]::Ordinal)
    $executionMode = [string]$authority.Contract.execution_mode
    if ($executionMode -cnotin @('read_only', 'mutating')) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-CORRUPT' -ExitCode 4 -SafeMessage 'The task execution mode is invalid.'
    }
    $kernel = [ordered]@{
        schema_version = 1
        record_type = 'context_continuity_kernel'
        task = [ordered]@{
            task_id = [string]$authority.Revision.task_id
            workflow_class = $workflowClass
            objective = ConvertTo-AgentTasksProjectionText -Value $authority.Contract.objective -MaximumUtf8Bytes 4096
            authority = @(ConvertTo-AgentTasksContinuityStringArray -Value $authority.Contract.authority -MaximumUtf8Bytes 512)
            execution_mode = $executionMode
            write_scope = @(ConvertTo-AgentTasksContinuityWriteScope -Value $authority.Contract.write_scope)
            acceptance_criteria = @(ConvertTo-AgentTasksContinuityAcceptanceCriteria -Value $authority.Contract.acceptance_criteria)
            obligations = @(ConvertTo-AgentTasksContinuityStringArray -Value $authority.Contract.obligations -MaximumUtf8Bytes 512)
            locked_decisions = @($lockedDecisions)
        }
        lifecycle = [ordered]@{
            status = [string]$authority.Revision.status
            owner_session_ref = ConvertTo-AgentTasksProjectionText -Value $SessionRef -MaximumUtf8Bytes 512
            owner_runtime = 'omp'
            revision = [long]$authority.Revision.revision
            revision_id = [string]$authority.Revision.revision_id
            revision_sha256 = ConvertTo-AgentTasksContinuityHash -Value $authority.RevisionSha256
            lease_generation = [long]$authority.Revision.lease_generation
        }
        checkpoint = $checkpoint
        candidate = $candidate
        evidence_bindings = @($evidenceBindings)
        degraded_fields = @($degraded)
    }
    $kernel.kernel_sha256 = (Get-AgentTasksSha256 -Value $kernel).ToLowerInvariant()
    $canonical = ConvertTo-AgentTasksCanonicalJson -Value $kernel
    $byteCount = [Text.UTF8Encoding]::new($false).GetByteCount($canonical)
    if ($byteCount -gt 16384) {
        Throw-AgentTasksError -Code 'AT-CONTINUITY-TOO-LARGE' -ExitCode 4 -SafeMessage 'The continuity kernel exceeds the 16 KiB boundary.'
    }
    return $kernel
}

function New-AgentTasksHandoffProjection {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][Collections.IDictionary]$HandoffRecord,
        [Parameter(Mandatory)][string]$HandoffSha256,
        [Parameter(Mandatory)][Collections.IDictionary]$RevisionRecord,
        [Parameter(Mandatory)][string]$RevisionSha256,
        [Parameter(Mandatory)][Collections.IDictionary]$CandidateBinding
    )

    if (
        [string]$CandidateBinding.candidate_id -cne [string]$HandoffRecord.candidate_id -or
        [string]$CandidateBinding.candidate_sha256 -cne [string]$HandoffRecord.candidate_hash
    ) {
        Throw-AgentTasksError -Code 'AT-HANDOFF-STALE' -ExitCode 3 -SafeMessage 'The handoff candidate binding is stale.'
    }

    $projection = [ordered]@{
        schema_version = 1
        record_type = 'handoff_projection'
        task_contract = [ordered]@{
            task_id = [string]$Authority.Contract.task_id
            objective = [string]$Authority.Contract.objective
            authority = @($Authority.Contract.authority)
            acceptance_criteria = @($Authority.Contract.acceptance_criteria)
            obligations = @($Authority.Contract.obligations)
            execution_mode = [string]$Authority.Contract.execution_mode
            write_scope = @($Authority.Contract.write_scope)
            owned_ignored_outputs = @($Authority.Contract.owned_ignored_outputs)
            task_contract_sha256 = Get-AgentTasksSha256 -Value $Authority.Contract
        }
        candidate = [ordered]@{
            candidate_id = $CandidateBinding.candidate_id
            candidate_sha256 = $CandidateBinding.candidate_sha256
            diff_ref = $CandidateBinding.diff_ref
            artifact_refs = @($CandidateBinding.artifact_refs)
            evidence_bindings = @($HandoffRecord.evidence_bindings)
            workspace_snapshot_sha256 = [string]$HandoffRecord.workspace_snapshot_sha256
        }
        lifecycle = [ordered]@{
            status = [string]$RevisionRecord.status
            prior_status = [string]$HandoffRecord.predecessor_status
            next_action = [string]$HandoffRecord.next_action
            blockers = @($HandoffRecord.blockers)
            open_risks = @($HandoffRecord.open_risks)
        }
        successor = [ordered]@{
            session_ref = [string]$HandoffRecord.successor_session_ref
            runtime = [string]$HandoffRecord.successor_runtime
        }
        transfer = [ordered]@{
            task_id = [string]$HandoffRecord.task_id
            handoff_id = [string]$HandoffRecord.handoff_id
            handoff_sha256 = $HandoffSha256
            predecessor_revision = [long]$HandoffRecord.predecessor_revision
            predecessor_revision_sha256 = [string]$HandoffRecord.predecessor_revision_sha256
            revision = [long]$RevisionRecord.revision
            revision_sha256 = $RevisionSha256
            lease_generation = [long]$RevisionRecord.lease_generation
        }
    }
    $projection.projection_sha256 = Get-AgentTasksSha256 -Value $projection
    return $projection
}
