# Makefile for chezmoi + KeePassXC setup
# Supports: Linux (apt/dnf/pacman/apk/zypper/xbps), macOS (Homebrew/MacPorts), Windows (winget/scoop/choco)

ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPT_DIR := $(ROOT)scripts
INSTALL_BIN ?= $(HOME)/.local/bin
PATH := $(INSTALL_BIN):$(PATH)
export PATH

.PHONY: install install-chezmoi install-keepassxc-cli install-lefthook install-gitleaks keepassxc-entry add show edit rm ls search check-keepassxc install-deps setup-hooks help test

help:
	@echo "Targets:"
	@echo "  install             - Install all dependencies (chezmoi, keepassxc-cli, lefthook, gitleaks)"
	@echo "  install-chezmoi     - Install chezmoi only"
	@echo "  install-keepassxc-cli - Install keepassxc-cli (via keepassxc package) only"
	@echo "  install-lefthook    - Install lefthook only"
	@echo "  install-gitleaks    - Install gitleaks only"
	@echo "  setup-hooks         - Setup git hooks with lefthook"
	@echo "  keepassxc-entry [cmd] - KeePassXC entry CRUD (add|show|edit|rm|ls|search)"
	@echo "  check-keepassxc     - Check KeePassXC database and Claude Code entry"
	@echo "  install-deps        - Alias for install (installs all dependencies)"
	@echo "  test                - Run keepassxc-entry tests"

install: install-chezmoi install-keepassxc-cli install-lefthook install-gitleaks setup-hooks

install-deps: install

install-chezmoi:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-chezmoi.sh"

install-keepassxc-cli:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-keepassxc-cli.sh"

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

keepassxc-entry:
	@sh "$(SCRIPT_DIR)/keepassxc-entry.sh" $(filter-out $@,$(MAKECMDGOALS))

add show edit rm ls search:
	@:

check-keepassxc:
	@sh "$(SCRIPT_DIR)/check-keepassxc.sh"

test:
	@sh "$(ROOT)tests/test_keepassxc_entry.sh"
