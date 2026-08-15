#Requires -Version 5.1

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-runtime-evidence.ps1'
$runnerPath = Join-Path $repositoryRoot 'scripts\run-phase00-e3j-e3k.ps1'
$e3jFixture = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-J\fixture'
$e3kFixture = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-K\fixture'
$script:helperLoaded = $false
$script:runnerLoaded = $false

if (Test-Path -LiteralPath $helperPath -PathType Leaf) {
    . $helperPath
    $script:helperLoaded = $true
}
if (Test-Path -LiteralPath $runnerPath -PathType Leaf) {
    . $runnerPath
    $script:runnerLoaded = $true
}

function Assert-RuntimeHelperLoaded {
    $script:helperLoaded | Should Be $true
}

function Test-Throws([scriptblock]$Action) {
    try {
        $null = & $Action
        return $false
    } catch {
        return $true
    }
}

function New-ProbeOutput([int]$Index, [long]$Start, [long]$End) {
    [ordered]@{
        probe = 'phase00-timing-v1'
        index = $Index
        started_at_ms = $Start
        ended_at_ms = $End
    } | ConvertTo-Json -Compress
}

function New-TaskResult([object[]]$Results, [string]$Text = 'completed', [object[]]$Progress = @(), $Async = $null) {
    $details = [ordered]@{
        projectAgentsDir = $null
        results = @($Results)
        totalDurationMs = 3000
        progress = @($Progress)
    }
    if ($null -ne $Async) { $details.async = $Async }
    [ordered]@{
        content = @([ordered]@{ type = 'text'; text = $Text })
        details = $details
    }
}

function New-TaskEnd([string]$Id, $Result) {
    [pscustomobject][ordered]@{
        type = 'tool_execution_end'
        toolCallId = $Id
        toolName = 'task'
        result = $Result
        isError = $false
    }
}

function New-TaskStart([string]$Id, $InputArgs) {
    [pscustomobject][ordered]@{
        type = 'tool_execution_start'
        toolCallId = $Id
        toolName = 'task'
        args = $InputArgs
    }
}

function New-J1Events {
    $results = @(
        [ordered]@{ index = 0; id = 'worker-0'; exitCode = 0; output = (New-ProbeOutput 0 1000 4000) },
        [ordered]@{ index = 1; id = 'worker-1'; exitCode = 0; output = (New-ProbeOutput 1 1100 6000) },
        [ordered]@{ index = 2; id = 'worker-2'; exitCode = 0; output = (New-ProbeOutput 2 1200 3000) }
    )
    @(
        (New-TaskStart 'j1-task' ([ordered]@{
            context = 'phase00 probe'
            tasks = @(
                [ordered]@{ name = 'worker-0'; agent = 'phase00-blocking-probe'; task = 'index=0'; isolated = $true },
                [ordered]@{ name = 'worker-1'; agent = 'phase00-blocking-probe'; task = 'index=1'; isolated = $true },
                [ordered]@{ name = 'worker-2'; agent = 'phase00-blocking-probe'; task = 'index=2'; isolated = $true }
            )
        })),
        (New-TaskEnd 'j1-task' (New-TaskResult $results))
    )
}

function New-J2Events {
    $results = @(
        [ordered]@{ index = 0; id = 'control-0'; exitCode = 0; output = (New-ProbeOutput 0 1000 3000) },
        [ordered]@{ index = 1; id = 'control-1'; exitCode = 0; output = (New-ProbeOutput 1 1100 3100) }
    )
    $progress = @(
        [ordered]@{ index = 0; id = 'control-0'; status = 'completed' },
        [ordered]@{ index = 1; id = 'control-1'; status = 'completed' },
        [ordered]@{ index = 2; id = 'control-2'; status = 'running' }
    )
    @(
        (New-TaskStart 'j2-task' ([ordered]@{
            context = 'phase00 control'
            tasks = @(
                [ordered]@{ name = 'control-0'; agent = 'phase00-blocking-probe'; task = 'index=0'; isolated = $true },
                [ordered]@{ name = 'control-1'; agent = 'phase00-blocking-probe'; task = 'index=1'; isolated = $true },
                [ordered]@{ name = 'control-2'; agent = 'phase00-background-probe'; task = 'index=2'; isolated = $true }
            )
        })),
        (New-TaskEnd 'j2-task' (New-TaskResult $results 'Spawned agent `control-2` (job `control-2`).' $progress ([ordered]@{ state = 'running'; jobId = 'control-2'; type = 'task' })))
    )
}

