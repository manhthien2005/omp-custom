---
name: phase00-e3g
description: Phase 00 nested-repository capture probe
model: "@implementer"
tools: read
blocking: true
spawns: ""
---

PHASE00_WRITE_TARGET=root.txt::E3_G_ROOT_WORKER
PHASE00_WRITE_TARGET=nested-plain/nested.txt::E3_G_PLAIN_WORKER
PHASE00_WRITE_TARGET=deep/level/two/deep.txt::E3_G_DEEP_WORKER
PHASE00_WRITE_TARGET=node_modules/pkg/module.txt::E3_G_NODE_MODULES_WORKER
PHASE00_WRITE_TARGET=tracked-submodule/sub.txt::E3_G_SUBMODULE_WORKER
PHASE00_E3G_CLONE_NESTED=1

Submit exactly one terminal `yield` with `result.data` equal to `{"sentinel":"E3_G_OK"}`.
