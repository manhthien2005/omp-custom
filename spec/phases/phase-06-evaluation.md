# Phase 06 — Evaluation

> OPUS PROPOSED SPEC v1 | Replace the benchmark placeholder with real measurement.

**Depends on**: phase-05
**Blocks**: phase-07

---

## Objective

Build the four-level validation stack and a benchmark harness that executes real OMP
sessions, so quality claims rest on measurement rather than on file-existence counts.

---

## Rationale

`validate-template.ps1` reports 63/63 PASS while eight P0 defects are present — it
checks that files exist and are the right length, which is orthogonal to whether the
system works. `benchmark.ps1` executes nothing; it lists fixtures and asks the user to
hand-write result files. Both need replacing before any quality claim is defensible.

---

## Tasks

### T-06.1 — Keep Level 1 static validation, honestly scoped

Retain file-existence, token-budget, and YAML checks — they catch real regressions —
but rename the output so passing no longer implies working. Add the checks that would
have caught phase-01's defects: no `policy:` references, no tool named outside its own
allowlist, no bundled-name collision, every `autoloadSkills` name resolvable, every
dispatch carrying `outputSchema`.

**Acceptance**: Level 1 detects all eight P0 defects when reintroduced. Report wording
states it verifies structure, not behavior.

### T-06.2 — Add Level 2 OMP discovery validation

Assert OMP actually discovers what was installed: agents by name, commands by name,
skills by name, config roles resolving. This is the layer that catches "installed but
invisible."

**Acceptance**: Level 2 confirms five agents, three commands, three skills, and five
resolvable model roles.

### T-06.3 — Add Level 3 workflow fixtures

Execute each workflow against fixtures with known-correct outcomes: a one-line fix for
`/quick`, a two-file change for `/standard`, an independent three-module change for
`/orchestrated`, plus an ambiguous task that must trigger triage rather than a guess,
and a failing-verification task that must not report completion.

**Acceptance**: each fixture asserts a specific observable outcome, including the two
negative cases.

### T-06.4 — Add Level 4 adversarial fixtures

Test the failure modes the design claims to prevent: an Implementer that claims
success falsely (Verifier must contradict), an environment failure (must classify as
`env`), a non-git-repo isolated dispatch (must hit the fallback, not throw), a
schema-violating result (must retry then surface the override), and conflicting
parallel patches (must be detected).

**Acceptance**: all five adversarial cases produce the specified detection.

### T-06.5 — Rewrite the benchmark harness

Replace metadata recording with real execution capturing: workflow, agents spawned,
tool calls, input/output tokens, wall time, accepted outcome, test pass rate, retries,
and rework loops.

**Acceptance**: the harness runs a fixture end to end and emits a populated record
with no manual authoring.

### T-06.6 — Establish the baseline comparison

Measure each fixture with the template and with plain OMP (no template). Without the
baseline there is no evidence the orchestration helps rather than just costing more.

**Acceptance**: recorded results for both arms on identical fixtures.

### T-06.7 — Define the primary metric

Optimize **tokens per accepted outcome**: total tokens across all agents and retries,
divided by outcomes that pass verification and review. Raw token count rewards cheap
wrong answers.

**Acceptance**: the metric is defined, computed by the harness, and reported per arm.

---

## Deliverables

- Level 1 with defect-catching static checks, honestly labeled
- Level 2 discovery validation
- Level 3 workflow fixtures including negative cases
- Level 4 adversarial fixtures
- Executing benchmark harness
- Baseline comparison
- Primary metric implemented

---

## Verification

1. Reintroduce each P0 defect; confirm Level 1 or 2 catches it.
2. Run all Level 3 fixtures; confirm expected outcomes including the two negatives.
3. Run all Level 4 fixtures; confirm each failure mode is detected.
4. Run the benchmark on both arms; confirm records populate automatically.
5. Confirm the metric is computed, not asserted.

---

## Exit Criteria

- [ ] Level 1 catches all eight P0 defects
- [ ] Level 2 confirms OMP discovery
- [ ] Level 3 fixtures pass, including ambiguity and failing-verification cases
- [ ] Level 4 adversarial cases detected
- [ ] Benchmark executes real sessions
- [ ] Baseline measured
- [ ] Tokens per accepted outcome computed for both arms

---

## Risks

| Risk | Mitigation |
|---|---|
| Fixtures are nondeterministic (LLM variance) | Multiple runs; report distribution, not a single number |
| Benchmark costs real tokens | Small fixtures; run deliberately, not on every commit |
| Baseline arm is unflattering | That is the finding; report it honestly |
| Level 3/4 fixtures rot as workflows change | Fixtures assert outcomes, not internal steps |
