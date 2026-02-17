#!/bin/bash
# session-end-learnings.sh: Logs session end and writes a marker for learnings extraction
# Runs as sessionEnd hook
# The actual AI-driven analysis is performed by the session-learnings skill/prompt
set -e

INPUT=$(cat)

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ARTIFACTS_DIR="copilot-config/agent-artifacts/learnings"

# Create learnings directory if it doesn't exist
mkdir -p "$ARTIFACTS_DIR"

# Extract session metadata via node
SESSION_META=$(node -e "
const input = JSON.parse(process.argv[1]);
const ts = new Date().toISOString();
const cwd = input.cwd || process.cwd();
const path = require('path');

let repoName;
try {
  const { execSync } = require('child_process');
  repoName = path.basename(execSync('git rev-parse --show-toplevel', { cwd, encoding: 'utf8' }).trim());
} catch {
  repoName = path.basename(cwd);
}

let branch;
try {
  const { execSync } = require('child_process');
  branch = execSync('git rev-parse --abbrev-ref HEAD', { cwd, encoding: 'utf8' }).trim();
} catch {
  branch = 'unknown';
}

let commitHash;
try {
  const { execSync } = require('child_process');
  commitHash = execSync('git rev-parse --short HEAD', { cwd, encoding: 'utf8' }).trim();
} catch {
  commitHash = 'unknown';
}

console.log(JSON.stringify({ timestamp: ts, cwd, repoName, branch, commitHash }));
" "$INPUT")

# Write session-end marker with metadata
MARKER_FILE="$ARTIFACTS_DIR/.session-end-marker.json"
echo "$SESSION_META" > "$MARKER_FILE"

# Append to session log
echo "Session ended at $TIMESTAMP" >> "$ARTIFACTS_DIR/session-end.log"

exit 0
