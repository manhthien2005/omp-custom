#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:AgentTasksMaximumJsonBytes = 1MB
$script:AgentTasksMaximumJsonDepth = 32
$script:AgentTasksMaximumSafeInteger = [long]9007199254740991
$script:AgentTasksForbiddenPropertyNames = [Collections.Generic.HashSet[string]]::new(
    [string[]]@(
        'command_to_run', 'transcript', 'reasoning', 'api_key', 'token', 'secret',
        'credential', 'env_contents', 'terminal_history'
    ),
    [StringComparer]::OrdinalIgnoreCase
)

function New-AgentTasksResult {
    param(
        [Parameter(Mandatory)][bool]$Ok,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Operation,
        [AllowNull()][object]$Data
    )

    if ($null -eq $Data) { $Data = [ordered]@{} }
    return [ordered]@{
        ok = $Ok
        code = $Code
        operation = $Operation
        data = $Data
    }
}

function Throw-AgentTasksError {
    param(
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][ValidateSet(2, 3, 4, 5)][int]$ExitCode,
        [Parameter(Mandatory)][string]$SafeMessage
    )

    $exception = [InvalidOperationException]::new($SafeMessage)
    $exception.Data['AgentTasksCode'] = $Code
    $exception.Data['AgentTasksExitCode'] = $ExitCode
    $exception.Data['AgentTasksSafeMessage'] = $SafeMessage
    throw $exception
}

function ConvertTo-AgentTasksFailure {
    param(
        [Parameter(Mandatory)][Exception]$Exception,
        [Parameter(Mandatory)][string]$Operation
    )

    $code = [string]$Exception.Data['AgentTasksCode']
    $storedExitCode = $Exception.Data['AgentTasksExitCode']
    if ($code -and $null -ne $storedExitCode) {
        $exitCode = [int]$storedExitCode
        $safeMessage = [string]$Exception.Data['AgentTasksSafeMessage']
        if (-not $safeMessage) { $safeMessage = 'The request was refused.' }
    } else {
        $code = 'AT-INTERNAL'
        $exitCode = 5
        $safeMessage = 'An unexpected internal error occurred.'
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Result = New-AgentTasksResult -Ok $false -Code $code -Operation $Operation -Data ([ordered]@{
            message = $safeMessage
        })
        Diagnostic = $code
    }
}

function ConvertFrom-AgentTasksJsonElement {
    param(
        [Parameter(Mandatory)][Text.Json.JsonElement]$Element,
        [Parameter(Mandatory)][int]$Depth
    )

    if ($Depth -gt $script:AgentTasksMaximumJsonDepth) {
        Throw-AgentTasksError -Code 'AT-JSON-LIMIT' -ExitCode 2 -SafeMessage 'The JSON nesting depth exceeds the supported limit.'
    }

    switch ($Element.ValueKind) {
        ([Text.Json.JsonValueKind]::Object) {
            $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            $value = [ordered]@{}
            foreach ($property in $Element.EnumerateObject()) {
                if (-not $seen.Add($property.Name)) {
                    Throw-AgentTasksError -Code 'AT-JSON-DUPLICATE-KEY' -ExitCode 2 -SafeMessage 'The JSON document contains a duplicate object property.'
                }
                if ($script:AgentTasksForbiddenPropertyNames.Contains($property.Name)) {
                    Throw-AgentTasksError -Code 'AT-SCHEMA-FORBIDDEN-PROPERTY' -ExitCode 2 -SafeMessage 'The JSON document contains a forbidden property name.'
                }
                $value[$property.Name] = ConvertFrom-AgentTasksJsonElement -Element $property.Value -Depth ($Depth + 1)
            }
            return ,$value
        }
        ([Text.Json.JsonValueKind]::Array) {
            $items = [Collections.Generic.List[object]]::new()
            foreach ($item in $Element.EnumerateArray()) {
                [void]$items.Add((ConvertFrom-AgentTasksJsonElement -Element $item -Depth ($Depth + 1)))
            }
            return ,$items.ToArray()
        }
        ([Text.Json.JsonValueKind]::String) {
            return $Element.GetString()
        }
        ([Text.Json.JsonValueKind]::Number) {
            $raw = $Element.GetRawText()
            if ($raw -notmatch '^-?(0|[1-9][0-9]*)$') {
                Throw-AgentTasksError -Code 'AT-JSON-NUMBER' -ExitCode 2 -SafeMessage 'Only integers are supported in authority JSON.'
            }
            [long]$integer = 0
            if (-not [long]::TryParse($raw, [Globalization.NumberStyles]::AllowLeadingSign, [Globalization.CultureInfo]::InvariantCulture, [ref]$integer)) {
                Throw-AgentTasksError -Code 'AT-JSON-NUMBER' -ExitCode 2 -SafeMessage 'The JSON integer is outside the supported range.'
            }
            if ([Math]::Abs([decimal]$integer) -gt $script:AgentTasksMaximumSafeInteger) {
                Throw-AgentTasksError -Code 'AT-JSON-NUMBER' -ExitCode 2 -SafeMessage 'The JSON integer is outside the safe-integer range.'
            }
            return $integer
        }
        ([Text.Json.JsonValueKind]::True) { return $true }
        ([Text.Json.JsonValueKind]::False) { return $false }
        ([Text.Json.JsonValueKind]::Null) { return $null }
        default {
            Throw-AgentTasksError -Code 'AT-JSON-SYNTAX' -ExitCode 2 -SafeMessage 'The JSON document contains an unsupported value.'
        }
    }
}

