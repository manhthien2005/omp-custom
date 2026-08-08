# Repo Report — context7

> **Path:** `_research/upstreams/context7`
> **SHA:** `8d52608e4e27557e6c1e807c8241cffb5544a9a3` (`git -C context7 rev-parse HEAD`)
> **License:** **MIT** — `LICENSE` at root: *"The MIT License (MIT) / Copyright (c) 2021
> Upstash, Inc."* A second copy at `packages/mcp/LICENSE` (20L). Matches
> `registry/upstreams.yml:499`. No correction needed.
> **Size:** 390 tracked files (`git ls-files | wc -l`)
> **Read this pass:** **first time this repo's source has been opened.**
> `packages/mcp/src/index.ts` **in full** (587L) · `packages/mcp/src/lib/api.ts` **in full**
> (175L) · `packages/mcp/src/lib/utils.ts` **in full** (117L) ·
> `packages/mcp/src/lib/types.ts` **in full** (47L) ·
> `packages/mcp/src/lib/constants.ts` **in full** (22L) ·
> `skills/find-docs/SKILL.md` **in full** (159L) · `skills/context7-mcp/SKILL.md` **in full**
> (56L) · `rules/context7-mcp.md` **in full** (11L) ·
> `plugins/claude/context7/agents/docs-researcher.md` **in full** (41L) ·
> `plugins/cursor/context7/rules/use-context7.mdc` **in full** (18L) ·
> `plugins/context7-power/POWER.md` (first 40L).

---

## 1. What this repo is

A **hosted documentation retrieval service** plus the client surface that reaches it: an MCP
server (`packages/mcp`), a CLI (`packages/cli`), and the same instructions packaged eight ways
for eight different agent hosts (`skills/`, `rules/`, `plugins/claude|codex|copilot|cursor`).

The important structural fact: **the retrieval intelligence is not in this repo.** Both tools
are thin `fetch` wrappers around `https://context7.com/api/v2/{libs/search,context}`
(`api.ts:116,149`). Ranking, snippet selection, and reranking all happen server-side. What *is*
here, and what is worth reading, is a **worked example of the persistent-tier cost of adding
one MCP server** — measurable, in a repo small enough to count.

Its verdict was `Conditional` / `D-conditional` with `adopted_mechanisms: []`. This read
**confirms** that verdict and supplies the number the argument was missing.

---

