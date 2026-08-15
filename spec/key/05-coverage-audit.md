# 05 — Coverage Audit

> **Question this file answers:** have we actually seen the whole OMP customization
> surface, or only the part the first pass happened to look at?
>
> Method: enumerate OMP's real surface from source at `3a8591a`, then diff it against what
> `spec/00`–`16` + `spec/key/*` + `template/` reference. Anything on the left and not the
> right is a blind spot, whether or not we end up using it.
>
> **Verdict: the spec covers the surface it chose well, and missed roughly a third of the
> runtime.** Nine gaps are material. Two invalidate a recorded constraint. One is an OMP
> feature that overlaps `/orchestrated` closely enough that building ours without deciding
> about it would be negligent.
>
> Grades per `00-method.md §B`. OMP citations are `packages/coding-agent/src/<path>:<line>`.
>
> Former fixed-role topology statements below are historical audit observations, not current
> topology authority. Current topology and review behavior derive from the accepted design,
> active specs, phase plans, and Topic 03-selected manifest.

---

## A. The measurement

Two counts, both mechanical.

**Settings.** `config/settings-schema.ts` is 5,887 lines and
defines **453 setting keys** (415 quoted-dotted + 38 unquoted-flat) across **91** namespaces.
The prior count of 607 was wrong — see `spec/key/repos/oh-my-pi-settings.md §5-1` for the
mechanism; short version: `type:` appears 467× file-wide, inflated by `options[]` entries,
and the obvious regex silently drops 38 unquoted keys. Grepping every key against the
*deployable* surface (`spec/**`, `template/**`, `registry/**`, `docs/**`):
**28 appear, 425 do not.** Coverage is **6.2%**.

The prior figure of 24% included `spec/key/` decision docs and per-repo analysis files in the
corpus, which turns coverage measurement into self-reference. The three-tier breakdown:

| Corpus | Covered | % |
|---|---|---|
| Deployable surface only (`spec/` `template/` `registry/` `docs/`) | 28 | 6.2% |
| + `spec/key/` decision docs (excl. `repos/`) | 64 | 14.1% |
| + all `repos/` analysis reports | 101 | 22.3% |

The 6.2% figure is the one that matters for gap analysis.

**Subsystems.** `src/` has ~50 top-level directories. Eleven are referenced **zero** times
anywhere in the project:

```
autoresearch  auto-thinking  cleanse  collab  hindsight
markit  memory-backend  mnemopi  ssh  stt  tui
```

Another nine are referenced once or twice — effectively incidental word collisions rather
than actual coverage: `memories`, `plan-mode`, `slash-commands`, `tts`, `internal-urls`,
`vibe`, `goals`, `irc`, `subprocess`.

Low coverage is not automatically a defect: `stt`, `tts`, `irc`, `collab`, `ssh` are
genuinely irrelevant to a workflow template, and a deliberate non-decision is fine. What
matters is the difference between *"considered and excluded"* and *"never seen"*. Everything
in §B was never seen.

---

## B. The nine material gaps

Ordered by consequence.

| # | Gap | Class | Consequence |
|---|---|---|---|
| **G-1** | `eval` orchestration DSL (`agent()`, `parallel()`, `pipeline()`, `budget`) | **Competing implementation** | OMP already ships what `/orchestrated` is being built to do — and its version has a per-call `apply` |
| **G-2** | Per-call `apply` **does** exist on the `eval` path | **Invalidates a constraint** | `spec/08 §E-7`'s "no per-item apply field" is true for `task`, false for `eval` |
| **G-3** | Commands are **Handlebars templates** with positional args | **Unused capability** | `spec/04`/`06` treat command files as flat markdown; `$1`, `$@[2:3]`, `{{#if}}`, 19 helpers all work |
| **G-4** | `WATCHDOG.yml` / `WATCHDOG.md` advisor surface | **Missing discovery root** | An entire project-level config file, absent from every discovery table |
| **G-5** | `magicKeywords` (`ultrathink` / `orchestrate` / `workflowz`) | **Uncontrolled prompt injection** | Three keywords inject large hidden system notices; `orchestrate` contradicts our topology |
| **G-6** | Turn budget (`+Nk` / `+Nk!`) | **Unused control** | A hard token ceiling that makes `agent()` refuse to spawn — the enforcement `spec/05` wants |
| **G-7** | `@import` expansion in context files | **Unused capability** | `AGENTS.md` can transclude files; `spec/05`'s "no concatenation" finding is incomplete |
| **G-8** | ~14 foreign-agent discovery providers | **Unmanaged inputs** | `.claude/`, `.cursor/`, `.codex/`, `opencode`, `windsurf`… all load agents/commands/skills |
| **G-9** | `prewalk`, `task.agentModelOverrides`, `task.disabledAgents`, `task.eager` | **Unused levers** | Settings-level control of agent routing with no file edits |

