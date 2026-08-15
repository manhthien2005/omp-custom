# 09 — Model Routing

> OPUS PROPOSED SPEC v1 | Runtime mechanics verified against OMP source in `_research/upstreams/oh-my-pi`; environment-specific model/gateway availability claims explicitly marked.
>
> **Topic 02 supersession boundary:** Topic 03 owns the worker roster and routing assignment.
> Only model-role aliases referenced by the Topic 03-selected topology manifest are required.
> The former four-role routing table is non-authoritative migration input.

---

## 0. Canonical Selected Routing (KD-027)

Only model-role aliases referenced by the Topic 03-selected topology manifest are required. The
former four-role routing table is non-authoritative. The selected project configuration is:

```yaml
modelRoles:
  cheap-scout: omniroute/ds/deepseek-v4-flash:xhigh
  worker: omniroute/codex/gpt-5.6-sol:high
  reviewer: omniroute/codex/gpt-5.6-sol:xhigh
retry:
  modelFallback: true
  usageAwareFallback: false
  fallbackChains:
    default: []
    cheap-scout:
      - omniroute/ds/deepseek-v4-pro:xhigh
    worker: []
    reviewer: []
task:
  enableEffort: true
  maxEffort: xhigh
```

`ds/deepseek-v4-flash` and `ds/deepseek-v4-pro` are OmniRoute gateway model IDs.
`omniroute/ds/deepseek-v4-flash:xhigh` and
`omniroute/ds/deepseek-v4-pro:xhigh` are their full OMP selectors. For these two DeepSeek
entries, OMP `xhigh` maps to provider effort `max`; the catalog must declare reasoning support,
the `high..xhigh` thinking range, and `reasoningEffortMap.xhigh: max`.

### 0.1 Scout-only availability fallback

Cheap Scout primary is `omniroute/ds/deepseek-v4-flash:xhigh`. Cheap Scout availability
fallback is `omniroute/ds/deepseek-v4-pro:xhigh`, then Tech Lead retrieval. The Pro transition is
allowed only for retryable availability/runtime failure before usable evidence. A weak or
structurally inadequate Flash answer is a quality judgment: the Tech Lead reconciles the evidence,
narrows/reissues the retrieval contract, or retrieves inline. It does not disguise rework as an
automatic provider fallback.

Global `retry.modelFallback: true` exists solely so the named Cheap Scout chain can run.
`fallbackChains.default`, `.worker`, and `.reviewer` are explicitly empty, and
`retry.usageAwareFallback` remains false. Cheap Scout is advisory and cannot create or accept a
candidate, so Flash-to-Pro is evidence-path availability fallback rather than candidate mutation.

### 0.2 Worker and Reviewer identity

Worker defaults to exact `high`; a difficult dispatch uses the task wire `effort: hi`, which maps
to the highest supported level and is capped by `task.maxEffort: xhigh`. Reviewer always uses exact
`xhigh`. Any selected per-spawn effort path requires effective task.enableEffort true and fails
before dispatch otherwise. Selected exact effort requires task.maxEffort at least the requested
level, and acceptance confirms the resolvedModel effort suffix matches the expected effective
effort.

Worker and Reviewer selectors carry explicit `:high` / `:xhigh` suffixes because OMP's returned
`resolvedModel` displays an agent-default thinking level only when the selector or per-spawn
effort made it explicit. The suffixes make acceptance-bearing effort identity observable; a hard
Worker's `effort: hi` still overrides `:high` to `:xhigh`.

Empty Worker/Reviewer fallback chains are necessary but not sufficient. Effective selected-model
preflight reconciles `task.agentModelOverrides` before dispatch. OMP may also perform an
unauthenticated credential fallback to the parent model without setting
`resolvedModelIsFallback`. Acceptance compares returned modelRole and resolvedModel with the
reconciled expected identity; any mismatch fails even when resolvedModelIsFallback is false.
Availability before material output may instead return control to the Tech Lead for an explicit,
disclosed new selection. Quality failure after a candidate exists opens rework or a new candidate;
it never silently switches model.

### 0.3 Topic 02 compatibility sentinel

The earlier generic rule, “Selected model identity requires effective retry.modelFallback false
and retry.usageAwareFallback false; resolvedModelIsFallback true fails acceptance,” remains valid
for a selected path that declares *no* fallback. KD-027 narrows that rule for the current product:
the global retry switch may be true only with the closed Scout-only chain above, while exact
returned-identity checks protect Worker and Reviewer. This paragraph preserves the Topic 02
fail-closed intent without disabling the user-approved Scout availability fallback.

E2 proves missing or unknown aliases and unavailable models hard-fail with no fallback, while
project values win precedence. That E2 result describes alias resolution and an unavailable target;
it does not prohibit the explicit, selected, runtime-retry chain introduced by KD-027.

