---
name: improve-codebase-architecture
description: 扫描代码库找出架构深化机会（把浅模块改写成深模块），生成可视化 HTML 报告供用户挑选，再用 grilling 技能逐项走查所选候选。当用户想改善代码库架构、做重构、找「深模块」、生成架构审查报告、定位测试难点或可测试性问题时触发。
---

# Improve Codebase Architecture

暴露架构上的摩擦点，并提出**深化机会（deepening opportunities）**——把浅层模块（shallow modules）重构为深层模块（deep modules）的改进方案。目标是提升可测试性（testability）与 AI 可导航性（AI-navigability）。

本技能**受到**项目领域模型的启发，并建立在共享的设计词汇之上：

- 运行 `codebase-design` 技能获取架构词汇（**module**、**interface**、**depth**、**seam**、**adapter**、**leverage**、**locality**）及其原则（删除测试 deletion test、「接口即测试面 the interface is the test surface」、「一个 adapter = 假设的 seam，两个 = 真实的 the one-adapter/two-adapter rule」）。在每条建议里**原样使用这些术语**，不要漂移到 "component"、"service"、"API" 或 "boundary"。
- 领域语言记录在仓库的领域词表（按仓库现有约定，通常是 `CONTEXT.md`；不存在则按规范创建），它为好的 seam 提供命名。`docs/adr/` 下的 ADR 记录了本技能不应重新争论的决定。

## 触发时机

- 用户提到「改善代码库架构」「做架构重构」「找深模块」「浅模块问题」。
- 用户希望生成架构审查 HTML 报告、扫描代码库热点、或排查难以测试／难以改动的地方。
- 用户要求用 grilling 方式对一个候选改动进行压力测试。

## 工作流

1. **探索（Explore）**：先确定要看哪里（依托近期改动热点），再通读领域词表与相关 ADR，然后用 `subagent` 工具实际走查代码库，记录摩擦点。
2. **呈现候选（Present candidates as HTML report）**：把候选写入 OS 临时目录下的自包含 HTML 文件，用 `start` 打开并告知绝对路径。引用 [references/HTML-REPORT.md](references/HTML-REPORT.md) 中的完整 HTML 脚手架、图表模式与样式指引。
3. **Grilling 走查（Grilling loop）**：用户选中一个候选后，运行 `grilling` 技能逐项走查决策树；决策固化时用 `domain-modeling` 技能保持领域模型最新。

## 步骤

### 1. 探索（Explore）

**先定范围再扫描 —— YAGNI。** 深化一个模块的价值在于让未来改动它更容易，所以给**近期频繁改动**的部分更高权重。先决定*从哪看*，再去看：

- 如果用户指定了方向——某个模块、子系统或痛点——直接采纳，跳过下面的推断。
- 否则，走查一长段提交历史（`git log --oneline`，通过 `pwsh` 运行）找出代码库的**热点（hot spots）**——反复出现的关键文件与区域，让这些路径优先吸引你的注意力。如果改动分散、没有明显的热点，就扩大范围。

先读项目的领域词表（`CONTEXT.md` 或仓库现有约定）以及涉及区域内的任何 ADR。

然后用 `subagent` 工具（后台运行）走查代码库。不要死板套用启发式——有机地探索，并记录你亲身体验到的摩擦点：

- 理解一个概念是否需要在很多小模块之间来回跳转？
- 哪些模块**浅（shallow）**——接口几乎和实现一样复杂？
- 哪些地方为了可测试性而抽取了纯函数，但真正的 bug 藏在它们如何被调用上（缺少**locality**）？
- 哪些紧耦合模块把内部实现泄漏到 seam 之外？
- 代码库哪些部分没测试，或通过当前接口很难测试？

对任何你怀疑是浅层的东西应用**删除测试（deletion test）**：删除它会**聚集**复杂度，还是只是把复杂度**迁移**走了？「会聚集复杂度」正是你要的信号。

### 2. 把候选呈现为 HTML 报告

