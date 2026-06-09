# Marketplace conventions (source of truth)

This file encodes the conventions every skill in `marketplace-builder` enforces.
Skills load it on demand (progressive disclosure). When a skill scaffolds or
audits, it MUST conform to what is written here. If reality and this file
disagree, this file wins — update it deliberately, in one place.

---

## 1. The two load-bearing facts

1. **A plugin ships wholesale via its git-subdir `source`.** Every tracked file
   under `plugins/<name>/` reaches end users. Build/test tooling left inside that
   tree ships by accident.
2. **Installed plugins run with `${CLAUDE_PLUGIN_ROOT}` set, but the agent's cwd
   is the user's project, not the plugin root.** A skill that runs a bare
   `scripts/x.sh` cannot find it once installed. Every executed helper must be
   referenced as `${CLAUDE_PLUGIN_ROOT}/<path>`.

Everything below exists to make those two facts impossible to get wrong.

---

## 2. Marketplace anatomy

```
.claude-plugin/marketplace.json     # the catalog (lists every plugin + its git-subdir source)
plugins/<name>/                     # one shipped plugin per dir
├── .claude-plugin/plugin.json      # manifest: name, version, description, depends-on
├── agents/  skills/  commands/     # behavioral surface (loaded on demand)
├── hooks/   settings.json          # PreToolUse/PostToolUse/SessionStart wiring
├── knowledge/ templates/ prompts/  # reference data + scaffolds
├── install.sh                      # prerequisite checker (ships)
└── CLAUDE.md                       # plugin instructions (ships)
tests/        scripts/              # gates + dev tooling — repo root, NEVER shipped
evals/  docs/  plans/               # corpus, dev docs, design — repo root, NEVER shipped
.github/workflows/                  # CI: structural + portability + tests
release-please-config.json          # automated versioning + catalog sync
requirements-dev.txt  scripts/dev-setup.sh
```

### 2.1 The catalog — `.claude-plugin/marketplace.json`

```json
{
  "name": "<owner-handle>",
  "owner": { "name": "..." },
  "plugins": [
    {
      "name": "dev-team",
      "version": "6.7.0",
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/<org>/<repo>.git",
        "path": "plugins/dev-team",
        "ref": "dev-team-v6.7.0"
      }
    }
  ]
}
```

Key invariant: each catalog entry's `version` and `source.ref` must stay in
lock-step with the plugin's own `plugin.json` version and its release tag.
Do **not** hand-edit these — automate them (§6).

### 2.2 The manifest — `plugins/<name>/.claude-plugin/plugin.json`

`name`, `version`, `description`, optional `depends-on` (companion plugins) and a
contract version when plugins share a primitives contract.

### 2.3 Shipped vs not-shipped (the load-bearing distinction)

| Ships (under `plugins/<name>/`) | Never ships (repo root) |
|---|---|
| `agents/ skills/ commands/ hooks/ knowledge/ templates/ prompts/` | `tests/` (all bats + `*.test.sh` + fixtures) |
| `settings.json install.sh CLAUDE.md` | `scripts/` (CI/eval/build tooling) |
| `harness/` (executable app code, if any) | `evals/ docs/ plans/ reports/` |

A plugin must **refuse** to leave a test/build script inside a plugin dir, and
must reference every runtime helper as `${CLAUDE_PLUGIN_ROOT}/<path>`.

---

## 3. The four hygiene invariants (the sensor)

The backbone is a `bats` sensor (`tests/repo/shipped_script_refs_test.bats`) that
auto-discovers `plugins/*` and proves four invariants:

1. **Every `${CLAUDE_PLUGIN_ROOT}/<file>` reference resolves** inside the same
   plugin (discoverability once installed).
2. **No shipped file escapes its plugin** via `${CLAUDE_PLUGIN_ROOT}/../..`
   (resolves in the dev monorepo, breaks once installed) — minus an explicit
   maintainer allowlist.
3. **Every `settings.json` hook command resolves** to a shipped file. Hooks run
   from the plugin root, so the bare `bash hooks/x.sh` form is correct there.
4. **No build/test tooling ships inside a plugin** (`*.test.sh`, `*.bats`,
   `run-all*.sh`, a `tests/` dir, …).

`/new-marketplace` drops the sensor into the repo-root test tree and wires it into
CI; `/audit-plugin` runs it.

---

## 4. Portability — macOS bash 3.2 / BSD coreutils / Windows Git Bash

> **Rule: every script created for a plugin MUST be cross-platform.** No script
> may assume a single OS. A bash script **must run on macOS, Linux, and Windows
> Git Bash**; a script in any other language (Python, Node, …) must likewise run
> on all three. There is no "Linux-only" or "macOS-only" script in a plugin or in
> the repo-root tooling — `/portability-check` and CI enforce this, and
> `/add-plugin`/`/audit-plugin` refuse scripts that violate it.

All shell is `#!/usr/bin/env bash` and must run on all three targets:

