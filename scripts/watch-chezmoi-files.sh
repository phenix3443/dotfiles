#!/usr/bin/env bash
# Watch chezmoi-managed files and auto-sync to repository on changes
# Requires: fswatch (install via: brew install fswatch)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

check_chezmoi() {
  if ! command -v chezmoi &> /dev/null; then
    log_error "chezmoi is not installed"
    exit 1
  fi
}

# True if path is $HOME/.cursor or a path under it (not e.g. $HOME/.cursor-backup).
path_is_under_home_dot_cursor() {
  local p="$1"
  local base="$HOME/.cursor"
  [[ "$p" == "$base" || "$p" == "$base/"* ]]
}

# Get list of files managed by chezmoi
get_managed_files() {
  chezmoi managed -i files 2>/dev/null || true
}

# Get list of directories to watch
get_watch_dirs() {
  local managed_files
  managed_files=$(get_managed_files)
  local watch_dirs=()
  
  # Extract unique directories from managed files
  while IFS= read -r file; do
    if [ -n "$file" ] && [ -e "$HOME/$file" ]; then
      local dir
      dir=$(dirname "$HOME/$file")
      if path_is_under_home_dot_cursor "$dir"; then
        continue
      fi
      # Add to array if not already present
      local found=0
      for existing_dir in "${watch_dirs[@]}"; do
        if [ "$existing_dir" = "$dir" ]; then
          found=1
          break
        fi
      done
      if [ "$found" -eq 0 ]; then
        watch_dirs+=("$dir")
      fi
    fi
  done <<< "$managed_files"
  
  # If no managed files found, watch common directories
  if [ ${#watch_dirs[@]} -eq 0 ]; then
    log_warning "No managed files found, watching common directories..."
    watch_dirs=(
      "$HOME/.ssh"
      "$HOME/.config"
      "$HOME/.claude"
    )
  fi
  
  printf '%s\n' "${watch_dirs[@]}"
}

# Debounce mechanism to avoid multiple syncs for rapid changes
LAST_SYNC=0
DEBOUNCE_SECONDS=3

should_sync() {
  local now
  now=$(date +%s)
  local elapsed=$((now - LAST_SYNC))
  
  if [ $elapsed -ge $DEBOUNCE_SECONDS ]; then
    LAST_SYNC=$now
    return 0
  else
    return 1
  fi
}

# Sync changes to chezmoi
sync_changes() {
  local changed_file="$1"

  if path_is_under_home_dot_cursor "$changed_file"; then
    log_info "Skipping ~/.cursor (IDE runtime data is not synced)"
    return
  fi

  if ! should_sync; then
    log_info "Debouncing sync (too soon after last sync)"
    return
  fi
  
  log_info "Change detected: $changed_file"
  
  # Determine which sync script to use based on file path
  local sync_script=""
  local file_type=""
  
  if [[ "$changed_file" =~ /.ssh/ ]]; then
    sync_script="$SCRIPT_DIR/sync-ssh-config.sh"
    file_type="SSH"
  elif [[ "$changed_file" =~ /.claude/ ]]; then
    sync_script="$SCRIPT_DIR/sync-claude-config.sh"
    file_type="Claude"
  elif [[ "$changed_file" =~ /\.zshrc$ ]] || [[ "$changed_file" =~ /zsh/conf\.d/ ]]; then
    sync_script="$SCRIPT_DIR/sync-zsh-config.sh"
    file_type="Zsh"
  elif [[ "$changed_file" =~ /Cursor/ ]] || [[ "$changed_file" =~ /.config/Cursor/ ]]; then
    sync_script="$SCRIPT_DIR/sync-cursor-config.sh"
    file_type="Cursor"
  else
    # Generic chezmoi add for other files
    log_info "Running generic chezmoi add..."
    if chezmoi add "$changed_file" > /tmp/chezmoi-watch-sync.log 2>&1; then
      log_success "File added to chezmoi"
    else
      log_error "Failed to add file to chezmoi"
      tail -5 /tmp/chezmoi-watch-sync.log | while read -r line; do
        log_error "  $line"
      done
    fi
    echo ""
    return
  fi
  
  # Run specific sync script if available
  if [ -f "$sync_script" ] && [ -x "$sync_script" ]; then
    log_info "Running $file_type sync..."
    if bash "$sync_script" > /tmp/chezmoi-watch-sync.log 2>&1; then
      log_success "Sync completed successfully"
      
      # Show summary from sync output
      if grep -q "Success:" /tmp/chezmoi-watch-sync.log; then
        grep "Success:\|Failed:" /tmp/chezmoi-watch-sync.log | while read -r line; do
          log_info "  $line"
        done
      fi
    else
      log_error "Sync failed! Check /tmp/chezmoi-watch-sync.log for details"
      tail -5 /tmp/chezmoi-watch-sync.log | while read -r line; do
        log_error "  $line"
      done
    fi
  else
    log_warning "No specific sync script found for $file_type, using generic chezmoi add"
    if chezmoi add "$changed_file" > /tmp/chezmoi-watch-sync.log 2>&1; then
      log_success "File added to chezmoi"
    else
      log_error "Failed to add file to chezmoi"
    fi
  fi
  
  echo ""
}

handle_deletion() {
  local deleted_file="$1"

  if path_is_under_home_dot_cursor "$deleted_file"; then
    log_info "Skipping deletion under ~/.cursor"
    return
  fi

  if ! should_sync; then
    log_info "Debouncing sync (too soon after last sync)"
    return
  fi

  log_info "Deletion detected: $deleted_file"

  if [[ "$deleted_file" =~ /.ssh/ ]]; then
    log_info "Running SSH sync (will clean stale source files)..."
    local sync_script="$SCRIPT_DIR/sync-ssh-config.sh"
    if [ -f "$sync_script" ] && [ -x "$sync_script" ]; then
      if bash "$sync_script" > /tmp/chezmoi-watch-sync.log 2>&1; then
        log_success "SSH sync completed (stale files cleaned)"
      else
        log_error "SSH sync failed"
        tail -5 /tmp/chezmoi-watch-sync.log | while read -r line; do
          log_error "  $line"
        done
      fi
    fi
  else
    local rel_path="${deleted_file#"$HOME"/}"
    if chezmoi managed -i files 2>/dev/null | grep -qF "$rel_path"; then
      log_info "Removing $rel_path from chezmoi..."
      if chezmoi forget "$rel_path" > /tmp/chezmoi-watch-sync.log 2>&1; then
        log_success "File removed from chezmoi"
      else
        log_error "Failed to remove file from chezmoi"
        tail -5 /tmp/chezmoi-watch-sync.log | while read -r line; do
          log_error "  $line"
        done
      fi
    else
      log_info "File not managed by chezmoi, skipping"
    fi
  fi

  echo ""
}

start_watching() {
  local watch_dirs
  watch_dirs=$(get_watch_dirs)
  local dir_count
  dir_count=$(echo "$watch_dirs" | wc -l | tr -d ' ')
  
  log_info "Starting chezmoi file watcher..."
  log_info "Watching $dir_count directories:"
  
  while IFS= read -r dir; do
    if [ -d "$dir" ]; then
      log_info "  - $dir"
    fi
  done <<< "$watch_dirs"
  
  log_info ""
  log_info "Press Ctrl+C to stop"
  log_info "Debounce interval: ${DEBOUNCE_SECONDS}s"
  echo ""
  
  # Build fswatch command with all directories
  local fswatch_cmd="fswatch -r -e '.*' -i '\\.json$' -i '\\.toml$' -i '\\.yaml$' -i '\\.yml$' -i '\\.conf$' -i '\\.sconf$' -i '\\.ini$' -i '\\.txt$' -i '/config$' -i '/ssh-.*' -e '~$' -e '\\.swp$' -e '\\.tmp$' -e '\\.log$' -l 0.5"
  
  # Add all watch directories
  while IFS= read -r dir; do
    if [ -d "$dir" ]; then
      fswatch_cmd="$fswatch_cmd \"$dir\""
    fi
  done <<< "$watch_dirs"
  
  # Execute fswatch and process changes
  eval "$fswatch_cmd" 2>/dev/null | while read -r file; do
    # Skip .git directory
    if [[ "$file" =~ /.git/ ]]; then
      continue
    fi

    if [ -e "$file" ]; then
      sync_changes "$file"
    else
      handle_deletion "$file"
    fi
  done
}

cleanup() {
  log_info "Stopping file watcher..."
  exit 0
}

trap cleanup SIGINT SIGTERM

# Main
check_fswatch
check_chezmoi

start_watching
