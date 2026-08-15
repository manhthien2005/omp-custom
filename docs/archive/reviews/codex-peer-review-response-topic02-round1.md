# Codex Peer Review — Topic 02 — Round 1

## 1. Verdict

REOPEN_TOPIC_02

All 28 pinned files match byte-for-byte, the pinned OMP checkout is clean at the expected commit, and all three validators pass with only the documented warning. However, the frozen active authority contains three Important defects: verification obligations are omitted from the canonical task-contract boundary, the DNA still mandates a fixed worker/reviewer topology, and Phase 06 hard-codes that same topology while claiming not to. The verdict policy permits acceptance only with no Critical or Important scoped defect.

## 2. Hash, validator, and source audit

| Check | Expected | Observed | Result |
|---|---|---|---|
| Review packet | `B26118D339C644B75035CA0EFA8B1C443AE0CE7086B31877AEFD0A912EF7D20E` | Same | PASS |
| Design | `DADD361135629B210AFF0F581E3B27FDFD2AB869D04E18476B59691106CF0AFE` | Same | PASS |
| `spec/01-target-architecture.md` | `E022AC1C7BDA7DC27FFEBA41ECFB807B716925C7033B9CBA60B59916D884859A` | Same | PASS |
| `spec/03-agent-topology.md` | `F2AF9FE39C7C942F03CBA5D158F45A60ACE65888707A8171CE17C2CB07389266` | Same | PASS |
| Canonical `spec/04` | `3B5EE8686C5B6FF96E0D573D2C357F7F1922B70D40CE4CBE61C01AABEAF47481` | Same | PASS |
| `spec/05` | `76DDFBE46AE412CB298E296702C90C109E4B032A43AC3AA409AE592CC163FFB8` | Same | PASS |
| `spec/08` | `B1B38CFE6EDE9218D595A40B6C45EC92172DB189F83D29791F2858A584E5EF19` | Same | PASS |
| `spec/10` | `331C7F17E57D634FCF77CFB3B789D7FA71CA6DF6FC596CFDD08AA41EB032818C` | Same | PASS |
| `spec/13` | `E51C32802664040F84144A5A95887E22468234BEDFD16F0A27A4D8F08DF38F57` | Same | PASS |
| `spec/README.md` | `98D08A9E0484C99204708E0B39B354AA6975D0853A9A45DDB83491CC5C1CC2A1` | Same | PASS |
| DNA | `745DFEFBFDDDB638F503CA108DA80A3CFDF27F92620213FD315D0F152D19D73E` | Same | PASS |
| Token-quality model | `3015BE8C1B5D540274547508C5CF2110445071267D4F21D643159962F6079989` | Same | PASS |
| Decision log | `4F4C6A103BB2815C5CA2335A460C42754946BF2623869E9B09A7C83B284AE29D` | Same | PASS |
| Phase 02 | `CA0E002E66D33B9F7F3AAE681D272D8C053BC6AAEA3282DE336D58E6FE670E05` | Same | PASS |
| Phase 03 | `D31591F84DBD6484F0736983541A336D8ED6BB1EC5B141C9164CE679B0366095` | Same | PASS |
| Phase 06 | `D276240CE344816B4243EF5C186CE67A641D83D6E5F2E87B14EFF30DC29CFEAA` | Same | PASS |
| Focused helper | `C44300F726522874B2EFE88AD2E266470C75F063B6740192C5ACA989A8882DB9` | Same | PASS |
| Focused self-test | `743B699780B45BB835011D0D14B9C6605B59E3BAAA665962880D8A6317448AC7` | Same | PASS |
| Focused wrapper | `EC4F5BC38194C3DB4E486D77BDEBC1AAA73E335A49746CCDC44B31AA447582A4` | Same | PASS |
| `CHANGELOG.md` | `C83FF7B6886E682B23B23ACC1A5F37D57DF07F77A90E26401AB55C6A110350C0` | Same | PASS |
| Topic ledger | `B966276CE8C92CC78108921119415163B35D9CAE7EDBAA52C1C7B34FCD18C97B` | Same | PASS |
| Historical `AGENTS.md` | `3F194D81208872B6CDE4A51265156D06A8016810CAA9D24BF37B545E60848BBC` | Same | PASS |
| Historical Tech Lead | `47B3060A725F9C41EA832E2CE8E7CBAEFCAFACB4137A9B4153C2819732016AD2` | Same | PASS |
| Historical Quick | `F4E9081846368DA140923C8D51C7BAB079DA4B75577019A412735DBAC4A21731` | Same | PASS |
| Historical Standard | `F849485369F0E8EE6D7D816752D7CAD263DA5381EF8216C319B19091FCBB626B` | Same | PASS |
| Historical Orchestrated | `D88179FA0C27B9EEDF9EE59B5CD6A59B75FC426BCDAD18061209942C36012D12` | Same | PASS |
| Historical triage skill | `D398AFAE80D199F6951C988A4D13C90FD4EFDE4E2B1290CF8A9AB642977430BC` | Same | PASS |
| Historical validator | `D78594BA7DD28C843BDCCEC6F532FBBB491C9E380FD91B686B2AA70850D61701` | Same | PASS |
| Repository Git state | `main`, `62fecf…`, no staged paths | Exact HEAD/branch; staged count `0` | PASS |
| Pinned OMP | Clean `3a8591a…`, version 17.2.10 | Exact SHA; porcelain empty; `package.json:4` is `17.2.10` | PASS |
| Plain-text expansion | Non-`/` text unchanged | `slash-commands.ts:113-114` | PASS |
| Prompt command gate | Command handlers only for `/` | `agent-session.ts:4945-4964` | PASS |
| Handoff behavior | Generated text, new session, reset, injection | `session-handoff.ts:191-208,217-275` | PASS |
| Focused self-test | 8 assertions | Exit `0`; `PASS ... (8 assertions)` | PASS |
| Focused validator | `60/0/0` | Exit `0`; `60 passed, 0 warnings, 0 failed` | PASS |
| Full validator | `102/1/0` | Exit `0`; only `RULES.md 226 < 300` warning | PASS |
| Contradiction searches | No active conflicting authority | Fixed topology and unconditional review found in DNA; exact-four topology found in Phase 06/spec 13 | FAIL |
| `git diff --check` | Exit `0`; documented unrelated warning allowed | Exit `0`; Phase 00 CRLF→LF warning only | PASS |
| Phase DAG projection | Nine declared edges with reciprocal headers | Current graph and phase headers agree | PASS |

