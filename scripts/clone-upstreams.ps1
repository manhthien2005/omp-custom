# Clone Upstreams — fetch all research repositories
# Run from project root: .\scripts\clone-upstreams.ps1
# Creates _research/upstreams/<name> with --depth=1 shallow clones.

param(
    [switch]$SkipExisting,
    [string]$Filter = ""  # Optional: filter by repo name substring
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$upstreams_dir = Join-Path $root "_research\upstreams"

if (-not (Test-Path $upstreams_dir)) {
    New-Item -ItemType Directory -Path $upstreams_dir -Force | Out-Null
}

$repos = @(
    @{ name = "oh-my-pi";                         url = "https://github.com/can1357/oh-my-pi.git" },
    @{ name = "superpowers";                       url = "https://github.com/obra/superpowers.git" },
    @{ name = "skills";                            url = "https://github.com/anthropics/skills.git" },
    @{ name = "spec-kit";                          url = "https://github.com/github/spec-kit.git" },
    @{ name = "OpenSpec";                          url = "https://github.com/Fission-AI/OpenSpec.git" },
    @{ name = "Agent-Skills-for-Context-Engineering"; url = "https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering.git" },
    @{ name = "agent-skills";                      url = "https://github.com/addyosmani/agent-skills.git" },
    @{ name = "promptfoo";                         url = "https://github.com/promptfoo/promptfoo.git" },
    @{ name = "ECC";                               url = "https://github.com/affaan-m/ECC.git" },
    @{ name = "mini-swe-agent";                    url = "https://github.com/SWE-agent/mini-swe-agent.git" },
    @{ name = "andrej-karpathy-skills";            url = "https://github.com/multica-ai/andrej-karpathy-skills.git" },
    @{ name = "12-factor-agents";                  url = "https://github.com/humanlayer/12-factor-agents.git" },
    @{ name = "aider";                             url = "https://github.com/Aider-AI/aider.git" },
    @{ name = "agents.md";                         url = "https://github.com/agentsmd/agents.md.git" },
    @{ name = "serena";                            url = "https://github.com/oraios/serena.git" },
    @{ name = "repomix";                           url = "https://github.com/yamadashy/repomix.git" },
    @{ name = "context7";                          url = "https://github.com/upstash/context7.git" }
)

$filtered = if ($Filter) { $repos | Where-Object { $_.name -like "*$Filter*" } } else { $repos }
$ok = 0; $skipped = 0; $failed = 0

foreach ($repo in $filtered) {
    $dest = Join-Path $upstreams_dir $repo.name
    if ($SkipExisting -and (Test-Path $dest)) {
        Write-Host "SKIP  $($repo.name) (already exists)" -ForegroundColor DarkGray
        $skipped++
        continue
    }
    Write-Host "Clone $($repo.name)..." -ForegroundColor Cyan
    try {
        git clone --depth=1 --single-branch $repo.url $dest 2>&1 | Out-Null
        $hash = git -C $dest rev-parse HEAD 2>&1
        Write-Host "  OK    $($repo.name) @ $($hash.Substring(0,[Math]::Min(8,$hash.Length)))" -ForegroundColor Green
        $ok++
    } catch {
        Write-Host "  FAIL  $($repo.name): $_" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "$ok cloned, $skipped skipped, $failed failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
if ($failed -gt 0) { exit 1 }
