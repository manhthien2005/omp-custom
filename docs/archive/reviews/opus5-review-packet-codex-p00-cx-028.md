# Codex → Opus 5 — Compact Review Packet for P00-CX-028

> **Project:** `omp-template` Phase 00
>
> **Review scope:** Codex's Attempt 5 retry-fact correction and terminal blocked materialization
>
> **Peer model:** Codex and Opus are equal reviewers; neither is presumed correct
>
> **Requested activity:** adversarial review only; do not mutate files in this first response
>
> **Full audit ledger:** `codex-phase00-execution-changelog-for-opus5.md`
>
> **Full ledger SHA-256:** `476075901D51C66EB8341AC977A58C21E6B82D031E5C5EC52CF76D4F0798F63A`

---

## 0. Token-efficient review protocol

Read this packet first. Inspect repository files named here only when testing a claim. Read the
full ledger only for drill-down:

1. `P00-CX-027A`, lines 3529-3754: provider launch and immutable Attempt 5 raw audit.
2. `P00-CX-028`, lines 3755-4010: correction, materialization, tests, and non-claims.
3. Older entries only if a predecessor claim cannot be verified from current files or hashes.

Stop and report `INSUFFICIENT_EVIDENCE` if the packet hash supplied in the review prompt, the
full-ledger hash above, or any load-bearing artifact hash below does not match disk.

Do not summarize the entire project. The only requested decision is whether P00-CX-028 is a
faithful, fail-closed terminal representation of Attempt 5.

---

## 1. Requested verdict

Return exactly one:

```text
ACCEPT_P00_CX_028
REOPEN_P00_CX_028
INSUFFICIENT_EVIDENCE
```

Acceptance means only:

- the raw Attempt 5 outcome remains `BLOCKED_ENVIRONMENT`;
- the recovered nested retry is recorded independently and truthfully;
- the immutable raw joint record was not rewritten;
- E3-I and E3-L terminal artifacts are hash-coherent and make no partial semantic claim;
- E3-M and parallel authority remain disabled;
- no material defect remains in the scoped correction.

Acceptance does **not** mean E3-I PASS, E3-L PASS, E3-M PASS, Phase 00 completion, parallel
enablement, or approval of an Attempt 6.

---

## 2. Current authority state

| Authority | Current state | Exact consequence |
| --- | --- | --- |
| E3-I | `BLOCKED_ENVIRONMENT` | No selected transaction, Session B, or I1-I4 materialization |
| E3-L | `BLOCKED_ENVIRONMENT` | No selected transaction or L1-L3 materialization |
| E3-M | `DEFERRED_PARALLEL_DISABLED` | Remains the only parallel-enablement experiment |
| Root | `parallel_mode: DISABLED` | No parallel authority exists |
| Opus review | `PENDING_QUOTA` | Codex's terminal adjudication is provisional |

Attempt 5 executed Session A exactly once. Parent-terminal provider overload stopped
continuation, so Session B was not invoked. No Attempt 6 exists. The correction/materialization
round made no provider call.

---

## 3. The one disputed fact projection

Two raw facts coexist:

1. Session A parent events contain terminal OmniRoute `server_is_overloaded` evidence.
2. Nested canary `e3i-runtime-3` contains one recovered automatic provider retry.

Independent replay produced:

```yaml
parent_events: 735
canary_outputs: 6
e3_i_classifier:
  status: BLOCKED_ENVIRONMENT
  reason: P00-RUNTIME-PROVIDER-OVERLOAD
shared_transport_classifier:
  status: BLOCKED_ENVIRONMENT
  reason: P00-RUNTIME-PROVIDER-OVERLOAD
selection_classifier:
  status: BLOCKED_ENVIRONMENT
  reason: P00-RUNTIME-PROVIDER-OVERLOAD
recovered_retry_canaries:
  - e3i-runtime-3
```

The original joint writer derived `recovered_provider_retry` only from selection reasons.
Parent-terminal precedence returned before nested recovery became a selection reason, so the
raw joint summary wrote `false`. The terminal classification was correct; the orthogonal retry
projection was incomplete.

Codex's correction:

- future joint writes inspect `Invocation.CanaryEvents` using the existing recovered-provider
  helper, with selection reasons only as a fallback;
- historical raw bytes remain immutable;
- `joint-attempt-005.adjudication.json` hash-links the raw joint and records exactly
  `correction_reason: E3IL_RETRY_FACT_UNDER_REPORTED` plus
  `sessions.a.recovered_provider_retry: true`;
- the durable validator fails closed unless the predecessor exists, its hash matches, the
  correction reason is exact, and the recovered-retry value is true.

Review the key implementation at:

- `scripts/run-phase00-e3l-joint.ps1:165-196`
- `scripts/lib/phase00-evidence.ps1:412-487`
- `scripts/tests/phase00-e3l.Tests.ps1:1129-1184`
- `scripts/tests/phase00-e3l.Tests.ps1:1372-1394`

---

## 4. Load-bearing artifact chain

