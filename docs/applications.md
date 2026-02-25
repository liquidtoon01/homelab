# Applications

This document describes all Helm-based applications deployed on your infrastructure.

## Applications Overview

All applications are accessible via Tailscale hostnames. See [Tailscale Operator Setup](tailscale-operator.md) for configuration details.

| Application | Purpose | Default Namespace | Tailscale Hostname | Fallback Port |
|-------------|---------|-------------------|-------------------|---------------|
| Gogs | Self-hosted Git service | git | `http://gogs` | 3000 |
| Sonarr | TV show PVR | media | `http://sonarr:8989` | 8989 |
| qBittorrent | BitTorrent client | media | `http://qbittorrent:8080` | 8080 |
| Pi-hole | Network-wide ad blocker & DNS | pihole | `http://pihole` | 80 |

**Note:** The Tailscale hostnames work automatically when connected to your Tailnet. Fallback ports are available via `minikube service` commands.

---

## Gogs

**Purpose**: Self-hosted Git service with web interface.

**Deployment**: Kubernetes StatefulSets with PostgreSQL database

**Namespace**: `git`

### Access

**Primary (Tailscale):**
```bash
# Web interface
http://gogs:3000

# SSH access
ssh://gogs-ssh:22
```

**Fallback (NodePort):**
```bash
# Get access URLs
kubectl get svc -n git

# Or use port forwarding
kubectl port-forward -n git svc/gogs-http 3000:3000
```

### Default Credentials

Gogs requires initial setup on first run. Navigate to the web interface and complete the installation wizard.

**⚠️ IMPORTANT**: Choose a strong admin password during setup!

### Configuration

Gogs is deployed with:
- PostgreSQL database (separate StatefulSet)
- Persistent storage (10Gi for Gogs data, 5Gi for PostgreSQL)
- HTTP and SSH services exposed via Tailscale LoadBalancer

### Database Setup

During first-run installation wizard, use these database settings:

- **Database Type**: PostgreSQL
- **Host**: `postgres.git.svc.cluster.local:5432`
- **User**: `gogs`
- **Password**: `gogspassword`
- **Database Name**: `gogs`

**⚠️ SECURITY NOTE**: Change the database password in the ConfigMap before deploying to production:
```bash
kubectl edit configmap postgres-config -n git
# Change db_pass value, then restart both PostgreSQL and Gogs pods
```

### Management

```bash
# View Gogs pods
kubectl get pods -n git

# View logs
kubectl logs -n git -l app=gogs

# Access Gogs config
kubectl exec -it -n git <pod-name> -- /bin/sh
```

### Persistent Data

Location: `/data` inside the pod, backed by PVC

### Backup

```bash
# Backup Gogs data
kubectl exec -n git <pod-name> -- tar czf /tmp/gogs-backup.tar.gz /data
kubectl cp git/<pod-name>:/tmp/gogs-backup.tar.gz ./gogs-backup.tar.gz
```

---

## Sonarr

**Purpose**: PVR for managing and downloading TV shows.

**Helm Chart**: https://artifacthub.io/packages/helm/pree-helm-charts/sonarr

**Namespace**: `media`

### Access

**Primary (Tailscale):**
```bash
# Web interface
http://sonarr:8989
```

**Fallback (NodePort):**
```bash
# Get access URL
minikube service sonarr -n media
```

### Configuration

Sonarr is configured with:
- Config storage: 1Gi PVC
- Media storage: 50Gi PVC
- NodePort service (port 8989)

### First-Time Setup

1. Access the web interface
2. Configure download client (qBittorrent)
3. Add indexers
4. Set up quality profiles
5. Add TV shows

### Integration with qBittorrent

In Sonarr settings:
- Host: `qbittorrent.media.svc.cluster.local`
- Port: `8080`

### Persistent Data

- Config: `/config` (1Gi)
- Media: `/media` (50Gi)

---

## qBittorrent

**Purpose**: BitTorrent client for downloading media.

**Helm Chart**: https://artifacthub.io/packages/helm/gabe565/qbittorrent

**Namespace**: `media`

### Access

**Primary (Tailscale):**
```bash
# Web interface
http://qbittorrent:8080
```

**Fallback (NodePort):**
```bash
# Get access URL
minikube service qbittorrent -n media
```

### Default Credentials

- Username: `admin`
- Password: `adminadmin`

