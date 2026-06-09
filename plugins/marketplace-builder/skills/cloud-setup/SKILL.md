---
name: cloud-setup
description: Generate the gated SessionStart install hook plus cloud-setup.sh and a "use skills directly" fallback so the marketplace is usable in Claude Code web/cloud sessions. Use to make a marketplace cloud-aware.
user-invocable: true
---

# /cloud-setup

Make the marketplace usable in cloud/web sessions: install prerequisites at
session start, gated so local sessions are unaffected, with a skill-file
fallback when the hook can't run.

## Before you start

Read `${CLAUDE_PLUGIN_ROOT}/knowledge/marketplace-conventions.md` (§5, cloud-aware).

## Procedure

1. **cloud-setup.sh.** Copy
   `${CLAUDE_PLUGIN_ROOT}/templates/cloud/cloud-setup.sh` to
   `.claude/cloud-setup.sh`; replace `__NAME__` with the marketplace handle.
   It self-gates (acts only in cloud/CI sessions) and runs once per session,
   delegating to `scripts/dev-setup.sh`.

2. **SessionStart hook.** Merge the `SessionStart` block from
   `${CLAUDE_PLUGIN_ROOT}/templates/cloud/settings.json` into
   `.claude/settings.json` (create it if absent). The command is
   `bash .claude/cloud-setup.sh`.

3. **Fallback.** In the root CLAUDE.md, add a short "Cloud sessions" note: if the
   hook did not run (e.g. settings not loaded), the user can invoke the
   marketplace's skills directly and run `bash scripts/dev-setup.sh` by hand.

4. **Verify + report.** Run `bash -n .claude/cloud-setup.sh`, validate
   `.claude/settings.json` with `jq`, and report what was wired.
