# Security Guide

<!-- round09-12-projection:release-readiness -->
## Round 09–12 safety boundary

The evaluator rejects secret-shaped evidence without echo, stale candidate/review bindings,
partial results presented as complete, destructive work without authority, and duplicate
side-effect retries. Critical and important review findings block acceptance; minor findings do
not silently escalate or disappear.

Deterministic evaluation is the default and starts no provider/model process. Campaign execution
requires all of: `-Mode Campaign`, `-AllowProviderCalls`, a positive `-EvidenceBudget`, a concrete
OMP path, a bounded output directory, and a separate user authorization. Local campaign results
stay under ignored `evals/results/`; governed fixtures and bounded hash-only evidence remain in
Git. Missing runtime or authority yields `ENVIRONMENT_BLOCKED` or `NOT_RUN`, never a false pass.

The scratch package proof used disposable Git projects only. It did not mutate a live OMP
installation, user model catalog, credential store, or provider configuration.

<!-- topic05-doc:security -->
The optional CodeGraph adapter accepts only a bounded question and file count. Models cannot choose
process, path, environment, or index authority. The pinned bundle runs through absolute recorded
paths without a shell, MCP, hooks, daemon, interactive install, or auto-update. Physical
worktree-local indexes and Topic 04 candidate/source post-checks prevent cross-task evidence reuse.
See [`retrieval.md`](retrieval.md).

See `docs/research/security-analysis.md` for the full threat model and analysis.

## Summary of security properties

### What the template does NOT do

- The installer and static validators do not call a model provider; runtime model calls go only
  through the user-configured OmniRoute gateway
- Does not write to any OMP live directory without explicit user confirmation
- Does not execute upstream scripts from cloned repositories
- Does not store API keys, tokens, or credentials anywhere
- Does not enable persistent memory or autolearn
- Does not install MCP servers

### What the template does

- Defines agent prompts in plain `.md` files (reviewable before installation)
- Defines commands and agents as reviewable Markdown, with schemas as YAML documentation
- Keeps human policy references outside the installed surface; executable constraints are in their consumers
- Installs only to directories the user explicitly specifies
- Creates a timestamped backup before every installation
- Retires only the four explicitly named stale agent files; custom agents and protected
  model/database/credential/session files survive
- Installs a manifest-verified state core while keeping operational `agent-tasks` data outside
  Git and outside installer/rollback ownership

DeepSeek credentials and the external `~/.omp/agent/models.yml` catalog are user-owned and stay
outside the repository. Cheap Scout is read-only and fail-soft. If its Flash and Pro routes are
unavailable, retrieval returns to the main-session Tech Lead; it does not silently accept a
different model or weaken verification.

Security, authentication, durable data, database migration, concurrency, public API, and
destructive-change concerns select an `xhigh` independent Reviewer. Opus is preferred when
available, not required. Same-model review runs in a separate session and is disclosed.

## Durable-state boundary

State records use canonical paths, closed schemas, immutable revisions, hashes, compare-and-swap
checks, ordered locks, and one non-expiring writer lease per task. There is no heartbeat timeout
or automatic ownership takeover. Normal handoff is two-phase; crash recovery requires explicit
user authority plus workspace and process-instance reconciliation.

The schema rejects transcripts, hidden reasoning, API keys, tokens, credentials, raw environment
contents, and terminal history. Raw `.task/` files and runtime artifacts are transient and never
acceptance authority. Cleanup previews first, archive moves exact task state to recoverable trash,
and permanent purge is a separate exact-target confirmation. The state core never deletes,
merges, or prunes Git worktrees.

This protects consistency and detects drift; it is not an OS security boundary. A local process
with filesystem access can still alter files. State is same-machine, repository-metadata loss can
remove Git-backed authority, direct edits are detected at checked boundaries, and the Tech Lead
must still identify complete semantic acceptance inputs. Automatic lifecycle integration remains
an unclaimed Topic 08 capability until its installed-runtime probe passes.

The Topic 06 wrapper is an evidence boundary, not an operating-system sandbox. It rejects unknown
packet fields, transcripts, hidden reasoning, secrets, unsafe authority paths, stale candidate
bindings, identity substitution, malformed results, async acknowledgements, nested dispatch, and
forced partials. Reviewer receives ARTIFACT + CONTRACT and not Worker CLAIM. If the wrapper is
unavailable, inline work is allowed but no managed receipt or independent-review claim is created.
Bare OMP/Vibe/`eval` output remains unmanaged; `OPEN-T06-RUNTIME-01` records the nonblocking
upstream universal-hook question.

## Managed continuity boundary

Topic 07 accepts no focus text and trusts only a manifest-matched extension, exact effective
settings, the current persisted OMP session, one Topic 04 task projection, verified branch bytes,
a locally written/re-read recovery artifact, and a short-lived single-use nonce. The native
summary, recovery artifact, and injected kernel are context—not authority—and contain no authority
paths, transcripts, hidden reasoning, terminal history, raw evidence observations, or credentials.

Automatic semantic/context promotion, idle, mid-turn, auto-continue, remote, built-in `/compact`,
direct `shake`, snapcompact, and automatic handoff paths are unsupported in managed continuity.
At pressure, provider dispatch is aborted. A bounded child returns failed/partial without automatic
retry. If artifact persistence, task/revision/lease/branch binding, or kernel injection cannot be
proved, the original branch remains authoritative and managed work stops. Bare OMP remains usable
but cannot claim this guarantee.

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
