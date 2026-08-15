#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command Get-AgentTasksWorkspaceSnapshot -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'AgentTasks.Git.ps1')
}

$script:TaskTransitions = @{
    active = @('waiting_for_user', 'blocked', 'partial', 'candidate_frozen', 'transferring', 'cancelled', 'terminally_blocked', 'reconcile_required')
    waiting_for_user = @('active', 'cancelled', 'terminally_blocked', 'reconcile_required')
    blocked = @('active', 'waiting_for_user', 'cancelled', 'terminally_blocked', 'reconcile_required')
    partial = @('active', 'rework', 'candidate_frozen', 'cancelled', 'terminally_blocked', 'reconcile_required')
    candidate_frozen = @('verifying', 'reviewing', 'rework', 'transferring', 'accepted', 'cancelled', 'reconcile_required')
    verifying = @('reviewing', 'rework', 'candidate_frozen', 'transferring', 'reconcile_required')
    reviewing = @('rework', 'candidate_frozen', 'transferring', 'accepted', 'reconcile_required')
    rework = @('active', 'partial', 'candidate_frozen', 'transferring', 'cancelled', 'terminally_blocked', 'reconcile_required')
    transferring = @('active', 'partial', 'candidate_frozen', 'verifying', 'reviewing', 'rework', 'waiting_for_user', 'blocked', 'reconcile_required')
    reconcile_required = @('active', 'partial', 'candidate_frozen', 'rework', 'waiting_for_user', 'blocked', 'cancelled', 'terminally_blocked')
    accepted = @()
    cancelled = @()
    terminally_blocked = @()
}

$script:PhaseTransitions = @{
    planned = @('active', 'cancelled', 'terminally_blocked')
    active = @('waiting', 'blocked', 'accepted', 'cancelled', 'terminally_blocked')
    waiting = @('active', 'blocked', 'cancelled', 'terminally_blocked')
    blocked = @('active', 'waiting', 'cancelled', 'terminally_blocked')
    accepted = @()
    cancelled = @()
    terminally_blocked = @()
}

function Assert-AgentTasksIdentifier {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Code
    )
    if ($Id -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$') {
        Throw-AgentTasksError -Code $Code -ExitCode 2 -SafeMessage 'The authority identifier is invalid.'
    }
}

function ConvertTo-AgentTasksRelativePath {
    param([Parameter(Mandatory)][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or [IO.Path]::IsPathFullyQualified($Path) -or $Path.Contains([char]0)) {
        Throw-AgentTasksError -Code 'AT-SCOPE-PATH' -ExitCode 2 -SafeMessage 'A write-scope path is invalid.'
    }
    $normalized = ($Path -replace '\\', '/').Trim('/')
    if (-not $normalized -or @($normalized -split '/') -contains '..') {
        Throw-AgentTasksError -Code 'AT-SCOPE-PATH' -ExitCode 2 -SafeMessage 'A write-scope path escapes the repository.'
    }
    $reserved = @('CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9')
    foreach ($segment in $normalized -split '/') {
        if ($reserved -contains [IO.Path]::GetFileNameWithoutExtension($segment).ToUpperInvariant()) {
            Throw-AgentTasksError -Code 'AT-SCOPE-PATH' -ExitCode 2 -SafeMessage 'A write-scope path contains a reserved device name.'
        }
    }
    return $normalized
}

function ConvertTo-AgentTasksWriteScope {
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Scope)

    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $normalized = [Collections.Generic.List[object]]::new()
    foreach ($entry in $Scope) {
        if ($entry -isnot [Collections.IDictionary]) {
            Throw-AgentTasksError -Code 'AT-SCOPE-TYPE' -ExitCode 2 -SafeMessage 'Each write-scope entry must be an object.'
        }
        if (-not $entry.Contains('kind') -or [string]$entry.kind -notin @('exact', 'subtree', 'glob')) {
            Throw-AgentTasksError -Code 'AT-SCOPE-TYPE' -ExitCode 2 -SafeMessage 'Each write-scope entry must use exact, subtree, or glob.'
        }
        $kind = [string]$entry.kind
        $field = if ($kind -ceq 'glob') { 'pattern' } else { 'path' }
        Assert-AgentTasksClosedObject -Value $entry -Allowed @('kind', $field) -Required @('kind', $field)
        $value = ConvertTo-AgentTasksRelativePath -Path ([string]$entry[$field])
        $identity = "$kind|$value"
        if (-not $seen.Add($identity)) {
            Throw-AgentTasksError -Code 'AT-SCOPE-DUPLICATE' -ExitCode 2 -SafeMessage 'The write scope contains a duplicate entry.'
        }
        $copy = [ordered]@{ kind = $kind }
        $copy[$field] = $value
        [void]$normalized.Add($copy)
    }
    return $normalized.ToArray()
}

function Test-AgentTasksScopePair {
    param(
        [Parameter(Mandatory)][Collections.IDictionary]$Left,
        [Parameter(Mandatory)][Collections.IDictionary]$Right
    )
    if ([string]$Left.kind -ceq 'glob' -or [string]$Right.kind -ceq 'glob') { return 'ambiguous' }
    $leftPath = [string]$Left.path
    $rightPath = [string]$Right.path
    if ($Left.kind -ceq 'exact' -and $Right.kind -ceq 'exact') {
        return $(if ($leftPath.Equals($rightPath, [StringComparison]::OrdinalIgnoreCase)) { 'conflict' } else { 'disjoint' })
    }
    $leftPrefix = $leftPath.TrimEnd('/') + '/'
    $rightPrefix = $rightPath.TrimEnd('/') + '/'
    if (
        $leftPath.Equals($rightPath, [StringComparison]::OrdinalIgnoreCase) -or
        $leftPath.StartsWith($rightPrefix, [StringComparison]::OrdinalIgnoreCase) -or
        $rightPath.StartsWith($leftPrefix, [StringComparison]::OrdinalIgnoreCase)
    ) { return 'conflict' }
    return 'disjoint'
}

