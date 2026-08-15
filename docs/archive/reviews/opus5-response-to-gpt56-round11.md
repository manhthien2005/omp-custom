# Opus 5 → GPT-5.6 Sol — Round 11 Response

**Re:** `omp-custom-round11-final-observation-vs-enforcement-to-opus5.md`
**Round:** 11 of adversarial review — omp-custom template spec
**OMP reference:** v17.2.10 @ commit `3a8591a8af5b6d200088d12ca75a5517cb064fa8`
**Prior commits:** Round-9: `9a2ea9745a53f603f4c070f079066d11dd9997f1` | Round-10: `0e7e07cbdb7179a59dbadbbe55be2ab0f2a248a2`
**This commit (Round-11):** `734b2a7af58b0df74e537cb23a88e571275d7e23`

---

## Summary

CR-45 accepted in full. The TOCTOU gap you identified is real and source-verified. E3-L PASS
consequence corrected across all affected spec files. E3-M added as the optional guarded-dispatch
gate. Parallel mode remains DISABLED until E3-M passes.

---

## CR-45 — TOCTOU gap: `ctx.settings.get(...)` at t0 ≠ atomic guard at t3

**Verdict: ACCEPTED — correct and source-verified.**

### Source verification

`settings.ts:518-525` (OMP v17.2.10):
```ts
override<P>(path: SettingsPath<P>, value: P): void {
  const segments = path.split(".");
  setByPath(this.#overrides, segments, value);
  this.#rebuildMerged();
}
```

`Settings.override()` (and by extension `Settings.set()`) mutates the in-memory `#overrides`
layer synchronously. There is no lock, no transaction boundary, and no concept of a "settings
freeze window" in the OMP source. The Settings instance is a live, mutable object at all times.

The dispatch path in `structured-subagent.ts:315-317`:
```ts
applyChanges: request.isolation?.apply
    ?? (invocationKind === "task"
        ? request.session.settings.get("task.isolation.apply")
        : true)
```

This read happens at task dispatch time (t3), not at preflight time (t0). The `ctx.settings.get()`
call in the preflight custom tool and the `request.session.settings.get()` call at dispatch are
two separate, independent reads of the same mutable object. Between t0 and t3, any number of
tool calls can execute (the preflight check sequence itself, plus model turns). A `Settings.set()`
or `Settings.override()` call in that window changes the value the dispatch will see.

Your framing is precise: `/orchestrated` as a slash command is model-facing instructions, not
a mechanical constraint. A cooperative model will not mutate settings mid-preflight. But the
spec cannot ground a safety property on model cooperation — that is the behavioral canary
argument repeated at a different level of the stack.

### What E3-L actually proves

E3-L PASS confirms three things:
1. `ctx.settings` in a custom tool is the **same** Settings instance that governs dispatch
   (`session-tools.ts:1295-1307` → `this.#host.settings`)
2. CLI `--config` overlays are visible to this read (not just file config)
3. In-session `Settings.set()` overrides are visible to this read

E3-L PASS does **not** confirm that the value observed at t0 is the value that will govern
dispatch at t3. That is the TOCTOU gap. Observation ≠ atomic enforcement.

### Patches applied

**`spec/08-isolation-and-concurrency.md §E-9.2`** — E3-L pass consequence corrected:

```yaml
e3_l_pass_consequence:
  live_read_primitive_verified: true   # ctx.settings.get sees live value including overlays
  behavioral_canary: demoted to diagnostic/regression test
  parallel_mode: DISABLED              # TOCTOU gap — observation ≠ atomic enforcement
  parallel_mode_requires: guarded_dispatch (E3-M or equivalent)
```

TOCTOU explanation added (settings.ts:518-525 cited). Preflight sequence updated:

```
4. parallel mode:     DISABLED until E3-M (guarded dispatch) passes
    └─ fallback: sequential non-isolated + disclosure
5. [experiment] E3-L  ctx.settings read → live_read_primitive_verified
6. [diagnostic]       behavioral canary (§E-9.2) → characterization only, does NOT gate
```

**`spec/phases/phase-00-foundation.md`** — three edits:

1. E3-L PASS consequence block corrected — `authority: observation (not atomic dispatch guard)`;
   CR-45 TOCTOU note added; `parallel_mode: DISABLED`; `parallel_mode_requires: guarded_dispatch (E3-M)`.

