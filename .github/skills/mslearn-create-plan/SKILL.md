---
description: Create implementation plans with thorough research (no thoughts directory)
---

# Implementation Plan

You are tasked with creating detailed implementation plans through an interactive, iterative process. You should be skeptical, thorough, and work collaboratively with the user to produce high-quality technical specifications.

## Initial Response

When this command is invoked:

1. **Check if parameters were provided**:
   - If a file path or ticket reference was provided as a parameter, skip the default message
   - Immediately read any provided files FULLY
   - Begin the research process

2. **If no parameters provided**, respond with:
```
I'll help you create a detailed implementation plan. Let me start by understanding what we're building.

Please provide:
1. The task/ticket description (or reference to a ticket file)
2. Any relevant context, constraints, or specific requirements
3. Links to related research or previous implementations

I'll analyze this information and work with you to create a comprehensive plan.

Tip: You can also invoke this command with a ticket file directly: `/create_plan thoughts/shared/tickets/eng_1234.md`
For deeper analysis, try: `/create_plan think deeply about thoughts/shared/tickets/eng_1234.md`
```

Then wait for the user's input.

## Process Steps

### Step 1: Context Gathering & Initial Analysis

1. **Read all mentioned files immediately and FULLY**:
   - Ticket files (e.g., `thoughts/shared/tickets/eng_1234.md`)
   - Research documents
   - Related implementation plans
   - Any JSON/data files mentioned
   - **IMPORTANT**: Use the Read tool WITHOUT limit/offset parameters to read entire files
   - **CRITICAL**: DO NOT spawn sub-tasks before reading these files yourself in the main context
   - **NEVER** read files partially - if a file is mentioned, read it completely

2. **Conduct initial research to gather context**:
   Before asking the user any questions, use search and read tools directly to research in parallel:

   - Use `semantic_search` to find all files related to the ticket/task
   - Use `grep_search` to find exact references, imports, and patterns
   - Use `read_file` to understand how the current implementation works
   - If a Linear ticket is mentioned, use the `/linear` skill to get full ticket details

   This direct research will:
   - Find relevant source files, configs, and tests
   - Identify the specific directories to focus on
   - Trace data flow and key functions
   - Provide detailed file:line references

3. **Read all files identified by research tasks**:
   - After research tasks complete, read ALL files they identified as relevant
   - Read them FULLY into the main context
   - This ensures you have complete understanding before proceeding

4. **Analyze and verify understanding**:
   - Cross-reference the ticket requirements with actual code
   - Identify any discrepancies or misunderstandings
   - Note assumptions that need verification
   - Determine true scope based on codebase reality

5. **Present informed understanding and focused questions**:
   ```
   Based on the ticket and my research of the codebase, I understand we need to [accurate summary].

   I've found that:
   - [Current implementation detail with file:line reference]
   - [Relevant pattern or constraint discovered]
   - [Potential complexity or edge case identified]

   Questions that my research couldn't answer:
   - [Specific technical question that requires human judgment]
   - [Business logic clarification]
   - [Design preference that affects implementation]
   ```

   Only ask questions that you genuinely cannot answer through code investigation.

### Step 2: Research & Discovery

After getting initial clarifications:

1. **If the user corrects any misunderstanding**:
   - DO NOT just accept the correction
   - Spawn new research tasks to verify the correct information
   - Read the specific files/directories they mention
   - Only proceed once you've verified the facts yourself

2. **Create a research todo list** using TodoWrite to track exploration tasks

3. **Conduct parallel research for comprehensive discovery**:
   - Run multiple search and read operations concurrently to investigate different aspects:

   **For deeper investigation:**
   - `semantic_search` — To find conceptually related files (e.g., "find all files that handle [specific component]")
   - `grep_search` — To find exact patterns, imports, and references
   - `read_file` — To understand implementation details of specific files
   - `file_search` — To find similar features we can model after

   **For related tickets:**
   - Use the `/linear` skill to search for similar issues or past implementations

   Direct tool usage:
   - Finds the right files and code patterns
   - Identifies conventions and patterns to follow
   - Reveals integration points and dependencies
   - Returns specific file:line references
   - Finds tests and examples

