---
description: Explain what was done in a PR branch with research-style documentation
mode: agent
---

# Explain PR Workflow

Generate comprehensive documentation explaining what was done in a PR branch, similar to research document format. This helps reviewers, future maintainers, and stakeholders understand the changes in context.

## When to Use

- Before submitting a PR for review (self-documentation)
- When onboarding reviewers to complex changes
- Creating documentation for significant features
- Explaining architectural decisions in a PR

## Configuration

Load from `copilot-config/.github/config/workflow-config.json`:
- Repository settings
- Artifact naming patterns

## Process

### Step 1: Identify PR Context

```
Explain PR request received.

Options:
1. Current branch (explain local changes)
2. Branch name (compare against default)
```

### Step 2: Gather Changed Files

```bash
# Get default branch from config
DEFAULT_BRANCH={from config or 'main'}

# Show changed files
git diff origin/$DEFAULT_BRANCH...HEAD --name-only

# Get full diff for analysis
git diff origin/$DEFAULT_BRANCH...HEAD
```

### Step 3: Analyze Changes

For each changed file:
1. **Read the file** to understand the full context
2. **Identify the purpose** of changes in that file
3. **Find related patterns** - what existing code influenced this
4. **Note architectural decisions** - why was this approach chosen

### Step 4: Gather Metadata

```bash
# Get current branch name
git branch --show-current

# Get commit history for this branch
git log origin/$DEFAULT_BRANCH..HEAD --oneline

# Get user info
git config user.name
git config user.email
```

### Step 5: Generate PR Explanation Document

Create artifact at: `copilot-config/agent-artifacts/reviews/{date}-{branch}-explain.md`

Structure the document:

```markdown
---
date: {ISO timestamp}
author: {from git config}
branch: {branch name}
repository: {repo name}
base_branch: {default branch}
files_changed: {count}
type: pr-explanation
status: complete
---

# PR Explanation: {Branch Name}

**Date**: {Current date and time}
**Author**: {Author name}
**Branch**: `{branch}` → `{default branch}`
**Repository**: {Repository name}

## Summary

{High-level summary of what this PR accomplishes - 2-3 sentences describing the feature/fix/change}

## Motivation

{Why was this change needed? Link to ticket if available}

## Changes Overview

| File | Change Type | Description |
|------|-------------|-------------|
| `{file1}` | {added/modified/deleted} | {brief description} |
| `{file2}` | {added/modified/deleted} | {brief description} |

## Detailed Changes

### {Component/Area 1}

**Files involved**:
- `{path/to/file1.ts}` - {role in this component}
- `{path/to/file2.ts}` - {role in this component}

**What was done**:
{Detailed explanation of the changes in this component}

**Why this approach**:
{Explanation of architectural decisions, pattern choices, trade-offs}

**Pattern references**:
- Followed pattern from `{existing/file.ts:line}` - {what pattern}

### {Component/Area 2}
...

## Architecture Decisions

### Decision 1: {Decision Title}
**Context**: {What situation required a decision}
**Options considered**:
1. {Option A} - {pros and cons}
2. {Option B} - {pros and cons}

**Chosen approach**: {Which option and why}

## Pattern Compliance

### Existing Patterns Applied
- `{pattern name}` - Followed example from `{reference file}`
- `{pattern name}` - Extended existing implementation in `{reference file}`

### New Patterns Introduced
- `{pattern name}` - {Why a new pattern was needed and where it can be reused}

## Testing

### Test Coverage
- `{test/file1.test.ts}` - {what it tests}
- `{test/file2.test.ts}` - {what it tests}

### Manual Testing Notes
{Any manual testing steps or verification needed}

## Impact Analysis

### Files Affected
{List of direct changes}

### Downstream Impact
{Any components, services, or consumers affected by these changes}

### Breaking Changes
{None / List of breaking changes with migration guidance}

## Related Work

### Related PRs/Tickets
- {Ticket/PR reference} - {relationship}

### Future Work
- {Any follow-up work enabled or required by this PR}

## Reviewer Notes

{Special areas to pay attention to, questions for reviewers, or context that would help the review}
```

### Step 6: Present Explanation

```
PR Explanation complete for: {branch}

📄 Summary: {brief summary}

📊 Stats:
- Files changed: {count}
- Lines added: +{count}
- Lines removed: -{count}

🔗 Key changes:
- {Component 1}: {brief description}
- {Component 2}: {brief description}

📝 Explanation document: `copilot-config/agent-artifacts/reviews/{filename}`

Would you like me to:
1. Add more detail to any section
2. Generate a shorter PR description for the PR itself
3. Identify additional pattern references
```

## Quick Commands

### Explain current branch
```
/explain-pr
```

### Generate with specific focus
```
/explain-pr --focus architecture
/explain-pr --focus testing
/explain-pr --focus patterns
```

## Integration with Review Workflow

The explain document complements the review process:

```
1. /explain-pr        # Document what you did
2. /review-it          # Get feedback on the changes
3. Fix issues          # Address any review feedback
4. /ship-it            # Push and create PR
```

## Important Guidelines

1. **Be comprehensive** - Include enough context for someone unfamiliar with the changes
2. **Explain "why"** - Not just what changed, but why that approach was chosen
3. **Reference patterns** - Show how changes relate to existing codebase patterns
4. **Include trade-offs** - Document alternatives considered
5. **Think about future** - Help future maintainers understand the code

