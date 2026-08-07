# 05 — Context and Token Model

> OPUS PROPOSED SPEC v1 | What loads when, what each budget is, and where the current template overspends.

---

## A. The Metric

The optimization target is **tokens per accepted outcome**, not tokens.

This distinction decides every trade-off below. A run that spends 40k tokens and
produces a change the user accepts beats a run that spends 15k and produces one
they reject — the second run's real cost includes the retry. Any change that
saves tokens by weakening verification is therefore not a saving; it moves cost
from the measured column to the unmeasured one.

Concretely, the following are never acceptable token reductions:

- Skipping the Verifier because the Implementer reported success.
- Dropping the failing-test-first step on a bug fix.
- Reducing thinking level on a high-risk task.
- Trimming acceptance criteria to fewer than the change needs.
- Suppressing uncertainty to avoid a clarification round-trip.

---

## B. What Loads, and When

Four distinct lifetimes. Confusing them is the source of most token waste.

| Tier | Loaded | Cost model |
|---|---|---|
| Persistent | Every turn of every session | Paid once per turn, forever |
| Sticky | Re-attached near the current turn | Paid per turn, survives compaction |
| Per-session | Once per subagent session | Paid per spawn |
| Lazy | Only when referenced | Paid only on use |

Assignments:

- **Persistent** — `AGENTS.md`; the skill *listing* (name + description of every
  discovered skill).
- **Sticky** — `RULES.md`. Verified: `discovery/builtin.ts:416` forces
  `alwaysApply` regardless of frontmatter, so it survives compaction.
- **Per-session** — each agent's system prompt body; each task packet.
- **Lazy** — skill bodies, read via `skill://<name>`.

The skill *listing* being persistent while skill *bodies* are lazy is the
progressive-disclosure mechanism that makes skills cheap. It also means a skill's
`description` is load-bearing: it is the only part most sessions ever pay for,
and it is what the model uses to decide whether to pay for the body.

---

## C. Budgets

Adopted from `context-budget.yml` as **provisional defaults pending Phase 06 evaluation** (CR-19).
These targets represent initial baselines based on role complexity; actual optimal values
will be validated through A/B testing before being promoted to production recommendations.

| Component | Target | Warn above | Tier |
|---|---|---|---|
| `AGENTS.md` | 600–1,200 | 1,500 | persistent |
| `RULES.md` | 300–700 | 800 | sticky |
| Agent system prompt | 500–1,200 | 1,500 | per-session |
| Skill description | 30–80 | 120 | persistent |
| Skill body | 800–2,000 | 2,500 | lazy |
| Task packet | 300–800 | 1,200 | per-task |
| Worker result | 200–600 | 1,000 | per-result |

`validate-template.ps1` already checks the first three. It does not check skill
descriptions, skill bodies, or — because they are runtime artifacts — packets and
results. Packets and results are enforced by contract in the agent prompts, not
statically.

---

## D. The Two Prohibitions

**Task packets must not contain the parent transcript.** This is `RULES.md`
invariant 4 and it is the single most important token rule in the system. A
packet carrying the parent conversation defeats the entire purpose of
delegation: the subagent pays for context it cannot act on, and the parent pays
again when the result comes back. Packets carry objective, scope, criteria,
file references, and constraints — nothing that reads as history.

**Worker results must not contain chain-of-thought or full transcripts.** The
Tech Lead needs the conclusion and the evidence, not the path taken. A result
that quotes 200 lines of test output to prove 12 tests passed has spent ~1,500
tokens to convey what "12 passed, 0 failed, exit 0" conveys in ten.

Both prohibitions are stated in `context-budget.yml` under `must_not_contain`
and both are correct. They need to appear in the agent prompts, not only in a
policy file no agent reads.

---

## E. Where the Current Template Overspends

### E-1. `read-summarize: false` on Explorer — P1 defect

The global baseline sets `read.summarize.enabled = true`. Explorer's frontmatter
sets `read-summarize: false`, which `parseAgentFields` reads
(`discovery/helpers.ts:300`) and honours. The field works. That is the problem.

Explorer's own instructions say it must not dump full files and should prefer
symbol lookup. Its frontmatter disables the mechanism that would summarize the
files it does read. The two are in direct opposition, and the frontmatter wins
because it is machinery and the instruction is prose.

Explorer's job is ranked evidence — file paths, line references, symbol names,
brief context. Summarized reads are *better* input for that than full contents.
Recommend removing the override.

### E-2. `read-summarize: false` on Verifier — P1, weaker case

More defensible: verification needs exact output, and a summarizer that elides
the one line showing which assertion failed has destroyed the evidence.

But the Verifier gets its evidence from `bash` command output, which
`read.summarize` does not touch. The override only affects files it reads with
`read` — mostly test files and source, where summaries are adequate.

Recommend removing it, with a documented exception: if a fixture shows the
Verifier missing failure detail because of summarization, restore it for the
Verifier only, and record why.

