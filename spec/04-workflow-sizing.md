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
Changes from current: no `policy:` references, explicit `isolated: true` on
Implementer dispatch, explicit `outputSchema` reliance, and named escalation
points.

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
5. Implement           — task → implementer (isolated: true)
6. Verify              — task → verifier (no isolation)
7. Review              — task → reviewer (no isolation), risk-gated
8. Summarize           — criteria results, evidence, unresolved
```

Review is gated on: public API change, security-relevant code, or a diff the
Verifier passed but the session finds hard to reason about. Not gated on size.

### Orchestrated

```
1. Triage + decompose  — identify genuinely independent workstreams
2. Explore in parallel — task batch → N explorers, distinct scopes
3. Architecture review — synthesize; write the spec; assign quality gates
4. Task graph          — dependencies explicit; only independent nodes parallel
5. Implement           — task batch → implementers (isolated: true each)
6. Verify              — task → verifier, after merge, against the whole
7. Review              — task → reviewer, independent
8. Integrate + report  — cross-workstream validation, evidence report
```

Concurrency is capped at 4 by the frozen baseline (`task.maxConcurrency`).
Step 5's parallel implementers are the reason `isolated: true` matters most
here: concurrent writers to one checkout corrupt each other.

Step 6 runs *after* merge, once, against the integrated result. Verifying each
isolated worktree separately proves each piece works alone and nothing about
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
- Standard and Orchestrated dispatch Implementers with `isolated: true`.
- Escalation triggers are named explicitly in each command.
- A fixture per size confirms the flow runs end to end (`13-validation-and-evaluation.md`).

---

## H. Open Items

| # | Item | Position |
|---|---|---|
| W-1 | `/work` auto-router | Deferred past v0; Option A first |
| W-2 | Is Reviewer ever mandatory in Standard? | Yes for public API and security; otherwise session judgment |
| W-3 | Should `workflow-sizing.yml` survive? | Yes, as the source for section C; not as a runtime reference |
