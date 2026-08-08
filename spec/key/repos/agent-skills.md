# Repo Report — agent-skills (addyosmani)

> **Path:** `_research/upstreams/agent-skills`
> **SHA:** `d2478bf0c73a6357df39a3ed6aff16acaa218843`
> **License:** MIT. `LICENSE:1-3` — "MIT License / Copyright (c) 2025 Addy Osmani". Root file
> present; no per-skill overrides.
> **Size:** 182 tracked files (`git ls-files | wc -l`)
> **Read this pass:** `evals/README.md` (86L, full) — the most valuable file in the repo;
> `scripts/run-evals.js:40-360` (the whole ranking + trigger + collision engine);
> `scripts/lib/skill-lint.js` (251L, full); `docs/skill-anatomy.md` (183L, full);
> `skills/doubt-driven-development/SKILL.md` (243L, full);
> `skills/using-agent-skills/SKILL.md` (191L, full); frontmatter of all 24 skills with
> line/word counts; section maps (`## `/`### `/table rows) of `incremental-implementation`,
> `test-driven-development`, `debugging-and-error-recovery`, `context-engineering`,
> `source-driven-development`; `evals/cases/{api-and-interface-design,test-driven-development,debugging-and-error-recovery}.json`
> in full; `evals/fixtures/test-driven-development/authority-pressure.md`;
> `hooks/hooks.json`, `hooks/session-start.sh`; `references/definition-of-done.md:1-40`.

## 1. What this repo is

A **24-skill lifecycle library with the strongest validation harness in the corpus**. The
skills themselves are competent-but-uniform process documents (mean 315 lines, all conforming
to one enforced template). The actual contribution is `evals/` + `scripts/`: a **three-tier
eval model** where Tier 1 is structural lint, **Tier 2 is a deterministic, CI-safe, zero-token
routing check over the whole catalog**, and Tier 3 is behavioral grading via headless agent
runs. Tier 2 is this repo's own invention and it is the thing we should take.

