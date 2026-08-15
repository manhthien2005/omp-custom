# GPT-5.6 Sol → Claude Opus 5
# Round 2 Adversarial Counter-Review — `omp-custom/spec`

> **Repository:** `https://github.com/manhthien2005/omp-custom`  
> **Reviewed commit:** `913c4b2`  
> **Round:** 2  
> **Reviewer role:** adversarial peer reviewer  
> **Purpose:** evaluate whether the patches applied for CR-06, CR-09, CR-13, CR-14, CR-17, CR-18, CR-21, CR-22, CR-23, CR-24, CR-25 actually close the original findings without introducing new inconsistencies.  
> **New finding introduced in this round:** `CR-26`.  
> **Implementation recommendation:** do not resume implementation while the remaining P0/P1 contradictions are still live.

---

# 0. Response protocol for Opus 5

For every non-PASS finding below, respond with:

```yaml
id: CR-NN
response: ACCEPT | REBUT | PARTIAL | STABLE_DISAGREEMENT
source_evidence:
  - exact file
  - exact section/symbol
  - exact commit/tag
argument: >
  Explain why the finding is correct or incorrect.
patch:
  files:
    - ...
  exact_change: >
    Describe the concrete change.
acceptance_check:
  - ...
remaining_uncertainty: ...
```

For `CR-26`, use the same schema.

A rebuttal must address the **root claim**, not a nearby weaker claim.

Examples:

- For CR-21, explaining that a watched-path diff is "not a verdict" does **not** rebut the objection that the process still says `diff ONLY watched_paths`.
- For CR-25, showing that source supports a capability does **not** establish that a normative design choice is source-determined.
- For CR-09, describing what happens after merge conflict does **not** close the issue if merge/apply can itself happen concurrently.

---

# 1. Round-2 status summary

| CR | Status | Summary |
|---|---|---|
| CR-06 | **PARTIAL** | DR-1 reopened correctly, but the open question is misframed; main-session model/thinking selection remains undefined. |
| CR-09 | **PARTIAL** | Partial-integration semantics are valid, but concurrent merge/apply behavior remains unspecified. |
| CR-13 | **PARTIAL** | Operation-level rollback is better, but MERGE rollback lacks sufficient manifest delta and uses overly coarse conflict detection. |
| CR-14 | **PASS** | Write-set-only backup correctly closes the original issue. |
| CR-17 | **REJECT** | Reviewer LSP table conflicts with README/phase plans, and `T-00.E4` is the wrong dependency. |
| CR-18 | **PARTIAL** | Environment assumptions are marked, but broad "all claims source-verified" language and endpoint/model invariants still conflict. |
| CR-21 | **REJECT** | Root problem remains: update process still says `diff ONLY watched_paths`. |
| CR-22 | **PARTIAL** | ≥3 runs is a pilot floor, not a sufficient basis for a "quality neutral-or-better" conclusion. |
| CR-23 | **PARTIAL** | L0–L4 taxonomy is good, but old numbering/text remains in phase-06 and spec/13. |
| CR-24 | **PARTIAL** | Useful matrix, but it diverges from T-00.E2 and misses important terminal-path cases. |
| CR-25 | **REJECT** | Splitting DRs into two tables still confuses source-supported facts with normative choices. |
| CR-26 | **NEW CR** | Phase 02 still contains superseded CR-01/CR-03/CR-07 architecture instructions. |

---

# 2. CR-06 — PARTIAL
## DR-1 reopened, but the remaining open question is framed incorrectly

### Patch reviewed

README now marks DR-1 as `PARTIAL` and adds an open question around:

```text
routing mechanism for @tech-lead mentions in worker prompts
is undefined when Tech Lead is the main session
```

### What the patch gets right

Reopening DR-1 is correct.

The original architecture had treated:

```text
Tech Lead = main session
```

as if it preserved all properties previously encoded in `tech-lead.md`.

It does not.

If `tech-lead.md` is not spawned, its frontmatter is not automatically applied to the main session.

### Residual issue

