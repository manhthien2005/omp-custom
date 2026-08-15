# Authority Map

> Authority boundary: This research file is source/research evidence.
> Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology,
> dispatch, review mechanism, or capability behavior.
> Current design and execution authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.

<!-- Generated: 2026-08-07 — Phase 2 -->

Historical research input only; no current design, execution, routing, fallback, topology, or capability authority.
Current authority lives in the accepted design, key decisions, active specs, and Topic 03-selected manifest.
Labels below record the 2026-08-07 research pass.

## Historical design rule (superseded)

Each concern has exactly ONE primary authority. If an upstream source conflicts with the authority, the authority wins. If evidence shows the authority is wrong, amend this document before changing any implementation.

---

## Authority assignments

| Concern | Primary Authority | Rationale |
|---------|------------------|-----------|
| **Runtime and orchestration** | OMP (`oh-my-pi`) | OMP is the coding-agent runtime. Every other upstream is either consumed by OMP or is a pattern source only. |
| **Model gateway and account routing** | OmniRoute | Sole model gateway. `omniroute/codex/gpt-5.6-sol-high` is the current model. No direct provider API keys in template. |
| **Agent definition format** | OMP (`.omp/agents/*.md` frontmatter) | Native discovery and parsing. `name`, `description`, `model`, `tools`, `spawns`, `thinking-level`, `output` fields are OMP-defined. |
| **Skill format and discovery** | OMP (`SKILL.md` in `.omp/skills/*/`) | Native provider requires `name` + `description`. Progressive disclosure via `skill://` URLs is OMP-native. |
| **Context-file injection (AGENTS.md / RULES.md)** | OMP | Native provider priority 100. Project `.omp/AGENTS.md` and `RULES.md` are the authoritative injection points. |
| **Compaction and context window management** | OMP (shake strategy) | Shake compaction is the configured strategy. All compaction decisions go through OMP session maintenance. |
| **Task isolation** | OMP (`task.isolation.*`) | `mode=auto`, `apply=true`, `merge=patch`. No external worktree management. |
| **Config layering (global → project → overlay)** | OMP (`config.yml` precedence) | Global (`~/.omp/agent/config.yml`) → project (`.omp/config.yml`) → `PI_CONFIG_FILES` overlays → runtime. |
| **Coding constitution** | Karpathy principles, implemented locally | Four principles independently rewritten: think before coding, simplicity first, surgical changes, goal-driven execution. Lives in `template/.omp/AGENTS.md`. |
| **Control-flow and context ownership** | 12-Factor Agents principles | Own prompts, own context, own control flow, structured outputs, compact errors. Architecture principles only — no runtime layer. |
| **Specification: clarification and acceptance** | Spec Kit | Clarification gate, user stories with priority, acceptance scenarios (Given/When/Then), success criteria. |
| **Specification: brownfield change lifecycle** | OpenSpec | Delta specs (ADDED/MODIFIED/REMOVED), change-folder structure, archive lifecycle. Synthesized with Spec Kit into one system. |
| **Implementation discipline** | Selected Superpowers mechanisms (rewritten) | systematic-debugging (4-phase), evidence-before-completion. Both rewritten as OMP-native skills. |
| **Production quality gates** | Selected Addy Agent Skills mechanisms | API compatibility, security, performance, ADR, release/rollback readiness. Extracted into `quality-gates.yml`. |
| **Context and token policy** | Context Engineering Skills (muratcankoylan) | Budget per component, progressive retrieval order, no transcript forwarding, structured results. |
| **Skill packaging and triggers** | Anthropic Skills format | `name` + `description` frontmatter, progressive disclosure, positive/negative trigger design. |
| **Model routing policy** | Selected ECC patterns | Token/context profiles translated into `model-routing.yml`. OmniRoute is the execution layer. |
| **Complexity governor** | mini-SWE-agent principles | Minimal worker loop, small tool surface, explicit termination. Applied to Implementer agent contract. |
| **Repository-map and code exploration** | Aider principles | Symbol-first exploration, references before full-file reads, token-budgeted context. Applied to Explorer agent contract. |
| **Evaluation** | Promptfoo (external) + local deterministic tests | Local `validate-template.ps1` for structural checks. Promptfoo optional for model-graded evaluation. |
| **Upstream governance** | This template's registry | `registry/upstreams.yml`, `registry/adoption-ledger.yml`, `registry/rejected-mechanisms.yml`. |

---

## Second-authority assignments (for disputed areas)

| Concern | Primary | Fallback |
|---------|---------|---------|
| Specification: clarification gate | Spec Kit | Task-triage skill (triggers clarification) |
| Code understanding: symbol lookup | OMP LSP | Explicit non-LSP contract, reconciled and validated before continuation |
| Context management: offloading | OMP shake compaction | Context-budget policy filesystem-offloading guidance |
| Documentation retrieval | Local docs first | Context7 (last resort in retrieval order) |

---

## Explicitly excluded authorities

These sources were studied but have **no authority** over any concern in this template:

| Source | Excluded from | Reason |
|--------|--------------|--------|
| superpowers SDD | Orchestration | Duplicate of OMP task subsystem |
| superpowers finishing-branch | Git workflow | Duplicate of OMP task isolation |
| ECC hooks | Hook system | OMP hooks are the authority; ECC hooks not installed |
| ECC memory / instinct | Memory | memory.backend=off; autolearn=false |
| ECC orchestration runtime | Orchestration | OMP is the sole runtime |
| Full spec-kit CLI | Specification | No external CLI dependency |
| Full OpenSpec CLI | Specification | No external CLI dependency |
| Anthropics skills content | Skill bodies | No license; only format is authoritative |
| andrej-karpathy-skills CLAUDE.md text | Coding constitution | No license; principles rewritten independently |
