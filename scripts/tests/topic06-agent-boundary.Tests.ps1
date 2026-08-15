#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fixtureHelper = Join-Path $repositoryRoot 'scripts\lib\topic04-test-fixtures.ps1'
$installer = Join-Path $repositoryRoot 'scripts\install-template.ps1'
$uninstaller = Join-Path $repositoryRoot 'scripts\uninstall-template.ps1'
$e2eHelper = Join-Path $repositoryRoot 'scripts\tests\fixtures\topic06-boundary-e2e.mjs'
$commonPath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Common.ps1'
$storePath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Store.ps1'
$gitPath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Git.ps1'
$lifecyclePath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Lifecycle.ps1'

. $fixtureHelper
. $commonPath
. $storePath
. $gitPath
. $lifecyclePath

$script:Assertions = 0

function Assert-Topic06Boundary {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Get-Topic06BoundaryAuthority {
    param([Parameter(Mandatory)][object]$Context, [Parameter(Mandatory)][string]$TaskId)
    return Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $TaskId
}

function Invoke-Topic06BoundaryState {
    param(
        [Parameter(Mandatory)][string]$CliPath,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Operation,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [string]$SessionRef = 'codex:topic06-e2e'
    )
    return Invoke-Topic04CliObject -CliPath $CliPath -FixtureRoot $FixtureRoot `
        -WorkingDirectory $Repository -Operation $Operation -Request $Request -SessionRef $SessionRef
}

function New-Topic06BoundaryTask {
    param(
        [Parameter(Mandatory)][string]$CliPath,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Objective,
        [ValidateSet('mutating', 'read_only')][string]$ExecutionMode,
        [object[]]$WriteScope = @()
    )
    $result = Invoke-Topic06BoundaryState -CliPath $CliPath -FixtureRoot $FixtureRoot -Repository $Repository `
        -Operation 'create-task' -Request ([ordered]@{
            objective = $Objective
            authority = @('user-approved-topic-06')
            acceptance_criteria = @(
                [ordered]@{ id = 'AC-001'; text = 'The managed boundary is deterministic.'; mandatory = $true },
                [ordered]@{ id = 'AC-002'; text = 'The parent remains provisional.'; mandatory = $true }
            )
            obligations = @('Preserve unrelated user bytes.')
            execution_mode = $ExecutionMode
            write_scope = @($WriteScope)
            owned_ignored_outputs = @()
            workflow_class = 'standard'
            locked_decisions = @()
        })
    if ($result.ExitCode -ne 0) { throw "Could not create Topic 06 task: $($result.Stdout) $($result.Stderr)" }
    return [string]$result.Parsed.data.task_id
}

function Add-Topic06BoundaryWorkUnit {
    param(
        [Parameter(Mandatory)][string]$CliPath,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$TaskId,
        [Parameter(Mandatory)][string]$WorkUnitId,
        [string[]]$Inputs = @(),
        [string[]]$Outputs = @(),
        [string[]]$Ownership = @(),
        [string[]]$Dependencies = @(),
        [string[]]$CompletionConditions = @('Return one closed semantic result.')
    )
    $authority = Get-Topic06BoundaryAuthority -Context $Context -TaskId $TaskId
    $result = Invoke-Topic06BoundaryState -CliPath $CliPath -FixtureRoot $FixtureRoot -Repository $Repository `
        -Operation 'create-work-unit' -Request ([ordered]@{
            task_id = $TaskId
            work_unit_id = $WorkUnitId
            inputs = @($Inputs)
            outputs = @($Outputs)
            ownership = @($Ownership)
            dependencies = @($Dependencies)
            completion_conditions = @($CompletionConditions)
            expected_revision = [long]$authority.Revision.revision
            expected_revision_sha256 = [string]$authority.RevisionSha256
            expected_lease_generation = [long]$authority.Revision.lease_generation
        })
    if ($result.ExitCode -ne 0) { throw "Could not create work unit ${WorkUnitId}: $($result.Stdout) $($result.Stderr)" }
}

function Add-Topic06BoundaryOutcome {
    param(
        [Parameter(Mandatory)][string]$CliPath,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$TaskId,
        [Parameter(Mandatory)][string]$WorkUnitId,
        [Parameter(Mandatory)][string[]]$ArtifactRefs,
        [Parameter(Mandatory)][Collections.IDictionary]$ObservedSummary
    )
    $authority = Get-Topic06BoundaryAuthority -Context $Context -TaskId $TaskId
    $result = Invoke-Topic06BoundaryState -CliPath $CliPath -FixtureRoot $FixtureRoot -Repository $Repository `
        -Operation 'record-work-unit-outcome' -Request ([ordered]@{
            task_id = $TaskId
            work_unit_id = $WorkUnitId
            status = 'completed'
            artifact_refs = @($ArtifactRefs)
            observed_summary = $ObservedSummary
            expected_revision = [long]$authority.Revision.revision
            expected_revision_sha256 = [string]$authority.RevisionSha256
            expected_lease_generation = [long]$authority.Revision.lease_generation
        })
    if ($result.ExitCode -ne 0) { throw "Could not record work-unit outcome: $($result.Stdout) $($result.Stderr)" }
}

function Close-Topic06BoundaryTask {
    param(
        [Parameter(Mandatory)][string]$CliPath,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$TaskId
    )
    $authority = Get-Topic06BoundaryAuthority -Context $Context -TaskId $TaskId
    $result = Invoke-Topic06BoundaryState -CliPath $CliPath -FixtureRoot $FixtureRoot -Repository $Repository `
        -Operation 'close' -Request ([ordered]@{
            task_id = $TaskId
            terminal_status = 'cancelled'
            reason = 'Disposable Topic 06 fixture complete.'
            expected_revision = [long]$authority.Revision.revision
            expected_revision_sha256 = [string]$authority.RevisionSha256
            expected_lease_generation = [long]$authority.Revision.lease_generation
        })
    if ($result.ExitCode -ne 0) { throw "Could not close Topic 06 fixture task: $($result.Stdout) $($result.Stderr)" }
}

function Invoke-Topic06BoundaryHelper {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$WrapperPath,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][Collections.IDictionary]$Semantics,
        [string]$SessionRef = 'codex:topic06-e2e'
    )
    $inputPath = Join-Path $FixtureRoot ('topic06-e2e-{0}.json' -f [guid]::NewGuid().ToString('N'))
    Set-Topic04Utf8File -LiteralPath $inputPath -Content (([ordered]@{
        schema_version = 1
        wrapper_path = [IO.Path]::GetFullPath($WrapperPath)
        project_directory = [IO.Path]::GetFullPath($Repository)
        session_ref = $SessionRef
        request = $Request
        semantics = $Semantics
    }) | ConvertTo-Json -Depth 64 -Compress)
    $output = @(& node $e2eHelper $inputPath 2>&1)
    $exitCode = $LASTEXITCODE
    $line = @($output | ForEach-Object { [string]$_ } | Where-Object { $_.StartsWith('{', [StringComparison]::Ordinal) })[-1]
    $parsed = if ($line) { $line | ConvertFrom-Json -Depth 64 } else { $null }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = $output -join [Environment]::NewLine
        Parsed = $parsed
    }
}

function New-Topic06ScoutSemantic {
    return [ordered]@{
        status = 'completed'
        summary = 'The bounded producer and consumer were found.'
        capability = 'native'
        source_fitness_reason = 'Current repository source is sufficient.'
        fallback_path = @()
        claims = @([ordered]@{
            claim = 'The managed boundary is installed in the project.'
            sources = @([ordered]@{ path = 'src/review.txt'; line_start = 1; line_end = 1 })
        })
        gaps = @()
        searches_performed = @([ordered]@{ method = 'grep'; query = 'candidate'; outcome = 'Found the fixture.' })
        recommended_next_action = 'Inspect the bounded consumer.'
    }
}

function New-Topic06WorkerSemantic {
    param([Parameter(Mandatory)][string]$Artifact, [string]$Summary = 'The bounded output was produced and checked.')
    return [ordered]@{
        status = 'completed'
        summary = $Summary
        artifact_refs = @($Artifact)
        verification_observations = @([ordered]@{
            command_id = 'topic06-fixture-check'
            status = 'passed'
            observation = 'The deterministic fixture check passed.'
        })
        covered_ac_ids = @('AC-001', 'AC-002')
        blockers = @()
        remaining_risks = @()
    }
}

function New-Topic06ReviewerSemantic {
    return [ordered]@{
        decision = 'APPROVED'
        summary = 'The frozen fixture preserves the selected boundary.'
        findings = @()
        cleared_concerns = @([ordered]@{
            concern = 'Reviewer independence'
            evidence = 'The packet binds the contract and frozen artifact directly.'
        })
        recommended_action = 'ACCEPT'
    }
}

try {
    $tempBefore = @(Get-ChildItem -LiteralPath ([IO.Path]::GetTempPath()) -Directory `
        -Filter 'agent-tasks-topic06-*' -ErrorAction SilentlyContinue | ForEach-Object FullName)
    $fixture = New-Topic04FixtureRoot -Label 'topic06-boundary'
    $repository = Initialize-Topic04GitFixture -Root $fixture
    foreach ($relative in @('src/worker.txt', 'src/review.txt', 'src/batch-a.txt', 'src/batch-b.txt')) {
        Set-Topic04Utf8File -LiteralPath (Join-Path $repository $relative) -Content "baseline`n"
    }
    & git -C $repository add src
    & git -C $repository commit --quiet -m 'Topic 06 boundary baseline'
    if ($LASTEXITCODE -ne 0) { throw 'Could not commit Topic 06 boundary baseline.' }

    $installOutput = @(& pwsh -NoProfile -File $installer -Target project -ProjectDir $repository `
        -Components 'agents,workflows,skills,state,agents-md,rules-md,config,agent-boundary' '-DryRun:$false' 2>&1)
    Assert-Topic06Boundary ($LASTEXITCODE -eq 0) "Disposable boundary installation failed: $($installOutput -join ' ')"
    $targetOmp = Join-Path $repository '.omp'
    $stateCli = Join-Path $targetOmp 'state\agent-tasks.ps1'
    $wrapper = Join-Path $targetOmp 'extensions\agent-task-boundary.js'
    $installRecord = Get-Content -Raw -LiteralPath (Join-Path $targetOmp 'contracts\install-record.json') | ConvertFrom-Json
    $context = Resolve-AgentTasksContext -WorkingDirectory $repository
    $packetHashes = [Collections.Generic.List[string]]::new()

    $scoutTask = New-Topic06BoundaryTask -CliPath $stateCli -FixtureRoot $fixture -Repository $repository `
        -Objective 'Map the bounded candidate source.' -ExecutionMode read_only
    Add-Topic06BoundaryWorkUnit -CliPath $stateCli -FixtureRoot $fixture -Repository $repository -Context $context `
        -TaskId $scoutTask -WorkUnitId 'WU-SCOUT-001' -Inputs @('src/review.txt') `
        -CompletionConditions @('Return one cited current-source claim.')
    $scoutRequest = [ordered]@{
        task_id = $scoutTask; work_unit_id = 'WU-SCOUT-001'; agent = 'cheap-scout'; role = 'cheap_scout'
    }
    $scoutSemantics = [ordered]@{ 'WU-SCOUT-001' = New-Topic06ScoutSemantic }
    $scoutFirst = Invoke-Topic06BoundaryHelper -FixtureRoot $fixture -WrapperPath $wrapper -Repository $repository `
        -Request $scoutRequest -Semantics $scoutSemantics
    Assert-Topic06Boundary (
        $scoutFirst.ExitCode -eq 0 -and $scoutFirst.Parsed.result.isError -eq $false -and
        $scoutFirst.Parsed.native_call_count -eq 1 -and $scoutFirst.Parsed.result.details.receipts[0].outcome.recorded -eq $true
    ) "Scout round trip failed: $($scoutFirst.Output)"
    $scoutSecond = Invoke-Topic06BoundaryHelper -FixtureRoot $fixture -WrapperPath $wrapper -Repository $repository `
        -Request $scoutRequest -Semantics $scoutSemantics
    Assert-Topic06Boundary (
        $scoutSecond.ExitCode -eq 0 -and
        $scoutSecond.Parsed.dispatched[0].packet_sha256 -ceq $scoutFirst.Parsed.dispatched[0].packet_sha256
    ) 'Repeated Scout projection did not produce deterministic packet bytes.'
    [void]$packetHashes.Add([string]$scoutFirst.Parsed.dispatched[0].packet_sha256)
    $scoutAuthority = Get-Topic06BoundaryAuthority -Context $context -TaskId $scoutTask
    Assert-Topic06Boundary (
        $scoutAuthority.Revision.status -ceq 'active' -and @($scoutAuthority.Revision.work_unit_outcome_ids).Count -eq 2
    ) 'Scout receipts changed the parent task status or failed to record provisional outcomes.'

    $workerTask = New-Topic06BoundaryTask -CliPath $stateCli -FixtureRoot $fixture -Repository $repository `
        -Objective 'Produce the bounded Worker artifact.' -ExecutionMode mutating `
        -WriteScope @([ordered]@{ kind = 'exact'; path = 'src/worker.txt' })
    Add-Topic06BoundaryWorkUnit -CliPath $stateCli -FixtureRoot $fixture -Repository $repository -Context $context `
        -TaskId $workerTask -WorkUnitId 'WU-WORKER-001' -Inputs @('src/worker.txt') -Outputs @('src/worker.txt') `
        -Ownership @('src/worker.txt') -CompletionConditions @('Run topic06-fixture-check.')
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/worker.txt') -Content "worker candidate`n"
    $workerRequest = [ordered]@{
        task_id = $workerTask; work_unit_id = 'WU-WORKER-001'; agent = 'worker'; role = 'worker'
        effort = 'high'; isolated = $false
    }
    $worker = Invoke-Topic06BoundaryHelper -FixtureRoot $fixture -WrapperPath $wrapper -Repository $repository `
        -Request $workerRequest -Semantics ([ordered]@{ 'WU-WORKER-001' = New-Topic06WorkerSemantic 'src/worker.txt' })
    Assert-Topic06Boundary (
        $worker.ExitCode -eq 0 -and $worker.Parsed.result.isError -eq $false -and
        $worker.Parsed.result.details.receipts[0].role -ceq 'worker' -and
        $worker.Parsed.result.details.receipts[0].outcome.recorded -eq $true
    ) "Worker round trip failed: $($worker.Output)"
    [void]$packetHashes.Add([string]$worker.Parsed.dispatched[0].packet_sha256)
    $workerAuthority = Get-Topic06BoundaryAuthority -Context $context -TaskId $workerTask
    Assert-Topic06Boundary ($workerAuthority.Revision.status -ceq 'active') `
        'A completed Worker receipt accepted or closed the parent task.'
    Close-Topic06BoundaryTask -CliPath $stateCli -FixtureRoot $fixture -Repository $repository -Context $context -TaskId $workerTask

    $reviewTask = New-Topic06BoundaryTask -CliPath $stateCli -FixtureRoot $fixture -Repository $repository `
        -Objective 'Review the frozen bounded candidate.' -ExecutionMode mutating `
        -WriteScope @([ordered]@{ kind = 'exact'; path = 'src/review.txt' })
    Add-Topic06BoundaryWorkUnit -CliPath $stateCli -FixtureRoot $fixture -Repository $repository -Context $context `
        -TaskId $reviewTask -WorkUnitId 'WU-REVIEW-SEED' -Inputs @('src/review.txt') -Outputs @('src/review.txt') `
        -Ownership @('src/review.txt') -CompletionConditions @('Produce the candidate artifact.')
    Add-Topic06BoundaryWorkUnit -CliPath $stateCli -FixtureRoot $fixture -Repository $repository -Context $context `
        -TaskId $reviewTask -WorkUnitId 'WU-REVIEW-001' -Inputs @('src/review.txt') `
        -CompletionConditions @('Check reviewer independence.')
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/review.txt') -Content "review candidate`n"
    $sentinel = 'WORKER_CLAIM_SENTINEL_MUST_NOT_REACH_REVIEWER'
    Add-Topic06BoundaryOutcome -CliPath $stateCli -FixtureRoot $fixture -Repository $repository -Context $context `
        -TaskId $reviewTask -WorkUnitId 'WU-REVIEW-SEED' -ArtifactRefs @('src/review.txt') `
        -ObservedSummary ([ordered]@{ role = 'worker'; status = 'completed'; summary = $sentinel })
    $reviewAuthority = Get-Topic06BoundaryAuthority -Context $context -TaskId $reviewTask
    $freeze = Invoke-Topic06BoundaryState -CliPath $stateCli -FixtureRoot $fixture -Repository $repository `
        -Operation 'freeze' -Request ([ordered]@{
            task_id = $reviewTask
            acceptance_inputs = @()
            scope_dispositions = @()
            expected_revision = [long]$reviewAuthority.Revision.revision
            expected_revision_sha256 = [string]$reviewAuthority.RevisionSha256
            expected_lease_generation = [long]$reviewAuthority.Revision.lease_generation
        })
    Assert-Topic06Boundary ($freeze.ExitCode -eq 0 -and $freeze.Parsed.data.status -ceq 'candidate_frozen') `
        "Reviewer candidate did not freeze: $($freeze.Stdout) $($freeze.Stderr)"
    $reviewRequest = [ordered]@{
        task_id = $reviewTask; work_unit_id = 'WU-REVIEW-001'; agent = 'reviewer'; role = 'reviewer'
    }
    $review = Invoke-Topic06BoundaryHelper -FixtureRoot $fixture -WrapperPath $wrapper -Repository $repository `
        -Request $reviewRequest -Semantics ([ordered]@{ 'WU-REVIEW-001' = New-Topic06ReviewerSemantic })
    $reviewPacket = [string]$review.Parsed.dispatched[0].task
    Assert-Topic06Boundary (
        $review.ExitCode -eq 0 -and $review.Parsed.result.isError -eq $false -and
        -not $reviewPacket.Contains($sentinel, [StringComparison]::Ordinal) -and
        $reviewPacket.Contains('selected_frozen_candidate', [StringComparison]::Ordinal) -and
        $reviewPacket.Contains('selected_candidate_diff', [StringComparison]::Ordinal) -and
        $reviewPacket.Contains('src/review.txt', [StringComparison]::Ordinal) -and
        $reviewPacket.Contains('AC-001', [StringComparison]::Ordinal)
    ) 'Reviewer packet did not bind ARTIFACT + CONTRACT independently of the Worker claim.'
    [void]$packetHashes.Add([string]$review.Parsed.dispatched[0].packet_sha256)
    $reviewAfter = Get-Topic06BoundaryAuthority -Context $context -TaskId $reviewTask
    Assert-Topic06Boundary ($reviewAfter.Revision.status -ceq 'candidate_frozen') `
        'Reviewer receipt accepted or closed the frozen parent task.'
    Close-Topic06BoundaryTask -CliPath $stateCli -FixtureRoot $fixture -Repository $repository -Context $context -TaskId $reviewTask

    $batchTask = New-Topic06BoundaryTask -CliPath $stateCli -FixtureRoot $fixture -Repository $repository `
        -Objective 'Produce two independent bounded Worker artifacts.' -ExecutionMode mutating `
        -WriteScope @(
            [ordered]@{ kind = 'exact'; path = 'src/batch-a.txt' },
            [ordered]@{ kind = 'exact'; path = 'src/batch-b.txt' }
        )
    foreach ($entry in @(
        [ordered]@{ Id = 'WU-BATCH-A'; Path = 'src/batch-a.txt' },
        [ordered]@{ Id = 'WU-BATCH-B'; Path = 'src/batch-b.txt' }
    )) {
        Add-Topic06BoundaryWorkUnit -CliPath $stateCli -FixtureRoot $fixture -Repository $repository -Context $context `
            -TaskId $batchTask -WorkUnitId $entry.Id -Inputs @($entry.Path) -Outputs @($entry.Path) `
            -Ownership @($entry.Path) -CompletionConditions @('Run topic06-fixture-check.')
        Set-Topic04Utf8File -LiteralPath (Join-Path $repository $entry.Path) -Content "batch candidate $($entry.Id)`n"
    }
    $batchRequest = [ordered]@{ tasks = @(
        [ordered]@{
            task_id = $batchTask; work_unit_id = 'WU-BATCH-A'; agent = 'worker'; role = 'worker'
            effort = 'high'; isolated = $false
        },
        [ordered]@{
            task_id = $batchTask; work_unit_id = 'WU-BATCH-B'; agent = 'worker'; role = 'worker'
            effort = 'xhigh'; isolated = $false
        }
    ) }
    $batch = Invoke-Topic06BoundaryHelper -FixtureRoot $fixture -WrapperPath $wrapper -Repository $repository `
        -Request $batchRequest -Semantics ([ordered]@{
            'WU-BATCH-A' = New-Topic06WorkerSemantic 'src/batch-a.txt'
            'WU-BATCH-B' = New-Topic06WorkerSemantic 'src/batch-b.txt'
        })
    Assert-Topic06Boundary (
        $batch.ExitCode -eq 0 -and $batch.Parsed.native_call_count -eq 1 -and
        @($batch.Parsed.result.details.receipts).Count -eq 2 -and
        @($batch.Parsed.result.details.receipts | Where-Object { $_.outcome.recorded -eq $true }).Count -eq 2
    ) "Managed batch did not cross one all-or-none native barrier: $($batch.Output)"
    foreach ($row in @($batch.Parsed.dispatched)) { [void]$packetHashes.Add([string]$row.packet_sha256) }
    $batchAuthority = Get-Topic06BoundaryAuthority -Context $context -TaskId $batchTask
    Assert-Topic06Boundary (
        $batchAuthority.Revision.status -ceq 'active' -and @($batchAuthority.Revision.work_unit_outcome_ids).Count -eq 2
    ) 'Batch receipts changed parent acceptance or failed ordered provisional outcome recording.'
    Assert-Topic06Boundary (-not $batch.Output.Contains('native prose must stay private', [StringComparison]::Ordinal)) `
        'Raw native prose leaked through the managed receipt.'
    Close-Topic06BoundaryTask -CliPath $stateCli -FixtureRoot $fixture -Repository $repository -Context $context -TaskId $batchTask

    $stateBeforeUninstall = Get-Topic04TreeFingerprint -LiteralPath $context.StateRoot
    $uninstallOutput = @(& pwsh -NoProfile -File $uninstaller -Target project -ProjectDir $repository `
        -BackupDir ([string]$installRecord.backup_dir) '-DryRun:$false' 2>&1)
    Assert-Topic06Boundary ($LASTEXITCODE -eq 0) "Boundary uninstall failed: $($uninstallOutput -join ' ')"
    Assert-Topic06Boundary (
        -not (Test-Path -LiteralPath $wrapper -PathType Leaf) -and
        -not (Test-Path -LiteralPath (Join-Path $targetOmp 'bin\omp-managed.ps1') -PathType Leaf) -and
        (Get-Topic04TreeFingerprint -LiteralPath $context.StateRoot) -ceq $stateBeforeUninstall
    ) 'Removing the managed component changed Topic 04 authority or left a false managed entrypoint.'
    $unavailable = Invoke-Topic06BoundaryHelper -FixtureRoot $fixture -WrapperPath $wrapper -Repository $repository `
        -Request $scoutRequest -Semantics $scoutSemantics
    Assert-Topic06Boundary (
        $unavailable.ExitCode -ne 0 -and $unavailable.Parsed.ok -eq $false -and
        (Get-Topic04TreeFingerprint -LiteralPath $context.StateRoot) -ceq $stateBeforeUninstall
    ) 'Unavailable managed dispatch fabricated a packet, receipt, native call, or authority mutation instead of leaving inline work.'

    $locks = @(Get-ChildItem -LiteralPath (Join-Path $context.StateRoot 'locks') -File -Filter '*.lock' -ErrorAction SilentlyContinue)
    Assert-Topic06Boundary ($locks.Count -eq 0) 'Topic 06 left an authority lock behind.'
    $tempAfter = @(Get-ChildItem -LiteralPath ([IO.Path]::GetTempPath()) -Directory `
        -Filter 'agent-tasks-topic06-*' -ErrorAction SilentlyContinue | ForEach-Object FullName)
    $newTemp = @($tempAfter | Where-Object { $tempBefore -cnotcontains $_ })
    Assert-Topic06Boundary ($newTemp.Count -eq 0) 'Topic 06 left a state-adapter temp directory behind.'

    $deterministicHash = Get-AgentTasksSha256 -Value @($packetHashes)
    Write-Host "PASS: Topic 06 agent boundary ($script:Assertions assertions; packet-set=$deterministicHash)." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Remove-Topic04FixtureRoots
}