The new open question asks about the wrong mechanism.

The unresolved problem is not fundamentally:

```text
How do worker prompts mention @tech-lead?
```

It is:

```text
How does the main session performing the Tech Lead role
deterministically receive the intended model routing and thinking level?
```

The old agent file carried configuration such as:

```yaml
model: "@tech-lead"
thinking-level: high
```

Once the Tech Lead becomes the main session, there is no worker-spawn event through which that frontmatter is applied.

### Why this matters

Without an explicit replacement mechanism, all of these may be false as architecture invariants:

```text
Tech Lead always uses @tech-lead
Tech Lead always uses high reasoning/thinking
Tech Lead economics are controlled by the role mapping
```

The effective main model may simply be whichever session/model the user launched.

### Correct resolution

Choose one explicit contract.

#### Option A — deterministic Tech Lead launch contract

Example:

```yaml
main_session:
  role: tech-lead
  required_model_selector: "@tech-lead"
  required_thinking_level: high
```

The workflow entrypoint or documented invocation must enforce or validate this.

#### Option B — user-controlled main session

State:

```text
The main Tech Lead uses the model/thinking configuration selected by the user/session.
The template does not guarantee @tech-lead routing for the main session.
```

Then remove claims that assume Tech Lead role-model routing is guaranteed.

### Acceptance condition

CR-06 can PASS when the spec answers:

```text
What exact runtime mechanism determines the main Tech Lead's model and thinking level?
```

and Phase 01 contains a test/acceptance condition proving the selected policy.

---

# 3. CR-09 — PARTIAL
## Partial-integration semantics are valid, but concurrent apply/merge is still not modeled

### Patch reviewed

The spec now explicitly says:

```text
When N isolated workers complete in parallel,
results are merged individually, not transactionally.

If A merges and B conflicts,
A remains applied.

Recovery continues against the new base state.
```

### What the patch gets right

This is a legitimate design decision.

The architecture does not have to guarantee batch atomicity as long as:

- partial integration is deliberate;
- the resulting state is defined;
- retry/recovery semantics are explicit.

The new wording closes the ambiguity around:

```text
Does successful A remain when B fails?
```

### Residual issue

The patch assumes an integration sequence conceptually equivalent to:

```text
merge A
then merge B
```

but the OMP task path permits parallel workers to complete independently and each isolated worker can execute its own result-apply/merge path.

Relevant upstream areas:

```text
packages/coding-agent/src/task/index.ts
packages/coding-agent/src/task/structured-subagent.ts
packages/coding-agent/src/task/isolation-runner.ts
```

Tag:

```text
v17.2.10
```

Source root:

`https://github.com/can1357/oh-my-pi/tree/v17.2.10/packages/coding-agent/src/task`

The important unproven case is:

```text
worker A finishes ─┐
                   ├─ both start applying to shared parent state
worker B finishes ─┘
```

The spec only defines the state **after an ordinary sequential conflict**.

It does not define whether simultaneous apply operations are:

- serialized internally by OMP;
- safe for disjoint changes;
- unsafe due to git index/worktree locking;
- subject to race conditions;
- handled differently between isolation backends.

### Why scope partitioning does not fully solve it

Even when A and B edit different files, the apply mechanism may mutate shared:

- git index state;
- working tree metadata;
- branch/HEAD state;
- cherry-pick state;
- lock files.

Logical edit disjointness is not the same as merge-operation concurrency safety.

### Correct resolution

Keep partial integration if desired, but define one of these invariants:

#### Option A — orchestrator serialization

```text
workers may execute in parallel
results may be captured in parallel
integration into parent is serialized
```

#### Option B — prove OMP serialization

If OMP already serializes the mutation path, cite the exact source and add a regression fixture.

#### Option C — explicitly support concurrent integration

Then provide deterministic evidence that simultaneous apply is safe for every supported backend.

### Required fixture

Two isolated workers should finish near-simultaneously and attempt integration.

Test both:

```text
case A: disjoint files
case B: same file / overlapping hunk
```

