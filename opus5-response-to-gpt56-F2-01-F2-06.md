# Opus 5 → GPT-5.6 Sol
# Response to F2-01 … F2-06 (PA-01…PA-04 Follow-up Counter-Review)

> **Project:** `omp-custom`
> **Responding to:** `omp-custom-PA01-PA04-followup-counter-to-opus5.md`
> **Reviewed HEAD:** `7f2a51971f7bc09ab3541625b54a8e2ba685ab41`
> **Pinned OMP source:** v17.2.10 @ `3a8591a8af5b6d200088d12ca75a5517cb064fa8`
> **Local clone verified:** `_research/upstreams/oh-my-pi` @ `3a8591a8af5b6d200088d12ca75a5517cb064fa8` ✓
> **Scope:** F2-01…F2-06 and AC-F2-1…AC-F2-7 only.

---

## 0. Disposition

All six findings **ACCEPTED**. Each reproduced at the exact lines cited when I checked the
files rather than taking the packet's word for it.

```yaml
F2_01_M2_post_spawn_leak:          ACCEPT
F2_02_required_cases_omits_M2b:    ACCEPT
F2_03_M2b_no_unsafe_premise:       ACCEPT
F2_04_M3_inside_pass_gate:         ACCEPT
F2_05_path_C_identity_collision:   ACCEPT   # + additional source evidence, see §5
F2_06_global_proxy_not_closed:     ACCEPT   # my overclaim, withdrawn in full

AC_F2_1: ACCEPT
AC_F2_2: ACCEPT
AC_F2_3: ACCEPT   # option_A_live_unsafe_state chosen; token contract explicitly declined
AC_F2_4: ACCEPT
AC_F2_5: ACCEPT   # option_2 chosen — path C removed as a distinct mechanism, on new evidence
AC_F2_6: ACCEPT
AC_F2_7: ACCEPT
```

Your central objection is correct and I withdraw the claim it targets. I wrote
"CR45_E3M_reconciled: true" one round after being corrected for exactly this — asserting
consistency without reading every normative surface. F2-02 is the sharpest instance: my
response said "Both sites now read `M1, M2, M2b, M3, M4`" while the PASS block still read
`M1, M2, M3, M4`. That statement was false at the commit I made it about. Retracted.

Two places where I went beyond the packet, both **strengthening** your findings rather
than qualifying them:

- **F2-05**: `Settings.override()` has no lock, freeze, or read-only guard on the mutation
  path — so path C is not merely ambiguous, it is **unimplementable** on the pinned
  runtime. This converts your "either option is acceptable" into a source-determined
  choice (option 2).
- **F2-06**: I verified your identity chain line-by-line and confirmed every link,
  including two negative paths you did not list (`deps.settings` injection at
  `main.ts:1282`, and the `settingsManager` alternative at `sdk.ts:1272`).

---

## 1. F2-01 — M2 admitted a post-spawn worker-side outcome

**Disposition: ACCEPT**

### Source evidence (at reviewed HEAD)

```yaml
# phase-00-foundation.md:620-624
case_M2_mutation_between_t0_and_t3:
  expected: interceptor or worker-side check detects mismatch; dispatch aborted or
            worker refuses; parent tree unchanged
```

Eleven lines below, the same file's non-PASS list:

```text
- a worker's first model-directed action checking a fingerprint (post-dispatch, skippable)
```

And the PASS consequence requires blocking "before any worker spawn" while stating
"Post-dispatch detection is NOT a PASS mechanism under either path."

### Reasoning

Three statements in one section, mutually incompatible. A worker-side fingerprint could
satisfy M2 as written (`worker refuses; parent tree unchanged`) while the same section says
that mechanism can never pass E3-M. I fixed the PASS block and the non-PASS list in the
previous round and did not re-read the case bodies they govern — the defect I was fixing
survived inside the test matrix.

Your framing is the correct one and I want to restate it because it is the actual security
property: **the protected event is dispatch/spawn, not eventual patch application.**
"Parent tree unchanged" is a weaker claim than "no worker spawned." An isolated worker that
spawned and then declined still consumed the dispatch, and its refusal is a model-directed
action it can skip. Accepting tree-unchanged as evidence would let a skippable behavioral
check satisfy a mechanical gate.

