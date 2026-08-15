#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Topic08PinnedOmpSha = '3a8591a8af5b6d200088d12ca75a5517cb064fa8'

function New-Topic08BehaviorCoreResult {
    param(
        [ValidateSet('PASS', 'WARN', 'FAIL')][string]$Status,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Message
    )
    return [pscustomobject]@{ Status = $Status; Code = $Code; Message = $Message }
}

function New-Topic08BehaviorCoreBooleanResult {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$PassMessage,
        [Parameter(Mandatory)][string]$FailMessage
    )
    return New-Topic08BehaviorCoreResult -Status $(if ($Condition) { 'PASS' } else { 'FAIL' }) `
        -Code $Code -Message $(if ($Condition) { $PassMessage } else { $FailMessage })
}

function Get-Topic08BehaviorCoreGovernedFiles {
    return @(
        'template/.omp/bin/omp-managed.ps1'
        'template/.omp/contracts/agent-boundary-cli.mjs'
        'template/.omp/contracts/agent-boundary-core.mjs'
        'template/.omp/contracts/agent-boundary-schema.mjs'
        'template/.omp/contracts/behavior-core-schema.mjs'
        'template/.omp/contracts/behavior-core.mjs'
        'template/.omp/contracts/behavior-manifest.json'
        'template/.omp/contracts/component-manifest.json'
        'template/.omp/contracts/context-continuity-core.mjs'
        'template/.omp/contracts/context-continuity-schema.mjs'
        'template/.omp/contracts/managed-runtime.yml'
        'template/.omp/contracts/managed-state-client.mjs'
        'template/.omp/extensions/agent-task-boundary.js'
        'template/.omp/extensions/context-continuity.js'
        'template/.omp/agents/cheap-scout.md'
        'template/.omp/agents/worker.md'
        'template/.omp/agents/reviewer.md'
        'template/.omp/skills/task-triage/SKILL.md'
        'template/.omp/skills/systematic-debugging/SKILL.md'
        'template/.omp/skills/evidence-before-completion/SKILL.md'
        'template/.omp/state/manifest.json'
        'evals/triggers/topic08/task-triage-positive.yml'
        'evals/triggers/topic08/task-triage-negative.yml'
        'evals/triggers/topic08/systematic-debugging-positive.yml'
        'evals/triggers/topic08/systematic-debugging-negative.yml'
        'evals/triggers/topic08/evidence-before-completion-positive.yml'
        'evals/triggers/topic08/evidence-before-completion-negative.yml'
        'evals/pressure/topic08/behavior-gates.json'
        'registry/skill-lock.yml'
        'registry/adoption-ledger.yml'
        'registry/licenses.yml'
        'registry/upstreams.yml'
        'scripts/install-template.ps1'
        'scripts/uninstall-template.ps1'
        'scripts/update-skill-lock.ps1'
        'scripts/lib/topic06-agent-boundary.ps1'
        'scripts/lib/topic08-behavior-core.ps1'
        'scripts/validate-topic08-behavior-core.ps1'
        'scripts/capture-topic08-evidence.ps1'
        'scripts/tests/topic08-behavior-core.Tests.mjs'
        'scripts/tests/topic08-skill-contracts.Tests.mjs'
        'scripts/tests/topic08-agent-tasks-tool.Tests.mjs'
        'scripts/tests/topic08-behavior-gates.Tests.mjs'
        'scripts/tests/topic08-installer.Tests.ps1'
        'scripts/tests/topic08-validator-mutations.Tests.ps1'
        'docs/behavior-core.md'
        'README.md'
        'docs/architecture.md'
        'docs/customization.md'
        'docs/installation.md'
        'docs/rollback.md'
        'docs/workflow-v0.md'
        'docs/final-report.md'
        'spec/11-skills-rules-and-quality-gates.md'
        'spec/12-installation-and-rollback.md'
        'spec/13-validation-and-evaluation.md'
        'spec/README.md'
        'spec/key/01-dna.md'
        'spec/key/03-token-quality-model.md'
        'spec/phases/phase-02-core-orchestration.md'
        'spec/phases/phase-06-evaluation.md'
        'template/.omp/schemas/verification-result.schema.yml'
        'codex-topic08-portable-behavior-core-runtime-adapters-changelog.md'
        'docs/evidence/current-product/topic-08/deterministic.json'
        'docs/evidence/current-product/topic-08/manifest.json'
        'docs/evidence/current-product/topic-08/behavior-manifest.json'
    )
}

function Get-Topic08BehaviorCoreText {
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$RelativePath)
    $path = Join-Path $Root ($RelativePath -replace '/', '\')
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try { return Get-Content -Raw -LiteralPath $path -Encoding UTF8 } catch { return $null }
}

function Get-Topic08BehaviorCoreJson {
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$RelativePath)
    $text = Get-Topic08BehaviorCoreText -Root $Root -RelativePath $RelativePath
    if ($null -eq $text) { return $null }
    try { return $text | ConvertFrom-Json -AsHashtable } catch { return $null }
}

function Test-Topic08ClosedMap {
    param([object]$Value, [Parameter(Mandatory)][string[]]$Names)
    if ($Value -isnot [Collections.IDictionary]) { return $false }
    $actual = @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object)
    $expected = @($Names | Sort-Object)
    return ($actual -join '|') -ceq ($expected -join '|')
}

function Test-Topic08ContainsAll {
    param([AllowNull()][string]$Text, [Parameter(Mandatory)][string[]]$Needles)
    if ($null -eq $Text) { return $false }
    foreach ($needle in $Needles) {
        if (-not $Text.Contains($needle, [StringComparison]::Ordinal)) { return $false }
    }
    return $true
}

function Test-Topic08OrderedNeedles {
    param([Parameter(Mandatory)][string]$Text, [Parameter(Mandatory)][string[]]$Needles)
    $offset = 0
    foreach ($needle in $Needles) {
        $index = $Text.IndexOf($needle, $offset, [StringComparison]::Ordinal)
        if ($index -lt 0) { return $false }
        $offset = $index + $needle.Length
    }
    return $true
}

function Get-Topic08Sha256 {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) { return $null }
    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-Topic08NormalizedRangeHash {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][int]$StartLine,
        [Parameter(Mandatory)][int]$EndLine
    )
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) { throw 'Source file is missing.' }
    $lines = [IO.File]::ReadAllLines([IO.Path]::GetFullPath($LiteralPath))
    if ($StartLine -lt 1 -or $EndLine -lt $StartLine -or $EndLine -gt $lines.Count) {
        throw 'Source range is invalid.'
    }
    $text = (($lines[($StartLine - 1)..($EndLine - 1)] -join "`n") + "`n")
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData(
        [Text.Encoding]::UTF8.GetBytes($text)
    )).ToLowerInvariant()
}

function Get-Topic08SourceAttachmentManifest {
    return @(
        [pscustomobject]@{ Name = 'skill-discovery'; Path = 'discovery/builtin.ts'; Start = 281; End = 305; Sha256 = '6d2d6e57d647b9ce2a57efe190e037132463d5d191b4c0f6a5f2f618116e9a19'; Needles = @('async function loadSkills', 'getAncestorDirs', 'projectScans', 'userScan', 'Promise.all') }
        [pscustomobject]@{ Name = 'skill-render'; Path = 'system-prompt.ts'; Start = 836; End = 840; Sha256 = '931beb5bd10be9ed21629b0f12693ba9c3faf2da32d3c5a4a088e3e141b3dfbc'; Needles = @('const hasRead', 'skills.filter(skill => skill.hide !== true)') }
        [pscustomobject]@{ Name = 'discover-skills-sdk'; Path = 'sdk.ts'; Start = 769; End = 780; Sha256 = 'ab452ec11587f3ecb447a991722957f137940f5d4e1db8f5d30bfffd32f9cf39'; Needles = @('export async function discoverSkills', 'loadSkillsInternal') }
        [pscustomobject]@{ Name = 'autoload-resolve'; Path = 'task/structured-subagent.ts'; Start = 365; End = 370; Sha256 = '5162dc0d31fa26435a9a54597c627d1b3050b54f2042593e901399dcc4ff80f6'; Needles = @('function resolveAutoloadSkills', 'agent.autoloadSkills?.length', 'skills.find') }
        [pscustomobject]@{ Name = 'autoload-inject'; Path = 'task/executor.ts'; Start = 3233; End = 3248; Sha256 = '2f33f673faade6e8856bfa03cf8fcaf1b74de046e0c6362f7b8889842d2035d6'; Needles = @('if (options.autoloadSkills?.length)', 'buildSkillPromptMessage', 'sendCustomMessage', 'display: false') }
        [pscustomobject]@{ Name = 'rules-forward'; Path = 'task/structured-subagent.ts'; Start = 433; End = 440; Sha256 = '495547ae34a756840d3f0489160a416fbcf9da75c60159c86a7001752a4da4c9'; Needles = @('contextFiles:', 'autoloadSkills,', 'rules: session.rules') }
        [pscustomobject]@{ Name = 'skill-command'; Path = 'extensibility/skills.ts'; Start = 399; End = 449; Sha256 = '64d07db9217a0bebc0de30a2710171077f059ed85590cfa9d10060f9b5260b22'; Needles = @('getSkillSlashCommandName', 'MID_PROMPT_SKILL_RE', 'parseSkillInvocation', 'trimmedStart.startsWith("/skill:")') }
        [pscustomobject]@{ Name = 'tool-block-wrapper'; Path = 'extensibility/extensions/wrapper.ts'; Start = 200; End = 233; Sha256 = 'd4ccc00bc2154ad295277b178e89e62b2c4efe158838b3dcf7bade82db67c29c'; Needles = @('hasHandlers("tool_call")', 'emitToolCall', 'if (callResult?.block)', 'throw new Error(reason)') }
        [pscustomobject]@{ Name = 'tool-call-failclosed'; Path = 'extensibility/extensions/runner.ts'; Start = 1072; End = 1137; Sha256 = '561b1d0e642262ee3438405ad117501ec1093cb2ef071853fbadd88067cdd05f'; Needles = @('async emitToolCall', 'raceHandlerWithTimeout', 'block: true', 'failed: ${message}') }
        [pscustomobject]@{ Name = 'extension-api'; Path = 'extensibility/extensions/types.ts'; Start = 1132; End = 1153; Sha256 = 'da08b759af2230fec7609f9b6032a1173335112516bdd385093b58408ea3d9d5'; Needles = @('export interface ExtensionAPI', 'logger:', 'pi: typeof PiCodingAgent') }
        [pscustomobject]@{ Name = 'extension-register-tool'; Path = 'extensibility/extensions/types.ts'; Start = 1205; End = 1233; Sha256 = '977e390d6b53db72aa9dceaaec4d5d9f22561756f885bd0a48c3b3b097d55691'; Needles = @('on(event: "tool_call"', 'Tool Registration', 'registerTool<', 'registerCommand') }
    )
}

function Test-Topic08SourceAttachments {
    param([Parameter(Mandatory)][string]$RepositoryRoot)
    $upstream = Join-Path ([IO.Path]::GetFullPath($RepositoryRoot)) '_research\upstreams\oh-my-pi'
    try {
        if (-not (Test-Path -LiteralPath (Join-Path $upstream '.git') -PathType Container)) {
            throw 'The pinned OMP checkout is missing.'
        }
        $head = (@(& git -C $upstream rev-parse HEAD 2>&1) -join '').Trim()
        if ($LASTEXITCODE -ne 0 -or $head -cne $script:Topic08PinnedOmpSha) {
            throw "Pinned OMP HEAD mismatch: expected $script:Topic08PinnedOmpSha, got $head."
        }
        $status = @(& git -C $upstream status --porcelain --untracked-files=no 2>&1)
        if ($LASTEXITCODE -ne 0 -or @($status | Where-Object { [string]$_ }).Count -ne 0) {
            throw 'The pinned OMP checkout is not clean.'
        }
        foreach ($attachment in Get-Topic08SourceAttachmentManifest) {
            $path = Join-Path $upstream ('packages\coding-agent\src\' + ([string]$attachment.Path -replace '/', '\'))
            $lines = [IO.File]::ReadAllLines($path)
            $text = (($lines[([int]$attachment.Start - 1)..([int]$attachment.End - 1)] -join "`n") + "`n")
            if ((Get-Topic08NormalizedRangeHash -LiteralPath $path -StartLine $attachment.Start `
                    -EndLine $attachment.End) -cne [string]$attachment.Sha256) {
                throw "Bounded source hash mismatch for $($attachment.Name)."
            }
            if (-not (Test-Topic08OrderedNeedles -Text $text -Needles @($attachment.Needles))) {
                throw "Structural source order mismatch for $($attachment.Name)."
            }
        }
        return [pscustomobject]@{ Status = 'PASS'; Code = 'T08-SOURCE-ATTACHED'; OmpSha = $head; Message = 'Pinned OMP source attachments match.' }
    } catch {
        return [pscustomobject]@{ Status = 'FAIL'; Code = 'T08-SOURCE-ATTACHED'; OmpSha = $null; Message = $_.Exception.Message }
    }
}

