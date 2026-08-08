# spec/key — Decision Layer

> **What this folder is.** `spec/00`–`spec/16` describe *what omp-custom must be* and
> why, verified against OMP source. `spec/key` is the layer above that: it records the
> **decisions** — which upstream mechanism was taken, in what form, where it attaches to
> an OMP primitive, and what it costs in tokens.
>
> Everything here is a decision or the evidence for one. Nothing here is a runtime file.

---

## Why this layer exists

The spec answers *"is this correct?"*. It does not answer *"where did this shape come
from, and is it the best available shape?"* — the question that matters when you are
assembling a workflow out of seventeen upstream repositories.

Without this layer, three failure modes recur:

1. **Re-litigating settled choices.** A mechanism is rejected in round 3, reappears in
   round 6 because the rejection lived in a review document nobody re-reads.
2. **Cargo-culting structure.** A repo's folder layout gets copied because it looks
   organized, not because its mechanism maps to something OMP executes. This is exactly
   how `.omp/policies/` and `.omp/schemas/` were born — nine YAML files, 581 lines,
   zero runtime consumers.
3. **Unpriced adoption.** A mechanism is adopted for its quality benefit with no record
   of what it costs per turn, per spawn, or per session. Costs compound silently.

`spec/key` closes all three: every decision names its source, its OMP attachment point,
its token cost, and the condition under which it would be reversed.

---

## Contents

| File | What it decides |
|---|---|
| `00-method.md` | How upstreams were analyzed, what counts as evidence, how a claim is graded |
| `01-dna.md` | **The DNA.** Per-layer structural blueprint: for each part of the workflow, which shape applies and why |
| `02-repo-synthesis.md` | Per-repo verdicts: what each of the seventeen upstreams contributes, its OMP attachment point, and the 11 proposed deltas |
| `03-token-quality-model.md` | The cost/quality decision model — how a token trade-off is judged |
| `04-decision-log.md` | Numbered, dated decisions with reversal conditions |
| `05-coverage-audit.md` | **Blind-spot audit.** OMP's real surface vs what the spec covers — 9 material gaps, 2 corrections |
| `06-investment-thesis.md` | **What to build, and why.** Six gates that decide whether a mechanism earns its place; ranked roadmap; MCP / semantic search / memory verdicts |
| `dossiers/` | Per-repo deep analysis (the evidence `02` summarizes) |

Read `01-dna.md` first if you want the architecture. Read `04-decision-log.md` first if
you want to know whether something was already decided. Read `02-repo-synthesis.md` if you
want to know whether a given upstream has anything left to give. Read `05-coverage-audit.md`
before implementing anything — it lists what the spec has not seen, and two places where a
recorded claim is wrong.

---

## Relationship to the rest of the repo

```
plan.md                  original intent (frozen)
   │
spec/00-16               correctness specification, OMP-source-verified
   │
spec/key/                ← this layer: decisions + upstream provenance
   │
spec/phases/             execution order
   │
template/.omp/           the runtime surface OMP actually discovers
registry/                machine-readable ledger (adoption, rejection, licenses)
```

`spec/key` and `registry/` overlap deliberately and differ in purpose. `registry/` is
machine-readable and answers *"what is installed and under what license"*. `spec/key` is
human-readable and answers *"why, and what was the alternative"*. When they disagree,
`registry/` is authoritative for facts and `spec/key` is authoritative for reasoning.

---

## Standing constraints these decisions operate under

Not negotiable within this layer; they come from `plan.md` and `spec/01`:

1. **OMP is the only runtime.** No second orchestrator, scheduler, or worktree manager.
2. **OmniRoute is the only gateway.** No direct provider calls.
3. **Every file in `template/.omp/` is discovered by OMP, or it does not live there.**
4. **Optimize tokens per accepted outcome** — never tokens alone.
5. **No mechanism without a named OMP attachment point.** A mechanism that cannot name
   one is documentation, or it is a defect.

Constraint 5 is the one that would have prevented the `policies/` class of error, and it
is the primary filter every candidate in `02-repo-synthesis.md` is run through.
