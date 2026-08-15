#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command Get-AgentTasksTaskAuthority -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'AgentTasks.Lifecycle.ps1')
}

function Copy-AgentTasksDictionaryWithoutHash {
    param([Parameter(Mandatory)][Collections.IDictionary]$Value)
    $copy = [ordered]@{}
    foreach ($key in $Value.Keys) {
        if ([string]$key -cne 'record_hash') { $copy[[string]$key] = $Value[$key] }
    }
    return ,$copy
}

function Get-AgentTasksIndexMap {
    param([Parameter(Mandatory)][object]$Snapshot)
    $map = @{}
    foreach ($entry in @($Snapshot.index_entries)) {
        if ([long]$entry.stage -eq 0) { $map[[string]$entry.path] = $entry }
    }
    return $map
}

function Get-AgentTasksSnapshotEntryMap {
    param([Parameter(Mandatory)][object]$Snapshot)
    $map = @{}
    foreach ($entry in @($Snapshot.entries)) { $map[[string]$entry.path] = $entry }
    return $map
}

function Get-AgentTasksPathIdentity {
    param(
        [Parameter(Mandatory)][string]$WorktreeRoot,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][hashtable]$IndexMap
    )
    $indexEntry = if ($IndexMap.ContainsKey($Path)) { $IndexMap[$Path] } else { $null }
    $mode = if ($null -ne $indexEntry) { [string]$indexEntry.mode } else { '000000' }
    $objectId = if ($null -ne $indexEntry) { [string]$indexEntry.object_id } else { $null }
    return Get-AgentTasksFileIdentity -WorktreeRoot $WorktreeRoot -RelativePath $Path -IndexMode $mode -IndexObjectId $objectId
}

function Get-AgentTasksIdentityProjection {
    param([Parameter(Mandatory)][Collections.IDictionary]$Entry)
    $projection = [ordered]@{
        path = [string]$Entry.path
        presence = [string]$Entry.presence
        file_type = [string]$Entry.file_type
        mode = [string]$Entry.mode
        sha256 = $Entry.sha256
    }
    if ($Entry.Contains('gitlink_commit')) { $projection.gitlink_commit = $Entry.gitlink_commit }
    return ,$projection
}

function Test-AgentTasksFileIdentityEqual {
    param(
        [Parameter(Mandatory)][Collections.IDictionary]$Left,
        [Parameter(Mandatory)][Collections.IDictionary]$Right
    )
    return (ConvertTo-AgentTasksCanonicalJson -Value (Get-AgentTasksIdentityProjection -Entry $Left)) -ceq
        (ConvertTo-AgentTasksCanonicalJson -Value (Get-AgentTasksIdentityProjection -Entry $Right))
}

function Assert-AgentTasksBaselineIdentity {
    param(
        [Parameter(Mandatory)][object]$Baseline,
        [Parameter(Mandatory)][object]$Current
    )
    if ([bool]$Baseline.git.is_git -ne [bool]$Current.git.is_git) {
        Throw-AgentTasksError -Code 'AT-BASELINE-WORKTREE' -ExitCode 3 -SafeMessage 'The workspace repository kind changed after task bootstrap.'
    }
    if ($Baseline.git.is_git) {
        if ([string]$Baseline.git.head -cne [string]$Current.git.head) {
            Throw-AgentTasksError -Code 'AT-BASELINE-HEAD' -ExitCode 3 -SafeMessage 'Repository HEAD changed after task bootstrap.'
        }
        if (
            [string]$Baseline.git.branch -cne [string]$Current.git.branch -or
            [string]$Baseline.git.worktree_root -cne [string]$Current.git.worktree_root -or
            [string]$Baseline.git.git_common_dir -cne [string]$Current.git.git_common_dir
        ) {
            Throw-AgentTasksError -Code 'AT-BASELINE-WORKTREE' -ExitCode 3 -SafeMessage 'The branch or authoritative worktree changed after task bootstrap.'
        }
    } elseif ([string]$Baseline.git.worktree_root -cne [string]$Current.git.worktree_root) {
        Throw-AgentTasksError -Code 'AT-BASELINE-WORKTREE' -ExitCode 3 -SafeMessage 'The non-Git project root changed after task bootstrap.'
    }
}

