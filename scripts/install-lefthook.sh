#!/usr/bin/env sh
# Install lefthook

set -e

if command -v lefthook >/dev/null 2>&1; then
  echo "lefthook is already installed: $(lefthook version)"
  exit 0
fi

echo "Installing lefthook..."

install_with_go() {
  if ! command -v go >/dev/null 2>&1; then
    return 1
  fi
  
  echo "Using go install..."
  GOBIN="${INSTALL_BIN:-$HOME/.local/bin}"
  export GOBIN
  mkdir -p "$GOBIN"
  
  if go install github.com/evilmartians/lefthook@latest; then
    export PATH="$GOBIN:$PATH"
    return 0
  fi
  return 1
}

install_with_npm() {
  if ! command -v npm >/dev/null 2>&1; then
    return 1
  fi
  
  echo "Using npm..."
  npm install -g @evilmartians/lefthook
  return $?
}

install_with_curl() {
  if ! command -v curl >/dev/null 2>&1; then
    return 1
  fi
  
  echo "Using curl install script..."
  INSTALL_BIN="${INSTALL_BIN:-$HOME/.local/bin}"
  mkdir -p "$INSTALL_BIN"
  
  curl -1sLf 'https://dl.cloudsmith.io/public/evilmartians/lefthook/setup.sh' | sh -s -- -b "$INSTALL_BIN"
  return $?
}

OS="$(uname -s)"
case "$OS" in
  Linux*)
    if install_with_go; then
      :
    elif install_with_npm; then
      :
    elif install_with_curl; then
      :
    elif command -v nix-env >/dev/null 2>&1; then
      echo "Using nix-env..."
      nix-env -iA nixpkgs.lefthook
    elif command -v apt-get >/dev/null 2>&1; then
      echo "Using apt-get (requires sudo)..."
      sudo apt-get update && sudo apt-get install -y lefthook
    elif command -v dnf >/dev/null 2>&1; then
      echo "Using dnf (requires sudo)..."
      sudo dnf install -y lefthook
    elif command -v pacman >/dev/null 2>&1; then
      echo "Using pacman (requires sudo)..."
      sudo pacman -S --noconfirm lefthook
    elif command -v apk >/dev/null 2>&1; then
      echo "Using apk (requires sudo)..."
      sudo apk add lefthook
    elif command -v zypper >/dev/null 2>&1; then
      echo "Using zypper (requires sudo)..."
      sudo zypper install -y lefthook
    elif command -v snap >/dev/null 2>&1; then
      echo "Using snap (requires sudo)..."
      sudo snap install lefthook
    else
      echo "No supported package manager found for Linux"
      echo "Please install lefthook manually: https://github.com/evilmartians/lefthook#install"
      exit 1
    fi
    ;;
  Darwin*)
    if install_with_go; then
      :
    elif install_with_npm; then
      :
    elif install_with_curl; then
      :
    elif command -v brew >/dev/null 2>&1; then
      echo "Using Homebrew..."
      brew install lefthook
    elif command -v port >/dev/null 2>&1; then
      echo "Using MacPorts (requires sudo)..."
      sudo port install lefthook
    elif command -v nix-env >/dev/null 2>&1; then
      echo "Using nix-env..."
      nix-env -iA nixpkgs.lefthook
    else
      echo "No supported package manager found for macOS"
      echo "Please install lefthook manually: https://github.com/evilmartians/lefthook#install"
      exit 1
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    if install_with_go; then
      :
    elif install_with_npm; then
      :
    elif command -v winget >/dev/null 2>&1; then
      echo "Using winget..."
      winget install evilmartians.lefthook
    elif command -v scoop >/dev/null 2>&1; then
      echo "Using Scoop..."
      scoop install lefthook
    elif command -v choco >/dev/null 2>&1; then
      echo "Using Chocolatey..."
      choco install lefthook
    else
      echo "No supported package manager found for Windows"
      echo "Please install lefthook manually: https://github.com/evilmartians/lefthook#install"
      exit 1
    fi
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

if command -v lefthook >/dev/null 2>&1; then
  echo "lefthook installed successfully: $(lefthook version)"
else
  echo "lefthook installation may have failed, please verify"
  exit 1
fi
