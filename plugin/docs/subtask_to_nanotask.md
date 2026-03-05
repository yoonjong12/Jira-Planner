# SubtaskToNanotask Workflow

Convert Jira Subtasks into Claude Code tasks with nanotask-level planning.

---

## Quick Reference

### Hierarchy

```
Epic (WAO-180)
└── Story (WAO-252)
    └── Subtask (WAO-264)           ← CC Task (group)
        ├── Nanotask [commit]   WAO-264-1   ← CC Task (work item)
        ├── Nanotask [design]   WAO-264-2   ← CC Task (work item)
        ├── Nanotask [review]   WAO-264-3   ← CC Task (work item)
        └── Nanotask [docs]     WAO-264-4   ← CC Task (work item)
```

### Blocking Rules

| CP | Gate | Verify |
| --- | --- | --- |
| CP1 | Plan files exist on disk | `ls space/{epic}/{story}/` shows plan.md + nanotask files |
| CP2 | User says "Approve" | Block until explicit approval |
| CP3 | TaskCreate called | Tasks visible in Claude Code |

### Routing

**Read this first. Find your scenario, go to that section.**

| Scenario | How to detect | Go to |
| --- | --- | --- |
| Cold start | No plan.md | → Cold Start |
| Partial plan | plan.md exists, no nanotask files | → Cold Start (skip Select Story) |
| Ready for approval | plan.md + nanotask files, no status.md | → Approval |
| Warm start | status.md exists | → Implementation |
| Add nanotask mid-work | During Implementation, missing nanotask found | → Amend Nanotask |
| Reopen completed nanotask | Completed nanotask needs follow-up under same goal | → Reopen Nanotask |
| Add subtask mid-review | During Approval, missing subtask found | → Escalate Subtask |
| Close out | All tasks done | → Close & Report |
| Context alert | `[CTX N%]` ≥ 90% | → see `docs/checkpoint.md` |

### Session Budget

Never mix planning and implementation in one session.

**At session start, tell user:** "컨텍스트가 부족해지면 '체크포인트'라고 요청해주세요."

| Session | Sections | Output |
| --- | --- | --- |
| **Planning** | Cold Start → Approval → Task Creation | plan.md + nanotask files + status.md + CC Tasks |
| **Implementation** | Implementation (+ Amend if needed) | Code / analysis / docs |

---

## Formats

### Jira Subtask Description (enforced by hook)

Every Jira subtask description MUST use this template. The `jira-description-guard.sh` hook blocks create/update without these 4 sections.

```text
h2. Context
[Why this task exists — prior task, background. 1-2 sentences.]

h2. Objective
[What we're doing. 1-2 sentences.]

h2. Deliverables
* [Output 1]
* [Output 2]

h2. Acceptance Criteria
* [Condition 1]
* [Condition 2]
```

Purpose: concise plan that lets a manager understand context, scope, and expected results at a glance. No implementation details, no nanotask breakdowns, no internal architecture.

### File Structure

```text
.claude/jira-planner/space/{epic-id}/{story-id}/
├── plan.md                    # Blueprint: objectives, nanotask definitions, decisions
├── status.md                  # Status tracker: nanotask current state (fast edit)
├── WAO-264-1.md               # Nanotask plan: subtask 264, nanotask 1
├── WAO-264-2.md               # Nanotask plan: subtask 264, nanotask 2
└── WAO-265-1.md               # Nanotask plan: subtask 265, nanotask 1
```

### plan.md Format

Blueprint — rarely modified after planning. Updated only when adding nanotasks or at Close.

```markdown
# Story WAO-252: [Summary]

## Objectives / Scope / Deliverables
[From Jira]

## Nanotasks

### WAO-264: [Summary]
[1] [commit] [Name]: [brief description]
[2] [analysis] [Name]: [brief description]

### WAO-265: [Summary]
[1] [docs] [Name]: [brief description]

## Dependency Chain
[Subtask/nanotask dependency graph]

## MUST READ
[Paths to reports, blueprints, or reference docs essential for this story's context.
These files are auto-loaded by /jira-planner:onboarding at session start.]

## Decisions
[Architectural choices made during planning/implementation]
```

### status.md Format

Fast-edit status tracker — updated at every checkpoint and task completion.