---

## C. G-1 / G-2 — OMP already has an orchestration DSL

This is the finding that most changes what should be built.

### What exists

The `eval` tool exposes a Python/JavaScript/Ruby/Julia runtime whose global scope includes
an orchestration API (`eval/agent-bridge.ts`, `eval/concurrency-bridge.ts`,
`prompts/system/workflow-notice.md`), grade **A**:

```python
agent(prompt, *, agent="task", label=None, schema=None,
      isolated=None, apply=None, merge=None, handle=False)
parallel(thunks)          # bounded pool, input order preserved
pipeline(items, *stages)  # barrier between stages
completion(prompt, *, model="default", schema=None)
log(msg) / phase(title)
budget.total / budget.spent() / budget.remaining() / budget.hard
```

`agent()` returns the validated object when `schema=` is given, and state **persists across
`eval` calls** in a session — so scouting in one call and fanning out in the next is the
documented pattern.

### Why this is not merely interesting

Compare against what `spec/08` had to design around on the `task` path:

| Need | `task` tool | `eval.agent()` |
|---|---|---|
| Per-call isolation | `isolated: true` ✓ | `isolated=True` ✓ |
| **Per-call capture-only** | **absent** — session setting only (`spec/08 §E-7`) | **`apply=False`** (`eval/agent-bridge.ts:30,43,137`) |
| Retain artifacts | implicit | **`handle=True`** → `retainArtifacts: true` (`:153`) |
| Merge mode per call | absent | `merge=False` → `"patch"` (`:136`) |
| Structured result | `outputSchema` ✓ | `schema=` ✓ (`:148`) |
| Ordered fan-out | `results[index]` ✓ | `parallel()` preserves input order ✓ |
| Token ceiling | none | `budget.hard` refuses to spawn (`:126-131`) |

**G-2 is a correction, not an addition.** `spec/08 §E-7` states: *"`apply=false` is a
session/settings control, not a per-task-item field… **Do NOT** put `apply: false` inside
task item bodies."* That is **correct for `task`** and **false for `eval`**. The
`invocationKind: "eval"` path constructs an isolation request object carrying `apply`
directly (`eval/agent-bridge.ts:132-139`), and `runStructuredSubagent` honors it.

The consequence is that the entire CR-31 apparatus — installer-owned `task.isolation.apply`
keys, target-aware blast-radius policy, a mandatory runtime preflight reading effective
settings, and the manifest `installer_delta` tracking — exists to work around a limitation
**that only applies to the dispatch mechanism we chose**. On the `eval` path, capture-first
is a function argument. No settings deployment, no global blast radius, no preflight, no
rollback bookkeeping.

`eval` also fails **loudly** where `task` fails silently: an isolated apply failure throws
`ToolError` (`:174-180`), and a nested-patch apply failure throws with the notification text
(`:185-190`) — the exact CR-32 silent-loss channel, surfaced as an exception.

### What this does not settle

I am **not** recommending a rewrite on this evidence, and the honest reasons are:

- `eval` requires `task` **and** `eval` in the active tool set for the `workflowz` notice to
  fire; whether a `.omp/commands/*.md` body can drive `eval` as reliably as prose-directed
  `task` calls is **grade D**.
- The orchestration logic becomes **code inside a command body**, which is harder to review
  than prose and moves failure modes from "model misreads instruction" to "script throws".
- Recursion still applies: `eval`-spawned agents obey `task.maxRecursionDepth`.
- Nothing measured. `/orchestrated` on the `task` path is fully specified after five
  rounds; switching mechanism resets that.

**Decision needed, not made.** This belongs in `04-decision-log.md` as a KD with a named
experiment, because the current spec chose `task` *without knowing `eval` existed* — which
is not a decision, it is an accident. The cheapest resolution: one `/orchestrated` fixture
implemented both ways, compared through the frozen stable-product and promotion contract in
`spec/13 §C`, including failure-mode visibility.

