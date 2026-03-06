# Infrastructure Provisioning Domain

## Overview
This domain handles the installation and configuration of core infrastructure components required for the homelab: Minikube, kubectl, Helm, Tailscale, Docker, and system dependencies.

## Core Patterns

### Version Management
All infrastructure tools support dynamic "latest" version fetching:

**Example from kubectl role:**
```yaml
- name: Get latest stable kubectl version
  ansible.builtin.uri:
    url: https://dl.k8s.io/release/stable.txt
    return_content: yes
  register: kubectl_stable_version
  when: kubectl_version == "latest"

- name: Set kubectl version fact
  ansible.builtin.set_fact:
    kubectl_install_version: "{{ kubectl_stable_version.content | trim if kubectl_version == 'latest' else kubectl_version }}"
```

**Example from Helm role:**
```yaml
- name: Get latest Helm version
  ansible.builtin.uri:
    url: https://api.github.com/repos/helm/helm/releases/latest
    return_content: yes
  register: helm_latest_release
  when: helm_version == "latest"

- name: Set Helm version fact
  ansible.builtin.set_fact:
    helm_install_version: "{{ helm_latest_release.json.tag_name if helm_version == 'latest' else helm_version }}"
```

### Idempotency Checks
Every installation verifies current state before making changes:

**Example from Minikube role:**
```yaml
- name: Check if Minikube is already installed
  ansible.builtin.stat:
    path: "{{ minikube_install_path }}/minikube"
  register: minikube_binary

- name: Download Minikube binary
  ansible.builtin.get_url:
    url: "https://github.com/kubernetes/minikube/releases/download/{{ minikube_install_version }}/minikube-linux-amd64"
    dest: "{{ minikube_install_path }}/minikube"
    mode: '0755'
  when: not minikube_binary.stat.exists or minikube_version == "latest"
```

### Service Lifecycle Management
Services are started and enabled using systemd:

**Example from base role:**
```yaml
- name: Start and enable Docker service
  ansible.builtin.systemd:
    name: docker
    state: started
    enabled: yes
```

**Example from Tailscale role:**
```yaml
- name: Start and enable Tailscale service
  ansible.builtin.systemd:
    name: tailscaled
    state: started
    enabled: yes
```

### Privilege Handling
Clear separation between root and user operations:

**Example from Minikube role:**
```yaml
- name: Start Minikube cluster
  ansible.builtin.command: >
    minikube start
    --driver={{ minikube_driver }}
    --cpus={{ minikube_cpus }}
    --memory={{ minikube_memory }}
    --disk-size={{ minikube_disk_size }}
    --mount-string="/mnt:/tmp/hostpath-provisioner"
  when: minikube_status.rc != 0
  become: no  # Run as user, not root
  environment:
    CHANGE_MINIKUBE_NONE_USER: "true"
```

### Base System Dependencies
Common packages installed for all infrastructure components:

**Example from base role:**
```yaml
- name: Install common dependencies
  ansible.builtin.apt:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
      - software-properties-common
      - python3-pip
      - git
      - wget
      - zip
      - unzip
      - conntrack
      - socat
      - cifs-utils
      - nfs-common
    state: present
    update_cache: yes
```

## Implementation Details

### Binary Installation Pattern
1. Fetch latest version from API or stable channel
2. Set version fact (either latest or specified)
3. Check if binary already exists
4. Download binary to install path
5. Set executable permissions (0755)
6. Verify installation with version check

### Archive Extraction Pattern (Helm)
1. Create temporary directory
2. Download archive to temp location
3. Extract archive
4. Copy binary from archive to install path
5. Clean up temporary directory

### Repository Management Pattern
Helm repositories added with idempotent loop:

```yaml
- name: Add Helm repositories
  ansible.builtin.command: "helm repo add {{ item.name }} {{ item.url }}"
  loop:
    - { name: "stable", url: "https://charts.helm.sh/stable" }
    - { name: "bitnami", url: "https://charts.bitnami.com/bitnami" }
  changed_when: false
  failed_when: false
  become: no

- name: Update Helm repositories
  ansible.builtin.command: helm repo update
  changed_when: false
  become: no
```

## Role Structure
Each infrastructure component is a separate role:
- `base/` - System dependencies and Docker
- `minikube/` - Kubernetes cluster
- `kubectl/` - Kubernetes CLI
- `helm/` - Kubernetes package manager
- `tailscale/` - VPN mesh network

## Default Variables
All roles have configurable defaults:

**From group_vars/all.yml:**
```yaml
minikube_version: "latest"
minikube_driver: "docker"
minikube_cpus: 2
minikube_memory: "4096"
minikube_disk_size: "20g"

kubectl_version: "latest"
helm_version: "latest"
```

**From role defaults:**
```yaml
# roles/minikube/defaults/main.yml
minikube_install_path: "/usr/local/bin"

# roles/kubectl/defaults/main.yml
kubectl_install_path: "/usr/local/bin"

# roles/helm/defaults/main.yml
helm_install_path: "/usr/local/bin"
```

## Constraints
- Must run as root for system packages and Docker installation
- Must run as non-root user for Minikube and kubectl operations
- Docker service must be running before Minikube start
- All binaries installed to `/usr/local/bin` for system-wide access
- Network connectivity required for version fetching and downloads
