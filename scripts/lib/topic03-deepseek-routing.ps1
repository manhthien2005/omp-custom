#Requires -Version 5.1

Set-StrictMode -Version Latest

function New-Topic03DeepSeekValidationResult {
    param(
        [ValidateSet('PASS', 'FAIL', 'WARN')][string]$Status,
        [string]$Code,
        [string]$Message
    )

    [pscustomobject]@{
        Status = $Status
        Code = $Code
        Message = $Message
    }
}

function Get-Topic03DeepSeekProperty {
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Test-Topic03DeepSeekCatalog {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$GatewayModelIds,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$OmpModels
    )

    $results = @()
    $routes = @(
        [pscustomobject]@{
            Label = 'FLASH'
            Id = 'ds/deepseek-v4-flash'
        },
        [pscustomobject]@{
            Label = 'PRO'
            Id = 'ds/deepseek-v4-pro'
        }
    )

    foreach ($route in $routes) {
        if ($GatewayModelIds -contains $route.Id) {
            $results += New-Topic03DeepSeekValidationResult -Status 'PASS' -Code "T03-DS-GATEWAY-$($route.Label)" -Message "gateway advertises $($route.Id)"
        } else {
            $results += New-Topic03DeepSeekValidationResult -Status 'FAIL' -Code "T03-DS-GATEWAY-$($route.Label)-MISSING" -Message "gateway does not advertise $($route.Id)"
        }

        $model = @($OmpModels | Where-Object {
            (Get-Topic03DeepSeekProperty -InputObject $_ -Name 'provider') -eq 'omniroute' -and
            (Get-Topic03DeepSeekProperty -InputObject $_ -Name 'id') -eq $route.Id
        }) | Select-Object -First 1

        if ($null -eq $model) {
            $results += New-Topic03DeepSeekValidationResult -Status 'FAIL' -Code "T03-DS-OMP-$($route.Label)-MISSING" -Message "OMP catalog is missing omniroute/$($route.Id)"
            continue
        }

        $results += New-Topic03DeepSeekValidationResult -Status 'PASS' -Code "T03-DS-OMP-$($route.Label)" -Message "OMP catalog contains omniroute/$($route.Id)"

        if ((Get-Topic03DeepSeekProperty -InputObject $model -Name 'reasoning') -eq $true) {
            $results += New-Topic03DeepSeekValidationResult -Status 'PASS' -Code "T03-DS-$($route.Label)-REASONING" -Message "$($route.Id) declares reasoning support"
        } else {
            $results += New-Topic03DeepSeekValidationResult -Status 'FAIL' -Code "T03-DS-$($route.Label)-REASONING" -Message "$($route.Id) must declare reasoning=true"
        }

        $thinking = Get-Topic03DeepSeekProperty -InputObject $model -Name 'thinking'
        $rangeValid =
            (Get-Topic03DeepSeekProperty -InputObject $thinking -Name 'minLevel') -eq 'high' -and
            (Get-Topic03DeepSeekProperty -InputObject $thinking -Name 'maxLevel') -eq 'xhigh' -and
            (Get-Topic03DeepSeekProperty -InputObject $thinking -Name 'mode') -eq 'effort'
        if (-not $rangeValid) {
            $results += New-Topic03DeepSeekValidationResult -Status 'FAIL' -Code 'T03-DS-THINKING-RANGE' -Message "$($route.Id) must expose effort thinking from high through xhigh"
        }

        $compat = Get-Topic03DeepSeekProperty -InputObject $model -Name 'compat'
        $effortMap = Get-Topic03DeepSeekProperty -InputObject $compat -Name 'reasoningEffortMap'
        $effortMapValid =
            (Get-Topic03DeepSeekProperty -InputObject $compat -Name 'supportsReasoningEffort') -eq $true -and
            (Get-Topic03DeepSeekProperty -InputObject $effortMap -Name 'high') -eq 'high' -and
            (Get-Topic03DeepSeekProperty -InputObject $effortMap -Name 'xhigh') -eq 'max'
        if (-not $effortMapValid) {
            $results += New-Topic03DeepSeekValidationResult -Status 'FAIL' -Code 'T03-DS-EFFORT-MAP' -Message "$($route.Id) must map high to high and xhigh to max"
        }
    }

    return $results
}

function Test-Topic03DeepSeekSmokeEvidence {
    param([Parameter(Mandatory)][object]$Evidence)

    $results = @()
    $status = Get-Topic03DeepSeekProperty -InputObject $Evidence -Name 'status'
    if (@('PASS', 'FAIL', 'ENVIRONMENT_BLOCKED') -contains $status) {
        $results += New-Topic03DeepSeekValidationResult -Status 'PASS' -Code 'T03-DS-EVIDENCE-STATE' -Message "evidence state is $status"
    } else {
        $results += New-Topic03DeepSeekValidationResult -Status 'FAIL' -Code 'T03-DS-EVIDENCE-STATE' -Message 'evidence state must be PASS, FAIL, or ENVIRONMENT_BLOCKED'
    }

    $serialized = $Evidence | ConvertTo-Json -Depth 20 -Compress
    if ($serialized -match '(?i)(api[_-]?key|access[_-]?token|authorization|bearer\s+|secret)') {
        $results += New-Topic03DeepSeekValidationResult -Status 'FAIL' -Code 'T03-DS-EVIDENCE-SECRET' -Message 'evidence contains secret-bearing material'
    } else {
        $results += New-Topic03DeepSeekValidationResult -Status 'PASS' -Code 'T03-DS-EVIDENCE-SECRET' -Message 'evidence is redacted'
    }

    return $results
}

