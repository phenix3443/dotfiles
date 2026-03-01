# Makefile for chezmoi + KeePassXC setup
# Supports: Linux (apt/dnf/pacman/apk/zypper/xbps), macOS (Homebrew/MacPorts), Windows (winget/scoop/choco)

ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPT_DIR := $(ROOT)scripts
INSTALL_BIN ?= $(HOME)/.local/bin
PATH := $(INSTALL_BIN):$(PATH)
export PATH

.PHONY: install install-chezmoi install-keepassxc-cli keepassxc-entry add show edit rm ls search check-keepassxc install-deps help test

help:
	@echo "Targets:"
	@echo "  install             - Install both chezmoi and keepassxc-cli"
	@echo "  install-chezmoi     - Install chezmoi only"
	@echo "  install-keepassxc-cli - Install keepassxc-cli (via keepassxc package) only"
	@echo "  keepassxc-entry [cmd] - KeePassXC entry CRUD (add|show|edit|rm|ls|search)"
	@echo "  check-keepassxc     - Check KeePassXC database and Claude Code entry"
	@echo "  install-deps        - Alias for install (installs all dependencies)"
	@echo "  test                - Run keepassxc-entry tests"

install: install-chezmoi install-keepassxc-cli

install-deps: install

install-chezmoi:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-chezmoi.sh"

install-keepassxc-cli:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-keepassxc-cli.sh"

keepassxc-entry:
	@sh "$(SCRIPT_DIR)/keepassxc-entry.sh" $(filter-out $@,$(MAKECMDGOALS))

add show edit rm ls search:
	@:

check-keepassxc:
	@sh "$(SCRIPT_DIR)/check-keepassxc.sh"

test:
	@sh "$(ROOT)tests/test_keepassxc_entry.sh"
