#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script:assertions = 0

function Read-Topic05RoutingFile {
    param([Parameter(Mandatory)][string]$RelativePath)

    $path = Join-Path $repositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "missing Topic 05 routing file: $RelativePath"
    }
    return Get-Content -Raw -LiteralPath $path -Encoding UTF8
}

function Get-Topic05Frontmatter {
    param([Parameter(Mandatory)][string]$Content)

    $match = [regex]::Match($Content, '\A---\r?\n(?<yaml>.*?)\r?\n---\r?\n', 'Singleline')
    if (-not $match.Success) { throw 'agent frontmatter is missing or malformed' }
    return $match.Groups['yaml'].Value
}

function Get-Topic05Scalar {
    param(
        [Parameter(Mandatory)][string]$Frontmatter,
        [Parameter(Mandatory)][string]$Name
    )

    $match = [regex]::Match($Frontmatter, "(?m)^$([regex]::Escape($Name)):\s*(.*?)\s*$")
    if (-not $match.Success) { return $null }
    return $match.Groups[1].Value.Trim().Trim('"').Trim("'")
}

function Assert-Topic05 {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Message
    )

    $script:assertions++
    if (-not $Condition) { throw "FAIL [$Code] $Message" }
}

function Assert-Topic05Contains {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$Code
    )

    Assert-Topic05 -Condition ([regex]::IsMatch($Content, $Pattern, 'IgnoreCase, Singleline')) `
        -Code $Code -Message "required semantic rule is missing: $Pattern"
}

$scout = Read-Topic05RoutingFile 'template/.omp/agents/cheap-scout.md'
$reviewer = Read-Topic05RoutingFile 'template/.omp/agents/reviewer.md'
$agents = Read-Topic05RoutingFile 'template/.omp/AGENTS.md'
$quick = Read-Topic05RoutingFile 'template/.omp/commands/quick.md'
$standard = Read-Topic05RoutingFile 'template/.omp/commands/standard.md'
$orchestrated = Read-Topic05RoutingFile 'template/.omp/commands/orchestrated.md'
$config = Read-Topic05RoutingFile 'template/.omp/config.yml'

$scoutFrontmatter = Get-Topic05Frontmatter $scout
$reviewerFrontmatter = Get-Topic05Frontmatter $reviewer
$scoutTools = @((Get-Topic05Scalar -Frontmatter $scoutFrontmatter -Name 'tools') -split '\s*,\s*')
Assert-Topic05 -Condition (($scoutTools -join ',') -ceq 'read,grep,glob,web_search') `
    -Code 'T05-SCOUT-TOOLS' -Message 'Cheap Scout tools must be exactly read, grep, glob, web_search'
Assert-Topic05 -Condition ((Get-Topic05Scalar $scoutFrontmatter 'model') -ceq '@cheap-scout') `
    -Code 'T05-SCOUT-MODEL' -Message 'Cheap Scout must use @cheap-scout'
Assert-Topic05 -Condition ((Get-Topic05Scalar $scoutFrontmatter 'thinking-level') -ceq 'xhigh') `
    -Code 'T05-SCOUT-EFFORT' -Message 'Cheap Scout must run at xhigh/DeepSeek max'
Assert-Topic05 -Condition ((Get-Topic05Scalar $scoutFrontmatter 'spawns') -ceq '') `
    -Code 'T05-SCOUT-SPAWNS' -Message 'Cheap Scout must not spawn agents'
Assert-Topic05 -Condition ($config -cmatch '(?m)^  cheap-scout: omniroute/ds/deepseek-v4-flash:xhigh\s*$' -and
        $config -cmatch '(?ms)^    cheap-scout:\s*\r?\n      - omniroute/ds/deepseek-v4-pro:xhigh\s*$') `
    -Code 'T05-SCOUT-CHAIN' -Message 'Cheap Scout must be Flash max with only Pro max fallback'
$fallbackBlock = [regex]::Match($config, '(?ms)^    cheap-scout:\s*\r?\n(?<items>(?:      - [^\r\n]+\r?\n?)+)')
$fallbackItems = @(
    if ($fallbackBlock.Success) {
        [regex]::Matches($fallbackBlock.Groups['items'].Value, '(?m)^      - (?<value>[^\r\n]+)$') |
            ForEach-Object { $_.Groups['value'].Value.Trim() }
    }
)
Assert-Topic05 -Condition ($fallbackItems.Count -eq 1 -and
        $fallbackItems[0] -ceq 'omniroute/ds/deepseek-v4-pro:xhigh') `
    -Code 'T05-SCOUT-CHAIN-CLOSED' -Message 'Cheap Scout fallback chain must contain only Pro xhigh'
Assert-Topic05 -Condition ((Get-Topic05Scalar $reviewerFrontmatter 'thinking-level') -ceq 'xhigh') `
    -Code 'T05-REVIEWER-EFFORT' -Message 'Reviewer must remain xhigh'

