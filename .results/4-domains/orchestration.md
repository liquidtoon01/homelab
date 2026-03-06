# Orchestration Domain

## Overview
This domain defines how playbooks, inventory, and Make targets orchestrate the execution of roles and manage the infrastructure lifecycle.

## Playbook Structure

### Master Playbook (site.yml)
Imports all other playbooks in correct order:

```yaml
---
# Main playbook - runs all provisioning tasks
- name: Import infrastructure playbook
  ansible.builtin.import_playbook: infrastructure.yml

- name: Import applications playbook
  ansible.builtin.import_playbook: applications.yml
```

Pattern:
- Use `import_playbook` (static import, runs at parse time)
- Infrastructure before applications
- Clear execution order

### Infrastructure Playbook (infrastructure.yml)
Provisions base infrastructure:

```yaml
---
# Infrastructure components playbook
- name: Install Infrastructure Components
  hosts: all
  become: yes
  
  roles:
    - role: base
      tags: ['base', 'infrastructure']
    
    - role: apt_updates
      tags: ['apt_updates', 'infrastructure']
    
    - role: kubectl
      tags: ['kubectl', 'infrastructure']
    
    - role: helm
      tags: ['helm', 'infrastructure']
    
    - role: minikube
      tags: ['minikube', 'infrastructure']
    
    - role: tailscale
      tags: ['tailscale', 'infrastructure']
```

Pattern:
- Single play targeting `all` hosts
- `become: yes` at play level (can override at task level)
- Roles listed in dependency order
- Each role tagged with component and category

### Applications Playbook (applications.yml)
Deploys applications to Kubernetes:

```yaml
---
# Helm applications playbook
- name: Deploy Helm Applications
  hosts: all
  become: yes
  
  roles:
    - role: helm_apps
      tags: ['applications', 'helm']
```

Pattern:
- Single role containing all applications
- Applications split via include_tasks within role

### Backup Playbook (backup.yml)
Operational task playbook:

```yaml
---
- name: Backup Minikube Volumes
  hosts: all
  become: yes
  
  roles:
    - role: backup
      tags: ['backup']
```

## Execution Order

### Correct Sequence
1. **site.yml** → imports infrastructure.yml → imports applications.yml
2. **infrastructure.yml** executes:
   - base (Docker, system packages)
   - apt_updates (security updates)
   - kubectl (Kubernetes CLI)
   - helm (Helm package manager)
   - minikube (Kubernetes cluster) - requires Docker
   - tailscale (VPN)
3. **applications.yml** executes:
   - helm_apps (all applications) - requires kubectl, helm, minikube

### Why This Order Matters
- Docker must exist before Minikube (uses Docker driver)
- kubectl/helm must exist before deploying applications
- Minikube must be running before kubectl/helm commands
- Tailscale should be configured before Tailscale Operator

## Tag-Based Execution

### Infrastructure Tags
Run specific infrastructure components:

```bash
# Install only Docker and system packages
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml --tags base

# Install only Minikube
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml --tags minikube

# Install all infrastructure
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml --tags infrastructure
```

### Application Tags
Deploy or update applications:

```bash
# Deploy all applications
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml --tags applications

# Deploy only Helm apps
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml --tags helm
```

### Component-Specific Tags
Each role has its own tag:

```yaml
roles:
  - role: base
    tags: ['base', 'infrastructure']
  - role: minikube
    tags: ['minikube', 'infrastructure']
```

Execute single component:
```bash
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml --tags kubectl
```

## Makefile Wrapper

### Make Targets
Simplified interface to complex ansible-playbook commands:

**From Makefile:**
```makefile
install: ## Install everything (infrastructure + applications)
	@echo "Installing all components..."
	ansible-playbook -i inventory/hosts.yml playbooks/site.yml

install-infrastructure: ## Install only infrastructure components
	@echo "Installing infrastructure components..."
	ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml

install-apps: ## Install only applications
	@echo "Installing applications..."
	ansible-playbook -i inventory/hosts.yml playbooks/applications.yml

backup: ## Backup Minikube volumes and send via Tailscale
	@echo "Creating backup of Minikube volumes..."
	ansible-playbook -i inventory/hosts.yml playbooks/backup.yml
```

### Status and Monitoring Targets
```makefile
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
```

