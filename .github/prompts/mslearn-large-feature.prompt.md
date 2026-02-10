---
description: Comprehensive workflow for large features spanning multiple repos - research, plan, then implement
model: Claude Opus 4.6 (copilot)
---

# Large Feature Workflow

Comprehensive workflow for complex features that require thorough research, cross-repository analysis, and phased implementation.

## When to Use

- Feature spans multiple repositories
- Significant complexity or unknowns
- Cross-team coordination needed
- Estimated time: > 1 day
- Would benefit from SWE delegation

## Configuration

Load from `copilot-config/.github/config/workflow-config.json` for:
- Repository details and repo pairs
- Build/test commands per repo
- Preview URL patterns
- Artifact paths

## Phase 1: Research

### 1.1 Scope Definition

```
Large feature: {description}

Repositories involved (from workspace):
- [ ] {repo1} - {why}
- [ ] {repo2} - {why}

Key questions to answer:
1. What exists today?
2. What needs to change?
3. What are the integration points?
4. What are the risks?
```

**Check if all mentioned repos are in workspace:**
- If a repo is NOT in workspace, ask if user wants to add it
- Clone if confirmed, then continue with research

### 1.2 Deep Research

Invoke the **research** agent:
```
@research Analyze {feature description}

Focus repositories: {repo1}, {repo2}

Research goals:
1. Map current implementation of {related feature}
2. Identify all integration points between repos
3. Document patterns to follow
4. Define success criteria
```

Wait for research artifact at `copilot-config/agent-artifacts/research/`

### 1.3 Review Research

Present research summary and **pause for user review**:
```
✅ Research complete!

Artifact: `copilot-config/agent-artifacts/research/{filename}.md`

Key findings:
- {Finding 1}
- {Finding 2}

Success criteria identified:
- [ ] {Criterion 1}
- [ ] {Criterion 2}

⏸️ PAUSED FOR REVIEW

Please review the research artifact for accuracy. When ready to continue:

  @planning Create implementation plan from:
  copilot-config/agent-artifacts/research/{filename}.md

Or to refine the research:
  @research [additional questions or areas to explore]
```

**Do not proceed to planning automatically.** Wait for user to invoke the planning agent.

---

## Phase 2: Planning

### 2.1 Create Implementation Plan

Invoke the **planning** agent with research artifact:
```
@planning Create implementation plan from:
copilot-config/agent-artifacts/research/{research-file}.md

Requirements:
- Identify SWE-suitable phases
- Include cross-repo coordination steps
- Define testing strategy with preview URLs
```

Wait for plan artifact at `copilot-config/agent-artifacts/plans/`

### 2.2 Review Plan

Present plan summary and **pause for user review**:
```
✅ Plan created!

Artifact: `copilot-config/agent-artifacts/plans/{filename}.md`

Phases: {N} total
- {X} suitable for SWE assignment
- {Y} require human implementation

Estimated complexity: {S/M/L}

⏸️ PAUSED FOR REVIEW

Please review the plan artifact for accuracy and completeness.

When ready, choose your next step:

1. Create ADO work items:
   /create-ado-workitems
   Plan: copilot-config/agent-artifacts/plans/{filename}.md
   Parent Feature ID: {your feature ID}

2. Begin implementation directly:
   @implementation
   Plan: copilot-config/agent-artifacts/plans/{filename}.md
   Execute: Phase 1

3. Update/refine the plan:
   @planning [refinements needed]

4. Check plan status later:
   /update-plan copilot-config/agent-artifacts/plans/{filename}.md
```

**Do not proceed to implementation automatically.** Wait for user direction.

---

## Phase 3: Work Item Creation (Optional)

If creating ADO work items:
```
@create-ado-workitems

Plan: copilot-config/agent-artifacts/plans/{plan-file}.md
Parent Feature ID: {ADO feature ID}
Assign to: {from config.user.adoAssignee}
```

See `/create-ado-workitems` for detailed work item creation.

## Phase 4: Implementation

### 4.1 Phase Selection

```
Implementation options:

Human implementation:
- Phases requiring judgment/complexity

SWE delegation:
- Phases marked as SWE-suitable

Which approach for which phases?
```

### 4.2 Human Implementation

Invoke **implementation** agent:
```
@implementation

Plan: copilot-config/agent-artifacts/plans/{plan-file}.md
Execute: Phase {N}
```

### 4.3 SWE Delegation

For SWE-suitable phases:
```
@assign-swe

Work Item: {ADO ID}
Instructions: Implement Phase {N} following plan at {path}
```

## Phase 5: Integration & Testing

After all phases complete:
```
Integration checklist:

Per-repository:
- [ ] {repo1}: Build passes, tests pass
- [ ] {repo2}: Build passes, tests pass

Cross-repository:
- [ ] Integration points verified
- [ ] Preview environments tested

Preview URLs:
- {repo1}: {previewUrlPattern from config}
- {repo2}: {previewUrlPattern from config}
```

## Phase 6: Ship

When ready to ship:
```
Run `/ship-it` for each repository with changes.
```

## Artifact Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Research   │ ──▶ │   Planning  │ ──▶ │ ADO Items   │
│   Agent     │     │    Agent    │     │  (optional) │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  research/  │     │   plans/    │     │ Work Items  │
│  {file}.md  │     │  {file}.md  │     │  in ADO     │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │ Phase 1  │ │ Phase 2  │ │ Phase 3  │
        │  (SWE)   │ │ (Human)  │ │  (SWE)   │
        └──────────┘ └──────────┘ └──────────┘
```

## Handoff Support

To pause work and create handoff:
```
/create_handoff

Task: {feature name}
Status: Phase {N} complete, Phase {M} in progress
```

To resume:
```
/resume_handoff copilot-config/agent-artifacts/handoffs/{file}.md
```

