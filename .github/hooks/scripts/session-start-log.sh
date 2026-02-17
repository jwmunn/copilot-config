#!/bin/bash
# session-start-log.sh: Logs session start for Copilot CLI
INPUT=$(cat)
TIMESTAMP=$(echo "$INPUT" | node -pe "JSON.parse(require('fs').readFileSync(0, 'utf8')).timestamp")
CWD=$(echo "$INPUT" | node -pe "JSON.parse(require('fs').readFileSync(0, 'utf8')).cwd")
echo "Session started at $TIMESTAMP in $CWD" >> .github/hooks/session-start.log
exit 0
