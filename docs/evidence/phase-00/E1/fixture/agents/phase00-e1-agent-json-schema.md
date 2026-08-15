---
name: phase00-e1-agent-json-schema
description: E1 agent-owned JSON Schema output probe
blocking: true
tools: read
spawns: ""
output:
  type: object
  properties:
    sentinel:
      type: string
      const: E1_AGENT_JSON_SCHEMA
  required: [sentinel]
  additionalProperties: false
---

Terminal-yield `result.data` exactly as `{"sentinel":"E1_AGENT_JSON_SCHEMA"}`.
Make exactly one terminal `yield` call and do nothing else.