function Invoke-Topic08ManifestSemanticValidation {
    param([Parameter(Mandatory)][string]$Root)
    $core = Join-Path $Root 'template\.omp\contracts\behavior-core.mjs'
    $manifest = Join-Path $Root 'template\.omp\contracts\behavior-manifest.json'
    if (-not (Test-Path -LiteralPath $core -PathType Leaf) -or
        -not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        return [pscustomobject]@{ Ok = $false; ReasonCode = 'BHV-MANIFEST-INVALID'; Message = 'Core or manifest is missing.' }
    }
    $program = @'
import fs from "node:fs";
import { pathToFileURL } from "node:url";
const [corePath, manifestPath] = process.argv.slice(1);
try {
  const core = await import(pathToFileURL(corePath).href + `?topic08=${Date.now()}`);
  const value = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  const result = core.validateBehaviorManifest(value);
  process.stdout.write(JSON.stringify({ ok: result.ok === true, reason_code: result.reason_code ?? null, message: result.message ?? null }));
} catch (error) {
  process.stdout.write(JSON.stringify({ ok: false, reason_code: "BHV-MANIFEST-INVALID", message: String(error?.message ?? error) }));
}
'@
    $output = @(& node --input-type=module -e $program $core $manifest 2>&1)
    if ($LASTEXITCODE -ne 0 -or $output.Count -ne 1) {
        return [pscustomobject]@{ Ok = $false; ReasonCode = 'BHV-MANIFEST-INVALID'; Message = ($output -join ' ') }
    }
    try {
        $result = ([string]$output[0]) | ConvertFrom-Json -AsHashtable
        return [pscustomobject]@{ Ok = [bool]$result.ok; ReasonCode = [string]$result.reason_code; Message = [string]$result.message }
    } catch {
        return [pscustomobject]@{ Ok = $false; ReasonCode = 'BHV-MANIFEST-INVALID'; Message = 'Semantic validator returned invalid JSON.' }
    }
}

