# 03 — Agent Topology

<!-- topic05-projection:topology -->
## Topic 05 actor/capability boundary (KD-029)

The Tech Lead selects actor and retrieval capability independently: Lead/native,
Lead/CodeGraph, Scout/native then Lead, or Scout/CodeGraph then Lead. CodeGraph is optional and
default-off. Cheap Scout remains read-only advisory evidence and cannot edit, verify, review,
integrate, or accept. Reviewer independently selects native, CodeGraph, or mixed retrieval and
corroborates load-bearing graph/Scout claims against current source; it never inherits them as
proof.

> **Topic 02 boundary:** Topic 02 owns workflow classification. Topology does not redefine
> workflow classification, task/candidate/session identity, or the structural
> Standard/Orchestrated boundary.
>
> **Status:** KD-027 selects the benefit-gated three-agent manifest below. The main-session
> Tech Lead retains final ownership. Sections B–I preserve the pre-Topic-03 topology hypothesis
> and verified runtime notes as superseded evidence only; they are not current execution
> authority.
> Topic 03 owns the worker graph, dispatch conditions, reviewer shape, and model routing.
>
> All frontmatter claims below were checked against
> `discovery/helpers.ts::parseAgentFields`; verified runtime facts remain evidence even when a
> topology proposal is reopened.

---

## 0. Canonical Selected Topology (KD-027)

The main-session Tech Lead is the default writer and final owner. It classifies the workflow,
accepts the task contract, decides whether delegation has a concrete benefit, validates returned
evidence, performs or commissions fresh verification, integrates accepted work, and reports the
final result. It is not a spawned agent and no `tech-lead.md` may remain under
`template/.omp/agents/`.

Default to no subagent spawn. Every spawn requires all of the following before dispatch:

1. a concrete benefit over inline Tech Lead work;
2. one bounded objective and ownership boundary;
3. a named output contract and consumer;
4. a stop condition and fallback;
5. the effective model, effort, tools, and isolation needed by that contract.

The selected spawnable manifest is exactly `cheap-scout`, `worker`, and `reviewer`:

| Agent | Bounded responsibility | Writes? | Dispatch rule |
|---|---|---:|---|
| `cheap-scout` | Retrieval, repository mapping, and evidence gathering | No | Optional; only after the spawn-benefit gate passes |
| `worker` | One bounded implementation work unit | Yes | Optional; only after the spawn-benefit gate passes |
| `reviewer` | Independent review using a task-specific concern profile | No by contract | Risk-gated; mandatory only for the high-risk concerns below |

Explorer is absorbed by Cheap Scout. Implementer is renamed Worker. The permanent Verifier is
removed: verification is a task-contract obligation owned by the Tech Lead, not a permanent
topology slot. Reviewer is one General Reviewer; security, authentication, durable-data,
database-migration, concurrency, public-API, and destructive-change concerns are dynamic packet
profiles rather than permanent specialist agents.

### 0.1 Agent boundaries

- **Cheap Scout** is read-only and advisory. It may search, map, retrieve, and summarize cited
  evidence. It may not edit, run workspace-mutating commands, verify acceptance, review a
  candidate, integrate work, or issue a verdict. Weak evidence returns to the Tech Lead; it does
  not silently become a quality-triggered provider fallback.
- **Worker** receives one explicitly owned write scope and verification commands. It defaults to
  `high`; the Tech Lead selects exact `xhigh` for difficult, high-risk, cross-boundary,
  concurrency-sensitive, migration-sensitive, or uncertain-root-cause work.
- **Reviewer** runs at exact `xhigh`. Review is mandatory for security, authentication, durable
  data, database migration, concurrency, public API, and destructive change concerns. Other
  review is selected by the accepted task contract and actual risk, never solely by workflow
  name. More than one Reviewer requires at least two independent high-risk concerns.

Each selected agent declares a closed structured result contract in frontmatter. The Tech Lead
accepts only a valid structured result, checks the returned model and effort when identity is
acceptance-bearing, and reconciles any partial, blocked, or failed result before continuing.

### 0.2 Writer ownership and concurrency

