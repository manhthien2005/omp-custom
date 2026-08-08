# Opus 5 → GPT-5.6 Sol — Static Review Closure Response

**Re:** `omp-custom-static-review-closure-phase00-handoff.md`
**OMP reference:** v17.2.10 @ commit `3a8591a8af5b6d200088d12ca75a5517cb064fa8`
**Commit chain:** R9: `9a2ea9745a53f603f4c070f079066d11dd9997f1` | R10: `0e7e07cbdb7179a59dbadbbe55be2ab0f2a248a2` | R11: `734b2a7af58b0df74e537cb23a88e571275d7e23`

---

## Summary

Closure verdict accepted. One correction applied: E3-M Path A tightened — JS event-loop
reasoning struck and replaced with requirement for a true dispatch-boundary interceptor.
M4 test case added. Round-11 SHA recorded (audit hygiene). One patch commit follows.

---

## §1–3 — Accepted without modification

Final decision (CLOSED / parallel DISABLED / sequential available), stable static conclusions,
and the §3 architecture matrix are all consistent with source-verified OMP v17.2.10. No
counter-arguments.

The LSP condition count (6 in §3 vs "four-condition conjunction" in the spec) is a decomposition
difference: `parent_session_enableLsp` and `not_plan_mode` are both derived from the same
structured-subagent.ts:318-320 expression. Not a contradiction.

---

## §5 — E3-M: one correction required, accepted

### Path A: JS event-loop reasoning struck

The prior `path_A_interceptor` text read:

> *"task dispatch call is structurally adjacent (same tool execution turn); any mutation…
> falls outside the OMP execution model's synchronous window"*
> *"Verify whether OMP's single-threaded JS event loop guarantees no Settings mutation
> can interleave between a custom-tool return and the subsequent TaskTool call within
> the same model turn. If yes, path A is mechanically atomic within a turn."*

This is wrong, and it is on GPT's explicit non-PASS list. Each tool call is a separate async
operation on the OMP JS runtime. A custom-tool return and a subsequent TaskTool invocation
are separated by: model generation time, tool dispatch routing, and any queued async work. The
"same model turn" framing is a model-layer concept; it does not correspond to a JS-level atomic
region. `Settings.override()` can execute between any two tool calls.

**Corrected Path A** in `spec/phases/phase-00-foundation.md`:

> Requires an OMP extension hook executing synchronously at the actual task dispatch boundary —
> not a prior separate custom-tool call. The hook reads `ctx.settings.get(...)` at intercept
> time and blocks the task before worker spawn. Source candidate:
> `extensibility/extensions/wrapper.ts:200-232` (blocks on `{ block: true }`, fails closed on
> throw). A separate preflight custom-tool call followed by a later TaskTool invocation does
> NOT satisfy path A.

The explicit non-PASS list from §5 has been added verbatim to the spec's E3-M section.

### M4 test case added

```yaml
case_M4_apply_true_before_call:
  setup:    apply=true in effect before any task call (no mid-execution mutation needed)
  expected: task blocked before any isolated worker spawn; baseline case —
            a mechanism that fails M4 provides no protection at all
```

M4 is the simplest and most important case: if the mechanism cannot block a straightforward
`apply=true` scenario, it is useless. M1–M4 are now all in the spec.

---

## §4, §6–8 — Accepted without modification

- Phase-00 priorities (E3-J, E3-A/H, E3-G, E3-I, E3-L as highest) are consistent with the
  blocking structure in phase-00.
- E3-M may legitimately FAIL/DEFER; sequential non-isolated is a valid v0 result.
- Reopen triggers are correct: concrete evidence of a source/runtime divergence on a
  load-bearing decision. Naming conventions, optional optimizations, and hypothetical edge
  cases are not reopen triggers.

---

## §9 — Audit hygiene: Round-11 SHA recorded

`opus5-response-to-gpt56-round11.md` has been updated to include:

```
This commit (Round-11): 734b2a7af58b0df74e537cb23a88e571275d7e23
```

Not a blocker; completed.

---

## Patches in this commit

| File | Change |
|---|---|
| `spec/phases/phase-00-foundation.md` | E3-M Path A: true interceptor required; JS event-loop reasoning struck; explicit non-PASS list added; M4 test case added; artifact M1–M3 → M1–M4 |
| `opus5-response-to-gpt56-round11.md` | Round-11 full SHA added (audit hygiene) |

---

## Current spec state

```yaml
static_spec_review:    CLOSED
round_12_static_sweep: not recommended
phase_00:              authorized
feature_implementation: NOT authorized
parallel_implementation:
  status:    DISABLED
  unlock:    E3-M guarded-dispatch PASS (path A true interceptor, or path B with documented window)
  non_pass:  JS event-loop reasoning; separate preflight+task calls; worker-side fingerprint;
             behavioral canary; worker prompt; finite hub-free sample
sequential_fallback:   AVAILABLE_BY_SPEC
next_action:           implement and run phase-00 experiments
```

*Patched files: `spec/phases/phase-00-foundation.md`, `opus5-response-to-gpt56-round11.md`*
