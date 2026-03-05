#!/bin/bash
# Plan File Format Validator
# Validates plan.md, status.md, and nanotask plan files have required sections
#
# Usage: PreToolUse hook with matcher "Write"

set -e

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check Write tool
if [ "$TOOL_NAME" != "Write" ]; then
    exit 0
fi

# Only validate specific files in space/ directory
FILENAME=$(basename "$FILE_PATH")

# Early exit: not in space/ directory
if [[ ! "$FILE_PATH" =~ /jira-planner/ ]]; then
    exit 0
fi

# Early exit: not a validatable file
# Nanotask pattern: {PROJECT_KEY}-{SUBTASK_NUM}-{NANOTASK_NUM}.md (e.g., WAO-274-1.md)
if [[ "$FILENAME" != "plan.md" ]] && \
   [[ "$FILENAME" != "status.md" ]] && \
   [[ ! "$FILENAME" =~ ^[A-Z]+-[0-9]+-[0-9]+\.md$ ]]; then
    exit 0
fi

CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')

# Validate plan.md
if [[ "$FILE_PATH" == */plan.md ]]; then
    MISSING=""

    echo "$CONTENT" | grep -q "## Nanotasks" || MISSING="$MISSING ## Nanotasks,"
    echo "$CONTENT" | grep -q "## MUST READ" || MISSING="$MISSING ## MUST READ,"

    if [ -n "$MISSING" ]; then
        jq -n --arg missing "$MISSING" '{
            hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: ("plan.md validation failed. Missing sections:" + $missing + " See subtask_to_nanotask.md for required format.")
            }
        }'
        exit 0
    fi
fi

# Validate status.md
if [[ "$FILE_PATH" == */status.md ]]; then
    MISSING=""

    echo "$CONTENT" | grep -q "TASK_LIST_ID" || MISSING="$MISSING TASK_LIST_ID,"
    echo "$CONTENT" | grep -q "| ID " || MISSING="$MISSING status table,"

    if [ -n "$MISSING" ]; then
        jq -n --arg missing "$MISSING" '{
            hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: ("status.md validation failed. Missing:" + $missing + " See subtask_to_nanotask.md status.md Format.")
            }
        }'
        exit 0
    fi
fi

# Validate nanotask plan files (WAO-XXX-N.md pattern)
if [[ "$FILE_PATH" =~ WAO-[0-9]+-[0-9]+\.md$ ]]; then
    MISSING=""

    echo "$CONTENT" | grep -q "## Goal" || MISSING="$MISSING ## Goal,"

    if [ -n "$MISSING" ]; then
        jq -n --arg missing "$MISSING" --arg file "$(basename "$FILE_PATH")" '{
            hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: ("Nanotask plan file " + $file + " validation failed. Missing sections:" + $missing + " See subtask_to_nanotask.md for required format.")
            }
        }'
        exit 0
    fi
fi

# Validation passed
exit 0