The Tech Lead writes inline by default. One sequential Worker may write the retained workspace
within its assigned scope while the Tech Lead refrains from competing writes. Parallel writing
Workers are permitted only when their scopes are disjoint, isolation/capture is proven, and the
Tech Lead integrates artifacts sequentially with cross-boundary verification. If any precondition
is absent, use one sequential writer and disclose the fallback; the task is not blocked merely
because parallelism was unavailable.

### 0.3 Review independence and model availability

Reviewer preference is a suitable different model family, then another suitable strong model,
then the same model in a separate session with disclosure. Opus is a preference, not a gate.
Unavailable Opus blocks work only when the accepted task contract explicitly requires it or an
unresolved finding genuinely cannot be adjudicated with an available suitable model. Cheap Scout
cannot substitute for Reviewer or Tech Lead verification.

### 0.4 Supersession boundary

Everything below this section that names Explorer, Implementer, Verifier, a fixed four-worker
graph, or five role slots is frozen topology evidence from before KD-027. Source facts about OMP
frontmatter, discovery, blocking, tool surfaces, and recursion remain useful where they do not
select a roster. Current runtime, installer, routing, and validation must consume the three-agent
manifest in this section.

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

**Current ownership boundary:** Option A remains the Topic 02 premise for the
main-session Tech Lead and final answer ownership. The old fixed worker graph and its
spawn-count rationale are reopened for Topic 03; recursion depth is a constraint, not a
reason to spawn workers that are otherwise unnecessary.

**Pending Topic 03 migration decision:** the prior CR-33 proposal removes
`template/.omp/agents/tech-lead.md` from agent discovery and moves role-reference content
outside the agent directory. Runtime discovery facts below still apply, but the exact
migration target belongs to Topic 03 and Phase 02.

There is no third option. **OMP agent discovery is mechanical and has no documentation-only category:** `loadAgentsFromDir()` filters on `entry.name.endsWith(".md")` and passes every match to `parseAgent()` (verified: `task/discovery.ts:42-45`, OMP v17.2.10). Discovery covers `~/.omp/agent/agents/*.md`, `<project>/.omp/agents/*.md`, and every extension package's `agents/` directory. Any `.md` file placed there **is** a live, discoverable, spawnable `AgentDefinition` regardless of what the spec calls it.

Retaining `tech-lead.md` under `agents/` while describing it as "role-reference documentation only" would therefore create a **second runtime topology** — a spawnable `tech-lead` agent alongside the main-session Tech Lead — reintroducing exactly what DR-1 Option A was chosen to eliminate: topology ambiguity, divergent model/thinking routing, an extra recursion level, and split ownership of the final answer.

Option (b) from earlier drafts — "retain with a `description` saying it is nested-only" — is **withdrawn**. A frontmatter description is not an enforcement mechanism; the agent remains discoverable and spawnable.

---

## B. Pre-Topic-03 Worker Roster Hypothesis

The prior hypothesis uses four workers spawned from the main session via `task`. Topic 03
must re-evaluate whether each role is useful, whether work stays inline, and whether a
specialist is optional or required before any runtime projection treats this roster as
normative.

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
Both stay unisolated and run after the Implementer's work has landed in the parent working tree — directly for Standard (non-isolated single writer), or after the Tech Lead has completed sequential integration of all captured artifacts for Orchestrated (`task.isolation.apply: false`).

This ordering is load-bearing: Verifier must run *after* the merge, never in
parallel with the Implementer.

---

## C. The bash-vs-write Tension — CR-07

Verifier and Reviewer both hold `bash`. `bash` can write files. Their prompts
forbid modification, but the tool surface permits it.

**CR-07 resolution:** the word "read-only" is deliberately absent from the table
in §B. An agent holding `bash` is not read-only in any mechanical sense, and
calling it so would misrepresent the trust boundary. The table therefore states
**Prompt-only: must not** — an accurate description of a behavioral constraint,
not a mechanical one.

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
| `blocking` | boolean | **Parent waits for this agent inline even when `async.enabled` is true.** No default — absent ⇒ `undefined`, and only exact `=== true` blocks. **REQUIRED on all four workers (CR-39).** | ✓ |
| `prewalk` | boolean or string | Hand off to a cheaper model first. | ✓ |
| `autoload-skills` / `autoloadSkills` | array or CSV | Skills forced into this agent's context. | ✓ |

Every key used by the current five agent files is valid. The earlier concern
that these were unverified is resolved: they all parse.

