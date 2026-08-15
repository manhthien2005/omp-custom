#Requires -Version 5.1

Set-StrictMode -Version 2.0

$phase00RuntimeEvidencePath = Join-Path $PSScriptRoot 'phase00-runtime-evidence.ps1'
if (-not (Test-Path -LiteralPath $phase00RuntimeEvidencePath -PathType Leaf)) {
    throw "Phase 00 runtime evidence helper not found: $phase00RuntimeEvidencePath"
}
. $phase00RuntimeEvidencePath

function Get-Phase00E1CaseDefinition {
    param(
        [Parameter(Mandatory)]
        [ValidateSet(
            'AgentJtd',
            'AgentJsonSchema',
            'CallerOnly',
            'CallerOverAgent',
            'SessionOnly',
            'ProviderStrictOffControl',
            'ProviderStrictOn'
        )]
        [string]$CaseId
    )

    $definitions = [ordered]@{
        AgentJtd = [ordered]@{
            ExecutionOrder = 1
            MatrixArtifact = 'case-1-agent-jtd'
            Source = 'agent'
            Mode = 'permissive'
            Agent = 'phase00-e1-agent-jtd'
            PromptRelativePath = Join-Path 'prompts' 'agent-jtd.md'
            PiNoStrict = $null
            ExpectedSentinelProperty = 'sentinel'
            ExpectedSentinel = 'E1_AGENT_JTD'
            ForbiddenProperty = $null
            ProhibitedValue = $null
            RequiresProvider = $true
        }
        AgentJsonSchema = [ordered]@{
            ExecutionOrder = 2
            MatrixArtifact = 'case-1-agent-json-schema'
            Source = 'agent'
            Mode = 'permissive'
            Agent = 'phase00-e1-agent-json-schema'
            PromptRelativePath = Join-Path 'prompts' 'agent-json-schema.md'
            PiNoStrict = $null
            ExpectedSentinelProperty = 'sentinel'
            ExpectedSentinel = 'E1_AGENT_JSON_SCHEMA'
            ForbiddenProperty = $null
            ProhibitedValue = $null
            RequiresProvider = $true
        }
        CallerOnly = [ordered]@{
            ExecutionOrder = 3
            MatrixArtifact = 'case-2-caller-only'
            Source = 'caller'
            Mode = 'permissive'
            Agent = 'phase00-e1-caller-only'
            PromptRelativePath = Join-Path 'prompts' 'caller-only.md'
            PiNoStrict = $null
            ExpectedSentinelProperty = 'sentinel'
            ExpectedSentinel = 'E1_CALLER_ONLY'
            ForbiddenProperty = $null
            ProhibitedValue = $null
            RequiresProvider = $true
        }
        CallerOverAgent = [ordered]@{
            ExecutionOrder = 4
            MatrixArtifact = 'case-3-caller-over-agent'
            Source = 'caller'
            Mode = 'permissive'
            Agent = 'phase00-e1-caller-over-agent'
            PromptRelativePath = Join-Path 'prompts' 'caller-over-agent.md'
            PiNoStrict = $null
            ExpectedSentinelProperty = 'caller_sentinel'
            ExpectedSentinel = 'E1_CALLER_WINS'
            ForbiddenProperty = 'agent_sentinel'
            ProhibitedValue = 'E1_AGENT_LOSES'
            RequiresProvider = $true
        }
        SessionOnly = [ordered]@{
            ExecutionOrder = 5
            MatrixArtifact = 'case-4-session-only'
            Source = 'session'
            Mode = 'permissive'
            Agent = 'phase00-e1-session-carrier'
            PromptRelativePath = Join-Path 'prompts' 'session-only.md'
            PiNoStrict = $null
            ExpectedSentinelProperty = 'session_sentinel'
            ExpectedSentinel = 'E1_SESSION_ONLY'
            ForbiddenProperty = $null
            ProhibitedValue = $null
            RequiresProvider = $true
        }
        ProviderStrictOffControl = [ordered]@{
            ExecutionOrder = 6
            MatrixArtifact = 'case-5-provider-strict'
            Source = 'caller'
            Mode = 'strict'
            Agent = 'phase00-e1-provider-strict'
            PromptRelativePath = Join-Path 'prompts' 'provider-strict.md'
            PiNoStrict = '1'
            ExpectedSentinelProperty = 'allowed'
            ExpectedSentinel = 'E1_STRICT_ALLOWED'
            ForbiddenProperty = 'forbidden_extra'
            ProhibitedValue = 'E1_STRICT_FORBIDDEN'
            RequiresProvider = $true
        }
        ProviderStrictOn = [ordered]@{
            ExecutionOrder = 7
            MatrixArtifact = 'case-5-provider-strict'
            Source = 'caller'
            Mode = 'strict'
            Agent = 'phase00-e1-provider-strict'
            PromptRelativePath = Join-Path 'prompts' 'provider-strict.md'
            PiNoStrict = $null
            ExpectedSentinelProperty = 'allowed'
            ExpectedSentinel = 'E1_STRICT_ALLOWED'
            ForbiddenProperty = 'forbidden_extra'
            ProhibitedValue = 'E1_STRICT_FORBIDDEN'
            RequiresProvider = $true
        }
    }

    return [pscustomobject]$definitions[$CaseId]
}
function New-Phase00E1Analysis {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('PASS','FAIL','BLOCKED_ENVIRONMENT','INVALID_RUN')]
        [string]$Status,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$ReasonCodes,

        [Parameter(Mandatory)]
        [AllowNull()]
        $Facts
    )

    return [pscustomobject][ordered]@{
        Status = $Status
        ReasonCodes = @($ReasonCodes)
        Facts = $Facts
    }
}

function Assert-Phase00E1DisposableDescendant {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$TempRoot
    )

    $trimCharacters = [char[]]@('\','/')
    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd($trimCharacters)
    $fullTempRoot = [IO.Path]::GetFullPath($TempRoot).TrimEnd($trimCharacters)
    $requiredPrefix = $fullTempRoot + [IO.Path]::DirectorySeparatorChar

    if (
        $fullPath.Length -le $fullTempRoot.Length -or
        -not $fullPath.StartsWith($requiredPrefix, [StringComparison]::OrdinalIgnoreCase)
    ) {
        throw "E1 disposable path is not a strict temp descendant: $fullPath"
    }

    return $fullPath
}

function Test-Phase00E1OmpIdentity {
    param(
        [Parameter(Mandatory)]
        [string]$Sha256,

        [Parameter(Mandatory)]
        [string]$Version
    )

    $expectedSha256 = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
    return (
        $Sha256.ToUpperInvariant() -eq $expectedSha256 -and
        $Version.Trim() -eq 'omp/17.2.10'
    )
}

function Get-Phase00E1FileSha256 {
    param([Parameter(Mandatory)][string]$Path)

    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function Get-Phase00E1StringSha256 {
    param([AllowEmptyString()][string]$Text)

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
        return [BitConverter]::ToString($sha256.ComputeHash($bytes)).Replace('-','')
    } finally {
        $sha256.Dispose()
    }
}

