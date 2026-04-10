# Jira MCP Command Reference

Quick reference for token-efficient Jira MCP usage in jira-planner workflows.

## Core Principles

1. **OAuth via Atlassian Plugin** - Auth handled by `atlassian@claude-plugins-official` plugin. No local MCP server needed.
2. **cloudId required** - All tools require `cloudId`. Use site URL (e.g., `mindai.atlassian.net`) or UUID.
3. **Use JQL for filtering** - More efficient than fetching all then filtering
4. **Limit result size** - Always set `maxResults` parameter appropriately
5. **Markdown format** - Use `responseContentFormat: "markdown"` for readable output

## Quick Reference

### User Info

```typescript
// Get current user info
atlassianUserInfo({})

// Lookup user account ID
lookupJiraAccountId({
  cloudId: "mindai.atlassian.net",
  searchString: "yoonjong"
})
```

### Search & Discovery

```typescript
// Find active epics in WAO project
searchJiraIssuesUsingJql({
  cloudId: "mindai.atlassian.net",
  jql: "project = WAO AND type = Epic AND status IN (Open, \"In Progress\") ORDER BY updated DESC",
  maxResults: 5,
  fields: ["summary", "status", "updated"],
  responseContentFormat: "markdown"
})

// Find stories under specific epic
searchJiraIssuesUsingJql({
  cloudId: "mindai.atlassian.net",
  jql: "parent = WAO-180 AND type = Story",
  maxResults: 20,
  fields: ["summary", "status", "assignee"]
})

// Find my assigned issues
searchJiraIssuesUsingJql({
  cloudId: "mindai.atlassian.net",
  jql: "project = WAO AND assignee = currentUser() AND status != Done",
  maxResults: 10
})
```

### Issue Operations

```typescript
// Get single issue with full details
getJiraIssue({
  cloudId: "mindai.atlassian.net",
  issueIdOrKey: "WAO-180",
  fields: ["summary", "description", "status", "assignee", "subtasks"],
  responseContentFormat: "markdown"
})

// Create Epic
createJiraIssue({
  cloudId: "mindai.atlassian.net",
  projectKey: "WAO",
  issueTypeName: "Epic",
  summary: "Epic title",
  description: "Epic description in Markdown",
  contentFormat: "markdown",
  additional_fields: {
    "customfield_10011": "Epic Name"
  }
})

// Create Story under Epic
createJiraIssue({
  cloudId: "mindai.atlassian.net",
  projectKey: "WAO",
  issueTypeName: "Story",
  summary: "Story title",
  description: "Story description",
  contentFormat: "markdown",
  parent: "WAO-180"
})

// Create Subtask under Story
createJiraIssue({
  cloudId: "mindai.atlassian.net",
  projectKey: "WAO",
  issueTypeName: "Subtask",  // ⚠️ "Subtask" NOT "Sub-task"
  summary: "Subtask title",
  description: "Subtask description",
  contentFormat: "markdown",
  parent: "WAO-181",
  additional_fields: {
    "priority": {"name": "1"},
    "duedate": "2026-02-10",
    "customfield_10025": "2026-02-09"
  }
})

// Add comment
addCommentToJiraIssue({
  cloudId: "mindai.atlassian.net",
  issueIdOrKey: "WAO-180",
  commentBody: "Comment in Markdown",
  contentFormat: "markdown"
})

// Update issue fields
editJiraIssue({
  cloudId: "mindai.atlassian.net",
  issueIdOrKey: "WAO-180",
  fields: {
    "summary": "Updated title",
    "description": "Updated description"
  },
  contentFormat: "markdown"
})
```

### Transitions & Status

```typescript
// Get available transitions for issue
getTransitionsForJiraIssue({
  cloudId: "mindai.atlassian.net",
  issueIdOrKey: "WAO-180"
})

// Transition issue to new status
transitionJiraIssue({
  cloudId: "mindai.atlassian.net",
  issueIdOrKey: "WAO-180",
  transition: { id: "31" }
})
```

### Issue Links

```typescript
// Link two issues
createIssueLink({
  cloudId: "mindai.atlassian.net",
  inwardIssue: "WAO-181",
  outwardIssue: "WAO-180",
  type: "Blocks"
})

// Get available link types
getIssueLinkTypes({
  cloudId: "mindai.atlassian.net"
})
```

### Metadata & Discovery

```typescript
// List accessible projects
getVisibleJiraProjects({
  cloudId: "mindai.atlassian.net"
})

// Get issue types for project
getJiraProjectIssueTypesMetadata({
  cloudId: "mindai.atlassian.net",
  projectIdOrKey: "WAO"
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
```

## Token Efficiency Tips

1. **Selective fields**: Only request needed fields (array format)
   ```typescript
   fields: ["summary", "status"]  // Good
   ```

2. **Limit results**: Use `maxResults` aggressively
   ```typescript
   maxResults: 5   // For user selection
   maxResults: 1   // For "latest epic"
   ```

3. **Markdown format**: Use `responseContentFormat: "markdown"` for readable, compact output

## Error Handling

- **401/403**: OAuth token expired → Re-authenticate via plugin
- **404 Not Found**: Issue doesn't exist or no permission
- **400 Bad Request**: Check required fields for issue type
- **"유효한 이슈 유형을 지정하세요"**: Wrong issueTypeName. Use `"Subtask"` not `"Sub-task"`
- **"No such tool available"**: Tool is deferred. Call `ToolSearch("select:mcp__plugin_atlassian_atlassian__editJiraIssue")` first

## Deferred Tools

All Atlassian plugin tools are deferred. Load via `ToolSearch` before first use:

```typescript
ToolSearch({ query: "select:mcp__plugin_atlassian_atlassian__getJiraIssue" })
ToolSearch({ query: "select:mcp__plugin_atlassian_atlassian__searchJiraIssuesUsingJql" })
ToolSearch({ query: "select:mcp__plugin_atlassian_atlassian__createJiraIssue" })
ToolSearch({ query: "select:mcp__plugin_atlassian_atlassian__editJiraIssue" })
ToolSearch({ query: "select:mcp__plugin_atlassian_atlassian__addCommentToJiraIssue" })
ToolSearch({ query: "select:mcp__plugin_atlassian_atlassian__transitionJiraIssue" })
ToolSearch({ query: "select:mcp__plugin_atlassian_atlassian__getTransitionsForJiraIssue" })
```

## Workflow-Specific Patterns

### EpicToStory Workflow
```typescript
// 1. Get epic
getJiraIssue({ cloudId: "mindai.atlassian.net", issueIdOrKey: epicKey })

// 2. Get existing stories to avoid duplicates
searchJiraIssuesUsingJql({
  cloudId: "mindai.atlassian.net",
  jql: `parent = ${epicKey} AND type = Story`,
  fields: ["summary"]
})

// 3. Create stories iteratively
createJiraIssue({
  cloudId: "mindai.atlassian.net",
  projectKey: "WAO",
  issueTypeName: "Story",
  summary: "Story title",
  parent: epicKey
})
```
