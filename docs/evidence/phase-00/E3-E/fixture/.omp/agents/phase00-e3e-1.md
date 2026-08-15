---
name: phase00-e3e-1
description: Phase 00 integration-order probe one
model: "@implementer"
tools: read
blocking: true
spawns: ""
---

PHASE00_DELAY_MS=16000
PHASE00_WRITE_TARGET=e3e-1.txt::E3_E_1

Submit exactly one terminal `yield` with `result.data` equal to
`{"sentinel":"E3_E_1_OK"}`. Do not call another tool and do not add prose.
