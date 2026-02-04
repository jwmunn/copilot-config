# Copilot Workflow Automation

GitHub Copilot workflow automation for Microsoft Learn platform development.

## Quick Start

```
# Research a feature
@research Analyze the article rating system in docs-ui

# Create implementation plan
@planning Create plan from: copilot-config/agent-artifacts/research/{file}.md

# Implement
@implementation Execute Phase 1 of plan

# Ship it
/ship-it
```

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
|------|------------|---------|---------|
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
    
    Q2 --> |Yes| SF["/small-feature"]
    Q2 --> |No| LF["/large-feature"]
    
    Q3 --> |Parity| PF["/parity-feature"]
    Q3 --> |E2E| LF
    
    SF --> IMPL([Implement])
    LF --> RES["@research"] --> PLAN["@planning"] --> IMPL
    PF --> RES
    
    IMPL --> DONE{Done?}
    DONE --> |"Ready to ship"| SHIP["/ship-it"]
    DONE --> |"Stopping for now"| HO["/create_handoff"]
    
    HO --> LATER([Resume later])
    LATER --> RESUME["/resume_handoff"]
```

## Artifact Flow

```mermaid
sequenceDiagram
    participant U as User
    participant R as @research
    participant P as @planning
    participant I as @implementation
    participant A as Artifacts
    
    U->>R: @research [topic]
    R->>A: Creates research/*.md
    R-->>U: ⏸️ PAUSED - Review artifact
    
    U->>P: @planning [from research]
    P->>A: Reads research/*.md
    P->>A: Creates plans/*.md
    P-->>U: ⏸️ PAUSED - Review plan
    
    U->>I: @implementation [phase]
    I->>A: Reads plans/*.md
    I->>I: Modifies codebase
    I-->>U: Phase complete
```

## Directory Structure

```
copilot-config/
├── README.md                    # This file - system overview
├── WORKFLOWS.md                 # Detailed workflow documentation
├── .github/
│   ├── config/
│   │   └── workflow-config.json # Central configuration
│   ├── agents/                  # Autonomous agents
│   │   ├── research.agent.md
│   │   ├── planning.agent.md
│   │   ├── implementation.agent.md
│   │   ├── code-review.agent.md
│   │   ├── multi-agent-startup.agent.md
│   │   └── (sub-agents: codebase-*, thoughts-*, web-search-*)
│   ├── prompts/                 # User-invoked workflows
│   │   ├── small-feature.prompt.md
│   │   ├── large-feature.prompt.md
│   │   ├── parity-feature.prompt.md
│   │   ├── ship-it.prompt.md
│   │   ├── review-it.prompt.md
│   │   ├── update-plan.prompt.md
│   │   ├── create-ado-workitems.prompt.md
│   │   ├── assign-swe.prompt.md
│   │   ├── pre-commit.prompt.md
│   │   ├── create_handoff.prompt.md
│   │   ├── create_plan.prompt.md
│   │   ├── implement_plan.prompt.md
│   │   ├── research_codebase.prompt.md
│   │   └── resume_handoff.prompt.md
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
```
✅ Research complete!
⏸️ PAUSED FOR REVIEW

When ready:
  @planning Create plan from: {artifact path}
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
|---------|-------------|
| `/small-feature` | Quick feature implementation |
| `/large-feature` | Complex multi-repo feature |
| `/parity-feature` | Port feature between repos |
| `/ship-it` | Commit, push, create PR |
| `/review-it` | Review PR branch |
| `/update-plan` | Sync plan with codebase status |

### Agents
| Agent | Description |
|-------|-------------|
| `@research` | Deep codebase analysis |
| `@planning` | Create implementation plans |
| `@implementation` | Execute plan phases |
| `@code-review` | Review code changes |
| `@multi-agent-startup` | Setup parallel worktrees |

### Skills
| Command | Description |
|---------|-------------|
| `/create-ado-workitems` | Create ADO items from plan |
| `/assign-swe` | Assign GitHub SWE to work item |
| `/pre-commit` | Run quality gate checks |

### Session Management
| Command | Description |
|---------|-------------|
| `/create_handoff` | Save session for later |
| `/resume_handoff` | Resume from handoff |

## Documentation

- **[WORKFLOWS.md](WORKFLOWS.md)** - Detailed workflow usage with examples
- **[workflow-config.json](.github/config/workflow-config.json)** - Configuration reference
