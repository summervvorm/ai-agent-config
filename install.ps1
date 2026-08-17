# install.ps1 - One-shot install/switch AI agent configs (skills + MCP + plugins)
# Usage:
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Agent opencode
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Agent codex
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Agent claude
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Agent zed
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Agent all
#
# Requires: secrets.env next to this script (copy from .env.example and fill in).

param(
    [ValidateSet('opencode', 'codex', 'claude', 'zed', 'all')]
    [string]$Agent = 'all'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$HomeDir  = $env:USERPROFILE
$Stamp    = Get-Date -Format 'yyyyMMdd-HHmmss'
$Backup   = Join-Path $RepoRoot 'backups'
$SkillsSrc = Join-Path $RepoRoot 'skills'

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
    # leftover placeholders -> fail loudly
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

# ---------- main ----------
$secrets = Read-Secrets
Write-Host "== AI Agent Config Installer ==" -ForegroundColor Cyan
Write-Host "Repo: $RepoRoot"

$targets = if ($Agent -eq 'all') { @('opencode', 'codex', 'claude', 'zed') } else { @($Agent) }

foreach ($ag in $targets) {
    Write-Host "`n### [$ag] ###" -ForegroundColor Yellow
    switch ($ag) {
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