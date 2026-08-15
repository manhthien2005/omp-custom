#Requires -Version 5.1

Set-StrictMode -Version 2.0

$sharedTransportPath = Join-Path $PSScriptRoot 'phase00-e3il-transport.ps1'
if (-not (Get-Command Get-Phase00E3ILToolEventPairs -ErrorAction SilentlyContinue)) {
    . $sharedTransportPath
}

$script:Phase00E3LPinnedCommit = '3a8591a8af5b6d200088d12ca75a5517cb064fa8'
$script:Phase00E3LOfficialOrigin = 'https://github.com/can1357/oh-my-pi.git'
$script:Phase00E3LRuntimeVersion = 'omp/17.2.10'
$script:Phase00E3LRuntimeSha256 = `
    '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
$script:Phase00E3LSupportedHost = `
    'OMP-owned default main-CLI root-session construction class'
$script:Phase00E3LReaderOperation = 'pi.pi.settings.get("task.isolation.apply")'

function New-Phase00E3LResult {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('PASS','FAIL','INVALID_RUN','BLOCKED_ENVIRONMENT')]
        [string]$Status,
        [string[]]$Reasons = @(),
        [hashtable]$Properties = @{}
    )

    $result = [ordered]@{
        Status = $Status
        Reasons = @($Reasons)
    }
    foreach ($name in @($Properties.Keys)) { $result[$name] = $Properties[$name] }
    [pscustomobject]$result
}

function Test-Phase00E3LGitIdentity {
    param(
        [AllowEmptyString()][Parameter(Mandatory)][string]$Head,
        [AllowEmptyCollection()][Parameter(Mandatory)][object[]]$StatusLines,
        [AllowEmptyString()][Parameter(Mandatory)][string]$Origin
    )

    $reasons = @()
    if ($Head.Trim() -cne $script:Phase00E3LPinnedCommit) {
        $reasons += 'E3L_SOURCE_COMMIT_MISMATCH'
    }
    $dirtyLines = @($StatusLines | Where-Object {
        $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_)
    })
    if ($dirtyLines.Count -ne 0) { $reasons += 'E3L_SOURCE_TREE_DIRTY' }
    if ($Origin.Trim() -cne $script:Phase00E3LOfficialOrigin) {
        $reasons += 'E3L_SOURCE_ORIGIN_MISMATCH'
    }
    New-Phase00E3LResult -Status $(if ($reasons.Count -eq 0) { 'PASS' } else {
        'INVALID_RUN'
    }) -Reasons $reasons -Properties @{
        Head = $Head.Trim()
        Origin = $Origin.Trim()
        Clean = ($dirtyLines.Count -eq 0)
    }
}

