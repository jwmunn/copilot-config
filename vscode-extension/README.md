# MSLearn Copilot Agents - VS Code Extension

This VS Code extension allows you to use your custom MSLearn GitHub Copilot agents directly in VS Code with the `@` symbol syntax.

## Features

- 🤖 **Auto-discovery**: Automatically loads all `.agent.md` files from your copilot-config
- 💬 **Native Chat Integration**: Use `@agent-name` syntax in VS Code Chat
- 🔄 **Hot Reload**: Automatically reloads agents when files change
- 📋 **Follow-up Questions**: Smart follow-up suggestions based on agent type
- 🎯 **Context Aware**: Passes agent instructions and user prompts to GitHub Copilot

## Quick Start

### 1. Installation

Choose your preferred installation method:

#### Option A: Automated Installation (Recommended)
```bash
# PowerShell (Windows)
cd path/to/copilot-config/vscode-extension
./install.ps1

# Bash (Linux/Mac/WSL)
cd path/to/copilot-config/vscode-extension
./install.sh
```

#### Option B: Manual Installation
```bash
cd vscode-extension
npm install
npm run compile
npm run package
code --install-extension *.vsix
```

### 2. Usage

1. **Restart VS Code** after installation
2. **Open your workspace** containing the `copilot-config` directory
3. **Open Chat** (Ctrl+Alt+I / Cmd+Alt+I)
4. **Use your agents** with `@agent-name`

Example:
```
@mslearn-research Can you analyze the codebase structure for the docs-ui project?

@mslearn-planning Create an implementation plan for adding a new component

@mslearn-code-review Review this code for security issues
```

## Available Agents

The extension automatically loads all agents from your `.github/agents/` directory:

- `@mslearn-research` - Deep codebase analysis and documentation
- `@mslearn-planning` - Implementation planning and task breakdown  
- `@mslearn-code-review` - Code review and quality analysis
- `@mslearn-implementation` - Code implementation assistance
- `@mslearn-test` - Testing strategy and test generation
- And more...

## Agent Structure

Agents are defined in `.agent.md` files with this structure:

```markdown
---
name: my-agent
description: What this agent does
tools: []
---

# Agent Instructions

Your detailed agent instructions go here...
```

## Commands

- **Reload Agents**: `Ctrl+Shift+P` → "MSLearn: Reload Agents"
- **Show Agent Info**: `Ctrl+Shift+P` → "MSLearn: Show Agents Info"

## Requirements

- **VS Code**: 1.90.0 or higher
- **GitHub Copilot**: Extension must be installed and active
- **Node.js**: For building the extension
- **Workspace**: Must contain `copilot-config/.github/agents/` directory

## Directory Structure

The extension looks for agents in these locations (in order):
1. `{workspace}/copilot-config/.github/agents/`
2. `{workspace}/.github/agents/`
3. `{workspace}/../copilot-config/.github/agents/`

## Troubleshooting

### Extension Not Loading Agents
- Ensure your workspace contains the `copilot-config` directory
- Check VS Code Developer Console for errors: `Help → Toggle Developer Tools → Console`
- Try the "MSLearn: Reload Agents" command

### Agents Not Appearing in Chat
- Make sure GitHub Copilot extension is installed and active
- Restart VS Code after installation
- Verify agent files have proper frontmatter format

### Build Errors
- Ensure Node.js is installed: `npm --version`
- Clear cache: `npm clean-install`
- Check TypeScript compilation: `npm run compile`

## Development

### Building from Source
```bash
git clone <repository>
cd vscode-extension
npm install
npm run compile
npm run package
```

### File Watching
```bash
npm run watch  # Continuously compile TypeScript changes
```

### Debugging
1. Open the extension in VS Code
2. Press F5 to launch Extension Development Host
3. Test your changes in the new VS Code window

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This extension is part of the MSLearn platform tooling.