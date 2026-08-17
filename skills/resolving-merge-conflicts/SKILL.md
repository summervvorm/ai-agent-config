---
name: resolving-merge-conflicts
description: 解决进行中的 git merge/rebase 冲突。当 git merge、git rebase、git cherry-pick 或 pull 报出 CONFLICT / Merge conflict、冲突标记 "<<" ">>" 或无法继续合并时触发；也适用于用户要求"解决冲突"、"处理合并冲突"、"把这次合并做完"。
---

# 解决合并冲突

解决进行中的 git merge / rebase / pull / cherry-pick 冲突。git 命令保持不变，shell 语境为 pwsh（Windows PowerShell）。

## 触发时机

- `git merge`、`git pull`（拉取触发合并）报出 `CONFLICT` 或"自动合并失败"。
- `git rebase` 进行中，某一提交碰到冲突被暂停。
- `git cherry-pick` 报冲突。
- 用户说"解决冲突"、"处理合并冲突"、"帮我把这次合并完成"、"rebase 卡住了"。
- 工作区里出现 `<<<<<<<` / `=======` / `>>>>>>>` 冲突标记。

## 核心原则

- **绝不 `--abort`**。总是设法解决冲突并完成合并，不要半途取消。
- 不发明新行为：尽量保留双方的意图；无法兼容时才二选一，并说明取舍。
- git 命令直接使用（git merge / git rebase / git commit 等），shell 环境用 pwsh 工具执行。

## 工作流

### 步骤 1：查看当前状态

- 用 `pwsh` 运行 `git status`，确认处于 merge/rebase 状态以及哪些文件冲突。
- `git log --oneline -10` 查看历史。
- 打开冲突文件，定位所有 `<<<<<<<` 冲突块并逐一处理。

### 步骤 2：找到冲突的原始来源

- 深刻理解每个冲突为什么产生、改动本意是什么。
- `git log --oneline -- <file>` 查看该文件相关提交。
- 阅读提交信息（`git show <hash>`），尽量查看对应 PR、issue/ticket 里的原意。
- 目标是理解"双方各自想干什么"，而不是草率删掉一边。

### 步骤 3：逐个解决冲突块

- 逐个处理每个 `<<<<<<<` hunk。
- 能同时保留双方意图的，尽量合并保留（取并集）。
- 无法兼容的，选择与本次合并既定目标一致的一方，注明做出的取舍。
- **不要**为了省事发明新的、双方都没写过的行为。
- 解决完所有冲突块后再进行下一步；绝不对整个合并 `--abort`。

### 步骤 4：运行项目的自动化检查并修复

- 发现项目的自动化检查手段并运行——典型顺序：类型检查（typecheck）、测试（tests）、格式化（format）。
- 确定项目配置：`package.json` 的 scripts、`Makefile`、`pom.xml`/Maven 的 verify、或其他约定。
- 在 `pwsh` 中执行相应命令，修复任何由 merge 引入的破坏。

### 步骤 5：完成 merge / rebase

- 检查 `git status`，确认无未解决冲突、无未跟踪的冲突残留。
- `git add -A`（或 `git add <files>`）暂存全部改动。
- 提交：`git commit`（合并后提交）或按 rebase 流程 `git rebase --continue` 提交当前 commit 信息。
- 若是 rebase：重复"继续"，直到所有提交都被 rebase 完成。
- 最后 `git log --oneline` 与 `git status` 确认干净收尾。

## 检查清单

- [ ] `git status` 不再显示 `Unmerged paths` 或 `CONFLICT`。
- [ ] 所有冲突块均已解决，无 `<<<<<<<`、`=======`、`>>>>>>>` 残留（可用 `git diff --check` 复核）。
- [ ] 每个冲突都保留了意图，未擅自发明新行为；取舍处已说明。
- [ ] 自动化检查（typecheck → tests → format）全部通过，merge 引入的破坏已修复。
- [ ] 所有改动已暂存并提交；rebase 场景下所有提交已 rebase 完成。