function Get-Phase00E3LSafeSourceFile {
    param(
        [Parameter(Mandatory)][string]$OmpSourceRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $segments = @($RelativePath -split '[\\/]')
    if ([IO.Path]::IsPathRooted($RelativePath) -or $segments -contains '..') {
        throw "E3-L source path escapes audited root: $RelativePath"
    }
    $root = [IO.Path]::GetFullPath($OmpSourceRoot).TrimEnd('\','/')
    $candidate = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
    $prefix = $root + [IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "E3-L source path escapes audited root: $RelativePath"
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw "E3-L source file is missing: $RelativePath"
    }
    $candidate
}

function Test-Phase00E3LSourceWindow {
    param(
        [Parameter(Mandatory)][string]$OmpSourceRoot,
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][int]$StartLine,
        [Parameter(Mandatory)][int]$EndLine,
        [Parameter(Mandatory)][string[]]$Patterns,
        [Parameter(Mandatory)][string]$Reason
    )

    $path = Get-Phase00E3LSafeSourceFile -OmpSourceRoot $OmpSourceRoot `
        -RelativePath $RelativePath
    $lines = @([IO.File]::ReadAllLines($path))
    if ($StartLine -lt 1 -or $EndLine -lt $StartLine -or $EndLine -gt $lines.Count) {
        return [pscustomobject][ordered]@{
            Id = $Id; Status = 'INVALID_RUN'; Reason = 'E3L_SOURCE_LINE_RANGE_INVALID'
            Path = $RelativePath.Replace('\','/'); ExpectedStartLine = $StartLine
            ExpectedEndLine = $EndLine; ActualLines = @(); FileSha256 = ''
        }
    }

    $actualLines = @()
    $missing = $false
    foreach ($pattern in $Patterns) {
        $matchedLines = @()
        for ($lineNumber = $StartLine; $lineNumber -le $EndLine; $lineNumber++) {
            if ($lines[$lineNumber - 1] -match $pattern) { $matchedLines += $lineNumber }
        }
        if ($matchedLines.Count -eq 0) {
            $missing = $true
        } else {
            $actualLines += $matchedLines[0]
        }
    }
    [pscustomobject][ordered]@{
        Id = $Id
        Status = if ($missing) { 'FAIL' } else { 'PASS' }
        Reason = if ($missing) { $Reason } else { '' }
        Path = $RelativePath.Replace('\','/')
        ExpectedStartLine = $StartLine
        ExpectedEndLine = $EndLine
        ActualLines = @($actualLines | Sort-Object -Unique)
        FileSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
    }
}

function Test-Phase00E3LSourceLinks {
    param([Parameter(Mandatory)][string]$OmpSourceRoot)

    try {
        $positive = @(
            Test-Phase00E3LSourceWindow $OmpSourceRoot 'EXPORT' `
                'packages/coding-agent/src/index.ts' 17 17 @(
                    '^export \{ Settings, settings \} from "\./config/settings";$'
                ) 'E3L_SOURCE_EXPORT_CONTRADICTION'
            Test-Phase00E3LSourceWindow $OmpSourceRoot 'GLOBAL_INIT' `
                'packages/coding-agent/src/config/settings.ts' 404 416 @(
                    'static init\(options: SettingsOptions = \{\}\): Promise<Settings>',
                    'const instance = new Settings\(options\);',
                    'globalInstancePromise = promise;',
                    'globalInstance = instance;',
                    'globalInstancePromise = Promise\.resolve\(instance\);',
                    'return instance;'
                ) 'E3L_SOURCE_INIT_CONTRADICTION'
            Test-Phase00E3LSourceWindow $OmpSourceRoot 'MAIN_INIT' `
                'packages/coding-agent/src/main.ts' 1282 1283 @(
                    'const settingsInstance =',
                    'deps\.settings \?\? \(await logger\.time\("settings:init", Settings\.init,'
                ) 'E3L_SOURCE_MAIN_INIT_CONTRADICTION'
            Test-Phase00E3LSourceWindow $OmpSourceRoot 'SESSION_OPTIONS' `
                'packages/coding-agent/src/main.ts' 1533 1545 @(
                    'const sessionOptions = await logger\.time\(',
                    '^\s*settingsInstance,?$',
                    'sessionOptions\.settings = settingsInstance;'
                ) 'E3L_SOURCE_SESSION_OPTIONS_CONTRADICTION'
            Test-Phase00E3LSourceWindow $OmpSourceRoot 'SDK_EXPLICIT_SETTINGS' `
                'packages/coding-agent/src/sdk.ts' 1271 1274 @(
                    'const settings = await \(options\.settings \?\?',
                    'options\.settingsManager \?\?',
                    'Settings\.init',
                    'initializeWithSettings.*settings'
                ) 'E3L_SOURCE_SDK_SETTINGS_CONTRADICTION'
            Test-Phase00E3LSourceWindow $OmpSourceRoot 'TASK_DISPATCH' `
                'packages/coding-agent/src/task/structured-subagent.ts' 315 317 @(
                    'applyChanges:',
                    'request\.isolation\?\.apply \?\?',
                    'request\.session\.settings\.get\("task\.isolation\.apply"\)'
                ) 'E3L_SOURCE_DISPATCH_CONTRADICTION'
            Test-Phase00E3LSourceWindow $OmpSourceRoot 'GLOBAL_PROXY' `
                'packages/coding-agent/src/config/settings.ts' 2371 2388 @(
                    'export const settings = new Proxy',
                    'if \(!globalInstance\)',
                    'boundSettingsInstance = globalInstance;',
                    'const value = \(globalInstance as unknown',
                    'value\.bind\(globalInstance\)',
                    'return value;'
                ) 'E3L_SOURCE_PROXY_CONTRADICTION'
        )
        $exclusions = @(
            Test-Phase00E3LSourceWindow $OmpSourceRoot 'ACP_SESSION_NEW' `
                'packages/coding-agent/src/main.ts' 397 424 @(
                    'createAcpSessionFactory',
                    'args\.settings\.cloneForCwd\(cwd\)',
                    'settings: nextSettings'
                ) 'E3L_SOURCE_ACP_EXCLUSION_CONTRADICTION'
            Test-Phase00E3LSourceWindow $OmpSourceRoot 'CLONE_FOR_CWD' `
                'packages/coding-agent/src/config/settings.ts' 603 620 @(
                    'cloneForCwd\(cwd: string\)',
                    'const cloned = new Settings\(',
                    'cloned\.#global = structuredClone',
                    'return cloned;'
                ) 'E3L_SOURCE_CLONE_EXCLUSION_CONTRADICTION'
            Test-Phase00E3LSourceWindow $OmpSourceRoot 'SDK_SETTINGS_INJECTION' `
                'packages/coding-agent/src/sdk.ts' 1271 1273 @(
                    'options\.settings \?\?',
                    'options\.settingsManager \?\?'
                ) 'E3L_SOURCE_SDK_INJECTION_EXCLUSION_CONTRADICTION'
            Test-Phase00E3LSourceWindow $OmpSourceRoot 'MAIN_DEPENDENCY_INJECTION' `
                'packages/coding-agent/src/main.ts' 1282 1283 @(
                    'deps\.settings \?\?',
                    'Settings\.init'
                ) 'E3L_SOURCE_DEPENDENCY_INJECTION_EXCLUSION_CONTRADICTION'
            Test-Phase00E3LSourceWindow $OmpSourceRoot 'RPC_PROTOCOL' `
                'packages/coding-agent/src/main.ts' 1269 1269 @(
                    'const isProtocolMode = mode === "rpc"'
                ) 'E3L_SOURCE_RPC_EXCLUSION_CONTRADICTION'
            Test-Phase00E3LSourceWindow $OmpSourceRoot 'RPC_UI_PROTOCOL' `
                'packages/coding-agent/src/main.ts' 1269 1269 @(
                    'mode === "rpc-ui"'
                ) 'E3L_SOURCE_RPC_UI_EXCLUSION_CONTRADICTION'
        )
    } catch {
        return New-Phase00E3LResult -Status INVALID_RUN `
            -Reasons @('E3L_SOURCE_INACCESSIBLE_OR_AMBIGUOUS') -Properties @{
                PositiveLinks = @(); Exclusions = @(); Error = $_.Exception.Message
            }
    }

    $checks = @($positive + $exclusions)
    $invalid = @($checks | Where-Object Status -eq 'INVALID_RUN')
    $failed = @($checks | Where-Object Status -eq 'FAIL')
    $status = if ($invalid.Count -gt 0) { 'INVALID_RUN' } elseif ($failed.Count -gt 0) {
        'FAIL'
    } else { 'PASS' }
    $reasons = if ($invalid.Count -gt 0) {
        @($invalid.Reason | Sort-Object -Unique)
    } elseif ($failed.Count -gt 0) {
        @($failed.Reason | Sort-Object -Unique)
    } else {
        @()
    }
    New-Phase00E3LResult -Status $status -Reasons $reasons -Properties @{
        PositiveLinks = $positive
        Exclusions = $exclusions
    }
}

function Get-Phase00E3LSourceIdentity {
    param([Parameter(Mandatory)][string]$OmpSourceRoot)

    try {
        $root = (Resolve-Path -LiteralPath $OmpSourceRoot -ErrorAction Stop).Path
        $headOutput = @(& git -C $root rev-parse HEAD 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Cannot resolve Git HEAD: $($headOutput -join ' ')" }
        $statusOutput = @(& git -C $root status --porcelain=v1 --untracked-files=all 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Cannot resolve Git status: $($statusOutput -join ' ')" }
        $originOutput = @(& git -C $root remote get-url origin 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Cannot resolve Git origin: $($originOutput -join ' ')" }
    } catch {
        return New-Phase00E3LResult -Status INVALID_RUN `
            -Reasons @('E3L_SOURCE_GIT_INACCESSIBLE') -Properties @{
                SourceRoot = $OmpSourceRoot; Error = $_.Exception.Message
                PositiveLinks = @(); Exclusions = @()
            }
    }

    $gitIdentity = Test-Phase00E3LGitIdentity -Head ([string]$headOutput[0]) `
        -StatusLines @($statusOutput) -Origin ([string]$originOutput[0])
    if ($gitIdentity.Status -ne 'PASS') {
        return New-Phase00E3LResult -Status INVALID_RUN -Reasons $gitIdentity.Reasons `
            -Properties @{
                SourceRoot = $root; GitIdentity = $gitIdentity
                PositiveLinks = @(); Exclusions = @()
            }
    }

    $links = Test-Phase00E3LSourceLinks -OmpSourceRoot $root
    New-Phase00E3LResult -Status $links.Status -Reasons $links.Reasons -Properties @{
        SchemaVersion = 1
        Experiment = 'E3-L'
        RuntimeVersion = $script:Phase00E3LRuntimeVersion
        RuntimeSha256 = $script:Phase00E3LRuntimeSha256
        PinnedCommit = $script:Phase00E3LPinnedCommit
        OfficialOrigin = $script:Phase00E3LOfficialOrigin
        SupportedHost = $script:Phase00E3LSupportedHost
        ReaderOperation = $script:Phase00E3LReaderOperation
        SourceRoot = $root
        GitIdentity = $gitIdentity
        PositiveLinks = @($links.PositiveLinks)
        Exclusions = @($links.Exclusions)
    }
}

