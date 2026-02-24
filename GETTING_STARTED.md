# Getting Started

This guide will help you get this infrastructure up and running from scratch.

## Prerequisites

Before you begin, ensure you have:
- A fresh Ubuntu 24.04 LTS server (bare-metal or VM)
- Root or sudo access
- SSH access to the server
- Internet connection

## Setup Process Overview

1. **Clone Repository** - Get the code onto your server
2. **Run Bootstrap** - Install Ansible and configure SSH
3. **Configure Variables** - Set your preferences
4. **Deploy Infrastructure** - Install Kubernetes components
5. **Deploy Applications** - Install all Helm applications

---

## Step-by-Step Guide

### 1. Access Your Server

Connect to your Ubuntu 24.04 server:

```bash
ssh user@your-server-ip
```

### 2. Clone This Repository

Install Git and clone the repository:

```bash
# Update package cache
sudo apt-get update

# Install Git
sudo apt-get install -y git

# Clone the repository
git clone https://github.com/YOUR_USERNAME/kimsufi.git

# Change to the repository directory
cd kimsufi
```

**Note**: Replace `YOUR_USERNAME/kimsufi` with your actual repository location.

### 3. Run the Bootstrap Script

The bootstrap script will:
- Install Git (if not already present)
- Install snapd and msedit
- Install Ansible
- Configure SSH security hardening

```bash
sudo bash bootstrap.sh
```

**What happens:**
- Git is installed
- Snapd is installed
- msedit (text editor) is installed via Snap
- Ansible PPA is added
- Ansible is installed
- SSH is hardened (password auth still enabled by default)
- SSH config is backed up

This takes approximately 2-5 minutes.

### 4. Review and Configure Variables

Edit the global variables file:

```bash
nano group_vars/all.yml
```

**Key settings to review:**

```yaml
# Minikube resources (adjust based on your server)
minikube_cpus: 2
minikube_memory: "4096"
minikube_disk_size: "20g"

# Tailscale (optional but recommended)
tailscale_auth_key: ""  # Get from https://login.tailscale.com/admin/settings/keys

# Tailscale Operator (REQUIRED for Tailscale ingress)
# Create OAuth client at: https://login.tailscale.com/admin/settings/oauth
tailscale_oauth_client_id: ""
tailscale_oauth_client_secret: ""

# Application passwords (CHANGE THESE!)
gitea_admin_password: "changeme"
pihole_admin_password: "changeme"
```

**Important: Tailscale Operator Setup**

To enable secure Tailscale access to all applications:

