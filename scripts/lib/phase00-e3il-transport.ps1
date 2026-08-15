#Requires -Version 5.1

Set-StrictMode -Version 2.0

$runtimeHelper = Join-Path $PSScriptRoot 'phase00-runtime-evidence.ps1'
if (-not (Get-Command Get-Phase00PropertyValue -ErrorAction SilentlyContinue)) {
    . $runtimeHelper
}

function New-Phase00E3ILTransportResult {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('ELIGIBLE','INVALID_RUN','BLOCKED_ENVIRONMENT')]
        [string]$Status,
        [Parameter(Mandatory)][string[]]$Reasons,
        [System.Collections.IDictionary]$Data = ([ordered]@{})
    )

    $result = [ordered]@{
        Status = $Status
        Reasons = @($Reasons | Select-Object -Unique)
    }
    foreach ($key in @($Data.Keys)) { $result[$key] = $Data[$key] }
    [pscustomobject]$result
}

function Get-Phase00E3ILToolEventPairs {
    param([Parameter(Mandatory)][object[]]$Events)

    $starts = @{}
    $ends = @{}
    $startIndexes = @{}
    $endIndexes = @{}
    for ($index = 0; $index -lt $Events.Count; $index++) {
        $event = $Events[$index]
        $type = [string](Get-Phase00PropertyValue $event 'type')
        if ($type -notin @('tool_execution_start','tool_execution_end')) { continue }
        $id = [string](Get-Phase00PropertyValue $event 'toolCallId')
        $name = [string](Get-Phase00PropertyValue $event 'toolName')
        if ([string]::IsNullOrWhiteSpace($id) -or [string]::IsNullOrWhiteSpace($name)) {
            throw "Tool event at index $index lacks identity."
        }
        if ($type -eq 'tool_execution_start') {
            if ($starts.ContainsKey($id)) { throw "Duplicate tool start '$id'." }
            $starts[$id] = $event
            $startIndexes[$id] = $index
        } else {
            if ($ends.ContainsKey($id)) { throw "Duplicate tool end '$id'." }
            $ends[$id] = $event
            $endIndexes[$id] = $index
        }
    }

    $ids = @($starts.Keys + $ends.Keys | Sort-Object -Unique)
    if ($ids.Count -eq 0) { throw 'No parent tool events found.' }
    $pairs = foreach ($id in $ids) {
        if (-not $starts.ContainsKey($id) -or -not $ends.ContainsKey($id)) {
            throw "Unpaired tool event '$id'."
        }
        if ([int]$startIndexes[$id] -ge [int]$endIndexes[$id]) {
            throw "Tool end does not follow start for '$id'."
        }
        $startName = [string](Get-Phase00PropertyValue $starts[$id] 'toolName')
        $endName = [string](Get-Phase00PropertyValue $ends[$id] 'toolName')
        if ($startName -ne $endName) { throw "Tool name mismatch for '$id'." }
        [pscustomobject][ordered]@{
            ToolCallId = $id
            ToolName = $startName
            StartIndex = [int]$startIndexes[$id]
            EndIndex = [int]$endIndexes[$id]
            Start = $starts[$id]
            End = $ends[$id]
        }
    }
    @($pairs | Sort-Object StartIndex)
}

function Get-Phase00E3ILResultText {
    param([Parameter(Mandatory)]$ToolResult)

    $content = @(Get-Phase00PropertyValue $ToolResult 'content')
    if ($content.Count -ne 1 -or
        (Get-Phase00PropertyValue $content[0] 'type') -ne 'text') {
        throw 'Expected exactly one text content item.'
    }
    [string](Get-Phase00PropertyValue $content[0] 'text')
}

function Get-Phase00E3ILPropertyNames {
    param([Parameter(Mandatory)]$Object)

    if ($Object -is [System.Collections.IDictionary]) {
        return @($Object.Keys | ForEach-Object { [string]$_ } | Sort-Object)
    }
    @($Object.PSObject.Properties | ForEach-Object { [string]$_.Name } | Sort-Object)
}

