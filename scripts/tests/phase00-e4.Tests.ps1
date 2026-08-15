#Requires -Version 5.1

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-e4-evidence.ps1'
if (Test-Path -LiteralPath $helperPath -PathType Leaf) { . $helperPath }
$contractHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-evidence.ps1'
if (Test-Path -LiteralPath $contractHelperPath -PathType Leaf) { . $contractHelperPath }

function New-E4ChildEvents {
    param(
        [ValidateSet('RULE','AUTOLOAD')][string]$Arm,
        [bool]$EmitPhrase = $true
    )

    $sentinel = 'RULE_SENTINEL_7F3A: before claiming task complete, emit the phrase QUALITY_GATE_SEEN.'
    $events = @(
        [pscustomobject]@{
            type = 'session_init'
            systemPrompt = if ($Arm -eq 'RULE') { "prefix`n$sentinel`nsuffix" } else { 'prefix suffix' }
            task = 'Complete the bounded probe.'
            tools = @('read','yield','hub')
            agent = 'phase00-e4-worker'
            readOnly = $true
        }
    )
    if ($Arm -eq 'AUTOLOAD') {
        $events += [pscustomobject]@{
            type = 'custom_message'; customType = 'skill-prompt'
            content = $sentinel; display = $false; attribution = 'user'
            details = [pscustomobject]@{ name = 'e4-quality-gate' }
        }
    }
    $phrase = if ($EmitPhrase) { 'QUALITY_GATE_SEEN' } else { 'DONE' }
    $events += [pscustomobject]@{
        type = 'message'
        message = [pscustomobject]@{
            role = 'assistant'
            content = @([pscustomobject]@{
                type = 'toolCall'; name = 'yield'
                arguments = [pscustomobject]@{ result = "{`"data`":{`"completion`":`"$phrase`"}}" }
            })
            usage = [pscustomobject]@{ input = 1200; totalTokens = 1250 }
        }
    }
    @($events)
}

Describe 'E4 rule sentinel oracle' {
    It 'loads the focused evidence helper' {
        (Get-Command Test-Phase00E4Arm -ErrorAction SilentlyContinue) |
            Should Not BeNullOrEmpty
    }

    It 'classifies prompt-visible rule forwarding as A' {
        $result = Test-Phase00E4Arm -Arm RULE `
            -Events (New-E4ChildEvents RULE)
        $result.Status | Should Be 'PASS'
        $result.PropagationClass | Should Be 'A_PROMPT_VISIBLE'
        $result.SystemPromptSentinelCount | Should Be 1
        $result.BehaviorPhraseCount | Should Be 1
        $result.AutoloadMessageCount | Should Be 0
        $result.InputTokens | Should Be 1200
    }

    It 'separates autoload delivery from system-prompt forwarding' {
        $result = Test-Phase00E4Arm -Arm AUTOLOAD `
            -Events (New-E4ChildEvents AUTOLOAD)
        $result.Status | Should Be 'PASS'
        $result.PropagationClass | Should Be 'AUTOLOAD_HIDDEN_MESSAGE'
        $result.SystemPromptSentinelCount | Should Be 0
        $result.BehaviorPhraseCount | Should Be 1
        $result.AutoloadMessageCount | Should Be 1
    }

    It 'allows declared read calls while still requiring exactly one terminal yield' {
        $events = [System.Collections.Generic.List[object]]::new()
        foreach ($event in @(New-E4ChildEvents RULE)) { $events.Add($event) }
        $events.Insert(1, [pscustomobject]@{
            type = 'message'
            message = [pscustomobject]@{
                role = 'assistant'
                content = @([pscustomobject]@{
                    type = 'toolCall'; name = 'read'
                    arguments = [pscustomobject]@{ path = 'prompt.md' }
                })
                usage = [pscustomobject]@{ input = 1100; totalTokens = 1150 }
            }
        })
        $result = Test-Phase00E4Arm -Arm RULE -Events @($events)
        $result.Status | Should Be 'PASS'
        $result.ReadCallCount | Should Be 1
        $result.ForbiddenToolCallCount | Should Be 0
    }

    It 'counts behavior only from emitted content and ignores context snapshots' {
        $events = @(New-E4ChildEvents RULE)
        $assistant = @($events | Where-Object type -eq 'message')[0].message
        $assistant | Add-Member -NotePropertyName contextSnapshot `
            -NotePropertyValue 'standing rule mentions QUALITY_GATE_SEEN'
        $result = Test-Phase00E4Arm -Arm RULE -Events $events
        $result.Status | Should Be 'PASS'
        $result.BehaviorPhraseCount | Should Be 1
    }

    It 'accepts repeated visible compliance while requiring one terminal yield' {
        $events = @(New-E4ChildEvents RULE)
        $assistant = @($events | Where-Object type -eq 'message')[0].message
        $assistant.content = @(
            [pscustomobject]@{ type = 'text'; text = 'Observed QUALITY_GATE_SEEN.' },
            $assistant.content[0]
        )
        $result = Test-Phase00E4Arm -Arm RULE -Events $events
        $result.Status | Should Be 'PASS'
        $result.BehaviorPhraseCount | Should Be 2
        $result.YieldCallCount | Should Be 1
    }

    It 'fails missing behavior, widened tools, and duplicate sentinels' {
        (Test-Phase00E4Arm -Arm RULE `
            -Events (New-E4ChildEvents RULE -EmitPhrase $false)).Status |
            Should Be 'FAIL'

        $widened = @(New-E4ChildEvents RULE)
        $widened[0].tools += 'bash'
        (Test-Phase00E4Arm -Arm RULE -Events $widened).Status |
            Should Be 'INVALID_RUN'

        $duplicated = @(New-E4ChildEvents RULE)
        $duplicated[0].systemPrompt += "`nRULE_SENTINEL_7F3A"
        (Test-Phase00E4Arm -Arm RULE -Events $duplicated).Status |
            Should Be 'INVALID_RUN'
    }

    It 'preserves direct CLI parameters across dependency loading' {
        $runner = Join-Path $repositoryRoot 'scripts\run-phase00-e4.ps1'
        $missing = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e4-missing-{0}.exe" -f [guid]::NewGuid().ToString('N'))
        . $runner -Attempt 17 -Model 'omniroute/oc/mimo-v2.5-free' `
            -OmpExecutable $missing
        $script:Phase00E4CliAttempt | Should Be 17
        $script:Phase00E4CliModel | Should Be 'omniroute/oc/mimo-v2.5-free'
        $script:Phase00E4CliOmpExecutable | Should Be $missing
    }

    It 'uses the platform path-list separator exposed by System.IO.Path' {
        $runner = Get-Content -LiteralPath (Join-Path $repositoryRoot `
            'scripts\run-phase00-e4.ps1') -Raw -Encoding UTF8
        $runner | Should Match '\[IO\.Path\]::PathSeparator\b'
        $runner | Should Not Match '\[IO\.Path\]::PathSeparatorChar\b'
    }
}

Describe 'E4 terminal artifact contract' {
    It 'exposes a production validator and accepts the selected correction' {
        (Get-Command Test-Phase00E4ArtifactContract -ErrorAction SilentlyContinue) |
            Should Not BeNullOrEmpty
        $results = @(Test-Phase00E4ArtifactContract -RepositoryRoot $repositoryRoot)
        @($results | Where-Object Status -eq 'FAIL').Count | Should Be 0
        @($results | Where-Object Status -eq 'PASS').Count | Should BeGreaterThan 0
    }
}