function Write-Phase00E3LSourceIdentityArtifact {
    param(
        [Parameter(Mandatory)]$Identity,
        [Parameter(Mandatory)][string]$OutputPath
    )

    if ($Identity.Status -ne 'PASS') {
        throw "Cannot write non-PASS E3-L source identity: $($Identity.Status)"
    }
    $filesByPath = @{}
    foreach ($check in @($Identity.PositiveLinks + $Identity.Exclusions)) {
        $filesByPath[[string]$check.Path] = [string]$check.FileSha256
    }
    $artifact = [ordered]@{
        schema_version = 1
        experiment = 'E3-L'
        status = 'PASS'
        runtime_version = [string]$Identity.RuntimeVersion
        runtime_executable_sha256 = [string]$Identity.RuntimeSha256
        pinned_commit = [string]$Identity.PinnedCommit
        official_origin = [string]$Identity.OfficialOrigin
        supported_host = [string]$Identity.SupportedHost
        reader_operation = [string]$Identity.ReaderOperation
        positive_links = @($Identity.PositiveLinks | ForEach-Object {
            [ordered]@{
                id = $_.Id; path = $_.Path
                expected_line_range = @([int]$_.ExpectedStartLine, [int]$_.ExpectedEndLine)
                actual_lines = @($_.ActualLines)
                file_sha256 = $_.FileSha256
            }
        })
        exclusions = @($Identity.Exclusions | ForEach-Object {
            [ordered]@{
                id = $_.Id; path = $_.Path
                expected_line_range = @([int]$_.ExpectedStartLine, [int]$_.ExpectedEndLine)
                actual_lines = @($_.ActualLines)
                file_sha256 = $_.FileSha256
            }
        })
        files = @($filesByPath.Keys | Sort-Object | ForEach-Object {
            [ordered]@{ path = $_; sha256 = $filesByPath[$_] }
        })
        non_claims = @(
            'ACP-created sessions are outside this claim.',
            'Cloned settings instances are outside this claim.',
            'Injected SDK or dependency settings are outside this claim.',
            'RPC and RPC-UI lifecycle coverage is outside this claim.',
            'Parallel behavior remains disabled and is governed by E3-M.'
        )
        runtime_observation_substitutes_source = $false
    }
    $parent = Split-Path -Parent $OutputPath
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [IO.Directory]::CreateDirectory($parent) | Out-Null
    }
    $json = $artifact | ConvertTo-Json -Depth 12
    [IO.File]::WriteAllText($OutputPath, $json + "`n", [Text.UTF8Encoding]::new($false))
    $artifact
}

