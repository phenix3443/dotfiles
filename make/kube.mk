# Kubernetes: apply and sync kubeconfig

.PHONY: apply-kube sync-kube encrypt-kubeconfig help-kube

help-kube:
	@echo "  apply-kube          - chezmoi apply ~/.kube/config only (decrypt from age)"
	@echo "  sync-kube           - encrypt ~/.kube/config to repo"
	@echo "  encrypt-kubeconfig  - (alias for sync-kube)"

apply-kube:
	@chezmoi apply "$$HOME/.kube/config"

sync-kube:
	@ROOT="$(ROOT)" sh "$(SCRIPT_DIR)/encrypt-kubeconfig.sh"

encrypt-kubeconfig: sync-kube
