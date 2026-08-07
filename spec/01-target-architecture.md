# 01 — Target Architecture

> OPUS PROPOSED SPEC v1 | Status: awaiting joint review. All claims source-verified against
> `_research/upstreams/oh-my-pi` unless marked OPEN.

---

## 1. Design Goal

A workflow template that is **entirely expressible in OMP-native primitives**, where every
file either (a) is discovered and consumed by OMP at runtime, or (b) is explicitly labelled
a human/build artifact with no runtime role. No third category. The current template's
central flaw is that `policies/` and `schemas/` sit in an unlabelled third category —
they look runtime-loaded, and the agent prompts reference them as if they were.

## 2. The Layer Model

Four layers, each with a single owner and a single reason to change.

```
┌─────────────────────────────────────────────────────────────────┐
│ L4  EVIDENCE            evals/, benchmark results, manifests    │
│     Owner: evaluation   Changes when: measuring outcomes        │
├─────────────────────────────────────────────────────────────────┤
│ L3  DELIVERY            scripts/ (install, validate, benchmark)  │
│     Owner: tooling      Changes when: install contract changes  │
├─────────────────────────────────────────────────────────────────┤
│ L2  RUNTIME SURFACE     template/.omp/**  ← OMP discovers this  │
│     Owner: template     Changes when: agent behavior changes    │
├─────────────────────────────────────────────────────────────────┤
│ L1  OMP + OmniRoute     the only runtime, the only gateway      │
│     Owner: upstream     Changes when: OMP version changes       │
└─────────────────────────────────────────────────────────────────┘
```

**L1 is never modified.** No wrapper runtime, no second orchestrator, no second worktree
manager, no second scheduler. OMP's `task` tool is the only fan-out mechanism; OMP's
`task.isolation.*` is the only isolation mechanism; OmniRoute is the only gateway.

**L2 must contain only files OMP discovers.** Verified discovery surface for a `.omp`
directory (`discovery/builtin.ts`):

| Path | Capability | Verified at |
|---|---|---|
| `.omp/AGENTS.md` | context file (persistent) | `builtin.ts:905-942` |
| `.omp/RULES.md` | rule, forced `alwaysApply` | `builtin.ts:387-416` |
| `.omp/config.yml` | settings | `builtin.ts:879` |
| `.omp/settings.json` | settings | `builtin.ts:484,863` |
| `.omp/agents/*.md` | task agents | `task/discovery.ts:70-138` |
| `.omp/commands/*.md` | slash commands | `builtin.ts:345` |
| `.omp/skills/<name>/SKILL.md` | skills | `builtin.ts:287,296` |
| `.omp/rules/*.md` | rules | `builtin.ts:377` |
| `.omp/prompts/*.md` | prompts | `builtin.ts:435` |
| `.omp/instructions/*.md` | instructions | `builtin.ts:642` |
| `.omp/hooks/<type>/*` | hooks | `builtin.ts:687` |
| `.omp/tools/*` | custom tools | `builtin.ts:736-750` |
| `.omp/extensions/*` | extensions | `builtin.ts:483,575-587` |

`policies/` and `schemas/` appear nowhere in that surface. Grepping the entire
`discovery/` tree for either name returns zero hits.

## 3. Where Policies and Schemas Actually Belong

The information in `policies/*.yml` and `schemas/*.yml` is **good content in a
non-functional location**. Three destinations, chosen by what consumes the information:

| Content | Current location | Target location | Why |
|---|---|---|---|
| Workflow sizing rules | `policies/workflow-sizing.yml` | inline in `commands/*.md` + `AGENTS.md` role table | The command IS the decision procedure; the agent reads it directly |
| Quality gate matrix | `policies/quality-gates.yml` | `skills/quality-gates/SKILL.md` | Lazy-loaded on demand, `skill://quality-gates` is a real resolvable URI |
| Context budget targets | `policies/context-budget.yml` | `docs/` + `scripts/validate-template.ps1` thresholds | Nothing at runtime reads a budget; the validator enforces it |
| Model routing table | `policies/model-routing.yml` | `config.yml` `modelRoles` (already there) | `config.yml` is the real consumer; the YAML duplicates it |
| Escalation rules | `policies/escalation.yml` | inline in `agents/*.md` "Must not" sections | No consumer exists; the rules are agent instructions |
| Result shapes | `schemas/*.schema.yml` | agent frontmatter `output:` and/or task `outputSchema` | These are the OMP-native enforcement points |

The YAML files may remain as **human reference** under `docs/reference/`, but nothing in
an agent prompt may reference them with a `policy:` or `schema:` pseudo-URI, because no
such scheme resolves. The resolvable internal schemes are `skill://`, `agent://`,
`artifact://`, `memory://`, `rule://`, `local://`, `mcp://`, `pr://`, `issue://`,
`conflict://`, `xd://` (`tools/read.ts:3270`).

## 4. Structured Output: the Real Mechanism

OMP enforces subagent output shape through two verified surfaces:

1. **Agent frontmatter `output:`** — `ParsedAgentFields.output?: unknown`
   (`discovery/helpers.ts:289`). Declared per agent, applies to every spawn of it.