function Get-Phase00E3ILSummaryBranch {
    param([AllowEmptyString()][Parameter(Mandatory)][string]$Text)

    $matches = [regex]::Matches(
        $Text.Replace("`r`n", "`n"),
        '(?s)<merge-summary>\s*(.*?)\s*</merge-summary>'
    )
    if ($matches.Count -ne 1) {
        return [pscustomobject]@{ Branch = 'CONTRADICTION'; Summary = $null }
    }
    $summary = $matches[0].Groups[1].Value.Trim()
    if ($summary.StartsWith('Isolation:', [StringComparison]::Ordinal)) {
        return [pscustomobject]@{
            Branch = 'APPLY_FALSE_CAPTURE_ONLY'
            Summary = $summary
        }
    }
    if ($summary -eq 'No changes to apply.') {
        return [pscustomobject]@{
            Branch = 'APPLY_TRUE_NO_DIFF'
            Summary = $summary
        }
    }
    [pscustomobject]@{ Branch = 'CONTRADICTION'; Summary = $summary }
}

function ConvertFrom-Phase00E3ILChildDiagnostic {
    param([Parameter(Mandatory)]$ToolResult)

    try {
        $text = (Get-Phase00E3ILResultText $ToolResult).Replace("`r`n", "`n")
        $wrapper = [regex]::Match(
            $text,
            '(?s)\A(?<payload>.+?)\n\n\nWall time: [0-9]+(?:\.[0-9]+)? seconds\s*\z'
        )
        if (-not $wrapper.Success) { throw 'Bash result wrapper mismatch.' }
        $parsed = $wrapper.Groups['payload'].Value.Trim() |
            ConvertFrom-Json -ErrorAction Stop
        if ((@(Get-Phase00E3ILPropertyNames $parsed) -join ',') -ne
            'description,key,type,value') {
            throw 'Child diagnostic shape mismatch.'
        }
        if ($parsed.key -ne 'task.isolation.apply' -or
            $parsed.type -ne 'boolean' -or $parsed.value -isnot [bool] -or
            $parsed.description -isnot [string] -or
            [string]::IsNullOrWhiteSpace($parsed.description)) {
            throw 'Child diagnostic contract mismatch.'
        }
        [pscustomobject][ordered]@{
            Status = 'OBSERVED'
            Value = [bool]$parsed.value
            Raw = $parsed
        }
    } catch {
        [pscustomobject][ordered]@{
            Status = 'INVALID_RUN'
            Value = $null
            Error = $_.Exception.Message
        }
    }
}

function Test-Phase00E3ILInteger60 {
    param($Value)

    foreach ($type in @(
        [sbyte],[byte],[int16],[uint16],[int32],[uint32],[int64],[uint64]
    )) {
        if ($Value -is $type) { return [decimal]$Value -eq [decimal]60 }
    }
    $false
}

