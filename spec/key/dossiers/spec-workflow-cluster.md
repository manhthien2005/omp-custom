# Dossier — spec-workflow cluster (partial + coordinator addendum)

> Authority boundary: This dossier is source/research evidence.
> Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology,
> dispatch, review mechanism, or capability behavior.
> Current design and execution authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.


> Status: **PARTIAL for the delegated pass**, supplemented by a coordinator pass (§5).
> The delegated pass read spec-kit in depth, enumerated OpenSpec without reading file
> contents, and did not open the other four repos. The coordinator then read a targeted
> slice of all four plus two more OpenSpec/spec-kit files — recorded in §5, and the basis
> for the grade-B claims those repos carry in `02-repo-synthesis.md`. §4 remains the
> honest gap list for everything neither pass covered.

| Repo | Commit SHA | License | Read at | Depth this pass |
|---|---|---|---|---|
| github/spec-kit | `81d5cdbbf2c96f7ce1a2801c6185f2951f1f61be` | MIT (`LICENSE` present, not re-read this pass) | `_research/upstreams/spec-kit` | **deep** — 9 command/template files read in full; +2 in §5 |
| Fission-AI/OpenSpec | `d57889664cab4f2f061d236ec3ff82a5578701bb` | MIT (`LICENSE` present, not re-read this pass) | `_research/upstreams/OpenSpec` | **structure only** — `git ls-files` (1052 files); +1 skill body and schema listing in §5 |
| 12-factor-agents | `d20c728368bf9c189d6d7aab704744decb6ec0cc` | Apache-2.0 code / CC-BY-SA-4.0 content | `_research/upstreams/12-factor-agents` | **targeted** — 4 of 13 factor files (§5) |
| agents.md | `d1ac7f063d20e70015ed6732664049ae4ba9d74e` | LICENSE present | `_research/upstreams/agents.md` | **surface** — tree + README size only (§5) |
| mini-swe-agent | `a83fcae82d2a08f0ee0c688f9d137b3566c097f8` | LICENSE.md present | `_research/upstreams/mini-swe-agent` | **targeted** — `agents/default.py` + `config/default.yaml` (§5) |
| promptfoo | `1c30e183c4a464d953898398399dc6aa69786471` | LICENSE present | `_research/upstreams/promptfoo` | **targeted** — deterministic assertion docs (§5) |

