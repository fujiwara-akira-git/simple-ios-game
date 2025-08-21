#!/usr/bin/env bash
set -euo pipefail

# Robust generator script for macOS Xcode project using xcodegen
# - copies Resources/sounds/tap.wav into SimpleGameMac/Resources so xcodegen includes it
# - runs xcodegen and writes logs to /tmp
# - creates workspace referencing existing iOS project and the new macOS project
# - opens the workspace when done

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen not found. Install via 'brew install xcodegen' and re-run."
  exit 2
fi

# ensure destination resources folder exists and copy tap.wav if present
if [ -f "Resources/sounds/tap.wav" ]; then
  mkdir -p SimpleGameMac/Resources/sounds
  cp -f Resources/sounds/tap.wav SimpleGameMac/Resources/sounds/tap.wav
  echo "Copied Resources/sounds/tap.wav -> SimpleGameMac/Resources/sounds/tap.wav"
fi

LOGFILE="/tmp/xcodegen_simplegamemac.log"
rm -f "$LOGFILE"

echo "Running xcodegen (log: $LOGFILE)"
if ! xcodegen --spec project-mac.yml --project SimpleGameMac.xcodeproj > "$LOGFILE" 2>&1; then
  echo "xcodegen failed. See $LOGFILE for details." >&2
  sed -n '1,200p' "$LOGFILE" >&2 || true
  exit 3
fi

# Create workspace that includes existing SimpleGame.xcodeproj and new SimpleGameMac.xcodeproj
WORKSPACE_DIR="$ROOT_DIR/SimpleGame.xcworkspace"
if [ -d "$WORKSPACE_DIR" ]; then
  echo "Workspace already exists at $WORKSPACE_DIR"
else
  mkdir -p "$WORKSPACE_DIR"
  cat > "$WORKSPACE_DIR/contents.xcworkspacedata" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Workspace version = "1.0">
  <FileRef location = "group:SimpleGame/SimpleGame.xcodeproj"/>
  <FileRef location = "group:SimpleGameMac.xcodeproj"/>
</Workspace>
EOF
  echo "Created workspace at $WORKSPACE_DIR"
fi

echo "Done. Generated SimpleGameMac.xcodeproj and workspace. Opening workspace..."
open SimpleGame.xcworkspace || true
