---
name: evidence-before-completion
description: >
  Use before claiming any work is complete, fixed, passing, or done.
  Requires running the relevant verification command and reading its output in the current session.
  Do NOT activate for: mid-task progress updates, planning steps, or reporting a failure.
---

# Evidence Before Completion

## The iron law

```
NO COMPLETION CLAIM WITHOUT FRESH VERIFICATION EVIDENCE IN THIS SESSION
```

If you have not run the verification command **in this message**, you may not claim it passes.

---

## The gate

Before any claim of success or completion:

```
1. IDENTIFY  — What exact command proves this claim?
2. RUN       — Execute it now, fresh, complete. No partial runs.
3. READ      — Read the full output. Check exit code. Count failures.
4. VERIFY    — Does the output confirm the claim?
               YES → proceed to claim WITH the evidence quoted
               NO  → state the actual status with the failure evidence
5. CLAIM     — Only after step 4 confirms.
```

Skipping any step is claiming without evidence.

---

## Claim types that require fresh verification

| Claim | Requires |
|-------|---------|
| "Tests pass" | Run test command → read output → 0 failures |
| "Build succeeds" | Run build command → exit 0 |
| "Linter clean" | Run linter → 0 errors |
| "Bug is fixed" | Reproduce the original symptom → it no longer occurs |
| "Feature works" | Execute the acceptance scenario → expected outcome observed |
| "Agent completed successfully" | Inspect VCS diff → verify actual changes |

---

## Red flags — stop before claiming

- Using "should", "probably", "seems to", "likely"
- About to say "Done", "Complete", "Fixed", "All tests pass" without having run them
- Relying on a previous run (not this turn)
- Trusting another agent's success report without independent verification
- Partial verification ("I ran the unit tests" — did you run integration tests too?)

---

## Acceptable evidence formats

**Tests:**
```
Ran: npm test
Output: 34 passed, 0 failed (exit 0)
Claim: All tests pass. ✓
```

**Build:**
```
Ran: cargo build --release
Output: Compiling... Finished release [optimized] (exit 0)
Claim: Build succeeds. ✓
```

**Bug fix:**
```
Reproduced original failure: [step] → error: "..."
After fix: [same step] → [expected output] (exit 0)
Claim: Bug resolved. ✓
```

---

## False-evidence prevention

Evidence must come from the CURRENT SESSION, not from:
- A previous message in this conversation
- A memory of an earlier run
- An assumption based on code that "looks correct"
- Another agent's report (always verify independently)
