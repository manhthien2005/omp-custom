# 09 — Model Routing

> OPUS PROPOSED SPEC v1 | Runtime mechanics verified against OMP source in `_research/upstreams/oh-my-pi`; environment-specific model/gateway availability claims explicitly marked.

---

## A. Custom Model Roles Are Supported — Conditionally

OMP defines ten built-in roles (`config/model-roles.ts:22-32`):

```
default · smol · slow · vision · plan · designer · commit · tiny · task · advisor
```

`tech-lead`, `explorer`, `implementer`, `verifier`, and `reviewer` are **not** among them. The template nonetheless uses `model: "@tech-lead"` and friends in every agent file, and defines matching entries under `modelRoles:` in `config.yml`.

This works. The resolution logic at `config/model-resolver.ts:925` is decisive:

```ts
if (isModelRole(candidate) || settings?.getModelRole(candidate) !== undefined) return candidate;
return undefined;
```

A role alias resolves if it is either a built-in **or** present in settings. `getKnownRoleIds` (`model-roles.ts:87`) confirms the design intent by folding `settings.getModelRoles()` into the known-role set — custom roles are a supported extension point, not an accident.

**Verified conclusion:** `@tech-lead` resolves correctly **when `config.yml` is installed**. My earlier suspicion that custom roles were unsupported was wrong.

---

## B. The Coupling Defect (P1)

Because custom roles live in `config.yml` and are referenced from `agents/*.md`, the two are **hard-coupled**. The installer, however, treats them as independently selectable components:

```powershell
[string[]]$Components = @(
    "agents", "workflows", "skills", "schemas", "policies", "agents-md", "rules-md", "config"
)
```

Installing `agents` without `config` yields five agent files whose `model:` fields reference roles that do not exist. `getModelRoleAlias` returns `undefined`, the alias is not recognized as a role, and `"@tech-lead"` falls through as a literal model pattern that matches nothing in the catalog.

The exact downstream behavior — hard error versus silent fallback to `default` — is **not verified**; I traced the alias-resolution path but did not trace every fallback branch to a terminal outcome. Either way the user's intent is lost, and a silent fallback is arguably worse because it looks like it worked.

### Resolution

Two changes, both required:

1. **Declare the dependency in the installer.** Selecting `agents` MUST pull in `config`. If a user explicitly excludes `config` while including `agents`, fail with a clear message rather than installing a broken pair.
2. **Validate role references statically.** `validate-template.ps1` MUST parse every `model: "@<role>"` in `agents/*.md` and confirm a matching key exists under `modelRoles:` in `config.yml`. This is a cheap check that catches the whole class of defect — including future typos.

---

## C. The Roles Currently Do Nothing

Every role in `config.yml` points at the same model:

```yaml
modelRoles:
  explorer:    omniroute/codex/gpt-5.6-sol-high   # required — spawned worker
  implementer: omniroute/codex/gpt-5.6-sol-high   # required — spawned worker
  verifier:    omniroute/codex/gpt-5.6-sol-high   # required — spawned worker
  reviewer:    omniroute/codex/gpt-5.6-sol-high   # required — spawned worker
  # tech-lead: OPTIONAL user alias (CR-34) — not installer-owned, no mandatory consumer
```

Four aliases, one destination. The routing layer currently provides **zero differentiation**.

**CR-34 — `tech-lead` is not among the required roles.** A model role has an effect only
when something resolves it, and resolution happens at exactly two points: spawn-time agent
frontmatter, or explicit user model selection. After CR-06/DR-1 (main-session model is
user-controlled, and the main session is never spawned) and CR-33 (`agents/tech-lead.md` is
removed from discovery, so no frontmatter references `@tech-lead`), neither point is on a
required workflow path. The four spawnable worker roles are required; `tech-lead` is an
optional convenience alias a user may add for manual selection. See
`12-installation-and-rollback.md §C-1`.

This is not a defect, and the template's own comments are honest about it: the environment exposes one model through OmniRoute, so there is nothing to differentiate *yet*. The abstraction is correct and worth keeping — it is the seam that makes differentiation possible later without touching five agent files.

What must not happen is mistaking the seam for a benefit already realized. Any claim that the template "routes work by intent" is false today. It routes five names to one model.

### When differentiation becomes real

The moment a second model is available, the natural split follows the cost/capability asymmetry of the roles:

| Role | Wants | Rationale |
|---|---|---|
| `tech-lead` | Strongest reasoning | Owns decomposition and final judgment; errors here propagate to every worker. |
| `implementer` | Strong reasoning | Root-cause fixes and correct edits are the highest-value output. |
| `reviewer` | Strong reasoning, ideally a *different* family than implementer | Independent perspective catches what the author rationalized. |
| `explorer` | Fast, cheap | Ranked-evidence retrieval is mechanical; volume matters more than depth. |
| `verifier` | Fast, cheap | Runs commands and reads output. Determinism comes from the commands, not the model. |

