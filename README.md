# omp-workflow-template

A production-grade, OMP-native workflow template.

## Status

**Workflow v0 — in construction.**

## What this is

A carefully designed set of OMP configuration files — agents, workflows, skills, schemas, and policies — extracted from research across leading AI coding-agent repositories and reimplemented natively for OMP.

OMP remains the sole runtime and orchestration engine. OmniRoute remains the sole model gateway. No second runtime is introduced.

## What this is not

- A copy of any external framework.
- A second coding agent layered on OMP.
- An automatic installer that touches live OMP files without review.

## Structure

```
template/.omp/     — installable OMP configuration
docs/              — architecture, research, token strategy, installation
registry/          — upstream provenance, licenses, adoption ledger
evals/             — evaluation fixtures and deterministic tests
scripts/           — install, validate, benchmark, rollback tooling
_research/         — upstream clones (gitignored; tracked via registry)
```

## Installation

See `docs/installation.md` — supports dry-run, selective install, and rollback.

## Research provenance

All adopted mechanisms are recorded in `registry/adoption-ledger.yml` with source, license, and rationale.
