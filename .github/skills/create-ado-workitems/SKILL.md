---
description: Create structured Azure DevOps work items from an implementation plan with proper hierarchy (Feature → User Stories → Tasks). Use when a user wants to create ADO work items from a plan, break down an implementation plan into trackable work items, or set up a work item hierarchy for a feature. Triggers on requests like "create work items", "create ADO items from plan", "break this plan into stories and tasks".
---

# Create Azure DevOps Work Items from Plan

Create User Stories and Tasks in Azure DevOps from an implementation plan, linked under a parent Feature with proper hierarchy.

## Prerequisites

- Call `activate_work_item_management` to access work item creation and linking tools
- Implementation plan in `copilot-config/agent-artifacts/plans/`

## Configuration

Load from `copilot-config/.github/config/workflow-config.json`:

- `azureDevOps.organization`, `azureDevOps.project`
- `azureDevOps.areaPath`, `azureDevOps.iteration`
- `user.adoAssignee`

## Process

### 1. Parse the Plan

Read the implementation plan. Extract phases with their descriptions, files, success criteria, and SWE suitability.

Prompt the user for:
- Plan path (or list available plans from `copilot-config/agent-artifacts/plans/`)
- Parent Feature ID to link items under

Validate the parent feature exists using the work item get tool:
- **project**: `{project}`
- **id**: `{FEATURE_ID}`

### 2. Propose Work Item Structure

Present the hierarchy for user approval before creating anything:

```
📁 Feature #{feature ID}: {title}
├── 📖 User Story: Phase 1 - {name}
│   ├── 📋 Task: {change 1}
│   └── 📋 Task: {change 2}
├── 📖 User Story: Phase 2 - {name}
│   └── 📋 Task: {change 1}
└── ...
```

### 3. Create User Stories

For each phase, create a User Story using the work item creation tool:
- **project**: `{project}`
- **type**: `User Story`
- **title**: `Phase {N}: {Phase Name}`
- **assignedTo**: `{adoAssignee}`
- **areaPath**: `{areaPath}`
- **iterationPath**: `{iteration}`
- **description**: `{see references/templates.md}`

Then link to the parent Feature using the work item link tool:
- **project**: `{project}`
- **id**: `{STORY_ID}` (from creation response)
- **type**: `parent`
- **targetId**: `{FEATURE_ID}`

### 4. Create Tasks

For each change within a phase, create a Task using the work item creation tool:
- **project**: `{project}`
- **type**: `Task`
- **title**: `{file}: {change description}`
- **areaPath**: `{areaPath}`
- **iterationPath**: `{iteration}`
- **description**: `{see references/templates.md}`

Then link to the parent User Story using the work item link tool:
- **project**: `{project}`
- **id**: `{TASK_ID}` (from creation response)
- **type**: `parent`
- **targetId**: `{STORY_ID}`

### 5. Tag SWE Candidates

For phases marked as SWE-suitable in the plan, use the work item update tool:
- **project**: `{project}`
- **id**: `{STORY_ID}`
- **tags**: `swe-candidate`

### 6. Output Summary

Present a table of all created items with IDs, types, titles, and SWE status. Include:
- Quick links to the board and parent feature
- List of SWE-candidate items ready for the `assign-swe` skill
- Suggested next steps

## Dry Run Mode

When `--dry-run` is specified, show the proposed structure without creating any items. Output counts and hierarchy only.

## Templates

See [references/templates.md](references/templates.md) for User Story and Task description HTML templates.
