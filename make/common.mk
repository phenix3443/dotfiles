# common: path and help

.PHONY: ensure-path help

help-common:
	@echo "  help                - 显示本帮助"

ensure-path:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/ensure-local-bin-in-path.sh"
