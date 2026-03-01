#!/usr/bin/env sh
# Install keepassxc (includes keepassxc-cli) - supports Linux, macOS, Windows (MSYS2/Git Bash)

UNAME_S="$(uname -s)"

installed() {
  if command -v keepassxc-cli >/dev/null 2>&1; then
    echo "keepassxc-cli already installed: $(keepassxc-cli --version 2>/dev/null | head -1)"
    return 0
  fi
  return 1
}

install_linux() {
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y keepassxc
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y keepassxc || (sudo dnf install -y epel-release && sudo dnf install -y keepassxc)
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm keepassxc
  elif command -v apk >/dev/null 2>&1; then
    sudo apk add keepassxc
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y keepassxc
  elif command -v xbps-install >/dev/null 2>&1; then
    sudo xbps-install -Sy keepassxc
  elif command -v flatpak >/dev/null 2>&1; then
    flatpak install -y flathub org.keepassxc.KeePassXC
  elif command -v snap >/dev/null 2>&1; then
    sudo snap install keepassxc
  else
    echo "No supported package manager found. Install keepassxc manually."
    return 1
  fi
}

install_darwin() {
  if command -v brew >/dev/null 2>&1; then
    brew install --cask keepassxc
  elif command -v port >/dev/null 2>&1; then
    sudo port install keepassxc
  else
    echo "Install Homebrew (brew.sh) or MacPorts, then: brew install --cask keepassxc"
    return 1
  fi
}

install_windows() {
  if command -v winget >/dev/null 2>&1; then
    winget install --accept-package-agreements KeePassXCTeam.KeePassXC
  elif command -v scoop >/dev/null 2>&1; then
    scoop install keepassxc
  elif command -v choco >/dev/null 2>&1; then
    choco install keepassxc -y
  else
    echo "Install winget, scoop, or chocolatey to install keepassxc"
    return 1
  fi
}

installed && exit 0

case "$UNAME_S" in
  Linux)    install_linux ;;
  Darwin)   install_darwin ;;
  MINGW64*|MSYS*|CYGWIN*) install_windows ;;
  *)
    echo "Unsupported platform: $UNAME_S. Install keepassxc from https://keepassxc.org/download/"
    exit 1
    ;;
esac
