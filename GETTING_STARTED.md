# Getting Started

Complete guide to set up and manage your homelab infrastructure.

## Quick Start

For a fresh Ubuntu 24.04 server:

```bash
# 1. Clone the repository
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/YOUR_USERNAME/homelab.git
cd homelab

# 2. Run bootstrap (installs Ansible, configures SSH)
sudo bash bootstrap.sh

# 3. Configure Tailscale OAuth (required for LoadBalancer services)
# Get OAuth credentials from: https://login.tailscale.com/admin/settings/oauth
nano group_vars/all.yml
# Set: tailscale_oauth_client_id: "your-client-id"
# Set: tailscale_oauth_client_secret: "your-client-secret"

# 4. Deploy everything
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

Installation takes 30-50 minutes.

## Prerequisites

- Ubuntu 24.04 LTS server (bare-metal or VM)
- Root or sudo access
- SSH access
- Internet connection

## Detailed Setup Steps

### 1. Clone Repository

```bash
ssh user@your-server-ip
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/YOUR_USERNAME/homelab.git
cd homelab
```


### 2. Run Bootstrap

The bootstrap script installs Ansible and configures SSH security:

```bash
sudo bash bootstrap.sh
```

This installs Git, snapd, msedit, Ansible, and hardens SSH (public key auth enabled, password auth still allowed, max 3 login attempts). Takes 2-5 minutes.

**Optional SSH Hardening:**

After setting up SSH keys, disable password authentication:

```bash
sudo nano /etc/ssh/sshd_config
# Uncomment: PasswordAuthentication no
# Uncomment: PermitRootLogin no
sudo systemctl restart sshd
```

**Warning:** Only do this after confirming SSH key login works.

### 3. Configure Variables

Edit `group_vars/all.yml`:

```yaml
# Minikube resources
minikube_cpus: 2
minikube_memory: "4096"
minikube_disk_size: "20g"

# Tailscale Operator (REQUIRED for LoadBalancer services)
# Create OAuth client at: https://login.tailscale.com/admin/settings/oauth
tailscale_oauth_client_id: "your-client-id"
tailscale_oauth_client_secret: "your-client-secret"

# Optional: Tailscale auth key
tailscale_auth_key: ""

# Application passwords (CHANGE THESE)
pihole_admin_password: "changeme"
```

**Tailscale OAuth Setup:**

1. Visit [Tailscale OAuth Clients](https://login.tailscale.com/admin/settings/oauth)
2. Generate OAuth Client named "Kubernetes Operator"
3. Copy Client ID and Secret to `group_vars/all.yml`

See [Tailscale Operator Setup](docs/tailscale-operator.md) for details.

### 4. Configure Inventory

Local installation (default): No changes needed.

Remote installation: Edit `inventory/hosts.yml`:

```yaml
all:
  hosts:
    homelab:
      ansible_host: your.server.ip
      ansible_user: your_user
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

### 5. Deploy

Run the main playbook (30-50 minutes):

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

Installs:
- Infrastructure: Docker, kubectl, Helm, Minikube, Tailscale, Tailscale Operator
- Storage: local-path-provisioner
- Applications: Gogs, Sonarr, qBittorrent, Pi-hole

### 6. Verify Installation

```bash
# Check Minikube
minikube status

# Check Kubernetes
kubectl get nodes
kubectl get pods --all-namespaces

# Or use convenience command
make status
```

## What Gets Installed

**Infrastructure:**
- Docker
- kubectl
- Helm
- Minikube (Kubernetes cluster)
- Tailscale (VPN)
- Tailscale Operator (LoadBalancer ingress)
- Scheduled system updates

**Applications:**
- Gogs (Git server)
- Sonarr (TV shows)
- qBittorrent (Downloads)
- Pi-hole (DNS/Ad blocker)

## Accessing Applications

### Via Tailscale (Recommended)

Connect to your Tailnet, then access:
- Gogs: `http://gogs:3000`
- Sonarr: `http://sonarr:8989`
- qBittorrent: `http://qbittorrent:8080`
- Pi-hole: `http://pihole/admin`

### Via NodePort (Fallback)

```bash
# List all services
minikube service list

# Or use convenience command
make services

# Open specific service
minikube service gogs-http -n git
```

## Default Credentials

**Gogs:** Set during first run

**qBittorrent:**
- Username: `admin`
- Password: `adminadmin` (CHANGE THIS)

**Pi-hole:**
- Password: `changeme` (CHANGE THIS)

## Common Commands

### Make Shortcuts

```bash
make status          # Check everything
make services        # View service URLs
make check          # Check for issues
make logs-gogs      # View Gogs logs
make logs-sonarr    # View Sonarr logs
```

### Kubectl Commands

```bash
# View all pods
kubectl get pods --all-namespaces

# View specific namespace
kubectl get pods -n git

# View logs
kubectl logs -n <namespace> <pod-name> -f

# Describe pod
kubectl describe pod -n <namespace> <pod-name>

# Shell into pod
kubectl exec -it -n <namespace> <pod-name> -- /bin/sh

# Check storage
kubectl get pvc --all-namespaces

# Restart deployment
kubectl rollout restart deployment -n <namespace> <deployment-name>
```

### Minikube Commands

```bash
# Stop/Start
minikube stop
minikube start

# Get IP
minikube ip

# SSH into cluster
minikube ssh
```

