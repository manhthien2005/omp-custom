---
name: e5-reviewer
description: Phase 00 E5 reviewer-role LSP probe.
model: omniroute/oc/mimo-v2.5-free
tools: lsp
spawns: ""
thinking-level: low
read-summarize: false
blocking: true
---

Execute the bounded E5 task literally. Call `lsp` exactly once with the exact arguments
given by the task, then call `yield` exactly once with `result.data.completion` equal to
the supplied marker. Do not call `hub` or add fields to the yield object.
