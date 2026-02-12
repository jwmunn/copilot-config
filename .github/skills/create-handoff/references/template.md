# Handoff Document Template

```markdown
---
date: [ISO 8601 timestamp with timezone]
researcher: [Agent/researcher name]
git_commit: [Current commit hash]
branch: [Current branch name]
repository: [Repository name]
topic: "[Feature/Task Name] Implementation Strategy"
tags: [implementation, strategy, relevant-component-names]
status: complete
last_updated: [YYYY-MM-DD]
last_updated_by: [Agent name]
type: implementation_strategy
---

# Handoff: CAS-XXX {concise description}

## Task(s)
{Description of tasks with status: completed, work in progress, planned/discussed.
Reference the implementation plan and/or research documents provided at session start.
Call out which phase you are on if working from a plan.}

## System Context (Mermaid Diagrams)

### Component Relationships
```mermaid
graph TB
    {key components and their relationships}
```

### Key Flow (if applicable)
```mermaid
sequenceDiagram
    {main flow being worked on}
```

## Critical References
{2-3 most important file paths: specs, architectural decisions, design docs. Leave blank if none.}

## Recent Changes
{Changes made in file:line syntax}

## Learnings
{Important discoveries: patterns, root causes, non-obvious knowledge.
Include explicit file paths.}

## Artifacts
{Exhaustive list of produced/updated artifacts as file paths and file:line references.}

## Action Items & Next Steps
{Ordered list of what the next agent should do.}

## Other Notes
{Relevant codebase locations, references, or other context that doesn't fit above.}
```