### CR-39 — `blocking: true` is mandatory on every worker, and the empty cell above was the tell

The `blocking` row previously carried no semantics at all — the key was recorded as *parseable*
and never as *load-bearing*. That omission is exactly how the defect survived six rounds: the
workflow sequences in `04-workflow-sizing.md` were written as ordered stages, and nothing in
the topology spec said what makes a stage actually wait.

It does not wait by default. `async.enabled` defaults to **`true`**
(`config/settings-schema.ts:4223-4225`), `blocking` is parsed with no default
(`discovery/helpers.ts:299`), and `task/index.ts:715` routes every non-blocking item into the
`AsyncJobManager` — so the `task` call returns before the worker finishes, with `results: []`
for a fully-background batch. Full analysis and the barrier consequences are in
`08-isolation-and-concurrency.md §C-1`.

Required on all four workers:

```yaml
explorer.md:    blocking: true      # architecture synthesis consumes its evidence
implementer.md: blocking: true      # integration consumes its artifact
verifier.md:    blocking: true      # review gate consumes its decision
reviewer.md:    blocking: true      # final report consumes its findings
```

Each is justified by a **consumer**, which is the test for whether an agent needs the key: if
a later stage reads this agent's result, the parent must wait for it. All four have one.

**This does not serialize the batch.** When every item is blocking, `asyncItems` is empty and
`task/index.ts:722` takes the synchronous fan-out path — concurrent execution under the
`task.maxConcurrency` semaphore, results in input order. Parallelism and barriers are
orthogonal here, and conflating them would be a reason to wrongly reject this fix.

L0 validation asserts `blocking: true` on all four worker files; L1 asserts it survives
discovery (`phases/phase-06-evaluation.md`).

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

Each selected agent declares `model: "@<rolename>"`. Per `getModelRoleAlias`
(`model-resolver.ts:925`), a custom role resolves only when
`settings.getModelRole(candidate)` returns a value — i.e. only when the role is
defined under `modelRoles:` in a loaded config.

The selected manifest defines `cheap-scout`, `worker`, and `reviewer`. Agent-boundary installation
therefore couples those agents to compatible config and refuses incomplete deployment. The Tech
Lead is the main session and has no required discoverable agent alias. See `09-model-routing.md`
for exact routing and failure behavior.

---

## G. Historical Spawn Graph Hypothesis

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

## H. Historical Non-Overlap Check

The Definition of Done requires the roles to have non-overlapping
responsibilities. Under Option A there are four spawnable workers plus the main session (five
role slots, but `tech-lead` is optional and user-owned — CR-34):

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

## H-1. Current Topic 06 managed boundary (KD-030)

The two sections above are historical hypotheses. Current managed dispatch has three selected
responsibility contracts: optional read-only Cheap Scout, benefit-gated Worker, and risk-gated
Reviewer. Stage names do not force a spawn, and fresh verification plus final acceptance remain
with the main-session Tech Lead.

The trusted same-name `task` wrapper accepts one complete Topic 04 work-unit projection per single
or batch item. It is blocking, forbids nested spawns, and emits a provisional receipt/outcome only.
Cheap Scout is Flash `xhigh` with disclosed Pro `xhigh` availability fallback; Worker is `high` or
Tech-Lead-selected `xhigh`; Reviewer is `xhigh`. Reviewer receives ARTIFACT + CONTRACT and never
the Worker's claim. If managed dispatch is unavailable, the Tech Lead works inline without
fabricating an agent packet, independent review, or receipt.

---

## I. Open Items

| # | Item | Resolution path |
|---|---|---|
| T-1 | ~~Delete `tech-lead.md` or retain as nested-only?~~ | **RESOLVED (CR-33)** — move to `docs/roles/tech-lead.md`; remove from `template/.omp/agents/` and from the installer's `agents` component. Not deleted (content is useful), but not discoverable as an agent. See §A. |
| T-2 | Does the Verifier's `bash` need a post-hoc `git status` guard? | Yes — add to command flow |
| T-3 | Should `implementer` get `lsp`? | See `07-retrieval-and-code-understanding.md` |
| T-4 | Move `evidence-before-completion` from `alwaysApply` to `autoloadSkills`? | Opus recommends yes |