function Get-AgentTasksDerivedWorkspaceChanges {
    param(
        [Parameter(Mandatory)][object]$Baseline,
        [Parameter(Mandatory)][object]$Current,
        [Parameter(Mandatory)][string]$WorktreeRoot
    )
    $baselineMap = Get-AgentTasksSnapshotEntryMap -Snapshot $Baseline
    $currentMap = Get-AgentTasksSnapshotEntryMap -Snapshot $Current
    $currentIndexMap = Get-AgentTasksIndexMap -Snapshot $Current
    $paths = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($path in $baselineMap.Keys) { [void]$paths.Add([string]$path) }
    foreach ($path in $currentMap.Keys) { [void]$paths.Add([string]$path) }

    $changes = [Collections.Generic.List[object]]::new()
    foreach ($path in @($paths | Sort-Object)) {
        $baselineEntry = if ($baselineMap.ContainsKey($path)) { $baselineMap[$path] } else { $null }
        $currentEntry = if ($currentMap.ContainsKey($path)) {
            $currentMap[$path]
        } else {
            Get-AgentTasksPathIdentity -WorktreeRoot $WorktreeRoot -Path $path -IndexMap $currentIndexMap
        }
        if ($null -eq $baselineEntry -or -not (Test-AgentTasksFileIdentityEqual -Left $baselineEntry -Right $currentEntry)) {
            [void]$changes.Add($currentEntry)
        }
    }
    return @($changes.ToArray() | Sort-Object path)
}

function Test-AgentTasksPathInScope {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][object[]]$Scope
    )
    foreach ($entry in $Scope) {
        $kind = [string]$entry.kind
        if ($kind -ceq 'exact' -and $Path.Equals([string]$entry.path, [StringComparison]::OrdinalIgnoreCase)) { return $true }
        if ($kind -ceq 'subtree') {
            $root = ([string]$entry.path).TrimEnd('/')
            if (
                $Path.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or
                $Path.StartsWith($root + '/', [StringComparison]::OrdinalIgnoreCase)
            ) { return $true }
        }
        if ($kind -ceq 'glob') {
            $pattern = [Regex]::Escape([string]$entry.pattern)
            $pattern = $pattern.Replace('\*\*', '.*').Replace('\*', '[^/]*').Replace('\?', '[^/]')
            if ([Regex]::IsMatch($Path, '^' + $pattern + '$', [Text.RegularExpressions.RegexOptions]::IgnoreCase)) { return $true }
        }
    }
    return $false
}

