# Phase 01 — Runtime Correctness

> OPUS PROPOSED SPEC v1 | Fix every defect that causes silent failure or data loss.

**Depends on**: phase-00
**Blocks**: phase-02

---

## Objective

Eliminate all eight P0 defects. After this phase the template installs completely,
loses no user data, contains no self-contradicting agent configuration, and has no
unresolvable references.

---

## Rationale

These are not stylistic issues. Four of them fail **silently**: the installer
reports success while installing nothing; an agent is told to use a tool it cannot
call; a live global config is overwritten without warning; a project agent shadows a
bundled one. Silent failure is the worst class of defect in an autonomous system
because nothing surfaces it — which is why this phase precedes everything else.

---

## Tasks

### T-01.1 — Fix the installer component map (P0-1)

`install-template.ps1` maps `"workflows" → "workflows"`, but the directory is
`commands/`. The `default` switch branch does `Test-Path` and silently contributes
nothing when the path is missing.

Fix:
- rename the component to `commands` (map `"commands" → "commands"`)
- validate every requested component against the known set; **fail** on unknown
- assert a non-zero planned file count per requested component

**Acceptance**: default install plans files from `commands/`; `-Components bogus`
exits non-zero with a message naming valid components.

### T-01.2 — Protect config.yml from overwrite (P0-4)

`config.yml` is absent from `$protected`, so `-Target user` overwrites
`~/.omp/agent/config.yml` — the user's live global baseline. Data loss.

Fix:
- add `config.yml` to the protected set
- when a destination `config.yml` exists, write `config.yml.new` and print a merge
  instruction instead of overwriting
- when absent, copy normally

**Acceptance**: with an existing `config.yml`, install leaves it byte-identical and
produces `config.yml.new`. Verified by hash comparison.

### T-01.3 — Resolve the LSP contradiction (P0-3)

`explorer.md` instructs "Use LSP hover, references, and grep" but its `tools:` list
is `read, grep, glob`. `parseAgentFields` treats `tools` as a closed allowlist (plus
auto-appended `yield`), and `task.enableLsp` defaults to **false**, so `lsp` is
doubly unavailable.

Fix (all three parts required):
- add `lsp` to `explorer.md`, `implementer.md`, **and `reviewer.md`** tool lists — per the CR-17 authoritative table in `spec/07§A` (Reviewer requires `lsp references` for blast-radius checks)
- document `task.enableLsp: true` as a required setting, and state the graceful
  degradation to grep/glob when it is off

**Acceptance**: no agent prompt names a tool absent from its own allowlist. Explorer, Implementer, and Reviewer each carry `lsp` in their `tools:` lists. The LSP prerequisite is documented where a user will see it before installing.

### T-01.4 — Reverse the read-summarize inversion (P1-6, promoted)

`explorer.md`, `verifier.md`, and `reviewer.md` set `read-summarize: false`, which
*disables* summarization and *increases* context — the opposite of the
context-budget policy in the same repository.

Fix: remove `read-summarize: false` from all three. Set it only where a
justification is written down (verifier reading exact failure output is the one
defensible case, and it should be argued explicitly, not defaulted).

**Acceptance**: no agent disables summarization without an inline written reason.

### T-01.5 — Resolve the bundled-agent name collision (P0-5)

OMP bundles an agent named `reviewer` (`task/agents.ts`). Project agents win by
first-wins precedence in `task/discovery.ts`, so the template's `reviewer` silently
shadows it.

Fix: rename to `diff-reviewer` (or accept the shadow **and document it explicitly**).
Update every command reference atomically.

**Acceptance**: no template agent name collides with `scout`, `designer`, `reviewer`,
`security-reviewer`, `librarian`, `task`, `sonic` — or the collision is documented as
deliberate.

### T-01.6 — Remove unresolvable policy references (P0-6)

`tech-lead.md` and `orchestrated.md` reference `policy:workflow-sizing` and
`policy:quality-gates`. No resolver exists; the model cannot fetch them.

Fix: inline the decision content as prose at each reference site. Keep the YAML as
the human-authoritative source (phase-00 labeled it).

**Acceptance**: zero `policy:` references remain in `agents/` and `commands/`.

### T-01.7 — Replace prose schema references with real enforcement (P0-7)

Agents say "Return schema: `agent-result`". Nothing enforces this at runtime.

**CR-03 correction**: OMP resolves output schema via `resolveSchema` in
`task/structured-subagent.ts:176-188` with precedence:
1. caller task `outputSchema` (key presence, not truthiness)
2. agent frontmatter `output:` field
3. session-level `outputSchema`

