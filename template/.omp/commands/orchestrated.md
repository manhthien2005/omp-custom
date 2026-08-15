# Orchestrated Workflow

Orchestrated is selected when the accepted task contains at least two independently verifiable
work units, explicit ownership/dependencies, one integration contract, and cross-boundary
verification. Parallelism, multiple writers, and agent count do not define this workflow.

## Contract construction

For every work unit name its objective, input, output, owned scope, dependencies, completion
condition, verification, and integration consumer. Only the fully integrated frozen task candidate
can be accepted; a completed work unit cannot accept the parent task.

After the contract is accepted, create the task through `state/agent-tasks.ps1` as described by
`state/PROTOCOL.md` before mutation. At lifecycle boundaries call that same core and record work
units; never edit authority JSON directly. If the core or authority root is unavailable, mutating
work fails closed, while read-only diagnosis may continue with the limitation disclosed. The same
`create-task` request must include exact `workflow_class: orchestrated` and the complete initial
`locked_decisions` array; an empty array is valid, but no decision is inferred from the graph or
agent count. A legacy active task uses `set-continuity-contract` with
`workflow_class: orchestrated`, complete `locked_decisions`, non-empty authority/reason, and the
exact current revision/hash/lease compare-and-swap.

## Flow

1. Reconcile the task contract and build the dependency graph.
2. Use bounded Cheap Scout questions only where retrieval delegation has concrete value.
3. Implement units inline or dispatch Worker only when delegation benefits the graph.
4. Integrate accepted artifacts sequentially in dependency/task order.
5. Freeze the integrated candidate and run fresh unit, integration, and cross-boundary verification.
6. Apply the General Reviewer risk gate with dynamic concern profiles.
7. Rework blocking findings as a new candidate; report actual execution/fallback paths.

Retrieval routing has the same truth authority in every workflow; only workflow depth differs.
For each bounded question the Tech Lead independently selects Lead/native, Lead/CodeGraph,
Scout/native then Lead, or Scout/CodeGraph then Lead according to source fitness. CodeGraph is
optional/default-off. An absent/unhealthy graph takes a named native fallback; Scout unavailability
is `ENVIRONMENT_BLOCKED`, after which the Tech Lead continues the required retrieval.

## Worker effort and writer ownership

Normal Worker dispatch uses its frontmatter `high` default and omits `effort`. Difficult,
high-risk, concurrency-sensitive, migration-sensitive, or uncertain-root-cause units use
`effort: hi` only when preflight proves the expected effective `xhigh` identity.

One writer is the default. Multiple Workers may write in parallel only when scopes are disjoint,
isolation/capture is proven, nested repositories are absent from the owned scopes, and the Tech
Lead can integrate artifacts sequentially. If batching, isolation, capture, or ownership cannot be
proven, run Workers sequentially/non-isolated and disclose the fallback; Orchestrated remains
structurally valid. Never race the Tech Lead against a Worker.

## Result gates

Every selected agent has one bounded packet, output consumer, stop condition, and fallback.
Accept only valid, non-overridden structured output. Verify Worker/Reviewer returned model and
effort identity. Cheap Scout evidence is advisory. Tech Lead fresh verification runs only after
full integration; a partially integrated tree cannot reach review or acceptance.

## Review gate

General Reviewer is fixed at `xhigh` and mandatory for security, authentication, durable data,
database migration, concurrency, public API, and destructive change concerns. More than one
Reviewer requires at least two independent high-risk concerns. Prefer cross-family independence,
then another strong model, then same-model separate-session review with disclosure. Opus absence
does not block an approved fallback.

## Failure and lifecycle

Preserve successful independent work when another unit fails. Stop integration on conflicts,
retain/report remaining artifacts, and open rework or request authority as required. Any mutation
after evidence creates the next candidate. Material contract change opens a linked task.

Run argument-free `/safe-compact` only after exactly one active task is owned by the current
persisted OMP session and the continuity gate is armed. Orchestrated requires every applicable
secondary continuity field; degradation is not allowed. The command writes verified local
recovery bytes, runs one native soft transaction, and injects one kernel on the next normal prompt
without hidden continuation. If unavailable/refused or one attempt leaves pressure unresolved,
checkpoint the integration graph and use explicit Topic 04 `begin-handoff`/`accept-handoff`; the
handoff creates a reconciled successor session. Never use built-in `/compact`, `/shake`,
snapcompact, automatic retry, or automatic handoff.
