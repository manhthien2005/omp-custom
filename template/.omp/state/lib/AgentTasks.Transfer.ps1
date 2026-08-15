#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command Get-AgentTasksWorkspaceSnapshot -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'AgentTasks.Git.ps1')
}
if (-not (Get-Command Get-AgentTasksTaskAuthority -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'AgentTasks.Lifecycle.ps1')
}
if (-not (Get-Command Test-AgentTasksCandidateCurrentUnlocked -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'AgentTasks.Candidate.ps1')
}
if (-not (Get-Command Get-AgentTasksArtifactMetadata -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'AgentTasks.Evidence.ps1')
}

function Assert-AgentTasksTransferCas {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][Collections.IDictionary]$Request
    )
    if ([long]$Request.expected_revision -ne [long]$Authority.Revision.revision) {
        Throw-AgentTasksError -Code 'AT-CAS-REVISION' -ExitCode 3 -SafeMessage 'The expected task revision is stale.'
    }
    if ([string]$Request.expected_revision_sha256 -cne [string]$Authority.RevisionSha256) {
        Throw-AgentTasksError -Code 'AT-CAS-HASH' -ExitCode 3 -SafeMessage 'The expected task revision hash is stale.'
    }
    if ([long]$Request.expected_lease_generation -ne [long]$Authority.Revision.lease_generation) {
        Throw-AgentTasksError -Code 'AT-CAS-LEASE' -ExitCode 3 -SafeMessage 'The expected writer lease generation is stale.'
    }
}

function Assert-AgentTasksUserAuthorization {
    param(
        [AllowNull()][object]$Authorization,
        [Parameter(Mandatory)][string]$Code
    )
    if ($Authorization -isnot [Collections.IDictionary]) {
        Throw-AgentTasksError -Code $Code -ExitCode 3 -SafeMessage 'Explicit user authorization is required.'
    }
    $allowed = [Collections.Generic.HashSet[string]]::new(
        [string[]]@('confirmed', 'authority', 'reason', 'observed_at'),
        [StringComparer]::Ordinal
    )
    foreach ($key in $Authorization.Keys) {
        if (-not $allowed.Contains([string]$key)) {
            Throw-AgentTasksError -Code $Code -ExitCode 3 -SafeMessage 'Explicit user authorization is malformed.'
        }
    }
    foreach ($required in @('confirmed', 'authority', 'reason', 'observed_at')) {
        if (-not $Authorization.Contains($required)) {
            Throw-AgentTasksError -Code $Code -ExitCode 3 -SafeMessage 'Explicit user authorization is incomplete.'
        }
    }
    $parsed = [DateTimeOffset]::MinValue
    $validTimestamp = [string]$Authorization.observed_at -match 'Z$' -and
        [DateTimeOffset]::TryParse(
            [string]$Authorization.observed_at,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::RoundtripKind,
            [ref]$parsed
        )
    if (
        $Authorization.confirmed -ne $true -or
        [string]$Authorization.authority -cne 'user' -or
        [string]::IsNullOrWhiteSpace([string]$Authorization.reason) -or
        -not $validTimestamp -or
        (Test-AgentTasksSensitiveValue -Value $Authorization)
    ) {
        Throw-AgentTasksError -Code $Code -ExitCode 3 -SafeMessage 'Explicit user authorization is invalid.'
    }
}

function Get-AgentTasksTransferWorkspaceSnapshot {
    param([Parameter(Mandatory)][object]$Authority)
    $worktree = [string]$Authority.Revision.observation_worktree
    if ([string]::IsNullOrWhiteSpace($worktree) -or -not (Test-Path -LiteralPath $worktree -PathType Container)) {
        Throw-AgentTasksError -Code 'AT-HANDOFF-STALE' -ExitCode 3 -SafeMessage 'The handoff worktree is unavailable.'
    }
    return Get-AgentTasksWorkspaceSnapshot -WorkingDirectory $worktree -OwnedIgnoredOutputs @($Authority.Contract.owned_ignored_outputs)
}

