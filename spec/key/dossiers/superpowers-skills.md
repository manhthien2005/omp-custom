# Dossier — Skills Cluster (superpowers, anthropics/skills, addyosmani/agent-skills, Agent-Skills-for-Context-Engineering, karpathy-skills)

> commits (read from each `.git`, `_research/upstreams/`):
> - `superpowers` — `44c9b2d6e889982ac18c27d05a19fefe335194e1` (2026-07-28) — LICENSE present (MIT, Jesse Vincent)
> - `skills` (anthropics) — `b29e7cf65e5cb78a5ac33d582270551bc74a14eb` (2026-07-24) — no root LICENSE; 16 per-skill `LICENSE.txt`
> - `agent-skills` (addyosmani) — `d2478bf0c73a6357df39a3ed6aff16acaa218843` (2026-08-06) — LICENSE present (MIT, Addy Osmani)
> - `Agent-Skills-for-Context-Engineering` (muratcankoylan) — `a1841d1ea3dadc70098d94b60fa7a4ab8875dc50` (2026-08-02) — LICENSE present (MIT)
> - `andrej-karpathy-skills` (multica-ai) — `2c606141936f1eeef17fa3043a72095b4765b9c2` (2026-04-20) — no LICENSE file, **but MIT declared in-file**
>
> Paths below are relative to `_research/upstreams/`. Note the upstreams live in the **main repo**, not this worktree.
>
> **Coverage honesty.** I read all 14 superpowers SKILL.md files (bodies or heads), the superpowers
> `writing-skills` body in full, ~9 anthropics skills, ~6 addyosmani skills in full plus frontmatter of all
> 24, ~5 murat skills plus frontmatter of all 17, and karpathy in full. Items marked **NOT READ THIS PASS**
> were measured mechanically (line/word/char counts, grep) but not read for craft.

---

## 1. Per-repo thesis

**superpowers (obra).** The only repo in the cluster that treats a skill as a *behavioral intervention to be
tested*, not a document. Its thesis is stated as an iron law — `skills/writing-skills/SKILL.md:377` "NO SKILL
WITHOUT A FAILING TEST FIRST" — and it ships the fixtures to back it (`skills/systematic-debugging/test-pressure-1.md`,
`-2`, `-3`, `CREATION-LOG.md`). Descriptions are the tightest in the cluster (median 106 chars, min 79 at
`skills/test-driven-development/SKILL.md:3`). The craft is anti-rationalization: iron law → gate function →
rationalization table. Its weakness is that a third of the library is orchestration machinery that OMP already owns.

**anthropics/skills.** A packaging-and-tooling repo, not a discipline repo. Its thesis: the SKILL.md body is a
*dispatcher to bundled resources*, and the resources should be **executed, not read** —
`skills/webapp-testing/SKILL.md:14` is the cluster's single clearest statement of level-3 progressive disclosure.
Descriptions are the longest and most trigger-engineered (median 319 chars, max 1,077 at
`skills/claude-api/SKILL.md:3-7`). It also contains the only *empirical* skill-authoring tooling in the cluster
(`skills/skill-creator/scripts/run_eval.py`, `improve_description.py`). Its weakness: several skills are pure
data sheets (`skills/brand-guidelines/SKILL.md:38-73`).

**addyosmani/agent-skills.** The most disciplined *format* in the cluster and the most over-populated *library*.
24 lifecycle skills, each with an identical closing suite — `Common Rationalizations` / `Red Flags` /
`Verification` present in 23 of 24 (only `using-agent-skills` lacks it). It is the only repo with machine-readable
trigger fixtures carrying a **negative-owner** field (`evals/cases/api-and-interface-design.json:18-27`), and the
only one that governs its own sprawl with a *rule* rather than a skill
(`.claude/rules/skills-contributing.md:9-13`). Its weakness is the sprawl itself: it needed a 191-line router
skill to navigate its own catalogue.

**Agent-Skills-for-Context-Engineering (muratcankoylan).** A research corpus wearing skill frontmatter. Its one
genuinely transferable invention is the **routing description**: every one of its 17 skills carries an explicit
"do not activate — that belongs to X" block, mandated by its own template at `template/SKILL.md:12,23-26` and
verified present in 17/17 bodies. This is the best negative-constraint craft in the cluster. Its weakness is that
most bodies are explainers, self-declared: `skills/context-fundamentals/SKILL.md:3` says "Use this for conceptual
explanation, onboarding, and background reading."

**andrej-karpathy-skills (multica-ai).** One skill, 67 lines, four principles
(`skills/karpathy-guidelines/SKILL.md:13,24,37,51`). It is a constitution, not a skill — which is exactly how
`adopt-016` classified it. Correct call. Its licensing status in our ledger, however, is wrong (§8).

---

## 2. The SKILL.md authoring template

Derived from the four sources that agree, with the disagreements resolved inline.