## 3. Findings

### Important — Verification obligations fall outside the canonical task-contract lock

- Classification: actionable
- Claim rejected: “A task starts only after objective, scope/authority, mandatory criteria, and verification obligations are accepted as one contract.”
- Evidence: `codex-peer-review-packet-topic02-round1.md:49`; `spec/04-workflow-sizing.md:48-53`; `docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md:65-70`; `spec/key/04-decision-log.md:947-950`
- Observed: The packet expressly names verification obligations as a fourth contract component. The design, canonical authority, and KD-026 define the contract using only objective, scope/authority, and mandatory acceptance criteria.
- Expected: Required verification and review obligations must be accepted and locked before the task cycle begins.
- Impact: A task can nominally start before its evidence obligations are fixed. Later adding, removing, or weakening a gate is not captured by the stated material-change test, allowing evidence requirements and accounting boundaries to drift inside one task.
- Minimal correction: Add verification obligations to every authoritative task-contract definition and add a focused validator assertion for that exact boundary.

### Important — The load-bearing DNA still mandates topology and unconditional review

- Classification: actionable
- Claim rejected: Topic 03 owns final topology, specialists are optional, and Orchestrated classification alone never forces review.
- Evidence: `spec/key/01-dna.md:142-176`; `spec/key/01-dna.md:519-522`; `spec/04-workflow-sizing.md:137-166,297-305`
- Observed: DNA normatively specifies four depth-one workers, makes Verifier separation permanent, and says review is “Always in Orchestrated.” Unlike `spec/03-agent-topology.md`, these rules are not fenced as a historical hypothesis.
- Expected: Topic 02 must remain topology-neutral; reviewer dispatch is contract/risk-gated.
- Impact: This directly preempts Topic 03 and changes reviewer dispatch, agent count, and spawn requirements. It is an active second authority for mandatory question 8.
- Minimal correction: Recast DNA L2/L7 as source facts or a clearly non-authoritative pre-Topic-03 hypothesis, and replace unconditional review with the canonical contract/risk gate.

