# Cursor: Configuration sync

.PHONY: sync-cursor help-cursor

help-cursor:
	@echo "  sync-cursor         - Sync local Cursor config to repository (preserves template placeholders)"

sync-cursor:
	@sh "$(SCRIPT_DIR)/sync-cursor-config.sh"
