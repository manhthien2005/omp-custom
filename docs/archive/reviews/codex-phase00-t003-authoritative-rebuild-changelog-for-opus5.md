# Codex Phase 00 T-00.3 Authoritative Rebuild Ledger for Opus 5

Status: `PROVISIONAL_PENDING_OPUS_REVIEW`  
Execution mode: Codex-only, inline in the user-authorized dirty `main` worktree  
Opened: `2026-08-09T20:58:11.1243761+07:00`

## Scope and authority

This ledger records every Codex mutation and the evidence used to rebuild Phase 00 task
`T-00.3`. It is intended for an equal, independent Opus 5 review when quota is available.
Nothing in this ledger asks Opus to defer to Codex; every conclusion remains challengeable
against the cited files, hashes, and test output.

Approved design:

- Path: `docs/superpowers/specs/2026-08-09-phase-00-t003-authoritative-policy-rehoming-design.md`
- SHA-256: `EA56CD82EBE1D59A40AC3F549D39F57DF66D3B8558D024252333C7E2E71A5A4F`

Approved implementation plan:

- Path: `docs/superpowers/plans/2026-08-09-phase-00-t003-authoritative-policy-rehoming-plan.md`
- SHA-256: `56D94FD194A88CEFACB2C9AA2E6F654DB6136DE13F287EAA7B617B3904BA19E3`

Authority order used by the approved design:

1. `spec/key/04-decision-log.md` (`KD-001`)
2. `spec/phases/phase-00-foundation.md` (`T-00.3`)
3. `spec/04-workflow-sizing.md`, `spec/05-context-and-token-model.md`,
   `spec/09-model-routing.md`, `spec/11-skills-rules-and-quality-gates.md`, and
   `spec/15-security-and-failure-recovery.md`
4. Verified OMP behavior and compatibility evidence
5. The five legacy policy YAML files as historical input only
6. Existing implementation and product documentation

## Non-authorizations

This work does **not** authorize or perform any of the following:

- provider calls;
- Attempt 6;
- Session B replay;
- E3-M execution;
- parallel-mode enablement;
- branch creation, worktree creation, staging, commit, push, pull request, reset, or checkout;
- unrelated cleanup outside the approved T-00.3 direct-consistency boundary;
- topology redesign or removal of the optional `tech-lead` alias.

## Round 1 — Pre-state lock and focused RED proof

### Repository identity

- Branch: `main`
- HEAD: `62fecf277dc9d5e47d06319387eac747462214c1`
- Staged paths before mutation: `0`
- Legacy policy files: `5`
- Legacy policy physical lines: `363`

### Locked legacy source identities

| Path | Lines | SHA-256 | Git blob at HEAD |
|---|---:|---|---|
| `template/.omp/policies/context-budget.yml` | 89 | `A3FE19A6C131F3A9F43EF2AC5156993437CDC07B0ABE6AF284FE6E966C2F03EE` | `f5591a7b7cd3e06efbd5431536ebd2391bdedd6d` |
| `template/.omp/policies/escalation.yml` | 52 | `49CB215BEEC2424C9274BBA285E2AD28B651A124AF1BF07102A925FDAEA5FD1F` | `c8e51d31baed0b2ce7ee000bd0be5deb3858e691` |
| `template/.omp/policies/model-routing.yml` | 61 | `67E7F80534AB66C57B13EF91AD88CABAE5518F8828E89C496B78AB9C4209F4A2` | `c73070c1e73737a6947b48eb84338b583e4aa663` |
| `template/.omp/policies/quality-gates.yml` | 105 | `69A8635F66C118D5BC12612E7D7B6F498E1886B7213F15613BE5A37B6370A1E2` | `47f6d06191a9e7b68f07da1903d96b931024fa30` |
| `template/.omp/policies/workflow-sizing.yml` | 56 | `603112590C993F9DEC61D17C32387C040C775C384B1D8656756170971703671B` | `195c1f836bfd62381099cd9633073db4a37c88bc` |

The SHA-256 values and Git blobs matched the approved design before any legacy source was
changed or removed.

### Mutation made

Created `scripts/tests/phase00-t003.Tests.ps1`. The five desired-state tests name the
observable breaks they protect:

1. the inert installed policy directory must be absent;
2. `docs/policies/` must contain exactly the four approved Markdown references;
3. installed agents and commands must not retain dangling policy-path or `policy:` references;
4. the durable `Test-Phase00T003PolicyRehomingContract` function must exist;
5. the durable contract must accept the canonical repository only when all categories pass.

No production implementation was changed before the RED run.

### Focused RED evidence

Commands:

```powershell
pwsh -NoProfile -Command "Invoke-Pester -Script scripts/tests/phase00-t003.Tests.ps1 -PassThru"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
  "Invoke-Pester -Script scripts/tests/phase00-t003.Tests.ps1 -PassThru"
```

Observed after one test-only correction that suppressed a missing-directory diagnostic while
preserving the intended assertion failure:

| Shell | Total | Passed | Failed | Skipped | Pester time |
|---|---:|---:|---:|---:|---:|
| PowerShell 7 (`pwsh`) | 5 | 0 | 5 | 0 | `00:00:00.4027476` |
| Windows PowerShell 5.1 (`powershell.exe`) | 5 | 0 | 5 | 0 | `00:00:00.7017373` |

Exact failing observations were identical in both shells:

- `removes the inert runtime directory`: expected `False`, observed `True`;
- `creates exactly four non-runtime policy reference files`: expected
  `context-budget.md,model-routing.md,quality-gates.md,README.md`, observed an empty set;
- `contains no dangling installed policy reference`: expected `0`, observed `2`;
- `exports the durable T-00.3 validator`: expected `True`, observed `False`;
- `accepts the canonical repository state`: failed at the same missing-validator assertion.

These are expected feature-absence failures, not syntax, import, or fixture errors. This proves
the focused test surface can detect the pre-implementation state.

All later ledger entries must append only facts already observed on disk. Historical entries
must not be silently rewritten if later evidence changes a conclusion.

### Round 1 checkpoint

- `scripts/tests/phase00-t003.Tests.ps1` SHA-256:
  `579FC022CC9E4C8A6B8CB8DB1A6B56EFE1F2ECAB47076EB692A33EEEB41C380A`
- Ledger SHA-256 immediately before this checkpoint entry:
  `0B29105D22E666E407316E516E0EB5A58FE185939B2BAE468F56A5BC70225277`
- Staged paths at checkpoint: `0`

The ledger hash is explicitly a pre-entry checkpoint because embedding a file's own final hash
inside that same file would be self-referential. Later rounds therefore record the immediately
preceding ledger hash and separately expose the final on-disk hash to the reviewer.

After the checkpoint evidence existed, Task 1 Steps 1–5 were marked complete in the execution
plan. The plan's resulting SHA-256 is
`6319D1DDEBEF6C59124A4BCFE8C2D7EFB8A1A038737617A6EDE7ED269C5ACC7C`; the ledger SHA-256
immediately before this status entry was
`1E7291A6581C469CC00D5E8352BD595EC9BF5A964DAD41E841945CE6E0BDFC18`.

