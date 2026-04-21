# Copilot Workflow Automation

GitHub Copilot workflow automation for Microsoft Learn platform development.

## Quick Start

```bash
# Research a feature
@mslearn-research Analyze the article rating system in docs-ui

# Create implementation plan
@mslearn-planning Create plan from: copilot-config/agent-artifacts/research/{file}.md

# Implement
@mslearn-implementation Execute Phase 1 of plan

# Ship it
/mslearn-ship-it
```

## Multi-Repo Workspace Setup

This repo provides assets for **two Copilot surfaces**:

| Surface | Loads | Setup script |
|---|---|---|
| **Copilot CLI** | `.github/skills/` (auto-loaded from `~/.copilot/skills/`) | `setup-global.ps1` |
| **VS Code Copilot Chat** | `.github/{prompts,instructions,agents}/` (per-repo) | `setup-agents.ps1` |

Skills and prompts are kept in lockstep by `migrate-prompts-to-skills.ps1` — every `mslearn-*.prompt.md` has a matching `mslearn-*` skill folder.

### One-Time Setup

```powershell
# 1. Make ALL mslearn skills available globally in Copilot CLI
.\setup-global.ps1

# 2. Link prompts/instructions/agents into every sibling repo for VS Code
.\setup-agents.ps1
```

```bash
# macOS/Linux equivalent (skills only - no CLI sym-link script yet)
./setup-agents.sh
```

After running both, in any Copilot CLI session you'll see all `mslearn-*` skills in `/env`, and in any VS Code session inside a sibling repo you'll see `/mslearn-*` slash commands.

### Options

```powershell
# Preview without applying
.\setup-global.ps1 -DryRun
.\setup-agents.ps1 -DryRun

# Link specific repos only
.\setup-agents.ps1 -TargetRepos docs-ui, Learn.SharedComponents

# Restrict which assets get linked (default: all three)
.\setup-agents.ps1 -Assets prompts, instructions

# Replace existing folders (will delete their contents!)
.\setup-agents.ps1 -Force
.\setup-global.ps1 -Force
```

### Keeping Skills In Sync With Prompts

When you add or modify a prompt in `.github/prompts/`, regenerate the matching skill:

```powershell
.\migrate-prompts-to-skills.ps1            # idempotent; preview with -DryRun
.\setup-global.ps1                         # link any newly-created skills
```

The migration script:
- Renames legacy un-prefixed skill folders to `mslearn-<name>`
- Creates `SKILL.md` from any `mslearn-*.prompt.md` lacking a matching skill
- Strips VS-Code-only frontmatter (`agent:`, `model:`) on conversion
- Leaves originals in `.github/prompts/` untouched

### Manual Setup

If you prefer manual setup or have repos in non-standard locations:

```powershell
# Windows (PowerShell) - Junction (no admin required)
New-Item -ItemType Junction -Path "{TARGET_REPO}\.github\agents" -Target "C:\repos\mslearn\copilot-config\.github\agents"
New-Item -ItemType Junction -Path "$env:USERPROFILE\.copilot\skills\mslearn-ship-it" -Target "C:\repos\mslearn\copilot-config\.github\skills\mslearn-ship-it"
```

```bash
# macOS/Linux - Symlink
ln -s /path/to/copilot-config/.github/agents {TARGET_REPO}/.github/agents
ln -s /path/to/copilot-config/.github/skills/mslearn-ship-it ~/.copilot/skills/mslearn-ship-it
```

### Notes

- **Junctions/symlinks are local** — each developer runs setup once. Edits to source files are reflected immediately; no resync needed.
- **Restart any active Copilot session** after setup to pick up new skills.
- If a target repo has existing prompts/instructions, `setup-agents.ps1` skips them (use `-Force` to replace or merge manually).
- Agents have **full access to all repos** in the workspace regardless of discovery location.
- **CLI invocation differs from VS Code:** CLI skills aren't typed as `/mslearn-ship-it` — describe your intent (e.g., "ship this") and the agent picks the matching skill from its description. VS Code still uses explicit `/mslearn-ship-it` slash commands.

## Environment Configuration

The workflow configuration uses environment variables to avoid storing personal information in Git. Set up your environment:

### Initial Setup

1. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your personal information:
   ```bash
   # User Information  
   USER_ALIAS=your-alias
   USER_EMAIL=your-email@microsoft.com
   ADO_ASSIGNEE=your-email@microsoft.com
   ADO_AREA_PATH=Engineering\\POD\\YourTeam
   ```

