---
description: "Jira workflow entry point — user profiling and workflow routing."
allowed-tools: Read, Bash, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_search, mcp__atlassian__jira_get_user_profile, AskUserQuestion
---

# Jira Planner

**Hierarchy:** Epic > Story > Subtask > Nanotask (design / review / commit / docs)

**Workspace:** `.claude/jira-planner/space/`

## Agent Behavior Rules

### Approval Gates (Non-negotiable)

| Action | Required Before Proceeding |
| --- | --- |
| Jira Issue Create/Update | User says "Confirm" or "Approve" |
| CC TaskCreate | plan.md exists (CP1) + User approved (CP2) |
| Issue Status Transition | User confirms transition |
| Shared config modification | Present numbered plan → wait for "Go" |

**NEVER:**
- Create Jira issues without explicit user confirmation
- Modify `.claude/settings.json`, `MEMORY.md`, or `status.md` without stating what will change
- Skip guardrail hooks or propose workarounds to bypass them

### Nanotask Type Selection

| User Signal | Default Type | NOT |
| --- | --- | --- |
| "설계", "디자인", "아키텍처", "개념", "토론" | `design` | `commit` |
| "리뷰", "비교", "분석", "검토", "평가" | `review` | `commit` |
| "구현", "코드", "리팩토링", "버그" | `commit` | `design` |
| "문서화", "보고서", "정리" | `docs` | `commit` |

### Naming Conventions

1. Check existing patterns in the same Story/Subtask directory
2. Nanotask ID: `{subtask번호}-{정수 인덱스}` — append-only
3. File names: `{SUBTASK_KEY}-{N}.md` (e.g., `WAO-264-1.md`)

### Tool Usage

- Use MCP tools directly (`mcp__atlassian__*`), never bash/curl
- NEVER call `jira_get_all_projects` (large output)

## Workflow

Read and follow the start workflow at `docs/start.md` in this plugin directory.

Also read `references/jira_commands.md` for MCP tool patterns.

ARGUMENTS: $ARGUMENTS
