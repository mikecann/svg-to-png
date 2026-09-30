# Agent guidance for svg-to-png

This is a Bun and TypeScript CLI. `svg-to-png.ts` renders an SVG to a PNG
beside the input, with the shortest dimension at least 2048px. It keeps larger
SVGs at their natural size. The `svg-to-png` shell launcher supports macOS;
`install.ps1` adds Windows command stubs and an Explorer context menu.

## Development rules

- Use test-first development for non-trivial changes. If there is no clean
  test seam, extract one first, then write a test before changing behaviour.
- When behaviour or a tested contract changes, update the affected tests and
  rerun them. Run `bun install`, then `bun test` before committing, and run
  the actual CLI against an SVG as a smoke test.
- Parse every `.ps1` with PowerShell's
  `[System.Management.Automation.Language.Parser]::ParseFile` after edits.
  Verify Windows installation and removal on Windows before claiming they work.
- Keep source in this clone. `C:\dev\tools` only gets generated stubs and
  large binaries, never source files. Never commit `.exe` or `.dll` files.
- Write generated `.bat` files with `-Encoding ASCII` and ASCII content.
- Keep the shared "Mike's Tools" submenu and other tools' verbs intact.
  `uninstall.ps1` must remove only this tool's stubs, icon and `SvgToPng` verb.
- `deps.ps1` must remain self-contained, idempotent and clear about errors.
  Check for Bun with `Get-Command`, run installation from `$PSScriptRoot`,
  check its exit code, and always restore the caller's location.
- Stubs point at live files in this clone, so ordinary source edits do not
  need reinstallation. Rerun the installer after moving the clone or changing
  installer integration.
- If a future dependency needs large Windows binaries, keep them in
  `C:\dev\tools` and accept `EXEDIR` rather than embedding a personal path.
- Keep docs plain and friendly. Do not use em dashes or en dashes.

## Local checks

```sh
bun install --frozen-lockfile
bun test
bash -n install.sh svg-to-png
```

```powershell
pwsh -NoProfile -File ./scripts/check-powershell.ps1
```

There was no tool-specific agent section for this CLI in the original guidance.
