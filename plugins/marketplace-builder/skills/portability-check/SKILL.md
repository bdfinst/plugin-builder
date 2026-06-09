---
name: portability-check
description: Run shellcheck -x over every shipped and dev shell script, flag bash-4/GNU-only constructs, verify env-bash shebangs, and check that each install.sh has the Git-Bash-on-Windows guard. Use to validate cross-platform portability (macOS bash 3.2 / BSD / Windows Git Bash).
user-invocable: true
---

# /portability-check

Sweep the marketplace for portability hazards across the three targets: macOS
(bash 3.2 / BSD coreutils), Linux, and Windows Git Bash.

## Before you start

Read `${CLAUDE_PLUGIN_ROOT}/knowledge/marketplace-conventions.md` (§4).

## Procedure

1. **Run the sweep.** `bash scripts/portability-check.sh` — verifies every
   `*.sh` has a `#!/usr/bin/env bash` shebang and runs `shellcheck -x -S warning`.

2. **bash 3.2 hazards.** Beyond shellcheck, grep shipped + dev scripts for
   constructs that break on macOS's bash 3.2 and report each hit:
   `mapfile`, `readarray`, `declare -A`, `${var,,}` / `${var^^}`, `wait -n`,
   and bare `"${arr[@]}"` under `set -u` (use `${arr[@]+"${arr[@]}"}`).

3. **BSD-vs-GNU hazards.** Grep for `readlink -f`, `sed -i` (without backup
   arg), `date +%N`, `stat -c`, `find -printf`, `timeout`, `base64 -w`; flag
   each as needing a guard or fallback.

4. **install.sh guards.** For each `plugins/*/install.sh`, confirm it detects
   Windows-without-Git-Bash (a `uname -s` case matching `MINGW*/MSYS*/CYGWIN*`
   vs native Windows) and tells the user to install Git Bash.

5. **Report.** List every hit with file:line and the portable replacement. Offer
   to apply fixes.
