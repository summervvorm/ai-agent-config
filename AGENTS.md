# AGENTS.md

本仓库是 AI 编程助手的配置仓库（skills + MCP + 插件），不是业务代码仓库。

## 你在本仓库中的职责

- 回答"如何配置/切换 Agent"类问题：参考 README.md 和 docs/switch-guide.md
- 修改配置模板（`mcp/templates/`、`plugins/`）时，保持**脱敏**：密钥一律用 `__VAR__`（toml/json 模板）或 `{env:VAR}`（opencode）占位符
- 修改 Skills 时遵守 SKILL.md 规范：frontmatter 必须含 `name`（匹配目录名）和 `description`；name 用小写字母数字+连字符
- 新增/删除 Skill 后同步更新 docs/skills-index.md
- 永不把 `secrets.env` 或真实密钥提交入库

## 常用命令

```powershell
# 安装/切换 Agent 配置
powershell -ExecutionPolicy Bypass -File install.ps1 -Agent opencode|codex|claude|zed|all

# 只同步 skills
powershell -ExecutionPolicy Bypass -File scripts\sync-skills.ps1
```