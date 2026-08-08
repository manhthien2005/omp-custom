# Repo Report — oh-my-pi (prompt assembly & discovery)

> **Path:** `_research/upstreams/oh-my-pi`
> **SHA:** `3a8591a8af5b6d200088d12ca75a5517cb064fa8` (`git -C _research/upstreams/oh-my-pi rev-parse HEAD`)
> **License:** MIT. `LICENSE` carries a dual copyright line — `Copyright (c) 2025 Mario Zechner` and
> `Copyright (c) 2025-2026 Can Bölük`. Standard MIT grant, no additional in-file restrictions found
> in the files opened this pass.
> **Size:** 6323 tracked files (`git ls-files | wc -l`)
> **Read this pass:** all of `discovery/builtin.ts`, `discovery/helpers.ts`, `discovery/agents.ts`,
> `discovery/agents-md.ts`, `discovery/at-imports.ts`, `capability/rule.ts`,
> `capability/rule-buckets.ts`, `capability/instruction.ts`, `advisor/watchdog.ts`,
> `advisor/config.ts`, `config/prompt-templates.ts`, `task/discovery.ts`,
> `prompts/system/system-prompt.md`, `prompts/system/subagent-system-prompt.md`,
> `prompts/system/custom-system-prompt.md`, `prompts/system/project-prompt.md`,
> `prompts/system/orchestrate-notice.md`, `prompts/system/ultrathink-notice.md`,
> `modes/{ultrathink,orchestrate,workflow,magic-keyword-boundary}.ts`,
> `docs/rulebook-matching-pipeline.md`. Sampled by grep/section: `system-prompt.ts`, `sdk.ts`,
> `task/executor.ts`, `task/structured-subagent.ts`, `session/agent-session.ts`,
> `session/session-advisors.ts`, `config/settings-schema.ts`, `config.ts`, `capability/fs.ts`,
> `discovery/{claude,claude-plugins,codex,cursor,gemini,opencode,windsurf,cline,github,vscode,mcp-json,ssh,omp-plugins,omp-extension-roots}.ts`,
> `crates/pi-walker/src/lib.rs`, `crates/pi-natives/src/glob.rs`.

Cited `file:line` is relative to `packages/coding-agent/src/` unless the path starts with
`docs/` or `crates/`.

---

## 1. What this repo is

The OMP runtime itself — a Bun/TypeScript coding agent with Rust natives. For this report's scope
it is two subsystems: a **capability/provider registry** that scans the filesystem for config from
OMP *and thirteen other agent tools*, and a **prompt assembler** that renders one Handlebars-ish
template family into an array of system-prompt blocks. Both are single implementations with no
plugin seam we control, so every claim below is a hard constraint on our template, not a preference.

## 2. Mechanism inventory

### 2a. Every path the `native` provider reads under `.omp/`

The gate for the whole directory is `ifNonEmptyDir` (`discovery/builtin.ts:46-56`): it calls
`readDirEntries` and returns `null` when the listing is empty. `getConfigDirs`
(`discovery/builtin.ts:58-73`) uses it for both project (`cwd/.omp` — **cwd only, no walk**) and
user (`getAgentDir()`). **An empty `.omp/` directory is invisible to every capability that routes
through `getConfigDirs`.** Confirmed.

Two separate resolution strategies exist and the difference is the single most load-bearing fact
in this report:

| Strategy | Helper | Reach |
|---|---|---|
| **cwd-only** | `getConfigDirs` → `ifNonEmptyDir(ctx.cwd, ".omp")` | exactly `cwd/.omp`, nothing above |
| **ancestor walk** | `getAncestorDirs` (`builtin.ts:75-88`) / `findNearestProjectConfigDir` (`builtin.ts:90-99`) | `cwd` up to `repoRoot` (or `home`) |

