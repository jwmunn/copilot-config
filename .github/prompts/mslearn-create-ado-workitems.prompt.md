---
description: Create ADO work items from an implementation plan with proper hierarchy and instructions
agent: mslearn-planning
model: Claude Opus 4.6 (fast mode) (Preview) (copilot)
---

# Create Azure DevOps Work Items from Plan

Create structured work items in Azure DevOps from an implementation plan, with proper hierarchy (Feature → User Stories → Tasks) and SWE assignment ready.

## Instructions

Follow the skill instructions in `copilot-config/.github/skills/mslearn-create-ado-workitems/SKILL.md`.

## Workflow

1. Parse the implementation plan from `copilot-config/agent-artifacts/plans/`
2. Prompt for plan path and parent Feature ID (validate feature exists)
3. Propose work item hierarchy for user approval before creating anything
4. Create User Stories for each phase, linked to parent Feature
5. Create Tasks for each change, linked to their User Story
6. Tag SWE-candidate phases for later `/mslearn-assign-swe` assignment
7. Output summary table with IDs, links, and suggested next steps

