# SSH: Configuration sync and apply

.PHONY: sync-ssh apply-ssh help-ssh

help-ssh:
	@echo "  sync-ssh            - Sync local SSH config to repository"
	@echo "  apply-ssh           - Apply only SSH configuration via chezmoi (~/.ssh)"

sync-ssh:
	@sh "$(SCRIPT_DIR)/sync-ssh-config.sh"

apply-ssh:
	@chezmoi apply "$$HOME/.ssh"
