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

Agents are discovered from `.github/agents/` relative to your **active file's repo**. Run the setup script once after cloning to make agents available from all sibling repos:

### One-Time Setup

```powershell
# Windows (PowerShell)
.\setup-agents.ps1

# macOS/Linux
./setup-agents.sh
```

This auto-discovers sibling repos and creates junctions/symlinks to copilot-config's agents folder.

### Options

```bash
# Preview changes without applying
./setup-agents.sh --dry-run

# Link specific repos only
./setup-agents.sh docs-ui feature-gap-wt

# Replace existing agents folders
./setup-agents.sh --force
```

### Manual Setup

If you prefer manual setup or need to add repos in different locations:

```powershell
# Windows (PowerShell) - Junction (no admin required)
New-Item -ItemType Junction -Path "{TARGET_REPO}\.github\agents" -Target "c:\repos\mslearn\copilot-config\.github\agents"
```

```bash
# macOS/Linux - Symlink
ln -s /path/to/copilot-config/.github/agents {TARGET_REPO}/.github/agents
```

### Notes

- **Junctions/symlinks are local** - each developer runs setup once
- If target repo has existing agents, use `--force` to replace or manually merge
- Agents have **full access to all repos** in the workspace regardless of discovery location

## System Architecture

```mermaid
graph TB
    subgraph "User Commands"
        P["/prompts"]
        A["@agents"]
    end
    
    subgraph "Orchestration Layer"
        P --> WF["Workflow Prompts<br/>(small-feature, large-feature, ship-it, etc.)"]
    end
    
    subgraph "Autonomous Agents"
        A --> RA["@research<br/>Deep analysis"]
        A --> PA["@planning<br/>Create plans"]
        A --> IA["@implementation<br/>Execute plans"]
        A --> CR["@code-review<br/>Review PRs"]
    end
    
    subgraph "Sub-Agents (called by main agents)"
        RA --> CL["codebase-locator"]
        RA --> CA["codebase-analyzer"]
        RA --> CP["codebase-pattern-finder"]
        PA --> CL
        PA --> CA
    end
    
    subgraph "Artifacts (agent-artifacts/)"
        RA --> |creates| RES["research/*.md"]
        PA --> |creates| PLN["plans/*.md"]
        WF --> |creates| HND["handoffs/*.md"]
        CR --> |creates| REV["reviews/*.md"]
    end
    
    subgraph "Configuration"
        CFG["workflow-config.json"]
        INS["instructions/*.md"]
    end
    
    WF --> CFG
    PA --> CFG
    IA --> CFG
```

## Component Types

```mermaid
graph LR
    subgraph "Invoked by User"
        P["Prompts (/slash)"]
        AG["Agents (@mention)"]
    end
    
    subgraph "Called by Agents"
        SUB["Sub-Agents"]
    end
    
    subgraph "Auto-Loaded"
        I["Instructions"]
        C["Config"]
    end
    
    P --> |orchestrates| AG
    AG --> |spawns| SUB
    I --> |applies to| AG
    C --> |configures| P
    C --> |configures| AG
```

| Type | Invocation | Context | Purpose |
| ------ | ------------ | --------- | --------- |
| **Prompts** | `/command` | Shared with chat | User-initiated workflows, orchestration |
| **Agents** | `@agent-name` | Isolated (own context) | Autonomous complex tasks |
| **Sub-Agents** | Called by agents | Isolated | Focused sub-tasks (locate, analyze, find patterns) |
| **Instructions** | Auto-loaded | Shared | Static rules by file pattern |
| **Config** | Referenced | Minimal | Central settings |

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
    LF --> RES["@mslearn-research"] --> PLAN["@mslearn-planning"] --> IMPL
    PF --> RES
    
    IMPL --> DONE{Done?}
    DONE --> |"Ready to ship"| SHIP["/mslearn-ship-it"]
    DONE --> |"Stopping for now"| HO["/mslearn-create_handoff"]
    
    HO --> LATER([Resume later])
    LATER --> RESUME["/mslearn-resume_handoff"]
```

## Artifact Flow

```mermaid
sequenceDiagram
    participant U as User
    participant R as @mslearn-research
    participant P as @mslearn-planning
    participant I as @mslearn-implementation
    participant A as Artifacts
    
    U->>R: @mslearn-research [topic]
    R->>A: Creates research/*.md
    R-->>U: ⏸️ PAUSED - Review artifact
    
    U->>P: @mslearn-planning [from research]
    P->>A: Reads research/*.md
    P->>A: Creates plans/*.md
    P-->>U: ⏸️ PAUSED - Review plan
    
    U->>I: @mslearn-implementation [phase]
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
│   ├── agents/                  # Autonomous agents
│   │   ├── mslearn-research.agent.md
│   │   ├── mslearn-planning.agent.md
│   │   ├── mslearn-implementation.agent.md
│   │   ├── mslearn-code-review.agent.md
│   │   ├── mslearn-multi-agent-startup.agent.md
│   │   └── (sub-agents: mslearn-codebase-*, mslearn-thoughts-*, mslearn-web-search-*)
│   ├── prompts/                 # User-invoked workflows
│   │   ├── mslearn-small-feature.prompt.md
│   │   ├── mslearn-large-feature.prompt.md
│   │   ├── mslearn-parity-feature.prompt.md
│   │   ├── mslearn-ship-it.prompt.md
│   │   ├── mslearn-review-it.prompt.md
│   │   ├── mslearn-update-plan.prompt.md
│   │   ├── mslearn-create-ado-workitems.prompt.md
│   │   ├── mslearn-assign-swe.prompt.md
│   │   ├── mslearn-pre-commit.prompt.md
│   │   ├── mslearn-create_handoff.prompt.md
│   │   ├── mslearn-create_plan.prompt.md
│   │   ├── mslearn-implement_plan.prompt.md
│   │   ├── mslearn-research_codebase.prompt.md
│   │   └── mslearn-resume_handoff.prompt.md
│   └── instructions/            # Auto-loaded rules
│       └── azure-devops-workitems.instructions.md
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

Central config at `.github/config/workflow-config.json`:

- User settings (alias, email)
- Azure DevOps settings
- Repository-specific commands (build, test, pre-commit)
- Preview URL patterns

## Commands Reference

### Workflows

| Command | Description |
| --------- | ------------- |
| `/mslearn-small-feature` | Quick feature implementation |
| `/mslearn-large-feature` | Complex multi-repo feature |
| `/mslearn-parity-feature` | Port feature between repos |
| `/mslearn-ship-it` | Commit, push, create PR |
| `/mslearn-review-it` | Review PR branch |
| `/mslearn-update-plan` | Sync plan with codebase status |

### Agents

| Agent | Description |
| ------- | ------------- |
| `@mslearn-research` | Deep codebase analysis |
| `@mslearn-planning` | Create implementation plans |
| `@mslearn-implementation` | Execute plan phases |
| `@mslearn-code-review` | Review code changes |
| `@mslearn-multi-agent-startup` | Setup parallel worktrees |

### Skills

| Command | Description |
| --------- | ------------- |
| `/mslearn-create-ado-workitems` | Create ADO items from plan |
| `/mslearn-assign-swe` | Assign GitHub SWE to work item |
| `/mslearn-pre-commit` | Run quality gate checks |

### Session Management

| Command | Description |
| --------- | ------------- |
| `/mslearn-create_handoff` | Save session for later |
| `/mslearn-resume_handoff` | Resume from handoff |

## Documentation

- **[WORKFLOWS.md](WORKFLOWS.md)** - Detailed workflow usage with examples
- **[workflow-config.json](.github/config/workflow-config.json)** - Configuration reference
