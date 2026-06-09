---
name: audit-plugin
description: Audit a marketplace (or a single plugin) — run the shipping-hygiene sensor, structural checks (every catalog entry has a dir, every dir has a manifest, versions in sync), and the portability sweep. Reports findings and offers fixes. Use to validate a marketplace is healthy.
user-invocable: true
---

# /audit-plugin `[name]`

Audit the whole marketplace, or one plugin if `[name]` is given.

## Before you start

Read `${CLAUDE_PLUGIN_ROOT}/knowledge/marketplace-conventions.md` (§3–§5b) and
`${CLAUDE_PLUGIN_ROOT}/knowledge/agent-authoring.md`.

## Procedure

1. **Hygiene sensor (§3).** Run `bats tests/repo`. This proves the four
   invariants: refs resolve, no plugin-escaping refs, hook commands resolve, no
   shipped test/build tooling. If `tests/repo/shipped_script_refs_test.bats` is
   missing, offer to install it from
   `${CLAUDE_PLUGIN_ROOT}/templates/tests/shipped_script_refs_test.bats`.

2. **Structural checks.** Run `bash scripts/structural-check.sh`:
   - every catalog entry maps to a `plugins/<name>/` with a `plugin.json`
   - every plugin dir is registered in the catalog
   - catalog `version` == manifest `version`, and `source.ref` == `<name>-v<version>`

3. **Portability sweep.** Run `bash scripts/portability-check.sh` (or invoke
   `/portability-check`): `shellcheck -x` + shebang verification over shipped +
   dev scripts.

4. **Agent frontmatter (deterministic).** Run `bash scripts/agent-check.sh`:
   every `agents/*.md` has required `name`/`description`, no plugin-ignored
   `hooks`/`mcpServers`/`permissionMode`, and a least-privilege `tools` allowlist.
   Then review each agent by judgment (§agent-authoring): single responsibility,
   an explicit "does NOT handle" boundary, a clear delegation `description`, and
   a right-sized `model`. Offer `/add-agent` to scaffold missing ones.

5. **Primitive selection (§5b).** Flag any shipped **skill whose entire job is
   running a fixed deterministic command** — it should be a **hook** wired to
   that script, not a model-invoked skill. Recommend the conversion. (This check
   is judgment, not mechanical — that is itself why it lives here, not in the
   deterministic sensor.)

6. **Report.** For each failure, name the file, the invariant it violates, and a
   concrete fix. If `[name]` was given, filter the report to that plugin. Offer
   to apply the fixes; only edit files after the user confirms (or proceed if
   the fix is mechanical and unambiguous, e.g. syncing a drifted version).

Be a sensor, not a narrator: surface findings, propose fixes, then act.
