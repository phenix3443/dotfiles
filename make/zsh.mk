# Zsh: apply and sync ~/.zshrc + ~/.config/zsh

.PHONY: apply-zsh sync-zsh help-zsh

help-zsh:
	@echo "  apply-zsh           - chezmoi apply ~/.zshrc and ~/.config/zsh only"
	@echo "  sync-zsh            - copy ~/.zshrc and conf.d/*.zsh to repo (skip claude.zsh)"

apply-zsh:
	@chezmoi apply "$$HOME/.zshrc" "$$HOME/.config/zsh"

sync-zsh:
	@bash "$(SCRIPT_DIR)/sync-zsh-config.sh"
