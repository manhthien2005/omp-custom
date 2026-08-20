#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-e1-evidence.ps1'
# Production always reaches Test-Phase00E1ArtifactContract through the main Phase 00 helper, which
# dot-sources this helper and also owns Test-Phase00T003LaterProductSupersessionContract. Hosting
# only the E1 helper hides that function, so the validator's current-product supersession branch
# can never fire and the four retired Workflow v0 agent pins look like unexplained drift. Load the
# main helper first; re-loading the E1 helper afterwards restores this suite's StrictMode 2.0.
$mainHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-evidence.ps1'

if (Test-Path -LiteralPath $mainHelperPath -PathType Leaf) {
    . $mainHelperPath
}
if (Test-Path -LiteralPath $helperPath -PathType Leaf) {
    . $helperPath
}

function Get-Phase00E1TestError {
    param([Parameter(Mandatory)][scriptblock]$Operation)

    try {
        $null = & $Operation
        return $null
    } catch {
        return $_
    }
}

function New-Phase00E1TestDirectory {
    $path = Join-Path ([IO.Path]::GetTempPath()) ('phase00-e1-test-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    return [IO.Path]::GetFullPath($path)
}

function Remove-Phase00E1TestDirectory {
    param([Parameter(Mandatory)][string]$Path)

    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\','/')
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')
    $prefix = $tempRoot + [IO.Path]::DirectorySeparatorChar
    if (
        -not $fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($fullPath) -notlike 'phase00-e1-test-*'
    ) {
        throw "Refusing unsafe E1 test cleanup path: $fullPath"
    }
    if (Test-Path -LiteralPath $fullPath) {
        Remove-Item -LiteralPath $fullPath -Recurse -Force
    }
}

function Write-Phase00E1TestJsonLines {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][object[]]$Objects
    )

    $lines = @($Objects | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 50 })
    [IO.File]::WriteAllLines($Path, $lines, [Text.UTF8Encoding]::new($false))
}

function Write-Phase00E1TestJson {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Value
    )

    $json = $Value | ConvertTo-Json -Compress -Depth 50
    [IO.File]::WriteAllText($Path, $json, [Text.UTF8Encoding]::new($false))
}

function Invoke-Phase00E1NodeProcess {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [int]$TimeoutSeconds = 30
    )

    $node = (Get-Command node -CommandType Application -ErrorAction Stop).Source
    $quotedArguments = @($Arguments | ForEach-Object {
        '"' + ([string]$_).Replace('"','\"') + '"'
    }) -join ' '
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $node
    $startInfo.Arguments = $quotedArguments
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) { throw 'Node process did not start.' }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            try { $process.Kill() } catch {}
            throw "Node process exceeded $TimeoutSeconds seconds."
        }
        return [pscustomobject][ordered]@{
            ExitCode = $process.ExitCode
            Stdout = $stdoutTask.GetAwaiter().GetResult()
            Stderr = $stderrTask.GetAwaiter().GetResult()
        }
    } finally {
        $process.Dispose()
    }
}

function Start-Phase00E1NodeProcess {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $node = (Get-Command node -CommandType Application -ErrorAction Stop).Source
    $quotedArguments = @($Arguments | ForEach-Object {
        '"' + ([string]$_).Replace('"','\"') + '"'
    }) -join ' '
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $node
    $startInfo.Arguments = $quotedArguments
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        $process.Dispose()
        throw 'Node process did not start.'
    }
    return $process
}

function Read-Phase00E1ProcessLine {
    param(
        [Parameter(Mandatory)][Diagnostics.Process]$Process,
        [int]$TimeoutSeconds = 10
    )

    $task = $Process.StandardOutput.ReadLineAsync()
    if (-not $task.Wait($TimeoutSeconds * 1000)) {
        throw "Node process emitted no line within $TimeoutSeconds seconds."
    }
    $line = $task.GetAwaiter().GetResult()
    if ($null -eq $line) {
        $stderr = $Process.StandardError.ReadToEnd()
        throw "Node process ended before its ready record. stderr: $stderr"
    }
    return $line
}

function Stop-Phase00E1TestProcess {
    param([AllowNull()][Diagnostics.Process]$Process)

    if ($null -eq $Process) { return }
    try {
        if (-not $Process.HasExited) {
            try { $Process.Kill() } catch {}
            $null = $Process.WaitForExit(5000)
        }
    } finally {
        $Process.Dispose()
    }
}

function Get-Phase00E1SingleJsonBlock {
    param([Parameter(Mandatory)][string]$Text)

    $normalized = $Text.Replace("`r`n", "`n")
    $matches = [regex]::Matches(
        $normalized,
        '(?ms)^```json\n(?<json>\{.*?\})\n```$'
    )
    if ($matches.Count -ne 1) {
        throw "Expected exactly one JSON code block; found $($matches.Count)."
    }
    return $matches[0].Groups['json'].Value | ConvertFrom-Json
}

function Get-Phase00E1Frontmatter {
    param([Parameter(Mandatory)][string]$Text)

    $normalized = $Text.Replace("`r`n", "`n")
    $match = [regex]::Match($normalized, '\A---\n(?<frontmatter>.*?)\n---\n', 'Singleline')
    if (-not $match.Success) {
        throw 'Expected one leading YAML frontmatter block.'
    }
    return $match.Groups['frontmatter'].Value
}

Describe 'Phase 00 E1 public evidence surface' {
    It 'exports every stable E1 function required by the approved plan' {
        $requiredFunctions = @(
            'Get-Phase00E1CaseDefinition',
            'New-Phase00E1Analysis',
            'Protect-Phase00E1EventStream',
            'Get-Phase00E1StructuredResults',
            'Get-Phase00E1ProviderLedger',
            'Resolve-Phase00E1PinnedSource',
            'Read-Phase00E1AttemptEvidence',
            'Test-Phase00E1Attempt',
            'Test-Phase00E1ProviderStrictPair',
            'Get-Phase00E1ExperimentOutcome',
            'New-Phase00E1CaseRecord',
            'New-Phase00E1ProviderStrictCaseRecord',
            'Write-Phase00E1CaseRecord',
            'Write-Phase00E1Conclusion',
            'Test-Phase00E1ArtifactContract',
            'Get-Phase00E1ExpectedFixtureHashes',
            'Get-Phase00E1ProtectedHashes',
            'Resolve-Phase00E1PinnedOmpSource',
            'Get-Phase00E1AttemptPaths',
            'Assert-Phase00E1AttemptDestinations',
            'New-Phase00E1DisposableRoot',
            'Remove-Phase00E1DisposableRoot',
            'Get-Phase00E1DirectorySnapshot',
            'Compare-Phase00E1DirectorySnapshot',
            'Get-Phase00E1ProtectedSnapshot',
            'Compare-Phase00E1ProtectedSnapshot',
            'Get-Phase00E1ProcessEnvironment',
            'Get-Phase00E1OmpArguments',
            'Invoke-Phase00E1CapturedProcess',
            'Initialize-Phase00E1DisposableFixture',
            'Protect-Phase00E1TextStream',
            'Test-Phase00E1SanitizedArtifacts',
            'Invoke-Phase00E1EvidenceCase'
        )

        $missingFunctions = @(
            $requiredFunctions |
                Where-Object { $null -eq (Get-Command $_ -CommandType Function -ErrorAction SilentlyContinue) }
        )

        @($missingFunctions).Count | Should Be 0
    }
}

Describe 'Phase 00 E1 case definitions' {
    It 'maps all seven process cases to the approved deterministic execution matrix' {
        $expected = @(
            [pscustomobject]@{ CaseId='AgentJtd'; Order=1; Artifact='case-1-agent-jtd'; Source='agent'; Mode='permissive'; Agent='phase00-e1-agent-jtd'; Prompt='agent-jtd.md'; PiNoStrict=$null; Property='sentinel'; Sentinel='E1_AGENT_JTD'; Forbidden=$null; Prohibited=$null },
            [pscustomobject]@{ CaseId='AgentJsonSchema'; Order=2; Artifact='case-1-agent-json-schema'; Source='agent'; Mode='permissive'; Agent='phase00-e1-agent-json-schema'; Prompt='agent-json-schema.md'; PiNoStrict=$null; Property='sentinel'; Sentinel='E1_AGENT_JSON_SCHEMA'; Forbidden=$null; Prohibited=$null },
            [pscustomobject]@{ CaseId='CallerOnly'; Order=3; Artifact='case-2-caller-only'; Source='caller'; Mode='permissive'; Agent='phase00-e1-caller-only'; Prompt='caller-only.md'; PiNoStrict=$null; Property='sentinel'; Sentinel='E1_CALLER_ONLY'; Forbidden=$null; Prohibited=$null },
            [pscustomobject]@{ CaseId='CallerOverAgent'; Order=4; Artifact='case-3-caller-over-agent'; Source='caller'; Mode='permissive'; Agent='phase00-e1-caller-over-agent'; Prompt='caller-over-agent.md'; PiNoStrict=$null; Property='caller_sentinel'; Sentinel='E1_CALLER_WINS'; Forbidden='agent_sentinel'; Prohibited='E1_AGENT_LOSES' },
            [pscustomobject]@{ CaseId='SessionOnly'; Order=5; Artifact='case-4-session-only'; Source='session'; Mode='permissive'; Agent='phase00-e1-session-carrier'; Prompt='session-only.md'; PiNoStrict=$null; Property='session_sentinel'; Sentinel='E1_SESSION_ONLY'; Forbidden=$null; Prohibited=$null },
            [pscustomobject]@{ CaseId='ProviderStrictOffControl'; Order=6; Artifact='case-5-provider-strict'; Source='caller'; Mode='strict'; Agent='phase00-e1-provider-strict'; Prompt='provider-strict.md'; PiNoStrict='1'; Property='allowed'; Sentinel='E1_STRICT_ALLOWED'; Forbidden='forbidden_extra'; Prohibited='E1_STRICT_FORBIDDEN' },
            [pscustomobject]@{ CaseId='ProviderStrictOn'; Order=7; Artifact='case-5-provider-strict'; Source='caller'; Mode='strict'; Agent='phase00-e1-provider-strict'; Prompt='provider-strict.md'; PiNoStrict=$null; Property='allowed'; Sentinel='E1_STRICT_ALLOWED'; Forbidden='forbidden_extra'; Prohibited='E1_STRICT_FORBIDDEN' }
        )

        foreach ($row in $expected) {
            $actual = Get-Phase00E1CaseDefinition -CaseId $row.CaseId
            ($null -ne $actual) | Should Be $true
            $actual.ExecutionOrder | Should Be $row.Order
            $actual.MatrixArtifact | Should Be $row.Artifact
            $actual.Source | Should Be $row.Source
            $actual.Mode | Should Be $row.Mode
            $actual.Agent | Should Be $row.Agent
            $actual.PromptRelativePath | Should Be (Join-Path 'prompts' $row.Prompt)
            $actual.PiNoStrict | Should Be $row.PiNoStrict
            $actual.ExpectedSentinelProperty | Should Be $row.Property
            $actual.ExpectedSentinel | Should Be $row.Sentinel
            $actual.ForbiddenProperty | Should Be $row.Forbidden
            $actual.ProhibitedValue | Should Be $row.Prohibited
            $actual.RequiresProvider | Should Be $true
        }
    }
}

Describe 'Phase 00 E1 normalized analysis objects' {
    It 'preserves the approved status, reason-code order, and direct fact object' {
        $facts = [pscustomobject][ordered]@{ case_id='AgentJtd'; attributable=$true }
        $analysis = New-Phase00E1Analysis -Status PASS -ReasonCodes @('E1_PIN_OK','E1_SENTINEL_OK') -Facts $facts

        ($null -ne $analysis) | Should Be $true
        $analysis.Status | Should Be 'PASS'
        @($analysis.ReasonCodes).Count | Should Be 2
        $analysis.ReasonCodes[0] | Should Be 'E1_PIN_OK'
        $analysis.ReasonCodes[1] | Should Be 'E1_SENTINEL_OK'
        [object]::ReferenceEquals($analysis.Facts, $facts) | Should Be $true
        @($analysis.PSObject.Properties.Name) -join ',' | Should Be 'Status,ReasonCodes,Facts'
    }

    It 'rejects status text outside the four-state attempt vocabulary' {
        $caught = $null
        try {
            $null = New-Phase00E1Analysis -Status READY -ReasonCodes @('E1_BAD_STATUS') -Facts ([pscustomobject]@{})
        } catch {
            $caught = $_
        }

        ($null -ne $caught) | Should Be $true
        $caught.Exception.GetType().FullName | Should Be 'System.Management.Automation.ParameterBindingValidationException'
        ($caught.Exception.Message -match 'PASS,FAIL,BLOCKED_ENVIRONMENT,INVALID_RUN') | Should Be $true
    }
}

