# MCP 说明

## 服务清单

| 服务 | 用途 | opencode | Codex | Claude Code | Zed |
|---|---|---|---|---|---|
| `mysql` | 只读查询测试库 xht_scm（禁写） | ✅ | ✅ | ✅ | 片段 |
| `mcp-obsidian` | Obsidian Vault 读写（Local REST API） | ✅ | — | ✅ | 片段 |
| `gitnexus` | 代码知识图谱：查询/影响分析/重构 | ✅ | `setup` 后 | ✅ | 片段 |
| `toolknit` | 本地文件工作台：PDF/PPT/音视频/图像/硬件（46 个 MCP 工具） | ✅ | — | ✅ | — |
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

## ToolKnit 注意

- 安装：`npm install --global @toolknit/cli`；音视频工具需要 FFmpeg（`winget install Gyan.FFmpeg`），PDF 加解密/压缩自带 qpdf
- 本地文件工具（PDF/图像/硬件/文本）不需要 AI Key；AI 文档/表格/PPT 大纲/转写 refine 需要 `DEEPSEEK_API_KEY` 或 `TOOLKNIT_AI_API_KEY`
- 验证：`toolknit doctor --json`（看 qpdf/ffmpeg 是否 available）；MCP 工具清单用 `opencode mcp list` 或 `toolknit --help`