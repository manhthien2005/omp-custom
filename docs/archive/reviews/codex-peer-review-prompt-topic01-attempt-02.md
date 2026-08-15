# Codex Peer Review — Topic 01 — Attempt 02 launcher

Run the complete adversarial audit defined in
`codex-peer-review-prompt-topic01-optimization-metrics.md`, whose SHA-256 is
`6B7FAEE9BE002E2022426D4B1ACD7A0B86A00A68B59ABABFFA795C7A8A7CF118`, with these mandatory
attempt-specific instructions:

1. Start fresh. Do not inherit the verdict from Attempt 01.
2. Attempt 01 ran in a Windows read-only sandbox that rejected every shell hashing command.
   It nevertheless reported an unsupported decision-log hash
   `AA517C5CAF531DD8A32E0F346FB255D2542291F1BCACCA5A7DA918DC4F32DFA0` and stopped.
3. The controlling process then read the actual file bytes with .NET SHA-256 and observed:

   ```text
   spec/key/04-decision-log.md
   raw bytes:     D1A99C8C0094837A8FBBBAD773EC6CFAAB168D4306C1B9D5CED4F9CBD72C5AE2
   LF-normalized: D1A99C8C0094837A8FBBBAD773EC6CFAAB168D4306C1B9D5CED4F9CBD72C5AE2
   bytes: 51994; CRLF: 0; bare LF: 928; UTF-8 BOM: false
   ```

4. Your sandbox permits shell execution for this attempt solely so you can run read-only
   inspection and hashing commands. The review remains non-mutating: do not edit, create,
   delete, format, stage, commit, or otherwise change any file or Git state.
5. Recompute the decision-log byte hash with `Get-FileHash -Algorithm SHA256` or an equivalent
   byte-level command. If it matches `D1A99C...C5AE2`, classify Attempt 01's mismatch as a tool
   artifact and continue the entire substantive audit. If an executable byte-level command
   produces a different hash, return `INSUFFICIENT_EVIDENCE` with the exact command and output.
6. Recheck the other frozen hashes, source claims, and all ten mandatory questions. Do not stop
   merely because Attempt 01 stopped.
7. Return the exact response format and verdict vocabulary required by the primary prompt,
   headed `# Codex Peer Review — Topic 01 — Attempt 02`.