function Test-AgentTasksScopeOverride {
    param([AllowNull()][object]$Override)
    if ($Override -isnot [Collections.IDictionary]) { return $false }
    foreach ($name in @('confirmed', 'authority', 'paths', 'reason', 'order')) {
        if (-not $Override.Contains($name)) { return $false }
    }
    return $Override.confirmed -eq $true -and [string]$Override.authority -ceq 'user' -and
        @($Override.paths).Count -gt 0 -and @($Override.order).Count -gt 0 -and
        -not [string]::IsNullOrWhiteSpace([string]$Override.reason)
}

function Get-AgentTasksPhaseAuthority {
    param(
        [Parameter(Mandatory)][string]$StateRoot,
        [Parameter(Mandatory)][string]$PhaseId
    )
    $phaseRoot = Join-Path $StateRoot (Join-Path 'phases' $PhaseId)
    if (-not (Test-Path -LiteralPath $phaseRoot -PathType Container)) {
        Throw-AgentTasksError -Code 'AT-PHASE-NOT-FOUND' -ExitCode 3 -SafeMessage 'The requested phase does not exist.'
    }
    $stateDirectory = Join-Path $phaseRoot 'state'
    $chain = Get-AgentTasksRevisionChain -StateDirectory $stateDirectory
    if ($chain.Status -cne 'valid') {
        Throw-AgentTasksError -Code 'AT-REVISION-CHAIN' -ExitCode 4 -SafeMessage 'Phase authority requires reconciliation.'
    }
    $revision = $chain.Records[-1]
    return [pscustomobject]@{
        Root = $phaseRoot
        Contract = Read-AgentTasksJsonFile -LiteralPath (Join-Path $phaseRoot 'contract.json')
        Revision = $revision
        RevisionSha256 = Get-AgentTasksSha256 -LiteralPath (Join-Path $stateDirectory ('R{0:D6}.json' -f [long]$revision.revision))
    }
}

function Get-AgentTasksTaskAuthority {
    param(
        [Parameter(Mandatory)][string]$StateRoot,
        [Parameter(Mandatory)][string]$TaskId
    )
    $activeRoot = Join-Path $StateRoot (Join-Path 'tasks' $TaskId)
    $trashRoot = Join-Path $StateRoot (Join-Path 'trash' $TaskId)
    $activeExists = Test-Path -LiteralPath $activeRoot -PathType Container
    $trashExists = Test-Path -LiteralPath $trashRoot -PathType Container
    if ($activeExists -and $trashExists) {
        Throw-AgentTasksError -Code 'AT-TASK-DUPLICATE' -ExitCode 4 -SafeMessage 'The task identifier exists in both active and trash authority.'
    }
    if (-not $activeExists -and -not $trashExists) {
        Throw-AgentTasksError -Code 'AT-TASK-NOT-FOUND' -ExitCode 3 -SafeMessage 'The requested task does not exist.'
    }
    $taskRoot = if ($activeExists) { $activeRoot } else { $trashRoot }
    $stateDirectory = Join-Path $taskRoot 'state'
    $chain = Get-AgentTasksRevisionChain -StateDirectory $stateDirectory
    if ($chain.Status -cne 'valid') {
        Throw-AgentTasksError -Code 'AT-REVISION-CHAIN' -ExitCode 4 -SafeMessage 'Task authority requires reconciliation.'
    }
    $revision = $chain.Records[-1]
    $baselineRef = if ($revision.Contains('baseline_ref')) { [string]$revision.baseline_ref } else { 'baseline.json' }
    $baselinePath = [IO.Path]::GetFullPath((Join-Path $taskRoot ($baselineRef -replace '/', [IO.Path]::DirectorySeparatorChar)))
    Assert-AgentTasksPathInside -Root $taskRoot -Candidate $baselinePath
    return [pscustomobject]@{
        Root = $taskRoot
        Contract = Read-AgentTasksJsonFile -LiteralPath (Join-Path $taskRoot 'contract.json')
        Baseline = Read-AgentTasksJsonFile -LiteralPath $baselinePath
        BaselinePath = $baselinePath
        Revision = $revision
        RevisionSha256 = Get-AgentTasksSha256 -LiteralPath (Join-Path $stateDirectory ('R{0:D6}.json' -f [long]$revision.revision))
    }
}

function Initialize-AgentTasksPhase {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request
    )
    Assert-AgentTasksIdentifier -Id ([string]$Request.phase_id) -Code 'AT-PHASE-ID'
    $stateRoot = Initialize-AgentTasksStateRoot -Context $Context
    return Invoke-WithAgentTasksLock -StateRoot $stateRoot -Domain repository -Id 'authority' -Action {
        [void](Initialize-AgentTasksProjectUnlocked -Context $Context -DisplayName ([IO.Path]::GetFileName($Context.ProjectRoot)))
        $phaseId = [string]$Request.phase_id
        $phaseRoot = Join-Path $stateRoot (Join-Path 'phases' $phaseId)
        if (Test-Path -LiteralPath $phaseRoot) {
            Throw-AgentTasksError -Code 'AT-PHASE-EXISTS' -ExitCode 3 -SafeMessage 'The phase identifier already exists.'
        }
        foreach ($dependency in @($Request.dependencies)) {
            Assert-AgentTasksIdentifier -Id ([string]$dependency) -Code 'AT-PHASE-ID'
            [void](Get-AgentTasksPhaseAuthority -StateRoot $stateRoot -PhaseId ([string]$dependency))
        }
        [void](Publish-AgentTasksBundle -FinalDirectory $phaseRoot -Builder {
            param($temporary)
            [void](New-Item -ItemType Directory -Path (Join-Path $temporary 'state'))
            [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $temporary 'contract.json') -Value ([ordered]@{
                schema_version = 1; record_type = 'phase_contract'; phase_id = $phaseId
                objective = [string]$Request.objective; authority = @($Request.authority)
                dependencies = @($Request.dependencies); exit_obligations = @($Request.exit_obligations)
            }))
            [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $temporary 'state\R000001.json') -Value ([ordered]@{
                schema_version = 1; record_type = 'phase_state_revision'; phase_id = $phaseId
                revision = 1; revision_id = 'R000001'; previous_revision = $null
                previous_revision_sha256 = $null; status = 'planned'; linked_task_ids = @()
                supporting_refs = @(); created_at = Get-AgentTasksUtcTimestamp
            }))
        })
        return [ordered]@{ phase_id = $phaseId; revision = 1; status = 'planned' }
    }
}

