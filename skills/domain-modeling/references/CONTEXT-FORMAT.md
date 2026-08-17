# CONTEXT.md 格式（CONTEXT Format）

## 结构

```md
# {上下文名称}

{一两句说明这个上下文是什么、为什么存在。}

## Language

**Order**:
{一两句对该术语的描述}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

## 规则

- **要有主张（Be opinionated）。** 当同一个概念有多个词时，挑最好的一个，把其余的列在 `_Avoid_` 下。
- **定义要紧凑。** 最多一两句。定义它 *是什么*，而不是它 *干什么*。
- **只收录本项目上下文特有的术语。** 通用编程概念（timeout、错误类型、工具类模式）即使项目大量使用也不该放进来。加术语前问一句：这是本上下文独有的概念，还是一个通用编程概念？只有前者才该放进来。
- **自然聚类时按小标题分组。** 如果所有术语都属于一个连贯领域，平铺列表即可。

## 单上下文 vs 多上下文仓库

**单上下文（大多数仓库）：** 仓库根目录一个 `CONTEXT.md`。

**多上下文：** 仓库根目录一个 `CONTEXT-MAP.md` 列出各上下文、它们在哪、以及它们如何关联：

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — 接收并跟踪客户订单
- [Billing](./src/billing/CONTEXT.md) — 生成发票并处理支付
- [Fulfillment](./src/fulfillment/CONTEXT.md) — 管理仓库拣货与发货

## Relationships

- **Ordering → Fulfillment**: Ordering 发出 `OrderPlaced` 事件；Fulfillment 消费它们开始拣货
- **Fulfillment → Billing**: Fulfillment 发出 `ShipmentDispatched` 事件；Billing 消费它们生成发票
- **Ordering ↔ Billing**: 共享 `CustomerId` 与 `Money` 的类型
```

技能按以下规则推断适用哪个结构：

- 如果存在 `CONTEXT-MAP.md`，读它来找出各上下文
- 如果只有根 `CONTEXT.md`，就是单上下文
- 如果两者都不存在，在第一个术语被确定时懒创建根 `CONTEXT.md`

当存在多个上下文时，推断当前话题属于哪一个。如果不清楚，就 `ask_user_question` 询问。
