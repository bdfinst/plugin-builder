---
name: add-agent
description: Author a focused subagent inside a plugin using Anthropic's role-definition recommendations — single responsibility, an explicit "focuses on" workflow AND a "does NOT handle" boundary, least-privilege tools, and a right-sized model. Use when adding an agent to a plugin.
user-invocable: true
---

# /add-agent `<plugin>` `<agent-name>`

Scaffold a well-scoped agent at `plugins/<plugin>/agents/<agent-name>.md`.

## Before you start

Read `${CLAUDE_PLUGIN_ROOT}/knowledge/agent-authoring.md` (the format + Anthropic's
recommendations) and `${CLAUDE_PLUGIN_ROOT}/knowledge/marketplace-conventions.md`
§5b (primitive selection).

**First ask: should this even be an agent?** Apply the decision order
*deterministic tool/hook → skill → agent*:
- If the job is deterministic (validate, lint, format, block), it is a **hook**
  wired to a script — not an agent and not a skill. Stop and build that instead.
- If it is a reusable procedure needing light judgment, it may be a **skill**.
- Choose an **agent** only for complex, high-context, multi-step reasoning you
  want isolated from the main conversation.

## Procedure

1. **Confirm the plugin exists** (`plugins/<plugin>/.claude-plugin/plugin.json`).
   Create `plugins/<plugin>/agents/` if absent.

2. **Define the role with the user (single responsibility).** Pin down, in one
   sentence each:
   - the agent's **one** job (its identity);
   - what it **focuses on** — a numbered workflow + a concrete checklist;
   - what it **does NOT handle** — the adjacent concerns it must not drift into,
     and which agent/skill/main-conversation owns them instead;
   - its **output contract** (e.g. findings by severity, with fixes).

3. **Scaffold from the template.** Copy
   `${CLAUDE_PLUGIN_ROOT}/templates/plugin/agent.md` to
   `plugins/<plugin>/agents/<agent-name>.md` and fill every `__PLACEHOLDER__`:
   - `name`: lowercase-hyphen, matches the filename.
   - `description`: *when to delegate* — specific, with trigger phrases. This
     drives automatic delegation; vague descriptions never get picked.
   - `tools`: **least privilege** — only what the job needs. A read-only
     reviewer gets `Read, Grep, Glob` (add `Bash` only if it must run commands);
     never `Write`/`Edit` unless it must modify files.
   - `model`: `haiku` for screening, `sonnet` for most work, `opus` only when
     maximum reasoning is required.
   - Do **not** add `hooks`, `mcpServers`, or `permissionMode` — plugin agents
     ignore them.

4. **Validate + report.** Run `bash scripts/agent-check.sh` (required fields,
   forbidden fields, least-privilege warning) and `bats tests/repo`. Report the
   new file and the green gates.
