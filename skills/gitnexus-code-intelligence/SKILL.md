---
name: gitnexus-code-intelligence
description: "Use when structural impact, callers, dependencies, execution flows, API routes, or cross-module safety matter in a GitNexus-indexed repository, or when the user explicitly asks for GitNexus. Do not activate merely because a repository is indexed or for routine local edits."
---

# GitNexus Code Intelligence

Use GitNexus as a selective decision aid, not as an unconditional gate. Keep routine work fast, and increase rigor when a change can affect callers, contracts, routes, schemas, cross-module behavior, concurrency, or security boundaries.

## References

- Read [references/mcp-tools.md](references/mcp-tools.md) when selecting an MCP tool, binding a repository, interpreting staleness, or checking risk semantics.
- Read [references/cli-commands.md](references/cli-commands.md) when a terminal command is needed, the MCP server is unavailable, or exact flags must be resolved.

## Choose the Lightest Safe Path

- **Fast path:** documentation, comments, non-executable text, an isolated leaf function, or a change whose callers cannot be affected. Read the source directly, make the scoped edit, and run only targeted checks. Do not query GitNexus or rebuild.
- **Standard path:** an executable symbol in one module. Use GitNexus when caller or dependency knowledge would change the edit; otherwise use normal source search. Run targeted tests or type checking for changed behavior.
- **High-risk path:** shared APIs, public symbols, cross-module or package changes, routes, schemas, dependency injection/configuration, concurrency, security, refactors, renames, or uncertain callers. Run impact analysis before editing and graph change analysis before committing.

Repository-specific instructions in `AGENTS.md`, CI configuration, and the user's explicit requirement take precedence. Treat GitNexus' generic build-current/index-current procedure as high-risk-path guidance, not as a requirement to compile before every edit.

## Use the MCP Narrowly

1. Call `list_repos` once per task when the target repository is uncertain. Pass `repo` explicitly when more than one repository is indexed.
2. Use the tool-selection table in [references/mcp-tools.md](references/mcp-tools.md). Prefer `query` for concepts, `context` for a named symbol, and `impact` for callers or blast radius.
3. Use `route_map`, `api_impact`, or `shape_check` for HTTP/API changes. Use `explain` or `pdg_query` only when security or control/data dependence justifies the extra depth.
4. Read `staleness.status` on graph results. Refresh with `gitnexus analyze --index-only` only when stale graph data is load-bearing for the current decision. Do not automatically reindex every repository or after every edit.
5. The MCP server is configured read-only. Do not expect `rename`, raw `cypher`, or group mutation tools. Perform edits through normal source editing or an appropriate refactoring tool.

When impact results are `HIGH` or `CRITICAL`, surface the affected callers before proceeding. Treat `UNKNOWN` as unresolved, not as low risk, and confirm it with source search or tests. Do not substitute a text search for graph analysis after choosing the high-risk path.

## Indexing Rule

Never run bare `gitnexus analyze`. In a repository-local checkout, always invoke one of:

```bash
gitnexus analyze --index-only
node .gitnexus/run.cjs analyze --index-only
```

`--index-only` prevents generation or updates to `AGENTS.md`, `CLAUDE.md`, `.claude/skills`, and `.agents/skills`. Do not pass `--skills`. If a project-local script or documented workflow invokes bare `gitnexus analyze`, do not use that path; run the equivalent `--index-only` command directly. If neither command can run, skip the index refresh rather than allowing generated agent files to be written.

## Verification and Builds

GitNexus indexing is not an application build. `analyze` updates the knowledge graph and must not be used as a substitute for compiling, type checking, or testing the product.

- Run targeted tests or targeted type checking when behavior changes.
- Do not run a full compile by default. A full build is justified only for a large, broad change that touches many files or modules and also crosses an integration boundary such as build configuration, package manifests, shared public contracts, or generated artifacts.
- If build output must be regenerated for a small change, run the smallest targeted build that covers the affected artifact rather than a repository-wide build.
- Run at most one full build per task, during final verification. Never rebuild after each edit.
- For refactors or cross-module changes, use `detect_changes` before the final commit when it is available.
- Do not compile after documentation-only, comment-only, isolated, or small single-module changes unless the repository's CI configuration or the user explicitly requires it.

If GitNexus is unavailable, the repository is not indexed, or the graph cannot answer the question, fall back to source search and the repository's tests. State that graph evidence was unavailable; do not block unrelated work.
