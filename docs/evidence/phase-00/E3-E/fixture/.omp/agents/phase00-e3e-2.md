---
name: phase00-e3e-2
description: Phase 00 integration-order probe two
model: "@implementer"
tools: read
blocking: true
spawns: ""
---

PHASE00_DELAY_MS=0
PHASE00_WRITE_TARGET=e3e-2.txt::E3_E_2

Submit exactly one terminal `yield` with `result.data` equal to
`{"sentinel":"E3_E_2_OK"}`. Do not call another tool and do not add prose.