```markdown
# WAO-252 Status

**TASK_LIST_ID:** WAO-252

| ID | Type | Summary | Status | Hash | Updated |
|----|------|---------|--------|------|---------|
| 264-1 | commit | Add lifecycle tests | pending | - | - |
| 264-2 | analysis | Investigate feedback | pending | - | - |
| 265-1 | docs | Write integration guide | pending | - | - |
```

Status values: `pending`, `in_progress`, `completed`, `blocked`, `reopened`.

**Architecture:**
- **plan.md** = blueprint (nanotask definitions, context, decisions) — static after planning
- **status.md** = current state (status, hashes) — frequently edited
- **CC Tasks** = working interface (2-level hierarchy, dependencies, resume point) — synced from status.md at checkpoint

### Nanotask Plan Formats ({subtask-id}-{N}.md)

#### Type: commit (code change)

```markdown
# WAO-264-1: [Name]
**Type:** commit

## Goal
[One sentence]

## Diffs
### [Logical unit name]
- path/to/file.py:145-160
  contents: [What exactly doing]
  note: [Context if risky]

## Blocked by / Blocks
[WAO-XXX-N if any]

## Verify
[pytest command or make lint]
```

#### Type: design (conceptual / architecture)

Produces **design documents, architecture decisions, or conceptual explorations** — NOT code.

```markdown
# WAO-264-2: [Name]
**Type:** design

## Goal
[What design question to answer or architecture to define]

## Scope
- [Concepts / components / trade-offs to explore]
- [Existing code or docs to reference]
- [NOT in scope]

## Decision Points
- [Choices the user must make]

## Output
- [Document path or Jira comment]
```

#### Type: review (analysis / evaluation)

Investigates, compares, or evaluates existing code/data/artifacts.

```markdown
# WAO-264-3: [Name]
**Type:** review

## Goal
[What question to answer or what to evaluate]

## Scope
- [Files / modules / APIs to investigate]
- [Constraints: time, depth]

## Findings
[Filled after completion]

## Recommendation
[Action items or next nanotasks]
```

#### Type: docs (documentation)

```markdown
# WAO-264-4: [Name]
**Type:** docs

## Goal
[What document to produce]

## Outline
- [Section 1]
- [Section 2]

## Target Files
- path/to/docs/guide.md

## Review Criteria
[What makes this "done"]
```

#### Shared Rules

- `Blocked by` / `Blocks` support both subtask-level (`WAO-265`) and nanotask-level (`WAO-264-2`) references
- Nanotask numbers (`{N}`) are append-only; always increment, no gaps
- Execution order follows dependency graph, not number order
- Type `commit` requires `## Diffs` and `## Verify`
- Type `design` requires `## Decision Points` and `## Output`
- Type `review` requires `## Findings` (filled after completion)
- Type `docs` requires `## Outline` and `## Target Files`
- **Type selection is critical** — read SKILL.md "Nanotask Type Selection" table before assigning types

---

## Cold Start

Full planning flow: select story → explore → write plans → approve → create tasks.

### Select Story

**Skip if Story already provided via args or Start workflow context.**

```typescript
jira_search({
  jql: "project = WAO AND type = Story AND assignee = currentUser() AND status IN (\"In Progress\", \"진행 중\")",
  limit: 5,
  fields: "summary,status,parent,updated"
})
```

Present options, user picks a story. Then fetch Story context using `references/common_patterns.md#context-fetch`.

#### Story Transition

When switching to a **different Story** (new TASK_LIST_ID):

```text
1. CHECK: Read current settings.json env.CLAUDE_CODE_TASK_LIST_ID
2. IF different from new Story ID:
   a. Confirm with user: "현재 태스크 리스트는 {old_id}입니다. {new_id}로 전환할까요?"
   b. Update settings.json: env.CLAUDE_CODE_TASK_LIST_ID → new Story ID
   c. Bash("mkdir -p ~/.claude/tasks/{new_id}")
3. RESULT: TaskList now shows tasks for the new Story (old tasks preserved in ~/.claude/tasks/{old_id}/)
```

Previous Story's tasks are not deleted — they remain in `~/.claude/tasks/{old_id}/` and can be restored by switching back.

### Sync

Check local state and route:

