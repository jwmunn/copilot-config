# MSLearn Copilot Agents - VS Code Extension

This VS Code extension allows you to use your custom MSLearn GitHub Copilot agents directly in VS Code with the `@` symbol syntax.

## Features

- 🤖 **Auto-discovery**: Automatically loads all `.agent.md` files from your copilot-config
- 💬 **Native Chat Integration**: Use `@agent-name` syntax in VS Code Chat
- 🔄 **Hot Reload**: Automatically reloads agents when files change
- 📋 **Follow-up Questions**: Smart follow-up suggestions based on agent type
- 🎯 **Context Aware**: Passes agent instructions and user prompts to GitHub Copilot

## Architecture

The copilot-config system has three invocation types:

| Type | Location | Invocation | Managed By |
|------|----------|------------|------------|
| **Agents** | `.github/agents/*.agent.md` | `@agent-name` | This extension |
| **Workflows** | `.github/prompts/*.prompt.md` | `/command` | VS Code native prompts |
| **Skills** | `.github/skills/{name}/SKILL.md` | Context for agents/Copilot | Self-contained packages |

This extension **only manages agents**. Workflows are native VS Code prompt files. Skills are self-contained `SKILL.md` packages in `.github/skills/` that provide specialized knowledge and templates — they are loaded on-demand as context by agents and Copilot, not registered as chat participants.

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
- `@mslearn-implementation` - Code implementation assistance
- `@mslearn-code-review` - Code review and quality analysis
- `@mslearn-test` - Testing strategy and test generation

## Available Skills

Skills are self-contained packages in `.github/skills/{name}/` with a `SKILL.md` file. They are **not** registered as chat participants — they provide specialized knowledge loaded as context when needed.

| Skill | Location | Purpose |
|-------|----------|--------|
| `create-ado-workitems` | `.github/skills/create-ado-workitems/` | Create ADO work items from plan |
| `assign-swe` | `.github/skills/assign-swe/` | Assign GitHub SWE to work item |
| `create-handoff` | `.github/skills/create-handoff/` | Create session handoff document |
| `explain-pr` | `.github/skills/explain-pr/` | Generate PR explanation document |
| `pre-commit` | `.github/skills/pre-commit/` | Run quality gate checks |

Each skill may include a `references/` directory with templates and domain knowledge.

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

## Skill Structure

Skills use the `SKILL.md` format:

```
skill-name/
├── SKILL.md              # name + description frontmatter, instructions
└── references/           # Optional templates and domain knowledge
    └── template.md
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

Skills are discovered from `.github/skills/` in the same copilot-config directory.

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