Note on clone location: the clones are **not** inside this worktree. `.gitignore:2` excludes
`_research/upstreams/`, so they live only at `D:\Dev\Projects\omp-template\_research\upstreams\`.
All paths below are relative to that directory.

---

## 1. Per-repo thesis

- **spec-kit** — Quality is enforced by making each stage's *prompt* demand a
  self-validating artifact: a fixed-shape template, a generated checklist, and a hard gate
  that refuses to advance while the checklist fails or an ambiguity marker survives.
- **OpenSpec** — (inferred from layout, unverified) A ratified spec tree is kept separate
  from in-flight change proposals, and each change carries only the *delta* against
  named capabilities, then is archived date-prefixed on completion.

---

## 2. Mechanism inventory — spec-kit (verified)

OMP attachment points are drawn only from the real discovery surface: `commands/`,
`agents/`, `skills/<name>/SKILL.md`, `rules/`, `RULES.md`, `prompts/`, `instructions/`
(with `applyTo`), `hooks/pre|post`, `tools/`, `AGENTS.md`, `SYSTEM.md`, `config.yml`.

| # | Mechanism | file:line | Problem it prevents | OMP attachment point | Token cost | Verdict |
|---|---|---|---|---|---|---|
| 1 | **Ambiguity-marker budget** — at most 3 `[NEEDS CLARIFICATION: …]` markers; everything else must be an informed guess recorded as an assumption; markers ranked scope > security/privacy > UX > technical | `templates/commands/specify.md:122-129`, `:297-303` | Interrogation spiral (20 questions) *and* silent guessing. Forces the model to spend its uncertainty budget on decisions that actually move scope | `skills/<name>/SKILL.md` body (spec-authoring skill) | on use, ~120 tok | **ADOPT** — smallest high-value rule in the repo; pure prose |
| 2 | **Self-generated quality checklist + bounded re-validation loop** — after writing the spec, the command *generates* `checklists/requirements.md` (16 concrete items), grades the spec against each, patches, re-runs, max 3 iterations, then warns | `templates/commands/specify.md:144-234` | Artifact declared done while it still contains placeholders, untestable requirements, or leaked implementation detail. The checklist is a machine-checkable proxy for review | `skills/<name>/SKILL.md` body; the 16 items also fit an `output:` schema on a spec-writing agent | on use, ~350 tok (checklist body) | **ADAPT** — adopt the loop + item list; drop the separate file, put the grade in structured output |
| 3 | **Clarification-question presentation contract** — recommended option stated first with 1–2 sentence reasoning, then an options table with an *Implications* column, plus a Custom row | `templates/commands/specify.md:202-221`; `templates/commands/clarify.md:148-169` | Questions that cost the user more than they save. User answers with one letter, and the implications column means they answer *informedly* | `skills/` body or `command prose` | on use, ~150 tok | **ADOPT** — cheap, and directly raises tokens-per-accepted-outcome |
| 4 | **Ambiguity taxonomy scan with Clear/Partial/Missing coverage map** — 11 named categories (functional scope, domain/data, interaction, non-functional, integration, edge cases, constraints/tradeoffs, terminology, completion signals, placeholders) scanned before any question is asked; map stays internal | `templates/commands/clarify.md:73-127` | Asking whatever comes to mind. Converts "is this spec vague?" into a checklist sweep, so unresolved *categories* compete on Impact × Uncertainty | `skills/<name>/SKILL.md` body | on use, ~450 tok | **ADAPT** — taxonomy is good; 11 categories is more than our task sizes justify. Trim to ~6 |
| 5 | **One-question-at-a-time loop with hard cap (5) and no lookahead** — never reveal queued questions; retries on the same question don't consume budget; early-exit on "done/good/no more" | `templates/commands/clarify.md:129-180`, `:233-235` | Wall-of-questions dumps, and unbounded clarification. The no-lookahead rule stops the model from anchoring the user on its own agenda | `skills/` body | on use, ~200 tok | **ADOPT** |
| 6 | **Incremental write-after-each-answer** — each accepted answer is appended to a `## Clarifications` / `### Session YYYY-MM-DD` log *and* immediately routed into the correct spec section (functional → FR bullet, non-functional → measurable Success Criterion, edge case → Edge Cases, terminology → normalize globally), file saved atomically after each | `templates/commands/clarify.md:182-198` | Losing 5 answers to a context blowout at question 5, and answers piling into a Q&A appendix that never reaches the requirements | `skills/` body | on use, ~250 tok | **ADOPT** — the routing table is the valuable half; the session log is optional |
| 7 | **Contradiction-replacement rule** — if a clarification invalidates an earlier statement, *replace* it; "leave no obsolete contradictory text" | `templates/commands/clarify.md:195` | Specs that accumulate mutually exclusive requirements. Single line, high leverage | `RULES.md` line, or `skills/` body | sticky if in RULES.md (~25 tok/turn) | **ADOPT** — as one `RULES.md` line |
| 8 | **Checklist re-validation with regression reporting** — re-grade the checklist against the updated artifact, toggle only markers whose state *changed*, and report three lists: newly passing / **regressions** / still unchecked, plus `12/16 → 15/16` counts | `templates/commands/clarify.md:210-227`, `:281` | Fixing item A while silently breaking item B; and noisy diffs from cosmetic rewrites | `agent frontmatter output:` (a verifier agent returning `{passed, failed, regressed}`) | per spawn, schema ~80 tok | **ADOPT** — this is the single best fit for OMP structured output |
| 9 | **Constitution as a gate, re-checked twice** — `## Constitution Check` is a GATE that must pass before research and be re-evaluated *after* design; `ERROR on gate failures` | `templates/plan-template.md:39-43`; `templates/commands/plan.md:66-72`, `:164` | Principles read once at kickoff then quietly abandoned once design pressure arrives. The post-design re-check is the part most people omit | `AGENTS.md` (principles) + `commands/*.md` prose (the gate) | principles persistent; gate ~60 tok on use | **ADAPT** — omp-custom already has AGENTS.md + RULES.md; it lacks the *re-check after design* step |
| 10 | **Complexity Tracking table** — filled *only* when the constitution check has violations: `Violation \| Why Needed \| Simpler Alternative Rejected Because` | `templates/plan-template.md:106-113` | Complexity added by default. Forcing the third column ("simpler alternative rejected because") is what kills most unnecessary abstraction | `skills/` body, or an `output:` field on a planning agent | on use, ~60 tok | **ADOPT** — near-zero cost, directly serves our anti-gold-plating stance |
| 11 | **Given/When/Then acceptance scenarios attached per user story** | `templates/spec-template.md:34-37`, `:49-51`, `:63-65` | "Done" with no agreed observable. Given/When/Then is directly executable as a verification step | `skills/` body; template block in `prompts/*.md` | on use, ~40 tok | **ADOPT** |
| 12 | **Prioritized, independently testable story slices** — P1/P2/P3, each with *Why this priority* and an *Independent Test*; each slice must be a viable MVP on its own | `templates/spec-template.md:11-24`, `:26-37` | Monolithic features that can only be evaluated at the end. The "Independent Test" line is what makes a slice verifiable | `skills/` body | on use, ~120 tok | **ADAPT** — valuable for `/orchestrated`, overkill for `/quick` |
| 13 | **Technology-agnostic measurable success criteria, taught by counterexample** — SC-### must be measurable, tech-agnostic, user-focused, verifiable; prompt ships 4 good and 4 bad examples ("API response <200ms" → rejected as too technical) | `templates/spec-template.md:106-118`; `templates/commands/specify.md:318-339` | Success criteria that restate the implementation. The bad-examples list does more work than the rules | `skills/` body | on use, ~200 tok | **ADOPT** — the good/bad example pairs specifically |
| 14 | **Assumptions section as the escape valve for guesses** — "make informed guesses" is only safe because every guess must be written down, with a named list of things never to ask about (data retention, perf targets, error handling, authn, integration patterns) | `templates/spec-template.md:120-131`; `templates/commands/specify.md:297-316` | Both failure directions at once: asking about defaults, and guessing invisibly | `skills/` body | on use, ~100 tok | **ADOPT** — pairs with #1; neither works alone |
| 15 | **Strict task-line grammar with positive AND negative examples** — `- [ ] T001 [P] [US1] Description with file path`; 4 ✅ and 4 ❌ examples, each ❌ annotated with what's missing | `templates/commands/tasks.md:149-179` | Task lists that can't be machine-read: missing IDs, missing file paths, missing parallel markers. The ❌-with-reason format is a reliable way to get format compliance from a model | `skills/` body, or `agent frontmatter output:` for a planner | on use, ~200 tok | **ADAPT** — keep the grammar and the ❌ examples; drop `[US#]` unless we adopt #12 |
| 16 | **`[P]` parallelizable marker with an explicit predicate** — "different files, no dependencies on incomplete tasks" | `templates/commands/tasks.md:161` | Fan-out that corrupts shared files. Gives a concrete test for "can these run concurrently" | `commands/*.md` prose in `/orchestrated`; a `hooks/pre` `tool_call` guard could enforce file-disjointness | on use, ~30 tok | **ADOPT** — cheapest safe-parallelism rule found |
| 17 | **Read-only cross-artifact analysis pass** — separate command, `STRICTLY READ-ONLY`, builds semantic models then runs 6 named detection passes (duplication, ambiguity, underspecification, constitution alignment, coverage gaps, inconsistency) and *offers* remediation without applying it | `templates/commands/analyze.md:56-60`, `:106-152`, `:200-202`, `:246-251` | Review that mutates while it reviews, so you can never tell what the reviewer found vs. changed. Also gives coverage as a number: requirements with ≥1 task | `agents/reviewer.md` (we already have this agent) + `output:` frontmatter | per spawn, ~600 tok if shipped whole | **ADAPT** — our `reviewer` agent should get the 6 detection passes + the read-only constraint; skip the report tables |
| 18 | **Severity heuristic bound to the constitution** — CRITICAL is defined as violating a constitution MUST, a missing core artifact, or a zero-coverage requirement blocking baseline function; constitution conflicts are *automatically* CRITICAL and may not be resolved by reinterpreting the principle | `templates/commands/analyze.md:56-60`, `:153-160` | Reviewers negotiating with the rules. "Adjust the spec, not the principle" is the load-bearing sentence | `RULES.md` line + `agents/reviewer.md` `output:` enum | ~40 tok sticky | **ADOPT** |
| 19 | **Explicit token-efficiency budget inside the prompt** — 50-finding cap with overflow summary; progressive disclosure (load only named sections of each artifact); determinism requirement (same input → same finding IDs) | `templates/commands/analyze.md:115-117`, `:236-243` | Review passes whose cost scales with repo size. Note the *named-section* loading list — it tells the model which slices to read, not "read the files" | `agents/reviewer.md` prose | per spawn, ~80 tok | **ADOPT** — directly serves tokens-per-accepted-outcome |
| 20 | **Constitution semver + Sync Impact Report** — MAJOR/MINOR/PATCH rules for principle changes, and an HTML-comment changelog prepended to the file recording version delta, renamed principles, added/removed sections, deferred TODOs | `templates/commands/constitution.md:87-91`, `:99-104` | Silent drift of the governing document. Amendments become reviewable | `AGENTS.md` header block | persistent, ~50 tok | **DEFER** — real value, but only once our constitution actually changes under multiple hands |
| 21 | **Scope Guard** — the constitution command must classify each part of user input as governance content vs. other intent, must NOT execute the non-governance parts, and must list them under `Next Actions` with a suggested follow-up command | `templates/commands/constitution.md:17-34` | Scope creep smuggled in via a config request ("update the rules and also build the login page") | `commands/*.md` prose | on use, ~80 tok | **ADAPT** — the classify-then-defer pattern generalizes to all our commands |
| 22 | **Placeholder-token template** — the artifact ships as `[ALL_CAPS_IDENTIFIER]` slots plus HTML-comment exemplars, and validation asserts *no unexplained bracket tokens remain* | `templates/constitution-template.md:1-50`; `templates/commands/constitution.md:80`, `:106-110` | Models rewriting structure instead of filling it. The "no bracket tokens left" check is a cheap machine-verifiable completeness test | `prompts/*.md` (fill-in templates) | zero (build-time) + on use | **ADOPT** — the leftover-placeholder check is the reusable half |
| 23 | **Decision / Rationale / Alternatives-considered research record** — Phase 0 must resolve every NEEDS CLARIFICATION and consolidate into that exact 3-field shape | `templates/commands/plan.md:114-135` | Decisions with no recoverable "why", so the next session re-litigates them | `skills/` body; or `output:` on `agents/explorer.md` | on use, ~60 tok | **ADOPT** — trivially cheap, and our `explorer` agent has no output contract today |
| 24 | **Quickstart-as-validation-guide, with an explicit anti-scope list** — must contain prerequisites, run commands and expected outcomes; must NOT contain implementation code, model/service bodies, migrations, or full test suites | `templates/commands/plan.md:150-157` | Planning artifacts that become shadow implementations, burning tokens twice | `skills/` body (evidence-before-completion) | on use, ~70 tok | **ADAPT** — fold the "how do I prove this works" prompt into our existing `evidence-before-completion` skill |
| 25 | **Handoff declarations in command frontmatter** — `handoffs:` lists next-stage label + agent + seed prompt, some with `send: true` for auto-dispatch | `templates/commands/specify.md:3-11`; `plan.md:3-11`; `tasks.md:3-12` | Users stranded mid-workflow with no idea what comes next. Cost is paid in frontmatter, not context | **NONE** — OMP command frontmatter has no `handoffs` key. Nearest is prose "next: run /X" | n/a | **REJECT as a mechanism**; keep as prose. Flagging honestly: no attachment point |
| 26 | **`.specify/extensions.yml` hook dispatch protocol** — every command carries ~35 lines of before_/after_ hook discovery, `enabled` filtering, condition-deferral, and an `EXECUTE_COMMAND:` emission contract | `templates/commands/specify.md:21-54`, `:236-269` (repeated near-verbatim in clarify/plan/tasks/analyze/constitution) | Extensibility without editing core commands | **NONE for the prose** — OMP has real `hooks/pre|post/*` TypeScript modules with 25 events; a model-interpreted hook protocol is strictly worse than a runtime one | ~700 tok/command × 6 | **REJECT** — this is the largest single block of text in spec-kit and OMP replaces it with actual runtime hooks |
| 27 | **`{SCRIPT}` prerequisite/path resolution via bash/ps/python trios** — `scripts:` frontmatter, `check-prerequisites.sh --json --paths-only`, JSON parsed for FEATURE_DIR/FEATURE_SPEC/IMPL_PLAN/TASKS | `templates/commands/clarify.md:7-10`, `:64-69`; `plan.md:11-14`; `tasks.md:12-16` | Path guessing across agents. But it's an external-CLI dependency | **NONE as shipped** (violates our no-external-CLI constraint; already rejected as reject-008). A `tools/*.ts` custom tool could serve the same role | n/a | **REJECT** as designed; the *idea* (one deterministic path-resolution call, JSON out) → **ADAPT** into `tools/` if we ever need it |

