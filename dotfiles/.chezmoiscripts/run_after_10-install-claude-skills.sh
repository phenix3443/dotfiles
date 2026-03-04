#!/usr/bin/env sh
# Install Claude Code user-level skills from ~/.claude/skills_manifest.txt.
# Runs after chezmoi apply. Requires add-skill and Node; exits with error if missing.

set -e

MANIFEST="${HOME}/.claude/skills_manifest.txt"
SKILLS_DIR="${HOME}/.claude/skills"

if ! command -v add-skill >/dev/null 2>&1 && ! command -v npx >/dev/null 2>&1; then
  echo "run_after_10-install-claude-skills: add-skill 未找到，且 npx 不可用。请先执行 make install 或安装 Node/npm 后重试。" >&2
  exit 1
fi

if [ ! -f "$MANIFEST" ]; then
  echo "run_after_10-install-claude-skills: 清单文件不存在: $MANIFEST" >&2
  exit 1
fi

mkdir -p "$SKILLS_DIR"

run_add_skill() {
  if command -v add-skill >/dev/null 2>&1; then
    add-skill "$@" -g -y < /dev/null
  else
    npx add-skill "$@" -g -y < /dev/null
  fi
}

failed=0
while IFS= read -r line || [ -n "$line" ]; do
  line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  [ -z "$line" ] && continue
  case "$line" in
    \#*) continue ;;
    *) ;;
  esac
  set -- $line
  if ! run_add_skill "$@"; then
    echo "run_after_10-install-claude-skills: 安装失败: $line" >&2
    failed=1
  fi
done < "$MANIFEST"

echo "Claude Code skills installed from $MANIFEST"
[ "$failed" -eq 1 ] && exit 1 || true
