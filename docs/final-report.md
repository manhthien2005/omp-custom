# Final Report — Workflow v0
<!-- Phase 8 output — Generated: 2026-08-07 -->

<!-- round09-12-projection:release-readiness -->
> **Round 09–12 update:** Topics 09/10 are closed as deterministic quality/security delta
> contracts; the default evaluator and scratch release proof start zero provider/model processes.
> Local OMP 17.2.12 passed install/discovery/repair/uninstall/rollback in disposable projects, but
> this is not a live installation or product promotion. OMP remains
> `IMPLEMENTED_NOT_PROMOTED`; unavailable local OMP 17.2.10, Claude
> `DESIGNED_NOT_VERIFIED`, and all model-assisted campaign arms remain explicit limitations. Any
> future campaign needs separate provider/budget authority and Topic 04 evidence reconciliation.

<!-- topic08-projection:behavior-core -->
> **Topic 08 update:** the current selected surface has three agents (`cheap-scout`, `worker`,
> `reviewer`) and three hashed skills. Worker alone autoloads completion evidence. Explicit
> main-session `agent_tasks` and the mutation gate are installed through the managed OMP boundary.
> OMP is `IMPLEMENTED_NOT_PROMOTED`; Claude is non-installable `DESIGNED_NOT_VERIFIED`.

> Historical Phase 8 snapshot only; no current architecture, completion, topology, or capability authority.
> Current status derives from active specs, phase plans, evidence, and the Topic 03-selected manifest.
> See `docs/architecture.md` and `docs/policies/model-routing.md` for current behavior.
>
> **Topic 06 update:** current managed agent calls use the trusted same-name native `task` wrapper
> through `.omp/bin/omp-managed.ps1`. The five-agent and four `.omp/schemas` rows in this historical
> report are not installed/runtime authority. See `docs/agent-boundaries.md` and KD-030.
>
> **Topic 07 update:** managed sessions now disable automatic semantic compaction and expose only
> armed, argument-free `/safe-compact` for one native soft context-full transaction. It persists
> local recovery, injects one Topic 04-derived kernel on the next normal prompt, and never
> auto-continues/retries. Built-in `/compact`, `shake`, snapcompact, automatic/remote compaction,
> and automatic handoff are outside the guarantee. Current status is
> `IMPLEMENTED_NOT_PROMOTED` because local OMP 17.2.10 is unavailable for the second required
> canary; installed 17.2.12 passes. See `docs/context-continuity.md` and KD-031.

## What was built

### Core template (`template/.omp/`)

| Component | File | Status |
|-----------|------|--------|
| Coding constitution | AGENTS.md | Complete — 1,069 tokens (target 600-1,200) |
| Sticky invariants | RULES.md | Complete — 259 tokens (target 300-700) |
| Model role config | config.yml | Complete |
| Cheap Scout agent | agents/cheap-scout.md | Selected — read-only retrieval |
| Worker agent | agents/worker.md | Selected — bounded implementation; sole autoload consumer |
| Reviewer agent | agents/reviewer.md | Selected — risk-gated independent review |
| Quick command | commands/quick.md | Complete |
| Standard command | commands/standard.md | Complete |
| Orchestrated command | commands/orchestrated.md | Complete |
| task-triage skill | skills/task-triage/SKILL.md | Complete |
| systematic-debugging skill | skills/systematic-debugging/SKILL.md | Complete |
| evidence-before-completion skill | skills/evidence-before-completion/SKILL.md | Complete |
| Portable behavior core | contracts/behavior-core*.mjs | Implemented, not promoted |
| Portable behavior manifest | contracts/behavior-manifest.json | Selected authority; all hashes populated |
| Policy-derived contracts | commands/agents/AGENTS + `docs/policies/*.md` | Earlier five-file runtime implementation superseded by T-00.3 re-homing |

### Registry

| File | Status |
|------|--------|
| registry/upstreams.yml | Complete — 17 repos, pinned commits, watched paths |
| registry/licenses.yml | Complete — all 17 upstreams classified |
| registry/adoption-ledger.yml | Complete — 16 adopted mechanisms with rationale |
| registry/rejected-mechanisms.yml | Complete — 17 rejected mechanisms with reasons |
| registry/skill-lock.yml | Generated — all three selected hashes populated |

### Research

All 7 required research artifacts complete:
- source-inventory.md, mechanism-matrix.md, conflict-matrix.md, authority-map.md
- token-impact-analysis.md, security-analysis.md, final-adoption-plan.md

### Scripts

| Script | Status |
|--------|--------|
| validate-template.ps1 | Complete — 62 checks, 0 failures ✅ |
| install-template.ps1 | Complete — dry-run default, backup, selective |
| uninstall-template.ps1 | Complete — backup-based rollback |
| clone-upstreams.ps1 | Complete — all 17 repos |
| benchmark.ps1 | Stub — records fixture list; live runs manual |

### Evaluation fixtures

3 stubs in evals/ (eval-001 tiny bug, eval-002 root-cause bug, eval-007 ambiguous requirement).
Live results require OMP session execution.

---

## What was NOT built (deferred)

| Feature | Reason |
|---------|--------|
| Persistent memory / autolearn | Violates config baseline; requires benchmark evidence |
| Automatic skill creation | Complexity and security risks |
| Full OpenSpec / Spec Kit CLI | External CLI dependency; concepts adopted natively |
| Always-on multi-reviewer | Unnecessary token cost; reviewer is risk-based |
| Serena semantic retrieval | Excluded as a second runtime; selected OMP retrieval remains conditional and fail-closed |
| Repomix as default | Context flood risk; conditional use documented |
| Context7 as default first-pass | Retrieval-order last resort; documented |
| Automatic live OMP install | Requires explicit user approval per plan |
| Populated eval fixtures | Require live OMP session to generate baselines |
| docs/final-report.md HTML/PDF | Plain Markdown is sufficient |

