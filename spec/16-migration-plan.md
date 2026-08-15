# 16 — Migration Plan

<!-- round09-12-projection:release -->
## Round 09–12 phase supersession and readiness derivation (KD-032)

The current executable path supersedes the remaining placeholder interpretation of Topics 09–12:
Topic 09/10 are delta closures over existing Topic 04/06 authority, Topic 11 now has a model-free
deterministic evaluator plus an explicitly authorized campaign boundary, and Topic 12 consumes
those records plus scratch package proof. Historical phase task text below remains provenance and
gap history; it does not override the current round markers or recreate a fixed roster.

Release readiness is derived, not asserted. Without separately authorized final provider evidence,
the current product remains `IMPLEMENTED_NOT_PROMOTED`; unavailable OMP 17.2.10, Claude runtime,
and model-assisted arms remain named limitations rather than fabricated PASS results. Local-only
implementation does not imply Git publication or live installation.

## Topic 04 state migration (KD-028)

If a project gains Git after local state exists, `<project-root>/.agent-tasks` becomes read-only.
Explicit migration validates every record/revision, copies and rehashes into a temporary sibling of
`<absolute-git-common-dir>/agent-tasks`, publishes one target atomically, and renames the source to
a marked read-only backup. Interrupted copies require explicit recovery. Topic 04 ships the manual
Claude/Codex core adapter; Topic 08 may lift it to automatic lifecycle events only after the
installed-runtime probe.

> OPUS PROPOSED SPEC v1 | How to get from the current state to the target architecture.
>
> **Topic 02 supersession boundary:** runtime migration consumes the Topic 03-selected
> topology manifest. The former agent-file rows are non-authoritative baseline inventory.
> Worker names, count, schemas, capabilities, and dispatch adapters are derived at migration
> time rather than frozen here.
>
> **KD-027 migration target:** install `cheap-scout.md`, `worker.md`, and `reviewer.md`; move the
> Tech Lead reference outside discovery; retire stale Explorer/Implementer/Verifier/Tech-Lead
> definitions only after backup; deploy selected aliases/effort/retry settings; and bind the new
> current-product evidence identity to immutable Phase 00 evidence.

---

## A. Migration Stance

The current template is **not** a failed design. Its intent, its agent-role
decomposition, its structured result contracts, and its coding constitution are
sound and worth keeping. What is broken is the **runtime wiring** — the connection
between good intentions and OMP primitives.

So this is a **repair-and-rewire migration**, not a rewrite. Concretely:

- **Keep as migration input**: `AGENTS.md` constitution, `RULES.md` invariants, former agent
  responsibility definitions, three workflow entry adapters, result-contract content,
  context-budget targets, and skills. **CR-33 caveat:** the Tech Lead role definition is kept
  as content but **relocated** to `docs/roles/tech-lead.md`; no fixed number of agent files is
  implied because any file retained under `template/.omp/agents/` is live and spawnable.
- **Rewire**: selected schemas → selected worker **`output:` frontmatter** (KD-002; caller
  `outputSchema` is a per-call override, not the default path — CR-28); policies → prose in
  commands and agent prompts; skills → `autoloadSkills` frontmatter.
- **Fix**: installer component map, `config.yml` protection, LSP contradiction,
  `read-summarize` reversal, tech-lead ambiguity.
- **Replace**: benchmark script, validation tiers.
- **Remove**: `template/.omp/policies/` and `template/.omp/schemas/` cease to exist
  (KD-001). Their content is re-homed, not relabelled in place — a header does not undo
  what the directory path claims.

---

## B. Migration Ordering Constraint

The ordering is forced by dependency, not preference:

1. **Correctness first.** A P0 bug makes every downstream measurement meaningless.
   Measuring token efficiency on a template whose commands were never installed
   measures nothing.
2. **Wiring before optimization.** Structured output must actually be enforced
   before "results are compact" is a testable claim.
3. **Validation before evaluation.** L0/L1 validation must pass before L3 fixtures produce trustworthy numbers.
4. **Evaluation before expansion.** No new mechanism (memory, advisor, specialist
   skills) until v0 has a measured baseline.

---

## C. What Changes, By File

