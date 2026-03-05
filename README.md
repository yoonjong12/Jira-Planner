# Jira Planner

Claude Code plugin for Jira workflow automation — Epic, Story, Subtask, and Nanotask planning and tracking.

## Skills

| Command | Description |
|---------|-------------|
| `/jira-planner:onboarding` | Resume work — loads plan, status, references |
| `/jira-planner:help` | Show available skills and getting started guide |
| `/jira-planner:epic-to-story` | Plan Stories under an Epic |
| `/jira-planner:story-to-subtask` | Create Subtasks for a Story |
| `/jira-planner:subtask-to-nanotask` | Convert Subtasks to Claude Code tasks |
| `/jira-planner:checkpoint` | Save session state for fast resume |
| `/jira-planner:install` | Set up Jira MCP connection |
| `/jira-planner:uninstall` | Remove all config and restore pre-install state |

## Installation

```bash
# Add marketplace
/plugin marketplace add https://github.com/yoonjong12/Jira-Planner.git

# Install plugin
/plugin install jira-planner
```

After installation, run `/jira-planner:install` to configure Atlassian MCP and guardrail hooks.

## Hierarchy

```
Epic > Story > Subtask > Nanotask (design / review / commit / docs)
```

## Workspace

Planning data is stored project-locally at `.claude/jira-planner/space/`.

## Requirements

- Claude Code with plugin support
- Atlassian MCP (`mcp-atlassian` via uvx)
- Jira workspace access with API token
