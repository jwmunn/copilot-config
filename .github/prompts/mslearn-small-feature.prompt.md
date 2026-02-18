---
description: Quick workflow for small, well-defined features - analyze and implement in one session
agent: mslearn-implementation
model: Claude Opus 4.6 (fast mode) (Preview) (copilot)
---

# Small Feature Workflow

Streamlined workflow for implementing small, well-scoped features in a single session.

## When to Use

- Feature scope is clear and bounded
- Single repository impact
- Estimated time: < 2 hours
- No cross-team dependencies

## Process

### Step 1: Quick Context Scan

First, understand what we're building:

```
Small feature request: {user's description}

Quick analysis:
- Repository: {identify from description}
- Scope: {estimate}
- Patterns needed: {what to look for}
```

Use search tools directly to find relevant files quickly:
- `semantic_search` for conceptually similar functionality
- `grep_search` for exact patterns, imports, and references
- `read_file` on the most relevant matches to understand patterns to follow

### Step 2: Mini-Plan (Mental Model)

Before coding, outline the approach:
```
Implementation approach:
1. Modify `{file1}` to add {change}
2. Update `{file2}` to support {change}
3. Verify with {command from config}

Pattern reference: `{existing_file:line}`
```

### Step 3: Implement

Make changes following discovered patterns:
- Read each file before modifying
- Make precise edits
- No placeholder comments

### Step 4: Verify

Run quality checks from config:

```bash
# Get pre-commit command for this repo from workflow-config.json
{preCommitCommand}
```

Ensure:
- [ ] Build passes
- [ ] No new lint errors
- [ ] No type errors
- [ ] Existing tests pass

### Step 5: Summary

Provide completion summary:
```
✅ Feature complete: {description}

Changes made:
- `{file1:line}` - {change}
- `{file2:line}` - {change}

Verified with:
- {build command}: ✅
- {test command}: ✅

Ready for commit. Run `/ship-it` to push and create PR.
```

## Configuration Reference

Load from `copilot-config/.github/config/workflow-config.json`:
- Repository-specific build commands
- Pre-commit quality checks
- Branch naming patterns

## Tips

- If scope grows during implementation, stop and switch to `/large-feature`
- If blocked by unclear requirements, ask rather than assume
- If pattern matching is complex, run parallel `grep_search` queries to find multiple examples

