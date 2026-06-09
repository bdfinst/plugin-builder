#!/usr/bin/env bash
# structural-check.sh — prove catalog <-> plugin-dir <-> manifest consistency.
#   * every catalog entry maps to a plugins/<name>/ with a plugin.json
#   * every plugins/<name>/ is listed in the catalog
#   * catalog version == manifest version; source.ref == <name>-v<version>
# Portable: bash 3.2 / BSD coreutils / Git Bash. Requires jq.
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CATALOG="$REPO_ROOT/.claude-plugin/marketplace.json"
fail=0

err() { printf 'FAIL: %s\n' "$1" >&2; fail=1; }

command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 2; }
[ -f "$CATALOG" ] || { err "missing catalog: $CATALOG"; exit 1; }

# 1. Every catalog entry resolves to a manifest with matching version/ref.
names="$(jq -r '.plugins[].name' "$CATALOG")"
while IFS= read -r name; do
  [ -n "$name" ] || continue
  manifest="$REPO_ROOT/plugins/$name/.claude-plugin/plugin.json"
  if [ ! -f "$manifest" ]; then
    err "catalog lists '$name' but $manifest is missing"
    continue
  fi
  cat_ver="$(jq -r --arg n "$name" '.plugins[] | select(.name==$n) | .version' "$CATALOG")"
  cat_ref="$(jq -r --arg n "$name" '.plugins[] | select(.name==$n) | .source.ref' "$CATALOG")"
  man_ver="$(jq -r '.version' "$manifest")"
  [ "$cat_ver" = "$man_ver" ] || err "$name: catalog version ($cat_ver) != manifest version ($man_ver)"
  [ "$cat_ref" = "$name-v$man_ver" ] || err "$name: source.ref ($cat_ref) != expected $name-v$man_ver"
done <<EOF
$names
EOF

# 2. Every plugin dir is registered in the catalog.
if [ -d "$REPO_ROOT/plugins" ]; then
  for d in "$REPO_ROOT/plugins"/*; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"
    if ! printf '%s\n' "$names" | grep -qxF "$n"; then
      err "plugins/$n exists but is not registered in the catalog"
    fi
    [ -f "$d/.claude-plugin/plugin.json" ] || err "plugins/$n is missing .claude-plugin/plugin.json"
  done
fi

[ "$fail" -eq 0 ] && printf 'structural-check: OK\n'
exit "$fail"
