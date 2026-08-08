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

**Decision.** Each worker declares its result schema in its own frontmatter `output:`
key. Caller-side `outputSchema` on the `task` call is reserved for explicit per-call
narrowing, not the default path.

**Grounds:** A for the mechanism; C for choosing frontmatter over call-site.

**Because.** `parseAgentFields` reads `output` off the frontmatter into
`ParsedAgentFields.output` (`discovery/helpers.ts:289`). Schema source is tracked
explicitly as `"caller" | "agent" | "session" | "none"` (`task/types.ts:20`), with
`outputSchemaOverridesAgent` recorded when the call site wins
(`task/executor.ts:384`) — so both paths are first-class and the precedence is
designed, not incidental. Choosing frontmatter is the C part: the schema travels with
the agent and cannot be forgotten at a call site, and there is exactly one place to
change it.

**Rejected.** *Inline `outputSchema` at every dispatch.* Duplicates the source of truth
across three command files and makes drift the default outcome.

**Reverse if** a live spawn shows frontmatter `output:` is not honoured, or accepts a
form the YAML contracts cannot express. This is a real gap — see OQ-A below.

**Touches** `spec/06`, `spec/01 §4`, all four worker agent files.

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

**Decision.** L0 validation parses every agent `output:` block and fails on: any `$ref`,
any construct that makes the schema unrepresentable, and any required field the agent's
prose never instructs it to produce.

**Grounds:** A (the silent-degrade path) + C (the lint rule set).

**Because.** KD-003 established that a malformed schema does not fail the spawn — it
yields `status: "unavailable"` and unvalidated output. That is a silent failure with no
runtime signal, which is exactly the class `spec/13` exists to catch statically. A schema
nobody validates is worse than no schema: it produces the *appearance* of enforcement.

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

## KD-006 — Commands dispatch in batch shape, with `context` populated

**Decision.** Every dispatch in every command file uses the batch wire form
`{context, tasks: [...]}`. `context` carries the shared objective and constraints once,
never the parent transcript. Command prose must not show the flat `{agent, task}` form.

**Grounds:** A.

**Because.** `task.batch` defaults to **`true`** (`config/settings-schema.ts:4570-4580`),
so the shape the model actually sees is `{context, tasks[]}` with **`context` required**
(`task/types.ts:167-171`). The flat form survives for internal callers and stale
transcripts (`types.ts:285-305`) but is rejected model-side when batch is on. Command
prose written against the flat form is wrong under the default baseline — and this is not
recorded anywhere in `spec/02` or `spec/04`.

**Second-order benefit.** A required shared `context` is a token win, not a tax: text
common to N workers is stated once instead of N times. For parallel exploration this is
the difference between one copy of the objective and four.

**Rejected.** *Disable `task.batch` to keep the simpler flat shape.* Trades a real
token saving for familiarity, and adds a settings deviation the template would have to
deploy and verify.

**Reverse if** the default flips. Watch `settings-schema.ts:4570-4580`.

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

**Touches** `spec/02 §B`, `spec/03 §B/§H`, all four worker agent files.

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

**Rejected.** *Leave budgets undocumented.* Silent truncation into a plausible-looking
result is the worst available failure mode.

**Reverse if** the defaults change materially.

**Touches** `spec/05 §C`, `spec/15 §D`, `spec/13` L4 (add a forced-partial-yield case).

---

## KD-012 — Result telemetry is the measurement surface; nothing is hand-counted

**Decision.** `tokens-per-accepted-outcome` is computed from the `SingleResult` telemetry
OMP already returns. The benchmark harness reads those fields; it does not estimate from
transcript length or `chars / 4`.

**Grounds:** A.

**Because.** Every spawn returns `tokens` (input + output + cacheWrite, excluding
cacheRead), `requests`, `contextTokens`, `contextWindow`, `cost`, `usage`, `durationMs`,
`structuredOutput`, and `patchPath`/`branchName` (`task/types.ts:471-539`), with live
equivalents streaming on `AgentProgress` over `task:subagent:*` EventBus channels
(`:395-469`, `:59-65`). Per-spawn `modelRole`, `resolvedModel`, and
`resolvedModelIsFallback` are also reported (`:428-434`, `:500-505`).

That last triple closes a failure mode `spec/09 §B` left open. The spec says a
misresolved model role fails *silently*; in fact `resolvedModelIsFallback` is returned on
every spawn. It is silent only because nobody reads it. Detection is a coordinator
acceptance check, not new infrastructure.

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
roles. The session looks configured. `/standard` is simply not there, and `@explorer`
resolves to nothing.

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

So the full listing is present in every worker session, not just the main one. At ~90
tokens per skill worst case, a Standard workflow (main + explorer + implementer + verifier)
pays **4×**, and Orchestrated with parallel workers pays more:

| N skills | Per session | Standard (4 sessions) | Orchestrated (6) |
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
ranking primitive, an agent answers from filename plausibility and its own priors. The
output is fluent, confident, and unverifiable — there is no error signal. So describing the
Explorer's LLM-judged "ranked evidence" **as** the repository map relabels the failure mode
as the solution.

