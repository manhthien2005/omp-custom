# 02 — Runtime Semantics

## Selected Topic 04 lifecycle reducer (KD-028)

`state/agent-tasks.ps1` is the only reducer for immutable init/status, phase/task creation, worktree binding,
checkpoint, work-unit outcome, freeze/check, artifact/evidence, handoff/takeover, terminal close,
invalidation, cleanup/restore/purge, lock recovery, and migration. Every mutation uses a lock plus
expected revision, revision hash, and lease generation; mismatch refuses without merging.
There is no heartbeat TTL and no automatic takeover. Normal handoff is two-phase structured transfer;
crash takeover needs explicit structured user authority. Topic 04 uses the manual shared core;
automatic lifecycle attachment remains gated to Topic 08.

## Selected Topic 07 runtime semantics (KD-031)

The `agent-boundary` component v2 installs `context-continuity.js` last with an exact runtime-only
profile: `contextPromotion.enabled=false`, `compaction.enabled=false`, `strategy=off`, automatic
thresholds disabled, `autoContinue=false`, and remote/idle/mid-turn paths disabled. The extension
registers argument-free `/safe-compact`; only a single-use nonce from that command may pass
`session_before_compact`, and the command calls native `ctx.compact({ mode: "soft" })` once.
`project-continuity` derives exactly one active task from the persisted OMP session identity.
Before ordinary provider dispatch the adapter rechecks settings, authority, epoch/kernel binding,
and context pressure. Failure aborts rather than silently continuing. Bounded subagents inherit
the disabled profile, cannot compact, and settle pressure as failed/partial without auto-retry.

> OPUS PROPOSED SPEC v1 | Every omp-custom component mapped to a real OMP primitive.
> **All claims below are verified against OMP source at `_research/upstreams/oh-my-pi`.**
> Citations are `file:line`. Nothing in this document is inference.
>
> Former worker names and counts below describe the frozen Phase 00 baseline only; they are
> runtime observations, not topology authority. The Topic 03-selected manifest owns current
> worker names and count; Phase 02 owns runtime projection.
>
> **Current manifest:** exactly `cheap-scout`, `worker`, and `reviewer`. `tech-lead`, `explorer`,
> `implementer`, and `verifier` must be absent from agent discovery. Current-product evidence
> supersedes the Phase 00 roster for runtime acceptance without rewriting historical bytes.

---

## A. How OMP Actually Discovers Things

The authoritative list of subdirectories OMP scans under a `.omp/` config dir is in
`packages/coding-agent/src/discovery/builtin.ts`. Verified by grepping every
`path.join(dir, ...)` call in that provider:

| Subdir / file | Line | Capability |
|---|---|---|
| `commands/` | `builtin.ts:345` | SlashCommand |
| `rules/` | `builtin.ts:377` | Rule |
| `prompts/` | `builtin.ts:435` | Prompt |
| `extensions/` | `builtin.ts:483` | Extension module |
| `settings.json` | `builtin.ts:484` | Settings |
| `instructions/` | `builtin.ts:642` | Instruction |
| `hooks/<type>/` | `builtin.ts:687` | Hook |
| `tools/` | `builtin.ts:736` | Tool |
| `config.yml` | `builtin.ts:879` | Settings |
| `skills/` | `builtin.ts:287`, `:296` | Skill |
| `AGENTS.md` | `builtin.ts:910`, `:923` | Context file |
| `RULES.md` | `builtin.ts:392`, `:398` | Sticky always-apply Rule |
| `agents/` | `task/discovery.ts:73–85` | AgentDefinition |

**`policies/` and `schemas/` appear nowhere in this list.** A grep for
`path.join.*polic` and `path.join.*schema` across the whole `discovery/` tree
returns zero hits. These two directories have no loader, no URI scheme, and no
runtime consumer of any kind.

---

## B. Agent Frontmatter — The Real Contract

Authoritative parser: `parseAgentFields()` at
`packages/coding-agent/src/discovery/helpers.ts:253–323`.

### Key normalization (resolves the kebab-case question)

