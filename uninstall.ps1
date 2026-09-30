param([string]$ToolsDir = 'C:\dev\tools')
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'This uninstaller needs Windows. On macOS, remove the svg-to-png symlink.'
}

# Remove only this verb. Keep the shared submenu, even when it is empty.
$verb = 'HKCU:\Software\Classes\SystemFileAssociations\.svg\shell\MikesTools\shell\SvgToPng'
if (Test-Path -LiteralPath $verb) { Remove-Item -LiteralPath $verb -Recurse -Force }
foreach ($name in @('svg-to-png.bat', 'svg-to-png')) {
    $path = Join-Path $ToolsDir $name
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
}
$icon = Join-Path $env:LOCALAPPDATA 'svg-to-png\icons\svg-to-png.ico'
if (Test-Path -LiteralPath $icon) { Remove-Item -LiteralPath $icon -Force }
Write-Host 'Removed svg-to-png stubs, icon and Explorer verb. Kept the clone and shared menu.' -ForegroundColor Green