## 2. Mechanism inventory

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| C1 | **Two-step resolve-then-fetch protocol** | `resolve-library-id(libraryName, query)` → `/org/project`; then `query-docs(libraryId, query)`. Fetch is refused without a resolved ID unless the user supplied one literally | `index.ts:174-308` (`:180`, `:270` state the obligation) | **A** |
| C2 | **Hallucinated-argument aliasing** | A `z.preprocess` step rewrites wrong-but-plausible arg names before Zod validation: `query` ← `userQuery`/`question`; on `query-docs` only, `libraryId` ← `context7CompatibleLibraryID`/`libraryID`/`libraryName` | `index.ts:109-145` (map `:114-123`, rewriter `:129-145`, wiring `:211,273`) | **A** |
| C3 | **Tool-scoped vs global alias sets** | `libraryName` is *canonical* on `resolve-library-id` and a *hallucination* on `query-docs`, so aliasing is scoped per tool rather than global | `index.ts:118-123` + comment `:118-120` | **A** |
| C4 | **Self-imposed call cap in the description** | "Do not call this tool more than 3 times per question" — a budget stated in prose, enforced only by the model's compliance | `index.ts:210,272`; repeated `find-docs/SKILL.md:51` | **A** |
| C5 | **Negative routing clause** | Server instructions name what *not* to use it for: refactoring, scripts from scratch, business-logic debugging, code review, general concepts | `index.ts:170`; `rules/context7-mcp.md:3` | **A** |
| C6 | **Anti-overconfidence routing clause** | "Use even when you think you know the answer — your training data may not reflect recent changes. Prefer this over web search for library docs." | `index.ts:168`; `find-docs/SKILL.md:14-17` | **A** |
| C7 | **Numeric score → interpretable label** | `trustScore` is mapped to `High` (≥7) / `Medium` (≥4) / `Low` / `Unknown` (<0 or absent) before reaching the model, rather than exposing the raw number | `utils.ts:9-16` | **A** |
| C8 | **Suppress invalid fields rather than emit sentinels** | `totalSnippets === -1`, `benchmarkScore <= 0`, empty `versions` are **omitted** from the formatted result instead of printed as `-1`/`0` | `utils.ts:33-50` | **A** |
| C9 | **Selection rubric shipped with the results** | The description tells the model how to choose: name match, description relevance, snippet count, source reputation, benchmark score — the same rubric restated in every client copy | `index.ts:191-208`; `find-docs/SKILL.md:79-90`; `docs-researcher.md:21-24` | **A** |
| C10 | **One-concept-per-query rule** | Multi-topic queries "dilute ranking and return shallow results for each topic", so split into one call per concept — *unless* the question is about how the concepts interact | `index.ts:284`; `find-docs/SKILL.md:118,158`; `docs-researcher.md:38` | **A** |
| C11 | **Query-quality table with negative examples** | Good/Bad table: `"How to set up authentication with JWT in Express.js"` vs `"auth"`, `"hooks"`, `"routing and auth and caching in Next.js"` | `find-docs/SKILL.md:120-128` | **A** |
| C12 | **Do-not-send-secrets clause in the parameter schema** | The prohibition on API keys/credentials/proprietary code lives in the **`.describe()` of the parameter itself**, not only in prose docs | `index.ts:217,284` | **A** |
| C13 | **Explicit no-silent-fallback rule** | On quota exhaustion: tell the user, suggest auth, and if answering from training data, *say so.* "Do not silently fall back to training data — always tell the user why Context7 was not used." | `find-docs/SKILL.md:144-151` | **A** |
| C14 | **Actionable error messages keyed to status** | 429 → different text depending on whether an API key was present; 404 → "try a different library ID"; 401 → "keys should start with `ctx7sk`" | `api.ts:25-37` | **A** |
| C15 | **Empty-response recovery hint** | An empty (not failed) body returns prose telling the model the likely cause is an invalid library ID and to re-run `resolve-library-id` | `api.ts:163-168` | **A** |
| C16 | **Errors returned as tool content, not thrown** | Both API functions catch and return `{results: [], error}` / `{data: errorMessage}`, so the model sees a readable failure instead of a transport exception | `api.ts:124-135,157-174` | **A** |
| C17 | **MCP tool annotations** | `readOnlyHint: true`, `destructiveHint: false`, `openWorldHint: true`, `idempotentHint: true` on both tools | `index.ts:226-231,288-293` | **A** |
| C18 | **Delegated-subagent pattern for retrieval** | `docs-researcher` — a `model: sonnet` subagent whose stated purpose is "fetching library documentation **without cluttering your main conversation context**", returning a summary | `docs-researcher.md:1-11,41` | **A** |
| C19 | **Stateless per-request server construction** | HTTP mode builds a fresh `McpServer` per request, no session store; `responseMode: "sse"` flushes headers immediately because some clients cap the fetch at 60 s waiting for headers | `index.ts:364-377` | **A** |
| C20 | **Capability declaration to satisfy unconditional clients** | Declares empty `prompts`/`resources` capabilities so the SDK installs `*/list` handlers for clients that request them regardless | `index.ts:162-167` | **A** |
| C21 | **Eight-way instruction fan-out** | The same routing content in `skills/` (3), `rules/` (2), and `plugins/` for claude, codex, copilot, cursor, plus a `POWER.md` | `skills/**`, `rules/**`, `plugins/**` | **A** |
| C22 | **Teamspace filter disclosure** | When server-side library filters narrowed the results, the response says so and links to the policy dashboard | `utils.ts:74-78` | **A** |