function Assert-AgentTasksTaskCas {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
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
    if ([string]$Authority.Revision.owner_session_ref -cne $SessionRef) {
        Throw-AgentTasksError -Code 'AT-SESSION-OWNER' -ExitCode 3 -SafeMessage 'The session does not own task authority.'
    }
    if ([string]$Authority.Revision.status -ceq 'transferring') {
        Throw-AgentTasksError -Code 'AT-TRANSFER-IN-PROGRESS' -ExitCode 3 -SafeMessage 'Only the named handoff transition may mutate a transferring task.'
    }
}

function Write-AgentTasksRevision {
    param(
        [Parameter(Mandatory)][string]$StateRoot,
        [Parameter(Mandatory)][string]$TaskId,
        [Parameter(Mandatory)][long]$ExpectedRevision,
        [Parameter(Mandatory)][string]$ExpectedRevisionSha256,
        [Parameter(Mandatory)][long]$ExpectedLeaseGeneration,
        [Parameter(Mandatory)][string]$SessionRef,
        [Parameter(Mandatory)][scriptblock]$Mutator,
        [switch]$AllowLegacyContinuityInitialization,
        [AllowNull()][scriptblock]$BeforePublish = $null
    )
    return Invoke-WithAgentTasksLock -StateRoot $StateRoot -Domain task -Id $TaskId -Action {
        $authority = Get-AgentTasksTaskAuthority -StateRoot $StateRoot -TaskId $TaskId
        $casValues = [ordered]@{
            expected_revision = $ExpectedRevision
            expected_revision_sha256 = $ExpectedRevisionSha256
            expected_lease_generation = $ExpectedLeaseGeneration
        }
        Assert-AgentTasksTaskCas -Authority $authority -Request $casValues -SessionRef $SessionRef
        $hasWorkflowClass = $authority.Revision.Contains('workflow_class')
        $hasLockedDecisions = $authority.Revision.Contains('locked_decisions')
        if ($hasWorkflowClass -ne $hasLockedDecisions) {
            Throw-AgentTasksError -Code 'AT-REVISION-CHAIN' -ExitCode 4 -SafeMessage 'Task continuity authority requires reconciliation.'
        }
        if (-not $hasWorkflowClass -and -not $AllowLegacyContinuityInitialization) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CLASSIFICATION-REQUIRED' -ExitCode 3 -SafeMessage 'The legacy task requires an explicit continuity classification.'
        }
        $next = [ordered]@{}
        foreach ($key in $authority.Revision.Keys) {
            if ([string]$key -cne 'record_hash') { $next[[string]$key] = $authority.Revision[$key] }
        }
        & $Mutator $next $authority
        if (-not $next.Contains('workflow_class') -or -not $next.Contains('locked_decisions')) {
            Throw-AgentTasksError -Code 'AT-CONTINUITY-CLASSIFICATION-REQUIRED' -ExitCode 3 -SafeMessage 'A task revision must retain its continuity classification.'
        }
        $next.workflow_class = Assert-AgentTasksWorkflowClass -Value $next.workflow_class
        $next.locked_decisions = @(ConvertTo-AgentTasksLockedDecisions -Value $next.locked_decisions)
        $nextNumber = [long]$authority.Revision.revision + 1
        $next.revision = $nextNumber
        $next.revision_id = 'R{0:D6}' -f $nextNumber
        $next.previous_revision = [string]$authority.Revision.revision_id
        $next.previous_revision_sha256 = [string]$authority.RevisionSha256
        $next.created_at = Get-AgentTasksUtcTimestamp
        $path = Join-Path $authority.Root ('state\R{0:D6}.json' -f $nextNumber)
        $rollbackPaths = [Collections.Generic.List[string]]::new()
        try {
            if ($null -ne $BeforePublish) {
                foreach ($rollbackPath in @(& $BeforePublish $next $authority)) {
                    if (-not [string]::IsNullOrWhiteSpace([string]$rollbackPath)) {
                        [void]$rollbackPaths.Add([IO.Path]::GetFullPath([string]$rollbackPath))
                    }
                }
            }
            $published = Publish-AgentTasksRecord -LiteralPath $path -Value $next
            return [pscustomobject]@{ Revision = $published.Record; RevisionSha256 = $published.Sha256 }
        } catch {
            $supportingRoot = [IO.Path]::GetFullPath((Join-Path $authority.Root 'supporting')).TrimEnd('\', '/')
            foreach ($rollbackPath in $rollbackPaths) {
                if ((Test-AgentTasksPathInside -Root $supportingRoot -Candidate $rollbackPath) -and (Test-Path -LiteralPath $rollbackPath -PathType Leaf)) {
                    Remove-Item -LiteralPath $rollbackPath -Force
                }
            }
            throw
        }
    }
}

function Get-AgentTasksActiveTaskAuthorities {
    param([Parameter(Mandatory)][string]$StateRoot)
    $tasksRoot = Join-Path $StateRoot 'tasks'
    if (-not (Test-Path -LiteralPath $tasksRoot -PathType Container)) { return @() }
    return @(
        foreach ($directory in Get-ChildItem -LiteralPath $tasksRoot -Directory | Sort-Object Name) {
            $authority = Get-AgentTasksTaskAuthority -StateRoot $StateRoot -TaskId $directory.Name
            if ([string]$authority.Revision.status -notin @('accepted', 'cancelled', 'terminally_blocked')) { $authority }
        }
    )
}

function New-AgentTasksAcceptanceCriteria {
    param([Parameter(Mandatory)][object[]]$Criteria)
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $result = [Collections.Generic.List[object]]::new()
    $sequence = 1
    foreach ($criterion in $Criteria) {
        if ($criterion -isnot [Collections.IDictionary] -or -not $criterion.Contains('text') -or -not $criterion.Contains('mandatory')) {
            Throw-AgentTasksError -Code 'AT-AC-SCHEMA' -ExitCode 2 -SafeMessage 'Each acceptance criterion requires text and mandatory.'
        }
        $id = if ($criterion.Contains('id')) { [string]$criterion.id } else { 'AC-{0:D3}' -f $sequence }
        Assert-AgentTasksIdentifier -Id $id -Code 'AT-AC-ID'
        if (-not $seen.Add($id)) {
            Throw-AgentTasksError -Code 'AT-AC-ID' -ExitCode 2 -SafeMessage 'Acceptance criterion IDs must be unique.'
        }
        [void]$result.Add([ordered]@{ id = $id; text = [string]$criterion.text; mandatory = [bool]$criterion.mandatory })
        $sequence++
    }
    return $result.ToArray()
}

