---
name: obsidian-vault
description: Search, create, and manage notes in the Obsidian vault with wikilinks and index notes. Use when user wants to find, create, or organize notes in Obsidian.
---

# Obsidian Vault

## 本机环境（2026-08 更新）

- **Vault 根目录**：`C:\Users\20301\Documents\Obsidian Vault\`
- **访问方式**：优先通过 **mcp-obsidian MCP 工具**读写，无需直接操作文件系统
- Obsidian 通过 "REST and MCP server" 插件对外提供 API（`https://127.0.0.1:27124`）

> [!warning] 旧内容弃用
> 本 skill 原版面向 WSL 路径 `/mnt/d/Obsidian Vault/AI Research/`（他机模板残留），该路径在本机**不存在**。原版用 bash `find`/`grep` 操作 vault 的方式**已不适用**，一律改用下方 MCP 工具。

## MCP 工具使用（首选）

直接调用 `obsidian_*` 工具即可，无需文件系统路径：

| 场景 | 工具 |
|------|------|
| 列目录 / 递归遍历 | `obsidian_list_notes` |
| 全文 / JSONLogic 搜索 | `obsidian_search_notes` |
| 读笔记（content/full/结构 map/单节） | `obsidian_get_note` |
| 新建 / 覆盖笔记 | `obsidian_write_note` |
| 追加内容 | `obsidian_append_to_note` |
| 按标题/块/元数据精准编辑 | `obsidian_patch_note` |
| 全文查找替换 | `obsidian_replace_in_note` |
| frontmatter 原子读写 | `obsidian_manage_frontmatter` |
| 标签管理 | `obsidian_manage_tags` |
| 在 Obsidian 界面打开 | `obsidian_open_in_ui` |

## MCP 配置与排障备忘（2026-08-17 实测）

- **配置位置**：`C:\Users\20301\.config\opencode\opencode.json` → `mcp.mcp-obsidian`
- **实现**：`npx.cmd -y obsidian-mcp-server`（cyanheads v3.2.12），local stdio transport，由 opencode 自动管理生命周期
- **端点**：`https://127.0.0.1:27124`（自签名证书）
- **必须** `OBSIDIAN_VERIFY_SSL=false`（该 server 内建跳过自签证书校验，官方 SDK 层实现，不需动进程级 TLS）
- **token**：`OBSIDIAN_API_KEY`（Bearer token 明文存于 opencode.json，本文件不重复存放）
- **协议**：MCP 2025-06-18 规范的 stdio 为 **JSONL**（`\n` 分隔）——手工测试时用 JSONL，不要用旧版 LSP `Content-Length` framing（cyanheads 读端实测不兼容）
- ❌ **不要用 remote 类型**配置 Obsidian：opencode 客户端（Node/undici）拒绝自签证书（`DEPTH_ZERO_SELF_SIGNED_CERT`），且 remote schema 无跳过证书选项
- ❌ `@oleksandrkucherenko/mcp-obsidian` 包在本机不可用（进程启动后 stdout/stderr 完全静默，无响应）
- 若 MCP 无响应：先确认 Obsidian 已启动、Local REST API 插件已启用、curl `https://127.0.0.1:27124/mcp/`（带 `Accept: application/json, text/event-stream`）能返回 200

## 本机笔记规范

- 技术文档：统一输出到 `文档/` 下，按 `设计文档/接口文档/ERD文档/表设计文档/流程图文档/测试文档/迭代文档/第三方平台接口文档/其他文档` 分类——完整规范见 **obsidian-docs** skill
- 日报：`馨恒泰日报/`，命名 `YY-MM-DD.md`
- 链接用 `[[wikilinks]]`，标签用 `#标签`（详见 obsidian-docs）
