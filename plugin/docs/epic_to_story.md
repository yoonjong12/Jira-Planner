# EpicToStory Workflow

Plan Stories under an Epic with structured guidance.

**Goal:** Create well-structured, achievable plans through iterative refinement.

**Key principle:** Actively help users create systematic, explicit, clear plans — not arbitrary ticket filling.

## Storage

```text
.claude/jira-planner/space/{epic-id}/
├── story.md                    # Story plans
└── {story-id}-subtasks.md      # Optional subtask plans
```

## Steps

### Step 0: Select Epic

**Skip if Epic already provided via args.**

```typescript
jira_search({
  jql: "project = WAO AND type = Epic AND status IN (Open, \"In Progress\") ORDER BY updated DESC",
  limit: 5,
  fields: "summary,status,updated"
})
```

Present:

```text
Which Epic would you like to plan Stories for?

1. WAO-180 - [Validation] Strategy Evolution [In Progress]
2. WAO-175 - Wisdom Graph optimization [Open]

Enter Epic key (e.g., WAO-180) or select number.
```

---

### Step 1: Fetch Epic

Fetch the selected Epic details.

```typescript
jira_get_issue({
  issue_key: epicKey,
  fields: "summary,description,status,duedate"
})
```

Present:

```text
Epic: WAO-XXX - [Title]
Status: [Status] | Due: [Date]

[Description]

Have you decided on the stories you want to create?
```

---

### Step 2: Story Ideas Discussion

Listen to user's story proposals. For each:

- Main objective
- Rough scope
- Expected deliverables

Ask clarifying questions if vague.

---

### Step 3: Structured Story Planning

**Required sections:**

Use Plan Structure from `references/common_patterns.md#plan-structure`.

**Review criteria:**

- [ ] Objectives are clear and measurable
- [ ] Scope is explicit (in/out)
- [ ] Deliverables are concrete
- [ ] Timeline is realistic
- [ ] "Done" is unambiguous

**Iterative process:**

1. User provides draft
2. Agent formats with sections
3. Agent identifies gaps/ambiguities:
   - "The objective mentions 'integration' but doesn't specify what systems?"
   - "The scope doesn't clarify if testing is included?"
   - "What's the concrete deliverable? A PR? A report? Both?"
4. User refines based on feedback
5. Repeat until criteria met OR user requests to proceed

---

### Step 4: Subtask Planning (Optional)

Only if user requests or story is complex.

Same rigor applies - each subtask needs Objectives/Scope/Deliverables.

---

### Step 5: Finalization

1. Save to `space/{epic-id}/story.md`
2. Present final plan
3. Request confirmation
4. Create Jira Stories with Epic link
5. Confirm creation with issue keys

---

## Example Good Plan

```markdown
## Story: Build Workflow Strategy foundation

**Objectives**
- Design Workflow-level strategy architecture
- Implement PoC based on GH's SKILL pattern

**Scope**
- Included: Strategy structure, generation, injection, evaluation lifecycle
- Excluded: Integration with existing MEGA components (separate story)

**Deliverables**
- Workflow strategy design document (10-15 pages)
- PR: Merge workflow-strategy branch to main
- Working PoC demonstrating strategy injection

**Timeline**
- Start: 2026-02-01
- End: 2026-02-13
- Duration: 2 weeks (reasonable for PoC + documentation)
```

---

## Quality Checkpoints

**Story-level:**

- [ ] Objectives answer "What will this achieve?"
- [ ] Scope answers "What's included/excluded?"
- [ ] Deliverables answer "What proves completion?"
- [ ] Story fits Epic's goals and timeline

**Subtask-level (if applicable):**

- [ ] Each subtask < 1 week
- [ ] Subtasks sum to story
- [ ] No overlap between subtasks

**Integration:**

- [ ] Story links to correct Epic
- [ ] Dependencies on other stories are noted
- [ ] Assignee is set
- [ ] Priority aligns with Epic priority

---

## Common Issues

| Issue                    | Bad                              | Good                                                                                       |
| ------------------------ | -------------------------------- | ------------------------------------------------------------------------------------------ |
| Vague objectives | "Improve the system" | "Reduce latency by 30% through caching" |
| Missing scope | "Work on integration" | "Integrate wisdom graph into MEGA. Excludes: performance tuning, UI changes" |
| Non-concrete deliverables | "Better code" | "PR merging refactored wisdom graph module + integration test suite with >80% coverage" |
| Unrealistic timelines | "Rewrite entire system in 3 days" | "Refactor core module (500 LOC) in 1 week" |

---

## Tips for Agents

1. **Be persistent but not annoying:**
   - If plan is 80% there, ask 1-2 targeted questions
   - If plan is 50% there, point out multiple gaps at once
   - If user says "let's just go with this," respect it but note risks

2. **Use examples:**
   - "Like how WAO-251 specified 'PoC implementation' as a deliverable, what's the concrete output here?"

3. **Validate timelines:**
   - "This story includes 5 major components. 1 week seems tight. Consider 2 weeks or splitting into 2 stories?"

4. **Think about the developer:**
   - "If someone else reads this story 3 months from now, would they know exactly what to build?"

---

## Session Management

If `[CONTEXT ALERT]` appears during planning, follow the Checkpoint Protocol (`docs/checkpoint.md`):
save current planning state to a Claude Code task, then end the session.

---

## References

- Common patterns: `references/common_patterns.md`
- JQL/MCP: `references/jira_commands.md`
- Checkpoint: `docs/checkpoint.md`
