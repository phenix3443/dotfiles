#!/usr/bin/env sh
# Install RTK binary if not already present.
# Hooks and RTK.md are managed by chezmoi directly; this only ensures the binary exists.

set -e

if command -v rtk >/dev/null 2>&1; then
  exit 0
fi

echo "run_after_05-install-rtk: Installing RTK..."

UNAME_S="$(uname -s)"
case "$UNAME_S" in
  Darwin*)
    if command -v brew >/dev/null 2>&1; then
      brew install rtk
    elif command -v curl >/dev/null 2>&1; then
      curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
    else
      echo "run_after_05-install-rtk: Need brew or curl to install RTK." >&2
      exit 1
    fi
    ;;
  Linux*)
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
    elif command -v cargo >/dev/null 2>&1; then
      cargo install --git https://github.com/rtk-ai/rtk
    else
      echo "run_after_05-install-rtk: Need curl or cargo to install RTK." >&2
      exit 1
    fi
    ;;
  *)
    echo "run_after_05-install-rtk: Unsupported OS: $UNAME_S" >&2
    exit 1
    ;;
esac

if command -v rtk >/dev/null 2>&1; then
  echo "run_after_05-install-rtk: RTK installed ($(rtk --version 2>/dev/null || true))"
fi
