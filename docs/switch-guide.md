# 切换指南

本机已装 4 个 Agent（npm 全局）：opencode 1.18.18、@openai/codex 0.147.0、@anthropic-ai/claude-code 2.1.226、GitNexus 1.6.9。

## 从 opencode 切到 Codex

```powershell
cd <仓库位置>
Copy-Item .env.example secrets.env   # 首次，填好密钥
powershell -ExecutionPolicy Bypass -File install.ps1 -Agent codex
```

- Codex 读取 `~/.codex/skills/`，安装脚本会自动同步 53 个 skills
- 模型走本地代理 `http://127.0.0.1:15721/v1`（cc-switch），需先启动代理
- MySQL/Obsidian MCP 直接可用；GitNexus 需在目标仓库跑 `gitnexus analyze`（MCP 本身用 `gitnexus setup` 配）

## 从 opencode 切到 Claude Code

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -Agent claude
```

- 写 `~/.claude/mcp.json`（mysql/obsidian/gitnexus/search-service）
- 同步 skills 到 `~/.claude/skills/`
- 模型/代理配置在 `~/.claude/settings.json`（ANTHROPIC_BASE_URL 等），不在本仓库内（含 token），需自行迁移

## 切到 Zed

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -Agent zed
```

- 生成 `~/.config/zed/mcp.generated.json` 片段，需手动合并 `mcp` 数组到 `settings.json`
- Zed 本体不读 SKILL.md；若装 zed-claude 等扩展，skills 复用 `~/.claude/skills/`

## 切回 opencode

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -Agent opencode
```

- 生成 `~/.config/opencode/opencode.json`（provider + plugins + MCP，密钥用 `{env:VAR}` 引用系统环境变量）
- 记得设置环境变量：MYSQL_PASS、OBSIDIAN_API_KEY、MIMO_API_KEY、ZHIPU_API_KEY
- 同步 skills 到 `~/.agents/skills/`（opencode 自动扫描）

## 通用提示

- 所有安装脚本都会把被覆盖的旧配置备份到 `backups/<时间戳>/`，可随时回滚
- 换机器：clone → 填 secrets.env → install.ps1 -Agent all
- 索引过期：gitnexus 提示 stale 时在目标仓库跑 `gitnexus analyze`