### Helm Commands

```bash
# Update repositories
helm repo update

# List releases
helm list --all-namespaces

# Upgrade application
helm upgrade -n <namespace> <release-name> <repo>/<chart>
```

## Common Tasks

### View Logs

```bash
kubectl logs -n git -l app=gogs --tail=100 -f
kubectl logs -n media -l app=sonarr --tail=100 -f
```

### Restart Application

```bash
# Delete pod (auto-recreates)
kubectl delete pod -n <namespace> <pod-name>

# Or restart deployment
kubectl rollout restart deployment -n <namespace> <deployment-name>
```

### Update Application

```bash
helm repo update
helm upgrade -n git gogs keyporttech/gogs
helm upgrade -n media sonarr pree/sonarr
helm upgrade -n media qbittorrent gabe565/qbittorrent
```

### Remote kubectl Access

Set up SSH tunnel to manage cluster remotely:

```bash
# On server, get Kubernetes API endpoint
minikube kubectl -- config view --minify --output jsonpath='{.clusters[0].cluster.server}'

# On local machine, create SSH tunnel
ssh -L 8443:$(minikube ip):8443 user@your-server-ip -N

# Copy kubeconfig from server
cat ~/.kube/config  # Run on server

# Edit local ~/.kube/config
# Change server URL to: https://localhost:8443
# Add: insecure-skip-tls-verify: true

# Test connection
kubectl get nodes
```

Alternative using sshuttle:

```bash
brew install sshuttle  # macOS
sshuttle -r user@your-server-ip $(minikube ip)/24
```

### Storage Management

```bash
# Access Minikube storage
minikube ssh
cd /opt/local-path-provisioner/
ls -la

# Check disk usage
df -h /opt/local-path-provisioner/
```

### Backup

```bash
# Backup Gogs
kubectl exec -n git <pod-name> -- tar czf /tmp/backup.tar.gz /data
kubectl cp git/<pod-name>:/tmp/backup.tar.gz ./gogs-backup.tar.gz
```

## Troubleshooting

### Can't Access Services

```bash
minikube service list
# Or use port forwarding
kubectl port-forward -n <namespace> svc/<service-name> 8080:80
```

### Pods Not Starting

```bash
kubectl get pods --all-namespaces
kubectl describe pod -n <namespace> <pod-name>
kubectl logs -n <namespace> <pod-name>
```

### Out of Disk Space

```bash
df -h
minikube ssh
docker system prune -a
```

### Minikube Won't Start

```bash
minikube delete
minikube start --driver=docker
```

### Pod Stuck Pending

```bash
kubectl describe pod -n <namespace> <pod-name>
# Usually storage or resource issues
```

See [docs/troubleshooting.md](docs/troubleshooting.md) for more help.

## Performance Tuning

Increase Minikube resources in `group_vars/all.yml`:

```yaml
minikube_cpus: 4
minikube_memory: "8192"
minikube_disk_size: "50g"
```

Then recreate:

```bash
minikube delete
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml --tags minikube
```

## Next Steps

### 1. Secure Installation

Change all default passwords in `group_vars/all.yml`:

```yaml
pihole_admin_password: "strong-password-here"
```

Re-run:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml
```

### 2. Configure Pi-hole DNS

**Router-level (recommended):**
Set DHCP DNS server to your server's IP

**Per-device:**
Get Pi-hole IP: `minikube service pihole-dns -n pihole --url`

### 3. Set Up Backups

**Automated Backup:**

Backup all Minikube volumes and send via Tailscale:

```bash
# Using Make
make backup

# Using Ansible directly
ansible-playbook -i inventory/hosts.yml playbooks/backup.yml
```

This will:
- Create a timestamped zip archive of `/var/lib/docker/volumes/minikube/_data/hostpath-provisioner`
- Send the backup to your Tailscale device (default: 100.97.131.29)
- Clean up temporary files

**Manual Backup:**

Important data locations:
- Gogs repositories: Inside Minikube volumes
- Pi-hole configuration: Inside Minikube volumes
- All persistent data: `/var/lib/docker/volumes/minikube/_data/hostpath-provisioner`

See [docs/applications.md](docs/applications.md) for application-specific backup procedures.

**Configure Backup Target:**

Edit `roles/backup/defaults/main.yml` to change:
- `tailscale_target_ip`: Target device IP (default: 100.97.131.29)
- `backup_source_dir`: Source directory to backup

### 4. Security Best Practices

- Set up SSH key authentication
- Disable SSH password authentication (after confirming keys work)
- Change all default passwords
- Set up Tailscale for secure remote access
- Regular backups
- Monitor logs
- Don't expose services directly to internet without proxy/SSL

## Documentation

- [README.md](README.md) - Project overview
- [docs/bootstrap.md](docs/bootstrap.md) - Bootstrap details
- [docs/ssh-security.md](docs/ssh-security.md) - SSH hardening
- [docs/infrastructure.md](docs/infrastructure.md) - Infrastructure components
- [docs/applications.md](docs/applications.md) - Application configuration
- [docs/tailscale-operator.md](docs/tailscale-operator.md) - Tailscale setup
- [docs/troubleshooting.md](docs/troubleshooting.md) - Troubleshooting guide

---

Complete self-hosted infrastructure with Kubernetes, Git server, media management, ad blocking, and VPN.
