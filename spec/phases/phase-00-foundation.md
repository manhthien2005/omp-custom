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

Add an equivalent header to each `template/.omp/schemas/*.yml`, stating that:
- runtime enforcement happens through the worker agent's **`output:` frontmatter** (the canonical schema source per DR-2);
- caller task `outputSchema` is an explicit per-call override, not the default path;
- these YAML files are the human-authoritative source that generates the inline `output:` blocks; nothing reads them at runtime.

**CR-28 correction:** the header must NOT say "enforcement happens through `outputSchema` inlined in the task call" — that inverts DR-2. The canonical enforcement path is `agent output: frontmatter → YieldTool validator`. Caller `outputSchema` is the override/escape-hatch.

**Acceptance**: all four schema files carry the corrected header. No schema file claims caller `outputSchema` is the primary enforcement path.

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
phases do not relitigate them. Each DR must explicitly separate **runtime_facts**
(source/test-backed — eligible for "verified from source" label) from **design_objectives**
and **normative decisions** (not source-provable; require explicit rationale instead).
See CR-25.

**Acceptance**: each decision has a resolution; runtime facts carry source citations;
normative decisions carry explicit rationale; no source citation used to justify a
purely normative choice.

---

## Experiment Tasks (Phase-Gate Required)

These experiments resolve open questions that later phases depend on. **Phase 00
cannot close and dependent phases cannot begin until each experiment has a recorded
artifact.** Record: exact OMP SHA, OS/runtime, provider/gateway version, raw
(sanitized) output, interpretation, and which decision is changed or retained.

### T-00.E1 — Schema precedence and provider enforcement

Verify `resolveSchema` precedence and provider strict-mode behavior at the pinned SHA.

Test cases:
1. agent `output:` only (no caller `outputSchema`)
2. caller `outputSchema` only (no agent `output:`)
3. both present with intentionally different sentinel schemas — confirm caller wins
4. session-level `outputSchema` only — confirm session is used when neither caller nor agent is set
5. `schemaMode: strict` — confirm provider enforces rather than permissively accepts

**Artifact**: structured-output experiment transcript with binary result per case.

**Blocks**: phase-01 T-01.7 implementation; DR-2 runtime_facts section.

### T-00.E2 — Model-role merge order

Verify how missing/unknown model roles resolve in the OMP main session and for workers. This is the **canonical fallback test matrix** — `spec/09-model-routing.md §F` references these cases.

Test cases:
1. known built-in role with config present — record selected model
2. known custom role (`@tech-lead`) with config present — record selected model
3. referenced custom role absent from config — record selected model or error
4. arbitrary `@unknown` pattern (not a built-in, not in config) — record parser/resolver terminal behavior (error vs silent fallback)
5. role resolves to unavailable provider/model — record error or fallback (distinguishes alias-resolution success from downstream provider failure)
6. **user-level** role vs **project-level** role with same name — assert which wins (project beats user?) by defining the role differently at each level
7. role name collision with OMP built-in (e.g., `default`) — custom role wins or OMP built-in wins?
8. main-session model selection path (coordinator) vs worker agent model selection — verify they use the same resolver or document the difference

**Artifact**: model-selection transcript per case; final statement for §09/§14/§15 normalization.

**Blocks**: DR-1 and DR for model routing (§09); §14/§15 consistency.

### T-00.E3 — Isolation backend, capture-first control surface, and artifact lifecycle

**CR-31/CR-32 escalation:** this is no longer a backend smoke test. The capture-first architecture in `08-isolation-and-concurrency.md §E-7/§E-9/§E-10` depends on settings that OMP defaults *against* (`task.isolation.apply` default `true`), and on artifact durability that OMP does not guarantee for nested repositories. T-00.E3 is the experiment that either proves the architecture or forces the documented degradation. It blocks all parallel implementation.

Baseline cases (original scope):
1. standard workflow (single Implementer, `isolated: false`) — confirm parent worktree unchanged after success
2. orchestrated workflow (parallel Implementers, `isolated: true`) — confirm isolation backend engages
3. isolation backend unavailable — record fallback behavior
4. non-git repository — record fallback behavior

#### E3-A — Settings control surface (CR-30)

Assert the effective values are readable at runtime and that no per-item `apply` exists:

```
effective task.isolation.mode  != "none"
effective task.isolation.apply == false
```

Also confirm that passing `apply: false` inside a task **item** is silently stripped (arktype `"+": "delete"`), not honored — i.e. that the settings layer is the only control point.

**Records**: how `/orchestrated` reads effective settings (the exact mechanism the preflight will use).

#### E3-B — Capture-only root patch durability

```
isolated: true, apply=false
worker edits root repo, exits 0
→ parent working tree unchanged
→ root patch path present in result summary
→ patch file still readable AFTER worktree teardown
```

#### E3-C — Branch mode (if `merge: branch` is selected)

```
branch retained, not merged
Tech Lead can integrate it later by name
```

#### E3-D — Parallel capture

Two near-simultaneous isolated workers:

```
parent unchanged until the Tech Lead begins integration
neither worker's changes visible in parent before integration
```

#### E3-E — Sequential integration ordering (CR-29)

Integrate by **original task-list index**, not completion order:

```
task[0] artifact → task[1] → task[2]
```

Arrange for `task[2]` to finish first; assert integration still runs 0 → 1 → 2.

#### E3-F — Conflict semantics

```
apply task[0] → succeeds
apply task[1] → conflicts
→ integration STOPS (task[2] not attempted)
→ parent retains task[0] only
→ task[1] and task[2] artifacts remain readable on disk
```

