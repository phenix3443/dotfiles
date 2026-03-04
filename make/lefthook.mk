# lefthook: git hooks

.PHONY: install-lefthook setup-hooks

install-lefthook:
	@sh "$(SCRIPT_DIR)/install-lefthook.sh"

setup-hooks:
	@if command -v lefthook >/dev/null 2>&1; then \
		lefthook install; \
		echo "Git hooks installed successfully"; \
	else \
		echo "lefthook not found, run 'make install-lefthook' first"; \
		exit 1; \
	fi
