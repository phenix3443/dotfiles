#!/usr/bin/env bash
# Sync local SSH configuration to chezmoi repository
# Handles config file, encrypted .sconf files, and bin scripts

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$REPO_ROOT/dotfiles/private_dot_ssh"

SSH_DIR="$HOME/.ssh"

if [ ! -d "$SSH_DIR" ]; then
  echo "Error: SSH directory not found: $SSH_DIR" >&2
  exit 1
fi

echo "SSH directory: $SSH_DIR"
echo "Repository template path: $TEMPLATE_DIR"
echo ""

sync_config_file() {
  local local_file="$SSH_DIR/config"
  local template_file="$TEMPLATE_DIR/config"
  
  if [ ! -f "$local_file" ]; then
    echo "Warning: SSH config file not found: $local_file"
    return 1
  fi
  
  echo "Processing config..."
  
  cp "$local_file" "$template_file"
  echo "  File synced"
  
  return 0
}

sync_sconf_files() {
  local config_d_dir="$SSH_DIR/config.d"
  
  if [ ! -d "$config_d_dir" ]; then
    echo "Warning: config.d directory not found: $config_d_dir"
    return 1
  fi
  
  echo "Processing .sconf files (encrypted)..."
  
  local count=0
  for sconf_file in "$config_d_dir"/*.sconf; do
    if [ -f "$sconf_file" ]; then
      chezmoi add --encrypt "$sconf_file" 2>&1 | grep -v "^$" || true
      count=$((count + 1))
      echo "  Added: $(basename "$sconf_file")"
    fi
  done
  
  if [ $count -eq 0 ]; then
    echo "  No .sconf files found"
    return 1
  fi
  
  echo "  Total: $count file(s) synced"
  return 0
}

sync_bin_scripts() {
  local bin_dir="$SSH_DIR/bin"
  
  if [ ! -d "$bin_dir" ]; then
    echo "Warning: bin directory not found: $bin_dir"
    return 1
  fi
  
  echo "Processing bin scripts..."
  
  local count=0
  for script in "$bin_dir"/*; do
    if [ -f "$script" ]; then
      chezmoi add "$script" 2>&1 | grep -v "^$" || true
      count=$((count + 1))
      echo "  Added: $(basename "$script")"
    fi
  done
  
  if [ $count -eq 0 ]; then
    echo "  No scripts found"
    return 1
  fi
  
  echo "  Total: $count script(s) synced"
  return 0
}

echo "=== Syncing SSH Configuration ==="
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

if sync_config_file; then
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""

if sync_sconf_files; then
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""

if sync_bin_scripts; then
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""
echo "=== Sync Summary ==="
echo "Success: $SUCCESS_COUNT section(s)"
echo "Failed: $FAIL_COUNT section(s)"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
  echo "Next steps:"
  echo "  1. Review changes: cd $REPO_ROOT && git diff dotfiles/private_dot_ssh/"
  echo "  2. Test templates: chezmoi diff"
  echo "  3. Commit changes: git add dotfiles/private_dot_ssh/ && git commit -m 'sync: update SSH configuration'"
  exit 0
else
  echo "Some sections failed to sync. Please check the errors above."
  exit 1
fi
