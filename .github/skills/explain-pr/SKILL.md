---
name: explain-pr
description: Generate comprehensive documentation explaining what was done in a PR branch, including change analysis, architectural decisions, pattern compliance, and impact assessment. Use when a user wants to document a PR before review, onboard reviewers to complex changes, create feature documentation, or explain architectural decisions. Triggers on "explain PR", "explain this branch", "document PR changes", "what did this PR do".
---

# Explain PR

Generate a research-style document explaining the changes in a PR branch — what was done, why, and how it fits the codebase.

## Configuration

Load from `copilot-config/.github/config/workflow-config.json`:

- Repository settings (default branch, type)
- Artifact naming patterns

## Process

### 1. Identify Context

Determine the branch to explain:
- Current branch (default) — compare against repo's default branch
- Specified branch name — compare against default

### 2. Gather Changes

```bash
DEFAULT_BRANCH={from config}
git diff origin/$DEFAULT_BRANCH...HEAD --name-only
git diff origin/$DEFAULT_BRANCH...HEAD
git log origin/$DEFAULT_BRANCH..HEAD --oneline
git branch --show-current
```

### 3. Analyze Each Changed File

For each file:
1. Read the full file for context
2. Identify the purpose of changes
3. Find related patterns in existing code
4. Note architectural decisions and trade-offs

### 4. Generate Document

Create artifact at `copilot-config/agent-artifacts/reviews/{date}-{branch}-explain.md` using the template in [references/template.md](references/template.md).

### 5. Present Summary

Output a brief summary with:
- File count, lines added/removed
- Key changes by component
- Path to the generated document
- Options: add detail, generate short PR description, find more pattern references

## Integration

Complements the review workflow:
1. `/explain-pr` → Document what you did
2. `/review-it` → Get feedback
3. Fix issues → Address review feedback
4. `/ship-it` → Push and create PR
