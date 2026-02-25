# Ansible Vault Setup

This project uses Ansible Vault to encrypt sensitive credentials. This guide shows you how to set it up.

## Quick Setup

### 1. Create Vault Password File

On your **local machine** (for testing):
```bash
cd /Users/lewisjackson/git/homelab
echo "your-strong-vault-password" > .vault_pass
chmod 600 .vault_pass
```

On the **server** (for deployment):
```bash
cd /home/ubuntu/homelab
echo "your-strong-vault-password" > .vault_pass
chmod 600 .vault_pass
```

**Important:** Use the **same password** on both machines!

### 2. Create Encrypted Vault File

```bash
# Copy the template
cp vault.yml.example vault.yml

# Encrypt it with your actual secrets
ansible-vault encrypt vault.yml

# Edit the encrypted file
ansible-vault edit vault.yml
```

When editing, replace the placeholder values with your actual credentials:

```yaml
---
# Tailscale authentication
vault_tailscale_auth_key: "tskey-auth-xxxxx-YOUR-ACTUAL-KEY"

# Tailscale Operator OAuth
vault_tailscale_oauth_client_id: "kXXXXXXXXXXXXXXXX"
vault_tailscale_oauth_client_secret: "tskey-client-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# Application passwords
vault_pihole_admin_password: "your-strong-password"
```

Save and exit (`:wq` in vim).

### 3. Copy Vault File to Server

```bash
# Copy the encrypted vault file to the server
scp vault.yml server:/home/ubuntu/homelab/vault.yml
```

### 4. Run Playbooks

Ansible will automatically decrypt using `.vault_pass`:

```bash
# On server
cd /home/ubuntu/homelab
ansible-playbook playbooks/site.yml
```

## Common Commands

### View Encrypted File
```bash
ansible-vault view vault.yml
```

### Edit Encrypted File
```bash
ansible-vault edit vault.yml
```

### Change Vault Password
```bash
ansible-vault rekey vault.yml
```

### Encrypt Existing File
```bash
ansible-vault encrypt vault.yml
```

### Decrypt File (not recommended)
```bash
ansible-vault decrypt vault.yml
```

## How It Works

1. **vault.yml** contains encrypted secrets prefixed with `vault_`
2. **group_vars/all.yml** references these: `tailscale_auth_key: "{{ vault_tailscale_auth_key }}"`
3. **ansible.cfg** points to `.vault_pass` for automatic decryption
4. **.gitignore** excludes both `.vault_pass` and `vault.yml` from git

## Security Best Practices

✅ **DO:**
- Keep `.vault_pass` and `vault.yml` in `.gitignore`
- Use strong, unique vault passwords
- Regularly rotate credentials
- Sync `vault.yml` to server securely (scp/rsync)

❌ **DON'T:**
- Commit `.vault_pass` or `vault.yml` to git
- Share vault password via insecure channels
- Use the same password for vault and services
- Decrypt files unnecessarily

## File Structure

```
homelab/
├── .vault_pass              # Vault password (gitignored)
├── vault.yml                # Encrypted secrets (gitignored)
├── vault.yml.example        # Template (committed)
├── group_vars/
│   └── all.yml              # References vault_ variables
└── ansible.cfg              # Points to .vault_pass
```

## Troubleshooting

### "ERROR! Attempting to decrypt but no vault secrets found"
- The file isn't encrypted. Run: `ansible-vault encrypt vault.yml`

### "ERROR! Decryption failed"
- Wrong vault password in `.vault_pass`
- Ensure the same password on local and server

### Variables still empty
- Verify `vault.yml` is in the project root
- Check variable names match: `vault_tailscale_auth_key` not `tailscale_auth_key`
- Run: `ansible-vault view vault.yml` to verify content

### Manual password entry
Remove `vault_password_file` from `ansible.cfg` and use:
```bash
ansible-playbook playbooks/site.yml --ask-vault-pass
```

## Migrating Existing Secrets

If you already have secrets in `roles/helm_apps/defaults/main.yml` on the server:

1. Extract values to `vault.yml`:
   ```bash
   ansible-vault create vault.yml
   # Copy your actual values into it
   ```

2. Reset defaults to reference vault:
   ```bash
   scp roles/ server:/home/ubuntu/homelab/
   ```

3. Run playbook to verify it works

4. Remove hardcoded values from server's `defaults/main.yml`
