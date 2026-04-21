---
description: Delegate a task to a remote Dev Box for unattended execution via the Dev Box MCP. Use when you want work to continue running while you are away from your machine — the Dev Box will implement the task, validate it, push a branch, create an ADO PR, and leave a completion handoff. Triggers on "delegate to devbox", "run on devbox", "delegate devbox", "background task", "unattended implementation".
---

# Delegate Task to Dev Box

Package the current task as a structured job, start the target Dev Box via MCP, and run the implementation remotely so it completes independently of the local session.

## Configuration

Load from `copilot-config/.github/config/workflow-config.json`:

- `devBox.project`, `devBox.name`, `devBox.userId` — target Dev Box identity
- `devBox.repoBasePath` — base directory where repos live on the Dev Box (e.g., `C:\repos\mslearn`)
- `devBox.cloneUrlPattern` — ADO clone URL template used if a repo is missing on the Dev Box (e.g., `https://{orgName}@{domain}/{orgName}/{project}/_git/{repoName}`)
- `azureDevOps.domain`, `azureDevOps.orgName`, `azureDevOps.project` — used to resolve clone URLs
- Repository-specific `defaultBranch`, `buildCommand`, `testCommand`, `preCommitCommand`

The **repo name** comes from the user's prompt (the `repo` parameter). The full repo path on the Dev Box is `{repoBasePath}\{repoName}`. Artifact paths are derived as `{repoBasePath}\copilot-config\agent-artifacts`.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| task-prompt | Yes | The implementation prompt to execute remotely |
| repo | Yes | Target repository name (must exist in `workflow-config.json` repositories) |
| branch | No | Working branch name. Defaults to `{alias}/devbox-{description}` |
| base-ref | No | Base ref to branch from. Defaults to repo's `defaultBranch` |
| devbox-project | No | Dev Box project override. Defaults to `devBox.project` from config |
| devbox-name | No | Dev Box name override. Defaults to `devBox.name` from config |
| ticket-id | No | ADO ticket ID for artifact organization (e.g., `CAS-123`) |

## Process

### 1. Resolve Configuration

1. Read `copilot-config/.github/config/workflow-config.json`
2. Match `repo` parameter against `repositories` keys and aliases
3. Resolve Dev Box target from parameters or config defaults
4. Compute working branch name if not provided

### 2. Create Job Artifact

Write a structured job file to `copilot-config/agent-artifacts/jobs/{ticket-dir}/{filename}.md` where:

- **ticket-dir**: `CAS-XXX` if ticket-id provided, otherwise `general`
- **filename**: `{date}_{time}_{ticket}_{description}-job.md`

Use the template in [references/job-template.md](references/job-template.md). The job artifact must include:

- Original task prompt (verbatim)
- Target repository and branch details
- Repo-specific validation commands from config
- Expected outputs (branch push, PR creation, completion handoff)
- Bootstrap command sequence

### 3. Ensure Dev Box Is Running

Use the Dev Box MCP tools:

1. **Check status**: Read the Dev Box resource at `/projects/{project}/users/{userId}/devboxes/{name}` (operation: `read`)
2. **Start if needed**: If the Dev Box is stopped, use the DevBox Action at `/projects/{project}/users/{userId}/devboxes/{name}` (action: `start`)
3. **Wait for ready**: Poll operation status until the Dev Box is running
4. **Get connection info**: Use action `getRemoteConnection` to verify connectivity

### 4. Write Job Artifact to Dev Box

Use the Dev Box MCP `Run Tasks On Dev Box` to write the job artifact directly on the Dev Box. The artifact path is derived from config: `{repoBasePath}\copilot-config\agent-artifacts\jobs\{ticket-dir}\{filename}.md`

```powershell
$jobContent = @'
{full job artifact markdown content}
'@
$artifactDir = '{repoBasePath}\copilot-config\agent-artifacts\jobs\{ticket-dir}'
New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
Set-Content -Path "$artifactDir\{filename}.md" -Value $jobContent -Encoding UTF8
```

### 4a. Ensure Target Repo Exists on Dev Box

Use the Dev Box MCP `Run Tasks On Dev Box` to check if the repo exists and clone it if missing:

```powershell
$repoPath = '{repoBasePath}\{repoName}'
if (-not (Test-Path $repoPath)) {
    git clone '{cloneUrlPattern}' $repoPath
}
```

Where `{cloneUrlPattern}` is resolved from `devBox.cloneUrlPattern` with `{repoName}` substituted (e.g., `https://ceapex@dev.azure.com/ceapex/Engineering/_git/docs-ui`).

### 5. Bootstrap Remote Execution

Use the Dev Box MCP `Run Tasks On Dev Box` to launch the unattended implementation. The bootstrap must start a durable process that survives the MCP connection ending:

```powershell
# Launch the job runner as a detached process on the Dev Box
Start-Process powershell -ArgumentList '-NoProfile', '-File', '{repoBasePath}\copilot-config\.github\skills\delegate-devbox\references\run-devbox-job.ps1', '-JobPath', '{jobArtifactPath}', '-ConfigPath', '{repoBasePath}\copilot-config\.github\config\workflow-config.json' -WindowStyle Hidden
```

The bootstrap script handles:
1. Navigate to the target repo on the Dev Box
2. Fetch latest and create/checkout the working branch
3. Read the job artifact for the task prompt and validation commands
4. Execute the implementation (via `copilot` CLI or Copilot coding agent)
5. Run repo-specific validation (`preCommitCommand` from config)
6. Stage, commit, and push the branch
7. Create an ADO pull request using `az repos pr create`
8. Write a completion handoff and status files locally on the Dev Box (gitignored)

### 6. Record Local Job State

Write a job status sidecar file next to the job artifact (`{filename}-status.json`):

```json
{
  "jobId": "{filename stem}",
  "status": "submitted",
  "devBox": "{project}/{name}",
  "repo": "{repo}",
  "branch": "{branch}",
  "submittedAt": "{ISO 8601}",
  "jobArtifactPath": "{path}",
  "completionHandoffPath": null,
  "prUrl": null
}
```

Status values: `submitted` → `devbox-starting` → `running` → `completed` | `failed`

### 7. Confirm Submission

Output to the user:

- Job artifact path
- Dev Box name and project
- Target repo, branch, and base ref
- Expected completion artifact path
- Command to check status later: `/mslearn-devbox-status {jobId}`

## Dev Box Prerequisites

The target Dev Box **must** already have:

- Azure DevOps authentication (`az login`, Git credential manager)
- `copilot-config` cloned at `{repoBasePath}/copilot-config`
- Repo-specific toolchains (Node.js/npm, .NET SDK, etc.)
- Azure CLI with `azure-devops` extension (for `az repos pr create`)
- GitHub Copilot CLI or coding agent (for unattended implementation)

**Note**: The target repo does NOT need to be pre-cloned — the bootstrap will clone it automatically using the `cloneUrlPattern` from config if it is missing.

## Limitations

- The remote implementation quality depends on the Copilot CLI/coding agent capabilities on the Dev Box
- Complex multi-repo tasks should be split into single-repo delegations
- The Dev Box must remain running until the job completes — use `Schedule Resource` to delay/skip auto-shutdown if needed