**Rejected.** *Leave the spec argument as written.* A correct conclusion resting on a false
premise is fragile: the next reviewer who checks the premise reopens the settled
conclusion.

**Rejected for v0.** *Ship a `repo_rank` custom tool now.* `.omp/tools/*` is a real
discovery surface (`discovery/builtin.ts:750-796`) and a deterministic, mtime-cached,
pull-only ranking tool would satisfy every objection in `spec/07` — it is recomputed so it
cannot go stale, invoked explicitly so it is not paid unconditionally, and computes
something OMP provably lacks. But it is new machinery with an unmeasured benefit, and v0's
deliverable is a measured baseline. It becomes a candidate **after** the baseline exists.

**Reverse if** a measurement shows Explorer-with-ranking beats Explorer-with-`glob`+`read`
on tokens per accepted outcome for unfamiliar-repo tasks. Absent that number, the gap is
documented rather than filled.

**Touches** `spec/07 §D`, `spec/13` L3 fixtures, `registry/rejected-mechanisms.yml`.

---

## KD-016 — Strictness governs how hard you look; confidence governs what you report

**Decision.** The Reviewer contract carries both halves explicitly, and the resolution rule
between them is stated: **uncertainty resolves toward blocking, not toward silence.** A
finding that cannot be proven is dropped; a *blocking* finding that cannot be refuted stays
blocking.

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

**Touches** `spec/10 §C`, `template/.omp/agents/diff-reviewer.md`.

---

## KD-017 — Discipline skills are behavioral interventions, and are tested under pressure

**Decision.** Every discipline skill (`evidence-before-completion`, `systematic-debugging`,
`failing-test-first`) ships with **two** fixture classes: activation fixtures
(does it trigger?) and **pressure fixtures** (does it hold when the model has a reason to
skip it?). Negative activation fixtures name the skill that *should* win instead.

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
layers — schema (shape) and independence (the verifier did not write the code) — and provenance
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
`impl`, which dispatches the Implementer at code outside the change's scope. That is the worst
available outcome: scope creep justified by a verification result, on a defect the change did
not cause.

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

**Touches** `spec/10 §B`, `verifier.md` `output:` schema, `spec/13` L2 cases.

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

## Open questions this log cannot close

Each needs a live experiment, not more source reading. Recorded here so no decision
silently assumes an answer.

| # | Question | Blocks | Cheapest resolution |
|---|---|---|---|
| OQ-A | Which forms does frontmatter `output:` accept — JTD, JSON Schema, or both? Typed `unknown` at `helpers.ts:289`, `object\|boolean\|string\|null` on the wire; `tools/jtd-to-json-schema.ts` exists and hints at JTD | KD-002, KD-004 | One spawn per candidate form; inspect `structuredOutput.status` |
| OQ-B | Do project-`.omp/` hooks load inside subagent sessions, or only the main session? | Whether hooks can serve as per-worker quality gates | Register a `tool_call` hook; spawn a worker; observe whether it fires |
| OQ-C | Real token delta of `snapcompact` vs `shake` on these workflows | KD-009 | Same fixture, both strategies, compare telemetry |
| OQ-D′ | Does an `autoloadSkills` body charge the child's budget or the parent's? (The *listing* half is closed by KD-014; this is the `sendCustomMessage` path at `task/executor.ts:3234-3243`) | `spec/11 §B` cost table | Autoload a marker skill; diff `contextTokens` at first turn |
| OQ-E | Does a `tools:` allowlist hard-block a fabricated call to an unlisted tool? | `spec/02` OQ-4; KD-007's strength | Have a worker emit a call for an unlisted tool |
| OQ-F | On Windows, does `mode: auto` select `projfs`/`block-clone` or degrade to `rcopy`, and does two-writer isolation hold? | `spec/08` entirely | Two concurrent isolated writers on the target volume |
| OQ-G | Does symbol-graph ranking actually reduce tokens per accepted outcome on unfamiliar-repo tasks? | KD-015's reversal condition | A/B: Explorer with a ranking tool vs `glob`+`read`, ≥3 runs/arm |
| **OQ-H** | Should `/orchestrated` dispatch via the `task` tool or via `eval`'s `agent()`/`parallel()` DSL? | All of `spec/08`'s CR-29/30/31/32 machinery | One `/orchestrated` fixture implemented both ways; compare tokens per accepted outcome **and** failure-mode visibility |

OQ-A remains the highest-priority for the contract layer: KD-002 and KD-004 both rest on it,
and it is the cheapest to settle.

**OQ-H is the highest-priority overall**, because it is not a tuning question — it is a
mechanism the spec chose *without knowing the alternative existed*
(`05-coverage-audit.md §C`). `eval`'s `agent()` takes **per-call `apply`**
(`eval/agent-bridge.ts:30,137`), which is the exact capability `spec/08 §E-7` states does not
exist and which the entire capture-first settings apparatus was built to work around. It also
throws on isolated-apply and nested-patch failure (`:174-190`) where the `task` path is
silent. Until OQ-H is answered, every CR-31 deliverable is work that may be unnecessary.
