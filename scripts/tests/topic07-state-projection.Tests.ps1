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
$candidatePath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Candidate.ps1'
$evidencePath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Evidence.ps1'
$projectionPath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Projection.ps1'
$cliPath = Join-Path $repositoryRoot 'template\.omp\state\agent-tasks.ps1'
$corePath = Join-Path $repositoryRoot 'template\.omp\contracts\context-continuity-core.mjs'

. $fixtureHelper
. $commonPath
. $storePath
. $gitPath
. $lifecyclePath
. $candidatePath
. $evidencePath
. $projectionPath

$script:Assertions = 0

function Assert-Topic07Projection {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Assert-Topic07ProjectionFailure {
    param([Parameter(Mandatory)][object]$Result, [Parameter(Mandatory)][string]$Code, [Parameter(Mandatory)][string]$Scenario)
    $script:Assertions++
    if ($Result.ExitCode -eq 0 -or $Result.Parsed.code -cne $Code) {
        throw "[$Scenario] expected $Code, got exit=$($Result.ExitCode) code=$($Result.Parsed.code)."
    }
}

function Initialize-Topic07ProjectionRepository {
    param([Parameter(Mandatory)][string]$Label)
    $fixture = New-Topic04FixtureRoot -Label $Label
    $repository = Initialize-Topic04GitFixture -Root $fixture
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "baseline`n"
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'config/input.json') -Content "{`"version`":1}`n"
    & git -C $repository add .
    & git -C $repository commit --quiet -m 'continuity projection baseline'
    if ($LASTEXITCODE -ne 0) { throw 'Could not commit the continuity projection fixture.' }
    return [pscustomobject]@{ Fixture = $fixture; Repository = $repository; Context = Resolve-AgentTasksContext -WorkingDirectory $repository }
}

function New-Topic07ProjectionTask {
    param(
        [Parameter(Mandatory)][object]$Fixture,
        [string]$Owner = 'omp:topic07-owner',
        [string]$Runtime = 'omp',
        [ValidateSet('quick', 'standard', 'orchestrated')][string]$WorkflowClass = 'standard',
        [ValidateSet('mutating', 'read_only')][string]$ExecutionMode = 'read_only',
        [string]$Objective = 'Preserve exact continuity without private history.'
    )
    $request = [ordered]@{
        objective = $Objective
        authority = @('user-approved-topic-07')
        acceptance_criteria = @([ordered]@{ id = 'AC-001'; text = 'The continuity kernel is exact.'; mandatory = $true })
        obligations = @('Run deterministic verification.')
        execution_mode = $ExecutionMode
        write_scope = @()
        owned_ignored_outputs = @()
        workflow_class = $WorkflowClass
        locked_decisions = @([ordered]@{
            decision_id = 'D-001'; statement = 'Use the approved managed continuity path.'; authority_ref = 'user:2026-08-13'
        })
    }
    if ($ExecutionMode -ceq 'mutating') { $request.write_scope = @([ordered]@{ kind = 'subtree'; path = 'src' }) }
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $Fixture.Fixture -WorkingDirectory $Fixture.Repository `
        -Operation 'create-task' -SessionRef $Owner -Runtime $Runtime -Request $request
}

function Invoke-Topic07Project {
    param(
        [Parameter(Mandatory)][object]$Fixture,
        [string]$SessionRef = 'omp:topic07-owner',
        [string]$Runtime = 'omp',
        [Collections.IDictionary]$Request = ([ordered]@{})
    )
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $Fixture.Fixture -WorkingDirectory $Fixture.Repository `
        -Operation 'project-continuity' -SessionRef $SessionRef -Runtime $Runtime -Request $Request
}

function Get-Topic07ProjectionAuthority {
    param([Parameter(Mandatory)][object]$Fixture, [Parameter(Mandatory)][string]$TaskId)
    return Get-AgentTasksTaskAuthority -StateRoot $Fixture.Context.StateRoot -TaskId $TaskId
}

function Set-Topic07LatestRevision {
    param([Parameter(Mandatory)][object]$Authority, [Parameter(Mandatory)][scriptblock]$Mutator)
    $path = Join-Path $Authority.Root ('state\R{0:D6}.json' -f [long]$Authority.Revision.revision)
    $record = Read-AgentTasksJsonFile -LiteralPath $path
    [void]$record.Remove('record_hash')
    & $Mutator $record
    $record.record_hash = Get-AgentTasksSha256 -Value $record
    Set-Topic04Utf8File -LiteralPath $path -Content ((ConvertTo-AgentTasksCanonicalJson -Value $record) + "`n")
}

