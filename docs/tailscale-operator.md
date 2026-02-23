# Tailscale Operator Setup

This document describes how to configure and use the Tailscale Kubernetes Operator to provide secure Tailscale ingress to all applications.

## Overview

The [Tailscale Kubernetes Operator](https://tailscale.com/kb/1236/kubernetes-operator) enables you to access your Kubernetes services securely via your Tailnet without exposing them to the public internet.

**Key Benefits:**
- Secure access to all applications via Tailscale
- No need for public IPs or port forwarding
- Automatic DNS resolution within your Tailnet
- Zero-trust network access

## Prerequisites

Before deploying the Tailscale operator, you need to create OAuth credentials:

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/oauth)
2. Click **Generate OAuth Client**
3. Give it a descriptive name (e.g., "Kubernetes Operator")
4. Save the **Client ID** and **Client Secret**

## Configuration

Edit `group_vars/all.yml` and set the following variables:

```yaml
# Tailscale Operator configuration
tailscale_oauth_client_id: "YOUR_CLIENT_ID"
tailscale_oauth_client_secret: "YOUR_CLIENT_SECRET"
tailscale_operator_hostname: "ts-operator"

# Customize Tailscale hostnames (optional)
tailscale_gitea_hostname: "gitea"
tailscale_sonarr_hostname: "sonarr"
tailscale_headscale_hostname: "headscale"
tailscale_immich_hostname: "immich"
tailscale_qbittorrent_hostname: "qbittorrent"
tailscale_pihole_hostname: "pihole"
```

## How It Works

The Tailscale operator automatically:
1. Creates a Tailscale device for each LoadBalancer service
2. Assigns a MagicDNS hostname to each service
3. Routes traffic from your Tailnet to the Kubernetes service

### Service Annotations

Each application service is configured with Tailscale annotations:

```yaml
service:
  annotations:
    tailscale.com/expose: "true"
    tailscale.com/hostname: "app-name"
```

This tells the operator to:
- Expose the service to your Tailnet
- Assign it a hostname (e.g., `http://gitea`, `http://sonarr`)

## Accessing Applications

Once deployed, you can access applications from any device on your Tailnet:

| Application | Tailscale URL | Description |
|-------------|---------------|-------------|
| Gitea | `http://gitea` | Git web interface |
| Gitea SSH | `ssh://gitea-ssh` | Git SSH access |
| Sonarr | `http://sonarr:8989` | TV show PVR |
| Headscale | `http://headscale:8080` | Tailscale control server |
| Immich | `http://immich:3001` | Photo/video backup |
| qBittorrent | `http://qbittorrent:8080` | BitTorrent client |
| Pi-hole | `http://pihole` | Ad blocker web UI |

**Note:** Make sure you're connected to your Tailnet via the Tailscale client on your device.

## Verification

After deployment, verify the Tailscale operator is running:

```bash
# Check operator pods
kubectl get pods -n tailscale

# Check operator logs
kubectl logs -n tailscale -l app=tailscale-operator

# List Tailscale devices in your admin console
# You should see entries for each exposed service
```

## Viewing Tailscale Devices

1. Go to [Tailscale Machines](https://login.tailscale.com/admin/machines)
2. Look for devices with names matching your configured hostnames
3. Each service will have its own Tailscale device entry

## Troubleshooting

### Service Not Accessible

```bash
# Check if service has LoadBalancer type
kubectl get svc -A | grep LoadBalancer

# Check service annotations
kubectl describe svc <service-name> -n <namespace>

# Verify operator is running
kubectl get pods -n tailscale
```

### OAuth Credentials Invalid

```bash
# Delete and recreate the secret
kubectl delete secret operator-oauth -n tailscale

# Re-run the applications playbook
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml
```

### Hostname Conflicts

If you have hostname conflicts, customize the hostnames in `group_vars/all.yml`:

```yaml
tailscale_gitea_hostname: "k8s-gitea"
tailscale_sonarr_hostname: "k8s-sonarr"
# etc...
```

Then re-deploy:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml
```

## Advanced Configuration

### Custom Tags

Add custom Tailscale tags to devices:

Edit the Tailscale operator values in `roles/helm_apps/tasks/tailscale-operator.yml`:

```yaml
operatorConfig:
  tags:
    - "tag:kubernetes"
    - "tag:production"
```

### Funnel (Public URLs)

To expose services publicly via [Tailscale Funnel](https://tailscale.com/kb/1223/funnel):

```yaml
service:
  annotations:
    tailscale.com/expose: "true"
    tailscale.com/funnel: "true"
    tailscale.com/hostname: "public-app"
```

**⚠️ Warning:** Only use Funnel for services you want publicly accessible!

## Security Considerations

1. **OAuth Secret**: Keep your OAuth client secret secure
2. **ACLs**: Configure Tailscale ACLs to restrict access to services
3. **Authentication**: Applications should still have their own authentication
4. **HTTPS**: Consider enabling HTTPS via Tailscale's automatic certificates

## References

- [Tailscale Operator Documentation](https://tailscale.com/kb/1236/kubernetes-operator)
- [Tailscale Operator Helm Chart](https://artifacthub.io/packages/helm/tailscale/tailscale-operator)
- [Tailscale Service Annotations](https://tailscale.com/kb/1236/kubernetes-operator#exposing-services)
