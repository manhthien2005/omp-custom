# Dossier — oh-my-pi (OMP runtime)

> Authority boundary: This dossier is source/research evidence.
> Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology,
> dispatch, review mechanism, or capability behavior.
> Current design and execution authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.

> Upstream commit: `3a8591a8af5b6d200088d12ca75a5517cb064fa8` (2026-08-06) | Verified by source reading at `_research/upstreams/oh-my-pi`
> **All `file:line` citations below are relative to `packages/coding-agent/src/`** unless the path starts with `packages/`.
> Claims carried over from `spec/02` that I did **not** re-read this pass are tagged `[spec-carried]`. Unverified items are in §11, not asserted here.

---

## 1. Discovery surface (path → capability → file:line)

Authoritative provider: `discovery/builtin.ts` (PROVIDER_ID `"native"`, priority 100 — `builtin.ts:39-43`).

| Path under a `.omp/` dir | Capability | file:line | Ancestor walk? |
|---|---|---|---|
| `mcp.json`, `.mcp.json` | MCP servers | `builtin.ts:206-211` | no |
| `SYSTEM.md` | **custom system prompt** | `builtin.ts:245`, `:258` | **yes** (nearest project dir) |
| `skills/<name>/SKILL.md` | Skill | `builtin.ts:284-291` (project), `:296` (user) | **yes** (every ancestor) |
| `commands/*.md` | SlashCommand | `builtin.ts:345-355` | no |
| `rules/*.{md,mdc}` | Rule | `builtin.ts:377-381` | no |
| `RULES.md` | Rule, `alwaysApply` **forced** | `builtin.ts:392-418` (force at `:416-418`) | **yes** |
| `prompts/*.md` | Prompt | `builtin.ts:435-443` | no |
| `extensions/` (dir or `*.ts`/`*.js`) | ExtensionModule | `builtin.ts:483`, resolver `helpers.ts:619-699` | no |
| `settings.json` → `extensions: [...]` | ExtensionModule paths | `builtin.ts:484`, `:506-520` | no |
| `extensions/<n>/gemini-extension.json` | Extension (manifest) | `builtin.ts:587-621` | no |
| `instructions/*.md` (+ `applyTo`) | Instruction | `builtin.ts:642-654` | no |
| `hooks/{pre,post}/<tool>.<ext>` | Hook | `builtin.ts:676`, `:687`, `:700-716` | no |
| `tools/*.{json,md,ts,js,sh,bash,py}` | CustomTool | `builtin.ts:750-796` | no |
| `tools/<name>/index.ts` | CustomTool | `builtin.ts:804`, `:821-833` | no |
| `settings.json` | Settings | `builtin.ts:863-877` | no |
| `config.yml` | Settings (YAML) | `builtin.ts:879-891` | no |
| `AGENTS.md` | ContextFile | `builtin.ts:910` (user), `:923` (project, carries `depth`) | **yes** |
| `agents/*.md` | AgentDefinition | `task/discovery.ts:42-58`, `:80-91` | nearest only |

Three structural facts the spec does not record:

1. **An empty `.omp/` directory is invisible.** `ifNonEmptyDir` returns `null` when `readDirEntries` is empty (`builtin.ts:46-56`), and `getConfigDirs` gates everything on it (`builtin.ts:58-73`).
2. **Most surfaces do NOT walk up.** `getConfigDirs` resolves exactly `cwd/.omp` + the user profile dir (`builtin.ts:61-71`). Only `skills/` (`:284`), `AGENTS.md`, `RULES.md`, `SYSTEM.md` (via `findNearestProjectConfigDir`, `builtin.ts:90-99`) search ancestors. Running `omp` from a subdirectory of the repo silently loses `commands/`, `rules/`, `prompts/`, `hooks/`, `tools/`, `extensions/`, `settings.json`, `config.yml`.
3. **User native config is profile-scoped**, `getAgentDir()` = `~/.omp/profiles/<name>/agent` (`builtin.ts:65-68`, `helpers.ts:95`).