function ConvertFrom-AgentTasksJsonBytes {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    if ($Bytes.Length -gt $script:AgentTasksMaximumJsonBytes) {
        Throw-AgentTasksError -Code 'AT-JSON-LIMIT' -ExitCode 2 -SafeMessage 'The JSON request exceeds the supported byte limit.'
    }

    try {
        $utf8 = [Text.UTF8Encoding]::new($false, $true)
        $json = $utf8.GetString($Bytes)
    } catch {
        Throw-AgentTasksError -Code 'AT-JSON-ENCODING' -ExitCode 2 -SafeMessage 'The JSON request must be valid UTF-8.'
    }

    $options = [Text.Json.JsonDocumentOptions]::new()
    $options.AllowTrailingCommas = $false
    $options.CommentHandling = [Text.Json.JsonCommentHandling]::Disallow
    $options.MaxDepth = 128
    try {
        $document = [Text.Json.JsonDocument]::Parse($json, $options)
    } catch {
        Throw-AgentTasksError -Code 'AT-JSON-SYNTAX' -ExitCode 2 -SafeMessage 'The JSON request is malformed.'
    }

    try {
        return ConvertFrom-AgentTasksJsonElement -Element $document.RootElement -Depth 1
    } finally {
        $document.Dispose()
    }
}

function Read-AgentTasksJsonFile {
    param([Parameter(Mandatory)][string]$LiteralPath)

    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        Throw-AgentTasksError -Code 'AT-JSON-NOT-FOUND' -ExitCode 4 -SafeMessage 'The requested JSON document does not exist.'
    }
    try {
        $bytes = [IO.File]::ReadAllBytes($LiteralPath)
    } catch {
        Throw-AgentTasksError -Code 'AT-JSON-READ' -ExitCode 4 -SafeMessage 'The JSON document could not be read.'
    }
    return ConvertFrom-AgentTasksJsonBytes -Bytes $bytes
}

function Assert-AgentTasksClosedObject {
    param(
        [Parameter(Mandatory)][Collections.IDictionary]$Value,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Allowed,
        [AllowEmptyCollection()][string[]]$Required = @()
    )

    $allowedSet = [Collections.Generic.HashSet[string]]::new($Allowed, [StringComparer]::Ordinal)
    foreach ($key in $Value.Keys) {
        if (-not $allowedSet.Contains([string]$key)) {
            Throw-AgentTasksError -Code 'AT-SCHEMA-UNKNOWN-PROPERTY' -ExitCode 2 -SafeMessage 'The JSON document contains an unknown property.'
        }
    }
    foreach ($key in $Required) {
        if (-not $Value.Contains($key)) {
            Throw-AgentTasksError -Code 'AT-SCHEMA-REQUIRED' -ExitCode 2 -SafeMessage 'The JSON document is missing a required property.'
        }
    }
}

