---
name: request-refactor-plan
description: 为重构/代码改造制定详细的分步（tiny commits）实施计划，并产出一份 RFC 文档。通过采访了解问题、核实代码库、拆解最小提交。当用户提到"制定重构计划""写重构 RFC""拆解重构步骤""安全增量重构""refactor plan""重构需求"时触发。不要用 GitNexus 或无关技能处理；这是规划流程。
---

# 重构计划请求（Request Refactor Plan）

本技能在用户想要创建一份重构需求 / 改造计划时触发。按下面的步骤执行；若某一步在当前场景下不必要，可以跳过，但请说明理由。

## 触发时机

- 用户要求计划一次重构（refactor）或代码改造。
- 用户想要一份重构 RFC / 设计文档 / 实施计划。
- 用户想把一个大的重构拆成安全、可增量（tiny commits）的步骤。
- 涉及"先规划再动手"的较大改动。

## 工作流

采访（`ask_user_question`）→ 核实代码库 → 拆解 tiny commits 计划 → 产出本地 RFC markdown 文件。

## 步骤

1. **采访问题与解决思路**
   用 `ask_user_question` 向用户索要一份"长、详细"的问题描述：他/她想要解决什么问题、以及任何潜在的做法。可一次问多个问题。

2. **核实代码库**
   用 `read` / `grep` / `glob` 探索代码库，核实用户的说法是否属实，并理解当前代码的状态。必要时可派发 `subagent` 做旁路侦查（默认后台运行；prompt 必须自包含，因为子代理没有本会话上下文；需要立即拿结果时设 `run_in_background: false`）。

3. **提出其他选项**
   用 `ask_user_question` 询问是否考虑过其它做法，并把其他选项呈现给用户权衡。

4. **深入采访实现细节**
   极其详细、彻底地采访用户关于实现的问题。覆盖实现的所有关键维度。

5. **敲定实现范围**
   明确计划"要改什么、不改什么"（scope / out of scope）。落地成明确的边界。

6. **核对测试覆盖**
   在代码库中检查该区域的测试覆盖情况。若覆盖不足，用 `ask_user_question` 询问用户的测试计划。

7. **拆解 tiny commits 计划**
   把实现拆成一份 tiny commits 计划。牢记 Martin Fowler 的建议："让每一步重构尽可能小，这样你永远能看到程序处于可用状态。" 每个 commit 都要让代码库保持可运行。

8. **产出 RFC 文档**
   把完整计划写成一份本地 RFC markdown 文件（DSH 无内置 issue 跟踪器，改为写本地文件）：
   - 建议路径：`docs/rfc/<feature>.md`，或 `.scratch/<feature>/RFC.md`（按仓库约定选择；若仓库无约定，可先征询用户偏好）。
   - 使用下方完整模板作为文档正文。
   - 完成后告知用户文件路径；如需要可再人工发布到 issue 跟踪器。

## 模板（RFC 文档正文 <refactor-plan-template>）

```markdown
## Problem Statement

The problem that the developer is facing, from the developer's perspective.

## Solution

The solution to the problem, from the developer's perspective.

## Commits

A LONG, detailed implementation plan. Write the plan in plain English, breaking
down the implementation into the tiniest commits possible. Each commit should
leave the codebase in a working state.

## Decision Document

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being
outdated very quickly.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not
  implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this refactor.

## Further Notes (optional)

Any further notes about the refactor.
```

## 检查清单

- [ ] 已用 `ask_user_question` 完成至少几轮彻底采访（问题、方案、其他选项、实现细节、测试计划）。
- [ ] 已核实代码库（`read`/`grep`/`glob`，必要时 `subagent`）。
- [ ] 已明确 scope 与 out of scope。
- [ ] 已拆出 tiny commits，每步保持代码库可用。
- [ ] 已用完整模板写出 RFC 文档到本地 `docs/` 或 `.scratch/`，并告知用户路径。