| # | `.omp/` path | Capability it becomes | Resolution | Evidence `file:line` | Grade |
|---|---|---|---|---|---|
| 1 | `.omp/skills/<name>/SKILL.md` | `skills` | **ancestor walk**, closest first, stop at `repoRoot ?? home` | `builtin.ts:282-307` (walk at `:284`) | A |
| 2 | `.omp/AGENTS.md` | `context-files` | **ancestor walk**, *nearest non-empty `.omp/` only* | `builtin.ts:906-937` (`:921`) | A |
| 3 | `.omp/RULES.md` | `rules`, forced `alwaysApply:true`, name `RULES@project` | **ancestor walk**, nearest non-empty `.omp/` only | `builtin.ts:396-401`, `:410-419` | A |
| 4 | `.omp/SYSTEM.md` | `system-prompts` (wholesale replacement — see §2c) | **ancestor walk**, nearest non-empty `.omp/` only | `builtin.ts:242-271` (`:256`) | A |
| 5 | `.omp/rules/*.{md,mdc}` | `rules` (rulebook / always / TTSR) | **cwd only** | `builtin.ts:372-385` | A |
| 6 | `.omp/commands/*.md` | `slash-commands` | **cwd only** | `builtin.ts:340-361` | A |
| 7 | `.omp/prompts/*.md` | `prompts` capability | **cwd only** | `builtin.ts:430-450` | A |
| 8 | `.omp/instructions/*.md` (`applyTo`) | `instructions` capability — **INERT, see §4** | **cwd only** | `builtin.ts:637-661` | A |
| 9 | `.omp/hooks/{pre,post}/<tool>.*` | `hooks` | **cwd only** | `builtin.ts:672-720` | A |
| 10 | `.omp/tools/*.{json,md,ts,js,sh,bash,py}` + `.omp/tools/<n>/index.ts` | `tools` (custom tools) | **cwd only** | `builtin.ts:731-836` | A |
| 11 | `.omp/extensions/*.{ts,js}`, `<n>/index.*`, `<n>/package.json#omp` | `extension-modules` | **cwd only** | `builtin.ts:461-559`, `helpers.ts:619-699` | A |
| 12 | `.omp/extensions/<n>/gemini-extension.json` | `extensions` | **cwd only** | `builtin.ts:570-626` | A |
| 13 | `.omp/settings.json` | `settings` (+ `extensions:` array → #11) | **cwd only** | `builtin.ts:862-877` | A |
| 14 | `.omp/config.yml` | `settings` (YAML variant) | **cwd only** | `builtin.ts:879-891` | A |
| 15 | `.omp/mcp.json`, `.omp/.mcp.json` | `mcps` | **cwd only**, and **NOT gated by `ifNonEmptyDir`** — read directly at `:207-208` | `builtin.ts:206-211` | A |
| 16 | `.omp/plugins/installed_plugins.json` | Claude-format plugin registry | **ancestor walk** for `.omp/`, then `.git` fallback | `helpers.ts:821-855` | A |
| 17 | `.omp/agents/*.md` | task-agent definitions (our 4 workers) | **`findAllNearestProjectConfigDirs`** — nearest `.omp/agents` *directory* walking up | `task/discovery.ts:80-91`, `config.ts:206-235` | A |
| 18 | `.omp/prompts/**/*.md` (again) | `PromptTemplate` (`/name` expansion) | **cwd only**, via a *second, independent* loader | `config/prompt-templates.ts:165-181` | A |
| 19 | `.omp/WATCHDOG.md` / `.omp/WATCHDOG.yml` / `.yaml` | advisor roster + attention text — see §2d | **ancestor walk**, `.omp/<F>` *and* bare `<F>` at each level | `advisor/watchdog.ts:53-121` | A |
| 20 | `.omp/APPEND_SYSTEM.md` | appended system block | `findConfigFile` — **cwd only**, `.omp` → `.claude` → `.codex` → `.gemini` | `main.ts:860-871`, `config.ts:172-183` | A |
| 21 | `.omp/TITLE_SYSTEM.md` | session-title prompt override | `findConfigFile`, cwd only | `system-prompt.ts:301-311` | A |

Note on #17 and #20/#21: these bypass the capability registry entirely and use
`config.ts`'s own `getConfigDirs`, whose `PROJECT_CONFIG_BASES` is `[".omp", ".claude", ".codex",
".gemini"]` (`config.ts:9-13`, `:88-91`). So `findConfigFile("SYSTEM.md")` will happily return
`.claude/SYSTEM.md` when `.omp/SYSTEM.md` is absent.

### 2b. FOREIGN discovery providers — the unmanaged-input surface

`discovery/index.ts:23-39` imports 17 provider modules. They register **18 distinct provider ids**
(`builtin.ts` registers both `native` and `managed-skills`). Of these, **13 read directories that
are not `.omp/`**. Every one is enabled by default: the only lever is `disabledProviders`
(`config/settings-schema.ts:529`, default `[]`) consumed at `capability/index.ts:239`, `:285-288`.

| Provider id | Prio | Reads | Capabilities it grants | Walks ancestors? | Evidence |
|---|---|---|---|---|---|
| `native` | 100 | `.omp/`, `~/.omp/agent/` | all 14 | partially (§2a) | `builtin.ts:39-42` |
| `managed-skills` | 5 | `~/.omp/agent/managed-skills/` | `skills` | no | `builtin.ts:313-337` |
| `omp-plugins` | 90 | `<extRoot>/{skills,hooks,tools,commands,rules,prompts,.mcp.json}` for CLI `--extension`, `extensions:` settings, and npm/link plugins | skills, commands, rules, prompts, hooks, tools, mcps | n/a | `omp-plugins.ts:41-45`, `omp-extension-roots.ts` |
| **`claude`** | 80 | `~/.claude/`, `<cwd>/.claude/` | mcps, context-files (`CLAUDE.md`), **skills**, extension-modules, **slash-commands**, hooks, tools, settings, **system-prompts (`~/.claude/SYSTEM.md`)** | **yes for `skills` only** (`.claude/skills` up to repoRoot, skipping `$HOME`) | `claude.ts:32-34`, `:169-191`, `:450-469`, `:521-590` |
| **`claude-plugins`** | 70 | `~/.claude/plugins/cache/` per `installed_plugins.json`, plus OMP's own and the project registry | skills, slash-commands, hooks, tools, mcps | via registry resolution | `claude-plugins.ts:29-31`, `:586-622`; `helpers.ts:902-1079` |
| **`agents`** | 70 | `~/.agent/`, `~/.agents/`, and `<ancestor>/.agent[s]/` — **plus the Windows host profile under WSL** | skills, rules, prompts, slash-commands, context-files (`AGENTS.md`), **system-prompts (`SYSTEM.md`)** | **yes, all six** | `agents.ts:26-29`, `:100-131`, `:150-299` |
| **`codex`** | 70 | `~/.codex/`, `<cwd>/.codex/`, `config.toml` | context-files (`~/.codex/AGENTS.md`), mcps, skills, extension-modules, slash-commands, prompts, hooks, tools, settings | no | `codex.ts:42-44`, `:483-551` |
| **`gemini`** | 60 | `~/.gemini/`, `<cwd>/.gemini/` | mcps, context-files (`GEMINI.md`), **system-prompts (`system.md`, user *and* project)**, extensions, extension-modules, settings | no | `gemini.ts:39-41`, `:302-386` |
| **`opencode`** | 55 | `~/.config/opencode/`, `<cwd>/.opencode/`, `<cwd>/opencode.json` | context-files (`AGENTS.md`), mcps, skills, extension-modules (`plugins/`), slash-commands, settings | no | `opencode.ts:42-44`, `:395-441` |
| **`cursor`** | 50 | `~/.cursor/`, `<cwd>/.cursor/` | mcps (`mcp.json`), rules (`rules/*.{mdc,md}`), settings | no | `cursor.ts:35-37`, `:201-223` |
| **`windsurf`** | 50 | `~/.codeium/windsurf/memories/global_rules.md`, `<cwd>/.windsurf/rules/*.md` | mcps (`mcp_config.json`), rules | no | `windsurf.ts:29-31`, `:135-149` |
| **`cline`** | 40 | nearest `.clinerules` (file or dir) walking up | rules | **yes** | `cline.ts:15-17`, `:20-33`, `:77-83` |
| **`github`** | 30 | `<cwd>/.github/`, `~/.copilot/` (or `$COPILOT_HOME`), each dir in `$COPILOT_CUSTOM_INSTRUCTIONS_DIRS` | rules (`*.instructions.md`), skills, prompts (`*.prompt.md`), instructions | via env list | `github.ts:40-42`, `:52-198`, `:316-337`; `helpers.ts:117-120` |
| **`vscode`** | 20 | `<cwd>/.vscode/mcp.json` | mcps | no | `vscode.ts:14-16`, `:22-30` |
| `agents-md` | 10 | bare `AGENTS.md` at every ancestor up to `repoRoot ?? home`, skipping dot-dirs | context-files | **yes** | `agents-md.ts:15-16`, `:21-67` |
| `builtin-defaults` | 1 | embedded (`discovery/builtin-rules/*.md`, 21 files) | rules (TTSR) | n/a | `builtin-defaults.ts:20-37` |
| `mcp-json` | — | `mcp.json` / `.mcp.json` in cwd | mcps | no | `mcp-json.ts:17-18`, `:161`, `:176` |
| `ssh-json` | — | `<cwd>/ssh.json`, `<cwd>/.ssh.json` | ssh hosts | no | `ssh.ts:16-17`, `:132-133`, `:147` |

**Count that matters for us: 13 foreign providers reading non-`.omp` paths** (`claude`,
`claude-plugins`, `agents`, `codex`, `gemini`, `opencode`, `cursor`, `windsurf`, `cline`, `github`,
`vscode`, `agents-md`, `ssh-json`). Adding `mcp-json` (cwd-root `mcp.json`, arguably ours) gives
**14**, which matches the prior audit's number. Grade A.

The two highest-risk foreign inputs for a workflow template:

1. **`agents` provider (prio 70) reads `SYSTEM.md`** from `<ancestor>/.agent[s]/SYSTEM.md` **with
   an ancestor walk** (`agents.ts:284-300`), and under WSL also from the Windows host profile
   (`agents.ts:88-104`). A `SYSTEM.md` there replaces the whole default prompt (§2c) at priority 70
   — below `native` (100) but above everything else. A stray `~/.agents/SYSTEM.md` on a dev's
   machine silently swaps our entire prompt.
2. **`gemini` provider registers `system.md` at *project* level** (`gemini.ts:339-351`), so
   `<cwd>/.gemini/system.md` is also a whole-prompt replacement candidate.

Skill listing is the shared blast radius: `claude`, `claude-plugins`, `agents`, `codex`,
`opencode`, `github`, `omp-plugins`, `managed-skills`, and `native` all register `skills`. Every
skill any of them finds lands in the persistent `<skills>` block (§2c). Note `native`/`omp-plugins`/
`github` pass `requireDescription: true` (`builtin.ts:290,299,319`; `omp-plugins.ts:59`;
`github.ts:291`) but **`claude`, `claude-plugins`, `agents`, `codex`, `opencode` do not** — a
description-less `SKILL.md` from those sources loads with an empty description and still consumes a
line in the listing.

### 2c. PROMPT ASSEMBLY

`buildSystemPromptInternal` (`system-prompt.ts`, ends `:921`) returns
`{ systemPrompt: string[] }` — an **array of blocks**, not one string. Composition
(`system-prompt.ts:899-916`):

```
block 0 = render(resolvedCustomPrompt ? custom-system-prompt.md : system-prompt.md, data)
block +  = computer-safety.md          (only when toolNames includes "computer")   :900-903
block +  = render(project-prompt.md, data)                                          :906-911
block +  = activeRepoContextPrompt     (when in a nested repo)                      :912-914
```

Two mutually exclusive templates for block 0:

- **`system-prompt.md`** (263 lines) — the default. Contains the skills listing
  (`prompts/system/system-prompt.md:27-33` — **verified, the prior claim is correct**),
  `<generic-rules>` = always-apply rule bodies (`:36-42`), `<domain-rules>` = rulebook
  name+globs+description lines (`:44-50`), internal-URL catalog (`:52-72`), tool inventory
  (`:74-83`), tool policy, delegation gates (`:147-178`), the 6-phase execution workflow
  (`:180-215`), and the delivery contract (`:217-263`).
- **`custom-system-prompt.md`** (65 lines) — used **only** when a `resolvedCustomPrompt` exists.
  It renders `systemPromptCustomization`, then `customPrompt`, then `appendPrompt`, then a
  `<project>` block, then skills, then always-apply rules, then rules. It **drops** the
  tool inventory, internal URLs, tool policy, delegation gates, execution workflow, and delivery
  contract entirely.

#### SILENT DEGRADATION #1 — `SYSTEM.md` discovered by the capability path is never rendered

`{{systemPromptCustomization}}` appears in **exactly one file**: `custom-system-prompt.md:1-3`.
Verified by exhaustive grep over `src/` and `test/` — the only other hits are the five plumbing
lines in `system-prompt.ts` (`:625, :677, :732, :754, :842, :857`). It does **not** appear in
`system-prompt.md` or `project-prompt.md` (grep count 0 for both).

`custom-system-prompt.md` is selected only when `resolvedCustomPrompt` is truthy
(`system-prompt.ts:899`). But `resolvedCustomPrompt` comes from the caller's `customSystemPrompt`
option, and `systemPromptCustomization` is loaded **only when the caller did NOT supply one** —
`callerControlsCustomPrompt` short-circuits it to `null` otherwise (`system-prompt.ts:674-679`).

So the two are mutually exclusive by construction: whenever `systemPromptCustomization` is
non-null, `resolvedCustomPrompt` is falsy, the *default* template is chosen, and that template has
no `{{systemPromptCustomization}}` placeholder. **A `SYSTEM.md` reaching `buildSystemPromptInternal`
through the capability provider path (`builtin.ts:242-271`, `loadSystemPromptFiles` at
`system-prompt.ts:396-407`) is loaded, deduped, passed into `data`, and then discarded by the
template.** Grade A on the code reading; **Grade D on the runtime consequence** — needs one live run
to confirm nothing upstream of `buildSystemPromptInternal` re-routes it.

The path that *does* work is the CLI/main path: `main.ts:846-858` `discoverSystemPromptFile()` uses
`findConfigFile("SYSTEM.md")` (cwd-only, `.omp`→`.claude`→`.codex`→`.gemini`), and
`applyResolvedSystemPromptInputs` (`main.ts:874-884`) assigns it to
`options.customSystemPrompt` → `resolvedCustomPrompt` (`sdk.ts:2918`) → selects
`custom-system-prompt.md`. **That is the wholesale-replacement path, and it is a real one.**

Consequence for us: `.omp/SYSTEM.md` at the project root, in a normal `omp` CLI launch, replaces
block 0 with the 65-line stub and **deletes the tool policy, delegation gates, execution workflow,
and delivery contract**. It does NOT walk ancestors on this path (`findConfigFile` is cwd-only), and
it *will* fall through to `.claude/SYSTEM.md` if ours is absent. Two different discovery mechanisms
for the same filename with different reach and different rendering behavior. Grade A.

#### The subagent prompt

`task/executor.ts:3029-3046`:

```ts
systemPrompt: defaultPrompt => {
  const subagentPrompt = prompt.render(subagentSystemPromptTemplate, { agent: agent.systemPrompt, … });
  return defaultPrompt.length === 0
    ? [subagentPrompt]
    : [...defaultPrompt.slice(0, -1), subagentPrompt, defaultPrompt[defaultPrompt.length - 1]];
}
```

**Verified: the subagent template is spliced in second-to-last, not substituted.** The subagent
receives every default block. Its own `ROLE`/`COOP`/`COMPLETION` sections land *before* the last
default block (which is `project-prompt.md` or `activeRepoContext`). So the subagent inherits, in
order: the full `system-prompt.md`, then its assignment, then `project-prompt.md`. The prior claim
is correct.

What the subagent inherits that it arguably should not:

| Inherited | Why it's wrong for a worker | Evidence |
|---|---|---|
| **Full `<skills>` listing** | Every spawn re-pays for the whole library. This is the cost multiplier already recorded in memory. | `system-prompt.md:27-33`; `structured-subagent.ts:367-370, :434` passes `skills` = full parent set |
| **Delegation gates + concurrency cap** (`# Delegation`, `## Delegation gates`) | ~30 lines telling a leaf worker to decompose and fan out. `spawns` may forbid it entirely, and the block is gated on `{{#has tools "task"}}` only — not on agent kind. | `system-prompt.md:147-178` |
| **`# 3. Decompose` / todo batching rules** | Contradicts `subagent-system-prompt.md:49` "No TODO tracking, no progress updates." Both are in the same prompt. | `system-prompt.md:192-194` vs `subagent-system-prompt.md:49` |
| **Full `<generic-rules>` + `<domain-rules>`** | `rules: rulebookRules` and `alwaysApplyRules` are inherited verbatim (`structured-subagent.ts:437` passes `session.rules`; `executor.ts:3027` `rules: options.rules`). | `sdk.ts:2923`; `executor.ts:3027` |
| **`project-prompt.md`'s `<critical>` block** | Tells the worker "no stopping condition other than completion" *and* it must self-verify behavioral changes — which the orchestrate contract explicitly forbids subagents from doing (rule 9). | `project-prompt.md:53-57` vs `orchestrate-notice.md:17` |
| **Whole tool inventory** | Even when `toolNames` is restricted, `toolInfo` is built from the *resolved* set, so this one is actually correct. Not a defect. | `system-prompt.ts:812-838` |

Two things the subagent correctly does **not** inherit:

- `personality` is forced to `"none"` for `agentKind === "sub"` (`sdk.ts:2947`, kind decided at
  `sdk.ts:1657`).
- `AGENTS.md` is filtered out of inherited `contextFiles`:
  `session.contextFiles?.filter(f => path.basename(f.path).toLowerCase() !== "agents.md")`
  (`structured-subagent.ts:433`, mirrored `vibe/runtime.ts:1434`). Note this is a **basename**
  filter — `CLAUDE.md`, `GEMINI.md`, `RULES.md` bodies, and `.omp/AGENTS.md` (basename *is*
  `agents.md`, so that one *is* filtered) behave differently. `CLAUDE.md` and `GEMINI.md` survive
  into every subagent.

### 2d. `magicKeywords` — exact keywords, sizes, triggers

Three keywords. Detection is `keywordInProse(text, magicKeywordRegex(kw))` — **lowercase only**,
prose-delimited, never inside a fenced block / inline code span / XML section
(`modes/magic-keyword-boundary.ts:1-23`, `modes/markdown-prose.ts`). Boundaries reject letters,
digits, `_`, `/`, `\`, `-`, a following `.<word>`, a following `(`, and a preceding `::`. So
`Ultrathink`, `ultrathinking`, `orchestrate.ts`, `orchestrate()` do **not** fire.

Injection: `#createMagicKeywordNotices` (`session/agent-session.ts:4882-4922`), called from
`sendPrompt` (`:4974`, skipped when `options.synthetic`) and from the skill-invocation path
(`:5081`). Each notice is pushed as `{ role: "custom", display: false, attribution: "user" }` —
**a hidden message in the conversation, not a system-prompt block.** So the cost is per-turn-that-
mentions-it, not persistent.

Gate: `#magicKeywordEnabled` requires `magicKeywords.enabled` **AND** `magicKeywords.<kw>`
(`agent-session.ts:4878-4880`). **All four default to `true`**
(`config/settings-schema.ts:1871-1912`).

| Keyword | Notice file | Size | Extra trigger condition | Grade |
|---|---|---|---|---|
| `ultrathink` | `prompts/system/ultrathink-notice.md` | **3 lines / 129 bytes** (~35 tok) | none. Also bypasses the auto-thinking classifier and the `providers.autoThinkingMaxEffort` ceiling, jumping straight to `Effort.Max` (`session/model-controls.ts:597-602`) | A |
| `orchestrate` | `prompts/system/orchestrate-notice.md` | **40 lines / 5539 bytes** (~1.4k tok, estimate at 4 B/tok) | none | A |
| `workflowz` | `prompts/system/workflow-notice.md` | **112 lines / 9538 bytes** (~2.4k tok, estimate) | **only when the active tool set contains BOTH `task` and `eval`** (`agent-session.ts:4907-4910`); rendered with `taskBatch` and `scoutAvailable` (`modes/workflow.ts:26-33`) | A |

The prior audit's "large hidden system notices" is right for `orchestrate` and `workflowz`, wrong
for `ultrathink` (129 bytes).

#### SILENT DEGRADATION #2 — `orchestrate` contradicts a flat topology, at any depth

`orchestrate-notice.md` is a 10-rule contract that says, verbatim (`:11`): *"Parallelize maximally;
NEVER launch a one-off task… If you are about to dispatch exactly one subagent, stop."* and (`:17`)
*"Subagents do not verify, lint, or format. Every `task` assignment MUST instruct the subagent to
skip all gates and formatters."*

This fires on the mere presence of the lowercase word in prose — including a user asking *"should we
orchestrate this differently?"*. There is **no `agentKind` gate**: `#createMagicKeywordNotices` is a
method on `AgentSession`, and a subagent is an `AgentSession`. A worker that receives an assignment
containing the word `orchestrate` in prose gets the full orchestrator contract injected as a hidden
user-attributed message, in direct conflict with `subagent-system-prompt.md:49-58` (yield-only, no
todos) and with `project-prompt.md:56` (must self-verify). Grade A on the mechanism; **Grade C** on
"contradicts a flat-topology design" — that's our judgment, but the code offers no depth guard.

Mitigation is a setting, not a file: `magicKeywords.orchestrate: false`. Cost: `zero`.

### 2e. `buildRuleFromMarkdown` and activation semantics

`discovery/helpers.ts:182-221`. **Every field in the prior claim is verified:**

| Field | Accepted shapes | Parsed at |
|---|---|---|
| `globs` | `string[]` (string elements only) or single `string` | `helpers.ts:195-200` |
| `alwaysApply` | strictly `=== true` | `helpers.ts:213` |
| `description` | `string` only | `helpers.ts:214` |
| `condition` | `string` or `string[]`; legacy aliases `ttsr_trigger` / `ttsrTrigger` | `rule.ts:211-212` |
| `astCondition` | `string` or `string[]`, ast-grep patterns, kept verbatim | `rule.ts:213` |
| `scope` | `string` (comma-split, paren/bracket/brace/quote-aware) or `string[]`; tolerates the malformed `scope: "text","thinking"` | `rule.ts:86-177` |
| `interruptMode` | exactly one of `never` \| `prose-only` \| `tool-only` \| `always`; **anything else silently → `undefined`** | `helpers.ts:203-207` |
| extension | `.md` **and `.mdc`** (`stripNamePattern: /\.(md\|mdc)$/`), glob `extensions: ["md","mdc"]` | `builtin.ts:379-382` |

Activation is decided by `bucketRules` (`capability/rule-buckets.ts:33-66`), a **strict priority
cascade**, first match wins:

1. **TTSR** — non-empty `condition` OR `astCondition` **that `ttsrManager.addRule(rule)` accepts**
   (`:52-55`). If accepted, `continue` — the rule is TTSR-**only**. It fires mid-stream when the
   regex/pattern matches within `scope`, gated by `globs` as a path filter, and interrupts per
   `interruptMode ?? ttsr.interruptMode` (default `always`,
   `config/settings-schema.ts:3099-3115`).
2. **always-apply** — `alwaysApply === true` (`:56-59`). Full body injected into `<generic-rules>`
   every turn.
3. **rulebook** — has a `description` (`:60-62`). Only `- name (globs): description` is rendered;
   body is on-demand via `rule://<name>`.
4. **nothing.** Falls off the end of the loop.

Three levers drop rules before bucketing: `ttsr.disabledRules` by name (`:49`) and
`ttsr.builtinRules: false` for the `builtin-defaults` provider (`:50`). `ttsr.enabled` (default
`true`) governs the manager.

#### SILENT DEGRADATION #3 — the fourth bucket is a black hole

**A rule with no `description`, no `alwaysApply`, and no `condition`/`astCondition` is loaded,
validated, deduped, counted in `allRules` — and then reaches no bucket. It is invisible in the
prompt, unreachable via `rule://`, and produces no warning.** `rule-buckets.ts:48-63` simply falls
through. Corroborated by `docs/rulebook-matching-pipeline.md:311, :320`. A `.omp/rules/x.md` whose
frontmatter has a typo'd `descripton:` is completely inert. Grade A.

#### SILENT DEGRADATION #4 — `condition` glob shorthand rewrites your rule

`parseRuleConditionAndScope` (`capability/rule.ts:208-238`): a `condition` token that
`isLikelyFileGlob` accepts (`rule.ts:181-196`: contains `?*[]{}`, no `\^$+|()`, and either has a
`/` or matches `^\*\.[^\s/]+$`) is **removed from `condition`** and converted into
`tool:edit(<glob>)` + `tool:write(<glob>)` scope entries; if that empties `condition`, a catch-all
`.*` is inserted (`:228-230`). So `condition: "*.ts"` silently becomes "match *anything* written by
edit/write to a `.ts` file" — a firehose, not the intended filter. `astCondition` is exempt. Grade A.

#### SILENT DEGRADATION #5 — bucket precedence eats `alwaysApply`

TTSR runs first. A rule with **both** `alwaysApply: true` and an accepted `condition` is
TTSR-**only**: its body never enters `<generic-rules>`. It looks like a standing instruction and
behaves like a tripwire. `rule-buckets.ts:54-56`;
`docs/rulebook-matching-pipeline.md:225-226`. Grade A.

#### Is activation OBSERVABLE? — this decides testability

| Bucket | Observable? | How |
|---|---|---|
| always-apply | **Yes, statically.** Body appears in the rendered system prompt; `session.systemPrompt` is a public getter (`session/agent-session.ts:4136-4138`) and is exposed to extensions (`task/executor.ts:3218`). | A |
| rulebook | **Yes, statically.** The `- name (globs): description` line appears in `<domain-rules>`. Presence in the listing proves bucket assignment. | A |
| TTSR | **Yes, but only dynamically.** Registration is observable via `ttsrManager.getRules()` (`sdk.ts:1843`), and a fire emits a `ttsr_triggered` event with `rules` (`sdk.ts:1048`) plus a TUI notification (`modes/components/ttsr-notification.ts`). There is also a CLI surface: `cli/ttsr-cli.ts:277-292` calls `loadCapability("rules")` + `bucketRules` directly. | A |
| the fourth bucket | **No.** No warning, no event, no listing. Only detectable by *absence* from all three surfaces. | A |

**Testable conclusion:** all four states are distinguishable by a static diff of the rendered system
prompt plus `omp`'s ttsr CLI listing. `cli/ttsr-cli.ts` is the cheapest oracle — it runs the exact
production `bucketRules` call. No live model turn required except to test TTSR *firing*.
Grade B (I read the CLI's call site, not its full output format).

### 2f. `instructions/` capability and `applyTo`

`.omp/instructions/*.md` is parsed with `applyTo` from frontmatter
(`builtin.ts:645-654`), the name is stripped of `.instructions.md` then `.md`, and a provider is
registered for `instructionCapability` (`builtin.ts:663-669`). `github.ts:308-314` registers a
second provider for `.github/instructions/`.

#### SILENT DEGRADATION #6 — `instructions` has zero consumers

Exhaustive grep for `instructionCapability` and `loadCapability(…"instructions"…)` across
`src/`: the **only** references are the capability definition (`capability/instruction.ts:25-35`),
the two provider registrations, and **two lines in `test/discovery/github-copilot.test.ts:116,196`.**
There is no production `loadCapability("instructions")` call anywhere. `modes/components/extensions/
state-manager.ts` loads nine capabilities (skills, rules, tools, extension-modules, mcps, prompts,
slash-commands, hooks, context-files, `:106-275`) and **`instructions` is not among them** — so it
isn't even visible in the `/extensions` UI.

`.omp/instructions/` is the `.omp/policies/` pattern again: a real parser, a real provider, an
`applyTo` field, and no runtime consumer. **This is a top finding — anything we put there is
inert.** Grade A.

Note the discriminator: GitHub's `applyTo` *does* have an effect, but only because
`github.ts:197-215` uses it a **second time** on the `rules` capability path
(`normalizeApplyToGlobs` → `globs`, `*`/`**`/`**/*` → `alwaysApply`). The `instructions`
capability itself is dead in both providers.

### 2g. `@import` expansion

`discovery/at-imports.ts`. Semantics (all Grade A):

- Regex `(^|[ \t])@([./~A-Za-z0-9_-][^\s]*)` (`:40`) — `@` at line start or after a single space/tab.
- Relative paths resolve against **the importing file's own directory**, not cwd (`:181-186`).
  `~/` → home; absolute paths honored.
- Skipped inside fenced blocks (` ``` `/`~~~`, `:201-253`) and inline code spans
  (backtick-parity scan, `:261-273`).