function Get-AgentTasksRequestShape {
    param([Parameter(Mandatory)][string]$Operation)

    $cas = @('expected_revision', 'expected_revision_sha256', 'expected_lease_generation')
    $shapes = @{
        'init-project' = @{ Allowed = @('display_name'); Required = @('display_name') }
        'create-phase' = @{ Allowed = @('phase_id', 'objective', 'authority', 'dependencies', 'exit_obligations') + $cas; Required = @('phase_id', 'objective', 'authority', 'dependencies', 'exit_obligations') }
        'transition-phase' = @{ Allowed = @('phase_id', 'target_status') + $cas; Required = @('phase_id', 'target_status', 'expected_revision', 'expected_revision_sha256') }
        'create-task' = @{ Allowed = @('objective', 'authority', 'acceptance_criteria', 'obligations', 'execution_mode', 'write_scope', 'phase_id', 'owned_ignored_outputs', 'scope_override', 'workflow_class', 'locked_decisions') + $cas; Required = @('objective', 'authority', 'acceptance_criteria', 'obligations', 'execution_mode', 'write_scope', 'workflow_class', 'locked_decisions') }
        'set-continuity-contract' = @{ Allowed = @('task_id', 'workflow_class', 'locked_decisions', 'authority_ref', 'reason') + $cas; Required = @('task_id', 'workflow_class', 'locked_decisions', 'authority_ref', 'reason', 'expected_revision', 'expected_revision_sha256', 'expected_lease_generation') }
        'bind-worktree' = @{ Allowed = @('task_id', 'worktree_root') + $cas; Required = @('task_id', 'worktree_root', 'expected_revision', 'expected_revision_sha256', 'expected_lease_generation') }
        'claim' = @{ Allowed = @('task_id') + $cas; Required = @('task_id', 'expected_revision', 'expected_revision_sha256', 'expected_lease_generation') }
        'create-work-unit' = @{ Allowed = @('task_id', 'work_unit_id', 'inputs', 'outputs', 'ownership', 'dependencies', 'completion_conditions') + $cas; Required = @('task_id', 'work_unit_id', 'inputs', 'outputs', 'ownership', 'dependencies', 'completion_conditions') }
        'project-work-unit' = @{ Allowed = @('task_id', 'work_unit_id'); Required = @('task_id', 'work_unit_id') }
        'project-continuity' = @{ Allowed = @(); Required = @() }
        'record-work-unit-outcome' = @{ Allowed = @('task_id', 'work_unit_id', 'status', 'artifact_refs', 'observed_summary') + $cas; Required = @('task_id', 'work_unit_id', 'status', 'artifact_refs', 'observed_summary') }
        'status' = @{ Allowed = @('task_id', 'phase_id'); Required = @() }
        'checkpoint' = @{ Allowed = @('task_id', 'kind', 'next_action', 'blockers', 'open_risks', 'work_unit_id') + $cas; Required = @('task_id', 'kind', 'next_action', 'blockers', 'open_risks') }
        'freeze' = @{ Allowed = @('task_id', 'acceptance_inputs', 'scope_dispositions') + $cas; Required = @('task_id', 'acceptance_inputs', 'scope_dispositions') }
        'check' = @{ Allowed = @('task_id', 'candidate_id'); Required = @('task_id', 'candidate_id') }
        'promote-artifact' = @{ Allowed = @('task_id', 'source_path', 'media_type', 'candidate_id', 'handoff_id') + $cas; Required = @('task_id', 'source_path', 'media_type') }
        'record-evidence' = @{ Allowed = @('task_id', 'evidence_type', 'covered_ac_ids', 'observation', 'validity_triggers', 'candidate_id', 'artifact_hash', 'producer', 'producer_session_ref', 'acceptance_input_hashes', 'input_evidence_ids', 'authority_scope', 'contract_hash', 'environment_fingerprint', 'source_identity') + $cas; Required = @('task_id', 'evidence_type', 'covered_ac_ids', 'observation', 'validity_triggers') }
        'begin-handoff' = @{ Allowed = @('task_id', 'successor_session_ref', 'successor_runtime', 'next_action', 'blockers', 'open_risks') + $cas; Required = @('task_id', 'successor_session_ref', 'successor_runtime', 'next_action', 'blockers', 'open_risks') }
        'accept-handoff' = @{ Allowed = @('task_id', 'handoff_id', 'predecessor_revision', 'predecessor_revision_sha256') + $cas; Required = @('task_id', 'handoff_id', 'predecessor_revision', 'predecessor_revision_sha256') }
        'takeover' = @{ Allowed = @('task_id', 'successor_session_ref', 'successor_runtime', 'user_authorization', 'reconciliation') + $cas; Required = @('task_id', 'successor_session_ref', 'successor_runtime', 'user_authorization', 'reconciliation') }
        'close' = @{ Allowed = @('task_id', 'terminal_status', 'candidate_id', 'reason') + $cas; Required = @('task_id', 'terminal_status') }
        'invalidate' = @{ Allowed = @('task_id', 'target_type', 'target_id', 'reason', 'remediation_task_id') + $cas; Required = @('task_id', 'target_type', 'target_id', 'reason') }
        'cleanup' = @{ Allowed = @('task_id', 'mode') + $cas; Required = @('task_id') }
        'restore' = @{ Allowed = @('task_id') + $cas; Required = @('task_id') }
        'purge' = @{ Allowed = @('task_id', 'confirmation') + $cas; Required = @('task_id', 'confirmation') }
        'recover-lock' = @{ Allowed = @('lock_domain', 'lock_id', 'user_authorization'); Required = @('lock_domain', 'lock_id', 'user_authorization') }
        'migrate' = @{ Allowed = @('migration_kind', 'target_schema_version'); Required = @('migration_kind') }
    }
    if ($shapes.ContainsKey($Operation)) { return $shapes[$Operation] }
    return $null
}

