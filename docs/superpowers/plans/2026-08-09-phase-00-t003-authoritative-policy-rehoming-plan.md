# Phase 00 T-00.3 Authoritative Policy Re-homing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the inert `.omp/policies/` runtime surface and rebuild each useful policy contract in its real consumer with durable Phase 00 evidence.

**Architecture:** Treat the five tracked YAML files as hash-locked historical inputs, not runtime authority. Re-home reconciled contracts into commands, agents, main-session instructions, three reference documents, and static advisory validation; then delete the old surface and make T-00.3 authority depend on a mutation-tested evidence contract.

**Tech Stack:** PowerShell 5.1-compatible scripts, Pester 3.4 syntax, Markdown/YAML artifacts, SHA-256 and Git blob provenance, existing Phase 00 manifest/validator framework.

**Approved design:** `docs/superpowers/specs/2026-08-09-phase-00-t003-authoritative-policy-rehoming-design.md`  
**Approved design SHA-256:** `EA56CD82EBE1D59A40AC3F549D39F57DF66D3B8558D024252333C7E2E71A5A4F`

## Global Constraints

- Work inline in the user-authorized dirty `main` workspace; preserve unrelated user changes.
- Apply authored file mutations with `apply_patch`.
- Do not create or switch branches/worktrees; do not stage, commit, push, reset, checkout, or open a pull request.
- Do not call a provider or launch E1, E2, E3-I, E3-L, E3-M, Session B, or Attempt 6.
- Keep `parallel_mode: DISABLED`; do not change any E3 authority row.
- Do not implement T-00.4, exact BPE token counting, Tech Lead relocation, Reviewer rename, worker `blocking`, output schemas, LSP, or the installer `workflows` defect.
- Preserve raw runtime evidence, adjudication sidecars, prior review packets, prior changelogs, and historical research documents byte-for-byte unless a file is explicitly listed below.
- Use PowerShell 5.1-compatible syntax and Pester 3.4 assertions (`Should Be`, `Should Match`, no Pester 5-only configuration API).
- The old policy hashes and line counts in the approved design are immutable inputs.
- Maintain `codex-phase00-t003-authoritative-rebuild-changelog-for-opus5.md` in English after every implementation task.
- Treat T-00.3 as locally evidenced but `PROVISIONAL_PENDING_OPUS_REVIEW`; Codex alone does not close peer review.

---

## Design Coverage Map

| Approved design section | Implemented by |
|---|---|
| §1-4 objective, authority, pre-state | Task 1 and Task 2 constants/ledger |
| §5 source-to-consumer mapping | Task 3 reference docs, commands, agents, and spec anchors |
| §6 documentation layout | Task 3 exact four-file reference set |
| §7 installed-surface cleanup | Task 4 installer, validator, direct docs, and deletion |
| §8 validator/test design | Task 1 RED, Task 2 durable contract and mutation-code registration, then Task 5 baseline-backed mutation execution |
| §9 evidence and manifest | Task 5 conclusion and isolated T-00.3 transition |
| §10 direct documentation boundary | Task 4 exact scan-driven current-product set |
| §11 exclusions | Global constraints plus Task 6 non-claim audit |
| §12 Opus changelog | Task 1 initial ledger and updates through Task 6 |
| §13 acceptance criteria | Task 5 focused GREEN and Task 6 full cross-shell verification |

## File Responsibility Map

### Create

| File | Responsibility |
|---|---|
| `scripts/tests/phase00-t003.Tests.ps1` | Focused desired-state, fixture mutation, evidence-chain, and regression tests |
| `docs/policies/README.md` | Non-runtime status plus five-source disposition index |
| `docs/policies/context-budget.md` | Human reference for provisional budgets, packet/result prohibitions, retrieval, and offload constraints |
| `docs/policies/model-routing.md` | Human reference separating required roles, optional Tech Lead alias, runtime facts, and E2 unknowns |
| `docs/policies/quality-gates.md` | Human expansion of the six gates, triggers, checks, matrix, and selection ownership |
| `docs/evidence/phase-00/T-00.3/conclusion.yml` | Hash-bearing local PASS authority and explicit non-claims |
| `codex-phase00-t003-authoritative-rebuild-changelog-for-opus5.md` | Complete continuation ledger for later equal Opus review |

### Modify

