# 04 — Workflow Sizing

> OPUS PROPOSED SPEC v1 | When each of the three workflows applies, and how the choice is made.

---

## A. What Exists Today

Three command files — `quick.md`, `standard.md`, `orchestrated.md` — each open
with a "When to use / When NOT to use" section. The signals in them are good.
They are the most immediately reusable artifacts in the current template.

Two problems:

1. `tech-lead.md` instructs the model to select a size "based on
   `policy:workflow-sizing`" — an unresolvable reference (F-09). The signals in
   `workflow-sizing.yml` are never read.
2. Nothing selects a workflow. The user types `/quick` or `/standard`
   themselves. The triage step inside each command can only confirm or
   contradict a choice already made.

The second is not necessarily a defect. It may be the better design.

---

## B. Who Chooses

Two options.

**Option A — user chooses.** The user types `/quick`. The command's first step
checks the choice against its own criteria and escalates if wrong.

**Option B — router chooses.** A single `/work` command triages, then routes
internally to quick/standard/orchestrated logic.

Opus recommends **Option A with mandatory escalation**, for three reasons:

- The user usually knows the scope better than a triage pass does. "Fix the
  typo in line 12" does not need a classification step.
- Option B adds a triage turn to every task, including the trivial ones. That
  is a real token cost paid on every interaction to save the user one word.
- Escalation is cheap and safe; de-escalation is not. If `/quick` discovers
  mid-flight that the change spans four modules, it can stop and say so. The
  reverse — `/orchestrated` discovering the task was trivial — has already
  spent the tokens.

Option B remains available later as a thin `/work` wrapper that picks a size
and then behaves exactly as that size. It is not needed for v0.

---

## C. Sizing Criteria

Consolidated from the three command files, with the contradictions resolved.

| Signal | Quick | Standard | Orchestrated |
|---|---|---|---|
| Files touched | 1 | 2–several | Across modules |
| Root cause known | Yes, from the task text | No — needs investigation | No, and may be several |
| Behaviour change | No | Yes | Yes |
| Public API / wire format | Unchanged | May change | Changes |
| Independent workstreams | None | None | ≥2, genuinely parallel |
| Security / migration risk | None | Low | Present |
| Worker agents | 0 | 2–4, sequential | 4+, some parallel |

The decisive question for each boundary:

- **Quick → Standard**: do I know which file to change before I look? If no,
  Standard.
- **Standard → Orchestrated**: are there two pieces of work that could proceed
  simultaneously without either waiting on the other? If no, Standard —
  regardless of how large the task feels. Size alone does not justify
  Orchestrated; independence does.

That second rule is the one the current `orchestrated.md` gets right and
`workflow-sizing.yml` blurs. A large sequential task is Standard with more
steps, not Orchestrated. Spawning four agents to do four dependent things in
sequence is strictly worse than one agent doing them, because each handoff
loses context and costs a task spawn.

---

## D. Escalation

Escalation is the only mid-flight size change permitted.

| From | To | Trigger | Action |
|---|---|---|---|
| Quick | Standard | Change spans >1 file, or root cause not found after inspection | Stop, report why, restart as Standard |
| Quick | Standard | Verification fails twice for different reasons | Stop; the task was misclassified |
| Standard | Orchestrated | Exploration reveals ≥2 independent workstreams | Stop, present the split, restart as Orchestrated |
| Any | Halt | Ambiguity that changes the acceptance criteria | Ask the user (`RULES.md` invariant 8) |

Escalation **restarts**, it does not continue. A Quick run that escalates
discards its partial work and begins the Standard flow with what it learned as
input. Continuing in place is how the Tech Lead ends up holding a transcript it
was supposed to compact.

De-escalation is not permitted. An Orchestrated run that discovers the task was
small finishes as Orchestrated. The waste is already sunk; abandoning
mid-flight to save the remaining tokens risks leaving isolated worktrees
unmerged.

---

## E. Flows

Each flow below is the corrected version of the corresponding command file.
Changes from current: no `policy:` references, **per-workflow** explicit
isolation on Implementer dispatch (`false` in Standard, `true` in Orchestrated —
CR-02), explicit `outputSchema` reliance, and named escalation points.

