````instructions
# Azure DevOps Work Item Management Instructions

## Overview

Use `az boards` CLI to create and manage work items in Azure DevOps. Configuration is loaded from `copilot-config/.github/config/workflow-config.json`.

## Prerequisites

- Azure CLI installed with DevOps extension (`az extension add --name azure-devops`)
- Logged in to Azure DevOps (`az login` or `az devops login`)
- Default organization and project configured (optional but recommended)

## Configuration

Configuration values are read from `workflow-config.json`:
- **Organization**: `azureDevOps.organization`
- **Project**: `azureDevOps.project`
- **Area Path**: `azureDevOps.areaPath`
- **Iteration**: `azureDevOps.iteration`

Set defaults to avoid repeating them:

```bash
az devops configure --defaults organization=https://dev.azure.com/ceapex project=Engineering
```

## Creating User Stories

To create a user story assigned to a specific person under a feature:

```bash
az boards work-item create \
  --type "User Story" \
  --title "<title>" \
  --assigned-to "<email from config>" \
  --area "<areaPath from config>" \
  --iteration "<iteration from config>" \
  --fields "System.Description=<description>" \
  --org <organization from config> \
  --project <project from config>
```

To link the user story to a parent feature:

```bash
az boards work-item relation add \
  --id <user-story-id> \
  --relation-type "Parent" \
  --target-id <feature-id> \
  --org <organization from config> \
  --project <project from config>
```

## Creating Dev Tasks (Unassigned)

To create an unassigned dev task under a user story:

```bash
az boards work-item create \
  --type "Task" \
  --title "<title>" \
  --area "<areaPath from config>" \
  --iteration "<iteration from config>" \
  --org <organization from config> \
  --project <project from config>
```

Then link it to the parent user story:

```bash
az boards work-item relation add \
  --id <task-id> \
  --relation-type "Parent" \
  --target-id <user-story-id> \
  --org <organization from config>
```

## SWE Assignment

To assign a work item to GitHub Copilot SWE:

```bash
az boards work-item update \
  --id <work-item-id> \
  --assigned-to "<sweAssignee from config>" \
  --org <organization from config>
```

## Common Fields

| Field               | Path                                       | Example                    |
| ------------------- | ------------------------------------------ | -------------------------- |
| Title               | System.Title                               | "Implement feature X"      |
| Description         | System.Description                         | "Details about the work"   |
| Acceptance Criteria | Microsoft.VSTS.Common.AcceptanceCriteria   | "Given... When... Then..." |
| Story Points        | Microsoft.VSTS.Scheduling.StoryPoints      | 3                          |
| Priority            | Microsoft.VSTS.Common.Priority             | 2                          |
| Original Estimate   | Microsoft.VSTS.Scheduling.OriginalEstimate | 8 (hours for tasks)        |
| Tags                | System.Tags                                | "swe-candidate"            |

## Querying Work Items

Find work items by area path:

```bash
az boards query --wiql "SELECT [System.Id], [System.Title] FROM workitems WHERE [System.AreaPath] = '<areaPath from config>' AND [System.State] <> 'Closed'" --org <organization> --project <project>
```

````
