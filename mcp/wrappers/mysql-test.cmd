@echo off
REM ============================================================
REM mysql-test MCP wrapper  ->  ~/.mcp/mysql-test.cmd
REM install.ps1 renders __VAR__ placeholders from secrets.env.
REM NOTE: this wrapper enables write + DDL. Keep it on test only.
REM ============================================================
set "MYSQL_HOST=__MYSQL_TEST_HOST__"
set "MYSQL_PORT=3306"
set "MYSQL_USER=__MYSQL_USER__"
set "MYSQL_PASS=%MYSQL_TEST_PASS%"
set "MYSQL_DB=__MYSQL_DB__"
set "MYSQL_SSL=true"
set "MYSQL_TIMEZONE=+08:00"
set "ALLOW_DDL_OPERATION=true"
set "ALLOW_DELETE_OPERATION=true"
set "ALLOW_INSERT_OPERATION=true"
set "ALLOW_UPDATE_OPERATION=true"
"C:\Users\<USER>\AppData\Roaming\npm\mcp-server-mysql.cmd"
