# Repo Report — OpenSpec

> **Path:** `_research/upstreams/OpenSpec`
> **SHA:** `d57889664cab4f2f061d236ec3ff82a5578701bb` (`git -C OpenSpec rev-parse HEAD`)
> **License:** MIT. `LICENSE:1-3` — "MIT License / Copyright (c) 2024 OpenSpec Contributors".
> No conflicting in-file grant found in the files read; the `skills/*/SKILL.md` frontmatter
> carries `license: MIT` per-skill (e.g. `skills/openspec-propose/SKILL.md:5`), which agrees.
> **Size:** 1052 tracked files (`git ls-files | wc -l`)
> **Read this pass:** First actual read of this repo — the prior pass enumerated with
> `git ls-files` and opened nothing. Read in full: the validator, all three Zod schemas,
> validation constants, the requirement-text and spec-structure parsers, the `spec-driven`
> schema.yaml, all four artifact templates, and 4 of 12 SKILL.md files. Sampled the archive
> module, the parallel-merge plan, and one real change directory. See §7.

## 1. What this repo is

A TypeScript CLI (`openspec`) plus a methodology for change-scoped specification. Its
distinguishing idea is that specs are **deltas**: a change directory holds
`specs/<capability>/spec.md` written with `## ADDED / MODIFIED / REMOVED / RENAMED
Requirements` headers, and `archive` merges those deltas into a persistent
`openspec/specs/` tree. The artifact of interest to us is not the CLI but the **requirement
grammar and the validator that enforces it** — the only mechanically-checked prose-spec
linter in this cluster.

