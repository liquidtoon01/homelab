# Ansible Role Tasks Style Guide

## Overview
Task files define the actual work performed by roles. This project uses two patterns: simple roles (single main.yml) and complex roles (main.yml with includes).

## Module Naming

### Always Use FQCN (Fully Qualified Collection Name)
```yaml
# Correct
- name: Install packages
  ansible.builtin.apt:
    name: docker.io
    state: present

# Incorrect
- name: Install packages
  apt:  # Legacy short name
    name: docker.io
```

All modules prefixed with collection name (`ansible.builtin`, `ansible.posix`, etc.)

## Task Naming

### Format
Clear, action-oriented descriptions:
```yaml
- name: Get latest stable kubectl version
- name: Download kubectl binary
- name: Verify kubectl installation
- name: Create Gogs namespace
```

### Naming Patterns
- Start with verb: Get, Download, Install, Create, Deploy, Configure, Verify
- Be specific about what's being acted upon
- Keep under 60 characters when possible

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
  ansible.builtin.command: minikube start ...
  when: minikube_status.rc != 0
  become: no
```

### Graceful Namespace Creation
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
  changed_when: false  # Already exists is acceptable
  failed_when: false
  become: no
```

## Privilege Management

### Default Behavior
Tasks inherit `become: yes` from play level.

### User Operations Override
```yaml
- name: Start Minikube cluster
  ansible.builtin.command: minikube start
  become: no  # Must run as user, not root
```

Pattern: Add `become: no` for:
- minikube operations
- kubectl operations
- helm operations
- User-specific commands

## Variable Usage

### Version Management
```yaml
- name: Get latest Minikube version
  ansible.builtin.uri:
    url: https://api.github.com/repos/kubernetes/minikube/releases/latest
    return_content: yes
  register: minikube_latest_release
  when: minikube_version == "latest"

- name: Set Minikube version fact
  ansible.builtin.set_fact:
    minikube_install_version: "{{ minikube_latest_release.json.tag_name if minikube_version == 'latest' else minikube_version }}"
```

Pattern: Support both "latest" (dynamic) and specific versions.

### Variable References
```yaml
# In YAML values
namespace: {{ gogs_namespace }}

# In command strings
--namespace {{ gogs_namespace }}

# In conditionals
when: tailscale_auth_key is defined and tailscale_auth_key | length > 0
```

## changed_when and failed_when

### Status Check Commands
```yaml
- name: Check if Minikube cluster is running
  ansible.builtin.command: minikube status
  register: minikube_status
  changed_when: false  # Checking status doesn't change anything
  failed_when: false   # Non-zero exit is expected, not an error
```

### Idempotent Commands
```yaml
- name: Create Gogs namespace
  ansible.builtin.command: kubectl create namespace {{ gogs_namespace }}
  failed_when: false  # Already existing is fine
  changed_when: false # Report as not changed
```

### Deployment Commands
```yaml
- name: Deploy qBittorrent using Helm
  ansible.builtin.command: >
    helm upgrade --install qbittorrent gabe565/qbittorrent ...
  changed_when: true  # Always report as changed
  become: no
```

## Loop Patterns

### Simple Loop
```yaml
- name: Enable Minikube addons
  ansible.builtin.command: "minikube addons enable {{ item }}"
  loop:
    - storage-provisioner
    - default-storageclass
    - metrics-server
  changed_when: false
  failed_when: false
  become: no
```

### Dictionary Loop
```yaml
- name: Add Helm repositories
  ansible.builtin.command: "helm repo add {{ item.name }} {{ item.url }}"
  loop:
    - { name: "tailscale", url: "https://pkgs.tailscale.com/helmcharts" }
    - { name: "k8s-at-home", url: "https://k8s-at-home.com/charts/" }
  register: helm_repo_add_result
  changed_when: false
  failed_when: false
  become: no
```

## Conditional Execution

### Simple Condition
```yaml
- name: Download Minikube binary
  ansible.builtin.get_url:
    url: "https://github.com/kubernetes/minikube/releases/download/{{ minikube_install_version }}/minikube-linux-amd64"
    dest: "{{ minikube_install_path }}/minikube"
    mode: '0755'
  when: not minikube_binary.stat.exists or minikube_version == "latest"
```

