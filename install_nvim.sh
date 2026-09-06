#!/usr/bin/env bash
set -euo pipefail

URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
TMPDIR="$(mktemp -d)"
TARBALL="$TMPDIR/nvim.tar.gz"
DEST="$HOME/.local"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
# init.lua lives next to this script in the repo; when the script is piped
# through bash (curl ... | bash) there is no script dir, so fall back to fetching
# it from GitHub like configure.sh does for the other dotfiles.
CONFIG_SRC="$(dirname "${BASH_SOURCE[0]:-}")/init.lua"
CONFIG_URL="https://raw.githubusercontent.com/AkashKarnatak/vm-setup/main/init.lua"

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

# Back up any existing config the same way configure.sh does for other dotfiles
mkdir -p "$CONFIG_DIR"
if [[ -f "$CONFIG_DIR/init.lua" ]]; then
  BACKUP="$CONFIG_DIR/init.lua.bak.$(date +%s)"
  echo "Backing up existing config to $BACKUP..."
  mv "$CONFIG_DIR/init.lua" "$BACKUP"
fi

echo "Installing config to $CONFIG_DIR/init.lua..."
if [[ -f "$CONFIG_SRC" ]]; then
  install -m 0644 "$CONFIG_SRC" "$CONFIG_DIR/init.lua"
else
  curl -sL --fail -o "$CONFIG_DIR/init.lua" "$CONFIG_URL"
fi

echo "Done. nvim installed at $DEST/bin/nvim, config at $CONFIG_DIR/init.lua"

# Sanity check
if ! command -v nvim >/dev/null 2>&1; then
  echo
  echo "Note: $DEST/bin is not on your PATH. Add this to your shell rc:"
  echo '  export PATH="$HOME/.local/bin:$PATH"'
else
  echo "Version: $(nvim --version | head -n1)"
fi