function Get-Topic03DeepSeekSmokeState {
    param(
        [Parameter(Mandatory)][int]$ExitCode,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$JsonLines,
        [Parameter(Mandatory)][string]$ExpectedSentinel
    )

    $events = @()
    foreach ($line in $JsonLines) {
        try {
            $events += ([string]$line | ConvertFrom-Json -ErrorAction Stop)
        } catch {
            continue
        }
    }

    $errorMessages = @()
    $assistantTexts = @()
    $readToolSeen = $false

    foreach ($event in $events) {
        $eventError = Get-Topic03DeepSeekProperty -InputObject $event -Name 'errorMessage'
        if ($null -ne $eventError) {
            $errorMessages += [string]$eventError
        }

        $messageCandidates = @()
        $message = Get-Topic03DeepSeekProperty -InputObject $event -Name 'message'
        if ($null -ne $message) {
            $messageCandidates += $message
        }
        $messages = Get-Topic03DeepSeekProperty -InputObject $event -Name 'messages'
        if ($null -ne $messages) {
            $messageCandidates += @($messages)
        }

        foreach ($candidate in $messageCandidates) {
            $candidateError = Get-Topic03DeepSeekProperty -InputObject $candidate -Name 'errorMessage'
            if ($null -ne $candidateError) {
                $errorMessages += [string]$candidateError
            }

            if ((Get-Topic03DeepSeekProperty -InputObject $candidate -Name 'role') -ne 'assistant') {
                continue
            }
            foreach ($item in @(Get-Topic03DeepSeekProperty -InputObject $candidate -Name 'content')) {
                if ((Get-Topic03DeepSeekProperty -InputObject $item -Name 'type') -eq 'text') {
                    $text = Get-Topic03DeepSeekProperty -InputObject $item -Name 'text'
                    if ($null -ne $text) {
                        $assistantTexts += [string]$text
                    }
                }

                $itemName = Get-Topic03DeepSeekProperty -InputObject $item -Name 'name'
                $itemType = [string](Get-Topic03DeepSeekProperty -InputObject $item -Name 'type')
                $itemIsError = Get-Topic03DeepSeekProperty -InputObject $item -Name 'isError'
                if ($itemName -eq 'read' -and $itemType -match '(?i)(tool.?result|tool.?execution.?end)' -and $itemIsError -ne $true) {
                    $readToolSeen = $true
                }
            }
        }

        $eventType = [string](Get-Topic03DeepSeekProperty -InputObject $event -Name 'type')
        $eventTool = Get-Topic03DeepSeekProperty -InputObject $event -Name 'toolName'
        if ($null -eq $eventTool) {
            $eventTool = Get-Topic03DeepSeekProperty -InputObject $event -Name 'name'
        }
        $eventIsError = Get-Topic03DeepSeekProperty -InputObject $event -Name 'isError'
        if ($eventTool -eq 'read' -and $eventType -match '(?i)(tool.?result|tool.?execution.?end)' -and $eventIsError -ne $true) {
            $readToolSeen = $true
        }
    }

    $allErrors = $errorMessages -join "`n"
    $sentinelSeen = ($assistantTexts -join "`n").Contains($ExpectedSentinel)
    if ($allErrors -match '(?i)No active credentials for provider:\s*deepseek') {
        return [pscustomobject]@{
            Status = 'ENVIRONMENT_BLOCKED'
            ReasonCode = 'DEEPSEEK_CREDENTIAL_MISSING'
            ReadToolSeen = $readToolSeen
            SentinelSeen = $sentinelSeen
        }
    }

    if ($ExitCode -ne 0) {
        return [pscustomobject]@{
            Status = 'FAIL'
            ReasonCode = 'OMP_EXIT_NONZERO'
            ReadToolSeen = $readToolSeen
            SentinelSeen = $sentinelSeen
        }
    }

    if ($errorMessages.Count -gt 0) {
        return [pscustomobject]@{
            Status = 'FAIL'
            ReasonCode = 'MODEL_CALL_ERROR'
            ReadToolSeen = $readToolSeen
            SentinelSeen = $sentinelSeen
        }
    }

    if (-not $readToolSeen) {
        return [pscustomobject]@{
            Status = 'FAIL'
            ReasonCode = 'READ_EVENT_MISSING'
            ReadToolSeen = $false
            SentinelSeen = $sentinelSeen
        }
    }

    if (-not $sentinelSeen) {
        return [pscustomobject]@{
            Status = 'FAIL'
            ReasonCode = 'SENTINEL_MISSING'
            ReadToolSeen = $true
            SentinelSeen = $false
        }
    }

    return [pscustomobject]@{
        Status = 'PASS'
        ReasonCode = 'NONE'
        ReadToolSeen = $true
        SentinelSeen = $true
    }
}
