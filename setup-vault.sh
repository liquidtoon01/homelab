#!/bin/bash
# Ansible Vault Setup Script

set -e

echo "=== Ansible Vault Setup ==="
echo ""

# Check if .vault_pass exists
if [ -f .vault_pass ]; then
    echo "✓ .vault_pass already exists"
else
    echo "Creating .vault_pass..."
    read -sp "Enter vault password: " VAULT_PASS
    echo ""
    read -sp "Confirm vault password: " VAULT_PASS_CONFIRM
    echo ""
    
    if [ "$VAULT_PASS" != "$VAULT_PASS_CONFIRM" ]; then
        echo "❌ Passwords don't match!"
        exit 1
    fi
    
    echo "$VAULT_PASS" > .vault_pass
    chmod 600 .vault_pass
    echo "✓ Created .vault_pass"
fi

# Check if vault.yml exists
if [ -f vault.yml ]; then
    echo "⚠ vault.yml already exists"
    read -p "Do you want to edit it? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ansible-vault edit vault.yml
    fi
else
    echo "Creating vault.yml from template..."
    if [ -f vault.yml.example ]; then
        cp vault.yml.example vault.yml
        echo "✓ Copied vault.yml.example to vault.yml"
        echo "Now encrypting vault.yml..."
        ansible-vault encrypt vault.yml
        echo "✓ Encrypted vault.yml"
        echo ""
        echo "Opening vault.yml for editing..."
        echo "Replace the placeholder values with your actual secrets."
        sleep 2
        ansible-vault edit vault.yml
    else
        echo "❌ vault.yml.example not found!"
        exit 1
    fi
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Copy vault.yml to your server:"
echo "   scp vault.yml server:/home/ubuntu/homelab/vault.yml"
echo ""
echo "2. Copy .vault_pass to your server:"
echo "   scp .vault_pass server:/home/ubuntu/homelab/.vault_pass"
echo "   ssh server 'chmod 600 /home/ubuntu/homelab/.vault_pass'"
echo ""
echo "3. Run your playbook:"
echo "   ssh server 'cd /home/ubuntu/homelab && ansible-playbook playbooks/site.yml'"
echo ""
