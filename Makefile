# Makefile for chezmoi setup (entry only; see make/*.mk for targets)
# Supports: Linux (apt/dnf/pacman/apk/zypper/xbps), macOS (Homebrew/MacPorts), Windows (winget/scoop/choco)

ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPT_DIR := $(ROOT)scripts
INSTALL_BIN ?= $(HOME)/.local/bin
PATH := $(INSTALL_BIN):$(PATH)
export PATH

include make/chezmoi.mk make/age.mk make/lefthook.mk make/gitleaks.mk make/add-skill.mk make/claude.mk make/cursor.mk make/zsh.mk make/ssh.mk make/kube.mk make/watcher.mk make/common.mk

.PHONY: install help
.PHONY: install-chezmoi install-age install-lefthook install-gitleaks install-add-skill install-claude install-rtk install-zsh-plugins
.PHONY: bootstrap-chezmoi-config encrypt-kubeconfig apply-cursor apply-claude apply-zsh sync-zsh apply-kube sync-kube check-sync sync-ssh apply-ssh watch-ssh install-ssh-watcher uninstall-ssh-watcher status-ssh-watcher logs-ssh-watcher watch-chezmoi install-chezmoi-watcher uninstall-chezmoi-watcher status-chezmoi-watcher logs-chezmoi-watcher
.PHONY: setup-hooks setup-age-keys ensure-path shellcheck lint
.PHONY: help-chezmoi help-age help-add-skill help-claude help-cursor help-zsh help-ssh help-kube help-watcher help-common

install: install-chezmoi install-age install-lefthook install-gitleaks install-add-skill install-claude install-rtk install-zsh-plugins setup-hooks ensure-path bootstrap-chezmoi-config

help: help-chezmoi help-add-skill help-claude help-cursor help-zsh help-ssh help-kube help-watcher help-age help-common