## 2. Mechanism inventory

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| 1 | Requirement grammar | `### Requirement: <name>` + body + one or more `#### Scenario:` with WHEN/THEN bullets. Level-4 header for scenarios is load-bearing | `schemas/spec-driven/schema.yaml:80-84`; `templates/spec.md:6-11` | A |
| 2 | SHALL/MUST detection | One regex, `/\b(SHALL\|MUST)\b/`, shared by every code path so all readers accept/reject identical text | `src/core/parsers/requirement-text.ts:36-38` | A |
| 3 | **Keyword must be in the BODY, not the header** | A `SHALL` appearing only in `### Requirement: The system SHALL…` is a finding; the message tells the author to move it to the line after the header | `validator.ts:747-758`; rationale `requirement-text.ts:84-86` | A |
| 4 | SHALL/MUST is a WARNING, not an ERROR | Missing keyword in a non-empty body = `WARNING` "(RFC 2119 best practice)". Missing *body* = `ERROR` | `validator.ts:250-260, 623-633, 752-753` | A |
| 5 | Strict mode = promote warnings | `strictMode` changes only the verdict function: `errors===0 && warnings===0` vs `errors===0`. So SHALL enforcement is opt-in per invocation | `validator.ts:704-706` | A |
| 6 | ≥1 scenario per requirement, enforced twice | Zod `min(1)` on the array, plus an imperative ERROR on ADDED/MODIFIED delta blocks | `base.schema.ts:17-18`; `validator.ts:261-264, 296-299` | A |
| 7 | Fence-aware counting | `#### Scenario:` inside a fenced code block does not count — a mask is built over the lines first | `requirement-text.ts:93-101`; `code-fence.ts` (via `buildCodeFenceMask`) | A |
| 8 | Scenario-loss check (`MODIFIED` replaces the whole block) | Compares a MODIFIED block against the live main spec and ERRORs listing scenarios the delta would silently drop. **Multiplicity-aware** (N present, M incoming ⇒ max(0,N−M) missing) | `validator.ts:467-551`; `requirement-blocks.ts:341-363` | A |
| 9 | Rename-chain walking | Follows `A→B→C` rename chains with a visited-set cycle guard before comparing scenarios | `validator.ts:515-525` | A |
| 10 | Cross-section contradiction checks | Same requirement in ADDED+REMOVED, MODIFIED+REMOVED, MODIFIED+ADDED, RENAMED+REMOVED (case/whitespace-folded) all ERROR | `validator.ts:350-387` | A |
| 11 | Duplicate-name detection | Within a delta section, and within a main spec's `## Requirements` — "names must be unique so spec updates cannot discard one block while updating another" | `validator.ts:236-240`; `spec-structure.ts:76-89` | A |
| 12 | Structural placement checks | Delta header in a main spec = ERROR; `### Requirement:` outside the `## Requirements` section = ERROR ("invisible to validate, list, and archive") | `spec-structure.ts:41-72` | A |
| 13 | Layout trap: `specs/spec.md` at root | A delta at the `specs/` root has no capability folder, so the merge silently drops it. Now an explicit ERROR | `validator.ts:174-184` | A |
| 14 | Numeric thresholds | Why ≥50 and ≤1000 chars; requirement text >500 chars = INFO; >10 deltas per change = a splitting hint | `validation/constants.ts:6-12` | A |
| 15 | `skip_specs: true` escape hatch | A change with zero deltas is an ERROR *unless* `.openspec.yaml` declares `skip_specs`. Marker + files present = conflict ERROR (fails closed on unreadable dir) | `validator.ts:416-451`; `constants.ts:29-34` | A |
| 16 | "Do not invent a requirement to satisfy validation" | Explicit anti-gaming instruction paired with the escape hatch | `schema.yaml:26-30`; `templates/proposal.md:21-24` | A |
| 17 | Non-canonical headers surface as INFO | A stray `### Documentation Requirements` the reader skipped is reported, not silently ignored — it would pass `validate <change>` but fail archive | `validator.ts:202-212` | A |
| 18 | Artifact DAG with `requires` edges | `proposal → {specs, design} → tasks`; `apply.requires: [tasks]`. Declarative, in YAML | `schema.yaml:36, 128-129, 163-164, 201-206` | A |
| 19 | Completion = file existence, nothing more | `detectCompleted` globs for the artifact's `generates` pattern. That is the entire state machine | `artifact-graph/state.ts:14-37` | A |
| 20 | The DAG's own failure mode, documented | "`status` is file-existence only, so an `applyRequires` artifact reading `done` does NOT mean its dependencies exist." Walk `requires` edges, not `status` | `skills/openspec-propose/SKILL.md:107` | A |
| 21 | "Dependencies are enablers, not gates" | If a required artifact is `blocked` only because a *conditional* dependency was skipped, write it anyway | `skills/openspec-propose/SKILL.md:111` | A |
| 22 | Planning boundary | "The user request that selected this workflow authorizes planning only, **even if it asks to build or fix something**." Does not carry forward | `skills/openspec-propose/SKILL.md:14, 143` | A |
| 23 | `Using change: <name>` announcement | Every change-scoped skill must announce the resolved target and how to override | `apply-change/SKILL.md:27`; `verify-change/SKILL.md:31`; `update-change/SKILL.md:37` | A |
| 24 | Disambiguation ladder | explicit arg → infer from conversation → auto-select if exactly one → else `list --json` and ask. "If vague or ambiguous you MUST prompt" | `apply-change/SKILL.md:16, 20-26` | A |
| 25 | Divergence: bidirectional reconciliation | "an edit to a later artifact may require revising an earlier one… Build order is a useful reading order, not a constraint on which artifacts may be revised" | `update-change/SKILL.md:59` | A |
| 26 | Update vs. start-fresh heuristic | If the request changes the change's *intent* rather than refining it, start a new change instead of editing | `update-change/SKILL.md:90` | A |
| 27 | Frontier discipline | `update-change` may revise only files in `existingOutputPaths`; creating new artifacts is a different command's job | `update-change/SKILL.md:61, 88` | A |
| 28 | Confirm-before-write, per artifact | "Show each proposed revision and why. Write only after the user confirms." | `update-change/SKILL.md:65-66` | A |
| 29 | Re-read dependencies from disk | "always re-read them from disk, even if you saw them earlier in the conversation (the user may have edited them)" | `propose/SKILL.md:98, 145` | A |
| 30 | 3-axis verification | Completeness / Correctness / Coherence, each × CRITICAL/WARNING/SUGGESTION | `verify-change/SKILL.md:50-57` | A |
| 31 | False-positive bias rule | "When uncertain, prefer SUGGESTION over WARNING, WARNING over CRITICAL" | `verify-change/SKILL.md:157` | A |
| 32 | Graceful degradation by artifact set | tasks only ⇒ task check; +specs ⇒ +correctness; full ⇒ all three. Always state what was skipped | `verify-change/SKILL.md:160-165` | A |
| 33 | "context and rules are constraints for YOU, not content for the file" | Prevents the instruction text leaking into the artifact | `propose/SKILL.md:137-140` | A |
| 34 | Spec/design boundary test | "if the implementation can change without changing externally visible behavior, it likely does not belong in the spec" | `schema.yaml:59-60` | A |
| 35 | Explicit no-mechanism list for specs | Avoid: internal class/function names, library choices, step-by-step implementation, execution plans | `schema.yaml:53-57` | A |
| 36 | Conditional `design.md` | Four named triggers (cross-cutting, new dependency, security/perf/migration, ambiguity); otherwise skip | `schema.yaml:137-142` | A |
| 37 | Open Questions must be genuinely deferrable | "If a question would change the specs, the approach, or the task breakdown, resolve it now — ask the user instead of guessing" | `schema.yaml:150-155` | A |
| 38 | Anti-restatement rule | If a design section would only restate the proposal or specs, point at them instead | `schema.yaml:145, 158-160` | A |
| 39 | Task grammar | `- [ ] X.Y description` under `## N.` headings. "The apply phase parses checkbox format… Tasks not using `- [ ]` won't be tracked" | `schema.yaml:177-184`; `templates/tasks.md:1-9` | A |
| 40 | Task ordering = dependency order, informally | "Order tasks by dependency (what must be done first?)" — prose only, no notation | `schema.yaml:184` | A |
| 41 | **No parallel marker anywhere** | A grep for "parallel" across `skills/ schemas/ src/` returns only a bulk-archive description and two unrelated code comments | grep over `skills schemas src`, 3 hits, none a task marker | A |
| 42 | Stacking metadata (proposed, unshipped) | `dependsOn` / `provides` / `requires` / `touches` / `parent`; `dependsOn` is the ordering source of truth and `provides`/`requires` explicitly do **not** create implicit edges | `openspec/changes/add-change-stacking-awareness/proposal.md:19-31` | B |
| 43 | Parallel-archive data loss, self-documented | Two changes editing one requirement: the second archive replaces the block and silently drops the first's scenario. "No warning, diff, or conflict indicator" | `openspec-parallel-merge-plan.md:3-14` | B |
| 44 | Explore mode as a *stance* | "This is a stance, not a workflow. There are no fixed steps, no required sequence, no mandatory outputs." Read/search allowed, writing code forbidden | `skills/openspec-explore/SKILL.md:12, 14` | A |
| 45 | Interactive/bulk validate | `--strict`, `--json`, `--concurrency`, `--all`, interactive selector | `src/commands/validate.ts:24, 55, 62, 265-275` | B |

