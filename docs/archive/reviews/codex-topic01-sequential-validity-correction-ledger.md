# Topic 01 correction ledger — sequential validity after Codex peer review

```yaml
topic: 01-optimization-metrics
correction: sequential-valid-adaptive-promotion
date: 2026-08-12
reviewer_substitution_authority: user-approved-codex-temporarily
original_opus_status: PENDING_UNAVAILABLE
runtime_changed: false
benchmark_harness_implemented: false
thresholds_changed: false
historical_packets_edited: false
```

## 1. Why this correction exists

Claude Opus was unavailable because no usable account/quota existed. The user explicitly
authorized Codex as the temporary reviewer. Two fresh `gpt-5.6-sol` / `xhigh` Codex CLI
attempts were run:

1. Attempt 01 returned `INSUFFICIENT_EVIDENCE` after reporting a decision-log hash that no
   executed byte-level command produced. The controller recomputed the raw UTF-8/LF file hash
   as the frozen expected value; the review log showed the sandbox had rejected its hashing
   commands. The alleged mismatch was rejected as a tool artifact.
2. Attempt 02 again could not execute hashes because of the CLI policy, but completed the
   substantive audit. Nine mandatory questions passed. Question 8 failed because the written
   protocol repeatedly inspected nominal 95% intervals under adaptive stopping without a
   confidence sequence, alpha-spending schedule, or equivalent sequential error control.

The Important Attempt 02 finding is technically correct. Freezing a stopping rule prevents
post-hoc rule changes; it does not preserve 95% coverage when ordinary intervals are inspected
repeatedly. A chance early boundary crossing could therefore change a promotion verdict.

## 2. Adjudication

```yaml
finding: adaptive-stopping-does-not-preserve-promised-95-percent-confidence
severity: Important
classification: actionable
disposition: accepted_and_corrected
contract_effect: preserves_user_approved_95_percent_gate
threshold_effect: none
scope_effect: none
```

The smallest faithful correction is a predeclared joint sequential procedure. It may be an
anytime-valid paired confidence sequence, a finite look schedule with explicit alpha spending
and multiplicity adjustment, or an equivalent construction. It must bound the probability of
any false promotion at `<=0.05` across all interim looks, both promotion paths, and every
promotion-bearing bound. Nominal per-look intervals are descriptive only. Pilot observations
cannot be added retroactively after selection; they enter final inference only when the
procedure was frozen before the pilot and defines it as the first look.

## 3. Files corrected

| File | Frozen pre-correction SHA-256 | Corrected SHA-256 | Correction |
|---|---|---|---|
| `docs/superpowers/specs/2026-08-12-topic-01-optimization-metrics-design.md` | `D4505E510A66D5746A88AAE53BDDDF017DC7B0D0FCECAA811656D939B684FCF3` | `437CF16D1759357AE51DE347DDF13D8721F193DD0977A8CA3A9C77611A45BBC5` | Sequential-valid design and pilot boundary |
| `spec/key/03-token-quality-model.md` | `F83A471CD01377BBE24F98679359B8D86354AEDE87941130D8167D2E1E186D27` | `DF235DA4712B8B2144F87A1CD8BC004EEC4648629D39E15BFC3EFDDFBC7830EF` | Canonical promotion authority |
| `spec/key/04-decision-log.md` | `D1A99C8C0094837A8FBBBAD773EC6CFAAB168D4306C1B9D5CED4F9CBD72C5AE2` | `7F01A324E1FC35D811815DF40665E39B37A9C8F1F81CF3468274731E17447D8E` | Appended KD-025; KD-024 history retained |
| `spec/13-validation-and-evaluation.md` | `F92E031ED121297BC34A4365659C37A3F644E713342470540DC6A799A7347DEA` | `78F1157C614CC27CCC2CF7053FADD8DC6CB142D0DEC56AA57BFD89A2B347D062` | Executable sequential contract and AC-17 |
| `spec/phases/phase-06-evaluation.md` | `3682FF448A23F81EF951229FA4AE1075BD7AF451AD89EC3221FC66F431F46E28` | `1301FB89CDF6225C6A644021093728DE2E0B37C782AB47B373E10290FCD8E153` | Harness task, fixtures, verification, exit gate |
| `CHANGELOG.md` | `718932BCEADB64E8F8ACD0264317CDDEA61D46F2F099ADC35D1319A572CE169D` | `C920B7E0B05B8EAD334AAE23AD64C623390A7E3831F94B3B1FE7226C26338B7C` | Concise sequential-valid qualifier |

All other load-bearing Topic 01 files retain their original frozen hashes.

## 4. Corrected semantic contract

- The approved 5% non-inferiority margin, 10% efficiency improvement, 10% quality-win token
  ceiling, hard gates, outcome denominator, accounting ledgers, Cheap Scout treatment, latency
  role, and dual baselines are unchanged.
- The statistical 95% claim now applies to the complete adaptive promotion decision rather
  than to each independently recomputed snapshot.
- Overall false-promotion probability is at most 5% across interim looks, both win paths, and
  all promotion-bearing bounds.
- Ordinary per-look paired/bootstrap intervals remain useful descriptive telemetry but never
  authorize adaptive promotion.
- Missing sequential metadata, an undeclared look, exhausted/missing alpha allocation, or
  pilot reuse outside the frozen procedure fails promotion closed.
- No statistical implementation is selected here. Phase 06 may choose any construction that
  satisfies and verifies this contract.

## 5. Fresh validation evidence

```text
scripts/validate-template.ps1
102 passed, 1 warning, 0 failed
```

The warning remains the pre-existing advisory `template/.omp/RULES.md` approximate budget
below target (`226 < 300`).

Additional checks:

- `git diff --check`: exit 0; only the pre-existing Phase 00 CRLF warning appeared in the full
  repository scan.
- Markdown fence balance: `16/16` active Topic 01 targets.
- Required sequential terms appear in design, decision authority, decision log, evaluation
  authority, Phase 06, and changelog.
- Superseded phrases `predeclared adaptive stopping rule`, `Final sampling is adaptive`,
  `final adaptive 95%`, and `predeclared adaptive 95%` have no active match in those targets.

## 6. Explicit non-claims

- Topic 01 still implements no runtime, benchmark harness, confidence sequence, alpha-spending
  function, provider route, or Cheap Scout deployment.
- No candidate has been benchmarked or promoted.
- The correction does not reopen Topic 0, modify Phase 00/DAG work, or edit historical Opus or
  Codex response artifacts.
- The two earlier Codex top-level verdicts remain historical `INSUFFICIENT_EVIDENCE`; neither is
  rewritten as acceptance.

## 7. Required closure audit

The next reviewer must independently verify the corrected hashes, confirm the correction
actually supplies joint sequential validity without changing the approved numeric thresholds,
recheck all ten original mandatory questions, and return exactly one of:

```text
ACCEPT_TOPIC_01
REOPEN_TOPIC_01
INSUFFICIENT_EVIDENCE
```
