# GitNexus Read-Only MCP Reference

The Codex MCP server is configured with `GITNEXUS_MCP_READ_ONLY=1`. It exposes 13 read-only tools and rejects mutation, raw Cypher, and group routing.

## Start Every Graph Task

1. Call `list_repos({})` when the target repository is unknown.
2. If more than one repository is indexed, pass `repo: "<name>"` on every later call. Never guess when names are ambiguous.
3. Read `gitnexus://repo/<name>/context` before using graph results.
4. Check `staleness.status` on `query`, `context`, `impact`, and `pdg_query` results.
5. Read `staleness.branch` and `staleness.lastCommit` when identity matters.

`list_repos` is paginated:

- Default `limit` is 50 and maximum is 200.
- If `pagination.hasMore` is true, call again with `offset: pagination.nextOffset`.
- Do not conclude that a repository is absent until `hasMore` is false.

Staleness values:

- `current`: the index matches the clone's checked-out HEAD. Use it.
- `behind`: the index is behind HEAD. Refresh only when the answer is load-bearing.
- `diverged`: the indexed commit is not in the current clone history. Refresh before relying on it.
- `unknown`: freshness cannot be measured. State that limitation; an analyze command cannot automatically make a non-Git folder current.

## Tool Selection

| Need | Tool | Key inputs | Important follow-up |
| --- | --- | --- | --- |
| Discover indexed repos | `list_repos` | `limit`, `offset` | Bind `repo` when there are multiple |
| Understand a concept or execution flow | `query` | `search_query`; optional `task_context`, `goal`, `limit`, `max_symbols` | Inspect returned processes, then use `context` on key symbols |
| Inspect one symbol | `context` | `name` or `uid`; optional `file_path`, `kind` | Read `epistemic`, `boundaries`, and `causes` before treating incoming references as complete |
| Find blast radius | `impact` | `target`, `direction`; optional `maxDepth`, `minConfidence`, `uid`, `file`, `kind` | Review depth 1 first; surface HIGH/CRITICAL risk |
| Find how A reaches B | `trace` | `from`, `to`; optional UIDs/files, `maxDepth`, `includeTests` | Use when repeated `context` calls would be wasteful |
| Inspect current diff impact | `detect_changes` | `scope`, optional `base_ref`, `worktree` | Treat `partial` or `truncated` as unresolved |
| Find circular imports | `check` | `cycles` | Read `enumeration` before numeric counts |
| Map API routes | `route_map` | optional `route` | Use `api_impact` before editing a handler |
| Check response shape drift | `shape_check` | optional `route` | Treat a mismatch as a review signal, not proof of a runtime bug |
| Pre-change API report | `api_impact` | `route` or `file`; optional `method` | Review consumers, middleware, mismatch, and risk |
| Inspect MCP/RPC tools | `tool_map` | optional `tool` | Use before changing tool definitions or handlers |
| Inspect taint findings | `explain` | optional `target`, `limit` | Requires an index built with `--pdg`; absence is not proof of safety |
| Inspect control/data dependence | `pdg_query` | `mode`, `target`; optional `variable`, `limit` | `controls` asks what gates X; `flows` traces a variable |

Every tool accepts `repo` when multiple repositories exist. Branch-pinned indexes accept `branch`; use it only when the user or repository workflow names a branch index.

## Common Calls

### Understand code

```text
list_repos({})
query({search_query: "authentication flow", repo: "my-app", limit: 5})
context({name: "validateUser", repo: "my-app"})
```

After selecting a process, read:

```text
gitnexus://repo/my-app/process/<processName>
```

### Analyze impact before a risky edit

```text
impact({
  target: "validateUser",
  repo: "my-app",
  direction: "upstream",
  maxDepth: 3
})
```

Then use `detect_changes` before the final commit:

```text
detect_changes({scope: "all", repo: "my-app"})
```

For a linked worktree that the MCP server did not start from:

```text
detect_changes({
  scope: "all",
  repo: "my-app",
  worktree: "C:/absolute/path/to/worktree"
})
```

### Trace a call chain

```text
trace({
  from: "processCheckout",
  to: "fetchRates",
  repo: "my-app",
  maxDepth: 10
})
```

When `status` is `ambiguous`, retry with `from_uid` or `to_uid`. When it is `no_path`, inspect the furthest reachable hop instead of inventing a path.

### Review an API change

```text
api_impact({route: "/api/orders", method: "POST", repo: "my-app"})
route_map({route: "/api/orders", repo: "my-app"})
shape_check({route: "/api/orders", repo: "my-app"})
```

### Review security or data dependence

```text
explain({target: "runUserCommand", repo: "my-app"})
pdg_query({mode: "controls", target: "runUserCommand", repo: "my-app"})
pdg_query({mode: "flows", target: "runUserCommand", variable: "sql", repo: "my-app"})
```

## Risk and Completeness Rules

- `impact` risk `HIGH` or `CRITICAL`: report affected callers before editing.
- Risk `UNKNOWN`: unresolved, not low risk. Confirm with source search or tests.
- `context.epistemic = "lower-bound"`: incoming references are a floor, not proof of completeness.
- `detect_changes.partial = true`: a graph step failed. Do not treat an empty or short diff as clean.
- `detect_changes.truncated = true`: the changed-symbol list is capped. Re-run or narrow the scope.
- `check.enumeration = "component-representatives"`: the full cycle list was capped. Use `status` and `componentCount`, not a numeric `cycleCount`.
- `explain` and `pdg_query` need an index built with `--pdg`; absence of a finding is not proof of safety.

## Resources

| Resource | Use |
| --- | --- |
| `gitnexus://repo/<name>/context` | Repository overview and index freshness |
| `gitnexus://repo/<name>/clusters` | Functional areas |
| `gitnexus://repo/<name>/cluster/<clusterName>` | Area members |
| `gitnexus://repo/<name>/processes` | Execution flows |
| `gitnexus://repo/<name>/process/<processName>` | One execution trace |
| `gitnexus://repo/<name>/schema` | Graph schema; raw Cypher is unavailable over this MCP server |

## Unavailable in Read-Only Mode

Do not plan around these MCP tools:

- `rename`
- `cypher`
- `group_list`, `group_sync`, and group-routed calls

Use normal source editing and an appropriate refactoring tool for mutations. Use the CLI reference for the read-only CLI fallback when MCP is unavailable.