### Mechanisms with no OMP attachment point (documentation or defect)

Called out plainly, per instruction: **#25 (`handoffs:`)**, **#26 (extensions.yml hook protocol)**,
**#27 (`{SCRIPT}` trio)**. All three are runtime-integration machinery that OMP either already
provides natively (hooks) or forbids (external CLI). Copying their *prose* into `.omp/` would
reproduce the exact error class the template was cleaned up to remove.

---

## 3. OpenSpec — structural observations only (contents NOT read)

Evidence: `git ls-files` at `d578896` (1052 files). Nothing below is confirmed by reading a
spec body, a schema, or a validator. Treat all of it as a hypothesis to verify next pass.

Observed layout, repeated consistently across ~40 change folders:

```
openspec/changes/<change-name>/
  .openspec.yaml          # per-change metadata (contents unread)
  proposal.md             # the "why" (present in every change)
  design.md               # optional — present in ~1/3 of changes
  tasks.md                # the "how" (present in nearly every change)
  specs/<capability>/spec.md   # one delta file PER named capability
openspec/changes/archive/<YYYY-MM-DD>-<change-name>/   # same shape, date-prefixed
```

Three structural claims I consider well-supported by the listing alone:

1. **Change proposals are separated from ratified specs, and a change touches N capabilities.**
   e.g. `openspec/changes/add-global-install-scope/specs/` contains 7 sibling
   `<capability>/spec.md` files (`ai-tool-paths`, `cli-config`, `cli-init`, `cli-update`,
   `command-generation`, `global-config`, `installation-scope`). Capability names recur
   across unrelated changes (`cli-init` appears in 15+ changes) — strong evidence that
   `specs/<capability>/spec.md` inside a change is a *delta against a stable named
   capability*, not a standalone document.
