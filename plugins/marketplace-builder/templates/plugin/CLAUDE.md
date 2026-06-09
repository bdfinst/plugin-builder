# __NAME__

__DESCRIPTION__

## What ships

Everything under this directory (`plugins/__NAME__/`) ships wholesale to end
users via the catalog's git-subdir `source`. Do not place tests or build tooling
here — those live at the repo root (`tests/`, `scripts/`).

## Runtime helpers

Reference every executed helper as `${CLAUDE_PLUGIN_ROOT}/<path>` so it resolves
once installed (the agent's cwd is the user's project, not the plugin root).

## Commands

<!-- Document each /command this plugin provides and the conventions it enforces. -->