Skill gates: `enabled: false` in frontmatter drops the skill (`helpers.ts:387-389`); a **missing `description` silently drops it** because every native scan passes `requireDescription: true` (`builtin.ts:290`, gate at `helpers.ts:390-392`); `name` falls back to the directory basename (`helpers.ts:393-395`). Auto-learn managed skills are a separate provider at priority 5 so any authored skill of the same name wins (`builtin.ts:309-337`).

Agent precedence, first-name-wins dedup: project `.omp/agents` → user → OMP extension roots → Claude marketplace plugins → bundled (`task/discovery.ts:87-133`). Loading is unconditional for every `.md` in the dir (`task/discovery.ts:42-58`), so any file parked in `agents/` is a live spawnable agent.

---

## 2. Agent frontmatter contract

Interface `ParsedAgentFields` (`discovery/helpers.ts:234-247`); parser `parseAgentFields` (`helpers.ts:253-323`). Keys are normalized kebab→camel upstream in `packages/utils/src/frontmatter.ts` `[spec-carried]`.

| Key | Type / parse | file:line | Notes |
|---|---|---|---|
| `name` | string, **required** | `helpers.ts:254`, `:257-259` | missing ⇒ whole file skipped |
| `description` | string, **required** | `helpers.ts:255`, `:257-259` | same |
| `tools` | array or CSV → `normalizeToolNames` | `helpers.ts:261-262` | legacy aliases `search`→`grep`, `find`→`glob` (`tools/builtin-names.ts`) |
| `spawns` | `"*"` \| array \| CSV | `helpers.ts:270-282` | |
| `model` | array or CSV of patterns | `helpers.ts:298` | |
| `output` | passthrough (`unknown`) | `helpers.ts:289` | the frontmatter output schema |
| `thinkingLevel` / `thinking` | `ConfiguredThinkingLevel` | `helpers.ts:290-297` | either spelling |
| `blocking` | boolean | `helpers.ts:299` | see §4 — decides sync vs detached |
| `readSummarize` | boolean | `helpers.ts:300` | `false` ⇒ subagent gets `read.summarize.enabled: false` (`task/executor.ts:2648`) |
| `prewalk` | boolean \| model-pattern string | `helpers.ts:302-306` | |
| `autoloadSkills` | array or CSV | `helpers.ts:307-309` | |

**That list is exhaustive.** There is no `isolated`, `effort`, `maxRuntimeMs`, `softRequestBudget`, `outputSchema`, `schemaMode`, `enableLsp`, or `concurrency` frontmatter key — those are call-site or settings-level only.

Two rewrites with consequences:
- `yield` is force-appended to any explicit `tools` list (`helpers.ts:265-267`).
- `tools` containing `task` implies `spawns: "*"` when `spawns` is absent (`helpers.ts:285-287`).

Two more the executor adds at spawn time, invisible in the frontmatter:
- **`hub` is force-appended to every subagent tool list** unless the session is a restricted one (`task/executor.ts:2691-2694`). Every omp-custom worker therefore has agent-to-agent messaging whether the spec wants it or not.
- If `spawns` is defined but `task` is absent from `tools`, `task` is **added** (unless at max depth) (`task/executor.ts:2676-2681`); at max depth `task` is **stripped** (`:2683-2685`). `exec` expands to `eval` + `bash` (`:2695-2701`).

**`spawns` semantics (`task/spawn-policy.ts:19-64`)**: `false`/empty ⇒ `enabled: false`; `true`/`null`/`undefined`/`"*"` ⇒ unrestricted with default agent `task`; otherwise **`allowedAgents[0]` becomes the default agent for calls that omit `agent`** (`spawn-policy.ts:52-59`). The order of a `spawns:` list is therefore semantically load-bearing.

**Read-only classification (`task/read-only-policy.ts`)**: an agent is read-only iff `tools` is a non-empty subset of `{read, grep, glob, web_search, ast_grep, yield, hub, ask, todo, recall, reflect, retain, memory_edit, inspect_image, checkpoint, rewind}`. Unknown tool ⇒ not read-only (fail-safe).

