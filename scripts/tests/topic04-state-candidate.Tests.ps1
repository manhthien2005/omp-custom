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
$cliPath = Join-Path $repositoryRoot 'template\.omp\state\agent-tasks.ps1'

if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
    Write-Host 'FAIL [AT-TEST-CANDIDATE-MISSING] Topic 04 candidate core is not installed.' -ForegroundColor Red
    exit 1
}

. $fixtureHelper
. $commonPath
. $storePath
. $gitPath
. $lifecyclePath
. $candidatePath

$script:Assertions = 0

function Assert-Topic04Candidate {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Assert-Topic04CandidateFailure {
    param(
        [Parameter(Mandatory)][object]$Result,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Scenario
    )
    $script:Assertions++
    if ($Result.ExitCode -eq 0 -or $Result.Parsed.code -cne $Code) {
        throw "[$Scenario] expected $Code, got exit=$($Result.ExitCode), code=$($Result.Parsed.code)."
    }
}

function Invoke-Topic04GitChecked {
    param(
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string[]]$Arguments
    )
    $output = @(& git -C $WorkingDirectory @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Git failed in candidate fixture: git $($Arguments -join ' '): $($output -join ' ')"
    }
    return ($output -join "`n").Trim()
}

function New-Topic04CandidateTaskPayload {
    param(
        [Parameter(Mandatory)][string]$Objective,
        [Parameter(Mandatory)][object[]]$WriteScope,
        [string[]]$OwnedIgnoredOutputs = @()
    )
    return [ordered]@{
        objective = $Objective
        authority = @('user')
        acceptance_criteria = @(
            [ordered]@{ id = 'AC-001'; text = 'Candidate bytes match the accepted scope.'; mandatory = $true }
        )
        obligations = @('verification')
        execution_mode = 'mutating'
        write_scope = @($WriteScope)
        owned_ignored_outputs = @($OwnedIgnoredOutputs)
        workflow_class = 'standard'
        locked_decisions = @()
    }
}

function New-Topic04FreezePayload {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][object[]]$AcceptanceInputs,
        [object[]]$ScopeDispositions = @()
    )
    return [ordered]@{
        task_id = [string]$Authority.Contract.task_id
        acceptance_inputs = @($AcceptanceInputs)
        scope_dispositions = @($ScopeDispositions)
        expected_revision = [long]$Authority.Revision.revision
        expected_revision_sha256 = [string]$Authority.RevisionSha256
        expected_lease_generation = [long]$Authority.Revision.lease_generation
    }
}

function Get-Topic04CandidateRecord {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$CandidateId
    )
    return Read-AgentTasksJsonFile -LiteralPath (Join-Path $Authority.Root (Join-Path 'candidates' ($CandidateId + '.json')))
}

