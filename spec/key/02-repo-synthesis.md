# 02 — Repo Synthesis

> Per-repository verdicts. What each upstream actually contributes to omp-custom, in one
> place, after running each through the six questions in `00-method.md §C`.
>
> **Grades** per `00-method.md §B`: **A** = OMP source-verified, **B** = upstream-verified
> at the pinned SHA, **C** = reasoned design judgment, **D** = needs a live experiment.
> Citations are `repo@sha:path`. Claims I did **not** re-read this pass are tagged
> `[registry-carried]` and are not asserted as B.
>
> This file is the evidence layer under `04-decision-log.md`. Where it proposes something
> new, §G lists it as an actionable delta — nothing here silently changes a decision.

---

## A. The filter, restated

Question 4 of the method — *which OMP primitive carries this?* — is the only question that
eliminates candidates. Everything else is analysis. Applied across seventeen repositories,
it sorts them into four outcomes:

| Outcome | Meaning | Count |
|---|---|---|
| **Runtime authority** | Defines what is true; every grade-A claim traces here | 1 |
| **Mechanism source** | Contributes a behavior that attaches to a named OMP primitive | 11 |
| **Negative control** | Contributes a priced counter-example | 1 |
| **Conditional** | Evaluated, not integrated in v0; a named trigger would revisit | 3 |
| **Principle only** | Contributes wording or a bar, no mechanism | 1 |

The eleven mechanism sources contribute **nine** new behaviors the current spec does not
already have — SD-2..SD-9 and SD-11. Everything else is confirmation of decisions already
recorded, which is the outcome to expect from a corpus that has been through six review
rounds. §G carries twelve deltas rather than nine because three of them (SD-1, SD-10, SD-12)
correct registry *facts* rather than adding a behavior; they attach to governance, not to an
OMP primitive.

### Summary verdict table

| Repo | Pinned | Role | Attaches to | Net new this pass |
|---|---|---|---|---|
| `oh-my-pi` | `3a8591a` | Runtime authority | — (it *is* the runtime) | See `dossiers/oh-my-pi.md` |
| `superpowers` | `44c9b2d` | Mechanism | skill bodies, coordinator acceptance check | **2** |
| `agent-skills` | `d2478bf` | Mechanism | reviewer prompt, eval fixtures, security gate | **3** |
| `spec-kit` | `81d5cdb` | Mechanism | `task-triage` skill body | **1** |
| `OpenSpec` | `d578896` | Mechanism | acceptance-criteria authoring rule in commands | **1** |
| `promptfoo` | `1c30e18` | Mechanism | `evals/` assertion vocabulary | **1** |
| `anthropics/skills` | `b29e7cf` | Mechanism | SKILL.md frontmatter shape | 0 (+ registry correction) |
| `aider` | `5dc9490` | Mechanism | Explorer contract | **1** |
| `mini-swe-agent` | `a83fcae` | Mechanism | termination-condition set | 0 (confirms KD-011) |
| `12-factor-agents` | `d20c728` | Mechanism | `output:` schema shape | 0 (already reflected) |
| `Agent-Skills-…-Context-Engineering` | `a1841d1` | Mechanism | topology + objective-function rationale | 0 (corroborates) |
| `agents.md` | `d1ac7f0` | Mechanism | `AGENTS.md` project section | 0 |
| `andrej-karpathy-skills` | `2c60614` | Principle only | `AGENTS.md` constitution | 0 |
| `ECC` | `9aac858` | **Negative control** | nothing — it prices the persistent tier | 0 (cited as anti-pattern) |
| `serena` | `c7af2c0` | Conditional | — | 0 |
| `repomix` | `a27ecec` | Conditional | — | 0 |
| `context7` | `8d52608` | Conditional | retrieval order position 4 | 0 |

---

## B. `oh-my-pi` — the only runtime authority

Everything that decides a question lives here. The verdict is not "adopt": OMP is not
adopted, it is the substrate. `dossiers/oh-my-pi.md` carries the discovery surface,
frontmatter contract, task wire format, schema enforcement path, and the twelve
corrections to spec claims that source reading produced.

One thing belongs in this file rather than the dossier, because it is a *synthesis*
finding: **the repository's own registry entry for OMP watches the wrong paths.**

`registry/upstreams.yml` records for `oh-my-pi`:

```yaml
watched_paths:
  - docs/config-usage.md
  - docs/context-files.md
  - docs/skills.md
  - docs/task-agent-discovery.md
  - docs/compaction.md
  - docs/settings.md
update_policy: watch-docs-only
tier: A-runtime
```

`spec/14 §B` records thirteen paths under `packages/coding-agent/src/**` and
`update_policy: manual-review-only`, `tier: runtime-authority`.