2. **Archive lifecycle is a date-prefixed move**, `changes/<name>/` →
   `changes/archive/<YYYY-MM-DD>-<name>/`, preserving the internal structure
   (`openspec/changes/archive/2025-08-19-adopt-delta-based-changes/…`). ~35 archived
   entries vs ~9 active.
3. **The project self-hosts its own format** — the delta format itself was introduced by a
   change (`archive/2025-08-19-adopt-delta-based-changes/`), and validation by another
   (`archive/2025-08-19-add-zod-validation/`). That means Zod is the validation
   substrate, so "what makes a spec valid" is likely a code schema, not prose.

**Not verified**: the ADDED/MODIFIED/REMOVED requirement-block syntax, the validation
rules, `.openspec.yaml` fields, and the dashboard/archive commands. Files that would settle
it, unread: `docs/writing-specs.md`, `docs/agent-contract.md`, `docs/concepts.md`,
`docs/how-commands-work.md`, `AGENTS.md`, and whatever Zod schema lives under `src/`
(I did not even enumerate `src/`).

---

## 4. Gaps — NOT READ THIS PASS

**spec-kit** (read 9 of ~15 relevant files; ~2,000 of 4,290 lines in the core set):
- `templates/commands/checklist.md` (369 lines) — the general checklist-generation
  mechanism. Likely the single most relevant unread file for mechanism #2/#8.
