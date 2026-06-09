#!/usr/bin/env bash
# install.sh — prerequisite checker for the __NAME__ plugin.
# Runs on macOS (bash 3.2 / BSD coreutils), Linux, and Windows Git Bash.
set -eu

fail=0

note() { printf '  %s\n' "$1"; }
err()  { printf 'ERROR: %s\n' "$1" >&2; fail=1; }

# --- Windows-without-Git-Bash guard -----------------------------------------
# On Windows the only supported shell is Git Bash. Native cmd.exe / PowerShell
# are not targets. Detect Windows and confirm we are inside an MSYS/Cygwin bash.
case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*)
    : # Good — we are in Git Bash.
    ;;
  Windows_NT|*Windows*)
    err "On Windows this plugin requires Git Bash. Install Git for Windows (https://git-scm.com/download/win) and re-run from the Git Bash shell."
    ;;
  *)
    : # macOS / Linux — fine.
    ;;
esac

# --- Prerequisite tools ------------------------------------------------------
need() {
  if command -v "$1" >/dev/null 2>&1; then
    note "found $1"
  else
    err "missing required tool: $1${2:+ ($2)}"
  fi
}

need bash
need git
need jq "install with: brew install jq | apt-get install jq"

if [ "$fail" -ne 0 ]; then
  printf '\n__NAME__: prerequisite check FAILED. Resolve the items above.\n' >&2
  exit 1
fi

printf '\n__NAME__: prerequisites satisfied.\n'