The reviewer-differs-from-implementer point is the most valuable and the least obvious: same-model review inherits the same blind spots.

Any such change requires before/after benchmark evidence recorded in the adoption ledger, per the governance rules in `14-upgradeability-and-governance.md`. Routing changes are exactly the kind of plausible-sounding tuning that must be measured rather than assumed.

---

## D. Effort Is Separate From Model

Thinking effort is orthogonal to model selection and is configured per agent via `thinking-level:`, verified as a real field (`parseAgentFields` reads `thinkingLevel`, with `thinking` accepted as an alias, and kebab→camel normalization making `thinking-level:` valid).

Current assignments:

| Agent | `thinking-level` | Assessment |
|---|---|---|
| `tech-lead` | `high` | Correct — decomposition and evidence adjudication. |
| `implementer` | `high` | Correct — root-cause reasoning. |
| `reviewer` | `high` | Correct — finding real defects requires depth. |
| `explorer` | `medium` | Correct — retrieval is not a reasoning bottleneck. |
| `verifier` | `medium` | Correct — reading command output is not deep work. |

These are well-chosen and need no change. The baseline `task.enableEffort = true` and `task.maxEffort = max` permit per-task effort overrides through the `task` call's `effort` parameter, verified present in the task schema (`effortField` in `createTaskSchema`). That gives the orchestrator a per-dispatch lever without editing agent files — the right place for task-specific escalation.

---

## E. OmniRoute Remains the Only Gateway

Non-negotiable, and correctly reflected in `model-routing.yml`:

- All model access goes through OmniRoute.
- No direct provider API calls.
- `retry.modelFallback = false` and `retry.usageAwareFallback = false` stay off — silent cross-model fallback would invalidate any benchmark comparison and make failures hard to attribute.

**ENVIRONMENT ASSUMPTION (CR-18):** The OmniRoute gateway address and available model identifiers are properties of this specific deployment environment, not portable design invariants. The specific endpoint (`http://127.0.0.1:20128`) and model ID (`omniroute/codex/gpt-5.6-sol-high`) shown in this spec are examples from the development environment. A production installation may expose different endpoints and model IDs. The template's model-role abstraction (`@tech-lead`, `@explorer`, etc.) exists precisely to insulate agent files from these environment-specific strings.

The single-gateway architectural constraint is what keeps routing auditable: one place to see what ran, one place to change it.

---

## F. Model-Role Fallback Test Matrix

**CR-24** — Before committing to the model-role mechanism in phase-02, **T-00.E2** (see `spec/phases/phase-00-foundation.md`) defines the canonical fallback test matrix. This section cross-references those cases and notes what each verifies:

| Case | Setup | Must verify |
|---|---|---|
| T-00.E2 case 1 | Built-in role + config present | Known happy path |
| T-00.E2 case 2 | Custom role + config present | Custom happy path |
| T-00.E2 case 3 | Custom role absent from config | Role lookup behavior (error vs fallback) |
| T-00.E2 case 4 | Arbitrary `@unknown` (not built-in, not configured) | Parser/resolver terminal behavior |
| T-00.E2 case 5 | Configured role → unavailable provider/model | Downstream resolution failure (distinct from alias lookup failure) |
| T-00.E2 case 6 | User-level vs project-level conflict | Precedence: `getModelRoleAlias` merge order |
| T-00.E2 case 7 | Built-in/custom collision (e.g., `default`) | Namespace collision: custom wins or built-in wins? |
| T-00.E2 case 8 | Main-session selection vs worker selection | Coordinator path vs worker path (if different) |

**Stable disagreement on case 8 granularity:** Opus holds that case 8 (main-session vs worker resolver path) should be part of the experiment only if evidence suggests they diverge. GPT's preference is to always verify both paths independently. The experiment design includes case 8 to resolve this empirically.

Outcome of T-00.E2 feeds directly into: (a) the installer coupling requirement in §B, (b) validation static-check wording, and (c) whether a graceful fallback mode (inform user but continue) is viable vs a hard abort.

## G. Contract Summary

1. Custom model roles are supported (verified) but require `config.yml` to be installed.
2. The installer MUST couple `agents` → `config`; validation MUST check every `@role` reference resolves.
3. **Four** required worker roles currently target one model — the abstraction is a seam, not a realized benefit. Do not claim otherwise. `tech-lead` is an optional user alias, not installer-owned (CR-34).
4. `thinking-level` assignments are correct as written; per-task `effort` overrides are available via the `task` call.
5. OmniRoute is the sole gateway; model fallback stays disabled.
6. Routing changes require benchmark evidence in the adoption ledger.
