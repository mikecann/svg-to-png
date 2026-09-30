#!/usr/bin/env bash
# Run again after moving the clone so the symlink points at its new location.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/bin"
SKIP_DEPS=0
for arg in "$@"; do
  case "$arg" in
    --skip-deps) SKIP_DEPS=1 ;;
    -h|--help)
      echo "Usage: install.sh [target_bin_dir] [--skip-deps]"
      exit 0 ;;
    -*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *) TARGET_DIR="$arg" ;;
  esac
done
if ! command -v bun >/dev/null 2>&1; then
  echo "Bun is required. Install it from https://bun.sh" >&2
  exit 1
fi
if [[ "$SKIP_DEPS" -eq 0 ]]; then
  (cd "$REPO_DIR" && bun install --frozen-lockfile)
fi
mkdir -p "$TARGET_DIR"
chmod +x "$REPO_DIR/svg-to-png"
ln -sfn "$REPO_DIR/svg-to-png" "$TARGET_DIR/svg-to-png"
echo "Installed $TARGET_DIR/svg-to-png -> $REPO_DIR/svg-to-png"
case ":$PATH:" in
  *":$TARGET_DIR:"*) ;;
  *) echo "Add to ~/.zshrc or ~/.bashrc: export PATH=\"$TARGET_DIR:\$PATH\"" ;;
esac
