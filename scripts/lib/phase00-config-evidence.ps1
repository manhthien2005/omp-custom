#Requires -Version 5.1

Set-StrictMode -Version 2.0

function New-Phase00ConfigDecision {
    param(
        [Parameter(Mandatory)][ValidateSet('OBSERVED','REFUSE','INVALID_RUN')][string]$Status,
        [Parameter(Mandatory)][string[]]$Reasons,
        $Observation = $null,
        [AllowNull()]$Fallback = 'SEQUENTIAL_NON_ISOLATED_DISCLOSED',
        [string]$Context = 'DirectRead'
    )

    return [pscustomobject][ordered]@{
        Status = $Status
        Reasons = @($Reasons)
        Observation = $Observation
        Fallback = $Fallback
        Context = $Context
    }
}

function ConvertFrom-Phase00ConfigJson {
    param(
        [Parameter(Mandatory)][string]$ExpectedKey,
        [Parameter(Mandatory)][string]$Text
    )

    try {
        $parsed = $Text.Trim() | ConvertFrom-Json -ErrorAction Stop
    } catch {
        return [pscustomobject][ordered]@{
            Valid = $false
            Reason = 'CONFIG_JSON_INVALID'
            Observation = $null
        }
    }

    if ($null -eq $parsed -or $parsed -is [System.Array] -or
        $parsed -is [string] -or $parsed -is [ValueType]) {
        return [pscustomobject][ordered]@{
            Valid = $false
            Reason = 'CONFIG_SHAPE_MISMATCH'
            Observation = $null
        }
    }

    $propertyNames = @($parsed.PSObject.Properties.Name | Sort-Object)
    if (($propertyNames -join ',') -ne 'description,key,type,value') {
        return [pscustomobject][ordered]@{
            Valid = $false
            Reason = 'CONFIG_SHAPE_MISMATCH'
            Observation = $null
        }
    }

    if ([string]$parsed.key -cne $ExpectedKey) {
        return [pscustomobject][ordered]@{
            Valid = $false
            Reason = 'CONFIG_KEY_MISMATCH'
            Observation = $null
        }
    }

    $expectedType = switch ($ExpectedKey) {
        'task.isolation.mode' { 'enum' }
        'task.isolation.apply' { 'boolean' }
        default { $null }
    }
    if ($null -eq $expectedType -or [string]$parsed.type -cne $expectedType) {
        return [pscustomobject][ordered]@{
            Valid = $false
            Reason = 'CONFIG_TYPE_MISMATCH'
            Observation = $null
        }
    }

    $valueTypeValid = if ($expectedType -eq 'enum') {
        $parsed.value -is [string]
    } else {
        $parsed.value -is [bool]
    }
    if (-not $valueTypeValid -or $parsed.description -isnot [string]) {
        return [pscustomobject][ordered]@{
            Valid = $false
            Reason = 'CONFIG_VALUE_TYPE_MISMATCH'
            Observation = $null
        }
    }

    return [pscustomobject][ordered]@{
        Valid = $true
        Reason = $null
        Observation = [pscustomobject][ordered]@{
            Key = [string]$parsed.key
            Value = $parsed.value
            Type = [string]$parsed.type
            Description = [string]$parsed.description
        }
    }
}

