#!/usr/bin/env bash
# Watch SSH configuration files and auto-sync to chezmoi on changes
# Requires: fswatch (install via: brew install fswatch)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync-ssh-config.sh"
SSH_DIR="$HOME/.ssh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_error() {
  echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*" >&2
}

check_fswatch() {
  if ! command -v fswatch &> /dev/null; then
    log_error "fswatch is not installed"
    log_info "Install it with: brew install fswatch (macOS) or apt install fswatch (Linux)"
    exit 1
  fi
}

check_sync_script() {
  if [ ! -f "$SYNC_SCRIPT" ]; then
    log_error "Sync script not found: $SYNC_SCRIPT"
    exit 1
  fi
  
  if [ ! -x "$SYNC_SCRIPT" ]; then
    log_warning "Sync script is not executable, fixing..."
    chmod +x "$SYNC_SCRIPT"
  fi
}

check_ssh_dir() {
  if [ ! -d "$SSH_DIR" ]; then
    log_error "SSH directory not found: $SSH_DIR"
    exit 1
  fi
}

# Debounce mechanism to avoid multiple syncs for rapid changes
LAST_SYNC=0
DEBOUNCE_SECONDS=3

should_sync() {
  local now=$(date +%s)
  local elapsed=$((now - LAST_SYNC))
  
  if [ $elapsed -ge $DEBOUNCE_SECONDS ]; then
    LAST_SYNC=$now
    return 0
  else
    return 1
  fi
}

sync_changes() {
  local changed_file="$1"
  
  if ! should_sync; then
    log_info "Debouncing sync (too soon after last sync)"
    return
  fi
  
  log_info "Change detected: $changed_file"
  log_info "Running sync..."
  
  if bash "$SYNC_SCRIPT" > /tmp/ssh-watch-sync.log 2>&1; then
    log_success "Sync completed successfully"
    
    # Show summary from sync output
    if grep -q "Success:" /tmp/ssh-watch-sync.log; then
      grep "Success:\|Failed:" /tmp/ssh-watch-sync.log | while read line; do
        log_info "  $line"
      done
    fi
  else
    log_error "Sync failed! Check /tmp/ssh-watch-sync.log for details"
    tail -5 /tmp/ssh-watch-sync.log | while read line; do
      log_error "  $line"
    done
  fi
  
  echo ""
}

start_watching() {
  log_info "Starting SSH config file watcher..."
  log_info "Watching directories:"
  log_info "  - $SSH_DIR/config"
  log_info "  - $SSH_DIR/config.d/"
  log_info "  - $SSH_DIR/bin/"
  log_info ""
  log_info "Press Ctrl+C to stop"
  log_info "Debounce interval: ${DEBOUNCE_SECONDS}s"
  echo ""
  
  # Watch SSH config files and directories
  # -r: recursive
  # -e Updated: watch for file updates
  # -e Created: watch for new files
  # -e Removed: watch for deleted files
  # -l 0.5: latency 0.5 seconds
  fswatch -r \
    -e ".*" \
    -i "\\.sconf$" \
    -i "/config$" \
    -i "/ssh-.*" \
    -e "~$" \
    -e "\\.swp$" \
    -e "\\.tmp$" \
    -l 0.5 \
    "$SSH_DIR/config" \
    "$SSH_DIR/config.d" \
    "$SSH_DIR/bin" 2>/dev/null | while read file; do
    sync_changes "$file"
  done
}

cleanup() {
  log_info "Stopping file watcher..."
  exit 0
}

trap cleanup SIGINT SIGTERM

# Main
check_fswatch
check_sync_script
check_ssh_dir

start_watching
