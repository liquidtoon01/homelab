# GitHub Copilot Instructions for Homelab Infrastructure

## Overview

This file enables AI coding assistants to generate features aligned with this project's architecture and style. It is based on actual, observed patterns from the codebase — not invented practices.

This is an **Ansible-based Infrastructure as Code project** for provisioning and managing a Kubernetes homelab environment on bare-metal Ubuntu 24.04 servers. The infrastructure uses Minikube for Kubernetes, Helm for application deployment, and Tailscale for secure VPN access to all services.

**Core Technologies:**
- **Ansible** - Infrastructure automation and configuration management
- **Kubernetes (Minikube)** - Container orchestration (single-node)
- **Helm** - Kubernetes package manager
- **Docker** - Container runtime
- **Tailscale** - Zero-config VPN mesh network

**Domain:** Homelab infrastructure automation, self-hosted media management, development tools, and network services — all accessible only via VPN with no public exposure.

---

## File Category Reference

### ansible-playbooks
**What it is:** YAML files orchestrating role execution and defining deployment order.

**Examples:**
- `playbooks/site.yml` - Master playbook importing infrastructure and applications
- `playbooks/infrastructure.yml` - Infrastructure component deployment
- `playbooks/applications.yml` - Application deployment

**Key Conventions:**
- Always start with `---`
- Use `import_playbook` for playbook composition (not include_playbook)
- Single play per file (except site.yml)
- Target `hosts: all` with `become: yes`
- Each role tagged with component name AND category (`['minikube', 'infrastructure']`)
- Infrastructure roles before application roles
- No variables or conditionals in playbooks (handle in roles)

### ansible-role-tasks
**What it is:** Task files defining actual work performed by roles.

**Examples:**
- `roles/minikube/tasks/main.yml` - Minikube installation and cluster setup
- `roles/helm_apps/tasks/gogs.yml` - Gogs Git service deployment

**Key Conventions:**
- Always use FQCN (Fully Qualified Collection Names): `ansible.builtin.apt`, `ansible.builtin.command`
- Task names: verb-first, descriptive ("Get latest version", "Deploy application")
- Add `become: no` for user operations (minikube, kubectl, helm)
- Use `changed_when: false` for status checks
- Use `failed_when: false` for idempotent operations (namespace creation, repo addition)
- Set `changed_when: true` for deployment commands
- Check state before actions for idempotency
- Version management: support "latest" with dynamic API fetching
- Write manifest/values files to `/tmp` before applying
- No handlers used - service management explicit in tasks

### ansible-role-defaults
**What it is:** Default variable definitions with sensible out-of-box values.

**Examples:**
- `roles/minikube/defaults/main.yml`
- `roles/backup/defaults/main.yml`

**Key Conventions:**
- Prefix variables with role/component name: `minikube_version`, `kubectl_install_path`
- Version variables default to `"latest"`
- Cron schedules: `"0 3 * * 0"` format with inline comments
- Optional settings: empty string `""`
- Binary paths: `/usr/local/bin`
- Resource values: quoted strings (`"4096"`, `"20g"`)
- Boolean: lowercase `true`/`false`
- Integer: unquoted
- Comments inline for clarity

### ansible-role-meta
**What it is:** Role metadata, platform compatibility, and dependencies.

**Examples:**
- `roles/minikube/meta/main.yml`

**Key Conventions:**
- Always `dependencies: []` (no role dependencies - orchestrated via playbooks)
- Platform: Ubuntu Noble (24.04) and Focal (20.04)
- min_ansible_version: 2.9
- Include galaxy_info with author, description, license

### ansible-templates
**What it is:** Jinja2 templates for system configuration files.

**Examples:**
- `roles/apt_updates/templates/50unattended-upgrades.j2` - APT security updates config
- `roles/apt_updates/templates/20auto-upgrades.j2` - Automatic update enablement

