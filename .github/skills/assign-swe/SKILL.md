---
name: assign-swe
description: Assign GitHub Copilot SWE (autonomous coding agent) to an Azure DevOps work item with structured implementation instructions. Use when a user wants to delegate a work item to SWE, assign an automated agent to implement a task, or batch-assign SWE to plan phases marked as SWE candidates. Triggers on "assign SWE", "delegate to SWE", "automate this work item".
---

# Assign GitHub SWE to Work Item

Assign GitHub Copilot Workspace Agent (SWE) to an ADO work item with structured instructions for autonomous implementation.

## Configuration

Load from `copilot-config/.github/config/workflow-config.json`:

- `azureDevOps.sweAssignee`, `azureDevOps.organization`, `azureDevOps.project`
- Repository-specific `buildCommand`, `testCommand` for verification steps

## Prerequisites

- Call `activate_work_item_management` to access work item tools

## Process

### 1. Validate Work Item

Use the work item get tool:
- **project**: `{project}`
- **id**: `{WORK_ITEM_ID}`

Verify the response includes `id`, `title`, and `state`.

### 2. Prepare Instructions

If a plan is referenced, extract the relevant phase details. Format structured instructions:

```markdown
## SWE Implementation Instructions

### Plan Reference
Plan: `{plan path}` — Phase: {N}

### Scope
{Phase description}

### Files to Modify
- `{file1}` - {change}
- `{file2}` - {change}

### Success Criteria
- [ ] {criterion 1}
- [ ] {criterion 2}

### Verification Commands
{buildCommand}
{testCommand}

### Pattern References
See `{example file:line}` for implementation pattern.
```

### 3. Assign and Tag

Use the work item update tool:
- **project**: `{project}`
- **id**: `{WORK_ITEM_ID}`
- **assignedTo**: `{sweAssignee}`
- **tags**: `swe-assigned`

Add the formatted instructions to the work item description.

### 4. Confirm

Output the work item ID, title, instruction summary, and a direct link to the work item.

## Batch Assignment

When `--from-plan {path} --phases 1,3,5` is specified:

1. Read the plan
2. Find phases marked as "SWE Candidate: Yes"
3. Locate or create work items for each phase
4. Assign each to SWE with phase-specific instructions

## SWE Candidate Assessment

### Good candidates
- Well-defined scope with clear success criteria
- Follows documented patterns with references
- Single repository, automated verification possible

### Not suitable
- Requires human judgment or cross-repo coordination
- Security-sensitive or architecturally ambiguous
- Complex design decisions needed

## Monitoring

Use the work item query tool with WIQL:

```wiql
SELECT [System.Id], [System.Title], [System.State]
FROM workitems
WHERE [System.Tags] CONTAINS 'swe-assigned'
  AND [System.AreaPath] = '{areaPath}'
```
