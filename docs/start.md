# Start Workflow

Entry point when user invokes `/jira-planner`. Routes to appropriate workflow.

## Routing Decision

**FIRST, check invocation pattern:**

```text
/jira-planner
├─ No args → Full Start workflow (Step 1-4)
│
├─ [workflow] only (e.g., "SubtaskToNanotask")
│   → Step 1 (profiling) → Route to workflow Step 0 (workflow asks for target)
│
├─ [workflow] [issue-key] (e.g., "SubtaskToNanotask WAO-252")
│   → Step 1 (profiling) → Route to workflow Step 1 (target provided)
│
└─ [issue-key] only (e.g., "WAO-252")
    → Step 1 (profiling) → Infer workflow from issue type → Route
```

**Issue type to workflow mapping:**

| Issue Type | Workflow |
| --- | --- |
| Epic | EpicToStory |
| Story | StoryToSubtask or SubtaskToNanotask (ask user) |
| Subtask | SubtaskToNanotask (use parent Story) |

---

## Steps

### Step 1: User Profiling

Execute User Profiling pattern from `references/common_patterns.md#user-profiling`.

**Decision tree (only for no-args invocation):**

```text
Has in-progress work?
├─ YES → Present hierarchy tree with options
│         User selects:
│         ├─ Issue key (WAO-264) → Fetch issue, show action menu
│         ├─ Workflow (EpicToStory) → Route to workflow
│         └─ "different" → Proceed to Step 2
│
└─ NO → Proceed to Step 2
```

**If user has in-progress work:**

```text
Welcome back! You're currently working on:

Epic WAO-180 - [Title] [Status]
└─ Story WAO-252 - [Title] [Status]
   ├─ Subtask WAO-264 - [Title] [Status]
   └─ Subtask WAO-265 - [Title] [Status]

Options:
1. View Details - Full description of selected issue
2. Update Status - Transition issue
3. Add Comment - Log progress
4. EpicToStory - Plan Stories under Epic
5. StoryToSubtask - Plan Subtasks under Story
6. SubtaskToNanotask - Convert to Claude Code tasks
7. Switch Epic - Work on different Epic

Enter issue key (e.g., WAO-264) or select number.
```

**If user selects an issue key:**

```text
What would you like to do with Subtask WAO-264?

1. View Full Details - See complete description
2. Update Status - Transition (In Progress → Done)
3. Add Comment - Log progress or blockers
4. Manage Dependencies - Add/remove blocked/blocker
5. Switch Task - Work on different task
```

**If no in-progress work:** Skip to Step 2.

---

### Step 2: Confirm Project

**Only if Step 1 found no active work or user chose "different".**

```text
Which project would you like to work on?

1. [PROJECT_KEY from installation] (Default)
2. Other project (please specify key)
```

---

### Step 3: Show Active Epics

```typescript
// Use PROJECT_KEY from Step 2 or installation
jira_search({
  jql: `project = ${PROJECT_KEY} AND type = Epic AND status IN (Open, \"In Progress\") ORDER BY updated DESC`,
  limit: 5,
  fields: "summary,status,updated"
})
```

Present:

```text
Active epics in ${PROJECT_KEY}:

1. ${PROJECT_KEY}-XXX - [Epic Title] (In Progress)
   Last updated: YYYY-MM-DD

2. ${PROJECT_KEY}-YYY - [Epic Title] (Open)
   Last updated: YYYY-MM-DD

Which epic would you like to work on, or create a new one?
```

---

### Step 4: Route to Workflow

Based on user choice, read target workflow doc from `index.yaml` path field:

- EpicToStory → `docs/epic_to_story.md`
- StoryToSubtask → `docs/story_to_subtask.md`
- SubtaskToNanotask → `docs/subtask_to_nanotask.md`

**Announce:** "Entering [Workflow] - reading [path]"

**TRANSITION RULE (MANDATORY):**

1. Find workflow in `index.yaml` by name
2. Read the workflow document from `path` field
3. Announce: "Entering [Workflow Name] - reading [path]"
4. Follow the document's steps sequentially
5. NEVER proceed without reading the workflow document

---

## State Management

Cache in conversation context for subsequent workflows:

- **Selected project**: `${PROJECT_KEY}` (from installation or user's choice)
- **Selected epic**: `${PROJECT_KEY}-XXX` (user's choice)
- **User email**: From installation step

Pass to subsequent workflows so they don't need to re-ask.

---

## Edge Cases

### No Active Epics

```text
No active epics found in ${PROJECT_KEY}. Would you like to:

1. View all epics (including closed ones)
2. Create a new epic
3. Work on a specific epic (provide key like ${PROJECT_KEY}-XXX)
```
```

---

## References

- Common patterns: `references/common_patterns.md`
- JQL/MCP: `references/jira_commands.md`
- Constants: `references/jira_commands.md#constants`
