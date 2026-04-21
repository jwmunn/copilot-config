---
description: Assign GitHub Copilot SWE to an ADO work item
agent: mslearn-planning
model: Claude Opus 4.6 (fast mode) (Preview) (copilot)
---

# Assign GitHub SWE to Work Item

Assign GitHub Copilot Workspace Agent (SWE) to Azure DevOps work items with structured implementation instructions.

## Instructions

Follow the skill instructions in `copilot-config/.github/skills/mslearn-assign-swe/SKILL.md`.

## Workflow

1. Validate the target work item exists and get its current state
2. Prepare structured SWE instructions (extract plan/phase details if referenced)
3. Assign work item to SWE identity and add instructions to description
4. Tag work item with `swe-assigned`
5. Confirm assignment with work item link and instruction summary
6. For batch mode (`--from-plan`), process all SWE-candidate phases

