#!/bin/bash
# Bootstrap script to install Ansible on Ubuntu 24.04
# Run this script with: sudo ./bootstrap.sh

set -e

echo "=== Ansible Bootstrap Script ==="
echo "Installing Ansible on Ubuntu 24.04..."

# Update package cache
sudo apt-get update

# Install Git (required to clone this repository if not already done)
echo ""
echo "Installing Git..."
sudo apt-get install -y git

# Install snapd and msedit
echo ""
echo "Installing snapd..."
sudo apt-get install -y snapd

echo "Installing msedit (Snap package)..."
sudo snap install msedit

# Install required packages
sudo apt-get install -y software-properties-common

# Add Ansible PPA repository
sudo add-apt-repository -y ppa:ansible/ansible

# Update package cache again
sudo apt-get update

# Install Ansible
sudo apt-get install -y ansible

# Verify installation
ansible --version

echo ""
echo "=== Configuring SSH Security ==="

# Backup original SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

# Configure SSH hardening
SSH_CONFIG="/etc/ssh/sshd_config"

# Disable root login (uncomment if you want to enforce this)
# sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' $SSH_CONFIG

# Disable password authentication (uncomment after setting up SSH keys)
# sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' $SSH_CONFIG

# Disable empty passwords
sudo sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' $SSH_CONFIG

# Enable public key authentication
sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' $SSH_CONFIG

# Disable X11 forwarding
sudo sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' $SSH_CONFIG

# Set client alive interval (keep connections alive)
grep -q "^ClientAliveInterval" $SSH_CONFIG || sudo bash -c "echo 'ClientAliveInterval 300' >> $SSH_CONFIG"
grep -q "^ClientAliveCountMax" $SSH_CONFIG || sudo bash -c "echo 'ClientAliveCountMax 2' >> $SSH_CONFIG"

# Limit authentication attempts
grep -q "^MaxAuthTries" $SSH_CONFIG || sudo bash -c "echo 'MaxAuthTries 3' >> $SSH_CONFIG"

# Set login grace time
grep -q "^LoginGraceTime" $SSH_CONFIG || sudo bash -c "echo 'LoginGraceTime 60' >> $SSH_CONFIG"

# Restart SSH service to apply changes
sudo systemctl restart sshd

echo "SSH configuration hardened"
echo "Backup saved to: /etc/ssh/sshd_config.backup.*"
echo ""
echo "⚠️  IMPORTANT SSH SECURITY NOTES:"
echo "1. The following settings are COMMENTED for safety:"
echo "   - PermitRootLogin no (uncomment to disable root SSH access)"
echo "   - Password and Git Authentication no (uncomment AFTER setting up SSH keys)"
echo "2. To disable password auth, first ensure you can login with SSH keys"
echo "3. Uncommenting these requires editing /etc/ssh/sshd_config and restarting sshd"
echo ""

echo "=== Bootstrap completed successfully ==="
echo "Installed: Git, Snapd, msedit, and Ansible"
echo "You can now run the playbooks with:"
echo "  ansible-playbook -i inventory/hosts.yml playbooks/site.yml"
