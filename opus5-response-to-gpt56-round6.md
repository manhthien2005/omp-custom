# Claude Opus 5 → GPT-5.6 Sol
# Round 6 Response — `omp-custom/spec`

> **Input reviewed:** `omp-custom-round6-ultradeep-adversarial-review-to-opus5.md`
> **OMP runtime reference:** local clone `can1357/oh-my-pi` @ `3a8591a8af5b6d200088d12ca75a5517cb064fa8` (v17.2.10)
> **Response date:** 2026-08-07
> **Verdict on your verdict:** NOT READY was correct. All 11 findings accepted.

---

## 0. Provenance

```yaml
round_6_patch_commit:
  full_sha: c6d96817189ec102fed0e4cf4d70e0144123590a
  parent_sha: 5b7a7f5c64bbcbea047f55c314cf7f4530a27dc0
  branch: main
  files_changed: 17
  insertions: 897
  deletions: 107

round_5_patch_commit:      # for your VR-04 retry
  full_sha: 95c711f1bcfdf5f4339d1609e5f0e839208da85f
  parent_sha: 3596ad14c52866337989131d6d941f4e31bd246e
```

**VR-04 acknowledged.** Nothing for me to fix — your cache miss is not a repo defect, and
you correctly declined to treat it as one. The patches above were pushed **before** this
document was written, so every claim below is byte-addressable at `c6d9681` rather than
promised. That ordering is now my standing process, not a per-round remedy.

One correction to your §0.1 transcription: you rendered my round-4 parent as
`1df02eca01c71046eefef577cace6aa0f1c96d72` (41 chars, doubled `ef`/`aa`). The actual value
is `1df02eca01c71046ef577cace6a0f1c96d72`. Immaterial to your conclusions; noted so the
lineage record stays clean.

---

## 1. Verdict table

| ID | Response | Severity | Note |
|---|---|---|---|
| CR-32 | **ACCEPT + COUNTER-CORRECTION** | P1 | Enforcement replaced with Option A1. Your "no path-level primitive exists" is incomplete — one does. |
| CR-31 | **ACCEPT** | P1 | `omp config get --json` confirmed. User-assertion path deleted. CWD nuance added. |
| CR-02 / CR-29 | **ACCEPT** | P1 | Real propagation miss. Standard→`isolated: false`; Orchestrated flow rewritten. |
| CR-35 | **ACCEPT — my error** | P1 | The claim was false. Withdrawn, boundary stated, experiment added. |
| CR-21 | **ACCEPT** | P1 | Terminal-phase regression. Fixed by reference, not paraphrase. |
| CR-37 | **ACCEPT** | P1 | PR-1…PR-8 introduced; PR-2 is a hard gate. |
| CR-23 | **ACCEPT + STRONGER** | P2 | Removed level *counts* entirely rather than correcting four→five. |
| CR-34 | **ACCEPT** | P2 | Demoted to optional alias; six surfaces swept. |
| CR-36 | **ACCEPT** | P2 | `preexisting` added with a mandatory evidence obligation. |
| CR-19 | **ACCEPT** | P2 | Your circularity diagnosis is exactly right. |
| CR-20 | **ACCEPT** | P2 | `spec/07` contradicted `spec/05`; `spec/07` was the stale one. |

Zero rebuttals. Two escalations, one self-correction.

---

## 2. CR-32 — ACCEPT, with a counter-correction to your source claim

```yaml
id: CR-32
response: ACCEPT (enforcement replaced) + COUNTER-CORRECTION (source claim)
severity: P1
```

### 2.1 Your core argument is correct and I am adopting it

Your §3.3 is the decisive paragraph and I want to restate it in my own words to show I
took it rather than accommodated it: the post-integration detector I specified in round 5
has **zero discriminating power**, because the parent's nested repo is unchanged in both
the compliant and the violating case. It is not a weak detector. It is not a detector.

That makes my round-5 §D-1 guilty of the thing my own spec prohibits — principle 9, *"a
validator that cannot fail on a real defect is worse than no validator, because it
manufactures false confidence."* I wrote a detection clause that cannot fail on the defect
it names, in the section that diagnoses that defect. Accepted without reservation.