function Test-Topic07KernelWithNode {
    param([Parameter(Mandatory)][object]$Fixture, [Parameter(Mandatory)][object]$Kernel)
    $jsonPath = Join-Path $Fixture.Fixture ('kernel-{0}.json' -f [guid]::NewGuid().ToString('N'))
    Set-Topic04Utf8File -LiteralPath $jsonPath -Content ((ConvertTo-AgentTasksCanonicalJson -Value $Kernel) + "`n")
    $program = @'
import fs from "node:fs";
import { pathToFileURL } from "node:url";
const core = await import(pathToFileURL(process.argv[1]).href);
const value = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const result = core.buildContinuityKernel(value);
process.stdout.write(JSON.stringify(result.ok ? {
  ok: true,
  sha256: result.sha256,
  utf8_bytes: result.utf8_bytes,
  canonical: result.canonical,
} : result));
'@
    $output = & node --input-type=module -e $program $corePath $jsonPath
    if ($LASTEXITCODE -ne 0) { throw 'The JavaScript continuity validator failed to execute.' }
    return ($output -join "`n") | ConvertFrom-Json -Depth 64
}

try {
    $empty = Initialize-Topic07ProjectionRepository -Label 'topic07-projection-empty'
    $noTask = Invoke-Topic07Project -Fixture $empty
    Assert-Topic07ProjectionFailure -Result $noTask -Code 'AT-CONTINUITY-TASK-NOT-FOUND' -Scenario 'zero owned active tasks'

    $main = Initialize-Topic07ProjectionRepository -Label 'topic07-projection-main'
    $create = New-Topic07ProjectionTask -Fixture $main -ExecutionMode 'mutating'
    Assert-Topic07Projection ($create.ExitCode -eq 0) 'The main continuity task must be created.'
    $taskId = [string]$create.Parsed.data.task_id
    $authority = Get-Topic07ProjectionAuthority -Fixture $main -TaskId $taskId

    $callerSelection = Invoke-Topic07Project -Fixture $main -Request ([ordered]@{ task_id = $taskId })
    Assert-Topic07ProjectionFailure -Result $callerSelection -Code 'AT-SCHEMA-UNKNOWN-PROPERTY' -Scenario 'caller cannot select a task'
    $otherSession = Invoke-Topic07Project -Fixture $main -SessionRef 'omp:other-session'
    Assert-Topic07ProjectionFailure -Result $otherSession -Code 'AT-CONTINUITY-TASK-NOT-FOUND' -Scenario 'another session cannot project this task'
    $wrongRuntime = Invoke-Topic07Project -Fixture $main -Runtime 'codex'
    Assert-Topic07ProjectionFailure -Result $wrongRuntime -Code 'AT-CONTINUITY-TASK-NOT-FOUND' -Scenario 'wrong runtime cannot project this task'

    $initial = Invoke-Topic07Project -Fixture $main
    Assert-Topic07Projection ($initial.ExitCode -eq 0) 'A classified exact-session task with explicit empty secondary state must project.'
    $initialAgain = Invoke-Topic07Project -Fixture $main
    Assert-Topic07Projection ((ConvertTo-AgentTasksCanonicalJson -Value $initial.Parsed.data) -ceq (ConvertTo-AgentTasksCanonicalJson -Value $initialAgain.Parsed.data)) 'Repeated projection must be byte-stable.'
    Assert-Topic07Projection ($initial.Parsed.data.degraded_fields.Count -eq 0) 'Explicit null and empty secondary fields are not degradation.'
    $initialNode = Test-Topic07KernelWithNode -Fixture $main -Kernel $initial.Parsed.data
    Assert-Topic07Projection ($initialNode.ok -and $initialNode.sha256 -ceq $initial.Parsed.data.kernel_sha256) 'The JavaScript core must accept the PowerShell projection and reproduce its hash.'

    $workUnit = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $main.Fixture -WorkingDirectory $main.Repository `
        -Operation 'create-work-unit' -SessionRef 'omp:topic07-owner' -Runtime 'omp' -Request ([ordered]@{
            task_id = $taskId; work_unit_id = 'WU-CURRENT'; inputs = @('task contract'); outputs = @('src/output.txt')
            ownership = @('src/output.txt'); dependencies = @(); completion_conditions = @('candidate frozen')
            expected_revision = $authority.Revision.revision; expected_revision_sha256 = $authority.RevisionSha256
            expected_lease_generation = $authority.Revision.lease_generation
        })
    Assert-Topic07Projection ($workUnit.ExitCode -eq 0) 'The projected current work unit must be created.'
    $authority = Get-Topic07ProjectionAuthority -Fixture $main -TaskId $taskId
    $checkpoint = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $main.Fixture -WorkingDirectory $main.Repository `
        -Operation 'checkpoint' -SessionRef 'omp:topic07-owner' -Runtime 'omp' -Request ([ordered]@{
            task_id = $taskId; kind = 'mandatory'; work_unit_id = 'WU-CURRENT'; next_action = 'Verify the selected candidate.'
            blockers = @('Await deterministic evidence.'); open_risks = @('Candidate bytes may drift.')
            expected_revision = $authority.Revision.revision; expected_revision_sha256 = $authority.RevisionSha256
            expected_lease_generation = $authority.Revision.lease_generation
        })
    Assert-Topic07Projection ($checkpoint.ExitCode -eq 0) 'The continuity checkpoint must be created.'
    $authority = Get-Topic07ProjectionAuthority -Fixture $main -TaskId $taskId

    Set-Topic04Utf8File -LiteralPath (Join-Path $main.Repository 'src/output.txt') -Content "candidate`n"
    $freeze = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $main.Fixture -WorkingDirectory $main.Repository `
        -Operation 'freeze' -SessionRef 'omp:topic07-owner' -Runtime 'omp' -Request ([ordered]@{
            task_id = $taskId; acceptance_inputs = @([ordered]@{ path = 'config/input.json'; role = 'contract_input' }); scope_dispositions = @()
            expected_revision = $authority.Revision.revision; expected_revision_sha256 = $authority.RevisionSha256
            expected_lease_generation = $authority.Revision.lease_generation
        })
    Assert-Topic07Projection ($freeze.ExitCode -eq 0 -and $freeze.Parsed.data.candidate_id -ceq 'C1') 'The selected candidate must be frozen.'
    $authority = Get-Topic07ProjectionAuthority -Fixture $main -TaskId $taskId
    $candidate = Read-AgentTasksJsonFile -LiteralPath (Join-Path $authority.Root 'candidates\C1.json')
    $inputHashes = @($candidate.acceptance_inputs | ForEach-Object { [ordered]@{ path = [string]$_.path; sha256 = [string]$_.sha256 } })
    $evidence = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $main.Fixture -WorkingDirectory $main.Repository `
        -Operation 'record-evidence' -SessionRef 'omp:topic07-owner' -Runtime 'omp' -Request ([ordered]@{
            task_id = $taskId; evidence_type = 'test'; producer = 'deterministic_runner'; candidate_id = 'C1'
            covered_ac_ids = @('AC-001'); observation = [ordered]@{ status = 'PASS'; total = 1; failed = 0 }
            validity_triggers = @([ordered]@{ kind = 'candidate_drift' }, [ordered]@{ kind = 'acceptance_input_drift' })
            acceptance_input_hashes = $inputHashes
            expected_revision = $authority.Revision.revision; expected_revision_sha256 = $authority.RevisionSha256
            expected_lease_generation = $authority.Revision.lease_generation
        })
    Assert-Topic07Projection ($evidence.ExitCode -eq 0 -and $evidence.Parsed.data.evidence_id -ceq 'E000001') 'A deterministic evidence binding must be recorded.'

    $rich = Invoke-Topic07Project -Fixture $main
    Assert-Topic07Projection ($rich.ExitCode -eq 0) 'The checkpoint/candidate/evidence-rich task must project.'
    Assert-Topic07Projection ($rich.Parsed.data.checkpoint.checkpoint_id -ceq 'CP000001' -and $rich.Parsed.data.checkpoint.work_unit_id -ceq 'WU-CURRENT') 'The kernel must bind the latest valid checkpoint and work unit.'
    Assert-Topic07Projection ($rich.Parsed.data.candidate.candidate_id -ceq 'C1' -and $rich.Parsed.data.candidate.candidate_hash -ceq $rich.Parsed.data.candidate.candidate_sha256) 'The selected and validated candidate hashes must agree.'
    Assert-Topic07Projection ($rich.Parsed.data.evidence_bindings.Count -eq 1 -and $rich.Parsed.data.evidence_bindings[0].evidence_id -ceq 'E000001') 'The kernel must expose only stable evidence identity and hash.'
    $richJson = ConvertTo-AgentTasksCanonicalJson -Value $rich.Parsed.data
    foreach ($forbidden in @([IO.Path]::GetFullPath($main.Repository), 'observation', 'terminal output', 'transcript', 'reasoning', 'providerpayload', '"status":"PASS"')) {
        Assert-Topic07Projection (-not $richJson.Contains($forbidden, [StringComparison]::OrdinalIgnoreCase)) "The projection must not expose private or raw authority content: $forbidden"
    }
    $richNode = Test-Topic07KernelWithNode -Fixture $main -Kernel $rich.Parsed.data
    Assert-Topic07Projection ($richNode.ok -and $richNode.sha256 -ceq $rich.Parsed.data.kernel_sha256 -and $richNode.utf8_bytes -le 16384) 'The rich projection must match the portable core byte-for-byte.'

    $checkpointPath = Join-Path $authority.Root 'checkpoints\CP000001.json'
    $checkpointBytes = [IO.File]::ReadAllText($checkpointPath)
    Set-Topic04Utf8File -LiteralPath $checkpointPath -Content ($checkpointBytes.Replace('Verify the selected candidate.', 'Corrupt checkpoint content.'))
    $corruptCheckpoint = Invoke-Topic07Project -Fixture $main
    Assert-Topic07ProjectionFailure -Result $corruptCheckpoint -Code 'AT-CONTINUITY-CORRUPT' -Scenario 'corrupt referenced checkpoint'
    Set-Topic04Utf8File -LiteralPath $checkpointPath -Content $checkpointBytes

    $evidencePathValue = Join-Path $authority.Root 'evidence\E000001.json'
    $evidenceBytes = [IO.File]::ReadAllText($evidencePathValue)
    Set-Topic04Utf8File -LiteralPath $evidencePathValue -Content ($evidenceBytes.Replace('"total":1', '"total":2'))
    $corruptEvidence = Invoke-Topic07Project -Fixture $main
    Assert-Topic07ProjectionFailure -Result $corruptEvidence -Code 'AT-CONTINUITY-CORRUPT' -Scenario 'corrupt referenced evidence'
    Set-Topic04Utf8File -LiteralPath $evidencePathValue -Content $evidenceBytes

    Set-Topic04Utf8File -LiteralPath (Join-Path $main.Repository 'src/output.txt') -Content "drifted`n"
    $drift = Invoke-Topic07Project -Fixture $main
    Assert-Topic07ProjectionFailure -Result $drift -Code 'AT-CANDIDATE-DRIFT' -Scenario 'candidate workspace drift'

    $multiple = Initialize-Topic07ProjectionRepository -Label 'topic07-projection-multiple'
    [void](New-Topic07ProjectionTask -Fixture $multiple -Owner 'omp:shared')
    [void](New-Topic07ProjectionTask -Fixture $multiple -Owner 'omp:shared')
    $ambiguous = Invoke-Topic07Project -Fixture $multiple -SessionRef 'omp:shared'
    Assert-Topic07ProjectionFailure -Result $ambiguous -Code 'AT-CONTINUITY-TASK-AMBIGUOUS' -Scenario 'multiple owned active tasks'

    $quickLegacy = Initialize-Topic07ProjectionRepository -Label 'topic07-projection-quick-legacy'
    $quickCreate = New-Topic07ProjectionTask -Fixture $quickLegacy -WorkflowClass 'quick'
    $quickAuthority = Get-Topic07ProjectionAuthority -Fixture $quickLegacy -TaskId ([string]$quickCreate.Parsed.data.task_id)
    Set-Topic07LatestRevision -Authority $quickAuthority -Mutator {
        param($record)
        foreach ($key in @('latest_checkpoint_id', 'selected_candidate_id', 'selected_candidate_hash', 'evidence_ids')) { [void]$record.Remove($key) }
    }
    $quickProjection = Invoke-Topic07Project -Fixture $quickLegacy
    Assert-Topic07Projection ($quickProjection.ExitCode -eq 0) 'Quick may project a classified legacy task with only named secondary degradation.'
    Assert-Topic07Projection ((@($quickProjection.Parsed.data.degraded_fields) -join ',') -ceq 'blockers,candidate,checkpoint,evidence_bindings,next_action,open_risks,work_unit_id') 'Quick degradation must name every and only unavailable secondary field.'
    Assert-Topic07Projection ((Test-Topic07KernelWithNode -Fixture $quickLegacy -Kernel $quickProjection.Parsed.data).ok) 'The portable core must accept named Quick degradation.'

    $standardLegacy = Initialize-Topic07ProjectionRepository -Label 'topic07-projection-standard-legacy'
    $standardCreate = New-Topic07ProjectionTask -Fixture $standardLegacy
    $standardAuthority = Get-Topic07ProjectionAuthority -Fixture $standardLegacy -TaskId ([string]$standardCreate.Parsed.data.task_id)
    Set-Topic07LatestRevision -Authority $standardAuthority -Mutator {
        param($record)
        foreach ($key in @('latest_checkpoint_id', 'selected_candidate_id', 'selected_candidate_hash', 'evidence_ids')) { [void]$record.Remove($key) }
    }
    $standardProjection = Invoke-Topic07Project -Fixture $standardLegacy
    Assert-Topic07ProjectionFailure -Result $standardProjection -Code 'AT-CONTINUITY-DEGRADED' -Scenario 'Standard refuses missing secondary pointers'

    $unclassified = Initialize-Topic07ProjectionRepository -Label 'topic07-projection-unclassified'
    $unclassifiedCreate = New-Topic07ProjectionTask -Fixture $unclassified -WorkflowClass 'quick'
    $unclassifiedAuthority = Get-Topic07ProjectionAuthority -Fixture $unclassified -TaskId ([string]$unclassifiedCreate.Parsed.data.task_id)
    Set-Topic07LatestRevision -Authority $unclassifiedAuthority -Mutator {
        param($record)
        [void]$record.Remove('workflow_class'); [void]$record.Remove('locked_decisions')
    }
    $unclassifiedProjection = Invoke-Topic07Project -Fixture $unclassified
    Assert-Topic07ProjectionFailure -Result $unclassifiedProjection -Code 'AT-CONTINUITY-UNCLASSIFIED' -Scenario 'unclassified legacy task'

    $inactive = Initialize-Topic07ProjectionRepository -Label 'topic07-projection-inactive'
    $inactiveCreate = New-Topic07ProjectionTask -Fixture $inactive
    $inactiveAuthority = Get-Topic07ProjectionAuthority -Fixture $inactive -TaskId ([string]$inactiveCreate.Parsed.data.task_id)
    Set-Topic07LatestRevision -Authority $inactiveAuthority -Mutator { param($record) $record.status = 'transferring'; $record.lease_status = 'transferring' }
    $inactiveProjection = Invoke-Topic07Project -Fixture $inactive
    Assert-Topic07ProjectionFailure -Result $inactiveProjection -Code 'AT-CONTINUITY-INACTIVE' -Scenario 'transferring task'

    $corrupt = Initialize-Topic07ProjectionRepository -Label 'topic07-projection-corrupt'
    $corruptCreate = New-Topic07ProjectionTask -Fixture $corrupt
    $corruptAuthority = Get-Topic07ProjectionAuthority -Fixture $corrupt -TaskId ([string]$corruptCreate.Parsed.data.task_id)
    $corruptRevisionPath = Join-Path $corruptAuthority.Root 'state\R000001.json'
    $corruptText = [IO.File]::ReadAllText($corruptRevisionPath).Replace('"status":"active"', '"status":"rework"')
    Set-Topic04Utf8File -LiteralPath $corruptRevisionPath -Content $corruptText
    $corruptProjection = Invoke-Topic07Project -Fixture $corrupt
    Assert-Topic07ProjectionFailure -Result $corruptProjection -Code 'AT-CONTINUITY-CORRUPT' -Scenario 'corrupt owned revision chain'

    $large = Initialize-Topic07ProjectionRepository -Label 'topic07-projection-large'
    [void](New-Topic07ProjectionTask -Fixture $large -Objective ('x' * 17000))
    $tooLarge = Invoke-Topic07Project -Fixture $large
    Assert-Topic07ProjectionFailure -Result $tooLarge -Code 'AT-CONTINUITY-TOO-LARGE' -Scenario 'kernel exceeds 16 KiB'

    Write-Host ("PASS Topic 07 state continuity projection ({0} assertions)" -f $script:Assertions) -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("FAIL [AT-TEST-TOPIC07-PROJECTION] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    Remove-Topic04FixtureRoots
}
