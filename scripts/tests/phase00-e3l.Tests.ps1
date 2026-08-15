#Requires -Version 5.1

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$transportPath = Join-Path $repositoryRoot 'scripts\lib\phase00-e3il-transport.ps1'
$e3lHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-e3l-evidence.ps1'
$phase00SpecPath = Join-Path $repositoryRoot 'spec\phases\phase-00-foundation.md'
$isolationSpecPath = Join-Path $repositoryRoot 'spec\08-isolation-and-concurrency.md'
$validationSpecPath = Join-Path $repositoryRoot 'spec\13-validation-and-evaluation.md'
$phase02SpecPath = Join-Path $repositoryRoot 'spec\phases\phase-02-core-orchestration.md'
$manifestPath = Join-Path $repositoryRoot 'docs\evidence\phase-00\manifest.yml'
$pinnedOmpSourceRoot = Join-Path $repositoryRoot '_research\upstreams\oh-my-pi'
$sourceIdentityPath = Join-Path $repositoryRoot `
    'docs\evidence\phase-00\E3-L\source-identity.json'
$jointRunnerPath = Join-Path $repositoryRoot 'scripts\run-phase00-e3l-joint.ps1'
$phase00EvidencePath = Join-Path $repositoryRoot 'scripts\lib\phase00-evidence.ps1'
$script:e3ilTransportLoaded = $false
$script:e3lHelperLoaded = $false
$script:e3lJointRunnerLoaded = $false

if (Test-Path -LiteralPath $transportPath -PathType Leaf) {
    . $transportPath
    $script:e3ilTransportLoaded = $true
}
if (Test-Path -LiteralPath $e3lHelperPath -PathType Leaf) {
    . $e3lHelperPath
    $script:e3lHelperLoaded = $true
}
if (Test-Path -LiteralPath $jointRunnerPath -PathType Leaf) {
    . $jointRunnerPath
    $script:e3lJointRunnerLoaded = $true
}
. $phase00EvidencePath

function New-E3LTransportStart([string]$Id, [string]$Name, $Arguments) {
    [pscustomobject][ordered]@{
        type = 'tool_execution_start'
        toolCallId = $Id
        toolName = $Name
        args = $Arguments
    }
}

function Read-E3LJsonLines([string]$Path) {
    @(Get-Content -LiteralPath $Path -Encoding UTF8 | ForEach-Object {
        $_ | ConvertFrom-Json
    })
}

function Get-E3LAttemptCanaryEvents([int]$Attempt) {
    $rawRoot = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-I\raw'
    $events = [ordered]@{}
    foreach ($id in @(
        'e3i-project-1','e3i-project-2','e3i-project-3',
        'e3i-runtime-1','e3i-runtime-2','e3i-runtime-3'
    )) {
        $path = Join-Path $rawRoot `
            ("session-a-attempt-{0:D3}.canary.$id.jsonl" -f $Attempt)
        $events[$id] = @(Read-E3LJsonLines $path)
    }
    $events
}

function New-E3LTransportEnd([string]$Id, [string]$Name, $Result) {
    [pscustomobject][ordered]@{
        type = 'tool_execution_end'
        toolCallId = $Id
        toolName = $Name
        result = $Result
        isError = $false
    }
}

function New-E3LTransportTextResult([string]$Text, $Details = $null) {
    $result = [ordered]@{
        content = @([ordered]@{ type = 'text'; text = $Text })
    }
    if ($null -ne $Details) { $result.details = $Details }
    [pscustomobject]$result
}

function New-E3LTransportReaderEvents([string]$Id, [bool]$Value) {
    $details = [ordered]@{
        probe = 'phase00-e3l-live-reader-v1'
        setting = 'task.isolation.apply'
        operation = 'pi.pi.settings.get'
        value = $Value
        scope = 'parent-only'
    }
    @(
        New-E3LTransportStart $Id 'phase00_e3l_read_apply' ([ordered]@{})
        New-E3LTransportEnd $Id 'phase00_e3l_read_apply' `
            (New-E3LTransportTextResult ($details | ConvertTo-Json -Compress) $details)
    )
}

function New-E3LTransportDiagnosticEvents([string]$Id) {
    $json = '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"Automatically apply successful isolated task changes"}'
    @(
        New-E3LTransportStart $Id 'bash' ([ordered]@{
            command = 'omp config get task.isolation.apply --json'
            timeout = [int]60
        })
        New-E3LTransportEnd $Id 'bash' `
            (New-E3LTransportTextResult "$json`n`n`nWall time: 0.12 seconds")
    )
}

function New-E3LTransportTaskEvents(
    [string]$Id,
    [ValidateSet('APPLY_FALSE_CAPTURE_ONLY','APPLY_TRUE_NO_DIFF')][string]$Branch
) {
    $summary = if ($Branch -eq 'APPLY_FALSE_CAPTURE_ONLY') {
        'Isolation: no changes captured.'
    } else {
        'No changes to apply.'
    }
    $details = [ordered]@{
        results = @([ordered]@{
            id = $Id
            durationMs = 100
            tokens = 10
            requests = 1
            resolvedModel = 'test/model'
            exitCode = 0
            aborted = $false
            output = '{"acknowledgement":"PHASE00_E3I_CANARY_OK"}'
        })
    }
    @(
        New-E3LTransportStart "call-$Id" 'task' ([ordered]@{
            context = 'Phase 00 E3-I sequential behavioral canary'
            tasks = @([ordered]@{
                name = $Id
                agent = 'phase00-e3i-canary'
                task = 'Submit the exact acknowledgement required by your agent contract through its required terminal yield. Do not call any other tool.'
                isolated = $true
            })
        })
        New-E3LTransportEnd "call-$Id" 'task' `
            (New-E3LTransportTextResult "<merge-summary>$summary</merge-summary>" $details)
    )
}

function New-E3LTransportOverrideEvents {
    $details = [ordered]@{
        probe = 'phase00-e3i-runtime-override-v1'
        setting = 'task.isolation.apply'
        before = $false
        operation = 'pi.pi.settings.override'
        requested = $true
        after = $true
        calledSet = $false
        calledFlushOrSave = $false
        scope = 'parent-only'
    }
    @(
        New-E3LTransportStart 'call-override' 'phase00_e3i_override_apply_true' ([ordered]@{})
        New-E3LTransportEnd 'call-override' 'phase00_e3i_override_apply_true' `
            (New-E3LTransportTextResult ($details | ConvertTo-Json -Compress) $details)
    )
}

function New-E3LTransportCanaryEvents {
    @(
        [pscustomobject][ordered]@{
            type = 'session_init'
            agent = 'phase00-e3i-canary'
            tools = @('read','yield','hub')
            readOnly = $true
        }
        [pscustomobject][ordered]@{
            type = 'message'
            message = [ordered]@{
                role = 'assistant'
                content = @([ordered]@{
                    type = 'toolCall'
                    name = 'yield'
                    arguments = [ordered]@{
                        type = 'result'
                        result = [ordered]@{
                            data = [ordered]@{
                                acknowledgement = 'PHASE00_E3I_CANARY_OK'
                            }
                        }
                    }
                })
            }
        }
        [pscustomobject][ordered]@{ type = 'agent_end'; isTerminal = $true }
    )
}

function New-E3LTransportFixture([ValidateSet('A','B')][string]$Session) {
    $events = @()
    $canaries = @{}
    if ($Session -eq 'A') {
        $events += New-E3LTransportReaderEvents 'call-reader-l1' $false
        $events += New-E3LTransportDiagnosticEvents 'call-diagnostic-l1'
        foreach ($id in @('e3i-project-1','e3i-project-2','e3i-project-3')) {
            $events += New-E3LTransportTaskEvents $id APPLY_FALSE_CAPTURE_ONLY
            $canaries[$id] = @(New-E3LTransportCanaryEvents)
        }
        $events += New-E3LTransportOverrideEvents
        $events += New-E3LTransportReaderEvents 'call-reader-l3' $true
        $events += New-E3LTransportDiagnosticEvents 'call-diagnostic-l3'
        foreach ($id in @('e3i-runtime-1','e3i-runtime-2','e3i-runtime-3')) {
            $events += New-E3LTransportTaskEvents $id APPLY_TRUE_NO_DIFF
            $canaries[$id] = @(New-E3LTransportCanaryEvents)
        }
    } else {
        $events += New-E3LTransportReaderEvents 'call-reader-l2' $true
        $events += New-E3LTransportDiagnosticEvents 'call-diagnostic-l2'
        foreach ($id in @('e3i-cli-1','e3i-cli-2','e3i-cli-3')) {
            $events += New-E3LTransportTaskEvents $id APPLY_TRUE_NO_DIFF
            $canaries[$id] = @(New-E3LTransportCanaryEvents)
        }
    }
    [pscustomobject][ordered]@{
        ParentEvents = @($events)
        CanaryEvents = $canaries
    }
}

function New-E3LTransportBoundary {
    [pscustomobject][ordered]@{
        ParentContentUnchanged = $true
        ParentHeadUnchanged = $true
        ParentStatusUnchanged = $true
        FixtureHashesUnchanged = $true
        LiveHomeUnchanged = $true
        CleanupSucceeded = $true
    }
}

function New-E3LReaderToolResult($Value) {
    $details = [ordered]@{
        probe = 'phase00-e3l-live-reader-v1'
        setting = 'task.isolation.apply'
        operation = 'pi.pi.settings.get'
        value = $Value
        scope = 'parent-only'
    }
    New-E3LTransportTextResult ($details | ConvertTo-Json -Compress) $details
}

function Set-E3LReaderEventResult($Fixture, [int]$ReaderOrdinal, $Value) {
    $readerEnds = @($Fixture.ParentEvents | Where-Object {
        $_.type -eq 'tool_execution_end' -and
        $_.toolName -eq 'phase00_e3l_read_apply'
    })
    $readerEnds[$ReaderOrdinal].result = New-E3LReaderToolResult $Value
}

function Set-E3LEnvelopeMetadata($Envelope, [int]$Attempt = 5) {
    $metadata = [ordered]@{
        Attempt = $Attempt
        Selected = $true
        RuntimeVersion = 'omp/17.2.10'
        RuntimeSha256 = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
        SupportedHost = 'OMP-owned default main-CLI root-session construction class'
    }
    foreach ($name in $metadata.Keys) {
        $Envelope | Add-Member NoteProperty $name $metadata[$name] -Force
    }
    $Envelope
}

