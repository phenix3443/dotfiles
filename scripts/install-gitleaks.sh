#!/usr/bin/env sh
# Install gitleaks

set -e

if command -v gitleaks >/dev/null 2>&1; then
  echo "gitleaks is already installed: $(gitleaks version)"
  exit 0
fi

echo "Installing gitleaks..."

install_with_go() {
  if ! command -v go >/dev/null 2>&1; then
    return 1
  fi
  
  echo "Using go install..."
  GOBIN="${INSTALL_BIN:-$HOME/.local/bin}"
  export GOBIN
  mkdir -p "$GOBIN"
  
  if go install github.com/gitleaks/gitleaks/v8@latest; then
    export PATH="$GOBIN:$PATH"
    return 0
  fi
  return 1
}

install_with_curl() {
  if ! command -v curl >/dev/null 2>&1; then
    return 1
  fi
  
  echo "Using curl install script..."
  INSTALL_BIN="${INSTALL_BIN:-$HOME/.local/bin}"
  mkdir -p "$INSTALL_BIN"
  
  OS="$(uname -s)"
  ARCH="$(uname -m)"
  
  case "$OS" in
    Linux*)
      case "$ARCH" in
        x86_64) ARCH="x64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        armv7l) ARCH="armv7" ;;
        *) echo "Unsupported architecture: $ARCH"; return 1 ;;
      esac
      PLATFORM="linux"
      ;;
    Darwin*)
      case "$ARCH" in
        x86_64) ARCH="x64" ;;
        arm64) ARCH="arm64" ;;
        *) echo "Unsupported architecture: $ARCH"; return 1 ;;
      esac
      PLATFORM="darwin"
      ;;
    *)
      echo "Unsupported OS: $OS"
      return 1
      ;;
  esac
  
  VERSION=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  if [ -z "$VERSION" ]; then
    echo "Failed to get latest version"
    return 1
  fi
  
  URL="https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/gitleaks_${VERSION}_${PLATFORM}_${ARCH}.tar.gz"
  echo "Downloading from: $URL"
  
  TEMP_DIR=$(mktemp -d)
  if curl -fsSL "$URL" | tar -xz -C "$TEMP_DIR"; then
    mv "$TEMP_DIR/gitleaks" "$INSTALL_BIN/"
    chmod +x "$INSTALL_BIN/gitleaks"
    rm -rf "$TEMP_DIR"
    return 0
  fi
  rm -rf "$TEMP_DIR"
  return 1
}

OS="$(uname -s)"
case "$OS" in
  Linux*)
    if install_with_go; then
      :
    elif install_with_curl; then
      :
    elif command -v apt-get >/dev/null 2>&1; then
      echo "Using apt-get (requires sudo)..."
      sudo apt-get update && sudo apt-get install -y gitleaks
    elif command -v dnf >/dev/null 2>&1; then
      echo "Using dnf (requires sudo)..."
      sudo dnf install -y gitleaks
    elif command -v pacman >/dev/null 2>&1; then
      echo "Using pacman (requires sudo)..."
      sudo pacman -S --noconfirm gitleaks
    elif command -v apk >/dev/null 2>&1; then
      echo "Using apk (requires sudo)..."
      sudo apk add gitleaks
    else
      echo "No supported package manager found for Linux"
      echo "Please install gitleaks manually: https://github.com/gitleaks/gitleaks#installation"
      exit 1
    fi
    ;;
  Darwin*)
    if install_with_go; then
      :
    elif install_with_curl; then
      :
    elif command -v brew >/dev/null 2>&1; then
      echo "Using Homebrew..."
      brew install gitleaks
    else
      echo "No supported package manager found for macOS"
      echo "Please install gitleaks manually: https://github.com/gitleaks/gitleaks#installation"
      exit 1
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    if install_with_go; then
      :
    elif command -v winget >/dev/null 2>&1; then
      echo "Using winget..."
      winget install gitleaks.gitleaks
    elif command -v scoop >/dev/null 2>&1; then
      echo "Using Scoop..."
      scoop install gitleaks
    elif command -v choco >/dev/null 2>&1; then
      echo "Using Chocolatey..."
      choco install gitleaks
    else
      echo "No supported package manager found for Windows"
      echo "Please install gitleaks manually: https://github.com/gitleaks/gitleaks#installation"
      exit 1
    fi
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

if command -v gitleaks >/dev/null 2>&1; then
  echo "gitleaks installed successfully: $(gitleaks version)"
else
  echo "gitleaks installation may have failed, please verify"
  exit 1
fi
