# omp-workflow-template Changelog

## [Unreleased] — Workflow v0

### Added
- `template/.omp/` — full OMP-native workflow template (Workflow v0)
  - `AGENTS.md` — coding constitution (Karpathy principles, workflow architecture, agent overview)
  - `RULES.md` — sticky critical invariants
  - `config.yml` — model role aliases
  - Five agents: tech-lead, explorer, implementer, verifier, reviewer
  - Three workflows: quick, standard, orchestrated
  - Three skills: task-triage, systematic-debugging, evidence-before-completion
  - Four schemas: task-packet, agent-result, verification-result, review-result
  - Five policies: context-budget, model-routing, workflow-sizing, quality-gates, escalation
- `registry/` — upstream provenance, licenses, adoption ledger, rejected mechanisms, skill lock
- `docs/research/` — seven research artifacts (mechanism matrix, conflict matrix, authority map, etc.)
- `docs/` — architecture, workflow-v0, installation, customization, rollback, security, token-strategy
- `scripts/` — validate-template.ps1, install-template.ps1, uninstall-template.ps1, clone-upstreams.ps1, benchmark.ps1
- `_research/upstreams/` — 17 shallow-cloned reference repositories (gitignored)
- `.gitignore`, `README.md`

### Research sources (17 repositories)
See `registry/upstreams.yml` for full provenance.

### Not built (deferred)
- Persistent memory / autolearn
- Full OpenSpec / Spec Kit CLI integration
- Evaluation fixtures populated with live results
- Automated skill-lock hash generation
- Serena / Repomix / Context7 default integration
- Automatic live OMP installation
