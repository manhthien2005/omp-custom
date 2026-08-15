# Phase 01 — Runtime Correctness

<!-- topic06-projection:phase-01 -->
## Topic 06 runtime consumer

Install and discover the exact `cheap-scout`, `worker`, and `reviewer` contracts consumed by the
managed wrapper. Their closed `output:` blocks, tools including OMP-appended `yield`, blocking
mode, no-spawn boundary, model aliases, and effort metadata must reconcile exactly. Historical
`.omp/schemas` files are not runtime prerequisites.

<!-- topic07-projection:phase-01 -->
## Topic 07 runtime consumer

Discover the trusted continuity adapter from the manifest-coupled `agent-boundary` component,
register argument-free `/safe-compact`, and prove the effective disabled automatic-compaction
profile can be read and reasserted before provider work. `create-task` requires exact
`workflow_class` and `locked_decisions`; legacy classification uses the explicit Topic 04 CAS
operation. Any missing extension, settings surface, persisted-session identity, or state
projection fails closed rather than exposing a weaker managed path.

> OPUS PROPOSED SPEC v1 | Fix every defect that causes silent failure or data loss.
>
> **Topic 02 supersession boundary:** Runtime migration consumes the Topic 03-selected
> topology manifest. Former worker filenames below identify frozen-baseline defects and
> candidate adapters; acceptance derives the installed roster and capabilities from the
> selected manifest.
>
> **KD-027 target:** exactly `cheap-scout`, `worker`, and `reviewer` parse with their closed
> schemas and effort contracts; `tech-lead`, `explorer`, `implementer`, and `verifier` are absent
> from discovery. Phase 01 fixes parser/tool/frontmatter defects without reintroducing the old
> roster.

**Depends on**: phase-00
**Blocks**: phase-02, phase-05 (P5 depends only on P1 — see `README.md §6`)

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

### T-01.3 — Resolve selected LSP capability contradictions (P0-3)

`explorer.md` instructs "Use LSP hover, references, and grep" but its `tools:` list
is `read, grep, glob`. `parseAgentFields` treats `tools` as a closed allowlist (plus
auto-appended `yield`), and `task.enableLsp` defaults to **false**, so `lsp` is
doubly unavailable.

Fix for the Topic 03-selected topology:
- add `lsp` to every selected LSP-consuming worker whose contract requires symbol-aware
  retrieval; the old Explorer/Implementer/Reviewer mapping is candidate input only
- **deploy** `task.enableLsp: true` as an installer-owned project setting when at least one
  selected contract consumes it; do not own the key for a topology with no LSP consumer
- the selected LSP-consuming path must fail closed before dispatch or acceptance when any of
  the four conditions is unavailable, naming the exact failed condition
- runtime validation rejects the selected LSP path when no applicable language server exists or
  a required call reports details.success false; four-gate registration is not semantic success
- continuation requires remediation or explicit selection of a different contract that does not
  consume LSP, followed by manifest/task-contract reconciliation and path revalidation

**CR-40/CR-41 — documenting the setting is not deploying it, and three conditions are not all
conditions.** This task previously said "document `task.enableLsp: true` as a required setting".
Documentation does not change effective settings, and the default is `false`
(`config/settings-schema.ts:4615-4617`), so on a default machine the allowlist fix alone leaves
`lsp` granted at the agent and withheld at the gate. The setting becomes an installer-owned
conditional project key (`spec/12 §C-1`, `phase-05` T-05.3); the user/global target requires
`-EnableSubagentLsp`. LSP availability is a **four-condition conjunction** —
allowlist ∧ `task.enableLsp` ∧ parent-session LSP ∧ `lsp.enabled` — detailed in
`spec/07 §A-1`, with T-00.E5 cases A–F distinguishing the five remediations.

### T-01.3b — Add `blocking: true` to every selected stage-barrier worker (CR-39)

Mechanically trivial, architecturally load-bearing. Add to each selected spawned worker whose
completed result gates a later stage:

```yaml
blocking: true
```

Without it, `async.enabled` (default **`true`**) routes that worker to the `AsyncJobManager`,
the `task` call returns before the work completes, and its stage barrier in
`04-workflow-sizing.md` silently breaks — the parent proceeds on an empty result set. Full
analysis in `08-isolation-and-concurrency.md §C-1`; rationale for `blocking` over disabling
`async.enabled` in §C-1.3. This does **not** serialize batches: all-blocking takes OMP's
synchronous fan-out path, preserving concurrency and input ordering.

**Acceptance**: no selected agent prompt names a tool absent from its own allowlist. Every
selected LSP-consuming worker carries `lsp`; `task.enableLsp: true` is a conflict-preserving
project key only when consumed. Every selected stage-barrier worker carries `blocking: true`.
The LSP prerequisite and fail-closed selected-path behavior are documented where a user will
see them before installing. Runtime validation rejects the selected LSP path when no applicable
language server exists or a required call reports details.success false. A sequential inline
Orchestrated topology is not forced to invent workers, batching, or LSP consumers.

### T-01.4 — Reverse the read-summarize inversion (P1-6, promoted)

`explorer.md`, `verifier.md`, and `reviewer.md` set `read-summarize: false`, which
*disables* summarization and *increases* context — the opposite of the
context-budget policy in the same repository.

Fix: remove unjustified `read-summarize: false` from the frozen adapters. In the selected
topology, set it only where a responsibility-specific justification is written down (exact
failure-output reading is one defensible case, but it must be argued, not defaulted).

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
- Each selected spawned worker whose contract requires structured output puts the canonical
  schema in its `output:` frontmatter (per DR-2 and `06-structured-output.md`). This is the
  primary enforcement path.