function Get-Phase00E1PathReplacements {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$DisposableRoot,
        [string[]]$LiveHomePaths = @()
    )

    $entries = @(
        [pscustomobject]@{ Path=[IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\','/'); Marker='<E1_REPOSITORY_ROOT>' },
        [pscustomobject]@{ Path=[IO.Path]::GetFullPath($DisposableRoot).TrimEnd('\','/'); Marker='<E1_DISPOSABLE_ROOT>' }
    )
    for ($index = 0; $index -lt @($LiveHomePaths).Count; $index += 1) {
        $entries += [pscustomobject]@{
            Path = [IO.Path]::GetFullPath($LiveHomePaths[$index]).TrimEnd('\','/')
            Marker = "<E1_LIVE_HOME_$($index + 1)>"
        }
    }

    $expanded = foreach ($entry in $entries) {
        $variants = @(
            $entry.Path,
            $entry.Path.Replace('\','/'),
            $entry.Path.Replace('/','\')
        ) | Sort-Object -Unique
        foreach ($variant in $variants) {
            if (-not [string]::IsNullOrWhiteSpace($variant)) {
                [pscustomobject]@{ Path=$variant; Marker=$entry.Marker }
            }
        }
    }
    return @($expanded | Sort-Object { $_.Path.Length } -Descending)
}

function Protect-Phase00E1Text {
    param(
        [AllowEmptyString()][string]$Text,
        [AllowEmptyString()][string]$PropertyName,
        [Parameter(Mandatory)][hashtable]$Context
    )

    $credentialNames = '(OPENAI_API_KEY|ANTHROPIC_API_KEY|ANTHROPIC_OAUTH_TOKEN|GEMINI_API_KEY|OMNIROUTE_API_KEY)'
    $credentialValuePattern = "(?i)($credentialNames|api[-_ ]?key)\s*[:=]\s*\S{8,}|Authorization\s*:\s*Bearer\s+\S+"
    if ($Text -match $credentialValuePattern) {
        if ($Context.ContainsKey('CredentialLines') -and $Context.ContainsKey('CurrentSourceLine')) {
            $lineNumber = [int]$Context.CurrentSourceLine
            if (-not $Context.CredentialLines.Contains($lineNumber)) {
                $Context.CredentialLines.Add($lineNumber)
            }
        }
        return New-Phase00E1RedactionMarker -Kind 'credential_shaped_text' -Field $PropertyName.ToLowerInvariant()
    }

    $protected = [regex]::Replace(
        $Text,
        "(?i)$credentialNames",
        '<E1_CREDENTIAL_VARIABLE>'
    )
    foreach ($replacement in @($Context.PathReplacements)) {
        $protected = [regex]::Replace(
            $protected,
            [regex]::Escape([string]$replacement.Path),
            [string]$replacement.Marker,
            [Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
    }
    return $protected
}

function New-Phase00E1RedactionMarker {
    param(
        [Parameter(Mandatory)][string]$Kind,
        [Parameter(Mandatory)][string]$Field
    )

    return [ordered]@{ redacted=$Kind; field=$Field }
}

function Get-Phase00E1ToolErrorClassification {
    param([AllowNull()]$Message)

    if ($null -eq $Message -or
        [string](Get-Phase00E1PropertyValue -Object $Message -Name 'role') -cne 'toolResult' -or
        [string](Get-Phase00E1PropertyValue -Object $Message -Name 'toolName') -cne 'yield' -or
        (Get-Phase00E1PropertyValue -Object $Message -Name 'isError') -ne $true) {
        return $null
    }
    $textParts = [Collections.Generic.List[string]]::new()
    foreach ($item in @(Get-Phase00E1PropertyValue -Object $Message -Name 'content')) {
        if ($null -eq $item) { continue }
        $text = Get-Phase00E1PropertyValue -Object $item -Name 'text'
        if ($text -is [string]) { $textParts.Add($text) }
    }
    $joined = $textParts -join "`n"
    if ($joined -match '(?i)(?:^|\b)Output does not match schema:') {
        return 'yield_schema_validation'
    }
    return 'other_yield_tool_error'
}

function Protect-Phase00E1MessageContent {
    param(
        [AllowNull()]$Value,
        [Parameter(Mandatory)][hashtable]$Context
    )

    if ($null -eq $Value) {
        return $null
    }
    if ($Value -is [string]) {
        return New-Phase00E1RedactionMarker -Kind 'private_message_content' -Field 'content'
    }

    $protectedItems = foreach ($item in @($Value)) {
        if ($null -eq $item -or -not ($item -is [pscustomobject] -or $item -is [Collections.IDictionary])) {
            New-Phase00E1RedactionMarker -Kind 'private_message_content' -Field 'content'
            continue
        }

        $type = if ($item -is [Collections.IDictionary]) {
            [string]$item['type']
        } else {
            [string]$item.type
        }
        if ($type -eq 'toolCall') {
            Protect-Phase00E1Value -Value $item -PropertyName 'content_item' -Context $Context
            continue
        }

        $copy = [ordered]@{}
        $properties = if ($item -is [Collections.IDictionary]) {
            @($item.Keys | ForEach-Object {
                [pscustomobject]@{ Name=[string]$_; Value=$item[$_] }
            })
        } else {
            @($item.PSObject.Properties)
        }
        foreach ($property in $properties) {
            $propertyKey = $property.Name.ToLowerInvariant()
            if ($propertyKey -in @('thinking','reasoning')) {
                $copy[$property.Name] = New-Phase00E1RedactionMarker -Kind 'private_reasoning' -Field $propertyKey
            } elseif ($propertyKey -in @('text','content')) {
                $copy[$property.Name] = New-Phase00E1RedactionMarker -Kind 'private_message_content' -Field $propertyKey
            } else {
                $copy[$property.Name] = Protect-Phase00E1Value -Value $property.Value -PropertyName $property.Name -Context $Context
            }
        }
        $copy
    }
    return ,@($protectedItems)
}

function Protect-Phase00E1Value {
    param(
        [AllowNull()]$Value,
        [AllowEmptyString()][string]$PropertyName,
        [Parameter(Mandatory)][hashtable]$Context
    )

    $secretKeys = @(
        'authorization',
        'apikey',
        'api_key',
        'cookie',
        'set-cookie',
        'thinkingsignature',
        'encrypted_content'
    )
    $reasoningKeys = @('thinking','reasoning','private_reasoning')
    $privateKeys = @('system_prompt','systemprompt','input','displaycontent','display_content')
    $key = ([string]$PropertyName).ToLowerInvariant()

    if ($key -in $secretKeys) {
        return New-Phase00E1RedactionMarker -Kind 'secret' -Field $key
    }
    if ($key -in $reasoningKeys) {
        return New-Phase00E1RedactionMarker -Kind 'private_reasoning' -Field $key
    }
    if ($key -in $privateKeys) {
        return New-Phase00E1RedactionMarker -Kind 'private_content' -Field $key
    }
    if ($null -eq $Value) {
        return $null
    }
    if ($Value -is [string]) {
        return Protect-Phase00E1Text -Text $Value -PropertyName $PropertyName -Context $Context
    }
    if ($Value -is [ValueType]) { return $Value }
    if ($Value -is [Collections.IDictionary]) {
        $caseCollisionMarker = Get-Phase00E1CaseCollidingJsonMarker -Value $Value
        if ($null -ne $caseCollisionMarker) { return $caseCollisionMarker }
        $copy = New-Object System.Collections.Specialized.OrderedDictionary `
            ([StringComparer]::Ordinal)
        foreach ($entryKey in $Value.Keys) {
            if ($key -eq 'truncation' -and [string]$entryKey -ieq 'content') {
                $copy.Add([string]$entryKey, (New-Phase00E1RedactionMarker `
                    -Kind 'private_content' -Field 'truncation.content'))
            } else {
                $copy.Add([string]$entryKey, (Protect-Phase00E1Value `
                    -Value $Value[$entryKey] `
                    -PropertyName ([string]$entryKey) `
                    -Context $Context))
            }
        }
        return $copy
    }
    if ($Value -is [pscustomobject]) {
        $copy = [ordered]@{}
        $propertyNames = @($Value.PSObject.Properties | ForEach-Object { $_.Name })
        $isMessage = $propertyNames -contains 'role' -and $propertyNames -contains 'content'
        $objectType = if ($propertyNames -contains 'type') { [string]$Value.type } else { '' }
        $toolErrorClassification = if ($isMessage) {
            Get-Phase00E1ToolErrorClassification -Message $Value
        } else { $null }
        foreach ($property in $Value.PSObject.Properties) {
            if ($key -eq 'truncation' -and $property.Name -ieq 'content') {
                $copy[$property.Name] = New-Phase00E1RedactionMarker `
                    -Kind 'private_content' -Field 'truncation.content'
            } elseif ($objectType -ceq 'session_init' -and
                $property.Name -in @('systemPrompt','system_prompt','task')) {
                $copy[$property.Name] = New-Phase00E1RedactionMarker `
                    -Kind 'private_content' -Field $property.Name.ToLowerInvariant()
            } elseif ($isMessage -and $property.Name -eq 'content') {
                $copy[$property.Name] = Protect-Phase00E1MessageContent -Value $property.Value -Context $Context
            } elseif ($objectType -match '^thinking' -and $property.Name -eq 'content') {
                $copy[$property.Name] = New-Phase00E1RedactionMarker -Kind 'private_reasoning' -Field 'content'
            } else {
                $copy[$property.Name] = Protect-Phase00E1Value `
                    -Value $property.Value `
                    -PropertyName $property.Name `
                    -Context $Context
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($toolErrorClassification)) {
            $copy['e1_tool_error_classification'] = $toolErrorClassification
        }
        return $copy
    }
    if ($Value -is [Collections.IEnumerable]) {
        $items = @(
            $Value | ForEach-Object {
                Protect-Phase00E1Value -Value $_ -PropertyName $PropertyName -Context $Context
            }
        )
        return ,$items
    }
    return $Value
}

function Get-Phase00E1JsonValueKind {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$JsonText)

    $trimmed = $JsonText.TrimStart()
    if ($trimmed.Length -eq 0) { return 'empty' }
    switch ($trimmed[0]) {
        '{' { return 'object' }
        '[' { return 'array' }
        '"' { return 'string' }
        'n' { return 'null' }
        't' { return 'boolean' }
        'f' { return 'boolean' }
        default { return 'number' }
    }
}

function ConvertFrom-Phase00E1JsonText {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$JsonText)

    try {
        return ($JsonText | ConvertFrom-Json -ErrorAction Stop)
    } catch {
        # PowerShell's object projection rejects valid JSON objects whose keys
        # differ only by case. Fall through to a case-sensitive parser so the
        # sanitizer can replace only the ambiguous object with a typed marker.
    }

    $convertFromJson = Get-Command ConvertFrom-Json -CommandType Cmdlet -ErrorAction Stop
    if ($convertFromJson.Parameters.ContainsKey('AsHashtable')) {
        $value = ConvertFrom-Json -InputObject $JsonText -AsHashtable -Depth 100 `
            -ErrorAction Stop
        $safeValue = ConvertTo-Phase00E1CaseCollisionSafeValue -Value $value
        return $safeValue
    }

    if ($null -eq ('System.Web.Script.Serialization.JavaScriptSerializer' -as [type])) {
        Add-Type -AssemblyName System.Web.Extensions -ErrorAction Stop
    }
    $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $serializer.MaxJsonLength = [int]::MaxValue
    $serializer.RecursionLimit = 1024
    $value = $serializer.DeserializeObject($JsonText)
    $safeValue = ConvertTo-Phase00E1CaseCollisionSafeValue -Value $value
    return $safeValue
}

function Get-Phase00E1CaseCollidingJsonMarker {
    param([Parameter(Mandatory)][Collections.IDictionary]$Value)

    $keys = [string[]]@($Value.Keys | ForEach-Object { [string]$_ })
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' `
        ([StringComparer]::OrdinalIgnoreCase)
    $collisionGroupCount = 0
    foreach ($key in $keys) {
        if (-not $seen.Add($key)) { continue }
        $matchingCount = @($keys | Where-Object {
            [string]::Equals($_, $key, [StringComparison]::OrdinalIgnoreCase)
        }).Count
        if ($matchingCount -gt 1) { $collisionGroupCount += 1 }
    }
    if ($collisionGroupCount -eq 0) { return $null }

    [Array]::Sort($keys, [StringComparer]::Ordinal)
    return [ordered]@{
        type = 'phase00_e1_redaction'
        redacted = 'case_colliding_json_object'
        key_count = $keys.Count
        collision_group_count = $collisionGroupCount
        key_set_sha256 = Get-Phase00E1StringSha256 -Text ($keys -join "`n")
    }
}

function ConvertTo-Phase00E1CaseCollisionSafeValue {
    param([AllowNull()]$Value)

    if ($null -eq $Value -or $Value -is [string]) { return $Value }
    if ($Value -is [Collections.IDictionary]) {
        $marker = Get-Phase00E1CaseCollidingJsonMarker -Value $Value
        if ($null -ne $marker) { return [pscustomobject]$marker }
        $copy = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $copy[[string]$key] = ConvertTo-Phase00E1CaseCollisionSafeValue `
                -Value $Value[$key]
        }
        return [pscustomobject]$copy
    }
    if ($Value -is [Collections.IEnumerable]) {
        $items = @($Value | ForEach-Object {
            ConvertTo-Phase00E1CaseCollisionSafeValue -Value $_
        })
        return ,$items
    }
    return $Value
}

function Protect-Phase00E1EventStream {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$DestinationPath,
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$DisposableRoot,
        [Parameter(Mandatory)][Collections.IDictionary]$FixtureHashes,
        [string[]]$LiveHomePaths = @()
    )

    $resolvedSourcePath = [IO.Path]::GetFullPath($SourcePath)
    $resolvedDestinationPath = [IO.Path]::GetFullPath($DestinationPath)
    if ($resolvedSourcePath.Equals($resolvedDestinationPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'E1 sanitization source and destination must differ.'
    }
    if (Test-Path -LiteralPath $resolvedDestinationPath) {
        throw "E1 sanitization destination already exists: $resolvedDestinationPath"
    }

    $sourceCaptureSha256 = Get-Phase00E1FileSha256 -Path $resolvedSourcePath
    $context = @{
        PathReplacements = @(
            Get-Phase00E1PathReplacements `
                -RepositoryRoot $RepositoryRoot `
                -DisposableRoot $DisposableRoot `
                -LiveHomePaths $LiveHomePaths
        )
    }
    $encoding = [Text.UTF8Encoding]::new($false)
    $writer = [IO.StreamWriter]::new($resolvedDestinationPath, $false, $encoding)
    $enumerator = $null
    $sourceLineCount = 0
    $sanitizedLineCount = 0
    $malformedLines = [Collections.Generic.List[int]]::new()
    $invalidShapeLines = [Collections.Generic.List[int]]::new()
    $processingErrorLines = [Collections.Generic.List[int]]::new()
    $credentialLines = [Collections.Generic.List[int]]::new()
    $context.CredentialLines = $credentialLines

    try {
        $enumerator = [IO.File]::ReadLines($resolvedSourcePath).GetEnumerator()
        while ($enumerator.MoveNext()) {
            $line = [string]$enumerator.Current
            $sourceLineCount += 1
            $context.CurrentSourceLine = $sourceLineCount
            $parsed = $null
            $parseSucceeded = $false
            try {
                $parsed = ConvertFrom-Phase00E1JsonText -JsonText $line
                $parseSucceeded = $true
            } catch {
                $malformedLines.Add($sourceLineCount)
                $sanitized = [ordered]@{
                    type = 'phase00_e1_redaction'
                    redacted = 'invalid_json_line'
                    source_line = $sourceLineCount
                    source_line_sha256 = Get-Phase00E1StringSha256 -Text $line
                }
            }
            if ($parseSucceeded) {
                $jsonKind = Get-Phase00E1JsonValueKind -JsonText $line
                if ($jsonKind -ne 'object') {
                    $invalidShapeLines.Add($sourceLineCount)
                    $sanitized = [ordered]@{
                        type = 'phase00_e1_redaction'
                        redacted = 'invalid_json_shape'
                        observed_kind = $jsonKind
                        source_line = $sourceLineCount
                        source_line_sha256 = Get-Phase00E1StringSha256 -Text $line
                    }
                } else {
                    try {
                        $sanitized = Protect-Phase00E1Value `
                            -Value $parsed -PropertyName '' -Context $context
                    } catch {
                        $processingErrorLines.Add($sourceLineCount)
                        $sanitized = [ordered]@{
                            type = 'phase00_e1_redaction'
                            redacted = 'sanitizer_processing_error'
                            error_type = $_.Exception.GetType().FullName
                            source_line = $sourceLineCount
                            source_line_sha256 = Get-Phase00E1StringSha256 -Text $line
                        }
                    }
                }
            }
            $writer.WriteLine(($sanitized | ConvertTo-Json -Compress -Depth 100))
            $sanitizedLineCount += 1
        }
    } finally {
        if ($null -ne $enumerator) {
            $enumerator.Dispose()
        }
        $writer.Dispose()
    }

    $reasonCodes = [Collections.Generic.List[string]]::new()
    if ($malformedLines.Count -gt 0) {
        $reasonCodes.Add('E1_SANITIZER_UNPARSEABLE_LINE')
    }
    if ($invalidShapeLines.Count -gt 0) {
        $reasonCodes.Add('E1_SANITIZER_NON_OBJECT_LINE')
    }
    if ($processingErrorLines.Count -gt 0) {
        $reasonCodes.Add('E1_SANITIZER_PROCESSING_ERROR')
    }
    if ($credentialLines.Count -gt 0) {
        $reasonCodes.Add('E1_SANITIZER_CREDENTIAL_SHAPED_TEXT')
    }
    $status = if ($reasonCodes.Count -eq 0) { 'PASS' } else { 'INVALID_RUN' }
    return [pscustomobject][ordered]@{
        Status = $status
        ReasonCodes = [string[]]@($reasonCodes)
        SourceCaptureSha256 = $sourceCaptureSha256
        SanitizedOutputSha256 = Get-Phase00E1FileSha256 -Path $resolvedDestinationPath
        SourceLineCount = $sourceLineCount
        SanitizedLineCount = $sanitizedLineCount
        MalformedLines = @($malformedLines)
        InvalidShapeLines = @($invalidShapeLines)
        ProcessingErrorLines = @($processingErrorLines)
        CredentialLines = @($credentialLines)
        FixtureHashes = $FixtureHashes
    }
}
function Get-Phase00E1PropertyValue {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $Object) { return $null }
    if ($Object -is [Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-Phase00E1HasProperty {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $Object) { return $false }
    if ($Object -is [Collections.IDictionary]) { return $Object.Contains($Name) }
    return $null -ne $Object.PSObject.Properties[$Name]
}

function Find-Phase00E1StructuredResultCandidates {
    param(
        [AllowNull()]$Value,
        [Parameter(Mandatory)][AllowEmptyCollection()][Collections.Generic.List[object]]$Candidates
    )

    if ($null -eq $Value -or $Value -is [string]) { return }

    $isObject = $Value -is [Collections.IDictionary] -or $Value -is [pscustomobject]
    if (
        $isObject -and
        (Test-Phase00E1HasProperty -Object $Value -Name 'id') -and
        (Test-Phase00E1HasProperty -Object $Value -Name 'agent') -and
        (Test-Phase00E1HasProperty -Object $Value -Name 'structuredOutput')
    ) {
        $Candidates.Add($Value)
        return
    }

    if ($Value -is [Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            Find-Phase00E1StructuredResultCandidates -Value $Value[$key] -Candidates $Candidates
        }
        return
    }
    if ($Value -is [pscustomobject]) {
        foreach ($property in $Value.PSObject.Properties) {
            Find-Phase00E1StructuredResultCandidates -Value $property.Value -Candidates $Candidates
        }
        return
    }
    if ($Value -is [Collections.IEnumerable]) {
        foreach ($item in $Value) {
            Find-Phase00E1StructuredResultCandidates -Value $item -Candidates $Candidates
        }
    }
}

function Get-Phase00E1StructuredResults {
    param([Parameter(Mandatory)][string[]]$EventPaths)

    $results = [Collections.Generic.List[object]]::new()
    $seen = @{}
    foreach ($eventPath in $EventPaths) {
        $resolvedPath = [IO.Path]::GetFullPath($eventPath)
        if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
            throw "E1 event artifact not found: $resolvedPath"
        }

        $enumerator = $null
        $lineNumber = 0
        try {
            $enumerator = [IO.File]::ReadLines($resolvedPath).GetEnumerator()
            while ($enumerator.MoveNext()) {
                $lineNumber += 1
                $line = [string]$enumerator.Current
                try {
                    $event = $line | ConvertFrom-Json -ErrorAction Stop
                } catch {
                    throw "Malformed E1 JSONL at line $lineNumber in '$resolvedPath': $($_.Exception.Message)"
                }

                $candidates = [Collections.Generic.List[object]]::new()
                Find-Phase00E1StructuredResultCandidates -Value $event -Candidates $candidates
                foreach ($candidate in $candidates) {
                    $id = [string](Get-Phase00E1PropertyValue -Object $candidate -Name 'id')
                    $agent = [string](Get-Phase00E1PropertyValue -Object $candidate -Name 'agent')
                    if ([string]::IsNullOrWhiteSpace($id) -or [string]::IsNullOrWhiteSpace($agent)) {
                        continue
                    }
                    $identity = "$resolvedPath|$id|$agent"
                    if ($seen.ContainsKey($identity)) { continue }
                    $seen[$identity] = $true
                    $results.Add([pscustomobject][ordered]@{
                        Id = $id
                        Agent = $agent
                        StructuredOutput = Get-Phase00E1PropertyValue -Object $candidate -Name 'structuredOutput'
                        OriginPath = $resolvedPath
                        LineNumber = $lineNumber
                        RawResult = $candidate
                    })
                }
            }
        } finally {
            if ($null -ne $enumerator) { $enumerator.Dispose() }
        }
    }
    return @($results)
}

function Get-Phase00E1CanonicalTaskArguments {
    param([Parameter(Mandatory)]$Arguments)

    if ($Arguments -is [Collections.IDictionary]) {
        $propertyNames = @($Arguments.Keys | ForEach-Object { [string]$_ } | Sort-Object)
    } elseif ($Arguments -is [pscustomobject]) {
        $propertyNames = @($Arguments.PSObject.Properties.Name | Sort-Object)
    } else {
        throw 'E1 task arguments must be a JSON object.'
    }

    $canonical = [ordered]@{}
    foreach ($propertyName in $propertyNames) {
        if ($propertyName -ceq 'i') { continue }
        $canonical[$propertyName] = Get-Phase00E1PropertyValue -Object $Arguments -Name $propertyName
    }

    $hasOutputSchema = Test-Phase00E1HasProperty -Object $canonical -Name 'outputSchema'
    return [pscustomobject][ordered]@{
        Arguments = [pscustomobject]$canonical
        Names = [string[]]@($canonical.Keys)
        HasOutputSchema = $hasOutputSchema
        OutputSchema = if ($hasOutputSchema) { $canonical['outputSchema'] } else { $null }
    }
}

function Get-Phase00E1TaskCalls {
    param([Parameter(Mandatory)][string[]]$EventPaths)

    $calls = [Collections.Generic.List[object]]::new()
    foreach ($eventPath in $EventPaths) {
        $resolvedPath = [IO.Path]::GetFullPath($eventPath)
        if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
            throw "E1 event artifact not found: $resolvedPath"
        }

        $enumerator = $null
        $lineNumber = 0
        try {
            $enumerator = [IO.File]::ReadLines($resolvedPath).GetEnumerator()
            while ($enumerator.MoveNext()) {
                $lineNumber += 1
                $line = [string]$enumerator.Current
                try {
                    $event = $line | ConvertFrom-Json -ErrorAction Stop
                } catch {
                    throw "Malformed E1 JSONL at line $lineNumber in '$resolvedPath': $($_.Exception.Message)"
                }

                if (
                    [string](Get-Phase00E1PropertyValue -Object $event -Name 'type') -cne 'tool_execution_start' -or
                    [string](Get-Phase00E1PropertyValue -Object $event -Name 'toolName') -cne 'task'
                ) {
                    continue
                }

                $toolCallId = [string](Get-Phase00E1PropertyValue -Object $event -Name 'toolCallId')
                if ([string]::IsNullOrWhiteSpace($toolCallId)) {
                    throw "E1 task start lacks toolCallId at line $lineNumber in '$resolvedPath'."
                }
                $arguments = Get-Phase00E1PropertyValue -Object $event -Name 'args'
                $canonical = Get-Phase00E1CanonicalTaskArguments -Arguments $arguments
                $agent = [string](Get-Phase00E1PropertyValue -Object $canonical.Arguments -Name 'agent')
                if ([string]::IsNullOrWhiteSpace($agent)) {
                    throw "E1 task start lacks agent at line $lineNumber in '$resolvedPath'."
                }

                $calls.Add([pscustomobject][ordered]@{
                    ToolCallId = $toolCallId
                    Agent = $agent
                    CanonicalArguments = $canonical.Arguments
                    ArgumentNames = [string[]]@($canonical.Names)
                    HasOutputSchema = $canonical.HasOutputSchema
                    OutputSchema = $canonical.OutputSchema
                    OriginPath = $resolvedPath
                    LineNumber = $lineNumber
                    RawEvent = $event
                })
            }
        } finally {
            if ($null -ne $enumerator) { $enumerator.Dispose() }
        }
    }
    return @($calls)
}

function Get-Phase00E1ProviderLedger {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Events
    )

    $requestEventIndexes = [Collections.Generic.List[int]]::new()
    $responseEndEventIndexes = [Collections.Generic.List[int]]::new()
    $retryStartEventIndexes = [Collections.Generic.List[int]]::new()
    $retryEndEventIndexes = [Collections.Generic.List[int]]::new()
    $retryExhaustedEvents = [Collections.Generic.List[object]]::new()
    $providerModelsByKey = @{}
    $unattributedRequestCount = 0

    for ($index = 0; $index -lt $Events.Count; $index++) {
        $event = $Events[$index]
        $type = [string](Get-Phase00E1PropertyValue -Object $event -Name 'type')
        $message = Get-Phase00E1PropertyValue -Object $event -Name 'message'
        $isAssistantMessage = (
            $null -ne $message -and
            [string](Get-Phase00E1PropertyValue -Object $message -Name 'role') -ceq 'assistant'
        )

        if ($type -ceq 'message_start' -and $isAssistantMessage) {
            $requestEventIndexes.Add($index)
            $provider = [string](Get-Phase00E1PropertyValue -Object $message -Name 'provider')
            $model = [string](Get-Phase00E1PropertyValue -Object $message -Name 'model')
            if ([string]::IsNullOrWhiteSpace($provider) -or [string]::IsNullOrWhiteSpace($model)) {
                $unattributedRequestCount += 1
            }
        } elseif ($type -ceq 'message_end' -and $isAssistantMessage) {
            $responseEndEventIndexes.Add($index)
        }

        if ($isAssistantMessage) {
            $provider = [string](Get-Phase00E1PropertyValue -Object $message -Name 'provider')
            $model = [string](Get-Phase00E1PropertyValue -Object $message -Name 'model')
            if (-not [string]::IsNullOrWhiteSpace($provider) -and
                -not [string]::IsNullOrWhiteSpace($model)) {
                $providerModelsByKey["$provider`n$model"] = [pscustomobject][ordered]@{
                    Provider = $provider
                    Model = $model
                }
            }
        }

        if ($type -ceq 'agent_end') {
            foreach ($terminalMessage in @(Get-Phase00E1PropertyValue -Object $event -Name 'messages')) {
                if ([string](Get-Phase00E1PropertyValue -Object $terminalMessage -Name 'role') -cne 'assistant') {
                    continue
                }
                $provider = [string](Get-Phase00E1PropertyValue -Object $terminalMessage -Name 'provider')
                $model = [string](Get-Phase00E1PropertyValue -Object $terminalMessage -Name 'model')
                if (-not [string]::IsNullOrWhiteSpace($provider) -and
                    -not [string]::IsNullOrWhiteSpace($model)) {
                    $providerModelsByKey["$provider`n$model"] = [pscustomobject][ordered]@{
                        Provider = $provider
                        Model = $model
                    }
                }
            }
        }

        if ($type -ceq 'auto_retry_start') {
            $retryStartEventIndexes.Add($index)
        } elseif ($type -ceq 'auto_retry_end') {
            $retryEndEventIndexes.Add($index)
            if ((Get-Phase00E1PropertyValue -Object $event -Name 'success') -eq $false) {
                $retryExhaustedEvents.Add([pscustomobject][ordered]@{
                    EventIndex = $index
                    Attempt = [int](Get-Phase00E1PropertyValue -Object $event -Name 'attempt')
                    FinalError = [string](Get-Phase00E1PropertyValue -Object $event -Name 'finalError')
                })
            }
        }
    }

    $providerModels = @($providerModelsByKey.Values | Sort-Object Provider, Model)
    $providers = @($providerModels.Provider | Sort-Object -Unique)
    $models = @($providerModels.Model | Sort-Object -Unique)
    $recoveredRetries = @(Get-Phase00ParentRecoveredProviderRetries -Events $Events)
    $authoritativeOutcome = Get-Phase00AuthoritativeAssistantOutcome -Events $Events
    $terminalFailure = Get-Phase00TerminalModelFailure -Events $Events

    return [pscustomobject][ordered]@{
        RequestCount = $requestEventIndexes.Count
        AttributedRequestCount = $requestEventIndexes.Count - $unattributedRequestCount
        UnattributedRequestCount = $unattributedRequestCount
        RequestEventIndexes = [int[]]@($requestEventIndexes)
        ResponseEndCount = $responseEndEventIndexes.Count
        ResponseEndEventIndexes = [int[]]@($responseEndEventIndexes)
        RetryStartCount = $retryStartEventIndexes.Count
        RetryStartEventIndexes = [int[]]@($retryStartEventIndexes)
        RetryEndCount = $retryEndEventIndexes.Count
        RetryEndEventIndexes = [int[]]@($retryEndEventIndexes)
        RecoveredRetryCount = $recoveredRetries.Count
        RecoveredRetries = @($recoveredRetries)
        RetryExhausted = $retryExhaustedEvents.Count -gt 0
        RetryExhaustedCount = $retryExhaustedEvents.Count
        RetryExhaustedEvents = @($retryExhaustedEvents)
        Provider = if ($providers.Count -eq 1) { $providers[0] } else { $null }
        Model = if ($models.Count -eq 1) { $models[0] } else { $null }
        ProviderModels = @($providerModels)
        AuthoritativeOutcome = $authoritativeOutcome
        TerminalFailure = $terminalFailure
    }
}

function Test-Phase00E1Sha256Text {
    param([AllowNull()]$Value)

    return [string]$Value -cmatch '^[0-9A-F]{64}$'
}

function Test-Phase00E1CommonAttempt {
    param(
        [Parameter(Mandatory)]$Definition,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$AttributableResults,
        [Parameter(Mandatory)]$ProviderLedger,
        [Parameter(Mandatory)]$RunRecord
    )

    $resultList = @($AttributableResults)
    $attributableResult = if ($resultList.Count -eq 1) { $resultList[0] } else { $null }
    $facts = [ordered]@{
        Definition = $Definition
        AttributableResult = $attributableResult
        ProviderLedger = $ProviderLedger
        RunRecord = $RunRecord
    }
    $invalidReasons = [Collections.Generic.List[string]]::new()

    $requiredRunProperties = @(
        'PinnedSourceCommit','RuntimeSha256','RuntimeVersion','ExitCode','TimedOut',
        'SanitizerStatus','RawArtifacts','RequiredEventAnchors','CleanupSucceeded',
        'RemainingChildPids','ProtectedSurfacesUnchanged'
    )
    if (@($requiredRunProperties | Where-Object {
        -not (Test-Phase00E1HasProperty -Object $RunRecord -Name $_)
    }).Count -gt 0) {
        $invalidReasons.Add('E1_RUN_RECORD_INCOMPLETE')
    }

    $sourceCommit = [string](Get-Phase00E1PropertyValue -Object $RunRecord -Name 'PinnedSourceCommit')
    if ($sourceCommit -cne '3a8591a8af5b6d200088d12ca75a5517cb064fa8') {
        $invalidReasons.Add('E1_SOURCE_PIN_MISMATCH')
    }
    $runtimeSha256 = [string](Get-Phase00E1PropertyValue -Object $RunRecord -Name 'RuntimeSha256')
    $runtimeVersion = [string](Get-Phase00E1PropertyValue -Object $RunRecord -Name 'RuntimeVersion')
    if ([string]::IsNullOrWhiteSpace($runtimeSha256) -or
        [string]::IsNullOrWhiteSpace($runtimeVersion) -or
        -not (Test-Phase00E1OmpIdentity -Sha256 $runtimeSha256 -Version $runtimeVersion)) {
        $invalidReasons.Add('E1_RUNTIME_IDENTITY_MISMATCH')
    }
    if ([string](Get-Phase00E1PropertyValue -Object $RunRecord -Name 'SanitizerStatus') -cne 'PASS') {
        $invalidReasons.Add('E1_SANITIZER_INVALID')
    }
    if ($resultList.Count -ne 1) {
        $invalidReasons.Add('E1_ATTRIBUTABLE_RESULT_COUNT')
    }

    $requiredLedgerProperties = @(
        'RequestCount','AttributedRequestCount','UnattributedRequestCount',
        'Provider','Model','RetryExhausted','RecoveredRetryCount','TerminalFailure'
    )
    if (@($requiredLedgerProperties | Where-Object {
        -not (Test-Phase00E1HasProperty -Object $ProviderLedger -Name $_)
    }).Count -gt 0) {
        $invalidReasons.Add('E1_PROVIDER_LEDGER_INCOMPLETE')
    } else {
        $requestCount = [int](Get-Phase00E1PropertyValue -Object $ProviderLedger -Name 'RequestCount')
        $attributedRequestCount = [int](Get-Phase00E1PropertyValue -Object $ProviderLedger -Name 'AttributedRequestCount')
        $unattributedRequestCount = [int](Get-Phase00E1PropertyValue -Object $ProviderLedger -Name 'UnattributedRequestCount')
        if ($requestCount -le 0) {
            $invalidReasons.Add('E1_PROVIDER_REQUEST_ABSENT')
        } elseif ($attributedRequestCount -ne $requestCount -or $unattributedRequestCount -ne 0) {
            $invalidReasons.Add('E1_PROVIDER_REQUEST_UNATTRIBUTED')
        }
        if (
            [string](Get-Phase00E1PropertyValue -Object $ProviderLedger -Name 'Provider') -cne 'omniroute' -or
            [string](Get-Phase00E1PropertyValue -Object $ProviderLedger -Name 'Model') -cne 'codex/gpt-5.6-sol-high'
        ) {
            $invalidReasons.Add('E1_PROVIDER_BOUNDARY_MISMATCH')
        }
    }

    if ((Get-Phase00E1PropertyValue -Object $RunRecord -Name 'TimedOut') -ne $false) {
        $invalidReasons.Add('E1_PROCESS_TIMEOUT')
    }

    $rawArtifacts = @(Get-Phase00E1PropertyValue -Object $RunRecord -Name 'RawArtifacts')
    $rawPaths = @{}
    if ($rawArtifacts.Count -eq 0) {
        $invalidReasons.Add('E1_RAW_ARTIFACT_MISSING')
    } else {
        $rawPathInvalid = $false
        $rawHashInvalid = $false
        foreach ($artifact in $rawArtifacts) {
            $rawPath = [string](Get-Phase00E1PropertyValue -Object $artifact -Name 'Path')
            if ([string]::IsNullOrWhiteSpace($rawPath)) {
                $rawPathInvalid = $true
            } else {
                $rawPaths[$rawPath] = $true
            }
            if (-not (Test-Phase00E1Sha256Text `
                -Value (Get-Phase00E1PropertyValue -Object $artifact -Name 'Sha256'))) {
                $rawHashInvalid = $true
            }
        }
        if ($rawPathInvalid) { $invalidReasons.Add('E1_RAW_ARTIFACT_MISSING') }
        if ($rawHashInvalid) { $invalidReasons.Add('E1_RAW_HASH_MISSING') }
    }

    $anchors = @(Get-Phase00E1PropertyValue -Object $RunRecord -Name 'RequiredEventAnchors')
    $anchorInvalid = $anchors.Count -eq 0
    foreach ($anchor in $anchors) {
        $anchorPath = [string](Get-Phase00E1PropertyValue -Object $anchor -Name 'Path')
        $anchorLine = [int](Get-Phase00E1PropertyValue -Object $anchor -Name 'Line')
        $anchorType = [string](Get-Phase00E1PropertyValue -Object $anchor -Name 'Type')
        if (
            [string]::IsNullOrWhiteSpace($anchorPath) -or
            -not $rawPaths.ContainsKey($anchorPath) -or
            $anchorLine -le 0 -or
            [string]::IsNullOrWhiteSpace($anchorType)
        ) {
            $anchorInvalid = $true
        }
    }
    if ($anchorInvalid) { $invalidReasons.Add('E1_RAW_ANCHOR_MISSING') }

    if ((Get-Phase00E1PropertyValue -Object $RunRecord -Name 'CleanupSucceeded') -ne $true) {
        $invalidReasons.Add('E1_CLEANUP_UNCERTAIN')
    }
    if (@(Get-Phase00E1PropertyValue -Object $RunRecord -Name 'RemainingChildPids').Count -gt 0) {
        $invalidReasons.Add('E1_CHILD_PROCESS_REMAINED')
    }
    if ((Get-Phase00E1PropertyValue -Object $RunRecord -Name 'ProtectedSurfacesUnchanged') -ne $true) {
        $invalidReasons.Add('E1_PROTECTED_SURFACE_MUTATION')
    }

    if ($invalidReasons.Count -gt 0) {
        return New-Phase00E1Analysis -Status INVALID_RUN `
            -ReasonCodes ([string[]]@($invalidReasons)) -Facts $facts
    }

    $terminalFailure = Get-Phase00E1PropertyValue -Object $ProviderLedger -Name 'TerminalFailure'
    if ((Get-Phase00E1PropertyValue -Object $terminalFailure -Name 'Found') -eq $true -and
        (Get-Phase00E1PropertyValue -Object $terminalFailure -Name 'IsEnvironmentBlock') -eq $true) {
        return New-Phase00E1Analysis -Status BLOCKED_ENVIRONMENT `
            -ReasonCodes @('E1_PROVIDER_ENVIRONMENT_BLOCK') -Facts $facts
    }

    $failureReasons = [Collections.Generic.List[string]]::new()
    if ((Get-Phase00E1PropertyValue -Object $terminalFailure -Name 'Found') -eq $true) {
        $failureReasons.Add('E1_TERMINAL_MODEL_FAILURE')
    }
    if ((Get-Phase00E1PropertyValue -Object $ProviderLedger -Name 'RetryExhausted') -eq $true) {
        $failureReasons.Add('E1_RETRY_EXHAUSTED')
    }
    if ([int](Get-Phase00E1PropertyValue -Object $RunRecord -Name 'ExitCode') -ne 0) {
        $failureReasons.Add('E1_PROCESS_EXIT_NONZERO')
    }

    $structuredOutput = Get-Phase00E1PropertyValue -Object $attributableResult -Name 'StructuredOutput'
    if ([string](Get-Phase00E1PropertyValue -Object $structuredOutput -Name 'status') -cne 'valid') {
        $failureReasons.Add('E1_STRUCTURED_STATUS_MISMATCH')
    }
    if ([string](Get-Phase00E1PropertyValue -Object $structuredOutput -Name 'source') -cne
        [string](Get-Phase00E1PropertyValue -Object $Definition -Name 'Source')) {
        $failureReasons.Add('E1_STRUCTURED_SOURCE_MISMATCH')
    }
    if ([string](Get-Phase00E1PropertyValue -Object $structuredOutput -Name 'mode') -cne
        [string](Get-Phase00E1PropertyValue -Object $Definition -Name 'Mode')) {
        $failureReasons.Add('E1_STRUCTURED_MODE_MISMATCH')
    }

    if ($failureReasons.Count -gt 0) {
        return New-Phase00E1Analysis -Status FAIL `
            -ReasonCodes ([string[]]@($failureReasons)) -Facts $facts
    }
    return New-Phase00E1Analysis -Status PASS `
        -ReasonCodes @('E1_COMMON_ORACLES_PASS') -Facts $facts
}

function Get-Phase00E1ExpectedFixtureHashes {
    return [ordered]@{
        '.omp/config.yml' = 'C1B6B21417044393E91BE3079545959D42CB72F00E0601D8909DF58527E10619'
        'agents/phase00-e1-agent-jtd.md' = 'B6A9CA4AF3A4E0365C8D2166F1FB143C34779001DBCC11138777CDA0D45B9E79'
        'agents/phase00-e1-agent-json-schema.md' = '2292140A382F80E8ADA2F0005626AD8E0716A180B004C4C78C81E33484DBE9E8'
        'agents/phase00-e1-caller-only.md' = '1C266E64CAC83797E7D7DA052631F858D624B5DDC4D2AA048BB607C7E54676B1'
        'agents/phase00-e1-caller-over-agent.md' = 'E68AF921F59BA6FD7FD12ECF95DBC5FBBA2D800683AAF6D8843C405A401A1B24'
        'agents/phase00-e1-session-carrier.md' = '02A737F9D61B7D0BE62B85AAA5B72F1820F7C44946A61B9B087A6EEE0EEF91B8'
        'agents/phase00-e1-session-leaf.md' = 'ECC6A1F4E415EF6E34893754EEE233676B440636FC376415E95BE8A3F1B9F801'
        'agents/phase00-e1-provider-strict.md' = 'F8E53C651A41707CA2226F3CE687F97236BB0F0600024E42E87ACD14B85293EA'
        'prompts/agent-jtd.md' = 'EE192EA1419604FDC8814F4A44D1B848F525DC41274DD6661C33A2877826742C'
        'prompts/agent-json-schema.md' = 'D5D1BD76225910C5112B1C6F07513B1CB6E677429A3B113699A47C395BD7B6B6'
        'prompts/caller-only.md' = '5D6F452B7AD069CB09070EC7C297BD533F0F0E17B3565C3C82A216C71541BF17'
        'prompts/caller-over-agent.md' = '6C1F4C76DEC505690B2E4D62FA259CCE885061FE753E7B6152629C034A8FF5E7'
        'prompts/session-only.md' = 'D93A14C4AF93541DB049C3A7154593FADF5275CCC07D2D912EFCEB20EF8BE817'
        'prompts/provider-strict.md' = '15B1C1BA9133F89B1125FCD089F87147F282DC1AAF315FFB303322A46AC87113'
    }
}

function Get-Phase00E1ProtectedHashes {
    return [ordered]@{
        'template/.omp/schemas/agent-result.schema.yml' = 'A55B8E64DA16BB8205A6F815E9A8CD8DDE96BB8E085139435C71B785DCAE57D8'
        'template/.omp/schemas/review-result.schema.yml' = '439D5B321739FE22792847C8D091668C58DEFC0244E8AD14A6328FE464A8182B'
        'template/.omp/schemas/task-packet.schema.yml' = '78459082CC66C1F9320D3734B1BBA9C10F7DAA4E68EB4828B3D3879357DF2ABB'
        'template/.omp/schemas/verification-result.schema.yml' = '2D6F05567482CAADB39E487BA7838DF24904ADFE12C66DEE180AA4B8D4DB627C'
        'template/.omp/agents/explorer.md' = 'EFF925B0CF199144F306AE8F40226F8087ECF45297B0CEB270E07C3E9DF3CAE6'
        'template/.omp/agents/implementer.md' = '6090C229C4A6B9132B99F4540EA9788A2520BB358846C6ADC5482DD911E72A22'
        'template/.omp/agents/reviewer.md' = '7960C0C595A2B11AD5DFDC9C9F2A591C34F5CCFC2C0ADF43D5EA70F94E3C3DE3'
        'template/.omp/agents/tech-lead.md' = '47B3060A725F9C41EA832E2CE8E7CBAEFCAFACB4137A9B4153C2819732016AD2'
        'template/.omp/agents/verifier.md' = 'A3F49E18266587929D05B2DE28AD59D7B31E3832C20DAD5C201AB03348C449E0'
    }
}

function ConvertTo-Phase00E1WindowsArgument {
    param([AllowEmptyString()][Parameter(Mandatory)][string]$Argument)

    if ($Argument.Length -gt 0 -and $Argument -notmatch '[\s"]') { return $Argument }
    $builder = [Text.StringBuilder]::new()
    [void]$builder.Append('"')
    $backslashes = 0
    foreach ($character in $Argument.ToCharArray()) {
        if ($character -eq '\') {
            $backslashes += 1
            continue
        }
        if ($character -eq '"') {
            [void]$builder.Append(('\' * (($backslashes * 2) + 1)))
            [void]$builder.Append('"')
            $backslashes = 0
            continue
        }
        if ($backslashes -gt 0) { [void]$builder.Append(('\' * $backslashes)) }
        [void]$builder.Append($character)
        $backslashes = 0
    }
    if ($backslashes -gt 0) { [void]$builder.Append(('\' * ($backslashes * 2))) }
    [void]$builder.Append('"')
    return $builder.ToString()
}

function Get-Phase00E1DescendantProcessIds {
    param([Parameter(Mandatory)][int]$ParentProcessId)

    $processRows = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Select-Object ProcessId,ParentProcessId)
    if ($processRows.Count -eq 0) { return @() }
    $seen = @{}
    $frontier = @($ParentProcessId)
    $descendants = [Collections.Generic.List[int]]::new()
    while ($frontier.Count -gt 0) {
        $next = [Collections.Generic.List[int]]::new()
        foreach ($parentId in $frontier) {
            foreach ($row in @($processRows | Where-Object {
                [int]$_.ParentProcessId -eq [int]$parentId
            })) {
                $childId = [int]$row.ProcessId
                if ($seen.ContainsKey($childId)) { continue }
                $seen[$childId] = $true
                $descendants.Add($childId)
                $next.Add($childId)
            }
        }
        $frontier = @($next)
    }
    return [int[]]@($descendants | Sort-Object -Unique)
}

function Stop-Phase00E1ProcessTree {
    param([Parameter(Mandatory)][Diagnostics.Process]$Process)

    if ($Process.HasExited) { return }
    $killTreeMethod = $Process.GetType().GetMethod('Kill', [type[]]@([bool]))
    if ($null -ne $killTreeMethod) {
        [void]$killTreeMethod.Invoke($Process, @($true))
        return
    }
    $taskkill = Get-Command taskkill.exe -CommandType Application -ErrorAction SilentlyContinue
    if ($null -ne $taskkill) {
        $taskkillProcess = Start-Process -FilePath $taskkill.Source `
            -ArgumentList @('/PID',[string]$Process.Id,'/T','/F') `
            -Wait -PassThru -WindowStyle Hidden
        if ($taskkillProcess.ExitCode -eq 0) { return }
    }
    $Process.Kill()
}

function Invoke-Phase00E1CapturedProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Arguments,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][Collections.IDictionary]$EnvironmentSet,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$EnvironmentRemove,
        [ValidateRange(1,3600)][int]$TimeoutSeconds = 540
    )

    $resolvedFile = [IO.Path]::GetFullPath($FilePath)
    $resolvedWorking = [IO.Path]::GetFullPath($WorkingDirectory)
    if (-not (Test-Path -LiteralPath $resolvedFile -PathType Leaf)) {
        throw "Captured-process executable does not exist: $resolvedFile"
    }
    if (-not (Test-Path -LiteralPath $resolvedWorking -PathType Container)) {
        throw "Captured-process working directory does not exist: $resolvedWorking"
    }

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $resolvedFile
    $startInfo.WorkingDirectory = $resolvedWorking
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    if ($null -ne $startInfo.PSObject.Properties['StandardOutputEncoding']) {
        $startInfo.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
        $startInfo.StandardErrorEncoding = [Text.UTF8Encoding]::new($false)
    }
    foreach ($name in @($EnvironmentRemove | Sort-Object -Unique)) {
        [void]$startInfo.EnvironmentVariables.Remove([string]$name)
    }
    foreach ($name in $EnvironmentSet.Keys) {
        $startInfo.EnvironmentVariables[[string]$name] = [string]$EnvironmentSet[$name]
    }
    if ($null -ne $startInfo.PSObject.Properties['ArgumentList']) {
        foreach ($argument in $Arguments) {
            [void]$startInfo.ArgumentList.Add([string]$argument)
        }
    } else {
        $startInfo.Arguments = @($Arguments | ForEach-Object {
            ConvertTo-Phase00E1WindowsArgument -Argument ([string]$_)
        }) -join ' '
    }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $startedAt = [DateTimeOffset]::Now
    $started = $false
    $timedOut = $false
    $descendantsObserved = @()
    try {
        if (-not $process.Start()) { throw 'Captured child process did not start.' }
        $started = $true
        $processId = [int]$process.Id
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $timedOut = $true
            $descendantsObserved = @(Get-Phase00E1DescendantProcessIds `
                -ParentProcessId $processId)
            Stop-Phase00E1ProcessTree -Process $process
            [void]$process.WaitForExit(10000)
        }
        if (-not $process.HasExited) {
            throw 'Timed-out captured process did not terminate.'
        }
        $process.WaitForExit()
        if (-not $stdoutTask.Wait(10000) -or -not $stderrTask.Wait(10000)) {
            throw 'Captured process streams did not close after process termination.'
        }
        $completedAt = [DateTimeOffset]::Now
        $remaining = @($descendantsObserved | Where-Object {
            $null -ne (Get-Process -Id $_ -ErrorAction SilentlyContinue)
        })
        return [pscustomobject][ordered]@{
            ProcessId = $processId
            ExitCode = [int]$process.ExitCode
            Stdout = [string]$stdoutTask.GetAwaiter().GetResult()
            Stderr = [string]$stderrTask.GetAwaiter().GetResult()
            StartedAt = $startedAt
            CompletedAt = $completedAt
            TimedOut = $timedOut
            DescendantPidsObserved = [int[]]@($descendantsObserved)
            RemainingChildPids = [int[]]@($remaining)
        }
    } finally {
        if ($started -and -not $process.HasExited) {
            try { Stop-Phase00E1ProcessTree -Process $process } catch {}
            try { [void]$process.WaitForExit(5000) } catch {}
        }
        $process.Dispose()
    }
}

function Get-Phase00E1IsolationRemovalVariables {
    $fixed = @(
        'PI_NO_STRICT','PI_CODING_AGENT_DIR','PI_CONFIG_FILES','PI_CONFIG_DIR',
        'PI_PROFILE','OMP_PROFILE','OMP_AUTH_BROKER_URL','OMP_AUTH_BROKER_TOKEN',
        'OMP_AUTH_BROKER_ACCOUNT_POOL_FILE','OMP_WORKTREE_DIR','NODE_OPTIONS',
        'BUN_OPTIONS','HOME','USERPROFILE','APPDATA','LOCALAPPDATA',
        'XDG_CONFIG_HOME','XDG_DATA_HOME','XDG_STATE_HOME','XDG_CACHE_HOME',
        'HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','NO_PROXY'
    )
    $dynamic = @([Environment]::GetEnvironmentVariables('Process').Keys |
        ForEach-Object { [string]$_ } | Where-Object { $_ -match '^(PI_|OMP_)' })
    return [string[]]@($fixed + $dynamic | Sort-Object -Unique)
}

function Resolve-Phase00E1PinnedSource {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $repository = [IO.Path]::GetFullPath($RepositoryRoot)
    $sourceRoot = Join-Path $repository '_research\upstreams\oh-my-pi'
    if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
        throw "E1_PINNED_SOURCE_MISSING: $sourceRoot"
    }
    $git = @(Get-Command git.exe -CommandType Application `
        -ErrorAction SilentlyContinue | Select-Object -First 1)[0]
    if ($null -eq $git) {
        throw 'E1_PINNED_SOURCE_GIT_UNAVAILABLE'
    }
    $headOutput = @(& $git.Source -C $sourceRoot rev-parse HEAD 2>&1)
    if ($LASTEXITCODE -ne 0 -or $headOutput.Count -ne 1) {
        throw "E1_PINNED_SOURCE_HEAD_UNAVAILABLE: $($headOutput -join ' ')"
    }
    $statusOutput = @(& $git.Source -C $sourceRoot status `
        --porcelain=v1 --untracked-files=all 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "E1_PINNED_SOURCE_STATUS_UNAVAILABLE: $($statusOutput -join ' ')"
    }
    $originOutput = @(& $git.Source -C $sourceRoot remote get-url origin 2>&1)
    if ($LASTEXITCODE -ne 0 -or $originOutput.Count -ne 1) {
        throw "E1_PINNED_SOURCE_ORIGIN_UNAVAILABLE: $($originOutput -join ' ')"
    }
    $commit = ([string]$headOutput[0]).Trim()
    $origin = ([string]$originOutput[0]).Trim()
    $expectedCommit = '3a8591a8af5b6d200088d12ca75a5517cb064fa8'
    $expectedOrigin = 'https://github.com/can1357/oh-my-pi.git'
    if ($commit -cne $expectedCommit) {
        throw "E1_PINNED_SOURCE_COMMIT_MISMATCH: expected $expectedCommit, observed $commit"
    }
    if (@($statusOutput).Count -ne 0) {
        throw 'E1_PINNED_SOURCE_DIRTY'
    }
    if ($origin -cne $expectedOrigin) {
        throw "E1_PINNED_SOURCE_ORIGIN_MISMATCH: expected $expectedOrigin, observed $origin"
    }
    return [pscustomobject][ordered]@{
        SourceRoot = [IO.Path]::GetFullPath($sourceRoot)
        Commit = $commit
        Clean = $true
        Origin = $origin
    }
}

function Resolve-Phase00E1PinnedOmpSource {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ExpectedSha256,
        [Parameter(Mandatory)][string]$ExpectedVersion,
        [Parameter(Mandatory)][string]$WorkingDirectory
    )

    if (-not [IO.Path]::IsPathRooted($Path)) {
        throw 'Pinned OMP executable path must be absolute.'
    }
    $resolved = [IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        throw "Pinned OMP executable does not exist: $resolved"
    }
    $sha256 = (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash
    if ($sha256 -ine $ExpectedSha256) {
        throw "Pinned OMP SHA-256 mismatch: expected $ExpectedSha256, observed $sha256"
    }
    $probe = Invoke-Phase00E1CapturedProcess -FilePath $resolved `
        -Arguments @('--version') -WorkingDirectory $WorkingDirectory `
        -EnvironmentSet @{} `
        -EnvironmentRemove (Get-Phase00E1IsolationRemovalVariables) `
        -TimeoutSeconds 30
    $observedVersion = $probe.Stdout.Trim()
    if (
        $probe.TimedOut -or
        $probe.ExitCode -ne 0 -or
        $observedVersion -cne $ExpectedVersion -or
        -not [string]::IsNullOrEmpty($probe.Stderr)
    ) {
        throw "Pinned OMP version probe mismatch: expected $ExpectedVersion, observed $observedVersion"
    }
    return [pscustomobject][ordered]@{
        Path = $resolved
        Sha256 = $sha256
        Version = $observedVersion
        ProbeArguments = @('--version')
        ProbeExitCode = $probe.ExitCode
        ProbeTimedOut = $probe.TimedOut
    }
}

function Get-Phase00E1CaseSlug {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn')]
        [string]$CaseId
    )

    switch ($CaseId) {
        'AgentJtd' { 'agent-jtd' }
        'AgentJsonSchema' { 'agent-json-schema' }
        'CallerOnly' { 'caller-only' }
        'CallerOverAgent' { 'caller-over-agent' }
        'SessionOnly' { 'session-only' }
        'ProviderStrictOffControl' { 'provider-strict-off-control' }
        'ProviderStrictOn' { 'provider-strict-on' }
    }
}

function Get-Phase00E1AttemptPaths {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)]
        [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn')]
        [string]$CaseId,
        [ValidateRange(1,999)][int]$Attempt = 1
    )

    $root = [IO.Path]::GetFullPath($RepositoryRoot)
    $slug = Get-Phase00E1CaseSlug -CaseId $CaseId
    $caseDirectory = Join-Path $root "docs\evidence\phase-00\E1\raw\$slug"
    $stem = 'attempt-{0:D3}' -f $Attempt
    return [pscustomobject][ordered]@{
        CaseDirectory = $caseDirectory
        Stem = $stem
        StdoutPath = Join-Path $caseDirectory "$stem.stdout.jsonl"
        StderrPath = Join-Path $caseDirectory "$stem.stderr.jsonl"
        RunPath = Join-Path $caseDirectory "$stem.run.json"
        ForwarderPath = Join-Path $caseDirectory "$stem.forwarder.ndjson"
        SessionDirectory = Join-Path $caseDirectory "$stem.sessions"
    }
}

function Assert-Phase00E1AttemptDestinations {
    param(
        [Parameter(Mandatory)]$Paths,
        [switch]$AllowOverwrite
    )

    if ($AllowOverwrite) {
        throw 'E1 evidence overwrite is not authorized; preserve the attempt and use a new number.'
    }
    $destinations = @(
        $Paths.StdoutPath,$Paths.StderrPath,$Paths.RunPath,
        $Paths.ForwarderPath,$Paths.SessionDirectory
    )
    $existing = @($destinations | Where-Object { Test-Path -LiteralPath $_ })
    if ($existing.Count -gt 0) {
        throw "E1 evidence destination exists; preserve it and use a new attempt: $($existing[0])"
    }
    return $true
}

function New-Phase00E1DisposableRoot {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn')]
        [string]$CaseId,
        [string]$TempRoot = [IO.Path]::GetTempPath()
    )

    $systemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')
    $base = [IO.Path]::GetFullPath($TempRoot).TrimEnd('\','/')
    if ($base -ne $systemTemp) {
        $null = Assert-Phase00E1DisposableDescendant -Path $base -TempRoot $systemTemp
    }
    if (-not (Test-Path -LiteralPath $base -PathType Container)) {
        throw "E1 disposable base does not exist: $base"
    }
    $slug = Get-Phase00E1CaseSlug -CaseId $CaseId
    $path = Join-Path $base ("omp-phase00-e1-{0}-{1}" -f $slug,[guid]::NewGuid().ToString('N'))
    $verified = Assert-Phase00E1DisposableDescendant -Path $path -TempRoot $systemTemp
    New-Item -ItemType Directory -Path $verified -ErrorAction Stop | Out-Null
    return $verified
}

function Remove-Phase00E1DisposableRoot {
    param([Parameter(Mandatory)][string]$Path)

    $systemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')
    $verified = Assert-Phase00E1DisposableDescendant -Path $Path -TempRoot $systemTemp
    $leaf = [IO.Path]::GetFileName($verified)
    if ($leaf -notmatch '^omp-phase00-e1-[a-z0-9-]+-[0-9a-f]{32}$') {
        throw "Refusing non-generated E1 disposable root: $verified"
    }
    for ($attempt = 1; $attempt -le 10; $attempt += 1) {
        if (-not (Test-Path -LiteralPath $verified)) { break }
        try {
            Remove-Item -LiteralPath $verified -Recurse -Force -ErrorAction Stop
        } catch {
            if ($attempt -eq 10) { throw }
            Start-Sleep -Milliseconds (100 * $attempt)
        }
    }
    if (Test-Path -LiteralPath $verified) {
        throw "E1 disposable root remains after cleanup: $verified"
    }
}

function Get-Phase00E1DirectorySnapshot {
    param([Parameter(Mandatory)][string]$Path)

    $root = [IO.Path]::GetFullPath($Path).TrimEnd('\','/')
    $entries = @()
    if (Test-Path -LiteralPath $root -PathType Container) {
        $prefix = $root + [IO.Path]::DirectorySeparatorChar
        $entries = @(Get-ChildItem -LiteralPath $root -Force -File -Recurse |
            ForEach-Object {
                [pscustomobject][ordered]@{
                    Path = $_.FullName.Substring($prefix.Length).Replace('\','/')
                    Length = [long]$_.Length
                    LastWriteUtcTicks = [long]$_.LastWriteTimeUtc.Ticks
                    Sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
                }
            } | Sort-Object Path)
    }
    $canonical = @($entries | ForEach-Object {
        '{0}|{1}|{2}|{3}' -f $_.Path,$_.Length,$_.LastWriteUtcTicks,$_.Sha256
    }) -join "`n"
    return [pscustomobject][ordered]@{
        Exists = Test-Path -LiteralPath $root -PathType Container
        FileCount = $entries.Count
        Sha256 = Get-Phase00E1StringSha256 -Text $canonical
        Entries = @($entries)
    }
}

function Compare-Phase00E1DirectorySnapshot {
    param(
        [Parameter(Mandatory)]$Before,
        [Parameter(Mandatory)]$After
    )

    $beforeByPath = @{}
    $afterByPath = @{}
    foreach ($entry in @($Before.Entries)) { $beforeByPath[[string]$entry.Path] = $entry }
    foreach ($entry in @($After.Entries)) { $afterByPath[[string]$entry.Path] = $entry }
    $changed = @($beforeByPath.Keys + $afterByPath.Keys | Sort-Object -Unique |
        Where-Object {
            $path = [string]$_
            if (-not $beforeByPath.ContainsKey($path) -or -not $afterByPath.ContainsKey($path)) {
                return $true
            }
            $left = $beforeByPath[$path]
            $right = $afterByPath[$path]
            [long]$left.Length -ne [long]$right.Length -or
            [long]$left.LastWriteUtcTicks -ne [long]$right.LastWriteUtcTicks -or
            [string]$left.Sha256 -ne [string]$right.Sha256
        })
    return [pscustomobject][ordered]@{
        Unchanged = ($Before.Exists -eq $After.Exists -and $changed.Count -eq 0)
        BeforeFileCount = [int]$Before.FileCount
        AfterFileCount = [int]$After.FileCount
        BeforeSha256 = [string]$Before.Sha256
        AfterSha256 = [string]$After.Sha256
        ChangedPaths = [string[]]@($changed)
        ChangedCount = $changed.Count
    }
}

function Get-Phase00E1ProtectedSnapshot {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][Collections.IDictionary]$ExpectedHashes
    )

    $root = [IO.Path]::GetFullPath($RepositoryRoot)
    $entries = foreach ($relativePath in @($ExpectedHashes.Keys | Sort-Object)) {
        $path = Join-Path $root ([string]$relativePath).Replace('/',[IO.Path]::DirectorySeparatorChar)
        $exists = Test-Path -LiteralPath $path -PathType Leaf
        $actual = if ($exists) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash } else { $null }
        [pscustomobject][ordered]@{
            Path = [string]$relativePath
            Exists = $exists
            ExpectedSha256 = [string]$ExpectedHashes[$relativePath]
            ActualSha256 = $actual
            Matched = $exists -and $actual -ieq [string]$ExpectedHashes[$relativePath]
        }
    }
    $matched = @($entries | Where-Object Matched).Count
    return [pscustomobject][ordered]@{
        FileCount = @($entries).Count
        MatchedCount = $matched
        AllExpected = $matched -eq @($entries).Count
        Entries = @($entries)
    }
}

function Compare-Phase00E1ProtectedSnapshot {
    param(
        [Parameter(Mandatory)]$Before,
        [Parameter(Mandatory)]$After
    )

    $beforeByPath = @{}
    $afterByPath = @{}
    foreach ($entry in @($Before.Entries)) { $beforeByPath[[string]$entry.Path] = $entry }
    foreach ($entry in @($After.Entries)) { $afterByPath[[string]$entry.Path] = $entry }
    $changed = @($beforeByPath.Keys + $afterByPath.Keys | Sort-Object -Unique |
        Where-Object {
            $path = [string]$_
            if (-not $beforeByPath.ContainsKey($path) -or -not $afterByPath.ContainsKey($path)) {
                return $true
            }
            $left = $beforeByPath[$path]
            $right = $afterByPath[$path]
            [bool]$left.Exists -ne [bool]$right.Exists -or
            [string]$left.ActualSha256 -ne [string]$right.ActualSha256
        })
    return [pscustomobject][ordered]@{
        Unchanged = ($changed.Count -eq 0)
        BeforeAllExpected = [bool]$Before.AllExpected
        AfterAllExpected = [bool]$After.AllExpected
        ChangedPaths = [string[]]@($changed)
        ChangedCount = $changed.Count
    }
}

function Get-Phase00E1ProcessEnvironment {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn')]
        [string]$CaseId,
        [Parameter(Mandatory)][string]$AgentDirectory,
        [Parameter(Mandatory)][string]$DisposableRoot,
        [Parameter(Mandatory)][string]$RuntimeDirectory
    )

    $agent = [IO.Path]::GetFullPath($AgentDirectory)
    $root = [IO.Path]::GetFullPath($DisposableRoot)
    $runtime = [IO.Path]::GetFullPath($RuntimeDirectory)
    $existingPath = [Environment]::GetEnvironmentVariable('PATH','Process')
    $set = [ordered]@{
        PI_CODING_AGENT_DIR = $agent
        HOME = $root
        USERPROFILE = $root
        APPDATA = Join-Path $root 'appdata'
        LOCALAPPDATA = Join-Path $root 'localappdata'
        XDG_CONFIG_HOME = Join-Path $root 'xdg-config'
        XDG_DATA_HOME = Join-Path $root 'xdg-data'
        XDG_STATE_HOME = Join-Path $root 'xdg-state'
        XDG_CACHE_HOME = Join-Path $root 'xdg-cache'
        PATH = if ([string]::IsNullOrEmpty($existingPath)) {
            $runtime
        } else {
            $runtime + [IO.Path]::PathSeparator + $existingPath
        }
        NO_PROXY = '127.0.0.1,localhost'
    }
    if ($CaseId -eq 'ProviderStrictOffControl') {
        $set.PI_NO_STRICT = '1'
    }
    return [pscustomobject][ordered]@{
        SetVariables = $set
        RemoveVariables = [string[]]@(Get-Phase00E1IsolationRemovalVariables)
        Record = [ordered]@{
            PI_CODING_AGENT_DIR = '<DISPOSABLE_AGENT_HOME>'
            HOME = '<DISPOSABLE_ROOT>'
            USERPROFILE = '<DISPOSABLE_ROOT>'
            PATH_PREFIX = '<DISPOSABLE_RUNTIME>'
            PI_NO_STRICT = if ($CaseId -eq 'ProviderStrictOffControl') { '1' } else { '<ABSENT>' }
            PROFILES = '<REMOVED>'
            EXTRA_CONFIG = '<REMOVED>'
            AUTH_BROKER = '<REMOVED>'
            LOOPBACK_NO_PROXY = $true
        }
    }
}

