# 14 — Upgradeability and Governance

> OPUS PROPOSED SPEC v1 | How the template survives OMP upgrades and upstream drift.

---

## A. The Governance Problem

The template depends on OMP runtime behavior that is **not a public API**. Every
verified fact in `02-runtime-semantics.md` was read out of OMP source at a single
commit. OMP ships frequently. Any of these can change without a deprecation notice:

- `parseAgentFields` accepted keys (`tools`, `spawns`, `thinkingLevel`, `readSummarize`, `prewalk`, `autoloadSkills`)
- kebab→camel frontmatter normalization in `normalizeKeys`
- custom model-role acceptance in `getModelRoleAlias`
- `autoloadSkills` injection via `sendCustomMessage`
- isolation requiring a git repo (`prepareIsolationContext` throws)
- the `outputSchema` / `schemaMode` parameters on the `task` tool
- default values (`task.enableLsp: false`, `task.isolation.mode: none`)

The template must treat these as **pinned, watched dependencies** — not assumptions.

---

## B. Pinned Upstream Record

`registry/upstreams.yml` must record, for OMP specifically:

```yaml
- id: oh-my-pi
  repository: can1357/oh-my-pi
  url: https://github.com/can1357/oh-my-pi
  default_branch: main
  pinned_commit: <exact SHA the semantics were verified against>
  clone_date: <ISO date>
  license: MIT
  tier: runtime-authority
  authority_for:
    - runtime and orchestration
    - agent frontmatter contract
    - skill and command discovery
    - isolation backend
    - model role resolution
  watched_paths:
    - packages/coding-agent/src/discovery/helpers.ts        # parseAgentFields
    - packages/coding-agent/src/discovery/builtin.ts        # commands/skills/RULES.md/config discovery
    - packages/coding-agent/src/task/discovery.ts           # agent discovery + precedence
    - packages/coding-agent/src/task/agents.ts              # parseAgent + bundled agents
    - packages/coding-agent/src/task/index.ts               # task schema, isolationEnabled
    - packages/coding-agent/src/task/executor.ts            # autoloadSkills injection
    - packages/coding-agent/src/task/structured-subagent.ts # autoload resolution
    - packages/coding-agent/src/task/isolation-runner.ts    # git-repo requirement
    - packages/coding-agent/src/tools/yield.ts              # output schema enforcement
    - packages/coding-agent/src/config/model-resolver.ts    # custom role acceptance
    - packages/coding-agent/src/config/model-roles.ts        # built-in role list
    - packages/coding-agent/src/config/settings-schema.ts    # setting names + defaults
    - packages/utils/src/frontmatter.ts                     # kebab→camel normalization
  update_policy: manual-review-only
  last_reviewed: <ISO date>
  evaluation_suite: evals/
```

`update_policy: manual-review-only` is deliberate. Never auto-pull.

---

## C. The Watched-Path Contract

Each watched path maps to a **specific claim** the template depends on. The value of
the registry is not "we cloned this repo" — it is "if this file changes, this claim
may be false, and this part of the template may break."

| Watched path | Claim it backs | Template component that breaks if it changes |
|---|---|---|
| `discovery/helpers.ts` | `parseAgentFields` accepts our frontmatter keys | All 5 agent files |
| `utils/src/frontmatter.ts` | kebab-case keys normalize to camelCase | `thinking-level`, `read-summarize` |
| `discovery/builtin.ts` | `.omp/commands`, `.omp/skills`, `.omp/RULES.md`, `.omp/config.yml` are discovered | Commands, skills, rules, config |
| `task/discovery.ts` | project `.omp/agents` beats user and bundled | Agent name precedence (`reviewer` shadowing) |
| `task/index.ts` | `isolated` param exists only when isolation enabled | Implementer isolation |
| `task/executor.ts` | `autoloadSkills` injects skill bodies into subagents | evidence-before-completion guarantee |
| `task/isolation-runner.ts` | isolation requires a git repo | Non-git-repo fallback path |
| `tools/yield.ts` | `outputSchema` is validated with bounded retries | All structured results |
| `config/model-resolver.ts` | custom roles resolve when configured | `@tech-lead`, `@explorer`, … |
| `config/model-roles.ts` | built-in role list (name-collision risk) | Custom role naming |
| `config/settings-schema.ts` | setting names and defaults | `task.*`, `lsp.*`, `compaction.*` |

---

## D. Controlled Update Process

