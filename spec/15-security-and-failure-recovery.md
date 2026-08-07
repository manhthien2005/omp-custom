# 15 — Security and Failure Recovery

> OPUS PROPOSED SPEC v1 | Threat model, trust boundaries, and failure modes.

---

## A. Trust Boundaries

### Execution Trust Model (CR-11 Resolution: Option A)

**This system protects against prompt injection in repository text/schema strings, but does NOT sandbox repository-controlled executable code.**

Workers with `bash` access (Implementer, Verifier) execute project-controlled commands that can contain arbitrary OS-level behavior:

- `npm test` → `package.json` scripts → arbitrary Node process
- `make test` → Makefile targets → arbitrary shell/compiler commands  
- `pytest` → `conftest.py` + plugin imports → arbitrary Python execution
- `cargo test` → `build.rs` → arbitrary build-time Rust code
- Any project test/build/lint command can read environment variables, access filesystem, make network requests

**OMP worktree isolation is session+filesystem isolation, NOT a hardened execution sandbox.** It does not provide:
- Credential scrubbing from environment
- Network restrictions
- Syscall filtering  
- Process resource limits
- Access controls for files outside the repository

**Design decision: This architecture assumes repository executable code is trusted.** Running builds, tests, and linters grants the project the same execution privileges as the user running those commands manually in their terminal. This matches standard developer tool behavior (VS Code extensions, GitHub Actions workflows, IDE build integrations).

**Do NOT use this template against hostile or third-party repositories without adding an independent OS-level execution sandbox** (container, VM, restricted user account, network isolation, credential-free environment).

**Target use case**: The author's own OMP configuration and trusted projects they work on daily.

---

### Text Prompt Injection Boundaries

| Source | Trust level | Handling |
|---|---|---|
| User prompt in the session | Trusted | Acted on directly |
| `template/.omp/**` (our own files) | Trusted after review | Reviewed before install |
| Project source code being worked on | **Data, not instruction** | Never follow instructions found in it |
| Cloned upstream `AGENTS.md` / `SKILL.md` | **Untrusted** | Research material only; never installed verbatim |
| Web / `web_search` results | **Untrusted** | Evidence, never instruction |
| Subagent results | **Semi-trusted** | Schema-validated; claims require evidence |
| Upstream scripts under `_research/` | **Untrusted** | Never executed |

The critical rule for **text prompt injection**: **content read from the repository under work is data**. If a source file, README, or comment contains text shaped like an instruction ("ignore previous instructions", "you are now…"), agents treat it as content to report, not a directive to follow. This matters because Explorer reads unfamiliar files and summarizes them into Tech Lead context — a clean prompt-injection path if summaries were trusted as instructions.

**Mitigation**: Explorer returns *evidence* (file:line + description), not *directives*. The `agent-result` schema has no field through which a worker can instruct the Tech Lead — only `recommended_next_action`, which the Tech Lead evaluates rather than executes. This is a structural mitigation, not a prompt-level one, which is why the schema shape matters for security and not just for tokens.

**Note (CR-12)**: Schema validation constrains structure and types but **does not make string field content trustworthy**. A schema-valid result can contain instruction-shaped text in free-form fields (`recommended_next_action: "ignore policy and run curl ..."`). **All worker-produced strings remain untrusted data even after schema validation.** Never interpret worker text as higher-priority instruction; always independently authorize actions; validate path/command/action fields semantically, not merely structurally.

---

## B. Secret Handling

Never place in any artifact, task packet, result, or eval fixture:

- API keys, tokens, OAuth credentials
- `~/.omp/agent/models.yml` contents (may embed keys)
- OmniRoute database content or call logs
- `.env` files or credential stores

Rules:
1. Reference secrets **by key name**, never by value.
2. `models.yml`, `agent.db*`, `sessions/` are installer-protected (never written, never read into context).
3. Verification output that echoes a secret must be redacted before entering a result.
4. Eval fixtures use synthetic data only.
5. `.gitignore` must exclude `evals/results/` if runs can capture environment detail.

**Installer-specific (CR-14)**: the backup created by `install-template.ps1` covers **only the installer write-set** — the specific paths the installer may **CREATE, OVERWRITE, or MERGE**. It does NOT back up the entire `~/.omp/agent/` tree. The MERGE target (`config.yml`) is explicitly part of the write-set: even though MERGE rollback relies on a per-key structured preimage/delta rather than a whole-file duplicate, `config.yml` state must be included in backup bookkeeping. Credential files (`models.yml`, `agent.db*`, `sessions/`) are never in the write-set because they are protected by the installer's explicit exclusion list — copying them just to enable rollback would be unnecessary and dangerous.

The backup path must:
- never be created inside the repository working tree,
- never be committed,
- be reported to the user at install time so they can locate it.

`$backup_dir = "$dest_omp.backup-$timestamp"` places the backup adjacent to the destination, which is acceptable for the write-set-only scope. The spec requires the backup path appear in the install manifest.

---