## 3. Transferable to omp-custom

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| #3 keyword-in-body-not-header | Coordinator's criteria-writing rule; verifier check | `zero` (rule text already budgeted) | **ADOPT** | The single highest-value line in this repo for us. Our rule "one SHALL" is satisfiable by a *title*, which is exactly the loophole they closed. One clause: the SHALL must be in the criterion sentence, not its label. |
| #7 fence-aware counting | Any check we write over a mini-spec | `zero` | **ADOPT** | Prevents a criterion in a fenced example from counting as real. We put code blocks in mini-specs constantly. |
| #8 scenario-loss / multiplicity-aware drift | diff-reviewer prose rule | `per-action` (diff-reviewer only) | **ADAPT** | Their code compares a delta against a live spec — we have no spec tree (rejected). Extract the *craft*: when an edit replaces a block wholesale, enumerate what the old block asserted and confirm each survives. Set membership is not enough. |
| #14 numeric thresholds | Mini-spec authoring rule | `zero` | **ADAPT** | Take only ">500 chars ⇒ probably two criteria" as a splitting heuristic. The 50-char `Why` minimum is character-count theatre; skip it. |
| #15 + #16 `skip_specs` + anti-gaming | `/quick` and `/standard` triage | `zero` | **ADOPT** | We need the pair: an explicit "this change has no acceptance criteria" declaration, *and* the instruction not to invent one to satisfy the gate. Without the escape hatch the rule gets gamed; without the anti-gaming line the hatch gets over-used. |
| #20 file-existence ≠ satisfied | Coordinator dispatch check | `zero` | **ADOPT** | Directly applicable: an implementer reporting "done" is a file-existence-grade signal. Verify against criteria, not against the report. |
| #22 planning boundary non-carry-forward | `/standard`, `/orchestrated` preamble | `zero` | **ADOPT** | Sharp and cheap. "Plan this" containing "and fix it" does not authorize the fix. We dispatch on the coordinator's reading of intent, so this closes a real scope leak. |
| #23 + #24 announce + disambiguation ladder | Coordinator, when >1 unit is open | `zero` | **ADAPT** | Take the ladder (explicit → infer → auto-select-if-one → else ask) and the announcement. Drop the CLI status call. |
| #25 bidirectional reconciliation | Divergence handling mid-implementation | `zero` | **ADOPT** | Answers the artifact-lifecycle question. When an implementer discovers the mini-spec is wrong, the fix may be *upstream*. Build order is reading order, not edit order. |
| #26 update-vs-start-fresh | Coordinator, on scope change | `zero` | **ADOPT** | Cheap decision rule that prevents a mini-spec mutating into something nobody agreed to. Refine ⇒ edit; intent change ⇒ new unit. |
| #29 re-read from disk | All 4 worker agents | `per-spawn` (one line each) | **ADOPT** | We fan out parallel implementers; stale conversation-memory reads are a live failure mode for us specifically. |
| #31 false-positive bias | verifier, diff-reviewer | `zero` | **ADOPT** | A verifier that inflates severity gets ignored, which costs a whole review cycle. One clause. |
| #32 graceful degradation + state what you skipped | verifier | `zero` | **ADOPT** | Matches the contract's own rule 3. Already our house style; make it the verifier's explicit output requirement. |
| #33 constraints-not-content | Worker agent prompts | `zero` | **ADOPT** | We pass criteria into subagents; without this they get echoed into the deliverable. |
| #34 + #35 implementation-change test, no-mechanism list | Criteria-writing rule | `zero` | **ADOPT** | #34 is a *test* for our existing "no mechanism" rule, which currently states the rule without giving a way to apply it. #35 is the concrete list. |
| #36 conditional design doc | `/standard` vs `/orchestrated` routing | `zero` | **ADAPT** | Reuse the four triggers as our escalation predicate. We have no `design.md`; the triggers still decide whether a unit needs a plan step. |
| #37 open-questions discipline | Triage cap (already adopted) | `zero` | **ADOPT** | Tightens the adopted 5-question cap: a question that would change scope/approach/decomposition must be asked *now*, not deferred. Turns the cap into a filter instead of an excuse. |
| #38 anti-restatement | Coordinator's mini-spec | `zero` | **ADOPT** | Directly serves tokens-per-accepted-outcome. Point, don't restate. |
| #41 + #43 no parallel marker + archive data loss | Our parallelization rule | `zero` (negative finding) | **ADOPT as evidence** | See §4/§5. Their omission plus their documented corruption is the strongest available support for our hard rule. |
| #44 explore-as-stance | explorer agent | `zero` | **ADOPT** | "No fixed steps, no mandatory outputs" is the right frame for an explorer. A step-numbered explorer wastes tokens producing structure nobody consumes. |
| #42 `dependsOn` vs `provides`/`requires` | — | — | **DEFER** | Trigger: if we ever run >1 concurrent *unit* (not >1 implementer within a unit). The precise lesson worth keeping: capability markers must **not** create implicit dependency edges — declared ordering only. Inferred edges are how you get a cycle you cannot see. |
| #45 CLI validate surface | — | — | **REJECT** | CLI-dependent by construction. |
| #1 delta grammar / #18 artifact DAG / #19 file-existence state | — | — | **REJECT** | Requires the `specs/` tree we already rejected, plus a CLI to walk the DAG. |