**Key Conventions:**
- Extension: `.j2`
- Deploy with `ansible.builtin.template` module
- System config file permissions: `mode: '0644'`
- Simple variable substitution: `{{ variable }}`
- Conditionals for optional config: `{% if variable %} ... {% endif %}`
- No loops or complex logic in templates
- Preserve target file comment style (shell `#` or C `//`)
- Used sparingly - prefer `copy` module with `content` for most files

### ansible-inventory
**What it is:** Host definitions and group organization.

**Example:**
- `inventory/hosts.yml`

**Key Conventions:**
- Default: `ansible_connection: local` for localhost
- Comment includes remote host example
- `all` group contains all hosts
- `children` for logical grouping (kubernetes)
- YAML format (not INI)

### ansible-group-variables
**What it is:** Variables shared across all hosts.

**Example:**
- `group_vars/all.yml`

**Key Conventions:**
- Global component versions: `minikube_version: "latest"`
- Resource allocations: `minikube_cpus: 2`, `minikube_memory: "4096"`
- Namespace definitions: `gogs_namespace: "git"`
- Tailscale hostnames: `tailscale_gogs_hostname: "gogs"`
- Storage class: `storage_class: "standard"`
- Vault variable references: `tailscale_auth_key: "{{ vault_tailscale_auth_key | default('') }}"`
- Never hardcode secrets

### ansible-configuration
**What it is:** Ansible behavior and settings.

**Example:**
- `ansible.cfg`

**Key Conventions:**
- `[defaults]` section: inventory path, roles path, vault password file
- `vault_password_file = .vault_pass` for automatic decryption
- `interpreter_python = auto_silent` for auto Python detection
- `[privilege_escalation]`: become=True, become_method=sudo
- `[ssh_connection]`: pipelining=True for performance

### helm-charts
**What it is:** Custom Helm charts for applications without suitable public charts.

**Example:**
- `roles/helm_apps/files/crontab-ui/`

**Key Conventions:**
- Standard structure: Chart.yaml, values.yaml, templates/, .helmignore, README.md
- Chart.yaml: apiVersion v2, type application, semver version
- values.yaml: image, service, persistence, resources, tailscale sections
- Templates: _helpers.tpl with standard helper functions
- All services `type: ClusterIP` (no LoadBalancer/NodePort)
- Tailscale annotations: `tailscale.com/expose: "true"`, `tailscale.com/hostname`
- Resource limits and requests defined
- PVC conditional: `{{- if .Values.persistence.enabled }}`

### helm-templates
**What it is:** Kubernetes manifest templates for Helm charts.

**Examples:**
- `roles/helm_apps/files/crontab-ui/templates/deployment.yaml`
- `roles/helm_apps/files/crontab-ui/templates/service.yaml`

**Key Conventions:**
- Helper function calls: `{{ include "chart-name.fullname" . }}`
- Labels: Use helpers for consistent labels
- Conditionals for optional features
- Standard resource nesting with `toYaml` and `nindent`

### kubernetes-manifests
**What it is:** Kubernetes YAML manifests embedded in Ansible tasks.

**Examples:**
- `roles/helm_apps/tasks/gogs.yml` - PostgreSQL StatefulSet, Gogs Deployment
- `roles/helm_apps/tasks/sonarr.yml` - PVCs, Deployments

**Key Conventions:**
- Multi-document YAML with `---` separators
- Created inline with `ansible.builtin.copy` and `content: |`
- Variable interpolation: `namespace: {{ var_name }}`
- Applied with `kubectl apply -f /tmp/filename.yaml`
- Namespace created first with `failed_when: false`
- ConfigMaps for application configuration
- Services with Tailscale annotations
- StatefulSets for databases with volumeClaimTemplates
- PVCs before Deployments

### bootstrap-scripts
**What it is:** Shell scripts for initial system setup before Ansible.

**Examples:**
- `bootstrap.sh` - Install Ansible and dependencies
- `setup-vault.sh` - Configure Ansible Vault

**Key Conventions:**
- Shebang: `#!/bin/bash`
- `set -e` at start
- Section headers: `echo "=== Section Name ==="`
- Commands with `sudo` where needed
- APT: `sudo apt-get install -y package-name`
- Backup before modify: timestamp format `YYYYMMDD_HHMMSS`
- sed in-place editing: `sudo sed -i 's/pattern/replacement/' "$file"`
- Verify installations: `ansible --version`
- Success messages with next steps

