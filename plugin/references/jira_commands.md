# Jira MCP Command Reference

Quick reference for token-efficient Jira MCP usage in jira-planner workflows.

## Core Principles

1. **API Token auth** - Permanent auth via `mcp-atlassian` (sooperset). No OAuth expiry.
2. **Use JQL for filtering** - More efficient than fetching all then filtering
3. **Limit result size** - Always set `limit` parameter appropriately

## Quick Reference

### User Info

```typescript
// Get current user profile
jira_get_user_profile({
  user_identifier: "yoonjong@wisdomgraph.ai"
})
// Output: displayName, emailAddress, accountId, etc.

// ⚠️ WARNING: Avoid unless absolutely necessary (large output)
jira_get_all_projects()
```

**Best Practice:** Only call project discovery during installation or boot.

### Search & Discovery

```typescript
// Find active epics in WAO project
jira_search({
  jql: "project = WAO AND type = Epic AND status IN (Open, \"In Progress\") ORDER BY updated DESC",
  limit: 5,
  fields: "summary,status,updated"
})

// Find stories under specific epic
jira_search({
  jql: "parent = WAO-180 AND type = Story",
  limit: 20,
  fields: "summary,status,assignee"
})

// Find my assigned issues
jira_search({
  jql: "project = WAO AND assignee = currentUser() AND status != Done",
  limit: 10
})
```

### Issue Operations

```typescript
// Get single issue with full details
jira_get_issue({
  issue_key: "WAO-180",
  fields: "summary,description,status,assignee,subtasks"
})

// Create Epic
jira_create_issue({
  project_key: "WAO",
  issue_type: "Epic",
  summary: "Epic title",
  description: "Epic description in Markdown",
  additional_fields: {
    "customfield_10011": "Epic Name"
  }
})

// Create Story under Epic
jira_create_issue({
  project_key: "WAO",
  issue_type: "Story",
  summary: "Story title",
  description: "Story description",
  additional_fields: {
    "parent": "WAO-180"  // ⚠️ String, NOT {"key": "WAO-180"}
  }
})

// Create Subtask under Story
jira_create_issue({
  project_key: "WAO",
  issue_type: "Subtask",  // ⚠️ "Subtask" NOT "Sub-task"
  summary: "Subtask title",
  description: "Subtask description",
  additional_fields: {
    "parent": "WAO-181",  // ⚠️ String, NOT {"key": "WAO-181"}
    "priority": {"name": "1"},  // 0=Blocker, 1=Critical, 2=High, 3=Medium
    "duedate": "2026-02-10",
    "customfield_10025": "2026-02-09"  // Start date
  }
})

// Link issue to Epic (alternative to parent field)
jira_link_to_epic({
  issue_key: "WAO-181",
  epic_key: "WAO-180"
})

// Add comment
jira_add_comment({
  issue_key: "WAO-180",
  comment: "Comment in Markdown"
})

// Update issue fields
// ⚠️ DEFERRED TOOL: Must call ToolSearch("select:mcp__atlassian__jira_update_issue") first!
jira_update_issue({
  issue_key: "WAO-180",
  fields: {
    "summary": "Updated title",
    "description": "Updated description"
  }
})
```

### Transitions & Status

```typescript
// Get available transitions for issue
jira_get_transitions({
  issue_key: "WAO-180"
})

// Transition issue to new status
jira_transition_issue({
  issue_key: "WAO-180",
  transition_id: "31"  // Get ID from jira_get_transitions
})
```

### Metadata & Fields

```typescript
// Search for field names/IDs
jira_search_fields({
  keyword: "epic"
})
```

## Common JQL Patterns

```jql
# Active epics, recently updated
project = WAO AND type = Epic AND status IN (Open, "In Progress") ORDER BY updated DESC

# All stories under epic
parent = WAO-180 AND type = Story

# Unassigned stories in project
project = WAO AND type = Story AND assignee is EMPTY

# My incomplete tasks
assignee = currentUser() AND status != Done AND resolution = Unresolved

# Recent issues (last 7 days)
project = WAO AND created >= -7d ORDER BY created DESC

# Issues updated today
project = WAO AND updated >= startOfDay() ORDER BY updated DESC
```