function New-E3LEligibleEnvelope(
    [ValidateSet('A','B')][string]$Session,
    $Fixture = $null,
    [int]$Attempt = 5
) {
    if ($null -eq $Fixture) { $Fixture = New-E3LTransportFixture $Session }
    $transport = Test-Phase00E3ILSessionTransport -Session $Session `
        -ParentEvents $Fixture.ParentEvents -CanaryEvents $Fixture.CanaryEvents
    $envelope = Test-Phase00E3ILSelectionEnvelope -SessionTransport $transport `
        -Boundary (New-E3LTransportBoundary) `
        -LiveHomeMutationAttributable $false -CleanupError ''
    Set-E3LEnvelopeMetadata $envelope $Attempt
}

function New-E3LSourceIdentityStub(
    [ValidateSet('PASS','FAIL','INVALID_RUN')][string]$Status = 'PASS'
) {
    [pscustomobject][ordered]@{
        Status = $Status
        Reasons = if ($Status -eq 'PASS') { @() } else { @('SOURCE_STUB_REASON') }
        RuntimeVersion = 'omp/17.2.10'
        RuntimeSha256 = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
        PinnedCommit = '3a8591a8af5b6d200088d12ca75a5517cb064fa8'
        SupportedHost = 'OMP-owned default main-CLI root-session construction class'
        ReaderOperation = 'pi.pi.settings.get("task.isolation.apply")'
        PositiveLinks = @(1..7 | ForEach-Object { [pscustomobject]@{ Id = "L$_" } })
        Exclusions = @(
            'ACP_SESSION_NEW','CLONE_FOR_CWD','SDK_SETTINGS_INJECTION',
            'MAIN_DEPENDENCY_INJECTION','RPC_PROTOCOL','RPC_UI_PROTOCOL'
        )
    }
}

function Get-E3LPinnedExecutable {
    $expected = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
    $installed = (Get-Command omp -ErrorAction Stop).Source
    $candidates = @(
        $installed
        @(Get-ChildItem -LiteralPath (Split-Path -Parent $installed) -File `
            -Filter 'omp.exe*.bak' -ErrorAction SilentlyContinue | ForEach-Object FullName)
    ) | Select-Object -Unique
    foreach ($candidate in $candidates) {
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $candidate).Hash -eq $expected) {
            return $candidate
        }
    }
    throw 'Pinned 17.2.10 executable is unavailable for E3-L runner tests.'
}