## 2. Mechanism inventory

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| O-1 | **Three-tier eval model, with cost stated per tier** | Structural (CI, free) / Trigger & routing (CI, free) / Behavioral (on demand, tokens). The table literally has a `Cost` column | `evals/README.md:16-20` | A |
| O-2 | **Tier 2: deterministic lexical routing over the catalog** | Stemmed TF-IDF + cosine over `name` (weighted 2×) + `description`, one document per skill, run in CI at zero token cost | `run-evals.js:104-149`; name doubling at `:109` | A |
| O-3 | **Negative fixtures declare an OWNING skill** | `{"prompt": …, "owner": "debugging-and-error-recovery"}`. Verified at `evals/cases/api-and-interface-design.json:18-27` — exactly as our spec records | `evals/cases/api-and-interface-design.json:18-27`; enforcement at `run-evals.js:328-343` | A |
| O-4 | **Owner turns a negative into a pairwise routing test** | Without an owner a negative can pass *vacuously* when the prompt matches nothing. With one, the runner asserts `ownerIdx <= selfIdx` **and** `owner.score > 0` | `run-evals.js:315-343`, with the rationale in the comment at `:316-318`; restated at `evals/README.md:75` | A |
| O-5 | **Two distinct positive failure modes, reported differently** | `score === 0` → "description shares no vocabulary with a prompt users would say"; ranked but too low → prints the actual top-3 with scores | `run-evals.js:302-311` | A |
| O-6 | **Description-collision check across the catalog** | Pairwise cosine between every two descriptions: **error at ≥0.75, warn at ≥0.50** | `run-evals.js:57-58`, `:357-370` | A |
| O-7 | **rank-1 ratchet** | `--min-rank1 <pct>` fails CI when the share of positives ranking their own skill **first** (not merely top-k) drops. CI runs at 80 against a checked-in 86% baseline; "Raise the floor as routing improves; never lower it to make a regression pass" | `run-evals.js:299`, `:374-381`; policy at `evals/README.md:85` |A |
| O-8 | **Tier-2 failure means fix the description, not the eval** | "A Tier-2 failure usually means *fix the description*, not the eval." And: "If a realistic prompt can't rank because the description lacks its vocabulary, that is a real finding — improve the description" | `evals/README.md:22`, `:77` | A |
| O-9 | **Anti-gaming rule for trigger prompts** | "paraphrase how users actually talk; don't copy the description (that's gaming the eval)" | `evals/README.md:77` | A |
| O-10 | **Enforced per-skill fixture minimums** | 3 positive, 2 negative, 1 behavioral — below minimum is a **CI error**, not a warning | `run-evals.js:52-54`, `:347-354`; policy at `evals/README.md:81` | A |
| O-11 | **Pressure cases as a named eval class** | "Discipline skills also include pressure cases for time pressure, sunk cost, and authority pressure; these verify that the workflow still holds when the prompt argues for skipping it" | `evals/README.md:38`; instances at `evals/cases/test-driven-development.json:37-49` (authority) and `evals/cases/debugging-and-error-recovery.json:31-43` (time) | A |
| O-12 | **Pressure fixture = scenario file + eval entry + expectations** | Format verified below | `evals/fixtures/test-driven-development/authority-pressure.md`; paired entry `evals/cases/test-driven-development.json:37-49` | A |
| O-13 | **Tier 3 runs in a throwaway git repo with a committed baseline** | Fixtures materialized from `evals/fixtures/`, committed as baseline, so the grader can judge a real diff | `evals/README.md:36` | B |
| O-14 | **Grader judges the execution *trace*, not the final answer** | `--output-format stream-json --verbose`, "including tool calls" | `evals/README.md:36`; invocation at `run-evals.js:488`, `:507` | A |
| O-15 | **Traces fenced as untrusted data, piped over stdin** | "Traces are fenced as untrusted data in the grader prompt and piped to the grader over stdin (they can be megabytes; argv would hit the OS argument-size limit)" | `evals/README.md:38` | A |
| O-16 | **Explicit executor permission mode, justified** | `--permission-mode acceptEdits` + a pinned tool list "so execution evals can genuinely edit files… rather than being denied and narrating instead" | `run-evals.js:45-49`; `EXECUTOR_TOOLS` at `:49` | A |
| O-17 | **`dialogue` kind is a human-reviewed exemption** | "Claiming `dialogue` is a human-reviewed exemption, not a general escape hatch for execution skills." Execution evals **require** non-empty `files[]` | `evals/README.md:36`, `:74` | A |
| O-18 | **Validator-owned exemptions** | Section-check exemptions live in `skill-lint.js`, not in frontmatter, "so contributors cannot bypass the validator by editing their own skill file" — and declaring `type: meta` in frontmatter without being on the allowlist is itself an **error** | `skill-lint.js:53-60`, guard at `:179-187` | A |
| O-19 | **Five required sections, enforced** | `## Overview`, `## When to Use`, `## Common Rationalizations`, `## Red Flags`, `## Verification` | `skill-lint.js:45-51` | A |
| O-20 | **Fenced code stripped before section matching** | So a heading inside an example or template cannot satisfy the check; headings must match at line start, so `### Verification` does not satisfy `## Verification` | `skill-lint.js:84-86`, `:192-206` | A |
| O-21 | **Description must contain a trigger, with negation rejected** | Regex accepts `use when` / `use before\|after\|during`; a separate regex rejects `do not\|don't\|never use … when` so an exclusion clause cannot satisfy the trigger requirement | `skill-lint.js:39-40`, `:164-172` | A |
| O-22 | **Dead cross-reference detection** | Ten patterns for explicit skill references (incl. ASCII diagram arrows `──→ name`) warn when the target is not a known skill | `skill-lint.js:65-76`, `:208-214` | A |
| O-23 | **Private policy collections** | `REQUIRED_SECTIONS`, `SECTION_EXEMPT_SKILLS`, and the regexes are deliberately **not** exported "so a test or future consumer cannot mutate shared state and change lint results" | `skill-lint.js:241-250` | A |
| O-24 | **"Do not summarize the workflow" in the anatomy doc** | "if the description contains process steps, the agent may follow the summary instead of reading the full skill" — the same finding as superpowers S-7, independently stated | `docs/skill-anatomy.md:35` | A |
| O-25 | **Context-efficiency rules incl. scripts-over-inline** | "Prefer scripts over inline code. Executing a script consumes no context; only its output does. Inline code blocks are paid for on every load." Plus ≤500 lines, one-level-deep references | `docs/skill-anatomy.md:121-129` | A |
| O-26 | **Token-conscious as a writing principle** | "If removing it wouldn't change agent behavior, remove it" | `docs/skill-anatomy.md:149` | A |
| O-27 | **Shared `references/` at repo root, with the tradeoff admitted** | Cross-skill checklists live outside any skill dir; the doc states the portability cost ("a per-skill install… leaves the repo-root sibling behind, and those links resolve to nothing") and links the tracking issue | `docs/skill-anatomy.md:111-119` | A |
| O-28 | **`doubt-driven-development`: adversarial fresh-context review** | 5 steps: CLAIM → EXTRACT → DOUBT → RECONCILE → STOP | `skills/doubt-driven-development/SKILL.md:53-60` | A |
| O-29 | **Do NOT pass the CLAIM to the reviewer** | "Pass ARTIFACT + CONTRACT only… Handing the reviewer your conclusion biases it toward agreement" | `doubt-driven-development/SKILL.md:106`; restated as a Red Flag at `:221` |A |
| O-30 | **Strip your own reasoning from the artifact** | "If you hand over conclusions, you'll get back validation of your conclusions" | `doubt-driven-development/SKILL.md:83` | A |
| O-31 | **Adversarial prompt overrides persona response shape** | Personas produce balanced verdicts; doubt needs issues-only. "Paste the adversarial prompt verbatim into the invocation so it overrides the persona's default" | `doubt-driven-development/SKILL.md:110` | A |
| O-32 | **Finding classification with a stated precedence order** | 1 contract misread → 2 valid+actionable → 3 valid trade-off → 4 noise; **first match wins** | `doubt-driven-development/SKILL.md:172-177` | A |
| O-33 | **Reviewer output is data, not verdict** | "You are still the orchestrator… rubber-stamping the reviewer is the same failure mode as ignoring it" | `doubt-driven-development/SKILL.md:170`, `:179` | A |
| O-34 | **Bounded loop with a decomposition escape** | Stop at trivial findings, 3 cycles, or user override. "If 3 cycles is 'obviously insufficient' because the artifact is large: the artifact is too big — return to Step 2 and decompose. **Do not lift the bound**" | `doubt-driven-development/SKILL.md:181-191` | A |
| O-35 | **"Doubt theater" as a *checkable* red flag** | "across 2 or more cycles where the reviewer surfaced substantive findings, zero findings were classified as actionable. You are validating, not doubting" | `doubt-driven-development/SKILL.md:215` | A |
| O-36 | **Loading Constraints section** | The skill declares where it may **not** be loaded: "Do NOT add this skill to a persona's `skills:` frontmatter" because a persona following Step 3 would spawn another persona | `doubt-driven-development/SKILL.md:42-47` | A |
| O-37 | **Read-only sandbox for cross-model review, with the injection reason** | "A read-only sandbox is the load-bearing detail: a doubt artifact may itself contain instructions (intentional or accidental prompt injection) that the cross-model CLI would otherwise execute" | `doubt-driven-development/SKILL.md:151` | A |
| O-38 | **Never interpolate an artifact into a shell-quoted argument** | Backticks and `$(...)` in code will truncate or execute. Write to a file, pipe stdin | `doubt-driven-development/SKILL.md:135` | A |
| O-39 | **Definition of Done vs Acceptance Criteria, tabulated** | Standing project-wide bar ("is it *ready*?") vs per-task criteria ("did we build *this thing*?"); a task is done only when **both** hold | `references/definition-of-done.md:5-15` | A |
| O-40 | **Runtime-verification item in the DoD** | "Code runs and behaves as intended, **verified at runtime, not just compiled or typechecked**"; "New behavior is covered by tests that fail without the change and pass with it" | `references/definition-of-done.md:23-25` | A |
| O-41 | **`using-agent-skills` as a routing flowchart + 6 operating behaviors** | ASCII decision tree over all 24 skills; then Surface Assumptions / Manage Confusion / Push Back / Enforce Simplicity / Scope Discipline / Verify | `using-agent-skills/SKILL.md:16-42`, `:44-113` | A |
| O-42 | **SessionStart hook injects the meta-skill via jq** | Cats `using-agent-skills/SKILL.md` into `{priority: "IMPORTANT", message: …}`; degrades to an INFO message when `jq` is absent | `hooks/session-start.sh:15-26`, fallback `:9-12` | A |
| O-43 | **Interaction-with-other-skills section** | Per-skill prose disambiguation against 5 named neighbours, e.g. "SDD checks the API exists; doubt-driven checks you used it correctly under the contract" | `doubt-driven-development/SKILL.md:223-229` | A |

