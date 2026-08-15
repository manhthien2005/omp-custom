#Requires -Version 5.1

Set-StrictMode -Version 2.0

function Read-Phase00JsonLines {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "JSONL artifact not found: $Path"
    }

    $events = [System.Collections.Generic.List[object]]::new()
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $lineNumber += 1
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $event = $line | ConvertFrom-Json -ErrorAction Stop
        } catch {
            throw "Malformed JSONL at line $lineNumber in '$Path': $($_.Exception.Message)"
        }
        if ($null -eq $event -or $event -isnot [psobject]) {
            throw "JSONL line $lineNumber in '$Path' is not an object."
        }
        [void]$events.Add($event)
    }
    if ($events.Count -eq 0) { throw "JSONL artifact contains no events: $Path" }
    return @($events)
}

function Get-Phase00PropertyValue {
    param($Object, [Parameter(Mandatory)][string]$Name)

    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-Phase00HasProperty {
    param($Object, [Parameter(Mandatory)][string]$Name)

    if ($null -eq $Object) { return $false }
    if ($Object -is [System.Collections.IDictionary]) { return $Object.Contains($Name) }
    return $null -ne $Object.PSObject.Properties[$Name]
}

function Get-Phase00TaskEventPairs {
    param([Parameter(Mandatory)][object[]]$Events)

    $starts = @{}
    $ends = @{}
    $startPositions = @{}
    $endPositions = @{}
    for ($index = 0; $index -lt $Events.Count; $index++) {
        $event = $Events[$index]
        if ((Get-Phase00PropertyValue $event 'toolName') -ne 'task') { continue }
        $id = [string](Get-Phase00PropertyValue $event 'toolCallId')
        if ([string]::IsNullOrWhiteSpace($id)) { throw "Task event at index $index has no toolCallId." }
        $type = [string](Get-Phase00PropertyValue $event 'type')
        if ($type -eq 'tool_execution_start') {
            if ($starts.ContainsKey($id)) { throw "Duplicate task start event for '$id'." }
            $starts[$id] = $event
            $startPositions[$id] = $index
        } elseif ($type -eq 'tool_execution_end') {
            if ($ends.ContainsKey($id)) { throw "Duplicate task end event for '$id'." }
            $ends[$id] = $event
            $endPositions[$id] = $index
        }
    }

    $ids = @($starts.Keys + $ends.Keys | Sort-Object -Unique)
    if ($ids.Count -eq 0) { throw 'No task tool events were found.' }
    $pairs = foreach ($id in $ids) {
        if (-not $starts.ContainsKey($id) -or -not $ends.ContainsKey($id)) {
            throw "Unpaired task event for '$id'."
        }
        if ([int]$startPositions[$id] -ge [int]$endPositions[$id]) {
            throw "Task end for '$id' does not follow its start."
        }
        [pscustomobject][ordered]@{
            ToolCallId = $id
            StartIndex = [int]$startPositions[$id]
            EndIndex = [int]$endPositions[$id]
            Start = $starts[$id]
            End = $ends[$id]
        }
    }
    return @($pairs | Sort-Object StartIndex)
}

function Get-Phase00ProbeTimings {
    param([Parameter(Mandatory)]$TaskResult)

    $details = Get-Phase00PropertyValue $TaskResult 'details'
    $results = @(Get-Phase00PropertyValue $details 'results')
    if ($results.Count -eq 0) { throw 'Task result contains no inline results.' }

    $timings = [System.Collections.Generic.List[object]]::new()
    foreach ($result in $results) {
        $output = [string](Get-Phase00PropertyValue $result 'output')
        if ([string]::IsNullOrWhiteSpace($output)) {
            throw "Task result index $(Get-Phase00PropertyValue $result 'index') has no probe output."
        }
        try {
            $payload = $output.Trim() | ConvertFrom-Json -ErrorAction Stop
        } catch {
            throw "Task result index $(Get-Phase00PropertyValue $result 'index') is not exact probe JSON."
        }
        if ((Get-Phase00PropertyValue $payload 'probe') -ne 'phase00-timing-v1') {
            throw "Task result index $(Get-Phase00PropertyValue $result 'index') lacks the timing discriminator."
        }
        foreach ($required in @('index','started_at_ms','ended_at_ms')) {
            if (-not (Test-Phase00HasProperty $payload $required)) {
                throw "Probe payload lacks '$required'."
            }
        }
        $logicalIndex = [int](Get-Phase00PropertyValue $payload 'index')
        $startedAt = [long](Get-Phase00PropertyValue $payload 'started_at_ms')
        $endedAt = [long](Get-Phase00PropertyValue $payload 'ended_at_ms')
        if ($startedAt -le 0 -or $endedAt -le $startedAt) {
            throw "Probe $logicalIndex has an invalid timing interval."
        }
        [void]$timings.Add([pscustomobject][ordered]@{
            Index = $logicalIndex
            ResultIndex = [int](Get-Phase00PropertyValue $result 'index')
            Id = [string](Get-Phase00PropertyValue $result 'id')
            StartedAtMs = $startedAt
            EndedAtMs = $endedAt
            DurationMs = $endedAt - $startedAt
        })
    }
    $unique = @($timings.Index | Sort-Object -Unique)
    if ($unique.Count -ne $timings.Count) { throw 'Probe timing indexes are not unique.' }
    return @($timings)
}

function Test-Phase00IntervalsOverlap {
    param([Parameter(Mandatory)]$First, [Parameter(Mandatory)]$Second)

    $latestStart = [Math]::Max([long]$First.StartedAtMs, [long]$Second.StartedAtMs)
    $earliestEnd = [Math]::Min([long]$First.EndedAtMs, [long]$Second.EndedAtMs)
    return $latestStart -lt $earliestEnd
}

function Get-Phase00CompletionOrder {
    param([Parameter(Mandatory)][object[]]$Timings)

    return @($Timings | Sort-Object EndedAtMs, Index | ForEach-Object { [int]$_.Index })
}

function Get-Phase00AuthoritativeAssistantOutcome {
    param([Parameter(Mandatory)][object[]]$Events)

    $terminalEndIndex = -1
    for ($index = 0; $index -lt $Events.Count; $index++) {
        if ((Get-Phase00PropertyValue $Events[$index] 'type') -eq 'agent_end' -and
            (Get-Phase00PropertyValue $Events[$index] 'isTerminal') -eq $true) {
            $terminalEndIndex = $index
        }
    }

    if ($terminalEndIndex -ge 0) {
        $assistantMessages = @(
            @(Get-Phase00PropertyValue $Events[$terminalEndIndex] 'messages') |
                Where-Object {
                    (Get-Phase00PropertyValue $_ 'role') -eq 'assistant'
                }
        )
        if ($assistantMessages.Count -gt 0) {
            return [pscustomobject][ordered]@{
                Found = $true
                Message = $assistantMessages[-1]
                EventIndex = $terminalEndIndex
                Source = 'terminal-agent-end'
            }
        }
        return [pscustomobject][ordered]@{
            Found = $false
            Message = $null
            EventIndex = $terminalEndIndex
            Source = 'terminal-agent-end'
        }
    }

    $messageEndIndex = -1
    $messageEnd = $null
    for ($index = 0; $index -lt $Events.Count; $index++) {
        if ((Get-Phase00PropertyValue $Events[$index] 'type') -eq 'message_end') {
            $candidate = Get-Phase00PropertyValue $Events[$index] 'message'
            if ((Get-Phase00PropertyValue $candidate 'role') -eq 'assistant') {
                $messageEndIndex = $index
                $messageEnd = $candidate
            }
        }
    }
    [pscustomobject][ordered]@{
        Found = $null -ne $messageEnd
        Message = $messageEnd
        EventIndex = $messageEndIndex
        Source = if ($null -ne $messageEnd) { 'message-end-fallback' } else { $null }
    }
}

function Get-Phase00ParentRecoveredProviderRetries {
    param([Parameter(Mandatory)][object[]]$Events)

    $facts = @()
    for ($startIndex = 0; $startIndex -lt $Events.Count; $startIndex++) {
        $start = $Events[$startIndex]
        if ((Get-Phase00PropertyValue $start 'type') -ne 'auto_retry_start') {
            continue
        }

        $recoveryMessage = $null
        $recoveryIndex = -1
        $recoverySource = $null
        for ($index = $startIndex + 1; $index -lt $Events.Count; $index++) {
            $event = $Events[$index]
            $type = Get-Phase00PropertyValue $event 'type'
            if ($type -eq 'message_end') {
                $message = Get-Phase00PropertyValue $event 'message'
                if ((Get-Phase00PropertyValue $message 'role') -eq 'assistant' -and
                    (Get-Phase00PropertyValue $message 'stopReason') -in
                        @('stop','toolUse')) {
                    $recoveryMessage = $message
                    $recoveryIndex = $index
                    $recoverySource = 'message-end'
                    break
                }
            }
            if ($type -eq 'agent_end' -and
                (Get-Phase00PropertyValue $event 'isTerminal') -eq $true) {
                $assistantMessages = @(
                    @(Get-Phase00PropertyValue $event 'messages') | Where-Object {
                        (Get-Phase00PropertyValue $_ 'role') -eq 'assistant'
                    }
                )
                if ($assistantMessages.Count -gt 0 -and
                    (Get-Phase00PropertyValue $assistantMessages[-1] 'stopReason') -in
                        @('stop','toolUse')) {
                    $recoveryMessage = $assistantMessages[-1]
                    $recoveryIndex = $index
                    $recoverySource = 'terminal-agent-end'
                }
                break
            }
        }
        if ($null -ne $recoveryMessage) {
            $facts += [pscustomobject][ordered]@{
                Attempt = [int](Get-Phase00PropertyValue $start 'attempt')
                MaxAttempts = [int](Get-Phase00PropertyValue $start 'maxAttempts')
                ErrorId = Get-Phase00PropertyValue $start 'errorId'
                ErrorMessage = [string](Get-Phase00PropertyValue $start 'errorMessage')
                StartEventIndex = $startIndex
                RecoveryEventIndex = $recoveryIndex
                RecoveryStopReason = [string](Get-Phase00PropertyValue `
                    $recoveryMessage 'stopReason')
                RecoverySource = $recoverySource
            }
        }
    }
    @($facts)
}

function Get-Phase00TerminalModelFailure {
    param([Parameter(Mandatory)][object[]]$Events)

    $outcome = Get-Phase00AuthoritativeAssistantOutcome -Events $Events
    $terminalMessage = if ($outcome.Found) { $outcome.Message } else { $null }
    if ($null -eq $terminalMessage -or
        (Get-Phase00PropertyValue $terminalMessage 'stopReason') -notin
            @('error','aborted')) {
        return [pscustomobject][ordered]@{
            Found = $false
            IsEnvironmentBlock = $false
            Code = $null
            Provider = $null
            Model = $null
            ErrorMessage = $null
        }
    }

    $message = [string](Get-Phase00PropertyValue $terminalMessage 'errorMessage')
    $code = 'P00-RUNTIME-MODEL-ERROR'
    $environmentBlock = $false
    if ($message -match '(?i)(unable to connect|connection (refused|failed|timed out)|network|access the url)') {
        $code = 'P00-RUNTIME-PROVIDER-CONNECTION'
        $environmentBlock = $true
    } elseif ($message -match '(?i)(quota|rate.?limit|too many requests)') {
        $code = 'P00-RUNTIME-PROVIDER-QUOTA'
        $environmentBlock = $true
    } elseif ($message -match '(?i)(authentication|unauthorized|forbidden|credential|api.?key)') {
        $code = 'P00-RUNTIME-PROVIDER-AUTH'
        $environmentBlock = $true
    } elseif ($message -match '(?i)(model.+not.+found|unknown model|provider.+not.+found)') {
        $code = 'P00-RUNTIME-MODEL-UNAVAILABLE'
        $environmentBlock = $true
    }
    [pscustomobject][ordered]@{
        Found = $true
        IsEnvironmentBlock = $environmentBlock
        Code = $code
        Provider = [string](Get-Phase00PropertyValue $terminalMessage 'provider')
        Model = [string](Get-Phase00PropertyValue $terminalMessage 'model')
        ErrorMessage = $message
    }
}

function Get-Phase00ResultOrder {
    param([Parameter(Mandatory)]$TaskResult)

    $details = Get-Phase00PropertyValue $TaskResult 'details'
    return @(@(Get-Phase00PropertyValue $details 'results') | ForEach-Object { [int](Get-Phase00PropertyValue $_ 'index') })
}

function Get-Phase00OverlapPairs {
    param([Parameter(Mandatory)][object[]]$Timings)

    $pairs = [System.Collections.Generic.List[string]]::new()
    for ($left = 0; $left -lt $Timings.Count; $left++) {
        for ($right = $left + 1; $right -lt $Timings.Count; $right++) {
            if (Test-Phase00IntervalsOverlap -First $Timings[$left] -Second $Timings[$right]) {
                [void]$pairs.Add("$($Timings[$left].Index)-$($Timings[$right].Index)")
            }
        }
    }
    return @($pairs)
}

function New-Phase00RuntimeAnalysis {
    param(
        [Parameter(Mandatory)][ValidateSet('PASS','FAIL','INVALID_RUN','BLOCKED_ENVIRONMENT')][string]$Status,
        [Parameter(Mandatory)][string[]]$Reasons,
        [hashtable]$Data = @{}
    )

    $result = [ordered]@{ Status = $Status; Reasons = @($Reasons) }
    foreach ($key in $Data.Keys) { $result[$key] = $Data[$key] }
    return [pscustomobject]$result
}

function Test-Phase00J1Evidence {
    param([Parameter(Mandatory)][object[]]$Events)

    try {
        $pairs = @(Get-Phase00TaskEventPairs -Events $Events)
        if ($pairs.Count -ne 1) { throw "Expected one task call; observed $($pairs.Count)." }
        $pair = $pairs[0]
        $args = Get-Phase00PropertyValue $pair.Start 'args'
        $tasks = @(Get-Phase00PropertyValue $args 'tasks')
        if ($tasks.Count -ne 3 -or [string]::IsNullOrWhiteSpace([string](Get-Phase00PropertyValue $args 'context'))) {
            throw 'J1 did not use one three-item batch with shared context.'
        }
        foreach ($item in $tasks) {
            if ((Get-Phase00PropertyValue $item 'agent') -ne 'phase00-blocking-probe' -or
                (Get-Phase00PropertyValue $item 'isolated') -ne $true) {
                throw 'J1 task items are not all isolated phase00-blocking-probe spawns.'
            }
        }
        $taskResult = Get-Phase00PropertyValue $pair.End 'result'
        $results = @((Get-Phase00PropertyValue (Get-Phase00PropertyValue $taskResult 'details') 'results'))
        if ($results.Count -ne 3) { throw "J1 has $($results.Count) inline results; expected three." }
        if (@($results | Where-Object { [int](Get-Phase00PropertyValue $_ 'exitCode') -ne 0 }).Count -gt 0) {
            throw 'J1 contains a failed spawn.'
        }
        $resultOrder = @(Get-Phase00ResultOrder -TaskResult $taskResult)
        if (($resultOrder -join ',') -ne '0,1,2') {
            return New-Phase00RuntimeAnalysis FAIL @('J1_RESULT_ORDER_MISMATCH') @{ ResultOrder = $resultOrder }
        }
        $timings = @(Get-Phase00ProbeTimings -TaskResult $taskResult)
        if ((@($timings.Index | Sort-Object) -join ',') -ne '0,1,2') { throw 'J1 timing indexes are incomplete.' }
        $completion = @(Get-Phase00CompletionOrder -Timings $timings)
        $overlapPairs = @(Get-Phase00OverlapPairs -Timings $timings)
        $failures = @()
        if (($completion -join ',') -ne '2,0,1') { $failures += 'J1_COMPLETION_ORDER_MISMATCH' }
        if ($overlapPairs.Count -eq 0) { $failures += 'J1_NO_CONCURRENCY_OVERLAP' }
        $status = if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
        return New-Phase00RuntimeAnalysis $status $(if ($failures.Count -eq 0) { @('J1_ALL_PREDICATES') } else { $failures }) @{
            ResultOrder = $resultOrder
            CompletionOrder = $completion
            OverlapPairs = $overlapPairs
            Timings = $timings
            TaskCallReturnsAfterAll = $true
        }
    } catch {
        return New-Phase00RuntimeAnalysis INVALID_RUN @("J1_INVALID: $($_.Exception.Message)")
    }
}

function Test-Phase00J2Evidence {
    param([Parameter(Mandatory)][object[]]$Events)

    try {
        $pairs = @(Get-Phase00TaskEventPairs -Events $Events)
        if ($pairs.Count -ne 1) { throw "Expected one task call; observed $($pairs.Count)." }
        $args = Get-Phase00PropertyValue $pairs[0].Start 'args'
        $tasks = @(Get-Phase00PropertyValue $args 'tasks')
        if ($tasks.Count -ne 3) { throw 'J2 did not use a three-item batch.' }
        if ((Get-Phase00PropertyValue $tasks[2] 'agent') -ne 'phase00-background-probe') {
            throw 'J2 item 2 did not use the no-blocking control agent.'
        }
        $taskResult = Get-Phase00PropertyValue $pairs[0].End 'result'
        $details = Get-Phase00PropertyValue $taskResult 'details'
        $results = @(Get-Phase00PropertyValue $details 'results')
        if ($results.Count -ne 2) { throw "J2 control expected two inline results; observed $($results.Count)." }
        $indexes = @($results | ForEach-Object { [int](Get-Phase00PropertyValue $_ 'index') })
        if (($indexes -join ',') -ne '0,1') { throw "J2 inline result indexes are '$($indexes -join ',')'." }
        $contentText = @((Get-Phase00PropertyValue $taskResult 'content') | ForEach-Object { [string](Get-Phase00PropertyValue $_ 'text') }) -join "`n"
        $progress = @(Get-Phase00PropertyValue $details 'progress')
        $detached = @($progress | Where-Object { [int](Get-Phase00PropertyValue $_ 'index') -eq 2 -and (Get-Phase00PropertyValue $_ 'status') -in @('pending','running') })
        $async = Get-Phase00PropertyValue $details 'async'
        $observable = $contentText -match 'Spawned' -and $detached.Count -eq 1 -and $null -ne $async
        if (-not $observable) {
            return New-Phase00RuntimeAnalysis FAIL @('J2_BACKGROUND_BOUNDARY_NOT_OBSERVABLE') @{ InlineResultIndexes = $indexes }
        }
        return New-Phase00RuntimeAnalysis PASS @('J2_DISCRIMINATING_CONTROL') @{
            InlineResultIndexes = $indexes
            DetachedIndex = 2
            AsyncState = [string](Get-Phase00PropertyValue $async 'state')
        }
    } catch {
        return New-Phase00RuntimeAnalysis INVALID_RUN @("J2_INVALID: $($_.Exception.Message)")
    }
}

function Get-Phase00TaskInvocationName {
    param([Parameter(Mandatory)]$Pair)

    $arguments = Get-Phase00PropertyValue $Pair.Start 'args'
    if (Test-Phase00HasProperty $arguments 'tasks') {
        $items = @(Get-Phase00PropertyValue $arguments 'tasks')
        if ($items.Count -ne 1) { return $null }
        return [string](Get-Phase00PropertyValue $items[0] 'name')
    }
    return [string](Get-Phase00PropertyValue $arguments 'name')
}

function Test-Phase00J3Evidence {
    param([Parameter(Mandatory)][object[]]$Events)

    try {
        $pairs = @(Get-Phase00TaskEventPairs -Events $Events)
        if ($pairs.Count -ne 2) { throw "Expected two task calls; observed $($pairs.Count)." }
        $verifier = @($pairs | Where-Object { (Get-Phase00TaskInvocationName $_) -eq 'verifier' })
        $reviewer = @($pairs | Where-Object { (Get-Phase00TaskInvocationName $_) -eq 'reviewer' })
        if ($verifier.Count -ne 1 -or $reviewer.Count -ne 1) { throw 'Verifier or Reviewer task call is missing.' }
        $finalPositions = @()
        for ($index = 0; $index -lt $Events.Count; $index++) {
            $event = $Events[$index]
            if ((Get-Phase00PropertyValue $event 'type') -eq 'message_start' -and
                (Get-Phase00PropertyValue (Get-Phase00PropertyValue $event 'message') 'role') -eq 'assistant') {
                $finalPositions += $index
            }
        }
        if ($finalPositions.Count -eq 0) { throw 'Parent final-message boundary is absent.' }
        $barriersHold = $verifier[0].EndIndex -lt $reviewer[0].StartIndex -and $reviewer[0].EndIndex -lt $finalPositions[-1]
        foreach ($pair in @($verifier[0], $reviewer[0])) {
            $timing = @(Get-Phase00ProbeTimings -TaskResult (Get-Phase00PropertyValue $pair.End 'result'))
            if ($timing.Count -ne 1 -or $timing[0].DurationMs -le 0) { throw 'Stage probe has no non-zero delay.' }
        }
        if (-not $barriersHold) {
            return New-Phase00RuntimeAnalysis FAIL @('J3_STAGE_BARRIER_ORDER_MISMATCH') @{
                VerifierEndIndex = $verifier[0].EndIndex
                ReviewerStartIndex = $reviewer[0].StartIndex
                ReviewerEndIndex = $reviewer[0].EndIndex
                FinalMessageIndex = $finalPositions[-1]
            }
        }
        return New-Phase00RuntimeAnalysis PASS @('J3_BOTH_STAGE_BARRIERS') @{
            VerifierEndIndex = $verifier[0].EndIndex
            ReviewerStartIndex = $reviewer[0].StartIndex
            ReviewerEndIndex = $reviewer[0].EndIndex
            FinalMessageIndex = $finalPositions[-1]
        }
    } catch {
        return New-Phase00RuntimeAnalysis INVALID_RUN @("J3_INVALID: $($_.Exception.Message)")
    }
}

function Get-Phase00TextContent {
    param($Result)

    return (@((Get-Phase00PropertyValue $Result 'content') | ForEach-Object {
        if ((Get-Phase00PropertyValue $_ 'type') -eq 'text') { [string](Get-Phase00PropertyValue $_ 'text') }
    }) -join "`n")
}

function Test-Phase00K1Evidence {
    param([Parameter(Mandatory)][object[]]$Events)

    try {
        $pairs = @(Get-Phase00TaskEventPairs -Events $Events)
        if ($pairs.Count -ne 2) { throw "Expected two sequential flat task calls; observed $($pairs.Count)." }
        $firstTaskStart = ($pairs | Sort-Object StartIndex | Select-Object -First 1).StartIndex
        $attestation = $null
        $attestationIndex = -1
        for ($index = 0; $index -lt $Events.Count; $index++) {
            $event = $Events[$index]
            if ((Get-Phase00PropertyValue $event 'type') -ne 'tool_execution_end' -or
                (Get-Phase00PropertyValue $event 'toolName') -ne 'bash') { continue }
            $text = Get-Phase00TextContent -Result (Get-Phase00PropertyValue $event 'result')
            foreach ($line in @($text -split "\r?\n")) {
                $line = $line.Trim()
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                try { $candidate = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
                if ((Get-Phase00PropertyValue $candidate 'probe') -eq 'phase00-task-wire-v1') {
                    $attestation = $candidate
                    $attestationIndex = $index
                    break
                }
            }
            if ($null -ne $attestation) { break }
        }
        if ($null -eq $attestation) { throw 'K1 model-visible wire attestation is absent.' }
        $wireIsFlat = (Get-Phase00PropertyValue $attestation 'has_task') -eq $true -and
            (Get-Phase00PropertyValue $attestation 'has_tasks') -eq $false -and
            (Get-Phase00PropertyValue $attestation 'has_context') -eq $false -and
            (Get-Phase00PropertyValue $attestation 'decision') -eq 'SEQUENTIAL_FALLBACK'
        $callsAreFlat = $true
        foreach ($pair in $pairs) {
            $args = Get-Phase00PropertyValue $pair.Start 'args'
            if (-not (Test-Phase00HasProperty $args 'task') -or
                (Test-Phase00HasProperty $args 'tasks') -or
                (Test-Phase00HasProperty $args 'context')) {
                $callsAreFlat = $false
            }
        }
        $ordered = @($pairs | Sort-Object StartIndex)
        $sequential = $ordered[0].EndIndex -lt $ordered[1].StartIndex
        $preflight = $attestationIndex -lt $firstTaskStart
        $failures = @()
        if (-not $wireIsFlat) { $failures += 'K1_ATTESTATION_NOT_FLAT' }
        if (-not $callsAreFlat) { $failures += 'K1_TASK_ARGUMENTS_NOT_FLAT' }
        if (-not $sequential) { $failures += 'K1_CALLS_NOT_SEQUENTIAL' }
        if (-not $preflight) { $failures += 'K1_PREFLIGHT_AFTER_DISPATCH' }
        $status = if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
        return New-Phase00RuntimeAnalysis $status $(if ($failures.Count -eq 0) { @('K1_FLAT_WIRE_SEQUENTIAL_FALLBACK') } else { $failures }) @{
            TaskCallCount = $pairs.Count
            PreflightBeforeDispatch = $preflight
            SequentialFallback = $sequential
            TopLevelKeys = @(Get-Phase00PropertyValue $attestation 'top_level_keys')
        }
    } catch {
        return New-Phase00RuntimeAnalysis INVALID_RUN @("K1_INVALID: $($_.Exception.Message)")
    }
}

function Protect-Phase00EvidenceText {
    param(
        [AllowEmptyString()][Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$DisposableRoot
    )

    $credentialNames = '(OPENAI_API_KEY|ANTHROPIC_API_KEY|ANTHROPIC_OAUTH_TOKEN|GEMINI_API_KEY|OMNIROUTE_API_KEY)'
    $credentialValuePattern = "(?i)($credentialNames|api[-_ ]?key)\s*[:=]\s*[`"']?[^\s`"',;}]{8,}|Authorization\s*:\s*Bearer\s+\S+"
    if ($Text -match $credentialValuePattern) {
        throw 'Credential-shaped content detected; refusing to persist runtime output.'
    }
    $safe = [regex]::Replace($Text, "(?i)$credentialNames", '<CREDENTIAL_VARIABLE>')
    foreach ($replacement in @(
        @($DisposableRoot, '<DISPOSABLE_ROOT>'),
        @($RepositoryRoot, '<REPO_ROOT>')
    )) {
        $path = [string]$replacement[0]
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        $variants = [System.Collections.Generic.List[string]]::new()
        [void]$variants.Add(($path -replace '\\','/'))
        $escapedPath = $path
        for ($escapeDepth = 0; $escapeDepth -le 6; $escapeDepth++) {
            if (-not $variants.Contains($escapedPath)) { [void]$variants.Add($escapedPath) }
            $escapedPath = $escapedPath.Replace('\', '\\')
        }
        foreach ($variant in @($variants | Sort-Object Length -Descending)) {
            $safe = [regex]::Replace($safe, [regex]::Escape($variant), [string]$replacement[1], [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        }
    }
    return $safe
}

function New-Phase00FixtureCheck {
    param([string]$Code, [bool]$Passed, [string]$Message)
    [pscustomobject][ordered]@{ Code = $Code; Passed = $Passed; Message = $Message }
}

function Test-Phase00RuntimeFixtureContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $root = [System.IO.Path]::GetFullPath($RepositoryRoot)
    $jRoot = Join-Path $root 'docs\evidence\phase-00\E3-J\fixture'
    $kRoot = Join-Path $root 'docs\evidence\phase-00\E3-K\fixture'
    $required = @(
        'docs\evidence\phase-00\E3-J\fixture\.omp\agents\phase00-blocking-probe.md',
        'docs\evidence\phase-00\E3-J\fixture\.omp\agents\phase00-background-probe.md',
        'docs\evidence\phase-00\E3-J\fixture\config.yml',
        'docs\evidence\phase-00\E3-J\fixture\prompts\J1-blocking-batch.md',
        'docs\evidence\phase-00\E3-J\fixture\prompts\J2-missing-blocking-control.md',
        'docs\evidence\phase-00\E3-J\fixture\prompts\J3-stage-barriers.md',
        'docs\evidence\phase-00\E3-K\fixture\.omp\agents\phase00-blocking-probe.md',
        'docs\evidence\phase-00\E3-K\fixture\config.yml',
        'docs\evidence\phase-00\E3-K\fixture\prompts\K1-flat-wire-fallback.md'
    )
    $missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf) })
    New-Phase00FixtureCheck P00-RUNTIME-FIXTURE-FILES ($missing.Count -eq 0) $(if ($missing.Count -eq 0) { 'All runtime fixture files exist.' } else { "Missing: $($missing -join ', ')" })
    if ($missing.Count -gt 0) { return }

    $jConfig = Get-Content -Raw -LiteralPath (Join-Path $jRoot 'config.yml') -Encoding UTF8
    $kConfig = Get-Content -Raw -LiteralPath (Join-Path $kRoot 'config.yml') -Encoding UTF8
    $jConfigOk = $jConfig -match '(?ms)^async:\s+enabled:\s+true\s*$' -and
        $jConfig -match '(?ms)^task:\s+batch:\s+true\s*$' -and
        $jConfig -match '(?m)^  maxConcurrency:\s+3\s*$' -and
        $jConfig -match '(?ms)^  isolation:\s+mode:\s+rcopy\s+apply:\s+false\s*$'
    $kConfigOk = $kConfig -match '(?ms)^async:\s+enabled:\s+true\s*$' -and
        $kConfig -match '(?ms)^task:\s+batch:\s+false\s*$' -and
        $kConfig -match '(?ms)^  isolation:\s+mode:\s+none\s*$'
    New-Phase00FixtureCheck P00-RUNTIME-J-CONFIG $jConfigOk 'E3-J overlay pins async batch concurrency and capture-only isolation.'
    New-Phase00FixtureCheck P00-RUNTIME-K-CONFIG $kConfigOk 'E3-K overlay pins flat wire and disables isolation.'

    $blockingFiles = @(
        (Join-Path $jRoot '.omp\agents\phase00-blocking-probe.md'),
        (Join-Path $kRoot '.omp\agents\phase00-blocking-probe.md')
    )
    $blockingOk = @($blockingFiles | Where-Object { (Get-Content -Raw -LiteralPath $_ -Encoding UTF8) -notmatch '(?m)^blocking:\s+true\s*$' }).Count -eq 0
    $background = Get-Content -Raw -LiteralPath (Join-Path $jRoot '.omp\agents\phase00-background-probe.md') -Encoding UTF8
    $backgroundOk = $background -notmatch '(?m)^blocking:'
    New-Phase00FixtureCheck P00-RUNTIME-BLOCKING-AGENT $blockingOk 'Both blocking probe definitions declare blocking: true.'
    New-Phase00FixtureCheck P00-RUNTIME-CONTROL-AGENT $backgroundOk 'The control agent omits the blocking key.'

    $allFixtureText = @($required | ForEach-Object { Get-Content -Raw -LiteralPath (Join-Path $root $_) -Encoding UTF8 }) -join "`n"
    $unsafe = $allFixtureText -match '(?i)C:[/\\]Users[/\\]MrThien[/\\]\.omp[/\\]agent|OPENAI_API_KEY|ANTHROPIC_API_KEY|GEMINI_API_KEY'
    New-Phase00FixtureCheck P00-RUNTIME-FIXTURE-SAFETY (-not $unsafe) 'Fixture inputs contain no live-home path or credential-key marker.'
}