1. Go to [Tailscale OAuth Clients](https://login.tailscale.com/admin/settings/oauth)
2. Click **Generate OAuth Client**
3. Name it "Kubernetes Operator"
4. Copy the **Client ID** and **Client Secret**
5. Paste them into `group_vars/all.yml`

See [Tailscale Operator Setup](docs/tailscale-operator.md) for detailed instructions.

### 5. Configure Inventory

For local installation (running on the server itself):

```bash
# inventory/hosts.yml is already configured for localhost
# No changes needed
```

For remote installation (managing from another machine):

```bash
nano inventory/hosts.yml
```

Change to:
```yaml
all:
  hosts:
    kimsufi:
      ansible_host: your.server.ip
      ansible_user: your_user
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

### 6. Deploy Everything

Run the main playbook:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

This will:
- Install Docker, kubectl, Helm, Minikube
- Set up Tailscale VPN
- Configure scheduled system updates
- Deploy all Helm applications

**Expected time:** 30-50 minutes

**What's being installed:**
- Infrastructure components (Docker, Minikube, kubectl, Helm, Tailscale)
- Tailscale Operator (for secure ingress)
- Storage provisioner (local-path)
- Gitea (Git server)
- Sonarr (TV shows)
- Headscale (Tailscale controller)
- Immich (Photos)
- qBittorrent (Downloads)
- Pi-hole (DNS/Ad blocking)

### 7. Verify Installation

Check that everything is running:

```bash
# Check Minikube
minikube status

# Check Kubernetes
kubectl get nodes
kubectl get pods --all-namespaces

# Check Helm
helm list --all-namespaces

# Check Tailscale
tailscale status
```

Or use the convenience command:

```bash
make status
```

---

## Accessing Your Applications

### Primary Access Method: Tailscale

Once the Tailscale operator is configured and deployed, all applications are accessible via Tailscale hostnames:

| Application | Tailscale URL | Description |
|-------------|---------------|-------------|
| Gitea | `http://gitea` | Git web interface |
| Gitea SSH | `ssh://gitea-ssh` | Git SSH access |
| Sonarr | `http://sonarr:8989` | TV show manager |
| Headscale | `http://headscale:8080` | Tailscale control server |
| Immich | `http://immich:3001` | Photo/video backup |
| qBittorrent | `http://qbittorrent:8080` | BitTorrent client |
| Pi-hole | `http://pihole` | Ad blocker web UI |

**Note:** You must be connected to your Tailnet (via Tailscale client on your device) to access these URLs.

See [Tailscale Operator Setup](docs/tailscale-operator.md) for detailed configuration.

### Fallback Access Method: NodePort/Minikube Service

If you haven't configured Tailscale operator yet, or need direct access:

```bash
# List all services with access URLs
minikube service list

# Or use the convenience command
make services
```

### Access Individual Services (Fallback)

```bash
# Open Gitea in browser
minikube service gitea-http -n gitea

# Open Immich
minikube service immich-server -n immich

# Open Pi-hole
minikube service pihole-web -n pihole
```

### Default Credentials

**Gitea:**
- Username: `gitea_admin` (or as configured)
- Password: `changeme` (CHANGE THIS!)

**qBittorrent:**
- Username: `admin`
- Password: `adminadmin` (CHANGE THIS!)

**Pi-hole:**
- Password: `changeme` (CHANGE THIS!)

**Immich:**
- Create account on first access

---

## Next Steps

### 1. Secure Your Installation

**Change all default passwords:**
```yaml
# Edit group_vars/all.yml
gitea_admin_password: "strong-password-here"
pihole_admin_password: "strong-password-here"

# Re-run applications playbook
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml
```

**Harden SSH (optional but recommended):**

After setting up SSH keys:
```bash
sudo nano /etc/ssh/sshd_config

# Uncomment these lines:
# PermitRootLogin no
# PasswordAuthentication no

sudo systemctl restart sshd
```

See [SSH Security Guide](docs/ssh-security.md) for details.

### 2. Set Up Tailscale

If you want secure remote access:

1. Get auth key from https://login.tailscale.com/admin/settings/keys
2. Add to `group_vars/all.yml`:
   ```yaml
   tailscale_auth_key: "tskey-auth-xxxxx"
   ```
3. Re-run infrastructure:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml --tags tailscale
   ```

### 3. Configure Pi-hole as DNS

To use Pi-hole for ad-blocking:

**Option 1: Router-level (recommended)**
1. Access your router admin panel
2. Set DHCP DNS server to your server's IP
3. All devices will use Pi-hole

**Option 2: Per-device**
1. Get Pi-hole service URL: `minikube service pihole-dns -n pihole --url`
2. Set device DNS to this IP

See [Applications Guide](docs/applications.md#pi-hole) for details.

### 4. Set Up Backups

Important data to backup:
- Gitea repositories
- Immich photos/database
- Pi-hole configuration

See [Applications Guide](docs/applications.md) for backup procedures.

---

## Common Tasks

### View Logs

```bash
# Use make shortcuts
make logs-gitea
make logs-immich
make logs-pihole

# Or directly
kubectl logs -n gitea -l app.kubernetes.io/name=gitea --tail=100
```

### Restart an Application

```bash
# Delete the pod (it will be recreated)
kubectl delete pod -n <namespace> <pod-name>

# Or restart the deployment
kubectl rollout restart deployment -n <namespace> <deployment-name>
```

### Update an Application

```bash
# Update Helm repos
helm repo update

# Upgrade specific app
helm upgrade -n gitea gitea gitea/gitea

# Or upgrade all
helm list --all-namespaces | awk 'NR>1 {print $1, $2}' | while read name ns; do
  helm upgrade -n $ns $name $(helm get values -n $ns $name -o yaml)
done
```

### Stop/Start Everything

```bash
# Stop Minikube
minikube stop

# Start Minikube
minikube start

# Check status
minikube status
```

### Remote kubectl Access via SSH Tunnel

You can manage your Kubernetes cluster from your local machine by setting up an SSH tunnel:

**1. On your server, get the Minikube IP and port:**

```bash
minikube kubectl -- config view --minify --output jsonpath='{.clusters[0].cluster.server}'
```

This will show something like `https://192.168.49.2:8443`

**2. On your local machine, create an SSH tunnel:**

```bash
# Forward the Kubernetes API port through SSH
ssh -L 8443:$(minikube ip):8443 user@your-server-ip -N

# Or run in background
ssh -fNL 8443:$(minikube ip):8443 user@your-server-ip
```

**3. Copy the kubeconfig from the server:**

```bash
# On the server
cat ~/.kube/config
```

Copy this content to your local `~/.kube/config` (or a separate file).

**4. Update the local kubeconfig to use the tunnel:**

Edit your local `~/.kube/config` and change the server URL:

```yaml
server: https://localhost:8443
```

Also, add this to skip certificate verification (development only):

```yaml
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://localhost:8443
  name: minikube
```

**5. Test the connection:**

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

**Alternative: Use a dedicated kubeconfig file:**

```bash
# Set KUBECONFIG environment variable
export KUBECONFIG=~/.kube/homelab-config

# Or specify it with each command
kubectl --kubeconfig ~/.kube/homelab-config get nodes
```

**Tip:** You can also use `sshuttle` for a more seamless VPN-like experience:

```bash
# Install sshuttle (macOS)
brew install sshuttle

# Create tunnel to server's network
sshuttle -r user@your-server-ip $(minikube ip)/24
```

---

## Troubleshooting

### Issue: Can't access services

**Solution:**
```bash
# Get service URLs
minikube service list

# Or use port forwarding
kubectl port-forward -n <namespace> svc/<service-name> 8080:80
```

### Issue: Pods not starting

**Solution:**
```bash
# Check pod status
kubectl get pods --all-namespaces

# Describe the pod
kubectl describe pod -n <namespace> <pod-name>

# Check logs
kubectl logs -n <namespace> <pod-name>
```

### Issue: Out of disk space

**Solution:**
```bash
# Check disk usage
df -h

# Clean up Docker
minikube ssh
docker system prune -a

# Check Minikube disk
minikube ssh
df -h /opt/local-path-provisioner/
```

For more issues, see [Troubleshooting Guide](docs/troubleshooting.md).

---

## Documentation

- **[README.md](README.md)** - Project overview
- **[QUICKSTART.md](QUICKSTART.md)** - Quick reference guide
- **[docs/bootstrap.md](docs/bootstrap.md)** - Detailed bootstrap guide
- **[docs/ssh-security.md](docs/ssh-security.md)** - SSH security hardening
- **[docs/infrastructure.md](docs/infrastructure.md)** - Infrastructure components
- **[docs/applications.md](docs/applications.md)** - Application guides
- **[docs/troubleshooting.md](docs/troubleshooting.md)** - Problem solving

---

## Support

If you encounter issues:

1. Check the [Troubleshooting Guide](docs/troubleshooting.md)
2. Review application logs: `kubectl logs -n <namespace> <pod-name>`
3. Check GitHub issues
4. Consult official documentation for each component

---

## Summary

You now have a complete self-hosted infrastructure running:

✅ Kubernetes cluster (Minikube)  
✅ Git server (Gitea)  
✅ Photo backup (Immich)  
✅ Media management (Sonarr, qBittorrent)  
✅ Ad blocking (Pi-hole)  
✅ VPN (Tailscale/Headscale)  
✅ Automated updates  

Enjoy your infrastructure! 🚀