| File group | Responsibility |
|---|---|
| `template/.omp/commands/{quick,standard,orchestrated}.md` | Local sizing/escalation; Standard/Orchestrated gate matrix and role-based dispatch |
| `template/.omp/agents/{tech-lead,explorer,implementer,verifier,reviewer}.md` | Remove dangling policy reference and deliver role-specific stop/return contracts |
| `template/.omp/AGENTS.md` | Main-session packet/result and user-escalation boundaries |
| `scripts/lib/phase00-evidence.ps1` | Export `Test-Phase00T003PolicyRehomingContract` and strict evidence parsing |
| `scripts/validate-template.ps1` | Register T-00.3; retire policy-file checks; make the first-three-category token thresholds explicit and advisory |
| `scripts/install-template.ps1` | Remove/explicitly reject the retired component |
| `scripts/tests/phase00-wave-a.Tests.ps1` | Require six Phase 00 validators and T-00.3 entrypoint output |
| `docs/evidence/phase-00/manifest.yml` | Transition only T-00.3 from READY to evidence-backed PASS |
| `README.md`, `CHANGELOG.md` | Current-product inventory and change record |
| `docs/{architecture,customization,final-report,installation,report-design,security,token-strategy,workflow-v0}.md` | Remove immediately false installed-policy claims and point to the new delivery model |
| `spec/04-workflow-sizing.md` | Clarify the retired YAML does not survive as runtime/reference authority |
| `spec/09-model-routing.md` | Replace the direct retired-YAML anchor with the human reference |
| `spec/11-skills-rules-and-quality-gates.md` | Name the Markdown reference destination |
| `spec/phases/phase-00-foundation.md` | Correct the stale `03-token-quality-model.md` anchor to `03-agent-topology.md` |

### Delete

`template/.omp/policies/context-budget.yml`, `escalation.yml`, `model-routing.yml`,
`quality-gates.yml`, and `workflow-sizing.yml`. The empty directory disappears with them.

### Verify without modification

`registry/upstreams.yml` and `registry/adoption-ledger.yml` already use Markdown
`local_components` and explicit `superseded_paths` for the three upstream-derived policy
contracts. The implementation verifies these records; it does not churn them.

---

### Task 1: Lock pre-state, create the continuation ledger, and prove RED

**Files:**

- Create: `scripts/tests/phase00-t003.Tests.ps1`
- Create: `codex-phase00-t003-authoritative-rebuild-changelog-for-opus5.md`

**Interfaces:**

- Consumes: approved design hash and the five locked source rows.
- Produces: desired-state test names used by all later tasks; an append-only round ledger.

- [x] **Step 1: Capture the exact pre-state without mutation**

Run:

```powershell
$policyFiles = Get-ChildItem -LiteralPath template/.omp/policies -File | Sort-Object Name
git branch --show-current
git rev-parse HEAD
@(git diff --cached --name-only).Count
$policyFiles | ForEach-Object {
    $relative = $_.FullName.Substring((Get-Location).Path.Length + 1).Replace('\','/')
    [pscustomobject]@{
        path = $relative
        lines = (Get-Content -LiteralPath $_.FullName).Count
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        git_blob = (git rev-parse "HEAD:$relative").Trim()
    }
}
```

Expected: branch `main`, HEAD `62fecf277dc9d5e47d06319387eac747462214c1`, staged count `0`, five rows totaling 363 lines, and exact hashes from the approved design.

- [x] **Step 2: Create the focused test surface**

Start `scripts/tests/phase00-t003.Tests.ps1` with:

```powershell
#Requires -Version 5.1

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-evidence.ps1'
$script:t003HelperLoaded = $false
if (Test-Path -LiteralPath $helperPath -PathType Leaf) {
    . $helperPath
    $script:t003HelperLoaded = $true
}

function Get-T003FailureCodes($Results) {
    @($Results | Where-Object { $_.Status -eq 'FAIL' } |
        ForEach-Object { $_.Code })
}

function Assert-T003HelperLoaded {
    $script:t003HelperLoaded | Should Be $true
    (Get-Command Test-Phase00T003PolicyRehomingContract -ErrorAction SilentlyContinue) `
        -ne $null | Should Be $true
}

