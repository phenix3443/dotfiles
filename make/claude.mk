# Claude Code: CLI app install and config sync

.PHONY: install-claude sync-claude apply-claude

help-claude:
	@echo "  install-claude      - 检测并安装 Claude Code CLI（macOS: brew cask / 官方脚本，Linux: 官方脚本 / npm）"
	@echo "  sync-claude         - 将 ~/.claude/settings.json 与 skills_manifest 原样拷回 dotfiles/dot_claude/"
	@echo "  apply-claude        - chezmoi 仅应用 ~/.claude（源文件为普通 JSON，非模板）"

install-claude:
	@sh "$(SCRIPT_DIR)/install-claude.sh"

sync-claude:
	@sh "$(SCRIPT_DIR)/sync-claude-config.sh"

apply-claude:
	@chezmoi apply "$$HOME/.claude"