- `templates/commands/implement.md` (219), `converge.md` (273), `taskstoissues.md` (106)
- `templates/tasks-template.md` (252) — I read the *rules* in `commands/tasks.md` but not
  the template they fill
- `templates/checklist-template.md` (40)
- `.specify/memory/constitution.md` (214) — spec-kit's own *filled* constitution. I read
  only the empty template. This is where I'd learn what a good principle looks like.
- `AGENTS.md` (599)
- `docs/concepts/sdd.md`, `spec-of-specs.md`, `spec-persistence.md`, `complex-features.md`,
  `docs/guides/evolving-specs.md`
- `presets/lean/*` — a *smaller* variant of all five core commands. Directly relevant to our
  token constraint and unread.
- `extensions/assess/*` (5 commands: intake/research/shape/define/decide) — an upstream
  triage funnel, relevant to our `task-triage` skill
- `workflows/speckit/workflow.yml` (78) + `src/specify_cli/workflows/steps/*` (gate,
  fan_out, fan_in, do_while, switch…) — a declarative orchestration engine. Not read;
  probably REJECT territory (second orchestrator) but I have not confirmed that.
- License file not re-opened; MIT asserted from `LICENSE` presence + prior registry entry.

**OpenSpec**: no file contents read at all. Everything in §3 is inferred from the path
listing. Highest-value unread: `docs/writing-specs.md`, `docs/agent-contract.md`,
`docs/concepts.md`, the Zod schema under `src/`, one concrete
`changes/<name>/specs/<cap>/spec.md` body, and one `.openspec.yaml`.

