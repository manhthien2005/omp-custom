# Dossier — External Agentic TUIs (Amp, Harness, jcode)
> Web research, 2026-08-07. Confidence marked per claim.
> Method: primary sources only (vendor manuals, vendor blog, upstream repo docs read via `gh api`). Web search returned empty for every query this pass; all findings come from direct URL fetch or GitHub API. Anything I did not read is tagged **NOT READ THIS PASS** rather than omitted.

---

## 0. Identification and confidence

| Named by user | What I believe it is | Official URL | Confidence it is the intended tool |
|---|---|---|---|
| **Amp** | Sourcegraph's agentic coding CLI/editor-extension. Modes low/medium/high/ultra, oracle + librarian subagents, thread-centric UX. | https://ampcode.com | **HIGH** — unambiguous, well documented, matches every detail the user cited (oracle subagent, no model picker). |
| **jcode** | `1jehuang/jcode` — Rust terminal coding agent, MIT, self-described "The most RAM efficient harness". 16,291 stars, created 2026-01-05, last push 2026-08-06 (verified via GitHub API 2026-08-07). Vendor: Solo Systems, site https://jcode.sh. | https://github.com/1jehuang/jcode | **HIGH** — a second repo `zin39/jcode` exists but is tiny/derivative; the 16.3k-star Rust project with a native TUI is plainly the referent. |
| **Harness** | **NOT CONFIDENTLY IDENTIFIED.** Four candidates, none a clean match. See §2. | — | **LOW** |

**Important terminology trap:** "harness" is the industry generic term for the scaffold around a model (agent loop, provider wiring, sandboxing, extension model). jcode's own tagline uses it. So "Harness" in the user's list may be the generic sense, a fourth unnamed tool, or one of the candidates in §2. I did not guess. `[Confidence HIGH that the ambiguity is real]`

---

## 1. Amp (Sourcegraph)

Primary sources: the owner's manual https://ampcode.com/manual (read in full this pass), plus vendor posts https://ampcode.com/news/handoff, https://ampcode.com/200k-tokens-is-plenty, https://ampcode.com/news/lazy-load-mcp-with-skills, https://ampcode.com/notes/by-an-agent-for-an-agent, and the Chronicle index at https://ampcode.com/news.

### 1.1 Orchestration model

Single main loop that **spawns subagents on its own judgment**. There is no user-facing "Task" tool in the manual; delegation is a capability of the agent, not a command you issue. `[HIGH — https://ampcode.com/manual]`

- **Subagents** each get "its own context window and access to tools like file editing and terminal commands". They are **isolated**: no inter-subagent communication, no mid-task steering, and the parent "only receives their final summary". Used automatically, "mostly in `medium` mode". You steer fan-out by prompt, e.g. "Convert these 5 files to use Tailwind, use one subagent per file". `[HIGH — /manual]`
- **`oracle`** — a named tool exposing a stronger reasoning model as a read-only second opinion for review, debugging, refactor planning, and next-step decisions. Originally o3, later GPT-5, and routing now varies by mode and linked subscription (e.g. `high` without ChatGPT linked → Claude Fable 5 high reasoning; with it → GPT-5.6 Sol high). "Slightly slower, slightly more expensive." `[HIGH — /manual; MEDIUM on the exact current model mapping, which the manual says changes]`
- **Oracle invocation is deliberately not forced.** Manual: "We intentionally do not force the main agent to _always_ use the oracle." The earlier oracle post gives the reason: "We consciously haven't pushed the oracle too hard in the system prompt, to avoid unnecessarily increasing costs", so they "rely on explicit prompting". `[HIGH on both quotes; MEDIUM on the post's exact URL slug]`
- **Librarian** — subagent for cross-repo code search over public GitHub plus your private repos, default branch only. Iterated repeatedly for speed/cost: "~3x faster and 43% cheaper" (2026-06-18). `[HIGH — /manual + Chronicle index]`
- **`amp review`** spawns "a separate subagent for each check". Checks are Markdown files in `.agents/checks/` with frontmatter `name`, `description`, `severity-default`, `tools`. This is the cleanest reviewer-as-file pattern I found anywhere. `[HIGH — /manual]`
- **Agent-to-agent (2026-07-17).** Agents can now spawn other agents locally, in "orbs", or on another machine, and "send messages and files to each other". Plugin API: `amp.createAgent(...)`, `amp.registerAgentMode(...)`, `amp.getBuiltinAgent(mode)` for `'low' | 'medium' | 'high' | 'ultra'`, `agent.run(...)`, `agent.createThread(...)`; `parentThreadID` "keeps the subagent run connected to the thread that invoked the tool"; `executor: 'orb'` or `{ type: 'runner', id }`. `[HIGH — /manual]`

### 1.2 Context management

The organizing unit is the **thread**, and the discipline is *one thread per task* rather than in-place compression.

