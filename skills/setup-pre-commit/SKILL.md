---
name: setup-pre-commit
description: 配置 Husky + lint-staged（Prettier）+ 类型检查 + 测试的 pre-commit 钩子。当用户想添加 pre-commit 钩子、初始化 Husky、配置 lint-staged、或在提交时自动格式化/类型检查/运行测试时触发。适用于 npm/pnpm/yarn/bun 前端项目。
---

# 配置 Pre-Commit 钩子

## 触发时机

- 用户要求"添加 pre-commit 钩子"、"初始化 Husky"、"配置 lint-staged"、"提交前自动格式化/类型检查/测试"。
- 用户想为当前仓库设置提交时的代码格式化（Prettier）、类型检查与测试流程。

## 这套配置会做什么

- **Husky** pre-commit 钩子
- **lint-staged** 对暂存文件运行 Prettier
- **Prettier** 配置（若无则创建）
- 在 pre-commit 钩子中加入 **typecheck**（类型检查）和 **test**（测试）脚本

## 工作流

### 1. 检测包管理器

检查 `package-lock.json`（npm）、`pnpm-lock.yaml`（pnpm）、`yarn.lock`（yarn）、`bun.lockb`（bun），按存在的文件选择对应包管理器。若都不明确，默认 npm。

### 2. 安装依赖

以 devDependencies 安装：

```
husky lint-staged prettier
```

### 3. 初始化 Husky

```
npx husky init
```

这会在仓库创建 `.husky/` 目录，并向 package.json 的 `scripts` 添加 `prepare: "husky"`。

### 4. 创建 `.husky/pre-commit`

写入以下内容（Husky v9+ 无需 shebang）：

```
npx lint-staged
npm run typecheck
npm run test
```

**适配**：将 `npm` 替换为第 1 步检测到的包管理器（pnpm/yarn/bun）。若仓库的 package.json 中没有 `typecheck` 或 `test` 脚本，则省略对应行并告知用户。

### 5. 创建 `.lintstagedrc`

```json
{
  "*": "prettier --ignore-unknown --write"
}
```

### 6. 创建 `.prettierrc`（若不存在）

仅当项目中尚无 Prettier 配置时才创建。使用以下默认值：

```json
{
  "useTabs": false,
  "tabWidth": 2,
  "printWidth": 80,
  "singleQuote": false,
  "trailingComma": "es5",
  "semi": true,
  "arrowParens": "always"
}
```

### 7. 验证

- [ ] `.husky/pre-commit` 是否存在且可执行
- [ ] `.lintstagedrc` 是否存在
- [ ] package.json 中 `prepare` 脚本是否为 `"husky"`
- [ ] Prettier 配置是否存在
- [ ] 运行 `npx lint-staged` 验证其正常工作

### 8. 提交

暂存所有新建/修改的文件，提交信息为：`Add pre-commit hooks (husky + lint-staged + prettier)`。

此次提交会完整触发新的 pre-commit 钩子——正好作为端到端的冒烟测试。

## 检查清单

- 使用在 Windows 上可用的 npm/pnpm/yarn/bun Windows 命令（shell 为 pwsh）。
- 确保 `prepare` 脚本、`.husky/pre-commit`、`.lintstagedrc`、Prettier 配置四者齐全。
- 提交时钩子能跑通 lint-staged、typecheck、test。

## 注意事项

- Husky v9+ 的 hook 文件无需 shebang。
- `prettier --ignore-unknown` 会跳过 Prettier 无法解析的文件（如图片等）。
- pre-commit 先运行 lint-staged（快、只处理暂存文件），再运行完整的 typecheck 和 test。
