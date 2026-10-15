# 常泰云测试环境速查

## 环境矩阵

| 环境 | Auth | SCM / API 前缀 | MySQL MCP |
|------|------|----------------|-----------|
| local | `http://127.0.0.1:19200` | `http://127.0.0.1:19204` | `mysql_dev` |
| dev | `https://__CT_DEV_HOST__/api/auth` | `https://__CT_DEV_HOST__/api/scm` | `mysql_dev` |
| test | `https://__CT_TEST_HOST__/api/auth` | `https://__CT_TEST_HOST__/api/scm` | `mysql_test` |

## 判断规则

1. 未指定环境、URL 或环境变量 -> 默认 `local`。
2. URL 包含 `__CT_DEV_HOST__` -> `dev`。
3. URL 包含 `__CT_TEST_HOST__` -> `test`。
4. URL 包含 `127.0.0.1` / `localhost` -> `local`。
5. `CT_TEST_ENV` 可覆盖默认值。
6. 不需要强制用户先指定环境。

## 路由

| 场景 | local | dev | test |
|------|-------|-----|------|
| 登录 | `/login` | `/api/auth/login` | `/api/auth/login` |
| 直连 API | `http://127.0.0.1:19204/<path>` | `https://__CT_DEV_HOST__/api/scm/<path>` | `https://__CT_TEST_HOST__/api/scm/<path>` |
| 网关 API | `http://127.0.0.1:18080/scm/<path>` | `https://__CT_DEV_HOST__/api/scm/<path>` | `https://__CT_TEST_HOST__/api/scm/<path>` |

## Token

优先级：

1. `CT_TEST_TOKEN`
2. `%TEMP%\ct-test-token-{env}.json` 缓存
3. `CT_TEST_USERNAME` + `CT_TEST_PASSWORD`

请求头：

```http
Authorization: Bearer <access_token>
```

401 时自动清缓存并重登一次。

## Dry-run

不登录、不调接口，只检查环境判断和最终 URI：

```powershell
pwsh -File scripts/Invoke-ChangtaiApi.ps1 -Environment auto -Route gateway -Path /service/resource/action -DryRun
```

## MCP

MySQL：

- local / dev：`mysql_dev`
- test：`mysql_test`
- 一次一条 SQL
- 写操作前先查当前数据库

Obsidian：

- 默认不调用。
- 用户明确指定文档或要求回写时使用 `mcp_obsidian`。

## 安全规则

- 测试数据带唯一前缀。
- 不修改无法按唯一前缀回滚的数据。
- 共享环境不调用全量扫描接口。
- 密码和 Token 不进入仓库、Skill、Obsidian、日志。
- 测试完成后清理数据并复查残留。

## 网关服务前缀

默认使用 -ServicePrefix /scm。如果测试其它服务，可覆盖该参数。
