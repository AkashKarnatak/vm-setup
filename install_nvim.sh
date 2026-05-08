#!/usr/bin/env bash
set -euo pipefail

URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
TMPDIR="$(mktemp -d)"
TARBALL="$TMPDIR/nvim.tar.gz"
DEST="$HOME/.local"

trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading nvim nightly..."
curl -L --fail --progress-bar -o "$TARBALL" "$URL"

echo "Extracting..."
tar -xzf "$TARBALL" -C "$TMPDIR"

# The tarball extracts to a directory like nvim-linux-x86_64/
EXTRACTED_DIR="$(find "$TMPDIR" -maxdepth 1 -type d -name 'nvim-linux*' | head -n1)"

if [[ -z "$EXTRACTED_DIR" ]]; then
  echo "Could not find extracted nvim directory" >&2
  exit 1
fi

echo "Installing to $DEST..."
mkdir -p "$DEST/bin" "$DEST/lib" "$DEST/share"

# Copy contents into ~/.local, merging with existing structure
cp -r "$EXTRACTED_DIR/bin/." "$DEST/bin/"
cp -r "$EXTRACTED_DIR/lib/." "$DEST/lib/"
cp -r "$EXTRACTED_DIR/share/." "$DEST/share/"

echo "Done. nvim installed at $DEST/bin/nvim"

# Sanity check
if ! command -v nvim >/dev/null 2>&1; then
  echo
  echo "Note: $DEST/bin is not on your PATH. Add this to your shell rc:"
  echo '  export PATH="$HOME/.local/bin:$PATH"'
else
  echo "Version: $(nvim --version | head -n1)"
fi