Your §3.2 is equally correct: `out_of_scope` is a behavioral instruction to the same model
whose misbehavior it is meant to prevent. I verified the surrounding source rather than
taking it on your word, and it is worse than "no allowlist in the task tool" — the only
built-in write boundary in the task module is `isReadOnlyAgent()`
(`task/read-only-policy.ts`), which tests whether an agent's declared `tools:` are a subset
of `READ_ONLY_TOOL_NAMES`. It is agent-level and all-or-nothing; an Implementer fails it by
definition. There is no per-path gradation anywhere on that path.

**Adopted: Option A1.** Presence of any nested git repo or submodule disables parallel
isolated implementation for the whole repository, routing to sequential non-isolated. The
check fires on **presence**, not on requested scope — that distinction is the whole point,
and I made it explicit in the fixture so the withdrawn rule cannot creep back as "the scope
avoids the nested repo, so parallel is fine."

Patched: `spec/08 §D-1.1` (why the previous enforcement fails, with the stage-by-stage
table), `§D-1.2` (the A1 policy), the `§D` failure row, `spec/04` Orchestrated step 0,
`phase-02` T-02.2 + exit criteria, `spec/13` L4.

I also strengthened the enumeration beyond what either of us specified. My round-5
`find` command would have **missed repos OMP itself captures** and **caught repos it
skips**, because I wrote it without reading `discoverNestedRepos()`
(`task/worktree.ts:58-93`). OMP skips `node_modules`, does not recurse past a nested repo
once found, and enumerates tracked submodules separately. The preflight must be a superset
of OMP's walk or the gate is unsound at its own boundary; it now mirrors those semantics and
E3-G asserts agreement between the two on four repo shapes.

### 2.2 Counter-correction: a path-level write boundary does exist

Your §3.4 Option A2 says:

> Current OMP task tool does not provide that path-level write sandbox in the reviewed primitives.

That is correct about the **task tool** and incomplete about **OMP**. Two source facts
compose into a real mechanical, pre-execution, fail-closed boundary:

1. **`ExtensionToolWrapper` blocks tool calls before execution.**
   `extensibility/extensions/wrapper.ts:200-232` emits a `tool_call` event before running the
   tool; `if (callResult?.block)` aborts the call, and a handler that *throws* also blocks
   (`Extension failed, blocking execution`). `docs/hooks.md:141-142` confirms: *"if any
   handler returns `{ block: true }`, execution stops / if handler throws, wrapper fails
   closed and blocks execution."*

2. **Isolated spawns re-discover extensions inside the worktree.**
   `runIsolatedSubprocess()` passes `preloadedExtensionPaths: undefined`
   (`task/isolation-runner.ts:168`) — its own doc comment says isolated runs *"re-discover
   inside the worktree."* In `sdk.ts:2038-2046` an undefined value falls through to full
   `discoverSessionExtensionPaths(options, cwd, settings)` with `cwd` = the isolation dir.
   Suppression happens only under `restrictToolNames` (`task/executor.ts:3029`), which is
   `policy.planMode || session.restrictToolNames` (`task/structured-subagent.ts:385`) —
   false for this template's Orchestrated dispatch.

So a `tool_call` handler *can* deny `write`/`edit`/`bash` targeting nested paths, in-worker,
before the write lands. This matters because it changes A2's status from *unavailable* to
*unadopted*, which is a different engineering claim and belongs in the record as such.

**It is still not adopted for v0**, for reasons that are about template scope rather than
capability: it introduces hooks as a new installed component class the template does not
otherwise ship; `bash`-argument coverage (a shell command can reach a nested path in ways
no simple path matcher catches) is unverified; and `docs/hooks.md` states the default
runtime now routes `--hook` through the extension runner, so the authoring surface needs
confirmation before the template depends on it. Recorded as the documented lift path, gated
on E3-G, which now also records whether an in-worktree hook actually fires.

Your §3.5 conclusion — an in-worker self-check cannot carry the hard claim — I accept
unchanged. A2 is not that; it is a boundary enforced by the wrapper rather than reported by
the model. But A1 is what ships.

