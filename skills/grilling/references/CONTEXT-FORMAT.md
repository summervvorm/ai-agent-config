# CONTEXT.md Format

## 结构

```md
# {Context 名称}

{一两句话描述这个 context 是什么、为何存在。}

## Language（语言）

**Order（订单）**：
{关于该术语的一两句话}
_避免（Avoid）_: Purchase、transaction

**Invoice（发票）**:
发给客户、在交付后要求付款的请求。
_避免_: Bill、payment request

**Customer（客户）**:
下订单的个人或组织。
_避免_: Client、buyer、account
```

## 规则

- **要有立场（Be opinionated）。**多个词指同一概念时，选最好的一个，把其余的列在 `_避免_` 下。
- **定义要紧凑。**最多一两句。定义它"是什么（IS）"，而不是"做什么"。
- **只包含属于该项目 context 特有的术语。**通用的编程概念（超时、错误类型、工具性模式）即使项目大量使用也不该进来。加术语前问自己：这是这个 context 独有的概念，还是通用编程概念？只有前者才合适。
- **自然成簇时按子标题分组。**若所有术语都属于同一内聚领域，平铺列表即可。

## 单一 vs 多 context 仓库

**单一 context（多数仓库）：**仓库根目录一个 `CONTEXT.md`。

**多 context：**仓库根目录一个 `CONTEXT-MAP.md`，列出各 context、它们在哪、彼此如何关联：

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) —— 接收并跟踪客户订单
- [Billing](./src/billing/CONTEXT.md) —— 生成发票并处理付款
- [Fulfillment](./src/fulfillment/CONTEXT.md) —— 管理仓库拣货与发货

## Relationships（关系）

- **Ordering → Fulfillment**：Ordering 发出 `OrderPlaced` 事件；Fulfillment 消费它们来开始拣货
- **Fulfillment → Billing**：Fulfillment 发出 `ShipmentDispatched` 事件；Billing 消费它们来生成发票
- **Ordering ↔ Billing**：「CustomerId」和「Money」共享类型
```

按以下方式推断结构：

- 若 `CONTEXT-MAP.md` 存在，读它来找 context
- 若只有根 `CONTEXT.md`，则是单一 context
- 若都不存在，在第一个术语敲定时懒建根 `CONTEXT.md`

存在多个 context 时，推断当前话题属于哪个；不清楚就问用户。
