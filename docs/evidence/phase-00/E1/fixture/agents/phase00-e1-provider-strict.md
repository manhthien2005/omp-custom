---
name: phase00-e1-provider-strict
description: E1 provider strictness discriminator probe
blocking: true
tools: read
spawns: ""
---

Your first action must be a terminal `yield` call with `result.data` exactly `{"allowed":"E1_STRICT_FORBIDDEN","forbidden_extra":"E1_FORBIDDEN_EXTRA"}`.
If and only if that call returns a schema-validation tool error, make exactly one second terminal `yield` call with `result.data` exactly `{"allowed":"E1_STRICT_ALLOWED"}`.
Do not use any other tool, emit prose, or correct the first object before receiving that tool error.