**⚠️ IMPORTANT**: Change the password after first login (Tools → Options → Web UI)

### Configuration

qBittorrent is configured with:
- Config storage: 1Gi PVC
- Downloads storage: 100Gi PVC
- Running as user 1000:1000

### Integration with Sonarr

qBittorrent can be used as the download client for Sonarr.

In qBittorrent:
1. Enable Web UI (already enabled)
2. Note the connection details

In Sonarr:
1. Settings → Download Clients → Add → qBittorrent
2. Host: qbittorrent service name
3. Port: 8080
4. Username/Password: qBittorrent credentials

### Persistent Data

- Config: `/config` (1Gi)
- Downloads: `/downloads` (100Gi)

### Performance Tuning

For better performance, consider adjusting:
- Connection limits
- Upload/download limits
- Disk cache settings

---

## Pi-hole

**Purpose**: Network-wide ad blocker and DNS server.

**Helm Chart**: https://artifacthub.io/packages/helm/mojo2600/pihole

**Namespace**: `pihole`

### Access

**Primary (Tailscale):**
```bash
# Web interface
http://pihole

# DNS service (for configuration)
http://pihole-dns
```

**Fallback (NodePort):**
```bash
# Get access URL
minikube service pihole-web -n pihole
```

### Default Credentials

- Password: `changeme` (configurable in `group_vars/all.yml`)

**⚠️ IMPORTANT**: Change the password after first login!

### Configuration

Pi-hole is configured with:
- Web interface on port 80
- DNS service (NodePort)
- Persistent storage (1Gi PVC)
- Upstream DNS: Quad DNS (9.9.9.9, 149.112.112.112)
- Resource limits: 500m CPU, 512Mi RAM

### First-Time Setup

1. Access the web interface
2. Log in with the admin password
3. Navigate to Settings

**Recommended Settings:**
- **DNS**: Configure conditional forwarding if needed
- **DHCP**: Disable unless you want Pi-hole to handle DHCP
- **Blocklists**: The default blocklists are pre-configured
- **Whitelist/Blacklist**: Add domains as needed

### Using Pi-hole as DNS Server

#### Option 1: Configure Specific Devices

On client devices, set DNS to the Pi-hole service:
1. Get the Pi-hole service IP: `minikube service pihole-dns -n pihole --url`
2. Configure device DNS to point to this IP

#### Option 2: Router-Level (Recommended)

Configure your router's DHCP to use Pi-hole as the DNS server:
1. Access your router's admin panel
2. Find DHCP/DNS settings
3. Set primary DNS to Pi-hole IP
4. Save and restart router

#### Option 3: Via Tailscale

Access Pi-hole over Tailscale network:
1. Get Minikube Tailscale IP: `tailscale ip`
2. Configure devices on Tailscale to use this IP as DNS

### Accessing the Admin Interface

The web admin interface provides:
- **Dashboard**: Real-time statistics on queries and blocked ads
- **Query Log**: Detailed log of all DNS queries
- **Blocklist Management**: Add/remove blocklists
- **Whitelist/Blacklist**: Fine-tune blocking
- **Settings**: Configure DNS, DHCP, and other options

### Adding Custom Blocklists

1. Navigate to **Group Management** → **Adlists**
2. Add blocklist URLs (popular lists):
   - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
   - https://v.firebog.net/hosts/lists.php (collection of lists)
3. Click **Save and Update**
4. Go to **Tools** → **Update Gravity** to apply changes

### Whitelisting Domains

If a legitimate site is blocked:

1. Navigate to **Whitelist**
2. Add the domain (e.g., `example.com`)
3. Click **Add**
4. Optionally add comment for reference

### Query Log and Statistics

**Dashboard Features:**
- Total queries (24 hours)
- Queries blocked
- Percentage blocked
- Top blocked domains
- Top permitted domains
- Query types over time

**Query Log:**
- Real-time DNS queries
- Filter by domain, client, or status
- Blacklist directly from log

### DNS Over HTTPS (DoH)

Pi-hole supports DoH for added privacy:

Edit values before deployment or upgrade with:
```yaml
doh:
  enabled: true
  upstream: "https://dns.cloudflare.com/dns-query"
```

### Persistent Data

Location: `/etc/pihole` and `/etc/dnsmasq.d` inside the pod

### Backup and Restore

**Backup Settings:**
1. In web interface: **Settings** → **Teleporter**
2. Click **Backup** to download configuration

