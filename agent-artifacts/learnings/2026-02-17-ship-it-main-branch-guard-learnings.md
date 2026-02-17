---
date: 2026-02-17
session_id: ship-it-copilot-config
repository: copilot-config
branch: jumunn/update-skill-descriptions
topic: "Ship-it workflow pushed directly to main instead of creating a PR"
learnings_count: 3
applied_count: 3
status: applied
---

# Session Learnings: Ship-it Main Branch Guard

## Session Summary

**Repository**: copilot-config  
**Branch**: jumunn/update-skill-descriptions  
**Duration**: ~30 minutes  
**Primary task**: Ship changes from copilot-config using /mslearn-ship-it workflow

## Learnings

### Learning 1: Never push directly to default branch — enforce as hard block

- **Signal**: correction
- **Confidence**: high
- **User said**: "Don't ever ship to main, revert that change and open a PR"
- **Root cause**: The ship-it prompt has a check in Step 4 ("Ensure we're not on default branch") but the agent offered "Push directly to main" as an option when it detected the user was on main with an unpushed commit. The agent then executed the push when the user selected it. The prompt's guard was treated as advisory rather than mandatory.

**Target file**: `.github/prompts/mslearn-ship-it.prompt.md`  
**Change type**: guard

**Suggested patch**:
```diff
  ### Step 4: Push Branch
  
  ```bash
  # Get default branch from config (main or develop for docs-ui)
  DEFAULT_BRANCH={from config}
  
  # Ensure we're not on default branch
  if [ "$BRANCH" = "$DEFAULT_BRANCH" ]; then
      echo "Error: Cannot ship from $DEFAULT_BRANCH. Create a feature branch first."
      exit 1
  fi
+ ```
+ 
+ **⛔ HARD BLOCK**: If the current branch IS the default branch, you MUST:
+ 1. Create a feature branch using the naming pattern from config: `{alias}/{description}`
+ 2. Move the unpushed commit(s) to the new branch
+ 3. Reset the default branch to match origin
+ 4. Continue the workflow on the feature branch
+ 
+ **NEVER offer "push directly to main/develop" as an option.** This is not negotiable, even for config-only repos.
+ 
+ ```bash
  # Push to origin
  git push -u origin $BRANCH
  ```
```

**Rationale**: The existing conditional check was correctly coded but not enforced as a hard block in the prompt instructions. Adding explicit "NEVER" language and a recovery procedure ensures the agent creates a feature branch instead of offering to push directly.

---

### Learning 2: copilot-config repo missing from workflow-config.json

- **Signal**: missing-context
- **Confidence**: medium
- **User said**: (implicit — the agent didn't know copilot-config uses GitHub instead of ADO for PRs)
- **Root cause**: The `repositories` section of `workflow-config.json` lists docs-ui, Learn.SharedComponents, Docs.ContentService, and Learn.Rendering.Preview but not copilot-config. This caused the agent to not know the hosting platform (GitHub vs ADO) and attempt to use `az repos pr create` initially before falling back to `gh pr create`.

**Target file**: `.github/config/workflow-config.json`  
**Change type**: context

**Suggested patch**:
```diff
      "Learn.Rendering.Preview": {
        "defaultBranch": "main",
        "preCommitCommand": "dotnet build",
        "buildCommand": "dotnet build",
        "testCommand": "dotnet test",
        "previewUrlPattern": null,
        "type": "deployment",
        "aliases": ["rendering-preview"]
-     }
+     },
+     "copilot-config": {
+       "defaultBranch": "main",
+       "preCommitCommand": null,
+       "buildCommand": null,
+       "testCommand": null,
+       "previewUrlPattern": null,
+       "type": "config",
+       "platform": "github",
+       "prUrlPattern": "https://github.com/jwmunn/copilot-config/pull/{PrNumber}",
+       "aliases": ["copilot-config"]
+     }
    },
```

**Rationale**: Adding copilot-config to the repositories config gives the ship-it workflow the context it needs: no build/test commands, GitHub platform (not ADO), and the correct PR URL pattern.

---

### Learning 3: Ship-it should handle GitHub repos (gh CLI) in addition to ADO repos

- **Signal**: wrong-pattern
- **Confidence**: medium
- **User said**: (implicit — agent had to switch from `az repos pr create` to `gh pr create` at runtime)
- **Root cause**: The ship-it prompt Step 5 only documents `az repos pr create` for Azure DevOps. copilot-config is hosted on GitHub and requires `gh pr create`. The prompt should branch based on the repo's platform.

**Target file**: `.github/prompts/mslearn-ship-it.prompt.md`  
**Change type**: rule

**Suggested patch**:
```diff
  ### Step 5: Create PR
  
+ Determine the platform from config (`repositories.{repo}.platform`). Default is `ado` if not specified.
+ 
+ **For GitHub repos** (`platform: "github"`):
+ ```bash
+ gh pr create \
+     --title "{PR title}" \
+     --body "{PR description}" \
+     --base $DEFAULT_BRANCH \
+     --head $BRANCH
+ ```
+ 
+ **For Azure DevOps repos** (`platform: "ado"` or unspecified):
  ```bash
  # Create PR using Azure DevOps CLI
  az repos pr create \
      --repository $REPO_NAME \
      --source-branch $BRANCH \
      --target-branch $DEFAULT_BRANCH \
      --title "{PR title}" \
      --description-file .azuredevops/pull_request_template.md \
      --org https://dev.azure.com/ceapex \
      --project Engineering
  ```
```

**Rationale**: Supporting both GitHub and ADO repos makes the ship-it workflow work across all repositories in the workspace without runtime guesswork.

---

## Applied Changes

| # | Learning | Target File | Status |
|---|---------|-------------|--------|
| 1 | Never push to default branch — hard block | `.github/prompts/mslearn-ship-it.prompt.md` | applied |
| 2 | Add copilot-config to workflow-config.json | `.github/config/workflow-config.json` | applied |
| 3 | Support GitHub repos in ship-it PR creation | `.github/prompts/mslearn-ship-it.prompt.md` | applied |

## Meta

- **Generalizability**: Learning 1 (main branch guard) is broadly applicable to all repos. Learnings 2-3 are specific to supporting GitHub-hosted repos alongside ADO repos.
- **Related learnings**: None — first ship-it session learning.
- **Follow-up**: After applying, test `/mslearn-ship-it` against copilot-config to verify GitHub PR creation works end-to-end.
