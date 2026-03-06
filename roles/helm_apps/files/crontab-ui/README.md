# Crontab UI Helm Chart

A Helm chart for deploying Crontab UI - a web interface for managing cron jobs on the Kubernetes host.

## Introduction

This chart deploys Crontab UI with privileged access to the host's cron system, allowing you to manage cron jobs through a web interface.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Tailscale Operator (optional, for LoadBalancer service)

## Installing the Chart

To install the chart with the release name `crontab-ui`:

```bash
helm install crontab-ui ./crontab-ui \
  --namespace admin \
  --create-namespace
```

## Uninstalling the Chart

To uninstall/delete the `crontab-ui` deployment:

```bash
helm uninstall crontab-ui --namespace admin
```

## Parameters

### Common parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `alseambusher/crontab-ui` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### Service parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `8000` |
| `service.targetPort` | Container port | `8000` |

### Tailscale parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tailscale.enabled` | Enable Tailscale annotations | `true` |
| `tailscale.hostname` | Tailscale hostname | `cron` |

### Host access parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `hostAccess.enabled` | Enable host cron access | `true` |
| `hostAccess.cronPath` | Host cron path | `/var/spool/cron` |
| `hostNetwork` | Use host network | `true` |
| `hostPID` | Use host PID namespace | `true` |

### Persistence parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.enabled` | Enable persistence | `true` |
| `persistence.storageClass` | Storage class | `""` |
| `persistence.accessMode` | Access mode | `ReadWriteOnce` |
| `persistence.size` | Storage size | `100Mi` |

### Resources parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `200m` |
| `resources.limits.memory` | Memory limit | `256Mi` |
| `resources.requests.cpu` | CPU request | `50m` |
| `resources.requests.memory` | Memory request | `128Mi` |

### Security parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `securityContext.privileged` | Run as privileged | `true` |

## Configuration

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`:

```bash
helm install crontab-ui ./crontab-ui \
  --namespace admin \
  --set tailscale.hostname=mycron
```

Alternatively, a YAML file that specifies the values can be provided:

```bash
helm install crontab-ui ./crontab-ui \
  --namespace admin \
  --values custom-values.yaml
```

## Security Considerations

⚠️ **Warning**: This chart deploys a container with:
- `privileged: true` - Full host access
- `hostNetwork: true` - Access to host network
- `hostPID: true` - Access to host processes
- Host path mount to `/var/spool/cron`

These permissions are required for managing host cron jobs but should be carefully controlled. Only deploy in trusted environments and restrict access via network policies or Tailscale authentication.

## Storage

The chart creates a PersistentVolumeClaim for storing Crontab UI configuration and backups. The host's cron directory (`/var/spool/cron`) is mounted directly via hostPath.

## Accessing the Application

If Tailscale is enabled (default), access the UI at:
- `http://cron` (or your configured hostname)

Otherwise, use port-forwarding:
```bash
kubectl port-forward -n admin svc/crontab-ui 8000:8000
```

Then access at: `http://localhost:8000`

## License

This chart is distributed under the same license as the Crontab UI application.