foreach ($field in @('status', 'summary', 'capability', 'source_fitness_reason', 'fallback_path',
        'claims', 'gaps', 'searches_performed', 'recommended_next_action')) {
    Assert-Topic05 -Condition ($scoutFrontmatter -cmatch "(?m)^    $field`:\s*") `
        -Code "T05-RESULT-$($field.ToUpperInvariant())" -Message "closed Scout semantic result lacks $field"
}
foreach ($field in @('claim', 'sources', 'path', 'line_start', 'line_end', 'method', 'query', 'outcome')) {
    Assert-Topic05 -Condition ($scoutFrontmatter -cmatch "(?m)^\s+$field`:\s*") `
        -Code "T05-RESULT-$($field.ToUpperInvariant())" -Message "nested Scout semantic result lacks $field"
}
Assert-Topic05 -Condition ([regex]::Matches($scoutFrontmatter, '(?m)^\s+additionalProperties:\s*false\s*$').Count -eq 4) `
    -Code 'T05-RESULT-CLOSED-OBJECTS' -Message 'root, claim, source, and search objects must all be closed'
Assert-Topic05 -Condition ($scoutFrontmatter -cmatch '(?m)^  type:\s*object\s*$' -and
        $scoutFrontmatter -cmatch '(?m)^  required:\s*$') `
    -Code 'T05-RESULT-JSON-SCHEMA' -Message 'Scout semantic output must be a required closed JSON Schema object'
Assert-Topic05Contains $scoutFrontmatter 'capability:\s*\r?\n\s+enum:\s*\[native, codegraph, mixed\]' 'T05-RESULT-CAPABILITY-CLOSED'
Assert-Topic05Contains $scoutFrontmatter 'method:\s*\r?\n\s+enum:\s*\[read, grep, glob, web_search, codegraph\]' 'T05-RESULT-SEARCH-METHOD-CLOSED'
foreach ($runtimeField in @('question', 'actor', 'binding', 'worktree_root', 'task_id', 'candidate_id',
        'candidate_hash', 'codegraph_version', 'index_path', 'index_state')) {
    Assert-Topic05 -Condition ($scoutFrontmatter -cnotmatch "(?m)^\s+$runtimeField`:\s*") `
        -Code "T05-RESULT-NO-$($runtimeField.ToUpperInvariant())" `
        -Message "Scout semantic output must not echo runtime field $runtimeField"
}
Assert-Topic05Contains $scout 'canonical `agent_dispatch` packet.*accepted question|accepted question.*canonical `agent_dispatch` packet' 'T05-SCOUT-QUESTION-IN-INPUT'
Assert-Topic05Contains $scout 'do not echo.*bindings.*hashes.*worktree roots|bindings.*hashes.*worktree roots.*do not echo' 'T05-SCOUT-NO-RUNTIME-ECHO'
Assert-Topic05Contains $scout 'CodeGraph.*optional.*default-off|default-off.*CodeGraph' 'T05-SCOUT-CODEGRAPH-OPTIONAL'
Assert-Topic05Contains $scout 'native retrieval when sufficient|native retrieval.*sufficient' 'T05-SCOUT-NATIVE-FIRST'
Assert-Topic05Contains $scout 'materially improves.*relationship|relationship.*blast-radius' 'T05-SCOUT-FITNESS'
Assert-Topic05Contains $scout 'absent|non-completed' 'T05-SCOUT-FALLBACK-TRIGGER'
Assert-Topic05Contains $scout 'continue natively|native fallback' 'T05-SCOUT-NATIVE-FALLBACK'
Assert-Topic05Contains $scout 'never duplicate.*raw|do not duplicate.*raw' 'T05-SCOUT-NO-RAW-DUPLICATION'
Assert-Topic05Contains $scout 'graph gap.*completeness|completeness.*graph gap' 'T05-SCOUT-GAP'
Assert-Topic05Contains $scout 'partial.*named gaps|named gaps.*partial' 'T05-SCOUT-PARTIAL'
Assert-Topic05Contains $scout 'do not retry another model' 'T05-SCOUT-NO-QUALITY-RETRY'
Assert-Topic05Contains $scout 'never.*accept|cannot.*accept|no.*acceptance' 'T05-SCOUT-NO-ACCEPTANCE'

Assert-Topic05Contains $reviewer 'native, CodeGraph, or mixed|native.*CodeGraph.*mixed' 'T05-REVIEWER-CAPABILITY'
Assert-Topic05Contains $reviewer 'independent' 'T05-REVIEWER-INDEPENDENCE'
Assert-Topic05Contains $reviewer 'critical.*current source|current source.*critical' 'T05-REVIEWER-CORROBORATION'
Assert-Topic05Contains $reviewer 'stale|candidate-mismatched' 'T05-REVIEWER-BINDING'

$persistent = "$agents`n$quick`n$standard`n$orchestrated"
Assert-Topic05Contains $agents 'actor.*capability.*independent|capability.*actor.*independent|actor and retrieval capability independently' 'T05-PERSISTENT-INDEPENDENCE'
Assert-Topic05Contains $agents 'graph.*hypothesis|hypothesis.*graph' 'T05-PERSISTENT-HYPOTHESIS'
Assert-Topic05Contains $agents 'native fallback|fallback.*native' 'T05-PERSISTENT-FALLBACK'
Assert-Topic05Contains $agents 'critical.*corroborat|corroborat.*critical' 'T05-PERSISTENT-CORROBORATION'
Assert-Topic05Contains $agents 'default-off|no default-on indexing|never.*index.*default' 'T05-PERSISTENT-DEFAULT-OFF'
Assert-Topic05Contains $persistent 'ENVIRONMENT_BLOCKED.*Tech Lead|Tech Lead.*ENVIRONMENT_BLOCKED' 'T05-SCOUT-ENVIRONMENT-FALLBACK'

