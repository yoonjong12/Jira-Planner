#!/bin/bash
# Jira Planner Hook Installer
# Adds guardrail hooks to .claude/settings.json
#
# Usage: scripts/install-hooks.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$(dirname "$(dirname "$SKILL_DIR")")")"
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"

echo "Jira Planner Hook Installer"
echo "========================"
echo "Skill directory: $SKILL_DIR"
echo "Settings file: $SETTINGS_FILE"

# Make hook scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

# Check if settings.json exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "Creating new settings.json..."
    echo '{"permissions": {"allow": []}}' > "$SETTINGS_FILE"
fi

# Hooks configuration
HOOKS_CONFIG='{
  "PreToolUse": [
    {
      "matcher": "TaskCreate",
      "hooks": [
        {
          "type": "command",
          "command": "$CLAUDE_PROJECT_DIR/scripts/subtask-to-nanotask-guard.sh"
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
          "command": "$CLAUDE_PROJECT_DIR/scripts/jira-creation-guard.sh"
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
}'

# Check if hooks already exist
if jq -e '.hooks' "$SETTINGS_FILE" > /dev/null 2>&1; then
    echo "Hooks already exist in settings.json"
    read -p "Overwrite existing hooks? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Hooks not modified."
        exit 0
    fi
fi

# Add hooks to settings.json
jq --argjson hooks "$HOOKS_CONFIG" '.hooks = $hooks' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

# Set CLAUDE_CODE_TASK_LIST_ID for task persistence across sessions
PROJECT_NAME="$(basename "$PROJECT_DIR")"
CURRENT_TASK_ID=$(jq -r '.env.CLAUDE_CODE_TASK_LIST_ID // empty' "$SETTINGS_FILE" 2>/dev/null)

if [ -z "$CURRENT_TASK_ID" ]; then
    echo ""
    echo "Task persistence setup"
    echo "----------------------"
    echo "Claude Code tasks are session-scoped by default and lost on restart."
    echo "CLAUDE_CODE_TASK_LIST_ID makes tasks persist across sessions."
    echo "Use your current Jira Story ID (e.g., WAO-252) as the task list ID."
    echo "Change it when you switch Stories via SubtaskToNanotask."
    echo ""
    read -p "Task list ID (Jira Story ID) [${PROJECT_NAME}]: " TASK_ID
    TASK_ID="${TASK_ID:-$PROJECT_NAME}"
    jq --arg id "$TASK_ID" '.env.CLAUDE_CODE_TASK_LIST_ID = $id' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
    mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    mkdir -p "$HOME/.claude/tasks/$TASK_ID"
    echo "Set CLAUDE_CODE_TASK_LIST_ID=$TASK_ID"
    echo "Tasks will persist in ~/.claude/tasks/$TASK_ID/"
else
    echo ""
    echo "Task persistence: CLAUDE_CODE_TASK_LIST_ID=$CURRENT_TASK_ID (already set)"
fi

echo ""
echo "Hooks installed successfully!"
echo ""
echo "Installed guardrails:"
echo "  - TaskCreate guard: Blocks task creation without plan files (CP1)"
echo "  - TaskUpdate guard: Blocks task deletion, reminds to update plan.md on completion"
echo "  - Jira guard: Validates Jira description template (Context/Objective/Deliverables/AC)"
echo "  - Format validator: Validates plan.md and nanotask plan file formats"
echo ""
echo "Note: Checkpoint is now a workflow (/jira-planner checkpoint), not a hook."
echo ""
echo "Restart Claude Code for hooks to take effect."
