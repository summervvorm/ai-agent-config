---
name: browser-doc-fetcher
description: 通过模拟浏览器（Playwright + 系统浏览器）抓取整个文档站点的全部页面并保存为 Markdown 文件，保留原始目录结构。特别适用于 docsify/VuePress 等 SPA 文档站（如领星 apidoc.lingxing.com、各类开源项目文档站），也支持需要 JS 渲染或反爬限制的文档站点。当用户提到"抓取文档站点"、"下载整个文档站"、"把 XX 文档全部保存下来"、"抓取在线文档"、"批量下载 API 文档"、"用浏览器获取文档"、"爬取文档网站"、或提供一个文档站 URL 要求下载全部内容时，必须使用此技能。即使用户只说"把 https://xxx.com 文档下载下来"，也应触发。注意：此技能用于获取公开可访问的文档，不得用于绕过认证或抓取受保护/私有内容。
---

# 浏览器文档抓取技能

通过模拟浏览器方式抓取整个文档站点，保存为结构化的 Markdown 文件库。本技能封装了一套经过实战验证（领星 API 文档 625 个页面全量抓取）的可靠流程，优先获取干净的 Markdown 源码，回退到 DOM 渲染提取。

## 核心判断：先用浏览器，而非 curl/fetch

用户明确要求"模拟浏览器方式"，且很多文档站会拒绝非浏览器请求或依赖 JS 渲染。因此**始终使用 Playwright 的浏览器上下文发起请求**，它能带上真实 UA、Cookie、Referer，与真实浏览器无异。即使用 curl 看似能拿到内容，也优先用浏览器，因为：
- 部分站点对 curl 返回不同内容或 403
- 浏览器上下文自动处理 cookie/重定向
- 满足"模拟浏览器"的明确诉求，行为可预期

## 关键决策：检测站点类型，选择最优抓取策略

文档站主要有两类，抓取策略不同。**先探测再决定**，不要盲目套用一种方法：

### 类型 A：docsify 类站点（最常见，优先策略）

特征：URL 用 hash 路由（`/#/path`），页面内容是服务器上的独立 `.md` 文件，前端通过 AJAX 加载。

**探测方法**：请求 `<站点根>/_sidebar.md`，若返回有效 Markdown（含 `* [xxx](docs/...)` 这类链接），即为 docsify 站。

**抓取策略（首选，最快最干净）**：直接通过浏览器上下文 GET 每个 `.md` 源文件。docsify 把 markdown 原文放在服务器上，直接拉取源码能得到**最干净的内容**——表格、交叉链接、代码块全部完好，远胜于把渲染后的 HTML 再转回 Markdown（后者会破坏表格）。

### 类型 B：需要 JS 渲染的站点（回退策略）

特征：直接 GET `.md` 返回 HTML 或 404，内容必须等 JS 执行后才出现在 DOM 里（VuePress、Docusaurus、VitePress 等）。

**抓取策略**：用浏览器导航到每个页面路由，等待内容容器（常见选择器：`.markdown-section`、`.theme-default-content`、`main`、`article`）渲染完成，提取其 innerHTML，再用 turndown 转 Markdown。表格用 `turndown.keep(['table'])` 保留原始 HTML，避免转换损坏。

## 操作流程

### 第 1 步：探测站点类型

1. 用浏览器 GET `<根URL>/` 看首页，再 GET `<根URL>/_sidebar.md`。
2. 若 `_sidebar.md` 返回 Markdown 且含链接 → **docsify 路径**，跳到第 2A 步。
3. 否则 → **JS 渲染路径**，跳到第 2B 步。此时需要先找到站点地图/侧边栏导航（常见：`/sitemap.xml`、页面侧边栏 DOM、或 `/docs/.vitepress/sidebar.ts` 之类配置）来枚举全部页面 URL。

### 第 2A 步：docsify 抓取

1. 解析 `_sidebar.md`，正则提取所有 `(...)` 里的文档路径。**统一处理**：去掉前导 `/`、去掉结尾 `.md`、去重。注意 sidebar 里有的链接带 `.md` 有的不带，有的带前导 `/`，要归一化。
   - 提取正则：`/\((/)?docs\/[^)]+\)/g`（针对 docs/ 路径），或更通用的 `/\(([^)]+)\)/g` 后过滤掉 http(s) 外链和锚点。
2. 对每个路径，浏览器 GET `<根URL>/<path>.md`（若 path 已以 `.md` 结尾则不再追加）。
3. **内容校验**：状态码 200 + 内容不以 `<!DOCTYPE`/`<html` 开头（否则是 HTML 错误页，视为失败重试）。
4. 按 `<path 去掉 docs/ 前缀>` 作为相对路径写入输出目录，保留子目录结构。

### 第 2B 步：JS 渲染抓取

1. 枚举所有页面 URL（见第 1 步第 3 点）。
2. 浏览器导航到每个 URL，`waitUntil: 'domcontentloaded'`，再 `waitForFunction` 等内容容器 innerHTML 长度 > 50。
3. 提取容器 innerHTML，turndown 转 Markdown（表格 keep）。
4. 从 URL 推导输出文件路径。