foreach ($entry in @(
        @{ Name = 'quick'; Content = $quick },
        @{ Name = 'standard'; Content = $standard },
        @{ Name = 'orchestrated'; Content = $orchestrated }
    )) {
    Assert-Topic05Contains $entry.Content 'Lead/native|Tech Lead.*native' "T05-$($entry.Name.ToUpperInvariant())-LEAD-NATIVE"
    Assert-Topic05Contains $entry.Content 'Lead/CodeGraph|Tech Lead.*CodeGraph' "T05-$($entry.Name.ToUpperInvariant())-LEAD-GRAPH"
    Assert-Topic05Contains $entry.Content 'Scout/native.*Lead|Scout.*native.*Tech Lead' "T05-$($entry.Name.ToUpperInvariant())-SCOUT-NATIVE"
    Assert-Topic05Contains $entry.Content 'Scout/CodeGraph.*Lead|Scout.*CodeGraph.*Tech Lead' "T05-$($entry.Name.ToUpperInvariant())-SCOUT-GRAPH"
    Assert-Topic05Contains $entry.Content 'workflow depth|depth.*workflow' "T05-$($entry.Name.ToUpperInvariant())-TRUTH-AUTHORITY"
}

# Mutation sentinels: each load-bearing semantic rule is removed independently. The same focused
# matcher used above must no longer recognize the mutated surface.
$mutationCases = @(
    @{ Name = 'scout-fixed-tools'; Content = $scoutFrontmatter; Pattern = '(?m)^tools: read, grep, glob, web_search\s*$' },
    @{ Name = 'scout-flash-primary'; Content = $config; Pattern = '(?m)^  cheap-scout: omniroute/ds/deepseek-v4-flash:xhigh\s*$' },
    @{ Name = 'scout-pro-fallback'; Content = $config; Pattern = '(?m)^      - omniroute/ds/deepseek-v4-pro:xhigh\s*$' },
    @{ Name = 'reviewer-xhigh'; Content = $reviewerFrontmatter; Pattern = '(?m)^thinking-level: xhigh\s*$' },
    @{ Name = 'scout-native-first'; Content = $scout; Pattern = 'Use native retrieval when sufficient' },
    @{ Name = 'scout-source-fitness'; Content = $scout; Pattern = 'materially improves relationship or blast-radius discovery' },
    @{ Name = 'scout-fallback'; Content = $scout; Pattern = 'continue natively' },
    @{ Name = 'scout-no-raw-copy'; Content = $scout; Pattern = 'Never duplicate its raw payload' },
    @{ Name = 'scout-gap'; Content = $scout; Pattern = 'graph gap cannot establish completeness' },
    @{ Name = 'scout-partial'; Content = $scout; Pattern = 'partial` with named gaps' },
    @{ Name = 'reviewer-independence'; Content = $reviewer; Pattern = 'independently from any Scout choice' },
    @{ Name = 'reviewer-current-source'; Content = $reviewer; Pattern = 'corroborated\s+against current source' },
    @{ Name = 'persistent-actor-capability'; Content = $agents; Pattern = 'Choose actor and retrieval capability independently' },
    @{ Name = 'persistent-hypothesis'; Content = $agents; Pattern = 'CodeGraph is optional/default-off and its\s+output is a hypothesis' },
    @{ Name = 'quick-arms'; Content = $quick; Pattern = 'Lead/native, Lead/CodeGraph, Scout/native\s+then Lead, or Scout/CodeGraph then Lead' },
    @{ Name = 'standard-arms'; Content = $standard; Pattern = 'Lead/native, Lead/CodeGraph, Scout/native then Lead, or\s+Scout/CodeGraph then Lead' },
    @{ Name = 'orchestrated-arms'; Content = $orchestrated; Pattern = 'Lead/native, Lead/CodeGraph,\s+Scout/native then Lead, or Scout/CodeGraph then Lead' }
)
foreach ($case in $mutationCases) {
    $regex = [regex]::new([string]$case.Pattern, [Text.RegularExpressions.RegexOptions]'IgnoreCase, Singleline')
    Assert-Topic05 -Condition $regex.IsMatch([string]$case.Content) -Code "T05-MUTATION-$($case.Name)" `
        -Message "mutation precondition did not match $($case.Name)"
    $mutated = $regex.Replace([string]$case.Content, '', 1)
    Assert-Topic05 -Condition (-not $regex.IsMatch($mutated)) -Code "T05-MUTATION-$($case.Name)-CAUGHT" `
        -Message "removing $($case.Name) did not trip its focused guard"
}

Write-Host "PASS Topic 05 routing tests ($script:assertions assertions)" -ForegroundColor Green
exit 0
