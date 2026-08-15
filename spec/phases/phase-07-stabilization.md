# Phase 07 — Stabilization

<!-- round09-12-projection:release -->
## Round 09–12 release-readiness supersession

Release status is derived from focused/full validators, bounded evidence hashes, and scratch
package proof. Unless a separately authorized final campaign clears spec 13, OMP remains
`IMPLEMENTED_NOT_PROMOTED`; Claude remains `DESIGNED_NOT_VERIFIED / installable false`. OMP
17.2.10, Claude runtime, and model-assisted arms stay named limitations. Local implementation
does not imply live install, Git staging/commit, remote mutation, or mandatory Opus review.

<!-- topic06-projection:phase-07 -->
## Topic 06 stabilization consumer

Release only with reproducible current-product evidence, manifest hashes, focused/full validator
passes, transactional uninstall coverage, and the managed launcher documented as the supported
entry point. Keep changes local and unstaged unless the user separately requests Git. Preserve
`OPEN-T06-RUNTIME-01` as a scoped upstream enhancement, not a release blocker.

## Topic 04 consumer projection

Topic 04 consumes release limitation and migration reconciliation. Phase 07 keeps same-machine and
repository-metadata-loss limits explicit, verifies schema/root migration and rollback retention,
and reports the Topic 08 automatic-adapter gate without claiming an unprobed hook.

> OPUS PROPOSED SPEC v1 | Governance, upgradeability, and the honest production-ready call.
>
> **KD-027 stabilization scope:** promote only after the exact three-agent manifest, Scout
> Flash→Pro route, Worker high/xhigh selection, Reviewer xhigh/risk gate, stale-agent retirement,
> and current-product evidence boundary pass. `ENVIRONMENT_BLOCKED` DeepSeek credentials are
> reported honestly and retain Tech Lead retrieval fallback; Opus absence is not a blocker.

**Depends on**: phase-06
**Blocks**: nothing (terminal phase)

---

## Objective

Make the template maintainable against a moving upstream, complete the governance
registries, and decide — on evidence — whether it is production ready.

---

## Rationale

Every runtime claim in this spec is verified against one OMP commit. OMP will change.
Without a defined detection-and-response process, the template silently drifts from
truth: the failure mode is not a crash but slow divergence, where documentation
describes behavior that no longer exists.

---

## Tasks

### T-07.1 — Complete the upstream registry

For `oh-my-pi` (tier: runtime-authority) record the pinned commit, the watched paths
from §14-C, and which claim each path supports. For pattern-source upstreams record
the pin and that only ideas — never code — are adopted, with license terms.

**Acceptance**: every upstream has a pin, a tier, and license terms; every watched
path maps to a specific claim.

### T-07.2 — Define the update process

**CR-21 — the process is full-commit-range discovery, not watched-path diffing.** An
earlier revision of this task said "diff watched paths, re-verify affected claims." That
is the exact process `14-upgradeability-and-governance.md` rejected, and restating it here
would reintroduce the blind spot: a watched-path diff can only find changes in paths we
already knew to watch, so any behavior change *outside* the current watch list is
invisible by construction — including the changes most likely to break an assumption we
never wrote down. Because this is the terminal phase, an implementer following it would
ship the weaker process.

The normative process is defined in `14-upgradeability-and-governance.md §D`
(*Controlled Update Process*), whose step 2 and CR-21 note already carry full-range
discovery; `§C` defines the watched-path contract those steps triage against. Do not
restate a summary here; reference them. The required sequence:

```
1. Diff the FULL upstream commit range (old pin → new pin) — not a path subset
2. Triage: watched-path changes first (highest prior probability of claim impact)
3. Scan non-watched changes for transitive impact — call-chain reachability into
   any primitive a claim depends on, renames/moves that relocate a watched symbol,
   and default-value changes in settings the template reads
4. Map each candidate change to the specific claim(s) it could invalidate
5. Re-run the affected source checks AND the behavioral suite (L3) for those claims
6. Record the new pin, the re-verification date, and any claim whose status changed
```

Step 3 is the load-bearing addition. Steps 2 and 3 together mean watched paths are
**triage anchors that set inspection order**, never the boundary of what gets inspected.
A new watched path discovered in step 3 is itself an output: add it to the registry.

**Acceptance**: the documented process performs full-range discovery with watched-path
prioritization and an explicit non-watched transitive-impact scan; it names an owner and a
trigger; it references `spec/14 §D` (with `§C` for the watched-path contract) rather than paraphrasing them. A watched-path-only
process fails this task.

