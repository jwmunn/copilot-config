#!/bin/bash
# Test script for Copilot agent lifecycle hooks
# Usage: bash .github/hooks/scripts/test-hooks.sh
# Run from the repo root where hooks are symlinked/installed

set -e

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

run_test() {
  local description="$1"
  local script="$2"
  local input="$3"
  local expect_deny="$4"  # "deny" or "allow"

  output=$(echo "$input" | bash "$SCRIPTS_DIR/$script" 2>/dev/null || true)

  if [ "$expect_deny" = "deny" ]; then
    if echo "$output" | grep -q '"permissionDecision":"deny"'; then
      echo -e "  ${GREEN}✓ PASS${NC} $description"
      PASS=$((PASS + 1))
    else
      echo -e "  ${RED}✗ FAIL${NC} $description"
      echo -e "    Expected: deny"
      echo -e "    Got: ${output:-<empty>}"
      FAIL=$((FAIL + 1))
    fi
  else
    if echo "$output" | grep -q '"permissionDecision":"deny"'; then
      echo -e "  ${RED}✗ FAIL${NC} $description"
      echo -e "    Expected: allow (no deny output)"
      echo -e "    Got: $output"
      FAIL=$((FAIL + 1))
    else
      echo -e "  ${GREEN}✓ PASS${NC} $description"
      PASS=$((PASS + 1))
    fi
  fi
}

make_input() {
  local tool_name="$1"
  local tool_args="$2"
  node -e "console.log(JSON.stringify({timestamp:1707800000000,cwd:process.cwd(),toolName:process.argv[1],toolArgs:process.argv[2]}))" "$tool_name" "$tool_args"
}

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Copilot Agent Hook Tests${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo ""

# ─── Safety Guard Tests ───────────────────────────────────────────
echo -e "${YELLOW}▸ safety-guard.sh${NC}"
echo ""

echo "  Destructive commands:"
run_test "Block rm -rf /" \
  "safety-guard.sh" \
  "$(make_input bash '{"command":"rm -rf /"}')" \
  "deny"

run_test "Block sudo rm" \
  "safety-guard.sh" \
  "$(make_input bash '{"command":"sudo rm -rf /tmp/data"}')" \
  "deny"

run_test "Block DROP TABLE" \
  "safety-guard.sh" \
  "$(make_input bash '{"command":"mysql -e \"DROP TABLE users;\""}')" \
  "deny"

run_test "Block format C:" \
  "safety-guard.sh" \
  "$(make_input bash '{"command":"format C:"}')" \
  "deny"

echo ""
echo "  Branch protection:"
run_test "Block force push to main" \
  "safety-guard.sh" \
  "$(make_input bash '{"command":"git push --force origin main"}')" \
  "deny"

run_test "Block git push -f to develop" \
  "safety-guard.sh" \
  "$(make_input bash '{"command":"git push -f origin develop"}')" \
  "deny"

run_test "Block direct push to main" \
  "safety-guard.sh" \
  "$(make_input bash '{"command":"git push origin main"}')" \
  "deny"

run_test "Allow push to feature branch" \
  "safety-guard.sh" \
  "$(make_input bash '{"command":"git push origin jumunn/my-feature"}')" \
  "allow"

run_test "Allow force push to feature branch" \
  "safety-guard.sh" \
  "$(make_input bash '{"command":"git push --force origin jumunn/my-feature"}')" \
  "allow"

echo ""
echo "  File protection:"
run_test "Block edit to CI/CD pipeline" \
  "safety-guard.sh" \
  "$(make_input edit '{"path":"azurepipelines/build.yml"}')" \
  "deny"

run_test "Block edit to package-lock.json" \
  "safety-guard.sh" \
  "$(make_input edit '{"path":"package-lock.json"}')" \
  "deny"

run_test "Block edit to yarn.lock" \
  "safety-guard.sh" \
  "$(make_input edit '{"path":"yarn.lock"}')" \
  "deny"

run_test "Allow edit to source file" \
  "safety-guard.sh" \
  "$(make_input edit '{"path":"src/components/MyComponent.tsx"}')" \
  "allow"

echo ""
echo "  Safe commands:"
run_test "Allow npm test" \
  "safety-guard.sh" \
  "$(make_input bash '{"command":"npm test"}')" \
  "allow"

run_test "Allow npm install" \
  "safety-guard.sh" \
  "$(make_input bash '{"command":"npm install"}')" \
  "allow"

run_test "Allow git status" \
  "safety-guard.sh" \
  "$(make_input bash '{"command":"git status"}')" \
  "allow"

run_test "Allow non-bash tools" \
  "safety-guard.sh" \
  "$(make_input view '{"path":"README.md"}')" \
  "allow"

echo ""

# ─── Pre-Commit Gate Tests ────────────────────────────────────────
echo -e "${YELLOW}▸ pre-commit-gate.sh${NC}"
echo ""

run_test "Ignore non-commit commands" \
  "pre-commit-gate.sh" \
  "$(make_input bash '{"command":"git status"}')" \
  "allow"

run_test "Ignore git add" \
  "pre-commit-gate.sh" \
  "$(make_input bash '{"command":"git add -A"}')" \
  "allow"

