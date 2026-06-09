# plugin-builder

A Claude Code **plugin marketplace** containing **`marketplace-builder`** — a
meta-plugin that scaffolds, audits, and maintains *plugin-marketplace
monorepos*. It bakes in the two hard-won facts about marketplaces so you can't
get them wrong:

1. **A plugin ships wholesale via its git-subdir `source`.** Every tracked file
   under `plugins/<name>/` reaches end users — build/test tooling left there
   ships by accident.
2. **Installed plugins run with `${CLAUDE_PLUGIN_ROOT}` set, but cwd is the
   user's project.** A skill that runs a bare `scripts/x.sh` breaks once
   installed; reference helpers as `${CLAUDE_PLUGIN_ROOT}/<path>`.

## Install

Add this marketplace and install the plugin in Claude Code:

```
/plugin marketplace add bdfinst/plugin-builder
/plugin install marketplace-builder@bdfinst
```

Then check prerequisites: `bash plugins/marketplace-builder/install.sh`.

## Commands

| Command | Role | What it does |
|---|---|---|
| `/new-marketplace <owner>` | scaffold | Create the catalog, repo-root `tests/ scripts/ docs/` trees, CI, `release-please-config.json`, `dev-setup.sh`, the hygiene sensor, and a root `CLAUDE.md`. |
| `/add-plugin <name>` | scaffold | Create `plugins/<name>/` (shipped skeleton, `plugin.json`, `install.sh` with the Git-Bash guard, `settings.json`, `CLAUDE.md`); register it in the catalog and release config with the catalog `extra-files` sync. |
| `/audit-plugin [name]` | audit | Run the hygiene sensor + structural checks + portability sweep; report and offer fixes. |
| `/portability-check` | audit | `shellcheck -x` shipped + dev scripts; flag bash-4/GNU-only constructs; verify shebangs; check the Git-Bash `install.sh` guard. |
| `/release-setup` | scaffold | Wire `release-please` per-plugin packages + the `marketplace.json` `extra-files` jsonpath sync. |
| `/cloud-setup` | scaffold | Generate the gated `SessionStart` install hook + `cloud-setup.sh` + a skill-file fallback. |

## What the plugin enforces

A marketplace produced (or audited-clean) by `marketplace-builder` passes the
four hygiene invariants proved by a portable `bats` sensor:

1. Every `${CLAUDE_PLUGIN_ROOT}/<file>` reference resolves inside its plugin.
2. No shipped file escapes its plugin via `${CLAUDE_PLUGIN_ROOT}/../..` (minus an
   explicit allowlist).
3. Every `settings.json` hook command resolves to a shipped file.
4. No build/test tooling ships inside a plugin.

…plus portability across macOS bash 3.2 / BSD coreutils / Windows Git Bash,
model-free CI gates, and automated `release-please` versioning with catalog sync.

See [`plugins/marketplace-builder/knowledge/marketplace-conventions.md`](plugins/marketplace-builder/knowledge/marketplace-conventions.md)
for the full source of truth.

## Repository layout

```
.claude-plugin/marketplace.json          # the catalog
plugins/marketplace-builder/             # the shipped plugin
├── .claude-plugin/plugin.json           # manifest
├── skills/                              # the six /commands
├── knowledge/marketplace-conventions.md # source of truth
├── templates/                           # scaffolding payloads (sensor, CI, configs…)
├── install.sh  CLAUDE.md
tests/repo/                              # the hygiene sensor (this repo's own gate)
tests/marketplace-builder/               # scaffolder self-test + fixtures
scripts/                                 # structural / portability / dev-setup / ci-local
.github/workflows/                       # CI + release-please
release-please-config.json               # automated versioning + catalog sync
```

## Development

```bash
bash scripts/dev-setup.sh   # installs jq, shellcheck, bats
bash scripts/ci-local.sh    # runs every gate locally (mirrors CI)
```

Commit with [Conventional Commits](https://www.conventionalcommits.org/);
`release-please` handles versions, tags, and catalog sync automatically.

## License

MIT
