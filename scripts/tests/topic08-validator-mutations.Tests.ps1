#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\topic08-behavior-core.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    throw 'Topic 08 validator helper is missing.'
}
. $helperPath

$script:Assertions = 0
$script:FixtureRoots = [Collections.Generic.List[string]]::new()

function Assert-Topic08ValidatorMutation {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function New-Topic08ValidatorFixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('omp-topic08-validator-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $root)
    [void]$script:FixtureRoots.Add([IO.Path]::GetFullPath($root))
    foreach ($relative in Get-Topic08BehaviorCoreGovernedFiles) {
        if ($relative -like 'docs/evidence/current-product/topic-08/*') { continue }
        $source = Join-Path $repositoryRoot ($relative -replace '/', '\')
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "Governed source is missing: $relative"
        }
        $destination = Join-Path $root ($relative -replace '/', '\')
        [void](New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force)
        Copy-Item -LiteralPath $source -Destination $destination
    }
    return $root
}

function Update-Topic08ValidatorFixture {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][scriptblock]$Mutation
    )
    $path = Join-Path $Root ($RelativePath -replace '/', '\')
    $before = Get-Content -Raw -LiteralPath $path -Encoding UTF8
    $after = & $Mutation $before
    if ($after -ceq $before) { throw "Mutation did not change $RelativePath" }
    Set-Content -LiteralPath $path -Value $after -Encoding UTF8 -NoNewline
}

function Get-Topic08MutationFailureCodes {
    param([Parameter(Mandatory)][string]$Root)
    return @(Test-Topic08BehaviorCore -RepositoryRoot $Root -SkipEvidence -SkipRuntime |
        Where-Object Status -eq FAIL | ForEach-Object Code)
}

function Assert-Topic08MutationCaught {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$ExpectedCode,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][scriptblock]$Mutation
    )
    $root = New-Topic08ValidatorFixture
    Update-Topic08ValidatorFixture -Root $root -RelativePath $RelativePath -Mutation $Mutation
    $failCodes = Get-Topic08MutationFailureCodes -Root $root
    Assert-Topic08ValidatorMutation ($failCodes -ccontains $ExpectedCode) `
        "[$Name] expected $ExpectedCode, got: $($failCodes -join ', ')"
}

try {
    $live = @(Test-Topic08BehaviorCore -RepositoryRoot $repositoryRoot -SkipEvidence -SkipRuntime)
    $liveFailures = @($live | Where-Object Status -eq FAIL)
    Assert-Topic08ValidatorMutation ($liveFailures.Count -eq 0) `
        "Live contract failures: $(($liveFailures | ForEach-Object Code) -join ', ')"

    Assert-Topic08MutationCaught 'manifest-extra-key' 'T08-MANIFEST' `
        'template/.omp/contracts/behavior-manifest.json' {
        param($t) $t -replace '^\{', "{`n  `"unexpected`": true,"
    }
    Assert-Topic08MutationCaught 'manifest-zero-hash' 'T08-MANIFEST' `
        'template/.omp/contracts/behavior-manifest.json' {
        param($t) [regex]::Replace($t, '"sha256": "[a-f0-9]{64}"',
            '"sha256": "0000000000000000000000000000000000000000000000000000000000000000"', 1)
    }

    $missingSkillRoot = New-Topic08ValidatorFixture
    Remove-Item -LiteralPath (Join-Path $missingSkillRoot 'template\.omp\skills\task-triage\SKILL.md') -Force
    $missingSkillCodes = Get-Topic08MutationFailureCodes -Root $missingSkillRoot
    Assert-Topic08ValidatorMutation ($missingSkillCodes -ccontains 'T08-ROSTER') `
        'A missing selected skill was not rejected.'

    Assert-Topic08MutationCaught 'user-shadow-path' 'T08-ROSTER' `
        'template/.omp/contracts/behavior-core.mjs' {
        param($t) $t.Replace(
            'normalizedPath(matches[0].filePath) !== normalizedPath(expected)',
            'false'
        )
    }
    Assert-Topic08MutationCaught 'worker-autoload-removed' 'T08-AUTOLOAD' `
        'template/.omp/agents/worker.md' {
        param($t) $t.Replace('autoloadSkills: ["evidence-before-completion"]', 'autoloadSkills: []')
    }
    Assert-Topic08MutationCaught 'worker-autoload-extra' 'T08-AUTOLOAD' `
        'template/.omp/agents/worker.md' {
        param($t) $t.Replace(
            'autoloadSkills: ["evidence-before-completion"]',
            'autoloadSkills: ["evidence-before-completion", "systematic-debugging"]'
        )
    }
    Assert-Topic08MutationCaught 'reviewer-autoload-added' 'T08-AUTOLOAD' `
        'template/.omp/agents/reviewer.md' {
        param($t) $t.Replace('blocking: true', "blocking: true`nautoloadSkills: [`"evidence-before-completion`"]")
    }
    Assert-Topic08MutationCaught 'description-budget' 'T08-BUDGET' `
        'template/.omp/contracts/behavior-manifest.json' {
        param($t) $t.Replace('"description_max_tokens": 80', '"description_max_tokens": 81')
    }
    Assert-Topic08MutationCaught 'autoload-body-budget' 'T08-BUDGET' `
        'template/.omp/contracts/behavior-manifest.json' {
        param($t) $t.Replace('"body_max_tokens": 500', '"body_max_tokens": 501')
    }

    $missingFixtureRoot = New-Topic08ValidatorFixture
    Remove-Item -LiteralPath (Join-Path $missingFixtureRoot `
        'evals\triggers\topic08\systematic-debugging-negative.yml') -Force
    $missingFixtureCodes = Get-Topic08MutationFailureCodes -Root $missingFixtureRoot
    Assert-Topic08ValidatorMutation ($missingFixtureCodes -ccontains 'T08-TRIGGERS') `
        'A missing trigger fixture was not rejected.'

    Assert-Topic08MutationCaught 'duplicate-trigger-case' 'T08-TRIGGERS' `
        'evals/triggers/topic08/task-triage-positive.yml' {
        param($t)
        $line = '  - "Improve the API; the desired behavior and success criteria are not specified."'
        $t.Replace($line, "$line`n$line")
    }
    Assert-Topic08MutationCaught 'claude-installable' 'T08-CLAUDE-FENCE' `
        'template/.omp/contracts/behavior-manifest.json' {
        param($t)
        $t.Replace(
            '"status": "DESIGNED_NOT_VERIFIED",' + "`n" + '      "installable": false',
            '"status": "DESIGNED_NOT_VERIFIED",' + "`n" + '      "installable": true'
        )
    }
    Assert-Topic08MutationCaught 'lifecycle-purge' 'T08-LIFECYCLE' `
        'template/.omp/contracts/behavior-core-schema.mjs' {
        param($t) $t.Replace('  "invalidate",', "  `"invalidate`",`n  `"purge`",")
    }
    Assert-Topic08MutationCaught 'component-hash-drift' 'T08-COMPONENT' `
        'template/.omp/contracts/component-manifest.json' {
        param($t) [regex]::Replace($t, '"sha256": "[a-f0-9]{64}"',
            '"sha256": "0000000000000000000000000000000000000000000000000000000000000000"', 1)
    }
    Assert-Topic08MutationCaught 'installer-skill-dependency' 'T08-INSTALLER' `
        'scripts/install-template.ps1' {
        param($t) $t.Replace(
            "'.omp/skills/task-triage/SKILL.md'",
            "'.omp/skills/task-triage-disabled/SKILL.md'"
        )
    }
    Assert-Topic08MutationCaught 'source-sentinel' 'T08-SOURCE-ATTACHED' `
        'scripts/lib/topic08-behavior-core.ps1' {
        param($t) $t.Replace(
            '6d2d6e57d647b9ce2a57efe190e037132463d5d191b4c0f6a5f2f618116e9a19',
            '0000000000000000000000000000000000000000000000000000000000000000'
        )
    }
    Assert-Topic08MutationCaught 'documentation-projection' 'T08-DOC-PROJECTION' `
        'docs/behavior-core.md' {
        param($t) $t.Replace(
            '<!-- topic08-projection:behavior-core -->',
            '<!-- topic08-projection:missing -->'
        )
    }

    Write-Host "PASS: Topic 08 validator mutations ($script:Assertions assertions)." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    foreach ($root in $script:FixtureRoots) {
        $resolved = [IO.Path]::GetFullPath($root)
        $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
        if (-not $resolved.StartsWith($temp + [IO.Path]::DirectorySeparatorChar,
                [StringComparison]::OrdinalIgnoreCase) -or
            [IO.Path]::GetFileName($resolved) -notlike 'omp-topic08-validator-*') {
            throw "Refusing unsafe Topic 08 validator cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) {
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }
}