function New-E3LMockSessionResult(
    [ValidateSet('A','B')][string]$Session,
    [string]$EvidenceRoot,
    [int]$Attempt,
    [ValidateSet('ELIGIBLE','INVALID_RUN','BLOCKED_ENVIRONMENT')]
    [string]$SelectionStatus = 'ELIGIBLE',
    [ValidateSet('PASS','FAIL','INVALID_RUN','BLOCKED_ENVIRONMENT')]
    [string]$AnalysisStatus = 'PASS'
) {
    $rawRoot = Join-Path $EvidenceRoot 'E3-I\raw'
    [IO.Directory]::CreateDirectory($rawRoot) | Out-Null
    $stem = "session-$($Session.ToLowerInvariant())-attempt-{0:D3}" -f $Attempt
    $stdout = Join-Path $rawRoot "$stem.stdout.jsonl"
    $stderr = Join-Path $rawRoot "$stem.stderr.txt"
    $run = Join-Path $rawRoot "$stem.run.json"
    [IO.File]::WriteAllText($stdout, "{}`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($stderr, '', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($run, '{"selected":false}', [Text.UTF8Encoding]::new($false))
    $ids = if ($Session -eq 'A') {
        @(
            'e3i-project-1','e3i-project-2','e3i-project-3',
            'e3i-runtime-1','e3i-runtime-2','e3i-runtime-3'
        )
    } else { @('e3i-cli-1','e3i-cli-2','e3i-cli-3') }
    $canaries = @($ids | ForEach-Object {
        $path = Join-Path $rawRoot "$stem.canary.$_.jsonl"
        [IO.File]::WriteAllText($path, "{}`n", [Text.UTF8Encoding]::new($false))
        [pscustomobject]@{ Id = $_; Path = $path; Sha256 = (Get-FileHash $path).Hash }
    })
    $selection = if ($SelectionStatus -eq 'ELIGIBLE') {
        New-E3LEligibleEnvelope $Session $null $Attempt
    } else {
        [pscustomobject]@{ Status = $SelectionStatus; Reasons = @("MOCK_$SelectionStatus") }
    }
    [pscustomobject][ordered]@{
        Session = $Session
        Attempt = $Attempt
        Analysis = [pscustomobject]@{ Status = $AnalysisStatus; Reasons = @("MOCK_$AnalysisStatus") }
        SelectionEnvelope = $selection
        Boundary = New-E3LTransportBoundary
        LiveHomeMutationAttributable = $false
        CleanupError = ''
        StdoutPath = $stdout
        StderrPath = $stderr
        RunPath = $run
        CanaryArtifacts = $canaries
        CleanupSucceeded = $true
    }
}

function Write-E3LTestJson([string]$Path, $Value) {
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
    [IO.File]::WriteAllText(
        $Path,
        ($Value | ConvertTo-Json -Depth 20) + "`n",
        [Text.UTF8Encoding]::new($false)
    )
}

function Set-E3LFixtureManifestEntry(
    [string]$Root,
    [string]$State,
    [string[]]$Artifacts
) {
    $path = Join-Path $Root 'docs\evidence\phase-00\manifest.yml'
    $lines = @([IO.File]::ReadAllLines($path))
    $artifactText = '[' + ($Artifacts -join ', ') + ']'
    $start = [Array]::IndexOf($lines, '  - id: E3-L')
    $end = [Array]::IndexOf($lines, '  - id: E3-M')
    if ($start -lt 0 -or $end -le $start) { throw 'E3-L manifest fixture anchors missing.' }
    $replacement = @(
        '  - id: E3-L',
        '    kind: experiment',
        "    state: $State",
        '    depends_on: [E3-A, E3-H]',
        "    artifacts: $artifactText",
        '    decision: "E3-L terminal fixture"'
    )
    $updated = @($lines[0..($start - 1)] + $replacement + $lines[$end..($lines.Count - 1)])
    [IO.File]::WriteAllLines($path, $updated, [Text.UTF8Encoding]::new($false))
}

function New-E3LDurableFixture(
    [ValidateSet('READY','PASS','FAIL','BLOCKED_ENVIRONMENT')][string]$State
) {
    $root = Join-Path ([IO.Path]::GetTempPath()) `
        ("omp-phase00-e3l-durable-{0}" -f [guid]::NewGuid().ToString('N'))
    $phaseRoot = Join-Path $root 'docs\evidence\phase-00'
    $e3lRoot = Join-Path $phaseRoot 'E3-L'
    [IO.Directory]::CreateDirectory($e3lRoot) | Out-Null
    Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $phaseRoot 'manifest.yml')
    Copy-Item -LiteralPath $sourceIdentityPath `
        -Destination (Join-Path $e3lRoot 'source-identity.json')
    if ($State -eq 'READY') {
        Set-E3LFixtureManifestEntry $root READY @()
        return $root
    }

    $attempt = 5
    $sourceRelative = 'docs/evidence/phase-00/E3-L/source-identity.json'
    $sourceHash = (Get-FileHash -Algorithm SHA256 `
        (Join-Path $e3lRoot 'source-identity.json')).Hash
    if ($State -eq 'BLOCKED_ENVIRONMENT') {
        $blockRawRoot = Join-Path $root 'docs\evidence\phase-00\E3-I\raw'
        [IO.Directory]::CreateDirectory($blockRawRoot) | Out-Null
        $blockRefs = @{}
        foreach ($name in @('run.json','stdout.jsonl','stderr.txt')) {
            $blockPath = Join-Path $blockRawRoot "session-a-attempt-005.$name"
            [IO.File]::WriteAllText($blockPath, "{}`n", `
                [Text.UTF8Encoding]::new($false))
            $blockRefs[$name] = [ordered]@{
                path = ConvertTo-Phase00E3ILRelativeEvidencePath $blockPath $phaseRoot
                sha256 = (Get-FileHash -Algorithm SHA256 $blockPath).Hash
            }
        }
        $jointRelative = 'docs/evidence/phase-00/E3-L/raw/joint-attempt-005.json'
        $jointPath = Join-Path $root $jointRelative
        $jointRecord = [ordered]@{
            schema_version = 1; experiment = 'E3-I+E3-L'; attempt = $attempt
            selected = $false
            runtime = [ordered]@{
                version = 'omp/17.2.10'
                sha256 = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
            }
            source_identity = [ordered]@{ path = $sourceRelative; sha256 = $sourceHash }
            sessions = [ordered]@{
                a = [ordered]@{
                    invoked = $true; transport_status = 'BLOCKED_ENVIRONMENT'
                    run = $blockRefs['run.json']
                    parent_stdout = $blockRefs['stdout.jsonl']
                    parent_stderr = $blockRefs['stderr.txt']
                    canaries = @()
                }
                b = [ordered]@{ invoked = $false; skip_reason = 'A_BLOCKED_ENVIRONMENT' }
            }
            automatic_retry = $false
            e3_i_conclusion_consumed = $false
            e3_l_conclusion_consumed = $false
        }
        Write-E3LTestJson $jointPath $jointRecord
        $jointHash = (Get-FileHash -Algorithm SHA256 $jointPath).Hash
        $adjudicationRelative = `
            'docs/evidence/phase-00/E3-L/raw/joint-attempt-005.adjudication.json'
        $adjudicationPath = Join-Path $root $adjudicationRelative
        $adjudicationRecord = $jointRecord | ConvertTo-Json -Depth 20 | ConvertFrom-Json
        $adjudicationRecord | Add-Member NoteProperty correction_of ([ordered]@{
            path = $jointRelative
            sha256 = $jointHash
        })
        $adjudicationRecord | Add-Member NoteProperty correction_reason `
            'E3IL_RETRY_FACT_UNDER_REPORTED'
        $adjudicationRecord.sessions.a | Add-Member NoteProperty `
            recovered_provider_retry $true
        Write-E3LTestJson $adjudicationPath $adjudicationRecord
        $adjudicationHash = (Get-FileHash -Algorithm SHA256 $adjudicationPath).Hash
        $conclusionRelative = 'docs/evidence/phase-00/E3-L/conclusion.json'
        Write-E3LTestJson (Join-Path $root $conclusionRelative) ([ordered]@{
            schema_version = 1; experiment = 'E3-L'; state = $State; attempt = $attempt
            joint_adjudication = [ordered]@{
                path = $adjudicationRelative; sha256 = $adjudicationHash
            }
            parallel_authorized = $false; parallel_mode_after = 'DISABLED'
            e3_m_replaced = $false; incomplete_markers = @()
        })
        Set-E3LFixtureManifestEntry $root $State `
            @($adjudicationRelative,$conclusionRelative)
        return $root
    }

    $rawRoot = Join-Path $e3lRoot 'raw'
    [IO.Directory]::CreateDirectory($rawRoot) | Out-Null
    $rawPaths = @(
        Join-Path $rawRoot 'session-a-attempt-005.stdout.jsonl'
        Join-Path $rawRoot 'session-b-attempt-005.stdout.jsonl'
    )
    [IO.File]::WriteAllText($rawPaths[0], "{}`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($rawPaths[1], "{}`n", [Text.UTF8Encoding]::new($false))
    $caseRows = @(
        [ordered]@{
            name = 'L1'; status = $State; reader_value = $false; child_value = $false
            task_branches = @('APPLY_FALSE_CAPTURE_ONLY') * 3
        },
        [ordered]@{
            name = 'L2'; status = $State; reader_value = $true; child_value = $false
            task_branches = @('APPLY_TRUE_NO_DIFF') * 3
        },
        [ordered]@{
            name = 'L3'; status = $State; reader_value = $true; child_value = $false
            task_branches = @('APPLY_TRUE_NO_DIFF') * 3
        }
    )
    $projectionRelative = 'docs/evidence/phase-00/E3-L/selected-transaction.json'
    $projectionPath = Join-Path $root $projectionRelative
    Write-E3LTestJson $projectionPath ([ordered]@{
        schema_version = 1; experiment = 'E3-L'; status = $State; selected = $true
        attempt = $attempt
        source_identity = [ordered]@{ path = $sourceRelative; sha256 = $sourceHash }
        runtime = [ordered]@{
            version = 'omp/17.2.10'
            sha256 = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
        }
        supported_host = 'OMP-owned default main-CLI root-session construction class'
        raw_inputs = @($rawPaths | ForEach-Object {
            [ordered]@{
                path = ConvertTo-Phase00E3ILRelativeEvidencePath $_ $phaseRoot
                sha256 = (Get-FileHash -Algorithm SHA256 $_).Hash
            }
        })
        cases = $caseRows
        transport = [ordered]@{ a = 'ELIGIBLE'; b = 'ELIGIBLE' }
        boundaries = [ordered]@{ a = 'PASS'; b = 'PASS' }
        oracle_statuses = [ordered]@{ session_a = $State; session_b = $State; transaction = $State }
    })
    $projectionHash = (Get-FileHash -Algorithm SHA256 $projectionPath).Hash
    $caseReferences = @()
    foreach ($case in $caseRows) {
        $relative = "docs/evidence/phase-00/E3-L/$($case.name).json"
        $path = Join-Path $root $relative
        Write-E3LTestJson $path ([ordered]@{
            schema_version = 1; experiment = 'E3-L'; case = $case.name
            state = $State; attempt = $attempt
            selected_transaction = [ordered]@{
                path = $projectionRelative; sha256 = $projectionHash
            }
            observation = [ordered]@{
                reader_value = $case.reader_value; child_value = $case.child_value
                task_branches = $case.task_branches
            }
        })
        $caseReferences += [ordered]@{
            name = $case.name; path = $relative
            sha256 = (Get-FileHash -Algorithm SHA256 $path).Hash
        }
    }
    $conclusionRelative = 'docs/evidence/phase-00/E3-L/conclusion.json'
    Write-E3LTestJson (Join-Path $root $conclusionRelative) ([ordered]@{
        schema_version = 1; experiment = 'E3-L'; state = $State; attempt = $attempt
        source_identity = [ordered]@{ path = $sourceRelative; sha256 = $sourceHash }
        selected_transaction = [ordered]@{ path = $projectionRelative; sha256 = $projectionHash }
        cases = $caseReferences
        supported_host = 'OMP-owned default main-CLI root-session construction class'
        runtime_version = 'omp/17.2.10'
        parallel_authorized = $false; parallel_mode_after = 'DISABLED'
        e3_m_replaced = $false; incomplete_markers = @()
        opus_peer_review = 'PENDING_QUOTA'
        claim = if ($State -eq 'PASS') {
            'The approved proxy observes live effective task.isolation.apply for the OMP-owned default main-CLI root-session class on pinned 17.2.10.'
        } else { $null }
    })
    $artifacts = @(
        $sourceRelative,$projectionRelative,
        'docs/evidence/phase-00/E3-L/L1.json',
        'docs/evidence/phase-00/E3-L/L2.json',
        'docs/evidence/phase-00/E3-L/L3.json',
        $conclusionRelative
    )
    Set-E3LFixtureManifestEntry $root $State $artifacts
    $root
}

function Test-E3LContractHasFailure([string]$Root) {
    @((Test-Phase00E3LArtifactContract -RepositoryRoot $Root) |
        Where-Object Status -eq 'FAIL').Count -gt 0
}

function Remove-E3LTestTree([string]$Path) {
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')
    $resolved = [IO.Path]::GetFullPath($Path).TrimEnd('\','/')
    $prefix = $tempRoot + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing non-temporary E3-L test cleanup: $resolved"
    }
    if (Test-Path -LiteralPath $resolved) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

function New-E3LSyntheticSourceTree {
    $root = Join-Path ([IO.Path]::GetTempPath()) `
        ("omp-phase00-e3l-source-{0}" -f [guid]::NewGuid().ToString('N'))
    $relativePaths = @(
        'packages/coding-agent/src/index.ts'
        'packages/coding-agent/src/config/settings.ts'
        'packages/coding-agent/src/main.ts'
        'packages/coding-agent/src/sdk.ts'
        'packages/coding-agent/src/task/structured-subagent.ts'
    )
    foreach ($relativePath in $relativePaths) {
        $source = Join-Path $pinnedOmpSourceRoot $relativePath
        $destination = Join-Path $root $relativePath
        [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination
    }
    $root
}

function Replace-E3LSyntheticSourceText(
    [string]$Root,
    [string]$RelativePath,
    [string]$Before,
    [string]$After
) {
    $path = Join-Path $Root $RelativePath
    $text = [IO.File]::ReadAllText($path)
    if (-not $text.Contains($Before)) {
        throw "Synthetic mutation anchor missing: $RelativePath :: $Before"
    }
    [IO.File]::WriteAllText(
        $path,
        $text.Replace($Before, $After),
        [Text.UTF8Encoding]::new($false)
    )
}

Describe 'E3-L normative contract' {
    It 'selects the scoped proxy and corrected non-persistent override case' {
        $phase00 = Get-Content -Raw -LiteralPath $phase00SpecPath -Encoding UTF8
        $isolation = Get-Content -Raw -LiteralPath $isolationSpecPath -Encoding UTF8
        $validation = Get-Content -Raw -LiteralPath $validationSpecPath -Encoding UTF8
        $phase02 = Get-Content -Raw -LiteralPath $phase02SpecPath -Encoding UTF8

        $phase00 | Should Match ([regex]::Escape(
            'pi.pi.settings.get("task.isolation.apply")'))
        $phase00 | Should Match ([regex]::Escape(
            'Settings.override("task.isolation.apply", true)'))
        $phase00 | Should Match ([regex]::Escape(
            'OMP-owned default main-CLI root-session construction class'))
        $phase00 | Should Match 'parallel_mode:\s*DISABLED'

        $isolation | Should Match ([regex]::Escape(
            'pi.pi.settings.get("task.isolation.apply")'))
        $isolation | Should Match ([regex]::Escape(
            'OMP-owned default main-CLI root-session construction class'))
        $isolation | Should Match 'Settings\.set\(\).*queues persistence'
        $isolation | Should Match 'Settings\.override\(\).*non-persistent'

        $validation | Should Match ([regex]::Escape(
            'OMP-owned default main-CLI root-session construction class'))
        $phase02 | Should Match ([regex]::Escape(
            'OMP-owned default main-CLI root-session construction class'))
    }

    It 'retires impossible and universal E3-L claims' {
        $combined = @(
            Get-Content -Raw -LiteralPath $phase00SpecPath -Encoding UTF8
            Get-Content -Raw -LiteralPath $isolationSpecPath -Encoding UTF8
        ) -join "`n"

        $combined | Should Not Match ([regex]::Escape(
            'change via /settings mid-session (Settings.set())'))
        $combined | Should Not Match ([regex]::Escape(
            'E3-L remains unresolved until an alternative public surface is designed and reviewed'))
        $combined | Should Not Match ([regex]::Escape(
            'source-verified for every supported host'))
    }

    It 'records bounded PASS while E3-M remains the disabled parallel gate' {
        . (Join-Path $repositoryRoot 'scripts\lib\phase00-evidence.ps1')
        $manifest = Read-Phase00Manifest -Path $manifestPath
        $entries = @{}
        foreach ($entry in @($manifest.Entries)) { $entries[$entry.id] = $entry }

        $entries['E3-L'].state | Should Be 'PASS'
        @($entries['E3-L'].artifacts).Count | Should Be 6
        $entries['E3-M'].state | Should Be 'DEFERRED_PARALLEL_DISABLED'
        $manifest.parallel_mode | Should Be 'DISABLED'
    }
}

Describe 'E3-L implementation interfaces' {
    It 'loads the shared transport and independent E3-L evidence helpers' {
        $script:e3ilTransportLoaded | Should Be $true
        $script:e3lHelperLoaded | Should Be $true
    }
}

Describe 'E3-L pinned source identity' {
    It 'rejects wrong Git commit, dirty state, and wrong origin independently' {
        $pinnedCommit = '3a8591a8af5b6d200088d12ca75a5517cb064fa8'
        $officialOrigin = 'https://github.com/can1357/oh-my-pi.git'

        @((Test-Phase00E3LGitIdentity -Head ('0' * 40) -StatusLines @() `
            -Origin $officialOrigin).Reasons) -contains 'E3L_SOURCE_COMMIT_MISMATCH' |
            Should Be $true
        @((Test-Phase00E3LGitIdentity -Head $pinnedCommit `
            -StatusLines @(' M main.ts') -Origin $officialOrigin).Reasons) `
            -contains 'E3L_SOURCE_TREE_DIRTY' | Should Be $true
        @((Test-Phase00E3LGitIdentity -Head $pinnedCommit -StatusLines @() `
            -Origin 'https://example.invalid/fork.git').Reasons) `
            -contains 'E3L_SOURCE_ORIGIN_MISMATCH' | Should Be $true
    }

    It 'accepts exactly seven positive links and all bounded-host exclusions' {
        $root = New-E3LSyntheticSourceTree
        try {
            $result = Test-Phase00E3LSourceLinks -OmpSourceRoot $root
            $result.Status | Should Be 'PASS'
            @($result.PositiveLinks).Count | Should Be 7
            (@($result.PositiveLinks.Id) -join ',') | Should Be `
                'EXPORT,GLOBAL_INIT,MAIN_INIT,SESSION_OPTIONS,SDK_EXPLICIT_SETTINGS,TASK_DISPATCH,GLOBAL_PROXY'
            (@($result.Exclusions.Id) -join ',') | Should Be `
                'ACP_SESSION_NEW,CLONE_FOR_CWD,SDK_SETTINGS_INJECTION,MAIN_DEPENDENCY_INJECTION,RPC_PROTOCOL,RPC_UI_PROTOCOL'
        } finally {
            Remove-E3LTestTree $root
        }
    }

    It 'fails every complete positive-link source contradiction' {
        $cases = @(
            @('packages/coding-agent/src/index.ts',
              'export { Settings, settings } from "./config/settings";',
              'export { Settings } from "./config/settings";',
              'E3L_SOURCE_EXPORT_CONTRADICTION'),
            @('packages/coding-agent/src/config/settings.ts',
              'globalInstance = instance;', 'globalInstance = new Settings();',
              'E3L_SOURCE_INIT_CONTRADICTION'),
            @('packages/coding-agent/src/config/settings.ts',
              'return instance;', 'return new Settings();',
              'E3L_SOURCE_INIT_CONTRADICTION'),
            @('packages/coding-agent/src/main.ts',
              'deps.settings ?? (await logger.time("settings:init", Settings.init, { cwd, configFiles: parsedArgs.config }))',
              'deps.settings', 'E3L_SOURCE_MAIN_INIT_CONTRADICTION'),
            @('packages/coding-agent/src/main.ts',
              'sessionOptions.settings = settingsInstance;',
              'sessionOptions.settings = deps.settings;',
              'E3L_SOURCE_SESSION_OPTIONS_CONTRADICTION'),
            @('packages/coding-agent/src/sdk.ts',
              'options.settings ??', 'undefined ??',
              'E3L_SOURCE_SDK_SETTINGS_CONTRADICTION'),
            @('packages/coding-agent/src/task/structured-subagent.ts',
              'request.session.settings.get("task.isolation.apply")',
              'request.session.settings.get("task.isolation.parallel")',
              'E3L_SOURCE_DISPATCH_CONTRADICTION'),
            @('packages/coding-agent/src/config/settings.ts',
              'value.bind(globalInstance)', 'value.bind({})',
              'E3L_SOURCE_PROXY_CONTRADICTION')
        )
        foreach ($case in $cases) {
            $root = New-E3LSyntheticSourceTree
            try {
                Replace-E3LSyntheticSourceText $root $case[0] $case[1] $case[2]
                $result = Test-Phase00E3LSourceLinks -OmpSourceRoot $root
                $result.Status | Should Be 'FAIL'
                @($result.Reasons) -contains $case[3] | Should Be $true
            } finally {
                Remove-E3LTestTree $root
            }
        }
    }

    It 'fails missing clone, injection, ACP, RPC, and RPC-UI exclusions' {
        $cases = @(
            @('packages/coding-agent/src/main.ts',
              'args.settings.cloneForCwd(cwd)', 'args.settings',
              'E3L_SOURCE_ACP_EXCLUSION_CONTRADICTION'),
            @('packages/coding-agent/src/config/settings.ts',
              'const cloned = new Settings({', 'const cloned = this as Settings; void ({',
              'E3L_SOURCE_CLONE_EXCLUSION_CONTRADICTION'),
            @('packages/coding-agent/src/sdk.ts',
              'options.settingsManager ??', 'undefined ??',
              'E3L_SOURCE_SDK_INJECTION_EXCLUSION_CONTRADICTION'),
            @('packages/coding-agent/src/main.ts',
              'deps.settings ?? (await logger.time("settings:init", Settings.init, { cwd, configFiles: parsedArgs.config }))',
              'await logger.time("settings:init", Settings.init, { cwd, configFiles: parsedArgs.config })',
              'E3L_SOURCE_DEPENDENCY_INJECTION_EXCLUSION_CONTRADICTION'),
            @('packages/coding-agent/src/main.ts',
              'const isProtocolMode = mode === "rpc" || mode === "rpc-ui" || mode === "acp";',
              'const isProtocolMode = mode === "rpc-ui" || mode === "acp";',
              'E3L_SOURCE_RPC_EXCLUSION_CONTRADICTION'),
            @('packages/coding-agent/src/main.ts',
              'const isProtocolMode = mode === "rpc" || mode === "rpc-ui" || mode === "acp";',
              'const isProtocolMode = mode === "rpc" || mode === "acp";',
              'E3L_SOURCE_RPC_UI_EXCLUSION_CONTRADICTION')
        )
        foreach ($case in $cases) {
            $root = New-E3LSyntheticSourceTree
            try {
                Replace-E3LSyntheticSourceText $root $case[0] $case[1] $case[2]
                $result = Test-Phase00E3LSourceLinks -OmpSourceRoot $root
                $result.Status | Should Be 'FAIL'
                @($result.Reasons) -contains $case[3] | Should Be $true
            } finally {
                Remove-E3LTestTree $root
            }
        }
    }

    It 'rejects source paths that escape the audited root' {
        $root = New-E3LSyntheticSourceTree
        try {
            $rejected = $false
            try {
                Get-Phase00E3LSafeSourceFile -OmpSourceRoot $root `
                    -RelativePath '..\outside.ts' | Out-Null
            } catch {
                $rejected = $true
            }
            $rejected | Should Be $true
        } finally {
            Remove-E3LTestTree $root
        }
    }

    It 'captures and re-audits the real pinned source without absolute paths' {
        $identity = Get-Phase00E3LSourceIdentity -OmpSourceRoot $pinnedOmpSourceRoot
        $identity.Status | Should Be 'PASS'
        @($identity.PositiveLinks).Count | Should Be 7
        Test-Path -LiteralPath $sourceIdentityPath -PathType Leaf | Should Be $true

        $raw = Get-Content -Raw -LiteralPath $sourceIdentityPath -Encoding UTF8
        $artifact = $raw | ConvertFrom-Json
        $artifact.status | Should Be 'PASS'
        $artifact.pinned_commit | Should Be '3a8591a8af5b6d200088d12ca75a5517cb064fa8'
        $artifact.supported_host | Should Be `
            'OMP-owned default main-CLI root-session construction class'
        $artifact.reader_operation | Should Be `
            'pi.pi.settings.get("task.isolation.apply")'
        @($artifact.positive_links).Count | Should Be 7
        @($artifact.exclusions).Count | Should Be 6
        foreach ($file in @($artifact.files)) {
            [IO.Path]::IsPathRooted([string]$file.path) | Should Be $false
            (Get-FileHash -Algorithm SHA256 `
                -LiteralPath (Join-Path $pinnedOmpSourceRoot ([string]$file.path))).Hash |
                Should Be ([string]$file.sha256)
        }
        $raw | Should Not Match ([regex]::Escape([IO.Path]::GetFullPath($repositoryRoot)))
        $raw | Should Not Match 'all sessions|all OMP hosts|universal'
    }
}

Describe 'E3-L exact reader and override evidence' {
    It 'accepts only false and true five-field reader results' {
        foreach ($value in @($false,$true)) {
            $result = ConvertFrom-Phase00E3LReaderResult `
                -ToolResult (New-E3LReaderToolResult $value)
            $result.Status | Should Be 'PASS'
            $result.Value | Should Be $value
        }
    }

    It 'invalidates absent, malformed, multi-content, and divergent reader evidence' {
        $absent = [pscustomobject]@{ content = @() }
        (ConvertFrom-Phase00E3LReaderResult $absent).Status | Should Be 'INVALID_RUN'

        $malformed = New-E3LReaderToolResult $false
        $malformed.content[0].text = '{not-json'
        (ConvertFrom-Phase00E3LReaderResult $malformed).Status | Should Be 'INVALID_RUN'

        $multiple = New-E3LReaderToolResult $false
        $multiple.content += [pscustomobject]@{ type = 'text'; text = '{}' }
        (ConvertFrom-Phase00E3LReaderResult $multiple).Status | Should Be 'INVALID_RUN'

        $divergent = New-E3LReaderToolResult $false
        $divergent.content[0].text = `
            ((New-E3LReaderToolResult $true).details | ConvertTo-Json -Compress)
        (ConvertFrom-Phase00E3LReaderResult $divergent).Status | Should Be 'INVALID_RUN'
    }

    It 'fails attributable reader shape, type, probe, key, operation, and scope contradictions' {
        $mutations = @(
            { param($d) $d['extra'] = 'forbidden' },
            { param($d) $d.value = 'false' },
            { param($d) $d.probe = 'wrong-probe' },
            { param($d) $d.setting = 'task.isolation.parallel' },
            { param($d) $d.operation = 'pi.pi.settings.set' },
            { param($d) $d.scope = 'all-hosts' }
        )
        foreach ($mutation in $mutations) {
            $toolResult = New-E3LReaderToolResult $false
            & $mutation $toolResult.details
            $toolResult.content[0].text = $toolResult.details | ConvertTo-Json -Compress
            $result = ConvertFrom-Phase00E3LReaderResult $toolResult
            $result.Status | Should Be 'FAIL'
            @($result.Reasons) -contains 'E3L_READER_CONTRADICTION' |
                Should Be $true
        }
    }

    It 'invalidates non-empty reader arguments and errored completion' {
        $events = @(New-E3LTransportReaderEvents 'reader-pair' $false)
        $pairs = @(Get-Phase00E3ILToolEventPairs $events)
        $pairs[0].Start.args = [ordered]@{ key = 'forbidden' }
        (Test-Phase00E3LReaderPair $pairs[0]).Status | Should Be 'INVALID_RUN'

        $events = @(New-E3LTransportReaderEvents 'reader-pair' $false)
        $events[1].isError = $true
        $pairs = @(Get-Phase00E3ILToolEventPairs $events)
        (Test-Phase00E3LReaderPair $pairs[0]).Status | Should Be 'INVALID_RUN'
    }

    It 'accepts only the exact non-persistent false-to-true override attestation' {
        $fixture = New-E3LTransportFixture A
        $pairs = @(Get-Phase00E3ILToolEventPairs $fixture.ParentEvents)
        $result = ConvertFrom-Phase00E3LOverrideResult `
            (Get-Phase00PropertyValue $pairs[5].End 'result')
        $result.Status | Should Be 'PASS'

        $wrong = Get-Phase00PropertyValue $pairs[5].End 'result'
        $wrong.details.calledSet = $true
        $wrong.content[0].text = $wrong.details | ConvertTo-Json -Compress
        (ConvertFrom-Phase00E3LOverrideResult $wrong).Status | Should Be 'FAIL'
    }
}