## Round 2 — Durable fail-closed contract and controlled partial state

Timestamp: `2026-08-09T21:17:26.6787718+07:00`

### Evidence corrections made before locking the contract

Two shortened spec filenames in the initial authority list did not resolve on disk. They were
corrected to `spec/05-context-and-token-model.md` and
`spec/15-security-and-failure-recovery.md`. This is a path-accuracy correction, not an
authority or design change.

The approved plan also described every registry destination as a `local_components` row.
Direct inspection showed that `docs/policies/model-routing.md` is under `adopted_to` in
`registry/adoption-ledger.yml`, while the other destinations occur under `local_components`
and/or `adopted_to`. A RED regression test proved the original registry predicate rejected the
real ledger; the validator now recognizes both explicit destination fields and still requires
retired YAML paths to remain under `superseded_paths`.

### Mutations made

| File | Before SHA-256 | After SHA-256 | Exact responsibility / anchors |
|---|---|---|---|
| `scripts/lib/phase00-evidence.ps1` | `6CFCA69F96C12F8654AD704EED497CD714B19EEC4A0FCA770D6051F0FB403450` | `A9B12B92BA515C466C9D5D98A446DB8CEDF6B2F3ED1A8B11CE99DE477F34F888` | Locked five-source/disposition/destination constants at line 33; SHA helpers at line 115; strict conclusion parser at line 238; nine-category contract at line 447. The before hash is independently recorded as the final hash in `codex-phase00-p00-cx-028-correction-changelog-for-opus5.md`. |
| `scripts/validate-template.ps1` | `0CFC2A17BBA7BD860C278C3284199B0CDD6A921795C44D866A282D7FB9C3EDFB` | `81D157012B46A7A694D0C40863F2919B7A22C96029F4C30DECD90AAF87ADCC35` | Registered `Test-Phase00T003PolicyRehomingContract` at line 237. The before hash comes from the same prior correction ledger. |
| `scripts/tests/phase00-t003.Tests.ps1` | `579FC022CC9E4C8A6B8CB8DB1A6B56EFE1F2ECAB47076EB692A33EEEB41C380A` | `A9064AFFABABC5554764826CD4B219B8BC69912739EA39CF1FDD2FA2FC761A0A` | Pre-registered eight mutation/code pairs at line 6; added category cardinality, no-internal-error, registry-field, strict-parser positive, and six parser-negative controls. |
| `scripts/tests/phase00-wave-a.Tests.ps1` | `60490FF05AF73EBBD7EE5C9BDB6254D23810B86F1EE7B7199D7DBF949E3B7B8E` | `A8AD2B13EA2D368ACEAD7872A1066334722E028FCDD8AA98B5903FA503B2524D` | Changed five validators to six at lines 86–91 and required `P00-T003-MANIFEST` entrypoint output at line 350. The before hash comes from the prior correction ledger. |
| `docs/superpowers/plans/2026-08-09-phase-00-t003-authoritative-policy-rehoming-plan.md` | `6319D1DDEBEF6C59124A4BCFE8C2D7EFB8A1A038737617A6EDE7ED269C5ACC7C` | `2630448B65B549F168561E7F76794B132A22684565B9A7B5061ED9DE9BB05E4D` | Marked Task 2 evidence-backed steps complete and moved executable mutation fixtures to Task 5, where each mutated category can first prove a GREEN baseline. |

This ledger's SHA-256 immediately before the Round 2 entry was
`7BC1B02F099CB24463761BFB1225EB3528A658D0DA7C83075E4BCE009066ED96`.

### Contract shape

`Test-Phase00T003PolicyRehomingContract -RepositoryRoot <path>` always returns exactly one
result for each of these codes, even when artifacts are absent or malformed:

1. `P00-T003-SURFACE`
2. `P00-T003-REFERENCES`
3. `P00-T003-CONSUMERS`
4. `P00-T003-INSTALLER`
5. `P00-T003-VALIDATOR`
6. `P00-T003-REGISTRY`
7. `P00-T003-PRODUCT-DOCS`
8. `P00-T003-EVIDENCE`
9. `P00-T003-MANIFEST`

The strict parser accepts only the declared conclusion sections and rejects duplicate root
keys, duplicate source IDs, duplicate destination paths, unknown disposition states,
non-uppercase SHA-256 values, malformed Git blobs/line counts, tabs, unknown keys, empty
sections, and incomplete markers. No external YAML module was introduced.

### RED-to-partial chronology

- New parser/category tests before implementation: PowerShell 7 `0 passed / 13 failed`;
  Windows PowerShell 5.1 `0 passed / 13 failed`. Failures were missing exported behavior.
- The Wave A registration test before entrypoint registration: `25 passed / 1 failed / 26`
  in both shells; the sole failure was absent `P00-T003-MANIFEST` output.
- A PowerShell 7/Pester 3.4 incompatibility made native `Should Throw` fail even for an
  unconditional `throw`, while Windows PowerShell 5.1 passed the same probe. The parser tests
  now use an explicit cross-shell `try/catch` assertion helper; production behavior was not
  weakened.
- A new RED test caught an internal `Select-String -Pattern` binding error being surfaced as a
  category message. The minimal fix added the required line continuation; a durable test now
  rejects leaked binding/command-resolution errors.
- A new RED test caught the registry `adopted_to` omission described above; the minimal fix
  broadened only the recognized explicit destination fields.

Final controlled partial-state focused result:

| Shell | Total | Passed | Failed | Expected remaining direct failures |
|---|---:|---:|---:|---|
| PowerShell 7 | 15 | 11 | 4 | old directory, missing four docs, two dangling references, canonical 9-category acceptance |
| Windows PowerShell 5.1 | 15 | 11 | 4 | same |

Direct contract result in both shells: `9 results / 0 PASS / 9 FAIL`, with exactly the nine
pre-registered codes above and no internal execution error. After entrypoint registration,
both direct repository-validator runs emitted exactly nine `P00-T003-*` lines and exited `1`,
which is the required fail-closed state before Tasks 3–5 materialize the migration.

### Mutation-test sequencing decision

Executable repository mutation fixtures are intentionally not claimed complete in this round.
Running them while their baseline category is already FAIL would be tautological: the expected
code could pre-exist without the mutation. The eight mutation/code pairs are pre-registered now;
Task 5 must create a temp copy of the completed contract surface, prove the relevant category is
PASS before each mutation, then prove the named FAIL code appears afterward. The execution plan
was updated to make this evidence rule explicit rather than silently changing sequence.

Staged paths at the Round 2 checkpoint: `0`. No provider call, runtime experiment, E3 state
transition, branch/worktree operation, or Git mutation occurred.

## Round 3 — Authoritative content re-homed into real consumers

Timestamp: `2026-08-09T21:27:56.6467636+07:00`

### Created non-runtime references

