#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\topic03-deepseek-routing.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    Write-Host 'FAIL [T03-DS-TEST-HELPER] Topic 03 DeepSeek routing helper is missing' -ForegroundColor Red
    exit 1
}
. $helperPath

$script:assertions = 0

function Assert-NoFailures {
    param(
        [Parameter(Mandatory)][object[]]$Results,
        [Parameter(Mandatory)][string]$Scenario
    )

    $script:assertions++
    $failures = @($Results | Where-Object Status -eq 'FAIL')
    if ($failures.Count -ne 0) {
        throw "[$Scenario] expected zero failures, got: $($failures.Code -join ', ')"
    }
}

function Assert-OnlyFailureCode {
    param(
        [Parameter(Mandatory)][object[]]$Results,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Scenario
    )

    $script:assertions++
    $failures = @($Results | Where-Object Status -eq 'FAIL')
    if ($failures.Count -ne 1 -or $failures[0].Code -ne $Code) {
        throw "[$Scenario] expected only FAIL '$Code', got: $($failures.Code -join ', ')"
    }
}

function Assert-EqualValue {
    param(
        [AllowNull()][object]$Actual,
        [AllowNull()][object]$Expected,
        [Parameter(Mandatory)][string]$Scenario
    )

    $script:assertions++
    if ($Actual -ne $Expected) {
        throw "[$Scenario] expected '$Expected', got '$Actual'"
    }
}

function New-ValidOmpModels {
    @(
        [pscustomobject]@{
            provider = 'omniroute'
            id = 'ds/deepseek-v4-flash'
            reasoning = $true
            thinking = [pscustomobject]@{
                minLevel = 'high'
                maxLevel = 'xhigh'
                mode = 'effort'
            }
            compat = [pscustomobject]@{
                supportsReasoningEffort = $true
                reasoningEffortMap = [pscustomobject]@{
                    high = 'high'
                    xhigh = 'max'
                }
            }
        },
        [pscustomobject]@{
            provider = 'omniroute'
            id = 'ds/deepseek-v4-pro'
            reasoning = $true
            thinking = [pscustomobject]@{
                minLevel = 'high'
                maxLevel = 'xhigh'
                mode = 'effort'
            }
            compat = [pscustomobject]@{
                supportsReasoningEffort = $true
                reasoningEffortMap = [pscustomobject]@{
                    high = 'high'
                    xhigh = 'max'
                }
            }
        }
    )
}

$gatewayIds = @('ds/deepseek-v4-flash', 'ds/deepseek-v4-pro')

# Break caught: a complete gateway/catalog pair must not be rejected.
$results = @(Test-Topic03DeepSeekCatalog -GatewayModelIds $gatewayIds -OmpModels (New-ValidOmpModels))
Assert-NoFailures -Results $results -Scenario 'complete catalog'

# Break caught: losing the primary gateway route must fail closed.
$results = @(Test-Topic03DeepSeekCatalog -GatewayModelIds @('ds/deepseek-v4-pro') -OmpModels (New-ValidOmpModels))
Assert-OnlyFailureCode -Results $results -Code 'T03-DS-GATEWAY-FLASH-MISSING' -Scenario 'missing Flash gateway ID'

# Break caught: losing the fallback OMP entry must not leave an unusable fallback chain.
$models = @(New-ValidOmpModels | Where-Object id -ne 'ds/deepseek-v4-pro')
$results = @(Test-Topic03DeepSeekCatalog -GatewayModelIds $gatewayIds -OmpModels $models)
Assert-OnlyFailureCode -Results $results -Code 'T03-DS-OMP-PRO-MISSING' -Scenario 'missing Pro OMP entry'

# Break caught: a non-reasoning primary cannot satisfy the approved Scout contract.
$models = @(New-ValidOmpModels)
$models[0].reasoning = $false
$results = @(Test-Topic03DeepSeekCatalog -GatewayModelIds $gatewayIds -OmpModels $models)
Assert-OnlyFailureCode -Results $results -Code 'T03-DS-FLASH-REASONING' -Scenario 'Flash reasoning disabled'

