# age: encryption and key setup

.PHONY: install-age setup-age-keys

help-age:
	@echo "  setup-age-keys        - 生成 age 密钥并写入 chezmoi.toml.tmpl 的 recipient（首次使用 age 加密前执行）"

install-age:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-age.sh"

setup-age-keys:
	@ROOT="$(ROOT)" sh "$(SCRIPT_DIR)/age-keys-configure.sh"
