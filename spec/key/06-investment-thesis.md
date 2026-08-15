# 06 — Investment Thesis

> **Two questions.** What is left to optimize across the OMP and OmniRoute layers, and what
> makes a mechanism *worth building* rather than merely possible.
>
> The second question decides the first, so it comes first. Section §A is the test; §B–§D
> apply it to the two layers; §E ranks everything; §F answers the three candidates named
> directly (MCP, semantic search, memory).
>
> Grades per `00-method.md §B`. OMP citations are `packages/coding-agent/src/<path>:<line>`
> @ `3a8591a`.
>
> Former fixed-role routing examples are historical hypotheses; selected model responsibilities
> come only from the Topic 03 manifest.

---

## A. The test: six gates, in order

`00-method.md §C` filters *upstream mechanisms*. This is the filter for **our own build
decisions**, which is a different question — nothing upstream is involved when deciding
whether to wire memory. Six gates, and a candidate must pass **all** of them:

```
1. ATTACHMENT     Does it name an OMP primitive that carries it?
                  NO → documentation, or a defect. Stop.

2. FAILURE        Does it solve a failure we have OBSERVED, with a recorded instance?
                  NO → stop. "It would probably help" is not a failure.

3. DUPLICATION    Does the runtime already do this?
                  YES → use the runtime's version. Stop.

4. TIER + MULTIPLIER   Which tier, and multiplied by what?
                  Unknown multiplier → stop until it is known.

5. CONSTRAINT     Could it weaken verification, evidence, or independence?
                  YES → REJECT regardless of benefit. Hard gate.

6. REVERSIBILITY  Can it be removed, and is the procedure written?
                  NO → stop.
```

### Gate 2 is where almost everything dies

This is the finding that should govern the whole roadmap. **We have no measured, frozen
baseline pair.** `spec/13` L3/L4 has never run; `benchmark.ps1` executes nothing. So for
every candidate in this file, the honest answer to *"what failure does this solve?"* is
currently **"unknown"**.

That has a sharp consequence: **the baseline pair is not a prerequisite for the roadmap, it
is the first item on it.** The last promoted template must be frozen for candidate decisions;
pinned plain OMP must be frozen for release-value decisions. Until both exist, every
investment decision is a guess dressed as architecture, and
`03-token-quality-model.md §A`'s objective function has no validated denominator.

The failure mode this gate prevents is specific and this project has already committed it
once: `.omp/policies/` was 581 lines built to solve a problem nobody had recorded.

### Gate 3 is where this question's real answer lives

`05-coverage-audit.md` found that 24% of OMP's settings surface was seen. The corollary is
that **the highest-return work is not building new mechanisms — it is using the ones already
paid for.** A capability that ships with the runtime costs nothing to adopt, has no removal
procedure to write, and cannot drift from upstream.

Three of the four Tier-1 items in §E are gate-3 discoveries: capability we already own and
were not using.

### The denominator test, stated plainly

Every candidate must first clear the quality gates, then answer: **does this improve validated
accepted-outcome rate, or core workflow tokens per validated accepted outcome, relative to the
last promoted template?** Capability without a validated outcome is a cost with no recorded
benefit. Release checkpoints separately ask whether the promoted template adds value over
pinned plain OMP. Exact promotion semantics live in `spec/13 §C`.

---

## B. The OMP layer — deep, and mostly unexplored

**Surface:** 607 settings, ~50 subsystems, 24% referenced. This is where essentially all
remaining optimization lives.

The asymmetry worth internalizing: OMP is not a model provider with a config file. It is a
runtime with a **discovery system, an extension system, a hook system with 25 events, four
scripting backends, three memory backends, and an orchestration DSL.** The template
currently uses six discovery paths and one dispatch mechanism.

Ranked by what they could change, the unexplored OMP surfaces are:

| Surface | Status | Gate that decides it |
|---|---|---|
| `eval` orchestration DSL | **Competes with `/orchestrated`** | 3 (duplication) — the runtime may already do this better |
| Handlebars in commands | **Owned, unused** | 3 — capability already paid for |
| Turn budget (`+Nk!`) | **Owned, unused** | 3 — runtime enforcement we said didn't exist |
| Hooks (25 events, `tool_call` can block + rewrite args) | Deferred on OQ-B | 1 — unverified whether it loads in subagents |
| `.omp/tools/*` custom tools | Deferred (KD-015) | 2 — would fill the ranking gap, unmeasured |
| `mnemopi` / `hindsight` / `local` memory | Untouched | 2 — no observed failure |
| `WATCHDOG.yml` advisors | Untouched | 5 — a mutating watcher risks the constraint |
| `prewalk`, `agentModelOverrides`, `disabledAgents`, `eager` | Untouched | 4 — cheap, but unmeasured |
| `SYSTEM.md` | Rejected | 5/6 — total blast radius |

