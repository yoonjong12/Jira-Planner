# Uninstall Guide

## For Agents — Interactive Uninstall Protocol

**You are guiding a human through uninstallation. Follow this script step by step.**

- ONE step at a time. Wait for user response before next step.
- YOU perform all actions. The user only confirms.
- If user says "Uninstall Jira Planner", start from Step 1.

---

### Step 0: Confirm Intent

**Say to user:**

```text
Jira Planner 삭제를 시작합니다.

삭제하면 다음이 복구됩니다:
1. MCP 서버 (atlassian) — ~/.claude.json에서 제거
2. markdown-reader skill — ~/.claude/skills/markdown-reader/ 제거
3. Guardrail Hooks — .claude/settings.json에서 제거
4. 권한 Deny 규칙 — .claude/settings.local.json에서 제거
5. Task 영속성 설정 (CLAUDE_CODE_TASK_LIST_ID)

Skill 디렉토리(.claude/jira-planner/)와 작업 파일(space/)은 유지됩니다.
필요하면 수동으로 삭제할 수 있습니다.

진행할까요? (보존 옵션도 가능합니다)
```

**Wait for user confirmation.**

**If user asks about options, present:**

```text
보존 옵션:
- MCP 유지: Atlassian MCP를 다른 용도로도 쓰고 있다면 유지
- Task 유지: Claude Code task 데이터를 보존

어떤 옵션이 필요하신가요?
```

Collect user preferences → map to script flags:
- MCP 유지 → `--keep-mcp`
- Task 유지 → `--keep-tasks`

---

### Step 1: Dry Run

Run the uninstaller in dry-run mode first to show what will be removed:

```bash
bash .claude/jira-planner/scripts/uninstall.sh --dry-run
```

**Show output to user and say:**

```text
위 항목이 제거됩니다. 진행할까요?
```

**Wait for confirmation.**

---

### Step 2: Execute Uninstall

Run the uninstaller with user-selected flags:

```bash
# No options (full removal)
bash .claude/jira-planner/scripts/uninstall.sh

# With options (example)
bash .claude/jira-planner/scripts/uninstall.sh --keep-mcp --keep-tasks
```

---

### Step 3: API Token Warning

**If MCP was removed (no --keep-mcp), say to user:**

```text
Atlassian API Token이 ~/.claude.json에서 제거되었습니다.

보안을 위해 토큰을 Atlassian에서도 폐기(revoke)하세요:
https://id.atlassian.com/manage-profile/security/api-tokens

(Jira Planner를 다시 설치할 때 새 토큰을 발급받으면 됩니다.)
```

---

### Step 4: Verify & Restart

**Say to user:**

```text
삭제 완료!

Claude Code를 재시작해 주세요.
(/exit 후 claude 재실행)

Skill 파일을 완전히 삭제하려면:
  rm -rf .claude/jira-planner/

재설치가 필요하면 "Install Jira Planner"로 다시 시작할 수 있습니다.
```

---

## What Gets Removed

| File | Removed | Notes |
|------|---------|-------|
| `~/.claude.json` → `mcpServers.atlassian` | Yes (unless --keep-mcp) | API token 포함 |
| `~/.claude/skills/markdown-reader/` | Yes | SKILL 디렉토리 |
| `.claude/settings.json` → `hooks` (jira-planner entries) | Yes | 다른 hooks는 유지 |
| `.claude/settings.json` → `env.CLAUDE_CODE_TASK_LIST_ID` | Yes | |
| `.claude/settings.local.json` → deny rules (3 entries) | Yes | |
| `~/.claude/tasks/{ID}/` | Yes (unless --keep-tasks) | |

## What Stays

| Path | Reason |
|------|--------|
| `.claude/jira-planner/` | Skill files — 사용자가 수동 삭제 |
| `.claude/jira-planner/space/` | 작업 계획 파일 — 수동 삭제 |
| `.claude/settings.json` → non-jira-planner hooks | 다른 hook 보존 |
| `.claude/settings.local.json` → non-jira deny rules | 다른 deny rule 보존 |
