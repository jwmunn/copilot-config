````instructions
# Azure DevOps Work Item Management Instructions

## Overview

Use the **Azure DevOps MCP tools** to create and manage work items. Configuration is loaded from `copilot-config/.github/config/workflow-config.json`.

## Prerequisites

- No CLI installation required — MCP tools are built into the agent environment
- Call `activate_work_item_management` to access work item tools
- Call `activate_azure_devops_project_management` to access project/repo tools

## Configuration

Configuration values are read from `workflow-config.json`:
- **Organization**: `azureDevOps.organization` (e.g., `https://dev.azure.com/ceapex`)
- **Project**: `azureDevOps.project` (e.g., `Engineering`)
- **Area Path**: `azureDevOps.areaPath`
- **Iteration**: `azureDevOps.iteration`

## Tool Activation

Before any work item operation, activate the appropriate tool group:

```
activate_work_item_management          → create, get, update, query, link work items
activate_work_item_comment_management  → add comments to work items
activate_azure_devops_project_management → list projects, teams, repos, search code/wikis
```

## Creating User Stories

Use the work item creation tool with:
- **project**: `{project from config}`
- **type**: `User Story`
- **title**: `<title>`
- **assignedTo**: `{adoAssignee from config}`
- **areaPath**: `{areaPath from config}`
- **iterationPath**: `{iteration from config}`
- **description**: `<description HTML>`

To link the user story to a parent feature, use the work item link tool with:
- **project**: `{project}`
- **id**: `<user-story-id>`
- **type**: `parent`
- **targetId**: `<feature-id>`

## Creating Dev Tasks (Unassigned)

Use the work item creation tool with:
- **project**: `{project from config}`
- **type**: `Task`
- **title**: `<title>`
- **areaPath**: `{areaPath from config}`
- **iterationPath**: `{iteration from config}`

Then link it to the parent user story with the work item link tool:
- **project**: `{project}`
- **id**: `<task-id>`
- **type**: `parent`
- **targetId**: `<user-story-id>`

## SWE Assignment

Use the work item update tool with:
- **project**: `{project}`
- **id**: `<work-item-id>`
- **assignedTo**: `{sweAssignee from config}`
- **tags**: `swe-assigned`

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

Use the work item query tool with a WIQL query:

```wiql
SELECT [System.Id], [System.Title]
FROM workitems
WHERE [System.AreaPath] = '{areaPath from config}'
  AND [System.State] <> 'Closed'
```

Or use `mcp_microsoft_azu_wit_get_query` with a saved query path or ID.

## Artifact Links

Use `mcp_microsoft_azu_wit_add_artifact_link` to link work items to branches, commits, builds, or PRs:
- **workItemId**: `<id>`
- **project**: `{project}`
- **linkType**: `Branch` | `Fixed in Commit` | `Pull Request` | `Build`
- Plus the relevant identifier (`branchName`, `commitId`, `pullRequestId`, `buildId`)

````
