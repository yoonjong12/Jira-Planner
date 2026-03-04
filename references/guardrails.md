# Jira Planner Guardrails

Hook-based workflow enforcement system.

## Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                    Jira Planner Guardrails                     │
├─────────────────────────────────────────────────────────────┤
│ PreToolUse Hooks:                                           │
│   ├── jira_create_issue → Block Jira creation without approval│
│   ├── TaskCreate → Block task creation without plan file     │
│   └── Write(space/) → Block malformed plan files            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Hook 1: Jira Issue Creation Guard

**Target Workflow:** EpicToStory, StoryToSubtask

**Blocking Condition:** Calling jira_create_issue without user approval

See `scripts/jira-creation-guard.sh` for implementation.

---

## Hook 2: SubtaskToNanotask CP2 Guard

**Target Workflow:** SubtaskToNanotask

**Blocking Condition:** Calling TaskCreate without plan.md

```bash
#!/bin/bash
# scripts/subtask-planning-guard.sh
# (Already created)
```

---

## Hook 3: Task Delete Guard

**Target Workflow:** SubtaskToNanotask

**Behavior:**
- `TaskUpdate(status=deleted)` on **completed** task → **ALLOWED** (checkpoint compaction)
- `TaskUpdate(status=deleted)` on **active** task (pending/in_progress) → **BLOCKED**
- `TaskUpdate(status=completed)` → Allowed, with reminder to update status.md

```bash
#!/bin/bash
# scripts/task-delete-guard.sh
# Reads task status from ~/.claude/tasks/{list_id}/{task_id}.json
# Only blocks deletion of non-completed tasks
```

---

## Hook 4: Plan File Format Validator

**Target:** When Write tool writes to space/ directory

**Validation:**
- plan.md: TASK_LIST_ID header, Nanotasks section required
- {subtask}-{N}.md: Goal section required; Diffs + Verify required for type: commit

```bash
#!/bin/bash
# scripts/plan-format-validator.sh

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ "$TOOL_NAME" != "Write" ]; then
    exit 0
fi

# Ignore outside space/ directory
if [[ "$FILE_PATH" != *"/space/"* ]]; then
    exit 0
fi

CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')

# plan.md validation
if [[ "$FILE_PATH" == */plan.md ]]; then
    if ! echo "$CONTENT" | grep -q "## Nanotasks"; then
        jq -n '{
            hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: "plan.md must contain ## Nanotasks section"
            }
        }'
        exit 0
    fi
fi

# nanotask plan file validation ({PROJECT_KEY}-{SUBTASK}-{N}.md)
if [[ "$FILE_PATH" =~ [A-Z]+-[0-9]+-[0-9]+\.md$ ]]; then
    MISSING=""
    echo "$CONTENT" | grep -q "## Goal" || MISSING="$MISSING Goal,"

    if [ -n "$MISSING" ]; then
        jq -n --arg missing "$MISSING" '{
            hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: ("Nanotask plan file must contain sections: " + $missing)
            }
        }'
        exit 0
    fi
fi

exit 0
```

---

## Configuration File

**.claude/settings.json:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "TaskCreate",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/scripts/subtask-planning-guard.sh"
          }
        ]
      },
      {
        "matcher": "TaskUpdate",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/scripts/task-delete-guard.sh"
          }
        ]
      },
      {
        "matcher": "mcp__atlassian__jira_create_issue",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/scripts/jira-description-guard.sh"
          }
        ]
      },
      {
        "matcher": "mcp__atlassian__jira_update_issue",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/scripts/jira-description-guard.sh"
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/scripts/plan-format-validator.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Checkpoints by Workflow

### EpicToStory

| Step | Checkpoint | Guard |
| --- | --- | --- |
| 3 | plan_confirmation | Block jira_create_issue until user says "Confirm" |
| 5 | file_saved | Verify story.md exists before Jira creation |

### StoryToSubtask

| Step | Checkpoint | Guard |
| --- | --- | --- |
| 3 | collaborative_planning | Block if objectives/scope/deliverables not discussed |
| 4 | user_approval | Block jira_create_issue until user says "Confirm" |

### SubtaskToNanotask

| Step | Checkpoint | Guard |
| --- | --- | --- |
| 2 | CP1 | plan.md + nanotask plan files exist on disk |
| 3 | CP2 | User says "Approve" |
| 4 | CP3 | TaskCreate allowed only after CP1+CP2 |

---

## How to Activate

```bash
chmod +x scripts/*.sh
```

Hooks are configured in `.claude/settings.json` (see Configuration File section above).

---

## Limitations

1. **Bypass Potential** - Agent could bypass guards by using alternative tools
2. **Debugging Complexity** - Difficult to identify cause of Hook failure

## Alternative: LLM Prompt Hook

LLM analyzes conversation context instead of state file:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "TaskCreate",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Analyze the conversation. Is this a SubtaskToNanotask workflow? If yes, check: 1) Were plan files created? 2) Did user approve? Respond with {\"allow\": true} or {\"allow\": false, \"reason\": \"...\"}"
          }
        ]
      }
    ]
  }
}
```

**Pros:** No state file required
**Cons:** Increased cost, latency