# Configuration Management Domain

## Overview
This domain manages variables, inventory, secrets, and configuration across the entire infrastructure using Ansible's variable hierarchy and Vault encryption.

## Variable Hierarchy

### Global Variables (group_vars/all.yml)
Defines configuration used across all hosts:

```yaml
---
# Global variables for all hosts

# Minikube configuration
minikube_version: "latest"
minikube_driver: "docker"
minikube_cpus: 2
minikube_memory: "4096"
minikube_disk_size: "20g"

# kubectl configuration
kubectl_version: "latest"

# Helm configuration
helm_version: "latest"

# Tailscale configuration
# Set actual value in group_vars/vault.yml (encrypted)
tailscale_auth_key: "{{ vault_tailscale_auth_key | default('') }}"

# Tailscale Operator configuration
# Create OAuth client at: https://login.tailscale.com/admin/settings/oauth
# Set actual values in group_vars/vault.yml (encrypted)
tailscale_oauth_client_id: "{{ vault_tailscale_oauth_client_id | default('') }}"
tailscale_oauth_client_secret: "{{ vault_tailscale_oauth_client_secret | default('') }}"
tailscale_operator_hostname: "ts-operator"

# Tailscale Ingress hostnames (customize as needed)
tailscale_gogs_hostname: "gogs"
tailscale_gogs_ssh_hostname: "gogs-ssh"
tailscale_sonarr_hostname: "sonarr"
tailscale_qbittorrent_hostname: "qbittorrent"
tailscale_pihole_hostname: "pihole"
tailscale_pihole_dns_hostname: "pihole-dns"

# Helm application namespaces
gogs_namespace: "git"
sonarr_namespace: "media"
qbittorrent_namespace: "media"
pihole_namespace: "pihole"

# Storage configuration
storage_class: "standard"
```

### Role Defaults
Each role defines its own defaults:

**Example from roles/apt_updates/defaults/main.yml:**
```yaml
---
apt_updates_schedule: "0 3 * * 0"  # Weekly on Sunday at 3 AM
apt_updates_email: ""
```

**Example from roles/minikube/defaults/main.yml:**
```yaml
---
minikube_install_path: "/usr/local/bin"
```

### Vault Variables (vault.yml - encrypted)
Sensitive credentials stored encrypted:

**Example vault.yml.example:**
```yaml
---
# Copy this file to vault.yml and encrypt with: ansible-vault encrypt vault.yml
vault_tailscale_auth_key: "tskey-auth-xxxx"
vault_tailscale_oauth_client_id: "kxxxx"
vault_tailscale_oauth_client_secret: "tskey-client-xxxx"
```

## Inventory Structure

**inventory/hosts.yml:**
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

Patterns:
- `all` group contains all hosts
- `children` groups for logical organization
- Host-specific variables can be set per host
- Support for localhost (local) or remote (SSH) connections

## Secret Management Patterns

### Vault Reference Pattern
Reference encrypted variables with default fallback:

```yaml
tailscale_auth_key: "{{ vault_tailscale_auth_key | default('') }}"
```

This allows:
- Graceful handling of missing vault variables
- Empty string defaults that can be checked in conditionals
- Clear naming convention (`vault_` prefix)

### Conditional Execution Based on Secrets
Tasks check if secrets are configured before using them:

**From tailscale-operator.yml:**
```yaml
- name: Deploy Tailscale operator using Helm
  ansible.builtin.command: >
    helm upgrade --install tailscale-operator tailscale/tailscale-operator
    --namespace tailscale
    --set-string oauth.clientId="{{ tailscale_oauth_client_id }}"
    --set-string oauth.clientSecret="{{ tailscale_oauth_client_secret }}"
    --set apiServerProxyConfig.mode=true
    --set operatorConfig.hostname="{{ tailscale_operator_hostname | default('ts-operator') }}"
    {{ '--version ' + tailscale_operator_chart_version if tailscale_operator_chart_version else '' }}
    --wait
  changed_when: true
  become: no
  when:
    - tailscale_oauth_client_id is defined
    - tailscale_oauth_client_secret is defined
    - tailscale_oauth_client_id | length > 0
    - tailscale_oauth_client_secret | length > 0

- name: Display Tailscale operator skip message
  ansible.builtin.debug:
    msg: "Skipping Tailscale operator deployment - OAuth credentials not configured. See docs/tailscale-operator.md for setup instructions."
  when: >
    tailscale_oauth_client_id is not defined or
    tailscale_oauth_client_secret is not defined or
    tailscale_oauth_client_id | length == 0 or
    tailscale_oauth_client_secret | length == 0
```

### Variable Interpolation in Manifests
Variables used within Kubernetes manifests:

```yaml
- name: Create Gogs manifest
  ansible.builtin.copy:
    dest: /tmp/gogs-manifest.yaml
    content: |
      apiVersion: v1
      kind: Service
      metadata:
        name: gogs
        namespace: {{ gogs_namespace }}
        annotations:
          tailscale.com/expose: "true"
          tailscale.com/hostname: "{{ tailscale_gogs_hostname }}"
```

## Configuration File Management

### Ansible Configuration (ansible.cfg)
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
- `vault_password_file`: Automatic vault decryption
- `become = True`: Default privilege escalation
- `interpreter_python = auto_silent`: Automatic Python detection
- `pipelining = True`: Performance optimization

## Variable Naming Conventions

### Component Configuration Pattern
```
{component}_{setting}
```
Examples:
- `minikube_version`
- `minikube_cpus`
- `kubectl_install_path`
- `helm_version`

### Namespace Pattern
```
{application}_namespace
```
Examples:
- `gogs_namespace: "git"`
- `sonarr_namespace: "media"`
- `pihole_namespace: "pihole"`

### Tailscale Hostname Pattern
```
tailscale_{application}_hostname
```
Examples:
- `tailscale_gogs_hostname: "gogs"`
- `tailscale_sonarr_hostname: "sonarr"`

### Vault Variable Pattern
```
vault_{variable_name}
```
Referenced as:
```yaml
variable_name: "{{ vault_variable_name | default('default_value') }}"
```

## Version Management

All external components support version variables:
```yaml
minikube_version: "latest"
kubectl_version: "latest"
helm_version: "latest"
# Optional chart versions:
tailscale_operator_chart_version: ""
sonarr_chart_version: ""
```

"latest" triggers dynamic version fetching from release APIs.

## Constraints
- Vault password file (`.vault_pass`) required for encrypted variables
- All secrets must use `vault_` prefix
- Variables must have defaults for optional features
- No hardcoded secrets in any file (use vault references)
- Namespace variables required for all applications
- Version variables should default to "latest" for ease of maintenance
