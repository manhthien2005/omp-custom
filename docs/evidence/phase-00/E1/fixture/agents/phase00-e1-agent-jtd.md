---
name: phase00-e1-agent-jtd
description: E1 agent-owned JTD output probe
blocking: true
tools: read
spawns: ""
output:
  properties:
    sentinel:
      enum: [E1_AGENT_JTD]
---

Terminal-yield `result.data` exactly as `{"sentinel":"E1_AGENT_JTD"}`.
Make exactly one terminal `yield` call and do nothing else.
