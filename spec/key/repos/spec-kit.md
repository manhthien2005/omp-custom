# Repo Report — spec-kit

> **Path:** `_research/upstreams/spec-kit`
> **SHA:** `81d5cdbbf2c96f7ce1a2801c6185f2951f1f61be` (`git -C spec-kit rev-parse HEAD`)
> **License:** MIT. `LICENSE:1-3` — "MIT License / Copyright GitHub, Inc." No conflicting
> in-file grant found in the files read; the command templates carry no per-file license
> header (frontmatter is `description:` / `scripts:` / `handoffs:` only).
> **Size:** 533 tracked files (`git ls-files | wc -l`)
> **Read this pass:** A **gap-fill and verification** pass, not a fresh start — the prior
> pass read ~9 command/template files. Explicitly split below.
>
> **Re-verified this pass (previously read, claims re-checked against source):**
> `templates/commands/specify.md`, `templates/commands/analyze.md`,
> `templates/commands/constitution.md`, `templates/spec-template.md`,
> `templates/tasks-template.md`, `templates/plan-template.md`.
>
> **Newly read this pass:** `templates/commands/checklist.md` (370 lines — the "unit tests
> for English" doctrine, the single most valuable file in this repo and previously unread),
> `.specify/memory/constitution.md` (a *real* Sync Impact Report instance, not the
> template), `docs/guides/evolving-specs.md` (the three persistence models),
> `templates/constitution-template.md`, plus targeted greps over
> `templates/commands/{clarify,converge,tasks,implement}.md`.

## 1. What this repo is

GitHub's Spec-Driven Development toolkit: a Python CLI (`specify`) that installs a set of
agent-facing slash-command prompts and markdown templates into a repo, for ~40 agent
integrations. The methodology is `constitution → specify → clarify → plan → tasks →
analyze → implement → converge`. Unlike OpenSpec, **nothing here validates the spec
mechanically** — every quality gate is a prompt instructing an agent to check prose against
prose. That makes it the better source for *criteria craft* and the worse source for
*enforcement*.

## 2. Mechanism inventory

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| 1 | **"Checklists are unit tests for English"** | The framing that a spec is code written in English and a checklist is its test suite — testing whether requirements are *well-written*, not whether code works | `templates/commands/checklist.md:9-28` | A |
| 2 | Requirements-quality vs implementation-test distinction | Long paired wrong/right lists. Wrong: "Verify landing page displays 3 cards". Right: "Are the number and layout of featured episodes explicitly specified?" | `checklist.md:11-28, 161-173, 307-336` | A |
| 3 | Prohibited-opener list | Items starting with "Verify / Test / Confirm / Check" + behavior are banned, as are "click, navigate, render, load, execute" and "displays correctly / works properly" | `checklist.md:232-238` | A |
| 4 | Required item patterns | Six sanctioned shapes: "Are X defined for Y?", "Is [vague term] quantified?", "Are requirements consistent between A and B?", "Can X be objectively measured?", … | `checklist.md:240-246` | A |
| 5 | Six quality dimensions | Completeness, Clarity, Consistency, Measurability, Coverage (+ Edge Cases), each tagged in-line in brackets | `checklist.md:141-146, 183-206` | A |
| 6 | Traceability floor, quantified | "MINIMUM: ≥80% of items MUST include at least one traceability reference" — `[Spec §X.Y]` or a marker | `checklist.md:214-217` | A |
| 7 | Marker vocabulary | `[Gap]`, `[Ambiguity]`, `[Conflict]`, `[Assumption]`, `[Traceability]` — distinguishes "spec says it badly" from "spec is silent" | `checklist.md:216` | A |
| 8 | Vague-adjective blacklist | fast, scalable, secure, intuitive, robust — flagged when unaccompanied by measurable criteria | `analyze.md:126` | A |
| 9 | Placeholder detection | TODO, TKTK, ???, `<placeholder>` | `analyze.md:127` | A |
| 10 | Underspecification test | "Requirements with verbs but missing object or measurable outcome" | `analyze.md:131-134` | A |
| 11 | Success-criteria rules | Measurable / technology-agnostic / user-focused / verifiable, with good and **bad** examples: "API response time under 200ms" is a BAD criterion (too technical) | `specify.md:318-339` | A |
| 12 | Criteria-vs-mechanism boundary, by example | "Database can handle 1000 TPS" and "Redis cache hit rate above 80%" rejected as implementation detail; "Users can complete checkout in under 3 minutes" accepted | `specify.md:327-339` | A |
| 13 | Spec quality checklist (16 items) | Generated at `checklists/requirements.md`; includes "Requirements are testable and unambiguous", "Success criteria are measurable", "All functional requirements have clear acceptance criteria" | `specify.md:146-183` | A |
| 14 | Self-validation loop with a hard cap | Re-run validation until all items pass, **max 3 iterations**, then document remaining issues and warn | `specify.md:193-197` | A |
| 15 | `[NEEDS CLARIFICATION: question]` inline marker | Ambiguity is recorded *in* the spec at the point of ambiguity rather than in a side channel | `spec-template.md:96-99` | A |
| 16 | **Max 3 clarification markers**, with a priority order | "LIMIT: Maximum 3 … total"; priority `scope > security/privacy > user experience > technical details`. If >3 exist, keep the 3 most critical and guess the rest | `specify.md:128-129, 201, 299-303` | A |
| 17 | Explicit "reasonable defaults — don't ask" list | Data retention, performance targets, error handling, auth method, integration patterns | `specify.md:310-316` | A |
| 18 | Three conditions gating a clarification | Significantly impacts scope/UX **and** multiple reasonable interpretations exist **and** no reasonable default exists | `specify.md:124-127` | A |
| 19 | `/clarify` cap of 5 | "maximum 5 … Maximum of 5 total questions across the whole session", queued internally, not emitted at once | `clarify.md:129-130` | A |
| 20 | Checklist clarify cap of 3 (+2 escalation) | Up to 3 questions; may add Q4/Q5 only if ≥2 scenario classes remain unclear, each with a one-line justification. Never exceed five | `checklist.md:81, 111` | A |
| 21 | "Think like a tester" | "Every vague requirement should fail the 'testable and unambiguous' checklist item" | `specify.md:304` | A |
| 22 | FR-###/SC-### stable IDs | Functional Requirements and Success Criteria get explicit keys used as the primary traceability key | `spec-template.md:88-99, 113-118`; `analyze.md:110` | A |
| 23 | SC filter: buildable work only | Success Criteria enter the coverage model only if they require buildable work; post-launch KPIs ("reduce support tickets by 50%") are excluded | `analyze.md:110, 144` | A |
| 24 | Constitution semver — **verified exactly as reported** | MAJOR = backward-incompatible governance/principle removals or redefinitions; MINOR = new principle/section added or materially expanded guidance; PATCH = clarifications, wording, typos, non-semantic refinements | `constitution.md:87-90` | A |
| 25 | Ambiguous-bump rule | "If version bump type ambiguous, propose reasoning before finalizing" | `constitution.md:91` | A |
| 26 | Sync Impact Report — **verified exactly as reported** | Prepended as an **HTML comment** at the top of the constitution file. Records: version change old → new; modified principles (old title → new title if renamed); added sections; removed sections; follow-up TODOs for deferred placeholders | `constitution.md:99-104` | A |
| 27 | A real Sync Impact Report instance | Their own constitution carries one: "Version change: (template/unratified) → 1.0.0", bump rationale, five principles listed, three added sections, four templates reviewed with ✅ and line refs, "Follow-up TODOs: none" | `.specify/memory/constitution.md:1-32` | A |
| 28 | Report includes downstream-template review | The instance records which dependent templates were checked for alignment and why each needed no change — a propagation audit, not just a version delta | `.specify/memory/constitution.md:23-29` | A |
| 29 | Constitution scope guard | Non-governance intents in the input MUST NOT be executed; they are extracted into a `Next Actions` section suggesting a follow-up command **without invoking it** | `constitution.md:17-34` | A |
| 30 | Constitution validation before write | No unexplained bracket tokens; version line matches report; ISO dates; "Principles are declarative, testable, and free of vague language" | `constitution.md:106-110` | A |
| 31 | `TODO(<FIELD_NAME>): explanation` for genuinely-unknown values | Plus mandatory listing in the Sync Impact Report's deferred items | `constitution.md:129` | A |
| 32 | Version/Ratified/Last-Amended footer | Single line: `**Version**: … \| **Ratified**: … \| **Last Amended**: …` | `constitution-template.md:49` | A |
| 33 | Constitution supremacy in analysis | Constitution conflicts are **automatically CRITICAL** and require changing the spec/plan/tasks — "not dilution, reinterpretation, or silent ignoring". Changing a principle must happen in a separate explicit command | `analyze.md:60` | A |
| 34 | `/analyze` is strictly read-only | "Do **not** modify any files." Remediation offered but never auto-applied; user must approve | `analyze.md:58, 202, 247` | A |
| 35 | Six detection passes | Duplication, Ambiguity, Underspecification, Constitution Alignment, Coverage Gaps, Inconsistency | `analyze.md:119-152` | A |
| 36 | Bidirectional coverage gaps | Requirements with zero tasks **and** tasks with no mapped requirement | `analyze.md:142-144` | A |
| 37 | Terminology-drift detection | Same concept named differently across files; entities in plan but absent from spec | `analyze.md:148-149` | A |
| 38 | 4-level severity with an untestable-criterion rule | CRITICAL/HIGH/MEDIUM/LOW; **"untestable acceptance criterion" is HIGH** | `analyze.md:157-160` | A |
| 39 | Finding cap = 50, with overflow summary | "Limit to 50 findings total; aggregate remainder in overflow summary" | `analyze.md:117, 242` | A |
| 40 | Determinism requirement | "Rerunning without changes should produce consistent IDs and counts" | `analyze.md:243` | A |
| 41 | Progressive disclosure, named as a principle | Load only the minimal necessary context per artifact; summarize long sections; don't dump raw text | `analyze.md:75-77, 241`; `checklist.md:124-128` | A |
| 42 | `[P]` parallel marker | `[ID] [P?] [Story] Description`. "**[P]**: Can run in parallel (different files, no dependencies)" | `tasks-template.md:16-18, 246` | A |
| 43 | `[P]` emission rule | "Include ONLY if task is parallelizable (different files, no dependencies on incomplete tasks)" | `tasks.md:161` | A |
| 44 | Inline dependency notation | Sequential tasks name their predecessors in prose: `T014 [US1] Implement [Service] … (depends on T012, T013)` — and carry no `[P]` | `tasks-template.md:94` | A |
| 45 | **Independence is designed in at the spec layer** | User stories must be prioritized P1/P2/P3 and each **INDEPENDENTLY TESTABLE** — "if you implement just ONE of them, you should still have a viable MVP" | `spec-template.md:14-24` | A |
| 46 | `**Independent Test**:` is a required spec field | Every user story states how it can be verified alone | `spec-template.md:32, 47, 61` | A |
| 47 | Foundational phase as an explicit barrier | Phase 2 "Blocking Prerequisites" — "No user story work can begin until this phase is complete", ending in a **Checkpoint** | `tasks-template.md:58-73` | A |
| 48 | Parallelism follows from independence | Only *after* the barrier do stories go parallel: "Once Foundational phase completes, all user stories can start in parallel" | `tasks-template.md:169-171, 188-195` | A |
| 49 | Explicit anti-pattern line | "Avoid: vague tasks, same file conflicts, **cross-story dependencies that break independence**" | `tasks-template.md:252` | A |
| 50 | `[Story]` tag for traceability | Each task carries `US1`/`US2`/`US3` mapping it to a user story | `tasks-template.md:19, 247` | A |
| 51 | Failure policy differs by marker | "Halt execution if any non-parallel task fails. For parallel tasks [P], continue with successful tasks, report failed ones" | `implement.md:162-163` | A |
| 52 | Constitution Check as a plan-time gate | "*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*" — checked twice | `plan-template.md:39-41` | A |
| 53 | Complexity Tracking table | Filled **only** on a constitution violation: Violation \| Why Needed \| Simpler Alternative Rejected Because | `plan-template.md:106-113` | A |
| 54 | Three named spec-persistence models | **Flow-Forward** (each feature dir is a historical record), **Living Spec** (spec.md is the contract, plan/tasks derived), **Flow-Back** (implementation discoveries may reshape the artifact set) | `docs/guides/evolving-specs.md:17-80` | A |
| 55 | Flow-Back's discipline clause | "the first useful edit can happen wherever the insight lands" — but "Do not leave a lower-level change in tasks.md or code if spec.md still says something different" | `evolving-specs.md:65-80` | A |
| 56 | Re-analyze before resuming | In Living Spec and Flow-Back, `/analyze` runs again before implementation resumes | `evolving-specs.md:51, 73-76` | A |
| 57 | `/converge` gap-type taxonomy | `missing` / `partial` / `contradicts` / `unrequested`, each finding tracing to a `source-ref`, emitted as `- [ ] T042 <description> per <source-ref> (<gap-type>)` | `converge.md:148-215` (grep) | B |
| 58 | `unrequested` as a first-class gap | Code that exists but no artifact asked for — scope creep detected in the same pass as missing work | `converge.md:148-176` (grep) | B |
| 59 | Converge appends, never rewrites | Adds a `## Phase N: Convergence` section to tasks.md; leaves tasks.md untouched when already satisfied | `converge.md:74-82` (grep) | B |
| 60 | Sections deleted, not marked N/A | "When a section doesn't apply, remove it entirely (don't leave as 'N/A')" | `specify.md:291` | A |
| 61 | Checklist append-only with monotonic IDs | `CHK001`+; existing file ⇒ continue from last ID; "Never delete or replace existing checklist content" | `checklist.md:136-138` | A |
| 62 | Extension hook protocol | `.specify/extensions.yml`, `hooks.before_*`/`after_*`, `optional` flag, `EXECUTE_COMMAND:` emission, explicit "emitting the block alone does not run the hook" | `analyze.md:19-50`; repeated in every command | A |
| 63 | Workflow engine with loop constructs | `do_while`, `while_loop`, `fan_out`, `fan_in`, `gate`, `if_then`, `switch` as Python step packages | `src/specify_cli/workflows/steps/*/` (ls) | B |
| 64 | `.specify/feature.json` as the disambiguation pointer | Persists the resolved feature dir so downstream commands locate it without relying on branch names | `specify.md:99-106` | A |
| 65 | Spec dir and git branch decoupled | "The spec directory name and the git branch name are independent" | `specify.md:110` | A |

## 3. Transferable to omp-custom

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| #1 "unit tests for English" | Coordinator's mini-spec framing; verifier | `zero` | **ADOPT** | The best single sentence in this cluster. It gives the coordinator a *generative* test for a criterion — "would this fail if the spec were badly written, or only if the code were broken?" — which is exactly the falsifiability property our workflow's quality story rests on. Our rule currently asserts criteria must be checkable; this makes the assertion operational. |
| #2/#3/#4 wrong-vs-right + prohibited openers + required patterns | Criteria-writing rule | `zero` | **ADOPT (trimmed)** | Take the prohibited openers (#3) and 3-4 of the six patterns (#4). Their full paired lists run ~60 lines; we need ~8. The banned-opener list is the cheap high-value half: it catches the most common bad criterion mechanically, by first word. |
| #5 six dimensions + #7 marker vocabulary | Verifier output shape | `zero` | **ADAPT** | Adopt the `[Gap]` vs `[Ambiguity]` vs `[Conflict]` distinction — "the spec is silent" and "the spec is unclear" need different fixes and our verifier currently conflates them. Drop the six-dimension taxonomy as ceremony at our scale. |
| #8/#9/#10 vague adjectives, placeholders, verb-without-object | Verifier / diff-reviewer check | `zero` | **ADOPT** | Three of the very few things that *are* mechanically checkable in prose: a word blacklist, a token blacklist, and a missing-object test. Cheap, and they are checks we implement ourselves — no CLI. |
| #11/#12 measurable + tech-agnostic, with **bad** examples | Criteria-writing rule | `zero` | **ADOPT** | The bad examples do the work. "API response time under 200ms" being *rejected* teaches the mechanism boundary better than any positive rule. Directly serves our "no mechanism" clause. |
| #14 self-validation with max-3-iterations | `/standard`, `/orchestrated` | `zero` | **ADOPT** | A bounded quality loop with a documented give-up. This is loop *discipline*, not a loop-control engine — the bound is the whole point and it protects tokens-per-accepted-outcome. |
| #15 `[NEEDS CLARIFICATION: q]` inline | Coordinator's mini-spec | `zero` | **ADOPT** | Records ambiguity *at the point of ambiguity*. An implementer reading criterion 3 sees the doubt attached to criterion 3. Costs one bracket convention. |
| #16/#18 max-3 markers + priority order + 3 gating conditions | Our adopted 5-question triage cap | `zero` | **ADOPT** | Upgrades the cap we already adopted from a *count* to a *filter*. `scope > security/privacy > UX > technical detail` tells you which 5, and the three conditions tell you whether a question qualifies at all. Without this the cap is arbitrary. |
| #17 "reasonable defaults — don't ask" list | Triage cap | `zero` | **ADOPT** | The other half of the cap: an explicit list of things you must decide yourself. Prevents the cap being spent on auth-method and retention questions. |
| #21 "think like a tester" | Criteria-writing rule | `zero` | **ADOPT** | One clause, and it is the disposition that makes #1 work. |
| #22 FR-###/SC-### stable IDs | Mini-spec criteria | `zero` | **ADAPT** | Numbered criteria (`AC-1`…) so a verifier, an implementer, and a diff-reviewer can all cite the same one. We fan out; unnumbered criteria cannot be referenced across parallel workers without ambiguity. Skip the FR/SC *split* — one flat list. |
| #23 buildable-work filter | Mini-spec | `zero` | **ADOPT** | A criterion nobody can build against is not a criterion. Keeps aspirational metrics out of the acceptance set. |
| #38 untestable criterion = HIGH | Verifier severity | `zero` | **ADOPT** | Puts a *price* on our central rule. An unfalsifiable criterion is a defect in the spec, not a nitpick. |
| #39 finding cap + overflow summary | verifier, diff-reviewer | `zero` | **ADOPT** | Scale it down hard (theirs is 50). Directly protects tokens-per-accepted-outcome: a reviewer that returns 200 findings costs a full cycle and gets skimmed. |
| #40 determinism | verifier | `zero` | **ADAPT** | Aspirational for an LLM, but stating it suppresses gratuitous re-ordering between runs and makes two verifier runs comparable. |
| #41 progressive disclosure | All 4 worker agents | `per-spawn` | **ADOPT** | Named, quotable version of the discipline our whole metric depends on. One line per worker. |
| #33 constitution supremacy + separate-amendment rule | `AGENTS.md` (constitution already adopted) | `zero` | **ADOPT** | The missing enforcement half of what we already took. A principle that can be reinterpreted mid-task to unblock work is not a principle. "Fix the work, not the principle; amend only in a separate explicit step." |
| #34 read-only analysis + approval-gated remediation | diff-reviewer | `zero` | **ADOPT** | A reviewer that edits destroys its own evidence. Our diff-reviewer should be structurally read-only. |
| #36 bidirectional coverage | verifier | `zero` | **ADOPT** | Criteria with no implementation **and** changes with no criterion. The second direction catches scope creep, which our parallel fan-out makes likelier. |
| #45/#46/#49 independence designed at spec layer; `Independent Test` field; anti-pattern line | Coordinator, **before** dispatch | `zero` | **ADOPT — the key structural finding** | Their model **agrees with our hard rule and is stricter**: independence is a property established when the units are *defined*, then merely honored at execution. `[P]` is a consequence, not a decision. See §5. |
| #47/#48 foundational barrier + checkpoint | `/orchestrated` | `zero` | **ADOPT** | Shared prerequisites are done *serially before* fan-out. This is how you get real independence instead of asserting it. Maps onto coordinator-does-foundation-then-dispatches. |
| #51 failure policy by marker | `/orchestrated` | `zero` | **ADOPT** | Halt on a sequential failure; on parallel failure keep the successes and report. We need a stated policy for a partially-failed fan-out. |
| #53 Complexity Tracking table | `AGENTS.md` constitution | `zero` | **ADOPT** | Three columns, filled only on violation, and the third — "Simpler Alternative Rejected Because" — is the one that would have stopped `.omp/policies/`. Cheapest governance artifact in the cluster. |
| #54/#55 three persistence models + Flow-Back discipline | Divergence handling | `zero` | **ADOPT (pick one)** | Names our situation: we are **Flow-Back**. Adopt the label plus its discipline clause — capture the discovery where it lands, then reconcile upward before continuing. Reject Flow-Forward (needs a doc tree) and Living Spec (needs regeneration). |
| #57/#58 gap-type taxonomy incl. `unrequested` | verifier / diff-reviewer | `zero` | **ADAPT** | Four words — missing / partial / contradicts / unrequested — that make a verdict actionable, and `unrequested` gives scope creep a name. Grade B (grepped, not read in full); verify before writing into the spec. |
| #24/#25 constitution semver + ambiguous-bump rule | `AGENTS.md` | `zero` | **DEFER → now ADOPTABLE** | We deferred this wanting the real shape. It is 4 lines of rule + a 1-line footer (#32), no tooling. Verified precisely at `constitution.md:87-90`. Trigger met: decide now. |
| #26/#27/#28 Sync Impact Report | `AGENTS.md` amendments | `zero` when unchanged; `per-action` on amendment | **ADAPT** | Verified precisely. Adopt the **rename record** (old → new title) and the version delta — a renamed principle silently invalidates every reference to it, and that is the failure the HTML comment prevents. Drop the ✅ downstream-template audit (#28): ceremony at our file count. Note the real cost: an HTML comment at the top of `AGENTS.md` is `persistent` — `AGENTS.md` is in context every turn — so cap it at ~4 lines, or put it in the commit message instead, where it is `zero`. |
| #29 scope guard + Next Actions without invoking | Command preambles | `zero` | **ADOPT** | Converges with OpenSpec's planning boundary. Suggest the follow-up; do not run it. |
| #30 declarative, testable, free of vague language | `AGENTS.md` principle-writing | `zero` | **ADOPT** | Applies our criterion discipline to the constitution itself. |
| #60 delete inapplicable sections | Mini-spec | `zero` | **ADOPT** | "N/A" sections are pure token cost. Trivial, real. |
| #6 ≥80% traceability floor | — | — | **DEFER** | Trigger: if verifier findings are ever observed drifting from cited criteria. A percentage floor over a handful of criteria is noise; the *citation* habit is already covered by #22. |
| #13 16-item checklist file / #61 CHK IDs | — | — | **REJECT** | A generated per-feature checklist file is a fifth document. Harvest the item *text* into our criteria rule; do not create the artifact. |
| #52 double-checked plan gate | — | — | **REJECT** | Two constitution checks per feature is ceremony at our scale. One, at dispatch. |
| #62 extension hooks | — | — | **REJECT** | ~30 lines of hook boilerplate in *every* command file — the largest single token cost in this repo and it buys nothing without their installer. |
| #63 workflow engine (`do_while`, `fan_out`, `gate`) | — | — | **REJECT** | Their loop-control engine; already rejected, and confirmed here as Python step packages requiring the CLI. |
| #64/#65 `.specify/feature.json`, branch decoupling | — | — | **REJECT** | State-file disambiguation for a multi-session CLI. Our coordinator holds this in-session. The *principle* (never infer identity from branch name) is worth remembering, but there is nothing to attach it to. |

## 4. What this repo does that we deliberately will not

**Five to eight documents before code.** `spec.md`, `plan.md`, `research.md`,
`data-model.md`, `quickstart.md`, `contracts/`, `tasks.md`, plus `checklists/*.md`
(`plan-template.md:49-57`). This is precisely the failure mode named in our objective
function. `/quick` must produce code from a request with a mini-spec in the same session;
this pipeline cannot.

**Nine commands with a fixed order.** `constitution → specify → clarify → plan → tasks →
analyze → implement → converge`, several with hard preconditions ("This command MUST run
only after `tasks` has successfully produced a complete tasks.md", `analyze.md:54`). Our
three commands are entry points, not pipeline stages.

**Hook boilerplate in every command file.** The `.specify/extensions.yml` protocol is
restated nearly verbatim in pre- and post-execution blocks in every template — `analyze.md`
spends lines 19-50 and 204-234 on it, roughly **30% of a 255-line file**, on a mechanism
that does nothing unless their CLI installed a `extensions.yml`. `checklist.md` spends 33 of
370 lines the same way. This is the concrete ceremony-exceeds-value case in this repo, and
it is a token cost paid on *every* invocation.

**Constitution self-application is unverified.** The constitution declares "Test-Backed
Change (NON-NEGOTIABLE)" (`.specify/memory/constitution.md:13`), yet no principle appears
enforceable by anything in `templates/` — the gates are prompts asking an agent to check.
The pattern we adopted is sound; the lesson is that a constitution's teeth are entirely in
whatever *reads* it, and for us that is a coordinator's attention, not a checker.

**`/analyze` as a separate pass.** A ninth command whose whole job is cross-artifact
consistency. Its *checks* (#8/#9/#10/#35/#36) are excellent and we take them; its
*existence as a command* is an artifact of having many documents. With one mini-spec, these
become verifier clauses, not a command.

**Prose-only dependency notation.** `(depends on T012, T013)` in free text
(`tasks-template.md:94`) is unparseable and unvalidated — nothing checks that a `[P]` task
truly shares no file with its siblings. `[P]` is an assertion by the author, honored on
trust. We should not pretend otherwise if we adopt the marker.

## 5. Contradictions with our current spec or registry

**1. The parallelization question — their model agrees with us, and is stricter than our
rule as stated.** Our hard rule is stated as an execution-time constraint: if two units
have a real dependency they must not have been parallelized. spec-kit reaches the same
place from the other end, and the ordering matters:

- Independence is required **at spec time**, before any task exists: user stories must be
  "INDEPENDENTLY TESTABLE — if you implement just ONE of them, you should still have a
  viable MVP" (`spec-template.md:16-24`), and each carries a mandatory
  `**Independent Test**:` field (`spec-template.md:32`).
- Genuinely shared work is extracted into a **serial barrier phase** before any fan-out:
  "No user story work can begin until this phase is complete" (`tasks-template.md:58-73`).
- Only then is parallelism *granted*: "Once Foundational phase completes, all user stories
  can start in parallel" (`tasks-template.md:169-171`).
- And a cross-story dependency is named an **anti-pattern**, not a case to handle:
  "Avoid: … cross-story dependencies that break independence" (`tasks-template.md:252`).

So `[P]` is not a decision about how to run a task — it is a *readout* of a property
established when the units were defined. Our rule is correct but describes the symptom; the
stronger form is a coordinator obligation: **before dispatching, state how each unit can be
verified alone, and pull anything shared into a serial step first.** If our recorded rule is
phrased only as an execution-time prohibition, it is incomplete rather than wrong.

**2. The reported governance shape is confirmed exactly — no correction needed.** The task
brief said spec-kit "reportedly has constitution semver (MAJOR/MINOR/PATCH rules for
principle changes) plus a Sync Impact Report as an HTML comment recording version delta,
renamed principles, added/removed sections." Verified line by line:
semver rules at `constitution.md:87-90` (MAJOR = "backward incompatible governance/principle
removals or redefinitions"; MINOR = "New principle/section added or materially expanded
guidance"; PATCH = "Clarifications, wording, typo fixes, non-semantic refinements"); the
report at `constitution.md:99-104` ("prepend as an HTML comment at top of the constitution
file after update") with version change, "old title → new title if renamed", added sections,
removed sections, and deferred TODOs. A live instance exists at
`.specify/memory/constitution.md:1-32`. The recorded description was accurate.

**3. Do not record that spec-kit *validates* specs.** There is no schema, no linter, no
validate command over spec content, and no strict mode. `/analyze` and `/checklist` are
prompt files instructing an agent to read prose and report. The `scripts:` frontmatter
(`analyze.md:3-6`) calls `check-prerequisites.sh`, which checks *file presence*, not
content. Contrast OpenSpec, which has a real Zod + imperative validator. If any recorded
claim treats spec-kit's `/analyze` as mechanical validation, it is overstated — and this
matters to us because #8/#9/#10 are checks we would have to implement ourselves.

**4. The constitution-vs-`analyze` boundary is sharper than a generic "constitution wins."**
Constitution conflicts are "automatically CRITICAL and require adjustment of the spec, plan,
or tasks — **not dilution, reinterpretation, or silent ignoring** of the principle"
(`analyze.md:60`). We adopted the constitution pattern into `AGENTS.md`; if what we recorded
is only "AGENTS.md holds principles," we are missing the clause that makes it binding.

## 6. Cost profile

Every ADOPT/ADAPT row is prose or a naming convention. Nothing needs a runtime consumer.

- **Criteria-craft cluster (#1, #3, #4-trimmed, #8, #9, #10, #11, #12, #21):** the core
  recommendation of this report. Estimate **~15-20 lines** in one place — wherever the
  criterion rule already lives. Cost tier `zero` in the contract's sense: it enters context
  only when the coordinator writes criteria, which is already a step we pay for. Basis: #1 is
  one sentence, #3 a one-line blacklist, #4 four patterns, #8/#9 two blacklists, #10-#12 one
  line each plus 2 bad examples.
- **Triage-cap upgrade (#16, #17, #18):** ~6 lines attached to the already-adopted cap. `zero`.
- **Verifier/diff-reviewer clauses (#5-markers, #34, #36, #38, #39, #40, #57):** ~10 lines
  across two agent prompts. `per-spawn` for those two agents only.
- **Progressive disclosure (#41):** one line × 4 workers. `per-spawn`, and the tier that
  multiplies — consistent with the recorded skill-listing multiplier finding, worker-prompt
  additions are the expensive tier and must stay at one line.
- **Independence-before-dispatch (#45/#46/#47/#48/#49/#51):** ~8 lines in `/orchestrated`
  plus one obligation in the coordinator's pre-dispatch step. `lazy` — paid on
  `/orchestrated` invocation only, never in `/quick`.
- **Governance (#24/#25/#32 semver, #53 Complexity Tracking, #30, #33):** ~10 lines in
  `AGENTS.md`. **`persistent`** — `AGENTS.md` is in context every turn. This is the most
  expensive tier in this report, so the semver rules plus the footer are worth it and the
  Sync Impact Report probably belongs in the commit message (`zero`) rather than at the top
  of the file (`persistent`).
- **Flow-Back label (#54/#55):** ~3 lines. `zero`.
- **REJECTs (#62 hooks, #63 engine, #13/#61 checklist files, #52, #64/#65):** save both the
  CLI dependency and, in #62's case, the largest per-invocation token cost in the repo.

All line counts are estimates from rule text drafted while reading. Nothing has been written
to a file, so nothing is token-counted.

## 7. Coverage and limits

**Files read in full this pass:**
- `templates/commands/checklist.md` (370 lines — **new this pass**, the highest-value file)
- `templates/commands/analyze.md` (255 lines — re-verified)
- `templates/commands/constitution.md` (165 lines — re-verified, §5 item 2 rests on it)
- `templates/commands/specify.md` (346 lines — re-verified)
- `templates/spec-template.md` (131 lines — re-verified)
- `templates/tasks-template.md` (253 lines — re-verified)
- `templates/plan-template.md` (113 lines — re-verified)
- `templates/constitution-template.md` (51 lines — **new this pass**)
- `docs/guides/evolving-specs.md` (~80 lines read of the file — **new this pass**)
- `.specify/memory/constitution.md` — **first 60 lines only** (the Sync Impact Report
  instance and Principle I). The remaining principles are unread.
- `LICENSE` (head)

**Files sampled (grep only):**
- `templates/commands/converge.md` — grepped for headers/MUST/gap; #57/#58/#59 are grade **B**
  and rest on grep context lines, not a full read
- `templates/commands/clarify.md` — grepped for the question cap only (#19). The rest of its
  taxonomy and coverage matrix is unread
- `templates/commands/tasks.md` — grepped for `[P]`/parallel only
- `templates/commands/implement.md` — grepped for parallel/failure policy only
- `src/specify_cli/workflows/steps/` — directory listing only, no Python read (#63 grade B)

**Not opened:** all 159 files under `tests/`; all 126 under `src/` (no Python source read
this pass at all); all 59 under `extensions/`; all 29 `presets/`; 8 `workflows/` incl.
`speckit/workflow.yml` and `ARCHITECTURE.md`; 33 of 37 `docs/` — notably
`docs/concepts/sdd.md`, `spec-of-specs.md`, `spec-persistence.md`,
`docs/concepts/complex-features.md`; all 37 `.github/`; `templates/commands/plan.md`
(the command, distinct from the template — **not read**);
`templates/commands/taskstoissues.md`; `templates/checklist-template.md`;
`spec-driven.md` (root, likely the methodology essay); `AGENTS.md`; `CHANGELOG.md`;
`README.md`; 8 `examples/`; 15 `scripts/`.

**Claims that need a live run before use:**
- Whether the 16-item spec quality checklist (#13) actually blocks progress or is advisory
  in practice. The template says items marked incomplete "require spec updates before
  clarify or plan" (`specify.md:182`) with no enforcement path — a live run would show
  whether an agent honors it.
- Whether `/analyze`'s coverage mapping produces stable IDs across runs as #40 requires.
  Asserted in the prompt; unverifiable by reading.
- Whether `[P]` markers in generated `tasks.md` files are ever wrong (two `[P]` tasks
  touching one file). Nothing validates it, so the only check is empirical.

**Anything I suspect but could not verify:**
- That `templates/commands/plan.md` contains additional criteria-quality or gate rules not
  in `plan-template.md`. I read the template but **not** the command that fills it — a real
  gap, since the command files consistently carry more rule content than their templates
  (compare `specify.md`'s 346 lines against `spec-template.md`'s 131).
- That `docs/concepts/spec-of-specs.md` and `docs/concepts/sdd.md` state the methodology's
  rationale in a form worth quoting. Unread; likely the best source for a fair statement of
  what the ceremony is *for*, which would strengthen §4.
- That `/converge`'s four gap types are exactly as I recorded. Grade B — grep context only.
  Confirm before writing #57/#58 into the spec.
- That the `.specify/memory/constitution.md` instance is generated rather than hand-written.
  It is unusually thorough (line-referenced template audits), which suggests careful human
  authoring, and if so #27/#28 describe an aspiration more than a typical output.
