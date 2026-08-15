# Customization Guide

<!-- topic08-projection:behavior-core -->
Extend behavior through the reviewed manifest procedure in [`behavior-core.md`](behavior-core.md),
not by adding an untracked skill or agent autoload. The current three-skill roster is a selected
minimum, not a permanent cap; every addition needs a consumer, budget, provenance, trigger pair,
component hash, and focused validation.

<!-- topic05-doc:customization -->
CodeGraph may be enabled per project as an optional component, but do not make it default or alter
its process/index authority from agent prompts. Tune only source-fitness guidance and benchmark it
against native retrieval; keep Scout and Reviewer authority independent. See
[`retrieval.md`](retrieval.md).

> Current Topic 03 guide. The selected custom-agent manifest is `cheap-scout`, `worker`, and
> `reviewer`; the Tech Lead remains the main session.

## What to customize per project

### 1. AGENTS.md — Project section (required)

The template's `AGENTS.md` contains a **Project** section with placeholders. Fill these in for every project:

```markdown
## Project

### Build and test commands

\`\`\`
build: cargo build
test: cargo test
lint: cargo clippy
\`\`\`

### Architecture notes

This project is a REST API with three main modules:
- `src/auth/` — JWT authentication
- `src/api/` — route handlers
- `src/db/` — database access layer

All database mutations go through `src/db/` — never query the database from handlers.

### Conventions

- All public functions must have doc comments
- Error types in `src/errors.rs` — do not define ad hoc errors inline
```

Keep the Project section under 400 tokens. For longer architecture docs, use `@imports`.

### 2. config.yml — Model roles

Change the model for any role without editing agent definitions:

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

The gateway advertises `ds/deepseek-v4-flash` and `ds/deepseek-v4-pro`; OMP resolves them as
`omniroute/ds/...` selectors. Add those entries to the external user-owned
`~/.omp/agent/models.yml` catalog and configure provider credentials in OmniRoute. Never put a
credential in this repository.

Cheap Scout owns only read-only retrieval. Flash at maximum reasoning is primary, Pro at maximum
reasoning is the only model fallback, and the Tech Lead performs the needed retrieval if both fail.
Worker has no model fallback: omit per-spawn `effort` for normal `high`, and let the Tech Lead use
`effort: hi` for difficult `xhigh` work. Reviewer is always `xhigh`.

### 3. Add project-specific skills

Place custom skills in `.omp/skills/<name>/SKILL.md`:

```markdown
---
name: my-project-skill
description: Use when working with [specific domain]. Do NOT use for [non-applicable cases].
---

# My Project Skill

...
```

Skills must have `name:` and `description:` frontmatter for OMP native discovery.

### 4. Customize policy-derived contracts

Edit the consumer that owns the behavior: workflow sizing, routing, and selected quality gates
live in `.omp/commands/`; worker stop conditions live in `.omp/agents/`; main-session escalation
and packet/result boundaries live in `.omp/AGENTS.md`. Keep the matching human explanation under
`docs/policies/` synchronized when the change affects a documented contract.

Do not create a separate runtime policy file: OMP does not discover one, so it would drift from
the prompt or validator that actually applies the rule.

### 5. Add project-specific agents

Create `.omp/agents/<name>.md` for project-specific specialists:

```markdown
---
name: database-specialist
description: Handles schema migrations, query optimization, and database-specific review.
model: "@reviewer"
tools: read, grep, glob, bash
spawns: ""
---

You are the Database Specialist...
```

Project agents take precedence over user-level agents with the same name.

Adding another agent expands the selected manifest. Document its concrete benefit, capability
preflight, fallback, result consumer, and validation before installation; do not turn it into a
fixed workflow step.

Adding a file alone does not add it to the managed boundary. Topic 06 reconciles exactly the three
selected agent contracts and component-manifest hashes. Extending that set requires a versioned
boundary-policy/schema change, role-specific result validation, installer migration, and focused
tests. Do not edit generated `runtime.json`/`install-record.json` or bypass the launcher with an
untrusted extension order.

## What NOT to customize without benchmarking

- The three selected agent responsibility contracts (`cheap-scout`, `worker`, `reviewer`)
- Main-session Tech Lead ownership of classification, integration, fresh verification, and acceptance
- Scout-only Flash → Pro → Tech Lead retrieval fallback order
- Worker `high`/`xhigh` selection and Reviewer fixed `xhigh`
- Risk-gated review, including the rule that Opus is preferred rather than required
- The workflow definitions (Quick/Standard/Orchestrated are benefit gates, not a fixed chain)
- The selected agent `output:` fields and `.omp/contracts` boundary schemas
- The managed continuity profile and `/safe-compact` transaction (automatic semantic paths stay off)

Changes to these require a before/after benchmark recorded in `registry/adoption-ledger.yml`.
