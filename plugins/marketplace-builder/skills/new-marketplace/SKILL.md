---
name: new-marketplace
description: Scaffold a new Claude Code plugin-marketplace monorepo — catalog, repo-root tests/scripts/docs trees, CI workflows, release-please config, dev-setup, the hygiene sensor, and a root CLAUDE.md. Use when starting a fresh marketplace repository.
user-invocable: true
---

# /new-marketplace `<owner-handle>` [owner-name]

Scaffold a healthy marketplace monorepo from scratch.

## Before you start

Read `${CLAUDE_PLUGIN_ROOT}/knowledge/marketplace-conventions.md` — it is the
source of truth for the anatomy and invariants below. Confirm the target
directory is empty or is a fresh git repo.

## Inputs

- `<owner-handle>` — the catalog `name` (e.g. a GitHub org/handle). **Required.**
- `[owner-name]` — human-readable owner name. Defaults to the handle.
- Ask for the repo `url` (e.g. `https://github.com/<org>/<repo>.git`) — needed
  so `/add-plugin` can fill catalog `source.url`. Store it in the root CLAUDE.md.

## Procedure

1. **Catalog.** Copy `${CLAUDE_PLUGIN_ROOT}/templates/marketplace/marketplace.json`
   to `.claude-plugin/marketplace.json`; replace `__OWNER_HANDLE__` and
   `__OWNER_NAME__`. Leave `plugins: []` — `/add-plugin` populates it.

2. **Repo-root trees (NEVER shipped).** Create `tests/repo/`, `scripts/`,
   `docs/`, `evals/`, `plans/`. These live at the repo root, never inside a
   plugin dir.

3. **Hygiene sensor.** Copy
   `${CLAUDE_PLUGIN_ROOT}/templates/tests/shipped_script_refs_test.bats`
   to `tests/repo/shipped_script_refs_test.bats`. Create an empty
   `tests/repo/escape_allowlist.txt` (one repo-relative path per intentional
   escape; empty for now).

4. **Dev scripts.** Copy from `${CLAUDE_PLUGIN_ROOT}/templates/scripts/`:
   `structural-check.sh`, `portability-check.sh`, `agent-check.sh`,
   `dev-setup.sh` into `scripts/`. `chmod +x` them. Also write
   `scripts/ci-local.sh` that runs all of these gates plus `bats tests/repo`
   (the local pre-push mirror of CI).

5. **CI.** Copy `${CLAUDE_PLUGIN_ROOT}/templates/ci/plugin-tests.yml` to
   `.github/workflows/plugin-tests.yml`.

6. **Release scaffolding.** Write `release-please-config.json` with an empty
   `packages: {}` and `.release-please-manifest.json` as `{}`. `/add-plugin`
   and `/release-setup` populate them per plugin.

7. **requirements-dev.txt.** Create it (empty or with any Python dev deps).

8. **Root CLAUDE.md.** Document: the shipped-vs-not-shipped rule, the repo URL,
   how to run the gates (`bash scripts/ci-local.sh`), and that versions/refs are
   automated via release-please — never hand-edited.

9. **Report.** List what you created and run `bash scripts/ci-local.sh` (it
   should pass on the empty marketplace). Tell the user to run `/add-plugin
   <name>` next.

Emit files and run the gate. Do not narrate beyond the final report.