function Read-AgentTasksEnvelope {
    param([Parameter(Mandatory)][string]$Path)

    if ($Path -ceq '-') {
        $text = [Console]::In.ReadToEnd()
        $bytes = [Text.UTF8Encoding]::new($false, $true).GetBytes($text)
        $value = ConvertFrom-AgentTasksJsonBytes -Bytes $bytes
    } else {
        $value = Read-AgentTasksJsonFile -LiteralPath $Path
    }

    if ($value -isnot [Collections.IDictionary]) {
        Throw-AgentTasksError -Code 'AT-SCHEMA-TYPE' -ExitCode 2 -SafeMessage 'The operation envelope must be a JSON object.'
    }
    Assert-AgentTasksClosedObject -Value $value -Allowed @(
        'schema_version', 'operation', 'working_directory', 'session_ref', 'runtime', 'request'
    ) -Required @('schema_version', 'operation', 'working_directory', 'session_ref', 'runtime', 'request')
    if ([long]$value.schema_version -ne 1) {
        Throw-AgentTasksError -Code 'AT-SCHEMA-VERSION' -ExitCode 2 -SafeMessage 'The operation envelope schema version is unsupported.'
    }
    foreach ($name in @('operation', 'working_directory', 'session_ref', 'runtime')) {
        if ($value[$name] -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$value[$name])) {
            Throw-AgentTasksError -Code 'AT-SCHEMA-TYPE' -ExitCode 2 -SafeMessage 'The operation envelope contains an invalid string property.'
        }
    }
    if ($value.request -isnot [Collections.IDictionary]) {
        Throw-AgentTasksError -Code 'AT-SCHEMA-TYPE' -ExitCode 2 -SafeMessage 'The operation request must be a JSON object.'
    }
    $shape = Get-AgentTasksRequestShape -Operation ([string]$value.operation)
    if ($null -ne $shape) {
        Assert-AgentTasksClosedObject -Value $value.request -Allowed $shape.Allowed -Required $shape.Required
    }
    return ,$value
}

