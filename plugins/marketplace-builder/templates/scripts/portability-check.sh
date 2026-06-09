#!/usr/bin/env bash
# portability-check.sh — shellcheck sweep + shebang verification over every
# shipped and dev shell script. Flags the common bash-4 / GNU-only footguns.
# Portable: bash 3.2 / BSD coreutils / Git Bash.
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

err() { printf 'FAIL: %s\n' "$1" >&2; fail=1; }

# Collect all *.sh under the repo, skipping VCS and node_modules.
scripts="$(find "$REPO_ROOT" -type f -name '*.sh' \
  -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null)"

while IFS= read -r f; do
  [ -n "$f" ] || continue
  # Shebang must be env bash.
  first="$(head -n1 "$f")"
  case "$first" in
    '#!/usr/bin/env bash') : ;;
    *) err "${f#"$REPO_ROOT"/}: shebang is not '#!/usr/bin/env bash' (got: $first)" ;;
  esac
done <<EOF
$scripts
EOF

# Lint each script with shellcheck -x at warning severity, if available.
if command -v shellcheck >/dev/null 2>&1; then
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if ! shellcheck -x -S warning "$f"; then
      err "${f#"$REPO_ROOT"/}: shellcheck reported issues"
    fi
  done <<EOF
$scripts
EOF
else
  printf 'warn: shellcheck not installed; skipping lint (shebang checks still ran)\n' >&2
fi

[ "$fail" -eq 0 ] && printf 'portability-check: OK\n'
exit "$fail"