function Test-Phase00E3LValueEquality {
    param($Left, $Right)

    if ($null -eq $Left -or $null -eq $Right) { return $null -eq $Left -and $null -eq $Right }
    if (($Left -is [bool]) -xor ($Right -is [bool])) { return $false }
    if (($Left -is [string]) -xor ($Right -is [string])) { return $false }
    $Left -ceq $Right
}

function ConvertFrom-Phase00E3LReaderResult {
    param([Parameter(Mandatory)]$ToolResult)

    try {
        $details = Get-Phase00PropertyValue $ToolResult 'details'
        if ($null -eq $details) { throw 'Reader details are absent.' }
        $text = Get-Phase00E3ILResultText $ToolResult
        $rendered = $text | ConvertFrom-Json -ErrorAction Stop
    } catch {
        return New-Phase00E3LResult INVALID_RUN @('E3L_READER_EVIDENCE_INVALID') @{
            Error = $_.Exception.Message
        }
    }

    $expected = @('operation','probe','scope','setting','value')
    $detailNames = @(Get-Phase00E3ILPropertyNames $details)
    $renderedNames = @(Get-Phase00E3ILPropertyNames $rendered)
    if (($detailNames -join ',') -ne ($renderedNames -join ',')) {
        return New-Phase00E3LResult INVALID_RUN @('E3L_READER_EVIDENCE_INVALID') @{
            Error = 'Reader text/details shape divergence.'
        }
    }
    foreach ($name in $detailNames) {
        if (-not (Test-Phase00E3LValueEquality `
            (Get-Phase00PropertyValue $details $name) `
            (Get-Phase00PropertyValue $rendered $name))) {
            return New-Phase00E3LResult INVALID_RUN `
                @('E3L_READER_EVIDENCE_INVALID') @{
                    Error = "Reader text/details divergence at '$name'."
                }
        }
    }
    if (($detailNames -join ',') -ne ($expected -join ',')) {
        return New-Phase00E3LResult FAIL @('E3L_READER_CONTRADICTION') @{
            ObservedProperties = $detailNames
        }
    }

    $value = Get-Phase00PropertyValue $details 'value'
    $exact =
        (Get-Phase00PropertyValue $details 'probe') -ceq 'phase00-e3l-live-reader-v1' -and
        (Get-Phase00PropertyValue $details 'setting') -ceq 'task.isolation.apply' -and
        (Get-Phase00PropertyValue $details 'operation') -ceq 'pi.pi.settings.get' -and
        $value -is [bool] -and
        (Get-Phase00PropertyValue $details 'scope') -ceq 'parent-only'
    if (-not $exact) {
        return New-Phase00E3LResult FAIL @('E3L_READER_CONTRADICTION') @{
            Details = $details
        }
    }
    New-Phase00E3LResult PASS @('E3L_READER_EXACT') @{
        Value = [bool]$value
        Details = $details
    }
}

function Test-Phase00E3LReaderPair {
    param([Parameter(Mandatory)]$Pair)

    try {
        if ((Get-Phase00PropertyValue $Pair 'ToolName') -ne 'phase00_e3l_read_apply') {
            throw 'Expected phase00_e3l_read_apply.'
        }
        $arguments = Get-Phase00PropertyValue `
            (Get-Phase00PropertyValue $Pair 'Start') 'args'
        if (@(Get-Phase00E3ILPropertyNames $arguments).Count -ne 0) {
            throw 'Reader invocation arguments are not empty.'
        }
        $end = Get-Phase00PropertyValue $Pair 'End'
        if ((Get-Phase00PropertyValue $end 'isError') -eq $true) {
            throw 'Reader completion is an error.'
        }
        ConvertFrom-Phase00E3LReaderResult `
            (Get-Phase00PropertyValue $end 'result')
    } catch {
        New-Phase00E3LResult INVALID_RUN @('E3L_READER_EVIDENCE_INVALID') @{
            Error = $_.Exception.Message
        }
    }
}

function ConvertFrom-Phase00E3LOverrideResult {
    param([Parameter(Mandatory)]$ToolResult)

    try {
        $details = Get-Phase00PropertyValue $ToolResult 'details'
        if ($null -eq $details) { throw 'Override details are absent.' }
        $text = Get-Phase00E3ILResultText $ToolResult
        $rendered = $text | ConvertFrom-Json -ErrorAction Stop
    } catch {
        return New-Phase00E3LResult INVALID_RUN @('E3L_OVERRIDE_EVIDENCE_INVALID') @{
            Error = $_.Exception.Message
        }
    }

    $expected = @(
        'after','before','calledFlushOrSave','calledSet','operation',
        'probe','requested','scope','setting'
    )
    $detailNames = @(Get-Phase00E3ILPropertyNames $details)
    $renderedNames = @(Get-Phase00E3ILPropertyNames $rendered)
    if (($detailNames -join ',') -ne ($renderedNames -join ',')) {
        return New-Phase00E3LResult INVALID_RUN @('E3L_OVERRIDE_EVIDENCE_INVALID') @{
            Error = 'Override text/details shape divergence.'
        }
    }
    foreach ($name in $detailNames) {
        if (-not (Test-Phase00E3LValueEquality `
            (Get-Phase00PropertyValue $details $name) `
            (Get-Phase00PropertyValue $rendered $name))) {
            return New-Phase00E3LResult INVALID_RUN `
                @('E3L_OVERRIDE_EVIDENCE_INVALID') @{
                    Error = "Override text/details divergence at '$name'."
                }
        }
    }
    if (($detailNames -join ',') -ne ($expected -join ',')) {
        return New-Phase00E3LResult FAIL @('E3L_OVERRIDE_CONTRADICTION') @{
            ObservedProperties = $detailNames
        }
    }

    $before = Get-Phase00PropertyValue $details 'before'
    $requested = Get-Phase00PropertyValue $details 'requested'
    $after = Get-Phase00PropertyValue $details 'after'
    $calledSet = Get-Phase00PropertyValue $details 'calledSet'
    $calledFlush = Get-Phase00PropertyValue $details 'calledFlushOrSave'
    $exact =
        (Get-Phase00PropertyValue $details 'probe') -ceq 'phase00-e3i-runtime-override-v1' -and
        (Get-Phase00PropertyValue $details 'setting') -ceq 'task.isolation.apply' -and
        $before -is [bool] -and -not $before -and
        (Get-Phase00PropertyValue $details 'operation') -ceq 'pi.pi.settings.override' -and
        $requested -is [bool] -and $requested -and
        $after -is [bool] -and $after -and
        $calledSet -is [bool] -and -not $calledSet -and
        $calledFlush -is [bool] -and -not $calledFlush -and
        (Get-Phase00PropertyValue $details 'scope') -ceq 'parent-only'
    if (-not $exact) {
        return New-Phase00E3LResult FAIL @('E3L_OVERRIDE_CONTRADICTION') @{
            Details = $details
        }
    }
    New-Phase00E3LResult PASS @('E3L_OVERRIDE_EXACT') @{
        Before = $false; After = $true; Details = $details
    }
}

