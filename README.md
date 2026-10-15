# AI Agent 配置仓库

一套**跨 Agent 无缝切换**的 AI 编程助手配置：Skills（技能）+ MCP（外部工具）+ 插件 + 文档。
支持 DSH / opencode / Codex / Claude Code / Zed，备份到 GitHub 后可在任意新机器一键还原。

## 目录结构

```
ai-agent-config/
├── install.ps1              # 一键安装/切换（skills + MCP + 包装脚本 + 环境变量）
├── .env.example             # 密钥模板（复制为 secrets.env 填写，不入库）
├── skills/                  # 48 个通用 Skills（SKILL.md 格式，全 Agent 兼容）
├── mcp/
│   ├── README.md            # 服务清单、占位符机制、密钥边界
│   ├── templates/           # 各 Agent 的 MCP 配置模板（脱敏）
│   │   ├── dsh-cordis-patch.fragment.yml   # DSH cordis.patch.yml 片段
│   │   ├── opencode.json                   # opencode 全量配置（provider + plugin + mcp）
│   │   ├── codex-config.toml               # Codex CLI 配置
│   │   ├── claude-mcp.json                 # Claude Code ~/.claude/mcp.json
│   │   └── zed-settings.fragment.json      # Zed settings.json 片段
│   └── wrappers/            # 装到 ~/.mcp/ 的包装脚本（域名/密钥走占位符）
├── plugins/
│   └── opencode-plugins.json # npm 插件清单
├── docs/
│   ├── skills-index.md            # 技能索引
│   ├── switch-guide.md            # Agent 切换步骤
│   └── backend-standards-guide.md # 后端规范（backend-standards 技能依赖）
└── scripts/
    └── sync-skills.ps1       # 仅同步 skills（不碰配置）
```

## 快速开始（新机器/换 Agent）

1. `git clone` 本仓库到任意位置
2. 复制 `.env.example` → `secrets.env` 并填写真实值（数据库域名/密码、Obsidian key、各 provider API key、GitHub token）
3. 运行安装脚本，`-Agent` 选目标（可重复执行，配置会自动备份到 `backups/`）：

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -Agent dsh       # 或 opencode / codex / claude / zed / all
```

4. 重启 Agent 生效

## 安装了什么

| 组件 | DSH | opencode | Codex | Claude Code | Zed |
|---|---|---|---|---|---|
| Skills（48 个） | `~/.agents/skills/` | `~/.agents/skills/` | `~/.codex/skills/` | `~/.claude/skills/` | 同 Claude |
| MCP: mysql（只读） | ✅ | — | ✅ | — | 片段 |
| MCP: mysql-dev / mysql-test（可写） | ✅ | ✅ | ✅ | ✅ | 片段 |
| MCP: obsidian | ✅ | ✅ | ✅ | ✅ | 片段 |
| MCP: gitnexus | ✅ | — | ✅ | — | 片段 |
| MCP: toolknit | — | ✅ | — | ✅ | 片段 |
| MCP: search-service | — | — | — | ✅ | — |
| MCP: github（远程 http） | ✅ | — | — | — | — |
| 包装脚本 `~/.mcp/` | ✅ | — | ✅ | ✅ | ✅ |

> Skills 是通用 `SKILL.md` 格式。DSH 与 opencode 会自动扫描 `~/.agents/skills`；
> Codex 和 Claude Code 也原生读取，无需转换。
>
> DSH 的模板是**片段**而非整文件：`cordis.patch.yml` 同时持有模型与 UI 插件配置，
> 必须手工合并 `insert:` 条目，不能整文件覆盖。

## 安全

- 所有密钥只存在于本地 `secrets.env`（已 gitignore）或模板的 `{env:VAR}` / `__VAR__` / `!!js process.env.X` 占位符
- **服务器地址（数据库域名）同样不入库**，以 `__VAR__` 占位
- 本地用户名路径统一写作 `C:\Users\<USER>\...`；`127.0.0.1` 回环地址保留
- 提交前请确认没有真实值入库：

```powershell
# 通用凭据形态扫描，应为 0 命中（文档示例 ghp_xxx / sk-xxx / __VAR__ 除外）
git grep -inE "ghp_[A-Za-z0-9]{20}|github_pat_[A-Za-z0-9_]{30}|sk-[A-Za-z0-9]{20}|tp-[a-z0-9]{30}|user_[A-Za-z0-9]{40}|BEGIN [A-Z ]*PRIVATE KEY|Users[\\/][0-9]{3,}"
```

> 本仓库**刻意不记录**历史域名/主机名/密钥片段，连上面的自查命令也只放通用形态，
> 避免"为了自查反而把隐私写进公开仓库"。如果你需要按本机真实值精确比对，请把这些
> 值临时写进一个已 gitignore 的本地文件（如 `secrets.env`），不要写进 README。

### 安全审计记录

| 日期 | 方式 | 结果 |
|---|---|---|
| 2026-08-17 | 内置正则扫描（API key / token / password / 私钥 / JWT 等 12 类模式） | ✅ 干净，仅占位符/示例命中 |
| 2026-10-15 | 全量重新脱敏（skills 494 文件 + 全部 MCP 模板）：域名、密码、API Key、GitHub PAT、本地用户名路径 | ✅ 干净，仅 `ghp_xxx` / `sk-xxx` 文档示例命中 |

> 建议安装 [gitleaks](https://github.com/gitleaks/gitleaks) 做 pre-commit 自动扫描：
> `gitleaks git --pre-commit --redact`（首次运行 `gitleaks detect` 全量扫描）

## 配套工具

- **GitNexus**：`gitnexus setup` 自动配 MCP；对每个仓库 `gitnexus analyze` 建知识图谱索引
- **opencode-goal-plugin / dsh-model-proxy**：opencode 的 goal 模式与本地模型代理
