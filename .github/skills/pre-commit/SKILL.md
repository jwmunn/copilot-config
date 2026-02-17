---
description: Run repository-specific quality gate checks before committing changes. Identifies and runs the correct build, lint, and type-check commands based on which repository you're in. Use before any git commit, before the ship-it workflow, or after completing implementation phases. Triggers on "pre-commit check", "quality check", "run checks before commit", "verify build".
---

# Pre-Commit Quality Check

Run the correct pre-commit quality gate for the current repository.

## Configuration

Load from `copilot-config/.github/config/workflow-config.json`:

- Match the current repo to `repositories.{name}.preCommitCommand`
- Fall back to `qualityGates.preCommit.checks` for default behavior

## Repository Commands

| Repository | Command |
|------------|---------|
| docs-ui | `npx wireit betterer precommit --cache` |
| Learn.SharedComponents | `npm run clean && npm run components:build && npm run app:build` |
| Docs.ContentService | `dotnet build` |
| Learn.Rendering.Preview | `dotnet build` |

## Process

### 1. Identify Repository

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename $REPO_ROOT)
```

Match against repo names and aliases in the config.

### 2. Run Checks

```bash
cd $REPO_ROOT
{preCommitCommand from config}
```

### 3. Report Results

**On success**: Confirm all checks passed, show duration, indicate safe to commit.

**On failure**: Show error output, parse and list specific issues, suggest common fixes:
- Type errors → check referenced file and fix type mismatch
- Lint errors → `npm run lint:fix`
- Build errors → check for syntax errors or missing dependencies
- Missing packages → `npm install` or `dotnet restore`

## Skip Mode

For emergency hotfixes only — when `--skip` is specified, warn prominently that quality gates are being bypassed and proceed.

## Integration

This check runs:
- Standalone via direct invocation
- Automatically before `ship-it` workflow commits
- After each implementation phase in the `implement_plan` workflow
- During code review for build verification
