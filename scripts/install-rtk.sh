#!/usr/bin/env sh
# Detect and install RTK (Rust Token Killer) - macOS, Linux.
# https://github.com/rtk-ai/rtk

set -e

if command -v rtk >/dev/null 2>&1; then
  echo "RTK already installed: $(rtk --version 2>/dev/null || true)"
  exit 0
fi

UNAME_S="$(uname -s)"
echo "Installing RTK..."

case "$UNAME_S" in
  Darwin*)
    if command -v brew >/dev/null 2>&1; then
      echo "Using Homebrew..."
      brew install rtk
    elif command -v curl >/dev/null 2>&1; then
      echo "Using install script..."
      curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
    else
      echo "Need brew or curl to install RTK." >&2
      exit 1
    fi
    ;;
  Linux*)
    if command -v curl >/dev/null 2>&1; then
      echo "Using install script..."
      curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
    elif command -v cargo >/dev/null 2>&1; then
      echo "Using cargo..."
      cargo install --git https://github.com/rtk-ai/rtk
    else
      echo "Need curl or cargo to install RTK." >&2
      exit 1
    fi
    ;;
  *)
    echo "Unsupported OS: $UNAME_S. See https://github.com/rtk-ai/rtk#installation" >&2
    exit 1
    ;;
esac

if command -v rtk >/dev/null 2>&1; then
  echo "RTK installed successfully: $(rtk --version 2>/dev/null || true)"
else
  echo "RTK may not be in PATH. Restart shell or check install location." >&2
fi
