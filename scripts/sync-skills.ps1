# sync-skills.ps1 - Re-sync skills from repo to all installed agents
# Usage: powershell -ExecutionPolicy Bypass -File scripts\sync-skills.ps1 [-Agent dsh|opencode|codex|claude|all]

param(
    [ValidateSet('dsh', 'opencode', 'codex', 'claude', 'all')]
    [string]$Agent = 'all'
)

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$SkillsSrc = Join-Path $RepoRoot 'skills'
$HomeDir = $env:USERPROFILE

if (-not (Test-Path $SkillsSrc)) { Write-Host "[ERROR] skills dir missing: $SkillsSrc" -ForegroundColor Red; exit 1 }

$targets = if ($Agent -eq 'all') { @('dsh', 'opencode', 'codex', 'claude') } else { @($Agent) }

foreach ($ag in $targets) {
    $dest = switch ($ag) {
        'dsh'      { Join-Path $HomeDir '.agents\skills' }
        'opencode' { Join-Path $HomeDir '.agents\skills' }
        'codex'    { Join-Path $HomeDir '.codex\skills' }
        'claude'   { Join-Path $HomeDir '.claude\skills' }
    }
    if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
    Get-ChildItem $SkillsSrc -Directory | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $dest $_.Name) -Recurse -Force
    }
    Write-Host "[$ag] $((Get-ChildItem $dest -Directory).Count) skills -> $dest" -ForegroundColor Green
}