function New-J3Events {
    $verifier = @([ordered]@{ index = 0; id = 'verifier'; exitCode = 0; output = (New-ProbeOutput 0 1000 2000) })
    $reviewer = @([ordered]@{ index = 0; id = 'reviewer'; exitCode = 0; output = (New-ProbeOutput 1 3000 4000) })
    @(
        (New-TaskStart 'verify-task' ([ordered]@{ context = 'Verifier barrier'; tasks = @([ordered]@{ name = 'verifier'; agent = 'phase00-blocking-probe'; task = 'stage=verifier'; isolated = $true }) })),
        (New-TaskEnd 'verify-task' (New-TaskResult $verifier)),
        (New-TaskStart 'review-task' ([ordered]@{ context = 'Reviewer barrier'; tasks = @([ordered]@{ name = 'reviewer'; agent = 'phase00-blocking-probe'; task = 'stage=reviewer'; isolated = $true }) })),
        (New-TaskEnd 'review-task' (New-TaskResult $reviewer)),
        [pscustomobject][ordered]@{ type = 'message_start'; message = [ordered]@{ role = 'assistant'; content = @() } }
    )
}

function New-K1Events {
    $attestation = '{"probe":"phase00-task-wire-v1","top_level_keys":["name","agent","task","outputSchema","schemaMode"],"has_task":true,"has_tasks":false,"has_context":false,"decision":"SEQUENTIAL_FALLBACK"}'
    @(
        [pscustomobject][ordered]@{ type = 'tool_execution_start'; toolCallId = 'wire'; toolName = 'bash'; args = [ordered]@{ command = 'Write-Output schema-attestation' } },
        [pscustomobject][ordered]@{ type = 'tool_execution_end'; toolCallId = 'wire'; toolName = 'bash'; result = [ordered]@{ content = @([ordered]@{ type = 'text'; text = "$attestation`n`nWall time: 0.28 seconds" }) }; isError = $false },
        (New-TaskStart 'flat-0' ([ordered]@{ name = 'flat-0'; agent = 'phase00-blocking-probe'; task = 'index=0' })),
        (New-TaskEnd 'flat-0' (New-TaskResult @([ordered]@{ index = 0; id = 'flat-0'; exitCode = 0; output = (New-ProbeOutput 0 1000 2000) }))),
        (New-TaskStart 'flat-1' ([ordered]@{ name = 'flat-1'; agent = 'phase00-blocking-probe'; task = 'index=1' })),
        (New-TaskEnd 'flat-1' (New-TaskResult @([ordered]@{ index = 0; id = 'flat-1'; exitCode = 0; output = (New-ProbeOutput 1 3000 4000) })))
    )
}