function Get-Phase00E1OmpArguments {
    param(
        [Parameter(Mandatory)][string]$DisposableProject,
        [Parameter(Mandatory)][string]$SessionDirectory,
        [Parameter(Mandatory)][string]$ConfigPath,
        [Parameter(Mandatory)][string]$Model,
        [AllowEmptyString()][Parameter(Mandatory)][string]$PromptText,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    $project = [IO.Path]::GetFullPath($DisposableProject).TrimEnd('\','/')
    $repository = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\','/')
    $repositoryPrefix = $repository + [IO.Path]::DirectorySeparatorChar
    if ($project.Equals($repository,[StringComparison]::OrdinalIgnoreCase) -or
        $project.StartsWith($repositoryPrefix,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'E1 OMP cwd must be a non-repository disposable project.'
    }
    $null = Assert-Phase00E1DisposableDescendant -Path $project -TempRoot ([IO.Path]::GetTempPath())
    $session = Assert-Phase00E1DisposableDescendant `
        -Path $SessionDirectory -TempRoot ([IO.Path]::GetTempPath())
    $config = [IO.Path]::GetFullPath($ConfigPath)
    if (-not (Test-Path -LiteralPath $config -PathType Leaf)) {
        throw "E1 disposable config does not exist: $config"
    }
    return @(
        '-p','--mode','json',
        '--cwd',$project,
        '--session-dir',$session,
        '--config',$config,
        '--model',$Model,
        '--tools','task',
        '--approval-mode','yolo',
        '--max-time','8m',
        '--no-extensions','--no-skills','--no-rules','--no-lsp','--no-title',
        $PromptText
    )
}

function Get-Phase00E1FixtureDestinationPath {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $normalized = $RelativePath.Replace('\','/')
    if ($normalized -eq '.omp/config.yml') {
        return Join-Path $ProjectRoot '.omp\config.yml'
    }
    if ($normalized.StartsWith('agents/',[StringComparison]::Ordinal)) {
        return Join-Path $ProjectRoot ('.omp\' + $normalized.Replace('/','\'))
    }
    if ($normalized.StartsWith('prompts/',[StringComparison]::Ordinal)) {
        return Join-Path $ProjectRoot $normalized.Replace('/','\')
    }
    throw "Unknown E1 fixture path: $RelativePath"
}

function Test-Phase00E1FixtureTree {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][Collections.IDictionary]$ExpectedHashes,
        [string]$ProjectRoot
    )

    $root = [IO.Path]::GetFullPath($FixtureRoot).TrimEnd('\','/')
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        return [pscustomobject][ordered]@{
            Matched = $false
            ExpectedCount = $ExpectedHashes.Count
            ActualCount = 0
            Mismatches = @('FIXTURE_ROOT_MISSING')
            Hashes = [ordered]@{}
        }
    }
    $actualPaths = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $prefix = $root + [IO.Path]::DirectorySeparatorChar
        @(Get-ChildItem -LiteralPath $root -File -Recurse | ForEach-Object {
            $_.FullName.Substring($prefix.Length).Replace('\','/')
        } | Sort-Object)
    } else {
        @($ExpectedHashes.Keys | Sort-Object)
    }
    $hashes = [ordered]@{}
    $mismatches = [Collections.Generic.List[string]]::new()
    $expectedPaths = @($ExpectedHashes.Keys | Sort-Object)
    if ([string]::IsNullOrWhiteSpace($ProjectRoot) -and
        ($actualPaths -join "`n") -ne ($expectedPaths -join "`n")) {
        $mismatches.Add('FIXTURE_PATH_SET')
    }
    foreach ($relativePath in $expectedPaths) {
        $path = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
            Join-Path $root ([string]$relativePath).Replace('/',[IO.Path]::DirectorySeparatorChar)
        } else {
            Get-Phase00E1FixtureDestinationPath -RelativePath $relativePath `
                -ProjectRoot $ProjectRoot
        }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $mismatches.Add("MISSING:$relativePath")
            continue
        }
        $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        $hashes[[string]$relativePath] = $hash
        if ($hash -ine [string]$ExpectedHashes[$relativePath]) {
            $mismatches.Add("HASH:$relativePath")
        }
    }
    return [pscustomobject][ordered]@{
        Matched = ($mismatches.Count -eq 0)
        ExpectedCount = $ExpectedHashes.Count
        ActualCount = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
            $actualPaths.Count
        } else {
            $hashes.Count
        }
        Mismatches = [string[]]@($mismatches)
        Hashes = $hashes
    }
}

function Get-Phase00E1SanitizedModelCatalogText {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$ProviderBaseUrl
    )

    $resolvedSource = [IO.Path]::GetFullPath($SourcePath)
    if (-not (Test-Path -LiteralPath $resolvedSource -PathType Leaf)) {
        throw "E1 runtime model catalog does not exist: $resolvedSource"
    }
    $expectedCatalogHash = '2F3EEE2C67E38C571A5D96D55D9068CF8FE0110877F1EE5F95274CCC76DBA34E'
    $sourceHash = (Get-FileHash -LiteralPath $resolvedSource -Algorithm SHA256).Hash
    if ($sourceHash -ne $expectedCatalogHash) {
        throw "E1 runtime model catalog SHA-256 mismatch: $sourceHash"
    }
    $sourceText = [IO.File]::ReadAllText($resolvedSource).Replace("`r`n","`n")
    foreach ($required in @(
        'providers:','  omniroute:','    baseUrl: http://127.0.0.1:20128/v1',
        '    apiKey: OMNIROUTE_API_KEY','    api: openai-responses',
        '      - id: codex/gpt-5.6-sol-high'
    )) {
        if (-not $sourceText.Contains($required)) {
            throw "E1 runtime model catalog lacks required pinned text: $required"
        }
    }
    $uri = $null
    try { $uri = [Uri]$ProviderBaseUrl } catch {
        throw "E1 provider base URL is invalid: $ProviderBaseUrl"
    }
    if (
        $uri.Scheme -cne 'http' -or
        $uri.Host -cne '127.0.0.1' -or
        $uri.IsDefaultPort -or
        $uri.AbsolutePath -cne '/v1' -or
        -not [string]::IsNullOrEmpty($uri.Query) -or
        -not [string]::IsNullOrEmpty($uri.Fragment) -or
        -not [string]::IsNullOrEmpty($uri.UserInfo)
    ) {
        throw 'E1 provider base URL must be exactly an HTTP 127.0.0.1:<port>/v1 URL.'
    }
    return @"
providers:
  omniroute:
    baseUrl: $ProviderBaseUrl
    apiKey: OMNIROUTE_API_KEY
    api: openai-responses
    authHeader: true
    models:
      - id: codex/gpt-5.6-sol-high
        name: Codex GPT-5.6 Sol High via OmniRoute
        reasoning: true
        input: [text]
        contextWindow: 128000
"@.Replace("`r`n","`n").TrimEnd("`r","`n") + "`n"
}

function Initialize-Phase00E1DisposableFixture {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)]$RuntimeIdentity,
        [string]$ProviderBaseUrl = 'http://127.0.0.1:20128/v1'
    )

    $systemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')
    $verifiedRoot = Assert-Phase00E1DisposableDescendant -Path $Root -TempRoot $systemTemp
    if ([IO.Path]::GetFileName($verifiedRoot) -notmatch '^omp-phase00-e1-[a-z0-9-]+-[0-9a-f]{32}$') {
        throw "E1 fixture root is not a generated runner root: $verifiedRoot"
    }
    $existing = @(Get-ChildItem -LiteralPath $verifiedRoot -Force -ErrorAction Stop)
    if ($existing.Count -gt 0) {
        throw "E1 disposable root is not empty: $verifiedRoot"
    }

    $repository = [IO.Path]::GetFullPath($RepositoryRoot)
    $sourceFixture = Join-Path $repository 'docs\evidence\phase-00\E1\fixture'
    $expectedFixtureHashes = Get-Phase00E1ExpectedFixtureHashes
    $sourceCheck = Test-Phase00E1FixtureTree -FixtureRoot $sourceFixture `
        -ExpectedHashes $expectedFixtureHashes
    if (-not $sourceCheck.Matched) {
        throw "E1 source fixture identity mismatch: $($sourceCheck.Mismatches -join ',')"
    }

    $agentHome = Join-Path $verifiedRoot 'agent-home'
    $projectRoot = Join-Path $verifiedRoot 'project'
    $projectAgentDirectory = Join-Path $projectRoot '.omp\agents'
    $promptDirectory = Join-Path $projectRoot 'prompts'
    $sessionDirectory = Join-Path $verifiedRoot 'sessions'
    $captureDirectory = Join-Path $verifiedRoot 'capture'
    $runtimeDirectory = Join-Path $verifiedRoot 'runtime'
    foreach ($directory in @(
        $agentHome,$projectAgentDirectory,$promptDirectory,
        $sessionDirectory,$captureDirectory,$runtimeDirectory
    )) {
        New-Item -ItemType Directory -Path $directory -ErrorAction Stop | Out-Null
    }

    foreach ($relativePath in $expectedFixtureHashes.Keys) {
        $source = Join-Path $sourceFixture `
            ([string]$relativePath).Replace('/',[IO.Path]::DirectorySeparatorChar)
        $destination = Get-Phase00E1FixtureDestinationPath `
            -RelativePath $relativePath -ProjectRoot $projectRoot
        $parent = Split-Path -Parent $destination
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -ErrorAction Stop | Out-Null
        }
        [IO.File]::Copy($source,$destination,$false)
    }
    $copiedCheck = Test-Phase00E1FixtureTree -FixtureRoot $projectRoot `
        -ExpectedHashes $expectedFixtureHashes -ProjectRoot $projectRoot
    if (-not $copiedCheck.Matched) {
        throw "E1 copied fixture identity mismatch: $($copiedCheck.Mismatches -join ',')"
    }

    $catalogSource = Join-Path $repository `
        'docs\evidence\phase-00\environment\runtime-models.yml'
    $catalogText = Get-Phase00E1SanitizedModelCatalogText `
        -SourcePath $catalogSource -ProviderBaseUrl $ProviderBaseUrl
    $catalogPath = Join-Path $agentHome 'models.yml'
    [IO.File]::WriteAllText($catalogPath,$catalogText,[Text.UTF8Encoding]::new($false))

    $sourceExecutable = [IO.Path]::GetFullPath([string]$RuntimeIdentity.Path)
    $sourceHash = (Get-FileHash -LiteralPath $sourceExecutable -Algorithm SHA256).Hash
    if ($sourceHash -ine [string]$RuntimeIdentity.Sha256) {
        throw 'E1 pinned runtime source changed after preflight.'
    }
    $runtimeExecutable = Join-Path $runtimeDirectory 'omp.exe'
    [IO.File]::Copy($sourceExecutable,$runtimeExecutable,$false)
    $copiedHash = (Get-FileHash -LiteralPath $runtimeExecutable -Algorithm SHA256).Hash
    if ($copiedHash -ine $sourceHash) {
        throw 'E1 copied runtime SHA-256 does not match its pinned source.'
    }
    $versionProbe = Invoke-Phase00E1CapturedProcess -FilePath $runtimeExecutable `
        -Arguments @('--version') -WorkingDirectory $verifiedRoot `
        -EnvironmentSet @{} `
        -EnvironmentRemove (Get-Phase00E1IsolationRemovalVariables) `
        -TimeoutSeconds 30
    $runtimeVersion = $versionProbe.Stdout.Trim()
    if (
        $versionProbe.TimedOut -or
        $versionProbe.ExitCode -ne 0 -or
        $runtimeVersion -cne [string]$RuntimeIdentity.Version -or
        -not [string]::IsNullOrEmpty($versionProbe.Stderr)
    ) {
        throw "E1 copied runtime version mismatch: $runtimeVersion"
    }

    return [pscustomobject][ordered]@{
        Root = $verifiedRoot
        AgentDirectory = [IO.Path]::GetFullPath($agentHome)
        ProjectRoot = [IO.Path]::GetFullPath($projectRoot)
        ProjectAgentDirectory = [IO.Path]::GetFullPath($projectAgentDirectory)
        PromptDirectory = [IO.Path]::GetFullPath($promptDirectory)
        SessionDirectory = [IO.Path]::GetFullPath($sessionDirectory)
        CaptureDirectory = [IO.Path]::GetFullPath($captureDirectory)
        RuntimeDirectory = [IO.Path]::GetFullPath($runtimeDirectory)
        RuntimeExecutable = [IO.Path]::GetFullPath($runtimeExecutable)
        RuntimeSourceSha256 = $sourceHash
        RuntimeCopiedSha256 = $copiedHash
        RuntimeVersion = $runtimeVersion
        ConfigPath = [IO.Path]::GetFullPath((Join-Path $projectRoot '.omp\config.yml'))
        ModelCatalogPath = [IO.Path]::GetFullPath($catalogPath)
        ModelCatalogText = $catalogText
        ModelCatalogSha256 = (Get-FileHash -LiteralPath $catalogPath -Algorithm SHA256).Hash
        ProviderBaseUrl = $ProviderBaseUrl
        SourceFixtureMatched = [bool]$sourceCheck.Matched
        CopiedFixtureMatched = [bool]$copiedCheck.Matched
        FixtureHashes = $copiedCheck.Hashes
    }
}

function Protect-Phase00E1TextStream {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$DestinationPath
    )

    $source = [IO.Path]::GetFullPath($SourcePath)
    $destination = [IO.Path]::GetFullPath($DestinationPath)
    if ($source.Equals($destination,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'E1 text sanitization source and destination must differ.'
    }
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "E1 text sanitization source does not exist: $source"
    }
    if (Test-Path -LiteralPath $destination) {
        throw "E1 text sanitization destination already exists: $destination"
    }
    $sourceHash = Get-Phase00E1FileSha256 -Path $source
    $writer = [IO.StreamWriter]::new($destination,$false,[Text.UTF8Encoding]::new($false))
    $enumerator = $null
    $lineCount = 0
    try {
        $enumerator = [IO.File]::ReadLines($source).GetEnumerator()
        while ($enumerator.MoveNext()) {
            $line = [string]$enumerator.Current
            $lineCount += 1
            $record = [ordered]@{
                record_type = 'phase00_e1_stderr_line'
                source_line = $lineCount
                source_line_sha256 = Get-Phase00E1StringSha256 -Text $line
                source_line_length = $line.Length
                classification = if ([string]::IsNullOrWhiteSpace($line)) {
                    'empty'
                } else {
                    'text_redacted'
                }
            }
            $writer.WriteLine(($record | ConvertTo-Json -Compress -Depth 10))
        }
    } finally {
        if ($null -ne $enumerator) { $enumerator.Dispose() }
        $writer.Dispose()
    }
    return [pscustomobject][ordered]@{
        Status = 'PASS'
        ReasonCodes = [string[]]@()
        SourceCaptureSha256 = $sourceHash
        SanitizedOutputSha256 = Get-Phase00E1FileSha256 -Path $destination
        SourceLineCount = $lineCount
        SanitizedLineCount = $lineCount
        MalformedLines = @()
        InvalidShapeLines = @()
        ProcessingErrorLines = @()
        CredentialLines = @()
        FixtureHashes = [ordered]@{}
    }
}

function Test-Phase00E1TextContainsSecret {
    param(
        [AllowEmptyString()][string]$Text,
        [AllowEmptyString()][string]$Secret
    )

    if ([string]::IsNullOrEmpty($Secret)) { return $false }
    if ($Text.IndexOf($Secret,[StringComparison]::Ordinal) -ge 0) { return $true }
    $encoded = $Secret | ConvertTo-Json -Compress
    if ($encoded.Length -ge 2 -and $encoded[0] -eq '"' -and
        $encoded[$encoded.Length - 1] -eq '"') {
        $encoded = $encoded.Substring(1,$encoded.Length - 2)
    }
    return (
        -not [string]::IsNullOrEmpty($encoded) -and
        $Text.IndexOf($encoded,[StringComparison]::Ordinal) -ge 0
    )
}

function Test-Phase00E1SanitizedArtifacts {
    param(
        [Parameter(Mandatory)][object[]]$Artifacts,
        [AllowEmptyCollection()][string[]]$SecretValues = @()
    )

    $reasons = [Collections.Generic.List[string]]::new()
    $totalSourceLines = 0
    $totalSanitizedLines = 0
    foreach ($artifact in @($Artifacts)) {
        $path = [string](Get-Phase00E1PropertyValue -Object $artifact -Name 'Path')
        $metadata = Get-Phase00E1PropertyValue -Object $artifact -Name 'Metadata'
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $reasons.Add('E1_SANITIZED_ARTIFACT_MISSING')
            continue
        }
        $expectedHash = [string](Get-Phase00E1PropertyValue `
            -Object $metadata -Name 'SanitizedOutputSha256')
        $actualHash = Get-Phase00E1FileSha256 -Path $path
        if ([string]::IsNullOrWhiteSpace($expectedHash) -or $actualHash -ine $expectedHash) {
            $reasons.Add('E1_SANITIZED_ARTIFACT_HASH_MISMATCH')
        }
        $sourceLineCount = [int](Get-Phase00E1PropertyValue `
            -Object $metadata -Name 'SourceLineCount')
        $expectedLineCount = [int](Get-Phase00E1PropertyValue `
            -Object $metadata -Name 'SanitizedLineCount')
        $totalSourceLines += $sourceLineCount
        $parsedLineCount = 0
        $enumerator = $null
        try {
            $enumerator = [IO.File]::ReadLines($path).GetEnumerator()
            while ($enumerator.MoveNext()) {
                $line = [string]$enumerator.Current
                $parsedLineCount += 1
                try {
                    $null = $line | ConvertFrom-Json -ErrorAction Stop
                    if ((Get-Phase00E1JsonValueKind -JsonText $line) -ne 'object') {
                        $reasons.Add('E1_SANITIZED_ARTIFACT_NON_OBJECT')
                    }
                } catch {
                    $reasons.Add('E1_SANITIZED_ARTIFACT_UNPARSEABLE')
                }
            }
        } finally {
            if ($null -ne $enumerator) { $enumerator.Dispose() }
        }
        $totalSanitizedLines += $parsedLineCount
        if ($parsedLineCount -ne $expectedLineCount -or
            $expectedLineCount -ne $sourceLineCount) {
            $reasons.Add('E1_SANITIZED_ARTIFACT_LINE_COUNT')
        }
        $text = [IO.File]::ReadAllText($path)
        foreach ($secret in @($SecretValues)) {
            if (Test-Phase00E1TextContainsSecret -Text $text -Secret $secret) {
                $reasons.Add('E1_SANITIZED_ARTIFACT_SECRET_LEAK')
            }
        }
    }
    $uniqueReasons = [string[]]@($reasons | Select-Object -Unique)
    return [pscustomobject][ordered]@{
        Status = if ($uniqueReasons.Count -eq 0) { 'PASS' } else { 'INVALID_RUN' }
        ReasonCodes = $uniqueReasons
        ArtifactCount = @($Artifacts).Count
        TotalSourceLines = $totalSourceLines
        TotalSanitizedLines = $totalSanitizedLines
    }
}

function Get-Phase00E1LiveHomeSurfaces {
    $candidates = [Collections.Generic.List[string]]::new()
    $userProfile = [Environment]::GetFolderPath('UserProfile')
    if ([string]::IsNullOrWhiteSpace($userProfile)) {
        $userProfile = [Environment]::GetEnvironmentVariable('USERPROFILE','Process')
    }
    if (-not [string]::IsNullOrWhiteSpace($userProfile)) {
        $candidates.Add((Join-Path $userProfile '.omp\agent'))
    }
    $inheritedAgentHome = [Environment]::GetEnvironmentVariable(
        'PI_CODING_AGENT_DIR',
        'Process'
    )
    if (-not [string]::IsNullOrWhiteSpace($inheritedAgentHome)) {
        $candidates.Add($inheritedAgentHome)
    }

    $seen = [Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $surfaces = [Collections.Generic.List[object]]::new()
    foreach ($candidate in $candidates) {
        $fullPath = [IO.Path]::GetFullPath($candidate).TrimEnd('\','/')
        if (-not $seen.Add($fullPath)) { continue }
        $surfaces.Add([pscustomobject][ordered]@{
            Id = 'LIVE_HOME_{0}' -f ($surfaces.Count + 1)
            Path = $fullPath
        })
    }
    return @($surfaces)
}

function Get-Phase00E1LiveHomeSnapshots {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Surfaces
    )

    $seen = @{}
    $snapshots = foreach ($surface in @($Surfaces)) {
        $id = [string](Get-Phase00E1PropertyValue -Object $surface -Name 'Id')
        $path = [string](Get-Phase00E1PropertyValue -Object $surface -Name 'Path')
        if ($id -notmatch '^LIVE_HOME_[1-9][0-9]*$') {
            throw "Invalid E1 live-home surface id: $id"
        }
        if ($seen.ContainsKey($id)) {
            throw "Duplicate E1 live-home surface id: $id"
        }
        $seen[$id] = $true
        if ([string]::IsNullOrWhiteSpace($path) -or -not [IO.Path]::IsPathRooted($path)) {
            throw "E1 live-home surface must be absolute: $id"
        }
        [pscustomobject][ordered]@{
            Id = $id
            Path = [IO.Path]::GetFullPath($path).TrimEnd('\','/')
            Snapshot = Get-Phase00E1DirectorySnapshot -Path $path
        }
    }
    return @($snapshots)
}

function Compare-Phase00E1LiveHomeSnapshots {
    param(
        [Parameter(Mandatory)][object[]]$Before,
        [Parameter(Mandatory)][object[]]$After
    )

    $beforeById = @{}
    $afterById = @{}
    foreach ($surface in @($Before)) { $beforeById[[string]$surface.Id] = $surface }
    foreach ($surface in @($After)) { $afterById[[string]$surface.Id] = $surface }
    $ids = @($beforeById.Keys + $afterById.Keys | Sort-Object -Unique)
    $records = foreach ($id in $ids) {
        if (-not $beforeById.ContainsKey($id) -or -not $afterById.ContainsKey($id)) {
            [pscustomobject][ordered]@{
                Id = [string]$id
                Unchanged = $false
                BeforeExists = $beforeById.ContainsKey($id)
                AfterExists = $afterById.ContainsKey($id)
                BeforeFileCount = $null
                AfterFileCount = $null
                BeforeSha256 = $null
                AfterSha256 = $null
                ChangedCount = 1
            }
            continue
        }
        $left = $beforeById[$id]
        $right = $afterById[$id]
        if (-not ([string]$left.Path).Equals(
            [string]$right.Path,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            throw "E1 live-home snapshot path changed for surface $id."
        }
        $comparison = Compare-Phase00E1DirectorySnapshot `
            -Before $left.Snapshot -After $right.Snapshot
        [pscustomobject][ordered]@{
            Id = [string]$id
            Unchanged = [bool]$comparison.Unchanged
            BeforeExists = [bool]$left.Snapshot.Exists
            AfterExists = [bool]$right.Snapshot.Exists
            BeforeFileCount = [int]$comparison.BeforeFileCount
            AfterFileCount = [int]$comparison.AfterFileCount
            BeforeSha256 = [string]$comparison.BeforeSha256
            AfterSha256 = [string]$comparison.AfterSha256
            ChangedCount = [int]$comparison.ChangedCount
        }
    }
    $changed = @($records | Where-Object { -not $_.Unchanged })
    return [pscustomobject][ordered]@{
        Unchanged = ($changed.Count -eq 0)
        SurfaceCount = @($records).Count
        ChangedCount = $changed.Count
        Surfaces = @($records)
    }
}

function Get-Phase00E1SecretValues {
    $fixedNames = @(
        'OPENAI_API_KEY','ANTHROPIC_API_KEY','ANTHROPIC_OAUTH_TOKEN',
        'GEMINI_API_KEY','OMNIROUTE_API_KEY','OMP_AUTH_BROKER_TOKEN'
    )
    $dynamicNames = @(
        [Environment]::GetEnvironmentVariables('Process').Keys |
            ForEach-Object { [string]$_ } |
            Where-Object { $_ -match '(?i)(API_KEY|TOKEN|SECRET|PASSWORD|AUTHORIZATION)$' }
    )
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $values = [Collections.Generic.List[string]]::new()
    foreach ($name in @($fixedNames + $dynamicNames | Sort-Object -Unique)) {
        $value = [Environment]::GetEnvironmentVariable($name,'Process')
        if ([string]::IsNullOrEmpty($value) -or $value.Length -lt 8) { continue }
        if ($seen.Add($value)) { $values.Add($value) }
    }
    return [string[]]@($values)
}

function Write-Phase00E1RunEnvelope {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Envelope,
        [AllowEmptyCollection()][string[]]$SecretValues = @(),
        [AllowEmptyCollection()][string[]]$PrivatePaths = @()
    )

    $resolved = [IO.Path]::GetFullPath($Path)
    if (Test-Path -LiteralPath $resolved) {
        throw "E1 run-envelope destination already exists: $resolved"
    }
    $parent = Split-Path -Parent $resolved
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        throw "E1 run-envelope parent does not exist: $parent"
    }
    $json = ($Envelope | ConvertTo-Json -Depth 100).Replace("`r`n","`n").TrimEnd("`r","`n") + "`n"
    try {
        $parsed = $json | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw 'E1 run envelope is not valid JSON.'
    }
    if ((Get-Phase00E1JsonValueKind -JsonText $json) -ne 'object' -or $null -eq $parsed) {
        throw 'E1 run envelope must be one JSON object.'
    }
    foreach ($privatePath in @($PrivatePaths)) {
        if ([string]::IsNullOrWhiteSpace($privatePath)) { continue }
        $fullPrivatePath = [IO.Path]::GetFullPath($privatePath).TrimEnd('\','/')
        $pathVariants = @(
            $fullPrivatePath,
            $fullPrivatePath.Replace('\','/'),
            $fullPrivatePath.Replace('/','\'),
            $fullPrivatePath.Replace('\','\\')
        ) | Sort-Object -Unique
        foreach ($variant in $pathVariants) {
            if ($json.IndexOf($variant,[StringComparison]::OrdinalIgnoreCase) -ge 0) {
                throw 'E1 run envelope contains a private absolute path.'
            }
        }
    }
    foreach ($secret in @($SecretValues)) {
        if (Test-Phase00E1TextContainsSecret -Text $json -Secret $secret) {
            throw 'E1 run envelope contains an exact secret value.'
        }
    }

    $stream = [IO.FileStream]::new(
        $resolved,
        [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write,
        [IO.FileShare]::None
    )
    $writer = [IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
    try {
        $writer.Write($json)
    } finally {
        $writer.Dispose()
    }
    return [pscustomobject][ordered]@{
        Sha256 = Get-Phase00E1FileSha256 -Path $resolved
        Length = (Get-Item -LiteralPath $resolved).Length
    }
}

function Get-Phase00E1ForwarderPrerequisite {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $repository = [IO.Path]::GetFullPath($RepositoryRoot)
    $sourcePath = Join-Path $repository 'scripts\lib\phase00-e1-forwarder.mjs'
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "E1 forwarder source does not exist: $sourcePath"
    }
    $expectedHash = 'D9CDAEB5FF4235658D10AD8371410E7F480ADEBDCD85C0F0EA13BFFCD53FA483'
    $actualHash = Get-Phase00E1FileSha256 -Path $sourcePath
    if ($actualHash -ine $expectedHash) {
        throw "E1 forwarder SHA-256 mismatch: $actualHash"
    }
    $node = Get-Command node -CommandType Application -ErrorAction Stop
    $nodePath = [IO.Path]::GetFullPath($node.Source)
    return [pscustomobject][ordered]@{
        SourcePath = [IO.Path]::GetFullPath($sourcePath)
        SourceSha256 = $actualHash
        NodePath = $nodePath
        NodeSha256 = Get-Phase00E1FileSha256 -Path $nodePath
    }
}

function Test-Phase00E1LoopbackPortClosed {
    param(
        [Parameter(Mandatory)][ValidateRange(1,65535)][int]$Port,
        [ValidateRange(1,50)][int]$Attempts = 10
    )

    for ($attempt = 1; $attempt -le $Attempts; $attempt += 1) {
        $client = [Net.Sockets.TcpClient]::new()
        try {
            $task = $client.ConnectAsync('127.0.0.1',$Port)
            if ($task.Wait(200) -and $client.Connected) { return $false }
        } catch {
            return $true
        } finally {
            $client.Dispose()
        }
        Start-Sleep -Milliseconds 100
    }
    return $true
}

function Start-Phase00E1Forwarder {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)][bool]$PiNoStrictEffective,
        [string]$TargetOrigin = 'http://127.0.0.1:20128',
        $Prerequisite
    )

    $resolvedOutput = Assert-Phase00E1DisposableDescendant `
        -Path $OutputPath -TempRoot ([IO.Path]::GetTempPath())
    if (Test-Path -LiteralPath $resolvedOutput) {
        throw "E1 forwarder capture already exists: $resolvedOutput"
    }
    $parent = Split-Path -Parent $resolvedOutput
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        throw "E1 forwarder capture parent does not exist: $parent"
    }
    if ($null -eq $Prerequisite) {
        $Prerequisite = Get-Phase00E1ForwarderPrerequisite `
            -RepositoryRoot $RepositoryRoot
    }
    $target = $null
    try { $target = [Uri]$TargetOrigin } catch {
        throw 'E1 forwarder target origin is invalid.'
    }
    if (
        $target.Scheme -notin @('http','https') -or
        $target.Host -cne '127.0.0.1' -or
        $target.IsDefaultPort -or
        $target.AbsolutePath -cne '/' -or
        -not [string]::IsNullOrEmpty($target.Query) -or
        -not [string]::IsNullOrEmpty($target.Fragment) -or
        -not [string]::IsNullOrEmpty($target.UserInfo)
    ) {
        throw 'E1 forwarder target must be an HTTP(S) 127.0.0.1 origin with an explicit port.'
    }

    $arguments = @(
        [string]$Prerequisite.SourcePath,
        '--listen','127.0.0.1:0',
        '--target',$TargetOrigin,
        '--output',$resolvedOutput,
        '--pi-no-strict',$(if ($PiNoStrictEffective) { 'true' } else { 'false' })
    )
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = [string]$Prerequisite.NodePath
    $startInfo.WorkingDirectory = [IO.Path]::GetFullPath($RepositoryRoot)
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    [void]$startInfo.EnvironmentVariables.Remove('NODE_OPTIONS')
    [void]$startInfo.EnvironmentVariables.Remove('PI_NO_STRICT')
    if ($null -ne $startInfo.PSObject.Properties['ArgumentList']) {
        foreach ($argument in $arguments) {
            [void]$startInfo.ArgumentList.Add([string]$argument)
        }
    } else {
        $startInfo.Arguments = @($arguments | ForEach-Object {
            ConvertTo-Phase00E1WindowsArgument -Argument ([string]$_)
        }) -join ' '
    }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $started = $false
    try {
        if (-not $process.Start()) { throw 'E1 forwarder process did not start.' }
        $started = $true
        $readyTask = $process.StandardOutput.ReadLineAsync()
        if (-not $readyTask.Wait(10000)) {
            throw 'E1 forwarder did not announce readiness within ten seconds.'
        }
        $readyLine = [string]$readyTask.GetAwaiter().GetResult()
        if ([string]::IsNullOrWhiteSpace($readyLine)) {
            throw 'E1 forwarder readiness line is empty.'
        }
        try { $ready = $readyLine | ConvertFrom-Json -ErrorAction Stop } catch {
            throw 'E1 forwarder readiness line is not JSON.'
        }
        $readyNames = @($ready.PSObject.Properties.Name | Sort-Object)
        if (($readyNames -join ',') -cne 'listen_host,listen_port,record_type' -or
            [string]$ready.record_type -cne 'phase00_e1_forwarder_ready' -or
            [string]$ready.listen_host -cne '127.0.0.1' -or
            [int]$ready.listen_port -lt 1 -or [int]$ready.listen_port -gt 65535) {
            throw 'E1 forwarder readiness record violates the pinned contract.'
        }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        return [pscustomobject][ordered]@{
            Process = $process
            ProcessId = [int]$process.Id
            StartedAt = [DateTimeOffset]::Now
            ListenHost = [string]$ready.listen_host
            ListenPort = [int]$ready.listen_port
            OutputPath = $resolvedOutput
            StdoutTask = $stdoutTask
            StderrTask = $stderrTask
            SourceSha256 = [string]$Prerequisite.SourceSha256
            NodeSha256 = [string]$Prerequisite.NodeSha256
            PiNoStrictEffective = $PiNoStrictEffective
        }
    } catch {
        if ($started -and -not $process.HasExited) {
            try { Stop-Phase00E1ProcessTree -Process $process } catch {}
            try { [void]$process.WaitForExit(5000) } catch {}
        }
        $process.Dispose()
        throw
    }
}

