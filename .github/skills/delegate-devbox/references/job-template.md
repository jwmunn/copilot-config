# Dev Box Job Template

```markdown
---
date: {ISO 8601 timestamp}
submitter: {user alias}
status: submitted
type: devbox-job
ticket: {ticket-id or null}
repo: {repository name}
branch: {working branch}
baseRef: {base branch}
devBox:
  project: {devbox project}
  name: {devbox name}
---

# Dev Box Job: {short description}

## Task Prompt

{Original user prompt, verbatim. This is what the remote agent should implement.}

## Target Repository

- **Repo**: {repository name}
- **Clone URL**: {cloneUrlPattern with repoName substituted}
- **Base branch**: {baseRef}
- **Working branch**: {branch}

## Validation Commands

Run these after implementation, before committing:

```bash
{preCommitCommand from workflow-config.json for this repo}
```

Build command:
```bash
{buildCommand}
```

Test command:
```bash
{testCommand}
```

## Expected Outputs

1. **Branch**: Push `{branch}` to origin
2. **Pull Request**: Create ADO PR targeting `{baseRef}` with:
   - Title: `{conventional commit title}`
   - Description: Summary of changes, linked to {ticket-id} if provided
3. **Completion Handoff**: Write to `copilot-config/agent-artifacts/handoffs/{ticket-dir}/{date}_{time}_{ticket}_{description}-devbox-complete.md`

## Bootstrap Sequence

```powershell
# Clone repo if not present on Dev Box
$repoPath = '{repoBasePath}\{repoName}'
if (-not (Test-Path $repoPath)) {
    git clone '{cloneUrl}' $repoPath
}
cd $repoPath
git fetch origin
git checkout -b {branch} origin/{baseRef}
# ... implement task ...
# ... run validation ...
git add -A
git commit -m "{commit message}"
git push -u origin {branch}
az repos pr create --repository {repoName} --source-branch {branch} --target-branch {baseRef} --title "{title}" --description "{description}"
```

## Context

{Any additional context from the session: relevant file paths, patterns to follow, related tickets, plan references, etc.}
```