---

## 3. Command / slash-command frontmatter contract

Verified: the native loader stores only `name` (filename minus `.md`), `path`, `content`, `level` — **it does not parse frontmatter at all** (`builtin.ts:346-355`). Whatever frontmatter keys commands support (`allowed-tools`, `argument-hint`, `model`, …) are consumed downstream in the slash-command layer, which I did not read. See §11 — do not design command frontmatter against this dossier.

Related verified setting: `skills.enableSkillCommands` default `true` registers every skill as `/skill:<name>` (`config/settings-schema.ts:4779-4788`).

---

## 4. Task tool wire format

Schemas in `task/types.ts`; builder `createTaskSchema` (`types.ts:195-257`), selector `getTaskSchema` (`types.ts:260-278`).

**`task.batch` defaults to `true`** (`config/settings-schema.ts:4570-4580`). The shape the model actually sees under defaults is therefore:

```
{ context: string,            // REQUIRED (types.ts:167-171)
  tasks: [ { name?, agent = 'task', task, effort?, outputSchema?, schemaMode?, isolated? } ] }
```

- `agent` carries a schema-level default of the spawn policy's default agent (`types.ts:187-193`, `:201`).
- `isolated?` exists **only when `task.isolation.mode !== "none"`** (`types.ts:122-130`, `:236-247`; gate at `task/index.ts:570`).
- `effort?` exists **only when `task.enableEffort` is true** — default `false` (`types.ts:202`, `settings-schema.ts:4582-4592`).
- `outputSchema` accepts `object | boolean | string | null` (`types.ts:110`).
- Flat form `{name?, agent, task, …}` remains valid at runtime for internal callers and stale transcripts (`types.ts:285-305`), but is rejected model-side when batch is on; a stale `schema` field gets an explicit error (`task/index.ts:192-202`).

**Concurrency**: one `Semaphore` per `TaskTool` instance (per session), resized to `task.maxConcurrency` on each call (`task/index.ts:560-624`); default **32** (`settings-schema.ts:4594-4613`), `0` = unlimited.

**Blocking vs detached**: spawns are partitioned by the agent definition's `blocking` flag — `blocking: true` runs inline and the parent waits; everything else runs as a detached background job (`task/index.ts:707-710`, `:820-833`, `:853-854`, `:972-974`).

**Recursion depth — spec OQ-3 is now closed.** `maxRecursionDepth = settings.get("task.maxRecursionDepth") ?? 2` (`executor.ts:2656`); `parentDepth = options.taskDepth ?? 0`, `childDepth = parentDepth + 1`, `atMaxDepth = maxRecursionDepth >= 0 && childDepth >= maxRecursionDepth` (`executor.ts:2670-2672`). With the default `2`: main session is depth 0 → its child is depth 1 (**keeps `task`**) → grandchild is depth 2 (**`task` stripped**, `:2683-2685`). So the default permits **two** levels of subagents below the main session, not one. `maxRecursionDepth < 0` disables the cap (`types.ts:330-332`).

**Isolation**: `task.isolation.mode` default `"none"`, enum `none|auto|apfs|btrfs|zfs|reflink|overlayfs|projfs|block-clone|rcopy`; `"auto"` = native PAL picks (`settings-schema.ts:4449-4495`). Windows backends are `projfs` and `block-clone` (`:4482-4487`), `rcopy` = git worktree else recursive copy (`:4489-4492`). `task.isolation.apply` default `true` (`:4497-4507`), `merge` `patch|branch` default `patch` (`:4509-4523`), `commits` `generic|ai` (`:4525-4539`), worktree root `worktree.base` / `OMP_WORKTREE_DIR` / `~/.omp/wt` (`:4541-4551`). An isolated spawn gets `workspace.additionalDirectories: []` (`executor.ts:2647-2650`).

