# HTML Report Format

架构审查被渲染成一个**自包含的 HTML 文件**，放在 OS 临时目录中（Windows 用 `$env:TEMP`，文件名 `architecture-review-<timestamp>.html`，用 `start <path>` 打开）。Tailwind 与 Mermaid 都来自 CDN。Mermaid 可靠地处理图状图表；手工构建的 div 与内联 SVG 处理更「编辑性」的视觉（质量图 mass diagrams、剖面图）。两者混用——不要事事都用 Mermaid，那样会显得千篇一律。

## Scaffold

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Architecture review — {{repo name}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
    </script>
    <style>
      /* small custom layer for things Tailwind doesn't cover cleanly:
         dashed seam lines, hand-drawn-feeling arrow heads, etc. */
      .seam { stroke-dasharray: 4 4; }
      .leak { stroke: #dc2626; }
      .deep { background: linear-gradient(135deg, #0f172a, #1e293b); }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="candidates" class="space-y-10">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

## Header

仓库名、日期，以及一个紧凑图例：实心框 = 模块（module），虚线 = seam，红色箭头 = 泄漏（leakage），粗深色框 = 深模块（deep module）。不要引言段落——直接进候选。

## Candidate card

图表承担主要表达。散文稀疏、平实，并原样使用词表术语（来自 `codebase-design` 技能），不加修饰。

每个候选是一张 `<article>`：

- **Title**——简短，点名深化方向（如 "Collapse the Order intake pipeline"）。
- **Badge row**——建议强度（`Strong` = emerald，`Worth exploring` = amber，`Speculative` = slate），外加一个依赖类别标签（`in-process`、`local-substitutable`、`ports & adapters`、`mock`）。
- **Files**——等宽字体列表，`font-mono text-sm`。
- **Before / After diagram**——核心。两列并排。见下方模式。
- **Problem**——一句话。痛点在哪。
- **Solution**——一句话。改什么。
- **Wins**——要点，每条 ≤6 词。例如 "Tests hit one interface"、"Pricing logic stops leaking"、"Delete 4 shallow wrappers"。
- **ADR callout**（如适用）——琥珀色框里的一行。

不要解释段落。如果图表需要一段话来理解，就重画图表。

## Diagram patterns

选取匹配候选的模式。把它们混搭。不要让每一张图看起来都一样——多样性本身就是重点。

### Mermaid graph（依赖／调用流的常用引擎）

当要点是「X 调用 Y 调用 Z，看看这团乱麻」时，用 Mermaid `flowchart` 或 `graph`。把它包进一个 Tailwind 样式的卡片里，免得像被硬塞进来。用 classDef 把泄漏边染成红色、把深模块染成深色。时序图适合「before：6 次往返；after：1 次」。

```html
<div class="rounded-lg border border-slate-200 bg-white p-4">
  <pre class="mermaid">
    flowchart LR
      A[OrderHandler] --> B[OrderValidator]
      B --> C[OrderRepo]
      C -.leak.-> D[PricingClient]
      classDef leak stroke:#dc2626,stroke-width:2px;
      class C,D leak
  </pre>
</div>
```

### Hand-built boxes-and-arrows（当 Mermaid 布局跟你较劲时）

模块用带边框与标签的 `<div>`。箭头用排布在相对定位容器上的内联 SVG `<line>` 或 `<path>` 元素。当你想要的「after」图感觉是一个粗边框深模块、内部变灰时，就用这个——Mermaid 无法以正确的权重渲染出来。

### Cross-section（适合分层式浅层）

堆叠横向条（`h-12 border-l-4`）来显示一次调用穿过的层次。Before：6 条什么事都不做的细薄层。After：1 条粗带，标注合并后的职责。

### Mass diagram（适合「接口和实现一样宽」）

每个模块画两个矩形——一个代表接口表面积，一个代表实现。Before：接口矩形几乎和实现矩形一样高（浅）。After：接口矩形矮、实现矩形高（深）。

### Call-graph collapse

Before：一棵函数调用树，渲染为嵌套盒子。After：同一棵树折叠进一个盒子，如今内部的调用在盒子里以淡色显示。

## Style guidance

- 偏编辑性，不要企业仪表盘。留白充分。标题可选衬线字体（`font-serif` 与 stone/slate 搭配很好）。
- 配色克制：一个强调色（emerald 或 indigo），红色用于泄漏，琥珀色用于警告。
- 图表高度控制在 ~320px，这样 before/after 可以舒服地并排、无需滚动。
- 图表内部的模块标签用 `text-xs uppercase tracking-wider`——应读起来像示意图，而不是 UI。
- 唯一的脚本是 Tailwind CDN 与 Mermaid ESM 导入。报告其余部分都是静态的——无应用代码，除 Mermaid 自己的渲染外无交互。

## Top recommendation section

一张更大的卡片。候选名、一句话说明为什么、锚点链接到它的卡片。就这样。

## Tone

平实、简洁英文——但建筑名词与动词直接来自 `codebase-design` 技能。简洁不是漂移的借口。

**原样使用：** module、interface、implementation、depth、deep、shallow、seam、adapter、leverage、locality。

**绝不替换：** component、service、unit（代指 module）· API、signature（代指 interface）· boundary（代指 seam）· layer、wrapper（当你想表达 module 时）。

**符合风格的措辞：**

- "Order intake module is shallow — interface nearly matches the implementation."
- "Pricing leaks across the seam."
- "Deepen: one interface, one place to test."
- "Two adapters justify the seam: HTTP in prod, in-memory in tests."

**Wins 要点**用词表术语命名收益：*"locality: bugs concentrate in one module"*、*"leverage: one interface, N call sites"*、*"interface shrinks; implementation absorbs the wrappers"*。不要写 *"easier to maintain"* 或 *"cleaner code"*——这些词不在词表里，也不配占位置。

不模棱两可、不含糊其辞、不写 "it's worth noting that…"。如果一个句子能写成要点，就写成要点。如果一个要点能被删掉，就删掉。如果某个词不在 `codebase-design` 词表里，在发明新词之前先去找一个在词表里的说法。
