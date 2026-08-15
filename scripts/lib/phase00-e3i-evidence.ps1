#Requires -Version 5.1

Set-StrictMode -Version 2.0

$sharedTransportPath = Join-Path $PSScriptRoot 'phase00-e3il-transport.ps1'
if (Test-Path -LiteralPath $sharedTransportPath -PathType Leaf) {
    . $sharedTransportPath
}

function New-Phase00E3IAnalysis {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('PASS','FAIL','INVALID_RUN','BLOCKED_ENVIRONMENT')]
        [string]$Status,
        [Parameter(Mandatory)][string[]]$Reasons,
        [hashtable]$Data = @{}
    )

    $result = [ordered]@{
        Status = $Status
        Reasons = @($Reasons)
    }
    foreach ($key in $Data.Keys) {
        $result[$key] = $Data[$key]
    }
    return [pscustomobject]$result
}

function Get-Phase00E3ISummaryBranch {
    param([AllowEmptyString()][Parameter(Mandatory)][string]$Text)

    $matches = [regex]::Matches(
        $Text.Replace("`r`n", "`n"),
        '(?s)<merge-summary>\s*(.*?)\s*</merge-summary>'
    )
    if ($matches.Count -ne 1) {
        return [pscustomobject]@{
            Branch = 'CONTRADICTION'
            Summary = $null
        }
    }

    $summary = $matches[0].Groups[1].Value.Trim()
    if ($summary.StartsWith('Isolation:', [System.StringComparison]::Ordinal)) {
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
    return [pscustomobject]@{
        Branch = 'CONTRADICTION'
        Summary = $summary
    }
}

function Get-Phase00E3IToolEventPairs {
    param([Parameter(Mandatory)][object[]]$Events)

    $starts = @{}
    $ends = @{}
    $startIndex = @{}
    $endIndex = @{}

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
            $startIndex[$id] = $index
        } else {
            if ($ends.ContainsKey($id)) { throw "Duplicate tool end '$id'." }
            $ends[$id] = $event
            $endIndex[$id] = $index
        }
    }

    $ids = @($starts.Keys + $ends.Keys | Sort-Object -Unique)
    if ($ids.Count -eq 0) { throw 'No parent tool events found.' }

    $pairs = foreach ($id in $ids) {
        if (-not $starts.ContainsKey($id) -or -not $ends.ContainsKey($id)) {
            throw "Unpaired tool event '$id'."
        }
        if ([int]$startIndex[$id] -ge [int]$endIndex[$id]) {
            throw "Tool end does not follow start for '$id'."
        }

        $startName = [string](Get-Phase00PropertyValue $starts[$id] 'toolName')
        $endName = [string](Get-Phase00PropertyValue $ends[$id] 'toolName')
        if ($startName -ne $endName) { throw "Tool name mismatch for '$id'." }

        [pscustomobject][ordered]@{
            ToolCallId = $id
            ToolName = $startName
            StartIndex = [int]$startIndex[$id]
            EndIndex = [int]$endIndex[$id]
            Start = $starts[$id]
            End = $ends[$id]
        }
    }

    @($pairs | Sort-Object StartIndex)
}

function Get-Phase00E3IResultText {
    param([Parameter(Mandatory)]$ToolResult)

    $content = @(Get-Phase00PropertyValue $ToolResult 'content')
    if ($content.Count -ne 1 -or
        (Get-Phase00PropertyValue $content[0] 'type') -ne 'text') {
        throw 'Expected exactly one text content item.'
    }
    [string](Get-Phase00PropertyValue $content[0] 'text')
}

function Get-Phase00E3IPropertyNames {
    param([Parameter(Mandatory)]$Object)

    if ($Object -is [System.Collections.IDictionary]) {
        return @($Object.Keys | ForEach-Object { [string]$_ } | Sort-Object)
    }
    @($Object.PSObject.Properties | ForEach-Object { [string]$_.Name } | Sort-Object)
}

function Get-Phase00E3IChildDiagnosticCommand {
    'omp config get task.isolation.apply --json'
}

function ConvertFrom-Phase00E3IChildDiagnostic {
    param([Parameter(Mandatory)]$ToolResult)

    try {
        $text = (Get-Phase00E3IResultText $ToolResult).Replace("`r`n", "`n")
        $wrapper = [regex]::Match(
            $text,
            '(?s)\A(?<payload>.+?)\n\n\nWall time: [0-9]+(?:\.[0-9]+)? seconds\s*\z'
        )
        if (-not $wrapper.Success) { throw 'Bash result wrapper mismatch.' }

        $parsed = $wrapper.Groups['payload'].Value.Trim() | ConvertFrom-Json -ErrorAction Stop
        $properties = @($parsed.PSObject.Properties.Name | Sort-Object)
        if (($properties -join ',') -ne 'description,key,type,value') {
            throw 'Child diagnostic shape mismatch.'
        }
        if ($parsed.key -ne 'task.isolation.apply' -or
            $parsed.type -ne 'boolean' -or $parsed.value -isnot [bool]) {
            throw 'Child diagnostic contract mismatch.'
        }
        if ($parsed.description -isnot [string] -or
            [string]::IsNullOrWhiteSpace($parsed.description)) {
            throw 'Child diagnostic description is absent.'
        }

        [pscustomobject]@{
            Status = 'OBSERVED'
            Value = [bool]$parsed.value
            Raw = $parsed
        }
    } catch {
        [pscustomobject]@{
            Status = 'INVALID_RUN'
            Value = $null
            Error = $_.Exception.Message
        }
    }
}

