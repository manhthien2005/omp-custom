# 00 — Method

> How the seventeen upstream repositories were analyzed, what counts as evidence in this
> layer, and how a claim is graded. Read this before trusting anything in `01`–`04`.

---

## A. Why method comes first

The first pass of this project produced `.omp/policies/` and `.omp/schemas/` — nine YAML
files, **581 lines**, with zero runtime consumers. They were not written carelessly.
They were written by looking at repositories that had `policies/` folders, concluding the
shape was good, and copying the shape.

The failure was methodological, not intellectual. There was no step in the process that
asked *"what reads this file at runtime?"* — so nothing caught the answer, which was
"nothing".

A second methodological failure happened during the audit itself and is worth recording
because it changes what counts as evidence. An early pass read OMP agent files through
GitHub's rendered HTML and concluded that two of them were missing YAML `---` fences —
a P0 that would have broken agent discovery entirely. Byte-level inspection showed `---`
at byte 0 of all five files. GitHub's HTML view swallows frontmatter fences. The finding
was retracted (`spec/00` F-20).

Both failures share a root: **a claim was accepted from a source that could not decide the
question.** A folder layout cannot decide whether a loader exists. Rendered HTML cannot
decide what bytes a file starts with. So the method below is built around one rule: for
every claim, name the thing that decides it.

---

## B. Evidence grades

Every factual claim in this layer carries one of four grades. They are not
interchangeable, and mixing them is how confident wrongness gets built.

| Grade | Means | Decided by | Example |
|---|---|---|---|
| **A — Source-verified** | A named file and symbol in the implementation decides it | `path:symbol` citation in OMP source, read from the local clone | "`yield` is auto-appended to any explicit `tools:` list" — `discovery/helpers.ts:265-267` |
| **B — Upstream-verified** | The upstream repo's own code or docs decide it, at a pinned commit | `repo@sha:path` citation | "Aider's repo-map is token-budgeted via graph ranking" — `aider@5dc9490` |
| **C — Reasoned** | A design judgment supported by A/B facts but not entailed by them | Named rationale + named alternative | "Explorer should not be isolated" — read-only agents gain nothing from a worktree clone |
| **D — Unverified** | Requires a live experiment; cannot be settled by reading | Named experiment ID | "Does `output:` frontmatter enforce through OmniRoute's `openai-codex-responses` API?" — `spec/README` OQ-1 |

Two rules govern grades:

1. **A grade-C claim may not be presented as a grade-A fact.** `spec/README §10` already
   applies this discipline by splitting each decision record into *source facts* (what OMP
   proves) and *design choice* (what was chosen). This layer keeps that split.
2. **A grade-D claim blocks anything that depends on it.** It does not get promoted by
   confidence. `spec/phases/phase-00-foundation.md` exists precisely to convert D into A
   before the dependent work starts.

---

## C. The mechanism-extraction procedure

Each upstream repo was analyzed with the same six questions, in order. The order matters:
question 4 kills most candidates, and asking it late wastes the analysis.

```
1. WHAT PROBLEM does this repo solve that omp-custom also has?
      → If none, stop. The repo is interesting, not relevant.

2. WHAT MECHANISM does it use? (not: what folders does it have)
      → Describe the behavior. A folder is not a mechanism.

3. IS THE MECHANISM SEPARABLE from its runtime?
      → Many good mechanisms are inseparable from a CLI, a daemon, or an
        MCP server. Those are rejections, not adoptions.

4. WHICH OMP PRIMITIVE would carry it?          ← the filter that matters
      → Name it: command / agent frontmatter field / skill / rule /
        hook / tool / config key / output schema.
      → If no primitive carries it, the answer is one of:
          (a) documentation under docs/,
          (b) a rejection with a recorded reason,
          (c) a request for an OMP change (out of scope for v0).
        It is NEVER a new folder under .omp/.

5. WHAT DOES IT COST?
      → Which tier (persistent / sticky / per-spawn / lazy), and how many
        tokens in that tier. A per-spawn cost multiplies by fan-out width.

6. WHAT WOULD MAKE US REVERSE IT?
      → A named, checkable condition. "It didn't help" is not one.
```

Question 4 is the load-bearing step, and it is stated as a constraint in `spec/01 §9`
invariant 2: *every file in `template/.omp/` is discovered by OMP, or it does not live
there.* This layer's contribution is to apply that test **at analysis time** rather than
at audit time.

### Why "separable from its runtime" is a distinct question