---

## D. G-3 — Command files are Handlebars templates

Grade **A**, and it closes `dossiers/oh-my-pi.md §11` item 1 ("command frontmatter keys —
UNVERIFIED"), which the dossier explicitly warned not to design against.

### The verified contract

Two consumers, and they differ:

**1. `task/commands.ts` (workflow-command path).** Reads frontmatter `description` **only**
(`:54`, `:93` via `getString`). Body is `instructions`. `expandCommand` replaces `$@` with
input (`:122-125`). Nothing else is parsed.

**2. `extensibility/slash-commands.ts` (the interactive path — what `/standard` actually
hits).** `expandSlashCommand` (`:113-129`) does considerably more:

```
parseCommandArgs(argsString)                      → shell-like tokenizer, honors quotes
substituteArgs(content, args)                     → $1 $2 … $@ $ARGUMENTS $@[n] $@[n:m]
prompt.render(substituted, {args, ARGUMENTS, arguments})   → FULL HANDLEBARS
appendInlineArgsFallback(...)                     → appends args if no placeholder used
```

Called from `session/agent-session.ts:4964` on every `/`-prefixed prompt.

So a command file gets:

- **Positional args** — `$1`, `$2`; **all args** — `$@` / `$ARGUMENTS`; **slices** —
  `$@[2]`, `$@[2:3]` (`utils/command-args.ts:45-65`).
- **Handlebars** with `{{#if}}`, `{{#each}}`, subexpressions, and ~19 registered helpers:
  `arg`, `join`, `default`, `ifAny`, `ifAll`, `codeblock`, `xml`, `escapeXml`, `len`, `add`,
  `sub`, `includes`, `not`, `jsonStringify` (`packages/utils/src/prompt.ts:316-518`).
  Compiled with `noEscape: true, strict: false` (`:531-534`) — so an undefined variable
  renders empty rather than throwing.
- A **graceful-fallback** rule: if the template uses no placeholder at all, the args get
  appended anyway — so `/standard fix the login bug` works without any `$@`.

### Why it matters for us

Three concrete wins the spec currently cannot express:

1. **`/quick`, `/standard`, `/orchestrated` can be one file.** The sizing decision is a
   `{{#if}}` over an argument, and `spec/04`'s deferred `/work` auto-router (W-1) becomes a
   template branch rather than a fourth command.
2. **The inlined risk→gate matrix can be conditional.** `spec/11 §E` inlines the whole
   LOW/MEDIUM/HIGH/CRITICAL table into two command bodies. With `{{#if}}` only the selected
   tier renders — command bodies are lazy-tier, but they are still paid per invocation.
3. **Structured argument contracts.** `/standard --risk=high src/auth.ts` is parseable
   today, with quote handling, without inventing a convention.

The risk is equally real and belongs in the same note: **`strict: false` means a typo'd
`{{varname}}` renders as empty string, silently.** That is another entry for §E's
silent-failure catalogue, and an L0 lint target (render every command template with empty
args; fail on an unresolved `{{`).

---

## E. G-4 — `WATCHDOG.yml`: an entire discovery root we never listed

Grade **A**. `advisor/config.ts:130-140` discovers `WATCHDOG.yml` / `WATCHDOG.yaml` on the
same user+project search path as `WATCHDOG.md`, via `collectConfigCandidates`, and
`resolveWatchdogPath` (`:201-209`) resolves `project` → `<projectDir>/WATCHDOG.yml`, `user`
→ `<agentDir>/WATCHDOG.yml`.

Shape (`:52-62`):

```yaml
instructions: <shared baseline, prepended to every advisor>
advisors:
  - name: <string>          # required
    model: <selector[:level]>
    tools: [<BUILTIN_TOOL_NAMES subset>]
    instructions: <specialization>
    enabled: <bool, default true>
```

Two facts make this more than a curiosity:

- **An advisor is a full agent.** `tools` may include **mutating** tools —
  `edit`/`write`/`bash` are explicitly permitted (`config.ts:11-18`). Omitted defaults to
  `read`/`grep`/`glob`; explicit `[]` grants nothing.
- It runs as a **watcher on primary turns**, with its own model, its own transcript
  (`advisor/transcript-recorder.ts`), an emission guard limiting it to one `advise()` per
  update (`advisor/emission-guard.ts`), and a documented lifecycle including
  `quota_exhausted` with auto-retry (`config.ts:30-39`).

`spec/README §8` lists "always-on advisor" under **What Must NOT Be Implemented Yet**, and
`spec/00 F-*` never mentions the file. So the *decision* to skip advisors was made, but
without knowing the surface — and more importantly, **the installer and validation never
check whether one already exists.** A user with a pre-existing `WATCHDOG.yml` granting
`edit` gets a mutating watcher running alongside our workflow, invisible to every validation
tier and unmentioned in `spec/15`'s threat model.

**Actionable regardless of the advisor decision:** L1 discovery must report a discovered
advisor roster, and `spec/15 §A` must place advisor-authored edits in the trust table.

---

## F. G-5 — Magic keywords, and one that contradicts our topology

Grade **A**. `session/agent-session.ts:4882-4924` (`#createMagicKeywordNotices`) appends
hidden, `display: false` system notices to a user turn when a keyword appears in prose.
Settings: `magicKeywords.enabled`, `.ultrathink`, `.orchestrate`, `.workflow`
(`settings-schema.ts:1871-1904`). Matching is lowercase, prose-delimited, and skips code
blocks/spans (`modes/magic-keyword-boundary.ts`, `modes/markdown-prose.ts`).

The payloads are not small nudges:

| Keyword | Injects | Size |
|---|---|---|
| `ultrathink` | `prompts/system/ultrathink-notice.md` | reasoning nudge |
| `orchestrate` | `prompts/system/orchestrate-notice.md` | **40 lines** — a full orchestrator contract |
| `workflowz` | `prompts/system/workflow-notice.md` (Handlebars-rendered) | **112 lines** — the `eval` DSL manual |

`workflowz` additionally gates on `task` **and** `eval` both being active
(`agent-session.ts:4908-4909`), and renders with `taskBatch` + `scoutAvailable`.

### The contradiction

`orchestrate-notice.md` is a competing orchestration doctrine, and it disagrees with ours on
substance, not wording:

| `orchestrate-notice.md` says | Our spec says |
|---|---|
| "**NEVER launch a one-off task**… If you are about to dispatch exactly one subagent, stop" | Standard may remain integrated or select one responsibility; Orchestrated may execute selected work units sequentially. Dispatch count does not define workflow identity (`spec/04`) |
| "**Subagents do not verify, lint, or format.** Every `task` assignment MUST instruct the subagent to skip all gates" | A selected non-author verification mechanism may be a subagent, so its contract must preserve the required gates (`spec/10`) |
| "Parallelize maximally" | "Parallelize only on genuine independence; size alone never justifies fan-out" (`spec/08 §C`) |
| Orchestrator makes trivial edits inline with `edit`/`write` | Tech Lead never edits; `/quick` is the inline path |

If a user types "orchestrate" in a message that also invokes `/standard`, the session
receives both contracts. The notice explicitly claims override authority: *"This contract
overrides any default tendency to yield early, narrate, or do the work yourself."*

This is not hypothetical — "orchestrate" is an ordinary English word for exactly what this
template does, so a user describing their intent will trigger it by accident.

**Three options, none free:**
1. Set `magicKeywords.orchestrate: false` as a template-owned setting — but that is a
   global behavior change, with the same blast-radius argument CR-31 applied to
   `task.isolation.apply`.
2. Reconcile our command prose with the notice where they can agree, and state the
   precedence where they cannot.
3. Document the interaction and leave it. Cheapest, and it leaves a live contradiction.

`spec/13` L4 gains a case either way: run `/standard` with "orchestrate" in the prompt and
assert the workflow still runs its own topology. The `ultrathink` interaction is benign and
`workflowz` is opt-in-by-obscurity, but both should be named.

---

## G. G-6 — Turn budget: the enforcement `spec/05` asked for

Grade **A**. `modes/turn-budget.ts:23` `parseTurnBudget(text)` reads a `+Nk` / `+Nk!`
directive from the user's message; `sessionManager.beginTurnBudget(total, hard)` arms it
(`agent-session.ts:4884-4885`). When hard, `eval`'s `agent()` **refuses to spawn**:

```
agent() blocked: turn token budget exhausted (spent/total output tokens).
Raise or drop the +Nk! ceiling to continue.
```
(`eval/agent-bridge.ts:126-131`)

`spec/05 J C-4` records *"Enforce packet/result budgets at runtime — **not possible
statically; contract-only in v0**."* That is true for packet size and false for total spend:
a hard turn budget is a real, runtime-enforced ceiling, and `budget.remaining()` lets a
fan-out scale itself to what is left.

For `/orchestrated`, whose whole risk is unbounded fan-out cost, this is the missing guard
rail. It is per-turn and user-supplied rather than template-owned, so it does not replace the
budgets — but "no runtime enforcement exists" is no longer accurate.

---

## H. G-7 / G-8 / G-9 — three smaller gaps

### G-7 — `@import` in context files

`discovery/at-imports.ts` expands `@path/to/file` inside `AGENTS.md` (and
`CLAUDE.md`/`GEMINI.md`) before it reaches the system prompt: `@` must start a line or
follow whitespace, relative paths resolve against the **importing file's** directory, `~/`
works, imports inside code fences/spans are preserved, recursion is capped, and an unreadable
target is left verbatim with a debug log.

`template/.omp/AGENTS.md` already suggests *"Use @imports for longer architecture docs"* —
so the template recommends a mechanism the spec never verified. Now verified, with two
consequences: the persistent-tier cost of `AGENTS.md` is **not** bounded by its own file
size (an import pulls its target into every turn), and `spec/05 §I`'s budget check must
measure post-expansion size to mean anything.

Worth pairing with the `dossiers/oh-my-pi.md §7` finding that project `AGENTS.md` returns
at the **nearest** match with no upward concatenation: `@import` is the supported way to
compose, and a monorepo package file must import the root explicitly.

### G-8 — foreign discovery providers

`discovery/` ships ~14 non-native providers: `claude.ts`, `claude-plugins.ts`, `codex.ts`,
`cursor.ts`, `gemini.ts`, `cline.ts`, `windsurf.ts`, `opencode.ts`, `vscode.ts`,
`github.ts`, `agents-md.ts`, `omp-plugins.ts`, `omp-extension-roots.ts`, `mcp-json.ts`.

They load **agents, commands, and skills** from other tools' directories. `skills.*`
settings include per-source toggles for Codex/Claude/pi/AGENTS at user and project scope
(`settings-schema.ts:4790-4802`), which implies real precedence interactions.

Direct consequence for us: this repository has a `.claude/` directory. A user installing our
template into a repo that also uses Claude Code, Cursor, or opencode gets a **merged**
capability set. L1 compares the Topic 03-selected worker set and reports foreign discovered
agents separately. Foreign discovery neither expands the selected set nor invalidates its
exact comparison; the former fixed-roster assertion in this audit is superseded.

### G-9 — settings-level agent control

Four levers, all grade **A**, none referenced anywhere:

| Setting | Effect | Why it matters |
|---|---|---|
| `task.agentModelOverrides` | record: agent name → model | Overrides `model:` frontmatter **without editing agent files** — a cleaner seam than `modelRoles` for per-project routing |
| `task.disabledAgents` | array | Kills specific agents; consulted for `scout` at `task/spawn-policy.ts:66-77` |
| `task.agentPrewalk` | record | Per-agent prewalk without frontmatter |
| `task.eager` | `default\|preferred\|always` | Injects delegation pressure into the system prompt |

`task.agentModelOverrides` deserves a second look in particular: `spec/09 §B` documents a
hard coupling where installing `agents/` without `config.yml` silently breaks every `@role`.
An override record is a different placement of the same decision, and possibly a less
fragile one.

---

## I. Where the audit found the spec already complete

Stated so this reads as an audit and not a complaint. Verified as covered, correctly:

- **Discovery surface for what we ship** — `agents/`, `commands/`, `skills/`, `AGENTS.md`,
  `RULES.md`, `config.yml`, plus the cwd-anchoring trap and the empty-dir invisibility.
  `dossiers/oh-my-pi.md §1` is accurate and more complete than `spec/01 §2`.
- **Agent frontmatter** — the eleven-key list is exhaustive and matches
  `helpers.ts:253-323`. The floors-not-ceilings correction (`hub`, `task`, `yield`
  force-appended) is right.
- **Schema enforcement** — `mustReject` is correctly read, including that permissive still
  rejects and that a malformed schema degrades silently.
- **Isolation on the `task` path** — every claim holds. G-2 does not contradict it; it adds
  a second path the spec did not know about.
- **Native compaction, read summarization, artifact spill, subagent budgets** — source defaults
  were verified, including `snapcompact` rather than `shake`. KD-031 separately selects managed
  `strategy: off` plus explicit `/safe-compact`; this audit statement is source evidence, not
  current deployment authority.
- **Telemetry** — `SingleResult` fields expose selected identity. resolvedModelIsFallback detects
  retry fallback only; credential fallback requires returned modelRole and resolvedModel identity
  comparison. Malformed schemas and non-valid structured outputs fail acceptance.
- **Hooks** — correctly identified as TS modules with a discarded path convention, and
  correctly deferred on OQ-B rather than adopted.

---

## J. What to pay special attention to

The user asked for this explicitly. Six items, in the order they can hurt.

### 1. `orchestrate` is a live contradiction, and the word is unavoidable

The single highest-risk finding. A 40-line contract claiming override authority, triggered
by an ordinary English word, disagrees with any selected contract that assigns required
verification to a subagent. A selected subagent verification mechanism is incompatible with
the injected prohibition on subagent verification. The notice cannot silently override the
accepted task contract; decide its handling before writing command prose.

### 2. Silent-failure catalogue — now eleven entries

`01-dna.md §M` invariant 5 lists nine. This audit adds two:

10. **Handlebars `strict: false`** — a typo'd `{{var}}` in a command renders empty.
11. **`@import` of a missing file** — leaves the raw `@token` in the prompt, debug log only.

Every entry is a validation assertion, not a comment. Both new ones are cheap L0 checks.

### 3. The `task` vs `eval` choice was never made

`spec/08`'s most elaborate machinery (CR-29/30/31/32 — preflight, target-aware config
ownership, manifest delta tracking, nested-repo exclusion) exists to work around
`task`-path limits. On the `eval` path, `apply` and artifact retention are function
arguments and failures throw. Not necessarily better — but currently unchosen, which is
worse than either choice.