4. **Wait for ALL research to complete** before proceeding

5. **Present findings and design options**:
   ```
   Based on my research, here's what I found:

   **Current State:**
   - [Key discovery about existing code]
   - [Pattern or convention to follow]

   **Design Options:**
   1. [Option A] - [pros/cons]
   2. [Option B] - [pros/cons]

   **Open Questions:**
   - [Technical uncertainty]
   - [Design decision needed]

   Which approach aligns best with your vision?
   ```

### Step 3: Plan Structure Development

Once aligned on approach:

1. **Create initial plan outline**:
   ```
   Here's my proposed plan structure:

   ## Overview
   [1-2 sentence summary]

   ## Implementation Phases:
   1. [Phase name] - [what it accomplishes]
   2. [Phase name] - [what it accomplishes]
   3. [Phase name] - [what it accomplishes]

   Does this phasing make sense? Should I adjust the order or granularity?
   ```

2. **Get feedback on structure** before writing details

### Step 4: Detailed Plan Writing

After structure approval:

1. **Write the plan** to `copilot-config/agent-artifacts/plans/YYYY-MM-DD-ENG-XXXX-description.md`
   - Format: `YYYY-MM-DD-ENG-XXXX-description.md` where:
     - YYYY-MM-DD is today's date
     - ENG-XXXX is the ticket number (omit if no ticket)
     - description is a brief kebab-case description
   - Examples:
     - With ticket: `2025-01-08-ENG-1478-parent-child-tracking.md`
     - Without ticket: `2025-01-08-improve-error-handling.md`
2. **Use this template structure**:

````markdown
# [Feature/Task Name] Implementation Plan

## Overview