Question 3 catches a specific and frequent error: adopting a mechanism whose value lives
entirely in the infrastructure that implements it. `spec/README §8` already forbids a
second orchestration engine, and `registry/rejected-mechanisms.yml` records seven
rejections that are all instances of this one pattern — external CLI, external daemon,
external MCP dependency, or a second control loop.

The distinction that survives: **a mechanism's *idea* is often separable even when its
*implementation* is not.** Aider's repository map is inseparable from Aider's tree-sitter
indexer; the *principle* — signature-level view under a token budget — is separable and is
adopted as behavior in `spec/07 §D` without a persistent artifact. Recording this
distinction explicitly is what prevents the next round from re-proposing the indexer.

---

## D. What was read, and how

### Upstream corpus

Seventeen repositories under `_research/upstreams/`, each a pinned clone. The pinned SHA
is the citation anchor; a claim without one is grade C at best.

| Repo | Pinned | Authority for |
|---|---|---|
| `oh-my-pi` | `3a8591a` (v17.2.10) | **Runtime authority.** Every grade-A claim about discovery, frontmatter, isolation, schema enforcement, model roles |
| `ECC` | `9aac858` | Large-scale agent config organization |
| `superpowers` | `44c9b2d` | Skill packaging, debugging discipline, verification gates |
| `aider` | `5dc9490` | Repository map, symbol-first retrieval |
| `serena` | `c7af2c0` | Semantic/LSP retrieval |
| `repomix` | `a27ecec` | Whole-repo packing (and its cost) |
| `12-factor-agents` | `d20c728` | Agent architecture principles |
| `mini-swe-agent` | `a83fcae` | Minimal worker loop |
| `spec-kit` | `81d5cdb` | Constitution, clarification gate, Given/When/Then |
| `OpenSpec` | `d578896` | Delta specs |
| `promptfoo` | `1c30e18` | Evaluation harness patterns |
| `context7` | `8d52608` | Versioned library docs |
| `skills` (Anthropic) | `b29e7cf` | SKILL.md format |
| `agent-skills` | `d2478bf` | Production quality gates |
| `Agent-Skills-for-Context-Engineering` | `a1841d1` | Context budget policy |
| `andrej-karpathy-skills` | `2c60614` | Coding principles |
| `agents.md` | `d1ac7f0` | AGENTS.md convention |

### Reading rules

Derived directly from the two methodological failures in §A:

1. **Local clone, never rendered HTML.** GitHub's blob view drops YAML frontmatter fences
   and truncates long files. `spec/00` F-20 records the false P0 this produced. Read
   `_research/upstreams/**`, or `raw.githubusercontent.com` if the clone lacks a path.
2. **Bytes when delimiters matter.** `cat -A` for anything where a fence, trailing
   whitespace, or line ending decides the question.
3. **Grep the consumer, not the producer.** To establish that a file is loaded, find the
   code that loads it. Absence of a loader is proven by an exhaustive grep of the discovery
   layer — which is how `policies/`/`schemas/` were shown to be inert (`spec/02 §A`).
4. **Read the parser for a format claim.** Frontmatter questions are decided by
   `parseAgentFields` and `normalizeKeys`, not by what other repos' files look like. This
   is what settled the kebab-case question: `normalizeKeys` rewrites `thinking-level` →
   `thinkingLevel`, so both spellings are valid (`spec/02 §B`).

---

## E. License discipline

Adoption type is a legal question before it is a design question, and it constrains what
"adopt" can mean. Four types, as used in `registry/adoption-ledger.yml`:

| Type | What may be taken | License requirement |
|---|---|---|
| `conceptual-inspiration` | The idea, re-expressed independently | None — ideas are not copyrightable expression |
| `paraphrased-implementation` | The structure, rewritten in own words | Permissive license; attribution recorded |
| `adapted` | Modified copy | Permissive license; attribution + modification note |
| `copied` | Verbatim | Permissive license; full attribution; **not used in this project** |

Two repos in the corpus (`skills`, `andrej-karpathy-skills`) ship no LICENSE file **at the
repository root**, and `registry/rejected-mechanisms.yml` reads that absence as all-rights-
reserved (`reject-013`, `reject-014`). **Both records are factually wrong, verified against
the clones on 2026-08-07.** A root-level LICENSE file is not the only way a grant is made,
and this method treats "no LICENSE file" as a claim to check, not a conclusion:

