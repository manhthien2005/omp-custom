#Requires -Version 5.1

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runtimeHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-runtime-evidence.ps1'
$configHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-config-evidence.ps1'
$e3iHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-e3i-evidence.ps1'
$runnerPath = Join-Path $repositoryRoot 'scripts\run-phase00-e3i.ps1'
$e3iFixtureRoot = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-I\fixture'
$script:e3iHelperLoaded = $false
$script:e3iRunnerLoaded = $false

. $runtimeHelperPath
. $configHelperPath
if (Test-Path -LiteralPath $e3iHelperPath -PathType Leaf) {
    . $e3iHelperPath
    $script:e3iHelperLoaded = $true
}
if (Test-Path -LiteralPath $runnerPath -PathType Leaf) {
    . $runnerPath
    $script:e3iRunnerLoaded = $true
}

function Assert-E3IHelperLoaded { $script:e3iHelperLoaded | Should Be $true }
function Assert-E3IRunnerLoaded { $script:e3iRunnerLoaded | Should Be $true }

function New-E3IToolStart([string]$Id, [string]$Name, $Arguments) {
    [pscustomobject]@{
        type = 'tool_execution_start'
        toolCallId = $Id
        toolName = $Name
        args = $Arguments
    }
}

function New-E3IToolEnd([string]$Id, [string]$Name, $Result, [bool]$IsError = $false) {
    [pscustomobject]@{
        type = 'tool_execution_end'
        toolCallId = $Id
        toolName = $Name
        result = $Result
        isError = $IsError
    }
}

function New-E3ITaskPair([string]$Id, [object[]]$ResultRows, [string]$Summary) {
    $toolCallId = "call-$Id"
    $start = New-E3IToolStart $toolCallId 'task' ([ordered]@{
        context = 'Phase 00 E3-I sequential behavioral canary'
        tasks = @([ordered]@{
            agent = 'phase00-e3i-canary'
            isolated = $true
            name = $Id
            task = 'Submit the exact acknowledgement required by your agent contract through its required terminal yield. Do not call any other tool.'
        })
    })
    $result = [ordered]@{
        content = @([ordered]@{
            type = 'text'
            text = "<merge-summary>$Summary</merge-summary>"
        })
        details = [ordered]@{ results = @($ResultRows) }
    }
    $end = New-E3IToolEnd $toolCallId 'task' $result
    [pscustomobject][ordered]@{
        ToolCallId = $toolCallId
        ToolName = 'task'
        StartIndex = 0
        EndIndex = 1
        Start = $start
        End = $end
    }
}

function New-E3IResultRow([string]$Id) {
    [pscustomobject][ordered]@{
        id = $Id
        durationMs = 1200
        tokens = 34
        requests = 1
        resolvedModel = 'test/model'
        exitCode = 0
        aborted = $false
        output = '{"acknowledgement":"PHASE00_E3I_CANARY_OK"}'
    }
}

function New-E3IBashPair([string]$Id, [bool]$Value = $false) {
    $jsonValue = if ($Value) { 'true' } else { 'false' }
    $json = '{"key":"task.isolation.apply","value":' + $jsonValue +
        ',"type":"boolean","description":"Automatically apply successful isolated task changes"}'
    $start = New-E3IToolStart $Id 'bash' ([ordered]@{
        command = Get-Phase00E3IChildDiagnosticCommand
        timeout = [int]60
    })
    $end = New-E3IToolEnd $Id 'bash' ([ordered]@{
        content = @([ordered]@{
            type = 'text'
            text = "$json`n`n`nWall time: 0.12 seconds"
        })
    })
    [pscustomobject][ordered]@{
        ToolCallId = $Id; ToolName = 'bash'; StartIndex = 0; EndIndex = 1
        Start = $start; End = $end
    }
}

