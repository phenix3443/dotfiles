#!/usr/bin/env sh
# Install add-skill (npm package) to INSTALL_BIN for Claude Code skills management.

set -e

INSTALL_BIN="${INSTALL_BIN:-$HOME/.local/bin}"

if command -v add-skill >/dev/null 2>&1; then
  echo "add-skill already installed: $(add-skill --version 2>/dev/null || true)"
  exit 0
fi

if npx add-skill --version >/dev/null 2>&1; then
  echo "add-skill available via npx"
  exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "跳过 add-skill：未检测到 npm"
  exit 0
fi

echo "Installing add-skill..."
NPM_PREFIX="$(dirname "$INSTALL_BIN")"
mkdir -p "$INSTALL_BIN"
npm install add-skill --prefix "$NPM_PREFIX" --no-save

if command -v add-skill >/dev/null 2>&1; then
  echo "add-skill installed successfully to $INSTALL_BIN"
else
  echo "add-skill may not be in PATH; ensure $INSTALL_BIN is in your PATH"
fi
