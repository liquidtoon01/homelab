# Bootstrap Guide

This guide walks you through the initial setup of your Kimsufi infrastructure.

## Prerequisites

- Fresh Ubuntu 24.04 LTS installation
- Root or sudo access
- Internet connection
- Minimum 4GB RAM
- Minimum 20GB disk space

## Step 1: Initial System Preparation

Connect to your server via SSH:

```bash
ssh user@your-server-ip
```

## Step 2: Clone the Repository

First, install Git and clone this repository:

```bash
# Update package cache and install git
sudo apt-get update
sudo apt-get install -y git

# Clone the repository
git clone https://github.com/YOUR_USERNAME/kimsufi.git
cd kimsufi
```

Replace `YOUR_USERNAME` with your actual GitHub username or use your repository URL.

## Step 3: Run Bootstrap Script

The bootstrap script installs Git, snapd, msedit, Ansible, and configures SSH security:

```bash

# Make bootstrap script executable
chmod +x bootstrap.sh

# Run the bootstrap script
sudo ./bootstrap.sh
```

The script will:
- Update the system package cache
- Install Git (if not already present)
- Install snapd (Snap package manager)
- Install msedit (text editor via Snap)
- Add the Ansible PPA repository
- Install Ansible and required dependencies
- Configure SSH security hardening
- Verify the installation

### SSH Security Hardening

The bootstrap script automatically hardens SSH configuration:

**Applied Settings:**
- ✅ Public key authentication enabled
- ✅ Empty passwords disabled
- ✅ X11 forwarding disabled
- ✅ Client alive interval set (maintains connections)
- ✅ Max authentication attempts limited to 3
- ✅ Login grace time set to 60 seconds
- 📁 Original config backed up to `/etc/ssh/sshd_config.backup.*`

**Optional Settings (commented for safety):**
- 🔒 `PermitRootLogin no` - Uncomment to disable root SSH access
- 🔒 `PasswordAuthentication no` - Uncomment to require SSH keys only

**To enable strict SSH key-only authentication:**

1. First, ensure you have SSH key access working:
   ```bash
   # On your local machine (if not done already)
   ssh-copy-id user@your-server-ip
   
   # Test SSH key login
   ssh user@your-server-ip
   ```

2. If key login works, edit SSH config on the server:
   ```bash
   sudo nano /etc/ssh/sshd_config
   ```

3. Uncomment or set these lines:
   ```
   PermitRootLogin no
   PasswordAuthentication no
   ```

4. Restart SSH:
   ```bash
   sudo systemctl restart sshd
   ```

⚠️ **Warning**: Only disable password authentication AFTER confirming SSH key authentication works!

## Step 4: Configure Inventory

Edit the inventory file to match your setup:

```bash
nano inventory/hosts.yml
```

For local installation (on the same server):
```yaml
all:
  hosts:
    kimsufi:
      ansible_host: localhost
      ansible_connection: local
```

For remote installation:
```yaml
all:
  hosts:
    kimsufi:
      ansible_host: your.server.ip
      ansible_user: your_user
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

## Step 5: Configure Variables

Edit global variables if needed:

```bash
nano group_vars/all.yml
```

Key variables to review:
- `tailscale_auth_key`: Your Tailscale authentication key (optional)
- `minikube_cpus`, `minikube_memory`: Adjust based on your server resources
- Application namespaces and configurations

## Step 6: Run the Playbooks

### Option A: Install Everything

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

### Option B: Install Infrastructure Only

```bash
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml
```

### Option C: Install Applications Only (requires infrastructure)

```bash
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml
```

## Step 7: Verify Installation

Check that all components are running:

```bash
# Check Minikube status
minikube status

# Check Kubernetes nodes
kubectl get nodes

# Check Helm version
helm version

# Check deployed applications
kubectl get pods --all-namespaces

# Check Tailscale status
tailscale status
```

## Next Steps

- [SSH Security Guide](ssh-security.md) - Harden SSH and set up key authentication
- [Infrastructure Components](infrastructure.md) - Learn about each component
- [Applications](applications.md) - Access and configure your applications
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

## Security Recommendations

1. **SSH Security**: 
   - Set up SSH key authentication if not already done
   - Consider disabling password authentication (see SSH hardening above)
   - Optionally disable root SSH login
   - Review SSH logs regularly: `sudo tail -f /var/log/auth.log`
2. **Change default passwords**: Update all default credentials in `group_vars/all.yml`
3. **Configure Tailscale**: Set up Tailscale for secure remote access
4. **Enable firewall**: Configure UFW to restrict access
   ```bash
   sudo ufw allow OpenSSH
   sudo ufw enable
   ```
5. **Regular updates**: The system is configured for automatic updates, but monitor logs
6. **Backup strategy**: Implement regular backups of persistent data

## Estimated Installation Time

- Bootstrap: 2-5 minutes
- Infrastructure: 10-15 minutes
- Applications: 15-30 minutes (depending on image download speeds)
- **Total: 30-50 minutes**
