# File helpers run on any platform. Registry checks use an isolated key on Windows.
$ErrorActionPreference = 'Stop'
$repoDir = Split-Path -Parent $PSScriptRoot
. (Join-Path $repoDir 'install-lib.ps1')
function Assert($condition, $message) {
    if (-not $condition) { throw $message }
}
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "svg-to-png helpers $([guid]::NewGuid())"
$registryRoot = "HKCU:\Software\svg-to-png-tests-$([guid]::NewGuid())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
try {
    $content = "@echo off`r`nbun run `"C:\clone with spaces\svg-to-png.ts`" %*"
    Write-BatStub 'svg-to-png' $content $tempDir
    $batPath = Join-Path $tempDir 'svg-to-png.bat'
    Assert (([IO.File]::ReadAllText($batPath).TrimEnd()) -eq $content) 'Batch stub changed its command.'
    Assert (@([IO.File]::ReadAllBytes($batPath) | Where-Object { $_ -gt 127 }).Count -eq 0) 'Batch stub is not ASCII.'
    $bash = [IO.File]::ReadAllText((Join-Path $tempDir 'svg-to-png'))
    Assert ($bash.Contains('exec "$SCRIPT_DIR/svg-to-png.bat" "$@"')) 'Git Bash argument forwarding is missing.'

    $png = Join-Path $repoDir 'icons/svg-to-png.png'
    $ico = Join-Path $tempDir 'svg-to-png.ico'
    ConvertTo-Ico $png $ico
    $bytes = [IO.File]::ReadAllBytes($ico)
    Assert ([BitConverter]::ToUInt16($bytes, 2) -eq 1) 'ICO type is incorrect.'
    Assert ([BitConverter]::ToUInt32($bytes, 18) -eq 22) 'ICO PNG offset is incorrect.'
    Assert ([Convert]::ToBase64String($bytes[22..($bytes.Length - 1)]) -eq [Convert]::ToBase64String([IO.File]::ReadAllBytes($png))) 'Icon conversion changed the PNG.'
    Write-Host 'Passed batch, Git Bash and icon checks.'

    # Simulate a failed native command without network access or changing dependencies.
    function bun { $global:LASTEXITCODE = 7 }
    $callerLocation = (Get-Location).Path
    $caughtFailure = $false
    try {
        & (Join-Path $repoDir 'deps.ps1')
    } catch {
        $caughtFailure = $_.Exception.Message -match 'bun install failed with exit code 7'
    } finally {
        Remove-Item Function:\bun
        $global:LASTEXITCODE = 0
    }
    Assert $caughtFailure 'Dependency failure was not propagated.'
    Assert ((Get-Location).Path -eq $callerLocation) 'Dependency failure changed the caller location.'
    Write-Host 'Passed dependency failure and location restoration checks.'

    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
        Set-MikesToolsRoot $registryRoot 'existing.ico'
        New-Item -Path "$registryRoot\shell\OtherTool" -Force | Out-Null
        Set-MikesToolsRoot $registryRoot 'replacement.ico'
        Assert ((Get-ItemProperty -LiteralPath $registryRoot).Icon -eq 'existing.ico') 'Shared root icon changed.'
        $command = 'cmd.exe /k ""C:\tools with spaces\svg-to-png.bat" "%1""'
        for ($i = 0; $i -lt 2; $i++) {
            Add-MikesVerb $registryRoot 'SvgToPng' 'Render to PNG (2048px min)' 'svg.ico' $command
        }
        Assert (Test-Path -LiteralPath "$registryRoot\shell\OtherTool") 'Another tool was removed.'
        $actual = (Get-Item -LiteralPath "$registryRoot\shell\SvgToPng\command").GetValue('')
        Assert ($actual -eq $command) 'Explorer command quoting changed.'
        Write-Host 'Passed isolated registry and idempotence checks.'
    } else {
        Write-Host 'Skipped Windows registry checks on this platform.'
    }
} finally {
    Remove-Item -LiteralPath $tempDir -Recurse -Force
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT -and (Test-Path -LiteralPath $registryRoot)) {
        Remove-Item -LiteralPath $registryRoot -Recurse -Force
    }
}
