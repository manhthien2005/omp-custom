# 16 — Migration Plan

> OPUS PROPOSED SPEC v1 | How to get from the current state to the target architecture.

---

## A. Migration Stance

The current template is **not** a failed design. Its intent, its agent-role
decomposition, its structured result contracts, and its coding constitution are
sound and worth keeping. What is broken is the **runtime wiring** — the connection
between good intentions and OMP primitives.

So this is a **repair-and-rewire migration**, not a rewrite. Concretely:

- **Keep**: `AGENTS.md` constitution, `RULES.md` invariants, all five agent role
  definitions, the three workflow sizes, the four result contracts, the
  context-budget targets, the three skills.
- **Rewire**: schemas → inline `outputSchema` in commands; policies → prose in
  commands and agent prompts; skills → `autoloadSkills` frontmatter.
- **Fix**: installer component map, `config.yml` protection, LSP contradiction,
  `read-summarize` reversal, tech-lead ambiguity.
- **Replace**: benchmark script, validation tiers.
- **Reclassify**: `policies/` and `schemas/` from runtime to documentation.

---

## B. Migration Ordering Constraint

The ordering is forced by dependency, not preference:

1. **Correctness first.** A P0 bug makes every downstream measurement meaningless.
   Measuring token efficiency on a template whose commands were never installed
   measures nothing.
2. **Wiring before optimization.** Structured output must actually be enforced
   before "results are compact" is a testable claim.
3. **Validation before evaluation.** Level 1/2 validation must pass before Level 3
   fixtures produce trustworthy numbers.
4. **Evaluation before expansion.** No new mechanism (memory, advisor, specialist
   skills) until v0 has a measured baseline.

---

## C. What Changes, By File

| File | Action | Reason |
|---|---|---|
| `scripts/install-template.ps1` | Fix component map; protect `config.yml`; honor `$Force`; add manifest; validate component names | P0-1, P0-4, F-04 |
| `scripts/uninstall-template.ps1` | Align params with installer; manifest-driven restore | P1-11 |
| `scripts/validate-template.ps1` | Add Level 1 + Level 2 tiers | P1-12 |
| `scripts/benchmark.ps1` | Replace with real execution or rename to reflect reality | P1-13 |
| `template/.omp/agents/explorer.md` | Add `lsp` to tools; remove `read-summarize: false`; add `autoloadSkills` | P0-3, P1-6 |
| `template/.omp/agents/implementer.md` | Add `lsp` to tools; add `autoloadSkills`; note isolation | P0-3, P1-8 |
| `template/.omp/agents/verifier.md` | Remove `read-summarize: false`; add `autoloadSkills` | P1-6 |
| `template/.omp/agents/reviewer.md` | Rename to avoid bundled collision; remove `read-summarize: false`; add `autoloadSkills` | P0-5, P1-6 |
| `template/.omp/agents/tech-lead.md` | Resolve dead-abstraction ambiguity | P0-2 |
| `template/.omp/commands/*.md` | Inline `outputSchema`; inline policy prose; explicit `isolated: true`; remove `policy:*` refs | P0-6, P0-7 |
| `template/.omp/config.yml` | Add install guidance; keep role aliases | P0-4 |
| `template/.omp/schemas/*.yml` | Reclassify as docs; add header stating no runtime role | P0-7 |
| `template/.omp/policies/*.yml` | Reclassify as docs; add header; remove or wire `escalation.yml` | P0-6, F-29 |
| `template/.omp/skills/*/SKILL.md` | Keep bodies; ensure descriptions carry trigger boundaries | — |
| `docs/**` | Correct claims about schema/policy enforcement and validation meaning | Honesty |
| `registry/upstreams.yml` | Add OMP watched paths + pinned commit | §14 |

---

## D. Migration Risks

| Risk | Mitigation |
|---|---|
| Fixing the installer reveals further breakage that static validation hid | Expected; Level 1 validation exists to surface it |
| Renaming `reviewer` breaks existing command references | Rename atomically across agent file + all commands |
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
3. Level 1 + Level 2 validation pass; Level 3 fixtures run and produce recorded numbers.
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
