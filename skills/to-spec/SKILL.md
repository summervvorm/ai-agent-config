---
name: to-spec
description: 把当前对话综合成一份 spec（PRD），不做采访，不额外提问。当用户把一次聊天/需求讨论结束后要求"把它写成 spec"、"生成 PRD"、"整理成需求文档"、"把对话总结成开发规格"、"to spec"时，务必触发此技能。
---

# To Spec（对话转需求规格）

本技能把当前对话上下文和代码库理解综合成一份 spec（你可能称之为 PRD）。**不做采访**——不要反复向用户提问，只综合你已经在对话中掌握的已知信息。如确有需要澄清的取舍点（例如测试接入点与用户预期不符），可用 `ask_user_question` 一次性问齐，但不要用它替代综合。

## 触发时机

- 用户把一次讨论/对话结束后要求"写成 spec"、"生成 PRD"、"整理成需求文档"、"把对话综合成规格"、"to spec"。
- 用户给出一个已讨论的功能/特性，希望产出可交付给开发执行的规格文档。
- 需要把当前对话的结论沉淀成一份结构化需求文档时。

## 工作流

1. **了解代码库当前状态**（若尚未了解）。可用 `read`/`glob`/`grep` 直接探查；若涉及大范围探索，可用 `subagent` 工具后台派生子代理（子代理没有本会话上下文，prompt 必须自包含）。全程使用项目<ruby>领域术语表</ruby>（AGENTS.md / CONTEXT.md / UBIQUITOUS_LANGUAGE.md 等仓库文档，按仓库现有约定，不存在则按规范创建），并尊重你所涉及区域内已有的 ADR（架构决策记录）。

2. **勾勒测试接入点（seam）**。优先复用既有接入点，不新建；总是选最高层的接入点（highest seam possible）。若确实需要新接入点，尽量提出在你能想到的最高位置。全代码库的接入点越少越好——理想数量是一个。用 `ask_user_question` 与用户确认这些接入点是否符合预期。

3. **用下方模板写 spec**，然后写到本地文件。发布地址：优先写在仓库合理的文档路径下（如 `docs/<feature>/SPEC.md`），或按仓库约定的需求文档目录；若无约定，可写 `.scratch/<feature>/SPEC.md`。文件为 markdown，一个文件即可，说明可稍后人工发布给 issue tracker。

## 模板

复制以下模板并填充分节。

```markdown
# <Feature> — Spec

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this spec.

## Further Notes

Any further notes about the feature.
```

## 步骤

1. 用 `read`/`glob`/`grep`（或 `subagent` 进行大规模探索）理解代码库当前状态，确认领域术语表与相关 ADR。
2. 勾勒测试接入点，用 `ask_user_question` 与用户确认是否匹配预期（一次可问多个问题）。
3. 按上述模板写完整 spec，不省略任何分节。
4. 用 `write` 工具把 spec 写到本地文件（如 `docs/<feature>/SPEC.md` 或 `.scratch/<feature>/SPEC.md`）。

## 检查清单

- [ ] 未对用户进行反复采访，只综合已知信息。
- [ ] 未发布到 issue tracker；spec 写入本地 markdown 文件并已说明可稍后人工发布。
- [ ] spec 使用项目领域术语表词汇，尊重相关 ADR。
- [ ] 模板全部分节齐全（Problem Statement / Solution / User Stories / Implementation Decisions / Testing Decisions / Out of Scope / Further Notes）。
- [ ] User Stories 足够长、覆盖特性所有方面。
- [ ] Implementation Decisions 不包含具体文件路径或代码片段（原型提炼出的决策性片段除外）。
- [ ] 已写入文件。
