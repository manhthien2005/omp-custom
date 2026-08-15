# Codex Peer Review — Topic 02 — Round 2

## 1. Verdict

REOPEN_TOPIC_02

All required hashes, source anchors, validators, Git identity, and DAG checks are reproducible. The three specific Round‑1 defects are corrected on their targeted surfaces, but other active hash-pinned specifications still mandate a permanent named Verifier and fixed worker topology, preempting Topic 03. This is an Important scoped defect, and the focused phrase guard does not detect it.

## 2. Hash, validator, and source audit

“Same” means the complete observed SHA‑256 exactly equaled Expected.

| Check | Expected | Observed | Result |
|---|---|---|---|
| Round‑2 packet | `7823E99DB0E917C267FF8BD0C87F53B463056A50A842BB1434E69A56D732008A` | Same | PASS |
| Correction ledger | `BE9CE1AAA904D2D03E06973364FA7294690DEA5B59B63FAD026F59F8E7B4FAC9` | Same | PASS |
| Round‑1 packet | `B26118D339C644B75035CA0EFA8B1C443AE0CE7086B31877AEFD0A912EF7D20E` | Same | PASS |
| Round‑1 prompt | `470B915043336395E61C633DCA1FDB1837EA2ED9964ABAF6767CAD1B85122CE6` | Same | PASS |
| Round‑1 response | `4821FC972FD2828BFDDC3C4167BF2A3AB39C7BB99ABA09B32FA5E12C3B9D06B9` | Same | PASS |
| Blocked-input record | `01FB30C8687C268F9634D1E891C690604B0895F3D53CA78A86168DEE1B64EC7C` | Same | PASS |
| Approved design | `1A9F0DD9449B18FF56F870EA0F0B57739E2F7D494429269C6BAAFF1F22A9204A` | Same | PASS |
| `spec/01` | `E022AC1C7BDA7DC27FFEBA41ECFB807B716925C7033B9CBA60B59916D884859A` | Same | PASS |
| `spec/03` | `F2AF9FE39C7C942F03CBA5D158F45A60ACE65888707A8171CE17C2CB07389266` | Same | PASS |
| Canonical `spec/04` | `DBD99DCD3871142B8C22EE6EEBF51AC833097CB8841C8E9E65DA6F8A5FF273CF` | Same | PASS |
| `spec/05` | `76DDFBE46AE412CB298E296702C90C109E4B032A43AC3AA409AE592CC163FFB8` | Same | PASS |
| `spec/08` | `B1B38CFE6EDE9218D595A40B6C45EC92172DB189F83D29791F2858A584E5EF19` | Same | PASS |
| `spec/10` | `331C7F17E57D634FCF77CFB3B789D7FA71CA6DF6FC596CFDD08AA41EB032818C` | Same | PASS |
| `spec/13` | `CFE96317B33ACDEAB81D3E853DDDE3B72955EAC91E5849E23112C2F46655A23D` | Same | PASS |
| `spec/README` | `98D08A9E0484C99204708E0B39B354AA6975D0853A9A45DDB83491CC5C1CC2A1` | Same | PASS |
| DNA | `81FDC69E8A1563EC17C9215537AA92F61AC91BFC8FCBE17FA96F1F61C319E544` | Same | PASS |
| Token-quality model | `3015BE8C1B5D540274547508C5CF2110445071267D4F21D643159962F6079989` | Same | PASS |
| Decision log | `64FD57060E38249A241D657C3E6520023B876985E7D858106BD801687FBE9760` | Same | PASS |
| Phase 02 | `0F98830CF5E3E47892FD9B00B1309F31CF321FD7E8C550DB86AF0E863AD3F0BC` | Same | PASS |
| Phase 03 | `D31591F84DBD6484F0736983541A336D8ED6BB1EC5B141C9164CE679B0366095` | Same | PASS |
| Phase 06 | `0CA71FD4CDA5708B48E13C7EC4BA99202CD2027A722D71E056E0A96375AE4ABD` | Same | PASS |
| Focused helper | `FFEFDD3F98002E8F1F23D9955FAE2F67BE79805991F706B69B26D567340940FE` | Same | PASS |
| Focused self-test | `38848B5F70CF4860CC5ED3EE567F1CB1803E198A492D4CA3F541485FF0A59814` | Same | PASS |
| Focused wrapper | `EC4F5BC38194C3DB4E486D77BDEBC1AAA73E335A49746CCDC44B31AA447582A4` | Same | PASS |
| `CHANGELOG.md` | `C83FF7B6886E682B23B23ACC1A5F37D57DF07F77A90E26401AB55C6A110350C0` | Same | PASS |
| Topic ledger | `B966276CE8C92CC78108921119415163B35D9CAE7EDBAA52C1C7B34FCD18C97B` | Same | PASS |
| Historical Phase‑00 pins | Seven packet digests | `7/7` exact | PASS |
| Old Round‑1 semantic blobs | Old `spec/04`, DNA, KD‑026, `spec/13`, Phase 02, Phase 06 hashes | Recovered byte-exact through Git object inspection | PASS |
| Repository identity | `main`, `62fecf277dc9d5e47d06319387eac747462214c1`, staged `0` | Exact | PASS |
| Pinned OMP | Clean `3a8591a8af5b6d200088d12ca75a5517cb064fa8`, `17.2.10` | Exact; porcelain empty | PASS |
| Plain-text handling | Non-slash text unchanged | `slash-commands.ts:113-114` | PASS |
| Command gate | Command handling only for slash input | `agent-session.ts:4945-4964` | PASS |
| Handoff | New session, state reset, generated text injected | `session-handoff.ts:217-275` | PASS |
| Focused self-test | 12 assertions | `PASS ... (12 assertions)`, exit `0` | PASS |
| Focused validator | `81/0/0` | `81 passed, 0 warnings, 0 failed`, exit `0` | PASS |
| Full validator | `102/1/0` | Exact; only `RULES.md 226 < 300` warning | PASS |
| Phase‑02 history boundary | Explicit superseded appendix | Heading at `phase-02-core-orchestration.md:112`; remainder expressly non-authoritative | PASS |
| Active-authority contradiction search | No fixed topology/permanent Verifier | Active hits in `spec/05`, `spec/08`, `spec/10`, token model, and `spec/README` | FAIL |
| `git diff --check` | Exit `0` | Exit `0`; Phase‑00 CRLF advisory only | PASS |
| Phase DAG | Nine reciprocal edges | `EXPECTED_EDGES=9`, `RECIPROCAL_FAILURES=0` | PASS |

