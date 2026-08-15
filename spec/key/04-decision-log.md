# 04 — Decision Log

> Numbered, dated decisions. Each carries the evidence class that grounds it and the
> condition under which it would be reversed. A decision with no reversal condition is a
> belief, not a decision.
>
> **KD** = Key Decision. Numbering is append-only; superseded decisions are marked, never
> deleted or renumbered.

---

## How to read an entry

| Field | Meaning |
|---|---|
| **Decision** | What was chosen, stated so it can be checked against the artifact |
| **Grounds** | Evidence class from `00-method.md` (A = source-read, B = behavioral, C = design judgment) |
| **Because** | The reasoning; for grade A, the `file:line` that forces it |
| **Rejected** | The alternative and why it lost |
| **Reverse if** | The observation that would overturn this |
| **Touches** | Spec sections and template files affected |

Decisions grounded **A** cannot be overturned by preference — only by a different reading
of source or a new OMP version. Decisions grounded **C** are the ones worth arguing about.

---

## KD-001 — `.omp/policies/` and `.omp/schemas/` do not ship

**Decision.** Neither directory exists in the installed runtime surface. Their content is
re-homed: policy prose into the command or agent prompt that consumes it, result shapes
into agent `output:` frontmatter, reference material into `docs/`.

**Grounds:** A.

**Because.** `discovery/builtin.ts` enumerates every subdirectory OMP reads under a
`.omp/` dir — `skills/`, `commands/`, `rules/`, `prompts/`, `extensions/`,
`instructions/`, `hooks/`, `tools/`, `agents/`, plus `settings.json`, `config.yml`,
`AGENTS.md`, `RULES.md`, `SYSTEM.md`, `mcp.json`. Neither `policies/` nor `schemas/`
appears. There is no loader, no URI scheme, and no consumer. Nine YAML files totalling
**581 lines** were inert, while four agent prompts referenced them as though they resolved.
(Corrected 2026-08-08: earlier revisions of this entry and eight other files said "~1,100
lines". The real figure is 581, verified by `wc -l` and unchanged since the initial commit
`32c37df`. The finding is unaffected; the number was inflated by 89%.)

**Rejected.** *Keep them in `.omp/` with a "documentation only" header.* Placement inside
`.omp/` is itself a claim about runtime meaning. A header is read by maintainers; the
directory path is read by everyone who greps the tree. The `policies/` class of error was
possible precisely because location implied function.

**Reverse if** OMP adds a discovery hook for either directory. Watch
`discovery/builtin.ts`.

**Touches** `spec/01 §2-3`, `spec/02 §A`, `spec/06`, `spec/11 §E`,
`template/.omp/policies/**`, `template/.omp/schemas/**`.

---

## KD-002 — Result contracts live in agent `output:` frontmatter

**Decision.** Each selected spawned worker whose contract requires a structured result
declares its result schema in its own frontmatter `output:` key. A selected inline or
main-session producer uses the equivalent contract at its enforced boundary. Caller-side
`outputSchema` on the `task` call is reserved for explicit per-call narrowing, not the
default spawned-worker path.

**Grounds:** A for the mechanism; C for choosing frontmatter over call-site.

**Because.** `parseAgentFields` reads `output` off the frontmatter into
`ParsedAgentFields.output` (`discovery/helpers.ts:289`). Schema source is tracked
explicitly as `"caller" | "agent" | "session" | "none"` (`task/types.ts:20`), with
`outputSchemaOverridesAgent` recorded when the call site wins
(`task/executor.ts:384`) — so both paths are first-class and the precedence is
designed, not incidental. Choosing frontmatter is the C part: the schema travels with
the selected spawned-worker contract and cannot be forgotten at a call site, and there is
exactly one place to change it.

**Rejected.** *Inline `outputSchema` at every dispatch.* Duplicates the source of truth
across three command files and makes drift the default outcome.

**Reverse if** a live spawn shows frontmatter `output:` is not honoured, or accepts a
form the YAML contracts cannot express. This is a real gap — see OQ-A below.

**Touches** `spec/06`, `spec/01 §4`, and the worker adapters selected by Topic 03.

---

## KD-003 — Enforcement is stronger than the spec claimed; treat it as a gate

**Decision.** Structured output is treated as an enforcing gate, not a nudge. A
`schema_violation` result is a failed spawn. `schemaOverridden` marks a result
**unvalidated** and the coordinator re-verifies rather than reading its fields.

**Grounds:** A. **This corrects `spec/01 §4` and `spec/02 §D`.**

**Because.** `finalizeSubprocessOutput` (`task/executor.ts:598-700`) computes
`mustReject = failure !== undefined && (mode === "strict" || (!assembled.schemaOverridden && !schemaError))`.
So in **permissive** mode an invalid payload still becomes a `schema_violation` with
`exitCode 1` — rejection is the default, and acceptance is the narrow exception for a
retry-exhausted override or a malformed schema. Strict rejects even the override. The
spec's "after 3 failures OMP accepts the payload anyway — a strong nudge, not a hard
gate" understated the mechanism.

One genuine soft spot remains, and it is the opposite of the one the spec worried about:
a **malformed** `outputSchema` degrades silently to unvalidated output
(`structuredOutput.status: "unavailable"`) rather than failing the spawn. So the risk is
an author writing a bad schema, not a worker evading a good one.

**Rejected.** *Carry the spec's softer reading forward.* It would have justified prose
fallbacks and parent-side parsing that the runtime makes unnecessary.

**Reverse if** `mustReject` changes. Watch `task/executor.ts:598-700`.

**Touches** `spec/01 §4`, `spec/02 §D`, `spec/06 §B/§F`, `spec/13` L2 cases.

---

## KD-004 — Validation must lint schemas, not just check they exist

**Decision.** L0 validation parses every selected agent `output:` block and fails on: any
`$ref`, any construct that makes the schema unrepresentable, and any required field the
selected agent's prose never instructs it to produce. Equivalent non-agent structured-result
boundaries are validated by the contract that selects them.

**Grounds:** A (the silent-degrade path) + C (the lint rule set).

**Because.** KD-003 established that a malformed schema does not fail the spawn — it
yields `status: "unavailable"` and unvalidated output. That is a silent failure with no
runtime signal, which is exactly the class `spec/13` exists to catch statically. A schema
nobody validates is worse than no schema: it produces the *appearance* of enforcement.
Malformed selected schemas yield structuredOutput.status unavailable and fail acceptance.

**Rejected.** *Rely on runtime rejection.* There is none for this case.

**Reverse if** OMP begins failing spawns on malformed schemas.

**Touches** `spec/13 §B` (L0), `spec/06 §D`.

---

## KD-005 — `tech-lead.md` does not ship under `agents/`

**Decision.** The Tech Lead is the main session. The role contract moves to
`docs/roles/tech-lead.md` and is not installed. Zero `.md` files describing the Tech Lead
live under any agent discovery root.

**Grounds:** A for "there is no documentation-only category"; C for main-session-as-Tech-Lead.

**Because.** `loadAgentsFromDir()` filters on `entry.name.endsWith(".md")` and passes
every match to `parseAgent()` (`task/discovery.ts:42-58`). Loading is unconditional.
A file parked in `agents/` **is** a live, spawnable `AgentDefinition` whatever the spec
calls it. Retaining it as "reference documentation" would create a second spawnable Tech
Lead beside the main-session one — the exact topology ambiguity the decision exists to
remove.

**Correction to the spec's stated reasoning.** `spec/01 §8` and `spec/03 §A` justify
main-session-as-Tech-Lead partly on recursion budget: a spawned Tech Lead would
"leave zero spare depth." That premise is **wrong**. Depth accounting is
`childDepth = parentDepth + 1`, refused when `childDepth >= maxRecursionDepth`
(`task/executor.ts:2656`, `:2670-2672`, `:2683-2685`). With the default `2`: main session
is depth 0, its child depth 1 (keeps `task`), grandchild depth 2 (`task` stripped). The
default permits **two** levels of subagents, not one — so a spawned Tech Lead with its own
workers fits.

The decision stands on its other grounds, which are C and survive intact: a spawned
coordinator moves ownership of the final answer into a child the parent must then
re-summarize, duplicates context, and adds a spawn per task. But the *recursion argument
must be struck from the spec* — it is a false statement about the runtime, and leaving it
in place means the decision rests partly on evidence that does not exist.

**Rejected.** *Spawn the Tech Lead.* Rejected on ownership and context-duplication
grounds, no longer on depth grounds.

**Reverse if** the context cost of orchestration in the user-facing session measurably
dominates, and L3 evidence shows a spawned coordinator produces better outcomes per token.
The depth objection is withdrawn and can no longer be cited against it.

**Touches** `spec/01 §8`, `spec/03 §A/§G`, `spec/13` L1, `spec/16 §C`,
`template/.omp/agents/tech-lead.md`.

---

## KD-006 — Historical batch-shape decision, superseded as a global rule

**Current status.** KD-006 is superseded as a global rule. Topic 03 decides whether a selected
topology dispatches workers and whether its task-tool path uses batch mode; Phase 02 projects
that choice into runtime commands. Dispatch syntax follows the effective task-tool schema selected by Topic 03:
a selected batch-enabled path uses `{context, tasks: [...]}`, while a
selected non-batch path uses its effective flat schema. Neither shape selects Standard or
Orchestrated.

**Superseded decision (historical record).** The earlier plan required the batch wire form for
each command dispatch. `context` carried the shared objective and constraints once, never the
parent transcript, and command prose excluded the flat `{agent, task}` form.