### build-automation
**What it is:** Makefile targets for simplified command execution.

**Example:**
- `Makefile`

**Key Conventions:**
- Targets with ## comments for help text
- `@echo` messages before commands
- Wrap ansible-playbook commands with clear names
- Status commands with `|| true` to not fail
- Cleanup commands with `|| true` to not fail on missing resources
- Log viewing with `--tail=100`
- Variables at top if needed

### documentation
**What it is:** Markdown documentation for users and developers.

**Examples:**
- `README.md` - Project overview and quick start
- `docs/applications.md` - Application details

**Key Conventions:**
- Headers: # Title, ## Section, ### Subsection
- Code blocks: ` ```bash `, ` ```yaml ` with language
- Inline code: backticks for paths, commands, variables
- Bold for component names: **Minikube**
- Numbered steps as headers: `### 1. Step Name`
- Commands in code blocks with comments
- Always mention Tailscale access for services
- Links: relative paths for internal docs
- Tables for configuration reference

---

## Feature Scaffold Guide

### Planning a New Feature

When adding functionality to this project, determine the appropriate implementation approach:

**1. New Infrastructure Component (e.g., adding PostgreSQL, Redis)**
- Create new role: `roles/{component}/`
- Structure: `defaults/main.yml`, `meta/main.yml`, `tasks/main.yml`
- Add to `playbooks/infrastructure.yml` with appropriate tag
- Follow version management pattern (support "latest")
- Check state before installation for idempotency

**2. New Application Deployment (e.g., adding Jellyfin, Nextcloud)**
- Add task file: `roles/helm_apps/tasks/{app}.yml`
- Include in `roles/helm_apps/tasks/main.yml`
- Create namespace first
- Define namespace variable in `group_vars/all.yml` 
- Define Tailscale hostname in `group_vars/all.yml`
- Either:
  - Use Helm chart from public repo with values file in `/tmp`
  - Create inline Kubernetes manifests with `ansible.builtin.copy`
- Add Tailscale annotations to Service
- Use ClusterIP service type only
- Define PVCs if stateful

**3. New Role**
Create directory structure:
```
roles/{role-name}/
├── defaults/main.yml    # Default variables
├── meta/main.yml        # Metadata (dependencies: [])
└── tasks/main.yml       # Task list
```

**4. Modifying Existing Application**
- Locate task file in `roles/helm_apps/tasks/{app}.yml`
- Update manifest or Helm values
- Maintain idempotency (namespace creation, PVC creation)
- Keep Tailscale annotations

### File Naming Conventions

- **Playbooks:** `{category}.yml` (infrastructure, applications, backup)
- **Role directories:** lowercase, hyphen-separated, match component name
- **Task files:** `main.yml` or `{app-name}.yml`
- **Templates:** `{filename}.j2`
- **Variables:** `{component}_{setting}` or `{app}_namespace`
- **Vault variables:** `vault_{variable_name}`

### Where Files Go

- **Playbooks:** `playbooks/`
- **Roles:** `roles/{role-name}/`
- **Group variables:** `group_vars/all.yml`
- **Encrypted secrets:** `group_vars/vault.yml` (encrypted)
- **Inventory:** `inventory/hosts.yml`
- **Documentation:** `docs/` or root
- **Custom Helm charts:** `roles/helm_apps/files/{chart-name}/`

---

## Integration Rules

### Infrastructure Provisioning Domain

**Required:**
- Always check for "latest" version with API call: `ansible.builtin.uri` to GitHub releases or stable.txt
- Set version fact with conditional: `{{ api_result.json.tag_name if version == 'latest' else version }}`
- Check if binary exists before downloading
- Use `ansible.builtin.get_url` with `mode: '0755'` for binaries
- Install to `/usr/local/bin` by default
- Verify installation with version check command
- Start and enable services with `ansible.builtin.systemd`
- Use `become: no` for Minikube/kubectl/helm operations