function Get-Topic08AgentAutoload {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return [pscustomobject]@{ Valid = $false; Values = @() } }
    $matches = [regex]::Matches($Text, '(?m)^autoloadSkills:\s*(.+)\s*$')
    if ($matches.Count -eq 0) { return [pscustomobject]@{ Valid = $true; Values = @() } }
    if ($matches.Count -ne 1) { return [pscustomobject]@{ Valid = $false; Values = @() } }
    try {
        $values = @(([string]$matches[0].Groups[1].Value | ConvertFrom-Json))
        return [pscustomobject]@{ Valid = $true; Values = @($values | ForEach-Object { [string]$_ }) }
    } catch { return [pscustomobject]@{ Valid = $false; Values = @() } }
}

function Test-Topic08SkillBudgets {
    param([Parameter(Mandatory)][string]$Root, [Collections.IDictionary]$Manifest)
    if ($null -eq $Manifest -or $Manifest.skills -isnot [Collections.IEnumerable]) { return $false }
    foreach ($skill in @($Manifest.skills)) {
        if ([string]$skill.status -cne 'active') { continue }
        $relative = 'template/' + [string]$skill.path
        $text = Get-Topic08BehaviorCoreText -Root $Root -RelativePath $relative
        if ($null -eq $text) { return $false }
        $parts = [regex]::Split($text, '(?m)^---\s*$')
        if ($parts.Count -lt 3) { return $false }
        $frontmatter = [string]$parts[1]
        $descriptionMatch = [regex]::Match($frontmatter, '(?ms)^description:\s*>\s*\r?\n(?<value>(?:\s{2}.+\r?\n?)+)')
        if (-not $descriptionMatch.Success) { return $false }
        $description = ([regex]::Replace($descriptionMatch.Groups['value'].Value, '(?m)^\s{2}', '') -replace '\s+', ' ').Trim()
        $body = ($parts[2..($parts.Count - 1)] -join '---').Trim()
        if ([Math]::Ceiling($description.Length / 4.0) -gt [int]$skill.description_max_tokens -or
            [Math]::Ceiling($body.Length / 4.0) -gt [int]$skill.body_max_tokens) { return $false }
    }
    return $true
}