function Get-AgentTasksTransferWorkspaceHash {
    param([Parameter(Mandatory)][object]$Snapshot)
    $identity = [ordered]@{}
    foreach ($key in $Snapshot.Keys) {
        if ([string]$key -notin @('captured_at', 'record_hash')) { $identity[[string]$key] = $Snapshot[$key] }
    }
    return Get-AgentTasksSha256 -Value $identity
}

function Get-AgentTasksTransferEvidenceBindings {
    param([Parameter(Mandatory)][object]$Authority)
    $bindings = [Collections.Generic.List[object]]::new()
    $ids = if ($Authority.Revision.Contains('evidence_ids')) {
        @($Authority.Revision.evidence_ids | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
    } else {
        @()
    }
    foreach ($evidenceId in $ids) {
        $path = Join-Path $Authority.Root (Join-Path 'evidence' ([string]$evidenceId + '.json'))
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Throw-AgentTasksError -Code 'AT-HANDOFF-STALE' -ExitCode 3 -SafeMessage 'Referenced handoff evidence is missing.'
        }
        $record = Read-AgentTasksJsonFile -LiteralPath $path
        if ([string]$record.record_hash -cne (Get-AgentTasksSha256 -Value $record)) {
            Throw-AgentTasksError -Code 'AT-HANDOFF-STALE' -ExitCode 3 -SafeMessage 'Referenced handoff evidence is invalid.'
        }
        if ($record.artifact_hash) {
            [void](Get-AgentTasksArtifactMetadata -Authority $Authority -ArtifactHash ([string]$record.artifact_hash) -VerifyBytes)
        }
        [void]$bindings.Add([ordered]@{
            evidence_id = [string]$evidenceId
            record_hash = [string]$record.record_hash
        })
    }
    return $bindings.ToArray()
}

function Assert-AgentTasksTransferEvidenceBindings {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Bindings
    )
    $current = @(Get-AgentTasksTransferEvidenceBindings -Authority $Authority)
    if ((ConvertTo-AgentTasksCanonicalJson -Value $current) -cne (ConvertTo-AgentTasksCanonicalJson -Value @($Bindings))) {
        Throw-AgentTasksError -Code 'AT-HANDOFF-STALE' -ExitCode 3 -SafeMessage 'The handoff evidence set changed before acceptance.'
    }
}

function Get-AgentTasksMandatoryCheckpoint {
    param([Parameter(Mandatory)][object]$Authority)
    $checkpointId = if ($Authority.Revision.Contains('latest_checkpoint_id')) { [string]$Authority.Revision.latest_checkpoint_id } else { '' }
    if ([string]::IsNullOrWhiteSpace($checkpointId)) {
        Throw-AgentTasksError -Code 'AT-HANDOFF-CHECKPOINT' -ExitCode 3 -SafeMessage 'A mandatory predecessor checkpoint is required.'
    }
    $path = Join-Path $Authority.Root (Join-Path 'checkpoints' ($checkpointId + '.json'))
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Throw-AgentTasksError -Code 'AT-HANDOFF-CHECKPOINT' -ExitCode 3 -SafeMessage 'The predecessor checkpoint is missing.'
    }
    $record = Read-AgentTasksJsonFile -LiteralPath $path
    if ([string]$record.record_hash -cne (Get-AgentTasksSha256 -Value $record) -or [string]$record.kind -cne 'mandatory') {
        Throw-AgentTasksError -Code 'AT-HANDOFF-CHECKPOINT' -ExitCode 3 -SafeMessage 'The predecessor checkpoint is not a valid mandatory checkpoint.'
    }
    return $record
}

function Get-AgentTasksNextHandoffId {
    param([Parameter(Mandatory)][object]$Authority)
    $existing = @(Get-ChildItem -LiteralPath (Join-Path $Authority.Root 'handoffs') -File -Filter 'H*.json')
    return 'H{0:D6}' -f ($existing.Count + 1)
}

