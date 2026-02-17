---
date: 2026-02-17
session_id: email-to-ado-workitems
repository: copilot-config
branch: main
topic: "Email lookup via Work IQ and ADO work item creation patterns"
learnings_count: 3
applied_count: 3
status: applied
---

# Session Learnings: Email lookup via Work IQ and ADO work item creation patterns

## Session Summary

**Repository**: copilot-config (cross-repo workflow)  
**Branch**: main  
**Duration**: ~30 minutes  
**Primary task**: Look up an email by subject, create an ADO user story with the email content, and create a child dev task

## Learnings

### Learning 1: Use Work IQ MCP to search emails

- **Signal**: correction
- **Confidence**: high
- **User said**: "Use the Work IQ MCP to find the email."
- **Root cause**: No instruction file mentions `mcp_workiq_ask_work_iq` as the tool for searching emails. The agent tried Microsoft Graph Mail API (403 - no Mail.Read scope), `fetch_webpage` on Outlook URLs (failed), and Playwright browser navigation before the user corrected it.

**Target file**: `.github/instructions/azure-devops-workitems.instructions.md`  
**Change type**: context

**Suggested patch**:
```diff
  ## Artifact Links
  
  Use `mcp_microsoft_azu_wit_add_artifact_link` to link work items to branches, commits, builds, or PRs:
  - **workItemId**: `<id>`
  - **project**: `{project}`
  - **linkType**: `Branch` | `Fixed in Commit` | `Pull Request` | `Build`
  - Plus the relevant identifier (`branchName`, `commitId`, `pullRequestId`, `buildId`)
  
  ````
+ 
+ ````instructions
+ # Email and Communication Lookup
+ 
+ ## Finding Emails
+ 
+ When you need to search for or retrieve email content, use the **Work IQ MCP** tool:
+ 
+ ```
+ mcp_workiq_ask_work_iq
+ ```
+ 
+ - Pass a natural language question describing the email (subject, sender, date, etc.)
+ - Work IQ can search across Outlook emails and return full body content, sender, recipients, and date
+ - **Do NOT** attempt Microsoft Graph Mail API (`/v1.0/me/messages`) — Mail.Read scope is not authorized
+ - **Do NOT** attempt `fetch_webpage` on Outlook URLs — requires authentication
+ - **Do NOT** attempt Playwright browser navigation to Outlook — cancelled/blocked
+ 
+ ### Example
+ 
+ ```
+ mcp_workiq_ask_work_iq(question="Find the email with subject 'Rendering issue for Course page' and return the full body content, sender, date, and recipients")
+ ```
+ 
+ ### Note on EULA
+ 
+ Work IQ may require EULA acceptance on first use. If prompted, call `mcp_workiq_accept_eula` first.
+ ````
```

**Rationale**: The agent wasted 4+ tool calls trying incorrect approaches. Adding explicit guidance about Work IQ for email lookup prevents this in every future session that involves email content.

---

### Learning 2: Omit IterationPath when creating work items (use ADO default)

- **Signal**: workaround
- **Confidence**: high
- **User said**: (no explicit correction — agent self-corrected after API error)
- **Root cause**: The `workflow-config.json` sets `iteration` to `{adoAreaPath}` (same as area path), but the iteration tree in ADO doesn't have a matching node at `Engineering\POD\Xinxin-OctoPod`. The first `create_work_item` call failed with `TF401347: Invalid tree name`. The workaround was to omit `System.IterationPath` entirely and let ADO default it to `Engineering`.

**Target file**: `.github/instructions/azure-devops-workitems.instructions.md`  
**Change type**: guard

**Suggested patch**:
```diff
  ## Creating User Stories
  
  Use the work item creation tool with:
  - **project**: `{project from config}`
  - **type**: `User Story`
  - **title**: `<title>`
  - **assignedTo**: `{adoAssignee from config}`
  - **areaPath**: `{areaPath from config}`
- - **iterationPath**: `{iteration from config}`
+ - **iterationPath**: `{iteration from config}` ⚠️ **If this fails with TF401347, omit iterationPath and let ADO use the default iteration. The configured iteration path may not exist as a valid iteration node.**
  - **description**: `<description HTML>`
```

and similarly for Task creation:

```diff
  ## Creating Dev Tasks (Unassigned)
  
  Use the work item creation tool with:
  - **project**: `{project from config}`
  - **type**: `Task`
  - **title**: `<title>`
  - **areaPath**: `{areaPath from config}`
- - **iterationPath**: `{iteration from config}`
+ - **iterationPath**: `{iteration from config}` ⚠️ **If this fails with TF401347, omit iterationPath and let ADO use the default iteration.**
```

**Rationale**: The iteration path in `workflow-config.json` maps to the area path, which may not be a valid iteration. This guard prevents a wasted API call and immediate retry on every work item creation.

---

### Learning 3: No GitHub PR MCP tool for private repos

- **Signal**: missing-context
- **Confidence**: medium
- **User said**: "It's a private repo. Is there MCP we can use to check?"
- **Root cause**: The user asked to look up a PR on a private GitHub repo (`MicrosoftDocs/learn-certs-pr#9652`). The agent tried `fetch_webpage` (404), `github_repo` (code-only), and ADO repo tools (wrong platform). None of the available MCP tools can access GitHub PRs on private repos. The `github_repo` tool only searches code snippets, not PR metadata.

**Target file**: `.github/copilot-instructions.md`  
**Change type**: guard

**Suggested patch**:
```diff
+ ## Tool Guidance — Common Pitfalls
+
+ | Scenario | What to do |
+ |----------|------------|
+ | GitHub URL returns 404 | The repo may be private. Prompt the user: "This returned a 404 — is this a private repo? If so, I don't have a GitHub PR MCP tool for private repos. Could you check the PR directly and share the details?" |
+ | Need to search emails | Use `mcp_workiq_ask_work_iq` (see ADO work item instructions for details) |
+ | ADO work item iteration fails (TF401347) | Omit `iterationPath` and let ADO default it |
+
  ## Execution Architecture
```

**Rationale**: Instead of documenting a permanent gap, prompt the user when a GitHub URL 404s so they can confirm it's private and assist.

---

## Applied Changes

| # | Learning | Target File | Status |
|---|---------|-------------|--------|
| 1 | Use Work IQ MCP for email lookup | `.github/instructions/azure-devops-workitems.instructions.md` | applied |
| 2 | Omit IterationPath on TF401347 error | `.github/instructions/azure-devops-workitems.instructions.md` | applied |
| 3 | Prompt user on GitHub 404 (private repo) | `.github/copilot-instructions.md` | applied |

## Meta

- **Generalizability**: Learning 1 (Work IQ for email) is broadly applicable to any session needing email content. Learning 2 (iteration path) applies to all ADO work item creation. Learning 3 (GitHub PR gap) is a permanent platform limitation.
- **Related learnings**: None found in existing learnings directory.
- **Follow-up**: Consider updating `workflow-config.json` to set `iteration` to a valid iteration path (e.g., `Engineering`) instead of mapping it to the area path.
