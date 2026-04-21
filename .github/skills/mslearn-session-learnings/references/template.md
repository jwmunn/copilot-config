---
date: {date}
session_id: {session_id}
repository: {repository}
branch: {branch}
topic: "{description}"
learnings_count: {count}
applied_count: {applied}
status: {draft|reviewed|applied}
---

# Session Learnings: {description}

## Session Summary

**Repository**: {repository}  
**Branch**: {branch}  
**Duration**: {approximate duration or "unknown"}  
**Primary task**: {what the session was about}

## Learnings

### Learning 1: {title}

- **Signal**: {correction|workaround|repetition|frustration|missing-context|wrong-pattern}
- **Confidence**: {high|medium|low}
- **User said**: "{relevant quote or paraphrase}"
- **Root cause**: {why the agent/prompt/skill got it wrong}

**Target file**: `{path to agent/prompt/skill/instruction}`  
**Change type**: {rule|example|guard|context|template}

**Suggested patch**:
```diff
  {3 lines of existing context}
+ {new line(s) to add}
  {3 lines of existing context}
```

**Rationale**: {why this change prevents the issue in future sessions}

---

### Learning 2: {title}

{same structure as above}

---

## Applied Changes

| # | Learning | Target File | Status |
|---|---------|-------------|--------|
| 1 | {title} | `{file}` | {pending\|applied\|skipped} |
| 2 | {title} | `{file}` | {pending\|applied\|skipped} |

## Meta

- **Generalizability**: {Is this learning specific to one repo/task or broadly applicable?}
- **Related learnings**: {Link to previous learnings artifacts if patterns recur}
- **Follow-up**: {Any manual review or testing needed after applying}