function ConvertTo-AgentTasksContinuityText {
    param(
        [AllowNull()][object]$Value,
        [Parameter(Mandatory)][int]$MaximumUtf8Bytes,
        [Parameter(Mandatory)][string]$Code
    )
    if ($Value -isnot [string]) {
        Throw-AgentTasksError -Code $Code -ExitCode 2 -SafeMessage 'A continuity string is invalid.'
    }
    try {
        $normalized = ([string]$Value).Replace("`r`n", "`n").Replace("`r", "`n").Normalize([Text.NormalizationForm]::FormC)
        $byteCount = [Text.UTF8Encoding]::new($false, $true).GetByteCount($normalized)
    } catch {
        Throw-AgentTasksError -Code $Code -ExitCode 2 -SafeMessage 'A continuity string is invalid.'
    }
    if ([string]::IsNullOrWhiteSpace($normalized) -or $normalized.Contains([char]0) -or $byteCount -gt $MaximumUtf8Bytes) {
        Throw-AgentTasksError -Code $Code -ExitCode 2 -SafeMessage 'A continuity string is invalid.'
    }
    return $normalized
}

function Assert-AgentTasksWorkflowClass {
    param([AllowNull()][object]$Value)
    if ($Value -isnot [string] -or [string]$Value -cnotin @('quick', 'standard', 'orchestrated')) {
        Throw-AgentTasksError -Code 'AT-WORKFLOW-CLASS' -ExitCode 2 -SafeMessage 'Workflow class must be quick, standard, or orchestrated.'
    }
    return [string]$Value
}

function ConvertTo-AgentTasksLockedDecisions {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value -or $Value -is [string] -or $Value -is [Collections.IDictionary] -or $Value -isnot [Collections.IEnumerable]) {
        Throw-AgentTasksError -Code 'AT-DECISION-SCHEMA' -ExitCode 2 -SafeMessage 'Locked decisions must be a JSON array.'
    }
    $items = @($Value)
    if ($items.Count -gt 64) {
        Throw-AgentTasksError -Code 'AT-DECISION-LIMIT' -ExitCode 2 -SafeMessage 'The locked-decision limit was exceeded.'
    }
    $byId = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    foreach ($item in $items) {
        if ($item -isnot [Collections.IDictionary]) {
            Throw-AgentTasksError -Code 'AT-DECISION-SCHEMA' -ExitCode 2 -SafeMessage 'Each locked decision must be a JSON object.'
        }
        Assert-AgentTasksClosedObject -Value $item -Allowed @('decision_id', 'statement', 'authority_ref') -Required @('decision_id', 'statement', 'authority_ref')
        if ($item.decision_id -isnot [string] -or [string]$item.decision_id -cnotmatch '^D-[A-Z0-9][A-Z0-9._-]{0,63}$') {
            Throw-AgentTasksError -Code 'AT-DECISION-ID' -ExitCode 2 -SafeMessage 'A locked-decision ID is invalid.'
        }
        $decisionId = [string]$item.decision_id
        if ($byId.ContainsKey($decisionId)) {
            Throw-AgentTasksError -Code 'AT-DECISION-ID' -ExitCode 2 -SafeMessage 'Locked-decision IDs must be unique.'
        }
        $byId[$decisionId] = [ordered]@{
            decision_id = $decisionId
            statement = ConvertTo-AgentTasksContinuityText -Value $item.statement -MaximumUtf8Bytes 2048 -Code 'AT-DECISION-STRING'
            authority_ref = ConvertTo-AgentTasksContinuityText -Value $item.authority_ref -MaximumUtf8Bytes 512 -Code 'AT-DECISION-STRING'
        }
    }
    [string[]]$ids = @($byId.Keys)
    [Array]::Sort($ids, [StringComparer]::Ordinal)
    return @($ids | ForEach-Object { $byId[$_] })
}