## Token Efficiency Tips

1. **Selective fields**: Only request needed fields in `jira_search`
   ```typescript
   fields: "summary,status"  // Good (comma-separated string)
   // vs leaving empty (returns all fields)
   ```

2. **Limit results**: Use `limit` aggressively
   ```typescript
   limit: 5  // For user selection
   limit: 1  // For "latest epic"
   ```

3. **JQL filtering**: Filter server-side, not client-side
   ```typescript
   // Good: Filter in JQL
   jql: "project = WAO AND status = Open"

   // Bad: Fetch all, filter locally
   jql: "project = WAO"  // then filter in code
   ```

## Error Handling

- **401 Unauthorized**: API token invalid or expired → Regenerate at id.atlassian.com
- **404 Not Found**: Issue doesn't exist or no permission
- **400 Bad Request**: Check required fields for issue type
- **"유효한 이슈 유형을 지정하세요"**: Wrong issue_type name. Use `"Subtask"` not `"Sub-task"`
- **"expected 'key' property to be a string"**: parent field must be a string (`"WAO-180"`), not an object (`{"key": "WAO-180"}`)
- **"No such tool available"**: Tool is deferred. Call `ToolSearch("select:mcp__atlassian__jira_update_issue")` first
- **Large output**: Results exceed token limit → Reduce `limit` or field list

## Deferred Tools

Some Jira MCP tools are **deferred** and must be loaded via `ToolSearch` before use:

```typescript
// These tools require ToolSearch loading BEFORE first use:
ToolSearch({ query: "select:mcp__atlassian__jira_update_issue" })   // Update issue fields
ToolSearch({ query: "select:mcp__atlassian__jira_add_worklog" })    // Add work logs
ToolSearch({ query: "select:mcp__atlassian__jira_get_transitions" }) // Get transitions

// These tools are available immediately (not deferred):
// jira_get_issue, jira_search, jira_create_issue, jira_create_issue_link, jira_add_comment
```

## Workflow-Specific Patterns

### Start Workflow
```typescript
// Step 1: User Profiling (Smart Context)
// Get user info
jira_get_user_profile({
  user_identifier: "yoonjong@wisdomgraph.ai"
})

// Find user's in-progress work
jira_search({
  jql: "project = WAO AND assignee = currentUser() AND status IN (\"In Progress\", \"진행 중\") ORDER BY updated DESC",
  limit: 3,
  fields: "summary,status,issuetype,parent"
})
// → If found: Offer quick resume
// → If not found: Continue to Step 1

// Step 1: Get recent active epics (if no user work found)
jira_search({
  jql: "project = WAO AND type = Epic AND status IN (Open, \"In Progress\") ORDER BY updated DESC",
  limit: 5,
  fields: "summary,status,updated"
})

// Step 2: Present to user, let them choose

// Step 3: Fetch full details only after selection
jira_get_issue({ issue_key: "WAO-180" })
```

### Kickoff Workflow
```typescript
// 1. Get epic (from boot context or user input)
jira_get_issue({ issue_key: epicKey })

// 2. Get existing stories to avoid duplicates
jira_search({
  jql: `parent = ${epicKey} AND type = Story`,
  fields: "summary"
})

// 3. Create stories iteratively based on planning
jira_create_issue({ ..., additional_fields: { "parent": epicKey } })  // String, NOT {"key": epicKey}
```

## Constants

**Note:** These are examples for WAO project. Replace with your project's values.

```typescript
// Example: Replace with your project
const PROJECT_KEY = "WAO"  // Your project key (e.g., "PROJ", "DEV")
const PROJECT_NAME = "WG Agent Optimization"  // Your project name
const USER_EMAIL = "user@example.com"  // Your Atlassian email

// Common Issue Type Names (check your project's configuration)
const ISSUE_TYPES = {
  EPIC: "Epic",       // or "에픽" (Korean)
  STORY: "Story",     // or "스토리"
  SUBTASK: "Subtask", // ⚠️ NOT "Sub-task"
  TASK: "Task"
}

// Common Status Names
const STATUSES = {
  OPEN: "Open",
  IN_PROGRESS: "In Progress",
  DONE: "Done",
  TODO: "To Do"
}
```