| Path | Before | Lines | SHA-256 | Contract delivered |
|---|---|---:|---|---|
| `docs/policies/README.md` | `ABSENT` | 21 | `14BF081DC148463C4D670DC53FAD70F33BAAD540C88411B191E4F1AC555894BB` | Non-runtime status and five-source disposition index |
| `docs/policies/context-budget.md` | `ABSENT` | 68 | `B3FB28CFE1ABC3C7D8C0EBED874F079E9F4271E1D47F9AF1CD4372DCC5776400` | Seven provisional budgets, enforcement levels, packet/result prohibitions, retrieval, compaction, and isolation-aware offload |
| `docs/policies/model-routing.md` | `ABSENT` | 46 | `9E348E097D6CD65B102C97BDE160E30C4ECADCB7A74FB405FBC274B4E8ABD8A1` | Four required worker aliases, optional user Tech Lead alias, environment boundary, effort mapping, and E2 unknowns |
| `docs/policies/quality-gates.md` | `ABSENT` | 61 | `28E693652A34304DC85117C578F23017E2863E68F104AFF05849EA2A9D9F32B5` | Six definitions, exact risk matrix, main-session selection, packet delivery, Reviewer application, and override rule |

All four files state `OMP runtime: not loaded` and carry retired-source provenance. No
workflow-sizing or escalation duplicate reference was created: `spec/04` plus commands own the
first, while worker/main-session instructions own the second.

### Modified runtime consumers

| Path | Before SHA-256 | After SHA-256 | Lines after | Change |
|---|---|---|---:|---|
| `template/.omp/commands/quick.md` | `1EEC17539BE289087C9714622E4A7FCA0A377AE7474E7AD1BA3868E62AE6C628` | `F4E9081846368DA140923C8D51C7BAB079DA4B75577019A412735DBAC4A21731` | 67 | Provenance; target/scope boundary; restart-as-Standard escalation |
| `template/.omp/commands/standard.md` | `F9656F8904AC8ABC8DA8CC16D3D8C6BDC903A7939ABE83AA76649B29BCC2BEC1` | `F849485369F0E8EE6D7D816752D7CAD263DA5381EF8216C319B19091FCBB626B` | 96 | Independence-only Orchestrated boundary; exact gate matrix; role routing; escalation |
| `template/.omp/commands/orchestrated.md` | `5578CECEC5148B29483B511CBD1BD6677706321DADD84A068A4F79C0FB49A010` | `D88179FA0C27B9EEDF9EE59B5CD6A59B75FC426BCDAD18061209942C36012D12` | 110 | Mandatory independence; no de-escalation; exact gate matrix; role routing; bounded stop conditions |
| `template/.omp/agents/tech-lead.md` | `003B08124A4A0C1DA8204741C93EABE83506136047765739D6CBE0DE69B41D58` | `47B3060A725F9C41EA832E2CE8E7CBAEFCAFACB4137A9B4153C2819732016AD2` | 47 | Removed dangling pseudo-URI; inserted the two decisive sizing questions only |
| `template/.omp/agents/explorer.md` | `C6120803499E8DFECF49F88CB3ACE5D8D8080D2ECFD44871F7D9D881795C0103` | `EFF925B0CF199144F306AE8F40226F8087ECF45297B0CEB270E07C3E9DF3CAE6` | 50 | Bounded-investigation return; no guessed root cause |
| `template/.omp/agents/implementer.md` | `25465E0813369B3A0F630524D5E94C0A86260E27DD6F82AB7172273449F1E6AD` | `6090C229C4A6B9132B99F4540EA9788A2520BB358846C6ADC5482DD911E72A22` | 61 | Exact `failed` / `blocked` / `partial` outcomes |
| `template/.omp/agents/verifier.md` | `8258A71E62C0EB64E838B308804C81CAC97BC0BEF148D77193ECDEC253104F38` | `A3F49E18266587929D05B2DE28AD59D7B31E3832C20DAD5C201AB03348C449E0` | 56 | Uncovered-criterion and environment-failure boundary |
| `template/.omp/agents/reviewer.md` | `FB09B2CECB0E1C74D8D287AF62C3067E38692F95C449230EF891FA3812785B7D` | `7960C0C595A2B11AD5DFDC9C9F2A591C34F5CCFC2C0ADF43D5EA70F94E3C3DE3` | 67 | Selected-gates-only review; BLOCKING -> CHANGES_REQUESTED; no self-rewrite |
| `template/.omp/AGENTS.md` | `9B82D18402709C00748551AE29E499E84B650B34258D944889E223711B16F88E` | `3F194D81208872B6CDE4A51265156D06A8016810CAA9D24BF37B545E60848BBC` | 87 | User-selected command/size validation, workflow-specific isolation, compact packet/result rules, and main-to-user authority boundary |

Approximate `chars / 4` sizes after the edits are within the documented target for every modified
static component: AGENTS `1173`; Tech Lead `517`; Explorer `524`; Implementer `718`; Verifier
`555`; Reviewer `728`. No threshold was raised or padded to force a pass.

### Corrected normative anchors

| Path | Before SHA-256 | After SHA-256 | Exact T-00.3 change |
|---|---|---|---|
| `spec/04-workflow-sizing.md` | `AADBCD183E6A0AA6C60AA548E6FB62E240CC4CF505272342936ED889490EAB7C` | `8E9329E1A953028A8ACFFBFF8E2D6FC97F42CF5C6B595BD57A97A9E1FB78593F` | W-3 now says the YAML does not survive; section C and commands are authoritative |
| `spec/09-model-routing.md` | `B0DCD1401F287F9551062048B46D704E0D2B3636517433EADCC94DB2D4643430` | `AF1B7F54D98DDC4A2FB03DB1A6F95CFC4C44B75763DB347A1E85ECCF57DA2EFE` | OmniRoute contract now points to the Markdown reference and command boundaries |
| `spec/11-skills-rules-and-quality-gates.md` | `C1059F8A10530D749F6F4E417791ACA9827C385D989DDD49948F71E4DE31AB25` | `691B9D0E593FF1EC6C4C552D045742E7B6297E0DDF4364DDFB4DCA33CFDF2AE3` | Both delivery text and acceptance criterion name `docs/policies/quality-gates.md` |
| `spec/phases/phase-00-foundation.md` | `9E2E3532B307EA1166B9F5B754FD1D5C515BB02AA246C9BDAA2194A8C0CF476D` | `F0251A10AFE35BFA5EBF83FBBB99E18A05C47D79390D6ACD3198F307F3B7964C` | Corrected only the stale `03-token-quality-model.md` anchor to `03-agent-topology.md`; unrelated pre-existing edits were preserved |

### Cross-shell validator correction discovered during re-homing

PowerShell 7 accepted the context reference while Windows PowerShell 5.1 rejected it. A focused
RED test isolated the cause: BOM-less `.ps1` files are decoded differently by Windows PowerShell
5.1, so literal en-dash budget markers in the validator were not stable. The helper now contains
only ASCII source literals and checks the seven canonical table rows with regex `\u2013` escapes.
This preserves the spec's typography without relying on script-source encoding.

