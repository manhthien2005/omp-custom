# 07 — Retrieval and Code Understanding

> OPUS PROPOSED SPEC v1 | Runtime mechanics verified against OMP source in `_research/upstreams/oh-my-pi`; environment-specific availability claims (Context7) explicitly marked.

---

## A. The LSP Contradiction (P1, verified)

The frozen baseline used during spec construction enabled LSP inside subagents:

```
task.enableLsp = true
```

**That was a property of the development environment, not of OMP or of any install (CR-40).** The setting's default is `false`; §A-1 below makes deploying it the template's responsibility.

`config/settings-schema.ts:4615-4624` confirms this setting exists, defaults to `false`, and is described as: *"Allow subagents spawned via the task tool to use the lsp tool. Off by default to keep subagents cheap; enable when LSP-aware delegation is worth the extra tokens."* So the baseline deliberately turns on a non-default capability.

But **no agent file lists `lsp` in its `tools:` allowlist**:

| Agent | `tools:` (verbatim from source) | `lsp` present? |
|---|---|---|
| `explorer` | `read, grep, glob` | No |
| `implementer` | `read, grep, glob, edit, write, bash` | No |
| `verifier` | `read, grep, glob, bash` | No |
| `reviewer` | `read, grep, glob, bash` | No |
| `tech-lead` | `task, read, grep, glob, web_search` | No |

Because `parseAgentFields` (`discovery/helpers.ts:261`) treats `tools:` as an explicit allowlist — appending only `yield` — a tool absent from the list is unavailable to that agent. `task.enableLsp = true` is therefore **inert** for every agent in this template: the session-level permission is granted, then withheld at the per-agent allowlist.

This is a genuine defect, and it is the one place where the template pays a cost (the baseline deviation) for a benefit it never receives.

### Why this matters most for the Explorer

The Explorer's own instructions say *"Symbol first. Use LSP hover, references, and grep before reading full files."* The agent is instructed to use a tool it cannot call. Under the best case the agent notices and silently substitutes `grep`; under the worst case it attempts `lsp`, receives a tool-unavailable error, and burns a turn recovering. Neither outcome is acceptable in an agent whose entire purpose is efficient symbol-first retrieval.

### Resolution

Add `lsp` to the allowlist of the agents whose retrieval quality depends on it:

| Agent | Add `lsp`? | Reasoning |
|---|---|---|
| `explorer` | **Yes** | Symbol-first exploration is its core contract. `lsp references` and `lsp symbols` replace whole-file reads — this is a token *saving*, not a cost. |
| `implementer` | **Yes** | Needs `lsp references` before modifying an exported symbol, and diagnostics-on-write is already enabled in the baseline (`lsp.diagnosticsOnWrite = true`). |
| `reviewer` | **Yes** | Verifying a finding's blast radius requires callers, which is exactly `lsp references`. |
| `verifier` | No | Runs commands and reads output. Symbol navigation is not part of its contract; adding it invites scope creep into review territory. |
| orchestrator (main session) | N/A | Not governed by an agent allowlist. |

The alternative — flipping `task.enableLsp` back to `false` and removing the LSP language from the Explorer prompt — is worse. It gives up genuinely token-efficient retrieval to preserve a setting nobody benefits from.

### A-1. CR-40 — The allowlist is necessary but NOT sufficient

**An earlier revision of this section said "this change requires no baseline modification —
`task.enableLsp = true` is already set."** That sentence is withdrawn. It described the *spec
author's development environment*, which had the setting enabled, and mistook that local fact
for a property of every install. `task.enableLsp` defaults to **`false`**
(`config/settings-schema.ts:4615-4617`) — the same paragraph above says so — so on a default
machine the template ships four agents whose LSP access is granted at the allowlist and then
withheld at the settings gate. That is the CR-31 defect class exactly: **the spec assumes a
required runtime setting the installer never establishes.**

LSP availability in a subagent is a **conjunction of three conditions**, all verified:

```ts
// task/structured-subagent.ts:318-320
enableLsp:
  !planMode &&
  (request.enableLsp ??
    ((request.session.enableLsp ?? true) && request.session.settings.get("task.enableLsp"))),
```

| # | Condition | Default | Who establishes it |
|---|---|---|---|
| 1 | `lsp` in the agent's `tools:` allowlist | absent | **Template** (this section's resolution) |
| 2 | `task.enableLsp == true` | **`false`** | **Template** — project-target install (see below) |
| 3 | parent `session.enableLsp` not disabled, and not plan mode | enabled | **User's session** — template cannot control |

Condition 1 alone was the round-1 finding. Condition 2 is CR-40. Condition 3 is why T-00.E5
remains a genuine runtime gate rather than a formality: a parent session with LSP disabled
disables it for every child regardless of what the project config says.

There is **no per-call escape hatch.** `request.enableLsp` is not exposed on the model-facing
task wire (`docs/tools/task.md` lists `{name?, agent?, task, effort?, outputSchema?,
schemaMode?, isolated?}`), so a command cannot request LSP per dispatch. The settings layer is
the only control point — the same structural situation as `task.isolation.apply` (§08 §E-9).

