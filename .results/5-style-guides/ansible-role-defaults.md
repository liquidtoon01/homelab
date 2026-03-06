# Ansible Role Defaults Style Guide

## Overview
Role defaults define configurable variables with sensible default values. All user-configurable settings should be in defaults, allowing override via group_vars or command-line.

## File Structure

### File Location
`roles/{role-name}/defaults/main.yml`

### Document Format
```yaml
---
# Comments explaining variable group

variable_name: "default_value"
another_variable: value
```

## Naming Conventions

### Variable Prefix
Prefix with role or component name:
```yaml
# roles/minikube/defaults/main.yml
minikube_version: "latest"
minikube_driver: "docker"
minikube_cpus: 2
minikube_memory: "4096"
minikube_disk_size: "20g"
minikube_install_path: "/usr/local/bin"
```

Pattern: `{role_name}_{setting_name}`

### Component-Specific Variables
```yaml
# roles/apt_updates/defaults/main.yml
apt_updates_schedule: "0 3 * * 0"  # Weekly on Sunday at 3 AM
apt_updates_email: ""
```

## Variable Types

### Version Variables
```yaml
minikube_version: "latest"
kubectl_version: "latest"
helm_version: "latest"
```

Default to "latest" for automatic version detection.

### Path Variables
```yaml
minikube_install_path: "/usr/local/bin"
kubectl_install_path: "/usr/local/bin"
helm_install_path: "/usr/local/bin"
```

Absolute paths for binary installation.

### Resource Configuration
```yaml
minikube_driver: "docker"
minikube_cpus: 2
minikube_memory: "4096"  # String with quotes for memory
minikube_disk_size: "20g"  # String with quotes for disk
```

Memory and disk sizes as quoted strings.

### Schedule Variables (Cron Format)
```yaml
apt_updates_schedule: "0 3 * * 0"  # Weekly on Sunday at 3 AM
backup_schedule: "0 2 * * 0"  # Weekly on Sunday at 2 AM
```

Five fields: minute hour day month weekday

### Optional Settings (Empty String)
```yaml
apt_updates_email: ""
pushover_user_key: ""
pushover_api_token: ""
```

Empty string for optional configuration.

### Boolean Settings
```yaml
pushover_enabled: false
```

Lowercase `true` or `false`.

### Numeric Settings
```yaml
pushover_priority: 0  # -2=lowest, -1=low, 0=normal, 1=high, 2=emergency
minikube_cpus: 2
```

No quotes for integers.

## Comments

### Inline Comments for Clarity
```yaml
apt_updates_schedule: "0 3 * * 0"  # Weekly on Sunday at 3 AM
backup_source_dir: /var/lib/docker/volumes/minikube/_data/hostpath-provisioner
pushover_priority: 0  # -2=lowest, -1=low, 0=normal, 1=high, 2=emergency
```

### Section Headers
```yaml
---
# Backup configuration
backup_source_dir: /var/lib/docker/volumes/minikube/_data/hostpath-provisioner
backup_temp_dir: /tmp

# Pushover notification configuration
pushover_enabled: false
pushover_user_key: ""
```

## Value Guidelines

### Sensible Defaults
Choose defaults that work out-of-the-box:
```yaml
minikube_cpus: 2  # Reasonable for most systems
minikube_memory: "4096"  # 4GB RAM
minikube_disk_size: "20g"  # 20GB disk
```

### Empty for User-Provided Values
```yaml
tailscale_target_ip: "100.97.131.29"  # Example IP, user should override
apt_updates_email: ""  # Empty if user doesn't want email notifications
```

### Path Conventions
- Binary install paths: `/usr/local/bin`
- Temp directory: `/tmp`
- Data directories: Full absolute path

## Variable Overrides

### Override Priority
1. Role defaults (lowest priority)
2. group_vars/all.yml
3. Host vars
4. Playbook vars
5. Command-line `-e` (highest priority)

### Commonly Overridden in group_vars
```yaml
# Versions
minikube_version: "latest"
kubectl_version: "latest"

# Resources  
minikube_cpus: 2
minikube_memory: "4096"

# Namespaces (set in group_vars, not role defaults)
gogs_namespace: "git"
sonarr_namespace: "media"
```

## Documentation

### Add Usage Comments
```yaml
---
# Minikube configuration
# Override in group_vars/all.yml or with -e flag

minikube_version: "latest"  # Use "latest" or specific version like "v1.32.0"
minikube_driver: "docker"   # Driver: docker, podman, virtualbox, etc.
```

## Minimal Defaults

### Only Required Variables
Only include variables that:
1. Are referenced in role tasks
2. Need user customization
3. Have sensible defaults

Don't include:
- Variables better suited for group_vars
- Computed values
- Constants

## Real Examples

### Infrastructure Role (minikube)
```yaml
---
minikube_install_path: "/usr/local/bin"
```

Single variable - version and resources set in group_vars.

### Operational Role (backup)
```yaml
---
# Backup configuration
backup_source_dir: /var/lib/docker/volumes/minikube/_data/hostpath-provisioner
backup_temp_dir: /tmp
tailscale_target_ip: "100.97.131.29"
backup_schedule: "0 2 * * 0"  # Weekly on Sunday at 2 AM
homelab_dir: "{{ ansible_facts.env.HOME }}/homelab"

# Pushover notification configuration
pushover_enabled: false
pushover_user_key: ""
pushover_api_token: ""
pushover_priority: 0  # -2=lowest, -1=low, 0=normal, 1=high, 2=emergency
```

Comprehensive configuration with multiple sections.

### System Configuration Role (apt_updates)
```yaml
---
apt_updates_schedule: "0 3 * * 0"  # Weekly on Sunday at 3 AM
apt_updates_email: ""
```

Minimal - only schedule and optional email.

## Unique Patterns

### No Derived Variables
Don't compute variables in defaults - set facts in tasks:
```yaml
# In tasks, not defaults:
- name: Set Helm version fact
  ansible.builtin.set_fact:
    helm_install_version: "{{ helm_latest_release.json.tag_name if helm_version == 'latest' else helm_version }}"
```

### No Secret Defaults
Secrets defined in group_vars/vault.yml, referenced in group_vars/all.yml:
```yaml
# Not in role defaults - in group_vars/all.yml:
tailscale_auth_key: "{{ vault_tailscale_auth_key | default('') }}"
```

### Environment Variable References
```yaml
homelab_dir: "{{ ansible_facts.env.HOME }}/homelab"
```

Use `ansible_facts.env.{VAR}` for environment variables.
