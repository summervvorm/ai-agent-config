# install.ps1 - One-shot install/switch AI agent configs (skills + MCP + wrappers + env)
# Usage:
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Agent dsh
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Agent opencode
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Agent codex
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Agent claude
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Agent zed
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Agent all
#
# Requires: secrets.env next to this script (copy from .env.example and fill in).
#
# Templates use three placeholder styles:
#   __VAR__   -> substituted from secrets.env
#   <USER>    -> substituted with the current Windows username
#   {env:VAR} -> left as-is; opencode resolves it natively at startup

param(
    [ValidateSet('dsh', 'opencode', 'codex', 'claude', 'zed', 'all')]
    [string]$Agent = 'all'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$HomeDir  = $env:USERPROFILE
$Stamp    = Get-Date -Format 'yyyyMMdd-HHmmss'
$Backup   = Join-Path $RepoRoot 'backups'
$SkillsSrc = Join-Path $RepoRoot 'skills'

# Secrets that must exist in the *process* environment for the MCP wrappers,
# opencode and DSH to authenticate at runtime.
$RuntimeEnvKeys = @(
    'MYSQL_PASS',
    'MYSQL_DEV_PASS',
    'MYSQL_TEST_PASS',
    'OBSIDIAN_API_KEY',
    'GITHUB_MCP_TOKEN',
    'B_AI_API_KEY',
    'COMMANDCODE_API_KEY',
    'JUSTWORK_API_KEY',
    'MIMO_API_KEY',
    'SENSENOVA_API_KEY'
)

# ---------- helpers ----------
function Read-Secrets {
    $secretsFile = Join-Path $RepoRoot 'secrets.env'
    if (-not (Test-Path $secretsFile)) {
        Write-Host "[ERROR] $secretsFile not found. Copy .env.example to secrets.env and fill in values." -ForegroundColor Red
        Write-Host "        Copy-Item (Join-Path $RepoRoot '.env.example') $secretsFile"
        exit 1
    }
    $secrets = @{}
    Get-Content $secretsFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
            $idx = $line.IndexOf('=')
            $key = $line.Substring(0, $idx).Trim()
            $val = $line.Substring($idx + 1).Trim().Trim('"')
            $secrets[$key] = $val
        }
    }
    return $secrets
}

function Render-Template([string]$templatePath, [hashtable]$secrets) {
    $content = Get-Content $templatePath -Raw -Encoding UTF8
    foreach ($key in $secrets.Keys) {
        $content = $content.Replace("__$key`__", $secrets[$key])
    }
    # <USER> is a literal placeholder, not a secrets.env key
    $content = $content.Replace('<USER>', $env:USERNAME)
    # leftover __VAR__ placeholders -> fail loudly
    if ($content -match '__[A-Z_]+__') {
        Write-Host "[ERROR] Unresolved placeholders in $templatePath : $($Matches[0])" -ForegroundColor Red
        exit 1
    }
    return $content
}

function Backup-File([string]$path) {
    if (Test-Path $path) {
        $bakDir = Join-Path $Backup $Stamp
        New-Item -ItemType Directory -Force -Path $bakDir | Out-Null
        Copy-Item $path (Join-Path $bakDir (Split-Path $path -Leaf)) -Force
        Write-Host "  backup -> $bakDir\$(Split-Path $path -Leaf)" -ForegroundColor DarkGray
    }
}

function Sync-Skills([string]$destRoot) {
    if (-not (Test-Path $destRoot)) { New-Item -ItemType Directory -Force -Path $destRoot | Out-Null }
    Get-ChildItem $SkillsSrc -Directory | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $destRoot $_.Name) -Recurse -Force
    }
    Write-Host "  skills: $((Get-ChildItem $destRoot -Directory).Count) installed -> $destRoot"
}

# Renders mcp/wrappers/*.cmd into ~/.mcp/ (referenced by Claude / Codex / DSH / Zed).
function Sync-Wrappers([hashtable]$secrets) {
    $src = Join-Path $RepoRoot 'mcp\wrappers'
    $dst = Join-Path $HomeDir '.mcp'
    if (-not (Test-Path $src)) { return }
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Get-ChildItem $src -Filter *.cmd | ForEach-Object {
        Backup-File (Join-Path $dst $_.Name)
        $content = Render-Template $_.FullName $secrets
        [System.IO.File]::WriteAllText((Join-Path $dst $_.Name), $content, [System.Text.UTF8Encoding]::new($false))
    }
    Write-Host "  wrappers: $((Get-ChildItem $src -Filter *.cmd).Count) rendered -> $dst"
}

