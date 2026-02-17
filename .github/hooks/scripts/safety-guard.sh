#!/bin/bash
# Safety guard hook - blocks dangerous commands and protects critical paths
# Runs as preToolUse hook before any tool execution
# Uses node for JSON parsing (available in all MS Learn repos)
set -e

INPUT=$(cat)

node -e "
const input = JSON.parse(process.argv[1]);
const toolName = input.toolName;
let toolArgs;
try { toolArgs = typeof input.toolArgs === 'string' ? JSON.parse(input.toolArgs) : input.toolArgs; }
catch { toolArgs = {}; }

function deny(reason) {
  console.log(JSON.stringify({ permissionDecision: 'deny', permissionDecisionReason: reason }));
  process.exit(0);
}

if (toolName === 'bash' || toolName === 'shell') {
  const cmd = toolArgs.command || '';
  if (!cmd) process.exit(0);

  // Block destructive system commands
  if (/rm\s+-rf\s+\/|sudo\s+rm|mkfs|dd\s+if=|:\(\)\{\s*:|format\s+[A-Z]:/i.test(cmd)) {
    deny('Destructive system command blocked by safety guard');
  }

  // Block SQL injection patterns
  if (/DROP\s+TABLE|DROP\s+DATABASE|TRUNCATE\s+TABLE|DELETE\s+FROM\s+\w+\s*;/i.test(cmd)) {
    deny('Destructive SQL command blocked by safety guard');
  }

  // Block force pushes to protected branches
  if (/git\s+push\s+.*(-f|--force)/.test(cmd) && /\b(main|develop|master)\b/.test(cmd)) {
    deny('Force push to protected branch (main/develop) blocked by safety guard');
  }

  // Block direct pushes to protected branches
  if (/git\s+push\s+origin\s+(main|develop|master)\b/.test(cmd)) {
    deny('Direct push to protected branch blocked - use a feature branch and PR');
  }
} else if (toolName === 'edit' || toolName === 'create') {
  const filePath = toolArgs.path || toolArgs.filePath || '';
  if (!filePath) process.exit(0);

  // Protect CI/CD pipeline configs
  if (/(azurepipelines|\.azure-pipelines|\.github\/workflows)\//.test(filePath)) {
    deny('CI/CD pipeline files are protected - modify manually');
  }

  // Protect package lock files
  if (/(package-lock\.json|yarn\.lock|pnpm-lock\.yaml)$/.test(filePath)) {
    deny('Lock files should not be edited directly - run package manager commands instead');
  }
}

// Allow everything else
" "$INPUT"