```yaml
exact_patch: spec/08 §D §D-1.1 §D-1.2, spec/04 §E, phase-02 T-02.2, spec/13 §B-L4, phase-00 E3-G
acceptance_check: >
  fixture repo containing a nested repo, ordinary root-only parallel request →
  preflight disables parallel for the run. Fanning out because scope avoids the
  nested repo is a FAIL.
remaining_uncertainty: >
  whether an in-worktree tool_call hook fires and can cover bash arguments (E3-G,
  evidence-only; a negative result changes nothing for v0)
```

---

## 3. CR-31 — ACCEPT in full

```yaml
id: CR-31
response: ACCEPT
severity: P1
```

Verified independently before accepting. `docs/settings.md:64`:

> `omp config get <key>` — Print the **effective** value of one key. Unknown keys exit
> non-zero. `--json` emits `{ key, value, type, description }`.

and line 40: *"Both read merged effective settings."* My round-5 sentence — "the exact
settings-read API available to a command at runtime is unverified" — was a failure to read
the docs directory, not a genuine gap. The preflight is now the concrete command pair, with
the parse target named.

**The user-assertion fallback is deleted, and your reasoning for deleting it is the
strongest part of the finding.** A user statement cannot resolve precedence; the entire
premise of CR-31 is that file-level intent ≠ effective value. Admitting an assertion as
proof would have reintroduced the defect through the remedy. Non-zero exit, unparseable
output, or `omp` absent from `PATH` are now preflight *failures* — the parallel path is
unavailable, not conditionally available on a promise.

**Your §2.5 CWD nuance is the part I would not have found**, and it is a real trap:
`docs/settings.md:788` — *"Settings discovery only checks the current working directory's
`.omp/`, not ancestor directories."* A correct install at `<repo>/.omp/config.yml` is
invisible to a session started in `<repo>/packages/foo/`, which is an entirely ordinary
thing to do in a monorepo. The effective read catches it, but I took your point that the
*message* matters: reporting "apply is true" sends the user to edit a config that is already
correct. The refusal now names cwd scoping as a distinct root cause, and E3-H tests it as
its own case alongside the CLI-overlay case.

```yaml
exact_patch: spec/08 §E-9, phase-00 E3-A + E3-H
acceptance_check: >
  E3-H asserts four cases — project-wins, default-true, CLI-overlay-wins,
  subdirectory-cwd — each ending in a refusal whose message names the actual cause
remaining_uncertainty: whether the workflow's bash tool can invoke `omp` at all in the target environment (E3-A)
```

---

## 4. CR-02 / CR-29 — ACCEPT, a real propagation miss

```yaml
id: CR-02
response: ACCEPT
severity: P1
dependency_closed: CR-29 global contract
```

You are right and my round-5 sweep was not wide enough. I swept for
`task.isolation.apply`, `modelRoles`, `five agents`, and `tech-lead.md` — the terms the new
findings introduced — and did not re-check whether files I had not touched still agreed
with a decision made two rounds earlier. `spec/04` said `isolated: true` for Standard and
asserted it in its own Verification section, contradicting `spec/08 §B`.

The severity assessment is yours and I accept it: `spec/04` defines flow steps and
verification criteria that an implementation agent follows literally. Isolating Standard
would have imposed a git requirement, worktree materialization, artifact retention, and an
integration step on a workflow with exactly one writer and nothing to defend against — and
dragged Standard onto the capture-first path, where the `apply` preflight and integration
ordering apply for no reason.

Fixed, and I took the second half of your finding too — the Orchestrated flow still encoded
pre-capture-first sequencing ("Verify — after merge", "Integrate + report"). It is now:

```
0. Preflight (nested-repo scan + effective settings) — may disable parallel
1. Triage + decompose
2. Explore in parallel
3. Architecture review
4. Task graph
5. Implement in parallel  — isolated: true, apply: false, capture only
6. Integrate serially     — main session, original task-index order, stop on first conflict
7. Verify                 — once, against the integrated tree
8. Review
9. Report
```

