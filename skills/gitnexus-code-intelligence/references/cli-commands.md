# GitNexus Safety-First CLI Reference

The global GitNexus CLI is installed. Prefer MCP for read-only graph work; use CLI when MCP is unavailable or a command exists only in the terminal.

## Non-Negotiable Indexing Rule

Never run a one-shot bare `gitnexus analyze`. It can generate or update `AGENTS.md`, `CLAUDE.md`, and GitNexus skill files. Use:

```bash
gitnexus analyze --index-only
node .gitnexus/run.cjs analyze --index-only
```

When indexing a path other than the current working directory:

```bash
gitnexus analyze --index-only <path>
```

`--index-only` skips all AI-context file injection. Do not combine an index refresh with `--skills`, `--skip-agents-md`, or `--skip-skills`; `--index-only` is the stricter and preferred boundary.

### Index options

```bash
gitnexus analyze --index-only --force
gitnexus analyze --index-only --pdg
gitnexus analyze --index-only --embeddings
gitnexus analyze --index-only --branch <branch-name>
```

- Use `--force` only when a full graph rebuild is necessary.
- Use `--pdg` only when `explain` or `pdg_query` is needed.
- Use `--embeddings` only when semantic search is needed; it is slower and may download runtime assets.
- Use `--branch` only for a deliberate branch-pinned index.

### Continuous updates

`gitnexus analyze --watch` is the one safe watch form because watch refreshes update only the graph and skip generated agent files. Do not add `--index-only`; watch rejects it. Use watch only when the user explicitly wants a long-running local indexer.

Never use the ambiguous command `gitnexus watch`.

## Read and Status Commands

### Check what is indexed

```bash
gitnexus list
gitnexus status --json
gitnexus status --repo <name-or-path> --json
gitnexus doctor
```

`status --json` is preferred when the result must be parsed. `doctor` reports runtime and embedding capabilities without changing the index.

### Register an existing index

```bash
gitnexus index
gitnexus index <path>
```

This registers an existing `.gitnexus/` directory and does not re-analyze the repository. Use `--force` only for incomplete metadata; use `--allow-non-git` only when the user explicitly wants a non-Git folder registered.

## Query Commands

### Query concepts and flows

```bash
gitnexus query "<concept>" --repo <name>
gitnexus query "<concept>" --repo <name> --limit 5
gitnexus query "<concept>" --repo <name> --content
```

Use `--content` only when retained source text is needed; it increases output size.

### Inspect a symbol

```bash
gitnexus context <symbol> --repo <name>
gitnexus context <symbol> --repo <name> --file <path>
gitnexus context <symbol> --repo <name> --uid <uid>
```

Use `--file` or `--uid` to resolve ambiguity.

### Impact analysis

```bash
gitnexus impact <symbol> --direction upstream --repo <name>
gitnexus impact <symbol> --direction downstream --repo <name>
gitnexus impact <symbol> --direction upstream --repo <name> --depth 3 --include-tests
gitnexus impact <symbol> --direction upstream --repo <name> --summary-only
gitnexus impact <symbol> --direction upstream --repo <name> --mode pdg --line <n>
```

Use `upstream` to find dependants and `downstream` to find dependencies. Use `--summary-only` when only counts and risk are needed.

### Trace a call chain

```bash
gitnexus trace <from> <to> --repo <name>
gitnexus trace <from> <to> --repo <name> --depth 10
gitnexus trace <from> <to> --repo <name> --from-file <path> --to-file <path>
```

### Detect current diff impact

```bash
gitnexus detect-changes --scope unstaged --repo <name>
gitnexus detect-changes --scope staged --repo <name>
gitnexus detect-changes --scope all --repo <name>
gitnexus detect-changes --scope compare --base-ref main --repo <name>
```

Use `--repo .` only when the command is run from the intended checkout. For a linked worktree, run from that worktree or pass its path as `--repo`.

### Structural checks

```bash
gitnexus check --repo <name>
gitnexus check --cycles --json --repo <name>
```

`--cycles` is a failing check when cycles exist. Use `--json` when the result must be parsed.

## Repository Groups

Read-only group inspection:

```bash
gitnexus group list
gitnexus group list <group>
gitnexus group status <group>
gitnexus group impact <group> --target <symbol> --repo <member-path>
gitnexus group query <group> "<concept>"
gitnexus group contracts <group>
```

Mutation or synchronization commands require an explicit user request:

```bash
gitnexus group create <name>
gitnexus group add <group> <group-path> <registry-name>
gitnexus group remove <group> <path>
gitnexus group sync <group>
```

## Destructive or Global Commands

Do not run these unless the user explicitly asks for that exact operation:

- `gitnexus clean` or `gitnexus clean --all`
- `gitnexus remove <target>`
- `gitnexus uninstall`
- `gitnexus update`
- `gitnexus auto-sync`
- `gitnexus publish`
- `gitnexus setup`

Do not run `gitnexus cypher` from this skill. Raw Cypher is outside the configured read-only MCP surface; inspect the graph through the read-only tools instead.

`gitnexus wiki` is not part of routine code work. Run it only when the user explicitly asks for generated documentation; it may call an LLM, write files, and optionally publish a Gist.

## Long-Running Services

Do not start these as background helpers from this skill:

- `gitnexus mcp` — already managed by Codex configuration
- `gitnexus serve`
- `gitnexus eval-server`
- `gitnexus auto-sync`

Use `gitnexus <command> --help` to resolve flags for the installed version. The installed version is authoritative when this reference and the CLI help differ.
