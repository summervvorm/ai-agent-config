---
name: to-tickets
description: 把计划、spec 或当前对话拆成一组 tracer-bullet 垂直切片 tickets，每个 ticket 声明阻塞自己的其他 tickets，并以本地 markdown 文件形式输出。当用户要求把计划/需求/spec 拆分成任务、tickets、待办、垂直切片、分阶段实施步骤、按依赖排序的开发任务，或说“to tickets / 转成 tickets / 排任务”时触发此技能。
---

# To Tickets（拆分成 Ticket）

把计划、spec 或对话拆成一组 **tickets** —— tracer-bullet（曳光弹）垂直切片，每个 ticket 声明阻塞它的其他 tickets。

技能以**本地文件模式**输出：每个 ticket 一个 markdown 文件，按依赖顺序编号。**不发布到任何真实 issue tracker**，也不假设 `gh`/GitHub/Linear 等可用。

## 触发时机

- 用户给出一个计划、spec、PR 描述或一段需求对话，要求拆成可执行的 tickets / 任务清单
- 用户要求「垂直切片」「tracer bullet」「按依赖排序」「分阶段/分步实施」来拆解开发工作
- 用户明确说「to tickets」「转成 tickets」「排任务」，或递给本技能一个 spec 路径要求拆分

## 工作流

### 1. 收集上下文

从当前对话上下文中已有的内容入手。若用户传入了引用（spec 路径、issue 编号或 URL）作为参数，先**读取/抓取它并读完正文与评论**。

### 2. 探索代码库（可选）

若尚未了解代码库现状，先探索以掌握当前状态。ticket 标题与描述应使用项目领域词汇表（UBIQUITOUS_LANGUAGE）的用语，并尊重所改动区域的 ADR（架构决策记录）。按仓库现有约定读取这些文档；若不存在，可按规范创建。

寻找可以**预重构（prefactor）**的机会让实现更简单。"Make the change easy, then make the easy change."（先让改动变容易，再做容易的改动。）

### 3. 起草垂直切片

把工作拆成 **tracer bullet** tickets。

**垂直切片规则：**

- 每个切片切穿一条**窄但完整**的通路，覆盖每一层（schema、API、UI、测试）——是**纵向**切片，不是某一层的横向切片
- 完成后的切片能独立演示或验证
- 每个切片的大小能放进单个新的上下文窗口
- 任何预重构都应先做

给每个 ticket 标出它的**阻塞边（blocking edges）**——必须先于它完成的其它 tickets。没有阻塞者的 ticket 可以立即开始。

**宽重构是垂直切片规则的例外。** 宽重构（wide refactor）是**一次性机械性改动**——改列名、改共享符号的类型——其**爆炸半径**波及整个代码库，一次编辑会同时破坏成千上万的调用点，没有任何垂直切片能单独变绿。不要强制把它塞进 tracer bullet，而要按 **expand–contract（扩展–收缩）** 编排：先 **expand**：在旧形式旁边加上新形式，什么都不破坏；然后按爆炸半径分批（按 package、按目录）迁移调用点，每一批都是一个被 expand 阻塞的 ticket，因为旧形式仍在，所以 CI 逐批保持绿；最后 **contract**：在没有调用者之后删除旧形式，作为一个被所有迁移批次阻塞的 ticket。当即便分批也无法单独保持绿色时，保留上述顺序，但让它们共享一个集成分支，由该分支阻塞一个最终的 integrate-and-verify（集成并验证）ticket——绿色只在该处被承诺。

### 4. 向用户确认

把拟定的拆解以**编号列表**呈现。每个 ticket 展示：

- **标题**：简短描述性名称
- **被阻塞**（Blocked by）：必须先完成的其它 tickets（如有）
- **交付什么**：该 ticket 使哪条端到端行为可用

用 `ask_user_question` 工具（可一次问多个问题）询问用户：

- 粒度是否合适？（太粗 / 太细）
- 阻塞边是否正确——每个 ticket 是否只依赖真正门控它的 tickets？
- 是否有 tickets 需要合并或进一步拆分？

反复迭代直到用户批准这份拆解。

### 5. 以本地文件发布 tickets

把已批准的 tickets 写成本地 markdown 文件。**格式固定：**

先在 `.scratch/<feature-slug>/issues/` 下按依赖顺序编号（阻塞者在前，从 `01` 开始），每个 ticket 一个文件，文件名为 `<NN>-<slug>.md`。每个文件的 "Blocked by" 列出它所依赖的编号/标题。**使用下面的 per-ticket 模板——一个 ticket 一个文件，绝不写进单个合并文件。**

做好 **frontier（前沿）**：优先推进阻塞者全部完成的 tickets。对纯线性链，就是自上而下。

**不要**关闭或修改任何父级 issue。

**本地 ticket 模板：**

```markdown
# <NN> — <Ticket title>

**要构建什么（What to build):** 从用户视角，该 ticket 让哪条端到端行为可用——不是逐层实现清单。

**被阻塞（Blocked by):** 触发本 ticket 的其它编号/标题，或 "None — can start immediately"。

**状态（Status):** ready-for-agent

- [ ] 验收标准 1
- [ ] 验收标准 2
```

## 检查清单

- [ ] 每个切片都是贯穿各层的完整垂直通路，能够独立演示/验证
- [ ] 大小适合单个新的上下文窗口
- [ ] 每个 ticket 都声明了阻塞它的其它 tickets；无阻塞者可立即开始
- [ ] 宽重构改用 expand–contract 顺序及其批次/集成分支，不强行当 tracer bullet
- [ ] 已与用户确认粒度与阻塞边
- [ ] 按依赖顺序编号（`01` 起，阻塞者在前），每个 ticket 一个文件放在 `.scratch/<feature-slug>/issues/`
- [ ] 使用本地文件模式与 per-ticket 模板；未发布到任何真实 tracker
- [ ] 正文避免具体文件路径或代码片段（易过期）

## 模板中"要构建什么"与验收标准的写作

两种形式（本地 ticket / 更长的结构）都**避免**具体文件路径或代码片段——它们很快会过期。例外：若原型产生了比文字更能精确编码决策的片段（状态机、reducer、schema、类型形状），可内联它，并简要注明来自原型。只裁剪到富含决策的部分——不是可运行 demo，只是重要要点。

## 技巧要点

- 用项目领域词汇表措辞 ticket 标题与描述，尊重相关 ADR
- 先处理**预重构**，让后续切片落地更简单
- 让每个 ticket 都是 agent 可领取的（ready-for-agent）——阻塞关系清晰即具备此性质
