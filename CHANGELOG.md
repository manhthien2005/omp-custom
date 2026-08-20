# omp-workflow-template Changelog

## [Unreleased] — Workflow v0

### Added
- Topic 07 adds explicit safe context-full continuity to the managed launcher. Automatic semantic,
  idle, mid-turn, remote, and auto-continue paths are disabled; argument-free `/safe-compact`
  persists and re-verifies local recovery bytes, authorizes one native soft transaction, and
  injects one Topic 04-derived kernel on the next normal prompt with no hidden continuation or
  retry. Pressure stops before provider dispatch; bounded children fail/partial rather than
  compacting. Source attachments and the installed 17.2.12 zero-network canary pass, while missing
  local 17.2.10 remains `OPEN-T07-RUNTIME-02`, so status is `IMPLEMENTED_NOT_PROMOTED`. No Git or
  provider mutation is part of this work.
- Topic 06 adds a portable closed agent-boundary core and a trusted same-name OMP `task` wrapper,
  launched through `.omp/bin/omp-managed.ps1`. It projects Topic 04 work units, validates exact
  role/model/effort and settled structured output, excludes Worker CLAIM from Reviewer input, and
  records provisional receipts/outcomes without taking parent acceptance authority. Managed v1
  supports blocking single/batch calls, rejects async/nested and incompatible plan-mode work,
  pins `task.softRequestBudget: 200`, installs/rolls back transactionally, and falls back to inline
  Tech Lead work without fabricating a receipt. Bare OMP/Vibe/`eval` remains unmanaged;
  `OPEN-T06-RUNTIME-01` is nonblocking. All changes and operational state remain local/no-Git.
- Topic 05 adds an optional, default-off CodeGraph v1.5.0 component with exact release-artifact
  pins, a capability-narrowed retrieval tool, safe per-worktree lazy indexes, explicit provisioning
  and recoverable cleanup, a contamination-controlled four-arm benchmark, and hash-locked
  current-product evidence. The real-binary smoke and deterministic campaign passed without a
  model call; the paid model campaign remains `NOT_RUN` and no route is promoted.
- Topic 04 adds a deterministic local task-state component under `template/.omp/state`: immutable
  revision/CAS authority, exact candidate and evidence binding, checked handoff/takeover, compact
  offload promotion, recoverable archive/restore, exact purge, schemas, protocol, tests, and a
  focused mutation validator. Operational state stays outside Git at `agent-tasks` (plural).
- `template/.omp/` — full OMP-native workflow template (Workflow v0)
  - `AGENTS.md` — coding constitution (Karpathy principles, workflow architecture, agent overview)
  - `RULES.md` — sticky critical invariants
  - `config.yml` — model role aliases
  - Initial Workflow v0 roster: tech-lead, explorer, implementer, verifier, reviewer
    (historical; superseded by Topic 03)
  - Three workflows: quick, standard, orchestrated
  - Three skills: task-triage, systematic-debugging, evidence-before-completion
  - Four schemas: task-packet, agent-result, verification-result, review-result
  - T-00.3 retired five inert policy YAML sources and re-homed their contracts into commands,
    agents, main-session instructions, advisory validation, and human references under `docs/policies/`
- `registry/` — upstream provenance, licenses, adoption ledger, rejected mechanisms, skill lock
- `docs/research/` — seven research artifacts (mechanism matrix, conflict matrix, authority map, etc.)
- `docs/` — architecture, workflow-v0, installation, customization, rollback, security, token-strategy
- `scripts/` — validate-template.ps1, install-template.ps1, uninstall-template.ps1, clone-upstreams.ps1, benchmark.ps1
- `_research/upstreams/` — 17 shallow-cloned reference repositories (gitignored)
- `.gitignore`, `README.md`

### Changed
- Progressive retrieval now selects actor and capability independently. Native retrieval remains
  the default; CodeGraph output is a hypothesis, absence requires native corroboration, Cheap Scout
  remains read-only/fail-soft, and Reviewer retrieval remains independent at exact `xhigh`.
- Rollback retains and reports exact known CodeGraph bundle/index paths. A strict-mode regression
  now guarantees a single-file backup restores correctly instead of failing on scalar enumeration.
- The installer now includes the manifest-verified state component by default and requires
  PowerShell 7.4+ for it. Install, rollback, and cleanup preserve local operational authority.
  Claude and Codex/OMP use one explicit shared core; automatic lifecycle attachment remains an
  honest Topic 08 installed-runtime gate rather than an implicit requirement.