**Constraints:**
- Docker must be installed before Minikube
- kubectl/helm must exist before application deployment
- All infrastructure tools support "latest" version fetching

### Application Deployment Domain

**Required:**
- Create namespace first: `kubectl create namespace` with `failed_when: false`, `changed_when: false`
- Add Helm repos before deploying from them
- Storage class must exist before PVC creation
- PVCs must exist before Deployment references
- All Helm deployments use: `helm upgrade --install {name} {chart} --namespace {ns} --wait`
- Tailscale annotations on all Services: `tailscale.com/expose: "true"`, `tailscale.com/hostname`

**Constraints:**
- All services MUST be `type: ClusterIP` (never LoadBalancer or NodePort)
- External access ONLY via Tailscale ingress
- Manifests written to `/tmp` before `kubectl apply`
- All Helm/kubectl operations with `become: no`
- Multi-document YAML for complex deployments
- Namespace isolation: separate namespaces for logical groups (git, media, pihole)

### Configuration Management Domain

**Required:**
- Global configuration in `group_vars/all.yml`
- Secrets reference vault: `{{ vault_var | default('') }}`
- Role defaults for role-specific settings
- Version variables default to "latest"
- Namespace variables: `{app}_namespace`
- Hostname variables: `tailscale_{app}_hostname`

**Constraints:**
- No secrets in defaults or group_vars (use vault reference)
- All secrets have `vault_` prefix
- Variable naming: `{component}_{setting}`
- Vault password file (`.vault_pass`) must exist
- No hardcoded credentials anywhere

### Security Hardening Domain

**Required:**
- Backup config files before modification with timestamp
- Use unattended-upgrades for automatic security updates
- SSH config modifications commented for safety
- All secrets in encrypted vault.yml
- VPN-only access (no public exposure)
- Ansible Vault encryption for sensitive data

**Constraints:**
- Services never exposed publicly
- All ingress via Tailscale
- System config file permissions: `0644`
- Scripts: `0755`
- No automatic reboots (set to false)

### Storage Management Domain

**Required:**
- Verify storage provisioner exists before deployment
- Enable `storage-provisioner` addon if missing
- Set `standard` as default storage class
- PVCs before Deployments
- StatefulSets use `volumeClaimTemplates`

**Constraints:**
- Storage class: `standard` (Minikube provisioner)
- Access modes: ReadWriteOnce (config) or ReadWriteMany (shared/NFS)
- External NFS requires PV + PVC with `volumeName` binding
- All storage from Minikube provisioner or external NFS (no cloud providers)

### Role Architecture Domain

**Required:**
- Every role has: `defaults/main.yml`, `meta/main.yml`, `tasks/main.yml`
- Metadata specifies: `dependencies: []` (no dependencies)
- Complex roles split tasks with `include_tasks`
- Platform: Ubuntu 24.04 (Noble)

**Constraints:**
- No role dependencies via meta (orchestrate via playbooks)
- Simple roles: single main.yml
- Complex roles: main.yml + included task files
- All roles idempotent (safe to re-run)

### Orchestration Domain

**Required:**
- Playbooks target `hosts: all`
- Play-level `become: yes` (override at task level)
- Dual tagging: component tag + category tag
- Infrastructure playbook before applications playbook
- Master playbook uses `import_playbook`

**Constraints:**
- Single play per playbook (except site.yml)
- Execution order enforced by playbook, not role dependencies
- Inventory specified with `-i` flag
- No dynamic includes (use static imports)

---

## Example Prompt Usage

### Example 1: Add New Application

**User Prompt:**
> "Add Jellyfin media server to the homelab with Tailscale access"

**Expected AI Response:**

I'll add Jellyfin as a new Helm application. This involves:

1. Adding namespace variable to [group_vars/all.yml](group_vars/all.yml)
2. Creating task file [roles/helm_apps/tasks/jellyfin.yml](roles/helm_apps/tasks/jellyfin.yml)
3. Including it in [roles/helm_apps/tasks/main.yml](roles/helm_apps/tasks/main.yml)

