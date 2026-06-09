#!/usr/bin/env bats
# scaffold_self_test.bats — prove the scaffolder's shipped sensor template works
# on a scaffolded-shaped marketplace: it passes a hygiene-clean fixture and fails
# closed on a fixture full of violations. (Playbook §7.4.)
#
# Each case assembles a temp marketplace (sensor at tests/repo/, fixture plugins
# at plugins/) and runs the sensor against it as a subprocess.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  SENSOR="$REPO_ROOT/plugins/marketplace-builder/templates/tests/shipped_script_refs_test.bats"
  FIXTURES="$REPO_ROOT/tests/marketplace-builder/fixtures"
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/mb-selftest.XXXXXX")"
}

teardown() {
  [ -n "${WORK:-}" ] && rm -rf "$WORK"
}

# Assemble a temp marketplace from a named fixture and echo its root.
_assemble() {
  # $1 = fixture name (good|bad)
  root="$WORK/$1"
  mkdir -p "$root/tests/repo"
  cp "$SENSOR" "$root/tests/repo/shipped_script_refs_test.bats"
  : > "$root/tests/repo/escape_allowlist.txt"
  cp -R "$FIXTURES/$1/plugins" "$root/plugins"
  printf '%s\n' "$root"
}

@test "sensor template exists and is shipped under the plugin" {
  [ -f "$SENSOR" ]
}

@test "sensor PASSES on a hygiene-clean scaffolded marketplace" {
  root="$(_assemble good)"
  run bats "$root/tests/repo"
  [ "$status" -eq 0 ] || { printf 'expected pass, got status %s:\n%s\n' "$status" "$output" >&2; false; }
}

@test "sensor FAILS CLOSED on a marketplace with hygiene violations" {
  root="$(_assemble bad)"
  run bats "$root/tests/repo"
  [ "$status" -ne 0 ]
  # All four invariants should be exercised by the bad fixture.
  [[ "$output" == *"missing"* ]]
}