### Fixture format, verified precisely

**Trigger block** (`evals/cases/api-and-interface-design.json:3-28`) — verified at the exact
lines our spec cites:

```json
"trigger": {
  "positive": [ { "prompt": "Design a REST endpoint for creating invoices, including error responses and versioning", "top_k": 3 } ],
  "negative": [ { "prompt": "My unit test is failing with a null pointer exception", "owner": "debugging-and-error-recovery" },
                { "prompt": "Make this landing page responsive on mobile",             "owner": "frontend-ui-engineering" } ]
}
```

`top_k` defaults to 3; `evals/README.md:75` says "tighten to 1 for a skill's signature ask".

**Behavioral eval** (`evals/cases/api-and-interface-design.json:29-44`): `id`, optional `kind`
(`execution` default | `dialogue`), `prompt`, `expected_output`, `files[]` (paths under
`evals/fixtures/`), `expectations[]`. Expectations are *behaviors*: "Error responses are
specified with status codes and a consistent error shape, not just happy paths"; "The response
does not silently invent unstated requirements".

**Pressure fixture** — two coupled files:

1. Scenario prose, `evals/fixtures/test-driven-development/authority-pressure.md` (7 lines,
   read in full). Names the pressure in the H1, states who is applying it and what they want,
   and — critically — **pins the exact numeric case**: "three units at 3.335 each; the invoice
   total displayed to customers must use currency-safe rounding to 10.01."
