# 插件说明

## opencode（npm 插件，启动时自动安装）

见 `opencode-plugins.json`，当前启用：

| 插件 | 作用 |
|---|---|
| `opencode-goal-plugin` | 会话级 `/goal` 工作流：目标常驻上下文，自动持续执行直到完成（等效 Codex goal 模式） |
| `oh-my-openagent` | 后台代理 + 预置 LSP/AST/MCP 工具，Claude Code 兼容 |

常用生态插件（按需加，别贪多——插件和 MCP 都会占上下文）：

- `opencode-background-agents`：异步后台子代理
- `opencode-supermemory`：跨会话持久记忆
- `opencode-dynamic-context-pruning`：剪裁旧工具输出省 token
- `opencode-vibeguard`：发送前脱敏密钥/PII
- `opencode-notificator`：桌面通知
- `opencode-openai-codex-auth`：用 ChatGPT Plus/Pro 订阅代替 API 计费

完整列表：https://opencode.ai/docs/ecosystem

## Codex / Claude Code

- Codex：桌面版插件（`~/.codex/plugins/`）由应用托管，不随仓库分发
- Claude Code：插件走官方插件市场（`claude plugin marketplace add`），需要时手动安装