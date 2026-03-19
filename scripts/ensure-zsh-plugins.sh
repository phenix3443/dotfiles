#!/usr/bin/env sh
# Ensure zsh plugins (zsh-syntax-highlighting, zsh-autosuggestions) are installed
# Installs Homebrew if missing on macOS, then installs the plugins

set -e

UNAME_S="$(uname -s)"

log_info() {
  echo "[INFO] $*"
}

log_error() {
  echo "[ERROR] $*" >&2
}

check_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

install_homebrew_macos() {
  log_info "Homebrew not found, installing..."
  if ! command -v curl >/dev/null 2>&1; then
    log_error "curl not found, cannot install Homebrew"
    exit 1
  fi
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  case "$(uname -m)" in
    arm64)
      eval "$(/opt/homebrew/bin/brew shellenv)"
      ;;
    x86_64)
      eval "$(/usr/local/bin/brew shellenv)"
      ;;
  esac
  
  if ! check_brew; then
    log_error "Homebrew installation failed"
    exit 1
  fi
  log_info "Homebrew installed successfully"
}

check_plugin() {
  plugin_name="$1"
  brew_prefix="$(brew --prefix 2>/dev/null || echo '/opt/homebrew')"
  if [ -f "$brew_prefix/share/$plugin_name/$plugin_name.zsh" ]; then
    return 0
  fi
  return 1
}

install_plugins() {
  log_info "Installing zsh plugins..."
  brew install zsh-syntax-highlighting zsh-autosuggestions
  log_info "zsh plugins installed successfully"
}

main() {
  case "$UNAME_S" in
    Darwin*)
      if ! check_brew; then
        install_homebrew_macos
      else
        log_info "Homebrew already installed"
      fi
      
      if check_plugin "zsh-syntax-highlighting" && check_plugin "zsh-autosuggestions"; then
        log_info "zsh plugins already installed"
        exit 0
      fi
      
      install_plugins
      ;;
    Linux*)
      if ! check_brew; then
        log_error "Homebrew not found on Linux"
        log_error "Please install Homebrew first: https://brew.sh"
        log_error "Or manually install: zsh-syntax-highlighting, zsh-autosuggestions"
        exit 1
      fi
      
      if check_plugin "zsh-syntax-highlighting" && check_plugin "zsh-autosuggestions"; then
        log_info "zsh plugins already installed"
        exit 0
      fi
      
      install_plugins
      ;;
    *)
      log_error "Unsupported OS: $UNAME_S"
      log_error "Please manually install: zsh-syntax-highlighting, zsh-autosuggestions"
      exit 1
      ;;
  esac
}

main