---

## 3. Transferable to omp-custom

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| **C13** | `explorer.md`; `spec/07 §B` level-5 disclosure rule | per-spawn | **ADOPT** | `spec/07:164` already requires disclosure for level 5 (web). C13 is the same rule one level earlier and stated as a **prohibition on silent degradation**, which is cross-layer invariant #8 in `01-dna.md` ("fail loudly"). Cheapest correctness item here |
| **C10 C11** | `explorer.md` query-formation guidance | per-spawn | **ADOPT** | One-concept-per-query with a *reason* ("multi-topic queries dilute ranking"), plus a negative-example table. Applies to our `grep`/`lsp` queries, not just Context7 — the failure mode is identical |
| **C5 C6** | `.omp/skills/*/SKILL.md` `description` fields | zero (already paid) | **ADOPT as description craft** | A description that names both **when to use** and **when not to** is the shape `agent-skills` and `Agent-Skills-for-Context-Engineering` argue for; this is a third independent instance. C6's anti-overconfidence framing is the specific wording worth copying for `evidence-before-completion` |
| **C7 C8** | worker `output:` frontmatter; Explorer result formatting | per-spawn | **ADOPT as a result-shape rule** | Two rules: map raw scores to labels the model can act on, and **omit** invalid fields rather than emitting `-1`. Our SD-11 Explorer result ("name what you excluded") gains a companion: *do not emit placeholder values for what you could not determine.* Prevents a model reasoning over `-1` as if it were a score |
| **C14 C15 C16** | `verifier`/`implementer` failure path; KD-020 | per-action | **ADOPT — reinforces SD-13** | Independent corroboration of `aider`'s A21/A22: a failure message should name the likely cause and the next action. C16 (return errors as content, never throw) matters for us because OMP's `task` path is **silent** on some failures (`spec/08`); a worker that returns a readable error beats one that dies. Folds into the proposed **SD-13** |
| **C18** | `/orchestrated` topology — a cheap retrieval subagent | per-spawn | **ADAPT — and note it is already our shape** | `docs-researcher` is our Explorer's purpose stated in one line: isolate retrieval in a subagent so the main context stays clean, and route it to a **cheaper model**. Grade-A corroboration for `spec/09` model routing + L2 topology, from a repo that ships it |
| **C12** | Any tool/skill our workers call with free-text input | zero | **ADOPT as convention** | Put the do-not-send-secrets prohibition in the **parameter description**, where it is read at call time, not in a policy doc nobody loads. Directly relevant to `spec/15`; and it is the anti-`policies/` lesson in miniature |
| **C2 C3** | — (**no OMP primitive**; we author no tool schemas) | — | **REJECT, retain the insight** | We cannot use `z.preprocess`. But C2 records something valuable and measurable: models emit argument names copied from *prose in the description* rather than the schema keys. That is an argument for keeping our `output:` field names identical to the words used in the prompt — a **naming discipline**, not a mechanism |
| C1 C4 | — | — | **REJECT** | C1 is this service's API shape. C4 is a budget in prose with no enforcement — precisely what G-6 (`+Nk!` turn budget) does properly at the runtime level. Worth citing as the weak form |
| C9 | — | — | **DEFER** | A selection rubric shipped alongside results is a good idea whose value depends on the fields being trustworthy. Trigger: if we ever return ranked candidates from a retrieval step, C9 is the shape for telling the consumer how to choose |
| C17 | — | — | **REJECT (informational)** | MCP-protocol annotations. Noted only because `readOnlyHint`/`idempotentHint` are the sort of metadata our `tools:` allowlists express differently (OQ-E) |
| C19 C20 C22 | — | — | **REJECT** | Server implementation and hosted-service concerns. C19's 60 s header-flush detail is a real-world constraint on long-running MCP tools worth remembering if we ever add one |
| C21 | — | — | **REJECT (negative finding)** | See §4. Eight copies of one instruction set is the distribution problem, and for us it would be duplicated cost |

