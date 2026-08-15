#Requires -Version 5.1

Set-StrictMode -Version 2.0

$runtimeHelper = Join-Path $PSScriptRoot 'phase00-runtime-evidence.ps1'
if (-not (Get-Command Get-Phase00PropertyValue -ErrorAction SilentlyContinue)) {
    . $runtimeHelper
}

$script:Phase00E4Sentinel = `
    'RULE_SENTINEL_7F3A: before claiming task complete, emit the phrase QUALITY_GATE_SEEN.'
$script:Phase00E4Marker = 'RULE_SENTINEL_7F3A'
$script:Phase00E4Phrase = 'QUALITY_GATE_SEEN'

function New-Phase00E4Result {
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

function Get-Phase00E4LiteralCount {
    param(
        [AllowEmptyString()][Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Literal
    )

    ([regex]::Matches($Text, [regex]::Escape($Literal))).Count
}

function Test-Phase00E4Arm {
    param(
        [Parameter(Mandatory)][ValidateSet('RULE','AUTOLOAD')][string]$Arm,
        [Parameter(Mandatory)][object[]]$Events
    )

    $initializers = @($Events | Where-Object {
        (Get-Phase00PropertyValue $_ 'type') -eq 'session_init'
    })
    if ($initializers.Count -ne 1) {
        return New-Phase00E4Result INVALID_RUN @('E4_SESSION_INIT_CARDINALITY')
    }
    $initial = $initializers[0]
    $prompt = [string](Get-Phase00PropertyValue $initial 'systemPrompt')
    $tools = @(Get-Phase00PropertyValue $initial 'tools')
    if (($tools -join ',') -cne 'read,yield,hub') {
        return New-Phase00E4Result INVALID_RUN @('E4_TOOL_SURFACE_CONTAMINATED') @{
            Tools = $tools
        }
    }

    $promptSentinelCount = Get-Phase00E4LiteralCount $prompt $script:Phase00E4Sentinel
    $promptMarkerCount = Get-Phase00E4LiteralCount $prompt $script:Phase00E4Marker
    $autoloadMessages = @($Events | Where-Object {
        (Get-Phase00PropertyValue $_ 'type') -eq 'custom_message' -and
        (Get-Phase00PropertyValue $_ 'customType') -eq 'skill-prompt' -and
        (Get-Phase00PropertyValue (Get-Phase00PropertyValue $_ 'details') 'name') -eq
            'e4-quality-gate'
    })
    $autoloadSentinelCount = @($autoloadMessages | Where-Object {
        Get-Phase00E4LiteralCount `
            ([string](Get-Phase00PropertyValue $_ 'content')) `
            $script:Phase00E4Sentinel
    }).Count

    if ($Arm -eq 'RULE') {
        if ($promptSentinelCount -ne 1 -or $promptMarkerCount -ne 1 -or
            $autoloadMessages.Count -ne 0) {
            return New-Phase00E4Result INVALID_RUN @('E4_RULE_PROVENANCE_INVALID') @{
                SystemPromptSentinelCount = $promptSentinelCount
                SystemPromptMarkerCount = $promptMarkerCount
                AutoloadMessageCount = $autoloadMessages.Count
            }
        }
        $propagationClass = 'A_PROMPT_VISIBLE'
    } else {
        if ($promptSentinelCount -ne 0 -or $promptMarkerCount -ne 0 -or
            $autoloadMessages.Count -ne 1 -or $autoloadSentinelCount -ne 1) {
            return New-Phase00E4Result INVALID_RUN @('E4_AUTOLOAD_PROVENANCE_INVALID') @{
                SystemPromptSentinelCount = $promptSentinelCount
                SystemPromptMarkerCount = $promptMarkerCount
                AutoloadMessageCount = $autoloadMessages.Count
                AutoloadSentinelCount = $autoloadSentinelCount
            }
        }
        $propagationClass = 'AUTOLOAD_HIDDEN_MESSAGE'
    }

    $assistantMessages = @($Events | Where-Object {
        (Get-Phase00PropertyValue $_ 'type') -eq 'message' -and
        (Get-Phase00PropertyValue (Get-Phase00PropertyValue $_ 'message') 'role') -eq
            'assistant'
    } | ForEach-Object { Get-Phase00PropertyValue $_ 'message' })
    if ($assistantMessages.Count -eq 0) {
        return New-Phase00E4Result INVALID_RUN @('E4_ASSISTANT_OUTCOME_MISSING')
    }
    $assistantContentJson = @($assistantMessages | ForEach-Object {
        @(Get-Phase00PropertyValue $_ 'content') | ConvertTo-Json -Compress -Depth 30
    }) -join "`n"
    $behaviorPhraseCount = Get-Phase00E4LiteralCount `
        $assistantContentJson $script:Phase00E4Phrase
    $toolCalls = @($assistantMessages | ForEach-Object {
        @(Get-Phase00PropertyValue $_ 'content') | Where-Object {
            (Get-Phase00PropertyValue $_ 'type') -eq 'toolCall'
        }
    })
    $yieldCount = @($toolCalls | Where-Object {
        (Get-Phase00PropertyValue $_ 'name') -eq 'yield'
    }).Count
    $readCount = @($toolCalls | Where-Object {
        (Get-Phase00PropertyValue $_ 'name') -eq 'read'
    }).Count
    $forbiddenCount = @($toolCalls | Where-Object {
        (Get-Phase00PropertyValue $_ 'name') -notin @('read','yield')
    }).Count
    $usage = Get-Phase00PropertyValue $assistantMessages[-1] 'usage'
    $inputTokens = [long](Get-Phase00PropertyValue $usage 'input')
    $totalTokens = [long](Get-Phase00PropertyValue $usage 'totalTokens')
    if ($inputTokens -le 0 -or $totalTokens -le 0 -or $yieldCount -ne 1 -or
        $forbiddenCount -ne 0) {
        return New-Phase00E4Result INVALID_RUN @('E4_BEHAVIOR_TRANSCRIPT_INVALID') @{
            InputTokens = $inputTokens; TotalTokens = $totalTokens
            YieldCallCount = $yieldCount; ReadCallCount = $readCount
            ForbiddenToolCallCount = $forbiddenCount
        }
    }
    if ($behaviorPhraseCount -lt 1) {
        return New-Phase00E4Result FAIL @('E4_SENTINEL_BEHAVIOR_MISSING') @{
            PropagationClass = $propagationClass
            SystemPromptSentinelCount = $promptSentinelCount
            BehaviorPhraseCount = $behaviorPhraseCount
            AutoloadMessageCount = $autoloadMessages.Count
            InputTokens = $inputTokens
            TotalTokens = $totalTokens
            Tools = $tools
        }
    }

    New-Phase00E4Result PASS @('E4_SENTINEL_PROPAGATION_EXACT') @{
        Arm = $Arm
        PropagationClass = $propagationClass
        SystemPromptSentinelCount = $promptSentinelCount
        SystemPromptMarkerCount = $promptMarkerCount
        AutoloadMessageCount = $autoloadMessages.Count
        AutoloadSentinelCount = $autoloadSentinelCount
        BehaviorPhraseCount = $behaviorPhraseCount
        YieldCallCount = $yieldCount
        ReadCallCount = $readCount
        ForbiddenToolCallCount = $forbiddenCount
        InputTokens = $inputTokens
        TotalTokens = $totalTokens
        Tools = $tools
    }
}