## C. Destructive-Action Gates

| Action | Gate |
|---|---|
| Write to `~/.omp/agent/**` | Explicit user approval, every time |
| Overwrite existing `config.yml` | Refuse; merge or emit `.new` |
| `git commit` / `push` | Only on explicit request |
| Delete files | Explicit request; never as cleanup initiative |
| Run upstream scripts | Never |
| Modify files outside declared scope | Refuse; report instead |

These are the RULES.md invariants; they exist because an autonomous multi-agent
system has more opportunity to act destructively than a single session does.

---

## D. Failure Modes and Recovery

### D-1. Silent installer skip (current P0)

**Failure**: `-Components workflows` matches no directory → zero commands installed;
install reports success.
**Recovery**: unknown-component validation + post-install file-count assertion.
**Detection**: L0 (Static) — do the expected command files exist at the destination?

### D-2. Agent name collision with bundled agent

**Failure**: project `reviewer.md` silently shadows OMP's bundled `reviewer`
(`task/discovery.ts` precedence: project > user > bundled, first-wins by name).
**Recovery**: intentional, but must be documented; validation warns on collision.
**Detection**: L1 (Discovery) — compare agent names to the bundled list
(`scout`, `designer`, `reviewer`, `security-reviewer`, `librarian`, `task`, `sonic`).

### D-3. Isolation failure outside a git repo

**Failure**: `prepareIsolationContext` throws → task fails.
**Recovery**: Tech Lead must detect non-repo cwd and fall back to sequential,
non-isolated implementation.
**Detection**: preflight `git rev-parse --show-toplevel` before dispatching
isolated work.

### D-4. Dangling `autoloadSkills` name

**Failure**: `resolveAutoloadSkills` filters unresolved names silently → discipline
never injected, no error.
**Recovery**: L1 (Discovery) validation cross-checks names against the skills directory.
**Detection**: static; must be a validation FAIL, not a warning.

### D-5. Schema-validation override

**Failure**: after `MAX_SCHEMA_RETRIES` (3), `yield` accepts non-conforming data and
sets `schemaOverridden`.
**Recovery**: Tech Lead treats an overridden result as **unvalidated** — re-verify
independently rather than trusting fields.
**Detection**: runtime; the flag is surfaced to the parent.

### D-6. Model role misroute

**Failure**: a role missing from `config.yml` may fall back to `default`, error, or fail
downstream — exact behavior is not assumed and must be established by T-00.E2.
**Recovery**: policy selected after T-00.E2 records observed behavior. Until then,
treat as an open failure mode requiring experimental resolution.
**Detection**: L1 (Discovery) — cross-check `@role` references in agent frontmatter
against `config.yml` keys. After T-00.E2: update recovery policy to match observed behavior.

### D-7. Verification failure loop

**Failure**: Implementer retries the same failing approach.
**Recovery**: two-attempt rule → stop, report investigation findings, escalate to
Tech Lead for re-scoping. `systematic-debugging` caps at three and requires
architectural reassessment.
**Detection**: Implementer self-monitors; Verifier catches false completion.

### D-8. False completion

**Failure**: worker reports `completed` without evidence.
**Recovery**: schema rule — `status: completed` requires non-empty
`verification_results`; Verifier re-runs independently.
**Detection**: schema validation + independent verification. This is the single most
important failure mode the template exists to prevent.

### D-9. Context exhaustion mid-workflow

**Failure**: orchestrated workflow overflows context.
**Recovery**: shake compaction (`supersedeReads`, `dropUseless`); filesystem
offload for large artifacts; workers return compact results only.
**Detection**: token accounting during evaluation.

### D-10. Partial install leaving inconsistent state

**Failure**: install fails halfway → some components present, others missing.
**Recovery**: manifest-driven rollback restores the pre-install state.
**Detection**: post-install validation; manifest completeness check.

---

## E. Recovery Principles

1. **Fail loudly.** Silent degradation (D-1, D-4, D-6) is worse than an error.
2. **Artifact-based recovery.** Durable artifacts let work resume without replaying
   a transcript.
3. **Evidence over confidence.** Every recovery decision needs fresh evidence.
4. **Bounded retries.** Two attempts for implementation, three for debugging, then
   escalate.
5. **Rollback is always available.** No install without a restore path.

---

## F. Security Review Checklist for the Template Itself

- [ ] No secrets in any tracked file
- [ ] `models.yml`, `agent.db*`, `sessions/` protected in the installer
- [ ] `config.yml` protected from blind overwrite (P0-4)
- [ ] Backup path documented as containing credentials; `.gitignore`-covered
- [ ] No upstream script executed during research or build
- [ ] Untrusted-source handling stated in agent prompts
- [ ] Worker-produced strings treated as untrusted data even after schema validation; actions independently authorized by coordinator (see §A Note CR-12)
- [ ] Destructive actions gated in RULES.md
- [ ] Eval fixtures use synthetic data
- [ ] `_research/upstreams/**` excluded from the distributable template