function Test-Topic08TriggerFixtures {
    param([Parameter(Mandatory)][string]$Root, [Collections.IDictionary]$Manifest)
    if ($null -eq $Manifest) { return $false }
    $expected = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($skill in @($Manifest.skills)) {
        if ([string]$skill.status -cne 'active') { continue }
        foreach ($field in @('positive_trigger_fixture', 'negative_trigger_fixture')) {
            $relative = [string]$skill[$field]
            if (-not $expected.Add($relative)) { return $false }
            $text = Get-Topic08BehaviorCoreText -Root $Root -RelativePath $relative
            $expectation = if ($field -ceq 'positive_trigger_fixture') { 'should_trigger' } else { 'should_not_trigger' }
            if (-not (Test-Topic08ContainsAll -Text $text -Needles @(
                'schema_version: 1',
                'record_type: topic08_skill_trigger_fixture',
                "skill: $([string]$skill.name)",
                "expectation: $expectation",
                'cases:'
            ))) { return $false }
            $cases = @([regex]::Matches($text, '(?m)^\s{2}-\s+"(?<case>.+)"\s*$') |
                ForEach-Object { $_.Groups['case'].Value })
            if ($cases.Count -lt 2 -or @($cases | Sort-Object -Unique).Count -ne $cases.Count) { return $false }
        }
    }
    $directory = Join-Path $Root 'evals\triggers\topic08'
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) { return $false }
    $actual = @(Get-ChildItem -LiteralPath $directory -File -Filter '*.yml' |
        ForEach-Object { 'evals/triggers/topic08/' + $_.Name })
    return $actual.Count -eq $expected.Count -and @($actual | Where-Object { -not $expected.Contains($_) }).Count -eq 0
}