function Stop-Phase00E1Forwarder {
    param([Parameter(Mandatory)]$Handle)

    $process = $Handle.Process
    $timedOut = $false
    $descendantsObserved = @()
    try {
        if (-not $process.HasExited) {
            try {
                $process.StandardInput.WriteLine('close')
                $process.StandardInput.Flush()
                $process.StandardInput.Close()
            } catch {}
            if (-not $process.WaitForExit(15000)) {
                $timedOut = $true
                $descendantsObserved = @(Get-Phase00E1DescendantProcessIds `
                    -ParentProcessId ([int]$process.Id))
                Stop-Phase00E1ProcessTree -Process $process
                [void]$process.WaitForExit(10000)
            }
        }
        if (-not $process.HasExited) {
            throw 'E1 forwarder did not terminate.'
        }
        $process.WaitForExit()
        if (-not $Handle.StdoutTask.Wait(10000) -or -not $Handle.StderrTask.Wait(10000)) {
            throw 'E1 forwarder streams did not close.'
        }
        $stdoutRemainder = [string]$Handle.StdoutTask.GetAwaiter().GetResult()
        $stderr = [string]$Handle.StderrTask.GetAwaiter().GetResult()
        $remaining = @($descendantsObserved | Where-Object {
            $null -ne (Get-Process -Id $_ -ErrorAction SilentlyContinue)
        })
        $records = [Collections.Generic.List[object]]::new()
        if (Test-Path -LiteralPath $Handle.OutputPath -PathType Leaf) {
            foreach ($line in [IO.File]::ReadLines([string]$Handle.OutputPath)) {
                if ([string]::IsNullOrWhiteSpace($line)) {
                    throw 'E1 forwarder capture contains an empty line.'
                }
                try { $record = $line | ConvertFrom-Json -ErrorAction Stop } catch {
                    throw 'E1 forwarder capture contains an unparseable line.'
                }
                if ((Get-Phase00E1JsonValueKind -JsonText $line) -ne 'object') {
                    throw 'E1 forwarder capture contains a non-object line.'
                }
                $records.Add($record)
            }
        }
        $types = [string[]]@($records | ForEach-Object { [string]$_.record_type })
        $readyRecords = @($records | Where-Object {
            [string]$_.record_type -ceq 'phase00_e1_forwarder_ready'
        })
        $closedRecords = @($records | Where-Object {
            [string]$_.record_type -ceq 'phase00_e1_forwarder_closed'
        })
        $projectionCount = @($records | Where-Object {
            [string]$_.record_type -ceq 'phase00_e1_request_projection'
        }).Count
        $portClosed = Test-Phase00E1LoopbackPortClosed -Port ([int]$Handle.ListenPort)
        $lifecycleValid = (
            $readyRecords.Count -eq 1 -and
            $closedRecords.Count -eq 1 -and
            $types.Count -ge 2 -and
            $types[0] -ceq 'phase00_e1_forwarder_ready' -and
            $types[$types.Count - 1] -ceq 'phase00_e1_forwarder_closed' -and
            [int]$readyRecords[0].listen_port -eq [int]$Handle.ListenPort -and
            [int]$closedRecords[0].listen_port -eq [int]$Handle.ListenPort -and
            [string]$readyRecords[0].listen_host -ceq '127.0.0.1' -and
            [string]$closedRecords[0].listen_host -ceq '127.0.0.1' -and
            $process.ExitCode -eq 0 -and
            -not $timedOut -and
            $remaining.Count -eq 0 -and
            $portClosed -and
            [string]::IsNullOrEmpty($stdoutRemainder) -and
            [string]::IsNullOrEmpty($stderr)
        )
        return [pscustomobject][ordered]@{
            ProcessId = [int]$Handle.ProcessId
            ExitCode = [int]$process.ExitCode
            TimedOut = $timedOut
            DescendantPidsObserved = [int[]]@($descendantsObserved)
            RemainingChildPids = [int[]]@($remaining)
            ListenHost = [string]$Handle.ListenHost
            ListenPort = [int]$Handle.ListenPort
            PortClosed = $portClosed
            ProjectionCount = $projectionCount
            RecordCount = $records.Count
            RecordTypes = $types
            StdoutRemainderSha256 = Get-Phase00E1StringSha256 -Text $stdoutRemainder
            StderrSha256 = Get-Phase00E1StringSha256 -Text $stderr
            LifecycleValid = $lifecycleValid
        }
    } finally {
        if (-not $process.HasExited) {
            try { Stop-Phase00E1ProcessTree -Process $process } catch {}
            try { [void]$process.WaitForExit(5000) } catch {}
        }
        $process.Dispose()
    }
}

function Set-Phase00E1DisposableModelCatalog {
    param(
        [Parameter(Mandatory)]$Fixture,
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$ProviderBaseUrl
    )

    $catalogPath = Assert-Phase00E1DisposableDescendant `
        -Path ([string]$Fixture.ModelCatalogPath) `
        -TempRoot ([IO.Path]::GetTempPath())
    if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
        throw "E1 disposable model catalog does not exist: $catalogPath"
    }
    $sourcePath = Join-Path ([IO.Path]::GetFullPath($RepositoryRoot)) `
        'docs\evidence\phase-00\environment\runtime-models.yml'
    $text = Get-Phase00E1SanitizedModelCatalogText `
        -SourcePath $sourcePath -ProviderBaseUrl $ProviderBaseUrl
    [IO.File]::WriteAllText(
        $catalogPath,
        $text,
        [Text.UTF8Encoding]::new($false)
    )
    $hash = Get-Phase00E1FileSha256 -Path $catalogPath
    if ([IO.File]::ReadAllText($catalogPath).Replace("`r`n","`n") -cne $text) {
        throw 'E1 disposable model catalog verification failed.'
    }
    $Fixture.ModelCatalogText = $text
    $Fixture.ModelCatalogSha256 = $hash
    $Fixture.ProviderBaseUrl = $ProviderBaseUrl
    return $hash
}

function Get-Phase00E1RepositoryRelativePath {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$Path
    )

    $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\','/')
    $target = [IO.Path]::GetFullPath($Path)
    $prefix = $root + [IO.Path]::DirectorySeparatorChar
    if (-not $target.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'E1 evidence path is outside the repository.'
    }
    return $target.Substring($prefix.Length).Replace('\','/')
}

function Read-Phase00E1JsonLineObjects {
    param([Parameter(Mandatory)][string]$Path)

    $records = [Collections.Generic.List[object]]::new()
    foreach ($line in [IO.File]::ReadLines([IO.Path]::GetFullPath($Path))) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            throw 'E1 JSONL artifact contains an empty line.'
        }
        if ((Get-Phase00E1JsonValueKind -JsonText $line) -ne 'object') {
            throw 'E1 JSONL artifact contains a non-object line.'
        }
        try { $record = $line | ConvertFrom-Json -ErrorAction Stop } catch {
            throw 'E1 JSONL artifact contains an unparseable line.'
        }
        $records.Add($record)
    }
    return @($records)
}

function Read-Phase00E1JsonLineEntries {
    param([Parameter(Mandatory)][string]$Path)

    $resolved = [IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        throw "E1_JSONL_ARTIFACT_MISSING: $resolved"
    }
    $entries = [Collections.Generic.List[object]]::new()
    $lineNumber = 0
    foreach ($line in [IO.File]::ReadLines($resolved)) {
        $lineNumber += 1
        if ([string]::IsNullOrWhiteSpace($line)) {
            throw "E1_JSONL_EMPTY_LINE: $resolved`:$lineNumber"
        }
        if ((Get-Phase00E1JsonValueKind -JsonText $line) -ne 'object') {
            throw "E1_JSONL_NON_OBJECT: $resolved`:$lineNumber"
        }
        try { $value = $line | ConvertFrom-Json -ErrorAction Stop } catch {
            throw "E1_JSONL_UNPARSEABLE: $resolved`:$lineNumber"
        }
        $entries.Add([pscustomobject][ordered]@{
            Path = $resolved
            LineNumber = $lineNumber
            Value = $value
        })
    }
    return @($entries)
}

function ConvertTo-Phase00E1CanonicalJsonNode {
    param([AllowNull()]$Value)

    if ($null -eq $Value -or $Value -is [string] -or $Value -is [char] -or
        $Value -is [bool] -or $Value -is [ValueType]) {
        return $Value
    }
    if ($Value -is [Collections.IDictionary]) {
        $mapping = [ordered]@{}
        foreach ($key in @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object)) {
            $mapping[$key] = ConvertTo-Phase00E1CanonicalJsonNode -Value $Value[$key]
        }
        return $mapping
    }
    if ($Value -is [pscustomobject]) {
        $mapping = [ordered]@{}
        foreach ($property in @($Value.PSObject.Properties | Sort-Object Name)) {
            $mapping[$property.Name] = ConvertTo-Phase00E1CanonicalJsonNode `
                -Value $property.Value
        }
        return $mapping
    }
    if ($Value -is [Collections.IEnumerable]) {
        $items = @($Value | ForEach-Object {
            ConvertTo-Phase00E1CanonicalJsonNode -Value $_
        })
        return ,$items
    }
    throw "E1_CANONICAL_JSON_UNSUPPORTED_TYPE: $($Value.GetType().FullName)"
}

function ConvertTo-Phase00E1CanonicalJsonText {
    param([AllowNull()]$Value)

    $canonical = ConvertTo-Phase00E1CanonicalJsonNode -Value $Value
    return $canonical | ConvertTo-Json -Compress -Depth 100
}

function Get-Phase00E1CanonicalObjectSha256 {
    param([AllowNull()]$Value)

    return Get-Phase00E1StringSha256 `
        -Text (ConvertTo-Phase00E1CanonicalJsonText -Value $Value)
}

function ConvertTo-Phase00E1StructuredResultEvidence {
    param(
        [Parameter(Mandatory)]$Result,
        [Parameter(Mandatory)][string]$OriginPath,
        [Parameter(Mandatory)][ValidateRange(1,2147483647)][int]$LineNumber
    )

    $structuredOutput = Get-Phase00E1PropertyValue `
        -Object $Result -Name 'structuredOutput'
    $isAsyncAcknowledgement = $null -eq $structuredOutput -and (
        [string](Get-Phase00E1PropertyValue -Object $Result -Name 'status') -in
            @('accepted','queued','running') -or
        (Test-Phase00E1HasProperty -Object $Result -Name 'taskId')
    )
    return [pscustomobject][ordered]@{
        Id = [string](Get-Phase00E1PropertyValue -Object $Result -Name 'id')
        Agent = [string](Get-Phase00E1PropertyValue -Object $Result -Name 'agent')
        IsAsyncAcknowledgement = [bool]$isAsyncAcknowledgement
        StructuredOutput = $structuredOutput
        OriginPath = [IO.Path]::GetFullPath($OriginPath)
        LineNumber = $LineNumber
        RawResult = $Result
    }
}

function Get-Phase00E1DirectTaskExecutionProjection {
    param([Parameter(Mandatory)][string]$Path)

    $entries = @(Read-Phase00E1JsonLineEntries -Path $Path)
    $calls = @(Get-Phase00E1TaskCalls -EventPaths @($Path))
    $callsById = @{}
    foreach ($call in $calls) {
        if ($callsById.ContainsKey([string]$call.ToolCallId)) {
            throw "E1_TASK_CALL_ID_DUPLICATE: $Path"
        }
        $callsById[[string]$call.ToolCallId] = $call
    }
    $endsById = @{}
    foreach ($entry in $entries) {
        $event = $entry.Value
        if ([string](Get-Phase00E1PropertyValue -Object $event -Name 'type') -cne
                'tool_execution_end' -or
            [string](Get-Phase00E1PropertyValue -Object $event -Name 'toolName') -cne
                'task') {
            continue
        }
        $toolCallId = [string](Get-Phase00E1PropertyValue `
            -Object $event -Name 'toolCallId')
        if ([string]::IsNullOrWhiteSpace($toolCallId) -or
            $endsById.ContainsKey($toolCallId)) {
            throw "E1_TASK_END_ID_INVALID: $Path`:$($entry.LineNumber)"
        }
        $endsById[$toolCallId] = $entry
    }

    $executions = [Collections.Generic.List[object]]::new()
    $results = [Collections.Generic.List[object]]::new()
    foreach ($call in $calls) {
        $end = if ($endsById.ContainsKey([string]$call.ToolCallId)) {
            $endsById[[string]$call.ToolCallId]
        } else { $null }
        $directResults = [Collections.Generic.List[object]]::new()
        if ($null -ne $end) {
            $resultEnvelope = Get-Phase00E1PropertyValue `
                -Object $end.Value -Name 'result'
            $details = Get-Phase00E1PropertyValue `
                -Object $resultEnvelope -Name 'details'
            foreach ($rawResult in @(Get-Phase00E1PropertyValue `
                -Object $details -Name 'results')) {
                if ($null -eq $rawResult) { continue }
                $normalized = ConvertTo-Phase00E1StructuredResultEvidence `
                    -Result $rawResult -OriginPath $Path `
                    -LineNumber ([int]$end.LineNumber)
                $directResults.Add($normalized)
                $results.Add($normalized)
            }
        }
        $executions.Add([pscustomobject][ordered]@{
            Call = $call
            End = $end
            Results = @($directResults)
        })
    }
    foreach ($endId in $endsById.Keys) {
        if (-not $callsById.ContainsKey([string]$endId)) {
            throw "E1_TASK_END_WITHOUT_START: $Path"
        }
    }
    return [pscustomobject][ordered]@{
        Path = [IO.Path]::GetFullPath($Path)
        Entries = @($entries)
        Calls = @($calls)
        Executions = @($executions)
        Results = @($results)
    }
}

function Get-Phase00E1FixtureJsonBlock {
    param([Parameter(Mandatory)][string]$Path)

    $resolved = [IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        throw "E1_FIXTURE_JSON_BLOCK_SOURCE_MISSING: $resolved"
    }
    $text = [IO.File]::ReadAllText($resolved).Replace("`r`n","`n")
    $matches = [regex]::Matches($text,'(?ms)^```json\n(?<json>\{.*?\})\n```$')
    if ($matches.Count -ne 1) {
        throw "E1_FIXTURE_JSON_BLOCK_COUNT: $resolved"
    }
    try {
        return $matches[0].Groups['json'].Value | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "E1_FIXTURE_JSON_BLOCK_INVALID: $resolved"
    }
}

function Get-Phase00E1PersistedSessionProjection {
    param([Parameter(Mandatory)][string]$Path)

    $entries = @(Read-Phase00E1JsonLineEntries -Path $Path)
    $sessionInitEntries = @($entries | Where-Object {
        [string](Get-Phase00E1PropertyValue -Object $_.Value -Name 'type') -ceq 'session_init'
    })
    if ($sessionInitEntries.Count -gt 1) {
        throw "E1_SESSION_INIT_COUNT: $Path"
    }
    $sessionInit = if ($sessionInitEntries.Count -eq 1) {
        $sessionInitEntries[0]
    } else { $null }
    $agent = if ($null -eq $sessionInit) { $null } else {
        [string](Get-Phase00E1PropertyValue -Object $sessionInit.Value -Name 'agent')
    }
    $resolvedModel = if ($null -eq $sessionInit) { $null } else {
        [string](Get-Phase00E1PropertyValue `
            -Object $sessionInit.Value -Name 'resolvedModel')
    }

    $events = [Collections.Generic.List[object]]::new()
    $assistantEntries = [Collections.Generic.List[object]]::new()
    $taskCalls = [Collections.Generic.List[object]]::new()
    $yieldCalls = [Collections.Generic.List[object]]::new()
    $toolResultsById = @{}
    foreach ($entry in $entries) {
        $record = $entry.Value
        if ([string](Get-Phase00E1PropertyValue -Object $record -Name 'type') -cne 'message') {
            continue
        }
        $message = Get-Phase00E1PropertyValue -Object $record -Name 'message'
        $role = [string](Get-Phase00E1PropertyValue -Object $message -Name 'role')
        if ($role -ceq 'toolResult') {
            $toolCallId = [string](Get-Phase00E1PropertyValue `
                -Object $message -Name 'toolCallId')
            if ([string]::IsNullOrWhiteSpace($toolCallId) -or
                $toolResultsById.ContainsKey($toolCallId)) {
                throw "E1_SESSION_TOOL_RESULT_ID_INVALID: $Path`:$($entry.LineNumber)"
            }
            $toolResultsById[$toolCallId] = $entry
            continue
        }
        if ($role -cne 'assistant') { continue }
        $assistantEntries.Add($entry)
        foreach ($contentItem in @(Get-Phase00E1PropertyValue `
            -Object $message -Name 'content')) {
            if ([string](Get-Phase00E1PropertyValue `
                -Object $contentItem -Name 'type') -cne 'toolCall') { continue }
            $toolName = [string](Get-Phase00E1PropertyValue `
                -Object $contentItem -Name 'name')
            $toolCallId = [string](Get-Phase00E1PropertyValue `
                -Object $contentItem -Name 'id')
            $arguments = Get-Phase00E1PropertyValue `
                -Object $contentItem -Name 'arguments'
            if ([string]::IsNullOrWhiteSpace($toolCallId)) {
                throw "E1_SESSION_TOOL_CALL_ID_MISSING: $Path`:$($entry.LineNumber)"
            }
            if ($toolName -ceq 'task') {
                $canonical = Get-Phase00E1CanonicalTaskArguments -Arguments $arguments
                $taskCalls.Add([pscustomobject][ordered]@{
                    ToolCallId = $toolCallId
                    Agent = [string](Get-Phase00E1PropertyValue `
                        -Object $canonical.Arguments -Name 'agent')
                    CanonicalArguments = $canonical.Arguments
                    ArgumentNames = [string[]]@($canonical.Names)
                    HasOutputSchema = [bool]$canonical.HasOutputSchema
                    OutputSchema = $canonical.OutputSchema
                    OriginPath = [IO.Path]::GetFullPath($Path)
                    LineNumber = [int]$entry.LineNumber
                    RawEvent = $record
                })
            } elseif ($toolName -ceq 'yield') {
                $yieldCalls.Add([pscustomobject][ordered]@{
                    ToolCallId = $toolCallId
                    Arguments = $arguments
                    OriginPath = [IO.Path]::GetFullPath($Path)
                    LineNumber = [int]$entry.LineNumber
                })
            }
        }
    }

    $pendingRecovery = $null
    foreach ($entry in $assistantEntries) {
        $message = Get-Phase00E1PropertyValue -Object $entry.Value -Name 'message'
        $events.Add([pscustomobject][ordered]@{
            type='message_start';message=$message;e1_origin_line=[int]$entry.LineNumber
        })
        $events.Add([pscustomobject][ordered]@{
            type='message_end';message=$message;e1_origin_line=[int]$entry.LineNumber
        })
        $stopReason = [string](Get-Phase00E1PropertyValue `
            -Object $message -Name 'stopReason')
        if ($null -ne $pendingRecovery -and $stopReason -in @('stop','toolUse')) {
            $events.Add([pscustomobject][ordered]@{
                type='auto_retry_end';attempt=[int]$pendingRecovery.Attempt
                success=$true;e1_origin_line=[int]$entry.LineNumber
            })
            $pendingRecovery = $null
        }
        $recovery = Get-Phase00E1PropertyValue -Object $message -Name 'retryRecovery'
        if ($null -ne $recovery -and
            [string](Get-Phase00E1PropertyValue `
                -Object $recovery -Name 'status') -ceq 'recovered') {
            if ($null -ne $pendingRecovery) {
                throw "E1_SESSION_RETRY_CHAIN_AMBIGUOUS: $Path`:$($entry.LineNumber)"
            }
            $attempt = [int](Get-Phase00E1PropertyValue `
                -Object $recovery -Name 'attempt')
            $events.Add([pscustomobject][ordered]@{
                type='auto_retry_start';attempt=$attempt;maxAttempts=0
                errorId=Get-Phase00E1PropertyValue -Object $message -Name 'errorId'
                errorMessage=[string](Get-Phase00E1PropertyValue `
                    -Object $message -Name 'errorMessage')
                e1_origin_line=[int]$entry.LineNumber
            })
            $pendingRecovery = [pscustomobject]@{Attempt=$attempt}
        }
    }
    if ($null -ne $pendingRecovery) {
        throw "E1_SESSION_RECOVERY_NOT_SUPERSEDED: $Path"
    }
    $ledger = Get-Phase00E1ProviderLedger -Events ([object[]]@($events))

    $yieldAttempts = [Collections.Generic.List[object]]::new()
    $schemaOverrideCount = 0
    for ($index = 0; $index -lt $yieldCalls.Count; $index += 1) {
        $call = $yieldCalls[$index]
        $toolResultEntry = if ($toolResultsById.ContainsKey($call.ToolCallId)) {
            $toolResultsById[$call.ToolCallId]
        } else { $null }
        $resultObject = Get-Phase00E1PropertyValue `
            -Object $call.Arguments -Name 'result'
        $data = Get-Phase00E1PropertyValue -Object $resultObject -Name 'data'
        $yieldType = Get-Phase00E1PropertyValue -Object $call.Arguments -Name 'type'
        $terminal = -not (
            $null -ne $yieldType -and
            $yieldType -is [Collections.IEnumerable] -and
            -not ($yieldType -is [string])
        )
        $classification = if ($null -eq $toolResultEntry) { 'missing_tool_result' } else {
            [string](Get-Phase00E1PropertyValue `
                -Object (Get-Phase00E1PropertyValue `
                    -Object $toolResultEntry.Value -Name 'message') `
                -Name 'e1_tool_error_classification')
        }
        $resultMessage = if ($null -eq $toolResultEntry) { $null } else {
            Get-Phase00E1PropertyValue -Object $toolResultEntry.Value -Name 'message'
        }
        $isError = if ($null -eq $resultMessage) { $null } else {
            Get-Phase00E1PropertyValue -Object $resultMessage -Name 'isError'
        }
        $details = if ($null -eq $resultMessage) { $null } else {
            Get-Phase00E1PropertyValue -Object $resultMessage -Name 'details'
        }
        if ((Get-Phase00E1PropertyValue `
            -Object $details -Name 'schemaOverridden') -eq $true) {
            $schemaOverrideCount += 1
        }
        $rejected = $isError -eq $true -and $classification -ceq 'yield_schema_validation'
        $yieldAttempts.Add([pscustomobject][ordered]@{
            Index = $index + 1
            ProviderReturned = $true
            Terminal = $terminal
            Data = $data
            LocalValidationRejected = $rejected
            LocalValidationReason = if ($rejected) {
                'schema'
            } elseif ($isError -eq $true) {
                if ([string]::IsNullOrWhiteSpace($classification)) {'other'} else {$classification}
            } elseif ($null -eq $toolResultEntry) {'missing_tool_result'} else {$null}
            OriginPath = [string]$call.OriginPath
            LineNumber = [int]$call.LineNumber
            ToolResultLineNumber = if ($null -eq $toolResultEntry) {
                0
            } else { [int]$toolResultEntry.LineNumber }
        })
    }
    $localRejections = @($yieldAttempts | Where-Object LocalValidationRejected)
    $localRetries = @($localRejections | Where-Object {
        [int]$_.Index -lt $yieldAttempts.Count
    })
    $taskExecutions = [Collections.Generic.List[object]]::new()
    foreach ($taskCall in $taskCalls) {
        $toolResultEntry = if ($toolResultsById.ContainsKey($taskCall.ToolCallId)) {
            $toolResultsById[$taskCall.ToolCallId]
        } else { $null }
        $directResults = [Collections.Generic.List[object]]::new()
        if ($null -ne $toolResultEntry) {
            $resultMessage = Get-Phase00E1PropertyValue `
                -Object $toolResultEntry.Value -Name 'message'
            $details = Get-Phase00E1PropertyValue `
                -Object $resultMessage -Name 'details'
            foreach ($rawResult in @(Get-Phase00E1PropertyValue `
                -Object $details -Name 'results')) {
                if ($null -eq $rawResult) { continue }
                $directResults.Add((ConvertTo-Phase00E1StructuredResultEvidence `
                    -Result $rawResult -OriginPath $Path `
                    -LineNumber ([int]$toolResultEntry.LineNumber)))
            }
        }
        $taskExecutions.Add([pscustomobject][ordered]@{
            Call = $taskCall
            ToolResultLineNumber = if ($null -eq $toolResultEntry) {
                0
            } else { [int]$toolResultEntry.LineNumber }
            Results = @($directResults)
        })
    }
    return [pscustomobject][ordered]@{
        Path = [IO.Path]::GetFullPath($Path)
        Agent = $agent
        ResolvedModel = $resolvedModel
        SessionInitLine = if ($null -eq $sessionInit) { 0 } else {
            [int]$sessionInit.LineNumber
        }
        Entries = @($entries)
        NormalizedEvents = @($events)
        ProviderMessageEntries = @($assistantEntries)
        ProviderLedger = $ledger
        TaskCalls = @($taskCalls)
        TaskExecutions = @($taskExecutions)
        YieldAttempts = @($yieldAttempts)
        LocalSchemaRejectionCount = $localRejections.Count
        LocalSchemaRetryCount = $localRetries.Count
        SchemaOverrideCount = $schemaOverrideCount
    }
}

function Resolve-Phase00E1RawArtifactPath {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath) -or
        [IO.Path]::IsPathRooted($RelativePath) -or
        $RelativePath.IndexOf('\') -ge 0 -or
        $RelativePath.StartsWith('/',[StringComparison]::Ordinal) -or
        $RelativePath.EndsWith('/',[StringComparison]::Ordinal)) {
        throw "E1_ARTIFACT_PATH_INVALID: $RelativePath"
    }
    $segments = $RelativePath.Split('/')
    if ($segments.Count -eq 0 -or @($segments | Where-Object {
        [string]::IsNullOrWhiteSpace($_) -or $_ -in @('.','..')
    }).Count -gt 0) {
        throw "E1_ARTIFACT_PATH_INVALID: $RelativePath"
    }
    $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\','/')
    $candidate = [IO.Path]::GetFullPath((Join-Path $root `
        $RelativePath.Replace('/',[IO.Path]::DirectorySeparatorChar)))
    $prefix = $root + [IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) {
        throw "E1_ARTIFACT_PATH_INVALID: $RelativePath"
    }
    $canonical = Get-Phase00E1RepositoryRelativePath `
        -RepositoryRoot $root -Path $candidate
    if (-not $canonical.Equals($RelativePath,[StringComparison]::OrdinalIgnoreCase)) {
        throw "E1_ARTIFACT_PATH_INVALID: $RelativePath"
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw "E1_ARTIFACT_MISSING: $RelativePath"
    }
    $cursorPath = $candidate
    while (-not $cursorPath.TrimEnd('\','/').Equals(
        $root,[StringComparison]::OrdinalIgnoreCase)) {
        $cursorItem = Get-Item -LiteralPath $cursorPath -Force
        if (($cursorItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "E1_ARTIFACT_PATH_INVALID: reparse point in $RelativePath"
        }
        $parentPath = Split-Path -Parent $cursorPath
        if ([string]::IsNullOrWhiteSpace($parentPath) -or
            $parentPath.Equals($cursorPath,[StringComparison]::OrdinalIgnoreCase)) {
            throw "E1_ARTIFACT_PATH_INVALID: $RelativePath"
        }
        $cursorPath = [IO.Path]::GetFullPath($parentPath)
    }
    return $candidate
}

function Get-Phase00E1FileLineCount {
    param([Parameter(Mandatory)][string]$Path)

    $count = 0
    foreach ($null in [IO.File]::ReadLines([IO.Path]::GetFullPath($Path))) {
        $count += 1
    }
    return $count
}

function Test-Phase00E1CanonicalJsonEqual {
    param([AllowNull()]$Left,[AllowNull()]$Right)

    return (ConvertTo-Phase00E1CanonicalJsonText -Value $Left) -ceq
        (ConvertTo-Phase00E1CanonicalJsonText -Value $Right)
}

function Read-Phase00E1VerifiedRunEnvelope {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)]
        [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn')]
        [string]$CaseId,
        [ValidateRange(1,999)][int]$Attempt = 1
    )

    $root = [IO.Path]::GetFullPath($RepositoryRoot)
    $definition = Get-Phase00E1CaseDefinition -CaseId $CaseId
    $paths = Get-Phase00E1AttemptPaths -RepositoryRoot $root `
        -CaseId $CaseId -Attempt $Attempt
    if (-not (Test-Path -LiteralPath $paths.RunPath -PathType Leaf)) {
        throw "E1_RUN_ENVELOPE_MISSING: $($paths.RunPath)"
    }
    $runText = [IO.File]::ReadAllText($paths.RunPath)
    if ((Get-Phase00E1JsonValueKind -JsonText $runText) -ne 'object') {
        throw 'E1_RUN_ENVELOPE_INVALID: root is not an object'
    }
    try { $envelope = $runText | ConvertFrom-Json -ErrorAction Stop } catch {
        throw 'E1_RUN_ENVELOPE_INVALID: JSON parse failed'
    }

    $requiredEnvelopeFields = @(
        'record_type','schema_version','case_id','case_slug','attempt',
        'execution_order','capture_integrity_status','case_status',
        'case_oracle_evaluated','reason_codes','pinned_source','pinned_runtime',
        'fixture','command','environment','process','artifacts','session_capture',
        'capture_verification','provider_observations','forwarder',
        'protected_repository','live_agent_home','cleanup','operation_error_type'
    )
    if (@($requiredEnvelopeFields | Where-Object {
        -not (Test-Phase00E1HasProperty -Object $envelope -Name $_)
    }).Count -gt 0) {
        throw 'E1_RUN_ENVELOPE_FIELDS_INCOMPLETE'
    }

    $slug = Get-Phase00E1CaseSlug -CaseId $CaseId
    if ([string](Get-Phase00E1PropertyValue -Object $envelope -Name 'record_type') -cne
            'phase00_e1_run' -or
        [int](Get-Phase00E1PropertyValue -Object $envelope -Name 'schema_version') -ne 1 -or
        [string](Get-Phase00E1PropertyValue -Object $envelope -Name 'case_id') -cne
            $CaseId -or
        [string](Get-Phase00E1PropertyValue -Object $envelope -Name 'case_slug') -cne
            $slug -or
        [int](Get-Phase00E1PropertyValue -Object $envelope -Name 'attempt') -ne
            $Attempt -or
        [int](Get-Phase00E1PropertyValue -Object $envelope -Name 'execution_order') -ne
            [int]$definition.ExecutionOrder) {
        throw 'E1_RUN_ENVELOPE_IDENTITY_MISMATCH'
    }
    if ([string](Get-Phase00E1PropertyValue `
            -Object $envelope -Name 'capture_integrity_status') -cne 'PASS' -or
        (Get-Phase00E1PropertyValue -Object $envelope -Name 'case_oracle_evaluated') -ne
            $false -or
        $null -ne (Get-Phase00E1PropertyValue -Object $envelope -Name 'case_status') -or
        @(Get-Phase00E1PropertyValue -Object $envelope -Name 'reason_codes').Count -ne 0 -or
        $null -ne (Get-Phase00E1PropertyValue `
            -Object $envelope -Name 'operation_error_type')) {
        throw 'E1_RUN_ENVELOPE_CAPTURE_NOT_PASS'
    }

    $source = Get-Phase00E1PropertyValue -Object $envelope -Name 'pinned_source'
    if ([string](Get-Phase00E1PropertyValue -Object $source -Name 'source_root') -cne
            '<E1_REPOSITORY_ROOT>/_research/upstreams/oh-my-pi' -or
        [string](Get-Phase00E1PropertyValue -Object $source -Name 'commit') -cne
            '3a8591a8af5b6d200088d12ca75a5517cb064fa8' -or
        (Get-Phase00E1PropertyValue -Object $source -Name 'clean') -ne $true -or
        [string](Get-Phase00E1PropertyValue -Object $source -Name 'origin') -cne
            'https://github.com/can1357/oh-my-pi.git') {
        throw 'E1_RUN_ENVELOPE_SOURCE_PIN_MISMATCH'
    }
    $runtime = Get-Phase00E1PropertyValue -Object $envelope -Name 'pinned_runtime'
    if (-not (Test-Phase00E1OmpIdentity `
            -Sha256 ([string](Get-Phase00E1PropertyValue -Object $runtime -Name 'sha256')) `
            -Version ([string](Get-Phase00E1PropertyValue -Object $runtime -Name 'version'))) -or
        @(Get-Phase00E1PropertyValue `
            -Object $runtime -Name 'version_probe_arguments') -join ',' -cne '--version' -or
        [int](Get-Phase00E1PropertyValue `
            -Object $runtime -Name 'version_probe_exit_code') -ne 0 -or
        (Get-Phase00E1PropertyValue `
            -Object $runtime -Name 'version_probe_timed_out') -ne $false) {
        throw 'E1_RUN_ENVELOPE_RUNTIME_PIN_MISMATCH'
    }

    $expectedFixtureHashes = Get-Phase00E1ExpectedFixtureHashes
    $fixtureRoot = Join-Path $root 'docs\evidence\phase-00\E1\fixture'
    $fixtureCheck = Test-Phase00E1FixtureTree -FixtureRoot $fixtureRoot `
        -ExpectedHashes $expectedFixtureHashes
    $fixture = Get-Phase00E1PropertyValue -Object $envelope -Name 'fixture'
    if (-not $fixtureCheck.Matched -or
        (Get-Phase00E1PropertyValue `
            -Object $fixture -Name 'source_fixture_matched') -ne $true -or
        (Get-Phase00E1PropertyValue `
            -Object $fixture -Name 'copied_fixture_matched') -ne $true -or
        -not (Test-Phase00E1CanonicalJsonEqual `
            -Left (Get-Phase00E1PropertyValue -Object $fixture -Name 'fixture_hashes') `
            -Right $expectedFixtureHashes) -or
        -not (Test-Phase00E1Sha256Text (Get-Phase00E1PropertyValue `
            -Object $fixture -Name 'model_catalog_sha256')) -or
        [string](Get-Phase00E1PropertyValue `
            -Object $fixture -Name 'runtime_source_sha256') -cne
            '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6' -or
        [string](Get-Phase00E1PropertyValue `
            -Object $fixture -Name 'runtime_copied_sha256') -cne
            '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6' -or
        [string](Get-Phase00E1PropertyValue `
            -Object $fixture -Name 'runtime_version') -cne 'omp/17.2.10') {
        throw 'E1_RUN_ENVELOPE_FIXTURE_MISMATCH'
    }
    $promptPath = Join-Path $fixtureRoot ([string]$definition.PromptRelativePath)
    $command = Get-Phase00E1PropertyValue -Object $envelope -Name 'command'
    if ([string](Get-Phase00E1PropertyValue `
            -Object $command -Name 'prompt_sha256') -cne
            (Get-Phase00E1FileSha256 -Path $promptPath) -or
        [string](Get-Phase00E1PropertyValue -Object $command -Name 'model') -cne
            'omniroute/codex/gpt-5.6-sol-high' -or
        (Get-Phase00E1PropertyValue -Object $command -Name 'launch_invoked') -ne $true) {
        throw 'E1_RUN_ENVELOPE_COMMAND_MISMATCH'
    }
    $processRecord = Get-Phase00E1PropertyValue -Object $envelope -Name 'process'
    $requiredProcessFields = @(
        'process_id','exit_code','timed_out','descendant_pids_observed',
        'remaining_child_pids'
    )
    if ($null -eq $processRecord -or @($requiredProcessFields | Where-Object {
        -not (Test-Phase00E1HasProperty -Object $processRecord -Name $_)
    }).Count -gt 0) {
        throw 'E1_RUN_ENVELOPE_PROCESS_INCOMPLETE'
    }
    $cleanupRecord = Get-Phase00E1PropertyValue -Object $envelope -Name 'cleanup'
    if (@('Required','Attempted','Succeeded','ErrorType' | Where-Object {
        -not (Test-Phase00E1HasProperty -Object $cleanupRecord -Name $_)
    }).Count -gt 0) {
        throw 'E1_RUN_ENVELOPE_CLEANUP_INCOMPLETE'
    }

    $sessionCapture = Get-Phase00E1PropertyValue `
        -Object $envelope -Name 'session_capture'
    $expectedSessionCount = if ($CaseId -eq 'SessionOnly') { 3 } else { 2 }
    $expectedOutputFileCount = if (Test-Phase00E1HasProperty `
            -Object $sessionCapture -Name 'expected_output_file_count') {
        [int](Get-Phase00E1PropertyValue `
            -Object $sessionCapture -Name 'expected_output_file_count')
    } else { 0 }
    if ([int](Get-Phase00E1PropertyValue `
            -Object $sessionCapture -Name 'jsonl_source_count') -ne $expectedSessionCount -or
        $expectedOutputFileCount -lt 0 -or
        $expectedOutputFileCount -gt ($expectedSessionCount - 1) -or
        [int](Get-Phase00E1PropertyValue `
            -Object $sessionCapture -Name 'unexpected_file_count') -ne 0) {
        throw 'E1_RUN_ENVELOPE_SESSION_COUNT_MISMATCH'
    }

    $artifactRecords = @(Get-Phase00E1PropertyValue -Object $envelope -Name 'artifacts')
    $strict = $CaseId -in @('ProviderStrictOffControl','ProviderStrictOn')
    $expectedArtifactCount = 2 + $expectedSessionCount + $(if ($strict) { 1 } else { 0 })
    if ($artifactRecords.Count -ne $expectedArtifactCount) {
        throw 'E1_RUN_ENVELOPE_ARTIFACT_COUNT_MISMATCH'
    }
    $verifiedArtifacts = [Collections.Generic.List[object]]::new()
    $seenPaths = @{}
    $seenKinds = @{}
    $totalSourceLines = 0
    $totalSanitizedLines = 0
    foreach ($artifact in $artifactRecords) {
        $kind = [string](Get-Phase00E1PropertyValue -Object $artifact -Name 'kind')
        if ($kind -notin @('stdout','stderr','session','forwarder')) {
            throw "E1_ARTIFACT_KIND_INVALID: $kind"
        }
        $relativePath = [string](Get-Phase00E1PropertyValue `
            -Object $artifact -Name 'path')
        if ($seenPaths.ContainsKey($relativePath)) {
            throw "E1_ARTIFACT_PATH_DUPLICATE: $relativePath"
        }
        $seenPaths[$relativePath] = $true
        $fullPath = Resolve-Phase00E1RawArtifactPath `
            -RepositoryRoot $root -RelativePath $relativePath
        $metadata = Get-Phase00E1PropertyValue -Object $artifact -Name 'metadata'
        $expectedHash = [string](Get-Phase00E1PropertyValue `
            -Object $metadata -Name 'SanitizedOutputSha256')
        $actualHash = Get-Phase00E1FileSha256 -Path $fullPath
        if (-not (Test-Phase00E1Sha256Text $expectedHash) -or
            $actualHash -cne $expectedHash) {
            throw "E1_ARTIFACT_HASH_MISMATCH: $relativePath"
        }
        $lineCount = Get-Phase00E1FileLineCount -Path $fullPath
        $sourceLineCount = [int](Get-Phase00E1PropertyValue `
            -Object $metadata -Name 'SourceLineCount')
        $sanitizedLineCount = [int](Get-Phase00E1PropertyValue `
            -Object $metadata -Name 'SanitizedLineCount')
        if ([string](Get-Phase00E1PropertyValue `
                -Object $metadata -Name 'Status') -cne 'PASS' -or
            @(Get-Phase00E1PropertyValue `
                -Object $metadata -Name 'ReasonCodes').Count -ne 0 -or
            -not (Test-Phase00E1Sha256Text (Get-Phase00E1PropertyValue `
                -Object $metadata -Name 'SourceCaptureSha256')) -or
            $sourceLineCount -ne $lineCount -or
            $sanitizedLineCount -ne $lineCount -or
            @(Get-Phase00E1PropertyValue `
                -Object $metadata -Name 'MalformedLines').Count -ne 0 -or
            @(Get-Phase00E1PropertyValue `
                -Object $metadata -Name 'InvalidShapeLines').Count -ne 0 -or
            @(Get-Phase00E1PropertyValue `
                -Object $metadata -Name 'ProcessingErrorLines').Count -ne 0 -or
            @(Get-Phase00E1PropertyValue `
                -Object $metadata -Name 'CredentialLines').Count -ne 0) {
            throw "E1_ARTIFACT_METADATA_INVALID: $relativePath"
        }
        $metadataFixtureHashes = Get-Phase00E1PropertyValue `
            -Object $metadata -Name 'FixtureHashes'
        $expectedMetadataHashes = if ($kind -eq 'stderr') { [ordered]@{} } else {
            $expectedFixtureHashes
        }
        if (-not (Test-Phase00E1CanonicalJsonEqual `
            -Left $metadataFixtureHashes -Right $expectedMetadataHashes)) {
            throw "E1_ARTIFACT_FIXTURE_HASH_MISMATCH: $relativePath"
        }
        try { $null = @(Read-Phase00E1JsonLineEntries -Path $fullPath) } catch {
            throw "E1_ARTIFACT_JSONL_INVALID: $relativePath`: $($_.Exception.Message)"
        }
        $sourceRelativeHash = Get-Phase00E1PropertyValue `
            -Object $artifact -Name 'source_relative_path_sha256'
        if ($kind -eq 'session') {
            if (-not (Test-Phase00E1Sha256Text $sourceRelativeHash)) {
                throw "E1_ARTIFACT_SESSION_SOURCE_ID_INVALID: $relativePath"
            }
        } elseif ($null -ne $sourceRelativeHash) {
            throw "E1_ARTIFACT_SOURCE_ID_UNEXPECTED: $relativePath"
        }
        $totalSourceLines += $sourceLineCount
        $totalSanitizedLines += $sanitizedLineCount
        $verifiedArtifacts.Add([pscustomobject][ordered]@{
            Kind = $kind
            Path = $fullPath
            RelativePath = $relativePath
            Sha256 = $actualHash
            LineCount = $lineCount
            Metadata = $metadata
            SourceRelativePathSha256 = $sourceRelativeHash
        })
        if (-not $seenKinds.ContainsKey($kind)) { $seenKinds[$kind] = 0 }
        $seenKinds[$kind] = [int]$seenKinds[$kind] + 1
    }

    if ([int]$seenKinds['stdout'] -ne 1 -or [int]$seenKinds['stderr'] -ne 1 -or
        [int]$seenKinds['session'] -ne $expectedSessionCount -or
        [int]$seenKinds['forwarder'] -ne $(if ($strict) { 1 } else { 0 })) {
        throw 'E1_RUN_ENVELOPE_ARTIFACT_KIND_COUNT_MISMATCH'
    }
    $expectedStdout = Get-Phase00E1RepositoryRelativePath `
        -RepositoryRoot $root -Path $paths.StdoutPath
    $expectedStderr = Get-Phase00E1RepositoryRelativePath `
        -RepositoryRoot $root -Path $paths.StderrPath
    if (-not $seenPaths.ContainsKey($expectedStdout) -or
        -not $seenPaths.ContainsKey($expectedStderr)) {
        throw 'E1_RUN_ENVELOPE_PRIMARY_ARTIFACT_PATH_MISMATCH'
    }
    $sessionArtifacts = @($verifiedArtifacts | Where-Object Kind -eq 'session' |
        Sort-Object RelativePath)
    $actualSessionFiles = @(Get-ChildItem -LiteralPath $paths.SessionDirectory `
        -File -Recurse -Force | ForEach-Object {
            Get-Phase00E1RepositoryRelativePath -RepositoryRoot $root -Path $_.FullName
        } | Sort-Object)
    $expectedSessionFiles = @()
    for ($index = 1; $index -le $expectedSessionCount; $index += 1) {
        $expectedSessionFiles += Get-Phase00E1RepositoryRelativePath `
            -RepositoryRoot $root `
            -Path (Join-Path $paths.SessionDirectory ('session-{0:D3}.jsonl' -f $index))
    }
    if (($actualSessionFiles -join "`n") -cne ($expectedSessionFiles -join "`n") -or
        (@($sessionArtifacts.RelativePath | Sort-Object) -join "`n") -cne
            ($expectedSessionFiles -join "`n")) {
        throw 'E1_RUN_ENVELOPE_SESSION_PATH_SET_MISMATCH'
    }
    if ($strict) {
        $expectedForwarder = Get-Phase00E1RepositoryRelativePath `
            -RepositoryRoot $root -Path $paths.ForwarderPath
        if (-not $seenPaths.ContainsKey($expectedForwarder)) {
            throw 'E1_RUN_ENVELOPE_FORWARDER_PATH_MISMATCH'
        }
    } else {
        $ordinaryForwarder = Get-Phase00E1PropertyValue `
            -Object $envelope -Name 'forwarder'
        if ((Test-Path -LiteralPath $paths.ForwarderPath) -or
            (Get-Phase00E1PropertyValue `
                -Object $ordinaryForwarder -Name 'required') -ne $false -or
            (Get-Phase00E1PropertyValue `
                -Object $ordinaryForwarder -Name 'artifact_present') -ne $false) {
            throw 'E1_RUN_ENVELOPE_UNEXPECTED_FORWARDER'
        }
    }

    $capture = Get-Phase00E1PropertyValue `
        -Object $envelope -Name 'capture_verification'
    if ([string](Get-Phase00E1PropertyValue -Object $capture -Name 'Status') -cne
            'PASS' -or
        @(Get-Phase00E1PropertyValue -Object $capture -Name 'ReasonCodes').Count -ne 0 -or
        [int](Get-Phase00E1PropertyValue -Object $capture -Name 'ArtifactCount') -ne
            $verifiedArtifacts.Count -or
        [int](Get-Phase00E1PropertyValue -Object $capture -Name 'TotalSourceLines') -ne
            $totalSourceLines -or
        [int](Get-Phase00E1PropertyValue `
            -Object $capture -Name 'TotalSanitizedLines') -ne $totalSanitizedLines) {
        throw 'E1_RUN_ENVELOPE_CAPTURE_TOTAL_MISMATCH'
    }
    $runRelativePath = Get-Phase00E1RepositoryRelativePath `
        -RepositoryRoot $root -Path $paths.RunPath
    $runArtifact = [pscustomobject][ordered]@{
        Kind = 'run'
        Path = [IO.Path]::GetFullPath($paths.RunPath)
        RelativePath = $runRelativePath
        Sha256 = Get-Phase00E1FileSha256 -Path $paths.RunPath
        LineCount = Get-Phase00E1FileLineCount -Path $paths.RunPath
        Metadata = $null
        SourceRelativePathSha256 = $null
    }
    return [pscustomobject][ordered]@{
        RepositoryRoot = $root
        Paths = $paths
        Definition = $definition
        Envelope = $envelope
        Artifacts = @($verifiedArtifacts)
        RunArtifact = $runArtifact
        PromptPath = [IO.Path]::GetFullPath($promptPath)
    }
}

function Merge-Phase00E1ProviderLedgers {
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Ledgers)

    $providerModels = @{}
    $requestCount = 0
    $attributedRequestCount = 0
    $unattributedRequestCount = 0
    $responseEndCount = 0
    $retryStartCount = 0
    $retryEndCount = 0
    $recoveredRetryCount = 0
    $retryExhaustedCount = 0
    $terminalFailureCount = 0
    foreach ($ledger in @($Ledgers)) {
        $requestCount += [int](Get-Phase00E1PropertyValue `
            -Object $ledger -Name 'RequestCount')
        $attributedRequestCount += [int](Get-Phase00E1PropertyValue `
            -Object $ledger -Name 'AttributedRequestCount')
        $unattributedRequestCount += [int](Get-Phase00E1PropertyValue `
            -Object $ledger -Name 'UnattributedRequestCount')
        $responseEndCount += [int](Get-Phase00E1PropertyValue `
            -Object $ledger -Name 'ResponseEndCount')
        $retryStartCount += [int](Get-Phase00E1PropertyValue `
            -Object $ledger -Name 'RetryStartCount')
        $retryEndCount += [int](Get-Phase00E1PropertyValue `
            -Object $ledger -Name 'RetryEndCount')
        $recoveredRetryCount += [int](Get-Phase00E1PropertyValue `
            -Object $ledger -Name 'RecoveredRetryCount')
        $retryExhaustedCount += [int](Get-Phase00E1PropertyValue `
            -Object $ledger -Name 'RetryExhaustedCount')
        $terminalFailure = Get-Phase00E1PropertyValue `
            -Object $ledger -Name 'TerminalFailure'
        if ((Get-Phase00E1PropertyValue `
            -Object $terminalFailure -Name 'Found') -eq $true) {
            $terminalFailureCount += 1
        }
        foreach ($identity in @(Get-Phase00E1PropertyValue `
            -Object $ledger -Name 'ProviderModels')) {
            $provider = [string](Get-Phase00E1PropertyValue `
                -Object $identity -Name 'Provider')
            $model = [string](Get-Phase00E1PropertyValue `
                -Object $identity -Name 'Model')
            if (-not [string]::IsNullOrWhiteSpace($provider) -and
                -not [string]::IsNullOrWhiteSpace($model)) {
                $providerModels["$provider`n$model"] = [pscustomobject][ordered]@{
                    Provider=$provider;Model=$model
                }
            }
        }
    }
    $identities = @($providerModels.Values | Sort-Object Provider,Model)
    $providers = @($identities.Provider | Sort-Object -Unique)
    $models = @($identities.Model | Sort-Object -Unique)
    return [pscustomobject][ordered]@{
        RequestCount = $requestCount
        AttributedRequestCount = $attributedRequestCount
        UnattributedRequestCount = $unattributedRequestCount
        ResponseEndCount = $responseEndCount
        RetryStartCount = $retryStartCount
        RetryEndCount = $retryEndCount
        RecoveredRetryCount = $recoveredRetryCount
        RetryExhaustedCount = $retryExhaustedCount
        RetryExhausted = $retryExhaustedCount -gt 0
        TerminalFailureCount = $terminalFailureCount
        Provider = if ($providers.Count -eq 1) { $providers[0] } else { $null }
        Model = if ($models.Count -eq 1) { $models[0] } else { $null }
        ProviderModels = @($identities)
    }
}

