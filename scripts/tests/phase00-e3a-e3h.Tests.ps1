#Requires -Version 5.1

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$configHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-config-evidence.ps1'
$runtimeHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-runtime-evidence.ps1'
$runnerPath = Join-Path $repositoryRoot 'scripts\run-phase00-e3a-e3h.ps1'
$e3aFixtureRoot = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-A\fixture'
$e3hFixtureRoot = Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-H\fixture'
$script:configHelperLoaded = $false
$script:runnerLoaded = $false

if (Test-Path -LiteralPath $runtimeHelperPath -PathType Leaf) { . $runtimeHelperPath }
if (Test-Path -LiteralPath $configHelperPath -PathType Leaf) {
    . $configHelperPath
    $script:configHelperLoaded = $true
}
if (Test-Path -LiteralPath $runnerPath -PathType Leaf) {
    . $runnerPath
    $script:runnerLoaded = $true
}

function Assert-ConfigHelperLoaded {
    $script:configHelperLoaded | Should Be $true
}

function Get-E3APinnedTestOmp {
    $expected = '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
    $installed = (Get-Command omp -ErrorAction Stop).Source
    $candidates = @(
        $installed
        @(Get-ChildItem -LiteralPath (Split-Path -Parent $installed) -File `
            -Filter 'omp.exe*.bak' -ErrorAction SilentlyContinue |
            ForEach-Object FullName)
    ) | Select-Object -Unique
    foreach ($candidate in $candidates) {
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $candidate).Hash -eq
            $expected) {
            return $candidate
        }
    }
    throw 'Pinned 17.2.10 executable is unavailable for E3-A/E3-H runner tests.'
}

function New-ConfigToolStart([string]$Id, [string]$ToolName, $Arguments) {
    [pscustomobject][ordered]@{
        type = 'tool_execution_start'
        toolCallId = $Id
        toolName = $ToolName
        args = $Arguments
    }
}

function New-ConfigToolEnd([string]$Id, [string]$ToolName, $Result, [bool]$IsError = $false) {
    [pscustomobject][ordered]@{
        type = 'tool_execution_end'
        toolCallId = $Id
        toolName = $ToolName
        result = $Result
        isError = $IsError
    }
}

Describe 'E3-H H3 CLI overlay control surface' {
    It 'refuses an unsupported config-subcommand overlay without authorizing parallel work' {
        Assert-ConfigHelperLoaded
        $result = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.apply' `
            -ExitCode 1 `
            -Stdout '' `
            -Stderr "error: Unknown option '--config'." `
            -Context CliOverlay

        $result.Status | Should Be 'REFUSE'
        @($result.Reasons) -contains 'CONFIG_CLI_OVERLAY_UNSUPPORTED' | Should Be $true
        @($result.Reasons) -contains 'CLI_OVERLAY_UNOBSERVABLE' | Should Be $true
        (($result | ConvertTo-Json -Depth 8) -match 'ALLOW_PARALLEL') | Should Be $false
    }
}

Describe 'Strict omp config get parsing' {
    It 'accepts an exact enum observation' {
        Assert-ConfigHelperLoaded
        $json = '{"key":"task.isolation.mode","value":"rcopy","type":"enum","description":"Isolation backend"}'
        $result = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.mode' `
            -ExitCode 0 -Stdout $json -Stderr '' -Context ProjectRoot

        $result.Status | Should Be 'OBSERVED'
        $result.Observation.Key | Should Be 'task.isolation.mode'
        $result.Observation.Value | Should Be 'rcopy'
        $result.Observation.Type | Should Be 'enum'
        $result.Fallback | Should Be $null
    }

    It 'accepts an exact boolean observation without string coercion' {
        Assert-ConfigHelperLoaded
        $json = '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"Apply changes"}'
        $result = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout $json -Stderr '' -Context ProjectRoot

        $result.Status | Should Be 'OBSERVED'
        $result.Observation.Value | Should Be $false
        $result.Observation.Type | Should Be 'boolean'
    }

    It 'distinguishes an unknown setting from a generic process failure' {
        Assert-ConfigHelperLoaded
        $unknown = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.__phase00_unknown' -ExitCode 1 -Stdout '' `
            -Stderr 'Unknown setting: task.isolation.__phase00_unknown' -Context DirectRead
        $generic = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.apply' -ExitCode 9 -Stdout '' `
            -Stderr 'generic process failure' -Context Synthetic

        $unknown.Status | Should Be 'REFUSE'
        @($unknown.Reasons) | Should Be @('CONFIG_KEY_UNKNOWN')
        $generic.Status | Should Be 'REFUSE'
        @($generic.Reasons) | Should Be @('CONFIG_READ_NONZERO')
    }

    It 'fails closed with a distinct invalid-JSON reason' {
        Assert-ConfigHelperLoaded
        $result = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.apply' -ExitCode 0 -Stdout 'not-json' `
            -Stderr '' -Context Synthetic

        $result.Status | Should Be 'REFUSE'
        @($result.Reasons) | Should Be @('CONFIG_JSON_INVALID')
    }

    It 'invalidates empty stdout, wrong keys, wrong declared types, and wrong runtime value types' {
        Assert-ConfigHelperLoaded
        $empty = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.apply' -ExitCode 0 -Stdout '' -Stderr '' -Context Synthetic
        $wrongKey = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.apply' -ExitCode 0 `
            -Stdout '{"key":"task.isolation.mode","value":"none","type":"enum","description":"x"}' `
            -Stderr '' -Context Synthetic
        $wrongDeclaredType = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.apply' -ExitCode 0 `
            -Stdout '{"key":"task.isolation.apply","value":false,"type":"enum","description":"x"}' `
            -Stderr '' -Context Synthetic
        $wrongValueType = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.apply' -ExitCode 0 `
            -Stdout '{"key":"task.isolation.apply","value":"false","type":"boolean","description":"x"}' `
            -Stderr '' -Context Synthetic

        $empty.Status | Should Be 'INVALID_RUN'
        @($empty.Reasons) | Should Be @('CONFIG_STDOUT_EMPTY')
        @($wrongKey.Reasons) | Should Be @('CONFIG_KEY_MISMATCH')
        @($wrongDeclaredType.Reasons) | Should Be @('CONFIG_TYPE_MISMATCH')
        @($wrongValueType.Reasons) | Should Be @('CONFIG_VALUE_TYPE_MISMATCH')
    }

    It 'invalidates extra or missing JSON properties' {
        Assert-ConfigHelperLoaded
        $extra = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.apply' -ExitCode 0 `
            -Stdout '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"x","extra":1}' `
            -Stderr '' -Context Synthetic
        $missing = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.apply' -ExitCode 0 `
            -Stdout '{"key":"task.isolation.apply","value":false,"type":"boolean"}' `
            -Stderr '' -Context Synthetic

        $extra.Status | Should Be 'INVALID_RUN'
        @($extra.Reasons) | Should Be @('CONFIG_SHAPE_MISMATCH')
        $missing.Status | Should Be 'INVALID_RUN'
        @($missing.Reasons) | Should Be @('CONFIG_SHAPE_MISMATCH')
    }
}

Describe 'Fail-closed isolation diagnostics' {
    It 'returns diagnostic success without parallel authorization for rcopy and apply false' {
        Assert-ConfigHelperLoaded
        $mode = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.mode' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.mode","value":"rcopy","type":"enum","description":"x"}' `
            -Stderr '' -Context ProjectRoot
        $apply = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"x"}' `
            -Stderr '' -Context ProjectRoot

        $result = Test-Phase00IsolationDiagnostic -ModeResult $mode -ApplyResult $apply -Context ProjectRoot

        $result.Decision | Should Be 'DIAGNOSTIC_OK_NOT_AUTHORIZATION'
        @($result.Reasons) | Should Be @('CONFIG_VALUES_MATCH_CAPTURE_ONLY_EXPECTATION')
        $result.Fallback | Should Be $null
        $result.Mode | Should Be 'rcopy'
        $result.Apply | Should Be $false
        (($result | ConvertTo-Json -Depth 8) -match 'ALLOW_PARALLEL') | Should Be $false
    }

    It 'refuses mode none and apply true with both unsafe-setting reasons' {
        Assert-ConfigHelperLoaded
        $mode = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.mode' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.mode","value":"none","type":"enum","description":"x"}' `
            -Stderr '' -Context NoProject
        $apply = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.apply","value":true,"type":"boolean","description":"x"}' `
            -Stderr '' -Context NoProject

        $result = Test-Phase00IsolationDiagnostic -ModeResult $mode -ApplyResult $apply -Context NoProject

        $result.Decision | Should Be 'REFUSE'
        @($result.Reasons) | Should Be @('ISOLATION_MODE_NONE','ISOLATION_APPLY_TRUE')
        $result.Fallback | Should Be 'SEQUENTIAL_NON_ISOLATED_DISCLOSED'
    }

    It 'adds cwd diagnosis when a nested cwd loses the project settings' {
        Assert-ConfigHelperLoaded
        $mode = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.mode' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.mode","value":"none","type":"enum","description":"x"}' `
            -Stderr '' -Context NestedCwd
        $apply = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.apply","value":true,"type":"boolean","description":"x"}' `
            -Stderr '' -Context NestedCwd

        $result = Test-Phase00IsolationDiagnostic -ModeResult $mode -ApplyResult $apply -Context NestedCwd

        $result.Decision | Should Be 'REFUSE'
        @($result.Reasons) | Should Be @(
            'ISOLATION_MODE_NONE',
            'ISOLATION_APPLY_TRUE',
            'CWD_PROJECT_CONFIG_NOT_DISCOVERED'
        )
    }

    It 'propagates unreadable config reasons into refusal' {
        Assert-ConfigHelperLoaded
        $mode = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.mode' `
            -ExitCode 9 -Stdout '' -Stderr 'generic failure' -Context ToolUnavailable
        $apply = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout 'not-json' -Stderr '' -Context ToolUnavailable

        $result = Test-Phase00IsolationDiagnostic -ModeResult $mode -ApplyResult $apply -Context ToolUnavailable

        $result.Decision | Should Be 'REFUSE'
        @($result.Reasons) | Should Be @('CONFIG_READ_NONZERO','CONFIG_JSON_INVALID')
        $result.Mode | Should Be $null
        $result.Apply | Should Be $null
    }
}

