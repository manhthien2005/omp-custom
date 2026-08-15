# Standard Workflow

Standard is one integrated implementation lane owned by the main-session Tech Lead. A plain
request may be classified Standard; `/standard` is a compatibility/advanced hint that must be
validated before mutation.

## Contract

Accept objective, scope/authority, mandatory criteria, verification/review obligations, risk, and
one integrated candidate lineage. Standard may be large or high-risk; Orchestrated is selected
only when at least two independently verifiable work units and an integration contract exist.

After the contract is accepted, create the task through `state/agent-tasks.ps1` as described by
`state/PROTOCOL.md` before mutation. At lifecycle boundaries call that same core; never edit
authority JSON directly. If the core or authority root is unavailable, mutating work fails closed,
while read-only diagnosis may continue with the limitation disclosed. The same `create-task`
request must include exact `workflow_class: standard` and the complete initial `locked_decisions`
array; an empty array is valid, but no decision is inferred from prompt text. A legacy active task
uses `set-continuity-contract` with `workflow_class: standard`, complete `locked_decisions`,
non-empty authority/reason, and the exact current revision/hash/lease compare-and-swap.

## Flow

1. Triage and reconcile the accepted task contract.
2. Gather only the evidence needed for a mini-spec and plan.
3. Implement inline or delegate one bounded work unit when the spawn-benefit gate passes.
4. Integrate, freeze the candidate, and run fresh Tech Lead verification.
5. Apply the review risk gate, resolve blocking findings through rework, and report.

## Benefit-gated agents

- **Cheap Scout (optional):** one bounded read-only retrieval/mapping question. Validate its cited
  evidence before use. Missing Scout availability returns retrieval to the Tech Lead.
- **Worker (optional):** one explicitly owned implementation scope with acceptance criteria and
  verification commands. Omit per-spawn `effort` for normal `high`; use `effort: hi` only when the
  Tech Lead classifies the work difficult and expects effective `xhigh`.
- **General Reviewer (risk-gated):** exact `xhigh`, with the dynamic concern profile already
  selected. Security, authentication, durable data, database migration, concurrency, public API,
  and destructive change concerns require review.

Retrieval routing has the same truth authority in every workflow; only workflow depth differs.
The Tech Lead independently selects Lead/native, Lead/CodeGraph, Scout/native then Lead, or
Scout/CodeGraph then Lead according to source fitness. CodeGraph is optional/default-off. An
absent/unhealthy graph takes a named native fallback; Scout unavailability is
`ENVIRONMENT_BLOCKED`, after which the Tech Lead continues the required retrieval.

Default to no subagent spawn and one writer. While Worker writes the retained workspace, the Tech
Lead does not compete with it. Accept only valid, non-overridden structured output and verify the
returned Worker/Reviewer identity and effort. A quality failure opens rework; it does not silently
change model.

## Verification and review

The Tech Lead owns fresh verification after all accepted writes are integrated. A permanent
Verifier is not part of the topology. Reviewer preference is a suitable different family, another
suitable strong model, then a same-model separate session with disclosure. Opus is a preference,
not a gate.

## Escalation and lifecycle

If exploration proves the structural Orchestrated boundary, preserve valid work, create work-unit
contracts and an integration contract, then change internal classification. New objective/scope/
mandatory criteria/locked obligations open a linked task. Mutation after verification creates a
new candidate and invalidates old evidence.

## Context continuity

Run argument-free `/safe-compact` only after exactly one active task is owned by the current
persisted OMP session and the continuity gate is armed. Standard requires complete applicable
secondary checkpoint/work-unit/next-action/blocker/risk/candidate/evidence state; named Quick
degradation is invalid here. The command writes verified local recovery bytes, runs one native
soft transaction, and injects one kernel on the next normal prompt without hidden continuation.
If it is unavailable/refused or one attempt leaves pressure unresolved, checkpoint and use the
explicit Topic 04 `begin-handoff`/`accept-handoff` path. Never fall back to built-in `/compact`,
`/shake`, snapcompact, automatic retry, or automatic handoff.
