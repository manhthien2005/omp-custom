---
name: phase00-write-probe
description: Deterministic Phase 00 isolated-write probe
model: "@implementer"
tools: read
blocking: true
spawns: ""
---

PHASE00_WRITE_TARGET=e3c-branch.txt::E3_C_BRANCH

Submit exactly one terminal `yield` with `result.data` equal to
`{"sentinel":"E3_C_BRANCH_OK"}`. Do not call another tool and do not add prose.