function Set-AgentTasksContinuityContract {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef,
        [Parameter(Mandatory)][string]$Runtime
    )

    $taskId = [string]$Request.task_id
    Assert-AgentTasksIdentifier -Id $taskId -Code 'AT-TASK-ID'
    $workflowClass = Assert-AgentTasksWorkflowClass -Value $Request.workflow_class
    $lockedDecisions = @(ConvertTo-AgentTasksLockedDecisions -Value $Request.locked_decisions)
    $authorityRef = ConvertTo-AgentTasksContinuityText -Value $Request.authority_ref -MaximumUtf8Bytes 512 -Code 'AT-CONTINUITY-AUTHORITY'
    $reason = ConvertTo-AgentTasksContinuityText -Value $Request.reason -MaximumUtf8Bytes 2048 -Code 'AT-CONTINUITY-REASON'
    $stateRoot = Initialize-AgentTasksStateRoot -Context $Context

    $mutation = Write-AgentTasksRevision -StateRoot $stateRoot -TaskId $taskId `
        -ExpectedRevision ([long]$Request.expected_revision) `
        -ExpectedRevisionSha256 ([string]$Request.expected_revision_sha256) `
        -ExpectedLeaseGeneration ([long]$Request.expected_lease_generation) `
        -SessionRef $SessionRef -AllowLegacyContinuityInitialization -Mutator {
            param($next, $currentAuthority)
            if ([string]$currentAuthority.Revision.owner_runtime -cne $Runtime) {
                Throw-AgentTasksError -Code 'AT-RUNTIME-OWNER' -ExitCode 3 -SafeMessage 'The runtime does not own task authority.'
            }
            $priorWorkflow = if ($currentAuthority.Revision.Contains('workflow_class')) { [string]$currentAuthority.Revision.workflow_class } else { $null }
            $priorDecisions = if ($currentAuthority.Revision.Contains('locked_decisions')) { @($currentAuthority.Revision.locked_decisions) } else { $null }
            if (
                $null -ne $priorWorkflow -and
                $priorWorkflow -ceq $workflowClass -and
                (ConvertTo-AgentTasksCanonicalJson -Value @($priorDecisions)) -ceq (ConvertTo-AgentTasksCanonicalJson -Value @($lockedDecisions))
            ) {
                Throw-AgentTasksError -Code 'AT-CONTINUITY-NOOP' -ExitCode 3 -SafeMessage 'The requested continuity contract is already current.'
            }
            $next.workflow_class = $workflowClass
            $next.locked_decisions = @($lockedDecisions)
        } -BeforePublish {
            param($next, $currentAuthority)
            $supportingDirectory = Join-Path $currentAuthority.Root 'supporting'
            [void](New-Item -ItemType Directory -Path $supportingDirectory -Force)
            $existing = @(Get-ChildItem -LiteralPath $supportingDirectory -File -Filter 'CC*.json' | Sort-Object Name)
            for ($index = 0; $index -lt $existing.Count; $index++) {
                if ($existing[$index].Name -cne ('CC{0:D6}.json' -f ($index + 1))) {
                    Throw-AgentTasksError -Code 'AT-REVISION-CHAIN' -ExitCode 4 -SafeMessage 'Continuity supporting authority requires reconciliation.'
                }
            }
            $changeId = 'CC{0:D6}' -f ($existing.Count + 1)
            $priorWorkflow = if ($currentAuthority.Revision.Contains('workflow_class')) { [string]$currentAuthority.Revision.workflow_class } else { $null }
            $priorDecisionsHash = if ($currentAuthority.Revision.Contains('locked_decisions')) { Get-AgentTasksSha256 -Value @($currentAuthority.Revision.locked_decisions) } else { $null }
            $published = Publish-AgentTasksRecord -LiteralPath (Join-Path $supportingDirectory ($changeId + '.json')) -Value ([ordered]@{
                schema_version = 1
                record_type = 'continuity_contract_change'
                continuity_change_id = $changeId
                task_id = $taskId
                prior_workflow_class = $priorWorkflow
                new_workflow_class = $workflowClass
                prior_locked_decisions_sha256 = $priorDecisionsHash
                new_locked_decisions_sha256 = Get-AgentTasksSha256 -Value @($lockedDecisions)
                authority_ref = $authorityRef
                reason = $reason
                created_at = [string]$next.created_at
            })
            $next.supporting_refs = @(@($next.supporting_refs) + @($changeId))
            return $published.Path
        }

    $changeId = [string]@($mutation.Revision.supporting_refs)[-1]
    return [ordered]@{
        task_id = $taskId
        workflow_class = [string]$mutation.Revision.workflow_class
        locked_decisions_sha256 = Get-AgentTasksSha256 -Value @($mutation.Revision.locked_decisions)
        continuity_change_id = $changeId
        revision = [long]$mutation.Revision.revision
        revision_sha256 = [string]$mutation.RevisionSha256
    }
}