### 4. L1's exact-roster assertion will misfire

Fourteen foreign discovery providers mean the installed agent set is frequently a superset
of ours. Assert on our names and the absence of `tech-lead`; **report** foreign names rather
than failing on them.

### 5. `AGENTS.md` budget is unbounded until `@import` is expanded

`spec/05 §I` checks file size. The template's own comment recommends `@import`. Measure
post-expansion, or the tightest-multiplier budget in the system is measuring the wrong
number.

### 6. `WATCHDOG.yml` can grant `edit`/`write`/`bash` to a watcher

Not something we ship, and precisely why it needs a check: a pre-existing advisor mutates
the tree during our workflow, and no validation tier or threat-model row currently sees it.

---

## J-1. Topic 06 closure of the dispatch gap

KD-030 selects the same-name trusted `task` wrapper, so §J.3 is no longer an open product
mechanism choice. The wrapper delegates to the native executor and adds deterministic validation;
`eval` remains an available but unmanaged OMP facility. Its output, Vibe output, and unrelated
internal-agent output cannot claim an `agent_boundary_receipt`.

The remaining gap is narrower and nonblocking: `OPEN-T06-RUNTIME-01` asks upstream for a universal
interception seam if future product scope must cover those unrelated facilities. Managed v1 does
not pretend to cover them and does not need them for acceptance.

---

## K. Honest limits of this audit

- **Coverage is measured by textual reference**, so the 24% figure counts a setting as
  "covered" if its name appears anywhere — including in a list of things we do not use. True
  *considered* coverage is lower than 24%, not higher.
- **Twelve subsystems were identified but not read**: `hindsight` (27 settings),
  `mnemopi` (23), `memories` (17), `autolearn`, `autoresearch`, `auto-thinking`, `cleanse`,
  `goals`, `tiny`, `vibe`, `live`, `markit`. Most look irrelevant to a workflow template and
  several are rejected by name already (`reject-005`, `reject-015`), but "looks irrelevant
  from its directory name" is exactly the reasoning `00-method.md §A` warns about.
- **`eval` was read at the bridge layer only.** `eval/py`, `eval/js`, `kernel-base.ts`, and
  `executor-base.ts` were not read, so the G-1 API surface is as-documented plus
  `agent-bridge.ts`, not fully traced.
- **No new claim here is measured.** G-1's viability, G-3's template-branching benefit, and
  G-5's actual severity all need a live session.
- **The 461 uncovered settings were not individually assessed.** I sampled namespaces; a
  full pass could surface a tenth gap.
