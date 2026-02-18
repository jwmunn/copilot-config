#!/bin/bash
# setup-node.sh: Install Node.js and npm for GitHub Copilot SWE agent sessions.
#
# Called by: copilot-agent-hooks.json (sessionStart)
# Purpose: The SWE agent container doesn't have Node.js/npm pre-installed.
#          This script installs the version specified in .nvmrc and runs npm ci.
#
# Environment: Linux container (GitHub Copilot SWE agent)
# Exit: Always exits 0 to avoid blocking the session if setup fails partially.
#       The agent will see errors when it tries to run npm commands and can retry.

set -e

# ─── Check if Node.js is already available ───
if command -v node &>/dev/null && command -v npm &>/dev/null; then
  echo "✓ Node.js $(node --version) and npm $(npm --version) already available"
  exit 0
fi

echo "⚙ Setting up Node.js environment..."

# ─── Determine desired Node.js version ───
NODE_VERSION=""
if [ -f ".nvmrc" ]; then
  NODE_VERSION=$(cat .nvmrc | tr -d '[:space:]')
  echo "  Found .nvmrc: v${NODE_VERSION}"
elif [ -f "package.json" ]; then
  NODE_VERSION=$(node -pe "try { JSON.parse(require('fs').readFileSync('package.json','utf8')).engines?.node?.replace(/[^0-9.]/g,'') } catch(e) { '' }" 2>/dev/null || echo "")
  if [ -n "$NODE_VERSION" ]; then
    echo "  Found engines.node in package.json: v${NODE_VERSION}"
  fi
fi

# Fallback to a known LTS version
if [ -z "$NODE_VERSION" ]; then
  NODE_VERSION="24.11.1"
  echo "  No version spec found, using default: v${NODE_VERSION}"
fi

# ─── Try nvm first (may be pre-installed in some containers) ───
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  echo "  Using nvm to install Node.js v${NODE_VERSION}..."
  source "$NVM_DIR/nvm.sh"
  nvm install "$NODE_VERSION" && nvm use "$NODE_VERSION"
  if command -v node &>/dev/null; then
    echo "✓ Node.js $(node --version) installed via nvm"
  fi
else
  # ─── Direct download from nodejs.org ───
  echo "  Downloading Node.js v${NODE_VERSION} from nodejs.org..."
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) ARCH="x64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l) ARCH="armv7l" ;;
  esac

  NODE_DIST="node-v${NODE_VERSION}-linux-${ARCH}"
  NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/${NODE_DIST}.tar.xz"

  INSTALL_DIR="/usr/local/lib/nodejs"
  mkdir -p "$INSTALL_DIR"

  if command -v curl &>/dev/null; then
    curl -fsSL "$NODE_URL" | tar -xJ -C "$INSTALL_DIR"
  elif command -v wget &>/dev/null; then
    wget -qO- "$NODE_URL" | tar -xJ -C "$INSTALL_DIR"
  else
    echo "✗ Neither curl nor wget available. Cannot install Node.js."
    exit 0
  fi

  # Add to PATH for this session and future commands
  export PATH="$INSTALL_DIR/${NODE_DIST}/bin:$PATH"

  # Persist PATH for subsequent terminal commands in this session
  if [ -f "$HOME/.bashrc" ]; then
    echo "export PATH=\"$INSTALL_DIR/${NODE_DIST}/bin:\$PATH\"" >> "$HOME/.bashrc"
  fi
  if [ -f "$HOME/.profile" ]; then
    echo "export PATH=\"$INSTALL_DIR/${NODE_DIST}/bin:\$PATH\"" >> "$HOME/.profile"
  fi

  echo "✓ Node.js $(node --version) installed to $INSTALL_DIR/${NODE_DIST}"
fi

# ─── Verify installation ───
if ! command -v node &>/dev/null; then
  echo "✗ Node.js installation failed. Agent will need to install manually."
  exit 0
fi

echo "  Node.js: $(node --version)"
echo "  npm: $(npm --version)"

# ─── Install dependencies ───
if [ -f "package-lock.json" ]; then
  echo "⚙ Running npm ci..."
  npm ci --ignore-scripts 2>&1 | tail -5
  echo "✓ Dependencies installed"
elif [ -f "package.json" ]; then
  echo "⚙ Running npm install..."
  npm install --ignore-scripts 2>&1 | tail -5
  echo "✓ Dependencies installed"
fi

echo "✓ Node.js environment ready"
exit 0