function Get-Phase00E3ITaskSample {
    param(
        [Parameter(Mandatory)]$Pair,
        [Parameter(Mandatory)][string]$ExpectedId
    )

    if ($Pair.ToolName -ne 'task') { throw 'Expected a task pair.' }

    $arguments = Get-Phase00PropertyValue $Pair.Start 'args'
    $tasks = @(Get-Phase00PropertyValue $arguments 'tasks')
    $topLevelProperties = @(Get-Phase00E3IPropertyNames $arguments)
    $itemProperties = if ($tasks.Count -eq 1) {
        @(Get-Phase00E3IPropertyNames $tasks[0])
    } else {
        @()
    }
    $isolated = if ($tasks.Count -eq 1) {
        Get-Phase00PropertyValue $tasks[0] 'isolated'
    } else {
        $null
    }

    if (($topLevelProperties -join ',') -ne 'context,tasks' -or
        (Get-Phase00PropertyValue $arguments 'context') -ne
            'Phase 00 E3-I sequential behavioral canary' -or
        $tasks.Count -ne 1 -or
        ($itemProperties -join ',') -ne 'agent,isolated,name,task' -or
        (Get-Phase00PropertyValue $tasks[0] 'name') -ne $ExpectedId -or
        (Get-Phase00PropertyValue $tasks[0] 'agent') -ne 'phase00-e3i-canary' -or
        (Get-Phase00PropertyValue $tasks[0] 'task') -ne
            'Submit the exact acknowledgement required by your agent contract through its required terminal yield. Do not call any other tool.' -or
        $isolated -isnot [bool] -or -not $isolated) {
        throw "Task arguments mismatch for '$ExpectedId'."
    }

    $toolResult = Get-Phase00PropertyValue $Pair.End 'result'
    if ((Get-Phase00PropertyValue $Pair.End 'isError') -eq $true) {
        throw "Task '$ExpectedId' returned a tool error."
    }
    $details = Get-Phase00PropertyValue $toolResult 'details'
    $results = @(Get-Phase00PropertyValue $details 'results')
    if ($results.Count -ne 1) {
        throw "Task '$ExpectedId' has non-unit result cardinality."
    }

    $row = $results[0]
    $duration = [long](Get-Phase00PropertyValue $row 'durationMs')
    $tokens = [long](Get-Phase00PropertyValue $row 'tokens')
    $output = [string](Get-Phase00PropertyValue $row 'output')
    $acknowledgement = $null
    try {
        $parsedOutput = $output | ConvertFrom-Json -ErrorAction Stop
        if ((@(Get-Phase00E3IPropertyNames $parsedOutput) -join ',') -ne
            'acknowledgement') {
            throw 'Canary output shape mismatch.'
        }
        $acknowledgement = Get-Phase00PropertyValue $parsedOutput 'acknowledgement'
    } catch {
        throw "Task result output mismatch for '$ExpectedId': $($_.Exception.Message)"
    }
    if ((Get-Phase00PropertyValue $row 'id') -ne $ExpectedId -or
        [int](Get-Phase00PropertyValue $row 'exitCode') -ne 0 -or
        (Get-Phase00PropertyValue $row 'aborted') -eq $true -or
        $acknowledgement -ne 'PHASE00_E3I_CANARY_OK' -or
        $duration -le 0 -or $tokens -le 0) {
        throw "Task result contract mismatch for '$ExpectedId'."
    }

    $branch = Get-Phase00E3ISummaryBranch (Get-Phase00E3IResultText $toolResult)
    [pscustomobject][ordered]@{
        Id = $ExpectedId
        Branch = $branch.Branch
        Summary = $branch.Summary
        DurationMs = $duration
        Tokens = $tokens
        Requests = [int](Get-Phase00PropertyValue $row 'requests')
        ResolvedModel = [string](Get-Phase00PropertyValue $row 'resolvedModel')
        Acknowledgement = [string]$acknowledgement
    }
}

function Get-Phase00E3ICanaryToolCalls {
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
            (Get-Phase00PropertyValue $event 'customType') -eq 'tool_execution_start') {
            Get-Phase00PropertyValue $event 'data'
        } else {
            $null
        }
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

