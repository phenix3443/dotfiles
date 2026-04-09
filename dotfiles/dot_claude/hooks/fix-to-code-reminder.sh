#!/bin/bash
# PostToolUse hook: detect state-modifying commands and remind Claude
# to persist fixes back to source scripts/playbooks/manifests.
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Match commands that likely modify remote/cluster/system state
if echo "$command" | grep -qE '(ssh .*(sudo|systemctl|apt|yum|dnf|sed -i|tee|echo.*>>|mv |cp |chmod|chown|mkdir)|kubectl (apply|patch|delete|edit|scale|rollout|set)|ansible-playbook|helm (install|upgrade|delete))'; then
  echo '{"decision": "approve", "message": "[Fix-to-Code] 检测到状态修改命令。修复完成后，请立即将改动回写到对应的源脚本/playbook/manifest 中。"}'
else
  echo '{"decision": "approve"}'
fi
