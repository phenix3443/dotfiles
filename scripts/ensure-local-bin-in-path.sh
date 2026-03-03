#!/usr/bin/env sh
# 检测当前 shell 配置是否将 INSTALL_BIN（默认 ~/.local/bin）加入 PATH，
# 若未加入则追加一行，使 gitleaks 等工具在终端中可用（含 lefthook pre-commit）。

set -e

INSTALL_BIN="${INSTALL_BIN:-$HOME/.local/bin}"

# 根据默认 shell 选择配置文件（make 下用 SHELL，未设则优先 zsh）
choose_rc() {
  case "${SHELL:-}" in
    *zsh*)  echo "$HOME/.zshrc" ;;
    *bash*) echo "$HOME/.bashrc" ;;
    *)      echo "$HOME/.zshrc" ;;  # 默认 zsh 常见
  esac
}

RC="$(choose_rc)"
# 若配置文件不存在则创建
[ -f "$RC" ] || touch "$RC"

# 是否已包含将 .local/bin 加入 PATH 的配置（避免重复）
already_has_path() {
  grep -qE '\.local/bin.*PATH|PATH.*\.local/bin' "$RC" 2>/dev/null || false
}

LINE='export PATH="$HOME/.local/bin:$PATH"'

if already_has_path; then
  echo "PATH already includes ~/.local/bin in $RC"
  exit 0
fi

echo "" >> "$RC"
echo "# added by chezmoi make install: ensure gitleaks etc. are in PATH" >> "$RC"
echo "$LINE" >> "$RC"
echo "Added to $RC: $LINE"
echo "Run: source $RC  (or open a new terminal)"
