# 故障排查参考

本文件记录 browser-doc-fetcher 技能实战中遇到的典型问题与解法。遇到问题时先查这里。

## 1. 浏览器启动失败 / Chromium 下载卡死

### 现象
- `npx playwright install chromium` 只创建目录、长时间无输出、最终超时或留个 `__dirlock`。
- 报错 `Executable doesn't exist at ...\chrome-headless-shell.exe`。

### 原因
某些网络环境下 Playwright 的浏览器下载 CDN 不通，下载挂起。

### 解法（按优先级）
1. **用系统已装的 Edge**（Windows 默认有）：`channel: 'msedge'`。无需任何下载。
2. 用系统 Chrome：`channel: 'chrome'`。
3. 最后才回退下载 Chromium，并先 `rm -rf "<ms-playwright>/__dirlock"` 清锁。

### 检测系统浏览器是否存在
```bash
ls "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" 2>/dev/null && echo "EDGE OK"
ls "/c/Program Files/Google/Chrome/Application/chrome.exe" 2>/dev/null && echo "CHROME OK"
```

`fetch_docsify.js` 的 `--browser` 参数已内置回退逻辑：msedge 失败自动回退 chromium。

## 2. 文件写到了错误位置（Windows 路径陷阱）

### 现象
脚本报告 "Downloaded: N"，但目标输出目录里一个文件都没有；却可能在别处（如 `C:\c\Users\...` 或 `C:\tmp\...`）凭空出现一个目录树。

### 原因
Bash（Git Bash）里 `/c/Users/...`、`/tmp/...` 是合法路径，但 **Node.js 不解析这些**：
- Node 把 `/tmp/foo.txt` 当成 `C:\tmp\foo.txt`
- Node 把 `/c/Users/...` 当成 `C:\c\Users\...`（多了一个 `c` 盘符下的目录）

文件静默写到错误位置，**不报错**，极具迷惑性。

### 解法
所有传给 Node 的路径用 **Windows 格式**（正斜杠即可）：
```js
// 错
const OUT_ROOT = '/c/Users/20301/Documents/...';
// 对
const OUT_ROOT = 'C:/Users/20301/Documents/...';
```
从 Bash 传参时用 `cygpath -w` 转换：
```bash
WIN_OUT=$(cygpath -w "/c/Users/20301/Documents/Obsidian Vault/文档/...")
node fetch_docsify.js --out "$WIN_OUT" ...
```

### 清理误写的目录
若已写错位置，检查并删除：
```bash
ls -d "/c/c" 2>/dev/null          # Node 误建的 /c/ 解析
ls -d "C:/tmp" 2>/dev/null         # /tmp 误解析
```

## 3. 抓取内容是 HTML 而非 Markdown

### 现象
某些路径 GET 返回 200，但内容是 `<!DOCTYPE html>...`（站点的 404 页或 SPA 壳页）。

### 解法
`fetch_docsify.js` 已内置校验：检测到 `<!doctype`/`<html` 开头则判为失败并重试。若大量出现，说明该站不是 docsify 或路径规则不同，改用 JS 渲染策略（SKILL.md 第 2B 步）。

## 4. 站点不是 docsify

### 现象
`_sidebar.md` 返回 404 或 HTML。

### 解法
改用 JS 渲染抓取。需先枚举全部页面 URL：
- 查 `/sitemap.xml`
- 在浏览器里读侧边栏 DOM 的 `<a href>`
- 查构建配置（VitePress 的 `.vitepress/config.ts`、Docusaurus 的 `sidebars.js`）

然后导航 + 等待容器 + 提取 innerHTML + turndown。容器选择器候选：
`.markdown-section`（docsify）、`.theme-default-content`（VuePress）、`main article`（Docusaurus）、`article`（通用）。

## 5. 并发太高被限流 / 连接重置

### 解法
降低 `--concurrency`（如 3）。单 context 内串行请求，已避免瞬时并发过高。若仍被限流，在 `fetchOne` 失败重试前增加等待时间。

## 6. 中文/特殊字符文件名问题

输出路径含中文、空格（如 `Obsidian Vault`）在 Node 里没问题（用 Windows 正斜杠路径即可），但**在 Bash 里传参时务必用双引号包裹**整个路径，否则空格会断词。

## 7. 增量更新

重跑同一命令即可。脚本会跳过已存在且 > 20 字节的文件，只抓新增/变更的。站点更新后想全量重抓，先删除输出目录再跑。
