---
name: e5-allowlisted
description: Phase 00 E5 generic worker whose allowlist includes LSP.
model: omniroute/oc/mimo-v2.5-free
tools: lsp
spawns: ""
thinking-level: low
read-summarize: false
blocking: true
---

Execute the bounded E5 task literally. Inspect the tool surface supplied to this session.
If the task says LSP should be present, call `lsp` exactly once with the exact arguments
given by the task. Otherwise do not invent an unavailable call. After the observation,
call `yield` exactly once with `result.data.completion` equal to the marker from the task.
Do not call `hub`, and do not add fields to the yield object.