The original claim "OMP enforces only an `outputSchema` passed in the task call" was
wrong. An agent's `output:` frontmatter is a first-class, runtime-enforced schema
source. Inlining a schema in every task dispatch duplicates the source of truth and
contradicts DR-2.

Fix:
- Put the canonical schema in each worker agent's `output:` frontmatter (per DR-2
  and `06-structured-output.md`). This is the primary enforcement path.
- In task dispatch commands, use inline `outputSchema` **only** as an explicit caller
  override (e.g., a one-off call that needs a narrower or different schema).
- Add `schemaMode: "strict"` where strict enforcement is required.

**Acceptance**: every worker agent (`explorer`, `implementer`, `verifier`, `reviewer`)
has a valid JSON Schema in its `output:` frontmatter. Commands may carry inline
`outputSchema` for explicit overrides; this is not required for every dispatch.
Zero agents rely on prose "Return schema:" as the sole contract.

### T-01.8 — Resolve the tech-lead dead abstraction (P0-2) + main-session model/thinking contract (CR-06)

`tech-lead.md` exists but no command spawns it; the main session performs the role.
Its `model: "@tech-lead"` and `thinking-level: high` frontmatter **never apply** — agent frontmatter is only processed at spawn time, not for the main session.

**CR-06 open question:** When the main session IS the Tech Lead, what exact runtime mechanism ensures it uses `@tech-lead` routing and `high` thinking level? Two options:

- **Option A — Deterministic launch contract:** Document and enforce that the main session MUST be started with the `@tech-lead` model role and `high` effort. The workflow entrypoint or installation docs must state this as a hard requirement, not a recommendation.
- **Option B — User-controlled:** Accept that main-session model/thinking is user-controlled. State explicitly in `AGENTS.md` that the template does NOT guarantee `@tech-lead` routing for the main Tech Lead session. Update any architecture claim that assumes guaranteed routing.

Fix: choose one option, implement it, and document the choice in `AGENTS.md`.

**Acceptance**: the spec and `AGENTS.md` answer unambiguously: "What model and thinking level does the Tech Lead use, and what guarantees it?" Phase-01 exit criteria must include a test confirming whichever contract was chosen (e.g., for Option A: attempt a command with a non-tech-lead session and confirm the expected behavior; for Option B: confirm no claims assume guaranteed routing).

### T-01.9 — Honor the installer's `$Force` parameter (F-04)

`$Force` is declared and never read; `Copy-Item -Force` runs unconditionally.

Fix: without `-Force`, refuse to overwrite existing non-protected files and report
the collisions. With `-Force`, overwrite after backup.

**Acceptance**: a second install without `-Force` reports collisions and changes
nothing.

---

## Deliverables

- Fixed `install-template.ps1` (component map, config protection, `$Force`, validation)
- Corrected agent frontmatter across all five files
- Commands with inline `outputSchema` and inline policy prose
- Resolved tech-lead topology, documented in `AGENTS.md`

---

## Verification

```powershell
# 1. Dry-run plans commands/ files
.\scripts\install-template.ps1 -Target project -ProjectDir "$env:TEMP\omp-test" -DryRun

# 2. Unknown component fails
.\scripts\install-template.ps1 -Components bogus -DryRun   # expect non-zero exit

# 3. config.yml preserved
#    install twice into a temp dir; hash config.yml before/after; expect identical
#    and expect config.yml.new to exist

# 4. Second install without -Force reports collisions and makes no changes
```

Static checks: zero `policy:` references in `agents/`+`commands/`; every tool named
in an agent prompt present in that agent's `tools:`; no agent name in the bundled
list; every `task` dispatch carries `outputSchema`.

---

## Exit Criteria

- [ ] P0-1 installer installs commands
- [ ] P0-2 tech-lead ambiguity resolved
- [ ] P0-3 LSP contradiction resolved
- [ ] P0-4 config.yml never overwritten
- [ ] P0-5 no undocumented bundled-name collision
- [ ] P0-6 no `policy:` references
- [ ] P0-7 real `outputSchema` enforcement
- [ ] P0-8 `read-summarize` inversion corrected
- [ ] F-04 `$Force` honored
- [ ] Install → basic rollback succeeds (config.yml backup restored; no data loss from a failed install) — CR-16: full round-trip fidelity guarantee moves to phase-05

---

## Risks

| Risk | Mitigation |
|---|---|
| Fixing the installer exposes further breakage | Expected; that is what phase-01 is for |
| Renaming `reviewer` breaks references | Rename atomically across all files in one change |
| Inlining schemas lengthens commands | Commands are lazy-loaded, not persistent context |
| `lsp` requires a setting users may not enable | Document the prerequisite; degrade to grep/glob |
