# MCP 说明

## 服务清单

| 服务 | 用途 | DSH | opencode | Codex | Claude Code | Zed |
|---|---|---|---|---|---|---|
| `mysql` | **只读**查询测试库（写操作禁用） | ✅ | — | ✅ | — | 片段 |
| `mysql-test` | test 库，包装脚本**开着写 + DDL** | ✅ | ✅ | ✅ | ✅ | 片段 |
| `mysql-dev` | dev 库，包装脚本**开着写 + DDL** | ✅ | ✅ | ✅ | ✅ | 片段 |
| `mcp-obsidian` | Obsidian Vault 读写（Local REST API） | ✅ | ✅ | ✅ | ✅ | 片段 |
| `gitnexus` | 代码知识图谱：查询/影响分析/重构 | ✅ | — | ✅ | — | 片段 |
| `toolknit` | 本地文件工作台：PDF/PPT/音视频/图像/硬件（46 个 MCP 工具） | — | ✅ | — | ✅ | 片段 |
| `search-service` | 本地 Python 搜索服务（trae_projects） | — | — | — | ✅ | — |
| `github` | GitHub 官方远程 MCP（streamable-http） | ✅ | — | — | — | — |
| `node_repl` | Codex CUA 运行时（桌面版专属，路径含 hash，未同步） | 注释 | — | 可选 | — | — |

> ⚠️ **`mysql-dev` / `mysql-test` 是写权限连接**。它们的包装脚本把
> `ALLOW_DDL_OPERATION` / `ALLOW_INSERT` / `ALLOW_UPDATE` / `ALLOW_DELETE` 全设为
> `true`，用于造数与验证。若只想只读，把包装脚本里对应项改成 `false`，或直接
> 用 `mysql`（只读）那一条。

## 模板占位符

| 模板 | 机制 | 说明 |
|---|---|---|
| `opencode.json` | `{env:VAR}` | opencode 原生插值，启动时读系统环境变量 |
| `codex-config.toml` | `__VAR__` | install.ps1 从 `secrets.env` 替换 |
| `claude-mcp.json` | `__VAR__` + `<USER>` | 同上；`<USER>` 是 Windows 用户名占位符 |
| `zed-settings.fragment.json` | `__VAR__` + `<USER>` | 同上（需手动合并进 settings.json） |
| `dsh-cordis-patch.fragment.yml` | `__VAR__` + `!!js process.env.X` | 机密全部走 `!!js` 从环境变量读，文件内零明文 |
| `../wrappers/*.cmd` | `__VAR__` | install.ps1 渲染后装到 `~/.mcp/` |

### `<USER>` 占位符

Claude / Codex / DSH / Zed 的模板里，Windows 用户目录写作 `C:\Users\<USER>\...`。
`install.ps1` **不**替换它（只替换 `__VAR__`），所以：

- 用 `install.ps1` 安装时，脚本会按当前用户名自动渲染这几处路径；
- 手工复制模板时，请自行把 `<USER>` 换成你的用户名。

## 密钥边界

- 真实域名（`MYSQL_HOST` / `MYSQL_DEV_HOST` / `MYSQL_TEST_HOST`）**不入库**，只以
  `__VAR__` 或 `{env:VAR}` 形式出现。
- 密码、API Key、GitHub token 一律不入库；DSH 片段用 `!!js process.env.X` 读取。
- `127.0.0.1` 这类回环地址保留原样（本机端口，非隐私）。

## 新增 MCP 的步骤

1. 在对应模板里加配置（保持脱敏）
2. opencode 模板同时更新 `mcp` 段；DSH 片段更新 `insert:` 列表
3. 本机验证：`opencode mcp list` / `dsh` 里看 MCP 载入
4. 更新本文件的服务清单

## GitNexus 注意

- `gitnexus.cmd` 在 PATH 中即可（npm 全局安装）
- 每个仓库需要先 `gitnexus analyze` 才有数据；同名多分支仓库用路径区分

## ToolKnit 注意

- 安装：`npm install --global @toolknit/cli`；音视频工具需要 FFmpeg（`winget install Gyan.FFmpeg`），PDF 加解密/压缩自带 qpdf
- 本地文件工具（PDF/图像/硬件/文本）不需要 AI Key；AI 文档/表格/PPT 大纲/转写 refine 需要 `DEEPSEEK_API_KEY` 或 `TOOLKNIT_AI_API_KEY`
- 验证：`toolknit doctor --json`（看 qpdf/ffmpeg 是否 available）

## DSH 注意

`dsh-cordis-patch.fragment.yml` 的目标文件是 `~/.dsh/profiles/desktop/cordis.patch.yml`。
该文件**同时持有模型与 UI 插件配置**，所以：

- 只把片段里的 `insert:` 条目合并进去，**不要整文件覆盖**；
- `!!js` 表达式由 DSH profile 的 YAML 加载器求值，密钥从进程环境读取；
- 合并后重启 DSH 生效。
