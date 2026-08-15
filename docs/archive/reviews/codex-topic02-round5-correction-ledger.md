# Codex — Topic 02 Round-5 Correction Ledger

```yaml
topic: 02-workflow-entry-task-lifecycle
correction_after_review_round: 5
round5_verdict: REOPEN_TOPIC_02
critical_findings: 0
important_findings: 1
minor_findings: 2
important_findings_corrected_pending_review: 1
minor_findings_corrected_pending_review: 2
active_authority_documents_corrected: 10
focused_mutation_assertions: 78
focused_validator_passes: 262
runtime_implemented: false
phase02_runtime_migration_pending: true
historical_phase00_evidence_preserved: true
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
repository_branch: main
staged_paths: 0
```

## 1. Immutable Round-5 evidence

| Artifact | SHA-256 | Meaning |
|---|---|---|
| `codex-peer-review-packet-topic02-round5.md` | `CE94F2F14B6C6C4E64DD71F11A56C709E01FC431445EF975D096BF618B270B5B` | Frozen Round-5 snapshot |
| `codex-peer-review-prompt-topic02-round5.md` | `E78C65E3751D53ACF7D335C3C2EF0AA69B0D7B7F976B2CED2C7D2EE87AFC4FE3` | Round-5 reviewer instructions |
| `codex-peer-review-response-topic02-round5.md` | `EB7DAAAF7C59A96625F380CF043AF0D05A926636DD6433F183649A4A00DD7CDF` | Verbatim substantive `REOPEN_TOPIC_02` review |
| `codex-topic02-round4-correction-ledger.md` | `0EFC0F62F60373E34A1699FF243B62BA83DD917ADA1E0E4C7263F0E548C0A40F` | Round-4 correction record audited in Round 5 |

Round 5 reproduced all `54/54` packet-listed hashes, the seven historical pins, validators,
source anchors, Git facts, history fences, and the nine reciprocal Phase-DAG edges. It found
one Important selected-path safety defect plus two Minor active-authority drifts. The prior
Round-4 ledger's claim that every selected LSP consumer was fail-closed was false: several
active clauses permitted the same selected symbol-aware contract to continue with weaker
`grep` semantics.

## 2. Finding adjudication and corrections

### R5-F1 / reopened R1-F3, R2-F1, R3-F1, R4-F1 — Selected LSP path must fail closed

The finding is `actionable`. Disclosure does not make `grep` semantically equivalent to LSP,
and preserving a user's explicit `task.enableLsp: false` setting does not authorize the selected
LSP-consuming contract to run without its required capability.

Corrections:

1. **Canonical retrieval and DNA projection**
   - DNA now states that a selected LSP-consuming path fails closed when any required gate is
     unmet and that `grep` cannot satisfy the same semantic contract.
   - Spec 07 replaces its reduced-capability execution with refusal before dispatch or
     acceptance. It identifies all four remediation causes and permits continuation only after
     remediation or explicit selection of a different non-LSP contract, reconciliation, and
     validation.
   - A material change to locked criteria or verification/review obligations still creates a
     linked task/session; the correction does not weaken the accepted task boundary.

2. **Installation and configuration ownership**
   - Spec 12 and Phase 05 continue to preserve explicit user settings and refuse silent
     overwrites.
   - The selected LSP path remains disabled while its conjunction is unmet. The user/global
     installer notice no longer promises a reduced-capability run; it states the remediation or
     explicitly selected and validated non-LSP-contract choices.

3. **Runtime-correctness and evaluation projection**
   - Phase 01 now requires fail-closed preflight and removes the `grep`/glob degradation risk
     mitigation.
   - Spec 13 L1 and L4 require refusal before dispatch for both `task.enableLsp=false` and
     `lsp.enabled=false`; continuing the same contract with `grep` is an explicit failure.
   - Phase 06 now validates this conjunction at L1 and adds a sixth L4 adversarial case proving
     the selected path stops before dispatch or acceptance.
   - A breadth audit corrected spec 10's stale comparison that still called LSP absence a
     reduced-capability mode. Bash and LSP now share the same selected-path fail-closed
     principle while retaining their mechanism-specific outcomes.

### R5-F2 — Phase-03 retrieval exhaustion drift

Phase 03 now projects the canonical `default priority + bounded escalation + named permitted
skip` rule. It no longer requires every retrieval level to be tried before escalation, and its
acceptance criterion requires disclosure of named skips.

### R5-F3 — `.task/` offload attached to isolation, not workflow name

Spec 05 now permits `.task/` only when the worker is non-isolated and its workspace survives the
Tech-Lead lifecycle. That rule applies equally to Standard and sequential non-isolated
Orchestrated execution. Every isolated worker uses the parent artifact domain instead.

## 3. False-negative guard and RED → GREEN evidence

The Round-5 mutations were written before the corresponding helper guards. The first new
fixture proved the old validator did not recognize the invariant:

```text
FAIL [T02-TEST] [dna-lsp-fail-open] expected exactly one FAIL 'T02-DNA-BAN-11'
```

