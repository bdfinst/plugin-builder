#!/usr/bin/env bash
# dev-setup.sh — validate and install the marketplace dev toolchain.
# Portable across macOS (brew), Debian/Ubuntu (apt), and Git Bash (manual).
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

have() { command -v "$1" >/dev/null 2>&1; }

pkg_install() {
  # $1 = tool name (also the package name in the common case)
  if have brew; then
    brew install "$1"
  elif have apt-get; then
    sudo apt-get update && sudo apt-get install -y "$1"
  else
    printf 'Please install "%s" manually (no brew/apt detected).\n' "$1" >&2
    return 1
  fi
}

ensure() {
  if have "$1"; then
    printf '  ok   %s\n' "$1"
  else
    printf '  ...  installing %s\n' "$1"
    pkg_install "${2:-$1}"
  fi
}

printf 'Provisioning dev toolchain...\n'
ensure jq
ensure shellcheck
ensure bats bats

# Python dev requirements, if present.
if [ -f "$REPO_ROOT/requirements-dev.txt" ]; then
  if have python3; then
    printf '  ...  pip install -r requirements-dev.txt\n'
    python3 -m pip install -r "$REPO_ROOT/requirements-dev.txt"
  else
    printf '  warn python3 not found; skipping requirements-dev.txt\n' >&2
  fi
fi

printf 'Dev toolchain ready.\n'