2. The eval entry, `evals/cases/test-driven-development.json:37-49`, whose `prompt` restates
   the pressure inline and whose `expectations[]` are the compliance assertions:
   `"Authority pressure does not cause the failing-test step to be skipped"`,
   `"A regression test covers the reported three-at-3.335 currency case"`,
   `"The full suite is run after the minimal fix"`.

Contrast with superpowers: superpowers' fixture forces a **lettered A/B/C choice** and grades
the *stated decision*; addyosmani's grades the **execution trace of real work in a real repo**.
Superpowers measures what the agent says it would do; addyosmani measures what it did. Both
are useful and they catch different failures — a fact worth recording, because our
`evidence-before-completion` gate needs the trace form (an agent can *say* "I'll verify" and
then not run the command).

## 3. Transferable to omp-custom

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| O-1 three-tier model with a cost column | spec/13 validation tiers | **zero** | **ADOPT** | Our spec/13 has L1/L2/L3; adding a stated *cost* per tier is what stops L3 from being proposed for every check |
| O-2 + O-5 Tier-2 lexical routing | New `scripts/check-skill-routing.*` reading `template/.omp/skills/*` frontmatter + `evals/triggers/*.yml` | **zero** | **ADOPT — highest-value row in this report** | With ≤10 skills and a 900-token listing, description *collision* is our central design risk and this catches it with **no model in the loop**. ~120 lines of code, runs in CI, costs nothing forever |
| O-3 + O-4 negative fixtures declare an owner | `evals/triggers/<skill>.yml` schema | zero | **ADOPT** | Fixes the vacuous-pass hole. With 10 skills, "which of these two owns this prompt" is the only question that matters |
| O-6 collision thresholds (0.75 error / 0.50 warn) | Same script | zero | **ADOPT** | A direct, mechanical guard on the thing that breaks a small library: two descriptions drifting together |
| O-7 rank-1 ratchet | CI flag | zero | **ADOPT** | A monotone quality floor with an explicit never-lower rule. Free |
| O-8 + O-9 "fix the description, not the eval" / anti-gaming | Fixture authoring policy | zero | **ADOPT** | Both are one-line policies that prevent the two ways an eval suite rots |
| O-10 enforced minimums (3/2/1) | Our fixture schema | zero | **ADOPT (scale down)** | Our library is 3-10 skills, not 24. 3 positive / 2 negative-with-owner / 1 behavioral per skill is achievable and is *more* than spec/11 §D currently requires (1/1/0) |
| O-11 + O-12 pressure cases as a class | `evals/pressure/<skill>.yml` + a scenario file each | zero | **ADOPT** | Our three skills are all discipline skills. Time / sunk-cost / authority is the right starting triad, and the paired scenario-file + expectations format is copy-ready |
| O-14 grade the trace, not the answer | spec/13 L3 grader contract | tokens per run | **ADOPT** | For false completion this is the *only* valid grading target. A worker's summary is exactly the artifact we distrust |
| O-15 fence traces as untrusted; pipe via stdin | L3 harness | zero | **ADOPT** | Correct security posture and a real argv-limit fix |
| O-16 explicit permission mode + tool list | L3 harness | zero | **ADAPT** | The insight transfers: an executor denied its tools "narrates instead" — which would score as a false completion and pollute the measurement. The flags are Claude Code's |
| O-17 `dialogue` exemption is human-reviewed | Fixture governance | zero | **ADOPT** | Prevents "this skill's output is just conversation" from becoming a way to skip execution grading |
| O-18 + O-23 validator-owned exemptions, private policy | Our skill validator | zero | **ADOPT** | "Contributors cannot bypass the validator by editing their own skill file" is the exact failure our `registry/skill-lock.yml` is trying to prevent, done better |
| O-19 required sections | Our skill template + validator | lazy (already in bodies) | **ADOPT (trim to 4)** | Their 5 minus `## When to Use` — our trigger info lives entirely in the description by design. Keep Overview / Rationalizations / Red Flags / Verification |
| O-20 strip fenced code before matching | Our validator | zero | **ADOPT** | Prevents a template example from satisfying a structural check. 3 lines of regex |
| O-21 trigger regex with negation rejected | Our validator | zero | **ADAPT** | We must invert part of it: our descriptions *should* contain `Do NOT activate for:` (all three shipped ones do). Take the "reject a negation that masquerades as a trigger" idea, not the regex |
| O-22 dead cross-reference warning | Our validator | zero | **ADOPT** | Cheap; catches a reference to a skill we removed |
| O-24 don't summarize the workflow | Our descriptions | **persistent** | **ADOPT** | Independent confirmation of superpowers S-7 from a second author. Two independent sources raises this from B to A-by-corroboration |
| O-25 scripts over inline code | Skill bodies | lazy | **DEFER** | True and well-argued, but we ship no skill scripts and OMP script bundling is unverified. Trigger: first skill that would carry >30 lines of inline code |
| O-26 "if removing it wouldn't change behavior, remove it" | Skill authoring | zero | **ADOPT** | The single best one-line editing rule in the corpus for a token-capped library |
| O-29 + O-30 don't pass the CLAIM; strip reasoning | `diff-reviewer` dispatch contract (spec/10) | **saves** tokens | **ADOPT** | Our reviewer currently would receive the implementer's report. This says: pass the diff and the requirements, **not** the implementer's conclusions. Anti-false-completion and cheaper simultaneously |
| O-31 adversarial prompt overrides persona shape | `diff-reviewer` prompt | lazy | **ADOPT** | If our reviewer contract says "balanced verdict", it will produce validation. Issues-only framing must win |
| O-32 finding classification precedence | `diff-reviewer` output contract | lazy | **ADOPT** | `contract misread / actionable / trade-off / noise` with first-match-wins is a compact, unambiguous verdict schema — and "contract misread" first is right: it blames *our* packet before the code |
| O-33 reviewer output is data, not verdict | Coordinator contract | lazy | **ADOPT** | Guards the mirror-image failure: over-deferring to a reviewer that lacks context |
| O-34 bounded loop + decompose instead of lifting the bound | `commands/standard.md` fix loop | zero | **ADOPT** | "Do not lift the bound" is the operative clause. Our fix loop needs a cycle cap with an escalation, not an unbounded retry |
| O-35 doubt theater (checkable) | `diff-reviewer` self-check | lazy | **ADOPT** | A *mechanically checkable* rubber-stamp detector: N cycles with substantive findings and zero actionable classifications. Rare and valuable |
| O-36 Loading Constraints section | Our skill bodies where relevant | lazy | **ADOPT** | A skill declaring "do not autoload me into a worker" is directly useful given spec/11 §B assigns `autoloadSkills` per agent |
| O-37 + O-38 sandbox + no shell interpolation | Any cross-tool invocation we add | zero | **ADOPT (as a rule)** | Correct on both counts; the prompt-injection framing for review artifacts is a real threat we would otherwise miss |
| O-39 + O-40 Definition of Done | `verifier` contract (spec/10) | lazy | **ADAPT** | DoD-vs-acceptance-criteria is a clean separation. "Verified at runtime, not just compiled or typechecked" and "tests that fail without the change and pass with it" are two false-completion checks stated as checkboxes |
| O-41 routing flowchart | — | persistent | **REJECT** | A 27-line ASCII tree over 24 skills. With ≤10 skills the descriptions *are* the router; a tree would duplicate them at extra cost |
| O-42 SessionStart hook | — | — | **REJECT** | Harness. OMP is the runtime |
| O-43 Interaction-with-other-skills prose | Skill bodies, if a boundary is genuinely ambiguous | lazy | **DEFER** | At 3 skills there are no ambiguous boundaries. Trigger: when two skills first collide at ≥0.50 on the O-6 check |
| Any of the 24 skills as content | — | persistent | **REJECT** | See §4 |

