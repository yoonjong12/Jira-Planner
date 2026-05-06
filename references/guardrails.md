# Jira Planner Guardrails

Advisory hook system — warns but never blocks.

## Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                  Jira Planner Guardrails (advisory)          │
├─────────────────────────────────────────────────────────────┤
│ PreToolUse Hooks (all allow + warning):                      │
│   ├── jira_create/update_issue → Warn on missing template    │
│   ├── TaskUpdate → Warn on deleting active tasks             │
│   └── Write(jira-planner/) → Warn on malformed plan files    │
│                                                              │
│ Removed:                                                     │
│   └── TaskCreate CP1 guard (moved to skill prompt)           │
└─────────────────────────────────────────────────────────────┘
```

---

## Hook 1: Jira Description Guard (advisory)

**Target Workflow:** EpicToStory, StoryToSubtask

**Trigger:** `jira_create_issue` or `jira_update_issue` with description field present

**Behavior:** Warns if description is missing Context/Objective/Deliverables/AC sections. Never blocks.

See `scripts/jira-description-guard.sh`.

---

## Hook 2: Task Delete Guard (advisory)

**Target Workflow:** SubtaskToNanotask

**Behavior:**
- `TaskUpdate(status=deleted)` on **completed** task → silent (no output)
- `TaskUpdate(status=deleted)` on **active** task → **warning** (allow + advisory)
- `TaskUpdate(status=completed)` → allow + reminder to update status.md

See `scripts/task-delete-guard.sh`.

---

## Hook 3: Plan File Format Validator (advisory)

**Target:** Write tool targeting `/jira-planner/` files

**Behavior:** Warns when plan.md, status.md, or nanotask files are missing required sections. Never blocks.

See `scripts/plan-format-validator.sh`.

---

## Removed: CP1 TaskCreate Guard

Previously blocked all `TaskCreate` calls when plan.md was missing from space/ directory. This was too broad — it fired on every TaskCreate in any context, not just during SubtaskToNanotask workflow.

Plan file prerequisites are now handled by the SubtaskToNanotask skill prompt routing table (Cold Start / Partial Plan scenarios).

---

## Configuration

Hooks are auto-discovered from `hooks/hooks.json` when the plugin is enabled. No manual installation required.

---

## Checkpoints by Workflow

### SubtaskToNanotask

| CP | Gate | Enforcement |
| --- | --- | --- |
| CP1 | Plan files exist on disk | Skill prompt routing (not hook) |
| CP2 | User says "Approve" | Skill prompt |
| CP3 | TaskCreate called | Tasks visible in Claude Code |
