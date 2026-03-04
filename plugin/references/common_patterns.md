# Common Patterns

Shared patterns across jira-planner workflows. Import these instead of duplicating.

## User Profiling

Standard entry pattern for all workflows. Returns user's in-progress work.

```typescript
// 1. Get current user
jira_get_user_profile({
  user_identifier: "yoonjong@wisdomgraph.ai"
})

// 2. Find in-progress work
jira_search({
  jql: "project = WAO AND assignee = currentUser() AND status IN (\"In Progress\", \"진행 중\") ORDER BY updated DESC",
  limit: 5,
  fields: "summary,status,issuetype,parent"
})
```

**Decision:**
- Has work → Show hierarchy tree, offer quick resume
- No work → Proceed to workflow-specific step

**Tree format:**
```
Epic WAO-180 - [Title] [Status]
└─ Story WAO-252 - [Title] [Status]
   ├─ Subtask WAO-264 - [Title] [Status]
   └─ Subtask WAO-265 - [Title] [Status]
```

## Context Fetch

Fetch Story with parent Epic context.

```typescript
// Story with subtasks
jira_get_issue({
  issue_key: storyKey,
  fields: "summary,description,status,parent,subtasks,duedate"
})

// Parent Epic
jira_get_issue({
  issue_key: story.parent.key,
  fields: "summary,description,duedate"
})
```

## Quality Checklist

Before creating any Jira issue, verify:

- [ ] Objectives: What will be achieved?
- [ ] Scope: What's included/excluded?
- [ ] Deliverables: Concrete outputs?
- [ ] User explicitly approved?

## Plan Structure

Standard Objectives/Scope/Deliverables format:

```markdown
**Objectives**
- [Goal 1]
- [Goal 2]

**Scope**
- Included: [X, Y, Z]
- Excluded: [A, B]

**Deliverables**
- [Artifact 1]
- [Artifact 2]
```

## Constants

See `jira_commands.md#constants` for project keys, issue types, user email.