**Changes:**

[group_vars/all.yml](group_vars/all.yml) - Add namespace and hostname:
```yaml
jellyfin_namespace: "media"
tailscale_jellyfin_hostname: "jellyfin"
```

[roles/helm_apps/tasks/jellyfin.yml](roles/helm_apps/tasks/jellyfin.yml):
```yaml
---
- name: Create Jellyfin namespace
  ansible.builtin.command: kubectl create namespace {{ jellyfin_namespace }}
  failed_when: false
  changed_when: false
  become: no

- name: Create Jellyfin PVC
  ansible.builtin.copy:
    dest: /tmp/jellyfin-pvc.yaml
    content: |
      ---
      apiVersion: v1
      kind: PersistentVolumeClaim
      metadata:
        name: jellyfin-config
        namespace: {{ jellyfin_namespace }}
      spec:
        accessModes:
          - ReadWriteOnce
        storageClassName: {{ storage_class }}
        resources:
          requests:
            storage: 5Gi
  become: no

- name: Apply Jellyfin PVC
  ansible.builtin.command: kubectl apply -f /tmp/jellyfin-pvc.yaml
  changed_when: true
  become: no

- name: Deploy Jellyfin using Helm
  ansible.builtin.command: >
    helm upgrade --install jellyfin k8s-at-home/jellyfin
    --namespace {{ jellyfin_namespace }}
    --set service.main.type=ClusterIP
    --set service.main.annotations."tailscale\.com/expose"="true"
    --set service.main.annotations."tailscale\.com/hostname"="{{ tailscale_jellyfin_hostname }}"
    --set persistence.config.enabled=true
    --set persistence.config.existingClaim=jellyfin-config
    --wait
  changed_when: true
  become: no
```

[roles/helm_apps/tasks/main.yml](roles/helm_apps/tasks/main.yml) - Add include:
```yaml
- name: Deploy Jellyfin
  ansible.builtin.include_tasks: jellyfin.yml
```

### Example 2: Add Infrastructure Component

**User Prompt:**
> "Add PostgreSQL as an infrastructure component"

**Expected AI Response:**

I'll create a new role for PostgreSQL installation. Since this is infrastructure (not a Kubernetes application), it will be a system-level PostgreSQL installation.

**Structure:**

[roles/postgresql/defaults/main.yml](roles/postgresql/defaults/main.yml):
```yaml
---
postgresql_version: "14"
postgresql_install_path: "/usr/bin"
```

[roles/postgresql/meta/main.yml](roles/postgresql/meta/main.yml):
```yaml
---
galaxy_info:
  author: Your Name
  description: Install and configure PostgreSQL
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: Ubuntu
      versions:
        - noble

dependencies: []
```

[roles/postgresql/tasks/main.yml](roles/postgresql/tasks/main.yml):
```yaml
---
- name: Install PostgreSQL
  ansible.builtin.apt:
    name:
      - postgresql-{{ postgresql_version }}
      - postgresql-contrib
    state: present
    update_cache: yes

- name: Start and enable PostgreSQL service
  ansible.builtin.systemd:
    name: postgresql
    state: started
    enabled: yes

- name: Verify PostgreSQL installation
  ansible.builtin.command: psql --version
  changed_when: false
  become: no
```

[playbooks/infrastructure.yml](playbooks/infrastructure.yml) - Add role:
```yaml
- role: postgresql
  tags: ['postgresql', 'infrastructure']
```

---

## Notes

- This project targets **bare-metal Ubuntu 24.04** servers (not cloud providers)
- **Single-host deployment model** (localhost or single remote host)
- **Kubernetes via Minikube** (single-node, not production multi-node)
- **VPN-first networking** - all services via Tailscale, zero public exposure
- **Idempotent operations** - all tasks safe to re-run
- **Tag-based execution** - support selective provisioning with `--tags`
- **Make wrapper** - simplified interface to Ansible commands
- **Security focus** - vault encryption, automated updates, SSH hardening, no public services

When suggesting new features or changes, maintain these core principles and follow the established patterns documented above.
