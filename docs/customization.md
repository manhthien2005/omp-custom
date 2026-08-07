# Customization Guide

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
  tech-lead: omniroute/codex/gpt-5.6-sol-high
  explorer: omniroute/codex/gpt-5-mini      # faster/cheaper for symbol lookup
  implementer: omniroute/codex/gpt-5.6-sol-high
  verifier: omniroute/codex/gpt-5-mini
  reviewer: omniroute/codex/gpt-5.6-sol-high
```

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

### 4. Override policies

Copy a policy file to your project `.omp/policies/` and edit it:

```powershell
Copy-Item template\.omp\policies\quality-gates.yml .omp\policies\quality-gates.yml
# Edit as needed
```

Policies are plain YAML files. They are not runtime-loaded by OMP — they are referenced by agent instructions.

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

## What NOT to customize without benchmarking

- The five core agent responsibility contracts (tech-lead, explorer, implementer, verifier, reviewer)
- The workflow flow definitions (quick/standard/orchestrated steps)
- The schema field lists (other services may depend on these fields)
- The config baseline settings (memory.backend, compaction strategy, etc.)

Changes to these require a before/after benchmark recorded in `registry/adoption-ledger.yml`.
