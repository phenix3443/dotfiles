# Claude Code: CLI app install and config sync

.PHONY: install-claude install-rtk sync-claude apply-claude sync-codex apply-codex

help-claude:
	@echo "  install-claude      - 检测并安装 Claude Code CLI（macOS: brew cask / 官方脚本，Linux: 官方脚本 / npm）"
	@echo "  install-rtk         - 检测并安装 RTK（Rust Token Killer）二进制（brew / install.sh / cargo）"
	@echo "  sync-claude         - 拷回 settings/skills/hooks/md；并从 ~/.claude.json 抽取 mcpServers 到 mcp_servers.json（需 jq）"
	@echo "  apply-claude        - chezmoi 仅应用 ~/.claude（含 hooks、CLAUDE.md 等）"
	@echo "  sync-codex          - 拷回 ~/.codex/config.toml 到 dotfiles/dot_codex/config.toml.tmpl"
	@echo "  apply-codex         - chezmoi 仅应用 ~/.codex"

install-claude:
	@sh "$(SCRIPT_DIR)/install-claude.sh"

install-rtk:
	@sh "$(SCRIPT_DIR)/install-rtk.sh"

sync-claude:
	@sh "$(SCRIPT_DIR)/sync-claude-config.sh"

apply-claude:
	@chezmoi apply "$$HOME/.claude"

sync-codex:
	@sh "$(SCRIPT_DIR)/sync-codex-config.sh"

apply-codex:
	@chezmoi apply "$$HOME/.codex"
