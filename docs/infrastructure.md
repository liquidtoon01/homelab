# Infrastructure Components

This document describes all infrastructure components installed by the playbooks.

## Components Overview

| Component | Purpose | Version |
|-----------|---------|---------|
| Docker | Container runtime | Latest from Ubuntu repos |
| kubectl | Kubernetes CLI | Latest stable |
| Helm | Kubernetes package manager | Latest |
| Minikube | Local Kubernetes cluster | Latest |
| Tailscale | VPN mesh network | Latest stable |
| Tailscale Operator | Kubernetes ingress for Tailscale | Latest |
| Unattended Upgrades | Automated system updates | Ubuntu package |

---

## Docker

**Purpose**: Container runtime for Minikube and potentially other services.

**Installation Details**:
- Installed from Ubuntu repositories
- Service enabled and started automatically
- Current user added to `docker` group

**Verification**:
```bash
docker --version
docker ps
```

**Configuration Location**: `/etc/docker/daemon.json`

---

## kubectl

**Purpose**: Command-line tool for interacting with Kubernetes clusters.

**Installation Details**:
- Downloaded from official Kubernetes releases
- Installed to `/usr/local/bin/kubectl`
- Always installs the latest stable version

**Verification**:
```bash
kubectl version --client
kubectl get nodes
```

**Configuration**: Automatically configured by Minikube at `~/.kube/config`

**Common Commands**:
```bash
# List all pods across all namespaces
kubectl get pods --all-namespaces

# Get nodes
kubectl get nodes

# Describe a pod
kubectl describe pod <pod-name> -n <namespace>

# View logs
kubectl logs <pod-name> -n <namespace>
```

---

## Helm

**Purpose**: Package manager for Kubernetes applications.

**Installation Details**:
- Downloaded from official Helm releases
- Installed to `/usr/local/bin/helm`
- Pre-configured repositories: stable, bitnami

**Verification**:
```bash
helm version
helm repo list
```

**Common Commands**:
```bash
# List installed releases
helm list --all-namespaces

# Get values for a release
helm get values <release-name> -n <namespace>

# Upgrade a release
helm upgrade <release-name> <chart> -n <namespace>

# Uninstall a release
helm uninstall <release-name> -n <namespace>
```

---

## Minikube

**Purpose**: Single-node Kubernetes cluster for development and testing.

**Installation Details**:
- Driver: Docker
- Default resources:
  - CPUs: 2
  - Memory: 4096 MB
  - Disk: 20 GB
- Enabled addons:
  - storage-provisioner
  - default-storageclass
  - metrics-server

**Verification**:
```bash
minikube status
minikube profile list
```

**Configuration**: Customizable in `group_vars/all.yml`:
```yaml
minikube_cpus: 2
minikube_memory: "4096"
minikube_disk_size: "20g"
minikube_driver: "docker"
```

**Management Commands**:
```bash
# Start Minikube
minikube start

# Stop Minikube
minikube stop

# Delete and recreate
minikube delete
minikube start

# Access Kubernetes dashboard
minikube dashboard

# SSH into the Minikube VM
minikube ssh

# Get service URLs
minikube service list
```

---

## Tailscale

**Purpose**: Private VPN mesh network for secure remote access.

**Installation Details**:
- Installed from official Tailscale repository
- Service enabled and started
- Requires authentication key for auto-connection

**Configuration**:
Set your Tailscale auth key in `group_vars/all.yml`:
```yaml
tailscale_auth_key: "tskey-auth-xxxxx"
```

Get an auth key from: https://login.tailscale.com/admin/settings/keys

**Verification**:
```bash
tailscale status
tailscale ip
```

**Manual Connection** (if auth key not set):
```bash
sudo tailscale up
# Follow the URL to authenticate
```

**Common Commands**:
```bash
# Show connection status
tailscale status

# Show your Tailscale IP
tailscale ip

# Disconnect
tailscale down

# Reconnect
tailscale up
```

---

## Tailscale Operator

**Purpose**: Kubernetes operator that provides Tailscale ingress for services.