- `scripts/lib/phase00-evidence.ps1`:
  `A9B12B92BA515C466C9D5D98A446DB8CEDF6B2F3ED1A8B11CE99DE477F34F888` ->
  `A764121618A933D28AEB1FA17DBE826EB14AE9E4B55550BE9D7E2A5CA7428B92`
- `scripts/tests/phase00-t003.Tests.ps1`:
  `A9064AFFABABC5554764826CD4B219B8BC69912739EA39CF1FDD2FA2FC761A0A` ->
  `755A07AA99A55C3A57E96CBB72EF429E2094005516EA85602EB2ED399DF5D5D0`

### Verification checkpoint

Focused Pester in both shells: `16 total / 14 passed / 2 failed`. The two intended failures are
the still-present legacy directory and whole-repository canonical acceptance. Direct category
results are identical in both shells:

- PASS: `P00-T003-REFERENCES`, `P00-T003-CONSUMERS`, `P00-T003-REGISTRY`;
- FAIL by design until later tasks: `P00-T003-SURFACE`, `P00-T003-INSTALLER`,
  `P00-T003-VALIDATOR`, `P00-T003-PRODUCT-DOCS`, `P00-T003-EVIDENCE`,
  `P00-T003-MANIFEST`.

The installed prompt scan covered eight agent/command files and found `0` `policy:` or policy-path
references. `docs/policies/` contains exactly four files. The ledger SHA-256 immediately before
this Round 3 entry was
`2BB88A2B41C4B65F96DEEA03859CC14404FF2762B6A9D6383CDD3AA82FB5F32B`.
Staged paths remain `0`; no provider/runtime/E3/Git-authority operation occurred.

After the cited evidence existed, Task 3 Steps 1–9 were marked complete. The execution plan's
resulting SHA-256 is
`B742F59FF8850040E14D714E0F157ADFFCEF38C72D99475B35E44082278116B4`; the ledger SHA-256
immediately before this status entry was
`D8BC1C240EB70CBD7E006B112847CF6DFC1F186AFB2CAEFC78B32375F1B839B1`.

## Round 4 — Retired installed surface and bounded current-product correction

Timestamp: `2026-08-09T21:39:11.2054032+07:00`

### Installer and validator behavior

The installer tests were added before implementation. Both shells initially reported
`18 total / 14 passed / 4 failed`: the two new failures were the absent explicit-retirement
behavior and the default plan still advertising `policies`; the other two were the expected
legacy-directory and canonical-state failures.

| Path | Before SHA-256 | After SHA-256 | Lines | Exact location and result |
|---|---|---|---:|---|
| `scripts/install-template.ps1` | `E7BBE89A577A0DCAF0E5937DB1E93B2F61243C59472CFE677962E8E4BF536E51` | `45DC5D0B71905A2734F98821A9CF424A045EC09148CE941E24CE5446022E1D23` | 138 | Lines 18–20 and 51–60 omit `policies` from defaults/map; lines 30–32 reject an explicit case-sensitive legacy request before planning. The unrelated `workflows` mapping was not changed. |
| `scripts/validate-template.ps1` | `81D157012B46A7A694D0C40863F2919B7A22C96029F4C30DECD90AAF87ADCC35` | `8BC04E7B86C5DEA5F760874E1EABC749EAD080774D1CCB51BD43641269153BF2` | 279 | `Test-ApproxTokenBudget` at line 60 now names the approximation and emits advisory target/hard-warning results; calls at lines 164–170 use `600/1200/1500`, `300/700/800`, and `500/1200/1500`. The five retired YAML paths left required/YAML checks; exactly four `docs/policies/*.md` references entered required files. Schema YAML checks were preserved. |
| `scripts/tests/phase00-t003.Tests.ps1` | `755A07AA99A55C3A57E96CBB72EF429E2094005516EA85602EB2ED399DF5D5D0` | `57369972C481D896B4CB3667EA3CCB2B40B06674CC1FF8FE604C0365460E1DD7` | 292 | Lines 103–125 add an isolated installer probe; lines 279–291 require explicit rejection and absence from the default advertised plan. |

After only the installer mutation, PowerShell 7 reported `18 / 16 / 2`; the two remaining
failures were the still-present directory and canonical acceptance.

### Bounded direct-product documentation

Only the approved current-product boundary was rewritten. Historical research and broader spec
cleanup were not folded into this task.

| Path | Before SHA-256 | After SHA-256 | Lines | Semantic replacement |
|---|---|---|---:|---|
| `README.md` | `950522951EF5069B687F168271AE8D346564CF226DC0C43B0819FC1EAA80C55E` | `E5C87AD15E63BCFE1123288CBD1EA663F5D6B6068ED3C8B69782EC99495E6A9B` | 99 | Lines 18–20 and 66 remove an installed policy component/tree and identify consumers plus human-only references. |
| `CHANGELOG.md` | `636286F0F1C8DF043E1E70F066F09B391F401A49296BF6CD343F1676BB969DCC` | `09D79C80ABF3AD8798830F90AF9E214A9FE3A199732613B98DE24A5AD46F29B0` | 32 | Lines 14–16 replace “Five policies” with the T-00.3 retirement/re-homing record. |
| `docs/architecture.md` | `C4C8BFDC80DF27A84253621E99D200B2A0EE7483228C1668918AA5726F9EDBE6` | `7F5207BB583F0430D8DB5BE1C37C9F2861FBB6FAC05F33CE8DFB7C4D3878D19B` | 175 | Lines 47 and 55 place `docs/policies/` outside the installed tree and state OMP does not load it. |
| `docs/customization.md` | `6534629AD22CC7F1933132F71B52A85B7C110E3F2D397AFF3E0B2E08F33A3BC4` | `635D147434241AB9BC0B3993EFF1E548EFD4BFD7B382E992A0D4DAE03E910D13` | 102 | Lines 67–75 replace copy-to-`.omp/policies` guidance with edits to actual consumers/references. |
| `docs/final-report.md` | `A825D8B09394D2C6F826E5BE8589BF6238F5BD9D60151E79078CC7C4062481BB` | `30665C7D6208B13B55C25271BB39067E9A4B9954A90F06819D9D62D0987404CD` | 223 | Line 28 replaces five runtime-policy completion rows with one explicitly superseded/re-homed row. |
| `docs/installation.md` | `E38688EC82F5B9341512347A00AD3538D93F80E76886ACFCCE71A3284382012C` | `7E85A6107E8DFDBE5287DC8910B664AA34AD37ECC5BCBB4082B5BDCF4245BBB3` | 67 | Component examples/list at line 39 no longer advertise `policies`. |
| `docs/report-design.md` | `859119824450BE4D5E001FE257FFCA8A1DC62A684805F47FAE998D9A8D877E8F` | `6CECA9C7B45393C450B7E4808207D3C04E5598F7B14AA1069F53AF35D033C3C3` | 243 | Section 4.5 now maps policy-derived contracts to runtime consumers and non-runtime references. |
| `docs/security.md` | `271AECD73B4975A0C3A1D4DD48F254EEE9EE55DBE2B472891BF5915421CEB0` | `68EAFD255AB686620D2FAA9D4AA191FDA102CBD63A9CDFC8F191FE34CF9A943A` | 51 | Line 20 stops claiming installed policy YAML/runtime behavior. |
| `docs/token-strategy.md` | `E02CA9C34154D0CDF38C019AA5328702BE9EED96CBE3C106B41B0DABD4A0DB4E` | `F02F2C9F69AF5DD5C63F5C267B372AAC9408E096E0E81F18A0E88670F88B9747` | 61 | Lines 24 onward link the context reference and label `chars / 4` advisory with its enforcement boundary. |
| `docs/workflow-v0.md` | `042302A4A12657671F43DF03B7B813C351CC3F8F7EBA1D5D924EB992DA0A80A3` | `AD918B022418ADD4A8EFB46AC7F95802FC9423588552824E8912DFC544A2C817` | 96 | Lines 20 onward record the earlier five-file implementation as superseded and name the actual delivery surfaces. |