| File | Action | Reason |
|---|---|---|
| `scripts/install-template.ps1` | Fix component map; protect `config.yml`; honor `$Force`; add manifest; validate component names | P0-1, P0-4, F-04 |
| `scripts/uninstall-template.ps1` | Align params with installer; manifest-driven restore | P1-11 |
| `scripts/validate-template.ps1` | Add L0 (Static) + L1 (Discovery) tiers | P1-12 |
| `scripts/benchmark.ps1` | Replace with real execution or rename to reflect reality | P1-13 |
| `template/.omp/agents/<selected-worker>.md` | The runtime agent file set is derived from the Topic 03-selected topology manifest. Apply only the tools, `blocking`, output schema, skill autoload, isolation policy, and collision-safe name consumed by each selected contract; remove unselected baseline adapters. | P0-3, P0-5, P1-6, P1-8, Topic 03 |
| `template/.omp/agents/tech-lead.md` | **MOVE to `docs/roles/tech-lead.md`** (CR-33) — every `.md` under an agents dir is loaded as an active `AgentDefinition` by `loadAgentsFromDir()`; a "documentation-only" agent file does not exist as a category. Remove from the installer's `agents` component manifest. | P0-2, CR-33 |
| `template/.omp/commands/*.md` | Inline policy prose; pass explicit output overrides only when needed; request `isolated: true` only on a selected concurrent-writer path; remove `policy:*` refs | P0-6, P0-7 |
| `template/.omp/config.yml` | Add install guidance; keep only custom aliases/settings consumed by the selected topology | P0-4, Topic 03 |
| `template/.omp/schemas/*.yml` | **DELETE from `.omp/`** (KD-001). Result shapes become worker `output:` frontmatter (KD-002, gated on OQ-A); YAML retained under `docs/` as the generating source. `task-packet` is a dispatch input, not an output — `docs/` only | P0-7, KD-001 |
| `template/.omp/policies/*.yml` | **DELETE from `.omp/`** (KD-001). Re-home per phase-00 T-00.3: gates + routing + sizing inlined into the consuming command prose, budgets to `docs/` + validator thresholds, `escalation.yml` into agent "Must not" sections | P0-6, F-29, KD-001 |
| `template/.omp/skills/*/SKILL.md` | Keep bodies; ensure descriptions carry trigger boundaries | — |
| `docs/**` | Correct claims about schema/policy enforcement and validation meaning | Honesty |
| `registry/upstreams.yml` | Add OMP watched paths + pinned commit | §14 |

---

## D. Migration Risks

| Risk | Mitigation |
|---|---|
| Fixing the installer reveals further breakage that static validation hid | Expected; L0 (Static) validation exists to surface it |
| Renaming the former `reviewer` adapter, if retained, breaks existing command references | Rename atomically across the selected agent file + all consumers |
| Inlining schemas makes commands longer | Commands are lazy-loaded, not persistent — acceptable |
| Removing `read-summarize: false` changes worker behavior | That is the point; verify by measurement |
| Custom roles may collide with future OMP built-ins | Document; watch `model-roles.ts` |
| Docs corrections make the project look less complete | Accurate beats flattering |

---

## E. Rollback of the Migration Itself

The migration is a git-tracked change to a template repository. Rollback is
`git revert`. No live OMP state is touched during migration — the template is only
installed after review and approval, and installation has its own manifest-driven
rollback (§12).

---

## F. Definition of Migration Complete

1. All eight P0 items resolved with evidence.
2. All P1 items resolved or explicitly deferred with a recorded reason.
3. L0 (Static) + L1 (Discovery) validation pass; L3 (Behavioral) fixtures run and produce recorded numbers.
4. Docs contain no claim that contradicts verified runtime behavior.
5. `registry/upstreams.yml` records the pinned OMP commit and watched paths.
6. Every component has a documented removal procedure.
7. `validate-template.ps1` output no longer implies runtime correctness it cannot check.

---

## G. Post-Migration: What Becomes Possible

Only after the above:

- Specialist quality-gate skills (API compat, performance, migration, observability)
- Advisor role experiments
- Repository-map caching (Aider-style)
- Optional semantic retrieval (Serena) if LSP proves insufficient
- Memory backend evaluation
- Multi-reviewer workflows

Each requires its own before/after measurement against the v0 baseline established
in `13-validation-and-evaluation.md`. Without that baseline, none of them can be
shown to help — which is why the baseline is the real deliverable of v0.
