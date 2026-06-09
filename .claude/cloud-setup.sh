#!/usr/bin/env bash
# cloud-setup.sh — gated SessionStart install hook for cloud/web sessions.
# Installs the dev toolchain once per session. Self-gates so local sessions are
# unaffected. Safe to run repeatedly.
set -eu

# --- Gate: only act in cloud/CI sessions unless explicitly forced -----------
if [ "${MARKETPLACE_BUILDER_FORCE_SETUP:-}" != "1" ]; then
  case "${CLAUDE_CODE_REMOTE:-}${CLAUDE_CODE_WEB:-}${CI:-}" in
    "") exit 0 ;;
  esac
fi

stamp="${TMPDIR:-/tmp}/.marketplace-builder-cloud-setup.done"
[ -f "$stamp" ] && exit 0

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [ -x "$REPO_ROOT/scripts/dev-setup.sh" ]; then
  bash "$REPO_ROOT/scripts/dev-setup.sh" || true
fi

: > "$stamp"
exit 0