### T-07.3 — Complete the adoption ledger

Each adopted mechanism: source, what was adopted (pattern vs code), which OMP
primitive implements it, verification evidence, and adoption date. Each rejected
mechanism: why, so it is not relitigated.

**Acceptance**: every mechanism in the template appears in one ledger or the other.

### T-07.4 — Record the license position

Pattern adoption is not code adoption, but the distinction must be recorded per
upstream with its license, and any verbatim code must be attributed.

**Acceptance**: `registry/licenses.yml` covers every upstream; `LICENSES.md` matches.

### T-07.5 — Reconcile the specs with reality

After phases 00–06, the specs will have drifted from the implementation. Reconcile
them, and mark each open question resolved with evidence or explicitly still open.

**`explicitly_open` is a legal state for THIS task and NOT for T-07.6 (CR-37).**
Reconciliation is a documentation-accuracy pass: its job is to ensure no OQ is silently
unresolved. Production readiness is a different, stricter gate — see T-07.6 and PR-2.
An OQ left open here does not fail reconciliation; it fails release.

**Acceptance**: no spec statement contradicts the implementation; every OQ carries an
explicit status of `resolved_with_recorded_evidence` or `explicitly_open` — no OQ is
undeclared. Every `explicitly_open` OQ names what experiment would close it.

### T-07.6 — Make the production-ready determination

**Evaluate the canonical gates by ID; do not paraphrase them (CR-23, CR-37).** This task
previously restated the release criteria in prose, and the copy drifted from its source in
two ways at once: it said "all four validation levels" when the canonical taxonomy has
five (L0–L4, `13-validation-and-evaluation.md`), and it dropped the OQ-closure requirement
that `README.md §14` item 2 makes mandatory. Both drifts made the gate *weaker* than the
definition it claimed to implement. The fix is structural: the gates live in one place and
this task references them.

Canonical source: `README.md §14` (Definition of Production Ready), with
`13-validation-and-evaluation.md` for the validation taxonomy and
`14-upgradeability-and-governance.md` for governance. Enumerated as stable IDs:

| ID | Gate | Canonical source |
|---|---|---|
| PR-1 | All P0/P1 findings resolved, or explicitly waived with recorded rationale | README §14.1 |
| PR-2 | **OQ-1…OQ-5 each resolved by recorded experiment**, not inference | README §14.2 |
| PR-3 | All three workflows execute end-to-end with no silent no-ops | README §14.3 |
| PR-4 | Malformed worker result is demonstrably rejected and retried | README §14.4 |
| PR-5 | Installer: dry-run, diff, backup, manifest, rollback, idempotent re-run, config merged not clobbered | README §14.5 |
| PR-6 | Validation tiers report independently; no aggregate score conceals a tier failure | README §14.6 |
| PR-7 | Evaluate the canonical L4 comparative contract by ID; do not restate its dual-baseline or promotion thresholds locally | README §14.7, spec/13 §C |
| PR-8 | Every remaining abstraction has a named runtime consumer, or is documented as non-runtime | README §14.8 |

Note the L-level split in PR-7: L0–L3 are pass/fail operational gates; **L4 is a
comparative benchmark, not a pass/fail level** — it is met by clearing a threshold, which
is why "all N levels passing" was the wrong shape regardless of whether N was four or
five.

**PR-2 is a hard gate (CR-37).** A required OQ in state `explicitly_open` forces
`verdict: NOT_READY`. This is the one place where T-07.5's tolerance does not carry over:

```yaml
T_07_5_reconciliation:
  allowed_oq_states: [resolved_with_recorded_evidence, explicitly_open]

T_07_6_production_ready:
  requires:
    all_required_OQs: resolved_with_recorded_evidence
  on_any_explicitly_open_required_OQ:
    verdict: NOT_READY
```

Every current OQ (OQ-1…OQ-5) is High or Medium impact and each gates a runtime behavior
the architecture depends on — schema enforcement through the gateway, isolation on the
target filesystem, `autoloadSkills` cost, project-level `modelRoles` resolution. "Production
ready with caveats" remains a legitimate verdict for **documented limitations** (T-07.7)
and for waived P1s under PR-1, but it **cannot** waive an unresolved required OQ: that
would ship a release whose central claims rest on inference, which is the specific failure
mode README §14.2 exists to prevent. Changing that requires editing README §14 first —
deliberately, in one place — not silently relaxing it here.

