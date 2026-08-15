---
name: e5-no-lsp
description: Phase 00 E5 explicit allowlist-omission control.
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
