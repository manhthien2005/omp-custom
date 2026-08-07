# Token Impact Analysis
<!-- Generated: 2026-08-07 — Phase 2 -->

## Methodology

Token counts are estimated, not measured. All estimates assume GPT-5.6 tokenization (≈ 3.5 chars/token).
"Persistent" = loaded on every session start. "Lazy" = loaded only when triggered.
Primary metric: **tokens per accepted outcome** (not lowest token count).

---

## Persistent context budget

| Component | Target | Hard Warning | Load type |
|-----------|--------|--------------|-----------|
| `template/.omp/AGENTS.md` | 600–1,200 | > 1,500 | Persistent |
| `template/.omp/RULES.md` | 300–700 | > 800 | Sticky (re-attached each turn) |
| Each agent system prompt | 500–1,200 | > 1,500 | Per-subagent session |
| Each skill description (system prompt stub) | 30–80 tokens | > 120 | Persistent (all skills listed) |
| Each skill body (`skill://` on demand) | 800–2,000 | > 2,500 | Lazy |
| Task packet | Task-relevant only | No raw history | Per-task |
| Agent result / worker result | Structured + evidence | No chain-of-thought | Per-result |

---

## Token impact per mechanism

### Positive token savers

| Mechanism | Estimated Saving | How |
|-----------|-----------------|-----|
| OMP shake compaction | 20,000–80,000 tokens/session | Replaces tool results with `artifact://` references; `keepRecentTokens=20,000` |
| `compaction.dropUseless=true` | 500–5,000 tokens/session | Elides results flagged as useless (zero-match searches, etc.) |
| `read.summarize.enabled=true` | 1,000–10,000 tokens/session | OMP returns structured summaries instead of full file content |
| `compaction.supersedeReads=true` | 1,000–8,000 tokens/session | Removes superseded reads from context |
| Skills progressive disclosure | 2,000–8,000 tokens/session | Skill bodies not loaded until triggered |
| No parent-transcript forwarding | 5,000–30,000 tokens/task | Task packets carry only task-relevant context |
| Structured worker results (no chain-of-thought) | 2,000–10,000 tokens/task | Results are compact structured artifacts, not transcripts |
| Progressive retrieval order | 500–3,000 tokens/session | Avoids expensive web/doc calls when local code suffices |
| Symbol-first exploration (Explorer) | 1,000–5,000 tokens/task | Reads symbol references before full files |

### Token additions (justified)

| Mechanism | Estimated Addition | Justification |
|-----------|-------------------|---------------|
| AGENTS.md coding constitution | +800–1,200 tokens (one-time per session) | Prevents rework: eliminates speculative abstractions, scope creep, false completions |
| RULES.md sticky invariants | +300–700 tokens (re-attached per turn) | Prevents catastrophic violations in long sessions |
| Five agent definitions | +500–1,200 per agent (per-agent session only) | Each agent only spawned when needed; not loaded into main session |
| Task packet (structured) | +300–800 tokens per task | Enables evidence-based verification; prevents ambiguity rework |
| Verification-result schema | +200–500 tokens per verification | Enables independent verification; prevents false completion claims |
| Review-result schema | +300–600 tokens per review | Review only in Standard/Orchestrated workflow, not Quick |
| Systematic-debugging skill | +1,200–2,000 tokens (lazy) | Only loaded when a bug is encountered; prevents multi-fix thrashing |

### Token additions (unjustified — rejected)

| Mechanism | Would Add | Why Rejected |
|-----------|----------|-------------|
| Always-on multi-reviewer workflow | +3,000–8,000 per task | Marginal quality gain; Reviewer enabled selectively |
| Persistent memory (autolearn) | +5,000–20,000/session | Uncontrolled growth; no evidence of quality improvement |
| Full context forwarding to subagents | +10,000–50,000/task | No quality gain; severe cost; 12FA principle violation |
| Full repo dump (repomix default) | +20,000–200,000 one-time | Floods context; use only for onboarding/audits |
| Permanent specialist knowledge (all quality gates always on) | +2,000–5,000/session | Most quality gates only relevant to specific task types |
| Duplicate coding-constitution across all agent prompts | +3,000–6,000/task | Coding constitution in AGENTS.md once is sufficient |

---

## Workflow-level token estimates

### Quick workflow (single session, no subagents)
- Session start: AGENTS.md (~900) + RULES.md (~400) + skill stubs (~200) = ~1,500 persistent
- Task execution: 1–3 file reads + edit + verify ≈ 5,000–15,000 total
- No subagent overhead

### Standard workflow (Tech Lead + 2–3 subagents)
- Session start: ~1,500 persistent
- Explorer task packet: ~600 + exploration results ~3,000
- Implementer task packet: ~800 + implementation evidence ~2,000
- Verifier task packet: ~500 + verification result ~500
- Total additional: ~7,400 tokens of structured overhead
- Quality gain: independent verification, structured evidence

### Orchestrated workflow (Tech Lead + 5+ subagents)
- Session start: ~1,500 persistent
- Per-agent overhead: ~1,000–2,000 per agent
- Additional with reviewer: ~1,500
- Total additional: ~10,000–15,000 over Quick
- Quality gain: parallel exploration, architecture review, independent verification, code review

---

## Token efficiency optimization checklist

The following are enforced by the validation script:

- [ ] `AGENTS.md` ≤ 1,500 tokens
- [ ] `RULES.md` ≤ 800 tokens
- [ ] Each agent definition ≤ 1,500 tokens
- [ ] Skill descriptions (frontmatter) ≤ 120 tokens each
- [ ] No task packet contains parent transcript
- [ ] No worker result contains chain-of-thought narrative
- [ ] No duplicate coding principles across agent definitions
- [ ] No full repository dump by default

---

## Primary optimization metric

> **tokens per accepted outcome**

Not: lowest token count. Not: highest task success rate.

A workflow that uses 20% more tokens but produces 50% fewer rewrites is more efficient.
A workflow that uses fewer tokens but fails verification and requires three retries is less efficient.