---

## C. The OmniRoute layer — one lever, currently a no-op

This is the shorter section, and the brevity is the finding.

OmniRoute is a **gateway**. It does not decompose work, manage context, or enforce schemas —
OMP does all of that. So the layer's optimization surface is essentially one-dimensional:
**which model runs which role.**

And that lever is currently disconnected. Verified in the live baseline
(`~/.omp/agent/config.yml`, read this pass):

```yaml
modelRoles:
  default: omniroute/codex/gpt-5.6-sol-high
```

The frozen five-role baseline pointed every project alias at one model, while the *installed*
user config defined only `default`. That is historical measurement input, not a selected
topology. After reconciling the Phase-00 experiment:

- E2 supersedes the earlier fall-through hypothesis: missing and unknown aliases hard-fail before
  session creation, and unavailable models surface an error with no fallback.
- Project role values override global values.
- The former `spec/09 §C` note — "five aliases, one destination; the routing layer provides
  zero differentiation" — accurately describes that frozen baseline. Current aliases come
  only from the Topic 03-selected manifest.
- `resolvedModelIsFallback` detects retry fallback only; resolvedModelIsFallback does not mark
  credential fallback to the parent model. Acceptance compares returned modelRole and resolvedModel with the expected
  identity after reconciling `task.agentModelOverrides`; the flag is an additional gate, not the
  whole detector.

### The single highest-value OmniRoute investment

Differentiate two selected responsibility classes and measure. When the Topic 03 manifest
contains them, retrieval and deterministic command verification are candidates for the
cheaper/faster tier, while mutation, integration, and non-author judgement remain candidates
for the strong tier. The experiment compares selected contracts, not former role names.

Why this split, grade **C**: ranked retrieval is mechanical and volume-bound, while command
verification derives much of its determinism from the commands rather than the model. Those
responsibilities are natural cheap-tier candidates. Mutation, integration, and judgement
carry reasoning load where errors are expensive to recover.

Why it matters beyond cost: a selected non-author judge on a **different model family** than
the candidate author may catch what the author rationalized. Same-model review can inherit
same-model blind spots. That is a *quality* argument for differentiation, not a cost one —
and it is the only argument in this file where the cheaper option might also be the better one.

**This is also the cheapest experiment in the project.** It is a `config.yml` edit plus one
A/B arm. It requires no new mechanism, no removal procedure, and it converts the entire
model-role abstraction from unexercised to proven.

Two OmniRoute facts to establish before relying on it, both grade **D** — the gateway was
not reachable this pass (`127.0.0.1:20128` refused on `/v1/models`, `/models`, `/health`):

1. **The catalog.** Which models are actually available. Differentiation is impossible if
   the gateway exposes one.
2. **Strict schema support.** `spec/README` OQ-1 asks whether `output:` enforcement survives
   the `openai-codex-responses` path, since `tryEnforceStrictSchema` falls back per provider.
   The entire contract layer (KD-002/003) rests on this and it is still unverified.

---

## D. Two live-baseline corrections

Reading `~/.omp/agent/config.yml` this pass settled two things the spec had wrong or open.

**D-1 — historical live baseline, superseded for managed continuity.** This pass observed
`compaction.strategy: shake` in the user-owned live config and correctly established that native
OMP defaults to `snapcompact`. KD-031 later supersedes both as a managed product choice: the final
runtime overlay reasserts `strategy: off`, disables automatic/remote/auto-continue paths, and
permits only armed argument-free `/safe-compact` for one native soft transaction. The old live
observation remains evidence, not current authority; OQ-C is evaluation-only and blocks nothing.