```text
planExists?
├─ YES → Read plan.md
│         ├─ status.md exists → Warm Start (→ Implementation)
│         ├─ Nanotask files exist → go to Approval
│         └─ No nanotask files → continue to Plan & Write below
└─ NO → continue to Plan & Write below
```

### Plan & Write

**Goal:** Design nanotask plans and write all files in one pass.

```text
1. UNDERSTAND: Extract objectives from each Jira subtask
2. EXPLORE: Investigate codebase (parallel agents for 2+ subtasks)
3. DESIGN: Break each subtask into nanotasks, assign types (commit/analysis/docs)
4. WRITE: Create all plan files in one pass
5. VERIFY: ls to confirm files exist (CP1)
```

**Parallel exploration** (recommended for 2+ subtasks):

```text
# Launch parallel agents per subtask
Task(Explore, prompt="""
  Subtask: WAO-266 (Refactor wisdom graph)
  Nanotasks: [1] Extract storage, [2] Implement file backend

  For EACH nanotask, find:
  - Target files with line numbers
  - Dependencies and blockers
  - Verification command

  Return structured nanotask plan for each.
""", run_in_background=true)

# ... one agent per subtask, then collect results
```

**Write all files:**

```text
1. Bash("mkdir -p .claude/jira-planner/space/{epic-id}/{story-id}")
2. Write plan.md (blueprint only — no Progress table)
3. Write each {subtask-id}-{N}.md
4. Bash("ls -la .claude/jira-planner/space/{epic}/{story}/")
```

**CP1 — files must exist on disk before proceeding.**

### Context Management

Always delegate code exploration to subagents.

| Task | Owner |
| --- | --- |
| User questions/confirmation | Main agent |
| Codebase exploration | Task(Explore) |
| File comparison/analysis | Task(Bash) |
| Result synthesis/presentation | Main agent |

---

## Approval

**Goal:** Get user approval before creating tasks.

Present summary:
1. Tree (subtasks → nanotasks with types → file counts)
2. Dependency chain
3. Critical files (3-5)

```text
Story WAO-252: Preparing MEGA Strategy integration
├── WAO-264: QA lifecycle-related functions
│   ├── [1] [commit] Add lifecycle tests (3 files)
│   └── [2] [analysis] Investigate feedback loop
├── WAO-265: Integrate wisdom graph [blocked by WAO-266]
│   └── [1] [commit] WG merge (5 files)
└── WAO-266: Refactor wisdom graph [PRIORITY]
    ├── [1] [commit] Extract storage interface (2 files)
    └── [2] [commit] Implement file backend (3 files)

Approve this plan? (Approve / Revise / Escalate / Cancel)
```

**CP2 — User must explicitly say "Approve".**

| Response | Action |
| --- | --- |
| Approve | → Task Creation |
| Revise | → back to Plan & Write |
| Escalate | → Escalate Subtask |
| Cancel | abort |

---

## Task Creation

**Goal:** Create 2-level CC Task hierarchy + status.md.

### CC Tasks Limitation

CC Tasks API is a **flat list** — no parent/child relationship.
The 2-level hierarchy is expressed through **naming convention + blockedBy**:

| Level | Subject pattern | Example |
|-------|----------------|---------|
| Subtask (group) | `[WAO-{id}] {summary}` | `[WAO-264] QA lifecycle` |
| Nanotask (work) | `[{id}-{N}] {type}: {summary}` | `[264-1] commit: Add lifecycle tests` |

- Subtask → subtask ordering: `blockedBy` between subtask tasks
- Nanotask → subtask membership: inferred from ID prefix (`264-*` belongs to `WAO-264`)
- Cross-subtask nanotask deps: explicit `blockedBy` when needed

### Procedure

```text
1. FOR EACH subtask:
   TaskCreate({
       subject: "[WAO-264] QA lifecycle-related functions",
       description: "Subtask group. Nanotasks: 264-1, 264-2, 264-3, 264-4, 264-5",
       activeForm: "Managing WAO-264 nanotasks"
   })

2. FOR EACH nanotask:
   TaskCreate({
       subject: "[264-1] commit: Add lifecycle tests",
       description: "Plan: space/{epic}/{story}/WAO-264-1.md\n{goal}",
       activeForm: "{action description}"
   })

3. Set dependencies:
   # Subtask → subtask
   TaskUpdate({ taskId: "<WAO-265>", addBlockedBy: ["<WAO-266>"] })
   # Nanotask within subtask
   TaskUpdate({ taskId: "<264-1>", addBlockedBy: ["<264-5>"] })
   # Cross-subtask nanotask (if needed)
   TaskUpdate({ taskId: "<265-1>", addBlockedBy: ["<266-2>"] })

4. Verify:
   TaskList()
```