These are not two views of the same thing. **Every grade-A claim in this project comes
from `packages/**` source, and none comes from `docs/**`.** Watching only docs means a
change to `parseAgentFields`, `resolveSpawnPolicy`, `mustReject`, or any default in
`settings-schema.ts` produces no signal at all — the exact silent-drift failure `spec/14`
exists to prevent. The registry is the machine-readable artifact and `spec/key` defers to
it on facts (`README.md`), so this is a defect in the authoritative file, not a
documentation nit.

**Delta SD-1 (§G).** Replace the registry's `watched_paths` with the `spec/14 §B` list,
set `update_policy: manual-review-only`, and reconcile the tier name. Add the four paths
the dossier established this pass: `task/spawn-policy.ts`, `task/parallel.ts`,
`task/read-only-policy.ts`, `extensibility/hooks/loader.ts`.

---

## C. Methodology sources

### C-1. `superpowers` — verification discipline, and skills-as-TDD

**Problem shared.** An agent claims completion without evidence. Same problem the entire
template exists to solve.

**Mechanism (B).** `superpowers@44c9b2d:skills/verification-before-completion/SKILL.md`
states an Iron Law — *no completion claims without fresh verification evidence* — and
then does the thing most such documents omit: it supplies a **five-step gate function**
(identify the command → run it fresh and complete → read full output and exit code →
check the output actually confirms the claim → only then claim) and a failure table
mapping each claim type to what proves it.

Our `evidence-before-completion` skill already carries the Iron Law. Two rows of that
table are not reflected anywhere in the spec:

| Claim | What it requires | Not sufficient |
|---|---|---|
| Regression test works | Red-green cycle verified | Test passes once |
| **Agent completed** | **VCS diff shows changes** | **Agent reports "success"** |

The second row is a coordinator rule, not a worker rule, and it is directly actionable in
OMP: a spawn returns `patchPath` / `branchName` / `branchBaseSha`
(`task/types.ts:471-539`, grade A). So "did the worker actually change anything" is
checkable from the result object without trusting a word of the worker's prose. Under
capture-first isolation (`spec/08 §E-7`) this is *free* — the artifact path is already in
the result the Tech Lead reads.

**Delta SD-2.** Add to the Tech Lead acceptance check in all three command files: a
`status: completed` result whose `patchPath`/`branchName` is absent, or whose diff is
empty, is not a completion. Attaches to command prose (lazy tier). This closes **one** of
the false-completion channels schema validation structurally cannot catch — a worker can
emit a perfectly schema-valid completion having edited nothing.

It does **not** close the general case, and must not be described as doing so (CR-35). The
check is runtime-grounded because `patchPath` is written by OMP, not by the worker; but its
question is only "did anything change". A worker that *did* edit files and then fabricated
its verification evidence passes this check and every schema check — `buildOutputValidator()`
does no tool-event correlation. See `01-dna.md` L3 for the three-layer shape/independence/
provenance boundary; provenance has no v0 mechanism.

**Mechanism 2 (B).** `superpowers@44c9b2d:skills/writing-skills/SKILL.md` frames skill
authoring as TDD: run the pressure scenario **before** writing the skill, record the exact
rationalizations the agent produces, write the skill against those specific violations,
then verify compliance. Its core line — *"if you didn't watch an agent fail without the
skill, you don't know if the skill teaches the right thing"* — is the missing half of
`spec/11 §D`, which specifies trigger fixtures but no baseline arm.

**Delta SD-3.** `spec/11 §D` trigger fixtures gain a required baseline: for each of the
three skills, record the no-skill behavior on the positive prompt before the skill body is
finalized. This is an L3 arm (`spec/13`), and it is the same A/B machinery `spec/13 §C`
already requires for `autoloadSkills` on-vs-off — so the cost is a fixture, not
infrastructure. **Decided as KD-017**, which pairs this baseline arm with the *pressure*
fixtures that test whether a loaded skill holds when the model has a reason to skip it —
the failure mode an activation fixture cannot see.

**Rejected, unchanged.** SDD orchestration, `dispatching-parallel-agents`,
`finishing-a-development-branch` (`reject-001`…`003`). Newly confirmed:
`superpowers@44c9b2d:hooks/hooks.json` is a Claude Code `SessionStart` matcher invoking
`run-hook.cmd`. OMP hooks are TypeScript modules exporting
`default (pi: HookAPI) => void`, and the discovery layer's `pre`/`post` path convention is
discarded by the loader (`extensibility/hooks/loader.ts:236-237`, grade A). The hook is
**not portable in either direction** — a second, independent reason `reject-004`'s
reasoning generalizes.

**Reverse if** the gate-function wording is measured to underperform a shorter form. The
skill body budget is ≤500 tokens per spawn (`03-token-quality-model.md §F`), so the gate
function competes for space with the Iron Law itself.

---

### C-2. `agent-skills` — quality gates, and the best eval design in the corpus

**Problem shared.** Which review dimensions fire on which change, and how do you keep a
skill catalog from routing to the wrong skill.