### 第 3 步：并发与容错

- **并发**：开多个浏览器 context（建议 5 个），文档路径轮询分配到各 context，`Promise.all` 并发执行。单 context 串行请求，避免对站点压力过大。
- **重试**：每个文档失败重试 2 次，仍失败记入 failed 列表，最后输出。
- **断点续传**：写入前检查目标文件是否已存在且 > 20 字节，存在则跳过。这样中断后重跑不会重复抓取，也支持增量更新。
- **进度**：每 50 个打印一次 `[done/total] rate/s`。

### 第 4 步：生成导航索引（强烈建议）

抓完后生成一份 `README-导航索引.md`，按 sidebar 层级用 Obsidian wikilink（`[[相对路径|显示名]]`）组织，方便在 Obsidian 中浏览跳转。链接路径要去掉 `docs/` 前缀，与实际文件路径对齐。详见 `scripts/gen_index.js`。

## 浏览器选择：用系统 Edge，别下载 Chromium

**这是实战踩坑总结，务必遵守**：Playwright 默认要下载 Chromium，但在某些网络环境下 `npx playwright install chromium` 会卡死（只建目录不下文件）。系统已装的 Edge 可直接用，无需下载：

```js
const { chromium } = require('playwright');
const browser = await chromium.launch({ headless: true, channel: 'msedge' });
```

若系统无 Edge，再尝试 `channel: 'chrome'`，最后才回退到下载 Chromium。检测系统浏览器见 `references/troubleshooting.md`。

## 环境准备

1. **Node**：检查 `node --version`（需 ≥ 18）。
2. **Playwright 包**：在一个临时目录 `npm install playwright`。注意：本地装的 playwright 包需要自己的浏览器二进制，但因为用 `channel: 'msedge'` 指向系统 Edge，**无需额外 `npx playwright install`**。
3. **turndown**（仅 JS 渲染路径需要）：`npm install turndown`。

## Windows 路径陷阱（重要）

本机是 Windows，Bash（Git Bash）里 `/c/...`、`/tmp/...` 是有效路径，但 **Node.js 不认识这些**——Node 会把 `/tmp/foo.txt` 当成 `C:\tmp\foo.txt`，把 `/c/Users/...` 当成 `C:\c\Users\...`，导致文件写到错误位置（且不报错！）。

**所有传给 Node 脚本的路径必须用 Windows 格式**：`C:/Users/20301/...`（正斜杠在 Node 里没问题）。脚本里的 `OUT_ROOT`、输入文件路径、输出文件路径全部如此。从 Bash 传参时用 `cygpath -w <path>` 转换。

## 输出目录约定

默认输出到 Obsidian Vault 的第三方文档目录下，以站点名建子目录：

```
C:\Users\20301\Documents\Obsidian Vault\文档\第三方平台接口文档\<站点名>\
├── README-导航索引.md
├── <分类A>\
│   └── <文档>.md
└── <分类B>\
    └── <子分类>\
        └── <文档>.md
```

若用户指定了其他目录，按用户指定的来。站点名从 URL 推导（如 `apidoc.lingxing.com` → `领星`，或直接用域名）。

## 脚本使用

本技能提供两个参数化脚本，可直接复用，不必每次重写：

- `scripts/fetch_docsify.js` — docsify 站点抓取主脚本。用法：
  ```bash
  node scripts/fetch_docsify.js --site https://apidoc.lingxing.com --out "C:/Users/20301/Documents/Obsidian Vault/文档/第三方平台接口文档/领星" --concurrency 5
  ```
  它会自动探测 `_sidebar.md`、提取路径、并发抓取、校验、断点续传。支持 `--sidebar <相对路径>` 自定义 sidebar 路径，`--browser msedge|chrome|chromium` 切换浏览器。
- `scripts/gen_index.js` — 生成 Obsidian 导航索引。用法：
  ```bash
  node scripts/gen_index.js --sidebar "<输出的 sidebar 副本路径>" --out "<输出目录>/README-导航索引.md"
  ```

脚本细节和参数见各脚本顶部注释。对于 JS 渲染型站点，参考 `scripts/fetch_docsify.js` 的结构改写（导航 + 等待 + 提取 + turndown），核心模式一致。

## 完成后必做的校验

抓取完成后，务必验证质量，别只看"Downloaded: N"就交差：

1. **空文件检查**：`find <输出目录> -name "*.md" -size -30c` 应无结果。
2. **HTML 混入检查**：`grep -rl "^<!DOCTYPE\|^<html" <输出目录>` 应无结果。
3. **文件数核对**：与 sidebar 提取的路径数一致。
4. **抽样内容**：随机看 2-3 个文件，确认表格、代码块、交叉链接完整。

## 何时不用此技能

- 单个文档/单个页面：直接浏览器打开或 WebFetch 即可，不必批量抓取。
- 需要登录认证的私有文档：本技能面向公开文档，不处理登录态（除非用户提供已登录的 cookie，但这超出本技能范围，需用户明确授权）。
- 非 Markdown 友好的纯富文本站（如飞书、Notion 导出）：需专门工具，本技能不适用。
