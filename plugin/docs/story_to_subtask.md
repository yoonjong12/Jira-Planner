# StoryToSubtask Workflow

Create subtasks for an existing Story through collaborative discussion.

---

**MODE: StoryToSubtask Workflow**

**YOU MUST COMPLETE ALL STEPS BELOW BEFORE CALLING jira_create_issue**

---

## Steps

### Step 0: Select Story

**Skip if Story already provided via args or Start workflow context.**

```typescript
jira_search({
  jql: "project = WAO AND type = Story AND status IN (Open, \"In Progress\") ORDER BY updated DESC",
  limit: 5,
  fields: "summary,status,parent,updated"
})
```

Present:

```text
Which Story would you like to create Subtasks for?

1. WAO-252 - Preparing MEGA Strategy integration [In Progress]
   Epic: WAO-180 - [Validation] Strategy Evolution
2. WAO-251 - Build Workflow Strategy foundation [Open]
   Epic: WAO-180 - [Validation] Strategy Evolution

Enter Story key (e.g., WAO-252) or select number.
```

---

### Step 1: Context Gathering

Execute Context Fetch pattern from `references/common_patterns.md#context-fetch`.

Present:

```text
Story: WAO-XXX - [Summary]
Parent Epic: WAO-YYY - [Summary]

Objectives: [From description]
Scope: [From description]

Existing subtasks:
1. WAO-AAA - [Summary] [Status]
2. WAO-BBB - [Summary] [Status]

I see you want to create a new subtask. Let's plan it together.
```

---

### Step 2: Identify Subtask

Ask user what subtask they want to create:

```text
What subtask would you like to create?

You can either:
1. Describe what you want to accomplish
2. Select from uncovered scope items in the Story

Story scope that may need subtasks:
- [Item 1 from Story scope]
- [Item 2 from Story scope]
- [Item 3 from Story scope]
```

---

### Step 3: Collaborative Planning (MANDATORY)

**This step is REQUIRED. You must discuss with user before creating the subtask.**

Discuss the following with user:

**A. Objectives**

```text
What is the goal of this subtask?
- What problem does it solve?
- How does it contribute to the Story deliverables?
```

**B. Scope**

```text
What exactly will be done?
- What is included?
- What is explicitly excluded?
- Are there dependencies on other subtasks?
```

**C. Deliverables**

```text
What artifacts will be produced?
- Code changes?
- Tests?
- Documentation?
- Reports?
```

**D. Priority**

```text
How urgent is this subtask?
- 0 (Blocker) - Blocks other work
- 1 (Critical) - Essential for Story completion
- 2 (High) - Important but not blocking
- 3 (Medium) - Can be deferred if needed
```

**E. Schedule & Dependencies**

```text
When should this subtask be worked on?
- Start date: [YYYY-MM-DD]
- Due date: [YYYY-MM-DD]
- Blocked by: [Which subtask must finish before this can start?]
- Blocks: [Which subtask depends on this one's completion?]
```

**When planning multiple subtasks**, build the full dependency chain upfront:

```text
Here's the proposed timeline and dependencies:

WAO-AAA (2/9-10) ──blocks──→ WAO-BBB (2/10-11) ──blocks──→ WAO-CCC (2/11-13)
  Research                      Design                       Implement

Does this schedule and dependency chain look correct?
```

**Iterative refinement:**

- Present your understanding of the subtask(s)
- Include the timeline and block relationships in your summary
- Ask clarifying questions
- Get user confirmation before proceeding

---

### Step 4: Draft Content

Based on discussion, draft the subtask(s). When creating multiple subtasks, present them together with the full timeline and dependency chain.

**Single subtask draft:**

```text
Here's the subtask I'll create:

**Title:** [Concise, action-oriented summary]

**Description:**
Objectives:
- [Goal 1]
- [Goal 2]

Scope:
- [What will be done]
- [What won't be done]

Deliverables:
- [Artifact 1]
- [Artifact 2]

**Schedule:** [Start date] - [Due date]
**Priority:** [0/1/2/3]
**Blocked by:** [WAO-XXX] (if any)
**Blocks:** [WAO-YYY] (if any)
**Assignee:** [User or unassigned]

Does this look correct? Please confirm or suggest changes.
```

**Multiple subtask draft (preferred when planning a full Story):**

```text
Here are the subtasks I'll create:

| # | Key | Title | Schedule | Priority | Dependencies |
|---|-----|-------|----------|----------|--------------|
| 1 | (new) | Research X | 2/9 - 2/10 | P1 | — |
| 2 | (new) | Design Y | 2/10 - 2/11 | P1 | Blocked by #1 |
| 3 | (new) | Implement Z | 2/11 - 2/13 | P2 | Blocked by #2 |

Dependency chain:
#1 (2/9-10) ──blocks──→ #2 (2/10-11) ──blocks──→ #3 (2/11-13)

Does this look correct? Please confirm or suggest changes.
```

