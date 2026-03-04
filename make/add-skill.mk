# add-skill: Claude Code skills CLI

.PHONY: install-add-skill

help-add-skill:
	@echo "  install-add-skill    - 安装 add-skill CLI 到 INSTALL_BIN（用于安装 Claude Code skills）"

install-add-skill:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-add-skill.sh"