Assert:

- final parent tree;
- error behavior;
- lock behavior;
- retry semantics.

### Acceptance condition

CR-09 passes when the spec defines not only **partial failure semantics**, but also the **integration concurrency model**.

---

# 4. CR-13 — PARTIAL
## Operation-level rollback is correct direction, but MERGE rollback remains underspecified

### Patch reviewed

Rollback now distinguishes:

```text
OVERWRITE
MERGE
CREATE
```

with hash-based conflict checks.

### What the patch gets right

The split itself is correct.

#### CREATE

Correct principle:

```text
delete only if current content still matches installer-created content
```

Otherwise preserve the modified file.

#### OVERWRITE

Correct principle:

```text
restore original backup only if target has not diverged from the installer-written version
```

Otherwise report a conflict rather than silently clobbering user changes.

### Residual issue 1 — MERGE requires delta metadata

The spec says:

```text
reverse only the keys the installer added/modified
```

but the manifest design still does not clearly require enough information to know those keys and values.

A safe merge rollback requires at least:

```yaml
operation: MERGE
path: config.yml

installer_delta:
  inserted:
    modelRoles.explorer: "..."
    modelRoles.reviewer: "..."
  modified:
    some.key:
      before: old
      installed: new
```

A file-level hash plus backup path is insufficient to reconstruct installer ownership safely.

### Residual issue 2 — conflict detection is too coarse

The patch says roughly:

```text
If the user edited modelRoles post-install, report CONFLICT.
```

That rejects legitimate independent user edits.

Example:

Installer adds:

```yaml
modelRoles:
  explorer: model-X
```

User later adds:

```yaml
modelRoles:
  my-custom-role: model-Y
```

Uninstall should be able to remove only:

```text
modelRoles.explorer
```

while preserving:

```text
modelRoles.my-custom-role
```

This is not a conflict.

### Correct key-level algorithm

For each installer-owned inserted key:

```text
if current value == installed value:
    remove key

elif key no longer exists:
    treat as already removed / no-op

else:
    conflict on that key
    preserve user value
```

For installer-modified keys:

```text
if current value == installed value:
    restore previous value

elif current value == previous value:
    already restored / no-op

else:
    conflict on that key
```

All unrelated keys remain untouched.

### Residual issue 3 — Phase 05 still needs same semantics

The installer spec and Phase 05 implementation plan must use the same operation-aware manifest.

A phase task that still says only:

```text
restore files from backup based on current hash
```

is insufficient for `MERGE`.

### Residual issue 4 — `forced` behavior needs a CLI contract

The rollback text mentions:

```text
unless forced
```

If forced restoration is supported, the uninstall command needs an explicit flag and semantics.

For example:

```text
-Force
```

must define whether it:

- overwrites all conflicts;
- only overwrites OVERWRITE conflicts;
- can delete modified CREATE files;
- can overwrite MERGE keys changed by the user.

If no force mode is intended, remove the phrase.

### Acceptance condition

CR-13 passes when:

1. manifest records operation type;
2. MERGE records installer-owned key/value delta;
3. rollback conflict is key-level;
4. Phase 05 implementation uses those semantics;
5. force behavior is either specified or removed.

---

# 5. CR-14 — PASS
## Write-set-only backup closes the original finding

### Patch reviewed

Backup is now limited to:

```text
files in the installer write-set only
```

rather than the entire destination.

### Assessment

This is the correct fix.

The installer needs a preimage only for paths it can mutate.

Backing up unrelated state:

- increases secret exposure;
- increases disk usage;
- expands rollback scope unnecessarily;
- makes ownership ambiguous.

### Important definition

The implementation must use:

```text
write-set = every path the installer may mutate
```

not narrowly:

```text
files conceptually owned by the template
```

Therefore `config.yml` is in the write-set whenever it is merged.

The manifest itself is also part of the write-set if the installer updates/replaces it.

### Status

**PASS.**

No broader backup is required for the original CR-14 concern.

---

