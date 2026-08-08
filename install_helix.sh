#!/usr/bin/env bash
set -euo pipefail

API="https://api.github.com/repos/helix-editor/helix/releases/latest"
ASSET_PATTERN="helix-[^\"/]*-x86_64-linux.tar.xz"
TMPDIR="$(mktemp -d)"
TARBALL="$TMPDIR/helix.tar.xz"
DEST="$HOME/.local"
RUNTIME_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/helix/runtime"

trap 'rm -rf "$TMPDIR"' EXIT

echo "Looking up latest helix release..."
URL="$(curl -sL --fail "$API" \
  | grep -oE "https://[^\"]*${ASSET_PATTERN}" \
  | head -n1)"

if [[ -z "$URL" ]]; then
  echo "Could not find a x86_64-linux asset in the latest release" >&2
  exit 1
fi

echo "Downloading $(basename "$URL")..."
curl -L --fail --progress-bar -o "$TARBALL" "$URL"

echo "Extracting..."
tar -xJf "$TARBALL" -C "$TMPDIR"

# The tarball extracts to a directory like helix-25.07.1-x86_64-linux/
# containing the `hx` binary and a `runtime/` directory
EXTRACTED_DIR="$(find "$TMPDIR" -maxdepth 1 -type d -name 'helix-*-x86_64-linux' | head -n1)"

if [[ -z "$EXTRACTED_DIR" ]]; then
  echo "Could not find extracted helix directory" >&2
  exit 1
fi

if [[ ! -f "$EXTRACTED_DIR/hx" || ! -d "$EXTRACTED_DIR/runtime" ]]; then
  echo "Extracted archive is missing hx and/or runtime/" >&2
  exit 1
fi

echo "Installing to $DEST..."
mkdir -p "$DEST/bin"
install -m 0755 "$EXTRACTED_DIR/hx" "$DEST/bin/hx"

# hx needs its runtime files (grammars, queries, themes); replace wholesale so
# stale files from an older release don't linger
echo "Installing runtime to $RUNTIME_DEST..."
mkdir -p "$(dirname "$RUNTIME_DEST")"
rm -rf "$RUNTIME_DEST"
cp -r "$EXTRACTED_DIR/runtime" "$RUNTIME_DEST"

echo "Done. hx installed at $DEST/bin/hx"

# Sanity check
if ! command -v hx >/dev/null 2>&1; then
  echo
  echo "Note: $DEST/bin is not on your PATH. Add this to your shell rc:"
  echo '  export PATH="$HOME/.local/bin:$PATH"'
else
  echo "Version: $("$DEST/bin/hx" --version | head -n1)"
fi
