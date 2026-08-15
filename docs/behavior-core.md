# Portable Behavior Core

<!-- topic08-projection:behavior-core -->

Status: `IMPLEMENTED_NOT_PROMOTED` for OMP. The portable manifest is the selected authority;
runtime promotion remains a later evidence decision.

selected roster: task-triage, systematic-debugging, evidence-before-completion

## Placement and injection ownership

| Behavior | Installed location | Injection owner |
|---|---|---|
| Main-session constitution | `.omp/RULES.md` and `.omp/AGENTS.md` | Main OMP session |
| Task triage | `.omp/skills/task-triage/SKILL.md` | Lazy, selected by the Tech Lead |
| Systematic debugging | `.omp/skills/systematic-debugging/SKILL.md` | Lazy, selected by the current actor |
| Completion evidence | `.omp/skills/evidence-before-completion/SKILL.md` | Worker autoload plus the main-session invariant |
| Lifecycle bootstrap | `.omp/extensions/agent-task-boundary.js` | Main-session `agent_tasks` tool |
| Mutation boundary | `.omp/extensions/agent-task-boundary.js` | OMP `tool_call` gate |

The only intentional behavior duplication is completion evidence: the main session sees the
short invariant and Worker receives the compact skill body. Worker-only autoload is exact;
Cheap Scout and Reviewer autoload no skill; missing autoload names fail before managed dispatch.

The manifest does not impose a permanent three-skill ceiling. A later skill is added only through
the reviewed manifest procedure below, with its own consumer, budget, provenance, and fixtures.

## Trigger contract

| Skill | Positive boundary | Negative boundary |
|---|---|---|
| `task-triage` | Requirements, scope, or acceptance are materially unclear | A narrow request already identifies the change and success condition |
| `systematic-debugging` | A failure is unexplained or a prior fix did not address the cause | A direct mechanical edit has no observed failure to diagnose |
| `evidence-before-completion` | Worker is about to claim completed, fixed, passing, or done | Progress, planning, or an honest partial/blocked/failed result |

The six files under `evals/triggers/topic08/` are deterministic contract fixtures. Model-assisted
trigger semantics remain unpromoted until Topic 11; Topic 08 does not infer model behavior from
static text.

## Explicit lifecycle and mutation boundary

agent_tasks is explicit and main-session only. It accepts exactly these routine operations:

`init-project`, `status`, `create-phase`, `transition-phase`, `create-task`,
`set-continuity-contract`, `bind-worktree`, `checkpoint`, `claim`, `create-work-unit`, `freeze`,
`check`, `promote-artifact`, `record-evidence`, `begin-handoff`, `accept-handoff`, `close`, and
`invalidate`.

The tool supplies trusted workspace, session, and runtime fields to the Topic 04 state core. It
does not expose takeover, cleanup, restore, purge, lock recovery, or migration. A child session
cannot call it.

Read-only diagnosis remains available through `read`, `grep`, `glob`, `ast_grep`, `lsp`, and
permitted retrieval even before a task exists. Generic `edit`, `write`, and `bash` require exactly
one valid managed task binding in the main session, or a valid canonical Topic 06 child packet.
Missing or ambiguous state refuses mutation. The explicit lifecycle tool prevents a bootstrap
deadlock without allowing a shell/write bypass.

Logging, metrics, and notification failures are warnings only after the deterministic allow/block
decision; they never reverse that decision.

## Runtime adapters and external capabilities

OMP: `IMPLEMENTED_NOT_PROMOTED` / installable true.

Claude: DESIGNED_NOT_VERIFIED / installable false.

Claude has a complete placement mapping in the manifest, but no Claude runtime file is generated
or installed until a real compatible runtime and quota are available. Missing Opus never blocks
the OMP path; the Tech Lead uses the approved available reviewer fallback.

MCP servers, CodeGraph, web search, LSP, and similar integrations provide capabilities only. They
never own policy, task classification, workflow selection, acceptance, or lifecycle authority.

## Budgets

| Surface | Limit |
|---|---:|
| `RULES.md` target / hard warning | 700 / 800 approximate tokens |
| Skill description | 80 approximate tokens |
| Visible skill catalog | 900 approximate tokens; soft 10, hard 12 entries |
| Worker autoload body | 500 approximate tokens |
| Lazy skill body | 900 approximate tokens |

Approximate token validation uses the approved conservative character estimate. A budget failure
is a contract failure; it is not repaired by hiding a selected skill.

## Change procedure

1. Add or edit the skill and its positive/negative trigger fixtures.
2. Update `template/.omp/contracts/behavior-manifest.json`: status, consumers, injection owner,
   budgets, provenance, license, and replacement if applicable.
3. For deprecation, remove visibility/autoload and name a replacement. For removal, use status
   `removed`, a null hash, hidden visibility, and no autoload consumer.
4. Regenerate reviewed hashes:

   ```powershell
   pwsh -NoProfile -File scripts/update-skill-lock.ps1
   ```

5. Check without writing and run the focused suite:

   ```powershell
   pwsh -NoProfile -File scripts/update-skill-lock.ps1 -Check
   node --test scripts/tests/topic08-behavior-core.Tests.mjs scripts/tests/topic08-skill-contracts.Tests.mjs
   pwsh -NoProfile -File scripts/validate-topic08-behavior-core.ps1 -RepositoryRoot .
   pwsh -NoProfile -File scripts/tests/topic08-validator-mutations.Tests.ps1
   ```

Do not hand-edit generated hashes as the final operation. The check command must reproduce the
same manifest, lock, and component mirror without writes.

## Install, rollback, and retained state

Install/update stages and validates the manifest-coupled behavior files before target mutation.
Rollback uses the local backup snapshot and restores only attributable installed bytes.
agent-tasks operational state is retained on uninstall/rollback because it lives outside the
installed `.omp` component. Removing behavior files must never delete task authority, session
history, provider credentials, or user-owned model catalogs.

Authoritative details:

- [Topic 08 design](superpowers/specs/2026-08-14-topic-08-portable-behavior-core-runtime-adapters-design.md)
- [Selected behavior manifest](../template/.omp/contracts/behavior-manifest.json)
- [State protocol](../template/.omp/state/PROTOCOL.md)
- [Managed agent boundary](agent-boundaries.md)
- [Managed context continuity](context-continuity.md)