## 4. What this repo does that we deliberately will not

**Ship 24 skills.** Measured across all 24 frontmatters: 6,280 description chars, mean 261,
max 485, **≈1,570 tokens for the listing alone**. Under OMP's multiplier at 4-5 sessions per
Standard workflow that is **~6,300-7,800 tokens per workflow spent on a menu**, against our
900-token cap. Adopting this library is not a 74% overshoot, it is a ~700% one. Their own
`evals/README.md:85` reports a rank-1 rate of 86% — i.e. **roughly one positive prompt in
seven does not rank its own skill first**, and `evals/README.md:85` links issue #351 for
"known description-vocabulary gaps". That is what 24 mutually-adjacent process skills costs
even with the best routing harness in the corpus. It is the strongest available argument for
our cap, and it comes from the repo with the most evidence.

**The uniform 5-section template applied to all 24.** `skill-lint.js:45-51` requires
`Common Rationalizations` and `Red Flags` in *every* skill. The result is that
`ci-cd-and-automation`, `documentation-and-adrs`, and `frontend-ui-engineering` all carry
rationalization tables. Rationalization tables are a **discipline-failure** instrument
(superpowers `writing-skills/SKILL.md:459-480` is explicit that they backfire on
shaping failures). Requiring one in a reference-shaped skill produces filler like
"'I'll add the feature flag later' | If the feature isn't complete, it shouldn't be
user-visible" (`incremental-implementation/SKILL.md:220`) — not wrong, but not a
rationalization anyone was going to make. We keep the four sections for our three discipline
skills, where they are the right instrument, and would not impose them on a reference skill.

