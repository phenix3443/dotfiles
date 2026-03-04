# Makefile for chezmoi + KeePassXC setup (entry only; see make/*.mk for targets)
# Supports: Linux (apt/dnf/pacman/apk/zypper/xbps), macOS (Homebrew/MacPorts), Windows (winget/scoop/choco)

ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPT_DIR := $(ROOT)scripts
INSTALL_BIN ?= $(HOME)/.local/bin
PATH := $(INSTALL_BIN):$(PATH)
export PATH

include make/chezmoi.mk make/keepassxc.mk make/age.mk make/lefthook.mk make/gitleaks.mk make/add-skill.mk make/claude.mk make/common.mk

.PHONY: install help
.PHONY: install-chezmoi install-keepassxc-cli install-age install-lefthook install-gitleaks install-add-skill install-claude
.PHONY: keepassxc-entry bootstrap-chezmoi-config encrypt-kubeconfig add show edit rm ls search
.PHONY: setup-hooks setup-age-keys ensure-path test
.PHONY: help-chezmoi help-keepassxc help-age help-add-skill help-claude help-common

install: install-chezmoi install-keepassxc-cli install-age install-lefthook install-gitleaks install-add-skill install-claude setup-hooks ensure-path bootstrap-chezmoi-config

help: help-chezmoi help-add-skill help-claude help-age help-keepassxc help-common
