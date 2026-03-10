#!/usr/bin/env bash
# Sync runtime files from agent repo before publish.
# Agent is source of truth. CLI is distribution only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLI_DIR="$(dirname "$SCRIPT_DIR")"
AGENT_DIR="${AGENT_DIR:-$(dirname "$CLI_DIR")/agent}"

if [ ! -d "$AGENT_DIR/core" ]; then
  echo "ERROR: Agent repo not found at $AGENT_DIR"
  echo "Set AGENT_DIR env var or ensure ../agent/ exists"
  exit 1
fi

echo "Syncing from $AGENT_DIR → $CLI_DIR"

# Core modules
mkdir -p "$CLI_DIR/core"
cp "$AGENT_DIR/core/"*.ts "$CLI_DIR/core/"
echo "  ✓ core/ ($(ls "$CLI_DIR/core/" | wc -l | tr -d ' ') files)"

# Extensions
mkdir -p "$CLI_DIR/extensions"
cp "$AGENT_DIR/extensions/"*.ts "$CLI_DIR/extensions/"
echo "  ✓ extensions/ ($(ls "$CLI_DIR/extensions/" | wc -l | tr -d ' ') files)"

# .soma protocols + templates
cp -R "$AGENT_DIR/.soma/protocols/" "$CLI_DIR/.soma/protocols/"
cp -R "$AGENT_DIR/.soma/templates/" "$CLI_DIR/.soma/templates/"
echo "  ✓ .soma/ (protocols + templates)"

echo "Done. Ready to publish."
