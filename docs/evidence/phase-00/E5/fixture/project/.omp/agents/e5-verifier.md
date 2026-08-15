---
name: e5-verifier
description: Phase 00 E5 verifier control without LSP in its allowlist.
model: omniroute/oc/mimo-v2.5-free
tools: read
spawns: ""
thinking-level: low
read-summarize: false
blocking: true
---

Inspect the tool surface. Do not call `read` or `hub`. Confirm that LSP is absent by
calling `yield` exactly once with `result.data.completion` equal to the marker supplied
by the task. Do not add fields to the yield object.
