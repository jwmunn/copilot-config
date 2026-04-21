---
description: Create a new git worktree and duplicate the current VS Code workspace with the worktree swapped in, optionally creating a handoff document to transfer task context to the new workspace. Use when starting work on a new branch that needs an isolated working directory mirroring your current multi-root workspace. Triggers on "create worktree", "new worktree", "set up worktree", "worktree for branch".
---

# Create Worktree

Create a new git worktree, authenticate with Azure, install dependencies, and duplicate the current VS Code workspace — replacing the target repo folder with the new worktree while preserving all other workspace folders and settings.

## Configuration

Load from `copilot-config/.github/config/workflow-config.json`:

- `git.worktreeLocation`: Where to place the worktree (default: `sibling` — next to the repo root)
- `git.worktreeNamingPattern`: Naming pattern (default: `{repoName}-wt-{worktreeName}`)

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| branch | Yes | Branch name to check out (e.g., `alias/my-feature`) |
| worktree-name | No | Custom name for the worktree directory. Defaults to the branch name slug |
| base-ref | No | Base ref to create the branch from (default: `origin/main` or repo's `defaultBranch`) |
| workspace-name | No | Custom name for the new `.code-workspace` file. Defaults to the worktree naming pattern |
| task-prompt | No | The original task or prompt to hand off to the new workspace session. If provided (or if the user included task context beyond the worktree parameters), creates a worktree handoff document so work can be resumed immediately in the new workspace |

## Process

### 1. Determine Repository

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename $REPO_ROOT)
```

Match against `repositories` in config to find the correct `defaultBranch`.

### 2. Determine Worktree Path

Compute the worktree path based on config:

- **sibling**: `../` relative to repo root
- Apply `worktreeNamingPattern`, replacing `{repoName}` and `{worktreeName}`
- Example: `../Learn.SharedComponents-wt-my-feature`

### 3. Create Worktree

Check if the branch already exists locally, remotely, or needs to be created:

```bash
# If local branch exists
git worktree add <worktree-path> <branch>

# If remote branch exists
git worktree add --track -b <branch> <worktree-path> origin/<branch>

# If new branch
git worktree add -b <branch> <worktree-path> <base-ref>
```

### 4. Authenticate and Install

Run these commands **in the new worktree directory**:

```bash
cd <worktree-path>
vsts-npm-auth -F -C .npmrc
npm i
```

### 5. Link Copilot Agents

Create a junction/symlink so agents are discoverable when the active file is in the new worktree:

```bash
# Ensure .github directory exists in the worktree
mkdir -p <worktree-path>/.github

# Windows (junction)
cmd /c mklink /J "<worktree-path>\.github\agents" "<copilot-config-path>\.github\agents"

# macOS/Linux (symlink)
ln -s <copilot-config-path>/.github/agents <worktree-path>/.github/agents
```

Where `<copilot-config-path>` is resolved relative to the worktree (typically `../copilot-config`).

Skip this step if `.github/agents` already exists.

### 6. Duplicate Current Workspace

Instead of creating a minimal workspace, duplicate the **current** VS Code workspace file, replacing the target repo's folder entry with the new worktree path.

#### 6a. Find the Current Workspace File

Locate the active `.code-workspace` file. Use one of these strategies (in order):

1. **Search for `.code-workspace` files** in the parent directory of the repo root:
   ```bash
   find "$(dirname "$REPO_ROOT")" -maxdepth 1 -name "*.code-workspace" -type f
   ```
2. **Ask the user** if multiple workspace files are found or none are discovered.

If no workspace file is found, fall back to creating a new one (see Fallback below).

#### 6b. Read and Duplicate

Read the current workspace JSON file. It will contain a `folders` array and optional `settings`, `extensions`, `launch`, `tasks`, etc.

Example current workspace:
```json
{
  "folders": [
    { "path": "Learn.SharedComponents" },
    { "path": "docs-ui" },
    { "path": "Learn.Rendering.Preview" },
    { "path": "copilot-config" }
  ],
  "settings": { ... },
  "extensions": { ... }
}
```

#### 6c. Replace the Target Repo Folder

Find the folder entry whose `path` matches or ends with `REPO_NAME`. Replace it with the worktree path (relative to the workspace file location):

```json
// Before
{ "path": "Learn.SharedComponents" }