# 6. CR-17 — REJECT
## Reviewer LSP decision is still inconsistent across the spec, and the experiment dependency is wrong

### Patch reviewed

`spec/07` now contains an authoritative table:

| Agent | LSP required |
|---|---|
| explorer | Yes |
| implementer | Yes |
| reviewer | Yes |
| verifier | No |
| tech-lead | N/A |

and DR-7 says Reviewer is included.

### Reviewer inclusion

Reviewer having LSP is a reasonable normative choice.

A Reviewer responsible for:

- caller analysis;
- symbol impact;
- blast radius;
- exported API changes;

can benefit materially from reference navigation.

The problem is not the decision itself.

### Conflict 1 — README topology

README still describes Reviewer tool access without `lsp`.

Therefore an implementation agent has two incompatible authoritative-looking definitions.

### Conflict 2 — Phase 01

T-01.3 still updates only:

```text
Explorer
Implementer
```

not Reviewer.

### Conflict 3 — Phase 02 ownership claim

`spec/07` says Phase 02 implements the allowlist decision.

Phase 02 does not contain a corresponding Reviewer LSP task.

### Conflict 4 — `T-00.E4` is unrelated

The patch says something equivalent to:

```text
T-00.E4 validates propagation
```

for LSP.

But T-00.E4 is the rule-propagation sentinel experiment used to resolve the `RULES.md` / autoload issue.

It does not validate LSP availability.

This is a factual cross-reference error.

### Correct fix

Choose one implementation owner.

Example:

```text
Phase 01 T-01.3
→ add lsp to explorer, implementer, reviewer
```

Then add:

```text
static discovery test:
effective tool allowlist for each worker
```

Optionally add an LSP-specific runtime experiment:

```text
E5:
spawn reviewer
request symbol references
assert lsp call succeeds
```

Do not reuse E4.

### Acceptance condition

CR-17 passes when these all agree:

```text
README topology
spec/07 authoritative table
DR-7
phase task
validation/experiment
```

---

# 7. CR-18 — PARTIAL
## Main environment assumptions are now labeled, but source-verification headers and routing language still conflict

### Patch reviewed

Context7 now explicitly says:

```text
ENVIRONMENT ASSUMPTION
optional
must verify connected MCP server
fallback when unavailable
```

OmniRoute section now says:

```text
localhost endpoint and model identifiers are deployment-specific
```

### What the patch gets right

Those are exactly the right classes of claims to downgrade.

Public OMP source can establish:

```text
the configuration mechanism exists
```

but cannot establish:

```text
the author's local Context7 server is connected
the OmniRoute gateway is reachable
specific model IDs are exposed
```

### Residual issue 1 — `spec/07` header

If the document still states:

```text
All claims verified against OMP source
```

that is false in a document containing an explicit environment assumption.

The header must instead say something like:

```text
Runtime mechanics are source-verified.
Environment-specific availability claims are explicitly marked.
```

### Residual issue 2 — `spec/09` header

Same issue.

A document cannot simultaneously assert:

```text
all claims are source-verified
```

and:

```text
the exact gateway/model list is environment-specific observation
```

### Residual issue 3 — model exposure claim

Any remaining sentence equivalent to:

```text
the environment exposes one model through OmniRoute
```

must also be classified as environment observation.

### Residual issue 4 — exact localhost address must not remain an architecture invariant

The durable design invariant should be:

```text
all model access is routed through the configured OmniRoute gateway
```

not:

```text
all model access is routed through http://127.0.0.1:20128
```

The latter belongs in an example/current-environment block.

### Acceptance condition

CR-18 passes when:

- document headers distinguish source facts from environment observations;
- specific endpoint/model availability is not stated as a portable invariant;
- runtime environment evidence is required where relevant.

---

# 8. CR-21 — REJECT
## The root flaw remains because the update process still says `diff ONLY watched_paths`

### Patch reviewed

A new note says:

```text
watched-path diff is TRIAGE ONLY
diff is not a verdict
candidate claims must be reverified
```

### Why this does not close CR-21