### Create status.md

```text
5. Write status.md with all nanotasks (initial: all pending)
6. Update MEMORY.md with Next TODO
```

**CP3 — TaskList confirms 2-level structure. status.md exists on disk.**

### Task List ID

`CLAUDE_CODE_TASK_LIST_ID` in `.claude/settings.json` determines which task list is active.
Set per-Story by `install-hooks.sh` (first time) or Story Transition (subsequent).
Tasks persist in `~/.claude/tasks/{id}/` — switching ID switches the visible list, old tasks preserved.

---

## Implementation

**Goal:** Execute nanotask plans.

### Warm Start Entry

If status.md exists:

```text
1. TaskList() — load 2-level task hierarchy
2. Read status.md — source of truth for nanotask statuses
3. IF tasks missing (e.g., nanotask added via Amend or Reopen):
   TaskCreate for missing nanotasks only
4. PRIOR ARTIFACTS: Before starting work on any nanotask, check for
   related completed nanotasks in status.md. If found:
   - Read their plan files (reports/, blueprint/, WAO-{id}-{N}.md)
   - These contain decisions, findings, and analysis already done
   - Do NOT re-investigate what prior nanotasks already documented
5. Continue below
```

### Process

```text
1. TaskList → show available nanotasks (non-blocked first)
2. User selects nanotask (e.g., "264-1")
3. TaskUpdate → mark in_progress
4. Read nanotask plan file
5. Execute based on type:
   - commit: Execute diffs in order, run verification
   - analysis: Investigate scope, fill Findings + Recommendation
   - docs: Write documents, check review criteria
6. On completion:
   - Edit status.md row → completed + hash
   - TaskUpdate → completed
7. Proceed to next
```

### Example

```text
TaskList output:
#1 [WAO-266] Refactor wisdom graph         (subtask)
  #2 [266-1] commit: Extract storage        pending
  #3 [266-2] commit: Implement backend      pending (blocked by #2)
#4 [WAO-265] Integrate wisdom graph         (subtask, blocked by #1)
  #5 [265-1] commit: WG merge               pending (blocked by #4)
#6 [WAO-264] QA lifecycle                   (subtask, blocked by #4)
  #7 [264-1] commit: Add lifecycle tests     pending

Available: #2 [266-1]
Which nanotask? > 266-1
```

### Context Checkpoint

See `docs/checkpoint.md`. Triggered by user saying "체크포인트".

Updates: MEMORY.md → status.md → CC Tasks.

---

## Amend Nanotask

**When:** During Implementation, a missing nanotask is discovered.

**Trigger:** User says "나노태스크 추가", "커밋 하나 더 필요" etc.

```text
1. IDENTIFY: User describes what's missing
2. EXPLORE: Investigate target code
3. WRITE: Create {subtask-id}-{N+1}.md (next sequence number)
   → Choose type: commit / analysis / docs
4. UPDATE:
   - Append [N+1] entry to plan.md under the subtask
   - Append row to status.md (pending)
   - TaskCreate for new nanotask + set dependencies
5. CONTINUE: Resume Implementation
```