function Publish-AgentTasksSessionIdentity {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$SessionRef,
        [Parameter(Mandatory)][string]$Runtime
    )
    if ([string]::IsNullOrWhiteSpace($SessionRef) -or [string]::IsNullOrWhiteSpace($Runtime)) {
        Throw-AgentTasksError -Code 'AT-HANDOFF-SUCCESSOR' -ExitCode 3 -SafeMessage 'A named successor session and runtime are required.'
    }
    $path = Join-Path $Authority.Root ('sessions\{0}.json' -f (Get-AgentTasksSha256 -Value $SessionRef).Substring(0, 16))
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        [void](Publish-AgentTasksRecord -LiteralPath $path -Value ([ordered]@{
            schema_version = 1
            record_type = 'session_identity'
            session_ref = $SessionRef
            runtime = $Runtime
            created_at = Get-AgentTasksUtcTimestamp
        }))
        return
    }
    $identity = Read-AgentTasksJsonFile -LiteralPath $path
    if (
        [string]$identity.record_hash -cne (Get-AgentTasksSha256 -Value $identity) -or
        [string]$identity.session_ref -cne $SessionRef -or
        [string]$identity.runtime -cne $Runtime
    ) {
        Throw-AgentTasksError -Code 'AT-HANDOFF-SUCCESSOR' -ExitCode 3 -SafeMessage 'The successor session identity conflicts with existing authority.'
    }
}

