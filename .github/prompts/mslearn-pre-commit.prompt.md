---
description: Pre-commit quality gate - run before committing changes to catch issues early
agent: mslearn-implementation
model: Claude Opus 4.6 (fast mode) (Preview) (copilot)
---

# Pre-Commit Quality Check

Run repository-specific quality checks before committing to catch build, type, lint, and security issues early.

## Instructions

Follow the skill instructions in `copilot-config/.github/skills/mslearn-pre-commit/SKILL.md`.

## Workflow

1. Identify the current repository from `git rev-parse --show-toplevel`
2. Look up the repo-specific pre-commit command from `workflow-config.json`
3. Run the quality gate command at the repo root
4. Report pass/fail with parsed error details and suggested fixes
5. For `--skip` mode, warn prominently and bypass (emergency hotfixes only)