### Multi-Condition
```yaml
- name: Deploy Tailscale operator
  ansible.builtin.command: >
    helm upgrade --install tailscale-operator ...
  when:
    - tailscale_oauth_client_id is defined
    - tailscale_oauth_client_secret is defined
    - tailscale_oauth_client_id | length > 0
    - tailscale_oauth_client_secret | length > 0
```

## File Creation Patterns

### Inline Content (Small Files)
```yaml
- name: Create apt update script
  ansible.builtin.copy:
    dest: /usr/local/bin/apt-update.sh
    mode: '0755'
    content: |
      #!/bin/bash
      # Automated apt update script
      
      apt-get update
      apt-get upgrade -y
```

### Multi-Document YAML
```yaml
- name: Create Gogs manifest
  ansible.builtin.copy:
    dest: /tmp/gogs-manifest.yaml
    content: |
      ---
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: postgres-config
      ---
      apiVersion: v1
      kind: Service
      metadata:
        name: postgres
```

### File Permissions
- Scripts: `mode: '0755'`
- Config files: `mode: '0644'`

## Task Organization

### Simple Role (main.yml only)
Sequential tasks:
```yaml
---
- name: Get latest version
- name: Set version fact
- name: Download binary
- name: Verify installation
```

### Complex Role (main.yml + includes)
```yaml
---
- name: Add Helm repositories
  # ... common setup ...

- name: Deploy Gogs
  ansible.builtin.include_tasks: gogs.yml

- name: Deploy qBittorrent
  ansible.builtin.include_tasks: qbittorrent.yml
```

## Manifest Application Pattern

1. Create manifest in /tmp
2. Apply with kubectl
3. No cleanup (tmp cleaned on reboot)

```yaml
- name: Create Sonarr config PVC
  ansible.builtin.copy:
    dest: /tmp/sonarr-config-pvc.yaml
    content: |
      # YAML content
  become: no

- name: Apply Sonarr config PVC
  ansible.builtin.command: kubectl apply -f /tmp/sonarr-config-pvc.yaml
  changed_when: true
  become: no
```

## Command Module Usage

### Simple Command
```yaml
- name: Start Minikube cluster
  ansible.builtin.command: minikube start
  become: no
```

### Multi-Line Command
```yaml
- name: Start Minikube cluster
  ansible.builtin.command: >
    minikube start
    --driver={{ minikube_driver }}
    --cpus={{ minikube_cpus }}
    --memory={{ minikube_memory }}
    --disk-size={{ minikube_disk_size }}
  become: no
```

Use `>` for line folding (spaces between args).

### Helm Commands
```yaml
- name: Deploy qBittorrent using Helm
  ansible.builtin.command: >
    helm upgrade --install qbittorrent gabe565/qbittorrent
    --namespace {{ qbittorrent_namespace }}
    --values /tmp/qbittorrent-values.yaml
    {{ '--version ' + qbittorrent_chart_version if qbittorrent_chart_version else '' }}
    --wait
  changed_when: true
  become: no
```

Pattern: `helm upgrade --install` for idempotent deployments.

## Error Handling

### Block/Rescue Pattern
```yaml
- name: Run backup tasks with error handling
  block:
    - name: Check if backup source exists
      # ... tasks ...
  
  rescue:
    - name: Set error message
      ansible.builtin.set_fact:
        backup_error_msg: |
          Backup failed: {{ ansible_failed_result.msg }}
    
    - name: Display error message
      ansible.builtin.debug:
        msg: "{{ backup_error_msg }}"
```

## Unique Project Patterns

### No Handlers
This project doesn't use handlers - services started/restarted directly in tasks.

### Temporary File Location
All temporary manifests/values files written to `/tmp` (no temp directory creation).

### User Detection
```yaml
- name: Get current username
  ansible.builtin.command: whoami
  register: current_user
  changed_when: false
  become: no
```

### No Async Tasks
All tasks run synchronously (no `async` or `poll`).
