# Cursor: Configuration sync and apply

.PHONY: sync-cursor apply-cursor help-cursor

help-cursor:
	@echo "  sync-cursor         - Sync local Cursor config to repository (preserves template placeholders)"
	@echo "  apply-cursor        - Apply only Cursor configuration via chezmoi"

sync-cursor:
	@sh "$(SCRIPT_DIR)/sync-cursor-config.sh"

apply-cursor:
	@case "$$(uname -s)" in \
		Darwin) chezmoi apply "$$HOME/Library/Application Support/Cursor" ;; \
		Linux)  chezmoi apply "$$HOME/.config/Cursor" ;; \
		*)      chezmoi apply "$$HOME/AppData/Roaming/Cursor" ;; \
	esac
