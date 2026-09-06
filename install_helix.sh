#!/usr/bin/env bash
set -euo pipefail

API="https://api.github.com/repos/helix-editor/helix/releases/latest"
ASSET_PATTERN="helix-[^\"/]*-x86_64-linux.tar.xz"
TMPDIR="$(mktemp -d)"
TARBALL="$TMPDIR/helix.tar.xz"
DEST="$HOME/.local"
# hx searches for its runtime in this order:
#   $HELIX_RUNTIME, then <config dir>/helix/runtime, then <dir of hx>/runtime
# Installing beside the binary keeps the runtime version-matched to the hx it
# ships with, and leaves the config dir holding only hand-written config (so it
# can be a git repo you clone into without a non-empty-directory conflict).
RUNTIME_DEST="$DEST/bin/runtime"
LEGACY_RUNTIME="${XDG_CONFIG_HOME:-$HOME/.config}/helix/runtime"
COMPLETION_DEST="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"

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

# A runtime left over in the config dir wins over the one we just installed,
# which would silently pin hx to the grammars of whatever release put it there.
if [[ -d "$LEGACY_RUNTIME" ]]; then
  echo
  echo "WARNING: an older runtime exists at" >&2
  echo "  $LEGACY_RUNTIME" >&2
  echo "It takes precedence over $RUNTIME_DEST and will shadow it." >&2
  echo "If you have not added your own queries or themes in there, remove it:" >&2
  echo "  rm -rf '$LEGACY_RUNTIME'" >&2
  echo
fi

# Bash completion ships in the tarball under contrib/completion/. The file must
# be named after the command (`hx`) for bash-completion's on-demand loader to
# find it. Not fatal if a future release drops or moves it.
COMPLETION_SRC="$EXTRACTED_DIR/contrib/completion/hx.bash"
if [[ -f "$COMPLETION_SRC" ]]; then
  echo "Installing bash completion to $COMPLETION_DEST/hx..."
  mkdir -p "$COMPLETION_DEST"
  install -m 0644 "$COMPLETION_SRC" "$COMPLETION_DEST/hx"
else
  echo "Note: contrib/completion/hx.bash not in this release; skipping completion" >&2
fi

echo "Done. hx installed at $DEST/bin/hx, runtime at $RUNTIME_DEST"

# Sanity check
if ! command -v hx >/dev/null 2>&1; then
  echo
  echo "Note: $DEST/bin is not on your PATH. Add this to your shell rc:"
  echo '  export PATH="$HOME/.local/bin:$PATH"'
else
  echo "Version: $("$DEST/bin/hx" --version | head -n1)"
fi

if [[ -f "$COMPLETION_DEST/hx" ]]; then
  if [[ -r /usr/share/bash-completion/bash_completion ]]; then
    echo "Bash completion installed. Start a new shell to pick it up."
  else
    echo
    echo "Note: the bash-completion package is not installed, so the completion"
    echo "will not load. Install it, then start a new shell:"
    echo "  dnf install bash-completion   # or: apt install bash-completion"
  fi
fi
