# Repo Report — superpowers (obra / Jesse Vincent)

> Authority boundary: This repository report is source/research evidence.
> Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology,
> dispatch, review mechanism, or capability behavior.
> Current design and execution authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.


> **Path:** `_research/upstreams/superpowers`
> **SHA:** `44c9b2d6e889982ac18c27d05a19fefe335194e1`
> **License:** MIT. `LICENSE:1-3` — "MIT License / Copyright (c) 2025 Jesse Vincent". Root file
> present; no per-file overrides found.
> **Size:** 180 tracked files (`git ls-files | wc -l`)
> **Read this pass:** all 14 `skills/*/SKILL.md` (frontmatter + body for
> `writing-skills`, `verification-before-completion`, `systematic-debugging`,
> `using-superpowers`, `requesting-code-review`, `dispatching-parallel-agents` head,
> `subagent-driven-development:100-280`); `writing-skills/anthropic-best-practices.md`
> (1,150 lines, full); `writing-skills/testing-skills-with-subagents.md` (full);
> `writing-skills/persuasion-principles.md` (full); all four
> `systematic-debugging/test-*.md` fixtures + `CREATION-LOG.md` (full);
> `hooks/hooks.json`, `hooks/session-start` (full);
> `tests/explicit-skill-requests/run-test.sh` (full) + one prompt fixture;
> `tests/claude-code/analyze-token-usage.py:1-40`.

## 1. What this repo is

A cross-harness **plugin collection of discipline skills** plus the methodology for
producing them. Its distinguishing thesis, which no other repo in the cluster holds, is that
a skill is a *behavioral intervention that must be empirically tested on agents*, not
documentation — "Writing skills IS Test-Driven Development applied to process documentation"
(`skills/writing-skills/SKILL.md:10`). The artifact is therefore two things at once: a
14-skill library, and a tested craft manual for authoring skills that survive pressure.

