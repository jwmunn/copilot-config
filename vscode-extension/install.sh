#!/bin/bash

# MSLearn Copilot Agents - Installation Script (Bash)
# ====================================================

echo "🚀 MSLearn Copilot Agents - Installation Script"
echo "================================================"

EXTENSION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$EXTENSION_DIR"

run_command() {
    local command="$1"
    local description="$2"
    
    echo ""
    echo "📦 $description..."
    
    if eval "$command"; then
        return 0
    else
        echo "❌ Error: Failed to execute: $command"
        return 1
    fi
}

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm not found. Please install Node.js"
    exit 1
fi

# Check if code command is available
if ! command -v code &> /dev/null; then
    echo "❌ Error: 'code' command not found. Please ensure VS Code is installed and added to PATH"
    exit 1
fi

# Install dependencies
if ! run_command "npm install" "Installing dependencies"; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Compile TypeScript
if ! run_command "npm run compile" "Compiling TypeScript"; then
    echo "❌ Failed to compile TypeScript"
    exit 1
fi

# Package the extension
echo ""
echo "📦 Packaging extension..."
if ! run_command "npm run package" "Creating VSIX package"; then
    echo "❌ Failed to package extension"
    exit 1
fi

# Find the generated VSIX file
VSIX_FILE=$(ls *.vsix 2>/dev/null | head -n 1)

if [ -z "$VSIX_FILE" ]; then
    echo "❌ Error: VSIX file not found after packaging"
    exit 1
fi

echo ""
echo "✅ Extension packaged: $VSIX_FILE"

# Install the extension
echo ""
echo "🔧 Installing extension in VS Code..."
if ! run_command "code --install-extension $VSIX_FILE" "Installing extension"; then
    echo "❌ Failed to install extension"
    exit 1
fi

echo ""
echo "🎉 Installation completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Restart VS Code"
echo "2. Open a workspace with copilot-config directory"
echo "3. Use @mslearn-research, @mslearn-planning, etc. in the chat"
echo ""
echo "💡 Use Ctrl+Shift+P and search 'MSLearn' to see available commands"