function New-AgentTasksTask {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef,
        [Parameter(Mandatory)][string]$Runtime
    )
    if ([string]$Request.execution_mode -notin @('mutating', 'read_only')) {
        Throw-AgentTasksError -Code 'AT-EXECUTION-MODE' -ExitCode 2 -SafeMessage 'Task execution mode must be mutating or read_only.'
    }
    $workflowClass = Assert-AgentTasksWorkflowClass -Value $Request.workflow_class
    $lockedDecisions = @(ConvertTo-AgentTasksLockedDecisions -Value $Request.locked_decisions)
    $scope = ConvertTo-AgentTasksWriteScope -Scope @($Request.write_scope)
    $criteria = New-AgentTasksAcceptanceCriteria -Criteria @($Request.acceptance_criteria)
    $stateRoot = Initialize-AgentTasksStateRoot -Context $Context
    return Invoke-WithAgentTasksLock -StateRoot $stateRoot -Domain repository -Id 'authority' -Action {
        [void](Initialize-AgentTasksProjectUnlocked -Context $Context -DisplayName ([IO.Path]::GetFileName($Context.ProjectRoot)))
        $phaseId = if ($Request.Contains('phase_id')) { [string]$Request.phase_id } else { $null }
        if ($phaseId) {
            $phaseAuthority = Get-AgentTasksPhaseAuthority -StateRoot $stateRoot -PhaseId $phaseId
            if ([string]$phaseAuthority.Revision.status -cne 'active') {
                Throw-AgentTasksError -Code 'AT-PHASE-NOT-ACTIVE' -ExitCode 3 -SafeMessage 'A task can only be linked to an active phase.'
            }
        }

        $active = @(Get-AgentTasksActiveTaskAuthorities -StateRoot $stateRoot)
        $mutating = [string]$Request.execution_mode -ceq 'mutating'
        $worktreeRoot = [IO.Path]::GetFullPath($Context.WorktreeRoot).TrimEnd('\', '/')
        if ($mutating -and -not $Context.IsGit -and @($active | Where-Object { $_.Contract.execution_mode -ceq 'mutating' }).Count -gt 0) {
            Throw-AgentTasksError -Code 'AT-NON-GIT-MUTATOR' -ExitCode 3 -SafeMessage 'A non-Git authority permits only one active mutating task.'
        }
        if ($mutating) {
            foreach ($other in $active) {
                if ([string]$other.Contract.execution_mode -cne 'mutating') { continue }
                if ([string]$other.Revision.authoritative_worktree -and [string]$other.Revision.authoritative_worktree -ceq $worktreeRoot) {
                    Throw-AgentTasksError -Code 'AT-WORKTREE-CONFLICT' -ExitCode 3 -SafeMessage 'The authoritative worktree is already reserved.'
                }
                foreach ($left in $scope) {
                    foreach ($right in @($other.Contract.write_scope)) {
                        $relationship = Test-AgentTasksScopePair -Left $left -Right $right
                        if ($relationship -ceq 'conflict') {
                            Throw-AgentTasksError -Code 'AT-SCOPE-CONFLICT' -ExitCode 3 -SafeMessage 'The write scope overlaps another active mutating task.'
                        }
                        if ($relationship -ceq 'ambiguous' -and -not (Test-AgentTasksScopeOverride -Override $(if ($Request.Contains('scope_override')) { $Request.scope_override } else { $null }))) {
                            Throw-AgentTasksError -Code 'AT-SCOPE-AMBIGUOUS' -ExitCode 3 -SafeMessage 'The write-scope relationship is ambiguous and requires user authority.'
                        }
                    }
                }
            }
        }

        $tasksRoot = Join-Path $stateRoot 'tasks'
        $nextNumber = 1
        foreach ($namespace in @('tasks', 'trash')) {
            $namespaceRoot = Join-Path $stateRoot $namespace
            if (-not (Test-Path -LiteralPath $namespaceRoot -PathType Container)) { continue }
            foreach ($directory in Get-ChildItem -LiteralPath $namespaceRoot -Directory | Sort-Object Name) {
                if ($directory.Name -match '^T([0-9]{6})$') { $nextNumber = [Math]::Max($nextNumber, [int]$Matches[1] + 1) }
            }
        }
        $taskId = 'T{0:D6}' -f $nextNumber
        $taskRoot = Join-Path $tasksRoot $taskId
        $baseline = Get-AgentTasksWorkspaceSnapshot -WorkingDirectory $Context.WorktreeRoot -OwnedIgnoredOutputs @($Request.owned_ignored_outputs)
        $contract = [ordered]@{
            schema_version = 1; record_type = 'task_contract'; task_id = $taskId
            phase_id = $phaseId; objective = [string]$Request.objective; authority = @($Request.authority)
            acceptance_criteria = @($criteria); obligations = @($Request.obligations)
            execution_mode = [string]$Request.execution_mode; write_scope = @($scope)
            owned_ignored_outputs = @($Request.owned_ignored_outputs)
        }
        if ($Request.Contains('scope_override')) { $contract.scope_override = $Request.scope_override }
        [void](Publish-AgentTasksBundle -FinalDirectory $taskRoot -Builder {
            param($temporary)
            foreach ($directory in @('state', 'sessions', 'work-units', 'checkpoints', 'baselines', 'candidates', 'evidence', 'handoffs', 'artifacts', 'supporting')) {
                [void](New-Item -ItemType Directory -Path (Join-Path $temporary $directory))
            }
            [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $temporary 'contract.json') -Value $contract)
            [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $temporary 'baseline.json') -Value $baseline)
            [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $temporary ('sessions\{0}.json' -f (Get-AgentTasksSha256 -Value $SessionRef).Substring(0, 16))) -Value ([ordered]@{
                schema_version = 1; record_type = 'session_identity'; session_ref = $SessionRef
                runtime = $Runtime; created_at = Get-AgentTasksUtcTimestamp
            }))
            [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $temporary 'state\R000001.json') -Value ([ordered]@{
                schema_version = 1; record_type = 'task_state_revision'; task_id = $taskId
                revision = 1; revision_id = 'R000001'; previous_revision = $null
                previous_revision_sha256 = $null; status = 'active'; lease_generation = 1
                owner_session_ref = $SessionRef; owner_runtime = $Runtime; lease_status = 'active'
                authoritative_worktree = $(if ($mutating) { $worktreeRoot } else { $null })
                observation_worktree = $worktreeRoot; baseline_ref = 'baseline.json'; latest_checkpoint_id = $null
                workflow_class = $workflowClass; locked_decisions = @($lockedDecisions)
                work_unit_ids = @(); work_unit_outcome_ids = @(); supporting_refs = @(); handoff_ids = @()
                active_handoff_id = $null; invalidated_evidence_ids = @(); evidence_ids = @()
                selected_candidate_id = $null; selected_candidate_hash = $null
                created_at = Get-AgentTasksUtcTimestamp
            }))
        })

        if ($phaseId) {
            $phaseAuthority = Get-AgentTasksPhaseAuthority -StateRoot $stateRoot -PhaseId $phaseId
            $nextPhase = [ordered]@{}
            foreach ($key in $phaseAuthority.Revision.Keys) {
                if ([string]$key -cne 'record_hash') { $nextPhase[[string]$key] = $phaseAuthority.Revision[$key] }
            }
            $phaseRevision = [long]$phaseAuthority.Revision.revision + 1
            $nextPhase.revision = $phaseRevision
            $nextPhase.revision_id = 'R{0:D6}' -f $phaseRevision
            $nextPhase.previous_revision = [string]$phaseAuthority.Revision.revision_id
            $nextPhase.previous_revision_sha256 = [string]$phaseAuthority.RevisionSha256
            $nextPhase.linked_task_ids = @(@($phaseAuthority.Revision.linked_task_ids) + @($taskId) | Sort-Object -Unique)
            $nextPhase.created_at = Get-AgentTasksUtcTimestamp
            [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $phaseAuthority.Root ('state\R{0:D6}.json' -f $phaseRevision)) -Value $nextPhase)
        }
        return [ordered]@{
            task_id = $taskId; revision = 1; lease_generation = 1
            authoritative_worktree = $(if ($mutating) { $worktreeRoot } else { $null })
        }
    }
}