Describe 'E3-A/E3-H fixture and runner surface' {
    It 'provides the reviewed fixture files and executable runner' {
        Test-Path -LiteralPath (Join-Path $e3aFixtureRoot 'global-config.yml') -PathType Leaf | Should Be $true
        Test-Path -LiteralPath (Join-Path $e3aFixtureRoot 'project-config.yml') -PathType Leaf | Should Be $true
        Test-Path -LiteralPath (Join-Path $e3aFixtureRoot 'overlay-config.yml') -PathType Leaf | Should Be $true
        Test-Path -LiteralPath (Join-Path $e3aFixtureRoot 'prompts\A4-apply-non-authority.md') -PathType Leaf | Should Be $true
        Test-Path -LiteralPath (Join-Path $e3aFixtureRoot '.omp\agents\phase00-apply-probe.md') -PathType Leaf | Should Be $true
        Test-Path -LiteralPath (Join-Path $e3hFixtureRoot 'prompts\H5-config-command-unavailable.md') -PathType Leaf | Should Be $true
        Test-Path -LiteralPath $runnerPath -PathType Leaf | Should Be $true
    }

    It 'uses a portable A4 sentinel command that executes exactly as reviewed' {
        $agentPath = Join-Path $e3aFixtureRoot '.omp\agents\phase00-apply-probe.md'
        $content = Get-Content -Raw -LiteralPath $agentPath -Encoding UTF8
        $match = [regex]::Match($content, '(?ms)^<command>\r?\n(?<command>.+?)\r?\n</command>$')
        $match.Success | Should Be $true
        $command = $match.Groups['command'].Value.Trim()
        $command.StartsWith('python -c ') | Should Be $true

        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("omp-phase00-a4-command-{0}" -f [guid]::NewGuid().ToString('N'))
        try {
            New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
            Push-Location $tempRoot
            try {
                $output = Invoke-Expression $command
            } finally {
                Pop-Location
            }
            $output.Trim() | Should Be 'PHASE00_A4_APPLY_TRUE_SENTINEL'
            Get-Content -Raw -LiteralPath (Join-Path $tempRoot 'phase00-a4-sentinel.txt') -Encoding UTF8 | Should Be 'PHASE00_A4_APPLY_TRUE_SENTINEL'
        } finally {
            if (Test-Path -LiteralPath $tempRoot) {
                $resolved = [System.IO.Path]::GetFullPath($tempRoot)
                $prefix = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\','/') + [System.IO.Path]::DirectorySeparatorChar
                if (-not ($resolved + [System.IO.Path]::DirectorySeparatorChar).StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "Unsafe test cleanup path: $resolved"
                }
                Remove-Item -LiteralPath $resolved -Recurse -Force
            }
        }
    }

    It 'exports the runner boundary functions' {
        $script:runnerLoaded | Should Be $true
        foreach ($name in @(
            'Get-Phase00ConfigCaseDefinition',
            'Get-Phase00InstalledOmpPath',
            'Get-Phase00ConfigProcessEnvironment',
            'Get-Phase00ConfigCommandArguments',
            'Get-Phase00ParentArguments',
            'Get-Phase00PathWithoutOmp',
            'Initialize-Phase00ConfigFixture',
            'Invoke-Phase00CapturedProcess',
            'Invoke-Phase00ConfigEvidenceCase'
        )) {
            (Get-Command $name -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        }
    }

    It 'builds both H3 unsupported-overlay argument placements exactly' {
        $script:runnerLoaded | Should Be $true
        $overlay = 'C:\Temp\phase00\overlay.yml'
        $before = @(Get-Phase00ConfigCommandArguments -Key 'task.isolation.apply' `
            -OverlayPath $overlay -OverlayPosition Before)
        $after = @(Get-Phase00ConfigCommandArguments -Key 'task.isolation.apply' `
            -OverlayPath $overlay -OverlayPosition After)

        ($before -join '|') | Should Be "--config|$overlay|config|get|task.isolation.apply|--json"
        ($after -join '|') | Should Be "config|get|task.isolation.apply|--json|--config|$overlay"
    }

    It 'builds direct config-get arguments without an overlay' {
        $script:runnerLoaded | Should Be $true
        $arguments = @(Get-Phase00ConfigCommandArguments -Key 'task.isolation.mode')
        ($arguments -join '|') | Should Be 'config|get|task.isolation.mode|--json'
    }

    It 'removes only the normalized OMP directory from a child PATH' {
        $script:runnerLoaded | Should Be $true
        $separator = [System.IO.Path]::PathSeparator
        $inputPath = @('C:\Windows\System32','C:\Users\MrThien\AppData\Local\omp','C:\Program Files\Git\cmd') -join $separator
        $result = Get-Phase00PathWithoutOmp -PathValue $inputPath `
            -OmpDirectory 'c:\users\mrthien\appdata\local\omp\'

        $result | Should Be (@('C:\Windows\System32','C:\Program Files\Git\cmd') -join $separator)
    }

    It 'constructs a process-local agent directory override without a credential value' {
        $script:runnerLoaded | Should Be $true
        $environment = Get-Phase00ConfigProcessEnvironment -AgentDirectory 'C:\Temp\phase00-agent'

        $environment.PI_CODING_AGENT_DIR | Should Be 'C:\Temp\phase00-agent'
        $environment.Keys.Count | Should Be 1
    }

    It 'pins provider parents to the expected tools and disposable paths' {
        $script:runnerLoaded | Should Be $true
        $a4 = @(Get-Phase00ParentArguments -CaseId A4 -FixtureRoot 'C:\Temp\project' `
            -SessionDirectory 'C:\Temp\sessions' -ConfigPath 'C:\Temp\project\overlay.yml' `
            -Model 'omniroute/codex/gpt-5.6-sol-high' -Prompt 'A4 prompt')
        $h5 = @(Get-Phase00ParentArguments -CaseId H5 -FixtureRoot 'C:\Temp\project' `
            -SessionDirectory 'C:\Temp\sessions' -ConfigPath 'C:\Temp\project\overlay.yml' `
            -Model 'omniroute/codex/gpt-5.6-sol-high' -Prompt 'H5 prompt')

        ($a4 -join '|') | Should Match ([regex]::Escape('--tools|task,bash,eval'))
        ($h5 -join '|') | Should Match ([regex]::Escape('--tools|bash'))
        ($h5 -join '|') | Should Not Match ([regex]::Escape('task,bash,eval'))
        $a4[-1] | Should Be 'A4 prompt'
        $h5[-1] | Should Be 'H5 prompt'
    }

    It 'materializes A1 entirely under a caller-provided disposable root' {
        $script:runnerLoaded | Should Be $true
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("omp-phase00-config-fixture-{0}" -f [guid]::NewGuid().ToString('N'))
        try {
            $fixture = Initialize-Phase00ConfigFixture -DisposableRoot $tempRoot -CaseId A1

            $fixture.DisposableRoot | Should Be ([System.IO.Path]::GetFullPath($tempRoot))
            Test-Path -LiteralPath (Join-Path $fixture.AgentDirectory 'config.yml') -PathType Leaf | Should Be $true
            Test-Path -LiteralPath (Join-Path $fixture.ProjectRoot '.omp\config.yml') -PathType Leaf | Should Be $true
            Test-Path -LiteralPath $fixture.NestedCwd -PathType Container | Should Be $true
            Test-Path -LiteralPath (Join-Path $fixture.NestedCwd '.omp') | Should Be $false
            Test-Path -LiteralPath $fixture.OverlayPath -PathType Leaf | Should Be $true
            ([System.IO.Path]::GetFullPath($fixture.AgentDirectory)).StartsWith($fixture.DisposableRoot, [System.StringComparison]::OrdinalIgnoreCase) | Should Be $true
        } finally {
            if (Test-Path -LiteralPath $tempRoot) {
                $resolved = [System.IO.Path]::GetFullPath($tempRoot)
                $prefix = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\','/') + [System.IO.Path]::DirectorySeparatorChar
                if (-not ($resolved + [System.IO.Path]::DirectorySeparatorChar).StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "Unsafe test cleanup path: $resolved"
                }
                Remove-Item -LiteralPath $resolved -Recurse -Force
            }
        }
    }

    It 'captures a real child process and restores its working directory and environment' {
        $script:runnerLoaded | Should Be $true
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("omp-phase00-process-test-{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
        $stderrPath = Join-Path $tempRoot 'stderr.txt'
        $variableName = 'PHASE00_CAPTURE_TEST_VALUE'
        $before = [Environment]::GetEnvironmentVariable($variableName, 'Process')
        try {
            $shellExe = (Get-Process -Id $PID).Path
            $arguments = @('-NoProfile','-Command',"[Console]::Out.Write(`$env:$variableName); [Console]::Error.Write('phase00-stderr')")
            $result = Invoke-Phase00CapturedProcess -Executable $shellExe -Arguments $arguments `
                -WorkingDirectory $tempRoot -Environment @{$variableName = 'phase00-stdout'} `
                -StderrPath $stderrPath -TimeoutSeconds 30

            $result.ExitCode | Should Be 0
            $result.Stdout | Should Be 'phase00-stdout'
            $result.Stderr.TrimEnd() | Should Be 'phase00-stderr'
            $result.CompletedAt -ge $result.StartedAt | Should Be $true
            $after = [Environment]::GetEnvironmentVariable($variableName, 'Process')
            if ($null -eq $before) {
                [string]::IsNullOrEmpty($after) | Should Be $true
            } else {
                $after | Should Be $before
            }
        } finally {
            [Environment]::SetEnvironmentVariable($variableName, $before, 'Process')
            if (Test-Path -LiteralPath $tempRoot) {
                $resolved = [System.IO.Path]::GetFullPath($tempRoot)
                $prefix = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\','/') + [System.IO.Path]::DirectorySeparatorChar
                if (-not ($resolved + [System.IO.Path]::DirectorySeparatorChar).StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "Unsafe test cleanup path: $resolved"
                }
                Remove-Item -LiteralPath $resolved -Recurse -Force
            }
        }
    }

    It 'redacts a disposable path nested through two JSON string layers' {
        $disposable = 'C:\Users\Example\AppData\Local\Temp\omp-phase00-a4-test'
        $inner = [ordered]@{ outputPath = "$disposable\sessions\worker.md" } | ConvertTo-Json -Compress
        $outer = [ordered]@{ text = $inner } | ConvertTo-Json -Compress

        $safe = Protect-Phase00EvidenceText -Text $outer -RepositoryRoot $repositoryRoot -DisposableRoot $disposable

        $safe.Contains('<DISPOSABLE_ROOT>') | Should Be $true
        $safe.Contains('Users') | Should Be $false
        $safe.Contains('omp-phase00-a4-test') | Should Be $false
    }

    It 'executes A1 end to end in disposable roots and persists only sanitized evidence' {
        $script:runnerLoaded | Should Be $true
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("omp-phase00-a1-e2e-{0}" -f [guid]::NewGuid().ToString('N'))
        $evidenceRoot = Join-Path $tempRoot 'evidence'
        $pinned = Get-E3APinnedTestOmp
        try {
            $result = Invoke-Phase00ConfigEvidenceCase -CaseId A1 `
                -Model 'omniroute/codex/gpt-5.6-sol-high' -Attempt 1 `
                -EvidenceRoot $evidenceRoot -OmpExecutable $pinned

            $result.Analysis.Status | Should Be 'PASS'
            $result.CleanupSucceeded | Should Be $true
            Test-Path -LiteralPath $result.RunPath -PathType Leaf | Should Be $true
            Test-Path -LiteralPath $result.StdoutPath -PathType Leaf | Should Be $true
            Test-Path -LiteralPath $result.StderrPath -PathType Leaf | Should Be $true

            $run = Get-Content -Raw -LiteralPath $result.RunPath -Encoding UTF8 | ConvertFrom-Json
            $stdout = Get-Content -Raw -LiteralPath $result.StdoutPath -Encoding UTF8 | ConvertFrom-Json
            $run.case | Should Be 'A1'
            $run.analysis.Status | Should Be 'PASS'
            $run.omp_runtime.selection | Should Be 'EXPLICIT_SOURCE'
            $run.omp_runtime.sha256 | Should Be `
                '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6'
            $run.cleanup_succeeded | Should Be $true
            $run.live_home_metadata.changed_count | Should Be 0
            @($stdout.operations).Count | Should Be 2
            @($stdout.operations.key) | Should Be @('task.isolation.mode','task.isolation.apply')
            (Get-Content -Raw -LiteralPath $result.RunPath -Encoding UTF8) -match [regex]::Escape($tempRoot) | Should Be $false
        } finally {
            if (Test-Path -LiteralPath $tempRoot) {
                $resolved = [System.IO.Path]::GetFullPath($tempRoot)
                $prefix = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\','/') + [System.IO.Path]::DirectorySeparatorChar
                if (-not ($resolved + [System.IO.Path]::DirectorySeparatorChar).StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "Unsafe test cleanup path: $resolved"
                }
                Remove-Item -LiteralPath $resolved -Recurse -Force
            }
        }
    }
}

Describe 'Direct E3-A/E3-H case adjudication' {
    It 'passes A1 only for exact project-root rcopy and apply false observations' {
        $mode = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.mode' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.mode","value":"rcopy","type":"enum","description":"x"}' `
            -Stderr '' -Context ProjectRoot
        $apply = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"x"}' `
            -Stderr '' -Context ProjectRoot

        $result = Test-Phase00A1Evidence -ModeResult $mode -ApplyResult $apply

        $result.Status | Should Be 'PASS'
        @($result.Reasons) | Should Be @('A1_EFFECTIVE_PROJECT_VALUES')
        $result.DiagnosticDecision | Should Be 'DIAGNOSTIC_OK_NOT_AUTHORIZATION'
    }

    It 'passes A2 only for a nonzero unknown-key refusal with no observation' {
        $unknown = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.__phase00_unknown' -ExitCode 1 -Stdout '' `
            -Stderr 'Unknown setting: task.isolation.__phase00_unknown' -Context DirectRead

        $result = Test-Phase00A2Evidence -UnknownResult $unknown

        $result.Status | Should Be 'PASS'
        @($result.Reasons) | Should Be @('A2_UNKNOWN_KEY_REFUSED')
    }

    It 'passes A3 only when nested cwd loses the root project values' {
        $rootMode = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.mode' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.mode","value":"rcopy","type":"enum","description":"x"}' `
            -Stderr '' -Context ProjectRoot
        $rootApply = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"x"}' `
            -Stderr '' -Context ProjectRoot
        $nestedMode = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.mode' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.mode","value":"none","type":"enum","description":"x"}' `
            -Stderr '' -Context NestedCwd
        $nestedApply = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.apply","value":true,"type":"boolean","description":"x"}' `
            -Stderr '' -Context NestedCwd

        $result = Test-Phase00A3Evidence -RootModeResult $rootMode -RootApplyResult $rootApply `
            -NestedModeResult $nestedMode -NestedApplyResult $nestedApply

        $result.Status | Should Be 'PASS'
        @($result.Reasons) | Should Be @('A3_CWD_PROJECT_CONFIG_NOT_DISCOVERED')
        $result.NestedDecision | Should Be 'REFUSE'
    }

    It 'passes H1 while retaining diagnostic-only semantics' {
        $apply = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"x"}' `
            -Stderr '' -Context ProjectRoot

        $result = Test-Phase00H1Evidence -GlobalApply $true -ProjectApplyResult $apply

        $result.Status | Should Be 'PASS'
        @($result.Reasons) | Should Be @('H1_PROJECT_OVERRIDES_GLOBAL')
        $result.DiagnosticDecision | Should Be 'DIAGNOSTIC_OK_NOT_AUTHORIZATION'
    }

    It 'passes H2 only when defaults refuse with both unsafe reasons' {
        $mode = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.mode' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.mode","value":"none","type":"enum","description":"x"}' `
            -Stderr '' -Context NoProject
        $apply = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.apply","value":true,"type":"boolean","description":"x"}' `
            -Stderr '' -Context NoProject

        $result = Test-Phase00H2Evidence -ModeResult $mode -ApplyResult $apply

        $result.Status | Should Be 'PASS'
        @($result.RefusalReasons) | Should Be @('ISOLATION_MODE_NONE','ISOLATION_APPLY_TRUE')
        $result.Fallback | Should Be 'SEQUENTIAL_NON_ISOLATED_DISCLOSED'
    }

    It 'passes amended H3 only when both overlay placements are unsupported and refused' {
        $before = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 1 -Stdout '' -Stderr "error: Unknown option '--config'." -Context CliOverlay
        $after = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 1 -Stdout '' -Stderr "error: Unknown option '--config'." -Context CliOverlay

        $result = Test-Phase00H3Evidence -BeforeResult $before -AfterResult $after

        $result.Status | Should Be 'PASS'
        @($result.Reasons) | Should Be @('H3_CONFIG_CLI_OVERLAY_UNSUPPORTED_FAIL_CLOSED')
        $result.PrecedenceRead | Should Be $false
    }

    It 'passes H4 only with explicit cwd-scoping refusal and disclosed fallback' {
        $mode = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.mode' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.mode","value":"none","type":"enum","description":"x"}' `
            -Stderr '' -Context NestedCwd
        $apply = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.apply","value":true,"type":"boolean","description":"x"}' `
            -Stderr '' -Context NestedCwd

        $result = Test-Phase00H4Evidence -ModeResult $mode -ApplyResult $apply

        $result.Status | Should Be 'PASS'
        @($result.RefusalReasons) -contains 'CWD_PROJECT_CONFIG_NOT_DISCOVERED' | Should Be $true
        $result.Fallback | Should Be 'SEQUENTIAL_NON_ISOLATED_DISCLOSED'
    }

    It 'passes H6 only when nonzero and invalid JSON controls remain distinct refusals' {
        $nonzero = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 9 -Stdout '' -Stderr 'generic failure' -Context Synthetic
        $invalidJson = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout 'not-json' -Stderr '' -Context Synthetic

        $result = Test-Phase00H6Evidence -NonzeroResult $nonzero -InvalidJsonResult $invalidJson

        $result.Status | Should Be 'PASS'
        @($result.Reasons) | Should Be @('H6_DISTINCT_FAIL_CLOSED_CONTROLS')
        $result.RuntimeCall | Should Be $false
    }
}

