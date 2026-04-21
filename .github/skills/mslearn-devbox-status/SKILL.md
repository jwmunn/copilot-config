---
description: Check status of a Dev Box delegated job or resume from its completion
---

# Dev Box Job Status

Check the status of a job previously delegated to a Dev Box, or resume work from its completion handoff.

## Workflow

1. **Locate local job artifacts**: Search `copilot-config/agent-artifacts/jobs/` for the specified job ID or ticket. If no ID is given, list recent jobs and let the user pick
2. **Read local status sidecar**: Read the `-status.json` file next to the local job artifact for the last known submission state
3. **Check Dev Box remotely**: Use Dev Box MCP to verify the Dev Box is still running. Use `Run Tasks On Dev Box` to read the remote status file, check whether the bootstrap process is still active, and tail recent log output from the Dev Box's `agent-artifacts/jobs/` directory
4. **Check for completion**: Use `Run Tasks On Dev Box` to read the completion handoff from the Dev Box's `agent-artifacts/handoffs/` directory. If found, present:
   - PR URL
   - Validation result (pass/fail)
   - Branch name
   - Summary of what was implemented
5. **Offer next actions**:
   - If **completed**: Show the PR link for review. Offer to use `Run Tasks On Dev Box` to read the full completion handoff content so you can continue work locally
   - If **running**: Report progress from the remote log and offer to check again later
   - If **failed**: Use `Run Tasks On Dev Box` to read the remote log file, diagnose the failure, and offer to retry or fix locally

## Example

```
User: /mslearn-devbox-status CAS-456

Agent:
→ Reads agent-artifacts/jobs/CAS-456/2026-03-26_14-30-00_CAS-456_rating-component-status.json
→ Status: completed
→ "Dev Box job CAS-456 completed successfully.
    PR: https://dev.azure.com/ceapex/Engineering/_git/Learn.SharedComponents/pullrequest/1234
    Branch: jumunn/devbox-rating-component
    Validation: Passed
    Resume: /mslearn-resume-handoff copilot-config/agent-artifacts/handoffs/CAS-456/2026-03-26_15-45-00_CAS-456_rating-component-devbox-complete.md"
```

