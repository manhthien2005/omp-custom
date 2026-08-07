# Phase 07 — Stabilization

> OPUS PROPOSED SPEC v1 | Governance, upgradeability, and the honest production-ready call.

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

On upstream change: diff watched paths, re-verify affected claims, update the spec and
template where behavior changed, record the new pin and re-verification date. Never
bump a pin without re-verifying the claims that depend on it.

**Acceptance**: the process is documented with an owner and a trigger, not just
aspirational.

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

**Acceptance**: no spec statement contradicts the implementation; every OQ is resolved
or explicitly open.

### T-07.6 — Make the production-ready determination

Evaluate against §14 criteria: all P0/P1 resolved, all four validation levels passing,
benchmark showing measured improvement over baseline, install/rollback round-trip
clean, no unresolved-risk claims.

State the verdict plainly. "Production ready with caveats X and Y" is a legitimate and
more useful outcome than an unqualified claim the evidence does not support.

**Acceptance**: a written determination citing measured evidence per criterion.

### T-07.7 — Record known limitations

Document what the template does not do: no persistent memory, no autolearn, no
always-on advisor, no multi-reviewer, no automatic skill creation, no second
orchestration engine — plus the operational limits (isolation requires git, LSP
requires a setting, no policy loader exists).

**Acceptance**: limitations documented where a user will read them before relying on
absent behavior.

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
4. Confirm every OQ is resolved-with-evidence or explicitly open.
5. Confirm the determination cites measurements, not assertions.

---

## Exit Criteria

- [ ] Upstreams pinned with watched paths mapped to claims
- [ ] Update process documented with owner and trigger
- [ ] Adoption and rejection ledgers complete
- [ ] License position recorded
- [ ] Specs match implementation
- [ ] Every OQ resolved or explicitly open
- [ ] Production-ready determination written from evidence
- [ ] Limitations documented

---

## Risks

| Risk | Mitigation |
|---|---|
| Watched-path list grows unmaintainable | Scope to paths backing a specific claim; drop claims that no longer matter |
| Upstream churn outpaces re-verification | Tier by impact; runtime-authority paths first |
| Determination is "not ready" | That is a valid, useful outcome; state the gaps |
| Ledgers become stale documentation | Tie updates to the phase-06 validation run |