#### E3-G — Nested repository (CR-32 — decisive)

```
worker edits root repo AND a nested git repo / submodule
apply=false, exit 0
```

Record exactly:
- does the result summary mention the nested repo at all when the root also changed?
- is any nested patch file materialized under the artifacts dir?
- after teardown, can the parent locate and `git apply` the nested change?

**Expected per source reading (OMP v17.2.10):** no — `persistNestedPatches()` is reachable only from `isolationRecoveryHint()` (failure path), and the `apply=false` summary's `else if` chain reports only `patchPath` when the root also changed. If the experiment confirms this, the CR-32 Option A exclusion (nested-repo mutation FORBIDDEN for parallel isolated Implementers) stands as normative. If a future OMP version materializes them, the exclusion may be lifted with recorded evidence.

#### E3-H — Config precedence and preflight refusal (CR-31 — decisive)

```
global apply=true + project apply=false  → effective false   (project wins)
project config absent, global/default true → effective true
  → /orchestrated preflight MUST refuse the parallel path
  → falls back to sequential non-isolated, and discloses it
```

Also record whether a CLI/runtime overlay can override project config — this is why the preflight reads *effective* values rather than trusting the installed file.

**Artifact**: isolation behavior transcript per scenario, including the E3-G nested-repo determination and the E3-H precedence table.

**Blocks**: phase-02 T-02.2 (preflight), T-02.2b (integration order), T-02.9 (nested-repo exclusion); §08 §E-7/§E-9/§E-10; §12 §C config-ownership policy.

### T-00.E4 — Rule sentinel propagation

Verify whether a RULES.md rule actually appears in a spawned worker's system prompt.

Procedure:
1. Add a unique sentinel rule to `RULES.md`:
   `RULE_SENTINEL_7F3A: before claiming task complete, emit the phrase QUALITY_GATE_SEEN.`
2. Spawn a worker without `autoloadSkills` for a corresponding skill.
3. Capture child system prompt or debug rule buckets (A: prompt-visible; B: stored but not visible; C: not discovered).
4. Observe worker behavior.
5. Compare token cost: forwarded RULES.md vs autoloadSkills.

**Artifact**: child prompt/rule-bucket capture + behavioral observation + token diff.

**Discriminator**:
- A → rules propagate and are prompt-visible; DR-4 updated accordingly
- B → rules propagate but are not prompt-visible; `autoloadSkills` still required
- C → parent did not discover RULES.md; investigate discovery mode

**Blocks**: DR-4 final justification; phase-02 worker initialization.

### T-00.E5 — LSP allowlist validation (CR-17)

Verify that `task.enableLsp = true` baseline setting actually makes the `lsp` tool callable within spawned subagents when `lsp` is present in the agent's `tools:` allowlist.

Procedure:
1. Spawn an agent (e.g., explorer) with `tools: [read, grep, glob, lsp]` and `task.enableLsp = true` baseline.
2. Instruct the agent to call `lsp references` on a known symbol.
3. Capture whether the tool call succeeds or is rejected as unavailable.
4. Compare with control: same agent without `lsp` in allowlist (expect rejection).

**Artifact**: LSP tool availability transcript per case (with-allowlist vs without-allowlist).

**Discriminator**:
- Success with `lsp` in allowlist → phase-01 T-01.3 proceeds safely
- Rejection despite allowlist → investigate `task.enableLsp` propagation or allowlist gating logic

**Blocks**: phase-01 T-01.3 (LSP allowlist fix for explorer, implementer, reviewer).

---

## Deliverables

- Updated `registry/upstreams.yml` with pin + watched paths (SHA `3a8591a8af5b6d200088d12ca75a5517cb064fa8`)
- Compatibility/verified-claims record
- Nine reclassification headers (5 policies + 4 schemas)
- Corrected docs
- Fixed `agent-result.schema.yml`
- Decision record (runtime_facts separated from normative decisions per CR-25)
- Experiment artifacts: T-00.E1 through T-00.E4 recorded transcripts

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

- [ ] OMP pinned to exact SHA `3a8591a8af5b6d200088d12ca75a5517cb064fa8` with watched paths recorded
- [ ] All verified claims traceable to a source file
- [ ] Policies and schemas labeled documentation-only
- [ ] No documentation claim contradicts verified runtime behavior
- [ ] `agent-result` conditional requirement explicit
- [ ] DR-1 … DR-7 resolved and recorded with runtime_facts separated from normative decisions
- [ ] **T-00.E1 artifact present** (schema precedence + provider enforcement)
- [ ] **T-00.E2 artifact present** (model-role merge order)
- [ ] **T-00.E3 artifacts present for ALL cases E3-A … E3-H** (isolation backend, capture-first settings control, root patch durability, branch mode, parallel capture, task-index integration order, conflict stop-preserve-report, nested-repo artifact durability, config precedence + preflight). E3-A, E3-G and E3-H are BLOCKING for phase-02 parallel implementation.
- [ ] **T-00.E4 artifact present** (rule sentinel propagation)
- [ ] **T-00.E5 artifact present** (LSP allowlist validation)

---

## Risks

| Risk | Mitigation |
|---|---|
| Correcting docs makes the project look less complete | Accuracy is the point; completeness claims that are false are worse than gaps |
| Pinned commit becomes stale immediately | Expected; §14-D defines the controlled update process |
| Reclassification reads as "these files are useless" | Header states they are human-authoritative, just not runtime-loaded |