try {
    $fixture = New-Topic04FixtureRoot -Label 'candidate-main'
    $repository = Initialize-Topic04GitFixture -Root $fixture
    [void](Invoke-Topic04GitChecked -WorkingDirectory $repository -Arguments @('config', 'core.filemode', 'true'))

    foreach ($entry in ([ordered]@{
        'src/owned.txt' = "owned baseline`n"
        'src/preexisting.txt' = "preexisting baseline`n"
        'src/preexisting-untracked.txt' = $null
        'src/delete.txt' = "delete baseline`n"
        'src/mode.sh' = "#!/bin/sh`necho baseline`n"
        'src/link.txt' = "target-one"
        'config/input.json' = "{`"version`":1}`n"
        'config/other.json' = "{`"feature`":true}`n"
        '.gitignore' = ".cache/`n"
    }).GetEnumerator()) {
        if ($null -ne $entry.Value) {
            Set-Topic04Utf8File -LiteralPath (Join-Path $repository $entry.Key) -Content $entry.Value
        }
    }
    [void](Invoke-Topic04GitChecked -WorkingDirectory $repository -Arguments @('add', '.'))
    $linkBlob = Invoke-Topic04GitChecked -WorkingDirectory $repository -Arguments @('hash-object', '-w', 'src/link.txt')
    [void](Invoke-Topic04GitChecked -WorkingDirectory $repository -Arguments @('update-index', '--add', '--cacheinfo', "120000,$linkBlob,src/link.txt"))
    [void](Invoke-Topic04GitChecked -WorkingDirectory $repository -Arguments @('commit', '--quiet', '-m', 'candidate baseline'))

    Add-Content -LiteralPath (Join-Path $repository 'src/preexisting.txt') -Value 'user dirty baseline'
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/preexisting-untracked.txt') -Content "user untracked baseline`n"

    $create = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'create-task' -Request (
        New-Topic04CandidateTaskPayload -Objective 'Build an exact candidate.' -WriteScope @(
            [ordered]@{ kind = 'subtree'; path = 'src' }
        ) -OwnedIgnoredOutputs @('.cache/result.bin')
    ) -SessionRef 'codex:candidate-owner'
    Assert-Topic04Candidate ($create.ExitCode -eq 0) 'Candidate task creation must succeed.'
    $context = Resolve-AgentTasksContext -WorkingDirectory $repository
    $authority = Get-AgentTasksTaskAuthority -StateRoot $context.StateRoot -TaskId ([string]$create.Parsed.data.task_id)

    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/owned.txt') -Content "owned candidate`n"
    Add-Content -LiteralPath (Join-Path $repository 'src/preexisting.txt') -Value 'task-owned continuation'
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/new.txt') -Content "new output`n"
    Remove-Item -LiteralPath (Join-Path $repository 'src/delete.txt')
    [void](Invoke-Topic04GitChecked -WorkingDirectory $repository -Arguments @('update-index', '--chmod=+x', 'src/mode.sh'))
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/link.txt') -Content 'target-two'
    $linkBlobTwo = Invoke-Topic04GitChecked -WorkingDirectory $repository -Arguments @('hash-object', '-w', 'src/link.txt')
    [void](Invoke-Topic04GitChecked -WorkingDirectory $repository -Arguments @('update-index', '--cacheinfo', "120000,$linkBlobTwo,src/link.txt"))
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository '.cache/result.bin') -Content "declared ignored output`n"
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository '.cache/other.tmp') -Content "undeclared cache`n"
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'notes.txt') -Content "concurrent user note`n"

    $inputs = @(
        [ordered]@{ path = 'config/other.json'; role = 'configuration' },
        [ordered]@{ path = 'config/input.json'; role = 'configuration' }
    )
    $unexplained = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'freeze' -Request (
        New-Topic04FreezePayload -Authority $authority -AcceptanceInputs $inputs
    ) -SessionRef 'codex:candidate-owner'
    Assert-Topic04CandidateFailure -Result $unexplained -Code 'AT-SCOPE-UNEXPLAINED' -Scenario 'out-of-scope change without disposition'
    $afterRefusal = Get-AgentTasksTaskAuthority -StateRoot $context.StateRoot -TaskId ([string]$authority.Contract.task_id)
    Assert-Topic04Candidate ($afterRefusal.Revision.revision -eq $authority.Revision.revision) 'A refused freeze must not publish a candidate transition.'

    $dispositions = @(
        [ordered]@{
            path = 'notes.txt'
            disposition = 'accepted_external_change'
            reason = 'Concurrent user note is outside task ownership.'
        }
    )
    $freeze = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'freeze' -Request (
        New-Topic04FreezePayload -Authority $afterRefusal -AcceptanceInputs $inputs -ScopeDispositions $dispositions
    ) -SessionRef 'codex:candidate-owner'
    Assert-Topic04Candidate ($freeze.ExitCode -eq 0 -and $freeze.Parsed.data.candidate_id -ceq 'C1') "First candidate must freeze as C1 (exit=$($freeze.ExitCode), code=$($freeze.Parsed.code))."
    $afterFreeze = Get-AgentTasksTaskAuthority -StateRoot $context.StateRoot -TaskId ([string]$authority.Contract.task_id)
    $candidate = Get-Topic04CandidateRecord -Authority $afterFreeze -CandidateId 'C1'
    Assert-Topic04Candidate ($candidate.lineage -eq 1 -and $candidate.record_hash -ceq $freeze.Parsed.data.candidate_hash) 'C1 lineage and returned hash must match the immutable candidate.'
    $paths = @($candidate.entries | ForEach-Object path)
    foreach ($requiredPath in @('src/owned.txt', 'src/preexisting.txt', 'src/new.txt', 'src/delete.txt', 'src/mode.sh', 'src/link.txt', '.cache/result.bin', 'notes.txt')) {
        Assert-Topic04Candidate ($paths -contains $requiredPath) "Candidate must include $requiredPath."
    }
    Assert-Topic04Candidate ($paths -notcontains 'src/preexisting-untracked.txt') 'Unchanged pre-existing untracked bytes must not become task output.'
    Assert-Topic04Candidate ($paths -notcontains '.cache/other.tmp') 'Undeclared ignored cache must remain outside candidate identity.'
    $deleted = @($candidate.entries | Where-Object path -eq 'src/delete.txt')[0]
    Assert-Topic04Candidate ($deleted.presence -ceq 'absent' -and $null -eq $deleted.sha256) 'Tracked deletion must be an explicit absent marker.'
    $modeEntry = @($candidate.entries | Where-Object path -eq 'src/mode.sh')[0]
    Assert-Topic04Candidate ($modeEntry.mode -ceq '100755') 'Executable index-mode change must enter candidate identity.'
    $linkEntry = @($candidate.entries | Where-Object path -eq 'src/link.txt')[0]
    Assert-Topic04Candidate ($linkEntry.file_type -ceq 'symlink' -and $linkEntry.mode -ceq '120000') 'Symlink identity must hash target text without following it.'
    $ignoredEntry = @($candidate.entries | Where-Object path -eq '.cache/result.bin')[0]
    Assert-Topic04Candidate ($ignoredEntry.role -ceq 'owned_ignored_output' -and $ignoredEntry.sha256) 'Declared ignored output must be hashed explicitly.'
    $dispositionEntry = @($candidate.entries | Where-Object path -eq 'notes.txt')[0]
    Assert-Topic04Candidate ($dispositionEntry.role -ceq 'scope_disposition') 'Explicit out-of-scope disposition must be recorded, never silently dropped.'
    $sortedPaths = @($paths | Sort-Object)
    Assert-Topic04Candidate (($paths -join '|') -ceq ($sortedPaths -join '|')) 'Candidate entries must be sorted deterministically by normalized path.'
    Assert-Topic04Candidate ($candidate.acceptance_inputs[0].path -ceq 'config/input.json' -and $candidate.acceptance_inputs[1].path -ceq 'config/other.json') "Acceptance inputs must be canonicalized independently of request enumeration order (actual=$(@($candidate.acceptance_inputs | ForEach-Object path) -join '|'))."

    $check = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'check' -Request ([ordered]@{
        task_id = [string]$authority.Contract.task_id; candidate_id = 'C1'
    }) -SessionRef 'codex:candidate-owner'
    Assert-Topic04Candidate ($check.ExitCode -eq 0 -and $check.Parsed.data.status -ceq 'valid') 'An unchanged C1 must pass boundary rehash.'

    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'config/input.json') -Content "{`"version`":2}`n"
    $drift = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'check' -Request ([ordered]@{
        task_id = [string]$authority.Contract.task_id; candidate_id = 'C1'
    }) -SessionRef 'codex:candidate-owner'
    Assert-Topic04CandidateFailure -Result $drift -Code 'AT-CANDIDATE-DRIFT' -Scenario 'acceptance input mutation'
    $afterDrift = Get-AgentTasksTaskAuthority -StateRoot $context.StateRoot -TaskId ([string]$authority.Contract.task_id)
    Assert-Topic04Candidate ($afterDrift.Revision.status -ceq 'rework' -and @($afterDrift.Revision.stale_candidate_ids) -contains 'C1') 'C1 drift must preserve history and move current state to rework.'
    Assert-Topic04Candidate (Test-Path -LiteralPath (Join-Path $afterDrift.Root 'candidates\C1.json')) 'C1 must remain immutable after drift.'

    $freezeTwo = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'freeze' -Request (
        New-Topic04FreezePayload -Authority $afterDrift -AcceptanceInputs $inputs -ScopeDispositions $dispositions
    ) -SessionRef 'codex:candidate-owner'
    Assert-Topic04Candidate ($freezeTwo.ExitCode -eq 0 -and $freezeTwo.Parsed.data.candidate_id -ceq 'C2') 'Refreeze after drift must create C2.'
    Assert-Topic04Candidate ($freezeTwo.Parsed.data.candidate_hash -cne $freeze.Parsed.data.candidate_hash) 'C2 must have a new candidate hash.'
    $afterFreezeTwo = Get-AgentTasksTaskAuthority -StateRoot $context.StateRoot -TaskId ([string]$authority.Contract.task_id)
    $candidateTwo = Get-Topic04CandidateRecord -Authority $afterFreezeTwo -CandidateId 'C2'
    Assert-Topic04Candidate ($candidateTwo.lineage -eq 2) 'C2 must increment candidate lineage.'

    $headFixture = New-Topic04FixtureRoot -Label 'candidate-head-drift'
    $headRepository = Initialize-Topic04GitFixture -Root $headFixture
    Set-Topic04Utf8File -LiteralPath (Join-Path $headRepository 'src.txt') -Content "base`n"
    [void](Invoke-Topic04GitChecked -WorkingDirectory $headRepository -Arguments @('add', 'src.txt'))
    [void](Invoke-Topic04GitChecked -WorkingDirectory $headRepository -Arguments @('commit', '--quiet', '-m', 'tracked source'))
    $headCreate = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $headFixture -WorkingDirectory $headRepository -Operation 'create-task' -Request (
        New-Topic04CandidateTaskPayload -Objective 'Detect HEAD drift.' -WriteScope @([ordered]@{ kind = 'exact'; path = 'src.txt' })
    ) -SessionRef 'codex:head-owner'
    $headContext = Resolve-AgentTasksContext -WorkingDirectory $headRepository
    $headAuthority = Get-AgentTasksTaskAuthority -StateRoot $headContext.StateRoot -TaskId ([string]$headCreate.Parsed.data.task_id)
    Set-Topic04Utf8File -LiteralPath (Join-Path $headRepository 'later.txt') -Content "later`n"
    [void](Invoke-Topic04GitChecked -WorkingDirectory $headRepository -Arguments @('add', 'later.txt'))
    [void](Invoke-Topic04GitChecked -WorkingDirectory $headRepository -Arguments @('commit', '--quiet', '-m', 'move head'))
    $headFreeze = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $headFixture -WorkingDirectory $headRepository -Operation 'freeze' -Request (
        New-Topic04FreezePayload -Authority $headAuthority -AcceptanceInputs @([ordered]@{ path = 'README.md'; role = 'contract_input' })
    ) -SessionRef 'codex:head-owner'
    Assert-Topic04CandidateFailure -Result $headFreeze -Code 'AT-BASELINE-HEAD' -Scenario 'HEAD drift after baseline'
    $headAfter = Get-AgentTasksTaskAuthority -StateRoot $headContext.StateRoot -TaskId ([string]$headAuthority.Contract.task_id)
    Assert-Topic04Candidate ($headAfter.Revision.status -ceq 'reconcile_required') 'HEAD drift must put task authority into reconcile_required.'

    $nestedFixture = New-Topic04FixtureRoot -Label 'candidate-nested'
    $nestedRepository = Initialize-Topic04GitFixture -Root $nestedFixture
    $nestedCreate = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $nestedFixture -WorkingDirectory $nestedRepository -Operation 'create-task' -Request (
        New-Topic04CandidateTaskPayload -Objective 'Reject dirty nested repository.' -WriteScope @([ordered]@{ kind = 'subtree'; path = 'vendor' })
    ) -SessionRef 'codex:nested-owner'
    $nestedContext = Resolve-AgentTasksContext -WorkingDirectory $nestedRepository
    $nestedAuthority = Get-AgentTasksTaskAuthority -StateRoot $nestedContext.StateRoot -TaskId ([string]$nestedCreate.Parsed.data.task_id)
    $inner = Join-Path $nestedRepository 'vendor\inner'
    [void](New-Item -ItemType Directory -Path $inner -Force)
    [void](Invoke-Topic04GitChecked -WorkingDirectory $inner -Arguments @('init', '--quiet'))
    [void](Invoke-Topic04GitChecked -WorkingDirectory $inner -Arguments @('config', 'user.name', 'Nested Test'))
    [void](Invoke-Topic04GitChecked -WorkingDirectory $inner -Arguments @('config', 'user.email', 'nested@example.invalid'))
    Set-Topic04Utf8File -LiteralPath (Join-Path $inner 'tracked.txt') -Content "base`n"
    [void](Invoke-Topic04GitChecked -WorkingDirectory $inner -Arguments @('add', 'tracked.txt'))
    [void](Invoke-Topic04GitChecked -WorkingDirectory $inner -Arguments @('commit', '--quiet', '-m', 'nested base'))
    Add-Content -LiteralPath (Join-Path $inner 'tracked.txt') -Value 'dirty nested bytes'
    $nestedFreeze = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $nestedFixture -WorkingDirectory $nestedRepository -Operation 'freeze' -Request (
        New-Topic04FreezePayload -Authority $nestedAuthority -AcceptanceInputs @([ordered]@{ path = 'README.md'; role = 'contract_input' })
    ) -SessionRef 'codex:nested-owner'
    Assert-Topic04CandidateFailure -Result $nestedFreeze -Code 'AT-NESTED-REPOSITORY-DIRTY' -Scenario 'dirty nested repository'

    $submoduleFixture = New-Topic04FixtureRoot -Label 'candidate-gitlink'
    $submoduleSource = Join-Path $submoduleFixture 'source'
    [void](New-Item -ItemType Directory -Path $submoduleSource)
    [void](Invoke-Topic04GitChecked -WorkingDirectory $submoduleSource -Arguments @('init', '--quiet'))
    [void](Invoke-Topic04GitChecked -WorkingDirectory $submoduleSource -Arguments @('config', 'user.name', 'Submodule Test'))
    [void](Invoke-Topic04GitChecked -WorkingDirectory $submoduleSource -Arguments @('config', 'user.email', 'submodule@example.invalid'))
    Set-Topic04Utf8File -LiteralPath (Join-Path $submoduleSource 'lib.txt') -Content "v1`n"
    [void](Invoke-Topic04GitChecked -WorkingDirectory $submoduleSource -Arguments @('add', 'lib.txt'))
    [void](Invoke-Topic04GitChecked -WorkingDirectory $submoduleSource -Arguments @('commit', '--quiet', '-m', 'v1'))
    $outerRoot = Join-Path $submoduleFixture 'outer-root'
    [void](New-Item -ItemType Directory -Path $outerRoot)
    $outer = Initialize-Topic04GitFixture -Root $outerRoot
    [void](Invoke-Topic04GitChecked -WorkingDirectory $outer -Arguments @('-c', 'protocol.file.allow=always', 'submodule', 'add', '--quiet', $submoduleSource, 'modules/lib'))
    [void](Invoke-Topic04GitChecked -WorkingDirectory $outer -Arguments @('commit', '--quiet', '-am', 'add submodule'))
    $gitlinkCreate = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $submoduleFixture -WorkingDirectory $outer -Operation 'create-task' -Request (
        New-Topic04CandidateTaskPayload -Objective 'Record exact Gitlink.' -WriteScope @([ordered]@{ kind = 'exact'; path = 'modules/lib' })
    ) -SessionRef 'codex:gitlink-owner'
    $gitlinkContext = Resolve-AgentTasksContext -WorkingDirectory $outer
    $gitlinkAuthority = Get-AgentTasksTaskAuthority -StateRoot $gitlinkContext.StateRoot -TaskId ([string]$gitlinkCreate.Parsed.data.task_id)
    $checkedOutSubmodule = Join-Path $outer 'modules\lib'
    [void](Invoke-Topic04GitChecked -WorkingDirectory $checkedOutSubmodule -Arguments @('config', 'user.name', 'Submodule Test'))
    [void](Invoke-Topic04GitChecked -WorkingDirectory $checkedOutSubmodule -Arguments @('config', 'user.email', 'submodule@example.invalid'))
    Set-Topic04Utf8File -LiteralPath (Join-Path $checkedOutSubmodule 'lib.txt') -Content "v2`n"
    [void](Invoke-Topic04GitChecked -WorkingDirectory $checkedOutSubmodule -Arguments @('add', 'lib.txt'))
    [void](Invoke-Topic04GitChecked -WorkingDirectory $checkedOutSubmodule -Arguments @('commit', '--quiet', '-m', 'v2'))
    $gitlinkCommit = Invoke-Topic04GitChecked -WorkingDirectory $checkedOutSubmodule -Arguments @('rev-parse', 'HEAD')
    [void](Invoke-Topic04GitChecked -WorkingDirectory $outer -Arguments @('add', 'modules/lib'))
    $gitlinkFreeze = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $submoduleFixture -WorkingDirectory $outer -Operation 'freeze' -Request (
        New-Topic04FreezePayload -Authority $gitlinkAuthority -AcceptanceInputs @([ordered]@{ path = 'README.md'; role = 'contract_input' })
    ) -SessionRef 'codex:gitlink-owner'
    Assert-Topic04Candidate ($gitlinkFreeze.ExitCode -eq 0) "Clean changed Gitlink must freeze (exit=$($gitlinkFreeze.ExitCode), code=$($gitlinkFreeze.Parsed.code))."
    $gitlinkAfter = Get-AgentTasksTaskAuthority -StateRoot $gitlinkContext.StateRoot -TaskId ([string]$gitlinkAuthority.Contract.task_id)
    $gitlinkCandidate = Get-Topic04CandidateRecord -Authority $gitlinkAfter -CandidateId 'C1'
    $gitlinkEntry = @($gitlinkCandidate.entries | Where-Object path -eq 'modules/lib')[0]
    Assert-Topic04Candidate ($gitlinkEntry.file_type -ceq 'gitlink' -and $gitlinkEntry.mode -ceq '160000') 'Gitlink candidate entry must retain index mode 160000.'
    Assert-Topic04Candidate ($gitlinkEntry.gitlink_commit -ceq $gitlinkCommit) 'Gitlink candidate entry must bind the exact submodule commit.'

    Write-Host ("PASS Topic 04 state candidate ({0} assertions)" -f $script:Assertions) -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("FAIL [AT-TEST-CANDIDATE] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    Remove-Topic04FixtureRoots
}
