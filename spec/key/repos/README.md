# spec/key/repos — Per-Upstream Deep Reports

> **What this folder is.** One report per upstream, all in the same shape (`_CONTRACT.md`),
> so they can be compared, diffed, and rolled up mechanically.
>
> Every report repeats its own authority boundary. This folder summary cannot substitute for
> that per-file statement: reports are source/research evidence, while current design and
> execution authority lives in the accepted design, key decisions, active specs, phase plans,
> and Topic 03-selected manifest.
>
> **Why it exists alongside `dossiers/`.** The `dossiers/` were organized by *cluster*
> (retrieval, skills, spec-workflow). That was efficient to produce and turned out to be the
> wrong axis: a cluster file cannot be diffed against another cluster file, coverage hides
> inside prose, and a repo that got two paragraphs looks the same as one that got twenty. It
> also let five repos reach a verdict with their source never opened. These reports fix the
> axis: one repo, one file, one mandatory coverage section.

---

## Reading order

| If you want | Read |
|---|---|
| What OMP can already do that we are not using | `oh-my-pi-settings.md`, `oh-my-pi-prompt-discovery.md` |
| Whether `/orchestrated` is built on the right primitive | `oh-my-pi-orchestration.md` |
| How to build an eval harness that cannot lie | `promptfoo.md` |
| Whether ranking is worth building | `aider.md`, then `serena.md`, `repomix.md` |
| Skill authoring and description craft | `superpowers.md`, `skills.md`, `agent-skills.md` |
| Acceptance-criteria craft | `spec-kit.md`, `OpenSpec.md` |
| The strongest argument *against* our architecture | `mini-swe-agent.md` |
| What breadth-without-enforcement costs | `ECC.md` |

---

## Status

`_CONTRACT.md` defines the required shape. Every report must carry §7 Coverage and limits —
a report without it is not finished, regardless of length.

| Report | Scope | Prior coverage being replaced | Pass |
|---|---|---|---|
| `oh-my-pi-settings.md` | **453** setting keys (415 dotted + 38 flat), 91 namespaces | 146 of 607 keys (both numbers were wrong — see §5-1 of that report); **2026-08-08 pass reads 52 key defs, all 453 enumerated** | 2026-08-08 |
| `oh-my-pi-orchestration.md` | `task` vs `eval` paths, full comparison | `eval` DSL discovered late; spec chose `task` without knowing it existed | 2026-08-07 |
| `oh-my-pi-prompt-discovery.md` | discovery roots, prompt assembly, rules/skills | discovery tables incomplete; `WATCHDOG.yml` absent; foreign providers unmanaged | 2026-08-07 |
| `promptfoo.md` | assertions, fixtures, scoring, reproducibility | assertion *names* only, from docs | 2026-08-07 |
| `aider.md` | ranking algorithm + ContextCoder + architect/editor + failure feedback | **source never opened in full** (`repomap.py` previously only); **2026-08-08 pass reads repomap.py in full + 5 other files** | 2026-08-08 |
| `serena.md` | symbol tools, index/cache, LSP strategy, memory | one grep of `symbol_tools.py` | 2026-08-07 |
| `repomix.md` | packing, token counting, ranking-or-not | **source never opened** | 2026-08-07 |
| `context7.md` | tool surface, version resolution, token profile, CLI telemetry | **source never opened** — **2026-08-08 pass reads 10 files in full including index.ts, api.ts, all 3 skills** | 2026-08-08 |
| `OpenSpec.md` | criteria craft, lifecycle, validation, decomposition | `git ls-files` only, 1,052 files unread | 2026-08-07 |
| `spec-kit.md` | same, plus constitution semver + Sync Impact Report | 9 files read; gaps remain | 2026-08-07 |
| `superpowers.md` | authoring craft, description craft, pressure fixtures | read as part of a cluster | 2026-08-07 |
| `skills.md` | `skill-creator` + its eval scripts; per-skill licensing | ~9 skills; scripts unread | 2026-08-07 |
| `agent-skills.md` | eval cases with owning-skill attribution | ~6 of 24 bodies | 2026-08-07 |
| `Agent-Skills-for-Context-Engineering.md` | routing-aware descriptions, topology rationale | ~5 of 17 bodies | 2026-08-07 |
| `andrej-karpathy-skills.md` | four principles; in-file MIT grant | **NEW — all 9 files, first pass** | 2026-08-08 |
| `12-factor-agents.md` | all 13 factors vs our design | 4 of 13 factors | 2026-08-07 |
| `mini-swe-agent.md` | minimal loop, termination, limits | 2 files | 2026-08-07 |
| `agents.md.md` | the convention vs OMP's stricter implementation | tree + README size | 2026-08-07 |
| `ECC.md` | mine 282 skills / 67 agents; price the breadth | read as negative control only | 2026-08-07 |

---

## Standing filters every report is run through

1. **A mechanism with no OMP attachment point is documentation, or a defect.** The rule that
   would have prevented `.omp/policies/` — nine YAML files, 581 lines, zero consumers.
2. **OMP is the only runtime.** Upstream loop controllers, schedulers, and worktree managers
   are out of scope by constraint. Extract the craft inside them instead.
3. **No recommendation without a cost tier** (`zero` / `persistent` / `lazy` / `per-spawn` /
   `per-action`).
4. **The skill library is capped at 10** (hard ceiling 12), because in OMP every subagent pays
   for the full skill listing. A recommendation of 20 skills is a budget violation, not a
   recommendation.
5. **Enumeration is not ranking.** Conflating them is a mistake already made once in this
   project; every retrieval report must answer the question directly.
6. **Optimize tokens per accepted outcome**, never tokens alone.
