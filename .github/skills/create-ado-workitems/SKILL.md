---
name: create-ado-workitems
description: Create structured Azure DevOps work items from an implementation plan with proper hierarchy (Feature → User Stories → Tasks). Use when a user wants to create ADO work items from a plan, break down an implementation plan into trackable work items, or set up a work item hierarchy for a feature. Triggers on requests like "create work items", "create ADO items from plan", "break this plan into stories and tasks".
---

# Create Azure DevOps Work Items from Plan

Create User Stories and Tasks in Azure DevOps from an implementation plan, linked under a parent Feature with proper hierarchy.

## Prerequisites

- Azure CLI with DevOps extension
- Authenticated via `az login`
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

Validate the parent feature exists:
```bash
az boards work-item show --id {FEATURE_ID} --org {org} --project {project}
```

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

For each phase, create a User Story linked to the parent Feature:

```bash
STORY_ID=$(az boards work-item create \
    --type "User Story" \
    --title "Phase {N}: {Phase Name}" \
    --assigned-to "{adoAssignee}" \
    --area "{areaPath}" \
    --iteration "{iteration}" \
    --description "{see references/templates.md}" \
    --org {org} --project {project} \
    --query "id" -o tsv)

az boards work-item relation add \
    --id $STORY_ID --relation-type "Parent" \
    --target-id {FEATURE_ID} --org {org}
```

### 4. Create Tasks

For each change within a phase, create a Task linked to its User Story:

```bash
TASK_ID=$(az boards work-item create \
    --type "Task" \
    --title "{file}: {change description}" \
    --area "{areaPath}" --iteration "{iteration}" \
    --description "{see references/templates.md}" \
    --org {org} --project {project} \
    --query "id" -o tsv)

az boards work-item relation add \
    --id $TASK_ID --relation-type "Parent" \
    --target-id $STORY_ID --org {org}
```

### 5. Tag SWE Candidates

For phases marked as SWE-suitable in the plan:

```bash
az boards work-item update --id $STORY_ID \
    --fields "System.Tags=swe-candidate" --org {org}
```

### 6. Output Summary

Present a table of all created items with IDs, types, titles, and SWE status. Include:
- Quick links to the board and parent feature
- List of SWE-candidate items ready for the `assign-swe` skill
- Suggested next steps

## Dry Run Mode

When `--dry-run` is specified, show the proposed structure without creating any items. Output counts and hierarchy only.

## Templates

See [references/templates.md](references/templates.md) for User Story and Task description HTML templates.