### Important — Phase 06 hard-codes the topology it says it must not hard-code

- Classification: actionable
- Claim rejected: Phase 06 validates whatever topology Topic 03 selects without silently changing ownership.
- Evidence: `spec/phases/phase-06-evaluation.md:45-52,69-112,260-262`; `spec/13-validation-and-evaluation.md:53-56,74-83`
- Observed: Phase 06 first forbids hard-coding the four-worker hypothesis, then requires exactly four named agents and four model roles. Its exit criterion again says no fixed worker count. `spec/13` independently requires those same four workers.
- Expected: Validation should derive the selected worker set, stage barriers, and capabilities from Topic 03 authority while separately asserting that Tech Lead is not a discovered worker.
- Impact: Any legitimate Topic 03 topology change would fail Phase 06 by construction, making the plan internally contradictory and ownership-dependent on the old roster.
- Minimal correction: Parameterize L0/L1 over the Topic 03-selected topology manifest and remove exact-count/name requirements not independently required by Topic 02.

## 4. Mandatory-question answers

| # | Decision | Decisive evidence |
|---|---|---|
| 1 | ACCEPT | `slash-commands.ts:113-114`; `agent-session.ts:4945-4964`; `spec/04-workflow-sizing.md:87-122` |
| 2 | ACCEPT | `spec/04-workflow-sizing.md:87-122`; KD-026 at `spec/key/04-decision-log.md:940-945` |
| 3 | ACCEPT | `spec/04-workflow-sizing.md:232-251` |
| 4 | REJECT | Packet `:49-50` requires verification obligations; canonical `spec/04:50-53` omits them |
| 5 | ACCEPT | `spec/04-workflow-sizing.md:58-83,185-226` |
| 6 | ACCEPT | `spec/04-workflow-sizing.md:255-295`; OMP `session-handoff.ts:217-275` |
| 7 | ACCEPT | `spec/04-workflow-sizing.md:199-229`; `spec/13-validation-and-evaluation.md:187-227` |
| 8 | REJECT | `spec/key/01-dna.md:144-176,519-522`; `phase-06-evaluation.md:75-112` |
| 9 | ACCEPT | `spec/04-workflow-sizing.md:297-312`; `spec/key/03-token-quality-model.md:83-91` |
| 10 | REJECT | Topic/Phase preservation is otherwise coherent, but `phase-06-evaluation.md:51-52,75-112` and `spec/13:53-83` preempt Topic 03 |

## 5. Boundary and non-claim check

- plain/no-prefix source feasibility: CONFIRMED
- task/candidate/session boundaries: REOPEN — verification obligations are outside the canonical task-contract definition
- lifecycle/evaluation reconciliation: COHERENT
- structural Orchestrated and optional topology: REOPEN — DNA and Phase 06 retain active fixed-topology rules
- Cheap Scout fallback: COHERENT
- historical Phase 00 evidence preserved: CONFIRMED — all seven pins match
- runtime implemented by Topic 02: NO
- durable Topic 04 state implemented: NO
- candidate promoted by Topic 02: NO
- Phase DAG changed by Topic 02: NO
- Opus verdict claimed: NO

## 6. Next action

Publish a corrected hash-pinned snapshot that reconciles the three Important findings and extends the focused contradiction guards across DNA, task-contract definitions, `spec/13`, and Phase 06.
