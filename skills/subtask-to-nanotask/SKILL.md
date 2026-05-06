---
description: "Convert Subtasks to Claude Code tasks with nanotask-level planning and execution."
allowed-tools: Read, Bash, Write, Edit, mcp__plugin_atlassian_atlassian__getJiraIssue, mcp__plugin_atlassian_atlassian__searchJiraIssuesUsingJql, mcp__plugin_atlassian_atlassian__createJiraIssue, mcp__plugin_atlassian_atlassian__editJiraIssue, mcp__plugin_atlassian_atlassian__addCommentToJiraIssue, mcp__plugin_atlassian_atlassian__transitionJiraIssue, AskUserQuestion, TaskCreate, TaskUpdate, TaskList, TaskGet
---

Read and follow the SubtaskToNanotask workflow at `docs/subtask_to_nanotask.md` in this plugin directory.

Also read:
- `references/jira_commands.md` for MCP tool patterns
- `references/plan_mode.md` for plan mode details (use markdown-reader for efficient reading)

**Workspace:** `$JIRA_PLANNER_SPACE_DIR` (env var from settings.json). Fallback: `.claude/jira-planner/space/`

ARGUMENTS: $ARGUMENTS
