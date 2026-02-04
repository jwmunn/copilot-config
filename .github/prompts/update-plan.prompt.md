````prompt
---
description: Review codebase status and update implementation plan with current progress
---

# Update Plan Workflow

Review the current state of implementation against a plan and update the plan with actual progress.

## When to Use

- Syncing plan with actual implementation state
- Resuming work after a break
- Tracking progress across sessions

## Configuration

Load from `copilot-config/.github/config/workflow-config.json` for repository details.

## Process

### Step 1: Identify Plan

```
Looking for plan to update...

Options:
1. Specify plan path: copilot-config/agent-artifacts/plans/{file}.md
2. Search by ticket ID
3. List recent plans
```

If no plan specified, list available:
```bash
ls -la copilot-config/agent-artifacts/plans/
```

### Step 2: Read Plan

Read the plan completely:
```
Reading plan: {path}

Phases:
1. {Phase 1 name} - {current status marker}
2. {Phase 2 name} - {current status marker}
...
```

### Step 3: Analyze Codebase State

For each phase in the plan, check if changes have been made:

```
Analyzing codebase against plan...

Phase 1: {name}
- [ ] Check: `{file1}` - {expected change}
- [ ] Check: `{file2}` - {expected change}

Phase 2: {name}
- [ ] Check: `{file1}` - {expected change}
```

Use:
- **grep** to check if specific patterns exist
- **read_file** to verify implementations
- **git diff** to see recent changes

### Step 4: Generate Status Report

```markdown
## Plan Status Update: {plan name}

**Plan**: `{plan path}`
**Checked**: {timestamp}
**Branch**: {current branch}

### Phase Status

| Phase | Expected | Actual | Status |
|-------|----------|--------|--------|
| Phase 1 | {description} | {what was found} | ✅ Complete |
| Phase 2 | {description} | {what was found} | 🔄 Partial |
| Phase 3 | {description} | {what was found} | ⬜ Not started |

### Detailed Findings

#### Phase 1: {name} ✅ COMPLETE
**Expected changes**:
- `{file}` - {change}

**Found in codebase**:
- `{file:line}` - {implementation found}

**Verified**: {timestamp}

---

#### Phase 2: {name} 🔄 PARTIAL (60%)
**Expected changes**:
- `{file1}` - {change1} ✅ Found
- `{file2}` - {change2} ❌ Not found

**What remains**:
1. {Remaining task}

---

#### Phase 3: {name} ⬜ NOT STARTED
**Expected changes**:
- `{file}` - {change}

**Found**: No implementation yet

---

### Overall Progress

```
[████████░░░░░░░░░░░░] 40% Complete

✅ Completed: 2 phases
🔄 In Progress: 1 phase  
⬜ Remaining: 2 phases
```

### Next Steps
1. Complete Phase 2: {remaining item}
2. Begin Phase 3: {first task}

### Discrepancies Found
- {Any differences from plan}
- {Unexpected changes}
```

### Step 5: Update Plan File

Update the plan artifact with status:

```markdown
# Implementation Plan: {name}

**Status**: 🔄 In Progress (40%)
**Last Updated**: {timestamp}
**Updated By**: {user.alias}

## Phase Status Summary
- ✅ Phase 1: Complete
- 🔄 Phase 2: In Progress  
- ⬜ Phase 3-5: Not Started

---

## Phase 1: {name} ✅ COMPLETE

**Completed**: {date}
**Verified by**: {automation/manual}

[rest of phase details...]

---

## Phase 2: {name} 🔄 IN PROGRESS

**Progress**: 60%
**Last worked**: {date}

### Completed:
- [x] {task 1}
- [x] {task 2}

### Remaining:
- [ ] {task 3}

[rest of phase details...]
```

### Step 6: Present Summary

```
Plan updated: {plan path}

Progress: {percentage}%
- Completed: {N} phases
- In progress: {N} phases
- Remaining: {N} phases

Next recommended action:
→ Complete Phase {N}: {first remaining task}

Would you like to:
1. Continue implementation
2. Create handoff document
3. View detailed status
```

## Quick Commands

```
/update-plan                              # Interactive plan selection
/update-plan {plan-path}                  # Update specific plan
/update-plan --ticket {ADO-ID}            # Find and update plan by ticket
```

## Integration with Other Workflows

```
/update-plan                    # Check current status
→ See what's done vs remaining

/implementation                  # Continue work
→ Pick up where left off

/create_handoff                 # Save progress
→ Document for later/handoff
```

````