**WAIT FOR USER APPROVAL** - Do not proceed without explicit confirmation.

---

### Step 5: Create Subtasks

**ONLY AFTER USER APPROVAL**, create the subtask(s).

**Execution order: (1) Create all subtasks → (2) Link dependencies → (3) Update Story description**

```typescript
// ── Phase 1: Create subtasks ──────────────────────────────────
// ⚠️ CRITICAL field values for WAO project:
//   issue_type: "Subtask" (NOT "Sub-task")
//   parent: "WAO-XXX" (string, NOT {"key": "WAO-XXX"})
//   customfield_10025: Start date

jira_create_issue({
  project_key: "WAO",
  issue_type: "Subtask",
  summary: "Research X",
  description: "Structured description (Objectives/Scope/Deliverables/Schedule)",
  additional_fields: {
    "parent": "WAO-251",
    "priority": {"name": "1"},
    "customfield_10025": "2026-02-09",  // Start date
    "duedate": "2026-02-10",
    "assignee": {"id": "accountId"}
  }
})
// → WAO-AAA created

jira_create_issue({ ... })  // → WAO-BBB created
jira_create_issue({ ... })  // → WAO-CCC created

// ── Phase 2: Link dependencies (after all subtasks exist) ─────
// "inward_issue blocks outward_issue"
// i.e., outward_issue is blocked by inward_issue

jira_create_issue_link({
  type: "Blocks",
  inward_issue: "WAO-AAA",    // blocker (Research)
  outward_issue: "WAO-BBB"    // blocked (Design)
})

jira_create_issue_link({
  type: "Blocks",
  inward_issue: "WAO-BBB",    // blocker (Design)
  outward_issue: "WAO-CCC"    // blocked (Implement)
})

// ── Phase 3: Update Story description with subtask refs ───────
// ⚠️ DEFERRED TOOL: Must call ToolSearch("select:mcp__atlassian__jira_update_issue") first!
jira_update_issue({
  issue_key: "WAO-251",
  fields: { "description": "Updated description with subtask references" }
})
```

See `references/jira_commands.md#issue-operations` for full reference.

After creation, present a summary:

```text
✓ Created 3 subtasks for WAO-251:

WAO-AAA (2/9-10) ──blocks──→ WAO-BBB (2/10-11) ──blocks──→ WAO-CCC (2/11-13)
  Research [P1]                 Design [P1]                   Implement [P2]

Links:
- https://mindai.atlassian.net/browse/WAO-AAA
- https://mindai.atlassian.net/browse/WAO-BBB
- https://mindai.atlassian.net/browse/WAO-CCC

Would you like to:
1. Update the Story description with these subtask references
2. Proceed to SubtaskToNanotask for nanotask decomposition
3. Return to Story overview
```

---

## Validation Checklist

Before calling `jira_create_issue`, verify:

- [ ] Have you discussed objectives with user?
- [ ] Have you discussed scope with user?
- [ ] Have you discussed deliverables with user?
- [ ] Have you confirmed schedule (start date + due date) for each subtask?
- [ ] Have you confirmed dependency chain (Blocks/Blocked by) between subtasks?
- [ ] Has user explicitly approved the content?
- [ ] Is the description structured (Objectives/Scope/Deliverables/Schedule)?

**If any checkbox is unchecked, DO NOT create the subtask. Return to Step 3.**

---

## Example Conversation

### Example A: Multiple subtasks with dependency chain

**Agent:** (After Step 1)

```text
Story: WAO-251 - Build Workflow Strategy foundation
Parent Epic: WAO-180 - [Validation] Strategy Evolution

Objectives: Realize pcr_skill_networking PoC into MEGA's workflow optimization
Scope: Skill Definition → Design → Injection → Evaluation → Tracking

No existing subtasks.

What subtasks would you like to create for this Story?
```

**User:** 3 subtasks: Research, Design, Implement. Research 9-10, Design 10-11, Implement 11-13.

**Agent:** (Step 3 - Collaborative Planning, abbreviated)

```text
Here's my understanding of the 3 subtasks:

1. **Research Skill making system** (2/9-10, P1)
   - Deep research on skill-making methodologies
   - Analyze GH's SKILL Evolution, Superpowers repo

2. **Design MEGA workflow strategy lifecycle** (2/10-11, P1)
   - Lifecycle design: generation → injection → evaluation → tracking
   - Blocked by: Research

3. **Implement Workflow Strategy lifecycle** (2/11-13, P2)
   - Implementation + A/B testing
   - Blocked by: Design

Dependency chain:
Research (2/9-10) ──blocks──→ Design (2/10-11) ──blocks──→ Implement (2/11-13)

Does this capture what you want? Any changes to scope, schedule, or dependencies?
```

**User:** Looks good, create them

**Agent:** (Step 4 - Draft)

