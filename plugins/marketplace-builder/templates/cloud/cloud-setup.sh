#!/usr/bin/env bash
# cloud-setup.sh — gated SessionStart install hook for cloud/web sessions.
# Installs the plugin's prerequisites once per session. Safe to run repeatedly.
# Gate: only acts when CLAUDE_CODE_REMOTE (or similar) indicates a cloud session;
# otherwise it is a no-op so local users keep their own setup.
set -eu

# --- Gate -------------------------------------------------------------------
# Skip in non-cloud sessions unless explicitly forced.
if [ "${MARKETPLACE_BUILDER_FORCE_SETUP:-}" != "1" ]; then
  case "${CLAUDE_CODE_REMOTE:-}${CLAUDE_CODE_WEB:-}${CI:-}" in
    "") exit 0 ;;  # not a cloud/CI session — defer to local dev-setup
  esac
fi

# Run once per session.
stamp="${TMPDIR:-/tmp}/.__NAME__-cloud-setup.done"
[ -f "$stamp" ] && exit 0

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [ -x "$REPO_ROOT/scripts/dev-setup.sh" ]; then
  bash "$REPO_ROOT/scripts/dev-setup.sh" || true
fi

: > "$stamp"
exit 0