Explicitly excluded observations remain broader T-00.5/history work: `spec/README.md` and several
phase/key research records still discuss `.omp/policies/` as the diagnosed failure or historical
source; `docs/research/**` preserves the earlier adoption record. Unrelated stale installer
parameters, workflow paths, and schema claims were not repaired. The immutable legacy paths in
the validator/tests are evidence identities and negative fixtures, not advertisements.

### Deletion and recovery evidence

Immediately before deletion, all five files were re-hashed and re-counted; every SHA-256, Git
blob, and line count matched Round 1. Exactly these locked sources were then deleted with
`apply_patch`:

| Deleted path | Lines | SHA-256 | Git blob at HEAD |
|---|---:|---|---|
| `template/.omp/policies/context-budget.yml` | 89 | `A3FE19A6C131F3A9F43EF2AC5156993437CDC07B0ABE6AF284FE6E966C2F03EE` | `f5591a7b7cd3e06efbd5431536ebd2391bdedd6d` |
| `template/.omp/policies/escalation.yml` | 52 | `49CB215BEEC2424C9274BBA285E2AD28B651A124AF1BF07102A925FDAEA5FD1F` | `c8e51d31baed0b2ce7ee000bd0be5deb3858e691` |
| `template/.omp/policies/model-routing.yml` | 61 | `67E7F80534AB66C57B13EF91AD88CABAE5518F8828E89C496B78AB9C4209F4A2` | `c73070c1e73737a6947b48eb84338b583e4aa663` |
| `template/.omp/policies/quality-gates.yml` | 105 | `69A8635F66C118D5BC12612E7D7B6F498E1886B7213F15613BE5A37B6370A1E2` | `47f6d06191a9e7b68f07da1903d96b931024fa30` |
| `template/.omp/policies/workflow-sizing.yml` | 56 | `603112590C993F9DEC61D17C32387C040C775C384B1D8656756170971703671B` | `195c1f836bfd62381099cd9633073db4a37c88bc` |

The patch operation left the now-empty physical directory on Windows. Its absolute target was
resolved under the workspace, verified empty, and removed non-recursively. Final
`Test-Path template/.omp/policies` is `False`. No backup was created in the repository; recovery
is through the locked Git blobs plus the hash inventory.

### Scan correction and exact results

The first literal execution of the approved combined product/installer scan returned one match:
`scripts/install-template.ps1:30`, because `Components.*policies` necessarily matched the exact
negative-compatibility guard required by Task 4 Step 1. This was a plan predicate contradiction,
not a surviving advertisement. The code was not reformatted to hide the match.

The plan was corrected to keep the same product-doc scan, check installer advertisement entries
structurally, and separately require the registered rejection message. Plan SHA-256 after that
correction but before Task 4 checkbox updates:
`89BBF377AAE14DC239C0756557C59C8DD38C614AF9E8C5C6A13D9188CBD212BC`.

Corrected observations:

- installed agent/command scan: ripgrep exit `1`, `0` matches;
- bounded direct-product scan: ripgrep exit `1`, `0` matches;
- installer advertised component/map entries: `0`;
- installer exact retirement message: `True`;
- legacy directory exists: `False`;
- staged paths: `0`.

### GREEN-boundary debugging and verification

Deleting the directory exposed a latent helper defect: a newly true `SURFACE` passed an empty,
unused failure message into a mandatory PowerShell string parameter. Both shells reproduced
`Cannot bind argument to parameter 'FailMessage' because it is an empty string`; PowerShell 7
focused tests were `18 / 13 / 5`. Existing cardinality/no-internal-error tests supplied RED. Root
cause was `Add-Phase00T003ContractResult` binding both branch messages before selecting the PASS
branch. The minimal fix allows an empty `FailMessage`; no category predicate was weakened.

- `scripts/lib/phase00-evidence.ps1`:
  `A764121618A933D28AEB1FA17DBE826EB14AE9E4B55550BE9D7E2A5CA7428B92` ->
  `6972F5C3686747FD5D6A7EB86AA1A09C33A6A411569E87EA7F9C3DDC2CC80F94`
  (line 437, one `[AllowEmptyString()]` annotation).
- Focused Pester after the fix, both shells: `18 total / 17 passed / 1 failed`. The sole failure
  is canonical acceptance because evidence and manifest intentionally remain absent/not PASS.
- Direct contract after the fix, both shells: `9 results / 7 PASS / 2 FAIL`. PASS is exactly
  surface, references, consumers, installer, validator, registry, and product docs. FAIL is
  exactly evidence and manifest.
- Direct repository validator after the fix, both shells: exit `1`, with only
  `P00-T003-EVIDENCE` and `P00-T003-MANIFEST` failing. It also emits the honest non-failing
  advisory `RULES.md` warning (`226 < 300`); that under-target content predates T-00.3 and was not
  padded.
- Installed OMP CLI: `omp/17.2.12` (`omp --version`, exit `0`). This was read-only and made no
  provider call.

The ledger SHA-256 immediately before this Round 4 entry was
`F76434D7D5D398551CCE7A9DE19756638ABFF924E79DA29A29173869AE87D32E`.
No provider/runtime/E3/parallel/Git-authority action occurred; branch and HEAD remain the locked
`main` / `62fecf277dc9d5e47d06319387eac747462214c1`, and staged paths remain `0`.

After all cited Task 4 evidence existed, Task 4 Steps 1–7 were marked complete. The execution
plan's resulting SHA-256 is
`E9499A44C51E7748654BCDB300BC2A63D382F601DE1D76B998789A98F16F4244`; the ledger SHA-256
immediately before this status entry was
`650D68BF4788BC89BC6E15CAE33A3F1619FC4800BE2FEB84BFD1C6B12C3EF6C7`.

## Round 5 — Hash-linked local authority and baseline-backed mutation proof

Timestamp: `2026-08-09T21:48:34.7698044+07:00`

### Non-circular conclusion artifact

