# Quick Start Summary

This is a quick reference guide to get you started with your Kimsufi infrastructure.

> 📖 **New to this?** See [GETTING_STARTED.md](GETTING_STARTED.md) for a detailed step-by-step guide.

## One-Command Setup

For a fresh Ubuntu 24.04 server, run these commands in order:

```bash
# 1. Clone the repository
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/YOUR_USERNAME/kimsufi.git
cd kimsufi

# 2. Install Git, snapd, msedit, and Ansible (also configures SSH security)
sudo bash bootstrap.sh

# 3. Configure Tailscale OAuth (REQUIRED for Tailscale ingress)
# Get OAuth credentials from: https://login.tailscale.com/admin/settings/oauth
nano group_vars/all.yml
# Set: tailscale_oauth_client_id: "your-client-id"
# Set: tailscale_oauth_client_secret: "your-client-secret"
# Set: tailscale_auth_key: "your-key-here" (optional)

# 4. Install everything
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

Wait 30-50 minutes for everything to install.

## SSH Security (Applied by Bootstrap)

The bootstrap script automatically hardens SSH:
- ✅ Public key authentication enabled
- ✅ Empty passwords disabled  
- ✅ Max login attempts limited to 3
- 📁 Original SSH config backed up

**Optional (for maximum security):**
After setting up SSH keys, disable password authentication:
```bash
sudo nano /etc/ssh/sshd_config
# Uncomment: PasswordAuthentication no
# Uncomment: PermitRootLogin no
sudo systemctl restart sshd
```

⚠️ **Only do this after confirming SSH key login works!**

## What Gets Installed

### Infrastructure (10-15 min)
✅ Docker  
✅ kubectl  
✅ Helm  
✅ Minikube (Kubernetes cluster)  
✅ Tailscale (VPN)  
✅ Tailscale Operator (Kubernetes ingress)  
✅ Scheduled system updates  

### Applications (15-30 min)
✅ CSI Storage Driver (local-path-provisioner)  
✅ Gitea (Git server) - `http://gitea`  
✅ Sonarr (TV shows) - `http://sonarr:8989`  
✅ Headscale (Tailscale controller) - `http://headscale:8080`  
✅ Immich (Photos) - `http://immich:3001`  
✅ qBittorrent (Downloads) - `http://qbittorrent:8080`  
✅ Pi-hole (DNS/Ad blocker) - `http://pihole`  

**Note:** URLs shown are Tailscale hostnames (require Tailscale connection)  
### Primary: Tailscale (Recommended)

Connect to your Tailnet on your device, then access applications via:
- Gitea: `http://gitea`
- Sonarr: `http://sonarr:8989`
- Immich: `http://immich:3001`
- qBittorrent: `http://qbittorrent:8080`
- Headscale: `http://headscale:8080`
- Pi-hole: `http://pihole`

See [Tailscale Operator Setup](docs/tailscale-operator.md) for configuration.

### Fallback: NodePort (Direct Access)

```bash
# Get Minikube IP
minikube ip

# List all services with their ports
minikube service list

# Access a service (opens in browser)
minikube service <service-name> -n <namespace>
```

### Example NodePortrvice <service-name> -n <namespace>
```

### Example Access URLs

After installation, access services at:
- Gitea: `http://<minikube-ip>:<nodeport>`
- Sonarr: `http://<minikube-ip>:<nodeport>`
- Immich: `http://<minikube-ip>:<nodeport>`
- qBittorrent: `http://<minikube-ip>:<nodeport>`
- Headscale: `http://<minikube-ip>:<nodeport>`

Use `minikube service list` to see exact ports.

## Default Credentials

**Gitea:**
- Username: `gitea_admin` (configurable)
- Password: `changeme` (CHANGE THIS!)

**qBittorrent:**
- Username: `admin`
- Password: `adminadmin` (CHANGE THIS!)

**Pi-hole:**
- Password: `changeme` (CHANGE THIS!)

**Immich:**
- Create account on first access

## Essential Commands

