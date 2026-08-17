# MCP 说明

## 服务清单

| 服务 | 用途 | opencode | Codex | Claude Code | Zed |
|---|---|---|---|---|---|
| `mysql` | 只读查询测试库 xht_scm（禁写） | ✅ | ✅ | ✅ | 片段 |
| `mcp-obsidian` | Obsidian Vault 读写（Local REST API） | ✅ | — | ✅ | 片段 |
| `gitnexus` | 代码知识图谱：查询/影响分析/重构 | ✅ | `setup` 后 | ✅ | 片段 |
| `search-service` | 本地 Python 搜索服务（trae_projects） | — | — | ✅ | — |
| `node_repl` | Codex CUA 运行时（桌面版专属，路径含 hash） | — | 可选 | — | — |

## 模板占位符

- **opencode**：`{env:VAR}` —— opencode 原生支持，启动时读系统环境变量（MYSQL_PASS、OBSIDIAN_API_KEY、MIMO_API_KEY、ZHIPU_API_KEY）
- **toml/json 模板**：`__VAR__` —— install.ps1 从 `secrets.env` 替换

## 新增 MCP 的步骤

1. 在对应模板里加配置（保持脱敏）
2. opencode 模板同时更新 `mcp` 段
3. 本机验证：`opencode mcp list`
4. 更新 README 的服务清单

## GitNexus 注意

- `gitnexus.cmd` 在 PATH 中即可（npm 全局安装）
- 每个仓库需要先 `gitnexus analyze` 才有数据；同名多分支仓库（如 changtai-cloud 4 个副本）用路径区分