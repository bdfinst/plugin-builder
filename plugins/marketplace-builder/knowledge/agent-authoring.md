# Agent authoring (Anthropic's role-definition recommendations)

How to author **agents (subagents)** inside a plugin so each has a sharp,
single responsibility. Skills load this on demand. Sources:
<https://code.claude.com/docs/en/sub-agents> and
<https://code.claude.com/docs/en/plugins-reference> (Agents).

---

## 1. File format & location

Agent files live in `plugins/<name>/agents/<agent>.md` (same level as `skills/`,
`hooks/`). They may be nested (`agents/review/perf.md`). Each is Markdown with a
YAML frontmatter header; the body is the agent's **system prompt**.

```markdown
---
name: plugin-auditor
description: Read-only auditor that inspects a plugin against the marketplace conventions and reports findings by severity. Use when asked to deeply review or audit a plugin's structure, hygiene, and portability.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a meticulous plugin auditor. ...
```

### Frontmatter fields

| Field | Required | Notes |
|---|---|---|
| `name` | **yes** | lowercase-hyphen identifier; used in delegation. |
| `description` | **yes** | *When* Claude should delegate here. Drives automatic delegation — be specific, include trigger phrases ("Use immediately after…", "Use when asked to…"). |
| `tools` | no | Comma-separated allowlist (`Read, Grep, Glob, Bash`). Omit to inherit all. May name MCP tools/servers. **Recommended: set it** (least privilege). |
| `disallowedTools` | no | Denylist, applied first. |
| `model` | no | `sonnet` \| `opus` \| `haiku` \| full id (`claude-opus-4-8`) \| `inherit`. Default: `inherit`. |
| `effort` | no | `low`\|`medium`\|`high`\|`xhigh`\|`max`. |
| `maxTurns` | no | Cap on agentic turns. |
| `skills` | no | Skill names to preload into the agent's context. |
| `memory` | no | `user`\|`project`\|`local`. |
| `background` | no | `true` to default to a background task. |
| `isolation` | no | `"worktree"` (only valid value for plugin agents). |

**Plugin agents ignore `hooks`, `mcpServers`, and `permissionMode`** — they are
dropped for security when loaded from a plugin. Do not put them in a plugin
agent; if a user needs them they must copy the agent into `.claude/agents/`.
`agent-check.sh` flags these as errors.

---

## 2. Anthropic's role-definition recommendations

> "Design focused subagents: each subagent should excel at one specific task."
> "Write detailed descriptions: Claude uses the description to decide when to delegate."

**Single responsibility.** One agent, one job. A `code-reviewer` reviews; a
`debugger` debugs; a `security-reviewer` audits security. Multi-purpose agents
dilute focus and waste tokens.

**State focus AND non-responsibility.** Every agent's system prompt should make
both explicit:

- **Focuses on:** the one thing it owns, as a numbered workflow + a concrete
  checklist of what to look for.
- **Does NOT handle:** the adjacent concerns it must *not* drift into (and, where
  useful, which agent/skill owns them instead). This boundary is the difference
  between a focused agent and a vague one.
- **Output contract:** how it returns results (e.g. findings by severity:
  Critical / High / Medium / Low, with concrete fixes).

**Least-privilege tools.** Set `tools` to the minimum the job needs. A read-only
reviewer gets `Read, Grep, Glob` (and `Bash` only if it must run commands) — never
`Write`/`Edit`. Benefits: security, lower context cost, tighter focus.

**Right-size the model.** `haiku` for lightweight screening, `sonnet` for most
focused work, `opus` only when maximum reasoning is required.

**Split vs. keep as one.** Split into separate agents when tasks are
independent, want different models or tool access, or produce verbose output you
want isolated from the main context. Keep as one when steps are tightly coupled
and share context. Agents **cannot spawn other agents** (no nesting) — chain them
from the main conversation instead.

---

## 3. System-prompt skeleton this plugin scaffolds

```markdown
You are <role>: <one-sentence identity>.

## Focuses on
1. <step>
2. <step>
Checklist:
- <specific thing to look for>

## Does NOT handle
- <adjacent concern> — that belongs to <other agent/skill/the main conversation>.

## Output
Report findings as <contract, e.g. severity-ordered list with fixes>.
```

See `templates/plugin/agent.md` for the scaffolded template and
`agents/plugin-auditor.md` for a worked example.
