---
description: Analyze a feature in one repo and create a plan for implementing it in another repo
mode: agent
---

# Parity Feature Workflow

Workflow for analyzing an existing feature in one repository and creating an implementation plan for replicating it in another repository.

## When to Use

- Porting functionality between repos
- Feature exists in one repo, need it in another
- Want to maintain consistency across platforms

## Process

### Step 1: Identify Source and Target

First, identify the repositories from the user's request:

```
Parity feature request: {description}

Source repository: {repo with existing feature}
Target repository: {repo to implement in}
```

**Check if repos are in workspace:**
- List current workspace folders
- If target repo is NOT in workspace, ask:
  ```
  The repository "{repo name}" is not in your current workspace.
  
  Would you like me to add it? I can clone it to your workspace.
  
  Once added, I'll continue with the parity analysis.
  ```
- If user confirms, clone the repo and continue
- If user declines, work with available repos or ask for alternative

### Step 2: Analyze Source Implementation

Use **research** agent to document the source:
```
@research Document {feature name} implementation

Repository: {source repo}

Focus on:
1. Component structure and files
2. Public API/interface
3. State management approach
4. Styling patterns
5. Accessibility implementation
6. Tests

Output: Complete technical specification
```

Research artifact: `copilot-config/agent-artifacts/research/{date}-parity-{feature}-source.md`

### Step 3: Analyze Target Patterns

Use **research** agent for target repo conventions:
```
@research Analyze patterns in {target repo}

Find:
1. Similar existing components
2. Directory structure conventions
3. Styling approach differences
4. Testing patterns
5. Build/bundle requirements

Compare with source implementation.
```

Research artifact: `copilot-config/agent-artifacts/research/{date}-parity-{feature}-target-patterns.md`

### Step 4: Create Parity Plan

Use **planning** agent with both research artifacts:
```
@planning Create parity implementation plan

Source documentation: {source research path}
Target patterns: {target patterns research path}

Requirements:
1. Map source → target equivalents
2. Identify adaptation needed for target patterns
3. Note any features that can't be ported directly
4. Include testing strategy
```

### Step 5: Present Comparison

```markdown
## Parity Plan: {feature name}

### Source vs Target Comparison

| Aspect | Source ({source repo}) | Target ({target repo}) |
|--------|------------------------|------------------------|
| Component location | `{path}` | `{planned path}` |
| Styling | {approach} | {approach} |
| State management | {approach} | {approach} |
| Testing | {approach} | {approach} |

### Adaptation Required

#### Direct port (minimal changes):
- {Component A}
- {Utility B}

#### Requires adaptation:
- {Component C} - {why and how}
- {Pattern D} - {target equivalent}

#### Cannot port (different approach needed):
- {Feature E} - {target alternative}

### Implementation Plan
{link to plan artifact}

Ready to proceed with implementation?
```

## Pattern Mapping

During research, identify how patterns differ between source and target repos. Common mapping categories:

| Category | Look For |
|----------|----------|
| Styling | CSS-in-JS vs LESS/SCSS vs Tailwind |
| Components | Class vs Function, framework differences |
| State | Internal state vs props vs context vs store |
| Testing | Test framework, patterns, coverage expectations |
| Build | Bundler, transpilation, output format |

The research agent will document specific mappings for your source → target repos.

## Verification

After implementation:
```
Parity verification checklist:

Functionality:
- [ ] Feature works identically in target
- [ ] Edge cases handled similarly
- [ ] Accessibility maintained

Build:
- [ ] Source repo builds successfully
- [ ] Target repo builds successfully

Visual:
- [ ] Component appears correctly
- [ ] Responsive behavior matches
- [ ] Theme/styling applied correctly
```

## Example Usage

```
User: Port the article navigation from docs-ui to Learn.SharedComponents

Step 1: Check workspace
→ Both repos present ✓

Step 2: Research source
→ @research Document article navigation in docs-ui
→ ⏸️ PAUSED - Review source research

Step 3: Research target  
→ @research Analyze patterns in Learn.SharedComponents
→ ⏸️ PAUSED - Review target research

Step 4: Create plan
→ @planning Create parity plan from research artifacts
→ ⏸️ PAUSED - Review plan

Step 5: Implement
→ @implementation Execute parity plan
```

