#Requires -Version 5.1

Set-StrictMode -Version 2.0

$runtimeHelper = Join-Path $PSScriptRoot 'phase00-runtime-evidence.ps1'
if (-not (Get-Command Get-Phase00PropertyValue -ErrorAction SilentlyContinue)) {
    . $runtimeHelper
}

function New-Phase00E5Result {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('PASS','FAIL','INVALID_RUN','BLOCKED_ENVIRONMENT')]
        [string]$Status,
        [string[]]$Reasons = @(),
        [hashtable]$Properties = @{}
    )

    $result = [ordered]@{ Status = $Status; Reasons = @($Reasons) }
    foreach ($key in @($Properties.Keys)) { $result[$key] = $Properties[$key] }
    [pscustomobject]$result
}

function Get-Phase00E5Expectation {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('E5-A','E5-B','E5-C','E5-D','E5-E','E5-F')]
        [string]$CaseId,
        [Parameter(Mandatory)][string]$Role
    )

    $roleKey = $Role.ToLowerInvariant()
    if ($CaseId -eq 'E5-B' -and $roleKey -eq 'verifier') {
        return [pscustomobject][ordered]@{
            LspPresent = $false
            Tools = @('read','yield','hub')
            Marker = 'E5_B_VERIFIER_LSP_ABSENT'
            Cause = 'AGENT_ALLOWLIST_MISSING_CONTROL'
            Remediation = 'CONTROL_NO_REMEDIATION'
        }
    }
    if ($CaseId -eq 'E5-B') {
        return [pscustomobject][ordered]@{
            LspPresent = $true
            Tools = @('lsp','yield','hub')
            Marker = 'E5_B_{0}_LSP_OK' -f $roleKey.ToUpperInvariant()
            Cause = 'ALL_LSP_GATES_SATISFIED'
            Remediation = 'NONE'
        }
    }
    if ($CaseId -eq 'E5-E') {
        return [pscustomobject][ordered]@{
            LspPresent = $true
            Tools = @('lsp','yield','hub')
            Marker = 'E5_E_TOOL_PRESENT_NO_SERVER'
            Cause = 'LANGUAGE_SERVER_UNAVAILABLE'
            Remediation = 'INSTALL_OR_CONFIGURE_LANGUAGE_SERVER'
        }
    }

    $map = @{
        'E5-A' = @{
            Marker='E5_A_LSP_ABSENT'; Cause='TASK_ENABLE_LSP_FALSE'
            Remediation='MERGE_PROJECT_TASK_ENABLE_LSP_TRUE'
            Tools=@('yield','hub')
        }
        'E5-C' = @{
            Marker='E5_C_LSP_ABSENT'; Cause='PARENT_SESSION_LSP_DISABLED'
            Remediation='RELAUNCH_PARENT_WITH_LSP'
            Tools=@('yield','hub')
        }
        'E5-D' = @{
            Marker='E5_D_LSP_ABSENT'; Cause='AGENT_ALLOWLIST_MISSING'
            Remediation='ADD_LSP_TO_AGENT_ALLOWLIST'
            Tools=@('read','yield','hub')
        }
        'E5-F' = @{
            Marker='E5_F_LSP_ABSENT'; Cause='LSP_ENABLED_FALSE'
            Remediation='ENABLE_PROJECT_LSP_ENABLED'
            Tools=@('yield','hub')
        }
    }
    $entry = $map[$CaseId]
    [pscustomobject][ordered]@{
        LspPresent = $false
        Tools = @($entry.Tools)
        Marker = $entry.Marker
        Cause = $entry.Cause
        Remediation = $entry.Remediation
    }
}

