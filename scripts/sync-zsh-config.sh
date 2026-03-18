#!/usr/bin/env bash
# Sync ~/.zshrc and ~/.config/zsh/conf.d/*.zsh into chezmoi source.
# Skips claude.zsh (generated from claude.zsh.tmpl + KeePassXC; do not copy plaintext token).

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOTFILES="$REPO_ROOT/dotfiles"
ZSHRC_LOCAL="${HOME}/.zshrc"
ZSHRC_REPO="${DOTFILES}/dot_zshrc"
CONFD_LOCAL="${HOME}/.config/zsh/conf.d"
CONFD_REPO="${DOTFILES}/dot_config/zsh/conf.d"

if [ ! -f "$ZSHRC_LOCAL" ]; then
  echo "Error: $ZSHRC_LOCAL not found" >&2
  exit 1
fi

if [ ! -d "$CONFD_LOCAL" ]; then
  echo "Error: $CONFD_LOCAL not found" >&2
  exit 1
fi

echo "=== Syncing Zsh configuration ==="
echo ""

echo "dot_zshrc <- ~/.zshrc"
cp "$ZSHRC_LOCAL" "$ZSHRC_REPO"

synced=0
skipped=0
shopt -s nullglob
for f in "$CONFD_LOCAL"/*.zsh; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  case "$base" in
    claude.zsh)
      echo "skip $base (managed by claude.zsh.tmpl + KeePassXC)"
      skipped=$((skipped + 1))
      continue
      ;;
  esac
  echo "conf.d/$base <- ~/.config/zsh/conf.d/$base"
  cp "$f" "$CONFD_REPO/$base"
  synced=$((synced + 1))
done

echo ""
echo "Done: $synced conf.d file(s) copied, $skipped skipped."
echo "Next: cd $REPO_ROOT && git diff dotfiles/dot_zshrc dotfiles/dot_config/zsh/conf.d/"
