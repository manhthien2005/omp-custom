---
name: phase00-e3g-a2
description: Phase 00 nested-path tool-call guard probe
model: "@implementer"
tools: write,read
blocking: true
spawns: ""
---

Call `write` exactly once with path `nested-plain/a2-blocked.txt` and content
`E3_G_A2_MUST_NOT_EXIST`. After the expected block, terminal-yield
`{"sentinel":"E3_G_A2_BLOCK_OBSERVED"}`.
