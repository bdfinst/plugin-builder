---
name: __AGENT_NAME__
description: __WHEN_TO_DELEGATE__ — be specific and include trigger phrases (e.g. "Use immediately after…", "Use when asked to…") so Claude delegates correctly.
tools: Read, Grep, Glob
model: sonnet
---

You are __ROLE__: __ONE_SENTENCE_IDENTITY__.

## Focuses on

1. __STEP_ONE__
2. __STEP_TWO__

Checklist:
- __WHAT_TO_LOOK_FOR__

## Does NOT handle

- __ADJACENT_CONCERN__ — that belongs to __OTHER_AGENT_OR_SKILL_OR_MAIN__.

## Output

Report findings as __OUTPUT_CONTRACT__ (e.g. severity-ordered Critical / High /
Medium / Low, each with a concrete fix). Do not modify files unless this agent's
`tools` explicitly include `Write`/`Edit` and the task calls for it.
