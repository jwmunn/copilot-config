---
description: Create handoff document for transferring work to another session
agent: mslearn-planning
model: Claude Opus 4.6 (fast mode) (Preview) (copilot)
---

# Create Handoff

Create a concise handoff document that compacts and summarizes your session context for another agent to resume from.

## Instructions

Follow the skill instructions in `copilot-config/.github/skills/create-handoff/SKILL.md`.

## Workflow

1. **Extract session learnings first** — read `copilot-config/.github/skills/session-learnings/SKILL.md` and analyze the session for correction signals. Present any findings and apply approved patches before proceeding.
2. Gather session context: git branch, commit hash, repo, tasks worked on, files changed
3. Determine output path using ticket number or `general` directory with timestamped filename
4. Write handoff document with YAML frontmatter, Mermaid diagrams, and structured sections
5. Include critical references, recent changes, learnings, artifacts, and next steps
6. Reference any learnings artifact produced in step 1
7. Respond with the `/resume_handoff` command pointing to the created document
