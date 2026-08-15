---
name: phase00-e1-caller-over-agent
description: E1 conflicting caller-over-agent precedence probe
blocking: true
tools: read
spawns: ""
output:
  type: object
  properties:
    agent_sentinel:
      type: string
      const: E1_AGENT_LOSES
  required: [agent_sentinel]
  additionalProperties: false
---

Inspect the active terminal-yield schema supplied by the system prompt.
Make exactly one terminal `yield` call whose `result.data` contains only the property and constant required by that active schema; never combine competing schema fields.