`parseFrontmatter` (`packages/utils/src/frontmatter.ts:106`) pipes the parsed YAML
through `normalizeKeys` (`frontmatter.ts:16–38`), which recursively rewrites
kebab-case keys to camelCase via `key.replace(/-([a-z])/g, ...)` (`frontmatter.ts:11-12`).

**Therefore `thinking-level:` → `thinkingLevel`, and `read-summarize:` → `readSummarize`.
Both kebab-case spellings used in omp-custom are valid.** OMP's own bundled
`frontmatter.md` template emits `thinking-level:` in kebab-case, confirming it is
the house style rather than a tolerated alias.

### Every recognized field

| Frontmatter key | Parsed as | Line | Required |
|---|---|---|---|
| `name` | string | `helpers.ts:254` | **Yes** — null return without it |
| `description` | string | `helpers.ts:255` | **Yes** — null return without it |
| `tools` | array or CSV, normalized | `helpers.ts:261-262` | No |
| `spawns` | array, CSV, or `"*"` | `helpers.ts:270-282` | No |
| `model` | array or CSV of patterns | `helpers.ts:298` | No |
| `output` | passthrough (output schema) | `helpers.ts:289` | No |
| `thinkingLevel` / `thinking` | ConfiguredThinkingLevel | `helpers.ts:290-297` | No |
| `blocking` | boolean | `helpers.ts:299` | No |
| `readSummarize` | boolean | `helpers.ts:300` | No |
| `prewalk` | boolean or string | `helpers.ts:302-306` | No |
| `autoloadSkills` | array or CSV | `helpers.ts:307-309` | No |

### Two behaviors with real consequences

**`yield` is force-appended to any explicit tool list** (`helpers.ts:265-267`):
```ts
if (tools && !tools.includes("yield")) tools = [...tools, "yield"];
```
Every omp-custom worker declares `tools:`, so all four get `yield` automatically.
Structured output is therefore *mechanically possible* for every worker — the
missing piece is `outputSchema`, not the tool.

**`tools: task` implies `spawns: "*"`** (`helpers.ts:285-287`):
```ts
if (spawns === undefined && tools?.includes("task")) spawns = "*";
```
`tech-lead.md` declares both `tools: task` and an explicit `spawns:` list, so its
explicit list wins. Had it omitted `spawns:`, it would have silently gained
permission to spawn *any* agent.

### `spawns: ""` — verified as a no-op, not a lockdown

`parseArrayOrCSV("")` on an empty string yields no entries, so `spawns` resolves to
`undefined` rather than an empty allowlist. The four workers all use `spawns: ""`
intending "spawn nothing." What actually protects them is the **absence of `task`
from their `tools:` list** — with no `task` tool, they cannot spawn regardless.
The `spawns: ""` line is inert. Harmless today, but it encodes a false sense of
enforcement; the real guarantee is the tool allowlist.

---

## C. Model Roles — `@name` Resolution

Authoritative: `config/model-resolver.ts` and `config/model-roles.ts`.

Built-in roles (`model-roles.ts:22-32`): `default`, `smol`, `slow`, `vision`,
`plan`, `designer`, `commit`, `tiny`, `task`, `advisor`. **None of
`tech-lead`/`explorer`/`implementer`/`verifier`/`reviewer` is built in.**

The resolution gate is `getModelRoleAlias` (`model-resolver.ts:925`):
```ts
if (isModelRole(candidate) || settings?.getModelRole(candidate) !== undefined) return candidate;
return undefined;
```

**Custom role names are first-class — but only when defined in settings.**
`getKnownRoleIds` (`model-roles.ts:87`) explicitly folds in every key of
`settings.getModelRoles()`, confirming custom roles are a designed feature.

This makes `model: "@explorer"` correct **if and only if** the effective settings ship a
matching `modelRoles.explorer` entry. Phase-00 E2 supersedes the earlier fall-through
hypothesis: missing or unknown aliases and unavailable models fail with no fallback; project
configuration wins over the global value. Missing and unknown aliases hard-error before
session creation, while an alias mapped to an unavailable model resolves first and then
surfaces the downstream error. The installer and L1 therefore validate every alias referenced
by the selected manifest before dispatch.

---