function Bind-AgentTasksWorktree {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )

    $taskId = [string]$Request.task_id
    $targetContext = Resolve-AgentTasksContext -WorkingDirectory ([string]$Request.worktree_root)
    if ([bool]$Context.IsGit -ne [bool]$targetContext.IsGit) {
        Throw-AgentTasksError -Code 'AT-WORKTREE-REPOSITORY' -ExitCode 3 -SafeMessage 'The target worktree does not belong to the task repository.'
    }
    if ($Context.IsGit -and [string]$Context.GitCommonDir -cne [string]$targetContext.GitCommonDir) {
        Throw-AgentTasksError -Code 'AT-WORKTREE-REPOSITORY' -ExitCode 3 -SafeMessage 'The target worktree does not share the task Git common directory.'
    }
    if (-not $Context.IsGit -and [string]$Context.ProjectRoot -cne [string]$targetContext.ProjectRoot) {
        Throw-AgentTasksError -Code 'AT-WORKTREE-REPOSITORY' -ExitCode 3 -SafeMessage 'A non-Git task cannot move to another project root.'
    }

    $targetRoot = [IO.Path]::GetFullPath($targetContext.WorktreeRoot).TrimEnd('\', '/')
    return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain repository -Id 'authority' -Action {
        $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $taskId
        if ([string]$authority.Contract.execution_mode -cne 'mutating') {
            Throw-AgentTasksError -Code 'AT-WORKTREE-READ-ONLY' -ExitCode 3 -SafeMessage 'A read-only task has no authoritative writer worktree to bind.'
        }
        Assert-AgentTasksTaskCas -Authority $authority -Request $Request -SessionRef $SessionRef
        foreach ($other in @(Get-AgentTasksActiveTaskAuthorities -StateRoot $Context.StateRoot)) {
            if ([string]$other.Contract.task_id -ceq $taskId -or [string]$other.Contract.execution_mode -cne 'mutating') { continue }
            if ([string]$other.Revision.authoritative_worktree -ceq $targetRoot) {
                Throw-AgentTasksError -Code 'AT-WORKTREE-CONFLICT' -ExitCode 3 -SafeMessage 'The target authoritative worktree is already reserved.'
            }
        }
        $snapshot = Get-AgentTasksWorkspaceSnapshot -WorkingDirectory $targetRoot -OwnedIgnoredOutputs @($authority.Contract.owned_ignored_outputs)
        $baselineFiles = @(Get-ChildItem -LiteralPath (Join-Path $authority.Root 'baselines') -File -Filter 'B*.json')
        $baselineId = 'B{0:D6}' -f ($baselineFiles.Count + 2)
        [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $authority.Root (Join-Path 'baselines' ($baselineId + '.json'))) -Value $snapshot)
        $mutation = Write-AgentTasksRevision -StateRoot $Context.StateRoot -TaskId $taskId `
            -ExpectedRevision ([long]$Request.expected_revision) -ExpectedRevisionSha256 ([string]$Request.expected_revision_sha256) `
            -ExpectedLeaseGeneration ([long]$Request.expected_lease_generation) -SessionRef $SessionRef -Mutator {
                param($next, $current)
                $next.authoritative_worktree = $targetRoot
                $next.observation_worktree = $targetRoot
                $next.baseline_ref = 'baselines/' + $baselineId + '.json'
            }
        return [ordered]@{
            task_id = $taskId; authoritative_worktree = $targetRoot
            revision = [long]$mutation.Revision.revision; revision_sha256 = [string]$mutation.RevisionSha256
            baseline_ref = [string]$mutation.Revision.baseline_ref
        }
    }
}

function Set-AgentTasksPhaseStatus {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request
    )
    $stateRoot = $Context.StateRoot
    return Invoke-WithAgentTasksLock -StateRoot $stateRoot -Domain repository -Id 'authority' -Action {
        $phaseId = [string]$Request.phase_id
        return Invoke-WithAgentTasksLock -StateRoot $stateRoot -Domain phase -Id $phaseId -Action {
            $authority = Get-AgentTasksPhaseAuthority -StateRoot $stateRoot -PhaseId $phaseId
            if ([long]$Request.expected_revision -ne [long]$authority.Revision.revision) {
                Throw-AgentTasksError -Code 'AT-CAS-REVISION' -ExitCode 3 -SafeMessage 'The expected phase revision is stale.'
            }
            if ([string]$Request.expected_revision_sha256 -cne [string]$authority.RevisionSha256) {
                Throw-AgentTasksError -Code 'AT-CAS-HASH' -ExitCode 3 -SafeMessage 'The expected phase revision hash is stale.'
            }
            $target = [string]$Request.target_status
            if ($target -notin @($script:PhaseTransitions[[string]$authority.Revision.status])) {
                Throw-AgentTasksError -Code 'AT-PHASE-TRANSITION' -ExitCode 3 -SafeMessage 'The requested phase transition is not allowed.'
            }
            if ($target -in @('accepted', 'cancelled', 'terminally_blocked')) {
                foreach ($taskId in @($authority.Revision.linked_task_ids)) {
                    $task = Get-AgentTasksTaskAuthority -StateRoot $stateRoot -TaskId ([string]$taskId)
                    if ([string]$task.Revision.status -notin @('accepted', 'cancelled', 'terminally_blocked')) {
                        Throw-AgentTasksError -Code 'AT-PHASE-LINKED-TASKS' -ExitCode 3 -SafeMessage 'The phase has nonterminal linked tasks.'
                    }
                }
            }
            $nextNumber = [long]$authority.Revision.revision + 1
            $next = [ordered]@{}
            foreach ($key in $authority.Revision.Keys) { if ([string]$key -cne 'record_hash') { $next[[string]$key] = $authority.Revision[$key] } }
            $next.revision = $nextNumber; $next.revision_id = 'R{0:D6}' -f $nextNumber
            $next.previous_revision = [string]$authority.Revision.revision_id
            $next.previous_revision_sha256 = [string]$authority.RevisionSha256
            $next.status = $target; $next.created_at = Get-AgentTasksUtcTimestamp
            $published = Publish-AgentTasksRecord -LiteralPath (Join-Path $authority.Root ('state\R{0:D6}.json' -f $nextNumber)) -Value $next
            return [ordered]@{ phase_id = $phaseId; status = $target; revision = $nextNumber; revision_sha256 = $published.Sha256 }
        }
    }
}

