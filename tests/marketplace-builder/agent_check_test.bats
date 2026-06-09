#!/usr/bin/env bats
# agent_check_test.bats — prove the deterministic agent-frontmatter validator
# passes a well-formed agent and fails closed on a broken one (missing required
# fields / plugin-ignored fields). Mirrors how the script resolves its repo root
# (scripts/..), so each case assembles a temp repo with the script + fixtures.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  SCRIPT="$REPO_ROOT/plugins/marketplace-builder/templates/scripts/agent-check.sh"
  FIXTURES="$REPO_ROOT/tests/marketplace-builder/agent-fixtures"
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/mb-agentcheck.XXXXXX")"
}

teardown() {
  [ -n "${WORK:-}" ] && rm -rf "$WORK"
}

_assemble() {
  # $1 = fixture name (good|bad)
  root="$WORK/$1"
  mkdir -p "$root/scripts"
  cp "$SCRIPT" "$root/scripts/agent-check.sh"
  cp -R "$FIXTURES/$1/plugins" "$root/plugins"
  printf '%s\n' "$root"
}

@test "agent-check PASSES a well-formed agent" {
  root="$(_assemble good)"
  run bash "$root/scripts/agent-check.sh"
  [ "$status" -eq 0 ] || { printf 'expected pass, got %s:\n%s\n' "$status" "$output" >&2; false; }
}

@test "agent-check FAILS on missing 'description'" {
  root="$(_assemble bad)"
  run bash "$root/scripts/agent-check.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"description"* ]]
}

@test "agent-check FAILS on plugin-ignored 'hooks'/'permissionMode'" {
  root="$(_assemble bad)"
  run bash "$root/scripts/agent-check.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"hooks"* ]]
  [[ "$output" == *"permissionMode"* ]]
}