- Trailing sentence punctuation `[.,;:!?)\]}"']+` stripped (`:49`), so `See @AGENTS.md.` works.
- Recursion depth **5** (`MAX_AT_IMPORT_DEPTH`, `:31`); `visited` is shared across the whole tree so
  cross-file cycles break (`:164-177`).
- **A missing target leaves the literal `@token` in place and logs at `debug` only** (`:170-173`).
  Silent degradation #7: a typo'd import is indistinguishable from prose.

**Where expansion runs — this is narrower than it looks.** Three call sites total:

| Consumer | Site |
|---|---|
| context files (`AGENTS.md` / `CLAUDE.md` / `GEMINI.md` / `.omp/AGENTS.md`) | `system-prompt.ts:375` inside `loadProjectContextFiles` |
| `WATCHDOG.md` blocks | `advisor/watchdog.ts:131` |
| `WATCHDOG.yml` `instructions` (shared + per-advisor) | `advisor/config.ts:161, :168` |

#### SILENT DEGRADATION #8 — `@import` does NOT work in rules, skills, or commands

`RULES.md`, `.omp/rules/*.md`, `SKILL.md`, and `.omp/commands/*.md` all go through
`buildRuleFromMarkdown` / `scanSkillsFromDir` / `loadFilesFromDir`, **none of which call
`expandAtImports`**. An `@shared/foo.md` in a rule or skill body is passed to the model as the
literal five-character-plus string. Grade A (verified by exhaustive grep — 3 call sites, none in
the rule/skill/command paths).

