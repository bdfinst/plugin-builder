#!/usr/bin/env bash
# ci-local.sh — local pre-push gate mirroring CI: structural + portability +
# bats sensor + self-test. Run from anywhere; resolves the repo root itself.
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

fail=0
run() {
  printf '\n=== %s ===\n' "$1"
  shift
  if "$@"; then :; else fail=1; fi
}

run "structural"   bash scripts/structural-check.sh
run "portability"  bash scripts/portability-check.sh

if command -v bats >/dev/null 2>&1; then
  run "hygiene sensor + self-test" bats tests/repo tests/marketplace-builder
else
  printf '\nwarn: bats not installed; skipping sensor (run scripts/dev-setup.sh)\n' >&2
fi

if [ "$fail" -ne 0 ]; then
  printf '\nci-local: FAILED\n' >&2
  exit 1
fi
printf '\nci-local: OK\n'