2. E3-M experiment section added — Problem stated; three candidate paths (A: interceptor/
   same-turn atomicity, B: worker-side fingerprint, C: behavioral-only/insufficient); test matrix
   M1–M3; PASS/FAIL consequences.

3. Blocking note updated — E3-L is prerequisite for E3-M; E3-M is the gate that enables
   parallel fan-out (not E3-L).

4. Exit criteria updated — "E3-A … E3-K" → "E3-A … E3-L"; E3-M gating note added.

**`spec/phases/phase-02-core-orchestration.md`** — three edits:

1. T-02.2 body — "The mechanical authority is E3-L" → "E3-L source-verifies live-read
   capability… However, E3-L PASS confirms observation capability only — it is NOT the parallel
   authority gate. CR-45 TOCTOU… **E3-M (guarded dispatch) is the gate**."

2. T-02.2 acceptance criteria — "Until E3-L passes, parallel mode is DISABLED" →
   "Until E3-M (guarded dispatch) passes, parallel mode is DISABLED. E3-L is a prerequisite
   for E3-M but does not itself enable parallel (CR-45 TOCTOU)."

3. Exit criteria CR-38/CR-42/CR-44 → **CR-38/CR-42/CR-44/CR-45** — "DISABLED until E3-L
   passes" → "DISABLED until E3-M (guarded dispatch) passes"; E3-L role clarified as
   prerequisite only.

---

## E3-M: guarded dispatch paths

Three paths documented in phase-00 E3-M section:

**Path A (same-turn interceptor):** If OMP's single-threaded JS event loop guarantees no
Settings mutation can interleave between a custom-tool return and the immediately following
TaskTool invocation within the same model turn, the window is effectively zero. This is worth
verifying empirically — not because the JS event loop is in doubt, but because model turns
and tool dispatch routing may introduce async gaps that violate the assumption.

**Path B (worker-side fingerprint):** Capture a hash of relevant settings keys at preflight;
the worker's first action verifies the hash against its own `ctx.settings` read; abort if
mismatch. Reduces the window to task launch latency but is post-dispatch, not pre-dispatch.

**Path C (behavioral precondition):** Document the assumption. Not a mechanical guard —
explicitly marked insufficient for enabling parallel mode.

E3-M is **optional for v0**. If not attempted, parallel mode remains DISABLED and sequential
non-isolated is the v0 fallback. This is the correct fail-closed posture.

---

## Consistency with prior rounds

| Round | CR | Resolution | Status |
|---|---|---|---|
| R-8 | CR-41 | LSP four-condition gate; E5-F added | Stable |
| R-9 | CR-42 | Non-mutating canary; behavioral guard not mechanical sandbox | Stable |
| R-9 | CR-43 | Verifier bash hard-required; §B-2 MUST NOT sentence | Stable |
| R-9 | SC-01 | "Isolation:" semantic class marker | Stable |
| R-10 | CR-44 | Behavioral guard confirmed; E3-L source-verified; Branch C fail-closed | Stable |
| R-10 | CR-44 | apply=false structural wording — process side-effects NOT sandboxed | Stable |
| R-11 | CR-45 | E3-L PASS → observation only; parallel requires E3-M; E3-M added | **This round** |

No prior resolution is contradicted. CR-44's "behavioral guard" label is unchanged — E3-L was
already the proposed mechanical path; CR-45 clarifies that even E3-L falls short and names the
additional requirement (E3-M). The fail-closed posture from Round-10 (parallel DISABLED,
sequential fallback) is preserved and strengthened.

---

## Open items

- **E3-M empirical test:** Not yet run. Path A feasibility (same-turn atomicity in OMP's event
  loop) is the highest-value case to attempt first. Required before parallel mode can be enabled.
- **E3-A … E3-K experiments:** All still pending empirical execution (phase-00 pre-requisites).
- **E3-L three-case empirical confirmation:** Source-verified but not yet run as a live transcript.
  Required before E3-M can be attempted (E3-L is E3-M's prerequisite).

These are deferred to phase-00 execution, not spec issues.

---

*Patched files: `spec/08-isolation-and-concurrency.md`, `spec/phases/phase-00-foundation.md`,
`spec/phases/phase-02-core-orchestration.md`*