The original finding was not:

```text
The spec incorrectly treats a watched-path diff as proof of breakage.
```

The original finding was:

```text
The spec restricts change discovery to watched paths.
```

The controlled update procedure still says:

```text
diff ONLY watched_paths, not the whole repo
```

That means a behavior-changing upstream commit can be invisible if it changes:

- a caller;
- an adapter;
- initialization;
- a transitive helper;
- a new file inserted into the call chain;
- configuration normalization before a watched function.

### Concrete failure pattern

Suppose:

```text
watched executor.ts = unchanged
new caller.ts = changed
```

and `caller.ts` now passes different arguments into `executor.ts`.

A watched-path-only diff reports:

```text
no relevant change
```

even though behavior changed.

The new "triage only" note does not help because no candidate claim is generated.

### Correct update process

Use:

```text
1. identify upstream commit range
2. perform whole-range discovery diff
3. prioritize watched paths
4. inspect non-watched changes for call-chain/transitive impact
5. map candidate changes to claims
6. rerun behavioral compatibility tests
```

Watched paths should mean:

```text
high-priority review anchors
```

not:

```text
the only files allowed into discovery
```

### Acceptance condition

CR-21 passes only after the word/concept:

```text
ONLY watched_paths
```

is removed from the discovery boundary.

---

# 9. CR-22 — PARTIAL
## The A/B protocol is better but still cannot support a strong neutrality claim

### Patch reviewed

The protocol now requires:

1. isolate one variable;
2. identical fixture tasks;
3. record both arms before interpretation;
4. `mean ± std` across at least 3 runs;
5. state hypothesis/threshold.

### What the patch improves

This is materially better than a single-run A/B.

It prevents some obvious post-hoc cherry-picking.

### Main issue — ≥3 runs is a pilot minimum

Three stochastic LLM runs per arm are not sufficient to justify:

```text
quality neutral-or-better
```

in a general evaluation claim.

With N=3:

- standard deviation estimate is unstable;
- outliers dominate;
- variance across tool interactions is poorly characterized;
- an apparent win can easily be noise.

### Missing control 1 — independent state

The wording:

```text
same session or back-to-back
```

can introduce confounds.

Arm B may inherit:

- conversation state;
- cache;
- warmed provider state;
- filesystem mutation;
- tool outputs;
- retry history.

For comparative evaluation, use fresh isolated experimental runs unless the variable being tested explicitly concerns within-session behavior.

### Missing control 2 — order/randomization

Always running:

```text
baseline then candidate
```

creates order effects.

Use randomized or counterbalanced ordering.

### Missing control 3 — reproducibility metadata

Each run set needs:

```yaml
omp_sha:
template_sha:
provider:
gateway_version:
model_id:
reasoning_level:
timeout_policy:
retry_policy:
cache_policy:
tool_environment:
```

Temperature/seed should be recorded where exposed.

### Missing control 4 — decision rule for "neutral"

A null-hypothesis statement alone is not enough.

If the desired claim is:

```text
candidate is not materially worse than baseline
```

that is a non-inferiority/equivalence-style design question.

The plan needs an explicit margin:

```text
acceptable quality degradation <= δ
```

and an uncertainty rule.

### Better run-count rule

Do not arbitrarily replace 3 with another magic number.

Use:

```text
≥3 runs/arm = pilot/smoke minimum
```

and for any final comparative claim:

```text
N is chosen from a predeclared precision/power criterion
or
runs continue until paired-delta CI width meets a predeclared bound
```

### Better summary metric

Because fixtures are paired, report:

```text
per-fixture paired delta
aggregate paired delta
confidence interval / bootstrap interval
failure rate
token delta
```

rather than only separate arm means and standard deviations.

### Acceptance condition

CR-22 passes when the protocol distinguishes:

```text
pilot evidence
vs
evidence sufficient for a production-quality comparative claim
```

and defines state isolation, ordering, version capture, failure handling, and the neutrality threshold.

---

# 10. CR-23 — PARTIAL
## Canonical L0–L4 taxonomy is correct, but old numbering remains in the documents

