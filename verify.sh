#!/bin/bash
# Verification script to check if all files are in place

set -e

echo "=== Kimsufi Infrastructure Verification ==="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 (missing)"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1/"
        return 0
    else
        echo -e "${RED}✗${NC} $1/ (missing)"
        return 1
    fi
}

echo "Checking project structure..."
echo ""

# Root files
check_file "README.md"
check_file "GETTING_STARTED.md"
check_file "QUICKSTART.md"
check_file "CHANGELOG.md"
check_file "REQUIREMENTS.md"
check_file "PROJECT_STRUCTURE.md"
check_file "Makefile"
check_file ".gitignore"
check_file "bootstrap.sh"
check_file "ansible.cfg"

echo ""

# Directories
check_dir "inventory"
check_dir "group_vars"
check_dir "playbooks"
check_dir "roles"
check_dir "docs"

echo ""

# Inventory
check_file "inventory/hosts.yml"

echo ""

# Group vars
check_file "group_vars/all.yml"

echo ""

# Playbooks
check_file "playbooks/site.yml"
check_file "playbooks/infrastructure.yml"
check_file "playbooks/applications.yml"

echo ""

# Roles
ROLES=("base" "kubectl" "helm" "minikube" "tailscale" "apt_updates" "helm_apps")
for role in "${ROLES[@]}"; do
    check_dir "roles/$role"
    check_dir "roles/$role/tasks"
    check_file "roles/$role/tasks/main.yml"
    check_file "roles/$role/meta/main.yml"
done

echo ""

# Helm apps tasks
check_file "roles/helm_apps/tasks/tailscale-operator.yml"
check_file "roles/helm_apps/tasks/storage.yml"
check_file "roles/helm_apps/tasks/gitea.yml"
check_file "roles/helm_apps/tasks/sonarr.yml"
check_file "roles/helm_apps/tasks/headscale.yml"
check_file "roles/helm_apps/tasks/qbittorrent.yml"
check_file "roles/helm_apps/tasks/pihole.yml"

echo ""

# Documentation
check_file "docs/bootstrap.md"
check_file "docs/ssh-security.md"
check_file "docs/infrastructure.md"
check_file "docs/tailscale-operator.md"
check_file "docs/applications.md"
check_file "docs/troubleshooting.md"

echo ""
echo "=== Verification Complete ==="
echo ""
echo "Next steps:"
echo "1. Review and customize group_vars/all.yml"
echo "2. Run: sudo ./bootstrap.sh"
echo "3. Run: ansible-playbook -i inventory/hosts.yml playbooks/site.yml"
echo ""