## 3. Round-1 finding disposition

| Finding | Disposition | Decisive evidence |
|---|---|---|
| R1-F1 | CLOSED | Design `:68`, canonical `spec/04:50-58`, KD‑026 `:947-950`, DNA `:113-117`, active Phase 02 `:52-57`; material changes to verification/review gates open a linked task |
| R1-F2 | CLOSED | DNA `:145-152,180-187,528-533` now assigns topology to Topic 03, fences the old roster, and makes review contract/risk-gated |
| R1-F3 | CLOSED | `spec/13:74-104` and Phase 06 `:74-104` derive workers, roles, barriers, and capabilities from the selected manifest; sequential/no-LSP/no-parallel variants pass while selected unsafe paths fail closed |

## 4. New findings

### Important — Active specifications still mandate a named Verifier and fixed worker topology

- Classification: actionable
- Claim rejected: Topic 03 owns the final topology, and Topic 02 requires neither a permanent named Verifier nor a fixed worker roster.
- Evidence: `spec/10-verification-and-review.md:7-10,35-50,187-203,319`; `spec/05-context-and-token-model.md:33`; `spec/key/03-token-quality-model.md:146`; `spec/README.md:354`; `spec/08-isolation-and-concurrency.md:119-170,346-347`
- Observed: `spec/10` makes verification “a separate agent,” treats a separate child session per Verifier as an architectural guarantee, and declares the Verifier hard-required. The context and token models call skipping that named role never acceptable. `spec/README` preserves “Keep separate” as a normative DR‑8 choice. `spec/08` says the flat four-role topology is mandatory, contradicting its own introductory hypothesis fence.
- Expected: Independent evidence is contract-gated; Topic 03 may choose a main-session check, renamed or merged role, separate worker, or another justified mechanism. Only barriers and capabilities consumed by the selected topology are mandatory.
- Impact: A valid sequential Orchestrated topology with merged/renamed roles or no spawned Verifier violates active authority despite satisfying canonical `spec/04`, DNA, and manifest-derived L0/L1. Topic 03 therefore cannot exercise its assigned ownership.
- Minimal correction: Rewrite these active statements as selected-topology conditions, fence retained roster material explicitly as history, and extend the focused validator beyond its current literal `always in Orchestrated` ban (`scripts/lib/topic02-workflow-lifecycle.ps1:139`) to reject permanent named-role authority.

The 12 mutation assertions do target the three original regressions, but their phrase checks produce false confidence here: the suite passes while the semantically equivalent permanent-Verifier rule remains active.

## 5. Mandatory-question answers

| # | Decision | Decisive evidence |
|---|---|---|
| 1 | ACCEPT | Design `:66-74`; `spec/04:48-58,245-253`; KD‑026 `:947-950`; DNA `:113-117` |
| 2 | ACCEPT | DNA `:145-187,528-533` |
| 3 | ACCEPT | `spec/13:74-104`; Phase 06 `:74-104` |
| 4 | ACCEPT | `spec/04:87-122`; OMP `slash-commands.ts:113-114`, `agent-session.ts:4945-4964` |
| 5 | ACCEPT | `spec/04:48-83,185-226` |
| 6 | ACCEPT | `spec/04:255-295`; OMP `session-handoff.ts:217-275` |
| 7 | ACCEPT | `spec/04:199-229`; `spec/13:241-281` |
| 8 | REJECT | Canonical structure is correct, but `spec/10:7-10,35-50,319` and `spec/08:162-170,346-347` still mandate named/fixed execution roles |
| 9 | ACCEPT | `spec/04:297-312`; token-quality model `:70-79` |
| 10 | REJECT | Phase and history boundaries are honest, but the active fixed-Verifier authority preempts Topic 03 |

## 6. Boundary and non-claim check

- contract-gate lock: CLOSED
- DNA topology/review neutrality: CONFIRMED IN DNA; contradicted elsewhere by the Important finding
- manifest-derived L0/L1: CONFIRMED
- plain/no-prefix source feasibility: CONFIRMED
- task/candidate/session and lifecycle/evaluation: COHERENT
- Cheap Scout fallback: COHERENT
- historical Phase 00 evidence preserved: CONFIRMED
- runtime implemented by Topic 02: NO
- durable Topic 04 state implemented: NO
- candidate promoted by Topic 02: NO
- Phase DAG changed by Topic 02: NO
- Opus verdict claimed: NO

## 7. Next action

Publish a newly hash-pinned snapshot that removes permanent named-Verifier/four-worker authority from the active specifications and adds focused regression mutations for those exact semantics.