**Grounds:** A.

**Because.** `task.batch` defaults to **`true`** (`config/settings-schema.ts:4570-4580`),
so the shape the model actually sees is `{context, tasks[]}` with **`context` required**
(`task/types.ts:167-171`). The flat form survives for internal callers and stale
transcripts (`types.ts:285-305`) but is rejected model-side when batch is on. Command
prose written against the flat form is wrong under the default baseline — and this is not
recorded anywhere in `spec/02` or `spec/04`.

**Conditional benefit retained.** On a selected batch path, a shared `context` is a token win,
not a tax: text common to N workers is stated once instead of N times.

**Historical alternative.** The earlier plan rejected disabling `task.batch` to keep a flat
shape. That rejection no longer governs Topic 03; a selected non-batch topology may legitimately
make the opposite trade.

**Source watch.** If the default or schemas change, reverify
`settings-schema.ts:4570-4580` and the selected runtime path.

**Touches** `spec/02 §B`, `spec/04 §E`, `spec/05 §D`, all three command files.

---

## KD-007 — Every worker holds `hub`; allowlists are floors, not ceilings

**Decision.** Worker prompts state that agent-to-agent messaging exists and must not be
used for coordination. The coordinator does not treat a `tools:` list as proof of what a
worker can reach, and `spec/03`'s non-overlap argument is not allowed to rest on it.

**Grounds:** A.

**Because.** `hub` is force-appended to every subagent's tool list unless the session is
restricted (`task/executor.ts:2690-2691`). `task` is auto-**added** when `spawns` is set
and depth allows (`:2676-2681`), and stripped at max depth (`:2683-2685`). `yield` is
force-appended at parse time (`discovery/helpers.ts:265-267`). So a declared allowlist is
a lower bound on capability, and every omp-custom worker has messaging whether the spec
wants it or not.

This matters because `spec/03 §H` argues non-overlapping responsibility partly from tool
allowlists. That argument is weaker than stated: the allowlist bounds *intent*, and
`hub` is a channel outside it.

**Rejected.** *Ignore it as harmless.* The mitigation is one prompt line; the failure mode
is workers coordinating around the coordinator, which silently invalidates the topology.

**Reverse if** `hub` stops being force-appended, or a restriction flag becomes available
to template-level config.

**Touches** `spec/02 §B`, `spec/03 §B/§H`, and all selected worker prompt files.

---

## KD-008 — The `spawns:` list is ordered, and order is semantic

**Decision.** Where a `spawns:` list exists, its first entry is chosen deliberately.
`spawns: ""` is not used as a lockdown mechanism anywhere; absence of `task` from `tools:`
is the real guarantee and is what the spec cites.

**Grounds:** A.

**Because.** `resolveSpawnPolicy` (`task/spawn-policy.ts:19-64`) makes
**`allowedAgents[0]` the default agent for any call that omits `agent`** (`:52-59`).
List order is therefore load-bearing, which no spec section records. Separately, the two
layers disagree about `spawns: ""`: `parseArrayOrCSV("")` yields `undefined`
(`helpers.ts:167-177`), while `resolveSpawnPolicy` maps an empty list to
`enabled: false`. `spec/02 §B` calls it simply "inert" — true at the parse layer only.

**Rejected.** *Keep `spawns: ""` as documentation of intent.* It encodes a false sense of
enforcement, and the two-layer disagreement means its behavior depends on which layer
sees it.

**Reverse if** `spawn-policy.ts` stops defaulting to the first entry.

**Touches** `spec/02 §B`, `spec/03 §D`, worker agent frontmatter.

---

## KD-009 — Compaction strategy is deployed explicitly, not assumed

**Current managed-session supersession.** The source characterization below remains valid, but
KD-031 supersedes its deployment choice for the managed product. Managed sessions set the global
strategy to `off`; neither `shake` nor `snapcompact` is a fallback. One explicit `/safe-compact`
transaction may temporarily invoke native `mode: "soft"` context-full compaction.

**Decision.** The template deploys `compaction.strategy` explicitly if it depends on a
specific strategy's behavior, or states that it depends on none. `spec/05 §H`'s claim that
the baseline "configures `shake`" is corrected: `shake` is not the default.

**Grounds:** A.

**Because.** `compaction.strategy` defaults to **`snapcompact`**
(`config/settings-schema.ts:2164-2198`) — "archive history onto dense bitmap images the
model reads back; no LLM call." `shake` — "drop heavy content in place; recover via
artifact" — must be selected explicitly. `spec/05 §H` reasons from `shake` semantics,
particularly `supersedeReads` making the read-after-edit pattern cheap.

`supersedeReads: true` and `dropUseless: true` **are** defaults
(`settings-schema.ts:2346-2367`), so the specific token benefit `spec/05` relies on holds
regardless of strategy. The error is narrower than it looks: the named strategy is wrong,
the cited behavior is real.

**Rejected.** *Deploy `shake` to match the spec.* Would be choosing a strategy to make a
document true. `snapcompact` avoids an LLM call per compaction, which is a token argument
in its own right and deserves measurement (see OQ-C) rather than a documentation-driven
override.

**Reverse if** measurement shows one strategy dominates for these workflows.

**Touches** `spec/05 §H`, `spec/phases/phase-03-context-efficiency.md` T-03.1.

---

## KD-010 — Per-spawn `effort` requires deploying `task.enableEffort`

**Decision.** Any command that dispatches with `effort` also declares
`task.enableEffort: true` as a prerequisite, and validation asserts it. Absent that,
`effort` is silently unavailable and every dispatch runs at the default.
Selected per-spawn effort requires task.enableEffort true.

**Grounds:** A. **This corrects `spec/09 §D`.**

