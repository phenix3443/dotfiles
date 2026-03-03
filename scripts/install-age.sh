#!/usr/bin/env sh
# Install age (encryption tool for chezmoi) - supports Linux, macOS, Windows (MSYS2/Git Bash)

INSTALL_BIN="${INSTALL_BIN:-$HOME/.local/bin}"
UNAME_S="$(uname -s)"

installed() {
  if command -v age >/dev/null 2>&1; then
    echo "age already installed: $(age --version 2>/dev/null || true)"
    return 0
  fi
  return 1
}

install_with_go() {
  if ! command -v go >/dev/null 2>&1; then
    return 1
  fi
  GOBIN="$INSTALL_BIN" export GOBIN
  mkdir -p "$INSTALL_BIN"
  if go install filippo.io/age/cmd/...@latest 2>/dev/null; then
    export PATH="$INSTALL_BIN:$PATH"
    return 0
  fi
  return 1
}

install_with_curl() {
  if ! command -v curl >/dev/null 2>&1; then
    return 1
  fi
  mkdir -p "$INSTALL_BIN"
  OS="$(uname -s)"
  ARCH="$(uname -m)"
  case "$OS" in
    Linux*)
      PLATFORM="linux"
      case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) echo "Unsupported architecture: $ARCH"; return 1 ;;
      esac
      ;;
    Darwin*)
      PLATFORM="darwin"
      case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        arm64) ARCH="arm64" ;;
        *) echo "Unsupported architecture: $ARCH"; return 1 ;;
      esac
      ;;
    *)
      echo "Unsupported OS: $OS"; return 1 ;;
  esac
  VERSION=$(curl -s https://api.github.com/repos/FiloSottile/age/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  if [ -z "$VERSION" ]; then
    echo "Failed to get latest age version"
    return 1
  fi
  URL="https://github.com/FiloSottile/age/releases/download/v${VERSION}/age-v${VERSION}-${PLATFORM}-${ARCH}.tar.gz"
  echo "Downloading age from: $URL"
  TEMP_DIR=$(mktemp -d)
  if curl -fsSL "$URL" | tar -xz -C "$TEMP_DIR"; then
    for f in age age-keygen; do
      src=$(find "$TEMP_DIR" -maxdepth 2 -type f -name "$f" 2>/dev/null | head -1)
      [ -n "$src" ] && mv "$src" "$INSTALL_BIN/$f" && chmod +x "$INSTALL_BIN/$f"
    done
    rm -rf "$TEMP_DIR"
    export PATH="$INSTALL_BIN:$PATH"
    [ -x "$INSTALL_BIN/age" ] && return 0
  fi
  rm -rf "$TEMP_DIR"
  return 1
}

install_linux() {
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y age
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y age
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm age
  elif command -v apk >/dev/null 2>&1; then
    sudo apk add age
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y age
  elif command -v xbps-install >/dev/null 2>&1; then
    sudo xbps-install -Sy age
  elif command -v nix-env >/dev/null 2>&1; then
    nix-env -i age
  elif install_with_go; then
    :
  elif install_with_curl; then
    :
  else
    echo "No supported package manager found for Linux"
    echo "Install age manually: https://github.com/FiloSottile/age#installation"
    return 1
  fi
}

install_darwin() {
  if command -v brew >/dev/null 2>&1; then
    brew install age
  elif command -v port >/dev/null 2>&1; then
    sudo port install age
  elif command -v nix-env >/dev/null 2>&1; then
    nix-env -i age
  elif install_with_go; then
    :
  elif install_with_curl; then
    :
  else
    echo "No supported package manager found for macOS"
    echo "Install age manually: https://github.com/FiloSottile/age#installation"
    return 1
  fi
}

install_windows() {
  if command -v winget >/dev/null 2>&1; then
    winget install --accept-package-agreements FiloSottile.age 2>/dev/null || \
      winget install --accept-package-agreements age 2>/dev/null || install_with_go
  elif command -v scoop >/dev/null 2>&1; then
    scoop install age
  elif command -v choco >/dev/null 2>&1; then
    choco install age -y
  elif install_with_go; then
    :
  else
    echo "Install winget, scoop, or chocolatey, or install Go and run: go install filippo.io/age/cmd/...@latest"
    return 1
  fi
}

installed && exit 0

case "$UNAME_S" in
  Linux)   install_linux ;;
  Darwin)  install_darwin ;;
  MINGW64*|MSYS*|CYGWIN*) install_windows ;;
  *)
    echo "Unsupported platform: $UNAME_S"
    exit 1
    ;;
esac