After adding the new required/forbidden semantics, the mutation suite passed while the frozen
Round-5 active snapshot correctly went red:

```text
PASS Topic 02 validator self-test (76 assertions)
Topic 02 lifecycle: 226 passed, 0 warnings, 34 failed
```

The first prose correction exposed a validator defect: required semantic phrases split by
normal Markdown wrapping were treated as missing. A dedicated wrapping fixture reproduced it:

```text
FAIL [T02-TEST] [wrapped-lsp-fail-closed-semantic] expected zero failures, got: T02-DNA-REQ-13
```

The helper now normalizes whitespace in both content and needles before ordinal-insensitive
matching. This addresses the root cause rather than forcing long unwrapped prose lines:

```text
PASS Topic 02 validator self-test (77 assertions)
Topic 02 lifecycle: 260 passed, 0 warnings, 0 failed
```

A final breadth search found the stale LSP comparison in spec 10. Its mutation was again added
before its guard and failed as expected:

```text
FAIL [T02-TEST] [stale-lsp-reduced-capability-comparison] expected exactly one FAIL 'T02-REVIEW-BAN-6'
```

After guard and prose correction, final focused evidence is:

```text
PASS Topic 02 validator self-test (78 assertions)
Topic 02 lifecycle: 262 passed, 0 warnings, 0 failed
```

Full repository validation:

```text
Results: 102 passed, 1 warnings, 0 failed
VALIDATION PASSED WITH WARNINGS
```

The sole warning remains the pre-existing approximate `template/.omp/RULES.md` budget
(`226 < 300`). `git diff --check` exits `0` with only the unrelated pre-existing Phase-00
CRLF→LF advisory. The Phase DAG has nine expected reciprocal edges and zero failures.

## 4. Corrected snapshot hashes

| File | Corrected SHA-256 |
|---|---|
| `spec/key/01-dna.md` | `8376DD5D4CCF05A00F5A2E928ADB4B6BFE5BAB25C8F53A12152CD25957D23C7B` |
| `spec/05-context-and-token-model.md` | `9AC69603D50BF2966906BEDCB22BAAEDFBBDEB15FD3B3ACEA5EB50CFDB02544E` |
| `spec/07-retrieval-and-code-understanding.md` | `79EB094B303B89E245C12739387A8C3EFD99CC12C052F3AC7B71300F9054F9DB` |
| `spec/10-verification-and-review.md` | `7EAD3E10B52222FCE0E94F57BB89DED4692CE3F3FEA0AC6C63B4288810B92167` |
| `spec/12-installation-and-rollback.md` | `9F284EC8A652801DD10AFD8D4163E49D5BFAE7AE477AC6F242AF0D4D2B3CB19F` |
| `spec/13-validation-and-evaluation.md` | `28500C45BCAE811FE066A6935E4E029FEE43B4896F9FF00B6CEA19B8B167AD37` |
| `spec/phases/phase-01-runtime-correctness.md` | `58FF2161263E02BB4408485A4828C824D908EEDA98B232687F7B33385AF8080A` |
| `spec/phases/phase-03-context-efficiency.md` | `C56FB899B646470AD44D96526B5E60B596272F815415CCC6193A0D75F5C0FCAA` |
| `spec/phases/phase-05-installation-hardening.md` | `C095FF47ECC1DDCDB7FC360473221047F67FCAC4127B8585D31E9C39C21B0F9D` |
| `spec/phases/phase-06-evaluation.md` | `6619C8518DA37A3A623AC9F057482D221BECF488D6FDA8B470B12645F6EC7C57` |
| `scripts/lib/topic02-workflow-lifecycle.ps1` | `98EA82C492039EA77078771819A75C3D9CB55281BDAD42A9FDEC9CE924B3CD37` |
| `scripts/tests/topic02-workflow-lifecycle.Tests.ps1` | `A3CF83F625E642CBD9124F1F2096556929FE5C0050CFD7271DC3DFAA6B44981A` |

## 5. Preserved boundaries and non-claims

- R1-F1 remains closed; task start still locks required verification/review obligations and the
  material-change rule still covers them.
- Topic 03 still owns roster, worker graph, role names, dispatch, capabilities, schemas, and the
  selected skill set. The correction changes selected-path safety, not topology ownership.
- Topic 04 still owns durable lifecycle state; Topic 08 still owns deeper triage.
- Phase 02 still owns future runtime projection and must create new current-product evidence.
- Phase-02 Appendix A and Phase 00 remain historical evidence. All seven historical pins remain
  byte-identical.
- The pinned OMP checkout remains clean at commit
  `3a8591a8af5b6d200088d12ca75a5517cb064fa8` with coding-agent `17.2.10`.
- No runtime prompt, product documentation, durable state, topology implementation, evaluation
  harness, candidate promotion, stage/index, commit, push, or PR was created.
- Round 6 must independently audit the full corrected snapshot. This ledger does not close
  Topic 02.