**Installation Details**:
- Deployed via Helm chart from official Tailscale repository
- Namespace: `tailscale`
- Requires Tailscale OAuth credentials
- Automatically exposes services with appropriate annotations

**Configuration**:
Set OAuth credentials in `group_vars/all.yml`:
```yaml
tailscale_oauth_client_id: "your-client-id"
tailscale_oauth_client_secret: "your-client-secret"
```

Create OAuth client at: https://login.tailscale.com/admin/settings/oauth

**How It Works**:
- Watches for services with Tailscale annotations
- Creates a Tailscale device for each annotated LoadBalancer service
- Assigns MagicDNS hostnames (e.g., `http://gogs`, `http://sonarr`)
- Routes traffic from your Tailnet to the Kubernetes service

**Service Annotations**:
Services are exposed using these annotations:
```yaml
annotations:
  tailscale.com/expose: "true"
  tailscale.com/hostname: "app-name"
```

**Verification**:
```bash
# Check operator pods
kubectl get pods -n tailscale

# Check operator logs
kubectl logs -n tailscale -l app=tailscale-operator

# List Tailscale devices
# Go to: https://login.tailscale.com/admin/machines
```

**Common Commands**:
```bash
# View operator status
kubectl get pods -n tailscale

# View operator logs
kubectl logs -n tailscale deploy/tailscale-operator

# List services with Tailscale annotations
kubectl get svc -A -o json | jq '.items[] | select(.metadata.annotations["tailscale.com/expose"]=="true") | {name: .metadata.name, namespace: .metadata.namespace, hostname: .metadata.annotations["tailscale.com/hostname"]}'

# Restart operator
kubectl rollout restart deploy/tailscale-operator -n tailscale
```

**Accessing Applications via Tailscale**:
Once configured, access all applications via Tailscale hostnames:
- `http://gogs`
- `http://sonarr:8989`
- `http://qbittorrent:8080`
- `http://pihole`

See [Tailscale Operator Setup](tailscale-operator.md) for detailed configuration and troubleshooting.

---

## Scheduled APT Updates

**Purpose**: Automated system updates and security patches.

**Installation Details**:
- Uses `unattended-upgrades` package
- Configured to auto-install security updates
- Weekly full update via cron (Sundays at 3 AM)
- Automatic cleanup of old packages

**Configuration**:
Schedule can be adjusted in `group_vars/all.yml`:
```yaml
apt_updates_schedule: "0 3 * * 0"  # Weekly on Sunday at 3 AM
apt_updates_email: "admin@example.com"  # Optional email notifications
```

**Configuration Files**:
- `/etc/apt/apt.conf.d/50unattended-upgrades`
- `/etc/apt/apt.conf.d/20auto-upgrades`
- `/usr/local/bin/apt-update.sh`

**Logs**:
```bash
# View update logs
tail -f /var/log/apt-update.log

# View unattended-upgrades logs
tail -f /var/log/unattended-upgrades/unattended-upgrades.log
```

**Manual Update**:
```bash
sudo /usr/local/bin/apt-update.sh
```

---

## Storage (CSI Driver)

**Purpose**: Persistent storage for Kubernetes workloads.

**Implementation**: Rancher Local Path Provisioner

**Details**:
- Automatically installed as part of the helm_apps role
- Provides dynamic provisioning of persistent volumes
- Uses local host storage
- Set as the default storage class

**Verification**:
```bash
# Check storage class
kubectl get storageclass

# List persistent volumes
kubectl get pv

# List persistent volume claims
kubectl get pvc --all-namespaces
```

**Storage Location**: `/opt/local-path-provisioner/` on the host

---

## Network Access

All services are exposed via NodePort. To access them:

```bash
# Get service URLs
minikube service list

# Access a specific service
minikube service <service-name> -n <namespace>
```

Or access directly using the Minikube IP and NodePort:

```bash
# Get Minikube IP
minikube ip

# Access service at http://<minikube-ip>:<nodeport>
```

For external access, consider setting up:
- Nginx reverse proxy
- Tailscale for secure remote access
- Cloudflare Tunnel
- Port forwarding on your router (not recommended for security)
