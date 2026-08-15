# 14 — Upgradeability and Governance

<!-- topic05-projection:governance -->
## Topic 05 pin and update governance (KD-029)

CodeGraph is pinned by repository, release URL, version, tag, commit, license digest, checksum
asset, and six platform artifact digests. Updating it requires a new isolated lock, license and
host review, adapter/provisioning/installer/cleanup regression, deterministic four-arm evidence,
and a recorded adoption decision. No upstream release, auto-update mechanism, or vendor benchmark
silently changes the selected version or makes the component default-on.

## State schema governance (KD-028)

Every authority record carries a schema version and content hash; the installed component has its
own hashed manifest. Unknown newer authority schemas are status-only and reject mutation. Migration
is explicit, validates source/target manifests, leaves one canonical writable root, and records a
read-only migrated backup marker. Root/profile changes require a decision and migration path, never
silent fallback to a second store.

> OPUS PROPOSED SPEC v1 | How the template survives OMP upgrades and upstream drift.
>
> **Topic 02 supersession boundary:** governance consumes the
> Topic 03-selected topology manifest. Former worker names and counts are non-authoritative baseline examples. Watched
> claims, removal procedures, and upgrade checks attach only to selected responsibilities and
> capabilities.
>
> **KD-027 watched manifest:** `cheap-scout`, `worker`, `reviewer`; Tech Lead stays outside agent
> discovery. Governance watches DeepSeek reasoning/effort mapping, the closed Scout-only fallback
> chain, Worker/Reviewer returned identity, exact effort, stale-agent retirement, and the
> current-product supersession record.

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
    - packages/coding-agent/src/task/executor.ts            # selected allowlist + autoloadSkills injection
    - packages/coding-agent/src/task/structured-subagent.ts # child LSP gates + autoload resolution
    - packages/coding-agent/src/task/isolation-runner.ts    # git-repo requirement
    - packages/coding-agent/src/tools/index.ts              # built-in tool setting gates
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
| `discovery/helpers.ts` | `parseAgentFields` accepts our frontmatter keys | All selected worker definitions |
| `utils/src/frontmatter.ts` | kebab-case keys normalize to camelCase | `thinking-level`, `read-summarize` |
| `discovery/builtin.ts` | `.omp/commands`, `.omp/skills`, `.omp/RULES.md`, `.omp/config.yml` are discovered | Commands, skills, rules, config |
| `task/discovery.ts` | project `.omp/agents` beats user and bundled | Agent name precedence (`reviewer` shadowing) |
| `task/index.ts` | `isolated` param exists only when isolation enabled | Selected per-task isolation requests |
| `task/executor.ts` | selected `tools:` is the worker allowlist; `autoloadSkills` injects skill bodies | Selected skill-autoload consumers and tool consumers |
| `task/structured-subagent.ts` | plan mode, parent-session enablement, and `task.enableLsp` shape the child LSP gate | Selected LSP-consuming paths |
| `task/isolation-runner.ts` | isolation requires a git repo | Selected isolation paths |
| `tools/index.ts` | `lsp.enabled` independently gates built-in LSP registration | Selected LSP-consuming paths |
| `lsp/index.ts` | applicable-server routing and `details.success` distinguish working LSP calls from ordinary failure content | Selected LSP-consuming paths |
| `tools/yield.ts` | `outputSchema` is validated with bounded retries | Selected structured-result consumers |
| `config/model-resolver.ts` | custom roles resolve when configured | Selected custom model aliases |
| `config/model-roles.ts` | built-in role list (name-collision risk) | Selected alias naming and collision checks |
| `config/settings-schema.ts` | setting names and defaults | `task.*`, `lsp.*`, `compaction.*` |

The LSP four-gate conjunction is a watched governance claim: allowlist handling in
`task/executor.ts`, parent/plan/`task.enableLsp` handling in `task/structured-subagent.ts`, and
the independent `lsp.enabled` registration gate in `tools/index.ts` must be re-verified
together after an upstream change.

Applicable-language-server routing and LSP details.success are watched governance claims backed
by lsp/index.ts. Re-verify both the no-matching-server and no-configured-server branches, because
the four registration gates can remain unchanged while either branch still returns a failed
ordinary tool result.

