# 01 — Target Architecture

## Selected Topic 04 state authority (KD-028)

The template installs one local deterministic component at `.omp/state`, used explicitly by both
Claude and Codex/OMP. Operational hierarchy is project → optional phase → task → immutable state
revisions plus sessions, work units, candidates, evidence, handoffs, and promoted artifacts. Git
projects store it at `<absolute-git-common-dir>/agent-tasks`; non-Git projects use
`<project-root>/.agent-tasks`. Installed code and operational authority are separate.

## Selected Topic 07 continuity boundary (KD-031)

The managed entry point loads a trusted continuity extension after the Topic 04 state core.
Automatic semantic, idle, mid-turn, remote, and auto-continue paths are disabled. After exact
task arming, argument-free `/safe-compact` may authorize one native soft context-full transaction.
It persists local recovery bytes before mutation, binds one canonical Topic 04 kernel to the
current session/revision/lease, and injects it once on the next normal prompt. Summary and kernel
remain context, never authority. Pressure aborts ordinary provider dispatch; bounded children fail
without compaction or automatic retry. Bare OMP and direct native compaction are unmanaged.

> OPUS PROPOSED SPEC v1 | Status: awaiting joint review. All claims source-verified against
> `_research/upstreams/oh-my-pi` unless marked OPEN.
>
> **Topic 02 supersession boundary:** the main-session Tech Lead remains architectural
> authority. The Topic 03-selected topology manifest is the only authority for worker names,
> count, dispatch, and capability assignment. Former role names below describe the frozen
> baseline or a migration candidate; they do not require that roster.
>
> **Selected by KD-027:** main-session Tech Lead → optional read-only `cheap-scout`, optional
> bounded writer `worker`, and risk-gated General `reviewer`. Default is inline/no spawn.
> Verification is owned by the Tech Lead; Reviewer is fixed `xhigh`; Worker is `high` or
> Tech-Lead-selected `xhigh`; only Scout owns Flash→Pro availability fallback.

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

Enforcement starts in the `yield` tool: it wraps the declared schema into
`{result: {data: …}}`, validates on submit, and retries the model up to
`MAX_SCHEMA_RETRIES = 3` (`tools/yield.ts:202,377-401`). Finalization then rejects an ordinary
invalid payload as `schema_violation`; strict mode also rejects a retry-exhausted override
(`task/executor.ts:598-700`). This means:

- A declared schema produces **real model-facing retry pressure**, not just documentation.
- A retry-exhausted `schemaOverridden` result is unvalidated, not acceptance evidence.
- A malformed schema is the silent hole: it can return
  `structuredOutput.status: unavailable` without failing the spawn. Every selected
  structured-result schema is fully linted; acceptance requires structuredOutput.status valid.
- Incremental section yields (`type: ["findings"]`) validate per-section against the
  matching property sub-schema (`tools/yield.ts:444-454`).

**Decision (DR-2):** put the canonical result shape in agent frontmatter `output:` for
each selected spawned worker with a structured result contract, because it travels with the
agent and cannot be forgotten at the call site. Keep task-call `outputSchema` for per-call
narrowing only. Inline responsibilities use the equivalent main-session acceptance check.

## 5. Skills: Forced Loading

`autoloadSkills` is a verified agent frontmatter field
(`discovery/helpers.ts:307-309, 319`). It names skills that load into that agent's
context automatically. This is the correct mechanism for making
`evidence-before-completion` non-optional for workers — better than `alwaysApply: true`
on the skill, because `alwaysApply` affects every session globally whereas
`autoloadSkills` scopes the cost to the agents that need it.

**Decision (DR-4, revised):** `evidence-before-completion` stays a normal skill. Selected
completion-claiming roles declare `autoloadSkills: evidence-before-completion` when they are
spawned; inline completion claims remain governed by main-session rules. Token cost is paid
only in the selected contexts whose output the invariant governs. Topic 03 determines those
responsibilities rather than inheriting the former three-role assignment.

## 6. Tool Allowlists and LSP

`tools:` is a real allowlist; `yield` is auto-appended if missing
(`discovery/helpers.ts:261-267`). Effective subagent LSP uses a four-condition conjunction:
allowlist, `task.enableLsp`, parent session not disabled and not plan mode, and `lsp.enabled`
(`task/structured-subagent.ts:318-320`, `tools/index.ts:593`,
`task/executor.ts:2675-2678`). Consequences for the current template:

- `task.enableLsp` defaults to `false` and only *permits* the `lsp` tool in subagents
  (`config/settings-schema.ts:4615-4624`). It contributes one condition to the child-session
  gate alongside parent-session enablement and plan mode (`task/structured-subagent.ts:318-320`);
  `lsp.enabled` is enforced separately by tool creation (`tools/index.ts:593`). Permission is
  not provision: an agent whose `tools:` list omits `lsp` cannot call it regardless of the
  settings. Explorer's prompt instructs LSP use while its allowlist forbids it.