function Test-Phase00E3ILDiagnosticPair {
    param([Parameter(Mandatory)]$Pair)

    if ($Pair.ToolName -ne 'bash') { throw 'Expected a bash pair.' }
    $arguments = Get-Phase00PropertyValue $Pair.Start 'args'
    if ((@(Get-Phase00E3ILPropertyNames $arguments) -join ',') -ne
        'command,timeout' -or
        (Get-Phase00PropertyValue $arguments 'command') -ne
            'omp config get task.isolation.apply --json' -or
        -not (Test-Phase00E3ILInteger60 `
            (Get-Phase00PropertyValue $arguments 'timeout'))) {
        throw 'Child diagnostic invocation mismatch.'
    }
    if ((Get-Phase00PropertyValue $Pair.End 'isError') -eq $true) {
        throw 'Child diagnostic tool result is an error.'
    }
    $diagnostic = ConvertFrom-Phase00E3ILChildDiagnostic `
        (Get-Phase00PropertyValue $Pair.End 'result')
    if ($diagnostic.Status -ne 'OBSERVED') {
        throw "Child diagnostic evidence is invalid: $($diagnostic.Error)"
    }
    $diagnostic
}

function Get-Phase00E3ILTaskSample {
    param(
        [Parameter(Mandatory)]$Pair,
        [Parameter(Mandatory)][string]$ExpectedId
    )

    if ($Pair.ToolName -ne 'task') { throw 'Expected a task pair.' }
    $arguments = Get-Phase00PropertyValue $Pair.Start 'args'
    $tasks = @(Get-Phase00PropertyValue $arguments 'tasks')
    $isolated = if ($tasks.Count -eq 1) {
        Get-Phase00PropertyValue $tasks[0] 'isolated'
    } else { $null }
    if ((@(Get-Phase00E3ILPropertyNames $arguments) -join ',') -ne
        'context,tasks' -or
        (Get-Phase00PropertyValue $arguments 'context') -ne
            'Phase 00 E3-I sequential behavioral canary' -or
        $tasks.Count -ne 1 -or
        (@(Get-Phase00E3ILPropertyNames $tasks[0]) -join ',') -ne
            'agent,isolated,name,task' -or
        (Get-Phase00PropertyValue $tasks[0] 'name') -ne $ExpectedId -or
        (Get-Phase00PropertyValue $tasks[0] 'agent') -ne 'phase00-e3i-canary' -or
        (Get-Phase00PropertyValue $tasks[0] 'task') -ne
            'Submit the exact acknowledgement required by your agent contract through its required terminal yield. Do not call any other tool.' -or
        $isolated -isnot [bool] -or -not $isolated) {
        throw "Task arguments mismatch for '$ExpectedId'."
    }
    if ((Get-Phase00PropertyValue $Pair.End 'isError') -eq $true) {
        throw "Task '$ExpectedId' returned a tool error."
    }
    $toolResult = Get-Phase00PropertyValue $Pair.End 'result'
    $results = @(Get-Phase00PropertyValue `
        (Get-Phase00PropertyValue $toolResult 'details') 'results')
    if ($results.Count -ne 1) {
        throw "Task '$ExpectedId' has non-unit result cardinality."
    }
    $row = $results[0]
    $duration = [long](Get-Phase00PropertyValue $row 'durationMs')
    $tokens = [long](Get-Phase00PropertyValue $row 'tokens')
    try {
        $output = [string](Get-Phase00PropertyValue $row 'output') |
            ConvertFrom-Json -ErrorAction Stop
        if ((@(Get-Phase00E3ILPropertyNames $output) -join ',') -ne
            'acknowledgement' -or
            (Get-Phase00PropertyValue $output 'acknowledgement') -ne
                'PHASE00_E3I_CANARY_OK') {
            throw 'Canary acknowledgement mismatch.'
        }
    } catch {
        throw "Task result output mismatch for '$ExpectedId': $($_.Exception.Message)"
    }
    if ((Get-Phase00PropertyValue $row 'id') -ne $ExpectedId -or
        [int](Get-Phase00PropertyValue $row 'exitCode') -ne 0 -or
        (Get-Phase00PropertyValue $row 'aborted') -eq $true -or
        $duration -le 0 -or $tokens -le 0 -or
        [int](Get-Phase00PropertyValue $row 'requests') -le 0 -or
        [string]::IsNullOrWhiteSpace(
            [string](Get-Phase00PropertyValue $row 'resolvedModel'))) {
        throw "Task result contract mismatch for '$ExpectedId'."
    }
    $branch = Get-Phase00E3ILSummaryBranch `
        (Get-Phase00E3ILResultText $toolResult)
    [pscustomobject][ordered]@{
        Id = $ExpectedId
        Branch = $branch.Branch
        Summary = $branch.Summary
        DurationMs = $duration
        Tokens = $tokens
        Requests = [int](Get-Phase00PropertyValue $row 'requests')
        ResolvedModel = [string](Get-Phase00PropertyValue $row 'resolvedModel')
        Acknowledgement = 'PHASE00_E3I_CANARY_OK'
    }
}

function Get-Phase00E3ILCanaryToolCalls {
    param([Parameter(Mandatory)][object[]]$Events)

    $calls = @()
    $seenIds = @{}
    foreach ($event in $Events) {
        if ((Get-Phase00PropertyValue $event 'type') -ne 'message') { continue }
        $message = Get-Phase00PropertyValue $event 'message'
        foreach ($content in @(Get-Phase00PropertyValue $message 'content')) {
            if ((Get-Phase00PropertyValue $content 'type') -ne 'toolCall') { continue }
            $id = [string](Get-Phase00PropertyValue $content 'id')
            if (-not [string]::IsNullOrWhiteSpace($id)) { $seenIds[$id] = $true }
            $calls += [pscustomobject][ordered]@{
                Id = $id
                Name = [string](Get-Phase00PropertyValue $content 'name')
                Arguments = Get-Phase00PropertyValue $content 'arguments'
                Source = 'message.content'
            }
        }
    }
    foreach ($event in $Events) {
        $type = [string](Get-Phase00PropertyValue $event 'type')
        $data = if ($type -eq 'tool_execution_start') {
            $event
        } elseif ($type -eq 'custom' -and
            (Get-Phase00PropertyValue $event 'customType') -eq
                'tool_execution_start') {
            Get-Phase00PropertyValue $event 'data'
        } else { $null }
        if ($null -eq $data) { continue }
        $id = [string](Get-Phase00PropertyValue $data 'toolCallId')
        if (-not [string]::IsNullOrWhiteSpace($id) -and $seenIds.ContainsKey($id)) {
            continue
        }
        if (-not [string]::IsNullOrWhiteSpace($id)) { $seenIds[$id] = $true }
        $calls += [pscustomobject][ordered]@{
            Id = $id
            Name = [string](Get-Phase00PropertyValue $data 'toolName')
            Arguments = Get-Phase00PropertyValue $data 'args'
            Source = 'tool_execution_start'
        }
    }
    @($calls)
}

function Test-Phase00E3ILTerminalYieldCall {
    param([Parameter(Mandatory)]$Call)

    if ((Get-Phase00PropertyValue $Call 'Name') -ne 'yield') { return $false }
    $arguments = Get-Phase00PropertyValue $Call 'Arguments'
    $argumentNames = @(Get-Phase00E3ILPropertyNames $arguments)
    $unknownArguments = @($argumentNames | Where-Object { $_ -notin @('result','type') })
    if ($argumentNames -notcontains 'result' -or $unknownArguments.Count -ne 0) {
        return $false
    }
    if ($argumentNames -contains 'type') {
        $yieldType = Get-Phase00PropertyValue $arguments 'type'
        if ($null -ne $yieldType -and $yieldType -ne 'result') { return $false }
    }
    $result = Get-Phase00PropertyValue $arguments 'result'
    if ($result -is [string]) {
        try { $result = $result | ConvertFrom-Json -ErrorAction Stop }
        catch { return $false }
    }
    if ((@(Get-Phase00E3ILPropertyNames $result) -join ',') -ne 'data') {
        return $false
    }
    $data = Get-Phase00PropertyValue $result 'data'
    if ((@(Get-Phase00E3ILPropertyNames $data) -join ',') -ne
        'acknowledgement') {
        return $false
    }
    (Get-Phase00PropertyValue $data 'acknowledgement') -eq
        'PHASE00_E3I_CANARY_OK'
}

function Get-Phase00E3ILCanarySession {
    param(
        [Parameter(Mandatory)][object[]]$Events,
        [Parameter(Mandatory)][string]$ExpectedId
    )

    $init = @($Events | Where-Object {
        (Get-Phase00PropertyValue $_ 'type') -eq 'session_init'
    })
    $readOnly = if ($init.Count -eq 1) {
        Get-Phase00PropertyValue $init[0] 'readOnly'
    } else { $null }
    if ($init.Count -ne 1 -or
        (Get-Phase00PropertyValue $init[0] 'agent') -ne 'phase00-e3i-canary' -or
        $readOnly -isnot [bool] -or -not $readOnly) {
        throw "Canary '$ExpectedId' lacks one valid session_init."
    }
    $tools = @(Get-Phase00PropertyValue $init[0] 'tools')
    if (($tools -join ',') -ne 'read,yield,hub') {
        throw "Canary '$ExpectedId' tool surface is '$($tools -join ',')'."
    }
    $calls = @(Get-Phase00E3ILCanaryToolCalls -Events $Events)
    $yieldCalls = @($calls | Where-Object { $_.Name -eq 'yield' })
    $forbidden = @($calls | Where-Object { $_.Name -ne 'yield' })
    if ($yieldCalls.Count -ne 1 -or
        -not (Test-Phase00E3ILTerminalYieldCall $yieldCalls[0])) {
        throw "Canary '$ExpectedId' lacks one exact terminal yield call."
    }
    [pscustomobject][ordered]@{
        Id = $ExpectedId
        Tools = $tools
        ReadOnly = $true
        ToolCallCount = $calls.Count
        ToolNames = @($calls | ForEach-Object { $_.Name })
        YieldCallCount = $yieldCalls.Count
        ForbiddenToolCallCount = $forbidden.Count
    }
}

function Get-Phase00E3ILRecoveredProviderFailures {
    param([Parameter(Mandatory)][object[]]$Events)

    @($Events | Where-Object {
        (Get-Phase00PropertyValue $_ 'type') -in
            @('message','message_start','message_end')
    } | ForEach-Object {
        $message = Get-Phase00PropertyValue $_ 'message'
        $recovery = Get-Phase00PropertyValue $message 'retryRecovery'
        if ((Get-Phase00PropertyValue $message 'role') -eq 'assistant' -and
            (Get-Phase00PropertyValue $message 'stopReason') -eq 'error' -and
            (Get-Phase00PropertyValue $recovery 'status') -ceq 'recovered') {
            [pscustomobject][ordered]@{
                Provider = [string](Get-Phase00PropertyValue $message 'provider')
                Model = [string](Get-Phase00PropertyValue $message 'model')
                ErrorMessage = [string](Get-Phase00PropertyValue $message 'errorMessage')
                RecoveryKind = [string](Get-Phase00PropertyValue $recovery 'kind')
                RecoveryStatus = [string](Get-Phase00PropertyValue $recovery 'status')
                RecoveryAttempt = [int](Get-Phase00PropertyValue $recovery 'attempt')
            }
        }
    })
}

function Get-Phase00E3ILEnvironmentFailureCode {
    param([Parameter(Mandatory)]$Failure)

    if (-not $Failure.Found) { return $null }
    if ($Failure.IsEnvironmentBlock) { return [string]$Failure.Code }
    if ([string]$Failure.ErrorMessage -match
        '(?i)(overload(?:ed)?|temporarily unavailable|service unavailable|capacity exceeded)') {
        return 'P00-RUNTIME-PROVIDER-OVERLOAD'
    }
    $null
}

function Test-Phase00E3ILEmptyArguments {
    param([Parameter(Mandatory)]$Pair)

    $arguments = Get-Phase00PropertyValue $Pair.Start 'args'
    if (@(Get-Phase00E3ILPropertyNames $arguments).Count -ne 0) {
        throw "Tool '$($Pair.ToolName)' must receive an empty object."
    }
    if ((Get-Phase00PropertyValue $Pair.End 'isError') -eq $true) {
        throw "Tool '$($Pair.ToolName)' returned an error."
    }
}

function Test-Phase00E3ILSessionTransport {
    param(
        [Parameter(Mandatory)][ValidateSet('A','B')][string]$Session,
        [Parameter(Mandatory)][object[]]$ParentEvents,
        [Parameter(Mandatory)][System.Collections.IDictionary]$CanaryEvents,
        [bool]$TimedOut = $false
    )

    if ($TimedOut) {
        return New-Phase00E3ILTransportResult INVALID_RUN @('E3IL_TIMEOUT')
    }
    $parentFailure = Get-Phase00TerminalModelFailure -Events $ParentEvents
    if ($parentFailure.Found) {
        $environmentCode = Get-Phase00E3ILEnvironmentFailureCode $parentFailure
        if ($null -ne $environmentCode) {
            return New-Phase00E3ILTransportResult BLOCKED_ENVIRONMENT `
                @($environmentCode) ([ordered]@{ TerminalFailure = $parentFailure })
        }
        return New-Phase00E3ILTransportResult INVALID_RUN `
            @('E3IL_PARENT_PROVIDER_FAILURE') `
            ([ordered]@{ TerminalFailure = $parentFailure })
    }

    try {
        $pairs = @(Get-Phase00E3ILToolEventPairs -Events $ParentEvents)
    } catch {
        return New-Phase00E3ILTransportResult INVALID_RUN `
            @('E3IL_EVENT_PAIRING_INVALID') `
            ([ordered]@{ Error = $_.Exception.Message })
    }
    $expectedNames = if ($Session -eq 'A') {
        @(
            'phase00_e3l_read_apply','bash','task','task','task',
            'phase00_e3i_override_apply_true','phase00_e3l_read_apply',
            'bash','task','task','task'
        )
    } else {
        @('phase00_e3l_read_apply','bash','task','task','task')
    }
    if ((@($pairs.ToolName) -join ',') -ne ($expectedNames -join ',')) {
        return New-Phase00E3ILTransportResult INVALID_RUN `
            @('E3IL_PARENT_SEQUENCE_MISMATCH') ([ordered]@{
                Expected = $expectedNames
                Actual = @($pairs.ToolName)
            })
    }

    try {
        $readerIndexes = if ($Session -eq 'A') { @(0,6) } else { @(0) }
        foreach ($index in $readerIndexes) {
            Test-Phase00E3ILEmptyArguments $pairs[$index]
        }
        if ($Session -eq 'A') { Test-Phase00E3ILEmptyArguments $pairs[5] }
        $diagnosticIndexes = if ($Session -eq 'A') { @(1,7) } else { @(1) }
        $diagnostics = @($diagnosticIndexes | ForEach-Object {
            Test-Phase00E3ILDiagnosticPair $pairs[$_]
        })
        $expectedIds = if ($Session -eq 'A') {
            @(
                'e3i-project-1','e3i-project-2','e3i-project-3',
                'e3i-runtime-1','e3i-runtime-2','e3i-runtime-3'
            )
        } else { @('e3i-cli-1','e3i-cli-2','e3i-cli-3') }
        $taskIndexes = if ($Session -eq 'A') { @(2,3,4,8,9,10) } else { @(2,3,4) }
        $samples = for ($index = 0; $index -lt $expectedIds.Count; $index++) {
            Get-Phase00E3ILTaskSample -Pair $pairs[$taskIndexes[$index]] `
                -ExpectedId $expectedIds[$index]
        }
    } catch {
        return New-Phase00E3ILTransportResult INVALID_RUN `
            @('E3IL_PARENT_SEQUENCE_MISMATCH') `
            ([ordered]@{ Error = $_.Exception.Message })
    }

    $actualIds = @($CanaryEvents.Keys | ForEach-Object { [string]$_ } |
        Sort-Object)
    if (($actualIds -join ',') -ne (@($expectedIds | Sort-Object) -join ',')) {
        return New-Phase00E3ILTransportResult INVALID_RUN `
            @('E3IL_CANARY_PROVENANCE_MISSING') ([ordered]@{
                ExpectedIds = @($expectedIds | Sort-Object)
                ActualIds = $actualIds
            })
    }
    $canarySessions = @()
    foreach ($id in $expectedIds) {
        $events = @($CanaryEvents[$id])
        $recovered = @(Get-Phase00E3ILRecoveredProviderFailures $events)
        if ($recovered.Count -gt 0) {
            return New-Phase00E3ILTransportResult INVALID_RUN `
                @('E3IL_NESTED_PROVIDER_RECOVERY') ([ordered]@{
                    CanaryId = $id
                    ProviderFailures = $recovered
                })
        }
        $terminal = Get-Phase00TerminalModelFailure -Events $events
        if ($terminal.Found) {
            $environmentCode = Get-Phase00E3ILEnvironmentFailureCode $terminal
            if ($null -ne $environmentCode) {
                return New-Phase00E3ILTransportResult BLOCKED_ENVIRONMENT `
                    @($environmentCode) ([ordered]@{
                        CanaryId = $id
                        TerminalFailure = $terminal
                    })
            }
            return New-Phase00E3ILTransportResult INVALID_RUN `
                @('E3IL_CANARY_PROVENANCE_MISSING') ([ordered]@{
                    CanaryId = $id
                    TerminalFailure = $terminal
                })
        }
        try {
            $sessionRecord = Get-Phase00E3ILCanarySession `
                -Events $events -ExpectedId $id
            if ($sessionRecord.ForbiddenToolCallCount -ne 0) {
                throw "Canary '$id' called a forbidden tool."
            }
            $canarySessions += $sessionRecord
        } catch {
            return New-Phase00E3ILTransportResult INVALID_RUN `
                @('E3IL_CANARY_PROVENANCE_MISSING') `
                ([ordered]@{ CanaryId = $id; Error = $_.Exception.Message })
        }
    }

    New-Phase00E3ILTransportResult ELIGIBLE @('E3IL_SESSION_TRANSPORT_EXACT') `
        ([ordered]@{
            Session = $Session
            Pairs = $pairs
            Diagnostics = $diagnostics
            TaskSamples = @($samples)
            CanarySessions = @($canarySessions)
        })
}

function Test-Phase00E3ILSelectionEnvelope {
    param(
        [Parameter(Mandatory)]$SessionTransport,
        [Parameter(Mandatory)]$Boundary,
        [Parameter(Mandatory)][bool]$LiveHomeMutationAttributable,
        [AllowEmptyString()][string]$CleanupError = ''
    )

    if ($SessionTransport.Status -ne 'ELIGIBLE') { return $SessionTransport }
    $required = @(
        'ParentContentUnchanged','ParentHeadUnchanged','ParentStatusUnchanged',
        'FixtureHashesUnchanged','LiveHomeUnchanged','CleanupSucceeded'
    )
    $failed = @($required | Where-Object {
        (Get-Phase00PropertyValue $Boundary $_) -ne $true
    })
    if ($failed.Count -gt 0 -or $LiveHomeMutationAttributable) {
        return New-Phase00E3ILTransportResult INVALID_RUN `
            @('E3IL_BOUNDARY_INELIGIBLE') ([ordered]@{
                FailedBoundaries = $failed
                LiveHomeMutationAttributable = $LiveHomeMutationAttributable
                CleanupError = $CleanupError
                Transport = $SessionTransport
            })
    }
    New-Phase00E3ILTransportResult ELIGIBLE `
        @('E3IL_SELECTION_ENVELOPE_EXACT') ([ordered]@{
            Session = $SessionTransport.Session
            Pairs = @($SessionTransport.Pairs)
            Diagnostics = @($SessionTransport.Diagnostics)
            TaskSamples = @($SessionTransport.TaskSamples)
            CanarySessions = @($SessionTransport.CanarySessions)
            Boundary = $Boundary
            LiveHomeMutationAttributable = $false
        })
}
