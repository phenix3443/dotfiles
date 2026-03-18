#!/usr/bin/env bash
# Sync ~/.claude into dotfiles/dot_claude (plain files, no templates).

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$REPO_ROOT/dotfiles/dot_claude"

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
echo "Repository path: $TEMPLATE_DIR"
echo ""

sync_settings_json() {
  local local_file="$CLAUDE_CONFIG/settings.json"
  local repo_file="$TEMPLATE_DIR/settings.json"

  if [ ! -f "$local_file" ]; then
    echo "Warning: Local settings.json not found: $local_file" >&2
    return 1
  fi

  echo "Processing settings.json..."
  cp "$local_file" "$repo_file"
  echo "  Copied to dotfiles/dot_claude/settings.json"
  return 0
}

sync_skills_manifest() {
  local local_file="$CLAUDE_CONFIG/skills_manifest.txt"
  local repo_file="$TEMPLATE_DIR/skills_manifest.txt"

  if [ ! -f "$local_file" ]; then
    echo "Warning: Local skills_manifest.txt not found: $local_file" >&2
    return 1
  fi

  echo "Processing skills_manifest.txt..."
  cp "$local_file" "$repo_file"
  echo "  Copied to dotfiles/dot_claude/skills_manifest.txt"
  return 0
}

sync_mcp_servers() {
  local claude_json="${HOME}/.claude.json"
  local repo_file="$TEMPLATE_DIR/mcp_servers.json"

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

echo "=== Syncing Claude Configuration ==="
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

if sync_settings_json; then
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""

if sync_skills_manifest; then
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""
sync_mcp_servers
echo ""

echo "=== Sync Summary ==="
echo "Success: $SUCCESS_COUNT file(s)"
echo "Failed: $FAIL_COUNT file(s)"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
  echo "Next steps:"
  echo "  1. Review: cd $REPO_ROOT && git diff dotfiles/dot_claude/"
  echo "  2. Commit: git add dotfiles/dot_claude/ && git commit -m 'sync: update Claude configuration'"
  exit 0
else
  echo "Some files failed to sync. Please check the errors above." >&2
  exit 1
fi