## D. Structured Output — Where Schemas Actually Live

The `yield` tool (`tools/yield.ts`) builds its parameter schema from
`session.outputSchema` (`yield.ts:247`), then validates every submission against it
(`yield.ts:377-401`), with a 3-retry budget before overriding (`yield.ts:202`).

`session.outputSchema` is populated from the **`outputSchema` field of the `task`
tool call** (`task/types.ts:118`, `:126`, `:143`, `:154`) or from the agent's own
`output:` frontmatter (`helpers.ts:289`). Both are accepted as
`"object | boolean | string | null"` (`types.ts:110`).

`task` also accepts `schemaMode: "permissive" | "strict"` per call
(`task/prompt-policy.ts`, schema builder).

**Consequence:** OMP has a complete, enforcing structured-output mechanism, and
omp-custom uses none of it. The agent files say *"Return schema: `agent-result`"*
as English prose. `.omp/schemas/*.yml` is never read. The correct wiring is either
an `output:` block in each agent's frontmatter or an `outputSchema` argument in each
`task` call — the YAML files can remain as the human-authored source of truth that
those are generated from.

---

## E. Isolation

`task.isolation.mode` default is **`"none"`** (`config/settings-schema.ts:4463`),
with `"auto"` documented as *"lets the native PAL pick the best available backend"*
(`settings-schema.ts:4469`). The user's frozen baseline sets `auto`.

Per-call control is the **`isolated?: boolean`** field on the task schema
(`task/types.ts`, `createTaskSchema`) — present only when isolation is enabled
globally. So `isolation.mode` selects the *backend*; `isolated: true` selects
*whether a given task uses it*.

**`auto` does not mean "isolate automatically."** Nothing infers isolation from
whether an agent writes files. A parallel Implementer fan-out without explicit
`isolated: true` shares one workspace and can interleave edits. `orchestrated.md`
never passes `isolated`.

---

## F. LSP in Subagents

Source-verified LSP availability is a **four-condition conjunction**: per-agent allowlist,
`task.enableLsp`, parent session not disabled and not plan mode, and `lsp.enabled`.

- `task/structured-subagent.ts:318-320` combines plan mode, parent `enableLsp`, and
  `task.enableLsp`; the latter defaults **`false`** (`settings-schema.ts:4617`).
- `tools/index.ts:593` separately requires `lsp.enabled == true` before registering the
  built-in tool.
- `task/executor.ts:2675-2678` supplies the selected agent's `tools:` allowlist.

All four effective gates are source-verified independently. The spec author's development
environment setting `task.enableLsp: true` is not a property of OMP or any install (CR-40).
The project install owns that key only when the selected contract consumes LSP; parent/plan
state and CR-41 remain effective-runtime checks. See `07-retrieval-and-code-understanding.md
§A-1`.

A registered LSP tool may still return details.success false when no language server applies;
that result cannot satisfy a selected symbol-aware contract. In the pinned runtime, no matching
or configured server returns ordinary content with `details.success: false`
(`lsp/index.ts:2145-2160`) rather than preventing the worker from yielding a plausible result.
The coordinator therefore validates required LSP call outcomes, not tool registration alone.

No frozen-baseline omp-custom agent lists `lsp`, while `explorer.md` instructs LSP use. That
instruction is unsatisfiable under its current allowlist; OMP cannot expose the tool through
that worker definition.

---

## G. Component → Primitive Mapping

