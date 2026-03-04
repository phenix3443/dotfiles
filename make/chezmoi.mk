# chezmoi: bootstrap and install

.PHONY: bootstrap-chezmoi-config install-chezmoi

help-chezmoi:
	@echo "  install             - 安装使用 chezmoi 与在 dotfiles 仓库编辑所需的全部依赖并配置 git hooks（一键准备就绪）"
	@echo "  bootstrap-chezmoi-config - 首次 apply 前：引导 config（encryption、age、keepassxc）"

bootstrap-chezmoi-config:
	@sh "$(ROOT)scripts/bootstrap-chezmoi-config.sh"

install-chezmoi:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-chezmoi.sh"
