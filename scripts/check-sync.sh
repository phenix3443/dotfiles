#!/usr/bin/env bash
# Compare local vs repo; suggest sync targets. User-facing messages in zh-CN.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOTFILES="$REPO_ROOT/dotfiles"

cursor_user_dir() {
  case "$(uname -s)" in
    Darwin) echo "$HOME/Library/Application Support/Cursor/User" ;;
    Linux)  echo "$HOME/.config/Cursor/User" ;;
    *)      echo "$HOME/AppData/Roaming/Cursor/User" ;;
  esac
}

diff_plain() {
  local label=$1 sync_hint=$2 local_f=$3 repo_f=$4
  if [ ! -f "$local_f" ]; then
    echo "  · $label：本机无此文件，已跳过"
    return 1
  fi
  if [ ! -f "$repo_f" ]; then
    echo "  · $label：仓库无对应源文件，已跳过"
    return 1
  fi
  if ! cmp -s "$local_f" "$repo_f" 2>/dev/null; then
    echo "  · $label：与本机不一致 → 可执行 $sync_hint 把本机写回仓库"
    return 0
  fi
  return 1
}

echo "=== check-sync：哪些配置和仓库不一致 ==="
echo ""
echo "【本段会检查】~/.zshrc、conf.d 下非模板的 .zsh、Claude settings/skills/MCP、Cursor User、~/.ssh"
echo ""

zsh_any=0
echo "--- Zsh ---"
if diff_plain "~/.zshrc" "make sync-zsh" "$HOME/.zshrc" "$DOTFILES/dot_zshrc"; then zsh_any=1; fi
shopt -s nullglob
for repo_f in "$DOTFILES/dot_config/zsh/conf.d"/*.zsh; do
  base=$(basename "$repo_f")
  if diff_plain "conf.d/$base" "make sync-zsh" "$HOME/.config/zsh/conf.d/$base" "$repo_f"; then zsh_any=1; fi
done
if [ "$zsh_any" -eq 0 ]; then
  echo "  （上述明文与仓库一致，或无可比文件）"
  echo "  （未对比：claude.zsh，由 KeePass + claude.zsh.tmpl 生成）"
fi
echo ""

claude_any=0
echo "--- Claude ---"
if diff_plain "settings.json" "make sync-claude" "$HOME/.claude/settings.json" "$DOTFILES/dot_claude/settings.json"; then claude_any=1; fi
if diff_plain "skills_manifest.txt" "make sync-claude" "$HOME/.claude/skills_manifest.txt" "$DOTFILES/dot_claude/skills_manifest.txt"; then claude_any=1; fi
if command -v jq >/dev/null 2>&1 && [ -f "$HOME/.claude.json" ] && [ -f "$DOTFILES/dot_claude/mcp_servers.json" ]; then
  if local_m=$(jq -c -S '.mcpServers // {}' "$HOME/.claude.json" 2>/dev/null) &&
    repo_m=$(jq -c -S '.' "$DOTFILES/dot_claude/mcp_servers.json" 2>/dev/null); then
    if [ "$local_m" != "$repo_m" ]; then
      echo "  · mcp_servers（~/.claude.json 的 mcpServers）：与仓库不一致 → 可执行 make sync-claude 写回"
      claude_any=1
    fi
  else
    echo "  · mcp_servers：无法解析 ~/.claude.json 或仓库 mcp_servers.json"
    claude_any=1
  fi
elif ! command -v jq >/dev/null 2>&1; then
  echo "  （未对比 mcp_servers.json：未安装 jq）"
fi
if [ "$claude_any" -eq 0 ]; then
  if command -v jq >/dev/null 2>&1 && [ -f "$HOME/.claude.json" ] && [ -f "$DOTFILES/dot_claude/mcp_servers.json" ]; then
    echo "  （Claude 与仓库一致）"
  elif ! command -v jq >/dev/null 2>&1; then
    echo "  （settings/skills 与仓库一致；mcp_servers 需 jq 才可对比）"
  elif [ ! -f "$HOME/.claude.json" ]; then
    echo "  （settings/skills 与仓库一致；无 ~/.claude.json，未对比 MCP）"
  elif [ ! -f "$DOTFILES/dot_claude/mcp_servers.json" ]; then
    echo "  （settings/skills 与仓库一致；仓库无 mcp_servers.json，未对比 MCP）"
  else
    echo "  （与仓库一致，或本机/仓库缺文件）"
  fi
fi
echo ""

echo "--- Cursor ---"
CU="$(cursor_user_dir)"
if [ -d "$CU" ] && command -v chezmoi >/dev/null 2>&1; then
  if out=$(chezmoi diff "$CU" 2>/dev/null) && [ -n "$out" ]; then
    echo "  Cursor User 与「chezmoi apply 将要写出的内容」不一致。"
    echo "  若本机修改才是你要的 → 执行 make sync-cursor"
  else
    echo "  （无差异，或 chezmoi diff 无输出）"
  fi
else
  echo "  （未找到 Cursor 目录或 chezmoi，已跳过）"
fi
echo ""

echo "--- SSH ---"
if [ -d "$HOME/.ssh" ] && command -v chezmoi >/dev/null 2>&1; then
  if out=$(chezmoi diff "$HOME/.ssh" 2>/dev/null) && [ -n "$out" ]; then
    echo "  ~/.ssh 与 chezmoi 目标不一致。"
    echo "  若要以本机为准写回仓库 → 执行 make sync-ssh"
  else
    echo "  （无差异，或 chezmoi diff 无输出）"
  fi
else
  echo "  （已跳过）"
fi
echo ""

echo "【本脚本不会逐项对比的跟踪项】"
echo "  · ~/.config/chezmoi/chezmoi.toml（模板 + KeePass 等）"
echo "  · ~/.kube/config（多为 age 加密源，用 make encrypt-kubeconfig 等）"
echo "  · ~/.config/keepassxc 等"
echo "  · 任意 *.tmpl 渲染结果与源的语义差异（需 apply 后看效果）"
echo ""
echo "【全面检查】对上述全部已管理文件执行："
echo "  chezmoi diff"
if command -v chezmoi >/dev/null 2>&1; then
  if full=$(chezmoi diff 2>/dev/null) && [ -n "$full" ]; then
    echo ""
    echo "【结果】当前 chezmoi diff 有输出 → 仍有路径与仓库/模板目标不一致，请打开终端查看完整 diff。"
  else
    echo ""
    echo "【结果】chezmoi diff 当前无输出（或与 check 无关的错误已忽略）。若需确认请在本机直接运行 chezmoi diff。"
  fi
fi
