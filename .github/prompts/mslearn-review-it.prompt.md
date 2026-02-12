---
description: Review a PR branch and provide structured feedback
mode: agent
---

# Review It Workflow

Review a pull request branch and provide structured feedback based on repository patterns and standards.

## When to Use

- Reviewing PRs before approval
- Getting AI-assisted code review
- Checking for pattern compliance

## Configuration

Load from `copilot-config/.github/config/workflow-config.json`:
- Repository settings
- Build/test commands

## Process

### Step 1: Identify PR Context

```
Review request received.

Options:
1. Current branch (review local changes)
2. PR number (fetch and review)
3. Branch name (compare against default)
```

### Step 2: Get Changes

For current branch:
```bash
# Get default branch from config
DEFAULT_BRANCH={from config or 'main'}

# Show changed files
git diff origin/$DEFAULT_BRANCH...HEAD --name-only

# Get full diff
git diff origin/$DEFAULT_BRANCH...HEAD
```

For PR number:
```bash
# Fetch PR changes
az repos pr show --id {PR_NUMBER} --org https://dev.azure.com/ceapex

# Get diff
az repos pr diff --id {PR_NUMBER} --org https://dev.azure.com/ceapex
```

### Step 3: Invoke Code Review Agent

```
@code-review

Branch: {branch name}
Changed files: {list}
Repository: {repo name}

Focus areas:
- Pattern compliance with existing code
- Potential issues or bugs
- Accessibility (for UI changes)
- Security considerations
```

### Step 4: Present Review

The **code-review** agent produces a structured review at:
`copilot-config/agent-artifacts/reviews/{date}-{pr}-review.md`

Summary output:
```
Review complete for: {branch/PR}

📊 Summary:
- Critical issues: {count}
- Major issues: {count}
- Minor issues: {count}
- Nits: {count}

🔴 Critical (must fix):
{list if any}

🟠 Major (should fix):
{list if any}

✅ What's done well:
{positive notes}

Full review: copilot-config/agent-artifacts/reviews/{filename}

Would you like me to:
1. Explain any issue in detail
2. Show pattern examples for fixes
3. Generate PR comment with feedback
```

### Step 5: Generate PR Comment (Optional)

If requested, format review for PR comment:
```markdown
## Code Review Summary

### Issues Found

#### Must Fix
- [ ] `file.ts:45` - {issue description}

#### Should Fix
- [ ] `file.ts:78` - {issue description}

#### Suggestions
- `file.ts:90` - {suggestion}

### What's Good
- {positive note}

### Testing Notes
- Verify at: {preview URL}
```

## Quick Review Commands

### Review current branch
```
/review-it
```

### Review specific PR
```
/review-it PR-{number}
```

### Review with focus area
```
/review-it --focus accessibility
/review-it --focus security
/review-it --focus performance
```

## Integration with Ship-It

Before shipping, consider running review:
```
1. /explain-pr         # Document what you did (optional, but recommended)
2. /review-it          # Get feedback
3. Fix issues          # Address feedback
4. /ship-it            # Push and create PR
```

### Using /explain-pr

The `/explain-pr` prompt generates comprehensive documentation about what was done in the PR, similar to research documents. This is useful for:
- Self-documenting complex changes before review
- Helping reviewers understand the context quickly
- Creating a record of architectural decisions

The explain document is saved to: `copilot-config/agent-artifacts/reviews/{date}-{branch}-explain.md`

### Pattern Reuse Analysis

The review process now includes **Pattern Reuse Analysis** which:
- Searches the codebase for existing patterns that should be applied
- Identifies potential duplicate code being introduced
- Highlights reusable utilities that could simplify the PR
- Suggests existing components that could be extended instead of creating new ones

This helps ensure the codebase maintains consistency and avoids unnecessary duplication.

