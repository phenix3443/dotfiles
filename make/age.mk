# age: encryption and key setup

.PHONY: install-age setup-age-keys encrypt-kubeconfig

help-age:
	@echo "  setup-age-keys      - 生成 age 密钥并写入 chezmoi.toml.tmpl 的 recipient（首次使用 age 加密前执行）"
	@echo "  encrypt-kubeconfig  - 用 age 加密 ~/.kube/config 到 private_dot_kube/config.age"

install-age:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-age.sh"

setup-age-keys:
	@ROOT="$(ROOT)" sh "$(SCRIPT_DIR)/age-keys-configure.sh"

encrypt-kubeconfig:
	@ROOT="$(ROOT)" sh "$(SCRIPT_DIR)/encrypt-kubeconfig.sh"
