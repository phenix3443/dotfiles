# Claude Code: CLI app install and config sync

.PHONY: install-claude sync-claude apply-claude

help-claude:
	@echo "  install-claude      - 检测并安装 Claude Code CLI（macOS: brew cask / 官方脚本，Linux: 官方脚本 / npm）"
	@echo "  sync-claude         - Sync local Claude config to repository (preserves template placeholders)"
	@echo "  apply-claude        - Apply only Claude configuration via chezmoi (~/.claude)"

install-claude:
	@sh "$(SCRIPT_DIR)/install-claude.sh"

sync-claude:
	@sh "$(SCRIPT_DIR)/sync-claude-config.sh"

apply-claude:
	@chezmoi apply "$$HOME/.claude"