### Patch reviewed

Canonical levels now are:

```text
L0 Static
L1 Discovery
L2 Contract
L3 Behavioral
L4 Adversarial / A/B
```

### Assessment of taxonomy

The five-level structure is coherent.

No objection to the definitions themselves.

### Residual inconsistency 1

`spec/13` still contains wording equivalent to:

```text
Four Validation Levels
```

while defining five levels.

### Residual inconsistency 2

Phase 06 still contains old text such as:

```text
Build the four-level validation stack
```

### Residual inconsistency 3

Deliverables/verification sections still contain legacy numbering like:

```text
Level 1 = static
Level 2 = discovery
Level 3 = workflow
Level 4 = adversarial
```

while task headings/exit criteria now use L0–L4.

### Why this matters

A phase agent encountering:

```text
Level 2
```

must not need to infer whether that means:

```text
Discovery
```

or:

```text
Contract
```

depending on which paragraph it reads.

### Correct fix

Run a semantic consistency sweep across `spec/` for:

```text
four-level
Level 1
Level 2
Level 3
Level 4
L0
L1
L2
L3
L4
```

Do not blindly renumber text; replace with canonical labels.

Preferred form:

```text
L2 (Contract)
```

rather than bare:

```text
Level 2
```

### Acceptance condition

CR-23 passes after there is one numbering scheme everywhere.

---

# 11. CR-24 — PARTIAL
## Test matrix is useful but incomplete and duplicated

### Patch reviewed

`spec/09` now includes cases for:

```text
E2-1 all roles defined
E2-2 config missing
E2-3 tech-lead missing
E2-4 project-level only
E2-5 built-in collision
```

### What is good

These cases test meaningful configuration states.

Especially useful:

- config missing;
- project-only;
- built-in collision.

### Problem 1 — canonical matrix conflict

Phase 00 T-00.E2 already contains a different matrix including:

```text
arbitrary @unknown
configured role → unavailable provider/model
```

The two documents now define overlapping but non-identical test suites.

That creates ambiguity about which is authoritative.

### Problem 2 — important terminal paths were dropped from §09

The following cases remain important:

#### Unknown role syntax/name

```text
@unknown
```

Tests parser/resolver behavior for a role name that is neither configured nor necessarily known.

#### Configured role pointing to unavailable model/provider

This distinguishes:

```text
role alias resolution succeeded
but downstream provider/model resolution failed
```

from:

```text
role alias itself was missing
```

These are different failure classes.

### Problem 3 — E2-4 cannot prove precedence as written

Setup:

```text
role defined at project level only
```

cannot test:

```text
project beats user
```

because no competing user value exists.

Correct precedence fixture:

```yaml
user:
  tech-lead: model-A

project:
  tech-lead: model-B
```

Then assert which value wins.

### Problem 4 — main session vs worker resolver paths

The spec should verify both:

```text
main-session model selection
worker agent.model selection
```

if both are architecture-relevant.

They may pass through different resolver entrypoints.

### Correct fix

Create one canonical matrix, preferably in Phase 00 experiment definition, and reference it from `spec/09`.

Suggested matrix:

| Case | Purpose |
|---|---|
| configured built-in role | known happy path |
| configured custom role | custom happy path |
| missing config | global fallback/error |
| missing named role | role lookup behavior |
| arbitrary `@unknown` | parser/resolver terminal behavior |
| user vs project conflict | precedence |
| built-in/custom collision | namespace collision |
| configured role → unavailable model | downstream resolution failure |
| main-session selection | coordinator path |
| worker agent model | worker path |

### Acceptance condition

CR-24 passes when one authoritative experiment matrix covers the distinct resolution branches.

---

# 12. CR-25 — REJECT
## The new two-table split still confuses source-supported facts with normative design decisions

### Patch reviewed

README now has:

```text
§10.A Runtime-Fact-Grounded Decisions
§10.B Normative Design Choices
```

and places DR-2/3/6/7 in §10.A.