**Mechanism 1 (B) — trigger evals with ranking and ownership.**
`agent-skills@d2478bf:evals/cases/*.json` pairs every skill with a case file:

```json
"trigger": {
  "positive": [ { "prompt": "Audit this file upload handler…", "top_k": 3 } ],
  "negative": [ { "prompt": "Rename these variables for clarity",
                  "owner": "code-simplification" } ]
}
```

Three design choices here are better than `spec/11 §D`'s flat
`should_trigger` / `should_not_trigger` lists:

1. **`top_k` instead of binary.** The assertion is *rank within k against all
   descriptions*, which degrades gracefully and produces a ratchetable number. The runner
   enforces it with a `--min-rank1` percentage against a checked-in baseline
   (`agent-skills@d2478bf:scripts/run-evals.js`, header contract).
2. **Negatives name an `owner`.** "This prompt should not trigger security-and-hardening"
   is weak; "this prompt belongs to code-simplification" is a testable routing claim and
   catches description overlap that a binary negative misses.
3. **Description-collision detection.** The runner fails when two skill descriptions are
   near-duplicates above a cosine threshold — a catalog-level guard, not a per-skill one.

Choice 3 matters more for omp-custom than its three-skill catalog suggests, because a
skill `description` is **persistent tier** (`03-token-quality-model.md §B`) and a missing
one silently drops the skill (`discovery/helpers.ts:390-392`, grade A). Descriptions are
the one place where cost and correctness both concentrate.

**Delta SD-4.** Restructure `spec/11 §D` fixtures to the `{positive: [{prompt, top_k}],
negative: [{prompt, owner}]}` shape and add a description-collision check. Honest
constraint: ranking and cosine similarity both need a scorer, so this is **L3**, not L0 —
it cannot run in static validation, and `spec/13` must say so rather than implying a free
CI check. The `owner` field is adopted in **KD-017**; the catalog-size cap that makes
collision the binding quality risk rather than a cost concern is **KD-014**.

**Mechanism 2 (B) — STRIDE per trust boundary.**
`agent-skills@d2478bf:skills/security-and-hardening/SKILL.md` opens with *"controls bolted
on without a threat model are guesses"* and runs STRIDE across each boundary, then adds
*"write abuse cases next to use cases — then make that your first test."* `spec/15 §A`
already has a trust-boundary table; it has no per-boundary threat enumeration and no
abuse-case rule.

**Delta SD-5.** The `security` quality gate's check list (the one `spec/11 §E` keeps in
`docs/policies/`, zero tier) gains: enumerate boundaries, run STRIDE per boundary, write
one abuse case per new external input. Zero-tier content, so the cost of adding it is
nothing and the cost of it being absent is a gate that says "check security."

**Mechanism 3 (B) — the approval standard.**
`agent-skills@d2478bf:skills/code-review-and-quality/SKILL.md`: *"Approve a change when it
definitely improves overall code health, even if it isn't perfect. Don't block a change
because it isn't exactly how you would have written it."*

This is a **false-positive control** and it is the one `spec/10 §C` is missing. Our four
checks are all "is this finding real?" — none is "is this finding *worth blocking on*?"
The reviewer pathology that produces `CHANGES_REQUESTED` over a stylistic preference is
not caught by asking whether the concern is present in the code, because it is.

**Delta SD-6.** Add to `diff-reviewer`'s blocking criteria: a finding blocks only if it
makes the change worse than not merging. Divergence from the reviewer's preferred
implementation is an `OBSERVATION`, never `BLOCKING`. Per-spawn tier, one sentence.

This is the *permissive* half of the reviewer contract. Its counterweight — uncertainty on
an already-blocking finding resolves toward blocking, not toward silence — is **KD-016**,
which is where the two halves are reconciled. Shipping D-6 without that asymmetry would
turn "is it worth blocking on?" into a licence to approve.

**Rejected.** The 24-skill catalog (persistent-tier cost, see §E), the four bundled
agents, the `.toml` command format (not an OMP shape), the `hooks/*.sh` SessionStart
scripts (same non-portability as C-1).

**Reverse if** a measured run shows the `top_k` ratchet produces false failures from
scorer variance rather than real routing regressions.

---

### C-3. `spec-kit` — the clarification gate, made concrete

**Problem shared.** An ambiguous request implemented on a guess, discovered at review.

**Mechanism (B).** `spec-kit@81d5cdb:templates/commands/clarify.md` is far more specific
than "ask about ambiguity". It supplies:

- an **ambiguity taxonomy** of eleven categories (functional scope, domain/data model,
  interaction flow, non-functional attributes, integration, edge cases, constraints,
  terminology, completion signals, placeholders), each marked
  **Clear / Partial / Missing** into an internal coverage map;
- a **hard cap of five questions** for the whole session;
- an **answer-shape constraint**: every question must be answerable as a 2–5 option
  mutually-exclusive choice, or in ≤5 words;