## 4. What this repo does that we deliberately will not

**A separate `specs/` document tree with delta merge.** Already rejected; this repo prices
the rejection precisely. The delta language is why `archive.ts` needs SHA-256 directory
fingerprinting (`archive.ts:349-430`), a rename-chain walker, a multiplicity-aware
scenario-loss comparator, and a root-level-file trap check. That machinery is not
incidental complexity — it is the *minimum* needed to keep a delta language from losing
data, and it only exists because the tree exists. Our mini-spec is consumed within the
session that wrote it and never merged, so we inherit none of it.

**Four documents before code.** `proposal → specs → design → tasks`, all four in
`apply.requires`' transitive closure (`schema.yaml:201-206`), and `openspec-propose`
instructs the agent to create "every artifact the apply phase transitively depends on"
(`propose/SKILL.md:144`). At the pinned commit `design.md` is the only conditional one
(#36). Three mandatory documents before the first line of code fails our objective
function outright for `/quick`, and probably for `/standard`.

**Per-invocation strict mode.** Making SHALL enforcement a `--strict` flag (#5) means the
default run accepts a requirement with no normative keyword. A quality rule that is off by
default is a rule the mainline never applies. If we adopt SHALL, it is unconditional; we
have no flag surface and should not invent one.

**The CLI-coupling tax in the prose.** Every one of the 12 SKILL.md files opens with the
same ~200-word "Store selection" paragraph — byte-identical across files (compare
`propose/SKILL.md:28`, `apply-change/SKILL.md:14`, `verify-change/SKILL.md:14`,
`update-change/SKILL.md:14`). 2,548 lines of skill prose total, and the largest
(`onboard`, 560 lines) is pure CLI orchestration. This is what "extract prose rules, not
the tool" costs when you skip the extraction: the good craft rules in §3 are buried in
per-file boilerplate about a flag we will never pass.

**`AGENTS.md` as a live document.** Theirs is 0 bytes (`ls -la AGENTS.md`). We adopted the
constitution pattern into `AGENTS.md`; this repo is a reminder that the pattern's value is
entirely in the content, and that a checked-in empty file reads as adoption to anyone
grepping for it. Not a criticism of our decision — a caution about how it is verified.

## 5. Contradictions with our current spec or registry

**1. "OpenSpec has a task-parallelism model" — if recorded anywhere, it is false.**
There is no `[P]` marker, no parallel notation, and no concurrency concept in the task
format. `schema.yaml:184` orders tasks by dependency in prose only; `templates/tasks.md`
has no marker column. A grep for `parallel` across `skills/ schemas/ src/` returns three
hits, none of them a task marker. If any recorded claim attributes parallel-task machinery
to OpenSpec, the claim belongs to spec-kit, not here.

**2. Our hard rule on parallelization is *supported*, not contradicted — and the support
is stronger than a design argument.** Our rule: two units with a real dependency were not
independent and must not have been parallelized. OpenSpec permits parallel *changes*
without expressing dependencies between them, and its own repo documents the result:

> "After Change A archives, the main spec contains both scenarios… When Change B archives,
> `buildUpdatedSpec` sees a `MODIFIED` block… the Windsurf scenario disappears. There is
> no warning, diff, or conflict indicator" — `openspec-parallel-merge-plan.md:9-14`

That is silent data loss caused by parallelizing work with an undeclared shared
dependency. Their remediation is partial at the pinned commit: the scenario-loss ERROR
(#8) ships and is wired into authoring-time validation (`validator.ts:302-320`), and
`archive.ts` fingerprints directories — but the plan's Phase 0 item 1, per-requirement
base fingerprints stored in change metadata, does not appear in `src/` (grep for
`fingerprint|baseHash` finds hits only in `archive.ts`, all directory-level). Their own
proposed fix for cross-change dependencies (#42) is likewise an unshipped proposal in
`openspec/changes/`. Grade B on "unshipped" — inferred from grep plus the fact that the
proposal still sits in `changes/` rather than `archive/`; a live run would confirm.

**3. Anything claiming OpenSpec validates that a criterion is *observable* or
*mechanism-free* is overstated.** The validator checks: non-empty body, SHALL/MUST as a
whole word, ≥1 level-4 scenario, uniqueness, section placement, and cross-section
contradictions. Observability and mechanism-freedom appear only as prose instruction
(`schema.yaml:47-60`) with **no check behind them**. This is the honest answer to the
contract's question about what is mechanically checkable in a prose document: *presence,
placement, uniqueness, and keyword* are checkable. *Falsifiability is not.* Any claim that
a validator can enforce our four-part criterion rule is wrong, and this repo — the most
serious attempt in the cluster — is the evidence.

**4. `MAX_DELTAS_PER_CHANGE = 10` is a hard Zod `.max()`, not advice.** The message reads
"Consider splitting changes with more than 10 deltas" (`constants.ts:35`) but it is
attached to `.max()` on the array (`change.schema.ts:32`), so it fails as an ERROR via
`convertZodErrors`. If anything records this as a soft warning, that is wrong. Minor, but
it is exactly the class of inherited-wrong-constraint the contract warns about.

## 6. Cost profile

Everything in §3 marked ADOPT/ADAPT is prose. Nothing requires a runtime consumer, which is
the §4-rule-4 filter passing.

- **`zero` (rules absorbed into text we already write):** #15/#16, #20, #22, #25, #26, #34,
  #35, #37, #38, #41-as-evidence. These land in the coordinator's mini-spec instructions and
  the command preambles — files that already exist and are already in context when relevant.
  The marginal cost is the added sentences themselves.
- **Criteria-craft cluster (#3, #7, #14, #34, #35):** estimate **~10-14 lines** of rule text
  total, in one place (wherever the criterion rule already lives). Basis: #3 is one clause,
  #7 one clause, #34 one sentence, #35 a four-item list, #14 one heuristic. Paid wherever
  the existing criterion rule is paid — no new file, no new load path.
- **`per-spawn` (#29 re-read from disk, #33 constraints-not-content):** one line each in the
  4 worker agent prompts ⇒ estimate **~8 lines × 4 agents**. This is the only recommendation
  here that multiplies by spawn count, and it is the one our parallel-implementer design most
  needs. Note the known skill-listing multiplier already recorded in memory: every subagent
  pays for the full listing, so worker-prompt additions are the expensive tier and should stay
  at one line each.
- **`per-action` (#8-as-craft):** diff-reviewer only, on invocations that touch a
  wholesale-replaced block. Estimate ~3 lines of rule; runs only when the diff-reviewer runs.
- **`zero` and reversible (#31, #32, #44):** verifier and explorer prompt clauses.
- **REJECTs cost nothing and save the CLI dependency.**

No number above is measured. All are line-count estimates from the rule text drafted while
reading; none has been written into a file, so none has been token-counted.

## 7. Coverage and limits

**Files read in full:**
- `src/core/validation/validator.ts` (773 lines — the central artifact)
- `src/core/validation/constants.ts`, `src/core/schemas/base.schema.ts`,
  `src/core/schemas/spec.schema.ts`, `src/core/schemas/change.schema.ts`
- `src/core/parsers/requirement-text.ts`, `src/core/parsers/spec-structure.ts`
- `src/core/artifact-graph/state.ts`
- `schemas/spec-driven/schema.yaml` (211 lines) and all four templates
  (`proposal.md`, `spec.md`, `design.md`, `tasks.md`)
- `skills/openspec-propose/SKILL.md`, `openspec-apply-change/SKILL.md`,
  `openspec-verify-change/SKILL.md`, `openspec-update-change/SKILL.md`
- `LICENSE` (head)

**Files sampled (head/grep only):**
- `src/core/archive.ts` — grepped for fingerprint/hash and `buildUpdatedSpec`; the ~1500-line
  merge implementation is **not** read
- `src/core/parsers/requirement-blocks.ts` — read `findMissingCurrentScenarios` (341-363) only
- `src/commands/validate.ts` — grepped for flags
- `skills/openspec-explore/SKILL.md` — first 40 lines
- `openspec-parallel-merge-plan.md` — first 40 lines
- `openspec/changes/add-change-stacking-awareness/{proposal,tasks}.md` — heads
- `AGENTS.md` — confirmed 0 bytes

**Not opened:** 8 of 12 SKILL.md files (`onboard` 560 lines, `bulk-archive-change` 338,
`sync-specs` 261, `ff-change`, `continue-change`, `new-change`, `archive-change`, plus the
rest of `explore`); all 138 files under `test/`; all 34 under `website/`; all 26 under
`docs/`; ~170 of 183 `src/` files including the entire `command-generation/` adapter set
(26 adapters), `completions/`, `store/`, `worksets/`, `telemetry/`, `init.ts`,
`migration.ts`, `markdown-parser.ts`, `change-parser.ts`, `code-fence.ts`; 459 of 460 files
under `openspec/changes/`; all of `openspec/initiatives/`, `openspec/work/`,
`openspec/specs/`, `openspec/explorations/`; `CHANGELOG.md`; `README.md`; `README_OLD.md`;
`MAINTAINERS.md`; the 9 `scripts/`; `.github/`.

**Claims that need a live run before use:**
- Whether `validate --strict` fails on a missing SHALL in practice. Traced through
  `createReport` (`validator.ts:704-706`) and believed correct, but never executed.
- The exact ERROR-vs-WARNING split as *experienced*. I read the level assignments directly,
  so the levels are grade A, but I did not run the binary to see aggregate behavior.
- `buildCodeFenceMask`'s handling of tildes, indented fences, and unclosed fences. I relied
  on its callers' comments and never opened `code-fence.ts`. The fence-aware claims (#7) are
  A for *intent* and B for *edge-case behavior*.

**Anything I suspect but could not verify:**
- That the stacking-metadata proposal (#42) is unshipped. Inferred from grep plus its
  presence in `changes/` rather than `archive/`. Graded B; I did not read
  `change-metadata/schema.ts` to confirm the fields are absent.
- That per-requirement base fingerprints (the parallel-merge plan's Phase 0 item 1) never
  shipped. All `fingerprint` hits in `src/` are directory-level in `archive.ts`, but I did
  not read `archive.ts` in full, so a differently-named implementation could exist.
- That the ~200-word "Store selection" paragraph is byte-identical across all 12 skills. I
  compared 4 of them and they matched exactly; the other 8 are unread.
- Whether `test/` contains a criteria-quality test suite that would upgrade any §2 row from
  B to A, or reveal enforcement I did not find in `src/`. 138 unread files is the largest
  gap in this report.