### 0.4 Environment state

Catalog discovery and provider execution are separate gates. The development gateway currently
advertises both selected `ds/...` IDs and OMP resolves both catalog entries. Provider smoke remains
`ENVIRONMENT_BLOCKED` while OmniRoute has no active DeepSeek credential. This does not weaken the
contract: Cheap Scout falls back to Tech Lead retrieval until a later smoke proves both model/tool
paths. No credential or provider payload belongs in repository evidence.

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

Phase-00 E2 closes the downstream behavior. E2 proves missing or unknown aliases and
unavailable models hard-fail with no fallback, while project values win precedence. Missing
and arbitrary unknown roles hard-error before session creation; a configured alias pointing at
an unavailable model resolves first and then surfaces a downstream error. The former
silent-default hypothesis is superseded.

### Resolution

Two changes are required whenever the selected topology references custom aliases:

1. **Declare the dependency in the installer.** Selecting an agent that references a custom
   alias MUST pull in `config`. If a user excludes `config`, fail rather than install a broken
   pair. An agent using a built-in or direct model reference does not invent this dependency.
2. **Validate role references statically.** `validate-template.ps1` MUST parse every
   `model: "@<role>"` in the selected agent set and confirm a matching built-in or configured
   alias. This catches the whole class of defect, including future typos.

---

## C. The Roles Currently Do Nothing

Every role in `config.yml` points at the same model:

```yaml
modelRoles:
  explorer:    omniroute/codex/gpt-5.6-sol-high   # former candidate
  implementer: omniroute/codex/gpt-5.6-sol-high   # former candidate
  verifier:    omniroute/codex/gpt-5.6-sol-high   # former candidate
  reviewer:    omniroute/codex/gpt-5.6-sol-high   # former candidate
  # tech-lead: OPTIONAL user alias (CR-34) — not installer-owned, no mandatory consumer
```

Four aliases, one destination. The routing layer currently provides **zero differentiation**.

**CR-34 — `tech-lead` is not among the required roles.** A model role has an effect only
when something resolves it, and resolution happens at exactly two points: spawn-time agent
frontmatter, or explicit user model selection. After CR-06/DR-1 (main-session model is
user-controlled, and the main session is never spawned) and CR-33 (`agents/tech-lead.md` is
removed from discovery, so no frontmatter references `@tech-lead`), neither point is on a
required workflow path. For runtime migration, only aliases actually referenced by selected
workers are required; `tech-lead` remains an optional convenience alias a user may add for
manual selection. See `12-installation-and-rollback.md §C-1`.

This is not a defect, and the template's own comments are honest about it: the environment exposes one model through OmniRoute, so there is nothing to differentiate *yet*. The abstraction is correct and worth keeping — it is the seam that makes differentiation possible later without touching five agent files.

What must not happen is mistaking the seam for a benefit already realized. Any claim that the template "routes work by intent" is false today. It routes five names to one model.

### When differentiation becomes real

When a second model is available, Topic 03 may use cost/capability asymmetry. The table below is
a heuristic for the former candidate responsibilities, not a required roster:

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

Former candidate assignments (non-authoritative until Topic 03 selects responsibilities):

| Agent | `thinking-level` | Assessment |
|---|---|---|
| `tech-lead` | `high` | Correct — decomposition and evidence adjudication. |
| `implementer` | `high` | Correct — root-cause reasoning. |
| `reviewer` | `high` | Correct — finding real defects requires depth. |
| `explorer` | `medium` | Correct — retrieval is not a reasoning bottleneck. |
| `verifier` | `medium` | Correct — reading command output is not deep work. |

These values remain research input. `task.enableEffort` defaults to `false`; the `effort` field
exists in the task wire schema only when that setting is true (`task/types.ts:202`,
`settings-schema.ts:4582-4592`). Any selected per-spawn effort path requires effective
task.enableEffort true and fails before dispatch otherwise. Topic 03 selects whether the path
consumes per-spawn effort; the installer owns the setting only for that selected consumer, and
L1 verifies the effective value after precedence.

`task.maxEffort` is an independent ceiling (default `max`) applied after the caller's coarse
effort is mapped to the resolved model (`settings-schema.ts:4706-4717`,
`task/executor.ts:2886-2908`). Selected exact effort requires task.maxEffort at least the
requested level, and acceptance confirms the resolvedModel effort suffix matches the expected
effective effort. If effort is only a non-acceptance-bearing hint, Topic 03 must say so; the exact
effort gate activates only when the selected contract makes it quality-bearing.

---

## E. OmniRoute Remains the Only Gateway

Non-negotiable, and reflected in the non-runtime `docs/policies/model-routing.md` reference plus
the Standard/Orchestrated command dispatch boundaries:

- All model access goes through OmniRoute.
- No direct provider API calls.
- Selected model identity requires effective `retry.modelFallback: false` and
  `retry.usageAwareFallback: false`; `retry.modelFallback` otherwise defaults to `true`
  (`settings-schema.ts:1528-1541`). A result with `resolvedModelIsFallback: true` fails
  acceptance.
- Effective selected-model preflight reconciles `task.agentModelOverrides` before dispatch.
  This setting precedes agent frontmatter (`task/structured-subagent.ts:281-294`), so an
  unselected effective override disables the selected path rather than silently changing it.
- Credential fallback is a distinct runtime path: an unauthenticated selected model may fall
  back to the parent model with only a warning (`model-resolver.ts:1399-1421`,
  `task/executor.ts:2840-2867`), and that path does not set `resolvedModelIsFallback`. Acceptance
  compares returned modelRole and resolvedModel with the reconciled expected identity; any
  mismatch fails even when resolvedModelIsFallback is false.

In validator-facing terms: Selected model identity requires effective retry.modelFallback false
and retry.usageAwareFallback false; resolvedModelIsFallback true fails acceptance. Effective
selected-model preflight reconciles task.agentModelOverrides before dispatch.

**ENVIRONMENT ASSUMPTION (CR-18):** The OmniRoute gateway address and available model identifiers are properties of this specific deployment environment, not portable design invariants. The specific endpoint (`http://127.0.0.1:20128`) and model ID (`omniroute/codex/gpt-5.6-sol-high`) shown in this spec are examples from the development environment. A production installation may expose different endpoints and model IDs. The template's model-role abstraction (`@tech-lead`, `@explorer`, etc.) exists precisely to insulate agent files from these environment-specific strings.

The single-gateway architectural constraint is what keeps routing auditable: one place to see what ran, one place to change it.

---

## F. Model-Role Experiment E2 — Closed

**CR-24** — T-00.E2 executed the canonical matrix and closed all eight cases. The setup
columns below remain an evidence index; their terminal outcomes are authoritative in
`docs/evidence/phase-00/E2/conclusion.yml`.

| Case | Setup | Must verify |
|---|---|---|
| T-00.E2 case 1 | Built-in role + config present | Known happy path |
| T-00.E2 case 2 | Custom role + config present | Custom happy path |
| T-00.E2 case 3 | Custom role absent from config | Hard error before session creation; no fallback |
| T-00.E2 case 4 | Arbitrary `@unknown` (not built-in, not configured) | Hard error before session creation; no fallback |
| T-00.E2 case 5 | Configured role → unavailable provider/model | Alias resolves, then downstream error surfaces; no fallback |
| T-00.E2 case 6 | User-level vs project-level conflict | Project value wins |
| T-00.E2 case 7 | Built-in/custom collision (e.g., `default`) | Configured value wins |
| T-00.E2 case 8 | Main-session selection vs worker selection | Both resolve the exact configured value without fallback |

The closed outcome feeds directly into the installer coupling in §B and the L1 assertions:
selected aliases resolve exactly, terminal errors remain errors, and graceful fallback is not a
valid selected-path policy.

## G. Contract Summary

1. Custom model roles are supported (verified); any selected agent that references one requires
   the matching `config.yml` key.
2. The installer MUST couple selected custom-role agents to config; validation MUST check every
   selected `@role` reference resolves.
3. The former four aliases target one model, so that candidate realizes no differentiation.
   Topic 03 derives the required alias set; `tech-lead` is optional and not installer-owned.
4. A selected per-spawn effort path requires effective `task.enableEffort: true`; otherwise it
   stops before dispatch.
5. OmniRoute is the sole gateway. Selected model identity requires both fallback settings off,
   reconciles `task.agentModelOverrides`, and compares returned role/model identity against the
   expected identity to catch both marked retry fallback and unmarked credential fallback.
6. Routing changes require benchmark evidence in the adoption ledger.

---

## H. Topic 06 exact managed routes

For the current managed boundary, Cheap Scout selects
`omniroute/ds/deepseek-v4-flash:xhigh` and may fall back only to
`omniroute/ds/deepseek-v4-pro:xhigh`, with fallback disclosed in the receipt. If neither is
available, retrieval returns to the main-session Tech Lead; the wrapper does not substitute a
different Scout model. Worker selects `omniroute/codex/gpt-5.6-sol:high` by default and `xhigh`
only for a Tech-Lead-classified hard work unit. Reviewer selects exact `xhigh`.

The wrapper reconciles effective aliases, retry policy, agent overrides, credential substitution,
returned `modelRole`, returned `resolvedModel`, and effort suffix. A mismatch is unmanaged or
failed, never a successful receipt. Model catalog and credentials remain user-owned outside this
repository.