# Persists runtime secrets to the user-level environment so every agent
# inherits them without hardcoding credentials in any config file.
function Set-UserEnvVars([hashtable]$secrets) {
    $set = 0
    foreach ($k in $RuntimeEnvKeys) {
        if ($secrets.ContainsKey($k)) {
            [Environment]::SetEnvironmentVariable($k, $secrets[$k], 'User')
            Set-Item -Path "Env:$k" -Value $secrets[$k]
            $set++
        }
    }
    Write-Host "  env: $set/$($RuntimeEnvKeys.Count) runtime secrets written to user environment" -ForegroundColor DarkGray
    if ($set -lt $RuntimeEnvKeys.Count) {
        $missing = $RuntimeEnvKeys | Where-Object { -not $secrets.ContainsKey($_) }
        Write-Host "  env: not provided (skipped): $($missing -join ', ')" -ForegroundColor DarkYellow
    }
}

# ---------- main ----------
$secrets = Read-Secrets
Write-Host "== AI Agent Config Installer ==" -ForegroundColor Cyan
Write-Host "Repo: $RepoRoot"

$targets = if ($Agent -eq 'all') { @('dsh', 'opencode', 'codex', 'claude', 'zed') } else { @($Agent) }

# Wrappers + env are shared by every target, so do them once up front.
Write-Host "`n### [shared] wrappers + environment ###" -ForegroundColor Yellow
Sync-Wrappers $secrets
Set-UserEnvVars $secrets

foreach ($ag in $targets) {
    Write-Host "`n### [$ag] ###" -ForegroundColor Yellow
    switch ($ag) {
        'dsh' {
            $cfgDir = Join-Path $HomeDir '.dsh\profiles\desktop'
            New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
            $content = Render-Template (Join-Path $RepoRoot 'mcp\templates\dsh-cordis-patch.fragment.yml') $secrets
            $out = Join-Path $cfgDir 'mcp.generated.yml'
            [System.IO.File]::WriteAllText($out, $content, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  fragment -> $out"
            Sync-Skills (Join-Path $HomeDir '.agents\skills')
            Write-Host "  NOTE: merge this fragment's 'insert:' list into cordis.patch.yml manually." -ForegroundColor Yellow
            Write-Host "        Do NOT overwrite cordis.patch.yml - it also holds model/UI plugin config." -ForegroundColor Yellow
        }
        'opencode' {
            $cfgDir = Join-Path $HomeDir '.config\opencode'
            New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
            Backup-File (Join-Path $cfgDir 'opencode.json')
            $content = Render-Template (Join-Path $RepoRoot 'mcp\templates\opencode.json') $secrets
            [System.IO.File]::WriteAllText((Join-Path $cfgDir 'opencode.json'), $content, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  config -> $cfgDir\opencode.json"
            Sync-Skills (Join-Path $HomeDir '.agents\skills')
            Write-Host "  plugins: npm plugins install automatically on startup (see plugins\opencode-plugins.json)" -ForegroundColor DarkGray
        }
        'codex' {
            $cfgDir = Join-Path $HomeDir '.codex'
            New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
            Backup-File (Join-Path $cfgDir 'config.toml')
            $content = Render-Template (Join-Path $RepoRoot 'mcp\templates\codex-config.toml') $secrets
            [System.IO.File]::WriteAllText((Join-Path $cfgDir 'config.toml'), $content, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  config -> $cfgDir\config.toml"
            Sync-Skills (Join-Path $cfgDir 'skills')
        }
        'claude' {
            $cfgDir = Join-Path $HomeDir '.claude'
            New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
            Backup-File (Join-Path $cfgDir 'mcp.json')
            $content = Render-Template (Join-Path $RepoRoot 'mcp\templates\claude-mcp.json') $secrets
            [System.IO.File]::WriteAllText((Join-Path $cfgDir 'mcp.json'), $content, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  config -> $cfgDir\mcp.json"
            Sync-Skills (Join-Path $cfgDir 'skills')
        }
        'zed' {
            $cfgDir = Join-Path $HomeDir '.config\zed'
            New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
            $content = Render-Template (Join-Path $RepoRoot 'mcp\templates\zed-settings.fragment.json') $secrets
            $out = Join-Path $cfgDir 'mcp.generated.json'
            [System.IO.File]::WriteAllText($out, $content, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  fragment -> $out"
            Write-Host "  NOTE: merge 'mcp' array into settings.json manually (Zed has no include mechanism)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n== Done. Restart your agent to pick up the changes. ==" -ForegroundColor Green