- **Compaction was removed and replaced by Handoff.** "We have removed compaction from Amp and replaced it with something that we think works a lot better: Handoff." Two objections: information loss you cannot audit, and a behavioral one — "compaction, we found, encourages long, meandering threads, in which you just compact once you run out of context window, stacking summary on top of summary." Handoff instead takes a stated goal, "analyzes the current thread and generates a prompt to start the new thread, along with a list of relevant files", and hands you that prompt as an **editable draft**. CLI: `/handoff execute phase one of the created plan`. `[HIGH — https://ampcode.com/news/handoff]`
- **Threads reference each other instead of copying.** Mention a thread URL or `@T-...` ID and "Amp will read and extract relevant information to your current task". `@@` searches threads; `amp threads continue` resumes; a `read_thread` tool exists. `[HIGH — /manual + /200k-tokens-is-plenty]`
- **Published token numbers** (from Lewis Metcalf, https://ampcode.com/200k-tokens-is-plenty): one shipped CLI feature was built across **13 connected threads**; largest was **151k output tokens and four user messages**; average **~80k tokens**; summed they approach "one jam-packed 1 million token context window" — same budget, partitioned. Rationale: "Agents get drunk if you feed them too many tokens"; "Long threads are not just worse, they also cost more" (every token resent per request, long-context pricing tiers, cache misses across idle gaps); "Breaking into short threads == breaking into small tasks." `[HIGH]`
- **⚠️ Amp partially reversed this.** That page now carries an **Archived** banner stating auto-compaction makes longer threads work well and going beyond 200k is "fine and productive". So Amp's trajectory is handoff *and* compaction, not handoff instead of compaction. Do not cite the short-thread doctrine as current vendor guidance. `[HIGH — banner read directly]`
- **Lazy loading is the recurring instruction-context pattern:** subtree `AGENTS.md` loads only when a file in that subtree is read; a skill's `name`/`description` stay resident while the body "is loaded only when the skill is invoked"; glob-scoped guidance files load only on a matching read. `[HIGH — /manual]`
- **Tool count is treated as a context cost.** "Too many available tools can reduce model performance." With hard numbers from https://ampcode.com/news/lazy-load-mcp-with-skills: chrome-devtools MCP is 26 tools ≈ **17k tokens ≈ 10% of Opus 4.5's context window**; narrowing to four tools via an `mcp.json` beside `SKILL.md` with an `includeTools` glob list means "taking up **1.5k tokens instead of 17k**". Tool defs "have to be inserted into the context window whether they're used by the agent or not". `[HIGH]`
- **Binary payloads leave the window.** Plugin tools returning screenshots should call `amp.attachments.upload(...)` so "thread state stores a URL instead of the base64 payload" (limits 4.9 MB decoded, 8000px/dimension). `[HIGH — /manual]`
- Subagents are justified partly as context sinks: for "operations producing extensive output not needed after completion". `[HIGH — /manual]`

### 1.3 Tool surface

The manual **deliberately does not enumerate built-ins** — "You can see Amp's builtin tools by running `amp tools list`". Named in prose: `oracle`, `reload_skills`, `read_thread`, with `Grep`/`Read` appearing as values in a checks `tools` array. `project_status` and `focused_review_subagent` are plugin examples, not built-ins. `[HIGH that the manual withholds the list — I could not obtain the full built-in tool list this pass]`

Non-obvious items worth noting: `oracle` (delegate-to-smarter-read-only-model as a *tool*), `read_thread` (cross-session retrieval as a tool), skill-scoped MCP with `includeTools` globs, and `.agents/checks/*.md` (review criteria as frontmattered files, one subagent each). **TODOs were removed** (2026-01-12): "with Opus 4.5, we found it's no longer needed… The agent tracks its own work in a single thread just fine without TODOs… writing down a list of what it was going to do cost time _and_ tokens." `[HIGH]`

### 1.4 Permission model

**Permissive by default**, stated twice in the manual: "By default, Amp does not ask for approval before running tools." The manual names the exposure — untrusted repos and MCP servers "can influence what Amp does" — and points you at a custom policy plugin or an isolated environment. `[HIGH — /manual]`

- Gating is **plugin-implemented**, via the `tool.call` event returning `allow`, `reject-and-continue`, `modify`, or `synthesize`; `ctx.ui.confirm(...)` renders the dialog. The four-valued return (especially `modify` and `synthesize`) is more expressive than a boolean allow/deny. `[HIGH]`
- Shipped example `.amp/plugins/no-destructive-git-operations.ts`: a regex allowlist `safePatterns` covering read-only git plus `add`/`commit`/non-forced `push`; **anything unmatched is classified by `amp.ai.ask(...)`** and prompts only if judged risky. Regex allowlist first, model judgment as fallback. `[HIGH]`
- Legacy `amp.permissions`, `amp.guardedFiles.allowlist`, `amp.dangerouslyAllowAll: false` activate an internal plugin. `amp.tools.disable` accepts names or globs, with `builtin:toolname` to disable only the built-in variant. `[HIGH]`
- **MCP asymmetry:** workspace servers in `.amp/settings.json` "require explicit approval before they can run" (`amp mcp approve my-server`; `awaiting approval` in `amp mcp doctor`), but global or `--mcp-config` servers do **not**. `amp.mcpPermissions` is first-match allow/reject on `url` or `command`/`args`, **defaulting to allow** when nothing matches. `[HIGH]`
- "Plugins run code in your environment, so only load plugins you trust." Multiplayer warns every workspace member reaches "the thread, orb, secrets, files, and terminal." Enterprise-managed settings override user and workspace settings. `[HIGH]`
- https://ampcode.com/news/how-we-think-about-permissions (2025-09-10) exists but is **behind auth — NOT READ THIS PASS**.

### 1.5 Prompt practice

No leaked full system prompt found. What is *published* is prescriptive guidance.

- **"How to Prompt" (in /manual):** be direct — prefer "do X" over "can you do X?"; "Don't try to make the model guess", hand it the files and commands you already know; say "Do not edit any files." for research-only work; push durable guidance into `AGENTS.md`; tell the agent how to check itself, because "Feedback helps agents as much as it helps us." `[HIGH]`
- **Modes abstract models:** "Modes are capability presets, not fixed model selectors." Product stance from "Why Amp?": "Opinionated: You're always using the good parts of Amp" and "On the Frontier: Amp goes where the models take it. No backcompat, no legacy features." The dial low/medium/high/ultra replaced named modes (2026-07-09), and "Who Cares About the Model?" (2026-07-29) reports the default model was swapped with no complaints. `[HIGH]`
- **Write code the model expects to find** — https://ampcode.com/notes/by-an-agent-for-an-agent (Tim Culverhouse, 2025-12-18). Porting libvaxis to TypeScript for the Amp CLI, ~90% agent-written. He renamed the agent's `present()` to `swapScreens()` and then watched the agent repeatedly hunt for its own original name: "Amp spun its wheels because _I_ had interjected with _my_ opinions about code naming, structure, and layout." Lessons: let the agent pick names and file placement so they land on the statistically likely option; accept unfamiliar patterns as the price of predictability; build on vocabulary already dense in model weights (the framework borrows Flutter's Widgets/StatefulWidgets/Intents/Bindings). He is candid about the limits: "Ultimately I don't know _why_ it's so good at using it." `[HIGH]`
- Also on the Chronicle index but **NOT READ THIS PASS**: "How to Pair With an Agent" (quoted snippet: "Trust isn't a feeling. It's a passing test suite."), "Feedback Loopable", "Putting an Agent in an Orb", "Meet Puck" (a meta-agent that helps you use Amp).

### 1.6 What omp-custom should take

1. **Reviewer criteria as frontmattered files, one subagent per check** (`.agents/checks/*.md` → `.omp/agents/*.md` + a `/review` command). Directly maps onto OMP agent defs.
2. **Handoff as an explicit artifact** — goal + generated prompt + *relevant file list*, editable before launch. Lands as `.omp/commands/handoff.md`. Prefer this over summarize-in-place.
3. **Token-accounted lazy tool loading** — bundle MCP behind a skill so definitions stay out of context until invoked; 17k → 1.5k is the kind of number that moves tokens-per-accepted-outcome.
4. **A read-only reviewer role invoked by judgment, not on every turn** — the oracle's cost-aware "don't force it" stance is the right default for a `reviewer` agent in `.omp/agents/`.
5. **Name things the way the model would** — a short `.omp/RULES.md` clause. Free, and Amp's evidence for it is concrete.

---

## 2. Harness — NOT CONFIDENTLY IDENTIFIED

I could not establish which product the user meant. Four candidates, with what I verified about each. `[Overall confidence in identification: LOW]`

**(a) Harness.io — the CI/CD platform. Almost certainly NOT the referent.** `[HIGH]`
https://harness.io/products/harness-ai. Harness AI explicitly positions itself *after* code is written: it "focuses on everything _after_ code is written—the actual bottleneck in software delivery", contrasting itself with Copilot and ChatGPT. Ships "Agentic Flows" — DevOps, SRE, Release, AppSec, Test, FinOps agents plus IDP Knowledge Agent — over a "Software Delivery Knowledge Graph" spanning builds, tests, deployments, incidents, infra changes and spend. Only code-writing surface is the AppSec Agent delivering fixes "directly in the code or as a pull request"; Semantic Code Search reads but does not write. CLI is named once as a surface ("Meets devs in their IDE, chat, CLI") with **no CLI name, install path, or command set anywhere**. There is no terminal coding agent here, so it cannot be the "good TUI" reference point.
*One transferable idea regardless:* Test Intelligence selects only the tests tied to a change, claimed to cut test cycle time "by up to 80%" — a real tokens-per-outcome lever if a verification loop can pick its tests. `[MEDIUM — vendor claim, unverified]`

**(b) `harness-terminal` / `vaishnavisapkale/harness-cli` — is a terminal coding agent, but a portfolio project.** `[HIGH]`
https://github.com/vaishnavisapkale/harness-cli, https://vaishnavisapkale.github.io/harness-cli/. **4 stars, 0 forks, 29 commits, no releases, no other contributors.** MIT, TypeScript on Bun, Ink TUI, `npm i -g harness-terminal`. Standard single agent loop on Gemini (`2.5-flash` default, `/model` to switch), retry-with-backoff, conversation trimming for overflow, headless `harness agent -p "..."`. **Exactly six tools:** `read_file`, `list_file`, `file_exists`, `edit_file` (unique-match edit), `write_file`, `bash`. Permissions: allow-by-default with a **denylist** Y/N gate naming `rm`, `git reset --hard`, `chmod -R`; denial makes the agent "move on without retrying". Nothing here is novel next to the local repo set, and 4 stars makes it implausible as a design reference. `[HIGH]`

**(c) `zhijiewong/openharness` — feature-rich, but low adoption and stale.** `[MEDIUM-LOW that this is the referent]`
https://github.com/zhijiewong/openharness. **97 stars**, TypeScript, MIT, created 2026-03-31, **last push 2026-05-12** (~3 months stale as of today). Invoked as `oh`. If the user did mean this, the interesting parts are: **11 named in-tree subagents** (code-reviewer, test-writer, docs-writer, debugger, refactorer, security-auditor, evaluator, planner, architect, editor, migrator), each restricted to a tool subset; a **two-pass architect → editor split** where the strong model plans and the fast model applies mechanically, claiming "30-50%" savings on multi-file edits; **subagent permissions only narrow** — a requested looser mode is clamped to the parent, so "a model can never use a sub-agent to escape user-approval gates"; 7 permission modes (ask/trust/deny/acceptEdits/plan/auto/bypassPermissions); 44 **risk-tagged** tools with AST safety analysis on Bash raising risk level; pre-mutation checkpoints to `.oh/checkpoints/` with `/rewind` and `/undo`; **temporal-decay memory pruning** (untouched 30+ days sheds 0.1 relevance, deleted below 0.1); 27 hook events with JSON stdin/stdout allow/deny/ask; `--max-budget-usd` hard spend cap halting with `budget_exceeded`; additive parent-first instruction loading from `.oh/RULES.md`, `CLAUDE.md`, `AGENTS.md`. All self-reported (README claims "~95% feature parity" with Claude Code); **I did not read the source**, so treat mechanism claims as **UNVERIFIED**.
*Two ideas here are worth stealing on their merits even without confirming identity:* **permission clamping** (a subagent can never be granted more than its parent) and **budget-cap-as-halt-condition**.

**(d) The generic sense.** "Harness" is standard vocabulary for the agent scaffold — jcode calls itself "the most RAM efficient harness"; a comparison repo argues the differentiator is "the agent loop, provider wiring, sandboxing, and extension model". If the user meant the concept, the answer is §3 and §1, not a separate tool. `[HIGH that the generic usage is pervasive]`

**Recommendation: ask the user which Harness they meant before spending more effort.** Per the task instruction, I am reporting rather than guessing.

---

## 3. jcode (`1jehuang/jcode`)

Sources: https://jcode.sh, the README, and **in-repo docs read directly via `gh api`** — `crates/jcode-base/src/prompt/system_prompt.md`, `docs/SYSTEM_PROMPT_CONFIG.md`, `docs/HOOKS.md`, `docs/SAFETY_SYSTEM.md`, `docs/MEMORY_ARCHITECTURE.md`, `docs/MEMORY_BUDGET.md`, `.jcode/semantic-todo-migration-spec.md`. This is the only tool in this dossier where I read primary source rather than marketing.

### 3.1 Orchestration model

**Parallel sessions are the primary unit, not nested delegation.** `[HIGH]`

- **Swarm** — multiple agents in **one repo**, coordinated by a persistent server (`jcode serve` / `jcode connect`), explicitly **without git worktrees**: the system prompt tells the agent "There may be other jcode agents working in the codebase. The harness handles this natively without git worktrees." If agent A edits a file agent B has already read, **B is notified and can inspect the diff**. Agents get DM, repo-scoped broadcast, and global broadcast. A swarm tool lets the main agent become coordinator and spawn worker teammates, headed or headless; group membership, channels, and completion state are managed for it. Swarm routing guidance is its own overridable file, `.jcode/swarm-prompt.md`. `[HIGH]`
- **Sideagents** — a memory sideagent validates recalled entries and does extra retrieval before injection. Named model: GPT-5.3 Codex Spark as the memory sidecar. `[HIGH — docs/MEMORY_ARCHITECTURE.md]`
- **Auto-poke** — because "Models love to declare victory", the harness checks outstanding todos at end of turn and nudges the model back to work; same mechanism drives headless `jcode run`. Transient network failures retry, non-retryable ones halt. `[MEDIUM — jcode.sh claim; I did not read the implementation]`
- **Self-dev** — the agent edits, builds, tests, and reloads its own binary while sessions continue; they recommend a frontier model since "weaker models can make subtle, breaking changes." `[HIGH that it is documented]`
- **Ambient mode** — periodic memory consolidation, staleness and conflict checks, and the sole current consumer of the safety system.
- Cross-harness resume from codex, Claude Code, opencode, and pi; named resume (`jcode --resume fox`). `[HIGH]`

### 3.2 Context management

- **Append-only to protect the prompt cache.** Stable prefix, tool schemas served from an on-disk cache, **MCP tools advertised up front so late connections never rewrite earlier turns**, and dynamic material (memory recalls, system reminders) positioned "where they do the least damage". User input is interleaved at **KV-cache-safe boundaries**; the UI flags Anthropic cache going cold after 5 minutes and surfaces unexpected cache misses. `[HIGH — README/site; MEDIUM on internals, source NOT READ]`
- **Memory is semantic and never blocks.** Local embeddings (`all-MiniLM-L6-v2`) plus the sidecar. Design decisions, verbatim: "**Fully async and non-blocking** - The main agent never waits for memory; results from turn N are available at turn N+1"; "**Graph-based organization**" (petgraph `DiGraph` with Memory, Tag, and Cluster node types); "**Cascade retrieval** - Embedding hits trigger BFS traversal to find related memories"; "**Hybrid grouping**". Extraction triggers on semantic drift, K turns since last extraction, or session end. The pitch is recall "without actively calling memory tools or being a token burner." `[HIGH — docs/MEMORY_ARCHITECTURE.md, status "Implemented (Core), Planned (Graph-Based Hybrid)"]`
- **Agent grep** — grep results enriched with file structure (function lists, offsets) so the agent can skip full file reads, with harness-level adaptive truncation based on what the agent has already seen. `[HIGH that documented]`
- Skills are lazily injected on embedding hits rather than all loaded at startup. Per-model `context_window`/`context_limit` overrides avoid falling back to a 200k default. `[HIGH]`
- **`docs/MEMORY_BUDGET.md` is a governance pattern worth noting on its own:** an explicit regression budget split into **hard caps** (limits already enforced in code, e.g. `highlight_cache_entries <= 256` from `HIGHLIGHT_CACHE_LIMIT`) and **ratchet expectations** (expected relationships between counters, "allowed only with explanation and updated docs/tests"), each tied to an existing debug counter rather than "guessed RSS numbers". Stated goal: "The goal is not to freeze memory usage forever. The goal is to make memory changes: measurable, reviewable, intentionally justified." That sentence is a near-perfect template for a *token* budget. `[HIGH]`

### 3.3 Tool surface

- **Background tasks are the standout.** Any command can start with `run_in_background`, then be listed, tailed, inspected, cancelled, or waited on. **`wait` unblocks on completion _or_ the next progress checkpoint** instead of sleeping. Foreground commands that exceed their timeout are **adopted into the background rather than killed**, surviving even a binary reload. Progress renders as live cards from `JCODE_PROGRESS` lines or inferred output. `[HIGH that documented]`
- Built-in `browser` tool over Firefox with `status`/`setup`/`open`/`snapshot`/`get_content`/`interactables`/`click`/`type`/`fill_form`/`select`/`wait`/`screenshot`/`eval`/`scroll`/`upload`/`press`. Call summaries avoid echoing sensitive typed text. `[HIGH]`
- Explicit memory tools (search/store), session search for RAG over past sessions, a skill tool for manual activation, swarm/messaging tools. MCP via `~/.jcode/mcp.json` and `.jcode/mcp.json` with Claude Code config compatibility; **stdio only** — HTTP/SSE entries are recognized and skipped; servers connect lazily in background on first call while schemas advertise immediately. `[HIGH]`
- **The semantic todo tool is the most novel thing in this dossier — see §3.5.**

### 3.4 Permission and safety model

Two layers, both read directly.

**Layer 1 — lifecycle hooks (`docs/HOOKS.md`).** Configured in `~/.jcode/config.toml` under `[hooks]`, env-overridable. `turn_end`, `session_start`, `session_end`, `post_tool` are **observers**: "spawned detached, fire-and-forget. They can never block or slow the agent; failures are only logged." `pre_tool` is the one **gate**, running synchronously before every tool call:
- receives `JCODE_HOOK_TOOL_NAME` plus the full tool input JSON **on stdin** (16 KB-truncated copy in env),
- **exit 0** allows, **exit 2** blocks — and critically, "The hook's stderr (trimmed, capped at 2000 chars) is **returned to the model as the tool error, so the model can adapt**",
- **anything else fails open** with a logged warning (other exit codes, 5s default timeout, missing binary, spawn errors).

Fail-open is explicit design, with the reasoning stated: "a broken policy script should degrade to 'no policy' rather than brick every session. If you need fail-closed semantics, make the hook itself robust (it is your trust boundary, not jcode)." `JCODE_HOOKS_DISABLED=1` is always set to suppress hooks in nested jcode calls (recursion guard). `[HIGH — read verbatim]`

**Layer 2 — the safety system (`docs/SAFETY_SYSTEM.md`, status: Design, updated 2026-02-08).** A human-in-the-loop layer for *unmonitored* operation, decoupled so any feature can consume it (currently only ambient mode). **Exactly two tiers: auto-allowed and requires-permission. There is deliberately no "always denied" tier** — "if the user explicitly approves something, the agent can do it." The classification principle is a single sentence worth copying: "**anything that communicates with another human or leaves a trace outside the local sandbox requires permission.**" Tier 1 auto-allowed = "local, reversible, and don't affect anything outside the project sandbox." Supporting machinery: a persistent review queue, notification dispatcher (email, SMS, desktop, webhook, TUI widget), `jcode safety review`, transcript logger, per-session reporter. `[HIGH — read verbatim; note status is Design, not Implemented]`

**Layer 3 — supply chain / credential hygiene** (README): Windows installer verifies against release `SHA256SUMS` and stops rather than silently compiling; `--api-key-stdin` avoids shell history; plain HTTP allowed only for localhost and private LAN ("Public remote HTTP is still rejected"); MCP import warns imported env values "may contain secrets"; uninstall keeps config/auth/sessions by default with `--purge` and `--dry-run`. `[HIGH]`

### 3.5 Prompt practice — the actual system prompt

Unlike Amp, **jcode ships its system prompt in-repo and I read it**: `crates/jcode-base/src/prompt/system_prompt.md`. Claimed at **671 tokens, down 73% from v0.1's 2,476**. Five sections: Identity, Autonomy and persistence, Coding, User interaction. Verbatim lines worth studying:

> "Have autonomy. Persist to completing a task." / "Fix problems over just surfacing them." / "Given a task, complete all the tasks related and relevant to it." / "**Requesting input from user is a blocking action. Use this sparsely.**" / "Don't do anything that the user would regret." / "**Hesitate for destructive or non-reversible actions. Examples: Completing a payment, deleting a database, sending an email.**" / "Never reset a password." / "Commit as you go by default… Even in a dirty repo with actively changing things, try to commit just your changes." / "In a closed feedback loop, keep iterating." / "By default, have concise responses, under 5 lines is a good default." / "Use the todo tool extensively."

Two things stand out. First, **safety is prompt-level and example-driven** (payment / database / email) rather than a regex list — cheap and generalizing. Second, it is **strikingly short**, and the shrink from 2,476 → 671 tokens is treated as a headline feature. `[HIGH]`

**Prompt composition is layered and user-overridable (`docs/SYSTEM_PROMPT_CONFIG.md`), 7 layers in order:** (1) base prompt, replaceable by `./.jcode/system-prompt.md` then `~/.jcode/system-prompt.md`; (2) capability modules (e.g. Mermaid guidance); (3) self-dev guidance, self-dev sessions only; (4) `./AGENTS.md` + `~/AGENTS.md`; (5) prompt overlay `./.jcode/prompt-overlay.md` + `~/.jcode/prompt-overlay.md`; (6) preferred tools `./.jcode/preferred-tools.md` + `~/.jcode/preferred-tools.md`; (7) memory and the active skill prompt — explicitly "**dynamic, not cached**", i.e. the cache boundary is a documented part of the prompt architecture. Guards: "An empty or whitespace-only file falls back to the default, so you cannot accidentally ship an empty prompt"; changes apply to **new sessions only**, a running session keeps the prompt captured at start. `[HIGH]`

**Semantic completion gates (`.jcode/semantic-todo-migration-spec.md`) — the single most valuable find in this dossier.** jcode is migrating its todo tool off 0-100 numeric quality scores onto ordered semantic enums:

```rust
enum IntentUnderstanding { Uncertain, Partial, Clear, Complete }
enum FeedbackLoopState  { Absent, Weak, Usable, Strong, Closed }
enum ConfidenceState    { Speculative, Plausible, Validated, Verified }
enum Difficulty { Trivial, Routine, Involved, Complex, Hard, Expert, Research, OpenEnded }
enum Autonomy   { RequestedOnly, NecessaryFollowthrough, Proactive, Stewardship }
enum DeliveryState { ChangeMade, Integrated, WorkflowValidated, OutcomeDelivered }
```

The gate semantics are the interesting part, verbatim from the spec: "**Never reject a write. All existing 'deferred observation + turn-end digest + continuation' plumbing stays**, only comparisons change."
- Intent gate passes at `>= Clear`; severe first-write nudge when `== Uncertain`.
- Feedback loop gate passes only at `Closed`.
- Completion confidence gate passes at `>= Validated`.
- **Confidence spike:** a completed todo is "spike-finished" when its final history step **jumps 2 or more levels** (e.g. Speculative → Validated) — which triggers forced re-verification.
- **Delivery gate is calibrated by difficulty:** `None | Trivial | Routine` → `WorkflowValidated` or better; `Involved` and above → `OutcomeDelivered`. "**Difficulty itself is never a gate**"; absent difficulty just uses the lenient bar. Autonomy is "never gated anywhere. Display/telemetry only."

So: the agent self-assesses on ordered scales, writes always succeed, and mismatches produce *continuations* (more work) rather than errors. jcode.sh claims **92% vs 88% pass rate on completed Terminal-Bench 2.1 trials** from confidence stepping, and for the predecessor hill-climbability score a mean of **91.29 across 2,012 ratings with 18% falling below the gate**. `[HIGH on the spec — read verbatim. MEDIUM-LOW on the benchmark deltas — vendor self-report, single machine, no methodology published.]`

### 3.6 What omp-custom should take

1. **Semantic completion gates that never block a write** — the highest-value pattern here for tokens-per-accepted-outcome.
2. **`pre_tool`-style single deterministic gate whose block reason is fed back to the model as a tool error.**
3. **Prompt layering with a documented cache boundary** — static layers cached, memory/skill layers explicitly not.
4. **Example-driven destructive-action hesitation in the prompt** (payment / database / email) instead of a regex list.
5. **A regression budget doc** split into hard caps and ratchet expectations, tied to counters that already exist.

*Skip* the RAM/startup benchmarks (27.8 MB PSS vs 386.6 MB Claude Code; 14.0 ms to first frame vs 3436.9 ms; 10 sessions 117 MB vs 2300.6 MB). Self-reported on one Linux machine, and irrelevant to a token target. `[HIGH that these are self-reported and unverified]`

---

## 4. Cross-cutting patterns worth adopting

| Pattern | Source tool | Evidence + URL | Conf. | OMP-native landing artifact | Verdict |
|---|---|---|---|---|---|
| **Semantic completion gates: agent self-rates on ordered enums; writes never rejected, mismatch emits a continuation; delivery bar scaled by declared difficulty** | jcode | `.jcode/semantic-todo-migration-spec.md` via https://github.com/1jehuang/jcode — "Never reject a write… gates only emit continuations" | HIGH (spec) / LOW (benchmark) | `.omp/rules/completion-gates.md` defining the enums + `.omp/hooks/post/*` emitting the continuation | **ADOPT** |
| **Confidence-spike re-verification: a 2+ level jump between planning and completion forces re-check** | jcode | same spec, "spike-finished when its final history step jumps 2 or more levels" | HIGH | same hook; one predicate | **ADOPT** |
| **Handoff artifact = stated goal + generated prompt + relevant file list, editable before launch** | Amp | https://ampcode.com/news/handoff | HIGH | `.omp/commands/handoff.md` | **ADAPT** — Amp later re-added auto-compaction, so treat as a complement to compaction, not a replacement |
| **One deterministic pre-tool gate; blocked call returns its reason to the model as a tool error so the model adapts; fails open by design** | jcode | `docs/HOOKS.md` — "returned to the model as the tool error, so the model can adapt"; "Fail-open is deliberate" | HIGH | `.omp/hooks/pre/*` | **ADOPT** (gate + model-visible reason). **ADAPT** fail-open: for destructive tools omp-custom should fail *closed* |
| **Token-accounted lazy tool loading: MCP defs hidden behind a skill until invoked** | Amp | https://ampcode.com/news/lazy-load-mcp-with-skills — 26 tools ≈17k tokens ≈10% of window → 1.5k with 4 tools | HIGH | `.omp/skills/<name>/SKILL.md` + scoped `mcp.json`; tool disable in `.omp/config.yml` | **ADOPT** |
| **Review criteria as frontmattered files, one subagent per check** | Amp | /manual — `.agents/checks/*.md` with `name`, `description`, `severity-default`, `tools`; "a separate subagent for each check" | HIGH | `.omp/agents/check-*.md` + `.omp/commands/review.md` | **ADOPT** |
| **Read-only reviewer/oracle invoked on judgment, not every turn, for explicit cost reasons** | Amp | /manual "We intentionally do not force the main agent to _always_ use the oracle" | HIGH | `.omp/agents/oracle.md`, referenced conditionally from `.omp/AGENTS.md` | **ADOPT** |
| **Prompt layering with an explicit cache boundary — static layers cached, memory/skill layers marked "dynamic, not cached"** | jcode | `docs/SYSTEM_PROMPT_CONFIG.md`, 7 ordered layers | HIGH | `.omp/AGENTS.md` + `.omp/RULES.md` ordering, documented in `.omp/config.yml` | **ADOPT** |
| **Example-driven destructive hesitation in the system prompt** ("payment, deleting a database, sending an email"; "Never reset a password") | jcode | `crates/jcode-base/src/prompt/system_prompt.md` | HIGH | `.omp/RULES.md` | **ADOPT** — a few tokens, generalizes past any regex list |
| **Blocking-the-user is a costed action** ("Requesting input from user is a blocking action. Use this sparsely.") | jcode | same prompt file | HIGH | `.omp/RULES.md` | **ADOPT** |
| **Regression budget: hard caps tied to real counters + ratchet expectations changeable only with written justification** | jcode | `docs/MEMORY_BUDGET.md` — "measurable, reviewable, intentionally justified" | HIGH | `spec/` budget doc + a `.omp/commands/budget-check.md` | **ADOPT**, retargeted from memory to tokens |
| **Four-valued tool interception `allow / reject-and-continue / modify / synthesize`** | Amp | /manual, plugin `tool.call` event | HIGH | `.omp/hooks/pre/*` return contract | **ADAPT** — `modify` and `synthesize` are strictly better than deny for saving a turn |
| **Regex allowlist first, model judgment only on the unmatched remainder** | Amp | /manual, `.amp/plugins/no-destructive-git-operations.ts` `safePatterns` + `amp.ai.ask(...)` | HIGH | `.omp/hooks/pre/bash` | **ADOPT** — cheap path stays deterministic |
| **Permission clamping: a subagent can never hold looser permissions than its parent** | openHarness | https://github.com/zhijiewong/openharness — "a model can never use a sub-agent to escape user-approval gates" | MEDIUM (README only) | `.omp/agents/*.md` frontmatter convention + `.omp/RULES.md` | **ADOPT** as an invariant |
| **Budget cap as a halt condition** (`--max-budget-usd` → `budget_exceeded`) | openHarness | same | MEDIUM | `.omp/config.yml` + `.omp/hooks/pre/*` counter | **ADAPT** |
| **Write code the model expects: let the agent name and place things** | Amp | https://ampcode.com/notes/by-an-agent-for-an-agent — "Amp spun its wheels because _I_ had interjected with _my_ opinions about code naming" | HIGH | `.omp/RULES.md` | **ADOPT** |
| **Write-collision notification: if agent A edits a file agent B already read, B is told and can see the diff** | jcode | README "Swarm" | HIGH (documented) | Needs OMP server support; nearest fit is a `.omp/hooks/post/edit` stamp + a staleness check in `.omp/hooks/pre/edit` | **ADAPT** — the *staleness check* is portable even though the notification bus is not |
| **Enriched grep: return file structure (symbols, offsets) with matches so the agent can skip full reads** | jcode | README "agent grep" | MEDIUM (no source read) | `.omp/tools/agentgrep` | **ADAPT** — serena covers symbol lookup; the merge of grep + structure + adaptive truncation is the delta |
| **Background task with `wait` that unblocks on the next progress checkpoint, and timeout-adoption instead of kill** | jcode | https://jcode.sh | MEDIUM | `.omp/tools/*` wrapper | **ADAPT** if long builds/tests are in the loop |
| **Change-scoped test selection** (run only tests tied to the diff) | Harness.io Test Intelligence | https://harness.io/products/harness-ai — "up to 80%" cycle-time cut | MEDIUM (vendor claim) | `.omp/commands/verify.md` | **ADAPT** |
| **Two-tier permission classification with no "always denied" tier, and a one-sentence rule: anything that reaches another human or leaves the local sandbox needs approval** | jcode | `docs/SAFETY_SYSTEM.md` | HIGH (doc status: Design) | `.omp/RULES.md` + `.omp/hooks/pre/*` | **ADOPT** — the sentence is a better classifier than an enumerated list |

---

## 5. Patterns explicitly NOT worth adopting

- **Permissive-by-default tool execution** (Amp: "By default, Amp does not ask for approval before running tools"). Correct for a hosted product optimizing flow; wrong for a production-grade workflow that must gate destructive actions. **REJECT.** `[HIGH]`
- **MCP permission asymmetry** (Amp: workspace servers need approval, global and `--mcp-config` servers do not; `amp.mcpPermissions` defaults to allow on no match). Default-allow on no match is a footgun. **REJECT.** `[HIGH]`
- **jcode's fail-open `pre_tool` for destructive tools.** Their reasoning is sound for a general harness, but omp-custom should fail closed on write/delete/network. **REJECT as a blanket default; keep fail-open for read-only tools.** `[HIGH]`
- **Dropping explicit TODO/plan state** (Amp, 2026-01-12: "with Opus 4.5, we found it's no longer needed… cost time _and_ tokens"). Directly contradicted by jcode, which made the todo tool the centerpiece of its quality gates and says "Use the todo tool extensively." Conflicting vendor evidence, so **do not act on either** — keep plan state, but keep it cheap. `[HIGH that the two vendors conflict]`
- **The short-threads-only doctrine.** The source page is now archived by its own publisher, who states >200k is "fine and productive". Cite the *cost mechanics* (resend, long-context tiers, cache misses) — those still hold — not the conclusion. **REJECT the conclusion.** `[HIGH]`
- **Self-dev binary reload** (jcode). Fascinating, irrelevant: OMP is the fixed runtime and omp-custom must not modify it. **REJECT.** `[HIGH]`
- **RAM/startup-latency optimization as a design axis.** jcode's headline numbers are self-reported and orthogonal to tokens-per-accepted-outcome. **REJECT.** `[HIGH]`
- **Parallel-sessions-as-primary-unit / swarm server.** Needs a coordination server OMP does not have; standing up one would violate the single-runtime constraint. **REJECT the mechanism**, keep the staleness-check idea from §4. `[HIGH]`
- **Model routing and mode/model-picker design** (Amp's dial, "Who Cares About the Model?"). A runtime config concern, not an omp-custom artifact. **REJECT as out of scope**, though the underlying stance — capability presets over model names — is a reasonable way to name `.omp/agents/*`. `[HIGH]`
- **`harness-terminal` as a design reference.** 4 stars, 29 commits, 6 tools, denylist gating. Nothing the local repo set lacks. **REJECT.** `[HIGH]`

---

## 6. Gaps — what I could not verify

**Identification**
- **Which "Harness" the user meant is unresolved.** Four candidates in §2, none a confident match. This needs a one-line clarification from the user; further web research is unlikely to resolve it.

**Search tooling**
- **Every web-search query this pass returned empty results.** All findings came from direct URL fetch and the GitHub API. The Amp Chronicle index and the jcode repo tree partly compensated, but there is no independent third-party coverage in this dossier — **no claim here has been cross-checked against a source outside the vendor's own materials**, except star counts and commit dates from the GitHub API.

**Amp**
- **Full built-in tool list: NOT OBTAINED.** The manual deliberately withholds it ("run `amp tools list`"), and I have no Amp install.
- https://ampcode.com/news/how-we-think-about-permissions (2025-09-10) is **behind auth — NOT READ**. That is the primary source for Amp's permission philosophy and the biggest single gap in §1.4.
- **Amp's actual system prompt: NOT FOUND.** No leak located. §1.5 is published *guidance about* prompting, not the prompt.
- Several Chronicle posts **NOT READ THIS PASS**: "How to Pair With an Agent", "Feedback Loopable", "Putting an Agent in an Orb", "Meet Puck", "Context Management in Amp" (the guide — this one likely contains more than the manual and is the highest-value unread item), "Amp Now Reads Threads", "Agentic Review", "Liberating Code Review", "Thread Map", "1,000,000 Tokens", "Go Dep", "The Dial".
- Several `/news/<slug>` URLs 404'd, so **exact URL slugs for the handoff, oracle, and todos-are-done posts are MEDIUM confidence** even though I read their content. The Chronicle index at https://ampcode.com/news is the reliable entry point.
- **Current mode→model mapping is a moving target** by the manual's own admission. Do not treat the Fable 5 / GPT-5.6 Sol details as durable.

**jcode**
- **No Rust source read.** All jcode mechanism claims rest on in-repo Markdown docs, which are design/spec documents. Notably `docs/SAFETY_SYSTEM.md` is **status: Design**, so the review queue and notification dispatcher may not exist in shipped code.
- **The semantic-todo spec is a migration spec ("worker handoff")** — it describes the target state. I did not confirm the enums are merged; `crates/jcode-task-types/src/lib.rs` and `crates/jcode-base/src/todo.rs` matched the search but were **NOT READ**.
- **All jcode performance and quality numbers are unverified vendor self-reports** on one machine: 92% vs 88% Terminal-Bench 2.1, hill-climbability mean 91.29 / 2,012 ratings, jcode bench v1 float-print +8.64 vs +7.17, and every RAM/latency figure. No published methodology found.
- **671-token system prompt claim: NOT INDEPENDENTLY MEASURED.** I read the file and it is plainly short, but I did not tokenize it.
- Not read: `docs/AMBIENT_MODE.md`, `docs/SERVER_ARCHITECTURE.md`, `docs/MULTI_SESSION_CLIENT_ARCHITECTURE.md`, `docs/REMOTE_HANDOFF.md`, `docs/SPAWN_HOOK.md`, `docs/HARNESS_API_AND_DESKTOP_REWRITE.md`, `docs/DISCOVERY_ELICITATION_SPEC.md`, `docs/RETENTION_READINESS.md`, and `.jcode/swarm-prompt.md`. The discovery/elicitation and ambient docs look most likely to contain further transferable patterns.

**openHarness**
- Everything in §2(c) is README-level and **UNVERIFIED by source**. The "30-50% savings" from the architect→editor split and "~95% feature parity" are self-assessments. The repo has been stale since 2026-05-12.

**Not investigated at all** (surfaced in listings, could be relevant to a "good TUI" brief): Charm's Crush, xAI's Grok Build, Poolside's `pool`, Zap (skill-first context injection, SQLite symbol index), Smelt, Waveloom, MiMo Code, Devon.
