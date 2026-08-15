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
$cliPath = Join-Path $repositoryRoot 'template\.omp\state\agent-tasks.ps1'

if (-not (Test-Path -LiteralPath $evidencePath -PathType Leaf)) {
    Write-Host 'FAIL [AT-TEST-EVIDENCE-MISSING] Topic 04 evidence core is not installed.' -ForegroundColor Red
    exit 1
}

. $fixtureHelper
. $commonPath
. $storePath
. $gitPath
. $lifecyclePath
. $candidatePath
. $evidencePath

$script:Assertions = 0

function Assert-Topic04Evidence {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Assert-Topic04EvidenceFailure {
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

function Invoke-Topic04EvidenceGit {
    param([Parameter(Mandatory)][string]$WorkingDirectory, [Parameter(Mandatory)][string[]]$Arguments)
    $output = @(& git -C $WorkingDirectory @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Git fixture command failed: $($output -join ' ')" }
    return ($output -join "`n").Trim()
}

function New-Topic04EvidenceTask {
    param(
        [Parameter(Mandatory)][string]$CliPath,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Objective,
        [string[]]$Obligations = @('test', 'verification', 'review'),
        [string]$SessionRef = 'codex:evidence-owner'
    )
    return Invoke-Topic04CliObject -CliPath $CliPath -FixtureRoot $FixtureRoot -WorkingDirectory $Repository -Operation 'create-task' -Request ([ordered]@{
        objective = $Objective
        authority = @('user')
        acceptance_criteria = @(
            [ordered]@{ id = 'AC-001'; text = 'Output bytes are correct.'; mandatory = $true },
            [ordered]@{ id = 'AC-002'; text = 'Verification and review are complete.'; mandatory = $true },
            [ordered]@{ id = 'AC-OPTIONAL'; text = 'Optional note is present.'; mandatory = $false }
        )
        obligations = @($Obligations)
        execution_mode = 'mutating'
        write_scope = @([ordered]@{ kind = 'subtree'; path = 'src' })
        owned_ignored_outputs = @()
        workflow_class = 'standard'
        locked_decisions = @()
    }) -SessionRef $SessionRef
}

function Get-Topic04EvidenceAuthority {
    param([Parameter(Mandatory)][object]$Context, [Parameter(Mandatory)][string]$TaskId)
    return Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $TaskId
}

function Freeze-Topic04EvidenceCandidate {
    param(
        [Parameter(Mandatory)][string]$CliPath,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Authority,
        [string]$SessionRef = 'codex:evidence-owner'
    )
    return Invoke-Topic04CliObject -CliPath $CliPath -FixtureRoot $FixtureRoot -WorkingDirectory $Repository -Operation 'freeze' -Request ([ordered]@{
        task_id = [string]$Authority.Contract.task_id
        acceptance_inputs = @([ordered]@{ path = 'config/contract.json'; role = 'contract_input' })
        scope_dispositions = @()
        expected_revision = [long]$Authority.Revision.revision
        expected_revision_sha256 = [string]$Authority.RevisionSha256
        expected_lease_generation = [long]$Authority.Revision.lease_generation
    }) -SessionRef $SessionRef
}

function Get-Topic04CandidateInputHashes {
    param([Parameter(Mandatory)][object]$Authority, [Parameter(Mandatory)][string]$CandidateId)
    $candidate = Read-AgentTasksJsonFile -LiteralPath (Join-Path $Authority.Root (Join-Path 'candidates' ($CandidateId + '.json')))
    return @($candidate.acceptance_inputs | ForEach-Object {
        [ordered]@{ path = [string]$_.path; sha256 = [string]$_.sha256 }
    })
}

function Invoke-Topic04RecordEvidence {
    param(
        [Parameter(Mandatory)][string]$CliPath,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][Collections.IDictionary]$Evidence,
        [string]$SessionRef = 'codex:evidence-owner'
    )
    $request = [ordered]@{}
    foreach ($key in $Evidence.Keys) { $request[[string]$key] = $Evidence[$key] }
    $request.task_id = [string]$Authority.Contract.task_id
    $request.expected_revision = [long]$Authority.Revision.revision
    $request.expected_revision_sha256 = [string]$Authority.RevisionSha256
    $request.expected_lease_generation = [long]$Authority.Revision.lease_generation
    return Invoke-Topic04CliObject -CliPath $CliPath -FixtureRoot $FixtureRoot -WorkingDirectory $Repository -Operation 'record-evidence' -Request $request -SessionRef $SessionRef
}

function Invoke-Topic04Close {
    param(
        [Parameter(Mandatory)][string]$CliPath,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$Status,
        [AllowNull()][string]$CandidateId = $null,
        [AllowNull()][string]$Reason = $null,
        [string]$SessionRef = 'codex:evidence-owner'
    )
    $request = [ordered]@{
        task_id = [string]$Authority.Contract.task_id
        terminal_status = $Status
        expected_revision = [long]$Authority.Revision.revision
        expected_revision_sha256 = [string]$Authority.RevisionSha256
        expected_lease_generation = [long]$Authority.Revision.lease_generation
    }
    if ($CandidateId) { $request.candidate_id = $CandidateId }
    if ($Reason) { $request.reason = $Reason }
    return Invoke-Topic04CliObject -CliPath $CliPath -FixtureRoot $FixtureRoot -WorkingDirectory $Repository -Operation 'close' -Request $request -SessionRef $SessionRef
}

try {
    $fixture = New-Topic04FixtureRoot -Label 'evidence-main'
    $repository = Initialize-Topic04GitFixture -Root $fixture
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository '.gitignore') -Content ".task/`n"
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "baseline`n"
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'config/contract.json') -Content "{`"schema`":1}`n"
    [void](Invoke-Topic04EvidenceGit -WorkingDirectory $repository -Arguments @('add', '.'))
    [void](Invoke-Topic04EvidenceGit -WorkingDirectory $repository -Arguments @('commit', '--quiet', '-m', 'evidence baseline'))

    $create = New-Topic04EvidenceTask -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Objective 'Prove exact evidence and acceptance.'
    Assert-Topic04Evidence ($create.ExitCode -eq 0) 'Evidence task creation must succeed.'
    $context = Resolve-AgentTasksContext -WorkingDirectory $repository
    $taskId = [string]$create.Parsed.data.task_id
    $authority = Get-Topic04EvidenceAuthority -Context $context -TaskId $taskId
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "candidate`n"
    $freeze = Freeze-Topic04EvidenceCandidate -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $authority
    Assert-Topic04Evidence ($freeze.ExitCode -eq 0 -and $freeze.Parsed.data.candidate_id -ceq 'C1') 'Evidence fixture must freeze C1.'
    $authority = Get-Topic04EvidenceAuthority -Context $context -TaskId $taskId
    $inputHashes = Get-Topic04CandidateInputHashes -Authority $authority -CandidateId 'C1'

    $unknownType = Invoke-Topic04RecordEvidence -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $authority -Evidence ([ordered]@{
        evidence_type = 'model_opinion'; producer = 'model'; candidate_id = 'C1'; covered_ac_ids = @('AC-001')
        observation = [ordered]@{ status = 'PASS' }; validity_triggers = @(); acceptance_input_hashes = $inputHashes
    })
    Assert-Topic04EvidenceFailure -Result $unknownType -Code 'AT-EVIDENCE-TYPE' -Scenario 'unknown evidence type'

    $modelPass = Invoke-Topic04RecordEvidence -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $authority -Evidence ([ordered]@{
        evidence_type = 'test'; producer = 'model'; candidate_id = 'C1'; covered_ac_ids = @('AC-001')
        observation = [ordered]@{ status = 'PASS' }; validity_triggers = @([ordered]@{ kind = 'candidate_drift' }); acceptance_input_hashes = $inputHashes
    })
    Assert-Topic04EvidenceFailure -Result $modelPass -Code 'AT-EVIDENCE-PRODUCER' -Scenario 'model-authored PASS'

    $unknownAc = Invoke-Topic04RecordEvidence -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $authority -Evidence ([ordered]@{
        evidence_type = 'test'; producer = 'deterministic_runner'; candidate_id = 'C1'; covered_ac_ids = @('AC-UNKNOWN')
        observation = [ordered]@{ status = 'PASS' }; validity_triggers = @([ordered]@{ kind = 'candidate_drift' }); acceptance_input_hashes = $inputHashes
    })
    Assert-Topic04EvidenceFailure -Result $unknownAc -Code 'AT-EVIDENCE-AC' -Scenario 'unknown covered AC'

    $missingInputBinding = Invoke-Topic04RecordEvidence -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $authority -Evidence ([ordered]@{
        evidence_type = 'test'; producer = 'deterministic_runner'; candidate_id = 'C1'; covered_ac_ids = @('AC-001')
        observation = [ordered]@{ status = 'PASS' }; validity_triggers = @([ordered]@{ kind = 'candidate_drift' })
    })
    Assert-Topic04EvidenceFailure -Result $missingInputBinding -Code 'AT-EVIDENCE-BINDING' -Scenario 'test evidence without input binding'

    $ttlEvidence = Invoke-Topic04RecordEvidence -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $authority -Evidence ([ordered]@{
        evidence_type = 'test'; producer = 'deterministic_runner'; candidate_id = 'C1'; covered_ac_ids = @('AC-001')
        observation = [ordered]@{ status = 'PASS' }; validity_triggers = @([ordered]@{ kind = 'ttl_seconds'; value = 60 }); acceptance_input_hashes = $inputHashes
    })
    Assert-Topic04EvidenceFailure -Result $ttlEvidence -Code 'AT-EVIDENCE-TTL' -Scenario 'global TTL is forbidden'

    $sameSessionReview = Invoke-Topic04RecordEvidence -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $authority -Evidence ([ordered]@{
        evidence_type = 'review'; producer = 'independent_reviewer'; producer_session_ref = 'codex:evidence-owner'
        candidate_id = 'C1'; covered_ac_ids = @('AC-002'); observation = [ordered]@{ verdict = 'PASS'; blocking_findings = @() }
        validity_triggers = @([ordered]@{ kind = 'candidate_drift' })
    })
    Assert-Topic04EvidenceFailure -Result $sameSessionReview -Code 'AT-EVIDENCE-INDEPENDENCE' -Scenario 'review from owner session'

    $providerSecret = Invoke-Topic04RecordEvidence -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $authority -Evidence ([ordered]@{
        evidence_type = 'provider_environment'; producer = 'deterministic_probe'; covered_ac_ids = @()
        observation = [ordered]@{ status = 'PASS'; password = 'not-allowed' }
        validity_triggers = @([ordered]@{ kind = 'environment_change' })
        environment_fingerprint = [ordered]@{ runtime = 'pwsh'; version = '7.6.4'; platform = 'win32'; status = 'available' }
    })
    Assert-Topic04EvidenceFailure -Result $providerSecret -Code 'AT-EVIDENCE-ENVIRONMENT' -Scenario 'provider evidence nonallowlisted field'

    $externalNoFreshness = Invoke-Topic04RecordEvidence -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $authority -Evidence ([ordered]@{
        evidence_type = 'external_fact'; producer = 'retrieval_source'; covered_ac_ids = @()
        observation = [ordered]@{ status = 'PASS' }; validity_triggers = @([ordered]@{ kind = 'source_change' })
        source_identity = [ordered]@{ uri = 'https://example.invalid/fact'; retrieved_at = '2026-08-13T00:00:00Z' }
    })
    Assert-Topic04EvidenceFailure -Result $externalNoFreshness -Code 'AT-EVIDENCE-FRESHNESS' -Scenario 'external fact without freshness rule'

    $scratch = Join-Path $repository (Join-Path '.task' $taskId)
    [void](New-Item -ItemType Directory -Path $scratch -Force)
    Set-Topic04Utf8File -LiteralPath (Join-Path $scratch 'report.txt') -Content "sanitized report`n"
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'outside-report.txt') -Content "outside`n"
    $outsideArtifact = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'promote-artifact' -Request ([ordered]@{
        task_id = $taskId; source_path = (Join-Path $repository 'outside-report.txt'); media_type = 'text/plain'; candidate_id = 'C1'
        expected_revision = $authority.Revision.revision; expected_revision_sha256 = $authority.RevisionSha256
        expected_lease_generation = $authority.Revision.lease_generation
    }) -SessionRef 'codex:evidence-owner'
    Assert-Topic04EvidenceFailure -Result $outsideArtifact -Code 'AT-ARTIFACT-SOURCE' -Scenario 'artifact outside allowed roots'
    Remove-Item -LiteralPath (Join-Path $repository 'outside-report.txt')

    Set-Topic04Utf8File -LiteralPath (Join-Path $scratch '.env') -Content "API_KEY=sk-test-secret-value`n"
    $secretArtifact = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'promote-artifact' -Request ([ordered]@{
        task_id = $taskId; source_path = (Join-Path $scratch '.env'); media_type = 'text/plain'; candidate_id = 'C1'
        expected_revision = $authority.Revision.revision; expected_revision_sha256 = $authority.RevisionSha256
        expected_lease_generation = $authority.Revision.lease_generation
    }) -SessionRef 'codex:evidence-owner'
    Assert-Topic04EvidenceFailure -Result $secretArtifact -Code 'AT-ARTIFACT-SECRET' -Scenario 'raw env artifact'

    $escapeRoot = Join-Path $fixture 'artifact-escape'
    [void](New-Item -ItemType Directory -Path $escapeRoot)
    Set-Topic04Utf8File -LiteralPath (Join-Path $escapeRoot 'escaped.txt') -Content "escaped`n"
    $junction = Join-Path $scratch 'junction'
    [void](New-Item -ItemType Junction -Path $junction -Target $escapeRoot)
    $escapedArtifact = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'promote-artifact' -Request ([ordered]@{
        task_id = $taskId; source_path = (Join-Path $junction 'escaped.txt'); media_type = 'text/plain'; candidate_id = 'C1'
        expected_revision = $authority.Revision.revision; expected_revision_sha256 = $authority.RevisionSha256
        expected_lease_generation = $authority.Revision.lease_generation
    }) -SessionRef 'codex:evidence-owner'
    Assert-Topic04EvidenceFailure -Result $escapedArtifact -Code 'AT-ARTIFACT-REPARSE' -Scenario 'artifact reparse escape'

    $promote = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'promote-artifact' -Request ([ordered]@{
        task_id = $taskId; source_path = (Join-Path $scratch 'report.txt'); media_type = 'text/plain'; candidate_id = 'C1'
        expected_revision = $authority.Revision.revision; expected_revision_sha256 = $authority.RevisionSha256
        expected_lease_generation = $authority.Revision.lease_generation
    }) -SessionRef 'codex:evidence-owner'
    Assert-Topic04Evidence ($promote.ExitCode -eq 0 -and $promote.Parsed.data.artifact_hash) "Valid artifact must promote (exit=$($promote.ExitCode), code=$($promote.Parsed.code))."
    $authority = Get-Topic04EvidenceAuthority -Context $context -TaskId $taskId
    $artifactHash = [string]$promote.Parsed.data.artifact_hash
    $artifactPath = [string]$promote.Parsed.data.artifact_path
    Assert-Topic04Evidence (Test-Path -LiteralPath $artifactPath -PathType Leaf) 'Promoted artifact must exist at its content-addressed path.'
    Assert-Topic04Evidence ((Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash -ceq $artifactHash) 'Promoted artifact bytes must match its content address.'

    $promoteAgain = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'promote-artifact' -Request ([ordered]@{
        task_id = $taskId; source_path = (Join-Path $scratch 'report.txt'); media_type = 'text/plain'; candidate_id = 'C1'
        expected_revision = $authority.Revision.revision; expected_revision_sha256 = $authority.RevisionSha256
        expected_lease_generation = $authority.Revision.lease_generation
    }) -SessionRef 'codex:evidence-owner'
    Assert-Topic04Evidence ($promoteAgain.ExitCode -eq 0 -and $promoteAgain.Parsed.data.artifact_hash -ceq $artifactHash) 'Same validated artifact bytes must deduplicate.'
    $authority = Get-Topic04EvidenceAuthority -Context $context -TaskId $taskId
    Assert-Topic04Evidence (@(Get-ChildItem -LiteralPath (Join-Path $authority.Root 'artifacts') -File | Where-Object Extension -ne '.json').Count -eq 1) 'Artifact deduplication must publish one content file.'

    $testEvidence = Invoke-Topic04RecordEvidence -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $authority -Evidence ([ordered]@{
        evidence_type = 'test'; producer = 'deterministic_runner'; candidate_id = 'C1'; covered_ac_ids = @('AC-001')
        observation = [ordered]@{ status = 'PASS'; total = 12; failed = 0 }
        validity_triggers = @([ordered]@{ kind = 'candidate_drift' }, [ordered]@{ kind = 'acceptance_input_drift' })
        acceptance_input_hashes = $inputHashes; artifact_hash = $artifactHash
    })
    Assert-Topic04Evidence ($testEvidence.ExitCode -eq 0 -and $testEvidence.Parsed.data.evidence_id -ceq 'E000001') 'Deterministic test evidence must publish E000001.'
    $authority = Get-Topic04EvidenceAuthority -Context $context -TaskId $taskId
    Assert-Topic04Evidence (
        $authority.Revision.Contains('evidence_ids') -and
        @($authority.Revision.evidence_ids) -contains 'E000001'
    ) "Evidence revision must reference E000001 (revision=$($authority.Revision.revision), keys=$(@($authority.Revision.Keys) -join ','), ids=$(@($authority.Revision.evidence_ids) -join ','))."
    $storedTestEvidence = Read-AgentTasksJsonFile -LiteralPath (Join-Path $authority.Root 'evidence\E000001.json')
    $storedCandidate = Read-AgentTasksJsonFile -LiteralPath (Join-Path $authority.Root 'candidates\C1.json')
    Assert-Topic04Evidence (
        [string]$storedTestEvidence.candidate_hash -ceq [string]$storedCandidate.record_hash
    ) "Evidence must bind the exact candidate hash (evidence=$($storedTestEvidence.candidate_hash), candidate=$($storedCandidate.record_hash))."

    $verification = Invoke-Topic04RecordEvidence -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $authority -Evidence ([ordered]@{
        evidence_type = 'verification'; producer = 'tech_lead'; candidate_id = 'C1'; covered_ac_ids = @('AC-001', 'AC-002')
        observation = [ordered]@{ status = 'PASS'; conflicts = @() }
        validity_triggers = @([ordered]@{ kind = 'candidate_drift' }, [ordered]@{ kind = 'acceptance_input_drift' })
        acceptance_input_hashes = $inputHashes; input_evidence_ids = @('E000001'); artifact_hash = $artifactHash
    })
    Assert-Topic04Evidence ($verification.ExitCode -eq 0 -and $verification.Parsed.data.evidence_id -ceq 'E000002') 'Verification must bind exact test evidence and candidate.'
    $authority = Get-Topic04EvidenceAuthority -Context $context -TaskId $taskId

    $review = Invoke-Topic04RecordEvidence -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $authority -Evidence ([ordered]@{
        evidence_type = 'review'; producer = 'independent_reviewer'; producer_session_ref = 'codex:review-session'
        candidate_id = 'C1'; covered_ac_ids = @('AC-002')
        observation = [ordered]@{ verdict = 'PASS'; blocking_findings = @() }
        validity_triggers = @([ordered]@{ kind = 'candidate_drift' })
    })
    Assert-Topic04Evidence ($review.ExitCode -eq 0 -and $review.Parsed.data.evidence_id -ceq 'E000003') 'Independent review must publish candidate-bound evidence.'
    $authority = Get-Topic04EvidenceAuthority -Context $context -TaskId $taskId

    $candidateForAcceptance = Read-AgentTasksJsonFile -LiteralPath (Join-Path $authority.Root 'candidates\C1.json')
    Assert-Topic04Evidence (
        (@($authority.Revision.evidence_ids) -join ',') -ceq 'E000001,E000002,E000003'
    ) "Acceptance revision must reference the complete evidence set (ids=$(@($authority.Revision.evidence_ids) -join ','))."
    foreach ($evidenceId in @($authority.Revision.evidence_ids)) {
        $storedEvidence = Read-AgentTasksJsonFile -LiteralPath (Join-Path $authority.Root (Join-Path 'evidence' ($evidenceId + '.json')))
        Assert-Topic04Evidence (
            [string]$storedEvidence.record_hash -ceq (Get-AgentTasksSha256 -Value $storedEvidence)
        ) "$evidenceId must retain a valid record hash."
        Assert-Topic04Evidence (
            [string]$storedEvidence.candidate_hash -ceq [string]$candidateForAcceptance.record_hash
        ) "$evidenceId must retain its exact candidate binding."
        Assert-Topic04Evidence (Test-AgentTasksEvidencePasses -Evidence $storedEvidence) "$evidenceId must carry a passing observation."
        if ([string]$storedEvidence.evidence_type -in @('test', 'verification')) {
            Assert-Topic04Evidence (
                @($storedEvidence.acceptance_input_hashes).Count -eq 1
            ) "$evidenceId must retain one acceptance-input binding (value=$($storedEvidence.acceptance_input_hashes | ConvertTo-Json -Compress))."
        }
    }
    $acceptancePreview = Test-AgentTasksAcceptance -Authority $authority -Candidate $candidateForAcceptance
    Assert-Topic04Evidence $acceptancePreview.Valid "Evidence adjudication must cover every mandatory AC and obligation (missing_ac=$($acceptancePreview.MissingAcceptanceCriteria -join ','), missing_types=$($acceptancePreview.MissingObligations -join ','), evidence=$($acceptancePreview.EvidenceIds -join ','))."

    $close = Invoke-Topic04Close -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $authority -Status 'accepted' -CandidateId 'C1'
    Assert-Topic04Evidence ($close.ExitCode -eq 0 -and $close.Parsed.data.status -ceq 'accepted') "Fully evidenced C1 must close accepted (exit=$($close.ExitCode), code=$($close.Parsed.code))."
    $accepted = Get-Topic04EvidenceAuthority -Context $context -TaskId $taskId
    Assert-Topic04Evidence ($accepted.Revision.accepted_candidate_id -ceq 'C1' -and $accepted.Revision.accepted_candidate_hash -ceq $freeze.Parsed.data.candidate_hash) 'Terminal revision must name exact accepted candidate bytes.'
    Assert-Topic04Evidence ($accepted.Revision.historical_acceptance_validity -ceq 'valid') 'Fresh accepted history must start valid.'

    $invalidate = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'invalidate' -Request ([ordered]@{
        task_id = $taskId; target_type = 'candidate'; target_id = 'C1'; reason = 'A later security fact invalidated the historical decision.'
        remediation_task_id = 'T-REMEDIATE'; expected_revision = $accepted.Revision.revision
        expected_revision_sha256 = $accepted.RevisionSha256; expected_lease_generation = $accepted.Revision.lease_generation
    }) -SessionRef 'codex:evidence-owner'
    Assert-Topic04Evidence ($invalidate.ExitCode -eq 0) 'Later invalidation must append history without rewriting acceptance.'
    $invalidated = Get-Topic04EvidenceAuthority -Context $context -TaskId $taskId
    Assert-Topic04Evidence ($invalidated.Revision.status -ceq 'accepted' -and $invalidated.Revision.historical_acceptance_validity -ceq 'invalidated') 'Invalidation must preserve terminal accepted state and mark historical validity.'
    Assert-Topic04Evidence (Test-Path -LiteralPath (Join-Path $invalidated.Root 'candidates\C1.json')) 'Invalidation must not delete the candidate.'
    foreach ($evidenceId in @('E000001', 'E000002', 'E000003')) {
        Assert-Topic04Evidence (Test-Path -LiteralPath (Join-Path $invalidated.Root (Join-Path 'evidence' ($evidenceId + '.json')))) "Invalidation must preserve $evidenceId."
    }

    $missingCreate = New-Topic04EvidenceTask -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Objective 'Reject uncovered acceptance.' -Obligations @('test') -SessionRef 'codex:missing-owner'
    Assert-Topic04Evidence ($missingCreate.ExitCode -eq 0) 'A new task may reuse the worktree after the prior task is terminal.'
    $missingId = [string]$missingCreate.Parsed.data.task_id
    $missingAuthority = Get-Topic04EvidenceAuthority -Context $context -TaskId $missingId
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "candidate two`n"
    $missingFreeze = Freeze-Topic04EvidenceCandidate -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $missingAuthority -SessionRef 'codex:missing-owner'
    Assert-Topic04Evidence ($missingFreeze.ExitCode -eq 0) 'Second task must freeze its candidate.'
    $missingAuthority = Get-Topic04EvidenceAuthority -Context $context -TaskId $missingId
    $missingClose = Invoke-Topic04Close -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $missingAuthority -Status 'accepted' -CandidateId 'C1' -SessionRef 'codex:missing-owner'
    Assert-Topic04EvidenceFailure -Result $missingClose -Code 'AT-ACCEPTANCE-EVIDENCE' -Scenario 'uncovered mandatory AC and missing obligation'

    $driftHashes = Get-Topic04CandidateInputHashes -Authority $missingAuthority -CandidateId 'C1'
    $missingTest = Invoke-Topic04RecordEvidence -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $missingAuthority -Evidence ([ordered]@{
        evidence_type = 'test'; producer = 'deterministic_runner'; candidate_id = 'C1'; covered_ac_ids = @('AC-001', 'AC-002')
        observation = [ordered]@{ status = 'PASS' }; validity_triggers = @([ordered]@{ kind = 'candidate_drift' })
        acceptance_input_hashes = $driftHashes
    }) -SessionRef 'codex:missing-owner'
    Assert-Topic04Evidence ($missingTest.ExitCode -eq 0) 'C1 evidence must record before drift.'
    $missingAuthority = Get-Topic04EvidenceAuthority -Context $context -TaskId $missingId
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "candidate three`n"
    $driftCheck = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'check' -Request ([ordered]@{
        task_id = $missingId; candidate_id = 'C1'
    }) -SessionRef 'codex:missing-owner'
    Assert-Topic04EvidenceFailure -Result $driftCheck -Code 'AT-CANDIDATE-DRIFT' -Scenario 'candidate mutation invalidates C1 evidence'
    $missingAuthority = Get-Topic04EvidenceAuthority -Context $context -TaskId $missingId
    $refreeze = Freeze-Topic04EvidenceCandidate -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $missingAuthority -SessionRef 'codex:missing-owner'
    Assert-Topic04Evidence ($refreeze.ExitCode -eq 0 -and $refreeze.Parsed.data.candidate_id -ceq 'C2') 'Candidate drift must refreeze as C2.'
    $missingAuthority = Get-Topic04EvidenceAuthority -Context $context -TaskId $missingId
    $c2Close = Invoke-Topic04Close -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $missingAuthority -Status 'accepted' -CandidateId 'C2' -SessionRef 'codex:missing-owner'
    Assert-Topic04EvidenceFailure -Result $c2Close -Code 'AT-ACCEPTANCE-EVIDENCE' -Scenario 'C1 evidence cannot satisfy C2'

    $cancel = Invoke-Topic04Close -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $missingAuthority -Status 'cancelled' -Reason 'User stopped this fixture.' -SessionRef 'codex:missing-owner'
    Assert-Topic04Evidence ($cancel.ExitCode -eq 0 -and $cancel.Parsed.data.status -ceq 'cancelled') 'Cancelled terminal state must require only a compact reason.'
    $cancelled = Get-Topic04EvidenceAuthority -Context $context -TaskId $missingId
    Assert-Topic04Evidence ($null -eq $cancelled.Revision.accepted_candidate_id) 'Cancellation must not claim an accepted candidate.'

    $blockedCreate = New-Topic04EvidenceTask -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Objective 'Terminally blocked fixture.' -Obligations @() -SessionRef 'codex:blocked-owner'
    $blockedId = [string]$blockedCreate.Parsed.data.task_id
    $blockedAuthority = Get-Topic04EvidenceAuthority -Context $context -TaskId $blockedId
    $missingReason = Invoke-Topic04Close -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $blockedAuthority -Status 'terminally_blocked' -SessionRef 'codex:blocked-owner'
    Assert-Topic04EvidenceFailure -Result $missingReason -Code 'AT-TERMINAL-REASON' -Scenario 'terminally blocked without reason'
    $blocked = Invoke-Topic04Close -CliPath $cliPath -FixtureRoot $fixture -Repository $repository -Authority $blockedAuthority -Status 'terminally_blocked' -Reason 'Required external authority is unavailable.' -SessionRef 'codex:blocked-owner'
    Assert-Topic04Evidence ($blocked.ExitCode -eq 0 -and $blocked.Parsed.data.status -ceq 'terminally_blocked') 'Terminally blocked task must close with a compact reason and no candidate.'

    Write-Host ("PASS Topic 04 state evidence ({0} assertions)" -f $script:Assertions) -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("FAIL [AT-TEST-EVIDENCE] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    Remove-Topic04FixtureRoots
}
