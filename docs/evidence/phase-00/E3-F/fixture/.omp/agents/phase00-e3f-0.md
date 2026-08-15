---
name: phase00-e3f-0
description: Phase 00 conflict probe zero
model: "@implementer"
tools: read
blocking: true
spawns: ""
---

PHASE00_WRITE_TARGET=conflict.txt::E3_F_TASK_0

Submit exactly one terminal `yield` with `result.data` equal to
`{"sentinel":"E3_F_0_OK"}`. Do not call another tool and do not add prose.
