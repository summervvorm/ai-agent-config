#!/usr/bin/env node
/**
 * fetch_docsify.js — 抓取 docsify 文档站的全部页面为 Markdown
 *
 * 用法:
 *   node fetch_docsify.js --site https://apidoc.lingxing.com \
 *     --out "C:/Users/20301/Documents/Obsidian Vault/文档/第三方平台接口文档/领星" \
 *     [--sidebar _sidebar.md] [--concurrency 5] [--browser msedge]
 *
 * 参数:
 *   --site <url>         站点根 URL（必填）
 *   --out <dir>          输出目录，Windows 路径（必填）
 *   --sidebar <path>     sidebar 相对路径，默认 _sidebar.md
 *   --concurrency <n>    并发浏览器 context 数，默认 5
 *   --browser <channel>  浏览器: msedge(默认) | chrome | chromium
 *
 * 特性:
 *   - 通过 Playwright 浏览器上下文发起请求（真实 UA/Cookie）
 *   - 解析 _sidebar.md 提取全部文档路径并归一化
 *   - 并发抓取 + 失败重试 + 断点续传（跳过已存在文件）
 *   - 内容校验：拒绝 HTML 错误页
 *   - 保留原始目录结构，去掉 docs/ 前缀
 *
 * 依赖: npm install playwright
 * 浏览器: 默认用系统 Edge（channel: 'msedge'），无需下载 Chromium
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// ---------- 参数解析 ----------
function parseArgs() {
  const args = process.argv.slice(2);
  const opts = {
    site: null, out: null, sidebar: '_sidebar.md',
    concurrency: 5, browser: 'msedge'
  };
  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--site': opts.site = args[++i]; break;
      case '--out': opts.out = args[++i]; break;
      case '--sidebar': opts.sidebar = args[++i]; break;
      case '--concurrency': opts.concurrency = parseInt(args[++i]) || 5; break;
      case '--browser': opts.browser = args[++i]; break;
      default: console.warn(`未知参数: ${args[i]}`);
    }
  }
  if (!opts.site || !opts.out) {
    console.error('用法: node fetch_docsify.js --site <url> --out <dir> [--sidebar _sidebar.md] [--concurrency 5] [--browser msedge]');
    process.exit(1);
  }
  opts.site = opts.site.replace(/\/+$/, ''); // 去掉尾部斜杠
  return opts;
}

const MAX_RETRIES = 2;

// ---------- 从 sidebar 提取文档路径 ----------
function extractPaths(sidebarText) {
  // 匹配 markdown 链接里的 (path)，排除 http(s) 外链和纯锚点
  const linkRe = /\(([^)]+)\)/g;
  const set = new Set();
  let m;
  while ((m = linkRe.exec(sidebarText)) !== null) {
    let href = m[1].trim();
    if (/^https?:/i.test(href)) continue;       // 外链
    if (href.startsWith('#')) continue;          // 纯锚点
    // 归一化: 去前导斜杠、去 query/hash、去结尾 .md
    href = href.replace(/^\//, '').split('#')[0].split('?')[0];
    if (!href) continue;
    href = href.replace(/\.md$/i, '');
    if (href) set.add(href);
  }
  return [...set].sort();
}

function outFilePath(outRoot, p) {
  let rel = p.replace(/^docs\//, '');
  return path.join(outRoot, rel + '.md');
}

function ensureDir(file) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
}

// ---------- 主流程 ----------
(async () => {
  const opts = parseArgs();
  console.log(`站点: ${opts.site}`);
  console.log(`输出: ${opts.out}`);
  console.log(`浏览器: ${opts.browser}, 并发: ${opts.concurrency}`);

  // 启动浏览器
  const launchOpts = { headless: true };
  if (opts.browser !== 'chromium') launchOpts.channel = opts.browser;
  const browser = await chromium.launch(launchOpts).catch(async (e) => {
    if (opts.browser !== 'chromium') {
      console.warn(`启动 ${opts.browser} 失败 (${e.message})，回退到 chromium`);
      return chromium.launch({ headless: true });
    }
    throw e;
  });

  // 探测 + 抓取 sidebar
  const probeCtx = await browser.newContext();
  const probeReq = probeCtx.request;
  console.log(`探测 sidebar: ${opts.site}/${opts.sidebar}`);
  const sbResp = await probeReq.get(`${opts.site}/${opts.sidebar}`);
  if (sbResp.status() !== 200) {
    console.error(`无法获取 _sidebar.md (HTTP ${sbResp.status()})，可能不是 docsify 站。`);
    console.error('请改用 JS 渲染抓取策略（参考 SKILL.md 第 2B 步）。');
    await browser.close();
    process.exit(2);
  }
  const sidebarText = await sbResp.text();
  await probeCtx.close();

  // 保存 sidebar 副本，供 gen_index.js 使用
  ensureDir(path.join(opts.out, '_sidebar.source.md'));
  fs.writeFileSync(path.join(opts.out, '_sidebar.source.md'), sidebarText, 'utf8');

  const paths = extractPaths(sidebarText);
  console.log(`提取到 ${paths.length} 个文档路径`);

  // 并发 context
  const contexts = [], requests = [];
  for (let i = 0; i < opts.concurrency; i++) {
    const ctx = await browser.newContext({
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
      extraHTTPHeaders: {
        'Accept': 'text/markdown,text/plain,text/html;q=0.9,*/*;q=0.8',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      }
    });
    contexts.push(ctx);
    requests.push(ctx.request);
  }

  let done = 0, downloaded = 0, skipped = 0;
  const failed = [];
  const start = Date.now();

  async function fetchOne(req, p, attempt = 1) {
    const outFile = outFilePath(opts.out, p);
    if (fs.existsSync(outFile) && fs.statSync(outFile).size > 20) {
      skipped++; done++; return;
    }
    const mdPath = p.endsWith('.md') ? p : p + '.md';
    const url = `${opts.site}/${mdPath}`;
    try {
      const resp = await req.get(url, { timeout: 30000 });
      if (resp.status() !== 200) throw new Error(`HTTP ${resp.status()}`);
      const body = await resp.text();
      if (!body || body.trim().length < 10) throw new Error('空内容');
      const head = body.trim().slice(0, 15).toLowerCase();
      if (head.startsWith('<!doctype') || head.startsWith('<html')) {
        throw new Error('返回 HTML 而非 Markdown（可能是错误页）');
      }
      ensureDir(outFile);
      fs.writeFileSync(outFile, body, 'utf8');
      downloaded++;
    } catch (e) {
      if (attempt < MAX_RETRIES) {
        await new Promise(r => setTimeout(r, 1200));
        return fetchOne(req, p, attempt + 1);
      }
      failed.push(p);
      console.error(`FAILED (${attempt}x): ${p} -> ${e.message}`);
    }
    done++;
    if (done % 50 === 0) {
      const rate = (done / ((Date.now() - start) / 1000)).toFixed(1);
      console.log(`[${done}/${paths.length}] ${rate}/s  latest: ${p}`);
    }
  }

  // 轮询分配
  const queues = requests.map(() => []);
  paths.forEach((p, i) => queues[i % opts.concurrency].push(p));
  await Promise.all(requests.map(async (req, idx) => {
    for (const p of queues[idx]) await fetchOne(req, p);
  }));

  for (const ctx of contexts) await ctx.close();
  await browser.close();

  const elapsed = ((Date.now() - start) / 1000).toFixed(1);
  console.log(`\n=== 完成 ===`);
  console.log(`总数: ${paths.length}, 下载: ${downloaded}, 跳过(已存在): ${skipped}, 失败: ${failed.length}`);
  console.log(`耗时: ${elapsed}s`);
  if (failed.length) {
    fs.writeFileSync(path.join(opts.out, '_failed.txt'), failed.join('\n'), 'utf8');
    console.log('失败列表已写入 _failed.txt:');
    failed.forEach(f => console.log(`  - ${f}`));
  }
  console.log(`\nsidebar 副本: ${path.join(opts.out, '_sidebar.source.md')}`);
  console.log(`可用 gen_index.js 生成导航索引。`);
})().catch(e => { console.error('FATAL:', e); process.exit(1); });
