# marketplace-builder

A Claude Code **meta-plugin**: it scaffolds, audits, and maintains
plugin-marketplace monorepos. Its source of truth is
`${CLAUDE_PLUGIN_ROOT}/knowledge/marketplace-conventions.md`; every command reads
it before acting.

## Commands

| Command | Role | What it does |
|---|---|---|
| `/new-marketplace <owner>` | scaffold | Create the catalog, repo-root `tests/ scripts/ docs/` trees, CI, `release-please-config.json`, `dev-setup.sh`, the hygiene sensor, and a root `CLAUDE.md`. |
| `/add-plugin <name>` | scaffold | Create `plugins/<name>/` (shipped skeleton, `plugin.json`, `install.sh` with the Git-Bash guard, `settings.json`, `CLAUDE.md`); register it in the catalog and release config with the catalog `extra-files` sync. |
| `/audit-plugin [name]` | audit | Run the hygiene sensor + structural checks + portability sweep. Report findings; offer fixes. |
| `/portability-check` | audit | `shellcheck -x` shipped + dev scripts; flag bash-4/GNU-only constructs; verify shebangs; check the Git-Bash `install.sh` guard. |
| `/release-setup` | scaffold | Wire `release-please` per-plugin packages + the `marketplace.json` `extra-files` jsonpath sync. |
| `/cloud-setup` | scaffold | Generate the gated `SessionStart` install hook + `cloud-setup.sh` + a skill-file fallback. |

## The conventions it enforces

1. **A plugin ships wholesale via its git-subdir `source`** — keep build/test
   tooling at the repo root, never inside `plugins/<name>/`.
2. **Installed plugins run with `${CLAUDE_PLUGIN_ROOT}` set, cwd = user project**
   — reference every executed helper as `${CLAUDE_PLUGIN_ROOT}/<path>`.

See `knowledge/marketplace-conventions.md` for the full anatomy, the four
hygiene invariants, portability rules, and the release/catalog sync.

## What ships

Everything under `plugins/marketplace-builder/` ships to end users. This plugin's
own tests live at the repo root (`tests/`), proving it passes its own sensor.
