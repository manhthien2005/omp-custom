# Reproducible Evidence Byte Integrity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore every uniquely recoverable historical evidence byte sequence, preserve those bytes across Git checkouts, and prove the repaired repository from a fresh local clone.

**Architecture:** A fail-closed PowerShell 7.4 CLI reads the existing post-cleanup snapshot, classifies raw working-tree, index, or HEAD bytes, and applies only uniquely hash-matching EOL reconstructions. Root `.gitattributes` rules disable EOL conversion only for historical/evidence directories; the existing validator plus a clean local clone prove that the committed blobs reproduce the accepted bytes.

**Tech Stack:** PowerShell 7.4, .NET SHA-256 and strict UTF-8 APIs, Git attributes and plumbing commands, existing repository validator and self-contained PowerShell tests.

**Spec:** `docs/superpowers/specs/2026-08-15-reproducible-byte-integrity-design.md`

## Global Constraints

- Run every repair and test command with PowerShell 7.4 or newer.
- Use `docs/audit/claude-preflight-2026-08-14/02-POST-CLEANUP-CANDIDATE-SNAPSHOT.jsonl` as the only source of pre-commit SHA-256 values.
- Do not update evidence manifests, packet hashes, snapshot hashes, selected runtime files, or product behavior to make validation pass.
- Restore only candidates whose raw SHA-256 equals the existing snapshot SHA-256 exactly.
- Preserve the closed five-path limitation set and its accepted Git-LF hashes exactly as specified in Task 1.
- Default CLI behavior is read-only; writes require `-Apply` and a fully valid preflight plan.
- Preserve ordinary text diffs by using `-text`, not the Git `binary` macro.
- Do not make provider calls, run live installation, push, create a PR, or delete the source branch before clean-clone verification is green.
- Keep `codex/topic03-agent-topology` until every acceptance check succeeds.

---

## File Map

| Path | Responsibility |
|---|---|
| `scripts/repair-evidence-byte-integrity.ps1` | Read-only planner, guarded apply transaction, and working-tree/index/HEAD verifier |
| `scripts/tests/evidence-byte-integrity.Tests.ps1` | Disposable-fixture coverage for classification, refusal, rollback, and Git-source verification |
| `.gitattributes` | Disable EOL normalization for byte-bound evidence, audit, and archived-review paths |
| `docs/audit/claude-preflight-2026-08-14/reports/byte-integrity-recovery.md` | Record root cause, recovered counts, five unrecoverable paths, and non-claims |
| `codex-reproducible-byte-integrity-changelog.md` | Record implementation decisions, commands, outputs, and final local integration state |
| 132 existing snapshot paths | Restore exact historical bytes; no normalized-text change |

---

### Task 1: Fail-Closed Byte-Integrity Planner and Repair CLI

**Files:**
- Create: `scripts/repair-evidence-byte-integrity.ps1`
- Create: `scripts/tests/evidence-byte-integrity.Tests.ps1`

**Interfaces:**
- Consumes: repository root, JSONL snapshot path, source selector, and optional apply authorization.
- Produces: CLI parameters
  `-RepositoryRoot <string>`, `-SnapshotPath <string>`,
  `-Source WorkingTree|Index|Head`, `-Apply`, and `-Json`.
- Produces: `New-EvidenceByteIntegrityPlan -RepositoryRoot <string> -SnapshotPath <string> -Source <string>` returning one `PSCustomObject` with `Status`, `Counts`, and `Entries`.
- Produces: `Invoke-EvidenceByteIntegrityRepair -Plan <object> -WriteBytes <scriptblock>` returning a post-write plan with `Counts.Written` and rollback diagnostics; the writer parameter defaults to `[IO.File]::WriteAllBytes`.
- Exit codes: `0` for `PASS`, `2` for read-only `REPAIR_REQUIRED`, and `1` for `FAIL`.

- [ ] **Step 1: Write the focused test harness and synthetic snapshot fixture**

Create a self-contained PowerShell 7.4 test that uses only guarded system-temp directories. The fixture must contain exact, all-CRLF, CRLF-with-final-LF, and invalid entries:

```powershell
#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$repairScript = Join-Path $repositoryRoot 'scripts\repair-evidence-byte-integrity.ps1'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-byte-integrity-test-'
$tempRoots = [Collections.Generic.List[string]]::new()
$script:Assertions = 0
$utf8 = [Text.UTF8Encoding]::new($false)

function Assert-ByteIntegrity {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Get-TestSha256 {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    return [Convert]::ToHexString(
        [Security.Cryptography.SHA256]::HashData($Bytes)
    ).ToLowerInvariant()
}

function Write-TestBytes {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][byte[]]$Bytes)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    [IO.File]::WriteAllBytes($Path, $Bytes)
}

function New-TestSnapshotEntry {
    param([string]$Path, [byte[]]$ExpectedBytes)
    return [ordered]@{
        record_type = 'candidate_snapshot_entry'
        status = '??'
        path = $Path
        current_exists = $true
        current_bytes = $ExpectedBytes.Length
        current_sha256 = Get-TestSha256 -Bytes $ExpectedBytes
        baseline_sha256 = $null
    }
}
```

The test body must make these assertions:

1. missing repair script fails with a clear message;
2. default invocation does not alter bytes;
3. exact LF bytes classify as `exact`;
4. LF bytes whose expected hash is all-CRLF classify as `recoverable`;
5. LF bytes whose expected hash is CRLF-with-final-LF classify as `recoverable`;
6. read-only repairable state exits `2` with `REPAIR_REQUIRED`;
7. `-Apply` writes both recoverable candidates and exits `0`;
8. post-apply preflight reports no recoverable paths;
9. a rooted snapshot path entry is rejected;
10. a `../` snapshot path entry is rejected;
11. a missing file is rejected before any write;
12. an unexpected content mismatch is rejected before any write;
13. a valid repairable file remains unchanged when another entry is invalid;
14. a simulated second-write failure rolls back the first write;
15. `-Apply -Source Index` is refused;
16. after adding `-text` and staging fixture files, `-Source Index` reports exact bytes;
17. a mutated closed-limitation path is rejected; and
18. cleanup refuses any path outside the guarded temp prefix.

End with:

```powershell
Write-Host "PASS: evidence byte integrity ($script:Assertions assertions)." -ForegroundColor Green
```

- [ ] **Step 2: Run the new test and verify the RED state**

Run:

```powershell
pwsh -NoLogo -NoProfile -File scripts/tests/evidence-byte-integrity.Tests.ps1
```

Expected: exit `1` and a message containing `repair-evidence-byte-integrity.ps1 is missing`.

- [ ] **Step 3: Add the CLI contract and closed limitation map**

Start `scripts/repair-evidence-byte-integrity.ps1` with:

```powershell
#Requires -Version 7.4
[CmdletBinding()]
param(
    [string]$RepositoryRoot = '.',
    [string]$SnapshotPath = 'docs/audit/claude-preflight-2026-08-14/02-POST-CLEANUP-CANDIDATE-SNAPSHOT.jsonl',
    [ValidateSet('WorkingTree', 'Index', 'Head')][string]$Source = 'WorkingTree',
    [switch]$Apply,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:StrictUtf8 = [Text.UTF8Encoding]::new($false, $true)
$script:LimitationHashes = [ordered]@{
    'docs/archive/reviews/opus5-response-to-gpt56-counter-review.md' =
        '5c1f4ed33f3b9e57001a54a81dfc55f835e11521d19ce8bde145056ed1477c2b'
    'docs/evidence/phase-00/E3-J/raw/J1-attempt-002.run.json' =
        'b08da68322a73112e1495aa1bd888dadde7c1dde608add5c3632401c07e532b5'
    'docs/evidence/phase-00/E3-J/raw/J1-attempt-003.run.json' =
        'e348796c0d7323a920fde8ac90de5daae2e8fa898978a233fa09a0ff89cc7b59'
    'docs/evidence/phase-00/E3-J/raw/J1.run.json' =
        '27afe78ce8d9daec2f0a0cd058829428156a50a2d0e090ed81581bd8bbdfe76a'
    'spec/phases/phase-00-foundation.md' =
        'fd01490b089317f6253e4426a431af3d9275cffafd0ce56a200c4a02d2758b9b'
}
```

Define these exact helpers:

```powershell
function Get-ByteIntegritySha256([byte[]]$Bytes) { }
function Resolve-ByteIntegrityChildPath([string]$Root, [string]$RelativePath) { }
function Get-GitObjectBytes([string]$Root, [string]$ObjectExpression) { }
function Get-ByteIntegritySourceBytes(
    [string]$Root, [string]$RelativePath, [string]$Source
) { }
function Get-ByteIntegrityCandidates([byte[]]$CurrentBytes) { }
function Read-ByteIntegritySnapshot([string]$SnapshotLiteralPath) { }
function New-EvidenceByteIntegrityPlan(
    [string]$RepositoryRoot, [string]$SnapshotPath, [string]$Source
) { }
function Invoke-EvidenceByteIntegrityRepair(
    [object]$Plan,
    [scriptblock]$WriteBytes = { param($Path, $Bytes) [IO.File]::WriteAllBytes($Path, $Bytes) }
) { }
```

`Resolve-ByteIntegrityChildPath` must reject rooted paths, `..` segments, and resolved paths that
do not start with the resolved repository root plus a directory separator. `Get-GitObjectBytes`
must use `Diagnostics.ProcessStartInfo.ArgumentList` and copy raw stdout to a `MemoryStream`; never
send blob bytes through the PowerShell text pipeline.

- [ ] **Step 4: Implement deterministic EOL candidate classification**

Use strict UTF-8 decoding and exactly these two reconstruction shapes:

```powershell
$text = $script:StrictUtf8.GetString($CurrentBytes)
$lf = $text.Replace("`r`n", "`n")
$allCrlfText = $lf.Replace("`n", "`r`n")
$finalLfText = if ($lf.EndsWith("`n", [StringComparison]::Ordinal)) {
    $lf.Substring(0, $lf.Length - 1).Replace("`n", "`r`n") + "`n"
} else {
    $allCrlfText
}
$allCrlfBytes = $script:StrictUtf8.GetBytes($allCrlfText)
$finalLfBytes = $script:StrictUtf8.GetBytes($finalLfText)
```

For each snapshot entry, compare raw bytes first. If raw does not match, de-duplicate candidate
byte arrays by SHA-256 and accept a repair only when exactly one candidate hash equals
`current_sha256`. A nonmatching path in `$script:LimitationHashes` is `unrecoverable` only when its
current raw hash equals the closed accepted Git-LF hash. Every other nonmatch is `invalid`.

The returned plan must have this closed shape:

```powershell
[pscustomobject]@{
    SchemaVersion = 1
    RecordType = 'evidence_byte_integrity_plan'
    Status = 'PASS' # PASS | REPAIR_REQUIRED | FAIL
    RepositoryRoot = $resolvedRoot
    SnapshotPath = $resolvedSnapshot
    Source = $Source
    Counts = [pscustomobject]@{
        Exact = 0
        Recoverable = 0
        Unrecoverable = 0
        Missing = 0
        Invalid = 0
        Ambiguous = 0
        Written = 0
    }
    Entries = @($entries)
    Errors = @($errors)
}
```

- [ ] **Step 5: Implement two-phase apply with rollback**

Refuse `-Apply` unless `Source` is `WorkingTree`, the plan has no missing/invalid/ambiguous entry,
and every recoverable entry includes both `OriginalBytes` and `CandidateBytes`. Keep an in-memory
journal of original bytes. Call the injected `$WriteBytes` block for each candidate; focused tests
inject a block that throws on its second invocation. On any write or post-write hash failure,
restore every written path in reverse order with `[IO.File]::WriteAllBytes` and return `FAIL` with
a rollback result for each path.

After successful writes, rebuild the working-tree plan and require:

```powershell
$post.Counts.Recoverable -eq 0 -and
$post.Counts.Missing -eq 0 -and
$post.Counts.Invalid -eq 0 -and
$post.Counts.Ambiguous -eq 0
```

Set `Counts.Written` to the number of restored paths. JSON output must contain only the serialized
plan; human output must print one summary line and any error entries. Guard the CLI entrypoint with
`if ($MyInvocation.InvocationName -ne '.')` so the focused test can dot-source the functions
without executing the CLI.

- [ ] **Step 6: Run focused tests to verify GREEN**

Run:

```powershell
pwsh -NoLogo -NoProfile -File scripts/tests/evidence-byte-integrity.Tests.ps1
```

Expected: exit `0` and `PASS: evidence byte integrity (18 assertions).`

- [ ] **Step 7: Prove the live read-only RED inventory without writing**

Run:

```powershell
pwsh -NoLogo -NoProfile -File scripts/repair-evidence-byte-integrity.ps1 -Json
```

Expected: exit `2`, `Status = REPAIR_REQUIRED`, and counts
`Exact=838`, `Recoverable=132`, `Unrecoverable=5`, `Missing=0`, `Invalid=0`, `Ambiguous=0`,
`Written=0`.

- [ ] **Step 8: Commit the tested planner and CLI**

```powershell
git add -- scripts/repair-evidence-byte-integrity.ps1 scripts/tests/evidence-byte-integrity.Tests.ps1
git diff --cached --check
git commit -m "test: add fail-closed evidence byte repair"
```

---

### Task 2: Preserve Git Bytes and Restore the Real Evidence Set

**Files:**
- Create: `.gitattributes`
- Modify: 132 paths selected by the Task 1 plan
- Create: `docs/audit/claude-preflight-2026-08-14/reports/byte-integrity-recovery.md`
- Create: `codex-reproducible-byte-integrity-changelog.md`

**Interfaces:**
- Consumes: Task 1 CLI and the approved design counts.
- Produces: working tree and staged index with 970 exact, 0 recoverable, 5 closed limitations, and no errors.
- Produces: root Git attributes that report `text: unset` for every tracked path under the three protected directories.

- [ ] **Step 1: Add the narrow byte-preservation policy**

Create `.gitattributes` with exactly:

```gitattributes
# Hash-bound evidence and historical audit records must retain repository bytes.
/docs/evidence/** -text
/docs/audit/** -text
/docs/archive/reviews/** -text
```

Verify representative paths:

```powershell
git check-attr text -- `
  docs/evidence/phase-00/E3-I/raw/session-a-attempt-007.run.json `
  docs/audit/claude-preflight-2026-08-14/00-START-HERE.md `
  docs/archive/reviews/opus5-response-to-gpt56-counter-review.md
```

Expected: each row ends with `text: unset`.

- [ ] **Step 2: Re-run preflight immediately before applying**

```powershell
pwsh -NoLogo -NoProfile -File scripts/repair-evidence-byte-integrity.ps1 -Json
```

Expected: exit `2` and the exact `838 / 132 / 5 / 0 / 0 / 0` inventory from Task 1.

- [ ] **Step 3: Apply the precomputed repair transaction**

```powershell
pwsh -NoLogo -NoProfile -File scripts/repair-evidence-byte-integrity.ps1 -Apply -Json
```

Expected: exit `0`, `Status = PASS`, `Written=132`, `Exact=970`, `Recoverable=0`,
`Unrecoverable=5`, and zero missing/invalid/ambiguous entries.

- [ ] **Step 4: Verify no normalized-text content changed**

Run:

```powershell
git diff --ignore-space-at-eol --exit-code -- docs/evidence docs/archive/reviews
```

Expected: exit `0` with no diff output. Then rerun the CLI without `-Apply`; expect
`970 exact / 0 recoverable / 5 unrecoverable / 0 errors`.

- [ ] **Step 5: Write the provenance limitation report**

Create `docs/audit/claude-preflight-2026-08-14/reports/byte-integrity-recovery.md` with these
sections and exact claims:

```markdown
# Historical Evidence Byte-Integrity Recovery

## Result

- 975 existing snapshot entries inspected.
- 838 entries already matched raw bytes.
- 132 entries were restored to their existing snapshot SHA-256 values.
- 5 entries remain normalized-text-equivalent but are not raw-byte-reproducible.
- No snapshot, manifest, or pinned SHA-256 value was changed.

## Root cause

The original candidate was hashed while generated CRLF or mixed-EOL files were untracked.
With `core.autocrlf=input` and no repository attributes, Git stored LF blobs while the original
working tree retained pre-clean-filter bytes. A later checkout exposed the mismatch.

## Closed limitations

- `docs/archive/reviews/opus5-response-to-gpt56-counter-review.md` — `5c1f4ed33f3b9e57001a54a81dfc55f835e11521d19ce8bde145056ed1477c2b`
- `docs/evidence/phase-00/E3-J/raw/J1-attempt-002.run.json` — `b08da68322a73112e1495aa1bd888dadde7c1dde608add5c3632401c07e532b5`
- `docs/evidence/phase-00/E3-J/raw/J1-attempt-003.run.json` — `e348796c0d7323a920fde8ac90de5daae2e8fa898978a233fa09a0ff89cc7b59`
- `docs/evidence/phase-00/E3-J/raw/J1.run.json` — `27afe78ce8d9daec2f0a0cd058829428156a50a2d0e090ed81581bd8bbdfe76a`
- `spec/phases/phase-00-foundation.md` — `fd01490b089317f6253e4426a431af3d9275cffafd0ce56a200c4a02d2758b9b`

## Non-claims

- The five unavailable mixed-EOL byte sequences were not reconstructed or replaced.
- Passing normalized-text comparison is not claimed as raw-byte identity.
- No provider, live install, remote repository, or external backup was used.
```

- [ ] **Step 6: Write the implementation changelog**

Create `codex-reproducible-byte-integrity-changelog.md` with sections `Baseline`, `Root cause`,
`Files changed`, `RED evidence`, `GREEN evidence`, `Fresh-clone evidence`, `Limitations`, and
`Git integration`. Record the exact commands and observed counts. Under `Fresh-clone evidence`,
write `Status: NOT_RUN — Task 3 owns this proof.`; do not claim a clone result before Task 3.

- [ ] **Step 7: Run current-tree verification**

Run all commands separately and inspect every exit code:

```powershell
pwsh -NoLogo -NoProfile -File scripts/tests/evidence-byte-integrity.Tests.ps1
pwsh -NoLogo -NoProfile -File scripts/repair-evidence-byte-integrity.ps1 -Json
pwsh -NoLogo -NoProfile -File scripts/validate-template.ps1
pwsh -NoLogo -NoProfile -File docs/audit/claude-preflight-2026-08-14/capture-candidate-snapshot.Tests.ps1
git diff --check
```

Expected:

- focused test: 18 assertions pass;
- byte-integrity preflight: `970 / 0 / 5` with no error class;
- full validator: `356 passed, 1 warning, 0 failed`;
- snapshot test: `Audit snapshot tests: 22 PASS`;
- whitespace check: exit `0`.

- [ ] **Step 8: Stage only approved paths and verify index bytes**

```powershell
$restoredPaths = @(git diff --name-only -- docs/evidence docs/archive/reviews)
if ($restoredPaths.Count -ne 132) {
    throw "Expected exactly 132 restored paths, got $($restoredPaths.Count)."
}
git add -- $restoredPaths
git add -- .gitattributes `
    docs/audit/claude-preflight-2026-08-14/reports/byte-integrity-recovery.md `
    codex-reproducible-byte-integrity-changelog.md
pwsh -NoLogo -NoProfile -File scripts/repair-evidence-byte-integrity.ps1 -Source Index -Json
git diff --cached --check
git diff --cached --name-status
```

Expected index preflight: `970 exact / 0 recoverable / 5 unrecoverable / 0 errors`. Confirm that
`git diff --cached --ignore-space-at-eol --exit-code -- docs/evidence docs/archive/reviews` exits
`0`; this proves the staged historical changes are EOL-only.

- [ ] **Step 9: Commit the byte-preserving repair**

```powershell
git commit -m "fix: preserve historical evidence bytes"
```

Do not delete the source branch after this commit; Task 3 owns that gate.

---

### Task 3: Fresh-Clone Proof and Local Branch Finalization

**Files:**
- Modify: `codex-reproducible-byte-integrity-changelog.md`
- Delete: none

**Interfaces:**
- Consumes: committed Task 2 tree and local `main`.
- Produces: fresh-clone verification evidence, clean local `main`, and safe deletion of the fully merged source branch.

- [ ] **Step 1: Verify committed HEAD bytes before cloning**

```powershell
pwsh -NoLogo -NoProfile -File scripts/repair-evidence-byte-integrity.ps1 -Source Head -Json
git status --short --branch
```

Expected: HEAD reports `970 exact / 0 recoverable / 5 unrecoverable / 0 errors`; status is clean.

- [ ] **Step 2: Create a guarded disposable local clone**

Use this exact safety shape:

```powershell
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$clonePrefix = 'omp-byte-integrity-clone-'
$cloneRoot = Join-Path $tempBase ($clonePrefix + [guid]::NewGuid().ToString('N'))
git clone --no-hardlinks --local . $cloneRoot
if ($LASTEXITCODE -ne 0) { throw 'Local verification clone failed.' }
```

Do not reuse `.claude/worktrees/` or an existing directory.

- [ ] **Step 3: Run the complete acceptance gate in the clone**

Run with `workdir` equal to `$cloneRoot`:

```powershell
pwsh -NoLogo -NoProfile -File scripts/repair-evidence-byte-integrity.ps1 -Json
pwsh -NoLogo -NoProfile -File scripts/repair-evidence-byte-integrity.ps1 -Source Head -Json
pwsh -NoLogo -NoProfile -File scripts/tests/evidence-byte-integrity.Tests.ps1
pwsh -NoLogo -NoProfile -File scripts/validate-template.ps1
pwsh -NoLogo -NoProfile -File docs/audit/claude-preflight-2026-08-14/capture-candidate-snapshot.Tests.ps1
git diff --check
git status --porcelain=v1 -uall
```

Expected:

- working tree and HEAD each report `970 / 0 / 5` and exit `0`;
- focused test reports 18 assertions;
- full validator reports `356 passed, 1 warning, 0 failed`;
- snapshot test reports 22 assertions;
- `git diff --check` exits `0`;
- clone status is empty.

- [ ] **Step 4: Verify the audit packet's documented 11-of-12 state**

Parse `PACKET-SHA256.txt` and compute raw hashes. Require exactly 11 matches and exactly one mismatch
named `capture-candidate-snapshot.ps1`; this is the already documented minimal fix from `63b578d`.
Any other mismatch fails the gate.

```powershell
$packetRoot = Join-Path $cloneRoot 'docs\audit\claude-preflight-2026-08-14'
$rows = @(Get-Content -LiteralPath (Join-Path $packetRoot 'PACKET-SHA256.txt') |
    Where-Object { $_ -match '^([0-9A-Fa-f]{64})\s+(.+)$' } |
    ForEach-Object {
        $expected = $Matches[1].ToLowerInvariant()
        $name = $Matches[2]
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (
            Join-Path $packetRoot $name
        )).Hash.ToLowerInvariant()
        [pscustomobject]@{ Name = $name; Match = $expected -ceq $actual }
    })
$matched = @($rows | Where-Object Match).Count
$mismatched = @($rows | Where-Object { -not $_.Match })
if ($matched -ne 11 -or $mismatched.Count -ne 1 -or
    $mismatched[0].Name -cne 'capture-candidate-snapshot.ps1') {
    throw "Unexpected packet integrity result: $matched/12 matched."
}
```

- [ ] **Step 5: Remove only the guarded disposable clone**

```powershell
$resolved = [IO.Path]::GetFullPath($cloneRoot).TrimEnd('\', '/')
$parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
$leaf = [IO.Path]::GetFileName($resolved)
if ($parent -cne $tempBase -or
    -not $leaf.StartsWith($clonePrefix, [StringComparison]::Ordinal)) {
    throw "Refusing unsafe clone cleanup target: $resolved"
}
Remove-Item -LiteralPath $resolved -Recurse -Force
```

- [ ] **Step 6: Record fresh-clone evidence and commit the changelog**

Replace the pending fresh-clone section with the actual commit SHA, commands, counts, packet result,
and cleanup result. Then run:

```powershell
git add -- codex-reproducible-byte-integrity-changelog.md
git diff --cached --check
git commit -m "docs: record clean-clone byte integrity proof"
```

- [ ] **Step 7: Re-run final verification on local `main`**

```powershell
pwsh -NoLogo -NoProfile -File scripts/repair-evidence-byte-integrity.ps1 -Json
pwsh -NoLogo -NoProfile -File scripts/validate-template.ps1
pwsh -NoLogo -NoProfile -File docs/audit/claude-preflight-2026-08-14/capture-candidate-snapshot.Tests.ps1
git diff --check
git status --short --branch
```

Expected: the same green counts as the clone and a clean `main` worktree.

- [ ] **Step 8: Delete the fully merged source branch locally**

Only after Step 7 is green:

```powershell
git merge-base --is-ancestor codex/topic03-agent-topology main
git branch -d codex/topic03-agent-topology
```

Expected: the ancestry command exits `0`, branch deletion succeeds without force, `main` remains
checked out, and no push occurs.