Describe 'Phase 00 E3-J/E3-K runtime surface' {
    It 'provides the runtime evidence helper and runner' {
        Test-Path -LiteralPath $helperPath -PathType Leaf | Should Be $true
        Test-Path -LiteralPath $runnerPath -PathType Leaf | Should Be $true
    }

    It 'builds an isolated JSON-mode OMP command without profile or live-home flags' {
        $script:runnerLoaded | Should Be $true
        $args = @(Get-Phase00OmpArguments -CaseId J1 -FixtureRoot 'C:\Temp\phase00-fixture' -SessionDir 'C:\Temp\phase00-fixture\sessions' -Model 'omniroute/codex/gpt-5.6-sol-high' -Prompt 'probe prompt')
        ($args -contains '--mode') | Should Be $true
        ($args -contains 'json') | Should Be $true
        ($args -contains '--session-dir') | Should Be $true
        ($args -contains '--config') | Should Be $true
        ($args -contains '--no-extensions') | Should Be $true
        ($args -contains '--no-skills') | Should Be $true
        ($args -contains '--no-rules') | Should Be $true
        ($args -contains '--approval-mode') | Should Be $true
        ($args -contains 'yolo') | Should Be $true
        ($args -contains '--profile') | Should Be $false
        ($args -contains '--no-session') | Should Be $false
        ($args -contains 'C:\Users\MrThien\.omp\agent') | Should Be $false
        $args[-1] | Should Be 'probe prompt'
    }

    It 'builds a process-local OMP agent-directory override' {
        $script:runnerLoaded | Should Be $true
        $environment = Get-Phase00OmpEnvironment -AgentDirectory 'C:\Temp\phase00-agent-home'
        $environment.PI_CODING_AGENT_DIR | Should Be 'C:\Temp\phase00-agent-home'
        $environment.Keys.Count | Should Be 1
    }

    It 'fingerprints live-home metadata without retaining file contents' {
        $script:runnerLoaded | Should Be $true
        (Get-Command Get-Phase00DirectoryMetadataSnapshot -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        (Get-Command Compare-Phase00DirectoryMetadataSnapshot -ErrorAction SilentlyContinue) -ne $null | Should Be $true

        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("omp-phase00-metadata-{0}" -f [guid]::NewGuid().ToString('N'))
        try {
            New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
            $probePath = Join-Path $tempRoot 'agent.db-wal'
            [System.IO.File]::WriteAllText($probePath, 'credential-shaped-test-content', [System.Text.UTF8Encoding]::new($false))
            $before = Get-Phase00DirectoryMetadataSnapshot -Path $tempRoot
            [System.IO.File]::AppendAllText($probePath, '-changed', [System.Text.UTF8Encoding]::new($false))
            $after = Get-Phase00DirectoryMetadataSnapshot -Path $tempRoot
            $comparison = Compare-Phase00DirectoryMetadataSnapshot -Before $before -After $after

            $before.FileCount | Should Be 1
            $before.PSObject.Properties.Name -contains 'Contents' | Should Be $false
            $before.Entries[0].PSObject.Properties.Name -contains 'Content' | Should Be $false
            $comparison.ChangedCount | Should Be 1
            @($comparison.ChangedPaths)[0] | Should Be 'agent.db-wal'
            $comparison.BeforeSha256 -eq $comparison.AfterSha256 | Should Be $false
        } finally {
            if (Test-Path -LiteralPath $tempRoot) {
                Remove-Phase00DisposableDirectory -Path $tempRoot
            }
        }
    }

    It 'retries and removes only a verified disposable temp directory' {
        $script:runnerLoaded | Should Be $true
        $path = Join-Path ([System.IO.Path]::GetTempPath()) ("omp-phase00-cleanup-test-{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Remove-Phase00DisposableDirectory -Path $path
        Test-Path -LiteralPath $path | Should Be $false
    }

    It 'provides both durable fixture roots' {
        Test-Path -LiteralPath $e3jFixture -PathType Container | Should Be $true
        Test-Path -LiteralPath $e3kFixture -PathType Container | Should Be $true
    }

    It 'provides a non-secret process-local OmniRoute model catalog' {
        $catalogPath = Join-Path $repositoryRoot 'docs\evidence\phase-00\environment\runtime-models.yml'
        Test-Path -LiteralPath $catalogPath -PathType Leaf | Should Be $true
        $content = Get-Content -Raw -LiteralPath $catalogPath -Encoding UTF8
        ($content -match '(?m)^\s*baseUrl:\s+http://127\.0\.0\.1:20128/v1\s*$') | Should Be $true
        ($content -match '(?m)^\s*apiKey:\s+OMNIROUTE_API_KEY\s*$') | Should Be $true
        ($content -match '(?m)^\s*- id:\s+codex/gpt-5\.6-sol-high\s*$') | Should Be $true
        ($content -match '(?i)(sk-[A-Za-z0-9]|Bearer\s+[A-Za-z0-9])') | Should Be $false
    }

    It 'exports the required parser and analyzers' {
        Assert-RuntimeHelperLoaded
        foreach ($name in @(
            'Read-Phase00JsonLines','Get-Phase00TaskEventPairs','Get-Phase00ProbeTimings',
            'Test-Phase00IntervalsOverlap','Get-Phase00CompletionOrder','Test-Phase00J1Evidence',
            'Test-Phase00J2Evidence','Test-Phase00J3Evidence','Test-Phase00K1Evidence',
            'Get-Phase00TerminalModelFailure','Protect-Phase00EvidenceText',
            'Test-Phase00RuntimeFixtureContract'
        )) {
            (Get-Command $name -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        }
    }
}

Describe 'Fail-closed JSONL and timing primitives' {
    It 'parses one object per non-empty JSONL line' {
        Assert-RuntimeHelperLoaded
        $path = Join-Path ([System.IO.Path]::GetTempPath()) ("phase00-jsonl-{0}.jsonl" -f [guid]::NewGuid().ToString('N'))
        try {
            Set-Content -LiteralPath $path -Encoding UTF8 -Value @('{"type":"agent_start"}', '', '{"type":"agent_end"}')
            $events = @(Read-Phase00JsonLines -Path $path)
            $events.Count | Should Be 2
            $events[0].type | Should Be 'agent_start'
            $events[1].type | Should Be 'agent_end'
        } finally { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue }
    }

    It 'rejects a malformed or truncated JSONL line' {
        Assert-RuntimeHelperLoaded
        $path = Join-Path ([System.IO.Path]::GetTempPath()) ("phase00-jsonl-{0}.jsonl" -f [guid]::NewGuid().ToString('N'))
        try {
            Set-Content -LiteralPath $path -Encoding UTF8 -Value @('{"type":"agent_start"}', '{"type":')
            (Test-Throws { Read-Phase00JsonLines -Path $path }) | Should Be $true
        } finally { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue }
    }

    It 'pairs task start and end events by toolCallId' {
        Assert-RuntimeHelperLoaded
        $pairs = @(Get-Phase00TaskEventPairs -Events (New-J1Events))
        $pairs.Count | Should Be 1
        $pairs[0].ToolCallId | Should Be 'j1-task'
        @($pairs[0].Start.args.tasks).Count | Should Be 3
        $pairs[0].End.result.details.results.Count | Should Be 3
    }

    It 'rejects an unpaired task event' {
        Assert-RuntimeHelperLoaded
        (Test-Throws { Get-Phase00TaskEventPairs -Events @((New-J1Events)[0]) }) | Should Be $true
    }

    It 'extracts only discriminated probe timing payloads' {
        Assert-RuntimeHelperLoaded
        $pairs = @(Get-Phase00TaskEventPairs -Events (New-J1Events))
        $timings = @(Get-Phase00ProbeTimings -TaskResult $pairs[0].End.result)
        $timings.Count | Should Be 3
        @($timings.Index) -join ',' | Should Be '0,1,2'
    }

    It 'rejects prose that merely resembles a timing result' {
        Assert-RuntimeHelperLoaded
        $result = New-TaskResult @([ordered]@{ index = 0; id = 'fake'; exitCode = 0; output = 'worker 0 ran from 1000 to 2000' })
        (Test-Throws { Get-Phase00ProbeTimings -TaskResult $result }) | Should Be $true
    }

    It 'calculates strict interval overlap' {
        Assert-RuntimeHelperLoaded
        (Test-Phase00IntervalsOverlap -First ([pscustomobject]@{ StartedAtMs = 1000; EndedAtMs = 3000 }) -Second ([pscustomobject]@{ StartedAtMs = 2000; EndedAtMs = 4000 })) | Should Be $true
        (Test-Phase00IntervalsOverlap -First ([pscustomobject]@{ StartedAtMs = 1000; EndedAtMs = 2000 }) -Second ([pscustomobject]@{ StartedAtMs = 2000; EndedAtMs = 4000 })) | Should Be $false
    }

    It 'calculates completion order from observed end timestamps' {
        Assert-RuntimeHelperLoaded
        $pairs = @(Get-Phase00TaskEventPairs -Events (New-J1Events))
        $timings = @(Get-Phase00ProbeTimings -TaskResult $pairs[0].End.result)
        @(Get-Phase00CompletionOrder -Timings $timings) -join ',' | Should Be '2,0,1'
    }

    It 'classifies a terminal provider connection error even when the process exits zero' {
        Assert-RuntimeHelperLoaded
        $events = @(
            [pscustomobject][ordered]@{
                type = 'message_end'
                message = [ordered]@{
                    role = 'assistant'
                    stopReason = 'error'
                    provider = 'omniroute'
                    model = 'codex/gpt-5.6-sol-high'
                    errorMessage = 'Unable to connect. Is the computer able to access the url?'
                }
            },
            [pscustomobject][ordered]@{
                type = 'agent_end'
                messages = @([ordered]@{
                    role = 'assistant'
                    stopReason = 'error'
                    provider = 'omniroute'
                    model = 'codex/gpt-5.6-sol-high'
                    errorMessage = 'Unable to connect. Is the computer able to access the url?'
                })
                isTerminal = $true
            }
        )
        $failure = Get-Phase00TerminalModelFailure -Events $events
        $failure.IsEnvironmentBlock | Should Be $true
        $failure.Code | Should Be 'P00-RUNTIME-PROVIDER-CONNECTION'
    }
}

Describe 'E3-J adjudication' {
    It 'passes J1 only with a blocking isolated batch, stable results, completion skew, and overlap' {
        Assert-RuntimeHelperLoaded
        $analysis = Test-Phase00J1Evidence -Events (New-J1Events)
        $analysis.Status | Should Be 'PASS'
        $analysis.ResultOrder -join ',' | Should Be '0,1,2'
        $analysis.CompletionOrder -join ',' | Should Be '2,0,1'
        @($analysis.OverlapPairs).Count -gt 0 | Should Be $true
    }

    It 'invalidates J1 when result indexes are missing' {
        Assert-RuntimeHelperLoaded
        $events = New-J1Events
        $events[1].result.details.results = @($events[1].result.details.results | Select-Object -First 2)
        (Test-Phase00J1Evidence -Events $events).Status | Should Be 'INVALID_RUN'
    }

    It 'fails J1 when timing intervals do not overlap' {
        Assert-RuntimeHelperLoaded
        $events = New-J1Events
        $events[1].result.details.results[0].output = New-ProbeOutput 0 1000 2000
        $events[1].result.details.results[1].output = New-ProbeOutput 1 4000 6000
        $events[1].result.details.results[2].output = New-ProbeOutput 2 2500 3000
        (Test-Phase00J1Evidence -Events $events).Status | Should Be 'FAIL'
    }

    It 'passes the missing-blocking control only when the detached result is absent and observable' {
        Assert-RuntimeHelperLoaded
        $analysis = Test-Phase00J2Evidence -Events (New-J2Events)
        $analysis.Status | Should Be 'PASS'
        $analysis.InlineResultIndexes -join ',' | Should Be '0,1'
        $analysis.DetachedIndex | Should Be 2
    }

    It 'invalidates the control when all three results are inline' {
        Assert-RuntimeHelperLoaded
        $events = New-J2Events
        $events[1].result.details.results += [ordered]@{ index = 2; id = 'control-2'; exitCode = 0; output = (New-ProbeOutput 2 1200 9000) }
        (Test-Phase00J2Evidence -Events $events).Status | Should Be 'INVALID_RUN'
    }

    It 'passes stage barriers only when verifier, reviewer, and final report are ordered' {
        Assert-RuntimeHelperLoaded
        (Test-Phase00J3Evidence -Events (New-J3Events)).Status | Should Be 'PASS'
    }

    It 'fails a reviewer dispatch that occurs before verifier completion' {
        Assert-RuntimeHelperLoaded
        $events = New-J3Events
        $reordered = @($events[0], $events[2], $events[1], $events[3], $events[4])
        (Test-Phase00J3Evidence -Events $reordered).Status | Should Be 'FAIL'
    }
}

Describe 'E3-K adjudication' {
    It 'passes a pre-dispatch flat-wire attestation and two sequential task calls' {
        Assert-RuntimeHelperLoaded
        $analysis = Test-Phase00K1Evidence -Events (New-K1Events)
        $analysis.Status | Should Be 'PASS'
        $analysis.TaskCallCount | Should Be 2
        $analysis.SequentialFallback | Should Be $true
    }

    It 'rejects any tasks array in a task.batch=false runtime call' {
        Assert-RuntimeHelperLoaded
        $events = New-K1Events
        $events[2].args = [ordered]@{ context = 'bad'; tasks = @([ordered]@{ task = 'bad' }) }
        (Test-Phase00K1Evidence -Events $events).Status | Should Be 'FAIL'
    }

    It 'rejects an attestation emitted after the first dispatch' {
        Assert-RuntimeHelperLoaded
        $events = New-K1Events
        $reordered = @($events[2], $events[0], $events[1], $events[3], $events[4], $events[5])
        (Test-Phase00K1Evidence -Events $reordered).Status | Should Be 'FAIL'
    }
}

Describe 'Fixture and sanitization controls' {
    It 'executes every timing assignment without shell-variable interpolation' {
        $promptPaths = @(
            (Join-Path $e3jFixture 'prompts\J1-blocking-batch.md'),
            (Join-Path $e3jFixture 'prompts\J2-missing-blocking-control.md'),
            (Join-Path $e3jFixture 'prompts\J3-stage-barriers.md'),
            (Join-Path $e3kFixture 'prompts\K1-flat-wire-fallback.md')
        )
        $commands = @($promptPaths | ForEach-Object {
            $text = Get-Content -Raw -LiteralPath $_ -Encoding UTF8
            @([regex]::Matches($text, '(?s)<command>\s*(.*?)\s*</command>') | ForEach-Object { $_.Groups[1].Value.Trim() })
        })
        $expectedIndexes = @(0,1,2,0,1,2,0,1,0,1)
        $commands.Count | Should Be 10

        for ($i = 0; $i -lt $commands.Count; $i++) {
            $command = $commands[$i]
            ($command -notmatch '\$') | Should Be $true
            $python = [regex]::Match($command, '^python -c "(.*)"$')
            $python.Success | Should Be $true
            if ($python.Success) {
                $fastPayload = $python.Groups[1].Value -replace 'time\.sleep\([0-9]+\)', 'time.sleep(0)'
                $stdout = @(& python -c $fastPayload 2>&1)
                $LASTEXITCODE | Should Be 0
                $result = ($stdout -join "`n") | ConvertFrom-Json
                $result.probe | Should Be 'phase00-timing-v1'
                [int]$result.index | Should Be $expectedIndexes[$i]
                ([long]$result.ended_at_ms -ge [long]$result.started_at_ms) | Should Be $true
            }
        }
    }

    It 'accepts the canonical E3-J and E3-K fixtures' {
        Assert-RuntimeHelperLoaded
        @(Test-Phase00RuntimeFixtureContract -RepositoryRoot $repositoryRoot | Where-Object { -not $_.Passed }).Count | Should Be 0
    }

    It 'redacts exact repository and disposable roots' {
        Assert-RuntimeHelperLoaded
        $tempRoot = 'C:\Temp\omp-phase00-run-abc'
        $text = "repo=$repositoryRoot temp=$tempRoot"
        $safe = Protect-Phase00EvidenceText -Text $text -RepositoryRoot $repositoryRoot -DisposableRoot $tempRoot
        $safe.Contains($repositoryRoot) | Should Be $false
        $safe.Contains($tempRoot) | Should Be $false
        $safe.Contains('<REPO_ROOT>') | Should Be $true
        $safe.Contains('<DISPOSABLE_ROOT>') | Should Be $true
    }

    It 'redacts JSON-escaped Windows path variants' {
        Assert-RuntimeHelperLoaded
        $tempRoot = 'C:\Temp\omp-phase00-run-abc'
        $escapedRepo = $repositoryRoot.Replace('\', '\\')
        $escapedTemp = $tempRoot.Replace('\', '\\')
        $safe = Protect-Phase00EvidenceText -Text "repo=$escapedRepo temp=$escapedTemp" -RepositoryRoot $repositoryRoot -DisposableRoot $tempRoot
        $safe.Contains($escapedRepo) | Should Be $false
        $safe.Contains($escapedTemp) | Should Be $false
    }

    It 'rejects credential-shaped surviving content' {
        Assert-RuntimeHelperLoaded
        (Test-Throws { Protect-Phase00EvidenceText -Text 'OPENAI_API_KEY=secret-value' -RepositoryRoot $repositoryRoot -DisposableRoot 'C:\Temp\x' }) | Should Be $true
    }

    It 'redacts a standalone credential variable name without treating it as a secret value' {
        Assert-RuntimeHelperLoaded
        $safe = Protect-Phase00EvidenceText -Text 'Set OMNIROUTE_API_KEY in the environment.' -RepositoryRoot $repositoryRoot -DisposableRoot 'C:\Temp\x'
        $safe.Contains('OMNIROUTE_API_KEY') | Should Be $false
        $safe.Contains('<CREDENTIAL_VARIABLE>') | Should Be $true
    }

    It 'records complete E3-J PASS evidence before making E3-K eligible' {
        $j1Path = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-J\J1.yml'
        $j2Path = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-J\J2.yml'
        $j3Path = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-J\J3.yml'
        $conclusionPath = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-J\conclusion.yml'
        $diagnosticPath = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-J\environment-resume-diagnostic.yml'
        $j1Text = Get-Content -Raw -LiteralPath $j1Path -Encoding UTF8
        $j2Text = Get-Content -Raw -LiteralPath $j2Path -Encoding UTF8
        $j3Text = Get-Content -Raw -LiteralPath $j3Path -Encoding UTF8
        $conclusionText = Get-Content -Raw -LiteralPath $conclusionPath -Encoding UTF8
        $diagnosticText = Get-Content -Raw -LiteralPath $diagnosticPath -Encoding UTF8
        ($j1Text -match '(?m)^status: PASS\s*$') | Should Be $true
        ($j1Text -match '(?m)^  completion_order: \[2, 0, 1\]\s*$') | Should Be $true
        ($j1Text -match '(?m)^  result_order: \[0, 1, 2\]\s*$') | Should Be $true
        ($j2Text -match '(?m)^status: PASS\s*$') | Should Be $true
        ($j2Text -match '(?m)^  inline_result_indexes: \[0, 1\]\s*$') | Should Be $true
        ($j2Text -match '(?m)^  detached_index: 2\s*$') | Should Be $true
        ($j3Text -match '(?m)^status: PASS\s*$') | Should Be $true
        ($j3Text -match '(?m)^  barrier_order: \[verifier_end, reviewer_start, reviewer_end, final_message\]\s*$') | Should Be $true
        ($conclusionText -match '(?m)^status: PASS\s*$') | Should Be $true
        ($conclusionText -match '(?m)^  J1: PASS\s*$') | Should Be $true
        ($conclusionText -match '(?m)^  J2: PASS\s*$') | Should Be $true
        ($conclusionText -match '(?m)^  J3: PASS\s*$') | Should Be $true
        ($conclusionText -match '(?m)^  E3-K: ELIGIBLE\s*$') | Should Be $true
        ($conclusionText -match '(?m)^  parallel_mode: DISABLED\s*$') | Should Be $true
        ($diagnosticText -match '(?m)^  test_status: expired\s*$') | Should Be $true
        ($diagnosticText -match '(?m)^  final_test_status: active\s*$') | Should Be $true
        ($diagnosticText -match '(?m)^  credential_values_persisted_to_repository: false\s*$') | Should Be $true
    }

    It 'records complete E3-K PASS evidence while keeping parallel mode disabled' {
        $k1Path = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-K\K1.yml'
        $conclusionPath = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-K\conclusion.yml'
        $manifestPath = Join-Path $repositoryRoot 'docs\evidence\phase-00\manifest.yml'
        (Test-Path -LiteralPath $k1Path -PathType Leaf) | Should Be $true
        (Test-Path -LiteralPath $conclusionPath -PathType Leaf) | Should Be $true
        $k1Text = Get-Content -Raw -LiteralPath $k1Path -Encoding UTF8
        $conclusionText = Get-Content -Raw -LiteralPath $conclusionPath -Encoding UTF8
        $manifestText = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8
        ($k1Text -match '(?m)^status: PASS\s*$') | Should Be $true
        ($k1Text -match '(?m)^  selected_attempt: 3\s*$') | Should Be $true
        ($k1Text -match '(?m)^  preflight_before_dispatch: true\s*$') | Should Be $true
        ($k1Text -match '(?m)^  sequential_fallback: true\s*$') | Should Be $true
        ($k1Text -match '(?m)^  actual_task_calls_use_flat_task: true\s*$') | Should Be $true
        ($conclusionText -match '(?m)^status: PASS\s*$') | Should Be $true
        ($conclusionText -match '(?m)^  K1: PASS\s*$') | Should Be $true
        ($conclusionText -match '(?m)^  parallel_mode: DISABLED\s*$') | Should Be $true
        ($manifestText -match '(?ms)^  - id: E3-K\s+kind: experiment\s+state: PASS\s+') | Should Be $true
        ($manifestText -match '(?m)^parallel_mode: DISABLED\s*$') | Should Be $true
    }
}
