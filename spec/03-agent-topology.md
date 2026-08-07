# 03 — Agent Topology

> OPUS PROPOSED SPEC v1 | Who exists, who spawns whom, what each may touch.
> All frontmatter claims verified against `discovery/helpers.ts::parseAgentFields`.

---

## A. The Tech Lead Question (DR-1)

`tech-lead.md` exists as an agent file but no command spawns it. Reading
`quick.md`, `standard.md`, and `orchestrated.md`: all three describe Tech Lead
behavior in the second person, addressed to the session that ran the command.
The commands *are* the Tech Lead.

Two coherent resolutions:

**Option A — main session is the Tech Lead (Opus position).**
Commands carry the orchestration logic. `tech-lead.md` is deleted or repurposed
as a nested-orchestration helper only.

- Costs one less subprocess spawn per task, one less recursion level, and one
  less context copy per invocation.
- `task.maxRecursionDepth = 2` means a spawned Tech Lead would have only one
  level left for its own workers. Under Option A the workers sit at depth 1
  and retain a spare level.
- The user's own turn stays the thing that owns the result, which matches
  `RULES.md` invariant 1 (evidence before completion).

**Option B — Tech Lead is spawned.**
A command spawns `agent: tech-lead`, which then spawns workers.

- Buys isolation of the orchestration context from the user's conversation.
- Costs a recursion level and makes the depth budget tight.
- Adds a full agent context (~1.2k tokens) to every task.

**Decision: Option A.** Recursion budget is the deciding evidence, not
preference. `task.maxRecursionDepth = 2` in the frozen baseline does not leave
room for a spawned coordinator that itself fans out.

Consequence: `tech-lead.md` becomes either (a) deleted, with its content folded
into the three commands and `AGENTS.md`, or (b) retained with a frontmatter
`description` that states it is for nested orchestration only. Opus recommends
(a) for v0 — one fewer unused artifact.

---

## B. Worker Roster

Four workers, spawned from the main session via `task`.

| Agent | Tools | Writes? | Isolated? | Spawns |
|---|---|---|---|---|
| `explorer` | read, grep, glob | No | No | none |
| `implementer` | read, grep, glob, edit, write, bash | Yes | **Conditional** — Standard: No; Orchestrated: Yes (see §08 §B) | none |
| `verifier` | read, grep, glob, bash | **Prompt-only: must not** (bash enables side effects; see §C) | No | none |
| `reviewer` | read, grep, glob, bash | **Prompt-only: must not** (bash enables side effects; see §C) | No | none |

`yield` is appended automatically to every explicit `tools:` list by
`parseAgentFields`. It does not need to be declared and declaring it is
harmless.

### Why Explorer is not isolated (DR-6)

Explorer reads only. Isolation exists to keep concurrent *writers* from
colliding and to make their changes revertible. Applying it to a reader buys
nothing and costs a workspace clone plus, on non-CoW filesystems, a recursive
copy. Explorer stays unisolated.

### Why Verifier and Reviewer are not isolated

Both must observe the *post-merge* working tree — the state the Implementer's
changes actually landed in. An isolated Verifier would clone the workspace and
verify a copy, which is the opposite of the guarantee its contract promises.
Both stay unisolated and run after `task.isolation.apply` has merged the
Implementer's patch.

This ordering is load-bearing: Verifier must run *after* the merge, never in
parallel with the Implementer.

---

## C. The bash-vs-write Tension

Verifier and Reviewer both hold `bash`. `bash` can write files. Their prompts
forbid modification, but the tool surface permits it.

This is a real gap and it cannot be closed by the tool allowlist alone — both
agents genuinely need `bash` to run tests and read diffs. Mitigations, in
order of strength:

1. **Prompt-level prohibition** (current): "You MUST NOT modify any file."
   Weakest, but non-zero.
2. **Post-hoc detection**: the Tech Lead compares `git status` before and after
   a Verifier run. Any unexpected modification is a contract violation and the
   result is rejected. This is deterministic and cheap.
3. **Isolation with discarded output**: run the Verifier isolated with
   `task.isolation.apply` disabled for that call. Fully prevents leakage but
   breaks the post-merge-observation requirement above.

Opus recommends (1) + (2). Option (3) defeats the Verifier's purpose.

---

## D. Verified Frontmatter Contract

From `parseAgentFields` (`discovery/helpers.ts:253`), keys are read *after*
kebab→camel normalization in `parseFrontmatter`. Both spellings work.