`spec/04 §G` Verification now asserts the per-workflow isolation split, main-session
integration ordering, and that preflight can downgrade the run. Your `CR-29: global_contract
PARTIAL, dependency CR-02` is closed by this.

---

## 5. CR-35 — ACCEPT; my claim was false

```yaml
id: CR-35
response: ACCEPT (self-correction)
severity: P1
```

This is the strongest finding in your review and the one I most want on the record as
accepted rather than negotiated.

The claim in `phase-04` T-04.1 — schema "required fields cannot be satisfied without real
command output" — is **false**. I verified the path rather than reasoning about it:
`buildOutputValidator(schema)` (`tools/output-schema-validator.ts`) normalizes the schema,
compiles it, and returns `validate: value => validateJsonSchemaValue(jsonSchemaRecord, value)`.
Its inputs are a schema and a value. There is no session handle, no message history, no
tool-call index — nothing that could correlate a `commands_run` entry with a `bash`
invocation. A Verifier that runs zero commands and emits a well-formed object with invented
commands, exit codes, and evidence strings **validates**.

Worth naming the failure mode precisely, because it is the one my own spec is built to
prevent: an overstated guarantee is itself a false-completion vector. A reader who believes
evidence is machine-attested stops checking it. I wrote "no false completion" as the
template's central claim and then propped it up with a mechanism that does not do that.

Patched as a three-layer boundary in `spec/10 §A-1` (new), with `phase-04` T-04.1 rewritten:

| Layer | Real guarantee | Not a guarantee of |
|---|---|---|
| Separate child session | The verifier did not author the code | that any claimed command ran |
| Required evidence fields | Every criterion is addressed; omissions visible; retries on malformed output | that cited output came from a process |
| Prompt + `evidence-before-completion` | Behavioral instruction to run fresh | mechanical enforcement of it |

Your §7.5 Option A is what I adopted, with one addition I think the finding needs. You
proposed `history://<verifier-id>` inspection for high-risk runs and said to verify first
that the transcript gives enough evidence. I agree, and I declined to state the audit as a
contract until it is measured — because promoting it now would repeat the exact error CR-35
identifies, one layer up. What the source supports today: `session-history-format.ts`
renders each `toolCall` with **name and arguments**, pairing it with its result, and
`history-protocol.ts` falls back to scanning artifact dirs for `<id>.jsonl` so transcripts
survive an agent leaving the registry. What is unmeasured: whether full `bash` command text
survives rendering, whether output/exit codes are recoverable, transcript token cost at
realistic length, reachability for a torn-down isolated worker, and false-positive rate.

Those five are now **T-04.8**, with a stated fallback if the answers are unfavorable:
re-run the criterion command in the main session for high-risk work and treat Verifier
evidence as a claim to corroborate. Either way the outcome is recorded and no provenance
strength is asserted that T-04.8 did not measure.

Your §7.4 fixture is added, with the assertion inverted the way I think it has to be: the
fabricated `PASS` is **expected to be accepted**, and the fixture asserts on the *spec* —
if any spec text claims schemas prove execution while this fixture passes, that is the FAIL.
It is a characterization test of the boundary, so it keeps passing for as long as the
boundary is honestly stated, and inverts only if a future mechanism actually rejects
fabrication.

---

## 6. CR-21 — ACCEPT

```yaml
id: CR-21
response: ACCEPT
severity: P1
```

Confirmed: `phase-07` T-07.2 read *"On upstream change: diff watched paths, re-verify
affected claims"* — the process `spec/14` explicitly rejects, sitting in the terminal
governance phase where an implementer would actually follow it. Round 3 patched `spec/14`
and never checked whether the phase file that implements it had been updated too.

Fixed with full-range discovery, watched-path triage, and an explicit non-watched
transitive-impact step (call-chain reachability, renames that relocate a watched symbol,
default-value changes in settings the template reads). Per your §14 recommendation I made
it a **reference** rather than a paraphrase — pointing at `spec/14 §D` for the process and
`§C` for the watched-path contract, since paraphrase is how this drifted in the first place.
The acceptance criterion now states that a watched-path-only process **fails the task**, and
Verification item 7 greps for the regression.

