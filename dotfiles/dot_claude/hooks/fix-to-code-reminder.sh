#!/usr/bin/env bash
# PostToolUse hook: remind Claude to persist fixes after state-changing commands.
# Claude Code expects stdout JSON with optional systemMessage (not decision/message).
set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo '{"continue":true}'
  exit 0
fi

input=$(cat)
if [ -z "$input" ]; then
  echo '{"continue":true}'
  exit 0
fi
if ! echo "$input" | jq -e . >/dev/null 2>&1; then
  echo '{"continue":true}'
  exit 0
fi

command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || {
  echo '{"continue":true}'
  exit 0
}

if echo "$command" | grep -qE '(ssh .*(sudo|systemctl|apt|yum|dnf|sed -i|tee|echo.*>>|mv |cp |chmod|chown|mkdir)|kubectl (apply|patch|delete|edit|scale|rollout|set)|ansible-playbook|helm (install|upgrade|delete))'; then
  jq -n \
    --arg msg '[Fix-to-Code] State-changing command detected. After fixing, persist changes to the source script, playbook, or manifest.' \
    '{continue: true, suppressOutput: false, systemMessage: $msg}'
else
  echo '{"continue":true}'
fi

exit 0
