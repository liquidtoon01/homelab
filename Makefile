# Makefile for Kimsufi Infrastructure

.PHONY: help bootstrap install install-infrastructure install-apps status clean check

help: ## Show this help message
	@echo "Kimsufi Infrastructure Management"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Install Ansible on the system
	@echo "Running bootstrap script..."
	sudo bash bootstrap.sh

install: ## Install everything (infrastructure + applications)
	@echo "Installing all components..."
	ansible-playbook -i inventory/hosts.yml playbooks/site.yml

install-infrastructure: ## Install only infrastructure components
	@echo "Installing infrastructure components..."
	ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml

install-apps: ## Install only applications
	@echo "Installing applications..."
	ansible-playbook -i inventory/hosts.yml playbooks/applications.yml

status: ## Show status of all components
	@echo "=== Minikube Status ==="
	minikube status || true
	@echo ""
	@echo "=== Kubernetes Nodes ==="
	kubectl get nodes || true
	@echo ""
	@echo "=== All Pods ==="
	kubectl get pods --all-namespaces || true
	@echo ""
	@echo "=== All Services ==="
	kubectl get svc --all-namespaces || true
	@echo ""
	@echo "=== Tailscale Status ==="
	tailscale status || true

services: ## List all service URLs
	@echo "=== Service URLs ==="
	minikube service list

check: ## Check for common issues
	@echo "Running system checks..."
	@echo ""
	@echo "=== Docker Status ==="
	docker --version
	sudo systemctl status docker --no-pager || true
	@echo ""
	@echo "=== Disk Space ==="
	df -h / | grep -v tmpfs
	@echo ""
	@echo "=== Memory ==="
	free -h
	@echo ""
	@echo "=== Ansible Version ==="
	ansible --version || echo "Ansible not installed. Run 'make bootstrap'"

clean-minikube: ## Delete Minikube cluster
	@echo "Deleting Minikube cluster..."
	minikube delete

clean-apps: ## Uninstall all applications
	@echo "Uninstalling applications..."
	helm uninstall gitea -n gitea || true
	helm uninstall sonarr -n media || true
	helm uninstall qbittorrent -n media || true
	helm uninstall headscale -n headscale || true
	helm uninstall pihole -n pihole || true
	kubectl delete namespace gitea media headscale pihole || true

logs-gitea: ## Show Gitea logs
	kubectl logs -n gitea -l app.kubernetes.io/name=gitea --tail=100

logs-sonarr: ## Show Sonarr logs
	kubectl logs -n media -l app.kubernetes.io/name=sonarr --tail=100

logs-qbittorrent: ## Show qBittorrent logs
	kubectl logs -n media -l app.kubernetes.io/name=qbittorrent --tail=100

logs-headscale: ## Show Headscale logs
	kubectl logs -n headscale -l app.kubernetes.io/name=headscale --tail=100

logs-pihole: ## Show Pi-hole logs
	kubectl logs -n pihole -l app=pihole --tail=100