- Every selected structured-result schema is fully linted before dispatch. The lint compiles the
  complete schema and rejects `$ref`, malformed/unrepresentable constructs, and required fields
  absent from the selected producer's instructions.
- In task dispatch commands, use inline `outputSchema` **only** as an explicit caller
  override (e.g., a one-off call that needs a narrower or different schema).
- Add `schemaMode: "strict"` where strict enforcement is required.

**Acceptance**: every selected spawned worker whose contract requires a structured result has a
valid JSON Schema in its `output:` frontmatter, with no fixed worker name or count. Commands
may carry inline `outputSchema` for explicit overrides; this is not required for every
dispatch. Zero selected structured-result producers rely on prose "Return schema:" as the sole
contract.

Runtime acceptance requires structuredOutput.status valid. `unavailable`, `invalid`, and
`schemaOverridden` results remain unvalidated and cannot satisfy the selected result contract.

### T-01.8 — Resolve the tech-lead dead abstraction (P0-2) + main-session model/thinking contract (CR-06)

`tech-lead.md` exists but no command spawns it; the main session performs the role.
Its `model: "@tech-lead"` and `thinking-level: high` frontmatter **never apply** — agent frontmatter is only processed at spawn time, not for the main session.

**CR-06 resolution — Option B selected:** Main-session model/thinking is **user-controlled**, not template-controlled.

The template does not create, own, or configure the main session. It cannot guarantee that the main Tech Lead runs `@tech-lead` or `high` thinking level — these are the user's session settings. Inventing an enforcement hook that does not exist in OMP would be a false contract.

Normative statement (to appear in `AGENTS.md`):
> The template does not guarantee that the main Tech Lead runs under `@tech-lead` or a fixed thinking level. Those settings belong to the launched main session. Role-based `model:` and `thinking-level:` frontmatter are deterministic only for spawned worker agents where that frontmatter is applied at spawn time.

**CR-33 — "documentation only" is not a category OMP recognizes inside `agents/`.** A file cannot be role-reference documentation *and* live under an agent discovery root. OMP v17.2.10 `task/discovery.ts` `loadAgentsFromDir()` enumerates every `*.md` (file or symlink) in `~/.omp/agent/agents/`, `.omp/agents/`, and each extension's `agents/` directory, and passes each one to `parseAgent()`. There is no opt-out marker, no `enabled: false` in the discovery filter, and no documentation-only class. Any `tech-lead.md` installed to an agents directory **is a live, discoverable, spawnable `AgentDefinition`** regardless of what prose says about it.

Leaving it there creates a second Tech Lead topology — a spawnable `tech-lead` agent with its own `model:`/`thinking-level:` routing alongside the main-session Tech Lead — which reintroduces precisely the recursion-budget, routing-divergence, and result-ownership ambiguities DR-1 resolved.

**Resolution: relocate out of agent discovery.**

```yaml
tech_lead_role_reference:
  old_path: template/.omp/agents/tech-lead.md
  new_path: docs/roles/tech-lead.md
  installed_as_agent: false
  discoverable_by_omp: false
  rationale: >
    DR-1 Option A puts the Tech Lead in the main session. A discoverable
    tech-lead agent would create a competing topology. Role-contract prose
    belongs in documentation, not in an OMP discovery root.
  content_destination:
    - orchestration procedure  -> the three command files
    - role contract / duties   -> AGENTS.md role map
    - historical rationale     -> docs/roles/tech-lead.md
```

The installer MUST NOT copy `docs/roles/tech-lead.md` into any `agents/` destination. L1
(Discovery) validation MUST assert that the installed project-worker set exactly matches the
Topic 03-selected topology manifest — and independently that a discovered `tech-lead` agent is
a validation FAIL, not a warning.

Fix:
- Update `AGENTS.md` with the above normative statement.
- Update DR-1 in `spec/README.md` to select the main-session Tech Lead placement.
- Remove any claim in any spec file that assumes guaranteed `@tech-lead` routing for the main session.
- **Move `template/.omp/agents/tech-lead.md` → `docs/roles/tech-lead.md`.** Fold its orchestration procedure into the three commands and its role contract into `AGENTS.md`. It is not installed as an agent and is not discoverable by OMP.
- Add an L1 (Discovery) assertion that no `tech-lead` agent is discovered post-install.

**Acceptance**: `AGENTS.md` states the main-session model contract explicitly (user-controlled). Zero spec files assert guaranteed `@tech-lead` routing for the main session. **No file named `tech-lead.md` exists under any `agents/` path in `template/` or at any install destination**; the role reference lives at `docs/roles/tech-lead.md`; L1 validation fails if OMP discovers a `tech-lead` agent.

### T-01.9 — Honor the installer's `$Force` parameter (F-04)

`$Force` is declared and never read; `Copy-Item -Force` runs unconditionally.

Fix: without `-Force`, refuse to overwrite existing non-protected files and report
the collisions. With `-Force`, overwrite after backup.

**Acceptance**: a second install without `-Force` reports collisions and changes
nothing.

---

## Deliverables

- Fixed `install-template.ps1` (component map, config protection, `$Force`, validation)
- Corrected frontmatter for selected worker adapters and selected command contracts
- Inline `outputSchema` only for selected explicit overrides; no inline policy prose
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
in a selected agent prompt present in that agent's `tools:`; no selected project agent name
collides with the bundled list; every selected worker with a structured output contract carries
a valid `output:` frontmatter schema; no agent relies on prose "Return schema:" as the
sole contract; inline caller `outputSchema` used only for explicit overrides (not
required on every dispatch — see DR-2 and T-01.7).

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
| `lsp` requires a setting users may not enable | Preserve the setting; stop the selected LSP path and require remediation or an explicit validated non-LSP contract |