**`using-agent-skills` injected into every session by hook.** 191 lines / 1,307 words, of
which the 27-line routing tree and the 24-row Quick Reference table (`:167-191`) *restate the
skill list a third time* — once in the listing, once in the tree, once in the table. Section
`## Core Operating Behaviors` (`:44-113`) is the genuinely valuable part and it is not a
routing document at all; it is a constitution ("Sycophancy is a failure mode", `:83`; "If you
build 1000 lines and 100 would suffice, you have failed", `:94`). That content belongs in
`RULES.md`, which spec/11 §A confirms *does* propagate to subagents — costing us once per rule
set rather than once per skill listing per session.

**`doubt-driven-development` as a shipped skill.** Read in full; it contains six mechanisms we
want (O-29 through O-35) and is the best-reasoned body in the repo. But as a *skill* it is a
poor fit for us, for a reason it states about itself: `:44-47` says it must run in the
main-session orchestrator, must not be autoloaded into a persona, and degrades to an explicitly
"not fresh-context review" fallback inside a subagent. Our architecture already *has* a
fresh-context adversarial reviewer as a first-class agent (`diff-reviewer`, spec/10). Shipping
this as a skill would cost listing tokens in every session to describe a capability the
topology already provides. We take its craft into the reviewer's contract and ship no skill.

**Cross-model escalation (`:112-166`).** 55 lines mandating that the agent offer a
Gemini/Codex second opinion in *every* interactive doubt cycle, with PATH checks, version
tests, per-invocation re-authorization, and heredoc guidance. Sound engineering, but it is
multi-runtime orchestration. OMP is the only runtime; a skill that spends a third of its body
shelling out to competitor CLIs is out of scope by constraint.

**Repo-root shared `references/`.** `docs/skill-anatomy.md:111-119` is admirably honest that
this breaks per-skill installs and links the tracking issue. We should not repeat the
experiment: our skills must be self-contained because `autoloadSkills` injects a body, and a
body whose reference link resolves to nothing is worse than one with the content inline.

## 5. Contradictions with our current spec or registry

**1. Our recorded citation for the owner mechanism is exactly right.**
`spec/key/04-decision-log.md:582` states negative fixtures name an OWNING skill, citing
`evals/cases/api-and-interface-design.json:18-27`. Verified character-for-character: `:18` opens
`"negative": [`, `:19-22` is the first entry with `"owner": "debugging-and-error-recovery"`,
`:23-26` the second with `"owner": "frontend-ui-engineering"`, `:27` closes the array. **No
correction needed.** The *enforcement* half is worth adding to the record: `run-evals.js:328-343`
is what makes the field load-bearing, and the reason is in the source comment at `:316-318`
(a negative without an owner can pass vacuously).

**2. Our recorded argument at `spec/key/04-decision-log.md:442` is understated.** It says "at
24 skills, `addyosmani/agent-skills`…" and rests on a qualitative reason. The quantitative
case is now measured and stronger: **1,570 listing tokens** for their 24 descriptions, ×4-5
sessions = 6,300-7,800 tokens per Standard workflow, versus our 900-token cap — plus their own
published 86% rank-1 rate and an open issue for description-vocabulary gaps
(`evals/README.md:85`). Recommend attaching the number and the rank-1 datum, because a measured
overshoot is a harder constraint for a future maintainer to argue away than a judgment.

**3. spec/11 §D's fixture design is below this repo's enforced floor.** Ours is 1 positive + 1
negative per skill with no owner, no repetition, no pressure tier
(`spec/11-skills-rules-and-quality-gates.md:136-141`). Theirs is a **CI error** below 3
positive / 2 negative / 1 behavioral (`run-evals.js:52-54`, `:347-354`), negatives carry
owners, and discipline skills additionally carry pressure cases (`evals/README.md:38`). Not a
false claim — an under-specification. Combined with the near-miss defect identified in
`skills.md` §5, spec/11 §D should be reopened.

**4. spec/11 §D asserts trigger quality "is testable without running a workflow" — and this
repo proves it, but only partially.** Our text says trigger quality "is a property of that
description, and it is testable without running a workflow", then classifies the whole thing as
"an L3 (Behavioral) check… it needs a model in the loop, so it cannot run in static
validation". Both halves cannot be fully true, and this repo shows the resolution:
**Tier 2 is static and model-free** (stemmed TF-IDF cosine, `run-evals.js:104-149`) and catches
the two dominant failure modes — missing vocabulary and over-broad collision
(`evals/README.md:22`); only *semantic* judgment needs L3. Our spec collapses two tiers into
one and thereby classes a free check as an expensive one. **This is the most actionable
correction in this report.** Their own caveat must travel with it: Tier 2 "is a **lexical
approximation** of routing… It cannot judge semantics — that's Tier 3's job"
(`evals/README.md:22`).

**5. `spec/key/02-repo-synthesis.md`'s cluster read did not open the harness.** The dossier's
coverage note records "~6 addyosmani skills in full plus frontmatter of all 24" — i.e. the
skills, not `scripts/run-evals.js`, `scripts/lib/skill-lint.js`, or `evals/README.md`. The 30+
zero-cost mechanisms in §3 above come almost entirely from those three files. No recorded claim
is false; the coverage was skewed toward the least transferable part of the repo.

## 6. Cost profile

| Adopted item | Tier | Cost | Basis |
|---|---|---|---|
| O-2/O-3/O-4/O-5/O-6/O-7 Tier-2 routing script | **zero, permanently** | Never enters any context window. Implementation ~120-150 lines (theirs is `run-evals.js:40-381` including CLI and Tier 3 wiring; the ranking core is `:60-149`, ~90 lines). Runs in CI in milliseconds | Measured from source: `run-evals.js` is 576 lines total, of which the model-free routing engine is ~90 |
| O-10/O-11/O-12 fixture minimums + pressure tier | **zero** at rest | 3+2+1 fixtures × ≤10 skills ≈ 60 fixture entries + ~10 scenario files. Repo weight only | Their `MIN_POSITIVE`/`MIN_NEGATIVE`/`MIN_EVALS` at `:52-54` |
| O-14/O-15/O-16/O-17 L3 grading | **per-run tokens** | Their timeouts bound it: executor 15 min, grader 5 min per eval (`run-evals.js:42-43`). Trace size is why stdin is required — "they can be megabytes" (`evals/README.md:38`). At 1 behavioral eval × 10 skills, one full L3 pass is ~10 executor sessions + 10 grader sessions | `run-evals.js:42-43`; `evals/README.md:38`. Token figure **not measured** |
| O-18..O-23 validator rules | **zero** | `skill-lint.js` is 251 lines including comments; the rule set is ~80 lines. Runs in CI | Measured |
| O-19 required sections (4, trimmed) | lazy | No new cost — reorganizes bodies we already pay for. Our shipped bodies are 429/557/492 words | Measured from `template/.omp/skills/*/SKILL.md` |
| O-24/O-26 description + editing rules | **persistent** | Cost-reducing, not cost-adding. These are the rules that keep 10 descriptions under 900 tokens | — |
| O-29..O-35 reviewer craft | lazy, in `diff-reviewer` contract | ~250-350 tokens of contract text per reviewer spawn. O-29/O-30 **reduce** the packet (drop the implementer's conclusions) and likely net negative | Estimate: 7 mechanisms condensed to ~12 lines |
| O-34 bounded fix loop | zero | One rule in `commands/standard.md` | — |
| O-36 Loading Constraints | lazy | ~30 tokens where used | Estimate |
| O-39/O-40 DoD items | lazy, in `verifier` contract | ~80 tokens for the runtime-verification and red-to-green checkboxes | Estimate from `references/definition-of-done.md:23-25` |

**Zero of this repo's 24 skill bodies or descriptions enter our listing.** Its entire
contribution to us is validation harness (zero cost) plus reviewer/verifier contract craft
(lazy, in text we already pay for).

## 7. Coverage and limits (MANDATORY)

**Files read in full:**
`evals/README.md` (86L) · `scripts/lib/skill-lint.js` (251L) · `docs/skill-anatomy.md` (183L) ·
`skills/doubt-driven-development/SKILL.md` (243L) · `skills/using-agent-skills/SKILL.md` (191L) ·
`evals/cases/api-and-interface-design.json` (45L) ·
`evals/cases/test-driven-development.json` · `evals/cases/debugging-and-error-recovery.json` ·
`evals/fixtures/test-driven-development/authority-pressure.md` (7L) ·
`hooks/hooks.json` · `hooks/session-start.sh` · `LICENSE:1-3`.

**Files sampled (head/grep/partial only):**
`scripts/run-evals.js` — read `:40-149` (text pipeline + corpus) and `:290-381` (trigger
evaluation + collisions + ratchet) plus greps for `owner|rank1|collision|similar` across the
whole 576L; **`:150-289` and `:382-576` unread**, which includes the loader details and the
entire Tier-3 executor/grader plumbing (I have `evals/README.md`'s description of it, plus the
invocation strings at `:488` and `:507`) · `references/definition-of-done.md:1-40` of 67 ·
frontmatter + line/word counts of all 24 skills · section maps (`grep '^## \|^### \|^| '`) for
`incremental-implementation`, `test-driven-development`, `debugging-and-error-recovery`,
`context-engineering`, `source-driven-development` — I saw their headings and rationalization
rows, **not their prose** · `git ls-files` inventory.

**Not opened:**
19 of 24 skill bodies in full — `api-and-interface-design` (294L),
`browser-testing-with-devtools` (317L), `ci-cd-and-automation` (390L),
`code-review-and-quality` (396L), `code-simplification` (331L), `deprecation-and-migration`
(247L), `documentation-and-adrs` (288L), `frontend-ui-engineering` (328L),
`git-workflow-and-versioning` (355L), `idea-refine` (178L) + its 3 supporting files + script,
`interview-me` (225L), `observability-and-instrumentation` (203L), `performance-optimization`
(396L), `planning-and-task-breakdown` (234L), `security-and-hardening` (467L),
`shipping-and-launch` (310L), `spec-driven-development` (206L) ·
`references/{accessibility-checklist,observability-checklist,orchestration-patterns,performance-checklist,security-checklist,testing-patterns}.md`
(1,214L combined) — note `orchestration-patterns.md` (370L) is cited by
`doubt-driven-development:46` for the "personas do not invoke other personas" anti-pattern,
which I therefore have **only second-hand** · all 4 `agents/*.md` personas (488L combined) ·
21 of 24 `evals/cases/*.json` · ~35 of 40 `evals/fixtures/**` ·
`scripts/{validate-skills,validate-commands,validate-versions,validate-artifact-paths}.js` and
their 4 `-test.js` siblings · `scripts/run-evals-test.js` ·
`hooks/{sdd-cache-pre,sdd-cache-post,simplify-ignore,session-start-test,simplify-ignore-test}.sh`
and `hooks/{SDD-CACHE,SIMPLIFY-IGNORE}.md` · all 8 `.claude/commands/*.md` and 16
`commands/*.toml` + `.gemini/commands/*.toml` · all 13 `docs/*-setup.md` and
`docs/{adoption-guide,agents,comparison,developer-onboarding,getting-started}.md` ·
`CONTRIBUTING.md`, `CLAUDE.md`, `AGENTS.md`, `README.md`, `.claude/rules/skills-contributing.md`
· `.github/workflows/test-plugin-install.yml` · all plugin manifests.

**Claims that need a live run before use:**
- O-13 (throwaway git repo, fixtures committed as baseline) is read from `evals/README.md:36`
  only; the implementing code is in the `run-evals.js` region I did not read. **Grade B.**
- The 86% rank-1 baseline and the 80 CI floor (`evals/README.md:85`) are their reported
  numbers. I did not execute `node scripts/run-evals.js`, so I cannot confirm the current rate
  at this SHA. Cited as their claim, grade B.
- O-15's "fenced as untrusted data" is described in the README; I did not read the grader
  prompt construction that implements it. **Grade B on implementation**, A on stated intent.
- Whether their Tier 2 stemmer behaves sensibly on *our* vocabulary is unknown. `stem()`
  (`run-evals.js:69-87`) is explicitly "Not a real stemmer" (`:71`) and applies aggressive
  suffix stripping plus a trailing-`y`→`i` normalization. On a 10-skill catalog with words like
  `evidence`, `completion`, `debugging`, `triage` it should be fine, but this needs one dry run
  against our own descriptions before we set a ratchet floor. **D until run.**

**Suspected but not verified:**
- `stem()` at `:79` strips a trailing `e` from any token longer than 4 chars, so `evidence` →
  `evidenc` and `verifie`/`verify` may or may not converge. I traced this by reading, not by
  executing. If we adopt O-2 we should unit-test the stemmer against our actual description
  vocabulary rather than assume.
- The collision check at `:357-370` iterates `names` from `corpus.docs`, whose documents include
  **name tokens weighted 2×** (`:109`). So two skills with similar *names* will register as a
  description collision even if their descriptions differ. Probably intentional; I did not
  confirm against a case. Relevant to us: `evidence-before-completion` and
  `failing-test-first` share no name tokens, but a future `verification-*` skill would.
- I did not verify that `evals/results/` is gitignored as `evals/README.md:38` claims — I did
  not open `.gitignore`.
