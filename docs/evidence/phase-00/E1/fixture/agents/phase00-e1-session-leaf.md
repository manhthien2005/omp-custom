---
name: phase00-e1-session-leaf
description: E1 nested leaf parent-session fallback probe
blocking: true
tools: read
spawns: ""
---

Terminal-yield `result.data` exactly as `{"session_sentinel":"E1_SESSION_ONLY"}`.
Make exactly one terminal `yield` call and do nothing else.
