---
description: Create a concise handoff document to transfer work context to another agent session. Use when ending a session that has unfinished work, switching contexts, or needing to preserve implementation progress for continuity. Triggers on "create handoff", "hand off", "save session", "transfer context", "create continuity document".
---

# Create Handoff

Write a handoff document that compacts and summarizes the current session's context for another agent to resume from.

## Output Location

Save to `copilot-config/agent-artifacts/handoffs/{ticket-dir}/{filename}.md` where:

- **ticket-dir**: `CAS-XXX` if a ticket exists, otherwise `general`
- **filename**: `YYYY-MM-DD_HH-MM-SS_{ticket}_{description}` in kebab-case
- Example: `copilot-config/agent-artifacts/handoffs/CAS-123/2025-01-08_13-55-22_CAS-123_entity-conflation-fix.md`

## Process

### 1. Extract Session Learnings

Before gathering context, run the session-learnings analysis to capture any self-healing improvements from this session:

1. Read `.github/skills/session-learnings/SKILL.md` and follow its process
2. Analyze the conversation for correction signals (user fixes, workarounds, repeated explanations)
3. If learnings are found, present them and ask the user to approve high-confidence patches
4. Apply approved changes before creating the handoff
5. Reference the learnings artifact in the handoff document

If no learnings are found, note that in the handoff and continue.

### 2. Gather Context

Collect from the current session:
- Current git branch, commit hash, repository
- Tasks worked on and their completion status
- Files changed and key learnings
- Artifacts produced (plans, research docs, learnings docs, etc.)

### 3. Write the Document

Use the template in [references/template.md](references/template.md). Key principles:

- **Include Mermaid diagrams** — more token-efficient than prose for system context
- **Be thorough and precise** — include top-level objectives and lower-level details
- **Avoid excessive code snippets** — prefer `path/to/file.ts:line` references
- **More information, not less** — the template is a minimum, always add more if needed

### 4. Respond with Resume Command

After creating the document, respond with:

```
Handoff created! You can resume from this handoff in a new session with the following command:

/resume_handoff copilot-config/agent-artifacts/handoffs/{path-to-handoff.md}
```