function Get-Phase00E3LSessionMetadata {
    param([Parameter(Mandatory)]$SessionTransport)

    $metadata = @{}
    foreach ($name in @(
        'Attempt','Selected','RuntimeVersion','RuntimeSha256','SupportedHost'
    )) {
        if (Test-Phase00HasProperty $SessionTransport $name) {
            $metadata[$name] = Get-Phase00PropertyValue $SessionTransport $name
        }
    }
    $metadata.TransportStatus = Get-Phase00PropertyValue $SessionTransport 'Status'
    $metadata.TransportReasons = @(Get-Phase00PropertyValue $SessionTransport 'Reasons')
    if (Test-Phase00HasProperty $SessionTransport 'Boundary') {
        $metadata.Boundary = Get-Phase00PropertyValue $SessionTransport 'Boundary'
    }
    $metadata
}

function New-Phase00E3LCaseResult {
    param(
        [Parameter(Mandatory)][ValidateSet('L1','L2','L3')][string]$Name,
        [Parameter(Mandatory)]$Reader,
        [Parameter(Mandatory)]$Diagnostic,
        [Parameter(Mandatory)][object[]]$TaskSamples,
        [Parameter(Mandatory)][bool]$ExpectedReader,
        [Parameter(Mandatory)][bool]$ExpectedChild,
        [Parameter(Mandatory)][string]$ExpectedBranch,
        $Override = $null
    )

    $branches = @($TaskSamples | ForEach-Object {
        [string](Get-Phase00PropertyValue $_ 'Branch')
    })
    $readerValue = Get-Phase00PropertyValue $Reader 'Value'
    $childValue = Get-Phase00PropertyValue $Diagnostic 'Value'
    $exact =
        $Reader.Status -eq 'PASS' -and
        $readerValue -is [bool] -and $readerValue -eq $ExpectedReader -and
        $childValue -is [bool] -and $childValue -eq $ExpectedChild -and
        $TaskSamples.Count -eq 3 -and
        @($branches | Where-Object { $_ -ne $ExpectedBranch }).Count -eq 0 -and
        ($null -eq $Override -or $Override.Status -eq 'PASS')
    [pscustomobject][ordered]@{
        Name = $Name
        Status = if ($exact) { 'PASS' } else { 'FAIL' }
        Reason = if ($exact) { "E3L_${Name}_EXACT" } else { "E3L_${Name}_CONTRADICTION" }
        ReaderValue = $readerValue
        ChildValue = $childValue
        TaskBranches = $branches
        ExpectedReader = $ExpectedReader
        ExpectedChild = $ExpectedChild
        ExpectedBranch = $ExpectedBranch
        OverrideStatus = if ($null -eq $Override) { 'NOT_APPLICABLE' } else { $Override.Status }
    }
}