function ConvertTo-AgentTasksCanonicalNode {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) { return 'null' }
    if ($Value -is [Text.Json.JsonElement]) {
        $Value = ConvertFrom-AgentTasksJsonElement -Element $Value -Depth 1
    }
    if ($Value -is [bool]) { return $(if ($Value) { 'true' } else { 'false' }) }
    if ($Value -is [string] -or $Value -is [char]) {
        return [Text.Json.JsonSerializer]::Serialize([string]$Value, [string])
    }
    if ($Value -is [DateTime]) {
        $timestamp = $Value.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [Globalization.CultureInfo]::InvariantCulture)
        return [Text.Json.JsonSerializer]::Serialize($timestamp, [string])
    }

    $integerTypes = @(
        [byte], [sbyte], [int16], [uint16], [int32], [uint32], [int64], [uint64]
    )
    foreach ($type in $integerTypes) {
        if ($Value -is $type) {
            try { $number = [decimal]$Value } catch {
                Throw-AgentTasksError -Code 'AT-JSON-NUMBER' -ExitCode 2 -SafeMessage 'The integer is outside the supported range.'
            }
            if ([Math]::Abs($number) -gt $script:AgentTasksMaximumSafeInteger) {
                Throw-AgentTasksError -Code 'AT-JSON-NUMBER' -ExitCode 2 -SafeMessage 'The integer is outside the safe-integer range.'
            }
            return $number.ToString([Globalization.CultureInfo]::InvariantCulture)
        }
    }
    if ($Value -is [single] -or $Value -is [double] -or $Value -is [decimal]) {
        Throw-AgentTasksError -Code 'AT-JSON-NUMBER' -ExitCode 2 -SafeMessage 'Only safe integers are supported in authority JSON.'
    }
    if ($Value -is [Collections.IDictionary]) {
        [string[]]$keys = @($Value.Keys | ForEach-Object { [string]$_ })
        [Array]::Sort($keys, [StringComparer]::Ordinal)
        $members = foreach ($key in $keys) {
            ([Text.Json.JsonSerializer]::Serialize($key, [string])) + ':' + (ConvertTo-AgentTasksCanonicalNode -Value $Value[$key])
        }
        return '{' + (@($members) -join ',') + '}'
    }
    if ($Value -is [pscustomobject]) {
        $dictionary = [ordered]@{}
        foreach ($property in $Value.PSObject.Properties) { $dictionary[$property.Name] = $property.Value }
        return ConvertTo-AgentTasksCanonicalNode -Value $dictionary
    }
    if ($Value -is [Collections.IEnumerable]) {
        $items = foreach ($item in $Value) { ConvertTo-AgentTasksCanonicalNode -Value $item }
        return '[' + (@($items) -join ',') + ']'
    }
    Throw-AgentTasksError -Code 'AT-SCHEMA-TYPE' -ExitCode 2 -SafeMessage 'The value cannot be represented in authority JSON.'
}

function ConvertTo-AgentTasksCanonicalJson {
    param([Parameter(Mandatory)][AllowNull()][object]$Value)
    return ConvertTo-AgentTasksCanonicalNode -Value $Value
}

function Remove-AgentTasksRecordHash {
    param([Parameter(Mandatory)][object]$Value)

    if ($Value -is [Collections.IDictionary]) {
        $copy = [ordered]@{}
        foreach ($key in $Value.Keys) {
            if ([string]$key -cne 'record_hash') { $copy[[string]$key] = $Value[$key] }
        }
        return ,$copy
    }
    if ($Value -is [pscustomobject]) {
        $copy = [ordered]@{}
        foreach ($property in $Value.PSObject.Properties) {
            if ($property.Name -cne 'record_hash') { $copy[$property.Name] = $property.Value }
        }
        return ,$copy
    }
    return $Value
}

function Get-AgentTasksSha256 {
    [CmdletBinding(DefaultParameterSetName = 'Value')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Value')][AllowNull()][object]$Value,
        [Parameter(Mandatory, ParameterSetName = 'File')][string]$LiteralPath
    )

    if ($PSCmdlet.ParameterSetName -ceq 'File') {
        try { $bytes = [IO.File]::ReadAllBytes($LiteralPath) } catch {
            Throw-AgentTasksError -Code 'AT-HASH-READ' -ExitCode 4 -SafeMessage 'The file could not be hashed.'
        }
    } else {
        $hashValue = Remove-AgentTasksRecordHash -Value $Value
        $canonical = ConvertTo-AgentTasksCanonicalJson -Value $hashValue
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($canonical)
    }
    $digest = [Security.Cryptography.SHA256]::HashData($bytes)
    return [Convert]::ToHexString($digest)
}