function Add-AgentTasksCheckpoint {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )
    $taskId = [string]$Request.task_id
    $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $taskId
    if ([string]$authority.Contract.execution_mode -ceq 'read_only' -and [string]$Request.kind -notin @('mandatory', 'best_effort')) {
        Throw-AgentTasksError -Code 'AT-CHECKPOINT-KIND' -ExitCode 2 -SafeMessage 'The checkpoint kind is unsupported.'
    }
    return Write-AgentTasksRevision -StateRoot $Context.StateRoot -TaskId $taskId `
        -ExpectedRevision ([long]$Request.expected_revision) -ExpectedRevisionSha256 ([string]$Request.expected_revision_sha256) `
        -ExpectedLeaseGeneration ([long]$Request.expected_lease_generation) -SessionRef $SessionRef -Mutator {
            param($next, $current)
            $existing = @(Get-ChildItem -LiteralPath (Join-Path $current.Root 'checkpoints') -File -Filter 'CP*.json')
            $checkpointId = 'CP{0:D6}' -f ($existing.Count + 1)
            $record = [ordered]@{
                schema_version = 1; record_type = 'checkpoint'; checkpoint_id = $checkpointId
                kind = [string]$Request.kind; next_action = [string]$Request.next_action
                blockers = @($Request.blockers); open_risks = @($Request.open_risks)
                work_unit_id = $(if ($Request.Contains('work_unit_id')) { [string]$Request.work_unit_id } else { $null })
                lineage_revision = [long]$current.Revision.revision
                worktree_binding = [string]$current.Revision.observation_worktree
                created_at = Get-AgentTasksUtcTimestamp
            }
            [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $current.Root (Join-Path 'checkpoints' ($checkpointId + '.json'))) -Value $record)
            $next.latest_checkpoint_id = $checkpointId
            $next.supporting_refs = @(@($next.supporting_refs) + @($checkpointId) | Sort-Object -Unique)
        }
}

function Claim-AgentTasksTask {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )
    $currentAuthority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId ([string]$Request.task_id)
    if (
        $currentAuthority.Revision.Contains('selected_candidate_id') -and
        -not [string]::IsNullOrWhiteSpace([string]$currentAuthority.Revision.selected_candidate_id) -and
        (Get-Command Test-AgentTasksCandidate -ErrorAction SilentlyContinue)
    ) {
        [void](Test-AgentTasksCandidate -Context $Context -TaskId ([string]$Request.task_id) -CandidateId ([string]$currentAuthority.Revision.selected_candidate_id))
    }
    $result = Write-AgentTasksRevision -StateRoot $Context.StateRoot -TaskId ([string]$Request.task_id) `
        -ExpectedRevision ([long]$Request.expected_revision) -ExpectedRevisionSha256 ([string]$Request.expected_revision_sha256) `
        -ExpectedLeaseGeneration ([long]$Request.expected_lease_generation) -SessionRef $SessionRef -Mutator {
            param($next, $current)
            $next.last_claimed_at = Get-AgentTasksUtcTimestamp
        }
    return [ordered]@{
        task_id = [string]$Request.task_id; revision = [long]$result.Revision.revision
        revision_sha256 = [string]$result.RevisionSha256; lease_generation = [long]$result.Revision.lease_generation
    }
}

function New-AgentTasksWorkUnit {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )
    Assert-AgentTasksIdentifier -Id ([string]$Request.work_unit_id) -Code 'AT-WORK-UNIT-ID'
    $taskId = [string]$Request.task_id
    return Write-AgentTasksRevision -StateRoot $Context.StateRoot -TaskId $taskId `
        -ExpectedRevision ([long]$Request.expected_revision) -ExpectedRevisionSha256 ([string]$Request.expected_revision_sha256) `
        -ExpectedLeaseGeneration ([long]$Request.expected_lease_generation) -SessionRef $SessionRef -Mutator {
            param($next, $current)
            $workUnitId = [string]$Request.work_unit_id
            $path = Join-Path $current.Root (Join-Path 'work-units' ($workUnitId + '.json'))
            if (Test-Path -LiteralPath $path) {
                Throw-AgentTasksError -Code 'AT-WORK-UNIT-EXISTS' -ExitCode 3 -SafeMessage 'The work-unit identifier already exists.'
            }
            [void](Publish-AgentTasksRecord -LiteralPath $path -Value ([ordered]@{
                schema_version = 1; record_type = 'work_unit_contract'; work_unit_id = $workUnitId
                inputs = @($Request.inputs); outputs = @($Request.outputs); ownership = @($Request.ownership)
                dependencies = @($Request.dependencies); completion_conditions = @($Request.completion_conditions)
            }))
            $next.work_unit_ids = @(@($next.work_unit_ids) + @($workUnitId) | Sort-Object -Unique)
        }
}

function Add-AgentTasksWorkUnitOutcome {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][string]$SessionRef
    )
    if ([string]$Request.status -notin @('completed', 'partial', 'blocked', 'failed')) {
        Throw-AgentTasksError -Code 'AT-WORK-UNIT-STATUS' -ExitCode 3 -SafeMessage 'A work-unit outcome cannot accept the parent task.'
    }
    $taskId = [string]$Request.task_id
    return Write-AgentTasksRevision -StateRoot $Context.StateRoot -TaskId $taskId `
        -ExpectedRevision ([long]$Request.expected_revision) -ExpectedRevisionSha256 ([string]$Request.expected_revision_sha256) `
        -ExpectedLeaseGeneration ([long]$Request.expected_lease_generation) -SessionRef $SessionRef -Mutator {
            param($next, $current)
            $workUnitId = [string]$Request.work_unit_id
            if (-not (Test-Path -LiteralPath (Join-Path $current.Root (Join-Path 'work-units' ($workUnitId + '.json'))))) {
                Throw-AgentTasksError -Code 'AT-WORK-UNIT-NOT-FOUND' -ExitCode 3 -SafeMessage 'The work-unit contract does not exist.'
            }
            $outcomes = @(Get-ChildItem -LiteralPath (Join-Path $current.Root 'work-units') -File -Filter ($workUnitId + '-O*.json'))
            $outcomeId = '{0}-O{1:D6}' -f $workUnitId, ($outcomes.Count + 1)
            [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $current.Root (Join-Path 'work-units' ($outcomeId + '.json'))) -Value ([ordered]@{
                schema_version = 1; record_type = 'work_unit_outcome'; outcome_id = $outcomeId
                work_unit_id = $workUnitId; status = [string]$Request.status
                artifact_refs = @($Request.artifact_refs); observed_summary = $Request.observed_summary
                provisional = $true; created_at = Get-AgentTasksUtcTimestamp
            }))
            $next.work_unit_outcome_ids = @(@($next.work_unit_outcome_ids) + @($outcomeId) | Sort-Object -Unique)
        }
}
