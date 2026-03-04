# Checkpoint Protocol

Save all session state so the next session resumes with minimal token cost.

## Trigger

User invokes `/jira-planner checkpoint` when ready to save session state.

## Save (Checkpoint)

Write in importance order (smallest first = fail-safe).

### Step 0. Validate (read before write)

Cross-check active files for consistency before saving. Read:
- `plan.md` — nanotask list, dependency chain, key decisions
- `status.md` — status table
- Active nanotask files (`WAO-{subtask}-{n}.md`) for pending/in-progress items only

Check for:
- **Duplication**: Same diff/modification described in multiple nanotask files
- **Stale terms**: Deprecated terminology (e.g., old system names) in active docs
- **Inconsistency**: status.md rows vs plan.md nanotask list (missing/extra items, status mismatch)
- **Scope drift**: Nanotask content that contradicts current Key Decisions

Fix issues inline before proceeding to save steps. If no issues found, proceed directly.

### Step 1. MEMORY.md (compact, then write)

Write first — auto-loads on next session, fail-safe if session crashes mid-checkpoint.

**MEMORY.md has exactly 3 sections. No other sections allowed:**

```markdown
# Context
## Working Space
- Current epic/story summary (1-2 lines)
- Previous session summary (what was done, key findings, 3-5 lines max)

# Shortcuts
- Minimal paths for immediate codebase/doc access (table format)
- Only include paths that are actively referenced across sessions

# TODO
- Pending jobs with nanotask IDs
- Open questions that need resolution
- Do NOT include completed items or stable decisions
```

**Compaction rules:**
- **Target:** Under 50 lines. Anything stable belongs in code/config, not memory.
- **Remove** anything already encoded in code, config files, or CLAUDE.md rules.
- **Remove** completed TODOs — they live in status.md.
- **Remove** session-specific details older than 1 session.
- **Never include** key decisions, patterns, project structure, CLI commands that don't change.

### Step 2. status.md

Edit single rows — no full rewrite needed.
Path: `.claude/jira-planner/space/{epic-id}/{story-id}/status.md`

- Update Status column (`pending` → `in_progress` / `completed`)
- Add commit Hash for completed nanotasks
- Add Updated date
- Append new rows if nanotasks were added via Amend

### Step 3. CC Tasks (compact, then sync)

**Compaction first — remove noise, keep only actionable tasks:**

```text
1. TaskList() — read current state
2. FOR EACH completed task older than current subtask:
   TaskUpdate(status=deleted)  — historical record lives in status.md, not CC Tasks
3. FOR EACH task not in status.md (stale from prior Stories):
   TaskUpdate(status=deleted)
4. Result: CC Tasks contains only pending + in_progress + current subtask's completed
```

**Then sync remaining tasks to match status.md:**

- Completed (current subtask) → `TaskUpdate` status=completed
- In-progress → `TaskUpdate` with Progress block:

```text
## Progress
- In progress: [current work + exact resume point]
- Next: [exact next action]
```

- Pending → leave as-is
- Reopened → `TaskUpdate` status=in_progress, append follow-up context

## Restore (New Session)

Read in breadth order (summary first → detail).

1. MEMORY.md — auto-loaded in system prompt (resume context)
2. `TaskList` → 2-level hierarchy (subtask groups + nanotask work items)
3. `status.md` → current nanotask statuses
4. `plan.md` → blueprint context if needed (objectives, decisions)
5. **Prior artifacts** — for the target nanotask, read completed nanotasks in the same subtask (their plan files, reports/, blueprint/) to avoid re-investigating already documented findings
6. Resume from first pending/in-progress nanotask
