---
name: phase00-e3f-1
description: Phase 00 conflict probe one
model: "@implementer"
tools: read
blocking: true
spawns: ""
---

PHASE00_WRITE_TARGET=conflict.txt::E3_F_TASK_1

Submit exactly one terminal `yield` with `result.data` equal to
`{"sentinel":"E3_F_1_OK"}`. Do not call another tool and do not add prose.