function Test-Phase00E5Case {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('E5-A','E5-B','E5-C','E5-D','E5-E','E5-F')]
        [string]$CaseId,
        [Parameter(Mandatory)][string]$Role,
        [Parameter(Mandatory)][object[]]$Events
    )

    $expected = Get-Phase00E5Expectation $CaseId $Role
    $initializers = @($Events | Where-Object {
        (Get-Phase00PropertyValue $_ 'type') -eq 'session_init'
    })
    if ($initializers.Count -ne 1) {
        return New-Phase00E5Result INVALID_RUN @('E5_SESSION_INIT_CARDINALITY')
    }

    $tools = @(Get-Phase00PropertyValue $initializers[0] 'tools')
    $lspPresent = @($tools | Where-Object { $_ -ceq 'lsp' }).Count -eq 1
    $surfaceExact = ($tools -join ',') -ceq (@($expected.Tools) -join ',')

    $assistantMessages = @($Events | Where-Object {
        (Get-Phase00PropertyValue $_ 'type') -eq 'message' -and
        (Get-Phase00PropertyValue (Get-Phase00PropertyValue $_ 'message') 'role') -eq
            'assistant'
    } | ForEach-Object { Get-Phase00PropertyValue $_ 'message' })
    if ($assistantMessages.Count -eq 0) {
        return New-Phase00E5Result INVALID_RUN @('E5_ASSISTANT_OUTCOME_MISSING')
    }

    $toolCalls = @($assistantMessages | ForEach-Object {
        @(Get-Phase00PropertyValue $_ 'content') | Where-Object {
            (Get-Phase00PropertyValue $_ 'type') -eq 'toolCall'
        }
    })
    $lspCalls = @($toolCalls | Where-Object {
        (Get-Phase00PropertyValue $_ 'name') -eq 'lsp'
    })
    $yieldCalls = @($toolCalls | Where-Object {
        (Get-Phase00PropertyValue $_ 'name') -eq 'yield'
    })
    $assistantContentJson = @($assistantMessages | ForEach-Object {
        @(Get-Phase00PropertyValue $_ 'content') | ConvertTo-Json -Compress -Depth 30
    }) -join "`n"
    $markerCount = ([regex]::Matches(
        $assistantContentJson, [regex]::Escape([string]$expected.Marker))).Count

    $lspResults = @($Events | Where-Object {
        (Get-Phase00PropertyValue $_ 'type') -eq 'message' -and
        (Get-Phase00PropertyValue (Get-Phase00PropertyValue $_ 'message') 'role') -eq
            'toolResult' -and
        (Get-Phase00PropertyValue (Get-Phase00PropertyValue $_ 'message') 'toolName') -eq
            'lsp'
    } | ForEach-Object { Get-Phase00PropertyValue $_ 'message' })
    $lspResult = if ($lspResults.Count -eq 1) { $lspResults[0] } else { $null }
    $lspDetails = Get-Phase00PropertyValue $lspResult 'details'
    $lspResultSuccess = Get-Phase00PropertyValue $lspDetails 'success'
    $lspResultText = if ($null -eq $lspResult) { $null } else {
        @(@(Get-Phase00PropertyValue $lspResult 'content') | ForEach-Object {
            [string](Get-Phase00PropertyValue $_ 'text')
        }) -join "`n"
    }

    $firstUsage = Get-Phase00PropertyValue $assistantMessages[0] 'usage'
    $lastUsage = Get-Phase00PropertyValue $assistantMessages[-1] 'usage'
    $firstInput = [long](Get-Phase00PropertyValue $firstUsage 'input')
    $firstCache = [long](Get-Phase00PropertyValue $firstUsage 'cacheRead')
    $lastTotal = [long](Get-Phase00PropertyValue $lastUsage 'totalTokens')
    $properties = @{
        CaseId = $CaseId
        Role = $Role
        Tools = $tools
        LspPresent = $lspPresent
        LspCallCount = $lspCalls.Count
        LspResultCount = $lspResults.Count
        LspResultSuccess = $lspResultSuccess
        LspResultText = $lspResultText
        LspServerName = Get-Phase00PropertyValue $lspDetails 'serverName'
        YieldCallCount = $yieldCalls.Count
        MarkerCount = $markerCount
        Marker = $expected.Marker
        Cause = $expected.Cause
        Remediation = $expected.Remediation
        FirstTurnPromptTokens = $firstInput + $firstCache
        FinalTotalTokens = $lastTotal
    }

    if (-not $surfaceExact -or $lspPresent -ne $expected.LspPresent) {
        return New-Phase00E5Result FAIL @('E5_LSP_SURFACE_MISMATCH') $properties
    }
    if ($yieldCalls.Count -ne 1 -or $markerCount -ne 1 -or $lastTotal -le 0) {
        return New-Phase00E5Result INVALID_RUN @('E5_BEHAVIOR_TRANSCRIPT_INVALID') `
            $properties
    }

    if ($expected.LspPresent) {
        if ($lspCalls.Count -ne 1 -or $lspResults.Count -ne 1) {
            return New-Phase00E5Result FAIL @('E5_LSP_CALL_OR_RESULT_MISSING') `
                $properties
        }
        if ($CaseId -eq 'E5-E') {
            if ($lspResultSuccess -ne $false -or $lspResultText -notmatch
                '^No language server(s)? (found|configured)') {
                return New-Phase00E5Result FAIL @('E5_NO_SERVER_ERROR_SHAPE_MISMATCH') `
                    $properties
            }
        } elseif ($lspResultSuccess -ne $true -or
            [string]::IsNullOrWhiteSpace([string]$lspResultText)) {
            return New-Phase00E5Result FAIL @('E5_LSP_CALL_FAILED') $properties
        }
    } elseif ($lspCalls.Count -ne 0 -or $lspResults.Count -ne 0) {
        return New-Phase00E5Result FAIL @('E5_HIDDEN_LSP_WAS_CALLED') $properties
    }

    New-Phase00E5Result PASS @('E5_CONDITION_DISCRIMINATED') $properties
}
