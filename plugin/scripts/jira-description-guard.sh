#!/bin/bash
# Jira Description Template Guard (advisory — never blocks)
# Warns when subtask descriptions are missing Context/Objective/Deliverables/AC sections.
#
# Usage: PreToolUse hook with matcher "mcp__plugin_atlassian_atlassian__editJiraIssue"
#        PreToolUse hook with matcher "mcp__plugin_atlassian_atlassian__createJiraIssue"

set -e

INPUT=$(cat)

# Extract description from fields
DESC=$(echo "$INPUT" | jq -r '.tool_input.fields.description // empty')

# No description field in this update — not our concern
if [ -z "$DESC" ]; then
    exit 0
fi

# Required sections (Jira wiki markup)
MISSING=""
echo "$DESC" | grep -qi 'h2\.\s*Context' || MISSING="${MISSING}Context, "
echo "$DESC" | grep -qi 'h2\.\s*Objective' || MISSING="${MISSING}Objective, "
echo "$DESC" | grep -qi 'h2\.\s*Deliverables' || MISSING="${MISSING}Deliverables, "
echo "$DESC" | grep -qi 'h2\.\s*Acceptance Criteria' || MISSING="${MISSING}Acceptance Criteria, "

if [ -n "$MISSING" ]; then
    MISSING="${MISSING%, }"
    jq -n --arg missing "$MISSING" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "allow",
            permissionDecisionReason: ("[JIRA-PLANNER] Advisory: description missing sections: " + $missing + ". Recommended template: h2. Context / h2. Objective / h2. Deliverables / h2. Acceptance Criteria")
        }
    }'
    exit 0
fi

# Template valid
exit 0