```markdown
---
name: kebab-case-verb-first
description: >
  Use when <trigger conditions and symptoms>.
  <One clause naming the domain the skill owns.>
  Do NOT activate for: <adjacent case> — that belongs to <other skill / agent / rule>.
---

# Skill Name

## The iron law
```
<ONE IMPERATIVE LINE, ALL CAPS, THE THING THAT MUST NOT BE VIOLATED>
```
<One sentence naming the precondition that makes the law checkable.>

## The gate
1. IDENTIFY — ...
2. RUN / DO — ...
3. READ / CHECK — ...
4. VERIFY — YES → ... / NO → ...
5. CLAIM / PROCEED — only after 4.

## <Claim | Situation> → <Requirement> table
| Situation | What satisfies it | What does NOT |

## Red flags — stop
- <observable signal, not a feeling>

## Rationalizations
| Excuse | Reality |

## Verification
- [ ] <checkable line, one per gate step>

## Deeper reference (only if >2,000 tokens of detail exists)
See `references/<topic>.md` — read it when <condition>. Do not link with `@`.
```

Rationale, section by section:

| Section | Why it exists | Evidence |
|---|---|---|
| `description` as trigger-only + explicit non-trigger | The description is persistent; the body is not. It is the only part most sessions pay for and the sole basis for paying for the body (`spec/05-context-and-token-model.md:48-50`). A description that summarizes the workflow gets *followed instead of the body* | `superpowers/skills/writing-skills/SKILL.md:150-158`; `agent-skills/docs/skill-anatomy.md:35`; `Agent-Skills-for-Context-Engineering/template/SKILL.md:12,23-26` |
| Iron law first, in a code fence | Puts the single non-negotiable at the top of the body where attention is highest, and makes it quotable back. Every high-compliance skill in the cluster does this | `superpowers/skills/verification-before-completion/SKILL.md:14-20`; `.../systematic-debugging/SKILL.md:14-18`; `.../test-driven-development/SKILL.md:31-37` |
| Numbered gate | Converts a principle into a sequence with a failure branch. Without step 4's NO-branch, a gate collapses into a slogan | `superpowers/skills/verification-before-completion/SKILL.md:22-36` |
| Requirement table with a "not sufficient" column | The failure mode is not ignorance of the rule, it is accepting weaker evidence. Naming the *near-miss* is what closes it | `superpowers/skills/verification-before-completion/SKILL.md:40-48` |
| Red flags as observable signals | A model cannot check "am I being lazy" but can check "am I about to write 'should'" | `superpowers/skills/verification-before-completion/SKILL.md:50-59`; best variant: `agent-skills/skills/doubt-driven-development/SKILL.md:215` makes it *countable* ("across 2+ cycles, zero findings actionable") |
| Rationalization table | Skills with a compliance cost get argued away. Pre-refuting the argument is measurably what makes them stick | `superpowers/skills/using-superpowers/SKILL.md:35-50`; `agent-skills/skills/doubt-driven-development/SKILL.md:195-205` |
| Verification checklist at the end | Gives the skill a self-audit that maps 1:1 onto the gate, so compliance is inspectable by a reviewer | `agent-skills/skills/incremental-implementation/SKILL.md:237-245`; present in 23/24 addy skills |
| Reference files, never `@`-linked | `@` force-loads at parse time and destroys the whole point of lazy bodies | `superpowers/skills/writing-skills/SKILL.md:286-288` |
| Scripts described by `--help`, not documented | The bundled script is level 3 of disclosure via *execution*, not reading. Documenting its flags in the body pays for them persistently | `skills/skills/webapp-testing/SKILL.md:14`; `superpowers/skills/writing-skills/SKILL.md:224-230` |

**What the template deliberately omits:** an `## Overview` section. Every repo uses one and it is almost always
the most compressible part — `agent-skills/skills/incremental-implementation/SKILL.md:8-10` restates the
description in prose. Fold it into the iron-law preamble.

---

## 3. Description-writing craft (the load-bearing line)

Measured description lengths (chars of the `description` value, frontmatter parsed mechanically):

| Repo | n | min | median | max | mean |
|---|---|---|---|---|---|
| superpowers | 14 | 79 | 106 | 234 | 133 |
| anthropics/skills | 17 | 204 | 319 | 1,077 | 437 |
| addyosmani | 24 | 198 | 244 | 485 | 261 |
| murat | 17 | 216 | 259 | 853 | 386 |
| karpathy | 1 | 219 | 219 | 219 | 219 |
| **omp-custom (current)** | 3 | 260 | 294 | 316 | 290 |

At ~4 chars/token, omp-custom's median description is ~74 tokens — inside the 30–80 band of
`spec/05-context-and-token-model.md:67`. superpowers sits at ~27 tokens. anthropics' `claude-api` at ~269 tokens
is 2.2× the *warn* threshold and also appears to exceed the 1,024-char frontmatter cap that anthropics'
own downstream guidance asserts (`superpowers/skills/writing-skills/SKILL.md:97`).

**The four rules, in priority order.**

1. **Triggers, not workflow.** The strongest single finding in the cluster, and it is empirical rather than
   stylistic. `superpowers/skills/writing-skills/SKILL.md:154-156` reports that a description reading "code
   review between tasks" caused an agent to perform **one** review although the body's flowchart specified
   **two**; changing the description to trigger-conditions-only restored correct behavior. Independently
   reproduced as guidance in `agent-skills/docs/skill-anatomy.md:35`. Two unrelated authors converging on the
   same failure mode is the strongest evidence available here.
