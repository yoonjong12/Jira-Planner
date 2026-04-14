#!/bin/bash
# Task Delete Guard (advisory — never blocks)
# Warns on deleting active tasks during jira-planner workflow.
# Reminds to update status.md on task completion.
#
# Usage: PreToolUse hook with matcher "TaskUpdate"

set -e

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')

if [ "$TOOL_NAME" != "TaskUpdate" ]; then
    exit 0
fi

# Only care about status changes to deleted or completed
STATUS=$(echo "$INPUT" | jq -r '.tool_input.status // empty')

if [ "$STATUS" != "deleted" ] && [ "$STATUS" != "completed" ]; then
    exit 0
fi

# Check if we're in a jira-planner workflow by looking for space/ directory
SPACE_DIR="$CLAUDE_PROJECT_DIR/.claude/jira-planner/space"

if [ ! -d "$SPACE_DIR" ]; then
    exit 0
fi

# For deletion: allow completed tasks to be deleted (checkpoint compaction),
# block deletion of pending/in_progress tasks (protect active work)
if [ "$STATUS" = "deleted" ]; then
    TASK_ID=$(echo "$INPUT" | jq -r '.tool_input.taskId // empty')

    # Read current task status from CC Tasks file if available
    TASK_DIR="$HOME/.claude/tasks"
    TASK_LIST_ID=$(jq -r '.env.CLAUDE_CODE_TASK_LIST_ID // empty' "$CLAUDE_PROJECT_DIR/.claude/settings.json" 2>/dev/null)
    if [ -n "$TASK_LIST_ID" ]; then
        TASK_DIR="$TASK_DIR/$TASK_LIST_ID"
    fi

    TASK_FILE="$TASK_DIR/$TASK_ID.json"
    CURRENT_STATUS=""
    if [ -f "$TASK_FILE" ]; then
        CURRENT_STATUS=$(jq -r '.status // empty' "$TASK_FILE" 2>/dev/null)
    fi

    # Allow deleting completed tasks (checkpoint compaction)
    if [ "$CURRENT_STATUS" = "completed" ]; then
        exit 0
    fi

    # Advisory: warn about deleting non-completed tasks
    jq -n '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "allow",
            permissionDecisionReason: "[JIRA-PLANNER] Warning: deleting active (non-completed) task. Consider setting status to completed first so checkpoint can track it."
        }
    }'
    exit 0
fi

# status = completed: allow but inject reminder
jq -n '{
    hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow",
        permissionDecisionReason: "[JIRA-PLANNER] Task completed. Remember: update status.md row (Status → completed, Hash → commit hash)."
    }
}'
exit 0
