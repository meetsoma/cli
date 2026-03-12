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

# .soma protocols — only scope:bundled ship in npm package
# Source of truth for scope: community repo frontmatter
COMMUNITY_DIR="${COMMUNITY_DIR:-$(dirname "$CLI_DIR")/community}"
mkdir -p "$CLI_DIR/.soma/protocols"

bundled_count=0
hub_count=0
for proto in "$AGENT_DIR/.soma/protocols/"*.md; do
  [ -f "$proto" ] || continue
  name=$(basename "$proto")
  [[ "$name" == _* ]] && { cp "$proto" "$CLI_DIR/.soma/protocols/$name"; continue; }
  [[ "$name" == "README.md" ]] && { cp "$proto" "$CLI_DIR/.soma/protocols/$name"; continue; }

  # Check scope from community repo (canonical) or fallback to file itself
  community_proto="$COMMUNITY_DIR/protocols/$name"
  scope=""
  if [ -f "$community_proto" ]; then
    scope=$(awk '/^---$/{c++;next} c==1 && /^scope:/{gsub(/^scope:[[:space:]]*/, ""); print; exit} c>=2{exit}' "$community_proto")
  fi
  if [ -z "$scope" ]; then
    scope=$(awk '/^---$/{c++;next} c==1 && /^scope:/{gsub(/^scope:[[:space:]]*/, ""); print; exit} c>=2{exit}' "$proto")
  fi

  if [ "$scope" = "bundled" ]; then
    cp "$proto" "$CLI_DIR/.soma/protocols/$name"
    bundled_count=$((bundled_count + 1))
  else
    # Remove from CLI if it was previously synced
    [ -f "$CLI_DIR/.soma/protocols/$name" ] && rm "$CLI_DIR/.soma/protocols/$name"
    hub_count=$((hub_count + 1))
  fi
done
echo "  ✓ .soma/protocols/ ($bundled_count bundled, $hub_count hub-only skipped)"

# .soma templates
cp -R "$AGENT_DIR/.soma/templates/" "$CLI_DIR/.soma/templates/"
echo "  ✓ .soma/templates/"

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