- a **ranking rule**: `Impact × Uncertainty`, with an explicit exclusion for anything
  that would not change architecture, data modeling, task decomposition, test design, or
  acceptance tests;
- a **sequential loop** — one question at a time, answer encoded back into the spec before
  the next.

The answer-shape constraint is the non-obvious part. It converts clarification from an
open-ended interview into a bounded decision procedure, and it makes each answer directly
encodable as an acceptance criterion. The `Impact × Uncertainty` filter is what prevents
five questions being spent on trivia.

**Delta SD-7.** `task-triage`'s skill body adopts: the five-question cap, the answer-shape
constraint, `Impact × Uncertainty` ranking, and one question at a time. The eleven-category
taxonomy is too long for a skill body at 800–2,000 tokens — take the six categories that
apply to code tasks (scope, data model, edge cases, non-functional, integration,
completion signals) and leave the rest in `docs/`. Lazy tier: `task-triage` is main-session
only and read on demand.

**Rejected, unchanged.** The `specify` CLI (`reject-008`). Newly noted: `clarify.md`'s
`.specify/extensions.yml` hook protocol — pre-command hooks with `optional` / `condition`
fields that the *model* is instructed to enumerate and invoke — is a second control loop
implemented in prose. It is exactly the separability failure `00-method.md §C` question 3
exists to catch, and it is rejected on that ground independent of the CLI rejection.

**Reverse if** the five-question cap proves too tight on genuinely underspecified tasks.
Measure: fixture `eval-007-ambiguous` rework rate.

---

### C-4. `OpenSpec` — what makes an acceptance criterion testable

**Problem shared.** Task packets carry acceptance criteria; nothing in the spec says what
a *good* one looks like, so "the feature works" passes as a criterion.

**Mechanism (B).** `OpenSpec@d578896:docs/writing-specs.md` supplies the bar:

- **One statement, one `SHALL`.** Three "and also" clauses are three requirements.
- **Observable** — someone outside the code can tell whether it holds. *"SHALL show an
  error banner when the upload exceeds 10 MB"* passes; *"SHALL handle large uploads
  gracefully"* fails.
- **RFC 2119 strength chosen deliberately** — `MUST`/`SHALL` by default, `SHOULD` only
  when a justified exception is genuinely allowed.
- **Scenarios as GIVEN/WHEN/THEN that name the case in the title** — "Rejects an expired
  token", not "Test 2".
- The test: *could a tester who has never seen the code tell whether it passed?*
- And the separation that matters: behavior in the requirement, mechanism in `design.md`
  — *"when behavior and implementation get mixed into one requirement, the requirement
  stops being testable and starts going stale the moment the code changes."*

That last point is directly load-bearing for us. A task packet whose acceptance criteria
describe *how* to implement leaves the Verifier nothing to check independently — it can
only confirm the Implementer did what it was told, which is not verification.

**Delta SD-8.** The mini-spec step in `standard.md` and `orchestrated.md` states the
authoring rule: one `SHALL` per criterion, observable from outside, named case, and no
implementation mechanism inside a criterion. Lazy tier (command body). This makes
`spec/13`'s "deterministic acceptance check" achievable by construction rather than by
hope — a criterion written this way maps to a command, and one written the other way does
not.

**Rejected, unchanged.** The OpenSpec CLI and the `changes/` → `archive/` folder lifecycle
(`reject-009`). The delta-spec concept survives as documentation structure only.

**Reverse if** nothing — this is an authoring bar with zero runtime cost. It cannot fail
in a way that requires reversal, only in a way that requires better wording.

---

### C-5. `promptfoo` — the assertion vocabulary

**Problem shared.** Fixture assertions need a shared vocabulary, or every fixture invents
its own.

**Mechanism (B).** `promptfoo@1c30e18:site/docs/configuration/expected-outputs/` splits
assertions into **deterministic** and **model-assisted**, and supplies a compact string
syntax for the deterministic set: `equals`, `contains`, `icontains`, `contains-any`,
`contains-all`, `starts-with`, `regex`, `is-json`, `contains-json`, `javascript`,
`python`, `levenshtein(N)`, `similar(threshold)`, `file://path` for externalized
assertions, and a `not-` prefix for negation.

Two properties are worth taking. First, the deterministic/model-assisted split is a
*hard* boundary in their docs, with scoring and thresholds attached only to the second —
which is precisely `spec/13`'s rule that model-graded metrics are advisory and never
evidence of correctness. Second, the string form (`contains-all:Paris,France`) makes a
fixture readable at a glance, which matters when fixtures are the thing nobody maintains.

**Delta SD-9.** `evals/` fixtures adopt the deterministic assertion names verbatim as the
vocabulary for acceptance checks, and keep model-graded assertions in a separate block
that the harness reports but never gates on. Zero tier — this is fixture file format, it
never enters a model's context.