## 2. Mechanism inventory

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| S-1 | **Iron Law** | One all-caps prohibition in a code fence, stated once, as the skill's spine. Three instances: `NO SKILL WITHOUT A FAILING TEST FIRST`, `NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE`, `NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST` | `writing-skills/SKILL.md:374-378`; `verification-before-completion/SKILL.md:14-18`; `systematic-debugging/SKILL.md:14-18` | A |
| S-2 | **Gate Function** | Numbered pre-claim procedure with a terminal line that names the violation: "Skip any step = lying, not verifying" | `verification-before-completion/SKILL.md:22-36` | A |
| S-3 | **Rationalization table** | Two-column `Excuse \| Reality`, populated *from observed baseline failures*, not imagination | `verification-before-completion/SKILL.md:61-73`; `systematic-debugging/SKILL.md:244-255`; `writing-skills/SKILL.md:444-457` | A |
| S-4 | **Red Flags list** | Self-check trip-wires phrased as the agent's own inner monologue ("Using 'should', 'probably', 'seems to'"), closing with "ALL of these mean: …" | `verification-before-completion/SKILL.md:50-59`; `systematic-debugging/SKILL.md:214-231` | A |
| S-5 | **Spirit-vs-letter clause** | One line placed *early*, before the rules: "Violating the letter of this rule is violating the spirit of this rule." Cuts an entire rationalization class | `verification-before-completion/SKILL.md:12`; `systematic-debugging/SKILL.md:12`; rationale at `writing-skills/SKILL.md:506-514` | A |
| S-6 | **Loophole closure block** | After the rule, forbid the specific workarounds: "Don't keep it as 'reference' / Don't 'adapt' it / Don't look at it / Delete means delete" | `writing-skills/SKILL.md:494-503`; `test-driven-development/SKILL.md:37-43` | A |
| S-7 | **Description ≠ workflow (the load-bearing rule)** | Empirical finding that a workflow-summarizing description makes the agent follow the *summary* and skip the body. **Verified**: "A description saying 'code review between tasks' caused an agent to do ONE review, even though the skill's flowchart clearly showed TWO reviews (spec compliance then code quality)" | `writing-skills/SKILL.md:150-158`, with the corrected description quoted at `:156` and BAD/GOOD pairs at `:160-172` | A |
| S-8 | **Pressure fixtures** | Three graded scenario files + one academic control, checked into the skill dir. Format verified below | `systematic-debugging/test-pressure-1.md`, `-2.md`, `-3.md`, `test-academic.md` | A |
| S-9 | **Pressure taxonomy** | Named table of 7 pressure types (Time, Sunk cost, Authority, Economic, Exhaustion, Social, Pragmatic) with the rule "Best tests combine 3+ pressures" | `writing-skills/testing-skills-with-subagents.md:128-140` | A |
| S-10 | **Meta-testing** | After a failure, ask the agent *how the skill should have been written*; three canonical answer classes map to three distinct fixes | `testing-skills-with-subagents.md:240-266` | A |
| S-11 | **Match the Form to the Failure** | Four-row table mapping baseline failure type → right form → wrong form. Key claim: prohibitions *backfire* on output-shaping failures; the prohibition arm "trended worse than even the no-guidance control" | `writing-skills/SKILL.md:459-474` | A |
| S-12 | **Micro-test protocol** | 5-step wording test before full scenarios: one fresh-context sample per call, **mandatory no-guidance control**, 5+ reps, manual read of every flagged match, variance as a metric | `writing-skills/SKILL.md:575-585` | A |
| S-13 | **CREATION-LOG** | Per-skill record of extraction decisions, bulletproofing choices, test results, and iteration history. Names the single most effective element: the anti-patterns section | `systematic-debugging/CREATION-LOG.md:100-102` | A |
| S-14 | **Persuasion-principle mapping** | Cialdini's 7 principles mapped to skill types, with two explicitly banned (Reciprocity, Liking — "Creates sycophancy") and a per-skill-type combination table | `persuasion-principles.md:105-133` | A |
| S-15 | **SessionStart hook injects the meta-skill body** | Bash hook cats `using-superpowers/SKILL.md` and emits it as `additionalContext` wrapped in `<EXTREMELY_IMPORTANT>`; three per-platform JSON shapes | `hooks/session-start:10-47`; matcher `startup\|clear\|compact` at `hooks/hooks.json:5` | A |
| S-16 | **SUBAGENT-STOP marker** | The meta-skill's first line tells a dispatched subagent to ignore it — an explicit opt-out from the always-on skill | `using-superpowers/SKILL.md:6-8` | A |
| S-17 | **Trigger test harness** | `claude -p` per prompt fixture with isolated HOME; PASS requires the Skill tool invoked; separately detects **premature action** (non-Skill tool_use lines before the first Skill line) | `tests/explicit-skill-requests/run-test.sh:78-118` | A |
| S-18 | **No `@`-links between skills** | `@` force-loads immediately; cross-references use bare names with `**REQUIRED BACKGROUND:**` markers | `writing-skills/SKILL.md:278-288` | A |
| S-19 | **Token-efficiency word targets** | <150 words for always-loaded, <200 for frequently-loaded, <500 otherwise, verified with `wc -w` | `writing-skills/SKILL.md:213-266` | A |
| S-20 | **Per-subagent token accounting script** | Parses session transcripts into main-vs-subagent input/output/cache breakdown | `tests/claude-code/analyze-token-usage.py:12-40` | B |
| S-21 | **SDD ledger for compaction recovery** | "Conversation memory does not survive compaction… controllers that lost their place have re-dispatched entire completed task sequences — the single most expensive failure observed." Ledger's first line names its plan file; `Task <N>: complete` lines are the resume index | `subagent-driven-development/SKILL.md:117-140` | A |
| S-22 | **Hand artifacts as file paths, never as pasted text** | "Everything you paste into a dispatch prompt … stays resident in your context for the rest of the session and is re-read on every later turn." Real session cited: a dispatch hit 42k chars, 99% pasted history | `subagent-driven-development/SKILL.md:196-198`, `:221-225` | A |
| S-23 | **Model tiering with an anti-default clause** | "Always specify the model explicitly when dispatching a subagent. An omitted model inherits your session's model — often the most capable and most expensive — which silently defeats this section." Plus "Turn count beats token price" | `subagent-driven-development/SKILL.md:177-187` | A |

### Fixture formats, verified

**Pressure fixture** (`test-pressure-2.md`, 68 lines). Fixed five-part shape:

1. Title naming the pressures combined — `# Pressure Test 2: Sunk Cost + Exhaustion` (`:1`).
2. Reality-assertion preamble, verbatim across all three: "**IMPORTANT: This is a real
   scenario. You must choose and act. Don't ask hypothetical questions - make the actual
   decision.**" (`:3`).
