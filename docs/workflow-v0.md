# Workflow v0 — Implementation Record

<!-- round09-12-projection:release-readiness -->
## Round 09–12 closure record

Topics 09 and 10 now close only the delta from the Topic 03–08 baseline: current-candidate review
evidence, critical/important/minor blocking semantics, secret/no-echo handling, destructive
authority, retry identity, and partial-result refusal. They do not add a permanent Verifier,
require Opus, or force Reviewer on every task.

Topic 11 provides a deterministic zero-provider evaluator plus an optional, separately authorized
campaign boundary. Only four verdicts are legal; pilot, synthetic, stale, partial, or missing
telemetry cannot promote. Topic 12 proves the current OMP package in disposable projects only.
Status remains OMP `IMPLEMENTED_NOT_PROMOTED` and Claude non-installable
`DESIGNED_NOT_VERIFIED`; OMP 17.2.10 and model-assisted arms are still unverified.

<!-- topic08-projection:behavior-core -->
Topic 08 supersedes the old role/skill delivery record: the selected manifest contains
`task-triage`, `systematic-debugging`, and `evidence-before-completion`; Worker is the sole
autoload consumer; all release hashes are populated. OMP is implemented but not promoted, while
Claude remains a non-installable design mapping. The older inventory below is historical only.

<!-- topic05-doc:workflow -->
For each bounded retrieval question, the Tech Lead independently chooses Lead/native,
Lead/CodeGraph, Scout/native then Lead, or Scout/CodeGraph then Lead. CodeGraph is optional and
default-off. Failures return to a named native path; Scout never accepts work, and Reviewer
independently corroborates current source. See [`retrieval.md`](retrieval.md).
<!-- Documents what was built, decisions made, and known limitations -->

> Historical Workflow v0 snapshot only; no current topology, dispatch, review, routing, or
> lifecycle authority. Current authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.
> See `docs/architecture.md` and `docs/policies/model-routing.md` for the current three-agent,
> inline-first runtime.
>
> **Topic 06 supersession:** the four YAML schema rows and free-form boundary limitations below
> are historical. Current managed calls use `.omp/bin/omp-managed.ps1`, selected agent `output:`
> contracts, and the executable `.omp/contracts` boundary. See `docs/agent-boundaries.md`.
>
> **Topic 04 supersession:** persistent-memory deferral and the historical five-agent decisions
> below are not current authority. The current design uses local operational state outside Git at
> `<absolute-git-common-dir>/agent-tasks` (plural), or `<project-root>/.agent-tasks` without Git.
> See `docs/task-state.md` and KD-028.
>
> **Topic 07 supersession:** the historical `shake` choice below is not current policy. Managed
> sessions disable automatic semantic compaction; only armed argument-free `/safe-compact` may
> authorize one native soft transaction. See `docs/context-continuity.md` and KD-031.

## Status: Complete (awaiting validation pass)

## What was built

### Core template (`template/.omp/`)

| Component | Count | Token budget |
|-----------|-------|-------------|
| AGENTS.md (coding constitution) | 1 | ~850 tokens |
| RULES.md (sticky invariants) | 1 | ~200 tokens |
| config.yml (model roles) | 1 | ~100 tokens |
| Agent definitions | 3 | selected role-specific budgets |
| Command definitions | 3 | lazy command bodies |
| Skills (SKILL.md) | 3 | ≤900 lazy; ≤500 Worker autoload |
| Portable behavior manifest/core | 1 component | deterministic validation |

The earlier five-file policy implementation was superseded by T-00.3. Executable clauses now
live in commands, agents, main-session instructions, and advisory validation; human references
live under `docs/policies/` outside the installed surface.

### Registry (`registry/`)

- `upstreams.yml` — 17 upstream repos with pinned commits, watched paths, adopted/rejected mechanisms
- `licenses.yml` — license type and adoption type for each upstream
- `adoption-ledger.yml` — 16 adopted mechanisms with rationale
- `rejected-mechanisms.yml` — 17 rejected mechanisms with reasons
- `skill-lock.yml` — generated registry with all three selected release hashes populated

### Research (`docs/research/`)

- `source-inventory.md` — 17 repos, licenses, tiers
- `mechanism-matrix.md` — 60+ mechanisms: source, problem, overlap, token impact, decision
- `conflict-matrix.md` — 12 conflict areas resolved
- `authority-map.md` — 20 concerns, each with exactly one primary authority
- `token-impact-analysis.md` — per-component budgets, workflow-level estimates
- `security-analysis.md` — threat model, mitigations, installation safety
- `final-adoption-plan.md` — implementation sequence, open questions resolved

### Scripts (`scripts/`)

- `validate-template.ps1` — 8 check categories, exits 0/1
- `install-template.ps1` — dry-run default, backup, selective install
- `uninstall-template.ps1` — backup-based rollback
- `clone-upstreams.ps1` — shallow clone all 17 upstreams

## Outside the current selected scope

Per the plan's "Do not initially implement" list:

| Feature | Reason for deferral |
|---------|-------------------|
| Persistent memory / autolearn | Requires benchmark evidence and security review |
| Automatic skill creation | Complexity and security concerns |
| Swarm scheduling | Beyond current scope |
| Full OpenSpec / Spec Kit CLI integration | External CLI dependency |
| Always-on multi-reviewer workflow | Unnecessary token cost |
| Automatic external services | Not applicable to v0 |
| External MCP tools (Serena, Context7 default) | Conditional use only |
| Automatic live OMP installation | Requires explicit user approval |

## Architecture decisions

| Decision | Rationale |
|----------|-----------|
| Three currently selected agents, manifest-driven expansion | Inline-first topology; add a role only when a bounded responsibility justifies it |
| Coding constitution in AGENTS.md (not per-agent) | Single source of truth; no duplication |
| RULES.md for invariants (not in AGENTS.md) | Sticky attachment keeps invariants visible in long sessions |
| Shake compaction (not snapcompact) | Historical Workflow v0 choice; superseded by KD-031 managed `strategy: off` plus `/safe-compact` |
| Schema as YAML documentation (not runtime validation) | OMP does not have a built-in schema validator; validate-template.ps1 checks field presence |
| No external spec CLI | Plain Markdown files are portable and require no toolchain |

## Known limitations

1. **Schema validation is documentation-only** — The schemas describe expected structure but are not enforced at runtime. The validate-template.ps1 script checks presence of required fields but not deep type validation.

2. **Token estimates are rough** — All token estimates use ~3.5 chars/token approximation. Actual OMP token counts depend on the model's tokenizer.

3. **Provider availability remains environmental** — Cheap Scout selects DeepSeek Flash `xhigh`
   with Pro `xhigh` availability fallback; Worker is `high` or selected `xhigh`; Reviewer is
   `xhigh`. Missing DeepSeek quota falls back to Lead retrieval rather than changing authority.

4. **Evaluation fixtures are stubs** — The `evals/` directory contains the fixture structure but not populated benchmark tasks. These require a live OMP session to generate meaningful baselines.

5. **Semantic trigger promotion remains open** — Static fixtures prove roster and boundary shape;
   Topic 11 owns model-assisted trigger and pressure evaluation.

6. **Claude is not runtime-verified** — its complete mapping remains
   `DESIGNED_NOT_VERIFIED` and non-installable until a compatible runtime and quota exist.

## Recommended next phase

After Topic 08 deterministic evidence:
1. Topic 11 evaluates semantic trigger and pressure behavior without changing static authority.
2. Topic 12 owns broader cross-runtime installation and promotion decisions.
3. Claude runtime work waits for an available compatible runtime; it is not an Opus blocker.