2. **Task call `outputSchema:` + `schemaMode: "permissive" | "strict"`** —
   (`task/types.ts:110-163`, schema builder in `task/spawn-policy.ts`). Per-call,
   overrides the agent's own schema.

Enforcement happens in the `yield` tool: it wraps the declared schema into
`{result: {data: …}}`, validates on submit, and retries the model up to
`MAX_SCHEMA_RETRIES = 3` before accepting non-conforming data with a
`schemaOverridden` flag (`tools/yield.ts:202, 377-401`). This means:

- A declared schema produces **real model-facing retry pressure**, not just documentation.
- After 3 failures OMP accepts the payload anyway — so a schema is a strong nudge, not a
  hard gate. The parent must still check `status`.
- Incremental section yields (`type: ["findings"]`) validate per-section against the
  matching property sub-schema (`tools/yield.ts:444-454`).

**Decision (DR-2):** put the canonical result shape in agent frontmatter `output:` for
each worker, because it travels with the agent and cannot be forgotten at the call site.
Keep task-call `outputSchema` for per-call narrowing only.

## 5. Skills: Forced Loading

`autoloadSkills` is a verified agent frontmatter field
(`discovery/helpers.ts:307-309, 319`). It names skills that load into that agent's
context automatically. This is the correct mechanism for making
`evidence-before-completion` non-optional for workers — better than `alwaysApply: true`
on the skill, because `alwaysApply` affects every session globally whereas
`autoloadSkills` scopes the cost to the agents that need it.

**Decision (DR-4, revised):** `evidence-before-completion` stays a normal skill; the
implementer, verifier, and reviewer declare `autoloadSkills: evidence-before-completion`.
Token cost is paid only in the three agents whose output the invariant governs.

## 6. Tool Allowlists and LSP

`tools:` is a real allowlist; `yield` is auto-appended if missing
(`discovery/helpers.ts:261-267`). Two consequences the current template gets wrong:

- `task.enableLsp` defaults to `false` and only *permits* the `lsp` tool in subagents
  (`config/settings-schema.ts:4615-4624`, gate at `lsp/index.ts:1639`). Permission is not
  provision: an agent whose `tools:` list omits `lsp` cannot call it regardless of the
  setting. Explorer's prompt instructs LSP use while its allowlist forbids it.
- Any agent needing LSP must list `lsp` explicitly **and** run with
  `task.enableLsp: true`. The baseline already sets the latter.

## 7. Model Roles

Custom role names resolve, conditionally. `getModelRoleAlias` accepts a candidate when
`isModelRole(candidate) || settings?.getModelRole(candidate) !== undefined`
(`config/model-resolver.ts:925`). Built-in roles are exactly: `default`, `smol`, `slow`,
`vision`, `plan`, `designer`, `commit`, `tiny`, `task`, `advisor`
(`config/model-roles.ts:22-32`). `tech-lead`, `explorer`, `implementer`, `verifier`,
`reviewer` are **not** built-in, so `@explorer` resolves **only when `config.yml`
defines `modelRoles.explorer`**.

This creates a hidden coupling: the installer permits installing `agents` without
`config`, which silently degrades every worker's model selection. The architecture must
make `config.yml` a hard dependency of the `agents` component.

## 8. Agent Topology Decision

The three commands describe the Tech Lead's decision procedure and are invoked in the
main session. Nothing spawns `agents/tech-lead.md`. Two coherent options:

- **A — main session is the Tech Lead.** Commands carry the procedure; `tech-lead.md` is
  deleted or retained solely for nested orchestration. Costs one less recursion level,
  keeps `task.maxRecursionDepth: 2` usable for Explorer→(nothing) and
  Implementer→(nothing).
- **B — spawn a Tech Lead agent.** Consumes a recursion level immediately; workers then
  sit at depth 2, leaving no headroom under the frozen baseline.

**Decision (DR-1):** Option A. Under `task.maxRecursionDepth: 2`, option B leaves zero
spare depth, and the orchestrated workflow's parallel exploration would sit at the limit.

## 9. Invariants This Architecture Must Preserve

1. OMP is the only runtime; OmniRoute the only gateway.
2. Every file in `template/.omp/` is discovered by OMP, or it does not live there.
3. No agent prompt references a URI scheme OMP cannot resolve.
4. Result shapes are declared where OMP enforces them, not only described in prose.
5. A component's install-time dependencies are explicit and checked.
6. Isolation is requested explicitly for write-capable workers, never assumed.
7. Token budgets are enforced by the validator, not merely documented.
8. Static validation passing implies runtime discovery succeeded.

## 10. Open Items

| # | Item | Why still open |
|---|---|---|
| OQ-1 | Exact `output:` frontmatter value shape (JTD? JSON Schema? boolean?) | `output?: unknown` is untyped in `ParsedAgentFields`; `outputSchemaInputSchema` allows `object \| boolean \| string \| null`. Needs a live spawn to confirm which forms OMP accepts from frontmatter. |
| OQ-2 | Whether `auto` isolation engages for a write-capable agent without `isolated: true` | `task.isolation.mode` selects a *backend*; the per-task `isolated?: boolean` selects *participation*. Live test needed. |
| OQ-3 | Whether `autoloadSkills` content counts against the agent's own budget or the parent's | Affects context-budget numbers in §5 of `05-context-and-token-model.md`. |
