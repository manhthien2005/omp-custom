# 11 — Skills, Rules, and Quality Gates

<!-- topic08-projection:behavior-core -->
> **Topic 08 selected contract:** `behavior-manifest.json` selects exactly the current three-skill
> roster without imposing a permanent cap. `task-triage` and `systematic-debugging` are lazy;
> `evidence-before-completion` autoloads only on Worker. Missing, shadowed, or hash-drifted selected
> skills refuse managed dispatch. Static trigger fixtures are deterministic; semantic trigger
> promotion belongs to Topic 11.

> OPUS PROPOSED SPEC v1 | Source-verified against `capability/skill.ts`,
> `capability/rule-buckets.ts`, `task/executor.ts:3235`, `discovery/builtin.ts:387-418`.
>
> **Topic 02 supersession boundary:** Topic 03 selects responsibilities and dispatch. Skill
> autoload and gate-delivery requirements attach to selected contracts, not permanent agent
> names. The former role table is non-authoritative migration input. The skill set selected by the runtime manifest
> is authoritative for discovery and trigger coverage; the inventory below
> is candidate input, not a fixed count.

---

## A. The Three Injection Mechanisms (verified)

OMP has three distinct ways to get instructions in front of a model. They are not
interchangeable, and the difference is the single most important fact in this document.

| Mechanism | Where it lands | Reaches subagents? | Source |
|---|---|---|---|
| `RULES.md` (sticky rule) | Main session, re-attached near current turn; **content forwarded to all spawned subagents** | **Yes** — via `rules: session.rules` propagation | `discovery/builtin.ts:387-418` (sticky for main); `task/structured-subagent.ts:438` (forwarded to child) |
| Skill listing (name + description) | System prompt of whichever session lists it | Only if that session lists skills | `capability/skill.ts` |
| `autoloadSkills:` frontmatter | Injected into subagent at startup as a custom message | **Yes, deterministically** | `task/executor.ts:3235-3248` |

### CR-01 correction (2026-08-07): parent rules DO propagate to subagents

The original finding was derived by grepping for `alwaysApplyRules` in
`task/executor.ts` and `task/structured-subagent.ts` — that grep returns nothing, but
that is the wrong level of analysis.

The actual propagation chain, confirmed in v17.2.10:

1. `task/structured-subagent.ts:438` — `buildExecutorOptions` passes `rules: session.rules`
   to the child `ExecutorOptions`.
2. `task/executor.ts` — passes those options to `createAgentSession` (imported from `../sdk`).
3. `sdk.ts` — `createAgentSession` runs `bucketRules(options.rules)` for the child session,
   producing `rulebookRules` and `alwaysApplyRules` that reach the child's system prompt.

**The claim "RULES.md does not reach the Implementer, Verifier, or Reviewer" was wrong.**
Parent-discovered rules, including `RULES.md`, do propagate through subagent creation.

### Why autoloadSkills remains the recommended mechanism despite propagation

Rule forwarding is real but not a replacement for `autoloadSkills` for quality-gate
delivery. The reasons this spec retains `autoloadSkills: evidence-before-completion` when a
selected contract consumes that discipline:

1. **Forwarded rules include the entire parent rulebook.** Workers receive all parent
   rules — not just the quality gate. The token cost is the full rule set, not just
   the skill body.
2. **`autoloadSkills` gives explicit, intentional delivery.** The skill body is exactly
   what you intend. Forwarded rules are whatever the parent discovered at spawn time,
   subject to discovery variations across project layouts.
3. **Token accounting is opaque with forwarding.** With `autoloadSkills` the cost is
   exactly one skill body per spawn. Forwarding cost depends on the full parent rule set.
4. **The critical invariant must be present regardless of forwarding.** Even if
   forwarding works, a worker that receives an overwhelming rulebook may deprioritize a
   buried quality gate. Autoload makes it prominent.

DR-4 resolution stands for selected consumers: use `autoloadSkills: evidence-before-completion`. The
**justification** changes from "RULES.md doesn't propagate" to "explicit autoload is
preferable over implicit forwarding for quality-gate delivery."

---

## B. Resolution of DR-4 (evidence-before-completion)

The README lists DR-4 as "alwaysApply vs lazy." Source verification shows **both
options are wrong**, so the decision is resolved on evidence rather than preference.

| Option | Verdict |
|---|---|
| Leave as a lazy skill | Rejected — subagent must *choose* to read it; the failure mode is precisely a model that doesn't think to check |
| `alwaysApply: true` on the skill | Rejected — no subagent wiring exists; would silently do nothing |
| **`autoloadSkills: evidence-before-completion` on a selected consuming agent** | **Adopted when consumed** — verified deterministic injection at subagent startup |

### Assignment by selected responsibility

| Current role | autoloadSkills | Rationale |
|---|---|---|
| `worker` | `evidence-before-completion` | Produces the candidate and may claim its bounded work complete |
| `cheap-scout` | *(none)* | Returns read-only findings and never accepts or completes work |
| `reviewer` | *(none)* | Judges candidate evidence; it does not inherit the Worker's claim |

Autoload is not free — it costs the skill body in every Worker spawn. The selected manifest is
the authority for consumers and validates both sides of the binding. Missing names are not
silently tolerated by the managed adapter: reconciliation fails before dispatch.

### Cost

`evidence-before-completion` must stay small because it is paid per selected autoloading spawn,
not once per task.

| Item | Budget |
|---|---|
| Skill body | ≤ 500 tokens |
| Cost per selected autoloading spawn | ≤ 500 tokens per injected skill body |

If the skill grows past 500 tokens, move detail into a reference file the agent may
read on demand and keep the autoloaded body to the rule itself.

---

## C. Selected Skill Inventory

