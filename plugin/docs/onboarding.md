# Onboarding Protocol

Deterministic context injection for session resume. No agentic routing — follow steps exactly.

## Precondition

MEMORY.md must contain `active_story:` field under `# Context`.
If missing, STOP and tell user: "checkpoint를 먼저 실행하세요. (`/jira-planner:checkpoint`)"

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
| No `active_story` in MEMORY.md | STOP: "checkpoint를 먼저 실행하세요" |
| plan.md not found | STOP: "plan.md가 없습니다. `/jira-planner:subtask-to-nanotask`로 플래닝하세요" |
| status.md not found | Warn: "status.md 없음 — 플래닝은 완료됐지만 태스크가 생성되지 않았습니다" |
| All nanotasks completed | Report: "모든 나노태스크 완료. Close & Report 또는 새 스토리로 전환하세요" |
