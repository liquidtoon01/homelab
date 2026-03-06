# Bootstrap Scripts Style Guide

## Overview
Shell scripts for initial system setup, Ansible installation, and vault configuration. Run before Ansible playbooks.

## Script Types

### bootstrap.sh
Main bootstrap script - installs Ansible and dependencies:
- Location: Repository root
- Requires: sudo
- Purpose: Install Ansible, Git, snapd, system dependencies

### setup-vault.sh
Configure Ansible Vault for encrypted secrets:
- Location: Repository root
- Purpose: Create and encrypt vault.yml

### verify.sh
Verify system readiness:
- Location: Repository root
- Purpose: Check prerequisites

## Shebang and Options

### Standard Header
```bash
#!/bin/bash
# Script description

set -e  # Exit on error
```

### set -e
Always use `set -e` to exit on first error.

## Script Structure Pattern

```bash
#!/bin/bash
# Bootstrap script description
# Run this script with: sudo ./bootstrap.sh

set -e

echo "=== Section Name ==="
echo "Description of what's happening..."

# Commands
command1
command2

echo ""
echo "=== Next Section ==="
# More commands
```

## Output Formatting

### Section Headers
```bash
echo ""
echo "=== Installing Git ==="
```

Pattern:
- Empty line before section
- Triple equals (===) around section name
- Descriptive action name

### Progress Messages
```bash
echo "Installing Git..."
sudo apt-get install -y git

echo "Installing Ansible..."
sudo apt-get install -y ansible
```

## Command Patterns

### APT Operations
```bash
# Update package cache
sudo apt-get update

# Install packages
sudo apt-get install -y software-properties-common

# Add repository
sudo add-apt-repository -y ppa:ansible/ansible

# Update again after adding repo
sudo apt-get update

# Install from new repo
sudo apt-get install -y ansible
```

Pattern: Always use `-y` flag for non-interactive installation.

### Verification Commands
```bash
# Verify installation
ansible --version

echo ""
echo "Ansible installed successfully!"
```

### Snap Package Installation
```bash
echo "Installing msedit (Snap package)..."
sudo snap install msedit
```

## Configuration File Modification

### Backup Before Modify
```bash
# Backup original SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
```

Timestamp format: `YYYYMMDD_HHMMSS`

### sed In-Place Editing
```bash
SSH_CONFIG="/etc/ssh/sshd_config"

# Limit max authentication attempts
sudo sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' "$SSH_CONFIG"

# Restart service to apply changes
sudo systemctl restart sshd
```

Pattern:
- Variable for config file path
- `sed -i` for in-place editing
- Regular expression to match commented or uncommented lines
- Restart service after modification

## User Interaction

### Confirmation Prompts
```bash
if [ -f "vault.yml" ]; then
    echo "vault.yml already exists."
    read -p "Do you want to edit it? (y/n): " edit_choice
    if [ "$edit_choice" = "y" ]; then
        ansible-vault edit vault.yml
    fi
    exit 0
fi
```

Pattern:
- Check for existing files before overwriting
- Use `read -p` for prompts
- Simple y/n choices

### Editor Selection
```bash
$EDITOR vault.yml
```

Use `$EDITOR` environment variable for user's preferred editor.

## File Operations

### Copy with Backup
```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
```

### Copy Example Files
```bash
# Copy example to actual file
cp vault.yml.example vault.yml
```

### File Existence Checks
```bash
if [ -f "vault.yml" ]; then
    echo "File exists"
fi
```

## Ansible Vault Operations

### Encrypt File
```bash
ansible-vault encrypt vault.yml
```

### Edit Encrypted File
```bash
ansible-vault edit vault.yml
```

### Create New Vault
```bash
cp vault.yml.example vault.yml
$EDITOR vault.yml
ansible-vault encrypt vault.yml
```

## Service Management

### Systemd Operations
```bash
# Restart service
sudo systemctl restart sshd

# Check status
sudo systemctl status docker --no-pager
```

Use `--no-pager` when displaying status in scripts.

## Exit Codes

### Early Exit After Check
```bash
if [ -f "vault.yml" ]; then
    # Handle existing file
    exit 0
fi
```

### Success Message and Exit
```bash
echo ""
echo "vault.yml created and encrypted!"
echo "To edit in the future: ansible-vault edit vault.yml"
exit 0
```

## Comments

### Header Comments
```bash
#!/bin/bash
# Bootstrap script to install Ansible on Ubuntu 24.04
# Run this script with: sudo ./bootstrap.sh
```

Include:
- Script purpose
- How to run (sudo requirement)
- Platform (if specific)

### Section Comments
```bash
# Install Git (required to clone this repository if not already done)
```

### Inline Clarification
```bash
# Disable root login (uncomment if you want to enforce this)
# sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
```

Comment out optional/dangerous operations with explanation.

## Variable Usage

### Path Variables
```bash
SSH_CONFIG="/etc/ssh/sshd_config"
sudo sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' "$SSH_CONFIG"
```

### Quote Variables
```bash
"$SSH_CONFIG"  # Quoted to handle spaces
```

## Error Handling

### set -e for Automatic Exit
```bash
set -e  # Exit on any error
```

All commands checked automatically - script stops on first failure.

### Manual Error Checking (if needed)
```bash
if ! command -v ansible &> /dev/null; then
    echo "Ansible installation failed"
    exit 1
fi
```

## Installation Patterns

### System Packages
```bash
sudo apt-get install -y package-name
```

### Snap Packages
```bash
sudo snap install package-name
```

### PPA Repositories
```bash
sudo add-apt-repository -y ppa:name/repo
sudo apt-get update
sudo apt-get install -y package-from-ppa
```

## Completion Messages

### Success Confirmation
```bash
echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "Ansible installed successfully!"
echo ""
echo "Next steps:"
echo "1. Configure inventory: inventory/hosts.yml"
echo "2. Run playbook: ansible-playbook -i inventory/hosts.yml playbooks/site.yml"
```

Pattern:
- Clear success message
- Next steps for user
- Command examples

## Unique Project Patterns

### Bootstrap Order
1. Update apt cache
2. Install Git
3. Install snapd and packages
4. Add Ansible PPA
5. Update apt cache again
6. Install Ansible
7. Configure SSH (optional)
8. Verify installation

### Root Requirement
All bootstrap scripts require sudo/root:
```bash
# Run this script with: sudo ./bootstrap.sh
```

### Ubuntu-Specific
Scripts target Ubuntu 24.04 (Noble):
```bash
sudo apt-get ...
sudo add-apt-repository -y ppa:ansible/ansible
```

### No Error Recovery
Scripts use `set -e` - abort on any error, don't attempt recovery.

### Minimal Dependencies
Scripts use only basic shell features:
- No advanced bash features
- Basic conditionals only
- Simple variable substitution
- Standard Unix utilities (apt, sed, systemctl)