**12-factor-agents**: not opened. Only the `content/` filename list is known
(factor-01…factor-12 + `appendix-13-pre-fetch.md`); `factor-04-tools-are-structured-outputs.md`
and `factor-09-compact-errors.md` look most relevant to our structured-output surface.

**agents.md**, **mini-swe-agent**, **promptfoo**: not opened. No commit SHA or license
captured for any of the four un-read repos — I did not run `git log`/`ls-files` on them.

**Also not done**: no cross-check against `registry/rejected-mechanisms.yml` beyond the two
reject IDs supplied in my brief (reject-008 Python CLI, reject-009 Node CLI). Some
mechanisms above may already be recorded there under other IDs.

---

## 5. Coordinator addendum — what the coordinator read after the delegated pass

> Coordinator pass: 2026-08-07. This section records the four repos the delegated agent did
> not open, plus one additional file each from spec-kit and OpenSpec. These readings are the
> grade-B basis for the repo-synthesis claims in `02-repo-synthesis.md §C-3/§C-4/§D-2/§D-3`.
> File evidence is cited here; synthesis and verdicts are in `02-repo-synthesis.md`.

### 5.1 12-factor-agents — factors 4, 9, 10, 12

Files read: `_research/upstreams/12-factor-agents/content/factor-{04,09,10,12}-*.md`.

- **Factor 4** (`tools-are-structured-outputs.md`) — tools are a discriminated union on
  `intent`; deterministic code dispatches on the model's structured choice. Relevant: sharpens
  T-00.6 (the `status`-discriminated union shape for `agent-result.schema.yml`).
- **Factor 9** (`compact-errors.md`) — explicit `consecutive_errors` counter capped at ~3,
  reset on success, then escalate. Corroborates `spec/15 §D-7`; the *consecutive* reset is the
  delta not reflected in our bound.
