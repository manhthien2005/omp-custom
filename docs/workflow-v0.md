# Workflow v0 — Implementation Record
<!-- Documents what was built, decisions made, and known limitations -->

## Status: Complete (awaiting validation pass)

## What was built

### Core template (`template/.omp/`)

| Component | Count | Token budget |
|-----------|-------|-------------|
| AGENTS.md (coding constitution) | 1 | ~850 tokens |
| RULES.md (sticky invariants) | 1 | ~200 tokens |
| config.yml (model roles) | 1 | ~100 tokens |
| Agent definitions | 5 | ~700–1,100 each |
| Workflow definitions | 3 | ~400–700 each |
| Skills (SKILL.md) | 3 | ~1,200–1,800 each |
| Schemas (YAML) | 4 | ~300–600 each |
| Policies (YAML) | 5 | ~300–600 each |

### Registry (`registry/`)

- `upstreams.yml` — 17 upstream repos with pinned commits, watched paths, adopted/rejected mechanisms
- `licenses.yml` — license type and adoption type for each upstream
- `adoption-ledger.yml` — 16 adopted mechanisms with rationale
- `rejected-mechanisms.yml` — 17 rejected mechanisms with reasons
- `skill-lock.yml` — skill content hash registry (hashes populated post-validation)

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

## What was NOT built (deferred to post-v0)

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
| Five agents (not more) | Non-overlapping responsibilities; covers Quick/Standard/Orchestrated flows |
| Coding constitution in AGENTS.md (not per-agent) | Single source of truth; no duplication |
| RULES.md for invariants (not in AGENTS.md) | Sticky attachment keeps invariants visible in long sessions |
| Shake compaction (not snapcompact) | Config baseline default; sufficient for v0 |
| Schema as YAML documentation (not runtime validation) | OMP does not have a built-in schema validator; validate-template.ps1 checks field presence |
| No external spec CLI | Plain Markdown files are portable and require no toolchain |

## Known limitations

1. **Schema validation is documentation-only** — The schemas describe expected structure but are not enforced at runtime. The validate-template.ps1 script checks presence of required fields but not deep type validation.

2. **Token estimates are rough** — All token estimates use ~3.5 chars/token approximation. Actual OMP token counts depend on the model's tokenizer.

3. **Model role defaults to a single model** — All five roles currently point to `omniroute/codex/gpt-5.6-sol-high`. Cost vs. quality trade-offs for explorer/verifier (potentially cheaper models) have not been benchmarked.

4. **Evaluation fixtures are stubs** — The `evals/` directory contains the fixture structure but not populated benchmark tasks. These require a live OMP session to generate meaningful baselines.

5. **Workflow commands vs. OMP skill format** — The workflow `.md` files are documented as "commands" (OMP slash commands). Whether OMP 17.2.10 supports `.omp/workflows/` as a path is untested; they may need to be placed under `.omp/commands/` instead. Verify with `omp --version` documentation.

6. **Skill-lock hashes are null** — `registry/skill-lock.yml` records null hashes at initial construction. The `update-skill-lock.ps1` script (post-v0) will populate them.

## Recommended next phase

After validation and benchmark:
1. Populate eval fixtures with 3–5 representative tasks
2. Run benchmark (Quick vs Standard, with/without reviewer)
3. Evaluate model-role differentiation (explorer/verifier at lower tier)
4. Implement `update-skill-lock.ps1` and `benchmark.ps1`
5. Draft installation guide and run first live install in a test project