2. **Name what you do NOT own.** murat's routing pattern. `skills/context-fundamentals/SKILL.md:3` ends with an
   explicit routing table inside the description: degradation → `context-degradation`, token efficiency →
   `context-optimization`, summarization → `context-compression`. Mandated at `template/SKILL.md:12`: "This
   prevents broad skills from stealing activation from narrower skills." This is the only mechanism in the
   cluster that addresses *inter-skill* trigger collision, and it is the reason a library can grow past ~6
   skills without degrading. omp-custom already uses a weaker form ("Do NOT activate for: ..." at
   `template/.omp/skills/systematic-debugging/SKILL.md:6-7`) — upgrade it to name the *owner*, not just the
   exclusion.
3. **Third person, symptom vocabulary, technology-agnostic unless the skill is technology-specific.**
   `superpowers/skills/writing-skills/SKILL.md:174-197` gives the worked good/bad pairs; :199-206 argues for
   error-string and synonym coverage ("flaky", "hanging", "ENOTEMPTY") because the description is what the model
   pattern-matches against.
4. **Push against undertriggering — but only on the domain, never the process.** `skills/skill-creator/SKILL.md:67`
   states that models *undertrigger* skills and instructs authors to make descriptions "a little bit pushy."
   This **conflicts** with rule 1 as written. Resolution: pushiness belongs on the *trigger surface* ("even if
   they don't say the word X"), never on the *procedure*. `skills/skills/xlsx/SKILL.md:3` is the best executed
   example — it enumerates casual phrasings ("the xlsx in my downloads"), then closes with an explicit
   `Do NOT trigger when...` clause. That single description contains rules 1, 2 and 4 simultaneously and is
   the best description in the corpus on craft grounds.

**Anti-pattern, verified:** `agent-skills/skills/git-workflow-and-versioning/SKILL.md:3` — "Use when making any
code change." A trigger that always fires is not a trigger; it makes the body's cost unavoidable while providing
no selection signal. Same defect in `agent-skills/skills/incremental-implementation/SKILL.md:3` ("any feature or
change that touches more than one file"). Both are rules wearing skill frontmatter (§6).

---

## 4. Recommended skill roster for omp-custom — ranked

Existing three retained: `task-triage`, `systematic-debugging`, `evidence-before-completion`
(`registry/skill-lock.yml:11-27`). Additions below are ranked by expected reduction in **tokens per accepted
outcome**, i.e. by how much rework each prevents.

| # | Skill | Source of idea | Trigger (description core) | Body outline | Token budget | Autoload vs lazy | Priority |
|---|---|---|---|---|---|---|---|
| 1 | `failing-test-first` | `superpowers/skills/test-driven-development/SKILL.md:31-45` (MIT) | Use when fixing a bug or changing existing behavior, before editing implementation code. NOT for new-file scaffolding, config, or pure refactors under existing green tests | Iron law (no behavior fix without a test that fails first); red-green-restore loop; "wrote code first? delete it"; what counts as a *correct* failure vs a wrong one; verification checklist | 350–450 | **autoload on `implementer`** | P1 |
| 2 | `review-packet-discipline` | `agent-skills/skills/doubt-driven-development/SKILL.md:75-106,168-179` (MIT) | Use when constructing a packet for the Verifier or Reviewer, or when asking any agent to judge work. NOT for exploration packets | Pass ARTIFACT + CONTRACT only; **never pass your CLAIM or your reasoning** (biases toward agreement); adversarial framing ("find what is wrong"), not "is this good"; finding-classification precedence: contract-misread → actionable → trade-off → noise; bounded at 3 cycles then escalate | 450–550 | lazy, `tech-lead` (main session) | P1 |
| 3 | `receiving-review-feedback` | `superpowers/skills/receiving-code-review/SKILL.md:8-12,27-39,113-130` (MIT) | Use when review findings have been received, before implementing any suggestion, especially when a finding looks wrong or unclear | Verify before implementing; ask before assuming; forbidden responses (performative agreement, blind implementation); how to push back with evidence; YAGNI check on "professional" suggestions; implementation ordering by severity | 450–600 | lazy, `implementer` + `tech-lead` | P1 |
| 4 | `incremental-slicing` | `agent-skills/skills/incremental-implementation/SKILL.md:21-43` (MIT) | Use when a change spans multiple files or modules and cannot be verified in one step. NOT for single-file edits | Thin vertical slice definition; each increment leaves the tree green; slice-then-expand cycle; what to do when a slice cannot be made verifiable (decompose or escalate); per-increment verification | 400–500 | lazy, `implementer` | P2 |
| 5 | `skill-authoring` | `superpowers/skills/writing-skills/SKILL.md:93-137,150-266` (MIT) + `skills/skill-creator/SKILL.md:86-98` (Apache-2.0, attributable) | Use when creating, editing, or retiring a skill, rule, or agent prompt in `.omp/` | The §2 template; description rules from §3; the mechanism-selection decision table from §6; trigger-fixture requirement; budget check against `spec/05` §C; skill-lock regeneration | 600–750 (+ `references/description-craft.md`) | lazy, main session only | P2 |

Total library: **8 skills.**

Deliberately **not** adopted, with reasons:

- `brainstorming` (`superpowers/skills/brainstorming/SKILL.md:12-33`) — its `<HARD-GATE>` forbids implementation
  before an approved design on *every* task regardless of size. That is a workflow-selection decision, and
  `task-triage` Phase 4 already owns it (`template/.omp/skills/task-triage/SKILL.md:73-81`).
- `code-review-and-quality` (addy, 396 lines) — duplicates `reviewer.md`. Its five-axis structure and its
  checklist (`SKILL.md:302-347`) are worth mining *into* the reviewer prompt, not shipping as a skill.
- `security-and-hardening`, `performance-optimization`, `shipping-and-launch` (addy) — these are the
  quality gates, already resolved as inlined risk→gate data in `spec/11-skills-rules-and-quality-gates.md:155-167`.
- `using-superpowers` / `using-agent-skills` router skills — OMP's persistent skill listing *is* the router. A
  router skill pays twice for the same index.
- `context-engineering`, `context-optimization`, `context-degradation` (murat) — the actionable residue is a
  policy (`template/.omp/policies/context-budget.yml`, `adopt-011`) and prompt-level bounds, not a skill.

---

## 5. Skill-count economics

**Per-skill persistent cost.** The listing carries `name` + `description` + structural framing. Using
omp-custom's own measured median description (294 chars ≈ 74 tokens) plus ~10 tokens for the name, delimiters and
list framing: **~84 tokens per skill**. Capping descriptions at the `spec/05` §C ceiling of 80 tokens gives a
planning figure of **~90 tokens per skill** worst-case.

| N skills | Listing cost / session | As % of the `AGENTS.md` 1,200-token ceiling (`spec/05:63`) |
|---|---|---|
| 3 (today) | ~270 | 23% |
| 8 (recommended) | ~720 | 60% |
| 10 | ~900 | 75% |
| 12 | ~1,080 | 90% |
| 17 (murat) | ~1,530 | 128% |
| 24 (addy) | ~2,160 | 180% |

**The multiplier that decides the cap.** `spec/11-skills-rules-and-quality-gates.md:16` states the listing lands
in "the system prompt of whichever session lists it." If each spawned agent session also lists the library, the
cost is `N × 90 × (number of sessions that list skills)`. A Standard workflow (main + explorer + implementer +
verifier, ±reviewer) is 4–5 sessions, so at N=10 the library could cost **3,600–4,500 tokens per workflow** —
more than the packet, result, and `RULES.md` budgets combined.

> **NOT VERIFIED THIS PASS:** whether OMP injects the full skill listing into *every* subagent session or only
> into sessions whose agent definition enables skill discovery. This is the single highest-leverage unknown in
> this dossier — it swings the cap by a factor of 4–5. It must be resolved against
> `_research/upstreams/oh-my-pi/packages/coding-agent/src/capability/skill.ts` and the subagent system-prompt
> construction path before the cap is fixed as a spec number.

**Recommendation.** Cap at **10 skills**, hard ceiling 12, and enforce the following statically (extending the
check `spec/05-context-and-token-model.md:229` already calls for):

1. Description ≤ 80 tokens, warn at 120 — per skill.
2. Total listing ≤ 900 tokens — the whole library, checked as a sum, not per file.
3. Every skill must have a positive **and** a negative trigger fixture, and negatives must name the intended
   owner (§7, adopted from addy).
4. A new skill requires an explicit statement of which existing skill it does *not* duplicate — addy's
   anti-duplication guardrail (`.claude/rules/skills-contributing.md:9-13`), which is the only governance
   mechanism in the cluster that addresses library sprawl at the source.

The qualitative argument matters more than the arithmetic: at 24 skills addy needed a 191-line router skill
*and* a repo rule to keep triggers from colliding. That is the observable cost of exceeding the cap — trigger
precision degrades before the token budget does.

---

## 6. Should-not-be-a-skill

The decision rule, adapted from `superpowers/skills/writing-skills/SKILL.md:55-59` ("Mechanical constraints — if
it's enforceable with regex/validation, automate it; save documentation for judgment calls"):

| If the content is… | It belongs in… | Not a skill because… |
|---|---|---|
| An invariant that applies to every turn | `RULES.md` | A skill body is lazy; an always-true rule must be sticky |
| A role contract for one agent | that agent's prompt | Paid once per spawn either way, but a skill adds a discovery gamble |
| A fixed sequence the user invokes | `.omp/commands/*.md` | Commands are deterministic entry points; skills are conditional |
| Mechanically checkable | a script + `validate-template.ps1` | Prose enforcement of a regex-checkable rule is unreliable and repeatedly paid |
| Reference data with no decision in it | `docs/` | Nothing in it changes behavior |

Verified instances:

1. **`agent-skills/skills/using-agent-skills/SKILL.md:44-113`** — six "Core Operating Behaviors" declared
   "non-negotiable" and "apply at all times, across all skills." Content that applies at all times cannot live in
   a lazily-loaded body. This is `AGENTS.md`/`RULES.md` material; `adopt-016` already routes the equivalent
   karpathy principles there, which is the correct precedent.
2. **`agent-skills/skills/git-workflow-and-versioning/SKILL.md:3`** — trigger "Use when making any code change."
   Always-on ⇒ rule, not skill.
3. **`skills/skills/brand-guidelines/SKILL.md:15-73`** — a colour/font data sheet whose closing sections
   ("Features", "Technical Details", "Font Management") describe what *some other code* does. Zero agent
   decisions. Documentation dump; belongs in `assets/` + a `references/` file.
4. **`superpowers/skills/finishing-a-development-branch/SKILL.md:29-40`** — the body's load-bearing content is
   shell (`git rev-parse --git-dir`, `--git-common-dir`, `--show-toplevel`) feeding a state table. That is a
   script with a printed menu, not a judgment call. Independent of `reject-003`'s workflow-opinion objection,
   this is the wrong *mechanism*.
5. **`Agent-Skills-for-Context-Engineering/skills/context-fundamentals/SKILL.md:3`** — self-declared as being
   for "conceptual explanation, onboarding, and background reading." An onboarding explainer paid for in the
   persistent listing of every session is the exact inversion of progressive disclosure.
6. **`Agent-Skills-for-Context-Engineering/skills/context-degradation/scripts/degradation_detector.py`** — a
   *deterministic-looking* script that is not deterministic truth: its own header states the attention functions
   "simulate U-shaped attention curves for demonstration purposes" and token counts use "~1 token per
   whitespace-split word." Shipping this as tooling launders a simulation as a measurement. Reject outright.
7. **`skills/skills/claude-api/SKILL.md:3-7`** — a ~269-token description on a 546-line body. This is a
   library reference (model ids, pricing, params). The trigger engineering is genuinely sophisticated, but the
   persistent cost is being paid by every session for a body most will never load.
8. **omp-custom's own `quality-gates.yml`** — already correctly diagnosed at
   `spec/11-skills-rules-and-quality-gates.md:150-172`: good content, broken delivery mechanism, relocate to
   `docs/policies/`. This dossier's evidence supports that resolution.

---

## 7. Mechanism inventory

| Mechanism | Repo | Where (`file:line`) | OMP mapping | Verdict |
|---|---|---|---|---|
| Description = triggers only, never workflow summary | superpowers | `skills/writing-skills/SKILL.md:150-172` | skill `description` frontmatter | **ADOPT** — codify in `skill-authoring` + validator heuristic |
| Empirical basis for the above (one-review-vs-two anecdote) | superpowers | `skills/writing-skills/SKILL.md:154-156` | rationale in spec 11 §D | **ADOPT** as cited rationale |
| Iron law → gate → requirement table → rationalizations | superpowers | `skills/verification-before-completion/SKILL.md:14-72` | already partly in `evidence-before-completion` | **ADOPT** (already partly done) |
| Pressure-test fixtures per discipline skill | superpowers | `skills/systematic-debugging/test-pressure-1.md`…`-3.md`; `skills/writing-skills/testing-skills-with-subagents.md:30-45` | `evals/triggers/<skill>.yml` (spec 11 §D), L3 behavioral | **ADAPT** — we have `evals/triage/`, `evals/implementation/`; no pressure fixtures yet |
| `NO SKILL WITHOUT A FAILING TEST FIRST` | superpowers | `skills/writing-skills/SKILL.md:377` | governance gate in spec 14 | **ADAPT** — as a promotion precondition, not an absolute |
| No `@`-links between skills (force-loads context) | superpowers | `skills/writing-skills/SKILL.md:286-288` | `skill://<name>` + relative `references/` | **ADOPT** |
| Token-efficiency word-count targets by tier | superpowers | `skills/writing-skills/SKILL.md:213-266` | spec 05 §C budgets | **ADAPT** — we use tokens, they use words; keep tokens |
| `<SUBAGENT-STOP>` guard on a main-session-only skill | superpowers | `skills/using-superpowers/SKILL.md:6-8` | needed for `task-triage` (main-session only per spec 11 §C.3) | **ADOPT** — cheap, prevents subagent misfire |
| Router/meta skill listing all skills | superpowers / addy | `skills/using-superpowers/SKILL.md`; `agent-skills/skills/using-agent-skills/SKILL.md:14-42` | duplicates OMP persistent listing | **REJECT** |
| Orchestration loop as a skill (SDD, parallel dispatch) | superpowers | `skills/subagent-driven-development/SKILL.md:8`; `skills/dispatching-parallel-agents/SKILL.md:14` | `task.batch` | **REJECT** (upholds `reject-001`, `reject-002`) |
| "Subagents never inherit your session context; construct exactly what they need" | superpowers | `skills/dispatching-parallel-agents/SKILL.md:10`; `skills/requesting-code-review/SKILL.md:8` | spec 05 §D prohibition | **ADOPT** as independent corroboration of an existing decision |
| Three-level progressive disclosure, stated numerically | anthropics | `skills/skill-creator/SKILL.md:86-98` | listing / body / `references` + scripts | **ADOPT** (Apache-2.0, attributable) |
| Bundled scripts as **black boxes**: `--help`, do not read source | anthropics | `skills/webapp-testing/SKILL.md:14` | `.omp/tools/*`, `scripts/` | **ADOPT** — best level-3 articulation in the cluster |
| Description that enumerates casual phrasings **and** an explicit do-NOT-trigger clause | anthropics | `skills/xlsx/SKILL.md:3` | skill `description` | **ADAPT** — pattern only; that file is proprietary (§9) |
| "Pushy" descriptions to counter undertriggering | anthropics | `skills/skill-creator/SKILL.md:67` | skill `description` | **ADAPT** — pushy on triggers only, never on procedure |
| Description-optimizer + eval harness scripts | anthropics | `skills/skill-creator/scripts/improve_description.py`, `run_eval.py` | `evals/triggers/` tooling | **ADAPT** — concept; ours must be local + deterministic (`reject-017`) |
| Reference-file ToC when >300 lines | anthropics | `skills/skill-creator/SKILL.md:98` | `references/*.md` | **ADOPT** |
| Uniform closing suite: Rationalizations / Red Flags / Verification | addy | `docs/skill-anatomy.md:60-73`; present in 23/24 skills | §2 template | **ADOPT** |
| Trigger fixtures with **negative + owner** field | addy | `evals/cases/api-and-interface-design.json:18-27` | `evals/triggers/<skill>.yml` | **ADOPT** — strictly better than spec 11 §D's current shape |
| Anti-duplication guardrail as a *rule*, not a skill | addy | `.claude/rules/skills-contributing.md:1-15` | `.omp/rules/*.md` | **ADOPT** — the library-sprawl control we lack |
| Countable red flag ("2+ cycles, zero actionable ⇒ theater") | addy | `skills/doubt-driven-development/SKILL.md:215` | any gate skill | **ADOPT** — turns a vibe into a check |
| Adversarial review: pass ARTIFACT+CONTRACT, never the CLAIM | addy | `skills/doubt-driven-development/SKILL.md:75-106` | `reviewer` packet construction | **ADOPT** → roster #2 |
| Finding classification with precedence order | addy | `skills/doubt-driven-development/SKILL.md:168-179` | Tech Lead handling of review results | **ADOPT** → roster #2 |
| Bounded doubt loop (3 cycles, then escalate; don't lift the bound, decompose) | addy | `skills/doubt-driven-development/SKILL.md:181-191` | spec 15 failure recovery | **ADOPT** |
| Explicit loading-constraint block ("do NOT put this in an agent's `skills:`") | addy | `skills/doubt-driven-development/SKILL.md:42-47` | `autoload-skills` frontmatter discipline | **ADOPT** — prevents the nested-spawn anti-pattern in our topology |
| Cross-model escalation via external CLI | addy | `skills/doubt-driven-development/SKILL.md:112-166` | none — external process | **REJECT** for v0 (external CLI dependency; same class as `reject-008`/`reject-009`). Salvage the read-only-sandbox and stdin-not-argv safety reasoning at `:135,:151` |
| Routing description: name adjacent owners in the description | murat | `skills/context-fundamentals/SKILL.md:3`; mandated `template/SKILL.md:12,23-26`; 17/17 bodies | skill `description` | **ADOPT** — the key upgrade to our three existing descriptions |
| "Does this paragraph justify its token cost?" authoring challenge | murat | `template/SKILL.md:32-35` | skill-authoring review step | **ADOPT** |
| Freedom-level calibration (high/medium/low) for instruction specificity | murat | `template/SKILL.md:56-59` | body authoring | **ADAPT** — useful lens, no mechanism |
| Gotchas as numbered, non-overlapping failure modes | murat | `template/SKILL.md:83-88` | body section | **ADAPT** — overlaps our Red Flags; pick one |
| Claim-ID provenance for numeric assertions | murat | `template/SKILL.md:108` | none | **REJECT** — infrastructure cost without a runtime consumer |
| Simulated-attention "detector" script | murat | `skills/context-degradation/scripts/degradation_detector.py` (header) | none | **REJECT** — simulation presented as measurement |
| Four coding principles as a constitution | karpathy | `skills/karpathy-guidelines/SKILL.md:13,24,37,51` | `AGENTS.md` | **ADOPT** — already done (`adopt-016`) |
| Explicit tradeoff disclaimer ("biases toward caution over speed; for trivial tasks use judgment") | karpathy | `skills/karpathy-guidelines/SKILL.md:11` | `AGENTS.md` / skill preambles | **ADOPT** — cheap hedge that prevents over-application |

**Progressive disclosure — is it used well anywhere?** Yes, in exactly one place, and it is not where the
theory is written down. The theory is at `skills/skill-creator/SKILL.md:86-98` (three levels, stated cleanly).
The **best executed example is `skills/skills/pptx/`**: a 238-line body that is almost entirely a dispatch table
(`SKILL.md:23-27`) to `scripts/thumbnail.py`, `add_slide.py`, `clean.py`, `office/validate.py`, `office/soffice.py`
— each described by *what it does and what will bite you*, never by its implementation, with the standing rule
that the scripts are invoked rather than read (`skills/skills/webapp-testing/SKILL.md:14` states the rule
explicitly). Level 3 is reached by **execution**, so its content never enters context at all. That is the
strongest form of the mechanism in the cluster.

Second-best: `superpowers/skills/systematic-debugging/` — body plus `root-cause-tracing.md`,
`condition-based-waiting.md`, `defense-in-depth.md`, `find-polluter.sh`, each loaded only when the specific
sub-technique applies. Weakest: murat, where the `references/` directories exist but the bodies are 200–400 lines
of prose that should have been in them.

---

## 8. Challenges to existing decisions

**`reject-013` (anthropics/skills verbatim copy) — over-broad; correct it.** The stated reason is "No LICENSE
file in the repository." That is true of the *root* but materially misleading: there are **16 per-skill
`LICENSE.txt` files**, and 12 of them are **Apache-2.0** (`skills/skills/{algorithmic-art, brand-guidelines,
canvas-design, claude-api, frontend-design, internal-comms, mcp-builder, skill-creator, slack-gif-creator,
theme-factory, webapp-testing, web-artifacts-builder}/LICENSE.txt`). Only 4 are Anthropic-proprietary
(`docx`, `pdf`, `pptx`, `xlsx`), which `README.md:20` confirms as "source-available, not open source."
Consequence: **`skill-creator` — the single most relevant skill in that repo for our authoring craft — is
Apache-2.0 and may be copied with attribution and a NOTICE entry.** Recommend rewriting `reject-013` to scope the
rejection to the four proprietary document skills, and adding a matching `adopt-007` split. We still do not
*need* to copy body text (§2 is derived, not copied), so nothing in the template changes — but the ledger is
currently wrong about the facts, and a future maintainer would inherit a false constraint.

**`reject-014` (karpathy CLAUDE.md verbatim copy) — the premise is factually wrong.** The stated reason is
"No LICENSE file. Copyright all rights reserved by default." There is no LICENSE *file*, but the repo declares
MIT **twice**: `skills/karpathy-guidelines/SKILL.md:4` (`license: MIT`) and `README.md:169-171` ("## License" /
"MIT"). An in-file licence grant is a grant. The *conclusion* — independently rewrite the four principles — is
still the right call because they are general engineering concepts and our rewrite is already done and better
scoped for `AGENTS.md`. But the **rationale must be corrected**, and `adopt-016`'s `license_check: no-license`
should become `MIT (declared in SKILL.md frontmatter and README, no LICENSE file)`. Also correct `licenses.yml`
if it carries the same claim (**NOT READ THIS PASS**).

**`reject-001` / `reject-002` (SDD, dispatching-parallel-agents) — uphold, unchanged.** Verified: both are
loop-control engines. `skills/subagent-driven-development/SKILL.md:8` describes dispatching a fresh implementer
per task with reviews between, and ships its own workspace scripts (`scripts/sdd-workspace`, `task-brief`,
`review-package`); `skills/dispatching-parallel-agents/SKILL.md:14` is one-agent-per-domain fan-out. Both
duplicate `task.batch`. **However** — the *packet-construction* craft inside them is separable and valuable, and
both files independently state the rule our `spec/05` §D already carries
(`dispatching-parallel-agents/SKILL.md:10` and `requesting-code-review/SKILL.md:8`: subagents "should never
inherit your session's context or history — you construct exactly what they need"). Recommend citing these as
corroboration in spec 05 §D. Rejecting the mechanism should not mean discarding the argument.

**`reject-003` (finishing-a-development-branch) — uphold, with a stronger reason.** The current reason is that
git workflow is the user's business. True, but the more decisive objection is mechanism: the body is a shell
sequence plus a state table (`SKILL.md:29-40`). Even in a project that wanted this workflow, it should be a
script, not a skill. Adding this to the reason makes the rejection robust against the
"could be offered as an optional project-level skill post-v0" revisit condition.

**`adopt-005` (systematic-debugging 4-phase) — sound, but incomplete.** Our version preserves the iron law and
the four phases (`template/.omp/skills/systematic-debugging/SKILL.md:12-18,22-48`) and the paraphrase is clean.
What we did *not* adopt is the part that makes superpowers' version trustworthy: the pressure fixtures
(`test-pressure-1.md`, `-2`, `-3`, `test-academic.md`) and the `CREATION-LOG.md`. `spec/11` §D asks for
positive/negative trigger fixtures, which is a weaker test — it checks *activation*, not *compliance under
pressure*. Recommend extending the fixture format to include a compliance scenario per discipline skill.

**`adopt-006` (evidence-before-completion) — one acceptance criterion is currently violated.**
`spec/11-skills-rules-and-quality-gates.md:91` budgets the body at ≤500 tokens and §G.2 makes it an acceptance
criterion, because it is paid per Implementer *and* per Verifier spawn. Measured body (post-frontmatter,
chars/4): **~582 tokens** (380 words, 2,329 chars) at `template/.omp/skills/evidence-before-completion/SKILL.md`.
The two compressible sections are "Acceptable evidence formats" (`:62-83`, three worked examples where one
suffices — `superpowers/skills/writing-skills/SKILL.md:326` "One excellent example beats many mediocre ones")
and the overlap between "Red flags" (`:52-58`) and "False-evidence prevention" (`:87-93`), which restate each
other. Cutting to two examples and merging those sections lands it under 500. For reference,
`systematic-debugging` measures ~760 tokens and `task-triage` ~690 — both inside the 800–2,000 lazy-body band of
`spec/05:68`, so only `evidence-before-completion` is out of contract.

**`adopt-016` (karpathy principles → AGENTS.md) — correct classification, wrong licence note.** See above. The
routing decision is well supported: the file is 67 lines of always-applicable behavioural guidance with no
trigger condition narrower than "writing, reviewing, or refactoring code"
(`skills/karpathy-guidelines/SKILL.md:3`), which is the exact signature of constitution content (§6). Also worth
adopting: the tradeoff disclaimer at `:11`, which pre-empts over-application on trivial tasks — a hedge our
`AGENTS.md` version should carry (**AGENTS.md NOT READ THIS PASS** — verify whether it already does).

**One challenge to `spec/11` §D itself.** The current fixture design lists `should_trigger` /
`should_not_trigger` prompts. addy's format (`evals/cases/*.json:18-27`) attaches an `owner` to each negative —
naming which skill *should* win instead. With a routing-description discipline (§3 rule 2), that owner field is
what makes the negative case checkable rather than merely absent. Recommend amending the fixture schema.

---

## 9. Licensing constraints per repo

| Repo | Licence status (verified) | May copy? | Constraints |
|---|---|---|---|
| `superpowers` | MIT, root `LICENSE` ("Copyright (c) 2025 Jesse Vincent") | **Yes** | Retain copyright + permission notice. Attribute in `LICENSES.md`. Body text of `writing-skills`, `verification-before-completion`, `test-driven-development`, `receiving-code-review` may be copied or adapted. We nonetheless paraphrase (`adopt-005`, `adopt-006`) for project-native voice — a style choice, not a legal requirement |
| `skills` (anthropics) | **No root LICENSE. Split per skill:** 12 × Apache-2.0, 4 × Anthropic proprietary/source-available. `README.md:20` confirms | **Partly** | Apache-2.0 (`algorithmic-art`, `brand-guidelines`, `canvas-design`, `claude-api`, `frontend-design`, `internal-comms`, `mcp-builder`, `skill-creator`, `slack-gif-creator`, `theme-factory`, `webapp-testing`, `web-artifacts-builder`): copy permitted **with** attribution, licence text, and a NOTICE of changes. **Proprietary — do NOT copy** (`docx`, `pdf`, `pptx`, `xlsx`; e.g. `skills/skills/pdf/LICENSE.txt`: "© 2025 Anthropic, PBC. All rights reserved", use governed by an Anthropic services agreement). Skills with **no** `LICENSE.txt` at all (`doc-coauthoring`, `template`) default to all-rights-reserved — describe and paraphrase only. Note `THIRD_PARTY_NOTICES.md` covers bundled deps, not skill text |
| `agent-skills` (addyosmani) | MIT, root `LICENSE` ("Copyright (c) 2025 Addy Osmani") | **Yes** | Retain notice; attribute. `doubt-driven-development`, `incremental-implementation`, `docs/skill-anatomy.md`, `.claude/rules/skills-contributing.md`, and `evals/cases/*.json` schema are all copyable/adaptable |
| `Agent-Skills-for-Context-Engineering` | MIT, root `LICENSE` ("Copyright (c) 2025 Context Engineering Agent Skills Contributors") | **Yes** | Retain notice; attribute. `template/SKILL.md` and the routing-description pattern are copyable. Do **not** import numeric/benchmark claims — they are unverified here and several are hedged in-source |
| `andrej-karpathy-skills` | **MIT declared in-file** (`skills/karpathy-guidelines/SKILL.md:4`, `README.md:169-171`); **no LICENSE file** | **Yes, with caution** | The grant is explicit but not in a conventional LICENSE file, and the repo is a third-party derivation of a public X post by Karpathy (`SKILL.md:9`) rather than his work. Continue to rewrite independently (safest, and already done), but correct `reject-014`/`adopt-016`/`licenses.yml` to stop asserting "no licence / all rights reserved" |

**Standing rule for this dossier's own output.** §2's template, §3's rules, and §4's body outlines are *derived
descriptions and independently written structure*. No body text from any proprietary or unlicensed source is
reproduced. The only near-verbatim quotations above are short factual excerpts used to evidence a claim
(fair-use-scale citation with `file:line`), which is required by the assignment's evidence standard.

---

## Gaps — NOT READ THIS PASS

Honest list of what this dossier asserts mechanically (counts, greps, frontmatter) but did not read for craft:

- anthropics: `docx`, `pptx`, `xlsx`, `pdf` **bodies** (measured + frontmatter read only; proprietary, so
  deliberately not mined), `doc-coauthoring`, `algorithmic-art`, `canvas-design`, `frontend-design`,
  `mcp-builder`, `slack-gif-creator`, `web-artifacts-builder`; `spec/agent-skills-spec.md`.
- addyosmani: 18 of 24 bodies (frontmatter + section-heading maps read for all 24); `references/*.md`
  (7 files); `agents/*.md`; `commands/*.toml`; `hooks/`.
- murat: 12 of 17 bodies; all `references/`; `researcher/` corpus.
- superpowers: `anthropic-best-practices.md`, `persuasion-principles.md`,
  `examples/CLAUDE_MD_TESTING.md`, `graphviz-conventions.dot`, `hooks/`.
- **OMP source not opened this pass** — the §5 multiplier question (does every subagent session carry the skill
  listing?) is unresolved and is the highest-value follow-up.
- omp-custom: `template/.omp/AGENTS.md`, `RULES.md`, all five agent prompts, `registry/licenses.yml`,
  `scripts/validate-template.ps1`. §8's claims about them rest on `spec/05` and `spec/11` text, not on the files.
