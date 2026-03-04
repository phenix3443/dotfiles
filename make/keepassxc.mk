# KeePassXC: CLI install and entry management

.PHONY: install-keepassxc-cli keepassxc-entry add show edit rm ls search test

help-keepassxc:
	@echo "  keepassxc-entry [cmd] - KeePassXC 条目管理（add|show|edit|rm|ls|search）"
	@echo "  test                - 运行 keepassxc-entry 测试"

install-keepassxc-cli:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-keepassxc-cli.sh"

keepassxc-entry:
	@sh "$(SCRIPT_DIR)/keepassxc-entry.sh" $(filter-out $@,$(MAKECMDGOALS))

add show edit rm ls search:
	@:

test:
	@sh "$(ROOT)tests/test_keepassxc_entry.sh"