Describe 'Phase 00 E1 destructive-path containment' {
    It 'accepts only normalized strict descendants of the operating-system temp root' {
        $tempRoot = [IO.Path]::GetTempPath()
        $validChild = Join-Path $tempRoot 'phase00-e1-test-root\case-a\capture'
        $normalized = Assert-Phase00E1DisposableDescendant -Path $validChild -TempRoot $tempRoot

        $normalized | Should Be ([IO.Path]::GetFullPath($validChild).TrimEnd('\','/'))

        $unsafeTargets = @(
            $tempRoot,
            (Split-Path -Parent $tempRoot),
            ($tempRoot.TrimEnd('\','/') + '-sibling\capture'),
            (Join-Path $tempRoot '..\escaped'),
            $repositoryRoot
        )
        foreach ($unsafeTarget in $unsafeTargets) {
            $caught = Get-Phase00E1TestError {
                Assert-Phase00E1DisposableDescendant -Path $unsafeTarget -TempRoot $tempRoot
            }
            ($null -ne $caught) | Should Be $true
            ($caught.Exception.Message -match 'strict temp descendant') | Should Be $true
        }
    }
}

Describe 'Phase 00 E1 pinned runtime identity' {
    It 'pins the clean upstream source identity without mutating it' {
        $sourceRoot = Join-Path $repositoryRoot '_research\upstreams\oh-my-pi'
        $beforeHead = @(& git -C $sourceRoot rev-parse HEAD 2>&1)
        $beforeStatus = @(& git -C $sourceRoot status --porcelain=v1 --untracked-files=all 2>&1)
        $identity = Resolve-Phase00E1PinnedSource -RepositoryRoot $repositoryRoot

        $identity.SourceRoot | Should Be ([IO.Path]::GetFullPath($sourceRoot))
        $identity.Commit | Should Be '3a8591a8af5b6d200088d12ca75a5517cb064fa8'
        $identity.Clean | Should Be $true
        @(& git -C $sourceRoot rev-parse HEAD 2>&1) -join "`n" |
            Should Be ($beforeHead -join "`n")
        @(& git -C $sourceRoot status --porcelain=v1 --untracked-files=all 2>&1) -join "`n" |
            Should Be ($beforeStatus -join "`n")

        $badRoot = New-Phase00E1TestDirectory
        try {
            (Get-Phase00E1TestError {
                Resolve-Phase00E1PinnedSource -RepositoryRoot $badRoot
            }).Exception.Message | Should Match 'E1_PINNED_SOURCE'
        } finally {
            Remove-Phase00E1TestDirectory -Path $badRoot
        }
    }

    It 'accepts only the pinned SHA-256 and exact trimmed omp version' {
        $pin = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'

        (Test-Phase00E1OmpIdentity -Sha256 $pin -Version "omp/17.2.10`r`n") | Should Be $true
        (Test-Phase00E1OmpIdentity -Sha256 $pin.ToLowerInvariant() -Version 'omp/17.2.10') | Should Be $true
        (Test-Phase00E1OmpIdentity -Sha256 $pin -Version 'omp/17.2.12') | Should Be $false
        (Test-Phase00E1OmpIdentity -Sha256 ('0' + $pin.Substring(1)) -Version 'omp/17.2.10') | Should Be $false
    }
}

Describe 'Phase 00 E1 line-preserving event sanitization' {
    It 'redacts private material and known paths while preserving attributable experiment facts' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $sourcePath = Join-Path $testRoot 'source.jsonl'
            $destinationPath = Join-Path $testRoot 'sanitized.jsonl'
            $disposableRoot = Join-Path $testRoot 'disposable'
            $liveHome = 'C:\Users\Example\.omp'
            $fixtureHashes = [ordered]@{
                agent = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
                prompt = 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
            }
            $lines = @(
                ([ordered]@{
                    type = 'tool_execution_start'
                    toolName = 'task'
                    args = [ordered]@{
                        agent = 'phase00-e1-agent-jtd'
                        task = 'Yield exactly the E1_AGENT_JTD sentinel.'
                        i = 'controller-intent'
                        cwd = Join-Path $repositoryRoot 'docs\evidence\phase-00\E1'
                    }
                } | ConvertTo-Json -Compress -Depth 20),
                ([ordered]@{
                    type = 'tool_execution_end'
                    toolName = 'task'
                    provider = 'omniroute'
                    model = 'codex/gpt-5.6-sol-high'
                    retry = [ordered]@{ event='auto_retry_end'; success=$true; attempt=1 }
                    result = [ordered]@{
                        details = [ordered]@{
                            results = @(
                                [ordered]@{
                                    id = 'e1-result-1'
                                    agent = 'phase00-e1-agent-jtd'
                                    structuredOutput = [ordered]@{
                                        source = 'agent'
                                        mode = 'permissive'
                                        status = 'valid'
                                        data = [ordered]@{ sentinel='E1_AGENT_JTD' }
                                    }
                                }
                            )
                        }
                    }
                } | ConvertTo-Json -Compress -Depth 20),
                ([ordered]@{
                    authorization = 'Bearer E1_SECRET_AUTH_VALUE'
                    apiKey = 'E1_SECRET_API_VALUE'
                    cookie = 'session=E1_SECRET_COOKIE_VALUE'
                    thinkingSignature = 'E1_SECRET_SIGNATURE_VALUE'
                    encrypted_content = 'E1_SECRET_ENCRYPTED_VALUE'
                    system_prompt = 'E1_PRIVATE_SYSTEM_PROMPT'
                    messages = @([ordered]@{ role='user'; content='E1_PRIVATE_MESSAGE' })
                    input = 'E1_PRIVATE_INPUT'
                    repository_path = Join-Path $repositoryRoot 'template\.omp'
                    disposable_path = Join-Path $disposableRoot 'capture\stdout.jsonl'
                    live_home_path = Join-Path $liveHome 'sessions'
                } | ConvertTo-Json -Compress -Depth 20)
            )
            [IO.File]::WriteAllLines($sourcePath, $lines, [Text.UTF8Encoding]::new($false))
            $sourceHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash

            $result = Protect-Phase00E1EventStream -SourcePath $sourcePath -DestinationPath $destinationPath -RepositoryRoot $repositoryRoot -DisposableRoot $disposableRoot -FixtureHashes $fixtureHashes -LiveHomePaths @($liveHome)

            ($null -ne $result) | Should Be $true
            $result.Status | Should Be 'PASS'
            $result.SourceLineCount | Should Be 3
            $result.SanitizedLineCount | Should Be 3
            $result.MalformedLines.Count | Should Be 0
            $result.SourceCaptureSha256 | Should Be $sourceHashBefore
            $result.SanitizedOutputSha256 | Should Be (Get-FileHash -Algorithm SHA256 -LiteralPath $destinationPath).Hash
            (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash | Should Be $sourceHashBefore

            $sanitizedLines = @([IO.File]::ReadAllLines($destinationPath))
            $sanitizedLines.Count | Should Be 3
            $events = @($sanitizedLines | ForEach-Object { $_ | ConvertFrom-Json })
            $events.Count | Should Be 3

            $events[0].args.agent | Should Be 'phase00-e1-agent-jtd'
            $events[0].args.task | Should Be 'Yield exactly the E1_AGENT_JTD sentinel.'
            $events[0].args.cwd | Should Be '<E1_REPOSITORY_ROOT>\docs\evidence\phase-00\E1'
            $events[1].provider | Should Be 'omniroute'
            $events[1].retry.success | Should Be $true
            $events[1].result.details.results[0].structuredOutput.data.sentinel | Should Be 'E1_AGENT_JTD'
            $events[2].authorization.redacted | Should Be 'secret'
            $events[2].system_prompt.redacted | Should Be 'private_content'
            $events[2].repository_path | Should Be '<E1_REPOSITORY_ROOT>\template\.omp'
            $events[2].disposable_path | Should Be '<E1_DISPOSABLE_ROOT>\capture\stdout.jsonl'
            $events[2].live_home_path | Should Be '<E1_LIVE_HOME_1>\sessions'

            $sanitizedText = [IO.File]::ReadAllText($destinationPath)
            ($sanitizedText -match 'E1_SECRET_|E1_PRIVATE_') | Should Be $false
            ($sanitizedText -match [regex]::Escape($repositoryRoot)) | Should Be $false
            ($sanitizedText -match [regex]::Escape($disposableRoot)) | Should Be $false
            ($sanitizedText -match [regex]::Escape($liveHome)) | Should Be $false
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'emits one typed marker for an unparseable source line and invalidates the run' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $sourcePath = Join-Path $testRoot 'malformed-source.jsonl'
            $destinationPath = Join-Path $testRoot 'malformed-sanitized.jsonl'
            $sourceLines = @(
                '{"type":"first","sentinel":"E1_FIRST"}',
                '{"type":"broken","secret":"E1_SECRET_MALFORMED"',
                '{"type":"third","sentinel":"E1_THIRD"}'
            )
            [IO.File]::WriteAllLines($sourcePath, $sourceLines, [Text.UTF8Encoding]::new($false))
            $sourceHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash

            $result = Protect-Phase00E1EventStream -SourcePath $sourcePath -DestinationPath $destinationPath -RepositoryRoot $repositoryRoot -DisposableRoot (Join-Path $testRoot 'disposable') -FixtureHashes ([ordered]@{})

            $result.Status | Should Be 'INVALID_RUN'
            @($result.ReasonCodes).Count | Should Be 1
            $result.ReasonCodes[0] | Should Be 'E1_SANITIZER_UNPARSEABLE_LINE'
            @($result.MalformedLines).Count | Should Be 1
            $result.MalformedLines[0] | Should Be 2
            $result.SourceLineCount | Should Be 3
            $result.SanitizedLineCount | Should Be 3
            (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash | Should Be $sourceHashBefore

            $sanitizedLines = @([IO.File]::ReadAllLines($destinationPath))
            $sanitizedLines.Count | Should Be 3
            $events = @($sanitizedLines | ForEach-Object { $_ | ConvertFrom-Json })
            $events[0].sentinel | Should Be 'E1_FIRST'
            $events[1].type | Should Be 'phase00_e1_redaction'
            $events[1].redacted | Should Be 'invalid_json_line'
            $events[1].source_line | Should Be 2
            $events[1].source_line_sha256 | Should Be '5377327A8EAA87BF3CA1A08F40795D15FAA4555FF093C938CF83D9C284B6C4F0'
            $events[2].sentinel | Should Be 'E1_THIRD'
            ([IO.File]::ReadAllText($destinationPath) -match 'E1_SECRET_MALFORMED') | Should Be $false
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'accepts valid JSON with case-colliding keys and redacts only the ambiguous object' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $sourcePath = Join-Path $testRoot 'case-collision-source.jsonl'
            $destinationPath = Join-Path $testRoot 'case-collision-sanitized.jsonl'
            $sourceLine = '{"type":"message","message":{"role":"toolResult","content":[{"type":"text","text":"E1_PRIVATE_CASE_COLLISION"}],"details":{"headers":{"A":"upper-private","a":"lower-private"}}}}'
            [IO.File]::WriteAllText(
                $sourcePath,
                $sourceLine + "`n",
                [Text.UTF8Encoding]::new($false)
            )
            $sourceHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash

            $result = Protect-Phase00E1EventStream `
                -SourcePath $sourcePath `
                -DestinationPath $destinationPath `
                -RepositoryRoot $repositoryRoot `
                -DisposableRoot (Join-Path $testRoot 'disposable') `
                -FixtureHashes ([ordered]@{})

            $result.Status | Should Be 'PASS'
            @($result.ReasonCodes).Count | Should Be 0
            @($result.MalformedLines).Count | Should Be 0
            $result.SourceLineCount | Should Be 1
            $result.SanitizedLineCount | Should Be 1
            (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash |
                Should Be $sourceHashBefore

            $event = [IO.File]::ReadAllText($destinationPath) | ConvertFrom-Json
            $event.type | Should Be 'message'
            $event.message.content[0].text.redacted | Should Be 'private_message_content'
            $event.message.details.headers.type | Should Be 'phase00_e1_redaction'
            $event.message.details.headers.redacted | Should Be 'case_colliding_json_object'
            $event.message.details.headers.key_count | Should Be 2
            $event.message.details.headers.collision_group_count | Should Be 1
            $event.message.details.headers.key_set_sha256 |
                Should Be 'B63DE4B18D0C7FB59FA7BD4F0626769E39BB61CCE4EB6D51F7C2C23D51C010DF'
            [IO.File]::ReadAllText($destinationPath) |
                Should Not Match 'E1_PRIVATE_CASE_COLLISION|upper-private|lower-private'
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'preserves valid nested empty JSON objects without invalidating the capture' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $sourcePath = Join-Path $testRoot 'empty-object-source.jsonl'
            $destinationPath = Join-Path $testRoot 'empty-object-sanitized.jsonl'
            $sourceLine = '{"type":"message_start","message":{"role":"assistant","content":[],"usage":{"cost":{}}}}'
            [IO.File]::WriteAllText(
                $sourcePath,
                $sourceLine + "`n",
                [Text.UTF8Encoding]::new($false)
            )
            $sourceHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash

            $result = Protect-Phase00E1EventStream `
                -SourcePath $sourcePath `
                -DestinationPath $destinationPath `
                -RepositoryRoot $repositoryRoot `
                -DisposableRoot (Join-Path $testRoot 'disposable') `
                -FixtureHashes ([ordered]@{})

            $result.Status | Should Be 'PASS'
            @($result.ReasonCodes).Count | Should Be 0
            @($result.MalformedLines).Count | Should Be 0
            @($result.InvalidShapeLines).Count | Should Be 0
            @($result.ProcessingErrorLines).Count | Should Be 0
            $result.SourceLineCount | Should Be 1
            $result.SanitizedLineCount | Should Be 1
            (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash |
                Should Be $sourceHashBefore

            $event = [IO.File]::ReadAllText($destinationPath) | ConvertFrom-Json
            $event.type | Should Be 'message_start'
            $event.message.role | Should Be 'assistant'
            @($event.message.content).Count | Should Be 0
            @(
                $event.message.usage.cost.PSObject.Properties |
                    ForEach-Object { $_.Name }
            ).Count | Should Be 0
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'sanitizes file-read display metadata without mistaking numeric scalars for objects' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $sourcePath = Join-Path $testRoot 'file-read-source.jsonl'
            $destinationPath = Join-Path $testRoot 'file-read-sanitized.jsonl'
            $sourceLine = [ordered]@{
                type = 'message'
                message = [ordered]@{
                    role = 'toolResult'
                    toolCallId = 'e1-read-call'
                    toolName = 'read'
                    content = @([ordered]@{
                        type = 'text'
                        text = 'E1_PRIVATE_READ_CONTENT'
                    })
                    details = [ordered]@{
                        resolvedPath = Join-Path $repositoryRoot 'private-fixture.md'
                        displayContent = [ordered]@{
                            text = 'E1_PRIVATE_DISPLAY_CONTENT'
                            startLine = 1
                            lineNumbers = @(1,2,3)
                        }
                        truncation = [ordered]@{
                            content = 'E1_PRIVATE_TRUNCATION_CONTENT'
                            truncated = $true
                            truncatedBy = 'lines'
                            totalLines = 9
                            totalBytes = 99
                            outputLines = 3
                            outputBytes = 42
                        }
                        meta = [ordered]@{
                            truncation = [ordered]@{
                                direction = 'head'
                                truncatedBy = 'lines'
                                totalLines = 9
                                totalBytes = 99
                                outputLines = 3
                                outputBytes = 42
                            }
                        }
                        fileSize = 42
                        totalLines = 3
                        numericVector = @(7,11,13)
                    }
                    isError = $false
                    timestamp = '2026-08-10T00:00:00.000Z'
                }
            } | ConvertTo-Json -Compress -Depth 20
            [IO.File]::WriteAllText(
                $sourcePath,
                $sourceLine + "`n",
                [Text.UTF8Encoding]::new($false)
            )

            $result = Protect-Phase00E1EventStream `
                -SourcePath $sourcePath `
                -DestinationPath $destinationPath `
                -RepositoryRoot $repositoryRoot `
                -DisposableRoot (Join-Path $testRoot 'disposable') `
                -FixtureHashes ([ordered]@{})

            $result.Status | Should Be 'PASS'
            @($result.ReasonCodes).Count | Should Be 0
            @($result.MalformedLines).Count | Should Be 0
            @($result.ProcessingErrorLines).Count | Should Be 0
            $event = [IO.File]::ReadAllText($destinationPath) | ConvertFrom-Json
            $event.message.content[0].text.redacted | Should Be 'private_message_content'
            $event.message.details.displayContent.redacted | Should Be 'private_content'
            $event.message.details.truncation.content.redacted | Should Be 'private_content'
            $event.message.details.truncation.totalLines | Should Be 9
            $event.message.details.meta.truncation.totalLines | Should Be 9
            $event.message.details.fileSize | Should Be 42
            $event.message.details.totalLines | Should Be 3
            @($event.message.details.numericVector) -join ',' | Should Be '7,11,13'
            [IO.File]::ReadAllText($destinationPath) |
                Should Not Match 'E1_PRIVATE_READ_CONTENT|E1_PRIVATE_DISPLAY_CONTENT|E1_PRIVATE_TRUNCATION_CONTENT'
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'refuses in-place sanitization before changing the source bytes' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $sourcePath = Join-Path $testRoot 'same-path.jsonl'
            [IO.File]::WriteAllText(
                $sourcePath,
                '{"type":"source_must_survive","sentinel":"E1_IN_PLACE"}',
                [Text.UTF8Encoding]::new($false)
            )
            $sourceHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash

            $caught = Get-Phase00E1TestError {
                Protect-Phase00E1EventStream -SourcePath $sourcePath -DestinationPath $sourcePath -RepositoryRoot $repositoryRoot -DisposableRoot (Join-Path $testRoot 'disposable') -FixtureHashes ([ordered]@{})
            }

            ($null -ne $caught) | Should Be $true
            ($caught.Exception.Message -match 'source and destination must differ') | Should Be $true
            (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash | Should Be $sourceHashBefore
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'refuses an existing destination before changing its bytes' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $sourcePath = Join-Path $testRoot 'new-source.jsonl'
            $destinationPath = Join-Path $testRoot 'existing-destination.jsonl'
            [IO.File]::WriteAllText($sourcePath, '{"type":"new"}', [Text.UTF8Encoding]::new($false))
            [IO.File]::WriteAllText($destinationPath, '{"type":"existing","sentinel":"E1_KEEP"}', [Text.UTF8Encoding]::new($false))
            $destinationHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $destinationPath).Hash

            $caught = Get-Phase00E1TestError {
                Protect-Phase00E1EventStream -SourcePath $sourcePath -DestinationPath $destinationPath -RepositoryRoot $repositoryRoot -DisposableRoot (Join-Path $testRoot 'disposable') -FixtureHashes ([ordered]@{})
            }

            ($null -ne $caught) | Should Be $true
            ($caught.Exception.Message -match 'destination already exists') | Should Be $true
            (Get-FileHash -Algorithm SHA256 -LiteralPath $destinationPath).Hash | Should Be $destinationHashBefore
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'turns valid non-object JSON lines into typed invalid-shape markers' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $sourcePath = Join-Path $testRoot 'shape-source.jsonl'
            $destinationPath = Join-Path $testRoot 'shape-sanitized.jsonl'
            [IO.File]::WriteAllLines(
                $sourcePath,
                @('null','[]','"scalar"'),
                [Text.UTF8Encoding]::new($false)
            )

            $result = Protect-Phase00E1EventStream -SourcePath $sourcePath -DestinationPath $destinationPath -RepositoryRoot $repositoryRoot -DisposableRoot (Join-Path $testRoot 'disposable') -FixtureHashes ([ordered]@{})

            $result.Status | Should Be 'INVALID_RUN'
            @($result.ReasonCodes).Count | Should Be 1
            $result.ReasonCodes[0] | Should Be 'E1_SANITIZER_NON_OBJECT_LINE'
            @($result.MalformedLines).Count | Should Be 0
            @($result.InvalidShapeLines).Count | Should Be 3
            $result.SourceLineCount | Should Be 3
            $result.SanitizedLineCount | Should Be 3

            $events = @([IO.File]::ReadAllLines($destinationPath) | ForEach-Object { $_ | ConvertFrom-Json })
            $events.Count | Should Be 3
            $events[0].redacted | Should Be 'invalid_json_shape'
            $events[0].observed_kind | Should Be 'null'
            $events[1].observed_kind | Should Be 'array'
            $events[2].observed_kind | Should Be 'string'
            @($events.source_line) -join ',' | Should Be '1,2,3'
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'redacts message prose and thinking without deleting tool calls or terminal metadata' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $sourcePath = Join-Path $testRoot 'messages-source.jsonl'
            $destinationPath = Join-Path $testRoot 'messages-sanitized.jsonl'
            $assistantMessage = [ordered]@{
                role = 'assistant'
                content = @(
                    [ordered]@{
                        type = 'thinking'
                        thinking = 'E1_PRIVATE_ASSISTANT_THINKING'
                        thinkingSignature = 'E1_SECRET_ASSISTANT_SIGNATURE'
                    },
                    [ordered]@{
                        type = 'toolCall'
                        id = 'e1-task-call'
                        name = 'task'
                        arguments = [ordered]@{
                            agent = 'phase00-e1-agent-jtd'
                            task = 'E1_REQUIRED_TASK_ASSIGNMENT'
                        }
                    }
                )
                api = 'openai-responses'
                provider = 'omniroute'
                model = 'codex/gpt-5.6-sol-high'
                stopReason = 'toolUse'
            }
            $sourceLines = @(
                ([ordered]@{
                    type = 'message_end'
                    message = [ordered]@{
                        role = 'user'
                        content = @([ordered]@{ type='text'; text='E1_PRIVATE_USER_MESSAGE' })
                        attribution = 'user'
                    }
                } | ConvertTo-Json -Compress -Depth 20),
                ([ordered]@{ type='message_end'; message=$assistantMessage } | ConvertTo-Json -Compress -Depth 20),
                ([ordered]@{
                    type = 'message_update'
                    assistantMessageEvent = [ordered]@{
                        type = 'thinking_end'
                        contentIndex = 0
                        content = 'E1_PRIVATE_THINKING_DELTA'
                    }
                } | ConvertTo-Json -Compress -Depth 20),
                ([ordered]@{
                    type = 'agent_end'
                    messages = @($assistantMessage)
                    isTerminal = $true
                } | ConvertTo-Json -Compress -Depth 20)
            )
            [IO.File]::WriteAllLines($sourcePath, $sourceLines, [Text.UTF8Encoding]::new($false))

            $result = Protect-Phase00E1EventStream -SourcePath $sourcePath -DestinationPath $destinationPath -RepositoryRoot $repositoryRoot -DisposableRoot (Join-Path $testRoot 'disposable') -FixtureHashes ([ordered]@{})

            $result.Status | Should Be 'PASS'
            $events = @([IO.File]::ReadAllLines($destinationPath) | ForEach-Object { $_ | ConvertFrom-Json })
            $events.Count | Should Be 4
            $events[0].message.content[0].text.redacted | Should Be 'private_message_content'
            $events[1].message.content[0].thinking.redacted | Should Be 'private_reasoning'
            $events[1].message.content[0].thinkingSignature.redacted | Should Be 'secret'
            $events[1].message.content[1].name | Should Be 'task'
            $events[1].message.content[1].arguments.task | Should Be 'E1_REQUIRED_TASK_ASSIGNMENT'
            $events[2].assistantMessageEvent.content.redacted | Should Be 'private_reasoning'
            $events[3].messages[0].provider | Should Be 'omniroute'
            $events[3].messages[0].model | Should Be 'codex/gpt-5.6-sol-high'
            $events[3].messages[0].stopReason | Should Be 'toolUse'
            $events[3].messages[0].content[1].arguments.agent | Should Be 'phase00-e1-agent-jtd'
            $events[3].isTerminal | Should Be $true

            $sanitizedText = [IO.File]::ReadAllText($destinationPath)
            ($sanitizedText -match 'E1_PRIVATE_|E1_SECRET_ASSISTANT_SIGNATURE') | Should Be $false
            ($sanitizedText -match 'E1_REQUIRED_TASK_ASSIGNMENT') | Should Be $true
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'invalidates credential-shaped generic text without treating a variable name as a secret value' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $sourcePath = Join-Path $testRoot 'credential-source.jsonl'
            $destinationPath = Join-Path $testRoot 'credential-sanitized.jsonl'
            $sourceLine = [ordered]@{
                type = 'diagnostic'
                generic_note = 'Authorization: Bearer E1_GENERIC_SECRET_VALUE'
                environment_note = 'Read OMNIROUTE_API_KEY from the process environment.'
                attributable_fact = 'E1_ATTRIBUTABLE_FACT'
            } | ConvertTo-Json -Compress
            [IO.File]::WriteAllText($sourcePath, $sourceLine, [Text.UTF8Encoding]::new($false))

            $result = Protect-Phase00E1EventStream -SourcePath $sourcePath -DestinationPath $destinationPath -RepositoryRoot $repositoryRoot -DisposableRoot (Join-Path $testRoot 'disposable') -FixtureHashes ([ordered]@{})

            $result.Status | Should Be 'INVALID_RUN'
            @($result.ReasonCodes).Count | Should Be 1
            $result.ReasonCodes[0] | Should Be 'E1_SANITIZER_CREDENTIAL_SHAPED_TEXT'
            @($result.CredentialLines).Count | Should Be 1
            $result.CredentialLines[0] | Should Be 1

            $event = [IO.File]::ReadAllText($destinationPath) | ConvertFrom-Json
            $event.generic_note.redacted | Should Be 'credential_shaped_text'
            $event.generic_note.field | Should Be 'generic_note'
            $event.environment_note | Should Be 'Read <E1_CREDENTIAL_VARIABLE> from the process environment.'
            $event.attributable_fact | Should Be 'E1_ATTRIBUTABLE_FACT'
            ([IO.File]::ReadAllText($destinationPath) -match 'E1_GENERIC_SECRET_VALUE|OMNIROUTE_API_KEY') | Should Be $false
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

Describe 'Phase 00 E1 persisted-session sanitization' {
    It 'redacts camel-case session prompts while retaining typed local schema evidence' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $sourcePath = Join-Path $testRoot 'session-source.jsonl'
            $destinationPath = Join-Path $testRoot 'session-sanitized.jsonl'
            Write-Phase00E1TestJsonLines -Path $sourcePath -Objects @(
                [ordered]@{
                    type = 'session_init'
                    agent = 'phase00-e1-provider-strict'
                    systemPrompt = 'PRIVATE_SYSTEM_PROMPT_MUST_NOT_PERSIST'
                    task = 'PRIVATE_SESSION_TASK_DUPLICATE_MUST_NOT_PERSIST'
                    tools = @('read','yield')
                },
                [ordered]@{
                    type = 'message'
                    message = [ordered]@{
                        role = 'assistant'; provider='omniroute'
                        model='codex/gpt-5.6-sol-high'; stopReason='toolUse'
                        content = @([ordered]@{
                            type='toolCall'; id='yield-1'; name='yield'
                            arguments=[ordered]@{
                                result=[ordered]@{
                                    data=[ordered]@{
                                        allowed='E1_STRICT_FORBIDDEN'
                                        forbidden_extra='E1_FORBIDDEN_EXTRA'
                                    }
                                }
                            }
                        })
                    }
                },
                [ordered]@{
                    type = 'message'
                    message = [ordered]@{
                        role='toolResult'; toolCallId='yield-1'; toolName='yield'
                        isError=$true
                        content=@([ordered]@{
                            type='text'
                            text='Error: Output does not match schema: forbidden property.'
                        })
                    }
                }
            )

            $metadata = Protect-Phase00E1EventStream `
                -SourcePath $sourcePath -DestinationPath $destinationPath `
                -RepositoryRoot $repositoryRoot `
                -DisposableRoot (Join-Path $testRoot 'disposable') `
                -FixtureHashes ([ordered]@{})

            $metadata.Status | Should Be 'PASS'
            $records = @([IO.File]::ReadAllLines($destinationPath) |
                ForEach-Object { $_ | ConvertFrom-Json })
            $records[0].systemPrompt.redacted | Should Be 'private_content'
            $records[0].task.redacted | Should Be 'private_content'
            $records[0].agent | Should Be 'phase00-e1-provider-strict'
            $records[1].message.content[0].arguments.result.data.forbidden_extra |
                Should Be 'E1_FORBIDDEN_EXTRA'
            $records[2].message.content[0].text.redacted |
                Should Be 'private_message_content'
            $records[2].message.e1_tool_error_classification |
                Should Be 'yield_schema_validation'
            $text = [IO.File]::ReadAllText($destinationPath)
            $text | Should Not Match 'PRIVATE_SYSTEM_PROMPT_MUST_NOT_PERSIST'
            $text | Should Not Match 'PRIVATE_SESSION_TASK_DUPLICATE_MUST_NOT_PERSIST'
            $text | Should Not Match 'forbidden property'
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

Describe 'Phase 00 E1 structured-result extraction' {
    It 'deduplicates repeated sightings within one origin while preserving carrier and nested-leaf provenance' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $parentPath = Join-Path $testRoot 'parent.jsonl'
            $leafPath = Join-Path $testRoot 'leaf.jsonl'
            $carrierResult = [ordered]@{
                id = 'carrier-result'
                agent = 'phase00-e1-session-carrier'
                structuredOutput = [ordered]@{
                    source = 'caller'
                    mode = 'permissive'
                    status = 'valid'
                    data = [ordered]@{ session_sentinel='E1_SESSION_ONLY' }
                }
            }
            $leafResult = [ordered]@{
                id = 'leaf-result'
                agent = 'phase00-e1-session-leaf'
                structuredOutput = [ordered]@{
                    source = 'session'
                    mode = 'permissive'
                    status = 'valid'
                    data = [ordered]@{ session_sentinel='E1_SESSION_ONLY' }
                }
            }
            Write-Phase00E1TestJsonLines -Path $parentPath -Objects @(
                [ordered]@{
                    type = 'tool_execution_end'
                    result = [ordered]@{
                        details = [ordered]@{
                            results = @(
                                $carrierResult,
                                [ordered]@{ id='progress-only'; agent='phase00-e1-session-carrier'; status='running' }
                            )
                        }
                    }
                },
                [ordered]@{ type='message_end'; repeated=[ordered]@{ results=@($carrierResult) } }
            )
            Write-Phase00E1TestJsonLines -Path $leafPath -Objects @(
                [ordered]@{ type='nested_result'; payload=$leafResult },
                [ordered]@{ type='agent_end'; repeated=$leafResult; isTerminal=$true }
            )

            $results = @(Get-Phase00E1StructuredResults -EventPaths @($parentPath,$leafPath))

            $results.Count | Should Be 2
            $results[0].Id | Should Be 'carrier-result'
            $results[0].Agent | Should Be 'phase00-e1-session-carrier'
            $results[0].StructuredOutput.source | Should Be 'caller'
            $results[0].OriginPath | Should Be ([IO.Path]::GetFullPath($parentPath))
            $results[0].LineNumber | Should Be 1
            $results[1].Id | Should Be 'leaf-result'
            $results[1].Agent | Should Be 'phase00-e1-session-leaf'
            $results[1].StructuredOutput.source | Should Be 'session'
            $results[1].StructuredOutput.data.session_sentinel | Should Be 'E1_SESSION_ONLY'
            $results[1].OriginPath | Should Be ([IO.Path]::GetFullPath($leafPath))
            $results[1].LineNumber | Should Be 1
            @($results.Id) -contains 'progress-only' | Should Be $false
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

Describe 'Phase 00 E1 task-call argument provenance' {
    It 'drops only optional intent while preserving outputSchema absence versus explicit null' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $eventPath = Join-Path $testRoot 'task-calls.jsonl'
            Write-Phase00E1TestJsonLines -Path $eventPath -Objects @(
                [ordered]@{
                    type = 'tool_execution_start'
                    toolCallId = 'call-agent'
                    toolName = 'task'
                    args = [ordered]@{
                        task = 'Yield the agent sentinel.'
                        i = 'intent must not enter business args'
                        agent = 'phase00-e1-agent-jtd'
                        name = 'agent-probe'
                    }
                },
                [ordered]@{
                    type = 'tool_execution_update'
                    toolCallId = 'call-agent'
                    toolName = 'task'
                    args = [ordered]@{ agent='phase00-e1-agent-jtd'; task='duplicate update' }
                },
                [ordered]@{
                    type = 'tool_execution_start'
                    toolCallId = 'call-leaf'
                    toolName = 'task'
                    args = [ordered]@{
                        agent = 'phase00-e1-session-leaf'
                        task = 'Yield the session sentinel.'
                        outputSchema = $null
                        schemaMode = 'permissive'
                        i = 'second intent'
                    }
                }
            )

            $calls = @(Get-Phase00E1TaskCalls -EventPaths @($eventPath))

            $calls.Count | Should Be 2
            $calls[0].ToolCallId | Should Be 'call-agent'
            $calls[0].Agent | Should Be 'phase00-e1-agent-jtd'
            $calls[0].HasOutputSchema | Should Be $false
            @($calls[0].ArgumentNames) -join ',' | Should Be 'agent,name,task'
            $calls[0].CanonicalArguments.task | Should Be 'Yield the agent sentinel.'
            $calls[0].CanonicalArguments.PSObject.Properties.Name -contains 'i' | Should Be $false
            $calls[0].OriginPath | Should Be ([IO.Path]::GetFullPath($eventPath))
            $calls[0].LineNumber | Should Be 1

            $calls[1].ToolCallId | Should Be 'call-leaf'
            $calls[1].HasOutputSchema | Should Be $true
            $calls[1].OutputSchema | Should Be $null
            @($calls[1].ArgumentNames) -join ',' | Should Be 'agent,outputSchema,schemaMode,task'
            $calls[1].CanonicalArguments.schemaMode | Should Be 'permissive'
            $calls[1].LineNumber | Should Be 3
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

Describe 'Phase 00 E1 provider retry authority' {
    It 'counts requests and classifies a superseded provider error as recovered' {
        $errorMessage = [pscustomobject][ordered]@{
            role = 'assistant'
            stopReason = 'error'
            provider = 'omniroute'
            model = 'codex/gpt-5.6-sol-high'
            errorMessage = 'server_is_overloaded'
        }
        $stopMessage = [pscustomobject][ordered]@{
            role = 'assistant'
            stopReason = 'stop'
            provider = 'omniroute'
            model = 'codex/gpt-5.6-sol-high'
        }
        $events = @(
            [pscustomobject]@{ type='message_start'; message=$errorMessage },
            [pscustomobject]@{ type='message_end'; message=$errorMessage },
            [pscustomobject]@{
                type='auto_retry_start'; attempt=1; maxAttempts=10
                errorId=135168; errorMessage='server_is_overloaded'
            },
            [pscustomobject]@{ type='message_start'; message=$stopMessage },
            [pscustomobject]@{ type='message_end'; message=$stopMessage },
            [pscustomobject]@{ type='auto_retry_end'; attempt=1; success=$true },
            [pscustomobject]@{
                type='agent_end'; isTerminal=$true; messages=@($stopMessage)
            }
        )

        $ledger = Get-Phase00E1ProviderLedger -Events $events

        $ledger.RequestCount | Should Be 2
        $ledger.ResponseEndCount | Should Be 2
        $ledger.RetryStartCount | Should Be 1
        $ledger.RetryEndCount | Should Be 1
        $ledger.RecoveredRetryCount | Should Be 1
        $ledger.RetryExhausted | Should Be $false
        $ledger.TerminalFailure.Found | Should Be $false
        $ledger.AuthoritativeOutcome.Source | Should Be 'terminal-agent-end'
        $ledger.AuthoritativeOutcome.Message.stopReason | Should Be 'stop'
        $ledger.Provider | Should Be 'omniroute'
        $ledger.Model | Should Be 'codex/gpt-5.6-sol-high'
    }

    It 'classifies an unsuperseded exhausted provider error as terminal' {
        $firstError = [pscustomobject][ordered]@{
            role='assistant'; stopReason='error'; provider='omniroute'
            model='codex/gpt-5.6-sol-high'; errorMessage='server_is_overloaded'
        }
        $terminalError = [pscustomobject][ordered]@{
            role='assistant'; stopReason='error'; provider='omniroute'
            model='codex/gpt-5.6-sol-high'; errorMessage='quota exhausted'
        }
        $events = @(
            [pscustomobject]@{ type='message_start'; message=$firstError },
            [pscustomobject]@{ type='message_end'; message=$firstError },
            [pscustomobject]@{
                type='auto_retry_start'; attempt=1; maxAttempts=1
                errorId=135168; errorMessage='server_is_overloaded'
            },
            [pscustomobject]@{ type='message_start'; message=$terminalError },
            [pscustomobject]@{ type='message_end'; message=$terminalError },
            [pscustomobject]@{
                type='auto_retry_end'; attempt=1; success=$false
                finalError='quota exhausted'
            },
            [pscustomobject]@{
                type='agent_end'; isTerminal=$true; messages=@($terminalError)
            }
        )

        $ledger = Get-Phase00E1ProviderLedger -Events $events

        $ledger.RequestCount | Should Be 2
        $ledger.RecoveredRetryCount | Should Be 0
        $ledger.RetryExhausted | Should Be $true
        $ledger.RetryExhaustedCount | Should Be 1
        $ledger.TerminalFailure.Found | Should Be $true
        $ledger.TerminalFailure.IsEnvironmentBlock | Should Be $true
        $ledger.TerminalFailure.Code | Should Be 'P00-RUNTIME-PROVIDER-QUOTA'
        $ledger.AuthoritativeOutcome.Message.stopReason | Should Be 'error'
    }
}

Describe 'Phase 00 E1 common attempt oracle' {
    It 'passes only a complete pinned attributable attempt' {
        $definition = Get-Phase00E1CaseDefinition -CaseId AgentJtd
        $result = [pscustomobject][ordered]@{
            Id = 'agent-jtd-result'
            Agent = 'phase00-e1-agent-jtd'
            StructuredOutput = [pscustomobject][ordered]@{
                source='agent'; mode='permissive'; status='valid'
                data=[pscustomobject]@{ sentinel='E1_AGENT_JTD' }
            }
        }
        $ledger = [pscustomobject][ordered]@{
            RequestCount=1; AttributedRequestCount=1; UnattributedRequestCount=0
            Provider='omniroute'; Model='codex/gpt-5.6-sol-high'
            RetryExhausted=$false; RecoveredRetryCount=0
            TerminalFailure=[pscustomobject]@{
                Found=$false; IsEnvironmentBlock=$false; Code=$null
            }
        }
        $runRecord = [pscustomobject][ordered]@{
            PinnedSourceCommit='3a8591a8af5b6d200088d12ca75a5517cb064fa8'
            RuntimeSha256='1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
            RuntimeVersion='omp/17.2.10'
            ExitCode=0
            TimedOut=$false
            SanitizerStatus='PASS'
            RawArtifacts=@(
                [pscustomobject]@{
                    Path='raw/agent-jtd.stdout.jsonl'
                    Sha256=('A' * 64)
                }
            )
            RequiredEventAnchors=@(
                [pscustomobject]@{
                    Path='raw/agent-jtd.stdout.jsonl'; Line=7; Type='tool_execution_end'
                }
            )
            CleanupSucceeded=$true
            RemainingChildPids=@()
            ProtectedSurfacesUnchanged=$true
        }

        $analysis = Test-Phase00E1CommonAttempt -Definition $definition `
            -AttributableResults @($result) -ProviderLedger $ledger -RunRecord $runRecord

        $analysis.Status | Should Be 'PASS'
        ($analysis.ReasonCodes -join ',') | Should Be 'E1_COMMON_ORACLES_PASS'
        $analysis.Facts.AttributableResult.Id | Should Be 'agent-jtd-result'
    }

    It 'rejects each load-bearing mutation with deterministic status precedence' {
        $newResult = {
            [pscustomobject][ordered]@{
                Id='agent-jtd-result'; Agent='phase00-e1-agent-jtd'
                StructuredOutput=[pscustomobject][ordered]@{
                    source='agent'; mode='permissive'; status='valid'
                    data=[pscustomobject]@{ sentinel='E1_AGENT_JTD' }
                }
            }
        }
        $newLedger = {
            [pscustomobject][ordered]@{
                RequestCount=1; AttributedRequestCount=1; UnattributedRequestCount=0
                Provider='omniroute'; Model='codex/gpt-5.6-sol-high'
                RetryExhausted=$false; RecoveredRetryCount=0
                TerminalFailure=[pscustomobject]@{
                    Found=$false; IsEnvironmentBlock=$false; Code=$null
                }
            }
        }
        $newRunRecord = {
            [pscustomobject][ordered]@{
                PinnedSourceCommit='3a8591a8af5b6d200088d12ca75a5517cb064fa8'
                RuntimeSha256='1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
                RuntimeVersion='omp/17.2.10'; ExitCode=0; TimedOut=$false
                SanitizerStatus='PASS'
                RawArtifacts=@([pscustomobject]@{ Path='raw/test.jsonl'; Sha256=('B' * 64) })
                RequiredEventAnchors=@(
                    [pscustomobject]@{ Path='raw/test.jsonl'; Line=4; Type='message_end' }
                )
                CleanupSucceeded=$true; RemainingChildPids=@()
                ProtectedSurfacesUnchanged=$true
            }
        }
        $mutations = @(
            [pscustomobject]@{ Name='wrong-runtime'; Status='INVALID_RUN'; Reason='E1_RUNTIME_IDENTITY_MISMATCH' },
            [pscustomobject]@{ Name='duplicate-result'; Status='INVALID_RUN'; Reason='E1_ATTRIBUTABLE_RESULT_COUNT' },
            [pscustomobject]@{ Name='missing-anchor'; Status='INVALID_RUN'; Reason='E1_RAW_ANCHOR_MISSING' },
            [pscustomobject]@{ Name='missing-raw'; Status='INVALID_RUN'; Reason='E1_RAW_ARTIFACT_MISSING,E1_RAW_ANCHOR_MISSING' },
            [pscustomobject]@{ Name='missing-hash'; Status='INVALID_RUN'; Reason='E1_RAW_HASH_MISSING' },
            [pscustomobject]@{ Name='protected-mutation'; Status='INVALID_RUN'; Reason='E1_PROTECTED_SURFACE_MUTATION' },
            [pscustomobject]@{ Name='environment-terminal'; Status='BLOCKED_ENVIRONMENT'; Reason='E1_PROVIDER_ENVIRONMENT_BLOCK' },
            [pscustomobject]@{ Name='retry-exhausted'; Status='FAIL'; Reason='E1_RETRY_EXHAUSTED' },
            [pscustomobject]@{ Name='terminal-inversion'; Status='FAIL'; Reason='E1_TERMINAL_MODEL_FAILURE' },
            [pscustomobject]@{ Name='wrong-source'; Status='FAIL'; Reason='E1_STRUCTURED_SOURCE_MISMATCH' }
        )

        foreach ($mutation in $mutations) {
            $definition = Get-Phase00E1CaseDefinition -CaseId AgentJtd
            $results = @(& $newResult)
            $ledger = & $newLedger
            $runRecord = & $newRunRecord
            switch ($mutation.Name) {
                'wrong-runtime' { $runRecord.RuntimeVersion = 'omp/17.2.12' }
                'duplicate-result' { $results = @(& $newResult; & $newResult) }
                'missing-anchor' { $runRecord.RequiredEventAnchors = @() }
                'missing-raw' { $runRecord.RawArtifacts = @() }
                'missing-hash' { $runRecord.RawArtifacts[0].Sha256 = 'NOT_A_SHA256' }
                'protected-mutation' { $runRecord.ProtectedSurfacesUnchanged = $false }
                'environment-terminal' {
                    $ledger.TerminalFailure = [pscustomobject]@{
                        Found=$true; IsEnvironmentBlock=$true
                        Code='P00-RUNTIME-PROVIDER-QUOTA'
                    }
                }
                'retry-exhausted' { $ledger.RetryExhausted = $true }
                'terminal-inversion' {
                    $ledger.RecoveredRetryCount = 1
                    $ledger.TerminalFailure = [pscustomobject]@{
                        Found=$true; IsEnvironmentBlock=$false; Code='OVERLOADED'
                    }
                }
                'wrong-source' { $results[0].StructuredOutput.source = 'caller' }
            }

            $analysis = Test-Phase00E1CommonAttempt -Definition $definition `
                -AttributableResults $results -ProviderLedger $ledger -RunRecord $runRecord

            $analysis.Status | Should Be $mutation.Status
            ($analysis.ReasonCodes -join ',') | Should Be $mutation.Reason
        }
    }
}

Describe 'Phase 00 E1 forwarder offline projection' {
    It 'projects a closed explicit-strict yield deterministically without persisting secrets' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $forwarder = Join-Path $repositoryRoot 'scripts\lib\phase00-e1-forwarder.mjs'
            $requestPath = Join-Path $testRoot 'strict-request.json'
            $reorderedRequestPath = Join-Path $testRoot 'strict-request-reordered.json'
            $outputPath = Join-Path $testRoot 'projection.ndjson'
            $reorderedOutputPath = Join-Path $testRoot 'projection-reordered.ndjson'
            $parameters = [ordered]@{
                type = 'object'
                properties = [ordered]@{
                    data = [ordered]@{
                        type = 'object'
                        properties = [ordered]@{
                            zeta = [ordered]@{ type='string' }
                            allowed = [ordered]@{ type='string'; const='E1_STRICT_ALLOWED' }
                        }
                        required = @('zeta','allowed')
                        additionalProperties = $false
                    }
                }
                required = @('data')
                additionalProperties = $false
            }
            $request = [ordered]@{
                model = 'PRIVATE_MODEL_MUST_NOT_PERSIST'
                input = 'PRIVATE_PROMPT_MUST_NOT_PERSIST'
                api_key = 'SECRET_VALUE_MUST_NOT_PERSIST'
                tools = @(
                    [ordered]@{
                        type='function'; name='unrelated'; strict=$false
                        parameters=[ordered]@{ type='object'; properties=[ordered]@{} }
                    },
                    [ordered]@{
                        type='function'; name='yield'; strict=$true; parameters=$parameters
                    }
                )
            }
            $reorderedParameters = [ordered]@{
                additionalProperties = $false
                required = @('data')
                properties = [ordered]@{
                    data = [ordered]@{
                        additionalProperties = $false
                        required = @('zeta','allowed')
                        properties = [ordered]@{
                            allowed = [ordered]@{ const='E1_STRICT_ALLOWED'; type='string' }
                            zeta = [ordered]@{ type='string' }
                        }
                        type = 'object'
                    }
                }
                type = 'object'
            }
            Write-Phase00E1TestJson -Path $requestPath -Value $request
            Write-Phase00E1TestJson -Path $reorderedRequestPath -Value ([ordered]@{
                tools=@([ordered]@{
                    parameters=$reorderedParameters; strict=$true; name='yield'; type='function'
                })
            })

            $first = Invoke-Phase00E1NodeProcess -Arguments @(
                $forwarder,'--project-only',$requestPath,'--output',$outputPath,
                '--pi-no-strict','false'
            )
            $second = Invoke-Phase00E1NodeProcess -Arguments @(
                $forwarder,'--project-only',$reorderedRequestPath,'--output',$reorderedOutputPath,
                '--pi-no-strict','false'
            )

            $first.ExitCode | Should Be 0
            $second.ExitCode | Should Be 0
            $records = @(Get-Content -LiteralPath $outputPath | ForEach-Object { $_ | ConvertFrom-Json })
            $records.Count | Should Be 1
            $record = $records[0]
            $record.record_type | Should Be 'phase00_e1_request_projection'
            $record.request_index | Should Be 1
            $record.request_path | Should Be '/v1/responses'
            $record.forwarded | Should Be $false
            $record.gateway_http_status | Should Be $null
            $record.gateway | Should Be 'omniroute'
            $record.api | Should Be 'openai-responses'
            $record.yield_tool_present | Should Be $true
            $record.yield_strict_field_present | Should Be $true
            $record.yield_strict | Should Be $true
            $record.yield_parameters_sha256 | Should Match '^[0-9A-F]{64}$'
            @($record.allowed_data_properties) -join ',' | Should Be 'allowed,zeta'
            @($record.required_data_properties) -join ',' | Should Be 'allowed,zeta'
            $record.data_additional_properties | Should Be $false
            $record.pi_no_strict_effective | Should Be $false
            @($record.PSObject.Properties.Name | Sort-Object) -join ',' | Should Be (
                @(
                    'allowed_data_properties','api','data_additional_properties','forwarded',
                    'gateway','gateway_http_status','pi_no_strict_effective','record_type',
                    'request_index','request_path','required_data_properties',
                    'yield_parameters_sha256','yield_strict','yield_strict_field_present',
                    'yield_tool_present'
                ) -join ','
            )

            $reordered = Get-Content -LiteralPath $reorderedOutputPath -Raw | ConvertFrom-Json
            $reordered.yield_parameters_sha256 | Should Be $record.yield_parameters_sha256
            $persisted = Get-Content -LiteralPath $outputPath -Raw
            $persisted | Should Not Match 'PRIVATE_MODEL_MUST_NOT_PERSIST'
            $persisted | Should Not Match 'PRIVATE_PROMPT_MUST_NOT_PERSIST'
            $persisted | Should Not Match 'SECRET_VALUE_MUST_NOT_PERSIST'
            $persisted | Should Not Match 'api_key|authorization|cookie'

            $beforeOverwrite = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
            $overwrite = Invoke-Phase00E1NodeProcess -Arguments @(
                $forwarder,'--project-only',$requestPath,'--output',$outputPath,
                '--pi-no-strict','false'
            )
            $overwrite.ExitCode | Should Not Be 0
            $overwrite.Stderr | Should Match '(?i)(exists|overwrite|refus)'
            (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash |
                Should Be $beforeOverwrite
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'projects the pinned OMP YieldTool result wrapper data schema' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $forwarder = Join-Path $repositoryRoot 'scripts\lib\phase00-e1-forwarder.mjs'
            $requestPath = Join-Path $testRoot 'wrapped-yield-request.json'
            $outputPath = Join-Path $testRoot 'wrapped-yield-projection.ndjson'
            $dataSchema = [ordered]@{
                type = 'object'
                properties = [ordered]@{
                    allowed = [ordered]@{ type='string'; const='E1_STRICT_ALLOWED' }
                }
                required = @('allowed')
                additionalProperties = $false
            }
            $parameters = [ordered]@{
                type = 'object'
                properties = [ordered]@{
                    type = [ordered]@{
                        anyOf = @(
                            [ordered]@{ type='string' },
                            [ordered]@{ type='array'; minItems=1; items=[ordered]@{ type='string' } },
                            [ordered]@{ type='null' }
                        )
                    }
                    result = [ordered]@{
                        anyOf = @(
                            [ordered]@{
                                type = 'object'
                                properties = [ordered]@{ data=$dataSchema }
                                required = @('data')
                                additionalProperties = $false
                            },
                            [ordered]@{
                                type = 'object'
                                properties = [ordered]@{ error=[ordered]@{ type='string' } }
                                required = @('error')
                                additionalProperties = $false
                            },
                            [ordered]@{
                                type = 'object'
                                properties = [ordered]@{}
                                required = @()
                                additionalProperties = $false
                            }
                        )
                    }
                }
                required = @('type','result')
                additionalProperties = $false
            }
            Write-Phase00E1TestJson -Path $requestPath -Value ([ordered]@{
                tools=@([ordered]@{
                    type='function'; name='yield'; strict=$true; parameters=$parameters
                })
            })

            $run = Invoke-Phase00E1NodeProcess -Arguments @(
                $forwarder,'--project-only',$requestPath,'--output',$outputPath,
                '--pi-no-strict','false'
            )

            $run.ExitCode | Should Be 0
            $record = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
            @($record.allowed_data_properties) -join ',' | Should Be 'allowed'
            @($record.required_data_properties) -join ',' | Should Be 'allowed'
            $record.data_additional_properties | Should Be $false
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'distinguishes omitted and false strict while ignoring unrelated tools' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $forwarder = Join-Path $repositoryRoot 'scripts\lib\phase00-e1-forwarder.mjs'
            $cases = @(
                [pscustomobject][ordered]@{
                    Name='omitted-open'; PiNoStrict='true'; YieldPresent=$true
                    StrictPresent=$false; StrictValue=$null; AdditionalProperties=$true
                    Body=[ordered]@{ tools=@([ordered]@{
                        type='function'; name='yield'
                        parameters=[ordered]@{
                            type='object'; properties=[ordered]@{ data=[ordered]@{
                                type='object'; properties=[ordered]@{ beta=[ordered]@{type='string'}; alpha=[ordered]@{type='string'} }
                                required=@('beta'); additionalProperties=$true
                            }}
                        }
                    }) }
                },
                [pscustomobject][ordered]@{
                    Name='explicit-false'; PiNoStrict='false'; YieldPresent=$true
                    StrictPresent=$true; StrictValue=$false; AdditionalProperties=$false
                    Body=[ordered]@{ tools=@([ordered]@{
                        type='function'; name='yield'; strict=$false
                        parameters=[ordered]@{
                            type='object'; properties=[ordered]@{ data=[ordered]@{
                                type='object'; properties=[ordered]@{ allowed=[ordered]@{type='string'} }
                                required=@('allowed'); additionalProperties=$false
                            }}
                        }
                    }) }
                },
                [pscustomobject][ordered]@{
                    Name='missing-yield'; PiNoStrict='false'; YieldPresent=$false
                    StrictPresent=$false; StrictValue=$null; AdditionalProperties=$null
                    Body=[ordered]@{ tools=@([ordered]@{
                        type='function'; name='other'; strict=$true
                        parameters=[ordered]@{ type='object'; properties=[ordered]@{} }
                    }) }
                }
            )

            foreach ($case in $cases) {
                $requestPath = Join-Path $testRoot ($case.Name + '.json')
                $outputPath = Join-Path $testRoot ($case.Name + '.ndjson')
                Write-Phase00E1TestJson -Path $requestPath -Value $case.Body
                $run = Invoke-Phase00E1NodeProcess -Arguments @(
                    $forwarder,'--project-only',$requestPath,'--output',$outputPath,
                    '--pi-no-strict',$case.PiNoStrict
                )
                $run.ExitCode | Should Be 0
                $record = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
                $record.yield_tool_present | Should Be $case.YieldPresent
                $record.yield_strict_field_present | Should Be $case.StrictPresent
                $record.yield_strict | Should Be $case.StrictValue
                $record.data_additional_properties | Should Be $case.AdditionalProperties
                $record.pi_no_strict_effective | Should Be ([bool]::Parse($case.PiNoStrict))
                if ($case.Name -eq 'omitted-open') {
                    @($record.allowed_data_properties) -join ',' | Should Be 'alpha,beta'
                    @($record.required_data_properties) -join ',' | Should Be 'beta'
                }
                if (-not $case.YieldPresent) {
                    $record.yield_parameters_sha256 | Should Be $null
                    @($record.allowed_data_properties).Count | Should Be 0
                    @($record.required_data_properties).Count | Should Be 0
                }
            }
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'rejects unsafe live endpoints and refuses an existing evidence path before listening' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $forwarder = Join-Path $repositoryRoot 'scripts\lib\phase00-e1-forwarder.mjs'
            $unsafeListenOutput = Join-Path $testRoot 'unsafe-listen.ndjson'
            $unsafeListen = Invoke-Phase00E1NodeProcess -Arguments @(
                $forwarder,
                '--listen','0.0.0.0:0',
                '--target','http://127.0.0.1:20128',
                '--output',$unsafeListenOutput,
                '--pi-no-strict','false'
            )
            $unsafeListen.ExitCode | Should Not Be 0
            $unsafeListen.Stderr | Should Match '127\.0\.0\.1:0'
            $unsafeListen.Stdout | Should Be ''
            Test-Path -LiteralPath $unsafeListenOutput | Should Be $false

            $unsafeTargetOutput = Join-Path $testRoot 'unsafe-target.ndjson'
            $unsafeTarget = Invoke-Phase00E1NodeProcess -Arguments @(
                $forwarder,
                '--listen','127.0.0.1:0',
                '--target','http://localhost:20128',
                '--output',$unsafeTargetOutput,
                '--pi-no-strict','false'
            )
            $unsafeTarget.ExitCode | Should Not Be 0
            $unsafeTarget.Stderr | Should Match '127\.0\.0\.1 origin'
            $unsafeTarget.Stdout | Should Be ''
            Test-Path -LiteralPath $unsafeTargetOutput | Should Be $false

            $existingOutput = Join-Path $testRoot 'existing.ndjson'
            [IO.File]::WriteAllText(
                $existingOutput,
                "PRESERVE_EXISTING_EVIDENCE`n",
                [Text.UTF8Encoding]::new($false)
            )
            $existingHash = (Get-FileHash -LiteralPath $existingOutput -Algorithm SHA256).Hash
            $overwrite = Invoke-Phase00E1NodeProcess -Arguments @(
                $forwarder,
                '--listen','127.0.0.1:0',
                '--target','http://127.0.0.1:20128',
                '--output',$existingOutput,
                '--pi-no-strict','false'
            )
            $overwrite.ExitCode | Should Not Be 0
            $overwrite.Stderr | Should Match '(?i)(exists|overwrite|refus)'
            $overwrite.Stdout | Should Be ''
            (Get-FileHash -LiteralPath $existingOutput -Algorithm SHA256).Hash |
                Should Be $existingHash
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

Describe 'Phase 00 E1 forwarder local relay' {
    It 'relays bytes through loopback while persisting only ready projection and closed records' {
        $testRoot = New-Phase00E1TestDirectory
        $fakeProcess = $null
        $forwarderProcess = $null
        try {
            if (-not ('System.Net.Http.HttpClient' -as [type])) {
                Add-Type -AssemblyName System.Net.Http
            }
            $fakeScriptPath = Join-Path $testRoot 'fake-gateway.mjs'
            $observationPath = Join-Path $testRoot 'fake-observation.json'
            $forwarderOutputPath = Join-Path $testRoot 'forwarder.ndjson'
            $fakeScript = @'
import { createServer } from "node:http";
import { writeFileSync } from "node:fs";

const observationPath = process.argv[2];
const responseBytes = Buffer.from([0, 255, 1, 2, 13, 10, 69, 49, 0, 128]);
const server = createServer((request, response) => {
  const chunks = [];
  request.on("data", (chunk) => chunks.push(chunk));
  request.on("end", () => {
    const body = Buffer.concat(chunks);
    writeFileSync(observationPath, JSON.stringify({
      method: request.method,
      path: request.url,
      body_base64: body.toString("base64"),
      authorization_ok: request.headers.authorization === "Bearer E1_FORWARD_AUTH_SECRET",
      hop_header_present: Object.prototype.hasOwnProperty.call(request.headers, "x-remove-me"),
      end_to_end_header: request.headers["x-end-to-end"] ?? null
    }), { flag: "wx", mode: 0o600 });
    response.writeHead(207, {
      "content-type": "application/octet-stream",
      "content-length": String(responseBytes.length),
      "connection": "close, x-gateway-hop",
      "x-gateway-hop": "must-be-stripped",
      "x-end-response": "kept"
    });
    response.end(responseBytes);
  });
});
server.listen(0, "127.0.0.1", () => {
  const address = server.address();
  process.stdout.write(JSON.stringify({ host: address.address, port: address.port }) + "\n");
});
process.stdin.setEncoding("utf8");
process.stdin.on("data", (text) => {
  if (text.split(/\r?\n/).some((line) => line.trim() === "close")) {
    server.close(() => process.exit(0));
  }
});
'@
            [IO.File]::WriteAllText(
                $fakeScriptPath,
                $fakeScript,
                [Text.UTF8Encoding]::new($false)
            )
            $fakeProcess = Start-Phase00E1NodeProcess -Arguments @(
                $fakeScriptPath,$observationPath
            )
            $fakeReady = Read-Phase00E1ProcessLine -Process $fakeProcess |
                ConvertFrom-Json
            $fakeReady.host | Should Be '127.0.0.1'

            $forwarder = Join-Path $repositoryRoot 'scripts\lib\phase00-e1-forwarder.mjs'
            $forwarderProcess = Start-Phase00E1NodeProcess -Arguments @(
                $forwarder,
                '--listen','127.0.0.1:0',
                '--target',("http://127.0.0.1:{0}" -f $fakeReady.port),
                '--output',$forwarderOutputPath,
                '--pi-no-strict','false'
            )
            $ready = Read-Phase00E1ProcessLine -Process $forwarderProcess |
                ConvertFrom-Json
            $ready.record_type | Should Be 'phase00_e1_forwarder_ready'
            $ready.listen_host | Should Be '127.0.0.1'
            ([int]$ready.listen_port -gt 0) | Should Be $true
            @($ready.PSObject.Properties.Name | Sort-Object) -join ',' | Should Be `
                'listen_host,listen_port,record_type'

            $requestBody = [ordered]@{
                input='PRIVATE_LIVE_PROMPT_MUST_NOT_PERSIST'
                tools=@([ordered]@{
                    type='function'; name='yield'; strict=$true
                    parameters=[ordered]@{
                        type='object'; properties=[ordered]@{ data=[ordered]@{
                            type='object'; properties=[ordered]@{
                                allowed=[ordered]@{type='string';const='E1_STRICT_ALLOWED'}
                            }
                            required=@('allowed'); additionalProperties=$false
                        }}
                        required=@('data'); additionalProperties=$false
                    }
                })
            }
            $requestJson = $requestBody | ConvertTo-Json -Compress -Depth 50
            $requestBytes = [Text.Encoding]::UTF8.GetBytes($requestJson)
            $handler = [Net.Http.HttpClientHandler]::new()
            $handler.UseProxy = $false
            $client = [Net.Http.HttpClient]::new($handler)
            $request = [Net.Http.HttpRequestMessage]::new(
                [Net.Http.HttpMethod]::Post,
                ("http://127.0.0.1:{0}/v1/responses?trace=PRIVATE_QUERY_MUST_NOT_PERSIST" -f $ready.listen_port)
            )
            $request.Content = [Net.Http.ByteArrayContent]::new($requestBytes)
            $request.Content.Headers.ContentType = [Net.Http.Headers.MediaTypeHeaderValue]::new('application/json')
            $null = $request.Headers.TryAddWithoutValidation(
                'Authorization','Bearer E1_FORWARD_AUTH_SECRET'
            )
            $null = $request.Headers.TryAddWithoutValidation(
                'Connection','keep-alive, x-remove-me'
            )
            $null = $request.Headers.TryAddWithoutValidation(
                'X-Remove-Me','HOP_SECRET_MUST_NOT_FORWARD'
            )
            $null = $request.Headers.TryAddWithoutValidation('X-End-To-End','kept')
            try {
                $response = $client.SendAsync($request).GetAwaiter().GetResult()
                try {
                    [int]$response.StatusCode | Should Be 207
                    $responseBytes = $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
                    [Convert]::ToBase64String($responseBytes) |
                        Should Be ([Convert]::ToBase64String([byte[]](0,255,1,2,13,10,69,49,0,128)))
                    $response.Headers.Contains('x-gateway-hop') | Should Be $false
                    @($response.Headers.GetValues('x-end-response')) -join ',' | Should Be 'kept'
                } finally {
                    $response.Dispose()
                }
            } finally {
                $request.Dispose()
                $client.Dispose()
                $handler.Dispose()
            }

            $deadline = [DateTime]::UtcNow.AddSeconds(5)
            while (-not (Test-Path -LiteralPath $observationPath) -and
                [DateTime]::UtcNow -lt $deadline) {
                Start-Sleep -Milliseconds 20
            }
            $observation = Get-Content -LiteralPath $observationPath -Raw |
                ConvertFrom-Json
            $observation.method | Should Be 'POST'
            $observation.path | Should Be '/v1/responses?trace=PRIVATE_QUERY_MUST_NOT_PERSIST'
            $observation.body_base64 | Should Be ([Convert]::ToBase64String($requestBytes))
            $observation.authorization_ok | Should Be $true
            $observation.hop_header_present | Should Be $false
            $observation.end_to_end_header | Should Be 'kept'

            $forwarderProcess.StandardInput.WriteLine('close')
            $forwarderProcess.StandardInput.Flush()
            $forwarderProcess.StandardInput.Close()
            $forwarderProcess.WaitForExit(10000) | Should Be $true
            $forwarderProcess.ExitCode | Should Be 0
            $forwarderStderr = $forwarderProcess.StandardError.ReadToEnd()
            $forwarderStderr | Should Be ''

            $records = @(Get-Content -LiteralPath $forwarderOutputPath |
                ForEach-Object { $_ | ConvertFrom-Json })
            $records.Count | Should Be 3
            @($records.record_type) -join ',' | Should Be `
                'phase00_e1_forwarder_ready,phase00_e1_request_projection,phase00_e1_forwarder_closed'
            $records[1].request_index | Should Be 1
            $records[1].request_path | Should Be '/v1/responses'
            $records[1].forwarded | Should Be $true
            $records[1].gateway_http_status | Should Be 207
            $records[1].yield_strict | Should Be $true
            $records[2].listen_port | Should Be $ready.listen_port
            @($records[1].PSObject.Properties.Name | Sort-Object) -join ',' | Should Be (
                @(
                    'allowed_data_properties','api','data_additional_properties','forwarded',
                    'gateway','gateway_http_status','pi_no_strict_effective','record_type',
                    'request_index','request_path','required_data_properties',
                    'yield_parameters_sha256','yield_strict','yield_strict_field_present',
                    'yield_tool_present'
                ) -join ','
            )
            @($records[2].PSObject.Properties.Name | Sort-Object) -join ',' | Should Be `
                'listen_host,listen_port,record_type'

            $persisted = Get-Content -LiteralPath $forwarderOutputPath -Raw
            $persisted | Should Not Match 'PRIVATE_LIVE_PROMPT_MUST_NOT_PERSIST'
            $persisted | Should Not Match 'PRIVATE_QUERY_MUST_NOT_PERSIST'
            $persisted | Should Not Match 'E1_FORWARD_AUTH_SECRET'
            $persisted | Should Not Match 'HOP_SECRET_MUST_NOT_FORWARD'

            $tcpClient = [Net.Sockets.TcpClient]::new()
            $portClosed = $false
            try {
                $connectTask = $tcpClient.ConnectAsync('127.0.0.1',[int]$ready.listen_port)
                if (-not $connectTask.Wait(1000)) {
                    $portClosed = $true
                } else {
                    $portClosed = -not $tcpClient.Connected
                }
            } catch {
                $portClosed = $true
            } finally {
                $tcpClient.Dispose()
            }
            $portClosed | Should Be $true

            $fakeProcess.StandardInput.WriteLine('close')
            $fakeProcess.StandardInput.Flush()
            $fakeProcess.StandardInput.Close()
            $fakeProcess.WaitForExit(10000) | Should Be $true
            $fakeProcess.ExitCode | Should Be 0
        } finally {
            Stop-Phase00E1TestProcess -Process $forwarderProcess
            Stop-Phase00E1TestProcess -Process $fakeProcess
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

Describe 'Phase 00 E1 forwarder downstream abort lifecycle' {
    It 'disposes an unfinished upstream relay after downstream abort and exits cleanly' {
        $testRoot = New-Phase00E1TestDirectory
        $fakeProcess = $null
        $forwarderProcess = $null
        $client = $null
        try {
            $fakeScriptPath = Join-Path $testRoot 'hold-open-gateway.mjs'
            $forwarderOutputPath = Join-Path $testRoot 'forwarder.ndjson'
            $fakeScript = @'
import { createServer } from "node:http";

const sockets = new Set();
const server = createServer((request, response) => {
  request.resume();
  request.on("end", () => {
    response.writeHead(209, { "content-type": "text/plain" });
    response.write("E1_ABORT_PREFIX");
  });
});
server.on("connection", (socket) => {
  sockets.add(socket);
  socket.on("close", () => sockets.delete(socket));
});
server.listen(0, "127.0.0.1", () => {
  const address = server.address();
  process.stdout.write(JSON.stringify({ host: address.address, port: address.port }) + "\n");
});
process.stdin.setEncoding("utf8");
process.stdin.on("data", (text) => {
  if (text.split(/\r?\n/).some((line) => line.trim() === "close")) {
    for (const socket of sockets) socket.destroy();
    server.close(() => process.exit(0));
  }
});
'@
            [IO.File]::WriteAllText(
                $fakeScriptPath,
                $fakeScript,
                [Text.UTF8Encoding]::new($false)
            )
            $fakeProcess = Start-Phase00E1NodeProcess -Arguments @($fakeScriptPath)
            $fakeReady = Read-Phase00E1ProcessLine -Process $fakeProcess |
                ConvertFrom-Json
            $fakeReady.host | Should Be '127.0.0.1'

            $forwarder = Join-Path $repositoryRoot 'scripts\lib\phase00-e1-forwarder.mjs'
            $forwarderProcess = Start-Phase00E1NodeProcess -Arguments @(
                $forwarder,
                '--listen','127.0.0.1:0',
                '--target',("http://127.0.0.1:{0}" -f $fakeReady.port),
                '--output',$forwarderOutputPath,
                '--pi-no-strict','true'
            )
            $ready = Read-Phase00E1ProcessLine -Process $forwarderProcess |
                ConvertFrom-Json
            $ready.record_type | Should Be 'phase00_e1_forwarder_ready'

            $requestBody = [ordered]@{
                input = 'PRIVATE_ABORT_PROMPT_MUST_NOT_PERSIST'
                tools = @([ordered]@{
                    type = 'function'
                    name = 'yield'
                    parameters = [ordered]@{
                        type = 'object'
                        properties = [ordered]@{
                            data = [ordered]@{
                                type = 'object'
                                properties = [ordered]@{
                                    allowed = [ordered]@{ type='string' }
                                }
                                required = @('allowed')
                                additionalProperties = $false
                            }
                        }
                        required = @('data')
                        additionalProperties = $false
                    }
                })
            }
            $requestJson = $requestBody | ConvertTo-Json -Compress -Depth 50
            $requestBytes = [Text.Encoding]::UTF8.GetBytes($requestJson)
            $requestHead = (
                "POST /v1/responses HTTP/1.1`r`n" +
                "Host: 127.0.0.1`r`n" +
                "Content-Type: application/json`r`n" +
                "Content-Length: $($requestBytes.Length)`r`n" +
                "Connection: close`r`n`r`n"
            )
            $requestHeadBytes = [Text.Encoding]::ASCII.GetBytes($requestHead)
            $client = [Net.Sockets.TcpClient]::new()
            $client.Connect('127.0.0.1',[int]$ready.listen_port)
            $stream = $client.GetStream()
            $stream.ReadTimeout = 5000
            $stream.Write($requestHeadBytes,0,$requestHeadBytes.Length)
            $stream.Write($requestBytes,0,$requestBytes.Length)
            $stream.Flush()
            $received = [Text.StringBuilder]::new()
            $buffer = New-Object byte[] 1024
            while ($received.ToString() -notmatch 'E1_ABORT_PREFIX') {
                $count = $stream.Read($buffer,0,$buffer.Length)
                if ($count -le 0) {
                    throw 'Gateway prefix was not relayed before downstream close.'
                }
                $null = $received.Append(
                    [Text.Encoding]::ASCII.GetString($buffer,0,$count)
                )
            }
            $client.Dispose()
            $client = $null

            $forwarderProcess.StandardInput.WriteLine('close')
            $forwarderProcess.StandardInput.Flush()
            $forwarderProcess.StandardInput.Close()
            $exited = $forwarderProcess.WaitForExit(5000)
            if (-not $exited) {
                try { $forwarderProcess.Kill() } catch {}
                $null = $forwarderProcess.WaitForExit(5000)
            }
            $stderr = $forwarderProcess.StandardError.ReadToEnd()
            $records = @(Get-Content -LiteralPath $forwarderOutputPath |
                ForEach-Object { $_ | ConvertFrom-Json })
            $projections = @($records | Where-Object {
                $_.record_type -eq 'phase00_e1_request_projection'
            })
            $summary = (
                'exited={0};exit={1};projections={2};records={3};stderr_empty={4}' -f
                $exited,
                $forwarderProcess.ExitCode,
                $projections.Count,
                (@($records.record_type) -join ','),
                ($stderr -eq '')
            )
            $summary | Should Be (
                'exited=True;exit=0;projections=1;records=' +
                'phase00_e1_forwarder_ready,phase00_e1_request_projection,' +
                'phase00_e1_forwarder_closed;stderr_empty=True'
            )
            $projections[0].request_index | Should Be 1
            $projections[0].request_path | Should Be '/v1/responses'
            $projections[0].forwarded | Should Be $true
            $projections[0].gateway_http_status | Should Be 209
            $projections[0].pi_no_strict_effective | Should Be $true
            (Get-Content -LiteralPath $forwarderOutputPath -Raw) |
                Should Not Match 'PRIVATE_ABORT_PROMPT_MUST_NOT_PERSIST'

            $portProbe = [Net.Sockets.TcpClient]::new()
            $portClosed = $false
            try {
                $connectTask = $portProbe.ConnectAsync(
                    '127.0.0.1',[int]$ready.listen_port
                )
                if (-not $connectTask.Wait(1000)) {
                    $portClosed = $true
                } else {
                    $portClosed = -not $portProbe.Connected
                }
            } catch {
                $portClosed = $true
            } finally {
                $portProbe.Dispose()
            }
            $portClosed | Should Be $true

            $fakeProcess.StandardInput.WriteLine('close')
            $fakeProcess.StandardInput.Flush()
            $fakeProcess.StandardInput.Close()
            $fakeProcess.WaitForExit(10000) | Should Be $true
            $fakeProcess.ExitCode | Should Be 0
            $fakeProcess.StandardError.ReadToEnd() | Should Be ''
        } finally {
            if ($null -ne $client) { $client.Dispose() }
            Stop-Phase00E1TestProcess -Process $forwarderProcess
            Stop-Phase00E1TestProcess -Process $fakeProcess
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

Describe 'Phase 00 E1 deterministic fixture contracts' {
    $fixtureRoot = Join-Path $repositoryRoot 'docs\evidence\phase-00\E1\fixture'
    $expectedFixtureHashes = [ordered]@{
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

    It 'contains only the fourteen fixed fixture paths at their precommitted hashes' {
        if (-not (Test-Path -LiteralPath $fixtureRoot -PathType Container)) {
            throw "E1 fixture root does not exist: $fixtureRoot"
        }
        $actualPaths = @(
            Get-ChildItem -LiteralPath $fixtureRoot -File -Recurse |
                ForEach-Object {
                    $_.FullName.Substring($fixtureRoot.Length).TrimStart('\','/').Replace('\','/')
                } |
                Sort-Object
        )
        @($actualPaths) -join ',' | Should Be (@($expectedFixtureHashes.Keys | Sort-Object) -join ',')
        foreach ($entry in $expectedFixtureHashes.GetEnumerator()) {
            $relativePath = $entry.Key.Replace('/', [IO.Path]::DirectorySeparatorChar)
            $path = Join-Path $fixtureRoot $relativePath
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash | Should Be $entry.Value
        }
    }

    It 'pins direct mode, one-at-a-time execution, recursion two, and bounded runtime' {
        $path = Join-Path $fixtureRoot '.omp\config.yml'
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "E1 config fixture does not exist: $path"
        }
        $expected = @'
plan:
  defaultOnStartup: false
async:
  enabled: false
task:
  batch: false
  enableEffort: false
  maxConcurrency: 1
  maxRecursionDepth: 2
  maxRuntimeMs: 180000
  isolation:
    mode: none
    apply: false
'@
        $expected = $expected.Replace("`r`n", "`n").TrimEnd("`r","`n") + "`n"
        [IO.File]::ReadAllText($path).Replace("`r`n", "`n") | Should Be $expected
    }

    It 'pins seven blocking agents with minimal tools and exact output ownership' {
        $agents = @(
            [pscustomobject]@{File='phase00-e1-agent-jtd.md';Name='phase00-e1-agent-jtd';Description='E1 agent-owned JTD output probe';Tools='read';Spawns='""';Output='jtd'},
            [pscustomobject]@{File='phase00-e1-agent-json-schema.md';Name='phase00-e1-agent-json-schema';Description='E1 agent-owned JSON Schema output probe';Tools='read';Spawns='""';Output='json'},
            [pscustomobject]@{File='phase00-e1-caller-only.md';Name='phase00-e1-caller-only';Description='E1 caller-owned output probe without agent output';Tools='read';Spawns='""';Output='none'},
            [pscustomobject]@{File='phase00-e1-caller-over-agent.md';Name='phase00-e1-caller-over-agent';Description='E1 conflicting caller-over-agent precedence probe';Tools='read';Spawns='""';Output='conflict'},
            [pscustomobject]@{File='phase00-e1-session-carrier.md';Name='phase00-e1-session-carrier';Description='E1 parent-session schema carrier probe';Tools='task';Spawns='phase00-e1-session-leaf';Output='none'},
            [pscustomobject]@{File='phase00-e1-session-leaf.md';Name='phase00-e1-session-leaf';Description='E1 nested leaf parent-session fallback probe';Tools='read';Spawns='""';Output='none'},
            [pscustomobject]@{File='phase00-e1-provider-strict.md';Name='phase00-e1-provider-strict';Description='E1 provider strictness discriminator probe';Tools='read';Spawns='""';Output='none'}
        )
        foreach ($agent in $agents) {
            $path = Join-Path (Join-Path $fixtureRoot 'agents') $agent.File
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                throw "E1 agent fixture does not exist: $path"
            }
            $text = [IO.File]::ReadAllText($path).Replace("`r`n", "`n")
            $frontmatter = Get-Phase00E1Frontmatter -Text $text
            $topLevelKeys = @(
                [regex]::Matches($frontmatter, '(?m)^(?<key>[A-Za-z][A-Za-z0-9-]*):') |
                    ForEach-Object { $_.Groups['key'].Value }
            )
            $expectedKeys = @('name','description','blocking','tools','spawns')
            if ($agent.Output -ne 'none') { $expectedKeys += 'output' }
            @($topLevelKeys) -join ',' | Should Be ($expectedKeys -join ',')
            $frontmatter | Should Match ("(?m)^name: {0}$" -f [regex]::Escape($agent.Name))
            $frontmatter | Should Match ("(?m)^description: {0}$" -f [regex]::Escape($agent.Description))
            $frontmatter | Should Match '(?m)^blocking: true$'
            $frontmatter | Should Match ("(?m)^tools: {0}$" -f [regex]::Escape($agent.Tools))
            $frontmatter | Should Match ("(?m)^spawns: {0}$" -f [regex]::Escape($agent.Spawns))
            [regex]::Matches($frontmatter, '(?m)^blocking: true$').Count | Should Be 1
            $frontmatter | Should Not Match '(?m)^model:'
            if ($agent.Output -eq 'none') {
                $frontmatter | Should Not Match '(?m)^output:'
            }
            $text | Should Match ([regex]::Escape('result.data'))
        }

        $jtd = Get-Phase00E1Frontmatter -Text ([IO.File]::ReadAllText(
            (Join-Path $fixtureRoot 'agents\phase00-e1-agent-jtd.md')
        ).Replace("`r`n", "`n"))
        $jtd | Should Match '(?ms)^.*\noutput:\n  properties:\n    sentinel:\n      enum: \[E1_AGENT_JTD\]$'

        $json = Get-Phase00E1Frontmatter -Text ([IO.File]::ReadAllText(
            (Join-Path $fixtureRoot 'agents\phase00-e1-agent-json-schema.md')
        ).Replace("`r`n", "`n"))
        $json | Should Match '(?ms)^.*\noutput:\n  type: object\n  properties:\n    sentinel:\n      type: string\n      const: E1_AGENT_JSON_SCHEMA\n  required: \[sentinel\]\n  additionalProperties: false$'

        $conflict = Get-Phase00E1Frontmatter -Text ([IO.File]::ReadAllText(
            (Join-Path $fixtureRoot 'agents\phase00-e1-caller-over-agent.md')
        ).Replace("`r`n", "`n"))
        $conflict | Should Match '(?ms)^.*\noutput:\n  type: object\n  properties:\n    agent_sentinel:\n      type: string\n      const: E1_AGENT_LOSES\n  required: \[agent_sentinel\]\n  additionalProperties: false$'

        $carrierText = [IO.File]::ReadAllText(
            (Join-Path $fixtureRoot 'agents\phase00-e1-session-carrier.md')
        ).Replace("`r`n", "`n")
        $carrierCall = Get-Phase00E1SingleJsonBlock -Text $carrierText
        @($carrierCall.PSObject.Properties.Name | Sort-Object) -join ',' |
            Should Be 'agent,name,schemaMode,task'
        $carrierCall.name | Should Be 'E1SessionLeaf'
        $carrierCall.agent | Should Be 'phase00-e1-session-leaf'
        $carrierCall.schemaMode | Should Be 'permissive'
        ($carrierCall.PSObject.Properties.Name -contains 'outputSchema') | Should Be $false
        $carrierCall.task | Should Be 'Terminal-yield result.data exactly {"session_sentinel":"E1_SESSION_ONLY"} using the active parent-session schema.'

        $strictText = [IO.File]::ReadAllText(
            (Join-Path $fixtureRoot 'agents\phase00-e1-provider-strict.md')
        ).Replace("`r`n", "`n")
        $strictText | Should Match ([regex]::Escape('{"allowed":"E1_STRICT_FORBIDDEN","forbidden_extra":"E1_FORBIDDEN_EXTRA"}'))
        $strictText | Should Match ([regex]::Escape('{"allowed":"E1_STRICT_ALLOWED"}'))
        $strictText | Should Match 'If and only if that call returns a schema-validation tool error'
    }

    It 'pins six flat controller calls, omission semantics, schemas, and markers' {
        $prompts = @(
            [pscustomobject]@{File='agent-jtd.md';Name='E1AgentJtd';Agent='phase00-e1-agent-jtd';Mode='permissive';HasOutput=$false;Property=$null;Const=$null;Marker='E1_CONTROLLER_AGENT_JTD_DONE';Task='Terminal-yield result.data exactly {"sentinel":"E1_AGENT_JTD"} using the active agent-owned schema.'},
            [pscustomobject]@{File='agent-json-schema.md';Name='E1AgentJsonSchema';Agent='phase00-e1-agent-json-schema';Mode='permissive';HasOutput=$false;Property=$null;Const=$null;Marker='E1_CONTROLLER_AGENT_JSON_SCHEMA_DONE';Task='Terminal-yield result.data exactly {"sentinel":"E1_AGENT_JSON_SCHEMA"} using the active agent-owned schema.'},
            [pscustomobject]@{File='caller-only.md';Name='E1CallerOnly';Agent='phase00-e1-caller-only';Mode='permissive';HasOutput=$true;Property='sentinel';Const='E1_CALLER_ONLY';Marker='E1_CONTROLLER_CALLER_ONLY_DONE';Task='Terminal-yield result.data exactly {"sentinel":"E1_CALLER_ONLY"} using the active caller schema.'},
            [pscustomobject]@{File='caller-over-agent.md';Name='E1CallerOverAgent';Agent='phase00-e1-caller-over-agent';Mode='permissive';HasOutput=$true;Property='caller_sentinel';Const='E1_CALLER_WINS';Marker='E1_CONTROLLER_CALLER_OVER_AGENT_DONE';Task='Inspect the active terminal schema and terminal-yield only the property and constant it requires; never combine competing schema fields.'},
            [pscustomobject]@{File='session-only.md';Name='E1SessionOnly';Agent='phase00-e1-session-carrier';Mode='permissive';HasOutput=$true;Property='session_sentinel';Const='E1_SESSION_ONLY';Marker='E1_CONTROLLER_SESSION_ONLY_DONE';Task='Call the allowed session leaf exactly once as specified by your role, then terminal-yield result.data exactly {"session_sentinel":"E1_SESSION_ONLY"}.'},
            [pscustomobject]@{File='provider-strict.md';Name='E1ProviderStrict';Agent='phase00-e1-provider-strict';Mode='strict';HasOutput=$true;Property='allowed';Const='E1_STRICT_ALLOWED';Marker='E1_CONTROLLER_PROVIDER_STRICT_DONE';Task='First terminal-yield result.data exactly {"allowed":"E1_STRICT_FORBIDDEN","forbidden_extra":"E1_FORBIDDEN_EXTRA"}. Only if that yield returns a schema-validation tool error, terminal-yield {"allowed":"E1_STRICT_ALLOWED"} exactly once.'}
        )
        foreach ($prompt in $prompts) {
            $path = Join-Path (Join-Path $fixtureRoot 'prompts') $prompt.File
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                throw "E1 controller prompt does not exist: $path"
            }
            $text = [IO.File]::ReadAllText($path).Replace("`r`n", "`n")
            $call = Get-Phase00E1SingleJsonBlock -Text $text
            $expectedKeys = if ($prompt.HasOutput) {
                'agent,name,outputSchema,schemaMode,task'
            } else {
                'agent,name,schemaMode,task'
            }
            @($call.PSObject.Properties.Name | Sort-Object) -join ',' | Should Be $expectedKeys
            $call.name | Should Be $prompt.Name
            $call.agent | Should Be $prompt.Agent
            $call.schemaMode | Should Be $prompt.Mode
            $call.task | Should Be $prompt.Task
            foreach ($forbidden in @('blocking','isolated','effort','i','tasks','context')) {
                ($call.PSObject.Properties.Name -contains $forbidden) | Should Be $false
            }
            ($text -match '"outputSchema"\s*:\s*null') | Should Be $false
            $text | Should Match '(?m)^Do not use batch form\.'
            $text | Should Match ([regex]::Escape("output exactly ``$($prompt.Marker)`` as plain text and stop."))
            if (-not $prompt.HasOutput) {
                ($call.PSObject.Properties.Name -contains 'outputSchema') | Should Be $false
                continue
            }
            @($call.outputSchema.PSObject.Properties.Name | Sort-Object) -join ',' |
                Should Be 'additionalProperties,properties,required,type'
            $call.outputSchema.type | Should Be 'object'
            $call.outputSchema.additionalProperties | Should Be $false
            @($call.outputSchema.required) -join ',' | Should Be $prompt.Property
            @($call.outputSchema.properties.PSObject.Properties.Name) -join ',' |
                Should Be $prompt.Property
            $propertySchema = $call.outputSchema.properties.($prompt.Property)
            @($propertySchema.PSObject.Properties.Name | Sort-Object) -join ',' |
                Should Be 'const,type'
            $propertySchema.type | Should Be 'string'
            $propertySchema.const | Should Be $prompt.Const
        }
    }

    It 'uses one byte-identical strict prompt and schema for both environment arms' {
        $strictOff = Get-Phase00E1CaseDefinition -CaseId ProviderStrictOffControl
        $strictOn = Get-Phase00E1CaseDefinition -CaseId ProviderStrictOn
        $strictOff.Agent | Should Be $strictOn.Agent
        $strictOff.PromptRelativePath | Should Be $strictOn.PromptRelativePath
        $strictOff.PromptRelativePath.Replace('\','/') | Should Be 'prompts/provider-strict.md'
        $strictOff.Mode | Should Be 'strict'
        $strictOn.Mode | Should Be 'strict'
        $strictOff.PiNoStrict | Should Be '1'
        $strictOn.PiNoStrict | Should Be $null

        $promptPath = Join-Path $fixtureRoot $strictOn.PromptRelativePath
        if (-not (Test-Path -LiteralPath $promptPath -PathType Leaf)) {
            throw "E1 strict prompt does not exist: $promptPath"
        }
        (Get-FileHash -LiteralPath $promptPath -Algorithm SHA256).Hash |
            Should Be '15B1C1BA9133F89B1125FCD089F87147F282DC1AAF315FFB303322A46AC87113'
        [IO.File]::ReadAllText($promptPath) | Should Not Match 'PI_NO_STRICT'
    }
}

Describe 'Phase 00 E1 runner preflight and static contract' {
    It 'exposes only the approved parameters and delegates to the evidence runner' {
        $runnerPath = Join-Path $repositoryRoot 'scripts\run-phase00-e1.ps1'
        if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
            throw "E1 runner does not exist: $runnerPath"
        }
        $tokens = $null
        $parseErrors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $runnerPath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        @($parseErrors).Count | Should Be 0
        @($ast.ParamBlock.Parameters | ForEach-Object {
            $_.Name.VariablePath.UserPath
        }) -join ',' | Should Be 'CaseId,Attempt,OmpExecutable,Model,AllowOverwrite'
        $text = [IO.File]::ReadAllText($runnerPath).Replace("`r`n", "`n")
        $text | Should Match '(?m)^#Requires -Version 5\.1$'
        $text | Should Match '(?m)^Set-StrictMode -Version 2\.0$'
        $text | Should Match '(?m)^\. \(Join-Path \$PSScriptRoot ''lib\\phase00-e1-evidence\.ps1''\)$'
        $text | Should Match '(?m)^Invoke-Phase00E1EvidenceCase @PSBoundParameters$'
        $text | Should Match "\[ValidateSet\('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn'\)\]"
        $text | Should Match '\[ValidateRange\(1,999\)\]\[int\]\$Attempt = 1'
        $text | Should Match '\[string\]\$Model = ''omniroute/codex/gpt-5\.6-sol-high'''
        $text | Should Not Match '(?i)worktree|git branch|git checkout|provider-test-bypass'
    }

    It 'rejects missing, wrong-hash, and wrong-version runtimes before creating a root' {
        $pin = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
        $version = 'omp/17.2.10'
        $missing = Join-Path ([IO.Path]::GetTempPath()) `
            ('phase00-e1-missing-' + [guid]::NewGuid().ToString('N') + '.exe')
        $missingError = Get-Phase00E1TestError {
            Resolve-Phase00E1PinnedOmpSource -Path $missing `
                -ExpectedSha256 $pin -ExpectedVersion $version `
                -WorkingDirectory $repositoryRoot
        }
        ($null -ne $missingError) | Should Be $true
        $missingError.Exception.Message | Should Match '(?i)(does not exist|missing)'

        $nodePath = (Get-Command node -CommandType Application -ErrorAction Stop).Source
        $wrongHash = Get-Phase00E1TestError {
            Resolve-Phase00E1PinnedOmpSource -Path $nodePath `
                -ExpectedSha256 $pin -ExpectedVersion $version `
                -WorkingDirectory $repositoryRoot
        }
        ($null -ne $wrongHash) | Should Be $true
        $wrongHash.Exception.Message | Should Match '(?i)sha-?256'

        $nodeHash = (Get-FileHash -LiteralPath $nodePath -Algorithm SHA256).Hash
        $wrongVersion = Get-Phase00E1TestError {
            Resolve-Phase00E1PinnedOmpSource -Path $nodePath `
                -ExpectedSha256 $nodeHash -ExpectedVersion $version `
                -WorkingDirectory $repositoryRoot
        }
        ($null -ne $wrongVersion) | Should Be $true
        $wrongVersion.Exception.Message | Should Match '(?i)version'

        $pinnedPath = 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
        $identity = Resolve-Phase00E1PinnedOmpSource -Path $pinnedPath `
            -ExpectedSha256 $pin -ExpectedVersion $version `
            -WorkingDirectory $repositoryRoot
        $identity.Path | Should Be ([IO.Path]::GetFullPath($pinnedPath))
        $identity.Sha256 | Should Be $pin
        $identity.Version | Should Be $version
        @($identity.ProbeArguments) -join ',' | Should Be '--version'
        $identity.ProbeExitCode | Should Be 0
        $identity.ProbeTimedOut | Should Be $false
    }

    It 'implements the complete preflight capture sanitize cleanup and envelope order' {
        $definition = [string](Get-Command Invoke-Phase00E1EvidenceCase `
            -CommandType Function -ErrorAction Stop).Definition
        $definition | Should Not Match 'provider execution remains disabled'
        foreach ($requiredCall in @(
            'Resolve-Phase00E1PinnedSource',
            'Resolve-Phase00E1PinnedOmpSource',
            'Assert-Phase00E1AttemptDestinations',
            'Get-Phase00E1ProtectedSnapshot',
            'Get-Phase00E1LiveHomeSnapshots',
            'New-Phase00E1DisposableRoot',
            'Initialize-Phase00E1DisposableFixture',
            'Get-Phase00E1OmpArguments',
            'Invoke-Phase00E1CapturedProcess',
            'Protect-Phase00E1EventStream',
            'Protect-Phase00E1TextStream',
            'Get-Phase00E1SessionCaptureInventory',
            'Test-Phase00E1SanitizedArtifacts',
            'Remove-Phase00E1DisposableRoot',
            'Write-Phase00E1RunEnvelope'
        )) {
            $definition | Should Match ([regex]::Escape($requiredCall))
        }
        ($definition.IndexOf('Resolve-Phase00E1PinnedOmpSource',[StringComparison]::Ordinal) -lt
            $definition.IndexOf('New-Phase00E1DisposableRoot',[StringComparison]::Ordinal)) |
            Should Be $true
        ($definition.IndexOf('Resolve-Phase00E1PinnedSource',[StringComparison]::Ordinal) -lt
            $definition.IndexOf('New-Phase00E1DisposableRoot',[StringComparison]::Ordinal)) |
            Should Be $true
        ($definition.IndexOf('Assert-Phase00E1AttemptDestinations',[StringComparison]::Ordinal) -lt
            $definition.IndexOf('New-Phase00E1DisposableRoot',[StringComparison]::Ordinal)) |
            Should Be $true
        ($definition.LastIndexOf('Remove-Phase00E1DisposableRoot',[StringComparison]::Ordinal) -lt
            $definition.LastIndexOf('Write-Phase00E1RunEnvelope',[StringComparison]::Ordinal)) |
            Should Be $true
        $definition | Should Match '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
        $definition | Should Match 'omp/17\.2\.10'
        $definition | Should Not Match 'Test-Phase00E1Attempt|Write-Phase00E1CaseRecord'
        $definition | Should Not Match "'CAPTURED'"
        $definition | Should Match 'case_oracle_evaluated\s*=\s*\$false'
        $definition | Should Match 'case_status\s*=\s*\$null'
    }

    It 'leaves no disposable root or evidence when the executable preflight fails' {
        $runnerPath = Join-Path $repositoryRoot 'scripts\run-phase00-e1.ps1'
        $missingPath = Join-Path ([IO.Path]::GetTempPath()) `
            ('phase00-e1-missing-main-' + [guid]::NewGuid().ToString('N') + '.exe')
        $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        $beforeRoots = @(
            Get-ChildItem -LiteralPath $tempRoot -Directory -Force `
                -Filter 'omp-phase00-e1-*' -ErrorAction SilentlyContinue |
                ForEach-Object { $_.FullName } | Sort-Object
        )
        $rawRoot = Join-Path $repositoryRoot 'docs\evidence\phase-00\E1\raw'
        $rawExistedBefore = Test-Path -LiteralPath $rawRoot
        $error = Get-Phase00E1TestError {
            & $runnerPath -CaseId AgentJtd -Attempt 1 `
                -OmpExecutable $missingPath
        }
        ($null -ne $error) | Should Be $true
        $error.Exception.Message | Should Match '(?i)(does not exist|missing)'
        $afterRoots = @(
            Get-ChildItem -LiteralPath $tempRoot -Directory -Force `
                -Filter 'omp-phase00-e1-*' -ErrorAction SilentlyContinue |
                ForEach-Object { $_.FullName } | Sort-Object
        )
        @($afterRoots) -join "`n" | Should Be (@($beforeRoots) -join "`n")
        (Test-Path -LiteralPath $rawRoot) | Should Be $rawExistedBefore
    }
}

Describe 'Phase 00 E1 runner destination and cleanup containment' {
    It 'refuses overwrite and deletes only a generated strict temp descendant' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $paths = Get-Phase00E1AttemptPaths -RepositoryRoot $testRoot `
                -CaseId AgentJtd -Attempt 1
            $paths.CaseDirectory | Should Be (Join-Path $testRoot 'docs\evidence\phase-00\E1\raw\agent-jtd')
            $paths.StdoutPath | Should Be (Join-Path $paths.CaseDirectory 'attempt-001.stdout.jsonl')
            $paths.StderrPath | Should Be (Join-Path $paths.CaseDirectory 'attempt-001.stderr.jsonl')
            $paths.RunPath | Should Be (Join-Path $paths.CaseDirectory 'attempt-001.run.json')
            $paths.SessionDirectory | Should Be (Join-Path $paths.CaseDirectory 'attempt-001.sessions')
            Assert-Phase00E1AttemptDestinations -Paths $paths

            New-Item -ItemType Directory -Path $paths.CaseDirectory -Force | Out-Null
            [IO.File]::WriteAllText(
                $paths.StdoutPath,
                "PRESERVE_EXISTING_EVIDENCE`n",
                [Text.UTF8Encoding]::new($false)
            )
            $before = (Get-FileHash -LiteralPath $paths.StdoutPath -Algorithm SHA256).Hash
            $existingError = Get-Phase00E1TestError {
                Assert-Phase00E1AttemptDestinations -Paths $paths
            }
            ($null -ne $existingError) | Should Be $true
            $existingError.Exception.Message | Should Match '(?i)(exists|preserve|overwrite)'
            (Get-FileHash -LiteralPath $paths.StdoutPath -Algorithm SHA256).Hash |
                Should Be $before

            $generated = New-Phase00E1DisposableRoot -CaseId AgentJtd -TempRoot $testRoot
            Test-Path -LiteralPath $generated -PathType Container | Should Be $true
            [IO.Path]::GetFileName($generated) | Should Match '^omp-phase00-e1-agent-jtd-[0-9a-f]{32}$'
            [IO.File]::WriteAllText(
                (Join-Path $generated 'owned.tmp'),
                'owned',
                [Text.UTF8Encoding]::new($false)
            )
            Remove-Phase00E1DisposableRoot -Path $generated
            Test-Path -LiteralPath $generated | Should Be $false

            foreach ($unsafe in @($testRoot,[IO.Path]::GetTempPath(),$repositoryRoot)) {
                $unsafeError = Get-Phase00E1TestError {
                    Remove-Phase00E1DisposableRoot -Path $unsafe
                }
                ($null -ne $unsafeError) | Should Be $true
                $unsafeError.Exception.Message | Should Match '(?i)(refus|generated|strict temp)'
            }
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'classifies only sibling markdown outputs as expected session artifacts' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $sessionRoot = Join-Path $testRoot 'sessions'
            $nestedRoot = Join-Path $sessionRoot 'nested'
            New-Item -ItemType Directory -Path $nestedRoot -Force | Out-Null
            foreach ($relativePath in @(
                'controller.jsonl',
                'nested\child.jsonl',
                'nested\child.md',
                'nested\orphan.md',
                'nested\child.patch',
                'unexpected.txt'
            )) {
                $path = Join-Path $sessionRoot $relativePath
                $parent = Split-Path -Parent $path
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
                [IO.File]::WriteAllText($path, '{}', [Text.UTF8Encoding]::new($false))
            }

            $inventory = Get-Phase00E1SessionCaptureInventory `
                -SessionDirectory $sessionRoot

            @($inventory.SessionSources).Count | Should Be 2
            @($inventory.ExpectedOutputArtifacts).Count | Should Be 1
            @($inventory.UnexpectedArtifacts).Count | Should Be 3
            [IO.Path]::GetFileName($inventory.ExpectedOutputArtifacts[0].FullName) |
                Should Be 'child.md'
            @($inventory.UnexpectedArtifacts | ForEach-Object Name | Sort-Object) -join ',' |
                Should Be 'child.patch,orphan.md,unexpected.txt'
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

Describe 'Phase 00 E1 runner concurrent process capture' {
    It 'drains large stdout and stderr concurrently and preserves difficult arguments' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $scriptPath = Join-Path $testRoot 'concurrent-output.mjs'
            $script = @'
const args = process.argv.slice(2);
process.stdout.write(JSON.stringify({ args }) + "\n");
process.stdout.write("O".repeat(1024 * 1024));
process.stderr.write("E".repeat(1024 * 1024));
'@
            [IO.File]::WriteAllText($scriptPath,$script,[Text.UTF8Encoding]::new($false))
            $nodePath = (Get-Command node -CommandType Application -ErrorAction Stop).Source
            $arguments = @($scriptPath,'space value','quote"value','C:\path with space\')
            $result = Invoke-Phase00E1CapturedProcess -FilePath $nodePath `
                -Arguments $arguments -WorkingDirectory $testRoot `
                -EnvironmentSet @{} -EnvironmentRemove @() -TimeoutSeconds 20
            $result.ExitCode | Should Be 0
            $result.TimedOut | Should Be $false
            $result.Stdout.Length -gt (1024 * 1024) | Should Be $true
            $result.Stderr.Length | Should Be (1024 * 1024)
            $firstLine = $result.Stdout.Split(@("`n"),2,[StringSplitOptions]::None)[0] |
                ConvertFrom-Json
            @($firstLine.args) -join '|' | Should Be 'space value|quote"value|C:\path with space\'
            @($result.RemainingChildPids).Count | Should Be 0
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'terminates a timed-out process tree and records no remaining generated child' {
        $testRoot = New-Phase00E1TestDirectory
        $childPid = $null
        try {
            $scriptPath = Join-Path $testRoot 'timeout-tree.mjs'
            $script = @'
import { spawn } from "node:child_process";
const child = spawn(process.execPath, ["-e", "setInterval(() => {}, 1000)"], {
  stdio: "ignore",
  windowsHide: true
});
process.stdout.write(JSON.stringify({ child_pid: child.pid }) + "\n");
setInterval(() => {}, 1000);
'@
            [IO.File]::WriteAllText($scriptPath,$script,[Text.UTF8Encoding]::new($false))
            $nodePath = (Get-Command node -CommandType Application -ErrorAction Stop).Source
            $result = Invoke-Phase00E1CapturedProcess -FilePath $nodePath `
                -Arguments @($scriptPath) -WorkingDirectory $testRoot `
                -EnvironmentSet @{} -EnvironmentRemove @() -TimeoutSeconds 1
            $result.TimedOut | Should Be $true
            $record = $result.Stdout.Trim() | ConvertFrom-Json
            $childPid = [int]$record.child_pid
            @($result.DescendantPidsObserved) -contains $childPid | Should Be $true
            @($result.RemainingChildPids).Count | Should Be 0
            (Get-Process -Id $result.ProcessId -ErrorAction SilentlyContinue) | Should Be $null
            (Get-Process -Id $childPid -ErrorAction SilentlyContinue) | Should Be $null
        } finally {
            if ($null -ne $childPid) {
                $leftover = Get-Process -Id $childPid -ErrorAction SilentlyContinue
                if ($null -ne $leftover) { Stop-Process -Id $childPid -Force }
            }
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

Describe 'Phase 00 E1 runner environment isolation' {
    It 'removes inherited OMP controls and scopes PI_NO_STRICT to only the off arm' {
        $testRoot = New-Phase00E1TestDirectory
        $saved = [ordered]@{}
        $names = @(
            'PI_NO_STRICT','PI_CODING_AGENT_DIR','PI_CONFIG_FILES','PI_CONFIG_DIR',
            'PI_PROFILE','OMP_PROFILE','OMP_AUTH_BROKER_URL','OMP_AUTH_BROKER_TOKEN',
            'NODE_OPTIONS','OMNIROUTE_API_KEY'
        )
        foreach ($name in $names) {
            $saved[$name] = [Environment]::GetEnvironmentVariable($name,'Process')
        }
        try {
            $env:PI_NO_STRICT = 'PARENT_LEAK'
            $env:PI_CODING_AGENT_DIR = 'PARENT_AGENT_LEAK'
            $env:PI_CONFIG_FILES = 'PARENT_CONFIG_LEAK'
            $env:PI_CONFIG_DIR = 'PARENT_DIR_LEAK'
            $env:PI_PROFILE = 'PARENT_PROFILE_LEAK'
            $env:OMP_PROFILE = 'PARENT_OMP_PROFILE_LEAK'
            $env:OMP_AUTH_BROKER_URL = 'https://private.invalid'
            $env:OMP_AUTH_BROKER_TOKEN = 'BROKER_SECRET_MUST_NOT_PERSIST'
            $env:NODE_OPTIONS = '--require=private-hook'
            $env:OMNIROUTE_API_KEY = 'PROVIDER_SECRET_MUST_NOT_PERSIST'

            $agentDirectory = Join-Path $testRoot 'agent-home'
            $runtimeDirectory = Join-Path $testRoot 'runtime'
            New-Item -ItemType Directory -Path $agentDirectory,$runtimeDirectory | Out-Null
            $strictOn = Get-Phase00E1ProcessEnvironment -CaseId ProviderStrictOn `
                -AgentDirectory $agentDirectory -DisposableRoot $testRoot `
                -RuntimeDirectory $runtimeDirectory
            $strictOff = Get-Phase00E1ProcessEnvironment -CaseId ProviderStrictOffControl `
                -AgentDirectory $agentDirectory -DisposableRoot $testRoot `
                -RuntimeDirectory $runtimeDirectory
            foreach ($removed in @(
                'PI_NO_STRICT','PI_CODING_AGENT_DIR','PI_CONFIG_FILES','PI_CONFIG_DIR',
                'PI_PROFILE','OMP_PROFILE','OMP_AUTH_BROKER_URL','OMP_AUTH_BROKER_TOKEN',
                'NODE_OPTIONS'
            )) {
                @($strictOn.RemoveVariables) -contains $removed | Should Be $true
            }
            $strictOn.SetVariables.Contains('PI_NO_STRICT') | Should Be $false
            $strictOff.SetVariables.PI_NO_STRICT | Should Be '1'
            $strictOn.SetVariables.PI_CODING_AGENT_DIR | Should Be ([IO.Path]::GetFullPath($agentDirectory))
            $strictOn.SetVariables.USERPROFILE | Should Be ([IO.Path]::GetFullPath($testRoot))
            $strictOn.SetVariables.HOME | Should Be ([IO.Path]::GetFullPath($testRoot))
            $strictOn.SetVariables.PATH.StartsWith(
                [IO.Path]::GetFullPath($runtimeDirectory) + [IO.Path]::PathSeparator,
                [StringComparison]::OrdinalIgnoreCase
            ) | Should Be $true
            ($strictOn.Record | ConvertTo-Json -Compress -Depth 10) |
                Should Not Match 'PROVIDER_SECRET|BROKER_SECRET|MrThien'

            $scriptPath = Join-Path $testRoot 'show-environment.mjs'
            $script = @'
const names = ["PI_NO_STRICT","PI_CODING_AGENT_DIR","PI_CONFIG_FILES","PI_CONFIG_DIR","PI_PROFILE","OMP_PROFILE","OMP_AUTH_BROKER_URL","OMP_AUTH_BROKER_TOKEN","NODE_OPTIONS","OMNIROUTE_API_KEY","HOME","USERPROFILE"];
process.stdout.write(JSON.stringify(Object.fromEntries(names.map(name => [name, process.env[name] ?? null]))) + "\n");
'@
            [IO.File]::WriteAllText($scriptPath,$script,[Text.UTF8Encoding]::new($false))
            $nodePath = (Get-Command node -CommandType Application -ErrorAction Stop).Source
            $child = Invoke-Phase00E1CapturedProcess -FilePath $nodePath `
                -Arguments @($scriptPath) -WorkingDirectory $testRoot `
                -EnvironmentSet $strictOn.SetVariables `
                -EnvironmentRemove $strictOn.RemoveVariables -TimeoutSeconds 10
            $observed = $child.Stdout.Trim() | ConvertFrom-Json
            $observed.PI_NO_STRICT | Should Be $null
            $observed.PI_CONFIG_FILES | Should Be $null
            $observed.PI_PROFILE | Should Be $null
            $observed.OMP_PROFILE | Should Be $null
            $observed.OMP_AUTH_BROKER_TOKEN | Should Be $null
            $observed.NODE_OPTIONS | Should Be $null
            $observed.OMNIROUTE_API_KEY | Should Be 'PROVIDER_SECRET_MUST_NOT_PERSIST'
            $observed.PI_CODING_AGENT_DIR | Should Be ([IO.Path]::GetFullPath($agentDirectory))
        } finally {
            foreach ($name in $names) {
                [Environment]::SetEnvironmentVariable($name,$saved[$name],'Process')
            }
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

Describe 'Phase 00 E1 runner protected-boundary snapshots' {
    It 'reports the nine product pins with only superseded drift and exposes content and metadata deltas' {
        $protected = Get-Phase00E1ProtectedSnapshot -RepositoryRoot $repositoryRoot `
            -ExpectedHashes (Get-Phase00E1ProtectedHashes)
        $protected.FileCount | Should Be 9
        # Topic 03 retired the five Workflow v0 agents and reshaped the verification schema, so six
        # of the nine historical pins can no longer match live bytes. Asserting nine matches would
        # demand that Phase 00 evidence be rewritten to absorb a later product decision. The honest
        # assertion is that the drift set is exactly the superseded surface and that
        # P00-E1-PROTECTED-SURFACE still passes, through the current-product supersession branch.
        $protected.MatchedCount | Should Be 3
        $protected.AllExpected | Should Be $false
        @($protected.Entries | Where-Object { -not $_.Matched } |
            ForEach-Object { $_.Path } | Sort-Object) -join ',' | Should Be (
                'template/.omp/agents/explorer.md,template/.omp/agents/implementer.md,' +
                'template/.omp/agents/reviewer.md,template/.omp/agents/tech-lead.md,' +
                'template/.omp/agents/verifier.md,' +
                'template/.omp/schemas/verification-result.schema.yml')
        # Defined below this Describe, so resolve the row inline rather than depending on
        # declaration order inside the hosted script.
        @(Test-Phase00E1ArtifactContract -RepositoryRoot $repositoryRoot |
            Where-Object { $_.Code -ceq 'P00-E1-PROTECTED-SURFACE' } |
            ForEach-Object { $_.Status }) -join ',' | Should Be 'PASS'

        $testRoot = New-Phase00E1TestDirectory
        try {
            $firstPath = Join-Path $testRoot 'first.txt'
            $secondPath = Join-Path $testRoot 'second.txt'
            [IO.File]::WriteAllText($firstPath,'first',[Text.UTF8Encoding]::new($false))
            [IO.File]::WriteAllText($secondPath,'second',[Text.UTF8Encoding]::new($false))
            $expected = [ordered]@{
                'first.txt' = (Get-FileHash -LiteralPath $firstPath -Algorithm SHA256).Hash
                'second.txt' = (Get-FileHash -LiteralPath $secondPath -Algorithm SHA256).Hash
            }
            $beforeProtected = Get-Phase00E1ProtectedSnapshot -RepositoryRoot $testRoot `
                -ExpectedHashes $expected
            $beforeDirectory = Get-Phase00E1DirectorySnapshot -Path $testRoot
            Start-Sleep -Milliseconds 20
            [IO.File]::WriteAllText($secondPath,'changed',[Text.UTF8Encoding]::new($false))
            $afterProtected = Get-Phase00E1ProtectedSnapshot -RepositoryRoot $testRoot `
                -ExpectedHashes $expected
            $afterDirectory = Get-Phase00E1DirectorySnapshot -Path $testRoot
            $protectedDelta = Compare-Phase00E1ProtectedSnapshot `
                -Before $beforeProtected -After $afterProtected
            $directoryDelta = Compare-Phase00E1DirectorySnapshot `
                -Before $beforeDirectory -After $afterDirectory
            $protectedDelta.Unchanged | Should Be $false
            @($protectedDelta.ChangedPaths) -join ',' | Should Be 'second.txt'
            $afterProtected.AllExpected | Should Be $false
            $directoryDelta.Unchanged | Should Be $false
            @($directoryDelta.ChangedPaths) -join ',' | Should Be 'second.txt'
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'detects bounded live-home changes without exposing live paths in the comparison' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $liveHome = Join-Path $testRoot 'live-agent-home'
            New-Item -ItemType Directory -Path $liveHome | Out-Null
            [IO.File]::WriteAllText(
                (Join-Path $liveHome 'settings.json'),
                '{"before":true}',
                [Text.UTF8Encoding]::new($false)
            )
            $surfaces = @([pscustomobject][ordered]@{
                Id = 'LIVE_HOME_1'
                Path = $liveHome
            })
            $before = Get-Phase00E1LiveHomeSnapshots -Surfaces $surfaces
            $unchanged = Compare-Phase00E1LiveHomeSnapshots -Before $before -After `
                (Get-Phase00E1LiveHomeSnapshots -Surfaces $surfaces)
            $unchanged.Unchanged | Should Be $true
            $unchanged.ChangedCount | Should Be 0

            [IO.File]::AppendAllText(
                (Join-Path $liveHome 'settings.json'),
                "`n",
                [Text.UTF8Encoding]::new($false)
            )
            $changed = Compare-Phase00E1LiveHomeSnapshots -Before $before -After `
                (Get-Phase00E1LiveHomeSnapshots -Surfaces $surfaces)
            $changed.Unchanged | Should Be $false
            $changed.ChangedCount | Should Be 1
            @($changed.Surfaces).Count | Should Be 1
            $changed.Surfaces[0].Id | Should Be 'LIVE_HOME_1'
            (($changed | ConvertTo-Json -Depth 20) -match [regex]::Escape($liveHome)) |
                Should Be $false
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

Describe 'Phase 00 E1 runner disposable fixture and exact OMP wire' {
    It 'copies only pinned fixtures/runtime/model and never selects the repository cwd' {
        $testRoot = New-Phase00E1TestDirectory
        $disposableRoot = $null
        try {
            $pin = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
            $pinnedPath = 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
            $identity = [pscustomobject][ordered]@{
                Path = [IO.Path]::GetFullPath($pinnedPath)
                Sha256 = $pin
                Version = 'omp/17.2.10'
            }
            $disposableRoot = New-Phase00E1DisposableRoot `
                -CaseId ProviderStrictOn -TempRoot $testRoot
            $fixture = Initialize-Phase00E1DisposableFixture `
                -Root $disposableRoot -RepositoryRoot $repositoryRoot `
                -RuntimeIdentity $identity `
                -ProviderBaseUrl 'http://127.0.0.1:43123/v1'

            $fixture.ProjectRoot | Should Not Be ([IO.Path]::GetFullPath($repositoryRoot))
            $fixture.ProjectRoot.StartsWith(
                [IO.Path]::GetFullPath($disposableRoot) + [IO.Path]::DirectorySeparatorChar,
                [StringComparison]::OrdinalIgnoreCase
            ) | Should Be $true
            @(Get-ChildItem -LiteralPath (Join-Path $fixture.ProjectRoot '.omp\agents') -File).Count |
                Should Be 7
            @(Get-ChildItem -LiteralPath (Join-Path $fixture.ProjectRoot 'prompts') -File).Count |
                Should Be 6
            (Get-FileHash -LiteralPath $fixture.RuntimeExecutable -Algorithm SHA256).Hash |
                Should Be $pin
            $fixture.RuntimeVersion | Should Be 'omp/17.2.10'
            $fixture.SourceFixtureMatched | Should Be $true
            $fixture.CopiedFixtureMatched | Should Be $true
            $fixture.ModelCatalogText | Should Match 'baseUrl: http://127\.0\.0\.1:43123/v1'
            $fixture.ModelCatalogText | Should Match 'id: codex/gpt-5\.6-sol-high'
            $fixture.ModelCatalogText | Should Not Match '20128|PROVIDER_SECRET|Bearer '

            $promptPath = Join-Path $fixture.ProjectRoot 'prompts\provider-strict.md'
            $prompt = [IO.File]::ReadAllText($promptPath)
            $arguments = Get-Phase00E1OmpArguments `
                -DisposableProject $fixture.ProjectRoot `
                -SessionDirectory $fixture.SessionDirectory `
                -ConfigPath $fixture.ConfigPath `
                -Model 'omniroute/codex/gpt-5.6-sol-high' `
                -PromptText $prompt -RepositoryRoot $repositoryRoot
            @($arguments) -join "`n" | Should Be (@(
                '-p','--mode','json',
                '--cwd',$fixture.ProjectRoot,
                '--session-dir',$fixture.SessionDirectory,
                '--config',$fixture.ConfigPath,
                '--model','omniroute/codex/gpt-5.6-sol-high',
                '--tools','task',
                '--approval-mode','yolo',
                '--max-time','8m',
                '--no-extensions','--no-skills','--no-rules','--no-lsp','--no-title',
                $prompt
            ) -join "`n")
            @($arguments | Where-Object { $_ -eq '--tools' }).Count | Should Be 1
            $arguments[[Array]::IndexOf($arguments,'--tools') + 1] | Should Be 'task'
            (@($arguments) -contains 'eval') | Should Be $false
            (@($arguments) -contains 'bash') | Should Be $false

            $cwdError = Get-Phase00E1TestError {
                Get-Phase00E1OmpArguments -DisposableProject $repositoryRoot `
                    -SessionDirectory $fixture.SessionDirectory `
                    -ConfigPath $fixture.ConfigPath `
                    -Model 'omniroute/codex/gpt-5.6-sol-high' `
                    -PromptText $prompt -RepositoryRoot $repositoryRoot
            }
            ($null -ne $cwdError) | Should Be $true
            $cwdError.Exception.Message | Should Match '(?i)(repository|disposable)'
        } finally {
            if ($null -ne $disposableRoot -and (Test-Path -LiteralPath $disposableRoot)) {
                Remove-Phase00E1DisposableRoot -Path $disposableRoot
            }
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

Describe 'Phase 00 E1 runner sanitized capture verification' {
    It 'creates new parseable line-preserving artifacts linked to source hashes without secrets' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $captureRoot = Join-Path $testRoot 'capture'
            $artifactRoot = Join-Path $testRoot 'artifacts'
            New-Item -ItemType Directory -Path $captureRoot,$artifactRoot | Out-Null
            $stdoutSource = Join-Path $captureRoot 'stdout.jsonl'
            $stderrSource = Join-Path $captureRoot 'stderr.txt'
            $stdoutDestination = Join-Path $artifactRoot 'stdout.jsonl'
            $stderrDestination = Join-Path $artifactRoot 'stderr.jsonl'
            Write-Phase00E1TestJsonLines -Path $stdoutSource -Objects @(
                [ordered]@{
                    type='tool_execution_end'; toolName='task'
                    authorization='Bearer PROVIDER_SECRET_MUST_NOT_PERSIST'
                    result=[ordered]@{details=[ordered]@{results=@([ordered]@{
                        id='e1';agent='phase00-e1-agent-jtd';structuredOutput=[ordered]@{
                            source='agent';mode='permissive';status='valid';data=[ordered]@{sentinel='E1_AGENT_JTD'}
                        }
                    })}}
                },
                [ordered]@{type='agent_end';isTerminal=$true;stopReason='stop'}
            )
            [IO.File]::WriteAllText(
                $stderrSource,
                "warning one`nAuthorization: Bearer PROVIDER_SECRET_MUST_NOT_PERSIST`n",
                [Text.UTF8Encoding]::new($false)
            )
            $fixtureHashes = [ordered]@{prompt=('A' * 64);agent=('B' * 64)}
            $stdoutArtifact = Protect-Phase00E1EventStream `
                -SourcePath $stdoutSource -DestinationPath $stdoutDestination `
                -RepositoryRoot $repositoryRoot -DisposableRoot $testRoot `
                -FixtureHashes $fixtureHashes
            $stderrArtifact = Protect-Phase00E1TextStream `
                -SourcePath $stderrSource -DestinationPath $stderrDestination
            @($stdoutArtifact.ProcessingErrorLines).Count | Should Be 0
            @($stderrArtifact.ProcessingErrorLines).Count | Should Be 0
            $verification = Test-Phase00E1SanitizedArtifacts -Artifacts @(
                [pscustomobject]@{Path=$stdoutDestination;Metadata=$stdoutArtifact},
                [pscustomobject]@{Path=$stderrDestination;Metadata=$stderrArtifact}
            ) -SecretValues @('PROVIDER_SECRET_MUST_NOT_PERSIST')
            $verification.Status | Should Be 'PASS'
            $verification.ReasonCodes.Count | Should Be 0
            $verification.ArtifactCount | Should Be 2
            $verification.TotalSourceLines | Should Be 4
            $verification.TotalSanitizedLines | Should Be 4
            $persisted = [IO.File]::ReadAllText($stdoutDestination) +
                [IO.File]::ReadAllText($stderrDestination)
            $persisted | Should Not Match 'PROVIDER_SECRET_MUST_NOT_PERSIST|warning one'
            @(Get-Content -LiteralPath $stdoutDestination | ForEach-Object {
                $_ | ConvertFrom-Json
            }).Count | Should Be 2
            @(Get-Content -LiteralPath $stderrDestination | ForEach-Object {
                $_ | ConvertFrom-Json
            }).Count | Should Be 2

            [IO.File]::AppendAllText(
                $stderrDestination,
                "NOT_JSON`n",
                [Text.UTF8Encoding]::new($false)
            )
            $mutated = Test-Phase00E1SanitizedArtifacts -Artifacts @(
                [pscustomobject]@{Path=$stderrDestination;Metadata=$stderrArtifact}
            ) -SecretValues @('PROVIDER_SECRET_MUST_NOT_PERSIST')
            $mutated.Status | Should Be 'INVALID_RUN'
            @($mutated.ReasonCodes) -contains 'E1_SANITIZED_ARTIFACT_HASH_MISMATCH' |
                Should Be $true
            @($mutated.ReasonCodes) -contains 'E1_SANITIZED_ARTIFACT_UNPARSEABLE' |
                Should Be $true
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'writes a new private-path-free run envelope and refuses overwrite or secret leakage' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $path = Join-Path $testRoot 'attempt-001.run.json'
            $secret = 'E1_ENVELOPE_SECRET_7F2A9C'
            $envelope = [ordered]@{
                record_type = 'phase00_e1_run'
                capture_integrity_status = 'PASS'
                case_status = $null
                case_oracle_evaluated = $false
                artifact = 'raw/agent-jtd/attempt-001.stdout.jsonl'
            }
            $metadata = Write-Phase00E1RunEnvelope -Path $path -Envelope $envelope `
                -SecretValues @($secret) -PrivatePaths @($testRoot)
            $metadata.Sha256 | Should Match '^[0-9A-F]{64}$'
            $metadata.Length | Should BeGreaterThan 0
            $parsed = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
            $parsed.record_type | Should Be 'phase00_e1_run'

            $overwriteError = Get-Phase00E1TestError {
                Write-Phase00E1RunEnvelope -Path $path -Envelope $envelope `
                    -SecretValues @($secret) -PrivatePaths @($testRoot)
            }
            ($null -ne $overwriteError) | Should Be $true

            $privatePath = Join-Path $testRoot 'private.run.json'
            $privateError = Get-Phase00E1TestError {
                Write-Phase00E1RunEnvelope -Path $privatePath `
                    -Envelope ([ordered]@{ value=$testRoot }) `
                    -SecretValues @($secret) -PrivatePaths @($testRoot)
            }
            ($null -ne $privateError) | Should Be $true
            (Test-Path -LiteralPath $privatePath) | Should Be $false

            $secretPath = Join-Path $testRoot 'secret.run.json'
            $secretError = Get-Phase00E1TestError {
                Write-Phase00E1RunEnvelope -Path $secretPath `
                    -Envelope ([ordered]@{ value=$secret }) `
                    -SecretValues @($secret) -PrivatePaths @($testRoot)
            }
            ($null -ne $secretError) | Should Be $true
            (Test-Path -LiteralPath $secretPath) | Should Be $false

            $escapedSecret = 'E1\SECRET"VALUE'
            $escapedSecretPath = Join-Path $testRoot 'escaped-secret.run.json'
            $escapedSecretError = Get-Phase00E1TestError {
                Write-Phase00E1RunEnvelope -Path $escapedSecretPath `
                    -Envelope ([ordered]@{ value=$escapedSecret }) `
                    -SecretValues @($escapedSecret) -PrivatePaths @($testRoot)
            }
            ($null -ne $escapedSecretError) | Should Be $true
            (Test-Path -LiteralPath $escapedSecretPath) | Should Be $false
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

Describe 'Phase 00 E1 runner strict forwarder lifecycle' {
    It 'starts and closes the pinned forwarder without contacting the gateway' {
        $testRoot = New-Phase00E1TestDirectory
        $handle = $null
        try {
            $outputPath = Join-Path $testRoot 'forwarder.ndjson'
            $handle = Start-Phase00E1Forwarder -RepositoryRoot $repositoryRoot `
                -OutputPath $outputPath -PiNoStrictEffective $false `
                -TargetOrigin 'http://127.0.0.1:20128'
            $handle.ListenHost | Should Be '127.0.0.1'
            $handle.ListenPort | Should BeGreaterThan 0
            $result = Stop-Phase00E1Forwarder -Handle $handle
            $handle = $null
            $result.ExitCode | Should Be 0
            $result.TimedOut | Should Be $false
            $result.PortClosed | Should Be $true
            $result.ProjectionCount | Should Be 0
            $result.StderrSha256 | Should Be `
                (Get-Phase00E1StringSha256 -Text '')
            @($result.RecordTypes) -join ',' | Should Be `
                'phase00_e1_forwarder_ready,phase00_e1_forwarder_closed'
        } finally {
            if ($null -ne $handle) {
                try { $null = Stop-Phase00E1Forwarder -Handle $handle } catch {}
            }
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }
}

function Get-Phase00E1ProjectionTestJsonBlock {
    param([Parameter(Mandatory)][string]$Path)

    $text = [IO.File]::ReadAllText($Path).Replace("`r`n","`n")
    $matches = [regex]::Matches($text,'(?ms)^```json\n(?<json>\{.*?\})\n```$')
    if ($matches.Count -ne 1) {
        throw "Expected one JSON block in projection fixture: $Path"
    }
    return $matches[0].Groups['json'].Value | ConvertFrom-Json
}

function New-Phase00E1ProjectionTestArtifact {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$Kind,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][Collections.IDictionary]$FixtureHashes
    )

    $lineCount = 0
    foreach ($null in [IO.File]::ReadLines($Path)) { $lineCount += 1 }
    $metadata = [ordered]@{
        Status = 'PASS'
        ReasonCodes = @()
        SourceCaptureSha256 = ('C' * 64)
        SanitizedOutputSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
        SourceLineCount = $lineCount
        SanitizedLineCount = $lineCount
        MalformedLines = @()
        InvalidShapeLines = @()
        ProcessingErrorLines = @()
        CredentialLines = @()
        FixtureHashes = if ($Kind -eq 'stderr') { [ordered]@{} } else { $FixtureHashes }
    }
    return [pscustomobject][ordered]@{
        kind = $Kind
        path = Get-Phase00E1RepositoryRelativePath `
            -RepositoryRoot $RepositoryRoot -Path $Path
        source_relative_path_sha256 = if ($Kind -eq 'session') {
            Get-Phase00E1StringSha256 -Text ([IO.Path]::GetFileName($Path))
        } else { $null }
        metadata = $metadata
    }
}

function New-Phase00E1ProjectionTestFixture {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn')]
        [string]$CaseId,
        [string]$Root,
        [switch]$RecoveredRetry,
        [switch]$TerminalQuota,
        [switch]$DuplicateResult,
        [switch]$CarrierSubstitution
    )

    if ([string]::IsNullOrWhiteSpace($Root)) {
        $Root = New-Phase00E1TestDirectory
    } else {
        $Root = [IO.Path]::GetFullPath($Root)
    }
    $fixtureDestination = Join-Path $Root 'docs\evidence\phase-00\E1\fixture'
    if (-not (Test-Path -LiteralPath $fixtureDestination -PathType Container)) {
        [IO.Directory]::CreateDirectory((Split-Path -Parent $fixtureDestination)) | Out-Null
        Copy-Item -LiteralPath (Join-Path $repositoryRoot `
            'docs\evidence\phase-00\E1\fixture') `
            -Destination $fixtureDestination -Recurse
    }

    $definition = Get-Phase00E1CaseDefinition -CaseId $CaseId
    $paths = Get-Phase00E1AttemptPaths -RepositoryRoot $Root `
        -CaseId $CaseId -Attempt 1
    [IO.Directory]::CreateDirectory($paths.CaseDirectory) | Out-Null
    [IO.Directory]::CreateDirectory($paths.SessionDirectory) | Out-Null
    $fixtureHashes = Get-Phase00E1ExpectedFixtureHashes
    $promptPath = Join-Path $fixtureDestination `
        ([string]$definition.PromptRelativePath)
    $controllerArguments = Get-Phase00E1ProjectionTestJsonBlock -Path $promptPath

    $resultAgent = if ($CaseId -eq 'SessionOnly') {
        'phase00-e1-session-leaf'
    } else { [string]$definition.Agent }
    $resultData = [ordered]@{}
    $resultData[[string]$definition.ExpectedSentinelProperty] = `
        [string]$definition.ExpectedSentinel
    $selectedResult = [ordered]@{
        index = 0
        id = "$CaseId-result"
        agent = $resultAgent
        agentSource = 'project'
        exitCode = 0
        aborted = $false
        requests = if ($RecoveredRetry) { 2 } elseif (
            $CaseId -eq 'ProviderStrictOffControl') { 2 } else { 1 }
        structuredOutput = [ordered]@{
            source = [string]$definition.Source
            mode = [string]$definition.Mode
            status = 'valid'
            data = $resultData
        }
    }
    if ($TerminalQuota) {
        $selectedResult['retryFailure'] = [ordered]@{
            attempt=1; errorMessage='quota exhausted'
        }
    }

    $outerResult = $selectedResult
    if ($CaseId -eq 'SessionOnly') {
        $outerResult = [ordered]@{
            index = 0
            id = 'SessionOnly-carrier-result'
            agent = 'phase00-e1-session-carrier'
            agentSource = 'project'
            exitCode = 0
            aborted = $false
            requests = 1
            structuredOutput = [ordered]@{
                source='caller'; mode='permissive'; status='valid'
                data=[ordered]@{ session_sentinel='E1_SESSION_ONLY' }
            }
            extractedToolData = [ordered]@{
                task = @([ordered]@{
                    results = @($selectedResult)
                    totalDurationMs = 20
                })
            }
        }
    }
    $stdoutResults = @($outerResult)
    if ($DuplicateResult) {
        $duplicate = $outerResult | ConvertTo-Json -Depth 50 | ConvertFrom-Json
        $duplicate.id = "$CaseId-duplicate-result"
        $stdoutResults += $duplicate
    }

    $controllerFirst = [ordered]@{
        role='assistant'; provider='omniroute'; model='codex/gpt-5.6-sol-high'
        stopReason='toolUse'; content=@([ordered]@{
            type='toolCall'; id='controller-task'; name='task'
            arguments=$controllerArguments
        })
    }
    $controllerFinal = [ordered]@{
        role='assistant'; provider='omniroute'; model='codex/gpt-5.6-sol-high'
        stopReason='stop'; content=@()
    }
    Write-Phase00E1TestJsonLines -Path $paths.StdoutPath -Objects @(
        [ordered]@{ type='session'; version=3; id='controller-session' },
        [ordered]@{ type='message_start'; message=$controllerFirst },
        [ordered]@{ type='message_end'; message=$controllerFirst },
        [ordered]@{
            type='tool_execution_start'; toolCallId='controller-task'
            toolName='task'; args=$controllerArguments
        },
        [ordered]@{
            type='tool_execution_end'; toolCallId='controller-task'; toolName='task'
            result=[ordered]@{
                content=@([ordered]@{type='text';text=[ordered]@{redacted='private_message_content'}})
                details=[ordered]@{
                    projectAgentsDir='<E1_DISPOSABLE_ROOT>/.omp/agents'
                    results=$stdoutResults
                    totalDurationMs=50
                }
            }
            isError=$false
        },
        [ordered]@{ type='message_start'; message=$controllerFinal },
        [ordered]@{ type='message_end'; message=$controllerFinal },
        [ordered]@{ type='agent_end'; isTerminal=$true; messages=@($controllerFinal) }
    )
    [IO.File]::WriteAllText($paths.StderrPath,'',[Text.UTF8Encoding]::new($false))

    $mainSessionPath = Join-Path $paths.SessionDirectory 'session-001.jsonl'
    Write-Phase00E1TestJsonLines -Path $mainSessionPath -Objects @(
        [ordered]@{type='session';version=3;id='controller-session'},
        [ordered]@{type='message';message=$controllerFirst},
        [ordered]@{
            type='message';message=[ordered]@{
                role='toolResult';toolCallId='controller-task';toolName='task'
                isError=$false
                content=@([ordered]@{type='text';text=[ordered]@{redacted='private_message_content'}})
                details=[ordered]@{results=$stdoutResults;totalDurationMs=50}
            }
        },
        [ordered]@{type='message';message=$controllerFinal}
    )

    $sessionPaths = [Collections.Generic.List[string]]::new()
    $sessionPaths.Add($mainSessionPath)
    $targetSessionPath = $null
    if ($CaseId -eq 'SessionOnly') {
        $carrierPath = Join-Path $paths.SessionDirectory 'session-002.jsonl'
        $carrierAgentPath = Join-Path $fixtureDestination `
            'agents\phase00-e1-session-carrier.md'
        $nestedArguments = Get-Phase00E1ProjectionTestJsonBlock -Path $carrierAgentPath
        $carrierAssistant = [ordered]@{
            role='assistant'; provider='omniroute'; model='codex/gpt-5.6-sol-high'
            stopReason='toolUse'; content=@([ordered]@{
                type='toolCall'; id='nested-task'; name='task'; arguments=$nestedArguments
            })
        }
        $nestedResult = if ($CarrierSubstitution) { $outerResult } else { $selectedResult }
        Write-Phase00E1TestJsonLines -Path $carrierPath -Objects @(
            [ordered]@{type='session';version=3;id='carrier-session'},
            [ordered]@{
                type='session_init'; agent='phase00-e1-session-carrier'
                resolvedModel='omniroute/codex/gpt-5.6-sol-high'
                systemPrompt=[ordered]@{redacted='private_content'}
                task=[ordered]@{redacted='private_content'}
            },
            [ordered]@{type='message';message=$carrierAssistant},
            [ordered]@{
                type='message'; message=[ordered]@{
                    role='toolResult'; toolCallId='nested-task'; toolName='task'
                    isError=$false; content=@([ordered]@{type='text';text=[ordered]@{redacted='private_message_content'}})
                    details=[ordered]@{results=@($nestedResult);totalDurationMs=20}
                }
            }
        )
        $sessionPaths.Add($carrierPath)
        $targetSessionPath = Join-Path $paths.SessionDirectory 'session-003.jsonl'
    } else {
        $targetSessionPath = Join-Path $paths.SessionDirectory 'session-002.jsonl'
    }

    $targetRecords = [Collections.Generic.List[object]]::new()
    $targetRecords.Add([ordered]@{type='session';version=3;id="$CaseId-session"})
    $targetRecords.Add([ordered]@{
        type='session_init'; agent=$resultAgent
        resolvedModel='omniroute/codex/gpt-5.6-sol-high'
        systemPrompt=[ordered]@{redacted='private_content'}
        task=[ordered]@{redacted='private_content'}
    })
    if ($TerminalQuota) {
        $targetRecords.Add([ordered]@{
            type='message'; message=[ordered]@{
                role='assistant'; provider='omniroute'; model='codex/gpt-5.6-sol-high'
                stopReason='error'; errorMessage='quota exhausted'; content=@()
            }
        })
    } else {
        if ($RecoveredRetry) {
            $targetRecords.Add([ordered]@{
                type='message'; message=[ordered]@{
                    role='assistant'; provider='omniroute'; model='codex/gpt-5.6-sol-high'
                    stopReason='error'; errorMessage='server_is_overloaded'; content=@()
                    retryRecovery=[ordered]@{
                        kind='auto-retry'; status='recovered'; attempt=1
                        recoveredAt='2026-08-10T00:00:01Z'
                        supersededBy=[ordered]@{
                            provider='omniroute';model='codex/gpt-5.6-sol-high'
                            responseId='recovered-response'
                        }
                    }
                }
            })
        }
        $strictOff = $CaseId -eq 'ProviderStrictOffControl'
        $firstData = if ($strictOff) {
            [ordered]@{
                allowed='E1_STRICT_FORBIDDEN'
                forbidden_extra='E1_FORBIDDEN_EXTRA'
            }
        } else { $resultData }
        $firstAssistant = [ordered]@{
            role='assistant'; provider='omniroute'; model='codex/gpt-5.6-sol-high'
            stopReason='toolUse'; content=@([ordered]@{
                type='toolCall'; id='target-yield-1'; name='yield'
                arguments=[ordered]@{result=[ordered]@{data=$firstData}}
            })
        }
        $targetRecords.Add([ordered]@{type='message';message=$firstAssistant})
        $targetRecords.Add([ordered]@{
            type='message'; message=[ordered]@{
                role='toolResult'; toolCallId='target-yield-1'; toolName='yield'
                isError=$strictOff
                content=@([ordered]@{type='text';text=[ordered]@{redacted='private_message_content'}})
                e1_tool_error_classification=if ($strictOff) {'yield_schema_validation'} else {$null}
                details=if ($strictOff) {$null} else {
                    [ordered]@{data=$firstData;status='success'}
                }
            }
        })
        if ($strictOff) {
            $secondData = [ordered]@{allowed='E1_STRICT_ALLOWED'}
            $secondAssistant = [ordered]@{
                role='assistant'; provider='omniroute'; model='codex/gpt-5.6-sol-high'
                stopReason='toolUse'; content=@([ordered]@{
                    type='toolCall'; id='target-yield-2'; name='yield'
                    arguments=[ordered]@{result=[ordered]@{data=$secondData}}
                })
            }
            $targetRecords.Add([ordered]@{type='message';message=$secondAssistant})
            $targetRecords.Add([ordered]@{
                type='message'; message=[ordered]@{
                    role='toolResult'; toolCallId='target-yield-2'; toolName='yield'
                    isError=$false
                    content=@([ordered]@{type='text';text=[ordered]@{redacted='private_message_content'}})
                    details=[ordered]@{data=$secondData;status='success'}
                }
            })
        }
    }
    Write-Phase00E1TestJsonLines -Path $targetSessionPath `
        -Objects ([object[]]@($targetRecords))
    $sessionPaths.Add($targetSessionPath)

    $forwarderProjectionCount = 0
    if ($CaseId -in @('ProviderStrictOffControl','ProviderStrictOn')) {
        $isOff = $CaseId -eq 'ProviderStrictOffControl'
        $projectionRecords = [Collections.Generic.List[object]]::new()
        $projectionRecords.Add([ordered]@{
            record_type='phase00_e1_forwarder_ready';listen_host='127.0.0.1';listen_port=32123
        })
        $childRequestCount = if ($isOff) { 2 } else { 1 }
        $globalCount = $childRequestCount + 2
        for ($index = 1; $index -le $globalCount; $index += 1) {
            $isChild = $index -ge 2 -and $index -lt (2 + $childRequestCount)
            $projectionRecords.Add([ordered]@{
                record_type='phase00_e1_request_projection'
                request_index=$index
                request_path='/v1/responses'
                forwarded=$true
                gateway_http_status=200
                gateway='omniroute'
                api='openai-responses'
                yield_tool_present=$isChild
                yield_strict_field_present=($isChild -and -not $isOff)
                yield_strict=if ($isChild -and -not $isOff) {$true} else {$null}
                yield_parameters_sha256=if ($isChild) {
                    if ($isOff) {
                        'DB58E598EDFCAAB815558716F24EED4D61FD2B9F5057608E8409C6369B234EEE'
                    } else {
                        'BA45FA65ACE1C6653B74557015A2993085CF72FAF126D2CB01A76553DE05279C'
                    }
                } else {$null}
                allowed_data_properties=if ($isChild) {@('allowed')} else {@()}
                required_data_properties=if ($isChild) {@('allowed')} else {@()}
                data_additional_properties=if ($isChild) {$false} else {$null}
                pi_no_strict_effective=$isOff
            })
        }
        $projectionRecords.Add([ordered]@{
            record_type='phase00_e1_forwarder_closed';listen_host='127.0.0.1';listen_port=32123
        })
        Write-Phase00E1TestJsonLines -Path $paths.ForwarderPath `
            -Objects ([object[]]@($projectionRecords))
        $forwarderProjectionCount = $globalCount
    }

    $artifactRecords = [Collections.Generic.List[object]]::new()
    $artifactRecords.Add((New-Phase00E1ProjectionTestArtifact `
        -RepositoryRoot $Root -Kind stdout -Path $paths.StdoutPath `
        -FixtureHashes $fixtureHashes))
    $artifactRecords.Add((New-Phase00E1ProjectionTestArtifact `
        -RepositoryRoot $Root -Kind stderr -Path $paths.StderrPath `
        -FixtureHashes $fixtureHashes))
    foreach ($sessionPath in $sessionPaths) {
        $artifactRecords.Add((New-Phase00E1ProjectionTestArtifact `
            -RepositoryRoot $Root -Kind session -Path $sessionPath `
            -FixtureHashes $fixtureHashes))
    }
    if ($forwarderProjectionCount -gt 0) {
        $artifactRecords.Add((New-Phase00E1ProjectionTestArtifact `
            -RepositoryRoot $Root -Kind forwarder -Path $paths.ForwarderPath `
            -FixtureHashes $fixtureHashes))
    }
    $totalLines = 0
    foreach ($artifact in $artifactRecords) {
        $totalLines += [int]$artifact.metadata.SanitizedLineCount
    }
    $envelope = [ordered]@{
        record_type='phase00_e1_run'
        schema_version=1
        case_id=$CaseId
        case_slug=Get-Phase00E1CaseSlug -CaseId $CaseId
        attempt=1
        execution_order=[int]$definition.ExecutionOrder
        capture_integrity_status='PASS'
        case_status=$null
        case_oracle_evaluated=$false
        reason_codes=@()
        pinned_source=[ordered]@{
            source_root='<E1_REPOSITORY_ROOT>/_research/upstreams/oh-my-pi'
            commit='3a8591a8af5b6d200088d12ca75a5517cb064fa8';clean=$true
            origin='https://github.com/can1357/oh-my-pi.git'
        }
        pinned_runtime=[ordered]@{
            sha256='1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
            version='omp/17.2.10';version_probe_arguments=@('--version')
            version_probe_exit_code=0;version_probe_timed_out=$false
        }
        fixture=[ordered]@{
            source_fixture_matched=$true;copied_fixture_matched=$true
            fixture_hashes=$fixtureHashes
            model_catalog_sha256=('D' * 64)
            runtime_source_sha256='1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
            runtime_copied_sha256='1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
            runtime_version='omp/17.2.10'
        }
        command=[ordered]@{
            executable='<E1_DISPOSABLE_ROOT>/runtime/omp.exe'
            arguments=@();prompt_sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $promptPath).Hash
            model='omniroute/codex/gpt-5.6-sol-high';launch_invoked=$true
        }
        environment=[ordered]@{
            PI_NO_STRICT=if ($CaseId -eq 'ProviderStrictOffControl') {'1'} else {'<ABSENT>'}
        }
        process=[ordered]@{
            process_id=12345;exit_code=0;timed_out=$false
            descendant_pids_observed=@();remaining_child_pids=@()
        }
        artifacts=[object[]]@($artifactRecords)
        session_capture=[ordered]@{
            jsonl_source_count=$sessionPaths.Count;unexpected_file_count=0
        }
        capture_verification=[ordered]@{
            Status='PASS';ReasonCodes=@();ArtifactCount=$artifactRecords.Count
            TotalSourceLines=$totalLines;TotalSanitizedLines=$totalLines
        }
        provider_observations=[ordered]@{
            per_artifact=@();counts_are_per_artifact_not_deduplicated=$true
        }
        forwarder=if ($forwarderProjectionCount -eq 0) {
            [ordered]@{required=$false;artifact_present=$false}
        } else {
            [ordered]@{
                required=$true;pi_no_strict_effective=($CaseId -eq 'ProviderStrictOffControl')
                target_origin='http://127.0.0.1:20128'
                source_sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath `
                    (Join-Path $repositoryRoot 'scripts\lib\phase00-e1-forwarder.mjs')).Hash
                node_sha256=('E' * 64)
                exit_code=0;timed_out=$false;remaining_child_pids=@()
                listen_host='127.0.0.1';listen_port=32123;port_closed=$true
                projection_count=$forwarderProjectionCount
                record_count=$forwarderProjectionCount + 2
                lifecycle_valid=$true;artifact_present=$true
            }
        }
        protected_repository=[ordered]@{
            unchanged=$true;before_all_expected=$true;after_all_expected=$true
            changed_paths=@();changed_count=0
        }
        live_agent_home=[ordered]@{Unchanged=$true;ChangedCount=0;Surfaces=@()}
        cleanup=[ordered]@{Required=$true;Attempted=$true;Succeeded=$true;ErrorType=$null}
        operation_error_type=$null
    }
    Write-Phase00E1TestJson -Path $paths.RunPath -Value $envelope
    return [pscustomobject][ordered]@{
        Root=$Root;Paths=$paths;Envelope=$envelope
        SessionPaths=[string[]]@($sessionPaths)
        TargetSessionPath=$targetSessionPath
    }
}

Describe 'Phase 00 E1 raw-artifact attempt projection' {
    It 'projects an ordinary attempt from the selected child session without controller double counting' {
        $fixture = New-Phase00E1ProjectionTestFixture -CaseId AgentJtd
        try {
            $evidence = Read-Phase00E1AttemptEvidence `
                -RepositoryRoot $fixture.Root -CaseId AgentJtd -Attempt 1
            $analysis = Test-Phase00E1Attempt -CaseId AgentJtd `
                -AttemptEvidence $evidence

            $evidence.ProjectionStatus | Should Be 'PASS'
            $evidence.ProviderLedger.RequestCount | Should Be 1
            $evidence.ProcessProviderLedger.RequestCount | Should Be 3
            $summaries = @(Get-Phase00E1ProviderObservationSummaries `
                -Artifacts @($evidence.VerifiedRun.Artifacts) `
                -RepositoryRoot $fixture.Root)
            @($summaries | Where-Object {
                $_.Artifact -match '/attempt-001\.sessions/'
            } | Measure-Object -Property RequestCount -Sum).Sum | Should Be 3
            $evidence.AttributableResults.Count | Should Be 1
            $evidence.AttributableResults[0].Agent | Should Be 'phase00-e1-agent-jtd'
            $evidence.CaseFacts.CallerSchemaState | Should Be 'ABSENT'
            $evidence.CaseFacts.AgentSchemaDialect | Should Be 'JTD'
            $analysis.Status | Should Be 'PASS'
            @($evidence.RunRecord.RawArtifacts).Count | Should Be 5
            @($evidence.RunRecord.RequiredEventAnchors).Count | Should BeGreaterThan 3
        } finally {
            Remove-Phase00E1TestDirectory -Path $fixture.Root
        }
    }

    It 'normalizes a recovered persisted-session provider error as superseded' {
        $fixture = New-Phase00E1ProjectionTestFixture `
            -CaseId AgentJtd -RecoveredRetry
        try {
            $evidence = Read-Phase00E1AttemptEvidence `
                -RepositoryRoot $fixture.Root -CaseId AgentJtd -Attempt 1
            $evidence.ProviderLedger.RequestCount | Should Be 2
            $evidence.ProviderLedger.RecoveredRetryCount | Should Be 1
            $evidence.ProviderLedger.TerminalFailure.Found | Should Be $false
            (Test-Phase00E1Attempt -CaseId AgentJtd `
                -AttemptEvidence $evidence).Status | Should Be 'PASS'
        } finally {
            Remove-Phase00E1TestDirectory -Path $fixture.Root
        }
    }

    It 'selects the nested leaf and its provider ledger instead of the carrier' {
        $fixture = New-Phase00E1ProjectionTestFixture -CaseId SessionOnly
        try {
            $evidence = Read-Phase00E1AttemptEvidence `
                -RepositoryRoot $fixture.Root -CaseId SessionOnly -Attempt 1
            $evidence.AttributableResults.Count | Should Be 1
            $evidence.AttributableResults[0].Agent |
                Should Be 'phase00-e1-session-leaf'
            $evidence.ProviderLedger.RequestCount | Should Be 1
            $evidence.ProcessProviderLedger.RequestCount | Should Be 4
            $evidence.CaseFacts.SelectedResultRole | Should Be 'nested_leaf'
            $evidence.CaseFacts.OuterCarrierResultSource | Should Be 'caller'
            $evidence.CaseFacts.CallerSchemaState | Should Be 'ABSENT'
            $evidence.CaseFacts.SessionSchemaState | Should Be 'PRESENT'
            (Test-Phase00E1Attempt -CaseId SessionOnly `
                -AttemptEvidence $evidence).Status | Should Be 'PASS'
        } finally {
            Remove-Phase00E1TestDirectory -Path $fixture.Root
        }
    }

    It 'filters strict evidence to yield-bearing child requests while preserving global indexes' {
        foreach ($caseId in @('ProviderStrictOffControl','ProviderStrictOn')) {
            $fixture = New-Phase00E1ProjectionTestFixture -CaseId $caseId
            try {
                $evidence = Read-Phase00E1AttemptEvidence `
                    -RepositoryRoot $fixture.Root -CaseId $caseId -Attempt 1
                $expectedIndexes = if ($caseId -eq 'ProviderStrictOffControl') {
                    '2,3'
                } else { '2' }
                @($evidence.ForwarderProjections.request_index) -join ',' |
                    Should Be $expectedIndexes
                $evidence.ForwarderProjections.Count |
                    Should Be $evidence.ProviderLedger.RequestCount
                $evidence.ProcessProviderLedger.RequestCount |
                    Should Be ($evidence.ForwarderAllProjectionCount)
                (Test-Phase00E1Attempt -CaseId $caseId `
                    -AttemptEvidence $evidence).Status | Should Be 'PASS'
            } finally {
                Remove-Phase00E1TestDirectory -Path $fixture.Root
            }
        }
    }

    It 'fails closed on artifact mutation traversal and semantic attribution conflicts' {
        $hashFixture = New-Phase00E1ProjectionTestFixture -CaseId AgentJtd
        try {
            [IO.File]::AppendAllText(
                $hashFixture.Paths.StdoutPath,
                "{`"type`":`"mutated`"}`n",
                [Text.UTF8Encoding]::new($false)
            )
            (Get-Phase00E1TestError {
                Read-Phase00E1AttemptEvidence -RepositoryRoot $hashFixture.Root `
                    -CaseId AgentJtd -Attempt 1
            }).Exception.Message | Should Match 'E1_ARTIFACT_HASH_MISMATCH'
        } finally {
            Remove-Phase00E1TestDirectory -Path $hashFixture.Root
        }

        $traversalFixture = New-Phase00E1ProjectionTestFixture -CaseId AgentJtd
        try {
            $envelope = Get-Content -LiteralPath $traversalFixture.Paths.RunPath -Raw |
                ConvertFrom-Json
            $envelope.artifacts[0].path = '../outside.jsonl'
            Write-Phase00E1TestJson -Path $traversalFixture.Paths.RunPath -Value $envelope
            (Get-Phase00E1TestError {
                Read-Phase00E1AttemptEvidence -RepositoryRoot $traversalFixture.Root `
                    -CaseId AgentJtd -Attempt 1
            }).Exception.Message | Should Match 'E1_ARTIFACT_PATH_INVALID'
        } finally {
            Remove-Phase00E1TestDirectory -Path $traversalFixture.Root
        }

        $processingFixture = New-Phase00E1ProjectionTestFixture -CaseId AgentJtd
        try {
            $envelope = Get-Content -LiteralPath $processingFixture.Paths.RunPath -Raw |
                ConvertFrom-Json
            $envelope.artifacts[0].metadata.ProcessingErrorLines = @(1)
            Write-Phase00E1TestJson -Path $processingFixture.Paths.RunPath -Value $envelope
            (Get-Phase00E1TestError {
                Read-Phase00E1AttemptEvidence -RepositoryRoot $processingFixture.Root `
                    -CaseId AgentJtd -Attempt 1
            }).Exception.Message | Should Match 'E1_ARTIFACT_METADATA_INVALID'
        } finally {
            Remove-Phase00E1TestDirectory -Path $processingFixture.Root
        }

        $duplicateFixture = New-Phase00E1ProjectionTestFixture `
            -CaseId AgentJtd -DuplicateResult
        try {
            $evidence = Read-Phase00E1AttemptEvidence `
                -RepositoryRoot $duplicateFixture.Root -CaseId AgentJtd -Attempt 1
            $analysis = Test-Phase00E1Attempt -CaseId AgentJtd `
                -AttemptEvidence $evidence
            $analysis.Status | Should Be 'INVALID_RUN'
            @($analysis.ReasonCodes) -contains 'E1_ATTRIBUTABLE_RESULT_COUNT' |
                Should Be $true
        } finally {
            Remove-Phase00E1TestDirectory -Path $duplicateFixture.Root
        }

        $carrierFixture = New-Phase00E1ProjectionTestFixture `
            -CaseId SessionOnly -CarrierSubstitution
        try {
            $evidence = Read-Phase00E1AttemptEvidence `
                -RepositoryRoot $carrierFixture.Root -CaseId SessionOnly -Attempt 1
            $analysis = Test-Phase00E1Attempt -CaseId SessionOnly `
                -AttemptEvidence $evidence
            $analysis.Status | Should Be 'INVALID_RUN'
            @($analysis.ReasonCodes) -contains 'E1_NESTED_LEAF_NOT_SELECTED' |
                Should Be $true
        } finally {
            Remove-Phase00E1TestDirectory -Path $carrierFixture.Root
        }
    }
}

Describe 'Phase 00 E1 deterministic case-record derivation' {
    It 'derives and writes an ordinary record without embedding raw result payloads' {
        $fixture = New-Phase00E1ProjectionTestFixture -CaseId AgentJtd
        try {
            $evidence = Read-Phase00E1AttemptEvidence `
                -RepositoryRoot $fixture.Root -CaseId AgentJtd -Attempt 1
            $analysis = Test-Phase00E1Attempt -CaseId AgentJtd `
                -AttemptEvidence $evidence
            $record = New-Phase00E1CaseRecord -CaseId AgentJtd `
                -AttemptEvidence $evidence -Analysis $analysis
            @($record.Keys) -join ',' | Should Be `
                'schema_version,experiment,case_id,matrix_artifact,status,attempt,runtime,inputs,observations,provider_ledger,raw_artifacts,protected_surface,reason_codes,limitations'
            $record.case_id | Should Be 'AgentJtd'
            $record.status | Should Be 'PASS'
            $record.provider_ledger.selected_session.requests | Should Be 1
            $record.provider_ledger.process.requests | Should Be 3
            $record.observations.selected_result.agent |
                Should Be 'phase00-e1-agent-jtd'
            ($record | ConvertTo-Json -Depth 100) | Should Not Match 'RawResult'
            $path = Join-Path $fixture.Root `
                'docs\evidence\phase-00\E1\case-1-agent-jtd.yml'
            $written = Write-Phase00E1CaseRecord -Path $path -Record $record
            $written.Sha256 | Should Be `
                (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
        } finally {
            Remove-Phase00E1TestDirectory -Path $fixture.Root
        }
    }

    It 'derives one strict-pair record from two independently passing arms' {
        $root = New-Phase00E1TestDirectory
        try {
            $offFixture = New-Phase00E1ProjectionTestFixture `
                -Root $root -CaseId ProviderStrictOffControl
            $onFixture = New-Phase00E1ProjectionTestFixture `
                -Root $root -CaseId ProviderStrictOn
            $off = Read-Phase00E1AttemptEvidence -RepositoryRoot $root `
                -CaseId ProviderStrictOffControl -Attempt 1
            $on = Read-Phase00E1AttemptEvidence -RepositoryRoot $root `
                -CaseId ProviderStrictOn -Attempt 1
            $offAnalysis = Test-Phase00E1Attempt `
                -CaseId ProviderStrictOffControl -AttemptEvidence $off
            $onAnalysis = Test-Phase00E1Attempt `
                -CaseId ProviderStrictOn -AttemptEvidence $on
            $pair = Test-Phase00E1ProviderStrictPair `
                -StrictOffAttempt $off -StrictOnAttempt $on
            $record = New-Phase00E1ProviderStrictCaseRecord `
                -StrictOffAttemptEvidence $off -StrictOffAnalysis $offAnalysis `
                -StrictOnAttemptEvidence $on -StrictOnAnalysis $onAnalysis `
                -PairAnalysis $pair
            $record.case_id | Should Be 'ProviderStrictPair'
            $record.matrix_artifact | Should Be 'case-5-provider-strict'
            $record.status | Should Be 'PASS'
            $record.provider_ledger.process_attempts | Should Be 2
            $record.observations.strict_off_control.status | Should Be 'PASS'
            $record.observations.strict_on.status | Should Be 'PASS'
            $record.observations.cross_arm_identity_equal | Should Be $true
            @($record.raw_artifacts).Count | Should BeGreaterThan 8
        } finally {
            Remove-Phase00E1TestDirectory -Path $root
        }
    }
}

function New-Phase00E1OracleTestEvidence {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn')]
        [string]$CaseId
    )

    $definition = Get-Phase00E1CaseDefinition -CaseId $CaseId
    $sentinelProperty = [string]$definition.ExpectedSentinelProperty
    $data = [ordered]@{}
    $data[$sentinelProperty] = [string]$definition.ExpectedSentinel
    $resultAgent = if ($CaseId -eq 'SessionOnly') {
        'phase00-e1-session-leaf'
    } else {
        [string]$definition.Agent
    }
    $result = [pscustomobject][ordered]@{
        Id = "$CaseId-result"
        Agent = $resultAgent
        IsAsyncAcknowledgement = $false
        StructuredOutput = [pscustomobject][ordered]@{
            source = [string]$definition.Source
            mode = [string]$definition.Mode
            status = 'valid'
            data = [pscustomobject]$data
        }
    }
    $ledger = [pscustomobject][ordered]@{
        RequestCount = 1
        AttributedRequestCount = 1
        UnattributedRequestCount = 0
        Provider = 'omniroute'
        Model = 'codex/gpt-5.6-sol-high'
        RetryExhausted = $false
        RecoveredRetryCount = 0
        TerminalFailure = [pscustomobject]@{
            Found = $false
            IsEnvironmentBlock = $false
            Code = $null
        }
    }
    $runRecord = [pscustomobject][ordered]@{
        PinnedSourceCommit = '3a8591a8af5b6d200088d12ca75a5517cb064fa8'
        RuntimeSha256 = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
        RuntimeVersion = 'omp/17.2.10'
        ExitCode = 0
        TimedOut = $false
        SanitizerStatus = 'PASS'
        RawArtifacts = @(
            [pscustomobject]@{
                Path = "raw/$CaseId.jsonl"
                Sha256 = ('A' * 64)
            }
        )
        RequiredEventAnchors = @(
            [pscustomobject]@{
                Path = "raw/$CaseId.jsonl"
                Line = 7
                Type = 'tool_execution_end'
            }
        )
        CleanupSucceeded = $true
        RemainingChildPids = @()
        ProtectedSurfacesUnchanged = $true
    }
    $blockingExecutions = @(
        [pscustomobject][ordered]@{
            Role = 'target'
            Agent = [string]$definition.Agent
            DefinitionBlocking = $true
            SetupBlocking = $true
            ExecutionMode = 'blocking'
            AsyncAcknowledgement = $false
        }
    )
    $caseFacts = [pscustomobject][ordered]@{
        CallerSchemaState = 'ABSENT'
        AgentSchemaState = 'ABSENT'
        SessionSchemaState = 'ABSENT'
        AgentSchemaDialect = 'NONE'
        ChildInitializationSource = [string]$definition.Source
        SchemaOverrideObservable = $false
        SchemaOverrideObserved = $false
        SelectedResultRole = 'target'
        OuterCarrierResultSource = $null
        CarrierCallerSchemaState = 'ABSENT'
    }

    switch ($CaseId) {
        'AgentJtd' {
            $caseFacts.AgentSchemaState = 'PRESENT'
            $caseFacts.AgentSchemaDialect = 'JTD'
        }
        'AgentJsonSchema' {
            $caseFacts.AgentSchemaState = 'PRESENT'
            $caseFacts.AgentSchemaDialect = 'JSON_SCHEMA'
        }
        'CallerOnly' {
            $caseFacts.CallerSchemaState = 'PRESENT'
            $caseFacts.SchemaOverrideObservable = $true
            $caseFacts.SchemaOverrideObserved = $true
        }
        'CallerOverAgent' {
            $caseFacts.CallerSchemaState = 'PRESENT'
            $caseFacts.AgentSchemaState = 'PRESENT'
            $caseFacts.AgentSchemaDialect = 'JSON_SCHEMA'
            $caseFacts.SchemaOverrideObservable = $true
            $caseFacts.SchemaOverrideObserved = $true
        }
        'SessionOnly' {
            $caseFacts.SessionSchemaState = 'PRESENT'
            $caseFacts.SelectedResultRole = 'nested_leaf'
            $caseFacts.OuterCarrierResultSource = 'caller'
            $caseFacts.CarrierCallerSchemaState = 'PRESENT'
            $blockingExecutions = @(
                [pscustomobject][ordered]@{
                    Role = 'carrier'
                    Agent = 'phase00-e1-session-carrier'
                    DefinitionBlocking = $true
                    SetupBlocking = $true
                    ExecutionMode = 'blocking'
                    AsyncAcknowledgement = $false
                },
                [pscustomobject][ordered]@{
                    Role = 'leaf'
                    Agent = 'phase00-e1-session-leaf'
                    DefinitionBlocking = $true
                    SetupBlocking = $true
                    ExecutionMode = 'blocking'
                    AsyncAcknowledgement = $false
                }
            )
        }
        { $_ -in @('ProviderStrictOffControl','ProviderStrictOn') } {
            $caseFacts.CallerSchemaState = 'PRESENT'
            $caseFacts.SchemaOverrideObservable = $true
            $caseFacts.SchemaOverrideObserved = $true
        }
    }

    $identity = $null
    $forwarderProjections = @()
    $yieldAttempts = @()
    $piNoStrictState = 'NOT_APPLICABLE'
    $localSchemaRejectionCount = 0
    $localSchemaRetryCount = 0
    $schemaOverrideCount = 0
    if ($CaseId -in @('ProviderStrictOffControl','ProviderStrictOn')) {
        $strictOn = $CaseId -eq 'ProviderStrictOn'
        $identity = [pscustomobject][ordered]@{
            PromptSha256 = '15B1C1BA9133F89B1125FCD089F87147F282DC1AAF315FFB303322A46AC87113'
            AssignmentSha256 = 'D8F7E058CCD96702BAB3D6AF2698356736B9525785BB6C6684F0FBAAC12BE88A'
            OutputSchemaSha256 = 'D40C5DF70D19DB184EC8E5A7FA651E05790BFC4579E29C1ABA0E214C95712E59'
            AgentSha256 = 'F8E53C651A41707CA2226F3CE687F97236BB0F0600024E42E87ACD14B85293EA'
            YieldParametersSha256 = if ($strictOn) {
                'BA45FA65ACE1C6653B74557015A2993085CF72FAF126D2CB01A76553DE05279C'
            } else {
                'DB58E598EDFCAAB815558716F24EED4D61FD2B9F5057608E8409C6369B234EEE'
            }
            Agent = 'phase00-e1-provider-strict'
            Model = 'codex/gpt-5.6-sol-high'
            RuntimeSha256 = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
            RuntimeVersion = 'omp/17.2.10'
            Gateway = 'omniroute:127.0.0.1:20128'
        }
        $forwarderProjections = @(
            [pscustomobject][ordered]@{
                record_type = 'phase00_e1_request_projection'
                request_index = 1
                request_path = '/v1/responses'
                forwarded = $true
                gateway_http_status = 200
                gateway = 'omniroute'
                api = 'openai-responses'
                yield_tool_present = $true
                yield_strict_field_present = $strictOn
                yield_strict = if ($strictOn) { $true } else { $null }
                yield_parameters_sha256 = $identity.YieldParametersSha256
                allowed_data_properties = @('allowed')
                required_data_properties = @('allowed')
                data_additional_properties = $false
                pi_no_strict_effective = -not $strictOn
            }
        )
        if ($strictOn) {
            $piNoStrictState = 'ABSENT'
            $yieldAttempts = @(
                [pscustomobject][ordered]@{
                    Index = 1
                    ProviderReturned = $true
                    Terminal = $true
                    Data = [pscustomobject]@{ allowed='E1_STRICT_ALLOWED' }
                    LocalValidationRejected = $false
                    LocalValidationReason = $null
                }
            )
        } else {
            $piNoStrictState = 'PRESENT_1'
            $localSchemaRejectionCount = 1
            $localSchemaRetryCount = 1
            $yieldAttempts = @(
                [pscustomobject][ordered]@{
                    Index = 1
                    ProviderReturned = $true
                    Terminal = $true
                    Data = [pscustomobject]@{
                        allowed='E1_STRICT_FORBIDDEN'
                        forbidden_extra='E1_FORBIDDEN_EXTRA'
                    }
                    LocalValidationRejected = $true
                    LocalValidationReason = 'schema'
                },
                [pscustomobject][ordered]@{
                    Index = 2
                    ProviderReturned = $true
                    Terminal = $true
                    Data = [pscustomobject]@{ allowed='E1_STRICT_ALLOWED' }
                    LocalValidationRejected = $false
                    LocalValidationReason = $null
                }
            )
        }
    }

    return [pscustomobject][ordered]@{
        CaseId = $CaseId
        Attempt = 1
        ProjectionStatus = 'PASS'
        ProjectionReasonCodes = @()
        AttributableResults = @($result)
        ProviderLedger = $ledger
        RunRecord = $runRecord
        BlockingExecutions = @($blockingExecutions)
        CaseFacts = $caseFacts
        Identity = $identity
        PiNoStrictState = $piNoStrictState
        ForwarderProjections = @($forwarderProjections)
        YieldAttempts = @($yieldAttempts)
        LocalSchemaRejectionCount = $localSchemaRejectionCount
        LocalSchemaRetryCount = $localSchemaRetryCount
        SchemaOverrideCount = $schemaOverrideCount
    }
}

Describe 'Phase 00 E1 ordinary case dispatcher' {
    It 'passes all five ordinary normalized evidence contracts' {
        $expectedReasons = [ordered]@{
            AgentJtd = 'E1_AGENT_JTD_PASS'
            AgentJsonSchema = 'E1_AGENT_JSON_SCHEMA_PASS'
            CallerOnly = 'E1_CALLER_ONLY_PASS'
            CallerOverAgent = 'E1_CALLER_OVER_AGENT_PASS'
            SessionOnly = 'E1_SESSION_ONLY_PASS'
        }
        foreach ($caseId in $expectedReasons.Keys) {
            $evidence = New-Phase00E1OracleTestEvidence -CaseId $caseId
            $analysis = Test-Phase00E1Attempt -CaseId $caseId `
                -AttemptEvidence $evidence
            $analysis.Status | Should Be 'PASS'
            @($analysis.ReasonCodes) -join ',' | Should Be $expectedReasons[$caseId]
        }
    }

    It 'rejects schema-design attribution and blocking mutations deterministically' {
        $mutations = @(
            [pscustomobject]@{ Name='swapped-source'; Case='AgentJtd'; Status='FAIL'; Reason='E1_STRUCTURED_SOURCE_MISMATCH' },
            [pscustomobject]@{ Name='explicit-null'; Case='AgentJtd'; Status='INVALID_RUN'; Reason='E1_CALLER_SCHEMA_OMISSION_VIOLATED' },
            [pscustomobject]@{ Name='dual-sentinels'; Case='CallerOverAgent'; Status='FAIL'; Reason='E1_FORBIDDEN_SENTINEL_PRESENT' },
            [pscustomobject]@{ Name='carrier-substitution'; Case='SessionOnly'; Status='INVALID_RUN'; Reason='E1_NESTED_LEAF_NOT_SELECTED' },
            [pscustomobject]@{ Name='nested-caller-schema'; Case='SessionOnly'; Status='INVALID_RUN'; Reason='E1_CALLER_SCHEMA_OMISSION_VIOLATED' },
            [pscustomobject]@{ Name='async-ack'; Case='CallerOnly'; Status='INVALID_RUN'; Reason='E1_ASYNC_ACKNOWLEDGEMENT' },
            [pscustomobject]@{ Name='nonblocking'; Case='CallerOnly'; Status='INVALID_RUN'; Reason='E1_BLOCKING_EXECUTION_NOT_PROVEN' },
            [pscustomobject]@{ Name='hidden-override'; Case='CallerOnly'; Status='FAIL'; Reason='E1_SCHEMA_OVERRIDE_MISMATCH' },
            [pscustomobject]@{ Name='projector-invalid'; Case='AgentJtd'; Status='INVALID_RUN'; Reason='E1_SYNTHETIC_PROJECTOR_CONFLICT' }
        )
        foreach ($mutation in $mutations) {
            $evidence = New-Phase00E1OracleTestEvidence -CaseId $mutation.Case
            switch ($mutation.Name) {
                'swapped-source' { $evidence.AttributableResults[0].StructuredOutput.source = 'caller' }
                'explicit-null' { $evidence.CaseFacts.CallerSchemaState = 'NULL' }
                'dual-sentinels' {
                    $evidence.AttributableResults[0].StructuredOutput.data = [pscustomobject][ordered]@{
                        caller_sentinel='E1_CALLER_WINS'
                        agent_sentinel='E1_AGENT_LOSES'
                    }
                }
                'carrier-substitution' { $evidence.CaseFacts.SelectedResultRole = 'carrier' }
                'nested-caller-schema' { $evidence.CaseFacts.CallerSchemaState = 'PRESENT' }
                'async-ack' { $evidence.AttributableResults[0].IsAsyncAcknowledgement = $true }
                'nonblocking' { $evidence.BlockingExecutions[0].DefinitionBlocking = $false }
                'hidden-override' { $evidence.CaseFacts.SchemaOverrideObserved = $false }
                'projector-invalid' {
                    $evidence.ProjectionStatus = 'INVALID_RUN'
                    $evidence.ProjectionReasonCodes = @('E1_SYNTHETIC_PROJECTOR_CONFLICT')
                }
            }
            $analysis = Test-Phase00E1Attempt -CaseId $mutation.Case `
                -AttemptEvidence $evidence
            $analysis.Status | Should Be $mutation.Status
            (@($analysis.ReasonCodes) -contains $mutation.Reason) | Should Be $true
        }
    }
}

Describe 'Phase 00 E1 provider-strict arm oracles' {
    It 'passes the exercised strict-off control and rejects an unexercised control' {
        $off = New-Phase00E1OracleTestEvidence -CaseId ProviderStrictOffControl
        $analysis = Test-Phase00E1Attempt -CaseId ProviderStrictOffControl `
            -AttemptEvidence $off
        $analysis.Status | Should Be 'PASS'
        @($analysis.ReasonCodes) -join ',' | Should Be 'E1_PROVIDER_STRICT_OFF_PASS'

        $unexercised = New-Phase00E1OracleTestEvidence `
            -CaseId ProviderStrictOffControl
        $unexercised.YieldAttempts = @(
            [pscustomobject][ordered]@{
                Index=1; ProviderReturned=$true; Terminal=$true
                Data=[pscustomobject]@{ allowed='E1_STRICT_ALLOWED' }
                LocalValidationRejected=$false; LocalValidationReason=$null
            }
        )
        $unexercised.LocalSchemaRejectionCount = 0
        $unexercised.LocalSchemaRetryCount = 0
        $invalid = Test-Phase00E1Attempt -CaseId ProviderStrictOffControl `
            -AttemptEvidence $unexercised
        $invalid.Status | Should Be 'INVALID_RUN'
        (@($invalid.ReasonCodes) -contains 'E1_STRICT_CONTROL_NOT_EXERCISED') |
            Should Be $true
    }

    It 'rejects wrong off-arm wire environment and local-rejection facts' {
        $mutations = @('wire-strict','environment','rejection-count','retry-count')
        foreach ($mutation in $mutations) {
            $off = New-Phase00E1OracleTestEvidence `
                -CaseId ProviderStrictOffControl
            switch ($mutation) {
                'wire-strict' {
                    $off.ForwarderProjections[0].yield_strict_field_present = $true
                    $off.ForwarderProjections[0].yield_strict = $true
                }
                'environment' { $off.PiNoStrictState = 'ABSENT' }
                'rejection-count' { $off.LocalSchemaRejectionCount = 0 }
                'retry-count' { $off.LocalSchemaRetryCount = 0 }
            }
            $analysis = Test-Phase00E1Attempt `
                -CaseId ProviderStrictOffControl -AttemptEvidence $off
            $analysis.Status | Should Be 'FAIL'
        }
    }

    It 'passes strict-on and rejects hidden forbidden data retry override or wrong strict flag' {
        $on = New-Phase00E1OracleTestEvidence -CaseId ProviderStrictOn
        $analysis = Test-Phase00E1Attempt -CaseId ProviderStrictOn `
            -AttemptEvidence $on
        $analysis.Status | Should Be 'PASS'
        @($analysis.ReasonCodes) -join ',' | Should Be 'E1_PROVIDER_STRICT_ON_PASS'

        $mutations = @(
            'strict-omitted','open-schema','forbidden','final-forbidden',
            'retry','override','environment'
        )
        foreach ($mutation in $mutations) {
            $on = New-Phase00E1OracleTestEvidence -CaseId ProviderStrictOn
            switch ($mutation) {
                'strict-omitted' {
                    $on.ForwarderProjections[0].yield_strict_field_present = $false
                    $on.ForwarderProjections[0].yield_strict = $null
                }
                'open-schema' {
                    $on.ForwarderProjections[0].data_additional_properties = $true
                }
                'forbidden' {
                    $on.YieldAttempts[0].Data = [pscustomobject][ordered]@{
                        allowed='E1_STRICT_ALLOWED'
                        forbidden_extra='E1_FORBIDDEN_EXTRA'
                    }
                }
                'final-forbidden' {
                    $on.AttributableResults[0].StructuredOutput.data = `
                        [pscustomobject][ordered]@{
                            allowed='E1_STRICT_ALLOWED'
                            forbidden_extra='E1_FORBIDDEN_EXTRA'
                        }
                }
                'retry' { $on.LocalSchemaRetryCount = 1 }
                'override' { $on.SchemaOverrideCount = 1 }
                'environment' { $on.PiNoStrictState = 'PRESENT_1' }
            }
            $failed = Test-Phase00E1Attempt -CaseId ProviderStrictOn `
                -AttemptEvidence $on
            $failed.Status | Should Be 'FAIL'
        }
    }

    It 'invalidates a strict arm when forwarder and provider request counts diverge' {
        $on = New-Phase00E1OracleTestEvidence -CaseId ProviderStrictOn
        $on.ProviderLedger.RequestCount = 2
        $on.ProviderLedger.AttributedRequestCount = 2
        $analysis = Test-Phase00E1Attempt -CaseId ProviderStrictOn `
            -AttemptEvidence $on
        $analysis.Status | Should Be 'INVALID_RUN'
        (@($analysis.ReasonCodes) -contains 'E1_FORWARDER_PROVIDER_COUNT_MISMATCH') |
            Should Be $true
    }
}

Describe 'Phase 00 E1 provider-strict pair oracle' {
    It 'passes arm-specific wire hashes while requiring byte-identical invariant identities' {
        $off = New-Phase00E1OracleTestEvidence -CaseId ProviderStrictOffControl
        $on = New-Phase00E1OracleTestEvidence -CaseId ProviderStrictOn
        $pair = Test-Phase00E1ProviderStrictPair `
            -StrictOffAttempt $off -StrictOnAttempt $on
        $pair.Status | Should Be 'PASS'
        @($pair.ReasonCodes) -join ',' | Should Be 'E1_PROVIDER_STRICT_PAIR_PASS'

        foreach ($property in @(
            'PromptSha256','AssignmentSha256','OutputSchemaSha256','AgentSha256',
            'Agent','Model','RuntimeSha256','RuntimeVersion','Gateway'
        )) {
            $off = New-Phase00E1OracleTestEvidence -CaseId ProviderStrictOffControl
            $on = New-Phase00E1OracleTestEvidence -CaseId ProviderStrictOn
            $on.Identity.$property = [string]$on.Identity.$property + '-MUTATED'
            $invalid = Test-Phase00E1ProviderStrictPair `
                -StrictOffAttempt $off -StrictOnAttempt $on
            $invalid.Status | Should Be 'INVALID_RUN'
            (@($invalid.ReasonCodes) -contains 'E1_STRICT_PAIR_IDENTITY_MISMATCH') |
                Should Be $true
        }

        $off = New-Phase00E1OracleTestEvidence -CaseId ProviderStrictOffControl
        $off.ForwarderProjections[0].yield_parameters_sha256 =
            'BA45FA65ACE1C6653B74557015A2993085CF72FAF126D2CB01A76553DE05279C'
        $invalidArm = Test-Phase00E1Attempt `
            -CaseId ProviderStrictOffControl -AttemptEvidence $off
        $invalidArm.Status | Should Be 'INVALID_RUN'
        (@($invalidArm.ReasonCodes) -contains 'E1_STRICT_IDENTITY_MISMATCH') |
            Should Be $true
    }

    It 'propagates invalid fail and blocked arm outcomes with pair-level precedence' {
        $offInvalid = New-Phase00E1OracleTestEvidence `
            -CaseId ProviderStrictOffControl
        $offInvalid.YieldAttempts = @(
            [pscustomobject][ordered]@{
                Index=1; ProviderReturned=$true; Terminal=$true
                Data=[pscustomobject]@{ allowed='E1_STRICT_ALLOWED' }
                LocalValidationRejected=$false; LocalValidationReason=$null
            }
        )
        $offInvalid.LocalSchemaRejectionCount = 0
        $offInvalid.LocalSchemaRetryCount = 0
        $on = New-Phase00E1OracleTestEvidence -CaseId ProviderStrictOn
        (Test-Phase00E1ProviderStrictPair `
            -StrictOffAttempt $offInvalid -StrictOnAttempt $on).Status |
            Should Be 'INVALID_RUN'

        $off = New-Phase00E1OracleTestEvidence `
            -CaseId ProviderStrictOffControl
        $onFailed = New-Phase00E1OracleTestEvidence -CaseId ProviderStrictOn
        $onFailed.SchemaOverrideCount = 1
        (Test-Phase00E1ProviderStrictPair `
            -StrictOffAttempt $off -StrictOnAttempt $onFailed).Status |
            Should Be 'FAIL'

        $offBlocked = New-Phase00E1OracleTestEvidence `
            -CaseId ProviderStrictOffControl
        $offBlocked.ProviderLedger.TerminalFailure = [pscustomobject]@{
            Found=$true
            IsEnvironmentBlock=$true
            Code='P00-RUNTIME-PROVIDER-QUOTA'
        }
        $on = New-Phase00E1OracleTestEvidence -CaseId ProviderStrictOn
        (Test-Phase00E1ProviderStrictPair `
            -StrictOffAttempt $offBlocked -StrictOnAttempt $on).Status |
            Should Be 'BLOCKED_ENVIRONMENT'
    }
}

Describe 'Phase 00 E1 experiment outcome oracle' {
    It 'implements complete six-record status precedence and exact case set' {
        $caseIds = @(
            'AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent',
            'SessionOnly','ProviderStrictPair'
        )
        $newRecords = {
            @($caseIds | ForEach-Object {
                [pscustomobject][ordered]@{ CaseId=$_; Status='PASS'; ReasonCodes=@('PASS') }
            })
        }
        $pass = Get-Phase00E1ExperimentOutcome -CaseRecords (& $newRecords)
        $pass.Status | Should Be 'PASS'
        @($pass.ReasonCodes) -join ',' | Should Be 'E1_ALL_SIX_CASES_PASS'

        $incomplete = Get-Phase00E1ExperimentOutcome `
            -CaseRecords @((& $newRecords)[0..4])
        $incomplete.Status | Should Be 'INVALID_RUN'
        @($incomplete.ReasonCodes) -join ',' | Should Be 'E1_MATRIX_INCOMPLETE'

        $duplicate = @(& $newRecords)
        $duplicate[5].CaseId = 'SessionOnly'
        $badSet = Get-Phase00E1ExperimentOutcome -CaseRecords $duplicate
        $badSet.Status | Should Be 'INVALID_RUN'
        @($badSet.ReasonCodes) -join ',' | Should Be 'E1_MATRIX_CASE_SET_INVALID'

        $failed = @(& $newRecords)
        $failed[0].Status = 'FAIL'
        $failed[1].Status = 'BLOCKED_ENVIRONMENT'
        (Get-Phase00E1ExperimentOutcome -CaseRecords $failed).Status |
            Should Be 'FAIL'

        $blocked = @(& $newRecords)
        $blocked[0].Status = 'BLOCKED_ENVIRONMENT'
        (Get-Phase00E1ExperimentOutcome -CaseRecords $blocked).Status |
            Should Be 'BLOCKED_ENVIRONMENT'

        $nonterminal = @(& $newRecords)
        $nonterminal[0].Status = 'INVALID_RUN'
        (Get-Phase00E1ExperimentOutcome -CaseRecords $nonterminal).Status |
            Should Be 'INVALID_RUN'
    }
}

function New-Phase00E1ArtifactContractFixture {
    $fixtureRoot = New-Phase00E1TestDirectory
    $relativeFiles = @(
        'docs/evidence/phase-00/manifest.yml',
        'scripts/lib/phase00-evidence.ps1',
        'scripts/lib/phase00-e1-evidence.ps1',
        'scripts/lib/phase00-runtime-evidence.ps1',
        'scripts/lib/phase00-e1-forwarder.mjs',
        'scripts/run-phase00-e1.ps1'
    )
    $relativeFiles += @(Get-Phase00E1ExpectedFixtureHashes).Keys | ForEach-Object {
        'docs/evidence/phase-00/E1/fixture/{0}' -f $_
    }
    $relativeFiles += @(Get-Phase00E1ProtectedHashes).Keys

    # Topic 03 superseded four of the nine historical E1 agent pins, so those paths no longer exist.
    # P00-E1-PROTECTED-SURFACE resolves that drift through the current-product supersession branch,
    # which reads the Topic 03 manifest, the immutable T-00.3 conclusion it binds, and every
    # current_files row. Without them the fixture reports drift it has no evidence to explain.
    $supersessionManifest = 'docs/evidence/current-product/topic-03/manifest.yml'
    $relativeFiles += @($supersessionManifest, 'docs/evidence/phase-00/T-00.3/conclusion.yml')
    $manifestSource = Join-Path $repositoryRoot `
        $supersessionManifest.Replace('/',[IO.Path]::DirectorySeparatorChar)
    if (Test-Path -LiteralPath $manifestSource -PathType Leaf) {
        $manifest = Get-Content -Raw -LiteralPath $manifestSource -Encoding UTF8 | ConvertFrom-Json
        $relativeFiles += @($manifest.current_files | ForEach-Object { [string]$_.path })
    }

    foreach ($relativePath in @($relativeFiles | Sort-Object -Unique)) {
        $source = Join-Path $repositoryRoot `
            ([string]$relativePath).Replace('/',[IO.Path]::DirectorySeparatorChar)
        # A pinned protected path that no longer exists is retired historical evidence, never a
        # fixture defect. Copying only what the repository still carries keeps the fixture an
        # honest mirror of the live surface the validator is asked to judge.
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { continue }
        $destination = Join-Path $fixtureRoot `
            ([string]$relativePath).Replace('/',[IO.Path]::DirectorySeparatorChar)
        [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination
    }
    return $fixtureRoot
}

function Get-Phase00E1ArtifactValidationResult {
    param(
        [Parameter(Mandatory)]$Results,
        [Parameter(Mandatory)][string]$Code
    )
    return @($Results | Where-Object { $_.Code -eq $Code }) | Select-Object -First 1
}

Describe 'Phase 00 E1 durable READY artifact contract' {
    It 'accepts the exact READY surface and exposes all category checks plus READY' {
        $fixture = New-Phase00E1ArtifactContractFixture
        try {
            $results = @(Test-Phase00E1ArtifactContract -RepositoryRoot $fixture)
            @($results | Where-Object Status -eq 'FAIL').Count | Should Be 0
            @($results.Code) -join ',' | Should Be `
                'P00-E1-FIXTURE,P00-E1-RUNTIME,P00-E1-PROTECTED-SURFACE,P00-E1-MANIFEST,P00-E1-CONCLUSION,P00-E1-READY'
        } finally {
            Remove-Phase00E1TestDirectory -Path $fixture
        }
    }

    It 'keeps partial INVALID_RUN history non-authoritative while E1 remains READY' {
        $fixture = New-Phase00E1ArtifactContractFixture
        try {
            $rawDirectory = Join-Path $fixture `
                'docs\evidence\phase-00\E1\raw\agent-jtd\attempt-001'
            [IO.Directory]::CreateDirectory($rawDirectory) | Out-Null
            [IO.File]::WriteAllText(
                (Join-Path $rawDirectory 'envelope.json'),
                '{"capture_integrity_status":"INVALID_RUN","case_status":null,"case_oracle_evaluated":false}',
                [Text.UTF8Encoding]::new($false)
            )
            $results = @(Test-Phase00E1ArtifactContract -RepositoryRoot $fixture)
            @($results | Where-Object Status -eq 'FAIL').Count | Should Be 0
            (Get-Phase00E1ArtifactValidationResult $results 'P00-E1-READY').Status |
                Should Be 'PASS'
        } finally {
            Remove-Phase00E1TestDirectory -Path $fixture
        }
    }

    It 'rejects a READY row that grants T-00.4 premature authority' {
        $fixture = New-Phase00E1ArtifactContractFixture
        try {
            $manifestPath = Join-Path $fixture 'docs\evidence\phase-00\manifest.yml'
            $text = [IO.File]::ReadAllText($manifestPath)
            $text = [regex]::Replace(
                $text,
                '(?m)(^  - id: T-00\.4\r?\n    kind: foundation\r?\n    state:) NOT_STARTED$',
                '$1 READY'
            )
            [IO.File]::WriteAllText($manifestPath,$text,[Text.UTF8Encoding]::new($false))
            $results = @(Test-Phase00E1ArtifactContract -RepositoryRoot $fixture)
            (Get-Phase00E1ArtifactValidationResult $results 'P00-E1-MANIFEST').Status |
                Should Be 'FAIL'
            @(Get-Phase00E1ArtifactValidationResult $results 'P00-E1-READY').Count |
                Should Be 0
        } finally {
            Remove-Phase00E1TestDirectory -Path $fixture
        }
    }

    It 'rejects a terminal conclusion while the manifest still says READY' {
        $fixture = New-Phase00E1ArtifactContractFixture
        try {
            $conclusionPath = Join-Path $fixture `
                'docs\evidence\phase-00\E1\conclusion.yml'
            [IO.File]::WriteAllText(
                $conclusionPath,
                "schema_version: 1`nexperiment: E1`nstatus: PASS`n",
                [Text.UTF8Encoding]::new($false)
            )
            $results = @(Test-Phase00E1ArtifactContract -RepositoryRoot $fixture)
            (Get-Phase00E1ArtifactValidationResult $results 'P00-E1-CONCLUSION').Status |
                Should Be 'FAIL'
            @(Get-Phase00E1ArtifactValidationResult $results 'P00-E1-READY').Count |
                Should Be 0
        } finally {
            Remove-Phase00E1TestDirectory -Path $fixture
        }
    }

    It 'rejects fixture drift independently of the READY manifest' {
        $fixture = New-Phase00E1ArtifactContractFixture
        try {
            $path = Join-Path $fixture `
                'docs\evidence\phase-00\E1\fixture\prompts\caller-only.md'
            [IO.File]::AppendAllText($path,"`nMUTATED",[Text.UTF8Encoding]::new($false))
            $results = @(Test-Phase00E1ArtifactContract -RepositoryRoot $fixture)
            (Get-Phase00E1ArtifactValidationResult $results 'P00-E1-FIXTURE').Status |
                Should Be 'FAIL'
        } finally {
            Remove-Phase00E1TestDirectory -Path $fixture
        }
    }

    It 'rejects a protected product mutation independently of evidence history' {
        $fixture = New-Phase00E1ArtifactContractFixture
        try {
            $path = Join-Path $fixture `
                'template\.omp\schemas\agent-result.schema.yml'
            [IO.File]::AppendAllText($path,"`n# MUTATED",[Text.UTF8Encoding]::new($false))
            $results = @(Test-Phase00E1ArtifactContract -RepositoryRoot $fixture)
            (Get-Phase00E1ArtifactValidationResult `
                $results 'P00-E1-PROTECTED-SURFACE').Status | Should Be 'FAIL'
        } finally {
            Remove-Phase00E1TestDirectory -Path $fixture
        }
    }

    It 'rejects a missing pinned runtime surface before any provider execution' {
        $fixture = New-Phase00E1ArtifactContractFixture
        try {
            Remove-Item -LiteralPath (Join-Path $fixture 'scripts\run-phase00-e1.ps1')
            $results = @(Test-Phase00E1ArtifactContract -RepositoryRoot $fixture)
            (Get-Phase00E1ArtifactValidationResult $results 'P00-E1-RUNTIME').Status |
                Should Be 'FAIL'
        } finally {
            Remove-Phase00E1TestDirectory -Path $fixture
        }
    }
}

Describe 'Phase 00 E1 canonical derived-artifact writers' {
    It 'writes one deterministic no-overwrite case record in canonical field order' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $path = Join-Path $testRoot 'case-1-agent-jtd.yml'
            $record = [pscustomobject][ordered]@{
                schema_version = 1
                experiment = 'E1'
                case_id = 'AgentJtd'
                matrix_artifact = 'case-1-agent-jtd'
                status = 'PASS'
                attempt = 1
                runtime = [ordered]@{ version='omp/17.2.10'; sha256='ABCDEF' }
                inputs = [ordered]@{ source='agent'; note='colon: remains safe' }
                observations = [ordered]@{ sentinel='E1_AGENT_JTD' }
                provider_ledger = [ordered]@{ requests=1; retries=0 }
                raw_artifacts = @([ordered]@{ path='raw/stdout.jsonl'; sha256='1234' })
                protected_surface = [ordered]@{ matched=9; expected=9 }
                reason_codes = @('E1_AGENT_JTD_PASS')
                limitations = @('configured path only')
            }
            $written = Write-Phase00E1CaseRecord -Path $path -Record $record
            $written.Path | Should Be ([IO.Path]::GetFullPath($path))
            $written.Sha256 | Should Be (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
            $bytes = [IO.File]::ReadAllBytes($path)
            ($bytes.Length -gt 3 -and $bytes[0] -eq 0xEF -and
                $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) | Should Be $false
            $text = [IO.File]::ReadAllText($path)
            $topLevel = @([regex]::Matches($text,'(?m)^([a-z0-9_]+):') |
                ForEach-Object { $_.Groups[1].Value })
            $topLevel -join ',' | Should Be `
                'schema_version,experiment,case_id,matrix_artifact,status,attempt,runtime,inputs,observations,provider_ledger,raw_artifacts,protected_surface,reason_codes,limitations'
            $text | Should Match 'note: "colon: remains safe"'
            $before = $written.Sha256
            $caught = Get-Phase00E1TestError {
                Write-Phase00E1CaseRecord -Path $path -Record $record
            }
            $caught.Exception.Message | Should Match 'already exists'
            (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash | Should Be $before
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'rejects noncanonical case identity shape before creating a file' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $path = Join-Path $testRoot 'case-1-agent-jtd.yml'
            $record = [pscustomobject][ordered]@{
                schema_version = 1; experiment = 'E1'; case_id = 'AgentJtd'
                matrix_artifact = 'case-1-agent-jtd'; status = 'PASS'; attempt = 1
                runtime = [ordered]@{}; inputs = [ordered]@{}
                observations = [ordered]@{}; provider_ledger = [ordered]@{}
                raw_artifacts = @(); protected_surface = [ordered]@{}
                reason_codes = @('PASS'); limitations = @(); unexpected = 'drift'
            }
            $caught = Get-Phase00E1TestError {
                Write-Phase00E1CaseRecord -Path $path -Record $record
            }
            $caught.Exception.Message | Should Match 'exact top-level fields'
            Test-Path -LiteralPath $path | Should Be $false
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'writes a bounded terminal conclusion and refuses joint closure or overwrite' {
        $testRoot = New-Phase00E1TestDirectory
        try {
            $path = Join-Path $testRoot 'conclusion.yml'
            $outcome = [pscustomobject][ordered]@{
                schema_version = 1
                experiment = 'E1'
                status = 'PASS'
                case_records = @('case-1-agent-jtd.yml')
                runtime = [ordered]@{ version='omp/17.2.10' }
                provider_boundary = 'OMP_17_2_10_TO_OMNIROUTE_OPENAI_RESPONSES'
                open_question_a = 'BOTH_ACCEPTED'
                canonical_t_00_4_agent_output_dialect = 'JTD'
                precedence = [ordered]@{ order=@('caller','agent','session') }
                provider_enforcement = [ordered]@{
                    boundary='OMP_17_2_10_TO_OMNIROUTE_OPENAI_RESPONSES'
                    strict_on_observed=$true
                    strict_off_control_exercised=$true
                }
                upstream_provider_claim = 'none'
                spec_effect = 'CHANGE'
                downstream_files = @('template/.omp/agents/*.md')
                t_00_4_effect = 'READY_ONLY'
                raw_artifacts = @('raw/agent-jtd/attempt-001/envelope.json')
                limitations = @('configured path only')
                joint_closure = $false
            }
            $written = Write-Phase00E1Conclusion -Path $path -Outcome $outcome
            $written.Sha256 | Should Be (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
            $text = [IO.File]::ReadAllText($path)
            $topLevel = @([regex]::Matches($text,'(?m)^([a-z0-9_]+):') |
                ForEach-Object { $_.Groups[1].Value })
            $topLevel -join ',' | Should Be `
                'schema_version,experiment,status,case_records,runtime,provider_boundary,open_question_a,canonical_t_00_4_agent_output_dialect,precedence,provider_enforcement,upstream_provider_claim,spec_effect,downstream_files,t_00_4_effect,raw_artifacts,limitations,joint_closure'
            $text | Should Match '(?m)^joint_closure: false$'
            (Get-Phase00E1TestError {
                Write-Phase00E1Conclusion -Path $path -Outcome $outcome
            }).Exception.Message | Should Match 'already exists'

            $otherPath = Join-Path $testRoot 'nested\conclusion.yml'
            [IO.Directory]::CreateDirectory((Split-Path -Parent $otherPath)) | Out-Null
            $outcome.joint_closure = $true
            (Get-Phase00E1TestError {
                Write-Phase00E1Conclusion -Path $otherPath -Outcome $outcome
            }).Exception.Message | Should Match 'joint_closure must remain false'
            Test-Path -LiteralPath $otherPath | Should Be $false
        } finally {
            Remove-Phase00E1TestDirectory -Path $testRoot
        }
    }

    It 'contains no empty public writer implementation at the offline gate' {
        $source = [IO.File]::ReadAllText($helperPath).Replace("`r`n","`n")
        $source | Should Not Match '(?m)^function Write-Phase00E1(?:CaseRecord|Conclusion) \{\s*\}$'
    }
}
