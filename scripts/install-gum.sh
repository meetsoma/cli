#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# install-gum.sh — download gum binary for soma TUI support
# ═══════════════════════════════════════════════════════════════════════════
#
# Called by postinstall. Downloads the correct gum binary for the current
# platform into the package's bin/ directory. Falls back gracefully —
# soma works without gum, it just looks better with it.
#
# Usage: bash install-gum.sh [--force]
#
# Env:
#   SOMA_SKIP_GUM=1    Skip gum installation entirely
#   GUM_VERSION         Override version (default: 0.17.0)

set -euo pipefail

GUM_VERSION="${GUM_VERSION:-0.17.0}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$PKG_DIR/bin"
GUM_BIN="$BIN_DIR/gum"

# ─── Skip checks ──────────────────────────────────────────────────────────

if [ "${SOMA_SKIP_GUM:-0}" = "1" ]; then
  echo "  ℹ Skipping gum install (SOMA_SKIP_GUM=1)"
  exit 0
fi

# Already installed and not forcing
if [ -x "$GUM_BIN" ] && [ "${1:-}" != "--force" ]; then
  existing=$("$GUM_BIN" --version 2>/dev/null | grep -o '[0-9]*\.[0-9]*\.[0-9]*' || echo "unknown")
  echo "  ✓ gum $existing already installed"
  exit 0
fi

# Check if system gum exists
if command -v gum >/dev/null 2>&1 && [ "${1:-}" != "--force" ]; then
  sys_version=$(gum --version 2>/dev/null | grep -o '[0-9]*\.[0-9]*\.[0-9]*' || echo "unknown")
  echo "  ✓ System gum $sys_version found, skipping bundled install"
  # Symlink to system gum for consistent path
  mkdir -p "$BIN_DIR"
  ln -sf "$(command -v gum)" "$GUM_BIN" 2>/dev/null || true
  exit 0
fi

# ─── Detect platform ──────────────────────────────────────────────────────

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Darwin) PLATFORM="Darwin" ;;
  Linux)  PLATFORM="Linux" ;;
  MINGW*|MSYS*|CYGWIN*) 
    echo "  ⚠ Windows detected — install gum manually: scoop install gum"
    exit 0
    ;;
  *)
    echo "  ⚠ Unsupported OS: $OS — gum TUI features will be unavailable"
    exit 0
    ;;
esac

case "$ARCH" in
  x86_64|amd64) MACHINE="x86_64" ;;
  arm64|aarch64) MACHINE="arm64" ;;
  armv7*)        MACHINE="armv7" ;;
  armv6*)        MACHINE="armv6" ;;
  *)
    echo "  ⚠ Unsupported architecture: $ARCH — gum TUI features will be unavailable"
    exit 0
    ;;
esac

# ─── Download ──────────────────────────────────────────────────────────────

FILENAME="gum_${GUM_VERSION}_${PLATFORM}_${MACHINE}.tar.gz"
URL="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/${FILENAME}"
TMP_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "  ↓ Downloading gum v${GUM_VERSION} for ${PLATFORM}/${MACHINE}..."

# Try curl first, then wget
if command -v curl >/dev/null 2>&1; then
  HTTP_CODE=$(curl -fsSL -o "$TMP_DIR/$FILENAME" -w "%{http_code}" "$URL" 2>/dev/null) || true
  if [ "$HTTP_CODE" != "200" ] && [ ! -s "$TMP_DIR/$FILENAME" ]; then
    echo "  ⚠ Download failed (HTTP $HTTP_CODE) — gum TUI features will be unavailable"
    echo "    Install manually: brew install gum"
    exit 0
  fi
elif command -v wget >/dev/null 2>&1; then
  wget -q -O "$TMP_DIR/$FILENAME" "$URL" 2>/dev/null || {
    echo "  ⚠ Download failed — gum TUI features will be unavailable"
    echo "    Install manually: brew install gum"
    exit 0
  }
else
  echo "  ⚠ Neither curl nor wget found — install gum manually: brew install gum"
  exit 0
fi

# ─── Extract ───────────────────────────────────────────────────────────────

echo "  ⊙ Extracting..."
tar -xzf "$TMP_DIR/$FILENAME" -C "$TMP_DIR" 2>/dev/null || {
  echo "  ⚠ Extraction failed — gum TUI features will be unavailable"
  exit 0
}

# Find the gum binary in extracted files
GUM_EXTRACTED=$(find "$TMP_DIR" -name "gum" -type f -perm +111 2>/dev/null | head -1)
if [ -z "$GUM_EXTRACTED" ]; then
  GUM_EXTRACTED=$(find "$TMP_DIR" -name "gum" -type f 2>/dev/null | head -1)
fi

if [ -z "$GUM_EXTRACTED" ]; then
  echo "  ⚠ gum binary not found in archive — TUI features will be unavailable"
  exit 0
fi

# ─── Install ───────────────────────────────────────────────────────────────

mkdir -p "$BIN_DIR"
rm -f "$GUM_BIN"
cp "$GUM_EXTRACTED" "$GUM_BIN"
chmod +x "$GUM_BIN"

# Verify
if "$GUM_BIN" --version >/dev/null 2>&1; then
  installed_version=$("$GUM_BIN" --version | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
  echo "  ✓ gum v${installed_version} installed to $GUM_BIN"
else
  echo "  ⚠ gum installed but verification failed"
fi
