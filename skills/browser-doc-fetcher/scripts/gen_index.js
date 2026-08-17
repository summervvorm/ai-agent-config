#!/usr/bin/env node
/**
 * gen_index.js — 根据抓取保存的 _sidebar 生成 Obsidian 导航索引
 *
 * 用法:
 *   node gen_index.js --sidebar "<输出目录>/_sidebar.source.md" --out "<输出目录>/README-导航索引.md"
 *
 * 生成一个用 Obsidian wikilink ([[路径|显示名]]) 组织的索引文件，链接路径
 * 去掉 docs/ 前缀，与实际抓取保存的文件路径对齐。
 */

const fs = require('fs');
const path = require('path');

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { sidebar: null, out: null, title: null };
  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--sidebar': opts.sidebar = args[++i]; break;
      case '--out': opts.out = args[++i]; break;
      case '--title': opts.title = args[++i]; break;
    }
  }
  if (!opts.sidebar || !opts.out) {
    console.error('用法: node gen_index.js --sidebar <sidebar.md> --out <README.md> [--title 标题]');
    process.exit(1);
  }
  return opts;
}

(async () => {
  const opts = parseArgs();
  const sidebar = fs.readFileSync(opts.sidebar, 'utf8');
  const outDir = path.dirname(opts.out);
  const title = opts.title || '文档导航';

  // 统计实际文档数
  let count = 0;
  function walk(d) {
    if (!fs.existsSync(d)) return;
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const full = path.join(d, e.name);
      if (e.isDirectory()) walk(full);
      else if (e.name.endsWith('.md') && !e.name.startsWith('README') && !e.name.startsWith('_')) count++;
    }
  }
  walk(outDir);

  let out = `# ${title}\n\n`;
  out += `> 生成方式: browser-doc-fetcher skill (gen_index.js)\n`;
  out += `> 共 ${count} 个文档，按站点侧边栏层级组织。\n`;
  out += `> 链接格式 \`[[相对路径|显示名]]\`，路径已去掉 docs/ 前缀，对应实际文件位置。\n\n---\n\n`;

  for (const line of sidebar.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || !trimmed.startsWith('*')) continue;
    const indent = (line.match(/^\s*/)[0]).length;
    const level = Math.floor(indent / 2);
    const prefix = '  '.repeat(level);

    const linkMatch = trimmed.match(/\[([^\]]+)\]\(([^)]+)\)/);
    if (linkMatch) {
      const [, text, href] = linkMatch;
      let localPath = href.replace(/^\//, '').replace(/\.md$/i, '').replace(/^docs\//, '');
      out += `${prefix}- [[${localPath}|${text}]]\n`;
    } else {
      const text = trimmed.replace(/^\*\s*/, '');
      if (text) out += `${prefix}**${text}**\n`;
    }
  }

  fs.writeFileSync(opts.out, out, 'utf8');
  console.log(`索引已生成: ${opts.out} (${count} 个文档)`);
})().catch(e => { console.error('FATAL:', e); process.exit(1); });