| Repo | Ledger claim | Verified fact |
|---|---|---|
| `anthropics/skills` | "No LICENSE file in the repository" | True of the root only. **16 per-skill `LICENSE.txt` files: 12 Apache-2.0**, 4 Anthropic-proprietary (`docx`, `pdf`, `pptx`, `xlsx` — "All rights reserved"). `doc-coauthoring` has none. |
| `andrej-karpathy-skills` | "No LICENSE file. Copyright all rights reserved by default." | No LICENSE *file*, but MIT declared **twice**: `skills/karpathy-guidelines/SKILL.md:4` (`license: MIT`) and `README.md:169-171`. An in-file grant is a grant. |

Consequence for this layer: **`skill-creator` is Apache-2.0** and may be copied with
attribution and a NOTICE entry — it is the most relevant file in that repo for the authoring
craft in `dossiers/superpowers-skills.md §2`, and the ledger was blocking it for a reason
that does not exist. Nothing in `template/` changes (§2 is derived, not copied), but a wrong
license record is inherited as a false constraint by every future maintainer.

Required ledger corrections, not yet applied: scope `reject-013` to the four proprietary
document skills; correct `reject-014` and `adopt-016`'s `license_check: no-license` to "MIT
declared in SKILL.md frontmatter and README, no LICENSE file"; check `registry/licenses.yml`
for the same two errors. Tracked in `02-repo-synthesis.md §G`.

This constraint has a design consequence worth stating: **a mechanism available only as an
idea must be re-derived, and re-derivation is a chance to fit it to OMP rather than to its
original runtime.** The constraint improves the result more often than it costs anything.

---

## F. How a decision gets recorded

Every entry in `04-decision-log.md` carries these fields. The shape is deliberately close
to `spec/README §10`'s decision records so the two can be cross-read.

```yaml
id:              KD-nn                      # stable, never reused
date:            YYYY-MM-DD
question:        <the decision, as a question>
source_facts:    [<grade-A/B citations that constrain the answer>]
choice:          <what was decided>
grade:           A | B | C | D              # grade of the *choice*, not the facts
omp_attachment:  <the primitive that carries it, or NONE-BY-DESIGN>
cost:            <tier + token estimate>
alternative:     <the strongest rejected option>
why_not:         <why that alternative lost — on cost/benefit, not on being "wrong">
reverse_if:      <named, checkable condition>
```

Three fields do real work and are worth defending:

**`grade` on the choice, separate from the facts.** A decision can rest on grade-A facts
and still be a grade-C choice. `spec/README §10` DR-6 is the model: source proves isolation
requires git and costs a materialization; *choosing* not to isolate the Explorer is a
cost/benefit judgment, and the record says so.

**`why_not` framed as cost/benefit, not correctness.** Most rejected alternatives are not
wrong. `spec/README` DR-3 explicitly records that re-homing policies to `docs/` is a
legitimate alternative that lost on synchronization risk, not on being incorrect. Recording
a defensible alternative as "wrong" is how a decision becomes unrevisitable when the
trade-off shifts.

**`reverse_if` must be checkable.** "If it turns out worse" is not a condition. "If
`persistNestedPatches()` becomes reachable on the successful `apply=false` path" is —
that is the exact condition under which `spec/08 §D-1`'s nested-repo exclusion lifts.

---

## G. Anti-patterns this method exists to prevent

| Anti-pattern | What it looks like | The step that catches it |
|---|---|---|
| Folder cargo-culting | Copying `policies/` because a big repo has one | Q4 — name the OMP primitive |
| Unpriced adoption | "Add the skill, it's good practice" | Q5 — name the tier and the cost |
| Grade inflation | A reasoned choice cited later as a verified fact | §B grade split |
| Rendered-HTML reading | A frontmatter claim from a GitHub blob page | §D rule 1 |
| Irreversible decisions | No recorded condition for revisiting | §F `reverse_if` |
| Second-runtime creep | Adopting a mechanism plus the engine that runs it | Q3 — separability |
| Re-litigation | A rejected mechanism reappears three rounds later | `04-decision-log.md` + `registry/rejected-mechanisms.yml` |

---

## H. What this method does not do

Stated so the limits are not mistaken for coverage:

- **It does not measure.** Every quality claim in this layer is either source-derived or
  reasoned. Measurement is `spec/13`'s job, and `spec/phases/phase-06-evaluation.md` is
  where token-and-quality claims first become defensible. Until then, a cost figure here is
  an estimate with a stated basis, not a measurement.
- **It does not settle grade-D questions.** Five remain open in `spec/README §9` and four
  in `spec/02 §I`. This layer records which decisions depend on them; it does not resolve
  them by reasoning.
- **It does not cover upstream behavior at any commit but the pinned one.** Drift is
  `spec/14`'s job, via `watched_paths`.
