---
name: add-plugin
description: Scaffold a new plugin inside an existing marketplace — the shipped dir skeleton, plugin.json, install.sh with the Git-Bash guard, settings.json, and CLAUDE.md; then register it in the catalog and in release-please packages with the catalog extra-files sync. Use when adding a plugin to a marketplace.
user-invocable: true
---

# /add-plugin `<name>` [description]

Add a new shipped plugin to the current marketplace and wire its release/catalog
sync.

## Before you start

Read `${CLAUDE_PLUGIN_ROOT}/knowledge/marketplace-conventions.md` (§2, §5b, §6).
Confirm `.claude-plugin/marketplace.json` exists (run `/new-marketplace` first if
not). Find the repo `url` from the root CLAUDE.md or ask the user.

**Choose the right primitive for each behavior (§5b).** Apply the order
*deterministic tool/hook → skill → agent*. If a behavior is deterministic (lint,
validate, format, block, install), wire it as a **hook** to a script under
`hooks/` — do not default to a skill. Use a **skill** for reusable procedures
needing judgment, and an **agent** (via `/add-agent`) for complex, high-context
reasoning. Do not create a skill that merely runs one fixed command.

## Procedure

1. **Shipped dir skeleton.** Create `plugins/<name>/` with `.claude-plugin/`,
   `skills/`, `commands/`, `agents/`, `hooks/`, `knowledge/`, `templates/`. Only
   create the subdirs the plugin will actually use; never create a `tests/` dir
   inside the plugin.

2. **Manifest.** Copy `${CLAUDE_PLUGIN_ROOT}/templates/plugin/plugin.json` to
   `plugins/<name>/.claude-plugin/plugin.json`; fill `__NAME__`,
   `__DESCRIPTION__`, `__OWNER_NAME__`. Version starts at `0.1.0`.

3. **install.sh.** Copy `${CLAUDE_PLUGIN_ROOT}/templates/plugin/install.sh` (it
   includes the Windows/Git-Bash guard); replace `__NAME__`; `chmod +x`. Add any
   plugin-specific `need <tool>` checks.

4. **settings.json + CLAUDE.md.** Copy the templates from
   `${CLAUDE_PLUGIN_ROOT}/templates/plugin/`. If the plugin has no hooks, you may
   omit `settings.json`. Document the plugin's commands in its CLAUDE.md.

5. **Register in the catalog.** Append an entry to
   `.claude-plugin/marketplace.json` `.plugins`:
   ```json
   {
     "name": "<name>",
     "version": "0.1.0",
     "description": "<description>",
     "source": {
       "source": "git-subdir",
       "url": "<repo-url>",
       "path": "plugins/<name>",
       "ref": "<name>-v0.1.0"
     }
   }
   ```
   Use `jq` to edit so the JSON stays valid.

6. **Register the release package.** Add the per-plugin block from
   `${CLAUDE_PLUGIN_ROOT}/templates/release/release-please-config.json` (with
   `__NAME__` replaced) into `release-please-config.json` `.packages`, and add
   `"plugins/<name>": "0.1.0"` to `.release-please-manifest.json`. This wires the
   `extra-files` catalog sync so version + ref can never drift.

7. **Verify + report.** Run `bash scripts/ci-local.sh` (or at minimum
   `bash scripts/structural-check.sh` and `bats tests/repo`). Report the new
   files and the green gate.

Refuse to place any test/build script inside `plugins/<name>/`; if the plugin
needs tests, put them under repo-root `tests/<name>/`.

**Every script you create must be cross-platform (§4).** Any bash script must run
on macOS, Linux, and Windows Git Bash (`#!/usr/bin/env bash`, bash 3.2-safe, no
GNU-only constructs); scripts in other languages must run on all three too. Do
not write OS-specific scripts. Run `/portability-check` after adding any script.
