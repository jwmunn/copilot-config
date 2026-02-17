---
description: Create a git worktree with Azure auth, npm install, and agent symlinks
agent: mslearn-implementation
model: Claude Opus 4.6 (fast mode) (Preview) (copilot)
---

# Create Worktree

Create a new git worktree for isolated branch development, fully set up with authentication and dependencies.

## Instructions

Follow the skill instructions in `copilot-config/.github/skills/create-worktree/SKILL.md`.

## Workflow

1. Identify the current repository and determine the worktree path from config
2. Create the worktree (handle existing local/remote branches or create new)
3. Authenticate with Azure and install npm dependencies in the new worktree
4. Link copilot agents via symlink/junction so they're discoverable in the worktree
5. Duplicate the current VS Code `.code-workspace` file, replacing the target repo folder with the worktree path while preserving all other folders, settings, and extensions
6. Open the new workspace and report results