# Break caught: xhigh must map to DeepSeek max rather than a weaker provider effort.
$models = @(New-ValidOmpModels)
$models[0].compat.reasoningEffortMap.xhigh = 'high'
$results = @(Test-Topic03DeepSeekCatalog -GatewayModelIds $gatewayIds -OmpModels $models)
Assert-OnlyFailureCode -Results $results -Code 'T03-DS-EFFORT-MAP' -Scenario 'invalid xhigh effort mapping'

# Break caught: evidence states outside the closed lifecycle cannot be accepted.
$results = @(Test-Topic03DeepSeekSmokeEvidence -Evidence ([pscustomobject]@{ status = 'UNKNOWN'; model = 'Flash' }))
Assert-OnlyFailureCode -Results $results -Code 'T03-DS-EVIDENCE-STATE' -Scenario 'unknown evidence state'

# Break caught: redacted evidence must reject secret-bearing keys or values.
$results = @(Test-Topic03DeepSeekSmokeEvidence -Evidence ([pscustomobject]@{ status = 'PASS'; api_key = 'not-a-real-key' }))
Assert-OnlyFailureCode -Results $results -Code 'T03-DS-EVIDENCE-SECRET' -Scenario 'secret-bearing evidence'

# Break caught: a valid, redacted outcome must remain consumable by later validators.
$results = @(Test-Topic03DeepSeekSmokeEvidence -Evidence ([pscustomobject]@{
    status = 'ENVIRONMENT_BLOCKED'
    reason_code = 'DEEPSEEK_CREDENTIAL_MISSING'
    selector = 'omniroute/ds/deepseek-v4-flash:xhigh'
}))
Assert-NoFailures -Results $results -Scenario 'valid redacted evidence'

# Break caught: OMP may exit zero while the provider reports that DeepSeek has no credential.
$state = Get-Topic03DeepSeekSmokeState -ExitCode 0 -ExpectedSentinel 'TOPIC03_DEEPSEEK_FLASH_OK' -JsonLines @(
    '{"type":"message_end","message":{"role":"assistant","content":[],"stopReason":"error","errorMessage":"404 No active credentials for provider: deepseek"}}'
)
Assert-EqualValue -Actual $state.Status -Expected 'ENVIRONMENT_BLOCKED' -Scenario 'credential error state'
Assert-EqualValue -Actual $state.ReasonCode -Expected 'DEEPSEEK_CREDENTIAL_MISSING' -Scenario 'credential error reason'

# Break caught: only an assistant sentinel plus a real read-tool event can produce PASS.
$state = Get-Topic03DeepSeekSmokeState -ExitCode 0 -ExpectedSentinel 'TOPIC03_DEEPSEEK_FLASH_OK' -JsonLines @(
    '{"type":"tool_execution_end","toolName":"read","isError":false}',
    '{"type":"message_end","message":{"role":"assistant","content":[{"type":"text","text":"TOPIC03_DEEPSEEK_FLASH_OK"}],"stopReason":"stop"}}'
)
Assert-EqualValue -Actual $state.Status -Expected 'PASS' -Scenario 'successful smoke state'

# Break caught: echoing the sentinel in the user prompt cannot substitute for a read result.
$state = Get-Topic03DeepSeekSmokeState -ExitCode 0 -ExpectedSentinel 'TOPIC03_DEEPSEEK_FLASH_OK' -JsonLines @(
    '{"type":"message_end","message":{"role":"user","content":[{"type":"text","text":"Return TOPIC03_DEEPSEEK_FLASH_OK"}]}}',
    '{"type":"message_end","message":{"role":"assistant","content":[{"type":"text","text":"TOPIC03_DEEPSEEK_FLASH_OK"}],"stopReason":"stop"}}'
)
Assert-EqualValue -Actual $state.ReasonCode -Expected 'READ_EVENT_MISSING' -Scenario 'missing read event'

Write-Host "PASS Topic 03 DeepSeek routing tests ($script:assertions assertions)" -ForegroundColor Green
exit 0
