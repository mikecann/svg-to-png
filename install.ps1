param(
    [switch]$SkipDeps,
    [string]$ToolsDir = 'C:\dev\tools'
)
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'Use install.sh on macOS. This installer needs Windows.'
}
. (Join-Path $PSScriptRoot 'install-lib.ps1')

# ASCII batch files cannot safely reference a clone path containing Unicode.
if ($PSScriptRoot -match '[^\x00-\x7F]') {
    throw 'Clone into a path with ASCII characters so the Windows batch stub can reference it.'
}
if (-not $SkipDeps) { & (Join-Path $PSScriptRoot 'deps.ps1') }
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
$ToolsDir = (Resolve-Path -LiteralPath $ToolsDir).Path
$scriptPath = (Join-Path $PSScriptRoot 'svg-to-png.ts').Replace('%', '%%')
Write-BatStub 'svg-to-png' @"
@echo off
bun run "$scriptPath" %*
"@ $ToolsDir

$iconsDir = Join-Path $env:LOCALAPPDATA 'svg-to-png\icons'
New-Item -ItemType Directory -Path $iconsDir -Force | Out-Null
$svgIcon = Join-Path $iconsDir 'svg-to-png.ico'
ConvertTo-Ico (Join-Path $PSScriptRoot 'icons\svg-to-png.png') $svgIcon
$svgRoot = 'HKCU:\Software\Classes\SystemFileAssociations\.svg\shell\MikesTools'
# A system icon keeps the shared root independent of any one tool's uninstall.
Set-MikesToolsRoot $svgRoot "$env:SystemRoot\System32\shell32.dll,316"
$stubPath = Join-Path $ToolsDir 'svg-to-png.bat'
Add-MikesVerb $svgRoot 'SvgToPng' 'Render to PNG (2048px min)' $svgIcon "cmd.exe /k `"`"$stubPath`" `"%1`"`""

Write-Host "Installed svg-to-png into $ToolsDir" -ForegroundColor Green
if (-not (($env:PATH -split ';') | Where-Object { $_.TrimEnd('\') -ieq $ToolsDir.TrimEnd('\') })) {
    Write-Host "Add $ToolsDir to your user PATH, then open a new terminal." -ForegroundColor Yellow
}
