# Makefile for chezmoi + KeePassXC setup
# Supports: Linux (apt/dnf/pacman/apk/zypper/xbps), macOS (Homebrew/MacPorts), Windows (winget/scoop/choco)

ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPT_DIR := $(ROOT)scripts
INSTALL_BIN ?= $(HOME)/.local/bin
PATH := $(INSTALL_BIN):$(PATH)
export PATH

.PHONY: install install-chezmoi install-keepassxc-cli install-age install-lefthook install-gitleaks keepassxc-entry add show edit rm ls search setup-hooks setup-age-keys ensure-path help test

help:
	@echo "Targets:"
	@echo "  install             - 安装使用 chezmoi 与在 dotfiles 仓库编辑所需的全部依赖并配置 git hooks（一键准备就绪）"
	@echo "  setup-age-keys      - 生成 age 密钥并写入 chezmoi.toml.tmpl 的 recipient（首次使用 age 加密前执行）"
	@echo "  keepassxc-entry [cmd] - KeePassXC 条目管理（add|show|edit|rm|ls|search）"
	@echo "  test                - 运行 keepassxc-entry 测试"
	@echo "  help                - 显示本帮助"

install: install-chezmoi install-keepassxc-cli install-age install-lefthook install-gitleaks setup-hooks ensure-path

install-chezmoi:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-chezmoi.sh"

install-keepassxc-cli:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-keepassxc-cli.sh"

install-age:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-age.sh"

install-lefthook:
	@sh "$(SCRIPT_DIR)/install-lefthook.sh"

install-gitleaks:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-gitleaks.sh"

setup-hooks:
	@if command -v lefthook >/dev/null 2>&1; then \
		lefthook install; \
		echo "Git hooks installed successfully"; \
	else \
		echo "lefthook not found, run 'make install-lefthook' first"; \
		exit 1; \
	fi

ensure-path:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/ensure-local-bin-in-path.sh"

setup-age-keys:
	@ROOT="$(ROOT)" sh "$(SCRIPT_DIR)/age-keys-configure.sh"

keepassxc-entry:
	@sh "$(SCRIPT_DIR)/keepassxc-entry.sh" $(filter-out $@,$(MAKECMDGOALS))

add show edit rm ls search:
	@:

test:
	@sh "$(ROOT)tests/test_keepassxc_entry.sh"
