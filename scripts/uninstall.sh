#!/bin/bash
# Jira Planner Uninstaller
# Removes all Jira Planner additions from config files, restoring pre-install state.
#
# Usage: bash .claude/jira-planner/scripts/uninstall.sh [--keep-tasks] [--keep-mcp] [--dry-run]
#
# Options:
#   --keep-tasks  Preserve ~/.claude/tasks/ data
#   --keep-mcp    Preserve MCP server entries in ~/.claude.json
#   --dry-run     Show what would be removed without making changes

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$(dirname "$(dirname "$SKILL_DIR")")")"
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"
LOCAL_SETTINGS_FILE="$PROJECT_DIR/.claude/settings.local.json"
GLOBAL_CONFIG="$HOME/.claude.json"

KEEP_TASKS=false
KEEP_MCP=false
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --keep-tasks) KEEP_TASKS=true ;;
        --keep-mcp)   KEEP_MCP=true ;;
        --dry-run)    DRY_RUN=true ;;
    esac
done

echo "Jira Planner Uninstaller"
echo "====================="
echo "Project: $PROJECT_DIR"
echo ""

if $DRY_RUN; then
    echo "[DRY RUN] No changes will be made."
    echo ""
fi

CHANGES=0

# --- 1. Remove hooks from .claude/settings.json ---
if [ -f "$SETTINGS_FILE" ]; then
    if jq -e '.hooks' "$SETTINGS_FILE" > /dev/null 2>&1; then
        echo "[1/4] Remove Jira Planner hooks from .claude/settings.json"

        # Filter out hooks whose command contains "jira-planner"
        CLEANED=$(jq '
          .hooks |= (
            to_entries | map(
              .value |= map(
                select(
                  (.hooks // []) | all(.command | test("jira-planner") | not)
                )
              ) | .value |= [.[] | select(length > 0)]
            ) | map(select(.value | length > 0)) | from_entries
          )
        ' "$SETTINGS_FILE")

        # Remove empty hooks object
        CLEANED=$(echo "$CLEANED" | jq 'if .hooks == {} then del(.hooks) else . end')

        if ! $DRY_RUN; then
            echo "$CLEANED" > "${SETTINGS_FILE}.tmp"
            mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
        fi
        echo "  Removed Jira Planner hook entries"
        CHANGES=$((CHANGES + 1))
    else
        echo "[1/4] No hooks found in .claude/settings.json — skipping"
    fi

    # Remove CLAUDE_CODE_TASK_LIST_ID
    if jq -e '.env.CLAUDE_CODE_TASK_LIST_ID' "$SETTINGS_FILE" > /dev/null 2>&1; then
        TASK_ID=$(jq -r '.env.CLAUDE_CODE_TASK_LIST_ID' "$SETTINGS_FILE")
        echo "  Remove env.CLAUDE_CODE_TASK_LIST_ID ($TASK_ID)"
        if ! $DRY_RUN; then
            jq 'del(.env.CLAUDE_CODE_TASK_LIST_ID) | if .env == {} then del(.env) else . end' \
                "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
            mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
        fi
        CHANGES=$((CHANGES + 1))
    fi
else
    echo "[1/4] .claude/settings.json not found — skipping"
fi

# --- 2. Remove deny rules from .claude/settings.local.json ---
echo ""
if [ -f "$LOCAL_SETTINGS_FILE" ]; then
    JIRA_DENY_COUNT=$(jq '[.permissions.deny // [] | .[] | select(test("mcp__atlassian__jira_(transition|update|delete)_issue"))] | length' "$LOCAL_SETTINGS_FILE" 2>/dev/null || echo "0")

    if [ "$JIRA_DENY_COUNT" -gt 0 ]; then
        echo "[2/4] Remove Jira Planner deny rules from .claude/settings.local.json"
        if ! $DRY_RUN; then
            jq '.permissions.deny |= [.[] | select(test("mcp__atlassian__jira_(transition|update|delete)_issue") | not)]' \
                "$LOCAL_SETTINGS_FILE" > "${LOCAL_SETTINGS_FILE}.tmp"
            mv "${LOCAL_SETTINGS_FILE}.tmp" "$LOCAL_SETTINGS_FILE"
        fi
        echo "  Removed $JIRA_DENY_COUNT deny entries"
        CHANGES=$((CHANGES + 1))
    else
        echo "[2/4] No Jira Planner deny rules found — skipping"
    fi
else
    echo "[2/4] .claude/settings.local.json not found — skipping"
fi

# --- 3. Remove MCP servers from ~/.claude.json ---
echo ""
if $KEEP_MCP; then
    echo "[3/4] Keeping MCP servers (--keep-mcp)"
else
    if [ -f "$GLOBAL_CONFIG" ]; then
        echo "[3/4] Remove Jira Planner MCP servers from ~/.claude.json"

        if jq -e '.mcpServers.atlassian' "$GLOBAL_CONFIG" > /dev/null 2>&1; then
            if ! $DRY_RUN; then
                jq 'del(.mcpServers.atlassian)' "$GLOBAL_CONFIG" > "${GLOBAL_CONFIG}.tmp"
                mv "${GLOBAL_CONFIG}.tmp" "$GLOBAL_CONFIG"
            fi
            echo "  Removed mcpServers.atlassian"
            CHANGES=$((CHANGES + 1))
        else
            echo "  No atlassian MCP entry found — skipping"
        fi

        # Remove markdown-reader skill directory
        READER_DIR="$HOME/.claude/skills/markdown-reader"
        if [ -d "$READER_DIR" ]; then
            if ! $DRY_RUN; then
                rm -rf "$READER_DIR"
            fi
            echo "  Removed ~/.claude/skills/markdown-reader/"
            CHANGES=$((CHANGES + 1))
        else
            echo "  No markdown-reader skill found — skipping"
        fi

        echo ""
        echo "  WARNING: API token이 ~/.claude.json에서 제거되었습니다."
        echo "  보안을 위해 Atlassian에서 토큰을 수동 폐기하세요:"
        echo "  https://id.atlassian.com/manage-profile/security/api-tokens"
    else
        echo "[3/4] ~/.claude.json not found — skipping"
    fi
fi

# --- 4. Remove task persistence data ---
echo ""
if $KEEP_TASKS; then
    echo "[4/4] Keeping task data (--keep-tasks)"
else
    if [ -n "$TASK_ID" ] && [ -d "$HOME/.claude/tasks/$TASK_ID" ]; then
        echo "[4/4] Remove task persistence directory"
        echo "  Directory: ~/.claude/tasks/$TASK_ID/"
        if ! $DRY_RUN; then
            rm -rf "$HOME/.claude/tasks/$TASK_ID"
        fi
        echo "  Removed"
        CHANGES=$((CHANGES + 1))
    else
        echo "[4/4] No task data found — skipping"
    fi
fi

# --- Summary ---
echo ""
echo "========================"
if $DRY_RUN; then
    echo "Dry run complete. $CHANGES change(s) would be made."
    echo "Run without --dry-run to apply."
else
    echo "Uninstall complete. $CHANGES change(s) applied."
    echo ""
    echo "Remaining (not removed):"
    echo "  - .claude/jira-planner/ directory (skill files)"
    echo "  - .claude/jira-planner/space/ (plan files)"
    echo ""
    echo "To fully remove, delete the skill directory:"
    echo "  rm -rf .claude/jira-planner/"
    echo ""
    echo "Restart Claude Code for changes to take effect."
fi
