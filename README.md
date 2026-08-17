# AI Agent 配置仓库

一套**跨 Agent 无缝切换**的 AI 编程助手配置：Skills（技能）+ MCP（外部工具）+ 插件 + 文档。
支持 opencode / Codex / Claude Code / Zed，备份到 GitHub 后可在任意新机器一键还原。

## 目录结构

```
ai-agent-config/
├── install.ps1              # 一键安装/切换（skills + MCP + 配置）
├── .env.example             # 密钥模板（复制为 secrets.env 填写，不入库）
├── skills/                  # 53 个通用 Skills（SKILL.md 格式，全 Agent 兼容）
├── mcp/
│   ├── templates/           # 各 Agent 的 MCP 配置模板（脱敏）
│   │   ├── opencode.json            # opencode 全量配置（provider + plugin + mcp）
│   │   ├── codex-config.toml        # Codex CLI 配置
│   │   ├── claude-mcp.json          # Claude Code ~/.claude/mcp.json
│   │   └── zed-settings.fragment.json # Zed settings.json 片段
├── plugins/
│   └── opencode-plugins.json # npm 插件清单（goal 模式、oh-my-openagent 等）
├── docs/
│   ├── skills-index.md            # 53 个技能索引
│   ├── switch-guide.md            # Agent 切换步骤
│   └── backend-standards-guide.md # 后端规范（backend-standards 技能依赖）
└── scripts/
    └── sync-skills.ps1       # 仅同步 skills（不碰配置）
```

## 快速开始（新机器/换 Agent）

1. `git clone` 本仓库到任意位置
2. 复制 `.env.example` → `secrets.env` 并填写真实密钥（MySQL 密码、Obsidian key、API keys）
3. 运行安装脚本，`-Agent` 选目标（可重复执行，配置会自动备份到 `backups/`）：

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -Agent opencode   # 或 codex / claude / zed / all
```

4. 重启 Agent 生效

## 安装了什么

| 组件 | opencode | Codex | Claude Code | Zed |
|---|---|---|---|---|
| Skills（53 个） | `~/.agents/skills/` | `~/.codex/skills/` | `~/.claude/skills/` | 同 Claude（如用 zed-claude 扩展） |
| MCP: mysql | ✅ | ✅ | ✅ | 手动合并 fragment |
| MCP: obsidian | ✅ | — | ✅ | 手动合并 |
| MCP: gitnexus | ✅ | 需 `gitnexus setup` | ✅ | 手动合并 |
| MCP: search-service | — | — | ✅ | — |
| 插件 | npm 插件（goal/oh-my-openagent） | — | 插件市场手动 | — |

> Skills 是通用 `SKILL.md` 格式，opencode 还会自动扫描 `~/.agents/skills`、`.claude/skills`；Codex 和 Claude Code 也原生读取，无需转换。

## 安全

- 所有密钥只存在于本地 `secrets.env`（已 gitignore）或模板的 `{env:VAR}` / `__VAR__` 占位符
- 提交前请确认没有真实密钥入库：`git grep -i "Sincere\|sk-cfyg\|c041a886"` 应为空

### 安全审计记录

| 日期 | 方式 | 结果 |
|---|---|---|
| 2026-08-17 | 内置正则扫描（API key / token / password / 私钥 / JWT 等 12 类模式） | ✅ 干净，仅占位符/示例命中（`your-xxx`、`sk-xxx`、`__VAR__`） |

> 建议安装 [gitleaks](https://github.com/gitleaks/gitleaks) 做 pre-commit 自动扫描：
> `gitleaks git --pre-commit --redact`（首次运行 `gitleaks detect` 全量扫描）

## 配套工具

- **GitNexus**：`gitnexus setup` 自动配 MCP；对每个仓库 `gitnexus analyze` 建知识图谱索引
- **oh-my-openagent / goal plugin**：opencode 的 goal 模式、后台代理等能力