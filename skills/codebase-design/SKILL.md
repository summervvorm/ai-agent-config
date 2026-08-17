---
name: codebase-design
description: 设计深模块（deep modules）的共享词汇表与原则。当用户想设计或改进模块的接口、寻找加深（deepening）机会、决定 seam 放在哪里、让代码更可测或更便于 AI 导航、或当其他技能需要深模块设计词汇时，务必触发。核心概念包括 module/interface/depth/seam/adapter/leverage/locality、deletion test（删除测试）等。用户提到"模块接口设计"、"深模块"、"怎么划分边界/接缝"、"让代码更好测"、"重构模块使其更深"、"设计两次"等表述时即应触发。
---

# 代码库设计（Codebase Design）

设计**深模块（deep module）**：把大量行为放在一个很小的接口后面，接口位于一条干净、清晰的 seam 上，并通过该接口可测试。在一切代码设计或被重构之处，都使用这套语言与这些原则。目标是：对调用方而言是**杠杆（leverage）**，对维护者而言是**局部性（locality）**，对所有人而言是**可测试性**。

## 触发时机

- 用户要设计或改进某个模块的**接口（interface）**。
- 用户要寻找**加深（deepening）**机会——例如把多个浅模块（shallow module）合并成一个深模块。
- 用户要决定一条 **seam（接缝）** 放在哪里。
- 用户要让代码更可测，或更便于 AI 导航（便于模型理解与定位）。
- 其他技能需要深模块设计词汇时，也使用本技能的语言。

## 词汇表（Glossary）

必须**精确使用**这些术语，不要用 "component"、"service"、"API"、"boundary" 等词替代。语言一致本身就是关键。

- **Module（模块）** — 任何"有接口 + 有实现"的东西。刻意做到与规模无关：可以是一个函数、一个类、一个包，也可以是一个跨层切片。*避免*：unit、component、service。
- **Interface（接口）** — 调用方要正确使用此模块所必须知道的一切：类型签名，还包括不变量、顺序约束、错误模式、所需配置与性能特征。*避免*：API、signature（都太窄——它们只指类型层面的表面）。
- **Implementation（实现）** — 模块内部的东西，也就是它的代码主体。它与 **Adapter（适配器）** 不同：一个东西可以是一个"带大实现的小适配器"（例如一个 Postgres 仓储），也可以是一个"带小实现的大适配器"（例如内存假实现）。当讨论的主题是 seam 时用 "adapter"，否则用 "implementation"。
- **Depth（深度）** — 接口处的杠杆：调用方（或测试）每学习一单位接口所能产生的行为量。当一个模块大量行为位于一个小接口之后时它是**深的（deep）**；当接口几乎和实现一样复杂时它是**浅的（shallow）**。
- **Seam（接缝）**（Michael Feathers）— 一个你可以在不"在该处修改"的前提下改变行为的位置；也就是模块接口所栖身的*位置*。把 seam 放在哪里是与"接口后面放什么"相对独立的设计决策。*避免*：boundary（与 DDD 的 Bounded Context 语义冲突、过载）。
- **Adapter（适配器）** — 在 seam 处满足某个接口的具体实现。它描述的是*角色*（填补哪个位置），不是*实质*（内部是什么）。
- **Leverage（杠杆）** — 深度带给调用方的收益：每学习一单位接口，获得更多能力。一份实现能在 N 个调用点与 M 个测试之间摊还回报。
- **Locality（局部性）** — 深度带给维护者的收益：变更、缺陷、知识与验证都集中在一处，而不是散布到调用方。修一次，处处生效。

## 深 vs 浅

**深模块** = 小接口 + 大量实现：

```
┌─────────────────────┐
│   Small Interface   │  ← 少量方法、简单参数
├─────────────────────┤
│                     │
│  Deep Implementation│  ← 隐藏复杂逻辑
│                     │
└─────────────────────┘
```

**浅模块** = 大接口 + 少量实现（应避免）：

```
┌─────────────────────────────────┐
│       Large Interface           │  ← 很多方法、复杂参数
├─────────────────────────────────┤
│  Thin Implementation            │  ← 只是透传
└─────────────────────────────────┘
```

设计接口时，自问：

- 能否减少方法数量？
- 能否简化参数？
- 能否把更多复杂度藏进实现内部？

## 原则

- **深度是接口的属性，不是实现的属性。** 一个深模块内部可以由很多小而可 mock、可替换的部分组成——它们只是不属于接口而已。一个模块既可以有**内部 seam**（私有于其实现，供其自身测试使用），也可以有位于其接口处的**外部 seam**。
- **删除测试（the deletion test）。** 想象删除这个模块。如果复杂度随之消失，它就是一个透传（pass-through）。如果复杂度在 N 个调用方处重新出现，那它就在"赚取自己的存活价值"。
- **接口就是测试面（The interface is the test surface）。** 调用方与测试跨同一条 seam。如果你想测到接口*之外/内部*去，那这个模块的形态多半不对。
- **一个适配器 = 假设性的 seam；两个适配器 = 真实的 seam。** 除非确有东西跨 seam 变化，否则不要引入 seam。

## 为可测试性而设计

好的接口会让测试自然发生：

1. **接受依赖，而不是创建依赖。**

   ```typescript
   // 可测
   function processOrder(order, paymentGateway) {}

   // 难测
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. **返回结果，而不是产生副作用。**

   ```typescript
   // 可测
   function calculateDiscount(cart): Discount {}

   // 难测
   function applyDiscount(cart): void {
     cart.total -= discount;
   }
   ```

3. **小表面积（Small surface area）。** 方法更少 = 需要的测试更少；参数更少 = 测试搭建更简单。

## 关系（Relationships）

- 一个 **Module** 恰好有一个 **Interface**（它呈现给调用方与测试的表面）。
- **Depth** 是一个 **Module** 相对其 **Interface** 衡量的属性。
- 一条 **Seam** 就是一个 **Module** 的 **Interface** 栖身之处。
- 一个 **Adapter** 位于一条 **Seam** 处并满足该 **Interface**。
- **Depth** 为调用方带来 **Leverage**，为维护者带来 **Locality**。

## 被否定的框定（Rejected framings）

- **把深度定义为"实现行数/接口行数"之比**（Ousterhout）：这会奖励填充实现。本技能用"深度即杠杆"（depth-as-leverage）。
- **把 "Interface" 理解为 TypeScript 的 `interface` 关键字或一个类的公有方法**：太窄——这里的 interface 涵盖调用方必须知道的每一个事实。
- **用 "Boundary"**：与 DDD 的 Bounded Context 语义过载。应说 **seam** 或 **interface**。

## 深入（Going deeper）

- **给定依赖的情况下加深一簇模块** — 见 [`references/DEEPENING.md`](references/DEEPENING.md)：依赖分类、seam 纪律、以及"替换而不堆层"（replace-don't-layer）的测试策略。
- **探索备选接口** — 见 [`references/DESIGN-IT-TWICE.md`](references/DESIGN-IT-TWICE.md)：并行派出多个子代理（subagent），用几种截然不同的方式设计接口，然后按 depth、locality 与 seam 位置进行比较。