function Test-Phase00E3ITerminalYieldCall {
    param([Parameter(Mandatory)]$Call)

    if ((Get-Phase00PropertyValue $Call 'Name') -ne 'yield') { return $false }
    $arguments = Get-Phase00PropertyValue $Call 'Arguments'
    $argumentNames = @(Get-Phase00E3IPropertyNames $arguments)
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
    if ((@(Get-Phase00E3IPropertyNames $result) -join ',') -ne 'data') { return $false }
    $data = Get-Phase00PropertyValue $result 'data'
    if ((@(Get-Phase00E3IPropertyNames $data) -join ',') -ne 'acknowledgement') {
        return $false
    }
    (Get-Phase00PropertyValue $data 'acknowledgement') -eq 'PHASE00_E3I_CANARY_OK'
}

function Get-Phase00E3ICanarySession {
    param(
        [Parameter(Mandatory)][object[]]$Events,
        [Parameter(Mandatory)][string]$ExpectedId
    )

    $init = @($Events | Where-Object {
        (Get-Phase00PropertyValue $_ 'type') -eq 'session_init'
    })
    $readOnly = if ($init.Count -eq 1) {
        Get-Phase00PropertyValue $init[0] 'readOnly'
    } else {
        $null
    }
    if ($init.Count -ne 1 -or
        (Get-Phase00PropertyValue $init[0] 'agent') -ne 'phase00-e3i-canary' -or
        $readOnly -isnot [bool] -or -not $readOnly) {
        throw "Canary '$ExpectedId' lacks one valid session_init."
    }

    $tools = @(Get-Phase00PropertyValue $init[0] 'tools')
    if (($tools -join ',') -ne 'read,yield,hub') {
        throw "Canary '$ExpectedId' tool surface is '$($tools -join ',')'."
    }

    $calls = @(Get-Phase00E3ICanaryToolCalls -Events $Events)
    $yieldCalls = @($calls | Where-Object { $_.Name -eq 'yield' })
    $forbiddenCalls = @($calls | Where-Object { $_.Name -ne 'yield' })
    if ($yieldCalls.Count -ne 1 -or
        -not (Test-Phase00E3ITerminalYieldCall -Call $yieldCalls[0])) {
        throw "Canary '$ExpectedId' lacks one exact terminal yield call."
    }
    [pscustomobject][ordered]@{
        Id = $ExpectedId
        Tools = $tools
        ReadOnly = $true
        ToolCallCount = $calls.Count
        ToolNames = @($calls | ForEach-Object { $_.Name })
        YieldCallCount = $yieldCalls.Count
        ForbiddenToolCallCount = $forbiddenCalls.Count
        OverrideToolPresent = $tools -contains 'phase00_e3i_override_apply_true'
    }
}

function Test-Phase00E3IParentSequence {
    param(
        [Parameter(Mandatory)][ValidateSet('A','B')][string]$Session,
        [Parameter(Mandatory)][object[]]$Pairs
    )

    $expected = if ($Session -eq 'A') {
        @(
            'phase00_e3l_read_apply','bash','task','task','task',
            'phase00_e3i_override_apply_true','phase00_e3l_read_apply',
            'bash','task','task','task'
        )
    } else {
        @('phase00_e3l_read_apply','bash','task','task','task')
    }
    $actual = @($Pairs.ToolName)
    if (($actual -join ',') -ne ($expected -join ',')) {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_PARENT_SEQUENCE_MISMATCH') @{
            Expected = $expected
            Actual = $actual
        }
    }
    New-Phase00E3IAnalysis PASS @('E3I_PARENT_SEQUENCE_EXACT') @{
        Expected = $expected
        Actual = $actual
    }
}

function Test-Phase00E3IReaderInvocation {
    param([Parameter(Mandatory)]$Pair)

    try {
        if ($Pair.ToolName -ne 'phase00_e3l_read_apply') {
            throw 'Expected an E3-L reader pair.'
        }
        $arguments = Get-Phase00PropertyValue $Pair.Start 'args'
        if (@(Get-Phase00E3IPropertyNames $arguments).Count -ne 0) {
            throw 'E3-L reader invocation has parameters.'
        }
        if ((Get-Phase00PropertyValue $Pair.End 'isError') -eq $true) {
            throw 'E3-L reader returned an error.'
        }
        New-Phase00E3IAnalysis PASS @('E3I_READER_TRANSPORT_EXACT')
    } catch {
        New-Phase00E3IAnalysis INVALID_RUN @('E3I_PARENT_SEQUENCE_MISMATCH') @{
            Error = $_.Exception.Message
        }
    }
}

function Test-Phase00E3IInteger60 {
    param($Value)

    $integerTypes = @(
        [sbyte],[byte],[int16],[uint16],[int32],[uint32],[int64],[uint64]
    )
    foreach ($type in $integerTypes) {
        if ($Value -is $type) { return [decimal]$Value -eq [decimal]60 }
    }
    $false
}