3. Skill-availability line: "You have access to: skills/debugging/systematic-debugging" (`:5`).
4. `## Scenario` — concrete numbers, real file names, an attempt log. `-2.md:11-24` lists six
   already-tried fixes; `-1.md:9-13` gives `$15,000/minute` and `$75k lost`; `-3.md:8-30` is a
   scripted five-person dialogue where a senior engineer overrides the agent.
5. `## Your Options` — exactly three lettered options, each with its *costs spelled out
   including the social ones* ("You look like you don't trust experienced developers",
   `-3.md:51`), closing with "Choose A, B, or C" plus an honesty demand
   ("Be honest about what you would actually do", `-1.md:58`).

Note the design: option A is always the compliant-but-painful one, B is the tempting
violation, and C is the "balanced"/"pragmatic" hybrid — C exists specifically to catch the
compromise rationalization, which is the one agents reach for most.

**Academic control** (`test-academic.md`, 14 lines). No pressure at all. Six recall questions
("What are the four phases…", "Is it ever acceptable to skip the process for simple bugs?")
with the instruction "based SOLELY on what the skill says" and "Return your answers with
direct quotes" (`:5`, `:14`). This separates *comprehension* failure from *compliance*
failure — a distinction our trigger fixtures currently do not make.

**CREATION-LOG** (119 lines). Six sections: Source Material, Extraction Decisions
(include/leave-out), Structure, Bulletproofing Elements (Language Choices / Structural
Defenses / **Redundancy** — "'NEVER fix symptom' appears 4 times in different contexts",
`:52`), Testing Approach (4 named tests with one-line results), Iterations, Key Insight.

### The Iron Law line number

The task brief cited `~skills/writing-skills/SKILL.md:377` for "NO SKILL WITHOUT A FAILING
TEST FIRST". Exact location is `:377` inside the fence opened at `:376`, under the heading
`## The Iron Law (Same as TDD)` at `:374`. Verified.

## 3. Transferable to omp-custom

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| S-1 Iron Law | Body of each of our 3 shipped skills | lazy (already paid) | **ADOPT** | `evidence-before-completion` already encodes the idea; make the one-line fenced form explicit so the rule is greppable and unmissable |
| S-2 Gate Function | `evidence-before-completion` body | lazy / per-spawn via `autoloadSkills` | **ADOPT** | This is the exact anti-false-completion primitive. Numbered, terminal, ~90 tokens |
| S-3 + S-4 tables | Bodies of all 3 skills | lazy | **ADOPT** | Highest-density behavior change per token in the corpus. Cheap: a 8-row table ≈ 200 tokens |
| S-5 spirit-vs-letter | One line, near top of each discipline skill body | lazy | **ADOPT** | ~15 tokens; kills a whole rationalization class |
| S-7 description ≠ workflow | Every `description:` in `template/.omp/skills/*` | persistent (this *is* the listing) | **ADOPT** | Directly governs the 900-token listing budget. Also a correctness rule, not just a size rule |
| S-8 + S-9 pressure fixtures | `evals/triggers/<skill>.yml` per spec/11 §D, extended with a `pressure/` tier | zero (never enters a context) | **ADOPT** | The format is copy-ready. Our current spec/11 §D has one positive + one negative per skill and no pressure tier at all |
| S-10 meta-testing | Fixture-authoring procedure in spec/13 | zero | **ADAPT** | Free to write down; costs one extra model turn per failed fixture when actually run |
| S-11 Match the Form | `writing-skills`-equivalent guidance for *our* authors — as a doc, not a skill | zero | **ADOPT (as doc)** | We have exactly the failure it warns about: `diff-reviewer` output shape is a shaping problem, and a prohibition list there would backfire |
| S-12 micro-test + no-guidance control | spec/13 L3 procedure | zero to write; tokens per run | **ADOPT** | The mandatory control is the part we lack. "If the control doesn't exhibit the failure, there is nothing to fix — stop" prevents authoring skills for imagined failures |
| S-13 CREATION-LOG | One per shipped skill, beside `SKILL.md`, git-tracked | zero | **ADAPT** | Not read by any agent, so free. Makes `registry/skill-lock.yml`'s `reviewer:` field meaningful instead of `"initial-construction"` |
| S-16 SUBAGENT-STOP | N/A in OMP | — | **REJECT** | We have no always-on meta-skill; our equivalent lever is `autoloadSkills` per agent, which is already selective (spec/11 §B) |
| S-17 premature-action detection | spec/13 L3 harness | zero at runtime | **ADAPT** | The *check* transfers: "did a non-Skill tool fire before the skill was read". Their `claude -p` runner does not — OMP is the runtime |
| S-18 no `@`-links | Our skill bodies' cross-references | persistent-avoidance | **ADOPT** | Cheap discipline; we should never force-load one skill body from another |
| S-19 word targets | Per-skill budget in spec/11 | persistent + per-spawn | **ADAPT** | Their <150/<200/<500 *words* maps to our ≤500-*token* autoload budget. Same idea, different unit — state ours in tokens and stop translating |
| S-21 ledger for compaction | `orchestrated.md` coordinator contract | per-action (file writes) | **ADAPT** | We already have workflow state; the transferable part is *identity on the first line* and a resume rule that survives compaction. Not a skill |
| S-22 artifacts as paths | Worker dispatch contract in spec/03 | saves persistent tokens | **ADOPT** | Already partly our design; the "re-read on every later turn" justification is worth recording verbatim |
| S-23 explicit model per dispatch | spec/09 model routing | zero | **ADOPT** | The anti-default clause is the operative half and is one sentence |

