# Zsh: apply and sync ~/.zshrc + ~/.config/zsh

.PHONY: install-zsh-plugins apply-zsh sync-zsh help-zsh

help-zsh:
	@echo "  install-zsh-plugins - ensure Homebrew and zsh plugins (syntax-highlighting, autosuggestions) are installed"
	@echo "  apply-zsh           - ensure zsh plugins installed, then chezmoi apply ~/.zshrc and ~/.config/zsh"
	@echo "  sync-zsh            - copy ~/.zshrc and conf.d/*.zsh to repo (skip 30-claude.zsh)"

install-zsh-plugins:
	@sh "$(SCRIPT_DIR)/ensure-zsh-plugins.sh"

apply-zsh:
	@sh "$(SCRIPT_DIR)/ensure-zsh-plugins.sh"
	@chezmoi apply "$$HOME/.zshrc" "$$HOME/.config/zsh"

sync-zsh:
	@bash "$(SCRIPT_DIR)/sync-zsh-config.sh"
