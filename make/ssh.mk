# SSH: Configuration sync and apply

.PHONY: sync-ssh apply-ssh watch-ssh install-ssh-watcher uninstall-ssh-watcher status-ssh-watcher logs-ssh-watcher help-ssh

help-ssh:
	@echo "  sync-ssh            - Sync local SSH config to repository"
	@echo "  apply-ssh           - Apply only SSH configuration via chezmoi (~/.ssh)"
	@echo "  watch-ssh           - Watch SSH config files and auto-sync on changes (foreground)"
	@echo "  install-ssh-watcher - Install SSH config watcher as background service"
	@echo "  uninstall-ssh-watcher - Uninstall SSH config watcher service"
	@echo "  status-ssh-watcher  - Show SSH config watcher service status"
	@echo "  logs-ssh-watcher    - Show SSH config watcher service logs"

sync-ssh:
	@sh "$(SCRIPT_DIR)/sync-ssh-config.sh"

apply-ssh:
	@chezmoi apply "$$HOME/.ssh"

watch-ssh:
	@sh "$(SCRIPT_DIR)/watch-ssh-config.sh"

install-ssh-watcher:
	@sh "$(SCRIPT_DIR)/install-ssh-watcher.sh" install

uninstall-ssh-watcher:
	@sh "$(SCRIPT_DIR)/install-ssh-watcher.sh" uninstall

status-ssh-watcher:
	@sh "$(SCRIPT_DIR)/install-ssh-watcher.sh" status

logs-ssh-watcher:
	@sh "$(SCRIPT_DIR)/install-ssh-watcher.sh" logs