**Per-subagent budgets**: `task.maxRuntimeMs` default `0` = unlimited (`settings-schema.ts:4645-4662`); `task.softRequestBudget` default 200 — crossing it injects one wrap-up notice, **1.5× forces a stop and a partial yield** (`:4676-4692`, notice toggle `:4694-4704`); `task.agentIdleTtlMs` default 420 000 parks idle agents to disk (`:4664-4674`, read at `executor.ts:2662`). Output caps: `MAX_OUTPUT_BYTES` 500 000 (`PI_TASK_MAX_OUTPUT_BYTES`) and `MAX_OUTPUT_LINES` 5 000 (`types.ts:53-56`).

**Result telemetry per spawn** (`types.ts:471-539`): `tokens` (input+output+cacheWrite, excludes cacheRead), `requests`, `contextTokens`, `contextWindow`, `cost`, `usage`, `durationMs`, `structuredOutput`, `patchPath`/`branchName`/`branchBaseSha`, `outputMeta`. Live equivalents stream on `AgentProgress` (`types.ts:395-469`) over EventBus channels `task:subagent:{event,progress,lifecycle}` (`types.ts:59-65`). This is a ready-made token-per-outcome accounting surface.

---

## 5. Structured output / yield enforcement

Schema selection has three sources, tracked explicitly: `"caller" | "agent" | "session" | "none"` (`types.ts:20`), with `outputSchemaOverridesAgent` recorded when the call site wins (`executor.ts:384`). Mode is `"permissive" | "strict"` (`types.ts:14-17`).

Post-mortem validation lives in `finalizeSubprocessOutput` (`executor.ts:598-700`):
- Yields are assembled, then validated by `buildOutputValidator(outputSchema)` (`executor.ts:619-625`).
- **Rejection rule (spec §D is incomplete here):** `mustReject = failure !== undefined && (mode === "strict" || (!assembled.schemaOverridden && !schemaError))`. So in **permissive** mode an invalid payload is still turned into a `schema_violation` with `exitCode 1` unless the in-tool retry budget was exhausted (`schemaOverridden`) or the schema itself was malformed. Permissive is *not* "always accept after 3 tries" — it is "accept only the retry-exhausted override".
- Strict rejects even the retry-exhausted override (`types.ts:14-17`).
- With no yield at all, a fallback parse of raw output is attempted only when the run exited cleanly (`executor.ts:678-682`).
- `structuredOutput.status` ∈ `valid | invalid | unavailable`, and `unavailable` is what a malformed schema produces (`types.ts:23`, `executor.ts:640-660`).
- A malformed `outputSchema` degrades silently to unvalidated output — it does not fail the spawn.

The in-tool retry loop and its `MAX_SCHEMA_RETRIES = 3` live in `tools/yield.ts` `[spec-carried]` — not re-read this pass.

---

## 6. Model role resolution + config precedence

Verified this pass:
- `task.agentModelOverrides` is a `record` (agent name → model), default `{}` (`settings-schema.ts:4725-4728`) — a settings-level override of any agent's `model` frontmatter, per agent, with no file edit.
- `task.agentPrewalk` is a parallel `record` (`settings-schema.ts:4729-4732`), toggled with `P` in `/agents` (`:4741`).
- `task.disabledAgents` array kills specific agents (`settings-schema.ts:4720-4723`); consulted for `scout` at `task/spawn-policy.ts:66-77`.
- The resolved model per spawn is reported back as `modelRole` + `resolvedModel` + `resolvedModelIsFallback` (`types.ts:428-434`, `:500-505`), so misrouting is observable at the result, not silent — *if* the caller reads it.
- Settings sources are ordered project-then-user within the native provider, both `settings.json` and `config.yml` emitted as separate Settings items (`builtin.ts:862-892`); merge arbitration is in `config/settings.ts`, not read this pass.

`[spec-carried]`, not re-verified: built-in roles `default, smol, slow, vision, plan, designer, commit, tiny, task, advisor` (`config/model-roles.ts:22-32`); custom-role gate `isModelRole(candidate) || settings?.getModelRole(candidate) !== undefined` (`config/model-resolver.ts:925`); `getKnownRoleIds` folding in `settings.getModelRoles()` (`model-roles.ts:87`).

