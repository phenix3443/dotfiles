# Chezmoi File Watcher: Auto-sync all managed files

.PHONY: watch-chezmoi install-chezmoi-watcher uninstall-chezmoi-watcher status-chezmoi-watcher logs-chezmoi-watcher help-watcher

help-watcher:
	@echo "  watch-chezmoi           - Watch all chezmoi-managed files and auto-sync (foreground)"
	@echo "  install-chezmoi-watcher - Install chezmoi file watcher as background service"
	@echo "  uninstall-chezmoi-watcher - Uninstall chezmoi file watcher service"
	@echo "  status-chezmoi-watcher  - Show chezmoi file watcher service status"
	@echo "  logs-chezmoi-watcher    - Show chezmoi file watcher service logs"

watch-chezmoi:
	@sh "$(SCRIPT_DIR)/watch-chezmoi-files.sh"

install-chezmoi-watcher:
	@sh "$(SCRIPT_DIR)/install-chezmoi-watcher.sh" install

uninstall-chezmoi-watcher:
	@sh "$(SCRIPT_DIR)/install-chezmoi-watcher.sh" uninstall

status-chezmoi-watcher:
	@sh "$(SCRIPT_DIR)/install-chezmoi-watcher.sh" status

logs-chezmoi-watcher:
	@sh "$(SCRIPT_DIR)/install-chezmoi-watcher.sh" logs