**D-2 — historical live settings observation.** `task.isolation.apply: true` was the live value.
This is the CR-31 hazard, present
in the actual environment. The Orchestrated parallel path is **unsafe as currently
configured**, exactly as `spec/08 §E-9` predicted, and the mandatory preflight would refuse
today. Also live: `softRequestBudget: 120` (not the documented default 200, so KD-011's
forced-partial-yield threshold is *lower* here — 180 requests, not 300), `enableEffort: true`
(so KD-010's lever is real in this environment), `enableLsp: true`, `advisor.enabled: false`,
`memory.backend: "off"`, `autolearn.enabled: false`.

The last three are worth noting: the three biggest "should we build this?" candidates in
§F were all **off** in that captured live baseline. Current effective managed values come from the
manifest-coupled overlay and runtime preflight, not this historical snapshot.

---

## E. The ranked roadmap

Ordered by return, with the gate that justifies the position.

### Tier 0 — do first; everything else is unpriceable without it

| # | Item | Why first |
|---|---|---|
| 0.1 | **Frozen baseline pair** — fixtures + real harness reconciling main-session and unique per-spawn telemetry | Gate 2 has no answer until the stable-product candidate baseline and pinned plain-OMP release baseline exist without double counting |
| 0.2 | **OQ-A** — which forms `output:` accepts | KD-002 + KD-004 both rest on it; one spawn per candidate form |
| 0.3 | **OQ-H** — `task` vs `eval` for `/orchestrated` | May delete most of `spec/08`'s CR-29/30/31/32 machinery. Deciding *after* building it wastes the build |
| 0.4 | **OmniRoute reachability + catalog + strict-schema check** | Gates the contract layer (OQ-1) and all of §C |

### Tier 1 — high return, low risk, already owned

| # | Item | Gate | Cost |
|---|---|---|---|
| 1.1 | **Handlebars command templates** (G-3) | 3 — owned, unused | Zero new; enables `{{#if}}` gate matrices and a `/work` router as a branch |
| 1.2 | **Two model roles differ + A/B** (§C) | 3 + 4 | One config edit; converts the routing seam from unexercised to proven |
| 1.3 | **Silent-failure lint set — 11 entries** (`05 §J.2`) | 2 — each is an observed runtime behavior | L0 checks; catches the defect class that has bitten this project most |
| 1.4 | **Turn budget** (`+Nk!`) (G-6) | 3 — owned, unused | Zero; the runtime fan-out ceiling `spec/05 C-4` said didn't exist |
| 1.5 | **Read `resolvedModelIsFallback` and compare exact returned identity** in the acceptance check | 3 — all fields are already returned per spawn | The flag rejects retry fallback; returned `modelRole` + `resolvedModel` comparison closes override and credential misroutes the flag does not mark |

Read resolvedModelIsFallback and compare exact returned identity in the acceptance check. The
table shorthand above names both required gates; neither one substitutes for the other.

Every Tier-1 item is a **gate-3 pass**: capability the runtime already provides. None
requires a removal procedure, none can drift from upstream, none adds a per-turn cost.

### Tier 2 — conditional, named trigger required

| # | Item | Trigger that would justify it |
|---|---|---|
| 2.1 | `repo_rank` custom tool (KD-015) | OQ-G: measured Explorer-with-ranking beats `glob`+`read` on unfamiliar repos |
| 2.2 | Hooks as per-worker gates | OQ-B: project hooks verified to load in subagent sessions |
| 2.3 | MCP beyond Context7 | A retrieval question local sources + `lsp` provably cannot answer |
| 2.4 | `prewalk` | A/B showing quality holds (`03 §C-4` — highest-leverage untested lever, and the one most likely to trade quality invisibly) |

### Tier 3 — defer; fails gate 2 today

Memory (all three backends), advisors, autolearn, semantic memory. Not rejected — **unpriced**.
Each needs a recorded failure instance before it is a candidate. §F explains why.

### Tier 4 — never

Anything that weakens verification, evidence, or independence (gate 5). `SYSTEM.md`
(gate 5/6). A second orchestrator (gate 3). Self-modifying acceptance criteria — the
`Agent-Skills-for-Context-Engineering` "weakening the evaluator" anti-goal.

---

## F. The three you named

### F-1. MCP — mostly not worth it, and the reason is structural

MCP is a **tool-transport protocol**, not a capability. It adds *access*, not *judgment*, and
this template's failure modes are judgment failures: false completion, unranked retrieval,
scope creep. No MCP server fixes any of those.

Surface verified: `mcp.enableProjectConfig`, `.renderMarkdownResults`, `.notifications`,
`.notificationDebounceMs`; `.omp/mcp.json` / `.mcp.json` discovery (`builtin.ts:206-211`);
OAuth, Smithery registry, tool-cache, tool-bridge (`mcp/`, 20 files).

**Verdict: gate 2 fails for every server except one shape.** The exception is
**versioned external documentation** (Context7), which answers a question local sources
genuinely cannot: *"what is the current API of a dependency at the version we use?"* That is
already position 4 in the retrieval order (`reject-012`) and correctly not position 1.

The cost is not the tokens — it is that **every MCP tool's description is persistent tier**,
the same multiplier that caps the skill library at 10 (KD-014). A server exposing 20 tools
is 20 more descriptions in every session, including every subagent. MCP servers are subject
to the same catalog-size discipline as skills, and nothing in the spec says so.

**Actionable now, cheap:** state that MCP tool descriptions count against the persistent
budget, and that adding a server is a KD-level decision — not a convenience.

### F-2. Semantic search — the real gap, but not the real fix

This is the most interesting of the three, because **the gap is confirmed and the obvious
solution is off-label.**

KD-015 established grade **A** that OMP has **no ranking primitive**: `lsp` enumerates and
name-searches, `grep`/`ast_grep` match patterns. Nothing answers *"of the symbols I have not
read, which 30 matter for this task?"* That is a genuine capability gap, and it is the one
place where an Explorer must answer from filename plausibility with no error signal.

And OMP *does* ship a vector engine — `packages/mnemopi` has `embeddings.ts`,
`vector-index.ts`, `binary-vectors.ts`, `mmr.ts`, `episodic-graph.ts`, `fastembed-runtime.ts`,
plus `mnemopi.embeddingModel` / `.noEmbeddings` / `.polyphonicRecall` settings.

**But it indexes memories, not code.** Using it for code retrieval would mean building a
code-indexing pipeline on top of a memory store — a second index, an invalidation story, and
staleness, which is precisely what `spec/07 §D` rejected a persistent repo-map for.

**Verdict: the deterministic path dominates.** KD-015 already names it: a `repo_rank` custom
tool under `.omp/tools/*` (a real discovery surface, `builtin.ts:750-796`) that computes
reference-graph centrality on demand, mtime-cached, pull-only. It is recomputed so it cannot
go stale, invoked explicitly so it is not paid unconditionally, and it needs no embeddings,
no model, and no API — which means it also cannot hallucinate.

Semantic (embedding) search is the *weaker* option here: it costs an embedding model, an
index, and a similarity threshold to tune, to answer a question that graph centrality answers
deterministically. Aider's own implementation is PageRank, not embeddings
(`aider@5dc9490:aider/repomap.py:519-529`) — the strongest upstream precedent chose the
deterministic path.

**Gate 2 still blocks it.** OQ-G is the trigger: measure Explorer-with-ranking against
`glob`+`read` on unfamiliar-repo fixtures. Build after that number exists, not before.

### F-3. Memory — the one to be most careful about

Three backends, verified: `memory.backend: "off" | "local" | "hindsight" | "mnemopi"`
(`settings-schema.ts:2617-2620`). Live value: **`off`**.

- `local` — OMP's own store; `memories.*` (17 settings) governs rollout extraction.
- `hindsight` — remote API (`apiUrl`, `apiToken`, `bankId`), with mental models, auto-recall,
  auto-retain (27 settings).
- `mnemopi` — local vector memory with embeddings, banks, scoping, auto-recall/retain,
  proactive linking (23 settings).

Defaults that matter: `mnemopi.autoRecall: true` ("recall local memories into the first turn
of each session") and `mnemopi.injectionTokenLimit: 5000`. So **selecting the backend is not
the whole decision** — a backend with auto-recall on injects up to 5k tokens into the first
turn of every session, which is persistent-adjacent cost at the worst possible multiplier.

**Verdict: defer, and treat it as the highest-risk candidate in this file** — not because of
cost, but because of **gate 5**.

Memory is the one mechanism that can *silently weaken verification*. The template's central
claim is that no completion is accepted without fresh evidence. A memory system that recalls
"we verified this last week" into the current context creates exactly the failure the Iron
Law forbids: evidence from a prior session presented as current. `superpowers`' own table
says it — *"Tests pass → requires test output, 0 failures → **not sufficient: previous
run**"*.

That is not a reason it can never be built. It is the reason its acceptance criteria must be
written **before** it is switched on, and must include: recalled content is data, never
evidence; no completion claim may cite a recalled fact; and recall is disclosed in the result.
`reject-005` / `reject-015` already defer it on quality-and-security grounds — this adds the
sharper reason, which is that memory and the false-completion constraint are in direct
tension.

**Named trigger:** a recorded instance of a task that failed *because* context was lost
across sessions, plus acceptance criteria that keep recalled content out of the evidence
path. Absent both, `off` is the correct value.

---

## G. The short answer

**What is left to optimize:** on the OMP side, a great deal — but the top of the list is
*using capability already paid for* (Handlebars commands, turn budget, telemetry fields,
the `eval` DSL decision), not building new mechanisms. On the OmniRoute side, essentially
one thing: make two model roles differ and measure it. That lever has never been pulled.

**What makes something worth building:** it names an OMP attachment point, solves an
*observed* failure, is not already in the runtime, has a known cost multiplier, cannot weaken
verification, and can be removed. Six gates.

**Why most candidates fail:** gate 2. There is no baseline, so no failure has been observed,
so nothing can be priced. MCP fails gate 2 and 3. Semantic search passes gate 1 and 3 but
fails gate 2 pending OQ-G — and the deterministic alternative is better anyway. Memory fails
gate 2 and is the only candidate that genuinely threatens gate 5.

**Therefore the highest-return investment is the frozen baseline pair itself** — the one
thing that converts every other item on this list from a guess into a decision.
