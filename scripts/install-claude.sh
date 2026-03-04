#!/usr/bin/env sh
# Detect and install Claude Code (claude CLI) - macOS, Linux.

set -e

if command -v claude >/dev/null 2>&1; then
  echo "Claude Code already installed: $(claude --version 2>/dev/null || true)"
  exit 0
fi

UNAME_S="$(uname -s)"
echo "Installing Claude Code..."

install_darwin() {
  if command -v brew >/dev/null 2>&1; then
    echo "Using Homebrew..."
    brew install --cask claude-code
    return 0
  fi
  echo "Using official install script..."
  curl -fsSL https://claude.ai/install.sh | bash
}

install_linux() {
  if command -v curl >/dev/null 2>&1; then
    echo "Using official install script..."
    curl -fsSL https://claude.ai/install.sh | bash
    return 0
  fi
  if command -v npm >/dev/null 2>&1; then
    echo "Using npm..."
    npm install -g @anthropic-ai/claude-code
    return 0
  fi
  echo "需要 curl 或 npm 以安装 Claude Code。请安装其一后重试。" >&2
  return 1
}

case "$UNAME_S" in
  Darwin*)
    install_darwin
    ;;
  Linux*)
    install_linux
    ;;
  *)
    echo "未支持的系统: $UNAME_S。请从 https://docs.anthropic.com/en/docs/claude-code/setup 查看安装说明。" >&2
    exit 1
    ;;
esac

if command -v claude >/dev/null 2>&1; then
  echo "Claude Code installed successfully."
else
  echo "安装可能未加入 PATH，请重启终端或检查安装路径。" >&2
fi