function New-Phase00E3LOracleTransportResult {
    param(
        [Parameter(Mandatory)]$SessionTransport,
        [Parameter(Mandatory)][ValidateSet('A','B')][string]$ExpectedSession
    )

    $status = [string](Get-Phase00PropertyValue $SessionTransport 'Status')
    $reasons = @(Get-Phase00PropertyValue $SessionTransport 'Reasons')
    $metadata = Get-Phase00E3LSessionMetadata $SessionTransport
    if ($status -eq 'BLOCKED_ENVIRONMENT') {
        return New-Phase00E3LResult BLOCKED_ENVIRONMENT $reasons $metadata
    }
    if ($status -ne 'ELIGIBLE') {
        return New-Phase00E3LResult INVALID_RUN `
            @('E3L_SHARED_TRANSPORT_INVALID') $metadata
    }
    if ((Get-Phase00PropertyValue $SessionTransport 'Session') -ne $ExpectedSession) {
        return New-Phase00E3LResult INVALID_RUN `
            @('E3L_SESSION_IDENTITY_INVALID') $metadata
    }
    $null
}

function Test-Phase00E3LSessionAOracle {
    param([Parameter(Mandatory)]$SessionTransport)

    $early = New-Phase00E3LOracleTransportResult $SessionTransport A
    if ($null -ne $early) { return $early }
    $metadata = Get-Phase00E3LSessionMetadata $SessionTransport
    try {
        $pairs = @(Get-Phase00PropertyValue $SessionTransport 'Pairs')
        $diagnostics = @(Get-Phase00PropertyValue $SessionTransport 'Diagnostics')
        $samples = @(Get-Phase00PropertyValue $SessionTransport 'TaskSamples')
        if ($pairs.Count -ne 11 -or $diagnostics.Count -ne 2 -or $samples.Count -ne 6) {
            throw 'Session A cardinality is incomplete.'
        }
        $readerL1 = Test-Phase00E3LReaderPair $pairs[0]
        $readerL3 = Test-Phase00E3LReaderPair $pairs[6]
        $override = ConvertFrom-Phase00E3LOverrideResult `
            (Get-Phase00PropertyValue $pairs[5].End 'result')
        $invalidEvidence = @(@($readerL1,$readerL3,$override) | Where-Object {
            $_.Status -eq 'INVALID_RUN'
        })
        if ($invalidEvidence.Count -gt 0) {
            throw 'Session A reader or override evidence is structurally invalid.'
        }
        $cases = @(
            New-Phase00E3LCaseResult L1 $readerL1 $diagnostics[0] `
                @($samples[0..2]) $false $false 'APPLY_FALSE_CAPTURE_ONLY'
            New-Phase00E3LCaseResult L3 $readerL3 $diagnostics[1] `
                @($samples[3..5]) $true $false 'APPLY_TRUE_NO_DIFF' $override
        )
    } catch {
        $metadata.Error = $_.Exception.Message
        return New-Phase00E3LResult INVALID_RUN @('E3L_SESSION_A_EVIDENCE_INVALID') $metadata
    }
    $metadata.Cases = $cases
    $failed = @($cases | Where-Object Status -eq 'FAIL')
    New-Phase00E3LResult $(if ($failed.Count -eq 0) { 'PASS' } else { 'FAIL' }) `
        $(if ($failed.Count -eq 0) { @('E3L_SESSION_A_EXACT') } else {
            @($failed.Reason)
        }) $metadata
}

function Test-Phase00E3LSessionBOracle {
    param([Parameter(Mandatory)]$SessionTransport)

    $early = New-Phase00E3LOracleTransportResult $SessionTransport B
    if ($null -ne $early) { return $early }
    $metadata = Get-Phase00E3LSessionMetadata $SessionTransport
    try {
        $pairs = @(Get-Phase00PropertyValue $SessionTransport 'Pairs')
        $diagnostics = @(Get-Phase00PropertyValue $SessionTransport 'Diagnostics')
        $samples = @(Get-Phase00PropertyValue $SessionTransport 'TaskSamples')
        if ($pairs.Count -ne 5 -or $diagnostics.Count -ne 1 -or $samples.Count -ne 3) {
            throw 'Session B cardinality is incomplete.'
        }
        $reader = Test-Phase00E3LReaderPair $pairs[0]
        if ($reader.Status -eq 'INVALID_RUN') {
            throw 'Session B reader evidence is structurally invalid.'
        }
        $cases = @(
            New-Phase00E3LCaseResult L2 $reader $diagnostics[0] $samples `
                $true $false 'APPLY_TRUE_NO_DIFF'
        )
    } catch {
        $metadata.Error = $_.Exception.Message
        return New-Phase00E3LResult INVALID_RUN @('E3L_SESSION_B_EVIDENCE_INVALID') $metadata
    }
    $metadata.Cases = $cases
    $failed = @($cases | Where-Object Status -eq 'FAIL')
    New-Phase00E3LResult $(if ($failed.Count -eq 0) { 'PASS' } else { 'FAIL' }) `
        $(if ($failed.Count -eq 0) { @('E3L_SESSION_B_EXACT') } else {
            @($failed.Reason)
        }) $metadata
}

function Test-Phase00E3LTransaction {
    param(
        [Parameter(Mandatory)]$SourceIdentity,
        [Parameter(Mandatory)]$SessionA,
        [Parameter(Mandatory)]$SessionB
    )

    $sourceStatus = [string](Get-Phase00PropertyValue $SourceIdentity 'Status')
    if ($sourceStatus -eq 'INVALID_RUN' -or $sourceStatus -notin @('PASS','FAIL')) {
        return New-Phase00E3LResult INVALID_RUN @('E3L_SOURCE_IDENTITY_INVALID')
    }
    $aStatus = [string](Get-Phase00PropertyValue $SessionA 'Status')
    $bStatus = [string](Get-Phase00PropertyValue $SessionB 'Status')
    if ($aStatus -eq 'INVALID_RUN' -or $bStatus -eq 'INVALID_RUN' -or
        [string]::IsNullOrWhiteSpace($aStatus) -or [string]::IsNullOrWhiteSpace($bStatus)) {
        return New-Phase00E3LResult INVALID_RUN @('E3L_TRANSACTION_RAW_INVALID')
    }
    if ($aStatus -eq 'BLOCKED_ENVIRONMENT' -or $bStatus -eq 'BLOCKED_ENVIRONMENT') {
        $blockReasons = @(
            @(Get-Phase00PropertyValue $SessionA 'Reasons') +
            @(Get-Phase00PropertyValue $SessionB 'Reasons')
        )
        return New-Phase00E3LResult BLOCKED_ENVIRONMENT $blockReasons
    }
    if ($aStatus -notin @('PASS','FAIL') -or $bStatus -notin @('PASS','FAIL')) {
        return New-Phase00E3LResult INVALID_RUN @('E3L_TRANSACTION_RAW_INVALID')
    }

    $aAttempt = Get-Phase00PropertyValue $SessionA 'Attempt'
    $bAttempt = Get-Phase00PropertyValue $SessionB 'Attempt'
    $identityExact =
        $aAttempt -is [int] -and $aAttempt -ge 5 -and
        $bAttempt -is [int] -and $bAttempt -eq $aAttempt -and
        (Get-Phase00PropertyValue $SessionA 'Selected') -eq $true -and
        (Get-Phase00PropertyValue $SessionB 'Selected') -eq $true -and
        (Get-Phase00PropertyValue $SessionA 'RuntimeVersion') -ceq $script:Phase00E3LRuntimeVersion -and
        (Get-Phase00PropertyValue $SessionB 'RuntimeVersion') -ceq $script:Phase00E3LRuntimeVersion -and
        (Get-Phase00PropertyValue $SessionA 'RuntimeSha256') -ceq $script:Phase00E3LRuntimeSha256 -and
        (Get-Phase00PropertyValue $SessionB 'RuntimeSha256') -ceq $script:Phase00E3LRuntimeSha256 -and
        (Get-Phase00PropertyValue $SessionA 'SupportedHost') -ceq $script:Phase00E3LSupportedHost -and
        (Get-Phase00PropertyValue $SessionB 'SupportedHost') -ceq $script:Phase00E3LSupportedHost -and
        (Get-Phase00PropertyValue $SourceIdentity 'RuntimeVersion') -ceq $script:Phase00E3LRuntimeVersion -and
        (Get-Phase00PropertyValue $SourceIdentity 'RuntimeSha256') -ceq $script:Phase00E3LRuntimeSha256 -and
        (Get-Phase00PropertyValue $SourceIdentity 'PinnedCommit') -ceq $script:Phase00E3LPinnedCommit -and
        (Get-Phase00PropertyValue $SourceIdentity 'SupportedHost') -ceq $script:Phase00E3LSupportedHost -and
        @(Get-Phase00PropertyValue $SourceIdentity 'PositiveLinks').Count -eq 7 -and
        @(Get-Phase00PropertyValue $SourceIdentity 'Exclusions').Count -eq 6
    if (-not $identityExact) {
        return New-Phase00E3LResult INVALID_RUN @('E3L_TRANSACTION_IDENTITY_INVALID')
    }

    $cases = @(
        @(Get-Phase00PropertyValue $SessionA 'Cases') +
        @(Get-Phase00PropertyValue $SessionB 'Cases')
    ) | Sort-Object Name
    if ($sourceStatus -eq 'FAIL' -or $aStatus -eq 'FAIL' -or $bStatus -eq 'FAIL') {
        return New-Phase00E3LResult FAIL @('E3L_TRANSACTION_CONTRADICTION') @{
            Attempt = $aAttempt; Selected = $true; Cases = @($cases); Claim = $null
            RuntimeVersion = $script:Phase00E3LRuntimeVersion
            RuntimeSha256 = $script:Phase00E3LRuntimeSha256
            SupportedHost = $script:Phase00E3LSupportedHost
            Transport = [ordered]@{
                A = Get-Phase00PropertyValue $SessionA 'TransportStatus'
                B = Get-Phase00PropertyValue $SessionB 'TransportStatus'
            }
            Boundaries = [ordered]@{
                A = Get-Phase00PropertyValue $SessionA 'Boundary'
                B = Get-Phase00PropertyValue $SessionB 'Boundary'
            }
            OracleStatuses = [ordered]@{ SessionA = $aStatus; SessionB = $bStatus; Transaction = 'FAIL' }
        }
    }
    New-Phase00E3LResult PASS @('E3L_L1_L2_L3_EXACT') @{
        Attempt = $aAttempt
        Selected = $true
        Cases = @($cases)
        Claim = 'The approved proxy observes live effective task.isolation.apply for the OMP-owned default main-CLI root-session class on pinned 17.2.10.'
        RuntimeVersion = $script:Phase00E3LRuntimeVersion
        RuntimeSha256 = $script:Phase00E3LRuntimeSha256
        SupportedHost = $script:Phase00E3LSupportedHost
        Transport = [ordered]@{
            A = Get-Phase00PropertyValue $SessionA 'TransportStatus'
            B = Get-Phase00PropertyValue $SessionB 'TransportStatus'
        }
        Boundaries = [ordered]@{
            A = Get-Phase00PropertyValue $SessionA 'Boundary'
            B = Get-Phase00PropertyValue $SessionB 'Boundary'
        }
        OracleStatuses = [ordered]@{ SessionA = $aStatus; SessionB = $bStatus; Transaction = 'PASS' }
    }
}

function New-Phase00E3LTransactionProjection {
    param(
        [Parameter(Mandatory)]$Transaction,
        [Parameter(Mandatory)][object[]]$RawInputs,
        [string]$RepositoryRoot = ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')))
    )

    $status = [string](Get-Phase00PropertyValue $Transaction 'Status')
    $attempt = Get-Phase00PropertyValue $Transaction 'Attempt'
    if ($status -notin @('PASS','FAIL') -or
        (Get-Phase00PropertyValue $Transaction 'Selected') -ne $true -or
        $attempt -isnot [int] -or $attempt -lt 5) {
        throw 'Only a complete selected PASS/FAIL E3-L transaction can be projected.'
    }
    $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\','/')
    $prefix = $root + [IO.Path]::DirectorySeparatorChar
    $rawReferences = @()
    foreach ($input in $RawInputs) {
        $properties = @(Get-Phase00E3ILPropertyNames $input)
        if (($properties -join ',') -ne 'Path') {
            throw 'Raw projection inputs accept only one Path property.'
        }
        $path = [IO.Path]::GetFullPath([string](Get-Phase00PropertyValue $input 'Path'))
        if (-not $path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Raw projection input is missing or escapes the repository root: $path"
        }
        $rawReferences += [pscustomobject][ordered]@{
            path = $path.Substring($prefix.Length).Replace('\','/')
            sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
        }
    }
    $rawReferences = @($rawReferences | Sort-Object path)
    if ($rawReferences.Count -eq 0 -or
        @($rawReferences.path | Sort-Object -Unique).Count -ne $rawReferences.Count) {
        throw 'Selected projection requires unique raw input paths.'
    }

    $sourcePath = [string](Get-Phase00PropertyValue $Transaction 'SourceIdentityPath')
    $sourceHash = [string](Get-Phase00PropertyValue $Transaction 'SourceIdentitySha256')
    if ([IO.Path]::IsPathRooted($sourcePath) -or [string]::IsNullOrWhiteSpace($sourcePath)) {
        throw 'Selected projection requires a repository-relative source identity path.'
    }
    $sourceFull = [IO.Path]::GetFullPath((Join-Path $root $sourcePath))
    if (-not $sourceFull.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $sourceFull -PathType Leaf) -or
        (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceFull).Hash -cne $sourceHash) {
        throw 'Selected projection source identity is missing or hash-incoherent.'
    }

    $cases = @((Get-Phase00PropertyValue $Transaction 'Cases') | Sort-Object Name |
        ForEach-Object {
            [pscustomobject][ordered]@{
                name = [string](Get-Phase00PropertyValue $_ 'Name')
                status = [string](Get-Phase00PropertyValue $_ 'Status')
                reader_value = Get-Phase00PropertyValue $_ 'ReaderValue'
                child_value = Get-Phase00PropertyValue $_ 'ChildValue'
                task_branches = @(Get-Phase00PropertyValue $_ 'TaskBranches')
                expected_reader = Get-Phase00PropertyValue $_ 'ExpectedReader'
                expected_child = Get-Phase00PropertyValue $_ 'ExpectedChild'
                expected_branch = [string](Get-Phase00PropertyValue $_ 'ExpectedBranch')
                override_status = [string](Get-Phase00PropertyValue $_ 'OverrideStatus')
            }
        })
    if (($cases.name -join ',') -ne 'L1,L2,L3') {
        throw 'Selected projection requires exactly L1, L2, and L3.'
    }

    [pscustomobject][ordered]@{
        schema_version = 1
        experiment = 'E3-L'
        status = $status
        selected = $true
        attempt = $attempt
        source_identity = [ordered]@{
            path = $sourcePath.Replace('\','/')
            sha256 = $sourceHash
        }
        runtime = [ordered]@{
            version = [string](Get-Phase00PropertyValue $Transaction 'RuntimeVersion')
            sha256 = [string](Get-Phase00PropertyValue $Transaction 'RuntimeSha256')
        }
        supported_host = [string](Get-Phase00PropertyValue $Transaction 'SupportedHost')
        raw_inputs = $rawReferences
        cases = $cases
        transport = Get-Phase00PropertyValue $Transaction 'Transport'
        boundaries = Get-Phase00PropertyValue $Transaction 'Boundaries'
        oracle_statuses = Get-Phase00PropertyValue $Transaction 'OracleStatuses'
    }
}

function Test-Phase00E3LDurableContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $validatorPath = Join-Path $PSScriptRoot 'phase00-evidence.ps1'
    if (-not (Get-Command Test-Phase00E3LArtifactContract -ErrorAction SilentlyContinue)) {
        . $validatorPath
    }
    Test-Phase00E3LArtifactContract -RepositoryRoot $RepositoryRoot
}