| Key | Accepted forms | Semantics | Verified |
|---|---|---|---|
| `name` | string | Required. Null return without it. | ✓ |
| `description` | string | Required. Null return without it. | ✓ |
| `tools` | array or CSV string | Allowlist. `yield` auto-appended. Names normalized. | ✓ |
| `spawns` | array, CSV, or `"*"` | Which agents this agent may spawn. | ✓ |
| `model` | string or array | Prioritized list. `@role` resolves via settings. | ✓ |
| `thinking-level` / `thinkingLevel` | string | Also accepts legacy `thinking:`. | ✓ |
| `read-summarize` / `readSummarize` | boolean | Toggles read summarization. | ✓ |
| `output` | any | Structured output schema for `yield`. | ✓ |
| `blocking` | boolean | — | ✓ |
| `prewalk` | boolean or string | Hand off to a cheaper model first. | ✓ |
| `autoload-skills` / `autoloadSkills` | array or CSV | Skills forced into this agent's context. | ✓ |

Every key used by the current five agent files is valid. The earlier concern
that these were unverified is resolved: they all parse.

### The `spawns: ""` subtlety

`spawns: ""` parses through `parseArrayOrCSV("")`, which yields `undefined` for
an empty string. So `spawns: ""` is equivalent to omitting the key.

That matters because of the backward-compat inference at
`helpers.ts:285`: when `spawns` is `undefined` **and** `tools` includes `task`,
`spawns` is set to `"*"`. For the four workers this is harmless — none of them
list `task`, so they end up with no spawn rights either way. The explicit
`spawns: ""` is therefore documentation, not enforcement. Keep it for clarity
but do not rely on it.

Where it *would* matter: any future agent that holds `task` and intends to
restrict spawning must list targets explicitly. `spawns: ""` will not
restrict it — the inference will grant `"*"`.

---

## E. The `autoloadSkills` Opportunity

`autoloadSkills` is a verified frontmatter key that forces named skills into an
agent's context. This is the correct mechanism for the
`evidence-before-completion` problem (F-20).

Rather than `alwaysApply: true` on the skill — which loads it into *every*
context including agents that never complete anything — declare it on the
agents that make completion claims:

- `implementer`: `autoload-skills: evidence-before-completion`
- `verifier`: `autoload-skills: evidence-before-completion`

Explorer and Reviewer do not assert completion and do not need it.

This is strictly better than `alwaysApply` on token grounds and equal on
correctness grounds. It supersedes the earlier DR-4 framing.

Similarly, `systematic-debugging` is a natural `autoload-skills` entry for the
Implementer, whose contract includes root-cause fixes.

---

## F. Model Role Assignment

Each worker declares `model: "@<rolename>"`. Per `getModelRoleAlias`
(`model-resolver.ts:925`), a custom role resolves only when
`settings.getModelRole(candidate)` returns a value — i.e. only when the role is
defined under `modelRoles:` in a loaded config.

The template's `config.yml` defines all five. So the current setup works **if
and only if** that config is installed. If a user installs the agents without
the config, `@explorer` fails to resolve as a role and falls through to being
treated as a model pattern, which will not match. See `09-model-routing.md`
for the failure mode and the mitigation.

---

## G. Spawn Graph

```
Main session (Tech Lead — no agent file)
│
├─ /quick ────────► inline; no spawn unless scope demands one
│
├─ /standard ─────► task(explorer)      depth 1, unisolated
│                   task(implementer)   depth 1, isolated
│                   ── merge applied ──
│                   task(verifier)      depth 1, unisolated
│                   task(reviewer)      depth 1, unisolated, risk-gated
│
└─ /orchestrated ─► task[batch](explorer × N)     depth 1, unisolated, parallel
                    task[batch](implementer × N)  depth 1, isolated, parallel
                    ── merge applied ──
                    task(verifier)                depth 1, unisolated
                    task(reviewer)                depth 1, unisolated
```

All workers sit at depth 1. With `task.maxRecursionDepth = 2`, one level
remains spare. No worker spawns further agents, so the spare level is
currently unused — which is the desired headroom, not waste.

---

## H. Non-Overlap Check

The Definition of Done requires the five roles to have non-overlapping
responsibilities. Under Option A there are four workers plus the session:

| Concern | Owner | Anyone else? |
|---|---|---|
| Task classification, sizing | Main session | No |
| Task packet authoring | Main session | No |
| Locating code | Explorer | No |
| Changing code | Implementer | No |
| Fresh verification | Verifier | Implementer self-verifies, but Verifier is independent and authoritative |
| Diff review | Reviewer | No |
| Final result ownership | Main session | No |

The one deliberate overlap is verification: the Implementer runs its own
verification (its contract requires it) and the Verifier re-runs
independently. That is redundancy by design, not role confusion — the
Implementer's run catches its own errors early, the Verifier's run is the
authoritative evidence.

---

## I. Open Items

| # | Item | Resolution path |
|---|---|---|
| T-1 | Delete `tech-lead.md` or retain as nested-only? | Opus recommends delete for v0 |
| T-2 | Does the Verifier's `bash` need a post-hoc `git status` guard? | Yes — add to command flow |
| T-3 | Should `implementer` get `lsp`? | See `07-retrieval-and-code-understanding.md` |
| T-4 | Move `evidence-before-completion` from `alwaysApply` to `autoloadSkills`? | Opus recommends yes |
