#!/bin/bash

# Quick installer for MSLearn Copilot Agents VS Code Extension
echo "🚀 Installing MSLearn Copilot Agents VS Code Extension..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSION_DIR="$SCRIPT_DIR/vscode-extension"

if [ ! -d "$EXTENSION_DIR" ]; then
    echo "❌ Extension directory not found: $EXTENSION_DIR"
    exit 1
fi

cd "$EXTENSION_DIR"

if [ -f "install.sh" ]; then
    chmod +x install.sh
    ./install.sh
else
    echo "❌ install.sh not found in extension directory"
    exit 1
fi