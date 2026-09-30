$ErrorActionPreference = 'Stop'
$repoDir = Split-Path -Parent $PSScriptRoot
$failed = $false
Get-ChildItem -LiteralPath $repoDir -Filter '*.ps1' -Recurse |
    Where-Object { $_.FullName -notmatch '[\\/]node_modules[\\/]' } |
    ForEach-Object {
        $tokens = $null
        $parseErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile(
            $_.FullName, [ref]$tokens, [ref]$parseErrors)
        if ($parseErrors.Count -gt 0) {
            $failed = $true
            $parseErrors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        } else {
            Write-Host "Parsed $($_.Name)"
        }
    }
if ($failed) { exit 1 }