Everything else — `hooks/`, `scripts/`, `tests/*.sh`, `brainstorming/scripts/server.cjs`,
`using-git-worktrees`, `sdd-workspace` — is harness. Out of scope by constraint (contract
anti-pattern 3), not by preference.

## 4. What this repo does that we deliberately will not

**Ship 14 skills.** At their mean description length of 133 chars (~33 tokens; measured over
all 14 frontmatters) a 14-skill listing is ~465 tokens — which would actually fit our
900-token budget. The reason to refuse is not size, it is that their library assumes a
main-session-only listing. Under OMP's verified multiplier the *same* listing is re-paid in
every subagent, and 9 of their 14 skills (`brainstorming`, `writing-plans`,
`executing-plans`, `using-git-worktrees`, `finishing-a-development-branch`,
`dispatching-parallel-agents`, `subagent-driven-development`, `requesting-code-review`,
`receiving-code-review`) describe *coordination*, which in our design lives in the workflow
template and worker contracts. A worker paying listing tokens for `finishing-a-development-branch`
gets nothing.

**`using-superpowers` as an always-injected meta-skill.** `hooks/session-start:11` cats a
62-line / 481-word body into every session, and `using-superpowers/SKILL.md:11` states "If
you think there is even a 1% chance a skill might apply … you ABSOLUTELY MUST invoke the
skill." That is a deliberate trade: ~600 tokens of persistent context plus a bias toward
loading *more* skill bodies. Our enemy is false completion, not under-triggering, and our
budget is the constraint. We buy the same effect for less by autoloading one body into the
two agents that make completion claims (spec/11 §B).