**CR-02 — isolation is not uniform across sizes.** An earlier revision of this
file dispatched the Standard Implementer with `isolated: true`. That contradicted
the canonical isolation policy in `08-isolation-and-concurrency.md §B`, which the
capture-first architecture (CR-09/27/30) is built on:

```yaml
Standard:
  implementer:
    isolated: false          # single writer; no concurrency to defend against
Orchestrated:
  parallel_implementer:
    isolated: true
    apply: false             # capture-first; Tech Lead integrates serially
```

Standard has exactly one Implementer and no concurrent writer, so isolation buys
nothing and costs a git-repo requirement (`prepareIsolationContext` throws
without one), worktree materialization, and an integration step that can fail.
Isolation in Standard would also drag Standard onto the capture-first path — the
`task.isolation.apply: false` preflight, artifact retention, and integration
ordering — none of which Standard needs. The contradiction was load-bearing
because this file defines flow steps and verification criteria that an
implementation agent follows literally.

### Quick

```
1. Confirm size        — 1 file? root cause known? if no → escalate
2. State criteria      — 1–3 verifiable, plus the exact verify command
3. Inspect             — targeted read; grep/glob before full file
4. Implement           — inline, in the main session; minimal diff
5. Verify              — run the command, read the output
6. Report              — files changed, evidence, unresolved
```

No workers. The session does the work. This is the point of Quick: for a
one-file change, a task spawn costs more than it saves.

### Standard

```
1. Triage              — confirm size; resolve ambiguity or ask
2. Explore             — task → explorer (no isolation)
3. Mini-spec           — inline; 2–5 Given/When/Then criteria; out-of-scope
4. Plan                — ≤7 steps with checkpoints
5. Implement           — task → implementer (isolated: false — CR-02)
6. Verify              — task → verifier (no isolation)
7. Review              — task → reviewer (no isolation), risk-gated
8. Summarize           — criteria results, evidence, unresolved
```

Step 5 is **not** isolated. One Implementer writing to the checkout it was
dispatched against is the whole point of Standard: there is no second writer to
corrupt, and the edits are already in the working tree when the Verifier runs.
Standard therefore never enters the capture-first path and never needs the
`task.isolation.apply` preflight (`08-isolation-and-concurrency.md §E-9`).

**Standard still depends on stage barriers (CR-39).** Steps 2→3, 5→6, 6→7, and 7→8 each
consume the previous step's completed result, so every worker Standard dispatches must carry
`blocking: true` — without it the Verifier would run against an unfinished implementation and
the summary would be written before any result arrived. Standard needs no batch and no
canary, but it needs the barrier exactly as much as Orchestrated does. See §08 §C-1.

Review is gated on: public API change, security-relevant code, or a diff the
Verifier passed but the session finds hard to reason about. Not gated on size.

### Orchestrated

```
0. Preflight           — nested-repo scan → task.batch → settings diagnostics → capture
                          canary; any failure disables parallel (§D-1.2, §C-1.4, §E-9, §E-9.2)
1. Triage + decompose  — identify genuinely independent workstreams
2. Explore in parallel — task batch → N explorers, distinct scopes
3. Architecture review — synthesize; write the spec; assign quality gates
4. Task graph          — dependencies explicit; only independent nodes parallel
5. Implement in parallel — task batch → implementers (isolated: true, apply: false)
                          → capture only; nothing lands in the parent tree
6. Integrate serially  — main Tech Lead applies retained artifacts in
                          original task-index order (§E-10); stop on first conflict
7. Verify              — task → verifier, once, against the integrated tree
8. Review              — task → reviewer, independent
9. Report              — cross-workstream validation, evidence report
```

Concurrency is capped at 4 by the frozen baseline (`task.maxConcurrency`).
Step 5's parallel implementers are the reason `isolated: true` matters most
here: concurrent writers to one checkout corrupt each other.

