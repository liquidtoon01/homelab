# Documentation Style Guide

## Overview
Documentation files provide user guides, reference material, and operational procedures. Written in Markdown format.

## File Organization

### Root Level Documentation
- **README.md** - Project overview, quick start, high-level structure
- **GETTING_STARTED.md** - Detailed setup guide
- **REQUIREMENTS.md** - Prerequisites and system requirements

### docs/ Directory
Detailed topic-specific documentation:
- `ANSIBLE_VAULT.md` - Vault setup and usage
- `PROJECT_STRUCTURE.md` - Codebase organization
- `applications.md` - Application details
- `bootstrap.md` - Bootstrap process
- `infrastructure.md` - Infrastructure components
- `ssh-security.md` - SSH hardening
- `tailscale-operator.md` - Tailscale setup
- `troubleshooting.md` - Common issues

### Role Documentation
- `roles/{role}/README.md` - Role-specific documentation

## Markdown Structure

### Document Header
```markdown
# Document Title

Brief description of document purpose.

## Overview

High-level introduction...
```

### Section Hierarchy
```markdown
# Top Level (Document Title)
## Major Sections
### Subsections
#### Detail Sections
```

Use up to 4 levels of headers.

## Code Blocks

### Shell Commands
````markdown
```bash
sudo bash bootstrap.sh
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```
````

Language identifier: `bash`, `sh`, or no language for generic shell.

### YAML Configuration
````markdown
```yaml
minikube_version: "latest"
minikube_cpus: 2
minikube_memory: "4096"
```
````

### File Paths
````markdown
```
roles/
├── base/
├── minikube/
└── helm_apps/
```
````

No language identifier for file trees.

### Inline Code
```markdown
Edit `inventory/hosts.yml` to specify your target host(s).
```

Use backticks for:
- File names
- Commands
- Variables
- Configuration values

## Lists

### Bulleted Lists
```markdown
- **Minikube** - Local Kubernetes cluster
- **kubectl** - Kubernetes CLI
- **Helm** - Kubernetes package manager
```

Pattern: **Bold** for component name, dash, description.

### Numbered Lists
```markdown
### 1. Clone the Repository

Clone this repository:

```bash
git clone https://github.com/YOUR_USERNAME/homelab.git
cd homelab
```

### 2. Bootstrap Ansible

Run the bootstrap script:

```bash
sudo bash bootstrap.sh
```
```

Use numbered headers (not numbered list items) for step-by-step procedures.

### Nested Lists
```markdown
- Main item
  - Sub-item
  - Another sub-item
- Another main item
```

Two spaces for nest level.

## Links

### Internal Links
```markdown
- [Getting Started Guide](GETTING_STARTED.md)
- [Bootstrap Guide](docs/bootstrap.md)
```

Relative paths from document location.

### External Links
```markdown
[Ansible Documentation](https://docs.ansible.com/)
```

## Tables

### Configuration Reference
```markdown
| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `alseambusher/crontab-ui` |
```

## Formatting Conventions

### Bold Text
```markdown
**Important concept**
**Component Name** - Description
```

Use for:
- Component names in lists
- Important terms
- Emphasis

### Italic Text
Rarely used - prefer bold or code formatting.

### File/Directory References
```markdown
`inventory/hosts.yml`
`roles/minikube/defaults/main.yml`
`.vault_pass`
```

Always use inline code for paths.

### Commands
```markdown
Run `make install` to deploy everything.
```

Inline code for short commands in text.

### URLs
```markdown
Service accessible at `http://gogs` via Tailscale.
```

Inline code for URLs.

## README.md Pattern

### Structure
```markdown
# Project Name

Brief project description.

## Overview

What this project does:
- Component list
- Application list

## Quick Start

### 1. Step Name
Instructions...

### 2. Step Name
Instructions...

## Project Structure

```
directory tree
```

## Documentation

- [Link to doc](doc.md)
- [Link to another doc](doc2.md)

## Commands

Usage examples...
```

### Key Sections
1. Title and description
2. Overview with bullet points
3. Quick start steps
4. Project structure
5. Documentation links
6. Common commands

## Documentation Topics

### Setup Guides
Step-by-step instructions:
- Bootstrap process
- Vault configuration
- First-time deployment

### Reference Documentation
Technical details:
- Project structure
- Architecture decisions
- Configuration options

### Operational Procedures
How-to guides:
- Backup and restore
- Troubleshooting
- Service management

### Component Documentation
Individual service/tool docs:
- Tailscale operator
- SSH security
- Applications

## Quick Start Formatting

### Number Steps (as Headers)
```markdown
### 1. Clone the Repository
### 2. Bootstrap Ansible
### 3. Configure Inventory
```

### Include Commands in Code Blocks
```markdown
### 2. Bootstrap Ansible

Run the bootstrap script:

```bash
sudo bash bootstrap.sh
```
```

### Show Example Output (when helpful)
```markdown
Expected output:
```
Ansible 2.15.0
  ...
```
```

## Command Examples

### Format
```markdown
```bash
# Comment explaining command
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```
```

### Alternative Commands
```markdown
Or run specific playbooks:

```bash
# Install only infrastructure components
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml

# Deploy only Helm applications
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml
```
```

## Configuration Examples

### Show Full Context
```markdown
Edit `inventory/hosts.yml`:

```yaml
---
all:
  hosts:
    kimsufi:
      ansible_host: localhost
      ansible_connection: local
```
```

### Highlight Changes
```markdown
Update in `group_vars/all.yml`:

```yaml
minikube_cpus: 4  # Increase from default 2
minikube_memory: "8192"  # Increase from default 4096
```
```

## Service Access Documentation

### Format for URLs
```markdown
- **Gogs** - Self-hosted Git service (accessible via Tailscale at `http://gogs`)
- **Sonarr** - PVR for TV shows (accessible via Tailscale at `http://sonarr`)
```

Pattern: **Name** - Description (accessible via Tailscale at `http://hostname`)

## Troubleshooting Format

### Problem/Solution Structure
```markdown
### Issue: Minikube fails to start

**Symptoms:**
- Error message xyz
- Command abc fails

**Cause:**
Docker not running

**Solution:**
```bash
sudo systemctl start docker
minikube start
```
```

## Comment Style

### Explanatory Comments
```markdown
```bash
# Clone this repository
git clone https://github.com/YOUR_USERNAME/homelab.git
cd homelab
```
```

Brief comment above command.

### Placeholder Comments
```markdown
```yaml
ansible_host: your.server.ip
ansible_user: your_user
```
```

Use `your_` prefix for user-replaceable values.

## Unique Project Patterns

### Emphasis on Tailscale Access
Always mention that services are accessible via Tailscale, not publicly.

### localhost Default
Documentation assumes localhost deployment first, remote as secondary option.

### Makefile Integration
Always mention both Make and Ansible commands:
```markdown
```bash
# Using Make
make install

# Using Ansible directly
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```
```

### Ubuntu 24.04 Target
Documentation specifies Ubuntu 24.04 (Noble) as target platform.

### No Windows/macOS Instructions
Focus exclusively on Ubuntu Linux.

### Security Notes
Emphasize:
- Vault encryption for secrets
- VPN-only access
- No public exposure
