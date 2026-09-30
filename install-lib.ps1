function Write-BatStub {
    param([string]$ToolName, [string]$Content, [string]$ToolsDir)
    Set-Content -LiteralPath (Join-Path $ToolsDir "$ToolName.bat") -Value $Content -Encoding ASCII

    # Git Bash can use the same Windows stub, so both shells run the live clone.
    $bashContent = @'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/__TOOL_NAME__.bat" "$@"
'@.Replace('__TOOL_NAME__', $ToolName)
    Set-Content -LiteralPath (Join-Path $ToolsDir $ToolName) -Value $bashContent -Encoding ASCII
}

# Embed raw PNG bytes in the ICO container to preserve alpha transparency.
function ConvertTo-Ico($pngPath, $icoPath) {
    $pngBytes = [System.IO.File]::ReadAllBytes($pngPath)
    $stream = [System.IO.FileStream]::new($icoPath, [System.IO.FileMode]::Create)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
        $writer.Write([byte]16); $writer.Write([byte]16); $writer.Write([byte]0)
        $writer.Write([byte]0); $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$pngBytes.Length); $writer.Write([uint32]22)
        $writer.Write($pngBytes)
    } finally {
        $writer.Dispose()
    }
}

function Set-MikesToolsRoot($rootKey, $icon) {
    # This menu is shared. Leave an existing root and all of its verbs alone.
    if (-not (Test-Path -LiteralPath $rootKey)) {
        New-Item -Path $rootKey -Force | Out-Null
        Set-ItemProperty -LiteralPath $rootKey -Name 'MUIVerb' -Value "Mike's Tools"
        Set-ItemProperty -LiteralPath $rootKey -Name 'SubCommands' -Value ''
        Set-ItemProperty -LiteralPath $rootKey -Name 'Icon' -Value $icon
    }
}

function Add-MikesVerb($rootKey, $verbName, $label, $icon, $command) {
    $verbKey = "$rootKey\shell\$verbName"
    $cmdKey = "$verbKey\command"
    New-Item -Path $verbKey -Force | Out-Null
    New-Item -Path $cmdKey -Force | Out-Null
    Set-ItemProperty -LiteralPath $verbKey -Name 'MUIVerb' -Value $label
    Set-ItemProperty -LiteralPath $verbKey -Name 'Icon' -Value $icon
    Set-ItemProperty -LiteralPath $cmdKey -Name '(Default)' -Value $command
}
