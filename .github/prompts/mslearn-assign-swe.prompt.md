---
description: Assign GitHub Copilot SWE to an ADO work item
mode: agent
---

# Assign GitHub SWE to Work Item

Skill for assigning GitHub Copilot Workspace Agent (SWE) to Azure DevOps work items.

## Configuration

Load from `copilot-config/.github/config/workflow-config.json`:
- `azureDevOps.sweAssignee`: SWE identity for assignment
- `azureDevOps.organization`
- `azureDevOps.project`

## Usage

### Assign SWE to specific work item:
```
/assign-swe {WORK_ITEM_ID}
```

### Assign SWE with instructions:
```
/assign-swe {WORK_ITEM_ID} --instructions "Follow plan at copilot-config/agent-artifacts/plans/{plan}.md, implement Phase 2"
```

## Process

### Step 1: Validate Work Item

```bash
# Verify work item exists and get current state
az boards work-item show \
    --id {WORK_ITEM_ID} \
    --org https://dev.azure.com/ceapex \
    --project Engineering \
    --query "{id:id, title:fields.\"System.Title\", state:fields.\"System.State\", assignee:fields.\"System.AssignedTo\".displayName}"
```

### Step 2: Prepare Instructions

If a plan is referenced, extract relevant phase details:
```
Reading plan: {plan path}
Extracting Phase {N} details for work item instructions...
```

Format instructions for the work item:
```markdown
## SWE Implementation Instructions

### Context
This work item is assigned to GitHub Copilot SWE for automated implementation.

### Plan Reference
Plan: `{plan path}`
Phase: {N}

### Scope
{Phase description}

### Files to Modify
- `{file1}` - {change}
- `{file2}` - {change}

### Success Criteria
- [ ] {criterion 1}
- [ ] {criterion 2}

### Verification Commands
```bash
{build command from config}
{test command from config}
```

### Pattern References
See `{example file:line}` for implementation pattern.
```

### Step 3: Assign Work Item

```bash
# Assign to SWE
az boards work-item update \
    --id {WORK_ITEM_ID} \
    --assigned-to "66dda6c5-07d0-4484-9979-116241219397@72f988bf-86f1-41af-91ab-2d7cd011db47" \
    --org https://dev.azure.com/ceapex \
    --project Engineering

# Add implementation instructions as comment or description update
az boards work-item update \
    --id {WORK_ITEM_ID} \
    --fields "System.Description={updated description with instructions}" \
    --org https://dev.azure.com/ceapex \
    --project Engineering
```

### Step 4: Add SWE Tag

```bash
# Tag the work item as SWE-assigned
az boards work-item update \
    --id {WORK_ITEM_ID} \
    --fields "System.Tags=swe-assigned" \
    --org https://dev.azure.com/ceapex \
    --project Engineering
```

### Step 5: Confirmation

```
✅ Work item assigned to GitHub Copilot SWE

Work Item: #{WORK_ITEM_ID}
Title: {title}
Assignee: GitHub Copilot SWE
Tags: swe-assigned

Instructions added:
- Plan reference: {plan path}
- Phase: {N}
- Files: {count} files to modify

View work item: https://dev.azure.com/ceapex/Engineering/_workitems/edit/{WORK_ITEM_ID}

Note: SWE will process this work item asynchronously. 
Monitor the work item for updates and PR creation.
```

## Batch Assignment

Assign multiple work items from a plan:
```
/assign-swe --from-plan {plan path} --phases 1,3,5
```

This will:
1. Read the plan
2. Find phases marked as "SWE Candidate: Yes"
3. Create or find work items for each phase
4. Assign each to SWE with appropriate instructions

## Best Practices

### Good SWE Candidates
- Well-defined scope
- Clear success criteria
- Follows documented patterns
- Single repository changes
- Automated verification possible

### Not Suitable for SWE
- Requires human judgment
- Cross-repository coordination
- Security-sensitive changes
- Ambiguous requirements
- Complex architectural decisions

## Monitoring SWE Progress

After assignment, check status:
```bash
# Query SWE-assigned items
az boards query \
    --wiql "SELECT [System.Id], [System.Title], [System.State] FROM workitems WHERE [System.Tags] CONTAINS 'swe-assigned' AND [System.AreaPath] = 'Engineering\\POD\\Xinxin-OctoPod'" \
    --org https://dev.azure.com/ceapex \
    --project Engineering
```