### E-3. Reviewer scope creep — P1

`reviewer.md` says to read "the actual changed files and their diff context."
"Diff context" is unbounded — it can be read as the whole file. For a large
file with a three-line change, that is a full-file read to review three lines.

Recommend: diff first (`git diff`), then targeted expansion only where a finding
requires it, and only the enclosing symbol. Bound it explicitly in the prompt.

### E-4. Constitution duplication risk

`validate-template.ps1` section 3 already guards this: it warns if constitutional
phrases from `AGENTS.md` appear verbatim in agent files. This check is well
designed and should be extended to the skill bodies, which currently are not
scanned.

The reason it matters: `AGENTS.md` is persistent and every agent inherits it.
A rule repeated in five agent prompts is paid six times.

---

## F. Progressive Retrieval

Adopted from `context-budget.yml` as **guidance** (CR-20: not rigid gates — authority ordering is task-dependent).

```
1. Local code and types (LSP symbols, current file, related modules)
2. Local documentation (README, docs/, comments)
3. Official versioned documentation
4. Context7 (version-specific library docs)
5. Broader web research
```

**Guidance, not exhaustion gates**: prefer project executable truth for "what this repo currently does"; prefer version-matched official docs for external API/runtime semantics. If the current level cannot answer the question within a reasonable retrieval budget, escalate rather than continuing to search. Most retrieval failures are jumps from level 1 to level 5 — a web search for something the type definition next to the callsite already answered. But "exhaust level N before descending" is not the rule — the rule is: use the most authoritative source for the specific question type, within a bounded retrieval budget.

Levels 4 and 5 are not wired in v0. Context7 is available as an MCP tool in this
environment but is not part of the template; `web_search` is in the Tech Lead's
allowlist only.

> **ENVIRONMENT ASSUMPTION (CR-18)**: Context7 availability and `web_search` access depend on the runtime environment. These are not public-source-verifiable facts — verify with a sanitized runtime discovery transcript.

---

## G. Filesystem Offloading

When a result is large but must persist, write it to a file and pass the path.

| Artifact | Threshold | Destination | Isolation-safe? |
|---|---|---|---|
| Exploration evidence | >2,000 tokens | `.task/<id>/exploration.md` | Standard workflow only |
| Verification output | >500 tokens | quote key lines only; full output to `.task/<id>/verify.log` | Standard workflow only |
| Review findings | >1,000 tokens | `.task/<id>/review.md` | Standard workflow only |

This is how a worker returns a large finding without putting it in the parent's
context: the result carries `artifacts: [".task/impl-001/review.md"]` and the
Tech Lead reads it only if it needs to.

`.task/` must be gitignored. It is session scratch, not project content.

**CR-10 — Isolated workers must use the OMP artifact manager, not `.task/`.**

An isolated worker operates in a temporary worktree that is torn down after the task
lifecycle completes. A gitignored `.task/<id>/...` file inside the isolated worktree
does not propagate through git branch/patch merge, and is destroyed when the worktree
is cleaned up. The path reference passed in the result is invalid in the parent.

For Orchestrated (isolated) Implementers: use the OMP native artifact manager
(executor options for parent artifact manager adoption, available in `sdk.ts`).
The child session adopts the parent artifact manager, and artifacts are stored in
the parent artifact domain — remaining valid after isolation teardown.

The `.task/<id>/...` pattern is safe **only** for non-isolated (Standard) workers
where the working tree persists through the full Tech Lead lifecycle.

---

## H. Compaction

The frozen baseline configures `shake`:

```
compaction.enabled          = true
compaction.strategy         = shake
compaction.keepRecentTokens = 20000
compaction.supersedeReads   = true
compaction.dropUseless      = true
```

`supersedeReads = true` matters for the workflows: when a file is read twice,
the earlier read is dropped. This makes the "re-read after edit" pattern cheap
and removes the incentive to cache file contents in the conversation.

The template must not attempt its own compaction. OMP owns this
(`01-target-architecture.md`, principle 1). No summarize-the-conversation step
in any command.

---

## I. Verification

- `validate-template.ps1` checks budgets for `AGENTS.md`, `RULES.md`, and all
  five agent prompts (already implemented).
- Extend it to skill descriptions (30–120) and skill bodies (800–2,500).
- Extend the constitutional-phrase scan to skill bodies.
- No agent prompt or skill body contains a task-packet example with a transcript.
- `.task/` appears in `.gitignore`.

---

## J. Open Items

| # | Item | Position |
|---|---|---|
| C-1 | Remove `read-summarize: false` from Explorer | Yes — contradicts its own instructions |
| C-2 | Remove `read-summarize: false` from Verifier | Yes, with a documented restore condition |
| C-3 | Bound Reviewer's "diff context" | Diff first, enclosing symbol only on demand |
| C-4 | Enforce packet/result budgets at runtime | Not possible statically; contract-only in v0 |
| C-5 | Wire Context7 as level 4 | Deferred past v0 |
