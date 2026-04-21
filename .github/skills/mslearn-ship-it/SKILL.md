---
description: Commit, push, create PR with proper template and preview URLs
---

# Ship It Workflow

Comprehensive workflow for shipping changes: commit, push, create PR with proper template, and set up for testing.

## Prerequisites

- Azure DevOps CLI installed (`az extension add --name azure-devops`)
- Logged in (`az login`)
- Changes ready to commit

## Configuration

Load from `copilot-config/.github/config/workflow-config.json`:
- `git.branchNamingPattern`
- `git.prTemplateLocation`
- `repositories.{repo}.preCommitCommand`
- `repositories.{repo}.previewUrlPattern`
- `azureDevOps.prUrlPattern`

## Process

### Step 1: Pre-Flight Checks

```bash
# Check for uncommitted changes
git status

# Identify current repo
REPO_NAME=$(basename $(git rev-parse --show-toplevel))

# Get current branch
BRANCH=$(git branch --show-current)
```

### Step 2: Quality Gate

Run pre-commit checks before allowing commit:

```bash
# Get repo-specific pre-commit command from config
# Example outputs based on repo:
# docs-ui: npx wireit betterer precommit --cache
# Learn.SharedComponents: npm run clean && npm run components:build && npm run app:build
# Docs.ContentService: dotnet build
```

If checks fail:
```
❌ Pre-commit checks failed:

{error output}

Please fix the issues before shipping.
```

If checks pass, continue.

### Step 3: Stage and Commit

```bash
# Show changes to be committed
git diff --stat

# Stage all changes (or prompt for selective staging)
git add -A

# Commit with descriptive message
git commit -m "{type}: {description}

{body if needed}

{footer: work item if applicable}"
```

Commit message format:
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `docs:` - Documentation
- `test:` - Adding tests
- `chore:` - Maintenance

### Step 4: Push Branch

```bash
# Get default branch from config (main or develop for docs-ui)
DEFAULT_BRANCH={from config}

# Ensure we're not on default branch
if [ "$BRANCH" = "$DEFAULT_BRANCH" ]; then
    echo "Error: Cannot ship from $DEFAULT_BRANCH. Create a feature branch first."
    exit 1
fi
```

**⛔ HARD BLOCK**: If the current branch IS the default branch, you MUST:
1. Create a feature branch using the naming pattern from config: `{alias}/{description}`
2. Move the unpushed commit(s) to the new branch (e.g., `git checkout -b {new-branch}`)
3. Switch back to the default branch and reset it to match origin: `git checkout {default} && git reset --hard origin/{default}`
4. Switch to the feature branch and continue the workflow from there

**NEVER offer "push directly to main/develop" as an option.** This is not negotiable, even for config-only repos with no CI. All changes must go through a PR.

```bash
# Push to origin
git push -u origin $BRANCH
```

### Step 5: Create PR

Determine the platform from config (`repositories.{repo}.platform`). Default is `ado` if not specified.

**For GitHub repos** (`platform: "github"`):
```bash
gh pr create \
    --title "{PR title}" \
    --body "{PR description}" \
    --base $DEFAULT_BRANCH \
    --head $BRANCH
```

**For Azure DevOps repos** (`platform: "ado"` or unspecified):
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

### Step 6: Populate PR Description

Read and fill PR template from `.azuredevops/pull_request_template.md`:

```markdown
## Description
{Summary of changes from commit messages}

## Related Work Items
- #{ADO work item ID if applicable}

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing

### Preview Environment
{Preview URL from config with PR number}

Example URLs based on repo:
- docs-ui: https://ppe.preview.learn.microsoft-int.com/?pr={PrNumber}
- Learn.SharedComponents: https://shared-components.preview.learn.microsoft-int.com/?pr={PrNumber}

### Validation Steps
1. {Step to verify the change}
2. {Additional verification}

## Checklist
- [ ] Code follows repository patterns
- [ ] Self-reviewed the code
- [ ] Added/updated tests if applicable
- [ ] Documentation updated if needed
```

### Step 7: Output Summary

```
✅ Shipped successfully!

Branch: {branch}
PR: {PR URL from config pattern}
Preview: {preview URL}

Quick links:
- View PR: {URL}
- Test in preview: {preview URL}

Next steps:
- [ ] Verify in preview environment
- [ ] Request code review
- [ ] Address any feedback
```

## Error Handling

### Uncommitted Changes on Wrong Branch

```
⚠️ You're on {default branch} with uncommitted changes.

Options:
1. Create feature branch first: git checkout -b {alias}/{description}
2. Stash changes: git stash
```

### Pre-commit Failures

```
❌ Quality gate failed. Cannot ship.

Failed checks:
- {check1}: {error}
- {check2}: {error}

Fix these issues and run /ship-it again.
```

### Push Rejected

```
❌ Push rejected. Branch may need rebase.

Run:
git fetch origin
git rebase origin/{default branch}
git push --force-with-lease
```

## Quick Ship (Skip Checks)

For emergency fixes only:
```
/ship-it --force

⚠️ Skipping pre-commit checks. Use only for emergencies.
```

## Dry Run

To see what would happen without executing:
```
/ship-it --dry-run

Would execute:
1. git add -A
2. git commit -m "..."
3. git push -u origin {branch}
4. az repos pr create ...

Preview URL would be: {url}
```


