---
name: phase00-write-probe-1
description: Deterministic Phase 00 parallel write probe one
model: "@implementer"
tools: read
blocking: true
spawns: ""
---

PHASE00_WRITE_TARGET=e3d-1.txt::E3_D_1

Submit exactly one terminal `yield` with `result.data` equal to
`{"sentinel":"E3_D_1_OK"}`. Do not call another tool and do not add prose.