function Get-Phase00E1AgentFixtureFacts {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Agent
    )

    $path = Join-Path $FixtureRoot "agents\$Agent.md"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "E1_AGENT_FIXTURE_MISSING: $Agent"
    }
    $text = [IO.File]::ReadAllText($path).Replace("`r`n","`n")
    $match = [regex]::Match($text,'(?s)\A---\n(?<yaml>.*?)\n---(?:\n|\z)')
    if (-not $match.Success) {
        throw "E1_AGENT_FRONTMATTER_INVALID: $Agent"
    }
    $frontmatter = $match.Groups['yaml'].Value
    $blocking = $frontmatter -cmatch '(?m)^blocking:\s*true\s*$'
    $hasOutput = $frontmatter -cmatch '(?m)^output:\s*$'
    $dialect = 'NONE'
    if ($hasOutput) {
        $outputMatch = [regex]::Match(
            $frontmatter,
            '(?ms)^output:\s*\n(?<body>(?:^[ \t]+.*(?:\n|\z))+)'
        )
        if (-not $outputMatch.Success) {
            throw "E1_AGENT_OUTPUT_FRONTMATTER_INVALID: $Agent"
        }
        $dialect = if ($outputMatch.Groups['body'].Value -cmatch
            '(?m)^\s+type:\s*object\s*$') { 'JSON_SCHEMA' } else { 'JTD' }
    }
    return [pscustomobject][ordered]@{
        Agent = $Agent
        Path = [IO.Path]::GetFullPath($path)
        Sha256 = Get-Phase00E1FileSha256 -Path $path
        Blocking = $blocking
        OutputState = if ($hasOutput) { 'PRESENT' } else { 'ABSENT' }
        OutputDialect = $dialect
    }
}

function Get-Phase00E1TaskSetupBlocking {
    param(
        [AllowNull()]$TaskCall,
        [Parameter(Mandatory)][bool]$DefinitionBlocking
    )

    if ($null -eq $TaskCall) { return $false }
    $arguments = Get-Phase00E1PropertyValue `
        -Object $TaskCall -Name 'CanonicalArguments'
    if (Test-Phase00E1HasProperty -Object $arguments -Name 'blocking') {
        return (Get-Phase00E1PropertyValue `
            -Object $arguments -Name 'blocking') -eq $true
    }
    return $DefinitionBlocking
}

