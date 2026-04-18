#!/usr/bin/env bash
# Sync ~/.codex into dotfiles/dot_codex (config.toml as template).

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="$REPO_ROOT/dotfiles/dot_codex"
CODEX_CONFIG="$HOME/.codex"

if [ ! -d "$CODEX_CONFIG" ]; then
  echo "Error: Codex config directory not found: $CODEX_CONFIG" >&2
  exit 1
fi

echo "Codex config path: $CODEX_CONFIG"
echo "Repository path: $TARGET_DIR"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0
sync_ok() { SUCCESS_COUNT=$((SUCCESS_COUNT + 1)); }
sync_fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); }

# --- config.toml -> config.toml.tmpl ---
sync_config_toml() {
  local local_file="$CODEX_CONFIG/config.toml"
  local repo_file="$TARGET_DIR/config.toml.tmpl"

  if [ ! -f "$local_file" ]; then
    echo "Warning: config.toml not found: $local_file" >&2
    return 1
  fi

  echo "Processing config.toml -> config.toml.tmpl..."

  local home_escaped
  home_escaped=$(printf '%s' "$HOME" | sed 's/[\/&]/\\&/g')

  # Strip [marketplaces.*] blocks (runtime-generated), then template $HOME
  awk '/^\[marketplaces\./{skip=1} /^\[/ && !/^\[marketplaces\./{skip=0} !skip{print}' "$local_file" \
    | sed "s|${home_escaped}|{{ .chezmoi.homeDir }}|g" \
    > "$repo_file"

  echo "  Written to dotfiles/dot_codex/config.toml.tmpl"
  return 0
}

echo "=== Syncing Codex Configuration ==="
echo ""

if sync_config_toml; then sync_ok; else sync_fail; fi
echo ""

echo "=== Sync Summary ==="
echo "Success: $SUCCESS_COUNT item(s)"
echo "Failed: $FAIL_COUNT item(s)"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
  echo "Next steps:"
  echo "  1. Review: cd $REPO_ROOT && git diff dotfiles/dot_codex/"
  echo "  2. Commit: git add dotfiles/dot_codex/ && git commit -m 'sync: update Codex configuration'"
  exit 0
else
  echo "Some items failed to sync. Please check the errors above." >&2
  exit 1
fi
