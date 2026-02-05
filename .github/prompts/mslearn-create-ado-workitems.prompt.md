---
description: Create ADO work items from an implementation plan with proper hierarchy and instructions
---

# Create Azure DevOps Work Items from Plan

Create structured work items in Azure DevOps from an implementation plan, with proper hierarchy and SWE assignment ready.

## Prerequisites

- Azure CLI with DevOps extension (`az extension add --name azure-devops`)
- Logged in (`az login`)
- Implementation plan in `copilot-config/agent-artifacts/plans/`

## Configuration

Load from `copilot-config/.github/config/workflow-config.json`:
- `azureDevOps.organization`: https://dev.azure.com/ceapex
- `azureDevOps.project`: Engineering
- `azureDevOps.areaPath`: Engineering\POD\Xinxin-OctoPod
- `azureDevOps.iteration`: Engineering\POD\Xinxin-OctoPod
- `user.adoAssignee`: jumunn@microsoft.com

## Usage

### From plan with parent feature:
```
/create-ado-workitems

Plan: copilot-config/agent-artifacts/plans/{plan-file}.md
Parent Feature ID: {ADO Feature ID}
```

### Interactive mode:
```
/create-ado-workitems

I'll create ADO work items. Please provide:
1. Plan path (or I'll list available plans)
2. Parent Feature ID to link items to
```

## Process

### Step 1: Read and Parse Plan

```
Reading plan: {plan path}

Found {N} phases:
1. {Phase 1 name} - SWE: {Yes/No} - Complexity: {S/M/L}
2. {Phase 2 name} - SWE: {Yes/No} - Complexity: {S/M/L}
...

Parent Feature: #{feature ID}
```

Validate parent feature exists:
```bash
az boards work-item show --id {FEATURE_ID} --org https://dev.azure.com/ceapex --project Engineering
```

### Step 2: Create Work Items Structure

For each phase, create:
1. **User Story** - Represents the phase
2. **Tasks** - Individual changes within the phase

```
Proposed structure:

📁 Feature #{feature ID}: {feature title}
├── 📖 User Story: Phase 1 - {name}
│   ├── 📋 Task: {file1 changes}
│   └── 📋 Task: {file2 changes}
├── 📖 User Story: Phase 2 - {name}
│   ├── 📋 Task: {file1 changes}
│   └── 📋 Task: {file2 changes}
└── ...

Proceed with creation? (y/n)
```

### Step 3: Create User Stories

For each phase:

```bash
# Create user story
STORY_ID=$(az boards work-item create \
    --type "User Story" \
    --title "Phase {N}: {Phase Name}" \
    --assigned-to "jumunn@microsoft.com" \
    --area "Engineering\\POD\\Xinxin-OctoPod" \
    --iteration "Engineering\\POD\\Xinxin-OctoPod" \
    --description "{phase description with success criteria}" \
    --org https://dev.azure.com/ceapex \
    --project Engineering \
    --query "id" -o tsv)

# Link to parent feature
az boards work-item relation add \
    --id $STORY_ID \
    --relation-type "Parent" \
    --target-id {FEATURE_ID} \
    --org https://dev.azure.com/ceapex
```

### Step 4: Create Tasks

For each change within a phase:

```bash
# Create task (unassigned)
TASK_ID=$(az boards work-item create \
    --type "Task" \
    --title "{file}: {change description}" \
    --area "Engineering\\POD\\Xinxin-OctoPod" \
    --iteration "Engineering\\POD\\Xinxin-OctoPod" \
    --description "{detailed change instructions}" \
    --org https://dev.azure.com/ceapex \
    --project Engineering \
    --query "id" -o tsv)

# Link to parent user story
az boards work-item relation add \
    --id $TASK_ID \
    --relation-type "Parent" \
    --target-id $STORY_ID \
    --org https://dev.azure.com/ceapex
```

### Step 5: Add SWE Tags

For phases marked as SWE candidates:

```bash
# Tag user story as SWE-suitable
az boards work-item update \
    --id $STORY_ID \
    --fields "System.Tags=swe-candidate" \
    --org https://dev.azure.com/ceapex
```

### Step 6: Output Summary

```
✅ Work items created successfully!

Created under Feature #{feature ID}:

| ID | Type | Title | Assigned | SWE |
|----|------|-------|----------|-----|
| #{id1} | User Story | Phase 1: {name} | jumunn | ⬜ |
| #{id2} | Task | {task1} | - | - |
| #{id3} | Task | {task2} | - | - |
| #{id4} | User Story | Phase 2: {name} | jumunn | ✅ |
| #{id5} | Task | {task3} | - | - |

SWE-candidate items (ready for /assign-swe):
- #{id4}: Phase 2 - {name}

Quick links:
- Board: https://dev.azure.com/ceapex/Engineering/_boards/board/t/Xinxin-OctoPod/Backlog%20items
- Feature: https://dev.azure.com/ceapex/Engineering/_workitems/edit/{feature ID}

Next steps:
1. Review created items in ADO
2. Assign SWE items: /assign-swe {ID}
3. Begin implementation: /implementation {Plan path}
```

## Work Item Templates

### User Story Description Template
```html
<h2>Overview</h2>
<p>{Phase description from plan}</p>

<h2>Plan Reference</h2>
<p>Implementation Plan: {plan path}</p>
<p>Phase: {N} of {total}</p>

<h2>Changes Required</h2>
<ul>
{list of files and changes}
</ul>

<h2>Success Criteria</h2>
<h3>Automated Verification</h3>
<ul>
<li>{automated check 1}</li>
<li>{automated check 2}</li>
</ul>

<h3>Manual Verification</h3>
<ul>
<li>{manual check 1}</li>
</ul>

<h2>SWE Suitability</h2>
<p>{Yes/No with reasoning}</p>
```

### Task Description Template
```html
<h2>Change</h2>
<p>{Detailed change description}</p>

<h2>File</h2>
<p><code>{file path}</code></p>

<h2>Pattern Reference</h2>
<p>See <code>{similar file:line}</code> for implementation pattern.</p>

<h2>Code Changes</h2>
<pre><code>
{code snippet if provided in plan}
</code></pre>
```

## Dry Run Mode

Preview without creating:
```
/create-ado-workitems --dry-run

Would create:
- 5 User Stories
- 12 Tasks

Total items: 17
Parent: Feature #{ID}

No items created (dry run mode)
```