run_test "Ignore non-bash tools" \
  "pre-commit-gate.sh" \
  "$(make_input edit '{"path":"src/file.ts"}')" \
  "allow"

run_test "Intercepts git commit (config lookup)" \
  "pre-commit-gate.sh" \
  "$(make_input bash '{"command":"git commit -m \"test\""}')" \
  "allow"  # Will allow if no config found or if checks pass

# ─── Session End Learnings Tests ──────────────────────────────────
echo -e "${YELLOW}▸ session-end-learnings.sh${NC}"
echo ""

# Create a temp dir to avoid polluting the real artifacts
LEARNINGS_TEST_DIR=$(mktemp -d)

run_session_end_test() {
  local description="$1"
  local check="$2"  # "marker" or "log"

  # Use a mock input with cwd pointing to this repo
  local input
  input=$(node -e "console.log(JSON.stringify({timestamp:Date.now(),cwd:process.cwd()}))")

  # Run the script (it writes to copilot-config/agent-artifacts/learnings/)
  echo "$input" | bash "$SCRIPTS_DIR/session-end-learnings.sh" 2>/dev/null || true

  if [ "$check" = "marker" ]; then
    local marker="copilot-config/agent-artifacts/learnings/.session-end-marker.json"
    if [ -f "$marker" ]; then
      # Validate it's valid JSON with expected fields
      if node -e "const m=JSON.parse(require('fs').readFileSync('$marker','utf8')); if(!m.timestamp||!m.repoName||!m.branch) process.exit(1);" 2>/dev/null; then
        echo -e "  ${GREEN}✓ PASS${NC} $description"
        PASS=$((PASS + 1))
      else
        echo -e "  ${RED}✗ FAIL${NC} $description"
        echo -e "    Marker file exists but missing expected fields"
        FAIL=$((FAIL + 1))
      fi
    else
      echo -e "  ${RED}✗ FAIL${NC} $description"
      echo -e "    Marker file not created at $marker"
      FAIL=$((FAIL + 1))
    fi
  elif [ "$check" = "log" ]; then
    local logfile="copilot-config/agent-artifacts/learnings/session-end.log"
    if [ -f "$logfile" ] && grep -q "Session ended at" "$logfile"; then
      echo -e "  ${GREEN}✓ PASS${NC} $description"
      PASS=$((PASS + 1))
    else
      echo -e "  ${RED}✗ FAIL${NC} $description"
      echo -e "    Log file missing or doesn't contain expected entry"
      FAIL=$((FAIL + 1))
    fi
  fi
}

# Save existing marker/log if present
MARKER_BACKUP=""
LOG_BACKUP=""
if [ -f "copilot-config/agent-artifacts/learnings/.session-end-marker.json" ]; then
  MARKER_BACKUP=$(cat "copilot-config/agent-artifacts/learnings/.session-end-marker.json")
fi
if [ -f "copilot-config/agent-artifacts/learnings/session-end.log" ]; then
  LOG_BACKUP=$(cat "copilot-config/agent-artifacts/learnings/session-end.log")
fi

run_session_end_test "Creates marker file with session metadata" "marker"
run_session_end_test "Appends to session-end.log" "log"

# Verify marker JSON has correct structure
MARKER_FILE="copilot-config/agent-artifacts/learnings/.session-end-marker.json"
if [ -f "$MARKER_FILE" ]; then
  HAS_COMMIT=$(node -e "const m=JSON.parse(require('fs').readFileSync('$MARKER_FILE','utf8')); console.log(m.commitHash?'yes':'no');" 2>/dev/null || echo "no")
  if [ "$HAS_COMMIT" = "yes" ]; then
    echo -e "  ${GREEN}✓ PASS${NC} Marker includes commit hash"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗ FAIL${NC} Marker missing commit hash"
    FAIL=$((FAIL + 1))
  fi

  HAS_CWD=$(node -e "const m=JSON.parse(require('fs').readFileSync('$MARKER_FILE','utf8')); console.log(m.cwd?'yes':'no');" 2>/dev/null || echo "no")
  if [ "$HAS_CWD" = "yes" ]; then
    echo -e "  ${GREEN}✓ PASS${NC} Marker includes working directory"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗ FAIL${NC} Marker missing working directory"
    FAIL=$((FAIL + 1))
  fi
fi

# Restore originals
if [ -n "$MARKER_BACKUP" ]; then
  echo "$MARKER_BACKUP" > "copilot-config/agent-artifacts/learnings/.session-end-marker.json"
else
  rm -f "copilot-config/agent-artifacts/learnings/.session-end-marker.json"
fi
if [ -n "$LOG_BACKUP" ]; then
  echo "$LOG_BACKUP" > "copilot-config/agent-artifacts/learnings/session-end.log"
else
  rm -f "copilot-config/agent-artifacts/learnings/session-end.log"
fi

echo ""

# ─── Summary ─────────────────────────────────────────────────────
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
  echo -e "  ${GREEN}All $TOTAL tests passed${NC}"
else
  echo -e "  ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC} (of $TOTAL)"
fi
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo ""

exit $FAIL
