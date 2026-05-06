#!/bin/bash
# Jira Planner Checkpoint — UserPromptSubmit hook.
#
# Detects "체크포인트" or "checkpoint" keyword in user prompt.
# Injects [CHECKPOINT REQUEST] into agent's additionalContext.
#
# Hook event: UserPromptSubmit
# Input: JSON with session_id, prompt, cwd
# Output: JSON with hookSpecificOutput.additionalContext

INPUT=$(cat /dev/stdin 2>/dev/null)
USER_MSG=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('prompt', d.get('user_message','')))" 2>/dev/null)

if echo "$USER_MSG" | grep -qi "체크포인트\|checkpoint"; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "[CHECKPOINT REQUEST] Update all state for fast session resume: (0) Validate — read plan.md + status.md + active nanotask files, fix duplications/stale/inconsistency, (1) MEMORY.md — next TODO + decisions, (2) Space status.md — progress table + nanotask status, (3) Claude Code TaskUpdate — in-progress tasks with progress + next action. Formats: see docs/checkpoint.md and docs/subtask_to_nanotask.md (plan.md Format, Context Checkpoint sections)."
  }
}
EOF
fi