**Deployment contract (project target owns the key):**

```yaml
owned_required_settings:            # spec/12 §C-1 — project target
  task.enableLsp: true
conflict_policy:
  on_existing_false: report CONFLICT, do NOT overwrite
  rationale: >
    a user who explicitly disabled subagent LSP made a cost decision; overriding it
    silently is the config-clobbering behavior spec/12 exists to prevent
user_global_target:
  write: NEVER without an explicit -EnableSubagentLsp opt-in flag
  rationale: >
    turning on subagent LSP machine-wide spawns LSP servers for unrelated subagents in
    every repository — the same blast-radius argument as task.isolation.apply
```

**Reduced-capability mode, stated honestly.** If condition 2 or 3 is unmet, LSP is
unavailable and the workflow does not silently pretend otherwise:

- Explorer, Implementer, and Reviewer fall back to `grep` + ranged `read` for symbol
  questions. This is a **real degradation**, not an equivalent path: `grep` answers "what
  text exists", not "who calls this" (§C). Blast-radius review in particular gets weaker.
- The degradation MUST be disclosed in the final report, naming which of the three conditions
  failed — they have different fixes (edit the agent file / merge the project setting /
  relaunch the session with LSP enabled).
- DR-7 is therefore refined: LSP is **required for full-quality retrieval and blast-radius
  review**, and its absence is a disclosed capability limit — not a silent substitution. A
  run without LSP is a valid run with a stated weakness; calling it equivalent would be the
  overclaiming pattern CR-35 corrected elsewhere.

T-00.E5 must separate the three conditions as distinct failure causes, because they are
diagnosed and fixed differently. See `phases/phase-00-foundation.md` T-00.E5.

### CR-17 — Authoritative LSP Allowlist (DR-7 decision record)

The table below is the **required final state** after phase-01/phase-02 work, not the current state. It is the authoritative specification that validation must assert.

| Agent | `lsp` in allowlist (required) | Rationale |
|---|---|---|
| `explorer` | **Yes** | Symbol-first contract; `lsp references`/`lsp symbols` replace whole-file reads — token saving, not cost. |
| `implementer` | **Yes** | `lsp references` required before modifying an exported symbol; `lsp.diagnosticsOnWrite = true` in baseline. |
| `reviewer` | **Yes** | Blast-radius check (callers of a modified symbol) requires `lsp references`. |
| `verifier` | **No** | Runs commands, reads output. Symbol navigation is outside its contract and invites scope creep. |
| `tech-lead` (main session) | N/A | Main session, not governed by agent allowlist. |

DR-7 status: **DECIDED** — add `lsp` to explorer, implementer, reviewer. Phase-01 T-01.3 implements this; **T-00.E5** (see `spec/phases/phase-00-foundation.md`) validates that `task.enableLsp = true` propagates and the `lsp` tool is callable within subagents before committing. (T-00.E4 is the RULES.md sentinel experiment and is unrelated to LSP.)

---

## B. Progressive Retrieval Order

The existing `context-budget.yml` retrieval order is correct and worth preserving verbatim in behavior:

1. Local code and types (current file, related modules, LSP symbol lookup)
2. Local documentation (README, `docs/`, comments in code)
3. Official versioned documentation bundled with the dependency
4. Context7 (version-specific library docs via MCP)
5. Broader web research (last resort)

Two clarifications the current wording leaves implicit:

- **Levels are a default priority with bounded escalation — not exhaustion gates (CR-20).** See §B-1 below.
- **Level 5 requires disclosure.** Web-sourced facts enter the artifact as untrusted content per `15-security-and-failure-recovery.md`. Any claim resting on level 5 must name its source in the result.

### B-1. CR-20 — Source fitness, not ritual escalation

An earlier revision of this file said *"Levels are gates, not preferences. An agent MUST
NOT reach level 4 without having tried levels 1–3."* That is withdrawn. It contradicted
`05-context-and-token-model.md §D`, which already states the ordering is guidance within a
bounded retrieval budget, and it fails on three counts:

**Authority is not monotonic in locality.** A local README can be stale; bundled dependency
docs can describe a different installed patch version; source code shows what an
implementation *does* while official docs define what the public contract *guarantees*;
security advisories and current-compatibility facts may exist only externally. "Local is
always more authoritative" is false as a general rule.

**Cost is not monotonic either.** One targeted official-doc lookup can be cheaper than
grep + LSP + local-doc reads + excavating a dependency's source. Mandatory exhaustion can
*increase* tokens per accepted outcome — the metric §05 §A optimizes.

**"Exhausted" has no falsifiable definition.** An agent cannot prove it exhausted local
sources. A gate that can be satisfied by asserting "I exhausted local sources" is not a
gate; it is a prompt for a sentence. It is untestable, so L2/L3 validation cannot check it.

The rule is therefore **default priority + bounded escalation + named skip reasons**:

