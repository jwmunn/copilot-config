---
description: Analyze a completed session to extract learnings and generate self-healing patches for agents, prompts, skills, and instructions. Use at the end of a session to capture corrections, workarounds, and improvements the user made. Triggers on "extract learnings", "session learnings", "self-heal", "apply learnings", "improve prompts from session".
---

# Session Learnings (Self-Healing)

Analyze the current session to identify user corrections, workarounds, and repeated friction points, then generate concrete improvement suggestions for the copilot-config automation layer (agents, prompts, skills, instructions, hooks).

## When to Use

- End of any session where the user corrected agent behavior
- After a prompt/skill produced output that required manual fixing
- When you notice recurring patterns of user intervention
- As part of `/mslearn-create-handoff` to capture session intelligence

## Process

### 1. Analyze the Session

Review the full conversation for these **signal categories**:

| Signal | What to Look For | Example |
|--------|-----------------|---------|
| **Correction** | User says "no, do X instead" or edits agent output | "Don't use inline styles, use makeStyles" |
| **Workaround** | User manually does something the agent should have done | User runs a build step the agent skipped |
| **Repetition** | User explains the same thing multiple times | Repeatedly clarifying file structure conventions |
| **Frustration** | User expresses dissatisfaction with output quality | "That's not right", "Try again", "You keep doing X" |
| **Missing context** | Agent asks for info that should be in instructions | "Check the tsconfig for the path aliases" |
| **Wrong pattern** | Agent uses an anti-pattern for the codebase | Using `useState` where the codebase uses Fluent hooks |

### 2. Classify Each Learning

For each identified signal, determine:

1. **Scope**: Which file(s) should change?
   - `agents/*.agent.md` — behavioral rules, process steps
   - `prompts/*.prompt.md` — workflow steps, output format
   - `skills/*/SKILL.md` — action instructions, templates
   - `instructions/*.instructions.md` — contextual rules for file patterns
   - `.github/copilot-instructions.md` — global rules
   - `hooks/scripts/*` — automation guards

2. **Type**: What kind of change?
   - `rule` — Add a new rule or constraint
   - `example` — Add a concrete example of correct behavior
   - `guard` — Add a check that prevents the mistake
   - `context` — Add missing codebase context
   - `template` — Update output template/format

3. **Confidence**: How confident is this learning?
   - `high` — User explicitly stated the rule or corrected multiple times
   - `medium` — User corrected once; pattern is clear
   - `low` — Inferred from user behavior; may be situational

### 3. Generate Patches

For each learning, produce a **concrete diff** showing exactly what to add/change. Follow these rules:

- **Additive only** — prefer adding rules over modifying existing ones
- **Minimal scope** — target the most specific file possible (instruction > skill > prompt > agent > global)
- **Pattern-consistent** — match the formatting and style of the target file
- **Non-breaking** — changes must not conflict with existing rules

### 4. Write the Learnings Artifact

Save to `copilot-config/agent-artifacts/learnings/{filename}.md` using the template in [references/template.md](references/template.md).

Filename pattern: `{date}-{description}-learnings.md`  
Example: `2026-02-16-ssr-component-patterns-learnings.md`

### 5. Present Suggestions

After writing the artifact, present a summary to the user:

```
## Session Learnings Summary

Found {N} improvement(s) from this session:

### High Confidence
1. **{title}** → {target file}
   {one-line description of the change}

### Medium Confidence  
2. **{title}** → {target file}
   {one-line description of the change}

### Low Confidence (review recommended)
3. **{title}** → {target file}
   {one-line description of the change}

Would you like me to apply the high-confidence changes now?
```

### 6. Apply Changes (on user approval)

When the user approves:
- Apply high-confidence patches directly
- For medium/low confidence, show the full diff and wait for confirmation
- After applying, verify the target files are syntactically valid
- Log applied changes to the learnings artifact

## Scope Rules

### DO target
- Codebase-specific patterns (e.g., "always use `makeStyles` not inline styles")
- Missing process steps (e.g., "run `npm run clean` before build")
- Output format corrections (e.g., "include file:line references")
- Guard rails the user had to enforce manually
- Context that was missing from instructions

### DO NOT target
- One-off situational fixes (user typos, environment-specific issues)
- Changes that would make rules too specific to one feature/task
- Anything that contradicts the copilot-instructions.md architecture
- Security-sensitive changes (those go through manual review)

## Integration Points

This skill is designed to be called:
- By `/mslearn-create-handoff` — automatically extract learnings before handoff
- By `/mslearn-session-learnings` — standalone invocation
- By `/mslearn-ship-it` — optional learnings extraction before shipping
