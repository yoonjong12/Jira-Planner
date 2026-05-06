---
description: "Show available Jira Planner skills and how to get started."
allowed-tools: ""
---

# Jira Planner Help

## Available Skills

| Skill | Purpose | When to use |
|-------|---------|-------------|
| `/jira-planner:onboarding` | Resume work — loads plan, status, references | Every new session |
| `/jira-planner:epic-to-story` | Break Epic into Stories | Starting a new Epic |
| `/jira-planner:story-to-subtask` | Break Story into Subtasks | Starting a new Story |
| `/jira-planner:subtask-to-nanotask` | Plan nanotasks + create CC Tasks | Starting implementation |
| `/jira-planner:checkpoint` | Save session state for next resume | Before ending a session |
| `/jira-planner:install` | Set up Jira MCP + hooks | First time only |
| `/jira-planner:uninstall` | Remove all config | Cleanup |

## Getting Started

### First time?
1. `/jira-planner:install` — connect Jira + install guardrail hooks
2. `/jira-planner:epic-to-story` — plan Stories under your Epic
3. `/jira-planner:story-to-subtask` — plan Subtasks under a Story
4. `/jira-planner:subtask-to-nanotask` — break into nanotasks + start working

### Returning?
1. `/jira-planner:onboarding` — loads your current work context automatically
2. Continue from where you left off

### Ending a session?
1. `/jira-planner:checkpoint` — saves MEMORY.md, status.md, CC Tasks

## Hierarchy

```
Epic > Story > Subtask > Nanotask (design / review / commit / docs)
```

Workspace: `.claude/jira-planner/space/{epic}/{story}/`
