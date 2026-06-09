# plugin-builder — repo conventions

This repository is a Claude Code **plugin marketplace** whose single plugin,
`marketplace-builder`, is a meta-plugin for scaffolding and auditing *other*
marketplaces. It is built to pass its own sensor.

- Repo URL: `https://github.com/bdfinst/plugin-builder.git`
- Catalog: `.claude-plugin/marketplace.json`
- The plugin: `plugins/marketplace-builder/`

## The one rule that governs everything

**Files under `plugins/<name>/` ship wholesale to end users; everything at the
repo root does not.** So:

| Ships (`plugins/<name>/`) | Never ships (repo root) |
|---|---|
| `skills/ knowledge/ templates/`, `install.sh`, `CLAUDE.md`, `settings.json` | `tests/`, `scripts/`, `docs/`, `.github/`, `.claude/` |

Reference every helper a plugin executes at runtime as
`${CLAUDE_PLUGIN_ROOT}/<path>` — once installed, the agent's cwd is the user's
project, not the plugin root. A plugin's own `templates/` subtree is scaffolding
*payload* (it is materialized into other repos) and is exempt from the sensor.

## Gates

Run the full local gate before pushing (mirrors CI):

```bash
bash scripts/dev-setup.sh   # one-time: installs jq, shellcheck, bats
bash scripts/ci-local.sh    # structural + portability + bats sensor + self-test
```

- `scripts/structural-check.sh` — catalog ⇆ plugin-dir ⇆ manifest consistency; versions/refs in sync.
- `scripts/portability-check.sh` — `shellcheck -x` + `env bash` shebang sweep.
- `bats tests/repo` — the four hygiene invariants (the sensor).
- `bats tests/marketplace-builder` — the scaffolder self-test.

## Versioning — automated, never hand-edited

`release-please` owns `plugin.json` versions, release tags, and the catalog
`version`/`source.ref` (via `extra-files` in `release-please-config.json`). Use
conventional commits: `feat:` → minor, `fix:` → patch, `feat!:` / `BREAKING
CHANGE` → major. Do not hand-edit catalog versions or refs.

## Cloud sessions

`.claude/settings.json` runs a gated `SessionStart` hook
(`.claude/cloud-setup.sh`) that provisions the toolchain in web/cloud sessions
only. If it doesn't run, invoke the plugin's skills directly and run
`bash scripts/dev-setup.sh` by hand.
