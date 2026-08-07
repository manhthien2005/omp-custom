# Phase 02 — Core Orchestration

> OPUS PROPOSED SPEC v1 | Make the three workflows actually run end to end.

**Depends on**: phase-01
**Blocks**: phase-03, phase-04

---

## Objective

Get `/quick`, `/standard`, and `/orchestrated` executing correctly with real agent
dispatch, real structured results, explicit isolation, and guaranteed discipline
injection.

---

## Rationale

Phase-01 removed the defects; this phase supplies what was missing. The commands
currently describe a workflow in prose without the mechanics that make it happen:
no `outputSchema` on dispatch, no `isolated: true`, no `autoloadSkills`, no
non-git-repo fallback. Prose alone does not orchestrate.

---

## Tasks

### T-02.1 — Wire autoloadSkills for guaranteed discipline

`alwaysApply` has no subagent wiring; `autoloadSkills` demonstrably injects a skill
body into the subagent via `sendCustomMessage` (`task/executor.ts`). This is the only
deterministic mechanism.

Assign:
- `implementer`: `evidence-before-completion, systematic-debugging`
- `verifier`: `evidence-before-completion`
- `diff-reviewer`: `evidence-before-completion`
- `explorer`: none (read-only; nothing to falsely complete)

**Acceptance**: three agents carry `autoloadSkills`; every name resolves to an
existing skill directory. Dangling names fail validation (they are filtered silently
at runtime — `resolveAutoloadSkills` drops unresolved entries).

### T-02.2 — Make isolation explicit for write-capable workers

`task.isolation.mode` defaults to `none`, and the `isolated` parameter only exists in
the task schema when isolation is enabled (`task/index.ts`). Relying on `auto` is
not a correctness strategy.

Fix:
- document `task.isolation.mode: auto` as a prerequisite for parallel implementation
- pass `isolated: true` explicitly on every Implementer dispatch in `orchestrated.md`
- never isolate Explorer, Verifier, or Reviewer (read-only; isolation wastes setup
  and hides nothing)

**Acceptance**: every parallel Implementer dispatch carries `isolated: true`;
read-only dispatches carry none.

### T-02.3 — Add the non-git-repo fallback

`prepareIsolationContext` **throws** when cwd is not inside a git repository, failing
the task.

Fix: the Tech Lead checks `git rev-parse --show-toplevel` before dispatching
isolated work. On failure: sequential, non-isolated implementation, and say so in
the report.

**Acceptance**: `orchestrated.md` contains the preflight check and the documented
fallback.

### T-02.4 — Complete the dispatch contracts in commands

Each dispatch must specify: agent, task packet content, `outputSchema`,
`schemaMode: "strict"`, `isolated` (write-capable only), and `effort` when
`task.enableEffort` is on.

**Acceptance**: no dispatch relies on an unstated default.

### T-02.5 — Implement Quick as genuinely inline

`quick.md` says the Tech Lead "handles this workflow inline" — correct, and it should
spawn nothing. Make that explicit: zero subagents, main session does inspect →
implement → verify, and the escalation trigger to `/standard` is stated.

**Acceptance**: `/quick` spawns no subagent; escalation criteria are explicit.

### T-02.6 — Define the Verifier rework loop

`verification-result.decision: FAIL` must have a defined next step: return to
Implementer with the failure evidence, bounded to two attempts, then escalate to
re-scoping.

**Acceptance**: `standard.md` and `orchestrated.md` define the loop and its bound.

### T-02.7 — Handle the schema-override signal

`yield` accepts non-conforming data after three failed retries and sets
`schemaOverridden`. The Tech Lead must treat such a result as **unvalidated** rather
than trusting its fields.

**Acceptance**: commands instruct the Tech Lead to re-verify independently when the
override flag is present.

### T-02.8 — Bound concurrency deliberately

Set `task.maxConcurrency` per `08-isolation-and-concurrency.md` and state the
provider rate-limit interaction. Do not exceed the number of genuinely independent
work units.

**Acceptance**: concurrency is a stated number with a rationale, not a default.

---

## Deliverables

- Agent files with `autoloadSkills`
- Commands with complete dispatch contracts (schema, isolation, effort)
- Non-git-repo fallback path
- Defined rework loop and override handling
- `/quick` implemented as truly inline

---

## Verification

Execute each workflow against a real task in a scratch repository:

1. `/quick` on a one-line fix — expect zero subagents, verification evidence present.
2. `/standard` on a two-file change — expect Explorer → Implementer → Verifier, each
   returning a schema-valid result.
3. `/orchestrated` on an independent three-module change — expect parallel isolated
   Implementers and applied changes.
4. `/orchestrated` in a non-git directory — expect the documented fallback, not a throw.
5. Force a verification failure — expect the rework loop, not a false `completed`.

---

## Exit Criteria

- [ ] All three workflows run end to end without silent failure
- [ ] Every dispatch returns a schema-valid result
- [ ] Implementers isolated in parallel; read-only workers not
- [ ] Non-git-repo fallback works
- [ ] Discipline skills injected via `autoloadSkills`
- [ ] Rework loop bounded and defined
- [ ] `schemaOverridden` handled as unvalidated
- [ ] Concurrency set deliberately

---

## Risks

| Risk | Mitigation |
|---|---|
| `autoloadSkills` adds fixed cost per subagent | Only for agents that can falsely claim completion |
| Isolation setup latency | Only for parallel writes, where the alternative is corruption |
| Parallel isolated patches conflict on apply | Partition scope per Implementer; sequential fallback |
| Strict schema mode causes retry loops | Bounded at 3 by `yield`; override surfaces to parent |