- **Factor 10** (`small-focused-agents.md`) — 3–20 steps max; scaffolding encodes a current
  model limitation; re-test as models improve. Corroborates four-worker topology.
- **Factor 12** (`stateless-reducer.md`) — two images, "mostly just for fun." No actionable
  mechanism.

Not read: factors 1, 2, 3, 5, 6, 7, 8, 11, and `appendix-13-pre-fetch.md`. Factors 3 and 8
are the highest-value unread items in this cluster.

### 5.2 mini-swe-agent — `agents/default.py` + `config/default.yaml`

Files read: `_research/upstreams/mini-swe-agent/src/minisweagent/agents/default.py` (first
120 lines, including `AgentConfig` class and `run()` method); `config/default.yaml`
(full, 80 lines); `config/mini.yaml` filename only.

Key verified facts:
- `AgentConfig` declares `step_limit: int = 0`, `cost_limit: float = 3.0`,
  `wall_time_limit_seconds: int = 0`, `max_consecutive_format_errors: int = 3` as first-class
  typed halt conditions, not advisory guidance.
- Failed calls still charge cost ("the call was billed before parsing failed") — honest
  budget accounting.
- The loop resets `n_consecutive_format_errors = 0` on any clean step — consecutive, not total.
- System template mandates "exactly ONE bash code block" per response.

Not read: `environments/`, `models/`, `agents/interactive.py`, all benchmark configs.

### 5.3 promptfoo — deterministic assertion docs

Files read: `site/docs/configuration/expected-outputs/deterministic.md` (assertion tables);
`site/docs/configuration/expected-outputs/` listing (7 subdoc files).

Key verified: `defaults`-aware argument matching (`{status:'Q', page:1}` passes against
`{status:'Q'}` when `page:1` equals the declared default); `ignore` field for nondeterministic
fields; hallucinated extras (`delete_database: true`) fail in every mode; `contains-json`,
`starts-with`, `regex`, `levenshtein(N)`, `similar(threshold)` assertion types; `not-` prefix
for negation; deterministic/model-graded as a **hard split** in the docs organization.

Not read: `javascript.md`, `python.md`, `model-graded/`, `classifier.md`, `guardrails.md`,
all source.

### 5.4 agents.md — structure only

Directory listing from `_research/upstreams/agents.md/`: `pages/`, `components/`, `styles/`,
`public/`, `package.json`, `next.config.ts`. README is 49 lines (line count confirmed). This
is a Next.js documentation site for the `AGENTS.md` convention. There is no mechanism to read
beyond the convention itself, which OMP natively implements at `builtin.ts:910,923`.

Not read: any page bodies, any components.

### 5.5 spec-kit — two additional files

Files read (in addition to the delegated pass's 9):
- `_research/upstreams/spec-kit/.specify/memory/constitution.md` — read header only (the
  SYNC IMPACT REPORT block and the first 30 lines of principles). Confirms the
  version/rationale/sections/follow-up-TODOs governance structure. Body (remaining ~190 lines)
  not read this pass.
- `_research/upstreams/spec-kit/presets/lean/commands/` — directory listing only:
  `speckit.constitution.md`, `speckit.implement.md`, `speckit.plan.md`,
  `speckit.specify.md`, `speckit.tasks.md`. Confirms a *smaller* variant exists. No file
  bodies read.

### 5.6 OpenSpec — one skill body + schema directory listing

Files read (in addition to the delegated pass's structural scan):
- `_research/upstreams/OpenSpec/skills/openspec-verify-change/SKILL.md` — full body (read
  head, 50 lines). Confirms: `compatibility: Requires openspec CLI.` frontmatter honesty
  pattern; disambiguation rules with "Always announce: `Using change: <name>` and how to
  override"; `openspec status --change "<name>" --json` to get schema name and artifact
  paths. Body §4 ("Initialize verification report structure") not read.
- `_research/upstreams/OpenSpec/schemas/spec-driven/` — directory listing:
  `schema.yaml`, `templates/`. Contents not read.
