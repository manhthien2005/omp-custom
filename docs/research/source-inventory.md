# Source Inventory

> Authority boundary: This research file is source/research evidence.
> Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology,
> dispatch, review mechanism, or capability behavior.
> Current design and execution authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.

<!-- Generated: 2026-08-07 — Phase 1 complete -->

## Summary

17 upstream repositories cloned under `_research/upstreams/`. All pinned to shallow commits recorded in `registry/upstreams.yml`.

## Tier A — Runtime authority

| # | Repository | Commit | License | Purpose |
|---|-----------|--------|---------|---------|
| 1 | can1357/oh-my-pi | `3a8591a` | MIT | OMP source: agents, skills, config, compaction, LSP, task orchestration |

## Tier B — Core methodology authorities

| # | Repository | Commit | License | Purpose |
|---|-----------|--------|---------|---------|
| 2 | obra/superpowers | `44c9b2d` | MIT | systematic-debugging, verification-before-completion, plan writing |
| 3 | anthropics/skills | `b29e7cf` | No License | SKILL.md format, progressive disclosure, skill packaging |
| 4 | github/spec-kit | `81d5cdb` | MIT | constitution, clarification gate, spec template, acceptance scenarios |
| 5 | Fission-AI/OpenSpec | `d578896` | MIT | brownfield change lifecycle, delta specs, archive lifecycle |
| 6 | muratcankoylan/Agent-Skills-for-Context-Engineering | `a1841d1` | MIT | context budget, degradation prevention, progressive retrieval |
| 7 | addyosmani/agent-skills | `d2478bf` | MIT | production quality gates, API compatibility, security review |
| 8 | promptfoo/promptfoo | `1c30e18` | MIT | evaluation infrastructure (external tool, not integrated) |

## Tier C — Pattern and constraint sources

| # | Repository | Commit | License | Purpose |
|---|-----------|--------|---------|---------|
| 9 | affaan-m/ECC | `9aac858` | MIT | model routing patterns, security hardening (pattern mine only) |
| 10 | SWE-agent/mini-swe-agent | `a83fcae` | MIT | complexity governor: minimal loop, small tool surface |
| 11 | multica-ai/andrej-karpathy-skills | `2c60614` | No License | coding constitution principles (inspiration only, no copy) |
| 12 | humanlayer/12-factor-agents | `d20c728` | Apache-2.0 / CC-BY-SA-4.0 | workflow architecture principles, context ownership |
| 13 | Aider-AI/aider | `5dc9490` | Apache-2.0 | repository-map principles, symbol-first exploration |
| 14 | agentsmd/agents.md | `d1ac7f0` | MIT | AGENTS.md structural patterns |

## Tier D — Conditional tool references

| # | Repository | Commit | License | Purpose |
|---|-----------|--------|---------|---------|
| 15 | oraios/serena | `c7af2c0` | MIT | optional semantic retrieval via MCP |
| 16 | yamadashy/repomix | `a27ecec` | MIT | repository subset snapshots for onboarding/audits |
| 17 | upstash/context7 | `8d52608` | MIT | versioned library documentation MCP tool |

## Licensing status

| Status | Count | Repositories |
|--------|-------|-------------|
| MIT | 13 | oh-my-pi, superpowers, spec-kit, OpenSpec, agent-skills-context-engineering, addyosmani-agent-skills, promptfoo, ECC, mini-swe-agent, aider (Apache), 12-factor-agents (Apache/CC), agents-md, serena, repomix, context7 |
| Apache-2.0 | 2 | Aider-AI/aider, humanlayer/12-factor-agents (code) |
| CC-BY-SA-4.0 | 1 | humanlayer/12-factor-agents (content) |
| No license file | 2 | anthropics/skills, multica-ai/andrej-karpathy-skills |

**Licensing risk flags:**
- `anthropics/skills`: No LICENSE file. THIRD_PARTY_NOTICES.md covers only third-party components. **Do not copy skill body text.** Use only as format reference.
- `andrej-karpathy-skills`: No LICENSE file. **Do not copy CLAUDE.md text.** Rewrite principles independently.
- `12-factor-agents` content: CC BY-SA 4.0 requires attribution and share-alike. Attribution recorded in `registry/licenses.yml`.

## Upstream installers status

No upstream installers were run. All repositories are read-only research material.
