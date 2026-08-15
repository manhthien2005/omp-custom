# Quality Gate Reference

> OMP runtime: not loaded. This file expands the gate names carried by task packets; it does not
> select gates and is not discovered as an installed runtime component.

> Later-topic supersession: Topic 02 KD-026 and spec/10 replace the Phase 00 fixed-Reviewer
> projection. The Phase 00 destination hash remains historical evidence, not a current-byte pin.

Retired source: quality-gates.yml.

The main session selects gates; the task packet carries names; the selected gate-applier applies only those names.
The selected gate-applier may report a missing gate as a scoped finding but
does not expand its own review contract.

## Risk matrix

| Risk | Gates |
|---|---|
| LOW | none |
| MEDIUM | security |
| HIGH | api-compatibility, security, performance, release-readiness, rollback-readiness |
| CRITICAL | api-compatibility, security, performance, release-readiness, rollback-readiness, adr-documentation |

This matrix does not decide whether independent review is selected. Review remains task-contract
and risk-gated; Orchestrated classification alone does not mandate a Reviewer or worker dispatch.

Topic 03 selects the General Reviewer for security, authentication, durable data, database
migration, concurrency, public API, and destructive-change concerns. Reviewer effort is always
`xhigh`. Opus is preferred when suitable and available but is not required; another suitable
strong model or a same-model independent session with disclosure is valid. The Tech Lead still
runs fresh verification after integration.

## Gate definitions

### api-compatibility

Use when public signatures, endpoints, required parameters, serialization, wire contracts, or
database schemas change. Check every existing caller, migration/compatibility strategy,
documentation, and versioning consequence.

### security

Use when input validation, authentication/authorization, cryptography, user-controlled paths or
process execution, or secret handling changes. Check traversal, injection, permission boundaries,
and that credentials are referenced rather than embedded.

### performance

Use when hot paths, queries, allocation, or network-call frequency changes. Check N+1 behavior,
unnecessary repeated work, memory pressure, and cache invalidation.

### adr-documentation

Use when a design pattern, dependency, or architecture boundary changes. Check that the decision,
alternatives, and rationale are recorded in an ADR or equivalent artifact.

### release-readiness

Use for production features and infrastructure/configuration changes. Check rollout controls,
monitoring/alerting/observability, and user/operator documentation.

### rollback-readiness

Use for migrations, infrastructure, and external-service changes. Check the rollback procedure,
schema reversibility, and whether the feature can be disabled safely.

## Override rule

The main session may add gates or omit a default only by listing the resolved names in the task
packet. Omitting a default HIGH or CRITICAL gate requires an explicit reason. Gate selection must
remain bounded by the task's actual risk; it is not permission for speculative review scope.