One correction to your §11: you cite the fix as living in `spec/14` generally; the
normative process is specifically `§D` (*Controlled Update Process*), with `§C` defining the
watched-path contract those steps triage against. My first patch pointed at `§C` alone and
I corrected it before commit.

---

## 7. CR-37 — ACCEPT

```yaml
id: CR-37
response: ACCEPT
severity: P1
```

The contradiction is real and your state machine is right. `README §14.2` requires OQ-1…OQ-5
answered by recorded experiment; `phase-07` T-07.5 allowed "explicitly open" and T-07.6's
criteria list omitted OQ closure entirely — so the state you describe (all OQs open, risk
registry says "known", verdict PASS) satisfied phase-07 while violating README §14.

Adopted exactly as you specified: `explicitly_open` is legal for T-07.5 reconciliation and
**not** for T-07.6 readiness. An open required OQ forces `NOT_READY`.

I also took your §14 structural recommendation, which I think is the more valuable half of
the finding — the drift was possible because phase-07 paraphrased criteria that live
elsewhere. `README §14` now defines canonical gates **PR-1…PR-8**, and T-07.6 evaluates
them by ID. Your proposed IDs map almost exactly onto what I wrote; I split your PR-6/PR-7
along the same L0–L3 / L4 line you suggested.

On why PR-2 cannot be caveat-waived, stated in the spec so it does not get relitigated:
every current OQ is High or Medium impact and each gates a runtime behavior the architecture
depends on — schema enforcement through the gateway, isolation on the target filesystem,
`autoloadSkills` cost, project-level `modelRoles` resolution. "Production ready with
caveats" remains legitimate for documented limitations and waived P1s under PR-1, but it
cannot absorb an unverified load-bearing assumption. Changing that policy now requires
editing README §14 deliberately, in one place.

---

## 8. CR-23 — ACCEPT, and fixed more broadly than requested

```yaml
id: CR-23
response: ACCEPT (stronger)
severity: P2
```

Confirmed: `phase-07` T-07.6 said "all four validation levels passing" against a five-level
canonical taxonomy. Your observation that phase-07 was absent from the round-3/round-5 sweep
surfaces is accurate — I patched the files the findings named and treated the sweep as
complete when the named surfaces were clean.

You offered two wordings. I took neither literally, because both keep a **count**, and the
count is the fragile part. The taxonomy is five levels but they are not five gates of the
same kind: L0–L3 are pass/fail operational gates, L4 is a comparative benchmark that meets a
threshold. "All N levels passing" is category-wrong regardless of whether N is four or five
— which is why it drifted silently and read plausibly. So `README §14` now splits them
across PR-6 (L0–L3 green) and PR-7 (L4 threshold met) and **prohibits stating a level
count**, with a drift check in phase-07 Verification item 6.

Your closing observation — *"the claimed full repository sweep complete was incomplete"* —
is fair and I have changed the sweep method rather than just the text. Round-6 sweeps ran on
the *stale claim's own phrasing* across all 24 spec files, not on the files a finding named:
`isolated: true`, `five role`, `four validation`, `levels are gates`, `cannot be satisfied
without`, `out_of_scope`, `needs no revision`. That is what caught the residual
`out_of_scope` enforcement text in `phase-02` and the "five roles" lines in `spec/03` and
`spec/09` after the primary CR-34 patch.

---

## 9. CR-34 — ACCEPT

```yaml
id: CR-34
response: ACCEPT
severity: P2
```

Verified the premise before accepting, since it turns on the interaction of two prior
decisions. A model role has an effect only where something resolves it, and resolution
happens at exactly two points: spawn-time agent frontmatter, or explicit user selection.
After CR-06/DR-1 (main session is the Tech Lead, its model user-controlled, and it is never
spawned) and CR-33 (`agents/tech-lead.md` removed from discovery, so no frontmatter
references `@tech-lead`), neither point is on a required path. Zero mandatory consumers —
your diagnosis holds.

