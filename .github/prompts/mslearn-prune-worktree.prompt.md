---
description: Remove git worktrees, workspace files, agent symlinks, and optionally local branches
agent: mslearn-implementation
model: Claude Opus 4.6 (fast mode) (Preview) (copilot)
---

# Prune Worktree

Clean up one or more git worktrees and their associated resources.

## Instructions

Follow the skill instructions in `copilot-config/.github/skills/mslearn-prune-worktree/SKILL.md`.

## Workflow

1. List all worktrees (excluding the main working tree)
2. Present a numbered list and ask the user which to remove (support multi-select)
3. Detect if any selected worktree is the current workspace — warn and handle accordingly
4. Check for uncommitted changes and warn before proceeding
5. Remove agent symlinks, worktree directories, workspace files, and optionally branches
6. Report results with clear status per worktree