```
1. detect        — compare current OMP commit to pinned_commit
2. scope         — diff ONLY watched_paths, not the whole repo
3. summarize     — for each changed watched path: what claim might be affected?
4. classify      — useful | duplicate | incompatible | irrelevant
5. re-verify     — re-run Level 1 + Level 2 validation against the new OMP
6. port          — manually adjust the template; never auto-apply
7. regression    — run Level 3 fixtures; compare metrics to the recorded baseline
8. review        — human review of the diff + evidence
9. promote       — update pinned_commit + last_reviewed, or reject and stay pinned
```

**Never** skip step 5. A watched-path diff that looks cosmetic can still change
behavior — a renamed key, a flipped default, a moved throw.

---

## E. Reversibility Requirement

Every component must be removable independently. This is a hard design constraint
from the original plan (Definition of Done #18), and it constrains implementation:

| Component | Removal effect | Independently removable? |
|---|---|---|
| A single agent file | That agent stops being spawnable; commands referencing it must degrade | Yes — if commands degrade gracefully |
| A single skill | Its discipline stops being injected; `autoloadSkills` entry must be dropped too | Yes — coupled to agent frontmatter |
| `RULES.md` | Sticky invariants stop being enforced | Yes |
| `AGENTS.md` | Constitution stops loading | Yes |
| A command | That workflow size becomes unavailable | Yes |
| `config.yml` roles | Roles fall back to `default` per `resolveModelRoleValue` | Yes — graceful |
| Schema docs | Runtime unaffected (docs only); inline schemas in commands still work | Yes |
| Policy docs | Runtime unaffected (docs only) | Yes |

**Coupling to document explicitly**: removing a skill requires editing the
`autoloadSkills` frontmatter of every agent that autoloads it. This is a real
coupling the removal procedure must state, or removal leaves a dangling name.
`resolveAutoloadSkills` filters unresolved names out (`.filter(skill => skill !== undefined)`),
so a dangling entry fails **silently** — the discipline just stops being injected.
That silent-failure mode is exactly why Level 2 validation must cross-check
`autoloadSkills` names against the skills directory.

---

## F. Local Modification Tracking

For every adopted upstream mechanism, `registry/adoption-ledger.yml` records:

```yaml
- mechanism: <name>
  source_upstream: <id>
  adoption_type: conceptual | paraphrased | adapted | copied | linked
  local_component: <path in template/>
  local_modifications: <what we changed and why>
  rationale: <why adopted>
  omp_capability_used: <the real OMP primitive it maps to>
  removal_procedure: <how to remove it safely>
  evaluation: <which eval covers it>
```

The `omp_capability_used` field is the anti-drift guard: it forces every adopted
mechanism to name a real OMP primitive. A mechanism that cannot name one is either
documentation or a defect — which is exactly how `policies/` and `schemas/` should
have been caught before shipping.

`removal_procedure` is what makes Definition of Done #18 auditable rather than
aspirational.

---

## G. Rejected Mechanisms

`registry/rejected-mechanisms.yml` must record rejections with reasons, so the same
mechanism is not re-proposed each cycle:

```yaml
- mechanism: <name>
  source_upstream: <id>
  rejection_reason: duplicates-omp | token-cost | complexity | license | unverifiable
  omp_equivalent: <the OMP primitive that already solves it, if any>
  reconsider_if: <what would have to change>
```

`reconsider_if` matters: "OMP adds a policy loader" is a legitimate future trigger to
revisit the policy-file decision.

---

## H. Version Compatibility Declaration

The template must declare which OMP version it was verified against, and validation
must check it:

```yaml
# registry/skill-lock.yml or a dedicated compatibility record
omp_verified_version: 17.2.10
omp_verified_commit: <SHA>
omp_minimum_version: 17.2.0
verification_date: <ISO date>
verified_claims:
  - agent frontmatter keys accepted by parseAgentFields
  - kebab-case frontmatter normalization
  - custom model role resolution
  - autoloadSkills subagent injection
  - isolation git-repo requirement
  - task outputSchema enforcement
```

Level 1 validation should warn when the live OMP version differs from
`omp_verified_version`, because that is precisely when the verified claims need
re-checking.

---

## I. Governance Anti-Goals

- **No auto-update.** Never pull upstream changes into the live template.
- **No unpinned dependency.** Every upstream has a commit SHA.
- **No unrecorded local modification.** Divergence from upstream is documented.
- **No mechanism without an OMP mapping.** Prevents the `policies/` class of defect.
- **No removal without a documented procedure.** Prevents silent dangling references.