| omp-custom component | OMP primitive | Runtime consumer | Verdict |
|---|---|---|---|
| `commands/quick.md` | SlashCommand (`builtin.ts:345`) | ✓ | CORRECT |
| `commands/standard.md` | SlashCommand | ✓ | CORRECT |
| `commands/orchestrated.md` | SlashCommand | ✓ | CORRECT |
| `AGENTS.md` | Context file (`builtin.ts:923`) | ✓ | CORRECT |
| `RULES.md` | Sticky always-apply Rule (`builtin.ts:398`, forced at `:416`) | ✓ | CORRECT |
| `config.yml` | Settings (`builtin.ts:879`) | ✓ | CORRECT |
| `agents/explorer.md` | AgentDefinition (`task/discovery.ts:80`) | ✓ frontmatter valid | VALID; body↔tools conflict (§F) |
| `agents/implementer.md` | AgentDefinition | ✓ frontmatter valid | VALID; no `isolated` at call site |
| `agents/verifier.md` | AgentDefinition | ✓ frontmatter valid | VALID |
| `agents/reviewer.md` | AgentDefinition | ✓ frontmatter valid | VALID |
| `agents/tech-lead.md` | AgentDefinition | ✓ loads, never invoked | DEAD ABSTRACTION → **relocate out of `agents/` (CR-33)**. Loading is unconditional: `loadAgentsFromDir()` parses every `.md` in the directory. While the file sits there it is a real, spawnable agent regardless of intent, creating a second Tech Lead topology alongside DR-1's main-session decision. |
| `skills/task-triage/` | Skill (`builtin.ts:287`) | ✓ lazy | CORRECT |
| `skills/systematic-debugging/` | Skill | ✓ lazy | CORRECT |
| `skills/evidence-before-completion/` | Skill | ✓ lazy | works; `alwaysApply` candidate |
| `schemas/*.yml` | **none** | ✗ no loader | DOCS ONLY |
| `policies/*.yml` | **none** | ✗ no loader | DOCS ONLY |

---

## H. Corrections to Earlier Drafts

Recorded so the error does not survive into implementation:

| Earlier claim | Verified reality |
|---|---|
| `tech-lead.md` lacks `---` frontmatter fences | **False.** `od -c` confirms `---\n` at byte 0 of all five agent files. The apparent absence was a WebFetch HTML-rendering artifact. Frontmatter parses correctly. |
| `thinking-level:` / `read-summarize:` unsupported | **False.** `normalizeKeys` (`frontmatter.ts:16`) maps kebab→camel; both are recognized. |
| `spawns:` unverified | **Verified.** Parsed at `helpers.ts:270-282`; `spawns: ""` is a no-op, not an empty allowlist. |
| Custom model roles unverified | **Verified supported**, conditional on a `modelRoles` entry (`model-resolver.ts:925`). |
| Explorer omitting `lsp` is fine | **Wrong.** Its body instructs LSP use; the tool is unreachable. Real contradiction. |

**Methodological note:** every "unverified" item above became answerable the moment
the local clone was read instead of GitHub's rendered HTML. WebFetch on
`github.com/.../blob/...` strips frontmatter fences and refuses long files. Future
verification must read `_research/upstreams/oh-my-pi` or raw.githubusercontent.com.

---

## I. Remaining Open Questions

Genuinely unresolved after source reading — each needs a live experiment, not more
code reading.

OQ-3 is closed by pinned source: child depth 1 retains task, while child depth 2 reaches the
default maxRecursionDepth and loses task. The executor computes `childDepth = parentDepth + 1`
and strips `task` when `childDepth >= maxRecursionDepth` (`task/executor.ts:2655-2687`), so no
live experiment is needed to establish the default depth boundary.

| OQ | Question | Why source reading was insufficient | Experiment |
|---|---|---|---|
| OQ-1 | Does `alwaysApply: true` propagate a skill into *subagent* contexts, or only the main session? | Skill injection is assembled in the system-prompt builder; subagent prompt assembly is a separate path not traced. | Set `alwaysApply` on a marker skill, spawn a worker, inspect its rendered prompt. |
| OQ-2 | With `isolation.mode=auto` on Windows/ProjFS, does `isolated: true` succeed or silently degrade? | Backend selection is native (`pi-iso`), not readable from TS. | Run two isolated writers on the target volume; confirm patch-merge isolation. |
| OQ-4 | Does a `tools:` allowlist hard-*block* an unlisted tool, or merely omit it from the schema? | Registry filtering is visible; enforcement on a fabricated call is not. | Have a worker emit a call for an unlisted tool; observe error vs silent drop. |

The remaining OQ-1, OQ-2, and OQ-4 are deliberately narrower than the previous draft's OQ list:
the earlier OQ-1/OQ-2/OQ-5 (frontmatter fields, custom roles) are now **closed** by
§B and §C above.
