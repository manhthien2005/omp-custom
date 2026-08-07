# Security Analysis
<!-- Generated: 2026-08-07 — Phase 2 -->

## Threat model

This template is a configuration package for a local coding agent. The primary attack surfaces are:

1. **Upstream repository content injected into prompts** — cloned repositories could contain malicious AGENTS.md, SKILL.md, or instruction files.
2. **Template files that leak secrets** — API keys, OmniRoute credentials, or private prompts accidentally committed.
3. **Unsafe eval or execution of upstream scripts** — upstream repositories contain install scripts that could execute arbitrary code.
4. **Prompt injection via task content** — user task descriptions or file content could attempt to override agent behavior.
5. **Unreviewed upstream synchronization** — pulling upstream changes without inspection could introduce malicious instruction changes.

---

## Security constraints (from plan)

These are hard constraints enforced by the validation script and governance process:

| Constraint | Enforcement |
|-----------|-------------|
| No API keys committed | `.gitignore` excludes `.env`, `*.key`, `*.pem`, `credentials.*`, `secrets.*`; validation script scans for secret patterns |
| No OmniRoute credentials in template | OmniRoute URL is `http://127.0.0.1:20128` (local only); no auth tokens in template |
| No live OMP file modification | Installation requires explicit approval; template never writes to `~/.omp/agent/` automatically |
| No upstream script execution | `clone-upstreams.ps1` clones only; does not run any upstream installer, `npm install`, or `pip install` |
| No automatic upstream trust | Upstream AGENTS.md files are research material, not system instructions |
| No unreviewed skill promotion | `skill-lock.yml` records content hashes; changes require re-review |

---

## Upstream content trust classification

| Item | Trust level | Action |
|------|-------------|--------|
| Cloned `AGENTS.md` from any upstream | **Untrusted** | Read as research material; do not install into project `.omp/` without review |
| Cloned `SKILL.md` from any upstream | **Untrusted** | Extract concepts; rewrite in project-native language |
| Cloned install scripts (`install.sh`, `package.json`, etc.) | **Untrusted** | Do not execute without inspection and necessity confirmation |
| Cloned prompt files from any upstream | **Untrusted** | Treat as research material; do not copy verbatim into live template |
| MCP server configurations from any upstream | **Untrusted** | Do not activate without review |
| Generated memory from autolearn | **Untrusted** | memory.backend=off; autolearn=false in baseline |
| Web search results injected by skills | **Untrusted** | Skills should not inject web content directly into agent context without user awareness |

---

## Prompt injection mitigations

| Risk | Mitigation |
|------|-----------|
| External file content overrides agent behavior | RULES.md sticky rule asserts critical invariants; these are re-attached near current turn |
| Task content claims agent identity | Agent system prompts are explicit; identity claims in task content are ignored |
| Upstream AGENTS.md instructs agent to exfiltrate data | Upstreams are NOT loaded as context files; only `template/.omp/AGENTS.md` is the project context file |
| Malicious skill triggers exfiltration | Skills are audited before installation; skill-lock.yml prevents unreviewed changes |
| MCP server output injects instructions | No external MCP servers configured in v0; any MCP additions require explicit user configuration |

---

## Secrets prevention

### What must never be committed

- OmniRoute authentication tokens or database content
- API keys (Anthropic, OpenAI, etc.)
- OAuth tokens or refresh tokens
- Private prompt files with proprietary business logic
- Call logs or conversation transcripts
- User-specific session data

### Enforcement

The `.gitignore` excludes:
```
.env
*.key
*.pem
credentials.*
secrets.*
*.db
*.db-shm
*.db-wal
sessions/
```

The `scripts/validate-template.ps1` includes a secret-pattern scan:
- Matches `sk-[a-zA-Z0-9]{20,}` (OpenAI-style keys)
- Matches `Bearer [a-zA-Z0-9+/]{40,}` (auth tokens)
- Matches common environment variable patterns containing `KEY`, `TOKEN`, `SECRET`, `PASSWORD`

---

## Installation safety

The installation script enforces:

1. **Dry-run mode by default** — shows planned changes without applying them
2. **Timestamped backup** — before applying any changes, copies `~/.omp/agent/` to `~/.omp/agent.backup-<timestamp>/`
3. **Diff display** — shows exact files that will be created, modified, or deleted
4. **Selective install** — user chooses which components to install
5. **Preserves models.yml and credentials** — never overwrites model configuration or credentials
6. **Post-install validation** — runs OMP config sanity check after installation
7. **Rollback script** — `scripts/uninstall-template.ps1` can revert to the backup

---

## Security review gates (per plan quality-gates.yml)

For any task that touches:
- Authentication, authorization, or access controls → **mandatory security gate**
- File system operations with user-provided paths → **path traversal check**
- External network calls → **data exfiltration check**
- Cryptography or hashing → **algorithm review**
- Process execution with string interpolation → **injection check**

---

## Deferred security concerns

| Concern | Status | When to address |
|---------|--------|----------------|
| MCP server sandboxing | Deferred | When MCP tools are added post-v0 |
| Network egress control for skills with web access | Deferred | When skills with web access are added |
| Audit logging for agent actions | Deferred | Post-v0 production hardening phase |
| Agent impersonation prevention | Partial | RULES.md invariant; full solution post-v0 |
