---
name: prune-worktree
description: Remove git worktrees and their associated VS Code workspace files. Use when cleaning up finished branches, freeing disk space, or tearing down development environments. Triggers on "prune worktree", "remove worktree", "clean up worktrees", "tear down worktree".
---

# Prune Worktree

Remove one or more git worktrees and clean up their associated VS Code workspace files.

## Configuration

Load from `copilot-config/.github/config/workflow-config.json`:

- `git.worktreeNamingPattern`: Used to identify worktree directories (default: `{repoName}-wt-{worktreeName}`)

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| worktree | No | Specific worktree path or name to remove. If omitted, list all and prompt for selection |
| --all | No | Remove all worktrees (with confirmation) |
| --prune-only | No | Only run `git worktree prune` to clean stale entries without removing directories |

## Process

### 1. Identify Context

Determine the main worktree and current workspace:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
MAIN_WORKTREE=$(git worktree list | head -1 | awk '{print $1}')
CURRENT_DIR=$(pwd)
```

### 2. List Worktrees

```bash
git worktree list
```

Display the list to the user, excluding the main working tree (the first entry). Number each worktree for easy selection.

### 3. Select Worktrees to Remove

- If a specific worktree was provided, confirm it exists in the list
- If `--all` was specified, confirm with the user before proceeding
- Otherwise, present the list and ask which worktree(s) to remove

### 4. Detect Current Workspace Conflict

If the selected worktree is the **current workspace** (i.e., `CURRENT_DIR` is inside the worktree path):

1. **Warn the user**: "You are currently working inside this worktree."
2. **Change cwd** to the main worktree before attempting removal:
   ```bash
   cd "$MAIN_WORKTREE"
   ```
3. **Note**: The VS Code window for this workspace will become invalid after removal. Instruct the user to close the window after the operation completes.

### 5. Check for Uncommitted Changes

For each selected worktree, check for uncommitted work:

```bash
git -C <worktree-path> status --porcelain
```

If there are uncommitted changes, **warn the user** and ask for confirmation before proceeding. List the changed files.

### 6. Remove Agent Symlinks

Before removing the worktree directory, check for and remove the agents junction/symlink:

```bash
AGENTS_LINK="<worktree-path>/.github/agents"

# Check if it's a symlink/junction (not a real directory)
if [[ -L "$AGENTS_LINK" ]] || [[ -d "$AGENTS_LINK" && $(stat -c %F "$AGENTS_LINK" 2>/dev/null || stat -f %T "$AGENTS_LINK" 2>/dev/null) ]]; then
    # Windows: rmdir (junctions)
    # macOS/Linux: rm (symlinks)
    rm -f "$AGENTS_LINK" 2>/dev/null || cmd /c rmdir "$AGENTS_LINK" 2>/dev/null
fi
```

**Important**: Only remove if it's a symlink/junction — never delete a real agents directory.

### 7. Remove Worktrees

For each selected worktree:

```bash
# Remove the worktree (--force if user confirmed despite uncommitted changes)
git worktree remove <worktree-path>

# Or if the directory was already deleted
git worktree prune
```

### 8. Clean Up Workspace Files

After removing the worktree directory, find and delete the associated `.code-workspace` file:

```bash
WORKTREE_NAME=$(basename <worktree-path>)
WORKSPACE_FILE="<worktree-path>/${WORKTREE_NAME}.code-workspace"

# If the worktree directory still exists (workspace file inside it), it was removed with the directory
# If the workspace file was elsewhere, delete it explicitly
```

### 9. Clean Up Branches (Optional)

Ask the user if they also want to delete the local branch associated with the removed worktree:

```bash
git branch -d <branch-name>
```

Use `-d` (safe delete) by default. Only use `-D` (force delete) if the user explicitly confirms.

### 10. Report Results

**On success**:

```
✅ Removed worktree: <worktree-path>
🔗 Removed agents symlink
🗑️ Deleted workspace: <worktree-name>.code-workspace
🌿 Deleted branch: <branch-name> (if requested)
⚠️ Close this VS Code window (if pruning current workspace)
```

**On failure**:
- Uncommitted changes → suggest committing or stashing first
- Branch not fully merged → warn and offer `--force` with `-D`
- Stale worktree entries → run `git worktree prune`
