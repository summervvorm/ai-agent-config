# 写 Agent Brief

Agent brief 是在 issue 或 PR 移到 `ready-for-agent` 时，附在 `.scratch/triage/issues/<id>.md` 里的一段结构化说明（原 skill 是贴在 issue tracker 上的评论）。它是 AFK agent 会照做的权威规格。原始正文与讨论只是上下文——**agent brief 才是契约**。

brief 说明 **agent 应该做什么**，两个面都覆盖：对 issue，是从零构建改动；对 PR，是对*现有 diff* 还差什么——收尾、补缺口、处理评审点。两种情况原则相同；下面的 PR 示例展示了差别。

## 原则

### 耐久优先于精确

issue 可能在 `ready-for-agent` 静置数天到数周。期间代码库会变。把它写得即使文件被重命名、移动或重构也仍然有用。

- **要** 描述接口、类型与行为契约
- **要** 点名 agent 应寻找或修改的特定类型、函数签名、配置形状
- **不要** 引用文件路径——它们会过期
- **不要** 引用行号
- **不要** 假设当前的实现结构保持不变

### 行为式，而非过程式

描述系统**应做什么**，而不是**怎么实现**。agent 会全新地探索代码库，自己做实现决策。

- **好：** "`SkillConfig` 类型应接受一个可选 `schedule` 字段，类型为 `CronExpression`"
- **坏：** "打开 src/types/skill.ts，在第 42 行加上 schedule 字段"
- **好：** "当用户要求运行 triage 技能而不带具体参数时，应看到一份待关注 issue 的摘要"
- **坏：** "在主 handler 函数里加一个 switch 语句"

### 完整的验收标准

agent 需要知道何时算做完。每条 agent brief 都必须有具体、可测的验收标准。每条标准应能独立验证。

- **好：** "运行 `Get-ChildItem .scratch/triage/issues | where { $_.state -eq 'needs-triage' }` 返回已通过初次分类的 issues"
- **坏：** "Triage 应该正常运作"

### 明确的边界

写明哪些超出范围。这能阻止 agent 过度设计或对相邻功能做假设。

## 模板

```markdown
## Agent Brief

**Category:** bug / enhancement
**Summary:** one-line description of what needs to happen

**Current behavior:**
Describe what happens now. For bugs, this is the broken behavior.
For enhancements, this is the status quo the feature builds on.

**Desired behavior:**
Describe what should happen after the agent's work is complete.
Be specific about edge cases and error conditions.

**Key interfaces:**
- `TypeName` — what needs to change and why
- `functionName()` return type — what it currently returns vs what it should return
- Config shape — any new configuration options needed

**Acceptance criteria:**
- [ ] Specific, testable criterion 1
- [ ] Specific, testable criterion 2
- [ ] Specific, testable criterion 3

**Out of scope:**
- Thing that should NOT be changed or addressed in this issue
- Adjacent feature that might seem related but is separate
```

## 示例

### 好的 agent brief（bug）

```markdown
## Agent Brief

**Category:** bug
**Summary:** Skill description truncation drops mid-word, producing broken output

**Current behavior:**
When a skill description exceeds 1024 characters, it is truncated at exactly
1024 characters regardless of word boundaries. This produces descriptions
that end mid-word (e.g. "Use when the user wants to confi").

**Desired behavior:**
Truncation should break at the last word boundary before 1024 characters
and append "..." to indicate truncation.

**Key interfaces:**
- The `SkillMetadata` type's `description` field — no type change needed,
  but the validation/processing logic that populates it needs to respect
  word boundaries
- Any function that reads SKILL.md frontmatter and extracts the description

**Acceptance criteria:**
- [ ] Descriptions under 1024 chars are unchanged
- [ ] Descriptions over 1024 chars are truncated at the last word boundary
      before 1024 chars
- [ ] Truncated descriptions end with "..."
- [ ] The total length including "..." does not exceed 1024 chars

**Out of scope:**
- Changing the 1024 char limit itself
- Multi-line description support
```

### 好的 agent brief（enhancement）

```markdown
## Agent Brief

**Category:** enhancement
**Summary:** Add `.scratch/triage/out-of-scope/` directory support for tracking rejected feature requests

**Current behavior:**
When a feature request is rejected, the issue is closed with a `wontfix` state
and a comment. There is no persistent record of the decision or reasoning.
Future similar requests require the maintainer to recall or search for the
prior discussion.

**Desired behavior:**
Rejected feature requests should be documented in
`.scratch/triage/out-of-scope/<concept>.md` files that capture the decision,
reasoning, and links to all issues that requested the feature. When triaging
new issues, these files should be checked for matches.

**Key interfaces:**
- Markdown file format in `.scratch/triage/out-of-scope/` — each file should
  have a `# Concept Name` heading, a `**Decision:**` line, a `**Reason:**`
  line, and a `**Prior requests:**` list with issue links
- The triage workflow should read all `.scratch/triage/out-of-scope/*.md`
  files early and match incoming issues against them by concept similarity

**Acceptance criteria:**
- [ ] Closing a feature as wontfix creates/updates a file in
      `.scratch/triage/out-of-scope/`
- [ ] The file includes the decision, reasoning, and link to the closed issue
- [ ] If a matching `.scratch/triage/out-of-scope/` file already exists, the
      new issue is appended to its "Prior requests" list rather than creating
      a duplicate
- [ ] During triage, existing `.scratch/triage/out-of-scope/` files are
      checked and surfaced when a new issue matches a prior rejection

**Out of scope:**
- Automated matching (human confirms the match)
- Reopening previously rejected features
- Bug reports (only enhancement rejections go to `.scratch/triage/out-of-scope/`)
```

### 好的 agent brief（PR）

对 PR，"Current behavior" 描述 diff 的状态，brief 请 agent 收尾或修复它，而不是从零构建。

```markdown
## Agent Brief

**Category:** enhancement
**Summary:** Finish the contributor's `--json` output flag for `triage list`

**Current behavior:**
The PR adds a `--json` flag that serializes the issue list to JSON. The happy
path works and the diff matches the project's command structure. Two gaps
remain: errors are still printed as human text (not JSON), and the new flag has
no test coverage.

**Desired behavior:**
With `--json`, all output — including errors — is well-formed JSON on stdout,
and the command's exit codes are unchanged. The existing human-readable output
is untouched when the flag is absent.

**Key interfaces:**
- The command's error path should emit `{ "error": string }` under `--json`
  instead of the plain-text error
- Reuse the existing serializer the PR already added; don't introduce a second

**Acceptance criteria:**
- [ ] `triage list --json` emits valid JSON for both success and error cases
- [ ] Exit codes match the non-JSON command
- [ ] A test covers the `--json` success output and one error case
- [ ] Default (non-JSON) output is byte-for-byte unchanged

**Out of scope:**
- Adding `--json` to any other command
- Changing the JSON shape of the success payload the PR already defined
```

### 坏的 agent brief

```markdown
## Agent Brief

**Summary:** Fix the triage bug

**What to do:**
The triage thing is broken. Look at the main file and fix it.
The function around line 150 has the issue.

**Files to change:**
- src/triage/handler.ts (line 150)
- src/types.ts (line 42)
```

这之所以坏，是因为：
- 没有 category
- 描述含糊（"the triage thing is broken"）
- 引用了会过期的文件路径和行号
- 没有验收标准
- 没有范围边界
- 没有对当前 vs 期望行为的描述