State the verdict plainly. Naming the gaps is more useful than an unqualified claim the
evidence does not support.

**Acceptance**: a written determination that evaluates **PR-1…PR-8 by ID**, citing measured
evidence per gate; no gate restated in prose that diverges from its canonical source; any
`explicitly_open` required OQ yields `NOT_READY`.

### T-07.7 — Record known limitations

Document what the template does not do: no persistent memory, no autolearn, no
always-on advisor, no multi-reviewer, no automatic skill creation, no second
orchestration engine — plus the operational limits (isolation requires git, LSP
requires a setting, no policy loader exists).

**Two limitations added in round 6 must appear here**, because both are places a user could
reasonably assume a stronger guarantee than exists:

- **Verification evidence is not execution-attested (CR-35).** The `verification-result`
  schema enforces that an evidence claim is present, complete, and internally consistent. It
  does **not** prove the claimed commands ran — OMP's yield validation is generic JSON Schema
  validation with no access to the child's tool-call events. False-completion resistance in
  v0 comes from session independence plus prompt discipline, not attestation. State this in
  the same place the "no false completion" claim appears, or the claim reads stronger than it
  is. See `10-verification-and-review.md §A-1`.
- **Repositories containing nested git repos or submodules do not get parallel implementation
  (CR-32).** `/orchestrated` detects them in preflight and routes the whole run to sequential
  non-isolated implementation, because OMP v17.2.10 silently discards nested-repo changes on
  the capture-only path. This is a capability limit a user will notice as "parallelism did not
  engage", so the reason must be documented and the run must disclose it.

**Acceptance**: limitations documented where a user will read them before relying on
absent behavior; the CR-35 provenance boundary and the CR-32 nested-repo restriction are both
present, each stating what the user should do instead.

---

## Deliverables

- Complete upstream registry with pins, tiers, watched paths
- Documented update process with owner and trigger
- Adoption and rejection ledgers
- License position per upstream
- Specs reconciled with implementation
- Written production-ready determination
- Documented limitations

---

## Verification

1. Confirm every watched path resolves in the pinned clone.
2. Confirm every template mechanism appears in a ledger.
3. Confirm every spec claim matches the implementation.
4. Confirm every OQ carries an explicit status (T-07.5), and separately that every
   **required** OQ is `resolved_with_recorded_evidence` before any READY verdict (PR-2).
5. Confirm the determination cites measurements, not assertions, and evaluates PR-1…PR-8
   **by ID** — no paraphrased gate.
6. **Drift check (CR-23/CR-37):** grep this file and every phase file for restated release
   criteria. Any prose copy of a canonical gate is a defect even when currently accurate,
   because it is a future divergence site. Specifically confirm no file asserts a
   validation-level count ("all four/five levels") in place of the L0–L3 + L4-threshold
   split, and no file permits a READY verdict with an open required OQ.
7. **Governance-process check (CR-21):** confirm no file describes upstream change
   detection as watched-path diffing. The process is full-range discovery with watched-path
   triage (`spec/14 §D`).

---

## Exit Criteria

- [ ] Upstreams pinned with watched paths mapped to claims
- [ ] Update process documented with owner and trigger, **full-range discovery** with
      watched-path triage, referencing `spec/14 §D` (CR-21)
- [ ] Adoption and rejection ledgers complete
- [ ] License position recorded
- [ ] Specs match implementation
- [ ] Every OQ carries an explicit status (reconciliation state — T-07.5)
- [ ] **Every required OQ is `resolved_with_recorded_evidence`** before a READY verdict;
      an open required OQ forces NOT READY (CR-37, PR-2)
- [ ] Production-ready determination written from evidence, evaluating **PR-1…PR-8 by ID**
      with no paraphrased gate (CR-23/CR-37)
- [ ] No file states a validation-level *count*; L0–L3 operational + L4 threshold (CR-23)
- [ ] Limitations documented

---

## Risks

| Risk | Mitigation |
|---|---|
| Watched-path list grows unmaintainable | Scope to paths backing a specific claim; drop claims that no longer matter |
| Upstream churn outpaces re-verification | Tier by impact; runtime-authority paths first |
| Determination is "not ready" | That is a valid, useful outcome; state the gaps |
| Ledgers become stale documentation | Tie updates to the phase-06 validation run |