### Cleanup Targets
```makefile
clean-minikube: ## Delete Minikube cluster
	@echo "Deleting Minikube cluster..."
	minikube delete

clean-apps: ## Uninstall all applications
	@echo "Uninstalling applications..."
	helm uninstall gogs -n git || true
	helm uninstall sonarr -n media || true
	helm uninstall qbittorrent -n media || true
	helm uninstall pihole -n pihole || true
	kubectl delete namespace git media pihole || true
```

### Log Viewing Targets
```makefile
logs-gogs: ## Show Gogs logs
	kubectl logs -n git -l app=gogs --tail=100

logs-sonarr: ## Show Sonarr logs
	kubectl logs -n media -l app.kubernetes.io/name=sonarr --tail=100

logs-qbittorrent: ## Show qBittorrent logs
	kubectl logs -n media -l app.kubernetes.io/name=qbittorrent --tail=100
```

## Inventory Configuration

### Default Inventory (inventory/hosts.yml)
```yaml
---
all:
  hosts:
    kimsufi:
      ansible_host: localhost
      ansible_connection: local
      # For remote host, use:
      # ansible_host: your.server.ip
      # ansible_user: your_user
      # ansible_ssh_private_key_file: ~/.ssh/id_rsa
  
  children:
    kubernetes:
      hosts:
        kimsufi:
```

Pattern:
- `all` group contains all hosts
- Default to localhost with local connection
- Comments show remote configuration
- `children` groups for logical organization

### Inventory Specification
All playbook commands must specify inventory:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

ansible.cfg references inventory but helps with defaults:
```properties
[defaults]
inventory = inventory/hosts.yml
```

## Privilege Escalation

### Play-Level Privilege
```yaml
- name: Install Infrastructure Components
  hosts: all
  become: yes  # Default to root for this play
  
  roles:
    - role: base
```

All tasks in play run as root unless overridden.

### Task-Level Override
```yaml
- name: Start Minikube cluster
  ansible.builtin.command: minikube start
  become: no  # Override: run as regular user
```

## Execution Patterns

### Full Installation
```bash
# Using Make
make install

# Using Ansible directly
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

### Partial Installation
```bash
# Infrastructure only
make install-infrastructure

# Applications only
make install-apps
```

### Selective Execution
```bash
# Single component
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml --tags minikube

# Multiple components
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml --tags "kubectl,helm"
```

### Dry Run (Check Mode)
```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --check
```

### Verbose Output
```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -v
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -vv
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -vvv
```

## Bootstrap Workflow

Complete setup from scratch:

```bash
# 1. Clone repository
git clone https://github.com/YOUR_USERNAME/homelab.git
cd homelab

# 2. Bootstrap Ansible
sudo bash bootstrap.sh

# 3. Configure secrets (optional)
bash setup-vault.sh

# 4. Run full installation
make install

# 5. Check status
make status
```

## ansible.cfg Configuration

**From ansible.cfg:**
```properties
[defaults]
inventory = inventory/hosts.yml
roles_path = roles
host_key_checking = False
retry_files_enabled = False
stdout_callback = ansible.builtin.default
result_format = yaml
interpreter_python = auto_silent
vault_password_file = .vault_pass

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
```

Key settings:
- Default inventory location
- Automatic Python interpreter detection
- Default privilege escalation (can override)
- SSH pipelining for performance
- Vault password file for automatic decryption

## Error Handling

### Continue on Error (where appropriate)
```yaml
- name: Create Gogs namespace
  ansible.builtin.command: kubectl create namespace {{ gogs_namespace }}
  failed_when: false  # Don't stop if namespace exists
  changed_when: false
```

### Stop on Critical Error
```yaml
- name: Fail if backup source does not exist
  ansible.builtin.fail:
    msg: "Backup source directory {{ backup_source_dir }} does not exist"
  when: not backup_source.stat.exists
```

## Constraints
- Playbooks must be run from repository root
- Inventory must be specified (either in command or ansible.cfg)
- Infrastructure playbook must run before applications playbook
- All playbooks target `all` hosts (single-host design)
- Make targets assume system commands (minikube, kubectl) are in PATH
- Privilege escalation configured at play level, overridden at task level
- No parallel execution across multiple hosts (single host focus)
- Vault password file must exist if using encrypted variables
- Roles have no dependencies (order enforced via playbooks only)
