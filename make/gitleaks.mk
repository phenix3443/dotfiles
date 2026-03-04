# gitleaks: secret detection

.PHONY: install-gitleaks

install-gitleaks:
	@INSTALL_BIN="$(INSTALL_BIN)" sh "$(SCRIPT_DIR)/install-gitleaks.sh"