function Test-Phase00E3IChildDiagnosticInvocation {
    param([Parameter(Mandatory)]$Pair)

    try {
        if ($Pair.ToolName -ne 'bash') { throw 'Expected a bash pair.' }
        $arguments = Get-Phase00PropertyValue $Pair.Start 'args'
        $properties = @(Get-Phase00E3IPropertyNames $arguments)
        $command = Get-Phase00PropertyValue $arguments 'command'
        $timeout = Get-Phase00PropertyValue $arguments 'timeout'
        if (($properties -join ',') -ne 'command,timeout' -or
            $command -ne (Get-Phase00E3IChildDiagnosticCommand) -or
            -not (Test-Phase00E3IInteger60 $timeout)) {
            throw 'Child diagnostic invocation mismatch.'
        }
        if ((Get-Phase00PropertyValue $Pair.End 'isError') -eq $true) {
            throw 'Child diagnostic tool result is an error.'
        }

        $diagnostic = ConvertFrom-Phase00E3IChildDiagnostic `
            -ToolResult (Get-Phase00PropertyValue $Pair.End 'result')
        if ($diagnostic.Status -ne 'OBSERVED') {
            throw "Child diagnostic evidence is invalid: $($diagnostic.Error)"
        }
        New-Phase00E3IAnalysis PASS @('E3I_CHILD_DIAGNOSTIC_OBSERVED') @{
            Diagnostic = $diagnostic
        }
    } catch {
        New-Phase00E3IAnalysis INVALID_RUN @('E3I_EVENT_PAIRING_INVALID') @{
            Error = $_.Exception.Message
        }
    }
}

function ConvertFrom-Phase00E3IOverrideResult {
    param([Parameter(Mandatory)]$ToolResult)

    try {
        $details = Get-Phase00PropertyValue $ToolResult 'details'
        if ($null -eq $details) { throw 'Override details are absent.' }
        $properties = @(Get-Phase00E3IPropertyNames $details)
        if ($properties.Count -eq 0) { throw 'Override details are empty.' }

        $text = Get-Phase00E3IResultText $ToolResult
        $rendered = $text | ConvertFrom-Json -ErrorAction Stop
        $renderedProperties = @(Get-Phase00E3IPropertyNames $rendered)
        $expectedProperties = @(
            'after','before','calledFlushOrSave','calledSet','operation',
            'probe','requested','scope','setting'
        )
        $expectedShape = $expectedProperties -join ','
        if (($properties -join ',') -ne $expectedShape -or
            ($renderedProperties -join ',') -ne $expectedShape) {
            return New-Phase00E3IAnalysis FAIL @('E3I_OVERRIDE_CONTRADICTION') @{
                Details = $details
                ObservedProperties = $properties
                RenderedProperties = $renderedProperties
            }
        }

        foreach ($name in $expectedProperties) {
            if ((Get-Phase00PropertyValue $details $name) -ne
                (Get-Phase00PropertyValue $rendered $name)) {
                return New-Phase00E3IAnalysis FAIL @('E3I_OVERRIDE_CONTRADICTION') @{
                    Details = $details
                    Error = "Text/details divergence at '$name'."
                }
            }
        }

        $before = Get-Phase00PropertyValue $details 'before'
        $requested = Get-Phase00PropertyValue $details 'requested'
        $after = Get-Phase00PropertyValue $details 'after'
        $calledSet = Get-Phase00PropertyValue $details 'calledSet'
        $calledFlushOrSave = Get-Phase00PropertyValue $details 'calledFlushOrSave'
        $exact =
            (Get-Phase00PropertyValue $details 'probe') -eq
                'phase00-e3i-runtime-override-v1' -and
            (Get-Phase00PropertyValue $details 'setting') -eq
                'task.isolation.apply' -and
            $before -is [bool] -and -not $before -and
            (Get-Phase00PropertyValue $details 'operation') -eq
                'pi.pi.settings.override' -and
            $requested -is [bool] -and $requested -and
            $after -is [bool] -and $after -and
            $calledSet -is [bool] -and -not $calledSet -and
            $calledFlushOrSave -is [bool] -and -not $calledFlushOrSave -and
            (Get-Phase00PropertyValue $details 'scope') -eq 'parent-only'
        if (-not $exact) {
            return New-Phase00E3IAnalysis FAIL @('E3I_OVERRIDE_CONTRADICTION') @{
                Details = $details
            }
        }

        New-Phase00E3IAnalysis PASS @('E3I_OVERRIDE_ATTESTED') @{
            Details = $details
        }
    } catch {
        New-Phase00E3IAnalysis INVALID_RUN @('E3I_OVERRIDE_EVIDENCE_INVALID') @{
            Error = $_.Exception.Message
        }
    }
}

function Get-Phase00E3IEnvironmentFailureCode {
    param([Parameter(Mandatory)]$Failure)

    if (-not $Failure.Found) { return $null }
    if ($Failure.IsEnvironmentBlock) { return [string]$Failure.Code }
    if ([string]$Failure.ErrorMessage -match
        '(?i)(overload(?:ed)?|temporarily unavailable|service unavailable|capacity exceeded)') {
        return 'P00-RUNTIME-PROVIDER-OVERLOAD'
    }
    $null
}

function Get-Phase00E3IRecoveredProviderFailures {
    param([Parameter(Mandatory)][object[]]$Events)

    @($Events | Where-Object {
        (Get-Phase00PropertyValue $_ 'type') -in @(
            'message','message_start','message_end'
        )
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

function Test-Phase00E3ICanaryEvidenceSet {
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$CanaryEvents,
        [Parameter(Mandatory)][string[]]$ExpectedIds
    )

    foreach ($key in @($CanaryEvents.Keys)) {
        $failure = Get-Phase00TerminalModelFailure -Events @($CanaryEvents[$key])
        if ($failure.Found) {
            $environmentCode = Get-Phase00E3IEnvironmentFailureCode -Failure $failure
            if ($null -ne $environmentCode) {
                return New-Phase00E3IAnalysis BLOCKED_ENVIRONMENT @($environmentCode) @{
                    CanaryId = [string]$key
                    TerminalFailure = $failure
                }
            }
            return New-Phase00E3IAnalysis INVALID_RUN @('E3I_CANARY_PROVENANCE_MISSING') @{
                CanaryId = [string]$key
                TerminalFailure = $failure
            }
        }
        $recovered = @(Get-Phase00E3IRecoveredProviderFailures `
            -Events @($CanaryEvents[$key]))
        if ($recovered.Count -gt 0) {
            return New-Phase00E3IAnalysis INVALID_RUN `
                @('E3I_NESTED_PROVIDER_RECOVERY') @{
                    CanaryId = [string]$key
                    ProviderFailures = $recovered
                }
        }
    }

    $actualIds = @($CanaryEvents.Keys | ForEach-Object { [string]$_ } | Sort-Object)
    $sortedExpected = @($ExpectedIds | Sort-Object)
    if (($actualIds -join ',') -ne ($sortedExpected -join ',')) {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_CANARY_PROVENANCE_MISSING') @{
            ExpectedIds = $sortedExpected
            ActualIds = $actualIds
        }
    }

    $sessions = @()
    foreach ($id in $ExpectedIds) {
        $events = @($CanaryEvents[$id])
        $init = @($events | Where-Object {
            (Get-Phase00PropertyValue $_ 'type') -eq 'session_init'
        })
        if ($init.Count -eq 1) {
            $tools = @(Get-Phase00PropertyValue $init[0] 'tools')
            if (($tools -join ',') -ne 'read,yield,hub') {
                return New-Phase00E3IAnalysis FAIL `
                    @('E3I_CANARY_TOOL_SURFACE_CONTAMINATED') @{
                        CanaryId = $id
                        Tools = $tools
                    }
            }
        }
        try {
            $session = Get-Phase00E3ICanarySession -Events $events -ExpectedId $id
            if ($session.ForbiddenToolCallCount -gt 0) {
                return New-Phase00E3IAnalysis FAIL @('E3I_CANARY_TOOL_CALLED') @{
                    CanaryId = $id
                    ToolNames = @($session.ToolNames)
                }
            }
            $sessions += $session
        } catch {
            return New-Phase00E3IAnalysis INVALID_RUN `
                @('E3I_CANARY_PROVENANCE_MISSING') @{
                    CanaryId = $id
                    Error = $_.Exception.Message
                }
        }
    }

    New-Phase00E3IAnalysis PASS @('E3I_CANARY_PROVENANCE_EXACT') @{
        Sessions = @($sessions)
    }
}

function Get-Phase00E3IParentPairs {
    param([Parameter(Mandatory)][object[]]$ParentEvents)

    try {
        [pscustomobject][ordered]@{
            Status = 'PASS'
            Pairs = @(Get-Phase00E3ILToolEventPairs -Events $ParentEvents)
            Error = $null
        }
    } catch {
        [pscustomobject][ordered]@{
            Status = 'INVALID_RUN'
            Pairs = @()
            Error = $_.Exception.Message
        }
    }
}

function Test-Phase00E3IParentTerminal {
    param([Parameter(Mandatory)][object[]]$ParentEvents)

    $failure = Get-Phase00TerminalModelFailure -Events $ParentEvents
    if (-not $failure.Found) {
        return New-Phase00E3IAnalysis PASS @('E3I_PARENT_NO_TERMINAL_FAILURE')
    }
    $environmentCode = Get-Phase00E3IEnvironmentFailureCode -Failure $failure
    if ($null -ne $environmentCode) {
        return New-Phase00E3IAnalysis BLOCKED_ENVIRONMENT @($environmentCode) @{
            TerminalFailure = $failure
        }
    }
    New-Phase00E3IAnalysis INVALID_RUN @('E3I_EVENT_PAIRING_INVALID') @{
        TerminalFailure = $failure
    }
}

function Test-Phase00E3ISessionA {
    param(
        [Parameter(Mandatory)][object[]]$ParentEvents,
        [Parameter(Mandatory)][System.Collections.IDictionary]$CanaryEvents,
        [bool]$TimedOut = $false
    )

    $terminal = Test-Phase00E3IParentTerminal -ParentEvents $ParentEvents
    if ($terminal.Status -ne 'PASS') { return $terminal }
    if ($TimedOut) {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_TIMEOUT')
    }

    $pairResult = Get-Phase00E3IParentPairs -ParentEvents $ParentEvents
    if ($pairResult.Status -ne 'PASS') {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_EVENT_PAIRING_INVALID') @{
            Error = $pairResult.Error
        }
    }
    $pairs = @($pairResult.Pairs)
    $sequence = Test-Phase00E3IParentSequence -Session A -Pairs $pairs
    if ($sequence.Status -ne 'PASS') { return $sequence }

    foreach ($index in @(0,6)) {
        $readerInvocation = Test-Phase00E3IReaderInvocation -Pair $pairs[$index]
        if ($readerInvocation.Status -ne 'PASS') { return $readerInvocation }
    }
    foreach ($index in @(1,7)) {
        $invocation = Test-Phase00E3IChildDiagnosticInvocation -Pair $pairs[$index]
        if ($invocation.Status -ne 'PASS') { return $invocation }
    }
    $overrideArguments = Get-Phase00PropertyValue $pairs[5].Start 'args'
    if (@(Get-Phase00E3IPropertyNames $overrideArguments).Count -ne 0) {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_PARENT_SEQUENCE_MISMATCH') @{
            Error = 'Runtime override invocation has parameters.'
        }
    }

    $expectedIds = @(
        'e3i-project-1','e3i-project-2','e3i-project-3',
        'e3i-runtime-1','e3i-runtime-2','e3i-runtime-3'
    )
    $canaries = Test-Phase00E3ICanaryEvidenceSet `
        -CanaryEvents $CanaryEvents -ExpectedIds $expectedIds
    if ($canaries.Status -ne 'PASS') { return $canaries }

    $overrideToolError = (Get-Phase00PropertyValue $pairs[5].End 'isError') -eq $true
    if ($overrideToolError) {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_OVERRIDE_EXECUTION_ERROR') @{
            Error = Get-Phase00E3IResultText (Get-Phase00PropertyValue $pairs[5].End 'result')
        }
    }
    $override = ConvertFrom-Phase00E3IOverrideResult `
        -ToolResult (Get-Phase00PropertyValue $pairs[5].End 'result')
    if ($override.Status -ne 'PASS') { return $override }

    try {
        $diagnostics = @(
            (Test-Phase00E3IChildDiagnosticInvocation -Pair $pairs[1]).Diagnostic,
            (Test-Phase00E3IChildDiagnosticInvocation -Pair $pairs[7]).Diagnostic
        )
        $projectSamples = for ($index = 0; $index -lt 3; $index++) {
            Get-Phase00E3ITaskSample -Pair $pairs[$index + 2] `
                -ExpectedId $expectedIds[$index]
        }
        $runtimeSamples = for ($index = 0; $index -lt 3; $index++) {
            Get-Phase00E3ITaskSample -Pair $pairs[$index + 8] `
                -ExpectedId $expectedIds[$index + 3]
        }
    } catch {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_EVENT_PAIRING_INVALID') @{
            Error = $_.Exception.Message
        }
    }

    New-Phase00E3IAnalysis PASS @('E3I_SESSION_A_EXACT') @{
        Session = 'A'
        Diagnostics = @($diagnostics)
        ProjectSamples = @($projectSamples)
        RuntimeSamples = @($runtimeSamples)
        Override = $override
        CanarySessions = @($canaries.Sessions)
    }
}

function Test-Phase00E3ISessionB {
    param(
        [Parameter(Mandatory)][object[]]$ParentEvents,
        [Parameter(Mandatory)][System.Collections.IDictionary]$CanaryEvents,
        [bool]$TimedOut = $false
    )

    $terminal = Test-Phase00E3IParentTerminal -ParentEvents $ParentEvents
    if ($terminal.Status -ne 'PASS') { return $terminal }
    if ($TimedOut) {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_TIMEOUT')
    }

    $pairResult = Get-Phase00E3IParentPairs -ParentEvents $ParentEvents
    if ($pairResult.Status -ne 'PASS') {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_EVENT_PAIRING_INVALID') @{
            Error = $pairResult.Error
        }
    }
    $pairs = @($pairResult.Pairs)
    $sequence = Test-Phase00E3IParentSequence -Session B -Pairs $pairs
    if ($sequence.Status -ne 'PASS') { return $sequence }

    $readerInvocation = Test-Phase00E3IReaderInvocation -Pair $pairs[0]
    if ($readerInvocation.Status -ne 'PASS') { return $readerInvocation }

    $invocation = Test-Phase00E3IChildDiagnosticInvocation -Pair $pairs[1]
    if ($invocation.Status -ne 'PASS') { return $invocation }

    $expectedIds = @('e3i-cli-1','e3i-cli-2','e3i-cli-3')
    $canaries = Test-Phase00E3ICanaryEvidenceSet `
        -CanaryEvents $CanaryEvents -ExpectedIds $expectedIds
    if ($canaries.Status -ne 'PASS') { return $canaries }

    try {
        $samples = for ($index = 0; $index -lt 3; $index++) {
            Get-Phase00E3ITaskSample -Pair $pairs[$index + 2] `
                -ExpectedId $expectedIds[$index]
        }
    } catch {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_EVENT_PAIRING_INVALID') @{
            Error = $_.Exception.Message
        }
    }

    New-Phase00E3IAnalysis PASS @('E3I_SESSION_B_EXACT') @{
        Session = 'B'
        Diagnostics = @($invocation.Diagnostic)
        CliSamples = @($samples)
        CanarySessions = @($canaries.Sessions)
    }
}

function Copy-Phase00E3IUpstreamOutcome {
    param([Parameter(Mandatory)]$Analysis)

    New-Phase00E3IAnalysis ([string]$Analysis.Status) @($Analysis.Reasons) @{
        Upstream = $Analysis
    }
}

function Test-Phase00I1Evidence {
    param([Parameter(Mandatory)]$SessionA)

    if ($SessionA.Status -ne 'PASS') {
        return Copy-Phase00E3IUpstreamOutcome $SessionA
    }
    $failures = @()
    if (@($SessionA.Diagnostics).Count -lt 1 -or
        $SessionA.Diagnostics[0].Value -isnot [bool] -or
        $SessionA.Diagnostics[0].Value) {
        $failures += 'E3I_CHILD_VALUE_CONTRADICTION'
    }
    if (@($SessionA.ProjectSamples).Count -ne 3 -or
        @($SessionA.ProjectSamples | Where-Object {
            $_.Branch -ne 'APPLY_FALSE_CAPTURE_ONLY'
        }).Count -gt 0) {
        $failures += 'E3I_SUMMARY_BRANCH_CONTRADICTION'
    }
    $projectIds = @('e3i-project-1','e3i-project-2','e3i-project-3')
    $projectCanaries = @($SessionA.CanarySessions | Where-Object { $_.Id -in $projectIds })
    if ($projectCanaries.Count -ne 3 -or
        @($projectCanaries | Where-Object {
            $_.YieldCallCount -ne 1 -or $_.ForbiddenToolCallCount -ne 0
        }).Count -gt 0) {
        $failures += 'E3I_CANARY_TOOL_CALLED'
    }
    if ($failures.Count -gt 0) {
        return New-Phase00E3IAnalysis FAIL @($failures | Select-Object -Unique)
    }
    New-Phase00E3IAnalysis PASS @('E3I_PROJECT_CONTROL_CONFIRMED') @{
        Samples = @($SessionA.ProjectSamples)
    }
}

function Test-Phase00I2Evidence {
    param(
        [Parameter(Mandatory)]$SessionA,
        [Parameter(Mandatory)]$Boundary
    )

    if ($SessionA.Status -ne 'PASS') {
        return Copy-Phase00E3IUpstreamOutcome $SessionA
    }
    $failures = @()
    $details = $SessionA.Override.Details
    if ($SessionA.Override.Status -ne 'PASS') {
        $failures += 'E3I_OVERRIDE_CONTRADICTION'
    }
    if ((Get-Phase00PropertyValue $details 'calledSet') -eq $true -or
        (Get-Phase00PropertyValue $details 'calledFlushOrSave') -eq $true -or
        (Get-Phase00PropertyValue $Boundary 'FixtureHashesUnchanged') -ne $true) {
        $failures += 'E3I_OVERRIDE_PERSISTED'
    }
    if (@($SessionA.Diagnostics).Count -ne 2 -or
        $SessionA.Diagnostics[1].Value -isnot [bool] -or
        $SessionA.Diagnostics[1].Value) {
        $failures += 'E3I_CHILD_VALUE_CONTRADICTION'
    }
    if (@($SessionA.RuntimeSamples).Count -ne 3 -or
        @($SessionA.RuntimeSamples | Where-Object {
            $_.Branch -ne 'APPLY_TRUE_NO_DIFF'
        }).Count -gt 0) {
        $failures += 'E3I_SUMMARY_BRANCH_CONTRADICTION'
    }
    $runtimeIds = @('e3i-runtime-1','e3i-runtime-2','e3i-runtime-3')
    $runtimeCanaries = @($SessionA.CanarySessions | Where-Object { $_.Id -in $runtimeIds })
    if ($runtimeCanaries.Count -ne 3 -or
        @($runtimeCanaries | Where-Object {
            $_.YieldCallCount -ne 1 -or $_.ForbiddenToolCallCount -ne 0
        }).Count -gt 0) {
        $failures += 'E3I_CANARY_TOOL_CALLED'
    }
    if ($failures.Count -gt 0) {
        return New-Phase00E3IAnalysis FAIL @($failures | Select-Object -Unique)
    }
    New-Phase00E3IAnalysis PASS @('E3I_RUNTIME_OVERRIDE_DIVERGENCE_CONFIRMED') @{
        Samples = @($SessionA.RuntimeSamples)
        Override = $SessionA.Override
    }
}

function Test-Phase00I3Evidence {
    param([Parameter(Mandatory)]$SessionB)

    if ($SessionB.Status -ne 'PASS') {
        return Copy-Phase00E3IUpstreamOutcome $SessionB
    }
    $failures = @()
    if (@($SessionB.Diagnostics).Count -ne 1 -or
        $SessionB.Diagnostics[0].Value -isnot [bool] -or
        $SessionB.Diagnostics[0].Value) {
        $failures += 'E3I_CHILD_VALUE_CONTRADICTION'
    }
    if (@($SessionB.CliSamples).Count -ne 3 -or
        @($SessionB.CliSamples | Where-Object {
            $_.Branch -ne 'APPLY_TRUE_NO_DIFF'
        }).Count -gt 0) {
        $failures += 'E3I_SUMMARY_BRANCH_CONTRADICTION'
    }
    if (@($SessionB.CanarySessions).Count -ne 3 -or
        @($SessionB.CanarySessions | Where-Object {
            $_.YieldCallCount -ne 1 -or $_.ForbiddenToolCallCount -ne 0
        }).Count -gt 0) {
        $failures += 'E3I_CANARY_TOOL_CALLED'
    }
    if ($failures.Count -gt 0) {
        return New-Phase00E3IAnalysis FAIL @($failures | Select-Object -Unique)
    }
    New-Phase00E3IAnalysis PASS @('E3I_CLI_OVERLAY_DIVERGENCE_CONFIRMED') @{
        Samples = @($SessionB.CliSamples)
    }
}

function Test-Phase00E3IBoundaryShape {
    param([Parameter(Mandatory)]$Boundary)

    $expected = @(
        'CleanupSucceeded','FixtureHashesUnchanged','LiveHomeUnchanged',
        'ParentContentUnchanged','ParentHeadUnchanged','ParentStatusUnchanged'
    )
    $properties = @(Get-Phase00E3IPropertyNames $Boundary)
    if (($properties -join ',') -ne ($expected -join ',')) { return $false }
    foreach ($name in $expected) {
        if ((Get-Phase00PropertyValue $Boundary $name) -isnot [bool]) { return $false }
    }
    $true
}

function Test-Phase00I4Evidence {
    param(
        [Parameter(Mandatory)]$SessionA,
        [Parameter(Mandatory)]$SessionB,
        [Parameter(Mandatory)]$Boundary
    )

    foreach ($session in @($SessionA,$SessionB)) {
        if ($session.Status -ne 'PASS') {
            return Copy-Phase00E3IUpstreamOutcome $session
        }
    }
    if (-not (Test-Phase00E3IBoundaryShape $Boundary) -or
        -not (Get-Phase00PropertyValue $Boundary 'CleanupSucceeded')) {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_CLEANUP_UNCERTAIN')
    }

    $samples = @(
        @($SessionA.ProjectSamples) + @($SessionA.RuntimeSamples) +
        @($SessionB.CliSamples)
    )
    if ($samples.Count -ne 9 -or @($samples | Where-Object {
        [long]$_.DurationMs -le 0 -or [long]$_.Tokens -le 0
    }).Count -gt 0) {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_COST_OBSERVATION_MISSING')
    }

    $failures = @()
    $canaries = @(@($SessionA.CanarySessions) + @($SessionB.CanarySessions))
    if ($canaries.Count -ne 9 -or @($canaries | Where-Object {
        ($_.Tools -join ',') -ne 'read,yield,hub' -or $_.OverrideToolPresent
    }).Count -gt 0) {
        $failures += 'E3I_CANARY_TOOL_SURFACE_CONTAMINATED'
    }
    if (@($canaries | Where-Object {
        $_.YieldCallCount -ne 1 -or $_.ForbiddenToolCallCount -ne 0
    }).Count -gt 0) {
        $failures += 'E3I_CANARY_TOOL_CALLED'
    }
    if (-not (Get-Phase00PropertyValue $Boundary 'ParentContentUnchanged') -or
        -not (Get-Phase00PropertyValue $Boundary 'ParentHeadUnchanged') -or
        -not (Get-Phase00PropertyValue $Boundary 'ParentStatusUnchanged')) {
        $failures += 'E3I_PARENT_MUTATION'
    }
    if (-not (Get-Phase00PropertyValue $Boundary 'FixtureHashesUnchanged')) {
        $failures += 'E3I_OVERRIDE_PERSISTED'
    }
    if (-not (Get-Phase00PropertyValue $Boundary 'LiveHomeUnchanged')) {
        $failures += 'E3I_LIVE_HOME_MUTATION'
    }
    if ($failures.Count -gt 0) {
        return New-Phase00E3IAnalysis FAIL @($failures | Select-Object -Unique)
    }
    New-Phase00E3IAnalysis PASS @('E3I_CANARY_SAFETY_RELIABILITY_CONFIRMED') @{
        Samples = $samples
        CanarySessions = $canaries
        Boundary = $Boundary
    }
}