Created `docs/evidence/phase-00/T-00.3/conclusion.yml` (`195` lines, SHA-256
`E1B877F5594149F754E2299670F19C910E7C478B1606222D12B7B2A204A5631B`). It contains:

- exact root identity `schema_version: 1`, phase `00`, task `T-00.3`, local `PASS`,
  `provider_calls: 0`, and `parallel_mode: DISABLED`;
- the five locked legacy identities in original order, including line count, SHA-256, and Git
  blob;
- exactly 26 ordered disposition rows: 20 `REHOMED`, six `SUPERSEDED`;
- exactly 15 destination rows with on-disk SHA-256 binding;
- the prescribed branch/HEAD, surface/reference/installer/registry/doc/cross-shell/staging checks;
- all seven required non-claims, including `peer-review-not-closed`.

The six explicit supersessions are not silent drops:

1. universal `.task/` offload became isolation-aware artifact handling;
2. spawned-Tech-Lead escalation audience became the main session;
3. five required roles became four required workers plus an optional user Tech Lead alias;
4. portable concrete-model claims became environment-owned routing;
5. Reviewer self-selection became main-session task-packet selection;
6. “larger when in doubt” became the independence boundary.

The conclusion excludes itself, the manifest, and this ledger from destination hashes. Parser
proof before the manifest transition was `5 sources / 26 dispositions / 15 destinations /
7 non-claims`; `P00-T003-EVIDENCE` passed while `P00-T003-MANIFEST` still failed. This preserves
the evidence-before-authority ordering.

### Exact destination binding

All `15 / 15` values were recomputed from disk after the final Task 4 consumers/validator and
matched the conclusion byte-for-byte:

| Destination | SHA-256 |
|---|---|
| `docs/policies/README.md` | `14BF081DC148463C4D670DC53FAD70F33BAAD540C88411B191E4F1AC555894BB` |
| `docs/policies/context-budget.md` | `B3FB28CFE1ABC3C7D8C0EBED874F079E9F4271E1D47F9AF1CD4372DCC5776400` |
| `docs/policies/model-routing.md` | `9E348E097D6CD65B102C97BDE160E30C4ECADCB7A74FB405FBC274B4E8ABD8A1` |
| `docs/policies/quality-gates.md` | `28E693652A34304DC85117C578F23017E2863E68F104AFF05849EA2A9D9F32B5` |
| `template/.omp/AGENTS.md` | `3F194D81208872B6CDE4A51265156D06A8016810CAA9D24BF37B545E60848BBC` |
| `template/.omp/commands/quick.md` | `F4E9081846368DA140923C8D51C7BAB079DA4B75577019A412735DBAC4A21731` |
| `template/.omp/commands/standard.md` | `F849485369F0E8EE6D7D816752D7CAD263DA5381EF8216C319B19091FCBB626B` |
| `template/.omp/commands/orchestrated.md` | `D88179FA0C27B9EEDF9EE59B5CD6A59B75FC426BCDAD18061209942C36012D12` |
| `template/.omp/agents/tech-lead.md` | `47B3060A725F9C41EA832E2CE8E7CBAEFCAFACB4137A9B4153C2819732016AD2` |
| `template/.omp/agents/explorer.md` | `EFF925B0CF199144F306AE8F40226F8087ECF45297B0CEB270E07C3E9DF3CAE6` |
| `template/.omp/agents/implementer.md` | `6090C229C4A6B9132B99F4540EA9788A2520BB358846C6ADC5482DD911E72A22` |
| `template/.omp/agents/verifier.md` | `A3F49E18266587929D05B2DE28AD59D7B31E3832C20DAD5C201AB03348C449E0` |
| `template/.omp/agents/reviewer.md` | `7960C0C595A2B11AD5DFDC9C9F2A591C34F5CCFC2C0ADF43D5EA70F94E3C3DE3` |
| `scripts/install-template.ps1` | `45DC5D0B71905A2734F98821A9CF424A045EC09148CE941E24CE5446022E1D23` |
| `scripts/validate-template.ps1` | `8BC04E7B86C5DEA5F760874E1EABC749EAD080774D1CCB51BD43641269153BF2` |

### Isolated manifest transition

`docs/evidence/phase-00/manifest.yml` changed from
`E6DE878C41FF862EB16E4F0F99AB220E657D1CC0D7525F209A747C39F03F0F9E` to
`8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE`
(`179` lines). Only T-00.3 changed: `READY` -> `PASS`, one conclusion artifact, and the exact
approved advisory-budget decision.

Before and after parsing, the other 28 rows serialize to the same SHA-256
`0F8EBB4CCF34C9B4CDF02DC2ACC73D3AE4FB023C82178A1A356F3A7802E41CCA`.
Root `parallel_mode` remains `DISABLED`; E3-M remains `DEFERRED_PARALLEL_DISABLED`; the normalized
E3-A-through-E3-M block remains
`2BD5B20D935BFA8073016D3D3E131CB5E98F8B9D60531D0E4EDD53C352FEC312`.

### Baseline-backed negative controls

`scripts/tests/phase00-t003.Tests.ps1` changed from
`57369972C481D896B4CB3667EA3CCB2B40B06674CC1FF8FE604C0365460E1DD7` to
`D489184C01D2717BA5572EB291B0B7499C4C0B1BC022FD1EAF9875C56A1CD1BB`
(`452` lines). Each test creates a minimal byte-identical repository fixture, first requires its
target category to be `PASS`, applies one mutation, then requires the pre-registered category to
be `FAIL`:

| Mutation | Required code |
|---|---|
| recreate a policy file | `P00-T003-SURFACE` |
| add a dangling `policy:` reference | `P00-T003-CONSUMERS` |
| alter the quality-gate matrix | `P00-T003-CONSUMERS` |
| remove an escalation boundary | `P00-T003-CONSUMERS` |
| advertise the installer component | `P00-T003-INSTALLER` |
| forge a legacy-source SHA-256 | `P00-T003-EVIDENCE` |
| forge a destination SHA-256 | `P00-T003-EVIDENCE` |
| retain manifest PASS without conclusion evidence | `P00-T003-MANIFEST` |

The first expanded PowerShell 7 run was `26 / 25 / 1`: all eight new mutation controls passed,
while canonical GREEN exposed a test-only PowerShell array-unrolling defect (`0` failure codes
became `$null`, so `.Count` was unavailable). Existing canonical acceptance was the RED proof.
The one-line fix wraps the function result in `@(...)`; no production predicate changed.

Final focused results:

| Shell | Total | Passed | Failed | Mutation controls |
|---|---:|---:|---:|---:|
| PowerShell 7 | 26 | 26 | 0 | 8/8 |
| Windows PowerShell 5.1 | 26 | 26 | 0 | 8/8 |

Direct contract in both shells is exactly `9 results / 9 PASS / 0 FAIL`, in the registered code
order. Direct repository validation in both shells exits `0` with `93 passed / 1 warning /
0 failed`; the sole warning is the documented pre-existing `RULES.md` advisory (`226 < 300`).
No threshold was raised and no content was padded.

