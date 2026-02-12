# Copilot Workflow Automation Config

This repo contains GitHub Copilot workflow automation for Microsoft Learn platform development across multiple repositories.

## Architecture

```
.github/
├── agents/         # Autonomous agents (@mention) - spawn in isolated context
├── prompts/        # Workflows (/command) - run in shared context
├── skills/         # Self-contained single-purpose actions (SKILL.md packages)
├── config/         # workflow-config.json - central settings
└── instructions/   # Auto-loaded rules by file pattern
.vscode/
└── settings.json   # Copilot hooks (commit messages, review, test generation)
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
- Loaded by the MSLearn Copilot Agents VS Code extension

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
- Frontmatter: `description`, `mode: agent` (required for tool access)
- Prompts run in **shared context** with user chat
- Can orchestrate agents via `@agent-name` references
- Used for **Workflows**: Multi-step interactive processes (e.g., `/mslearn-large-feature`)

### Skill Packages (`.github/skills/{name}/SKILL.md`)
- Frontmatter: `name`, `description` (only these two fields)
- Self-contained packages with optional `references/` for templates and domain knowledge
- Used for **Skills**: Single-purpose focused actions (e.g., create ADO work items, handoffs)
- Follow progressive disclosure: keep SKILL.md concise, split details to `references/`

### Copilot Hooks (`.vscode/settings.json`)
- Automatic instructions applied when Copilot performs specific actions
- `github.copilot.chat.commitMessageGeneration.instructions` - Conventional commits format
- `github.copilot.chat.reviewSelection.instructions` - Learn platform review standards
- `github.copilot.chat.testGeneration.instructions` - Jest/TypeScript test conventions

### When to Use Agents vs Prompts vs Skills
| Use **Agent** when: | Use **Prompt** when: | Use **Skill** when: |
|---------------------|----------------------|---------------------|
| Task requires deep research | Multi-step interactive workflow | Single focused action |
| Need isolated context | Need to see user's chat history | Creating/assigning artifacts |
| Autonomous multi-step work | Orchestrating multiple agents | Running quality gates |
| Producing artifacts | Complex feature implementation | Template-driven output |

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

## Available Agents (`@mention`)

Agents run in isolated context for autonomous, multi-step work:

| Agent | Purpose |
|-------|---------|
| `@mslearn-research` | Deep codebase research and documentation |
| `@mslearn-planning` | Create detailed implementation plans |
| `@mslearn-implementation` | Execute plans step by step |
| `@mslearn-code-review` | Review code for quality and patterns |
| `@mslearn-test` | Test strategy and generation |

### Sub-Agents (used by main agents)

| Agent | Purpose |
|-------|---------|
| `@mslearn-codebase-locator` | Find WHERE files/components exist |
| `@mslearn-codebase-analyzer` | Analyze HOW code works |
| `@mslearn-codebase-pattern-finder` | Find examples of patterns |

## Available Workflows (`/command`)

Multi-step interactive workflows:

| Command | Purpose |
|---------|---------|
| `/mslearn-small-feature` | Quick implementation (< 2 hours) |
| `/mslearn-large-feature` | Multi-repo, multi-phase features |
| `/mslearn-parity-feature` | Port feature between repos |
| `/mslearn-create_plan` | Create implementation plans |
| `/mslearn-implement_plan` | Execute plan phases |
| `/mslearn-research_codebase` | Document codebase as-is |
| `/mslearn-ship-it` | Commit, push, create PR |
| `/mslearn-review-it` | Review PR branch |
| `/mslearn-update-plan` | Sync plan with codebase |
| `/mslearn-resume_handoff` | Resume from handoff document |

## Available Skills (`.github/skills/`)

Self-contained single-purpose action packages:

| Skill | Location | Purpose |
|-------|----------|--------|
| `create-ado-workitems` | `.github/skills/create-ado-workitems/` | Create ADO work items from plan |
| `assign-swe` | `.github/skills/assign-swe/` | Assign GitHub SWE to work item |
| `create-handoff` | `.github/skills/create-handoff/` | Create session handoff document |
| `explain-pr` | `.github/skills/explain-pr/` | Generate PR explanation document |
| `pre-commit` | `.github/skills/pre-commit/` | Run quality gate checks |

## Copilot Hooks (automatic)

Configured in `.vscode/settings.json`, applied automatically:

| Hook | When Applied |
|------|-------------|
| Commit message generation | Copilot generates a commit message |
| Code review instructions | Copilot reviews selected code |
| Test generation instructions | Copilot generates tests |

## Loading Behavior

- **Agents** (`.agent.md`): Loaded by MSLearn Copilot Agents extension, invoked with `@agent-name`
- **Prompts** (`.prompt.md`): Loaded when invoked with `/command`, run with `mode: agent` for tool access
- **Skills** (`SKILL.md`): Self-contained packages in `.github/skills/{name}/`, loaded on-demand
- **Instructions** (`.instructions.md`): Auto-loaded based on `applyTo` file patterns
- **Hooks** (`.vscode/settings.json`): Auto-applied by VS Code Copilot for specific actions

## Adding New Components

**New Agent**: Create `.github/agents/{name}.agent.md` with frontmatter defining `name`, `description`, `tools`, `model`

**New Prompt**: Create `.github/prompts/{name}.prompt.md` with `description` and `mode: agent` frontmatter

**New Skill**: Create `.github/skills/{name}/SKILL.md` with `name` and `description` frontmatter. Add optional `references/` directory for templates and domain knowledge. Follow progressive disclosure — keep SKILL.md under 500 lines.

**New Hook**: Add to `.vscode/settings.json` under the appropriate `github.copilot.chat.*` setting

**New Repo Config**: Add entry to `repositories` in `workflow-config.json` with `defaultBranch`, `preCommitCommand`, `previewUrlPattern`

## Artifacts Convention

Filename patterns (from config):
- Research: `{date}-{ticketId}-{description}.md`
- Plans: `{date}-{ticketId}-{description}-plan.md`  
- Handoffs: `{date}_{time}_{ticketId}_{description}.md`

Include Mermaid diagrams in research artifacts for quick system understanding.
