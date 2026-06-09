#!/usr/bin/env bash
# agent-check.sh — deterministic validator for shipped agent files.
# A real tool, not a model-driven skill (see knowledge/marketplace-conventions.md
# §5b): frontmatter validation is deterministic, so it is wired as a script/gate.
#
# For every plugins/*/agents/**/*.md (excluding templates/):
#   * must start with YAML frontmatter (--- ... ---)
#   * require: name, description
#   * forbid: hooks, mcpServers, permissionMode (ignored in plugin agents)
#   * warn (non-fatal): no tools allowlist => not least-privilege
#
# Portable: bash 3.2 / BSD coreutils / Git Bash.
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

err()  { printf 'FAIL: %s\n' "$1" >&2; fail=1; }
warn() { printf 'warn: %s\n' "$1" >&2; }

[ -d "$REPO_ROOT/plugins" ] || { printf 'agent-check: no plugins/ dir; OK\n'; exit 0; }

agents="$(find "$REPO_ROOT/plugins" -type f -name '*.md' \
  -path '*/agents/*' ! -path '*/templates/*' 2>/dev/null)"

count=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  count=$((count + 1))
  rel="${f#"$REPO_ROOT"/}"

  # Must open with a frontmatter fence.
  if [ "$(head -n1 "$f")" != "---" ]; then
    err "$rel: no YAML frontmatter (file must start with '---')"
    continue
  fi

  # Frontmatter = lines after the first '---' up to the next '---'.
  fm="$(awk 'NR==1{next} /^---[[:space:]]*$/{exit} {print}' "$f")"

  printf '%s\n' "$fm" | grep -qE '^name:[[:space:]]*[^[:space:]]' \
    || err "$rel: frontmatter missing required 'name'"
  printf '%s\n' "$fm" | grep -qE '^description:[[:space:]]*[^[:space:]]' \
    || err "$rel: frontmatter missing required 'description'"

  for forbidden in hooks mcpServers permissionMode; do
    if printf '%s\n' "$fm" | grep -qE "^${forbidden}:"; then
      err "$rel: '$forbidden' is ignored in plugin agents — remove it (copy the agent to .claude/agents/ if you need it)"
    fi
  done

  if ! printf '%s\n' "$fm" | grep -qE '^tools:'; then
    warn "$rel: no 'tools' allowlist — agent inherits all tools (not least-privilege)"
  fi
done <<EOF
$agents
EOF

if [ "$fail" -eq 0 ]; then
  printf 'agent-check: OK (%s agent file(s))\n' "$count"
fi
exit "$fail"
