#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fixtureHelper = Join-Path $repositoryRoot 'scripts\lib\topic04-test-fixtures.ps1'
$commonPath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Common.ps1'
$storePath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Store.ps1'
$gitPath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Git.ps1'
$lifecyclePath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Lifecycle.ps1'
$cliPath = Join-Path $repositoryRoot 'template\.omp\state\agent-tasks.ps1'

if (
    -not (Test-Path -LiteralPath $fixtureHelper -PathType Leaf) -or
    -not (Test-Path -LiteralPath $gitPath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $lifecyclePath -PathType Leaf)
) {
    Write-Host 'FAIL [AT-TEST-LIFECYCLE-MISSING] Topic 04 lifecycle core is not installed.' -ForegroundColor Red
    exit 1
}

. $fixtureHelper
. $commonPath
. $storePath
. $gitPath
. $lifecyclePath

$script:Assertions = 0

function Assert-Topic04Lifecycle {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Assert-Topic04CliFailure {
    param(
        [Parameter(Mandatory)][object]$Result,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Scenario
    )
    $script:Assertions++
    if ($Result.ExitCode -eq 0 -or $Result.Parsed.code -cne $Code) {
        throw "[$Scenario] expected $Code, got exit=$($Result.ExitCode) code=$($Result.Parsed.code)."
    }
}

function Get-Topic04TaskAuthority {
    param([Parameter(Mandatory)][string]$StateRoot, [Parameter(Mandatory)][string]$TaskId)
    $taskRoot = Join-Path $StateRoot (Join-Path 'tasks' $TaskId)
    $chain = Get-AgentTasksRevisionChain -StateDirectory (Join-Path $taskRoot 'state')
    if ($chain.Status -cne 'valid') { throw "Task $TaskId has an invalid revision chain." }
    $revisionPath = Join-Path $taskRoot ('state\R{0:D6}.json' -f [long]$chain.Records[-1].revision)
    return [pscustomobject]@{
        Root = $taskRoot
        Contract = Read-AgentTasksJsonFile -LiteralPath (Join-Path $taskRoot 'contract.json')
        Revision = $chain.Records[-1]
        RevisionSha256 = Get-AgentTasksSha256 -LiteralPath $revisionPath
    }
}

function New-Topic04TaskRequest {
    param(
        [string]$Objective,
        [string]$ExecutionMode = 'mutating',
        [object[]]$WriteScope = @(),
        [AllowNull()][string]$PhaseId = $null,
        [AllowNull()][object]$ScopeOverride = $null
    )
    $request = [ordered]@{
        objective = $Objective
        authority = @('user')
        acceptance_criteria = @(
            [ordered]@{ text = 'The requested behavior works.'; mandatory = $true },
            [ordered]@{ id = 'AC-CUSTOM'; text = 'No unrelated bytes change.'; mandatory = $false }
        )
        obligations = @('verification')
        execution_mode = $ExecutionMode
        write_scope = @($WriteScope)
        owned_ignored_outputs = @()
        workflow_class = 'standard'
        locked_decisions = @()
    }
    if ($null -ne $PhaseId) { $request.phase_id = $PhaseId }
    if ($null -ne $ScopeOverride) { $request.scope_override = $ScopeOverride }
    return $request
}

try {
    $fixtureRoot = New-Topic04FixtureRoot -Label 'lifecycle-git'
    $repository = Initialize-Topic04GitFixture -Root $fixtureRoot
    $linkedOne = Add-Topic04LinkedWorktree -Repository $repository -Root $fixtureRoot
    $linkedTwo = Join-Path $fixtureRoot 'linked-worktree-two'
    $branchTwo = 'topic04-linked-two-{0}' -f [guid]::NewGuid().ToString('N')
    & git -C $repository worktree add --quiet -b $branchTwo $linkedTwo
    if ($LASTEXITCODE -ne 0) { throw 'Failed to create second lifecycle worktree.' }

    $init = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'init-project' -Request ([ordered]@{ display_name = 'Lifecycle Fixture' })
    Assert-Topic04Lifecycle ($init.ExitCode -eq 0) 'Lifecycle fixture initialization must succeed.'
    $context = Resolve-AgentTasksContext -WorkingDirectory $repository
    $stateRoot = $context.StateRoot

    $phase = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'create-phase' -Request ([ordered]@{
        phase_id = 'P1'
        objective = 'Deliver lifecycle behavior.'
        authority = @('user')
        dependencies = @()
        exit_obligations = @('all linked tasks terminal')
    })
    Assert-Topic04Lifecycle ($phase.ExitCode -eq 0 -and $phase.Parsed.data.phase_id -ceq 'P1') 'create-phase must publish P1.'
    Assert-Topic04Lifecycle (Test-Path -LiteralPath (Join-Path $stateRoot 'phases\P1\contract.json')) 'Phase contract must be immutable and separate from state.'
    Assert-Topic04Lifecycle (Test-Path -LiteralPath (Join-Path $stateRoot 'phases\P1\state\R000001.json')) 'Phase R000001 must exist.'
    $duplicatePhase = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'create-phase' -Request ([ordered]@{
        phase_id = 'P1'; objective = 'duplicate'; authority = @('user'); dependencies = @(); exit_obligations = @()
    })
    Assert-Topic04CliFailure -Result $duplicatePhase -Code 'AT-PHASE-EXISTS' -Scenario 'duplicate phase ID'

    $plannedPhase = Get-AgentTasksPhaseAuthority -StateRoot $stateRoot -PhaseId 'P1'
    $activatePhase = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'transition-phase' -Request ([ordered]@{
        phase_id = 'P1'; target_status = 'active'; expected_revision = $plannedPhase.Revision.revision
        expected_revision_sha256 = $plannedPhase.RevisionSha256
    })
    Assert-Topic04Lifecycle ($activatePhase.ExitCode -eq 0 -and $activatePhase.Parsed.data.status -ceq 'active') 'Phase must enter active through CAS before accepting linked work.'

    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'preexisting-untracked.txt') -Content "user bytes`n"
    Add-Content -LiteralPath (Join-Path $repository 'README.md') -Value 'pre-existing dirty line'
    $beforeTaskSource = Get-Topic04WorktreeFingerprint -LiteralPath $repository
    $taskOne = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'create-task' -Request (
        New-Topic04TaskRequest -Objective 'Mutating main task.' -PhaseId 'P1' -WriteScope @(
            [ordered]@{ kind = 'subtree'; path = 'src/main' }
        )
    )
    Assert-Topic04Lifecycle ($taskOne.ExitCode -eq 0 -and $taskOne.Parsed.data.task_id -ceq 'T000001') 'First task must allocate T000001.'
    $afterTaskSource = Get-Topic04WorktreeFingerprint -LiteralPath $repository
    Assert-Topic04Lifecycle ($beforeTaskSource -ceq $afterTaskSource) 'Task authority must publish before and without source mutation.'
    $t1 = Get-Topic04TaskAuthority -StateRoot $stateRoot -TaskId 'T000001'
    Assert-Topic04Lifecycle ($t1.Contract.acceptance_criteria.Count -eq 2) 'Task contract must retain every AC.'
    Assert-Topic04Lifecycle ($t1.Contract.acceptance_criteria[0].id -ceq 'AC-001' -and $t1.Contract.acceptance_criteria[0].mandatory) 'Missing AC IDs must be assigned stably with mandatory flags.'
    Assert-Topic04Lifecycle ($t1.Contract.acceptance_criteria[1].id -ceq 'AC-CUSTOM' -and -not $t1.Contract.acceptance_criteria[1].mandatory) 'Explicit unique AC IDs and flags must be preserved.'
    $baseline = Read-AgentTasksJsonFile -LiteralPath (Join-Path $t1.Root 'baseline.json')
    $baselinePaths = @($baseline.entries | ForEach-Object path)
    Assert-Topic04Lifecycle ($baselinePaths -contains 'README.md') 'Baseline must identify pre-existing dirty tracked bytes.'
    Assert-Topic04Lifecycle ($baselinePaths -contains 'preexisting-untracked.txt') 'Baseline must identify pre-existing untracked bytes.'
    Assert-Topic04Lifecycle ($t1.Revision.authoritative_worktree -ceq [IO.Path]::GetFullPath($repository).TrimEnd('\', '/')) 'Mutating task must reserve its authoritative worktree.'
    Assert-Topic04Lifecycle ($t1.Revision.lease_generation -eq 1 -and $t1.Revision.owner_session_ref -ceq 'codex:test-session') 'Task bootstrap must create the first writer lease.'

    $readOnly = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'create-task' -Request (
        New-Topic04TaskRequest -Objective 'Read-only diagnosis.' -ExecutionMode 'read_only'
    ) -SessionRef 'codex:reader'
    Assert-Topic04Lifecycle ($readOnly.ExitCode -eq 0 -and $readOnly.Parsed.data.task_id -ceq 'T000002') "Read-only task may share an observation worktree (exit=$($readOnly.ExitCode), code=$($readOnly.Parsed.code))."
    $t2 = Get-Topic04TaskAuthority -StateRoot $stateRoot -TaskId 'T000002'
    Assert-Topic04Lifecycle ($null -eq $t2.Revision.authoritative_worktree -and $t2.Revision.observation_worktree) 'Read-only task must reserve no writer worktree.'

    $sameWorktree = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'create-task' -Request (
        New-Topic04TaskRequest -Objective 'Illegal same-worktree writer.' -WriteScope @([ordered]@{ kind = 'subtree'; path = 'docs/other' })
    ) -SessionRef 'codex:other-writer'
    Assert-Topic04CliFailure -Result $sameWorktree -Code 'AT-WORKTREE-CONFLICT' -Scenario 'same authoritative worktree reservation'

    $scopeConflict = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $linkedOne -Operation 'create-task' -Request (
        New-Topic04TaskRequest -Objective 'Illegal overlapping scope.' -WriteScope @([ordered]@{ kind = 'exact'; path = 'src/main/index.ts' })
    ) -SessionRef 'codex:scope-conflict'
    Assert-Topic04CliFailure -Result $scopeConflict -Code 'AT-SCOPE-CONFLICT' -Scenario 'exact and subtree scope overlap'

    $disjoint = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $linkedOne -Operation 'create-task' -Request (
        New-Topic04TaskRequest -Objective 'Disjoint linked writer.' -WriteScope @([ordered]@{ kind = 'subtree'; path = 'docs/feature' })
    ) -SessionRef 'codex:linked-writer'
    Assert-Topic04Lifecycle ($disjoint.ExitCode -eq 0 -and $disjoint.Parsed.data.task_id -ceq 'T000003') 'Disjoint scopes in separate worktrees must succeed.'

    $globAmbiguous = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $linkedTwo -Operation 'create-task' -Request (
        New-Topic04TaskRequest -Objective 'Ambiguous glob writer.' -WriteScope @([ordered]@{ kind = 'glob'; pattern = '**/*.md' })
    ) -SessionRef 'codex:glob-writer'
    Assert-Topic04CliFailure -Result $globAmbiguous -Code 'AT-SCOPE-AMBIGUOUS' -Scenario 'unresolved glob overlap'

    $override = [ordered]@{
        confirmed = $true
        authority = 'user'
        paths = @('README.md', 'docs/feature')
        reason = 'The work is intentionally ordered.'
        order = @('T000003', 'new-task')
    }
    $globOverride = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $linkedTwo -Operation 'create-task' -Request (
        New-Topic04TaskRequest -Objective 'Authorized glob writer.' -WriteScope @([ordered]@{ kind = 'glob'; pattern = 'notes/**/*.md' }) -ScopeOverride $override
    ) -SessionRef 'codex:glob-override'
    Assert-Topic04Lifecycle ($globOverride.ExitCode -eq 0) 'Explicit user scope override must record ambiguity disposition.'
    $t4 = Get-Topic04TaskAuthority -StateRoot $stateRoot -TaskId ([string]$globOverride.Parsed.data.task_id)
    Assert-Topic04Lifecycle ($t4.Contract.scope_override.authority -ceq 'user') 'Scope override authority must be stored in the immutable contract.'

    $phaseAuthority = Get-AgentTasksPhaseAuthority -StateRoot $stateRoot -PhaseId 'P1'
    $phaseExit = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'transition-phase' -Request ([ordered]@{
        phase_id = 'P1'
        target_status = 'accepted'
        expected_revision = $phaseAuthority.Revision.revision
        expected_revision_sha256 = $phaseAuthority.RevisionSha256
    })
    Assert-Topic04CliFailure -Result $phaseExit -Code 'AT-PHASE-LINKED-TASKS' -Scenario 'phase exit with nonterminal linked task'

    $wrongRevision = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'checkpoint' -Request ([ordered]@{
        task_id = 'T000001'; kind = 'mandatory'; next_action = 'continue'; blockers = @(); open_risks = @()
        expected_revision = 99; expected_revision_sha256 = ('A' * 64); expected_lease_generation = 1
    })
    Assert-Topic04CliFailure -Result $wrongRevision -Code 'AT-CAS-REVISION' -Scenario 'wrong task revision'

    $wrongHash = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'checkpoint' -Request ([ordered]@{
        task_id = 'T000001'; kind = 'mandatory'; next_action = 'continue'; blockers = @(); open_risks = @()
        expected_revision = $t1.Revision.revision; expected_revision_sha256 = ('A' * 64); expected_lease_generation = 1
    })
    Assert-Topic04CliFailure -Result $wrongHash -Code 'AT-CAS-HASH' -Scenario 'wrong task revision hash'

    $wrongGeneration = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'checkpoint' -Request ([ordered]@{
        task_id = 'T000001'; kind = 'mandatory'; next_action = 'continue'; blockers = @(); open_risks = @()
        expected_revision = $t1.Revision.revision; expected_revision_sha256 = $t1.RevisionSha256; expected_lease_generation = 2
    })
    Assert-Topic04CliFailure -Result $wrongGeneration -Code 'AT-CAS-LEASE' -Scenario 'wrong lease generation'

    $wrongSession = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'checkpoint' -Request ([ordered]@{
        task_id = 'T000001'; kind = 'mandatory'; next_action = 'continue'; blockers = @(); open_risks = @()
        expected_revision = $t1.Revision.revision; expected_revision_sha256 = $t1.RevisionSha256; expected_lease_generation = 1
    }) -SessionRef 'codex:not-owner'
    Assert-Topic04CliFailure -Result $wrongSession -Code 'AT-SESSION-OWNER' -Scenario 'wrong owning session'

    $checkpoint = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'checkpoint' -Request ([ordered]@{
        task_id = 'T000001'; kind = 'mandatory'; next_action = 'implement candidate'; blockers = @(); open_risks = @('candidate not frozen')
        expected_revision = $t1.Revision.revision; expected_revision_sha256 = $t1.RevisionSha256; expected_lease_generation = 1
    })
    Assert-Topic04Lifecycle ($checkpoint.ExitCode -eq 0 -and $checkpoint.Parsed.data.revision -eq 2) "Owning session must publish a mandatory checkpoint revision (exit=$($checkpoint.ExitCode), code=$($checkpoint.Parsed.code), data=$($checkpoint.Stdout))."
    $t1AfterCheckpoint = Get-Topic04TaskAuthority -StateRoot $stateRoot -TaskId 'T000001'
    Assert-Topic04Lifecycle ($t1AfterCheckpoint.Revision.latest_checkpoint_id -ceq 'CP000001') 'Latest checkpoint authority must live in the task revision.'

    Start-Sleep -Milliseconds 25
    $claim = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'claim' -Request ([ordered]@{
        task_id = 'T000001'; expected_revision = $t1AfterCheckpoint.Revision.revision
        expected_revision_sha256 = $t1AfterCheckpoint.RevisionSha256; expected_lease_generation = 1
    })
    Assert-Topic04Lifecycle ($claim.ExitCode -eq 0 -and $claim.Parsed.data.lease_generation -eq 1) 'Elapsed time must not expire or increment the writer lease.'
    $t1AfterClaim = Get-Topic04TaskAuthority -StateRoot $stateRoot -TaskId 'T000001'
    $foreignClaim = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'claim' -Request ([ordered]@{
        task_id = 'T000001'; expected_revision = $t1AfterClaim.Revision.revision
        expected_revision_sha256 = $t1AfterClaim.RevisionSha256; expected_lease_generation = 1
    }) -SessionRef 'codex:new-session'
    Assert-Topic04CliFailure -Result $foreignClaim -Code 'AT-SESSION-OWNER' -Scenario 'claim cannot transfer ownership'

    $workUnit = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'create-work-unit' -Request ([ordered]@{
        task_id = 'T000001'; work_unit_id = 'WU-1'; inputs = @('contract'); outputs = @('patch')
        ownership = @('src/main'); dependencies = @(); completion_conditions = @('tests pass')
        expected_revision = $t1AfterClaim.Revision.revision; expected_revision_sha256 = $t1AfterClaim.RevisionSha256; expected_lease_generation = 1
    })
    Assert-Topic04Lifecycle ($workUnit.ExitCode -eq 0) 'Owner must be able to create a bounded work unit.'
    $t1AfterWorkUnit = Get-Topic04TaskAuthority -StateRoot $stateRoot -TaskId 'T000001'
    $illegalOutcome = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'record-work-unit-outcome' -Request ([ordered]@{
        task_id = 'T000001'; work_unit_id = 'WU-1'; status = 'accepted'; artifact_refs = @(); observed_summary = [ordered]@{ result = 'done' }
        expected_revision = $t1AfterWorkUnit.Revision.revision; expected_revision_sha256 = $t1AfterWorkUnit.RevisionSha256; expected_lease_generation = 1
    })
    Assert-Topic04CliFailure -Result $illegalOutcome -Code 'AT-WORK-UNIT-STATUS' -Scenario 'work unit cannot accept parent task'
    $outcome = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixtureRoot -WorkingDirectory $repository -Operation 'record-work-unit-outcome' -Request ([ordered]@{
        task_id = 'T000001'; work_unit_id = 'WU-1'; status = 'completed'; artifact_refs = @(); observed_summary = [ordered]@{ result = 'ready for integration' }
        expected_revision = $t1AfterWorkUnit.Revision.revision; expected_revision_sha256 = $t1AfterWorkUnit.RevisionSha256; expected_lease_generation = 1
    })
    Assert-Topic04Lifecycle ($outcome.ExitCode -eq 0) 'Owner must record a provisional completed work-unit outcome.'

    $contractPath = Join-Path $t1.Root 'contract.json'
    $contractValue = Read-AgentTasksJsonFile -LiteralPath $contractPath
    $immutableCaught = $false
    try { [void](Publish-AgentTasksRecord -LiteralPath $contractPath -Value $contractValue) } catch {
        $immutableCaught = [string]$_.Exception.Data['AgentTasksCode'] -ceq 'AT-STORE-IMMUTABLE'
    }
    Assert-Topic04Lifecycle $immutableCaught 'A material task contract cannot be rewritten.'

    $bindFixture = New-Topic04FixtureRoot -Label 'lifecycle-bind'
    $bindRepository = Initialize-Topic04GitFixture -Root $bindFixture
    $bindLinked = Add-Topic04LinkedWorktree -Repository $bindRepository -Root $bindFixture
    $bindTask = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $bindFixture -WorkingDirectory $bindRepository -Operation 'create-task' -Request (
        New-Topic04TaskRequest -Objective 'Rebind before mutation.' -WriteScope @([ordered]@{ kind = 'subtree'; path = 'src/rebind' })
    ) -SessionRef 'codex:bind-owner'
    Assert-Topic04Lifecycle ($bindTask.ExitCode -eq 0) 'Binding fixture task must be created.'
    $bindContext = Resolve-AgentTasksContext -WorkingDirectory $bindRepository
    $bindAuthority = Get-Topic04TaskAuthority -StateRoot $bindContext.StateRoot -TaskId ([string]$bindTask.Parsed.data.task_id)
    $bind = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $bindFixture -WorkingDirectory $bindRepository -Operation 'bind-worktree' -Request ([ordered]@{
        task_id = [string]$bindTask.Parsed.data.task_id; worktree_root = [IO.Path]::GetFullPath($bindLinked)
        expected_revision = $bindAuthority.Revision.revision; expected_revision_sha256 = $bindAuthority.RevisionSha256
        expected_lease_generation = $bindAuthority.Revision.lease_generation
    }) -SessionRef 'codex:bind-owner'
    Assert-Topic04Lifecycle ($bind.ExitCode -eq 0 -and $bind.Parsed.data.authoritative_worktree -ceq [IO.Path]::GetFullPath($bindLinked).TrimEnd('\', '/')) 'Owner must rebind to an unreserved worktree in the same Git common directory.'

    $nonGit = New-Topic04FixtureRoot -Label 'lifecycle-non-git'
    $nonGitFirst = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $nonGit -WorkingDirectory $nonGit -Operation 'create-task' -Request (
        New-Topic04TaskRequest -Objective 'Non-Git writer.' -WriteScope @([ordered]@{ kind = 'subtree'; path = 'src' })
    ) -SessionRef 'codex:non-git-owner'
    Assert-Topic04Lifecycle ($nonGitFirst.ExitCode -eq 0) 'create-task must auto-initialize a missing non-Git project authority.'
    $nonGitSecond = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $nonGit -WorkingDirectory $nonGit -Operation 'create-task' -Request (
        New-Topic04TaskRequest -Objective 'Second non-Git writer.' -WriteScope @([ordered]@{ kind = 'subtree'; path = 'docs' })
    ) -SessionRef 'codex:non-git-second'
    Assert-Topic04CliFailure -Result $nonGitSecond -Code 'AT-NON-GIT-MUTATOR' -Scenario 'only one non-Git mutating task'
    foreach ($index in 1..2) {
        $reader = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $nonGit -WorkingDirectory $nonGit -Operation 'create-task' -Request (
            New-Topic04TaskRequest -Objective "Non-Git reader $index." -ExecutionMode 'read_only'
        ) -SessionRef "codex:non-git-reader-$index"
        Assert-Topic04Lifecycle ($reader.ExitCode -eq 0) 'Several non-Git read-only tasks must be permitted.'
    }

    Write-Host ("PASS Topic 04 state lifecycle ({0} assertions)" -f $script:Assertions) -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("FAIL [AT-TEST-LIFECYCLE] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    Remove-Topic04FixtureRoots
}
