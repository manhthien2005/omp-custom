# 11 — Skills, Rules, and Quality Gates

> OPUS PROPOSED SPEC v1 | Source-verified against `capability/skill.ts`,
> `capability/rule-buckets.ts`, `task/executor.ts:3235`, `discovery/builtin.ts:387-418`.

---

## A. The Three Injection Mechanisms (verified)

OMP has three distinct ways to get instructions in front of a model. They are not
interchangeable, and the difference is the single most important fact in this document.

| Mechanism | Where it lands | Reaches subagents? | Source |
|---|---|---|---|
| `RULES.md` (sticky rule) | Main session, re-attached near current turn | **No** | `discovery/builtin.ts:387-418` forces `alwaysApply: true` |
| Skill listing (name + description) | System prompt of whichever session lists it | Only if that session lists skills | `capability/skill.ts` |
| `autoloadSkills:` frontmatter | Injected into subagent at startup as a custom message | **Yes, deterministically** | `task/executor.ts:3235-3248` |

### The verified finding that drives this spec

`grep` for `alwaysApplyRules` in `task/executor.ts` and `task/structured-subagent.ts`
returns **nothing**. Always-apply rules are assembled in `sdk.ts:1573-1590` and passed
into the main session's system prompt (`system-prompt.ts:74-79`). Subagents get
`systemPrompt: agent.systemPrompt` — the agent file body — and nothing from the
main session's rulebook.

**Consequence:** a critical invariant placed only in `RULES.md` or only in a skill
marked `alwaysApply: true` **does not reach the Implementer, Verifier, or Reviewer.**
The current template relies on exactly this, so its most important invariant
("no false completion") is absent from the agents that most need it.

---

## B. Resolution of DR-4 (evidence-before-completion)

The README lists DR-4 as "alwaysApply vs lazy." Source verification shows **both
options are wrong**, so the decision is resolved on evidence rather than preference.

| Option | Verdict |
|---|---|
| Leave as a lazy skill | Rejected — subagent must *choose* to read it; the failure mode is precisely a model that doesn't think to check |
| `alwaysApply: true` on the skill | Rejected — no subagent wiring exists; would silently do nothing |
| **`autoloadSkills: evidence-before-completion` on the agent** | **Adopted** — verified deterministic injection at subagent startup |

### Assignment

| Agent | autoloadSkills | Rationale |
|---|---|---|
| `implementer` | `evidence-before-completion` | Claims completion; primary false-completion risk |
| `verifier` | `evidence-before-completion` | Its entire contract is evidence discipline |
| `explorer` | *(none)* | Returns findings, never claims completion |
| `reviewer` | *(none)* | Judges evidence rather than producing completion claims |

Autoload is not free — it costs the skill body in every spawn of that agent. Restrict
it to agents whose contract it actually governs. Adding it to all four would spend
tokens on Explorer, which has no completion claim to guard.

### Cost

`evidence-before-completion` must stay small because it is now paid per Implementer and
Verifier spawn, not once per session.

| Item | Budget |
|---|---|
| Skill body | ≤ 500 tokens |
| Cost per Standard workflow | ≤ 1,000 tokens (one Implementer + one Verifier) |

If the skill grows past 500 tokens, move detail into a reference file the agent may
read on demand and keep the autoloaded body to the rule itself.

---

## C. Skill Inventory

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

Triggered when the root cause is unclear. Lazy loading is right here: most tasks do not
need it, and the Implementer can read it via `skill://systematic-debugging` when a fix
fails twice. Keep the existing four-phase structure.

### C.3 `task-triage` (lazy, main session only)

Triage happens in the main session before any spawn, so main-session skill listing is
the correct mechanism. No autoload needed — no subagent performs triage.

---

## D. Trigger Testing

The plan requires positive and negative trigger cases per skill. Because OMP triggers
skills by model judgment over the `description` field, trigger quality is a property of
that description, and it is testable without running a workflow.

| Skill | Positive trigger | Negative trigger |
|---|---|---|
| `evidence-before-completion` | "The fix is done, tests pass" (must gate) | "What does this function do?" (no completion claim) |
| `systematic-debugging` | "Test fails intermittently, cause unclear" | "Rename this variable" (no diagnosis needed) |
| `task-triage` | "Make the API better" (ambiguous) | "Fix the typo on line 12" (unambiguous) |

Store as `evals/triggers/<skill>.yml` with `should_trigger` / `should_not_trigger`
prompt lists. This is a Level 3 check (see spec 13) — it needs a model in the loop, so
it cannot run in static validation.

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

Inline this table into `commands/standard.md` and `commands/orchestrated.md`, where the
main session picks gates while building the task packet. The Tech Lead then passes the
selected gate names in the packet's `quality_gates` field, and the Reviewer receives
them as data rather than resolving a `policy:` reference it cannot follow.

Keep `quality-gates.yml` as the human-readable expansion of what each gate *checks* —
the trigger conditions and check questions are too long to inline and are only needed
when a reviewer is actively applying a gate. Reclassify it under `docs/policies/` so
its non-runtime status is structural rather than a comment.

### Gate application rule

Gates are selected by the main session at packet-build time, never by the Reviewer
unilaterally. A Reviewer that invents gates produces unbounded review scope, which is
the false-positive failure mode the reviewer contract already guards against. If the
Reviewer believes a gate is missing, it reports that as a non-blocking finding.

---

## F. RULES.md Scope

`RULES.md` reaches only the main session. That is acceptable for its actual contents —
they are main-session concerns:

| Invariant | Correct home |
|---|---|
| Never commit/push unless asked | RULES.md — main session owns git |
| Never modify `~/.omp/agent/` without approval | RULES.md — main session runs the installer |
| Never forward parent transcript to a subagent | RULES.md — main session builds packets |
| Never claim complete without verification | **Also** autoloaded into Implementer/Verifier |
| Report failure with evidence, don't retry silently | **Also** autoloaded into Implementer/Verifier |

The last two must be duplicated by design: once in `RULES.md` for the main session, once
in the autoloaded skill for workers. This is the one place where duplication is correct,
because the two mechanisms serve disjoint audiences. Document it as intentional so a
future deduplication pass does not delete the worker copy.

Keep `RULES.md` at its current 8 invariants and ≤ 700 tokens. It is re-attached near
every turn, so growth is paid repeatedly.

---

## G. Acceptance Criteria

1. `implementer.md` and `verifier.md` carry `autoloadSkills: evidence-before-completion`.
2. `evidence-before-completion` body is ≤ 500 tokens.
3. No skill relies on `alwaysApply` to reach a subagent.
4. `default_matrix` risk→gates table is inlined into `standard.md` and `orchestrated.md`.
5. `quality-gates.yml` is relocated under `docs/policies/` with a non-runtime header.
6. Task packets carry resolved gate names, never `policy:` references.
7. Trigger fixtures exist for all three skills.
8. `RULES.md` ≤ 700 tokens; the intentional worker/main-session duplication is documented.
