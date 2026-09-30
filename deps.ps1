$ErrorActionPreference = 'Stop'
$toolDir = $PSScriptRoot

if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    Write-Host "  [svg-to-png] ERROR: bun is not installed. Install from https://bun.sh" -ForegroundColor Red
    throw 'Bun is required.'
}

Write-Host "  [svg-to-png] Installing npm dependencies..." -ForegroundColor Cyan
Push-Location $toolDir
try {
    bun install --frozen-lockfile
    if ($LASTEXITCODE -ne 0) { throw "bun install failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}
Write-Host "  [svg-to-png] Dependencies ready." -ForegroundColor Green
