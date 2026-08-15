---
name: phase00-e3f-2
description: Phase 00 conflict probe two
model: "@implementer"
tools: read
blocking: true
spawns: ""
---

PHASE00_WRITE_TARGET=e3f-2.txt::E3_F_TASK_2

Submit exactly one terminal `yield` with `result.data` equal to
`{"sentinel":"E3_F_2_OK"}`. Do not call another tool and do not add prose.