- **bash 3.2-safe:** no `mapfile`/`readarray`, `declare -A`, `${var,,}`,
  `wait -n`; expand possibly-empty arrays with `${arr[@]+"${arr[@]}"}` (bare
  `"${arr[@]}"` under `set -u` aborts on 3.2 — and CI on bash 5 won't catch it).
- **BSD-vs-GNU:** guard or avoid `readlink -f`, `sed -i`, `date +%N`, `stat -c`,
  `find -printf`, `timeout`, `base64 -w` — provide fallbacks.
- **Windows = Git Bash:** each `install.sh` detects Windows-without-Git-Bash and
  tells the user to install it (native cmd/PowerShell are not targets).
- **Python invoked as a module:** make it cwd-independent and spawn
  cross-platform (`subprocess`, not `os.exec*`).

---

## 5. Invariants baked into every generated/audited plugin

- **Shipping hygiene.** Runtime files only under `plugins/<name>/`; tests/build
  at repo root. Reference every executed helper as `${CLAUDE_PLUGIN_ROOT}/<path>`.
  Scripts the plugin runs at runtime **must** ship *and* be discoverable.
- **Portability (mandatory, all scripts).** Every script a plugin or its repo
  ships/runs must be cross-platform — bash must run on macOS, Linux, and Windows
  Git Bash; other languages must run on all three too. See §4.
- **Tested.** Ship a bats sensor (§3) + targeted unit/smoke tests; wire them into
  CI as model-free gates; mirror them in a local pre-push gate; keep gates
  parallel and fast. A runnable component gets a lightweight smoke test + CI job.
- **Versioned + released.** Conventional commits → `release-please` → tag +
  catalog sync (§6). Version bumps are mechanical lookups, never guesses.
- **Onboarding.** A `scripts/dev-setup.sh` that validates/installs the toolchain
  (brew/apt + `requirements-dev.txt`), and an `install.sh` prerequisite checker
  per plugin.
- **Cloud-aware.** A gated `SessionStart` install hook + a skill-file fallback so
  the plugin is usable in web sessions.

---

## 5b. Primitive selection — prefer deterministic hooks over skills

A plugin's behavior can be delivered as a **hook**, a **skill**, or an **agent**.
They are not interchangeable; choosing the wrong one trades reliability for
needless model invocation. The governing rule when authoring **or auditing**:

> **If a task can be done deterministically by a real tool/script, wire it as a
> hook (or call the tool directly) — do not default to a skill.** Reserve skills
> and agents for work that genuinely needs model judgment or generation.

A skill that merely shells out to a fixed command on every run is a hook wearing
a costume: it spends tokens and adds nondeterminism to something that should
just *execute*. Convert it.

| Use this | When the task is… | Why |
|---|---|---|
| **Hook** (`PreToolUse`/`PostToolUse`/`SessionStart`, wired to a script/tool) | deterministic, non-negotiable, must run every time (lint, validate, block, format, install) | runs in the harness, not the model; reliable + free of tokens |
| **Skill** (`SKILL.md`) | a reusable procedure or reference that needs reasoning/adaptation, or a user-invoked workflow | loaded on demand; model applies judgment |
| **Agent** (`agents/<name>.md`) | complex, high-context, multi-step reasoning best kept out of the main context | isolated context, focused role, returns a summary (see `agent-authoring.md`) |

Decision order: **deterministic tool/hook → skill → agent.** Start at the top and
only move down when the task truly needs it.

This is why this plugin's own validation (the bats sensor, `structural-check.sh`,
`agent-check.sh`) is implemented as deterministic scripts run by hooks/CI — not as
skills. `/audit-plugin` flags any shipped skill whose entire job is running a
fixed deterministic command and recommends converting it to a hook.

---

## 6. Release + catalog sync (automate, never hand-edit)

`release-please` with one `package` per plugin and `extra-files` that rewrite the
catalog entry on every release — so `plugin.json`, the tag, and `marketplace.json`
can never drift:

```jsonc
"plugins/<name>": {
  "release-type": "simple",
  "package-name": "<name>",
  "component": "<name>",
  "extra-files": [
    ".claude-plugin/plugin.json",
    { "type": "json", "path": "/.claude-plugin/marketplace.json",
      "jsonpath": "$.plugins[?(@.name=='<name>')].version" },
    { "type": "json", "path": "/.claude-plugin/marketplace.json",
      "jsonpath": "$.plugins[?(@.name=='<name>')].source.ref" }
  ]
}
```

`feat:` → minor, `fix:` → patch, `feat!:`/`BREAKING CHANGE` → major. The matching
`.release-please-manifest.json` carries the current version per package.

---

## 7. Acceptance checklist (a marketplace this plugin produces/audits-clean)

- [ ] Every catalog entry maps to a `plugins/<name>/` with a `plugin.json`; versions/refs in sync.
- [ ] The hygiene sensor (§3) is green — no shipped test/build scripts, all refs discoverable.
- [ ] Every script is cross-platform — bash runs on macOS, Linux, and Windows Git Bash (no OS-specific scripts); `shellcheck -x` clean (warning severity) over shipped + dev scripts; all shebangs `env bash`.
- [ ] Each `install.sh` has the Git-Bash-on-Windows guard; `scripts/dev-setup.sh` provisions the toolchain.
- [ ] CI runs structural + portability + bats gates; a local pre-push gate mirrors them.
- [ ] `release-please` wired with per-plugin packages + catalog `extra-files` sync.
- [ ] A gated `SessionStart` cloud hook + skill-file fallback exist.
- [ ] Every shipped `agents/*.md` has required `name`/`description`, least-privilege `tools`, and an explicit "does NOT handle" boundary; none uses the plugin-ignored `hooks`/`mcpServers`/`permissionMode` (see `agent-authoring.md`).
- [ ] No shipped skill merely runs a fixed deterministic command — those are hooks (§5b).
