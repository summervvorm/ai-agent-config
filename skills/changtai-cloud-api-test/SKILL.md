---
name: changtai-cloud-api-test
description: 在 changtai-cloud / 常泰云项目中，只要用户要求真实调用接口、造数据验证、接口联调、回归验证、验证接口结果、排查接口与数据库一致性，或使用 MCP 执行测试流程，就应使用本 Skill，即使没有明确说“测试”或“Skill”。默认 local 环境；用户提供 URL、环境变量或明确说明时可自动识别 dev/test。统一处理登录 Token、直连或网关调用、MySQL MCP 造数与断言、测试结果返回；仅在用户明确要求时使用 Obsidian MCP 读写文档。触发词包括“接口实测”“造数据”“调接口”“联调”“回归验证”“验证接口”“本地/开发/测试环境”“MCP”“查库断言”“真实请求”。
---

# 常泰云真实接口与造数测试

## 目标

将“确认测试目标 -> 判断环境 -> 登录鉴权 -> 造数 -> 调接口 -> 查库断言 -> 清理 -> 返回结果”做成一条可重复执行的闭环。

## 环境判断

### 默认规则

- 用户未指定环境、未提供 URL、也没有环境变量时：默认 `local`。
- 用户提供 URL：
  - `__CT_DEV_HOST__` -> `dev`
  - `__CT_TEST_HOST__` -> `test`
  - `127.0.0.1` / `localhost` -> `local`
- 用户明确说“开发/dev” -> `dev`。
- 用户明确说“测试/test” -> `test`。
- `CT_TEST_ENV` 可覆盖默认判断。
- 不需要为了开始测试而强制用户指定环境。

环境矩阵见 `references/environment.md`。

### 路由

默认直连业务服务；仅在用户要求验证网关时使用网关路径。

```text
local 直连：http://127.0.0.1:19204/<path>
local 网关：http://127.0.0.1:18080/scm/<path>

dev 直连：https://__CT_DEV_HOST__/api/scm/<path>
test 直连：https://__CT_TEST_HOST__/api/scm/<path>
```

## 鉴权与 Token

统一使用 `scripts/Invoke-ChangtaiApi.ps1`，不要在每次请求前重复手写登录逻辑。

Token 优先级：

1. `CT_TEST_TOKEN`
2. 对应环境的短时缓存
3. `CT_TEST_USERNAME` + `CT_TEST_PASSWORD` 登录
4. 缺少凭据时再向用户索取一次

规则：

- 同一轮测试只登录一次并复用 Token。
- local、dev、test 使用不同缓存文件。
- 401 时清除该环境缓存并重登一次。
- 禁止打印 Token 原文，只输出 `hasToken` 或 `tokenLength`。
- 禁止把密码、Token 写入仓库、Skill、Obsidian 或日志。

只检查环境和路由：

```powershell
pwsh -File scripts/Invoke-ChangtaiApi.ps1 `
  -Environment auto `
  -Route gateway `
  -Path /service/resource/action `
  -DryRun
```

只验证登录：

```powershell
pwsh -File scripts/Invoke-ChangtaiApi.ps1 -Environment auto -LoginOnly
```

调用接口：

```powershell
pwsh -File scripts/Invoke-ChangtaiApi.ps1 `
  -Environment auto `
  -Route direct `
  -Method POST `
  -Path /service/resource/action `
  -Body '{"key":"value"}'
```

## 标准流程

### 1. 明确测试目标

从用户描述、接口定义、代码或用户指定的文档中整理：

- 被测接口和请求参数。
- 预期业务结果。
- 预期数据库变化。
- 数据清理条件。
- 本轮不测什么。

只有用户明确要求读取或写入 Obsidian 时才调用 Obsidian MCP。

### 2. 判断环境和数据库

默认 `local`，按环境判断规则识别 dev/test。

执行写操作前，使用 MySQL MCP 确认：

```sql
SELECT DATABASE() AS current_db, @@hostname AS hostname, @@port AS port
```

默认选择：

- local / dev：`mysql_dev`
- test：`mysql_test`

实际以用户说明和数据库返回为准。

### 3. 造测试数据

- 使用唯一前缀，例如 `QAyyyyMMddHHmmss`。
- 先查残留，再插入。
- 先记录测试前状态。
- 只创建本轮需要的最小数据。
- 不修改无法通过唯一标识回滚的数据。
- 记录关键主键、业务单号和资源标识，供清理与断言。

### 4. 调接口

- 默认直连业务服务。
- 需要时才走网关。
- 同时检查 HTTP 状态、业务 `code`、`msg` 和 `data`。
- HTTP 200 不等于业务成功。

### 5. 数据库断言

使用对应 MySQL MCP：

- 核对更新行数和值。
- 核对新增行数和合计。
- 核对是否重复。
- 核对是否影响非本次前缀数据。

MCP 默认一次只执行一条 SQL。

### 6. 清理

按依赖顺序删除本次前缀数据，并复查残留为 0。

审计日志默认保留，除非用户明确要求清理。

### 7. 返回结果

默认只在对话中返回测试结果，不写 Obsidian。

只有用户明确说：

- “写到 Obsidian”
- “回写测试文档”
- “更新这份文档”
- “生成测试报告并保存”

才使用 Obsidian MCP。

## 默认边界

- 默认不测试定时任务、异步任务或消息任务，除非用户明确要求。
- 默认不调用会扫描全库的批量接口，除非用户明确接受影响范围。
- 默认不修改共享数据。
- 默认不写 Obsidian。
- 环境不明确时默认 `local`，但涉及写操作前必须复核数据库连接。

## MCP 使用约定

| MCP | 用途 | 使用条件 |
|-----|------|----------|
| `mysql_dev` / `mysql_test` | 造数、断言、清理 | 有数据库测试时 |
| `mcp_obsidian` | 读取/写入文档 | 用户明确指定文档或要求回写 |
| `node_repl` | 辅助 JSON/脚本处理 | 按需 |
| `toolknit` | 文件/媒体辅助 | 按需 |

## 输出要求

默认在对话中返回：

1. 使用的环境和实际地址。
2. 用例通过/失败/跳过表。
3. 失败用例的复现数据、实际结果和期望结果。
4. 数据库断言证据。
5. 数据清理结果。
6. 是否已写入 Obsidian。

## 相关文件

- `references/environment.md`：环境、端口、路由、MCP。
- `assets/test-run-template.md`：通用执行记录模板。
- `scripts/Invoke-ChangtaiApi.ps1`：环境识别、Token 复用、接口调用。
