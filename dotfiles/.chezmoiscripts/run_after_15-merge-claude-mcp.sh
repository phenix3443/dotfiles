#!/usr/bin/env sh
# Merge ~/.claude/mcp_servers.json into ~/.claude.json as mcpServers (other keys unchanged).

set -e

MCP_FILE="${HOME}/.claude/mcp_servers.json"
CLAUDB_JSON="${HOME}/.claude.json"

if [ ! -f "$MCP_FILE" ]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "run_after_15-merge-claude-mcp: jq not found; cannot merge MCP config." >&2
  exit 1
fi

tmp=$(mktemp "${TMPDIR:-/tmp}/claude-mcp-merge.XXXXXX")
cleanup() {
  rm -f "$tmp"
}
trap cleanup EXIT

if [ -f "$CLAUDB_JSON" ]; then
  jq --slurpfile mcp "$MCP_FILE" '.mcpServers = $mcp[0]' "$CLAUDB_JSON" >"$tmp"
else
  jq -n --slurpfile mcp "$MCP_FILE" '{mcpServers: $mcp[0]}' >"$tmp"
fi

mv "$tmp" "$CLAUDB_JSON"
trap - EXIT
