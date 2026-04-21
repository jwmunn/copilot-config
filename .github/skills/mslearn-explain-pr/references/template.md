# PR Explanation Document Template

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

{2-3 sentences: what this PR accomplishes}

## Motivation

{Why was this change needed? Link to ticket if available.}

## Changes Overview

| File | Change Type | Description |
|------|-------------|-------------|
| `{file1}` | {added/modified/deleted} | {brief description} |
| `{file2}` | {added/modified/deleted} | {brief description} |

## Detailed Changes

### {Component/Area 1}

**Files**: `{path/to/file1.ts}`, `{path/to/file2.ts}`

**What was done**: {Detailed explanation}

**Why this approach**: {Architectural decisions, pattern choices, trade-offs}

**Pattern references**: Followed pattern from `{existing/file.ts:line}`

### {Component/Area 2}
...

## Architecture Decisions

### Decision 1: {Title}
**Context**: {Situation requiring a decision}
**Options**: {Options considered with pros/cons}
**Chosen**: {Which option and why}

## Pattern Compliance

### Existing Patterns Applied
- `{pattern}` — from `{reference file}`

### New Patterns Introduced
- `{pattern}` — {Why needed, where reusable}

## Testing

- `{test/file.test.ts}` — {what it tests}
- Manual verification: {steps if needed}

## Impact Analysis

- **Downstream**: {Components/consumers affected}
- **Breaking changes**: {None / list with migration guidance}

## Related Work

- {Ticket/PR references}
- {Follow-up work enabled by this PR}

## Reviewer Notes

{Areas to focus on, questions for reviewers, helpful context}
```
