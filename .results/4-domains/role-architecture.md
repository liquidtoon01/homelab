# Role Architecture Domain

## Overview
This domain defines the structure, organization, and conventions for Ansible roles in the homelab infrastructure.

## Standard Role Structure

Every role follows Ansible's standard directory layout:

```
roles/{role-name}/
├── defaults/
│   └── main.yml
├── files/
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml
├── tasks/
│   └── main.yml
├── templates/
└── vars/
    └── main.yml
```

### Actually Used Directories
Most roles in this project use:
- `defaults/main.yml` - Default variables
- `meta/main.yml` - Role metadata and dependencies
- `tasks/main.yml` - Main task list

Some roles add:
- `templates/` - Jinja2 template files (apt_updates)
- `files/` - Static files (helm_apps has custom Helm charts)

## Role Categories

### Infrastructure Roles
Install and configure base infrastructure:

**Roles:**
- `base` - System dependencies, Docker
- `minikube` - Kubernetes cluster
- `kubectl` - Kubernetes CLI
- `helm` - Helm package manager
- `tailscale` - Tailscale VPN
- `apt_updates` - Automated system updates

**Pattern:**
- Install binary or package
- Configure service
- Verify installation
- Start and enable service

### Application Deployment Roles
Deploy applications to Kubernetes:

**Roles:**
- `helm_apps` - All Kubernetes applications

**Pattern:**
- Add Helm repositories
- Create namespaces
- Deploy applications via separate task files

### Operational Roles
Operational tasks:

**Roles:**
- `backup` - Backup Minikube volumes

## tasks/main.yml Patterns

### Simple Role (Direct Tasks)
Infrastructure roles execute tasks directly in main.yml:

**Example from roles/kubectl/tasks/main.yml:**
```yaml
---
- name: Get latest stable kubectl version
  ansible.builtin.uri:
    url: https://dl.k8s.io/release/stable.txt
    return_content: yes
  register: kubectl_stable_version
  when: kubectl_version == "latest"

- name: Set kubectl version fact
  ansible.builtin.set_fact:
    kubectl_install_version: "{{ kubectl_stable_version.content | trim if kubectl_version == 'latest' else kubectl_version }}"

- name: Download kubectl binary
  ansible.builtin.get_url:
    url: "https://dl.k8s.io/release/{{ kubectl_install_version }}/bin/linux/amd64/kubectl"
    dest: "{{ kubectl_install_path }}/kubectl"
    mode: '0755'

- name: Verify kubectl installation
  ansible.builtin.command: kubectl version --client
  changed_when: false
  become: no
```

### Complex Role (Task Includes)
Application deployment roles split into multiple files:

**Example from roles/helm_apps/tasks/main.yml:**
```yaml
---
- name: Add Helm repositories for applications
  ansible.builtin.command: "helm repo add {{ item.name }} {{ item.url }}"
  loop:
    - { name: "tailscale", url: "https://pkgs.tailscale.com/helmcharts" }
    - { name: "k8s-at-home", url: "https://k8s-at-home.com/charts/" }
  register: helm_repo_add_result
  changed_when: false
  failed_when: false
  become: no

- name: Update Helm repositories
  ansible.builtin.command: helm repo update
  changed_when: false
  become: no

- name: Deploy Tailscale operator
  ansible.builtin.include_tasks: tailscale-operator.yml

- name: Configure Minikube storage provisioner
  ansible.builtin.include_tasks: storage.yml

- name: Deploy Gogs
  ansible.builtin.include_tasks: gogs.yml

- name: Deploy qBittorrent
  ansible.builtin.include_tasks: qbittorrent.yml

- name: Deploy Sonarr
  ansible.builtin.include_tasks: sonarr.yml
```

Pattern:
- Common setup tasks in main.yml
- Per-application tasks in separate files
- Use `include_tasks` for modularity

## defaults/main.yml Pattern

All configurable values defined with sensible defaults:

**Example from roles/minikube/defaults/main.yml:**
```yaml
---
minikube_install_path: "/usr/local/bin"
```

**Example from roles/apt_updates/defaults/main.yml:**
```yaml
---
apt_updates_schedule: "0 3 * * 0"  # Weekly on Sunday at 3 AM
apt_updates_email: ""
```

**Example from roles/backup/defaults/main.yml:**
```yaml
---
backup_source_dir: /var/lib/docker/volumes/minikube/_data/hostpath-provisioner
backup_temp_dir: /tmp
tailscale_target_ip: "100.97.131.29"
backup_schedule: "0 2 * * 0"
```

