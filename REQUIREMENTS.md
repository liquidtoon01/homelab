# Requirements

This file documents the requirements for running this infrastructure.

## System Requirements

### Hardware
- **CPU**: Minimum 2 cores (4+ recommended)
- **RAM**: Minimum 4GB (8GB+ recommended)
- **Disk**: Minimum 20GB free space (100GB+ recommended for media storage)
- **Network**: Stable internet connection for initial setup

### Software
- **OS**: Ubuntu 24.04 LTS (bare-metal or VM)
- **Access**: Root or sudo privileges
- **SSH**: For remote management (optional)
- **SSH Keys**: Recommended for secure authentication (optional but strongly recommended)

## Pre-Installation Recommendations

### SSH Key Setup (Recommended)

Before running the bootstrap script, it's recommended to set up SSH key authentication:

**On your local machine:**
```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy the key to your server
ssh-copy-id user@your-server-ip

# Test the connection
ssh user@your-server-ip
```

**Why?** The bootstrap script hardens SSH security. Having SSH keys set up beforehand ensures you maintain access even if you later disable password authentication.

## Installed by Bootstrap

The following are automatically installed by the bootstrap script and Ansible playbooks:

### SSH Security Hardening

The bootstrap script automatically configures:
- Public key authentication enabled
- Empty passwords disabled
- X11 forwarding disabled
- Connection keep-alive (prevents timeouts)
- Max authentication attempts limited to 3
- Login grace time set to 60 seconds
- Original SSH config backed up

Optional settings (commented for safety):
- Disable root login
- Disable password authentication (enable after SSH key setup)

### System Packages
- git (version control - installed first by bootstrap)
- ansible
- software-properties-common
- apt-transport-https
- ca-certificates
- curl
- gnupg
- lsb-release
- python3-pip
- git
- wget
- unzip
- docker.io
- docker-compose
- conntrack
- socat
- unattended-upgrades
- tailscale

### Kubernetes Tools
- kubectl (latest stable)
- minikube (latest)
- helm (latest)

## Python Dependencies (Optional)

If you want to use the kubernetes.core Ansible collection:

```bash
pip3 install kubernetes
ansible-galaxy collection install kubernetes.core
```

Note: The playbooks are designed to work without this, falling back to kubectl commands.

## Ansible Collections

Already installed via Ansible Galaxy (if needed):

```bash
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install community.general
```

## External Services (Optional)

### Tailscale
- Account at https://tailscale.com
- Auth key from https://login.tailscale.com/admin/settings/keys

### DNS (Recommended for Production)
- Domain name
- DNS provider with API access (for Let's Encrypt)

### Backup Storage (Recommended)
- External backup location
- S3-compatible storage for backups

## Network Ports

The following ports are used (all on localhost/Minikube by default):

- **Gogs**: 3000 (HTTP), 22 (SSH)
- **Sonarr**: 8989
- **qBittorrent**: 8080
- **Headscale**: 8080
- **Kubernetes API**: 8443 (Minikube)

## Post-Installation

After installation, you should:

1. **Harden SSH security** (if not done yet):
   - Ensure SSH key authentication is working
   - Consider disabling password authentication
   - Optionally disable root SSH login
   - Review changes in `/etc/ssh/sshd_config`

2. **Change default passwords**:
   - Gogs admin password
   - qBittorrent admin password
   - Pi-hole admin password

3. **Configure Tailscale** (if used):
   - Set auth key in group_vars/all.yml
   - Re-run playbooks

4. **Set up backups**:
   - Configure backup strategy
   - Test restore procedures

5. **Configure monitoring** (optional):
   - Prometheus
   - Grafana
   - Alertmanager

## Verification

After installation, verify everything is working:

```bash
# Check all components
make status

# Or manually:
minikube status
kubectl get nodes
kubectl get pods --all-namespaces
helm list --all-namespaces
tailscale status
```

## Updating

To update components:

```bash
# Update Helm repositories
helm repo update

# Update specific application
helm upgrade <release-name> <chart> -n <namespace>

# Re-run infrastructure playbook for system updates
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml
```

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for detailed troubleshooting steps.