// After
{ "path": "Learn.SharedComponents-wt-my-feature" }
```

All other folder entries, `settings`, `extensions`, `launch`, `tasks`, and any other keys are **preserved exactly as-is**.

#### 6d. Write the New Workspace File

Write the modified workspace JSON to a new file. The filename uses the `workspace-name` parameter if provided, otherwise derives from the worktree naming pattern:

```bash
WORKTREE_NAME=$(basename <worktree-path>)
# Use workspace-name param if provided, else default to worktree name
WORKSPACE_NAME="${WORKSPACE_NAME_PARAM:-$WORKTREE_NAME}"
# Place the new workspace file next to the original
WORKSPACE_FILE="$(dirname "$ORIGINAL_WORKSPACE")/${WORKSPACE_NAME}.code-workspace"
```

Write the file with pretty-printed JSON (2-space indent).

#### 6e. Fallback — No Existing Workspace

If no current workspace file is found, create a new one with the worktree folder and copilot-config:

```json
{
  "folders": [
    { "path": "<worktree-relative-path>" },
    { "path": "copilot-config" }
  ],
  "settings": {}
}
```

Place it in the same parent directory as the worktree.

### 7. Create Worktree Handoff (if task context exists)

If the user provided a `task-prompt` parameter **or** included any task description, context, or instructions beyond the basic worktree parameters (branch, name, etc.), create a lightweight handoff document so work can be resumed immediately in the new workspace.

**When to create a handoff:** Always create one if the user's message contains more than just "create a worktree for branch X". For example, if they say "create a worktree for branch X to implement the rating component" — the "implement the rating component" part is the task prompt.

#### 7a. Build the Handoff Document

Create a markdown file with this structure:

```markdown
---
date: [ISO 8601 timestamp]
branch: [branch name]
repository: [repository name]
worktree_path: [absolute worktree path]
workspace_file: [workspace filename]
status: ready-to-start
type: worktree_handoff
---

# Worktree Handoff: {branch description}

## Task
{The original task/prompt from the user, preserved verbatim}

## Environment
- **Branch**: `{branch}`
- **Worktree**: `{worktree-path}`
- **Workspace**: `{workspace-file}`
- **Repository**: `{repo-name}`
- **Base ref**: `{base-ref}`

## Context
{Any additional context from the current session that's relevant — e.g., related plan files, research docs, ticket references, key file paths mentioned}

## Next Steps
1. Open this handoff with `/mslearn-resume-handoff` to continue the task
2. Or read this file and begin working on the task described above
```

#### 7b. Save the Handoff

Save to `copilot-config/agent-artifacts/handoffs/` following the standard naming convention:

```bash
# Determine ticket directory
TICKET_DIR="general"  # or CAS-XXX if a ticket is referenced

# Generate filename
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DESCRIPTION=$(echo "<worktree-name>" | tr '/' '-')
HANDOFF_FILE="copilot-config/agent-artifacts/handoffs/${TICKET_DIR}/${TIMESTAMP}_${DESCRIPTION}.md"
```

#### 7c. Skip Conditions

Skip handoff creation if:
- The user's message contains **only** worktree parameters with no task context
- The user explicitly says they don't need a handoff

### 8. Open the New Workspace

Open the workspace in VS Code. If a handoff was created, also open the handoff file so it's immediately visible:

```bash
# Without handoff
code "${WORKSPACE_FILE}"

# With handoff — open workspace and the handoff file
code "${WORKSPACE_FILE}" "${HANDOFF_FILE}"
```

### 9. Report Results

**On success (without handoff)**:

```
✅ Worktree ready at <worktree-path>
🔗 Agents linked from copilot-config
📂 Workspace duplicated: <original-workspace> → <new-workspace>.code-workspace
   Replaced: <repo-name> → <worktree-name>
   Preserved: all other folders, settings, and extensions
```

**On success (with handoff)**:

```
✅ Worktree ready at <worktree-path>
🔗 Agents linked from copilot-config
📂 Workspace duplicated: <original-workspace> → <new-workspace>.code-workspace
   Replaced: <repo-name> → <worktree-name>
   Preserved: all other folders, settings, and extensions
📋 Worktree handoff created: <handoff-file-path>

Resume in the new workspace with:
/mslearn-resume-handoff <handoff-file-path>
```

**On failure**: Show which step failed (worktree creation, auth, install, symlink, workspace duplication, or handoff creation) and suggest fixes:
- Auth failure → check VPN, re-run `vsts-npm-auth -F -C .npmrc`
- npm install failure → verify `.npmrc` exists, retry `vsts-npm-auth`
- Worktree conflict → `git worktree list` to check existing worktrees
- Symlink failure → check if `.github/agents` already exists, or run `setup-agents` manually
- Workspace duplication failure → check if the original `.code-workspace` file is valid JSON, or provide the path manually
- Handoff creation failure → non-blocking, worktree is still usable without the handoff
