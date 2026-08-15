# Per-repo report contract

> Every file in `spec/key/repos/` follows this shape. The point is **composability**: the
> existing `dossiers/` are organized by *cluster*, which is why they cannot be diffed against
> each other or mechanically rolled up. These can.
>
> One file per upstream. Named `<repo-dir-name>.md`, matching `_research/upstreams/<dir>`.

---

## Hard rules

1. **Read from `D:/Dev/Projects/omp-template/_research/upstreams/<repo>/`.** The clones are
   gitignored and exist only in the main repo, never in a worktree.
2. **Every claim carries `file:line` at the pinned commit, or a grade below A.** Get the SHA
   with `git -C <repo> rev-parse HEAD`. Record it in the header.
3. **Never assert what you did not open.** §7 is mandatory and must list what you skipped.
   A short honest report beats a long confident one. Unread ⇒ say unread.
4. **A mechanism with no OMP attachment point is not a finding.** It is either documentation
   or a defect. This is the filter that would have prevented `.omp/policies/`
   (nine YAML files, 581 lines, zero runtime consumers).
5. **No recommendation without a cost.** State where the token is paid: `zero` (never enters
   a context), `persistent` (every turn), `lazy` (on invocation), `per-spawn`, `per-action`.
6. **Do not edit any file outside your own report.** Not the spec, not the registry, not
   another repo's report. Propose; do not apply.
7. **Every repository report repeats its own authority boundary; a folder-level notice is
   insufficient.** The report is source/research evidence. Its former role names, counts,
   verdicts, and adoption labels cannot select current topology, dispatch, review, or
   capability behavior.

---

## Grades

| Grade | Meaning |
|---|---|
| **A** | Source-verified. `file:line` at the pinned SHA supports it exactly. |
| **B** | Read, but behavior inferred rather than traced (docs, README, tests). |
| **C** | Design judgment — our opinion, not their fact. |
| **D** | Unverified. Needs a live run. Never a basis for a decision. |

---

## Required sections

```markdown
# Repo Report — <name>

> **Path:** `_research/upstreams/<dir>`
> **SHA:** `<full sha>` (`git -C <dir> rev-parse HEAD`)
> **License:** <what the LICENSE file / in-file grant actually says — check both>
> **Size:** <n> tracked files (`git ls-files | wc -l`)
> **Read this pass:** <what you actually opened, honestly>

## 1. What this repo is
Two or three sentences. What problem it solves, and what kind of artifact it is
(runtime / plugin collection / methodology / library / spec).

## 2. Mechanism inventory
The core table. One row per separable mechanism. Aim for completeness over prose.

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|

## 3. Transferable to omp-custom
Only rows that survive rule 4. Each names its OMP attachment point.

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|

Verdict ∈ ADOPT | ADAPT | DEFER | REJECT. A DEFER needs a named trigger.

## 4. What this repo does that we deliberately will not
The negative findings. Often more valuable than the positive ones — they price the
alternative we rejected. Say why, not just that.

## 5. Contradictions with our current spec or registry
Anything here that makes a recorded claim in `spec/00-16`, `spec/key/*`, or `registry/*`
false or overstated. Quote the claim, then the evidence. This is the highest-value section:
a wrong recorded fact is inherited as a constraint by every future maintainer.

## 6. Cost profile
What adopting each §3 row actually costs, per the tiers in rule 5. If a number is an
estimate, say "estimate" and give the basis.

## 7. Coverage and limits  (MANDATORY)
- Files read in full:
- Files sampled (head/grep only):
- **Not opened:** ...
- Claims that need a live run before use:
- Anything you suspect but could not verify:
```

---

## Anti-patterns

- **Folder-shape envy.** "They organize skills into categories, we should too." Structure is
  not a mechanism. Ask what *executes* differently.
- **Star-count reasoning.** Popularity is not evidence about our workflow.
- **Recommending their runtime.** OMP is the only runtime. A loop controller, scheduler, or
  worktree manager from an upstream is out of scope by constraint, not by preference —
  extract the *craft* inside it instead.
- **Unpriced quality claims.** "Improves review quality" with no measurement and no cost is
  the exact pattern that produced nine inert YAML files.
- **Confident summary of an unread file.** The single most damaging output available here.
