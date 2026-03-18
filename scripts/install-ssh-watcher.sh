#!/usr/bin/env bash
# Install SSH config file watcher as a background service
# macOS: LaunchAgent, Linux: systemd user service

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WATCH_SCRIPT="$SCRIPT_DIR/watch-ssh-config.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

install_fswatch() {
  if command -v fswatch &> /dev/null; then
    log_info "fswatch is already installed"
    return 0
  fi
  
  log_warning "fswatch is not installed"
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &> /dev/null; then
      log_info "Installing fswatch via Homebrew..."
      brew install fswatch
    else
      log_error "Homebrew not found. Please install fswatch manually:"
      log_error "  brew install fswatch"
      exit 1
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    log_error "Please install fswatch manually:"
    log_error "  Ubuntu/Debian: sudo apt install fswatch"
    log_error "  Fedora: sudo dnf install fswatch"
    log_error "  Arch: sudo pacman -S fswatch"
    exit 1
  else
    log_error "Unsupported OS: $OSTYPE"
    exit 1
  fi
}

install_macos_launchagent() {
  local plist_file="$HOME/Library/LaunchAgents/com.chezmoi.ssh-watcher.plist"
  
  log_info "Creating LaunchAgent plist file..."
  
  cat > "$plist_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.chezmoi.ssh-watcher</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$WATCH_SCRIPT</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/ssh-watcher.log</string>
    
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/ssh-watcher.error.log</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:$HOME/.local/bin</string>
    </dict>
</dict>
</plist>
EOF
  
  log_info "LaunchAgent installed: $plist_file"
  log_info "Logs will be written to:"
  log_info "  - $HOME/Library/Logs/ssh-watcher.log"
  log_info "  - $HOME/Library/Logs/ssh-watcher.error.log"
  
  # Load the LaunchAgent
  log_info "Loading LaunchAgent..."
  launchctl unload "$plist_file" 2>/dev/null || true
  launchctl load "$plist_file"
  
  log_info "LaunchAgent loaded and started"
}

install_linux_systemd() {
  local service_file="$HOME/.config/systemd/user/ssh-watcher.service"
  
  mkdir -p "$HOME/.config/systemd/user"
  
  log_info "Creating systemd user service..."
  
  cat > "$service_file" <<EOF
[Unit]
Description=SSH Config File Watcher for Chezmoi
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash $WATCH_SCRIPT
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF
  
  log_info "Systemd service installed: $service_file"
  
  # Reload systemd and enable service
  log_info "Enabling and starting service..."
  systemctl --user daemon-reload
  systemctl --user enable ssh-watcher.service
  systemctl --user start ssh-watcher.service
  
  log_info "Service started"
  log_info "View logs with: journalctl --user -u ssh-watcher -f"
}

show_usage() {
  echo "Usage: $0 [install|uninstall|status|logs]"
  echo ""
  echo "Commands:"
  echo "  install    - Install and start the SSH config watcher service"
  echo "  uninstall  - Stop and remove the service"
  echo "  status     - Show service status"
  echo "  logs       - Show service logs"
  echo ""
  echo "The watcher monitors ~/.ssh/config, ~/.ssh/config.d/, and ~/.ssh/bin/"
  echo "and automatically syncs changes to chezmoi repository."
}

uninstall_service() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    local plist_file="$HOME/Library/LaunchAgents/com.chezmoi.ssh-watcher.plist"
    
    if [ -f "$plist_file" ]; then
      log_info "Unloading LaunchAgent..."
      launchctl unload "$plist_file" 2>/dev/null || true
      rm "$plist_file"
      log_info "LaunchAgent removed"
    else
      log_warning "LaunchAgent not found"
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    log_info "Stopping and disabling service..."
    systemctl --user stop ssh-watcher.service 2>/dev/null || true
    systemctl --user disable ssh-watcher.service 2>/dev/null || true
    
    local service_file="$HOME/.config/systemd/user/ssh-watcher.service"
    if [ -f "$service_file" ]; then
      rm "$service_file"
      systemctl --user daemon-reload
      log_info "Service removed"
    else
      log_warning "Service file not found"
    fi
  fi
}

show_status() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    local label="com.chezmoi.ssh-watcher"
    if launchctl list | grep -q "$label"; then
      log_info "Service is running"
      launchctl list | grep "$label"
    else
      log_warning "Service is not running"
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    systemctl --user status ssh-watcher.service
  fi
}

show_logs() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    local log_file="$HOME/Library/Logs/ssh-watcher.log"
    local error_log="$HOME/Library/Logs/ssh-watcher.error.log"
    
    if [ -f "$log_file" ]; then
      log_info "Standard output log:"
      tail -20 "$log_file"
    fi
    
    echo ""
    
    if [ -f "$error_log" ]; then
      log_info "Error log:"
      tail -20 "$error_log"
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    journalctl --user -u ssh-watcher -n 50 -f
  fi
}

# Main
case "${1:-}" in
  install)
    install_fswatch
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
      install_macos_launchagent
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      install_linux_systemd
    else
      log_error "Unsupported OS: $OSTYPE"
      exit 1
    fi
    
    echo ""
    log_info "Installation complete!"
    log_info "The SSH config watcher is now running in the background."
    log_info ""
    log_info "Try editing a file to test:"
    log_info "  vim ~/.ssh/config.d/personal.sconf"
    log_info ""
    log_info "Check status with: $0 status"
    log_info "View logs with: $0 logs"
    ;;
    
  uninstall)
    uninstall_service
    log_info "Uninstallation complete"
    ;;
    
  status)
    show_status
    ;;
    
  logs)
    show_logs
    ;;
    
  *)
    show_usage
    exit 1
    ;;
esac