写一个**自包含的 HTML 文件**到操作系统临时目录，这样仓库里不会落下任何东西。用 `$env:TEMP`（Windows）解析临时目录（不要在仓库内建临时文件），写到 `<tmpdir>/architecture-review-<timestamp>.html`，这样每次运行都得到一个全新文件。用它为用户打开——Windows 上用 `start <path>`（等价物：Linux 用 `xdg-open`，macOS 用 `open`）——并告诉用户绝对路径。

报告用 **Tailwind via CDN** 做布局与样式，用 **Mermaid via CDN** 在图形／流程图／时序图能可靠传意的地方画图。把 Mermaid 与手工 CSS/SVG 视觉元素混用——当关系是图状的（调用图、依赖、时序）用 Mermaid，当想要更「编辑性」的效果（质量图 mass diagrams、剖面图、折叠动画）用手工的 div/SVG。每一个候选都要配一个**前后对比图（before/after visualisation）**。要足够可视化。

每个候选渲染一张卡片，包含：

- **Files**——涉及哪些文件／模块
- **Problem**——为什么当前架构造成摩擦
- **Solution**——用通俗英文说明会改什么
- **Benefits**——用 locality 和 leverage 术语解释收益，以及测试会如何改进
- **Before / After diagram**——并排、自定义绘制，说明「浅」以及如何「深化」
- **Recommendation strength**——`Strong`、`Worth exploring`、`Speculative` 之一，作为徽章渲染

在报告末尾放一个**Top recommendation（首要建议）**部分：你会先攻克哪个候选、为什么。

**领域用领域词表（`CONTEXT.md`）词汇，架构用 `codebase-design` 词汇。** 如果 `CONTEXT.md` 定义了 "Order"，就谈 "the Order intake module"——不要谈 "the FooBarHandler"，也不要谈 "the Order service"。

**ADR 冲突**：如果某个候选与既有 ADR 矛盾，只有当摩擦真实到值得重新审视该 ADR 时才提出它。在卡片里明确标注（例如一个警示框：_"contradicts ADR-0007 — but worth reopening because…"_）。不要罗列每个 ADR 禁止的理论性重构。

完整的 HTML 脚手架、图表模式与样式指引见 [references/HTML-REPORT.md](references/HTML-REPORT.md)。

**先不要提议接口。** 写完文件后，问用户：「Which of these would you like to explore?」（你愿意探索其中哪一项？）。

### 3. Grilling 走查（Grilling loop）

用户选中一个候选后，运行 `grilling` 技能，与用户一起走查决策树——约束、依赖、深化后模块的形状、seam 后面是什么、哪些测试能存活。

随着决策固化，副作用要内联发生——用 `domain-modeling` 技能保持领域模型最新：

- **把一个深化后的模块用 `CONTEXT.md` 里没有的概念命名？** 把该术语加进 `CONTEXT.md`（按仓库现有约定）。文件不存在就延迟创建。
- **对话中把一个含糊术语变清晰？** 就地更新 `CONTEXT.md`。
- **用户用一个有承载力的理由拒绝了候选？** 提供一个 ADR，措辞如下：_"Want me to record this as an ADR so future architecture reviews don't re-suggest it?"_ 只有当这个理由确实是未来的探索者避免重复建议同一件事所必需时才提出——跳过短暂理由（如「现在不值得」）和不言自明的理由。
- **想为深化后的模块探索备选接口？** 运行 `codebase-design` 技能，用它的「设计两版（design-it-twice）」并行子代理模式。

## 检查清单

- [ ] 范围聚焦在近期改动热点（除非用户指定了方向）。
- [ ] 先读领域词表与相关 ADR。
- [ ] 用 `subagent` 走查代码库并记录摩擦点。
- [ ] 对每个浅层候选应用删除测试。
- [ ] 报告写入 `$env:TEMP`，文件名含时间戳，用 `start` 打开并告知绝对路径。
- [ ] 每个候选有 Files／Problem／Solution／Benefits／Before-After 图／强度徽章。
- [ ] 术语严格使用：module、interface、implementation、depth、deep、shallow、seam、adapter、leverage、locality。
- [ ] 报告末尾有 Top recommendation。
- [ ] 写完后先问用户选哪个，不先提议接口。
- [ ] 用 `grilling` 走查所选候选；决策固化时用 `domain-modeling` 更新领域模型。