function New-Phase00E1RawAnchor {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$Path,
        [ValidateRange(1,2147483647)][int]$Line,
        [Parameter(Mandatory)][string]$Type
    )

    return [pscustomobject][ordered]@{
        Path = Get-Phase00E1RepositoryRelativePath `
            -RepositoryRoot $RepositoryRoot -Path $Path
        Line = $Line
        Type = $Type
    }
}

function Read-Phase00E1AttemptEvidence {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)]
        [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn')]
        [string]$CaseId,
        [ValidateRange(1,999)][int]$Attempt = 1
    )

    $verified = Read-Phase00E1VerifiedRunEnvelope `
        -RepositoryRoot $RepositoryRoot -CaseId $CaseId -Attempt $Attempt
    $root = [string]$verified.RepositoryRoot
    $definition = $verified.Definition
    $envelope = $verified.Envelope
    $fixtureRoot = Join-Path $root 'docs\evidence\phase-00\E1\fixture'
    $projectionReasons = [Collections.Generic.List[string]]::new()
    $anchors = [Collections.Generic.List[object]]::new()

    $stdoutArtifact = @($verified.Artifacts | Where-Object Kind -eq 'stdout')[0]
    $stdoutProjection = Get-Phase00E1DirectTaskExecutionProjection `
        -Path $stdoutArtifact.Path
    $controllerCalls = @($stdoutProjection.Calls)
    $controllerCall = if ($controllerCalls.Count -eq 1) {
        $controllerCalls[0]
    } else { $null }
    if ($controllerCalls.Count -ne 1) {
        $projectionReasons.Add('E1_CONTROLLER_TASK_CALL_COUNT')
    }
    $expectedControllerArguments = Get-Phase00E1CanonicalTaskArguments `
        -Arguments (Get-Phase00E1FixtureJsonBlock -Path $verified.PromptPath)
    if ($null -ne $controllerCall) {
        $anchors.Add((New-Phase00E1RawAnchor -RepositoryRoot $root `
            -Path $controllerCall.OriginPath -Line $controllerCall.LineNumber `
            -Type 'controller_task_call'))
        if (-not (Test-Phase00E1CanonicalJsonEqual `
            -Left $controllerCall.CanonicalArguments `
            -Right $expectedControllerArguments.Arguments)) {
            $projectionReasons.Add('E1_CONTROLLER_ARGUMENTS_MISMATCH')
        }
    }
    foreach ($execution in @($stdoutProjection.Executions)) {
        if ($null -ne $execution.End) {
            $anchors.Add((New-Phase00E1RawAnchor -RepositoryRoot $root `
                -Path $stdoutArtifact.Path -Line ([int]$execution.End.LineNumber) `
                -Type 'controller_task_result'))
        }
    }

    $sessionArtifacts = @($verified.Artifacts | Where-Object Kind -eq 'session' |
        Sort-Object RelativePath)
    $sessionProjections = @($sessionArtifacts | ForEach-Object {
        Get-Phase00E1PersistedSessionProjection -Path $_.Path
    })
    $processProviderLedger = Merge-Phase00E1ProviderLedgers `
        -Ledgers @($sessionProjections.ProviderLedger)
    $mainSessions = @($sessionProjections | Where-Object {
        [string]::IsNullOrWhiteSpace([string]$_.Agent)
    })
    if ($mainSessions.Count -ne 1) {
        $projectionReasons.Add('E1_CONTROLLER_SESSION_COUNT')
    } else {
        $mainTaskCalls = @($mainSessions[0].TaskCalls)
        $mainTaskExecutions = @($mainSessions[0].TaskExecutions)
        if ($mainTaskCalls.Count -ne 1 -or $null -eq $controllerCall -or
            [string]$mainTaskCalls[0].ToolCallId -cne
                [string]$controllerCall.ToolCallId -or
            -not (Test-Phase00E1CanonicalJsonEqual `
                -Left $mainTaskCalls[0].CanonicalArguments `
                -Right $controllerCall.CanonicalArguments)) {
            $projectionReasons.Add('E1_CONTROLLER_SESSION_CALL_MISMATCH')
        }
        if ($mainTaskExecutions.Count -ne 1 -or
            [int]$mainTaskExecutions[0].ToolResultLineNumber -le 0) {
            $projectionReasons.Add('E1_CONTROLLER_SESSION_RESULT_MISSING')
        } else {
            $stdoutDirectRawResults = @($stdoutProjection.Results | ForEach-Object {
                Get-Phase00E1PropertyValue -Object $_ -Name 'RawResult'
            })
            $sessionDirectRawResults = @($mainTaskExecutions[0].Results |
                ForEach-Object {
                    Get-Phase00E1PropertyValue -Object $_ -Name 'RawResult'
                })
            if (-not (Test-Phase00E1CanonicalJsonEqual `
                -Left $stdoutDirectRawResults -Right $sessionDirectRawResults)) {
                $projectionReasons.Add('E1_CONTROLLER_SESSION_RESULT_MISMATCH')
            }
        }
    }

    $selectedAgent = if ($CaseId -eq 'SessionOnly') {
        'phase00-e1-session-leaf'
    } else { [string]$definition.Agent }
    $selectedSessions = @($sessionProjections | Where-Object {
        [string]$_.Agent -ceq $selectedAgent
    })
    $selectedSession = if ($selectedSessions.Count -eq 1) {
        $selectedSessions[0]
    } else { $null }
    if ($selectedSessions.Count -ne 1) {
        $projectionReasons.Add('E1_SELECTED_SESSION_COUNT')
    }
    $providerLedger = if ($null -eq $selectedSession) {
        Get-Phase00E1ProviderLedger -Events @()
    } else { $selectedSession.ProviderLedger }
    if ($null -ne $selectedSession) {
        if ([int]$selectedSession.SessionInitLine -gt 0) {
            $anchors.Add((New-Phase00E1RawAnchor -RepositoryRoot $root `
                -Path $selectedSession.Path `
                -Line ([int]$selectedSession.SessionInitLine) `
                -Type 'selected_session_init'))
        } else {
            $projectionReasons.Add('E1_SELECTED_SESSION_INIT_MISSING')
        }
        foreach ($entry in @($selectedSession.ProviderMessageEntries)) {
            $anchors.Add((New-Phase00E1RawAnchor -RepositoryRoot $root `
                -Path $selectedSession.Path -Line ([int]$entry.LineNumber) `
                -Type 'selected_provider_turn'))
        }
        foreach ($yieldAttempt in @($selectedSession.YieldAttempts)) {
            $anchors.Add((New-Phase00E1RawAnchor -RepositoryRoot $root `
                -Path $selectedSession.Path -Line ([int]$yieldAttempt.LineNumber) `
                -Type 'selected_yield_call'))
            if ([int]$yieldAttempt.ToolResultLineNumber -gt 0) {
                $anchors.Add((New-Phase00E1RawAnchor -RepositoryRoot $root `
                    -Path $selectedSession.Path `
                    -Line ([int]$yieldAttempt.ToolResultLineNumber) `
                    -Type 'selected_yield_result'))
            } else {
                $projectionReasons.Add('E1_YIELD_TOOL_RESULT_MISSING')
            }
        }
    }

    $outerResults = @($stdoutProjection.Results)
    $attributableResults = $outerResults
    $carrierSession = $null
    $nestedCall = $null
    $nestedResults = @()
    if ($CaseId -eq 'SessionOnly') {
        $carrierSessions = @($sessionProjections | Where-Object {
            [string]$_.Agent -ceq 'phase00-e1-session-carrier'
        })
        if ($carrierSessions.Count -eq 1) {
            $carrierSession = $carrierSessions[0]
        } else {
            $projectionReasons.Add('E1_CARRIER_SESSION_COUNT')
        }
        if ($null -ne $carrierSession) {
            $nestedExecutions = @($carrierSession.TaskExecutions)
            if ($nestedExecutions.Count -eq 1) {
                $nestedCall = $nestedExecutions[0].Call
                $nestedResults = @($nestedExecutions[0].Results)
                $anchors.Add((New-Phase00E1RawAnchor -RepositoryRoot $root `
                    -Path $carrierSession.Path -Line ([int]$nestedCall.LineNumber) `
                    -Type 'nested_leaf_task_call'))
                if ([int]$nestedExecutions[0].ToolResultLineNumber -gt 0) {
                    $anchors.Add((New-Phase00E1RawAnchor -RepositoryRoot $root `
                        -Path $carrierSession.Path `
                        -Line ([int]$nestedExecutions[0].ToolResultLineNumber) `
                        -Type 'nested_leaf_task_result'))
                }
            } else {
                $projectionReasons.Add('E1_NESTED_TASK_CALL_COUNT')
            }
        }
        $carrierAgentPath = Join-Path $fixtureRoot `
            'agents\phase00-e1-session-carrier.md'
        $expectedNestedArguments = Get-Phase00E1CanonicalTaskArguments `
            -Arguments (Get-Phase00E1FixtureJsonBlock -Path $carrierAgentPath)
        if ($null -ne $nestedCall -and -not (Test-Phase00E1CanonicalJsonEqual `
            -Left $nestedCall.CanonicalArguments `
            -Right $expectedNestedArguments.Arguments)) {
            $projectionReasons.Add('E1_NESTED_ARGUMENTS_MISMATCH')
        }
        $attributableResults = @($nestedResults)
    }

    $selectedFixtureFacts = Get-Phase00E1AgentFixtureFacts `
        -FixtureRoot $fixtureRoot -Agent $selectedAgent
    $callerTask = if ($CaseId -eq 'SessionOnly') { $nestedCall } else { $controllerCall }
    $callerSchemaState = if ($null -ne $callerTask -and
        (Get-Phase00E1PropertyValue -Object $callerTask -Name 'HasOutputSchema') -eq
            $true) { 'PRESENT' } else { 'ABSENT' }
    $carrierCallerState = if ($CaseId -eq 'SessionOnly' -and
        $null -ne $controllerCall -and
        (Get-Phase00E1PropertyValue `
            -Object $controllerCall -Name 'HasOutputSchema') -eq $true) {
        'PRESENT'
    } else { 'ABSENT' }
    $sessionSchemaState = if ($CaseId -eq 'SessionOnly' -and
        $carrierCallerState -eq 'PRESENT' -and $callerSchemaState -eq 'ABSENT') {
        'PRESENT'
    } else { 'ABSENT' }
    $selectedResult = if (@($attributableResults).Count -eq 1) {
        @($attributableResults)[0]
    } else { $null }
    $selectedStructuredOutput = if ($null -eq $selectedResult) { $null } else {
        Get-Phase00E1PropertyValue -Object $selectedResult -Name 'StructuredOutput'
    }
    $selectedSource = [string](Get-Phase00E1PropertyValue `
        -Object $selectedStructuredOutput -Name 'source')
    $outerStructuredOutput = if ($outerResults.Count -eq 1) {
        Get-Phase00E1PropertyValue -Object $outerResults[0] -Name 'StructuredOutput'
    } else { $null }
    $outerSource = [string](Get-Phase00E1PropertyValue `
        -Object $outerStructuredOutput -Name 'source')
    $overrideObservable = $CaseId -ne 'SessionOnly' -and
        $callerSchemaState -eq 'PRESENT'
    $caseFacts = [pscustomobject][ordered]@{
        CallerSchemaState = $callerSchemaState
        AgentSchemaState = [string]$selectedFixtureFacts.OutputState
        SessionSchemaState = $sessionSchemaState
        AgentSchemaDialect = [string]$selectedFixtureFacts.OutputDialect
        ChildInitializationSource = $selectedSource
        SchemaOverrideObservable = $overrideObservable
        SchemaOverrideObserved = $overrideObservable -and $selectedSource -ceq 'caller'
        SelectedResultRole = if ($CaseId -eq 'SessionOnly') {
            if ($null -ne $selectedResult -and
                [string]$selectedResult.Agent -ceq 'phase00-e1-session-leaf') {
                'nested_leaf'
            } else { 'carrier_or_unknown' }
        } else { 'target' }
        OuterCarrierResultSource = if ($CaseId -eq 'SessionOnly') { $outerSource } else { $null }
        CarrierCallerSchemaState = $carrierCallerState
    }

    $blockingExecutions = [Collections.Generic.List[object]]::new()
    if ($CaseId -eq 'SessionOnly') {
        $carrierFacts = Get-Phase00E1AgentFixtureFacts `
            -FixtureRoot $fixtureRoot -Agent 'phase00-e1-session-carrier'
        $carrierSetupBlocking = Get-Phase00E1TaskSetupBlocking `
            -TaskCall $controllerCall -DefinitionBlocking ([bool]$carrierFacts.Blocking)
        $blockingExecutions.Add([pscustomobject][ordered]@{
            Role='carrier';Agent=if ($null -eq $controllerCall) {
                ''
            } else {[string]$controllerCall.Agent}
            DefinitionBlocking=[bool]$carrierFacts.Blocking
            SetupBlocking=$carrierSetupBlocking
            ExecutionMode=if ($carrierFacts.Blocking -and $carrierSetupBlocking) {
                'blocking'
            } else {'nonblocking'}
            AsyncAcknowledgement=@($outerResults | Where-Object IsAsyncAcknowledgement).Count -gt 0
        })
        $leafSetupBlocking = Get-Phase00E1TaskSetupBlocking `
            -TaskCall $nestedCall -DefinitionBlocking ([bool]$selectedFixtureFacts.Blocking)
        $blockingExecutions.Add([pscustomobject][ordered]@{
            Role='leaf';Agent=if ($null -eq $nestedCall) {
                ''
            } else {[string]$nestedCall.Agent}
            DefinitionBlocking=[bool]$selectedFixtureFacts.Blocking
            SetupBlocking=$leafSetupBlocking
            ExecutionMode=if ($selectedFixtureFacts.Blocking -and $leafSetupBlocking) {
                'blocking'
            } else {'nonblocking'}
            AsyncAcknowledgement=@($nestedResults | Where-Object IsAsyncAcknowledgement).Count -gt 0
        })
    } else {
        $setupBlocking = Get-Phase00E1TaskSetupBlocking `
            -TaskCall $controllerCall `
            -DefinitionBlocking ([bool]$selectedFixtureFacts.Blocking)
        $blockingExecutions.Add([pscustomobject][ordered]@{
            Role='target';Agent=if ($null -eq $controllerCall) {
                ''
            } else {[string]$controllerCall.Agent}
            DefinitionBlocking=[bool]$selectedFixtureFacts.Blocking
            SetupBlocking=$setupBlocking
            ExecutionMode=if ($selectedFixtureFacts.Blocking -and $setupBlocking) {
                'blocking'
            } else {'nonblocking'}
            AsyncAcknowledgement=@($outerResults | Where-Object IsAsyncAcknowledgement).Count -gt 0
        })
    }

    $identity = $null
    $piNoStrictState = 'NOT_APPLICABLE'
    $forwarderProjections = @()
    $forwarderAllProjectionCount = 0
    $yieldAttempts = if ($null -eq $selectedSession) { @() } else {
        @($selectedSession.YieldAttempts)
    }
    $localSchemaRejectionCount = if ($null -eq $selectedSession) { 0 } else {
        [int]$selectedSession.LocalSchemaRejectionCount
    }
    $localSchemaRetryCount = if ($null -eq $selectedSession) { 0 } else {
        [int]$selectedSession.LocalSchemaRetryCount
    }
    $schemaOverrideCount = if ($null -eq $selectedSession) { 0 } else {
        [int]$selectedSession.SchemaOverrideCount
    }
    if ($CaseId -in @('ProviderStrictOffControl','ProviderStrictOn')) {
        $isOff = $CaseId -eq 'ProviderStrictOffControl'
        $environment = Get-Phase00E1PropertyValue -Object $envelope -Name 'environment'
        $piValue = [string](Get-Phase00E1PropertyValue `
            -Object $environment -Name 'PI_NO_STRICT')
        $piNoStrictState = if ($piValue -ceq '1') {
            'PRESENT_1'
        } elseif ($piValue -ceq '<ABSENT>') { 'ABSENT' } else { 'INVALID' }
        $forwarderArtifact = @($verified.Artifacts | Where-Object Kind -eq 'forwarder')[0]
        $forwarderEntries = @(Read-Phase00E1JsonLineEntries `
            -Path $forwarderArtifact.Path)
        $ready = @($forwarderEntries | Where-Object {
            [string](Get-Phase00E1PropertyValue `
                -Object $_.Value -Name 'record_type') -ceq 'phase00_e1_forwarder_ready'
        })
        $closed = @($forwarderEntries | Where-Object {
            [string](Get-Phase00E1PropertyValue `
                -Object $_.Value -Name 'record_type') -ceq 'phase00_e1_forwarder_closed'
        })
        $allProjectionEntries = @($forwarderEntries | Where-Object {
            [string](Get-Phase00E1PropertyValue `
                -Object $_.Value -Name 'record_type') -ceq 'phase00_e1_request_projection'
        })
        $forwarderAllProjectionCount = $allProjectionEntries.Count
        $forwarderRecord = Get-Phase00E1PropertyValue `
            -Object $envelope -Name 'forwarder'
        $forwarderSourcePath = Join-Path $PSScriptRoot 'phase00-e1-forwarder.mjs'
        if ($ready.Count -ne 1 -or $closed.Count -ne 1 -or
            [string](Get-Phase00E1PropertyValue `
                -Object $forwarderEntries[0].Value -Name 'record_type') -cne
                'phase00_e1_forwarder_ready' -or
            [string](Get-Phase00E1PropertyValue `
                -Object $forwarderEntries[-1].Value -Name 'record_type') -cne
                'phase00_e1_forwarder_closed' -or
            [string](Get-Phase00E1PropertyValue `
                -Object $ready[0].Value -Name 'listen_host') -cne '127.0.0.1' -or
            [int](Get-Phase00E1PropertyValue `
                -Object $ready[0].Value -Name 'listen_port') -le 0 -or
            [string](Get-Phase00E1PropertyValue `
                -Object $closed[0].Value -Name 'listen_host') -cne
                [string](Get-Phase00E1PropertyValue `
                    -Object $ready[0].Value -Name 'listen_host') -or
            [int](Get-Phase00E1PropertyValue `
                -Object $closed[0].Value -Name 'listen_port') -ne
                [int](Get-Phase00E1PropertyValue `
                    -Object $ready[0].Value -Name 'listen_port') -or
            (Get-Phase00E1PropertyValue -Object $forwarderRecord -Name 'required') -ne $true -or
            [string](Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'target_origin') -cne
                'http://127.0.0.1:20128' -or
            [string](Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'source_sha256') -cne
                (Get-Phase00E1FileSha256 -Path $forwarderSourcePath) -or
            -not (Test-Phase00E1Sha256Text (Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'node_sha256')) -or
            [string](Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'listen_host') -cne '127.0.0.1' -or
            [int](Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'listen_port') -ne
                [int](Get-Phase00E1PropertyValue `
                    -Object $ready[0].Value -Name 'listen_port') -or
            (Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'pi_no_strict_effective') -ne $isOff -or
            [int](Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'exit_code') -ne 0 -or
            (Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'timed_out') -ne $false -or
            @(Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'remaining_child_pids').Count -ne 0 -or
            (Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'port_closed') -ne $true -or
            (Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'lifecycle_valid') -ne $true -or
            (Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'artifact_present') -ne $true -or
            [int](Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'projection_count') -ne
                $allProjectionEntries.Count -or
            [int](Get-Phase00E1PropertyValue `
                -Object $forwarderRecord -Name 'record_count') -ne
                $forwarderEntries.Count) {
            $projectionReasons.Add('E1_FORWARDER_LIFECYCLE_INVALID')
        }
        $allIndexes = @($allProjectionEntries | ForEach-Object {
            [int](Get-Phase00E1PropertyValue -Object $_.Value -Name 'request_index')
        })
        $expectedAllIndexes = if ($allIndexes.Count -eq 0) { @() } else {
            @(1..$allIndexes.Count)
        }
        if (($allIndexes -join ',') -cne ($expectedAllIndexes -join ',')) {
            $projectionReasons.Add('E1_FORWARDER_GLOBAL_INDEX_INVALID')
        }
        $yieldProjectionList = [Collections.Generic.List[object]]::new()
        foreach ($entry in $allProjectionEntries) {
            $anchors.Add((New-Phase00E1RawAnchor -RepositoryRoot $root `
                -Path $forwarderArtifact.Path -Line ([int]$entry.LineNumber) `
                -Type 'forwarder_request_projection'))
            if ((Get-Phase00E1PropertyValue `
                -Object $entry.Value -Name 'yield_tool_present') -ne $true) {
                continue
            }
            $copy = [ordered]@{}
            foreach ($property in $entry.Value.PSObject.Properties) {
                $copy[$property.Name] = $property.Value
            }
            $copy['e1_origin_line'] = [int]$entry.LineNumber
            $yieldProjectionList.Add([pscustomobject]$copy)
        }
        $forwarderProjections = @($yieldProjectionList)
        if ($allProjectionEntries.Count -ne [int]$processProviderLedger.RequestCount) {
            $projectionReasons.Add('E1_FORWARDER_PROCESS_COUNT_MISMATCH')
        }
        $yieldParameterHashes = @($forwarderProjections | ForEach-Object {
            [string](Get-Phase00E1PropertyValue `
                -Object $_ -Name 'yield_parameters_sha256')
        } | Sort-Object -Unique)
        $actualControllerArguments = if ($null -eq $controllerCall) { $null } else {
            $controllerCall.CanonicalArguments
        }
        $assignment = Get-Phase00E1PropertyValue `
            -Object $actualControllerArguments -Name 'task'
        $outputSchema = Get-Phase00E1PropertyValue `
            -Object $actualControllerArguments -Name 'outputSchema'
        $targetOrigin = [Uri][string](Get-Phase00E1PropertyValue `
            -Object $forwarderRecord -Name 'target_origin')
        $identity = [pscustomobject][ordered]@{
            PromptSha256 = [string](Get-Phase00E1PropertyValue `
                -Object (Get-Phase00E1PropertyValue `
                    -Object $envelope -Name 'command') -Name 'prompt_sha256')
            AssignmentSha256 = if ($null -eq $assignment) { $null } else {
                Get-Phase00E1StringSha256 -Text ([string]$assignment)
            }
            OutputSchemaSha256 = if ($null -eq $outputSchema) { $null } else {
                Get-Phase00E1CanonicalObjectSha256 -Value $outputSchema
            }
            AgentSha256 = [string]$selectedFixtureFacts.Sha256
            YieldParametersSha256 = if ($yieldParameterHashes.Count -eq 1) {
                $yieldParameterHashes[0]
            } else { $null }
            Agent = if ($null -eq $controllerCall) { $null } else {
                [string]$controllerCall.Agent
            }
            Model = [string]$providerLedger.Model
            RuntimeSha256 = [string](Get-Phase00E1PropertyValue `
                -Object (Get-Phase00E1PropertyValue `
                    -Object $envelope -Name 'pinned_runtime') -Name 'sha256')
            RuntimeVersion = [string](Get-Phase00E1PropertyValue `
                -Object (Get-Phase00E1PropertyValue `
                    -Object $envelope -Name 'pinned_runtime') -Name 'version')
            Gateway = "omniroute:$($targetOrigin.Host):$($targetOrigin.Port)"
        }
    }

    $process = Get-Phase00E1PropertyValue -Object $envelope -Name 'process'
    $cleanup = Get-Phase00E1PropertyValue -Object $envelope -Name 'cleanup'
    $protected = Get-Phase00E1PropertyValue `
        -Object $envelope -Name 'protected_repository'
    $live = Get-Phase00E1PropertyValue -Object $envelope -Name 'live_agent_home'
    $remainingPids = @(
        @(Get-Phase00E1PropertyValue -Object $process -Name 'remaining_child_pids') +
        @(Get-Phase00E1PropertyValue `
            -Object (Get-Phase00E1PropertyValue `
                -Object $envelope -Name 'forwarder') -Name 'remaining_child_pids')
    ) | Where-Object { $null -ne $_ } | ForEach-Object { [int]$_ } |
        Sort-Object -Unique
    $rawArtifactRecords = @(
        @($verified.Artifacts) + @($verified.RunArtifact) | ForEach-Object {
            [pscustomobject][ordered]@{
                Kind = [string]$_.Kind
                Path = [string]$_.RelativePath
                Sha256 = [string]$_.Sha256
                Lines = [int]$_.LineCount
                SourceCaptureSha256 = if ($null -eq $_.Metadata) { $null } else {
                    [string](Get-Phase00E1PropertyValue `
                        -Object $_.Metadata -Name 'SourceCaptureSha256')
                }
            }
        }
    )
    $uniqueAnchors = @($anchors | Sort-Object Path,Line,Type -Unique)
    $runRecord = [pscustomobject][ordered]@{
        PinnedSourceCommit = [string](Get-Phase00E1PropertyValue `
            -Object (Get-Phase00E1PropertyValue `
                -Object $envelope -Name 'pinned_source') -Name 'commit')
        RuntimeSha256 = [string](Get-Phase00E1PropertyValue `
            -Object (Get-Phase00E1PropertyValue `
                -Object $envelope -Name 'pinned_runtime') -Name 'sha256')
        RuntimeVersion = [string](Get-Phase00E1PropertyValue `
            -Object (Get-Phase00E1PropertyValue `
                -Object $envelope -Name 'pinned_runtime') -Name 'version')
        ExitCode = [int](Get-Phase00E1PropertyValue -Object $process -Name 'exit_code')
        TimedOut = Get-Phase00E1PropertyValue -Object $process -Name 'timed_out'
        SanitizerStatus = [string](Get-Phase00E1PropertyValue `
            -Object $envelope -Name 'capture_integrity_status')
        RawArtifacts = @($rawArtifactRecords)
        RequiredEventAnchors = @($uniqueAnchors)
        CleanupSucceeded = (
            (Get-Phase00E1PropertyValue -Object $cleanup -Name 'Required') -eq $true -and
            (Get-Phase00E1PropertyValue -Object $cleanup -Name 'Attempted') -eq $true -and
            (Get-Phase00E1PropertyValue -Object $cleanup -Name 'Succeeded') -eq $true
        )
        RemainingChildPids = [int[]]@($remainingPids)
        ProtectedSurfacesUnchanged = (
            (Get-Phase00E1PropertyValue -Object $protected -Name 'unchanged') -eq $true -and
            (Get-Phase00E1PropertyValue `
                -Object $protected -Name 'before_all_expected') -eq $true -and
            (Get-Phase00E1PropertyValue `
                -Object $protected -Name 'after_all_expected') -eq $true -and
            [int](Get-Phase00E1PropertyValue `
                -Object $protected -Name 'changed_count') -eq 0 -and
            (Get-Phase00E1PropertyValue -Object $live -Name 'Unchanged') -eq $true
        )
    }
    $uniqueProjectionReasons = [string[]]@($projectionReasons | Select-Object -Unique)
    return [pscustomobject][ordered]@{
        RepositoryRoot = $root
        CaseId = $CaseId
        Attempt = $Attempt
        ProjectionStatus = if ($uniqueProjectionReasons.Count -eq 0) {
            'PASS'
        } else { 'INVALID_RUN' }
        ProjectionReasonCodes = $uniqueProjectionReasons
        AttributableResults = @($attributableResults)
        ProviderLedger = $providerLedger
        ProcessProviderLedger = $processProviderLedger
        RunRecord = $runRecord
        BlockingExecutions = @($blockingExecutions)
        CaseFacts = $caseFacts
        Identity = $identity
        PiNoStrictState = $piNoStrictState
        ForwarderProjections = @($forwarderProjections)
        ForwarderAllProjectionCount = $forwarderAllProjectionCount
        YieldAttempts = @($yieldAttempts)
        LocalSchemaRejectionCount = $localSchemaRejectionCount
        LocalSchemaRetryCount = $localSchemaRetryCount
        SchemaOverrideCount = $schemaOverrideCount
        VerifiedRun = $verified
    }
}

function Get-Phase00E1ProviderObservationSummaries {
    param(
        [Parameter(Mandatory)][object[]]$Artifacts,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    $summaries = foreach ($artifact in @($Artifacts)) {
        $kind = [string](Get-Phase00E1PropertyValue -Object $artifact -Name 'Kind')
        if ($kind -notin @('stdout','session')) { continue }
        $path = [string](Get-Phase00E1PropertyValue -Object $artifact -Name 'Path')
        $ledger = if ($kind -ceq 'session') {
            (Get-Phase00E1PersistedSessionProjection -Path $path).ProviderLedger
        } else {
            $events = @(Read-Phase00E1JsonLineObjects -Path $path)
            Get-Phase00E1ProviderLedger -Events $events
        }
        [pscustomobject][ordered]@{
            Artifact = Get-Phase00E1RepositoryRelativePath `
                -RepositoryRoot $RepositoryRoot -Path $path
            RequestCount = [int]$ledger.RequestCount
            AttributedRequestCount = [int]$ledger.AttributedRequestCount
            UnattributedRequestCount = [int]$ledger.UnattributedRequestCount
            ResponseEndCount = [int]$ledger.ResponseEndCount
            RetryStartCount = [int]$ledger.RetryStartCount
            RetryEndCount = [int]$ledger.RetryEndCount
            RecoveredRetryCount = [int]$ledger.RecoveredRetryCount
            RetryExhaustedCount = [int]$ledger.RetryExhaustedCount
            Provider = [string]$ledger.Provider
            Model = [string]$ledger.Model
        }
    }
    return @($summaries)
}

function Get-Phase00E1SessionCaptureInventory {
    param([Parameter(Mandatory)][string]$SessionDirectory)

    $resolved = [IO.Path]::GetFullPath($SessionDirectory)
    if (-not (Test-Path -LiteralPath $resolved -PathType Container)) {
        throw "E1 session capture directory does not exist: $resolved"
    }

    $allFiles = @(Get-ChildItem -LiteralPath $resolved -File -Recurse -Force `
        -ErrorAction Stop | Sort-Object FullName)
    $regularFiles = @($allFiles | Where-Object {
        ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0
    })
    $sessionSources = @($regularFiles | Where-Object {
        $_.Extension -ieq '.jsonl'
    })
    $sessionPathSet = New-Object 'System.Collections.Generic.HashSet[string]' `
        ([StringComparer]::OrdinalIgnoreCase)
    foreach ($source in $sessionSources) {
        $null = $sessionPathSet.Add([IO.Path]::GetFullPath($source.FullName))
    }

    $expectedOutputArtifacts = @($regularFiles | Where-Object {
        $_.Extension -ieq '.md' -and
        $sessionPathSet.Contains([IO.Path]::ChangeExtension($_.FullName, '.jsonl'))
    })
    $expectedPathSet = New-Object 'System.Collections.Generic.HashSet[string]' `
        ([StringComparer]::OrdinalIgnoreCase)
    foreach ($artifact in $expectedOutputArtifacts) {
        $null = $expectedPathSet.Add([IO.Path]::GetFullPath($artifact.FullName))
    }
    $unexpectedArtifacts = @($allFiles | Where-Object {
        $fullName = [IO.Path]::GetFullPath($_.FullName)
        -not $sessionPathSet.Contains($fullName) -and
        -not $expectedPathSet.Contains($fullName)
    })

    return [pscustomobject][ordered]@{
        SessionSources = [object[]]@($sessionSources)
        ExpectedOutputArtifacts = [object[]]@($expectedOutputArtifacts)
        UnexpectedArtifacts = [object[]]@($unexpectedArtifacts)
    }
}

function Invoke-Phase00E1EvidenceCase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet(
            'AgentJtd',
            'AgentJsonSchema',
            'CallerOnly',
            'CallerOverAgent',
            'SessionOnly',
            'ProviderStrictOffControl',
            'ProviderStrictOn'
        )]
        [string]$CaseId,
        [ValidateRange(1,999)][int]$Attempt = 1,
        [Parameter(Mandatory)][string]$OmpExecutable,
        [string]$Model = 'omniroute/codex/gpt-5.6-sol-high',
        [switch]$AllowOverwrite
    )

    if ($Model.Length -gt 200 -or $Model -cnotmatch '^[A-Za-z0-9._/-]+$') {
        throw 'E1 model identifier contains unsupported characters.'
    }
    $repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
    $definition = Get-Phase00E1CaseDefinition -CaseId $CaseId
    $paths = Get-Phase00E1AttemptPaths -RepositoryRoot $repositoryRoot `
        -CaseId $CaseId -Attempt $Attempt

    # Everything above fixture creation is a non-provider preflight. In particular,
    # the only executable probe here is the pinned runtime's exact --version call.
    $sourceIdentity = Resolve-Phase00E1PinnedSource `
        -RepositoryRoot $repositoryRoot
    $runtimeIdentity = Resolve-Phase00E1PinnedOmpSource `
        -Path $OmpExecutable `
        -ExpectedSha256 '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6' `
        -ExpectedVersion 'omp/17.2.10' `
        -WorkingDirectory $repositoryRoot
    $null = Assert-Phase00E1AttemptDestinations -Paths $paths `
        -AllowOverwrite:$AllowOverwrite

    $protectedHashes = Get-Phase00E1ProtectedHashes
    $protectedBefore = Get-Phase00E1ProtectedSnapshot `
        -RepositoryRoot $repositoryRoot -ExpectedHashes $protectedHashes
    if (-not $protectedBefore.AllExpected) {
        throw 'E1 protected repository preflight does not match all nine pins.'
    }
    $liveSurfaces = @(Get-Phase00E1LiveHomeSurfaces)
    $liveBefore = @(Get-Phase00E1LiveHomeSnapshots -Surfaces $liveSurfaces)
    $secretValues = @(Get-Phase00E1SecretValues)
    $strictForwarderRequired = $CaseId -in @(
        'ProviderStrictOffControl',
        'ProviderStrictOn'
    )
    $gatewayTargetOrigin = 'http://127.0.0.1:20128'
    $forwarderPrerequisite = $null
    if ($strictForwarderRequired) {
        $forwarderPrerequisite = Get-Phase00E1ForwarderPrerequisite `
            -RepositoryRoot $repositoryRoot
    }

    $runnerStartedAt = [DateTimeOffset]::Now
    $disposableRoot = $null
    $fixture = $null
    $environment = $null
    $arguments = @()
    $promptSha256 = $null
    $processLaunchInvoked = $false
    $processResult = $null
    $forwarderHandle = $null
    $forwarderResult = $null
    $captureVerification = $null
    $artifactRecords = [Collections.Generic.List[object]]::new()
    $sessionSourceCount = 0
    $unexpectedSessionFileCount = 0
    $operationError = $null
    $protectedAfter = $null
    $protectedComparison = $null
    $liveAfter = @()
    $liveComparison = $null
    $reasonCodes = [Collections.Generic.List[string]]::new()
    $cleanupRecord = [ordered]@{
        Required = $false
        Attempted = $false
        Succeeded = $true
        ErrorType = $null
    }

    try {
        $disposableRoot = New-Phase00E1DisposableRoot -CaseId $CaseId
        $cleanupRecord['Required'] = $true
        $fixture = Initialize-Phase00E1DisposableFixture `
            -Root $disposableRoot `
            -RepositoryRoot $repositoryRoot `
            -RuntimeIdentity $runtimeIdentity `
            -ProviderBaseUrl "$gatewayTargetOrigin/v1"

        if ($strictForwarderRequired) {
            $forwarderCapturePath = Join-Path $fixture.CaptureDirectory 'forwarder.ndjson'
            $forwarderHandle = Start-Phase00E1Forwarder `
                -RepositoryRoot $repositoryRoot `
                -OutputPath $forwarderCapturePath `
                -PiNoStrictEffective:($CaseId -eq 'ProviderStrictOffControl') `
                -TargetOrigin $gatewayTargetOrigin `
                -Prerequisite $forwarderPrerequisite
            $forwarderBaseUrl = 'http://127.0.0.1:{0}/v1' -f $forwarderHandle.ListenPort
            $null = Set-Phase00E1DisposableModelCatalog `
                -Fixture $fixture -RepositoryRoot $repositoryRoot `
                -ProviderBaseUrl $forwarderBaseUrl
        }

        $promptPath = Join-Path $fixture.ProjectRoot `
            ([string]$definition.PromptRelativePath)
        if (-not (Test-Path -LiteralPath $promptPath -PathType Leaf)) {
            throw 'E1 copied case prompt is missing.'
        }
        $promptText = [IO.File]::ReadAllText($promptPath)
        $promptSha256 = Get-Phase00E1FileSha256 -Path $promptPath
        $expectedPromptKey = ([string]$definition.PromptRelativePath).Replace('\','/')
        $expectedPromptHashes = Get-Phase00E1ExpectedFixtureHashes
        if (-not $expectedPromptHashes.Contains($expectedPromptKey) -or
            $promptSha256 -ine [string]$expectedPromptHashes[$expectedPromptKey]) {
            throw 'E1 copied case prompt identity mismatch.'
        }

        $environment = Get-Phase00E1ProcessEnvironment `
            -CaseId $CaseId `
            -AgentDirectory $fixture.AgentDirectory `
            -DisposableRoot $disposableRoot `
            -RuntimeDirectory $fixture.RuntimeDirectory
        $arguments = @(Get-Phase00E1OmpArguments `
            -DisposableProject $fixture.ProjectRoot `
            -SessionDirectory $fixture.SessionDirectory `
            -ConfigPath $fixture.ConfigPath `
            -Model $Model `
            -PromptText $promptText `
            -RepositoryRoot $repositoryRoot)

        $processLaunchInvoked = $true
        $processResult = Invoke-Phase00E1CapturedProcess `
            -FilePath $fixture.RuntimeExecutable `
            -Arguments $arguments `
            -WorkingDirectory $fixture.ProjectRoot `
            -EnvironmentSet $environment.SetVariables `
            -EnvironmentRemove $environment.RemoveVariables `
            -TimeoutSeconds 540

        if ($null -ne $forwarderHandle) {
            try {
                $forwarderResult = Stop-Phase00E1Forwarder -Handle $forwarderHandle
            } finally {
                $forwarderHandle = $null
            }
        }

        $stdoutCapturePath = Join-Path $fixture.CaptureDirectory 'stdout.jsonl'
        $stderrCapturePath = Join-Path $fixture.CaptureDirectory 'stderr.txt'
        [IO.File]::WriteAllText(
            $stdoutCapturePath,
            [string]$processResult.Stdout,
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            $stderrCapturePath,
            [string]$processResult.Stderr,
            [Text.UTF8Encoding]::new($false)
        )

        if (-not (Test-Path -LiteralPath $paths.CaseDirectory -PathType Container)) {
            New-Item -ItemType Directory -Path $paths.CaseDirectory `
                -Force -ErrorAction Stop | Out-Null
        }
        if (Test-Path -LiteralPath $paths.SessionDirectory) {
            throw 'E1 session evidence destination appeared after preflight.'
        }
        New-Item -ItemType Directory -Path $paths.SessionDirectory `
            -ErrorAction Stop | Out-Null

        $stdoutMetadata = Protect-Phase00E1EventStream `
            -SourcePath $stdoutCapturePath `
            -DestinationPath $paths.StdoutPath `
            -RepositoryRoot $repositoryRoot `
            -DisposableRoot $disposableRoot `
            -FixtureHashes $fixture.FixtureHashes `
            -LiveHomePaths @($liveSurfaces.Path)
        $artifactRecords.Add([pscustomobject][ordered]@{
            Kind = 'stdout'
            Path = $paths.StdoutPath
            SourceRelativePathSha256 = $null
            Metadata = $stdoutMetadata
        })

        $stderrMetadata = Protect-Phase00E1TextStream `
            -SourcePath $stderrCapturePath `
            -DestinationPath $paths.StderrPath
        $artifactRecords.Add([pscustomobject][ordered]@{
            Kind = 'stderr'
            Path = $paths.StderrPath
            SourceRelativePathSha256 = $null
            Metadata = $stderrMetadata
        })

        $sessionInventory = Get-Phase00E1SessionCaptureInventory `
            -SessionDirectory $fixture.SessionDirectory
        $sessionSources = @($sessionInventory.SessionSources)
        $expectedSessionOutputFileCount = `
            @($sessionInventory.ExpectedOutputArtifacts).Count
        $unexpectedSessionFileCount = @($sessionInventory.UnexpectedArtifacts).Count
        $sessionSourceCount = $sessionSources.Count
        $sessionPrefix = $fixture.SessionDirectory.TrimEnd('\','/') + `
            [IO.Path]::DirectorySeparatorChar
        for ($index = 0; $index -lt $sessionSources.Count; $index += 1) {
            $source = $sessionSources[$index]
            $relativeSource = $source.FullName.Substring($sessionPrefix.Length).Replace('\','/')
            $destination = Join-Path $paths.SessionDirectory `
                ('session-{0:D3}.jsonl' -f ($index + 1))
            $metadata = Protect-Phase00E1EventStream `
                -SourcePath $source.FullName `
                -DestinationPath $destination `
                -RepositoryRoot $repositoryRoot `
                -DisposableRoot $disposableRoot `
                -FixtureHashes $fixture.FixtureHashes `
                -LiveHomePaths @($liveSurfaces.Path)
            $artifactRecords.Add([pscustomobject][ordered]@{
                Kind = 'session'
                Path = $destination
                SourceRelativePathSha256 = Get-Phase00E1StringSha256 `
                    -Text $relativeSource
                Metadata = $metadata
            })
        }

        if ($strictForwarderRequired) {
            if ($null -eq $forwarderResult) {
                throw 'E1 strict forwarder did not produce a lifecycle result.'
            }
            $forwarderMetadata = Protect-Phase00E1EventStream `
                -SourcePath $forwarderCapturePath `
                -DestinationPath $paths.ForwarderPath `
                -RepositoryRoot $repositoryRoot `
                -DisposableRoot $disposableRoot `
                -FixtureHashes $fixture.FixtureHashes `
                -LiveHomePaths @($liveSurfaces.Path)
            $artifactRecords.Add([pscustomobject][ordered]@{
                Kind = 'forwarder'
                Path = $paths.ForwarderPath
                SourceRelativePathSha256 = $null
                Metadata = $forwarderMetadata
            })
        }

        $artifactArray = [object[]]@($artifactRecords)
        $captureVerification = Test-Phase00E1SanitizedArtifacts `
            -Artifacts $artifactArray -SecretValues $secretValues
        foreach ($artifact in $artifactArray) {
            if ([string]$artifact.Metadata.Status -cne 'PASS') {
                foreach ($reason in @($artifact.Metadata.ReasonCodes)) {
                    $reasonCodes.Add([string]$reason)
                }
            }
        }
        if ([string]$captureVerification.Status -cne 'PASS') {
            foreach ($reason in @($captureVerification.ReasonCodes)) {
                $reasonCodes.Add([string]$reason)
            }
        }
        if ([int]$stdoutMetadata.SourceLineCount -eq 0) {
            $reasonCodes.Add('E1_STDOUT_CAPTURE_EMPTY')
        }
        if ($sessionSourceCount -eq 0) {
            $reasonCodes.Add('E1_SESSION_CAPTURE_MISSING')
        }
        if ($unexpectedSessionFileCount -gt 0) {
            $reasonCodes.Add('E1_UNEXPECTED_SESSION_ARTIFACT')
        }
        if ($processResult.TimedOut) {
            $reasonCodes.Add('E1_PROCESS_TIMEOUT')
        }
        if (@($processResult.RemainingChildPids).Count -gt 0) {
            $reasonCodes.Add('E1_PROCESS_CHILD_REMAINS')
        }
        if ($strictForwarderRequired -and -not $forwarderResult.LifecycleValid) {
            $reasonCodes.Add('E1_FORWARDER_LIFECYCLE_INVALID')
        }
    } catch {
        $operationError = $_
        $reasonCodes.Add('E1_RUNNER_OPERATION_ERROR')
    } finally {
        if ($null -ne $forwarderHandle) {
            try {
                try {
                    $forwarderResult = Stop-Phase00E1Forwarder -Handle $forwarderHandle
                } finally {
                    $forwarderHandle = $null
                }
                if (-not $forwarderResult.LifecycleValid) {
                    $reasonCodes.Add('E1_FORWARDER_LIFECYCLE_INVALID')
                }
            } catch {
                $reasonCodes.Add('E1_FORWARDER_STOP_FAILED')
            }
        }
        try {
            $protectedAfter = Get-Phase00E1ProtectedSnapshot `
                -RepositoryRoot $repositoryRoot -ExpectedHashes $protectedHashes
            $protectedComparison = Compare-Phase00E1ProtectedSnapshot `
                -Before $protectedBefore -After $protectedAfter
            if (-not $protectedComparison.Unchanged -or
                -not $protectedComparison.AfterAllExpected) {
                $reasonCodes.Add('E1_PROTECTED_REPOSITORY_DELTA')
            }
        } catch {
            $reasonCodes.Add('E1_PROTECTED_SNAPSHOT_FAILED')
        }
        try {
            $liveAfter = @(Get-Phase00E1LiveHomeSnapshots -Surfaces $liveSurfaces)
            $liveComparison = Compare-Phase00E1LiveHomeSnapshots `
                -Before $liveBefore -After $liveAfter
            if (-not $liveComparison.Unchanged) {
                $reasonCodes.Add('E1_LIVE_HOME_DELTA')
            }
        } catch {
            $reasonCodes.Add('E1_LIVE_HOME_SNAPSHOT_FAILED')
        }
        if (-not [string]::IsNullOrWhiteSpace($disposableRoot)) {
            $cleanupRecord['Attempted'] = $true
            try {
                Remove-Phase00E1DisposableRoot -Path $disposableRoot
                $cleanupRecord['Succeeded'] = $true
            } catch {
                $cleanupRecord['Succeeded'] = $false
                $cleanupRecord['ErrorType'] = $_.Exception.GetType().FullName
                $reasonCodes.Add('E1_DISPOSABLE_CLEANUP_FAILED')
            }
        }
    }

    $providerObservations = @()
    if ($artifactRecords.Count -gt 0) {
        try {
            $providerObservations = @(Get-Phase00E1ProviderObservationSummaries `
                -Artifacts ([object[]]@($artifactRecords)) `
                -RepositoryRoot $repositoryRoot)
        } catch {
            $reasonCodes.Add('E1_PROVIDER_OBSERVATION_SUMMARY_FAILED')
        }
    }
    $uniqueReasons = [string[]]@($reasonCodes | Select-Object -Unique)
    $captureIntegrityStatus = if ($uniqueReasons.Count -eq 0 -and $null -ne $processResult) {
        'PASS'
    } else {
        'INVALID_RUN'
    }

    if (-not (Test-Path -LiteralPath $paths.CaseDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $paths.CaseDirectory `
            -Force -ErrorAction Stop | Out-Null
    }
    $artifactEnvelopeRecords = @($artifactRecords | ForEach-Object {
        [pscustomobject][ordered]@{
            kind = [string]$_.Kind
            path = Get-Phase00E1RepositoryRelativePath `
                -RepositoryRoot $repositoryRoot -Path ([string]$_.Path)
            source_relative_path_sha256 = $_.SourceRelativePathSha256
            metadata = $_.Metadata
        }
    })
    $safeArguments = if ($null -ne $fixture -and -not [string]::IsNullOrWhiteSpace($promptSha256)) {
        @(
            '-p','--mode','json',
            '--cwd','<E1_DISPOSABLE_ROOT>/project',
            '--session-dir','<E1_DISPOSABLE_ROOT>/sessions',
            '--config','<E1_DISPOSABLE_ROOT>/project/.omp/config.yml',
            '--model',$Model,
            '--tools','task',
            '--approval-mode','yolo',
            '--max-time','8m',
            '--no-extensions','--no-skills','--no-rules','--no-lsp','--no-title',
            "<PROMPT_SHA256:$promptSha256>"
        )
    } else { @() }
    $processRecord = if ($null -eq $processResult) {
        $null
    } else {
        [ordered]@{
            process_id = [int]$processResult.ProcessId
            exit_code = [int]$processResult.ExitCode
            started_at = $processResult.StartedAt.ToString('o')
            completed_at = $processResult.CompletedAt.ToString('o')
            timed_out = [bool]$processResult.TimedOut
            descendant_pids_observed = [int[]]@($processResult.DescendantPidsObserved)
            remaining_child_pids = [int[]]@($processResult.RemainingChildPids)
        }
    }
    $forwarderRecord = if (-not $strictForwarderRequired) {
        [ordered]@{ required=$false; artifact_present=$false }
    } elseif ($null -eq $forwarderResult) {
        [ordered]@{ required=$true; artifact_present=(Test-Path -LiteralPath $paths.ForwarderPath) }
    } else {
        [ordered]@{
            required = $true
            source_sha256 = [string]$forwarderPrerequisite.SourceSha256
            node_sha256 = [string]$forwarderPrerequisite.NodeSha256
            target_origin = $gatewayTargetOrigin
            pi_no_strict_effective = ($CaseId -eq 'ProviderStrictOffControl')
            process_id = [int]$forwarderResult.ProcessId
            exit_code = [int]$forwarderResult.ExitCode
            timed_out = [bool]$forwarderResult.TimedOut
            remaining_child_pids = [int[]]@($forwarderResult.RemainingChildPids)
            listen_host = [string]$forwarderResult.ListenHost
            listen_port = [int]$forwarderResult.ListenPort
            port_closed = [bool]$forwarderResult.PortClosed
            projection_count = [int]$forwarderResult.ProjectionCount
            record_count = [int]$forwarderResult.RecordCount
            record_types = [string[]]@($forwarderResult.RecordTypes)
            stdout_remainder_sha256 = [string]$forwarderResult.StdoutRemainderSha256
            stderr_sha256 = [string]$forwarderResult.StderrSha256
            lifecycle_valid = [bool]$forwarderResult.LifecycleValid
            artifact_present = Test-Path -LiteralPath $paths.ForwarderPath
        }
    }
    $fixtureRecord = if ($null -eq $fixture) {
        $null
    } else {
        [ordered]@{
            source_fixture_matched = [bool]$fixture.SourceFixtureMatched
            copied_fixture_matched = [bool]$fixture.CopiedFixtureMatched
            fixture_hashes = $fixture.FixtureHashes
            model_catalog_sha256 = [string]$fixture.ModelCatalogSha256
            runtime_source_sha256 = [string]$fixture.RuntimeSourceSha256
            runtime_copied_sha256 = [string]$fixture.RuntimeCopiedSha256
            runtime_version = [string]$fixture.RuntimeVersion
        }
    }
    $environmentRecord = if ($null -eq $environment) { $null } else { $environment.Record }
    $protectedRecord = if ($null -eq $protectedComparison) {
        $null
    } else {
        [ordered]@{
            unchanged = [bool]$protectedComparison.Unchanged
            before_all_expected = [bool]$protectedComparison.BeforeAllExpected
            after_all_expected = [bool]$protectedComparison.AfterAllExpected
            changed_paths = [string[]]@($protectedComparison.ChangedPaths)
            changed_count = [int]$protectedComparison.ChangedCount
        }
    }
    $operationErrorType = if ($null -eq $operationError) {
        $null
    } else {
        $operationError.Exception.GetType().FullName
    }
    $envelope = [ordered]@{
        record_type = 'phase00_e1_run'
        schema_version = 1
        case_id = $CaseId
        case_slug = Get-Phase00E1CaseSlug -CaseId $CaseId
        attempt = $Attempt
        execution_order = [int]$definition.ExecutionOrder
        capture_integrity_status = $captureIntegrityStatus
        case_status = $null
        case_oracle_evaluated = $false
        reason_codes = $uniqueReasons
        runner_started_at = $runnerStartedAt.ToString('o')
        runner_completed_at = [DateTimeOffset]::Now.ToString('o')
        pinned_source = [ordered]@{
            source_root = '<E1_REPOSITORY_ROOT>/_research/upstreams/oh-my-pi'
            commit = [string]$sourceIdentity.Commit
            clean = [bool]$sourceIdentity.Clean
            origin = [string]$sourceIdentity.Origin
        }
        pinned_runtime = [ordered]@{
            sha256 = [string]$runtimeIdentity.Sha256
            version = [string]$runtimeIdentity.Version
            version_probe_arguments = [string[]]@($runtimeIdentity.ProbeArguments)
            version_probe_exit_code = [int]$runtimeIdentity.ProbeExitCode
            version_probe_timed_out = [bool]$runtimeIdentity.ProbeTimedOut
        }
        fixture = $fixtureRecord
        command = [ordered]@{
            executable = '<E1_DISPOSABLE_ROOT>/runtime/omp.exe'
            arguments = $safeArguments
            prompt_sha256 = $promptSha256
            model = $Model
            launch_invoked = $processLaunchInvoked
        }
        environment = $environmentRecord
        process = $processRecord
        artifacts = $artifactEnvelopeRecords
        session_capture = [ordered]@{
            jsonl_source_count = $sessionSourceCount
            expected_output_file_count = $expectedSessionOutputFileCount
            unexpected_file_count = $unexpectedSessionFileCount
        }
        capture_verification = $captureVerification
        provider_observations = [ordered]@{
            per_artifact = $providerObservations
            counts_are_per_artifact_not_deduplicated = $true
        }
        forwarder = $forwarderRecord
        protected_repository = $protectedRecord
        live_agent_home = $liveComparison
        cleanup = $cleanupRecord
        operation_error_type = $operationErrorType
    }
    $privatePaths = [Collections.Generic.List[string]]::new()
    $privatePaths.Add($repositoryRoot)
    $privatePaths.Add([string]$runtimeIdentity.Path)
    if (-not [string]::IsNullOrWhiteSpace($disposableRoot)) {
        $privatePaths.Add($disposableRoot)
    }
    foreach ($surface in $liveSurfaces) { $privatePaths.Add([string]$surface.Path) }
    $runMetadata = Write-Phase00E1RunEnvelope `
        -Path $paths.RunPath -Envelope $envelope `
        -SecretValues $secretValues -PrivatePaths ([string[]]@($privatePaths))

    $result = [pscustomobject][ordered]@{
        CaseId = $CaseId
        Attempt = $Attempt
        CaptureIntegrityStatus = $captureIntegrityStatus
        ReasonCodes = $uniqueReasons
        RunPath = $paths.RunPath
        RunSha256 = $runMetadata.Sha256
        ProviderProcessAttempts = if ($processLaunchInvoked) { 1 } else { 0 }
    }
    if ($captureIntegrityStatus -eq 'INVALID_RUN') {
        $relativeRunPath = Get-Phase00E1RepositoryRelativePath `
            -RepositoryRoot $repositoryRoot -Path $paths.RunPath
        throw "E1 runner recorded INVALID_RUN; inspect $relativeRunPath and do not rerun automatically."
    }
    return $result
}

function Get-Phase00E1ObjectPropertyNames {
    param([AllowNull()]$Object)

    if ($null -eq $Object) { return @() }
    if ($Object -is [Collections.IDictionary]) {
        return [string[]]@($Object.Keys | ForEach-Object { [string]$_ })
    }
    return [string[]]@($Object.PSObject.Properties.Name)
}

function Test-Phase00E1ExactData {
    param(
        [AllowNull()]$Data,
        [Parameter(Mandatory)][string]$Property,
        [Parameter(Mandatory)][string]$Value
    )

    $names = @(Get-Phase00E1ObjectPropertyNames -Object $Data | Sort-Object)
    return (
        $names.Count -eq 1 -and
        $names[0] -ceq $Property -and
        [string](Get-Phase00E1PropertyValue -Object $Data -Name $Property) -ceq $Value
    )
}

function Test-Phase00E1ForbiddenStrictData {
    param([AllowNull()]$Data)

    $names = @(Get-Phase00E1ObjectPropertyNames -Object $Data)
    if ($names -contains 'forbidden_extra') { return $true }
    foreach ($name in $names) {
        $value = [string](Get-Phase00E1PropertyValue -Object $Data -Name $name)
        if ($value -in @('E1_STRICT_FORBIDDEN','E1_FORBIDDEN_EXTRA')) { return $true }
    }
    return $false
}

function Get-Phase00E1BlockingInvalidReasons {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn')]
        [string]$CaseId,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$BlockingExecutions,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$AttributableResults
    )

    $expected = if ($CaseId -eq 'SessionOnly') {
        [ordered]@{
            carrier = 'phase00-e1-session-carrier'
            leaf = 'phase00-e1-session-leaf'
        }
    } else {
        [ordered]@{
            target = [string](Get-Phase00E1CaseDefinition -CaseId $CaseId).Agent
        }
    }
    $reasons = [Collections.Generic.List[string]]::new()
    $records = @($BlockingExecutions)
    $byRole = @{}
    foreach ($record in $records) {
        $role = [string](Get-Phase00E1PropertyValue -Object $record -Name 'Role')
        if ([string]::IsNullOrWhiteSpace($role) -or $byRole.ContainsKey($role)) {
            $reasons.Add('E1_BLOCKING_FACTS_INCOMPLETE')
            continue
        }
        $byRole[$role] = $record
    }
    if ($records.Count -ne $expected.Count -or
        @($expected.Keys | Where-Object { -not $byRole.ContainsKey([string]$_) }).Count -gt 0) {
        $reasons.Add('E1_BLOCKING_FACTS_INCOMPLETE')
    }
    foreach ($role in $expected.Keys) {
        if (-not $byRole.ContainsKey([string]$role)) { continue }
        $record = $byRole[[string]$role]
        $required = @(
            'Role','Agent','DefinitionBlocking','SetupBlocking',
            'ExecutionMode','AsyncAcknowledgement'
        )
        if (@($required | Where-Object {
            -not (Test-Phase00E1HasProperty -Object $record -Name $_)
        }).Count -gt 0 -or
            [string](Get-Phase00E1PropertyValue -Object $record -Name 'Agent') -cne
                [string]$expected[$role]) {
            $reasons.Add('E1_BLOCKING_FACTS_INCOMPLETE')
            continue
        }
        if ((Get-Phase00E1PropertyValue -Object $record -Name 'AsyncAcknowledgement') -eq $true) {
            $reasons.Add('E1_ASYNC_ACKNOWLEDGEMENT')
        }
        if ((Get-Phase00E1PropertyValue -Object $record -Name 'DefinitionBlocking') -ne $true -or
            (Get-Phase00E1PropertyValue -Object $record -Name 'SetupBlocking') -ne $true -or
            [string](Get-Phase00E1PropertyValue -Object $record -Name 'ExecutionMode') -cne 'blocking') {
            $reasons.Add('E1_BLOCKING_EXECUTION_NOT_PROVEN')
        }
    }
    foreach ($result in @($AttributableResults)) {
        if (-not (Test-Phase00E1HasProperty -Object $result -Name 'IsAsyncAcknowledgement')) {
            $reasons.Add('E1_ASYNC_ACKNOWLEDGEMENT_STATE_MISSING')
        } elseif ((Get-Phase00E1PropertyValue `
            -Object $result -Name 'IsAsyncAcknowledgement') -eq $true) {
            $reasons.Add('E1_ASYNC_ACKNOWLEDGEMENT')
        }
    }
    return [string[]]@($reasons | Select-Object -Unique)
}

function Get-Phase00E1CaseSetupInvalidReasons {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn')]
        [string]$CaseId,
        [Parameter(Mandatory)]$CaseFacts
    )

    $reasons = [Collections.Generic.List[string]]::new()
    $required = @(
        'CallerSchemaState','AgentSchemaState','SessionSchemaState',
        'AgentSchemaDialect','ChildInitializationSource',
        'SchemaOverrideObservable','SchemaOverrideObserved','SelectedResultRole',
        'OuterCarrierResultSource','CarrierCallerSchemaState'
    )
    if (@($required | Where-Object {
        -not (Test-Phase00E1HasProperty -Object $CaseFacts -Name $_)
    }).Count -gt 0) {
        return @('E1_CASE_FACTS_INCOMPLETE')
    }
    $callerState = [string](Get-Phase00E1PropertyValue `
        -Object $CaseFacts -Name 'CallerSchemaState')
    $agentState = [string](Get-Phase00E1PropertyValue `
        -Object $CaseFacts -Name 'AgentSchemaState')
    $sessionState = [string](Get-Phase00E1PropertyValue `
        -Object $CaseFacts -Name 'SessionSchemaState')
    $dialect = [string](Get-Phase00E1PropertyValue `
        -Object $CaseFacts -Name 'AgentSchemaDialect')

    switch ($CaseId) {
        'AgentJtd' {
            if ($callerState -cne 'ABSENT') {
                $reasons.Add('E1_CALLER_SCHEMA_OMISSION_VIOLATED')
            }
            if ($agentState -cne 'PRESENT' -or $dialect -cne 'JTD') {
                $reasons.Add('E1_AGENT_SCHEMA_SETUP_MISMATCH')
            }
            if ($sessionState -cne 'ABSENT') {
                $reasons.Add('E1_SESSION_SCHEMA_SETUP_MISMATCH')
            }
        }
        'AgentJsonSchema' {
            if ($callerState -cne 'ABSENT') {
                $reasons.Add('E1_CALLER_SCHEMA_OMISSION_VIOLATED')
            }
            if ($agentState -cne 'PRESENT' -or $dialect -cne 'JSON_SCHEMA') {
                $reasons.Add('E1_AGENT_SCHEMA_SETUP_MISMATCH')
            }
            if ($sessionState -cne 'ABSENT') {
                $reasons.Add('E1_SESSION_SCHEMA_SETUP_MISMATCH')
            }
        }
        'CallerOnly' {
            if ($callerState -cne 'PRESENT') {
                $reasons.Add('E1_CALLER_SCHEMA_SETUP_MISMATCH')
            }
            if ($agentState -cne 'ABSENT') {
                $reasons.Add('E1_AGENT_SCHEMA_SETUP_MISMATCH')
            }
            if ($sessionState -cne 'ABSENT') {
                $reasons.Add('E1_SESSION_SCHEMA_SETUP_MISMATCH')
            }
        }
        'CallerOverAgent' {
            if ($callerState -cne 'PRESENT') {
                $reasons.Add('E1_CALLER_SCHEMA_SETUP_MISMATCH')
            }
            if ($agentState -cne 'PRESENT') {
                $reasons.Add('E1_AGENT_SCHEMA_SETUP_MISMATCH')
            }
            if ($sessionState -cne 'ABSENT') {
                $reasons.Add('E1_SESSION_SCHEMA_SETUP_MISMATCH')
            }
        }
        'SessionOnly' {
            if ($callerState -cne 'ABSENT') {
                $reasons.Add('E1_CALLER_SCHEMA_OMISSION_VIOLATED')
            }
            if ($agentState -cne 'ABSENT') {
                $reasons.Add('E1_AGENT_SCHEMA_SETUP_MISMATCH')
            }
            if ($sessionState -cne 'PRESENT') {
                $reasons.Add('E1_SESSION_SCHEMA_SETUP_MISMATCH')
            }
            if ([string](Get-Phase00E1PropertyValue `
                -Object $CaseFacts -Name 'SelectedResultRole') -cne 'nested_leaf') {
                $reasons.Add('E1_NESTED_LEAF_NOT_SELECTED')
            }
            if ([string](Get-Phase00E1PropertyValue `
                -Object $CaseFacts -Name 'OuterCarrierResultSource') -cne 'caller' -or
                [string](Get-Phase00E1PropertyValue `
                -Object $CaseFacts -Name 'CarrierCallerSchemaState') -cne 'PRESENT') {
                $reasons.Add('E1_CARRIER_SETUP_INCOMPLETE')
            }
        }
        { $_ -in @('ProviderStrictOffControl','ProviderStrictOn') } {
            if ($callerState -cne 'PRESENT') {
                $reasons.Add('E1_CALLER_SCHEMA_SETUP_MISMATCH')
            }
            if ($agentState -cne 'ABSENT') {
                $reasons.Add('E1_AGENT_SCHEMA_SETUP_MISMATCH')
            }
            if ($sessionState -cne 'ABSENT') {
                $reasons.Add('E1_SESSION_SCHEMA_SETUP_MISMATCH')
            }
        }
    }
    return [string[]]@($reasons | Select-Object -Unique)
}

function Get-Phase00E1StrictStructuralInvalidReasons {
    param(
        [Parameter(Mandatory)]$AttemptEvidence,
        [Parameter(Mandatory)]$Identity,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ForwarderProjections,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$YieldAttempts
    )

    $reasons = [Collections.Generic.List[string]]::new()
    $caseId = [string](Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'CaseId')
    $expectedYieldParametersSha256 = switch ($caseId) {
        'ProviderStrictOffControl' {
            'DB58E598EDFCAAB815558716F24EED4D61FD2B9F5057608E8409C6369B234EEE'
        }
        'ProviderStrictOn' {
            'BA45FA65ACE1C6653B74557015A2993085CF72FAF126D2CB01A76553DE05279C'
        }
        default { $null }
    }
    if ($null -eq $expectedYieldParametersSha256) {
        $reasons.Add('E1_STRICT_IDENTITY_MISMATCH')
    }
    $expectedIdentity = [ordered]@{
        PromptSha256 = '15B1C1BA9133F89B1125FCD089F87147F282DC1AAF315FFB303322A46AC87113'
        AssignmentSha256 = 'D8F7E058CCD96702BAB3D6AF2698356736B9525785BB6C6684F0FBAAC12BE88A'
        OutputSchemaSha256 = 'D40C5DF70D19DB184EC8E5A7FA651E05790BFC4579E29C1ABA0E214C95712E59'
        AgentSha256 = 'F8E53C651A41707CA2226F3CE687F97236BB0F0600024E42E87ACD14B85293EA'
        YieldParametersSha256 = $expectedYieldParametersSha256
        Agent = 'phase00-e1-provider-strict'
        Model = 'codex/gpt-5.6-sol-high'
        RuntimeSha256 = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
        RuntimeVersion = 'omp/17.2.10'
        Gateway = 'omniroute:127.0.0.1:20128'
    }
    if ($null -eq $Identity) {
        $reasons.Add('E1_STRICT_IDENTITY_INCOMPLETE')
    } else {
        foreach ($property in $expectedIdentity.Keys) {
            if (-not (Test-Phase00E1HasProperty -Object $Identity -Name $property)) {
                $reasons.Add('E1_STRICT_IDENTITY_INCOMPLETE')
            } elseif ([string](Get-Phase00E1PropertyValue `
                -Object $Identity -Name $property) -cne [string]$expectedIdentity[$property]) {
                $reasons.Add('E1_STRICT_IDENTITY_MISMATCH')
            }
        }
    }
    $projections = @($ForwarderProjections)
    if ($projections.Count -eq 0) {
        $reasons.Add('E1_FORWARDER_PROJECTION_MISSING')
    }
    $projectionRequired = @(
        'record_type','request_index','request_path','forwarded',
        'gateway_http_status','gateway','api','yield_tool_present',
        'yield_strict_field_present','yield_strict','yield_parameters_sha256',
        'allowed_data_properties','required_data_properties',
        'data_additional_properties','pi_no_strict_effective'
    )
    foreach ($projection in $projections) {
        if (@($projectionRequired | Where-Object {
            -not (Test-Phase00E1HasProperty -Object $projection -Name $_)
        }).Count -gt 0) {
            $reasons.Add('E1_FORWARDER_PROJECTION_INCOMPLETE')
            continue
        }
        $httpStatus = Get-Phase00E1PropertyValue `
            -Object $projection -Name 'gateway_http_status'
        if ([string](Get-Phase00E1PropertyValue `
            -Object $projection -Name 'record_type') -cne 'phase00_e1_request_projection' -or
            [string](Get-Phase00E1PropertyValue `
            -Object $projection -Name 'request_path') -cne '/v1/responses' -or
            (Get-Phase00E1PropertyValue -Object $projection -Name 'forwarded') -ne $true -or
            $null -eq $httpStatus -or [int]$httpStatus -lt 100 -or [int]$httpStatus -gt 599 -or
            [string](Get-Phase00E1PropertyValue `
            -Object $projection -Name 'gateway') -cne 'omniroute' -or
            [string](Get-Phase00E1PropertyValue `
            -Object $projection -Name 'api') -cne 'openai-responses' -or
            (Get-Phase00E1PropertyValue `
            -Object $projection -Name 'yield_tool_present') -ne $true) {
            $reasons.Add('E1_GATEWAY_RESPONSE_NOT_ATTRIBUTABLE')
        }
        if ($null -ne $Identity -and [string](Get-Phase00E1PropertyValue `
            -Object $projection -Name 'yield_parameters_sha256') -cne
            [string](Get-Phase00E1PropertyValue `
            -Object $Identity -Name 'YieldParametersSha256')) {
            $reasons.Add('E1_STRICT_IDENTITY_MISMATCH')
        }
    }
    $providerLedger = Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'ProviderLedger'
    $providerRequestCount = [int](Get-Phase00E1PropertyValue `
        -Object $providerLedger -Name 'RequestCount')
    if ($projections.Count -ne $providerRequestCount) {
        $reasons.Add('E1_FORWARDER_PROVIDER_COUNT_MISMATCH')
    }
    $projectionIndexes = @($projections | ForEach-Object {
        [int](Get-Phase00E1PropertyValue -Object $_ -Name 'request_index')
    })
    $sortedUniqueIndexes = @($projectionIndexes | Sort-Object -Unique)
    if (
        @($projectionIndexes | Where-Object { $_ -le 0 }).Count -gt 0 -or
        $sortedUniqueIndexes.Count -ne $projectionIndexes.Count -or
        ($projectionIndexes -join ',') -cne (($projectionIndexes | Sort-Object) -join ',')
    ) {
        $reasons.Add('E1_FORWARDER_REQUEST_INDEX_INVALID')
    }
    $attempts = @($YieldAttempts)
    if ($attempts.Count -eq 0) {
        $reasons.Add('E1_YIELD_ATTEMPT_EVIDENCE_MISSING')
    }
    foreach ($attempt in $attempts) {
        if (@('Index','ProviderReturned','Terminal','Data','LocalValidationRejected','LocalValidationReason' |
            Where-Object { -not (Test-Phase00E1HasProperty -Object $attempt -Name $_) }).Count -gt 0) {
            $reasons.Add('E1_YIELD_ATTEMPT_EVIDENCE_INCOMPLETE')
        }
    }
    return [string[]]@($reasons | Select-Object -Unique)
}

function Test-Phase00E1StrictAttemptFacts {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('ProviderStrictOffControl','ProviderStrictOn')]
        [string]$CaseId,
        [Parameter(Mandatory)]$AttemptEvidence,
        [Parameter(Mandatory)]$BaseFacts
    )

    $projections = @(Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'ForwarderProjections')
    $attempts = @(Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'YieldAttempts' | Sort-Object Index)
    $caseFacts = Get-Phase00E1PropertyValue -Object $AttemptEvidence -Name 'CaseFacts'
    $result = @(Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'AttributableResults')[0]
    $structuredOutput = Get-Phase00E1PropertyValue `
        -Object $result -Name 'StructuredOutput'
    $finalData = Get-Phase00E1PropertyValue -Object $structuredOutput -Name 'data'
    $failureReasons = [Collections.Generic.List[string]]::new()

    $successfulGatewayResponses = @($projections | Where-Object {
        $status = [int](Get-Phase00E1PropertyValue `
            -Object $_ -Name 'gateway_http_status')
        $status -ge 200 -and $status -lt 300
    })
    if ($successfulGatewayResponses.Count -eq 0) {
        return New-Phase00E1Analysis -Status INVALID_RUN `
            -ReasonCodes @('E1_GATEWAY_SUCCESS_RESPONSE_ABSENT') -Facts $BaseFacts
    }

    if ([string](Get-Phase00E1PropertyValue `
        -Object $caseFacts -Name 'ChildInitializationSource') -cne 'caller') {
        $failureReasons.Add('E1_CHILD_SCHEMA_SOURCE_MISMATCH')
    }
    if ((Get-Phase00E1PropertyValue `
        -Object $caseFacts -Name 'SchemaOverrideObservable') -eq $true -and
        (Get-Phase00E1PropertyValue `
        -Object $caseFacts -Name 'SchemaOverrideObserved') -ne $true) {
        $failureReasons.Add('E1_SCHEMA_OVERRIDE_MISMATCH')
    }

    $isOff = $CaseId -eq 'ProviderStrictOffControl'
    $expectedPiState = if ($isOff) { 'PRESENT_1' } else { 'ABSENT' }
    if ([string](Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'PiNoStrictState') -cne $expectedPiState) {
        $failureReasons.Add('E1_STRICT_ENVIRONMENT_MISMATCH')
    }
    foreach ($projection in $projections) {
        $strictPresent = Get-Phase00E1PropertyValue `
            -Object $projection -Name 'yield_strict_field_present'
        $strictValue = Get-Phase00E1PropertyValue `
            -Object $projection -Name 'yield_strict'
        $piEffective = Get-Phase00E1PropertyValue `
            -Object $projection -Name 'pi_no_strict_effective'
        if ($isOff) {
            if ($strictPresent -ne $false -or $null -ne $strictValue -or $piEffective -ne $true) {
                $failureReasons.Add('E1_STRICT_OFF_WIRE_MISMATCH')
            }
        } else {
            if ($strictPresent -ne $true -or $strictValue -ne $true -or $piEffective -ne $false) {
                $failureReasons.Add('E1_STRICT_ON_WIRE_MISMATCH')
            }
        }
        if (@(Get-Phase00E1PropertyValue `
            -Object $projection -Name 'allowed_data_properties') -join ',' -cne 'allowed' -or
            @(Get-Phase00E1PropertyValue `
            -Object $projection -Name 'required_data_properties') -join ',' -cne 'allowed' -or
            (Get-Phase00E1PropertyValue `
            -Object $projection -Name 'data_additional_properties') -ne $false) {
            $failureReasons.Add('E1_PROVIDER_DATA_SCHEMA_MISMATCH')
        }
    }

    if ($isOff) {
        $first = if ($attempts.Count -gt 0) { $attempts[0] } else { $null }
        $firstData = if ($null -eq $first) { $null } else {
            Get-Phase00E1PropertyValue -Object $first -Name 'Data'
        }
        if ($null -eq $first -or -not (Test-Phase00E1ForbiddenStrictData -Data $firstData)) {
            return New-Phase00E1Analysis -Status INVALID_RUN `
                -ReasonCodes @('E1_STRICT_CONTROL_NOT_EXERCISED') -Facts $BaseFacts
        }
        if ($attempts.Count -ne 2 -or
            [int](Get-Phase00E1PropertyValue -Object $attempts[0] -Name 'Index') -ne 1 -or
            [int](Get-Phase00E1PropertyValue -Object $attempts[1] -Name 'Index') -ne 2 -or
            (Get-Phase00E1PropertyValue -Object $attempts[0] -Name 'ProviderReturned') -ne $true -or
            (Get-Phase00E1PropertyValue -Object $attempts[1] -Name 'ProviderReturned') -ne $true -or
            (Get-Phase00E1PropertyValue -Object $attempts[0] -Name 'Terminal') -ne $true -or
            (Get-Phase00E1PropertyValue -Object $attempts[1] -Name 'Terminal') -ne $true -or
            (Get-Phase00E1PropertyValue -Object $attempts[0] -Name 'LocalValidationRejected') -ne $true -or
            [string](Get-Phase00E1PropertyValue `
            -Object $attempts[0] -Name 'LocalValidationReason') -cne 'schema' -or
            (Get-Phase00E1PropertyValue -Object $attempts[1] -Name 'LocalValidationRejected') -ne $false -or
            -not (Test-Phase00E1ExactData `
            -Data (Get-Phase00E1PropertyValue -Object $attempts[1] -Name 'Data') `
            -Property 'allowed' -Value 'E1_STRICT_ALLOWED')) {
            $failureReasons.Add('E1_STRICT_OFF_YIELD_SEQUENCE_MISMATCH')
        }
        if ([int](Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'LocalSchemaRejectionCount') -ne 1) {
            $failureReasons.Add('E1_STRICT_OFF_REJECTION_COUNT_MISMATCH')
        }
        if ([int](Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'LocalSchemaRetryCount') -ne 1) {
            $failureReasons.Add('E1_STRICT_OFF_RETRY_COUNT_MISMATCH')
        }
    } else {
        if ($attempts.Count -ne 1 -or
            [int](Get-Phase00E1PropertyValue -Object $attempts[0] -Name 'Index') -ne 1 -or
            (Get-Phase00E1PropertyValue -Object $attempts[0] -Name 'ProviderReturned') -ne $true -or
            (Get-Phase00E1PropertyValue -Object $attempts[0] -Name 'Terminal') -ne $true -or
            (Get-Phase00E1PropertyValue -Object $attempts[0] -Name 'LocalValidationRejected') -ne $false -or
            -not (Test-Phase00E1ExactData `
            -Data (Get-Phase00E1PropertyValue -Object $attempts[0] -Name 'Data') `
            -Property 'allowed' -Value 'E1_STRICT_ALLOWED')) {
            $failureReasons.Add('E1_STRICT_ON_FIRST_ATTEMPT_MISMATCH')
        }
        if ([int](Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'LocalSchemaRejectionCount') -ne 0 -or
            [int](Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'LocalSchemaRetryCount') -ne 0) {
            $failureReasons.Add('E1_STRICT_ON_LOCAL_RETRY_OBSERVED')
        }
        foreach ($attempt in $attempts) {
            if (Test-Phase00E1ForbiddenStrictData -Data `
                (Get-Phase00E1PropertyValue -Object $attempt -Name 'Data')) {
                $failureReasons.Add('E1_STRICT_ON_FORBIDDEN_DATA_OBSERVED')
            }
        }
    }
    if ([int](Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'SchemaOverrideCount') -ne 0) {
        $failureReasons.Add('E1_SCHEMA_OVERRIDE_OBSERVED')
    }
    if (-not (Test-Phase00E1ExactData -Data $finalData `
        -Property 'allowed' -Value 'E1_STRICT_ALLOWED')) {
        $failureReasons.Add('E1_STRICT_FINAL_DATA_MISMATCH')
    }
    $uniqueFailures = [string[]]@($failureReasons | Select-Object -Unique)
    if ($uniqueFailures.Count -gt 0) {
        return New-Phase00E1Analysis -Status FAIL `
            -ReasonCodes $uniqueFailures -Facts $BaseFacts
    }
    $passReason = if ($isOff) {
        'E1_PROVIDER_STRICT_OFF_PASS'
    } else {
        'E1_PROVIDER_STRICT_ON_PASS'
    }
    return New-Phase00E1Analysis -Status PASS `
        -ReasonCodes @($passReason) -Facts $BaseFacts
}

function Test-Phase00E1Attempt {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn')]
        [string]$CaseId,
        [Parameter(Mandatory)]$AttemptEvidence
    )

    $definition = Get-Phase00E1CaseDefinition -CaseId $CaseId
    $facts = [ordered]@{
        CaseId = $CaseId
        Definition = $definition
        AttemptEvidence = $AttemptEvidence
        CommonAnalysis = $null
    }
    $required = @(
        'CaseId','Attempt','ProjectionStatus','ProjectionReasonCodes',
        'AttributableResults','ProviderLedger','RunRecord',
        'BlockingExecutions','CaseFacts'
    )
    $invalidReasons = [Collections.Generic.List[string]]::new()
    if (@($required | Where-Object {
        -not (Test-Phase00E1HasProperty -Object $AttemptEvidence -Name $_)
    }).Count -gt 0) {
        return New-Phase00E1Analysis -Status INVALID_RUN `
            -ReasonCodes @('E1_ATTEMPT_EVIDENCE_INCOMPLETE') -Facts $facts
    }
    if ([string](Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'CaseId') -cne $CaseId) {
        $invalidReasons.Add('E1_CASE_ID_MISMATCH')
    }
    if ([int](Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'Attempt') -lt 1) {
        $invalidReasons.Add('E1_ATTEMPT_NUMBER_INVALID')
    }
    $projectionStatus = [string](Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'ProjectionStatus')
    if ($projectionStatus -cne 'PASS') {
        $projectionReasons = @(Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'ProjectionReasonCodes')
        if ($projectionReasons.Count -eq 0) {
            $invalidReasons.Add('E1_ATTEMPT_PROJECTION_INVALID')
        } else {
            foreach ($reason in $projectionReasons) {
                $invalidReasons.Add([string]$reason)
            }
        }
    }
    $results = @(Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'AttributableResults')
    foreach ($reason in @(Get-Phase00E1BlockingInvalidReasons `
        -CaseId $CaseId `
        -BlockingExecutions @(Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'BlockingExecutions') `
        -AttributableResults $results)) {
        $invalidReasons.Add([string]$reason)
    }
    $caseFacts = Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'CaseFacts'
    foreach ($reason in @(Get-Phase00E1CaseSetupInvalidReasons `
        -CaseId $CaseId -CaseFacts $caseFacts)) {
        $invalidReasons.Add([string]$reason)
    }
    if ($results.Count -eq 1) {
        $expectedAgent = if ($CaseId -eq 'SessionOnly') {
            'phase00-e1-session-leaf'
        } else {
            [string]$definition.Agent
        }
        if ([string](Get-Phase00E1PropertyValue `
            -Object $results[0] -Name 'Agent') -cne $expectedAgent) {
            $invalidReasons.Add('E1_ATTRIBUTABLE_AGENT_MISMATCH')
        }
    }
    if ($CaseId -in @('ProviderStrictOffControl','ProviderStrictOn')) {
        $strictRequired = @(
            'Identity','PiNoStrictState','ForwarderProjections','YieldAttempts',
            'LocalSchemaRejectionCount','LocalSchemaRetryCount','SchemaOverrideCount'
        )
        if (@($strictRequired | Where-Object {
            -not (Test-Phase00E1HasProperty -Object $AttemptEvidence -Name $_)
        }).Count -gt 0) {
            $invalidReasons.Add('E1_STRICT_EVIDENCE_INCOMPLETE')
        } else {
            foreach ($reason in @(Get-Phase00E1StrictStructuralInvalidReasons `
                -AttemptEvidence $AttemptEvidence `
                -Identity (Get-Phase00E1PropertyValue `
                    -Object $AttemptEvidence -Name 'Identity') `
                -ForwarderProjections @(Get-Phase00E1PropertyValue `
                    -Object $AttemptEvidence -Name 'ForwarderProjections') `
                -YieldAttempts @(Get-Phase00E1PropertyValue `
                    -Object $AttemptEvidence -Name 'YieldAttempts'))) {
                $invalidReasons.Add([string]$reason)
            }
        }
    }
    $uniqueInvalid = [string[]]@($invalidReasons | Select-Object -Unique)
    if ($uniqueInvalid.Count -gt 0) {
        return New-Phase00E1Analysis -Status INVALID_RUN `
            -ReasonCodes $uniqueInvalid -Facts $facts
    }

    $common = Test-Phase00E1CommonAttempt -Definition $definition `
        -AttributableResults $results `
        -ProviderLedger (Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'ProviderLedger') `
        -RunRecord (Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'RunRecord')
    $facts['CommonAnalysis'] = $common
    if ([string]$common.Status -cne 'PASS') {
        return New-Phase00E1Analysis -Status ([string]$common.Status) `
            -ReasonCodes ([string[]]@($common.ReasonCodes)) -Facts $facts
    }

    if ($CaseId -in @('ProviderStrictOffControl','ProviderStrictOn')) {
        return Test-Phase00E1StrictAttemptFacts `
            -CaseId $CaseId -AttemptEvidence $AttemptEvidence -BaseFacts $facts
    }

    $failureReasons = [Collections.Generic.List[string]]::new()
    if ([string](Get-Phase00E1PropertyValue `
        -Object $caseFacts -Name 'ChildInitializationSource') -cne
        [string]$definition.Source) {
        $failureReasons.Add('E1_CHILD_SCHEMA_SOURCE_MISMATCH')
    }
    $overrideObservable = Get-Phase00E1PropertyValue `
        -Object $caseFacts -Name 'SchemaOverrideObservable'
    $overrideObserved = Get-Phase00E1PropertyValue `
        -Object $caseFacts -Name 'SchemaOverrideObserved'
    $callerCase = $CaseId -in @('CallerOnly','CallerOverAgent')
    if (($callerCase -and $overrideObservable -eq $true -and $overrideObserved -ne $true) -or
        (-not $callerCase -and $overrideObserved -eq $true)) {
        $failureReasons.Add('E1_SCHEMA_OVERRIDE_MISMATCH')
    }
    $structuredOutput = Get-Phase00E1PropertyValue `
        -Object $results[0] -Name 'StructuredOutput'
    $data = Get-Phase00E1PropertyValue -Object $structuredOutput -Name 'data'
    $expectedProperty = [string]$definition.ExpectedSentinelProperty
    $expectedValue = [string]$definition.ExpectedSentinel
    if ([string](Get-Phase00E1PropertyValue `
        -Object $data -Name $expectedProperty) -cne $expectedValue) {
        $failureReasons.Add('E1_SENTINEL_MISMATCH')
    }
    $forbiddenProperty = [string]$definition.ForbiddenProperty
    if (-not [string]::IsNullOrWhiteSpace($forbiddenProperty) -and
        (Test-Phase00E1HasProperty -Object $data -Name $forbiddenProperty)) {
        $failureReasons.Add('E1_FORBIDDEN_SENTINEL_PRESENT')
    }
    if (-not (Test-Phase00E1ExactData -Data $data `
        -Property $expectedProperty -Value $expectedValue)) {
        $failureReasons.Add('E1_STRUCTURED_DATA_SHAPE_MISMATCH')
    }
    $uniqueFailures = [string[]]@($failureReasons | Select-Object -Unique)
    if ($uniqueFailures.Count -gt 0) {
        return New-Phase00E1Analysis -Status FAIL `
            -ReasonCodes $uniqueFailures -Facts $facts
    }
    $passReasons = [ordered]@{
        AgentJtd = 'E1_AGENT_JTD_PASS'
        AgentJsonSchema = 'E1_AGENT_JSON_SCHEMA_PASS'
        CallerOnly = 'E1_CALLER_ONLY_PASS'
        CallerOverAgent = 'E1_CALLER_OVER_AGENT_PASS'
        SessionOnly = 'E1_SESSION_ONLY_PASS'
    }
    return New-Phase00E1Analysis -Status PASS `
        -ReasonCodes @([string]$passReasons[$CaseId]) -Facts $facts
}

function Test-Phase00E1ProviderStrictPair {
    param(
        [Parameter(Mandatory)]$StrictOffAttempt,
        [Parameter(Mandatory)]$StrictOnAttempt
    )

    $offIdentity = Get-Phase00E1PropertyValue `
        -Object $StrictOffAttempt -Name 'Identity'
    $onIdentity = Get-Phase00E1PropertyValue `
        -Object $StrictOnAttempt -Name 'Identity'
    $identityProperties = @(Get-Phase00E1StrictCrossArmIdentityPropertyNames)
    $identityMismatch = $false
    foreach ($property in $identityProperties) {
        if (-not (Test-Phase00E1HasProperty -Object $offIdentity -Name $property) -or
            -not (Test-Phase00E1HasProperty -Object $onIdentity -Name $property) -or
            [string](Get-Phase00E1PropertyValue `
            -Object $offIdentity -Name $property) -cne
            [string](Get-Phase00E1PropertyValue `
            -Object $onIdentity -Name $property)) {
            $identityMismatch = $true
        }
    }
    $facts = [ordered]@{
        StrictOffAttempt = $StrictOffAttempt
        StrictOnAttempt = $StrictOnAttempt
        StrictOffAnalysis = $null
        StrictOnAnalysis = $null
    }
    if ($identityMismatch) {
        return New-Phase00E1Analysis -Status INVALID_RUN `
            -ReasonCodes @('E1_STRICT_PAIR_IDENTITY_MISMATCH') -Facts $facts
    }
    $offAnalysis = Test-Phase00E1Attempt `
        -CaseId ProviderStrictOffControl -AttemptEvidence $StrictOffAttempt
    $onAnalysis = Test-Phase00E1Attempt `
        -CaseId ProviderStrictOn -AttemptEvidence $StrictOnAttempt
    $facts['StrictOffAnalysis'] = $offAnalysis
    $facts['StrictOnAnalysis'] = $onAnalysis
    $statuses = @([string]$offAnalysis.Status,[string]$onAnalysis.Status)
    if ($statuses -contains 'INVALID_RUN') {
        return New-Phase00E1Analysis -Status INVALID_RUN `
            -ReasonCodes @('E1_STRICT_PAIR_ARM_INVALID') -Facts $facts
    }
    if ($statuses -contains 'BLOCKED_ENVIRONMENT') {
        return New-Phase00E1Analysis -Status BLOCKED_ENVIRONMENT `
            -ReasonCodes @('E1_STRICT_PAIR_CAPABILITY_UNAVAILABLE') -Facts $facts
    }
    if ($statuses -contains 'FAIL') {
        return New-Phase00E1Analysis -Status FAIL `
            -ReasonCodes @('E1_STRICT_PAIR_CONTRADICTION') -Facts $facts
    }
    if (@($statuses | Where-Object { $_ -cne 'PASS' }).Count -gt 0) {
        return New-Phase00E1Analysis -Status INVALID_RUN `
            -ReasonCodes @('E1_STRICT_PAIR_NONTERMINAL') -Facts $facts
    }
    return New-Phase00E1Analysis -Status PASS `
        -ReasonCodes @('E1_PROVIDER_STRICT_PAIR_PASS') -Facts $facts
}

function Get-Phase00E1StrictCrossArmIdentityPropertyNames {
    return [string[]]@(
        'PromptSha256','AssignmentSha256','OutputSchemaSha256','AgentSha256',
        'Agent','Model','RuntimeSha256','RuntimeVersion','Gateway'
    )
}

function Get-Phase00E1ExperimentOutcome {
    param([Parameter(Mandatory)][object[]]$CaseRecords)

    $records = @($CaseRecords)
    if ($records.Count -ne 6) {
        return New-Phase00E1Analysis -Status INVALID_RUN `
            -ReasonCodes @('E1_MATRIX_INCOMPLETE') `
            -Facts ([ordered]@{ Count=$records.Count; CaseRecords=$records })
    }
    $expectedCaseIds = @(
        'AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent',
        'SessionOnly','ProviderStrictPair'
    ) | Sort-Object
    $observedCaseIds = @($records | ForEach-Object {
        [string](Get-Phase00E1PropertyValue -Object $_ -Name 'CaseId')
    } | Sort-Object)
    if (($observedCaseIds -join "`n") -cne ($expectedCaseIds -join "`n")) {
        return New-Phase00E1Analysis -Status INVALID_RUN `
            -ReasonCodes @('E1_MATRIX_CASE_SET_INVALID') -Facts $records
    }
    if (@($records | Where-Object {
        [string](Get-Phase00E1PropertyValue -Object $_ -Name 'Status') -ceq 'FAIL'
    }).Count -gt 0) {
        return New-Phase00E1Analysis -Status FAIL `
            -ReasonCodes @('E1_COMPLETE_CASE_CONTRADICTION') -Facts $records
    }
    if (@($records | Where-Object {
        [string](Get-Phase00E1PropertyValue `
        -Object $_ -Name 'Status') -ceq 'BLOCKED_ENVIRONMENT'
    }).Count -gt 0) {
        return New-Phase00E1Analysis -Status BLOCKED_ENVIRONMENT `
            -ReasonCodes @('E1_REQUIRED_CAPABILITY_UNAVAILABLE') -Facts $records
    }
    if (@($records | Where-Object {
        [string](Get-Phase00E1PropertyValue -Object $_ -Name 'Status') -cne 'PASS'
    }).Count -gt 0) {
        return New-Phase00E1Analysis -Status INVALID_RUN `
            -ReasonCodes @('E1_MATRIX_NONTERMINAL') -Facts $records
    }
    return New-Phase00E1Analysis -Status PASS `
        -ReasonCodes @('E1_ALL_SIX_CASES_PASS') -Facts $records
}

function Assert-Phase00E1AnalysisMatchesEvidence {
    param(
        [Parameter(Mandatory)]$Supplied,
        [Parameter(Mandatory)]$Derived,
        [Parameter(Mandatory)][string]$Name
    )

    $suppliedStatus = [string](Get-Phase00E1PropertyValue `
        -Object $Supplied -Name 'Status')
    $derivedStatus = [string](Get-Phase00E1PropertyValue `
        -Object $Derived -Name 'Status')
    $suppliedReasons = @(
        Get-Phase00E1PropertyValue -Object $Supplied -Name 'ReasonCodes'
    )
    $derivedReasons = @(
        Get-Phase00E1PropertyValue -Object $Derived -Name 'ReasonCodes'
    )
    if ($suppliedStatus -cne $derivedStatus -or
        ($suppliedReasons -join "`n") -cne ($derivedReasons -join "`n")) {
        throw "E1_ANALYSIS_MISMATCH: $Name"
    }
}

function Get-Phase00E1SafeResultSummary {
    param(
        [Parameter(Mandatory)]$Result,
        [Parameter(Mandatory)]$Definition
    )

    $structured = Get-Phase00E1PropertyValue `
        -Object $Result -Name 'StructuredOutput'
    $data = Get-Phase00E1PropertyValue -Object $structured -Name 'data'
    $expectedProperty = [string](Get-Phase00E1PropertyValue `
        -Object $Definition -Name 'ExpectedSentinelProperty')
    $expectedSentinel = [string](Get-Phase00E1PropertyValue `
        -Object $Definition -Name 'ExpectedSentinel')
    $forbiddenProperty = [string](Get-Phase00E1PropertyValue `
        -Object $Definition -Name 'ForbiddenProperty')
    return [ordered]@{
        agent = [string](Get-Phase00E1PropertyValue -Object $Result -Name 'Agent')
        is_async_acknowledgement = (Get-Phase00E1PropertyValue `
            -Object $Result -Name 'IsAsyncAcknowledgement') -eq $true
        source = [string](Get-Phase00E1PropertyValue `
            -Object $structured -Name 'source')
        mode = [string](Get-Phase00E1PropertyValue `
            -Object $structured -Name 'mode')
        structured_status = [string](Get-Phase00E1PropertyValue `
            -Object $structured -Name 'status')
        data_property_names = [string[]]@(
            Get-Phase00E1ObjectPropertyNames -Object $data | Sort-Object
        )
        expected_sentinel_matches = [string](Get-Phase00E1PropertyValue `
            -Object $data -Name $expectedProperty) -ceq $expectedSentinel
        forbidden_property_present = -not [string]::IsNullOrWhiteSpace($forbiddenProperty) -and
            (Test-Phase00E1HasProperty -Object $data -Name $forbiddenProperty)
    }
}

function Get-Phase00E1SafeProviderLedgerSummary {
    param([Parameter(Mandatory)]$Ledger)

    $terminal = Get-Phase00E1PropertyValue `
        -Object $Ledger -Name 'TerminalFailure'
    return [ordered]@{
        requests = [int](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'RequestCount')
        attributed_requests = [int](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'AttributedRequestCount')
        unattributed_requests = [int](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'UnattributedRequestCount')
        response_ends = [int](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'ResponseEndCount')
        recovered_retries = [int](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'RecoveredRetryCount')
        retry_exhausted = (Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'RetryExhausted') -eq $true
        provider = [string](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'Provider')
        model = [string](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'Model')
        terminal_failure_found = (Get-Phase00E1PropertyValue `
            -Object $terminal -Name 'Found') -eq $true
        terminal_failure_code = [string](Get-Phase00E1PropertyValue `
            -Object $terminal -Name 'Code')
    }
}

function Get-Phase00E1SafeProcessLedgerSummary {
    param([Parameter(Mandatory)]$Ledger)

    return [ordered]@{
        requests = [int](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'RequestCount')
        attributed_requests = [int](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'AttributedRequestCount')
        unattributed_requests = [int](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'UnattributedRequestCount')
        response_ends = [int](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'ResponseEndCount')
        recovered_retries = [int](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'RecoveredRetryCount')
        retry_exhausted_count = [int](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'RetryExhaustedCount')
        terminal_failure_count = [int](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'TerminalFailureCount')
        provider = [string](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'Provider')
        model = [string](Get-Phase00E1PropertyValue `
            -Object $Ledger -Name 'Model')
    }
}

function Get-Phase00E1DerivedRawArtifacts {
    param([Parameter(Mandatory)]$AttemptEvidence)

    $runRecord = Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'RunRecord'
    return @(@(Get-Phase00E1PropertyValue `
        -Object $runRecord -Name 'RawArtifacts') | ForEach-Object {
        [ordered]@{
            kind = [string](Get-Phase00E1PropertyValue -Object $_ -Name 'Kind')
            path = [string](Get-Phase00E1PropertyValue -Object $_ -Name 'Path')
            sha256 = [string](Get-Phase00E1PropertyValue -Object $_ -Name 'Sha256')
            lines = [int](Get-Phase00E1PropertyValue -Object $_ -Name 'Lines')
            source_capture_sha256 = Get-Phase00E1PropertyValue `
                -Object $_ -Name 'SourceCaptureSha256'
        }
    })
}

function New-Phase00E1CaseRecord {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly')]
        [string]$CaseId,
        [Parameter(Mandatory)]$AttemptEvidence,
        [Parameter(Mandatory)]$Analysis
    )

    if ([string](Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'CaseId') -cne $CaseId) {
        throw 'E1_CASE_RECORD_CASE_ID_MISMATCH'
    }
    $derivedAnalysis = Test-Phase00E1Attempt `
        -CaseId $CaseId -AttemptEvidence $AttemptEvidence
    Assert-Phase00E1AnalysisMatchesEvidence -Supplied $Analysis `
        -Derived $derivedAnalysis -Name $CaseId
    $definition = Get-Phase00E1CaseDefinition -CaseId $CaseId
    $results = @(Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'AttributableResults')
    $selectedResult = if ($results.Count -eq 1) {
        Get-Phase00E1SafeResultSummary `
            -Result $results[0] -Definition $definition
    } else { $null }
    $runRecord = Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'RunRecord'
    $verifiedRun = Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'VerifiedRun'
    $envelope = Get-Phase00E1PropertyValue `
        -Object $verifiedRun -Name 'Envelope'
    $command = Get-Phase00E1PropertyValue -Object $envelope -Name 'command'
    $caseFacts = Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'CaseFacts'
    return [ordered]@{
        schema_version = 1
        experiment = 'E1'
        case_id = $CaseId
        matrix_artifact = [string]$definition.MatrixArtifact
        status = [string]$derivedAnalysis.Status
        attempt = [int](Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'Attempt')
        runtime = [ordered]@{
            pinned_source_commit = [string](Get-Phase00E1PropertyValue `
                -Object $runRecord -Name 'PinnedSourceCommit')
            omp_sha256 = [string](Get-Phase00E1PropertyValue `
                -Object $runRecord -Name 'RuntimeSha256')
            omp_version = [string](Get-Phase00E1PropertyValue `
                -Object $runRecord -Name 'RuntimeVersion')
            model = [string](Get-Phase00E1PropertyValue -Object $command -Name 'model')
        }
        inputs = [ordered]@{
            prompt_sha256 = [string](Get-Phase00E1PropertyValue `
                -Object $command -Name 'prompt_sha256')
            agent = if ($CaseId -eq 'SessionOnly') {
                'phase00-e1-session-leaf'
            } else { [string]$definition.Agent }
            caller_schema_state = [string](Get-Phase00E1PropertyValue `
                -Object $caseFacts -Name 'CallerSchemaState')
            agent_schema_state = [string](Get-Phase00E1PropertyValue `
                -Object $caseFacts -Name 'AgentSchemaState')
            agent_schema_dialect = [string](Get-Phase00E1PropertyValue `
                -Object $caseFacts -Name 'AgentSchemaDialect')
            session_schema_state = [string](Get-Phase00E1PropertyValue `
                -Object $caseFacts -Name 'SessionSchemaState')
        }
        observations = [ordered]@{
            selected_result = $selectedResult
            attributable_result_count = $results.Count
            selected_result_role = [string](Get-Phase00E1PropertyValue `
                -Object $caseFacts -Name 'SelectedResultRole')
            child_initialization_source = [string](Get-Phase00E1PropertyValue `
                -Object $caseFacts -Name 'ChildInitializationSource')
            schema_override_observable = (Get-Phase00E1PropertyValue `
                -Object $caseFacts -Name 'SchemaOverrideObservable') -eq $true
            schema_override_observed = (Get-Phase00E1PropertyValue `
                -Object $caseFacts -Name 'SchemaOverrideObserved') -eq $true
            blocking_executions = @(Get-Phase00E1PropertyValue `
                -Object $AttemptEvidence -Name 'BlockingExecutions')
        }
        provider_ledger = [ordered]@{
            selected_session = Get-Phase00E1SafeProviderLedgerSummary `
                -Ledger (Get-Phase00E1PropertyValue `
                    -Object $AttemptEvidence -Name 'ProviderLedger')
            process = Get-Phase00E1SafeProcessLedgerSummary `
                -Ledger (Get-Phase00E1PropertyValue `
                    -Object $AttemptEvidence -Name 'ProcessProviderLedger')
            controller_stdout_duplicates_excluded = $true
        }
        raw_artifacts = @(Get-Phase00E1DerivedRawArtifacts `
            -AttemptEvidence $AttemptEvidence)
        protected_surface = [ordered]@{
            unchanged = (Get-Phase00E1PropertyValue `
                -Object $runRecord -Name 'ProtectedSurfacesUnchanged') -eq $true
            cleanup_succeeded = (Get-Phase00E1PropertyValue `
                -Object $runRecord -Name 'CleanupSucceeded') -eq $true
            remaining_child_pid_count = @(Get-Phase00E1PropertyValue `
                -Object $runRecord -Name 'RemainingChildPids').Count
        }
        reason_codes = [string[]]@($derivedAnalysis.ReasonCodes)
        limitations = @(
            'Provider counts are attributed from persisted sessions; duplicated controller stdout events are excluded.',
            'Sanitized raw artifacts omit private prompts, reasoning, credentials, and complete provider bodies.'
        )
    }
}

function Get-Phase00E1StrictArmObservation {
    param(
        [Parameter(Mandatory)]$AttemptEvidence,
        [Parameter(Mandatory)]$Analysis
    )

    $caseId = [string](Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'CaseId')
    $definition = Get-Phase00E1CaseDefinition -CaseId $caseId
    $results = @(Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'AttributableResults')
    $yieldSummaries = @(@(Get-Phase00E1PropertyValue `
        -Object $AttemptEvidence -Name 'YieldAttempts') | ForEach-Object {
        $data = Get-Phase00E1PropertyValue -Object $_ -Name 'Data'
        [ordered]@{
            index = [int](Get-Phase00E1PropertyValue -Object $_ -Name 'Index')
            provider_returned = (Get-Phase00E1PropertyValue `
                -Object $_ -Name 'ProviderReturned') -eq $true
            terminal = (Get-Phase00E1PropertyValue `
                -Object $_ -Name 'Terminal') -eq $true
            data_property_names = [string[]]@(
                Get-Phase00E1ObjectPropertyNames -Object $data | Sort-Object
            )
            forbidden_data_observed = Test-Phase00E1ForbiddenStrictData -Data $data
            allowed_sentinel_matches = [string](Get-Phase00E1PropertyValue `
                -Object $data -Name 'allowed') -ceq 'E1_STRICT_ALLOWED'
            local_validation_rejected = (Get-Phase00E1PropertyValue `
                -Object $_ -Name 'LocalValidationRejected') -eq $true
            local_validation_reason = [string](Get-Phase00E1PropertyValue `
                -Object $_ -Name 'LocalValidationReason')
        }
    })
    return [ordered]@{
        status = [string](Get-Phase00E1PropertyValue -Object $Analysis -Name 'Status')
        reason_codes = [string[]]@(Get-Phase00E1PropertyValue `
            -Object $Analysis -Name 'ReasonCodes')
        pi_no_strict_state = [string](Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'PiNoStrictState')
        selected_result = if ($results.Count -eq 1) {
            Get-Phase00E1SafeResultSummary `
                -Result $results[0] -Definition $definition
        } else { $null }
        forwarder_request_indexes = [int[]]@(
            @(Get-Phase00E1PropertyValue `
                -Object $AttemptEvidence -Name 'ForwarderProjections') | ForEach-Object {
                [int](Get-Phase00E1PropertyValue -Object $_ -Name 'request_index')
            }
        )
        forwarder_all_projection_count = [int](Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'ForwarderAllProjectionCount')
        yield_attempts = $yieldSummaries
        local_schema_rejection_count = [int](Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'LocalSchemaRejectionCount')
        local_schema_retry_count = [int](Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'LocalSchemaRetryCount')
        schema_override_count = [int](Get-Phase00E1PropertyValue `
            -Object $AttemptEvidence -Name 'SchemaOverrideCount')
    }
}

function New-Phase00E1ProviderStrictCaseRecord {
    param(
        [Parameter(Mandatory)]$StrictOffAttemptEvidence,
        [Parameter(Mandatory)]$StrictOffAnalysis,
        [Parameter(Mandatory)]$StrictOnAttemptEvidence,
        [Parameter(Mandatory)]$StrictOnAnalysis,
        [Parameter(Mandatory)]$PairAnalysis
    )

    if ([string](Get-Phase00E1PropertyValue `
            -Object $StrictOffAttemptEvidence -Name 'CaseId') -cne
            'ProviderStrictOffControl' -or
        [string](Get-Phase00E1PropertyValue `
            -Object $StrictOnAttemptEvidence -Name 'CaseId') -cne
            'ProviderStrictOn') {
        throw 'E1_STRICT_RECORD_ARM_IDENTITY_MISMATCH'
    }
    $derivedOff = Test-Phase00E1Attempt -CaseId ProviderStrictOffControl `
        -AttemptEvidence $StrictOffAttemptEvidence
    $derivedOn = Test-Phase00E1Attempt -CaseId ProviderStrictOn `
        -AttemptEvidence $StrictOnAttemptEvidence
    $derivedPair = Test-Phase00E1ProviderStrictPair `
        -StrictOffAttempt $StrictOffAttemptEvidence `
        -StrictOnAttempt $StrictOnAttemptEvidence
    Assert-Phase00E1AnalysisMatchesEvidence -Supplied $StrictOffAnalysis `
        -Derived $derivedOff -Name 'ProviderStrictOffControl'
    Assert-Phase00E1AnalysisMatchesEvidence -Supplied $StrictOnAnalysis `
        -Derived $derivedOn -Name 'ProviderStrictOn'
    Assert-Phase00E1AnalysisMatchesEvidence -Supplied $PairAnalysis `
        -Derived $derivedPair -Name 'ProviderStrictPair'
    $offIdentity = Get-Phase00E1PropertyValue `
        -Object $StrictOffAttemptEvidence -Name 'Identity'
    $onIdentity = Get-Phase00E1PropertyValue `
        -Object $StrictOnAttemptEvidence -Name 'Identity'
    $identityEqual = $true
    foreach ($property in @(Get-Phase00E1StrictCrossArmIdentityPropertyNames)) {
        if (-not (Test-Phase00E1HasProperty -Object $offIdentity -Name $property) -or
            -not (Test-Phase00E1HasProperty -Object $onIdentity -Name $property) -or
            [string](Get-Phase00E1PropertyValue `
                -Object $offIdentity -Name $property) -cne
            [string](Get-Phase00E1PropertyValue `
                -Object $onIdentity -Name $property)) {
            $identityEqual = $false
        }
    }
    $offRun = Get-Phase00E1PropertyValue `
        -Object $StrictOffAttemptEvidence -Name 'RunRecord'
    $offSelectedLedger = Get-Phase00E1SafeProviderLedgerSummary `
        -Ledger (Get-Phase00E1PropertyValue `
            -Object $StrictOffAttemptEvidence -Name 'ProviderLedger')
    $onSelectedLedger = Get-Phase00E1SafeProviderLedgerSummary `
        -Ledger (Get-Phase00E1PropertyValue `
            -Object $StrictOnAttemptEvidence -Name 'ProviderLedger')
    $offProcessLedger = Get-Phase00E1SafeProcessLedgerSummary `
        -Ledger (Get-Phase00E1PropertyValue `
            -Object $StrictOffAttemptEvidence -Name 'ProcessProviderLedger')
    $onProcessLedger = Get-Phase00E1SafeProcessLedgerSummary `
        -Ledger (Get-Phase00E1PropertyValue `
            -Object $StrictOnAttemptEvidence -Name 'ProcessProviderLedger')
    return [ordered]@{
        schema_version = 1
        experiment = 'E1'
        case_id = 'ProviderStrictPair'
        matrix_artifact = 'case-5-provider-strict'
        status = [string]$derivedPair.Status
        attempt = [int](Get-Phase00E1PropertyValue `
            -Object $StrictOffAttemptEvidence -Name 'Attempt')
        runtime = [ordered]@{
            pinned_source_commit = [string](Get-Phase00E1PropertyValue `
                -Object $offRun -Name 'PinnedSourceCommit')
            omp_sha256 = [string](Get-Phase00E1PropertyValue `
                -Object $offRun -Name 'RuntimeSha256')
            omp_version = [string](Get-Phase00E1PropertyValue `
                -Object $offRun -Name 'RuntimeVersion')
            model = [string](Get-Phase00E1PropertyValue `
                -Object $offIdentity -Name 'Model')
        }
        inputs = [ordered]@{
            strict_off_identity = $offIdentity
            strict_on_identity = $onIdentity
            only_intended_wire_variable = 'PI_NO_STRICT'
        }
        observations = [ordered]@{
            strict_off_control = Get-Phase00E1StrictArmObservation `
                -AttemptEvidence $StrictOffAttemptEvidence -Analysis $derivedOff
            strict_on = Get-Phase00E1StrictArmObservation `
                -AttemptEvidence $StrictOnAttemptEvidence -Analysis $derivedOn
            cross_arm_identity_equal = $identityEqual
        }
        provider_ledger = [ordered]@{
            process_attempts = 2
            strict_off_selected_session = $offSelectedLedger
            strict_off_process = $offProcessLedger
            strict_on_selected_session = $onSelectedLedger
            strict_on_process = $onProcessLedger
            total_process_requests = [int]$offProcessLedger.requests +
                [int]$onProcessLedger.requests
            controller_stdout_duplicates_excluded = $true
        }
        raw_artifacts = @(
            @(Get-Phase00E1DerivedRawArtifacts `
                -AttemptEvidence $StrictOffAttemptEvidence) +
            @(Get-Phase00E1DerivedRawArtifacts `
                -AttemptEvidence $StrictOnAttemptEvidence)
        )
        protected_surface = [ordered]@{
            strict_off_unchanged = (Get-Phase00E1PropertyValue `
                -Object $offRun -Name 'ProtectedSurfacesUnchanged') -eq $true
            strict_on_unchanged = (Get-Phase00E1PropertyValue `
                -Object (Get-Phase00E1PropertyValue `
                    -Object $StrictOnAttemptEvidence -Name 'RunRecord') `
                -Name 'ProtectedSurfacesUnchanged') -eq $true
        }
        reason_codes = [string[]]@($derivedPair.ReasonCodes)
        limitations = @(
            'The strict pair isolates PI_NO_STRICT while preserving assignment, schema, agent, model, runtime, and gateway identity.',
            'Sanitized projections retain only yield-schema facts and omit complete provider request and response bodies.'
        )
    }
}

function Get-Phase00E1YamlValueKind {
    param([AllowNull()]$Value)

    if ($null -eq $Value) { return 'scalar' }
    if ($Value -is [Collections.IDictionary] -or $Value -is [pscustomobject]) {
        return 'mapping'
    }
    if ($Value -is [string] -or $Value -is [char] -or
        $Value -is [bool] -or $Value -is [ValueType]) {
        return 'scalar'
    }
    if ($Value -is [Collections.IEnumerable]) { return 'sequence' }
    throw "Unsupported E1 YAML value type: $($Value.GetType().FullName)"
}

function Get-Phase00E1YamlMappingEntries {
    param([Parameter(Mandatory)]$Value)

    if ($Value -is [Collections.IDictionary]) {
        $keys = @($Value.Keys)
        if (-not ($Value -is [Collections.Specialized.OrderedDictionary])) {
            $keys = @($keys | Sort-Object)
        }
        return @($keys | ForEach-Object {
            [pscustomobject][ordered]@{ Name=[string]$_; Value=$Value[$_] }
        })
    }
    if ($Value -is [pscustomobject]) {
        return @($Value.PSObject.Properties | ForEach-Object {
            [pscustomobject][ordered]@{ Name=[string]$_.Name; Value=$_.Value }
        })
    }
    throw 'E1 YAML mapping value must be a dictionary or PSCustomObject.'
}

function ConvertTo-Phase00E1YamlKey {
    param([Parameter(Mandatory)][string]$Value)

    if ($Value -match '^[A-Za-z_][A-Za-z0-9_-]*$') { return $Value }
    return ($Value | ConvertTo-Json -Compress)
}

function ConvertTo-Phase00E1YamlScalar {
    param([AllowNull()]$Value)

    if ($null -eq $Value) { return 'null' }
    if ($Value -is [bool]) {
        if ($Value) { return 'true' }
        return 'false'
    }
    if ($Value -is [byte] -or $Value -is [sbyte] -or
        $Value -is [int16] -or $Value -is [uint16] -or
        $Value -is [int32] -or $Value -is [uint32] -or
        $Value -is [int64] -or $Value -is [uint64] -or
        $Value -is [decimal]) {
        return ([IFormattable]$Value).ToString($null,[Globalization.CultureInfo]::InvariantCulture)
    }
    if ($Value -is [single] -or $Value -is [double]) {
        $number = [double]$Value
        if ([double]::IsNaN($number) -or [double]::IsInfinity($number)) {
            throw 'Non-finite numbers are not valid E1 YAML scalars.'
        }
        return ([IFormattable]$Value).ToString('R',[Globalization.CultureInfo]::InvariantCulture)
    }
    if ($Value -is [DateTime]) {
        return ($Value.ToString('o',[Globalization.CultureInfo]::InvariantCulture) |
            ConvertTo-Json -Compress)
    }
    if ($Value -is [DateTimeOffset]) {
        return ($Value.ToString('o',[Globalization.CultureInfo]::InvariantCulture) |
            ConvertTo-Json -Compress)
    }
    if ($Value -is [string] -or $Value -is [char] -or $Value -is [Guid] -or
        $Value.GetType().IsEnum) {
        return ([string]$Value | ConvertTo-Json -Compress)
    }
    throw "Unsupported E1 YAML scalar type: $($Value.GetType().FullName)"
}

function ConvertTo-Phase00E1YamlLines {
    param(
        [Parameter(Mandatory)]$Value,
        [ValidateRange(0,100)][int]$Indent = 0
    )

    $kind = Get-Phase00E1YamlValueKind $Value
    if ($kind -ne 'mapping') {
        throw 'The root E1 YAML value must be a mapping.'
    }
    $lines = [Collections.Generic.List[string]]::new()
    $spaces = ' ' * $Indent
    foreach ($entry in @(Get-Phase00E1YamlMappingEntries $Value)) {
        $key = ConvertTo-Phase00E1YamlKey $entry.Name
        $entryKind = Get-Phase00E1YamlValueKind $entry.Value
        if ($entryKind -eq 'scalar') {
            $lines.Add(('{0}{1}: {2}' -f $spaces,$key,
                (ConvertTo-Phase00E1YamlScalar $entry.Value)))
            continue
        }
        if ($entryKind -eq 'mapping') {
            $nestedEntries = @(Get-Phase00E1YamlMappingEntries $entry.Value)
            if ($nestedEntries.Count -eq 0) {
                $lines.Add(('{0}{1}: {{}}' -f $spaces,$key))
            } else {
                $lines.Add(('{0}{1}:' -f $spaces,$key))
                foreach ($line in @(ConvertTo-Phase00E1YamlLines `
                    -Value $entry.Value -Indent ($Indent + 2))) {
                    $lines.Add($line)
                }
            }
            continue
        }

        $items = @($entry.Value)
        if ($items.Count -eq 0) {
            $lines.Add(('{0}{1}: []' -f $spaces,$key))
            continue
        }
        $lines.Add(('{0}{1}:' -f $spaces,$key))
        $itemSpaces = ' ' * ($Indent + 2)
        foreach ($item in $items) {
            $itemKind = Get-Phase00E1YamlValueKind $item
            if ($itemKind -eq 'scalar') {
                $lines.Add(('{0}- {1}' -f $itemSpaces,
                    (ConvertTo-Phase00E1YamlScalar $item)))
                continue
            }
            if ($itemKind -eq 'mapping') {
                $nestedEntries = @(Get-Phase00E1YamlMappingEntries $item)
                if ($nestedEntries.Count -eq 0) {
                    $lines.Add(('{0}- {{}}' -f $itemSpaces))
                } else {
                    $lines.Add(('{0}-' -f $itemSpaces))
                    foreach ($line in @(ConvertTo-Phase00E1YamlLines `
                        -Value $item -Indent ($Indent + 4))) {
                        $lines.Add($line)
                    }
                }
                continue
            }
            throw 'Nested sequences are not supported in E1 derived YAML artifacts.'
        }
    }
    return [string[]]@($lines)
}

function Assert-Phase00E1ExactObjectFields {
    param(
        [Parameter(Mandatory)]$Value,
        [Parameter(Mandatory)][string[]]$Expected,
        [Parameter(Mandatory)][string]$ArtifactName
    )

    $actual = if ($Value -is [Collections.IDictionary]) {
        @($Value.Keys | ForEach-Object { [string]$_ })
    } elseif ($Value -is [pscustomobject]) {
        @($Value.PSObject.Properties.Name)
    } else {
        throw "$ArtifactName must be a mapping object."
    }
    $missing = @($Expected | Where-Object { $_ -cnotin $actual })
    $unknown = @($actual | Where-Object { $_ -cnotin $Expected })
    if ($actual.Count -ne $Expected.Count -or $missing.Count -gt 0 -or
        $unknown.Count -gt 0) {
        throw "$ArtifactName requires exact top-level fields; missing=$($missing -join ','); unknown=$($unknown -join ',')."
    }
}

function Assert-Phase00E1MappingField {
    param(
        [AllowNull()]$Value,
        [Parameter(Mandatory)][string]$Name
    )

    if (-not ($Value -is [Collections.IDictionary] -or $Value -is [pscustomobject])) {
        throw "E1 field '$Name' must be a mapping."
    }
}

function Get-Phase00E1SequenceField {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string]$Name,
        [switch]$RequireNonEmpty
    )

    $Value = $null
    if ($Object -is [Collections.IDictionary]) {
        if ($Object.Contains($Name)) { $Value = $Object[$Name] }
    } else {
        $property = $Object.PSObject.Properties[$Name]
        if ($null -ne $property) { $Value = $property.Value }
    }
    if ($null -eq $Value -or $Value -is [string] -or
        $Value -is [Collections.IDictionary] -or $Value -is [pscustomobject] -or
        -not ($Value -is [Collections.IEnumerable])) {
        throw "E1 field '$Name' must be a sequence."
    }
    $items = @($Value)
    if ($RequireNonEmpty -and $items.Count -eq 0) {
        throw "E1 field '$Name' must not be empty."
    }
    return ,$items
}

function Write-Phase00E1CanonicalYamlArtifact {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Value
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    if (Test-Path -LiteralPath $fullPath) {
        throw "E1 artifact destination already exists: $fullPath"
    }
    $parent = Split-Path -Parent $fullPath
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        throw "E1 artifact parent directory does not exist: $parent"
    }
    $lines = [string[]]@(ConvertTo-Phase00E1YamlLines -Value $Value)
    $text = ($lines -join "`n") + "`n"
    if ($text -match '(?i)E1_(?:SECRET|PRIVATE)_' -or
        $text -match '(?i)Authorization\s*:\s*"?Bearer\s+\S{8,}' -or
        $text -match '(?i)(?:OPENAI|ANTHROPIC|GEMINI|OMNIROUTE)_API_KEY\s*[:=]\s*\S{8,}') {
        throw 'Refusing to write a derived E1 artifact containing secret-shaped text.'
    }

    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($text)
    $stream = $null
    $created = $false
    try {
        $stream = [IO.File]::Open(
            $fullPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        $created = $true
        $stream.Write($bytes,0,$bytes.Length)
        $stream.Flush($true)
    } catch {
        if ($null -ne $stream) { $stream.Dispose(); $stream = $null }
        if ($created -and (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            [IO.File]::Delete($fullPath)
        }
        throw
    } finally {
        if ($null -ne $stream) { $stream.Dispose() }
    }
    return [pscustomobject][ordered]@{
        Path = $fullPath
        Sha256 = Get-Phase00E1FileSha256 -Path $fullPath
        Bytes = $bytes.Length
        Lines = $lines.Count
    }
}

function Write-Phase00E1CaseRecord {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Record
    )

    $fields = @(
        'schema_version','experiment','case_id','matrix_artifact','status','attempt',
        'runtime','inputs','observations','provider_ledger','raw_artifacts',
        'protected_surface','reason_codes','limitations'
    )
    Assert-Phase00E1ExactObjectFields -Value $Record -Expected $fields `
        -ArtifactName 'E1 case record'
    $caseId = [string](Get-Phase00E1PropertyValue -Object $Record -Name 'case_id')
    $matrixArtifacts = [ordered]@{
        AgentJtd='case-1-agent-jtd'
        AgentJsonSchema='case-1-agent-json-schema'
        CallerOnly='case-2-caller-only'
        CallerOverAgent='case-3-caller-over-agent'
        SessionOnly='case-4-session-only'
        ProviderStrictPair='case-5-provider-strict'
    }
    if (-not $matrixArtifacts.Contains($caseId)) {
        throw "Unknown E1 matrix case record ID: $caseId"
    }
    $matrixArtifact = [string](Get-Phase00E1PropertyValue `
        -Object $Record -Name 'matrix_artifact')
    if ($matrixArtifact -cne [string]$matrixArtifacts[$caseId]) {
        throw "E1 matrix artifact does not match case '$caseId'."
    }
    if ([IO.Path]::GetFileName($Path) -cne "$matrixArtifact.yml") {
        throw "E1 case record filename must be '$matrixArtifact.yml'."
    }
    if ([string](Get-Phase00E1PropertyValue -Object $Record -Name 'schema_version') -cne '1' -or
        [string](Get-Phase00E1PropertyValue -Object $Record -Name 'experiment') -cne 'E1') {
        throw 'E1 case record root identity must be schema_version 1 and experiment E1.'
    }
    $status = [string](Get-Phase00E1PropertyValue -Object $Record -Name 'status')
    if ($status -notin @('PASS','FAIL','BLOCKED_ENVIRONMENT','INVALID_RUN')) {
        throw "Unsupported E1 case record status: $status"
    }
    $attempt = [int](Get-Phase00E1PropertyValue -Object $Record -Name 'attempt')
    if ($attempt -lt 1 -or $attempt -gt 999) {
        throw 'E1 case record attempt must be between 1 and 999.'
    }
    foreach ($field in @(
        'runtime','inputs','observations','provider_ledger','protected_surface'
    )) {
        Assert-Phase00E1MappingField `
            -Value (Get-Phase00E1PropertyValue -Object $Record -Name $field) `
            -Name $field
    }
    $rawArtifacts = Get-Phase00E1SequenceField `
        -Object $Record `
        -Name 'raw_artifacts' -RequireNonEmpty
    $reasonCodes = Get-Phase00E1SequenceField `
        -Object $Record `
        -Name 'reason_codes' -RequireNonEmpty
    $limitations = Get-Phase00E1SequenceField `
        -Object $Record `
        -Name 'limitations'
    $canonical = [ordered]@{
        schema_version = 1
        experiment = 'E1'
        case_id = $caseId
        matrix_artifact = $matrixArtifact
        status = $status
        attempt = $attempt
        runtime = Get-Phase00E1PropertyValue -Object $Record -Name 'runtime'
        inputs = Get-Phase00E1PropertyValue -Object $Record -Name 'inputs'
        observations = Get-Phase00E1PropertyValue -Object $Record -Name 'observations'
        provider_ledger = Get-Phase00E1PropertyValue -Object $Record -Name 'provider_ledger'
        raw_artifacts = @($rawArtifacts)
        protected_surface = Get-Phase00E1PropertyValue -Object $Record -Name 'protected_surface'
        reason_codes = @($reasonCodes)
        limitations = @($limitations)
    }
    return Write-Phase00E1CanonicalYamlArtifact -Path $Path -Value $canonical
}

function Write-Phase00E1Conclusion {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Outcome
    )

    $fields = @(
        'schema_version','experiment','status','case_records','runtime',
        'provider_boundary','open_question_a',
        'canonical_t_00_4_agent_output_dialect','precedence',
        'provider_enforcement','upstream_provider_claim','spec_effect',
        'downstream_files','t_00_4_effect','raw_artifacts','limitations',
        'joint_closure'
    )
    Assert-Phase00E1ExactObjectFields -Value $Outcome -Expected $fields `
        -ArtifactName 'E1 conclusion'
    if ([IO.Path]::GetFileName($Path) -cne 'conclusion.yml') {
        throw "E1 conclusion filename must be 'conclusion.yml'."
    }
    if ([string](Get-Phase00E1PropertyValue -Object $Outcome -Name 'schema_version') -cne '1' -or
        [string](Get-Phase00E1PropertyValue -Object $Outcome -Name 'experiment') -cne 'E1') {
        throw 'E1 conclusion root identity must be schema_version 1 and experiment E1.'
    }
    $status = [string](Get-Phase00E1PropertyValue -Object $Outcome -Name 'status')
    if ($status -notin @('PASS','FAIL','BLOCKED_ENVIRONMENT')) {
        throw "E1 conclusion cannot use nonterminal status '$status'."
    }
    if ((Get-Phase00E1PropertyValue -Object $Outcome -Name 'joint_closure') -ne $false) {
        throw 'E1 conclusion joint_closure must remain false pending Opus peer review.'
    }
    foreach ($field in @('runtime','precedence','provider_enforcement')) {
        Assert-Phase00E1MappingField `
            -Value (Get-Phase00E1PropertyValue -Object $Outcome -Name $field) `
            -Name $field
    }
    $caseRecords = Get-Phase00E1SequenceField `
        -Object $Outcome `
        -Name 'case_records' -RequireNonEmpty
    $downstreamFiles = Get-Phase00E1SequenceField `
        -Object $Outcome `
        -Name 'downstream_files'
    $rawArtifacts = Get-Phase00E1SequenceField `
        -Object $Outcome `
        -Name 'raw_artifacts' -RequireNonEmpty
    $limitations = Get-Phase00E1SequenceField `
        -Object $Outcome `
        -Name 'limitations'
    $canonical = [ordered]@{
        schema_version = 1
        experiment = 'E1'
        status = $status
        case_records = @($caseRecords)
        runtime = Get-Phase00E1PropertyValue -Object $Outcome -Name 'runtime'
        provider_boundary = Get-Phase00E1PropertyValue -Object $Outcome -Name 'provider_boundary'
        open_question_a = Get-Phase00E1PropertyValue -Object $Outcome -Name 'open_question_a'
        canonical_t_00_4_agent_output_dialect = Get-Phase00E1PropertyValue `
            -Object $Outcome -Name 'canonical_t_00_4_agent_output_dialect'
        precedence = Get-Phase00E1PropertyValue -Object $Outcome -Name 'precedence'
        provider_enforcement = Get-Phase00E1PropertyValue `
            -Object $Outcome -Name 'provider_enforcement'
        upstream_provider_claim = Get-Phase00E1PropertyValue `
            -Object $Outcome -Name 'upstream_provider_claim'
        spec_effect = Get-Phase00E1PropertyValue -Object $Outcome -Name 'spec_effect'
        downstream_files = @($downstreamFiles)
        t_00_4_effect = Get-Phase00E1PropertyValue -Object $Outcome -Name 't_00_4_effect'
        raw_artifacts = @($rawArtifacts)
        limitations = @($limitations)
        joint_closure = $false
    }
    return Write-Phase00E1CanonicalYamlArtifact -Path $Path -Value $canonical
}

function New-Phase00E1ArtifactValidationResult {
    param(
        [Parameter(Mandatory)][ValidateSet('PASS','FAIL')][string]$Status,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Message
    )

    return [pscustomobject][ordered]@{
        Status = $Status
        Code = $Code
        Message = $Message
    }
}

function ConvertFrom-Phase00E1ManifestScalarText {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)

    $trimmed = $Value.Trim()
    if ($trimmed.Length -ge 2) {
        $first = $trimmed[0]
        $last = $trimmed[$trimmed.Length - 1]
        if (($first -eq '"' -and $last -eq '"') -or
            ($first -eq "'" -and $last -eq "'")) {
            return $trimmed.Substring(1,$trimmed.Length - 2)
        }
    }
    return $trimmed
}

function Read-Phase00E1ManifestEntryProjection {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Phase 00 manifest not found: $Path"
    }
    $rows = [Collections.Generic.List[object]]::new()
    $currentId = $null
    $currentFields = $null
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        if ($line -match '^  - id:\s*(.+?)\s*$') {
            if ($null -ne $currentFields) {
                $rows.Add([pscustomobject][ordered]@{
                    Id = $currentId
                    Fields = $currentFields
                })
            }
            $currentId = ConvertFrom-Phase00E1ManifestScalarText $Matches[1]
            $currentFields = [ordered]@{}
            continue
        }
        if ($null -ne $currentFields -and
            $line -match '^    (kind|state|depends_on|artifacts|decision):\s*(.*?)\s*$') {
            $key = [string]$Matches[1]
            if ($currentFields.Contains($key)) {
                throw "Duplicate manifest field for $currentId`: $key"
            }
            $currentFields[$key] = [string]$Matches[2]
        }
    }
    if ($null -ne $currentFields) {
        $rows.Add([pscustomobject][ordered]@{
            Id = $currentId
            Fields = $currentFields
        })
    }
    return @($rows)
}

function Test-Phase00E1ManifestSequenceText {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Value,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Expected
    )

    $trimmed = $Value.Trim()
    if ($trimmed.Length -lt 2 -or $trimmed[0] -ne '[' -or
        $trimmed[$trimmed.Length - 1] -ne ']') {
        return $false
    }
    $inner = $trimmed.Substring(1,$trimmed.Length - 2).Trim()
    [string[]]$actual = @()
    if (-not [string]::IsNullOrWhiteSpace($inner)) {
        $actual = @($inner.Split(',') | ForEach-Object {
            ConvertFrom-Phase00E1ManifestScalarText $_
        })
    }
    if ($actual.Count -ne $Expected.Count) { return $false }
    for ($index = 0; $index -lt $Expected.Count; $index += 1) {
        if ([string]$actual[$index] -cne [string]$Expected[$index]) { return $false }
    }
    return $true
}

function Test-Phase00E1ArtifactContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $results = [Collections.Generic.List[object]]::new()
    $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\','/')

    $fixtureRoot = Join-Path $root 'docs\evidence\phase-00\E1\fixture'
    $fixtureCheck = Test-Phase00E1FixtureTree -FixtureRoot $fixtureRoot `
        -ExpectedHashes (Get-Phase00E1ExpectedFixtureHashes)
    if ($fixtureCheck.Matched) {
        $results.Add((New-Phase00E1ArtifactValidationResult PASS P00-E1-FIXTURE `
            'The E1 fixture contains exactly fourteen precommitted files at their expected hashes.'))
    } else {
        $results.Add((New-Phase00E1ArtifactValidationResult FAIL P00-E1-FIXTURE `
            ("E1 fixture drift: " + (@($fixtureCheck.Mismatches) -join ', '))))
    }

    $runtimeProblems = [Collections.Generic.List[string]]::new()
    $runtimePaths = @(
        'scripts/lib/phase00-evidence.ps1',
        'scripts/lib/phase00-e1-evidence.ps1',
        'scripts/lib/phase00-runtime-evidence.ps1',
        'scripts/lib/phase00-e1-forwarder.mjs',
        'scripts/run-phase00-e1.ps1'
    )
    foreach ($relativePath in $runtimePaths) {
        $path = Join-Path $root $relativePath.Replace('/',[IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $runtimeProblems.Add("MISSING:$relativePath")
        }
    }

    $runnerPath = Join-Path $root 'scripts\run-phase00-e1.ps1'
    if (Test-Path -LiteralPath $runnerPath -PathType Leaf) {
        $runnerText = [IO.File]::ReadAllText($runnerPath).Replace("`r`n","`n")
        foreach ($marker in @(
            '#Requires -Version 5.1',
            '[Parameter(Mandatory)][string]$OmpExecutable',
            "[string]`$Model = 'omniroute/codex/gpt-5.6-sol-high'",
            ". (Join-Path `$PSScriptRoot 'lib\phase00-e1-evidence.ps1')",
            'Invoke-Phase00E1EvidenceCase @PSBoundParameters'
        )) {
            if (-not $runnerText.Contains($marker)) {
                $runtimeProblems.Add("RUNNER_MARKER:$marker")
            }
        }
    }

    $mainHelperPath = Join-Path $root 'scripts\lib\phase00-evidence.ps1'
    if (Test-Path -LiteralPath $mainHelperPath -PathType Leaf) {
        $mainHelperText = [IO.File]::ReadAllText($mainHelperPath).Replace("`r`n","`n")
        foreach ($marker in @(
            "`$phase00E1HelperPath = Join-Path `$PSScriptRoot 'phase00-e1-evidence.ps1'",
            'if (Test-Path -LiteralPath $phase00E1HelperPath -PathType Leaf)',
            '. $phase00E1HelperPath'
        )) {
            if (-not $mainHelperText.Contains($marker)) {
                $runtimeProblems.Add("REGISTRATION_MARKER:$marker")
            }
        }
    }

    $forwarderPath = Join-Path $root 'scripts\lib\phase00-e1-forwarder.mjs'
    if (Test-Path -LiteralPath $forwarderPath -PathType Leaf) {
        $forwarderHash = (Get-FileHash -LiteralPath $forwarderPath -Algorithm SHA256).Hash
        if ($forwarderHash -cne
            'D9CDAEB5FF4235658D10AD8371410E7F480ADEBDCD85C0F0EA13BFFCD53FA483') {
            $runtimeProblems.Add("FORWARDER_HASH:$forwarderHash")
        }
    }

    if (-not (Test-Phase00E1OmpIdentity `
        -Sha256 '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6' `
        -Version 'omp/17.2.10') -or
        (Test-Phase00E1OmpIdentity `
            -Sha256 '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6' `
            -Version 'omp/17.2.12')) {
        $runtimeProblems.Add('PINNED_RUNTIME_IDENTITY')
    }
    $caseIds = @(
        'AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly',
        'ProviderStrictOffControl','ProviderStrictOn'
    )
    try {
        for ($index = 0; $index -lt $caseIds.Count; $index += 1) {
            $definition = Get-Phase00E1CaseDefinition -CaseId $caseIds[$index]
            if ([int]$definition.ExecutionOrder -ne ($index + 1) -or
                $definition.RequiresProvider -ne $true) {
                $runtimeProblems.Add("CASE_DEFINITION:$($caseIds[$index])")
            }
        }
    } catch {
        $runtimeProblems.Add("CASE_DEFINITION_ERROR:$($_.Exception.Message)")
    }
    if ($runtimeProblems.Count -eq 0) {
        $results.Add((New-Phase00E1ArtifactValidationResult PASS P00-E1-RUNTIME `
            'The registered E1 runner, helpers, seven-case matrix, runtime pin, and strict forwarder are intact.'))
    } else {
        $results.Add((New-Phase00E1ArtifactValidationResult FAIL P00-E1-RUNTIME `
            ("E1 runtime surface drift: " + (@($runtimeProblems) -join '; '))))
    }

    $protected = Get-Phase00E1ProtectedSnapshot -RepositoryRoot $root `
        -ExpectedHashes (Get-Phase00E1ProtectedHashes)
    $drift = @($protected.Entries | Where-Object { -not $_.Matched } |
        ForEach-Object { $_.Path })
    $laterAgentSupersessionOk = $false
    $laterValidator = Get-Command Test-Phase00T003LaterProductSupersessionContract `
        -ErrorAction SilentlyContinue
    if ($null -ne $laterValidator -and $drift.Count -gt 0) {
        $allowedCurrentProductDrift = @(
            'template/.omp/agents/explorer.md',
            'template/.omp/agents/implementer.md',
            'template/.omp/agents/reviewer.md',
            'template/.omp/agents/tech-lead.md',
            'template/.omp/agents/verifier.md',
            'template/.omp/schemas/verification-result.schema.yml'
        )
        $unexpectedDrift = @($drift | Where-Object { $_ -cnotin $allowedCurrentProductDrift })
        $laterResult = @(Test-Phase00T003LaterProductSupersessionContract `
            -RepositoryRoot $root | Where-Object {
                $_.Code -ceq 'P00-T003-LATER-SUPERSESSION'
            }) | Select-Object -First 1
        $schemaDriftBound = $true
        if ($drift -ccontains 'template/.omp/schemas/verification-result.schema.yml') {
            try {
                $currentManifestPath = Join-Path $root `
                    'docs\evidence\current-product\topic-03\manifest.yml'
                $currentManifest = Get-Content -Raw -LiteralPath $currentManifestPath `
                    -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                $schemaRows = @($currentManifest.current_files | Where-Object {
                    $_.path -ceq 'template/.omp/schemas/verification-result.schema.yml'
                })
                $schemaPath = Join-Path $root `
                    'template\.omp\schemas\verification-result.schema.yml'
                $schemaDriftBound = $schemaRows.Count -eq 1 -and
                    $schemaRows[0].sha256 -ceq (Get-Phase00E1FileSha256 -Path $schemaPath)
            } catch {
                $schemaDriftBound = $false
            }
        }
        $laterAgentSupersessionOk = $unexpectedDrift.Count -eq 0 -and
            $schemaDriftBound -and $null -ne $laterResult -and
            $laterResult.Status -ceq 'PASS'
    }
    if ($protected.AllExpected -and $protected.FileCount -eq 9) {
        $results.Add((New-Phase00E1ArtifactValidationResult PASS `
            P00-E1-PROTECTED-SURFACE `
            'All nine immutable E1 product surfaces match their approved SHA-256 pins.'))
    } elseif ($laterAgentSupersessionOk) {
        $results.Add((New-Phase00E1ArtifactValidationResult PASS `
            P00-E1-PROTECTED-SURFACE `
            'Historical E1 pins remain evidence; current-product supersession binds selected agents and the verification schema.'))
    } else {
        $results.Add((New-Phase00E1ArtifactValidationResult FAIL `
            P00-E1-PROTECTED-SURFACE `
            ("Protected E1 surface drift: " + ($drift -join ', '))))
    }

    $manifestOk = $true
    $manifestMessage = 'E1 is READY with no authority while T-00.4 remains dependency-gated and NOT_STARTED.'
    try {
        $manifestPath = Join-Path $root 'docs\evidence\phase-00\manifest.yml'
        $manifestRows = @(Read-Phase00E1ManifestEntryProjection -Path $manifestPath)
        $e1Rows = @($manifestRows | Where-Object { $_.Id -ceq 'E1' })
        $t004Rows = @($manifestRows | Where-Object { $_.Id -ceq 'T-00.4' })
        if ($e1Rows.Count -ne 1 -or $t004Rows.Count -ne 1) {
            throw 'Manifest must contain exactly one E1 row and one T-00.4 row.'
        }
        $e1 = $e1Rows[0].Fields
        $t004 = $t004Rows[0].Fields
        foreach ($field in @('kind','state','depends_on','artifacts','decision')) {
            if (-not $e1.Contains($field) -or -not $t004.Contains($field)) {
                throw "E1 or T-00.4 is missing manifest field '$field'."
            }
        }
        $e1Ready =
            (ConvertFrom-Phase00E1ManifestScalarText $e1.kind) -ceq 'experiment' -and
            (ConvertFrom-Phase00E1ManifestScalarText $e1.state) -ceq 'READY' -and
            (Test-Phase00E1ManifestSequenceText $e1.depends_on @()) -and
            (Test-Phase00E1ManifestSequenceText $e1.artifacts @()) -and
            $e1.decision.Trim() -ceq 'null'
        $t004Gated =
            (ConvertFrom-Phase00E1ManifestScalarText $t004.kind) -ceq 'foundation' -and
            (ConvertFrom-Phase00E1ManifestScalarText $t004.state) -ceq 'NOT_STARTED' -and
            (Test-Phase00E1ManifestSequenceText $t004.depends_on @('E1')) -and
            (Test-Phase00E1ManifestSequenceText $t004.artifacts @()) -and
            $t004.decision.Trim() -ceq 'null'
        if (-not $e1Ready -or -not $t004Gated) {
            throw 'READY authority boundary requires E1 READY/empty and T-00.4 NOT_STARTED/empty depending only on E1.'
        }
    } catch {
        $manifestOk = $false
        $manifestMessage = $_.Exception.Message
    }
    $results.Add((New-Phase00E1ArtifactValidationResult `
        $(if ($manifestOk) { 'PASS' } else { 'FAIL' }) P00-E1-MANIFEST $manifestMessage))

    $conclusionPath = Join-Path $root 'docs\evidence\phase-00\E1\conclusion.yml'
    $conclusionAbsent = -not (Test-Path -LiteralPath $conclusionPath)
    if ($conclusionAbsent) {
        $results.Add((New-Phase00E1ArtifactValidationResult PASS P00-E1-CONCLUSION `
            'No terminal E1 conclusion exists while the manifest remains READY.'))
    } else {
        $results.Add((New-Phase00E1ArtifactValidationResult FAIL P00-E1-CONCLUSION `
            'READY E1 must not contain a terminal conclusion.'))
    }

    if (@($results | Where-Object { $_.Status -eq 'FAIL' }).Count -eq 0) {
        $rawRoot = Join-Path $root 'docs\evidence\phase-00\E1\raw'
        $historyCount = if (Test-Path -LiteralPath $rawRoot -PathType Container) {
            @(Get-ChildItem -LiteralPath $rawRoot -File -Recurse).Count
        } else { 0 }
        $results.Add((New-Phase00E1ArtifactValidationResult PASS P00-E1-READY `
            ("E1 READY is valid; $historyCount unlisted history file(s) have no terminal authority.")))
    }
    return @($results)
}