### 2h. `autoloadSkills` — whose budget?

Chain: frontmatter `autoloadSkills` (CSV or array, trimmed) → `ParsedAgentFields.autoloadSkills`
(`helpers.ts:307-309, :319`) → `AgentDefinition.autoloadSkills` (`task/types.ts:369`) →
`resolveAutoloadSkills` resolves names against the **parent's** skill list
(`task/structured-subagent.ts:366-370`) → `ExecutorOptions.autoloadSkills: Skill[]`
(`executor.ts:475`).

Injection (`task/executor.ts:3234-3248`):

```ts
if (options.autoloadSkills?.length) {
  for (const skill of options.autoloadSkills) {
    const { message } = await buildSkillPromptMessage(skill, "", "autoload");
    await session.sendCustomMessage(
      { customType: SKILL_PROMPT_MESSAGE_TYPE, content: message, display: false, … },
      { triggerTurn: false });
  }
}
```

`session` here is the **child** session, created at `executor.ts:3080`
(`createAgentSession(buildSubagentSessionOptions(...))`) and attached at `:3230`. The loop runs
after `extensionRunner.emit({type:"session_start"})` (`:3225`) and before
`driveSessionToYield(session, …)` (`:3251`).

**Answer: the autoloaded skill body charges the CHILD's context, not the parent's.** It is a
hidden (`display: false`), non-turn-triggering (`triggerTurn: false`) custom message in the child's
message array. The parent pays only the `Skill` object reference. Body is read fresh from disk with
frontmatter stripped (`extensibility/skills.ts:487-488`) and rendered through the `autoload`
template — which per `:502-511` deliberately does **not** claim the user invoked it. Grade A.