3. The `.env` file is already included in `.gitignore` and will not be committed.

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `USER_ALIAS` | Your Microsoft alias | `jumunn` |
| `USER_EMAIL` | Your Microsoft email | `jumunn@microsoft.com` |
| `ADO_ASSIGNEE` | Default assignee for ADO items | `jumunn@microsoft.com` |
| `ADO_AREA_PATH` | Your team's area path | `Engineering\POD\YourTeam` |
| `ADO_ORGANIZATION` | Azure DevOps org URL | `https://dev.azure.com/ceapex` |
| `ADO_PROJECT` | Azure DevOps project name | `Engineering` |
| `ADO_SWE_ASSIGNEE` | SWE agent identity (GUID) | *(see .env.example)* |

The workflow configuration in `.github/config/workflow-config.json` uses `${VAR_NAME}` placeholders that resolve from your `.env` file.

## Claude Code with GitHub Copilot (Proxy)

Use your GitHub Copilot Enterprise license as the backend for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — no separate Anthropic API key needed.

> **Prerequisite**: Your GitHub account must be linked to Microsoft Enterprise. If not, [link it first](https://repos.opensource.microsoft.com/link).

### Quick Start

1. **Start the proxy** (in a separate terminal):
   ```bash
   npx copilot-api@latest start
   ```
   First run opens a browser for GitHub OAuth. The proxy listens on `http://localhost:4141`.

2. **Run Claude Code** (in another terminal):
   ```bash
   ANTHROPIC_BASE_URL=http://localhost:4141 claude
   ```

### Recommended: Use `--claude-code` Mode

The `--claude-code` flag provides an interactive model picker and generates the correct launch command:

```bash
npx copilot-api@latest start --claude-code
```

### Shell Alias (Permanent Setup)

Add to `~/.zshrc`, `~/.bashrc`, or your PowerShell profile:

```bash
# bash/zsh
alias claude-copilot='ANTHROPIC_BASE_URL=http://localhost:4141 claude'
```

```powershell
# PowerShell ($PROFILE)
function claude-copilot { $env:ANTHROPIC_BASE_URL="http://localhost:4141"; claude @args }
```

### Proxy Options

| Flag | Description |
|------|-------------|
| `-p, --port` | Port to listen on (default: `4141`) |
| `-c, --claude-code` | Interactive model picker for Claude Code |
| `-v, --verbose` | Enable verbose logging |
| `-r, --rate-limit` | Rate limit in seconds between requests |
| `-w, --wait` | Wait instead of error when rate limit is hit |
| `--proxy-env` | Initialize proxy from environment variables |

### Troubleshooting

| Issue | Fix |
|-------|-----|
| `EADDRINUSE: address already in use :::4141` | A previous proxy is still running. Kill it: `netstat -ano \| grep 4141` to find the PID, then `taskkill /PID <pid> /F` (Windows) or `kill <pid>` (macOS/Linux). Or use `--port 4142` to pick a different port. |
| `--account-type=enterprise` hangs on startup | Omit it — the proxy auto-detects your enterprise license from the GitHub OAuth token. |
| Browser doesn't open for auth | Run `npx copilot-api@latest auth` first to complete OAuth separately, then start the proxy. |
| Need to re-authenticate | Run `npx copilot-api@latest auth` to refresh your GitHub token. |

## System Architecture

```mermaid
graph TB
    subgraph "User Commands"
        P["/prompts"]
    end
    
    subgraph "Orchestration Layer"
        P --> WF["Workflow Prompts<br/>(small-feature, large-feature, ship-it, etc.)"]
        WF --> |delegates to| SK["Skills<br/>(pre-commit, create-handoff, etc.)"]
    end
    
    subgraph "Agent Personas (referenced via prompt frontmatter)"
        WF --> RA["mslearn-research"]
        WF --> PA["mslearn-planning"]
        WF --> IA["mslearn-implementation"]
        WF --> CR["mslearn-code-review"]
    end
    
    subgraph "Automatic (no user invocation)"
        HK_I["Instruction Hooks<br/>(.vscode/settings.json)<br/>commit msg · code review · test gen"]
        HK_A["Agent Lifecycle Hooks<br/>(.github/hooks/)<br/>safety guard · pre-commit gate · session logging"]
        INS["Instructions<br/>(.github/instructions/)<br/>auto-loaded by file pattern"]
    end
    
    subgraph "Artifacts (agent-artifacts/)"
        RA --> |creates| RES["research/*.md"]
        PA --> |creates| PLN["plans/*.md"]
        WF --> |creates| HND["handoffs/*.md"]
        CR --> |creates| REV["reviews/*.md"]
    end
    
    subgraph "Configuration"
        CFG["workflow-config.json"]
    end
    
    WF --> CFG
    HK_A --> |reads| CFG
    INS --> |enriches| WF
```

## Component Types

```mermaid
graph LR
    subgraph "Invoked by User"
        P["Prompts (/command)"]
    end
    
    subgraph "Used by Prompts"
        AG["Agent Personas"]
        SK["Skills (SKILL.md)"]
    end
    
    subgraph "Automatic"
        I["Instructions"]
        HI["Instruction Hooks"]
        HA["Agent Lifecycle Hooks"]
        C["Config"]
    end
    
    P --> |"agent: frontmatter"| AG
    P --> |"reads SKILL.md"| SK
    I --> |"enriches context"| P
    HI --> |"shapes output"| P
    HA --> |"guards actions"| P
    C --> |configures| P
```

| Type | Invocation | Context | Purpose |
| ------ | ------------ | --------- | --------- |
| **Prompts** | `/command` | On invoke · High | User-initiated multi-step workflows |
| **Skills** | SKILL.md packages | Metadata auto, body on-demand · Low–Medium | Self-contained single-purpose actions |
| **Agent Personas** | Prompt `agent:` frontmatter | Loaded with prompt execution · Medium | Shared tool/instruction configs for prompt workflows |
| **Instruction Hooks** | Automatic | Auto on Copilot action · Low | Shape generated content (commit msgs, reviews, tests) |
| **Agent Lifecycle Hooks** | Automatic | Auto on agent events · Low | Guardrails and gates (safety guard, pre-commit, session logging) |
| **Instructions** | Auto-loaded | Auto on file match · Medium | Static rules by file pattern |
| **Config** | Referenced | On-demand · Low | Central settings |

> **Prompts vs Skills**: Prompts use `.prompt.md` files with frontmatter for multi-step interactive workflows. Skills use `SKILL.md` in `.github/skills/{name}/` directories — self-contained packages with optional `references/` for templates. Instruction hooks live in `.vscode/settings.json` and shape Copilot-generated content. Agent lifecycle hooks live in `.github/hooks/` and run shell scripts on events like `sessionStart` and `preToolUse`.

## Workflow Selection

```mermaid
flowchart TD
    START([New Task]) --> Q1{Single repo?}
    Q1 --> |Yes| Q2{< 2 hours?}
    Q1 --> |No| Q3{Parity or E2E?}
    
    Q2 --> |Yes| SF["/mslearn-small-feature"]
    Q2 --> |No| LF["/mslearn-large-feature"]
    
    Q3 --> |Parity| PF["/mslearn-parity-feature"]
    Q3 --> |E2E| LF
    
    SF --> IMPL([Implement])
    LF --> RES["/research-codebase"] --> PLAN["/create-plan"] --> IMPL
    PF --> RES
    
    IMPL --> DONE{Done?}
    DONE --> |"Ready to ship"| SHIP["/mslearn-ship-it"]
    DONE --> |"Stopping for now"| HO["/mslearn-create-handoff"]
    
    HO --> LATER([Resume later])
    LATER --> RESUME["/mslearn-resume-handoff"]
```

## Artifact Flow

```mermaid
sequenceDiagram
    participant U as User
    participant R as /research-codebase
    participant P as /create-plan
    participant I as /implement-plan
    participant A as Artifacts
    
    U->>R: /research-codebase [topic]
    R->>A: Creates research/*.md
    R-->>U: ⏸️ PAUSED - Review artifact
    
    U->>P: /create-plan [from research]
    P->>A: Reads research/*.md
    P->>A: Creates plans/*.md
    P-->>U: ⏸️ PAUSED - Review plan
    
    U->>I: /implement-plan [phase]
    I->>A: Reads plans/*.md
    I->>I: Modifies codebase
    I-->>U: Phase complete
```

## Directory Structure

```text
copilot-config/
├── README.md                    # This file - system overview
├── WORKFLOWS.md                 # Detailed workflow documentation
├── .github/
│   ├── config/
│   │   └── workflow-config.json # Central configuration
│   ├── agents/                  # Agent personas (referenced via prompt agent: frontmatter)
│   ├── prompts/                 # User-invoked workflows
│   │   ├── mslearn-small-feature.prompt.md
│   │   ├── mslearn-large-feature.prompt.md
│   │   ├── mslearn-parity-feature.prompt.md
│   │   ├── mslearn-create-plan.prompt.md
│   │   ├── mslearn-implement-plan.prompt.md
│   │   ├── mslearn-research-codebase.prompt.md
│   │   ├── mslearn-ship-it.prompt.md
│   │   ├── mslearn-review-it.prompt.md
│   │   ├── mslearn-update-plan.prompt.md
│   │   ├── mslearn-resume-handoff.prompt.md
│   │   ├── mslearn-create-handoff.prompt.md
│   │   ├── mslearn-create-ado-workitems.prompt.md
│   │   ├── mslearn-assign-swe.prompt.md
│   │   ├── mslearn-explain-pr.prompt.md
│   │   ├── mslearn-pre-commit.prompt.md
│   │   ├── mslearn-prune-worktree.prompt.md
│   │   └── mslearn-create-worktree.prompt.md
│   ├── skills/                  # Self-contained single-purpose actions (CLI-loadable)
│   │   ├── mslearn-assign-swe/             # SKILL.md
│   │   ├── mslearn-create-ado-workitems/   # SKILL.md + references/templates.md
│   │   ├── mslearn-create-handoff/         # SKILL.md + references/template.md
│   │   ├── mslearn-create-plan/            # SKILL.md
│   │   ├── mslearn-create-worktree/        # SKILL.md
│   │   ├── mslearn-delegate-devbox/        # SKILL.md
│   │   ├── mslearn-devbox-status/          # SKILL.md
│   │   ├── mslearn-explain-pr/             # SKILL.md + references/template.md
│   │   ├── mslearn-implement-plan/         # SKILL.md
│   │   ├── mslearn-large-feature/          # SKILL.md
│   │   ├── mslearn-parity-feature/         # SKILL.md
│   │   ├── mslearn-pre-commit/             # SKILL.md
│   │   ├── mslearn-prune-worktree/         # SKILL.md
│   │   ├── mslearn-research-codebase/      # SKILL.md
│   │   ├── mslearn-resume-handoff/         # SKILL.md
│   │   ├── mslearn-review-it/              # SKILL.md
│   │   ├── mslearn-session-learnings/      # SKILL.md + references/template.md
│   │   ├── mslearn-ship-it/                # SKILL.md
│   │   ├── mslearn-small-feature/          # SKILL.md
│   │   └── mslearn-update-plan/            # SKILL.md
│   ├── hooks/                   # Agent lifecycle hooks
│   │   ├── copilot-agent-hooks.json  # Hook config
│   │   └── scripts/                  # Shell scripts for hooks
│   └── instructions/            # Auto-loaded rules
│       └── azure-devops-workitems.instructions.md
├── .vscode/
│   └── settings.json            # Copilot hooks (commit, review, test)
├── vscode-extension/            # MSLearn Copilot Agents extension
└── agent-artifacts/             # Agent outputs (gitignored)
    ├── research/                # Research documents
    ├── plans/                   # Implementation plans
    ├── handoffs/                # Session handoffs
    └── reviews/                 # Code review documents
```

## Key Concepts

### Pause Points

Research and planning agents **pause after creating artifacts** to allow user review:

```text
✅ Research complete!
⏸️ PAUSED FOR REVIEW

When ready:
  @mslearn-planning Create plan from: {artifact path}
```

### Mermaid Diagrams

All artifacts include Mermaid diagrams for context efficiency:

- Research: Architecture + data flow diagrams
- Plans: Architecture overview + phase dependencies
- Handoffs: Component relationships + current flow

Diagrams help agents understand systems **without re-reading files**.

### Configuration

Two-layer config: `.env` for personal settings, `workflow-config.json` for shared structure.

- **`.env`**: alias, email, ADO assignee, area path, org, project (see [Environment Configuration](#environment-configuration))
- **`workflow-config.json`**: `${ENV_VAR}` placeholders, repo commands, preview URLs, artifact patterns
- **Setup**: `cp .env.example .env` then edit with your values

## Commands Reference

### Workflows (multi-step, interactive)

| Command | Description |
| --------- | ------------- |
| `/mslearn-small-feature` | Quick feature implementation (< 2 hours, single repo) |
| `/mslearn-large-feature` | Complex multi-repo feature with research and planning |
| `/mslearn-parity-feature` | Port feature between repos |
| `/mslearn-create-plan` | Create detailed implementation plans |
| `/mslearn-implement-plan` | Execute plan phases with verification |
| `/mslearn-research-codebase` | Document codebase without evaluation |
| `/mslearn-ship-it` | Commit, push, create PR |
| `/mslearn-review-it` | Review PR branch |
| `/mslearn-update-plan` | Sync plan with codebase status |
| `/mslearn-resume-handoff` | Resume from handoff document |
| `/mslearn-create-handoff` | Create a session handoff document |
| `/mslearn-create-ado-workitems` | Create ADO work items from a plan |
| `/mslearn-assign-swe` | Assign GitHub SWE to a work item |
| `/mslearn-explain-pr` | Generate PR explanation documentation |
| `/mslearn-pre-commit` | Run repository quality checks |
| `/mslearn-prune-worktree` | Remove worktrees and clean up resources |
| `/mslearn-create-worktree` | Create worktree with auth, deps, and agent symlinks |

### Skills (CLI-loadable; SKILL.md packages in `.github/skills/`)

Each prompt has a matching `mslearn-*` skillso workflows are discoverable in Copilot CLI (which doesn't load `.prompt.md`). In CLI, the agent picks a skill based on your phrasing — no slash command needed.

| Skill | Description |
| ----- | ----------- |
| `mslearn-assign-swe` | Assign GitHub SWE to work item |
| `mslearn-create-ado-workitems` | Create ADO items from plan |
| `mslearn-create-handoff` | Save session context for later |
| `mslearn-create-plan` | Create detailed implementation plan |
| `mslearn-create-worktree` | Create worktree with auth and npm install |
| `mslearn-delegate-devbox` | Delegate task to Dev Box for unattended execution |
| `mslearn-devbox-status` | Check status of a Dev Box delegated job |
| `mslearn-explain-pr` | Generate PR explanation document |
| `mslearn-implement-plan` | Execute plan phases with verification |
| `mslearn-large-feature` | Complex multi-repo feature workflow |
| `mslearn-parity-feature` | Port feature between repos |
| `mslearn-pre-commit` | Run quality gate checks |
| `mslearn-prune-worktree` | Remove worktrees and workspace files |
| `mslearn-research-codebase` | Document codebase without evaluation |
| `mslearn-resume-handoff` | Resume from handoff document |
| `mslearn-review-it` | Review PR branch |
| `mslearn-session-learnings` | Capture session learnings as self-healing patches |
| `mslearn-ship-it` | Commit, push, create PR with template |
| `mslearn-small-feature` | Quick feature implementation |
| `mslearn-update-plan` | Sync plan with codebase status |

### Hooks

#### Instruction Hooks (`.vscode/settings.json`)

| Hook | Trigger | What It Does |
| ---- | ------- | ------------ |
| Commit message generation | Copilot generates commit message | Enforces conventional commits format |
| Code review instructions | Copilot reviews code | Applies Learn platform standards |
| Test generation instructions | Copilot generates tests | Applies Jest/TypeScript conventions |

#### Agent Lifecycle Hooks (`.github/hooks/`)

| Hook | Event | Script | What It Does |
| ---- | ----- | ------ | ------------ |
| Safety guard | `preToolUse` | `safety-guard.sh/ps1` | Blocks destructive commands, force pushes to protected branches, edits to CI/CD configs |
| Pre-commit gate | `preToolUse` | `pre-commit-gate.sh/ps1` | Runs repo-specific quality checks before `git commit` |
| Session start | `sessionStart` | `setup-node.sh` | Installs Node.js/npm in SWE agent containers |
| Session logging | `sessionStart` | `session-start-log.sh` | Logs session metadata for diagnostics |
| Session end | `sessionEnd` | `session-end-learnings.sh/ps1` | Writes marker for learnings extraction |

### Agents

| Agent Persona | Description |
| ------- | ------------- |
| `mslearn-research` | Deep codebase research and documentation |
| `mslearn-planning` | Create implementation plans |
| `mslearn-implementation` | Execute plan phases |
| `mslearn-code-review` | Review code changes |

## Documentation

- **[WORKFLOWS.md](WORKFLOWS.md)** - Detailed workflow usage with examples
- **[workflow-config.json](.github/config/workflow-config.json)** - Configuration reference