**Rejected, unchanged.** promptfoo as a runtime dependency (`reject-017`); optional for
model-graded runs only. The red-team module stays out of scope.

**Reverse if** the local harness outgrows the vocabulary. Adding a name is cheap; adopting
the runtime is not.

---

### C-6. `anthropics/skills` — format only, and a stale watched path

**Mechanism (B).** SKILL.md frontmatter shape and one-skill-per-directory layout. Already
adopted; nothing new.

**Registry correction.** `registry/upstreams.yml` watches
`skills/*/SKILL.md`, `README.md`, and `spec/` for this repo. At `b29e7cf` the repository
contains `README.md`, `skills/`, `spec/`, `template/`, and `THIRD_PARTY_NOTICES.md` — and
`spec/agent-skills-spec.md` is now a **two-line pointer** reading *"The spec is now located
at https://agentskills.io/specification"*. Watching that file therefore detects nothing;
the authority moved off-repo.

**Delta SD-10.** Either watch the external specification URL as a `reference` upstream with
a recorded retrieval date, or record that the format is frozen at the shape we already
adopted and stop watching. The second is preferable: our three skills use four frontmatter
keys, all verified against OMP's own parser (grade A) rather than against the external
spec. OMP's `parseAgentFields` and skill gates are the authority that actually decides
whether our files load — the external spec cannot overrule it.

**License position corrected — `reject-013` is over-broad.** The ledger says "No LICENSE file
in the repository", which is true of the *root* and materially misleading. Verified at
`b29e7cf`: **16 per-skill `LICENSE.txt` files, 12 of them Apache-2.0**
(`algorithmic-art`, `brand-guidelines`, `canvas-design`, `claude-api`, `frontend-design`,
`internal-comms`, `mcp-builder`, `skill-creator`, `slack-gif-creator`, `theme-factory`,
`webapp-testing`, `web-artifacts-builder`); only 4 are Anthropic-proprietary (`docx`, `pdf`,
`pptx`, `xlsx`, each "All rights reserved"); `doc-coauthoring` has none and stays
all-rights-reserved. So **`skill-creator` may be copied with attribution and a NOTICE entry** —
see `dossiers/superpowers-skills.md §8`. `THIRD_PARTY_NOTICES.md` still does not grant use of
the repo's own content, and we do not *need* body text (our authoring template is derived).
The ledger is nonetheless wrong about the facts. Delta SD-12 (§G).

---

## D. Pattern sources

### D-1. `aider` — token-budgeted ranking, and one idea we are missing

**Mechanism (B).** `aider@5dc9490:aider/repomap.py` builds a whole-repo signature map and
then **fits it to a token budget by binary search**: rank tags by PageRank over the
symbol-reference graph (`:519-529`), then search the number of tags to include, measuring
actual token count each iteration and accepting within a `pct_err` tolerance
(`:666-698`), seeded at `middle = min(max_map_tokens // 25, num_tags)`. The budget itself
flexes when no files are in the chat (`:120-132`). Results are disk-cached.

The part worth extracting is not the map. It is the **personalization vector**
(`:365-445`, `:519-520`): files and identifiers *mentioned in the request* get elevated
PageRank weight, so ranking is task-relative rather than repo-absolute.

`spec/07` already tells the Explorer to return ranked evidence and prefer symbol lookup
over full reads. It does not say **what ranks against what**, and it does not bound the
output by a token budget — it bounds it by an offload threshold (`spec/phases/phase-03`
T-03.5), which is a different thing: a threshold says *when to spill*, a budget says
*what to include*.

**Delta SD-11.** The Explorer contract states: rank by relevance to the identifiers and
paths named in the task packet, return the highest-ranked evidence that fits the result
budget (200–600 tokens per `03-token-quality-model.md §F`), and name what was excluded
rather than silently truncating. "Named what it excluded" is the part that keeps a bounded
result honest — an Explorer that returns three files without saying it saw thirty has
produced a misleading result, not a compact one.

One correction this mechanism forces, recorded as **KD-015**: the ranking machinery above
has **no OMP equivalent**. `lsp` enumerates and name-searches; `ast_grep` and `grep` match
patterns. None of them ranks. So `spec/07`'s stated reason for rejecting a repository map —
that `lsp symbols` and `ast_grep` "duplicate what a repo-map computes" — is false. The
rejection stands on staleness and unconditional cost; the redundancy claim must be struck.
The distinction matters because an Explorer asked "what matters here" with no ranking
primitive answers from filename plausibility, fluently and unverifiably.

**Rejected, unchanged.** Running Aider; importing the codebase; a persistent repo-map
artifact. The cache in particular is a rejection with a specific reason under KD-013 and
`03-token-quality-model.md §C-3`: an isolated worktree is torn down after the task, so a
cache written inside it is destroyed and any path returned in the result is invalid in the
parent. OMP's `lsp symbols` / `lsp references` / `ast_grep` cover the query need without
an artifact.

