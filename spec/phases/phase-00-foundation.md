# Phase 00 — Foundation

> OPUS PROPOSED SPEC v1 | Establish ground truth before changing anything.

**Depends on**: nothing
**Blocks**: phase-01

---

## Objective

Freeze the facts. Record the exact OMP commit the template's runtime claims were
verified against, correct every documentation claim that contradicts verified
behavior, and reclassify `policies/` and `schemas/` as documentation.

No behavior changes in this phase. This is the phase that makes later phases
falsifiable.

---

## Rationale

Every downstream fix depends on knowing which OMP behaviors are real. The current
repository states things that are not true (schemas enforced, policies loaded,
validation implies correctness). Fixing code before fixing the record means later
work builds on the same false premises.

---

## Tasks

### T-00.1 — Pin the OMP commit

Record in `registry/upstreams.yml` for `oh-my-pi`: `pinned_commit`, `clone_date`,
`tier: runtime-authority`, and the full `watched_paths` list from §14-C.

**Acceptance**: `upstreams.yml` contains a resolvable SHA and ≥13 watched paths, each
mapping to a claim in `02-runtime-semantics.md`.

### T-00.2 — Record the verified-claims ledger

Create the compatibility record from §14-H: `omp_verified_version`,
`omp_verified_commit`, `verified_claims`.

**Acceptance**: every claim in `02-runtime-semantics.md` §A appears with its source
file path.

### T-00.3 — Reclassify policies as documentation

Add a header to each `template/.omp/policies/*.yml`:

> This file is **documentation**. OMP has no policy loader and no `policy://`
> scheme. Its content is authoritative for humans and is inlined into command and
> agent prose at authoring time. Nothing reads this file at runtime.

**Acceptance**: all five policy files carry the header. No file claims runtime effect.

### T-00.4 — Reclassify schemas as documentation

Add an equivalent header to each `template/.omp/schemas/*.yml`, stating that runtime
enforcement happens through `outputSchema` inlined in the `task` call, and that these
files are the human-authoritative source for that shape.

**Acceptance**: all four schema files carry the header.

### T-00.5 — Correct the documentation claims

Fix, in `docs/**`, `README.md`, and `docs/final-report.md`:

- any statement that schemas or policies are enforced at runtime
- any statement that `validate-template.ps1` passing means the workflow works
- the installer invocation examples that use non-existent parameters (`-TargetDir`)
- the claim that `benchmark.ps1` benchmarks anything

**Acceptance**: no doc statement contradicts `02-runtime-semantics.md`. Installer
examples match the script's real parameters.

### T-00.6 — Fix the agent-result schema contradiction

`agent-result.schema.yml` lists `verification_results` as optional while a field rule
requires it for `status: completed`. Make the conditional requirement explicit.

**Acceptance**: the schema states the conditional requirement unambiguously (F-30).

### T-00.7 — Record the resolved decisions

Record DR-1 … DR-7 (§README-10) with their evidence-based resolutions, so later
phases do not relitigate them.

**Acceptance**: each decision has a resolution and a source-file citation.

---

## Deliverables

- Updated `registry/upstreams.yml` with pin + watched paths
- Compatibility/verified-claims record
- Nine reclassification headers (5 policies + 4 schemas)
- Corrected docs
- Fixed `agent-result.schema.yml`
- Decision record

---

## Verification

```powershell
# All watched paths exist in the cloned upstream
# (run from repo root; expects _research/upstreams/oh-my-pi present)
.\scripts\validate-template.ps1 -Verbose
```

Manual checks:
1. Every watched path in `upstreams.yml` resolves to a real file in the pinned clone.
2. Grep `docs/` for "enforce", "validated", "benchmark" — each hit is accurate.
3. Grep for `-TargetDir` — zero hits outside a changelog note.

---

## Exit Criteria

- [ ] OMP pinned to an exact SHA with watched paths recorded
- [ ] All verified claims traceable to a source file
- [ ] Policies and schemas labeled documentation-only
- [ ] No documentation claim contradicts verified runtime behavior
- [ ] `agent-result` conditional requirement explicit
- [ ] DR-1 … DR-7 resolved and recorded

---

## Risks

| Risk | Mitigation |
|---|---|
| Correcting docs makes the project look less complete | Accuracy is the point; completeness claims that are false are worse than gaps |
| Pinned commit becomes stale immediately | Expected; §14-D defines the controlled update process |
| Reclassification reads as "these files are useless" | Header states they are human-authoritative, just not runtime-loaded |
