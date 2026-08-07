# Phase 06 — Evaluation

> OPUS PROPOSED SPEC v1 | Replace the benchmark placeholder with real measurement.

**Depends on**: phase-05
**Blocks**: phase-07

---

## Objective

Build the L0–L4 validation stack (per the canonical taxonomy in `spec/13-validation-and-evaluation.md §B`) and a benchmark harness that executes real OMP sessions, so quality claims rest on measurement rather than on file-existence counts.

---

## Rationale

`validate-template.ps1` reports 63/63 PASS while eight P0 defects are present — it
checks that files exist and are the right length, which is orthogonal to whether the
system works. `benchmark.ps1` executes nothing; it lists fixtures and asks the user to
hand-write result files. Both need replacing before any quality claim is defensible.

---

## Tasks

**CR-23 — Canonical level taxonomy:** All level references in this file follow the L0–L4 taxonomy defined in `spec/13-validation-and-evaluation.md §B`. Prior drafts of this file used "Level 1–4" for what the canonical taxonomy calls L0–L3; those references are corrected below.

### T-06.1 — Keep L0 (static) validation, honestly scoped

Retain file-existence, token-budget, and YAML checks — they catch real regressions —
but rename the output so passing no longer implies working. Add the checks that would
have caught phase-01's defects: no `policy:` references, no tool named outside its own
allowlist, no bundled-name collision, every `autoloadSkills` name resolvable, every
**worker agent** (`explorer`, `implementer`, `verifier`, `reviewer`) carrying a valid
`output:` frontmatter schema.

**CR-28 correction:** L0 must NOT require "every dispatch carries inline `outputSchema`" — that inverts DR-2. The correct L0 check is: every worker agent has a canonical `output:` frontmatter block (the primary enforcement path per DR-2 and `spec/06`). Caller inline `outputSchema` is an override, not the default — its presence is not required and its absence is not a defect.

**Acceptance**: L0 detects all eight P0 defects when reintroduced. Report wording
states it verifies structure, not behavior.

### T-06.2 — Add L1 (OMP discovery) validation

Assert OMP actually discovers what was installed: agents by name, commands by name,
skills by name, config roles resolving. This is the layer that catches "installed but
invisible."

**CR-33 — the agent count is four, and `tech-lead` must be ABSENT.** The discovered set is
exactly `explorer`, `implementer`, `verifier`, `reviewer`. The Tech Lead is the main session
(DR-1); its role contract lives at `docs/roles/tech-lead.md`, outside every discovery root. A
discovered `tech-lead` agent is a **FAIL** — `loadAgentsFromDir()` parses every `.md` under an
agents directory into an active `AgentDefinition`, so its presence creates a second spawnable
Tech Lead path.

**CR-31 — L1 also asserts effective isolation settings**, because a discovered-but-misconfigured
install still breaks the Orchestrated path: `task.isolation.mode != "none"` and, in the project
target, `task.isolation.apply == false`. See `13-validation-and-evaluation.md §L1`.

**Acceptance**: L1 confirms **four** agents (no `tech-lead`), three commands, three skills, five
resolvable model roles, and the effective isolation settings above.

### T-06.3 — Add L2 (contract) + L3 (behavioral) workflow fixtures

Execute each workflow against fixtures with known-correct outcomes: a one-line fix for
`/quick`, a two-file change for `/standard`, an independent three-module change for
`/orchestrated`, plus an ambiguous task that must trigger triage rather than a guess,
and a failing-verification task that must not report completion.

**Acceptance**: each fixture asserts a specific observable outcome, including the two
negative cases.

### T-06.4 — Add L4 (adversarial) fixtures

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

**CR-22 — Formal A/B protocol (applies to all comparisons):** Each A/B comparison MUST: (1) isolate exactly one variable; (2) run both arms on identical fixture tasks back-to-back or in the same session window; (3) record results from both arms before interpreting either; (4) report distribution (mean ± std) across ≥3 runs per arm — a single run is not evidence; (5) state the null hypothesis and the threshold used to judge the result. See `spec/13-validation-and-evaluation.md §C` for the full comparison matrix.

**Acceptance**: recorded results for both arms on identical fixtures.

### T-06.7 — Define the primary metric

Optimize **tokens per accepted outcome**: total tokens across all agents and retries,
divided by outcomes that pass verification and review. Raw token count rewards cheap
wrong answers.

**Acceptance**: the metric is defined, computed by the harness, and reported per arm.

---

## Deliverables

- L0 (Static) with defect-catching static checks, honestly labeled
- L1 (Discovery) validation
- L2 (Contract) + L3 (Behavioral) workflow fixtures including negative cases
- L4 (Adversarial/Comparative) fixtures
- Executing benchmark harness
- Baseline comparison
- Primary metric implemented

---

## Verification

1. Reintroduce each P0 defect; confirm L0 or L1 catches it.
2. Run all L3 (Behavioral) fixtures; confirm expected outcomes including the two negatives.
3. Run all L4 (Adversarial) fixtures; confirm each failure mode is detected.
4. Run the benchmark on both arms; confirm records populate automatically.
5. Confirm the metric is computed, not asserted.

---

## Exit Criteria

- [ ] L0 catches all eight P0 defects
- [ ] L1 confirms OMP discovery (5 agents, 3 commands, 3 skills, 5 model roles)
- [ ] L2 (contract) proves schema rejection and retry actually occur
- [ ] L3 (behavioral) fixtures pass, including ambiguity and failing-verification cases
- [ ] L4 adversarial cases detected
- [ ] Benchmark executes real sessions
- [ ] Baseline measured (template vs plain OMP, ≥3 runs per arm)
- [ ] Tokens per accepted outcome computed for both arms

---

## Risks

| Risk | Mitigation |
|---|---|
| Fixtures are nondeterministic (LLM variance) | Multiple runs; report distribution, not a single number |
| Benchmark costs real tokens | Small fixtures; run deliberately, not on every commit |
| Baseline arm is unflattering | That is the finding; report it honestly |
| L3/L4 fixtures rot as workflows change | Fixtures assert outcomes, not internal steps |