- Topic 03 moved Tech Lead ownership into the main session and selected exactly three discoverable
  agents: read-only fail-soft `cheap-scout`, benefit-gated `worker`, and risk-gated `reviewer`.
  Normal work stays inline. Worker uses `high` or Tech-Lead-selected `xhigh`; Reviewer remains
  `xhigh`; Opus is preferred rather than required; same-model review is independently sessioned
  and disclosed. Parallel writers remain conditional and fall back to sequential execution.
- Topic 03 routes Cheap Scout through DeepSeek Flash at maximum reasoning, then DeepSeek Pro at
  maximum reasoning, then main-session Tech Lead retrieval. Default, Worker, and Reviewer model
  fallback chains remain empty. Provider smoke is honestly recorded as environment-blocked when
  DeepSeek credentials are absent.
- The installer now maps `workflows` to OMP `commands`, backs up before mutation, retires only the
  four closed stale agent filenames, preserves custom/protected files, and requires explicit
  user-level opt-in before enabling global per-spawn effort.
- Topic 02 made plain natural-language requests the normal workflow entry, kept `/quick` as
  the user's explicit light-task choice, and assigned Standard-versus-Orchestrated
  classification to the main-session Tech Lead. It defined task/candidate/session,
  compaction/handoff, non-destructive reclassification, structural Orchestrated work units,
  and fail-soft Cheap Scout semantics. This change closes architecture/specification and phase
  planning only: Phase 02 owns runtime prompt migration and must create new product evidence
  without rewriting the hash-locked Phase 00 snapshot.
- Topic 01 replaced the ambiguous raw-token objective with a quality-first contract: validated
  accepted outcomes, full failed/rework task-cycle accounting, unweighted core/Scout/raw token
  ledgers, latency telemetry, frozen stable-template and plain-OMP baselines, and separate
  efficiency-win/quality-win promotion paths with sequentially valid adaptive evidence. This
  is specification and phase planning only; the Phase 06 benchmark implementation remains
  deferred.

### Fixed
- Managed `task` dispatch is accepted by strict-function validation again. The tool's root parameter
  schema was a `Type.Union`, which serializes to a bare `{ anyOf: [...] }` with no root `type`;
  OpenAI-responses strict validation rejects that outright and strict adaptation never repairs it
  because `anyOf` already satisfies the combinator escape. The root is now one closed object with
  every property optional, so both documented dispatch shapes stay satisfiable and
  `core.validateManagedRequest` remains the sole shape authority with exact reason codes.
- The Topic 05 token ledger no longer double-counts cached context. The accounting basis is
  `input + output + cacheWrite`, excluding `cacheRead`: each cached byte is written once, while
  cumulative cache reads recharge the same context every turn. A provider omitting any of the four
  counts leaves the ledger `not_measured` rather than estimated.
- `T07-EVIDENCE` now asserts the per-case verdicts (at least eight cases, none with a status other
  than `PASS`) instead of only the status, blocker, and counter fields, so a partially-failing
  capture can no longer satisfy it.
- The installed CodeGraph component manifest re-pins the `.omp/state/manifest.json` digest that
  install-time verification compares against.
- Five test defects that no validator surfaced — the Pester-hosted suites exit `0` even when
  individual assertions fail, and a mutation that stops mutating still reports success: an
  incomplete `phase00-t003` fixture whose one missing `current_files`
  path cascaded into eleven destination-row failures; a `phase00-wave-a` integration test asserting
  exit `0` from a shell where the deliberate pwsh-7.4 version gates must fail closed, and whose
  inherited `PSModulePath` shadowed `Get-FileHash` out of Windows PowerShell 5.1; a `phase00-e1`
  suite that hosted only its own helper, hiding the supersession validator that explains the six
  Topic 03-superseded protected pins; a version-coupled `topic06` mutation that silently stopped
  mutating after any `component_version` bump; and a `topic02` Quick-command fixture that
  contradicted the Topic 07 continuity contract.
- OMP 17.2.10 and 17.2.12 were re-compared across all thirteen watched source paths and the complete
  settings key set. Eight paths are byte-identical, every pinned default matches, and the only
  key-set delta is three unused `exa.*` removals, so the two-version support claim stands and the
  pin is unchanged. Details in
  `docs/audit/claude-preflight-2026-08-14/reports/claude-defect-repair-and-runtime-parity-report.md`.

### Research sources (17 repositories)
See `registry/upstreams.yml` for full provenance.

### Not built (deferred)
- Persistent memory / autolearn
- Full OpenSpec / Spec Kit CLI integration
- Evaluation fixtures populated with live results
- Automated skill-lock hash generation
- Serena / Repomix / Context7 default integration
- Automatic live OMP installation