**`persuasion-principles.md` as a live reference.** Read in full; the mapping table
(`:126-133`) is genuinely useful *to a skill author*. But it is authoring theory, and the
N=28,000 compliance figure (`:8`) is a finding about *objectionable* request compliance being
doubled — a result about jailbreaking, cited here as support for imperative skill wording.
The inference is plausible and unmeasured on this use. We take the two operational
conclusions (authority+commitment for discipline skills; never Liking, it "Creates
sycophancy", `:117-124`) and leave the citation chain out of our spec.

**Flowcharts in `dot`.** `dispatching-parallel-agents/SKILL.md:17-33` and
`subagent-driven-development/SKILL.md:100-107` spend real tokens on graphviz source that an
agent reads as text. Their own rule says flowcharts are only for "Decision where I might go
wrong?" (`writing-skills/SKILL.md:292-314`). At our budget, a 4-row table is strictly
cheaper than a digraph with quoted node labels.

**`subagent-driven-development` at 503 lines / 4,072 words.** The single largest skill in the
cluster, and it is a coordinator runbook — model tiering, ledger protocol, workspace scripts,
fix-loop rounds, review dispatch. In our architecture that content is `commands/orchestrated.md`
and the worker contracts, where it is paid once by the main session rather than being
discoverable by a worker that must not perform coordination.

## 5. Contradictions with our current spec or registry

**None found that make a recorded claim false.** The three claims I could check all hold:

| Our claim | Evidence | Status |
|---|---|---|
| `spec/key/04-decision-log.md:595` — a description caused ONE review where the body specified TWO, citing `superpowers/skills/writing-skills/SKILL.md:154-156` | `writing-skills/SKILL.md:154` is the exact sentence; `:156` is the corrected description. The framing sentence begins at `:150` (`**CRITICAL: Description = When to Use, NOT What the Skill Does**`) and the BAD/GOOD block runs `:160-172` | **Confirmed.** Consider widening the citation to `:150-172` so the rule and its evidence travel together |
| `spec/key/04-decision-log.md:577` — ships `test-pressure-1/-2/-3` | All three exist under `skills/systematic-debugging/`, 58/68/69 lines | **Confirmed** |
| `spec/key/00-method.md:121` — SHA `44c9b2d`, "Skill packaging, debugging discipline, verification gates" | `git rev-parse HEAD` = `44c9b2d6e88…` | **Confirmed** |

Two **understatements** worth correcting in our records, neither of which invalidates a decision:

1. `spec/key/02-repo-synthesis.md:42` credits this repo with **2** adopted mechanisms
   ("skill bodies, coordinator acceptance check"). §3 above finds 13 ADOPT/ADAPT rows whose
   cost is zero or already-paid. The under-count is a cluster-report artifact: the dossier
   read `writing-skills` in full but never opened `anthropic-best-practices.md`,
   `testing-skills-with-subagents.md` in the same pass, or the fixtures as *formats*.
2. `spec/key/02-repo-synthesis.md:162` describes `hooks/hooks.json` as "a Claude Code
   `SessionStart` matcher". Accurate but incomplete: `hooks/hooks.json:9` invokes
   `run-hook.cmd`, and `hooks/session-start:38-47` emits **three different JSON shapes** keyed
   on `CURSOR_PLUGIN_ROOT` / `CLAUDE_PLUGIN_ROOT` / `COPILOT_CLI`, with the comment at `:33-34`
   explaining that Claude Code reads *both* `additional_context` and `hookSpecificOutput`
   without dedup. Irrelevant to us (we have no hook layer) but the record should not imply a
   single-platform mechanism.

## 6. Cost profile

| Adopted item | Tier | Cost | Basis |
|---|---|---|---|
| S-1 Iron Law | lazy | ~20 tokens inside an already-paid body | 3 fenced lines, measured on their instances |
| S-2 Gate Function | per-spawn (autoloaded into implementer + verifier) | ~90 tokens × 2 spawns = ~180/workflow | `verification-before-completion/SKILL.md:22-36` is 15 lines; estimate at ~6 tokens/line |
| S-3 rationalization table (8 rows) | lazy | ~200 tokens | Their 8-row table at `:61-73`; estimate |
| S-4 red flags (8 items) | lazy | ~120 tokens | Their `:50-59`; estimate |
| S-5 spirit-vs-letter | lazy | ~15 tokens | One sentence, counted |
| S-7 description rule | **persistent** | Changes nothing about size; it *constrains* the 900-token listing sum. Our current three descriptions measure 39/47/44 words — all already compliant with "no workflow summary"? **No**: `task-triage`'s "Guides clarification of requirements, scope definition, and workflow selection" is a workflow summary and is the one to fix | Measured from `template/.omp/skills/*/SKILL.md` frontmatter |
| S-8..S-13, S-17 fixtures/logs | **zero** | Never enters any context window. Repo-weight only | Files live in `evals/` and beside `SKILL.md`; no agent reads them at runtime |
| S-11 Match-the-Form doc | zero | Authoring-time doc | Not a skill; not listed |
| S-19 word→token budgets | persistent + per-spawn | No new cost; it is the accounting rule | — |
| S-22 artifacts-as-paths | **saves** persistent tokens | Their measured case: a dispatch of 42k chars, 99% pasted history (`subagent-driven-development/SKILL.md:224-225`) | A |
| S-23 explicit model | zero | One sentence in spec/09 | — |

Total *new* per-workflow cost of everything in §3 that touches a context: ~180 tokens
(S-2, ×2 spawns), inside the ≤1,000-token autoload budget already set at spec/11 §B. Every
other adopted row is either zero-cost or a reallocation inside a body we already pay for.

## 7. Coverage and limits (MANDATORY)

**Files read in full:**
`skills/writing-skills/SKILL.md` (679L) · `skills/writing-skills/anthropic-best-practices.md`
(1,150L) · `skills/writing-skills/testing-skills-with-subagents.md` (384L) ·
`skills/writing-skills/persuasion-principles.md` (187L) ·
`skills/verification-before-completion/SKILL.md` (120L) ·
`skills/systematic-debugging/SKILL.md` (283L) ·
`skills/systematic-debugging/{test-pressure-1,test-pressure-2,test-pressure-3,test-academic}.md` ·
`skills/systematic-debugging/CREATION-LOG.md` (119L) ·
`skills/using-superpowers/SKILL.md` (62L) · `skills/requesting-code-review/SKILL.md` (95L) ·
`hooks/hooks.json` · `hooks/session-start` (49L) ·
`tests/explicit-skill-requests/run-test.sh` · `tests/explicit-skill-requests/prompts/skip-formalities.txt` ·
`LICENSE:1-5`.

**Files sampled (head/grep/partial only):**
`skills/subagent-driven-development/SKILL.md` — read `:100-280` of 503; the flowchart head and
the fix-loop tail are unread · `skills/dispatching-parallel-agents/SKILL.md:1-60` of 167 ·
`skills/test-driven-development/SKILL.md` — frontmatter + `:31-43` (Iron Law) of 320 ·
all 14 skill frontmatters + line/word counts via script ·
`tests/claude-code/analyze-token-usage.py:1-40` of an unmeasured whole ·
grep for `When NOT`, `Don't use`, `instead use` across `skills/`.

**Not opened:**
`skills/brainstorming/` (SKILL.md 151L, `visual-companion.md` 298L, `scripts/server.cjs`,
`helper.js`, `frame-template.html`, `spec-document-reviewer-prompt.md`) ·
`skills/writing-plans/` · `skills/executing-plans/SKILL.md` ·
`skills/finishing-a-development-branch/SKILL.md` (201L) ·
`skills/receiving-code-review/SKILL.md` (205L) ·
`skills/using-git-worktrees/SKILL.md` (167L) ·
`skills/requesting-code-review/code-reviewer.md` (172L) ·
`skills/subagent-driven-development/{implementer-prompt,task-reviewer-prompt,re-review-prompt}.md`
and `scripts/{review-package,sdd-workspace,task-brief}` ·
`skills/systematic-debugging/{root-cause-tracing,defense-in-depth,condition-based-waiting}.md`
and `find-polluter.sh` · `skills/test-driven-development/writing-good-tests.md` (198L) ·
`skills/writing-skills/{graphviz-conventions.dot,render-graphs.js,examples/CLAUDE_MD_TESTING.md}` ·
`skills/using-superpowers/references/*` (4 files) ·
all 24 `docs/superpowers/plans/` and `docs/superpowers/specs/` files ·
`docs/testing.md`, `docs/porting-to-a-new-harness.md`, `docs/windows/polyglot-hooks.md` ·
all ~45 remaining `tests/` files · all plugin manifests
(`.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `.kimi-plugin/`, `.pi/`, `.opencode/`) ·
`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `README.md`, `RELEASE-NOTES.md`, `scripts/*`.

**Claims that need a live run before use:**
- S-11's head-to-head result ("the prohibition arm produced clearly more of the unwanted
  content … and trended worse than even the no-guidance control",
  `writing-skills/SKILL.md:470`) is reported without data, N, or a linked artifact. Their own
  text says "micro-test your own case rather than assuming". **Grade B, do not treat as A.**
- S-7's ONE-vs-TWO-review finding is reported prose, not a checked-in transcript. The rule it
  supports is cheap and independently sensible, but the *evidence* is B: no fixture, no log.
- S-12's "5+ reps" and "variance is a metric" thresholds are asserted, unsourced. Fine as a
  procedure, not as a calibrated number.
- S-19's word targets (<150/<200/<500) have no measurement behind them in this repo.

**Suspected but not verified:**
- I did not confirm that any pressure fixture is *executed* by anything. `tests/` contains
  `tests/systematic-debugging/test-find-polluter.sh` (a shell-script test) and
  `tests/explicit-skill-requests/` (trigger tests), but I found **no runner that consumes
  `test-pressure-*.md`**. They appear to be manual fixtures — a human pastes them into a
  subagent. If so, the "NO SKILL WITHOUT A FAILING TEST FIRST" Iron Law is enforced by
  discipline, not by CI. This is worth knowing before we cite them as an automated tier.
- `CREATION-LOG.md:57` references `skills/meta/testing-skills-with-subagents` and `:25`
  references `skill-creation/SKILL.md` — paths that do not exist at this SHA (the file is now
  `skills/writing-skills/testing-skills-with-subagents.md`). The log is stale, dated
  `2025-10-03` (`:118`). Suggests CREATION-LOGs are written once and not maintained; if we
  adopt S-13 we should decide whether ours are living or archival.
