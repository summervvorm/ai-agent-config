@echo off
REM ============================================================
REM Obsidian MCP wrapper  ->  ~/.mcp/mcp-obsidian.cmd
REM The API key is injected from the OBSIDIAN_API_KEY env var,
REM never hardcoded here.
REM ============================================================
set "MCP_LOG_LEVEL=warn"
set "MCP_TRANSPORT_TYPE=stdio"
set "OBSIDIAN_BASE_URL=https://127.0.0.1:27124"
set "OBSIDIAN_VERIFY_SSL=false"
"C:\Users\<USER>\AppData\Roaming\npm\obsidian-mcp-server.cmd"
