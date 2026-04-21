---
description: Extract learnings from the current session and suggest self-healing improvements to agents, prompts, skills, and instructions
agent: mslearn-implementation
model: claude-sonnet-4-20250514
---

# Session Learnings

Extract learnings and self-healing improvements from the current session.

## Instructions

Read the skill definition at `.github/skills/mslearn-session-learnings/SKILL.md` and follow its process exactly.

## Context

You have access to:
- The full conversation history from this session
- All files in `copilot-config/.github/` (agents, prompts, skills, instructions, hooks)
- The learnings template at `.github/skills/mslearn-session-learnings/references/template.md`

## Steps

1. Read `.github/skills/mslearn-session-learnings/SKILL.md` for detailed instructions
2. Analyze this session's conversation for correction signals
3. Classify each learning by scope, type, and confidence
4. Generate concrete patches for the relevant automation files
5. Write the learnings artifact to `copilot-config/agent-artifacts/learnings/`
6. Present a summary and ask whether to apply high-confidence changes
7. Apply approved changes and verify file integrity

## Important

- Be conservative — only suggest changes you're confident will improve future sessions
- Prefer additive changes (new rules/examples) over modifications to existing rules
- Always show the full diff before applying any change
- If no learnings are found, say so — don't invent improvements