| Artifact | SHA-256 | Purpose |
| --- | --- | --- |
| `docs/evidence/phase-00/E3-L/raw/joint-attempt-005.json` | `BDC3A720531310C7F097A094542597FBCCF6ABAA5E05DA148A7594933B51948C` | Immutable original joint record |
| `docs/evidence/phase-00/E3-L/raw/joint-attempt-005.adjudication.json` | `C1D2307FDC3237477D50CA3C309A17E6A42EC9E2539A0D41D822180737BF0B5D` | Hash-linked correction and joint terminal adjudication |
| `docs/evidence/phase-00/E3-L/conclusion.json` | `0BC95B726B10EDCC79BFB44247F4C02C585939A72E3B0D279071851C20AB28E6` | E3-L terminal blocked conclusion |
| `docs/evidence/phase-00/E3-I/raw/session-a.attempt-005.adjudication.json` | `BB7F7395441B1ED7C6E4DF3B56433BD9C50A633F4CE943005D8B8E814239626C` | Independent E3-I interpretation of the same Session A raw set |
| `docs/evidence/phase-00/E3-I/conclusion.yml` | `E8D3016DD4A6665E194CA822481296E9648C111FC0536B73FE2F008F6E73D546` | Attempts 1-5 history and E3-I terminal state |
| `docs/evidence/phase-00/manifest.yml` | `611A95BD00DA30CD99DDF64BC9B545BAFEA0593A1E4F2B0A52A920C1B29E5F36` | Current authority state |

The correction sidecar's `correction_of.sha256` must equal the raw joint hash. The E3-L
conclusion's `joint_adjudication.sha256` must equal the correction-sidecar hash. The E3-I
adjudication must independently re-hash every Session A raw file.

### Attempt 5 Session A raw set

| Raw file suffix | SHA-256 |
| --- | --- |
| `stdout.jsonl` | `5F8DF445A52D54E6C48D11D35D75706E435D67B51D2CEB518B4C89F1804F44F0` |
| `stderr.txt` | `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` |
| `run.json` | `8A2EAFC45F771268FCB872F7ED0D6A278AD1F4217CDC625F0F431FF55CF3230B` |
| `canary.e3i-project-1.jsonl` | `97B8B7C06A57159C9865A06D179C2CE77B7EBA01869C10E4ABD13B328C2B3325` |
| `canary.e3i-project-2.jsonl` | `6A96C0C1A6DCBE0CA37F4A7C6EEBDF0FFE2DC7E786D9BC1F2A1BAC56D2BCE65A` |
| `canary.e3i-project-3.jsonl` | `0CDCAC4964F479BDEC49179A9EB6BEE045208C08FDCD5D0194E22BB7D4E47D16` |
| `canary.e3i-runtime-1.jsonl` | `D80867A0744FF62B846170D9CD9E3A28B23F5A2C73BA1B719BE3311A575EE4A1` |
| `canary.e3i-runtime-2.jsonl` | `5940D7F9C9AF277439F5D3F9D213FC7F06115117BBFB32137DF08E5F2268AB21` |
| `canary.e3i-runtime-3.jsonl` | `76CD96E3D797C290A2B92358F8800605BF609024E7F6B89C6BF8A13C9D08432B` |

All six possible Session B files are absent by design because continuation was blocked.

---

## 5. Exact mutation ledger

`before → after` SHA-256 values:

| File | Before | After | Review focus |
| --- | --- | --- | --- |
| `scripts/run-phase00-e3l-joint.ps1` | `79229428998D237DE337EF692A06F379A64D36B7613AECB250BED4D300914A97` | `E14C3444583518491E209F6B8901F9BE1815EBC1D49A078B3F6E14F35C7ADCE7` | Independent retry-fact projection |
| `scripts/lib/phase00-evidence.ps1` | `7A0F4325BCCDE50B5818490CF23BC7AB56CBF82AFF9E110614714B4478CF2D38` | `EFCCD7C2848A55852A8701F0622864FF3DF9BDBD9194AF33BF3035F98A294C5D` | Fail-closed sidecar validation |
| `scripts/tests/phase00-e3l.Tests.ps1` | `34A0BA86BD3807BDBF98AC25C8F72D46A9CD60A3C3B3575CDBB69DD52B4D244D` | `D207A59FD9A5C228EC3AB190C18C4E21A4CD4DA67C00811E3BC8F25EE4BF020A` | Regression and negative controls |
| `scripts/tests/phase00-e3i.Tests.ps1` | `9D7843AE18CD5E12BE19095C8211DF35671B90896299DC2004F94B0091ADA22C` | `B086C8E3CD54056106A6E466E60CD1A72715269476DE5C78762B4E0C5641D950` | Attempt 5 artifact contract |
| `scripts/tests/phase00-wave-a.Tests.ps1` | `C9CE99B9FF47ECE40208EBFAB03899AEEB84E09984303A26953FCED2A5F62A0E` | `6E947B4D7540D6839028CD12A07B51ED8528717A3610CCA6658BED005D053F51` | Fixture anchor only; no validator relaxation |
| `docs/evidence/phase-00/manifest.yml` | `89823F3E29C9689A90331A1994AB11D10F7CD2A122B051E0845173BD4A0EEDCA` | `611A95BD00DA30CD99DDF64BC9B545BAFEA0593A1E4F2B0A52A920C1B29E5F36` | E3-L READY → BLOCKED; E3-I stays blocked |
| `docs/evidence/phase-00/E3-I/conclusion.yml` | `4CBBDCFDDBC4991D5D4BDA0E76F44FBC2557FB3C96E7A4DB7732B866482C82E5` | `E8D3016DD4A6665E194CA822481296E9648C111FC0536B73FE2F008F6E73D546` | Attempt 5 history and non-claims |
| `docs/superpowers/specs/2026-08-09-phase-00-e3l-live-session-reader-design.md` | `F0E2573C27E18D3EE74E055BAEDE1910CD79CE297A68F0DC4C0475A8950595A3` | `274FBA02956F64FFBE34534C53CA6B56BEAAAEDE10C0C7C188D42F8F38650B8F` | Runtime status only |
| `docs/superpowers/specs/2026-08-09-phase-00-e3i-parent-overlay-canary-design.md` | `36E43AEAFA53C099A1D93F053F0EBB358C81505E147FA886F4B0AC410C8719F2` | `57091C7D149B3154B39CED82E7348FD02EEC898BA61E7E7ECBF0861BEA0C7E2E` | Joint Attempt 5 update only |

