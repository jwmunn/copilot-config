# Copilot Workflow Automation Config

This repo contains GitHub Copilot workflow automation for Microsoft Learn platform development across multiple repositories.

## Architecture

```
.github/
├── agents/         # Autonomous agents (@mention) - spawn in isolated context
├── prompts/        # User workflows (/command) - run in shared context  
├── config/         # workflow-config.json - central settings
└── instructions/   # Auto-loaded rules by file pattern
agent-artifacts/    # Output directory (not committed)
├── research/       # Deep analysis documents
├── plans/          # Implementation plans
├── handoffs/       # Session continuity
└── reviews/        # PR reviews
```

## Key Patterns

### Agent Files (`.agent.md`)
- Frontmatter: `name`, `description`, `tools`, `model` 
- Agents run in **isolated context** - they cannot see main chat history

### Sub-Agent Hierarchy
```
@mslearn-research ──┬── mslearn-codebase-locator (find files/components)
            ├── mslearn-codebase-analyzer (analyze implementations)
            └── mslearn-codebase-pattern-finder (find code patterns)

@mslearn-planning ──┬── mslearn-codebase-locator
            └── mslearn-codebase-analyzer

@mslearn-implementation ── (uses plan artifacts directly)

@mslearn-code-review ── (standalone, no sub-agents)
```

### Prompt Files (`.prompt.md`)
- Frontmatter: `description` only
- Prompts run in **shared context** with user chat
- Can orchestrate agents via `@agent-name` references

### When to Use Agents vs Prompts
| Use **Agent** when: | Use **Prompt** when: |
|---------------------|----------------------|
| Task requires deep research | Quick, interactive workflow |
| Need isolated context (large analysis) | Need to see user's chat history |
| Autonomous multi-step work | Orchestrating multiple agents |
| Producing artifacts (research, plans) | Simple commands like `/mslearn-ship-it` |

### Configuration (`workflow-config.json`)
- `user`: alias, email, ADO settings (personalize per developer)
- `repositories`: repo-specific build/test/preview commands
- `azureDevOps`: org, project, work item patterns

### Token Substitution Variables
| Token | Source | Example Value |
|-------|--------|---------------|
| `{alias}` | `user.alias` | `jumunn` |
| `{adoAreaPath}` | `user.adoAreaPath` | `Engineering\POD\Xinxin-OctoPod` |
| `{id}` | Runtime (work item) | `123456` |
| `{repo}` | Runtime (git) | `docs-ui` |
| `{PrNumber}` | Runtime (PR creation) | `4521` |
| `{date}` | Runtime | `2026-02-04` |
| `{ticketId}` | User input | `AB#123456` |
| `{description}` | User input | `rating-system` |

## Common Workflows

| Command | Purpose |
|---------|---------|
| `/mslearn-small-feature` | Quick implementation (< 2 hours) |
| `/mslearn-large-feature` | Multi-repo, multi-phase features |
| `/mslearn-ship-it` | Commit, push, create PR |
| `@mslearn-research` | Deep codebase analysis |
| `@mslearn-planning` | Create implementation plans |

## Adding New Components

**New Agent**: Create `.github/agents/{name}.agent.md` with frontmatter defining `name`, `description`, `tools`, `model`

**New Prompt**: Create `.github/prompts/{name}.prompt.md` with `description` frontmatter

**New Repo Config**: Add entry to `repositories` in `workflow-config.json` with `defaultBranch`, `preCommitCommand`, `previewUrlPattern`

## Artifacts Convention

Filename patterns (from config):
- Research: `{date}-{ticketId}-{description}.md`
- Plans: `{date}-{ticketId}-{description}-plan.md`  
- Handoffs: `{date}_{time}_{ticketId}_{description}.md`

Include Mermaid diagrams in research artifacts for quick system understanding.