[Brief description of what we're implementing and why]

## Current State Analysis

[What exists now, what's missing, key constraints discovered]

## Desired End State

[A Specification of the desired end state after this plan is complete, and how to verify it]

### Key Discoveries:
- [Important finding with file:line reference]
- [Pattern to follow]
- [Constraint to work within]

## What We're NOT Doing

[Explicitly list out-of-scope items to prevent scope creep]

## Implementation Approach

[High-level strategy and reasoning]

## Phase 1: [Descriptive Name]

### Overview
[What this phase accomplishes]

### Changes Required:

#### 1. [Component/File Group]
**File**: `path/to/file.ext`
**Changes**: [Summary of changes]

```[language]
// Specific code to add/modify
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `go build ./...`
- [ ] Tests pass (if applicable): `go test ./...`
- [ ] BAML client regenerated (if .baml files changed)

#### Manual Verification:
- [ ] Feature works as expected when tested
- [ ] No regressions in related features

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 2: [Descriptive Name]

[Similar structure with both automated and manual success criteria...]

---

## Verification Strategy

### Automated Checks:
- Code compiles: `go build ./...`
- Existing tests pass: `go test ./...` (if applicable)

### Manual Verification:
1. [Specific step to verify feature works]
2. [Edge case to verify]

*Note: Only add formal tests when they provide clear value (critical business logic, complex algorithms, regression prevention).*

## Performance Considerations

[Any performance implications or optimizations needed]

## Migration Notes

[If applicable, how to handle existing data/systems]

## References

- Original ticket: `copilot-config/agent-artifacts/research/eng_XXXX.md`
- Related research: `copilot-config/agent-artifacts/research/[relevant].md`
- Similar implementation: `[file:line]`
````

### Step 5: Review

1. **Present the draft plan location**:
   ```
   I've created the initial implementation plan at:
   `copilot-config/agent-artifacts/plans/YYYY-MM-DD-ENG-XXXX-description.md`

   Please review it and let me know:
   - Are the phases properly scoped?
   - Are the success criteria specific enough?
   - Any technical details that need adjustment?
   - Missing edge cases or considerations?
   ```

2. **Iterate based on feedback** - be ready to:
   - Add missing phases
   - Adjust technical approach
   - Clarify success criteria (both automated and manual)
   - Add/remove scope items

3. **Continue refining** until the user is satisfied

## Important Guidelines

1. **Be Skeptical**:
   - Question vague requirements
   - Identify potential issues early
   - Ask "why" and "what about"
   - Don't assume - verify with code

2. **Be Interactive**:
   - Don't write the full plan in one shot
   - Get buy-in at each major step
   - Allow course corrections
   - Work collaboratively

3. **Be Thorough**:
   - Read all context files COMPLETELY before planning
   - Research actual code patterns using parallel tool calls
   - Include specific file paths and line numbers
   - Write measurable success criteria with clear automated vs manual distinction
   - Use Go tooling directly: `go build ./...`, `go test ./...`

4. **Be Practical**:
   - Focus on incremental, testable changes
   - Consider migration and rollback
   - Think about edge cases
   - Include "what we're NOT doing"

5. **Track Progress**:
   - Use TodoWrite to track planning tasks
   - Update todos as you complete research
   - Mark planning tasks complete when done

6. **No Open Questions in Final Plan**:
   - If you encounter open questions during planning, STOP
   - Research or ask for clarification immediately
   - Do NOT write the plan with unresolved questions
   - The implementation plan must be complete and actionable
   - Every decision must be made before finalizing the plan

## Success Criteria Guidelines

**Separate success criteria into two categories:**

1. **Automated Verification** (can be run by execution agents):
   - Code compiles: `go build ./...`
   - Tests pass (if applicable): `go test ./...`
   - BAML regenerated (if .baml files changed)

2. **Manual Verification** (requires human testing):
   - Feature works as expected
   - No regressions in related features
   - Edge cases verified

**Format example:**
```markdown
### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `go build ./...`
- [ ] Tests pass: `go test ./...`
- [ ] API endpoint returns 200: `curl localhost:8081/api/new-endpoint`

#### Manual Verification:
- [ ] Feature works as expected when tested
- [ ] No regressions in related features
```

*Only add formal tests when they provide clear value (critical paths, complex logic, regression prevention).*

## Common Patterns

### For Database Changes:
- Start with schema/migration
- Add store methods
- Update business logic
- Expose via API
- Update clients

### For New Features:
- Research existing patterns first
- Start with data model
- Build backend logic
- Add API endpoints
- Implement UI last

### For Refactoring:
- Document current behavior
- Plan incremental changes
- Maintain backwards compatibility
- Include migration strategy

## Research Best Practices

When conducting codebase research:

1. **Run multiple searches in parallel** for efficiency
2. **Each search should be focused** on a specific aspect
3. **Use the right tool for each task**:
   - `semantic_search` for conceptual matches
   - `grep_search` for exact strings and patterns
   - `file_search` for locating files by name
   - `read_file` for understanding implementations
4. **Be specific about directories**:
   - If the ticket mentions "DocService", search within `DocService/` directory
   - If it mentions "JobService", focus on `JobService/` directory
   - Use `includePattern` parameter in grep_search for targeted results
5. **Request specific file:line references** in your notes
6. **Complete all research before synthesizing**
7. **Verify findings**:
   - If a search returns unexpected results, run follow-up searches
   - Cross-check findings by reading the actual files
   - Don't accept assumptions — verify with code

## Example Interaction Flow

```
User: /create_plan
Assistant: I'll help you create a detailed implementation plan...

User: We need to add parent-child tracking for Claude sub-tasks. See thoughts/shared/tickets/eng_1478.md
Assistant: Let me read that ticket file completely first...

[Reads file fully]

Based on the ticket, I understand we need to track parent-child relationships for Claude sub-task events in the hld daemon. Before I start planning, I have some questions...

[Interactive process continues...]
```

