# Out-of-Scope 知识库

仓库的 `.scratch/triage/out-of-scope/` 目录持久记录被拒绝的特性请求。它有两个用途：

1. **制度记忆** — 一个特性为什么被拒，这样理由不会在 issue 关闭后丢失
2. **去重** — 当新 issue 匹配先前的拒绝时，技能可暴露之前的决策，而非再次翻案

（本技能是本地文件模式，issue 全部落在 `.scratch/triage/` 下；若仓库另有约定放置被拒记录，按现有约定来，否则用 `.scratch/triage/out-of-scope/`。）

## 目录结构

```
.scratch/triage/out-of-scope/
├── dark-mode.md
├── plugin-system.md
└── graphql-api.md
```

一个文件对应一个**概念**，而不是一个 issue。多个请求同一事物的 issue 归到一个文件下。

## 文件格式

文件应以轻松、可读的风格撰写——更像一份简短设计文档，而不是数据库条目。用段落、代码样例与例证，让头一次碰到的人也能看清推理。

```markdown
# Dark Mode

This project does not support dark mode or user-facing theming.

## Why this is out of scope

The rendering pipeline assumes a single color palette defined in
`ThemeConfig`. Supporting multiple themes would require:

- A theme context provider wrapping the entire component tree
- Per-component theme-aware style resolution
- A persistence layer for user theme preferences

This is a significant architectural change that doesn't align with the
project's focus on content authoring. Theming is a concern for downstream
consumers who embed or redistribute the output.

```ts
// The current ThemeConfig interface is not designed for runtime switching:
interface ThemeConfig {
  colors: ColorPalette; // single palette, resolved at build time
  fonts: FontStack;
}
```

## Prior requests

- #42 — "Add dark mode support"
- #87 — "Night theme for accessibility"
- #134 — "Dark theme option"
```

### 命名文件

为概念取一个简短、描述性的 kebab-case 名字：`dark-mode.md`、`plugin-system.md`、`graphql-api.md`。名字应足以让浏览目录的人不看文件就知道被拒的是什么。

### 写理由

理由要实质——不是"我们不想要这个"，而是为什么。好理由会引用：

- 项目范围或理念（"本项目聚焦 X；theming 是下游关注点"）
- 技术约束（"支持这个需要 Y，这与我们 Z 架构冲突"）
- 战略决策（"我们选 A 而非 B，因为…"）

理由要 durable。避免引用临时情况（"我们现在太忙了"）——那不算真拒绝，只是延期。

## 何时检查 out-of-scope

在分诊（第 1 步：收集上下文）时，读取 `.scratch/triage/out-of-scope/` 下的所有文件。评估新 issue 时：

- 检查请求是否匹配某个既有 out-of-scope 概念
- 匹配按概念相似度，而非关键词——"night theme" 匹配 `dark-mode.md`
- 若有匹配，暴露给维护者："这类似 `.scratch/triage/out-of-scope/dark-mode.md` — 我们之前拒过，因为 [reason]。你还这么觉得吗？"

维护者可以：

- **确认** — 新 issue 被加进既有文件的 "Prior requests" 列表，然后关闭
- **重新考虑** — 删除或更新 out-of-scope 文件，issue 走正常分诊流程
- **不同意** — 这些 issue 相关但不同，走正常分诊流程

## 何时写入 out-of-scope

只有当 **enhancement**（而非 bug）被拒为 `wontfix` 时才写。对 enhancement PR 与对 issue 完全一致——被拒的 PR 也记录于此，免得同一请求又作为新代码回来。

当某样东西因**已实现**而被关为 `wontfix` 时，**不要**写在这里。那是做成的功能，不是被拒的；记录它会在去重检查里注入虚假拒绝。此时关闭说明指向该功能已存在的位置即可。

流程：

1. 维护者判定一个特性请求超出范围
2. 检查是否已有匹配的 `.scratch/triage/out-of-scope/` 文件
3. 若有：把新 issue 追加到 "Prior requests" 列表
4. 若无：创建新文件，含概念名、决策、理由与第一条 prior request
5. 在 issue 上发一条评论，说明决策并提及那条 out-of-scope 文件
6. 用 `wontfix` 状态关闭该 issue

## 更新或移除 out-of-scope 文件

如果维护者对先前拒绝过的概念改主意：

- 删除对应 `.scratch/triage/out-of-scope/` 文件
- 本技能无需重开旧 issue——它们是历史记录
- 触发重新考虑的那个新 issue 走正常分诊流程
