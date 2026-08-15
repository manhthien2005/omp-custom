---
name: phase00-e1-caller-only
description: E1 caller-owned output probe without agent output
blocking: true
tools: read
spawns: ""
---

Terminal-yield `result.data` exactly as `{"sentinel":"E1_CALLER_ONLY"}`.
Make exactly one terminal `yield` call and do nothing else.