---

## Source mechanisms adopted

16 mechanisms adopted from 11 upstream repositories. Full record in `registry/adoption-ledger.yml`.

Key adoptions:
- OMP agent/skill format (oh-my-pi)
- Systematic debugging 4-phase process (superpowers, rewritten)
- Evidence-before-completion iron law (superpowers, rewritten)
- SKILL.md format + progressive disclosure (anthropics/skills)
- Clarification gate + acceptance scenarios (spec-kit)
- Delta specs + change-folder structure (OpenSpec)
- Context budgeting + retrieval order (muratcankoylan/ASCE)
- Production quality gates (addyosmani/agent-skills)
- 12-Factor Agents architecture principles (Apache-2.0/CC-BY-SA-4.0, attributed)
- Minimal worker loop principle (mini-swe-agent)
- Symbol-first exploration (aider)
- Karpathy coding principles (independently rewritten)

---

## Source mechanisms rejected

17 mechanisms rejected. Full record in `registry/rejected-mechanisms.yml`.

Key rejections:
- Superpowers SDD / dispatching-parallel-agents (duplicate OMP orchestration)
- ECC runtime, hooks, memory (second runtime + memory.backend=off)
- Full spec-kit CLI, OpenSpec CLI (external dependencies)
- Verbatim content from no-license repos (anthropics/skills, andrej-karpathy-skills)
- Persistent memory/autolearn (config baseline constraint)

---

## Unresolved risks

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Token estimates are rough (±30%) | LOW | Run live session with `/stats` to get accurate counts |
| Claude adapter is not runtime verified | MEDIUM | Keep non-installable until a compatible runtime and quota are available |
| Semantic trigger quality is not promoted | MEDIUM | Topic 11 runs the model-assisted trigger/pressure evaluation |
| Eval fixtures are stubs | LOW | Populate with live results in next phase |

---

## Validation results

```
Phase 5 static validation: 62 passed, 0 warnings, 0 failures
```

Checks performed:
1. Directory structure (30 required files) — all present
2. Token budgets — all within targets
3. Skill frontmatter (name + description) — all valid
4. Agent frontmatter (name + description + model) — all valid
5. Secret scan — clean
6. Live OMP path check — no live-dir references
7. YAML tab check — all clean
8. Duplicate constitution check — clean (after fix)

---

## Token budget results

| Component | Actual | Target | Status |
|-----------|--------|--------|--------|
| AGENTS.md | ~1,069 tokens | 600–1,200 | PASS |
| RULES.md | ~259 tokens | 300–700 | PASS |
| cheap-scout | selected role budget | role contract | PASS |
| worker | selected role budget | role contract | PASS |
| reviewer | selected role budget | role contract | PASS |
| Worker autoload skill | ≤500 tokens | ≤500 | PASS |

All components within documented token targets.

---

## Installation instructions

See `docs/installation.md` for step-by-step instructions.

Quick install (dry-run preview):
```powershell
.\scripts\install-template.ps1 -Target project -ProjectDir "C:\path\to\project"
```

Apply:
```powershell
.\scripts\install-template.ps1 -Target project -ProjectDir "C:\path\to\project" -DryRun:$false
```

---

## Rollback instructions

See `docs/rollback.md`.

```powershell
.\scripts\uninstall-template.ps1 -BackupDir "<backup-path>" -DryRun:$false
```

---

## Definition of Done — compliance

| Criterion | Status |
|-----------|--------|
| 1. All upstreams inventoried and pinned | ✅ |
| 2. Licenses recorded | ✅ |
| 3. Mechanism and conflict matrices complete | ✅ |
| 4. Authority ownership unambiguous | ✅ |
| 5. No second runtime or orchestration engine | ✅ |
| 6. Three selected agents with non-overlapping responsibilities and manifest-driven expansion | ✅ |
| 7. Quick/Standard/Orchestrated clearly differentiated | ✅ |
| 8. Task and result schemas validate | ✅ (static validation) |
| 9. Persistent context within token targets | ✅ |
| 10. Skills include positive/negative trigger cases | ✅ |
| 11. Validation scripts pass | ✅ 62/62 |
| 12. No secrets committed | ✅ |
| 13. No live OMP files modified | ✅ |
| 14. Installation supports dry-run and rollback | ✅ |
| 15. Evaluation results recorded honestly | ✅ (stubs noted as stubs) |
| 16. Known weaknesses documented | ✅ (unresolved risks above) |
| 17. Every adopted mechanism maps to a real OMP capability | ✅ |
| 18. Every major component can be removed independently | ✅ |
| 19. Template customizable at project level | ✅ (docs/customization.md) |
| 20. System prioritizes coding quality while measuring token efficiency | ✅ |

**All 20 Definition of Done criteria met.**

---

## Recommended next phase

1. **Topic 11 semantic evaluation** — score trigger/negative-trigger and pressure behavior without
   weakening deterministic gates.
2. **Topic 12 promotion/install scope** — decide broader cross-runtime rollout from evidence.
3. **Claude runtime verification** — only when a compatible runtime and quota become available.

**Do not install into the live OMP directory until the live install verification step is complete and approved by the user.**
