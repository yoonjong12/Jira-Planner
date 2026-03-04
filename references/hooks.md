# Claude Code Hooks Guide

## What are Hooks?

Hooks are user-defined shell commands or LLM prompts that run automatically at specific points in the Claude Code lifecycle.

---

## 1. How to Add Hooks

**Method 1: /hooks command (Recommended)**
Type `/hooks` in the terminal and select events, matchers, and commands from the interactive menu.

**Method 2: Directly edit configuration file**
| Location | Scope |
| :--- | :--- |
| `~/.claude/settings.json` | Global (All projects) |
| `.claude/settings.json` | Project-specific (Committable) |
| `.claude/settings.local.json` | Project-specific (gitignored) |

**Configuration Example:**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "python -m black ."
          }
        ]
      }
    ]
  }
}
```

---

## 2. Hook Event Types (12 types)

| Event | Trigger Point |
| :--- | :--- |
| **SessionStart** | At session start/resume |
| **UserPromptSubmit** | When user prompt is submitted (before processing) |
| **PreToolUse** | Before tool execution (can block) |
| **PermissionRequest** | When permission dialog is displayed |
| **PostToolUse** | After successful tool execution |
| **PostToolUseFailure** | After failed tool execution |
| **Notification** | When notification is sent |
| **SubagentStart** | When subagent is created |
| **SubagentStop** | When subagent ends |
| **Stop** | When Claude response completes |
| **PreCompact** | Before context compression |
| **SessionEnd** | When session ends |

---

## 3. Hook Management

**Delete:** Select and delete from the `/hooks` menu or remove the entry from the configuration file.

**Temporarily Disable:**
```json
{
  "disableAllHooks": true
}
```

**Note:** Manual edits to the configuration file are loaded as snapshots at the start of a session. Changes are applied after review in the `/hooks` menu.

---

## 4. Monitoring and Debugging

**Debug Mode:**
`claude --debug`
Check Hook execution details (matched hooks, exit codes, output).

**Verbose Mode:** Toggle with `Ctrl+O` to see hook progress in the transcript.

**Asynchronous Execution:** Long-running tasks can be executed in the background.
```json
{
  "type": "command",
  "command": "npm test",
  "async": true,
  "timeout": 120
}
```

---

## 5. Hook Types

| Type | Description |
| :--- | :--- |
| **command** | Execute shell command |
| **prompt** | Request LLM to evaluate a single prompt |
| **agent** | Create subagent with tool usage capabilities |

---

## Practical Examples

**Auto-formatting on save:**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "python -m black \"$CLAUDE_PROJECT_DIR\""
          }
        ]
      }
    ]
  }
}
```

**Blocking dangerous commands:**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-rm.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Sources:
- https://code.claude.com/docs/en/hooks
- https://claudefa.st/blog/tools/hooks/hooks-guide
- https://github.com/disler/claude-code-hooks-multi-agent-observability

---

## How to Block/Monitor Tool Execution

### 1. Blocking with PreToolUse Hook

**Exit Code 2 Method (Simple):**
```bash
#!/bin/bash
# .claude/hooks/block-dangerous.sh
COMMAND=$(jq -r '.tool_input.command' < /dev/stdin)

if echo "$COMMAND" | grep -q 'rm -rf'; then
  echo "Dangerous command detected. Execution blocked." >&2
  exit 2  # Block reason is passed to Claude
fi
exit 0
```

**JSON Decision Method (Granular Control):**
```bash
#!/bin/bash
# permissionDecision: "allow" | "deny" | "ask"
COMMAND=$(jq -r '.tool_input.command')

if echo "$COMMAND" | grep -q 'DROP TABLE'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Dropping DB tables is prohibited."
    }
  }'
else
  exit 0
fi
```

---

### 2. LLM-based Judgment (Prompt Hook)

Instead of a script, you can let the LLM decide:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Evaluate if the following command is safe: $ARGUMENTS\n\nRisk Criteria:\n1. File deletion commands (rm -rf)\n2. System configuration changes\n3. Potential network attacks\n\nRespond with {\"ok\": true} or {\"ok\": false, \"reason\": \"block reason\"}."
          }
        ]
      }
    ]
  }
}
```

---

### 3. Agent-based Deep Validation

Validate after reading files and checking the codebase:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "agent",
            "prompt": "Check if this file modification aligns with project conventions. Review .eslintrc and CLAUDE.md rules. $ARGUMENTS",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

---

### 4. Decision Options Summary

| permissionDecision | Effect |
| :--- | :--- |
| **"allow"** | Bypass permission system, execute immediately |
| **"deny"** | Block, pass reason to Claude |
| **"ask"** | Request user confirmation |

---

## Real-world Example: Production DB Protection

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/db-guard.sh"
          }
        ]
      }
    ]
  }
}
```

```bash
#!/bin/bash
# db-guard.sh
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command')

# Block production DB access
if echo "$CMD" | grep -qE '(prod|production).*database'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Production DB access is prohibited. Please use the development DB."
    }
  }'
  exit 0
fi

# Safe commands pass through
exit 0
```

This way, you can inform and block Claude when it attempts dangerous operations.