---

## 7. Skills, rules, context-file injection

**Rules** are the richest under-used surface. `buildRuleFromMarkdown` (`helpers.ts:182-221`) parses:

| Key | Effect | file:line |
|---|---|---|
| `globs` (string or array) | path-scoped activation | `helpers.ts:195-200` |
| `alwaysApply` | sticky | `helpers.ts:213` |
| `description` | | `helpers.ts:214` |
| `condition`, `astCondition`, `scope` | conditional / **AST-conditional** activation | `helpers.ts:193`, `:216-218` (parser `capability/rule.ts`) |
| `interruptMode` | `never` \| `prose-only` \| `tool-only` \| `always` | `helpers.ts:203-207` |

`.mdc` is accepted alongside `.md` (`builtin.ts:379`). `RULES.md` gets `alwaysApply: true` forced regardless of frontmatter, named `RULES@project` at project level (`builtin.ts:410-419`).

**Instructions** carry `applyTo` (`builtin.ts:646-653`) — a second path-scoped injection channel, distinct from rules.

**Skills** settings: `skills.enabled` (`settings-schema.ts:4777`), `skills.ignoredSkills` / `includeSkills` / `customDirectories` arrays (`:4804-4808`), per-source toggles for Codex/Claude/pi/AGENTS user+project scopes (`:4790-4802`).

**Context files**: project `AGENTS.md` carries `depth` (`builtin.ts:930`) and returns immediately once found — nearest wins, no concatenation up the tree (`builtin.ts:921-936`).

`.omp/SYSTEM.md` replaces the system prompt wholesale at project or user level (`builtin.ts:242-271`) and appears nowhere in `spec/01` or `spec/02`.

---

## 8. Token-relevant levers

Compaction (`config/settings-schema.ts`):

| Setting | Default | Line |
|---|---|---|
| `compaction.strategy` | **`snapcompact`** (enum `context-full|handoff|shake|snapcompact|off`) | `2164-2198` |
| `compaction.enabled` | `true` | `2142` |
| `compaction.midTurnEnabled` | `true` | `2153` |
| `compaction.thresholdPercent` | `-1` (legacy reserve-based) | `2200` |
| `compaction.thresholdTokens` | `-1` | `2225` |
| `compaction.reserveTokens` | `undefined` (deliberately unset) | `2279-2283` |
| `compaction.keepRecentTokens` | `20000` | `2285` |
| `compaction.autoContinue` | `true` | `2287` |
| `compaction.v2RetainedMessageBudget` | `64000` | `2291` |
| `compaction.supersedeReads` | `true` — prunes older reads of the same file, every turn | `2346-2355` |
| `compaction.dropUseless` | `true` — prunes no-match/timeout results once consumed | `2357-2367` |
| `compaction.idleEnabled` / `idleThresholdTokens` / `idleTimeoutSeconds` | `false` / `200000` / `300` | `2294`, `2305`, `2327` |
| `contextPromotion.enabled` | `false` (promote to bigger model instead of compacting) | `2130-2139` |

`shake` = "drop heavy content (tool results + large blocks) in place; recover via artifact" (`2181-2185`). `snapcompact` = "archive history onto dense bitmap images the model reads back; **no LLM call**" (`2186-2190`).

Read summarization (`settings-schema.ts:3258-3375`): `read.defaultLimit` 300 (`3258`); `read.summarize.enabled` **true** (`3287`); `prose` false (`3298`); `minBodyLines` 4 (`3309`); `minCommentLines` 6 (`3320`); `minTotalLines` **100** — shorter files are read verbatim (`3331`); `unfoldUntil` 50 and `unfoldLimit` 100 govern BFS unfolding of elided spans (`3342`, `3354`).

Artifact spill (`settings-schema.ts:710-800`): `tools.artifactSpillThreshold` (`710`), `artifactHeadBytes` (`754`), `artifactTailBytes` (`734`), `artifactTailLines` (`796`), `tools.outputMaxColumns` (`776`) — the mechanism that keeps huge tool output out of context and behind a URL.

