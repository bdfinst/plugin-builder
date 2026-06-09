#!/usr/bin/env bats
# shipped_script_refs_test.bats — the marketplace hygiene sensor.
#
# Auto-discovers every plugins/<name>/ and proves the four shipping-hygiene
# invariants (see knowledge/marketplace-conventions.md §3):
#
#   1. Every ${CLAUDE_PLUGIN_ROOT}/<file> reference resolves inside its plugin.
#   2. No shipped file escapes its plugin via ${CLAUDE_PLUGIN_ROOT}/../..
#      (minus an explicit maintainer allowlist).
#   3. Every settings.json hook command resolves to a shipped file.
#   4. No build/test tooling ships inside a plugin.
#
# Portable: bash 3.2 / BSD coreutils / Git Bash. No mapfile, no declare -A,
# no GNU-only flags. Run from the repo root: `bats tests/repo`.

setup() {
  # Repo root = two levels up from this test file (tests/repo/<this>).
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  PLUGINS_DIR="$REPO_ROOT/plugins"
  ALLOWLIST="$REPO_ROOT/tests/repo/escape_allowlist.txt"
}

# Print every plugin directory (one per line). Empty if none.
_plugin_dirs() {
  [ -d "$PLUGINS_DIR" ] || return 0
  for d in "$PLUGINS_DIR"/*; do
    [ -d "$d" ] || continue
    printf '%s\n' "$d"
  done
}

# Files we scan for ${CLAUDE_PLUGIN_ROOT} references. Skip binary/lock noise and
# the plugin's own templates/ subtree — template contents are scaffolding payload
# destined for OTHER repos (and are validated there / by the scaffolder's
# self-test), not live code in this plugin.
_scan_files() {
  # $1 = plugin dir
  find "$1" -type f \
    ! -path '*/templates/*' \
    ! -name '*.png' ! -name '*.jpg' ! -name '*.jpeg' ! -name '*.gif' \
    ! -name '*.ico' ! -name '*.lock' 2>/dev/null
}

# Extract literal paths referenced after ${CLAUDE_PLUGIN_ROOT}/ in a file.
# Skips dynamic refs (containing $, *, ?, or runtime substitution).
_refs_in_file() {
  # $1 = file
  grep -oE '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9._/-]+' "$1" 2>/dev/null \
    | sed 's#^\${CLAUDE_PLUGIN_ROOT}/##'
}

# Extract escaping refs: ${CLAUDE_PLUGIN_ROOT}/../...
_escapes_in_file() {
  # $1 = file
  grep -oE '\$\{CLAUDE_PLUGIN_ROOT\}/\.\./[A-Za-z0-9._/-]*' "$1" 2>/dev/null
}

@test "invariant 1: every \${CLAUDE_PLUGIN_ROOT}/<file> ref resolves inside its plugin" {
  failures=""
  while IFS= read -r plugin; do
    [ -n "$plugin" ] || continue
    while IFS= read -r file; do
      [ -n "$file" ] || continue
      while IFS= read -r ref; do
        [ -n "$ref" ] || continue
        # Skip escapes (covered by invariant 2).
        case "$ref" in
          ../*) continue ;;
        esac
        if [ ! -e "$plugin/$ref" ]; then
          failures="$failures
  $file -> \${CLAUDE_PLUGIN_ROOT}/$ref (missing)"
        fi
      done <<EOF
$(_refs_in_file "$file")
EOF
    done <<EOF
$(_scan_files "$plugin")
EOF
  done <<EOF
$(_plugin_dirs)
EOF

  if [ -n "$failures" ]; then
    printf 'Unresolved \${CLAUDE_PLUGIN_ROOT} references:%s\n' "$failures" >&2
    return 1
  fi
}

@test "invariant 2: no shipped file escapes its plugin via \${CLAUDE_PLUGIN_ROOT}/../.." {
  failures=""
  while IFS= read -r plugin; do
    [ -n "$plugin" ] || continue
    while IFS= read -r file; do
      [ -n "$file" ] || continue
      rel="${file#"$REPO_ROOT"/}"
      while IFS= read -r esc; do
        [ -n "$esc" ] || continue
        # Allow if the file is on the maintainer allowlist.
        if [ -f "$ALLOWLIST" ] && grep -qxF "$rel" "$ALLOWLIST"; then
          continue
        fi
        failures="$failures
  $rel -> $esc"
      done <<EOF
$(_escapes_in_file "$file")
EOF
    done <<EOF
$(_scan_files "$plugin")
EOF
  done <<EOF
$(_plugin_dirs)
EOF

  if [ -n "$failures" ]; then
    printf 'Plugin-escaping references (add to tests/repo/escape_allowlist.txt if intentional):%s\n' "$failures" >&2
    return 1
  fi
}

@test "invariant 3: every settings.json hook command resolves to a shipped file" {
  failures=""
  while IFS= read -r plugin; do
    [ -n "$plugin" ] || continue
    settings="$plugin/settings.json"
    [ -f "$settings" ] || continue
    # Hook commands run from the plugin root. Pull out referenced .sh paths,
    # whether bare (bash hooks/x.sh) or ${CLAUDE_PLUGIN_ROOT}/hooks/x.sh.
    while IFS= read -r path; do
      [ -n "$path" ] || continue
      norm="${path#\${CLAUDE_PLUGIN_ROOT}/}"
      case "$norm" in
        /*) target="$norm" ;;
        *)  target="$plugin/$norm" ;;
      esac
      if [ ! -e "$target" ]; then
        failures="$failures
  $settings -> $path (missing)"
      fi
    done <<EOF
$(grep -oE '(\$\{CLAUDE_PLUGIN_ROOT\}/)?[A-Za-z0-9._/-]+\.(sh|py|js|mjs)' "$settings" 2>/dev/null)
EOF
  done <<EOF
$(_plugin_dirs)
EOF

  if [ -n "$failures" ]; then
    printf 'Unresolved settings.json hook commands:%s\n' "$failures" >&2
    return 1
  fi
}

@test "invariant 4: no build/test tooling ships inside a plugin" {
  failures=""
  while IFS= read -r plugin; do
    [ -n "$plugin" ] || continue
    while IFS= read -r bad; do
      [ -n "$bad" ] || continue
      failures="$failures
  $bad"
    done <<EOF
$(find "$plugin" -not -path '*/templates/*' \( -name '*.test.sh' -o -name '*.bats' -o -name 'run-all*.sh' -o -type d -name tests \) 2>/dev/null)
EOF
  done <<EOF
$(_plugin_dirs)
EOF

  if [ -n "$failures" ]; then
    printf 'Build/test tooling found inside plugin (move to repo-root tests/ or scripts/):%s\n' "$failures" >&2
    return 1
  fi
}