The grep, glob, ast_grep, and web_search setting gates are watched governance claims backed by
`tools/index.ts` and the matching `settings-schema.ts` entries. A default change or new filter
requires re-running the selected-consumer L1 checks before adoption.

---

## D. Controlled Update Process

```
1. detect        — compare current OMP commit to pinned_commit
2. scope         — diff the full upstream commit range; flag watched_paths changes FIRST as high-priority anchors, then inspect non-watched changes for transitive or call-chain impact on watched behavior
3. summarize     — for each changed file (watched or non-watched): what claim might be affected?
4. classify      — useful | duplicate | incompatible | irrelevant
5. re-verify     — re-run L0 (Static) + L1 (Discovery) validation against the new OMP for ALL candidate claims from step 3
6. port          — manually adjust the template; never auto-apply
7. regression    — run L3 (Behavioral) fixtures; compare metrics to the recorded baseline
8. review        — human review of the diff + evidence
9. promote       — update pinned_commit + last_reviewed, or reject and stay pinned
```

**Never** skip step 5. A watched-path diff that looks cosmetic can still change behavior — a renamed key, a flipped default, a moved throw. A non-watched change (caller, adapter, helper) can also alter behavior without touching watched paths.

**CR-21 — Full-range discovery, watched-path triage:** Discovery MUST cover the full upstream commit range, not just watched paths. A behavior-changing commit can modify callers, adapters, initialization, transitive helpers, or insert new files into the call chain — none of which may touch watched paths. Watched paths are **triage anchors** (high-priority review), not the boundary of discovery. Step 2 diffs the full range; step 3 processes watched-path hits first, then assesses non-watched changes for transitive impact. The diff is triage input, not a verdict on breakage.

---

## E. Reversibility Requirement

Every component must be removable independently. This is a hard design constraint
from the original plan (Definition of Done #18), and it constrains implementation:

| Component | Removal effect | Independently removable? |
|---|---|---|
| A selected worker file | That responsibility stops being spawnable; selected consumers must reconcile the manifest and contract before continuation | Yes — after manifest/consumer reconciliation and validation |
| A selected skill | Its discipline stops being injected; every selected `autoloadSkills` consumer must remove or replace the reference and revalidate | Yes — coupled to selected worker frontmatter |
| `RULES.md` | Sticky invariants stop being enforced | Yes |
| `AGENTS.md` | Constitution stops loading | Yes |
| A selected command adapter | That compatibility entry becomes unavailable; plain entry remains normal, and selected consumers must be reconciled | Yes — after consumer reconciliation |
| Selected `config.yml` aliases | Alias intent becomes unavailable; discovery must fail closed until every selected reference is reconciled | Yes — after selected references are removed or replaced |
| Schema docs | Runtime unaffected (docs only); inline schemas in commands still work | Yes |
| Policy docs | Runtime unaffected (docs only) | Yes |

**Coupling to document explicitly**: removing a selected skill requires editing the
`autoloadSkills` frontmatter of every selected worker that autoloads it. This is a real
coupling the removal procedure must state, or removal leaves a dangling name.
`resolveAutoloadSkills` filters unresolved names out (`.filter(skill => skill !== undefined)`),
so a dangling entry fails **silently** — the discipline just stops being injected.
That silent-failure mode is exactly why L1 (Discovery) validation must cross-check
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
  - selected agent frontmatter keys accepted by parseAgentFields
  - kebab-case frontmatter normalization
  - selected custom model role resolution
  - selected autoloadSkills subagent injection
  - selected isolation git-repo requirement
  - selected LSP four-gate conjunction
  - selected LSP applicable-server routing and required-call details.success
  - task outputSchema enforcement
```

L0 (Static) validation should warn when the live OMP version differs from
`omp_verified_version`, because that is precisely when the verified claims need
re-checking.

---

## I. Governance Anti-Goals

- **No auto-update.** Never pull upstream changes into the live template.
- **No unpinned dependency.** Every upstream has a commit SHA.
- **No unrecorded local modification.** Divergence from upstream is documented.
- **No mechanism without an OMP mapping.** Prevents the `policies/` class of defect.
- **No removal without a documented procedure.** Prevents silent dangling references.