Pattern:
- Paths, schedules, and configuration values
- Empty strings for optional settings
- Cron format for schedules

## meta/main.yml Pattern

All roles define metadata but NO dependencies:

**Example from roles/minikube/meta/main.yml:**
```yaml
---
galaxy_info:
  author: Your Name
  description: Install and configure Minikube
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: Ubuntu
      versions:
        - noble
        - focal
  galaxy_tags:
    - kubernetes
    - minikube
    - container

dependencies: []
```

**Example from roles/base/meta/main.yml:**
```yaml
---
galaxy_info:
  author: Your Name
  description: Base system configuration and Docker installation
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: Ubuntu
      versions:
        - noble
        - focal

dependencies: []
```

Pattern:
- `dependencies: []` - No role dependencies
- Platform specification: Ubuntu Noble (24.04) and Focal (20.04)
- Clear description and tags

## Task File Organization

### Infrastructure Role Tasks
Single main.yml file, sequential execution:

1. Check current state
2. Fetch version if needed
3. Install binary/package
4. Configure
5. Verify installation

### Application Role Tasks
Separate file per application/feature:

```
roles/helm_apps/tasks/
├── main.yml
├── crontab-ui.yml
├── gogs.yml
├── jackett.yml
├── pihole.yml
├── qbittorrent.yml
├── sonarr.yml
├── storage.yml
└── tailscale-operator.yml
```

Each file self-contained:
- Create namespace
- Create PVCs
- Create Helm values
- Deploy with Helm or kubectl

## Custom File Resources

**roles/helm_apps/files/crontab-ui/**
Contains custom Helm chart for Crontab UI:
```
crontab-ui/
├── Chart.yaml
├── .helmignore
├── README.md
├── values.yaml
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── pvc.yaml
    └── service.yaml
```

Used when no suitable Helm chart exists in public repositories.

## Idempotency Patterns

### Check Before Action
```yaml
- name: Check if Minikube cluster is running
  ansible.builtin.command: minikube status
  register: minikube_status
  changed_when: false
  failed_when: false
  become: no

- name: Start Minikube cluster
  ansible.builtin.command: ...
  when: minikube_status.rc != 0
```

### Namespace Creation
```yaml
- name: Create Gogs namespace
  ansible.builtin.command: kubectl create namespace {{ gogs_namespace }}
  failed_when: false  # Don't fail if already exists
  changed_when: false
  become: no
```

### Repository Addition
```yaml
- name: Add Helm repositories
  ansible.builtin.command: "helm repo add {{ item.name }} {{ item.url }}"
  loop:
    - { name: "stable", url: "https://charts.helm.sh/stable" }
  changed_when: false  # Already exists is fine
  failed_when: false
  become: no
```

## Variable Override Hierarchy

1. Role defaults (`roles/{role}/defaults/main.yml`) - Lowest priority
2. Group vars (`group_vars/all.yml`) - Override role defaults
3. Host vars (not used in this project)
4. Playbook vars (not used in this project)
5. Command-line vars (`-e` flag) - Highest priority

Example:
```yaml
# roles/minikube/defaults/main.yml
minikube_install_path: "/usr/local/bin"

# group_vars/all.yml (can override)
minikube_version: "latest"
minikube_cpus: 2
```

## Naming Conventions

### Role Names
- Lowercase, hyphen-separated
- Match component name: `minikube`, `kubectl`, `helm`, `tailscale`
- Generic functional names: `base`, `helm_apps`, `backup`

### Task File Names
- Application name: `gogs.yml`, `sonarr.yml`
- Feature name: `storage.yml`, `tailscale-operator.yml`

### Variable Names
- Prefixed with role name: `minikube_version`, `kubectl_install_path`
- Or component name: `tailscale_auth_key`, `gogs_namespace`

## Role Dependencies

This project uses NO role dependencies via meta/main.yml.

Orchestration handled via playbooks:
- Explicit role order in playbooks
- Clear execution sequence
- Easier to understand and debug

## Constraints
- All roles must have `defaults/main.yml`, `meta/main.yml`, `tasks/main.yml`
- No role dependencies (orchestrated via playbooks)
- Infrastructure roles: single main.yml task file
- Application roles: split tasks via include_tasks
- All roles must be idempotent (safe to re-run)
- Use `become: no` for user operations, default `become: yes` from play
- All configurable values in defaults with sensible defaults
- Platform target: Ubuntu 24.04 (Noble)
