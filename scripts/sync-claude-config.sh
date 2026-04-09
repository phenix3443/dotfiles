#!/usr/bin/env bash
# Sync ~/.claude into dotfiles/dot_claude (plain files + settings.json template).
# shellcheck disable=SC2329  # functions invoked indirectly via loop

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="$REPO_ROOT/dotfiles/dot_claude"

detect_claude_config_path() {
  case "$(uname -s)" in
    Darwin|Linux)
      echo "$HOME/.claude"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "$HOME/.claude"
      ;;
    *)
      echo "Unsupported OS: $(uname -s)" >&2
      exit 1
      ;;
  esac
}

CLAUDE_CONFIG="$(detect_claude_config_path)"

if [ ! -d "$CLAUDE_CONFIG" ]; then
  echo "Error: Claude config directory not found: $CLAUDE_CONFIG" >&2
  exit 1
fi

echo "Claude config path: $CLAUDE_CONFIG"
echo "Repository path: $TARGET_DIR"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

sync_ok() { SUCCESS_COUNT=$((SUCCESS_COUNT + 1)); }
sync_fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); }

# --- settings.json -> settings.json.tmpl ---
sync_settings_json() {
  local local_file="$CLAUDE_CONFIG/settings.json"
  local repo_file="$TARGET_DIR/settings.json.tmpl"

  if [ ! -f "$local_file" ]; then
    echo "Warning: Local settings.json not found: $local_file" >&2
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "Warning: jq not found; cannot process settings.json" >&2
    return 1
  fi

  echo "Processing settings.json -> settings.json.tmpl..."

  local tmp
  tmp=$(mktemp)

  # Strip the "env" block (machine-specific; belongs in settings.local.json)
  jq 'del(.env)' "$local_file" > "$tmp"

  # Replace $HOME with chezmoi template variable in hook command paths
  local home_escaped
  home_escaped=$(printf '%s' "$HOME" | sed 's/[\/&]/\\&/g')
  sed "s|${home_escaped}|{{ .chezmoi.homeDir }}|g" "$tmp" > "$repo_file"

  rm -f "$tmp"
  echo "  Written to dotfiles/dot_claude/settings.json.tmpl (env stripped, paths templated)"
  return 0
}

# --- skills_manifest.txt ---
sync_skills_manifest() {
  local local_file="$CLAUDE_CONFIG/skills_manifest.txt"
  local repo_file="$TARGET_DIR/skills_manifest.txt"

  if [ ! -f "$local_file" ]; then
    echo "Warning: Local skills_manifest.txt not found: $local_file" >&2
    return 1
  fi

  echo "Processing skills_manifest.txt..."
  cp "$local_file" "$repo_file"
  echo "  Copied to dotfiles/dot_claude/skills_manifest.txt"
  return 0
}

# --- mcp_servers.json (from ~/.claude.json) ---
sync_mcp_servers() {
  local claude_json="${HOME}/.claude.json"
  local repo_file="$TARGET_DIR/mcp_servers.json"

  if ! command -v jq >/dev/null 2>&1; then
    echo "Warning: jq not found; skipping mcp_servers.json sync." >&2
    return 0
  fi
  if [ ! -f "$claude_json" ]; then
    echo "Warning: ~/.claude.json not found; skipping mcp_servers.json sync." >&2
    return 0
  fi

  echo "Processing mcp_servers.json..."
  if ! jq '.mcpServers // {}' "$claude_json" >"${repo_file}.tmp"; then
    echo "Warning: failed to extract mcpServers from ~/.claude.json" >&2
    rm -f "${repo_file}.tmp"
    return 0
  fi
  mv "${repo_file}.tmp" "$repo_file"
  echo "  Wrote dotfiles/dot_claude/mcp_servers.json"
  return 0
}

# --- CLAUDE.md ---
sync_claude_md() {
  local local_file="$CLAUDE_CONFIG/CLAUDE.md"
  local repo_file="$TARGET_DIR/CLAUDE.md"

  if [ ! -f "$local_file" ]; then
    echo "Warning: Local CLAUDE.md not found" >&2
    return 1
  fi

  echo "Processing CLAUDE.md..."
  cp "$local_file" "$repo_file"
  echo "  Copied to dotfiles/dot_claude/CLAUDE.md"
  return 0
}

# --- RTK.md ---
sync_rtk_md() {
  local local_file="$CLAUDE_CONFIG/RTK.md"
  local repo_file="$TARGET_DIR/RTK.md"

  if [ ! -f "$local_file" ]; then
    echo "Info: RTK.md not found (RTK not installed?), skipping"
    return 0
  fi

  echo "Processing RTK.md..."
  cp "$local_file" "$repo_file"
  echo "  Copied to dotfiles/dot_claude/RTK.md"
  return 0
}

# --- hooks/ directory ---
sync_hooks() {
  local src_dir="$CLAUDE_CONFIG/hooks"
  local dst_dir="$TARGET_DIR/hooks"

  if [ ! -d "$src_dir" ]; then
    echo "Info: hooks/ directory not found, skipping"
    return 0
  fi

  echo "Processing hooks/..."
  mkdir -p "$dst_dir"

  local count=0
  for f in "$src_dir"/*.sh; do
    [ -f "$f" ] || continue
    local name
    name=$(basename "$f")
    cp "$f" "$dst_dir/$name"
    chmod +x "$dst_dir/$name"
    count=$((count + 1))
  done

  echo "  Synced $count hook script(s) to dotfiles/dot_claude/hooks/"
  return 0
}

# --- settings/mcp.json ---
sync_settings_mcp() {
  local local_file="$CLAUDE_CONFIG/settings/mcp.json"
  local repo_file="$TARGET_DIR/settings/mcp.json"

  if [ ! -f "$local_file" ]; then
    echo "Info: settings/mcp.json not found, skipping"
    return 0
  fi

  echo "Processing settings/mcp.json..."
  mkdir -p "$TARGET_DIR/settings"
  cp "$local_file" "$repo_file"
  echo "  Copied to dotfiles/dot_claude/settings/mcp.json"
  return 0
}

# --- Run all syncs ---
echo "=== Syncing Claude Configuration ==="
echo ""

for fn in sync_settings_json sync_skills_manifest sync_mcp_servers \
          sync_claude_md sync_rtk_md sync_hooks sync_settings_mcp; do
  if $fn; then
    sync_ok
  else
    sync_fail
  fi
  echo ""
done

echo "=== Sync Summary ==="
echo "Success: $SUCCESS_COUNT item(s)"
echo "Failed: $FAIL_COUNT item(s)"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
  echo "Next steps:"
  echo "  1. Review: cd $REPO_ROOT && git diff dotfiles/dot_claude/"
  echo "  2. Commit: git add dotfiles/dot_claude/ && git commit -m 'sync: update Claude configuration'"
  exit 0
else
  echo "Some items failed to sync. Please check the errors above." >&2
  exit 1
fi
