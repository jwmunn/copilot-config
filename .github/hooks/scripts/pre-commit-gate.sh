#!/bin/bash
# Pre-commit quality gate hook - runs repo-specific checks before git commit
# Runs as preToolUse hook, only activates when the tool is bash and the command is git commit
# Uses node for JSON parsing (available in all MS Learn repos)
set -e

INPUT=$(cat)

# Use node to parse JSON and determine if this is a git commit + find the pre-commit command
RESULT=$(node -e "
const input = JSON.parse(process.argv[1]);
const toolName = input.toolName;

// Only intercept bash/shell commands
if (toolName !== 'bash' && toolName !== 'shell') { process.exit(0); }

let toolArgs;
try { toolArgs = typeof input.toolArgs === 'string' ? JSON.parse(input.toolArgs) : input.toolArgs; }
catch { process.exit(0); }

const command = toolArgs.command || '';

// Only intercept git commit commands
if (!/git\s+commit/.test(command)) { process.exit(0); }

// Determine repo name from cwd
const path = require('path');
const { execSync } = require('child_process');
const cwd = input.cwd;

let repoName;
try {
  repoName = path.basename(execSync('git rev-parse --show-toplevel', { cwd, encoding: 'utf8' }).trim());
} catch {
  repoName = path.basename(cwd);
}

// Find workflow-config.json
const fs = require('fs');
const configLocations = [
  path.join(cwd, '.github/config/workflow-config.json'),
  path.join(cwd, '../copilot-config/.github/config/workflow-config.json'),
  path.join(cwd, '../../copilot-config/.github/config/workflow-config.json'),
];

let preCommitCmd = null;
for (const configPath of configLocations) {
  if (fs.existsSync(configPath)) {
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    const repos = config.repositories || {};

    // Direct name match
    if (repos[repoName]?.preCommitCommand) {
      preCommitCmd = repos[repoName].preCommitCommand;
      break;
    }

    // Alias match
    for (const [, repoConfig] of Object.entries(repos)) {
      if ((repoConfig.aliases || []).includes(repoName) && repoConfig.preCommitCommand) {
        preCommitCmd = repoConfig.preCommitCommand;
        break;
      }
    }
    if (preCommitCmd) break;
  }
}

// Output: CWD and pre-commit command (or empty)
console.log(JSON.stringify({ cwd, repoName, preCommitCmd }));
" "$INPUT")

# If node exited early (not a commit), allow
if [ -z "$RESULT" ]; then
  exit 0
fi

PRE_COMMIT_CMD=$(echo "$RESULT" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(d.preCommitCmd||'')")
TARGET_CWD=$(echo "$RESULT" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(d.cwd||'')")

# If no pre-commit command found, allow the commit
if [ -z "$PRE_COMMIT_CMD" ]; then
  exit 0
fi

# Run the pre-commit checks
echo "Running pre-commit quality gate: $PRE_COMMIT_CMD" >&2
cd "$TARGET_CWD"

if eval "$PRE_COMMIT_CMD" >&2 2>&1; then
  # Checks passed, allow the commit
  exit 0
else
  echo '{"permissionDecision":"deny","permissionDecisionReason":"Pre-commit quality gate failed. Fix the build/lint/typecheck errors before committing."}'
  exit 0
fi