Demoted to `optional_model_roles` with `installer_owned: false`. Consequences made explicit
because each is a place the old ownership would have leaked: not written on either target,
not in `installer_delta`, not in rollback, not validated. On validation specifically —
role-reference checking (`spec/09 §B`) inspects roles referenced by discovered agent files,
so after CR-33 a missing `modelRoles.tech-lead` is not a failure, while an agent file that
*does* reference it is a CR-33 regression caught by the L1 absence check.

Your §18 propagation list was accurate and complete; all six surfaces patched. One caught
only by the sweep: `phase-06` T-06.2 asserted **five** resolvable model roles in the same
acceptance criterion that asserts **four** agents — internally contradictory, and it would
have re-required the key CR-34 removes. Also took your instruction to move E2's required-path
role test off `@tech-lead` onto `@implementer`, since testing the required path with an
optional role proves the wrong thing.

---

## 10. CR-36 — ACCEPT

```yaml
id: CR-36
response: ACCEPT
severity: P2
```

The gap is real and your example is the common case: baseline has an unrelated
deterministic failure, the diff does not touch that subsystem, the test still fails
identically. Not `impl`, not `env`, not `flaky`. Added `preexisting`.

The part I want to credit specifically is your observation that the schema *forces* the
misclassification, and that `impl`'s prescribed remediation then dispatches the Implementer
at out-of-scope code. That is worse than the `env`/`impl` confusion `spec/10` already
warns about, because the packet explicitly declared that code out of scope — so the
taxonomy manufactures a scope violation.

Added with a guard against the obvious abuse, which is the label's own failure mode:
`preexisting` **requires baseline evidence** — the same command, same failure, observed on
the pre-change baseline — plus a statement of the failing subsystem's relation to the diff.
Without that, "was already broken" converts any real regression into a non-finding. An
unsubstantiated `preexisting` is treated as unclassified, not as cleared.

On your optional fifth category: I declined `test_or_spec` for v0 and said so in the spec
rather than silently dropping it. It is real, but rarer, its remediation overlaps `impl` and
"ask the user", and every added label costs classification accuracy on every run. Revisit
with phase-06 evidence. You flagged `preexisting` as the minimum concrete gap and I agree
that is where the line sits.

---

## 11. CR-19 — ACCEPT

```yaml
id: CR-19
response: ACCEPT
severity: P2
```

Your circularity diagram is exactly the defect:

```
choose 600 → constrain output to <600 → observe output fits 600 → call 600 sound
```

One factual note: the string you quote from `spec/05` — *"Adopted from context-budget.yml,
which is sound and needs no revision"* — is no longer present; round 3 already relabelled
the budget table as *"provisional defaults pending Phase 06 evaluation (CR-19)"*. Your
underlying point survives that fix completely, though, and this is the more useful half:
labelling the numbers provisional while the only task that touches them checks *compliance*
means nothing ever calibrates them. Provisional-forever is just asserted-with-a-disclaimer.

So the substantive gap was in `phase-03`, not `spec/05`. Added **T-03.8**: record
distributions (p50/p90/p95) per instrumented field with acceptance rate, retries, and
quality-failure reason; compare acceptance and total cost across threshold-crossing versus
threshold-respecting runs; then confirm or revise each target with the revision recorded.

One addition your version needs to be executable: **threshold-crossing runs must exist.**
T-03.5 enforces offload thresholds in the implementation, so if every fixture respects every
target the distribution has no data above the line and the comparison is impossible. Some
fixtures must run relaxed. Verification item 5 asserts this, and item 6 asserts no target is
reported as validated on compliance alone.

Also labelled the T-03.5/§05 §G offload thresholds provisional — they had escaped the round-3
relabelling that covered the budget table, so they were still reading as settled.

---

## 12. CR-20 — ACCEPT

```yaml
id: CR-20
response: ACCEPT
severity: P2
```

Confirmed the contradiction: `spec/05 §D` already said *"'exhaust level N before descending'
is not the rule"* while `spec/07` still said *"Levels are gates, not preferences. An agent
MUST NOT reach level 4 without having tried levels 1–3"* and repeated it in its contract
summary. `spec/07` was the stale one — a CR-20 patch that landed in one file and not its pair.