Prewalk: plan on the strong model, hand off to `smol` at the first edit/write (`settings-schema.ts:4733-4743`); per-agent via `prewalk` frontmatter (`helpers.ts:302-306`) or `task.agentPrewalk`; resolution and no-op detection at `executor.ts:2920-2950` (a prewalk target equal to the current model+level is skipped).

Effort: `task.enableEffort` false by default (`4582`), ceiling `task.maxEffort` default `max` (`4706-4718`), per-spawn values `lo|med|hi` (`types.ts:112`). Thinking budgets: minimal 1024 → max 32768 (`settings-schema.ts:5574-5584`).

LSP: `lsp.enabled` true (`3378`), `lsp.lazy` true (`3389`), `lsp.shared` true (`3401`), `diagnosticsOnWrite` true (`3424`), `diagnosticsOnEdit` **false** (`3435`), `diagnosticsDeduplicate` true (`3446`), `formatOnWrite` false (`3413`). Subagent registration requires the selected allowlist, `task.enableLsp`, parent LSP enabled and not plan mode, and `lsp.enabled`; registration still does not prove an applicable server or successful required call (`lsp/index.ts:2145-2160`).

Delegation pressure: `task.eager` `default|preferred|always` (`4553-4568`) injects delegation guidance into the system prompt.

---

## 9. Custom tools / hooks / extensions surface

### Hooks — the contract is NOT `pre`/`post`

Discovery walks only `hooks/pre/` and `hooks/post/`, deriving `type` from the directory and `tool` from the filename stem (`*` = all tools) (`builtin.ts:672-717`), and `capability/hook.ts:17-38` validates that shape. **But the loader discards all of it**: `discoverAndLoadHooks` keeps only `hook.path` (`extensibility/hooks/loader.ts:236-237`), then `loadHook` imports the file as a module and requires `export default (pi: HookAPI) => void` (`loader.ts:146-184`, factory type `extensibility/hooks/types.ts:599`). A hook is a **TypeScript event-subscription module**; the `pre|post|<toolname>` path is naming convention with no runtime meaning. A `.sh` file in `hooks/pre/` would be discovered and then fail to import.

`pi.on(...)` accepts 25 events (`extensibility/hooks/types.ts:483-512`): `session_start`, `session_before_switch`, `session_switch`, `session_before_branch`, `session_branch`, `session_before_compact`, `session.compacting`, `session_compact`, `session_shutdown`, `session_before_tree`, `session_tree`, `context`, `before_agent_start`, `agent_start`, `agent_end`, `turn_start`, `turn_end`, `auto_compaction_start`, `auto_compaction_end`, `auto_retry_start`, `auto_retry_end`, `ttsr_triggered`, `todo_reminder`, `tool_call`, `tool_result`.

Enforcement powers that matter for quality gates:
- `tool_call` → `{ block?: boolean, reason?: string, input?: unknown }` (`extensibility/shared-events.ts:294-314`). `block` returns `reason` to the model as a tool error; `input` **replaces the arguments the tool actually runs with**, revalidated against the tool schema before approval, so the user approves what really executes.
- `tool_call` handlers are **fail-safe by blocking**: a thrown error or a hook fault blocks execution (`extensibility/hooks/tool-wrapper.ts:44-74`). `tool_result` also fires on tool errors (`tool-wrapper.ts:101-120`).
- `tool_result` → `{ content?, details?, isError? }` (`shared-events.ts:322-329`) — can rewrite or shrink a tool result before it enters context.
- `context` → `{ messages? }` rewrites the entire message array before the provider request (`hooks/types.ts:415-418`).
- `before_agent_start` → `{ message? }` injects a persisted, TUI-visible context message (`hooks/types.ts:426-429`).
- `session_before_compact` / `session.compacting` can cancel or customize compaction (`hooks/types.ts:488-492`, event payloads at `shared-events.ts`).

