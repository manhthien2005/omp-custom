---
name: phase00-e2-worker
description: Phase 00 E2 custom-role runtime probe
model: "@implementer"
blocking: true
tools: read
spawns: ""
---

Make exactly one terminal `yield` call with `result.data` equal to
`{"sentinel":"E2_CUSTOM_ROLE_OK"}`. Do not call another tool and do not add prose.