Describe 'T-00.3 desired installed surface' {
    It 'removes the inert runtime directory' {
        (Test-Path -LiteralPath (Join-Path $repositoryRoot `
            'template\.omp\policies')) | Should Be $false
    }

    It 'creates exactly four non-runtime policy reference files' {
        $referenceRoot = Join-Path $repositoryRoot 'docs\policies'
        $names = @(Get-ChildItem -LiteralPath $referenceRoot -File | Sort-Object Name | ForEach-Object { $_.Name })
        ($names -join ',') | Should Be 'context-budget.md,model-routing.md,quality-gates.md,README.md'
    }

    It 'contains no dangling installed policy reference' {
        $files = @(Get-ChildItem -Recurse -File `
            (Join-Path $repositoryRoot 'template\.omp\agents'), `
            (Join-Path $repositoryRoot 'template\.omp\commands'))
        $bad = @($files | Select-String -Pattern '(?i)policy:|(?:^|[\\/])policies[\\/]')
        $bad.Count | Should Be 0
    }

    It 'exports the durable T-00.3 validator' {
        Assert-T003HelperLoaded
    }

    It 'accepts the canonical repository state' {
        Assert-T003HelperLoaded
        $codes = Get-T003FailureCodes `
            (Test-Phase00T003PolicyRehomingContract -RepositoryRoot $repositoryRoot)
        $codes.Count | Should Be 0
    }
}
```

- [x] **Step 3: Run focused RED in both shells**

Run:

```powershell
pwsh -NoProfile -Command "Invoke-Pester -Script scripts/tests/phase00-t003.Tests.ps1 -PassThru"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command `
  "Invoke-Pester -Script scripts/tests/phase00-t003.Tests.ps1 -PassThru"
```

Expected RED causes: old directory exists, four reference files are absent, the durable function is absent, `policy:workflow-sizing` remains, and canonical-state validation cannot pass.

- [x] **Step 4: Create the initial English changelog**

Write the title, scope, approved design path/hash, branch/HEAD/staged count, five-source table,
non-authorizations, and the exact RED output. Do not add empty future sections. State that every
subsequent task appends only facts already observed on disk.

- [x] **Step 5: Checkpoint instead of committing**

Run:

```powershell
Get-FileHash -Algorithm SHA256 `
  scripts/tests/phase00-t003.Tests.ps1, `
  codex-phase00-t003-authoritative-rebuild-changelog-for-opus5.md
@(git diff --cached --name-only).Count
```

Expected: two hashes and staged count `0`. Append both hashes to the changelog.

---

### Task 2: Add the durable fail-closed contract and pre-register mutation controls

**Files:**

- Modify: `scripts/lib/phase00-evidence.ps1`
- Modify: `scripts/validate-template.ps1`
- Modify: `scripts/tests/phase00-t003.Tests.ps1`
- Modify: `scripts/tests/phase00-wave-a.Tests.ps1`
- Modify: `codex-phase00-t003-authoritative-rebuild-changelog-for-opus5.md`

**Interfaces:**

- Produces: `Test-Phase00T003PolicyRehomingContract -RepositoryRoot <string>` returning `New-Phase00ValidationResult` objects.
- Result codes: `P00-T003-SURFACE`, `P00-T003-REFERENCES`, `P00-T003-CONSUMERS`, `P00-T003-INSTALLER`, `P00-T003-VALIDATOR`, `P00-T003-REGISTRY`, `P00-T003-PRODUCT-DOCS`, `P00-T003-EVIDENCE`, `P00-T003-MANIFEST`.

- [x] **Step 1: Add immutable legacy-source constants and hash helper**

Add near the other Phase 00 constants:

```powershell
$script:Phase00T003LegacySources = @(
    [pscustomobject]@{ Id='context-budget'; Path='template/.omp/policies/context-budget.yml'; Lines=89; Sha256='A3FE19A6C131F3A9F43EF2AC5156993437CDC07B0ABE6AF284FE6E966C2F03EE'; GitBlob='f5591a7b7cd3e06efbd5431536ebd2391bdedd6d' },
    [pscustomobject]@{ Id='escalation'; Path='template/.omp/policies/escalation.yml'; Lines=52; Sha256='49CB215BEEC2424C9274BBA285E2AD28B651A124AF1BF07102A925FDAEA5FD1F'; GitBlob='c8e51d31baed0b2ce7ee000bd0be5deb3858e691' },
    [pscustomobject]@{ Id='model-routing'; Path='template/.omp/policies/model-routing.yml'; Lines=61; Sha256='67E7F80534AB66C57B13EF91AD88CABAE5518F8828E89C496B78AB9C4209F4A2'; GitBlob='c73070c1e73737a6947b48eb84338b583e4aa663' },
    [pscustomobject]@{ Id='quality-gates'; Path='template/.omp/policies/quality-gates.yml'; Lines=105; Sha256='69A8635F66C118D5BC12612E7D7B6F498E1886B7213F15613BE5A37B6370A1E2'; GitBlob='47f6d06191a9e7b68f07da1903d96b931024fa30' },
    [pscustomobject]@{ Id='workflow-sizing'; Path='template/.omp/policies/workflow-sizing.yml'; Lines=56; Sha256='603112590C993F9DEC61D17C32387C040C775C384B1D8656756170971703671B'; GitBlob='195c1f836bfd62381099cd9633073db4a37c88bc' }
)

function Get-Phase00FileSha256 {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
}
```

- [x] **Step 2: Implement the category-based validator**

The function must emit exactly one PASS or FAIL result per result code. Use these predicates:

```powershell
function Test-Phase00T003PolicyRehomingContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $root = [IO.Path]::GetFullPath($RepositoryRoot)
    $results = New-Object System.Collections.Generic.List[object]

    # SURFACE: retired directory absent.
    # REFERENCES: exact four-file set; each contains "OMP runtime: not loaded" and
    #              "Retired source:"; canonical budget/routing/gate markers present.
    # CONSUMERS: agents+commands contain no policy:/policies path; exact sizing,
    #            routing, quality matrix, and escalation markers present.
    # INSTALLER: default/map omit policies and explicit legacy request text exists.
    # VALIDATOR: deleted YAML paths absent; T-00.3 function is registered; advisory
    #            budget calls carry (600,1200,1500), (300,700,800), (500,1200,1500).
    # REGISTRY: every docs/policies local_component exists; old policy paths appear
    #           only in superseded_paths or historical text.
    # PRODUCT-DOCS: exact current-product file set has no installed-policy claim.
    # EVIDENCE: strict schema/status/source rows/disposition rows/destination hashes.
    # MANIFEST: T-00.3 PASS, depends_on [], exactly one conclusion artifact;
    #           every E3 row and parallel_mode unchanged by this contract.

    return @($results)
}
```

Implement each comment as an explicit boolean and call
`New-Phase00ValidationResult PASS|FAIL <code> <message>`. Do not throw on a missing migration
file; return the category's FAIL result so one run reports the complete incomplete surface.

- [x] **Step 3: Define strict evidence parsing**

Add `Read-Phase00T003Conclusion -Path <string>`. Parse only the schema defined in Task 5:

- top-level `schema_version`, `phase`, `task`, `status`, `provider_calls`, `parallel_mode`;
- five `legacy_sources` rows with `id/path/lines/sha256/git_blob`;
- ordered `dispositions` rows with `source_section/status/destinations/authority`;
- `destinations` rows with `path/sha256`;
- `checks` scalar map and `non_claims` list.

Reject duplicate keys, duplicate source IDs, duplicate destination paths, unknown disposition
status, non-uppercase 64-character hashes, or any incomplete marker. Do not use an external YAML
module; preserve PowerShell 5.1 portability.

- [x] **Step 4: Register the validator**

Append `"Test-Phase00T003PolicyRehomingContract"` to `$phase00Validators` in
`scripts/validate-template.ps1`. In `phase00-wave-a.Tests.ps1`, change “five contract
validators” to “six contract validators”, assert the new command exists, and require
`P00-T003-MANIFEST` in verbose validator output.

- [x] **Step 5: Pre-register mutation codes; defer executable fixtures until a GREEN baseline exists**

Record the exact mutation-to-code map in the focused suite now. Add the temp-only
`New-T003Fixture` and its resolved-temp cleanup guard in Task 5, after the canonical contract
surface exists and is GREEN. Each mutation test must first prove that its category passes in
the unmodified fixture, then prove that the mutation produces the named code:

```powershell
@{
    RecreatedPolicyFile = 'P00-T003-SURFACE'
    DanglingPolicyRef   = 'P00-T003-CONSUMERS'
    ChangedGateMatrix   = 'P00-T003-CONSUMERS'
    MissingEscalation   = 'P00-T003-CONSUMERS'
    AdvertisedInstaller = 'P00-T003-INSTALLER'
    ForgedSourceHash    = 'P00-T003-EVIDENCE'
    ForgedDestHash      = 'P00-T003-EVIDENCE'
    PassWithoutEvidence = 'P00-T003-MANIFEST'
}
```

This sequencing prevents a tautological test that "detects" a mutation only because the same
category was already failing before the mutation. Every fixture write uses
`[IO.File]::WriteAllText(..., [Text.UTF8Encoding]::new($false))` so PowerShell 5.1 does not
introduce BOM/newline hash drift.

- [x] **Step 6: Run the new tests and record the controlled partial state**

Run both shells. Expected: helper/export, strict-parser negative controls, category cardinality,
and mutation-code registration are available; canonical repository acceptance remains RED for
the nine migration categories. Append the commands, counts, and exact failure codes to the
changelog. Executable mutation behavior is proven in Task 5 against a passing baseline.

- [x] **Step 7: Checkpoint hashes and staged state**

Hash all five modified files, append before/after rows to the changelog, and confirm staged
count remains zero.

---

### Task 3: Rebuild policy-derived reference and runtime consumers

**Files:**

- Create: `docs/policies/README.md`
- Create: `docs/policies/context-budget.md`
- Create: `docs/policies/model-routing.md`
- Create: `docs/policies/quality-gates.md`
- Modify: `template/.omp/commands/quick.md`
- Modify: `template/.omp/commands/standard.md`
- Modify: `template/.omp/commands/orchestrated.md`
- Modify: all five files under `template/.omp/agents/`
- Modify: `template/.omp/AGENTS.md`
- Modify: `spec/04-workflow-sizing.md`
- Modify: `spec/09-model-routing.md`
- Modify: `spec/11-skills-rules-and-quality-gates.md`
- Modify: `spec/phases/phase-00-foundation.md`
- Modify: `codex-phase00-t003-authoritative-rebuild-changelog-for-opus5.md`

**Interfaces:**

- Produces: the four exact reference files and stable markers consumed by the durable contract.
- Stable markers: `OMP runtime: not loaded`, `Retired source: <basename>`, `Policy-derived contract`, `Selected quality gates`, `Routing boundary`, `Escalation boundary`.

- [x] **Step 1: Write the documentation-only disposition index**

`docs/policies/README.md` must state:

```markdown
# Policy Reference

> OMP runtime: not loaded. This directory is human documentation outside the installed
> `.omp/` surface. Runtime behavior lives in the named command, agent, or validator consumer.

| Retired source | Disposition | Runtime consumer | Human authority |
|---|---|---|---|
| `context-budget.yml` | REHOMED | AGENTS/worker prompts + advisory validator | `context-budget.md`, `spec/05` |
| `model-routing.yml` | REHOMED_WITH_SUPERSEDED_CLAUSES | Standard/Orchestrated dispatch prose | `model-routing.md`, `spec/09` |
| `workflow-sizing.yml` | REHOMED_WITH_SUPERSEDED_TIE_BREAK | Quick/Standard/Orchestrated | `spec/04` |
| `quality-gates.yml` | REHOMED | Standard/Orchestrated task-packet construction | `quality-gates.md`, `spec/11` |
| `escalation.yml` | REHOMED_BY_OWNER | worker stop clauses + main-session escalation | `spec/04`, `spec/15` |
```

- [x] **Step 2: Write the context-budget reference**

Copy the exact seven-row table from `spec/05:60-68`, label all numbers provisional, retain the
two packet/result prohibitions and retrieval order, and state these enforcement levels:

| Category | Enforcement |
|---|---|
| AGENTS/RULES/agent prompt | advisory `chars / 4` static check |
| skill description/body | reference only; more-specific skill contract wins |
| task packet/worker result | prompt contract only |
| optimality | not established until evaluation |

Record `Retired source: context-budget.yml` without a retired directory path.

- [x] **Step 3: Write the model-routing reference**

Use this exact required-role table:

```markdown
| Role | Requirement | Resolution owner |
|---|---|---|
| explorer | required worker alias | agent frontmatter + project `config.yml` |
| implementer | required worker alias | agent frontmatter + project `config.yml` |
| verifier | required worker alias | agent frontmatter + project `config.yml` |
| reviewer | required worker alias | agent frontmatter + project `config.yml` |
| tech-lead | optional user alias | user-selected main-session model/config |
```

State that concrete gateway/model identifiers are environment properties, all access uses
OmniRoute in this deployment, silent model fallback is disabled, and E2 still owns unknown-role,
precedence, collision, and unavailable-model terminal behavior.

- [x] **Step 4: Write the quality-gate reference**

Retain all six gate names and their old trigger/check content, but change ownership to:

```text
main session selects gates -> task packet carries names -> Reviewer applies only those names
```

Include the exact risk matrix from the approved design. State separately that the matrix does
not decide whether a Reviewer is dispatched.

- [x] **Step 5: Rebuild command policy-derived sections**

In every command, add `<!-- Policy-derived contract; retired source: workflow-sizing.yml -->`
and the applicable escalation trigger. In Standard and Orchestrated, add:

```markdown
## Selected quality gates

| Risk | Gates |
|---|---|
| LOW | none |
| MEDIUM | security |
| HIGH | api-compatibility, security, performance, release-readiness, rollback-readiness |
| CRITICAL | api-compatibility, security, performance, release-readiness, rollback-readiness, adr-documentation |

The main session resolves these names while building the task packet. The Reviewer applies
the selected names and does not expand its own scope.

## Routing boundary

Dispatch the named worker. Its agent frontmatter selects `@<role>` and project `config.yml`
maps that alias to the environment's concrete model. Do not hard-code a model here and do not
change routing during the session.
```

Quick must say restart as Standard when its target is not known or its scope expands. Standard
must restart as Orchestrated only after exploration proves at least two independent workstreams.
Orchestrated must not de-escalate.

- [x] **Step 6: Rebuild escalation ownership in prompts**

Use role-specific clauses, not a duplicated generic block:

```markdown
Explorer: stop with bounded investigation evidence; never guess a missing root cause.
Implementer: verification failure -> failed; scope/dependency expansion -> blocked;
             unresolved root cause after two targeted investigations -> partial.
Verifier: any uncovered criterion -> PARTIAL/FAIL; never convert environment failure to PASS.
Reviewer: any verified BLOCKING issue -> CHANGES_REQUESTED; never self-merge or rewrite.
Main session: credentials, destructive action, critical risk, or required architecture
              violation -> stop and request user authority.
```

Remove `policy:workflow-sizing` from `tech-lead.md` and replace it with the Quick/Standard and
Standard/Orchestrated decisive questions. Do not otherwise repair Tech Lead topology.

- [x] **Step 7: Correct only the four normative consistency anchors**

- `spec/04`: W-3 says the YAML does not survive; section C and commands are authoritative.
- `spec/09`: replace “correctly reflected in model-routing.yml” with
  `docs/policies/model-routing.md` and command delivery.
- `spec/11`: replace the docs destination's `.yml` reference with
  `docs/policies/quality-gates.md`.
- Phase spec: replace `03-token-quality-model.md` with `03-agent-topology.md`.

- [x] **Step 8: Run focused tests in both shells**

Expected: `P00-T003-REFERENCES` and `P00-T003-CONSUMERS` turn GREEN. Surface, installer,
validator retirement, product docs, evidence, and manifest remain RED.

- [x] **Step 9: Append task evidence and checkpoint hashes**

Record every created/modified path, before/after hash, content-disposition decision, test
command/result, and staged count in the changelog.

---

### Task 4: Retire the old installed surface and every direct current-product claim

**Files:**

- Modify: `scripts/install-template.ps1`
- Modify: `scripts/validate-template.ps1`
- Modify: `README.md`, `CHANGELOG.md`
- Modify: `docs/architecture.md`, `docs/customization.md`, `docs/final-report.md`, `docs/installation.md`, `docs/report-design.md`, `docs/security.md`, `docs/token-strategy.md`, `docs/workflow-v0.md`
- Delete: all five `template/.omp/policies/*.yml`
- Modify: `scripts/tests/phase00-t003.Tests.ps1`
- Modify: `codex-phase00-t003-authoritative-rebuild-changelog-for-opus5.md`

**Interfaces:**

- Consumes: reference/consumer markers from Task 3.
- Produces: no installed policy directory, no advertised component, and honest advisory budget output.

- [x] **Step 1: Make the legacy installer argument fail explicitly**

Remove `"policies"` from the default component list and component map. Before planning files,
add:

```powershell
if (@($Components | Where-Object { $_ -ceq 'policies' }).Count -gt 0) {
    throw "Component 'policies' was retired by Phase 00 T-00.3. Policy contracts are inlined into commands/agents; human references live under docs/policies/."
}
```

Do not add general unknown-component validation and do not repair `workflows` in this task.

- [x] **Step 2: Replace misleading YAML checks with explicit advisory budget checks**

Rename `Test-TokenBudget` to `Test-ApproxTokenBudget` and use:

```powershell
function Test-ApproxTokenBudget(
    [string]$rel,
    [int]$targetMin,
    [int]$targetMax,
    [int]$hardWarningAbove
) {
    $full = Join-Path $PSScriptRoot "..\$rel"
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        Write-Fail "approx-token-budget (file missing): $rel"
        return
    }
    $tokens = Get-ApproxTokens $full
    if ($tokens -lt $targetMin) {
        Write-Warn "approx-token-budget below target ($tokens < $targetMin): $rel"
    } elseif ($tokens -gt $hardWarningAbove) {
        Write-Warn "approx-token-budget above hard warning ($tokens > $hardWarningAbove): $rel"
    } elseif ($tokens -gt $targetMax) {
        Write-Warn "approx-token-budget above target ($tokens > $targetMax): $rel"
    } else {
        Write-Pass "approx-token-budget in target ($tokens): $rel"
    }
}
```

Call with `600 1200 1500` for AGENTS, `300 700 800` for RULES, and `500 1200 1500`
for every currently installed agent prompt. Remove all five policy paths from `$required_files`
and `$yaml_files`; add the exact four `docs/policies/*.md` files to required files. Keep schema
YAML checks unchanged.

- [x] **Step 3: Rewrite direct current-product documentation**

Apply these exact semantic replacements:

| File | Required result |
|---|---|
| `README.md` | no Policies count or installed tree node; explain policy contracts are in consumers with docs references |
| `CHANGELOG.md` | replace “Five policies” with a T-00.3 removal/re-homing entry |
| `docs/architecture.md` | remove installed policies tree; show `docs/policies/` outside `template/.omp/` |
| `docs/customization.md` | replace copy-to-`.omp/policies` instructions with edits to commands/agents and reference docs |
| `docs/final-report.md` | remove five completed runtime policy rows; mark the earlier implementation superseded |
| `docs/installation.md` | remove `policies` from examples and available components |
| `docs/report-design.md` | describe inlined contracts plus human references, not five runtime policies |
| `docs/security.md` | stop listing policies as installed YAML/runtime behavior |
| `docs/token-strategy.md` | link `docs/policies/context-budget.md`; label `chars / 4` advisory |
| `docs/workflow-v0.md` | remove policy count/runtime-consumer claims and record supersession |

Do not fix unrelated stale workflow paths, schema claims, installer parameters, or historical
research reports; add each such observation to the changelog's explicit exclusions.

- [x] **Step 4: Delete the five old source files with `apply_patch`**

Delete exactly the files listed in the approved design. Before deletion, recompute their
SHA-256 and line counts and abort if any differs from the locked rows. After deletion, verify:

```powershell
Test-Path -LiteralPath template/.omp/policies
```

Expected: `False`. No backup copy is created inside the repository; Git plus the conclusion
source inventory is the recovery path.

- [x] **Step 5: Run exact retired-surface scans**

Run:

```powershell
rg -n -S 'policy:|(?:^|[\\/])policies[\\/]' template/.omp/agents template/.omp/commands
rg -n -S 'Policies.*5|policies/.*5 policy|\.omp[\\/]policies|Components.*policies' `
  README.md CHANGELOG.md docs/architecture.md docs/customization.md `
  docs/final-report.md docs/installation.md docs/report-design.md `
  docs/security.md docs/token-strategy.md docs/workflow-v0.md

$installer = Get-Content -LiteralPath scripts/install-template.ps1 -Raw
@([regex]::Matches($installer, '(?m)^\s*["'']policies["'']\s*(?:,|=)')).Count
$installer.Contains("Component 'policies' was retired by Phase 00 T-00.3. Policy contracts are inlined into commands/agents; human references live under docs/policies/.")
```

Expected: no runtime/current-product match, installer advertised-entry count `0`, and explicit
rejection `True`. The installer is checked separately because the required negative-compatibility
message intentionally names the retired component. Provenance basenames such as
`quality-gates.yml` are allowed only without a retired directory path.

Execution correction (2026-08-09): the originally approved combined scan also included
`scripts/install-template.ps1`, so its `Components.*policies` alternative necessarily matched the
required rejection guard from Step 1. Splitting advertisement detection from the registered
negative-compatibility message preserves the acceptance intent without hiding that intentional
occurrence.

- [x] **Step 6: Run focused tests in both shells**

Expected: surface, references, consumers, installer, validator, registry, and product-doc
categories GREEN. Evidence and manifest remain the only canonical-state failures.

- [x] **Step 7: Append deletion/rewrite evidence and checkpoint**

Record all deleted source hashes, every direct-doc before/after hash, exact scan output, test
counts, installed OMP version, and staged count zero in the changelog.

---

### Task 5: Materialize hash-linked evidence and transition only T-00.3 authority

**Files:**

- Create: `docs/evidence/phase-00/T-00.3/conclusion.yml`
- Modify: `docs/evidence/phase-00/manifest.yml`
- Modify: `scripts/tests/phase00-t003.Tests.ps1`
- Modify: `codex-phase00-t003-authoritative-rebuild-changelog-for-opus5.md`

**Interfaces:**

- Produces: one non-circular conclusion artifact; manifest artifact path
  `docs/evidence/phase-00/T-00.3/conclusion.yml`.
- Destination hashes exclude the conclusion, manifest, and changelog to avoid self/circular hashes.

- [x] **Step 1: Compute destination hashes from disk**

Use this exact set:

```powershell
$destinations = @(
  'docs/policies/README.md',
  'docs/policies/context-budget.md',
  'docs/policies/model-routing.md',
  'docs/policies/quality-gates.md',
  'template/.omp/AGENTS.md',
  'template/.omp/commands/quick.md',
  'template/.omp/commands/standard.md',
  'template/.omp/commands/orchestrated.md',
  'template/.omp/agents/tech-lead.md',
  'template/.omp/agents/explorer.md',
  'template/.omp/agents/implementer.md',
  'template/.omp/agents/verifier.md',
  'template/.omp/agents/reviewer.md',
  'scripts/install-template.ps1',
  'scripts/validate-template.ps1'
)
$destinations | ForEach-Object {
  [pscustomobject]@{ path=$_; sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $_).Hash }
}
```

Copy the emitted values verbatim into the conclusion. The validator recomputes them.

- [x] **Step 2: Write the strict conclusion schema**

Use these top-level values:

```yaml
schema_version: 1
phase: "00"
task: T-00.3
status: PASS
provider_calls: 0
parallel_mode: DISABLED
```

Include all five exact legacy source rows from the approved design. Include disposition rows
covering, at minimum:

- context: components, retrieval order, degradation prevention, offload candidates;
- escalation: worker-to-main, main-to-user, do-not-escalate;
- model routing: authority, five old roles, constraints, effort mapping, customization;
- quality gates: six gates, default matrix, override rule, selection owner;
- workflow sizing: Quick, Standard, Orchestrated, tie-break, risk levels, overrides.

Use only `REHOMED` or `SUPERSEDED`. The required supersessions are:

- five-required-role model claim -> four required workers plus optional Tech Lead alias;
- portable concrete-model claim -> environment-owned mapping;
- larger-workflow tie-break -> independence boundary;
- Reviewer self-selection -> main-session task-packet selection;
- `.task/` offload as universal -> non-isolated only; OMP artifact manager for isolated work;
- spawned-Tech-Lead escalation audience -> main session.

Add exact check outcomes for deleted surface, zero dangling runtime references, installer
retirement, registry resolution, direct-doc scan, cross-shell focused tests, and staged count.

- [x] **Step 3: Transition the manifest atomically with the evidence**

Replace only the T-00.3 block with:

```yaml
  - id: T-00.3
    kind: foundation
    state: PASS
    depends_on: []
    artifacts: [docs/evidence/phase-00/T-00.3/conclusion.yml]
    decision: "Five inert policy YAML sources removed from the installed surface; canonical content re-homed to real consumers and human references; chars/4 budget checks remain advisory, not exact token enforcement"
```

Before and after the patch, serialize every non-T-00.3 manifest row and confirm it is identical.
Explicitly confirm E3-M remains `DEFERRED_PARALLEL_DISABLED` and root parallel mode remains
`DISABLED`.

- [x] **Step 4: Run focused GREEN and all mutation controls in both shells**

Expected: zero failures. The canonical contract emits all nine PASS codes. Every mutation
produces its pre-registered failure code.

- [x] **Step 5: Run the direct validator once in each shell**

Expected at this checkpoint: exit 0. Any advisory token warning requires reducing duplicated
prompt prose or documenting a pre-existing under-target file; do not raise thresholds.

- [x] **Step 6: Append authority evidence and hashes to the changelog**

Record conclusion hash, manifest before/after hash, destination 15/15 hash verification,
focused test counts, validator summaries, unchanged E3 state, and zero provider calls.

---

### Task 6: Full cross-shell verification and final Opus-ready ledger

**Files:**

- Modify: `codex-phase00-t003-authoritative-rebuild-changelog-for-opus5.md`
- Modify: `docs/superpowers/plans/2026-08-09-phase-00-t003-authoritative-policy-rehoming-plan.md` (checkboxes only)

**Interfaces:**

- Produces: final local verification state and one self-contained later-review packet.

- [x] **Step 1: Run the complete Phase 00 suite in PowerShell 7**

```powershell
pwsh -NoProfile -Command '$files=Get-ChildItem -LiteralPath scripts/tests -Filter "phase00*.Tests.ps1" | Sort-Object Name | Select-Object -ExpandProperty FullName; $r=Invoke-Pester -Script $files -PassThru; "TOTAL=$($r.TotalCount) PASSED=$($r.PassedCount) FAILED=$($r.FailedCount)"; if($r.FailedCount -ne 0){exit 1}'
```

Expected: exit 0 and `FAILED=0`.

- [x] **Step 2: Run the complete Phase 00 suite in Windows PowerShell 5.1**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '$files=Get-ChildItem -LiteralPath scripts/tests -Filter "phase00*.Tests.ps1" | Sort-Object Name | Select-Object -ExpandProperty FullName; $r=Invoke-Pester -Script $files -PassThru; "TOTAL=$($r.TotalCount) PASSED=$($r.PassedCount) FAILED=$($r.FailedCount)"; if($r.FailedCount -ne 0){exit 1}'
```

Expected: exit 0 and `FAILED=0`.

- [x] **Step 3: Run direct validation in both shells**

Run `scripts/validate-template.ps1` under both shells. Expected: exit 0, zero failed checks,
and no policy-file required/non-empty check.

- [x] **Step 4: Recompute final integrity**

Verify:

- design and plan hashes;
- all five legacy source rows in conclusion;
- 15/15 destination hashes;
- exact four reference docs;
- zero retired installed files and dangling prompt references;
- all registry destinations exist and superseded paths are absent;
- conclusion and manifest contract PASS;
- every non-T-00.3 manifest row unchanged;
- `parallel_mode: DISABLED`, E3-M deferred;
- no E3-I/E3-L Attempt 6 artifact;
- branch `main`, expected HEAD, and staged count zero;
- frozen P00-CX-028 artifact hashes remain unchanged.

- [x] **Step 5: Finalize the English Opus changelog**

The final file must contain:

1. executive verdict and provisional peer status;
2. authority hierarchy and approved scope;
3. old source inventory with SHA-256/Git blobs;
4. complete section-level REHOMED/SUPERSEDED table;
5. created/modified/deleted ledger with before/after hashes and line anchors;
6. RED-to-GREEN chronology and mutation results;
7. evidence/manifest state and unchanged E3 authority;
8. both-shell test and validator output;
9. frozen/unchanged hashes, Git state, and no-provider proof;
10. exclusions and residual risks;
11. numbered review questions for Opus requiring `ACCEPT T-00.3` or exact objections.

Report the changelog's own final SHA-256 outside the file because self-hashing is impossible.

- [x] **Step 6: Self-review and close the local plan only**

Scan design, plan, evidence, and changelog for standard unfinished-marker patterns,
contradictory status, stale hashes, and ambiguous authority claims. Mark every plan checkbox
complete only after its evidence exists. Do not describe Opus peer review as complete.

- [x] **Step 7: Final checkpoint instead of committing**

Confirm staged count zero. Do not stage or commit. Report the exact files, final changelog path
and hash, tests, local manifest state, non-claims, and the fact that Opus review remains pending.
