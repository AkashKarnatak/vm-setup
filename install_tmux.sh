#!/usr/bin/env bash
set -euo pipefail

API="https://api.github.com/repos/tmux/tmux-builds/releases/latest"
ASSET_PATTERN="tmux-.*-linux-x86_64.tar.gz"
TMPDIR="$(mktemp -d)"
TARBALL="$TMPDIR/tmux.tar.gz"
DEST="$HOME/.local"

trap 'rm -rf "$TMPDIR"' EXIT

echo "Looking up latest tmux build..."
URL="$(curl -sL --fail "$API" \
  | grep -oE "https://[^\"]*${ASSET_PATTERN}" \
  | head -n1)"

if [[ -z "$URL" ]]; then
  echo "Could not find a linux-x86_64 asset in the latest release" >&2
  exit 1
fi

echo "Downloading $(basename "$URL")..."
curl -L --fail --progress-bar -o "$TARBALL" "$URL"

echo "Extracting..."
tar -xzf "$TARBALL" -C "$TMPDIR"

# The tarball contains a single static `tmux` binary at the root
BIN="$(find "$TMPDIR" -maxdepth 1 -type f -name 'tmux' | head -n1)"

if [[ -z "$BIN" ]]; then
  echo "Could not find tmux binary in extracted archive" >&2
  exit 1
fi

echo "Installing to $DEST..."
mkdir -p "$DEST/bin"
install -m 0755 "$BIN" "$DEST/bin/tmux"

echo "Done. tmux installed at $DEST/bin/tmux"

# Sanity check
if ! command -v tmux >/dev/null 2>&1; then
  echo
  echo "Note: $DEST/bin is not on your PATH. Add this to your shell rc:"
  echo '  export PATH="$HOME/.local/bin:$PATH"'
else
  echo "Version: $("$DEST/bin/tmux" -V)"
fi