```bash
# Check status of everything
make status

# View service URLs
make services

# Check for issues
make check

# View logs for a service
make logs-gitea
make logs-immich
make logs-sonarr

# Restart Minikube
minikube stop
minikube start

# Restart an application
kubectl rollout restart deployment -n <namespace> <deployment-name>
```

## Useful Kubectl Commands

```bash
# See all pods
kubectl get pods --all-namespaces

# See specific namespace
kubectl get pods -n gitea
kubectl get pods -n media
kubectl get pods -n immich

# View logs
kubectl logs -n <namespace> <pod-name> -f

# Describe a pod (for troubleshooting)
kubectl describe pod -n <namespace> <pod-name>

# Get into a pod's shell
kubectl exec -it -n <namespace> <pod-name> -- /bin/sh

# Check storage
kubectl get pvc --all-namespaces
```

## If Something Goes Wrong

1. **Check pod status:**
   ```bash
   kubectl get pods --all-namespaces
   ```

2. **Check logs:**
   ```bash
   kubectl logs -n <namespace> <pod-name>
   ```

3. **Restart a pod:**
   ```bash
   kubectl delete pod -n <namespace> <pod-name>
   # It will be recreated automatically
   ```

4. **Nuclear option (restart everything):**
   ```bash
   minikube stop
   minikube start
   ```

5. **See full troubleshooting guide:**
   - [docs/troubleshooting.md](docs/troubleshooting.md)

## Storage Locations

All persistent data is stored in Minikube at:
- `/opt/local-path-provisioner/` on the Minikube VM

To access:
```bash
minikube ssh
cd /opt/local-path-provisioner/
ls -la
```

## Backup Important Data

```bash
# Backup Gitea
kubectl exec -n gitea <pod-name> -- tar czf /tmp/backup.tar.gz /data
kubectl cp gitea/<pod-name>:/tmp/backup.tar.gz ./gitea-backup.tar.gz

# Backup Immich database
kubectl exec -n immich <postgres-pod> -- pg_dump -U postgres immich > immich-backup.sql
```

## Updating Applications

```bash
# Update Helm repositories
helm repo update

# Upgrade a specific application
helm upgrade -n <namespace> <release-name> <repo>/<chart>

# Example: Upgrade Gitea
helm upgrade -n gitea gitea gitea/gitea
```

## Security Best Practices

1. ✅ Set up SSH key authentication (if not already done)
2. ✅ Consider disabling SSH password authentication (see SSH Security section)
3. ✅ Change all default passwords immediately
4. ✅ Set up Tailscale for secure remote access
5. ✅ Keep the system updated (already automated)
6. ✅ Regular backups of important data
7. ✅ Monitor logs for suspicious activity
8. ❌ Don't expose services directly to the internet without proxy/SSL
9. ❌ Don't use default credentials in production

## Performance Tuning

If things are slow, increase Minikube resources in `group_vars/all.yml`:

```yaml
minikube_cpus: 4
minikube_memory: "8192"  # 8GB
minikube_disk_size: "50g"
```

Then recreate Minikube:
```bash
minikube delete
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml --tags minikube
```

## Next Steps

1. 📖 Read [docs/bootstrap.md](docs/bootstrap.md) for detailed setup
2. 📖 Read [docs/ssh-security.md](docs/ssh-security.md) for SSH hardening
3. 📖 Read [docs/applications.md](docs/applications.md) to configure apps
4. 🔐 Change all default passwords
5. 🔒 Set up Tailscale for secure access
6. 💾 Implement backup strategy
7. 📊 Consider adding monitoring (Prometheus/Grafana)

## Getting Help

- Check [docs/troubleshooting.md](docs/troubleshooting.md)
- Run `make check` to diagnose issues
- Check logs with `kubectl logs`
- Review the official docs for each tool

## Common Issues

**Minikube won't start:**
```bash
minikube delete
minikube start --driver=docker
```

**Pod stuck in Pending:**
```bash
kubectl describe pod -n <namespace> <pod-name>
# Usually storage or resource issues
```

**Can't access services:**
```bash
minikube service list
# Use the URLs shown
```

**Out of disk space:**
```bash
minikube ssh
docker system prune -a
```

---

**Enjoy your self-hosted infrastructure! 🚀**