**Reverse if** L3 measurement shows Explorer cost dominated by repeated
structure-discovery across spawns in the same session. Then a session-scoped map earns its
keep — and it would attach to OMP's artifact manager, not to a `.omp/` file.

---

### D-2. `mini-swe-agent` — termination conditions as a set

**Mechanism (B).** `mini-swe-agent@a83fcae:src/minisweagent/agents/default.py` bounds a
worker loop with four independent limits — `step_limit`, `cost_limit` (default 3.0),
`wall_time_limit_seconds`, `max_consecutive_format_errors` (default 3) — and terminates by
raising typed exceptions (`LimitsExceeded`, `TimeExceeded`, `FormatError`,
`InterruptAgentFlow`) rather than by returning a result.

Three of the four have direct OMP equivalents (grade A, KD-011):
`task.softRequestBudget` 200 with a hard stop at 1.5×, `task.maxRuntimeMs` (default 0 =
unlimited), `task.agentIdleTtlMs` 420 s. The fourth maps to `MAX_SCHEMA_RETRIES = 3` in
the yield retry ladder.

Two observations survive the mapping.

**Typed termination beats a returned result.** OMP's soft-budget overrun produces a
*partial yield* — a result object that looks like a completion (KD-011). mini-swe-agent's
shape makes the same condition unrepresentable as success. We cannot change OMP's shape,
which is exactly why KD-011's rule (treat a partial yield as a partial result) and D-2
above (empty diff is not a completion) are both coordinator-side checks. The upstream
confirms the design pressure is real rather than theoretical.

**A cost ceiling has no verified OMP equivalent.** Per-spawn `cost` is *returned*
(`task/types.ts:471-539`, grade A), so a ceiling is enforceable as a coordinator
acceptance check. Whether OMP has a settings-level cost cap is **grade D** — I did not
grep for one, and the dossier does not record one. Do not assert its absence.

**Delta: none.** KD-011 already covers this. Recorded because it is the second independent
upstream confirming that bounded workers need typed termination, which strengthens
KD-011's grade-C portion.

---

### D-3. `12-factor-agents` — the discriminated union

**Mechanism (B).** `12-factor-agents@d20c728:content/factor-04-tools-are-structured-outputs.md`
models tool calls as a **discriminated union on an `intent` field**, with per-variant
required fields:

```python
class CreateIssue: intent: "create_issue"; issue: Issue
class SearchIssues: intent: "search_issues"; query: str
```

and states the separation: *"The LLM decides what to do, but your code controls how it's
done."*

The union shape is the actionable part, and it lands on a known defect.
`spec/phases/phase-00` T-00.6 records that `agent-result.schema.yml` lists
`verification_results` as optional while a prose field rule requires it for
`status: completed` — a contradiction the task says to make "explicit". A discriminated
union on `status` **removes the contradiction structurally**: the `completed` variant
requires `verification_results`, the `blocked` variant does not, and no prose rule is
needed because the schema cannot express the invalid combination.

This matters more under KD-003 than it would otherwise: enforcement is a real gate
(permissive mode still rejects invalid payloads as `schema_violation`), so an invariant
expressed *in* the schema is enforced, while the same invariant expressed *beside* the
schema is not enforced at all.

**Delta: none new — T-00.6 is sharpened rather than extended.** The task's acceptance
should read "expressed as a discriminated union on `status`", not "stated unambiguously".
Blocked on **OQ-A** (which schema forms frontmatter `output:` accepts): a union is
expressible in JSON Schema via `oneOf`, and JTD via a `discriminator`/`mapping` form, but
the two are not interchangeable and `spec/key` has not established which OMP accepts.

**Rejected, unchanged.** The remaining eleven factors as operational checklists; the repo
as a dependency. License: Apache-2.0 code / CC-BY-SA-4.0 content, paraphrase attributed.

---

### D-4. `Agent-Skills-for-Context-Engineering` — the rationale we were missing wording for

**Mechanism (B).** `…@a1841d1:SKILL.md` contributes two sentences that carry more weight
than most mechanisms in this corpus.

*"Sub-agents exist primarily to isolate context rather than to simulate organizational
roles."*

This is the justification for `spec/03`'s topology stated in one line, and it is a live
constraint rather than a slogan: it is the test that rejects the ECC design (§E) and it is
the reason our four workers are named for what they *isolate* (retrieval, edit, evidence,
judgement) rather than for job titles. An agent added because an org chart has that role
fails this test.

*"The correct optimization target is tokens-per-task, not tokens-per-request."*

Independent corroboration of `03-token-quality-model.md §A`. Ours is stricter — tokens per
*accepted* outcome, with a false-completion constraint — and the difference is worth
keeping, because tokens-per-task still rewards a cheap wrong answer.