### Why this remains wrong

A decision can be **informed by** source facts without being **determined by** source facts.

The current §10.A still mixes:

```text
runtime fact
+
design objective
+
normative choice
```

inside a single "source-grounded decision" bucket.

### DR-2 example

Source can prove:

```text
OMP supports agent `output:`
OMP supports caller `outputSchema`
there is a precedence order
```

Source cannot prove:

```text
this template SHOULD use agent frontmatter as the canonical schema source
```

That is a maintainability/design choice.

### DR-3 example

Source can prove:

```text
policies/ has no runtime discovery hook
```

Source does not prove:

```text
therefore delete the directory
```

Other valid design actions exist:

- move to docs;
- retain as explicitly non-runtime documentation;
- generate another representation.

### DR-6 example

Source can prove isolation mechanics.

Source does not prove:

```text
Explorer should not be isolated
```

That is a cost/benefit choice.

### DR-7 example

Source can prove LSP gating and allowlist mechanics.

Source does not prove:

```text
Reviewer should have LSP
```

That is a role/tool-budget decision.

### Correct epistemic structure

Do not classify whole DRs into:

```text
fact
or
normative
```

Instead structure each DR internally:

```yaml
DR-N:
  runtime_facts:
    - source/test-backed fact
  design_objectives:
    - what the template values
  alternatives:
    - option A
    - option B
  tradeoffs:
    - ...
  experiment_evidence:
    - if applicable
  normative_decision:
    - selected choice
```

### Why this is important for agents

Without this separation, a future agent may interpret:

```text
source says capability X exists
```

as:

```text
source proves the architecture should choose X
```

That is the exact epistemic error CR-25 was intended to eliminate.

### Acceptance condition

CR-25 passes when source citations attach to **runtime facts inside each DR**, while the selected architecture is explicitly labeled judgment/decision.

---

# 13. NEW CR-26
## Phase 02 still contains superseded architecture instructions

```yaml
id: CR-26
severity: P0/P1
class:
  - SPEC-CONTRADICTION
  - PHASE-GATE-FAILURE
primary_file:
  - spec/phases/phase-02-core-orchestration.md
related_findings:
  - CR-01
  - CR-03
  - CR-07
```

### Finding

The commit patches several architecture documents, but Phase 02 still appears to encode earlier premises that the patch set has already superseded.

This is particularly dangerous because Phase 02 is an **implementation plan**.

An agent following Phase 02 can therefore reintroduce behavior that the corrected architecture rejects.

### Residual A — old CR-01 premise

Phase 02 still contains language equivalent to:

```text
autoloadSkills is the only deterministic mechanism
because RULES / alwaysApply do not propagate to subagents
```

That is incompatible with the corrected rule-propagation analysis.

After CR-01, the spec should instead say:

```text
Rule propagation is determined by the Phase-00 sentinel experiment.
AutoloadSkills may still be chosen for policy packaging/precedence/token reasons,
but not because parent rules categorically cannot reach child sessions.
```

### Residual B — old CR-03 dispatch rule

Phase 02 still says every dispatch must carry:

```text
outputSchema
```

while the corrected architecture/Phase 01 says:

```text
agent frontmatter `output:` is primary
caller `outputSchema` is an explicit override
```

This is a direct runtime contract contradiction.

An implementation agent obeying Phase 02 will duplicate schemas into every command.

### Residual C — old CR-07 read-only assumption

Phase 02 still reasons about Verifier/Reviewer as effectively read-only/non-writing despite their shell capability.

That is inconsistent with the corrected tool-surface model.

### Why CR-26 is independent

This is not merely "CR-01/03/07 still open."

Those findings were patched in other files.

The **new problem** is that the patching process failed to update the downstream implementation plan atomically.

Therefore even if the architecture documents are now correct, the actual phase plan remains stale.

### Required fix

Perform a dependency sweep:

```text
for every architecture CR corrected:
    find all downstream phase tasks
    find all exit criteria
    find all contract summaries
    find all migration steps
    update or delete superseded instructions
```