**Because.** `effort` is present in the task wire schema **only when
`task.enableEffort` is true** (`task/types.ts:202`), and the default is **`false`**
(`settings-schema.ts:4582-4592`). `spec/09 §D` states "the baseline `task.enableEffort =
true` … permits per-task effort overrides," describing an override lever that does not
exist unless the setting is actually deployed and verified.

This is the same failure signature as `task.enableLsp = true` with `lsp` absent from
every allowlist: a capability believed available, inert in practice, with no error. The
arktype schema strips unknown keys, so passing `effort` when disabled is not a validation
error — it is a silent no-op.

**Rejected.** *Assume the baseline provides it.* The `enableLsp` precedent is the argument
against assuming.

**Reverse if** the default flips to `true`.

**Touches** `spec/09 §D`, `spec/13` L1 (effective-settings assertions), command dispatch
sites.

---

## KD-011 — Subagent budgets are acknowledged, not discovered at runtime

**Decision.** Task packets are scoped to fit inside `task.softRequestBudget` (default
200 requests, hard stop at 1.5×). Result contracts stay well inside the 500 KB /
5,000-line output caps. A worker that hits the budget is a partitioning failure, not a
runtime surprise.

**Grounds:** A.

**Because.** `task.softRequestBudget` defaults to 200; crossing it injects one wrap-up
notice and **1.5× forces a stop with a partial yield**
(`settings-schema.ts:4676-4692`). `task.agentIdleTtlMs` (420 s) parks idle agents to disk
(`:4664-4674`). Output is capped at `MAX_OUTPUT_BYTES` 500,000 and `MAX_OUTPUT_LINES`
5,000 (`task/types.ts:53-56`). None of this appears in `spec/05`'s context model, which
budgets tokens without reference to the request ceiling that actually terminates a worker.

A forced partial yield is the most dangerous of these: it produces a *result* that looks
like a completion. That is the false-completion signature the whole template exists to
prevent, arriving through a channel no spec section covers.
A forced softRequestBudget stop returns a partial yield that cannot satisfy completion.

**Rejected.** *Leave budgets undocumented.* Silent truncation into a plausible-looking
result is the worst available failure mode.

**Reverse if** the defaults change materially.

**Touches** `spec/05 §C`, `spec/15 §D`, `spec/13` L4 (add a forced-partial-yield case).

---

## KD-012 — Result telemetry is the measurement surface; nothing is hand-counted

> **Superseded in part by KD-024 (2026-08-12):** `SingleResult` remains the authority for
> each subagent spawn, but it is not the whole task-cycle ledger.

**Decision.** `tokens-per-accepted-outcome` is computed from the `SingleResult` telemetry
OMP already returns. The benchmark harness reads those fields; it does not estimate from
transcript length or `chars / 4`.

**Grounds:** A.

**Because.** Every spawn returns `tokens`, `requests`, `contextTokens`, `contextWindow`,
`cost`, `usage`, `durationMs`, `structuredOutput`, and `patchPath`/`branchName`
(`task/types.ts:471-539`), with live equivalents streaming on `AgentProgress` over
`task:subagent:*` EventBus channels (`:395-469`, `:59-65`). Per-spawn `modelRole`,
`resolvedModel`, and `resolvedModelIsFallback` are also reported (`:428-434`, `:500-505`).

`tokens` is intended to be input + output + cacheWrite excluding cacheRead, but the runtime
falls back to provider `totalTokens` when the breakdown is absent and warns that the fallback
may include cacheRead (`task/executor.ts:759-782`). KD-024 therefore permits promotion only
from the explicit `usage` breakdown; a fallback-only run is `not_measured`.

That last triple supplies result telemetry but does not identify every misroute by itself.
resolvedModelIsFallback marks retry fallback only; credential fallback and
task.agentModelOverrides require exact returned identity comparison. The coordinator reconciles
the expected role/model before dispatch, compares returned `modelRole` and `resolvedModel`, and
separately rejects any result with `resolvedModelIsFallback: true`. Detection is a coordinator
acceptance check, not new infrastructure.
The coordinator rejects any result with resolvedModelIsFallback true.

**2026-08-12 scope correction.** The full metric must also include the main/Tech Lead
session. `AgentSession.getSessionStats()` aggregates assistant-message usage and `task` tool
usage (`session/session-stats.ts:52-110`), while JSON print mode emits authoritative
`message_end` / `agent_end` messages with their runtime usage (`modes/print-mode.ts:58-83,
191-194`). Phase 06 must use those runtime fields plus per-spawn role metadata to produce the
KD-024 ledgers without double counting. If the main-session portion cannot be captured, the
metric is `not_measured` and cannot support promotion; transcript-length estimation remains
forbidden.

**Rejected.** *`chars / 4` estimation.* `spec/13 AC-8` already rejects it; this decision
names what replaces it.

**Reverse if** the telemetry shape changes. Watch `task/types.ts:471-539`.

**Touches** `spec/13 §C`, `spec/09 §B`, `spec/15 §D-6`, `scripts/benchmark.ps1`.

---

## KD-013 — Discovery is cwd-anchored; the installer and docs must say so

**Decision.** Installation targets the repository root, and the runtime contract states
that `commands/`, `rules/`, `prompts/`, `hooks/`, `tools/`, `extensions/`,
`settings.json`, and `config.yml` are found **only** at `cwd/.omp`. Launching from a
subdirectory silently loses them.

**Grounds:** A.

**Because.** `getConfigDirs` resolves exactly `cwd/.omp` plus the user profile dir
(`discovery/builtin.ts:58-73`). Only `skills/`, `AGENTS.md`, `RULES.md`, and `SYSTEM.md`
walk ancestors (`:284`, `:90-99`). Additionally an **empty `.omp/` directory is invisible**
— `ifNonEmptyDir` returns `null` (`:46-56`).

The partial-degradation shape is what makes this dangerous. From `packages/web/`, a user
keeps `AGENTS.md`, `RULES.md`, and skills, and loses all three commands and the model
roles. The session looks configured. `/standard` is simply not there, and a selected worker
alias resolves to nothing.

**Rejected.** *Treat it as user error.* It is a documentable runtime property with a
one-line preflight check, and it is invisible from inside a session.

**Reverse if** `getConfigDirs` starts walking ancestors for all surfaces.

**Touches** `spec/01 §2`, `spec/02 §A`, `spec/12`, `spec/13` L1.

---

## KD-014 — The skill library is capped at 10, because every subagent pays for the listing

**Decision.** The installed skill library is capped at **10 skills, hard ceiling 12**, with
per-skill `description` ≤ 80 tokens and the **whole listing** ≤ 900 tokens checked as a sum.
The cap is a spec number, not a style preference.

**Grounds:** A.

**Because.** The cost is multiplied by the number of sessions, and the multiplication is
source-verified:

1. `task/structured-subagent.ts:366` — `resolveAutoloadSkills` does
   `const skills = [...(session.skills ?? [])]` and returns the **entire parent list**,
   which `buildExecutorOptions` passes as `skills` (`:434`).
2. `task/executor.ts:3025` forwards `skills: options.skills` into the child
   `createAgentSession`.
3. `prompts/system/system-prompt.md:26-33` renders `{{#if skills.length}}` → an
   `<skills>` block with an instruction to read `skill://<name>`.
4. The subagent template does **not** replace that block. `task/executor.ts:3045-3048`
   splices the subagent prompt *into* the default prompt
   (`[...defaultPrompt.slice(0, -1), subagentPrompt, defaultPrompt.at(-1)]`), and
   `prompts/system/subagent-system-prompt.md` contains no `skills` section of its own.

So the full listing is present in every selected worker session, not just the main one. At
~90 tokens per skill worst case, an illustrative four-session run pays **4×**, and an
illustrative six-session run pays more. These columns are cost examples, not workflow-roster
authority:

| N skills | Per session | 4-session example | 6-session example |
|---|---|---|---|
| 3 (today) | ~270 | ~1,080 | ~1,620 |
| 8 | ~720 | ~2,880 | ~4,320 |
| 10 (cap) | ~900 | ~3,600 | ~5,400 |
| 12 (ceiling) | ~1,080 | ~4,320 | ~6,480 |
| 24 | ~2,160 | ~8,640 | ~12,960 |

At the cap the library already costs more per workflow than `RULES.md`, the task packets,
and the results combined. That is the arithmetic reason for the number.

The qualitative reason is stronger and independent: at 24 skills, `addyosmani/agent-skills`
needed a 191-line router skill **and** a repo rule to stop triggers colliding
(`.claude/rules/skills-contributing.md:9-13`). Trigger precision degrades before the token
budget does, so the cap protects selection quality, not just cost.

**This resolves OQ-D's second half** (does the body reach the child) for the *listing*. The
`autoloadSkills` body question remains open — that path is `sendCustomMessage`
(`task/executor.ts:3234-3243`), a different mechanism from the listing.

**Rejected.** *Cap by per-file size only.* A per-file limit with no total permits unbounded
growth: twelve compliant descriptions still cost more than the budget allows. The sum is
the binding constraint, so the sum is what validation checks.

**Rejected.** *Ship a router skill to manage a larger library.* OMP's persistent listing
**is** the router. A router skill pays for the index twice.

**Reverse if** OMP gains a per-agent skill filter (so a worker can carry a subset), or
`skills` stops being forwarded at `task/structured-subagent.ts:366`. Either would decouple
worker count from library size and the cap could rise.

**Touches** `spec/05 §C`, `spec/11 §C/§G`, `spec/13` L0, `registry/skill-lock.yml`.

---

## KD-015 — Ranking is a real capability gap; enumeration is not ranking

**Decision.** `spec/07`'s **conclusion** stands — no persistent repository-map artifact
ships. Its **argument** is corrected: the claim that `lsp symbols` and `ast_grep`
"duplicate what a repo-map computes" is false. The spec text must say the artifact is
rejected for staleness and unconditional cost, **not** for redundancy.

**Grounds:** A.

**Because.** I searched the three candidate tools for any ranking, scoring, centrality, or
PageRank machinery in OMP at commit `3a8591a`:

- `tools/ast-grep.ts` — no `rank`, `score`, `centrality`, or `pagerank` symbol. The only
  match for "rank" in the file is unrelated (`internalUrlAction: "search"` region).
- `tools/grep.ts` — the sole "rank" hit is a comment about selector precedence
  (`:175`), not result ranking.
- `tools/lsp.ts` — no global graph construction, no centrality.

What `lsp` actually offers is enumeration and name search: `symbols` lists a file's symbols,
or searches the workspace given a `query` you must already know
(`prompts/tools/lsp.md:9`); `references` returns callers of one symbol you already named
(`:15-16`). Neither answers *"of the symbols I have not read, which 30 matter for this
task?"* — which needs a global reference graph, centrality over it, query personalization,
IDF-style demotion of ubiquitous names, and a budgeted cut. OMP has none of these.

The failure mode this creates is the reason it matters. Asked "what matters here" with no
ranking primitive, a selected discovery responsibility answers from filename plausibility and
its own priors. The output is fluent, confident, and unverifiable — there is no error signal.
So describing its LLM-judged "ranked evidence" **as** the repository map relabels the failure
mode as the solution.

**Rejected.** *Leave the spec argument as written.* A correct conclusion resting on a false
premise is fragile: the next reviewer who checks the premise reopens the settled
conclusion.

**Rejected for v0.** *Ship a `repo_rank` custom tool now.* `.omp/tools/*` is a real
discovery surface (`discovery/builtin.ts:750-796`) and a deterministic, mtime-cached,
pull-only ranking tool would satisfy every objection in `spec/07` — it is recomputed so it
cannot go stale, invoked explicitly so it is not paid unconditionally, and computes
something OMP provably lacks. But it is new machinery with an unmeasured benefit, and v0's
deliverable is a measured baseline. It becomes a candidate **after** the baseline exists.

**Reverse if** a measurement shows selected discovery with ranking beats selected discovery
with `glob`+`read` on tokens per accepted outcome for unfamiliar-repo tasks. Absent that
number, the gap is documented rather than filled.

> **KD-024 projection:** “tokens per accepted outcome” here now means the quality-first,
> full-task-cycle `core_workflow_tokens / validated_accepted_outcomes` promotion contract in
> `spec/13 §C`; a three-run pilot cannot satisfy this reversal condition.

**Touches** `spec/07 §D`, `spec/13` L3 fixtures, `registry/rejected-mechanisms.yml`.

---

## KD-016 — Strictness governs how hard you look; confidence governs what you report

**Decision.** Any selected independent review contract carries both halves explicitly, and
the resolution rule between them is stated: **uncertainty resolves toward blocking, not toward
silence.** A finding that cannot be proven is dropped; a *blocking* finding that cannot be
refuted stays blocking.

**Grounds:** C, on independently observed evidence.

**Because.** Two disciplines pull in opposite directions, and shipping both without a
resolution rule is how review degrades. `spec/10` already has the false-positive half
(don't manufacture findings, check pre-existing lint). What it lacks is the asymmetry that
keeps that half from becoming an excuse to approve.

ECC ships both and never reconciles them in prose — `agents/gan-evaluator.md:24` says "be
ruthlessly strict… do NOT talk yourself out of issues you found", while
`agents/code-reviewer.md:29-111` requires proof and permits zero findings. The resolution is
visible only in its executable: `workflows/orch-review.workflow.js` keeps three cases
blocking — unverifiable ("an unverifiable CRITICAL must never be demoted", `:247-248`),
refuted-below-confidence-threshold ("uncertainty must never demote a blocker", `:259-260`),
and a review dimension that failed to run at all (`:214`, fails closed).

Two mechanisms make it operational rather than aspirational, both worth adopting:

- **A named false-positive catalog**, not four generic bullets. ECC lists 12 concrete
  patterns with disqualifying conditions (`code-reviewer.md:76-111`): "consider adding
  error handling" where the framework handles it; "magic number" for `200`/`404`/`1024`;
  "function too long" for exhaustive switches ("length is not complexity"); security theater
  for `Math.random()` in animation jitter. The catalog is what makes the rule checkable.
- **Explicit permission to return nothing** (`:66-74`) — "A clean review is a valid review.
  Do not manufacture findings to justify the invocation," and its inverse, "Do not withhold
  approval to appear rigorous."

**Rejected.** *Add an adversarial second verification pass over findings for v0.* It is the
right mechanism and it doubles review cost. Adopt the asymmetry rule now (free, prose-level);
schedule the refutation pass as a measured A/B after the baseline.

**Reverse if** measurement shows the asymmetry produces blocking findings that reviewers
routinely override — that would mean the rule is generating noise, not catching defects.

**Touches** `spec/10 §C` and any review adapter selected by Topic 03.

---

## KD-017 — Discipline skills are behavioral interventions, and are tested under pressure

**Decision.** Every discipline skill selected by the runtime manifest ships with **two**
fixture classes: activation fixtures (does it trigger?) and **pressure fixtures** (does it
hold when the model has a reason to skip it?). The former three-skill baseline
(`evidence-before-completion`, `systematic-debugging`, `failing-test-first`) is illustrative,
not a required set or count. Negative activation fixtures name the selected skill that
*should* win instead.

**Grounds:** C, on convergent evidence from two independent authors.

**Because.** `spec/11 §D` currently asks for `should_trigger` / `should_not_trigger` prompt
lists. That tests *activation* only — and activation is not the failure mode these skills
exist to prevent. `evidence-before-completion` fails when a model that has already loaded it
decides this particular case doesn't need the command run. An activation fixture cannot
detect that.

Two upstream refinements close the gap:

- **Pressure fixtures.** `superpowers` ships `test-pressure-1.md` / `-2` / `-3` and
  `test-academic.md` per discipline skill, plus a `CREATION-LOG.md`, under an authoring law:
  "NO SKILL WITHOUT A FAILING TEST FIRST" (`skills/writing-skills/SKILL.md:377`). Adopted as
  a *promotion precondition* rather than an absolute — a skill may exist before its fixture,
  but not ship.
- **Negative fixtures name an owner.** `addyosmani/agent-skills`
  (`evals/cases/api-and-interface-design.json:18-27`) attaches the intended owning skill to
  each negative case. "Should not trigger" is weak; "should not trigger, `X` should" is
  checkable, and it is what makes the routing-description discipline testable.

The routing-description pattern this depends on is worth taking as well: every description
should name the adjacent domain it does *not* own and who does
(`Agent-Skills-for-Context-Engineering/template/SKILL.md:12` — "prevents broad skills from
stealing activation from narrower skills"). Under KD-014's cap, trigger collision is the
binding quality constraint, so descriptions must be routing-aware by construction.

One empirical detail justifies the emphasis on descriptions over bodies: a description
reading "code review between tasks" caused an agent to run **one** review although the body
specified **two** (`superpowers/skills/writing-skills/SKILL.md:154-156`). The description is
not a summary of the body — it competes with it.

**Rejected.** *Activation fixtures only.* Cheaper, and it tests the wrong property.

**Reverse if** pressure fixtures prove unmaintainable in practice — they are model-graded
(L3) and could drift. If so, downgrade to advisory rather than dropping them.

**Touches** `spec/11 §D/§G`, `spec/13` L3, `evals/triggers/**`.

---

## KD-018 — A nested repository disables parallel isolated implementation repository-wide

**Decision.** Orchestrator preflight enumerates tracked submodules and non-submodule nested
repos **before** fan-out. Any non-empty result disables parallel isolated implementation for
the whole repository and routes the run to sequential non-isolated implementation, with the
nested paths and the reason disclosed. Scope exclusion in the task packet and post-hoc
`git status` are explicitly **not** accepted as enforcement.

**Grounds:** A (the runtime path) + C (choosing repository-wide disable over a narrower fence).
**This supersedes the earlier "exclude nested repos from parallel scope" rule** carried in an
earlier draft of `01-dna.md` L6 rule 8.

**Because.** Two facts compose into an undetectable loss. First, on the *successful*
`apply=false` path OMP writes only `rootPatch` to a durable artifact; `nestedPatches` stays
in-memory, `persistNestedPatches()` is reachable only from `isolationRecoveryHint()`, and
`runIsolatedSubprocess()` tears the handle down in `finally`. Second, the `apply=false`
summary is an `else if` chain in which the root-patch branch wins whenever the root also
changed — so the nested count is *never mentioned*.

The consequence is what forces the coarse rule: after integration, the parent tree is
**identical** whether the worker correctly left the nested repo alone or edited it and lost
the work. A detector with zero discriminating power is not a guard, and an instruction in
`out_of_scope` is not a constraint on a worker that can ignore it. So the guarantee has to
come from never entering the path, which is a decision the orchestrator can make with its own
tool calls before dispatch. The preflight must be a **superset** of `discoverNestedRepos()`
semantics (walk from root, skip `node_modules`, do not descend past a nested repo) plus
`git submodule status --recursive`, so the two enumerations cannot disagree.

**Rejected.** *(a) Scope exclusion plus post-integration `git status`* — the previous rule;
rejected above on discriminating power. *(b) An in-worker baseline comparison before `yield`* —
useful defense in depth, but it is the worker checking itself, so it cannot ground the claim.
*(c) Option A2, a path-level write boundary* — technically reachable, and worth recording
against the common misreading that OMP cannot enforce this at all: `ExtensionToolWrapper`
emits `tool_call` *before* execution and blocks on `{block: true}` or on a throw (fail-closed,
`extensibility/extensions/wrapper.ts:200-232`), and isolated spawns re-discover extensions
in-worktree because `runIsolatedSubprocess()` passes `preloadedExtensionPaths: undefined`
(`task/isolation-runner.ts:168`). Not adopted for v0: it introduces hooks as a new installed
component class, and the worktree-relative discovery path and `bash`-argument coverage are
unverified in the target environment.

**Reverse if** OMP persists `nestedPatches` on the successful `apply=false` path and surfaces
the artifact paths in the result (then the exclusion narrows back to scope-level), or if A2 is
verified in the target environment. Watch `task/worktree.ts`, `task/isolation-runner.ts`.

**Touches** `spec/08 §D-1/§D-1.1/§D-1.2`, `01-dna.md` L6 rule 8, `spec/phases/phase-00` T-00.E3-G,
`orchestrated.md` preflight.

---

## KD-019 — Schemas prove shape, never provenance; false-completion resistance is behavioral in v0

**Decision.** No document, prompt, or command may describe structured output as evidence that
claimed work was performed. The template's v0 false-completion resistance rests on two
layers — schema (shape) and independence (the selected evidence source did not author the candidate) — and provenance
has **no** v0 mechanism. Claims about `history://<id>` transcripts are gated on measurement
(phase-04 T-04.8) before any document may rely on them.

**Grounds:** A. **This corrects my own earlier text in `01-dna.md` L3 and `02-repo-synthesis.md`
§C**, both of which overstated what enforcement buys.

**Because.** `buildOutputValidator()` compiles the declared schema and validates the payload
against it. That is all it does — there is no correlation with the session's tool events. So a
worker that ran zero commands and fabricated a well-formed `verification_results` array
produces a payload that validates and returns `PASS`. The earlier claim that required fields
"cannot be satisfied without real command output" was wrong and is withdrawn: a required field
constrains *shape*, and fabricated content has shape.

The `patchPath` check in SD-2 is a real runtime-grounded guard because OMP writes that field,
not the worker — but its question is only "did anything change". A worker that edited files and
then fabricated its evidence passes it and every schema check. Naming the boundary explicitly
matters more than it appears: the failure mode is not that the defense is weak, it is that a
document describing schemas as attestation causes a *fabricated* `PASS` to be read as verified,
which is the exact outcome the layer exists to prevent.

**Rejected.** *Treat required evidence fields as attestation.* It reads as a stronger guarantee
and delivers none — the worst combination available, because it suppresses the corroboration
(transcript audit, main-session re-run) that high-risk work would otherwise get.

**Reverse if** T-04.8 shows `history://<id>` transcripts carry enough tool-call detail to
substantiate a provenance claim mechanically. Then provenance becomes a third layer and this
entry narrows rather than disappears.

**Touches** `spec/10 §A-1`, `spec/phases/phase-04` T-04.1/T-04.8, `01-dna.md` L3,
`02-repo-synthesis.md` SD-2, the `fabricated-evidence` L4 fixture.

---

## KD-020 — Verification failures classify four ways; `preexisting` carries an evidence obligation

**Decision.** The failure enum is `impl | env | flaky | preexisting`. A `preexisting` claim
requires baseline evidence (the command, its output, and the pre-change ref at which it
failed); absent that evidence the claim is treated as `impl`.

**Grounds:** C, forced by a completeness argument rather than by source.

**Because.** `impl | env | flaky` is not exhaustive over real verification runs. A test that
fails deterministically, in a healthy environment, for a reason this change did not introduce
is none of the three — and the enum being closed means the model must pick one anyway. It picks
`impl`, which dispatches the selected remediation owner at code outside the change's scope.
That is the worst available outcome: scope creep justified by a verification result, on a
defect the change did not cause.

The evidence obligation exists because the label is also the most attractive excuse in the set.
"It was already broken" converts any inconvenient failure into someone else's problem, and
unlike `flaky` (which a re-run tests) nothing else in the pipeline checks it. Baseline evidence
is cheap — one command at one ref — and it is the only thing that separates the real category
from the abuse case.

**Rejected.** *(a) Keep three and fold baseline failures into `env`* — `env` routes to
environment repair, so the failure gets chased in the wrong place. *(b) Add it without the
evidence rule* — creates a universal escape hatch.

**Reverse if** L3 runs show `preexisting` is claimed with valid baseline evidence so rarely
that the category is dead weight, or so often that the fixtures themselves are unsound.

**Touches** `spec/10 §B`, the selected verification-result contract, and `spec/13` L2 cases.

---

## KD-021 — `.omp/SYSTEM.md` is deliberately unused

**Decision.** The template ships no `SYSTEM.md`, and the installer must not create one. Its
existence is documented in `docs/` as a surface we evaluated and declined, so a future
maintainer does not rediscover it as an opportunity.

**Grounds:** A (the mechanism) + C (the decline).

**Because.** `SYSTEM.md` does not *augment* the system prompt — it **replaces** it wholesale
(`discovery/builtin.ts:242-271`). Everything the replaced prompt carried goes with it: built-in
tool instructions, the skills listing block (`prompts/system/system-prompt.md:27-33`), and
whatever else a future OMP version puts there. The last clause is the decisive one. Our value
comes from OMP executing the workflow well, so a file that silently opts out of every upstream
improvement to the base prompt is a permanent maintenance liability in exchange for control we
do not need — `AGENTS.md` and `RULES.md` already reach every place we want to reach, additively.

This is the same class of error as `.omp/policies/` (KD-001) approached from the opposite
direction: `policies/` was a file OMP never reads, `SYSTEM.md` is a file OMP reads *too*
authoritatively.

**Rejected.** *Use `SYSTEM.md` to enforce workflow discipline at the strongest available level.*
It is genuinely the strongest lever, and that is why it is the wrong one: it converts every
future OMP prompt improvement into a silent regression for this template, with no error signal.

**Reverse if** OMP adds an additive system-prompt surface, or if `SYSTEM.md` gains a merge
semantic rather than a replace semantic. Watch `discovery/builtin.ts:242-271`.

**Touches** `01-dna.md` L0 rule 4, `spec/12` (installer manifest — assert absence),
`spec/13` L0.

---

## KD-022 — Path-scoped rules are the highest-value unexplored lever, and stay out of v0

**Decision.** v0 ships no `globs`/`condition`/`astCondition`-scoped rules and no
`instructions/` directory. The capability is recorded as the primary post-v0 candidate, gated
on an evaluated v0 baseline.

**Grounds:** A (the capability) + C (the deferral).

**Because.** `buildRuleFromMarkdown` (`discovery/helpers.ts:182-221`) parses far more than the
template uses: `globs` for path-scoped activation, `condition` and `astCondition` for
conditional activation, `scope`, and `interruptMode` (`never|prose-only|tool-only|always`);
`.mdc` is accepted alongside `.md`; `instructions/` carries `applyTo` as a second path-scoped
channel. The economics are unusually good — **a path-scoped rule costs nothing on files it does
not match**, which makes it the cheapest per-token quality mechanism in OMP and the only one
that gets cheaper as the rulebook grows.

It is nonetheless deferred, for a reason specific to this project rather than to the mechanism:
conditional activation is *conditionally invisible*. A rule that silently fails to activate on
the paths it was written for looks identical to a rule that activated and was obeyed, and v0 has
no measurement to tell those apart. Adopting a mechanism whose failure mode is silence, before
the harness that would detect the silence exists, is how `policies/` happened. Sequence matters
more than value here: `spec/13`'s L1 discovery assertions must be able to prove activation
first.

**Rejected.** *(a) Ship path-scoped rules in v0* — unmeasurable, and the failure is silent.
*(b) Drop the capability from the record* — it would be rediscovered from scratch, which is the
recurrence this log exists to prevent.

**Reverse if** L1 can assert rule activation per path (then this moves to a v0.x increment with
a real gate). Watch `discovery/helpers.ts:182-221`.

**Touches** `01-dna.md` L5, `spec/11`, `spec/13` L1, `spec/14` (post-v0 roadmap).

---

## KD-023 — Two upstream license records are factually wrong and must be corrected

**Decision.** `reject-013` is scoped to the four Anthropic-proprietary document skills;
`reject-014` and `adopt-016`'s `license_check` are corrected to record MIT declared in-file.
`registry/licenses.yml` is checked for the same two errors. No `template/` file changes.

**Grounds:** A — verified against the local clones on 2026-08-07.

**Because.** Both records infer "all rights reserved" from the absence of a root LICENSE file,
and in both cases a grant exists elsewhere. `anthropics/skills@b29e7cf` carries **16 per-skill
`LICENSE.txt` files: 12 Apache-2.0**, 4 proprietary (`docx`, `pdf`, `pptx`, `xlsx`), one skill
(`doc-coauthoring`) with none. `andrej-karpathy-skills@2c60614` declares MIT twice —
`skills/karpathy-guidelines/SKILL.md:4` and `README.md:169-171`. An in-file grant is a grant.

The consequence is asymmetric, which is why this is worth a decision rather than a footnote: a
false *permission* risks infringement, but a false *prohibition* is inherited silently as a
constraint and blocks legitimately available material forever. Here it blocks `skill-creator`,
Apache-2.0 and the most relevant upstream file for the skill-authoring craft in
`dossiers/superpowers-skills.md §2`. Nothing in the template needs to change today — our
authoring template is derived, not copied — so this is purely a correction of the record,
which is exactly the kind of debt that never gets paid unless it is logged.

**Rejected.** *Leave the ledger conservative since we don't copy body text anyway.* It trades a
permanent false constraint for zero benefit, and it teaches the next maintainer that ledger
entries are not checked.

**Reverse if** re-verification at a newer pin shows different license files. Both facts are
pinned to specific commits precisely so this is checkable.

**Touches** `registry/rejected-mechanisms.yml`, `registry/adoption-ledger.yml`,
`registry/licenses.yml`, `00-method.md §E`, `02-repo-synthesis.md` §C-6/§D-5/SD-12.

---

## KD-024 — Quality-first accepted-outcome economics use unweighted core and Scout ledgers

**Decision.** *(Approved by the user on 2026-08-12.)* Candidate decisions are
lexicographic: mandatory quality gates first, validated accepted-outcome rate second,
`core_workflow_tokens / validated_accepted_outcomes` third, and latency only as a final
tie-breaker. The task cycle includes failed attempts, retrieval, retries, rework, handoff,
compaction, and fallbacks. It reports `core_workflow_tokens`, `cheap_scout_tokens`, and
`raw_total_tokens` without model weighting. Cheap Scout tokens are telemetry only.

A validated accepted outcome requires a complete objective, PASS evidence for every mandatory
criterion, clear required verification/review, no blocking authority or scope issue, and Tech
Lead acceptance. `accepted_with_waiver` is a separate non-validated state. Candidate evaluation
uses the last promoted template as `stable_product_baseline`; releases and major architecture
checkpoints additionally compare with a pinned plain-OMP runtime baseline. Promotion requires
hard gates plus either the approved efficiency-win or quality-win threshold in `spec/13 §C`.

This decision supersedes KD-012's SingleResult-only aggregation scope, the unnumbered
`total_tokens / accepted_outcomes` objective, the
single plain-OMP baseline, pilot-sized promotion evidence, and the PR-7 requirement that every
win be both quality-neutral-or-better and equal-or-lower-token. KD-012's prohibition on
hand-counting and its per-spawn telemetry facts remain in force.

**Grounds:** C — explicit current-session user decision; A for the OMP per-spawn telemetry
surface already verified in KD-012 and `03-token-quality-model.md §C-7`.

**Because.** The old formula conflated expensive workflow work with deliberately abundant
Cheap Scout retrieval, left “accepted” dependent on self-report or user tolerance, omitted the
full failed/rework cycle from the accounting boundary, and had no candidate-promotion rule. A
weighted composite would hide a quality-gate failure behind an arbitrary price coefficient.
The dual ledger keeps the optimization target on Lead/core work while still exposing total
consumption; the dual baseline separately answers whether a change beats the stable product
and whether the product beats plain OMP.

**Rejected.** *(a) Weight every model token by price or quota* — provider economics change and
the weights become policy masquerading as measurement. *(b) Optimize raw total tokens* — makes
the intentionally cheap Scout budget a reason to suppress useful retrieval. *(c) Ignore all
Scout tokens* — hides operational consumption, so they remain telemetry. *(d) Use only plain
OMP or only the last template as baseline* — each answers only one of the two required
questions. *(e) Promote from three runs per arm* — that is smoke evidence, not a strong
neutral-or-better claim. *(f) Optimize latency* — speed cannot pay for lower quality or higher
core cost.

**Reverse if** a new explicit user decision changes the priority order, or a recorded Phase 06
calibration demonstrates that a numeric threshold is unsafe or infeasible and a replacement is
predeclared before new final sampling. Measurement may make the gate stricter without changing
the architecture; it may not loosen the gate post hoc.

**Touches** `03-token-quality-model.md §A`, `01-dna.md §L9`, `06-investment-thesis.md`,
`spec/05 §A`, `spec/13 §C-F`, `spec/README.md §4/§14`, phases 03/06/07, and
`docs/token-strategy.md`. No template/runtime artifact changes in Topic 01.

---

## KD-025 — Adaptive promotion evidence is sequentially valid at the 95% gate

**Decision.** *(Topic 01 audit correction, 2026-08-12.)* KD-024's adaptive final sampling uses
an anytime-valid paired confidence sequence, a finite look schedule with explicit alpha
spending/multiplicity adjustment, or an equivalent joint sequential construction. The
probability of any false promotion is at most 5% across all interim looks, both promotion
paths, and every promotion-bearing bound. Ordinary 95% intervals recomputed at each look are
descriptive only and cannot promote. Pilot observations enter final inference only when the
procedure was frozen before the first pilot look and includes them as that look.

This corrects only KD-024's phrase “predeclared adaptive stopping rule.” Predeclaration blocks
post-hoc rule changes but does not by itself preserve 95% coverage under repeated looks. All
KD-024 outcome, accounting, Scout, baseline, threshold, and non-claim decisions remain in
force.

**Grounds:** B — mathematical necessity for faithfully implementing the user-approved 95%
promotion gate under adaptive sampling; confirmed by adversarial Codex peer review after Opus
was unavailable.

**Rejected.** *(a) Recompute a nominal 95% bootstrap interval after every new pair and stop at
the first crossing* — repeated looks inflate false-promotion risk. *(b) Treat a frozen stopping
rule as sufficient error control* — reproducibility is not sequential validity. *(c) Add the
pilot retroactively to final evidence* — selection has already occurred unless the pilot was
the predeclared first look.

**Reverse if** final sampling becomes a single frozen look, or a stronger recorded statistical
design replaces the joint sequential construction while retaining at least 95% overall
false-promotion control.

**Touches** `03-token-quality-model.md §A-6`, `spec/13 §C-4/C-5`, Phase 06 T-06.6/T-06.8,
Phase 06 verification/exit criteria, the Topic 01 design, and `CHANGELOG.md`. No runtime or
benchmark harness is implemented by this correction.

---

## KD-026 — Workflow entry and lifecycle are contract-first and Tech-Lead-routed

**Decision.** *(Approved by the user on 2026-08-12.)* A plain natural-language request is the
normal entry and requires no workflow prefix. The user explicitly selects Quick with `/quick`;
the main-session Tech Lead selects Standard or Orchestrated. `/standard` and `/orchestrated`
remain compatibility/advanced hints, and the same words without `/` are natural-language
hints. The Tech Lead validates every hint before mutation and changes workflow through internal
classification state, never by pretending to reinvoke a slash command.

A phase is a program of tasks. A task begins when one objective, scope/authority boundary,
mandatory acceptance criteria, and required verification and review obligations are accepted
as its contract. Changing any of those locked elements materially opens a linked task. A
candidate is a frozen implementation snapshot; any acceptance-bearing mutation invalidates its
evidence and the next freeze becomes C2 or later. One session serves one task and one
non-competing candidate lineage, although bounded C1-to-C2 rework may stay in that session.
Compaction stays within the session; handoff creates a successor session for the same lineage;
new task/contract means a new session; fork is deliberate for an alternative candidate or
explicitly owned work unit; resume requires contract/candidate/workspace reconciliation.

Standard is one integrated implementation lane. Orchestrated requires at least two
independently verifiable work units with explicit boundaries, one integration contract, and
cross-boundary verification. Parallel agents, parallel writers, and parallel execution are
optional implementation choices, not the classification test. Cheap Scout remains an optional
read-only fail-soft retrieval role and owns no lifecycle decision.

Task lifecycle terminals are `accepted`, `cancelled`, and `terminally_blocked`. Progress labels
such as `waiting_for_user`, recoverable `blocked`, `partial`, and `rework` are nonterminal.
KD-024's `accepted_with_waiver` remains a non-promoting evaluation classification; waiving a
mandatory criterion changes the contract and cannot relabel the original candidate as a
validated accepted outcome.

This decision supersedes the unnumbered user-selects-all choice in the prior `spec/04`,
`01-dna.md §L1`'s user-picked fixed sizes, restart/discard escalation prose, the prohibition on
preflight reduction, and definitions of Orchestrated based on size, risk, fixed agent counts, or
mandatory parallel writers. It does not supersede source-backed safety requirements for a
parallel-writer path when that optional path is selected.

Runtime transformations cannot silently substitute a weaker selected contract. Plan mode is a
distinct planning-only contract and cannot satisfy selected mutation or fresh-command work. A
selected implementation or command-execution path stops before dispatch/acceptance while plan
mode is active, or transitions explicitly out of plan mode and revalidates the reconciled
contract. The same fail-closed rule applies to selected structured-output, effort, model-identity,
LSP, bash, skill, schema, alias, and settings conjunctions.

The four LSP registration gates do not authorize acceptance when no applicable language server
exists or a required LSP call returns details.success false. Pinned `lsp/index.ts:2145-2160`
returns an ordinary tool result for those failures, so the coordinator must inspect required call
outcomes or select, reconcile, and validate an explicitly different non-LSP contract.

**Grounds:** C — explicit current-session user decisions; A — pinned OMP source shows that file
slash commands expand only from `/`-prefixed user input
(`extensibility/slash-commands.ts:110-129`, `session/agent-session.ts:4942-4966`) and that handoff
uses generated text to create and seed a new session (`session/session-handoff.ts:97-103,
217-275`).

**Because.** Requiring the user to distinguish Standard from Orchestrated exposes an internal
integration decision and fails for ordinary no-prefix requests. A prose “restart” is not a
runtime command transition, while discarding partial work risks user data and erases attributable
task-cycle cost. Contract-centric tasks keep retries and evidence accounting honest;
candidate-bound evidence prevents stale verification; structural Orchestrated classification
works whether work units execute sequentially or concurrently.

**Rejected.** *(a) Remove `/standard` and `/orchestrated` immediately* — clean but an unnecessary
compatibility migration in Topic 02. *(b) Keep all three workflows user-selected* — contradicts
the approved entry experience and main-session authority. *(c) Implement a durable state engine
now* — preempts Topic 04 and couples the conceptual contract to an unapproved storage design.
*(d) Define Orchestrated by actual parallelism or task risk* — either collapses the workflow
when sequential integration is safer or over-routes large/high-risk sequential tasks.

**Reverse if** a later explicit user decision changes the entry authority, or verified runtime
mechanics supply a safer native transition/state mechanism without weakening candidate evidence
binding. Topic 03 may choose a different execution topology; Topic 04 may choose any durable
representation that preserves these boundaries.

**Touches** `spec/04`, `01-dna.md §L1/L8`, `03-token-quality-model.md §A`, `spec/05 §G-H`,
`spec/13 §C/F`, Topic 03/08 scope notices, phases 02/03/06, installable main-session/command/
triage surfaces, and concise human documentation. No runtime state store, final agent topology,
benchmark harness, registry, license, Phase 00 evidence, or upstream source is changed.

---

## KD-027 — Benefit-gated three-agent topology and explicit Scout routing

**Decision.** *(Approved by the user on 2026-08-12.)* The main session is the Tech Lead, default
writer, verification owner, integrator, and final owner. Default execution is inline with no
spawn. Every spawn must name a concrete benefit, bounded contract, output consumer, stop
condition, fallback, and effective capability prerequisites.

The selected spawnable manifest is exactly Cheap Scout, Worker, and Reviewer. Explorer is
absorbed by the read-only Cheap Scout; Implementer is renamed Worker; the permanent Verifier is
removed; and `tech-lead.md` moves outside agent discovery. Cheap Scout produces advisory retrieval
evidence only and cannot edit, verify acceptance, review, integrate, or issue a verdict. Worker
owns one bounded implementation unit and defaults to exact `high`; the Tech Lead selects exact
`xhigh` for difficult or high-risk work. One General Reviewer uses dynamic concern profiles, runs
at exact `xhigh`, and is mandatory for security, authentication, durable data, database migration,
concurrency, public API, and destructive change concerns. Other review remains contract/risk
gated rather than workflow-stage gated.

Cheap Scout routes through OmniRoute to DeepSeek V4 Flash at provider `max`, represented by OMP
selector `omniroute/ds/deepseek-v4-flash:xhigh`. Retryable availability/runtime failure may use
only `omniroute/ds/deepseek-v4-pro:xhigh`, also mapped to provider `max`, then returns retrieval to
the Tech Lead. Weak Scout evidence is quality rework, not automatic provider fallback. The global
retry switch may be enabled only with explicit empty default/Worker/Reviewer chains. Worker and
Reviewer acceptance compares returned role/model/effort identity with the reconciled expected
identity, including paths that do not set `resolvedModelIsFallback`.

One writer is the default. Parallel Workers require disjoint scopes, proven isolation/capture,
and sequential integration; otherwise the Tech Lead selects one sequential writer and discloses
the fallback. Reviewer preference is a suitable different family, another suitable strong model,
then a same-model separate session with disclosure. Opus is a preference, never an implicit
universal gate.

**Grounds:** C — explicit current-session user approval of the topology, effort, and Flash→Pro
routing; A — pinned OMP source for discovery, effort gating/capping, fallback chains, returned
model identity, and credential fallback; official DeepSeek OMP integration documentation for V4
thinking support and `xhigh -> max` mapping.

**Because.** A permanent five-role chain spends expensive Lead/core-model work even when inline
execution is clearer, turns retrieval and verification mechanisms into mandatory people, and
makes workflow labels decide topology instead of task structure. Cheap Scout can absorb bounded
evidence gathering cheaply without owning acceptance. Dynamic Worker effort preserves cost on
moderate tasks and depth on difficult tasks. A single risk-gated Reviewer keeps independence where
it matters while avoiding an unconditional review spawn. Explicit availability fallback is easier
to observe and reason about than hidden quality-based model switching.

**Rejected.** *(a) Fixed Explorer→Implementer→Verifier→Reviewer execution* — role count is not a
quality guarantee and mandatory stages waste work. *(b) Mandatory Worker or Reviewer spawn based
only on workflow name* — contradicts the spawn-benefit and risk gates. *(c) Permanent security,
database, migration, or other specialist agents* — concern profiles are task data, not topology.
*(d) Opus as a universal gate* — quota/provider availability must have suitable fallbacks unless
the accepted task contract explicitly requires Opus. *(e) Cheap Scout verification or verdicts* —
retrieval evidence is not independent acceptance. *(f) Silent model changes after weak output* —
quality failure is rework or a new candidate, not availability fallback.

**Reverse if** measured Phase 06 evidence shows the selected topology cannot satisfy the quality
contract and a recorded replacement passes the same gates, or a later explicit user decision
changes the roster/routing. Provider availability may change concrete model assignments without
changing the logical contracts, but any such change must be disclosed and validated.

**Touches** `spec/03`, `spec/09`, active topology/routing projections, Phase 02 runtime migration,
Phase 05 installation/retirement, Phase 06 evaluation, the selected three-agent runtime manifest,
and current-product evidence. Topic 02 remains workflow/lifecycle authority; Phase 02 owns runtime
migration. Historical Phase 00 conclusions stay immutable and receive an explicit current-product
supersession identity.

---

## KD-028 — Durable local task authority, candidate evidence, and safe handoff/offload

**Decision.**

```yaml
decision: local immutable JSON bundle plus deterministic PowerShell state core
git_root: <absolute-git-common-dir>/agent-tasks
non_git_root: <project-root>/.agent-tasks
writer: one authority/integration lease per task
mutating_concurrency: distinct authoritative worktree plus scope reservation
candidate: scoped baseline-relative identity manifest, not backup
evidence: typed, immutable, candidate/contract-bound
handoff: two-phase structured transfer; user-authorized crash takeover
offload: transient raw tier plus compact promoted evidence
cleanup: dry-run, recoverable trash, separate exact-target purge
runtime: explicit shared core in Topic 04; automatic adapter gated to Topic 08
```

The authority root is local and untracked. Revisions and supporting records are immutable;
compare-and-swap revision/hash/lease checks serialize mutation. There is no heartbeat TTL and no
automatic takeover. A transcript, compaction summary, artifact URI, `.task/` scratch file, or
handoff prose is context—not lifecycle authority. Models never choose the final owned-output list;
the core derives the scoped candidate from baseline and current workspace bytes.

**Grounds.** C — the user approved local-only `agent-tasks` authority, separate worktrees for
different mutating tasks, explicit shared-core use, and no mandatory automatic adapter. A — the
implemented deterministic core, 300 core assertions, 70 installer/adapter assertions, and the
Topic 04 approved design.

**Because.** Conversation memory cannot safely arbitrate ownership, candidate bytes, evidence
validity, or crash recovery. A small local append-only bundle is inspectable, portable across
Claude/Codex sessions on the same machine, and independent of model/provider calls.

**Rejected.** Git-tracked lifecycle state; a database/service; one shared writer worktree;
model-authored output inventories; global evidence TTLs; prose-only handoff; automatic timeout
takeover; runtime artifacts as authority; automatic purge; and unprobed lifecycle hooks.

**Reverse if** multi-machine/team coordination becomes required, local filesystem semantics cannot
provide safe atomic publication, or Topic 08 proves and selects a different adapter without
creating a second reducer. Such a change requires a versioned migration, not silent root switching.

**Touches** DNA L11, specs 01/02/04/05/08/10/12–16, Phases 02/03/05/06/07, the installed
`state` component, and current-product Topic 04 evidence.

---

<!-- topic05-authority:kd-029 -->
## KD-029 — Progressive retrieval and optional CodeGraph capability

**Decision.** CodeGraph v1.5.0 is an optional and default-off retrieval capability behind the
checked-in adapter. Actor and retrieval capability are selected independently. The legal routes
form a four-arm matrix: Lead/native, Lead/CodeGraph, Scout/native then Lead, and Scout/CodeGraph
then Lead. Graph output is a hypothesis, never acceptance evidence by itself; absence needs native
retrieval corroboration. Any graph failure names the native retrieval fallback.

Each Git worktree owns one physical `.codegraph` index. Shared/symlinked indexes and lazy
initialization after a candidate is frozen are refused. Topic 04 owns state/cache binding and the
adapter rechecks candidate and source identity after retrieval. Models may provide a bounded
question, not process/path/environment authority. The integration excludes MCP, upstream
interactive setup, hooks, daemons, auto-update, and arbitrary shell exposure.

**Grounds.** C — the user approved Cheap Scout as inexpensive read-only retrieval with Flash
`xhigh` then Pro `xhigh`, while keeping Tech Lead and Reviewer authority independent. A — the
pinned upstream lock, deterministic adapter/installer suites, and four-arm benchmark harness.
Provider-backed comparison remains unrun unless separately authorized.

**Because.** Native search is simpler for exact text and local configuration, while a graph may
reduce relationship-search cost on source-fit tasks. Making either universal would erase that
distinction. The optional adapter preserves reversibility and gives failures one observable,
bounded route back to native evidence.

**Rejected.** Default-on or universal CodeGraph; shared indexes; graph-as-truth; MCP or a second
runtime; interactive install, hooks, daemon, auto-update, and arbitrary shell; opaque retries;
Cheap Scout execution/review/acceptance; Reviewer inheritance of Scout evidence; provider
substitution; and promotion from estimates or contaminated/unpaired runs.

**Reverse if** a recorded, paid or otherwise provider-truthful campaign passes correctness and
contamination gates and demonstrates a source-fit task-class benefit without worsening a
load-bearing measure. Even then, a task-class recommendation is not a universal default.

**Touches** DNA L4/L9, specs 03/05/07/12–15, phases 03/05/06, the optional `codegraph`
component, registries `adopt-017`/`reject-018`/`reject-019`, and `docs/retrieval.md`.

---

<!-- topic06-authority:kd-030 -->
## KD-030 — Managed agent boundary over native OMP `task`

**Decision.** Template-managed dispatch uses a trusted, same-name `task` extension that validates a
closed Topic 04 work-unit projection, invokes the native OMP `task`, validates the returned role,
model, effort, structured result, and runtime signals, and publishes only a provisional Topic 04
work-unit outcome. The portable contract core is runtime-independent; the installed entry point is
`.omp/bin/omp-managed.ps1`. Bare OMP, Vibe, `eval`, and unrelated internal-agent facilities remain
usable but are unmanaged and cannot produce a Topic 06 receipt.

The managed boundary is local and requires no Git commit. Topic 04 remains the sole durable task,
candidate, acceptance-criterion, evidence, handoff, and acceptance authority. Topic 06 stores no
parallel task ledger and never upgrades a receipt or worker result into parent acceptance.

**Selected role policy.** Cheap Scout uses DeepSeek Flash `xhigh`, with DeepSeek Pro `xhigh` only
as its disclosed availability fallback; if the managed Scout route is unavailable, the Tech Lead
retrieves inline. Worker defaults to `high` and may use `xhigh` only when the Tech Lead classifies
the work as hard. Reviewer is always `xhigh`. Reviewer input is ARTIFACT + CONTRACT; Worker CLAIM,
hidden reasoning, and the parent transcript are excluded. The exact returned role/model/effort is
reconciled before a result is accepted as a managed observation.

**Runtime constraints.** Managed v1 is blocking. It supports one dispatch and bounded native batch
dispatch, rejects async and nested-agent requests, refuses mutation/fresh-command contracts in
plan mode, and treats the forced partial threshold as nonterminal. The managed overlay sets only
`task.softRequestBudget: 200`; the runtime's 1.5× forced-partial boundary is therefore 300
requests. Historical `.omp/schemas` files remain Phase 00 evidence only; the executable boundary
schema and role `output:` contracts are current authority.

**Fallback.** If the managed component, capability preflight, selected model, or wrapper is
unavailable, the Tech Lead either chooses and revalidates a genuinely different contract or works
inline. Inline fallback must not manufacture a self-packet, self-review, or managed receipt.

**Grounds.** The pinned OMP runtime preserves the built-in implementation before extension
overrides and exposes same-name delegation. Installed-runtime probes confirm that the wrapper is
last, calls the native implementation, and can inspect the completed result. Deterministic tests
cover state projection, route identity, result rejection, batch behavior, install/rollback, and
reviewer-claim exclusion without provider calls.

**Rejected.** A second orchestrator; Git-backed operational state; prose-only packets; installed
`.omp/schemas` as runtime enforcement; accepting raw native output directly; automatic self-review;
silent model/effort substitution; async or nested managed v1; and requiring Opus to proceed.

**Open, nonblocking.** `OPEN-T06-RUNTIME-01`: OMP does not expose one universal interception seam
for unrelated Vibe/`eval`/internal-agent paths. That is not required for this selected managed
boundary. If universal coverage is later required, resolve it upstream rather than widening this
local wrapper into a second runtime.

**Touches** DNA L3/L7/L9/L11/L12, specs 03/05/06/08–10/12/13/15, phases 01–07, the
`agent-boundary` component, Topic 04 state projection, operator documentation, and current-product
Topic 06 evidence.

---

<!-- topic07-authority:kd-031 -->
## KD-031 — Explicit safe context-full compaction with authoritative continuity kernel

**Decision.** Managed sessions disable automatic semantic compaction and context promotion. The
only supported semantic compaction path is the argument-free `/safe-compact` command in the
trusted managed OMP entry point. It authorizes exactly one native
`ctx.compact({ mode: "soft" })` transaction, which selects local context-full summarization for
that transaction. It adds no continuation prompt, retry loop, second compactor, or new runtime.

Topic 04 remains the sole task, ownership, revision, candidate, evidence, checkpoint, and handoff
authority. Every new Quick, Standard, or Orchestrated task records its exact `workflow_class` and
complete initial `locked_decisions` in `create-task`. A legacy active task must initialize both
through `set-continuity-contract` with the exact current revision/hash/lease compare-and-swap.
The adapter reads one closed, hash-stable Topic 04 continuity kernel; neither the native summary,
conversation, recovery artifact, nor injected kernel becomes lifecycle authority.

**Completeness rule.** Task identity, workflow class, objective, mandatory acceptance criteria,
authority, execution mode, write scope, obligations, revision/lease identity, and every locked
decision are mandatory for all three workflows. Standard and Orchestrated refuse any missing
applicable secondary continuity field. Quick alone may carry an explicitly named degradation for
an actually absent secondary checkpoint/work-unit/next-action/blocker/risk/candidate/evidence
field; it never drops purpose, authority, criteria, or decisions.

**Transaction and pressure rule.** Before native compaction, the adapter verifies a persisted idle
main session, exact current-session ownership, one active task, current revision/lease/kernel,
branch bytes, a locally written and re-read recovery artifact, and a single-use authorization
nonce. Every compact call without that nonce is cancelled. The next normal user prompt receives
one fresh canonical kernel exactly once; there is no hidden auto-continue. At the managed pressure
boundary, ordinary provider dispatch is aborted and the user must invoke `/safe-compact` or make
an explicit Topic 04 handoff. One unresolved attempt stops. Bounded subagents cannot invoke the
command; pressure aborts the child, produces a failed/partial Topic 06 outcome, and never triggers
an automatic retry.

**Unsupported paths.** Automatic context-full compaction, built-in `/compact`, direct `shake`,
`snapcompact`, automatic handoff, remote compaction, and remote streaming are outside the managed
guarantee. Bare OMP can still expose native behavior, but it cannot claim Topic 07 continuity.
OmniRoute and model routing remain separate and unchanged. Opus is not a continuity dependency.

**Promotion gate.** Source attachments are pinned to OMP commit
`3a8591a8af5b6d200088d12ca75a5517cb064fa8`. The component supports OMP 17.2.10 and 17.2.12, but
default promotion requires a stop-before-provider canary on both versions. Current status is
`IMPLEMENTED_NOT_PROMOTED`: installed 17.2.12 passes locally, while `OPEN-T07-RUNTIME-02` records
that a verified local 17.2.10 executable is unavailable. No download or downgrade is implied.

**Grounds.** The pinned runtime exposes native soft compaction, cancellable preparation,
compaction lifecycle hooks, persisted preserve data, local artifact/session APIs, and a final
before-provider boundary. Deterministic tests cover schema/state projection, transaction races,
kernel injection, pressure abort, bounded-child settlement, packaging, installation, rollback,
and a zero-network provider sentinel.

**Rejected.** Automatic semantic compaction; rescue shake; summary-as-authority; focus text that
can rewrite the kernel; remote compaction; hidden continuation; automatic retry or session
handoff; subagent compaction; Git-backed operational continuity; and requiring Opus to proceed.

**Touches** DNA L8/L11/L12, specs 01/02/05/13/15, phases 01/03/05/06, Topic 02 workflow entry,
Topic 04 durable state, Topic 06 result settlement, the `agent-boundary` component, operator
documentation, compatibility registry, and current-product Topic 07 evidence.

---

<!-- round09-12-authority:kd-032 -->
## KD-032 — Topics 09–12 close through one deterministic, authority-bounded readiness round

**Decision.** Topics 09 and 10 are delta closures over KD-028, KD-030, and KD-031, not new
lifecycle or orchestration authorities. Topic 04 remains the sole durable task, candidate,
evidence, invalidation, handoff, and final-acceptance authority. Topic 06 results remain
provisional. There is no permanent Verifier and no universal Reviewer dispatch. When independent
review is selected, the General Reviewer uses `critical | important | minor` at exact `xhigh`;
`critical` and `important` block, while `minor` alone may support `APPROVED_WITH_NOTES`.

Every candidate mutation invalidates acceptance-bearing proof. A fresh delta-scoped review may
read only the exact base/new candidate and unchanged bound concerns, but it still creates a new
result and never reuses approval. Opus is optional, never a readiness gate: unavailable Opus uses
the approved disclosed reviewer fallback. Cheap Scout remains optional read-only retrieval under
KD-027 and never becomes verification, review, or acceptance authority.

**Evaluation boundary.** The default Round 09–12 evaluator is deterministic and starts no
provider/model process. Synthetic quality/security/promotion records validate machinery only.
Campaign execution requires separate explicit provider-call authority, a positive evidence budget,
an exact runtime path, and a frozen manifest. Environment state is `PASS | ENVIRONMENT_BLOCKED |
NOT_RUN`, separate from the exact verdict set `PROMOTE_EFFICIENCY | PROMOTE_QUALITY | REJECT |
DEFER_INCONCLUSIVE`. A three-pair pilot cannot promote; only the frozen sequential final procedure
in spec 13 may do so.

**Release boundary.** Topic 12 derives readiness from the closed contracts, deterministic evidence,
and scratch-only install/discovery/repair/uninstall/rollback proof. Scratch proof is not live
installation, provider evidence, or Git publication. In the absence of separately authorized final
campaign evidence, OMP stays `IMPLEMENTED_NOT_PROMOTED / installable true`; Claude stays
`DESIGNED_NOT_VERIFIED / installable false`. OMP 17.2.10, Claude runtime, and model-assisted arms
remain explicit limitations, not blockers for model-free implementation and not fabricated PASS.

**Rejected.** A second task ledger; permanent Verifier; universal Reviewer; mandatory Opus;
promotion from deterministic/synthetic/pilot records; provider calls by default; hidden fallback;
hand-authored promotion results; live install or Git mutation inferred from implementation
approval; and a fifth verdict that conflates environment state with promotion.

**Touches** specs 10/12/13/15/16, phases 04–07, repository evaluation tooling, scratch package
proof, operator documentation, and the bounded current-product Round 09–12 evidence bundle.

---

## Open questions this log cannot close

Each needs a live experiment, not more source reading. Recorded here so no decision
silently assumes an answer.

| # | Question | Blocks | Cheapest resolution |
|---|---|---|---|
| OQ-A | Which forms does frontmatter `output:` accept — JTD, JSON Schema, or both? Typed `unknown` at `helpers.ts:289`, `object\|boolean\|string\|null` on the wire; `tools/jtd-to-json-schema.ts` exists and hints at JTD | KD-002, KD-004 | One spawn per candidate form; inspect `structuredOutput.status` |
| OQ-B | Do project-`.omp/` hooks load inside subagent sessions, or only the main session? | Whether hooks can serve as per-worker quality gates | Register a `tool_call` hook; spawn a worker; observe whether it fires |
| OQ-C | Historical/evaluation-only token delta of `snapcompact` vs `shake` | None; KD-031 keeps both outside managed fallback | Same fixture, both strategies, only if separate research is authorized |
| OQ-D′ | Does an `autoloadSkills` body charge the child's budget or the parent's? (The *listing* half is closed by KD-014; this is the `sendCustomMessage` path at `task/executor.ts:3234-3243`) | `spec/11 §B` cost table | Autoload a marker skill; diff `contextTokens` at first turn |
| OQ-E | Does a `tools:` allowlist hard-block a fabricated call to an unlisted tool? | `spec/02` OQ-4; KD-007's strength | Have a worker emit a call for an unlisted tool |
| OQ-F | On Windows, does `mode: auto` select `projfs`/`block-clone` or degrade to `rcopy`, and does two-writer isolation hold? | `spec/08` entirely | Two concurrent isolated writers on the target volume |
| OQ-G | Does symbol-graph ranking improve the KD-024 quality/core-token contract on unfamiliar-repo tasks? | KD-015's reversal condition | Frozen stable-product A/B: ranking vs `glob`+`read`; pilot may reject but final promotion requires `spec/13 §C` |

OQ-A remains the highest-priority for the contract layer: KD-002 and KD-004 both rest on it,
and it is the cheapest to settle.

OQ-H is closed by KD-030: the selected managed boundary is the same-name native `task` wrapper.
`eval` remains an unmanaged OMP facility and its output cannot claim a Topic 06 receipt.
