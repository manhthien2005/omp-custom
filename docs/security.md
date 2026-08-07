# Security Guide

See `docs/research/security-analysis.md` for the full threat model and analysis.

## Summary of security properties

### What the template does NOT do

- Does not connect to external services or APIs
- Does not write to any OMP live directory without explicit user confirmation
- Does not execute upstream scripts from cloned repositories
- Does not store API keys, tokens, or credentials anywhere
- Does not enable persistent memory or autolearn
- Does not install MCP servers

### What the template does

- Defines agent prompts in plain `.md` files (reviewable before installation)
- Defines workflows, skills, schemas, and policies as plain YAML/Markdown
- Installs only to directories the user explicitly specifies
- Creates a timestamped backup before every installation
- Validates against a secrets pattern list before accepting any file

## Secret prevention

The following patterns trigger validation failure:

- `sk-[a-zA-Z0-9]{20,}` — OpenAI-style API keys
- `ghp_[a-zA-Z0-9]{36}` — GitHub personal access tokens
- `AIza[0-9A-Za-z\-_]{35}` — Google API keys
- `AKIA[0-9A-Z]{16}` — AWS access key IDs
- `Bearer [a-zA-Z0-9+/]{40,}` — bearer tokens

Run before committing:

```powershell
.\scripts\validate-template.ps1
```

## Prompt injection awareness

The template includes agent system prompts that define clear boundaries. However, be aware:

- File content read by agents may contain adversarial instructions
- Task descriptions from external sources should be treated with the same care as any input
- The `RULES.md` sticky rule re-attachment is a defense-in-depth measure, not a complete mitigation

## Reporting security issues

Do not open public issues for security vulnerabilities. Report to the project maintainer directly.