```text
| # | Title | Schedule | Priority | Dependencies |
|---|-------|----------|----------|--------------|
| 1 | Research Skill making system | 2/9 - 2/10 | P1 | — |
| 2 | Design MEGA workflow strategy lifecycle | 2/10 - 2/11 | P1 | Blocked by #1 |
| 3 | Implement Workflow Strategy lifecycle | 2/11 - 2/13 | P2 | Blocked by #2 |

#1 (2/9-10) ──blocks──→ #2 (2/10-11) ──blocks──→ #3 (2/11-13)

Confirm to create all 3?
```

**User:** Confirm

**Agent:** (Step 5 - Create)

```text
✓ Created 3 subtasks for WAO-251:

WAO-272 (2/9-10) ──blocks──→ WAO-273 (2/10-11) ──blocks──→ WAO-274 (2/11-13)
  Research [P1]                 Design [P1]                   Implement [P2]

Links:
- https://mindai.atlassian.net/browse/WAO-272
- https://mindai.atlassian.net/browse/WAO-273
- https://mindai.atlassian.net/browse/WAO-274

Would you like to:
1. Update the Story description with these subtask references
2. Proceed to SubtaskToNanotask for nanotask decomposition
3. Return to Story overview
```

### Example B: Single subtask with existing dependencies

**Agent:** (After Step 1)

```text
Story: WAO-252 - Preparing MEGA Strategy integration

Existing subtasks:
1. WAO-264 - QA lifecycle-related functions [In Progress] (2/5-7)
2. WAO-265 - Integrate wisdom graph [To Do] (2/7-9, blocked by WAO-264)
3. WAO-266 - Refactor wisdom graph [In Progress] (2/6-8)

Story scope mentions "Verify PCR Networking" but no subtask exists for it.
Would you like to create a subtask for it?
```

**User:** Yes, after wisdom graph integration and refactoring are done

**Agent:** (Step 4 - Draft)

```text
**Title:** Verify PCR Networking in integrated MEGA

Objectives:
- Validate PCR networking after wisdom graph integration
- Performance test PCR calls under load

Scope:
- Unit + integration tests, performance benchmarks
- Excluded: E2E optimization tests

Deliverables:
- Test suite (pytest), benchmark report

**Schedule:** 2/9 - 2/11
**Priority:** 1 (Critical)
**Blocked by:** WAO-265 (Integrate), WAO-266 (Refactor)
**Assignee:** You

Existing chain with new subtask:
WAO-264 (2/5-7) ──→ WAO-265 (2/7-9) ──→ WAO-NEW (2/9-11)
WAO-266 (2/6-8) ─────────────────────────↗

Confirm to create?
```

**User:** Confirm

**Agent:** (Step 5 - Create)

```text
✓ Created Subtask WAO-267: Verify PCR Networking in integrated MEGA
  Schedule: 2/9 - 2/11 | Blocked by: WAO-265, WAO-266

Link: https://mindai.atlassian.net/browse/WAO-267

Would you like to create another subtask?
```

---

## Invocation from SubtaskToNanotask (Escalate)

StoryToSubtask can be invoked mid-flow from SubtaskToNanotask Step 3 (Escalate option).

**Context:** SubtaskToNanotask discovered a gap in subtask decomposition during plan review.

**What changes:**

| Aspect | Normal Invocation | Escalate Invocation |
| --- | --- | --- |
| Entry point | Step 0 (Select Story) | Step 2 (Identify Subtask) |
| Context gathering | Step 1 fetches from Jira | Reuses SubtaskToNanotask context |
| After creation | Offers "create another" | Returns to SubtaskToNanotask Step 2 |

**Flow:** Steps 2 → 3 → 4 → 5, then return control to SubtaskToNanotask.

**On return:** Pass the newly created subtask key back so SubtaskToNanotask can include it in nanotask planning.

---

## Edge Cases

### User Wants to Skip Planning

If user says "just create it", politely insist:

```text
I need to discuss the details with you first to ensure the subtask is well-structured and achievable.

This will only take a minute. Let's start with:
What is the goal of this subtask?
```

### User Provides Vague Requirements

Ask clarifying questions:

```text
Can you be more specific about [aspect]?

For example:
- What exactly needs to be tested?
- What artifact will be produced?
- Are there dependencies on other work?
```

### Parent Story Has No Clear Scope

```text
The parent Story doesn't have a clear scope/deliverables section.

Before creating subtasks, should we:
1. Review and update the Story description
2. Proceed with subtask planning (I'll infer from context)
```

---

## Session Management

If `[CONTEXT ALERT]` appears during planning, follow the Checkpoint Protocol (`docs/checkpoint.md`):
save current planning state to a Claude Code task, then end the session.

---

## References

- Common patterns: `references/common_patterns.md`
- JQL/MCP: `references/jira_commands.md`
- Checkpoint: `docs/checkpoint.md`