function Test-Topic08ComponentManifest {
    param([Parameter(Mandatory)][string]$Root, [Collections.IDictionary]$Component)
    if (-not (Test-Topic08ClosedMap -Value $Component -Names @(
        'schema_version', 'record_type', 'component', 'component_version', 'minimum_pwsh_version',
        'supported_omp_versions', 'role_policy', 'continuity_policy', 'dependencies', 'files',
        'generated_target_files'
    )) -or [int]$Component.schema_version -ne 2 -or
        [string]$Component.record_type -cne 'agent_boundary_component_manifest' -or
        [string]$Component.component_version -cne '2.1.0') { return $false }
    $dependencies = @($Component.dependencies)
    if ($dependencies.Count -ne 4 -or
        (@($dependencies | ForEach-Object { [string]$_.component }) -join '|') -cne 'agents|skills|state|config') {
        return $false
    }
    $skillDependency = @($dependencies | Where-Object { [string]$_.component -ceq 'skills' })
    $expectedSkillDependency = @(
        '.omp/skills/task-triage/SKILL.md',
        '.omp/skills/systematic-debugging/SKILL.md',
        '.omp/skills/evidence-before-completion/SKILL.md'
    ) -join '|'
    if ($skillDependency.Count -ne 1 -or
        (@($skillDependency[0].paths) -join '|') -cne $expectedSkillDependency) { return $false }
    $rows = @($Component.files)
    if ($rows.Count -ne 20 -or @($rows | Where-Object { $_.owned -eq $true }).Count -ne 13) { return $false }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($row in $rows) {
        $relative = [string]$row.path
        if (-not $seen.Add($relative) -or [string]$row.sha256 -cnotmatch '^[a-f0-9]{64}$') { return $false }
        $source = Join-Path $Root ('template\' + ($relative -replace '/', '\'))
        if ((Get-Topic08Sha256 -LiteralPath $source) -cne [string]$row.sha256) { return $false }
    }
    return $true
}

function Test-Topic08EvidenceBundle {
    param([Parameter(Mandatory)][string]$Root, [Collections.IDictionary]$BehaviorManifest)
    $directory = Join-Path $Root 'docs\evidence\current-product\topic-08'
    $deterministicPath = Join-Path $directory 'deterministic.json'
    $manifestPath = Join-Path $directory 'manifest.json'
    $snapshotPath = Join-Path $directory 'behavior-manifest.json'
    if (-not (Test-Path -LiteralPath $deterministicPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $manifestPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $snapshotPath -PathType Leaf)) { return $false }
    $evidence = Get-Topic08BehaviorCoreJson -Root $Root -RelativePath 'docs/evidence/current-product/topic-08/manifest.json'
    $deterministic = Get-Topic08BehaviorCoreJson -Root $Root -RelativePath 'docs/evidence/current-product/topic-08/deterministic.json'
    if (-not (Test-Topic08ClosedMap -Value $evidence -Names @(
        'schema_version', 'record_type', 'component', 'component_version', 'generated_at_utc', 'files'
    )) -or [int]$evidence.schema_version -ne 1 -or
        [string]$evidence.record_type -cne 'topic08_evidence_manifest' -or
        [string]$evidence.component -cne 'behavior-core' -or
        [string]$evidence.component_version -cne [string]$BehaviorManifest.component_version) { return $false }
    $rows = @($evidence.files)
    if ($rows.Count -ne 2 -or (@($rows | ForEach-Object { [string]$_.path }) -join '|') -cne
        'behavior-manifest.json|deterministic.json') { return $false }
    foreach ($row in $rows) {
        $path = Join-Path $directory ([string]$row.path)
        if ([string]$row.sha256 -cnotmatch '^[a-f0-9]{64}$' -or
            (Get-Topic08Sha256 -LiteralPath $path) -cne [string]$row.sha256) { return $false }
    }
    $currentManifest = Join-Path $Root 'template\.omp\contracts\behavior-manifest.json'
    if (-not [Linq.Enumerable]::SequenceEqual(
            [byte[]][IO.File]::ReadAllBytes($currentManifest),
            [byte[]][IO.File]::ReadAllBytes($snapshotPath)
        )) { return $false }
    return $null -ne $deterministic -and
        [string]$deterministic.record_type -ceq 'topic08_deterministic_evidence' -and
        [string]$deterministic.status -ceq 'IMPLEMENTED_NOT_PROMOTED' -and
        [string]$deterministic.omp_source_sha -ceq $script:Topic08PinnedOmpSha
}

function Test-Topic08BehaviorCore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [switch]$SkipEvidence,
        [switch]$SkipRuntime,
        [switch]$SkipDocumentation
    )
    $root = [IO.Path]::GetFullPath($RepositoryRoot)
    $results = [Collections.Generic.List[object]]::new()
    $manifest = Get-Topic08BehaviorCoreJson -Root $root -RelativePath 'template/.omp/contracts/behavior-manifest.json'
    $component = Get-Topic08BehaviorCoreJson -Root $root -RelativePath 'template/.omp/contracts/component-manifest.json'
    $semantic = Invoke-Topic08ManifestSemanticValidation -Root $root

    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $semantic.Ok `
        -Code 'T08-MANIFEST' -PassMessage 'The behavior manifest passes the JavaScript semantic core.' `
        -FailMessage "Behavior manifest rejected: $($semantic.ReasonCode) $($semantic.Message)"))

    $injectionValid = $semantic.Ok -and $null -ne $manifest -and
        (@($manifest.constitution.intentional_duplications) -join '|') -ceq 'evidence-before-completion'
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $injectionValid `
        -Code 'T08-INJECTION-OWNERSHIP' -PassMessage 'Behavior injection ownership is closed with one declared duplication.' `
        -FailMessage 'Behavior injection ownership is duplicated, missing, or undeclared.'))

    $budgetValid = $semantic.Ok -and (Test-Topic08SkillBudgets -Root $root -Manifest $manifest)
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $budgetValid `
        -Code 'T08-BUDGET' -PassMessage 'Manifest and selected skill token budgets are within approved limits.' `
        -FailMessage 'A behavior budget or selected skill body exceeds the approved limit.'))

    $selectedNames = @('task-triage', 'systematic-debugging', 'evidence-before-completion')
    $rosterValid = $null -ne $manifest -and
        (@($manifest.skills | Where-Object { [string]$_.status -ceq 'active' } |
            ForEach-Object { [string]$_.name }) -join '|') -ceq ($selectedNames -join '|')
    if ($rosterValid) {
        foreach ($skill in @($manifest.skills)) {
            $path = Join-Path $root ('template\' + ([string]$skill.path -replace '/', '\'))
            if ((Get-Topic08Sha256 -LiteralPath $path) -cne [string]$skill.sha256) { $rosterValid = $false; break }
        }
    }
    $coreText = Get-Topic08BehaviorCoreText -Root $root -RelativePath 'template/.omp/contracts/behavior-core.mjs'
    $lockText = Get-Topic08BehaviorCoreText -Root $root -RelativePath 'registry/skill-lock.yml'
    $rosterValid = $rosterValid -and (Test-Topic08ContainsAll -Text $coreText -Needles @(
        'if (matches.length !== 1)',
        'normalizedPath(matches[0].filePath) !== normalizedPath(expected)',
        'BHV-SKILL-SHADOWED'
    )) -and (Test-Topic08ContainsAll -Text $lockText -Needles $selectedNames)
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $rosterValid `
        -Code 'T08-ROSTER' -PassMessage 'The selected skill roster, paths, hashes, and shadow defense are exact.' `
        -FailMessage 'The selected skill roster is missing, shadowable, duplicated, or hash-drifted.'))

    $workerAutoload = Get-Topic08AgentAutoload (Get-Topic08BehaviorCoreText -Root $root -RelativePath 'template/.omp/agents/worker.md')
    $scoutAutoload = Get-Topic08AgentAutoload (Get-Topic08BehaviorCoreText -Root $root -RelativePath 'template/.omp/agents/cheap-scout.md')
    $reviewerAutoload = Get-Topic08AgentAutoload (Get-Topic08BehaviorCoreText -Root $root -RelativePath 'template/.omp/agents/reviewer.md')
    $autoloadValid = $workerAutoload.Valid -and $scoutAutoload.Valid -and $reviewerAutoload.Valid -and
        (@($workerAutoload.Values) -join '|') -ceq 'evidence-before-completion' -and
        @($scoutAutoload.Values).Count -eq 0 -and @($reviewerAutoload.Values).Count -eq 0 -and
        $null -ne $manifest -and
        (@($manifest.roles.worker.required_autoload) -join '|') -ceq 'evidence-before-completion' -and
        @($manifest.roles.'cheap-scout'.required_autoload).Count -eq 0 -and
        @($manifest.roles.reviewer.required_autoload).Count -eq 0
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $autoloadValid `
        -Code 'T08-AUTOLOAD' -PassMessage 'Worker is the sole autoload consumer.' `
        -FailMessage 'The exact Worker-only autoload binding drifted.'))

    $triggerValid = Test-Topic08TriggerFixtures -Root $root -Manifest $manifest
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $triggerValid `
        -Code 'T08-TRIGGERS' -PassMessage 'All six deterministic trigger fixtures are unique and bound to the roster.' `
        -FailMessage 'A trigger fixture is missing, duplicated, malformed, or unbound.'))

    $provenanceValid = $null -ne $manifest -and
        (@($manifest.provenance | ForEach-Object { [string]$_.id }) -join '|') -ceq
            'prov-task-triage|prov-systematic-debugging|prov-evidence-before-completion' -and
        @($manifest.provenance | Where-Object { [string]$_.commit -cnotmatch '^[a-f0-9]{40}$' }).Count -eq 0
    foreach ($relative in @('registry/upstreams.yml', 'registry/licenses.yml', 'registry/adoption-ledger.yml')) {
        $provenanceValid = $provenanceValid -and (Test-Topic08ContainsAll `
            -Text (Get-Topic08BehaviorCoreText -Root $root -RelativePath $relative) `
            -Needles @('superpowers', 'spec-kit'))
    }
    if (-not $SkipEvidence) { $provenanceValid = $provenanceValid -and (Test-Topic08EvidenceBundle -Root $root -BehaviorManifest $manifest) }
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $provenanceValid `
        -Code 'T08-PROVENANCE' -PassMessage 'Selected behavior provenance and local evidence are traceable.' `
        -FailMessage 'Behavior provenance, release hashes, or the local evidence bundle is incomplete.'))

    $schemaText = Get-Topic08BehaviorCoreText -Root $root -RelativePath 'template/.omp/contracts/behavior-core-schema.mjs'
    $extensionText = Get-Topic08BehaviorCoreText -Root $root -RelativePath 'template/.omp/extensions/agent-task-boundary.js'
    $lifecycleMatch = if ($null -ne $schemaText) {
        [regex]::Match($schemaText, '(?s)LIFECYCLE_OPERATIONS\s*=.*?\[(?<body>.*?)\]\)')
    } else { $null }
    $lifecycleValues = if ($null -ne $lifecycleMatch -and $lifecycleMatch.Success) {
        @([regex]::Matches($lifecycleMatch.Groups['body'].Value, '"(?<value>[a-z-]+)"') |
            ForEach-Object { $_.Groups['value'].Value })
    } else { @() }
    $expectedLifecycle = @(
        'init-project', 'status', 'create-phase', 'transition-phase', 'create-task',
        'set-continuity-contract', 'bind-worktree', 'checkpoint', 'claim', 'create-work-unit',
        'freeze', 'check', 'promote-artifact', 'record-evidence', 'begin-handoff',
        'accept-handoff', 'close', 'invalidate'
    )
    $lifecycleValid = ($lifecycleValues -join '|') -ceq ($expectedLifecycle -join '|') -and
        -not ($lifecycleValues -ccontains 'purge') -and
        (Test-Topic08ContainsAll -Text $extensionText -Needles @(
            'name: "agent_tasks"',
            '!isMainSession(ctx)',
            '!LIFECYCLE_OPERATIONS.has(params.operation)',
            'BHV-LIFECYCLE-FORBIDDEN'
        ))
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $lifecycleValid `
        -Code 'T08-LIFECYCLE' -PassMessage 'agent_tasks is main-session only with the exact routine lifecycle allowlist.' `
        -FailMessage 'The lifecycle allowlist or main-session bootstrap boundary drifted.'))

    $pressure = Get-Topic08BehaviorCoreJson -Root $root -RelativePath 'evals/pressure/topic08/behavior-gates.json'
    $mutationGateValid = $null -ne $pressure -and @($pressure.cases).Count -eq 13 -and
        @($pressure.cases | Where-Object { [string]$_.id -ceq 'read-only-diagnosis' -and [string]$_.expected -ceq 'allow' }).Count -eq 1 -and
        @($pressure.cases | Where-Object { [string]$_.id -ceq 'missing-state-mutation' -and [string]$_.expected -ceq 'BHV-STATE-MISSING' }).Count -eq 1 -and
        (Test-Topic08ContainsAll -Text $extensionText -Needles @(
            'DIAGNOSTIC_TOOLS.has(toolName)',
            'MUTATION_CAPABLE_TOOLS.has(toolName)',
            'BHV-STATE-MISSING',
            'BHV-STATE-AMBIGUOUS',
            'pi.on("tool_call"'
        ))
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $mutationGateValid `
        -Code 'T08-MUTATION-GATE' -PassMessage 'Diagnostic tools remain available while edit/write/bash fail closed on state.' `
        -FailMessage 'The deterministic mutation bootstrap or state gate drifted.'))

    $observationValid = Test-Topic08ContainsAll -Text $extensionText -Needles @(
        'observation failed',
        'catch { /* best effort */ }',
        'return decision;'
    )
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $observationValid `
        -Code 'T08-OBSERVATION' -PassMessage 'Observation failures preserve deterministic behavior decisions.' `
        -FailMessage 'Observation or logging can alter a deterministic decision.'))

    $externalValid = $null -ne $manifest -and
        $manifest.tools.external_capabilities.policy_authority -eq $false -and
        $manifest.tools.external_capabilities.workflow_selection -eq $false
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $externalValid `
        -Code 'T08-EXTERNAL-CAPABILITY' -PassMessage 'External tools provide capability without policy or workflow authority.' `
        -FailMessage 'An external capability was granted policy or workflow authority.'))

    $ompValid = $null -ne $manifest -and [string]$manifest.adapters.omp.status -ceq 'IMPLEMENTED_NOT_PROMOTED' -and
        $manifest.adapters.omp.installable -eq $true -and
        (Test-Topic08ContainsAll -Text $extensionText -Needles @(
            'loadBehaviorManifest', 'discoverAgents', 'discoverSkills', 'reconcileEffectiveBehavior',
            'pi.registerTool(createAgentTasksTool', 'pi.on("tool_call"'
        ))
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $ompValid `
        -Code 'T08-OMP-ADAPTER' -PassMessage 'The OMP behavior adapter is implemented but not promoted.' `
        -FailMessage 'The OMP adapter status or effective-catalog reconciliation is incomplete.'))

    $claudeValid = $null -ne $manifest -and [string]$manifest.adapters.claude.status -ceq 'DESIGNED_NOT_VERIFIED' -and
        $manifest.adapters.claude.installable -eq $false
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $claudeValid `
        -Code 'T08-CLAUDE-FENCE' -PassMessage 'Claude remains a complete non-installable design mapping.' `
        -FailMessage 'Claude runtime support was falsely enabled or promoted.'))

    $componentValid = Test-Topic08ComponentManifest -Root $root -Component $component
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $componentValid `
        -Code 'T08-COMPONENT' -PassMessage 'The 2.1 component owns 13 of 20 exact hashed files and declares all dependencies.' `
        -FailMessage 'The component identity, dependency set, ownership count, or file hash drifted.'))

    $installerText = Get-Topic08BehaviorCoreText -Root $root -RelativePath 'scripts/install-template.ps1'
    $uninstallerText = Get-Topic08BehaviorCoreText -Root $root -RelativePath 'scripts/uninstall-template.ps1'
    $installerValid = (Test-Topic08ContainsAll -Text $installerText -Needles @(
        'scripts\update-skill-lock.ps1',
        '-RepositoryRoot $root -Check',
        "'.omp/skills/task-triage/SKILL.md'",
        "'.omp/skills/systematic-debugging/SKILL.md'",
        "'.omp/skills/evidence-before-completion/SKILL.md'"
    )) -and (Test-Topic08ContainsAll -Text $uninstallerText -Needles @(
        "'.omp/contracts/behavior-core-schema.mjs'",
        "'.omp/contracts/behavior-core.mjs'",
        "'.omp/contracts/behavior-manifest.json'",
        'Operational agent-tasks state retained.'
    ))
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $installerValid `
        -Code 'T08-INSTALLER' -PassMessage 'Install/update/rollback preflight selected skills and retain operational state.' `
        -FailMessage 'Installer dependency preflight, owned behavior files, or retained-state rollback drifted.'))

    $documentationValid = $true
    if (-not $SkipDocumentation) {
        $projectionFiles = @(
            'docs/behavior-core.md', 'README.md', 'docs/architecture.md', 'docs/customization.md',
            'docs/installation.md', 'docs/rollback.md', 'docs/workflow-v0.md', 'docs/final-report.md',
            'spec/11-skills-rules-and-quality-gates.md', 'spec/12-installation-and-rollback.md',
            'spec/13-validation-and-evaluation.md', 'spec/README.md', 'spec/key/01-dna.md',
            'spec/key/03-token-quality-model.md', 'spec/phases/phase-02-core-orchestration.md',
            'spec/phases/phase-06-evaluation.md', 'template/.omp/schemas/verification-result.schema.yml',
            'codex-topic08-portable-behavior-core-runtime-adapters-changelog.md'
        )
        foreach ($relative in $projectionFiles) {
            if (-not (Test-Topic08ContainsAll -Text (Get-Topic08BehaviorCoreText -Root $root -RelativePath $relative) `
                    -Needles @('<!-- topic08-projection:behavior-core -->'))) {
                $documentationValid = $false
                break
            }
        }
        $guideText = Get-Topic08BehaviorCoreText -Root $root -RelativePath 'docs/behavior-core.md'
        $phase02Text = Get-Topic08BehaviorCoreText -Root $root -RelativePath 'spec/phases/phase-02-core-orchestration.md'
        $documentationValid = $documentationValid -and (Test-Topic08ContainsAll -Text $guideText -Needles @(
            'selected roster: task-triage, systematic-debugging, evidence-before-completion',
            'Worker-only autoload',
            'missing autoload names fail before managed dispatch',
            'agent_tasks is explicit and main-session only',
            'Claude: DESIGNED_NOT_VERIFIED / installable false',
            'trigger semantics remain unpromoted until Topic 11',
            'agent-tasks operational state is retained on uninstall/rollback'
        )) -and (Test-Topic08ContainsAll -Text $phase02Text -Needles @(
            '<!-- topic08-supersession:fixed-role-autoload -->'
        ))
    }
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $documentationValid `
        -Code 'T08-DOC-PROJECTION' -PassMessage 'Active documentation projects the selected behavior contract and historical fence.' `
        -FailMessage 'A current-product behavior projection or Phase 02 supersession fence is missing.'))

    $helperText = Get-Topic08BehaviorCoreText -Root $root -RelativePath 'scripts/lib/topic08-behavior-core.ps1'
    $sourcePolicyValid = Test-Topic08ContainsAll -Text $helperText -Needles @(
        "`$script:Topic08PinnedOmpSha = '$script:Topic08PinnedOmpSha'"
    )
    foreach ($attachment in Get-Topic08SourceAttachmentManifest) {
        $sourcePolicyValid = $sourcePolicyValid -and (Test-Topic08ContainsAll -Text $helperText -Needles @(
            "Name = '$($attachment.Name)'",
            "Path = '$($attachment.Path)'",
            "Start = $($attachment.Start)",
            "End = $($attachment.End)",
            "Sha256 = '$($attachment.Sha256)'"
        ))
    }
    $sourceMessage = 'Pinned OMP source policy and all 11 attachments are exact.'
    if (-not $SkipRuntime -and $sourcePolicyValid) {
        $source = Test-Topic08SourceAttachments -RepositoryRoot $root
        $sourcePolicyValid = $source.Status -ceq 'PASS'
        if (-not $sourcePolicyValid) { $sourceMessage = [string]$source.Message }
    }
    [void]$results.Add((New-Topic08BehaviorCoreBooleanResult -Condition $sourcePolicyValid `
        -Code 'T08-SOURCE-ATTACHED' -PassMessage $sourceMessage `
        -FailMessage "Pinned OMP source validation failed: $sourceMessage"))

    return @($results)
}