The ledger SHA-256 immediately before this Round 5 entry was
`883850EB42EDB81965E678C0B210837C468AF0127FF7B65C137D023B028B2AAD`.
Branch/HEAD remain `main` / `62fecf277dc9d5e47d06319387eac747462214c1`; staged paths are `0`;
provider calls are `0`; Attempt 6, Session B, E3-M, and parallel execution remain untouched.

After all cited Task 5 evidence existed, Task 5 Steps 1–6 were marked complete. The execution
plan's resulting SHA-256 is
`259AF08728C951C0D21A7186FC04C069A0C167E08F7FB8FEF5DBABC5E48358E1`; the ledger SHA-256
immediately before this status entry was
`43AFB3E1D72AB8AF5113B57F4A75ECF653924E78AAB3C8D1E8D4135DD061BFDF`.

## Round 6 — Full verification and Opus review packet

Timestamp: `2026-08-09T21:54:32.3617603+07:00`

### Executive verdict

Codex's local verdict is **T-00.3 IMPLEMENTATION PASS**, backed by the strict conclusion,
manifest transition, both-shell full Phase 00 suite, direct validator, and negative mutations.
Peer status remains **PROVISIONAL_PENDING_OPUS_REVIEW**. Local PASS does not close equal-peer
review, authorize provider/runtime work, or establish that every broader documentation defect is
fixed.

The approved authority hierarchy and scope are unchanged from the opening section. The design
still hashes to `EA56CD82EBE1D59A40AC3F549D39F57DF66D3B8558D024252333C7E2E71A5A4F`.
The plan hash at the completed Task 5 checkpoint is
`259AF08728C951C0D21A7186FC04C069A0C167E08F7FB8FEF5DBABC5E48358E1`;
its final checkbox-only hash is recorded after self-review below.

### Complete section disposition matrix

This is the complete 26-row contract from the conclusion, not a summary sample.

| Legacy section | Disposition | Concrete destination(s) | Normative authority |
|---|---|---|---|
| `context.components` | REHOMED | `docs/policies/context-budget.md` | `spec/05-context-and-token-model.md` |
| `context.retrieval-order` | REHOMED | `docs/policies/context-budget.md` | `spec/05-context-and-token-model.md` |
| `context.degradation-prevention` | REHOMED | `docs/policies/context-budget.md` | `spec/05-context-and-token-model.md` |
| `context.offload-candidates` | REHOMED | context reference; `template/.omp/AGENTS.md` | `spec/05-context-and-token-model.md` |
| `context.offload-universal` | SUPERSEDED | isolation-aware context reference and AGENTS contract | `spec/05-context-and-token-model.md` |
| `escalation.worker-to-main` | REHOMED | Explorer, Implementer, Verifier, Reviewer prompts | `spec/15-security-and-failure-recovery.md` |
| `escalation.main-to-user` | REHOMED | `template/.omp/AGENTS.md` | `spec/15-security-and-failure-recovery.md` |
| `escalation.do-not-escalate` | REHOMED | Explorer, Implementer, Verifier, Reviewer prompts | `spec/15-security-and-failure-recovery.md` |
| `escalation.spawned-tech-lead-audience` | SUPERSEDED | main-session authority in `AGENTS.md` | `spec/03-agent-topology.md` |
| `model-routing.authority` | REHOMED | model reference; Standard and Orchestrated commands | `spec/09-model-routing.md` |
| `model-routing.five-required-roles` | SUPERSEDED | four required workers plus optional Tech Lead in model reference | `spec/03-agent-topology.md` |
| `model-routing.portable-concrete-model` | SUPERSEDED | environment-owned mapping in model reference | `spec/09-model-routing.md` |
| `model-routing.constraints` | REHOMED | model reference; Standard and Orchestrated commands | `spec/09-model-routing.md` |
| `model-routing.effort-mapping` | REHOMED | `docs/policies/model-routing.md` | `spec/09-model-routing.md` |
| `model-routing.customization` | REHOMED | `docs/policies/model-routing.md` | `spec/09-model-routing.md` |
| `quality-gates.six-gates` | REHOMED | quality reference; Standard and Orchestrated commands | `spec/11-skills-rules-and-quality-gates.md` |
| `quality-gates.default-matrix` | REHOMED | quality reference; Standard and Orchestrated commands | `spec/11-skills-rules-and-quality-gates.md` |
| `quality-gates.override-rule` | REHOMED | quality reference; Standard and Orchestrated commands | `spec/11-skills-rules-and-quality-gates.md` |
| `quality-gates.selection-owner` | REHOMED | quality reference; `template/.omp/AGENTS.md` | `spec/03-agent-topology.md` |
| `quality-gates.reviewer-self-selection` | SUPERSEDED | main packet selection plus Reviewer application | `spec/03-agent-topology.md` |
| `workflow-sizing.quick` | REHOMED | `template/.omp/commands/quick.md` | `spec/04-workflow-sizing.md` |
| `workflow-sizing.standard` | REHOMED | `template/.omp/commands/standard.md` | `spec/04-workflow-sizing.md` |
| `workflow-sizing.orchestrated` | REHOMED | `template/.omp/commands/orchestrated.md` | `spec/04-workflow-sizing.md` |
| `workflow-sizing.larger-when-in-doubt` | SUPERSEDED | independence boundary in AGENTS/Standard/Orchestrated | `spec/04-workflow-sizing.md` |
| `workflow-sizing.risk-levels` | REHOMED | quality reference; Standard and Orchestrated commands | `spec/04-workflow-sizing.md` |
| `workflow-sizing.overrides` | REHOMED | quality reference; Standard and Orchestrated commands | `spec/04-workflow-sizing.md` |

### Created, modified, and deleted ledger index

The non-duplicated before/after hashes and line anchors are distributed by responsibility:

- Round 1: focused test creation and exact five-source inventory;
- Round 2: helper, repository validator, Wave A registration, and plan checkpoint;
- Round 3: four created references, nine runtime/main consumers, and four normative anchors;
- Round 4: installer, validator budget behavior, ten bounded product documents, helper GREEN
  correction, and all five deletions;
- Round 5: conclusion creation, isolated manifest transition, final test/mutation harness, and all
  15 destination hashes.

Governance artifacts were `ABSENT` before this T-00.3 continuation and remain separate from the
15 hashed product destinations:

| Artifact | Role | Current/final-handoff handling |
|---|---|---|
| `docs/superpowers/specs/2026-08-09-phase-00-t003-authoritative-policy-rehoming-design.md` | approved immutable design | hash above; unchanged during implementation |
| `docs/superpowers/plans/2026-08-09-phase-00-t003-authoritative-policy-rehoming-plan.md` | execution checklist | every mutation/checkpoint hash recorded chronologically; final hash below |
| `codex-phase00-t003-authoritative-rebuild-changelog-for-opus5.md` | append-only peer ledger | final SHA-256 must be reported outside this self-referential file |

