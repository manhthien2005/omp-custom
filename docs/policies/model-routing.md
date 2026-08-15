# Model Routing Reference

> OMP runtime: not loaded. This human reference explains the selected routing contract;
> `config.yml`, agent frontmatter, effective settings, and runtime identity enforce it.

> Later-topic supersession: Topic 02 KD-026 and spec/09 replace the Phase 00 fixed-role routing
> projection. The Phase 00 destination hash remains historical evidence, not a current-byte pin.

Retired source: model-routing.yml. Topic 03-selected aliases are the only required routing set.
The Phase 00 sentence “silent model fallback is disabled” describes the former global policy;
Topic 03 replaces it with one explicit, observable Cheap-Scout-only chain.

## Selected role contract

| Consumer | Selected OMP role/model | Resolution owner |
|---|---|---|
| Main-session Tech Lead | User-selected model; no installer-owned alias required | User/session configuration |
| Each Topic 03-selected spawned worker or command adapter | Its referenced alias and effective per-spawn effort | Selected contract + project configuration |
| `cheap-scout` primary | `omniroute/ds/deepseek-v4-flash:xhigh` | `modelRoles.cheap-scout` |
| `cheap-scout` fallback | `omniroute/ds/deepseek-v4-pro:xhigh` and nothing else | `retry.fallbackChains.cheap-scout` |
| `worker` | `omniroute/codex/gpt-5.6-sol:high`; Tech-Lead-selected `xhigh` for hard work | Agent alias + per-spawn effort |
| `reviewer` | `omniroute/codex/gpt-5.6-sol:xhigh`; fixed `xhigh` | Agent alias + fixed agent effort |

The `default`, `worker`, and `reviewer` fallback chains stay empty. Opus is a preferred Reviewer
family when suitable and available, not an installation or completion gate. Another suitable
strong model—or the same model in a separate session with disclosure—is a valid review fallback.

## Cheap Scout behavior

Cheap Scout is optional, read-only, and fail-soft. The Tech Lead selects it only when bounded
retrieval creates a concrete benefit. Flash at maximum reasoning is primary; Pro at maximum
reasoning is its only model fallback. If both fail or are unavailable, the Tech Lead performs the
retrieval needed by the active task. Scout failure never waives fresh verification, selected
review, or acceptance criteria.

The chain is explicit rather than silent: preflight resolves the selected alias, fallback use is
reported, and acceptance checks the returned model/effort identity against the reconciled current
candidate. Any credential-driven parent-model substitution or unrelated fallback is rejected.

## Gateway and catalog boundary

- OmniRoute is the only model gateway in this deployment.
- Gateway IDs are environment properties: `ds/deepseek-v4-flash` and
  `ds/deepseek-v4-pro`.
- OMP selectors add the gateway prefix and effort suffix:
  `omniroute/ds/deepseek-v4-flash:xhigh` and
  `omniroute/ds/deepseek-v4-pro:xhigh`.
- The external `~/.omp/agent/models.yml` catalog and OmniRoute provider credentials are
  user-owned. Commands and `AGENTS.md` do not embed concrete model IDs, and repository files never
  contain a provider key.
- Current smoke evidence is `ENVIRONMENT_BLOCKED` when OmniRoute has no active DeepSeek
  credential. That is an honest environment limitation, not a provider PASS.

## Effort and acceptance

Thinking effort is separate from model selection. Project configuration enables per-spawn effort
and caps it at `xhigh`. Worker omits an override for normal `high` work and uses `effort: hi` only
when the Tech Lead classifies the bounded work unit as hard. Reviewer never drops below `xhigh`.

Acceptance reconciles `task.agentModelOverrides`, retry settings, credential behavior,
`task.enableEffort`, and `task.maxEffort`; it then compares returned model and effort identity to
the expected candidate. A forced partial result, overridden/invalid structured output, or identity
mismatch cannot pass as completion.

## Closed E2 boundary

E2 is closed: missing or unknown aliases and unavailable models hard-fail with no fallback unless
a later selected contract declares a closed chain. Project configuration values win over global
values. Selected model identity rejects resolvedModelIsFallback true and any returned role/model
mismatch. Topic 03's Scout-only Flash-to-Pro chain is that later explicit product decision and
does not reopen global or Worker/Reviewer fallback.