Describe 'Provider E3-A/E3-H case adjudication' {
    It 'passes A4 when the supported wire excludes apply and forced raw apply false cannot prevent session apply true' {
        $attestation = '{"probe":"phase00-task-item-wire-v1","item_keys":["agent","isolated","name","outputSchema","schemaMode","task"],"has_isolated":true,"has_apply":false,"decision":"RUN_RAW_NON_AUTHORITY_CONTROL"}'
        $events = @(
            (New-ConfigToolStart 'a4-wire' 'bash' ([ordered]@{ command = 'Write-Output attestation' })),
            (New-ConfigToolEnd 'a4-wire' 'bash' ([ordered]@{
                content = @([ordered]@{ type = 'text'; text = "$attestation`n`nWall time: 0.1 seconds" })
                details = [ordered]@{ wallTimeMs = 100 }
            })),
            (New-ConfigToolStart 'a4-eval' 'eval' ([ordered]@{
                language = 'js'
                code = 'await tool.task({context:"Phase 00 A4 forced raw apply non-authority control",tasks:[{name:"a4-apply-probe",agent:"phase00-apply-probe",task:"Create sentinel",isolated:true,apply:false}]})'
                title = 'A4 raw apply control'
            })),
            (New-ConfigToolEnd 'a4-eval' 'eval' ([ordered]@{
                content = @([ordered]@{ type = 'text'; text = 'a4-apply-probe completed. Applied patches: yes' })
                details = [ordered]@{ language = 'js'; durationMs = 3000 }
            }))
        )

        $result = Test-Phase00A4Evidence -Events $events -SentinelObserved $true

        $result.Status | Should Be 'PASS'
        @($result.Reasons) | Should Be @('A4_PER_ITEM_APPLY_NOT_AUTHORITY')
        $result.HasIsolated | Should Be $true
        $result.HasApply | Should Be $false
        $result.SentinelApplied | Should Be $true
        $result.EvalBridgeProvesArkTypeDeletion | Should Be $false
    }

    It 'fails A4 when apply appears on the supported item wire' {
        $attestation = '{"probe":"phase00-task-item-wire-v1","item_keys":["agent","apply","isolated","task"],"has_isolated":true,"has_apply":true,"decision":"UNEXPECTED_TASK_ITEM_WIRE"}'
        $events = @(
            (New-ConfigToolStart 'a4-wire' 'bash' ([ordered]@{ command = 'Write-Output attestation' })),
            (New-ConfigToolEnd 'a4-wire' 'bash' ([ordered]@{
                content = @([ordered]@{ type = 'text'; text = $attestation })
                details = [ordered]@{}
            }))
        )

        $result = Test-Phase00A4Evidence -Events $events -SentinelObserved $false

        $result.Status | Should Be 'FAIL'
        @($result.Reasons) -contains 'A4_SUPPORTED_WIRE_EXPOSES_APPLY' | Should Be $true
    }

    It 'invalidates A4 when the parent retries the wire-attestation bash call' {
        $attestation = '{"probe":"phase00-task-item-wire-v1","item_keys":["agent","isolated","task"],"has_isolated":true,"has_apply":false,"decision":"RUN_RAW_NON_AUTHORITY_CONTROL"}'
        $events = @(
            (New-ConfigToolStart 'a4-wire-failed' 'bash' ([ordered]@{ command = 'Write-Output attestation' })),
            (New-ConfigToolEnd 'a4-wire-failed' 'bash' ([ordered]@{ content = @([ordered]@{ type = 'text'; text = 'command not found' }); details = [ordered]@{ exitCode = 127 } }) $true),
            (New-ConfigToolStart 'a4-wire' 'bash' ([ordered]@{ command = 'powershell -NoProfile -Command attestation' })),
            (New-ConfigToolEnd 'a4-wire' 'bash' ([ordered]@{ content = @([ordered]@{ type = 'text'; text = $attestation }); details = [ordered]@{} })),
            (New-ConfigToolStart 'a4-eval' 'eval' ([ordered]@{
                language = 'js'
                code = 'await tool.task({context:"x",tasks:[{agent:"phase00-apply-probe",task:"x",isolated:true,apply:false}]})'
            })),
            (New-ConfigToolEnd 'a4-eval' 'eval' ([ordered]@{ content = @([ordered]@{ type = 'text'; text = 'Applied patches: yes' }); details = [ordered]@{} }))
        )

        $result = Test-Phase00A4Evidence -Events $events -SentinelObserved $true

        $result.Status | Should Be 'INVALID_RUN'
        @($result.Reasons) -contains 'A4_BASH_CALL_COUNT_MISMATCH' | Should Be $true
    }

    It 'invalidates A4 when the eval call is unpaired' {
        $attestation = '{"probe":"phase00-task-item-wire-v1","item_keys":["agent","isolated","task"],"has_isolated":true,"has_apply":false,"decision":"RUN_RAW_NON_AUTHORITY_CONTROL"}'
        $events = @(
            (New-ConfigToolStart 'a4-wire' 'bash' ([ordered]@{ command = 'Write-Output attestation' })),
            (New-ConfigToolEnd 'a4-wire' 'bash' ([ordered]@{ content = @([ordered]@{ type = 'text'; text = $attestation }); details = [ordered]@{} })),
            (New-ConfigToolStart 'a4-eval' 'eval' ([ordered]@{ language = 'js'; code = 'await tool.task({})' }))
        )

        $result = Test-Phase00A4Evidence -Events $events -SentinelObserved $false

        $result.Status | Should Be 'INVALID_RUN'
    }

    It 'invalidates A4 when the nested worker aborts before producing a merge observation' {
        $attestation = '{"probe":"phase00-task-item-wire-v1","item_keys":["agent","isolated","task"],"has_isolated":true,"has_apply":false,"decision":"RUN_RAW_NON_AUTHORITY_CONTROL"}'
        $events = @(
            (New-ConfigToolStart 'a4-wire' 'bash' ([ordered]@{ command = 'Write-Output attestation' })),
            (New-ConfigToolEnd 'a4-wire' 'bash' ([ordered]@{ content = @([ordered]@{ type = 'text'; text = $attestation }); details = [ordered]@{} })),
            (New-ConfigToolStart 'a4-eval' 'eval' ([ordered]@{
                language = 'js'
                code = 'await tool.task({context:"x",tasks:[{agent:"phase00-apply-probe",task:"x",isolated:true,apply:false}]})'
            })),
            (New-ConfigToolEnd 'a4-eval' 'eval' ([ordered]@{
                content = @([ordered]@{ type = 'text'; text = '<task-result status="cancelled"><abort-reason>command failed</abort-reason>{"aborted":true}</task-result>' })
                details = [ordered]@{ language = 'js' }
            }))
        )

        $result = Test-Phase00A4Evidence -Events $events -SentinelObserved $false

        $result.Status | Should Be 'INVALID_RUN'
        @($result.Reasons) -contains 'A4_CHILD_ABORTED' | Should Be $true
    }

    It 'passes H5 only for a structured command-unavailable bash failure before task dispatch' {
        $events = @(
            (New-ConfigToolStart 'h5-bash' 'bash' ([ordered]@{ command = 'omp config get task.isolation.mode --json' })),
            (New-ConfigToolEnd 'h5-bash' 'bash' ([ordered]@{
                content = @([ordered]@{ type = 'text'; text = "omp: The term 'omp' is not recognized as a command." })
                details = [ordered]@{ exitCode = 1; wallTimeMs = 50 }
            }) $true)
        )

        $result = Test-Phase00H5Evidence -Events $events

        $result.Status | Should Be 'PASS'
        @($result.Reasons) | Should Be @('H5_CONFIG_COMMAND_UNAVAILABLE')
        $result.ConfigReason | Should Be 'CONFIG_COMMAND_UNAVAILABLE'
        $result.TaskDispatchCount | Should Be 0
    }

    It 'invalidates H5 when only prose claims the command was unavailable' {
        $events = @(
            [pscustomobject][ordered]@{ type = 'message_start'; message = [ordered]@{ role = 'assistant'; content = @([ordered]@{ type = 'text'; text = 'omp was unavailable' }) } }
        )

        $result = Test-Phase00H5Evidence -Events $events

        $result.Status | Should Be 'INVALID_RUN'
        @($result.Reasons) -contains 'H5_STRUCTURED_BASH_EVIDENCE_MISSING' | Should Be $true
    }

    It 'records complete process provenance in every provider run record' {
        $runPaths = @(
            (Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-A\raw\A4-attempt-004.run.json'),
            (Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-H\raw\H5-attempt-002.run.json')
        )
        foreach ($path in $runPaths) {
            Test-Path -LiteralPath $path -PathType Leaf | Should Be $true
            $run = Get-Content -Raw -LiteralPath $path -Encoding UTF8 | ConvertFrom-Json
            $run.process_exit_code | Should Be 0
            [string]::IsNullOrWhiteSpace([string]$run.started_at) | Should Be $false
            [string]::IsNullOrWhiteSpace([string]$run.completed_at) | Should Be $false
            [long]$run.duration_ms -gt 0 | Should Be $true
        }
    }
}

Describe 'Durable E3-A/E3-H closure contract' {
    It 'records one PASS case file for A1-A4 and H1-H6' {
        $expected = [ordered]@{
            'E3-A' = @('A1','A2','A3','A4')
            'E3-H' = @('H1','H2','H3','H4','H5','H6')
        }
        foreach ($experiment in $expected.Keys) {
            foreach ($case in $expected[$experiment]) {
                $path = Join-Path $repositoryRoot "docs\evidence\phase-00\$experiment\$case.yml"
                Test-Path -LiteralPath $path -PathType Leaf | Should Be $true
                $content = Get-Content -Raw -LiteralPath $path -Encoding UTF8
                $content | Should Match "(?m)^experiment: $([regex]::Escape($experiment))$"
                $content | Should Match "(?m)^case: $([regex]::Escape($case))$"
                $content | Should Match '(?m)^status: PASS$'
            }
        }
    }

    It 'selects only complete attempts and discloses every non-gating A4/H5 attempt' {
        $a4 = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-A\A4.yml') -Encoding UTF8
        $h5 = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-H\H5.yml') -Encoding UTF8

        $a4 | Should Match '(?m)^  selected_attempt: 4$'
        $a4 | Should Match '(?m)^  - attempt: 1$'
        $a4 | Should Match '(?m)^  - attempt: 2$'
        $a4 | Should Match '(?m)^  - attempt: 3$'
        $a4 | Should Match '(?m)^    gate_power: NONE$'
        $h5 | Should Match '(?m)^  selected_attempt: 2$'
        $h5 | Should Match '(?m)^  - attempt: 1$'
        $h5 | Should Match '(?m)^    gate_power: NONE$'
    }

    It 'records shared-source and synthetic cases without inventing runtime calls' {
        $h1 = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-H\H1.yml') -Encoding UTF8
        $h4 = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-H\H4.yml') -Encoding UTF8
        $h6 = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-H\H6.yml') -Encoding UTF8

        $h1 | Should Match '(?m)^  shared_raw_case: A1$'
        $h4 | Should Match '(?m)^  shared_raw_case: A3$'
        $h6 | Should Match '(?m)^  runtime_call: false$'
        $h6 | Should Match '(?m)^  nonzero_reason: CONFIG_READ_NONZERO$'
        $h6 | Should Match '(?m)^  invalid_json_reason: CONFIG_JSON_INVALID$'
    }

    It 'records PASS conclusions with explicit epistemic non-claims' {
        $a = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-A\conclusion.yml') -Encoding UTF8
        $h = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-H\conclusion.yml') -Encoding UTF8

        $a | Should Match '(?m)^experiment: E3-A$'
        $a | Should Match '(?m)^status: PASS$'
        $a | Should Match '(?m)^  A4: PASS$'
        $a | Should Match 'does not prove where ArkType deletion occurs'
        $h | Should Match '(?m)^experiment: E3-H$'
        $h | Should Match '(?m)^status: PASS$'
        $h | Should Match '(?m)^  H6: PASS$'
        $h | Should Match 'does not attest a parent launch overlay'
    }

    It 'records terminal E3-A through E3-L rows while parallel mode stays disabled' {
        . (Join-Path $repositoryRoot 'scripts\lib\phase00-evidence.ps1')
        $manifest = Read-Phase00Manifest -Path (Join-Path $repositoryRoot 'docs\evidence\phase-00\manifest.yml')
        $entries = @{}
        foreach ($entry in @($manifest.Entries)) { $entries[$entry.id] = $entry }

        foreach ($id in @(
            'E3-A','E3-B','E3-C','E3-D','E3-E','E3-F','E3-G','E3-H',
            'E3-I','E3-J','E3-K','E3-L'
        )) {
            $entries[$id].state | Should Be 'PASS'
        }
        $entries['E3-M'].state | Should Be 'DEFERRED_PARALLEL_DISABLED'
        $manifest.parallel_mode | Should Be 'DISABLED'
    }
}