Also useful as vocabulary: **observation masking** (replace verbose tool output with a
reference) names what OMP's artifact spill already does (`tools.artifactSpillThreshold`,
grade A), and the context-degradation patterns (lost-in-middle, U-shaped attention) are
the mechanism behind why sticky-tier content is expensive *and* less reliable as context
grows — a second argument for the ≤700-token `RULES.md` budget beyond multiplier cost.

**Delta: none.** Adopt as cited rationale in `spec/03 §A` and `03-token-quality-model.md
§A`. Zero tier.

**Rejected, unchanged.** Memory systems, self-improvement loops (`reject-005`,
`reject-006`, `reject-015`), latent briefing / KV-cache sharing (OmniRoute-specific and
requires worker KV-state access we do not have).

---

### D-5. `andrej-karpathy-skills` and `agents.md` — principle and convention

`andrej-karpathy-skills@2c60614`: four coding principles, independently rewritten into the
`AGENTS.md` constitution. Nothing new; the rewrite is complete and the original text is not
needed again.

**`reject-014`'s premise is false, though its conclusion holds.** The ledger says "No LICENSE
file. Copyright all rights reserved by default." There is no LICENSE *file*, but the repo
declares MIT twice — `skills/karpathy-guidelines/SKILL.md:4` (`license: MIT`) and
`README.md:169-171`. An in-file grant is a grant, so the material was never restricted to
ideas-only. The rewrite decision stands on its own ground (four general engineering concepts,
and our version is better scoped for `AGENTS.md`), but the rationale must be corrected and
`adopt-016`'s `license_check: no-license` is wrong. Delta SD-12 (§G).

`agents.md@d1ac7f0`: the `AGENTS.md` convention itself — a project section carrying real
build/test/lint commands and architecture rules. Already adopted. Worth noting that OMP's
implementation is *stricter* than the convention: project `AGENTS.md` returns at the
nearest match with no concatenation up the tree (`builtin.ts:921-936`, grade A), so a
monorepo cannot layer a root and a package file. That is a runtime fact the convention
does not imply, and it belongs in the installer docs.

---

## E. `ECC` — the negative control

`ECC@9aac858` ships **67 agents, 282 skills, 94 commands** by its own `AGENTS.md` count
(agents and commands verified by directory count this pass: 67 and 94).

Every mechanism was rejected in earlier rounds (`reject-004`…`007`). The reason to keep it
in the corpus is that it **prices the persistent tier** better than any argument we could
construct:

- A skill's `description` is persistent — paid every turn of every session that lists it
  (`03-token-quality-model.md §B`, grade A mechanism). At 282 skills and a 30–80 token
  description budget, the *listing alone* is 8k–23k tokens before any work happens. And the
  listing is forwarded to **every subagent**, not just the main session (`skills` propagates
  through `task/structured-subagent.ts:366` → `task/executor.ts:3025`, grade A) — so the
  figure multiplies by session count. This is the arithmetic behind **KD-014**'s 10-skill
  cap.
- Agent descriptions are listed for spawn selection. 67 more entries.
- `AGENTS.md` instructs *"Use agents proactively without user prompt"* with a
  trigger→agent table — the opposite of `spec/10 §D`'s risk-based dispatch, and an
  unbounded spawn-count policy.

Applied to §D-4's test: most of the 67 agents (`java-reviewer`, `django-reviewer`,
`go-reviewer`, `rust-reviewer`…) are the **same context isolation** parameterized by
language. They simulate roles rather than isolating distinct contexts. This is the
strongest available illustration of why our topology has four workers and why adding a
fifth requires naming what it isolates that no existing worker does.

**Delta: none.** Cite in `spec/03 §H` and `03-token-quality-model.md §B` as the priced
counter-example. This is the highest-value thing an unadopted repository can contribute.

---

## F. Conditional — evaluated, not integrated

| Repo | Would solve | Why not in v0 | Named revisit trigger |
|---|---|---|---|
| `serena@c7af2c0` | Semantic/LSP retrieval via MCP | OMP has `lsp` + `ast_grep` natively (grade A); Serena adds an MCP dependency and a second index | A documented retrieval failure OMP's `lsp` cannot resolve (`reject-010`) |
| `repomix@a27ecec` | Whole-repo snapshot for onboarding | 20k–200k tokens per invocation; violates the context budget as a default | Already conditionally approved for onboarding, audits, external review (`reject-011`) |
| `context7@8d52608` | Current versioned library docs | Local code and types rank ahead of it | Already position 4 in the retrieval order (`reject-012`) |

All three verdicts stand unchanged. One note: `repomix` and `context7` both now ship a
`skills/` directory at their pinned SHAs, and `context7` ships `rules/`. Neither changes
the verdict — the value is still the tool, not the packaging — but a future pass reading
these repos for skill-authoring patterns should know the directories exist.

---

## G. Deltas this synthesis proposes

Twelve actionable items. None changes a recorded decision; each either adds a mechanism to
a named attachment point or corrects a file that is currently wrong. Each needs a KD entry
in `04-decision-log.md` before implementation.

