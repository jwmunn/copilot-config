---
description: Explain what was done in a PR branch with research-style documentation
agent: mslearn-research
model: GPT-5.3-Codex (copilot)
---

# Explain PR

Generate comprehensive documentation explaining what was done in a PR branch — what changed, why, and how it fits the codebase.

## Instructions

Follow the skill instructions in `copilot-config/.github/skills/mslearn-explain-pr/SKILL.md`.

## Workflow

1. Identify the branch to explain (current branch or specified)
2. Gather changed files and diff against the repo's default branch
3. Analyze each changed file for purpose, patterns, and architectural decisions
4. Generate explanation document at `copilot-config/agent-artifacts/reviews/{date}-{branch}-explain.md`
5. Present summary with file count, key changes, and path to the generated document