function Start-AgentTasksHandoff {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )
    $taskId = [string]$Request.task_id
    return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain task -Id $taskId -Action {
        $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $taskId
        Assert-AgentTasksTaskCas -Authority $authority -Request $Request -SessionRef $SessionRef
        if ([string]$authority.Revision.status -notin @($script:TaskTransitions.Keys) -or
            [string]$authority.Revision.status -in @('accepted', 'cancelled', 'terminally_blocked', 'transferring')) {
            Throw-AgentTasksError -Code 'AT-HANDOFF-STATE' -ExitCode 3 -SafeMessage 'The task cannot begin a handoff in its current state.'
        }
        $successorRef = [string]$Request.successor_session_ref
        $successorRuntime = [string]$Request.successor_runtime
        if (
            [string]::IsNullOrWhiteSpace($successorRef) -or
            [string]::IsNullOrWhiteSpace($successorRuntime) -or
            $successorRef -ceq $SessionRef
        ) {
            Throw-AgentTasksError -Code 'AT-HANDOFF-SUCCESSOR' -ExitCode 3 -SafeMessage 'A distinct named successor session and runtime are required.'
        }
        $checkpoint = Get-AgentTasksMandatoryCheckpoint -Authority $authority
        $snapshot = Get-AgentTasksTransferWorkspaceSnapshot -Authority $authority
        $candidateId = if ($authority.Revision.Contains('selected_candidate_id')) { [string]$authority.Revision.selected_candidate_id } else { '' }
        $candidateHash = $null
        $candidateRecord = $null
        if (-not [string]::IsNullOrWhiteSpace($candidateId)) {
            $comparison = Test-AgentTasksCandidateCurrentUnlocked -Authority $authority -CandidateId $candidateId
            if (-not $comparison.Valid) {
                Throw-AgentTasksError -Code 'AT-CANDIDATE-DRIFT' -ExitCode 3 -SafeMessage 'The selected candidate drifted before handoff.'
            }
            $candidateRecord = $comparison.Candidate
            $candidateHash = [string]$comparison.Candidate.record_hash
        }
        $evidenceBindings = @(Get-AgentTasksTransferEvidenceBindings -Authority $authority)
        $candidateProjectionBinding = ConvertTo-AgentTasksProjectionCandidateBinding -Authority $authority -Candidate $candidateRecord
        $handoffId = Get-AgentTasksNextHandoffId -Authority $authority
        $handoffRecord = [ordered]@{
            schema_version = 1
            record_type = 'handoff'
            handoff_id = $handoffId
            handoff_kind = 'normal'
            task_id = $taskId
            authority_root = [string]$authority.Root
            task_contract_hash = Get-AgentTasksSha256 -Value $authority.Contract
            predecessor_revision = [long]$authority.Revision.revision
            predecessor_revision_sha256 = [string]$authority.RevisionSha256
            predecessor_session_ref = $SessionRef
            predecessor_runtime = $(if ($authority.Revision.Contains('owner_runtime')) { [string]$authority.Revision.owner_runtime } else { 'unknown' })
            predecessor_status = [string]$authority.Revision.status
            lease_generation = [long]$authority.Revision.lease_generation
            authoritative_worktree = [string]$authority.Revision.authoritative_worktree
            observation_worktree = [string]$authority.Revision.observation_worktree
            workspace_snapshot_sha256 = Get-AgentTasksTransferWorkspaceHash -Snapshot $snapshot
            candidate_id = $(if ($candidateId) { $candidateId } else { $null })
            candidate_hash = $candidateHash
            evidence_bindings = $evidenceBindings
            checkpoint_id = [string]$checkpoint.checkpoint_id
            checkpoint_hash = [string]$checkpoint.record_hash
            successor_session_ref = $successorRef
            successor_runtime = $successorRuntime
            last_work_unit_id = $(if (@($authority.Revision.work_unit_outcome_ids).Count -gt 0) { [string]@($authority.Revision.work_unit_outcome_ids)[-1] } else { $null })
            next_action = [string]$Request.next_action
            blockers = @($Request.blockers)
            open_risks = @($Request.open_risks)
            invalidated_evidence_ids = @()
            user_authorization = $null
            created_at = Get-AgentTasksUtcTimestamp
        }
        $published = Publish-AgentTasksRecord -LiteralPath (Join-Path $authority.Root (Join-Path 'handoffs' ($handoffId + '.json'))) -Value $handoffRecord
        $revision = Publish-AgentTasksTaskRevisionUnlocked -Authority $authority -Mutator {
            param($next)
            $next.transfer_prior_status = [string]$authority.Revision.status
            $next.status = 'transferring'
            $next.lease_status = 'transferring'
            $next.active_handoff_id = $handoffId
            $next.handoff_ids = @(@($next.handoff_ids) + @($handoffId) | Sort-Object -Unique)
            $next.supporting_refs = @(@($next.supporting_refs) + @($handoffId) | Sort-Object -Unique)
        }
        $handoffProjection = New-AgentTasksHandoffProjection -Authority $authority `
            -HandoffRecord $published.Record -HandoffSha256 ([string]$published.Record.record_hash) `
            -RevisionRecord $revision.Record -RevisionSha256 ([string]$revision.Sha256) `
            -CandidateBinding $candidateProjectionBinding
        return [ordered]@{
            task_id = $taskId
            handoff_id = $handoffId
            handoff_hash = [string]$published.Record.record_hash
            status = 'transferring'
            owner_session_ref = $SessionRef
            revision = [long]$revision.Record.revision
            revision_sha256 = [string]$revision.Sha256
            lease_generation = [long]$revision.Record.lease_generation
            handoff_projection = $handoffProjection
        }
    }
}

function Get-AgentTasksHandoffRecord {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$HandoffId
    )
    $path = Join-Path $Authority.Root (Join-Path 'handoffs' ($HandoffId + '.json'))
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Throw-AgentTasksError -Code 'AT-HANDOFF-STALE' -ExitCode 3 -SafeMessage 'The handoff record does not exist.'
    }
    $record = Read-AgentTasksJsonFile -LiteralPath $path
    if ([string]$record.record_hash -cne (Get-AgentTasksSha256 -Value $record)) {
        Throw-AgentTasksError -Code 'AT-HANDOFF-STALE' -ExitCode 3 -SafeMessage 'The handoff record is invalid.'
    }
    return $record
}

function Complete-AgentTasksHandoff {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )
    $taskId = [string]$Request.task_id
    return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain task -Id $taskId -Action {
        $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $taskId
        Assert-AgentTasksTransferCas -Authority $authority -Request $Request
        if (
            [string]$authority.Revision.status -cne 'transferring' -or
            [string]$authority.Revision.active_handoff_id -cne [string]$Request.handoff_id
        ) {
            Throw-AgentTasksError -Code 'AT-HANDOFF-STALE' -ExitCode 3 -SafeMessage 'The requested handoff is not the active transfer.'
        }
        $handoff = Get-AgentTasksHandoffRecord -Authority $authority -HandoffId ([string]$Request.handoff_id)
        if ([string]$handoff.successor_session_ref -cne $SessionRef) {
            Throw-AgentTasksError -Code 'AT-HANDOFF-SUCCESSOR' -ExitCode 3 -SafeMessage 'Only the named successor may accept this handoff.'
        }
        if (
            [long]$Request.predecessor_revision -ne [long]$handoff.predecessor_revision -or
            [string]$Request.predecessor_revision_sha256 -cne [string]$handoff.predecessor_revision_sha256 -or
            [string]$handoff.task_contract_hash -cne (Get-AgentTasksSha256 -Value $authority.Contract) -or
            [string]$handoff.authoritative_worktree -cne [string]$authority.Revision.authoritative_worktree -or
            [long]$handoff.lease_generation -ne [long]$authority.Revision.lease_generation
        ) {
            Throw-AgentTasksError -Code 'AT-HANDOFF-STALE' -ExitCode 3 -SafeMessage 'The handoff authority identity is stale.'
        }
        $snapshot = Get-AgentTasksTransferWorkspaceSnapshot -Authority $authority
        if ([string]$handoff.candidate_id) {
            $comparison = Test-AgentTasksCandidateCurrentUnlocked -Authority $authority -CandidateId ([string]$handoff.candidate_id)
            if (-not $comparison.Valid -or [string]$comparison.Candidate.record_hash -cne [string]$handoff.candidate_hash) {
                Throw-AgentTasksError -Code 'AT-CANDIDATE-DRIFT' -ExitCode 3 -SafeMessage 'The handoff candidate drifted before acceptance.'
            }
        } elseif ((Get-AgentTasksTransferWorkspaceHash -Snapshot $snapshot) -cne [string]$handoff.workspace_snapshot_sha256) {
            Throw-AgentTasksError -Code 'AT-HANDOFF-STALE' -ExitCode 3 -SafeMessage 'The pre-candidate workspace changed before handoff acceptance.'
        }
        Assert-AgentTasksTransferEvidenceBindings -Authority $authority -Bindings @($handoff.evidence_bindings)
        Publish-AgentTasksSessionIdentity -Authority $authority -SessionRef $SessionRef -Runtime ([string]$handoff.successor_runtime)
        $revision = Publish-AgentTasksTaskRevisionUnlocked -Authority $authority -Mutator {
            param($next)
            $next.status = [string]$handoff.predecessor_status
            $next.owner_session_ref = $SessionRef
            $next.owner_runtime = [string]$handoff.successor_runtime
            $next.lease_generation = [long]$next.lease_generation + 1
            $next.lease_status = 'active'
            $next.predecessor_session_ref = [string]$handoff.predecessor_session_ref
            $next.completed_handoff_id = [string]$handoff.handoff_id
            $next.active_handoff_id = $null
            $next.transfer_prior_status = $null
        }
        return [ordered]@{
            task_id = $taskId
            handoff_id = [string]$handoff.handoff_id
            status = [string]$revision.Record.status
            owner_session_ref = $SessionRef
            lease_generation = [long]$revision.Record.lease_generation
            revision = [long]$revision.Record.revision
            revision_sha256 = [string]$revision.Sha256
        }
    }
}

function Assert-AgentTasksTakeoverReconciliation {
    param(
        [AllowNull()][object]$Reconciliation,
        [Parameter(Mandatory)][object]$Snapshot
    )
    if ($Reconciliation -isnot [Collections.IDictionary]) {
        Throw-AgentTasksError -Code 'AT-TAKEOVER-RECONCILIATION' -ExitCode 3 -SafeMessage 'Takeover requires structured workspace reconciliation.'
    }
    try {
        Assert-AgentTasksClosedObject -Value $Reconciliation -Allowed @('workspace_snapshot_sha256', 'disposition') -Required @('workspace_snapshot_sha256', 'disposition')
    } catch {
        Throw-AgentTasksError -Code 'AT-TAKEOVER-RECONCILIATION' -ExitCode 3 -SafeMessage 'Takeover workspace reconciliation is malformed.'
    }
    if (
        [string]$Reconciliation.disposition -cne 'validated_current_workspace' -or
        [string]$Reconciliation.workspace_snapshot_sha256 -cne (Get-AgentTasksTransferWorkspaceHash -Snapshot $Snapshot)
    ) {
        Throw-AgentTasksError -Code 'AT-TAKEOVER-RECONCILIATION' -ExitCode 3 -SafeMessage 'Takeover workspace reconciliation does not match current bytes.'
    }
}

function Invoke-AgentTasksTakeover {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )
    $taskId = [string]$Request.task_id
    return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain task -Id $taskId -Action {
        $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $taskId
        Assert-AgentTasksTransferCas -Authority $authority -Request $Request
        Assert-AgentTasksUserAuthorization -Authorization $Request.user_authorization -Code 'AT-TAKEOVER-AUTHORITY'
        if ([string]$Request.successor_session_ref -cne $SessionRef -or [string]::IsNullOrWhiteSpace([string]$Request.successor_runtime)) {
            Throw-AgentTasksError -Code 'AT-TAKEOVER-SUCCESSOR' -ExitCode 3 -SafeMessage 'Takeover must name the calling successor session and runtime.'
        }
        if ([string]$authority.Revision.status -in @('accepted', 'cancelled', 'terminally_blocked')) {
            Throw-AgentTasksError -Code 'AT-TAKEOVER-STATE' -ExitCode 3 -SafeMessage 'A terminal task cannot be taken over.'
        }
        $snapshot = Get-AgentTasksTransferWorkspaceSnapshot -Authority $authority
        Assert-AgentTasksTakeoverReconciliation -Reconciliation $Request.reconciliation -Snapshot $snapshot
        $candidateId = if ($authority.Revision.Contains('selected_candidate_id')) { [string]$authority.Revision.selected_candidate_id } else { '' }
        $candidateHash = $null
        if ($candidateId) {
            $comparison = Test-AgentTasksCandidateCurrentUnlocked -Authority $authority -CandidateId $candidateId
            if (-not $comparison.Valid) {
                Throw-AgentTasksError -Code 'AT-CANDIDATE-DRIFT' -ExitCode 3 -SafeMessage 'Takeover cannot adopt a drifted selected candidate.'
            }
            $candidateHash = [string]$comparison.Candidate.record_hash
        }
        $invalidatedEvidence = if ($authority.Revision.Contains('evidence_ids')) {
            @($authority.Revision.evidence_ids | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) } | Sort-Object -Unique)
        } else {
            @()
        }
        $handoffId = Get-AgentTasksNextHandoffId -Authority $authority
        $resumeStatus = if ([string]$authority.Revision.status -ceq 'transferring' -and $authority.Revision.Contains('transfer_prior_status')) {
            [string]$authority.Revision.transfer_prior_status
        } else {
            [string]$authority.Revision.status
        }
        $handoffRecord = [ordered]@{
            schema_version = 1
            record_type = 'handoff'
            handoff_id = $handoffId
            handoff_kind = 'recovery'
            task_id = $taskId
            authority_root = [string]$authority.Root
            task_contract_hash = Get-AgentTasksSha256 -Value $authority.Contract
            predecessor_revision = [long]$authority.Revision.revision
            predecessor_revision_sha256 = [string]$authority.RevisionSha256
            predecessor_session_ref = [string]$authority.Revision.owner_session_ref
            predecessor_runtime = $(if ($authority.Revision.Contains('owner_runtime')) { [string]$authority.Revision.owner_runtime } else { 'unknown' })
            predecessor_status = [string]$authority.Revision.status
            lease_generation = [long]$authority.Revision.lease_generation
            authoritative_worktree = [string]$authority.Revision.authoritative_worktree
            observation_worktree = [string]$authority.Revision.observation_worktree
            workspace_snapshot_sha256 = Get-AgentTasksTransferWorkspaceHash -Snapshot $snapshot
            candidate_id = $(if ($candidateId) { $candidateId } else { $null })
            candidate_hash = $candidateHash
            evidence_bindings = @()
            checkpoint_id = $(if ($authority.Revision.Contains('latest_checkpoint_id')) { $authority.Revision.latest_checkpoint_id } else { $null })
            checkpoint_hash = $null
            successor_session_ref = $SessionRef
            successor_runtime = [string]$Request.successor_runtime
            last_work_unit_id = $(if (@($authority.Revision.work_unit_outcome_ids).Count -gt 0) { [string]@($authority.Revision.work_unit_outcome_ids)[-1] } else { $null })
            next_action = 'Resume only after the recorded takeover reconciliation.'
            blockers = @()
            open_risks = @('Prior-session evidence was invalidated conservatively.')
            invalidated_evidence_ids = $invalidatedEvidence
            user_authorization = $Request.user_authorization
            prior_handoff_id = $(if ($authority.Revision.Contains('active_handoff_id')) { $authority.Revision.active_handoff_id } else { $null })
            created_at = Get-AgentTasksUtcTimestamp
        }
        $published = Publish-AgentTasksRecord -LiteralPath (Join-Path $authority.Root (Join-Path 'handoffs' ($handoffId + '.json'))) -Value $handoffRecord
        Publish-AgentTasksSessionIdentity -Authority $authority -SessionRef $SessionRef -Runtime ([string]$Request.successor_runtime)
        $revision = Publish-AgentTasksTaskRevisionUnlocked -Authority $authority -Mutator {
            param($next)
            $next.status = $resumeStatus
            $next.owner_session_ref = $SessionRef
            $next.owner_runtime = [string]$Request.successor_runtime
            $next.lease_generation = [long]$next.lease_generation + 1
            $next.lease_status = 'active'
            $next.predecessor_session_ref = [string]$authority.Revision.owner_session_ref
            $next.completed_handoff_id = $handoffId
            $next.active_handoff_id = $null
            $next.transfer_prior_status = $null
            $next.handoff_ids = @(@($next.handoff_ids) + @($handoffId) | Sort-Object -Unique)
            $next.supporting_refs = @(@($next.supporting_refs) + @($handoffId) | Sort-Object -Unique)
            $next.invalidated_evidence_ids = @(@($next.invalidated_evidence_ids) + @($invalidatedEvidence) | Sort-Object -Unique)
        }
        return [ordered]@{
            task_id = $taskId
            handoff_id = $handoffId
            handoff_hash = [string]$published.Record.record_hash
            status = [string]$revision.Record.status
            owner_session_ref = $SessionRef
            invalidated_evidence_ids = $invalidatedEvidence
            lease_generation = [long]$revision.Record.lease_generation
            revision = [long]$revision.Record.revision
            revision_sha256 = [string]$revision.Sha256
        }
    }
}

function Repair-AgentTasksLock {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )
    Assert-AgentTasksUserAuthorization -Authorization $Request.user_authorization -Code 'AT-LOCK-RECOVERY-AUTHORITY'
    $domain = [string]$Request.lock_domain
    if ($domain -notin @('repository', 'phase', 'task')) {
        Throw-AgentTasksError -Code 'AT-LOCK-DOMAIN' -ExitCode 2 -SafeMessage 'The lock domain is unsupported.'
    }
    $canonicalId = ConvertTo-AgentTasksLockId -Id ([string]$Request.lock_id)
    $locksRoot = [IO.Path]::GetFullPath((Join-Path $Context.StateRoot 'locks')).TrimEnd('\', '/')
    $lockPath = [IO.Path]::GetFullPath((Join-Path $locksRoot ('{0}-{1}.lock' -f $domain, $canonicalId)))
    Assert-AgentTasksPathInside -Root $locksRoot -Candidate $lockPath
    if (-not (Test-Path -LiteralPath $lockPath -PathType Container)) {
        Throw-AgentTasksError -Code 'AT-LOCK-NOT-FOUND' -ExitCode 3 -SafeMessage 'The exact lock does not exist.'
    }
    if ((Get-Item -LiteralPath $lockPath -Force).Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)) {
        Throw-AgentTasksError -Code 'AT-LOCK-OWNER' -ExitCode 4 -SafeMessage 'The lock owner record cannot be trusted.'
    }
    $entries = @(Get-ChildItem -LiteralPath $lockPath -Force)
    if ($entries.Count -ne 1 -or $entries[0].Name -cne 'owner.json' -or $entries[0].PSIsContainer) {
        Throw-AgentTasksError -Code 'AT-LOCK-ACTIVE' -ExitCode 3 -SafeMessage 'The lock contains an active or unknown operation record.'
    }
    $ownerPath = Join-Path $lockPath 'owner.json'
    try {
        $owner = Read-AgentTasksJsonFile -LiteralPath $ownerPath
        Assert-AgentTasksClosedObject -Value $owner -Allowed @(
            'schema_version', 'record_type', 'created_at', 'host', 'process_id', 'process_start_time', 'record_hash'
        ) -Required @('schema_version', 'record_type', 'created_at', 'host', 'process_id', 'process_start_time', 'record_hash')
    } catch {
        Throw-AgentTasksError -Code 'AT-LOCK-OWNER' -ExitCode 4 -SafeMessage 'The lock owner record cannot be read safely.'
    }
    if (
        [long]$owner.schema_version -ne 1 -or
        [string]$owner.record_type -cne 'lock_owner' -or
        [string]$owner.record_hash -cne (Get-AgentTasksSha256 -Value $owner) -or
        [long]$owner.process_id -le 0 -or
        [string]::IsNullOrWhiteSpace([string]$owner.process_start_time)
    ) {
        Throw-AgentTasksError -Code 'AT-LOCK-OWNER' -ExitCode 4 -SafeMessage 'The lock owner record is invalid.'
    }
    if (-not ([string]$owner.host).Equals([Environment]::MachineName, [StringComparison]::OrdinalIgnoreCase) -or [string]$owner.process_start_time -ceq 'unknown') {
        Throw-AgentTasksError -Code 'AT-LOCK-LIVENESS' -ExitCode 3 -SafeMessage 'The lock owner process liveness cannot be established safely.'
    }
    $process = Get-Process -Id ([int]$owner.process_id) -ErrorAction SilentlyContinue
    if ($null -ne $process) {
        try {
            $observedStart = $process.StartTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [Globalization.CultureInfo]::InvariantCulture)
        } catch {
            Throw-AgentTasksError -Code 'AT-LOCK-LIVENESS' -ExitCode 3 -SafeMessage 'The lock owner process liveness cannot be established safely.'
        }
        if ($observedStart -ceq [string]$owner.process_start_time) {
            Throw-AgentTasksError -Code 'AT-LOCK-ACTIVE' -ExitCode 3 -SafeMessage 'The exact lock owner process instance is still alive.'
        }
    }
    $auditRoot = Join-Path $Context.StateRoot 'lock-recoveries'
    [void](New-Item -ItemType Directory -Path $auditRoot -Force)
    $recoveryId = 'LR-' + [guid]::NewGuid().ToString('N')
    [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $auditRoot ($recoveryId + '.json')) -Value ([ordered]@{
        schema_version = 1
        record_type = 'lock_recovery'
        recovery_id = $recoveryId
        lock_domain = $domain
        lock_id = [string]$Request.lock_id
        owner_record_hash = [string]$owner.record_hash
        recovered_by_session_ref = $SessionRef
        user_authorization = $Request.user_authorization
        created_at = Get-AgentTasksUtcTimestamp
    }))
    Assert-AgentTasksPathInside -Root $locksRoot -Candidate $lockPath
    Remove-Item -LiteralPath $lockPath -Recurse -Force
    return [ordered]@{
        recovery_id = $recoveryId
        lock_domain = $domain
        lock_id = [string]$Request.lock_id
        recovered = $true
        owner_record_hash = [string]$owner.record_hash
    }
}
