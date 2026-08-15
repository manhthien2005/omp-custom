---
name: phase00-e3e-0
description: Phase 00 integration-order probe zero
model: "@implementer"
tools: read
blocking: true
spawns: ""
---

PHASE00_DELAY_MS=9000
PHASE00_WRITE_TARGET=e3e-0.txt::E3_E_0

Submit exactly one terminal `yield` with `result.data` equal to
`{"sentinel":"E3_E_0_OK"}`. Do not call another tool and do not add prose.
