# Ansible Playbooks Style Guide

## Overview
Playbooks orchestrate role execution and define the order of infrastructure provisioning and application deployment.

## File Structure Pattern

### Master Playbook
Uses `import_playbook` to chain other playbooks:

```yaml
---
# Main playbook - runs all provisioning tasks
- name: Import infrastructure playbook
  ansible.builtin.import_playbook: infrastructure.yml

- name: Import applications playbook
  ansible.builtin.import_playbook: applications.yml
```

### Component Playbooks
Single play with multiple roles:

```yaml
---
# Infrastructure components playbook
- name: Install Infrastructure Components
  hosts: all
  become: yes
  
  roles:
    - role: base
      tags: ['base', 'infrastructure']
    
    - role: kubectl
      tags: ['kubectl', 'infrastructure']
    
    - role: helm
      tags: ['helm', 'infrastructure']
```

## Naming Conventions

### Playbook Names
- `site.yml` - Master playbook (runs everything)
- `{category}.yml` - Category-specific playbooks (infrastructure, applications, backup)
- Lowercase with hyphens for multi-word names

### Play Names
- Descriptive action-oriented names
- Format: "{Verb} {Object}" 
- Examples:
  - "Install Infrastructure Components"
  - "Deploy Helm Applications"
  - "Backup Minikube Volumes"

## Play-Level Settings

### Always Include
```yaml
- name: {Play Name}
  hosts: all          # Target hosts
  become: yes         # Privilege escalation
  
  roles:
    - role: {role_name}
      tags: ['{component}', '{category}']
```

### hosts
Always `all` - this project targets single host

### become
Always `yes` at play level (override with `become: no` at task level when needed)

## Role Declaration

### Format
```yaml
roles:
  - role: {role_name}
    tags: ['{component_tag}', '{category_tag}']
```

### Tagging Strategy
Each role has TWO tags:
1. Component-specific tag (role name)
2. Category tag (`infrastructure`, `applications`, `backup`)

Examples:
```yaml
- role: minikube
  tags: ['minikube', 'infrastructure']

- role: helm_apps
  tags: ['applications', 'helm']

- role: backup
  tags: ['backup']
```

## Execution Order

### Infrastructure Before Applications
Always import/execute infrastructure before applications:

```yaml
- ansible.builtin.import_playbook: infrastructure.yml
- ansible.builtin.import_playbook: applications.yml
```

### Role Order Within Playbook
List roles in dependency order:

```yaml
roles:
  - role: base          # System packages, Docker
  - role: apt_updates   # Security updates
  - role: kubectl       # Kubernetes CLI
  - role: helm          # Helm package manager  
  - role: minikube      # Kubernetes cluster (needs Docker)
  - role: tailscale     # VPN
```

## Import vs Include

### Use import_playbook (Static)
For playbook composition:
```yaml
- ansible.builtin.import_playbook: infrastructure.yml
```

NOT include_playbook (dynamic) - we want static parsing for clear execution order.

## File Location
All playbooks in `playbooks/` directory at repository root.

## YAML Formatting

### Document Start
Always start with `---`

### Indentation
- 2 spaces
- No tabs

### Lists
Use hyphen format:
```yaml
roles:
  - role: base
    tags: ['base']
  - role: minikube
    tags: ['minikube']
```

### Tags
Use YAML list syntax: `['tag1', 'tag2']`

## Comments

### Playbook Purpose
Add clear comment at top:
```yaml
---
# Infrastructure components playbook
- name: Install Infrastructure Components
```

### No Inline Comments
Avoid inline comments in playbooks - use descriptive role/play names instead.

## Unique Patterns

### No Variables in Playbooks
All variables in group_vars or role defaults, never in playbooks.

### No Conditionals in Playbooks
Conditionals handled within roles/tasks, not at playbook level.

### Single Play Per Playbook
Each playbook contains exactly one play (except site.yml which imports others).

### No Handlers
This project doesn't use handlers - service management handled explicitly in tasks.

## Example Complete Playbook

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