No registry file was mutated for T-00.3: existing `local_components`, `adopted_to`, and
`superseded_paths` records were verified. The dirty status of `registry/upstreams.yml` predates
this task and is not claimed as a T-00.3 edit. The same preservation rule applies to all unrelated
dirty/untracked paths not named in the approved file responsibility map.

### Fresh full verification

The complete `phase00*.Tests.ps1` set contains six files. Fresh final runs used that full set:

| Shell | Test files | Total | Passed | Failed | Exit | Pester time |
|---|---:|---:|---:|---:|---:|---:|
| PowerShell 7 | 6 | 227 | 227 | 0 | 0 | 45.4 s |
| Windows PowerShell 5.1 | 6 | 227 | 227 | 0 | 0 | 52.46 s |

Fresh direct repository validation after the full suite is identical in both shells:
`93 passed / 1 warning / 0 failed`, exit `0`, `VALIDATION PASSED WITH WARNINGS`. The warning is
only the explicitly advisory pre-existing `RULES.md` lower-target observation (`226 < 300`). No
retired policy file is required or checked as non-empty.

### Final integrity recomputation

- design hash matches the approved value;
- conclusion legacy identities: `5 / 5`, `0` mismatches;
- conclusion destination hashes: `15 / 15`, `0` mismatches;
- references are exactly `context-budget.md`, `model-routing.md`, `quality-gates.md`, `README.md`;
- `template/.omp/policies` is absent; dangling installed prompt references: `0`;
- all nine `P00-T003-*` categories PASS; registry destinations/superseded-path placement PASS;
- all 28 non-T-00.3 manifest rows still serialize to
  `0F8EBB4CCF34C9B4CDF02DC2ACC73D3AE4FB023C82178A1A356F3A7802E41CCA`;
- root parallel mode is `DISABLED`; E3-I is `READY`/0 artifacts; E3-L is `READY`/0 artifacts;
  E3-M is `DEFERRED_PARALLEL_DISABLED`/0 artifacts;
- normalized E3 block is unchanged at
  `2BD5B20D935BFA8073016D3D3E131CB5E98F8B9D60531D0E4EDD53C352FEC312`;
- Attempt 6 artifacts: `0`; unearned I1–I4/L1–L3/selected-transaction artifacts: `0`;
- durable `P00-CX-028` correction contract PASS;
- eight frozen P00-CX-028 inputs/sidecars/conclusions checked: `8 / 8`, hash mismatches `0`;
- branch `main`; HEAD `62fecf277dc9d5e47d06319387eac747462214c1`; staged paths `0`.

The eight frozen values checked include the three review inputs plus both second-order E3-I
sidecars, the second-order E3-L joint sidecar, and the E3-I/E3-L READY conclusions. Raw reference
hash chains are additionally covered by the passing durable correction contract and full suite.

### Explicit exclusions and residual risks

1. Opus has not reviewed this continuation; only both peers can close the issue.
2. `chars / 4` is advisory and is not exact BPE token counting. `RULES.md` remains below the
   target band as a transparent warning, not a failure.
3. The approved direct-product boundary was corrected; historical research and broader stale
   prose remain T-00.5 work. Their descriptions of the removed failure are not runtime claims.
4. The installer `workflows` versus `commands` defect, unrelated parameters, and broader schema
   claims remain outside T-00.3.
5. E2 concrete model/fallback behavior, topology redesign, Tech Lead relocation, Reviewer rename,
   `blocking`, output schemas, LSP, Phase 01/02 behavior, and exact token evaluation remain
   separately governed.
6. No new provider experiment was run. This closure proves the static contract and repository
   evidence, not new provider behavior or optimality.
7. The worktree contains unrelated user/prior-session changes. Nothing was staged or committed;
   later integration must preserve ownership boundaries.
8. Any future edit to one of the 15 destination files invalidates the conclusion hash binding
   until T-00.3 evidence is deliberately re-derived.

### Required independent Opus ruling

Please answer each question from raw files/tests rather than accepting this ledger by assertion:

1. Does the authority hierarchy and bounded T-00.3 scope correctly implement KD-001 and the
   Phase 00 task without importing T-00.4/T-00.5/E2/E3 work?
2. Do all 26 `REHOMED`/`SUPERSEDED` rows retain useful legacy content while removing claims that
   conflict with the current topology, isolation boundary, and environment-owned routing?
3. Are the four human references clearly non-runtime, and are executable clauses located in the
   consumers that actually receive them?
4. Is the installer negative-compatibility guard correct, including the documented correction to
   the originally contradictory `Components.*policies` scan?
5. Is the nine-category fail-closed validator plus eight baseline-backed mutations sufficient to
   prevent false PASS from recreated surfaces, dangling contracts, altered matrices, missing
   escalation, installer advertising, forged hashes, or manifest PASS without evidence?
6. Is the conclusion genuinely non-circular and complete, with trustworthy source/destination
   bindings and an isolated manifest transition that leaves E3/parallel authority unchanged?
7. Are any exclusions actually load-bearing for T-00.3 and therefore required before acceptance?

Return either `ACCEPT T-00.3` or numbered objections with exact file, line/section, expected
contract, and reproducing evidence. An acceptance or rejection by either peer alone does not
close the equal-review process.

The ledger SHA-256 immediately before this Round 6 entry was
`AB61C34B7AAC379595F5D15F9415168ECDFC9CEEF9DA7EE99EFED8A9608972DC`.

### Self-review gate

The design, plan, conclusion, and this ledger were scanned together after the review packet was
written:

- standard unfinished-marker scan returned five contextual matches only: the design's deliberate
  written-peer-review status, two plan descriptions of rejected markers, this ledger's parser
  description, and the plan's explicit Opus-review requirement;
- literal `TODO`, `TBD`, `PLACEHOLDER`, `FIXME`, and `WIP` work items: `0`;
- false claims that Opus/both peers had accepted or closed review: `0`;
- unchecked plan items at that instant: exactly the self-review and final-checkpoint steps being
  executed, with all evidence-producing steps already checked;
- strict conclusion parsing and all nine categories still PASS;
- current design and conclusion hashes match their cited values; all historical plan/ledger hashes
  are explicitly labeled as time-local checkpoints rather than current-file claims;
- implementation PASS, manifest PASS, and peer-review provisional status are stated as distinct
  authorities throughout; no ambiguous global closure claim was found.

At this self-review checkpoint: design `351` lines, conclusion `195` lines, plan `822` lines,
ledger `702` lines before this subsection, and staged paths `0`.

All Task 6 evidence then existed, so Steps 1–7 were marked complete. The local execution plan has
`0` unchecked items and final SHA-256
`476CFB0E41BEAFE5EB4B256DA6A2796B21BBD1E095BBAE68F2BC7351EF1FC77F`.
The ledger SHA-256 immediately before this final status entry was
`C4B939B2DCE9B8200FEC70F73602EE4C254B024E4C57ACAF8613ADB3563E2C7F`.
This closes the Codex local execution plan only; Opus peer review remains open.
