# Installation Guide

## For Agents — Interactive Installation Protocol

**You are guiding a human through installation. Follow this script step by step.**

- ONE step at a time. Wait for user response before next step.
- YOU perform all file edits. The user only provides information.
- If user says "Install Jira Planner", start from Step 1.

---

### Step 1: API Token

**Say to user:**

```text
Jira Planner 설치를 시작합니다.

Atlassian API Token이 필요합니다.
아래 링크에서 토큰을 발급받아 붙여넣어 주세요:

https://id.atlassian.com/manage-profile/security/api-tokens

(토큰은 수동 삭제 전까지 만료되지 않습니다.)
```

**Wait for user to paste token.**

**Then ask:**

```text
Atlassian 계정 이메일도 알려주세요. (예: name@wisdomgraph.ai)
```

**Collect:** `API_TOKEN` and `EMAIL` from user.

---

### Step 2: Configure Atlassian MCP (Agent does this)

**DO NOT ask user to edit files. You do it.**

Read `~/.claude.json`, then update the `mcpServers.atlassian` entry:

```bash
jq --arg email "$EMAIL" --arg token "$API_TOKEN" '
  .mcpServers.atlassian = {
    "command": "uvx",
    "args": ["mcp-atlassian"],
    "env": {
      "JIRA_URL": "https://mindai.atlassian.net",
      "JIRA_USERNAME": $email,
      "JIRA_API_TOKEN": $token,
      "CONFLUENCE_URL": "https://mindai.atlassian.net/wiki",
      "CONFLUENCE_USERNAME": $email,
      "CONFLUENCE_API_TOKEN": $token
    }
  }
' ~/.claude.json > ~/.claude.json.tmp && mv ~/.claude.json.tmp ~/.claude.json
```

Also install `markdown-reader` skill to the user's skills directory:

```bash
cp -r .claude/skills/jira-planner/scripts/markdown-reader ~/.claude/skills/
```

**Say to user:**

```text
설정 완료했습니다. Claude Code를 재시작해 주세요.
(/exit 후 claude 재실행)

재시작 후 "설치 계속" 이라고 말씀해 주시면 검증 단계로 넘어갑니다.
```

---

### Step 3: Verify Connection (after restart)

**Ask user for default project key:**

```text
설치할 Jira 프로젝트 키를 입력해 주세요 (예: WAO, PROJ, DEV):
```

**Collect:** `PROJECT_KEY` from user.

**Agent performs these calls silently:**

```typescript
// Test JQL search with user's project
jira_search({
  jql: `project = ${PROJECT_KEY} AND type = Epic ORDER BY updated DESC`,
  limit: 1,
  fields: "summary,status"
})
```

**If succeeds, say:**

```text
연결 확인 완료!

  Workspace: mindai.atlassian.net
  Project: ${PROJECT_KEY}
  Auth: API Token (영구)

다음으로 Guardrail Hook을 설치합니다.
```

**If fails, troubleshoot:**
- 401 → API token or email 오류. 재입력 요청.
- 404 → 프로젝트 키 확인 또는 접근 권한 확인 필요.
- Connection error → `uvx mcp-atlassian` 패키지 설치 확인.

---

### Step 4: Install Guardrail Hooks (Agent does this)

Run the installer:

```bash
bash .claude/skills/jira-planner/scripts/install-hooks.sh
```

This sets up:
- Task creation guard (CP1)
- Task deletion guard
- Jira description template validator
- Plan file format validator
- CLAUDE_CODE_TASK_LIST_ID for task persistence

**Say to user:**

```text
Guardrail Hook 설치 완료.

설치된 보호 장치:
- Jira 설명 템플릿 검증 (Context/Objective/Deliverables/AC)
- 태스크 생성 전 계획 파일 필수
- 태스크 삭제 방지
- 계획 파일 형식 검증

Note: 체크포인트는 이제 `/jira-planner checkpoint`로 호출하는 워크플로우입니다.
```

---

### Step 5: Configure Permissions (Agent does this)

Add deny rules to `.claude/settings.local.json`:

```bash
jq '.permissions.deny += [
  "mcp__atlassian__jira_transition_issue",
  "mcp__atlassian__jira_update_issue",
  "mcp__atlassian__jira_delete_issue"
] | .permissions.deny |= unique' .claude/settings.local.json > .claude/settings.local.json.tmp \
  && mv .claude/settings.local.json.tmp .claude/settings.local.json
```

**Say to user:**

```text
권한 설정 완료.

- 이슈 상태 변경(transition): 사용자 직접 실행만 가능
- 이슈 수정(update): 사용자 직접 실행만 가능
- 이슈 삭제(delete): 차단됨

Jira Planner 설치가 완료되었습니다!
재시작 후 /jira-planner 로 시작할 수 있습니다.
```

---

## Verification Checklist

Agent confirms all of these during Step 3-5:

- [x] `~/.claude.json` has atlassian in mcpServers (with API token)
- [x] `~/.claude/skills/markdown-reader/` exists
- [x] Can fetch WAO issues (`jira_get_issue`)
- [x] Can search issues (`jira_search`)
- [x] `.claude/settings.json` has guardrail hooks configured
- [x] `.claude/settings.local.json` denies mutation tools

## Troubleshooting

### Authentication Failed (401)

1. Verify API token is correct (regenerate if needed)
2. Check email matches your Atlassian account
3. Ensure `JIRA_URL` is `https://mindai.atlassian.net`

### MCP Server Not Appearing

1. Verify `~/.claude.json` has the atlassian entry in `mcpServers`
2. Restart Claude Code completely
3. Check for JSON syntax errors: `jq . ~/.claude.json`

### No Projects Visible

1. Verify you have WAO project access in Atlassian
2. Check with workspace admin for permissions

## References

- [Claude Code MCP Documentation](https://code.claude.com/docs/en/mcp)
- [mcp-atlassian (sooperset)](https://github.com/sooperset/mcp-atlassian)