The manifest currently selects the following three contracts. This is the minimum approved
roster, not a permanent cap; an addition must declare its consumer, injection owner, token budget,
provenance, license, release hash, and positive/negative fixtures.

### C.1 `evidence-before-completion` (autoloaded)

```yaml
---
name: evidence-before-completion
description: >
  Verification gate before any completion claim. Run the proof command in the
  current session, read its output, then state the claim with evidence quoted inline.
  Use before reporting done, passing, fixed, or working.
---
```

Body must state, in under 500 tokens: no completion claim without a command run in the
current session; evidence from a prior turn or another agent's report does not count;
quote the decisive output line inline. Do **not** set `alwaysApply` — it is inert for
subagents and misleads the next maintainer into thinking coverage exists.

### C.2 `systematic-debugging` (lazy, correct as-is)

Triggered when the root cause is unclear. Lazy loading is right here: most tasks do not need
it, and a selected debugging responsibility can read it via `skill://systematic-debugging`
when a fix fails twice. Keep the existing four-phase structure if this skill is selected.

### C.3 `task-triage` (lazy, main session only)

Triage happens in the main session before any spawn, so main-session skill listing is
the correct mechanism. No autoload needed — no subagent performs triage.

---

## D. Trigger Testing

The plan requires positive and negative trigger cases per selected skill. Static validation proves
the selected pair exists, is unique, and matches its manifest binding. OMP ultimately chooses a
lazy skill from its `description`, so semantic trigger quality still needs the Topic 11 model
evaluation before promotion.

| Skill | Positive trigger | Negative trigger |
|---|---|---|
| `evidence-before-completion` | "The fix is done, tests pass" (must gate) | "What does this function do?" (no completion claim) |
| `systematic-debugging` | "Test fails intermittently, cause unclear" | "Rename this variable" (no diagnosis needed) |
| `task-triage` | "Make the API better" (ambiguous) | "Fix the typo on line 12" (unambiguous) |

Store exact pairs as `evals/triggers/topic08/<skill>-positive.yml` and
`evals/triggers/topic08/<skill>-negative.yml` with `should_trigger` / `should_not_trigger` cases.
Fixture shape and coverage are L0 deterministic checks; semantic activation remains L3/Topic 11.

---

## E. Quality Gates

`quality-gates.yml` has no runtime consumer (verified: no `policies/` discovery in OMP).
Its content is good; only the delivery mechanism is broken.

### Resolution

The `default_matrix` is the load-bearing part and is small enough to inline:

| Risk | Gates |
|---|---|
| LOW | none |
| MEDIUM | security |
| HIGH | api-compatibility, security, performance, release-readiness, rollback-readiness |
| CRITICAL | all of HIGH + adr-documentation |

Inline this table into `commands/standard.md` and `commands/orchestrated.md`, where the main
session picks gates while building the task packet. The Tech Lead then passes the selected gate
names in the packet's `quality_gates` field. Any selected gate-applier or review responsibility
receives them as data rather than resolving a `policy:` reference it cannot follow.

Keep the gate definitions as the human-readable expansion in
`docs/policies/quality-gates.md` — the trigger conditions and check questions are too long to
inline and are only needed when a selected gate-applier is actively applying a gate. Its location
outside `.omp/` makes the non-runtime status structural rather than a comment.

### Gate application rule

Gates are selected by the main session at packet-build time, never by a selected gate-applier
unilaterally. A gate-applier that invents gates produces unbounded scope, the false-positive
failure mode the review contract guards against. If it believes a gate is missing, it reports
that as a non-blocking finding.

---

## F. RULES.md Scope

`RULES.md` content is re-attached near every turn in the main session **and** forwarded
to all spawned subagents via `rules: session.rules` (see §A correction above). The
forwarded rules are processed through `bucketRules` in each child session.

This changes the semantics of the table below: the "correct home" column now means
"where the rule is *authoritative* and *guaranteed to apply*", not "only place it
reaches." However, for the quality-gate invariants marked as **Also** autoloaded, the
`autoloadSkills` delivery is still preferred because it is explicit, token-controlled,
and independent of the full parent rule set that forwarding carries.

| Invariant | Correct home |
|---|---|
| Never commit/push unless asked | RULES.md — main session owns git |
| Never modify `~/.omp/agent/` without approval | RULES.md — main session runs the installer |
| Never forward parent transcript to a subagent | RULES.md — main session builds packets |
| Never claim complete without verification | **Also** autoloaded into selected completion-claiming roles |
| Report failure with evidence, don't retry silently | **Also** autoloaded into selected evidence-producing roles |

The last two must be duplicated by design: once in `RULES.md` for the main session, once
in the autoloaded skill for workers. This is the one place where duplication is correct,
because the two mechanisms serve disjoint audiences. Document it as intentional so a
future deduplication pass does not delete the worker copy.

Keep `RULES.md` at its current 8 invariants and ≤ 700 tokens. It is re-attached near
every turn, so growth is paid repeatedly.

---

## G. Acceptance Criteria

1. Every selected spawned role whose contract consumes `evidence-before-completion` carries
   that exact `autoloadSkills` entry; no unselected or non-consuming role is required.
2. `evidence-before-completion` body is ≤ 500 tokens.
3. No skill relies on `alwaysApply` to reach a subagent.
4. `default_matrix` risk→gates table is inlined into `standard.md` and `orchestrated.md`.
5. `docs/policies/quality-gates.md` contains the expanded definitions with a non-runtime header.
6. Task packets carry resolved gate names, never `policy:` references.
7. Trigger fixtures exist for every skill selected by the runtime manifest; no fixed skill
   count is inferred from the candidate inventory.
8. `RULES.md` ≤ 700 tokens; the intentional worker/main-session duplication is documented.
