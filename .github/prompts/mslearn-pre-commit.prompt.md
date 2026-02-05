---
description: Pre-commit quality gate - run before committing changes to catch issues early
---

# Pre-Commit Quality Check

Run repository-specific quality checks before committing to catch build, type, lint, and security issues early.

## Configuration

Load from `copilot-config/.github/config/workflow-config.json`:
- Repository-specific `preCommitCommand`
- Quality gate settings

## Automatic Invocation

This check should be run:
- Before any `git commit`
- Before `/ship-it` workflow
- After completing implementation phases

## Repository-Specific Commands

From config, each repo has its own pre-commit command:

| Repository | Pre-Commit Command |
|------------|-------------------|
| docs-ui | `npx wireit betterer precommit --cache` |
| Learn.SharedComponents | `npm run clean && npm run components:build && npm run app:build` |
| Docs.ContentService | `dotnet build` |
| Learn.Rendering.Preview | `dotnet build` |

## Process

### Step 1: Identify Repository

```bash
# Get repo name from git
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename $REPO_ROOT)
```

### Step 2: Get Repository Config

Look up in workflow-config.json:
```
Repository: {repo name}
Pre-commit command: {command}
```

### Step 3: Run Checks

```bash
# Navigate to repo root
cd $REPO_ROOT

# Run the pre-commit command
{preCommitCommand}
```

### Step 4: Report Results

#### Success ✅
```
Pre-commit checks passed ✅

Repository: {repo name}
Command: {command}
Duration: {time}

Safe to commit!
```

#### Failure ❌
```
Pre-commit checks FAILED ❌

Repository: {repo name}
Command: {command}

Errors:
{error output}

Please fix these issues before committing:
1. {parsed issue 1}
2. {parsed issue 2}

Common fixes:
- Type error: Check the referenced file and fix type mismatch
- Lint error: Run `npm run lint:fix` to auto-fix lint issues
- Build error: Check for syntax errors or missing dependencies
```

## Check Categories

### TypeScript Repositories (docs-ui, Learn.SharedComponents)

**Betterer** catches:
- Type regressions (new TypeScript errors)
- Lint regressions (new ESLint errors)
- Test regressions (failing tests)

**Build** catches:
- Compilation errors
- Missing dependencies
- Invalid imports

### C# Repositories (Docs.ContentService, Learn.Rendering.Preview)

**dotnet build** catches:
- Compilation errors
- Warning as errors (if configured)
- Missing packages

## Integration with Workflows

### In Implementation Agent
After each phase:
```
Phase {N} changes complete. Running quality check...

{run pre-commit}

✅ Quality check passed - safe to continue
```

### In Ship-It Workflow
Before commit:
```
Running pre-commit quality gate...

{run pre-commit}

✅ All checks pass - proceeding with commit
```

### In Code Review Agent
As part of review:
```
Running build verification...

{run pre-commit}

✅ Build passes - no regression introduced
```

## Troubleshooting

### Common TypeScript Issues

**Type Error Fix**:
```typescript
// Error: Type 'string' is not assignable to type 'number'
// Fix: Check the type definition and actual value
```

**Missing Import**:
```bash
npm install {package}
```

### Common C# Issues

**Missing Package**:
```bash
dotnet restore
```

**Build Configuration**:
```bash
dotnet build --configuration Release
```

## Skip Check (Emergency Only)

For emergency hotfixes:
```
/pre-commit --skip

⚠️ WARNING: Skipping pre-commit checks

This should only be used for:
- Emergency production fixes
- Known CI issues being addressed

Proceeding without quality gates...
```

