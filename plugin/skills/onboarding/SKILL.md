---
description: "Resume work instantly — deterministic context injection from MEMORY.md, plan, and status."
allowed-tools: Read
---

Deterministic context injection for session resume. Every step is mandatory. Do not skip, reorder, or add agentic routing.

## Precondition

MEMORY.md must contain `active_story:` field under `# Context`.
If missing, STOP and tell user: "Run `/jira-planner:checkpoint` first."

## Steps

### Step 1: Parse MEMORY.md

MEMORY.md is auto-loaded in system prompt. Extract:

```
active_story: {epic_key}/{story_key}
```

Derive workspace path: `.claude/jira-planner/space/{epic_key}/{story_key}/`

### Step 2: Read plan.md

Read `{workspace}/plan.md`. Extract:

1. **Objectives / Scope / Deliverables** — what this story is about
2. **Nanotasks** — full task breakdown
3. **Dependency Chain** — execution order
4. **MUST READ** — reference file paths

### Step 3: Read status.md

Read `{workspace}/status.md`. Identify:

1. First `in_progress` nanotask (if any — this is the resume point)
2. First `pending` nanotask (if no in_progress — this is the next task)
3. Count of `completed` vs total (progress summary)

### Step 4: Read MUST READ files

For each path listed in `## MUST READ` of plan.md:

1. Read the file
2. If the file is large (>200 lines), read only the first 100 lines

These are reports, blueprints, or reference docs that provide essential context for the current story.

### Step 5: Output

Present a compact summary:

```
## Onboarding Complete

**Story:** {story_key} — {summary}
**Progress:** {completed}/{total} nanotasks

**Resume point:** [{id}] {type}: {summary}
  Plan: {workspace}/{nanotask_file}.md

**Context loaded:**
- plan.md (objectives, {N} nanotasks, {M} decisions)
- status.md ({completed} done, {in_progress} active, {pending} pending)
- {list of MUST READ files loaded}
```

Do NOT ask the user what to do next. The output speaks for itself.

## Error Cases

| Condition | Action |
|-----------|--------|
| No `active_story` in MEMORY.md | STOP: "Run `/jira-planner:checkpoint` first." |
| plan.md not found | STOP: "plan.md not found. Run `/jira-planner:subtask-to-nanotask` to plan first." |
| status.md not found | Warn: "status.md missing — planning is done but tasks were not created." |
| All nanotasks completed | Report: "All nanotasks completed. Close & Report or switch to a new story." |

ARGUMENTS: $ARGUMENTS
