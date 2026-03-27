---
description: Delegate a task to a remote Dev Box for unattended execution
agent: mslearn-implementation
model: Claude Opus 4.6 (fast mode) (Preview) (copilot)
---

# Delegate Task to Dev Box

Delegate work to a remote Dev Box so it runs unattended while you are away. The Dev Box will implement the task, validate it, push the branch, create an ADO PR, and leave a completion handoff.

## Instructions

Follow the skill instructions in `copilot-config/.github/skills/delegate-devbox/SKILL.md`.

## Workflow

1. **Collect parameters**: Identify the target repo, task prompt, branch name, and ticket ID from the user's message. Infer defaults from the current session context (active repo, current branch naming conventions)
2. **Resolve Dev Box target**: Load config from `workflow-config.json`. Use parameters or defaults for project/name. If no Dev Box is configured, ask the user
3. **Create job artifact locally**: Write a structured job file to `agent-artifacts/jobs/` using the template in `delegate-devbox/references/job-template.md`. This stays local (gitignored) for your reference
4. **Ensure Dev Box is running**: Use Dev Box MCP to check status and start the box if needed. Use `getRemoteConnection` to verify it is reachable
5. **Delay auto-shutdown**: If the Dev Box has scheduled actions (auto-shutdown), use Dev Box MCP Schedule Resource to delay or skip them so the job has time to complete
6. **Write job artifact to Dev Box**: Use Dev Box MCP `Run Tasks On Dev Box` to write the job file directly on the Dev Box at the configured `artifactSyncPath`
7. **Launch remote job**: Use Dev Box MCP `Run Tasks On Dev Box` to start the bootstrap script (`run-devbox-job.ps1`) as a detached process. This ensures the job survives the local session ending
8. **Record local job state**: Write a status sidecar JSON file next to the local job artifact
9. **Confirm submission**: Report the job ID, Dev Box target, expected PR branch, and the command to check status later: `/mslearn-devbox-status`

## Example

```
User: /mslearn-delegate-devbox
      Implement the rating component in Learn.SharedComponents following the pattern
      in LearnArticle. Add tests and export from index.ts. Ticket CAS-456.

Agent:
→ Creates local job artifact: agent-artifacts/jobs/CAS-456/2026-03-26_14-30-00_CAS-456_rating-component-job.md
→ Starts Dev Box via MCP
→ Delays auto-shutdown schedule
→ Writes job artifact to Dev Box via MCP
→ Launches bootstrap on Dev Box
→ Reports: "Job submitted to Dev Box 'MyDevBox' in project 'MSLearn'.
            Branch: jumunn/devbox-rating-component
            Check status: /mslearn-devbox-status CAS-456"
```