function Get-Phase00ConfigCommandClassification {
    param(
        [Parameter(Mandatory)][string]$ExpectedKey,
        [Parameter(Mandatory)][int]$ExitCode,
        [AllowEmptyString()][Parameter(Mandatory)][string]$Stdout,
        [AllowEmptyString()][Parameter(Mandatory)][string]$Stderr,
        [Parameter(Mandatory)][ValidateSet('DirectRead','ProjectRoot','NoProject','CliOverlay','NestedCwd','ToolUnavailable','Synthetic')][string]$Context
    )

    if ($Context -eq 'CliOverlay' -and $ExitCode -ne 0 -and
        $Stderr -match '(?i)Unknown option [''"]--config[''"]') {
        return New-Phase00ConfigDecision -Status REFUSE `
            -Reasons @('CONFIG_CLI_OVERLAY_UNSUPPORTED','CLI_OVERLAY_UNOBSERVABLE') `
            -Context $Context
    }

    if ($ExitCode -ne 0 -and $Stderr -match '(?i)Unknown setting:') {
        return New-Phase00ConfigDecision -Status REFUSE `
            -Reasons @('CONFIG_KEY_UNKNOWN') -Context $Context
    }

    if ($ExitCode -ne 0) {
        return New-Phase00ConfigDecision -Status REFUSE `
            -Reasons @('CONFIG_READ_NONZERO') -Context $Context
    }

    if ([string]::IsNullOrWhiteSpace($Stdout)) {
        return New-Phase00ConfigDecision -Status INVALID_RUN `
            -Reasons @('CONFIG_STDOUT_EMPTY') -Context $Context
    }

    $parsedResult = ConvertFrom-Phase00ConfigJson -ExpectedKey $ExpectedKey -Text $Stdout
    if (-not $parsedResult.Valid) {
        $status = if ($parsedResult.Reason -eq 'CONFIG_JSON_INVALID') { 'REFUSE' } else { 'INVALID_RUN' }
        return New-Phase00ConfigDecision -Status $status `
            -Reasons @([string]$parsedResult.Reason) -Context $Context
    }

    return New-Phase00ConfigDecision -Status OBSERVED -Reasons @('CONFIG_READ_OK') `
        -Observation $parsedResult.Observation -Fallback $null -Context $Context
}

function Test-Phase00IsolationDiagnostic {
    param(
        [Parameter(Mandatory)]$ModeResult,
        [Parameter(Mandatory)]$ApplyResult,
        [Parameter(Mandatory)][ValidateSet('DirectRead','ProjectRoot','NoProject','CliOverlay','NestedCwd','ToolUnavailable','Synthetic')][string]$Context
    )

    $reasons = [System.Collections.Generic.List[string]]::new()
    $mode = $null
    $apply = $null

    if ([string]$ModeResult.Status -eq 'OBSERVED' -and $null -ne $ModeResult.Observation) {
        $mode = $ModeResult.Observation.Value
        if ([string]$mode -eq 'none') { [void]$reasons.Add('ISOLATION_MODE_NONE') }
    } else {
        foreach ($reason in @($ModeResult.Reasons)) {
            if (-not $reasons.Contains([string]$reason)) { [void]$reasons.Add([string]$reason) }
        }
    }

    if ([string]$ApplyResult.Status -eq 'OBSERVED' -and $null -ne $ApplyResult.Observation) {
        $apply = $ApplyResult.Observation.Value
        if ($apply -eq $true) { [void]$reasons.Add('ISOLATION_APPLY_TRUE') }
    } else {
        foreach ($reason in @($ApplyResult.Reasons)) {
            if (-not $reasons.Contains([string]$reason)) { [void]$reasons.Add([string]$reason) }
        }
    }

    if ($Context -eq 'NestedCwd' -and $reasons.Count -gt 0) {
        [void]$reasons.Add('CWD_PROJECT_CONFIG_NOT_DISCOVERED')
    }

    if ($reasons.Count -eq 0) {
        return [pscustomobject][ordered]@{
            Decision = 'DIAGNOSTIC_OK_NOT_AUTHORIZATION'
            Reasons = @('CONFIG_VALUES_MATCH_CAPTURE_ONLY_EXPECTATION')
            Fallback = $null
            Context = $Context
            Mode = $mode
            Apply = $apply
        }
    }

    return [pscustomobject][ordered]@{
        Decision = 'REFUSE'
        Reasons = @($reasons)
        Fallback = 'SEQUENTIAL_NON_ISOLATED_DISCLOSED'
        Context = $Context
        Mode = $mode
        Apply = $apply
    }
}

function Test-Phase00A1Evidence {
    param(
        [Parameter(Mandatory)]$ModeResult,
        [Parameter(Mandatory)]$ApplyResult
    )

    if ([string]$ModeResult.Status -ne 'OBSERVED' -or [string]$ApplyResult.Status -ne 'OBSERVED') {
        return New-Phase00RuntimeAnalysis INVALID_RUN @('A1_CONFIG_OBSERVATION_INCOMPLETE')
    }
    $diagnostic = Test-Phase00IsolationDiagnostic -ModeResult $ModeResult -ApplyResult $ApplyResult -Context ProjectRoot
    if ([string]$ModeResult.Observation.Value -ne 'rcopy' -or
        $ApplyResult.Observation.Value -ne $false -or
        $diagnostic.Decision -ne 'DIAGNOSTIC_OK_NOT_AUTHORIZATION') {
        return New-Phase00RuntimeAnalysis FAIL @('A1_EFFECTIVE_PROJECT_VALUES_MISMATCH') @{
            Mode = $ModeResult.Observation.Value
            Apply = $ApplyResult.Observation.Value
            DiagnosticDecision = $diagnostic.Decision
        }
    }
    return New-Phase00RuntimeAnalysis PASS @('A1_EFFECTIVE_PROJECT_VALUES') @{
        Mode = 'rcopy'
        Apply = $false
        DiagnosticDecision = $diagnostic.Decision
    }
}

function Test-Phase00A2Evidence {
    param([Parameter(Mandatory)]$UnknownResult)

    if ([string]$UnknownResult.Status -eq 'REFUSE' -and
        (@($UnknownResult.Reasons) -join ',') -eq 'CONFIG_KEY_UNKNOWN' -and
        $null -eq $UnknownResult.Observation) {
        return New-Phase00RuntimeAnalysis PASS @('A2_UNKNOWN_KEY_REFUSED') @{
            AcceptedObservation = $false
        }
    }
    $status = if ([string]$UnknownResult.Status -eq 'INVALID_RUN') { 'INVALID_RUN' } else { 'FAIL' }
    return New-Phase00RuntimeAnalysis $status @('A2_UNKNOWN_KEY_NOT_REFUSED')
}

function Test-Phase00A3Evidence {
    param(
        [Parameter(Mandatory)]$RootModeResult,
        [Parameter(Mandatory)]$RootApplyResult,
        [Parameter(Mandatory)]$NestedModeResult,
        [Parameter(Mandatory)]$NestedApplyResult
    )

    $root = Test-Phase00A1Evidence -ModeResult $RootModeResult -ApplyResult $RootApplyResult
    if ($root.Status -ne 'PASS') {
        return New-Phase00RuntimeAnalysis INVALID_RUN @('A3_ROOT_CONTROL_INVALID')
    }
    if ([string]$NestedModeResult.Status -ne 'OBSERVED' -or [string]$NestedApplyResult.Status -ne 'OBSERVED') {
        return New-Phase00RuntimeAnalysis INVALID_RUN @('A3_NESTED_OBSERVATION_INCOMPLETE')
    }
    $nested = Test-Phase00IsolationDiagnostic -ModeResult $NestedModeResult -ApplyResult $NestedApplyResult -Context NestedCwd
    $expected = [string]$NestedModeResult.Observation.Value -eq 'none' -and
        $NestedApplyResult.Observation.Value -eq $true -and
        $nested.Decision -eq 'REFUSE' -and
        @($nested.Reasons) -contains 'CWD_PROJECT_CONFIG_NOT_DISCOVERED'
    if (-not $expected) {
        return New-Phase00RuntimeAnalysis FAIL @('A3_CWD_SENSITIVITY_MISMATCH') @{
            NestedMode = $NestedModeResult.Observation.Value
            NestedApply = $NestedApplyResult.Observation.Value
            NestedDecision = $nested.Decision
        }
    }
    return New-Phase00RuntimeAnalysis PASS @('A3_CWD_PROJECT_CONFIG_NOT_DISCOVERED') @{
        RootMode = 'rcopy'
        RootApply = $false
        NestedMode = 'none'
        NestedApply = $true
        NestedDecision = $nested.Decision
    }
}

function Test-Phase00H1Evidence {
    param(
        [Parameter(Mandatory)][bool]$GlobalApply,
        [Parameter(Mandatory)]$ProjectApplyResult
    )

    if ([string]$ProjectApplyResult.Status -ne 'OBSERVED') {
        return New-Phase00RuntimeAnalysis INVALID_RUN @('H1_PROJECT_OBSERVATION_INCOMPLETE')
    }
    if ($GlobalApply -ne $true -or $ProjectApplyResult.Observation.Value -ne $false) {
        return New-Phase00RuntimeAnalysis FAIL @('H1_PRECEDENCE_MISMATCH') @{
            GlobalApply = $GlobalApply
            ProjectApply = $ProjectApplyResult.Observation.Value
        }
    }
    return New-Phase00RuntimeAnalysis PASS @('H1_PROJECT_OVERRIDES_GLOBAL') @{
        GlobalApply = $true
        ProjectApply = $false
        DiagnosticDecision = 'DIAGNOSTIC_OK_NOT_AUTHORIZATION'
    }
}

function Test-Phase00H2Evidence {
    param(
        [Parameter(Mandatory)]$ModeResult,
        [Parameter(Mandatory)]$ApplyResult
    )

    if ([string]$ModeResult.Status -ne 'OBSERVED' -or [string]$ApplyResult.Status -ne 'OBSERVED') {
        return New-Phase00RuntimeAnalysis INVALID_RUN @('H2_DEFAULT_OBSERVATION_INCOMPLETE')
    }
    $diagnostic = Test-Phase00IsolationDiagnostic -ModeResult $ModeResult -ApplyResult $ApplyResult -Context NoProject
    if (($diagnostic.Reasons -join ',') -ne 'ISOLATION_MODE_NONE,ISOLATION_APPLY_TRUE') {
        return New-Phase00RuntimeAnalysis FAIL @('H2_DEFAULT_REFUSAL_MISMATCH') @{
            RefusalReasons = @($diagnostic.Reasons)
        }
    }
    return New-Phase00RuntimeAnalysis PASS @('H2_DEFAULTS_REFUSED') @{
        RefusalReasons = @($diagnostic.Reasons)
        Fallback = $diagnostic.Fallback
    }
}

function Test-Phase00H3Evidence {
    param(
        [Parameter(Mandatory)]$BeforeResult,
        [Parameter(Mandatory)]$AfterResult
    )

    $required = 'CONFIG_CLI_OVERLAY_UNSUPPORTED,CLI_OVERLAY_UNOBSERVABLE'
    $bothRefuse = [string]$BeforeResult.Status -eq 'REFUSE' -and
        [string]$AfterResult.Status -eq 'REFUSE' -and
        (@($BeforeResult.Reasons) -join ',') -eq $required -and
        (@($AfterResult.Reasons) -join ',') -eq $required -and
        $null -eq $BeforeResult.Observation -and $null -eq $AfterResult.Observation
    if (-not $bothRefuse) {
        return New-Phase00RuntimeAnalysis FAIL @('H3_OVERLAY_CONTROL_SURFACE_MISMATCH') @{
            PrecedenceRead = $false
        }
    }
    return New-Phase00RuntimeAnalysis PASS @('H3_CONFIG_CLI_OVERLAY_UNSUPPORTED_FAIL_CLOSED') @{
        PrecedenceRead = $false
        DiagnosticDecision = 'REFUSE'
    }
}

function Test-Phase00H4Evidence {
    param(
        [Parameter(Mandatory)]$ModeResult,
        [Parameter(Mandatory)]$ApplyResult
    )

    if ([string]$ModeResult.Status -ne 'OBSERVED' -or [string]$ApplyResult.Status -ne 'OBSERVED') {
        return New-Phase00RuntimeAnalysis INVALID_RUN @('H4_NESTED_OBSERVATION_INCOMPLETE')
    }
    $diagnostic = Test-Phase00IsolationDiagnostic -ModeResult $ModeResult -ApplyResult $ApplyResult -Context NestedCwd
    $expected = $diagnostic.Decision -eq 'REFUSE' -and
        @($diagnostic.Reasons) -contains 'CWD_PROJECT_CONFIG_NOT_DISCOVERED' -and
        $diagnostic.Fallback -eq 'SEQUENTIAL_NON_ISOLATED_DISCLOSED'
    if (-not $expected) {
        return New-Phase00RuntimeAnalysis FAIL @('H4_CWD_REFUSAL_MISMATCH')
    }
    return New-Phase00RuntimeAnalysis PASS @('H4_NESTED_CWD_REFUSED') @{
        RefusalReasons = @($diagnostic.Reasons)
        Fallback = $diagnostic.Fallback
    }
}

function Test-Phase00H6Evidence {
    param(
        [Parameter(Mandatory)]$NonzeroResult,
        [Parameter(Mandatory)]$InvalidJsonResult
    )

    $expected = [string]$NonzeroResult.Status -eq 'REFUSE' -and
        (@($NonzeroResult.Reasons) -join ',') -eq 'CONFIG_READ_NONZERO' -and
        [string]$InvalidJsonResult.Status -eq 'REFUSE' -and
        (@($InvalidJsonResult.Reasons) -join ',') -eq 'CONFIG_JSON_INVALID'
    if (-not $expected) {
        return New-Phase00RuntimeAnalysis FAIL @('H6_FAIL_CLOSED_CONTROLS_MISMATCH') @{
            RuntimeCall = $false
        }
    }
    return New-Phase00RuntimeAnalysis PASS @('H6_DISTINCT_FAIL_CLOSED_CONTROLS') @{
        RuntimeCall = $false
        NonzeroReason = 'CONFIG_READ_NONZERO'
        InvalidJsonReason = 'CONFIG_JSON_INVALID'
    }
}

function Get-Phase00NamedToolEventPairs {
    param(
        [Parameter(Mandatory)][object[]]$Events,
        [Parameter(Mandatory)][string]$ToolName
    )

    $starts = @{}
    $ends = @{}
    $startIndexes = @{}
    $endIndexes = @{}
    for ($index = 0; $index -lt $Events.Count; $index++) {
        $event = $Events[$index]
        if ([string](Get-Phase00PropertyValue $event 'toolName') -ne $ToolName) { continue }
        $id = [string](Get-Phase00PropertyValue $event 'toolCallId')
        if ([string]::IsNullOrWhiteSpace($id)) { throw "$ToolName event at index $index has no toolCallId." }
        $type = [string](Get-Phase00PropertyValue $event 'type')
        if ($type -eq 'tool_execution_start') {
            if ($starts.ContainsKey($id)) { throw "Duplicate $ToolName start for '$id'." }
            $starts[$id] = $event
            $startIndexes[$id] = $index
        } elseif ($type -eq 'tool_execution_end') {
            if ($ends.ContainsKey($id)) { throw "Duplicate $ToolName end for '$id'." }
            $ends[$id] = $event
            $endIndexes[$id] = $index
        }
    }
    $ids = @($starts.Keys + $ends.Keys | Sort-Object -Unique)
    if ($ids.Count -eq 0) { throw "No $ToolName tool events were found." }
    $pairs = foreach ($id in $ids) {
        if (-not $starts.ContainsKey($id) -or -not $ends.ContainsKey($id)) {
            throw "Unpaired $ToolName event for '$id'."
        }
        if ([int]$startIndexes[$id] -ge [int]$endIndexes[$id]) {
            throw "$ToolName end for '$id' does not follow its start."
        }
        [pscustomobject][ordered]@{
            ToolCallId = $id
            StartIndex = [int]$startIndexes[$id]
            EndIndex = [int]$endIndexes[$id]
            Start = $starts[$id]
            End = $ends[$id]
        }
    }
    return @($pairs | Sort-Object StartIndex)
}

function Test-Phase00A4Evidence {
    param(
        [Parameter(Mandatory)][object[]]$Events,
        [Parameter(Mandatory)][bool]$SentinelObserved
    )

    try {
        $bashPairs = @(Get-Phase00NamedToolEventPairs -Events $Events -ToolName 'bash')
        if ($bashPairs.Count -ne 1) {
            return New-Phase00RuntimeAnalysis INVALID_RUN @('A4_BASH_CALL_COUNT_MISMATCH') @{
                BashCallCount = $bashPairs.Count
                SentinelApplied = $SentinelObserved
                EvalBridgeProvesArkTypeDeletion = $false
            }
        }
        $attestation = $null
        $attestationIndex = -1
        foreach ($pair in $bashPairs) {
            $text = Get-Phase00TextContent -Result (Get-Phase00PropertyValue $pair.End 'result')
            foreach ($line in @($text -split "\r?\n")) {
                $candidateText = $line.Trim()
                if ([string]::IsNullOrWhiteSpace($candidateText)) { continue }
                try { $candidate = $candidateText | ConvertFrom-Json -ErrorAction Stop } catch { continue }
                if ([string](Get-Phase00PropertyValue $candidate 'probe') -eq 'phase00-task-item-wire-v1') {
                    $attestation = $candidate
                    $attestationIndex = $pair.EndIndex
                    break
                }
            }
            if ($null -ne $attestation) { break }
        }
        if ($null -eq $attestation) { throw 'A4 supported-wire attestation is absent.' }

        $hasIsolated = (Get-Phase00PropertyValue $attestation 'has_isolated') -eq $true
        $hasApply = (Get-Phase00PropertyValue $attestation 'has_apply') -eq $true
        $itemKeys = @(Get-Phase00PropertyValue $attestation 'item_keys')
        if ($hasApply -or $itemKeys -contains 'apply') {
            return New-Phase00RuntimeAnalysis FAIL @('A4_SUPPORTED_WIRE_EXPOSES_APPLY') @{
                HasIsolated = $hasIsolated
                HasApply = $true
                SentinelApplied = $SentinelObserved
                EvalBridgeProvesArkTypeDeletion = $false
            }
        }
        $wireExpected = $hasIsolated -and $itemKeys -contains 'isolated' -and
            [string](Get-Phase00PropertyValue $attestation 'decision') -eq 'RUN_RAW_NON_AUTHORITY_CONTROL'
        if (-not $wireExpected) {
            return New-Phase00RuntimeAnalysis FAIL @('A4_SUPPORTED_WIRE_MISMATCH') @{
                HasIsolated = $hasIsolated
                HasApply = $hasApply
                SentinelApplied = $SentinelObserved
                EvalBridgeProvesArkTypeDeletion = $false
            }
        }

        $evalPairs = @(Get-Phase00NamedToolEventPairs -Events $Events -ToolName 'eval')
        if ($evalPairs.Count -ne 1) { throw "A4 expected one eval call; observed $($evalPairs.Count)." }
        $evalPair = $evalPairs[0]
        if ($attestationIndex -ge $evalPair.StartIndex) { throw 'A4 eval started before wire attestation completed.' }
        $evalArgs = Get-Phase00PropertyValue $evalPair.Start 'args'
        $code = [string](Get-Phase00PropertyValue $evalArgs 'code')
        $rawControlPresent = $code -match '(?s)tool\.task\s*\(' -and
            $code -match '(?s)tasks\s*:' -and
            $code -match '(?s)agent\s*:\s*["'']phase00-apply-probe["'']' -and
            $code -match '(?s)isolated\s*:\s*true' -and
            $code -match '(?s)apply\s*:\s*false'
        if (-not $rawControlPresent) {
            return New-Phase00RuntimeAnalysis FAIL @('A4_FORCED_RAW_CONTROL_MISMATCH') @{
                HasIsolated = $hasIsolated
                HasApply = $hasApply
                SentinelApplied = $SentinelObserved
                EvalBridgeProvesArkTypeDeletion = $false
            }
        }
        if ((Get-Phase00PropertyValue $evalPair.End 'isError') -eq $true) {
            return New-Phase00RuntimeAnalysis FAIL @('A4_EVAL_CONTROL_FAILED')
        }
        $evalText = Get-Phase00TextContent -Result (Get-Phase00PropertyValue $evalPair.End 'result')
        if ($evalText -match '(?i)(status="cancelled"|<abort-reason>|"aborted"\s*:\s*true|abortReason)') {
            return New-Phase00RuntimeAnalysis INVALID_RUN @('A4_CHILD_ABORTED') @{
                HasIsolated = $hasIsolated
                HasApply = $hasApply
                SentinelApplied = $SentinelObserved
                EvalBridgeProvesArkTypeDeletion = $false
            }
        }
        $appliedSummary = $evalText -match '(?i)(Applied patches:\s*yes|Merged branch:)'
        if (-not $SentinelObserved -or -not $appliedSummary) {
            return New-Phase00RuntimeAnalysis FAIL @('A4_SESSION_APPLY_TRUE_NOT_OBSERVED') @{
                HasIsolated = $hasIsolated
                HasApply = $hasApply
                SentinelApplied = $SentinelObserved
                AppliedSummary = $appliedSummary
                EvalBridgeProvesArkTypeDeletion = $false
            }
        }
        return New-Phase00RuntimeAnalysis PASS @('A4_PER_ITEM_APPLY_NOT_AUTHORITY') @{
            HasIsolated = $true
            HasApply = $false
            SentinelApplied = $true
            AppliedSummary = $true
            EvalBridgeProvesArkTypeDeletion = $false
        }
    } catch {
        return New-Phase00RuntimeAnalysis INVALID_RUN @("A4_INVALID: $($_.Exception.Message)") @{
            SentinelApplied = $SentinelObserved
            EvalBridgeProvesArkTypeDeletion = $false
        }
    }
}

function Test-Phase00H5Evidence {
    param([Parameter(Mandatory)][object[]]$Events)

    try {
        $bashPairs = @(Get-Phase00NamedToolEventPairs -Events $Events -ToolName 'bash')
        if ($bashPairs.Count -ne 1) { throw "H5 expected one bash call; observed $($bashPairs.Count)." }
        $pair = $bashPairs[0]
        $command = [string](Get-Phase00PropertyValue (Get-Phase00PropertyValue $pair.Start 'args') 'command')
        if ($command.Trim() -cne 'omp config get task.isolation.mode --json') {
            return New-Phase00RuntimeAnalysis FAIL @('H5_CONFIG_COMMAND_MISMATCH')
        }
        $taskDispatchCount = @($Events | Where-Object {
            [string](Get-Phase00PropertyValue $_ 'type') -eq 'tool_execution_start' -and
            [string](Get-Phase00PropertyValue $_ 'toolName') -eq 'task'
        }).Count
        if ($taskDispatchCount -ne 0) {
            return New-Phase00RuntimeAnalysis FAIL @('H5_TASK_DISPATCH_OCCURRED') @{
                TaskDispatchCount = $taskDispatchCount
            }
        }
        $endResult = Get-Phase00PropertyValue $pair.End 'result'
        $details = Get-Phase00PropertyValue $endResult 'details'
        $exitCode = Get-Phase00PropertyValue $details 'exitCode'
        $isError = (Get-Phase00PropertyValue $pair.End 'isError') -eq $true
        $text = Get-Phase00TextContent -Result $endResult
        $unavailable = $text -match '(?i)(not recognized|command not found|not found as a command|not a recognized)'
        $nonzero = $isError -or ($null -ne $exitCode -and [int]$exitCode -ne 0)
        if (-not $nonzero -or -not $unavailable) {
            return New-Phase00RuntimeAnalysis FAIL @('H5_COMMAND_UNAVAILABLE_SHAPE_MISMATCH') @{
                TaskDispatchCount = 0
            }
        }
        return New-Phase00RuntimeAnalysis PASS @('H5_CONFIG_COMMAND_UNAVAILABLE') @{
            ConfigReason = 'CONFIG_COMMAND_UNAVAILABLE'
            TaskDispatchCount = 0
            StructuredToolEvidence = $true
        }
    } catch {
        return New-Phase00RuntimeAnalysis INVALID_RUN @('H5_STRUCTURED_BASH_EVIDENCE_MISSING',"H5_INVALID: $($_.Exception.Message)") @{
            TaskDispatchCount = 0
        }
    }
}
