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

# Prompts (system-core.md etc.)
mkdir -p "$CLI_DIR/prompts"
cp "$AGENT_DIR/prompts/"*.md "$CLI_DIR/prompts/"
echo "  ✓ prompts/ ($(ls "$CLI_DIR/prompts/" | wc -l | tr -d ' ') files)"

# .soma protocols + templates
cp -R "$AGENT_DIR/.soma/protocols/" "$CLI_DIR/.soma/protocols/"
cp -R "$AGENT_DIR/.soma/templates/" "$CLI_DIR/.soma/templates/"
echo "  ✓ .soma/ (protocols + templates)"

# Scripts (search, scan, audit, etc.)
if [ -d "$AGENT_DIR/scripts" ]; then
  # Copy top-level scripts (excluding sync-from-agent.sh which is CLI-only)
  for f in "$AGENT_DIR/scripts/"*.sh; do
    [ -f "$f" ] && cp "$f" "$CLI_DIR/scripts/"
  done
  # Copy audit scripts directory
  if [ -d "$AGENT_DIR/scripts/audits" ]; then
    mkdir -p "$CLI_DIR/scripts/audits"
    cp "$AGENT_DIR/scripts/audits/"*.sh "$CLI_DIR/scripts/audits/"
  fi
  chmod +x "$CLI_DIR/scripts/"*.sh "$CLI_DIR/scripts/audits/"*.sh 2>/dev/null
  echo "  ✓ scripts/ ($(ls "$CLI_DIR/scripts/"*.sh 2>/dev/null | wc -l | tr -d ' ') scripts + audits)"
fi

echo "Done. Ready to publish."