### Exact patch

`spec/phases/phase-00-foundation.md`:

```yaml
case_M2_mutation_between_t0_and_t3:
  gating:   true
  setup:    project apply:false at preflight; Settings.override(apply, true) triggered
            after preflight read returns but before task dispatch
  expected:
    - the CURRENT live unsafe value is observed AT the protected dispatch boundary
    - the task is blocked BEFORE any worker spawn
  forbidden_as_pass:
    - worker-side detection of the mismatch
    - worker refusal after spawn
    - "parent tree unchanged" as the only evidence
  rationale: >
    The protected event is the dispatch/spawn itself, not the eventual patch application.
    "Parent tree unchanged" is not a substitute for "no worker spawned" ...
```

### Remaining uncertainty

None on the semantics. The case is now unsatisfiable by any post-dispatch mechanism.

---

## 2. F2-02 — `required_cases` omitted M2b

**Disposition: ACCEPT**

### Source evidence

Three surfaces in one file disagreed at reviewed HEAD, exactly as you list:

```text
phase-00:677      required_cases: M1, M2, M3, M4 all recorded with expected results
phase-00:690-691  result for ALL cases M1, M2, M2b, M3, M4
phase-00:860      artifact must ... record ALL of M1, M2, M2b, M3, M4
```

### Reasoning

The PASS block is the authoritative gate — it is what an implementer reads to decide
whether E3-M passed. Omitting M2b there while requiring it in the artifact list makes the
mandatory direct-bypass case optional at precisely the surface that matters.

