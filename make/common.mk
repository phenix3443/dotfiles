# common: path and help

.PHONY: ensure-path help check-sync shellcheck lint

help-common:
	@echo "  help                - 显示本帮助"
	@echo "  check-sync          - 中文列出与仓库不一致的配置及未覆盖项说明"
	@echo "  shellcheck          - 运行 shellcheck 检查所有脚本（与 CI 一致）"
	@echo "  lint                - shellcheck 的别名"

ensure-path:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/ensure-local-bin-in-path.sh"

check-sync:
	@bash "$(SCRIPT_DIR)/check-sync.sh"

shellcheck:
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo "Error: shellcheck not found. Install it with: brew install shellcheck (macOS) or apt install shellcheck (Linux)" >&2; \
		exit 1; \
	fi
	@echo "Running shellcheck on all scripts..."
	@find scripts -name "*.sh" -type f -exec shellcheck {} +

lint: shellcheck
