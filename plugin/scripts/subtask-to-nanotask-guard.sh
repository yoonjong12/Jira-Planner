#!/bin/bash
# SubtaskToNanotask CP1 Guard
# Blocks TaskCreate if plan files don't exist in space/ directory
#
# Usage: PreToolUse hook with matcher "TaskCreate"

set -e

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')

# Only check for TaskCreate
if [ "$TOOL_NAME" != "TaskCreate" ]; then
    exit 0
fi

SPACE_DIR="$CLAUDE_PROJECT_DIR/.claude/jira-planner/space"

# No space directory at all — not in jira-planner workflow, allow
if [ ! -d "$SPACE_DIR" ]; then
    exit 0
fi

# Find any plan.md under space/
PLAN_FILE=$(find "$SPACE_DIR" -name "plan.md" -type f 2>/dev/null | head -1)

if [ -z "$PLAN_FILE" ]; then
    jq -n '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: "CP1 FAILED: No plan.md found in space/ directory. Create plan files first."
        }
    }'
    exit 0
fi

# Check if at least one nanotask plan file exists in the same directory
PLAN_DIR=$(dirname "$PLAN_FILE")
NANOTASK_COUNT=$(find "$PLAN_DIR" -name "WAO-*-*.md" 2>/dev/null | wc -l)

if [ "$NANOTASK_COUNT" -eq 0 ]; then
    jq -n --arg dir "$PLAN_DIR" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: ("CP1 FAILED: No nanotask plan files (WAO-*-*.md) found in " + $dir + ". Create nanotask plans first.")
        }
    }'
    exit 0
fi

# CP1 passed
exit 0