Hook API also exposes `sendMessage` (with `triggerTurn`, `deliverAs: "steer" | "followUp"`), `appendEntry` (persisted state **not** sent to the LLM), `registerMessageRenderer`, `registerCommand` (real slash commands with handlers), `exec(command, args, opts)`, `logger`, `arktype`/`zod`/`typebox` validators, and the whole `pi` namespace (`hooks/types.ts:514-592`).

### Tools

Built-in tool names (`tools/builtin-names.ts`): `read, bash, edit, ast_grep, ast_edit, ask, debug, eval, github, glob, grep, lsp, inspect_image, browser, computer, checkpoint, rewind, security_scan, task, hub, todo, web_search, write, memory_edit, retain, recall, reflect, learn, manage_skill`. Hidden but addressable: `yield`, `goal`. Essential (always top-level, never demoted): `read, write, bash, edit, glob, computer, eval, task, hub, learn, manage_skill` (`tools/essential-tools.ts`).

Custom tools accept `.json` / `.md` (name + description from JSON body or frontmatter) and executables `.ts .js .sh .bash .py`, plus `tools/<name>/index.ts` (`builtin.ts:754-833`). The `.sh`/`.py` forms are the cheap deterministic-capability path; the exact runtime invocation contract lives in `extensibility/custom-tools/loader.ts`, not read this pass (§11).

### Extensions

`extensions/*.ts|*.js`, `extensions/<n>/index.{ts,js}`, or `extensions/<n>/package.json` with an `omp`/`pi` manifest declaring `extensions: [...]`; one level deep only, symlinks handled explicitly (`helpers.ts:608-699`, `:593-606`). Extensions can also be listed by path in `settings.json` `extensions: []` (`builtin.ts:506-520`). Bundled custom commands exist as a reference implementation (`extensibility/custom-commands/bundled/{ci-green,review}/index.ts`).

---

## 10. Corrections to spec claims

| Spec claim | Reality | Evidence |
|---|---|---|
| `spec/02` §A: hooks are `hooks/<type>/*`, type is the contract | `type`/`tool` are discovery metadata the loader throws away; a hook is a TS module exporting `default (pi: HookAPI) => void` with 25 subscribable events | `extensibility/hooks/loader.ts:236-237`, `:146-184`; `hooks/types.ts:483-512`, `:599` |
| `spec/01` §2 + `spec/02` §A discovery tables are complete | Missing `.omp/SYSTEM.md`, `.omp/mcp.json` / `.mcp.json`, `settings.json:extensions[]`, `tools/<name>/index.ts`, managed-skills provider | `builtin.ts:242-271`, `:206-211`, `:506-520`, `:804`, `:309-337` |
| (unstated) `.omp/` discovery works from any cwd | Only `skills/`, `AGENTS.md`, `RULES.md`, `SYSTEM.md` walk ancestors; everything else is exactly `cwd/.omp`. An empty `.omp/` is ignored entirely | `builtin.ts:58-73`, `:46-56`, `:284`, `:90-99` |
| (unstated) `task` is called as `{agent, task}` | `task.batch` defaults **true**, so the model-facing shape is `{context, tasks[]}` and `context` is **required**. Any command prose telling the Tech Lead to call the flat form is wrong under the default baseline | `settings-schema.ts:4570-4580`; `types.ts:167-171` |
| `spec/02` OQ-3: is depth counted from main or first subagent? | **Closed.** `childDepth = parentDepth + 1`, refused when `childDepth >= max`. Default `2` allows main → child(1) → grandchild(2, `task` stripped): two subagent levels, not one. `spec/01` §8's DR-1 premise that option B "leaves zero spare depth" is therefore too pessimistic | `executor.ts:2656`, `:2670-2672`, `:2683-2685` |
| `spec/01` §4 / `spec/02` §D: after 3 failures OMP "accepts the payload anyway — a schema is a strong nudge, not a hard gate" | In permissive mode an invalid payload is still rejected as `schema_violation` (exit 1) **unless** the in-tool retry budget was exhausted or the schema was malformed. Strict rejects even that. Closer to a gate than the spec assumes | `executor.ts:598-700` (`mustReject`) |
| `spec/02` §B: a worker's `tools:` allowlist bounds it | `hub` is force-appended to every subagent, and `task` is auto-added when `spawns` is set and depth allows. Allowlists are floors, not ceilings | `executor.ts:2691-2694`, `:2676-2681` |
| `spec/02` §B: `spawns: ""` is inert | True at the parse layer (`parseArrayOrCSV("")` → `undefined`), but `resolveSpawnPolicy` maps an empty list to `enabled: false`. The two layers disagree; the protection in practice is still the missing `task` tool. Also unrecorded: `allowedAgents[0]` becomes the default agent | `helpers.ts:167-177`, `:270-282`; `spawn-policy.ts:41-59` |
| `spec/05` context model implicitly assumes `shake` | Default `compaction.strategy` is `snapcompact` (no LLM call); `shake` must be selected explicitly | `settings-schema.ts:2164-2198` |
| (unstated) per-spawn `effort` is available | Absent from the wire schema unless `task.enableEffort: true` (default false), and capped by `task.maxEffort` | `types.ts:202`; `settings-schema.ts:4582-4592`, `4706-4718` |
| (unstated) subagents run unbounded | `task.softRequestBudget` 200 with a hard stop at 1.5×, `task.agentIdleTtlMs` 420 s parking, output caps 500 KB / 5 000 lines | `settings-schema.ts:4676-4692`, `4664-4674`; `types.ts:53-56` |

