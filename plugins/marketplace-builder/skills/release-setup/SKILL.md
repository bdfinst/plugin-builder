---
name: release-setup
description: Wire release-please with one package per plugin and the marketplace.json extra-files jsonpath sync, so plugin.json, the release tag, and the catalog entry can never drift. Use to set up or repair automated versioning + catalog sync.
user-invocable: true
---

# /release-setup

Wire (or repair) `release-please` so every plugin releases independently and the
catalog stays in lock-step automatically.

## Before you start

Read `${CLAUDE_PLUGIN_ROOT}/knowledge/marketplace-conventions.md` (§6).

## Procedure

1. **Per-plugin package block.** For every `plugins/<name>/` with a manifest,
   ensure `release-please-config.json` `.packages["plugins/<name>"]` matches the
   template at
   `${CLAUDE_PLUGIN_ROOT}/templates/release/release-please-config.json`
   (with `__NAME__` replaced). The `extra-files` must rewrite both the catalog
   `version` and `source.ref`:
   ```jsonc
   "extra-files": [
     ".claude-plugin/plugin.json",
     { "type": "json", "path": "/.claude-plugin/marketplace.json",
       "jsonpath": "$.plugins[?(@.name=='<name>')].version" },
     { "type": "json", "path": "/.claude-plugin/marketplace.json",
       "jsonpath": "$.plugins[?(@.name=='<name>')].source.ref" }
   ]
   ```

2. **Manifest.** Ensure `.release-please-manifest.json` has
   `"plugins/<name>": "<current manifest version>"` for each plugin.

3. **Workflow.** Confirm `.github/workflows/` has a release-please workflow
   (add one calling `googleapis/release-please-action` if missing). Document
   that `feat:` → minor, `fix:` → patch, `feat!:`/`BREAKING CHANGE` → major.

4. **Verify + report.** Validate the JSON (`jq . release-please-config.json`),
   run `bash scripts/structural-check.sh`, and report. Never hand-edit catalog
   versions/refs after this — the release flow owns them.