function New-E3IOverrideDetails {
    [pscustomobject][ordered]@{
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
}

function New-E3IOverrideToolResult($Details = (New-E3IOverrideDetails)) {
    [pscustomobject][ordered]@{
        content = @([pscustomobject][ordered]@{
            type = 'text'
            text = ($Details | ConvertTo-Json -Compress)
        })
        details = $Details
    }
}

function New-E3IOverridePair {
    $id = 'call-runtime-override'
    [pscustomobject][ordered]@{
        ToolCallId = $id
        ToolName = 'phase00_e3i_override_apply_true'
        StartIndex = 0
        EndIndex = 1
        Start = New-E3IToolStart $id 'phase00_e3i_override_apply_true' ([ordered]@{})
        End = New-E3IToolEnd $id 'phase00_e3i_override_apply_true' `
            (New-E3IOverrideToolResult)
    }
}

function New-E3IReaderDetails([bool]$Value) {
    [pscustomobject][ordered]@{
        probe = 'phase00-e3l-live-reader-v1'
        setting = 'task.isolation.apply'
        operation = 'pi.pi.settings.get'
        value = $Value
        scope = 'parent-only'
    }
}

function New-E3IReaderPair([string]$Id, [bool]$Value) {
    $details = New-E3IReaderDetails $Value
    $result = [pscustomobject][ordered]@{
        content = @([pscustomobject][ordered]@{
            type = 'text'
            text = ($details | ConvertTo-Json -Compress)
        })
        details = $details
    }
    [pscustomobject][ordered]@{
        ToolCallId = $Id
        ToolName = 'phase00_e3l_read_apply'
        StartIndex = 0
        EndIndex = 1
        Start = New-E3IToolStart $Id 'phase00_e3l_read_apply' ([ordered]@{})
        End = New-E3IToolEnd $Id 'phase00_e3l_read_apply' $result
    }
}

function New-E3ICanaryToolCallMessage(
    [string]$Name,
    $Arguments,
    [string]$ToolCallId = ''
) {
    $content = [ordered]@{
        type = 'toolCall'
        name = $Name
        arguments = $Arguments
    }
    if (-not [string]::IsNullOrWhiteSpace($ToolCallId)) {
        $content.id = $ToolCallId
    }
    [pscustomobject][ordered]@{
        type = 'message'
        message = [pscustomobject][ordered]@{
            role = 'assistant'
            content = @([pscustomobject]$content)
        }
    }
}

function New-E3ICanaryToolExecutionStart(
    [string]$Name,
    [string]$ToolCallId,
    $Arguments = $null
) {
    [pscustomobject][ordered]@{
        type = 'custom'
        customType = 'tool_execution_start'
        data = [pscustomobject][ordered]@{
            toolCallId = $ToolCallId
            toolName = $Name
            args = $Arguments
        }
    }
}

function New-E3ICanaryEvents(
    [string[]]$Tools = @('read','yield','hub'),
    [bool]$AddHubCall = $false
) {
    $events = @(
        [pscustomobject][ordered]@{
            type = 'session_init'
            agent = 'phase00-e3i-canary'
            tools = @($Tools)
            readOnly = $true
        },
        [pscustomobject]@{ type = 'agent_start' }
    )
    if ($AddHubCall) {
        $events += New-E3ICanaryToolCallMessage 'hub' @{ agent = 'x' }
    }
    $events += New-E3ICanaryToolCallMessage 'yield' ([ordered]@{
        type = 'result'
        result = [ordered]@{
            data = [ordered]@{ acknowledgement = 'PHASE00_E3I_CANARY_OK' }
        }
    })
    $events += [pscustomobject]@{
        type = 'agent_end'
        isTerminal = $true
        messages = @()
    }
    @($events)
}

function New-E3ITerminalFailureEvents([string]$Message) {
    $assistant = [ordered]@{
        role = 'assistant'
        stopReason = 'error'
        provider = 'omniroute'
        model = 'codex/gpt-5.6-sol-high'
        errorMessage = $Message
    }
    @(
        [pscustomobject][ordered]@{ type = 'message_end'; message = $assistant },
        [pscustomobject][ordered]@{
            type = 'agent_end'; messages = @($assistant); isTerminal = $true
        }
    )
}

function New-E3ISessionFixture([ValidateSet('A','B')][string]$Session) {
    $parentEvents = @()
    $canaryEvents = @{}
    $taskIds = if ($Session -eq 'A') {
        @(
            'e3i-project-1','e3i-project-2','e3i-project-3',
            'e3i-runtime-1','e3i-runtime-2','e3i-runtime-3'
        )
    } else {
        @('e3i-cli-1','e3i-cli-2','e3i-cli-3')
    }

    $firstReader = New-E3IReaderPair `
        "call-$($Session.ToLowerInvariant())-reader-1" ($Session -eq 'B')
    $parentEvents += @($firstReader.Start, $firstReader.End)
    $firstDiagnostic = New-E3IBashPair "call-$($Session.ToLowerInvariant())-diagnostic-1"
    $parentEvents += @($firstDiagnostic.Start, $firstDiagnostic.End)
    foreach ($id in @($taskIds | Select-Object -First 3)) {
        $summary = if ($Session -eq 'A') {
            'Isolation: no changes captured.'
        } else {
            'No changes to apply.'
        }
        $pair = New-E3ITaskPair $id @((New-E3IResultRow $id)) $summary
        $parentEvents += @($pair.Start, $pair.End)
        $canaryEvents[$id] = @(New-E3ICanaryEvents)
    }

    if ($Session -eq 'A') {
        $override = New-E3IOverridePair
        $parentEvents += @($override.Start, $override.End)
        $secondReader = New-E3IReaderPair 'call-a-reader-2' $true
        $parentEvents += @($secondReader.Start, $secondReader.End)
        $secondDiagnostic = New-E3IBashPair 'call-a-diagnostic-2'
        $parentEvents += @($secondDiagnostic.Start, $secondDiagnostic.End)
        foreach ($id in @($taskIds | Select-Object -Skip 3)) {
            $pair = New-E3ITaskPair $id @((New-E3IResultRow $id)) 'No changes to apply.'
            $parentEvents += @($pair.Start, $pair.End)
            $canaryEvents[$id] = @(New-E3ICanaryEvents)
        }
    }

    [pscustomobject][ordered]@{
        ParentEvents = @($parentEvents)
        CanaryEvents = $canaryEvents
    }
}

function New-E3IBoundary {
    [pscustomobject][ordered]@{
        ParentContentUnchanged = $true
        ParentHeadUnchanged = $true
        ParentStatusUnchanged = $true
        FixtureHashesUnchanged = $true
        LiveHomeUnchanged = $true
        CleanupSucceeded = $true
    }
}

function Read-E3IJsonLines([string]$Path) {
    @(Get-Content -LiteralPath $Path -Encoding UTF8 | ForEach-Object {
        $_ | ConvertFrom-Json
    })
}

function Get-E3IAttemptCanaryEvents([int]$Attempt) {
    $rawRoot = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-I\raw'
    $events = [ordered]@{}
    foreach ($id in @(
        'e3i-project-1','e3i-project-2','e3i-project-3',
        'e3i-runtime-1','e3i-runtime-2','e3i-runtime-3'
    )) {
        $path = Join-Path $rawRoot `
            ("session-a-attempt-{0:D3}.canary.$id.jsonl" -f $Attempt)
        $events[$id] = @(Read-E3IJsonLines $path)
    }
    $events
}

Describe 'E3-I merge-summary classifier' {
    It 'classifies only the two exact merge-summary branches' {
        Assert-E3IHelperLoaded

        (Get-Phase00E3ISummaryBranch `
            '<merge-summary>Isolation: no changes captured.</merge-summary>').Branch |
            Should Be 'APPLY_FALSE_CAPTURE_ONLY'
        (Get-Phase00E3ISummaryBranch `
            '<merge-summary>No changes to apply.</merge-summary>').Branch |
            Should Be 'APPLY_TRUE_NO_DIFF'
        (Get-Phase00E3ISummaryBranch `
            '<merge-summary>Nothing changed.</merge-summary>').Branch |
            Should Be 'CONTRADICTION'
    }

    It 'rejects missing or ambiguous merge-summary envelopes' {
        Assert-E3IHelperLoaded

        (Get-Phase00E3ISummaryBranch 'No summary envelope.').Branch |
            Should Be 'CONTRADICTION'
        (Get-Phase00E3ISummaryBranch `
            '<merge-summary>No changes to apply</merge-summary>').Branch |
            Should Be 'CONTRADICTION'
        (Get-Phase00E3ISummaryBranch `
            '<merge-summary>Isolation: first</merge-summary><merge-summary>No changes to apply.</merge-summary>').Branch |
            Should Be 'CONTRADICTION'
    }
}

Describe 'E3-I strict transcript primitives' {
    It 'treats an empty JSON object as an object with zero properties under StrictMode' {
        Assert-E3IHelperLoaded
        $emptyJsonObject = '{}' | ConvertFrom-Json

        @(Get-Phase00E3IPropertyNames $emptyJsonObject).Count | Should Be 0
    }

    It 'pairs mixed parent tools once and in start order' {
        Assert-E3IHelperLoaded
        $events = @(
            (New-E3IToolStart 'b1' 'bash' @{ command = 'probe' }),
            [pscustomobject]@{ type = 'message_update' },
            (New-E3IToolEnd 'b1' 'bash' @{ content = @() }),
            (New-E3IToolStart 't1' 'task' @{ tasks = @(@{ name = 'e3i-project-1' }) }),
            (New-E3IToolEnd 't1' 'task' @{ content = @() })
        )

        $pairs = @(Get-Phase00E3IToolEventPairs -Events $events)
        $pairs.Count | Should Be 2
        ($pairs.ToolName -join ',') | Should Be 'bash,task'
        ($pairs.ToolCallId -join ',') | Should Be 'b1,t1'
    }

    It 'rejects duplicate, unpaired, reversed, unnamed, and mismatched events' {
        Assert-E3IHelperLoaded

        $invalidCases = @(
            @{ Name = 'duplicate start'; Events = @(
                (New-E3IToolStart 'x' 'task' @{}),
                (New-E3IToolStart 'x' 'task' @{}),
                (New-E3IToolEnd 'x' 'task' @{})
            ) },
            @{ Name = 'duplicate end'; Events = @(
                (New-E3IToolStart 'x' 'task' @{}),
                (New-E3IToolEnd 'x' 'task' @{}),
                (New-E3IToolEnd 'x' 'task' @{})
            ) },
            @{ Name = 'unpaired'; Events = @(
                (New-E3IToolStart 'x' 'task' @{})
            ) },
            @{ Name = 'reversed'; Events = @(
                (New-E3IToolEnd 'x' 'task' @{}),
                (New-E3IToolStart 'x' 'task' @{})
            ) },
            @{ Name = 'unnamed'; Events = @(
                (New-E3IToolStart '' 'task' @{}),
                (New-E3IToolEnd '' 'task' @{})
            ) },
            @{ Name = 'mismatched name'; Events = @(
                (New-E3IToolStart 'x' 'task' @{}),
                (New-E3IToolEnd 'x' 'bash' @{})
            ) }
        )

        foreach ($case in $invalidCases) {
            $didThrow = $false
            try {
                @(Get-Phase00E3IToolEventPairs -Events @($case.Events)) | Out-Null
            } catch {
                $didThrow = $true
            }
            $didThrow | Should Be $true
        }
    }

    It 'accepts the exact direct OMP config JSON emitted by the reviewed bash command' {
        Assert-E3IHelperLoaded
        (Get-Phase00E3IChildDiagnosticCommand) |
            Should Be 'omp config get task.isolation.apply --json'
        $json = '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"Automatically apply successful isolated task changes"}'
        $toolResult = @{
            content = @(@{ type = 'text'; text = "$json`n`n`nWall time: 0.12 seconds" })
        }

        $result = ConvertFrom-Phase00E3IChildDiagnostic -ToolResult $toolResult
        $result.Status | Should Be 'OBSERVED'
        $result.Value | Should Be $false
    }

    It 'invalidates extra keys, string false, wrong key, malformed JSON, and suffix ambiguity' {
        Assert-E3IHelperLoaded
        foreach ($payload in @(
            '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"known","extra":1}',
            '{"key":"task.isolation.apply","value":"false","type":"boolean","description":"known"}',
            '{"key":"other","value":false,"type":"boolean","description":"known"}',
            '{"key":"task.isolation.apply","value":false,"type":"boolean","description":""}',
            'not-json',
            '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"known"}{"second":true}'
        )) {
            $text = "$payload`n`n`nWall time: 0.12 seconds"
            $result = ConvertFrom-Phase00E3IChildDiagnostic -ToolResult @{
                content = @(@{ type = 'text'; text = $text })
            }
            $result.Status | Should Be 'INVALID_RUN'
        }

        foreach ($text in @(
            '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"known"}',
            "{`"key`":`"task.isolation.apply`",`"value`":false,`"type`":`"boolean`",`"description`":`"known`"}`n`nWall time: 0.12 seconds",
            "{`"key`":`"task.isolation.apply`",`"value`":false,`"type`":`"boolean`",`"description`":`"known`"}`n`n`nWall time: unknown seconds"
        )) {
            $result = ConvertFrom-Phase00E3IChildDiagnostic -ToolResult @{
                content = @(@{ type = 'text'; text = $text })
            }
            $result.Status | Should Be 'INVALID_RUN'
        }
    }
}

Describe 'Phase 00 authoritative assistant outcome precedence' {
    It 'does not classify a superseded assistant error as terminal' {
        $errorMessage = [pscustomobject][ordered]@{
            role = 'assistant'
            stopReason = 'error'
            provider = 'omniroute'
            model = 'test/model'
            errorMessage = 'server_is_overloaded'
        }
        $stopMessage = [pscustomobject][ordered]@{
            role = 'assistant'
            stopReason = 'stop'
            provider = 'omniroute'
            model = 'test/model'
        }
        $events = @(
            [pscustomobject]@{ type = 'message_end'; message = $errorMessage },
            [pscustomobject]@{ type = 'auto_retry_start'; attempt = 1 },
            [pscustomobject]@{ type = 'message_end'; message = $stopMessage },
            [pscustomobject]@{
                type = 'agent_end'; isTerminal = $true; messages = @($stopMessage)
            }
        )

        (Get-Phase00TerminalModelFailure -Events $events).Found | Should Be $false
        $fallback = @(Get-Phase00TerminalModelFailure `
            -Events @($events | Select-Object -First 3))
        $fallback[0].Found | Should Be $false
    }

    It 'still classifies the final authoritative assistant error' {
        $errorMessage = [pscustomobject][ordered]@{
            role = 'assistant'
            stopReason = 'error'
            provider = 'omniroute'
            model = 'test/model'
            errorMessage = 'server_is_overloaded'
        }
        $events = @(
            [pscustomobject]@{ type = 'auto_retry_start'; attempt = 1 },
            [pscustomobject]@{ type = 'message_end'; message = $errorMessage },
            [pscustomobject]@{
                type = 'agent_end'; isTerminal = $true; messages = @($errorMessage)
            }
        )

        $failure = Get-Phase00TerminalModelFailure -Events $events
        $failure.Found | Should Be $true
        $failure.ErrorMessage | Should Be 'server_is_overloaded'
    }

    It 'projects only parent retry starts superseded by a later non-error outcome' {
        $stopMessage = [pscustomobject][ordered]@{
            role = 'assistant'; stopReason = 'stop'; provider = 'omniroute'; model = 'test/model'
        }
        $errorMessage = [pscustomobject][ordered]@{
            role = 'assistant'; stopReason = 'error'; provider = 'omniroute'
            model = 'test/model'; errorMessage = 'server_is_overloaded'
        }
        $recovered = @(Get-Phase00ParentRecoveredProviderRetries -Events @(
            [pscustomobject]@{
                type = 'auto_retry_start'; attempt = 1; maxAttempts = 10
                errorMessage = 'server_is_overloaded'; errorId = 135168
            },
            [pscustomobject]@{ type = 'message_end'; message = $stopMessage }
        ))
        $unrecovered = @(Get-Phase00ParentRecoveredProviderRetries -Events @(
            [pscustomobject]@{
                type = 'auto_retry_start'; attempt = 1; maxAttempts = 10
                errorMessage = 'server_is_overloaded'; errorId = 135168
            },
            [pscustomobject]@{ type = 'message_end'; message = $errorMessage },
            [pscustomobject]@{
                type = 'agent_end'; isTerminal = $true; messages = @($errorMessage)
            }
        ))
        $recoveredBeforeLaterTerminalFailure = @(
            Get-Phase00ParentRecoveredProviderRetries -Events @(
                [pscustomobject]@{
                    type = 'auto_retry_start'; attempt = 1; maxAttempts = 10
                    errorMessage = 'first transient error'; errorId = 135168
                },
                [pscustomobject]@{ type = 'message_end'; message = $stopMessage },
                [pscustomobject]@{ type = 'message_end'; message = $errorMessage },
                [pscustomobject]@{
                    type = 'agent_end'; isTerminal = $true; messages = @($errorMessage)
                }
            )
        )

        $recovered.Count | Should Be 1
        $recovered[0].Attempt | Should Be 1
        $recovered[0].RecoveryStopReason | Should Be 'stop'
        $unrecovered.Count | Should Be 0
        $recoveredBeforeLaterTerminalFailure.Count | Should Be 1
        $recoveredBeforeLaterTerminalFailure[0].RecoveryEventIndex | Should Be 1
    }

    It 'replays Attempts 4 and 5 as recovered parent outcomes' {
        $rawRoot = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-I\raw'
        foreach ($attempt in @(4,5)) {
            $events = @(Read-E3IJsonLines (Join-Path $rawRoot `
                ("session-a-attempt-{0:D3}.stdout.jsonl" -f $attempt)))
            (Get-Phase00TerminalModelFailure -Events $events).Found | Should Be $false
            $recoveries = @(Get-Phase00ParentRecoveredProviderRetries -Events $events)
            ($recoveries.Count -gt 0) | Should Be $true
            $recoveries[-1].RecoveryStopReason | Should Be 'stop'

            $analysis = Test-Phase00E3ISessionA -ParentEvents $events `
                -CanaryEvents (Get-E3IAttemptCanaryEvents $attempt)
            $analysis.Status | Should Be 'INVALID_RUN'
            ($analysis.Reasons -join ',') | Should Be $(if ($attempt -eq 4) {
                'E3I_PARENT_SEQUENCE_MISMATCH'
            } else {
                'E3I_NESTED_PROVIDER_RECOVERY'
            })
        }
    }
}

Describe 'E3-I recovered nested provider failure projection' {
    It 'requires explicit recovered metadata and preserves its fields' {
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

        @(Get-Phase00E3IRecoveredProviderFailures -Events @($bare)).Count |
            Should Be 0
        $facts = @(Get-Phase00E3IRecoveredProviderFailures -Events @($recovered))
        $facts.Count | Should Be 1
        $facts[0].RecoveryKind | Should Be 'auto-retry'
        $facts[0].RecoveryStatus | Should Be 'recovered'
        $facts[0].RecoveryAttempt | Should Be 1
    }
}

Describe 'E3-I task and nested-canary contracts' {
    It 'extracts one exact task sample with positive cost data' {
        Assert-E3IHelperLoaded
        $id = 'e3i-project-1'
        $pair = New-E3ITaskPair $id @((New-E3IResultRow $id)) `
            'Isolation: no changes captured.'

        $sample = Get-Phase00E3ITaskSample -Pair $pair -ExpectedId $id
        $sample.Id | Should Be $id
        $sample.Branch | Should Be 'APPLY_FALSE_CAPTURE_ONLY'
        $sample.Summary | Should Be 'Isolation: no changes captured.'
        ($sample.DurationMs -gt 0) | Should Be $true
        ($sample.Tokens -gt 0) | Should Be $true
        $sample.Acknowledgement | Should Be 'PHASE00_E3I_CANARY_OK'
    }

    It 'rejects plain prose and structurally widened canary outputs' {
        Assert-E3IHelperLoaded
        $id = 'e3i-project-1'
        foreach ($output in @(
            'PHASE00_E3I_CANARY_OK',
            '{"acknowledgement":"PHASE00_E3I_CANARY_OK","extra":true}',
            '{"acknowledgement":"wrong"}'
        )) {
            $row = New-E3IResultRow $id
            $row.output = $output
            $pair = New-E3ITaskPair $id @($row) 'Isolation: no changes captured.'
            $didThrow = $false
            try {
                Get-Phase00E3ITaskSample -Pair $pair -ExpectedId $id | Out-Null
            } catch {
                $didThrow = $true
            }
            $didThrow | Should Be $true
        }
    }

    It 'rejects non-unit, incomplete, and zero-cost task results' {
        Assert-E3IHelperLoaded
        $id = 'e3i-project-1'

        $row = New-E3IResultRow $id
        $invalidRows = @(
            @{ Name = 'two rows'; Rows = @($row, (New-E3IResultRow $id)) },
            @{ Name = 'missing duration'; Rows = @([pscustomobject][ordered]@{
                id = $id; tokens = 34; requests = 1; resolvedModel = 'test/model'
                exitCode = 0; aborted = $false; output = 'PHASE00_E3I_CANARY_OK'
            }) },
            @{ Name = 'zero tokens'; Rows = @([pscustomobject][ordered]@{
                id = $id; durationMs = 1200; tokens = 0; requests = 1
                resolvedModel = 'test/model'; exitCode = 0; aborted = $false
                output = 'PHASE00_E3I_CANARY_OK'
            }) }
        )

        foreach ($case in $invalidRows) {
            $pair = New-E3ITaskPair $id @($case.Rows) 'Isolation: no changes captured.'
            $didThrow = $false
            try {
                Get-Phase00E3ITaskSample -Pair $pair -ExpectedId $id | Out-Null
            } catch {
                $didThrow = $true
            }
            $didThrow | Should Be $true
        }
    }

    It 'accepts only the exact read-yield-hub surface and one terminal yield' {
        Assert-E3IHelperLoaded
        $id = 'e3i-project-1'
        $events = @(
            [pscustomobject]@{
                type = 'session_init'
                agent = 'phase00-e3i-canary'
                tools = @('read','yield','hub')
                readOnly = $true
            },
            [pscustomobject]@{ type = 'agent_start' },
            (New-E3ICanaryToolCallMessage 'yield' ([ordered]@{
                type = 'result'
                result = [ordered]@{
                    data = [ordered]@{ acknowledgement = 'PHASE00_E3I_CANARY_OK' }
                }
            })),
            [pscustomobject]@{ type = 'agent_end'; isTerminal = $true }
        )

        $session = Get-Phase00E3ICanarySession -Events $events -ExpectedId $id
        $session.Id | Should Be $id
        ($session.Tools -join ',') | Should Be 'read,yield,hub'
        $session.ReadOnly | Should Be $true
        $session.ToolCallCount | Should Be 1
        $session.YieldCallCount | Should Be 1
        $session.ForbiddenToolCallCount | Should Be 0
        ($session.ToolNames -join ',') | Should Be 'yield'
        $session.OverrideToolPresent | Should Be $false
    }

    It 'accepts the canonical untyped yield after provider string normalization' {
        Assert-E3IHelperLoaded
        $id = 'e3i-project-1'
        $events = @(
            [pscustomobject]@{
                type = 'session_init'
                agent = 'phase00-e3i-canary'
                tools = @('read','yield','hub')
                readOnly = $true
            },
            (New-E3ICanaryToolCallMessage 'yield' ([ordered]@{
                result = '{"data":{"acknowledgement":"PHASE00_E3I_CANARY_OK"}}'
            }))
        )

        $session = Get-Phase00E3ICanarySession -Events $events -ExpectedId $id
        $session.YieldCallCount | Should Be 1
        $session.ForbiddenToolCallCount | Should Be 0
    }

    It 'rejects an override-contaminated child surface and exposes child tool calls' {
        Assert-E3IHelperLoaded
        $id = 'e3i-project-1'
        $widened = @([pscustomobject]@{
            type = 'session_init'
            agent = 'phase00-e3i-canary'
            tools = @('read','yield','hub','phase00_e3i_override_apply_true')
            readOnly = $true
        })
        $didThrow = $false
        try {
            Get-Phase00E3ICanarySession -Events $widened -ExpectedId $id | Out-Null
        } catch {
            $didThrow = $true
        }
        $didThrow | Should Be $true

        $active = @(
            [pscustomobject]@{
                type = 'session_init'
                agent = 'phase00-e3i-canary'
                tools = @('read','yield','hub')
                readOnly = $true
            },
            (New-E3ICanaryToolCallMessage 'hub' @{ agent = 'x' }),
            (New-E3ICanaryToolCallMessage 'yield' ([ordered]@{
                type = 'result'
                result = [ordered]@{
                    data = [ordered]@{ acknowledgement = 'PHASE00_E3I_CANARY_OK' }
                }
            }))
        )
        $session = Get-Phase00E3ICanarySession -Events $active -ExpectedId $id
        $session.ToolCallCount | Should Be 2
        $session.YieldCallCount | Should Be 1
        $session.ForbiddenToolCallCount | Should Be 1
        ($session.ToolNames -join ',') | Should Be 'hub,yield'

        $wrongYield = @(New-E3ICanaryEvents)
        $yieldMessage = @($wrongYield | Where-Object {
            (Get-Phase00PropertyValue $_ 'type') -eq 'message'
        })[0]
        $yieldMessage.message.content[0].arguments.result.data.acknowledgement = 'wrong'
        $didThrow = $false
        try {
            Get-Phase00E3ICanarySession -Events $wrongYield -ExpectedId $id | Out-Null
        } catch {
            $didThrow = $true
        }
        $didThrow | Should Be $true

        $missingYield = @((New-E3ICanaryEvents) | Where-Object {
            (Get-Phase00PropertyValue $_ 'type') -ne 'message'
        })
        $didThrow = $false
        try {
            Get-Phase00E3ICanarySession -Events $missingYield -ExpectedId $id | Out-Null
        } catch {
            $didThrow = $true
        }
        $didThrow | Should Be $true
    }

    It 'deduplicates one call across message and execution events without hiding another call' {
        Assert-E3IHelperLoaded
        $yieldArguments = [ordered]@{
            type = 'result'
            result = [ordered]@{
                data = [ordered]@{ acknowledgement = 'PHASE00_E3I_CANARY_OK' }
            }
        }
        $events = @(
            [pscustomobject]@{
                type = 'session_init'
                agent = 'phase00-e3i-canary'
                tools = @('read','yield','hub')
                readOnly = $true
            },
            (New-E3ICanaryToolCallMessage 'yield' $yieldArguments 'call-yield'),
            (New-E3ICanaryToolExecutionStart 'yield' 'call-yield'),
            (New-E3ICanaryToolExecutionStart 'hub' 'call-hub' @{ agent = 'x' })
        )

        $session = Get-Phase00E3ICanarySession -Events $events -ExpectedId 'e3i-project-1'
        $session.ToolCallCount | Should Be 2
        $session.YieldCallCount | Should Be 1
        $session.ForbiddenToolCallCount | Should Be 1
        ($session.ToolNames -join ',') | Should Be 'yield,hub'
    }
}

Describe 'E3-I fixture and disposable runner surface' {
    It 'provides every reviewed fixture and runner entry point' {
        $paths = @(
            (Join-Path $e3iFixtureRoot '.omp\config.yml'),
            (Join-Path $e3iFixtureRoot 'overlay.yml'),
            (Join-Path $e3iFixtureRoot '.omp\agents\phase00-e3i-canary.md'),
            (Join-Path $e3iFixtureRoot '.omp\tools\phase00-e3i-runtime-override.ts'),
            (Join-Path $e3iFixtureRoot 'prompts\session-a.md'),
            (Join-Path $e3iFixtureRoot 'prompts\session-b.md'),
            $runnerPath
        )
        foreach ($path in $paths) { Test-Path -LiteralPath $path -PathType Leaf | Should Be $true }

        Assert-E3IRunnerLoaded
        foreach ($name in @(
            'Get-Phase00E3IParentArguments','Initialize-Phase00E3IFixture',
            'Initialize-Phase00E3IPinnedRuntime',
            'Get-Phase00E3IProcessEnvironment',
            'Assert-Phase00E3IDisposableRoot','Remove-Phase00E3IDisposableDirectory',
            'Get-Phase00E3IRepositorySnapshot','Compare-Phase00E3IRepositorySnapshot',
            'Get-Phase00E3IDirectoryMetadataSnapshot',
            'Compare-Phase00E3IDirectoryMetadataSnapshot',
            'Invoke-Phase00E3ICapturedProcess','Copy-Phase00E3ICanaryArtifacts',
            'Write-Phase00E3IUtf8NoBom','Resolve-Phase00E3IRunAnalysis',
            'Invoke-Phase00E3IEvidenceSession'
        )) {
            (Get-Command $name -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        }
    }

    It 'constructs distinct reviewed parent argument arrays without parallel tools' {
        Assert-E3IRunnerLoaded
        $a = @(Get-Phase00E3IParentArguments -Session A -FixtureRoot 'P' `
            -SessionDirectory 'S' -OverlayPath 'O' -Model 'M' -Prompt 'PROMPT')
        $b = @(Get-Phase00E3IParentArguments -Session B -FixtureRoot 'P' `
            -SessionDirectory 'S' -OverlayPath 'O' -Model 'M' -Prompt 'PROMPT')

        ($a -contains '--config') | Should Be $false
        ($b -join ' ') | Should Match '--config O'
        ($a -join ' ') | Should Match '--tools task,bash'
        ($b -join ' ') | Should Match '--tools task,bash'
        ($a -contains 'hub') | Should Be $false
        ($b -contains 'hub') | Should Be $false
        $a[-1] | Should Be 'PROMPT'
        $b[-1] | Should Be 'PROMPT'
    }

    It 'exposes the reader in both parents and the runtime override only in Session A' {
        Assert-E3IRunnerLoaded
        $fixture = [pscustomobject]@{
            AgentDirectory = 'AGENT'
            ProjectRoot = 'PROJECT'
            UserProfileDirectory = 'PROFILE'
        }
        $a = Get-Phase00E3IProcessEnvironment -Session A -Fixture $fixture
        $b = Get-Phase00E3IProcessEnvironment -Session B -Fixture $fixture

        $a.PI_CODING_AGENT_DIR | Should Be 'AGENT'
        $a.USERPROFILE | Should Be 'PROFILE'
        $a.OMP_PHASE00_E3IL_PARENT_CWD | Should Be 'PROJECT'
        $a.OMP_PHASE00_E3IL_ENABLE_OVERRIDE | Should Be '1'
        $b.PI_CODING_AGENT_DIR | Should Be 'AGENT'
        $b.USERPROFILE | Should Be 'PROFILE'
        $b.OMP_PHASE00_E3IL_PARENT_CWD | Should Be 'PROJECT'
        $b.OMP_PHASE00_E3IL_ENABLE_OVERRIDE | Should Be '0'
    }

    It 'locks both augmented prompts to the exact reader and override counts' {
        $a = Get-Content -Raw -LiteralPath `
            (Join-Path $e3iFixtureRoot 'prompts\session-a.md') -Encoding UTF8
        $b = Get-Content -Raw -LiteralPath `
            (Join-Path $e3iFixtureRoot 'prompts\session-b.md') -Encoding UTF8

        ([regex]::Matches($a, 'Call `phase00_e3l_read_apply`').Count) |
            Should Be 2
        ([regex]::Matches($a, 'Call `phase00_e3i_override_apply_true`').Count) |
            Should Be 1
        ([regex]::Matches($b, 'Call `phase00_e3l_read_apply`').Count) |
            Should Be 1
        ([regex]::Matches($b, 'Call `phase00_e3i_override_apply_true`').Count) |
            Should Be 0
        $a.IndexOf('Call `phase00_e3l_read_apply`') -lt
            $a.IndexOf('Call `bash`') | Should Be $true
        $b.IndexOf('Call `phase00_e3l_read_apply`') -lt
            $b.IndexOf('Call `bash`') | Should Be $true
    }

    It 'copies an explicitly selected 17.2.10 runtime and makes nested omp resolution use it' {
        Assert-E3IRunnerLoaded
        $installed = (Get-Command omp -ErrorAction Stop).Source
        $candidates = @(
            $installed
            @(Get-ChildItem -LiteralPath (Split-Path -Parent $installed) -File `
                -Filter 'omp.exe*.bak' -ErrorAction SilentlyContinue | ForEach-Object {
                    $_.FullName
                })
        ) | Select-Object -Unique
        $pinnedSource = $null
        foreach ($candidate in $candidates) {
            $probe = Invoke-Phase00E3ICapturedProcess -FilePath $candidate `
                -Arguments @('--version') -WorkingDirectory $repositoryRoot `
                -Environment @{} -TimeoutSeconds 30
            if ($probe.ExitCode -eq 0 -and $probe.Stdout.Trim() -eq 'omp/17.2.10') {
                $pinnedSource = $candidate
                break
            }
        }
        [string]::IsNullOrWhiteSpace([string]$pinnedSource) | Should Be $false

        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3i-test-{0}" -f [guid]::NewGuid().ToString('N'))
        try {
            $fixture = Initialize-Phase00E3IFixture -Root $safe
            $runtime = Initialize-Phase00E3IPinnedRuntime -Root $safe `
                -SourceExecutable $pinnedSource
            $runtime.Version | Should Be 'omp/17.2.10'
            $runtime.SourceSha256 | Should Be $runtime.CopiedSha256
            Test-Path -LiteralPath $runtime.Executable -PathType Leaf | Should Be $true

            $environment = Get-Phase00E3IProcessEnvironment -Session A `
                -Fixture $fixture -PinnedRuntime $runtime
            $environment.PATH.Split([IO.Path]::PathSeparator)[0] |
                Should Be $runtime.Directory
            $hostProcess = (Get-Process -Id $PID).Path
            $nested = Invoke-Phase00E3ICapturedProcess -FilePath $hostProcess `
                -Arguments @('-NoProfile','-Command','& omp --version') `
                -WorkingDirectory $fixture.ProjectRoot -Environment $environment `
                -TimeoutSeconds 30
            $nested.ExitCode | Should Be 0
            $nested.Stdout.Trim() | Should Be 'omp/17.2.10'
        } finally {
            if (Test-Path -LiteralPath $safe) {
                Remove-Phase00E3IDisposableDirectory -Path $safe
            }
        }
    }

    It 'rejects every unsafe cleanup target and removes one verified temp descendant' {
        Assert-E3IRunnerLoaded
        $unsafe = @(
            $repositoryRoot,
            [Environment]::GetFolderPath('UserProfile'),
            [IO.Path]::GetPathRoot([IO.Path]::GetTempPath()),
            (Join-Path $repositoryRoot 'outside-temp')
        )
        foreach ($path in $unsafe) {
            $didThrow = $false
            try { Assert-Phase00E3IDisposableRoot -Path $path | Out-Null } catch { $didThrow = $true }
            $didThrow | Should Be $true
        }

        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3i-test-{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $safe -Force | Out-Null
        Remove-Phase00E3IDisposableDirectory -Path $safe
        Test-Path -LiteralPath $safe | Should Be $false
    }

    It 'initializes and snapshots only a caller-owned disposable fixture' {
        Assert-E3IRunnerLoaded
        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3i-test-{0}" -f [guid]::NewGuid().ToString('N'))
        $hadParentCwd = Test-Path Env:OMP_PHASE00_E3IL_PARENT_CWD
        $parentCwdBefore = [Environment]::GetEnvironmentVariable(
            'OMP_PHASE00_E3IL_PARENT_CWD', 'Process'
        )
        $hadOverrideFlag = Test-Path Env:OMP_PHASE00_E3IL_ENABLE_OVERRIDE
        $overrideFlagBefore = [Environment]::GetEnvironmentVariable(
            'OMP_PHASE00_E3IL_ENABLE_OVERRIDE', 'Process'
        )
        try {
            $fixture = Initialize-Phase00E3IFixture -Root $safe
            Test-Path -LiteralPath $fixture.AgentDirectory -PathType Container | Should Be $true
            Test-Path -LiteralPath $fixture.ProjectRoot -PathType Container | Should Be $true
            Test-Path -LiteralPath $fixture.SessionDirectory -PathType Container | Should Be $true
            Test-Path -LiteralPath $fixture.UserProfileDirectory -PathType Container |
                Should Be $true
            $fixture.Environment.PI_CODING_AGENT_DIR | Should Be $fixture.AgentDirectory
            $fixture.Environment.USERPROFILE | Should Be $fixture.UserProfileDirectory
            $fixture.Environment.OMP_PHASE00_E3IL_PARENT_CWD | Should Be $fixture.ProjectRoot
            $fixture.Environment.OMP_PHASE00_E3IL_ENABLE_OVERRIDE | Should Be '1'
            [string]::IsNullOrWhiteSpace([string]$fixture.BaselineHead) | Should Be $false

            $node = Get-Command node -ErrorAction Stop
            $homeCapture = Invoke-Phase00E3ICapturedProcess -FilePath $node.Source `
                -Arguments @('-e','process.stdout.write(require("node:os").homedir())') `
                -WorkingDirectory $fixture.ProjectRoot -Environment $fixture.Environment `
                -TimeoutSeconds 30
            $homeCapture.ExitCode | Should Be 0
            $homeCapture.TimedOut | Should Be $false
            [IO.Path]::GetFullPath($homeCapture.Stdout) |
                Should Be ([IO.Path]::GetFullPath($fixture.UserProfileDirectory))

            $before = Get-Phase00E3IRepositorySnapshot -ProjectRoot $fixture.ProjectRoot
            $added = Join-Path $fixture.ProjectRoot 'added-by-test.txt'
            Set-Content -LiteralPath $added -Encoding UTF8 -Value 'changed'
            $changed = Get-Phase00E3IRepositorySnapshot -ProjectRoot $fixture.ProjectRoot
            $comparison = Compare-Phase00E3IRepositorySnapshot -Before $before -After $changed `
                -LiveHomeUnchanged $true -CleanupSucceeded $true
            $comparison.ParentContentUnchanged | Should Be $false
            $comparison.ParentStatusUnchanged | Should Be $false

            Remove-Item -LiteralPath $added -Force
            $restored = Get-Phase00E3IRepositorySnapshot -ProjectRoot $fixture.ProjectRoot
            $comparison = Compare-Phase00E3IRepositorySnapshot -Before $before -After $restored `
                -LiveHomeUnchanged $true -CleanupSucceeded $true
            $comparison.ParentContentUnchanged | Should Be $true
            $comparison.ParentHeadUnchanged | Should Be $true
            $comparison.ParentStatusUnchanged | Should Be $true
            $comparison.FixtureHashesUnchanged | Should Be $true
        } finally {
            if (Test-Path -LiteralPath $safe) {
                Remove-Phase00E3IDisposableDirectory -Path $safe
            }
        }
        (Test-Path Env:OMP_PHASE00_E3IL_PARENT_CWD) | Should Be $hadParentCwd
        [Environment]::GetEnvironmentVariable('OMP_PHASE00_E3IL_PARENT_CWD', 'Process') |
            Should Be $parentCwdBefore
        (Test-Path Env:OMP_PHASE00_E3IL_ENABLE_OVERRIDE) | Should Be $hadOverrideFlag
        [Environment]::GetEnvironmentVariable(
            'OMP_PHASE00_E3IL_ENABLE_OVERRIDE', 'Process'
        ) | Should Be $overrideFlagBefore
    }

    It 'detects metadata changes and leaves process environment unmodified' {
        Assert-E3IRunnerLoaded
        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3i-test-{0}" -f [guid]::NewGuid().ToString('N'))
        $metadataRoot = Join-Path $safe 'metadata'
        $probeName = 'E3I_CAPTURE_PROBE'
        $probeBefore = [Environment]::GetEnvironmentVariable($probeName, 'Process')
        try {
            New-Item -ItemType Directory -Path $metadataRoot -Force | Out-Null
            $before = Get-Phase00E3IDirectoryMetadataSnapshot -Path $metadataRoot
            Set-Content -LiteralPath (Join-Path $metadataRoot 'one.txt') -Encoding UTF8 -Value 'one'
            $after = Get-Phase00E3IDirectoryMetadataSnapshot -Path $metadataRoot
            $change = Compare-Phase00E3IDirectoryMetadataSnapshot -Before $before -After $after
            $change.BoundaryResult | Should Be 'FAIL'
            $change.ChangedCount | Should Be 1

            $missing = Get-Phase00E3IDirectoryMetadataSnapshot `
                -Path (Join-Path $safe 'missing')
            $missing.FileCount | Should Be 0

            $executable = (Get-Process -Id $PID).Path
            $capture = Invoke-Phase00E3ICapturedProcess -FilePath $executable `
                -Arguments @('-NoProfile','-Command',
                    '[Console]::Out.Write([Environment]::GetEnvironmentVariable("E3I_CAPTURE_PROBE","Process"))') `
                -WorkingDirectory $repositoryRoot -Environment @{ $probeName = 'scoped' } `
                -TimeoutSeconds 30
            $capture.ExitCode | Should Be 0
            $capture.TimedOut | Should Be $false
            $capture.Stdout | Should Be 'scoped'
        } finally {
            if (Test-Path -LiteralPath $safe) {
                Remove-Phase00E3IDisposableDirectory -Path $safe
            }
        }
        [Environment]::GetEnvironmentVariable($probeName, 'Process') | Should Be $probeBefore
    }

    It 'captures timeout without leaving the known child running' {
        Assert-E3IRunnerLoaded
        $executable = (Get-Process -Id $PID).Path
        $capture = Invoke-Phase00E3ICapturedProcess -FilePath $executable `
            -Arguments @('-NoProfile','-Command','Start-Sleep -Seconds 5') `
            -WorkingDirectory $repositoryRoot -Environment @{} -TimeoutSeconds 1
        $capture.TimedOut | Should Be $true
        ($capture.CompletedAt -ge $capture.StartedAt) | Should Be $true
    }

    It 'copies exactly one sanitized JSONL per canary and writes UTF-8 without BOM' {
        Assert-E3IRunnerLoaded
        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3i-test-{0}" -f [guid]::NewGuid().ToString('N'))
        $sessions = Join-Path $safe 'sessions'
        $destination = Join-Path $safe 'evidence'
        try {
            foreach ($id in @('e3i-cli-1','e3i-cli-2')) {
                $folder = Join-Path $sessions $id
                New-Item -ItemType Directory -Path $folder -Force | Out-Null
                $jsonl = @(
                    '{"type":"session_init","agent":"phase00-e3i-canary","tools":["read","yield","hub"],"readOnly":true,"systemPrompt":"PRIVATE_SYSTEM_PROMPT"}'
                    '{"type":"message","message":{"role":"assistant","content":[],"providerPayload":{"private":"PRIVATE_PROVIDER_PAYLOAD"},"contextSnapshot":{"private":"PRIVATE_CONTEXT_SNAPSHOT"}}}'
                ) -join "`n"
                Write-Phase00E3IUtf8NoBom -Path (Join-Path $folder "$id.jsonl") -Text $jsonl
            }
            $artifacts = @(Copy-Phase00E3ICanaryArtifacts -SessionDirectory $sessions `
                -DestinationDirectory $destination -Stem 'unit' `
                -ExpectedIds @('e3i-cli-1','e3i-cli-2') -RepositoryRoot $repositoryRoot `
                -DisposableRoot $safe)
            $artifacts.Count | Should Be 2
            ($artifacts.Id -join ',') | Should Be 'e3i-cli-1,e3i-cli-2'
            foreach ($artifact in $artifacts) {
                Test-Path -LiteralPath $artifact.Path -PathType Leaf | Should Be $true
                @($artifact.Events).Count | Should Be 2
                $persisted = [IO.File]::ReadAllText($artifact.Path)
                $persisted | Should Not Match 'PRIVATE_SYSTEM_PROMPT'
                $persisted | Should Not Match 'PRIVATE_PROVIDER_PAYLOAD'
                $persisted | Should Not Match 'PRIVATE_CONTEXT_SNAPSHOT'
                $persisted | Should Match '<SYSTEM_PROMPT_OMITTED>'
                $persisted | Should Match '<PROVIDER_PAYLOAD_OMITTED>'
                $bytes = [IO.File]::ReadAllBytes($artifact.Path)
                ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and
                    $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) | Should Be $false
            }

            $duplicateFolder = Join-Path $sessions 'duplicate'
            New-Item -ItemType Directory -Path $duplicateFolder -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $sessions 'e3i-cli-1\e3i-cli-1.jsonl') `
                -Destination (Join-Path $duplicateFolder 'e3i-cli-1.jsonl')
            $didThrow = $false
            try {
                Copy-Phase00E3ICanaryArtifacts -SessionDirectory $sessions `
                    -DestinationDirectory $destination -Stem 'duplicate' `
                    -ExpectedIds @('e3i-cli-1') -RepositoryRoot $repositoryRoot `
                    -DisposableRoot $safe | Out-Null
            } catch {
                $didThrow = $true
            }
            $didThrow | Should Be $true
        } finally {
            if (Test-Path -LiteralPath $safe) {
                Remove-Phase00E3IDisposableDirectory -Path $safe
            }
        }
    }


    It 'loads the TypeScript factory and gates fixed reader and override surfaces' {
        Assert-E3IRunnerLoaded
        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3i-test-{0}" -f [guid]::NewGuid().ToString('N'))
        $parent = Join-Path $safe 'parent'
        $child = Join-Path $safe 'child'
        try {
            New-Item -ItemType Directory -Path $parent,$child -Force | Out-Null
            $toolPath = Join-Path $e3iFixtureRoot `
                '.omp\tools\phase00-e3i-runtime-override.ts'
            $nodeScript = @'
import assert from "node:assert/strict";
import { pathToFileURL } from "node:url";
const [toolPath, parentCwd, childCwd] = process.argv.slice(1);
const factory = (await import(pathToFileURL(toolPath).href)).default;
const zod = { object: shape => ({ shape }) };
let state = false;
let overrideCalls = 0;
let readCalls = 0;
const settings = {
  get(key) { assert.equal(key, "task.isolation.apply"); readCalls += 1; return state; },
  override(key, value) {
    assert.equal(key, "task.isolation.apply");
    assert.equal(value, true);
    overrideCalls += 1;
    state = value;
  },
};
const api = cwd => ({ cwd, zod, pi: { settings } });
delete process.env.OMP_PHASE00_E3IL_PARENT_CWD;
delete process.env.OMP_PHASE00_E3IL_ENABLE_OVERRIDE;
assert.deepEqual(factory(api(parentCwd)), []);
process.env.OMP_PHASE00_E3IL_PARENT_CWD = parentCwd;
process.env.OMP_PHASE00_E3IL_ENABLE_OVERRIDE = "1";
const toolsA = factory(api(parentCwd));
assert.equal(toolsA.length, 2);
assert.deepEqual(toolsA.map(tool => tool.name), [
  "phase00_e3l_read_apply",
  "phase00_e3i_override_apply_true",
]);
assert.deepEqual(toolsA.map(tool => tool.loadMode), ["essential", "essential"]);
assert.deepEqual(factory(api(childCwd)), []);
process.env.OMP_PHASE00_E3IL_PARENT_CWD = childCwd;
await assert.rejects(
  () => toolsA[0].execute("call", {}, () => {}, {}),
  /P00_E3L_PARENT_SCOPE_MISMATCH/,
);
process.env.OMP_PHASE00_E3IL_PARENT_CWD = parentCwd;
const beforeRead = await toolsA[0].execute("call", {}, () => {}, {});
assert.equal(beforeRead.details.value, false);
assert.equal(beforeRead.details.operation, "pi.pi.settings.get");
assert.equal(beforeRead.details.scope, "parent-only");
const result = await toolsA[1].execute("call", {}, () => {}, {});
assert.equal(overrideCalls, 1);
assert.equal(result.details.before, false);
assert.equal(result.details.after, true);
assert.equal(result.details.operation, "pi.pi.settings.override");
assert.equal(result.details.calledSet, false);
assert.equal(result.details.calledFlushOrSave, false);
assert.equal(result.details.scope, "parent-only");
const afterRead = await toolsA[0].execute("call", {}, () => {}, {});
assert.equal(afterRead.details.value, true);
state = "true";
await assert.rejects(
  () => toolsA[0].execute("call", {}, () => {}, {}),
  /P00_E3L_READER_NON_BOOLEAN/,
);
state = true;
process.env.OMP_PHASE00_E3IL_ENABLE_OVERRIDE = "0";
const toolsB = factory(api(parentCwd));
assert.deepEqual(toolsB.map(tool => tool.name), ["phase00_e3l_read_apply"]);
process.env.OMP_PHASE00_E3IL_ENABLE_OVERRIDE = "yes";
assert.deepEqual(
  factory(api(parentCwd)).map(tool => tool.name),
  ["phase00_e3l_read_apply"],
);
console.log(JSON.stringify({ parentToolsA: toolsA.map(tool => tool.name), parentToolsB: toolsB.map(tool => tool.name), childToolCount: 0, overrideCalls, readCalls }));
'@
            $node = (Get-Command node -ErrorAction Stop).Source
            $capture = Invoke-Phase00E3ICapturedProcess -FilePath $node -Arguments @(
                '--experimental-strip-types','--input-type=module','-e',$nodeScript,
                $toolPath,$parent,$child
            ) -WorkingDirectory $repositoryRoot -Environment @{} -TimeoutSeconds 30
            $capture.ExitCode | Should Be 0
            $capture.TimedOut | Should Be $false
            $observed = $capture.Stdout.Trim() | ConvertFrom-Json
            ($observed.parentToolsA -join ',') | Should Be `
                'phase00_e3l_read_apply,phase00_e3i_override_apply_true'
            ($observed.parentToolsB -join ',') | Should Be 'phase00_e3l_read_apply'
            $observed.childToolCount | Should Be 0
            $observed.overrideCalls | Should Be 1
            $observed.readCalls | Should Be 5
        } finally {
            if (Test-Path -LiteralPath $safe) {
                Remove-Phase00E3IDisposableDirectory -Path $safe
            }
        }
    }

    It 'reads project apply false through the installed OMP config command' {
        Assert-E3IRunnerLoaded
        $safe = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e3i-test-{0}" -f [guid]::NewGuid().ToString('N'))
        try {
            $fixture = Initialize-Phase00E3IFixture -Root $safe
            $environment = Get-Phase00E3IProcessEnvironment `
                -Session B -Fixture $fixture
            $omp = (Get-Command omp -ErrorAction Stop).Source
            $capture = Invoke-Phase00E3ICapturedProcess -FilePath $omp -Arguments @(
                'config','get','task.isolation.apply','--json'
            ) -WorkingDirectory $fixture.ProjectRoot -Environment $environment `
                -TimeoutSeconds 30
            $classification = Get-Phase00ConfigCommandClassification `
                -ExpectedKey 'task.isolation.apply' -ExitCode $capture.ExitCode `
                -Stdout $capture.Stdout -Stderr $capture.Stderr -Context DirectRead
            $classification.Status | Should Be 'OBSERVED'
            $classification.Observation.Type | Should Be 'boolean'
            $classification.Observation.Value | Should Be $false
        } finally {
            if (Test-Path -LiteralPath $safe) {
                Remove-Phase00E3IDisposableDirectory -Path $safe
            }
        }
    }
}

Describe 'E3-I exact parent session protocols' {
    It 'accepts only the complete Session A and Session B procedures' {
        Assert-E3IHelperLoaded
        $fixtureA = New-E3ISessionFixture A
        $fixtureB = New-E3ISessionFixture B

        $sessionA = Test-Phase00E3ISessionA `
            -ParentEvents $fixtureA.ParentEvents -CanaryEvents $fixtureA.CanaryEvents
        $sessionB = Test-Phase00E3ISessionB `
            -ParentEvents $fixtureB.ParentEvents -CanaryEvents $fixtureB.CanaryEvents

        $sessionA.Status | Should Be 'PASS'
        $sessionB.Status | Should Be 'PASS'
        ($sessionA.ProjectSamples.Id -join ',') |
            Should Be 'e3i-project-1,e3i-project-2,e3i-project-3'
        ($sessionA.RuntimeSamples.Id -join ',') |
            Should Be 'e3i-runtime-1,e3i-runtime-2,e3i-runtime-3'
        ($sessionB.CliSamples.Id -join ',') |
            Should Be 'e3i-cli-1,e3i-cli-2,e3i-cli-3'
    }

    It 'invalidates missing, extra, reordered, duplicated, errored, or renamed calls' {
        Assert-E3IHelperLoaded
        foreach ($sessionName in @('A','B')) {
            $firstTaskId = if ($sessionName -eq 'A') {
                'e3i-project-1'
            } else {
                'e3i-cli-1'
            }
            $variants = @()

            $fixture = New-E3ISessionFixture $sessionName
            $variants += [pscustomobject]@{
                Name = 'missing call'
                ParentEvents = @($fixture.ParentEvents | Where-Object {
                    (Get-Phase00PropertyValue $_ 'toolCallId') -ne "call-$firstTaskId"
                })
                CanaryEvents = $fixture.CanaryEvents
            }

            $fixture = New-E3ISessionFixture $sessionName
            $extra = New-E3IBashPair 'call-extra'
            $variants += [pscustomobject]@{
                Name = 'extra call'
                ParentEvents = @($fixture.ParentEvents + @($extra.Start, $extra.End))
                CanaryEvents = $fixture.CanaryEvents
            }

            $fixture = New-E3ISessionFixture $sessionName
            $pairs = @(Get-Phase00E3IToolEventPairs -Events $fixture.ParentEvents)
            $swapped = @($pairs[0], $pairs[2], $pairs[1])
            if ($pairs.Count -gt 3) { $swapped += @($pairs | Select-Object -Skip 3) }
            $swappedEvents = @($swapped | ForEach-Object { $_.Start; $_.End })
            $variants += [pscustomobject]@{
                Name = 'reordered calls'
                ParentEvents = $swappedEvents
                CanaryEvents = $fixture.CanaryEvents
            }

            $fixture = New-E3ISessionFixture $sessionName
            $pairs = @(Get-Phase00E3IToolEventPairs -Events $fixture.ParentEvents)
            $variants += [pscustomobject]@{
                Name = 'duplicate result'
                ParentEvents = @($fixture.ParentEvents + $pairs[1].End)
                CanaryEvents = $fixture.CanaryEvents
            }

            $fixture = New-E3ISessionFixture $sessionName
            $taskEnd = @($fixture.ParentEvents | Where-Object {
                (Get-Phase00PropertyValue $_ 'type') -eq 'tool_execution_end' -and
                (Get-Phase00PropertyValue $_ 'toolCallId') -eq "call-$firstTaskId"
            })[0]
            $taskEnd.isError = $true
            $variants += [pscustomobject]@{
                Name = 'errored task result'
                ParentEvents = $fixture.ParentEvents
                CanaryEvents = $fixture.CanaryEvents
            }

            $fixture = New-E3ISessionFixture $sessionName
            $taskStart = @($fixture.ParentEvents | Where-Object {
                (Get-Phase00PropertyValue $_ 'type') -eq 'tool_execution_start' -and
                (Get-Phase00PropertyValue $_ 'toolCallId') -eq "call-$firstTaskId"
            })[0]
            $taskStart.args.tasks[0].name = 'wrong-id'
            $variants += [pscustomobject]@{
                Name = 'renamed task'
                ParentEvents = $fixture.ParentEvents
                CanaryEvents = $fixture.CanaryEvents
            }

            foreach ($variant in $variants) {
                $analysis = if ($sessionName -eq 'A') {
                    Test-Phase00E3ISessionA -ParentEvents $variant.ParentEvents `
                        -CanaryEvents $variant.CanaryEvents
                } else {
                    Test-Phase00E3ISessionB -ParentEvents $variant.ParentEvents `
                        -CanaryEvents $variant.CanaryEvents
                }
                $analysis.Status | Should Be 'INVALID_RUN'
            }
        }
    }

    It 'invalidates any change to diagnostic or override invocation arguments' {
        Assert-E3IHelperLoaded
        foreach ($sessionName in @('A','B')) {
            $variants = @()

            $fixture = New-E3ISessionFixture $sessionName
            $bashStart = @($fixture.ParentEvents | Where-Object {
                (Get-Phase00PropertyValue $_ 'type') -eq 'tool_execution_start' -and
                (Get-Phase00PropertyValue $_ 'toolName') -eq 'bash'
            })[0]
            $bashStart.args.command = 'different command'
            $variants += $fixture

            $fixture = New-E3ISessionFixture $sessionName
            $bashStart = @($fixture.ParentEvents | Where-Object {
                (Get-Phase00PropertyValue $_ 'type') -eq 'tool_execution_start' -and
                (Get-Phase00PropertyValue $_ 'toolName') -eq 'bash'
            })[0]
            $bashStart.args.timeout = '60'
            $variants += $fixture

            $fixture = New-E3ISessionFixture $sessionName
            $bashStart = @($fixture.ParentEvents | Where-Object {
                (Get-Phase00PropertyValue $_ 'type') -eq 'tool_execution_start' -and
                (Get-Phase00PropertyValue $_ 'toolName') -eq 'bash'
            })[0]
            $bashStart.args['extra'] = 1
            $variants += $fixture

            if ($sessionName -eq 'A') {
                $fixture = New-E3ISessionFixture A
                $overrideStart = @($fixture.ParentEvents | Where-Object {
                    (Get-Phase00PropertyValue $_ 'type') -eq 'tool_execution_start' -and
                    (Get-Phase00PropertyValue $_ 'toolName') -eq
                        'phase00_e3i_override_apply_true'
                })[0]
                $overrideStart.args['value'] = $true
                $variants += $fixture
            }

            foreach ($variant in $variants) {
                $analysis = if ($sessionName -eq 'A') {
                    Test-Phase00E3ISessionA -ParentEvents $variant.ParentEvents `
                        -CanaryEvents $variant.CanaryEvents
                } else {
                    Test-Phase00E3ISessionB -ParentEvents $variant.ParentEvents `
                        -CanaryEvents $variant.CanaryEvents
                }
                $analysis.Status | Should Be 'INVALID_RUN'
            }
        }
    }
}

Describe 'E3-I override attestation and failure precedence' {
    It 'passes only the exact parent-only override attestation' {
        Assert-E3IHelperLoaded
        $analysis = ConvertFrom-Phase00E3IOverrideResult `
            -ToolResult (New-E3IOverrideToolResult)
        $analysis.Status | Should Be 'PASS'
        ($analysis.Reasons -join ',') | Should Be 'E3I_OVERRIDE_ATTESTED'

        $mutations = @('missing-setting','before-true','after-false','operation','called-set',
            'called-save','extra-property')
        foreach ($mutation in $mutations) {
            $details = New-E3IOverrideDetails
            switch ($mutation) {
                'missing-setting' { $details.PSObject.Properties.Remove('setting') }
                'before-true' { $details.before = $true }
                'after-false' { $details.after = $false }
                'operation' { $details.operation = 'Settings.set' }
                'called-set' { $details.calledSet = $true }
                'called-save' { $details.calledFlushOrSave = $true }
                'extra-property' { $details | Add-Member NoteProperty extra 1 }
            }
            $wrong = ConvertFrom-Phase00E3IOverrideResult `
                -ToolResult (New-E3IOverrideToolResult $details)
            $wrong.Status | Should Be 'FAIL'
            ($wrong.Reasons -join ',') | Should Match 'E3I_OVERRIDE_CONTRADICTION'
        }
    }

    It 'distinguishes malformed override evidence from an attributable tool contradiction' {
        Assert-E3IHelperLoaded
        $malformed = ConvertFrom-Phase00E3IOverrideResult -ToolResult @{
            content = @(@{ type = 'text'; text = '{}' })
        }
        $malformed.Status | Should Be 'INVALID_RUN'

        $fixture = New-E3ISessionFixture A
        $overrideEnd = @($fixture.ParentEvents | Where-Object {
            (Get-Phase00PropertyValue $_ 'type') -eq 'tool_execution_end' -and
            (Get-Phase00PropertyValue $_ 'toolName') -eq
                'phase00_e3i_override_apply_true'
        })[0]
        $overrideEnd.isError = $true
        $analysis = Test-Phase00E3ISessionA -ParentEvents $fixture.ParentEvents `
            -CanaryEvents $fixture.CanaryEvents
        $analysis.Status | Should Be 'INVALID_RUN'
        ($analysis.Reasons -join ',') | Should Match 'E3I_OVERRIDE_EXECUTION_ERROR'
    }

    It 'lets terminal provider evidence win before missing canary provenance' {
        Assert-E3IHelperLoaded
        foreach ($message in @(
            'Quota exhausted',
            'Authentication failed for provider',
            'Provider overloaded; service temporarily unavailable',
            'Requested model not found'
        )) {
            $parentBlocked = Test-Phase00E3ISessionA `
                -ParentEvents (New-E3ITerminalFailureEvents $message) `
                -CanaryEvents @{}
            $parentBlocked.Status | Should Be 'BLOCKED_ENVIRONMENT'
        }

        $fixture = New-E3ISessionFixture B
        $nestedBlocked = @{
            'e3i-cli-1' = @(New-E3ITerminalFailureEvents 'Unable to connect to provider')
        }
        $analysis = Test-Phase00E3ISessionB -ParentEvents $fixture.ParentEvents `
            -CanaryEvents $nestedBlocked
        $analysis.Status | Should Be 'BLOCKED_ENVIRONMENT'

        $nestedTerminal = @{
            'e3i-cli-1' = @(New-E3ITerminalFailureEvents 'Unexpected model crash')
        }
        $analysis = Test-Phase00E3ISessionB -ParentEvents $fixture.ParentEvents `
            -CanaryEvents $nestedTerminal
        $analysis.Status | Should Be 'INVALID_RUN'

        $analysis = Test-Phase00E3ISessionB -ParentEvents $fixture.ParentEvents `
            -CanaryEvents @{}
        $analysis.Status | Should Be 'INVALID_RUN'
        ($analysis.Reasons -join ',') | Should Match 'E3I_CANARY_PROVENANCE_MISSING'
    }

    It 'invalidates a nested provider error that recovered inside the same canary' {
        Assert-E3IHelperLoaded
        $fixture = New-E3ISessionFixture B
        $events = @(New-E3ICanaryEvents)
        $recoveredError = [pscustomobject][ordered]@{
            type = 'message'
            message = [pscustomobject][ordered]@{
                role = 'assistant'
                stopReason = 'error'
                provider = 'omniroute'
                model = 'codex/gpt-5.6-sol-high'
                errorMessage = 'Error Code server_is_overloaded: recovered on retry.'
                content = @()
                retryRecovery = [pscustomobject][ordered]@{
                    kind = 'auto-retry'
                    status = 'recovered'
                    attempt = 1
                }
            }
        }
        $events = @($events[0..1] + @($recoveredError) + $events[2..($events.Count - 1)])
        $fixture.CanaryEvents['e3i-cli-1'] = $events

        $analysis = Test-Phase00E3ISessionB -ParentEvents $fixture.ParentEvents `
            -CanaryEvents $fixture.CanaryEvents
        $analysis.Status | Should Be 'INVALID_RUN'
        ($analysis.Reasons -join ',') | Should Be 'E3I_NESTED_PROVIDER_RECOVERY'
    }

    It 'keeps timeout invalid and override-tool leakage semantic' {
        Assert-E3IHelperLoaded
        $fixture = New-E3ISessionFixture B
        $timeout = Test-Phase00E3ISessionB -ParentEvents $fixture.ParentEvents `
            -CanaryEvents $fixture.CanaryEvents -TimedOut $true
        $timeout.Status | Should Be 'INVALID_RUN'
        ($timeout.Reasons -join ',') | Should Be 'E3I_TIMEOUT'

        $fixture = New-E3ISessionFixture B
        $fixture.CanaryEvents['e3i-cli-1'] = @(New-E3ICanaryEvents -Tools @(
            'read','yield','hub','phase00_e3i_override_apply_true'
        ))
        $leak = Test-Phase00E3ISessionB -ParentEvents $fixture.ParentEvents `
            -CanaryEvents $fixture.CanaryEvents
        $leak.Status | Should Be 'FAIL'
        ($leak.Reasons -join ',') | Should Be 'E3I_CANARY_TOOL_SURFACE_CONTAMINATED'
    }
}

Describe 'E3-I I1-I4 conjunction adjudication' {
    It 'passes all four cases only when every predicate is present' {
        Assert-E3IHelperLoaded
        $fixtureA = New-E3ISessionFixture A
        $fixtureB = New-E3ISessionFixture B
        $sessionA = Test-Phase00E3ISessionA -ParentEvents $fixtureA.ParentEvents `
            -CanaryEvents $fixtureA.CanaryEvents
        $sessionB = Test-Phase00E3ISessionB -ParentEvents $fixtureB.ParentEvents `
            -CanaryEvents $fixtureB.CanaryEvents
        $boundary = New-E3IBoundary

        $i1 = Test-Phase00I1Evidence -SessionA $sessionA
        $i2 = Test-Phase00I2Evidence -SessionA $sessionA -Boundary $boundary
        $i3 = Test-Phase00I3Evidence -SessionB $sessionB
        $i4 = Test-Phase00I4Evidence -SessionA $sessionA -SessionB $sessionB `
            -Boundary $boundary

        $i1.Status | Should Be 'PASS'
        $i2.Status | Should Be 'PASS'
        $i3.Status | Should Be 'PASS'
        $i4.Status | Should Be 'PASS'
        ($i1.Reasons -join ',') | Should Be 'E3I_PROJECT_CONTROL_CONFIRMED'
        ($i2.Reasons -join ',') | Should Be 'E3I_RUNTIME_OVERRIDE_DIVERGENCE_CONFIRMED'
        ($i3.Reasons -join ',') | Should Be 'E3I_CLI_OVERLAY_DIVERGENCE_CONFIRMED'
        ($i4.Reasons -join ',') | Should Be 'E3I_CANARY_SAFETY_RELIABILITY_CONFIRMED'
        foreach ($result in @($i1,$i2,$i3,$i4)) {
            (($result | ConvertTo-Json -Depth 12) -match 'ALLOW_PARALLEL') | Should Be $false
        }
    }

    It 'fails complete semantic contradictions without converting them to invalid runs' {
        Assert-E3IHelperLoaded
        $fixtureA = New-E3ISessionFixture A
        $sessionA = Test-Phase00E3ISessionA -ParentEvents $fixtureA.ParentEvents `
            -CanaryEvents $fixtureA.CanaryEvents
        $sessionA.Diagnostics[0].Value = $true
        (Test-Phase00I1Evidence -SessionA $sessionA).Status | Should Be 'FAIL'

        $fixtureA = New-E3ISessionFixture A
        $sessionA = Test-Phase00E3ISessionA -ParentEvents $fixtureA.ParentEvents `
            -CanaryEvents $fixtureA.CanaryEvents
        $sessionA.ProjectSamples[0].Branch = 'APPLY_TRUE_NO_DIFF'
        (Test-Phase00I1Evidence -SessionA $sessionA).Status | Should Be 'FAIL'

        $fixtureB = New-E3ISessionFixture B
        $fixtureB.CanaryEvents['e3i-cli-1'] = @(New-E3ICanaryEvents -AddHubCall $true)
        $sessionB = Test-Phase00E3ISessionB -ParentEvents $fixtureB.ParentEvents `
            -CanaryEvents $fixtureB.CanaryEvents
        (Test-Phase00I3Evidence -SessionB $sessionB).Status | Should Be 'FAIL'

        $fixtureA = New-E3ISessionFixture A
        $sessionA = Test-Phase00E3ISessionA -ParentEvents $fixtureA.ParentEvents `
            -CanaryEvents $fixtureA.CanaryEvents
        $sessionA.Override.Details.calledSet = $true
        $boundary = New-E3IBoundary
        (Test-Phase00I2Evidence -SessionA $sessionA -Boundary $boundary).Status |
            Should Be 'FAIL'
    }

    It 'separates cost, mutation, live-home, and cleanup outcomes in I4' {
        Assert-E3IHelperLoaded
        $fixtureA = New-E3ISessionFixture A
        $fixtureB = New-E3ISessionFixture B
        $sessionA = Test-Phase00E3ISessionA -ParentEvents $fixtureA.ParentEvents `
            -CanaryEvents $fixtureA.CanaryEvents
        $sessionB = Test-Phase00E3ISessionB -ParentEvents $fixtureB.ParentEvents `
            -CanaryEvents $fixtureB.CanaryEvents

        $sessionA.ProjectSamples[0].Tokens = 0
        $analysis = Test-Phase00I4Evidence -SessionA $sessionA -SessionB $sessionB `
            -Boundary (New-E3IBoundary)
        $analysis.Status | Should Be 'INVALID_RUN'
        ($analysis.Reasons -join ',') | Should Match 'E3I_COST_OBSERVATION_MISSING'

        $fixtureA = New-E3ISessionFixture A
        $sessionA = Test-Phase00E3ISessionA -ParentEvents $fixtureA.ParentEvents `
            -CanaryEvents $fixtureA.CanaryEvents
        $boundary = New-E3IBoundary
        $boundary.ParentContentUnchanged = $false
        (Test-Phase00I4Evidence -SessionA $sessionA -SessionB $sessionB `
            -Boundary $boundary).Status | Should Be 'FAIL'

        $boundary = New-E3IBoundary
        $boundary.LiveHomeUnchanged = $false
        (Test-Phase00I4Evidence -SessionA $sessionA -SessionB $sessionB `
            -Boundary $boundary).Status | Should Be 'FAIL'

        $boundary = New-E3IBoundary
        $boundary.CleanupSucceeded = $false
        $analysis = Test-Phase00I4Evidence -SessionA $sessionA -SessionB $sessionB `
            -Boundary $boundary
        $analysis.Status | Should Be 'INVALID_RUN'
        ($analysis.Reasons -join ',') | Should Match 'E3I_CLEANUP_UNCERTAIN'
    }
}

Describe 'E3-I selected-run boundary precedence' {
    It 'never promotes a parser or provenance exception by scanning unrelated transcript text' {
        Assert-E3IRunnerLoaded

        $analysis = New-Phase00E3ICaptureFailureAnalysis `
            -ErrorMessage "The property 'Name' cannot be found." -TimedOut $false
        $analysis.Status | Should Be 'INVALID_RUN'
        ($analysis.Reasons -join ',') | Should Be 'E3I_CANARY_PROVENANCE_MISSING'

        $timedOut = New-Phase00E3ICaptureFailureAnalysis `
            -ErrorMessage 'Parser stopped after capture.' -TimedOut $true
        $timedOut.Status | Should Be 'INVALID_RUN'
        ($timedOut.Reasons -join ',') | Should Be 'E3I_TIMEOUT'
    }

    It 'keeps harness defects and unattributed live-home noise invalid but attributable mutations fail' {
        Assert-E3IRunnerLoaded
        $clean = New-E3IBoundary
        $invalid = New-Phase00E3IAnalysis INVALID_RUN @('E3I_EVENT_PAIRING_INVALID')

        $noisy = New-E3IBoundary
        $noisy.LiveHomeUnchanged = $false
        $resolved = Resolve-Phase00E3IRunAnalysis -SessionAnalysis $invalid `
            -Boundary $noisy -LiveHomeMutationAttributable $false
        $resolved.Status | Should Be 'INVALID_RUN'
        ($resolved.Reasons -join ',') | Should Match 'E3I_EVENT_PAIRING_INVALID'
        ($resolved.Reasons -join ',') | Should Match 'E3I_LIVE_HOME_CONCURRENT_ACTIVITY'

        $semantic = New-Phase00E3IAnalysis PASS @('E3I_SESSION_A_EXACT')
        $unattributed = Resolve-Phase00E3IRunAnalysis -SessionAnalysis $semantic `
            -Boundary $noisy -LiveHomeMutationAttributable $false
        $unattributed.Status | Should Be 'INVALID_RUN'
        ($unattributed.Reasons -join ',') | Should Be 'E3I_LIVE_HOME_CONCURRENT_ACTIVITY'

        $attributed = Resolve-Phase00E3IRunAnalysis -SessionAnalysis $semantic `
            -Boundary $noisy -LiveHomeMutationAttributable $true
        $attributed.Status | Should Be 'FAIL'
        ($attributed.Reasons -join ',') | Should Be 'E3I_LIVE_HOME_MUTATION'

        $mutated = New-E3IBoundary
        $mutated.ParentContentUnchanged = $false
        $parentFailure = Resolve-Phase00E3IRunAnalysis -SessionAnalysis $invalid `
            -Boundary $mutated -LiveHomeMutationAttributable $false
        $parentFailure.Status | Should Be 'FAIL'
        ($parentFailure.Reasons -join ',') | Should Be 'E3I_PARENT_MUTATION'

        $cleanup = New-E3IBoundary
        $cleanup.CleanupSucceeded = $false
        $cleanupResult = Resolve-Phase00E3IRunAnalysis -SessionAnalysis $semantic `
            -Boundary $cleanup -LiveHomeMutationAttributable $false `
            -CleanupError 'known cleanup failure'
        $cleanupResult.Status | Should Be 'INVALID_RUN'
        ($cleanupResult.Reasons -join ',') | Should Be 'E3I_CLEANUP_UNCERTAIN'

        (Resolve-Phase00E3IRunAnalysis -SessionAnalysis $semantic `
            -Boundary $clean -LiveHomeMutationAttributable $false).Status | Should Be 'PASS'
    }
}

Describe 'E3-I preserved Attempt 1 adjudication' {
    It 'hash-links the non-selected harness-invalid attempt without rewriting raw history' {
        $adjudicationPath = Join-Path $repositoryRoot `
            'docs\evidence\phase-00\E3-I\raw\session-a.attempt-001.adjudication.json'
        Test-Path -LiteralPath $adjudicationPath -PathType Leaf | Should Be $true
        $record = Get-Content -LiteralPath $adjudicationPath -Raw | ConvertFrom-Json
        $record.schema_version | Should Be 1
        $record.experiment | Should Be 'E3-I'
        $record.session | Should Be 'A'
        $record.attempt | Should Be 1
        $record.selected | Should Be $false
        $record.original_runner_analysis.status | Should Be 'FAIL'
        $record.corrected_adjudication.status | Should Be 'INVALID_RUN'
        ($record.corrected_adjudication.reasons -join ',') |
            Should Be 'E3I_EVENT_PAIRING_INVALID,E3I_OVERRIDE_EXECUTION_ERROR,E3I_LIVE_HOME_CONCURRENT_ACTIVITY'
        $record.corrected_adjudication.retry_eligible_after_regression | Should Be $true
        $record.provider_execution.session_b_launched | Should Be $false

        foreach ($artifact in @($record.raw_artifacts)) {
            $path = Join-Path (Split-Path -Parent $adjudicationPath) $artifact.file
            Test-Path -LiteralPath $path -PathType Leaf | Should Be $true
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash |
                Should Be $artifact.sha256
        }
    }
}

Describe 'E3-I preserved Attempt 2 adjudication' {
    It 'hash-links the non-selected harness-invalid attempt and records every correction cause' {
        $adjudicationPath = Join-Path $repositoryRoot `
            'docs\evidence\phase-00\E3-I\raw\session-a.attempt-002.adjudication.json'
        Test-Path -LiteralPath $adjudicationPath -PathType Leaf | Should Be $true
        $record = Get-Content -LiteralPath $adjudicationPath -Raw | ConvertFrom-Json
        $record.schema_version | Should Be 1
        $record.experiment | Should Be 'E3-I'
        $record.session | Should Be 'A'
        $record.attempt | Should Be 2
        $record.selected | Should Be $false
        $record.original_runner_analysis.status | Should Be 'BLOCKED_ENVIRONMENT'
        $record.corrected_adjudication.status | Should Be 'INVALID_RUN'
        ($record.corrected_adjudication.reasons -join ',') | Should Be `
            'E3I_NESTED_PROVIDER_RECOVERY,E3I_CANARY_PROTOCOL_CONTRACT_INVALID,E3I_AMBIENT_CAPABILITY_DISCOVERY,E3I_CAPTURE_CLASSIFIER_INVALID'
        $record.corrected_adjudication.selection_eligible | Should Be $false
        $record.corrected_adjudication.retry_eligible_after_regression | Should Be $true
        $record.provider_execution.session_a_launches | Should Be 1
        $record.provider_execution.session_a_retry_launched | Should Be $false
        $record.provider_execution.session_b_launched | Should Be $false
        $record.provider_execution.automatic_retry_performed | Should Be $false
        $record.raw_artifacts.Count | Should Be 9

        foreach ($artifact in @($record.raw_artifacts)) {
            $path = Join-Path (Split-Path -Parent $adjudicationPath) $artifact.file
            Test-Path -LiteralPath $path -PathType Leaf | Should Be $true
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash |
                Should Be $artifact.sha256
        }
    }
}

Describe 'E3-I preserved Attempt 3 adjudication' {
    It 'hash-links the clean-boundary provider-recovered attempt without selecting it' {
        $adjudicationPath = Join-Path $repositoryRoot `
            'docs\evidence\phase-00\E3-I\raw\session-a.attempt-003.adjudication.json'
        Test-Path -LiteralPath $adjudicationPath -PathType Leaf | Should Be $true
        $record = Get-Content -LiteralPath $adjudicationPath -Raw | ConvertFrom-Json
        $record.schema_version | Should Be 1
        $record.experiment | Should Be 'E3-I'
        $record.session | Should Be 'A'
        $record.attempt | Should Be 3
        $record.selected | Should Be $false
        $record.corrected_adjudication.status | Should Be 'INVALID_RUN'
        ($record.corrected_adjudication.reasons -join ',') |
            Should Be 'E3I_NESTED_PROVIDER_RECOVERY'
        $record.corrected_adjudication.canary_id | Should Be 'e3i-project-2'
        $record.corrected_adjudication.selection_eligible | Should Be $false
        $record.provider_execution.session_a_launches | Should Be 1
        $record.provider_execution.session_a_retry_launched | Should Be $false
        $record.provider_execution.session_b_launched | Should Be $false
        $record.boundary.ParentContentUnchanged | Should Be $true
        $record.boundary.ParentHeadUnchanged | Should Be $true
        $record.boundary.ParentStatusUnchanged | Should Be $true
        $record.boundary.FixtureHashesUnchanged | Should Be $true
        $record.boundary.LiveHomeUnchanged | Should Be $true
        $record.boundary.CleanupSucceeded | Should Be $true
        $record.raw_artifacts.Count | Should Be 9

        foreach ($artifact in @($record.raw_artifacts)) {
            $path = Join-Path (Split-Path -Parent $adjudicationPath) $artifact.file
            Test-Path -LiteralPath $path -PathType Leaf | Should Be $true
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash |
                Should Be $artifact.sha256
        }
    }
}

Describe 'E3-I preserved Attempt 4 terminal environment block' {
    It 'preserves the first adjudication byte-for-byte as historical evidence' {
        $adjudicationPath = Join-Path $repositoryRoot `
            'docs\evidence\phase-00\E3-I\raw\session-a.attempt-004.adjudication.json'
        Test-Path -LiteralPath $adjudicationPath -PathType Leaf | Should Be $true
        $record = Get-Content -LiteralPath $adjudicationPath -Raw | ConvertFrom-Json
        $record.schema_version | Should Be 1
        $record.experiment | Should Be 'E3-I'
        $record.session | Should Be 'A'
        $record.attempt | Should Be 4
        $record.selected | Should Be $false
        $record.adjudication.status | Should Be 'BLOCKED_ENVIRONMENT'
        ($record.adjudication.reasons -join ',') |
            Should Be 'P00-RUNTIME-PROVIDER-OVERLOAD'
        $record.adjudication.failure_scope | Should Be 'parent-terminal'
        $record.adjudication.selection_eligible | Should Be $false
        $record.provider_execution.session_a_launches | Should Be 1
        $record.provider_execution.session_a_retry_launched | Should Be $false
        $record.provider_execution.session_b_launched | Should Be $false
        $record.provider_execution.automatic_retry_performed | Should Be $false
        $record.boundary.ParentContentUnchanged | Should Be $true
        $record.boundary.ParentHeadUnchanged | Should Be $true
        $record.boundary.ParentStatusUnchanged | Should Be $true
        $record.boundary.FixtureHashesUnchanged | Should Be $true
        $record.boundary.LiveHomeUnchanged | Should Be $true
        $record.boundary.CleanupSucceeded | Should Be $true
        $record.raw_artifacts.Count | Should Be 9

        foreach ($artifact in @($record.raw_artifacts)) {
            $path = Join-Path (Split-Path -Parent $adjudicationPath) $artifact.file
            Test-Path -LiteralPath $path -PathType Leaf | Should Be $true
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash |
                Should Be $artifact.sha256
        }
    }

    It 'keeps Attempt 4 non-authoritative after the complete Attempt 7 selection' {
        foreach ($case in @('I1','I2','I3','I4')) {
            $casePath = Join-Path $repositoryRoot `
                "docs\evidence\phase-00\E3-I\$case.yml"
            Test-Path -LiteralPath $casePath -PathType Leaf | Should Be $true
            $caseRaw = Get-Content -LiteralPath $casePath -Raw -Encoding UTF8
            $caseRaw | Should Match '(?m)^selected_attempt: 7$'
            $caseRaw | Should Not Match '(?m)^selected_attempt: 4$'
        }
    }

    It 'adds a second hash-linked adjudication with corrected terminal precedence' {
        $path = Join-Path $repositoryRoot `
            'docs\evidence\phase-00\E3-I\raw\session-a.attempt-004.adjudication-002.json'
        Test-Path -LiteralPath $path -PathType Leaf | Should Be $true
        $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $record.schema_version | Should Be 2
        $record.experiment | Should Be 'E3-I'
        $record.session | Should Be 'A'
        $record.attempt | Should Be 4
        $record.selected | Should Be $false
        $record.correction_of.path | Should Be `
            'docs/evidence/phase-00/E3-I/raw/session-a.attempt-004.adjudication.json'
        $predecessor = Join-Path $repositoryRoot $record.correction_of.path
        (Get-FileHash -LiteralPath $predecessor -Algorithm SHA256).Hash |
            Should Be $record.correction_of.sha256
        $record.correction_reason | Should Be `
            'E3I_PARENT_TERMINAL_PRECEDENCE_SUPERSESSION'
        $record.original_adjudication.status | Should Be 'BLOCKED_ENVIRONMENT'
        $record.corrected_adjudication.status | Should Be 'INVALID_RUN'
        ($record.corrected_adjudication.reasons -join ',') |
            Should Be 'E3I_PARENT_SEQUENCE_MISMATCH'
        $record.corrected_adjudication.selection_eligible | Should Be $false
        $record.authoritative_outcome.source | Should Be 'terminal-agent-end'
        $record.authoritative_outcome.event_line | Should Be 612
        $record.authoritative_outcome.stop_reason | Should Be 'stop'
        $record.authoritative_outcome.completion_text | Should Be 'E3I_SESSION_A_DONE'
        $record.parent_retry_recovery.observed | Should Be $true
        $record.parent_retry_recovery.count | Should Be 1
        ($record.parent_retry_recovery.start_event_lines -join ',') | Should Be '594'
        $record.nested_provider_recovery.observed | Should Be $false
        $record.provider_execution.new_provider_call | Should Be $false
        $record.provider_execution.session_b_launched | Should Be $false
        $record.raw_artifacts.Count | Should Be 9
        foreach ($artifact in @($record.raw_artifacts)) {
            $artifactPath = Join-Path (Split-Path -Parent $path) $artifact.file
            (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash |
                Should Be $artifact.sha256
        }
    }
}

Describe 'E3-I Attempt 5 joint terminal environment block' {
    It 'preserves the first adjudication byte-for-byte as historical evidence' {
        $adjudicationPath = Join-Path $repositoryRoot `
            'docs\evidence\phase-00\E3-I\raw\session-a.attempt-005.adjudication.json'
        Test-Path -LiteralPath $adjudicationPath -PathType Leaf | Should Be $true
        $record = Get-Content -LiteralPath $adjudicationPath -Raw | ConvertFrom-Json
        $record.schema_version | Should Be 1
        $record.experiment | Should Be 'E3-I'
        $record.session | Should Be 'A'
        $record.attempt | Should Be 5
        $record.selected | Should Be $false
        $record.adjudication.status | Should Be 'BLOCKED_ENVIRONMENT'
        ($record.adjudication.reasons -join ',') |
            Should Be 'P00-RUNTIME-PROVIDER-OVERLOAD'
        $record.adjudication.failure_scope | Should Be 'parent-terminal'
        $record.adjudication.selection_eligible | Should Be $false
        $record.nested_provider_recovery.observed | Should Be $true
        $record.nested_provider_recovery.canary_id | Should Be 'e3i-runtime-3'
        $record.nested_provider_recovery.count | Should Be 1
        $record.nested_provider_recovery.affects_terminal_status | Should Be $false
        $record.provider_execution.session_a_launches | Should Be 1
        $record.provider_execution.session_a_retry_launched | Should Be $false
        $record.provider_execution.session_b_launched | Should Be $false
        $record.provider_execution.automatic_retry_performed | Should Be $false
        $record.boundary.ParentContentUnchanged | Should Be $true
        $record.boundary.ParentHeadUnchanged | Should Be $true
        $record.boundary.ParentStatusUnchanged | Should Be $true
        $record.boundary.FixtureHashesUnchanged | Should Be $true
        $record.boundary.LiveHomeUnchanged | Should Be $true
        $record.boundary.CleanupSucceeded | Should Be $true
        $record.raw_artifacts.Count | Should Be 9

        foreach ($artifact in @($record.raw_artifacts)) {
            $path = Join-Path (Split-Path -Parent $adjudicationPath) $artifact.file
            Test-Path -LiteralPath $path -PathType Leaf | Should Be $true
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash |
                Should Be $artifact.sha256
        }
    }

    It 'adds a second hash-linked adjudication with nested recovery as the invalidity' {
        $path = Join-Path $repositoryRoot `
            'docs\evidence\phase-00\E3-I\raw\session-a.attempt-005.adjudication-002.json'
        Test-Path -LiteralPath $path -PathType Leaf | Should Be $true
        $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $record.schema_version | Should Be 2
        $record.experiment | Should Be 'E3-I'
        $record.session | Should Be 'A'
        $record.attempt | Should Be 5
        $record.selected | Should Be $false
        $record.correction_of.path | Should Be `
            'docs/evidence/phase-00/E3-I/raw/session-a.attempt-005.adjudication.json'
        $predecessor = Join-Path $repositoryRoot $record.correction_of.path
        (Get-FileHash -LiteralPath $predecessor -Algorithm SHA256).Hash |
            Should Be $record.correction_of.sha256
        $record.correction_reason | Should Be `
            'E3I_PARENT_TERMINAL_PRECEDENCE_SUPERSESSION'
        $record.original_adjudication.status | Should Be 'BLOCKED_ENVIRONMENT'
        $record.corrected_adjudication.status | Should Be 'INVALID_RUN'
        ($record.corrected_adjudication.reasons -join ',') |
            Should Be 'E3I_NESTED_PROVIDER_RECOVERY'
        $record.corrected_adjudication.selection_eligible | Should Be $false
        $record.authoritative_outcome.event_line | Should Be 735
        $record.authoritative_outcome.stop_reason | Should Be 'stop'
        $record.parent_retry_recovery.observed | Should Be $true
        $record.parent_retry_recovery.count | Should Be 8
        ($record.parent_retry_recovery.start_event_lines -join ',') |
            Should Be '28,238,248,491,501,511,612,717'
        $record.nested_provider_recovery.observed | Should Be $true
        $record.nested_provider_recovery.canary_id | Should Be 'e3i-runtime-3'
        $record.nested_provider_recovery.event_line | Should Be 7
        $record.nested_provider_recovery.status | Should Be 'recovered'
        $record.nested_provider_recovery.affects_corrected_status | Should Be $true
        $record.provider_execution.new_provider_call | Should Be $false
        $record.provider_execution.session_b_launched | Should Be $false
        $record.raw_artifacts.Count | Should Be 9
        foreach ($artifact in @($record.raw_artifacts)) {
            $artifactPath = Join-Path (Split-Path -Parent $path) $artifact.file
            (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash |
                Should Be $artifact.sha256
        }
    }

    It 'selects Attempt 7 as terminal PASS without granting parallel authority' {
        $conclusionPath = Join-Path $repositoryRoot `
            'docs\evidence\phase-00\E3-I\conclusion.yml'
        $conclusion = Get-Content -LiteralPath $conclusionPath -Raw -Encoding UTF8
        $conclusion | Should Match '(?m)^schema_version: 3$'
        $conclusion | Should Match '(?m)^status: PASS$'
        $conclusion | Should Match '(?m)^selected_attempt: 7$'
        $conclusion | Should Match '(?m)^session_a_status: PASS$'
        $conclusion | Should Match '(?m)^session_b_status: PASS$'
        $conclusion | Should Match '(?m)^authority: CHARACTERIZATION_ONLY$'
        $conclusion | Should Match '(?m)^parallel_authorized: false$'
        $conclusion | Should Match '(?m)^parallel_mode_after: DISABLED$'
        $conclusion | Should Match '(?m)^e3_l_conclusion_consumed: false$'
        $conclusion | Should Match '(?m)^e3_m_replaced: false$'

        . (Join-Path $repositoryRoot 'scripts\lib\phase00-evidence.ps1')
        $manifest = Read-Phase00Manifest -Path (Join-Path $repositoryRoot `
            'docs\evidence\phase-00\manifest.yml')
        $entry = @($manifest.Entries | Where-Object { $_.id -eq 'E3-I' })[0]
        $entry.state | Should Be 'PASS'
        @($entry.artifacts).Count | Should Be 5
        $entry.decision | Should Be `
            'Attempt 7 independently passes I1-I4; characterization only, with parallel mode still disabled'
        $manifest.parallel_mode | Should Be 'DISABLED'

        $contract = @(Test-Phase00E3IArtifactContract `
            -RepositoryRoot $repositoryRoot)
        @($contract | Where-Object Status -eq 'FAIL').Count | Should Be 0
        @($contract | Where-Object Code -eq 'P00-E3I-TERMINAL').Count |
            Should Be 1
    }
}
