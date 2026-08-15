#Requires -Version 5.1

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-e5-evidence.ps1'
if (Test-Path -LiteralPath $helperPath -PathType Leaf) { . $helperPath }
$contractHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-evidence.ps1'
if (Test-Path -LiteralPath $contractHelperPath -PathType Leaf) { . $contractHelperPath }

function New-E5ChildEvents {
    param(
        [Parameter(Mandatory)][string[]]$Tools,
        [string]$Marker = 'E5_TEST_OK',
        [switch]$CallLsp,
        [bool]$LspSuccess = $true,
        [string]$LspText = 'probe.ts:1:1',
        [string]$Role = 'allowlisted'
    )

    $events = @([pscustomobject]@{
        type = 'session_init'; tools = $Tools; agent = "e5-$Role"
        systemPrompt = 'bounded E5 fixture'; task = 'probe LSP'
        resolvedModel = 'omniroute/oc/mimo-v2.5-free'; readOnly = $true
    })
    if ($CallLsp) {
        $events += [pscustomobject]@{
            type = 'message'; message = [pscustomobject]@{
                role = 'assistant'
                content = @([pscustomobject]@{
                    type = 'toolCall'; id = 'lsp-1'; name = 'lsp'
                    arguments = [pscustomobject]@{
                        action = 'references'; file = 'probe.ts'; line = 1
                        symbol = 'alpha'
                    }
                })
                usage = [pscustomobject]@{ input = 1000; cacheRead = 0; totalTokens = 1050 }
            }
        }
        $events += [pscustomobject]@{
            type = 'message'; message = [pscustomobject]@{
                role = 'toolResult'; toolCallId = 'lsp-1'; toolName = 'lsp'
                content = @([pscustomobject]@{ type = 'text'; text = $LspText })
                details = [pscustomobject]@{
                    action = 'references'; success = $LspSuccess
                    serverName = if ($LspSuccess) { 'phase00-fake' } else { $null }
                }
                isError = $false
            }
        }
    }
    $events += [pscustomobject]@{
        type = 'message'; message = [pscustomobject]@{
            role = 'assistant'
            content = @([pscustomobject]@{
                type = 'toolCall'; id = 'yield-1'; name = 'yield'
                arguments = [pscustomobject]@{
                    result = "{`"data`":{`"completion`":`"$Marker`"}}"
                }
            })
            usage = [pscustomobject]@{ input = 80; cacheRead = 1024; totalTokens = 1150 }
        }
    }
    @($events)
}

