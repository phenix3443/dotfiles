#!/usr/bin/env sh
# Install chezmoi - supports Linux, macOS, Windows (MSYS2/Git Bash)

INSTALL_BIN="${INSTALL_BIN:-$HOME/.local/bin}"
UNAME_S="$(uname -s)"

installed() {
  if command -v chezmoi >/dev/null 2>&1; then
    echo "chezmoi already installed: $(chezmoi --version)"
    return 0
  fi
  return 1
}

install_linux() {
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y chezmoi
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y chezmoi || (sudo dnf install -y epel-release && sudo dnf install -y chezmoi)
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm chezmoi
  elif command -v apk >/dev/null 2>&1; then
    sudo apk add chezmoi
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y chezmoi
  elif command -v xbps-install >/dev/null 2>&1; then
    sudo xbps-install -Sy chezmoi
  elif command -v nix-env >/dev/null 2>&1; then
    nix-env -i chezmoi
  elif command -v snap >/dev/null 2>&1; then
    sudo snap install chezmoi --classic
  else
    echo "No supported package manager found, using install script..."
    mkdir -p "$INSTALL_BIN" && sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$INSTALL_BIN"
  fi
}

install_darwin() {
  if command -v brew >/dev/null 2>&1; then
    brew install chezmoi
  elif command -v port >/dev/null 2>&1; then
    sudo port install chezmoi
  elif command -v nix-env >/dev/null 2>&1; then
    nix-env -i chezmoi
  else
    echo "No supported package manager found, using install script..."
    mkdir -p "$INSTALL_BIN" && sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$INSTALL_BIN"
  fi
}

install_windows() {
  if command -v winget >/dev/null 2>&1; then
    winget install --accept-package-agreements twpayne.chezmoi
  elif command -v scoop >/dev/null 2>&1; then
    scoop install chezmoi
  elif command -v choco >/dev/null 2>&1; then
    choco install chezmoi -y
  else
    echo "Install winget, scoop, or chocolatey, or run: iex \"&{\$(irm 'https://get.chezmoi.io/ps1')}\" -b '$INSTALL_BIN'"
    return 1
  fi
}

installed && exit 0

case "$UNAME_S" in
  Linux)    install_linux ;;
  Darwin)   install_darwin ;;
  MINGW64*|MSYS*|CYGWIN*) install_windows ;;
  *)
    echo "Unsupported platform: $UNAME_S. Use: sh -c \"\$(curl -fsLS get.chezmoi.io)\" -- -b $INSTALL_BIN"
    exit 1
    ;;
esac