function ConvertTo-AgentTasksAcceptanceInputs {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$AcceptanceInputs,
        [Parameter(Mandatory)][string]$WorktreeRoot,
        [Parameter(Mandatory)][object]$CurrentSnapshot
    )
    $indexMap = Get-AgentTasksIndexMap -Snapshot $CurrentSnapshot
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $records = [Collections.Generic.List[object]]::new()
    foreach ($input in $AcceptanceInputs) {
        if ($input -isnot [Collections.IDictionary]) {
            Throw-AgentTasksError -Code 'AT-ACCEPTANCE-INPUT' -ExitCode 2 -SafeMessage 'Each acceptance input must be an object.'
        }
        Assert-AgentTasksClosedObject -Value $input -Allowed @('path', 'role') -Required @('path', 'role')
        $path = ConvertTo-AgentTasksRelativePath -Path ([string]$input.path)
        if (-not $seen.Add($path)) {
            Throw-AgentTasksError -Code 'AT-ACCEPTANCE-INPUT' -ExitCode 2 -SafeMessage 'Acceptance input paths must be unique.'
        }
        $identity = Get-AgentTasksPathIdentity -WorktreeRoot $WorktreeRoot -Path $path -IndexMap $indexMap
        if ([string]$identity.presence -cne 'present' -or -not $identity.sha256) {
            Throw-AgentTasksError -Code 'AT-ACCEPTANCE-INPUT-MISSING' -ExitCode 3 -SafeMessage 'An acceptance input is absent or cannot be hashed.'
        }
        $record = Get-AgentTasksIdentityProjection -Entry $identity
        $record.role = [string]$input.role
        [void]$records.Add($record)
    }
    return @($records.ToArray() | Sort-Object -Property `
        @{ Expression = { [string]$_['path'] } },
        @{ Expression = { [string]$_['role'] } })
}

function ConvertTo-AgentTasksScopeDispositions {
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ScopeDispositions)
    $map = @{}
    $records = [Collections.Generic.List[object]]::new()
    foreach ($disposition in $ScopeDispositions) {
        if ($disposition -isnot [Collections.IDictionary]) {
            Throw-AgentTasksError -Code 'AT-SCOPE-DISPOSITION' -ExitCode 2 -SafeMessage 'Each scope disposition must be an object.'
        }
        Assert-AgentTasksClosedObject -Value $disposition -Allowed @('path', 'disposition', 'reason') -Required @('path', 'disposition', 'reason')
        $path = ConvertTo-AgentTasksRelativePath -Path ([string]$disposition.path)
        if ($map.ContainsKey($path) -or [string]::IsNullOrWhiteSpace([string]$disposition.reason)) {
            Throw-AgentTasksError -Code 'AT-SCOPE-DISPOSITION' -ExitCode 2 -SafeMessage 'Scope dispositions must be unique and include a reason.'
        }
        $record = [ordered]@{
            path = $path
            disposition = [string]$disposition.disposition
            reason = [string]$disposition.reason
        }
        $map[$path] = $record
        [void]$records.Add($record)
    }
    return [pscustomobject]@{ Map = $map; Records = @($records.ToArray() | Sort-Object path) }
}

function New-AgentTasksCandidate {
    param(
        [Parameter(Mandatory)][object]$TaskState,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$AcceptanceInputs,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ScopeDispositions,
        [Parameter(Mandatory)][string]$CandidateId,
        [Parameter(Mandatory)][long]$Lineage,
        [Parameter(Mandatory)][string]$FrozenAt
    )
    $worktreeRoot = [string]$TaskState.Revision.authoritative_worktree
    if (-not $worktreeRoot) {
        Throw-AgentTasksError -Code 'AT-TASK-READ-ONLY' -ExitCode 3 -SafeMessage 'A read-only task cannot freeze a source candidate.'
    }
    [void](Test-AgentTasksNestedRepositories -WorktreeRoot $worktreeRoot)
    $current = Get-AgentTasksWorkspaceSnapshot -WorkingDirectory $worktreeRoot -OwnedIgnoredOutputs @($TaskState.Contract.owned_ignored_outputs)
    Assert-AgentTasksBaselineIdentity -Baseline $TaskState.Baseline -Current $current
    $acceptanceRecords = @(ConvertTo-AgentTasksAcceptanceInputs -AcceptanceInputs $AcceptanceInputs -WorktreeRoot $worktreeRoot -CurrentSnapshot $current)
    $acceptancePaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $acceptanceRecords) { [void]$acceptancePaths.Add([string]$entry.path) }
    $dispositions = ConvertTo-AgentTasksScopeDispositions -ScopeDispositions $ScopeDispositions
    $ignoredPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($path in @($TaskState.Contract.owned_ignored_outputs)) { [void]$ignoredPaths.Add([string]$path) }

    $entries = [Collections.Generic.List[object]]::new()
    $unexplained = [Collections.Generic.List[string]]::new()
    foreach ($change in @(Get-AgentTasksDerivedWorkspaceChanges -Baseline $TaskState.Baseline -Current $current -WorktreeRoot $worktreeRoot)) {
        $path = [string]$change.path
        if ($acceptancePaths.Contains($path)) { continue }
        $entry = Get-AgentTasksIdentityProjection -Entry $change
        if ($ignoredPaths.Contains($path)) {
            $entry.role = 'owned_ignored_output'
        } elseif (Test-AgentTasksPathInScope -Path $path -Scope @($TaskState.Contract.write_scope)) {
            $entry.role = 'owned_output'
        } elseif ($dispositions.Map.ContainsKey($path)) {
            $entry.role = 'scope_disposition'
            $entry.disposition = [string]$dispositions.Map[$path].disposition
            $entry.disposition_reason = [string]$dispositions.Map[$path].reason
        } else {
            [void]$unexplained.Add($path)
            continue
        }
        [void]$entries.Add($entry)
    }
    if ($unexplained.Count -gt 0) {
        Throw-AgentTasksError -Code 'AT-SCOPE-UNEXPLAINED' -ExitCode 3 -SafeMessage 'The workspace contains changed paths outside the accepted task scope.'
    }
    foreach ($path in $dispositions.Map.Keys) {
        if (-not @($entries | Where-Object { [string]$_.path -ceq [string]$path }).Count) {
            Throw-AgentTasksError -Code 'AT-SCOPE-DISPOSITION' -ExitCode 3 -SafeMessage 'A scope disposition does not name a current changed path.'
        }
    }
    $sortedEntries = @($entries.ToArray() | Sort-Object path, role)
    $baselineIdentity = [ordered]@{
        baseline_ref = [string]$TaskState.Revision.baseline_ref
        baseline_record_hash = [string]$TaskState.Baseline.record_hash
        head = $TaskState.Baseline.git.head
        branch = $TaskState.Baseline.git.branch
        worktree_root = [string]$TaskState.Baseline.git.worktree_root
        git_common_dir = $TaskState.Baseline.git.git_common_dir
    }
    return [ordered]@{
        schema_version = 1
        record_type = 'candidate'
        task_id = [string]$TaskState.Contract.task_id
        task_contract_hash = Get-AgentTasksSha256 -Value $TaskState.Contract
        candidate_id = $CandidateId
        lineage = $Lineage
        baseline = $baselineIdentity
        acceptance_inputs = @($acceptanceRecords)
        entries = $sortedEntries
        scope_dispositions = @($dispositions.Records)
        integration_provenance = @($TaskState.Revision.work_unit_outcome_ids | Sort-Object -Unique)
        frozen_at = $FrozenAt
    }
}

function Publish-AgentTasksTaskRevisionUnlocked {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][scriptblock]$Mutator
    )
    $next = Copy-AgentTasksDictionaryWithoutHash -Value $Authority.Revision
    & $Mutator $next
    $nextNumber = [long]$Authority.Revision.revision + 1
    $next.revision = $nextNumber
    $next.revision_id = 'R{0:D6}' -f $nextNumber
    $next.previous_revision = [string]$Authority.Revision.revision_id
    $next.previous_revision_sha256 = [string]$Authority.RevisionSha256
    $next.created_at = Get-AgentTasksUtcTimestamp
    return Publish-AgentTasksRecord -LiteralPath (Join-Path $Authority.Root ('state\R{0:D6}.json' -f $nextNumber)) -Value $next
}

function Set-AgentTasksReconcileRequiredUnlocked {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$ReasonCode
    )
    return Publish-AgentTasksTaskRevisionUnlocked -Authority $Authority -Mutator {
        param($next)
        $next.status = 'reconcile_required'
        $next.reconciliation_reason_code = $ReasonCode
    }
}

function New-AgentTasksFrozenCandidate {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )
    $taskId = [string]$Request.task_id
    return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain task -Id $taskId -Action {
        $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $taskId
        Assert-AgentTasksTaskCas -Authority $authority -Request $Request -SessionRef $SessionRef
        if ([string]$authority.Revision.status -notin @('active', 'partial', 'rework')) {
            Throw-AgentTasksError -Code 'AT-CANDIDATE-STATE' -ExitCode 3 -SafeMessage 'The task state cannot freeze a candidate.'
        }
        $existing = @(Get-ChildItem -LiteralPath (Join-Path $authority.Root 'candidates') -File -Filter 'C*.json')
        $lineage = $existing.Count + 1
        $candidateId = 'C{0}' -f $lineage
        $frozenAt = Get-AgentTasksUtcTimestamp
        try {
            $candidate = New-AgentTasksCandidate -TaskState $authority -AcceptanceInputs @($Request.acceptance_inputs) `
                -ScopeDispositions @($Request.scope_dispositions) -CandidateId $candidateId -Lineage $lineage -FrozenAt $frozenAt
        } catch {
            $code = [string]$_.Exception.Data['AgentTasksCode']
            if ($code -in @('AT-BASELINE-HEAD', 'AT-BASELINE-WORKTREE')) {
                [void](Set-AgentTasksReconcileRequiredUnlocked -Authority $authority -ReasonCode $code)
            }
            throw
        }
        $publishedCandidate = Publish-AgentTasksRecord -LiteralPath (Join-Path $authority.Root (Join-Path 'candidates' ($candidateId + '.json'))) -Value $candidate
        $candidateHash = [string]$publishedCandidate.Record.record_hash
        $revision = Publish-AgentTasksTaskRevisionUnlocked -Authority $authority -Mutator {
            param($next)
            $next.status = 'candidate_frozen'
            $next.selected_candidate_id = $candidateId
            $next.selected_candidate_hash = $candidateHash
            $next.candidate_lineage = $lineage
            $priorCandidateIds = if ($next.Contains('candidate_ids')) { @($next.candidate_ids) } else { @() }
            $next.candidate_ids = @(@($priorCandidateIds) + @($candidateId) | Sort-Object -Unique)
        }
        return [ordered]@{
            task_id = $taskId
            candidate_id = $candidateId
            candidate_hash = $candidateHash
            revision = [long]$revision.Record.revision
            revision_sha256 = [string]$revision.Sha256
            status = 'candidate_frozen'
        }
    }
}