Describe 'E5 four-condition LSP oracle' {
    It 'loads the focused evidence helper' {
        (Get-Command Test-Phase00E5Case -ErrorAction SilentlyContinue) |
            Should Not BeNullOrEmpty
    }

    It 'distinguishes task.enableLsp false as E5-A' {
        $result = Test-Phase00E5Case -CaseId 'E5-A' -Role allowlisted `
            -Events (New-E5ChildEvents @('yield','hub') -Marker 'E5_A_LSP_ABSENT')
        $result.Status | Should Be 'PASS'
        $result.LspPresent | Should Be $false
        $result.Cause | Should Be 'TASK_ENABLE_LSP_FALSE'
        $result.Remediation | Should Be 'MERGE_PROJECT_TASK_ENABLE_LSP_TRUE'
    }

    It 'accepts callable LSP for each E5-B production role' {
        foreach ($role in @('explorer','implementer','reviewer')) {
            $marker = 'E5_B_{0}_LSP_OK' -f $role.ToUpperInvariant()
            $result = Test-Phase00E5Case -CaseId 'E5-B' -Role $role `
                -Events (New-E5ChildEvents @('lsp','yield','hub') `
                    -Marker $marker -CallLsp -Role $role)
            $result.Status | Should Be 'PASS'
            $result.LspPresent | Should Be $true
            $result.LspCallCount | Should Be 1
            $result.LspResultSuccess | Should Be $true
        }
    }

    It 'keeps the E5-B verifier control without LSP' {
        $result = Test-Phase00E5Case -CaseId 'E5-B' -Role verifier `
            -Events (New-E5ChildEvents @('read','yield','hub') `
                -Marker 'E5_B_VERIFIER_LSP_ABSENT' -Role verifier)
        $result.Status | Should Be 'PASS'
        $result.LspPresent | Should Be $false
        $result.Cause | Should Be 'AGENT_ALLOWLIST_MISSING_CONTROL'
    }

    It 'distinguishes parent disable, allowlist omission, and lsp.enabled false' {
        $cases = @(
            [pscustomobject]@{ Id='E5-C'; Role='allowlisted'; Tools=@('yield','hub'); Marker='E5_C_LSP_ABSENT'; Cause='PARENT_SESSION_LSP_DISABLED'; Fix='RELAUNCH_PARENT_WITH_LSP' },
            [pscustomobject]@{ Id='E5-D'; Role='no-lsp'; Tools=@('read','yield','hub'); Marker='E5_D_LSP_ABSENT'; Cause='AGENT_ALLOWLIST_MISSING'; Fix='ADD_LSP_TO_AGENT_ALLOWLIST' },
            [pscustomobject]@{ Id='E5-F'; Role='allowlisted'; Tools=@('yield','hub'); Marker='E5_F_LSP_ABSENT'; Cause='LSP_ENABLED_FALSE'; Fix='ENABLE_PROJECT_LSP_ENABLED' }
        )
        foreach ($case in $cases) {
            $result = Test-Phase00E5Case -CaseId $case.Id -Role $case.Role `
                -Events (New-E5ChildEvents $case.Tools -Marker $case.Marker -Role $case.Role)
            $result.Status | Should Be 'PASS'
            $result.Cause | Should Be $case.Cause
            $result.Remediation | Should Be $case.Fix
        }
    }

    It 'distinguishes a callable tool with no language server as E5-E' {
        $result = Test-Phase00E5Case -CaseId 'E5-E' -Role allowlisted `
            -Events (New-E5ChildEvents @('lsp','yield','hub') `
                -Marker 'E5_E_TOOL_PRESENT_NO_SERVER' -CallLsp `
                -LspSuccess $false -LspText 'No language server found for this action')
        $result.Status | Should Be 'PASS'
        $result.LspPresent | Should Be $true
        $result.LspResultSuccess | Should Be $false
        $result.LspResultText | Should Be 'No language server found for this action'
        $result.Cause | Should Be 'LANGUAGE_SERVER_UNAVAILABLE'
        $result.Remediation | Should Be 'INSTALL_OR_CONFIGURE_LANGUAGE_SERVER'
    }

    It 'rejects a missing B call and an unavailable E tool' {
        (Test-Phase00E5Case -CaseId 'E5-B' -Role explorer `
            -Events (New-E5ChildEvents @('lsp','yield','hub') `
                -Marker 'E5_B_EXPLORER_LSP_OK')).Status | Should Be 'FAIL'
        (Test-Phase00E5Case -CaseId 'E5-E' -Role allowlisted `
            -Events (New-E5ChildEvents @('yield','hub') `
                -Marker 'E5_E_TOOL_PRESENT_NO_SERVER')).Status | Should Be 'FAIL'
    }
}

Describe 'E5 sequential runner contract' {
    It 'preserves direct CLI parameters and declares the exact sequential matrix' {
        $runner = Join-Path $repositoryRoot 'scripts\run-phase00-e5.ps1'
        Test-Path -LiteralPath $runner -PathType Leaf | Should Be $true
        $missing = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-e5-missing-{0}.exe" -f [guid]::NewGuid().ToString('N'))
        . $runner -Attempt 19 -Model 'omniroute/oc/mimo-v2.5-free' `
            -OmpExecutable $missing
        $script:Phase00E5CliAttempt | Should Be 19
        $script:Phase00E5CliModel | Should Be 'omniroute/oc/mimo-v2.5-free'
        $script:Phase00E5CliOmpExecutable | Should Be $missing

        $matrix = @(Get-Phase00E5Matrix)
        @($matrix | ForEach-Object { "$($_.CaseId)/$($_.Role)" }) -join ',' |
            Should Be 'E5-A/allowlisted,E5-B/explorer,E5-B/implementer,E5-B/reviewer,E5-B/verifier,E5-C/allowlisted,E5-D/no-lsp,E5-E/allowlisted,E5-F/allowlisted'
    }

    It 'uses the platform path-list separator and never overwrites evidence by default' {
        $runnerText = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot `
            'scripts\run-phase00-e5.ps1') -Encoding UTF8
        $runnerText | Should Match '\[IO\.Path\]::PathSeparator\b'
        $runnerText | Should Not Match '\[IO\.Path\]::PathSeparatorChar\b'
        $runnerText | Should Match 'E5 evidence already exists'
    }
}

Describe 'E5 terminal artifact contract' {
    It 'exposes a production validator and accepts all six terminal cases' {
        (Get-Command Test-Phase00E5ArtifactContract -ErrorAction SilentlyContinue) |
            Should Not BeNullOrEmpty
        $results = @(Test-Phase00E5ArtifactContract -RepositoryRoot $repositoryRoot)
        @($results | Where-Object Status -eq 'FAIL').Count | Should Be 0
        @($results | Where-Object Status -eq 'PASS').Count | Should BeGreaterThan 0
    }
}