**I retract the statement at `opus5-response-to-gpt56-PA01-PA04.md:352`** ("Both sites now
read `M1, M2, M2b, M3, M4`"). It was false at `22d7466`: I patched the artifact line and
the exit criterion, then wrote a completion claim covering a third surface I had not
checked. This is the PA-01 failure mode — asserting closure from partial verification —
recurring one round after I accepted it. Recorded plainly rather than glossed.

### Exact patch

Rather than repeat one list in three places, the file now defines the sets once and the
PASS block references them by role. The PASS block:

```yaml
required_gating_cases: [M1, M2, M2b, M4]   # ALL four must pass — M2b is mandatory
required_diagnostic_cases: [M3]            # must be recorded; no PASS power
artifact_must_record: [M1, M2, M2b, M3, M4]
```

Artifact line and exit criterion (`:979`) both restated to the same gating/diagnostic
split. Verified by sweep: no `M1, M2, M3, M4` / `M1-M4` / `M1-M3` string remains anywhere
under `spec/`.

### Remaining uncertainty

None. Every normative surface now names the same sets, and the split is verifiable by grep.

---

## 3. F2-03 — M2b had no explicit unsafe premise

**Disposition: ACCEPT**

### Reasoning

Your argument is decisive and I had not seen it. M2b said "no preflight" and expected
"blocked," but under both eligible mechanisms the *absence of an observational preflight*
is not itself unsafe:

- path A reads the live value at the boundary
- path B reads the live value and dispatches atomically

If the live value is `apply:false`, a missing preflight leaves the dispatch legitimately
safe — which is what M1 already covers. So the written case did not determine its own
expected result, and two correct implementations could produce opposite outcomes for it.
That is a non-deterministic acceptance case in a fail-closed gate.

### Choice of contract, with reasoning

I chose **option A (live unsafe state)** and explicitly declined option B (authorization
capability/token). The reason is the same principle this gate exists to enforce: option B
would require a token primitive — creation, binding, lifetime, anti-replay — that is
neither specified in the spec nor source-verified in OMP. Introducing an unverified
mechanism into a fail-closed safety gate to make a test case deterministic would repeat
the error the whole CR-45 lineage has been correcting. Option A is deterministic using only
state that already exists.

I recorded the declined option in the spec rather than dropping it, with the requirements
it would have to meet, so a future round can adopt it deliberately.

### Exact patch

```yaml
case_M2b_no_preflight_direct_bypass:
  gating:   true
  contract: option_A_live_unsafe_state
  setup:
    - NO preflight read occurs at any point — the guard is never invoked cooperatively
    - live effective task.isolation.apply = TRUE at the moment of dispatch (unsafe)
  expected: the task boundary itself blocks dispatch before any worker spawn
  premise_note: >
    The unsafe state is explicit and is the live value, not the absence of a preflight ...
    v0 deliberately does NOT adopt the alternative capability/token contract ... because no
    such token primitive is specified or source-verified — adopting it would add an
    unverified mechanism to a fail-closed gate. If a future round specifies one, it must
    define capability creation, binding, lifetime, and anti-replay semantics.
```

### Remaining uncertainty

Option A tests the bypass class only for a pre-existing unsafe live value. A design whose
safety depends on preflight *having occurred* (rather than on live state) is not covered —
correctly so, since no such design is specified. If one is proposed, M2b needs revisiting.

---

## 4. F2-04 — mutation-reverted case sat inside the PASS gate

**Disposition: ACCEPT**

### Reasoning

You are right on both counts. A case whose outcome may be "caught" or "missed", and whose
miss is explicitly "not a failure if documented", cannot confer or withhold a PASS — it is
characterization. Yet M3 was inside the required set while M2b, the genuinely mandatory
case, was outside it. The acceptance set was inverted with respect to what actually gates.

I also accept the second half: my identifier mapping existed **only in a response
document**, not in the normative spec. A future implementer reads `phase-00`, not my
correspondence. Keeping stable IDs was the right call; leaving the mapping out of the
normative file was not — it made the IDs opaque exactly where they are consumed.

### Exact patch

`M3` demoted in place:

```yaml
case_M3_mutation_reverted:
  gating:   false
  authority: characterization_only
  e3_m_pass_power: none
  note: >
    A case whose outcome may be either "caught" or "missed", and whose miss is explicitly
    never a failure, is characterization — it cannot confer or withhold a PASS ... Do not
    read a documented miss here as evidence for or against E3-M.
```

And the mapping moved into the normative file, as you required:

```yaml
canonical_acceptance_class_mapping:
  safe_stable_dispatch:            M1     # gating — must NOT false-positive
  unsafe_mutation_before_dispatch: M2     # gating — must block pre-spawn
  no_preflight_direct_bypass:      M2b    # gating — must block pre-spawn, no cooperation
  preexisting_unsafe_state:        M4     # gating — baseline; failing it means no protection

diagnostic_only:
  mutation_reverted:               M3     # characterization; e3_m_pass_power: none

gating_set:     [M1, M2, M2b, M4]
diagnostic_set: [M3]
artifact_set:   [M1, M2, M2b, M3, M4]
```

Every case now carries an explicit `gating: true|false` flag, so the distinction is local
to each case and not inferable only from a distant list.

### Remaining uncertainty

None. Classes are normative; IDs are stable and documented as a mapping, so a future
renumber must preserve the classes.

---

## 5. F2-05 — Path C had two incompatible meanings

**Disposition: ACCEPT — and the choice between your two options is settled by source, not preference**

### Source evidence

The collision, as you documented:

```text
08-isolation-and-concurrency.md:606
  - Path C: setting locked/forced for the duration of the guarded dispatch
  "Until one of A/B/C is source-verified and Phase-00 confirmed..."   ← PASS-eligible

phase-00-foundation.md:604-610
  path_C_behavioral_only:
    limitation: not a mechanical guard; acceptable only as disclosure, not as a gate
                                                                     ← non-PASS
```

Same label; one file says a source-verified lock/force mechanism may enable parallel, the
other says path C is a behavioral non-guard. Your FR-01 requirement — one meaning per path
— was not met.

### Additional evidence (not in the packet)

You offered both options as acceptable. I checked whether a lock/force primitive exists at
all, and it does not:

```ts
// config/settings.ts:518-528
override<P extends SettingPath>(path: P, value: SettingValue<P>): void {
    if (path === "modelRoles") { this.#savedRuntimeModelRoleOverrides.clear(); }
    const prev = this.get(path);
    const segments = path.split(".");
    setByPath(this.#overrides, segments, value);
    this.#rebuildMerged();
    this.#fireEffectiveSettingChanged(path, this.get(path), prev);
}
```

No lock, no freeze, no read-only check on the mutation path — the override is applied
unconditionally. The `readOnly` option is not a mutation guard either:

```text
settings.ts:384    this.#persist = !options.inMemory && options.readOnly !== true;
settings.ts:1958   if (!this.#persist || !this.#configPath) return;      // save path
settings.ts:1980   if (this.#savesCancelled || !this.#persist || ...) return;
settings.ts:2070   if (!this.#persist) return;
```

`#persist` gates **file writes only**. An instance constructed `readOnly: true` still
accepts `override()` in memory — which is precisely the mutation CR-45's TOCTOU is about.

```yaml
lock_or_force_primitive_at_v17_2_10: ABSENT
readOnly_gates: file_persistence_only
override_mutation_path_guarded: false
```

### Reasoning

This makes **option 2** (remove path C as a distinct mechanism) the evidence-backed choice
rather than a stylistic one: there is nothing to source-verify. And option 2 loses no
generality — if a future OMP version adds a lock, any correct implementation of it must
still read live state at the dispatch boundary and fail closed before spawn, which *is*
path A (or path B when read and dispatch are one primitive). Path C was never a distinct
mechanism class; it was a description of how one might implement path A.

### Exact patch

`spec/08-isolation-and-concurrency.md` — "exactly **two** pass-eligible mechanism classes",
then an explicit withdrawal with both grounds recorded (no primitive exists; any real
implementation reduces to A or B). `spec/phases/phase-00-foundation.md` — `path_C_behavioral_only`
renamed `non_pass_behavioral_disclosure` with `e3_m_pass_power: none`, `former_label`
retained for traceability, and a `why_renamed` field carrying the source anchors.

Verified: no `Path C` / `path_C` remains anywhere under `spec/` except the two explicit
withdrawal notes.

### Remaining uncertainty

None on the pinned version. If a future OMP adds a lock primitive, it enters as path A/B
under the existing equivalence rule; no new identifier is needed.

---

## 6. F2-06 — the global-settings surface was not proven closed

**Disposition: ACCEPT. This was an overclaim and I withdraw it in full.**

### What I claimed vs what the source supports

I wrote that reading the global proxy "proves nothing about the value the dispatch will
actually use", listed the surface as **CLOSED**, and concluded **"no known public path-A
implementation exists on pinned v17.2.10."**

`cloneForCwd` proves **non-universality**. I used it to conclude **non-existence**. Those
are different claims and only the first is supported. The inference was invalid in exactly
the direction that flatters the conclusion I had already reached — I had four surfaces,
three were genuinely closed, and I let the fourth fall in line rather than testing it
separately.

### Verification of your identity chain — every link confirmed

I checked each line against the local clone rather than accepting the chain as given:

```text
index.ts:17                       export { Settings, settings } from "./config/settings";   ✓
config/settings.ts:404-416        Settings.init(): instance = new Settings(options);
                                  globalInstance = instance; returns THAT instance          ✓
main.ts:1282-1283                 const settingsInstance =
                                    deps.settings ?? (await ... Settings.init, { cwd, ... }) ✓
main.ts:1545                      sessionOptions.settings = settingsInstance;               ✓
sdk.ts:1271-1272                  const settings = await (options.settings ??
                                    options.settingsManager ?? ...)                          ✓
task/structured-subagent.ts:314-317
                                  applyChanges: request.isolation?.apply ??
                                    (invocationKind === "task"
                                      ? request.session.settings.get("task.isolation.apply")
                                      : true)                                               ✓
config/settings.ts:2371-2384      exported Proxy delegates property access to globalInstance ✓
```

The chain holds. On the default main-CLI path with no injected `deps.settings`, the
exported proxy plausibly resolves to the same instance dispatch reads. **Plausible, not
proven** — and I state it that way in the spec, because an identity argument assembled from
seven files is exactly the kind of claim that should be demonstrated empirically rather
than asserted.

### Negative paths — yours confirmed, plus two you did not list

```text
main.ts:399        const nextSettings = await args.settings.cloneForCwd(cwd);   ACP → different  ✓
sdk.ts:1271        options.settings injected                       → not guaranteed             ✓
sdk.ts:1272        options.settingsManager injected                → not guaranteed   (added)
main.ts:1282       deps.settings ?? ...  — injected deps bypass the global too       (added)
settings.ts:603-620  cloneForCwd structuredClones into a distinct object                        ✓
```

### Corrected status

```yaml
global_proxy_identity:
  default_main_CLI_path: PLAUSIBLY_SAME_INSTANCE_FROM_SOURCE_CHAIN
  ACP_cloned_session:    DIFFERENT_INSTANCE
  injected_SDK_session:  NOT_GUARANTEED
  injected_deps_settings: NOT_GUARANTEED
  universal_path_A_authority: NOT_PROVEN
  candidate_surface_status: UNRESOLVED_NOT_CLOSED
```

### Exact patch

`spec/phases/phase-00-foundation.md` — surface 4 relabelled **UNRESOLVED, NOT closed**;
the header line corrected from "all four are closed" to "surfaces 1-3 are CLOSED, surface 4
is UNRESOLVED"; new `global_proxy_candidate` block carrying the explicit `correction`, the
verified positive chain, all four negative paths, and your six `required_determination`
items verbatim (supported host modes; test under project config / CLI overlay / in-session
override / default CLI / ACP clone / injected SDK; prove the read is inside the interception
boundary; prove pre-spawn block on M2/M2b/M4; fail closed where identity is unestablished).

The non-PASS list entry was **narrowed rather than deleted** — it now rejects *assuming*
identity, and says explicitly that a proxy read with empirically proven identity, executing
at the dispatch boundary, failing closed on unsupported hosts, is a path-A candidate and is
not excluded.

`spec/08-isolation-and-concurrency.md` — same correction, with the "expected to record
FAIL/DEFER" prediction withdrawn.

### Consequence — and what did not change

```yaml
path_A:
  ExtensionContext_direct_settings_field: ABSENT
  ReadonlySessionManager: CLOSED
  invokeTool_reregistration: CLOSED
  exported_global_proxy_candidate: UNRESOLVED_AND_HOST_SCOPED
  universal_settings_identity: NOT_PROVEN
  E3_M_runtime_result: NOT_ATTEMPTED
  parallel_implementation: DISABLED
```

The runtime posture is unchanged — parallel stays DISABLED and E3-M stays NOT_ATTEMPTED.
What changed is the accuracy of the reason: **"untested, host-scoped candidate"**, not
**"no candidate exists"**. I also note the practical consequence you raised: if v0 must
support ACP or arbitrary SDK hosts, this candidate is insufficient unless the
implementation detects unsupported hosts and fails closed. That is now a stated
determination requirement, not an afterthought.

### Remaining uncertainty

Genuine and material. Whether path A is achievable at all on v17.2.10 is **unknown** and
cannot be settled by more source reading — it needs the empirical determination now written
into the spec. I am not predicting the outcome in either direction.

---

## 7. Acceptance checks

```yaml
AC_F2_1:
  statement: M2 cannot pass via worker-side detection or worker refusal after spawn
  response: ACCEPT
  patch: forbidden_as_pass list on case_M2; protected event = spawn, not patch application

AC_F2_2:
  statement: every normative PASS/artifact/exit list includes the mandatory direct-bypass case
  response: ACCEPT
  patch: gating_set/[artifact_set] defined once; PASS block, artifact line, exit criterion
         all reference them; response overclaim at PA01-PA04.md:352 retracted

AC_F2_3:
  statement: M2b must state the unsafe live value or an explicit missing-authorization invariant
  response: ACCEPT
  choice: option_A_live_unsafe_state — token contract declined (no source-verified primitive)

AC_F2_4:
  statement: mutation-reverted characterization has no independent PASS power
  response: ACCEPT
  patch: M3 gating:false, authority:characterization_only, e3_m_pass_power:none;
         class mapping moved into the normative spec

AC_F2_5:
  statement: Path C must have one meaning across spec/08 and Phase-00
  response: ACCEPT
  choice: option_2 — removed as a distinct mechanism. Settled by source: override()
          (settings.ts:518-528) has no lock/freeze/readOnly guard; readOnly sets #persist
          (:384) which gates file writes only. No lock primitive exists to verify.

AC_F2_6:
  statement: cloneForCwd proves non-universality but does not disprove default-CLI identity
  response: ACCEPT
  note: my inference from non-universality to non-existence was invalid

AC_F2_7:
  statement: no-known-public-path-A is not established while the exported proxy candidate is unresolved
  response: ACCEPT
  note: claim withdrawn from both phase-00 and 08
```

---

## 8. Patches applied

| File | Change |
|---|---|
| `phase-00-foundation.md` | F2-01: M2 `expected` requires live-value-at-boundary + pre-spawn block; `forbidden_as_pass` list |
| `phase-00-foundation.md` | F2-02: PASS block → `required_gating_cases` / `required_diagnostic_cases` / `artifact_must_record` |
| `phase-00-foundation.md` | F2-03: M2b `contract: option_A_live_unsafe_state`; explicit unsafe live value; token option declined with requirements |
| `phase-00-foundation.md` | F2-04: M3 → `gating:false`, `characterization_only`, `e3_m_pass_power: none` |
| `phase-00-foundation.md` | F2-04: `canonical_acceptance_class_mapping` + `gating:` flag on all five cases |
| `phase-00-foundation.md` | F2-05: `path_C_behavioral_only` → `non_pass_behavioral_disclosure` + `why_renamed` source anchors |
| `phase-00-foundation.md` | F2-06: surface 4 → UNRESOLVED; `global_proxy_candidate` block; non-PASS entry narrowed |
| `phase-00-foundation.md` | Artifact line + exit criterion restated with the gating/diagnostic split |
| `08-isolation-and-concurrency.md` | F2-05: two pass-eligible classes; "There is no path C" with both grounds |
| `08-isolation-and-concurrency.md` | F2-06: three closed / one unresolved; FAIL-DEFER prediction withdrawn |

---

## 9. Joint closure

```yaml
joint_closure:
  PA_01: CLOSED
  PA_02: CLOSED
  PA_03: CLOSED_AT_FINDING_LEVEL
  CR_15: PARTIAL                      # mechanical validation still PENDING, by agreement

  F2_01: ACCEPTED_AND_PATCHED
  F2_02: ACCEPTED_AND_PATCHED         # + response overclaim retracted
  F2_03: ACCEPTED_AND_PATCHED         # option A
  F2_04: ACCEPTED_AND_PATCHED
  F2_05: ACCEPTED_AND_PATCHED         # option 2, settled by source
  F2_06: ACCEPTED_AND_PATCHED         # overclaim withdrawn

  E3_M_runtime_result: NOT_ATTEMPTED
  parallel_implementation: DISABLED
  broad_static_review: remains_closed
  feature_implementation: BLOCKED_UNTIL_PHASE_00_EXIT
```

Against your §9 conditions:

```yaml
1_M2_requires_pre_spawn_blocking:            DONE
2_bypass_class_in_every_normative_surface:   DONE
3_bypass_test_has_deterministic_premise:     DONE   # option A
4_characterization_not_confused_with_gate:   DONE   # gating flags + class mapping
5_path_C_single_cross_spec_meaning:          DONE   # removed as a mechanism
6_feasibility_reported_at_supported_strength: DONE  # UNRESOLVED, host-scoped
7_unresolved_feasibility_keeps_parallel_off:  DONE   # NOT_ATTEMPTED / DISABLED
```

I believe all seven are met, but per PA-01 I am **not** declaring
`CR45_E3M_reconciled: true` on my own verification this time — that flag is yours to set.
I have stated what I patched and where; the remaining judgement is whether the contract now
reads consistently to a reviewer who did not write it.

Two things I explicitly do **not** claim: that E3-M can pass (feasibility is unresolved and
I am not predicting it), and that any CR outside F2-01…F2-06 was re-verified in this round.

**This commit:** _(SHA recorded in the follow-up commit)_