---

## 11. Unverified / needs live experiment

Source-reading gaps in this pass (do not design against assumptions here):

1. **Command frontmatter keys.** `builtin.ts:346-355` parses none. The consumer is the slash-command layer (`slash-commands/`, `capability/slash-command.ts`) — unread. Argument handling, `allowed-tools`, per-command `model` are all **UNVERIFIED**.
2. **`tools/yield.ts`** — retry count, `{result: {data}}` wrapping, per-section incremental validation. `[spec-carried]` only.
3. **`config/model-roles.ts` / `model-resolver.ts`** — built-in role list and the custom-role gate are `[spec-carried]`; project-vs-user merge order in `config/settings.ts` is unread.
4. **Custom tool invocation contract** for `.sh`/`.py`/`.ts` in `.omp/tools/` — argument passing, stdout parsing, schema declaration. `extensibility/custom-tools/loader.ts` and `wrapper.ts` unread.
5. **`output:` frontmatter accepted forms.** Typed `unknown` at `helpers.ts:289` and `object|boolean|string|null` on the wire (`types.ts:110`). Whether JTD, JSON Schema, or both are accepted from frontmatter needs a live spawn. (`tools/jtd-to-json-schema.ts` and `output-schema-validator.ts` exist and hint at JTD; unread.)
6. **`autoloadSkills` propagation and accounting** — whether the skill body lands in the subagent's context only, and whose budget it charges. Prompt assembly path untraced.
7. **`alwaysApply` skill/rule propagation into subagent prompts** (spec OQ-1) — still open; subagent system-prompt assembly untraced.
8. **Isolation on Windows** (spec OQ-2): whether `mode: auto` selects `projfs`/`block-clone` or degrades to `rcopy` on the target volume, and whether patch-merge isolation actually holds for two concurrent writers. Backend selection is native (`pi-iso`), unreadable from TS. Needs a live two-writer test.
9. **Whether a `tools:` allowlist hard-blocks a fabricated call** to an unlisted tool, or merely omits it from the schema (spec OQ-4). Registry filtering is visible; enforcement is not.
10. **Hook execution scope**: whether hooks discovered from a project `.omp/` are loaded inside *subagent* sessions or only in the main session. `discoverAndLoadHooks(configuredPaths, cwd)` takes a `cwd` (`hooks/loader.ts:220`), but the subagent wiring path was not traced. This gates any design that uses hooks as a per-worker quality gate.
11. **`task.eager`, `contextPromotion`, `snapcompact.systemPrompt`** behavioral effects — settings verified, runtime effect not.