**Net new mechanisms for the spec: 0.** Confirms `02-repo-synthesis.md`'s `Conditional` /
`Net new: 0`. The retrieval capability stays at **position 4** in `spec/07 §B`.

**Net new for craft and for the MCP cost argument: substantial.** C13 and C7/C8 are genuine
result-shape rules we did not have; C14–C16 reinforce SD-13 from a second independent source;
and §6 supplies the first **measured** persistent-tier figure for an MCP server anywhere in
this corpus.

---

## 4. What this repo does that we deliberately will not

- **Ship the same instructions eight times.** `skills/find-docs` (1,116 words),
  `skills/context7-cli` (414), `skills/context7-mcp` (410), `rules/context7-cli` (344),
  `rules/context7-mcp` (~150), plus four plugin copies and a `POWER.md`. Correct for a vendor
  serving eight hosts; for us it is duplicated persistent cost. Same finding as
  `andrej-karpathy-skills` K9, at four times the scale — and note the **G-8 consequence**: a
  project with `plugins/cursor/context7/rules/use-context7.mdc` present is feeding OMP an
  `alwaysApply: true` rule through a foreign discovery provider, unbidden.
- **State a budget in prose and call it a cap.** C4's "do not call more than 3 times" is
  advisory. OMP's `+Nk!` turn budget (G-6) makes `agent()` *refuse to spawn*. The contrast is
  worth recording because our own spec has prose-budget language in places where G-6 would be
  enforceable.
- **Put retrieval judgment behind a network boundary.** All ranking is server-side
  (`api.ts:116,149`), unversioned, and unobservable. For a docs lookup at position 4 that is
  an acceptable trade. For anything a verification gate depends on, it is not — an
  unreproducible ranker cannot back a ratchet (`spec/13`).
- **Trust a `description` to bound behavior.** C4, C9, and C10 are all enforcement-by-prose.
  We keep them as *guidance* and refuse to count them as gates. This is the same distinction
  as the round-11 observation-vs-enforcement finding.
- **Route around the schema instead of fixing the prompt.** C2 is a pragmatic patch for a real
  problem; the root cause is that the description's prose uses different words than the schema
  keys. Our version of the fix is naming discipline, not an alias table.

---

## 5. Contradictions with our current spec or registry

### 5-1. `registry/upstreams.yml:508-509` — stale `local_components` (KD-001)

```yaml
local_components:
  - template/.omp/policies/context-budget.yml  # retrieval-order policy
```