All three of your arguments accepted. The third is the one that decides it for me:
**"exhausted" has no falsifiable definition.** A gate satisfiable by asserting "I exhausted
local sources" is not a gate, it is a prompt for a sentence — and it is untestable, so no
validation level can check it. That makes it strictly worse than a documented preference,
which is at least honest about being one.

Replaced with default priority + bounded escalation + named permitted skips. The bound is
`N = 3` *targeted* retrievals — a query with a named subject, so broad re-greps of the same
corpus do not count as new attempts — labelled a v0 starting value calibrated by T-03.8,
which is the same discipline CR-19 just imposed on the budget numbers.

The design change that makes this checkable: a skip must **name its permitted reason in the
result**. "Exhaustion" was unverifiable; "level 3 skipped, reason: question concerns a
guaranteed public contract, not observed implementation" is a string a fixture can assert on.
An undisclosed skip is a contract violation. Your source-fitness table is adopted nearly
verbatim.

The failure this ordering exists to prevent — a web search for what the type definition next
to the callsite already answered — is unchanged and still guarded by the default order.

---

## 13. What changed, by file

| File | Findings |
|---|---|
| `spec/04-workflow-sizing.md` | CR-02, CR-29 |
| `spec/08-isolation-and-concurrency.md` | CR-32 (§D-1.1/§D-1.2), CR-31 (§E-9) |
| `spec/10-verification-and-review.md` | CR-35 (§A-1 new), CR-36 |
| `spec/07-retrieval-and-code-understanding.md` | CR-20 (§B-1 new) |
| `spec/05-context-and-token-model.md` | CR-19 (offload thresholds) |
| `spec/12-installation-and-rollback.md` | CR-34 (§C-1) |
| `spec/09-model-routing.md`, `spec/03-agent-topology.md` | CR-34 |
| `spec/13-validation-and-evaluation.md` | CR-35, CR-36, CR-32 fixture rewrite |
| `spec/README.md` | CR-37 (PR-1…PR-8), CR-23, CR-34 |
| `phases/phase-07-stabilization.md` | CR-21, CR-23, CR-37, CR-35/CR-32 limitations |
| `phases/phase-04-quality-system.md` | CR-35 (+T-04.8), CR-36 |
| `phases/phase-03-context-efficiency.md` | CR-19 (+T-03.8) |
| `phases/phase-00-foundation.md` | CR-31 (E3-A/E3-H), CR-32 (E3-G), CR-34 (E2) |
| `phases/phase-02-core-orchestration.md` | CR-32 (A1) |
| `phases/phase-05/06` | CR-34 |

---

## 14. Where I think we still disagree, or the record is incomplete

Nothing rises to a stable disagreement this round. Three items where I did less than you
asked, each deliberate and each stated in the spec rather than left implicit:

1. **A2 not adopted despite being reachable (CR-32).** I demonstrated the mechanical
   boundary exists and still shipped the coarser A1. If you think the demonstration
   obligates adoption now rather than after E3-G, that is a real argument and I would rather
   hear it than have it inferred.

2. **Transcript audit not promoted to a contract (CR-35).** Your Option A permits it for
   high-risk runs; I made it available but gated the *claim* on T-04.8. My reasoning is that
   asserting a detection capability I have not measured repeats CR-35 one layer up. If you
   read that as excessive caution given the renderer source already shows tool names and
   arguments, say so.

3. **`test_or_spec` declined for v0 (CR-36).** You called it optional; I want the refusal on
   the record with its reason rather than as an omission.

On your §22: I agree the next step is **Phase 00 experiments**, not implementation. The
blocking set you named — E3-A, E3-G, E3-H — is exactly the set my own exit criteria mark
BLOCKING for phase-02, and after this round three of those cases carry decisions that cannot
be settled by more source reading. E3-A in particular now gates every preflight claim in the
spec: if the workflow's bash tool cannot invoke `omp config get`, CR-31's remedy needs a
different mechanism and I would rather learn that from an experiment than from round 7.

Round-6 patches are at `c6d96817189ec102fed0e4cf4d70e0144123590a`.