Created files are the E3-L correction sidecar, E3-L conclusion, and E3-I Attempt 5
adjudication listed in Section 4. No other current-round artifact was created.

---

## 6. Test and integrity evidence

### Required RED → GREEN cycles

| Contract | RED | GREEN |
| --- | --- | --- |
| Future runner preserves nested recovery under parent-terminal precedence | 34/35 | 35/35 |
| Validator accepts a valid corrected sidecar | 34/35 | 35/35 |
| Four malformed sidecars are rejected | 35/36; rejected 0/4 | 36/36; rejected 4/4 |
| E3-I requires Attempt 5 adjudication and current conclusion | 43/45 | 45/45 |
| Wave A fixture follows legitimate E3-L terminal state | 25/26 | 26/26 |

Malformed-sidecar controls cover: missing immutable predecessor, bad predecessor hash, wrong
correction reason, and `recovered_provider_retry:false`.

### Final cross-shell gate

Both PowerShell 7.6.4 and Windows PowerShell 5.1.26100.8875:

```yaml
phase00_e3_l: 37/37
phase00_e3_i: 45/45
phase00_e3_a_e3_h: 44/44
phase00_wave_a: 26/26
phase00_e3_j_e3_k: 35/35
aggregate: 187/187
validator: 90 passed, 0 warnings, 0 failed
```

The installed OMP is now 17.2.12. Final gates intentionally used a process-local copy of the
pinned 17.2.10 executable at SHA-256
`1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6`.
The installed executable was not changed, and the temporary copy was removed.

Final integrity checks: 15 Phase 00 PowerShell files parse in both shells; six JSON and seven
JSONL files parse; 796 JSONL events; zero reference-hash mismatches; zero selected I1-I4/L1-L3
artifacts; zero credential-value matches; zero unsanitized task-temp paths; zero remaining
task temp roots; pinned source clean at
`3a8591a8af5b6d200088d12ca75a5517cb064fa8`; live `.omp/agent` unchanged at
`A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4`.

---

## 7. Mandatory adversarial questions

Answer each with `ACCEPT`, `REJECT`, or `INSUFFICIENT`, followed by exact evidence:

1. Does parent-terminal provider overload correctly retain classification precedence over a
   nested recovered retry?
2. Is a hash-linked correction sidecar valid here, or must the immutable raw joint record be
   handled differently?
3. Are the predecessor hash, exact correction reason, and required `true` retry value sufficient
   fail-closed constraints? Identify any missing invariant.
4. Does the future runner correction preserve retry facts without changing provider execution,
   selection eligibility, or retry policy?
5. May E3-I and E3-L independently consume the same blocked joint transport while maintaining
   separate semantic authority and conclusions?
6. Is `E3-L: READY → BLOCKED_ENVIRONMENT` legal with only the correction sidecar and conclusion,
   and with no selected projection or L1-L3 files?
7. Do any artifact, test, manifest, or design statement accidentally imply semantic PASS,
   Phase 00 completion, Attempt 6 authorization, or parallel enablement?

---

## 8. Finding quality bar

Every reopening finding must include:

```yaml
severity: CRITICAL | IMPORTANT | MINOR
claim_rejected: exact Codex claim
evidence:
  path: repository-relative path
  lines_or_json_path: exact location
observed: what the file/raw event actually proves
expected: the contract that should hold
impact: why P00-CX-028 cannot be accepted
minimal_correction: exact change or additional evidence required
```

Do not reopen on style, naming preference, speculative future behavior, or facts outside this
scope. Conversely, do not accept merely because tests pass: independently inspect the raw-to-
sidecar-to-conclusion-to-manifest chain and the precedence logic.

The optimized response schema is defined in
`opus5-review-prompt-codex-p00-cx-028.md`.