KD-001 removes `.omp/policies/` from the installed surface. This is the **third** of the four
stale entries already catalogued in `02-repo-synthesis.md §G` ("Registry corrections beyond
SD-1 and SD-10"), and this read confirms it independently. Correct destination: `docs/` plus
the retrieval-order text now living at `spec/07 §B:151-165`. **No new finding — confirmation.**

### 5-2. `registry/upstreams.yml:503-504` — watched path is too narrow to be useful

```yaml
watched_paths:
  - README.md
```

The root `README.md` is marketing and install instructions. Everything we actually depend on —
the **tool surface** — lives in `packages/mcp/src/index.ts`, and the routing content lives in
`skills/` and `rules/`. If Context7 renamed a tool or changed the two-step protocol, watching
`README.md` would probably catch it late and might not catch it at all.

Recommended: `packages/mcp/src/index.ts`. Zero cost.

This is now the **fourth** watched-path defect found by hand (SD-1 `packages/**`, SD-10
`anthropics/skills` `spec/`, aider's non-existent `docs/repomap.md`, and this one). Four is
enough to stop treating them as individual corrections: **`spec/14` needs a check that every
`watched_paths` entry resolves at the pinned SHA**, and that the paths named cover the
mechanism the entry claims authority for. Proposed as part of the SD-1 cluster rather than a
new delta.

### 5-3. `spec/07 §B:158` — "via MCP" is now an over-specification

```
4. Context7 (version-specific library docs via MCP)
```

There are **two** transports at this SHA: the MCP server *and* a CLI (`npx ctx7@latest`,
`find-docs/SKILL.md:24-29`). The CLI path is materially cheaper for us, because MCP tool
descriptions are persistent-tier for every session **including every subagent**
(`06-investment-thesis.md §F-1`), whereas a `bash` invocation costs only the skill body, and
only when the skill loads.

Given §6's measurement, the level-4 entry should read "Context7 (version-specific library
docs)" with transport left open, and the transport choice recorded as a cost decision. This
does not change the retrieval *order* — position 4 is unaffected.

### 5-4. `06-investment-thesis.md §F-1` — the argument is right and was unmeasured

> "The cost is not the tokens — it is that **every MCP tool's description is persistent
> tier**… 20 more descriptions in every session, including every subagent."

Correct, and now quantified for the smallest realistic server (§6): **~940 tokens estimated,
for two tools.** The thesis says "the cost is not the tokens"; the measurement suggests the
tokens are, in fact, a substantial part of it — ~78–157% of our entire `AGENTS.md` budget for
one two-tool server. That strengthens F-1's conclusion while correcting its framing. Worth
patching, because "the cost is not the tokens" invites a reader to think the tokens are
negligible.

### 5-5. No contradiction with KD-015 or `01-dna.md` L4

Context7 does no local ranking, so it is orthogonal to the ranking gap. L4 Retrieval
(`lsp · grep · read ranges`) is unaffected; position 4 sits outside it.

---

## 6. Cost profile

**The measurement.** Word counts extracted from `packages/mcp/src/index.ts` by parsing the
template literals and `.describe()` calls:

| Persistent-tier item | Words | Est. tokens |
|---|---|---|
| Server `instructions` (`:168-170`) | 95 | ~130 |
| `resolve-library-id` description (`:178-210`) | 305 | ~410 |
| `query-docs` description (`:268-272`) | 65 | ~90 |
| 4 parameter `.describe()` strings (`:217,222,279,284`) | 231 | ~310 |
| **Total for a two-tool server** | **696** | **~940** |

Token figures are **estimates** at ~1.35 tok/word for English prose. Word counts are exact.

What that number means against `01-dna.md`'s budgets:

- `AGENTS.md` budget is **600–1,200 tok**. This one MCP server costs **~78–157% of the entire
  constitution** — and unlike `AGENTS.md`, it is paid by **every subagent spawn** as well.
- With our topology (Tech Lead + Explorer + Implementer + Verifier + reviewer), a single
  two-tool server is ~940 tok × 5 contexts ≈ **~4,700 tok per orchestrated run**, before any
  documentation is retrieved.
- Scaling F-1's hypothetical: a 20-tool server at this description density would be
  **~9,400 tok persistent**, which exceeds our entire L0 + L5 budget several times over.

Costs of the §3 rows, by contrast:

| §3 row | Tier | Cost |
|---|---|---|
| C13 (no-silent-fallback) | per-spawn | ~25 tok. One sentence |
| C10 C11 (query formation) | per-spawn | ~80–120 tok **estimate** — the rule plus a trimmed 4-row table |
| C7 C8 (result-shape rules) | zero | Authoring rules for `output:` frontmatter. No text added to any context |
| C5 C6 (description craft) | zero | Rewrites existing `description` fields; does not lengthen them |
| C12 (secrets clause placement) | zero → relocates | Moves an existing prohibition into the place it is read |
| C14–C16 (SD-13 reinforcement) | per-action, on failure | Same profile as aider's A21/A22 — likely net-negative, since a scoped retry replaces a blind one |
| **Adopting Context7 itself (MCP transport)** | **persistent × every context** | **~940 tok, measured above** |
| **Adopting Context7 via CLI** | **lazy** | Skill body only, on load. `find-docs/SKILL.md` is 1,116 words ≈ **~1,500 tok**, but paid **once on invocation**, in one context — not per spawn |

The transport comparison is the actionable result: **the CLI path costs more per load and
vastly less per session**, because it is lazy and single-context rather than persistent and
per-spawn. For a position-4 retrieval source consulted rarely, lazy is the correct tier. That
is a decision `spec/07` should record (§5-3) and currently does not.

---

## 7. Coverage and limits  (MANDATORY)

**Files read in full (10):** `packages/mcp/src/index.ts` (587L) ·
`packages/mcp/src/lib/api.ts` (175L) · `packages/mcp/src/lib/utils.ts` (117L) ·
`packages/mcp/src/lib/types.ts` (47L) · `packages/mcp/src/lib/constants.ts` (22L) ·
`skills/find-docs/SKILL.md` (159L) · `skills/context7-mcp/SKILL.md` (56L) ·
`rules/context7-mcp.md` (11L) · `plugins/claude/context7/agents/docs-researcher.md` (41L) ·
`plugins/cursor/context7/rules/use-context7.mdc` (18L).

**Files sampled:** `plugins/context7-power/POWER.md` (first 40 of ~90L) · `LICENSE` (first
lines) · word counts only for `skills/context7-cli/SKILL.md`, `rules/context7-cli.md`,
`skills/context7-mcp/SKILL.md`.

**Not opened:**
- **The entire `packages/cli/` tree** (~35 source files: `commands/{auth,docs,generate,remove,setup,skill,upgrade}.ts`,
  `setup/{agents,mcp-writer,templates}.ts`, `utils/*` incl. `library-id.ts`, `installer.ts`,
  `tracking.ts`). §6's CLI cost claim rests on the **skill body word count**, not on reading
  the CLI. `utils/tracking.ts` is unread and I therefore **cannot speak to what the CLI
  transmits** — relevant to §5-3's transport recommendation and flagged below.
- `packages/mcp/src/lib/jwt.ts` (120L), `encryption.ts` (62L), `client-ip.ts` (78L),
  `auth/auth-prompt.ts` (101L). `generateHeaders()` is called at `api.ts:120,153` and I did
  **not** read what it puts in the headers.
- **All 5 test files** under `packages/mcp/test/` (`integration`, `jwt`, `client-ip`,
  `certificate`, `utils` — 582L total). No claim here is test-backed.
- `packages/mcp/README.md` (1,630L — the largest file in the repo), `CHANGELOG.md` (230L),
  `schema/context7.json` (130L), `mcpb/manifest.json`, `Dockerfile`.
- **All 169 files under `docs/`** and all 15 under `i18n/`.
- 20 of 24 `plugins/**` files, including the codex and copilot variants I inferred C21 from
  via `git ls-files` and one `grep` of declared skill names.
- `skills/context7-cli/SKILL.md` body and its 3 `references/` files — word-counted, not read.

**Claims that need a live run before use:**
- **Every token figure in §6 is an estimate** from exact word counts at ~1.35 tok/word. The
  ratio is unverified against any tokenizer. The *conclusion* (a two-tool server rivals our
  whole `AGENTS.md` budget) holds under any plausible ratio; the percentages do not.
- Whether OMP actually loads MCP tool descriptions into **every subagent** context. This is
  the load-bearing assumption in §6's ×5 multiplication. It comes from
  `06-investment-thesis.md §F-1`, which I did not re-verify against OMP source in this pass.
  **If descriptions are main-session-only, §6's per-run figure is ~940 tok, not ~4,700.**
  This should be checked before §5-4's patch is written.
- Whether the CLI path is genuinely lazy under OMP (skill body loaded on invocation only) —
  depends on `autoloadSkills` semantics and OQ-D′, which is open.
- C2's premise (models echo description prose instead of schema keys) is asserted by
  Context7's own code comment (`index.ts:110-111`). Plausible and self-reported; unmeasured
  by us.

**Anything suspected but not verified:**
- `plugins/cursor/context7/rules/use-context7.mdc:18` says *"See the `context7-docs-lookup`
  skill"*. **No such skill exists** — declared names at this SHA are `context7-cli`,
  `context7-mcp`, `find-docs`. A dangling cross-reference in an `alwaysApply: true` rule. It
  costs the reader nothing but is evidence for §4's point: eight hand-synced copies drift, and
  this one already has. I did not check whether the skill was renamed (`find-docs` looks like
  the successor) or never existed.
- `utils.ts:12` treats `sourceReputation < 0` as `Unknown` while `:34` treats
  `totalSnippets === -1` as absent — two different sentinel conventions in the same file.
  Harmless; suggests `-1` is the API's general "unset" marker, which makes C8's suppression
  rule more important than it looks. Not verified against the API.
- Whether the `find-docs` skill (1,116 words, CLI-based) is intended to **replace**
  `context7-mcp` (410 words, MCP-based) — the CLI path is newer and much more detailed. If so,
  the vendor is itself migrating off the persistent-tier transport toward the lazy one, which
  would independently support §5-3. **This is inference from relative size and detail, not
  from any changelog I read.** `packages/mcp/CHANGELOG.md` would likely settle it; unopened.
- Whether the `find-docs` CLI skill's 1,116-word body is loaded lazily in practice or pulled
  in by a `description` match on every turn. Depends on OQ-D′.

---

## 8. Follow-up: CLI telemetry, resolved

§7 flagged `packages/cli/src/utils/tracking.ts` as the one unread file that could change a
recommendation. It has now been read, along with all 30 `trackEvent` call sites. **The §5-3
CLI recommendation stands.**

```ts
export function trackEvent(event: string, data?: Record<string, unknown>): void {
  if (process.env.CTX7_TELEMETRY_DISABLED) return;
  fetch(`${getBaseUrl()}/api/v2/cli/events`, { method: "POST", ... });
}
```
`tracking.ts:1-10`

| Finding | Evidence | Grade |
|---|---|---|
| The two retrieval commands send **only the command name** — not the query, not the library | `commands/docs.ts:57` `trackEvent("command", {name:"library"})`; `:122` `trackEvent("command", {name:"docs"})` | **A** |
| Telemetry is **opt-out by env var**, and fire-and-forget (`.catch(() => {})`) | `tracking.ts:4,9` | **A** |
| Exactly **one** call site transmits user-supplied query text — and it is `skill search`, the Skill Hub path, **not** documentation retrieval | `commands/skill.ts:504` `trackEvent("search_query", {query, resultCount})` | **A** |
| Install/setup events transmit which IDEs and skills were configured | `setup.ts:443-444`, `skill.ts:474`, `remove.ts:526` | **A** |

Consequences for us:

1. **`spec/15` concern does not materialize for the retrieval path.** Running
   `ctx7 docs /vercel/next.js "<query>"` sends the query to Context7's API (unavoidable — that
   *is* the request, and C12 already covers the do-not-send-secrets rule) but sends only
   `{name: "docs"}` to the events endpoint. Our packet content is not separately exfiltrated.
2. **Set `CTX7_TELEMETRY_DISABLED` anyway** if the CLI transport is adopted. It costs nothing,
   and removes a second network call per invocation. This belongs with the transport decision
   in §5-3, not as a separate delta.
3. **Do not use `ctx7 skill search`.** It is the one command that transmits free-text queries
   as telemetry, and it serves the Skill Hub — a mechanism we have no use for (our library is
   capped at 10 by KD-014, authored by us).

Still unread in `packages/cli/`: ~33 of 35 source files, including `utils/api.ts` beyond
`getBaseUrl` (`:19-25`), `auth.ts`, `installer.ts`, and all of `commands/generate.ts` (553L).
The telemetry question is closed; the CLI's broader behavior is not.