```yaml
default_order: [local_code_types, local_docs, official_versioned_docs, context7, web]

escalation_bound:
  rule: >
    After N targeted retrievals at the current level fail to answer the specific
    question, move to the next fitting source. Do not continue widening at the
    same level.
  N: 3                      # v0 starting value, calibrated in phase-03 (CR-19)
  targeted: >
    a query with a named subject — symbol, file, or exact string. Broad
    re-greps of the same corpus do not count as new attempts.

permitted_skips:            # each MUST be named in the result's retrieval note
  - local source absent for the dependency in question
  - local docs contradict installed version, or version cannot be confirmed
  - question is explicitly about current/external behavior
  - question is about a guaranteed public contract, not observed implementation
  - security advisory or freshness is the actual subject
  - user explicitly asked for the authoritative or latest source
```

Skipping is legitimate **and must be disclosed**: the result names the level skipped and
which permitted reason applied. That is checkable — a skip with no named reason is a
contract violation — whereas "exhaustion" was not.

Source fitness by question type:

| Question | Best first source |
|---|---|
| What does this installed function call? | LSP / local source |
| What behavior does library vX.Y guarantee? | official versioned docs |
| Is there a newly disclosed vulnerability? | current advisory / web |
| What type does this installed package expose? | local types |
| What is the latest upstream behavior? | current upstream source / docs |

The failure this ordering exists to prevent is unchanged: a web search for something the
type definition next to the callsite already answered. That remains the common error, and
the default order still guards against it.

**ENVIRONMENT ASSUMPTION (CR-18):** Context7 availability depends on an MCP server being wired into the session. This is true for the development environment used during spec construction, but is NOT guaranteed for every OMP session. Level 4 is aspirational unless the runtime confirms the Context7 MCP server is connected. Agents MUST NOT assume Context7 is available; they should treat it as optional and fall back to level 3 if unavailable. It remains **off the default path** regardless: reaching for versioned external docs before reading the local `node_modules` types is the exact inversion this ordering exists to prevent.

---

## C. Symbol-First Discipline

The rule, stated as an ordering over tools rather than a preference:

| Question | Correct tool | Wrong tool |
|---|---|---|
| Where is this symbol defined? | `lsp` definition | `read` the whole file |
| Who calls this function? | `lsp references` | `grep` for the name |
| What does this module export? | `lsp symbols` | `read` the whole file |
| Does this literal string appear anywhere? | `grep` | `lsp` |
| What files match this shape? | `glob` | `bash ls` |
| What is this specific function's body? | `read` with a narrow range | `read` the whole file |

`grep` is not a fallback for `lsp` — it answers a different question. `grep` finds text; `lsp` finds meaning. Searching for `getProfile` with grep returns comments, strings, and unrelated same-named methods; `lsp references` returns the actual call sites. When both could work, prefer `lsp`, because its result needs no filtering.

### Whole-file reads

`read.summarize.enabled = true` in the baseline means large reads return summarized snippets rather than raw content — a meaningful token saving that the template gets for free.

A full unsummarized read is justified when: the file is short, the agent must reason about its overall structure, or the task is to rewrite it. Otherwise, read a range.

**`read-summarize: false` is a real field** (`parseAgentFields` reads `readSummarize`), and the Explorer and Verifier both currently set it. For the Verifier this is defensible — verification evidence must be exact output lines, not a paraphrase. For the Explorer it is counterproductive: an agent whose job is ranked, compact evidence should be the *primary beneficiary* of summarization. See `05-context-and-token-model.md` for the disposition.

---

## D. Repository Map

Aider's repository-map concept — a token-budgeted, signature-level view of the codebase — is adopted as a **principle**, not as an artifact.

OMP already provides the underlying capability through `lsp symbols` and `ast_grep`, which produce structural summaries on demand for exactly the scope in question. Materializing a persistent map file would:

- go stale the moment code changes,
- cost tokens on every load whether or not the task needs it,
- duplicate what `lsp symbols` computes accurately and lazily.

The adopted behavior: **the Explorer builds the map for the task at hand and discards it.** Its ranked-evidence output *is* the repository map, scoped to one task and sized to one packet. Nothing persists.

If a future project genuinely needs a durable architecture overview, that belongs in the project's own `AGENTS.md` as prose written by a human — not in a generated cache the agent must keep synchronized.

---

## E. Contract Summary

1. `lsp` MUST be added to `explorer`, `implementer`, and `reviewer` allowlists — otherwise `task.enableLsp` is inert. **And the allowlist alone is not sufficient (CR-40):** subagent LSP requires the conjunction of allowlist membership, `task.enableLsp == true` (default **`false`** — project install owns it), and a parent session that has not disabled LSP. Absence is a disclosed reduced-capability mode, never a silent `grep` substitution. See §A-1.
2. Retrieval levels are a **default priority with bounded escalation**, not exhaustion gates (CR-20, §B-1). Skipping a level is permitted for a named reason from the `permitted_skips` list and MUST be disclosed in the result; an undisclosed skip is a contract violation. "I exhausted local sources" is not a checkable claim and is not required.
3. Symbol lookup answers "who/where/what exports"; `grep` answers "what text exists". They are not interchangeable.
4. Prefer ranged reads; reserve whole-file reads for short files, structural reasoning, or rewrites.
5. No persistent repository-map artifact. The Explorer's ranked evidence is the map.
