# common: path and help

.PHONY: ensure-path help check-sync

help-common:
	@echo "  help                - 显示本帮助"
	@echo "  check-sync          - 中文列出与仓库不一致的配置及未覆盖项说明"

ensure-path:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/ensure-local-bin-in-path.sh"

check-sync:
	@bash "$(SCRIPT_DIR)/check-sync.sh"