Cost tier: **`per-spawn`**, on the child. Two caveats:

- The skill must be findable **by name in the parent's resolved skill set**
  (`structured-subagent.ts:368`, `.find(s => s.name === name)`). A name that doesn't resolve is
  dropped by `.filter(s => s !== undefined)` — **silently, no warning** (silent degradation #9).
  A typo in `autoloadSkills:` produces a worker with no knowledge and no error.
- Autoloading a skill does **not** remove it from the persistent `<skills>` listing, so a
  worker that autoloads N skills pays for the listing *and* the N bodies.

### 2i. `WATCHDOG` — an entire discovery root

`collectConfigCandidates` (`advisor/watchdog.ts:53-121`) is a **separate search path** that
touches the capability registry not at all.

Search set, for each requested filename `<F>`:
1. `<agentDir>/<F>` (user level; `getAgentDir()` = active profile's agent dir).
2. Walking from `cwd` up to `repoRoot ?? home`: **both** `<dir>/.omp/<F>` **and** `<dir>/<F>`
   (`:83-84`). So a bare `WATCHDOG.md` at the repo root is discovered.
3. Filter (`:101`): kept when user-level, OR the owning dir's basename does not start with `.`, OR
   the file sat in a `.omp/`. Sorted user-first, then project by **depth descending** so the leaf
   directory is last/most prominent (`:115-118`).

Two filenames sets, two consumers:

| File | Consumer | What it becomes | Evidence |
|---|---|---|---|
| `WATCHDOG.md` | `discoverWatchdogFiles` | each file wrapped as `Especially pay attention to:\n<attention>…</attention>`, `@import`-expanded, joined `\n\n`, appended to **every advisor's** system prompt | `watchdog.ts:127-135`; `sdk.ts:1308`, `:3358-3362` |
| `WATCHDOG.yml` / `.yaml` | `discoverAdvisorConfigs` | the **advisor roster**: `advisors[]` with `name`, `model`, `tools`, `instructions`, `enabled`; plus top-level `instructions` as shared baseline | `advisor/config.ts:137-184`; `sdk.ts:1310` |

**What `WATCHDOG.yml` can grant — this is the part missing from our tables.** Per
`advisor/config.ts:20-29` and its doc comment `:10-19`:

- `model`: a full model selector with an optional `:level` thinking suffix
  (e.g. `x-ai/grok-code-fast:high`), resolved like any other model override.
- `tools`: **any subset of `BUILTIN_TOOL_NAMES`, explicitly including mutating tools —
  `edit`, `write`, `bash`.** The comment is unambiguous: *"the advisor is a full agent."*
  `filterAdvisorTools` (`:117-127`) only drops *unknown* names, with a warn. Omitted → default
  `read`/`grep`/`glob`; explicit `[]` → no tools.
- `instructions`: `@import`-expanded specialization text.
- Advisors are keyed by `slugifyAdvisorName` (`:71-77`); a more-specific file **replaces** an
  earlier same-slug entry. Top-level `instructions` across all files **concatenate**.
- A malformed file is logged and skipped, never thrown (`:146-158`) — so a broken `WATCHDOG.yml`
  degrades to "no advisors" silently.

So `WATCHDOG.yml` is a second, undocumented-in-our-spec agent-definition surface that can mint a
parallel agent with `bash`+`write` on any model, discovered by an ancestor walk that also accepts
bare (non-`.omp/`) filenames. Grade A.

**What it costs.** The gating chain, all of which must pass:

1. `advisor.enabled` — **default `false`** (`config/settings-schema.ts:447-457`).
2. `#buildAdvisorRuntime` returns early unless enabled (`session/session-advisors.ts:660`).
3. For a subagent: also requires `advisor.subagents` — **default `false`**
   (`settings-schema.ts:469-478`; check at `session-advisors.ts:656`).
4. A model must resolve for the `advisor` role (default role `slow`,
   `config/model-resolver.ts:983`), else status `no_model` and the advisor is inactive
   (`session-advisors.ts:592-601`).

**But discovery is unconditional.** `sdk.ts:1308-1311` fires both
`discoverWatchdogFiles` and `discoverAdvisorConfigs` on **every** session start, before any
enablement check. Cost when disabled: the filesystem walk only (a handful of `Bun.file().text()`
probes per ancestor level × 3 filenames), **zero tokens**. Cost when enabled: a full parallel
agent session per advisor per primary turn — `persistent` in the worst sense, plus
`advisor.syncBacklog` can **pause the main agent for up to 30s** (`settings-schema.ts:480-491`;
`session-advisors.ts:342-345`).

#### SILENT DEGRADATION #10 — `WATCHDOG.*` is inert by default

A committed `WATCHDOG.yml` declaring three advisors is discovered, parsed, schema-validated, and
then never built, because `advisor.enabled` defaults to `false`. The status surface shows nothing
because no runtime exists to report. Reviewers reading the repo will assume it is active. Grade A.

## 3. Transferable to omp-custom

This repo *is* the runtime, so "transferable" here means: which of its mechanisms should our
template actually attach to, given everything above.

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| Non-empty `.omp/` invariant | our repo layout must ensure `cwd/.omp` is never empty at ship time | `zero` | **ADOPT** | `ifNonEmptyDir` (`builtin.ts:46-56`) makes an empty `.omp/` invisible to 11 of 21 paths. A `.gitkeep`-only `.omp/` is not enough — `readDirEntries` counts entries, so one real file suffices, but the risk is a consumer deleting the last file. |
| `RULES.md` as our standing-instruction carrier | `.omp/RULES.md` at repo root | `persistent` (every turn, full body) | **ADOPT** | Only file that is force-`alwaysApply` regardless of frontmatter (`builtin.ts:416-418`) and ancestor-walked. The one guaranteed-rendered project surface. Keep it small — it re-enters context every turn. |
| `.omp/rules/*.md` rulebook entries | `rules` capability, rulebook bucket | `persistent` for the one-line listing, `lazy` for the body via `rule://` | **ADOPT** | The cheapest way to expose per-domain guidance. Requires `description` — see the fourth-bucket trap. |
| `.omp/agents/*.md` for our 4 workers | `task/discovery.ts:80-91` | `per-spawn` | **ADOPT** (already the plan) | Nearest-`.omp/agents`-**directory** walk-up. Highest precedence of all agent sources; only `.omp` source is accepted (`TASK_AGENT_CONFIG_SOURCE`, `task/discovery.ts:31, :74, :81`). |
| `.omp/commands/*.md` for our commands | `slash-commands`, cwd-only | `lazy` (body enters only on invocation) | **ADOPT** (already the plan) | Note it is **cwd-only** — running `omp` from a subdirectory loses every command. See §5. |
| `autoloadSkills:` on worker agents | `helpers.ts:307`, injected `executor.ts:3234-3248` | `per-spawn`, **charged to the child** | **ADAPT** | Correct mechanism for giving a worker its playbook without paying for it in the parent. But a name typo is silently dropped — pair each use with a test that asserts the child's first message count. |
| `disabledProviders` to fence off foreign inputs | `.omp/settings.json` → `disabledProviders: [...]` (`settings-schema.ts:529`, consumed `capability/index.ts:285-288`) | `zero` | **ADOPT** | The only lever that shuts off all 13 foreign providers. Cheapest single defense against silent degradation from a dev's `~/.claude` or `~/.agents`. |
| `magicKeywords.orchestrate: false` (and `.workflow`) | `.omp/settings.json` | `zero` | **ADOPT** | ~1.4k and ~2.4k hidden tokens on an accidental prose match, injecting a contract that fights our worker prompts. Keep `ultrathink` — 129 bytes and a genuinely useful effort escalation. |
| `interruptMode` / `condition` / `scope` TTSR rules | `.omp/rules/*.md` with `condition:` | `per-action` (fires mid-stream) | **DEFER** | Trigger: only after we have a *measured* failure mode a regex can catch. The glob-shorthand rewrite (§2e #4) and the `alwaysApply`-eating precedence (#5) make hand-authored TTSR rules easy to get silently wrong. Test via `cli/ttsr-cli.ts` before shipping any. |
| `WATCHDOG.yml` advisor roster | `advisor/config.ts:137` | `zero` while `advisor.enabled=false`; `persistent`+ once enabled | **REJECT** for now | Two default-false settings stand between the file and any effect, and it is a second agent-definition surface competing with `.omp/agents/`. If we ever want it, it must ship together with `advisor.enabled: true` in the same `settings.json` or it is decoration. |
| `.omp/instructions/` + `applyTo` | none | — | **REJECT** | No runtime consumer (§2f). This is `.omp/policies/` with a different name. |
| `@import` in context files | `.omp/AGENTS.md` | `persistent` (expanded inline) | **ADAPT** | Works only in `AGENTS.md`-family files and `WATCHDOG.*`. Useful for sharing one block between root `AGENTS.md` and `.omp/AGENTS.md`; useless in rules/skills/commands. Depth 5, silent on miss. |
| `SYSTEM.md` wholesale replacement | `.omp/SYSTEM.md` via the CLI path | `persistent`, and **removes** ~200 lines of default prompt | **REJECT** | Replacing block 0 deletes the tool policy, delegation gates, execution workflow, and delivery contract (§2c). Anything we want added belongs in `APPEND_SYSTEM.md` or `RULES.md`. |
| `APPEND_SYSTEM.md` | `.omp/APPEND_SYSTEM.md`, `main.ts:860-871` | `persistent` | **ADAPT** | Additive, renders at `project-prompt.md:59-61` (and `custom-system-prompt.md:5-7`). Safer than `SYSTEM.md`. cwd-only, and falls through to `.claude/APPEND_SYSTEM.md`. |

## 4. What this repo does that we deliberately will not

- **Ship a large skill library.** Every skill any of the nine skill providers finds occupies a
  persistent line in `<skills>` (`system-prompt.md:27-33`), and the block is inherited by every
  subagent because the subagent template is spliced, not substituted (`executor.ts:3038-3040`).
  This confirms the ~10-skill cap already in memory. The cost is `persistent × (1 + spawns)`.
- **Use `.omp/instructions/`, or any capability with no `loadCapability` call site.** The filter is
  mechanical: grep for the capability id being *loaded*, not *registered*. Registration proves a
  parser exists; loading proves a consumer exists.
- **Author TTSR rules speculatively.** Five distinct silent-failure modes (fourth bucket, glob
  shorthand, `alwaysApply` precedence, `interruptMode` typo → `undefined`, condition regex compile
  failure) and no warning on any of them. `docs/rulebook-matching-pipeline.md:321` records that
  discovery warnings are produced but *not surfaced* by `createAgentSession`.
- **Rely on `includeWorkspaceTree`.** Default `false` (`settings-schema.ts:1242-1252`) and the
  setting's own description warns it busts prompt caching. Consequence we should record: when it is
  `false`, `workspaceTree.agentsMdFiles` is empty (`system-prompt.ts:696-700` returns a stub), so
  **the `<dir-context>` "you MUST read these nested AGENTS.md" block (`project-prompt.md:20-26`)
  never renders.** Nested `AGENTS.md` files below cwd are not advertised at all by default. Grade A.
- **Depend on any cwd-only path from a subdirectory.** 11 of 21 `.omp/` paths — including
  `commands/`, `rules/`, `settings.json`, `hooks/`, `tools/` — resolve to exactly `cwd/.omp`. Our
  template must either document "run from repo root" or accept that half of it disappears.
- **Reproduce the `orchestrate` contract in our own prompts.** It is already one lowercase word away
  at all times, and it is internally inconsistent with the subagent prompt it lands beside.

## 5. Contradictions with our current spec or registry

I did not open `spec/00-16`, `spec/key/*`, or `registry/*` this pass — the contract forbids editing
them and my assignment is this one report. So these are stated as **claims to check**, each with the
evidence that would falsify a common formulation. Where a recorded fact already exists in memory I
have flagged it.

1. **"Only `skills/`, `AGENTS.md`, `RULES.md`, `SYSTEM.md` walk ancestors."** — Verified **correct
   for the `native` provider's capability paths**, but **incomplete as a statement about `.omp/`**.
   Three more `.omp/`-rooted things walk ancestors through *different* code:
   `.omp/agents/*.md` (`task/discovery.ts:80`, via `findAllNearestProjectConfigDirs`),
   `.omp/plugins/installed_plugins.json` (`helpers.ts:821-855`), and
   `.omp/WATCHDOG.{md,yml,yaml}` (`advisor/watchdog.ts:79-90`). If a table says "these four and
   nothing else," it is wrong about our own worker-agent directory — which matters, because it means
   `.omp/agents/` **does** survive being launched from a subdirectory while `.omp/commands/` does not.

2. **Any claim that `.omp/mcp.json` requires a non-empty `.omp/`.** False.
   `loadMCPServers` builds its path list directly (`builtin.ts:206-211`) and never calls
   `getConfigDirs`/`ifNonEmptyDir`. MCP is the one capability that reads through an otherwise-empty
   `.omp/`.

3. **Any claim that `SYSTEM.md` "adds to" or "customizes" the system prompt.** It *replaces* block 0
   with a 65-line template (`system-prompt.ts:899`, `custom-system-prompt.md`), and only via the CLI
   `main.ts:846-858` path. The capability-provider path for `SYSTEM.md` (`builtin.ts:242-271`) has
   **no rendering site at all** (§2c, silent degradation #1). Any spec row that lists
   `.omp/SYSTEM.md` as "custom system prompt (additive)" is wrong in both directions.

4. **Any claim that the subagent gets a different/minimal prompt.** It gets the *whole* default
   prompt plus its own template spliced second-to-last (`executor.ts:3038-3040`). The only
   subtractions are `personality → "none"` (`sdk.ts:2947`) and `AGENTS.md`-basename context files
   (`structured-subagent.ts:433`). `CLAUDE.md` and `GEMINI.md` bodies are **not** filtered.

5. **The `~14 foreign providers` figure.** Confirmed: 13 read non-`.omp` paths, 14 counting
   `mcp-json`. The list in §2b is complete against `discovery/index.ts:23-39`. If a registry row
   omits `agents` (`.agent`/`.agents`, **which reads `SYSTEM.md` with an ancestor walk and reaches
   the Windows host profile under WSL**) or `claude-plugins` (marketplace cache), it understates the
   unmanaged surface in the two most dangerous places.

6. **Memory record "OMP skill-listing cost multiplier — every subagent pays for the full skill
   listing."** Re-verified at this SHA. Mechanism confirmed at `executor.ts:3038-3040` +
   `system-prompt.md:27-33` + `structured-subagent.ts:434`. No change needed.

7. **`WATCHDOG.*` as a missing discovery root.** Confirmed missing-if-absent from our tables, and it
   is not one root but **two filename families with two different consumers and two different
   grants** (attention text vs. a full advisor roster with `bash`/`write`). It also accepts **bare
   `WATCHDOG.md` outside `.omp/`** (`watchdog.ts:84`), which no other OMP-native surface does.

## 6. Cost profile

Per rule 5 — where the token is actually paid.

| §3 row | Tier | Number / basis |
|---|---|---|
| Non-empty `.omp/` invariant | `zero` | filesystem only |
| `.omp/RULES.md` | `persistent` | full body, every turn, inside `<generic-rules>`. Budget it like a system-prompt section, not a doc. |
| `.omp/rules/*.md` rulebook | `persistent` + `lazy` | listing line is `- <name> (<globs>): <description>` (`system-prompt.md:47`) ≈ 15–30 tok/rule. Body only on `rule://<name>`. |
| `.omp/agents/*.md` | `per-spawn` | agent `systemPrompt` renders into `{{agent}}` at `subagent-system-prompt.md:4`. Parent pays nothing. |
| `.omp/commands/*.md` | `lazy` | body enters only on `/name` invocation. Description string appears in the TUI command list, **not** in the model's prompt. |
| `autoloadSkills` | `per-spawn`, on the **child** | one hidden message per skill, `display:false`/`triggerTurn:false` (`executor.ts:3239-3246`); body = `SKILL.md` minus frontmatter (`skills.ts:487-488`). |
| Skill listing | `persistent × (1 + concurrent spawns)` | `- {{name}}: {{description}}` per skill (`system-prompt.md:31`). ~20–40 tok each; ×N spawns. |
| `disabledProviders` | `zero` | a JSON array in `settings.json`; also *saves* whatever the foreign providers would have contributed |
| `magicKeywords.*: false` | `zero` | saves ~1.4k tok (`orchestrate`) / ~2.4k tok (`workflowz`) per triggering turn. Byte counts measured: 5539 B and 9538 B; token figures are **estimates** at 4 B/tok. |
| TTSR rule | `per-action` | zero until it fires; on fire, injects a warning and (default `interruptMode: always`) **interrupts the stream**, discarding partial output (`ttsr.contextMode` default `discard`, `settings-schema.ts:3087-3097`) |
| `WATCHDOG.md`/`.yml` while `advisor.enabled=false` | `zero` | discovered every session start (`sdk.ts:1308-1311`) but never rendered |
| `WATCHDOG.yml` with `advisor.enabled=true` | `persistent`, unbounded | one full parallel agent session per advisor, fed every completed primary turn (`session-advisors.ts:327-345`); `advisor.syncBacklog` can block the main agent 30s |
| `APPEND_SYSTEM.md` | `persistent` | appended verbatim at `project-prompt.md:59-61` |
| `includeWorkspaceTree: true` | `persistent` + cache-busting | its own setting description warns it "can bust prompt caching across sessions when files are modified" (`settings-schema.ts:1249-1250`) |

## 7. Coverage and limits

**Files read in full:**
`discovery/builtin.ts` (945), `discovery/helpers.ts` (1169), `discovery/agents.ts` (300),
`discovery/agents-md.ts` (67), `discovery/at-imports.ts` (273), `capability/rule.ts` (299),
`capability/rule-buckets.ts` (66), `capability/instruction.ts` (35), `advisor/watchdog.ts` (136),
`advisor/config.ts` (342), `config/prompt-templates.ts` (206), `task/discovery.ts:1-140`,
`prompts/system/system-prompt.md` (263), `prompts/system/subagent-system-prompt.md` (73),
`prompts/system/custom-system-prompt.md` (65), `prompts/system/project-prompt.md` (61),
`prompts/system/orchestrate-notice.md` (40), `prompts/system/ultrathink-notice.md` (3),
`modes/ultrathink.ts`, `modes/orchestrate.ts`, `modes/workflow.ts`,
`modes/magic-keyword-boundary.ts`, `docs/rulebook-matching-pipeline.md` (322), `LICENSE:1-20`.

**Files sampled (grep / targeted section reads only):**
`system-prompt.ts` (read `:300-420`, `:540-560`, `:610-700`, `:700-921`; **not** `:1-300` in full),
`sdk.ts` (read `:1280-1320`, `:1560-1600`, `:1700-1745`, `:2880-2980`, `:3350-3400`; ~3400 lines
unread), `task/executor.ts` (read `:2980-3110`, `:3200-3270`; ~3400 lines unread),
`task/structured-subagent.ts` (read `:340-450`), `session/agent-session.ts` (read `:4850-4935`,
grep elsewhere; ~9000 lines unread), `session/session-advisors.ts` (read `:570-670`, grep
elsewhere), `config/settings-schema.ts` (read the advisor / ttsr / magicKeywords / skills /
workspace-tree blocks; ~5800 lines unread), `config.ts:1-235`, `capability/fs.ts:37-77`,
`capability/index.ts` (grep only — **priority/dedup logic not read in full**),
`extensibility/skills.ts` (read `:482-522`, grep elsewhere), `extensibility/slash-commands.ts:40-110`,
`main.ts:835-895` + greps, `discovery/{claude,claude-plugins,codex,cursor,gemini,opencode,windsurf,cline,github,vscode,mcp-json,ssh,omp-plugins,omp-extension-roots}.ts`
(headers, path literals, and `registerProvider` blocks only — **no full read of any of the 14**),
`crates/pi-walker/src/lib.rs:3030-3130`, `crates/pi-natives/src/glob.rs:180-215`.

**Not opened:**
- `export/ttsr.ts` — **`TtsrManager.addRule` is the exact acceptance predicate for the TTSR bucket
  and I did not read it.** Everything in §2e about *which* rules TTSR accepts rests on
  `rule-buckets.ts:54` plus `docs/rulebook-matching-pipeline.md:222`. A rule with a `condition` that
  `addRule` *rejects* falls through to always-apply/rulebook, and I cannot state the rejection
  criteria.
- `cli/ttsr-cli.ts` beyond `:277-292` — I claim it is a usable test oracle without having read its
  output format.
- `capability/index.ts` `loadCapability` internals: the merge/dedup/`_shadowed` implementation. I
  took first-wins-by-priority from `docs/rulebook-matching-pipeline.md:176-193` (Grade B), not from
  the code.
- `modes/markdown-prose.ts` — `keywordInProse`. The "never inside code/XML" claim is from the
  doc-comments in `modes/{ultrathink,orchestrate,workflow}.ts`, not from reading the implementation.
  Grade B on that one clause.
- `discovery/builtin-rules/*` bodies (21 bundled TTSR rules). I counted them and read none. What
  the default `ttsr.builtinRules: true` actually injects into our sessions is **unassessed**.
- `discovery/substitute-plugin-root.ts`, `discovery/plugin-dir-roots.ts`.
- `prompts/system/workflow-notice.md` — I measured it (112 lines / 9538 B) but did **not** read it.
  The `workflowz` row's description ("steers toward a deterministic multi-subagent workflow") is from
  `modes/workflow.ts:13-14`'s doc comment, Grade B.
- `prompts/advisor/system.md` (98 lines) — the advisor's own baseline prompt. Measured, unread.
- `docs/context-files.md`, `docs/advisor-watchdog.md`, `docs/settings.md`,
  `docs/extension-loading.md`.
- Every test file except two grep hits in `test/discovery/github-copilot.test.ts`.
- `spec/00-16`, `spec/key/*`, `registry/*` in our own repo — hence §5 is framed as claims-to-check.

**Claims that need a live run before use:**
- **Silent degradation #1** (`SYSTEM.md` via the capability path never renders). The code path is
  unambiguous but the conclusion is negative — proving it needs one session with a
  `.omp/SYSTEM.md` present, `--system-prompt` absent, and a dump of `session.systemPrompt`.
  Currently **Grade D on the runtime consequence**, A on the code.
- Exact token counts for `orchestrate-notice.md` and `workflow-notice.md`. Byte counts are measured;
  token counts are 4-B/tok estimates.
- Whether `.omp/agents/` genuinely survives a subdirectory launch while `.omp/commands/` does not
  (the asymmetry in §5 item 1). Two different walk helpers; I read both but have not run either.
- The `TtsrManager.addRule` acceptance criteria (see above).

**Suspected but not verified:**
- `.omp/prompts/*.md` appears to be loaded **twice** by two independent code paths with different
  recursion: the `prompts` capability (`builtin.ts:430-450`, non-recursive, `*.md`) and
  `loadPromptTemplates` (`config/prompt-templates.ts:165-181`, **recursive** `**/*`). The
  `promptCapability` result has no production `loadCapability` call site that I found — same shape as
  the `instructions` defect — while `loadPromptTemplates` is the one actually wired into
  `session.promptTemplates` (`sdk.ts:1312-1315`, `:3394`). If so, `prompts` is a **second inert
  capability** and only the recursive loader matters. I grepped both but did not trace
  `promptCapability` consumers exhaustively enough to assert it. **Worth one follow-up grep.**
- `getConfigDirs` in `config.ts` (used by `.omp/agents/`, `SYSTEM.md`, `APPEND_SYSTEM.md`,
  `TITLE_SYSTEM.md`) falls through `.omp` → `.claude` → `.codex` → `.gemini`
  (`config.ts:9-13`). I read the base list and `findConfigFile`'s loop, so the fall-through is
  Grade A, but I have not confirmed no caller filters the source except
  `task/discovery.ts:74, :81` (which does, to `.omp` only).
- `scanSkillsFromDir` follows symlinked skill directories (`helpers.ts:418`
  `!entry.isDirectory() && !entry.isSymbolicLink()`) while the native glob used elsewhere is
  `follow_links(Never)` (`crates/pi-natives/src/glob.rs:194`). A symlinked skill dir is discovered;
  a symlinked `rules/` or `commands/` dir probably is not. Untested.
- `loadFilesFromDir` passes `gitignore: true, hidden: false` to the native glob
  (`helpers.ts:499-505`). Since `.omp/` is itself a dot-directory but is the glob *root*, its
  contents should be visible — but **a gitignored file inside `.omp/` (e.g. a local override we tell
  users to gitignore) would be skipped** for `rules/`, `commands/`, `prompts/`, `tools/`,
  `instructions/`. The walker does strip ancestor ignore rules that cover the explicit root
  (`crates/pi-walker/src/lib.rs:3056-3094`, `load_gitignore` with `explicit_root`), which suggests
  a `.gitignore` line matching `.omp/` itself is neutralized — but a line matching a *file inside*
  `.omp/` is not. This is a plausible silent-degradation source I could not confirm without a run.
  **Grade D.**