Describe 'E3-L independent L1-L3 oracles' {
    It 'passes exactly L1 and L3 in A, L2 in B, and the full transaction' {
        $a = Test-Phase00E3LSessionAOracle (New-E3LEligibleEnvelope A)
        $b = Test-Phase00E3LSessionBOracle (New-E3LEligibleEnvelope B)
        $transaction = Test-Phase00E3LTransaction `
            (New-E3LSourceIdentityStub) $a $b

        $a.Status | Should Be 'PASS'
        (@($a.Cases.Name) -join ',') | Should Be 'L1,L3'
        $b.Status | Should Be 'PASS'
        (@($b.Cases.Name) -join ',') | Should Be 'L2'
        $transaction.Status | Should Be 'PASS'
        (@($transaction.Cases.Name) -join ',') | Should Be 'L1,L2,L3'
        $transaction.Claim | Should Be `
            'The approved proxy observes live effective task.isolation.apply for the OMP-owned default main-CLI root-session class on pinned 17.2.10.'
    }

    It 'fails wrong reader, child, task branch, and override semantics without invalidating transport' {
        $aFixture = New-E3LTransportFixture A
        Set-E3LReaderEventResult $aFixture 0 $true
        (Test-Phase00E3LSessionAOracle `
            (New-E3LEligibleEnvelope A $aFixture)).Status | Should Be 'FAIL'

        $aFixture = New-E3LTransportFixture A
        $diagnosticEnd = @($aFixture.ParentEvents | Where-Object {
            $_.type -eq 'tool_execution_end' -and $_.toolName -eq 'bash'
        })[0]
        $diagnosticEnd.result.content[0].text = `
            '{"key":"task.isolation.apply","value":true,"type":"boolean","description":"Automatically apply successful isolated task changes"}' +
            "`n`n`nWall time: 0.12 seconds"
        (Test-Phase00E3LSessionAOracle `
            (New-E3LEligibleEnvelope A $aFixture)).Status | Should Be 'FAIL'

        $aFixture = New-E3LTransportFixture A
        $firstTaskEnd = @($aFixture.ParentEvents | Where-Object {
            $_.type -eq 'tool_execution_end' -and $_.toolName -eq 'task'
        })[0]
        $firstTaskEnd.result.content[0].text = `
            '<merge-summary>No changes to apply.</merge-summary>'
        (Test-Phase00E3LSessionAOracle `
            (New-E3LEligibleEnvelope A $aFixture)).Status | Should Be 'FAIL'

        $aFixture = New-E3LTransportFixture A
        $overrideEnd = @($aFixture.ParentEvents | Where-Object {
            $_.type -eq 'tool_execution_end' -and
            $_.toolName -eq 'phase00_e3i_override_apply_true'
        })[0]
        $overrideEnd.result.details.calledFlushOrSave = $true
        $overrideEnd.result.content[0].text = `
            $overrideEnd.result.details | ConvertTo-Json -Compress
        (Test-Phase00E3LSessionAOracle `
            (New-E3LEligibleEnvelope A $aFixture)).Status | Should Be 'FAIL'

        $bFixture = New-E3LTransportFixture B
        Set-E3LReaderEventResult $bFixture 0 $false
        (Test-Phase00E3LSessionBOracle `
            (New-E3LEligibleEnvelope B $bFixture)).Status | Should Be 'FAIL'
    }

    It 'applies source, environment, identity, selection, then semantic precedence' {
        $goodA = Test-Phase00E3LSessionAOracle (New-E3LEligibleEnvelope A)
        $goodB = Test-Phase00E3LSessionBOracle (New-E3LEligibleEnvelope B)

        $blockedA = [pscustomobject]@{
            Status = 'BLOCKED_ENVIRONMENT'; Reasons = @('P00-RUNTIME-PROVIDER-OVERLOAD')
        }
        (Test-Phase00E3LTransaction (New-E3LSourceIdentityStub INVALID_RUN) `
            $blockedA $goodB).Status | Should Be 'INVALID_RUN'
        (Test-Phase00E3LTransaction (New-E3LSourceIdentityStub PASS) `
            $blockedA $goodB).Status | Should Be 'BLOCKED_ENVIRONMENT'
        (Test-Phase00E3LTransaction (New-E3LSourceIdentityStub FAIL) `
            $blockedA $goodB).Status | Should Be 'BLOCKED_ENVIRONMENT'

        $wrongRuntimeA = Test-Phase00E3LSessionAOracle (New-E3LEligibleEnvelope A)
        $wrongRuntimeA.RuntimeVersion = 'omp/17.2.12'
        (Test-Phase00E3LTransaction (New-E3LSourceIdentityStub) `
            $wrongRuntimeA $goodB).Status | Should Be 'INVALID_RUN'

        $wrongHashB = Test-Phase00E3LSessionBOracle (New-E3LEligibleEnvelope B)
        $wrongHashB.RuntimeSha256 = ('0' * 64)
        (Test-Phase00E3LTransaction (New-E3LSourceIdentityStub) `
            $goodA $wrongHashB).Status | Should Be 'INVALID_RUN'

        $wrongHostB = Test-Phase00E3LSessionBOracle (New-E3LEligibleEnvelope B)
        $wrongHostB.SupportedHost = 'unsupported-host'
        (Test-Phase00E3LTransaction (New-E3LSourceIdentityStub) `
            $goodA $wrongHostB).Status | Should Be 'INVALID_RUN'

        $crossAttemptB = Test-Phase00E3LSessionBOracle (New-E3LEligibleEnvelope B $null 6)
        (Test-Phase00E3LTransaction (New-E3LSourceIdentityStub) `
            $goodA $crossAttemptB).Status | Should Be 'INVALID_RUN'

        $unselectedA = Test-Phase00E3LSessionAOracle (New-E3LEligibleEnvelope A)
        $unselectedA.Selected = $false
        (Test-Phase00E3LTransaction (New-E3LSourceIdentityStub) `
            $unselectedA $goodB).Status | Should Be 'INVALID_RUN'

        (Test-Phase00E3LTransaction (New-E3LSourceIdentityStub FAIL) `
            $goodA $goodB).Status | Should Be 'FAIL'
    }

    It 'keeps partial, retry, canary-surface, and boundary defects invalid' {
        $aFixture = New-E3LTransportFixture A
        $aFixture.CanaryEvents['e3i-project-1'] += [pscustomobject]@{
            type = 'message_end'
            message = [ordered]@{
                role = 'assistant'; stopReason = 'error'; provider = 'omniroute'
                model = 'test/model'; errorMessage = 'transient retry'
                retryRecovery = [ordered]@{
                    kind = 'auto-retry'; status = 'recovered'; attempt = 1
                }
            }
        }
        $retryTransport = Test-Phase00E3ILSessionTransport A `
            $aFixture.ParentEvents $aFixture.CanaryEvents
        (Test-Phase00E3LSessionAOracle $retryTransport).Status | Should Be 'INVALID_RUN'

        $bFixture = New-E3LTransportFixture B
        $bFixture.CanaryEvents['e3i-cli-1'][0].tools += 'bash'
        $surfaceTransport = Test-Phase00E3ILSessionTransport B `
            $bFixture.ParentEvents $bFixture.CanaryEvents
        (Test-Phase00E3LSessionBOracle $surfaceTransport).Status | Should Be 'INVALID_RUN'

        $partial = [pscustomobject]@{ Status = 'INVALID_RUN'; Reasons = @('PARTIAL_B') }
        (Test-Phase00E3LSessionBOracle $partial).Status | Should Be 'INVALID_RUN'

        $transport = Test-Phase00E3ILSessionTransport A `
            (New-E3LTransportFixture A).ParentEvents `
            (New-E3LTransportFixture A).CanaryEvents
        $boundary = New-E3LTransportBoundary
        $boundary.LiveHomeUnchanged = $false
        $invalidBoundary = Test-Phase00E3ILSelectionEnvelope $transport $boundary `
            $false 'boundary changed'
        (Test-Phase00E3LSessionAOracle $invalidBoundary).Status |
            Should Be 'INVALID_RUN'
    }

    It 'ignores foreign experiment verdicts in both directions' {
        $aEnvelope = New-E3LEligibleEnvelope A
        $bEnvelope = New-E3LEligibleEnvelope B
        $aEnvelope | Add-Member NoteProperty E3IStatus 'FAIL'
        $bEnvelope | Add-Member NoteProperty E3IStatus 'FAIL'
        $a = Test-Phase00E3LSessionAOracle $aEnvelope
        $b = Test-Phase00E3LSessionBOracle $bEnvelope
        (Test-Phase00E3LTransaction (New-E3LSourceIdentityStub) $a $b).Status |
            Should Be 'PASS'

        $badFixture = New-E3LTransportFixture B
        Set-E3LReaderEventResult $badFixture 0 $false
        $badEnvelope = New-E3LEligibleEnvelope B $badFixture
        $badEnvelope | Add-Member NoteProperty E3IStatus 'PASS'
        (Test-Phase00E3LSessionBOracle $badEnvelope).Status | Should Be 'FAIL'

        $helper = Get-Content -Raw -LiteralPath $e3lHelperPath -Encoding UTF8
        $helper | Should Not Match 'E3-I[\\/]conclusion\.yml'
        $helper | Should Not Match 'Test-Phase00E3I(?:Case|Adjudication|Conclusion)'
    }
}

Describe 'E3-L deterministic selected projection' {
    It 'sorts and re-hashes raw inputs while copying only oracle observations' {
        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3l-projection-{0}" -f [guid]::NewGuid().ToString('N'))
        try {
            $rawA = Join-Path $safe 'raw\z-session-a.jsonl'
            $rawB = Join-Path $safe 'raw\a-session-b.jsonl'
            [IO.Directory]::CreateDirectory((Split-Path -Parent $rawA)) | Out-Null
            [IO.File]::WriteAllText($rawA, 'WHOLE_TRANSCRIPT_A_SECRET', `
                [Text.UTF8Encoding]::new($false))
            [IO.File]::WriteAllText($rawB, 'WHOLE_TRANSCRIPT_B_SECRET', `
                [Text.UTF8Encoding]::new($false))
            $source = Join-Path $safe 'source-identity.json'
            Copy-Item -LiteralPath $sourceIdentityPath -Destination $source

            $a = Test-Phase00E3LSessionAOracle (New-E3LEligibleEnvelope A)
            $b = Test-Phase00E3LSessionBOracle (New-E3LEligibleEnvelope B)
            $transaction = Test-Phase00E3LTransaction `
                (New-E3LSourceIdentityStub) $a $b
            $transaction | Add-Member NoteProperty SourceIdentityPath `
                'source-identity.json' -Force
            $transaction | Add-Member NoteProperty SourceIdentitySha256 `
                (Get-FileHash -Algorithm SHA256 $source).Hash -Force

            $first = New-Phase00E3LTransactionProjection -Transaction $transaction `
                -RawInputs @([pscustomobject]@{ Path = $rawA },
                    [pscustomobject]@{ Path = $rawB }) -RepositoryRoot $safe
            $second = New-Phase00E3LTransactionProjection -Transaction $transaction `
                -RawInputs @([pscustomobject]@{ Path = $rawB },
                    [pscustomobject]@{ Path = $rawA }) -RepositoryRoot $safe

            ($first | ConvertTo-Json -Depth 20 -Compress) | Should Be `
                ($second | ConvertTo-Json -Depth 20 -Compress)
            (@($first.raw_inputs.path) -join ',') | Should Be `
                'raw/a-session-b.jsonl,raw/z-session-a.jsonl'
            @($first.cases).Count | Should Be 3
            (@($first.cases.name) -join ',') | Should Be 'L1,L2,L3'
            $first.selected | Should Be $true
            $rendered = $first | ConvertTo-Json -Depth 20
            $rendered | Should Not Match 'WHOLE_TRANSCRIPT|SECRET'
            foreach ($raw in @($first.raw_inputs)) {
                (Get-FileHash -Algorithm SHA256 (Join-Path $safe $raw.path)).Hash |
                    Should Be $raw.sha256
            }

            $forgedRejected = $false
            try {
                New-Phase00E3LTransactionProjection -Transaction $transaction `
                    -RawInputs @([pscustomobject]@{
                        Path = $rawA; Observation = 'caller-forged'
                    }) -RepositoryRoot $safe | Out-Null
            } catch { $forgedRejected = $true }
            $forgedRejected | Should Be $true
        } finally {
            if (Test-Path -LiteralPath $safe) { Remove-E3LTestTree $safe }
        }
    }
}

Describe 'E3-L durable artifact contract' {
    It 'accepts READY with an unlisted source identity and no runtime authority' {
        $root = New-E3LDurableFixture READY
        try {
            $results = @(Test-Phase00E3LArtifactContract -RepositoryRoot $root)
            @($results | Where-Object Status -eq 'FAIL').Count | Should Be 0
            @($results | Where-Object {
                $_.Code -eq 'P00-E3L-READY' -and $_.Status -eq 'PASS'
            }).Count | Should Be 1
        } finally { Remove-E3LTestTree $root }
    }

    It 'accepts the repository Attempt 7 PASS state with selected evidence' {
        $results = @(Test-Phase00E3LArtifactContract -RepositoryRoot $repositoryRoot)
        @($results | Where-Object Status -eq 'FAIL').Count | Should Be 0
        @($results | Where-Object {
            $_.Code -eq 'P00-E3L-TERMINAL' -and $_.Status -eq 'PASS'
        }).Count | Should Be 1
        foreach ($name in @('selected-transaction.json','L1.json','L2.json','L3.json')) {
            Test-Path -LiteralPath (Join-Path $repositoryRoot `
                "docs\evidence\phase-00\E3-L\$name") -PathType Leaf | Should Be $true
        }
    }

    It 'hash-links the second joint correction and records invalid selection honestly' {
        $path = Join-Path $repositoryRoot `
            'docs\evidence\phase-00\E3-L\raw\joint-attempt-005.adjudication-002.json'
        Test-Path -LiteralPath $path -PathType Leaf | Should Be $true
        $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $record.schema_version | Should Be 2
        $record.experiment | Should Be 'E3-I+E3-L'
        $record.attempt | Should Be 5
        $record.selected | Should Be $false
        $record.correction_of.path | Should Be `
            'docs/evidence/phase-00/E3-L/raw/joint-attempt-005.adjudication.json'
        $predecessor = Join-Path $repositoryRoot $record.correction_of.path
        (Get-FileHash -LiteralPath $predecessor -Algorithm SHA256).Hash |
            Should Be $record.correction_of.sha256
        $record.correction_reason | Should Be `
            'E3IL_PARENT_TERMINAL_PRECEDENCE_AND_SELECTION_CORRECTION'
        $record.sessions.a.transport_status | Should Be 'INVALID_RUN'
        ($record.sessions.a.transport_reasons -join ',') |
            Should Be 'E3IL_NESTED_PROVIDER_RECOVERY'
        $record.sessions.a.e3_i_status | Should Be 'INVALID_RUN'
        $record.sessions.a.e3_l_status | Should Be 'INVALID_RUN'
        $record.sessions.a.provider_terminal | Should Be $false
        $record.sessions.a.recovered_provider_retry | Should Be $true
        $record.sessions.a.parent_retry_recovery.count | Should Be 8
        $record.sessions.a.nested_retry_recovery.canary_id | Should Be 'e3i-runtime-3'
        $record.sessions.a.nested_retry_recovery.status | Should Be 'recovered'
        $record.sessions.b.invoked | Should Be $false
        $record.sessions.b.skip_reason | Should Be 'A_INVALID_RUN'
        $record.adjudication.status | Should Be 'INVALID_RUN'
        $record.adjudication.reason | Should Be 'E3IL_NESTED_PROVIDER_RECOVERY'
        $record.adjudication.selection_eligible | Should Be $false
        $record.automatic_retry | Should Be $false
        $record.new_provider_call | Should Be $false

        foreach ($reference in @(
            $record.source_identity,
            $record.sessions.a.run,
            $record.sessions.a.parent_stdout,
            $record.sessions.a.parent_stderr
        ) + @($record.sessions.a.canaries)) {
            $referencePath = Join-Path $repositoryRoot $reference.path
            (Get-FileHash -LiteralPath $referencePath -Algorithm SHA256).Hash |
                Should Be $reference.sha256
        }
    }

    It 'records the selected E3-L PASS conclusion without parallel authority' {
        $path = Join-Path $repositoryRoot `
            'docs\evidence\phase-00\E3-L\conclusion.json'
        $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $record.schema_version | Should Be 2
        $record.experiment | Should Be 'E3-L'
        $record.state | Should Be 'PASS'
        $record.attempt | Should Be 7
        $record.selected_transaction.path | Should Be `
            'docs/evidence/phase-00/E3-L/selected-transaction.json'
        @($record.cases).Count | Should Be 3
        $record.parallel_authorized | Should Be $false
        $record.parallel_mode_after | Should Be 'DISABLED'
        $record.e3_m_replaced | Should Be $false
        $record.claim | Should Be `
            'The approved proxy observes live effective task.isolation.apply for the OMP-owned default main-CLI root-session class on pinned 17.2.10.'
        $selectedPath = Join-Path $repositoryRoot $record.selected_transaction.path
        (Get-FileHash -LiteralPath $selectedPath -Algorithm SHA256).Hash |
            Should Be $record.selected_transaction.sha256
    }

    It 'validates the complete correction chain and rejects forged E3-I or E3-L links' {
        (Get-Command Test-Phase00P00CX028CorrectionContract -ErrorAction SilentlyContinue) |
            Should Not BeNullOrEmpty
        $repositoryResults = @(
            Test-Phase00P00CX028CorrectionContract -RepositoryRoot $repositoryRoot
        )
        @($repositoryResults | Where-Object Status -eq 'FAIL').Count | Should Be 0
        @($repositoryResults | Where-Object {
            $_.Code -eq 'P00-CX-028' -and $_.Status -eq 'PASS'
        }).Count | Should Be 1

        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-cx028-{0}" -f [guid]::NewGuid().ToString('N'))
        try {
            $destination = Join-Path $safe 'docs\evidence'
            [IO.Directory]::CreateDirectory($destination) | Out-Null
            Copy-Item -LiteralPath (Join-Path $repositoryRoot `
                'docs\evidence\phase-00') -Destination (Join-Path $destination `
                'phase-00') -Recurse

            $e3iPath = Join-Path $safe `
                'docs\evidence\phase-00\E3-I\raw\session-a.attempt-004.adjudication-002.json'
            $e3iRaw = [IO.File]::ReadAllText($e3iPath)
            $e3i = $e3iRaw | ConvertFrom-Json
            $e3i.correction_of.sha256 = ('0' * 64)
            Write-E3LTestJson $e3iPath $e3i
            @(Test-Phase00P00CX028CorrectionContract -RepositoryRoot $safe |
                Where-Object Status -eq 'FAIL').Count | Should Be 1
            [IO.File]::WriteAllText($e3iPath, $e3iRaw, `
                [Text.UTF8Encoding]::new($false))

            $e3lPath = Join-Path $safe `
                'docs\evidence\phase-00\E3-L\raw\joint-attempt-005.adjudication-002.json'
            $e3l = Get-Content -LiteralPath $e3lPath -Raw | ConvertFrom-Json
            $e3l.sessions.b.skip_reason = 'A_BLOCKED_ENVIRONMENT'
            Write-E3LTestJson $e3lPath $e3l
            @(Test-Phase00P00CX028CorrectionContract -RepositoryRoot $safe |
                Where-Object Status -eq 'FAIL').Count | Should Be 1
        } finally {
            if (Test-Path -LiteralPath $safe) { Remove-E3LTestTree $safe }
        }
    }

    It 'accepts complete PASS, FAIL, and BLOCKED_ENVIRONMENT fixtures' {
        foreach ($state in @('PASS','FAIL','BLOCKED_ENVIRONMENT')) {
            $root = New-E3LDurableFixture $state
            try {
                $results = @(Test-Phase00E3LArtifactContract -RepositoryRoot $root)
                $failures = @($results | Where-Object Status -eq 'FAIL')
                if ($failures.Count -gt 0) {
                    throw "$state fixture rejected: $($failures.Message -join '; ')"
                }
            } finally {
                Remove-E3LTestTree $root
            }
        }
    }

    It 'rejects a corrected block without its immutable predecessor and exact retry correction' {
        $mutations = @(
            { param($root,$record) [IO.File]::Delete((Join-Path $root `
                'docs\evidence\phase-00\E3-L\raw\joint-attempt-005.json')) },
            { param($root,$record) $record.correction_of.sha256 = ('0' * 64) },
            { param($root,$record) $record.correction_reason = 'UNREVIEWED_CORRECTION' },
            { param($root,$record) $record.sessions.a.recovered_provider_retry = $false }
        )
        $rejected = 0
        foreach ($mutation in $mutations) {
            $root = New-E3LDurableFixture BLOCKED_ENVIRONMENT
            try {
                $adjudicationPath = Join-Path $root `
                    'docs\evidence\phase-00\E3-L\raw\joint-attempt-005.adjudication.json'
                $record = Get-Content -Raw $adjudicationPath | ConvertFrom-Json
                & $mutation $root $record
                if (Test-Path -LiteralPath $adjudicationPath) {
                    Write-E3LTestJson $adjudicationPath $record
                    $conclusionPath = Join-Path $root `
                        'docs\evidence\phase-00\E3-L\conclusion.json'
                    $conclusion = Get-Content -Raw $conclusionPath | ConvertFrom-Json
                    $conclusion.joint_adjudication.sha256 = `
                        (Get-FileHash -Algorithm SHA256 $adjudicationPath).Hash
                    Write-E3LTestJson $conclusionPath $conclusion
                }
                if (Test-E3LContractHasFailure $root) { $rejected++ }
            } finally { Remove-E3LTestTree $root }
        }
        $rejected | Should Be $mutations.Count
    }

    It 'rejects missing conclusion and missing L1-L3 evidence' {
        $root = New-E3LDurableFixture PASS
        try {
            [IO.File]::Delete((Join-Path $root `
                'docs\evidence\phase-00\E3-L\conclusion.json'))
            Test-E3LContractHasFailure $root | Should Be $true
        } finally { Remove-E3LTestTree $root }

        $root = New-E3LDurableFixture FAIL
        try {
            [IO.File]::Delete((Join-Path $root `
                'docs\evidence\phase-00\E3-L\L2.json'))
            Test-E3LContractHasFailure $root | Should Be $true
        } finally { Remove-E3LTestTree $root }
    }

    It 'rejects unselected, bad-hash, mismatched-attempt, host, and runtime projections' {
        $mutations = @(
            { param($p) $p.selected = $false },
            { param($p) $p.raw_inputs[0].sha256 = ('0' * 64) },
            { param($p) $p.attempt = 6 },
            { param($p) $p.supported_host = 'unsupported-host' },
            { param($p) $p.runtime.version = 'omp/17.2.12' }
        )
        foreach ($mutation in $mutations) {
            $root = New-E3LDurableFixture PASS
            try {
                $path = Join-Path $root `
                    'docs\evidence\phase-00\E3-L\selected-transaction.json'
                $projection = Get-Content -Raw $path | ConvertFrom-Json
                & $mutation $projection
                Write-E3LTestJson $path $projection
                Test-E3LContractHasFailure $root | Should Be $true
            } finally { Remove-E3LTestTree $root }
        }
    }

    It 'rejects absent source, parallel drift, E3-M drift, circularity, and incomplete markers' {
        $root = New-E3LDurableFixture PASS
        try {
            [IO.File]::Delete((Join-Path $root `
                'docs\evidence\phase-00\E3-L\source-identity.json'))
            Test-E3LContractHasFailure $root | Should Be $true
        } finally { Remove-E3LTestTree $root }

        foreach ($manifestMutation in @(
            { param($t) $t.Replace('parallel_mode: DISABLED','parallel_mode: ENABLED') },
            { param($t) $t.Replace('state: DEFERRED_PARALLEL_DISABLED', 'state: READY') }
        )) {
            $root = New-E3LDurableFixture PASS
            try {
                $path = Join-Path $root 'docs\evidence\phase-00\manifest.yml'
                $text = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, (& $manifestMutation $text), `
                    [Text.UTF8Encoding]::new($false))
                Test-E3LContractHasFailure $root | Should Be $true
            } finally { Remove-E3LTestTree $root }
        }

        foreach ($marker in @(
            'docs/evidence/phase-00/E3-L/conclusion.json',
            'TODO_RUNTIME_EVIDENCE'
        )) {
            $root = New-E3LDurableFixture PASS
            try {
                $path = Join-Path $root `
                    'docs\evidence\phase-00\E3-L\conclusion.json'
                $conclusion = Get-Content -Raw $path | ConvertFrom-Json
                $conclusion.incomplete_markers = @($marker)
                Write-E3LTestJson $path $conclusion
                Test-E3LContractHasFailure $root | Should Be $true
            } finally { Remove-E3LTestTree $root }
        }
    }
}

Describe 'E3-I/E3-L mocked joint attempt runner' {
    It 'preserves direct CLI arguments across dependency loading before provider invocation' {
        $hostExecutable = if ($PSVersionTable.PSEdition -eq 'Core') {
            (Get-Command pwsh -ErrorAction Stop).Source
        } else {
            (Get-Command powershell.exe -ErrorAction Stop).Source
        }
        $missingRuntime = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3l-missing-{0}.exe" -f [guid]::NewGuid().ToString('N'))
        $arguments = @('-NoProfile')
        if ($PSVersionTable.PSEdition -ne 'Core') {
            $arguments += @('-ExecutionPolicy','Bypass')
        }
        $arguments += @(
            '-File',$jointRunnerPath,
            '-Attempt','5',
            '-Model','mock/provider-model',
            '-OmpExecutable',$missingRuntime
        )

        $capture = Invoke-Phase00E3ICapturedProcess -FilePath $hostExecutable `
            -Arguments $arguments -WorkingDirectory $repositoryRoot `
            -Environment @{} -TimeoutSeconds 30
        $combined = "$($capture.Stdout)`n$($capture.Stderr)"

        $capture.TimedOut | Should Be $false
        ($capture.ExitCode -ne 0) | Should Be $true
        $combined | Should Match 'Pinned OMP executable does not exist'
        $combined | Should Not Match 'Direct joint execution requires -OmpExecutable'
        Test-Path -LiteralPath $missingRuntime | Should Be $false
    }

    It 'loads without invoking a provider and runs A then B with one locked identity' {
        $script:e3lJointRunnerLoaded | Should Be $true
        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3l-joint-{0}" -f [guid]::NewGuid().ToString('N'))
        $calls = [System.Collections.ArrayList]::new()
        $pinned = Get-E3LPinnedExecutable
        $model = 'mock/provider-model'
        $repoRawBefore = @(Get-ChildItem `
            (Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-L\raw') `
            -File -ErrorAction SilentlyContinue).Count
        try {
            $invoker = {
                param($Session,$Attempt,$Model,$OmpExecutable)
                [void]$calls.Add([pscustomobject]@{
                    Session = $Session; Attempt = $Attempt; Model = $Model
                    OmpExecutable = $OmpExecutable
                })
                New-E3LMockSessionResult $Session $safe $Attempt
            }
            $result = Invoke-Phase00E3ILJointAttempt -Attempt 5 -Model $model `
                -OmpExecutable $pinned -SessionInvoker $invoker `
                -EvidenceRoot $safe -SourceIdentityPath $sourceIdentityPath

            (@($calls.Session) -join ',') | Should Be 'A,B'
            @($calls | Where-Object {
                $_.Attempt -ne 5 -or $_.Model -ne $model -or
                $_.OmpExecutable -ne $pinned
            }).Count | Should Be 0
            $result.Status | Should Be 'CAPTURED_UNSELECTED'
            Test-Path -LiteralPath $result.JointPath -PathType Leaf | Should Be $true

            $raw = Get-Content -Raw -LiteralPath $result.JointPath -Encoding UTF8
            $record = $raw | ConvertFrom-Json
            $record.attempt | Should Be 5
            $record.selected | Should Be $false
            $record.runtime.version | Should Be 'omp/17.2.10'
            $record.runtime.sha256 | Should Be `
                '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
            $record.sessions.a.transport_status | Should Be 'ELIGIBLE'
            $record.sessions.b.transport_status | Should Be 'ELIGIBLE'
            $record.e3_i_conclusion_consumed | Should Be $false
            $record.e3_l_conclusion_consumed | Should Be $false
            $record.automatic_retry | Should Be $false
            $raw | Should Not Match ([regex]::Escape([IO.Path]::GetFullPath($safe)))
            $raw | Should Not Match ([regex]::Escape([IO.Path]::GetFullPath($pinned)))
        } finally {
            if (Test-Path -LiteralPath $safe) { Remove-E3LTestTree $safe }
        }
        Test-Path -LiteralPath $safe | Should Be $false
        @(Get-ChildItem (Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-L\raw') `
            -File -ErrorAction SilentlyContinue).Count | Should Be $repoRawBefore
    }

    It 'skips B after A selection invalidity or environment block' {
        $pinned = Get-E3LPinnedExecutable
        foreach ($selectionStatus in @('INVALID_RUN','BLOCKED_ENVIRONMENT')) {
            $safe = Join-Path ([IO.Path]::GetTempPath()) `
                ("omp-phase00-e3l-joint-{0}" -f [guid]::NewGuid().ToString('N'))
            $calls = [System.Collections.ArrayList]::new()
            try {
                $invoker = {
                    param($Session,$Attempt,$Model,$OmpExecutable)
                    [void]$calls.Add($Session)
                    New-E3LMockSessionResult $Session $safe $Attempt $selectionStatus
                }
                $result = Invoke-Phase00E3ILJointAttempt 5 'mock/model' $pinned `
                    $invoker $safe $sourceIdentityPath
                (@($calls) -join ',') | Should Be 'A'
                $result.SessionBInvoked | Should Be $false
                $record = Get-Content -Raw $result.JointPath | ConvertFrom-Json
                $record.sessions.b.skip_reason | Should Be "A_$selectionStatus"
            } finally {
                if (Test-Path -LiteralPath $safe) { Remove-E3LTestTree $safe }
            }
        }
    }

    It 'preserves recovered nested retry facts when a parent terminal block wins precedence' {
        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3l-joint-{0}" -f [guid]::NewGuid().ToString('N'))
        $pinned = Get-E3LPinnedExecutable
        try {
            $invoker = {
                param($Session,$Attempt,$Model,$OmpExecutable)
                $invocation = New-E3LMockSessionResult $Session $safe $Attempt `
                    BLOCKED_ENVIRONMENT BLOCKED_ENVIRONMENT
                $recovered = [pscustomobject][ordered]@{
                    type = 'message'
                    message = [pscustomobject][ordered]@{
                        role = 'assistant'
                        stopReason = 'error'
                        provider = 'omniroute'
                        model = 'codex/gpt-5.6-sol-high'
                        errorMessage = 'server_is_overloaded'
                        retryRecovery = [pscustomobject][ordered]@{
                            kind = 'auto-retry'
                            status = 'recovered'
                            attempt = 1
                        }
                    }
                }
                $invocation | Add-Member NoteProperty CanaryEvents `
                    @{'e3i-runtime-3' = @($recovered)} -Force
                $invocation
            }
            $result = Invoke-Phase00E3ILJointAttempt 5 'mock/model' $pinned `
                $invoker $safe $sourceIdentityPath
            $result.SessionBInvoked | Should Be $false
            $record = Get-Content -Raw $result.JointPath | ConvertFrom-Json
            $record.sessions.a.transport_status | Should Be 'BLOCKED_ENVIRONMENT'
            $record.sessions.a.recovered_provider_retry | Should Be $true
        } finally {
            if (Test-Path -LiteralPath $safe) { Remove-E3LTestTree $safe }
        }
    }

    It 'projects recovered parent retry facts independently of selection precedence' {
        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3l-joint-{0}" -f [guid]::NewGuid().ToString('N'))
        $pinned = Get-E3LPinnedExecutable
        try {
            $invoker = {
                param($Session,$Attempt,$Model,$OmpExecutable)
                $invocation = New-E3LMockSessionResult $Session $safe $Attempt `
                    INVALID_RUN INVALID_RUN
                $stopMessage = [pscustomobject][ordered]@{
                    role = 'assistant'; stopReason = 'stop'
                    provider = 'omniroute'; model = 'test/model'
                }
                $invocation | Add-Member NoteProperty ParentEvents @(
                    [pscustomobject][ordered]@{
                        type = 'auto_retry_start'; attempt = 1; maxAttempts = 10
                        errorMessage = 'server_is_overloaded'; errorId = 135168
                    },
                    [pscustomobject][ordered]@{
                        type = 'message_end'; message = $stopMessage
                    }
                ) -Force
                $invocation
            }
            $result = Invoke-Phase00E3ILJointAttempt 5 'mock/model' $pinned `
                $invoker $safe $sourceIdentityPath
            $result.SessionBInvoked | Should Be $false
            $record = Get-Content -Raw $result.JointPath | ConvertFrom-Json
            $record.sessions.a.transport_status | Should Be 'INVALID_RUN'
            $record.sessions.a.recovered_provider_retry | Should Be $true
            $record.sessions.b.skip_reason | Should Be 'A_INVALID_RUN'
        } finally {
            if (Test-Path -LiteralPath $safe) { Remove-E3LTestTree $safe }
        }
    }

    It 'continues to B after an attributable experiment-semantic FAIL' {
        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3l-joint-{0}" -f [guid]::NewGuid().ToString('N'))
        $calls = [System.Collections.ArrayList]::new()
        $pinned = Get-E3LPinnedExecutable
        try {
            $invoker = {
                param($Session,$Attempt,$Model,$OmpExecutable)
                [void]$calls.Add($Session)
                New-E3LMockSessionResult $Session $safe $Attempt ELIGIBLE `
                    $(if ($Session -eq 'A') { 'FAIL' } else { 'PASS' })
            }
            $result = Invoke-Phase00E3ILJointAttempt 5 'mock/model' $pinned `
                $invoker $safe $sourceIdentityPath
            (@($calls) -join ',') | Should Be 'A,B'
            $result.SessionBInvoked | Should Be $true
            $record = Get-Content -Raw $result.JointPath | ConvertFrom-Json
            $record.sessions.a.e3_i_status | Should Be 'FAIL'
            $record.sessions.a.transport_status | Should Be 'ELIGIBLE'
        } finally {
            if (Test-Path -LiteralPath $safe) { Remove-E3LTestTree $safe }
        }
    }

    It 'rejects low attempts, collisions, and every implicit second invocation' {
        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3l-joint-{0}" -f [guid]::NewGuid().ToString('N'))
        $calls = [System.Collections.ArrayList]::new()
        $pinned = Get-E3LPinnedExecutable
        $collisionRoot = $null
        $invoker = {
            param($Session,$Attempt,$Model,$OmpExecutable)
            [void]$calls.Add($Session)
            New-E3LMockSessionResult $Session $safe $Attempt
        }
        try {
            $lowRejected = $false
            try {
                Invoke-Phase00E3ILJointAttempt 4 'mock/model' $pinned $invoker `
                    $safe $sourceIdentityPath | Out-Null
            } catch { $lowRejected = $true }
            $lowRejected | Should Be $true
            $calls.Count | Should Be 0

            $result = Invoke-Phase00E3ILJointAttempt 5 'mock/model' $pinned $invoker `
                $safe $sourceIdentityPath
            $calls.Count | Should Be 2
            $secondRejected = $false
            try {
                Invoke-Phase00E3ILJointAttempt 5 'mock/model' $pinned $invoker `
                    $safe $sourceIdentityPath | Out-Null
            } catch { $secondRejected = $true }
            $secondRejected | Should Be $true
            $calls.Count | Should Be 2

            $collisionRoot = Join-Path ([IO.Path]::GetTempPath()) `
                ("omp-phase00-e3l-joint-{0}" -f [guid]::NewGuid().ToString('N'))
            [IO.Directory]::CreateDirectory((Join-Path $collisionRoot 'E3-I\raw')) |
                Out-Null
            $collision = Join-Path $collisionRoot `
                'E3-I\raw\session-b-attempt-006.run.json'
            [IO.File]::WriteAllText($collision, '{}', [Text.UTF8Encoding]::new($false))
            $collisionRejected = $false
            try {
                Invoke-Phase00E3ILJointAttempt 6 'mock/model' $pinned $invoker `
                    $collisionRoot $sourceIdentityPath | Out-Null
            } catch { $collisionRejected = $true }
            $collisionRejected | Should Be $true
            Remove-E3LTestTree $collisionRoot
        } finally {
            if (Test-Path -LiteralPath $safe) { Remove-E3LTestTree $safe }
            if ($null -ne $collisionRoot -and (Test-Path -LiteralPath $collisionRoot)) {
                Remove-E3LTestTree $collisionRoot
            }
        }
    }
}

Describe 'E3-I/E3-L recovered retry fact projection' {
    It 'does not call a bare assistant error recovered' {
        $bare = [pscustomobject][ordered]@{
            type = 'message'
            message = [pscustomobject][ordered]@{
                role = 'assistant'; stopReason = 'error'; provider = 'omniroute'
                model = 'test/model'; errorMessage = 'server_is_overloaded'
            }
        }
        $recovered = $bare | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $recovered.message | Add-Member NoteProperty retryRecovery `
            ([pscustomobject][ordered]@{
                kind = 'auto-retry'; status = 'recovered'; attempt = 1
            })

        @(Get-Phase00E3ILRecoveredProviderFailures -Events @($bare)).Count |
            Should Be 0
        $facts = @(Get-Phase00E3ILRecoveredProviderFailures -Events @($recovered))
        $facts.Count | Should Be 1
        $facts[0].RecoveryKind | Should Be 'auto-retry'
        $facts[0].RecoveryStatus | Should Be 'recovered'
        $facts[0].RecoveryAttempt | Should Be 1
    }

    It 'replays immutable Attempt 4 as an invalid parent sequence' {
        $rawRoot = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-I\raw'
        $parent = @(Read-E3LJsonLines (Join-Path $rawRoot `
            'session-a-attempt-004.stdout.jsonl'))
        $canaries = Get-E3LAttemptCanaryEvents 4
        $result = Test-Phase00E3ILSessionTransport -Session A `
            -ParentEvents $parent -CanaryEvents $canaries

        $result.Status | Should Be 'INVALID_RUN'
        ($result.Reasons -join ',') | Should Be 'E3IL_PARENT_SEQUENCE_MISMATCH'
        @(Get-Phase00ParentRecoveredProviderRetries -Events $parent).Count |
            Should Be 1
    }

    It 'replays immutable Attempt 5 as an invalid nested provider recovery' {
        $rawRoot = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-I\raw'
        $parent = @(Read-E3LJsonLines (Join-Path $rawRoot `
            'session-a-attempt-005.stdout.jsonl'))
        $canaries = Get-E3LAttemptCanaryEvents 5
        $result = Test-Phase00E3ILSessionTransport -Session A `
            -ParentEvents $parent -CanaryEvents $canaries

        $result.Status | Should Be 'INVALID_RUN'
        ($result.Reasons -join ',') | Should Be 'E3IL_NESTED_PROVIDER_RECOVERY'
        @(Get-Phase00ParentRecoveredProviderRetries -Events $parent).Count |
            Should Be 8
    }
}

Describe 'E3-I/E3-L shared transport contract' {
    It 'accepts the canonical untyped yield after provider string normalization' {
        $script:e3ilTransportLoaded | Should Be $true
        $events = @(
            [pscustomobject][ordered]@{
                type = 'session_init'
                agent = 'phase00-e3i-canary'
                tools = @('read','yield','hub')
                readOnly = $true
            },
            [pscustomobject][ordered]@{
                type = 'message'
                message = [ordered]@{
                    role = 'assistant'
                    content = @([ordered]@{
                        type = 'toolCall'
                        name = 'yield'
                        arguments = [ordered]@{
                            result = '{"data":{"acknowledgement":"PHASE00_E3I_CANARY_OK"}}'
                        }
                    })
                }
            }
        )

        $session = Get-Phase00E3ILCanarySession -Events $events `
            -ExpectedId 'e3i-project-1'
        $session.YieldCallCount | Should Be 1
        $session.ForbiddenToolCallCount | Should Be 0
    }

    It 'accepts only the exact augmented parent protocols and controlled canaries' {
        $script:e3ilTransportLoaded | Should Be $true
        $a = New-E3LTransportFixture A
        $b = New-E3LTransportFixture B

        $aResult = Test-Phase00E3ILSessionTransport -Session A `
            -ParentEvents $a.ParentEvents -CanaryEvents $a.CanaryEvents
        $bResult = Test-Phase00E3ILSessionTransport -Session B `
            -ParentEvents $b.ParentEvents -CanaryEvents $b.CanaryEvents

        $aResult.Status | Should Be 'ELIGIBLE'
        $bResult.Status | Should Be 'ELIGIBLE'
        (@($aResult.Pairs.ToolName) -join ',') | Should Be `
            'phase00_e3l_read_apply,bash,task,task,task,phase00_e3i_override_apply_true,phase00_e3l_read_apply,bash,task,task,task'
        (@($bResult.Pairs.ToolName) -join ',') | Should Be `
            'phase00_e3l_read_apply,bash,task,task,task'
        @($aResult.CanarySessions).Count | Should Be 6
        @($bResult.CanarySessions).Count | Should Be 3
    }

    It 'invalidates pairing, sequence, retry, and timeout defects' {
        $script:e3ilTransportLoaded | Should Be $true
        $a = New-E3LTransportFixture A
        $duplicate = @($a.ParentEvents + $a.ParentEvents[0])
        (Test-Phase00E3ILSessionTransport -Session A -ParentEvents $duplicate `
            -CanaryEvents $a.CanaryEvents).Status | Should Be 'INVALID_RUN'

        $missing = @($a.ParentEvents | Select-Object -Skip 2)
        @((Test-Phase00E3ILSessionTransport -Session A `
            -ParentEvents $missing -CanaryEvents $a.CanaryEvents).Reasons) `
            -contains 'E3IL_PARENT_SEQUENCE_MISMATCH' | Should Be $true

        $recovered = [pscustomobject][ordered]@{
            type = 'message_end'
            message = [ordered]@{
                role = 'assistant'
                stopReason = 'error'
                provider = 'omniroute'
                model = 'test/model'
                errorMessage = 'server_is_overloaded'
                retryRecovery = [ordered]@{
                    kind = 'auto-retry'
                    status = 'recovered'
                    attempt = 1
                }
            }
        }
        $a.CanaryEvents['e3i-project-1'] += $recovered
        @((Test-Phase00E3ILSessionTransport -Session A `
            -ParentEvents $a.ParentEvents `
            -CanaryEvents $a.CanaryEvents).Reasons) `
            -contains 'E3IL_NESTED_PROVIDER_RECOVERY' | Should Be $true

        $clean = New-E3LTransportFixture A
        @((Test-Phase00E3ILSessionTransport -Session A `
            -ParentEvents $clean.ParentEvents -CanaryEvents $clean.CanaryEvents `
            -TimedOut $true).Reasons) -contains 'E3IL_TIMEOUT' | Should Be $true
    }

    It 'keeps shared selection eligibility separate from experiment semantics' {
        $script:e3ilTransportLoaded | Should Be $true
        $a = New-E3LTransportFixture A
        $transport = Test-Phase00E3ILSessionTransport -Session A `
            -ParentEvents $a.ParentEvents -CanaryEvents $a.CanaryEvents
        $eligible = Test-Phase00E3ILSelectionEnvelope -SessionTransport $transport `
            -Boundary (New-E3LTransportBoundary) `
            -LiveHomeMutationAttributable $false -CleanupError ''
        $eligible.Status | Should Be 'ELIGIBLE'
        @($eligible.PSObject.Properties.Name) -contains 'Verdict' | Should Be $false

        $boundary = New-E3LTransportBoundary
        $boundary.CleanupSucceeded = $false
        $invalid = Test-Phase00E3ILSelectionEnvelope -SessionTransport $transport `
            -Boundary $boundary -LiveHomeMutationAttributable $false `
            -CleanupError 'cleanup failed'
        $invalid.Status | Should Be 'INVALID_RUN'
        @($invalid.Reasons) -contains 'E3IL_BOUNDARY_INELIGIBLE' | Should Be $true
    }
}