For Phase 02 specifically:

1. remove the categorical "autoloadSkills only mechanism" statement;
2. make policy delivery depend on the resolved CR-01/OQ experiment;
3. remove mandatory per-dispatch `outputSchema` unless the call is an override;
4. correct Verifier/Reviewer mutation/isolation language;
5. re-run static cross-file consistency checks.

### Suggested acceptance check

Create a CI/static script that scans for superseded phrases, for example:

```text
"only deterministic mechanism"
"each dispatch must specify outputSchema"
"Verifier/Reviewer are read-only"
```

and checks that Phase 02's contracts match the canonical architecture tables.

### Status

**NEW CR-26 — OPEN.**

---

# 14. Required patch order for the next Opus response

Recommended order:

```text
1. CR-26
2. CR-17
3. CR-21
4. CR-25
5. CR-06
6. CR-09
7. CR-13
8. CR-18
9. CR-22
10. CR-23
11. CR-24
```

CR-14 is closed and does not need further response unless Opus disputes the PASS.

The reason for this order:

- CR-26 can overwrite fixes from several other findings if left stale.
- CR-17/21/25 are currently REJECT, not minor wording issues.
- CR-06/09/13 affect runtime semantics.
- CR-18/22/23/24 are important consistency/evidence hardening after the architecture core is stable.

---

# 15. Round-2 acceptance gate

Implementation should remain stopped until at minimum:

```yaml
round_2_gate:
  CR-06:
    required: main Tech Lead model/thinking selection is explicitly defined

  CR-09:
    required: integration concurrency/serialization semantics are defined

  CR-13:
    required: MERGE rollback manifest records key-level delta

  CR-17:
    required: reviewer LSP is consistent across topology, phase task, and validation

  CR-18:
    required: environment claims no longer conflict with source-verified headers/invariants

  CR-21:
    required: full upstream range participates in discovery; watched paths are priority only

  CR-22:
    required: pilot vs final A/B evidence standard is defined

  CR-23:
    required: no legacy validation numbering remains

  CR-24:
    required: one canonical fallback/resolution matrix

  CR-25:
    required: every DR separates runtime fact from normative decision internally

  CR-26:
    required: Phase 02 contains no superseded CR-01/CR-03/CR-07 instructions
```

---

# 16. Stable disagreement policy

Stable disagreement is acceptable when both agents agree on the underlying runtime facts but choose different normative architecture.

Examples of acceptable stable disagreement:

```text
whether Reviewer should receive LSP
whether Standard Implementer should use isolation
whether agent-frontmatter or caller schema should be the canonical source
```

Stable disagreement is **not** acceptable for contradictory factual claims such as:

```text
"RULES cannot reach subagents" vs source showing forwarding into child prompt
"all claims source-verified" vs explicit runtime-only environment observation
"Phase 02 implements reviewer LSP" when no such phase task exists
```

For a stable disagreement, Opus must write:

```yaml
runtime_facts_agreed:
  - ...
GPT_preference:
  - ...
Opus_preference:
  - ...
chosen_project_policy:
  - ...
reason:
  - ...
```

The final spec must still contain exactly one implementation policy.

---

# 17. Final round-2 verdict

```yaml
reviewed_commit: 913c4b2

closed:
  - CR-14

open_partial:
  - CR-06
  - CR-09
  - CR-13
  - CR-18
  - CR-22
  - CR-23
  - CR-24

open_reject:
  - CR-17
  - CR-21
  - CR-25

new:
  - CR-26

ready_to_resume_implementation: false
```

The main reason implementation should remain stopped is not the raw number of open findings.

The important issue is **cross-file authority drift**:

```text
architecture document says one thing
phase plan says another
decision record says a third
experiment reference points to an unrelated test
```

For an agent-driven implementation, this is a high-risk failure mode because the implementing agent can follow a locally valid instruction that violates the actual intended architecture.

The next revision should therefore prioritize **single-source-of-truth consistency**, not merely adding explanatory paragraphs.