function Test-AgentTasksCandidate {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$TaskId,
        [Parameter(Mandatory)][string]$CandidateId
    )
    return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain task -Id $TaskId -Action {
        $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $TaskId
        $comparison = Test-AgentTasksCandidateCurrentUnlocked -Authority $authority -CandidateId $CandidateId
        if (-not $comparison.Valid) {
            [void](Publish-AgentTasksTaskRevisionUnlocked -Authority $authority -Mutator {
                param($next)
                $next.status = 'rework'
                $priorStaleIds = if ($next.Contains('stale_candidate_ids')) { @($next.stale_candidate_ids) } else { @() }
                $next.stale_candidate_ids = @(@($priorStaleIds) + @($CandidateId) | Sort-Object -Unique)
                $next.selected_candidate_id = $null
                $next.selected_candidate_hash = $null
            })
            Throw-AgentTasksError -Code 'AT-CANDIDATE-DRIFT' -ExitCode 3 -SafeMessage 'The candidate or its acceptance inputs drifted.'
        }
        return [ordered]@{
            task_id = $TaskId
            candidate_id = $CandidateId
            candidate_hash = [string]$comparison.Candidate.record_hash
            status = 'valid'
        }
    }
}

function Test-AgentTasksCandidateCurrentUnlocked {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$CandidateId
    )
    $candidatePath = Join-Path $Authority.Root (Join-Path 'candidates' ($CandidateId + '.json'))
    if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
        Throw-AgentTasksError -Code 'AT-CANDIDATE-NOT-FOUND' -ExitCode 3 -SafeMessage 'The requested candidate does not exist.'
    }
    $candidate = Read-AgentTasksJsonFile -LiteralPath $candidatePath
    if ([string]$candidate.record_hash -cne (Get-AgentTasksSha256 -Value $candidate)) {
        Throw-AgentTasksError -Code 'AT-CANDIDATE-CORRUPT' -ExitCode 4 -SafeMessage 'The candidate record hash is invalid.'
    }
    try {
        $currentCandidate = New-AgentTasksCandidate -TaskState $Authority -AcceptanceInputs @($candidate.acceptance_inputs | ForEach-Object {
            [ordered]@{ path = [string]$_.path; role = [string]$_.role }
        }) -ScopeDispositions @($candidate.scope_dispositions) -CandidateId ([string]$candidate.candidate_id) `
            -Lineage ([long]$candidate.lineage) -FrozenAt ([string]$candidate.frozen_at)
        $valid = (Get-AgentTasksSha256 -Value $currentCandidate) -ceq [string]$candidate.record_hash
        return [pscustomobject]@{ Valid = $valid; Candidate = $candidate; ReasonCode = $(if ($valid) { $null } else { 'AT-CANDIDATE-DRIFT' }) }
    } catch {
        $code = [string]$_.Exception.Data['AgentTasksCode']
        if ($code -in @('AT-SCOPE-UNEXPLAINED', 'AT-BASELINE-HEAD', 'AT-BASELINE-WORKTREE', 'AT-NESTED-REPOSITORY-DIRTY', 'AT-ACCEPTANCE-INPUT-MISSING')) {
            return [pscustomobject]@{ Valid = $false; Candidate = $candidate; ReasonCode = $code }
        }
        throw
    }
}
