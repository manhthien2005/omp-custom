---
name: systematic-debugging
description: >
  Use when encountering any bug, test failure, unexpected behavior, or build failure,
  before proposing any fix. Requires completing root-cause investigation before implementation.
  Do NOT activate for: adding new features with no existing failure, clarifying requirements,
  or tasks where no defect is present.
---

# Systematic Debugging

## The iron law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you have not completed Phase 1, you may not propose a fix.

---

## Phase 1 — Root cause investigation (mandatory before any fix)

**Read the error carefully.**
- Do not skip stack traces. Read them completely.
- Note exact file paths, line numbers, and error codes.
- The error message often contains the solution.

**Reproduce consistently.**
- Can you trigger the failure reliably? What are the exact steps?
- If not reproducible: gather more data. Do not guess.

**Check recent changes.**
- What changed that could cause this? (git diff, recent edits)
- New dependencies, config changes, environmental differences?

**Trace the data flow.**
- Where does the bad value originate?
- What called this function with the bad value?
- Trace backward up the call stack until you find the source.
- Fix at the source, not at the observation site.

**In multi-component systems (CI, API→service→database, etc.):**
Add diagnostic instrumentation at each component boundary before proposing any fix:
- Log what enters each component
- Log what exits each component
- Run once to identify WHERE it breaks
- Then investigate THAT component specifically

---

## Phase 2 — Pattern analysis

- Find working examples of the same pattern in the codebase.
- Compare the broken code against a working reference line-by-line.
- List every difference, no matter how small.
- Identify dependencies, config, or environment assumptions.

---

## Phase 3 — Hypothesis and testing

1. Form one specific hypothesis: "I think X causes Y because Z."
2. Make the smallest change that tests this hypothesis.
3. If it works → Phase 4.
4. If it does not work → form a new hypothesis. Do not add more changes on top.

---

## Phase 4 — Implementation

1. Write a failing test case that reproduces the bug (smallest possible).
2. Implement the single root-cause fix.
3. Verify: test passes, no other tests broken, issue resolved.
4. Use `evidence-before-completion` before claiming success.

**If the third fix attempt fails:**
Stop. Do not attempt a fourth fix. Question the architecture:
- Is the fundamental pattern sound?
- Is the problem caused by coupling or shared state that requires refactoring?
- Present findings to the user before proceeding.

---

## Red flags — stop and return to Phase 1

- "Quick fix, investigate later"
- "Just try changing X"
- "It's probably X" (without tracing)
- "One more fix attempt" (after 2+ failures)
- Proposing solutions before tracing the data flow
- Each fix reveals a new problem in a different place

---

## Common rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, skip the process" | Simple bugs have root causes. Process is fast for simple bugs. |
| "Emergency, no time" | Systematic is faster than guess-and-check thrashing. |
| "I see the problem" | Seeing a symptom ≠ understanding the root cause. |
| "3+ fixes, one more try" | Multiple failures = wrong approach. Stop and re-analyze. |
