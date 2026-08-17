---
name: ubiquitous-language
description: 从对话中提取并规范化 DDD 通用语言（ubiquitous language）词汇表，标注歧义并提出规范术语。当用户提及「领域模型」「DDD」「领域术语」「通用语言」「术语表」「词汇表」「统一语言」，或要求整理/固化领域概念、定义领域词汇时，必须触发此技能。
---

# 通用语言（Ubiquitous Language）

从当前对话中提取并规范化领域术语，整理成一致的词汇表（glossary），写入本地文件 `UBIQUITOUS_LANGUAGE.md`。

## 触发时机

- 用户提及「领域模型」「DDD」「领域术语」「通用语言」「术语表」「词汇表」「统一语言」。
- 用户要求定义领域概念、固化术语、打磨术语边界、整理对话中的业务词汇。
- 用户提到「domain model」「ubiquitous language」等 DDD 概念。

## 工作流

1. **扫描对话**，找出领域相关的名词、动词与概念。
2. **识别问题**：
   - 同一词汇指代不同概念（歧义）
   - 不同词汇描述同一概念（同义词）
   - 含糊或过于宽泛的术语
3. **提出一套规范的词汇表**，术语选择要有明确立场（opinionated）。
4. **写入 `UBIQUITOUS_LANGUAGE.md`**：优先按仓库现有约定放置该文件；若不存在约定，则在当前工作目录创建，并使用下面的模板格式。
5. **在对话中输出摘要**。

> 说明：`UBIQUITOUS_LANGUAGE.md` 是一个仓库文档。按仓库现有约定决定文件存放位置；若仓库尚无该文件，则按本技能模板在合适位置创建。

## 输出模板

按如下结构写入 `UBIQUITOUS_LANGUAGE.md`：

```md
# Ubiquitous Language

## Order lifecycle

| Term        | Definition                                              | Aliases to avoid      |
| ----------- | ------------------------------------------------------- | --------------------- |
| **Order**   | A customer's request to purchase one or more items      | Purchase, transaction |
| **Invoice** | A request for payment sent to a customer after delivery | Bill, payment request |

## People

| Term         | Definition                                  | Aliases to avoid       |
| ------------ | ------------------------------------------- | ---------------------- |
| **Customer** | A person or organization that places orders | Client, buyer, account |
| **User**     | An authentication identity in the system    | Login, account         |

## Relationships

- An **Invoice** belongs to exactly one **Customer**
- An **Order** produces one or more **Invoices**

## Example dialogue

> **Dev:** "When a **Customer** places an **Order**, do we create the **Invoice** immediately?"
> **Domain expert:** "No — an **Invoice** is only generated once a **Fulfillment** is confirmed. A single **Order** can produce multiple **Invoices** if items ship in separate **Shipments**."
> **Dev:** "So if a **Shipment** is cancelled before dispatch, no **Invoice** exists for it?"
> **Domain expert:** "Exactly. The **Invoice** lifecycle is tied to the **Fulfillment**, not the **Order**."

## Flagged ambiguities

- "account" was used to mean both **Customer** and **User** — these are distinct concepts: a **Customer** places orders, while a **User** is an authentication identity that may or may not represent a **Customer**.
```

## 规则

- **要有明确立场。** 同一概念存在多个词汇时，选出一个最佳术语，其余列为需避免的别名（aliases to avoid）。
- **显式标注冲突。** 若某术语在对话中出现歧义，在「Flagged ambiguities」中明确指出，并给出清晰建议。
- **只收录领域专家关心的术语。** 跳过模块名或类名，除非它们在领域语言中有具体含义。
- **定义保持精简。** 定义最多一句话。说清楚它「是什么」，而不是「做什么」。
- **展示关系。** 术语名加粗，明显处标注基数关系（cardinality）。
- **只收录领域术语。** 跳过通用编程概念（array、function、endpoint 等），除非其带有领域特定含义。
- **按自然聚类分组。** 出现自然聚簇时（如按子域、生命周期、参与者）分为多个表格，每组有自己的标题与表格。若所有术语都属于单一凝聚的领域，一个表格即可，不必强行分组。
- **写下示例对话。** 一段简短的（3-5 轮）开发与领域专家对话，展示各术语如何自然互动。对话应澄清相关概念之间的边界，展示术语被准确使用。

示例对话补充：

> **Dev:** "How do I test the **sync service** without Docker?"

> **Domain expert:** "Provide the **filesystem layer** instead of the **Docker layer**. It implements the same **Sandbox service** interface but uses a local directory as the **sandbox**."

> **Dev:** "So **sync-in** still creates a **bundle** and unpacks it?"

> **Domain expert:** "Exactly. The **sync service** doesn't know which layer it's talking to. It calls `exec` and `copyIn` — the **filesystem layer** just runs those as local shell commands."

## 重复运行

在同一会话中再次被调用时：

1. 读取已有的 `UBIQUITOUS_LANGUAGE.md`
2. 纳入后续讨论中出现的任何新术语
3. 若理解有所演进，更新定义
4. 重新标注任何新出现的歧义
5. 重写示例对话，纳入新术语

## 检查清单

- [ ] 词汇表已写入 `UBIQUITOUS_LANGUAGE.md`（按仓库约定位置）
- [ ] 定义了歧义、同义词、含糊术语三类问题
- [ ] 每个术语定义精炼（一句话），说清「是什么」
- [ ] 术语名加粗，明显处标注基数关系
- [ ] 术语已按自然聚类分组（避免强行分组）
- [ ] 「Flagged ambiguities」标注了所有歧义并给出建议
- [ ] 提供了 3-5 轮示例对话
- [ ] 已在对话中输出摘要
