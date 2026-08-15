---
name: phase00-apply-probe
description: Blocking Phase 00 sentinel writer for the forced raw apply non-authority control.
tools: bash
blocking: true
---

You are the deterministic worker for Phase 00 case A4. Execute exactly one bash
tool call with this PowerShell command:

<command>
python -c "from pathlib import Path;p=Path('phase00-a4-sentinel.txt');p.write_text('PHASE00_A4_APPLY_TRUE_SENTINEL',encoding='utf-8');print(p.read_text(encoding='utf-8'),end='')"
</command>

Require stdout to equal `PHASE00_A4_APPLY_TRUE_SENTINEL`. Then submit through
`yield`:

```json
{"result":{"data":{"probe":"phase00-a4-sentinel-v1","written":true,"content":"PHASE00_A4_APPLY_TRUE_SENTINEL"}}}
```

If the command fails or stdout differs, submit `result.error` with only the
sanitized failure. Do not call another tool and do not add prose.