**Steps 5→6 are the capture-first split (CR-29).** Workers do not apply their own
changes; `apply: false` retains a patch or branch artifact per worker and the
main-session Tech Lead integrates them one at a time. Integration order is the
**original task-list index**, never worker completion order — see
`08-isolation-and-concurrency.md §E-10`. On the first conflict, integration stops,
the remaining artifacts are preserved unapplied, and the partial parent state is
reported; the Verifier does **not** run on a partially integrated tree.

Step 0 can veto parallelism entirely. Four conditions force the sequential
non-isolated fallback, checked in this order — cheapest and most decisive first:

| # | Check | Failure means | Ref |
|---|---|---|---|
| 1 | nested git repo / submodule present | structural: a lost nested change is undetectable | §D-1.2 |
| 2 | effective `task.batch != true` | the wire has no `tasks[]`, so no stable index | §C-1.4 |
| 3 | `omp config get` isolation diagnostics | produces the actionable message; **not** the gate | §E-9 |
| 4 | same-session capture canary | authoritative: does this session actually capture? | §E-9.2 |

Checks 3 and 4 are both required and are not redundant — 3 explains *why* to the user
(wrong file, wrong cwd, or an overlay), 4 decides *whether*. A subprocess settings read
cannot see the parent's `--config` overlay or an in-session override, both of which outrank
project config and both of which govern the real dispatch (CR-38, §E-9.1).

**Every stage arrow above is a barrier, and barriers are not free (CR-39).** OMP defaults
`async.enabled` to `true`, so a worker agent that does not declare `blocking: true` becomes a
background job: the `task` call returns immediately and the next stage begins with no result.
All four workers therefore carry `blocking: true` in frontmatter (§03, §08 §C-1.3). This does
not serialize step 5 — an all-blocking batch still fans out concurrently under the
concurrency cap and returns results in task-index order, which is what step 6 depends on.

Step 7 runs *after* integration, once, against the integrated result. Verifying
each isolated worktree separately proves each piece works alone and nothing about
the whole.

---

## F. Anti-Patterns

| Pattern | Why it is wrong |
|---|---|
| Orchestrated for a large sequential task | Handoff cost with no parallelism gain |
| Multiple explorers over the same files | Duplicated reads, duplicated tokens, no new evidence |
| Reviewer on every Quick task | Cost with no risk to justify it |
| Quick with a worker spawn | If it needs a worker it is not Quick |
| Skipping the Verifier because the Implementer said it passed | `RULES.md` invariant 1; the Verifier exists for this |
| Escalating by continuing in place | Leaks the accumulated transcript the size change was meant to shed |

---

## G. Verification

- Each command file's "when to use" matches the table in section C.
- No command file contains a `policy:` reference.
- Standard dispatches its Implementer with `isolated: false`; Orchestrated
  dispatches its parallel Implementers with `isolated: true` and does **not**
  rely on worker-side apply (CR-02).
- Orchestrated integration happens in the main session, in original task-index
  order, after all workers settle — not inside the workers (CR-29).
- Orchestrated preflight runs before fan-out and can downgrade to the sequential
  non-isolated flow: nested-repo scan (CR-32), `task.batch` check (CR-39), settings
  diagnostics (CR-31), same-session capture canary (CR-38).
- **Every worker agent the flows dispatch carries `blocking: true` (CR-39).** A flow diagram
  whose arrows are not backed by barriers is not a flow. Verify per-agent, not per-workflow —
  the frontmatter is the mechanism, in both Standard and Orchestrated.
- LSP-dependent roles (Explorer, Implementer, Reviewer) either have all three LSP conditions
  met or the run discloses reduced-capability mode naming which condition failed (CR-40,
  `07-retrieval-and-code-understanding.md §A-1`).
- Escalation triggers are named explicitly in each command.
- A fixture per size confirms the flow runs end to end (`13-validation-and-evaluation.md`).

---

## H. Open Items

| # | Item | Position |
|---|---|---|
| W-1 | `/work` auto-router | Deferred past v0; Option A first |
| W-2 | Is Reviewer ever mandatory in Standard? | Yes for public API and security; otherwise session judgment |
| W-3 | Should `workflow-sizing.yml` survive? | Yes, as the source for section C; not as a runtime reference |