**Constraints:**
- No Jira changes (nanotasks are SubtaskToNanotask's domain)
- Existing nanotask files untouched
- Sequence numbers always increment

---

## Reopen Nanotask

**When:** A completed nanotask needs follow-up work under the **same goal**.

**Trigger:** Post-completion issue found (e.g., review reveals gaps, test regression, follow-up analysis needed).

**Judgment — Reopen vs Amend (new):**

| Signal | Action |
| --- | --- |
| Follow-up serves the **same goal** as the original nanotask | **Reopen** the completed nanotask |
| Follow-up has a **different goal** (new scope, new deliverable) | **Amend** — create a new nanotask |

Examples:
- 292-4 "TDD 구현" completed → PCR 괴리 발견 → 같은 구현체의 품질 보강 = **Reopen 292-4**
- 292-4 "TDD 구현" completed → 새로운 모듈 추가 필요 → 새 deliverable = **Amend (292-10)**

```text
1. IDENTIFY: Describe what follow-up is needed and why
2. VERIFY GOAL: Is this the same goal as the original nanotask?
   YES → continue (Reopen)
   NO  → go to Amend Nanotask instead
3. UPDATE status.md: completed → reopened
4. UPDATE nanotask plan file: Add "## Follow-up" section with new scope
5. UPDATE CC Task: TaskUpdate → in_progress, add follow-up context to description
6. EXECUTE: Do the follow-up work
7. On completion:
   - Edit status.md row → completed + new hash
   - TaskUpdate → completed
```

**Constraints:**
- Do NOT create a new nanotask file — extend the existing one
- The nanotask plan file gets a `## Follow-up` section appended (original content preserved)
- status.md shows `reopened` then `completed` (audit trail)

---

## Escalate Subtask

**When:** During Approval, user identifies a missing subtask.

```text
1. → StoryToSubtask Steps 2-5 (reuse existing context)
     → Identify Subtask (user describes gap)
     → Collaborative Planning (Objectives/Scope/Deliverables)
     → Draft Content (user approval)
     → Create in Jira

2. → Return to Cold Start (Plan & Write)
     → Existing plans preserved
     → Re-run exploration for new subtask only
     → Update plan.md + write new {subtask-id}-{N}.md files

3. → Back to Approval
```

---

## Close & Report

**When:** All tasks done in Implementation.

```text
Agent: "모든 구현이 완료되었습니다. 레포트 작성으로 넘어갈까요?"
User: "예"
```

### Process

```text
1. COLLECT: git log + plan files + status.md + task list
2. DRAFT: Per-subtask report → present to user
3. REFINE: User feedback → incorporate
4. PUBLISH: Jira comment per subtask
```

### Report Format

```markdown
## WAO-264: [Subtask Summary]

### Summary
[1-2 sentences]

### Lessons Learned
- [Insight]

### Issues & Resolutions
- **Issue:** [What] → **Fix:** {hash}

### Nanotasks
| # | Type | Summary | Hash |
|---|------|---------|------|
| 1 | commit | Add lifecycle tests | abc123 |
| 2 | analysis | Investigate feedback loop | — |
```

Uses disk-based context, so works regardless of session state.

---

## Reference

### Quality Checklists

**Plan & Write:**
- [ ] Each subtask has a nanotask list with types
- [ ] Nanotask names are specific (include file/module names)
- [ ] Type `commit` has Diffs with file:line + Verify command
- [ ] Dependencies specified
- [ ] `## MUST READ` section lists reference docs (reports, blueprints)
- [ ] All files exist on disk (`ls` passed)

**Approval:**
- [ ] Tree summary with types shown
- [ ] Dependency chain + MUST READ references listed
- [ ] User explicitly said "Approve"

**Task Creation:**
- [ ] Subtask-level CC Tasks created (group headers)
- [ ] Nanotask-level CC Tasks created with dependencies
- [ ] status.md created with all nanotasks (initial: pending)
- [ ] TaskList confirms 2-level structure

**Close & Report:**
- [ ] Per-subtask report with Summary + Lessons + Nanotasks table
- [ ] Jira comments posted

### Common Issues

**Nanotask plan too abstract:**

Bad: `contents: add tests` → Good: `contents: Add test_lifecycle() with 3-phase test (generate→inject→evaluate)`

**Wrong nanotask type:**

`commit` = code change. `design` = conceptual/architecture (no code). `review` = analysis/evaluation. `docs` = documentation.

**Explore results insufficient:**

Agent found paths but no line numbers → Read file directly, identify function locations, add line numbers to plan.

**User wants to skip planning:**

Block. "Complete planning first. Current: {section}. Continue?"

### Links

- `references/plan_mode.md` — plan mode guide (use MCP to read sections)
- `references/common_patterns.md` — shared patterns
- `references/jira_commands.md` — JQL/MCP reference
- `references/guardrails.md` — hook-based enforcement
- `docs/checkpoint.md` — context checkpoint protocol