- A selected LSP consumer must list `lsp`, run with `task.enableLsp == true`, inherit a
  parent session that has not disabled LSP and is not in plan mode, and have
  `lsp.enabled == true`. The project install owns the conditional CR-40 key, while CR-41 and
  parent-session state remain effective-runtime checks; see `07-retrieval-and-code-understanding.md §A-1`.

The four registration gates establish LSP tool presence only; selected symbol-aware work also
requires an applicable working language server and successful required LSP calls. The pinned
runtime returns ordinary tool content with `details.success: false` when no server applies or no
server is configured (`lsp/index.ts:2145-2160`); that result is failed capability evidence, not a
valid substitute for the selected semantic contract.

## 7. Model Roles

Custom role names resolve, conditionally. `getModelRoleAlias` accepts a candidate when
`isModelRole(candidate) || settings?.getModelRole(candidate) !== undefined`
(`config/model-resolver.ts:925`). Built-in roles are exactly: `default`, `smol`, `slow`,
`vision`, `plan`, `designer`, `commit`, `tiny`, `task`, `advisor`
(`config/model-roles.ts:22-32`). `tech-lead`, `explorer`, `implementer`, `verifier`,
`reviewer` are **not** built-in, so `@explorer` resolves **only when `config.yml`
defines `modelRoles.explorer`**.

This creates a hard coupling for any selected agent that references a custom role. Phase-00
experiment E2 closed the terminal behavior: missing and unknown aliases hard-error before
session creation, an unavailable configured model surfaces a downstream error, and neither
case falls back. Selected model-role aliases fail closed with no fallback, and project
configuration wins precedence over the global value. The architecture therefore makes
`config.yml` a hard dependency whenever the Topic 03-selected topology manifest references a
custom alias. Selected-model preflight reconciles task.agentModelOverrides before dispatch.
Acceptance compares returned modelRole and resolvedModel with the reconciled expected identity;
any mismatch fails even when resolvedModelIsFallback is false. A
`resolvedModelIsFallback == true` result is independently rejected because that flag marks retry
fallback, while the exact identity comparison also catches settings overrides and unflagged
credential fallback to the parent model (`task/structured-subagent.ts:281-294`,
`config/model-resolver.ts:1399-1421`, `task/executor.ts:1707-1715,2840-2867`).

## 8. Agent Topology Decision

The three commands describe the Tech Lead's decision procedure and are invoked in the
main session. Nothing spawns `agents/tech-lead.md`. Two coherent options:

- **A — main session is the Tech Lead.** Commands carry the procedure; `tech-lead.md` is
  deleted or retained solely for nested orchestration. Costs one less recursion level,
  keeps `task.maxRecursionDepth: 2` usable for Explorer→(nothing) and
  Implementer→(nothing).
- **B — spawn a Tech Lead agent.** Consumes a recursion level immediately; workers then
  sit at depth 2, leaving no headroom under the frozen baseline.

**Decision (DR-1):** Option A for final-ownership placement: the main session is the Tech
Lead. The earlier fixed parallel-exploration topology is reopened by KD-026/Topic 03; recursion
depth remains a runtime constraint if Topic 03 later selects worker dispatch.

## 9. Invariants This Architecture Must Preserve

1. OMP is the only runtime; OmniRoute the only gateway.
2. Every file in `template/.omp/` is discovered by OMP, or it does not live there.
3. No agent prompt references a URI scheme OMP cannot resolve.
4. Result shapes are declared where OMP enforces them, not only described in prose.
5. A component's install-time dependencies are explicit and checked.
6. Isolation is requested explicitly for selected concurrently write-capable workers, never assumed.
7. Token budgets are enforced by the validator, not merely documented.
8. Static validation proves only L0 filesystem and text properties; runtime discovery requires a
   separate L1 OMP discovery check. Neither tier may claim evidence owned by the other.

## 10. Open Items

| # | Item | Why still open |
|---|---|---|
| OQ-1 | Exact `output:` frontmatter value shape (JTD? JSON Schema? boolean?) | `output?: unknown` is untyped in `ParsedAgentFields`; `outputSchemaInputSchema` allows `object \| boolean \| string \| null`. Needs a live spawn to confirm which forms OMP accepts from frontmatter. |
| OQ-2 | Whether `auto` isolation engages for a write-capable agent without `isolated: true` | `task.isolation.mode` selects a *backend*; the per-task `isolated?: boolean` selects *participation*. Live test needed. |
| OQ-3 | Whether `autoloadSkills` content counts against the agent's own budget or the parent's | Affects context-budget numbers in §5 of `05-context-and-token-model.md`. |
