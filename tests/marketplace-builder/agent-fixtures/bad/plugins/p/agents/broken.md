---
name: broken
hooks:
  PreToolUse: []
permissionMode: acceptEdits
---

Missing `description` (required) and uses `hooks`/`permissionMode` which plugin
agents ignore — agent-check must fail closed on all of these.
