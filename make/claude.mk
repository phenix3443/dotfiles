# Claude Code: CLI app install

.PHONY: install-claude

help-claude:
	@echo "  install-claude      - 检测并安装 Claude Code CLI（macOS: brew cask / 官方脚本，Linux: 官方脚本 / npm）"

install-claude:
	@sh "$(SCRIPT_DIR)/install-claude.sh"