**Restore Settings:**
1. In web interface: **Settings** → **Teleporter**
2. Upload backup file
3. Click **Restore**

**Backup via kubectl:**
```bash
kubectl exec -n pihole <pod-name> -- tar czf /tmp/pihole-backup.tar.gz /etc/pihole /etc/dnsmasq.d
kubectl cp pihole/<pod-name>:/tmp/pihole-backup.tar.gz ./pihole-backup.tar.gz
```

### Troubleshooting

**DNS not resolving:**
1. Check pod status: `kubectl get pods -n pihole`
2. Check logs: `kubectl logs -n pihole <pod-name>`
3. Verify service: `kubectl get svc -n pihole`

**Web interface not accessible:**
1. Get service URL: `minikube service pihole-web -n pihole`
2. Check pod logs for errors
3. Verify port forwarding: `kubectl port-forward -n pihole svc/pihole-web 8080:80`

**High memory usage:**
Pi-hole is lightweight, but if issues occur:
1. Check query log size
2. Disable excessive logging in settings
3. Reduce number of blocklists if needed

### Advanced Configuration

**Custom DNS Records:**
Add custom local DNS entries in **Local DNS** → **DNS Records**

**CNAME Records:**
Create aliases in **Local DNS** → **CNAME Records**

**Conditional Forwarding:**
Forward specific domains to specific DNS servers

**DHCP Server:**
Pi-hole can act as DHCP server (disable router DHCP first):
- Settings → DHCP → Enable DHCP

---

## Common Operations

### Viewing All Application Status

```bash
# Get all pods
kubectl get pods --all-namespaces

# Get all services
kubectl get svc --all-namespaces

# Get all PVCs
kubectl get pvc --all-namespaces
```

### Accessing Logs

```bash
# General format
kubectl logs -n <namespace> <pod-name>

# Follow logs
kubectl logs -n <namespace> <pod-name> -f

# Previous pod logs (after crash)
kubectl logs -n <namespace> <pod-name> --previous
```

### Restarting Applications

```bash
# Delete pod (will be recreated automatically)
kubectl delete pod -n <namespace> <pod-name>

# Or restart the deployment
kubectl rollout restart deployment -n <namespace> <deployment-name>
```

### Scaling Applications

```bash
# Scale up/down
kubectl scale deployment -n <namespace> <deployment-name> --replicas=<number>
```

### Uninstalling Applications

```bash
# Uninstall via Helm
helm uninstall -n <namespace> <release-name>

# Delete namespace (removes all resources)
kubectl delete namespace <namespace>
```

---

## Storage Management

All applications use persistent storage. Monitor disk usage:

```bash
# Check PVC usage
kubectl get pvc --all-namespaces

# Check node disk usage
minikube ssh
df -h /opt/local-path-provisioner/
```

### Expanding Storage

To expand a PVC:

```bash
# Edit the PVC
kubectl edit pvc -n <namespace> <pvc-name>

# Change the storage size (some storage classes support this)
# Otherwise, you'll need to backup data, delete PVC, and recreate
```

---

## Networking

All services are exposed via NodePort. For external access:

### Option 1: Tailscale (Recommended)

Access services securely over Tailscale:
1. Connect your client device to the same Tailscale network
2. Access via Minikube IP: `http://<minikube-tailscale-ip>:<nodeport>`

### Option 2: Reverse Proxy

Set up Nginx as a reverse proxy with SSL:
- Install Nginx on the host
- Configure virtual hosts for each service
- Use Let's Encrypt for SSL certificates

### Option 3: Port Forwarding

For testing only:
```bash
kubectl port-forward -n <namespace> svc/<service-name> <local-port>:<service-port>
```

---

## Security Considerations

1. **Change default passwords** for all applications
2. **Use Tailscale** or another VPN for remote access
3. **Enable authentication** on all services
4. **Regular backups** of persistent data
5. **Monitor logs** for suspicious activity
6. **Keep applications updated** via Helm upgrades
7. **Limit resource usage** with Kubernetes resource limits

---

## Updating Applications

```bash
# Update Helm repositories
helm repo update

# Check for updates
helm search repo <chart-name> --versions

# Upgrade an application
helm upgrade -n <namespace> <release-name> <repo>/<chart>

# Upgrade with custom values
helm upgrade -n <namespace> <release-name> <repo>/<chart> -f custom-values.yaml
```