| # | Delta | Attaches to | Tier | Target file | Grade |
|---|---|---|---|---|---|
| SD-1 | Registry watches OMP `docs/**` instead of `packages/**` source; `update_policy` and `tier` disagree with `spec/14 §B` | — (governance) | zero | `registry/upstreams.yml` | **A** (the mismatch is verifiable) |
| SD-2 | `status: completed` with absent `patchPath`/`branchName` or empty diff is not a completion | Tech Lead acceptance check | lazy | 3 command files | B + A |
| SD-3 | Trigger fixtures require a no-skill baseline arm before the skill body is final | L3 eval fixtures | zero | `spec/11 §D`, `spec/13 §C` | B |
| SD-4 | Fixture shape becomes `positive:[{prompt,top_k}]` / `negative:[{prompt,owner}]` + description-collision check; explicitly **L3, not L0** | eval fixtures | zero | `spec/11 §D`, `spec/13 §B` | B |
| SD-5 | Security gate check list gains STRIDE-per-boundary and one abuse case per new external input | `security` gate doc | zero | `docs/policies/` | B |
| SD-6 | A finding blocks only if it makes the change worse than not merging; preference divergence is `OBSERVATION` | reviewer prompt | per-spawn | `diff-reviewer.md`, `spec/10 §C` | B |
| SD-7 | Triage adopts 5-question cap, answer-shape constraint, `Impact × Uncertainty`, one at a time | `task-triage` body | lazy | `skills/task-triage/SKILL.md` | B |
| SD-8 | Acceptance criteria: one `SHALL`, observable, named case, no mechanism inside the criterion | mini-spec step | lazy | `standard.md`, `orchestrated.md` | B |
| SD-9 | `evals/` adopt promptfoo's deterministic assertion names; model-graded kept in a separate non-gating block | fixture format | zero | `evals/**` | B |
| SD-10 | Stop watching `anthropics/skills` `spec/` (now an external URL); OMP's parser is the operative authority | — (governance) | zero | `registry/upstreams.yml` | B + A |
| SD-11 | Explorer ranks by identifiers/paths named in the packet, fits the result budget, and **names what it excluded** | Explorer contract | per-spawn | `explorer.md`, `spec/07` | B + C |
| SD-12 | Two license records state facts that are false: `reject-013` reads a root-only absence as repo-wide (12 of 16 per-skill licenses are Apache-2.0, incl. `skill-creator`); `reject-014`/`adopt-016` miss MIT declared in `SKILL.md:4` + `README.md:169-171`. Decided in **KD-023** | — (governance) | zero | `registry/rejected-mechanisms.yml`, `adoption-ledger.yml`, `licenses.yml` | **A** (verified against clones) |

### Registry corrections beyond SD-1 and SD-10

KD-001 removes `.omp/policies/` and `.omp/schemas/` from the installed surface. Four
registry entries still list files in those directories as `local_components`:

| Entry | Stale path | Correct destination |
|---|---|---|
| `agent-skills` | `template/.omp/policies/quality-gates.yml` | inlined matrix in `standard.md`/`orchestrated.md` + `docs/policies/` |
| `agent-skills-context-engineering` | `template/.omp/policies/context-budget.yml` | `docs/` + validator thresholds |
| `context7` | `template/.omp/policies/context-budget.yml` | same |
| `12-factor-agents` | `template/.omp/schemas/agent-result.schema.yml` | worker agent `output:` frontmatter |

Also stale: `superpowers` and `anthropics-skills` list
`template/.omp/skills/evidence-before-completion/SKILL.md` — correct — but no entry records
that the skill is delivered via `autoloadSkills` frontmatter on `implementer` and
`verifier`, which is the actual attachment point and the thing that would break if the
skill were renamed.

---

## H. What this synthesis did not settle

Stated so the gaps are not mistaken for coverage.

- **No measurement.** Every delta above is grade B for "the upstream mechanism is as
  described" and grade C for "we should adopt it". `spec/13`'s L3/L4 runs are where any of
  it becomes defensible.
- **D-4's scorer is unspecified.** `top_k` ranking and description-collision detection both
  need an embedding or ranking model. Which one, and whether its variance is small enough
  for a ratchet, is open.
- **SD-11's budget interacts with an unread path.** Whether a bounded Explorer result loses
  detail the Implementer needs is exactly the kind of question `spec/13`'s fixtures answer
  and reasoning cannot.
- **OQ-A blocks D-3's schema sharpening** (the `oneOf` vs JTD discriminator question).
  Recorded in `04-decision-log.md`; unchanged by this pass.
- **Five repos were read at the surface only** this pass — `serena`, `repomix`,
  `context7`, `agents.md`, `andrej-karpathy-skills`. Their verdicts are
  `[registry-carried]` plus a directory listing. That is sufficient for "unchanged", and
  insufficient for any new adoption from them.
